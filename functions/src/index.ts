import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import Stripe from 'stripe';
import Mux from '@mux/mux-node';

admin.initializeApp();

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || '', {
  apiVersion: '2023-10-16', // Ensure you are using the correct version
});

const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET || '';

// Mux Initialization
const mux = new Mux({
  tokenId: process.env.MUX_TOKEN_ID || '',
  tokenSecret: process.env.MUX_TOKEN_SECRET || ''
});

// Helper: Check if user is Promoter
async function isPromoter(uid: string): Promise<boolean> {
  const doc = await admin.firestore().collection('users').doc(uid).get();
  return doc.exists && doc.data()?.role === 'promoter';
}

export const createFightStream = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
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