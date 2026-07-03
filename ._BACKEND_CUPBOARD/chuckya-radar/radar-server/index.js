/**
 * ╔══════════════════════════════════════════════════════════════╗
 * ║  DFC CHUCKYA RADAR — API SERVER                             ║
 * ║  Top-Secret Testing Room · DataFightCentral Internal        ║
 * ║  Anti-piracy signal ingestion, scoring & evidence export    ║
 * ╚══════════════════════════════════════════════════════════════╝
 */
"use strict";

const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const { v4: uuidv4 } = require("uuid");
const archiver = require("archiver");

const { mountPoliceRoutes, appendCustodyEntry } = require("./police_export");
const { mountVerifyRoute } = require("./verify_route");
const { mountDroneRoutes } = require("./drone_control");

// ─── Prometheus metrics (optional, degrades gracefully) ───
let metrics = null;
try {
  const promClient = require("prom-client");
  const register = promClient.register;
  promClient.collectDefaultMetrics({ register });
  metrics = {
    alertsCounter: new promClient.Counter({
      name: "radar_alerts_total",
      help: "Total alerts ingested",
      labelNames: ["mode"],
    }),
    signatureTotal: new promClient.Counter({
      name: "radar_signature_total",
      help: "Signature verification attempts",
    }),
    signatureVerified: new promClient.Counter({
      name: "radar_signature_verified_total",
      help: "Successful signature verifications",
    }),
    consentLocationTrue: new promClient.Counter({
      name: "radar_consent_location_true_total",
      help: "Events with location consent",
    }),
    falsePositiveCounter: new promClient.Counter({
      name: "radar_false_positive_total",
      help: "Alerts marked false positive",
    }),
    ingestLatency: new promClient.Histogram({
      name: "radar_ingest_latency_seconds",
      help: "Ingest latency",
      buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2, 5],
    }),
  };
  console.log("[metrics] prom-client loaded — /metrics available");
} catch {
  console.log("[metrics] prom-client not installed — metrics disabled");
}

const app = express();

// --------------- Middleware ---------------
app.use(cors({ origin: true }));
app.use(bodyParser.json({ limit: "1mb" }));

// --------------- Audit directory ---------------
const AUDIT_DIR = path.resolve(__dirname, "../ops-audit");
if (!fs.existsSync(AUDIT_DIR)) fs.mkdirSync(AUDIT_DIR, { recursive: true });

// In-memory alerts store (demo / testing mode)
const alerts = {};

// --------------- Healthcheck ---------------
app.get("/healthz", (_req, res) =>
  res.json({ status: "ok", service: "chuckya-radar" }),
);

// --------------- Prometheus metrics endpoint ---------------
if (metrics) {
  const promClient = require("prom-client");
  app.get("/metrics", async (_req, res) => {
    res.set("Content-Type", promClient.register.contentType);
    res.end(await promClient.register.metrics());
  });
}

// --------------- In-memory export requests (approval system) ---------------
const exportRequests = {};

// --------------- In-memory device registry (populated from pubkeys) ---------------
function loadDeviceRegistry() {
  const pubkeysDir = path.join(AUDIT_DIR, "device_pubkeys");
  if (!fs.existsSync(pubkeysDir)) return [];
  return fs
    .readdirSync(pubkeysDir)
    .filter((f) => f.endsWith(".json"))
    .map((f) => {
      try {
        const record = JSON.parse(
          fs.readFileSync(path.join(pubkeysDir, f), "utf8"),
        );
        return {
          appInstanceId: record.appInstanceId,
          registeredAt: record.registeredAt,
          registeredFromIp: record.registeredFromIp,
          publicKeySha256: require("crypto")
            .createHash("sha256")
            .update(record.publicKey || "")
            .digest("hex")
            .slice(0, 16),
          lastSeen: record.lastSeen || null,
          status: record.lastSeen
            ? Date.now() - new Date(record.lastSeen).getTime() < 60000
              ? "online"
              : Date.now() - new Date(record.lastSeen).getTime() < 300000
                ? "stale"
                : "offline"
            : "offline",
        };
      } catch {
        return null;
      }
    })
    .filter(Boolean);
}

// --------------- Device fleet endpoint ---------------
app.get("/v1/devices", (_req, res) => {
  res.json({ devices: loadDeviceRegistry() });
});

// --------------- Export approval system ---------------
app.get("/v1/radar/exports/pending", (_req, res) => {
  const list = Object.values(exportRequests).sort(
    (a, b) => new Date(b.requestedAt) - new Date(a.requestedAt),
  );
  res.json({ exports: list });
});

