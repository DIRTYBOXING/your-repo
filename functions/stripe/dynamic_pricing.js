// ═══════════════════════════════════════════════════════════════════════════
// DYNAMIC PRICING ENGINE — Demand-Based PPV Pricing with Surge/Decay
// ═══════════════════════════════════════════════════════════════════════════
//
// Reads real-time demand signals from Firestore (view counts, cart adds,
// social buzz, time-to-event) and adjusts PPV tier pricing dynamically.
//
// Guard rails:
//   - Prices never exceed 2× base or drop below 0.5× base
//   - Changes are capped at ±15% per evaluation cycle
//   - Feature-flagged: only active when `dynamicPricingEnabled` is true
// ═══════════════════════════════════════════════════════════════════════════

const { onCall } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { db, FieldValue, REGION } = require("../config");

// ── Base PPV tiers (same as ppv.js — single source of truth) ────────────
const BASE_TIERS = {
  0: 199,
  1: 399,
  2: 999,
  3: 1499,
  4: 2999,
  5: 4999,
  6: 1999,
  7: 2499,
  8: 3999,
};

// ── Guard rails ─────────────────────────────────────────────────────────
const PRICE_CEILING_MULT = 2;
const PRICE_FLOOR_MULT = 0.5;
const MAX_STEP_PCT = 0.15; // max ±15% change per cycle

function getTimeScore(hoursUntil) {
  if (hoursUntil <= 1) return 30;
  if (hoursUntil <= 6) return 25;
  if (hoursUntil <= 24) return 15;
  return 5;
}

// ═══════════════════════════════════════════════════════════════════════════
// DEMAND SCORING — Compute 0-100 demand score for a PPV event
// ═══════════════════════════════════════════════════════════════════════════

async function computeDemandScore(eventId) {
  const now = Date.now();

  // Fetch event doc for scheduled time
  const eventDoc = await db.collection("ppv_events").doc(eventId).get();
  if (!eventDoc.exists) return 50; // neutral if no data
  const eventData = eventDoc.data();

  // 1. Time-to-event urgency (closer = higher demand)
  const eventTime =
    eventData.scheduledAt?.toDate?.()?.getTime() || now + 86400000;
  const hoursUntil = Math.max(0, (eventTime - now) / 3600000);
  const timeScore = getTimeScore(hoursUntil);

  // 2. View velocity (page views in last hour)
  const viewsRef = db
    .collection("ppv_analytics")
    .where("eventId", "==", eventId)
    .where("type", "==", "page_view")
    .where("createdAt", ">", new Date(now - 3600000));
  const viewSnap = await viewsRef.get();
  const viewScore = Math.min(25, viewSnap.size * 0.5);

  // 3. Purchase velocity (buys in last 30 min)
  const purchasesRef = db
    .collection("ppv_purchases")
    .where("ppvId", "==", eventId)
    .where("createdAt", ">", new Date(now - 1800000));
  const purchaseSnap = await purchasesRef.get();
  const purchaseScore = Math.min(25, purchaseSnap.size * 2);

  // 4. Social buzz (mentions / engagement in last 2 hours)
  const buzzRef = db
    .collection("social_signals")
    .where("eventId", "==", eventId)
    .where("createdAt", ">", new Date(now - 7200000));
  const buzzSnap = await buzzRef.get();
  const buzzScore = Math.min(20, buzzSnap.size * 0.8);

  const total = Math.min(
    100,
    timeScore + viewScore + purchaseScore + buzzScore,
  );
  return Math.round(total);
}

// ═══════════════════════════════════════════════════════════════════════════
// PRICE ADJUSTMENT — Apply demand score to tier pricing
// ═══════════════════════════════════════════════════════════════════════════

function adjustPrice(baseCents, demandScore, currentCents) {
  // demand 50 = neutral (1.0×), 100 = max surge (2.0×), 0 = max decay (0.5×)
  let multiplier;
  if (demandScore >= 50) {
    multiplier = 1 + ((demandScore - 50) / 50) * (PRICE_CEILING_MULT - 1);
  } else {
    multiplier = PRICE_FLOOR_MULT + (demandScore / 50) * (1 - PRICE_FLOOR_MULT);
  }

  let targetCents = Math.round(baseCents * multiplier);

  // Clamp to ceiling/floor
  targetCents = Math.max(Math.round(baseCents * PRICE_FLOOR_MULT), targetCents);
  targetCents = Math.min(
    Math.round(baseCents * PRICE_CEILING_MULT),
    targetCents,
  );

  // Rate-limit step size
  if (currentCents > 0) {
    const maxDelta = Math.round(currentCents * MAX_STEP_PCT);
    const delta = targetCents - currentCents;
    if (Math.abs(delta) > maxDelta) {
      targetCents = currentCents + Math.sign(delta) * maxDelta;
    }
  }

  // Round to nearest 99 cents for clean display ($X.99)
  targetCents = Math.round(targetCents / 100) * 100 - 1;
  if (targetCents < 99) targetCents = 99;

  return targetCents;
}

