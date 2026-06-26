"use strict";
// ─────────────────────────────────────────────────────────────────────────────
// DFC PPV — Offer A/B Experiment Runner
//
// Routes:
//   POST /api/offers/ab/assign  — deterministically assign user to variant
//   POST /api/offers/ab/record  — record an impression or conversion event
//   GET  /api/offers/ab/results/:experimentId — conversion rates per variant
//
// Persistence: Firestore when firebase-admin is available and initialized.
// Falls back to in-memory Maps for local dev / CI where Firestore is not wired.
//
// Firestore collections:
//   experiments/{experimentId}              — experiment config
//   experiment_assignments/{expId_userId}   — variant assignments (idempotent)
//   experiment_events/{auto-id}             — impression / conversion events
// ─────────────────────────────────────────────────────────────────────────────

const express = require("express");

// ── Firestore adapter (graceful fallback to in-memory) ───────────────────────
let _db = null;
function getDb() {
  if (_db) return _db;
  try {
    const admin = require("firebase-admin");
    if (admin.apps.length) {
      _db = admin.firestore();
    }
  } catch (_) { /* firebase-admin not available */ }
  return _db;
}

// In-memory stores — used when Firestore is unavailable
const _memExperiments = new Map();
const _memAssignments = new Map();
const _memEvents = new Map(); // experimentId → []

async function getExperiment(experimentId) {
  const db = getDb();
  if (db) {
    const snap = await db.collection("experiments").doc(experimentId).get();
    return snap.exists ? snap.data() : null;
  }
  return _memExperiments.get(experimentId) || null;
}

async function setExperiment(experimentId, data) {
  const db = getDb();
  if (db) {
    await db.collection("experiments").doc(experimentId).set(data, { merge: true });
  } else {
    _memExperiments.set(experimentId, { ...(_memExperiments.get(experimentId) || {}), ...data });
  }
}

async function getAssignment(key) {
  const db = getDb();
  if (db) {
    const snap = await db.collection("experiment_assignments").doc(key).get();
    return snap.exists ? snap.data().variantId : null;
  }
  return _memAssignments.get(key) || null;
}

async function setAssignment(key, variantId) {
  const db = getDb();
  if (db) {
    await db.collection("experiment_assignments").doc(key).set({ variantId, assignedAt: new Date().toISOString() });
  } else {
    _memAssignments.set(key, variantId);
  }
}

async function recordEvent(experimentId, eventDoc) {
  const db = getDb();
  if (db) {
    await db.collection("experiment_events").add(eventDoc);
  } else {
    if (!_memEvents.has(experimentId)) _memEvents.set(experimentId, []);
    _memEvents.get(experimentId).push(eventDoc);
  }
}

async function getEvents(experimentId) {
  const db = getDb();
  if (db) {
    const snap = await db
      .collection("experiment_events")
      .where("experimentId", "==", experimentId)
      .get();
    return snap.docs.map((d) => d.data());
  }
  return _memEvents.get(experimentId) || [];
}

// ── Deterministic variant assignment via FNV-1a hash ─────────────────────────
function fnv1a(str) {
  let hash = 2166136261;
  for (let i = 0; i < str.length; i++) {
    hash ^= str.charCodeAt(i);
    hash = (hash * 16777619) >>> 0;
  }
  return hash;
}

function assignVariantDeterministic(experimentId, userId, variants) {
  const key = `${experimentId}_${userId}`;
  const totalWeight = variants.reduce((s, v) => s + (v.weight ?? 1), 0);
  const bucket = fnv1a(key) % totalWeight;
  let cumulative = 0;
  for (const v of variants) {
    cumulative += v.weight ?? 1;
    if (bucket < cumulative) return v.id;
  }
  return variants[0].id;
}

// ── Router ───────────────────────────────────────────────────────────────────
const router = express.Router();

/**
 * POST /api/offers/ab/assign
 * Body: { experimentId, userId, variants?: [{ id, label, weight }] }
 * Returns: { experimentId, userId, variantId, variantLabel }
 */
