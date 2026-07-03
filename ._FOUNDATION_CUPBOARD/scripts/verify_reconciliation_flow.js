// scripts/verify_reconciliation_flow.js
import { fork } from 'child_process';
import crypto from 'crypto';
import http from 'http';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const serverPath = path.resolve(__dirname, '../server/index.js');

const host = 'localhost';
const port = 4000;

function postJson(urlPath, body) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(body);
    const req = http.request({
      host,
      port,
      path: urlPath,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
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

async function runTests() {
  console.log('\n======================================================');
  console.log('🚀 RUNNING DFC PAYMENT RECONCILIATION & INTEGRITY SUITE');
  console.log('======================================================\n');

  let passed = true;

  // 1. Synthetic Checkouts Test
  console.log('--- Test 1: Running Synthetic Checkouts (Stripe and Wallet) ---');
  const count = 10;
  let successfulCheckouts = 0;

  for (let i = 0; i < count; i++) {
    const userId = `usr_test_${crypto.randomBytes(3).toString('hex')}`;
    const eventId = Math.floor(Math.random() * 100) + 1;
    const priceCents = 2999;

    if (i % 2 === 0) {
      // Stripe checkout sessioncompleted
      const sessionId = `cs_test_${crypto.randomUUID().replace(/-/g, '')}`;
      const payload = {
        type: 'checkout.session.completed',
        data: {
          object: {
            id: sessionId,
            amount_total: priceCents,
            payment_status: 'paid',
            metadata: { eventId: String(eventId), userId, sku: `PPV-${eventId}` }
          }
        }
      };
      const res = await postJson('/api/webhook/payment', payload);
      if (res.status === 200 && res.body?.ok === true) {
        successfulCheckouts++;
      }
    } else {
      // Wallet purchase (topup -> confirm -> purchase)
      const topupIdem = `idem_topup_${crypto.randomUUID()}`;
      const confirmIdem = `idem_confirm_${crypto.randomUUID()}`;
      const purchaseIdem = `idem_purchase_${crypto.randomUUID()}`;

      try {
        const topupRes = await postJson('/api/wallet/topup', {
          userId,
          amountCents: priceCents,
          currency: 'USD',
          idempotencyKey: topupIdem
        });
        const walletTxId = topupRes.body.walletTxId || topupRes.body.transaction?.id;

        await postJson('/api/wallet/topup/confirm', {
          userId,
          walletTxId,
          amountCents: priceCents,
          currency: 'USD',
          idempotencyKey: confirmIdem
        });

        const purchaseRes = await postJson('/api/wallet/purchase', {
          userId,
          itemId: eventId,
          amountCents: priceCents,
          idempotencyKey: purchaseIdem
        });

        if (purchaseRes.status === 200 && purchaseRes.body?.ok === true) {
          successfulCheckouts++;
        }
      } catch (err) {
        console.error('Wallet checkout flow error:', err.message);
      }
    }
  }

  console.log(`📊 Checkouts completed: ${successfulCheckouts}/${count} successful.`);
  if (successfulCheckouts !== count) {
    console.log('❌ Test 1 Failed: Some checkouts did not succeed.');
    passed = false;
  } else {
    console.log('✅ Test 1 Passed: Synthetic checkouts processed successfully.');
  }

  console.log('\n------------------------------------------------------\n');

  // 2. Webhook Replay Idempotency Test
  console.log('--- Test 2: Webhook Replay & Idempotency Check ---');
  const replayUserId = `usr_replay_${crypto.randomBytes(3).toString('hex')}`;
  const replayEventId = 555;
  const replaySessionId = `cs_replay_${crypto.randomUUID().replace(/-/g, '')}`;
  const replayPrice = 4999;

  const replayPayload = {
    type: 'checkout.session.completed',
    data: {
      object: {
        id: replaySessionId,
        amount_total: replayPrice,
        payment_status: 'paid',
        metadata: { eventId: String(replayEventId), userId: replayUserId, sku: `PPV-${replayEventId}` }
      }
    }
  };

  console.log('Sending webhook notification (1st Time)...');
  const res1 = await postJson('/api/webhook/payment', replayPayload);
  console.log(`Response 1: status=${res1.status}, ok=${res1.body?.ok}`);

  console.log('Sending replayed webhook notification (2nd Time)...');
  const res2 = await postJson('/api/webhook/payment', replayPayload);
  console.log(`Response 2: status=${res2.status}, ok=${res2.body?.ok}, replayed=${res2.body?.replayed}`);

  if (res2.status === 200 && res2.body?.replayed === true) {
    console.log('✅ Test 2 Passed: Webhook handler detected replay and returned existing transaction.');
  } else {
    console.log('❌ Test 2 Failed: Webhook handler did not mark the transaction as replayed/idempotent.');
    passed = false;
  }

  console.log('\n------------------------------------------------------\n');

  // 3. Reconciliation Check
  console.log('--- Test 3: Running Financial Reconciliation Audit ---');
  const reconRes = await postJson('/api/admin/reconciliation/run', {});
  const summary = reconRes.body?.summary || {};
  const mismatches = reconRes.body?.mismatches || [];

  console.log(`Accounts checked: ${summary.accountsChecked}`);
  console.log(`Mismatches flagged: ${summary.mismatchCount}`);

  if (summary.mismatchCount === 0) {
    console.log('✅ Test 3 Passed: 0 financial discrepancies found across all transactions.');
  } else {
    console.log(`❌ Test 3 Failed: Flagged ${summary.mismatchCount} mismatches in the ledger.`);
    console.log('Mismatches details:', JSON.stringify(mismatches, null, 2));
    passed = false;
  }

  console.log('\n======================================================');
  if (passed) {
    console.log('🎉 ALL INTEGRITY TESTS PASSED SUCCESSFULLY! CHAMPION READY.');
  } else {
    console.log('🛑 INTEGRITY SUITE DETECTED AUDIT GAPS OR FAILURE SCENARIOS.');
  }
  console.log('======================================================\n');

  return passed;
}

// Start the verification
console.log('[verify_reconciliation_flow] Spawning control API server on port 4000...');
const serverProcess = fork(serverPath, [], { stdio: 'inherit' });

// Wait 2.5 seconds for the server to bind and listen
setTimeout(async () => {
  try {
    const success = await runTests();
    serverProcess.kill();
    process.exit(success ? 0 : 1);
  } catch (err) {
    console.error('Fatal execution error:', err);
    serverProcess.kill();
    process.exit(1);
  }
}, 2500);
