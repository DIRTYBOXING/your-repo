// ═══════════════════════════════════════════════════════════════════════════
// ANTI-FRAUD SERVICE — PPV Purchase & Account Protection
// ═══════════════════════════════════════════════════════════════════════════
//
// Multi-layer fraud detection:
//   1. Device fingerprint scoring
//   2. Velocity checks (purchase / login frequency)
//   3. Geo-mismatch detection
//   4. Card testing pattern recognition
//   5. Account age + behaviour signals
//
// All checks return a risk score 0-100. Action thresholds:
//   0-30  = ALLOW (no friction)
//   31-60 = CHALLENGE (captcha or email verify)
//   61-80 = REVIEW (manual hold, notify ops)
//   81+   = BLOCK (deny transaction, flag account)
// ═══════════════════════════════════════════════════════════════════════════

const { onCall } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { admin, db, REGION } = require("./config");

// ── Risk Thresholds ─────────────────────────────────────────────────────
const RISK_ALLOW = 30;
const RISK_CHALLENGE = 60;
const RISK_REVIEW = 80;

// ── Velocity Windows ────────────────────────────────────────────────────
const PURCHASE_WINDOW_MS = 600_000; // 10 min
const MAX_PURCHASES_IN_WINDOW = 3;
const LOGIN_WINDOW_MS = 300_000; // 5 min
const MAX_LOGINS_IN_WINDOW = 10;

// ═══════════════════════════════════════════════════════════════════════════
// RISK SCORING ENGINE
// ═══════════════════════════════════════════════════════════════════════════

async function computeRiskScore(userId, fingerprint, purchaseData = {}) {
  let score = 0;
  const signals = [];

  // 1. Device Fingerprint History
  if (fingerprint) {
    const fpSnap = await db
      .collection("device_fingerprints")
      .where("fingerprint", "==", fingerprint)
      .limit(50)
      .get();

    const uniqueUsers = new Set(fpSnap.docs.map((d) => d.data().userId));
    if (uniqueUsers.size > 3) {
      score += 25;
      signals.push(`fingerprint_shared_by_${uniqueUsers.size}_users`);
    }

    // Check if this fingerprint was previously flagged
    const flagged = fpSnap.docs.some((d) => d.data().flagged);
    if (flagged) {
      score += 30;
      signals.push("fingerprint_previously_flagged");
    }
  } else {
    score += 10;
    signals.push("no_fingerprint");
  }

  // 2. Purchase Velocity
  const now = Date.now();
  const recentPurchases = await db
    .collection("ppv_purchases")
    .where("userId", "==", userId)
    .where("createdAt", ">", new Date(now - PURCHASE_WINDOW_MS))
    .get();

  if (recentPurchases.size >= MAX_PURCHASES_IN_WINDOW) {
    score += 20;
    signals.push(`velocity_${recentPurchases.size}_purchases_in_10min`);
  }

  // 3. Card Testing Pattern (many small purchases)
  if (purchaseData.amountCents && purchaseData.amountCents < 200) {
    const microPurchases = await db
      .collection("ppv_purchases")
      .where("userId", "==", userId)
      .where("amountCents", "<", 200)
      .where("createdAt", ">", new Date(now - 3600000))
      .get();

    if (microPurchases.size >= 3) {
      score += 25;
      signals.push(
        `card_testing_pattern_${microPurchases.size}_micro_purchases`,
      );
    }
  }

  // 4. Account Age
  const userDoc = await db.collection("users").doc(userId).get();
  if (userDoc.exists) {
    const createdAt = userDoc.data().createdAt?.toDate?.();
    if (createdAt) {
      const ageHours = (now - createdAt.getTime()) / 3600000;
      if (ageHours < 1) {
        score += 15;
        signals.push("account_age_under_1h");
      } else if (ageHours < 24) {
        score += 5;
        signals.push("account_age_under_24h");
      }
    }
  } else {
    score += 20;
    signals.push("user_not_found");
  }

  // 5. Geo-Mismatch (browser IP region vs card region)
  if (purchaseData.ipCountry && purchaseData.cardCountry) {
    if (purchaseData.ipCountry !== purchaseData.cardCountry) {
      score += 15;
      signals.push(
        `geo_mismatch_${purchaseData.ipCountry}_vs_${purchaseData.cardCountry}`,
      );
    }
  }

  // 6. Login Velocity (brute force indicator)
  const recentLogins = await db
    .collection("auth_events")
    .where("userId", "==", userId)
    .where("createdAt", ">", new Date(now - LOGIN_WINDOW_MS))
    .get();

  if (recentLogins.size >= MAX_LOGINS_IN_WINDOW) {
    score += 15;
    signals.push(`login_velocity_${recentLogins.size}_in_5min`);
  }

  // Cap at 100
  score = Math.min(100, score);

  // Determine action
  let action;
  if (score <= RISK_ALLOW) action = "allow";
  else if (score <= RISK_CHALLENGE) action = "challenge";
  else if (score <= RISK_REVIEW) action = "review";
  else action = "block";

  return { score, action, signals };
}

