"use strict";
// ─────────────────────────────────────────────────────────────────────────────
// DFC Webhook DLQ — Cloud Function HTTP endpoints
//
// Exported functions:
//   dlqInspect   — GET  /dlq           list pending/exhausted DLQ items
//   dlqRetry     — POST /dlq/retry     manually trigger retry of one item
//   dlqWorkerRun — POST /dlq/run       process all ready items (call from scheduler)
// ─────────────────────────────────────────────────────────────────────────────

const { onRequest } = require("firebase-functions/v2/https");
const { db, REGION } = require("../config");
const { enqueueDlq, processDlqOnce } = require("./dlq_worker");

const DLQ_COLLECTION = "webhook_dlq";

// ── GET /dlq — list items (pending + exhausted) ────────────────────────────
const dlqInspect = onRequest({ region: REGION, cors: true }, async (req, res) => {
  if (req.method !== "GET") return res.status(405).json({ error: "GET only" });

  const status = req.query.status || null; // optional filter: pending, resolved, exhausted
  let query = db.collection(DLQ_COLLECTION).orderBy("updatedAt", "desc").limit(100);
  if (status) query = db.collection(DLQ_COLLECTION).where("status", "==", status).limit(100);

  const snap = await query.get();
  const items = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  return res.json({ count: items.length, items });
});

// ── POST /dlq/retry — manually retry a single item ────────────────────────
const dlqRetry = onRequest({ region: REGION, cors: true }, async (req, res) => {
  if (req.method !== "POST") return res.status(405).json({ error: "POST only" });

  const { id } = req.body || {};
  if (!id) return res.status(400).json({ error: "id required" });

  const docRef = db.collection(DLQ_COLLECTION).doc(id);
  const doc = await docRef.get();
  if (!doc.exists) return res.status(404).json({ error: "DLQ item not found" });

  // Reset to pending with attempts decremented to force immediate reprocess
  const data = doc.data();
  await docRef.update({
    status: "pending",
    attempts: Math.max(0, (data.attempts || 1) - 1),
    nextRetryAt: db.constructor.Timestamp
      ? db.constructor.Timestamp.now()
      : require("firebase-admin/firestore").Timestamp.now(),
  });

  const results = await processDlqOnce(null, 1);
  return res.json({ ok: true, id, results });
});

// ── POST /dlq/run — process all ready items (used by Cloud Scheduler) ──────
const dlqWorkerRun = onRequest({ region: REGION }, async (req, res) => {
  if (req.method !== "POST") return res.status(405).json({ error: "POST only" });

  const webhookUrl = req.body?.webhookUrl || null;
  const results = await processDlqOnce(webhookUrl, 50);
  console.log(
    JSON.stringify({
      severity: "INFO",
      metric: "dlq_worker_run",
      service: "dlqWorkerRun",
      processed: results.length,
      resolved: results.filter((r) => r.status === "resolved").length,
      ts: new Date().toISOString(),
    })
  );
  return res.json({ ok: true, processed: results.length, results });
});

// ── POST /dlq/enqueue — manually enqueue item (for testing / ops) ──────────
const dlqEnqueue = onRequest({ region: REGION }, async (req, res) => {
  if (req.method !== "POST") return res.status(405).json({ error: "POST only" });

  const item = req.body;
  if (!item || Object.keys(item).length === 0) {
    return res.status(400).json({ error: "Request body required" });
  }

  const id = await enqueueDlq(item);
  return res.json({ ok: true, id });
});

module.exports = { dlqInspect, dlqRetry, dlqWorkerRun, dlqEnqueue };
