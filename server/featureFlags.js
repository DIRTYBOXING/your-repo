"use strict";
// ─────────────────────────────────────────────────────────────────────────────
// DFC Feature Flag SDK — Server-side adapter
//
// Wraps the Firestore-backed feature_flags collection with a synchronous-feel
// API (using a short-lived cache) suitable for Express middleware and route guards.
//
// Usage in routes:
//   const flags = require('../server/featureFlags');
//   await flags.refresh();  // call once on startup, or on-demand
//   flags.isEnabled('new_offer_ui', { userId, userRole })  // sync after refresh
//
// Usage as middleware:
//   router.get('/checkout', flags.gate('ppv_checkout_v2'), handler)
//
// Flag schema in Firestore `feature_flags/{flagName}`:
//   { enabled, rolloutPercent, allowedRoles, allowedUsers }
// ─────────────────────────────────────────────────────────────────────────────

const CACHE_TTL_MS = 60_000; // 1 minute

let _flagCache = {};
let _cacheExpiry = 0;
let _db = null;

function _getDb() {
  if (_db) return _db;
  try {
    const admin = require("firebase-admin");
    if (admin.apps.length) _db = admin.firestore();
  } catch (_) {}
  return _db;
}

function _simpleHash(str) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const chr = str.charCodeAt(i);
    hash = ((hash << 5) - hash + chr) | 0;
  }
  return Math.abs(hash);
}

function _evaluateFlag(flagData, userId = "", userRole = "free") {
  if (!flagData || !flagData.enabled) return false;
  if (flagData.allowedUsers?.includes(userId)) return true;
  if (flagData.allowedRoles?.length > 0 && !flagData.allowedRoles.includes(userRole)) return false;
  if (flagData.rolloutPercent !== undefined && flagData.rolloutPercent < 100) {
    const bucket = _simpleHash((flagData.name || "") + userId) % 100;
    if (bucket >= flagData.rolloutPercent) return false;
  }
  return true;
}

/**
 * Refresh flag cache from Firestore. No-ops if cache is still fresh.
 * Safe to call on every request; internal TTL throttles Firestore reads.
 */
async function refresh(force = false) {
  if (!force && Date.now() < _cacheExpiry) return;
  const db = _getDb();
  if (!db) return; // No Firestore — flags remain empty (default false)

  const snap = await db.collection("feature_flags").get();
  const fresh = {};
  for (const doc of snap.docs) {
    fresh[doc.id] = { ...doc.data(), name: doc.id };
  }
  _flagCache = fresh;
  _cacheExpiry = Date.now() + CACHE_TTL_MS;
}

/**
 * Synchronous flag check (uses cached data — call refresh() first).
 *
 * @param {string} flagName
 * @param {{ userId?: string, userRole?: string }} context
 * @returns {boolean}
 */
function isEnabled(flagName, context = {}) {
  const flagData = _flagCache[flagName];
  return _evaluateFlag(flagData, context.userId || "", context.userRole || "free");
}

/**
 * Returns all flag evaluations for the given context.
 *
 * @param {{ userId?: string, userRole?: string }} context
 * @returns {Record<string, boolean>}
 */
function getAll(context = {}) {
  const result = {};
  for (const [name, data] of Object.entries(_flagCache)) {
    result[name] = _evaluateFlag(data, context.userId || "", context.userRole || "free");
  }
  return result;
}

/**
 * Express middleware factory — refreshes flags then checks named flag.
 * Responds 404 (feature not enabled) if flag is off for the requesting user.
 *
 * Usage:
 *   router.get('/new-offer', flags.gate('new_offer_ui'), handler)
 *
 * @param {string} flagName
 */
function gate(flagName) {
  return async (req, res, next) => {
    await refresh();
    const userId = req.user?.uid || req.headers["x-dfc-user-id"] || "";
    const userRole = req.user?.role || req.headers["x-dfc-user-role"] || "free";
    if (!isEnabled(flagName, { userId, userRole })) {
      return res.status(404).json({ error: "feature_not_enabled", flag: flagName });
    }
    next();
  };
}

/**
 * Express middleware that attaches evaluated flags to req.featureFlags.
 * Call once per request, then use req.featureFlags.isEnabled() in handlers.
 */
async function middleware(req, _res, next) {
  await refresh();
  const userId = req.user?.uid || req.headers["x-dfc-user-id"] || "";
  const userRole = req.user?.role || req.headers["x-dfc-user-role"] || "free";
  req.featureFlags = {
    isEnabled: (flag) => isEnabled(flag, { userId, userRole }),
    getAll: () => getAll({ userId, userRole }),
  };
  next();
}

module.exports = { refresh, isEnabled, getAll, gate, middleware };
