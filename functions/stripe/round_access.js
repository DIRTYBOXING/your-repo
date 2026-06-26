// ═══════════════════════════════════════════════════════════════════════════
// ROUND-BY-ROUND ACCESS — Per-Round Micro-Unlock System
// ═══════════════════════════════════════════════════════════════════════════
//
// Allows users to purchase access to individual rounds of a fight,
// consuming DFC Fight Credits or creating a micro Stripe payment.
//
// Use cases:
//   - "I only want to watch Round 3 of the main event"
//   - "Buy next round" button during live events
//   - Budget-friendly micro-access for emerging markets
//
// Collections:
//   ppv_round_access/{compositeId}  → per-user per-round unlock records
//   ppv_round_purchases             → audit trail of round micro-payments
//
// Pricing:
//   Credits mode: 20 credits per round (matches SINGLE ROUND tier)
//   Stripe mode:  Regional pricing via regional_pricing.js
//
// ═══════════════════════════════════════════════════════════════════════════

const { onCall } = require("firebase-functions/v2/https");
const { admin, db, REGION, stripe } = require("../config");
const {
  REGION_CONFIG,
  DEFAULT_REGION,
  ROUND_BASE_PRICE_CENTS,
} = require("./regional_pricing");

const CREDITS_PER_ROUND = 20;
const ROUND_REPLAY_HOURS = 48; // Round replays expire after 48h

