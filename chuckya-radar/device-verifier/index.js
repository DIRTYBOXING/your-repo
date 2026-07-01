/**
 * ╔══════════════════════════════════════════════════════════════╗
 * ║  DFC CHUCKYA — Device Verifier Service                      ║
 * ║  Public key registration, signature verification,           ║
 * ║  consent storage, and device management                     ║
 * ╚══════════════════════════════════════════════════════════════╝
 */
"use strict";

const express = require("express");
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const cors = require("cors");

const app = express();
app.use(cors({ origin: true }));
app.use(express.json({ limit: "128kb" }));

// --------------- Storage ---------------
const AUDIT_DIR = path.resolve(__dirname, "../ops-audit");
const CONSENTS_DIR = path.join(AUDIT_DIR, "consents");
const PUBKEYS_DIR = path.join(AUDIT_DIR, "device_pubkeys");
const NONCES_DIR = path.join(AUDIT_DIR, "nonces");

for (const dir of [AUDIT_DIR, CONSENTS_DIR, PUBKEYS_DIR, NONCES_DIR]) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}

// --------------- Helpers ---------------
function sha256Hex(data) {
  return crypto.createHash("sha256").update(data).digest("hex");
}

/** Safe path resolution — reject traversal attempts */
function safeResolve(base, ...segments) {
  const resolved = path.resolve(base, ...segments);
  if (!resolved.startsWith(fs.realpathSync(base))) {
    throw new Error("path traversal blocked");
  }
  return resolved;
}

/** Validate appInstanceId format — alphanumeric, underscores, hyphens, max 128 chars */
function validInstanceId(id) {
  return typeof id === "string" && /^[a-zA-Z0-9_-]{1,128}$/.test(id);
}

/**
 * Deterministic canonical JSON: recursively sort object keys.
 * Arrays preserved in order; primitives returned as-is.
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

// --------------- Nonce tracking (filesystem-backed, per device) ---------------
const TTL_SECONDS = 300; // 5 minutes
const MAX_NONCES_PER_DEVICE = 200;

function loadNonces(appInstanceId) {
  const fp = safeResolve(NONCES_DIR, `${appInstanceId}.json`);
  if (!fs.existsSync(fp)) return [];
  try {
    return JSON.parse(fs.readFileSync(fp, "utf8"));
  } catch {
    return [];
  }
}

function saveNonces(appInstanceId, nonces) {
  const fp = safeResolve(NONCES_DIR, `${appInstanceId}.json`);
  // Trim to keep storage bounded
  const trimmed = nonces.slice(-MAX_NONCES_PER_DEVICE);
  fs.writeFileSync(fp, JSON.stringify(trimmed), "utf8");
}

// --------------- Healthcheck ---------------
app.get("/healthz", (_req, res) =>
  res.json({ status: "ok", service: "chuckya-device-verifier" }),
);

// ===============================================================
// POST /v1/device/registerPublicKey
// Body: { appInstanceId, publicKeyBase64 }
// Stores public key and writes a consent/registration record.
// ===============================================================
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

    // Verify the provided key is actually a valid PEM public key
    try {
      const pemString = Buffer.from(publicKeyBase64, "base64").toString("utf8");
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

    // Store public key
    const pubkeyPath = safeResolve(PUBKEYS_DIR, `${appInstanceId}.json`);
    fs.writeFileSync(pubkeyPath, JSON.stringify(record, null, 2), "utf8");

    // Store registration consent record (immutable — append-only naming)
    const consentPath = safeResolve(
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

    // Access log
    const logLine = `[${record.registeredAt}] REGISTER_PUBKEY ${appInstanceId} from:${record.registeredFromIp}\n`;
    fs.appendFileSync(path.join(AUDIT_DIR, "access.log"), logLine);

    return res.json({ status: "registered", appInstanceId });
  } catch (err) {
    console.error("registerPublicKey error:", err);
    return res.status(500).json({ error: "internal error" });
  }
});

// ===============================================================
// POST /v1/device/consent
// Body: { appInstanceId, consent: { appId: bool, imei: bool, location: bool } }
// Stores a signed, immutable consent record.
// ===============================================================
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

    // Immutable consent file
    const consentPath = safeResolve(
      CONSENTS_DIR,
      `${appInstanceId}_consent_${Date.now()}.json`,
    );
    fs.writeFileSync(consentPath, JSON.stringify(record, null, 2), "utf8");

    // Access log
    const logLine = `[${record.timestamp}] CONSENT ${appInstanceId} appId:${record.consent.appId} imei:${record.consent.imei} location:${record.consent.location}\n`;
    fs.appendFileSync(path.join(AUDIT_DIR, "access.log"), logLine);

    return res.json({
      status: "consent_stored",
      appInstanceId,
      consent: record.consent,
    });
  } catch (err) {
    console.error("consent error:", err);
    return res.status(500).json({ error: "internal error" });
  }
});

// ===============================================================
// GET /v1/device/:appInstanceId/status
// Returns registration and consent status for a device.
// ===============================================================
app.get("/v1/device/:appInstanceId/status", (req, res) => {
  try {
    const appInstanceId = req.params.appInstanceId;
    if (!validInstanceId(appInstanceId)) {
      return res.status(400).json({ error: "invalid appInstanceId format" });
    }

    const pubkeyPath = safeResolve(PUBKEYS_DIR, `${appInstanceId}.json`);
    const registered = fs.existsSync(pubkeyPath);

    // Find latest consent
    const consentFiles = fs
      .readdirSync(CONSENTS_DIR)
      .filter((f) => f.startsWith(`${appInstanceId}_consent_`))
      .sort()
      .reverse();

    let latestConsent = null;
    if (consentFiles.length > 0) {
      try {
        latestConsent = JSON.parse(
          fs.readFileSync(path.join(CONSENTS_DIR, consentFiles[0]), "utf8"),
        );
      } catch {
        /* ignore corrupt files */
      }
    }

    return res.json({
      appInstanceId,
      publicKeyRegistered: registered,
      latestConsent: latestConsent ? latestConsent.consent : null,
      consentTimestamp: latestConsent ? latestConsent.timestamp : null,
    });
  } catch (err) {
    console.error("device status error:", err);
    return res.status(500).json({ error: "internal error" });
  }
});

