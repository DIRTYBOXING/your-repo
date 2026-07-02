// backend/payments/test/verify_session.unit.test.js
const { expect } = require('chai');

const verifyModule = require('../verify_session');
const { processVerifySession, normalizePayload } = verifyModule._private;

class FakeClient {
  constructor({ existingOrder = null, shouldFailCreate = false } = {}) {
    this.existingOrder = existingOrder;
    this.shouldFailCreate = shouldFailCreate;
    this.rowsByEvent = new Map();
    this.queries = [];
  }

  setWebhookEvent(eventId, rawPayload) {
    this.rowsByEvent.set(eventId, { raw_payload: rawPayload, status: 'pending' });
  }

  async query(sql, params = []) {
    this.queries.push({ sql, params });

    if (sql.includes('SELECT raw_payload, status FROM webhook_events')) {
      const eventId = params[0];
      const row = this.rowsByEvent.get(eventId);
      return { rows: row ? [row] : [] };
    }

    if (sql.includes('SELECT * FROM orders WHERE checkout_session_id = $1')) {
      return { rows: this.existingOrder ? [this.existingOrder] : [] };
    }

    if (sql.includes('SELECT order_id FROM orders WHERE checkout_session_id = $1 FOR UPDATE')) {
      return { rows: this.existingOrder ? [this.existingOrder] : [] };
    }

    if (sql.includes('INSERT INTO orders(')) {
      if (this.shouldFailCreate) {
        throw new Error('insert failed');
      }
      this.existingOrder = { order_id: params[0], checkout_session_id: params[1] };
      return { rows: [] };
    }

    return { rows: [] };
  }
}

describe('verify-session unit behavior', () => {
  it('returns 400 when checkoutSessionId is missing', async () => {
    const fake = new FakeClient();
    const result = await processVerifySession(fake, {});
    expect(result.statusCode).to.equal(400);
    expect(result.body.error).to.equal('missing checkoutSessionId');
  });

  it('returns already_exists for pre-existing order (idempotent)', async () => {
    const fake = new FakeClient({ existingOrder: { order_id: 'order-existing-1' } });

    const result = await processVerifySession(fake, {
      checkoutSessionId: 'cs_test_1',
      provider: 'stripe',
      sourceEventId: 'evt_1',
    });

    expect(result.statusCode).to.equal(200);
    expect(result.body.status).to.equal('already_exists');
    expect(result.body.orderId).to.equal('order-existing-1');

    const processedUpdate = fake.queries.find((q) => q.sql.includes('UPDATE webhook_events SET status = $1'));
    expect(processedUpdate).to.not.equal(undefined);
  });

  it('creates records for first-time checkout', async () => {
    const fake = new FakeClient();
    fake.setWebhookEvent('evt_2', {
      id: 'evt_2',
      type: 'checkout.session.completed',
      data: {
        object: {
          id: 'cs_test_2',
          amount_total: 2500,
          currency: 'aud',
          metadata: { userId: 'user-a', productId: 'ppv-101' },
          payment_intent: 'pi_123',
        },
      },
    });

    const result = await processVerifySession(fake, {
      checkoutSessionId: 'cs_test_2',
      provider: 'stripe',
      sourceEventId: 'evt_2',
    });

    expect(result.statusCode).to.equal(200);
    expect(result.body.created).to.equal(true);
    expect(result.body.orderId).to.match(/^order-/);
    expect(result.body.entitlementId).to.match(/^ent-/);
  });

  it('rolls back and reports transaction failure', async () => {
    const fake = new FakeClient({ shouldFailCreate: true });

    const result = await processVerifySession(fake, {
      checkoutSessionId: 'cs_test_3',
      provider: 'stripe',
      sourceEventId: 'evt_3',
      payload: {
        amount_total: 500,
        metadata: { userId: 'user-b', productId: 'ppv-303' },
      },
    });

    expect(result.statusCode).to.equal(500);
    expect(result.body.error).to.equal('transaction_failed');

    const rollback = fake.queries.find((q) => q.sql === 'ROLLBACK');
    expect(rollback).to.not.equal(undefined);
  });

  it('normalizes both full event and raw object payloads', () => {
    const fullEvent = {
      data: {
        object: { id: 'cs_test_4', amount_total: 700 },
      },
    };
    const rawObject = { id: 'cs_test_5', amount_total: 800 };

    const p1 = normalizePayload(fullEvent);
    const p2 = normalizePayload(rawObject);

    expect(p1.id).to.equal('cs_test_4');
    expect(p2.id).to.equal('cs_test_5');
  });
});
