// ─────────────────────────────────────────────────────────────────────────────
// drm/signed_urls.js — CDN Signed URL issuance for posters and stream assets
//
// Two exports:
//
//   getPosterSignedUrl (onCall)
//     Firebase-Auth gated Callable that issues a GCS v4 signed URL for a
//     poster object.  Posters get a 7-day TTL (the CDN caches them; the
//     signed URL is the origin fallback).  Response includes Cache-Control
//     headers the caller should forward to its CDN: public, max-age=604800,
//     immutable.
//
//   cdnTokenApi (onRequest POST)
//     Issues a short-lived HMAC token for an arbitrary asset URL so edge
//     workers (Cloudflare / CloudFront / Fastly) can validate it without a
//     round-trip to Firebase.
//
//       POST /cdnTokenApi
//       Authorization: Bearer <Firebase ID token>
//       { "assetUrl": "https://cdn.example.com/posters/bkfc-2026.jpg",
//         "ttlSeconds": 3600 }
//
//     Response: { "signedAssetUrl": "...", "expiresAt": "..." }
//
// Required Firebase secrets:
//   CDN_SIGNING_SECRET — HMAC-SHA256 secret shared with your CDN edge worker.
//
// Firestore audit:
//   cdn_url_issuances/{autoId}  — written on every successful issuance.
// ─────────────────────────────────────────────────────────────────────────────

"use strict";

const crypto = require("crypto");
const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { admin, db, REGION } = require("../config");

// ── Secrets ──────────────────────────────────────────────────────────────────
const CDN_SIGNING_SECRET_PARAM = defineSecret("CDN_SIGNING_SECRET");

// ── Constants ─────────────────────────────────────────────────────────────────
const POSTER_TTL_SECONDS   = 7 * 24 * 60 * 60; // 7 days — CDN caches from here
const DEFAULT_CDN_TTL      = 3600;              // 1 hour
const MAX_CDN_TTL          = 86400;             // 24 hours hard cap
const ALLOWED_CDN_PREFIXES = [];                // fill in your CDN origin(s); empty = any HTTPS

// ── Helpers ───────────────────────────────────────────────────────────────────

function resolveCdnSecret() {
  try {
    return (CDN_SIGNING_SECRET_PARAM.value() || "").trim();
  } catch {
    return (process.env.CDN_SIGNING_SECRET || "").trim();
  }
}

/**
 * Build an HMAC-signed CDN URL.
 * Edge workers validate by recomputing the signature from path + expires.
 *
 * Signature input: `<url>|<expires_unix_seconds>`
 * Query params appended: ?expires=<n>&sig=<hex>
 *
 * @param {string} url        Base asset URL (must be HTTPS)
 * @param {string} secret     HMAC secret
 * @param {number} ttlSeconds Lifetime
 * @returns {{ signedUrl: string, expires: number }}
 */
function signCdnUrl(url, secret, ttlSeconds) {
  const expires = Math.floor(Date.now() / 1000) + ttlSeconds;
  const sig = crypto
    .createHmac("sha256", secret)
    .update(`${url}|${expires}`)
    .digest("hex");
  const separator = url.includes("?") ? "&" : "?";
  return {
    signedUrl: `${url}${separator}expires=${expires}&sig=${sig}`,
    expires,
  };
}

/**
 * Parse a gs:// path into { bucketName, objectPath }.
 * Mirrors the helper in ppv/commerce_api.js to avoid a shared import cycle.
 */
function parseGsPath(gsUrl) {
  if (typeof gsUrl !== "string" || !gsUrl.startsWith("gs://")) return null;
  const withoutScheme = gsUrl.slice(5);
  const slashIdx = withoutScheme.indexOf("/");
  if (slashIdx === -1) return null;
  return {
    bucketName: withoutScheme.slice(0, slashIdx),
    objectPath: withoutScheme.slice(slashIdx + 1),
  };
}

/**
 * Verify the Firebase ID token from the Authorization header.
 * Returns decoded token or null.
 */
async function verifyFirebaseToken(req) {
  const auth = (req.headers.authorization || "").trim();
  if (!auth.startsWith("Bearer ")) return null;
  const idToken = auth.slice(7).trim();
  try {
    return await admin.auth().verifyIdToken(idToken);
  } catch {
    return null;
  }
}

/**
 * Write a non-blocking audit record to Firestore.
 */
function logIssuance(record) {
  db.collection("cdn_url_issuances")
    .add({
      ...record,
      issuedAt: admin.firestore.FieldValue.serverTimestamp(),
    })
    .catch(() => {}); // never let audit failures block the caller
}

// ── Export 1: getPosterSignedUrl (Callable) ───────────────────────────────────

