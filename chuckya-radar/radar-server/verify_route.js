/**
 * ╔══════════════════════════════════════════════════════════════╗
 * ║  DFC CHUCKYA RADAR — Verified Ingest Route                  ║
 * ║  Signature verification, TTL, nonce, canonical JSON,        ║
 * ║  audit artifacts, and chain of custody for safety pings     ║
 * ╚══════════════════════════════════════════════════════════════╝
 *
 * Mount into the main Express app:
 *   const { mountVerifyRoute } = require('./verify_route');
 *   mountVerifyRoute(app, alerts, AUDIT_DIR);
 */
"use strict";

const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

// --------------- Storage paths ---------------
let AUDIT_DIR;
let PUBKEYS_DIR;
let NONCES_DIR;
let CONSENTS_DIR;

// --------------- Constants ---------------
const TTL_SECONDS = 300; // 5 minutes
const MAX_NONCES_PER_DEVICE = 200;

// --------------- Helpers ---------------
function sha256Hex(data) {
  return crypto.createHash("sha256").update(data).digest("hex");
}

function safeResolve(base, ...segments) {
  const resolved = path.resolve(base, ...segments);
  const realBase = fs.realpathSync(base);
  if (!resolved.startsWith(realBase) && !fs.existsSync(resolved)) {
    throw new Error("path traversal blocked");
  }
  if (
    fs.existsSync(resolved) &&
    !fs.realpathSync(resolved).startsWith(realBase)
  ) {
    throw new Error("path traversal blocked");
  }
  return resolved;
}

function validInstanceId(id) {
  return typeof id === "string" && /^[a-zA-Z0-9_-]{1,128}$/.test(id);
}

/**
 * Deterministic canonical JSON: recursively sort object keys.
 */
function canonicalize(obj) {
  if (obj === null || typeof obj !== "object") return obj;
  if (Array.isArray(obj)) return obj.map(canonicalize);
  const sorted = {};
  for (const k of Object.keys(obj).sort()) {
    sorted[k] = canonicalize(obj[k]);
  }
  return sorted;
}

// --------------- Nonce tracking ---------------
function loadNonces(appInstanceId) {
  const fp = path.join(NONCES_DIR, `${appInstanceId}.json`);
  if (!fs.existsSync(fp)) return [];
  try {
    return JSON.parse(fs.readFileSync(fp, "utf8"));
  } catch {
    return [];
  }
}

function saveNonces(appInstanceId, nonces) {
  const fp = path.join(NONCES_DIR, `${appInstanceId}.json`);
  const trimmed = nonces.slice(-MAX_NONCES_PER_DEVICE);
  fs.writeFileSync(fp, JSON.stringify(trimmed), "utf8");
}

