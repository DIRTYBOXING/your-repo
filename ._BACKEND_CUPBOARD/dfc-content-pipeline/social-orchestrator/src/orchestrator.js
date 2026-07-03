"use strict";

/**
 * DFC Social Orchestrator
 * ═══════════════════════════════════════════════════════════════
 * BullMQ worker that consumes `social-publish` jobs and drives:
 *   auto-clip → OG card → caption → cross-platform publish
 *
 * Each job payload looks like:
 * {
 *   postId:       string,        // Firestore social_posts doc
 *   eventId?:     string,        // optional event context
 *   platforms:    string[],      // ['meta_fb','meta_ig','x','youtube','tiktok','threads']
 *   mediaUrls:    string[],      // source media (video/image)
 *   captionHint?: string,        // optional user-supplied caption seed
 *   sponsorSkuId?:string,        // optional sponsor overlay
 *   schedule?:    { publishAt: string },
 *   abConfig?:    { enabled: boolean, variantCount: number },
 * }
 */

const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const { Worker, Queue, QueueEvents } = require("bullmq");
const IORedis = require("ioredis");
const { v4: uuidv4 } = require("uuid");
const fetch = require("node-fetch");
const admin = require("firebase-admin");

// ── Config ──────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 4004;
const REDIS_URL = process.env.REDIS_URL || "redis://127.0.0.1:6379";
const IMAGEGEN_URL = process.env.IMAGEGEN_URL || "http://imagegen-service:4002";
const CHUCKYA_URL = process.env.CHUCKYA_URL || "http://chuckya-radar:8081";
const CAPTION_URL = process.env.CAPTION_URL || ""; // Gemini Cloud Function URL

const CONCURRENCY = parseInt(process.env.WORKER_CONCURRENCY || "3", 10);
const MAX_RETRIES = 3;

// ── Firebase ────────────────────────────────────────────────────────────
if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  admin.initializeApp({ credential: admin.credential.applicationDefault() });
} else {
  admin.initializeApp();
}
const db = admin.firestore();

// ── Redis + Queues ──────────────────────────────────────────────────────
const redis = new IORedis(REDIS_URL, { maxRetriesPerRequest: null });

const socialQueue = new Queue("social-publish", { connection: redis });
const clipQueue = new Queue("video-transcode", { connection: redis });

// ── Express health / admin API ──────────────────────────────────────────
const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json());

app.get("/health", (_req, res) => {
  res.json({
    status: "ok",
    service: "social-orchestrator",
    uptime: process.uptime(),
  });
});

app.get("/v1/social/queue/stats", async (_req, res) => {
  const [waiting, active, completed, failed] = await Promise.all([
    socialQueue.getWaitingCount(),
    socialQueue.getActiveCount(),
    socialQueue.getCompletedCount(),
    socialQueue.getFailedCount(),
  ]);
  res.json({ waiting, active, completed, failed });
});

app.post("/v1/social/publish", async (req, res) => {
  const {
    postId,
    platforms,
    mediaUrls,
    captionHint,
    sponsorSkuId,
    schedule,
    abConfig,
  } = req.body;
  if (!postId || !platforms?.length) {
    return res.status(400).json({ error: "postId and platforms[] required" });
  }
  const job = await socialQueue.add(
    "publish",
    {
      postId,
      platforms,
      mediaUrls: mediaUrls || [],
      captionHint: captionHint || "",
      sponsorSkuId: sponsorSkuId || null,
      schedule: schedule || null,
      abConfig: abConfig || null,
    },
    {
      attempts: MAX_RETRIES,
      backoff: { type: "exponential", delay: 5000 },
      delay: schedule?.publishAt
        ? Math.max(0, new Date(schedule.publishAt).getTime() - Date.now())
        : 0,
    },
  );
  res.status(202).json({ jobId: job.id, postId });
});

// ═══════════════════════════════════════════════════════════════════════
// WORKER — processes social-publish jobs
// ═══════════════════════════════════════════════════════════════════════

