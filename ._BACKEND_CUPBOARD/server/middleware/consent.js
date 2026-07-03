"use strict";
// ─────────────────────────────────────────────────────────────────────────────
// DFC — Consent Management Platform middleware
//
// Provides:
//   1. consentMiddleware(req, res, next) — parses & validates consent from
//      Cookie header or `x-dfc-consent` header; attaches req.consent object.
//   2. requireConsent(purposes) — factory that returns a middleware blocking
//      requests when specified consent purposes are not granted.
//   3. getConsentState(req) — helper to read consent in route handlers.
//
// Consent model (stored in `dfc_consent` cookie as base64-encoded JSON):
//   { analytics: bool, advertising: bool, functional: bool, ts: number }
//
// Privacy:
//   - Cookie is read-only; server never writes it (that's the CMP's job).
//   - No PII is stored or logged by this middleware.
//   - DNT (Do Not Track) header overrides advertising consent to false.
// ─────────────────────────────────────────────────────────────────────────────

"use strict";

const CONSENT_COOKIE = "dfc_consent";
const CONSENT_HEADER = "x-dfc-consent";

const DEFAULT_CONSENT = {
  analytics: false,
  advertising: false,
  functional: true, // functional always on (essential)
};

/**
 * Parse consent from cookie or header.
 * Returns a safe object — never throws.
 */
function _parseConsent(raw) {
  if (!raw) return { ...DEFAULT_CONSENT };
  try {
    const decoded = Buffer.from(raw, "base64").toString("utf8");
    const parsed = JSON.parse(decoded);
    return {
      analytics: Boolean(parsed.analytics),
      advertising: Boolean(parsed.advertising),
      functional: true, // always on
      ts: parsed.ts || null,
    };
  } catch {
    return { ...DEFAULT_CONSENT };
  }
}

function _extractRaw(req) {
  // 1. Explicit header (useful for mobile app / server-to-server calls)
  if (req.headers[CONSENT_HEADER]) return req.headers[CONSENT_HEADER];
  // 2. Cookie
  const cookieHeader = req.headers.cookie || "";
  const match = cookieHeader.match(new RegExp(`(?:^|;\\s*)${CONSENT_COOKIE}=([^;]+)`));
  return match ? decodeURIComponent(match[1]) : null;
}

/**
 * Core middleware — always runs.  Attaches `req.consent` without blocking.
 */
function consentMiddleware(req, res, next) {
  const raw = _extractRaw(req);
  const consent = _parseConsent(raw);

  // DNT override
  if (req.headers.dnt === "1") {
    consent.advertising = false;
  }

  req.consent = consent;
  next();
}

/**
 * Guard middleware factory.
 *
 * Usage:
 *   router.post('/ads/meta/forward', requireConsent(['advertising']), handler)
 *
 * @param {string[]} purposes - List of consent purposes required (any of 'analytics', 'advertising').
 */
function requireConsent(purposes = []) {
  return (req, res, next) => {
    const consent = req.consent || _parseConsent(_extractRaw(req));
    const denied = purposes.filter((p) => !consent[p]);
    if (denied.length > 0) {
      return res.status(451).json({
        error: "consent_required",
        denied,
        message: "User has not granted required consent for this operation.",
      });
    }
    next();
  };
}

/**
 * Helper for use inside route handlers (no middleware required).
 */
function getConsentState(req) {
  return req.consent || _parseConsent(_extractRaw(req));
}

module.exports = { consentMiddleware, requireConsent, getConsentState };
