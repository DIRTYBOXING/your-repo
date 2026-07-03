import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import Stripe from 'stripe';

admin.initializeApp();

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || '', {
  apiVersion: '2023-10-16', // Ensure you are using the correct version
});

const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET || '';

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