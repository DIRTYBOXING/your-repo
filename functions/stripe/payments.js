// ═══════════════════════════════════════════════════════════════════════════
// STRIPE PAYMENTS — Legacy V1 payments, refunds, promo codes
// ═══════════════════════════════════════════════════════════════════════════

const { onCall, onRequest } = require("firebase-functions/v2/https");
const {
  admin,
  db,
  FieldValue,
  REGION,
  stripe,
  getStripe,
  withStripeSecret,
} = require("../config");
const { grantPPVAccess } = require("./ppv");

const STRIPE_WEBHOOK_SECRET = process.env.STRIPE_WEBHOOK_SECRET || "";
const BASE_URL = process.env.BASE_URL || "https://datafightcentral.com";
const CONNECTED_ACCOUNTS_V2 = "connected_accounts_v2";

function getV2ConnectStatus(readyToProcessPayments, onboardingComplete) {
  if (readyToProcessPayments) return "active";
  if (onboardingComplete) return "pending_verification";
  return "onboarding_required";
}

function getV2OnboardingStatus(readyToProcessPayments, onboardingComplete) {
  if (readyToProcessPayments) return "complete";
  if (onboardingComplete) return "pending_verification";
  return "onboarding_required";
}

function getLegacyConnectStatus(
  chargesEnabled,
  payoutsEnabled,
  detailsSubmitted,
) {
  if (chargesEnabled && payoutsEnabled) return "active";
  if (detailsSubmitted) return "pending_verification";
  return "onboarding";
}

function getPlatformFeeRate(productType) {
  const feeRates = {
    ppv: 0.3,
    marketplace: 0.25,
    ticket: 0.15,
    donation: 0,
    subscription: 1,
  };

  return feeRates[productType] || 0.3;
}

function mergeMetadata(baseMetadata, extraMetadata) {
  const metadata = { ...baseMetadata };
  if (extraMetadata) {
    Object.assign(metadata, extraMetadata);
  }
  return metadata;
}

