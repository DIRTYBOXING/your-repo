// test/payments.test.js
const fs = require('fs');
const path = require('path');
const { verifySession, recordWebhookEvent } = require('../backend/payments/verify_session.js');

// Minimal in-memory mock DB layer for offline tests
const memory = {
  orders: {},
  entitlements: {},
  ledger: {},
  providerTx: {},
  webhooks: {}
};

function mockDb() {
  return {
    query: async (sql, params) => {
      // very small parser for the SQL used in verify_session.js
      const s = sql.trim().toLowerCase();
      if (s.includes('insert into orders')) {
        const [orderId, checkoutSessionId, providerPaymentId, user_id, product_id, amount, currency, status, provider, metadata] = params;
        memory.orders[orderId] = { orderId, checkoutSessionId, providerPaymentId, user_id, product_id, amount, currency, status, provider, metadata };
        return { rows: [] };
      }
      if (s.includes('select') && s.includes('from orders') && s.includes('checkout_session_id')) {
        const row = Object.values(memory.orders).find(o => o.checkoutSessionId === params[0]);
        return { rows: row ? [row] : [] };
      }
      if (s.includes('insert into ppv_entitlements')) {
        const [entitlementId, orderId, userId, eventId, validFrom, validUntil, grantedBy] = params;
        memory.entitlements[entitlementId] = { entitlementId, orderId, userId, eventId, validFrom, validUntil, grantedBy };
        return { rows: [] };
      }
      if (s.includes('insert into ledger_entries')) {
        const [entryId, orderId, accountId, amount, currency, type, metadata] = params;
        memory.ledger[entryId] = { entryId, orderId, accountId, amount, currency, type, metadata };
        return { rows: [] };
      }
      if (s.includes('insert into provider_transactions')) {
        const [providerTxId, provider, amount, currency, status, rawPayload] = params;
        memory.providerTx[providerTxId] = { providerTxId, provider, amount, currency, status, rawPayload };
        return { rows: [] };
      }
      if (s.startsWith('insert into webhook_events')) {
        const [eventId, type, rawPayload, status, processedAt] = params;
        memory.webhooks[eventId] = { eventId, type, rawPayload, status, processedAt };
        return { rows: [] };
      }
      return { rows: [] };
    }
  };
}

// Override getClient for test
const { getClient: origGetClient } = require('../backend/payments/verify_session.js');

describe('Payments verify-session (offline, mocked DB)', () => {
  beforeAll(() => {
    // Not replacing module getClient globally here; these tests are intended as integration skeletons.
    // Run against a test DB with migrations applied for real assertions.
  });

  test('fixture files load', () => {
    const fixtureDir = path.join(__dirname, 'fixtures', 'webhooks');
    const files = fs.readdirSync(fixtureDir);
    expect(files.length).toBeGreaterThanOrEqual(4);
  });
});