// ─── Purchase Round with Credits ─────────────────────────────────────────
const purchaseRoundWithCredits = onCall({ region: REGION }, async (request) => {
  const { userId, ppvId, fightId, roundNumber } = request.data;

  if (!userId || !ppvId || !fightId || roundNumber == null) {
    return {
      error: "Missing required fields: userId, ppvId, fightId, roundNumber",
    };
  }

  const compositeId = `${userId}_${ppvId}_${fightId}_R${roundNumber}`;

  try {
    // Check if already unlocked
    const existing = await db
      .collection("ppv_round_access")
      .doc(compositeId)
      .get();
    if (existing.exists) {
      return { status: "already_unlocked", compositeId };
    }

    // Check credit balance
    const walletRef = db.collection("user_credits").doc(userId);
    const walletDoc = await walletRef.get();
    const balance = walletDoc.exists ? walletDoc.data().balance || 0 : 0;

    if (balance < CREDITS_PER_ROUND) {
      return {
        error: "insufficient_credits",
        required: CREDITS_PER_ROUND,
        balance,
        message: `Need ${CREDITS_PER_ROUND} credits, you have ${balance}`,
      };
    }

    const expiresAt = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + ROUND_REPLAY_HOURS * 60 * 60 * 1000),
    );

    // Atomic: deduct credits + grant access
    const batch = db.batch();

    // Deduct credits
    batch.update(walletRef, {
      balance: admin.firestore.FieldValue.increment(-CREDITS_PER_ROUND),
    });

    // Grant round access
    batch.set(db.collection("ppv_round_access").doc(compositeId), {
      userId,
      ppvId,
      fightId,
      roundNumber,
      method: "credits",
      creditsCost: CREDITS_PER_ROUND,
      grantedAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt,
    });

    // Audit trail
    batch.set(db.collection("ppv_round_purchases").doc(), {
      compositeId,
      userId,
      ppvId,
      fightId,
      roundNumber,
      method: "credits",
      creditsCost: CREDITS_PER_ROUND,
      purchasedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Record credit transaction
    batch.set(db.collection("credit_transactions").doc(), {
      userId,
      type: "spend",
      amount: -CREDITS_PER_ROUND,
      reason: `Round ${roundNumber} access: ${fightId}`,
      ppvId,
      fightId,
      roundNumber,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();

    return {
      status: "unlocked",
      compositeId,
      method: "credits",
      creditsUsed: CREDITS_PER_ROUND,
      remainingBalance: balance - CREDITS_PER_ROUND,
      expiresAt: expiresAt.toDate().toISOString(),
    };
  } catch (err) {
    console.error("purchaseRoundWithCredits error:", err);
    return { error: err.message };
  }
});

// ─── Create Round Stripe Payment Intent ──────────────────────────────────
// For users who want to pay per-round with card instead of credits.
const createRoundPaymentIntent = onCall({ region: REGION }, async (request) => {
  const {
    userId,
    ppvId,
    fightId,
    roundNumber,
    countryCode,
    promoterStripeAccountId,
  } = request.data;

  if (!userId || !ppvId || !fightId || roundNumber == null) {
    return { error: "Missing required fields" };
  }

  const compositeId = `${userId}_${ppvId}_${fightId}_R${roundNumber}`;

  try {
    // Check if already unlocked
    const existing = await db
      .collection("ppv_round_access")
      .doc(compositeId)
      .get();
    if (existing.exists) {
      return { status: "already_unlocked", compositeId };
    }

    // Calculate regional price
    const country = (countryCode || "AU").toUpperCase();
    const config = REGION_CONFIG[country] || DEFAULT_REGION;
    const priceCents = Math.max(
      50,
      Math.round(ROUND_BASE_PRICE_CENTS * config.multiplier),
    );

    // DFC takes 30% of round micro-payments (fixed rate for simplicity)
    const dfcFeeCents = Math.round(priceCents * 0.3);

    const paymentIntentParams = {
      amount: priceCents,
      currency: config.currency,
      metadata: {
        dfcUserId: userId,
        ppvId,
        fightId,
        roundNumber: roundNumber.toString(),
        compositeId,
        productType: "ppv_round",
        countryCode: country,
      },
      description: `DFC Round ${roundNumber} Access: ${fightId}`,
    };

    // Route to promoter's Connect account if available
    if (promoterStripeAccountId) {
      paymentIntentParams.application_fee_amount = dfcFeeCents;
      paymentIntentParams.transfer_data = {
        destination: promoterStripeAccountId,
      };
    }

    const paymentIntent =
      await stripe.paymentIntents.create(paymentIntentParams);

    // Record the pending payment intent
    await db.collection("ppv_payment_intents").doc(paymentIntent.id).set({
      userId,
      ppvId,
      fightId,
      roundNumber,
      compositeId,
      productType: "ppv_round",
      amountCents: priceCents,
      currency: config.currency,
      country,
      dfcFeeCents,
      status: "created",
      stripePaymentIntentId: paymentIntent.id,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
      amountCents: priceCents,
      currency: config.currency,
      displayPrice: formatPrice(priceCents, config),
      compositeId,
    };
  } catch (err) {
    console.error("createRoundPaymentIntent error:", err);
    return { error: err.message };
  }
});

// ─── Grant Round Access (called by webhook after payment succeeds) ───────
async function grantRoundAccess(paymentIntent) {
  const meta = paymentIntent.metadata || {};
  if (meta.productType !== "ppv_round") return;

  const { dfcUserId, ppvId, fightId, roundNumber, compositeId } = meta;
  if (!dfcUserId || !compositeId) return;

  try {
    const existing = await db
      .collection("ppv_round_access")
      .doc(compositeId)
      .get();
    if (existing.exists) {
      console.log(`Round access already exists: ${compositeId}`);
      return;
    }

    const expiresAt = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + ROUND_REPLAY_HOURS * 60 * 60 * 1000),
    );

    const batch = db.batch();

    batch.set(db.collection("ppv_round_access").doc(compositeId), {
      userId: dfcUserId,
      ppvId,
      fightId,
      roundNumber: parseInt(roundNumber, 10),
      method: "stripe",
      amountCents: paymentIntent.amount,
      currency: (paymentIntent.currency || "aud").toUpperCase(),
      stripePaymentId: paymentIntent.id,
      grantedAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt,
    });

    batch.set(db.collection("ppv_round_purchases").doc(), {
      compositeId,
      userId: dfcUserId,
      ppvId,
      fightId,
      roundNumber: parseInt(roundNumber, 10),
      method: "stripe",
      amountCents: paymentIntent.amount,
      currency: (paymentIntent.currency || "aud").toUpperCase(),
      stripePaymentId: paymentIntent.id,
      purchasedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();
    console.log(`Round access granted: ${compositeId}`);
  } catch (err) {
    console.error("grantRoundAccess error:", err);
  }
}

// ─── Check Round Access ──────────────────────────────────────────────────
const checkRoundAccess = onCall({ region: REGION }, async (request) => {
  const { userId, ppvId, fightId, roundNumber } = request.data;

  if (!userId || !ppvId || !fightId || roundNumber == null) {
    return { hasAccess: false, error: "Missing required fields" };
  }

  const compositeId = `${userId}_${ppvId}_${fightId}_R${roundNumber}`;

  try {
    const doc = await db.collection("ppv_round_access").doc(compositeId).get();
    if (!doc.exists) return { hasAccess: false };

    const data = doc.data();

    // Check expiry
    if (data.expiresAt && data.expiresAt.toDate() < new Date()) {
      return { hasAccess: false, reason: "expired" };
    }

    return { hasAccess: true, method: data.method, grantedAt: data.grantedAt };
  } catch (err) {
    return { hasAccess: false, error: err.message };
  }
});

// ─── Get All Unlocked Rounds for a Fight ─────────────────────────────────
const getUnlockedRounds = onCall({ region: REGION }, async (request) => {
  const { userId, ppvId, fightId } = request.data;
  if (!userId || !ppvId) return { rounds: [] };

  try {
    let query = db
      .collection("ppv_round_access")
      .where("userId", "==", userId)
      .where("ppvId", "==", ppvId);

    if (fightId) {
      query = query.where("fightId", "==", fightId);
    }

    const snap = await query.get();
    const now = new Date();

    const rounds = snap.docs
      .map((d) => ({ id: d.id, ...d.data() }))
      .filter((r) => !r.expiresAt || r.expiresAt.toDate() > now)
      .map((r) => ({
        fightId: r.fightId,
        roundNumber: r.roundNumber,
        method: r.method,
        grantedAt: r.grantedAt,
      }));

    return { rounds, count: rounds.length };
  } catch (err) {
    return { rounds: [], error: err.message };
  }
});

function formatPrice(cents, config) {
  const dollars = config.noDecimals
    ? Math.round(cents / 100)
    : (cents / 100).toFixed(2);
  return `${config.label} ${dollars}`;
}

module.exports = {
  purchaseRoundWithCredits,
  createRoundPaymentIntent,
  grantRoundAccess,
  checkRoundAccess,
  getUnlockedRounds,
  CREDITS_PER_ROUND,
  ROUND_REPLAY_HOURS,
};
