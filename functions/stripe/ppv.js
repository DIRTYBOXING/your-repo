// ═══════════════════════════════════════════════════════════════════════════
// STRIPE PPV PAYMENTS — Micro-Package Pay-Per-View System
// ═══════════════════════════════════════════════════════════════════════════

const { onCall } = require("firebase-functions/v2/https");
const {
  admin,
  db,
  FieldValue,
  Timestamp,
  REGION,
  stripe,
  getStripe,
  withStripeSecret,
} = require("../config");
const { enqueuerFighterEarnings } = require("./fighter_earnings");
const { grantRoundAccess } = require("./round_access");

const {
  getCanonicalPpvAccessState,
  isPurchaseRecordActive,
  readPpvLaterLine,
  resolvePpvEventDocument,
  resolvePpvLookupIds,
} = require("../ppv/access_state");

const {
  buildCanonicalPpvCheckoutSessionRecord,
  upsertCanonicalPpvCheckoutSession,
} = require("../ppv/canonical_checkout_sessions");
// ═══════════════════════════════════════════════════════════════════════════
// PPV PRICING TIERS
// ═══════════════════════════════════════════════════════════════════════════

const PPV_TIERS = {
  // MICRO PACKAGES
  0: { name: "SINGLE ROUND", price: 199, credits: 20, type: "micro" },
  1: { name: "HIGHLIGHTS", price: 399, credits: 40, type: "micro" },
  2: { name: "SINGLE FIGHT", price: 999, credits: 100, type: "micro" },
  // STANDARD PACKAGES
  3: { name: "PRELIMS", price: 1499, credits: 150, type: "standard" },
  4: { name: "MAIN CARD", price: 2999, credits: 300, type: "standard" },
  5: { name: "FULL SHOW", price: 4999, credits: 500, type: "standard" },
  // PREMIUM BUNDLES
  6: { name: "FIGHTER PASS", price: 1999, credits: 200, type: "premium" },
  7: { name: "REGION BUNDLE", price: 2499, credits: 250, type: "premium" },
  8: { name: "TITLE FIGHTS", price: 3999, credits: 400, type: "premium" },
};

// ═══════════════════════════════════════════════════════════════════════════
// DFC SLIDING AGREEMENT — Commission scales with exposure
// ═══════════════════════════════════════════════════════════════════════════
// DFC REVENUE MODEL — The Crown of Thorns
// You built the platform, the factory, 22+ machines, international pipeline,
// the PPV system, the email cannon, the AI bots — ALL of it.
// Promoters use YOUR infrastructure. They pay for the privilege.
//
// SLIDING SCALE (not fixed tiers — smooth interpolation):
//   Floor:   30% DFC at 0 buys
//   Ceiling: 50% DFC at 10,000+ buys
//   Between: Linear slide — no hard jumps, fair and transparent
//
// Example: 5,000 buys = 40% DFC | 2,500 buys = 35% DFC | 7,500 buys = 45% DFC

const DFC_FEE_FLOOR = 0.3;
const DFC_FEE_CEILING = 0.5;
const DFC_MAX_EXPOSURE = 10000;

function getDfcFeePercent(buyCount) {
  if (buyCount <= 0) return DFC_FEE_FLOOR;
  if (buyCount >= DFC_MAX_EXPOSURE) return DFC_FEE_CEILING;
  // Linear interpolation — smooth sliding agreement
  return (
    DFC_FEE_FLOOR +
    (DFC_FEE_CEILING - DFC_FEE_FLOOR) * (buyCount / DFC_MAX_EXPOSURE)
  );
}

async function getOrCreateStripeCustomerId(userId) {
  const custDoc = await db.collection("stripe_customers").doc(userId).get();
  if (custDoc.exists && custDoc.data().stripeCustomerId) {
    return custDoc.data().stripeCustomerId;
  }

  const userDoc = await db.collection("users").doc(userId).get();
  const email = userDoc.exists
    ? userDoc.data().email || `${userId}@dfc.app`
    : `${userId}@dfc.app`;
  const customer = await stripe.customers.create({
    email,
    metadata: { dfcUserId: userId },
  });

  await db.collection("stripe_customers").doc(userId).set({
    stripeCustomerId: customer.id,
    email,
    createdAt: FieldValue.serverTimestamp(),
  });

  return customer.id;
}

