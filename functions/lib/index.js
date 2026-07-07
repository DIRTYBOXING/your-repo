"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.autoFix = exports.placeSponsorBid = exports.renderOctanePromo = exports.systemIntegrityCheck = exports.onRevenueEventCreate = exports.runReadinessModel = exports.onTelemetryWrite = exports.muxWebhook = exports.stripeWebhook = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const stripe_1 = __importDefault(require("stripe"));
const google_auth_library_1 = require("google-auth-library");
const https_1 = require("firebase-functions/v2/https");
const node_fs_1 = __importDefault(require("node:fs"));
if (process.env.GOOGLE_APPLICATION_CREDENTIALS && !node_fs_1.default.existsSync(process.env.GOOGLE_APPLICATION_CREDENTIALS)) {
    functions.logger.warn(`Ignoring stale GOOGLE_APPLICATION_CREDENTIALS path: ${process.env.GOOGLE_APPLICATION_CREDENTIALS}`);
    delete process.env.GOOGLE_APPLICATION_CREDENTIALS;
}
admin.initializeApp();
const db = admin.firestore();
const stripeSecret = process.env.STRIPE_SECRET_KEY || process.env.STRIPE_SECRET || "";
const stripeEndpointSecret = process.env.STRIPE_WEBHOOK_SECRET ||
    process.env.STRIPE_ENDPOINT_SECRET ||
    process.env.STRIPE_WEBHOOK_SIGNING_SECRET ||
    "";
const stripe = stripeSecret
    ? new stripe_1.default(stripeSecret, {
        apiVersion: "2024-04-10",
    })
    : null;
