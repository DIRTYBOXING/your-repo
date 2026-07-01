// server/internalRoutes.js
// ═══════════════════════════════════════════════════════════════════════════
// Internal endpoints — NOT publicly reachable (firewall/VPC only in prod)
// ═══════════════════════════════════════════════════════════════════════════
"use strict";

const express = require("express");
const { v4: uuid } = require("uuid");
const router = express.Router();
const { ppvCommerceMetrics } = require("./monitoring/server/metrics");

// Share state with apiStubs via a simple module-level singleton.
// In production these would be database reads/writes.
const { posts, mediaJobs, audit } = require("./apiState");

function normalizeVariants(variants) {
  return variants && typeof variants === "object" && !Array.isArray(variants)
    ? variants
    : {};
}

function observeMediaCompletionMetrics(job, finalStatus) {
  if (!Number.isFinite(job?.enqueuedAt)) {
    return;
  }

  const durationSeconds = Math.max(
    0,
    (Date.now() - Number(job.enqueuedAt)) / 1000,
  );
  ppvCommerceMetrics.posterGenerationDurationSeconds.observe(
    { source: "media_worker", status: finalStatus },
    durationSeconds,
  );

  if (finalStatus === "failed") {
    ppvCommerceMetrics.posterGenerationErrors.inc({
      source: "media_worker",
      reason: "media_complete_failed",
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// POST /internal/media-complete — Worker callback: media processing finished
// Requires x-callback-secret header matching WORKER_CALLBACK_SECRET env var.
// Body: { postId, jobId, ogImageUrl?, variants?, status }
// Returns: { ok, postId, mediaStatus }
// ═══════════════════════════════════════════════════════════════════════════
router.post("/media-complete", express.json(), (req, res) => {
  const secret = req.headers["x-callback-secret"];
  const expected = process.env.WORKER_CALLBACK_SECRET;
  if (!expected || secret !== expected) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  const { postId, jobId, ogImageUrl, variants, status } = req.body || {};
  if (!postId || typeof postId !== "string") {
    return res.status(400).json({ error: "postId is required" });
  }

  // Use Object.hasOwn to prevent __proto__ prototype pollution
  if (!Object.hasOwn(posts, postId)) {
    return res.status(404).json({ error: "Post not found" });
  }
  const post = posts[postId];

  const finalStatus = status === "failed" ? "failed" : "ready";
  const normalizedVariants = normalizeVariants(variants);
  post.mediaStatus = finalStatus;
  post.ogImageUrl = typeof ogImageUrl === "string" ? ogImageUrl : null;
  post.variants = normalizedVariants;
  post.updatedAt = new Date().toISOString();

  if (jobId && typeof jobId === "string" && Object.hasOwn(mediaJobs, jobId)) {
    mediaJobs[jobId].status = finalStatus;
    mediaJobs[jobId].completedAt = Date.now();
    mediaJobs[jobId].retryEligible = false;
    mediaJobs[jobId].result = {
      ogImageUrl: typeof ogImageUrl === "string" ? ogImageUrl : null,
      variants: normalizedVariants,
    };
    observeMediaCompletionMetrics(mediaJobs[jobId], finalStatus);
  }

  audit.push({
    id: uuid(),
    action: "media_complete",
    postId,
    jobId,
    status: finalStatus,
    ts: Date.now(),
  });
  return res.json({ ok: true, postId, mediaStatus: finalStatus });
});

module.exports = router;