// ===============================================================
// Mount function
// ===============================================================
function mountVerifyRoute(app, alerts, auditDir, metricsObj) {
  AUDIT_DIR = auditDir;
  PUBKEYS_DIR = path.join(AUDIT_DIR, "device_pubkeys");
  NONCES_DIR = path.join(AUDIT_DIR, "nonces");
  CONSENTS_DIR = path.join(AUDIT_DIR, "consents");

  // Optional Prometheus metrics (from metrics-server/metrics.js)
  const m = metricsObj || {};

  for (const dir of [PUBKEYS_DIR, NONCES_DIR, CONSENTS_DIR]) {
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  }

  // ---------------------------------------------------------------
  // POST /v1/device/registerPublicKey
  // Body: { appInstanceId, publicKeyBase64 }
  // ---------------------------------------------------------------
  app.post("/v1/device/registerPublicKey", (req, res) => {
    try {
      const { appInstanceId, publicKeyBase64 } = req.body;

      if (!validInstanceId(appInstanceId)) {
        return res.status(400).json({ error: "invalid appInstanceId format" });
      }
      if (
        !publicKeyBase64 ||
        typeof publicKeyBase64 !== "string" ||
        publicKeyBase64.length > 8192
      ) {
        return res
          .status(400)
          .json({ error: "invalid or missing publicKeyBase64" });
      }

      // Validate key decodes to a real PEM public key
      try {
        const pemString = Buffer.from(publicKeyBase64, "base64").toString(
          "utf8",
        );
        crypto.createPublicKey(pemString);
      } catch {
        return res.status(400).json({
          error: "publicKeyBase64 does not decode to a valid PEM public key",
        });
      }

      const record = {
        appInstanceId,
        publicKey: publicKeyBase64,
        registeredAt: new Date().toISOString(),
        registeredFromIp: req.ip || "unknown",
      };

      const pubkeyPath = path.join(PUBKEYS_DIR, `${appInstanceId}.json`);
      fs.writeFileSync(pubkeyPath, JSON.stringify(record, null, 2), "utf8");

      // Immutable consent/registration record
      const consentPath = path.join(
        CONSENTS_DIR,
        `${appInstanceId}_reg_${Date.now()}.json`,
      );
      fs.writeFileSync(
        consentPath,
        JSON.stringify(
          {
            type: "public_key_registration",
            appInstanceId,
            timestamp: record.registeredAt,
            ip: record.registeredFromIp,
            publicKeySha256: sha256Hex(publicKeyBase64),
          },
          null,
          2,
        ),
        "utf8",
      );

      const logLine = `[${record.registeredAt}] REGISTER_PUBKEY ${appInstanceId} from:${record.registeredFromIp}\n`;
      fs.appendFileSync(path.join(AUDIT_DIR, "access.log"), logLine);

      return res.json({ status: "registered", appInstanceId });
    } catch (err) {
      console.error("registerPublicKey error:", err.message);
      return res.status(500).json({ error: "internal error" });
    }
  });

  // ---------------------------------------------------------------
  // POST /v1/device/consent
  // Body: { appInstanceId, consent: { appId, imei, location } }
  // ---------------------------------------------------------------
  app.post("/v1/device/consent", (req, res) => {
    try {
      const { appInstanceId, consent } = req.body;

      if (!validInstanceId(appInstanceId)) {
        return res.status(400).json({ error: "invalid appInstanceId format" });
      }
      if (!consent || typeof consent !== "object") {
        return res.status(400).json({ error: "missing consent object" });
      }

      const record = {
        type: "user_consent",
        appInstanceId,
        consent: {
          appId: consent.appId === true,
          imei: consent.imei === true,
          location: consent.location === true,
        },
        timestamp: new Date().toISOString(),
        ip: req.ip || "unknown",
      };

      const consentPath = path.join(
        CONSENTS_DIR,
        `${appInstanceId}_consent_${Date.now()}.json`,
      );
      fs.writeFileSync(consentPath, JSON.stringify(record, null, 2), "utf8");

      const logLine = `[${record.timestamp}] CONSENT ${appInstanceId} appId:${record.consent.appId} imei:${record.consent.imei} location:${record.consent.location}\n`;
      fs.appendFileSync(path.join(AUDIT_DIR, "access.log"), logLine);

      return res.json({
        status: "consent_stored",
        appInstanceId,
        consent: record.consent,
      });
    } catch (err) {
      console.error("consent error:", err.message);
      return res.status(500).json({ error: "internal error" });
    }
  });

  // ---------------------------------------------------------------
  // POST /v1/radar/event/verified
  // Signed ingest: verifies device signature, TTL, nonce, then
  // creates alert with full audit trail and chain of custody.
  // Body: canonical payload + signatureBase64
  // ---------------------------------------------------------------
  app.post("/v1/radar/event/verified", (req, res) => {
    const endLatency = m.ingestLatency ? m.ingestLatency.startTimer() : null;
    try {
      if (m.signatureTotal) m.signatureTotal.inc();
      const body = req.body;
      const appInstanceId = body.appInstanceId;
      const signatureBase64 = body.signatureBase64 || body.signature || null;

      if (!validInstanceId(appInstanceId)) {
        return res.status(400).json({ error: "invalid appInstanceId" });
      }
      if (!signatureBase64) {
        return res.status(400).json({ error: "missing signatureBase64" });
      }

      // --- TTL check ---
      const ts = new Date(body.timestamp || 0).getTime();
      if (!ts || isNaN(ts) || (Date.now() - ts) / 1000 > TTL_SECONDS) {
        return res.status(400).json({ error: "payload TTL exceeded (>5 min)" });
      }

      // --- Nonce check ---
      if (!body.nonce || typeof body.nonce !== "string") {
        return res.status(400).json({ error: "missing nonce" });
      }
      const nonces = loadNonces(appInstanceId);
      if (nonces.includes(body.nonce)) {
        return res
          .status(400)
          .json({ error: "replay detected (duplicate nonce)" });
      }

      // --- Load public key ---
      const pubkeyPath = path.join(PUBKEYS_DIR, `${appInstanceId}.json`);
      if (!fs.existsSync(pubkeyPath)) {
        return res
          .status(404)
          .json({ error: "public key not registered for this device" });
      }

      let publicKeyPem;
      try {
        const record = JSON.parse(fs.readFileSync(pubkeyPath, "utf8"));
        publicKeyPem = Buffer.from(record.publicKey, "base64").toString("utf8");
      } catch {
        return res.status(500).json({ error: "corrupt public key record" });
      }

      // --- Canonicalize payload (remove signature) ---
      const payloadCopy = JSON.parse(JSON.stringify(body));
      delete payloadCopy.signatureBase64;
      delete payloadCopy.signature;
      const canonical = JSON.stringify(canonicalize(payloadCopy));

      // --- Verify signature ---
      try {
        const verifier = crypto.createVerify("SHA256");
        verifier.update(canonical);
        verifier.end();
        const sigBuffer = Buffer.from(signatureBase64, "base64");
        const verified = verifier.verify(publicKeyPem, sigBuffer);
        if (!verified) {
          return res
            .status(400)
            .json({ error: "signature verification failed" });
        }
        if (m.signatureVerified) m.signatureVerified.inc();
      } catch (err) {
        return res
          .status(400)
          .json({ error: `signature error: ${err.message}` });
      }

      // --- Commit nonce ---
      nonces.push(body.nonce);
      saveNonces(appInstanceId, nonces);

      // --- Create alert ---
      const alertId = `R-${Date.now()}`;
      const mode = [
        "code_black",
        "code_red",
        "code_amber",
        "code_yellow",
      ].includes(payloadCopy.mode)
        ? payloadCopy.mode
        : "code_yellow";

      const riskScore =
        mode === "code_black"
          ? 95
          : mode === "code_red"
            ? 80
            : mode === "code_amber"
              ? 60
              : 40;

      const alert = {
        alertId,
        createdAt: new Date().toISOString(),
        status: "open",
        mode,
        riskScore,
        appInstanceId,
        type: "safety_ping",
        topSignals: Array.isArray(payloadCopy.signals)
          ? payloadCopy.signals.slice(0, 10).map((s) => String(s).slice(0, 128))
          : [],
        proximity: payloadCopy.proximity || null,
        signatureVerified: true,
      };

      // Prometheus counters
      if (m.alertsCounter) m.alertsCounter.inc({ mode });
      if (
        m.consentLocationTrue &&
        consentRecord &&
        consentRecord.consent &&
        consentRecord.consent.location
      ) {
        m.consentLocationTrue.inc();
      }

      // Store in memory for dashboard
      alerts[alertId] = alert;

      // --- Persist audit artifacts ---
      const incidentDir = path.join(AUDIT_DIR, alertId);
      fs.mkdirSync(incidentDir, { recursive: true });

      // payload.json (without signature)
      const payloadJson = JSON.stringify(payloadCopy, null, 2);
      fs.writeFileSync(path.join(incidentDir, "payload.json"), payloadJson);
      const payloadSha = sha256Hex(payloadJson);

      // alert.json
      const alertJson = JSON.stringify(alert, null, 2);
      fs.writeFileSync(path.join(incidentDir, "alert.json"), alertJson);
      const alertSha = sha256Hex(alertJson);

      // consent_record.json — find latest consent for this device
      let consentRecord = null;
      try {
        const consentFiles = fs
          .readdirSync(CONSENTS_DIR)
          .filter((f) => f.startsWith(`${appInstanceId}_consent_`))
          .sort()
          .reverse();
        if (consentFiles.length > 0) {
          consentRecord = JSON.parse(
            fs.readFileSync(path.join(CONSENTS_DIR, consentFiles[0]), "utf8"),
          );
        }
      } catch {
        /* no consent found */
      }

      if (consentRecord) {
        const consentJson = JSON.stringify(consentRecord, null, 2);
        fs.writeFileSync(
          path.join(incidentDir, "consent_record.json"),
          consentJson,
        );
      }

      // chain_of_custody.json
      const now = new Date().toISOString();
      const manifest = {
        incidentId: alertId,
        createdAt: now,
        items: [
          { filename: "payload.json", sha256: payloadSha, createdAt: now },
          { filename: "alert.json", sha256: alertSha, createdAt: now },
        ],
      };
      if (consentRecord) {
        manifest.items.push({
          filename: "consent_record.json",
          sha256: sha256Hex(JSON.stringify(consentRecord, null, 2)),
          createdAt: now,
        });
      }
      fs.writeFileSync(
        path.join(incidentDir, "chain_of_custody.json"),
        JSON.stringify(manifest, null, 2),
      );

      // Access log
      const logLine = `[${now}] VERIFIED_INGEST ${alertId} device:${appInstanceId} mode:${mode} score:${riskScore}\n`;
      fs.appendFileSync(path.join(AUDIT_DIR, "access.log"), logLine);

      if (endLatency) endLatency();
      return res.json({
        id: alertId,
        status: "ingested",
        signatureVerified: true,
        alert,
      });
    } catch (err) {
      if (endLatency) endLatency();
      console.error("verified ingest error:", err.message);
      return res.status(500).json({ error: "internal error" });
    }
  });
}

module.exports = { mountVerifyRoute, canonicalize, sha256Hex };