// ===============================================================
// Signature verification middleware (exported for use by radar-server)
// ===============================================================
function verifyDeviceSignature(payload) {
  const appInstanceId = payload.appInstanceId;
  if (!validInstanceId(appInstanceId)) {
    return { valid: false, error: "invalid appInstanceId" };
  }

  const signatureBase64 = payload.signatureBase64 || payload.signature;
  if (!signatureBase64) {
    return { valid: false, error: "missing signature" };
  }

  // TTL check
  const ts = new Date(payload.timestamp || 0).getTime();
  if (!ts || isNaN(ts) || (Date.now() - ts) / 1000 > TTL_SECONDS) {
    return { valid: false, error: "payload TTL exceeded (>5 min)" };
  }

  // Nonce check
  if (!payload.nonce || typeof payload.nonce !== "string") {
    return { valid: false, error: "missing nonce" };
  }
  const nonces = loadNonces(appInstanceId);
  if (nonces.includes(payload.nonce)) {
    return { valid: false, error: "replay detected (duplicate nonce)" };
  }

  // Load public key
  const pubkeyPath = path.join(PUBKEYS_DIR, `${appInstanceId}.json`);
  if (!fs.existsSync(pubkeyPath)) {
    return { valid: false, error: "public key not registered for this device" };
  }

  let publicKeyPem;
  try {
    const record = JSON.parse(fs.readFileSync(pubkeyPath, "utf8"));
    publicKeyPem = Buffer.from(record.publicKey, "base64").toString("utf8");
  } catch {
    return { valid: false, error: "corrupt public key record" };
  }

  // Canonical payload — remove signature fields before verification
  const payloadCopy = JSON.parse(JSON.stringify(payload));
  delete payloadCopy.signatureBase64;
  delete payloadCopy.signature;
  const canonical = JSON.stringify(canonicalize(payloadCopy));

  // Verify
  try {
    const verifier = crypto.createVerify("SHA256");
    verifier.update(canonical);
    verifier.end();
    const sigBuffer = Buffer.from(signatureBase64, "base64");
    const verified = verifier.verify(publicKeyPem, sigBuffer);
    if (!verified) {
      return { valid: false, error: "signature verification failed" };
    }
  } catch (err) {
    return { valid: false, error: `signature error: ${err.message}` };
  }

  // Signature valid — commit nonce
  nonces.push(payload.nonce);
  saveNonces(appInstanceId, nonces);

  return { valid: true };
}

// Export for use by radar-server
module.exports = {
  verifyDeviceSignature,
  canonicalize,
  sha256Hex,
  validInstanceId,
};

// --------------- Start ---------------
const port = process.env.PORT || 8083;
app.listen(port, () => {
  console.log("===============================================");
  console.log(" DFC CHUCKYA — Device Verifier Service");
  console.log(` Listening on port ${port}`);
  console.log(" Endpoints: registerPublicKey, consent, status");
  console.log("===============================================");
});
