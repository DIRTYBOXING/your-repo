// src/workers/media-worker.js
// ═══════════════════════════════════════════════════════════════════════════
// DFC MEDIA WORKER — S3-based media processing pipeline
//
// Flow:
//   1. Poll Redis queue for jobs (key: dfc:media-jobs)
//   2. Download original from S3 (uploads/originals/<key>)
//   3. Run FFmpeg: generate OG image (1200×630) + video variants (sd/hd)
//   4. Upload outputs to S3 (public/variants/<jobId>/...)
//   5. POST /internal/media-complete to notify the API
//
// Environment variables (see .env.example):
//   REDIS_URL              Redis connection string (default: redis://localhost:6379)
//   AWS_REGION             AWS region (default: us-east-1)
//   AWS_ACCESS_KEY_ID      AWS credentials
//   AWS_SECRET_ACCESS_KEY  AWS credentials
//   S3_UPLOAD_BUCKET       Bucket for originals  (default: dfc-uploads)
//   S3_PUBLIC_BUCKET       Bucket for variants   (default: dfc-public)
//   CDN_BASE_URL           Public CDN prefix for variant URLs
//   API_BASE_URL           Internal API base (default: http://localhost:4000)
//   WORKER_CALLBACK_SECRET Shared secret sent in x-callback-secret header
// ═══════════════════════════════════════════════════════════════════════════
"use strict";

const { createClient } = require("redis");
const {
  S3Client,
  GetObjectCommand,
  PutObjectCommand,
} = require("@aws-sdk/client-s3");
const ffmpeg = require("fluent-ffmpeg");
const fs = require("fs");
const path = require("path");
const os = require("os");
const { pipeline } = require("stream/promises");
const { v4: uuidv4 } = require("uuid");

// ── Config ──────────────────────────────────────────────────────────────────
const REDIS_URL = process.env.REDIS_URL || "redis://localhost:6379";
const QUEUE_KEY = "dfc:media-jobs";
const POLL_INTERVAL_MS = 2000;
const S3_UPLOAD_BUCKET = process.env.S3_UPLOAD_BUCKET || "dfc-uploads";
const S3_PUBLIC_BUCKET = process.env.S3_PUBLIC_BUCKET || "dfc-public";
const CDN_BASE_URL = (
  process.env.CDN_BASE_URL || `https://${S3_PUBLIC_BUCKET}.s3.amazonaws.com`
).replace(/\/$/, "");
const API_BASE_URL = (
  process.env.API_BASE_URL || "http://localhost:4000"
).replace(/\/$/, "");
const CALLBACK_SECRET = process.env.WORKER_CALLBACK_SECRET || "";
const AWS_REGION = process.env.AWS_REGION || "us-east-1";

const TMP_DIR = path.join(os.tmpdir(), "dfc-media-worker");
fs.mkdirSync(TMP_DIR, { recursive: true });

// ── AWS S3 Client ───────────────────────────────────────────────────────────
const s3 = new S3Client({ region: AWS_REGION });

// ── Redis Client ────────────────────────────────────────────────────────────
const redis = createClient({ url: REDIS_URL });

async function start() {
  await redis.connect();
  console.log("[media-worker] Connected to Redis — polling queue:", QUEUE_KEY);
  poll();
}

// ── Main Poll Loop ───────────────────────────────────────────────────────────
async function poll() {
  while (true) {
    try {
      // BLPOP blocks up to 2 s then returns null (non-blocking feel with timeout)
      const item = await redis.blPop(QUEUE_KEY, 2);
      if (item) {
        const job = JSON.parse(item.element);
        await processJob(job);
      }
    } catch (err) {
      console.error("[media-worker] Poll error:", err.message);
    }
    await sleep(POLL_INTERVAL_MS);
  }
}

