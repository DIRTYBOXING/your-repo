// ═══════════════════════════════════════════════════════════════════════════
// RSS FEED INGESTION — Live content from worldwide fight sources
// ═══════════════════════════════════════════════════════════════════════════

const { onCall } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { admin, db, REGION, Parser } = require("../config");
const { MEGA_RSS_FEEDS } = require("./mega_sources");

// ─── RSS Feed Sources (120+ worldwide feeds from mega_sources) ───────
const RSS_FEEDS = MEGA_RSS_FEEDS;

// ─── 6-Hour Rotation Strategy ────────────────────────────────────────
// Instead of hammering 120+ feeds every 15 min, we rotate in batches.
// "Always-on" tier-1 sources run EVERY cycle (breaking news).
// Everything else rotates across 24 slots (every 15 min = 24 per 6h).
// Full rotation = 6 hours. Each cycle hits ~15-25 feeds max.

const ALWAYS_ON_SOURCES = [
  "MMA Fighting",
  "ESPN MMA",
  "Sherdog",
  "MMA Junkie",
  "ESPN Boxing",
  "Boxing Scene",
  "Ring Magazine",
  "BKFC",
  "Sky Sports Boxing",
];

const ROTATION_SLOTS = 24; // 24 x 15min = 6 hours full cycle
const QUERY_TELEMETRY_SAMPLE_RATE = 0.2;

function getFeedsForCurrentCycle() {
  // Always-on feeds (tier-1 breaking news — every cycle)
  const alwaysOn = RSS_FEEDS.filter((f) =>
    ALWAYS_ON_SOURCES.includes(f.source),
  );

  // Remaining feeds split into 24 rotation slots
  const rotating = RSS_FEEDS.filter(
    (f) => !ALWAYS_ON_SOURCES.includes(f.source),
  );

  // Determine which slot we're in based on current time
  const now = new Date();
  const minutesSinceMidnight = now.getUTCHours() * 60 + now.getUTCMinutes();
  const slotIndex = Math.floor(minutesSinceMidnight / 15) % ROTATION_SLOTS;

  // Distribute rotating feeds evenly across slots
  const batchSize = Math.ceil(rotating.length / ROTATION_SLOTS);
  const start = slotIndex * batchSize;
  const batch = rotating.slice(start, start + batchSize);

  const combined = [...alwaysOn, ...batch];
  console.log(
    `[Feed Rotation] Slot ${slotIndex}/${ROTATION_SLOTS} — ${alwaysOn.length} always-on + ${batch.length} rotating = ${combined.length} feeds this cycle`,
  );
  return combined;
}

// ─── RSS Helpers ─────────────────────────────────────────────────────────
function stripHtml(html) {
  return (html || "")
    .replace(/<[^>]*>/g, "")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .trim();
}

function extractImageFromItem(item) {
  if (item.enclosure && item.enclosure.url) return item.enclosure.url;
  if (
    item["media:content"] &&
    item["media:content"]["$"] &&
    item["media:content"]["$"].url
  ) {
    return item["media:content"]["$"].url;
  }
  const imgMatch = (item.content || "").match(/<img[^>]+src="([^"]+)"/);
  if (imgMatch) return imgMatch[1];
  return null;
}

function extractTags(item, defaultCategory) {
  const tags = [defaultCategory];
  const categories = item.categories || [];
  for (const cat of categories) {
    if (typeof cat === "string") tags.push(cat.toLowerCase());
    else if (cat._) tags.push(cat._.toLowerCase());
  }
  return [...new Set(tags)].slice(0, 8);
}

function maybeLogQueryTelemetry(payload) {
  if (Math.random() > QUERY_TELEMETRY_SAMPLE_RATE) return;
  console.log(
    "[QueryTelemetry]",
    JSON.stringify({
      ts: new Date().toISOString(),
      ...payload,
    }),
  );
}

