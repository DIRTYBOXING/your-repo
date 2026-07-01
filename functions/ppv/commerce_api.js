const crypto = require("node:crypto");
const {
  onCall,
  onRequest,
  HttpsError,
} = require("firebase-functions/v2/https");
const {
  admin,
  db,
  FieldValue,
  REGION,
  stripe,
  getStripe,
  withStripeSecret,
  STRIPE_WEBHOOK_SECRET,
} = require("../config");
const { grantPPVAccess } = require("../stripe/ppv");

const DEFAULT_SUCCESS_URL =
  "https://datafightcentral.com/ppv/success?session_id={CHECKOUT_SESSION_ID}";
const DEFAULT_CANCEL_URL = "https://datafightcentral.com/ppv";
const BIGQUERY_DATASET = process.env.BIGQUERY_DATASET || "ppv_analytics";
const BIGQUERY_TABLE = process.env.BIGQUERY_TABLE || "events";
const APPLE_SHARED_SECRET = process.env.APPLE_SHARED_SECRET || "";
const GOOGLE_PLAY_PACKAGE_NAME =
  process.env.GOOGLE_PLAY_PACKAGE_NAME || "com.datafightcentral.app";

let bigQueryClient = null;
let googleAuthClient = null;

function getBigQueryClient() {
  if (bigQueryClient) return bigQueryClient;
  try {
    // Optional dependency: telemetry gracefully degrades when BigQuery SDK is absent.
    const { BigQuery } = require("@google-cloud/bigquery");
    bigQueryClient = new BigQuery();
    return bigQueryClient;
  } catch {
    return null;
  }
}

async function logPpvAnalytics(name, payload = {}) {
  try {
    const client = getBigQueryClient();
    if (!client) return;

    const row = {
      event_name: name,
      event_ts: new Date().toISOString(),
      payload_json: JSON.stringify(payload),
    };

    await client.dataset(BIGQUERY_DATASET).table(BIGQUERY_TABLE).insert([row], {
      ignoreUnknownValues: true,
      skipInvalidRows: true,
    });
  } catch (error) {
    console.warn("BigQuery analytics write skipped:", error.message);
  }
}

async function getGoogleAuthToken() {
  if (googleAuthClient) {
    const token = await googleAuthClient.getAccessToken();
    return token?.token || token;
  }

  try {
    // Loaded lazily to avoid hard dependency if environment does not need IAP validation.
    const { GoogleAuth } = require("google-auth-library");
    googleAuthClient = new GoogleAuth({
      scopes: ["https://www.googleapis.com/auth/androidpublisher"],
    });
    const client = await googleAuthClient.getClient();
    googleAuthClient = client;
    const token = await client.getAccessToken();
    return token?.token || token;
  } catch {
    return null;
  }
}

function normalizeCurrency(value) {
  if (typeof value !== "string" || !value.trim()) return "aud";
  return value.trim().toLowerCase();
}

function normalizeAmountCents(value) {
  const parsed = Number(value);
  if (Number.isFinite(parsed) && parsed > 0) {
    return Math.round(parsed);
  }
  return null;
}

function hashPurchaseFingerprint(input) {
  return crypto.createHash("sha256").update(input).digest("hex").slice(0, 24);
}

function normalizeEventPrice(eventData) {
  const amountFromPrice = normalizeAmountCents(
    Number(eventData?.price || 0) * 100,
  );
  if (amountFromPrice != null) return amountFromPrice;

  const amountFromCents = normalizeAmountCents(eventData?.priceCents);
  if (amountFromCents != null) return amountFromCents;

  return null;
}

function parseGsPath(input) {
  if (typeof input !== "string" || !input.trim()) return null;
  const value = input.trim();

  if (value.startsWith("gs://")) {
    const withoutScheme = value.slice(5);
    const slashIndex = withoutScheme.indexOf("/");
    if (slashIndex === -1) {
      return null;
    }

    const bucketName = withoutScheme.slice(0, slashIndex).trim();
    const objectPath = withoutScheme.slice(slashIndex + 1).trim();
    if (!bucketName || !objectPath) return null;
    return { bucketName, objectPath };
  }

  if (/^https?:\/\//i.test(value)) {
    return null;
  }

  const objectPath = value.replace(/^\/+/, "");
  if (!objectPath) return null;
  return { bucketName: null, objectPath };
}

async function resolveAuthenticatedUser(req) {
  const authHeader = req.headers.authorization || req.headers.Authorization;
  if (
    !authHeader ||
    typeof authHeader !== "string" ||
    !authHeader.startsWith("Bearer ")
  ) {
    return null;
  }

  const idToken = authHeader.slice("Bearer ".length).trim();
  if (!idToken) return null;

  try {
    return await admin.auth().verifyIdToken(idToken);
  } catch {
    return null;
  }
}

function resolveUserIdFromBody(body) {
  if (!body || typeof body !== "object") return null;
  const value = body.userId;
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed || null;
}

