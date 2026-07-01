import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import Stripe from 'stripe';

admin.initializeApp();
const db = admin.firestore();

// Initialize Stripe with your secret key
const stripe = new Stripe(functions.config().stripe.secret, {
  apiVersion: '2023-10-16',
});
const stripeEndpointSecret = functions.config().stripe.webhook_secret;

// ═══════════════════════════════════════════════════════════════════════════
// 💰 STRIPE WEBHOOK - PPV PURCHASES & REVENUE
// ═══════════════════════════════════════════════════════════════════════════
export const stripeWebhook = functions
  .runWith({ memory: "256MB", timeoutSeconds: 20 })
  .https.onRequest(async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

  const sig = req.headers['stripe-signature'];
    if (!sig) {
      res.status(400).send("Missing Stripe signature");
      return;
    }

  let event;
  try {
    // Cryptographically verify the event came from Stripe
    event = stripe.webhooks.constructEvent(req.rawBody, sig as string, stripeEndpointSecret);
  } catch (err: any) {
      functions.logger.error("❌ Stripe signature verification failed", err);
    res.status(400).send(`Webhook Error: ${err.message}`);
    return;
  }

    // Prevent duplicate processing
    const eventIdStripe = event.id;
    const existing = await db.collection("stripeEvents").doc(eventIdStripe).get();
    if (existing.exists) {
      functions.logger.warn(`⚠️ Duplicate Stripe event ignored: ${eventIdStripe}`);
      res.status(200).send("Duplicate ignored");
      return;
    }
    await db.collection("stripeEvents").doc(eventIdStripe).set({ receivedAt: admin.firestore.FieldValue.serverTimestamp() });

  // Handle successful payments
  if (event.type === 'checkout.session.completed') {
    const session = event.data.object as Stripe.Checkout.Session;

    // Extract custom metadata passed from the Flutter App during checkout
    const userId = session.metadata?.userId;
    const eventId = session.metadata?.eventId;

      if (!userId || !eventId) {
        functions.logger.error("❌ Missing metadata in Stripe session");
        res.status(400).send("Missing metadata");
        return;
      }

      const batch = db.batch();

      // 1. Write the receipt to unlock the PPV for the user
      const purchaseRef = db.collection('ppvPurchases').doc();
      batch.set(purchaseRef, {
        userId,
        eventId,
        status: 'paid',
        paymentProvider: 'stripe',
        amountTotal: session.amount_total ?? 0,
        currency: session.currency,
        purchaseTime: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 2. Log Revenue for the Promoter Dashboard
      const revenueRef = db.collection('revenueEvents').doc();
      batch.set(revenueRef, {
        eventId,
        revenueType: 'ppv',
        amount: (session.amount_total ?? 0) / 100,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      await batch.commit();
      functions.logger.info(`✅ PPV unlocked for User: ${userId}, Event: ${eventId}`);
  }

    res.status(200).json({ received: true });
});

// ═══════════════════════════════════════════════════════════════════════════
// 📺 MUX WEBHOOK - STREAMING OBSERVABILITY & STATUS
// ═══════════════════════════════════════════════════════════════════════════
export const muxWebhook = functions
  .runWith({ memory: "256MB", timeoutSeconds: 20 })
  .https.onRequest(async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

  const event = req.body;
  const streamId = event.data?.id;
    const eventType = event.type;

    if (!streamId || !eventType) {
      res.status(400).send('Invalid Mux payload');
    return;
  }

  try {
    // Find the PPV event tied to this specific Mux Stream ID
    const ppvEventsRef = db.collection('ppvEvents').where('streamId', '==', streamId);
      const ppvSnap = await ppvEventsRef.limit(1).get();

      if (ppvSnap.empty) {
        functions.logger.warn(`⚠️ No PPV event found for streamId: ${streamId}`);
        res.status(200).send("No matching PPV");
        return;
      }

      const docId = ppvSnap.docs[0].id;
      const isLive = eventType === 'video.live_stream.active';

      // Flip the 'isActive' boolean to instantly update the UI for all fans connected to Firestore
      await db.collection('ppvEvents').doc(docId).update({
        isActive: isLive,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      if (isLive) {
        functions.logger.info(`🔴 Stream went LIVE for PPV Event: ${docId}`);
        await db.collection('streamSessions').add({
          eventId: docId,
          streamId: streamId,
          status: 'started',
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        functions.logger.info(`⏹ Stream DISCONNECTED for PPV Event: ${docId}`);
        // Log a stream session end for QA and Observability
        await db.collection('streamSessions').add({
          eventId: docId,
          streamId: streamId,
          status: 'ended',
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

    res.status(200).json({ received: true });
  } catch (error) {
      functions.logger.error("❌ Mux Webhook Error", error);
    res.status(500).send('Internal Server Error');
  }
});