// ─── Get Fight News Feed ─────────────────────────────────────────────────
const getFightNewsFeed = onCall({ region: REGION }, async (request) => {
  const requestStartedAt = Date.now();
  const data = request.data || {};
  const offset = Number.isFinite(Number(data.offset)) ? Number(data.offset) : 0;
  const requestedLimit = Number.isFinite(Number(data.limit))
    ? Number(data.limit)
    : 40;
  const limit = Math.min(Math.max(requestedLimit, 1), 50);
  const categoryFilter = data.category;
  const regionFilter = data.region;
  const pageToken =
    typeof data.pageToken === "string" ? data.pageToken.trim() : "";
  const telemetryBase = {
    endpoint: "getFightNewsFeed",
    limit,
    offset,
    hasCategoryFilter: !!categoryFilter,
    hasRegionFilter: !!regionFilter,
    hasPageToken: !!pageToken,
  };

  // Cache-first path for unfiltered requests to reduce feed_content reads.
  if (!categoryFilter && !regionFilter) {
    let cacheQuery = db
      .collection("auto_feed_cache")
      .orderBy("publishedAt", "desc");
    if (pageToken) {
      const pageDoc = await db
        .collection("auto_feed_cache")
        .doc(pageToken)
        .get();
      if (pageDoc.exists) {
        cacheQuery = cacheQuery.startAfter(pageDoc);
      }
    }

    const cacheSnap = await cacheQuery.limit(limit).get();
    if (!cacheSnap.empty) {
      const articles = cacheSnap.docs.map((doc) => {
        const d = doc.data();
        return {
          id: doc.id,
          title: d.title || "",
          summary: (d.body || "").slice(0, 300),
          source: d.source || "",
          category: d.sourceType || "",
          url: d.linkUrl || "",
          publishedAt: d.publishedAt || "",
          imageUrl: d.imageUrl || null,
          tags: d.tags || [],
          region: d.region || "global",
          isBreaking: false,
          isFeatured: false,
          trustScore: d.trustScore || 0.8,
          authorName: d.source || "",
          attribution: d.source ? "Originally published by " + d.source : "",
        };
      });

      const nextPageToken =
        cacheSnap.docs.length === limit
          ? cacheSnap.docs[cacheSnap.docs.length - 1].id
          : null;

      maybeLogQueryTelemetry({
        ...telemetryBase,
        source: "auto_feed_cache",
        docsReturned: articles.length,
        nextPageTokenPresent: !!nextPageToken,
        durationMs: Date.now() - requestStartedAt,
      });

      return {
        articles,
        total: null,
        nextPageToken,
        source: "auto_feed_cache",
      };
    }
  }

  // PRIMARY PATH: Read from Firestore (fast, pre-ingested content)
  let query = db
    .collection("feed_content")
    .where("status", "==", "published")
    .orderBy("publishedAt", "desc");

  if (categoryFilter) query = query.where("category", "==", categoryFilter);
  if (regionFilter) query = query.where("region", "==", regionFilter);

  let docs = [];
  if (pageToken) {
    const pageDoc = await db.collection("feed_content").doc(pageToken).get();
    if (pageDoc.exists) {
      query = query.startAfter(pageDoc);
    }
    const snapshot = await query.limit(limit).get();
    docs = snapshot.docs;
  } else if (offset > 0) {
    // Backward-compatible path for legacy offset callers.
    const snapshot = await query.limit(offset + limit).get();
    docs = snapshot.docs.slice(offset, offset + limit);
  } else {
    const snapshot = await query.limit(limit).get();
    docs = snapshot.docs;
  }

  if (docs.length >= 1) {
    const articles = docs.map((doc) => {
      const d = doc.data();
      return {
        id: doc.id,
        title: d.title || "",
        summary: (d.summary || "").slice(0, 300),
        source: d.source || "",
        category: d.category || "",
        url: d.url || "",
        publishedAt: d.publishedAt || "",
        imageUrl: d.imageUrl || null,
        tags: d.tags || [],
        region: d.region || "global",
        isBreaking: d.isBreaking || false,
        isFeatured: d.isFeatured || false,
        trustScore: d.trustScore || 0.8,
        authorName: d.authorName || d.source || "",
        attribution:
          d.attribution || "Originally published by " + (d.source || "unknown"),
      };
    });

    const nextPageToken =
      docs.length === limit ? docs[docs.length - 1].id : null;

    maybeLogQueryTelemetry({
      ...telemetryBase,
      source: "firestore",
      docsReturned: articles.length,
      nextPageTokenPresent: !!nextPageToken,
      durationMs: Date.now() - requestStartedAt,
    });

    return {
      articles,
      total: null,
      nextPageToken,
      source: "firestore",
    };
  }

  // FALLBACK: Live RSS fetch
  if (!Parser) {
    return {
      articles: [],
      error:
        "No cached content yet. Ingestion pipeline will populate within 15 minutes.",
    };
  }

  const parser = new Parser({
    timeout: 10000,
    headers: {
      "User-Agent": "DataFightCentral/1.0 (Combat Sports Aggregator)",
    },
  });

  const allArticles = [];
  const feedPromises = RSS_FEEDS.filter(
    (f) => !categoryFilter || f.category === categoryFilter,
  )
    .filter((f) => !regionFilter || f.region === regionFilter)
    .map(async (feed) => {
      try {
        const parsed = await parser.parseURL(feed.url);
        return (parsed.items || []).slice(0, 15).map((item) => ({
          id:
            "rss_" +
            Buffer.from(item.link || item.guid || item.title || "")
              .toString("base64")
              .slice(0, 40),
          title: (item.title || "").trim(),
          summary: stripHtml(
            item.contentSnippet || item.content || item.summary || "",
          ).slice(0, 300),
          source: feed.source,
          category: feed.category,
          url: item.link || "",
          publishedAt: item.isoDate || item.pubDate || new Date().toISOString(),
          imageUrl: extractImageFromItem(item),
          tags: extractTags(item, feed.category),
          region: feed.region || "global",
          isBreaking: false,
          isFeatured: false,
          trustScore: feed.trustScore,
          authorName: item.creator || item.author || feed.source,
          attribution:
            "Originally published by " +
            feed.source +
            ". Tap to read full article.",
        }));
      } catch (err) {
        console.warn(
          "RSS fetch failed for " + feed.source + ": " + err.message,
        );
        return [];
      }
    });

  const results = await Promise.all(feedPromises);
  for (const items of results) {
    allArticles.push(...items);
  }

  allArticles.sort((a, b) => new Date(b.publishedAt) - new Date(a.publishedAt));
  const paginated = allArticles.slice(offset, offset + limit);
  maybeLogQueryTelemetry({
    ...telemetryBase,
    source: "live_rss_fallback",
    docsReturned: paginated.length,
    totalCandidates: allArticles.length,
    durationMs: Date.now() - requestStartedAt,
  });
  return {
    articles: paginated,
    total: allArticles.length,
    source: "live_rss_fallback",
  };
});

