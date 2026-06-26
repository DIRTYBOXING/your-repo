// ─────────────────────────────────────────────────────────────────────────────
// drm/token_issuance.js — Short-lived DRM playback token endpoint
//
// Issues JWT playback tokens validated against Firebase Auth, then logs
// each issuance to Firestore (drm_tokens) for audit and promoter reporting.
// Tokens are consumed by the DRM license exchange (drm-license-exchange.js)
// and the Mux entitlement proxy.
//
// Required env / Firebase secrets:
//   DRM_PROVIDER_SECRET   — HS256 secret used to sign playback tokens
//   DRM_TOKEN_TTL_SECONDS — token lifetime in seconds (default: 60)
//
// All callers must be authenticated Firebase users. Token scope is
// validated against the ppv_entitlements collection (Firestore).
// ─────────────────────────────────────────────────────────────────────────────

"use strict";

const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { admin, db, REGION } = require("../config");
const jwt = require("jsonwebtoken");

// ── Secrets ──────────────────────────────────────────────────────────────────
const DRM_PROVIDER_SECRET_PARAM = defineSecret("DRM_PROVIDER_SECRET");

// ── Constants ─────────────────────────────────────────────────────────────────
const DEFAULT_TTL = 60; // seconds
const MAX_TTL = 300;    // hard ceiling — never issue > 5 min tokens

// ── Helpers ───────────────────────────────────────────────────────────────────

/**
 * Resolve the DRM signing secret. Prefer the Firebase Secret, fall back to
 * process.env for local emulator runs where the secret isn't provisioned.
 */
function resolveDrmSecret() {
  try {
    return (DRM_PROVIDER_SECRET_PARAM.value() || "").trim();
  } catch {
    return (process.env.DRM_PROVIDER_SECRET || "").trim();
  }
}

/**
 * Verify the Firebase ID token from the Authorization header.
 * Returns the decoded token or null if invalid.
 */
async function verifyFirebaseToken(req) {
  const auth = req.headers.authorization || "";
  if (!auth.startsWith("Bearer ")) return null;
  try {
    return await admin.auth().verifyIdToken(auth.replace("Bearer ", ""));
  } catch {
    return null;
  }
}

/**
 * Check the caller has a valid entitlement for this event.
 * Looks up ppv_entitlements/{userId}__{eventId} or
 * stripe_entitlements where userId + eventId match.
 */
async function hasEntitlement(userId, eventId) {
  // Primary: composite doc ID
  const compositeId = `${userId}__${eventId}`;
  const snap = await db.collection("ppv_entitlements").doc(compositeId).get();
  if (snap.exists) {
    const data = snap.data() || {};
    // Treat any non-expired entitlement as valid
    if (!data.expiresAt) return true;
    const expiry = data.expiresAt.toMillis ? data.expiresAt.toMillis() : data.expiresAt;
    if (Date.now() < expiry) return true;
  }

  // Fallback: query by fields
  const query = await db
    .collection("ppv_entitlements")
    .where("userId", "==", userId)
    .where("eventId", "==", eventId)
    .where("status", "==", "active")
    .limit(1)
    .get();

  return !query.empty;
}

/**
 * Log token issuance for audit and promoter reporting.
 * Non-fatal — never block the response on a log write.
 */
async function logIssuance({ userId, eventId, device, scope, clientIp, ttl }) {
  try {
    await db.collection("drm_tokens").add({
      userId,
      eventId,
      device: device || null,
      scope: scope || "playback",
      clientIp: clientIp || null,
      issuedAt: admin.firestore.FieldValue.serverTimestamp(),
      ttlSeconds: ttl,
    });
  } catch (err) {
    console.error("[drm/token] audit log write failed (non-fatal):", err.message);
  }
}

// ── Handler ───────────────────────────────────────────────────────────────────

async function handleTokenRequest(req, res) {
  // Only POST
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  // ── Auth: require valid Firebase ID token ───────────────────────────────
  const decoded = await verifyFirebaseToken(req);
  if (!decoded) {
    return res.status(401).json({ error: "Unauthorized" });
  }
  const userId = decoded.uid;

  // ── Input validation ─────────────────────────────────────────────────────
  const { eventId, device, scope } = req.body || {};
  if (!eventId || typeof eventId !== "string" || eventId.length > 128) {
    return res.status(400).json({ error: "Missing or invalid eventId" });
  }

  // ── Entitlement check ────────────────────────────────────────────────────
  const entitled = await hasEntitlement(userId, eventId);
  if (!entitled) {
    return res.status(403).json({ error: "No active entitlement for this event" });
  }

  // ── Resolve signing secret ───────────────────────────────────────────────
  const drmSecret = resolveDrmSecret();
  if (!drmSecret) {
    console.error("[drm/token] DRM_PROVIDER_SECRET not configured");
    return res.status(500).json({ error: "DRM configuration error" });
  }

  // ── TTL ──────────────────────────────────────────────────────────────────
  const configuredTtl = parseInt(process.env.DRM_TOKEN_TTL_SECONDS || String(DEFAULT_TTL), 10);
  const ttl = Math.min(isNaN(configuredTtl) ? DEFAULT_TTL : configuredTtl, MAX_TTL);

  // ── Issue token ──────────────────────────────────────────────────────────
  const payload = {
    sub: userId,
    event: eventId,
    dev: device || "unknown",
    scope: scope || "playback",
  };

  let token;
  try {
    token = jwt.sign(payload, drmSecret, { expiresIn: `${ttl}s`, algorithm: "HS256" });
  } catch (err) {
    console.error("[drm/token] jwt.sign failed:", err.message);
    return res.status(500).json({ error: "Token issuance failed" });
  }

  // ── Audit log (non-blocking) ─────────────────────────────────────────────
  const clientIp =
    req.headers["x-forwarded-for"]?.split(",")[0].trim() ||
    req.ip ||
    null;

  logIssuance({ userId, eventId, device, scope, clientIp, ttl }); // intentionally not awaited

  // ── Respond ──────────────────────────────────────────────────────────────
  return res.json({ token, expiresIn: ttl });
}

// ── Firebase Function export ──────────────────────────────────────────────────

const drmTokenApi = onRequest(
  {
    region: REGION,
    cors: false, // tokens must never be issued cross-origin from a browser directly
    secrets: [DRM_PROVIDER_SECRET_PARAM],
  },
  handleTokenRequest,
);

module.exports = { drmTokenApi };
