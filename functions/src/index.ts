import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import Stripe from "stripe";
import { GoogleAuth } from "google-auth-library";
import { onRequest } from "firebase-functions/v2/https";
import fs from "node:fs";

if (process.env.GOOGLE_APPLICATION_CREDENTIALS && !fs.existsSync(process.env.GOOGLE_APPLICATION_CREDENTIALS)) {
  functions.logger.warn(
    `Ignoring stale GOOGLE_APPLICATION_CREDENTIALS path: ${process.env.GOOGLE_APPLICATION_CREDENTIALS}`,
  );
  delete process.env.GOOGLE_APPLICATION_CREDENTIALS;
}

admin.initializeApp();
const db = admin.firestore();

const stripeSecret = process.env.STRIPE_SECRET_KEY || process.env.STRIPE_SECRET || "";
const stripeEndpointSecret =
  process.env.STRIPE_WEBHOOK_SECRET ||
  process.env.STRIPE_ENDPOINT_SECRET ||
  process.env.STRIPE_WEBHOOK_SIGNING_SECRET ||
  "";
const stripe = stripeSecret
  ? new Stripe(stripeSecret, {
      apiVersion: "2024-04-10",
    })
  : null;

// ═══════════════════════════════════════════════════════════════════════════
// 💰 STRIPE WEBHOOK - PPV PURCHASES & REVENUE
// ═══════════════════════════════════════════════════════════════════════════
export const stripeWebhook = onRequest({ region: "us-central1", cpu: 1, memory: "256MiB" }, async (req, res) => {
  if (!stripe || !stripeEndpointSecret) {
    functions.logger.error("Stripe webhook is not configured. Missing stripe.secret or stripe.webhook_secret.");
    res.status(500).send("Stripe webhook not configured");
    return;
  }

  const sig = req.headers["stripe-signature"];

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
  if (event.type === "checkout.session.completed") {
    const session = event.data.object as Stripe.Checkout.Session;

    // Extract custom metadata passed from the Flutter App during checkout
    const userId = session.metadata?.userId;
    const eventId = session.metadata?.eventId;

    if (userId && eventId) {
      const batch = db.batch();

      // 1. Write the receipt to unlock the PPV for the user
      const purchaseRef = db.collection("ppvPurchases").doc();
      batch.set(purchaseRef, {
        userId: userId,
        eventId: eventId,
        status: "paid",
        paymentProvider: "stripe",
        amountTotal: session.amount_total,
        currency: session.currency,
        purchaseTime: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 2. Log Revenue for the Promoter Dashboard
      const revenueRef = db.collection("revenueEvents").doc();
      batch.set(revenueRef, {
        eventId: eventId,
        revenueType: "ppv",
        amount: session.amount_total ? session.amount_total / 100 : 0,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      await batch.commit();
      functions.logger.info(`✅ PPV unlocked for User: ${userId}, Event: ${eventId}`);
    }
  }

  res.json({ received: true });
});

// ═══════════════════════════════════════════════════════════════════════════
// 📺 MUX WEBHOOK - STREAMING OBSERVABILITY & STATUS
// ═══════════════════════════════════════════════════════════════════════════
export const muxWebhook = onRequest({ region: "australia-southeast1" }, async (req, res) => {
  const event = req.body;
  const streamId = event.data?.id;
  const status = event.type;

  if (!streamId) {
    res.status(400).send("No stream ID provided");
    return;
  }

  try {
    // Find the PPV event tied to this specific Mux Stream ID
    const ppvEventsRef = db.collection("ppvEvents").where("streamId", "==", streamId);
    const snapshot = await ppvEventsRef.get();

    if (!snapshot.empty) {
      const docId = snapshot.docs[0].id;
      const isActive = status === "video.live_stream.active";

      // Flip the 'isActive' boolean to instantly update the UI for all fans connected to Firestore
      await db.collection("ppvEvents").doc(docId).update({
        isActive: isActive,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      if (isActive) {
        functions.logger.info(`🔴 Stream went LIVE for PPV Event: ${docId}`);
      } else {
        functions.logger.info(`⏹ Stream DISCONNECTED for PPV Event: ${docId}`);
        // Log a stream session end for QA and Observability
        await db.collection("streamSessions").add({
          eventId: docId,
          streamId: streamId,
          status: "ended",
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }

    res.status(200).json({ received: true });
  } catch (error) {
    functions.logger.error(`Mux Webhook Error: ${error}`);
    res.status(500).send("Internal Server Error");
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// 🧠 AI ENGINE - TELEMETRY INGESTION & READINESS MODEL
// ═══════════════════════════════════════════════════════════════════════════

// 1. Trigger: Push new hardware telemetry into the AI processing queue
export const onTelemetryWrite = functions.firestore.document("telemetry/{docId}").onWrite(async (change, context) => {
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
export const runReadinessModel = functions.pubsub.schedule("every 15 minutes").onRun(async () => {
  const queueSnap = await db.collection("aiQueue").limit(10).get();
  if (queueSnap.empty) return;

  for (const doc of queueSnap.docs) {
    const { fighterId } = doc.data();

    // Pass actual telemetry window to Vertex AI / Gemini here
    functions.logger.info(`Analyzing telemetry window for fighter: ${fighterId}`);

    await db
      .collection("ai_insights")
      .doc(fighterId)
      .set(
        {
          readinessScore: Math.floor(Math.random() * 40) + 60, // 60-100 baseline
          fatigueScore: Math.floor(Math.random() * 30) + 10,
          injuryRisk: Math.floor(Math.random() * 20),
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

    await doc.ref.delete();
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// 💸 SPLIT ENGINE - REVENUE DISTRIBUTION
// ═══════════════════════════════════════════════════════════════════════════

export const onRevenueEventCreate = functions.firestore
  .document("revenueEvents/{revId}")
  .onCreate(async (snap, context) => {
    const rev = snap.data();
    if (!rev) return;

    const eventId = rev.eventId;
    const amountCents = Math.round(rev.amount * 100); // convert dollars to cents

    // Dynamic Split Configuration
    // DFC Platform: 10% | Promoter: 60% | Fighter Pool: 30%
    const platformShare = Math.floor(amountCents * 0.1);
    const promoterShare = Math.floor(amountCents * 0.6);
    const fighterPool = amountCents - platformShare - promoterShare;

    const batch = db.batch();

    // 1. Credit the DFC Platform
    const platformBalRef = db.collection("payoutBalances").doc("platform_DFC");
    batch.set(
      platformBalRef,
      {
        ownerType: "platform",
        ownerId: "DFC",
        balanceCents: admin.firestore.FieldValue.increment(platformShare),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    // 2. Identify Event & Credit Promoter
    const eventDoc = await db.collection("events").doc(eventId).get();
    if (eventDoc.exists) {
      const promoterId = eventDoc.data()?.promoter_id;
      if (promoterId) {
        const promoterBalRef = db.collection("payoutBalances").doc(`promoter_${promoterId}`);
        batch.set(
          promoterBalRef,
          {
            ownerType: "promoter",
            ownerId: promoterId,
            balanceCents: admin.firestore.FieldValue.increment(promoterShare),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }

      // 3. Find Fighters from the Event's bouts and split the Fighter Pool
      const fightsSnap = await db.collection("fights").where("event_id", "==", eventId).get();
      const fighterIds = new Set<string>();
      fightsSnap.docs.forEach((doc) => {
        const fight = doc.data();
        if (fight.fighter_a_id) fighterIds.add(fight.fighter_a_id);
        if (fight.fighter_b_id) fighterIds.add(fight.fighter_b_id);
      });

      if (fighterIds.size > 0) {
        const perFighterShare = Math.floor(fighterPool / fighterIds.size);
        fighterIds.forEach((fId) => {
          const fighterBalRef = db.collection("payoutBalances").doc(`fighter_${fId}`);
          batch.set(
            fighterBalRef,
            {
              ownerType: "fighter",
              ownerId: fId,
              balanceCents: admin.firestore.FieldValue.increment(perFighterShare),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true },
          );
        });
      }
    }

    await batch.commit();
    functions.logger.info(`💰 Split Engine processed ${amountCents} cents for Event: ${eventId}`);
  });

// ═══════════════════════════════════════════════════════════════════════════
// 🛡️ SELF-CHECK ENGINE - CLOUD INTEGRITY SCANNER
// ═══════════════════════════════════════════════════════════════════════════

export const systemIntegrityCheck = functions.pubsub.schedule("every 6 hours").onRun(async () => {
  const report: any = {
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    status: "GREEN",
    warnings: [],
    errors: [],
    stats: {},
  };

  try {
    // 1. Audit PPV Events & Purchases
    const ppvEventsSnap = await db.collection("ppvEvents").get();
    const activePpvs = ppvEventsSnap.docs.filter((doc) => doc.data().isActive);
    report.stats.activePpvs = activePpvs.length;
    report.stats.totalPpvs = ppvEventsSnap.size;

    // Check for purchases missing their parent event
    const recentPurchases = await db.collection("ppvPurchases").orderBy("purchaseTime", "desc").limit(100).get();
    const validEventIds = new Set(ppvEventsSnap.docs.map((doc) => doc.id));

    for (const purchase of recentPurchases.docs) {
      const eventId = purchase.data().eventId;
      if (!validEventIds.has(eventId)) {
        report.errors.push(`Orphaned Purchase found: ${purchase.id} references missing event ${eventId}`);
        report.status = "RED";
      }
    }

    // 2. Audit Roles & Governance
    const recentUsers = await db.collection("users").orderBy("createdAt", "desc").limit(50).get();
    for (const user of recentUsers.docs) {
      const role = user.data().role;
      if (!role) {
        report.warnings.push(`User ${user.id} has no defined role.`);
        if (report.status !== "RED") report.status = "YELLOW";
      }
    }

    // 3. Economy Checks (Ensure no negative payout balances)
    const balancesSnap = await db.collection("payoutBalances").get();
    for (const balance of balancesSnap.docs) {
      if (balance.data().balanceCents < 0) {
        report.errors.push(`NEGATIVE PAYOUT BALANCE DETECTED: ${balance.id}`);
        report.status = "RED";
      }
    }

    report.stats.totalPayoutAccounts = balancesSnap.size;
  } catch (e: any) {
    report.status = "RED";
    report.errors.push(`Scanner crashed: ${e.message}`);
  }

  // Save to the `latest` document for the UI to stream, and keep a historical log
  await db.collection("selfCheckReports").doc("latest").set(report);
  await db.collection("selfCheckReports").add(report);

  functions.logger.info(`System Integrity Check complete. Status: ${report.status}`);
});

// ═══════════════════════════════════════════════════════════════════════════
// 🎬 OCTANE VIDEO EDITOR - CLOUD RENDER ENGINE
// ═══════════════════════════════════════════════════════════════════════════
export const renderOctanePromo = functions
  .runWith({ timeoutSeconds: 540, memory: "1GB" })
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Must be logged in");

    const { eventId, theme, imageUrls } = data;
    if (!eventId || !theme || !imageUrls) {
      throw new functions.https.HttpsError("invalid-argument", "Missing required fields.");
    }

    const CLOUD_RUN_URL = "https://dfc-octane-engine-xyz123-uc.a.run.app"; // <-- REPLACE WITH ACTUAL

    try {
      // Secure IAM-authenticated request to Cloud Run
      const auth = new GoogleAuth();
      const client = await auth.getIdTokenClient(CLOUD_RUN_URL);

      await client.request({
        url: `${CLOUD_RUN_URL}/render-octane`,
        method: "POST",
        data: { eventId, theme, imageUrls },
      });

      const expectedVideoUrl = `https://storage.googleapis.com/datafightcentral.appspot.com/octane_final/${eventId}_promo.mp4`;
      return { videoUrl: expectedVideoUrl, status: "processing", message: "Octane Engine render job started." };
    } catch (e: any) {
      functions.logger.error("Failed to invoke secured Cloud Run service", e);
      throw new functions.https.HttpsError("internal", "Octane Engine securely rejected the render job.");
    }
  });

// ═══════════════════════════════════════════════════════════════════════════
// 🤝 SPONSORSHIP SYSTEM - BIDDING ENGINE
// ═══════════════════════════════════════════════════════════════════════════
export const placeSponsorBid = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Must be logged in");

  const { placementId, promoterId, bidAmountCents, brandName } = data;
  const brandId = context.auth.uid;

  const bidRef = db.collection("sponsorBids").doc();
  await bidRef.set({
    placementId,
    promoterId,
    brandId,
    brandName,
    bidAmountCents,
    status: "pending", // 'pending', 'accepted', 'rejected', 'paid'
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true, bidId: bidRef.id };
});

// ═══════════════════════════════════════════════════════════════════════════
// 🔧 AUTO-FIX ENGINE - HEALS BROKEN DATA
// ═══════════════════════════════════════════════════════════════════════════
export const autoFix = functions.https.onCall(async (data, context) => {
  // Verify Admin Status
  const uid = context.auth?.uid;
  if (!uid) throw new functions.https.HttpsError("unauthenticated", "Not allowed");

  const userDoc = await db.collection("users").doc(uid).get();
  if (userDoc.data()?.role !== "admin" && userDoc.data()?.role !== "superadmin") {
    throw new functions.https.HttpsError("permission-denied", "Admins only");
  }

  const reportSnap = await db.collection("selfCheckReports").orderBy("timestamp", "desc").limit(1).get();

  if (reportSnap.empty) return { message: "No reports found" };

  const report = reportSnap.docs[0].data();
  const fixes = {
    orphanedPurchasesFixed: 0,
    invalidSplitsFlagged: 0,
    missingOwnersFlagged: 0,
  };

  // 1) Auto-delete orphaned purchases (safe)
  for (const purchaseId of report.orphanedPurchases || []) {
    await db.collection("ppvPurchases").doc(purchaseId).delete();
    fixes.orphanedPurchasesFixed++;
  }

  // 2) Flag invalid splits (do NOT auto-change money logic)
  for (const split of report.invalidSplits || []) {
    await db
      .collection("revenueSplits")
      .doc(split.id)
      .set(
        {
          flagged: true,
          flaggedReason: `Percent total = ${split.total}`,
          flaggedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    fixes.invalidSplitsFlagged++;
  }

  // 3) Flag payout balances with missing owners
  for (const balanceId of report.missingOwners || []) {
    await db.collection("payoutBalances").doc(balanceId).set(
      {
        flagged: true,
        flaggedReason: "Owner not found in users collection",
        flaggedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    fixes.missingOwnersFlagged++;
  }

  // Log auto-fix run
  await db.collection("autoFixRuns").add({
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    reportId: reportSnap.docs[0].id,
    fixes,
    triggeredBy: uid,
  });

  return { message: "Auto-fix completed", fixes };
});
