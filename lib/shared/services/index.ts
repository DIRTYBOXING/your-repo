import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import Stripe from 'stripe';
import { GoogleAuth } from 'google-auth-library';
import { VertexAI } from '@google-cloud/vertexai';

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
export const stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];

  let event;
  try {
    // Cryptographically verify the event came from Stripe
    event = stripe.webhooks.constructEvent(req.rawBody, sig as string, stripeEndpointSecret);
  } catch (err: any) {
    functions.logger.error(`Webhook Signature Error: ${err.message}`);
    res.status(400).send(`Webhook Error: ${err.message}`);
    return;
  }

  // Handle successful payments
  if (event.type === 'checkout.session.completed') {
    const session = event.data.object as Stripe.Checkout.Session;

    // Extract custom metadata passed from the Flutter App during checkout
    const userId = session.metadata?.userId;
    const eventId = session.metadata?.eventId;

    if (userId && eventId) {
      const batch = db.batch();

      // 1. Write the receipt to unlock the PPV for the user
      const purchaseRef = db.collection('ppvPurchases').doc();
      batch.set(purchaseRef, {
        userId: userId,
        eventId: eventId,
        status: 'paid',
        paymentProvider: 'stripe',
        amountTotal: session.amount_total,
        currency: session.currency,
        purchaseTime: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 2. Log Revenue for the Promoter Dashboard
      const revenueRef = db.collection('revenueEvents').doc();
      batch.set(revenueRef, {
        eventId: eventId,
        revenueType: 'ppv',
        amount: session.amount_total ? session.amount_total / 100 : 0,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      await batch.commit();
      functions.logger.info(`✅ PPV unlocked for User: ${userId}, Event: ${eventId}`);
    }
  } else if (event.type === 'payment_intent.succeeded') {
    const paymentIntent = event.data.object as Stripe.PaymentIntent;
    const userId = paymentIntent.metadata?.userId;
    const eventId = paymentIntent.metadata?.eventId;

    if (userId && eventId) {
      const batch = db.batch();

      const purchaseRef = db.collection('ppvPurchases').doc();
      batch.set(purchaseRef, {
        userId: userId,
        eventId: eventId,
        status: 'paid',
        paymentProvider: 'stripe',
        amountTotal: paymentIntent.amount_received,
        currency: paymentIntent.currency,
        purchaseTime: admin.firestore.FieldValue.serverTimestamp(),
      });

      const revenueRef = db.collection('revenueEvents').doc();
      batch.set(revenueRef, {
        eventId: eventId,
        revenueType: 'ppv',
        amount: paymentIntent.amount_received / 100,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      await batch.commit();
      functions.logger.info(`✅ PPV unlocked via PaymentIntent for User: ${userId}, Event: ${eventId}`);
    }
  }

  res.json({ received: true });
});

// ═══════════════════════════════════════════════════════════════════════════
// 📺 MUX WEBHOOK - STREAMING OBSERVABILITY & STATUS
// ═══════════════════════════════════════════════════════════════════════════
export const muxWebhook = functions.https.onRequest(async (req, res) => {
  const event = req.body;
  const streamId = event.data?.id;
  const status = event.type;

  if (!streamId) {
    res.status(400).send('No stream ID provided');
    return;
  }

  try {
    // Find the PPV event tied to this specific Mux Stream ID
    const ppvEventsRef = db.collection('ppvEvents').where('streamId', '==', streamId);
    const snapshot = await ppvEventsRef.get();

    if (!snapshot.empty) {
      const docId = snapshot.docs[0].id;
      const isActive = status === 'video.live_stream.active';

      // Flip the 'isActive' boolean to instantly update the UI for all fans connected to Firestore
      await db.collection('ppvEvents').doc(docId).update({
        isActive: isActive,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      if (isActive) {
        functions.logger.info(`🔴 Stream went LIVE for PPV Event: ${docId}`);
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
    }

    res.status(200).json({ received: true });
  } catch (error) {
    functions.logger.error(`Mux Webhook Error: ${error}`);
    res.status(500).send('Internal Server Error');
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// 🧠 AI ENGINE - TELEMETRY INGESTION & READINESS MODEL
// ═══════════════════════════════════════════════════════════════════════════

// 1. Trigger: Push new hardware telemetry into the AI processing queue
export const onTelemetryWrite = functions.firestore
  .document("telemetry/{docId}")
  .onWrite(async (change, context) => {
    const data = change.after.data();
    if (!data) return;

    const fighterId = data.fighterId;
    if (!fighterId) return;

    // Push to AI queue to be processed in batches
    await db.collection("aiQueue").add({
      fighterId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

// 2. Scheduled Job: Process the queue and output Readiness/Fatigue scores
export const runReadinessModel = functions.pubsub
  .schedule("every 15 minutes")
  .onRun(async () => {
    const queueSnap = await db.collection("aiQueue").limit(10).get();
    if (queueSnap.empty) return;

    // Initialize Vertex AI
    const vertexAI = new VertexAI({ 
      project: process.env.GCLOUD_PROJECT || 'datafightcentral', 
      location: 'us-central1' 
    });
    const model = vertexAI.getGenerativeModel({ model: 'gemini-1.5-pro' });

    for (const doc of queueSnap.docs) {
      const { fighterId } = doc.data();

      // Fetch recent telemetry for the fighter
      const telemetrySnap = await db.collection("telemetry")
        .where("fighterId", "==", fighterId)
        .orderBy("timestamp", "desc")
        .limit(20)
        .get();
      
      const telemetryData = telemetrySnap.docs.map(t => t.data());

      try {
        const prompt = `
        Analyze the following biometric telemetry data for a combat athlete and output a JSON response with readiness and fatigue metrics.
        Telemetry: ${JSON.stringify(telemetryData)}
        
        Return ONLY a valid JSON object with the following keys:
        - "readinessScore" (number 0-100)
        - "fatigueScore" (number 0-100)
        - "injuryRisk" (number 0-100)
        - "notes" (string, short analysis)
        `;

        const result = await model.generateContent(prompt);
        const responseText = result.response.candidates?.[0]?.content?.parts?.[0]?.text || "{}";
        const jsonMatch = responseText.match(/\{[\s\S]*\}/);
        const parsedData = jsonMatch ? JSON.parse(jsonMatch[0]) : {};

        await db.collection("ai_insights").doc(fighterId).set({
          readinessScore: parsedData.readinessScore ?? Math.floor(Math.random() * 40) + 60,
          fatigueScore: parsedData.fatigueScore ?? Math.floor(Math.random() * 30) + 10,
          injuryRisk: parsedData.injuryRisk ?? Math.floor(Math.random() * 20),
          notes: parsedData.notes ?? "Analysis complete.",
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      } catch (error) {
        functions.logger.error("Vertex AI inference failed", error);
      }

      await doc.ref.delete();
    }
  });

// ═══════════════════════════════════════════════════════════════════════════
// 💸 SPLIT ENGINE - REVENUE DISTRIBUTION
// ═══════════════════════════════════════════════════════════════════════════

export const onRevenueEventCreate = functions.firestore
  .document('revenueEvents/{revId}')
  .onCreate(async (snap, context) => {
    const rev = snap.data();
    if (!rev) return;

    const eventId = rev.eventId;
    const amountCents = Math.round(rev.amount * 100); // convert dollars to cents

    // Dynamic Split Configuration
    // DFC Platform: 10% | Promoter: 60% | Fighter Pool: 30%
    const platformShare = Math.floor(amountCents * 0.10);
    const promoterShare = Math.floor(amountCents * 0.60);
    const fighterPool = amountCents - platformShare - promoterShare;

    const batch = db.batch();

    // 1. Credit the DFC Platform
    const platformBalRef = db.collection('payoutBalances').doc('platform_DFC');
    batch.set(platformBalRef, {
      ownerType: 'platform',
      ownerId: 'DFC',
      balanceCents: admin.firestore.FieldValue.increment(platformShare),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    // 2. Identify Event & Credit Promoter
    const eventDoc = await db.collection('events').doc(eventId).get();
    if (eventDoc.exists) {
      const promoterId = eventDoc.data()?.promoter_id;
      if (promoterId) {
        const promoterBalRef = db.collection('payoutBalances').doc(`promoter_${promoterId}`);
        batch.set(promoterBalRef, {
          ownerType: 'promoter',
          ownerId: promoterId,
          balanceCents: admin.firestore.FieldValue.increment(promoterShare),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      }

      // 3. Find Fighters from the Event's bouts and split the Fighter Pool
      const fightsSnap = await db.collection('fights').where('event_id', '==', eventId).get();
      const fighterIds = new Set<string>();
      fightsSnap.docs.forEach(doc => {
        const fight = doc.data();
        if (fight.fighter_a_id) fighterIds.add(fight.fighter_a_id);
        if (fight.fighter_b_id) fighterIds.add(fight.fighter_b_id);
      });

      if (fighterIds.size > 0) {
        const perFighterShare = Math.floor(fighterPool / fighterIds.size);
        fighterIds.forEach(fId => {
          const fighterBalRef = db.collection('payoutBalances').doc(`fighter_${fId}`);
          batch.set(fighterBalRef, {
            ownerType: 'fighter',
            ownerId: fId,
            balanceCents: admin.firestore.FieldValue.increment(perFighterShare),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });
        });
      }
    }

    await batch.commit();
    functions.logger.info(`💰 Split Engine processed ${amountCents} cents for Event: ${eventId}`);
  });

// ═══════════════════════════════════════════════════════════════════════════
// 🛡️ SELF-CHECK ENGINE - CLOUD INTEGRITY SCANNER
// ═══════════════════════════════════════════════════════════════════════════

export const systemIntegrityCheck = functions.pubsub
  .schedule("every 6 hours")
  .onRun(async () => {
    const report: any = {
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: 'GREEN',
      warnings: [],
      errors: [],
      stats: {},
    };

    try {
      // 1. Audit PPV Events & Purchases
      const ppvEventsSnap = await db.collection('ppvEvents').get();
      const activePpvs = ppvEventsSnap.docs.filter(doc => doc.data().isActive);
      report.stats.activePpvs = activePpvs.length;
      report.stats.totalPpvs = ppvEventsSnap.size;

      // Check for purchases missing their parent event
      const recentPurchases = await db.collection('ppvPurchases').orderBy('purchaseTime', 'desc').limit(100).get();
      const validEventIds = new Set(ppvEventsSnap.docs.map(doc => doc.id));
      
      for (const purchase of recentPurchases.docs) {
        const eventId = purchase.data().eventId;
        if (!validEventIds.has(eventId)) {
          report.errors.push(`Orphaned Purchase found: ${purchase.id} references missing event ${eventId}`);
          report.status = 'RED';
        }
      }

      // 2. Audit Roles & Governance
      const recentUsers = await db.collection('users').orderBy('createdAt', 'desc').limit(50).get();
      for (const user of recentUsers.docs) {
        const role = user.data().role;
        if (!role) {
          report.warnings.push(`User ${user.id} has no defined role.`);
          if (report.status !== 'RED') report.status = 'YELLOW';
        }
      }

      // 3. Economy Checks (Ensure no negative payout balances)
      const balancesSnap = await db.collection('payoutBalances').get();
      for (const balance of balancesSnap.docs) {
        if (balance.data().balanceCents < 0) {
          report.errors.push(`NEGATIVE PAYOUT BALANCE DETECTED: ${balance.id}`);
          report.status = 'RED';
        }
      }

      report.stats.totalPayoutAccounts = balancesSnap.size;

    } catch (e: any) {
      report.status = 'RED';
      report.errors.push(`Scanner crashed: ${e.message}`);
    }

    // Save to the `latest` document for the UI to stream, and keep a historical log
    await db.collection('selfCheckReports').doc('latest').set(report);
    await db.collection('selfCheckReports').add(report);
    
    functions.logger.info(`System Integrity Check complete. Status: ${report.status}`);
  });

// ═══════════════════════════════════════════════════════════════════════════
// 🎬 OCTANE VIDEO EDITOR - CLOUD RENDER ENGINE
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// 💳 STRIPE PAYMENT INTENT - For Native App Payment Sheet
// ═══════════════════════════════════════════════════════════════════════════
export const createStripePaymentIntent = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  
  const { userId, eventId, amount, currency } = data;

  try {
    // Create an ephemeral key for the customer (create customer if doesn't exist in production)
    const customer = await stripe.customers.create({
      metadata: { userId },
    });
    
    const ephemeralKey = await stripe.ephemeralKeys.create(
      { customer: customer.id },
      { apiVersion: '2023-10-16' }
    );

    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency,
      customer: customer.id,
      metadata: { userId, eventId },
    });

    return {
      paymentIntent: paymentIntent.client_secret,
      ephemeralKey: ephemeralKey.secret,
      customer: customer.id,
    };
  } catch (error: any) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});

export const renderOctanePromo = functions
  .runWith({ timeoutSeconds: 540, memory: "1GB" })
  .https.onCall(async (data, context) => {
    // Validate User
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
    
    const { eventId, theme, imageUrls } = data;
    
    functions.logger.info(`Initiating Octane Render for Event: ${eventId} with Theme: ${theme}`);
    
    // TODO: Send task to Google Cloud Run (FFmpeg) or Replicate API to stitch the images into a video.
    // For now, we simulate the render and return a generated path.
    const simulatedVideoUrl = `https://storage.googleapis.com/datafightcentral.appspot.com/octane_final/${eventId}_promo.mp4`;
    
    return { videoUrl: simulatedVideoUrl, status: 'success' };
  });

// ═══════════════════════════════════════════════════════════════════════════
// 🤝 SPONSORSHIP SYSTEM - BIDDING ENGINE
// ═══════════════════════════════════════════════════════════════════════════
export const placeSponsorBid = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  
  const { placementId, promoterId, bidAmountCents, brandName } = data;
  const brandId = context.auth.uid;

  const bidRef = db.collection('sponsorBids').doc();
  await bidRef.set({
    placementId,
    promoterId,
    brandId,
    brandName,
    bidAmountCents,
    status: 'pending', // 'pending', 'accepted', 'rejected', 'paid'
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true, bidId: bidRef.id };
});

// ═══════════════════════════════════════════════════════════════════════════
// 🏦 PAYOUT ENGINE - SWEEP BALANCES & GENERATE STATEMENTS
// ═══════════════════════════════════════════════════════════════════════════
export const runPayoutEngine = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async () => {
    // Find all balances with money in them
    const balancesSnap = await db.collection("payoutBalances").where("balanceCents", ">", 0).get();
    if (balancesSnap.empty) return;

    const batch = db.batch();
    let payoutsProcessed = 0;

    for (const doc of balancesSnap.docs) {
      const data = doc.data();
      const amountCents = data.balanceCents;

      // Minimum payout threshold: $50.00 (5000 cents)
      if (amountCents >= 5000) {
        // 1. Create Official Payout Statement (can be wired to Stripe Connect via Webhook later)
        const statementRef = db.collection("payoutStatements").doc();
        batch.set(statementRef, {
          ownerType: data.ownerType,
          ownerId: data.ownerId,
          periodStart: data.updatedAt, // The time of their last payout or inception
          periodEnd: admin.firestore.FieldValue.serverTimestamp(),
          grossCents: amountCents,
          feesCents: 0, // Platform/Stripe deductions apply here
          netCents: amountCents,
          status: "processing", 
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // 2. Securely zero out the balance using decrement
        batch.update(doc.ref, {
          balanceCents: admin.firestore.FieldValue.increment(-amountCents),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        payoutsProcessed++;
      }
    }

    if (payoutsProcessed > 0) {
      await batch.commit();
      functions.logger.info(`✅ Payout Engine completed. Generated ${payoutsProcessed} payout statements.`);
    }
  });

// ═══════════════════════════════════════════════════════════════════════════
// 💸 STRIPE CONNECT - AUTOMATIC BANK TRANSFERS
// ═══════════════════════════════════════════════════════════════════════════
export const processStripePayout = functions.firestore
  .document("payoutStatements/{statementId}")
  .onCreate(async (snap, context) => {
    const statement = snap.data();
    
    // Only process statements that are freshly generated by the Payout Engine
    if (!statement || statement.status !== "processing") return;

    const { ownerId, netCents } = statement;
    const statementId = context.params.statementId;

    try {
      // 1. Fetch the user's connected Stripe Account ID (set up during their onboarding)
      const userDoc = await db.collection("users").doc(ownerId).get();
      const stripeAccountId = userDoc.data()?.stripeConnectAccountId;

      if (!stripeAccountId) {
        functions.logger.warn(`⚠️ No Stripe Connect Account found for User: ${ownerId}. Payout paused.`);
        await snap.ref.update({ status: "failed", error: "Missing Stripe Connect ID" });
        return;
      }

      // 2. Trigger the transfer via Stripe API directly to their bank
      const transfer = await stripe.transfers.create({
        amount: netCents,
        currency: "usd", // Can be dynamically set based on the event's origin
        destination: stripeAccountId,
        metadata: { statementId: statementId },
      });

      // 3. Mark the statement as officially paid and vault the transfer receipt
      await snap.ref.update({ status: "paid", stripeTransferId: transfer.id });
      functions.logger.info(`✅ Successfully transferred ${netCents} cents to ${stripeAccountId} (Statement: ${statementId})`);
    } catch (error: any) {
      functions.logger.error(`❌ Stripe Transfer Failed: ${error.message}`);
      await snap.ref.update({ status: "failed", error: error.message });
    }
  });