// backend/payments/webhook_handler.js
// Minimal webhook receiver. Verifies signature (placeholder), persists raw event, and calls verify-session.
const { v4: uuidv4 } = require('uuid');
const { getClient } = require('./db');
const fetch = require('node-fetch');

const VERIFY_ENDPOINT = process.env.VERIFY_ENDPOINT || 'http://localhost:8080/internal/payments/verify-session';

async function persistWebhookEvent(client, eventId, type, rawPayload) {
  const q = `INSERT INTO webhook_events(event_id, type, raw_payload, status, received_at)
             VALUES($1,$2,$3,'pending',NOW())
             ON CONFLICT (event_id) DO NOTHING`;
  await client.query(q, [eventId, type, rawPayload]);
}

// Placeholder signature verification. Replace with provider SDK (Stripe, etc.)
function verifySignature(req) {
  // Example: check header 'x-provider-signature' against WEBHOOK_SECRET
  // For tests, allow bypass if WEBHOOK_SECRET is not set.
  return true;
}

module.exports = async function webhookHandler(req, res) {
  try {
    if (!verifySignature(req)) {
      return res.status(401).send('invalid signature');
    }

    const event = req.body;
    const eventId = event.id || uuidv4();
    const type = event.type || 'unknown';

    const client = getClient();
    await client.connect();
    try {
      await persistWebhookEvent(client, eventId, type, event);
    } finally {
      await client.end();
    }

    // Call internal verify endpoint asynchronously (fire-and-forget)
    const checkoutSessionId = event?.data?.object?.id || event?.data?.object?.payment_intent || null;
    if (checkoutSessionId) {
      const body = { checkoutSessionId, provider: 'stripe', sourceEventId: eventId };
      fetch(VERIFY_ENDPOINT, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) })
        .then(r => console.log(`verify-session responded ${r.status} for event ${eventId}`))
        .catch(err => console.error('verify-session call failed', err));
    }

    return res.status(200).send('received');
  } catch (err) {
    console.error('webhook handler error', err);
    return res.status(500).send('error');
  }
};
