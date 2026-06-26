// ═══════════════════════════════════════════════════════════════════════════
// DFC Prometheus Metrics
// Mounted by server/index.js:  app.use(metricsApp)
//
// Exposes:  GET /metrics  (Prometheus text format)
// Default metrics: CPU, memory, event loop lag, GC, etc. via prom-client
// Custom metrics:  BullMQ queue depths, active jobs
// ═══════════════════════════════════════════════════════════════════════════

"use strict";

const client = require("prom-client");
const express = require("express");

let firestoreDb = null;

// ── Prometheus registry ──────────────────────────────────────────────────────

const registry = new client.Registry();
registry.setDefaultLabels({ app: "dfc-platform" });
client.collectDefaultMetrics({ register: registry });

// ── Custom metrics ───────────────────────────────────────────────────────────

const queueGauge = new client.Gauge({
  name: "dfc_queue_depth",
  help: "Number of jobs in each BullMQ queue state",
  labelNames: ["queue", "state"],
  registers: [registry],
});

const httpRequestDuration = new client.Histogram({
  name: "dfc_http_request_duration_ms",
  help: "HTTP request duration in milliseconds",
  labelNames: ["method", "route", "status"],
  buckets: [5, 10, 25, 50, 100, 250, 500, 1000, 2500],
  registers: [registry],
});

const serviceHealthGauge = new client.Gauge({
  name: "dfc_service_health",
  help: "1 if the service is healthy, 0 if down",
  labelNames: ["service"],
  registers: [registry],
});

const purchaseAttempts = new client.Counter({
  name: "dfc_purchase_attempts_total",
  help: "Total purchase attempts initiated from PPV commerce flows",
  labelNames: ["source"],
  registers: [registry],
});

const purchaseSuccess = new client.Counter({
  name: "dfc_purchase_success_total",
  help: "Total successful purchases from webhook or checkout confirmation",
  labelNames: ["source"],
  registers: [registry],
});

const entitlementGranted = new client.Counter({
  name: "dfc_entitlement_granted_total",
  help: "Total entitlements granted for PPV content",
  labelNames: ["source"],
  registers: [registry],
});

const watchStarted = new client.Counter({
  name: "dfc_watch_started_total",
  help: "Total watch-start events for PPV sessions",
  labelNames: ["source"],
  registers: [registry],
});

const walletTopup = new client.Counter({
  name: "dfc_wallet_topup_total",
  help: "Total wallet topups completed",
  labelNames: ["provider", "source"],
  registers: [registry],
});

const walletSpend = new client.Counter({
  name: "dfc_wallet_spend_total",
  help: "Total wallet micropurchase debits",
  labelNames: ["source"],
  registers: [registry],
});

const walletBalanceCents = new client.Gauge({
  name: "dfc_wallet_balance_cents",
  help: "Current in-memory wallet balance in cents by user and currency",
  labelNames: ["user", "currency"],
  registers: [registry],
});

const webhookVerification = new client.Counter({
  name: "dfc_webhook_verification_total",
  help: "Webhook verification outcomes by provider",
  labelNames: ["provider", "result"],
  registers: [registry],
});

const checkoutSessions = new client.Counter({
  name: "ppv_checkout_sessions_total",
  help: "Total PPV checkout session creations",
  labelNames: ["provider", "source"],
  registers: [registry],
});

const checkoutSuccess = new client.Counter({
  name: "ppv_checkout_success_total",
  help: "Total PPV checkout completions",
  labelNames: ["provider", "source"],
  registers: [registry],
});

const webhookSignatureFailures = new client.Counter({
  name: "webhook_signature_failures_total",
  help: "Total webhook signature validation failures",
  labelNames: ["provider", "reason"],
  registers: [registry],
});

// ── Performance metrics ──────────────────────────────────────────────────────

const playerStartupMs = new client.Histogram({
  name: "dfc_player_startup_ms",
  help: "Time in ms from watch_started event to first frame (player startup)",
  labelNames: ["quality", "source"],
  buckets: [250, 500, 1000, 2000, 3000, 5000, 10000],
  registers: [registry],
});

const firstByteMs = new client.Histogram({
  name: "dfc_first_byte_ms",
  help: "Time to first byte for PPV API responses",
  labelNames: ["route"],
  buckets: [10, 25, 50, 100, 250, 500, 1000, 2500],
  registers: [registry],
});