// ═══════════════════════════════════════════════════════════════════════════
// 💰 STRIPE WEBHOOK - PPV PURCHASES & REVENUE
// ═══════════════════════════════════════════════════════════════════════════
exports.stripeWebhook = (0, https_1.onRequest)({ region: "us-central1", cpu: 1, memory: "256MiB" }, async (req, res) => {
    var _a, _b;
    if (!stripe || !stripeEndpointSecret) {
        functions.logger.error("Stripe webhook is not configured. Missing stripe.secret or stripe.webhook_secret.");
        res.status(500).send("Stripe webhook not configured");
        return;
    }
    const sig = req.headers["stripe-signature"];
    let event;
    try {
        // Cryptographically verify the event came from Stripe
        event = stripe.webhooks.constructEvent(req.rawBody, sig, stripeEndpointSecret);
    }
    catch (err) {
        functions.logger.error(`Webhook Signature Error: ${err.message}`);
        res.status(400).send(`Webhook Error: ${err.message}`);
        return;
    }
    // Handle successful payments
    if (event.type === "checkout.session.completed") {
        const session = event.data.object;
        // Extract custom metadata passed from the Flutter App during checkout
        const userId = (_a = session.metadata) === null || _a === void 0 ? void 0 : _a.userId;
        const eventId = (_b = session.metadata) === null || _b === void 0 ? void 0 : _b.eventId;
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
exports.muxWebhook = (0, https_1.onRequest)({ region: "australia-southeast1" }, async (req, res) => {
    var _a;
    const event = req.body;
    const streamId = (_a = event.data) === null || _a === void 0 ? void 0 : _a.id;
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
            }
            else {
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
    }
    catch (error) {
        functions.logger.error(`Mux Webhook Error: ${error}`);
        res.status(500).send("Internal Server Error");
    }
});
// ═══════════════════════════════════════════════════════════════════════════
// 🧠 AI ENGINE - TELEMETRY INGESTION & READINESS MODEL
// ═══════════════════════════════════════════════════════════════════════════
// 1. Trigger: Push new hardware telemetry into the AI processing queue
exports.onTelemetryWrite = functions.firestore.document("telemetry/{docId}").onWrite(async (change, context) => {
    const data = change.after.data();
    if (!data)
        return;
    const fighterId = data.fighterId;
    if (!fighterId)
        return;
    // Push to AI queue to be processed in batches
    await db.collection("aiQueue").add({
        fighterId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
});
// 2. Scheduled Job: Process the queue and output Readiness/Fatigue scores
exports.runReadinessModel = functions.pubsub.schedule("every 15 minutes").onRun(async () => {
    const queueSnap = await db.collection("aiQueue").limit(10).get();
    if (queueSnap.empty)
        return;
    for (const doc of queueSnap.docs) {
        const { fighterId } = doc.data();
        // TODO: Pass actual telemetry window to Vertex AI / Gemini here
        await db
            .collection("ai_insights")
            .doc(fighterId)
            .set({
            readinessScore: Math.floor(Math.random() * 40) + 60, // 60-100 baseline
            fatigueScore: Math.floor(Math.random() * 30) + 10,
            injuryRisk: Math.floor(Math.random() * 20),
            lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        await doc.ref.delete();
    }
});
// ═══════════════════════════════════════════════════════════════════════════
// 💸 SPLIT ENGINE - REVENUE DISTRIBUTION
// ═══════════════════════════════════════════════════════════════════════════
exports.onRevenueEventCreate = functions.firestore
    .document("revenueEvents/{revId}")
    .onCreate(async (snap, context) => {
    var _a;
    const rev = snap.data();
    if (!rev)
        return;
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
    batch.set(platformBalRef, {
        ownerType: "platform",
        ownerId: "DFC",
        balanceCents: admin.firestore.FieldValue.increment(platformShare),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    // 2. Identify Event & Credit Promoter
    const eventDoc = await db.collection("events").doc(eventId).get();
    if (eventDoc.exists) {
        const promoterId = (_a = eventDoc.data()) === null || _a === void 0 ? void 0 : _a.promoter_id;
        if (promoterId) {
            const promoterBalRef = db.collection("payoutBalances").doc(`promoter_${promoterId}`);
            batch.set(promoterBalRef, {
                ownerType: "promoter",
                ownerId: promoterId,
                balanceCents: admin.firestore.FieldValue.increment(promoterShare),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });
        }
        // 3. Find Fighters from the Event's bouts and split the Fighter Pool
        const fightsSnap = await db.collection("fights").where("event_id", "==", eventId).get();
        const fighterIds = new Set();
        fightsSnap.docs.forEach((doc) => {
            const fight = doc.data();
            if (fight.fighter_a_id)
                fighterIds.add(fight.fighter_a_id);
            if (fight.fighter_b_id)
                fighterIds.add(fight.fighter_b_id);
        });
        if (fighterIds.size > 0) {
            const perFighterShare = Math.floor(fighterPool / fighterIds.size);
            fighterIds.forEach((fId) => {
                const fighterBalRef = db.collection("payoutBalances").doc(`fighter_${fId}`);
                batch.set(fighterBalRef, {
                    ownerType: "fighter",
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
exports.systemIntegrityCheck = functions.pubsub.schedule("every 6 hours").onRun(async () => {
    const report = {
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
                if (report.status !== "RED")
                    report.status = "YELLOW";
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
    }
    catch (e) {
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
exports.renderOctanePromo = functions
    .runWith({ timeoutSeconds: 540, memory: "1GB" })
    .https.onCall(async (data, context) => {
    if (!context.auth)
        throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
    const { eventId, theme, imageUrls } = data;
    if (!eventId || !theme || !imageUrls) {
        throw new functions.https.HttpsError("invalid-argument", "Missing required fields.");
    }
    const CLOUD_RUN_URL = "https://dfc-octane-engine-xyz123-uc.a.run.app"; // <-- REPLACE WITH ACTUAL
    try {
        // Secure IAM-authenticated request to Cloud Run
        const auth = new google_auth_library_1.GoogleAuth();
        const client = await auth.getIdTokenClient(CLOUD_RUN_URL);
        await client.request({
            url: `${CLOUD_RUN_URL}/render-octane`,
            method: "POST",
            data: { eventId, theme, imageUrls },
        });
        const expectedVideoUrl = `https://storage.googleapis.com/datafightcentral.appspot.com/octane_final/${eventId}_promo.mp4`;
        return { videoUrl: expectedVideoUrl, status: "processing", message: "Octane Engine render job started." };
    }
    catch (e) {
        functions.logger.error("Failed to invoke secured Cloud Run service", e);
        throw new functions.https.HttpsError("internal", "Octane Engine securely rejected the render job.");
    }
});
// ═══════════════════════════════════════════════════════════════════════════
// 🤝 SPONSORSHIP SYSTEM - BIDDING ENGINE
// ═══════════════════════════════════════════════════════════════════════════
exports.placeSponsorBid = functions.https.onCall(async (data, context) => {
    if (!context.auth)
        throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
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
exports.autoFix = functions.https.onCall(async (data, context) => {
    var _a, _b, _c;
    // Verify Admin Status
    const uid = (_a = context.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!uid)
        throw new functions.https.HttpsError("unauthenticated", "Not allowed");
    const userDoc = await db.collection("users").doc(uid).get();
    if (((_b = userDoc.data()) === null || _b === void 0 ? void 0 : _b.role) !== "admin" && ((_c = userDoc.data()) === null || _c === void 0 ? void 0 : _c.role) !== "superadmin") {
        throw new functions.https.HttpsError("permission-denied", "Admins only");
    }
    const reportSnap = await db.collection("selfCheckReports").orderBy("timestamp", "desc").limit(1).get();
    if (reportSnap.empty)
        return { message: "No reports found" };
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
            .set({
            flagged: true,
            flaggedReason: `Percent total = ${split.total}`,
            flaggedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        fixes.invalidSplitsFlagged++;
    }
    // 3) Flag payout balances with missing owners
    for (const balanceId of report.missingOwners || []) {
        await db.collection("payoutBalances").doc(balanceId).set({
            flagged: true,
            flaggedReason: "Owner not found in users collection",
            flaggedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
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
//# sourceMappingURL=index.js.map