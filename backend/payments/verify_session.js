// backend/payments/verify_session.js
// Idempotent verify-session implementation.
// Expects { checkoutSessionId, provider, sourceEventId }
const { v4: uuidv4 } = require('uuid');
const { getClient } = require('./db');

async function findOrderByCheckout(client, checkoutSessionId) {
  const r = await client.query('SELECT * FROM orders WHERE checkout_session_id = $1', [checkoutSessionId]);
  return r.rows[0];
}

function normalizePayload(rawPayload) {
  if (!rawPayload || typeof rawPayload !== 'object') {
    return {};
  }

  // Some pipelines store full provider event, others store only data.object.
  if (rawPayload?.data?.object) {
    return rawPayload.data.object;
  }

  return rawPayload;
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
  const amount = (payload.amount_total || payload.amount || 0) / 100;
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

async function markWebhookProcessed(client, sourceEventId) {
  if (!sourceEventId) {
    return;
  }

  await client.query(
    'UPDATE webhook_events SET status = $1, processed_at = NOW() WHERE event_id = $2',
    ['processed', sourceEventId],
  );
}

async function markWebhookFailed(client, sourceEventId, errorMessage) {
  if (!sourceEventId) {
    return;
  }

  await client.query(
    'UPDATE webhook_events SET status = $1, retry_count = retry_count + 1, last_error = $2 WHERE event_id = $3',
    ['failed', String(errorMessage || 'unknown error').slice(0, 1000), sourceEventId],
  );
}

async function processVerifySession(client, body) {
  const { checkoutSessionId, provider, sourceEventId } = body || {};

  if (!checkoutSessionId) {
    return { statusCode: 400, body: { error: 'missing checkoutSessionId' } };
  }

  // Load raw payload from webhook_events if available.
  let payload = {};
  if (sourceEventId) {
    const ev = await client.query('SELECT raw_payload, status FROM webhook_events WHERE event_id = $1', [sourceEventId]);
    if (ev.rows.length > 0) {
      payload = normalizePayload(ev.rows[0].raw_payload);
    }
  }

  // Optional direct payload for internal replay callers.
  if ((!payload || Object.keys(payload).length === 0) && body?.payload && typeof body.payload === 'object') {
    payload = normalizePayload(body.payload);
  }

  const existingOrder = await findOrderByCheckout(client, checkoutSessionId);
  if (existingOrder) {
    await markWebhookProcessed(client, sourceEventId);
    return { statusCode: 200, body: { orderId: existingOrder.order_id, status: 'already_exists' } };
  }

  try {
    await client.query('BEGIN');
    const result = await createOrderEntitlementLedger(client, checkoutSessionId, provider || 'stripe', payload || {});
    await markWebhookProcessed(client, sourceEventId);
    await client.query('COMMIT');
    return {
      statusCode: 200,
      body: {
        orderId: result.orderId,
        entitlementId: result.entitlementId,
        created: result.created,
      },
    };
  } catch (err) {
    await client.query('ROLLBACK');
    await markWebhookFailed(client, sourceEventId, err?.message);
    return { statusCode: 500, body: { error: 'transaction_failed', message: err.message } };
  }
}

module.exports = async function verifySessionHandler(req, res) {
  const client = getClient();
  await client.connect();
  try {
    const result = await processVerifySession(client, req.body || {});
    return res.status(result.statusCode).json(result.body);
  } finally {
    await client.end();
  }
};

module.exports._private = {
  normalizePayload,
  processVerifySession,
};