/**
 * Firebase Callable — returns a GCS v4 signed URL for a poster object.
 *
 * Request data: { gsPath: "gs://bucket/path/to/poster.jpg" }
 * Response:     { signedUrl: string, expiresAt: string, cacheControl: string }
 */
const getPosterSignedUrl = onCall(
  { region: REGION, secrets: [CDN_SIGNING_SECRET_PARAM] },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    const gsPath =
      typeof request.data?.gsPath === "string"
        ? request.data.gsPath.trim()
        : "";

    if (!gsPath) {
      throw new HttpsError("invalid-argument", "gsPath is required");
    }

    const gs = parseGsPath(gsPath);
    if (!gs) {
      throw new HttpsError(
        "invalid-argument",
        "gsPath must be a valid gs:// URL"
      );
    }

    const bucket = gs.bucketName
      ? admin.storage().bucket(gs.bucketName)
      : admin.storage().bucket();
    const file = bucket.file(gs.objectPath);

    const [exists] = await file.exists();
    if (!exists) {
      throw new HttpsError("not-found", "Poster object not found");
    }

    const expiresMs = Date.now() + POSTER_TTL_SECONDS * 1000;
    const [signedUrl] = await file.getSignedUrl({
      action: "read",
      version: "v4",
      expires: expiresMs,
      responseDisposition: "inline",
      responseType: "image/*",
      extensionHeaders: {
        // Instruct the CDN (if configured as origin pull) to cache aggressively
        "Cache-Control": `public, max-age=${POSTER_TTL_SECONDS}, immutable`,
      },
    });

    logIssuance({
      type: "poster",
      uid,
      gsPath,
      objectPath: gs.objectPath,
      ttlSeconds: POSTER_TTL_SECONDS,
    });

    return {
      signedUrl,
      expiresAt: new Date(expiresMs).toISOString(),
      // forward these headers when serving from your CDN layer:
      cacheControl: `public, max-age=${POSTER_TTL_SECONDS}, immutable`,
    };
  }
);

// ── Export 2: cdnTokenApi (HTTP endpoint) ─────────────────────────────────────

/**
 * HTTP POST endpoint that issues a short-lived HMAC-signed CDN URL.
 *
 * The HMAC signature is computed using CDN_SIGNING_SECRET.  Your CDN edge
 * worker (Cloudflare Worker / CloudFront Lambda@Edge / Fastly Fiddle) must
 * recompute the same HMAC to validate the token without calling Firebase.
 *
 * Body: { assetUrl: string, ttlSeconds?: number }
 */
async function handleCdnTokenRequest(req, res) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  // ── Auth ─────────────────────────────────────────────────────────────────
  const decoded = await verifyFirebaseToken(req);
  if (!decoded) {
    return res.status(401).json({ error: "Authentication required" });
  }

  // ── Payload ──────────────────────────────────────────────────────────────
  const { assetUrl, ttlSeconds } = req.body || {};

  if (typeof assetUrl !== "string" || !assetUrl.trim()) {
    return res.status(400).json({ error: "assetUrl is required" });
  }

  const url = assetUrl.trim();

  if (!url.startsWith("https://")) {
    return res.status(400).json({ error: "assetUrl must be HTTPS" });
  }

  if (
    ALLOWED_CDN_PREFIXES.length > 0 &&
    !ALLOWED_CDN_PREFIXES.some((prefix) => url.startsWith(prefix))
  ) {
    return res.status(403).json({ error: "assetUrl origin not permitted" });
  }

  const ttl = Math.min(
    typeof ttlSeconds === "number" && ttlSeconds > 0
      ? Math.floor(ttlSeconds)
      : DEFAULT_CDN_TTL,
    MAX_CDN_TTL
  );

  // ── Sign ─────────────────────────────────────────────────────────────────
  const secret = resolveCdnSecret();
  if (!secret) {
    // CDN_SIGNING_SECRET not provisioned — fail safe
    return res.status(503).json({ error: "CDN signing not configured" });
  }

  const { signedUrl, expires } = signCdnUrl(url, secret, ttl);

  // ── Audit ─────────────────────────────────────────────────────────────────
  logIssuance({
    type: "cdn_token",
    uid: decoded.uid,
    assetUrl: url,
    ttlSeconds: ttl,
  });

  return res.status(200).json({
    signedAssetUrl: signedUrl,
    expiresAt: new Date(expires * 1000).toISOString(),
  });
}

const cdnTokenApi = onRequest(
  {
    region: REGION,
    cors: false,  // CDN tokens must not be issued cross-origin from a browser
    secrets: [CDN_SIGNING_SECRET_PARAM],
  },
  handleCdnTokenRequest
);

// ── Utility export (used by other modules / edge worker deployment scripts) ───

module.exports = {
  getPosterSignedUrl,
  cdnTokenApi,
  /** Pure HMAC URL signer — import in edge workers or other server code. */
  signCdnUrl,
};
