const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);

if (!admin.apps.length) {
  admin.initializeApp();
}

exports.stripeWebhook = functions.region('australia-southeast1').https.onRequest(async (req, res) => {
  const sig = req.headers["stripe-signature"];
  const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET;

  let event;

  try {
    // Verify the webhook signature to ensure it actually came from Stripe
    event = stripe.webhooks.constructEvent(req.rawBody, sig, endpointSecret);
  } catch (err) {
    console.error(`Webhook Signature Error: ${err.message}`);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle successful PPV checkout
  if (event.type === "checkout.session.completed") {
    const session = event.data.object;
    const { userId, eventId } = session.metadata;

    if (userId && eventId) {
      try {
        const db = admin.firestore();
        await db.collection("users").doc(userId).collection("ppv_purchases").doc(eventId).set({
          purchasedAt: admin.firestore.FieldValue.serverTimestamp(),
          stripeSessionId: session.id,
          amountTotal: session.amount_total,
          currency: session.currency,
          status: "active"
        });
        console.log(`✅ Granted PPV entitlement: User ${userId} for Event ${eventId}`);
      } catch (error) {
        console.error("Firestore Entitlement Error:", error);
        return res.status(500).send("Database Error");
      }
    }
  }

  res.json({ received: true });
});