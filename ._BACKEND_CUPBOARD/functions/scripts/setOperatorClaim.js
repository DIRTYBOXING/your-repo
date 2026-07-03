const admin = require('firebase-admin');
const serviceAccount = require(process.env.SERVICE_ACCOUNT_KEY_PATH || './service-account.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

async function setClaim(uid) {
  await admin.auth().setCustomUserClaims(uid, { operator: true });
  console.log('Operator claim set for', uid);
}

const uid = process.argv[2];
if (!uid) { console.error('Usage: node setOperatorClaim.js <uid>'); process.exit(1); }
setClaim(uid).catch(e => { console.error(e); process.exit(1); });
