// src/feeds/intake.ts
import fetch from "node-fetch";
import Parser from "rss-parser";
import crypto from "crypto";
import { Pool } from "pg"; // or use Firestore SDK if you prefer
// import { PubSub } from '@google-cloud/pubsub'; // optional

type SourceConfig = {
  id: string;
  type: "rss" | "youtube_channel" | "api";
  url?: string;
  channel_id?: string;
  trusted?: boolean;
  trust_score?: number;
  parsing?: Record<string, any>;
  dedupe?: {
    strategy: string;
    hash_fields?: string[];
    external_id_field?: string;
    window_hours?: number;
  };
  moderation?: { require_moderation?: boolean; moderators?: string[] };
  metadata?: Record<string, any>;
};

type NormalizedItem = {
  source_id: string;
  external_id?: string;
  title: string;
  body?: string;
  published_at?: string;
  author?: string | null;
  media_url?: string | null;
  trusted: boolean;
  trust_score?: number;
  metadata?: Record<string, any>;
  raw?: any;
};

const parser = new Parser();
const DB_POOL = new Pool({ connectionString: process.env.DATABASE_URL }); // used for dedupe index and queue
// const pubsub = new PubSub(); // optional: publish to Pub/Sub

const YOUTUBE_API_KEY = process.env.YOUTUBE_API_KEY || ""; // store in Secret Manager and inject at runtime

function contentHash(
  item: Partial<NormalizedItem>,
  fields: string[] = ["title", "body"],
) {
  const payload = fields.map((f) => (item as any)[f] ?? "").join("||");
  return crypto.createHash("sha256").update(payload).digest("hex");
}

async function fetchRss(url: string) {
  const feed = await parser.parseURL(url);
  return feed.items || [];
}

async function fetchYoutubeChannel(channelId: string) {
  if (!YOUTUBE_API_KEY) throw new Error("YOUTUBE_API_KEY not set");
  const apiUrl = `https://www.googleapis.com/youtube/v3/search?key=${YOUTUBE_API_KEY}&channelId=${channelId}&part=snippet,id&order=date&maxResults=10`;
  const res = await fetch(apiUrl);
  if (!res.ok) throw new Error(`YouTube API error ${res.status}`);
  const json: any = await res.json();
  return json.items || [];
}

function normalizeRssItem(
  srcId: string,
  raw: any,
  cfg: SourceConfig,
): NormalizedItem {
  return {
    source_id: srcId,
    external_id: raw.guid || raw.id || raw.link || null,
    title: raw.title || "",
    body: raw.contentSnippet || raw.content || raw.description || "",
    published_at: raw.isoDate || raw.pubDate || null,
    author: raw.creator || raw.author || null,
    media_url: raw.enclosure?.url || null,
    trusted: !!cfg.trusted,
    trust_score: cfg.trust_score,
    metadata: cfg.metadata || {},
    raw,
  };
}

function normalizeYoutubeItem(
  srcId: string,
  raw: any,
  cfg: SourceConfig,
): NormalizedItem {
  const snippet = raw.snippet || {};
  const videoId = raw.id?.videoId || raw.id;
  return {
    source_id: srcId,
    external_id: videoId,
    title: snippet.title || "",
    body: snippet.description || "",
    published_at: snippet.publishedAt || null,
    author: snippet.channelTitle || null,
    media_url: videoId ? `https://www.youtube.com/watch?v=${videoId}` : null,
    trusted: !!cfg.trusted,
    trust_score: cfg.trust_score,
    metadata: cfg.metadata || {},
    raw,
  };
}

async function isDuplicate(hash: string, windowHours = 168) {
  const client = await DB_POOL.connect();
  try {
    const res = await client.query(
      `SELECT 1 FROM feeds_dedupe WHERE hash = $1 AND created_at > NOW() - INTERVAL '${windowHours} hours' LIMIT 1`,
      [hash],
    );
    return res.rowCount > 0;
  } finally {
    client.release();
  }
}

async function markSeen(hash: string) {
  const client = await DB_POOL.connect();
  try {
    await client.query(
      `INSERT INTO feeds_dedupe (hash, created_at) VALUES ($1, NOW()) ON CONFLICT DO NOTHING`,
      [hash],
    );
  } finally {
    client.release();
  }
}