const rebufferRate = new client.Gauge({
  name: "dfc_rebuffer_rate",
  help: "Current rebuffer rate (stall seconds / play seconds) per session cohort",
  labelNames: ["quality"],
  registers: [registry],
});

// ── Reliability metrics ───────────────────────────────────────────────────────

const webhookErrors = new client.Counter({
  name: "dfc_webhook_errors_total",
  help: "Total webhook processing errors (DLQ enqueues)",
  labelNames: ["reason"],
  registers: [registry],
});

const dlqSize = new client.Gauge({
  name: "dfc_dlq_size",
  help: "Current number of items in the webhook dead-letter queue",
  labelNames: ["status"],
  registers: [registry],
});

const entitlementLatency = new client.Histogram({
  name: "dfc_entitlement_latency_ms",
  help: "Time in ms from purchase_success event to entitlement_granted",
  labelNames: ["source"],
  buckets: [50, 100, 250, 500, 1000, 2500, 5000],
  registers: [registry],
});

const entitlementGrantLatencySeconds = new client.Histogram({
  name: "entitlement_grant_latency_seconds",
  help: "Latency in seconds to grant entitlement after webhook/capture processing starts",
  labelNames: ["provider", "source"],
  buckets: [0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2, 5],
  registers: [registry],
});

const posterGenerationDurationSeconds = new client.Histogram({
  name: "poster_generation_duration_seconds",
  help: "Poster/media generation completion duration in seconds",
  labelNames: ["source", "status"],
  buckets: [0.1, 0.25, 0.5, 1, 2, 5, 10, 30, 60],
  registers: [registry],
});

const posterGenerationErrors = new client.Counter({
  name: "poster_generation_errors_total",
  help: "Total poster/media generation failures",
  labelNames: ["source", "reason"],
  registers: [registry],
});

// ── Reconciliation metrics ────────────────────────────────────────────────────

const walletReconciliationMismatchRatio = new client.Gauge({
  name: "dfc_wallet_reconciliation_mismatch_ratio",
  help: "Ratio of reconciliation mismatches (mismatches / total accounts checked) in the latest run",
  labelNames: ["run_id"],
  registers: [registry],
});

const walletReconciliationRunsTotal = new client.Counter({
  name: "dfc_wallet_reconciliation_runs_total",
  help: "Total reconciliation job runs completed",
  labelNames: ["status"],
  registers: [registry],
});

const walletReconciliationMismatchCents = new client.Gauge({
  name: "dfc_wallet_reconciliation_mismatch_cents",
  help: "Total absolute discrepancy in cents across all mismatches in the latest run",
  labelNames: ["run_id"],
  registers: [registry],
});

// ── AI-ops metrics ────────────────────────────────────────────────────────────

const offerGenerationMs = new client.Histogram({
  name: "dfc_offer_generation_ms",
  help: "Time in ms to generate an AI offer (Gemini + fallback path)",
  labelNames: ["path"],
  buckets: [100, 250, 500, 1000, 2000, 5000],
  registers: [registry],
});

const offerAcceptanceRate = new client.Gauge({
  name: "dfc_offer_acceptance_rate",
  help: "Rolling offer acceptance rate (accepted / shown) per variant",
  labelNames: ["variant", "experimentId"],
  registers: [registry],
});

// ── Analytics emit counter (per event type) ───────────────────────────────────

const analyticsEmitted = new client.Counter({
  name: "dfc_analytics_emitted_total",
  help: "Total analytics events emitted via /api/analytics/emit",
  labelNames: ["event", "source"],
  registers: [registry],
});

function getFirestoreDb() {
  if (firestoreDb) return firestoreDb;

  try {
    const admin = require("firebase-admin");
    if (!admin.apps.length) {
      admin.initializeApp();
    }
    firestoreDb = admin.firestore();
  } catch {
    firestoreDb = null;
  }

  return firestoreDb;
}

// ── Queue depth polling ──────────────────────────────────────────────────────

