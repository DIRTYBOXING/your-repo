// scripts/synthetic_checkout.js
import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import http from 'http';

const args = process.argv.slice(2);
let count = 50;
let reportPath = 'reports/synthetic_checkout_report.json';
let hostUrl = 'http://localhost:4000';

for (const arg of args) {
  if (arg.startsWith('--count=')) {
    count = parseInt(arg.split('=')[1], 10);
  } else if (arg.startsWith('--report=')) {
    reportPath = arg.split('=')[1];
  } else if (arg.startsWith('--host=')) {
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
  console.log(`[synthetic_checkout] Starting ${count} synthetic checkouts against ${hostUrl}...`);
  const results = [];
  let stripeSuccesses = 0;
  let walletSuccesses = 0;

  for (let i = 0; i < count; i++) {
    const userId = `usr_synth_${crypto.randomBytes(4).toString('hex')}`;
    const eventId = Math.floor(Math.random() * 1000) + 1;
    const priceCents = (Math.floor(Math.random() * 5) + 1) * 1000 + 99; // 1099, 2099, 3099, 4099, 5099

    // Alternate between Stripe Checkout and Wallet Purchase
    if (i % 2 === 0) {
      // 💳 Stripe Webhook Simulation
      const sessionId = `cs_synth_${crypto.randomUUID().replace(/-/g, '')}`;
      const stripePayload = {
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

      try {
        const response = await postJson('/api/webhook/payment', stripePayload);
        const success = response.status === 200 && response.body?.ok === true;
        if (success) stripeSuccesses++;
        
        results.push({
          type: 'stripe_webhook',
          userId,
          eventId,
          amountCents: priceCents,
          sessionId,
          status: response.status,
          success,
          error: success ? null : response.body
        });
      } catch (err) {
        results.push({
          type: 'stripe_webhook',
          userId,
          eventId,
          amountCents: priceCents,
          sessionId,
          success: false,
          error: err.message
        });
      }
    } else {
      // 👛 Wallet Purchase Simulation (topup -> confirm -> purchase)
      const topupIdemKey = `idem_topup_${crypto.randomUUID()}`;
      const confirmIdemKey = `idem_confirm_${crypto.randomUUID()}`;
      const purchaseIdemKey = `idem_purchase_${crypto.randomUUID()}`;

      try {
        // 1. Initiate Topup
        const topupRes = await postJson('/api/wallet/topup', {
          userId,
          amountCents: priceCents,
          currency: 'USD',
          provider: 'stripe',
          idempotencyKey: topupIdemKey
        });

        if (topupRes.status !== 200 || !topupRes.body?.transaction) {
          throw new Error(`Wallet topup initiation failed: ${JSON.stringify(topupRes.body)}`);
        }

        const walletTxId = topupRes.body.transaction.id;

        // 2. Confirm Topup
        const confirmRes = await postJson('/api/wallet/topup/confirm', {
          userId,
          walletTxId,
          amountCents: priceCents,
          currency: 'USD',
          provider: 'stripe',
          idempotencyKey: confirmIdemKey,
          status: 'completed'
        });

        if (confirmRes.status !== 200 || confirmRes.body?.ok !== true) {
          throw new Error(`Wallet topup confirmation failed: ${JSON.stringify(confirmRes.body)}`);
        }

        // 3. Purchase PPV Item
        const purchaseRes = await postJson('/api/wallet/purchase', {
          userId,
          itemId: eventId,
          amountCents: priceCents,
          currency: 'USD',
          idempotencyKey: purchaseIdemKey
        });

        const success = purchaseRes.status === 200 && purchaseRes.body?.ok === true;
        if (success) walletSuccesses++;

        results.push({
          type: 'wallet_purchase',
          userId,
          eventId,
          amountCents: priceCents,
          topupTxId: walletTxId,
          status: purchaseRes.status,
          success,
          error: success ? null : purchaseRes.body
        });
      } catch (err) {
        results.push({
          type: 'wallet_purchase',
          userId,
          eventId,
          amountCents: priceCents,
          success: false,
          error: err.message
        });
      }
    }
  }

  const summary = {
    timestamp: new Date().toISOString(),
    totalCount: count,
    stripeSuccesses,
    walletSuccesses,
    failures: count - (stripeSuccesses + walletSuccesses),
    results
  };

  const fullReportPath = path.resolve(reportPath);
  fs.mkdirSync(path.dirname(fullReportPath), { recursive: true });
  fs.writeFileSync(fullReportPath, JSON.stringify(summary, null, 2));

  console.log(`\n[synthetic_checkout] Simulation complete.`);
  console.log(`  - Total attempted: ${count}`);
  console.log(`  - Stripe successes: ${stripeSuccesses}`);
  console.log(`  - Wallet successes: ${walletSuccesses}`);
  console.log(`  - Failures: ${summary.failures}`);
  console.log(`  - Report saved to: ${fullReportPath}\n`);
}

run().catch((err) => {
  console.error('[synthetic_checkout] Fatal execution error:', err);
  process.exit(1);
});
