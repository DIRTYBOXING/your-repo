#!/usr/bin/env node
// scripts/test-job-runner.js
// ═══════════════════════════════════════════════════════════════════════════
// DFC Media Pipeline — End-to-End Test Harness
//
// Usage:
//   node scripts/test-job-runner.js --file ./test.mp4 --user <userId>
//
// What it does:
//   1. Calls POST /api/uploads/sign  → gets a signed URL + uploadId + key
//   2. Simulates an S3 upload        (logs the signed URL; real PUT via fetch)
//   3. Calls POST /api/posts         → creates a post record + enqueues job
//   4. Pushes the job onto Redis     (dfc:media-jobs) for the worker to pick up
//   5. Polls GET /api/posts/:id      → waits for media_status === 'ready'
//   6. Prints the final OG image URL + variant URLs
//
// Environment / flags:
//   --file    Path to a local test media file (required)
//   --user    DFC user ID (required)
//   --api     API base URL (default: http://localhost:4000)
//   --redis   Redis URL    (default: redis://localhost:6379)
// ═══════════════════════════════════════════════════════════════════════════
"use strict";

const fs = require("fs");
const path = require("path");

// ── Parse CLI args ────────────────────────────────────────────────────────
const args = process.argv.slice(2);
function getArg(name) {
  const idx = args.indexOf(`--${name}`);
  return idx !== -1 ? args[idx + 1] : null;
}

const filePath = getArg("file");
const userId = getArg("user");
const API_BASE = (
  getArg("api") ||
  process.env.API_BASE_URL ||
  "http://localhost:4000"
).replace(/\/$/, "");
const REDIS_URL =
  getArg("redis") || process.env.REDIS_URL || "redis://localhost:6379";

if (!filePath || !userId) {
  console.error(
    "Usage: node scripts/test-job-runner.js --file <path> --user <userId>",
  );
  process.exit(1);
}

if (!fs.existsSync(filePath)) {
  console.error(`File not found: ${filePath}`);
  process.exit(1);
}

const filename = path.basename(filePath);
const ext = filename.split(".").pop().toLowerCase();
const contentType =
  ext === "mp4"
    ? "video/mp4"
    : ext === "mov"
      ? "video/quicktime"
      : ext === "webm"
        ? "video/webm"
        : ext === "jpg" || ext === "jpeg"
          ? "image/jpeg"
          : ext === "png"
            ? "image/png"
            : ext === "webp"
              ? "image/webp"
              : "application/octet-stream";
const fileSizeBytes = fs.statSync(filePath).size;

// ── Helpers ──────────────────────────────────────────────────────────────
async function apiFetch(method, endpoint, body) {
  const res = await fetch(`${API_BASE}${endpoint}`, {
    method,
    headers: { "Content-Type": "application/json" },
    body: body ? JSON.stringify(body) : undefined,
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok)
    throw new Error(
      `${method} ${endpoint} → ${res.status}: ${JSON.stringify(data)}`,
    );
  return data;
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function log(icon, ...args) {
  console.log(`${icon}`, ...args);
}

// ── Main test flow ────────────────────────────────────────────────────────
async function run() {
  log("🚀", "DFC Media Pipeline Test Harness");
  log("   File   :", filePath, `(${(fileSizeBytes / 1024).toFixed(1)} KB)`);
  log("   User   :", userId);
  log("   API    :", API_BASE);
  log("   Redis  :", REDIS_URL);
  console.log();

  // ── Step 1: Get signed upload URL ─────────────────────────────────────
  log("1️⃣ ", "Requesting signed upload URL...");
  const signRes = await apiFetch("POST", "/api/uploads/sign", {
    filename,
    contentType,
    fileSizeBytes,
    userId,
  });
  log("   ✔ uploadId :", signRes.uploadId);
  log("   ✔ key      :", signRes.key);
  log("   ✔ signedUrl:", signRes.signedUrl.substring(0, 80) + "...");
  console.log();

  // ── Step 2: Simulate / perform S3 upload ──────────────────────────────
  log("2️⃣ ", "Uploading file to S3...");
  if (signRes.signedUrl.includes("stub=1")) {
    log(
      "   ⚠️  Stub signed URL detected — skipping real S3 PUT (local dev mode)",
    );
  } else {
    const fileBytes = fs.readFileSync(filePath);
    const putRes = await fetch(signRes.signedUrl, {
      method: "PUT",
      headers: { "Content-Type": contentType },
      body: fileBytes,
    });
    if (!putRes.ok) throw new Error(`S3 PUT failed: ${putRes.status}`);
    log("   ✔ Uploaded to S3");
  }
  console.log();

  // ── Step 3: Create post and enqueue job ───────────────────────────────
  log("3️⃣ ", "Creating post and enqueuing media job...");
  const postRes = await apiFetch("POST", "/api/posts", {
    userId,
    content: `Test post from test-job-runner — ${new Date().toISOString()}`,
    uploadId: signRes.uploadId,
    key: signRes.key,
  });
  log("   ✔ postId   :", postRes.postId);
  log("   ✔ jobId    :", postRes.jobId);
  log("   ✔ status   :", postRes.status);
  console.log();

  // ── Step 4: Push job to Redis for the worker ──────────────────────────
  log("4️⃣ ", "Pushing job to Redis queue (dfc:media-jobs)...");
  let redisClient;
  try {
    const { createClient } = require("redis");
    redisClient = createClient({ url: REDIS_URL });
    await redisClient.connect();
    const jobPayload = JSON.stringify({
      jobId: postRes.jobId,
      postId: postRes.postId,
      mediaKey: signRes.key,
      contentType,
    });
    await redisClient.rPush("dfc:media-jobs", jobPayload);
    await redisClient.quit();
    log("   ✔ Job pushed to Redis");
  } catch (err) {
    log("   ⚠️  Redis push failed (is Redis running?):", err.message);
    log(
      '      The API post was still created — media will stay in "pending" until the worker runs.',
    );
  }
  console.log();

  // ── Step 5: Poll for completion ───────────────────────────────────────
  log("5️⃣ ", "Waiting for worker to process media...");
  const TIMEOUT_MS = 120_000;
  const POLL_MS = 3_000;
  const start = Date.now();
  let finalPost = null;

  while (Date.now() - start < TIMEOUT_MS) {
    await sleep(POLL_MS);
    try {
      const statusRes = await apiFetch("GET", `/api/posts/${postRes.postId}`);
      process.stdout.write(`\r   Status: ${statusRes.mediaStatus}   `);
      if (
        statusRes.mediaStatus === "ready" ||
        statusRes.mediaStatus === "failed"
      ) {
        finalPost = statusRes;
        console.log();
        break;
      }
    } catch (_) {
      // endpoint may not exist yet — continue polling
    }
  }
  console.log();

  if (!finalPost) {
    log(
      "⏱️ ",
      "Timed out waiting for worker. The job may still be processing.",
    );
    log("   Check worker logs and re-run polling manually.");
    process.exit(2);
  }

  // ── Step 6: Print results ─────────────────────────────────────────────
  if (finalPost.mediaStatus === "ready") {
    log("✅", "Media processing COMPLETE");
    log("   OG Image URL :", finalPost.ogImageUrl || "(none)");
    if (finalPost.variants) {
      for (const [k, v] of Object.entries(finalPost.variants)) {
        log(`   Variant [${k}] :`, v);
      }
    }
  } else {
    log("❌", "Media processing FAILED");
  }
  console.log();
  log("🏁", "Test harness finished.");
}

run().catch((err) => {
  console.error("Test harness error:", err.message);
  process.exit(1);
});