// ─── Ingest RSS to Firestore (Scheduled) ─────────────────────────────────
const ingestRssToFirestore = onSchedule(
  { schedule: "every 15 minutes", region: REGION },
  async () => {
    if (!Parser) {
      console.warn("rss-parser not installed. Skipping ingestion.");
      return null;
    }

    const parser = new Parser({
      timeout: 10000,
      headers: {
        "User-Agent": "DataFightCentral/1.0 (Combat Sports Aggregator)",
      },
    });

    let ingestedCount = 0;
    const feedsThisCycle = getFeedsForCurrentCycle();

    for (const feed of feedsThisCycle) {
      try {
        const parsed = await parser.parseURL(feed.url);
        const items = (parsed.items || []).slice(0, 10);

        for (const item of items) {
          const articleUrl = item.link || "";
          if (!articleUrl) continue;

          const existing = await db
            .collection("ingested_content")
            .where("url", "==", articleUrl)
            .limit(1)
            .get();
          if (!existing.empty) continue;

          await db.collection("ingested_content").add({
            status: "new",
            title: (item.title || "").trim(),
            summary: stripHtml(item.contentSnippet || item.content || "").slice(
              0,
              500,
            ),
            source: feed.source,
            category: feed.category,
            region: feed.region || "global",
            url: articleUrl,
            imageUrl: extractImageFromItem(item),
            publishedAt:
              item.isoDate || item.pubDate || new Date().toISOString(),
            trustScore: feed.trustScore,
            authorName: item.creator || item.author || feed.source,
            attribution: "Originally published by " + feed.source,
            ingestedAt: admin.firestore.FieldValue.serverTimestamp(),
            tags: extractTags(item, feed.category),
          });
          ingestedCount++;
        }
      } catch (err) {
        console.warn(
          "RSS ingestion failed for " + feed.source + ": " + err.message,
        );
      }
    }

    console.log(
      "RSS ingestion complete: " +
        ingestedCount +
        " new articles from " +
        feedsThisCycle.length +
        "/" +
        RSS_FEEDS.length +
        " feeds this rotation.",
    );

    // Promotion is handled by the Waterfall Conveyor Belt (waterfall.js)
    // which runs on its own 15-min schedule with scoring, balancing,
    // hype engine, adrenaline dump, and archival.
    console.log("Articles queued for Waterfall Conveyor processing.");
  },
);