async function resolveEventById(eventId) {
  const directDoc = await db.collection("events").doc(eventId).get();
  if (directDoc.exists) {
    return { id: directDoc.id, data: directDoc.data() || {} };
  }

  const ppvDirectDoc = await db.collection("ppv_events").doc(eventId).get();
  if (ppvDirectDoc.exists) {
    return { id: ppvDirectDoc.id, data: ppvDirectDoc.data() || {} };
  }

  const eventsByAlias = await db
    .collection("events")
    .where("eventId", "==", eventId)
    .limit(1)
    .get();
  if (!eventsByAlias.empty) {
    const doc = eventsByAlias.docs[0];
    return { id: doc.id, data: doc.data() || {} };
  }

  const ppvByAlias = await db
    .collection("ppv_events")
    .where("eventId", "==", eventId)
    .limit(1)
    .get();
  if (!ppvByAlias.empty) {
    const doc = ppvByAlias.docs[0];
    return { id: doc.id, data: doc.data() || {} };
  }

  return null;
}

async function hasPpvAccess({ userId, eventId }) {
  const entitlementIds = new Set([eventId]);
  const eventLookup = await resolveEventById(eventId);
  if (eventLookup?.id) entitlementIds.add(eventLookup.id);
  if (eventLookup?.data?.eventId)
    entitlementIds.add(String(eventLookup.data.eventId));

  const checks = [];
  for (const lookupId of entitlementIds) {
    const entitlementDocId = `${userId}_${lookupId}`;
    checks.push(db.collection("entitlements").doc(entitlementDocId).get());
    checks.push(db.collection("purchases").doc(entitlementDocId).get());
    checks.push(db.collection("ppv_access").doc(entitlementDocId).get());
    checks.push(db.collection("ppv_purchases").doc(entitlementDocId).get());
    checks.push(
      db
        .collection("entitlements")
        .where("userId", "==", userId)
        .where("eventId", "==", lookupId)
        .limit(1)
        .get(),
    );
    checks.push(
      db
        .collection("purchases")
        .where("userId", "==", userId)
        .where("eventId", "==", lookupId)
        .where("status", "in", ["completed", "pending"])
        .limit(1)
        .get(),
    );
  }

  const snapshots = await Promise.all(checks);
  for (const snapshot of snapshots) {
    if (!snapshot) continue;

    if (typeof snapshot.exists === "boolean") {
      if (!snapshot.exists) continue;
      const data = snapshot.data() || {};
      if (
        data.hasAccess === true ||
        data.accessGranted === true ||
        data.isActive === true
      ) {
        return true;
      }

      const status = String(
        data.status || data.paymentStatus || "",
      ).toLowerCase();
      if (
        status === "completed" ||
        status === "succeeded" ||
        status === "active"
      ) {
        return true;
      }
      continue;
    }

    if (Array.isArray(snapshot.docs) && snapshot.docs.length > 0) {
      const data = snapshot.docs[0].data() || {};
      const status = String(
        data.status || data.paymentStatus || "",
      ).toLowerCase();
      if (
        data.hasAccess === true ||
        data.accessGranted === true ||
        data.isActive === true ||
        status === "completed" ||
        status === "succeeded" ||
        status === "active"
      ) {
        return true;
      }
    }
  }

  return false;
}

