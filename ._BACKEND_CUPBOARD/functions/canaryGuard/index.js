// functions/canaryGuard/index.js
// ─────────────────────────────────────────────────────────────────────────────
// Canary Guard — automated rollback + alert on KPI breach
//
// Triggers:
//   1. Cloud Scheduler → Pub/Sub → onMessagePublished (every 2 min while canary active)
//   2. Callable from ops tooling: callCanaryGuard({ action: 'pause' | 'resume' | 'status' })
//
// KPIs evaluated (all thresholds configurable via Firestore /config/canaryGuard):
//   - playback_success_rate  < threshold → pause
//   - token_error_rate       > threshold → pause
//   - dlq_size               > threshold → pause
//   - license_p95_ms         > threshold → pause
//
// On breach:
//   1. Sets promotion_config.canary_percent = 0 in Firestore
//   2. Pauses all active promotions (sets status='paused')
//   3. Writes incident doc to /incidents collection
//   4. Notifies Slack (SLACK_CANARY_WEBHOOK env var)
// ─────────────────────────────────────────────────────────────────────────────
"use strict";

const { onMessagePublished } = require("firebase-functions/v2/pubsub");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getApps, initializeApp } = require("firebase-admin/app");

if (!getApps().length) initializeApp();

const db = getFirestore();

// ── Default KPI thresholds (overridable via Firestore /config/canaryGuard) ───
const DEFAULT_THRESHOLDS = {
  playback_success_rate_min: 0.95, // pause if below 95 %
  token_error_rate_max: 0.05, // pause if above 5 %
  dlq_size_max: 50, // pause if DLQ > 50
  license_p95_ms_max: 3000, // pause if license p95 > 3 s
};

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

async function loadThresholds() {
  const snap = await db.doc("config/canaryGuard").get();
  return { ...DEFAULT_THRESHOLDS, ...(snap.exists ? snap.data() : {}) };
}

/**
 * Read the latest KPI window from Firestore.
 * Callers (monitoring pipeline, promotion-worker) write to:
 *   /kpi_snapshots/{windowId}  { ts, playback_success_rate, token_error_rate,
 *                                 dlq_size, license_p95_ms }
 */
async function latestKpiSnapshot() {
  const snap = await db
    .collection("kpi_snapshots")
    .orderBy("ts", "desc")
    .limit(1)
    .get();
  if (snap.empty) return null;
  return snap.docs[0].data();
}

async function getCurrentCanaryPercent() {
  const snap = await db.doc("promotion_config/global").get();
  return snap.exists ? (snap.data().canary_percent ?? 0) : 0;
}

async function setCanaryPercent(percent, reason) {
  await db.doc("promotion_config/global").set(
    {
      canary_percent: percent,
      updated_at: FieldValue.serverTimestamp(),
      last_guard_action: reason,
    },
    { merge: true },
  );
}

async function pauseActivePromotions(reason) {
  const active = await db
    .collection("promotions")
    .where("status", "==", "active")
    .get();
  const batch = db.batch();
  active.docs.forEach((d) =>
    batch.update(d.ref, {
      status: "paused",
      paused_reason: reason,
      paused_at: FieldValue.serverTimestamp(),
    }),
  );
  await batch.commit();
  return active.size;
}

async function writeIncident({ kpi, threshold, actual, reason }) {
  const ref = db.collection("incidents").doc();
  await ref.set({
    id: ref.id,
    type: "canary_rollback",
    kpi,
    threshold,
    actual,
    reason,
    created_at: FieldValue.serverTimestamp(),
    resolved: false,
  });
  return ref.id;
}