app.post("/v1/radar/exports/:alertId/request", (req, res) => {
  const alertId = req.params.alertId;
  if (!alerts[alertId])
    return res.status(404).json({ error: "Alert not found" });
  const requestedBy = req.body.requestedBy || req.ip || "unknown";

  exportRequests[alertId] = {
    alertId,
    requestedAt: new Date().toISOString(),
    requestedBy: String(requestedBy).slice(0, 128),
    mode: alerts[alertId].mode || alerts[alertId].type || "unknown",
    riskScore: alerts[alertId].riskScore || 0,
    status: "pending",
  };

  res.json({ status: "requested", alertId });
});

app.post("/v1/radar/exports/:alertId/approve", (req, res) => {
  const alertId = req.params.alertId;
  const entry = exportRequests[alertId];
  if (!entry)
    return res.status(404).json({ error: "No pending export for this alert" });

  const approvedBy =
    req.body.approvedBy || req.headers["x-dfc-approver"] || req.ip || "unknown";
  entry.status = "approved";
  entry.approvedBy = String(approvedBy).slice(0, 128);
  entry.approvedAt = new Date().toISOString();

  // Audit
  const logLine = `[${entry.approvedAt}] EXPORT_APPROVED ${alertId} by:${approvedBy}\n`;
  fs.appendFileSync(path.join(AUDIT_DIR, "access.log"), logLine);

  res.json({ status: "approved", alertId, approvedBy });
});

app.post("/v1/radar/exports/:alertId/reject", (req, res) => {
  const alertId = req.params.alertId;
  const entry = exportRequests[alertId];
  if (!entry)
    return res.status(404).json({ error: "No pending export for this alert" });

  const rejectedBy = req.body.rejectedBy || req.ip || "unknown";
  entry.status = "rejected";
  entry.rejectedBy = String(rejectedBy).slice(0, 128);
  entry.rejectedAt = new Date().toISOString();

  const logLine = `[${entry.rejectedAt}] EXPORT_REJECTED ${alertId} by:${rejectedBy}\n`;
  fs.appendFileSync(path.join(AUDIT_DIR, "access.log"), logLine);

  res.json({ status: "rejected", alertId });
});

// --------------- Ingest endpoint ---------------
app.post("/v1/radar/event", (req, res) => {
  const payload = req.body;

  // Basic input validation
  const allowedTypes = [
    "piracy",
    "restream",
    "credential_sharing",
    "watermark_match",
    "manual",
  ];
  const type = allowedTypes.includes(payload.type) ? payload.type : "manual";
  const riskScore = Math.max(0, Math.min(100, Number(payload.riskScore) || 60));

  // Threat mode for Control Room color coding
  const allowedModes = ["code_black", "code_red", "code_amber", "code_yellow"];
  const mode = allowedModes.includes(payload.mode)
    ? payload.mode
    : riskScore >= 90
      ? "code_black"
      : riskScore >= 70
        ? "code_red"
        : riskScore >= 40
          ? "code_amber"
          : "code_yellow";

  const id = `R-${Date.now()}`;
  const alert = {
    alertId: id,
    createdAt: new Date().toISOString(),
    status: "open",
    mode,
    riskScore,
    type,
    sessionId:
      typeof payload.sessionId === "string"
        ? payload.sessionId.slice(0, 128)
        : uuidv4(),
    source:
      typeof payload.source === "string"
        ? payload.source.slice(0, 64)
        : "unknown",
    topSignals: Array.isArray(payload.topSignals)
      ? payload.topSignals.slice(0, 10).map((s) => String(s).slice(0, 128))
      : [],
    evidence: [], // evidence paths are server-controlled, not user-supplied
    metadata: {
      eventId:
        typeof payload.eventId === "string"
          ? payload.eventId.slice(0, 128)
          : null,
      userId:
        typeof payload.userId === "string"
          ? payload.userId.slice(0, 128)
          : null,
      timestamp: payload.timestamp || new Date().toISOString(),
    },
  };

  alerts[id] = alert;

  // Persist evidence metadata to disk
  const incidentDir = path.join(AUDIT_DIR, id);
  fs.mkdirSync(incidentDir, { recursive: true });
  fs.writeFileSync(
    path.join(incidentDir, "alert.json"),
    JSON.stringify(alert, null, 2),
  );

  // Access log
  const logLine = `[${alert.createdAt}] INGEST ${id} score:${riskScore} type:${type}\n`;
  fs.appendFileSync(path.join(AUDIT_DIR, "access.log"), logLine);

  res.json({ id, status: "ingested", alert });
});