async function writeUnifiedPurchaseAndEntitlement({
  userId,
  eventId,
  provider,
  providerPaymentId,
  amount,
  currency,
  status = "completed",
  entitlementExpiresAt = null,
}) {
  const suffix = hashPurchaseFingerprint(
    `${provider}:${providerPaymentId}:${userId}:${eventId}`,
  );
  const purchaseDocId = `${userId}_${eventId}_${provider}_${suffix}`;
  const entitlementId = `${userId}_${eventId}`;

  const purchasePayload = {
    userId,
    eventId,
    provider,
    providerPaymentId,
    amount,
    currency: (currency || "AUD").toUpperCase(),
    status,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    entitlementExpiresAt: entitlementExpiresAt || null,
    sourcePurchaseId: purchaseDocId,
  };

  await db
    .collection("purchases")
    .doc(purchaseDocId)
    .set(purchasePayload, { merge: true });

  await db
    .collection("entitlements")
    .doc(entitlementId)
    .set(
      {
        userId,
        eventId,
        hasAccess: status === "completed",
        grantedAt: FieldValue.serverTimestamp(),
        sourcePurchaseId: purchaseDocId,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

  await db
    .collection("ppv_purchases")
    .doc(entitlementId)
    .set(
      {
        userId,
        ppvId: eventId,
        ppvEventId: eventId,
        eventId,
        paymentProvider: provider,
        stripePaymentId: providerPaymentId,
        amountCents: normalizeAmountCents(amount * 100) || 0,
        currency: (currency || "AUD").toUpperCase(),
        status: status === "completed" ? "completed" : status,
        paymentStatus: status === "completed" ? "succeeded" : status,
        accessGranted: status === "completed",
        isActive: status === "completed",
        purchasedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

  await db
    .collection("ppv_access")
    .doc(entitlementId)
    .set(
      {
        userId,
        eventId,
        paymentProvider: provider,
        stripePaymentId: providerPaymentId,
        accessGranted: status === "completed",
        isActive: status === "completed",
        grantedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

  return { purchaseDocId, entitlementId };
}

async function verifyAppleReceipt({ receiptData, sharedSecret }) {
  const body = {
    "receipt-data": receiptData,
    password: sharedSecret || undefined,
    "exclude-old-transactions": true,
  };

  const callVerifyReceipt = async (url) => {
    const response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    return response.json();
  };

  let result = await callVerifyReceipt(
    "https://buy.itunes.apple.com/verifyReceipt",
  );
  if (result?.status === 21007) {
    result = await callVerifyReceipt(
      "https://sandbox.itunes.apple.com/verifyReceipt",
    );
  }

  if (!result || result.status !== 0) {
    throw new Error(
      `Apple receipt validation failed with status ${result?.status ?? "unknown"}`,
    );
  }

  const latest =
    result.latest_receipt_info?.[0] || result.receipt?.in_app?.[0] || null;
  if (!latest) {
    throw new Error("Apple receipt has no in-app purchase records");
  }

  return {
    providerPaymentId: latest.transaction_id || latest.original_transaction_id,
    productId: latest.product_id || null,
    entitlementExpiresAt: latest.expires_date_ms
      ? new Date(Number(latest.expires_date_ms))
      : null,
  };
}

async function verifyGoogleReceipt({ packageName, productId, purchaseToken }) {
  const token = await getGoogleAuthToken();
  if (!token) {
    throw new Error(
      "Google auth token unavailable for Play Billing verification",
    );
  }

  const endpoint =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}` +
    `/purchases/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`;

  const response = await fetch(endpoint, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: "application/json",
    },
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(
      `Google receipt validation failed (${response.status}): ${body}`,
    );
  }

  const data = await response.json();
  if (data.purchaseState !== 0) {
    throw new Error(
      `Google purchaseState ${data.purchaseState} is not purchased`,
    );
  }

  return {
    providerPaymentId: data.orderId || purchaseToken,
    productId,
    entitlementExpiresAt: data.expiryTimeMillis
      ? new Date(Number(data.expiryTimeMillis))
      : null,
  };
}

async function getOrCreateStripeCustomerId(userId) {
  const existing = await db.collection("stripe_customers").doc(userId).get();
  if (existing.exists && existing.data()?.stripeCustomerId) {
    return existing.data().stripeCustomerId;
  }

  const userDoc = await db.collection("users").doc(userId).get();
  const email = userDoc.exists
    ? userDoc.data().email || `${userId}@dfc.app`
    : `${userId}@dfc.app`;

  const customer = await stripe.customers.create({
    email,
    metadata: { dfcUserId: userId },
  });

  await db.collection("stripe_customers").doc(userId).set(
    {
      stripeCustomerId: customer.id,
      email,
      createdAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return customer.id;
}

function writeWebhookLog(event) {
  return db
    .collection("webhooks")
    .doc("stripeEvents")
    .collection("events")
    .doc(event.id)
    .set(
      {
        eventId: event.id,
        type: event.type,
        livemode: event.livemode === true,
        processedAt: FieldValue.serverTimestamp(),
        created: event.created || null,
      },
      { merge: true },
    );
}

async function processCheckoutCompleted(session) {
  const metadata = session.metadata || {};
  const userId = metadata.dfcUserId || metadata.userId;
  const eventId = metadata.ppvId || metadata.eventId;

  if (!userId || !eventId) {
    return;
  }

  await grantPPVAccess({
    id: session.payment_intent || session.id,
    canonicalSessionId: session.id,
    amount: session.amount_total || 0,
    currency: session.currency || "aud",
    metadata: {
      ...metadata,
      productType: "ppv",
      ppvId: eventId,
      dfcUserId: userId,
    },
  });

  await writeUnifiedPurchaseAndEntitlement({
    userId,
    eventId,
    provider: "stripe",
    providerPaymentId: session.payment_intent || session.id,
    amount: Number(((session.amount_total || 0) / 100).toFixed(2)),
    currency: (session.currency || "aud").toUpperCase(),
    status: "completed",
  });

  await logPpvAnalytics("checkout.session.completed", {
    userId,
    eventId,
    sessionId: session.id,
    paymentIntentId: session.payment_intent || null,
    amountCents: session.amount_total || 0,
    currency: session.currency || "aud",
  });
}

const createStripeCheckoutApi = onRequest(
  withStripeSecret({ region: REGION, cors: true }),
  async (req, res) => {
    if (!getStripe()) {
      return res.status(500).json({ error: "Stripe not configured" });
    }

    if (req.method !== "POST") {
      return res.status(405).json({ error: "Method not allowed" });
    }

    const decoded = await resolveAuthenticatedUser(req);
    const eventId =
      typeof req.body?.eventId === "string" ? req.body.eventId.trim() : "";
    const explicitUserId = resolveUserIdFromBody(req.body);
    const userId = decoded?.uid || explicitUserId;

    if (!eventId || !userId) {
      return res
        .status(400)
        .json({ error: "eventId and authenticated user are required" });
    }

    if (decoded?.uid && explicitUserId && explicitUserId !== decoded.uid) {
      return res
        .status(403)
        .json({ error: "userId does not match authenticated token" });
    }

    try {
      const event = await resolveEventById(eventId);
      if (!event) {
        return res.status(404).json({ error: "Event not found" });
      }

      const amountCents = normalizeEventPrice(event.data);
      if (amountCents == null) {
        return res
          .status(400)
          .json({ error: "Event does not have a billable price" });
      }

      const currency = normalizeCurrency(event.data.currency);
      const customerId = await getOrCreateStripeCustomerId(userId);

      const successUrl =
        typeof req.body?.successUrl === "string" && req.body.successUrl.trim()
          ? req.body.successUrl.trim()
          : DEFAULT_SUCCESS_URL;
      const cancelUrl =
        typeof req.body?.cancelUrl === "string" && req.body.cancelUrl.trim()
          ? req.body.cancelUrl.trim()
          : DEFAULT_CANCEL_URL;

      const session = await stripe.checkout.sessions.create({
        customer: customerId,
        mode: "payment",
        payment_method_types: ["card"],
        line_items: [
          {
            price_data: {
              currency,
              product_data: {
                name: event.data.title || "DFC PPV Event",
                description: `PPV event ${eventId}`,
                metadata: {
                  eventId,
                  ppvProductId: event.data.ppvProductId || "",
                },
              },
              unit_amount: amountCents,
            },
            quantity: 1,
          },
        ],
        success_url: successUrl,
        cancel_url: cancelUrl,
        metadata: {
          productType: "ppv",
          ppvId: eventId,
          eventId,
          dfcUserId: userId,
          userId,
        },
        payment_intent_data: {
          metadata: {
            productType: "ppv",
            ppvId: eventId,
            eventId,
            dfcUserId: userId,
            userId,
          },
        },
      });

      await db.collection("ppv_checkout_sessions").doc(session.id).set(
        {
          sessionId: session.id,
          userId,
          ppvId: eventId,
          amountCents,
          currency,
          paymentProvider: "stripe",
          paymentStatus: "pending",
          status: "pending",
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      await logPpvAnalytics("checkout.session.created", {
        userId,
        eventId,
        sessionId: session.id,
        amountCents,
        currency,
      });

      return res.status(200).json({
        sessionId: session.id,
        url: session.url,
        amountCents,
        currency,
      });
    } catch (error) {
      console.error("createStripeCheckoutApi failed:", error);
      return res
        .status(500)
        .json({ error: error.message || "Failed to create checkout session" });
    }
  },
);

const stripePpvWebhookApi = onRequest(
  withStripeSecret({ region: REGION, cors: true }),
  async (req, res) => {
    if (!getStripe()) {
      return res.status(500).send("Stripe not configured");
    }

    if (req.method !== "POST") {
      return res.status(405).send("Method not allowed");
    }

    const allowUnsignedLocalEvent =
      process.env.FUNCTIONS_EMULATOR === "true" &&
      req.headers["x-dfc-local-webhook-test"] === "1";

    const signature = req.headers["stripe-signature"];
    let event;
    try {
      if (!STRIPE_WEBHOOK_SECRET && !allowUnsignedLocalEvent) {
        return res.status(500).send("Webhook secret not configured");
      }

      if (STRIPE_WEBHOOK_SECRET) {
        event = stripe.webhooks.constructEvent(
          req.rawBody || req.body,
          signature,
          STRIPE_WEBHOOK_SECRET,
        );
      } else {
        event = req.body;
      }
    } catch (error) {
      if (!allowUnsignedLocalEvent) {
        return res
          .status(400)
          .send(`Webhook verification failed: ${error.message}`);
      }

      try {
        event = Buffer.isBuffer(req.rawBody)
          ? JSON.parse(req.rawBody.toString("utf8"))
          : typeof req.body === "string"
            ? JSON.parse(req.body)
            : req.body;
      } catch (parseError) {
        return res
          .status(400)
          .send(`Webhook parse failed: ${parseError.message}`);
      }
    }

    if (!event?.id || !event?.type) {
      return res.status(400).send("Invalid webhook payload");
    }

    const idempotencyRef = db
      .collection("webhooks")
      .doc("stripeEvents")
      .collection("events")
      .doc(event.id);
    const idempotencyDoc = await idempotencyRef.get();
    if (idempotencyDoc.exists && idempotencyDoc.data()?.processed === true) {
      return res.status(200).send("Already processed");
    }

    try {
      if (event.type === "checkout.session.completed") {
        await processCheckoutCompleted(event.data.object);
      }

      if (event.type === "charge.refunded") {
        const charge = event.data.object || {};
        const paymentIntentId = charge.payment_intent;
        if (paymentIntentId) {
          const purchases = await db
            .collection("purchases")
            .where("providerPaymentId", "==", paymentIntentId)
            .limit(50)
            .get();

          const writes = [];
          for (const doc of purchases.docs) {
            const purchaseData = doc.data() || {};
            writes.push(
              doc.ref.set(
                {
                  status: "refunded",
                  refundedAt: FieldValue.serverTimestamp(),
                  updatedAt: FieldValue.serverTimestamp(),
                },
                { merge: true },
              ),
            );

            if (purchaseData.userId && purchaseData.eventId) {
              const entitlementId = `${purchaseData.userId}_${purchaseData.eventId}`;
              writes.push(
                db.collection("entitlements").doc(entitlementId).set(
                  {
                    hasAccess: false,
                    revokedAt: FieldValue.serverTimestamp(),
                    updatedAt: FieldValue.serverTimestamp(),
                  },
                  { merge: true },
                ),
              );
            }
          }

          await Promise.all(writes);
        }
      }

      await writeWebhookLog(event);
      await logPpvAnalytics("stripe.webhook.processed", {
        eventId: event.id,
        eventType: event.type,
        livemode: event.livemode === true,
      });
      await idempotencyRef.set(
        {
          processed: true,
          processedAt: FieldValue.serverTimestamp(),
          type: event.type,
        },
        { merge: true },
      );
      return res.status(200).send("OK");
    } catch (error) {
      console.error("stripePpvWebhookApi failed:", error);
      await idempotencyRef.set(
        {
          processed: false,
          failedAt: FieldValue.serverTimestamp(),
          type: event.type,
          error: error.message || "Webhook failure",
        },
        { merge: true },
      );
      return res.status(500).send(error.message || "Webhook failure");
    }
  },
);

async function buildSignedPlaybackResponse({ userId, eventId }) {
  const hasAccess = await hasPpvAccess({ userId, eventId });
  if (!hasAccess) {
    return {
      status: 403,
      body: { error: "PPV access required", needsPurchase: true },
    };
  }

  const event = await resolveEventById(eventId);
  if (!event) {
    return { status: 404, body: { error: "Event not found" } };
  }

  const rawStreamUrl =
    event.data.streamUrl ||
    event.data.hlsUrl ||
    event.data.videoUrl ||
    event.data.videoPath ||
    null;

  if (!rawStreamUrl) {
    return {
      status: 404,
      body: { error: "No stream URL configured for this event" },
    };
  }

  const gs = parseGsPath(rawStreamUrl);
  if (!gs) {
    return {
      status: 200,
      body: {
        signedUrl: rawStreamUrl,
        source: "external",
        expiresAt: null,
      },
    };
  }

  const bucket = gs.bucketName
    ? admin.storage().bucket(gs.bucketName)
    : admin.storage().bucket();
  const file = bucket.file(gs.objectPath);
  const [exists] = await file.exists();
  if (!exists) {
    return {
      status: 404,
      body: { error: "Protected stream object not found" },
    };
  }

  const expiresAt = Date.now() + 15 * 60 * 1000;
  const [signedUrl] = await file.getSignedUrl({
    action: "read",
    version: "v4",
    expires: expiresAt,
  });

  await db.collection("playback_access_logs").add({
    userId,
    eventId,
    streamPath: gs.objectPath,
    requestedAt: FieldValue.serverTimestamp(),
    expiresAt: new Date(expiresAt),
  });

  await logPpvAnalytics("playback.signed_url.issued", {
    userId,
    eventId,
    streamPath: gs.objectPath,
    expiresAt,
  });

  return {
    status: 200,
    body: {
      signedUrl,
      source: "gcs",
      expiresAt: new Date(expiresAt).toISOString(),
    },
  };
}

const getPpvSignedVideoUrlApi = onRequest(
  { region: REGION, cors: true },
  async (req, res) => {
    if (req.method !== "GET") {
      return res.status(405).json({ error: "Method not allowed" });
    }

    const decoded = await resolveAuthenticatedUser(req);
    if (!decoded?.uid) {
      return res.status(401).json({ error: "Authentication required" });
    }

    const eventId =
      typeof req.query?.eventId === "string" ? req.query.eventId.trim() : "";
    if (!eventId) {
      return res
        .status(400)
        .json({ error: "eventId query parameter is required" });
    }

    try {
      const response = await buildSignedPlaybackResponse({
        userId: decoded.uid,
        eventId,
      });
      return res.status(response.status).json(response.body);
    } catch (error) {
      console.error("getPpvSignedVideoUrlApi failed:", error);
      return res
        .status(500)
        .json({ error: error.message || "Failed to create signed URL" });
    }
  },
);

const getPpvSignedVideoUrl = onCall({ region: REGION }, async (request) => {
  const userId = request.auth?.uid;
  const eventId =
    typeof request.data?.eventId === "string"
      ? request.data.eventId.trim()
      : "";

  if (!userId) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }
  if (!eventId) {
    throw new HttpsError("invalid-argument", "eventId is required");
  }

  const response = await buildSignedPlaybackResponse({ userId, eventId });
  if (response.status !== 200) {
    const code = response.status === 403 ? "permission-denied" : "not-found";
    throw new HttpsError(
      code,
      response.body.error || "Unable to resolve playback URL",
    );
  }
  return response.body;
});

function computeReadinessIssueCounts({ events, purchases, entitlements }) {
  const issues = [];

  if (events < 1) {
    issues.push("No events documents found");
  }
  if (purchases < 1) {
    issues.push("No purchases records found");
  }
  if (entitlements < 1) {
    issues.push("No entitlements records found");
  }

  return issues;
}

const adminPpvReadiness = onRequest(
  { region: REGION, cors: true },
  async (req, res) => {
    if (req.method !== "GET") {
      return res.status(405).json({ error: "Method not allowed" });
    }

    const decoded = await resolveAuthenticatedUser(req);
    if (!decoded?.admin) {
      return res.status(403).json({ error: "Admin access required" });
    }

    try {
      const [eventsCount, purchasesCount, entitlementsCount] =
        await Promise.all([
          db.collection("events").count().get(),
          db.collection("purchases").count().get(),
          db.collection("entitlements").count().get(),
        ]);

      const counts = {
        events: eventsCount.data().count || 0,
        purchases: purchasesCount.data().count || 0,
        entitlements: entitlementsCount.data().count || 0,
      };

      const issues = computeReadinessIssueCounts(counts);
      return res.status(200).json({
        status: issues.length ? "warning" : "ok",
        counts,
        issues,
        checkedAt: new Date().toISOString(),
      });
    } catch (error) {
      console.error("adminPpvReadiness failed:", error);
      return res
        .status(500)
        .json({ error: error.message || "Readiness check failed" });
    }
  },
);

const verifyIapReceiptApi = onRequest(
  { region: REGION, cors: true },
  async (req, res) => {
    if (req.method !== "POST") {
      return res.status(405).json({ error: "Method not allowed" });
    }

    const decoded = await resolveAuthenticatedUser(req);
    const explicitUserId = resolveUserIdFromBody(req.body);
    const userId = decoded?.uid || explicitUserId;
    const eventId =
      typeof req.body?.eventId === "string" ? req.body.eventId.trim() : "";
    const provider =
      typeof req.body?.provider === "string"
        ? req.body.provider.trim().toLowerCase()
        : "";

    if (!userId || !eventId || !provider) {
      return res
        .status(400)
        .json({ error: "userId, eventId, and provider are required" });
    }

    if (decoded?.uid && explicitUserId && explicitUserId !== decoded.uid) {
      return res
        .status(403)
        .json({ error: "userId does not match authenticated token" });
    }

    try {
      const event = await resolveEventById(eventId);
      if (!event) {
        return res.status(404).json({ error: "Event not found" });
      }

      const amount = Number(req.body?.amount || event.data?.price || 0);
      const currency = (
        req.body?.currency ||
        event.data?.currency ||
        "AUD"
      ).toString();

      let verification;
      if (provider === "apple") {
        const receiptData =
          typeof req.body?.receiptData === "string"
            ? req.body.receiptData.trim()
            : "";
        if (!receiptData) {
          return res.status(400).json({
            error: "receiptData is required for Apple IAP verification",
          });
        }
        verification = await verifyAppleReceipt({
          receiptData,
          sharedSecret: APPLE_SHARED_SECRET,
        });
      } else if (provider === "google") {
        const purchaseToken =
          typeof req.body?.purchaseToken === "string"
            ? req.body.purchaseToken.trim()
            : "";
        const productId =
          typeof req.body?.productId === "string"
            ? req.body.productId.trim()
            : "";
        const packageName =
          typeof req.body?.packageName === "string" &&
          req.body.packageName.trim()
            ? req.body.packageName.trim()
            : GOOGLE_PLAY_PACKAGE_NAME;

        if (!purchaseToken || !productId) {
          return res.status(400).json({
            error:
              "purchaseToken and productId are required for Google IAP verification",
          });
        }

        verification = await verifyGoogleReceipt({
          packageName,
          productId,
          purchaseToken,
        });
      } else {
        return res
          .status(400)
          .json({ error: "provider must be apple or google" });
      }

      const writeResult = await writeUnifiedPurchaseAndEntitlement({
        userId,
        eventId,
        provider,
        providerPaymentId: verification.providerPaymentId,
        amount,
        currency,
        status: "completed",
        entitlementExpiresAt: verification.entitlementExpiresAt,
      });

      await logPpvAnalytics("iap.receipt.verified", {
        provider,
        userId,
        eventId,
        providerPaymentId: verification.providerPaymentId,
        productId: verification.productId,
      });

      return res.status(200).json({
        success: true,
        provider,
        purchaseId: writeResult.purchaseDocId,
        entitlementId: writeResult.entitlementId,
        providerPaymentId: verification.providerPaymentId,
        productId: verification.productId,
        entitlementExpiresAt: verification.entitlementExpiresAt
          ? verification.entitlementExpiresAt.toISOString()
          : null,
      });
    } catch (error) {
      console.error("verifyIapReceiptApi failed:", error);
      return res
        .status(500)
        .json({ error: error.message || "IAP verification failed" });
    }
  },
);

const verifyIapReceipt = onCall({ region: REGION }, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  const userId = request.auth.uid;
  const eventId = (request.data?.eventId || "").toString().trim();
  const provider = (request.data?.provider || "")
    .toString()
    .trim()
    .toLowerCase();

  if (!eventId || !provider) {
    throw new HttpsError(
      "invalid-argument",
      "eventId and provider are required",
    );
  }

  let verification;
  if (provider === "apple") {
    const receiptData = (request.data?.receiptData || "").toString().trim();
    if (!receiptData) {
      throw new HttpsError(
        "invalid-argument",
        "receiptData is required for Apple IAP verification",
      );
    }
    verification = await verifyAppleReceipt({
      receiptData,
      sharedSecret: APPLE_SHARED_SECRET,
    });
  } else if (provider === "google") {
    const purchaseToken = (request.data?.purchaseToken || "").toString().trim();
    const productId = (request.data?.productId || "").toString().trim();
    const packageName = (request.data?.packageName || GOOGLE_PLAY_PACKAGE_NAME)
      .toString()
      .trim();

    if (!purchaseToken || !productId) {
      throw new HttpsError(
        "invalid-argument",
        "purchaseToken and productId are required for Google IAP verification",
      );
    }

    verification = await verifyGoogleReceipt({
      packageName,
      productId,
      purchaseToken,
    });
  } else {
    throw new HttpsError(
      "invalid-argument",
      "provider must be apple or google",
    );
  }

  const event = await resolveEventById(eventId);
  if (!event) {
    throw new HttpsError("not-found", "Event not found");
  }

  const amount = Number(request.data?.amount || event.data?.price || 0);
  const currency = (
    request.data?.currency ||
    event.data?.currency ||
    "AUD"
  ).toString();
  const writeResult = await writeUnifiedPurchaseAndEntitlement({
    userId,
    eventId,
    provider,
    providerPaymentId: verification.providerPaymentId,
    amount,
    currency,
    status: "completed",
    entitlementExpiresAt: verification.entitlementExpiresAt,
  });

  await logPpvAnalytics("iap.receipt.verified", {
    provider,
    userId,
    eventId,
    providerPaymentId: verification.providerPaymentId,
    productId: verification.productId,
  });

  return {
    success: true,
    provider,
    purchaseId: writeResult.purchaseDocId,
    entitlementId: writeResult.entitlementId,
    providerPaymentId: verification.providerPaymentId,
    productId: verification.productId,
    entitlementExpiresAt: verification.entitlementExpiresAt
      ? verification.entitlementExpiresAt.toISOString()
      : null,
  };
});

const adminPpvReadinessCallable = onCall(
  { region: REGION },
  async (request) => {
    if (!request.auth?.token?.admin) {
      throw new HttpsError("permission-denied", "Admin access required");
    }

    const [eventsCount, purchasesCount, entitlementsCount] = await Promise.all([
      db.collection("events").count().get(),
      db.collection("purchases").count().get(),
      db.collection("entitlements").count().get(),
    ]);

    const counts = {
      events: eventsCount.data().count || 0,
      purchases: purchasesCount.data().count || 0,
      entitlements: entitlementsCount.data().count || 0,
    };

    const issues = computeReadinessIssueCounts(counts);
    return {
      status: issues.length === 0 ? "ok" : "warning",
      counts,
      issues,
      checkedAt: new Date().toISOString(),
    };
  },
);

const adminPpvRefundCallable = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    if (!request.auth?.token?.admin) {
      throw new HttpsError("permission-denied", "Admin access required");
    }

    if (!getStripe()) {
      throw new HttpsError("failed-precondition", "Stripe not configured");
    }

    const purchaseId = (request.data?.purchaseId || "").toString().trim();
    const providerPaymentId = (request.data?.providerPaymentId || "")
      .toString()
      .trim();
    const amountCents = normalizeAmountCents(request.data?.amountCents);

    if (!purchaseId && !providerPaymentId) {
      throw new HttpsError(
        "invalid-argument",
        "purchaseId or providerPaymentId is required",
      );
    }

    let purchaseDoc = null;
    if (purchaseId) {
      const byId = await db.collection("purchases").doc(purchaseId).get();
      if (byId.exists) purchaseDoc = byId;
    }

    if (!purchaseDoc && providerPaymentId) {
      const byPayment = await db
        .collection("purchases")
        .where("providerPaymentId", "==", providerPaymentId)
        .limit(1)
        .get();
      if (!byPayment.empty) purchaseDoc = byPayment.docs[0];
    }

    if (!purchaseDoc) {
      throw new HttpsError("not-found", "Purchase not found");
    }

    const purchase = purchaseDoc.data() || {};
    const paymentIntentId = purchase.providerPaymentId || providerPaymentId;
    if (!paymentIntentId) {
      throw new HttpsError(
        "invalid-argument",
        "Purchase has no providerPaymentId",
      );
    }

    const refundParams = { payment_intent: paymentIntentId };
    if (amountCents != null) {
      refundParams.amount = amountCents;
    }
    const refund = await stripe.refunds.create(refundParams);

    await purchaseDoc.ref.set(
      {
        status: "refunded",
        refundedAt: FieldValue.serverTimestamp(),
        stripeRefundId: refund.id,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    if (purchase.userId && purchase.eventId) {
      await db
        .collection("entitlements")
        .doc(`${purchase.userId}_${purchase.eventId}`)
        .set(
          {
            hasAccess: false,
            revokedAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
    }

    await logPpvAnalytics("admin.refund.created", {
      purchaseId: purchaseDoc.id,
      paymentIntentId,
      refundId: refund.id,
    });

    return {
      success: true,
      purchaseId: purchaseDoc.id,
      refundId: refund.id,
    };
  },
);

const adminPpvEntitlementAuditCallable = onCall(
  { region: REGION },
  async (request) => {
    if (!request.auth?.token?.admin) {
      throw new HttpsError("permission-denied", "Admin access required");
    }

    const limit = Math.max(1, Math.min(Number(request.data?.limit || 10), 50));
    const [entitlementsSnap, purchasesSnap] = await Promise.all([
      db
        .collection("entitlements")
        .orderBy("updatedAt", "desc")
        .limit(limit)
        .get(),
      db
        .collection("purchases")
        .orderBy("updatedAt", "desc")
        .limit(limit)
        .get(),
    ]);

    const entitlements = entitlementsSnap.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    const purchases = purchasesSnap.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    return {
      summary: {
        entitlementCount: entitlements.length,
        purchaseCount: purchases.length,
      },
      entitlements,
      purchases,
      fetchedAt: new Date().toISOString(),
    };
  },
);

const adminPpvRefund = onRequest(
  withStripeSecret({ region: REGION, cors: true }),
  async (req, res) => {
    if (!getStripe()) {
      return res.status(500).json({ error: "Stripe not configured" });
    }

    if (req.method !== "POST") {
      return res.status(405).json({ error: "Method not allowed" });
    }

    const decoded = await resolveAuthenticatedUser(req);
    if (!decoded?.admin) {
      return res.status(403).json({ error: "Admin access required" });
    }

    const purchaseId =
      typeof req.body?.purchaseId === "string"
        ? req.body.purchaseId.trim()
        : "";
    const providerPaymentId =
      typeof req.body?.providerPaymentId === "string"
        ? req.body.providerPaymentId.trim()
        : "";
    const amountCents = normalizeAmountCents(req.body?.amountCents);

    if (!purchaseId && !providerPaymentId) {
      return res
        .status(400)
        .json({ error: "purchaseId or providerPaymentId is required" });
    }

    try {
      let purchaseDoc = null;
      if (purchaseId) {
        const byId = await db.collection("purchases").doc(purchaseId).get();
        if (byId.exists) {
          purchaseDoc = byId;
        }
      }

      if (!purchaseDoc && providerPaymentId) {
        const byPayment = await db
          .collection("purchases")
          .where("providerPaymentId", "==", providerPaymentId)
          .limit(1)
          .get();
        if (!byPayment.empty) {
          purchaseDoc = byPayment.docs[0];
        }
      }

      if (!purchaseDoc) {
        return res.status(404).json({ error: "Purchase not found" });
      }

      const purchase = purchaseDoc.data() || {};
      const paymentIntentId = purchase.providerPaymentId || providerPaymentId;
      if (!paymentIntentId) {
        return res
          .status(400)
          .json({ error: "Purchase has no providerPaymentId" });
      }

      const refundParams = { payment_intent: paymentIntentId };
      if (amountCents != null) {
        refundParams.amount = amountCents;
      }
      const refund = await stripe.refunds.create(refundParams);

      await purchaseDoc.ref.set(
        {
          status: "refunded",
          refundedAt: FieldValue.serverTimestamp(),
          stripeRefundId: refund.id,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      if (purchase.userId && purchase.eventId) {
        const entitlementId = `${purchase.userId}_${purchase.eventId}`;
        await db.collection("entitlements").doc(entitlementId).set(
          {
            hasAccess: false,
            revokedAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }

      return res.status(200).json({
        success: true,
        refundId: refund.id,
        purchaseId: purchaseDoc.id,
      });
    } catch (error) {
      console.error("adminPpvRefund failed:", error);
      return res.status(500).json({ error: error.message || "Refund failed" });
    }
  },
);

module.exports = {
  createStripeCheckoutApi,
  stripePpvWebhookApi,
  verifyIapReceiptApi,
  verifyIapReceipt,
  getPpvSignedVideoUrlApi,
  getPpvSignedVideoUrl,
  adminPpvReadiness,
  adminPpvReadinessCallable,
  adminPpvRefund,
  adminPpvRefundCallable,
  adminPpvEntitlementAuditCallable,
};
