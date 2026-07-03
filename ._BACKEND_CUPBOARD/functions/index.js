const functions = require('firebase-functions')
const admin = require('firebase-admin')
const Stripe = require('stripe')

admin.initializeApp()
const db = admin.firestore()
// Initialize Stripe with your secret key from environment variables
const stripe = Stripe(process.env.STRIPE_SECRET_KEY)

/**
 * Webhook to securely ingest live fight telemetry from external providers or AI models.
 * Expects a POST request with the telemetry payload.
 */
exports.ingestFightTelemetry = functions.https.onRequest(async (req, res) => {
  // 1. Verify Authorization (e.g., using a secret API key shared with your ingestion worker)
  const apiKey = req.headers['x-telemetry-api-key']
  if (apiKey !== process.env.TELEMETRY_SECRET_KEY) {
    return res.status(401).json({ error: 'Unauthorized access' })
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' })
  }

  try {
    const {
      eventId,
      timecodeMilliseconds,
      redStrikes,
      blueStrikes,
      redControlTime,
      blueControlTime,
      redWinProbability,
    } = req.body

    if (!eventId || timecodeMilliseconds === undefined) {
      return res
        .status(400)
        .json({ error: 'Missing required fields: eventId, timecodeMilliseconds' })
    }

    // 2. Write to Firestore under the specific event's telemetry subcollection
    // We use the timecode as the Document ID to guarantee natural ordering and prevent duplicates.
    const telemetryRef = db
      .collection('ppv_events')
      .doc(eventId)
      .collection('telemetry')
      .doc(timecodeMilliseconds.toString())

    await telemetryRef.set({
      timecodeMilliseconds,
      redStrikes: redStrikes || 0,
      blueStrikes: blueStrikes || 0,
      redControlTime: redControlTime || '0:00',
      blueControlTime: blueControlTime || '0:00',
      redWinProbability: redWinProbability || 0.5,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    })

    res
      .status(200)
      .json({ success: true, message: 'Telemetry ingested at timecode ' + timecodeMilliseconds })
  } catch (error) {
    console.error('Telemetry Ingestion Error:', error)
    res.status(500).json({ error: 'Internal Server Error' })
  }
})

/**
 * Creates a Stripe Payment Intent for a PPV Event.
 * Called directly from the Flutter app before showing the payment sheet.
 */
exports.createPpvPaymentIntent = functions.https.onCall(async (data, context) => {
  // 1. Verify Authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'You must be logged in to purchase PPV.',
    )
  }

  const uid = context.auth.uid
  const eventId = data.eventId

  if (!eventId) {
    throw new functions.https.HttpsError('invalid-argument', 'Event ID is required.')
  }

  try {
    // 2. Fetch Event Details from Firestore
    const eventDoc = await db.collection('ppv_events').doc(eventId).get()
    if (!eventDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Event not found.')
    }

    const eventData = eventDoc.data()
    const price = eventData.price || 29.99 // Default fallback price
    const amountCents = Math.round(price * 100)
    const currency = eventData.currency || 'aud'

    // 3. Create Stripe Payment Intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountCents,
      currency: currency.toLowerCase(),
      metadata: { userId: uid, eventId: eventId, type: 'ppv_purchase' },
    })

    // 4. Return Client Secret to Flutter
    return { clientSecret: paymentIntent.client_secret }
  } catch (error) {
    console.error('Stripe Payment Intent Error:', error)
    throw new functions.https.HttpsError('internal', 'Failed to initialize payment.')
  }
})

// Mount Content Scoring Engine
const scoringEngine = require('./automation/content_scoring_engine');
exports.scoreNewOrUpdatedPost = scoringEngine.scoreNewOrUpdatedPost;

// Mount Minimal Admin API
exports.adminApi = require('./admin_api').adminApi;

/**
 * Publishes a new item to the global live feed manually or via admin CMS.
 */
