import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import Stripe from "stripe";

// Initialize Stripe with your Secret Key
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY as string, {
  apiVersion: "2023-10-16",
});

const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET as string;

export const stripeWebhookHandler = functions
  .region("australia-southeast1")
  .https.onRequest(async (req, res) => {
    const sig = req.headers["stripe-signature"];
    let event: Stripe.Event;

    try {
      // Cryptographically verify the webhook signature
      event = stripe.webhooks.constructEvent(req.rawBody, sig!, endpointSecret);
    } catch (err: any) {
      functions.logger.error(`Webhook signature verification failed: ${err.message}`);
      res.status(400).send(`Webhook Error: ${err.message}`);
      return;
    }

    // Route the event to the correct fulfillment logic
    try {
      switch (event.type) {
        case "checkout.session.completed":
          const session = event.data.object as Stripe.Checkout.Session;
          await fulfillCheckout(session);
          break;
        default:
          functions.logger.info(`Unhandled event type ${event.type}`);
      }
      res.json({ received: true });
    } catch (error) {
      functions.logger.error(`Error processing webhook: ${error}`);
      res.status(500).send("Internal Server Error");
    }
  });

async function fulfillCheckout(session: Stripe.Checkout.Session) {
  const metadata = session.metadata;
  if (!metadata) return;

  const { uid, targetType, targetId, scope, level, tokenAmount } = metadata;
  const batch = admin.firestore().batch();

  if (targetType === "ppv" || targetType === "subscription") {
    // Mint Entitlements (Rights to access Graph Content)
    const entRef = admin.firestore().collection("entitlements").doc();
    batch.set(entRef, {
      id: entRef.id,
      userId: uid,
      creatorId: targetType === "ppv" ? "SYSTEM" : targetId,
      scope: scope || `event:${targetId}`,
      level: level || "standard",
      source: "stripe_checkout",
      active: true,
      createdAt: Date.now(),
    });
  } else if (targetType === "tokens" && tokenAmount) {
    const parsedAmount = parseInt(tokenAmount, 10);
    if (!isNaN(parsedAmount) && parsedAmount > 0) {
      // Disburse DFC Tokens into Wallet
      const walletRef = admin.firestore().collection("wallets").doc(uid);
      batch.set(walletRef, {
        balance: admin.firestore.FieldValue.increment(parsedAmount),
        lastUpdated: Date.now(),
      }, { merge: true });
    } else {
      functions.logger.error(`Invalid tokenAmount provided for user ${uid}: ${tokenAmount}`);
    }
  }

  await batch.commit();
  functions.logger.info(`Successfully fulfilled ${targetType} for user: ${uid}`);
}