async function getOrCreateStripeCustomer(userId) {
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

async function getPromoDocOrError(code, productType) {
  const promoDoc = await db
    .collection("promo_codes")
    .doc(code.toUpperCase())
    .get();
  if (!promoDoc.exists) return { error: "Invalid promo code" };

  const promo = promoDoc.data();
  if (!promo.active) return { error: "Code no longer active" };
  if (promo.expiresAt && new Date(promo.expiresAt.toDate()) < new Date()) {
    return { error: "Code expired" };
  }
  if (promo.maxRedemptions && promo.timesRedeemed >= promo.maxRedemptions) {
    return { error: "Redemption limit reached" };
  }
  if (
    productType &&
    promo.productTypes &&
    !promo.productTypes.includes("all") &&
    !promo.productTypes.includes(productType)
  ) {
    return { error: `Code not valid for ${productType}` };
  }

  return { promo };
}

function getDiscountCents(promo, amountCents) {
  if (promo.percentOff) {
    return Math.round(amountCents * (promo.percentOff / 100));
  }
  if (promo.amountOffCents) {
    return Math.min(promo.amountOffCents, amountCents);
  }
  return 0;
}

async function findUserIdByStripeCustomerId(customerId) {
  const custQuery = await db
    .collection("stripe_customers")
    .where("stripeCustomerId", "==", customerId)
    .limit(1)
    .get();

  if (custQuery.empty) return null;
  return custQuery.docs[0].id;
}

async function handleSucceededPaymentIntent(paymentIntent) {
  await db.collection("payment_intents").doc(paymentIntent.id).set(
    {
      status: "succeeded",
      completedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  const ppvId =
    paymentIntent.metadata?.ppvId || paymentIntent.metadata?.productId;
  if (paymentIntent.metadata?.productType === "ppv" && ppvId) {
    await grantPPVAccess({
      id: paymentIntent.id,
      amount: paymentIntent.amount,
      currency: paymentIntent.currency || "aud",
      metadata: {
        ...paymentIntent.metadata,
        ppvId,
      },
    });
  }
}

async function handleFailedPaymentIntent(paymentIntent) {
  await db
    .collection("payment_intents")
    .doc(paymentIntent.id)
    .set(
      {
        status: "failed",
        failedAt: FieldValue.serverTimestamp(),
        failureMessage:
          paymentIntent.last_payment_error?.message || "Payment failed",
      },
      { merge: true },
    );
}

async function markPpvCheckoutSessionComplete(session) {
  const updates = {
    sessionId: session.id,
    status: "complete",
    paymentStatus: "succeeded",
    completedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    stripePaymentIntentId: session.payment_intent || null,
    amountCents: session.amount_total || 0,
    currency: session.currency || "aud",
  };

  const directRef = db.collection("ppv_checkout_sessions").doc(session.id);
  const directSnap = await directRef.get();
  let updatedAny = false;

  if (directSnap.exists) {
    await directRef.set(
      {
        ...updates,
        userId:
          session.metadata?.dfcUserId || directSnap.data()?.userId || null,
        ppvId: session.metadata?.ppvId || directSnap.data()?.ppvId || null,
      },
      { merge: true },
    );
    updatedAny = true;
  }

  const legacyQuery = await db
    .collection("ppv_checkout_sessions")
    .where("sessionId", "==", session.id)
    .limit(10)
    .get();

  if (!legacyQuery.empty) {
    await Promise.all(
      legacyQuery.docs.map((doc) =>
        doc.ref.set(
          {
            ...updates,
            userId: session.metadata?.dfcUserId || doc.data()?.userId || null,
            ppvId: session.metadata?.ppvId || doc.data()?.ppvId || null,
          },
          { merge: true },
        ),
      ),
    );
    updatedAny = true;
  }

  if (!updatedAny) {
    await directRef.set(
      {
        ...updates,
        userId: session.metadata?.dfcUserId || null,
        ppvId: session.metadata?.ppvId || null,
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
}

function normalizeOptionalString(value) {
  if (typeof value !== "string") return null;
  const normalized = value.trim();
  return normalized || null;
}

function normalizeOptionalStatus(value) {
  return normalizeOptionalString(value)?.toLowerCase() || null;
}

function parseUnsignedLocalWebhookEvent(req) {
  if (Buffer.isBuffer(req.rawBody) && req.rawBody.length > 0) {
    return JSON.parse(req.rawBody.toString("utf8"));
  }
  if (typeof req.body === "string" && req.body.trim()) {
    return JSON.parse(req.body);
  }
  if (req.body && typeof req.body === "object") {
    return req.body;
  }
  throw new Error("Missing local webhook payload");
}

function isDisputeBlockingStatus(status) {
  const normalized = normalizeOptionalStatus(status);
  if (!normalized) return false;
  return normalized !== "won" && normalized !== "warning_closed";
}

function isFullyRefundedCharge(charge = {}) {
  const amountRefunded = charge.amount_refunded || 0;
  const amount = charge.amount || 0;
  return (
    charge.refunded === true ||
    (amountRefunded > 0 && amount > 0 && amountRefunded >= amount)
  );
}

async function loadPaymentArtifactContext(paymentIntentId) {
  const paymentIntentRef = db
    .collection("payment_intents")
    .doc(paymentIntentId);
  const [paymentIntentSnap, sessionSnap, purchaseSnap, accessSnap] =
    await Promise.all([
      paymentIntentRef.get(),
      db
        .collection("ppv_checkout_sessions")
        .where("stripePaymentIntentId", "==", paymentIntentId)
        .limit(10)
        .get(),
      db
        .collection("ppv_purchases")
        .where("stripePaymentId", "==", paymentIntentId)
        .limit(25)
        .get(),
      db
        .collection("ppv_access")
        .where("stripePaymentId", "==", paymentIntentId)
        .limit(25)
        .get(),
    ]);

  const paymentIntentData = paymentIntentSnap.exists
    ? paymentIntentSnap.data()
    : {};
  const metadata = paymentIntentData?.metadata || {};
  const firstSession = sessionSnap.empty ? {} : sessionSnap.docs[0].data();
  const firstPurchase = purchaseSnap.empty ? {} : purchaseSnap.docs[0].data();

  return {
    paymentIntentRef,
    paymentIntentExists: paymentIntentSnap.exists,
    paymentIntentData,
    sessionDocs: sessionSnap.docs,
    purchaseDocs: purchaseSnap.docs,
    accessDocs: accessSnap.docs,
    productType: normalizeOptionalString(
      metadata.productType ||
        paymentIntentData?.productType ||
        firstSession.productType ||
        firstPurchase.productType,
    ),
    ppvId: normalizeOptionalString(
      metadata.ppvId ||
        firstSession.ppvId ||
        firstPurchase.ppvId ||
        firstPurchase.ppvEventId ||
        firstPurchase.eventId ||
        paymentIntentData?.productId,
    ),
    promoterId: normalizeOptionalString(
      metadata.promoterId ||
        firstSession.promoterId ||
        firstPurchase.promoterId,
    ),
    userId: normalizeOptionalString(
      metadata.dfcUserId ||
        paymentIntentData?.userId ||
        firstSession.userId ||
        firstPurchase.userId,
    ),
  };
}

async function applyRefundStateToPpvArtifacts({ charge, paymentIntentId }) {
  const context = await loadPaymentArtifactContext(paymentIntentId);
  const fullRefund = isFullyRefundedCharge(charge);
  const now = FieldValue.serverTimestamp();
  const amountRefunded = charge.amount_refunded || 0;
  const refundStatus = fullRefund ? "refunded" : "partially_refunded";

  const writes = [];
  for (const doc of context.purchaseDocs) {
    const update = {
      refundAmountCents: amountRefunded,
      refundReason: charge.reason || null,
      stripeChargeId: charge.id || null,
      paymentStatus: refundStatus,
      lastRefundAt: now,
      updatedAt: now,
    };
    if (fullRefund) {
      Object.assign(update, {
        refunded: true,
        status: "refunded",
        isActive: false,
        accessGranted: false,
        refundedAt: now,
      });
    }
    writes.push(doc.ref.set(update, { merge: true }));
  }

  for (const doc of context.accessDocs) {
    const update = {
      refundAmountCents: amountRefunded,
      refundReason: charge.reason || null,
      stripeChargeId: charge.id || null,
      paymentStatus: refundStatus,
      lastRefundAt: now,
      updatedAt: now,
    };
    if (fullRefund) {
      Object.assign(update, {
        refunded: true,
        status: "refunded",
        isActive: false,
        accessGranted: false,
        refundedAt: now,
      });
    }
    writes.push(doc.ref.set(update, { merge: true }));
  }

  for (const doc of context.sessionDocs) {
    const update = {
      refundAmountCents: amountRefunded,
      refundReason: charge.reason || null,
      stripeChargeId: charge.id || null,
      paymentStatus: refundStatus,
      lastRefundAt: now,
      updatedAt: now,
    };
    if (fullRefund) {
      Object.assign(update, {
        refunded: true,
        status: "refunded",
        isActive: false,
        accessGranted: false,
        refundedAt: now,
      });
    }
    writes.push(doc.ref.set(update, { merge: true }));
  }

  if (context.paymentIntentExists) {
    const update = {
      refundAmountCents: amountRefunded,
      refundReason: charge.reason || null,
      stripeChargeId: charge.id || null,
      status: refundStatus,
      lastRefundAt: now,
      updatedAt: now,
    };
    if (fullRefund) {
      update.refundedAt = now;
    }
    writes.push(context.paymentIntentRef.set(update, { merge: true }));
  }

  await Promise.all(writes);
  return context;
}

async function resolveDisputePaymentIntentId(dispute) {
  const directId = normalizeOptionalString(dispute?.payment_intent);
  if (directId) return directId;

  const chargeId = normalizeOptionalString(dispute?.charge);
  if (!chargeId || !getStripe()) return null;

  try {
    const charge = await stripe.charges.retrieve(chargeId);
    return normalizeOptionalString(charge?.payment_intent);
  } catch (error) {
    console.error("Failed to resolve dispute payment intent:", error.message);
    return null;
  }
}

function isRefundedArtifact(data = {}) {
  return (
    data.refunded === true ||
    normalizeOptionalStatus(data.paymentStatus) === "refunded" ||
    normalizeOptionalStatus(data.status) === "refunded"
  );
}

function buildDisputeArtifactUpdate({
  data = {},
  dispute,
  status,
  blocking,
  now,
  deleteField,
}) {
  const update = {
    stripeDisputeId: dispute.id,
    disputeStatus: status,
    disputeReason: dispute.reason || null,
    disputeAmountCents: dispute.amount || 0,
    disputeChargeId: dispute.charge || null,
    updatedAt: now,
  };

  if (blocking) {
    Object.assign(update, {
      revoked: true,
      isActive: false,
      accessGranted: false,
      disputeOpenedAt: now,
      preDisputePaymentStatus:
        data.preDisputePaymentStatus || data.paymentStatus || "succeeded",
      paymentStatus: "revoked",
    });
    return update;
  }

  Object.assign(update, {
    disputeResolvedAt: now,
    preDisputePaymentStatus: deleteField,
  });

  if (!isRefundedArtifact(data)) {
    Object.assign(update, {
      revoked: false,
      isActive: true,
      accessGranted: true,
      paymentStatus:
        data.preDisputePaymentStatus || data.paymentStatus || "succeeded",
    });
  }

  return update;
}

function buildPaymentIntentDisputeUpdate({
  paymentIntentData = {},
  dispute,
  status,
  blocking,
  now,
  deleteField,
}) {
  const update = {
    stripeDisputeId: dispute.id,
    disputeStatus: status,
    disputeReason: dispute.reason || null,
    disputeAmountCents: dispute.amount || 0,
    disputeChargeId: dispute.charge || null,
    updatedAt: now,
  };

  if (blocking) {
    Object.assign(update, {
      preDisputeStatus:
        paymentIntentData.preDisputeStatus ||
        paymentIntentData.status ||
        "succeeded",
      status: "disputed",
      disputeOpenedAt: now,
    });
    return update;
  }

  Object.assign(update, {
    disputeResolvedAt: now,
    preDisputeStatus: deleteField,
  });

  if (!isRefundedArtifact(paymentIntentData)) {
    const restoredStatus =
      paymentIntentData.preDisputeStatus ||
      paymentIntentData.status ||
      "succeeded";
    update.status =
      restoredStatus === "disputed" ? "succeeded" : restoredStatus;
  }

  return update;
}

async function applyDisputeStateToPpvArtifacts(dispute) {
  const now = FieldValue.serverTimestamp();
  const status = normalizeOptionalStatus(dispute?.status) || "needs_response";
  const paymentIntentId = await resolveDisputePaymentIntentId(dispute);
  const context = paymentIntentId
    ? await loadPaymentArtifactContext(paymentIntentId)
    : null;
  const blocking = isDisputeBlockingStatus(status);

  await db
    .collection("disputes")
    .doc(dispute.id)
    .set(
      {
        stripeDisputeId: dispute.id,
        chargeId: dispute.charge || null,
        paymentIntentId,
        amountCents: dispute.amount || 0,
        currency:
          dispute.currency || context?.paymentIntentData?.currency || "aud",
        reason: dispute.reason || null,
        status,
        blockingAccess: blocking,
        productType: context?.productType || null,
        eventId: context?.ppvId || null,
        ppvId: context?.ppvId || null,
        promoterId: context?.promoterId || null,
        userId: context?.userId || null,
        stripeCreatedAt:
          typeof dispute.created === "number"
            ? new Date(dispute.created * 1000)
            : null,
        updatedAt: now,
        resolvedAt: blocking ? null : now,
      },
      { merge: true },
    );

  if (!context) {
    return;
  }

  const deleteField = FieldValue.delete();
  const writes = [
    ...context.purchaseDocs.map((doc) =>
      doc.ref.set(
        buildDisputeArtifactUpdate({
          data: doc.data() || {},
          dispute,
          status,
          blocking,
          now,
          deleteField,
        }),
        { merge: true },
      ),
    ),
    ...context.accessDocs.map((doc) =>
      doc.ref.set(
        buildDisputeArtifactUpdate({
          data: doc.data() || {},
          dispute,
          status,
          blocking,
          now,
          deleteField,
        }),
        { merge: true },
      ),
    ),
    ...context.sessionDocs.map((doc) =>
      doc.ref.set(
        buildDisputeArtifactUpdate({
          data: doc.data() || {},
          dispute,
          status,
          blocking,
          now,
          deleteField,
        }),
        { merge: true },
      ),
    ),
  ];

  if (context.paymentIntentExists) {
    writes.push(
      context.paymentIntentRef.set(
        buildPaymentIntentDisputeUpdate({
          paymentIntentData: context.paymentIntentData || {},
          dispute,
          status,
          blocking,
          now,
          deleteField,
        }),
        { merge: true },
      ),
    );
  }

  await Promise.all(writes);
}

async function syncAccountUpdated(account) {
  const legacyQuery = await db
    .collection("connected_accounts")
    .where("stripeAccountId", "==", account.id)
    .limit(1)
    .get();
  if (!legacyQuery.empty) {
    const legacyStatus = getLegacyConnectStatus(
      account.charges_enabled === true,
      account.payouts_enabled === true,
      account.details_submitted === true,
    );
    await legacyQuery.docs[0].ref.update({
      status: legacyStatus,
      chargesEnabled: account.charges_enabled,
      payoutsEnabled: account.payouts_enabled,
      updatedAt: FieldValue.serverTimestamp(),
    });
  }

  const v2Query = await db
    .collection(CONNECTED_ACCOUNTS_V2)
    .where("stripeAccountId", "==", account.id)
    .limit(1)
    .get();
  if (!v2Query.empty) {
    const v2Status = getV2ConnectStatus(
      account.charges_enabled === true,
      account.details_submitted === true,
    );
    await v2Query.docs[0].ref.update({
      status: v2Status,
      onboardingComplete: account.details_submitted === true,
      cardPaymentsActive: account.charges_enabled === true,
      requirementsStatus: account.details_submitted
        ? "satisfied"
        : "currently_due",
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
}

async function handleCheckoutSessionCompleted(session) {
  await markPpvCheckoutSessionComplete(session);

  const meta = session.metadata || {};

  if (meta.productType === "ppv" && meta.ppvId && meta.dfcUserId) {
    await grantPPVAccess({
      id: session.payment_intent || session.id,
      canonicalSessionId: session.id,
      amount: session.amount_total,
      currency: session.currency || "aud",
      metadata: meta,
    });
  }

  if (meta.productType === "credits" && meta.dfcUserId) {
    const { creditWalletTopup } = require("./credits");
    await creditWalletTopup({
      id: session.payment_intent || session.id,
      metadata: meta,
    });
  }

  if (session.mode === "subscription" && meta.dfcUserId) {
    const subId = session.subscription;
    await db
      .collection("subscriptions")
      .doc(meta.dfcUserId)
      .set(
        {
          userId: meta.dfcUserId,
          stripeSubscriptionId: subId || null,
          stripeCustomerId: session.customer || null,
          planId: meta.planId || "pro",
          tier: meta.planId || "pro",
          isActive: true,
          status: "active",
          amountTotal: session.amount_total || 0,
          currency: session.currency || "aud",
          startDate: FieldValue.serverTimestamp(),
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
  }
}

async function syncSubscriptionLifecycle(subscription, isDeleted = false) {
  const userId = await findUserIdByStripeCustomerId(subscription.customer);
  if (!userId) return;

  if (isDeleted) {
    await db.collection("subscriptions").doc(userId).update({
      isActive: false,
      status: "canceled",
      canceledAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return;
  }

  await db
    .collection("subscriptions")
    .doc(userId)
    .set(
      {
        userId,
        stripeSubscriptionId: subscription.id,
        stripeCustomerId: subscription.customer,
        planId: subscription.metadata?.planId || "pro",
        tier: subscription.metadata?.planId || "pro",
        isActive:
          subscription.status === "active" ||
          subscription.status === "trialing",
        status: subscription.status,
        currentPeriodEnd: new Date(subscription.current_period_end * 1000),
        cancelAtPeriodEnd: subscription.cancel_at_period_end || false,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
}

async function recordPaidInvoice(invoice) {
  if (!invoice.subscription) return;
  await db.collection("subscription_payments").add({
    stripeInvoiceId: invoice.id,
    stripeSubscriptionId: invoice.subscription,
    stripeCustomerId: invoice.customer,
    amountPaid: invoice.amount_paid,
    currency: invoice.currency,
    status: "paid",
    invoiceUrl: invoice.hosted_invoice_url || null,
    invoicePdf: invoice.invoice_pdf || null,
    receiptEmail: invoice.customer_email || null,
    paidAt: FieldValue.serverTimestamp(),
  });
}

async function markInvoicePaymentFailed(invoice) {
  const userId = await findUserIdByStripeCustomerId(invoice.customer);
  if (!userId) return;

  await db.collection("subscriptions").doc(userId).update({
    paymentFailed: true,
    paymentFailedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
}

// ── Create Stripe Customer ───────────────────────────────────────────────
const createStripeCustomer = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    if (!getStripe()) return { error: "Stripe not configured" };
    const { userId, email, name } = request.data;
    if (!userId || !email) return { error: "userId and email required" };

    const existingDoc = await db
      .collection("stripe_customers")
      .doc(userId)
      .get();
    if (existingDoc.exists && existingDoc.data().stripeCustomerId) {
      return { customerId: existingDoc.data().stripeCustomerId };
    }

    const customer = await stripe.customers.create({
      email,
      name: name || undefined,
      metadata: { dfcUserId: userId },
    });

    await db
      .collection("stripe_customers")
      .doc(userId)
      .set({
        stripeCustomerId: customer.id,
        email,
        name: name || null,
        createdAt: FieldValue.serverTimestamp(),
      });

    return { customerId: customer.id };
  },
);

// ── Create Payment Intent ─────────────────────────────────────────────────
const createPaymentIntent = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    if (!getStripe()) return { error: "Stripe not configured" };
    const { userId, amountCents, currency, productType, productId, metadata } =
      request.data;

    if (!userId || !amountCents || !currency || !productType) {
      return { error: "Missing required fields" };
    }

    const customerId = await getOrCreateStripeCustomer(userId);

    const feeRate = getPlatformFeeRate(productType);
    const applicationFee = Math.round(amountCents * feeRate);
    const intentMetadata = mergeMetadata(
      {
        dfcUserId: userId,
        productType,
        productId: productId || "",
        platformFeePct: String(feeRate),
      },
      metadata,
    );

    const intentParams = {
      amount: amountCents,
      currency: currency.toLowerCase(),
      customer: customerId,
      metadata: intentMetadata,
      automatic_payment_methods: { enabled: true },
    };

    if (
      productType !== "subscription" &&
      productType !== "donation" &&
      metadata?.connected_account_id
    ) {
      intentParams.application_fee_amount = applicationFee;
      intentParams.transfer_data = {
        destination: metadata.connected_account_id,
      };
    }

    const paymentIntent = await stripe.paymentIntents.create(intentParams);

    await db
      .collection("payment_intents")
      .doc(paymentIntent.id)
      .set({
        userId,
        stripeCustomerId: customerId,
        amountCents,
        currency: currency.toLowerCase(),
        productType,
        productId: productId || "",
        status: paymentIntent.status,
        metadata: metadata || {},
        createdAt: FieldValue.serverTimestamp(),
      });

    return {
      paymentIntentId: paymentIntent.id,
      clientSecret: paymentIntent.client_secret,
      status: paymentIntent.status,
      customerId,
    };
  },
);

// ── Create Refund ────────────────────────────────────────────────────────
const createRefund = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    if (!getStripe()) return { error: "Stripe not configured" };
    const { paymentIntentId, amountCents, reason } = request.data;
    if (!paymentIntentId) return { error: "paymentIntentId required" };

    const refundParams = { payment_intent: paymentIntentId };
    if (amountCents) refundParams.amount = amountCents;
    if (reason) {
      let normalizedReason = "requested_by_customer";
      if (reason === "duplicate") normalizedReason = "duplicate";
      if (reason === "fraudulent") normalizedReason = "fraudulent";
      refundParams.reason = normalizedReason;
    }

    const refund = await stripe.refunds.create(refundParams);

    const paymentContext = await loadPaymentArtifactContext(paymentIntentId);

    await db
      .collection("refunds")
      .doc(refund.id)
      .set(
        {
          stripeRefundId: refund.id,
          paymentIntentId,
          amountCents: refund.amount,
          reason: reason || "customer_request",
          status: refund.status,
          productType: paymentContext.productType || null,
          eventId: paymentContext.ppvId || null,
          ppvId: paymentContext.ppvId || null,
          promoterId: paymentContext.promoterId || null,
          userId: paymentContext.userId || null,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

    return { refundId: refund.id, status: refund.status };
  },
);

// ── Stripe Connect Compatibility Wrapper — Onboard Promoters ─────────────
const createConnectAccount = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    if (!getStripe()) return { error: "Stripe not configured" };
    const { userId, email, businessName, country } = request.data;
    if (!userId || !email) return { error: "userId and email required" };

    const accountDocRef = db.collection(CONNECTED_ACCOUNTS_V2).doc(userId);
    const existingDoc = await accountDocRef.get();

    let accountId = existingDoc.exists
      ? existingDoc.data().stripeAccountId
      : null;

    if (!accountId) {
      const account = await stripe.v2.core.accounts.create({
        display_name: businessName || "DFC Partner",
        contact_email: email,
        identity: { country: (country || "AU").toLowerCase() },
        dashboard: "full",
        defaults: {
          responsibilities: {
            fees_collector: "stripe",
            losses_collector: "stripe",
          },
        },
        configuration: {
          customer: {},
          merchant: {
            capabilities: {
              card_payments: { requested: true },
            },
          },
        },
      });

      accountId = account.id;

      await accountDocRef.set(
        {
          stripeAccountId: accountId,
          email,
          displayName: businessName || null,
          country: (country || "AU").toUpperCase(),
          status: "onboarding_required",
          onboardingComplete: false,
          cardPaymentsActive: false,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }

    const accountLink = await stripe.v2.core.accountLinks.create({
      account: accountId,
      use_case: {
        type: "account_onboarding",
        account_onboarding: {
          configurations: ["merchant", "customer"],
          refresh_url: `${BASE_URL}/connect/refresh?userId=${userId}`,
          return_url: `${BASE_URL}/connect/return?accountId=${accountId}&userId=${userId}`,
        },
      },
    });

    await accountDocRef.set(
      {
        status: "onboarding_in_progress",
        lastLinkCreatedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return {
      accountId,
      onboardingUrl: accountLink.url,
      url: accountLink.url,
      status: "onboarding_in_progress",
    };
  },
);

// ── Promo Codes ──────────────────────────────────────────────────────────
const createPromoCoupon = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    if (!getStripe()) return { error: "Stripe not configured" };
    const {
      code,
      percentOff,
      amountOffCents,
      currency,
      maxRedemptions,
      expiresAt,
      productTypes,
    } = request.data;

    if (!code) return { error: "Promo code required" };
    if (!percentOff && !amountOffCents)
      return { error: "percentOff or amountOffCents required" };

    const couponParams = {
      id: code.toUpperCase().replaceAll(/[^A-Z0-9]/g, ""),
      name: code.toUpperCase(),
      metadata: {
        dfcCode: code.toUpperCase(),
        productTypes: productTypes ? productTypes.join(",") : "all",
      },
    };

    if (percentOff)
      couponParams.percent_off = Math.min(100, Math.max(1, percentOff));
    else {
      couponParams.amount_off = amountOffCents;
      couponParams.currency = (currency || "usd").toLowerCase();
    }
    if (maxRedemptions) couponParams.max_redemptions = maxRedemptions;
    if (expiresAt)
      couponParams.redeem_by = Math.floor(new Date(expiresAt).getTime() / 1000);

    try {
      const coupon = await stripe.coupons.create(couponParams);
      await db
        .collection("promo_codes")
        .doc(code.toUpperCase())
        .set({
          stripeCouponId: coupon.id,
          code: code.toUpperCase(),
          percentOff: percentOff || null,
          amountOffCents: amountOffCents || null,
          currency: currency || null,
          maxRedemptions: maxRedemptions || null,
          timesRedeemed: 0,
          expiresAt: expiresAt ? new Date(expiresAt) : null,
          productTypes: productTypes || ["all"],
          active: true,
          createdAt: FieldValue.serverTimestamp(),
        });
      return {
        success: true,
        couponId: coupon.id,
        code: code.toUpperCase(),
        percentOff: coupon.percent_off,
        amountOff: coupon.amount_off,
      };
    } catch (err) {
      return { error: err.message };
    }
  },
);

const validatePromoCode = onCall({ region: REGION }, async (request) => {
  const { code, productType, amountCents } = request.data;
  if (!code) return { valid: false, error: "Promo code required" };

  try {
    const promoDoc = await db
      .collection("promo_codes")
      .doc(code.toUpperCase())
      .get();
    if (!promoDoc.exists) return { valid: false, error: "Invalid promo code" };

    const promo = promoDoc.data();
    if (!promo.active) return { valid: false, error: "Code no longer active" };
    if (promo.expiresAt && new Date(promo.expiresAt.toDate()) < new Date())
      return { valid: false, error: "Code expired" };
    if (promo.maxRedemptions && promo.timesRedeemed >= promo.maxRedemptions)
      return { valid: false, error: "Redemption limit reached" };
    if (
      productType &&
      promo.productTypes &&
      !promo.productTypes.includes("all") &&
      !promo.productTypes.includes(productType)
    ) {
      return { valid: false, error: `Code not valid for ${productType}` };
    }

    let discountCents = 0,
      discountDescription = "";
    if (promo.percentOff) {
      discountCents = amountCents
        ? Math.round(amountCents * (promo.percentOff / 100))
        : 0;
      discountDescription = `${promo.percentOff}% off`;
    } else if (promo.amountOffCents) {
      discountCents = Math.min(
        promo.amountOffCents,
        amountCents || promo.amountOffCents,
      );
      discountDescription = `$${(promo.amountOffCents / 100).toFixed(2)} off`;
    }

    return {
      valid: true,
      code: promo.code,
      percentOff: promo.percentOff,
      amountOffCents: promo.amountOffCents,
      discountCents,
      discountDescription,
      finalAmountCents: amountCents
        ? Math.max(0, amountCents - discountCents)
        : null,
    };
  } catch (err) {
    return { valid: false, error: err.message };
  }
});

const applyPromoCode = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    if (!getStripe()) return { error: "Stripe not configured" };
    const {
      code,
      userId,
      amountCents,
      currency,
      productType,
      productId,
      metadata,
    } = request.data;

    if (!code || !userId || !amountCents || !currency || !productType)
      return { error: "Missing required fields" };

    // Inline validation (can't call .run() on v2 onCall functions)
    const promoResult = await getPromoDocOrError(code, productType);
    if (promoResult.error) return { error: promoResult.error };

    const promo = promoResult.promo;
    const discountCents = getDiscountCents(promo, amountCents);
    const finalAmount = Math.max(0, amountCents - discountCents);

    const customerId = await getOrCreateStripeCustomer(userId);

    const feeRate = getPlatformFeeRate(productType);
    const applicationFee = Math.round(finalAmount * feeRate);
    const intentMetadata = mergeMetadata(
      {
        dfcUserId: userId,
        productType,
        productId: productId || "",
        promoCode: code.toUpperCase(),
        originalAmountCents: amountCents,
        discountCents,
        platformFeePct: String(feeRate),
      },
      metadata,
    );

    const intentParams = {
      amount: finalAmount,
      currency: currency.toLowerCase(),
      customer: customerId,
      metadata: intentMetadata,
      automatic_payment_methods: { enabled: true },
    };

    if (
      productType !== "subscription" &&
      productType !== "donation" &&
      metadata?.connected_account_id
    ) {
      intentParams.application_fee_amount = applicationFee;
      intentParams.transfer_data = {
        destination: metadata.connected_account_id,
      };
    }

    const paymentIntent = await stripe.paymentIntents.create(intentParams);

    await db
      .collection("promo_codes")
      .doc(code.toUpperCase())
      .update({ timesRedeemed: FieldValue.increment(1) });
    await db.collection("promo_redemptions").add({
      userId,
      code: code.toUpperCase(),
      paymentIntentId: paymentIntent.id,
      originalAmountCents: amountCents,
      discountCents,
      finalAmountCents: finalAmount,
      productType,
      productId: productId || "",
      redeemedAt: FieldValue.serverTimestamp(),
    });
    await db
      .collection("payment_intents")
      .doc(paymentIntent.id)
      .set({
        userId,
        stripeCustomerId: customerId,
        amountCents: finalAmount,
        originalAmountCents: amountCents,
        promoCode: code.toUpperCase(),
        discountCents,
        currency: currency.toLowerCase(),
        productType,
        productId: productId || "",
        status: paymentIntent.status,
        metadata: metadata || {},
        createdAt: FieldValue.serverTimestamp(),
      });

    return {
      paymentIntentId: paymentIntent.id,
      clientSecret: paymentIntent.client_secret,
      status: paymentIntent.status,
      customerId,
      originalAmountCents: amountCents,
      discountCents,
      finalAmountCents: finalAmount,
      promoApplied: code.toUpperCase(),
    };
  },
);

const getConnectAccountStatus = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    if (!getStripe()) return { error: "Stripe not configured" };
    const { userId } = request.data;
    if (!userId) return { error: "userId required" };

    const doc = await db.collection(CONNECTED_ACCOUNTS_V2).doc(userId).get();
    if (!doc.exists) return { status: "not_connected", hasAccount: false };

    const { stripeAccountId } = doc.data();
    const account = await stripe.v2.core.accounts.retrieve(stripeAccountId, {
      include: ["configuration.merchant", "requirements"],
    });

    const readyToProcessPayments =
      account?.configuration?.merchant?.capabilities?.card_payments?.status ===
      "active";
    const requirementsStatus =
      account?.requirements?.summary?.minimum_deadline?.status;
    const onboardingComplete =
      requirementsStatus !== "currently_due" &&
      requirementsStatus !== "past_due";
    const status = getV2ConnectStatus(
      readyToProcessPayments,
      onboardingComplete,
    );

    await db
      .collection(CONNECTED_ACCOUNTS_V2)
      .doc(userId)
      .set(
        {
          status,
          onboardingComplete,
          cardPaymentsActive: readyToProcessPayments,
          requirementsStatus: requirementsStatus || null,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

    return {
      status,
      onboardingStatus: getV2OnboardingStatus(
        readyToProcessPayments,
        onboardingComplete,
      ),
      chargesEnabled: readyToProcessPayments,
      payoutsEnabled: readyToProcessPayments,
      detailsSubmitted: onboardingComplete,
      accountId: stripeAccountId,
      hasAccount: true,
      readyToProcessPayments,
      requirementsStatus: requirementsStatus || null,
      country: doc.data().country || null,
      defaultCurrency: null,
    };
  },
);

const createConnectLoginLink = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    if (!getStripe()) return { error: "Stripe not configured" };
    const { userId } = request.data;
    if (!userId) return { error: "userId required" };

    const legacyDoc = await db
      .collection("connected_accounts")
      .doc(userId)
      .get();
    if (legacyDoc.exists && legacyDoc.data().stripeAccountId) {
      const loginLink = await stripe.accounts.createLoginLink(
        legacyDoc.data().stripeAccountId,
      );
      return { url: loginLink.url, mode: "legacy_express" };
    }

    const v2Doc = await db.collection(CONNECTED_ACCOUNTS_V2).doc(userId).get();
    if (!v2Doc.exists) return { error: "No connected account found" };

    return {
      error:
        "V2 connected accounts use Stripe-hosted full dashboard access and do not expose Express login links. Use Stripe sign-in or createBillingPortalSession where appropriate.",
      code: "V2_LOGIN_LINK_UNAVAILABLE",
    };
  },
);

// ── Legacy Webhook Handler ───────────────────────────────────────────────
const handleStripeWebhook = onRequest(
  withStripeSecret({ region: REGION }),
  async (req, res) => {
    if (!getStripe()) return res.status(500).send("Stripe not configured");
    if (req.method !== "POST")
      return res.status(405).send("Method not allowed");

    const sig = req.headers["stripe-signature"];
    const allowUnsignedLocalEvent =
      process.env.FUNCTIONS_EMULATOR === "true" &&
      req.headers["x-dfc-local-webhook-test"] === "1";
    if (!STRIPE_WEBHOOK_SECRET)
      return res.status(500).send("Webhook secret not configured");

    let event;
    try {
      event = stripe.webhooks.constructEvent(
        req.rawBody || req.body,
        sig,
        STRIPE_WEBHOOK_SECRET,
      );
    } catch (err) {
      if (!allowUnsignedLocalEvent) {
        return res.status(400).send(`Webhook Error: ${err.message}`);
      }

      try {
        event = parseUnsignedLocalWebhookEvent(req);
        console.warn(
          "handleStripeWebhook: using emulator-only unsigned local webhook fallback",
        );
      } catch (parseError) {
        return res
          .status(400)
          .send(
            `Webhook Error: ${err.message}; Local parse error: ${parseError.message}`,
          );
      }
    }

    try {
      switch (event.type) {
        case "payment_intent.succeeded": {
          await handleSucceededPaymentIntent(event.data.object);
          break;
        }
        case "payment_intent.payment_failed": {
          await handleFailedPaymentIntent(event.data.object);
          break;
        }
        case "charge.refunded": {
          const charge = event.data.object;
          if (charge.payment_intent) {
            await applyRefundStateToPpvArtifacts({
              charge,
              paymentIntentId: charge.payment_intent,
            });
          }
          break;
        }
        case "charge.dispute.created":
        case "charge.dispute.updated":
        case "charge.dispute.closed": {
          await applyDisputeStateToPpvArtifacts(event.data.object);
          break;
        }
        case "account.updated": {
          await syncAccountUpdated(event.data.object);
          break;
        }
        case "checkout.session.completed": {
          await handleCheckoutSessionCompleted(event.data.object);
          break;
        }
        case "customer.subscription.created":
        case "customer.subscription.updated": {
          await syncSubscriptionLifecycle(event.data.object);
          break;
        }
        case "customer.subscription.deleted": {
          await syncSubscriptionLifecycle(event.data.object, true);
          break;
        }
        case "invoice.paid": {
          await recordPaidInvoice(event.data.object);
          break;
        }
        case "invoice.payment_failed": {
          await markInvoicePaymentFailed(event.data.object);
          break;
        }
      }
      return res.status(200).send("OK");
    } catch (err) {
      console.error("Webhook processing error:", err);
      return res.status(500).send(`Error: ${err.message}`);
    }
  },
);

// ── Sync Subscription Status (post-checkout polling) ─────────────────────
const syncSubscriptionStatus = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    const { userId } = request.data;
    if (!userId) return { error: "userId required" };

    try {
      const snapshot = await db
        .collection("subscriptions")
        .where("userId", "==", userId)
        .where("isActive", "==", true)
        .orderBy("startDate", "desc")
        .limit(1)
        .get();

      if (snapshot.empty) return { active: false, planId: "free" };
      const sub = snapshot.docs[0].data();
      return {
        active: true,
        planId: sub.tier || sub.planId || "free",
        subscriptionId: snapshot.docs[0].id,
      };
    } catch (err) {
      return { active: false, planId: "free", error: err.message };
    }
  },
);

// ── Create Stripe Checkout Session ───────────────────────────────────────
const createStripeCheckout = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    if (!getStripe()) return { error: "Stripe not configured" };
    const { userId, planId, couponCode, successUrl, cancelUrl } = request.data;
    if (!userId || !planId) return { error: "userId and planId required" };

    const userDoc = await db.collection("users").doc(userId).get();
    const email = userDoc.exists
      ? userDoc.data().email || userId + "@dfc.app"
      : userId + "@dfc.app";

    let customerId;
    const custDoc = await db.collection("stripe_customers").doc(userId).get();
    if (custDoc.exists && custDoc.data().stripeCustomerId) {
      customerId = custDoc.data().stripeCustomerId;
    } else {
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

    // Price IDs from Stripe Dashboard — acct_1T6WevBSoM6ez8FY
    // Fighter Pro $2.99/mo | Coach $4.99/mo | Promoter $9.99/mo | Supporter $1.99/mo
    const priceMap = {
      pro: "price_1T7r4EPcqZu7NL6NlwqBwl37",
      fighter: "price_1T7r4EPcqZu7NL6NlwqBwl37",
      fighterpro: "price_1T7r4EPcqZu7NL6NlwqBwl37",
      coachmentor: "price_1T7r4XPcqZu7NL6NRQJevavp",
      elite: "price_1T7r4dPcqZu7NL6NuGQNVc0V",
      promotergym: "price_1T7r4dPcqZu7NL6NuGQNVc0V",
      supporter: "price_1T7r4EPcqZu7NL6NlwqBwl37",
    };
    const priceId = priceMap[planId.toLowerCase()] || priceMap["pro"];

    const sessionParams = {
      customer: customerId,
      mode: "subscription",
      billing_address_collection: "required",
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: successUrl || "https://datafightcentral.com/",
      cancel_url: cancelUrl || "https://datafightcentral.com/",
      metadata: { dfcUserId: userId, planId },
    };
    if (couponCode) {
      sessionParams.discounts = [{ coupon: couponCode.toUpperCase() }];
    }

    const session = await stripe.checkout.sessions.create(sessionParams);
    return { url: session.url, sessionId: session.id };
  },
);

// ── Cancel Subscription ──────────────────────────────────────────────────
const cancelSubscription = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    if (!getStripe()) return { error: "Stripe not configured" };
    const { userId } = request.data;
    if (!userId) return { error: "userId required" };

    const snapshot = await db
      .collection("subscriptions")
      .where("userId", "==", userId)
      .where("isActive", "==", true)
      .limit(1)
      .get();

    if (snapshot.empty) return { error: "No active subscription found" };
    const sub = snapshot.docs[0].data();

    if (sub.stripeSubscriptionId) {
      await stripe.subscriptions.update(sub.stripeSubscriptionId, {
        cancel_at_period_end: true,
      });
    }

    await snapshot.docs[0].ref.update({
      canceledAt: FieldValue.serverTimestamp(),
    });
    return {
      success: true,
      message: "Subscription will cancel at end of billing period",
    };
  },
);

// ── Restore Purchases ────────────────────────────────────────────────────
const restorePurchases = onCall({ region: REGION }, async (request) => {
  const { userId } = request.data;
  if (!userId) return { error: "userId required" };

  const snapshot = await db
    .collection("subscriptions")
    .where("userId", "==", userId)
    .where("isActive", "==", true)
    .orderBy("startDate", "desc")
    .limit(1)
    .get();

  if (snapshot.empty) return { planId: null };
  const sub = snapshot.docs[0].data();
  return {
    planId: sub.tier || sub.planId || "free",
    subscriptionId: snapshot.docs[0].id,
  };
});

module.exports = {
  createStripeCustomer,
  createPaymentIntent,
  createRefund,
  createConnectAccount,
  createPromoCoupon,
  validatePromoCode,
  applyPromoCode,
  getConnectAccountStatus,
  createConnectLoginLink,
  handleStripeWebhook,
  syncSubscriptionStatus,
  createStripeCheckout,
  cancelSubscription,
  restorePurchases,
};