exports.publishToFeed = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'You must be logged in to publish.');
  }

  const { type, title, subtitle, imageUrl } = data;

  if (!type || !title) {
    throw new functions.https.HttpsError('invalid-argument', 'Feed item must have a type and title.');
  }

  try {
    const feedItem = {
      type,
      title,
      subtitle: subtitle || '',
      imageUrl: imageUrl || '',
      createdAt: Date.now(), // Saved as epoch ms to match FeedItem.fromDoc
      authorId: context.auth.uid,
    };

    const docRef = await db.collection('feed').add(feedItem);
    return { success: true, id: docRef.id };
  } catch (error) {
    console.error('Error publishing to feed:', error);
    throw new functions.https.HttpsError('internal', 'Failed to publish to feed.');
  }
});

/**
 * Automatically populate the live feed when a new PPV Event is created in Firestore.
 */
exports.onPpvEventCreated = functions.firestore
  .document('ppv_events/{eventId}')
  .onCreate(async (snap, context) => {
    const eventData = snap.data();
    const eventId = context.params.eventId;

    try {
      await db.collection('feed').add({
        type: 'event',
        title: `JUST ANNOUNCED: ${eventData.name || 'New Event'}`,
        subtitle: `Set for ${eventData.city || 'TBA'}. Click to view fight card!`,
        imageUrl: eventData.posterUrl || '',
        createdAt: Date.now(),
        eventId: eventId,
        autoGenerated: true,
      });
      console.log(`Auto-feed item created for event: ${eventId}`);
    } catch (error) {
      console.error('Error auto-populating feed:', error);
    }
  });

