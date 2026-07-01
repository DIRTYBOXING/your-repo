"use strict";

const express = require("express");
const crypto = require("crypto");

const ALLOWED_ANALYTICS_EVENTS = new Set([
  "offer_shown",
  "offer_accepted",
  "poster_impression",
  "poster_click",
  "watch_started",
  "purchase_attempted",
  "purchase_success",
  "entitlement_granted",
  "share_clicked",
]);

const META_ELIGIBLE_EVENTS = new Set([
  "offer_accepted",
  "purchase_attempted",
  "purchase_success",
  "offer_shown",
  "poster_impression",
  "watch_started",
]);

let firestoreDb = null;
const localDedupeCache = new Map();
const LOCAL_DEDUPE_TTL_MS = 5 * 60 * 1000;

function getDb() {
  if (firestoreDb) return firestoreDb;

  try {
    const admin = require("firebase-admin");
    if (!admin.apps.length) {
      admin.initializeApp();
    }
    firestoreDb = admin.firestore();
  } catch {
    firestoreDb = null;
  }

  return firestoreDb;
}

async function isDuplicate(dedupeKey) {
  if (!dedupeKey) return false;

  const db = getDb();
  if (db) {
    const ref = db.collection("_dedupe").doc(encodeURIComponent(dedupeKey));
    const snap = await ref.get();
    if (snap.exists) return true;
    await ref.set({
      createdAt: new Date().toISOString(),
      dedupeKey,
      scope: "analytics_emit",
    });
    return false;
  }

  const cached = localDedupeCache.get(dedupeKey);
  if (cached && cached > Date.now()) return true;
  localDedupeCache.set(dedupeKey, Date.now() + LOCAL_DEDUPE_TTL_MS);
  if (localDedupeCache.size % 100 === 0) {
    const now = Date.now();
    for (const [key, expiry] of localDedupeCache.entries()) {
      if (expiry < now) localDedupeCache.delete(key);
    }
  }
  return false;
}

function makeRequestId() {
  return crypto.randomUUID();
}

function createAnalyticsEmitRouter({ audit, ppvCommerceMetrics, forwardToMeta, getConsentState }) {
  const router = express.Router();

  router.post("/emit", express.json(), async (req, res) => {
    try {
      const {
        event,
        eventId,
        userId,
        anonymousId,
        source,
        meta,
        ts,
        dedupeKey,
        email,
        phone,
        fbc,
        fbp,
        fbclid,
        clientIpAddress,
        clientUserAgent,
        sourceUrl,
        amountCents,
        currency,
        orderId,
        offerId,
      } = req.body || {};

      if (!event || !ALLOWED_ANALYTICS_EVENTS.has(event)) {
        return res.status(400).json({
          error: "event required and must be one of: " + [...ALLOWED_ANALYTICS_EVENTS].join(", "),
        });
      }

      const requestId = eventId || makeRequestId();
      const effectiveDedupeKey =
        dedupeKey || `${event}:${userId || anonymousId || "anon"}:${ts || requestId}`;

      if (await isDuplicate(effectiveDedupeKey)) {
        return res.json({ status: "duplicate", requestId, dedupeKey: effectiveDedupeKey });
      }

      if (ppvCommerceMetrics) {
        if (event === "purchase_attempted") {
          ppvCommerceMetrics.purchaseAttempts.inc({ source: source || "web" });
        }
        if (event === "purchase_success") {
          ppvCommerceMetrics.purchaseSuccess.inc({ source: source || "web" });
        }
        if (event === "watch_started") {
          ppvCommerceMetrics.watchStarted.inc({ source: source || "web" });
        }
        if (event === "entitlement_granted") {
          ppvCommerceMetrics.entitlementGranted.inc({ source: source || "web" });
        }
        if (ppvCommerceMetrics.analyticsEmitted) {
          ppvCommerceMetrics.analyticsEmitted.inc({ event, source: source || "web" });
        }
      }

      const record = {
        ...req.body,
        requestId,
        dedupeKey: effectiveDedupeKey,
        receivedAt: new Date().toISOString(),
      };

      audit.push({
        ts: Date.now(),
        action: "analytics_emit",
        event,
        requestId,
        dedupeKey: effectiveDedupeKey,
        userId,
        source,
      });

      const db = getDb();
      if (db) {
        await db.collection("analytics_events").add(record);
        if (String(process.env.BQ_FORWARD_ENABLED || "false") === "true") {
          await db.collection("analytics_forward_queue").add({
            payload: record,
            status: "queued",
            createdAt: new Date().toISOString(),
          });
        }
      }

      const consent = getConsentState(req);
      if (consent.advertising && META_ELIGIBLE_EVENTS.has(event)) {
        forwardToMeta({
          event,
          eventId: requestId,
          userId,
          email,
          phone,
          fbc,
          fbp,
          fbclid,
          clientIpAddress,
          clientUserAgent,
          sourceUrl,
          amountCents,
          currency,
          orderId,
          offerId,
        }).catch((err) => {
          console.error(
            JSON.stringify({
              severity: "WARN",
              metric: "meta_capi_emit_error",
              service: "analyticsEmit",
              event,
              requestId,
              error: err.message,
              ts: new Date().toISOString(),
            })
          );
        });
      }

      return res.json({
        status: "ok",
        event,
        requestId,
        dedupeKey: effectiveDedupeKey,
        ts: new Date().toISOString(),
      });
    } catch (err) {
      console.error(
        JSON.stringify({
          severity: "ERROR",
          metric: "analytics_emit_error",
          service: "analyticsEmit",
          error: err.message,
          ts: new Date().toISOString(),
        })
      );
      return res.status(500).json({ error: err.message });
    }
  });

  return router;
}

module.exports = { createAnalyticsEmitRouter };