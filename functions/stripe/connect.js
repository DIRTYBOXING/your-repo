// ═══════════════════════════════════════════════════════════════════════════
// STRIPE CONNECT V2 — Connected Accounts, Products, Checkout, Subscriptions
// ═══════════════════════════════════════════════════════════════════════════

const { onCall, onRequest } = require("firebase-functions/v2/https");
const {
  admin,
  db,
  FieldValue,
  REGION,
  stripe,
  getStripe,
  STRIPE_WEBHOOK_SECRET,
  withStripeSecret,
} = require("../config");
const { getDfcFeePercent } = require("./ppv");

const BASE_URL = process.env.BASE_URL || "https://datafightcentral.com";
const STRIPE_WEBHOOK_SECRET_CONNECT =
  process.env.STRIPE_WEBHOOK_SECRET_CONNECT || "";
const STRIPE_WEBHOOK_SECRET_SUBSCRIPTIONS =
  process.env.STRIPE_WEBHOOK_SECRET_SUBSCRIPTIONS || "";

function getPlatformSubscriptionPriceId() {
  return (process.env.PLATFORM_SUBSCRIPTION_PRICE_ID || "").trim();
}

function deriveConnectedAccountStatus(paymentsActive, onboardingComplete) {
  if (!onboardingComplete) return "onboarding_required";
  return paymentsActive ? "active" : "pending_verification";
}

async function findConnectedAccountDocByStripeId(accountId) {
  if (!accountId) return null;

  const accountQuery = await db
    .collection("connected_accounts_v2")
    .where("stripeAccountId", "==", accountId)
    .limit(1)
    .get();

  return accountQuery.empty ? null : accountQuery.docs[0];
}

async function syncConnectedAccountStatus(accountId) {
  if (!accountId) return;

  const userDoc = await findConnectedAccountDocByStripeId(accountId);
  if (!userDoc) return;

  const account = await stripe.v2.core.accounts.retrieve(accountId, {
    include: ["configuration.merchant", "requirements"],
  });

  const cardPaymentsActive =
    account?.configuration?.merchant?.capabilities?.card_payments?.status ===
    "active";
  const requirementsStatus =
    account?.requirements?.summary?.minimum_deadline?.status;
  const onboardingComplete =
    requirementsStatus !== "currently_due" && requirementsStatus !== "past_due";

  await userDoc.ref.update({
    cardPaymentsActive,
    requirementsStatus: requirementsStatus || null,
    onboardingComplete,
    status: deriveConnectedAccountStatus(
      cardPaymentsActive,
      onboardingComplete,
    ),
    updatedAt: FieldValue.serverTimestamp(),
  });
}

function buildSubscriptionUpdate(subscription, isDeleted) {
  const update = {
    subscriptionId: subscription.id,
    subscriptionStatus: isDeleted ? "canceled" : subscription.status,
    subscriptionPriceId: subscription.items?.data?.[0]?.price?.id,
    subscriptionCurrentPeriodEnd: new Date(
      subscription.current_period_end * 1000,
    ),
    subscriptionCancelAtPeriodEnd: subscription.cancel_at_period_end || false,
    updatedAt: FieldValue.serverTimestamp(),
  };

  if (isDeleted) {
    update.subscriptionEndedAt = FieldValue.serverTimestamp();
  }

  return update;
}

async function syncSubscriptionLifecycleForAccount(
  accountId,
  subscription,
  isDeleted,
) {
  const userDoc = await findConnectedAccountDocByStripeId(accountId);
  if (!userDoc) return;
  await userDoc.ref.update(buildSubscriptionUpdate(subscription, isDeleted));
}

async function recordSubscriptionInvoicePaid(accountId, invoice) {
  if (!accountId) return;

  await db.collection("subscription_payments").add({
    stripeAccountId: accountId,
    invoiceId: invoice.id,
    amountPaid: invoice.amount_paid,
    currency: invoice.currency,
    status: "paid",
    paidAt: FieldValue.serverTimestamp(),
  });
}