/**
 * Stripe Webhook Handler
 * Listens for successful PPV payments and securely writes the user entitlement.
 */
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];
  // Define this in your Firebase environment variables or .env file
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

  let event;

  try {
    // Verify the webhook signature to ensure the request truly came from Stripe
    event = stripe.webhooks.constructEvent(req.rawBody, sig, webhookSecret);
  } catch (err) {
    console.error('Webhook Signature Error:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Listen specifically for successful PaymentIntents
  if (event.type === 'payment_intent.succeeded') {
    const paymentIntent = event.data.object;

    // Extract the metadata we attached in createPpvPaymentIntent
    const { userId, eventId, type } = paymentIntent.metadata || {};

    if (type === 'ppv_purchase' && userId && eventId) {
      try {
        const purchaseId = `${userId}_${eventId}`;

        // Fetch event data to calculate sliding scale splits
        const eventRef = db.collection('ppv_events').doc(eventId);
        const eventDoc = await eventRef.get();
        const eventData = eventDoc.exists ? eventDoc.data() : {};

        const currentBuys = eventData.purchaseCount || 0;
        const promoterId = eventData.promoterId;

        // DFC Promoter Partnership Sliding Scale Calculation
        // 30% - 50% DFC cut based on volume
        const grossCents = paymentIntent.amount;
        const gross = grossCents / 100;
        const stripeFee = (gross * 0.029) + 0.30;
        const net = gross - stripeFee;

        // DFC % starts at 30% and scales up to 50% at 10,000+ buys
        const dfcPercent = 0.30 + (Math.min(currentBuys + 1, 10000) / 10000) * 0.20;
        const dfcCut = net * dfcPercent;
        const promoterCut = net - dfcCut;

        const batch = db.batch();

        // 1. Write the Entitlement record (used by Mux/DRM to grant stream access)
        const entitlementRef = db.collection('entitlements').doc(purchaseId);
        batch.set(entitlementRef, {
          userId,
          eventId,
          purchaseId,
          paymentIntentId: paymentIntent.id,
          hasAccess: true,
          isActive: true,
          status: 'active',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        // 2. Write the PPV Purchase record (for receipts, auditing, and analytics)
        const purchaseRef = db.collection('ppv_purchases').doc(purchaseId);
        batch.set(purchaseRef, {
          userId,
          eventId,
          ppvEventId: eventId,
          promoterId: promoterId || null,
          amountCents: grossCents,
          netRevenueCents: Math.round(net * 100),
          dfcCutCents: Math.round(dfcCut * 100),
          promoterCutCents: Math.round(promoterCut * 100),
          currency: paymentIntent.currency,
          accessGranted: true,
          status: 'completed',
          paymentStatus: 'succeeded',
          paymentIntentId: paymentIntent.id,
          purchasedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        // 3. Increment the event's global purchase count and revenue
        batch.update(eventRef, {
          purchaseCount: admin.firestore.FieldValue.increment(1),
          totalRevenueCents: admin.firestore.FieldValue.increment(grossCents),
          promoterRevenueCents: admin.firestore.FieldValue.increment(Math.round(promoterCut * 100)),
          dfcRevenueCents: admin.firestore.FieldValue.increment(Math.round(dfcCut * 100)),
        });

        // 4. Update Promoter Stats (Residuals/Ledger)
        if (promoterId) {
          const promoterRef = db.collection('promoter_stats').doc(promoterId);
          batch.set(promoterRef, {
            totalBuys: admin.firestore.FieldValue.increment(1),
            totalGrossCents: admin.firestore.FieldValue.increment(grossCents),
            unpaidBalanceCents: admin.firestore.FieldValue.increment(Math.round(promoterCut * 100)),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });
        }

        await batch.commit();
        console.log(`✅ Entitlement & Split granted for User: ${userId}, Event: ${eventId}`);
      } catch (dbError) {
        console.error('Database Error writing entitlement:', dbError);
        return res.status(500).json({ error: 'Database error' });
      }
    }
  }

  // Return a 200 response to acknowledge receipt of the event so Stripe stops retrying
  res.json({ received: true });
});

/**
 * Mux Webhook Handler
 * Automatically transitions stream state from waiting to live (and to replay when idle).
 */
exports.muxWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['mux-signature'];
  const webhookSecret = process.env.MUX_WEBHOOK_SECRET;

  // Verify Mux Signature to ensure authenticity
  try {
    if (webhookSecret && sig) {
      const Mux = require('@mux/mux-node');
      Mux.Webhooks.verifyHeader(req.rawBody, sig, webhookSecret);
    }
  } catch (err) {
    console.error('Mux Webhook Signature Error:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  const event = req.body;
  const type = event.type;

  // In Mux, 'passthrough' is typically used to store internal identifiers
  // We expect passthrough to hold the DFC eventId or streamId
  const eventId = event.data ? event.data.passthrough : null;

  if (!eventId) {
    // Acknowledge events that don't belong to our managed workflow
    return res.status(200).json({ received: true, note: 'No passthrough ID provided.' });
  }

  try {
    const eventRef = db.collection('ppv_events').doc(eventId);

    if (type === 'video.live_stream.active') {
      // Encoder has connected and stream is receiving video data
      await eventRef.update({
        status: 'live',
        actualStart: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`✅ [MUX] Stream for event ${eventId} is now LIVE.`);
    }
    else if (type === 'video.live_stream.idle') {
      // Encoder has disconnected
      await eventRef.update({
        status: 'replay',
        endedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`⏸ [MUX] Stream for event ${eventId} has gone IDLE/REPLAY.`);
    }
    else if (type === 'video.asset.ready') {
      // VOD asset is fully processed and ready for replay
      const playbackIds = event.data.playback_ids;
      if (playbackIds && playbackIds.length > 0) {
        const playbackId = playbackIds[0].id;
        const duration = event.data.duration || 0;

        await eventRef.update({
          replayPlaybackId: playbackId,
          replayUrl: `https://stream.mux.com/${playbackId}.m3u8`,
          durationSeconds: duration,
          vodStatus: 'ready',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`🎬 [MUX] VOD Asset for event ${eventId} is ready for replay.`);
      }
    }

    res.status(200).json({ received: true });
  } catch (err) {
    console.error('Error processing Mux webhook:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});
