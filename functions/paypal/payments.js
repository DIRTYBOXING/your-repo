// ═══════════════════════════════════════════════════════════════════════════
// PAYPAL PAYMENTS — PPV, Subscriptions & One-Time Purchases
// ═══════════════════════════════════════════════════════════════════════════
//
// Uses PayPal REST API v2 (Orders + Subscriptions).
// Credentials: PAYPAL_CLIENT_ID + PAYPAL_CLIENT_SECRET in environment.
//
// Flow:
//   1. Flutter calls createPayPalOrder → returns approval URL
//   2. User completes payment on PayPal hosted page
//   3. PayPal redirects to success URL → Flutter calls capturePayPalOrder
//   4. Cloud Function captures the order and records in Firestore
//
// ═══════════════════════════════════════════════════════════════════════════

const { onCall, onRequest } = require("firebase-functions/v2/https");
const { admin, db, REGION } = require("../config");
const axios = require("axios");
const {
  getCanonicalPpvAccessState,
  readDateTime,
  resolvePpvEventDocument,
} = require("../ppv/access_state");
const {
  upsertCanonicalPpvCheckoutSession,
} = require("../ppv/canonical_checkout_sessions");

// ── PayPal Configuration ─────────────────────────────────────────────────

const PAYPAL_CLIENT_ID = process.env.PAYPAL_CLIENT_ID || "";
const PAYPAL_CLIENT_SECRET = process.env.PAYPAL_CLIENT_SECRET || "";
const PAYPAL_MODE = process.env.PAYPAL_MODE || "sandbox"; // 'sandbox' or 'live'

const PAYPAL_BASE_URL =
  PAYPAL_MODE === "live"
    ? "https://api-m.paypal.com"
    : "https://api-m.sandbox.paypal.com";

const PAYPAL_WEBHOOK_ID = process.env.PAYPAL_WEBHOOK_ID || "";

// ── DFC Fee (same sliding model as Stripe) ───────────────────────────────
const DFC_FEE_FLOOR = 0.3;
const DFC_FEE_CEILING = 0.5;
const DFC_MAX_EXPOSURE = 10000;

function getDfcFeePercent(buyCount) {
  if (buyCount <= 0) return DFC_FEE_FLOOR;
  if (buyCount >= DFC_MAX_EXPOSURE) return DFC_FEE_CEILING;
  return (
    DFC_FEE_FLOOR +
    (DFC_FEE_CEILING - DFC_FEE_FLOOR) * (buyCount / DFC_MAX_EXPOSURE)
  );
}

// ── Get PayPal Access Token ──────────────────────────────────────────────