const worker = new Worker(
  "social-publish",
  async (job) => {
    const {
      postId,
      platforms,
      mediaUrls,
      captionHint,
      sponsorSkuId,
      abConfig,
    } = job.data;
    const results = {};

    console.log(
      `[social-orchestrator] Processing job ${job.id} — post ${postId}`,
    );

    // ── Step 1: Safety check via CHUCKYA Radar ─────────────────────────
    const safetyOk = await checkSafety(postId, mediaUrls);
    if (!safetyOk) {
      await updatePostStatus(postId, "held_safety");
      throw new Error(`Post ${postId} held by safety review`);
    }

    // ── Step 2: Generate OG cards via imagegen-service ─────────────────
    const ogCards = await generateOGCards(postId, platforms, sponsorSkuId);
    await job.updateProgress(25);

    // ── Step 3: Request auto-clips for video content ───────────────────
    const clips = await requestAutoClips(mediaUrls);
    await job.updateProgress(50);

    // ── Step 4: Generate captions ──────────────────────────────────────
    const captions = await generateCaptions(
      postId,
      platforms,
      captionHint,
      abConfig,
    );
    await job.updateProgress(75);

    // ── Step 5: Publish to each platform ───────────────────────────────
    for (const platform of platforms) {
      try {
        const result = await publishToPlatform(platform, {
          postId,
          caption: captions[platform] || captions.default || "",
          ogCard: ogCards[platform] || ogCards.default || null,
          clips: clips,
          mediaUrls,
        });
        results[platform] = { success: true, ...result };
      } catch (err) {
        console.error(
          `[social-orchestrator] Publish failed for ${platform}:`,
          err.message,
        );
        results[platform] = { success: false, error: err.message };
      }
    }

    // ── Step 6: Write results back to Firestore ────────────────────────
    await db
      .collection("social_posts")
      .doc(postId)
      .update({
        publishResults: results,
        publishedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: Object.values(results).some((r) => r.success)
          ? "published"
          : "failed",
      });

    await job.updateProgress(100);
    console.log(
      `[social-orchestrator] Completed job ${job.id} — post ${postId}`,
    );
    return results;
  },
  {
    connection: redis,
    concurrency: CONCURRENCY,
  },
);

worker.on("failed", (job, err) => {
  console.error(`[social-orchestrator] Job ${job?.id} failed:`, err.message);
});

worker.on("completed", (job) => {
  console.log(`[social-orchestrator] Job ${job.id} completed`);
});

// ═══════════════════════════════════════════════════════════════════════
// PIPELINE STEPS
// ═══════════════════════════════════════════════════════════════════════

/** Check content against CHUCKYA Radar safety hold list */
async function checkSafety(postId, mediaUrls) {
  try {
    const resp = await fetch(`${CHUCKYA_URL}/v1/radar/scan`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ postId, urls: mediaUrls }),
    });
    if (!resp.ok) return true; // fail-open if radar is down
    const data = await resp.json();
    return data.riskScore < 0.7; // hold if risk >= 0.7
  } catch {
    return true; // fail-open
  }
}

/** Generate OG / social cards via imagegen-service */
async function generateOGCards(postId, platforms, sponsorSkuId) {
  const cards = {};
  const dimensions = {
    meta_fb: { w: 1200, h: 630 },
    meta_ig: { w: 1080, h: 1080 },
    x: { w: 1200, h: 675 },
    youtube: { w: 1280, h: 720 },
    tiktok: { w: 1080, h: 1920 },
    threads: { w: 1080, h: 1080 },
  };

  for (const platform of platforms) {
    const dim = dimensions[platform] || dimensions.meta_fb;
    try {
      const resp = await fetch(`${IMAGEGEN_URL}/v1/generate`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          template: "social_card",
          postId,
          platform,
          width: dim.w,
          height: dim.h,
          sponsorSkuId: sponsorSkuId || undefined,
        }),
      });
      if (resp.ok) {
        const data = await resp.json();
        cards[platform] = data.imageUrl;
      }
    } catch (err) {
      console.warn(`[OG] Failed for ${platform}:`, err.message);
    }
  }
  cards.default = cards.meta_fb || Object.values(cards)[0] || null;
  return cards;
}

