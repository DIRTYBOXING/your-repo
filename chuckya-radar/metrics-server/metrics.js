/**
 * ╔══════════════════════════════════════════════════════════════╗
 * ║  DFC CHUCKYA — Prometheus Metrics Exporter                  ║
 * ║  Instruments the ingest/verification pipeline for Grafana   ║
 * ╚══════════════════════════════════════════════════════════════╝
 */
"use strict";

const client = require("prom-client");
const express = require("express");

const register = client.register;
client.collectDefaultMetrics({ register });

// ─── Custom metrics ───
const alertsCounter = new client.Counter({
  name: "radar_alerts_total",
  help: "Total alerts ingested",
  labelNames: ["mode"],
});

const signatureTotal = new client.Counter({
  name: "radar_signature_total",
  help: "Total signature verification attempts",
});

const signatureVerified = new client.Counter({
  name: "radar_signature_verified_total",
  help: "Total successful signature verifications",
});

const consentLocationTrue = new client.Counter({
  name: "radar_consent_location_true_total",
  help: "Events where user granted location consent",
});

const falsePositiveCounter = new client.Counter({
  name: "radar_false_positive_total",
  help: "Alerts marked as false positives",
});

const ingestLatency = new client.Histogram({
  name: "radar_ingest_latency_seconds",
  help: "Ingest-to-stored latency in seconds",
  buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2, 5],
});

const wsClientsGauge = new client.Gauge({
  name: "radar_ws_clients_connected",
  help: "Current number of connected WebSocket clients",
});

const pendingApprovalsGauge = new client.Gauge({
  name: "radar_pending_approvals",
  help: "Number of evidence exports pending approval",
});

// ─── Express app for /metrics endpoint ───
const app = express();

app.get("/healthz", (_req, res) =>
  res.json({ status: "ok", service: "chuckya-metrics" }),
);

app.get("/metrics", async (_req, res) => {
  res.set("Content-Type", register.contentType);
  res.end(await register.metrics());
});

// Start standalone if run directly
if (require.main === module) {
  const PORT = process.env.METRICS_PORT || 9091;
  app.listen(PORT, () => {
    console.log(`[metrics] Prometheus exporter on :${PORT}/metrics`);
  });
}

module.exports = {
  metricsApp: app,
  metrics: {
    alertsCounter,
    signatureTotal,
    signatureVerified,
    consentLocationTrue,
    falsePositiveCounter,
    ingestLatency,
    wsClientsGauge,
    pendingApprovalsGauge,
  },
};