async function getPayPalAccessToken() {
  if (!PAYPAL_CLIENT_ID || !PAYPAL_CLIENT_SECRET) {
    throw new Error("PayPal credentials not configured");
  }

  const auth = Buffer.from(
    `${PAYPAL_CLIENT_ID}:${PAYPAL_CLIENT_SECRET}`,
  ).toString("base64");

  const response = await axios.post(
    `${PAYPAL_BASE_URL}/v1/oauth2/token`,
    "grant_type=client_credentials",
    {
      headers: {
        Authorization: `Basic ${auth}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
    },
  );

  return response.data.access_token;
}

// ═══════════════════════════════════════════════════════════════════════════
// CREATE PAYPAL ORDER — One-time payment (PPV, Credits, Tickets)
// ═══════════════════════════════════════════════════════════════════════════

const createPayPalOrder = onCall({ region: REGION }, async (request) => {
  const {
    userId,
    amountCents,
    currency,
    productType,
    productId,
    productName,
    tierId,
    tierName,
    tierKey,
    successUrl,
    cancelUrl,
  } = request.data;

  if (!userId || !amountCents || !currency || !productType) {
    return {
      error:
        "Missing required fields: userId, amountCents, currency, productType",
    };
  }

  try {
    if (productType === "ppv" && productId) {
      const accessState = await getCanonicalPpvAccessState({
        db,
        userId,
        eventId: productId,
      });
      if (accessState.hasAccess) {
        return {
          alreadyPurchased: true,
          message: "You already have access to this PPV event",
        };
      }
    }

    const accessToken = await getPayPalAccessToken();
    const amount = (amountCents / 100).toFixed(2);

    const orderPayload = {
      intent: "CAPTURE",
      purchase_units: [
        {
          reference_id: productId || `dfc_${productType}_${Date.now()}`,
          description: productName || `DFC ${productType} purchase`,
          amount: {
            currency_code: currency.toUpperCase(),
            value: amount,
          },
          custom_id: JSON.stringify({
            userId,
            productType,
            productId: productId || null,
            dfcFee: getDfcFeePercent(0),
          }),
        },
      ],
      application_context: {
        brand_name: "Data Fight Central",
        landing_page: "NO_PREFERENCE",
        user_action: "PAY_NOW",
        return_url:
          successUrl || "https://datafightcentral.com/payment-success",
        cancel_url:
          cancelUrl || "https://datafightcentral.com/payment-cancelled",
      },
    };

    const response = await axios.post(
      `${PAYPAL_BASE_URL}/v2/checkout/orders`,
      orderPayload,
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
      },
    );

    const order = response.data;
    const approvalUrl = order.links.find((l) => l.rel === "approve")?.href;

    // Record the pending order in Firestore
    await db
      .collection("paypal_orders")
      .doc(order.id)
      .set({
        orderId: order.id,
        userId,
        amountCents,
        currency: currency.toUpperCase(),
        productType,
        productId: productId || null,
        productName: productName || null,
        tierId: tierId ?? null,
        tierName: tierName || null,
        tierKey: tierKey || null,
        status: "CREATED",
        approvalUrl,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    return {
      orderId: order.id,
      approvalUrl,
      status: order.status,
    };
  } catch (e) {
    console.error("PayPal createOrder error:", e.response?.data || e.message);
    return { error: `Failed to create PayPal order: ${e.message}` };
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// CAPTURE PAYPAL ORDER — Finalize payment after user approval
// ═══════════════════════════════════════════════════════════════════════════

const capturePayPalOrder = onCall({ region: REGION }, async (request) => {
  const { orderId, userId } = request.data;

  if (!orderId || !userId) {
    return { error: "Missing required fields: orderId, userId" };
  }

  try {
    const accessToken = await getPayPalAccessToken();

    const response = await axios.post(
      `${PAYPAL_BASE_URL}/v2/checkout/orders/${encodeURIComponent(orderId)}/capture`,
      {},
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
      },
    );

    const capture = response.data;
    const captureId = capture.purchase_units?.[0]?.payments?.captures?.[0]?.id;
    const capturedAmount =
      capture.purchase_units?.[0]?.payments?.captures?.[0]?.amount;

    // Update Firestore order
    await db
      .collection("paypal_orders")
      .doc(orderId)
      .update({
        status: "COMPLETED",
        captureId: captureId || null,
        capturedAmount: capturedAmount || null,
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    // Record transaction in shared ledger
    await db.collection("transactions").add({
      paymentProvider: "paypal",
      paypalOrderId: orderId,
      paypalCaptureId: captureId || null,
      userId,
      amountCents: capturedAmount
        ? Math.round(Number.parseFloat(capturedAmount.value) * 100)
        : 0,
      currency: capturedAmount?.currency_code || "AUD",
      status: "completed",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Grant access if PPV purchase
    const orderDoc = await db.collection("paypal_orders").doc(orderId).get();
    const orderData = orderDoc.data();
    if (orderData?.productType === "ppv" && orderData?.productId) {
      const amountPaidCents = capturedAmount
        ? Math.round(Number.parseFloat(capturedAmount.value) * 100)
        : orderData.amountCents || 0;
      const sessionRecord = await upsertCanonicalPpvCheckoutSession({
        db,
        sessionId: `paypal_${orderId}`,
        paypalOrderId: orderId,
        userId,
        ppvId: orderData.productId,
        tierId: orderData.tierId,
        tierName: orderData.tierName || orderData.productName || "PAYPAL PPV",
        tierKey:
          orderData.tierKey ||
          orderData.tierName ||
          orderData.productName ||
          "PAYPAL PPV",
        amountCents: amountPaidCents,
        originalAmountCents: orderData.amountCents || amountPaidCents,
        currency: capturedAmount?.currency_code || orderData.currency || "AUD",
        paymentMethod: "paypal",
        paymentProvider: "paypal",
        status: "complete",
        paymentStatus: "completed",
        source: "paypal",
        requestSource: "paypal",
        checkoutSource: "paypal",
      });

      const canonicalPpvId = sessionRecord.canonicalPpvId;
      const replayExpiry = sessionRecord.expiresAt;
      const eventEndedAt = sessionRecord.eventEndedAt;
      const compositeId = `${userId}_${canonicalPpvId}`;
      await db
        .collection("ppv_purchases")
        .doc(compositeId)
        .set(
          {
            userId,
            ppvId: canonicalPpvId,
            ppvEventId: canonicalPpvId,
            eventId: canonicalPpvId,
            paymentProvider: "paypal",
            paymentMethod: "paypal",
            paypalOrderId: orderId,
            tierId: orderData.tierId ?? null,
            tierName:
              orderData.tierName || orderData.productName || "PAYPAL PPV",
            tierKey:
              orderData.tierKey ||
              orderData.tierName ||
              orderData.productName ||
              "PAYPAL PPV",
            purchasedAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: replayExpiry
              ? admin.firestore.Timestamp.fromDate(replayExpiry)
              : null,
            status: "completed",
            paymentStatus: "completed",
            accessGranted: true,
            isActive: true,
            replayExpired: false,
          },
          { merge: true },
        );
      if (canonicalPpvId !== orderData.productId) {
        await db.collection("ppv_purchases").doc(compositeId).set(
          {
            sourceEventId: orderData.productId,
          },
          { merge: true },
        );
      }
      if (eventEndedAt) {
        await db
          .collection("ppv_purchases")
          .doc(compositeId)
          .set(
            {
              eventEndedAt: admin.firestore.Timestamp.fromDate(eventEndedAt),
            },
            { merge: true },
          );
      }
      await db
        .collection("ppv_access")
        .doc(compositeId)
        .set(
          {
            userId,
            eventId: canonicalPpvId,
            sourceEventId: orderData.productId,
            paymentProvider: "paypal",
            paypalOrderId: orderId,
            bundleName:
              orderData.tierName || orderData.productName || "PAYPAL PPV",
            tierId: orderData.tierId ?? null,
            tierName:
              orderData.tierName || orderData.productName || "PAYPAL PPV",
            tierKey:
              orderData.tierKey ||
              orderData.tierName ||
              orderData.productName ||
              "PAYPAL PPV",
            grantedAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: replayExpiry
              ? admin.firestore.Timestamp.fromDate(replayExpiry)
              : null,
            accessGranted: true,
            paymentStatus: "completed",
            isActive: true,
            replayExpired: false,
          },
          { merge: true },
        );
    }

    return {
      status: "COMPLETED",
      captureId,
      amount: capturedAmount,
    };
  } catch (e) {
    console.error("PayPal captureOrder error:", e.response?.data || e.message);
    return { error: `Failed to capture PayPal order: ${e.message}` };
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// PAYPAL WEBHOOK HANDLER — Server-to-server notifications
// ═══════════════════════════════════════════════════════════════════════════

const handlePayPalWebhook = onRequest({ region: REGION }, async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).send("Method not allowed");
  }

  try {
    const event = req.body;
    const eventType = event.event_type;

    // Log webhook for audit
    await db.collection("paypal_webhook_events").add({
      eventType,
      eventId: event.id || null,
      resourceType: event.resource_type || null,
      summary: event.summary || null,
      receivedAt: admin.firestore.FieldValue.serverTimestamp(),
      raw: JSON.stringify(event).substring(0, 10000),
    });

    switch (eventType) {
      case "CHECKOUT.ORDER.APPROVED": {
        const orderId = event.resource?.id;
        if (orderId) {
          await db.collection("paypal_orders").doc(orderId).update({
            status: "APPROVED",
            approvedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
        break;
      }

      case "PAYMENT.CAPTURE.COMPLETED": {
        const captureId = event.resource?.id;
        const customId = event.resource?.custom_id;
        if (captureId) {
          console.log(`PayPal capture completed: ${captureId}`, customId);
        }
        break;
      }

      case "PAYMENT.CAPTURE.DENIED":
      case "PAYMENT.CAPTURE.REFUNDED": {
        const captureId = event.resource?.id;
        console.log(`PayPal capture ${eventType}: ${captureId}`);
        break;
      }

      default:
        console.log(`Unhandled PayPal event: ${eventType}`);
    }

    res.status(200).json({ received: true });
  } catch (e) {
    console.error("PayPal webhook error:", e);
    res.status(500).json({ error: "Webhook processing failed" });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// EXPORTS
// ═══════════════════════════════════════════════════════════════════════════

module.exports = {
  createPayPalOrder,
  capturePayPalOrder,
  handlePayPalWebhook,
};