// ═══════════════════════════════════════════════════════════════════════════
// CALLABLE: Check Transaction Risk
// ═══════════════════════════════════════════════════════════════════════════

const checkTransactionRisk = onCall({ region: REGION }, async (request) => {
  const { userId, fingerprint, amountCents, ipCountry, cardCountry, eventId } =
    request.data;

  if (!userId) return { error: "userId is required" };

  const result = await computeRiskScore(userId, fingerprint, {
    amountCents,
    ipCountry,
    cardCountry,
  });

  // Log the check
  await db.collection("fraud_checks").add({
    userId,
    eventId: eventId || null,
    fingerprint: fingerprint || null,
    amountCents: amountCents || null,
    riskScore: result.score,
    action: result.action,
    signals: result.signals,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // If blocked, also flag the account
  if (result.action === "block") {
    await db
      .collection("users")
      .doc(userId)
      .update({
        fraudFlag: true,
        fraudFlaggedAt: admin.firestore.FieldValue.serverTimestamp(),
        fraudReason: result.signals.join(", "),
      });
  }

  return result;
});

// ═══════════════════════════════════════════════════════════════════════════
// CALLABLE: Report Fraud (Manual flag by ops team)
// ═══════════════════════════════════════════════════════════════════════════

const reportFraud = onCall({ region: REGION }, async (request) => {
  const { userId, reason, reportedBy } = request.data;

  if (!userId || !reason) return { error: "userId and reason are required" };

  await db.collection("fraud_reports").add({
    userId,
    reason,
    reportedBy: reportedBy || "system",
    status: "open",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Flag account
  await db.collection("users").doc(userId).update({
    fraudFlag: true,
    fraudFlaggedAt: admin.firestore.FieldValue.serverTimestamp(),
    fraudReason: reason,
  });

  // Flag device fingerprints for this user
  const fpSnap = await db
    .collection("device_fingerprints")
    .where("userId", "==", userId)
    .get();
  const batch = db.batch();
  for (const doc of fpSnap.docs) {
    batch.update(doc.ref, { flagged: true });
  }
  await batch.commit();

  return { status: "ok", message: `User ${userId} flagged for fraud` };
});

// ═══════════════════════════════════════════════════════════════════════════
// TRIGGER: Auto-check on new PPV purchases
// ═══════════════════════════════════════════════════════════════════════════

const onPurchaseCreated = onDocumentCreated(
  { document: "ppv_purchases/{purchaseId}", region: REGION },
  async (event) => {
    const data = event.data?.data();
    if (!data?.userId) return;

    const result = await computeRiskScore(data.userId, data.fingerprint, {
      amountCents: data.amountCents,
      ipCountry: data.ipCountry,
      cardCountry: data.cardCountry,
    });

    // Store risk assessment on purchase
    await event.data.ref.update({
      riskScore: result.score,
      riskAction: result.action,
      riskSignals: result.signals,
    });

    if (result.action === "review" || result.action === "block") {
      console.warn(
        `[anti-fraud] High risk purchase ${event.params.purchaseId}: score=${result.score} action=${result.action}`,
      );

      // Create alert for ops team
      await db.collection("fraud_alerts").add({
        purchaseId: event.params.purchaseId,
        userId: data.userId,
        riskScore: result.score,
        action: result.action,
        signals: result.signals,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        resolved: false,
      });
    }
  },
);

module.exports = {
  checkTransactionRisk,
  reportFraud,
  onPurchaseCreated,
};
