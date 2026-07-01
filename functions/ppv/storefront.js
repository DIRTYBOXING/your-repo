const jwt = require("jsonwebtoken");
const { onRequest } = require("firebase-functions/v2/https");

const {
  db,
  FieldValue,
  REGION,
  getStripe,
  withStripeSecret,
  withMuxSecrets,
  getMuxRuntimeConfig,
} = require("../config");

const DEFAULT_TIERS = {
  standard: {
    amountCents: 4499,
    currency: "aud",
    title: "Standard",
  },
  premium: {
    amountCents: 6999,
    currency: "aud",
    title: "Premium",
  },
  ultimate: {
    amountCents: 8999,
    currency: "aud",
    title: "Ultimate Bundle",
  },
};

function sanitizeBody(req) {
  return req.body && typeof req.body === "object" ? req.body : {};
}

function resolveTier(eventData, tierId) {
  const normalizedTierId = String(tierId || "premium")
    .trim()
    .toLowerCase();
  const eventTier = eventData?.pricingTiers?.[normalizedTierId];
  if (eventTier && typeof eventTier.amountCents === "number") {
    return {
      id: normalizedTierId,
      amountCents: eventTier.amountCents,
      currency: String(eventTier.currency || "aud").toLowerCase(),
      title: eventTier.title || normalizedTierId,
    };
  }

  const fallback = DEFAULT_TIERS[normalizedTierId] || DEFAULT_TIERS.premium;
  return {
    id: normalizedTierId,
    ...fallback,
  };
}

function buildSandboxEvent(eventId) {
  return {
    id: eventId,
    collection: "sandbox",
    data: {
      title: "DFC Sandbox Main Card",
      name: "DFC Sandbox Main Card",
      playbackId: null,
      pricingTiers: DEFAULT_TIERS,
    },
  };
}

function isSandboxEventRecord(event) {
  return (
    event?.collection === "sandbox" ||
    String(event?.id || "").startsWith("sandbox-")
  );
}

function signPlaybackToken(playbackId, ttlSeconds = 3600) {
  const { signingKeyId, signingPrivateKey } = getMuxRuntimeConfig();
  if (!signingKeyId || !signingPrivateKey || !playbackId) {
    return null;
  }

  const privateKey = Buffer.from(signingPrivateKey, "base64").toString("ascii");
  const payload = {
    aud: "v",
    sub: playbackId,
    exp: Math.floor(Date.now() / 1000) + ttlSeconds,
    kid: signingKeyId,
  };

  return jwt.sign(payload, privateKey, {
    algorithm: "RS256",
    keyid: signingKeyId,
  });
}

async function loadEvent(eventId) {
  const collections = ["ppv_events", "events"];
  for (const collection of collections) {
    const snap = await db.collection(collection).doc(eventId).get();
    if (snap.exists) {
      return { id: snap.id, collection, data: snap.data() };
    }
  }
  return null;
}

exports.createPpvStorefrontOrder = onRequest(
  withStripeSecret(
    withMuxSecrets({
      region: REGION,
      cors: true,
    }),
  ),
  async (req, res) => {
    if (req.method !== "POST") {
      res.set("Allow", "POST");
      return res.status(405).json({ error: "method_not_allowed" });
    }

    const { eventId, tierId, userId, promoCode } = sanitizeBody(req);
    if (!eventId || !userId) {
      return res.status(400).json({ error: "missing_event_or_user" });
    }

    const requestedEventId = String(eventId);
    const event =
      (await loadEvent(requestedEventId)) ||
      (requestedEventId.startsWith("sandbox-") || requestedEventId == "demo-ppv"
        ? buildSandboxEvent(requestedEventId)
        : null);
    if (!event) {
      return res.status(404).json({ error: "event_not_found" });
    }

    const stripe = getStripe();
    if (!stripe && !isSandboxEventRecord(event)) {
      return res.status(503).json({ error: "stripe_not_configured" });
    }

    const tier = resolveTier(event.data, tierId);
    const orderRef = db.collection("ppv_orders").doc();
    const idempotencyKey = `${requestedEventId}_${String(userId)}_${tier.id}`;

    const paymentIntent = stripe
      ? await stripe.paymentIntents.create(
          {
            amount: tier.amountCents,
            currency: tier.currency,
            automatic_payment_methods: { enabled: true },
            metadata: {
              orderId: orderRef.id,
              eventId: requestedEventId,
              tierId: tier.id,
              userId: String(userId),
              promoCode: String(promoCode || ""),
              source: "ppv_storefront",
            },
          },
          {
            idempotencyKey,
          },
        )
      : {
          id: `sandbox_pi_${orderRef.id}`,
          client_secret: `sandbox_secret_${orderRef.id}`,
        };

    await orderRef.set({
      eventId: requestedEventId,
      eventCollection: event.collection,
      userId: String(userId),
      tierId: tier.id,
      tierTitle: tier.title,
      amountCents: tier.amountCents,
      currency: tier.currency,
      paymentIntentId: paymentIntent.id,
      status: "payment_pending",
      promoCode: String(promoCode || ""),
      playbackId: event.data.playbackId || null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    return res.json({
      orderId: orderRef.id,
      paymentIntentClientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
      eventTitle: event.data.title || event.data.name || "DFC Event",
      tierTitle: tier.title,
    });
  },
);

exports.confirmPpvStorefrontOrder = onRequest(
  withStripeSecret(
    withMuxSecrets({
      region: REGION,
      cors: true,
    }),
  ),
  async (req, res) => {
    if (req.method !== "POST") {
      res.set("Allow", "POST");
      return res.status(405).json({ error: "method_not_allowed" });
    }

    const { orderId, paymentIntentId, sandboxApproved } = sanitizeBody(req);
    if (!orderId) {
      return res.status(400).json({ error: "missing_order_id" });
    }

    const orderRef = db.collection("ppv_orders").doc(String(orderId));
    const orderSnap = await orderRef.get();
    if (!orderSnap.exists) {
      return res.status(404).json({ error: "order_not_found" });
    }

    const order = orderSnap.data();
    const stripe = getStripe();
    if (!stripe && !sandboxApproved) {
      return res.status(503).json({ error: "stripe_not_configured" });
    }

    let paymentIntent = null;
    if (!sandboxApproved) {
      const targetPaymentIntentId = paymentIntentId || order.paymentIntentId;
      if (!targetPaymentIntentId) {
        return res.status(400).json({ error: "missing_payment_intent_id" });
      }
      paymentIntent = await stripe.paymentIntents.retrieve(
        targetPaymentIntentId,
      );
      if (paymentIntent.status !== "succeeded") {
        return res.status(409).json({
          error: "payment_not_settled",
          status: paymentIntent.status,
        });
      }
    }

    const playbackToken = signPlaybackToken(order.playbackId, 3600);
    const entitlementRef = db
      .collection("ppv_entitlements")
      .doc(`${order.userId}_${order.eventId}`);
    await entitlementRef.set(
      {
        userId: order.userId,
        eventId: order.eventId,
        orderId: orderRef.id,
        status: "active",
        playbackId: order.playbackId || null,
        grantedAt: FieldValue.serverTimestamp(),
        paymentIntentId: paymentIntent?.id || order.paymentIntentId || null,
      },
      { merge: true },
    );

    await orderRef.set(
      {
        status: "paid",
        updatedAt: FieldValue.serverTimestamp(),
        paymentIntentStatus: paymentIntent?.status || "sandbox_succeeded",
      },
      { merge: true },
    );

    return res.json({
      orderId: orderRef.id,
      status: "paid",
      playbackId: order.playbackId || null,
      playbackToken,
    });
  },
);