/** Queue auto-clip jobs for video media */
async function requestAutoClips(mediaUrls) {
  const videoExts = [".mp4", ".mov", ".webm", ".mkv"];
  const videos = mediaUrls.filter((u) =>
    videoExts.some((ext) => u.toLowerCase().includes(ext)),
  );
  if (!videos.length) return [];

  const clipJobs = videos.map((url) =>
    clipQueue.add(
      "auto-clip",
      {
        sourceUrl: url,
        outputs: [
          { format: "mp4", maxDuration: 60, label: "short" },
          { format: "mp4", maxDuration: 15, label: "reel" },
        ],
      },
      { attempts: 2 },
    ),
  );

  const jobs = await Promise.all(clipJobs);
  return jobs.map((j) => ({ jobId: j.id, status: "queued" }));
}

/** Generate platform-specific captions */
async function generateCaptions(postId, platforms, captionHint, abConfig) {
  const captions = {};

  // Try Gemini Cloud Function for smart captions
  if (CAPTION_URL) {
    try {
      const resp = await fetch(CAPTION_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          postId,
          platforms,
          hint: captionHint,
          variants: abConfig?.enabled ? abConfig.variantCount || 2 : 1,
        }),
      });
      if (resp.ok) {
        const data = await resp.json();
        // data.captions = { meta_fb: 'caption...', x: 'caption...', ... }
        Object.assign(captions, data.captions || {});
      }
    } catch (err) {
      console.warn("[Caption] Gemini call failed:", err.message);
    }
  }

  // Fallback: use captionHint as-is with platform-aware truncation
  if (!Object.keys(captions).length && captionHint) {
    const limits = {
      x: 280,
      tiktok: 2200,
      meta_ig: 2200,
      meta_fb: 5000,
      youtube: 5000,
      threads: 500,
    };
    for (const p of platforms) {
      const limit = limits[p] || 5000;
      captions[p] =
        captionHint.length > limit
          ? captionHint.slice(0, limit - 3) + "..."
          : captionHint;
    }
  }

  captions.default = captions[platforms[0]] || captionHint || "";
  return captions;
}

/** Publish content to a specific platform connector */
async function publishToPlatform(platform, payload) {
  // Platform connectors are external services / Cloud Functions.
  // This orchestrator enqueues the publish intent and records metadata.
  // Full connector implementations live in functions/social/ or as separate services.

  const publishId = uuidv4();
  const utmParams = buildUTM(platform, payload.postId);

  // Write publish record to Firestore for connector pickup
  await db.collection("social_publish_queue").doc(publishId).set({
    publishId,
    platform,
    postId: payload.postId,
    caption: payload.caption,
    ogCardUrl: payload.ogCard,
    mediaUrls: payload.mediaUrls,
    clipJobs: payload.clips,
    utmParams,
    status: "pending",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { publishId, utmParams };
}

/** Build UTM parameters for link tracking */
function buildUTM(platform, postId) {
  return {
    utm_source: `dfc_${platform}`,
    utm_medium: "social",
    utm_campaign: `post_${postId}`,
    utm_content: platform,
  };
}

/** Update post status in Firestore */
async function updatePostStatus(postId, status) {
  try {
    await db.collection("social_posts").doc(postId).update({
      status,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (err) {
    console.error("[Firestore] Status update failed:", err.message);
  }
}

// ── Start ───────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`
╔═══════════════════════════════════════════════════════════╗
║  DFC Social Orchestrator                                  ║
║  Port:         ${String(PORT).padEnd(40)}║
║  Redis:        ${REDIS_URL.padEnd(40)}║
║  Concurrency:  ${String(CONCURRENCY).padEnd(40)}║
║  CHUCKYA:      ${(CHUCKYA_URL || "not configured").padEnd(40)}║
║  Imagegen:     ${(IMAGEGEN_URL || "not configured").padEnd(40)}║
║  Caption API:  ${(CAPTION_URL || "not configured").padEnd(40)}║
╚═══════════════════════════════════════════════════════════╝
  `);
});
