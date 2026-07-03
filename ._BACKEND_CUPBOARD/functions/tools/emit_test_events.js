const admin = require('firebase-admin');
const serviceAccount = require(process.env.SERVICE_ACCOUNT_KEY_PATH || './service-account.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function emit(eventId, payload) {
  await db.collection(`ppv_events/${eventId}/events`).add(payload);
  console.log('emitted', payload.funnel_step);
}

(async () => {
  const eventId = process.argv[2] || 'evt_demo_001';
  await emit(eventId, { funnel_step: 'gate_access_granted', price: 15.25, promoter_id: 'prom_1', fighter_id: 'f_1', timestamp: Date.now() });
  await emit(eventId, { funnel_step: 'watch_start', timestamp: Date.now() });
  setTimeout(async () => {
    const stats = await db.doc(`ppv_events/${eventId}/metrics/live`).get();
    console.log('stats:', stats.data());
    process.exit(0);
  }, 2000);
})();
