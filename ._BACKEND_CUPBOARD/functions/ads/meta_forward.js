"use strict";
// ─────────────────────────────────────────────────────────────────────────────
// DFC — Meta Conversions API Server-Side Forwarder
//
// Responsibilities:
//   1. Hash PII (email, phone) with SHA-256 before sending to Meta.
//   2. Deduplicate events using eventId TTL cache (prevents client+server double-count).
//   3. Forward batched events to Meta Conversions API v21.0.
//   4. Retry up to 3 times with exponential backoff on transient failures.
//   5. Structured metric logging for observability.
//
// Environment variables:
//   META_PIXEL_ID        — Facebook Pixel ID (required for live forwarding)
//   META_ACCESS_TOKEN    — System User access token (required for live forwarding)
//   META_TEST_EVENT_CODE — Optional; enables Test Events in Events Manager
//
// Usage:
//   const { forwardToMeta, hashPii } = require('./meta_forward');
// ─────────────────────────────────────────────────────────────────────────────

const crypto = require("crypto");

const PIXEL_ID = process.env.META_PIXEL_ID || "";
const ACCESS_TOKEN = process.env.META_ACCESS_TOKEN || "";
const TEST_EVENT_CODE = process.env.META_TEST_EVENT_CODE || "";
const META_API_VERSION = "v21.0";
const META_CAPI_URL = `https://graph.facebook.com/${META_API_VERSION}/${PIXEL_ID}/events`;
const MAX_RETRIES = 3;
const BASE_BACKOFF_MS = 500;

// ── Deduplication cache — in-memory TTL ring (5 minute window) ────────────
const _dedupeCache = new Map(); // eventId → expiry timestamp
const DEDUPE_TTL_MS = 5 * 60 * 1000;

function _isDuplicate(eventId) {
  if (!eventId) return false;
  const expiry = _dedupeCache.get(eventId);
  if (expiry && expiry > Date.now()) return true;
  _dedupeCache.set(eventId, Date.now() + DEDUPE_TTL_MS);
  // Prune expired entries every 100 checks to avoid unbounded growth
  if (_dedupeCache.size % 100 === 0) {
    const now = Date.now();
    for (const [k, v] of _dedupeCache) {
      if (v < now) _dedupeCache.delete(k);
    }
  }
  return false;
}

// ── PII hashing ──────────────────────────────────────────────────────────────
function hashPii(value) {
  if (!value) return undefined;
  return crypto
    .createHash("sha256")
    .update(String(value).toLowerCase().trim())
    .digest("hex");
}

// ── Event name mapping (DFC canonical → Meta standard) ───────────────────────
const EVENT_NAME_MAP = {
  purchase_success: "Purchase",
  offer_accepted: "InitiateCheckout",
  purchase_attempted: "AddPaymentInfo",
  offer_shown: "ViewContent",
  poster_impression: "ViewContent",
  watch_started: "Subscribe",
};

// ── Build Meta event payload ─────────────────────────────────────────────────
function _buildMetaEvent(dfcEvent) {
  const {
    event,
    eventId,
    userId,
    email,
    phone,
    fbc,
    fbp,
    clientIpAddress,
    clientUserAgent,
    sourceUrl,
    amountCents,
    currency = "USD",
    orderId,
    offerId,
    customData: dfcCustomData = {},
  } = dfcEvent;

  const metaEventName = EVENT_NAME_MAP[event] || "CustomEvent";
  const eventTime = Math.floor(Date.now() / 1000);

  const userData = {};
  if (email) userData.em = [hashPii(email)];
  if (phone) userData.ph = [hashPii(phone)];
  if (userId) userData.external_id = [hashPii(userId)];
  if (fbc) userData.fbc = fbc;
  if (fbp) userData.fbp = fbp;
  if (clientIpAddress) userData.client_ip_address = clientIpAddress;
  if (clientUserAgent) userData.client_user_agent = clientUserAgent;

  const customData = { ...dfcCustomData };
  if (amountCents != null) {
    customData.value = (Number(amountCents) / 100).toFixed(2);
    customData.currency = currency;
  }
  if (orderId) customData.order_id = orderId;
  if (offerId) customData.content_ids = [offerId];

  return {
    event_name: metaEventName,
    event_time: eventTime,
    event_id: eventId,
    action_source: "website",
    event_source_url: sourceUrl || undefined,
    user_data: userData,
    custom_data: Object.keys(customData).length > 0 ? customData : undefined,
  };
}

// ── HTTP send with retry ──────────────────────────────────────────────────────
async function _sendToMeta(events) {
  if (!PIXEL_ID || !ACCESS_TOKEN) {
    // Dev mode — log and return synthetic success
    console.log(
      JSON.stringify({
        severity: "DEBUG",
        metric: "meta_capi_skipped",
        service: "metaForward",
        reason: "META_PIXEL_ID or META_ACCESS_TOKEN not set",
        eventCount: events.length,
        ts: new Date().toISOString(),
      })
    );
    return { status: "skipped", events_received: 0 };
  }

  const body = {
    data: events,
    ...(TEST_EVENT_CODE ? { test_event_code: TEST_EVENT_CODE } : {}),
  };

  let lastError;
  for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 8_000);

      const resp = await fetch(`${META_CAPI_URL}?access_token=${ACCESS_TOKEN}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
        signal: controller.signal,
      });
      clearTimeout(timeout);

      if (resp.ok) {
        const json = await resp.json();
        console.log(
          JSON.stringify({
            severity: "INFO",
            metric: "meta_capi_forwarded",
            service: "metaForward",
            eventsReceived: json.events_received,
            fbtrace_id: json.fbtrace_id,
            ts: new Date().toISOString(),
          })
        );
        return json;
      }

      const errorText = await resp.text().catch(() => "");
      lastError = `HTTP ${resp.status}: ${errorText}`;
      // 400 = bad payload — don't retry
      if (resp.status === 400) break;
    } catch (err) {
      lastError = err.message;
    }

    if (attempt < MAX_RETRIES - 1) {
      await new Promise((r) => setTimeout(r, Math.pow(2, attempt) * BASE_BACKOFF_MS));
    }
  }

  console.log(
    JSON.stringify({
      severity: "ERROR",
      metric: "meta_capi_failed",
      service: "metaForward",
      lastError,
      ts: new Date().toISOString(),
    })
  );
  throw new Error(`Meta CAPI forward failed: ${lastError}`);
}

// ── Public API ─────────────────────────────────────────────────────────────────
/**
 * Forward one or more DFC analytics events to Meta Conversions API.
 *
 * @param {object|object[]} dfcEvents - Single event or array of events.
 * @returns {Promise<object>} Meta API response or { status: 'skipped' }.
 */
async function forwardToMeta(dfcEvents) {
  const eventsArr = Array.isArray(dfcEvents) ? dfcEvents : [dfcEvents];

  // Filter to events that map to Meta and deduplicate
  const metaEvents = eventsArr
    .filter((e) => EVENT_NAME_MAP[e.event])
    .filter((e) => !_isDuplicate(e.eventId))
    .map(_buildMetaEvent);

  if (metaEvents.length === 0) {
    return { status: "no_eligible_events" };
  }

  return _sendToMeta(metaEvents);
}

module.exports = { forwardToMeta, hashPii };
