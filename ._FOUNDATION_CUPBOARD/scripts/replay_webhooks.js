// scripts/replay_webhooks.js
import crypto from 'crypto';
import http from 'http';

const args = process.argv.slice(2);
let hostUrl = 'http://localhost:4000';

for (const arg of args) {
  if (arg.startsWith('--host=')) {
    hostUrl = arg.split('=')[1];
  }
}

const parsedUrl = new URL(hostUrl);
const requestConfig = {
  host: parsedUrl.hostname,
  port: parsedUrl.port || (parsedUrl.protocol === 'https:' ? 443 : 80),
};

function postJson(urlPath, body, headers = {}) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(body);
    const req = http.request({
      ...requestConfig,
      path: urlPath,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
        ...headers
      }
    }, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve({ status: res.statusCode, body: parsed });
        } catch {
          resolve({ status: res.statusCode, body: data });
        }
      });
    });

    req.on('error', (err) => { reject(err); });
    req.write(postData);
    req.end();
  });
}

async function run() {
  console.log(`[replay_webhooks] Targeting running server at ${hostUrl}...`);
  
  const userId = `usr_replay_${crypto.randomBytes(4).toString('hex')}`;
  const eventId = 999;
  const sessionId = `cs_replay_${crypto.randomUUID().replace(/-/g, '')}`;
  const priceCents = 4999;

  const webhookPayload = {
    type: 'checkout.session.completed',
    data: {
      object: {
        id: sessionId,
        amount_total: priceCents,
        payment_status: 'paid',
        metadata: {
          eventId: String(eventId),
          userId: userId,
          sku: `PPV-${eventId}`
        }
      }
    }
  };

  console.log(`\n1. Sending webhook payload (First Time)...`);
  const res1 = await postJson('/api/webhook/payment', webhookPayload);
  console.log(`   Response status: ${res1.status}`);
  console.log(`   Response body:`, res1.body);

  if (res1.status !== 200) {
    console.error(`[replay_webhooks] First webhook call failed. Cannot proceed.`);
    process.exit(1);
  }

  console.log(`\n2. Sending duplicate webhook payload (Second Time / Replay)...`);
  const res2 = await postJson('/api/webhook/payment', webhookPayload);
  console.log(`   Response status: ${res2.status}`);
  console.log(`   Response body:`, res2.body);

  console.log(`\n3. Running on-demand financial reconciliation audit...`);
  const reconRes = await postJson('/api/admin/reconciliation/run', {});
  console.log(`   Reconciliation Status: ${reconRes.status}`);
  
  const summary = reconRes.body?.summary || {};
  const mismatches = reconRes.body?.mismatches || [];
  
  console.log(`\n--- Audit Results ---`);
  console.log(`Total Accounts Checked: ${summary.accountsChecked}`);
  console.log(`Total Mismatch Count: ${summary.mismatchCount}`);
  
  const userMismatch = mismatches.find(m => m.userId === userId);
  
  if (userMismatch) {
    console.log(`\n❌ TEST FAILED: Idempotency violation detected!`);
    console.log(`   User ${userId} has a reconciliation discrepancy.`);
    console.log(`   Purchase Total Cents: ${userMismatch.purchaseTotalCents}`);
    console.log(`   Wallet Spend Cents: ${userMismatch.walletSpendCents}`);
    console.log(`   Discrepancy: ${userMismatch.discrepancyCents} cents`);
    process.exit(1);
  } else {
    console.log(`\n✅ TEST PASSED: Stripe Webhook handler is fully idempotent.`);
    console.log(`   Replayed webhooks did not cause duplicate purchase records.`);
  }
}

run().catch((err) => {
  console.error('[replay_webhooks] Fatal execution error:', err);
  process.exit(1);
});
