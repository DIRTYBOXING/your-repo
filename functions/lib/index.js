"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.stripeWebhook = exports.createFightStream = exports.bootstrapOwner = void 0;
exports.checkIsSuperAdmin = checkIsSuperAdmin;
const https_1 = require("firebase-functions/v2/https");
const v2_1 = require("firebase-functions/v2");
const admin = require("firebase-admin");
const stripe_1 = require("stripe");
const mux_node_1 = require("@mux/mux-node");
admin.initializeApp();
// ─── COST SAFETY — v2 runtime options set per-function via options param ──
const RUNTIME_OPTS = {
    timeoutSeconds: 30,
    memory: '256MiB',
    maxInstances: 10,
};
const MAX_WRITES_PER_MINUTE = 20;
async function checkRateLimit(uid, action) {
    const key = `rate_limits/${uid}_${action}`;
    const now = Date.now();
    const windowMs = 60 * 1000;
    const ref = admin.firestore().doc(key);
    const doc = await ref.get();
    if (doc.exists) {
        const d = doc.data();
        const windowStart = d.windowStart || 0;
        const count = d.count || 0;
        if (now - windowStart < windowMs) {
            if (count >= MAX_WRITES_PER_MINUTE) {
                v2_1.logger.warn(`Rate limit hit: uid=${uid} action=${action}`);
                return false;
            }
            await ref.update({ count: admin.firestore.FieldValue.increment(1) });
        }
        else {
            await ref.set({ windowStart: now, count: 1 });
        }
    }
    else {
        await ref.set({ windowStart: now, count: 1 });
    }
    return true;
}
const stripe = new stripe_1.default(process.env.STRIPE_SECRET_KEY || '', {
    apiVersion: '2024-04-10',
});
const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET || '';
const mux = new mux_node_1.default({
    tokenId: process.env.MUX_TOKEN_ID || '',
    tokenSecret: process.env.MUX_TOKEN_SECRET || '',
});
async function getUserData(uid) {
    const doc = await admin.firestore().collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
}
async function checkIsSuperAdmin(uid) {
    const data = await getUserData(uid);
    return data?.role === 'superadmin' || data?.role === 'admin';
}
async function isPromoter(uid) {
    const data = await getUserData(uid);
    return data?.role === 'promoter' || data?.role === 'superadmin' || data?.role === 'admin';
}
// ── Owner Bootstrap ───────────────────────────────────────────────────────
exports.bootstrapOwner = (0, https_1.onRequest)(RUNTIME_OPTS, async (req, res) => {
    const secret = req.headers['x-bootstrap-secret'];
    if (secret !== process.env.BOOTSTRAP_SECRET) {
        res.status(403).send('Forbidden');
        return;
    }
    const ownerEmail = 'owner@datafightcentral.com';
    const existing = await admin.firestore()
        .collection('users').where('email', '==', ownerEmail).limit(1).get();
    if (!existing.empty) {
        res.status(200).send('Owner already seeded.');
        return;
    }
    await admin.firestore().collection('platform_config').doc('ownership').set({
        headPilot: ownerEmail,
        role: 'superadmin',
        title: 'Head Pilot & Platform Owner — Data Fight Central',
        seededAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    v2_1.logger.info('DFC Owner bootstrapped:', ownerEmail);
    res.status(200).send(`Platform Owner seeded: ${ownerEmail}`);
});
// ── Create Mux Live Stream ────────────────────────────────────────────────
exports.createFightStream = (0, https_1.onCall)(RUNTIME_OPTS, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError('unauthenticated', 'User must be logged in');
    }
    const allowed = await checkRateLimit(request.auth.uid, 'createFightStream');
    if (!allowed) {
        throw new https_1.HttpsError('resource-exhausted', 'Rate limit exceeded. Try again in 1 minute.');
    }
    const isUserPromoter = await isPromoter(request.auth.uid);
    if (!isUserPromoter) {
        throw new https_1.HttpsError('permission-denied', 'Only promoters can create streams');
    }
    const { eventId } = request.data;
    if (!eventId) {
        throw new https_1.HttpsError('invalid-argument', 'Event ID is required');
    }
    try {
        const liveStream = await mux.video.liveStreams.create({
            playback_policy: ['public'],
            new_asset_settings: { playback_policy: ['public'] },
            test: process.env.NODE_ENV !== 'production',
        });
        await admin.firestore().collection('events').doc(eventId).update({
            streamId: liveStream.id,
            streamKey: liveStream.stream_key,
            playbackId: liveStream.playback_ids?.[0]?.id,
            streamStatus: 'created',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true, liveStreamId: liveStream.id };
    }
    catch (error) {
        v2_1.logger.error('Error creating Mux stream', error);
        throw new https_1.HttpsError('internal', error.message);
    }
});
// ── Stripe Webhook ────────────────────────────────────────────────────────
exports.stripeWebhook = (0, https_1.onRequest)(RUNTIME_OPTS, async (req, res) => {
    const sig = req.headers['stripe-signature'];
    if (!sig) {
        res.status(400).send('Missing stripe-signature header');
        return;
    }
    let event;
    try {
        event = stripe.webhooks.constructEvent(req.rawBody, sig, endpointSecret);
    }
    catch (err) {
        v2_1.logger.error(`Webhook signature verification failed: ${err.message}`);
        res.status(400).send(`Webhook Error: ${err.message}`);
        return;
    }
    try {
        if (event.type === 'checkout.session.completed') {
            const session = event.data.object;
            await handleSuccessfulPayment(session);
        }
        else {
            v2_1.logger.info(`Unhandled event type ${event.type}`);
        }
        res.json({ received: true });
    }
    catch (err) {
        v2_1.logger.error(`Error handling event: ${err}`);
        res.status(500).send('Internal Server Error');
    }
});
async function handleSuccessfulPayment(session) {
    const userId = session.metadata?.userId;
    const productId = session.metadata?.productId;
    if (!userId || !productId) {
        v2_1.logger.error('Missing userId or productId in session metadata');
        return;
    }
    await admin.firestore().collection('ppv_purchases').add({
        userId,
        productId,
        amount: session.amount_total,
        currency: session.currency,
        status: 'completed',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        paymentIntentId: session.payment_intent,
    });
    v2_1.logger.info(`Purchase recorded: user=${userId} product=${productId}`);
}
//# sourceMappingURL=index.js.map