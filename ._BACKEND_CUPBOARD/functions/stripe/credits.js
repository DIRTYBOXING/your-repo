// ═══════════════════════════════════════════════════════════════════════════
// STRIPE FIGHT CREDITS — Credit Pack Purchase & Wallet Top-Up
// ═══════════════════════════════════════════════════════════════════════════
//
// Endpoints:
//   createCreditPackCheckout  — Create Stripe Checkout Session for credit pack
//   creditWalletTopup         — Webhook handler: credits wallet after payment
//
// Firestore:
//   credit_wallets/{userId}                — Balance, totalPurchased, totalSpent
//   credit_wallets/{userId}/transactions   — Every credit/debit ledger entry
//
// ═══════════════════════════════════════════════════════════════════════════

const { onCall } = require("firebase-functions/v2/https");
const {
  db,
  FieldValue,
  REGION,
  stripe,
  getStripe,
  withStripeSecret,
} = require("../config");

// ═══════════════════════════════════════════════════════════════════════════
// CREDIT PACK DEFINITIONS — Must match Dart CreditPack constants
// ═══════════════════════════════════════════════════════════════════════════

const CREDIT_PACKS = {
  pack_starter: {
    name: "Starter",
    credits: 5,
    priceCents: 500,
    pricePerCredit: 1,
  },
  pack_fight_fan: {
    name: "Fight Fan",
    credits: 10,
    priceCents: 900,
    pricePerCredit: 0.9,
  },
  pack_war_chest: {
    name: "War Chest",
    credits: 25,
    priceCents: 2000,
    pricePerCredit: 0.8,
  },
  pack_legend: {
    name: "Legend",
    credits: 50,
    priceCents: 3500,
    pricePerCredit: 0.7,
  },
};

// ═══════════════════════════════════════════════════════════════════════════
// CREATE CREDIT PACK CHECKOUT SESSION
// ═══════════════════════════════════════════════════════════════════════════

const createCreditPackCheckout = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    if (!getStripe()) return { error: "Stripe not configured" };

    const { userId, packId, amountCents, currency, successUrl, cancelUrl } =
      request.data;

    if (!userId || !packId || !amountCents) {
      return { error: "Missing required fields: userId, packId, amountCents" };
    }

    // Validate pack exists and price matches (server-side truth)
    const serverPack = CREDIT_PACKS[packId];
    if (!serverPack) {
      return { error: `Invalid pack ID: ${packId}` };
    }
    if (serverPack.priceCents !== amountCents) {
      return { error: "Price mismatch — possible tampering" };
    }

    try {
      // Get or create Stripe customer
      let customerId;
      const custDoc = await db.collection("stripe_customers").doc(userId).get();
      if (custDoc.exists && custDoc.data().stripeCustomerId) {
        customerId = custDoc.data().stripeCustomerId;
      } else {
        const userDoc = await db.collection("users").doc(userId).get();
        const email = userDoc.exists
          ? userDoc.data().email || `${userId}@dfc.app`
          : `${userId}@dfc.app`;
        const customer = await stripe.customers.create({
          email,
          metadata: { dfcUserId: userId },
        });
        customerId = customer.id;
        await db.collection("stripe_customers").doc(userId).set({
          stripeCustomerId: customerId,
          email,
          createdAt: FieldValue.serverTimestamp(),
        });
      }

      // Create Checkout Session
      const session = await stripe.checkout.sessions.create({
        customer: customerId,
        payment_method_types: ["card"],
        line_items: [
          {
            price_data: {
              currency: (currency || "aud").toLowerCase(),
              product_data: {
                name: `DFC Fight Credits: ${serverPack.name}`,
                description: `${serverPack.credits} Fight Credits — Use for pay-per-fight, replays, tips & more`,
                images: [
                  "https://datafightcentral.com/assets/logos/dfc_logo.png",
                ],
                metadata: {
                  packId,
                  credits: String(serverPack.credits),
                  productType: "credits",
                },
              },
              unit_amount: serverPack.priceCents,
            },
            quantity: 1,
          },
        ],
        mode: "payment",
        success_url:
          successUrl ||
          `https://datafightcentral.com/credits/success?session_id={CHECKOUT_SESSION_ID}`,
        cancel_url: cancelUrl || `https://datafightcentral.com/credits`,
        metadata: {
          dfcUserId: userId,
          packId,
          packName: serverPack.name,
          credits: String(serverPack.credits),
          productType: "credits",
        },
        payment_intent_data: {
          metadata: {
            dfcUserId: userId,
            packId,
            credits: String(serverPack.credits),
            productType: "credits",
          },
        },
      });

      // Log checkout attempt
      await db.collection("credit_checkout_sessions").add({
        sessionId: session.id,
        userId,
        packId,
        packName: serverPack.name,
        credits: serverPack.credits,
        amountCents: serverPack.priceCents,
        currency: (currency || "aud").toLowerCase(),
        status: "created",
        createdAt: FieldValue.serverTimestamp(),
      });

      return { url: session.url, sessionId: session.id };
    } catch (err) {
      console.error("createCreditPackCheckout error:", err);
      return { error: err.message };
    }
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// CREDIT WALLET TOP-UP — Called by Stripe webhook after successful payment
// ═══════════════════════════════════════════════════════════════════════════
//
// This is called from the main webhook handler when metadata.productType === 'credits'
// It atomically credits the user's wallet and writes a transaction record.
//

async function creditWalletTopup(paymentIntent) {
  const { dfcUserId, packId, credits } = paymentIntent.metadata;

  if (!dfcUserId || !credits) {
    console.error(
      "creditWalletTopup: missing metadata",
      paymentIntent.metadata,
    );
    return;
  }

  const creditsInt = Number.parseInt(credits, 10);
  if (Number.isNaN(creditsInt) || creditsInt <= 0) {
    console.error("creditWalletTopup: invalid credits value", credits);
    return;
  }

  const walletRef = db.collection("credit_wallets").doc(dfcUserId);
  const txnRef = walletRef.collection("transactions").doc();

  await db.runTransaction(async (txn) => {
    const walletDoc = await txn.get(walletRef);

    let balance = 0;
    let totalPurchased = 0;
    let totalSpent = 0;

    if (walletDoc.exists) {
      const data = walletDoc.data();
      balance = data.balance || 0;
      totalPurchased = data.totalPurchased || 0;
      totalSpent = data.totalSpent || 0;
    }

    txn.set(
      walletRef,
      {
        userId: dfcUserId,
        balance: balance + creditsInt,
        totalPurchased: totalPurchased + creditsInt,
        totalSpent,
        lastPurchaseAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    txn.set(txnRef, {
      userId: dfcUserId,
      amount: creditsInt,
      description: `Purchased ${CREDIT_PACKS[packId]?.name || packId} pack (${creditsInt} credits)`,
      stripePaymentIntentId: paymentIntent.id,
      createdAt: FieldValue.serverTimestamp(),
    });
  });

  // Update checkout session status
  const sessions = await db
    .collection("credit_checkout_sessions")
    .where("userId", "==", dfcUserId)
    .where("packId", "==", packId)
    .where("status", "==", "created")
    .orderBy("createdAt", "desc")
    .limit(1)
    .get();

  if (!sessions.empty) {
    await sessions.docs[0].ref.update({
      status: "completed",
      paymentIntentId: paymentIntent.id,
      completedAt: FieldValue.serverTimestamp(),
    });
  }

  console.log(
    `Fight credits granted: ${creditsInt} credits to ${dfcUserId} (pack: ${packId})`,
  );
}

module.exports = {
  createCreditPackCheckout,
  creditWalletTopup,
};
