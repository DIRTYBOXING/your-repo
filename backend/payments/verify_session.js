// backend/payments/verify_session.js
// Idempotent verify-session implementation.
// Expects { checkoutSessionId, provider, sourceEventId }
const { v4: uuidv4 } = require('uuid');
const { getClient } = require('./db');

async function findWebhookEvent(client, eventId) {
  const r = await client.query('SELECT event_id, status FROM webhook_events WHERE event_id = $1', [eventId]);
  return r.rows[0];
}

async function findOrderByCheckout(client, checkoutSessionId) {
  const r = await client.query('SELECT * FROM orders WHERE checkout_session_id = $1', [checkoutSessionId]);
  return r.rows[0];
}

async function createOrderEntitlementLedger(client, checkoutSessionId, provider, payload) {
  // This function runs inside a transaction.
  // Check again for existing order (idempotency)
  const existing = await client.query('SELECT order_id FROM orders WHERE checkout_session_id = $1 FOR UPDATE', [checkoutSessionId]);
  if (existing.rows.length > 0) {
    return { orderId: existing.rows[0].order_id, created: false };
  }

  // Create order
  const orderId = 'order-' + uuidv4();
  const amount = (payload.amount_total || payload.amount || 0) / 100.0;
  const currency = (payload.currency || 'AUD').toUpperCase();
  const userId = payload?.metadata?.userId || payload?.customer || 'unknown';
  const productId = payload?.metadata?.productId || 'unknown';

  await client.query(
    `INSERT INTO orders(order_id, checkout_session_id, provider_payment_id, user_id, product_id, amount, currency, status, provider, metadata, created_at, updated_at)
     VALUES($1,$2,$3,$4,$5,$6,$7,'paid',$8,$9,NOW(),NOW())`,
    [orderId, checkoutSessionId, payload.payment_intent || payload.charge || null, userId, productId, amount, currency, provider, payload]
  );

  // Create entitlement
  const entitlementId = 'ent-' + uuidv4();
  await client.query(
    `INSERT INTO ppv_entitlements(entitlement_id, order_id, user_id, event_id, valid_from, granted_by, created_at)
     VALUES($1,$2,$3,$4,NOW(),'webhook',NOW())`,
    [entitlementId, orderId, userId, productId]
  );

  // Ledger entries: sale to platform (simple example)
  const entryId = 'ledger-' + uuidv4();
  await client.query(
    `INSERT INTO ledger_entries(entry_id, order_id, account_id, amount, currency, type, metadata, created_at)
     VALUES($1,$2,$3,$4,$5,'sale',$6,NOW())`,
    [entryId, orderId, 'platform', amount, currency, JSON.stringify({ source: 'webhook' })]
  );

  return { orderId, entitlementId, created: true };
}

module.exports = async function verifySessionHandler(req, res) {
  const { checkoutSessionId, provider, sourceEventId } = req.body || {};
  if (!checkoutSessionId) {
    return res.status(400).json({ error: 'missing checkoutSessionId' });
  }

  const client = getClient();
  await client.connect();
  try {
    // Load raw payload from webhook_events if available
    let rawPayload = null;
    if (sourceEventId) {
      const ev = await client.query('SELECT raw_payload, status FROM webhook_events WHERE event_id = $1', [sourceEventId]);
      if (ev.rows.length > 0) {
        rawPayload = ev.rows[0].raw_payload;
      }
    }

    // If no raw payload, attempt to use provider_transactions or other sources (left as TODO)
    const payload = rawPayload || {};

    // Idempotency: if order exists for checkoutSessionId, return existing
    const existingOrder = await findOrderByCheckout(client, checkoutSessionId);
    if (existingOrder) {
      // Mark webhook event processed if present
      if (sourceEventId) {
        await client.query('UPDATE webhook_events SET status = $1, processed_at = NOW() WHERE event_id = $2', ['processed', sourceEventId]);
      }
      return res.status(200).json({ orderId: existingOrder.order_id, status: 'already_exists' });
    }

    // Run creation inside a transaction
    try {
      await client.query('BEGIN');
      const result = await createOrderEntitlementLedger(client, checkoutSessionId, provider || 'stripe', payload);
      if (sourceEventId) {
        await client.query('UPDATE webhook_events SET status = $1, processed_at = NOW() WHERE event_id = $2', ['processed', sourceEventId]);
      }
      await client.query('COMMIT');
      return res.status(200).json({ orderId: result.orderId, entitlementId: result.entitlementId, created: result.created });
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('verify-session transaction failed', err);
      if (sourceEventId) {
        await client.query('UPDATE webhook_events SET status = $1, retry_count = retry_count + 1, last_error = $2 WHERE event_id = $3', ['failed', err.message.slice(0,1000), sourceEventId]);
      }
      return res.status(500).json({ error: 'transaction_failed', message: err.message });
    }
  } finally {
    await client.end();
  }
};