// ─── Manual Feed Ingest Trigger (callable) ───────────────────────────────
const triggerFeedIngest = onCall({ region: REGION }, async (request) => {
  if (!Parser) {
    return { error: "rss-parser not available" };
  }

  const parser = new Parser({
    timeout: 10000,
    headers: {
      "User-Agent": "DataFightCentral/1.0 (Combat Sports Aggregator)",
    },
  });

  let ingestedCount = 0;
  let promotedCount = 0;

  // Ingest (rotated batch)
  const feedsThisCycle = getFeedsForCurrentCycle();
  for (const feed of feedsThisCycle) {
    try {
      const parsed = await parser.parseURL(feed.url);
      const items = (parsed.items || []).slice(0, 10);
      for (const item of items) {
        const articleUrl = item.link || "";
        if (!articleUrl) continue;
        const existing = await db
          .collection("ingested_content")
          .where("url", "==", articleUrl)
          .limit(1)
          .get();
        if (!existing.empty) continue;
        await db.collection("ingested_content").add({
          status: "new",
          title: (item.title || "").trim(),
          summary: stripHtml(item.contentSnippet || item.content || "").slice(
            0,
            500,
          ),
          source: feed.source,
          category: feed.category,
          region: feed.region || "global",
          url: articleUrl,
          imageUrl: extractImageFromItem(item),
          publishedAt: item.isoDate || item.pubDate || new Date().toISOString(),
          trustScore: feed.trustScore,
          authorName: item.creator || item.author || feed.source,
          attribution: "Originally published by " + feed.source,
          ingestedAt: admin.firestore.FieldValue.serverTimestamp(),
          tags: extractTags(item, feed.category),
        });
        ingestedCount++;
      }
    } catch (err) {
      console.warn("Feed failed: " + feed.source + ": " + err.message);
    }
  }

  // Promotion handled by Waterfall Conveyor Belt
  // Articles stay as status:'new' in ingested_content for waterfall to score + promote

  return {
    ingestedCount,
    feedsChecked: feedsThisCycle.length,
    totalFeeds: RSS_FEEDS.length,
    note: "Promotion handled by waterfallConveyor",
  };
});

module.exports = {
  getFightNewsFeed,
  ingestRssToFirestore,
  triggerFeedIngest,
  RSS_FEEDS,
};