async function resolvePromoAdjustment({ promoCode, amountCents }) {
  if (!promoCode) {
    return {
      finalAmount: amountCents,
      discountCents: 0,
      stripeCouponId: null,
    };
  }

  const promoDoc = await db
    .collection("promo_codes")
    .doc(promoCode.toUpperCase())
    .get();
  if (!promoDoc.exists) {
    return {
      finalAmount: amountCents,
      discountCents: 0,
      stripeCouponId: null,
    };
  }

  const promo = promoDoc.data();
  const isValidForPpv =
    promo.active &&
    (!promo.productTypes ||
      promo.productTypes.includes("all") ||
      promo.productTypes.includes("ppv"));
  if (!isValidForPpv) {
    return {
      finalAmount: amountCents,
      discountCents: 0,
      stripeCouponId: null,
    };
  }

  let discountCents = 0;
  if (promo.percentOff) {
    discountCents = Math.round(amountCents * (promo.percentOff / 100));
  } else if (promo.amountOffCents) {
    discountCents = Math.min(promo.amountOffCents, amountCents);
  }

  return {
    finalAmount: Math.max(0, amountCents - discountCents),
    discountCents,
    stripeCouponId: promo.stripeCouponId || null,
  };
}

async function resolveCheckoutRevenueContext({ ppvId, finalAmount }) {
  const resolvedEvent = await resolvePpvEventDocument(db, ppvId);
  const promoterId = resolvedEvent?.data?.promoterId || null;

  let cumulativeBuys = 0;
  if (promoterId) {
    const statsDoc = await db
      .collection("promoter_stats")
      .doc(promoterId)
      .get();
    cumulativeBuys = statsDoc.exists ? statsDoc.data().totalPPVBuys || 0 : 0;
  }

  const dfcFeePercent = getDfcFeePercent(cumulativeBuys);
  const dfcFeeCents = Math.round(finalAmount * dfcFeePercent);

  let connectedAccountId = null;
  if (promoterId) {
    const connectDoc = await db
      .collection("connected_accounts_v2")
      .doc(promoterId)
      .get();
    if (
      connectDoc.exists &&
      connectDoc.data().stripeAccountId &&
      connectDoc.data().onboardingComplete
    ) {
      connectedAccountId = connectDoc.data().stripeAccountId;
    }
  }

  return {
    promoterId,
    cumulativeBuys,
    dfcFeePercent,
    dfcFeeCents,
    connectedAccountId,
  };
}

function buildCheckoutSessionParams({
  customerId,
  userId,
  ppvId,
  ppvTitle,
  tierId,
  tier,
  displayTierName,
  semanticTierKey,
  amountCents,
  originalAmountCents,
  discountCents,
  currency,
  promoCode,
  successUrl,
  cancelUrl,
  checkoutSource,
  legacyPriceId,
  dfcFeePercent,
  dfcFeeCents,
  promoterId,
  connectedAccountId,
  stripeCouponId,
}) {
  const sessionParams = {
    customer: customerId,
    payment_method_types: ["card"],
    billing_address_collection: "required",
    line_items: [
      {
        price_data: {
          currency: (currency || "aud").toLowerCase(),
          product_data: {
            name: displayTierName,
            description: `PPV: ${ppvTitle || "DFC Event"} - ${tier.type.toUpperCase()} Package`,
            images: ["https://datafightcentral.com/assets/logos/dfc_logo.png"],
            metadata: {
              ppvId,
              tierId: String(tierId),
              tierKey: semanticTierKey,
              tierType: tier.type,
            },
          },
          unit_amount: amountCents,
        },
        quantity: 1,
      },
    ],
    mode: "payment",
    success_url:
      successUrl ||
      `https://datafightcentral.com/ppv/${ppvId}/success?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: cancelUrl || `https://datafightcentral.com/ppv/${ppvId}`,
    metadata: {
      dfcUserId: userId,
      ppvId,
      tierId: String(tierId),
      tierName: displayTierName,
      tierKey: semanticTierKey,
      productType: "ppv",
      originalAmountCents: String(originalAmountCents),
      discountCents: String(discountCents),
      promoCode: promoCode || "",
      checkoutSource: checkoutSource || "functions/stripe/ppv",
      legacyPriceId: legacyPriceId || "",
      dfcFeePercent: String(dfcFeePercent),
      dfcFeeCents: String(dfcFeeCents),
      promoterId: promoterId || "",
      settlementMode: "event_reconciliation",
    },
    payment_intent_data: {
      metadata: {
        dfcUserId: userId,
        ppvId,
        tierId: String(tierId),
        tierKey: semanticTierKey,
        productType: "ppv",
        checkoutSource: checkoutSource || "functions/stripe/ppv",
        legacyPriceId: legacyPriceId || "",
        dfcFeePercent: String(dfcFeePercent),
        dfcFeeCents: String(dfcFeeCents),
        promoterId: promoterId || "",
        connectedAccountId: connectedAccountId || "",
        settlementMode: "event_reconciliation",
      },
    },
  };

  if (stripeCouponId && discountCents > 0) {
    sessionParams.discounts = [{ coupon: stripeCouponId }];
  }

  return sessionParams;
}