async function markSubscriptionPaymentFailedForAccount(accountId) {
  const userDoc = await findConnectedAccountDocByStripeId(accountId);
  if (!userDoc) return;

  await userDoc.ref.update({
    subscriptionPaymentFailed: true,
    subscriptionPaymentFailedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
}

async function handleStandardConnectWebhookEvent(payload, signature, secret) {
  try {
    const standardEvent = stripe.webhooks.constructEvent(
      payload,
      signature,
      secret,
    );

    if (standardEvent.type === "account.updated") {
      await syncConnectedAccountStatus(standardEvent.data?.object?.id);
    }

    return true;
  } catch {
    return false;
  }
}

async function handleThinConnectWebhookEvent(payload, signature, secret) {
  const thinEvent = stripe.parseThinEvent(payload, signature, secret);

  if (thinEvent.type === "v2.core.event_destination.ping") {
    return;
  }

  const event = await stripe.v2.core.events.retrieve(thinEvent.id);

  switch (event.type) {
    case "v2.core.account[requirements].updated":
    case "v2.core.account[configuration.merchant].capability_status_updated":
    case "v2.core.account[configuration.customer].capability_status_updated": {
      const accountId = event.data?.object?.id || event.related_object?.id;
      await syncConnectedAccountStatus(accountId);
      break;
    }
  }
}

async function handleLegacyConnectWebhookEvent(payload, signature) {
  const event = stripe.webhooks.constructEvent(
    payload,
    signature,
    STRIPE_WEBHOOK_SECRET,
  );

  if (event.type === "account.updated") {
    await syncConnectedAccountStatus(event.data?.object?.id);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE CONNECTED ACCOUNT (V2 API)
// ─────────────────────────────────────────────────────────────────────────────
const createConnectedAccountV2 = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    if (!getStripe()) {
      return { error: "Stripe not configured", code: "STRIPE_NOT_CONFIGURED" };
    }

    const { userId, email, displayName, country } = request.data;

    if (!userId)
      return { error: "userId is required", code: "MISSING_USER_ID" };
    if (!email) return { error: "email is required", code: "MISSING_EMAIL" };

    try {
      const existingDoc = await db
        .collection("connected_accounts_v2")
        .doc(userId)
        .get();
      if (existingDoc.exists && existingDoc.data().stripeAccountId) {
        return {
          success: true,
          accountId: existingDoc.data().stripeAccountId,
          status: existingDoc.data().status,
          alreadyExists: true,
        };
      }

      const account = await stripe.v2.core.accounts.create({
        display_name: displayName || "DFC Partner",
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

      await db
        .collection("connected_accounts_v2")
        .doc(userId)
        .set({
          stripeAccountId: account.id,
          email,
          displayName: displayName || null,
          country: (country || "AU").toUpperCase(),
          status: "onboarding_required",
          onboardingComplete: false,
          cardPaymentsActive: false,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });

      await db.collection("stripe_connect_logs").add({
        action: "account_created",
        userId,
        stripeAccountId: account.id,
        timestamp: FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        accountId: account.id,
        status: "onboarding_required",
        alreadyExists: false,
      };
    } catch (err) {
      console.error("Error creating V2 connected account:", err);
      return {
        error: err.message,
        code: err.code || "ACCOUNT_CREATION_FAILED",
      };
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// CREATE ACCOUNT LINK FOR ONBOARDING
// ─────────────────────────────────────────────────────────────────────────────
const createAccountLink = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    if (!getStripe()) return { error: "Stripe not configured" };

    const { userId } = request.data;
    if (!userId) return { error: "userId is required" };

    try {
      const accountDoc = await db
        .collection("connected_accounts_v2")
        .doc(userId)
        .get();
      if (!accountDoc.exists) {
        return { error: "No connected account found for this user" };
      }

      const accountId = accountDoc.data().stripeAccountId;

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

      await db.collection("connected_accounts_v2").doc(userId).update({
        status: "onboarding_in_progress",
        lastLinkCreatedAt: FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        onboardingUrl: accountLink.url,
        accountId: accountId,
        status: "onboarding_in_progress",
      };
    } catch (err) {
      console.error("Error creating account link:", err);
      return { error: err.message };
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// GET CONNECTED ACCOUNT STATUS
// ─────────────────────────────────────────────────────────────────────────────
const getConnectedAccountStatusV2 = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    if (!getStripe()) return { error: "Stripe not configured" };

    const { userId } = request.data;
    if (!userId) return { error: "userId is required" };

    try {
      const accountDoc = await db
        .collection("connected_accounts_v2")
        .doc(userId)
        .get();
      if (!accountDoc.exists) {
        return { exists: false, error: "No connected account found" };
      }

      const accountId = accountDoc.data().stripeAccountId;

      const account = await stripe.v2.core.accounts.retrieve(accountId, {
        include: ["configuration.merchant", "requirements"],
      });

      const readyToProcessPayments =
        account?.configuration?.merchant?.capabilities?.card_payments
          ?.status === "active";
      const requirementsStatus =
        account?.requirements?.summary?.minimum_deadline?.status;
      const onboardingComplete =
        requirementsStatus !== "currently_due" &&
        requirementsStatus !== "past_due";

      const status = deriveConnectedAccountStatus(
        readyToProcessPayments,
        onboardingComplete,
      );

      await db
        .collection("connected_accounts_v2")
        .doc(userId)
        .update({
          status,
          onboardingComplete: onboardingComplete,
          cardPaymentsActive: readyToProcessPayments,
          requirementsStatus: requirementsStatus || null,
          updatedAt: FieldValue.serverTimestamp(),
        });

      return {
        exists: true,
        accountId: accountId,
        status,
        onboardingComplete: onboardingComplete,
        readyToProcessPayments: readyToProcessPayments,
        requirementsStatus: requirementsStatus || "none",
        displayName: account.display_name,
        email: account.contact_email,
        country: accountDoc.data().country || null,
        defaultCurrency: null,
      };
    } catch (err) {
      console.error("Error getting account status:", err);
      return { error: err.message };
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// CREATE PRODUCT ON CONNECTED ACCOUNT
// ─────────────────────────────────────────────────────────────────────────────
const createConnectedProduct = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    if (!getStripe()) return { error: "Stripe not configured" };

    const {
      userId,
      name,
      description,
      priceInCents,
      currency,
      imageUrl,
      metadata,
    } = request.data;

    if (!userId) return { error: "userId is required" };
    if (!name) return { error: "name is required" };
    if (!priceInCents || priceInCents < 50)
      return { error: "priceInCents must be at least 50" };

    try {
      const accountDoc = await db
        .collection("connected_accounts_v2")
        .doc(userId)
        .get();
      if (!accountDoc.exists) return { error: "No connected account found" };

      const accountId = accountDoc.data().stripeAccountId;
      if (!accountDoc.data().cardPaymentsActive) {
        return { error: "Account not ready for payments" };
      }

      const productMetadata = { dfcUserId: userId, dfcAccountId: accountId };
      if (metadata) Object.assign(productMetadata, metadata);

      const product = await stripe.products.create(
        {
          name: name,
          description: description || undefined,
          default_price_data: {
            unit_amount: priceInCents,
            currency: (currency || "aud").toLowerCase(),
          },
          images: imageUrl ? [imageUrl] : undefined,
          metadata: productMetadata,
        },
        { stripeAccount: accountId },
      );

      await db.collection("connected_products").add({
        userId,
        stripeAccountId: accountId,
        stripeProductId: product.id,
        stripePriceId: product.default_price,
        name,
        description: description || null,
        priceInCents,
        currency: (currency || "aud").toLowerCase(),
        imageUrl: imageUrl || null,
        active: true,
        metadata: metadata || {},
        createdAt: FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        productId: product.id,
        priceId: product.default_price,
        name,
        priceInCents,
      };
    } catch (err) {
      console.error("Error creating connected product:", err);
      return { error: err.message };
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// LIST PRODUCTS FROM CONNECTED ACCOUNT
// ─────────────────────────────────────────────────────────────────────────────
const listConnectedProducts = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    if (!getStripe()) return { error: "Stripe not configured" };

    const { userId, accountId: directAccountId } = request.data;
    if (!userId && !directAccountId)
      return { error: "userId or accountId required" };

    try {
      let accountId = directAccountId;
      if (userId && !accountId) {
        const accountDoc = await db
          .collection("connected_accounts_v2")
          .doc(userId)
          .get();
        if (!accountDoc.exists) return { error: "No connected account found" };
        accountId = accountDoc.data().stripeAccountId;
      }

      const products = await stripe.products.list(
        {
          limit: 20,
          active: true,
          expand: ["data.default_price"],
        },
        { stripeAccount: accountId },
      );

      const formattedProducts = products.data.map((p) => ({
        id: p.id,
        name: p.name,
        description: p.description,
        images: p.images,
        priceId: p.default_price?.id,
        priceInCents: p.default_price?.unit_amount,
        currency: p.default_price?.currency,
        formattedPrice: p.default_price
          ? `$${(p.default_price.unit_amount / 100).toFixed(2)} ${p.default_price.currency.toUpperCase()}`
          : null,
        metadata: p.metadata,
      }));

      return {
        success: true,
        accountId,
        products: formattedProducts,
        count: formattedProducts.length,
      };
    } catch (err) {
      console.error("Error listing products:", err);
      return { error: err.message };
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// CREATE CHECKOUT SESSION
// ─────────────────────────────────────────────────────────────────────────────
const createConnectedCheckout = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    if (!getStripe()) return { error: "Stripe not configured" };

    const { userId, productId, priceInCents, currency, quantity, customerId } =
      request.data;
    if (!userId) return { error: "userId required" };
    if (!priceInCents) return { error: "priceInCents required" };

    try {
      const accountDoc = await db
        .collection("connected_accounts_v2")
        .doc(userId)
        .get();
      if (!accountDoc.exists) return { error: "Connected account not found" };

      const accountId = accountDoc.data().stripeAccountId;

      // Tiered commission: look up cumulative buys for this promoter
      const statsDoc = await db.collection("promoter_stats").doc(userId).get();
      const cumulativeBuys = statsDoc.exists
        ? statsDoc.data().totalPPVBuys || 0
        : 0;
      const APPLICATION_FEE_PERCENT = getDfcFeePercent(cumulativeBuys);
      const applicationFeeAmount = Math.round(
        priceInCents * APPLICATION_FEE_PERCENT,
      );

      const session = await stripe.checkout.sessions.create(
        {
          line_items: [
            {
              price_data: {
                currency: (currency || "aud").toLowerCase(),
                unit_amount: priceInCents,
                product_data: {
                  name: productId ? `Product ${productId}` : "DFC Purchase",
                },
              },
              quantity: quantity || 1,
            },
          ],
          billing_address_collection: "required",
          payment_intent_data: {
            application_fee_amount: applicationFeeAmount,
            metadata: {
              dfcUserId: userId,
              dfcProductId: productId || "",
              platformFeePercent: String(APPLICATION_FEE_PERCENT * 100),
            },
          },
          mode: "payment",
          success_url: `${BASE_URL}/checkout/success?session_id={CHECKOUT_SESSION_ID}`,
          cancel_url: `${BASE_URL}/checkout/cancel`,
          customer: customerId || undefined,
        },
        { stripeAccount: accountId },
      );

      await db.collection("checkout_sessions").add({
        sessionId: session.id,
        connectedAccountId: accountId,
        ownerUserId: userId,
        priceInCents,
        applicationFee: applicationFeeAmount,
        status: "created",
        createdAt: FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        sessionId: session.id,
        checkoutUrl: session.url,
        applicationFee: applicationFeeAmount,
      };
    } catch (err) {
      console.error("Error creating checkout:", err);
      return { error: err.message };
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// CREATE SUBSCRIPTION FOR CONNECTED ACCOUNT
// ─────────────────────────────────────────────────────────────────────────────
const createConnectedSubscription = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    if (!getStripe()) return { error: "Stripe not configured" };

    const { userId } = request.data;
    if (!userId) return { error: "userId is required" };

    const platformSubscriptionPriceId = getPlatformSubscriptionPriceId();
    if (
      !platformSubscriptionPriceId ||
      platformSubscriptionPriceId === "price_PLACEHOLDER_SET_IN_ENV"
    ) {
      return {
        error: "Platform subscription price not configured",
        code: "PRICE_NOT_CONFIGURED",
      };
    }

    try {
      const accountDoc = await db
        .collection("connected_accounts_v2")
        .doc(userId)
        .get();
      if (!accountDoc.exists) return { error: "Connected account not found" };

      const accountId = accountDoc.data().stripeAccountId;

      const session = await stripe.checkout.sessions.create({
        customer_account: accountId,
        mode: "subscription",
        billing_address_collection: "required",
        line_items: [{ price: platformSubscriptionPriceId, quantity: 1 }],
        success_url: `${BASE_URL}/subscription/success?session_id={CHECKOUT_SESSION_ID}&userId=${userId}`,
        cancel_url: `${BASE_URL}/subscription/cancel?userId=${userId}`,
      });

      return { success: true, sessionId: session.id, checkoutUrl: session.url };
    } catch (err) {
      console.error("Error creating subscription:", err);
      return { error: err.message };
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// CREATE BILLING PORTAL SESSION
// ─────────────────────────────────────────────────────────────────────────────
const createBillingPortalSession = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    if (!getStripe()) return { error: "Stripe not configured" };

    const { userId } = request.data;
    if (!userId) return { error: "userId is required" };

    try {
      const accountDoc = await db
        .collection("connected_accounts_v2")
        .doc(userId)
        .get();
      if (!accountDoc.exists) return { error: "Connected account not found" };

      const accountId = accountDoc.data().stripeAccountId;

      const session = await stripe.billingPortal.sessions.create({
        customer_account: accountId,
        return_url: `${BASE_URL}/dashboard?userId=${userId}`,
      });

      return { success: true, portalUrl: session.url };
    } catch (err) {
      console.error("Error creating billing portal:", err);
      return { error: err.message };
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// GET SUBSCRIPTION STATUS
// ─────────────────────────────────────────────────────────────────────────────
const getSubscriptionStatus = onCall({ region: REGION }, async (request) => {
  const { userId } = request.data;
  if (!userId) return { error: "userId is required" };

  try {
    const accountDoc = await db
      .collection("connected_accounts_v2")
      .doc(userId)
      .get();
    if (!accountDoc.exists) {
      return { hasAccount: false, hasSubscription: false };
    }

    const data = accountDoc.data();
    return {
      hasAccount: true,
      hasSubscription: !!data.subscriptionId,
      subscriptionId: data.subscriptionId || null,
      subscriptionStatus: data.subscriptionStatus || null,
      subscriptionPriceId: data.subscriptionPriceId || null,
      currentPeriodEnd:
        data.subscriptionCurrentPeriodEnd?.toDate()?.toISOString() || null,
      cancelAtPeriodEnd: data.subscriptionCancelAtPeriodEnd || false,
      paymentFailed: data.subscriptionPaymentFailed || false,
      isActive:
        data.subscriptionStatus === "active" ||
        data.subscriptionStatus === "trialing",
    };
  } catch (err) {
    console.error("Error getting subscription status:", err);
    return { error: err.message };
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// WEBHOOK: V2 ACCOUNT EVENTS
// ─────────────────────────────────────────────────────────────────────────────
const stripeConnectWebhook = onRequest(
  withStripeSecret({ region: REGION, invoker: "public" }),
  async (req, res) => {
    if (!getStripe()) return res.status(500).send("Stripe not configured");
    if (req.method !== "POST")
      return res.status(405).send("Method not allowed");

    const payload = req.rawBody || req.body;
    const sig = req.headers["stripe-signature"];
    if (!STRIPE_WEBHOOK_SECRET_CONNECT && !STRIPE_WEBHOOK_SECRET) {
      return res.status(500).send("Webhook secret not configured");
    }

    try {
      if (STRIPE_WEBHOOK_SECRET_CONNECT) {
        const handledStandardEvent = await handleStandardConnectWebhookEvent(
          payload,
          sig,
          STRIPE_WEBHOOK_SECRET_CONNECT,
        );

        if (!handledStandardEvent) {
          await handleThinConnectWebhookEvent(
            payload,
            sig,
            STRIPE_WEBHOOK_SECRET_CONNECT,
          );
        }
      } else {
        await handleLegacyConnectWebhookEvent(payload, sig);
      }

      return res.status(200).send("OK");
    } catch (err) {
      console.error("Webhook error:", err);
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// WEBHOOK: SUBSCRIPTION EVENTS
// ─────────────────────────────────────────────────────────────────────────────
const stripeSubscriptionWebhook = onRequest(
  withStripeSecret({ region: REGION, invoker: "public" }),
  async (req, res) => {
    if (!getStripe()) return res.status(500).send("Stripe not configured");
    if (req.method !== "POST")
      return res.status(405).send("Method not allowed");

    const sig = req.headers["stripe-signature"];
    if (!STRIPE_WEBHOOK_SECRET_SUBSCRIPTIONS) {
      return res.status(500).send("Webhook secret not configured");
    }

    let event;
    try {
      event = stripe.webhooks.constructEvent(
        req.rawBody || req.body,
        sig,
        STRIPE_WEBHOOK_SECRET_SUBSCRIPTIONS,
      );
    } catch (err) {
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    try {
      const payload = event.data?.object;
      const accountId = payload?.customer_account;

      switch (event.type) {
        case "customer.subscription.created":
        case "customer.subscription.updated":
        case "customer.subscription.deleted": {
          await syncSubscriptionLifecycleForAccount(
            accountId,
            payload,
            event.type === "customer.subscription.deleted",
          );
          break;
        }
        case "invoice.paid": {
          await recordSubscriptionInvoicePaid(accountId, payload);
          break;
        }
        case "invoice.payment_failed": {
          await markSubscriptionPaymentFailedForAccount(accountId);
          break;
        }
      }
      return res.status(200).send("OK");
    } catch (err) {
      console.error("Error processing webhook:", err);
      return res.status(500).send(`Error: ${err.message}`);
    }
  },
);

module.exports = {
  createConnectedAccountV2,
  createAccountLink,
  getConnectedAccountStatus: getConnectedAccountStatusV2,
  createConnectedProduct,
  listConnectedProducts,
  createConnectedCheckout,
  createConnectedSubscription,
  createBillingPortalSession,
  getSubscriptionStatus,
  stripeConnectWebhook,
  stripeSubscriptionWebhook,
};
