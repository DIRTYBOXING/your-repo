import admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp();
}

async function seed() {
  const db = admin.firestore();
  const userId = process.env.SEED_USER_ID || 'demo_user';
  const eventId = process.env.SEED_EVENT_ID || 'demo-eternal-80';
  const purchaseId = `${userId}_${eventId}`;

  await db.collection('ppv_checkout_sessions').doc(purchaseId).set({
    userId,
    eventId,
    ppvId: eventId,
    tierId: 2,
    status: 'completed',
    paymentStatus: 'succeeded',
    amountCents: 2999,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    completedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  await db.collection('entitlements').doc(purchaseId).set({
    userId,
    eventId,
    purchaseId,
    tierId: 2,
    hasAccess: true,
    isActive: true,
    status: 'active',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  await db.collection('ppv_purchases').doc(purchaseId).set({
    userId,
    ppvEventId: eventId,
    eventId,
    tierId: 2,
    accessGranted: true,
    status: 'completed',
    paymentStatus: 'succeeded',
    purchasedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  console.log(`Seeded demo order + entitlement for ${userId} on ${eventId}.`);
}

try {
  await seed();
  process.exit(0);
} catch (error) {
  console.error(error);
  process.exit(1);
}
