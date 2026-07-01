// stripe_checkout_express.js
const express = require('express');
const app = express();
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY || 'sk_test_fake_xxxx');
const admin = require('firebase-admin');

app.use(express.json());

// Firebase Admin Setup for Staging / Production
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault()
  });
}
const db = admin.firestore();

/**
 * 💳 POST /api/v1/purchase
 * Creates a Stripe Checkout Session supporting Afterpay/Clearpay and Cards
 * directly pointing to the mapped Creator Connect account for instant splits.
 */
app.post('/api/v1/purchase', async (req, res) => {
  const { buyerId, itemType, itemId, creatorId, priceCents } = req.body;

  try {
    // 1. Fetch Creator Connect Account ID
    const creatorSnap = await db.collection('users').doc(creatorId).get();
    const creatorData = creatorSnap.data();
    const connectAccountId = creatorData?.payoutAccountId;

    if (!connectAccountId) {
      return res.status(400).json({ error: 'Creator is not onboarded with Stripe payouts.' });
    }

    // 2. Create Stripe Checkout Session with Direct Payout & Fee Split (10% Platform Fee)
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card', 'afterpay_clearpay'],
      line_items: [{
        price_data: {
          currency: 'aud',
          product_data: {
            name: `${itemType.toUpperCase()} - Unified Direct Purchase`,
            description: `Supporting creator: ${creatorData?.displayName || 'Unknown Athlete'}`,
          },
          unit_amount: priceCents,
        },
        quantity: 1,
      }],
      payment_intent_data: {
        application_fee_amount: Math.round(priceCents * 0.10), // 10% Platform Commission
        transfer_data: {
          destination: connectAccountId,
        },
      },
      mode: 'payment',
      success_url: `https://datafightcentral.com/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `https://datafightcentral.com/cancelled`,
      metadata: {
        buyerId,
        itemType,
        itemId,
        creatorId
      }
    });

    return res.status(200).json({ checkout_url: session.url, session_id: session.id });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

/**
 * 📡 POST /api/v1/webhooks/stripe
 * Endpoint to safely listen for purchase completion and allocate digital credentials.
 */
app.post('/api/v1/webhooks/stripe', async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;

  try {
    event = stripe.webhooks.constructEvent(
      req.body,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET || 'whsec_fake_xxxx'
    );
  } catch (err) {
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle pay completed event
  if (event.type === 'checkout.session.completed') {
    const session = event.data.object;
    const { buyerId, itemType, itemId, creatorId } = session.metadata;

    const orderId = `order_${uuidv4()}`;
    const orderDoc = {
      id: orderId,
      buyerId,
      itemType,
      itemId,
      creatorId,
      amountCents: session.amount_total,
      currency: session.currency,
      status: 'completed',
      created_at: new Date().toISOString(),
    };

    // Issue ticket JWT token or PPV access token based on Type
    if (itemType === 'ticket') {
      const jwt = require('jsonwebtoken');
      const ticketJwt = jwt.sign(
        { orderId, buyerId, itemId, expiresAt: new Date(Date.now() + 86400000 * 3).toISOString() },
        process.env.JWT_SECRET || 'jwt_fake_secret'
      );
      orderDoc.ticketJwt = ticketJwt;
    } else {
      orderDoc.accessToken = `access_token_${uuidv4()}`;
    }

    // Persist finalized Order document to Firestore
    await db.collection('orders').doc(orderId).set(orderDoc);
    console.log(`Finalized unified direct-sale Order: ${orderId}`);
  }

  return res.status(200).json({ received: true });
});

function uuidv4() {
  return require('crypto').randomUUID();
}

module.exports = app;