// ── Process a single job ─────────────────────────────────────────────────────
async function processJob(job) {
  const { jobId, postId, mediaKey } = job;
  const workDir = path.join(TMP_DIR, uuidv4());
  fs.mkdirSync(workDir, { recursive: true });

  console.log(
    `[media-worker] Processing job ${jobId} — post ${postId} — key ${mediaKey}`,
  );

  try {
    // ── 1. Download original from S3 ────────────────────────────────────
    const inputPath = path.join(workDir, "original");
    await downloadFromS3(S3_UPLOAD_BUCKET, mediaKey, inputPath);
    console.log(`[media-worker] Downloaded ${mediaKey}`);

    // ── 2. Detect media type ─────────────────────────────────────────────
    const contentType = job.contentType || "";
    const isVideo = contentType.startsWith("video/");

    const outputs = {};

    if (isVideo) {
      // ── 3a. Video: generate OG image + sd/hd variants ───────────────
      const ogPath = path.join(workDir, "og-1200x630.jpg");
      await generateOgImage(inputPath, ogPath);
      const ogKey = `public/variants/${jobId}/og-1200x630.jpg`;
      await uploadToS3(S3_PUBLIC_BUCKET, ogKey, ogPath, "image/jpeg", true);
      outputs.ogImageUrl = `${CDN_BASE_URL}/${ogKey}`;

      const sdPath = path.join(workDir, "sd480.mp4");
      await transcodeToMp4(inputPath, sdPath, {
        width: 854,
        height: 480,
        videoBitrate: "800k",
        audioBitrate: "96k",
      });
      const sdKey = `public/variants/${jobId}/sd480.mp4`;
      await uploadToS3(S3_PUBLIC_BUCKET, sdKey, sdPath, "video/mp4", true);
      outputs.sd480 = `${CDN_BASE_URL}/${sdKey}`;

      const hdPath = path.join(workDir, "hd720.mp4");
      await transcodeToMp4(inputPath, hdPath, {
        width: 1280,
        height: 720,
        videoBitrate: "2500k",
        audioBitrate: "128k",
      });
      const hdKey = `public/variants/${jobId}/hd720.mp4`;
      await uploadToS3(S3_PUBLIC_BUCKET, hdKey, hdPath, "video/mp4", true);
      outputs.hd720 = `${CDN_BASE_URL}/${hdKey}`;

      console.log(
        `[media-worker] Video variants ready — ${Object.keys(outputs).length} outputs`,
      );
    } else {
      // ── 3b. Image: generate OG variant (1200×630) ───────────────────
      const ogPath = path.join(workDir, "og-1200x630.jpg");
      await resizeImageToOg(inputPath, ogPath);
      const ogKey = `public/variants/${jobId}/og-1200x630.jpg`;
      await uploadToS3(S3_PUBLIC_BUCKET, ogKey, ogPath, "image/jpeg", true);
      outputs.ogImageUrl = `${CDN_BASE_URL}/${ogKey}`;
      console.log(`[media-worker] Image OG variant ready`);
    }

    // ── 4. Notify API ────────────────────────────────────────────────────
    await notifyApi({
      postId,
      jobId,
      ogImageUrl: outputs.ogImageUrl,
      variants: outputs,
      status: "ready",
    });
    console.log(`[media-worker] Job ${jobId} COMPLETE`);
  } catch (err) {
    console.error(`[media-worker] Job ${jobId} FAILED:`, err.message);
    await notifyApi({ postId, jobId, status: "failed" }).catch(() => {});
  } finally {
    fs.rmSync(workDir, { recursive: true, force: true });
  }
}

// ── S3 helpers ───────────────────────────────────────────────────────────────
async function downloadFromS3(bucket, key, dest) {
  const { Body } = await s3.send(
    new GetObjectCommand({ Bucket: bucket, Key: key }),
  );
  const destStream = fs.createWriteStream(dest);
  await pipeline(Body, destStream);
}

async function uploadToS3(bucket, key, filePath, contentType, isPublic) {
  const body = fs.readFileSync(filePath);
  const params = {
    Bucket: bucket,
    Key: key,
    Body: body,
    ContentType: contentType,
  };
  if (isPublic) {
    params.ACL = "public-read";
  }
  await s3.send(new PutObjectCommand(params));
}

// ── FFmpeg helpers ───────────────────────────────────────────────────────────
function generateOgImage(inputPath, outputPath) {
  return new Promise((resolve, reject) => {
    ffmpeg(inputPath)
      .seekInput(3)
      .frames(1)
      .outputOptions([
        "-vf",
        "scale=1200:630:force_original_aspect_ratio=decrease,pad=1200:630:(ow-iw)/2:(oh-ih)/2:color=black",
      ])
      .output(outputPath)
      .on("end", () => resolve(outputPath))
      .on("error", reject)
      .run();
  });
}

function resizeImageToOg(inputPath, outputPath) {
  return new Promise((resolve, reject) => {
    ffmpeg(inputPath)
      .outputOptions([
        "-vf",
        "scale=1200:630:force_original_aspect_ratio=decrease,pad=1200:630:(ow-iw)/2:(oh-ih)/2:color=black",
      ])
      .frames(1)
      .output(outputPath)
      .on("end", () => resolve(outputPath))
      .on("error", reject)
      .run();
  });
}

function transcodeToMp4(input, output, profile) {
  return new Promise((resolve, reject) => {
    ffmpeg(input)
      .videoCodec("libx264")
      .audioCodec("aac")
      .videoBitrate(profile.videoBitrate)
      .audioBitrate(profile.audioBitrate)
      .size(`${profile.width}x?`)
      .autopad()
      .outputOptions([
        "-preset",
        "fast",
        "-crf",
        "23",
        "-movflags",
        "+faststart",
      ])
      .output(output)
      .on("end", resolve)
      .on("error", reject)
      .run();
  });
}

// ── API callback ─────────────────────────────────────────────────────────────
async function notifyApi(payload) {
  const url = `${API_BASE_URL}/internal/media-complete`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-callback-secret": CALLBACK_SECRET,
    },
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`Callback failed ${res.status}: ${text}`);
  }
  return res.json();
}

// ── Utility ──────────────────────────────────────────────────────────────────
function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// ── Graceful shutdown ────────────────────────────────────────────────────────
process.on("SIGTERM", async () => {
  console.log("[media-worker] Shutting down...");
  await redis.quit().catch(() => {});
  process.exit(0);
});

start().catch((err) => {
  console.error("[media-worker] Fatal startup error:", err);
  process.exit(1);
});