async function notifySlack(message) {
  const url = process.env.SLACK_CANARY_WEBHOOK;
  if (!url) return;
  try {
    await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ text: message }),
    });
  } catch (err) {
    console.error("[canaryGuard] Slack notify failed:", err.message);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Core evaluation
// ─────────────────────────────────────────────────────────────────────────────

async function evaluateAndMaybeRollback() {
  const [thresholds, kpi, canaryPct] = await Promise.all([
    loadThresholds(),
    latestKpiSnapshot(),
    getCurrentCanaryPercent(),
  ]);

  if (canaryPct === 0) {
    console.log("[canaryGuard] canary_percent already 0 — nothing to do.");
    return { action: "skipped", reason: "already_zero" };
  }

  if (!kpi) {
    console.warn("[canaryGuard] No KPI snapshot found — skipping evaluation.");
    return { action: "skipped", reason: "no_kpi_data" };
  }

  // Evaluate breach conditions
  const breaches = [];

  if (
    kpi.playback_success_rate != null &&
    kpi.playback_success_rate < thresholds.playback_success_rate_min
  ) {
    breaches.push({
      kpi: "playback_success_rate",
      threshold: thresholds.playback_success_rate_min,
      actual: kpi.playback_success_rate,
    });
  }
  if (
    kpi.token_error_rate != null &&
    kpi.token_error_rate > thresholds.token_error_rate_max
  ) {
    breaches.push({
      kpi: "token_error_rate",
      threshold: thresholds.token_error_rate_max,
      actual: kpi.token_error_rate,
    });
  }
  if (kpi.dlq_size != null && kpi.dlq_size > thresholds.dlq_size_max) {
    breaches.push({
      kpi: "dlq_size",
      threshold: thresholds.dlq_size_max,
      actual: kpi.dlq_size,
    });
  }
  if (
    kpi.license_p95_ms != null &&
    kpi.license_p95_ms > thresholds.license_p95_ms_max
  ) {
    breaches.push({
      kpi: "license_p95_ms",
      threshold: thresholds.license_p95_ms_max,
      actual: kpi.license_p95_ms,
    });
  }

  if (breaches.length === 0) {
    console.log("[canaryGuard] All KPIs healthy.");
    return { action: "ok", kpi };
  }

  // ── Rollback ──────────────────────────────────────────────────────────────
  const primary = breaches[0];
  const reason = `KPI breach: ${primary.kpi} = ${primary.actual} (threshold ${primary.threshold})`;
  console.warn(
    `[canaryGuard] ${breaches.length} breach(es) detected. Rolling back.`,
    breaches,
  );

  const [incidentId, pausedCount] = await Promise.all([
    writeIncident({ ...primary, reason }),
    pauseActivePromotions(reason),
    setCanaryPercent(0, reason),
  ]);

  const slackMsg = [
    `🚨 *DFC Canary Rollback* — ${new Date().toISOString()}`,
    `Breaches: ${breaches.map((b) => `\`${b.kpi}\` (actual ${b.actual}, limit ${b.threshold})`).join(", ")}`,
    `Actions: canary_percent → 0, ${pausedCount} promotion(s) paused`,
    `Incident ID: \`${incidentId}\``,
    `Resolve in Firestore: \`/incidents/${incidentId}\` → set \`resolved: true\`, then resume manually.`,
  ].join("\n");

  await notifySlack(slackMsg);

  return { action: "rollback", breaches, incidentId, pausedCount };
}

// ─────────────────────────────────────────────────────────────────────────────
// Exports
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Scheduled trigger: Cloud Scheduler → Pub/Sub topic `canary-guard-tick`
 * Set schedule to: every 2 minutes (every-2-min cron)
 */
exports.canaryGuardScheduled = onMessagePublished(
  { topic: "canary-guard-tick", region: "australia-southeast1" },
  async (_event) => {
    const result = await evaluateAndMaybeRollback();
    console.log("[canaryGuard] scheduled result:", JSON.stringify(result));
  },
);

/**
 * Callable: manual ops trigger
 * Accepts { action: 'evaluate' | 'pause' | 'resume' | 'status' }
 */
exports.canaryGuardCall = onCall(
  { region: "australia-southeast1" },
  async (request) => {
    const action = request.data?.action ?? "evaluate";

    if (action === "pause") {
      await setCanaryPercent(0, "manual_ops_pause");
      const paused = await pauseActivePromotions("manual_ops_pause");
      await notifySlack(
        `⏸️ *DFC Canary manually paused* by ops (${request.auth?.uid ?? "unknown"}). ${paused} promotion(s) paused.`,
      );
      return { ok: true, canary_percent: 0, paused_promotions: paused };
    }

    if (action === "resume") {
      const pct = request.data?.canary_percent ?? 10;
      if (typeof pct !== "number" || pct < 0 || pct > 100) {
        throw new HttpsError(
          "invalid-argument",
          "canary_percent must be 0–100",
        );
      }
      await setCanaryPercent(pct, `manual_ops_resume_to_${pct}`);
      await notifySlack(
        `▶️ *DFC Canary resumed* to ${pct}% by ops (${request.auth?.uid ?? "unknown"}).`,
      );
      return { ok: true, canary_percent: pct };
    }

    if (action === "status") {
      const [pct, kpi, thresholds] = await Promise.all([
        getCurrentCanaryPercent(),
        latestKpiSnapshot(),
        loadThresholds(),
      ]);
      return { canary_percent: pct, latest_kpi: kpi, thresholds };
    }

    // default: evaluate
    return evaluateAndMaybeRollback();
  },
);
