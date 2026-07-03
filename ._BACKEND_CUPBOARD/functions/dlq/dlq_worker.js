"use strict";
// ─────────────────────────────────────────────────────────────────────────────
// DFC Webhook DLQ — Firestore-backed dead-letter queue worker
//
// Collections:
//   webhook_dlq/{docId}  — pending/failed items
//     { orderId, payload, attempts, lastError, enqueuedAt, nextRetryAt, status }
//
// Usage:
//   const { enqueueDlq, processDlqOnce } = require('./dlq_worker');
//
// Cloud Monitoring: structured JSON logs on each reprocess or failure for
// log-based metric "webhook_dlq_reprocessed" and "webhook_dlq_exhausted".
// ─────────────────────────────────────────────────────────────────────────────

const { admin, db } = require("../config");

const DLQ_COLLECTION = "webhook_dlq";
const MAX_ATTEMPTS = 3;
const BASE_BACKOFF_MS = 60_000; // 1 minute

// ── Enqueue a failed webhook item into Firestore DLQ ─────────────────────────
async function enqueueDlq(item) {
  const orderId = item.orderId || db.collection("_").doc().id;
  const docRef = db.collection(DLQ_COLLECTION).doc(orderId);

  const existing = await docRef.get();
  const attempts = existing.exists ? (existing.data().attempts || 0) : 0;

  const backoffMs = Math.pow(2, attempts) * BASE_BACKOFF_MS;
  await docRef.set(
    {
      orderId,
      payload: item.payload || item,
      attempts,
      lastError: item.lastError || null,
      status: "pending",
      enqueuedAt: existing.exists
        ? existing.data().enqueuedAt
        : admin.firestore.FieldValue.serverTimestamp(),
      nextRetryAt: admin.firestore.Timestamp.fromMillis(
        Date.now() + backoffMs
      ),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return orderId;
}

// ── Process up to `limit` ready DLQ items (called by scheduler) ───────────────
async function processDlqOnce(webhookUrl, limit = 20) {
  const now = admin.firestore.Timestamp.now();
  const snap = await db
    .collection(DLQ_COLLECTION)
    .where("status", "==", "pending")
    .where("attempts", "<", MAX_ATTEMPTS)
    .where("nextRetryAt", "<=", now)
    .orderBy("nextRetryAt")
    .limit(limit)
    .get();

  if (snap.empty) return [];

  const results = [];

  for (const doc of snap.docs) {
    const data = doc.data();
    const currentAttempts = data.attempts || 0;
    const targetUrl =
      webhookUrl ||
      process.env.WEBHOOK_PROCESSOR_URL ||
      "http://localhost:3000/api/orders/webhook";

    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 10_000);

      const resp = await fetch(targetUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data.payload || data),
        signal: controller.signal,
      });
      clearTimeout(timeout);

      if (resp.ok) {
        await doc.ref.update({ status: "resolved", resolvedAt: admin.firestore.FieldValue.serverTimestamp() });
        console.log(
          JSON.stringify({
            severity: "INFO",
            metric: "webhook_dlq_reprocessed",
            service: "dlqWorker",
            orderId: data.orderId,
            attempts: currentAttempts + 1,
            ts: new Date().toISOString(),
          })
        );
        results.push({ id: doc.id, status: "resolved" });
      } else {
        const body = await resp.text().catch(() => "");
        await _handleRetryOrExhaust(doc, data, `HTTP ${resp.status}: ${body}`, currentAttempts);
        results.push({ id: doc.id, status: "retry_scheduled", httpStatus: resp.status });
      }
    } catch (err) {
      await _handleRetryOrExhaust(doc, data, err.message, currentAttempts);
      results.push({ id: doc.id, status: "error", error: err.message });
    }
  }

  return results;
}

async function _handleRetryOrExhaust(doc, data, errorMsg, currentAttempts) {
  const nextAttempts = currentAttempts + 1;
  if (nextAttempts >= MAX_ATTEMPTS) {
    await doc.ref.update({
      attempts: nextAttempts,
      status: "exhausted",
      lastError: errorMsg,
      exhaustedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(
      JSON.stringify({
        severity: "ERROR",
        metric: "webhook_dlq_exhausted",
        service: "dlqWorker",
        orderId: data.orderId,
        lastError: errorMsg,
        ts: new Date().toISOString(),
      })
    );
  } else {
    const backoffMs = Math.pow(2, nextAttempts) * BASE_BACKOFF_MS;
    await doc.ref.update({
      attempts: nextAttempts,
      lastError: errorMsg,
      nextRetryAt: admin.firestore.Timestamp.fromMillis(Date.now() + backoffMs),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

module.exports = { enqueueDlq, processDlqOnce };