// --------------- List alerts ---------------
app.get("/v1/radar/alerts", (_req, res) => {
  const list = Object.values(alerts).sort(
    (a, b) => new Date(b.createdAt) - new Date(a.createdAt),
  );
  res.json(list);
});

// --------------- Get single alert ---------------
app.get("/v1/radar/alerts/:id", (req, res) => {
  const a = alerts[req.params.id];
  if (!a) return res.status(404).json({ error: "not found" });
  res.json(a);
});

// --------------- Export Police Evidence Pack (zip) ---------------
app.post("/v1/radar/alerts/:id/export", (req, res) => {
  const id = req.params.id;
  const alert = alerts[id];
  if (!alert) return res.status(404).json({ error: "not found" });

  const incidentDir = path.join(AUDIT_DIR, id);

  // Build manifest with SHA-256 hashes
  const manifest = {
    exportedAt: new Date().toISOString(),
    exportedBy: req.ip || "unknown",
    alertId: id,
    files: [],
  };

  // Sanitize filename for Content-Disposition header
  const safeId = id.replace(/[^a-zA-Z0-9_-]/g, "_");
  res.setHeader(
    "Content-Disposition",
    `attachment; filename="${safeId}_evidence.zip"`,
  );
  res.setHeader("Content-Type", "application/zip");

  const archive = archiver("zip", { zlib: { level: 9 } });
  archive.on("error", (err) => res.status(500).json({ error: err.message }));
  archive.pipe(res);

  // Include the alert JSON
  const alertJson = JSON.stringify(alert, null, 2);
  const alertHash = crypto.createHash("sha256").update(alertJson).digest("hex");
  manifest.files.push({ name: "alert.json", sha256: alertHash });
  archive.append(alertJson, { name: "alert.json" });

  // Include any evidence files — SECURITY: only allow files under AUDIT_DIR
  if (fs.existsSync(incidentDir)) {
    const files = fs.readdirSync(incidentDir);
    for (const f of files) {
      if (f === "alert.json") continue; // already added
      const fullPath = path.join(incidentDir, f);
      const realPath = fs.realpathSync(fullPath);
      // Path-traversal guard: must stay inside AUDIT_DIR
      if (!realPath.startsWith(fs.realpathSync(AUDIT_DIR))) continue;
      const stat = fs.statSync(realPath);
      if (!stat.isFile()) continue;

      const buf = fs.readFileSync(realPath);
      const hash = crypto.createHash("sha256").update(buf).digest("hex");
      manifest.files.push({ name: f, sha256: hash, bytes: stat.size });
      archive.file(realPath, { name: f });
    }
  }

  // Append manifest as last file
  const manifestJson = JSON.stringify(manifest, null, 2);
  archive.append(manifestJson, { name: "manifest.json" });

  // Log the export
  const logLine = `[${new Date().toISOString()}] EXPORT ${id} by:${req.ip} files:${manifest.files.length}\n`;
  fs.appendFileSync(path.join(AUDIT_DIR, "access.log"), logLine);

  archive.finalize();
});

// --------------- Police Evidence Routes ---------------
mountPoliceRoutes(app, alerts, AUDIT_DIR);

// --------------- Device Verification & Signed Ingest Routes ---------------
mountVerifyRoute(app, alerts, AUDIT_DIR, metrics);

// --------------- Drone Fleet, Launch Pad & Detection Routes ---------------
mountDroneRoutes(app);

// Record custody entry on every ingest (auto-chain)
const _origPost = app.post;
app.use("/v1/radar/event", (req, _res, next) => {
  // After ingest completes, the response already has the alert ID.
  // We hook into the response to add custody entries for new alerts.
  const origJson = _res.json;
  _res.json = function (body) {
    if (body && body.id) {
      try {
        appendCustodyEntry(
          AUDIT_DIR,
          body.id,
          "INGEST",
          req.ip || "system",
          `type:${body.alert?.type || "unknown"} score:${body.alert?.riskScore || 0}`,
        );
      } catch (_) {
        /* non-critical */
      }
    }
    return origJson.call(this, body);
  };
  next();
});

// --------------- Start ---------------
const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log("===============================================");
  console.log(" DFC CHUCKYA RADAR — Top-Secret Testing Room");
  console.log(` API running on port ${port}`);
  console.log(" Police Evidence Export: ACTIVE");
  console.log(" Device Verification: ACTIVE");
  console.log(" Drone Fleet Control: ACTIVE");
  console.log(" Detection System: ACTIVE");
  console.log(` API running on port ${port}`);
  console.log("===============================================");
});
