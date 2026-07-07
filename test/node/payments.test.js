// test/node/payments.test.js
const request = require('supertest');
const express = require('express');
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path');

// Minimal express app for payments endpoints (adjust to your actual app)
const app = express();
app.use(bodyParser.json({ type: 'application/json' }));

// In-memory store for tests
const store = {
  orders: {},
  entitlements: {},
  ledger: {},
  webhooks: {}
};

function nowIso() {
  return new Date().toISOString();
}

// Minimal mock for /payments/webhook and /internal/payments/verify-session
app.post('/payments/webhook', async (req, res) => {
  const event = req.body;
  const eventId = event.id || `evt_${Date.now()}`;
  const type = event.type || 'unknown';

  store.webhooks[eventId] = { eventId, type, rawPayload: event, receivedAt: nowIso(), status: 'processed' };

  if (type === 'checkout.session.completed') {
    const session = event.data?.object || {};
    const sessionId = session.id;
    const userId = session.metadata?.userId || session.metadata?.user_id || 'unknown';
    const productId = session.metadata?.productId || session.metadata?.product_id || 'unknown';
    const amount = (session.amount_total || session.amount || 0) / 100;
    const currency = (session.currency || 'aud').toLowerCase();

    const orderId = `order-${sessionId}`;
    const entitlementId = `ent-${orderId}`;

    store.orders[orderId] = { orderId, checkoutSessionId: sessionId, user_id: userId, product_id: productId, amount, currency, status: 'paid', provider: 'stripe' };
    store.entitlements[entitlementId] = { entitlementId, orderId, user_id: userId, eventId: productId };
    store.ledger[`ledger-${orderId}-sale`] = { entryId: `ledger-${orderId}-sale`, orderId, accountId: 'platform', amount, currency, type: 'sale' };
    store.ledger[`ledger-${orderId}-credit`] = { entryId: `ledger-${orderId}-credit`, orderId, accountId: `creator-${userId}`, amount: Number((amount * 0.95).toFixed(2)), currency, type: 'sale' };
  }

  res.status(200).json({ received: true });
});

app.post('/internal/payments/verify-session', (req, res) => {
  const { checkoutSessionId } = req.body;
  const orderId = `order-${checkoutSessionId}`;
  const entitlementId = `ent-${orderId}`;
  res.status(200).json({ status: 'entitlement_created', orderId, entitlementId });
});

describe('Payments webhook integration (Node)', () => {
  test('checkout.session.completed processes and creates entitlement', async () => {
    const payload = JSON.parse(fs.readFileSync(path.join(__dirname, '../fixtures/webhooks/checkout.session.completed.json')));

    const res = await request(app)
      .post('/payments/webhook')
      .set('Content-Type', 'application/json')
      .send(payload);

    expect(res.statusCode).toBe(200);
    expect(Object.keys(store.orders).length).toBeGreaterThanOrEqual(1);
    expect(Object.keys(store.entitlements).length).toBeGreaterThanOrEqual(1);
    expect(Object.keys(store.ledger).length).toBeGreaterThanOrEqual(2);
  });

  test('idempotent processing: duplicate event ignored', async () => {
    const payload = JSON.parse(fs.readFileSync(path.join(__dirname, '../fixtures/webhooks/checkout.session.completed.json')));

    await request(app).post('/payments/webhook').send(payload);
    const res = await request(app).post('/payments/webhook').send(payload);
    expect(res.statusCode).toBe(200);
    // still one order for that session
    const orders = Object.values(store.orders).filter(o => o.checkoutSessionId === 'cs_test_abc123');
    expect(orders.length).toBe(1);
  });

  test('verify-session endpoint returns entitlement id', async () => {
    const res = await request(app)
      .post('/internal/payments/verify-session')
      .send({ checkoutSessionId: 'cs_test_abc123' });

    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('entitlement_created');
    expect(typeof res.body.orderId).toBe('string');
  });

  test('fixture files load', () => {
    const files = fs.readdirSync(path.join(__dirname, '../fixtures/webhooks'));
    expect(files.length).toBeGreaterThanOrEqual(4);
  });
});
