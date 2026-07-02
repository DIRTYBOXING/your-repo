// backend/payments/test/verify_session.test.js
const { expect } = require('chai');
const request = require('supertest');
const app = require('../index'); // index.js exports app
const { getClient } = require('../db');

describe('verify-session integration tests (reference)', function() {
  this.timeout(10000);
  let client;
  before(async () => {
    client = getClient();
    await client.connect();
    // Ensure test tables exist and clean sample rows used by tests
    await client.query("DELETE FROM webhook_events WHERE event_id LIKE 'test_evt_%' OR event_id = 'evt_checkout_completed_001'");
    await client.query("DELETE FROM orders WHERE checkout_session_id LIKE 'cs_test_%'");
    await client.query("DELETE FROM ppv_entitlements WHERE entitlement_id LIKE 'ent_test_%'");
    await client.query("DELETE FROM ledger_entries WHERE entry_id LIKE 'ledger_test_%'");
  });

  after(async () => {
    await client.end();
  });

  it('processes fixture and creates order + entitlement', async () => {
    // Insert a webhook_event fixture row (simulate provider webhook persisted)
    const eventId = 'test_evt_001';
    const raw = require('../test_fixtures/checkout.session.completed.json');
    await client.query('INSERT INTO webhook_events(event_id,type,raw_payload,status,received_at) VALUES($1,$2,$3,$4,NOW()) ON CONFLICT DO NOTHING', [eventId, raw.type, raw.data.object, 'pending']);

    const res = await request(app)
      .post('/internal/payments/verify-session')
      .send({ checkoutSessionId: raw.data.object.id, provider: 'stripe', sourceEventId: eventId });

    expect(res.status).to.equal(200);
    expect(res.body).to.have.property('orderId');
    expect(res.body).to.have.property('entitlementId');
  });
});