router.post("/assign", express.json(), async (req, res) => {
  try {
    const { experimentId, userId, variants } = req.body || {};
    if (!experimentId || !userId) {
      return res.status(400).json({ error: "experimentId and userId required" });
    }

    // Bootstrap experiment if first assignment
    let exp = await getExperiment(experimentId);
    if (!exp) {
      const defaultVariants = variants || [
        { id: "control", label: "Control", weight: 1 },
        { id: "treatment", label: "Treatment", weight: 1 },
      ];
      exp = {
        experimentId,
        variants: defaultVariants,
        active: true,
        createdAt: new Date().toISOString(),
      };
      await setExperiment(experimentId, exp);
    }

    if (!exp.active) {
      return res.status(409).json({ error: "Experiment is not active" });
    }

    const assignKey = `${experimentId}_${userId}`;
    let variantId = await getAssignment(assignKey);
    if (!variantId) {
      variantId = assignVariantDeterministic(experimentId, userId, exp.variants);
      await setAssignment(assignKey, variantId);
    }

    const variant = exp.variants.find((v) => v.id === variantId) || { id: variantId, label: variantId };
    return res.json({ experimentId, userId, variantId, variantLabel: variant.label });
  } catch (err) {
    console.error("[ab_runner] assign error", err);
    return res.status(500).json({ error: "Internal error" });
  }
});

/**
 * POST /api/offers/ab/record
 * Body: { experimentId, userId, variantId, eventType: 'impression'|'conversion' }
 * Returns: { recorded: true }
 */
router.post("/record", express.json(), async (req, res) => {
  try {
    const { experimentId, userId, variantId, eventType } = req.body || {};
    if (!experimentId || !userId || !variantId || !eventType) {
      return res.status(400).json({
        error: "experimentId, userId, variantId, and eventType required",
      });
    }
    if (!["impression", "conversion"].includes(eventType)) {
      return res.status(400).json({ error: "eventType must be impression or conversion" });
    }

    await recordEvent(experimentId, {
      experimentId,
      userId,
      variantId,
      eventType,
      ts: new Date().toISOString(),
    });

    return res.json({ recorded: true, experimentId, variantId, eventType });
  } catch (err) {
    console.error("[ab_runner] record error", err);
    return res.status(500).json({ error: "Internal error" });
  }
});

/**
 * GET /api/offers/ab/results/:experimentId
 * Returns per-variant impression/conversion counts and conversion rate
 */
router.get("/results/:experimentId", async (req, res) => {
  try {
    const { experimentId } = req.params;
    const exp = await getExperiment(experimentId);
    if (!exp) {
      return res.status(404).json({ error: "Experiment not found" });
    }

    const events = await getEvents(experimentId);
    const stats = {};

    for (const v of exp.variants) {
      stats[v.id] = { variantId: v.id, label: v.label, impressions: 0, conversions: 0, conversionRate: 0 };
    }

    for (const e of events) {
      if (!stats[e.variantId]) {
        stats[e.variantId] = { variantId: e.variantId, label: e.variantId, impressions: 0, conversions: 0, conversionRate: 0 };
      }
      if (e.eventType === "impression") stats[e.variantId].impressions++;
      if (e.eventType === "conversion") stats[e.variantId].conversions++;
    }

    for (const s of Object.values(stats)) {
      s.conversionRate = s.impressions > 0
        ? Number((s.conversions / s.impressions).toFixed(4))
        : 0;
    }

    // Identify winner (highest conversion rate with ≥ 10 impressions)
    const qualified = Object.values(stats).filter((s) => s.impressions >= 10);
    const winner = qualified.length > 0
      ? qualified.reduce((best, s) => (s.conversionRate > best.conversionRate ? s : best), qualified[0])
      : null;

    return res.json({
      experimentId,
      active: exp.active,
      totalEvents: events.length,
      variants: Object.values(stats),
      winner: winner ? { variantId: winner.variantId, conversionRate: winner.conversionRate } : null,
    });
  } catch (err) {
    console.error("[ab_runner] results error", err);
    return res.status(500).json({ error: "Internal error" });
  }
});

module.exports = { abRunnerRouter: router };