async function enqueueItem(item: NormalizedItem) {
  // Example: insert into a DB table for downstream publisher or push to Pub/Sub
  const client = await DB_POOL.connect();
  try {
    await client.query(
      `INSERT INTO feeds_incoming (source_id, external_id, title, body, published_at, author, media_url, trusted, trust_score, metadata, raw)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)`,
      [
        item.source_id,
        item.external_id,
        item.title,
        item.body,
        item.published_at,
        item.author,
        item.media_url,
        item.trusted,
        item.trust_score,
        JSON.stringify(item.metadata || {}),
        JSON.stringify(item.raw || {}),
      ],
    );
  } finally {
    client.release();
  }
}

export async function processSource(cfg: SourceConfig) {
  try {
    let rawItems: any[] = [];
    if (cfg.type === "rss" && cfg.url) {
      rawItems = await fetchRss(cfg.url);
    } else if (cfg.type === "youtube_channel" && cfg.channel_id) {
      rawItems = await fetchYoutubeChannel(cfg.channel_id);
    } else if (cfg.type === "api" && cfg.url) {
      const res = await fetch(cfg.url);
      const apiJson: any = await res.json();
      rawItems = apiJson.items || [];
    } else {
      console.warn(`Unsupported source type or missing config for ${cfg.id}`);
      return;
    }

    for (const raw of rawItems.slice(
      0,
      cfg.dedupe?.window_hours ? cfg.dedupe.window_hours : 50,
    )) {
      let item: NormalizedItem;
      if (cfg.type === "rss") item = normalizeRssItem(cfg.id, raw, cfg);
      else if (cfg.type === "youtube_channel")
        item = normalizeYoutubeItem(cfg.id, raw, cfg);
      else
        item = {
          source_id: cfg.id,
          title: raw.title || "",
          body: raw.description || "",
          trusted: !!cfg.trusted,
          metadata: cfg.metadata || {},
          raw,
        };

      // compute dedupe hash
      const hashFields = cfg.dedupe?.hash_fields || ["title", "body"];
      const hash = contentHash(item, hashFields);

      const duplicate = await isDuplicate(
        hash,
        cfg.dedupe?.window_hours || 168,
      );
      if (duplicate) {
        // skip duplicates
        continue;
      }

      // mark seen before enqueue to avoid race conditions
      await markSeen(hash);

      // moderation hook
      if (cfg.moderation?.require_moderation) {
        // insert into moderation queue instead of publishing
        const client = await DB_POOL.connect();
        try {
          await client.query(
            `INSERT INTO feeds_moderation (source_id, external_id, title, body, metadata, created_at) VALUES ($1,$2,$3,$4,$5,NOW())`,
            [
              item.source_id,
              item.external_id,
              item.title,
              item.body,
              JSON.stringify(item.metadata || {}),
            ],
          );
        } finally {
          client.release();
        }
        continue;
      }

      // enqueue for publishing
      await enqueueItem(item);
    }
  } catch (err) {
    console.error(`Error processing source ${cfg.id}:`, err);
    // emit structured log or metric here
  }
}

// Example runner: load config and process all sources
export async function runIntakeOnce(
  configPath = "config/auto_feed_sources.json",
) {
  const cfgRaw = await import(`../../${configPath}`); // dynamic import of JSON
  const cfg = cfgRaw.default || cfgRaw;
  const sources: SourceConfig[] = cfg.sources || [];

  // simple concurrency control
  const concurrency = Math.min(8, sources.length);
  const queue: Promise<void>[] = [];
  for (const s of sources) {
    const p = processSource(s);
    queue.push(p);
    if (queue.length >= concurrency) {
      await Promise.race(queue).catch(() => {});
      // remove settled promises
      for (let i = queue.length - 1; i >= 0; i--) {
        if ((queue[i] as any).isFulfilled) queue.splice(i, 1);
      }
    }
  }
  await Promise.all(queue);
}

// If run directly
if (require.main === module) {
  runIntakeOnce()
    .then(() => {
      console.log("Intake run complete");
      process.exit(0);
    })
    .catch((err) => {
      console.error("Intake failed", err);
      process.exit(1);
    });
}