// ═══════════════════════════════════════════════════════════════════════════
// CALLABLE: Get Dynamic Price for Event + Tier
// ═══════════════════════════════════════════════════════════════════════════

const getDynamicPrice = onCall({ region: REGION }, async (request) => {
  const { eventId, tierId } = request.data;
  if (!eventId || tierId === undefined) {
    return { error: "eventId and tierId are required" };
  }

  // Check feature flag
  const flagDoc = await db
    .collection("feature_flags")
    .doc("dynamicPricing")
    .get();
  if (!flagDoc.exists || !flagDoc.data()?.enabled) {
    return { price: BASE_TIERS[tierId] || 999, dynamic: false };
  }

  const baseCents = BASE_TIERS[tierId];
  if (!baseCents) return { error: `Unknown tierId: ${tierId}` };

  // Load current dynamic price
  const priceDoc = await db
    .collection("ppv_dynamic_prices")
    .doc(`${eventId}_${tierId}`)
    .get();
  const currentCents = priceDoc.exists ? priceDoc.data().priceCents : baseCents;

  const demandScore = await computeDemandScore(eventId);
  const newPrice = adjustPrice(baseCents, demandScore, currentCents);

  return {
    price: newPrice,
    baseCents,
    demandScore,
    multiplier: +(newPrice / baseCents).toFixed(2),
    dynamic: true,
  };
});

// ═══════════════════════════════════════════════════════════════════════════
// SCHEDULED: Re-evaluate all active event prices every 10 min
// ═══════════════════════════════════════════════════════════════════════════

const evaluateDynamicPrices = onSchedule(
  { schedule: "every 10 minutes", region: REGION, timeoutSeconds: 120 },
  async () => {
    const flagDoc = await db
      .collection("feature_flags")
      .doc("dynamicPricing")
      .get();
    if (!flagDoc.exists || !flagDoc.data()?.enabled) {
      console.log("[dynamic-pricing] Feature flag disabled — skipping");
      return;
    }

    // Get active PPV events (scheduled in the future or last 4 hours for replays)
    const cutoff = new Date(Date.now() - 4 * 3600000);
    const eventsSnap = await db
      .collection("ppv_events")
      .where("scheduledAt", ">", cutoff)
      .get();

    if (eventsSnap.empty) {
      console.log("[dynamic-pricing] No active events");
      return;
    }

    let updates = 0;
    for (const eventDoc of eventsSnap.docs) {
      const eventId = eventDoc.id;
      const demandScore = await computeDemandScore(eventId);

      for (const [tierId, baseCents] of Object.entries(BASE_TIERS)) {
        const docId = `${eventId}_${tierId}`;
        const priceDoc = await db
          .collection("ppv_dynamic_prices")
          .doc(docId)
          .get();
        const currentCents = priceDoc.exists
          ? priceDoc.data().priceCents
          : baseCents;
        const newPrice = adjustPrice(baseCents, demandScore, currentCents);

        if (newPrice !== currentCents) {
          await db
            .collection("ppv_dynamic_prices")
            .doc(docId)
            .set(
              {
                eventId,
                tierId: Number(tierId),
                baseCents,
                priceCents: newPrice,
                demandScore,
                multiplier: +(newPrice / baseCents).toFixed(2),
                updatedAt: FieldValue.serverTimestamp(),
                history: FieldValue.arrayUnion({
                  price: newPrice,
                  demand: demandScore,
                  at: new Date().toISOString(),
                }),
              },
              { merge: true },
            );
          updates++;
        }
      }
    }

    console.log(
      `[dynamic-pricing] Evaluated ${eventsSnap.size} events, ${updates} price changes`,
    );
  },
);

module.exports = {
  getDynamicPrice,
  evaluateDynamicPrices,
};