function pollQueueDepths() {
  // Dynamic import so the metrics file doesn't hard-crash if ioredis is absent
  let Redis;
  try {
    Redis = require("ioredis");
  } catch {
    return;
  }

  const redis = new Redis({
    host: process.env.REDIS_HOST || "redis",
    port: Number(process.env.REDIS_PORT || 6379),
    connectTimeout: 3000,
    maxRetriesPerRequest: 1,
    lazyConnect: true,
  });

  redis
    .connect()
    .then(() =>
      Promise.all([
        redis.llen("bull:auto-clip:wait"),
        redis.llen("bull:auto-clip:active"),
        redis.zcard("bull:auto-clip:failed"),
        redis.zcard("bull:auto-clip:completed"),
      ]),
    )
    .then(([waiting, active, failed, completed]) => {
      queueGauge.set({ queue: "auto-clip", state: "waiting" }, waiting);
      queueGauge.set({ queue: "auto-clip", state: "active" }, active);
      queueGauge.set({ queue: "auto-clip", state: "failed" }, failed);
      queueGauge.set({ queue: "auto-clip", state: "completed" }, completed);
    })
    .catch(() => {
      // Redis unreachable — metrics will just be stale, not fatal
    })
    .finally(() => {
      redis.disconnect();
    });
}

async function pollPpvFirestoreMetrics() {
  const db = getFirestoreDb();
  if (!db) return;

  try {
    const [dlqSnap, experimentsSnap] = await Promise.all([
      db.collection("webhook_dlq").get(),
      db.collection("experiments").where("active", "==", true).get(),
    ]);

    const dlqCounts = {};
    for (const doc of dlqSnap.docs) {
      const status = doc.data().status || "pending";
      dlqCounts[status] = (dlqCounts[status] || 0) + 1;
    }

    dlqSize.reset();
    for (const [status, count] of Object.entries(dlqCounts)) {
      dlqSize.set({ status }, count);
    }

    offerAcceptanceRate.reset();
    for (const doc of experimentsSnap.docs) {
      const experimentId = doc.id;
      const aggregatedStats = doc.data().aggregatedStats || [];
      for (const stat of aggregatedStats) {
        if (!stat?.variantId) continue;
        offerAcceptanceRate.set(
          { variant: stat.variantId, experimentId },
          Number(stat.conversionRate || 0),
        );
      }
    }
  } catch {
    // Firestore unavailable or collections absent — leave last scrape values in place.
  }
}

pollQueueDepths();
setTimeout(() => {
  void pollPpvFirestoreMetrics();
}, 0).unref();

// Poll every 15 seconds (don't overwhelm Redis)
setInterval(pollQueueDepths, 15_000).unref();
// Poll PPV state every 30 seconds to keep Grafana gauges hydrated from Firestore.
setInterval(() => {
  pollPpvFirestoreMetrics().catch(() => {});
}, 30_000).unref();

// ── Express app ──────────────────────────────────────────────────────────────

const metricsApp = express.Router();

// Request duration instrumentation — call this middleware before your routes
metricsApp.use((req, res, next) => {
  const end = httpRequestDuration.startTimer();
  res.on("finish", () => {
    end({
      method: req.method,
      route: req.route?.path || req.path,
      status: res.statusCode,
    });
  });
  next();
});

metricsApp.get("/metrics", async (req, res) => {
  try {
    res.set("Content-Type", registry.contentType);
    res.end(await registry.metrics());
  } catch (err) {
    res.status(500).end(err.message);
  }
});

const ppvCommerceMetrics = {
  purchaseAttempts,
  purchaseSuccess,
  entitlementGranted,
  watchStarted,
  walletTopup,
  walletSpend,
  walletBalanceCents,
  webhookVerification,
  checkoutSessions,
  checkoutSuccess,
  webhookSignatureFailures,
  playerStartupMs,
  firstByteMs,
  rebufferRate,
  webhookErrors,
  dlqSize,
  entitlementLatency,
  entitlementGrantLatencySeconds,
  posterGenerationDurationSeconds,
  posterGenerationErrors,
  walletReconciliationMismatchRatio,
  walletReconciliationRunsTotal,
  walletReconciliationMismatchCents,
  offerGenerationMs,
  offerAcceptanceRate,
  analyticsEmitted,
};

module.exports = {
  metricsApp,
  registry,
  queueGauge,
  serviceHealthGauge,
  ppvCommerceMetrics,
};
