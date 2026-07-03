import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import Stripe from 'stripe';
import Mux from '@mux/mux-node';

admin.initializeApp();

// ─── COST SAFETY CONFIG ───────────────────────────────────────────────────
// Max Cloud Function invocations per instance — prevents runaway billing
const FUNCTION_RUNTIME_OPTS: functions.RuntimeOptions = {
  timeoutSeconds: 30,       // Kill any function running > 30s (default 60s)
  memory: '256MB',          // Minimum memory (default 256MB, saves cost)
  maxInstances: 10,         // Hard cap: max 10 concurrent instances
};

// Rate limit: max writes per user per minute (Firestore abuse guard)
const MAX_WRITES_PER_MINUTE = 20;

async function checkRateLimit(uid: string, action: string): Promise<boolean> {
  const key = `rate_limits/${uid}_${action}`;
  const now = Date.now();
  const windowMs = 60 * 1000; // 1 minute window

  const ref = admin.firestore().doc(key);
  const doc = await ref.get();

  if (doc.exists) {
    const data = doc.data()!;
    const windowStart = data.windowStart || 0;
    const count = data.count || 0;

    if (now - windowStart < windowMs) {
      if (count >= MAX_WRITES_PER_MINUTE) {
        functions.logger.warn(`Rate limit hit: uid=${uid} action=${action}`);
        return false; // blocked
      }
      await ref.update({ count: admin.firestore.FieldValue.increment(1) });
    } else {
      await ref.set({ windowStart: now, count: 1 });
    }
  } else {
    await ref.set({ windowStart: now, count: 1 });
  }
  return true; // allowed
}

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || '', {
  apiVersion: '2023-10-16', // Ensure you are using the correct version
});

const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET || '';

// Mux Initialization
const mux = new Mux({
  tokenId: process.env.MUX_TOKEN_ID || '',
  tokenSecret: process.env.MUX_TOKEN_SECRET || ''
});

// ── Role Helpers ──────────────────────────────────────────────────────────

async function getUserData(uid: string) {
  const doc = await admin.firestore().collection('users').doc(uid).get();
  return doc.exists ? doc.data() : null;
}

async function isSuperAdmin(uid: string): Promise<boolean> {
  const data = await getUserData(uid);
  return data?.role === 'superadmin' || data?.role === 'admin';
}

async function isPromoter(uid: string): Promise<boolean> {
  const data = await getUserData(uid);
  // superadmin/admin can do everything a promoter can
  return data?.role === 'promoter' || data?.role === 'superadmin' || data?.role === 'admin';
}

// ── Owner Bootstrap ───────────────────────────────────────────────────────
// Call once to seed the platform owner record in Firestore
export const bootstrapOwner = functions.https.onRequest(async (req, res) => {
  const secret = req.headers['x-bootstrap-secret'];
  if (secret !== process.env.BOOTSTRAP_SECRET) {
    res.status(403).send('Forbidden');
    return;
  }

  const ownerEmail = 'owner@datafightcentral.com';
  const existing = await admin.firestore()
    .collection('users')
    .where('email', '==', ownerEmail)
    .limit(1)
    .get();

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

  functions.logger.info('DFC Owner bootstrapped:', ownerEmail);
  res.status(200).send(`Platform Owner seeded: ${ownerEmail}`);
});

export const createFightStream = functions.runWith(FUNCTION_RUNTIME_OPTS).https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
  }

  // ── Rate limit check ──
  const allowed = await checkRateLimit(context.auth.uid, 'createFightStream');
  if (!allowed) {
    throw new functions.https.HttpsError('resource-exhausted', 'Rate limit exceeded. Try again in 1 minute.');
  }

  const isUserPromoter = await isPromoter(context.auth.uid);
  if (!isUserPromoter) {
    throw new functions.https.HttpsError('permission-denied', 'Only promoters can create streams');
  }

  const { eventId, title } = data;
  if (!eventId) {
    throw new functions.https.HttpsError('invalid-argument', 'Event ID is required');
  }

  try {
    const liveStream = await mux.video.liveStreams.create({
      playback_policy: ['public'],
      new_asset_settings: { playback_policy: ['public'] },
      test: process.env.NODE_ENV !== 'production'
    });

    await admin.firestore().collection('events').doc(eventId).update({
      streamId: liveStream.id,
      streamKey: liveStream.stream_key,
      playbackId: liveStream.playback_ids?.[0]?.id,
      streamStatus: 'created',
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return { success: true, liveStreamId: liveStream.id };
  } catch (error: any) {
    functions.logger.error('Error creating Mux stream', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

export const stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];

  if (!sig) {
    res.status(400).send('Missing stripe-signature header');
    return;
  }

  let event: Stripe.Event;

  try {
    // We need to use req.rawBody to verify the signature
    event = stripe.webhooks.constructEvent(req.rawBody, sig, endpointSecret);
  } catch (err: any) {
    functions.logger.error(`Webhook signature verification failed: ${err.message}`);
    res.status(400).send(`Webhook Error: ${err.message}`);
    return;
  }

  // Handle the event
  try {
    switch (event.type) {
      case 'checkout.session.completed':
        const session = event.data.object as Stripe.Checkout.Session;
        await handleSuccessfulPayment(session);
        break;
      default:
        functions.logger.info(`Unhandled event type ${event.type}`);
    }

    res.json({ received: true });
  } catch (err) {
    functions.logger.error(`Error handling event: ${err}`);
    res.status(500).send('Internal Server Error');
  }
});

async function handleSuccessfulPayment(session: Stripe.Checkout.Session) {
  // Add your logic to fulfill the purchase
  // e.g., unlocking PPV, adding Digital FIT Coins to user's wallet
  const userId = session.metadata?.userId;
  const productId = session.metadata?.productId;
  
  if (!userId || !productId) {
    functions.logger.error('Missing userId or productId in session metadata');
    return;
  }

  const db = admin.firestore();
  
  // Example: Record the purchase in Firestore
  await db.collection('ppv_purchases').add({
    userId: userId,
    productId: productId,
    amount: session.amount_total,
    currency: session.currency,
    status: 'completed',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    paymentIntentId: session.payment_intent
  });

  functions.logger.info(`Successfully recorded purchase for user ${userId} and product ${productId}`);
}