async function logCheckoutSessionAttempt({
  session,
  userId,
  ppvId,
  tierId,
  displayTierName,
  semanticTierKey,
  tierType,
  finalAmount,
  originalAmountCents,
  discountCents,
  promoCode,
  legacyPriceId,
  currency,
  promoterId,
  dfcFeePercent,
  dfcFeeCents,
  cumulativeBuys,
  connectedAccountId,
  checkoutSource,
}) {
  await db
    .collection("ppv_checkout_sessions")
    .doc(session.id)
    .set(
      {
        sessionId: session.id,
        userId,
        ppvId,
        tierId,
        tierName: displayTierName,
        tierKey: semanticTierKey,
        tierType,
        amountCents: finalAmount,
        originalAmountCents,
        discountCents,
        promoCode: promoCode || null,
        legacyPriceId: legacyPriceId || null,
        currency: (currency || "aud").toLowerCase(),
        paymentMethod: "card",
        paymentProvider: "stripe",
        paymentStatus: "pending",
        promoterId: promoterId || null,
        connectedAccountId: connectedAccountId || null,
        dfcFeePercent,
        dfcFeeCents,
        cumulativeBuys,
        settlementMode: "event_reconciliation",
        directTransferEnabled: false,
        status: "pending",
        source: "functions/stripe/ppv",
        requestSource: checkoutSource || "functions/stripe/ppv",
        checkoutSource: checkoutSource || "functions/stripe/ppv",
        accessGranted: false,
        isActive: false,
        replayExpired: false,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
}

// ═══════════════════════════════════════════════════════════════════════════
// CREATE PPV CHECKOUT SESSION (Hosted Stripe Checkout)
// ═══════════════════════════════════════════════════════════════════════════

const createPPVCheckoutSession = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    if (!getStripe()) return { error: "Stripe not configured" };

    const {
      userId,
      ppvId,
      ppvTitle,
      tierId,
      tierName,
      tierKey,
      amountCents,
      currency,
      promoCode,
      successUrl,
      cancelUrl,
      checkoutSource,
      legacyPriceId,
    } = request.data;

    if (!userId || !ppvId || tierId === undefined || !amountCents) {
      return {
        error: "Missing required fields: userId, ppvId, tierId, amountCents",
      };
    }

    try {
      const accessState = await getCanonicalPpvAccessState({
        db,
        userId,
        eventId: ppvId,
      });
      if (accessState.hasAccess) {
        return {
          alreadyPurchased: true,
          message: "You already have access to this PPV event",
        };
      }

      const customerId = await getOrCreateStripeCustomerId(userId);
      const { finalAmount, discountCents, stripeCouponId } =
        await resolvePromoAdjustment({ promoCode, amountCents });
      const {
        promoterId,
        cumulativeBuys,
        dfcFeePercent,
        dfcFeeCents,
        connectedAccountId,
      } = await resolveCheckoutRevenueContext({ ppvId, finalAmount });

      const tier = PPV_TIERS[tierId] || PPV_TIERS[4];
      const displayTierName = tierName || tier.name;
      const semanticTierKey = (tierKey || displayTierName || tier.name)
        .toString()
        .trim();
      const sessionParams = buildCheckoutSessionParams({
        customerId,
        userId,
        ppvId,
        ppvTitle,
        tierId,
        tier,
        displayTierName,
        semanticTierKey,
        amountCents: finalAmount,
        originalAmountCents: amountCents,
        discountCents,
        currency,
        promoCode,
        successUrl,
        cancelUrl,
        checkoutSource,
        legacyPriceId,
        dfcFeePercent,
        dfcFeeCents,
        promoterId,
        connectedAccountId,
        stripeCouponId,
      });

      const session = await stripe.checkout.sessions.create(sessionParams);

      await logCheckoutSessionAttempt({
        session,
        userId,
        ppvId,
        tierId,
        displayTierName,
        semanticTierKey,
        tierType: tier.type,
        finalAmount,
        originalAmountCents: amountCents,
        discountCents,
        promoCode,
        legacyPriceId,
        currency,
        promoterId,
        dfcFeePercent,
        dfcFeeCents,
        cumulativeBuys,
        connectedAccountId,
        checkoutSource,
      });

      return {
        sessionId: session.id,
        url: session.url,
        amountCents: finalAmount,
        discountCents,
        dfcFeePercent,
        dfcFeeCents,
        settlementMode: "event_reconciliation",
      };
    } catch (err) {
      console.error("createPPVCheckoutSession error:", err);
      return { error: err.message };
    }
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// CREATE PPV PAYMENT INTENT (For Payment Sheet / Native)
// ═══════════════════════════════════════════════════════════════════════════

const createPPVPaymentIntent = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    return {
      error:
        "PPV PaymentIntent checkout has been retired. Use createPPVCheckoutSession instead.",
      code: "ppv_payment_intent_retired",
      checkoutRequired: true,
    };
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// CREATE CREDITS CHECKOUT SESSION
// ═══════════════════════════════════════════════════════════════════════════

const CREDIT_PACKS = [
  { credits: 100, price: 1000, total: 100 }, // $10 = 100C
  { credits: 300, price: 2700, total: 330 }, // $27 = 330C (18% off)
  { credits: 700, price: 6000, total: 800 }, // $60 = 800C (25% off)
  { credits: 1500, price: 12000, total: 1800 }, // $120 = 1800C (33% off)
];

const createCreditsCheckoutSession = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    if (!getStripe()) return { error: "Stripe not configured" };

    const { userId, credits, amountCents, currency, successUrl, cancelUrl } =
      request.data;

    if (!userId || !credits || !amountCents) {
      return { error: "Missing required fields" };
    }

    try {
      // Get or create customer
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

      const session = await stripe.checkout.sessions.create({
        customer: customerId,
        payment_method_types: ["card"],
        billing_address_collection: "required",
        line_items: [
          {
            price_data: {
              currency: (currency || "aud").toLowerCase(),
              product_data: {
                name: `${credits} DFC Credits`,
                description: "Spend on any PPV content, replays, or highlights",
                images: [
                  "https://datafightcentral.com/assets/logos/dfc_logo.png",
                ],
                metadata: { productType: "credits", credits: String(credits) },
              },
              unit_amount: amountCents,
            },
            quantity: 1,
          },
        ],
        mode: "payment",
        success_url:
          successUrl ||
          `https://datafightcentral.com/credits/success?session_id={CHECKOUT_SESSION_ID}`,
        cancel_url: cancelUrl || "https://datafightcentral.com/credits",
        metadata: {
          dfcUserId: userId,
          productType: "credits",
          credits: String(credits),
        },
        payment_intent_data: {
          metadata: {
            dfcUserId: userId,
            productType: "credits",
            credits: String(credits),
          },
        },
      });

      // Log checkout attempt
      await db.collection("credits_checkout_sessions").add({
        sessionId: session.id,
        userId,
        credits,
        amountCents,
        currency: (currency || "aud").toLowerCase(),
        status: "pending",
        createdAt: FieldValue.serverTimestamp(),
      });

      return {
        sessionId: session.id,
        url: session.url,
      };
    } catch (err) {
      console.error("createCreditsCheckoutSession error:", err);
      return { error: err.message };
    }
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// GRANT PPV ACCESS (Called by webhook after successful payment)
// ═══════════════════════════════════════════════════════════════════════════

const grantPPVAccess = async (paymentIntent) => {
  const { canonicalSessionId = null, metadata = {} } = paymentIntent || {};
  const { dfcUserId, ppvId, tierId, tierName, tierKey, tierType, productType } =
    metadata;

  if (productType !== "ppv" || !dfcUserId || !ppvId) {
    console.log("Not a PPV payment or missing metadata");
    return;
  }

  try {
    const normalizedTierId = Number.parseInt(tierId, 10) || 4;
    const tier = PPV_TIERS[normalizedTierId] || PPV_TIERS[4];
    const sessionRecord = await upsertCanonicalPpvCheckoutSession({
      db,
      sessionId: canonicalSessionId,
      stripeSessionId: canonicalSessionId,
      stripePaymentIntentId: paymentIntent.id,
      userId: dfcUserId,
      ppvId,
      tierId: normalizedTierId,
      tierName: tierName || tier.name,
      tierKey: tierKey || tierName || tier.name,
      tierType: tierType || tier.type,
      amountCents: paymentIntent.amount || 0,
      originalAmountCents: metadata.originalAmountCents,
      discountCents: metadata.discountCents,
      currency: paymentIntent.currency || "aud",
      paymentMethod: metadata.paymentMethod || "card",
      paymentProvider: "stripe",
      status: "complete",
      paymentStatus: "succeeded",
      source: canonicalSessionId
        ? "functions/stripe/ppv"
        : "legacy-payment-intent",
      requestSource:
        metadata.checkoutSource ||
        (canonicalSessionId ? "functions/stripe/ppv" : "legacy-payment-intent"),
      checkoutSource:
        metadata.checkoutSource ||
        (canonicalSessionId ? "functions/stripe/ppv" : "legacy-payment-intent"),
      legacyPriceId: metadata.legacyPriceId,
      promoterId: metadata.promoterId,
    });

    const canonicalPpvId = sessionRecord.canonicalPpvId;
    const compositeId = `${dfcUserId}_${canonicalPpvId}`;
    const existingPurchase = await db
      .collection("ppv_purchases")
      .doc(compositeId)
      .get();
    if (
      existingPurchase.exists &&
      isPurchaseRecordActive(existingPurchase.data() || {})
    ) {
      console.log(
        `PPV purchase already exists: ${compositeId} — skipping (idempotent)`,
      );
      return;
    }

    const expiresAt = Timestamp.fromDate(
      sessionRecord.expiresAt || new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    );
    const eventEndedAt = sessionRecord.eventEndedAt;

    // ── Write to ppv_purchases (canonical purchase record) ──
    const purchasePayload = {
      id: compositeId,
      userId: dfcUserId,
      ppvId: canonicalPpvId,
      ppvEventId: canonicalPpvId,
      eventId: canonicalPpvId,
      tierId: normalizedTierId,
      tierName: tierName || tier.name,
      tierKey: tierKey || tierName || tier.name,
      tierType: tierType || tier.type,
      paymentMethod: metadata.paymentMethod || "card",
      paymentProvider: "stripe",
      stripePaymentId: paymentIntent.id,
      amountCents: paymentIntent.amount,
      currency: paymentIntent.currency.toUpperCase(),
      status: "completed",
      paymentStatus: "succeeded",
      accessGranted: true,
      isActive: true,
      replayExpired: false,
      purchasedAt: FieldValue.serverTimestamp(),
      expiresAt,
    };
    if (canonicalPpvId !== ppvId) {
      purchasePayload.sourceEventId = ppvId;
    }
    if (eventEndedAt) {
      purchasePayload.eventEndedAt = Timestamp.fromDate(eventEndedAt);
    }
    await db
      .collection("ppv_purchases")
      .doc(compositeId)
      .set(purchasePayload, { merge: true });

    // ── DUAL-WRITE to ppv_access (gatekeeper reads this collection) ──
    const accessPayload = {
      userId: dfcUserId,
      eventId: canonicalPpvId,
      bundleName: tierName || tier.name,
      tierId: normalizedTierId,
      tierName: tierName || tier.name,
      tierKey: tierKey || tierName || tier.name,
      price: (paymentIntent.amount || 0) / 100,
      stripePaymentId: paymentIntent.id,
      grantedAt: FieldValue.serverTimestamp(),
      expiresAt,
      accessGranted: true,
      paymentStatus: "succeeded",
      isActive: true,
      replayExpired: false,
    };
    if (canonicalPpvId !== ppvId) {
      accessPayload.sourceEventId = ppvId;
    }
    await db
      .collection("ppv_access")
      .doc(compositeId)
      .set(accessPayload, { merge: true });

    // ── DUAL-WRITE to purchases + entitlements (web/mobile unified gate) ──
    await db
      .collection("purchases")
      .doc(compositeId)
      .set(
        {
          userId: dfcUserId,
          eventId: canonicalPpvId,
          provider: "stripe",
          providerPaymentId: paymentIntent.id,
          amount: Number(((paymentIntent.amount || 0) / 100).toFixed(2)),
          currency: (paymentIntent.currency || "aud").toUpperCase(),
          status: "completed",
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
          entitlementExpiresAt: expiresAt,
          sourcePurchaseId: compositeId,
          ...(canonicalPpvId !== ppvId ? { sourceEventId: ppvId } : {}),
        },
        { merge: true },
      );

    await db
      .collection("entitlements")
      .doc(compositeId)
      .set(
        {
          userId: dfcUserId,
          eventId: canonicalPpvId,
          hasAccess: true,
          grantedAt: FieldValue.serverTimestamp(),
          sourcePurchaseId: compositeId,
          updatedAt: FieldValue.serverTimestamp(),
          ...(canonicalPpvId !== ppvId ? { sourceEventId: ppvId } : {}),
        },
        { merge: true },
      );

    // Update payment intent status
    await db
      .collection("ppv_payment_intents")
      .doc(paymentIntent.id)
      .update({
        status: "succeeded",
        accessGranted: true,
        completedAt: FieldValue.serverTimestamp(),
      })
      .catch(() => {});

    console.log(
      `PPV access granted: user=${dfcUserId}, ppv=${ppvId}, tier=${tierName}, docId=${compositeId}`,
    );

    // ── FIGHTER MICRO-EARNINGS: Queue 20% fighter share ──
    await enqueueFighterEarnings({
      ppvId,
      amountCents: paymentIntent.amount,
      currency: paymentIntent.currency,
      paymentId: paymentIntent.id,
      buyerUserId: dfcUserId,
    });
  } catch (err) {
    console.error("grantPPVAccess error:", err);
  }
};

// ═══════════════════════════════════════════════════════════════════════════
// GRANT CREDITS (Called by webhook after successful payment)
// ═══════════════════════════════════════════════════════════════════════════

const grantCredits = async (paymentIntent) => {
  const { dfcUserId, credits, productType } = paymentIntent.metadata || {};

  if (productType !== "credits" || !dfcUserId || !credits) {
    console.log("Not a credits payment or missing metadata");
    return;
  }

  try {
    const creditsToAdd = Number.parseInt(credits, 10);

    // Update user credit balance
    const userCreditsRef = db.collection("user_credits").doc(dfcUserId);
    const userCreditsDoc = await userCreditsRef.get();

    if (userCreditsDoc.exists) {
      await userCreditsRef.update({
        balance: FieldValue.increment(creditsToAdd),
        lastPurchase: FieldValue.serverTimestamp(),
      });
    } else {
      await userCreditsRef.set({
        userId: dfcUserId,
        balance: creditsToAdd,
        totalPurchased: creditsToAdd,
        totalSpent: 0,
        createdAt: FieldValue.serverTimestamp(),
        lastPurchase: FieldValue.serverTimestamp(),
      });
    }

    // Log credit transaction
    await db.collection("credit_transactions").add({
      userId: dfcUserId,
      type: "purchase",
      amount: creditsToAdd,
      stripePaymentId: paymentIntent.id,
      amountCents: paymentIntent.amount,
      description: `Purchased ${creditsToAdd} credits`,
      timestamp: FieldValue.serverTimestamp(),
    });

    console.log(`Credits granted: user=${dfcUserId}, credits=${creditsToAdd}`);
  } catch (err) {
    console.error("grantCredits error:", err);
  }
};

// ═══════════════════════════════════════════════════════════════════════════
// CHECK PPV ACCESS
// ═══════════════════════════════════════════════════════════════════════════

const checkPPVAccess = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    const { userId, ppvId } = request.data;

    if (!userId || !ppvId) {
      return { hasAccess: false, error: "Missing userId or ppvId" };
    }

    try {
      const accessState = await getCanonicalPpvAccessState({
        db,
        userId,
        eventId: ppvId,
      });

      const resolvedTierId = Number.isInteger(accessState.tierId)
        ? accessState.tierId
        : null;
      const expiresAt = accessState.expiresAt || null;

      if (!accessState.hasAccess) {
        return {
          hasAccess: false,
          status: accessState.reason,
          tierLevel: resolvedTierId,
          tierName: accessState.tierName || null,
          tierKey: accessState.tierKey || null,
          expiresAt,
        };
      }

      const tier = PPV_TIERS[resolvedTierId ?? 4] || PPV_TIERS[4];
      return {
        hasAccess: true,
        status: "granted",
        tierLevel: resolvedTierId ?? 4,
        tierName: accessState.tierName || tier.name,
        tierKey: accessState.tierKey || accessState.tierName || tier.name,
        tierType: tier.type,
        expiresAt,
      };
    } catch (err) {
      console.error("checkPPVAccess error:", err);
      return { hasAccess: false, error: err.message };
    }
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// SPEND CREDITS FOR PPV
// ═══════════════════════════════════════════════════════════════════════════

const spendCreditsForPPV = onCall({ region: REGION }, async (request) => {
  const { userId, ppvId, tierId } = request.data;

  if (!userId || !ppvId || tierId === undefined || tierId === null) {
    return { error: "Missing required fields: userId, ppvId, tierId" };
  }

  try {
    const accessState = await getCanonicalPpvAccessState({
      db,
      userId,
      eventId: ppvId,
    });
    if (accessState.hasAccess) {
      return {
        alreadyPurchased: true,
        message: "You already have access to this PPV event",
      };
    }

    const tier = PPV_TIERS[tierId] || PPV_TIERS[4];
    const creditsRequired = tier.credits;
    const sessionRecord = await buildCanonicalPpvCheckoutSessionRecord({
      db,
      sessionId: `credits_${userId}_${ppvId}`,
      userId,
      ppvId,
      tierId,
      tierName: tier.name,
      tierKey: tier.name,
      tierType: tier.type,
      amountCents: 0,
      originalAmountCents: 0,
      discountCents: 0,
      currency: "aud",
      paymentMethod: "credits",
      paymentProvider: "credits",
      status: "complete",
      paymentStatus: "succeeded",
      source: "credits-wallet",
      requestSource: "credits-wallet",
      checkoutSource: "credits-wallet",
      creditsSpent: creditsRequired,
    });

    const compositeId = `${userId}_${sessionRecord.canonicalPpvId}`;
    const userCreditsRef = db.collection("user_credits").doc(userId);
    const sessionRef = db
      .collection("ppv_checkout_sessions")
      .doc(sessionRecord.sessionId);
    const purchaseRef = db.collection("ppv_purchases").doc(compositeId);
    const accessRef = db.collection("ppv_access").doc(compositeId);
    const creditTxnRef = db.collection("credit_transactions").doc();
    const hasSourceEventAlias =
      sessionRecord.sourceEventId !== sessionRecord.canonicalPpvId;

    await db.runTransaction(async (txn) => {
      const [userCreditsDoc, sessionDoc] = await Promise.all([
        txn.get(userCreditsRef),
        txn.get(sessionRef),
      ]);

      const currentCredits = userCreditsDoc.exists
        ? userCreditsDoc.data()?.balance || 0
        : 0;

      if (currentCredits < creditsRequired) {
        throw new Error(
          `Not enough credits. Need ${creditsRequired}, have ${currentCredits}`,
        );
      }

      txn.set(
        userCreditsRef,
        {
          userId,
          balance: currentCredits - creditsRequired,
          totalSpent: FieldValue.increment(creditsRequired),
          lastSpent: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      const sessionCreationFields = sessionDoc.exists
        ? {}
        : { createdAt: FieldValue.serverTimestamp() };

      txn.set(
        sessionRef,
        {
          ...sessionRecord.payload,
          ...sessionCreationFields,
        },
        { merge: true },
      );

      txn.set(
        purchaseRef,
        {
          id: compositeId,
          userId,
          ppvId: sessionRecord.canonicalPpvId,
          ppvEventId: sessionRecord.canonicalPpvId,
          eventId: sessionRecord.canonicalPpvId,
          ...(hasSourceEventAlias
            ? { sourceEventId: sessionRecord.sourceEventId }
            : {}),
          tierId: Number.parseInt(tierId, 10) || 4,
          tierName: tier.name,
          tierKey: tier.name,
          tierType: tier.type,
          paymentMethod: "credits",
          paymentProvider: "credits",
          creditsSpent: creditsRequired,
          amountCents: 0,
          currency: "AUD",
          status: "completed",
          paymentStatus: "succeeded",
          accessGranted: true,
          isActive: true,
          replayExpired: false,
          purchasedAt: FieldValue.serverTimestamp(),
          ...(sessionRecord.expiresAt
            ? { expiresAt: Timestamp.fromDate(sessionRecord.expiresAt) }
            : {}),
          ...(sessionRecord.eventEndedAt
            ? { eventEndedAt: Timestamp.fromDate(sessionRecord.eventEndedAt) }
            : {}),
        },
        { merge: true },
      );

      txn.set(
        accessRef,
        {
          userId,
          eventId: sessionRecord.canonicalPpvId,
          ...(hasSourceEventAlias
            ? { sourceEventId: sessionRecord.sourceEventId }
            : {}),
          bundleName: tier.name,
          tierId: Number.parseInt(tierId, 10) || 4,
          tierName: tier.name,
          tierKey: tier.name,
          price: 0,
          stripePaymentId: "credits",
          grantedAt: FieldValue.serverTimestamp(),
          ...(sessionRecord.expiresAt
            ? { expiresAt: Timestamp.fromDate(sessionRecord.expiresAt) }
            : {}),
          accessGranted: true,
          paymentStatus: "succeeded",
          isActive: true,
          replayExpired: false,
        },
        { merge: true },
      );

      txn.set(creditTxnRef, {
        userId,
        type: "spend",
        amount: -creditsRequired,
        productType: "ppv",
        productId: sessionRecord.canonicalPpvId,
        description: `PPV: ${tier.name}`,
        timestamp: FieldValue.serverTimestamp(),
      });
    });

    return {
      success: true,
      sessionId: sessionRecord.sessionId,
      canonicalPpvId: sessionRecord.canonicalPpvId,
      tierId: Number.parseInt(tierId, 10) || 4,
      tierName: tier.name,
      creditsSpent: creditsRequired,
    };
  } catch (err) {
    console.error("spendCreditsForPPV error:", err);
    return { error: err.message };
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// GET USER CREDITS BALANCE
// ═══════════════════════════════════════════════════════════════════════════

const getUserCredits = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    const { userId } = request.data;

    if (!userId) {
      return { balance: 0, error: "Missing userId" };
    }

    try {
      const doc = await db.collection("user_credits").doc(userId).get();
      if (!doc.exists) {
        return { balance: 0, totalPurchased: 0, totalSpent: 0 };
      }

      const data = doc.data();
      return {
        balance: data.balance || 0,
        totalPurchased: data.totalPurchased || 0,
        totalSpent: data.totalSpent || 0,
      };
    } catch (err) {
      console.error("getUserCredits error:", err);
      return { balance: 0, error: err.message };
    }
  },
);

module.exports = {
  createPPVCheckoutSession,
  createPPVPaymentIntent,
  createCreditsCheckoutSession,
  grantPPVAccess,
  grantCredits,
  checkPPVAccess,
  spendCreditsForPPV,
  getUserCredits,
  PPV_TIERS,
  CREDIT_PACKS,
  getDfcFeePercent,
};
