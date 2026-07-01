"use strict";
// ─────────────────────────────────────────────────────────────────────────────
// DFC A/B Results Aggregation — Cloud Function
//
// Called by Cloud Scheduler every 15 minutes.
// Reads experiment_events from Firestore, computes conversion rates per variant,
// and writes structured logs for Cloud Monitoring + emits Prometheus-compatible
// metric logs that the server can ingest.
//
// Also updates `experiments/{id}` with latest aggregated stats so the admin
// UI can display results without re-querying all events.
// ─────────────────────────────────────────────────────────────────────────────

const { onRequest } = require("firebase-functions/v2/https");
const { db, REGION } = require("../config");

const abResultsAggregation = onRequest({ region: REGION }, async (req, res) => {
  if (req.method !== "POST" && req.method !== "GET") {
    return res.status(405).json({ error: "POST or GET only" });
  }

  const updateMetrics = req.body?.updateMetrics !== false;

  // Fetch all active experiments
  const experimentsSnap = await db
    .collection("experiments")
    .where("active", "==", true)
    .get();

  if (experimentsSnap.empty) {
    return res.json({ ok: true, message: "No active experiments", processed: 0 });
  }

  const results = [];

  for (const expDoc of experimentsSnap.docs) {
    const experiment = expDoc.data();
    const experimentId = expDoc.id;

    // Fetch events for this experiment
    const eventsSnap = await db
      .collection("experiment_events")
      .where("experimentId", "==", experimentId)
      .get();

    const stats = {};

    for (const v of experiment.variants || []) {
      stats[v.id] = {
        variantId: v.id,
        label: v.label || v.id,
        impressions: 0,
        conversions: 0,
        conversionRate: 0,
      };
    }

    for (const eventDoc of eventsSnap.docs) {
      const e = eventDoc.data();
      if (!stats[e.variantId]) {
        stats[e.variantId] = {
          variantId: e.variantId,
          label: e.variantId,
          impressions: 0,
          conversions: 0,
          conversionRate: 0,
        };
      }
      if (e.eventType === "impression") stats[e.variantId].impressions++;
      if (e.eventType === "conversion") stats[e.variantId].conversions++;
    }

    for (const s of Object.values(stats)) {
      s.conversionRate = s.impressions > 0
        ? Number((s.conversions / s.impressions).toFixed(4))
        : 0;
    }

    // Detect winner
    const qualified = Object.values(stats).filter((s) => s.impressions >= 10);
    const winner = qualified.length > 0
      ? qualified.reduce((best, s) => (s.conversionRate > best.conversionRate ? s : best), qualified[0])
      : null;

    // Persist aggregated stats to experiment doc
    await expDoc.ref.update({
      aggregatedStats: Object.values(stats),
      winner: winner ? { variantId: winner.variantId, conversionRate: winner.conversionRate } : null,
      lastAggregatedAt: new Date().toISOString(),
    });

    // Emit structured metric log for each variant (Cloud Monitoring picks these up)
    if (updateMetrics) {
      for (const s of Object.values(stats)) {
        console.log(
          JSON.stringify({
            severity: "INFO",
            metric: "ab_offer_acceptance_rate",
            service: "abResultsAggregation",
            experimentId,
            variantId: s.variantId,
            conversionRate: s.conversionRate,
            impressions: s.impressions,
            conversions: s.conversions,
            ts: new Date().toISOString(),
          })
        );
      }
    }

    results.push({
      experimentId,
      variants: Object.values(stats),
      winner: winner ? { variantId: winner.variantId, conversionRate: winner.conversionRate } : null,
    });
  }

  console.log(
    JSON.stringify({
      severity: "INFO",
      metric: "ab_aggregation_run",
      service: "abResultsAggregation",
      experimentsProcessed: results.length,
      ts: new Date().toISOString(),
    })
  );

  return res.json({ ok: true, processed: results.length, results });
});

module.exports = { abResultsAggregation };
