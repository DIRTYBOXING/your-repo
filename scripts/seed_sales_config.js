import admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp();
}

async function seed() {
  const db = admin.firestore();
  const tiers = [
    {
      id: 'starter',
      name: 'Starter',
      rate_key: 'RATE_STARTER',
      criteria: { audience_threshold: 'ENV_OR_ADMIN', viral_flag: false },
    },
    {
      id: 'growth',
      name: 'Growth',
      rate_key: 'RATE_GROWTH',
      criteria: { audience_threshold: 'ENV_OR_ADMIN', viral_flag: 'ENV_OR_ADMIN' },
    },
    {
      id: 'global',
      name: 'Global',
      rate_key: 'RATE_GLOBAL',
      criteria: { audience_threshold: 'ENV_OR_ADMIN', viral_flag: true },
    },
  ];

  for (const tier of tiers) {
    await db.doc(`config/contract_tiers/tiers/${tier.id}`).set(tier, { merge: true });
  }

  await db.doc('config/sales_promotions').set({
    promotions: [
      {
        id: 'promo-ppv',
        title: 'Event PPV',
        type: 'ppv_full_show',
        active: true,
        requiresReview: true,
        reviewStatus: 'pending',
      },
      {
        id: 'promo-highlight',
        title: 'Highlight Pack',
        type: 'highlight_pack',
        active: true,
        requiresReview: true,
        reviewStatus: 'pending',
      },
    ],
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  console.log('Seeded contract tiers into config/contract_tiers/tiers.');
  console.log('Seeded sales promotion review config into config/sales_promotions.');
  console.log('Set numeric rate keys (RATE_STARTER/RATE_GROWTH/RATE_GLOBAL) in admin/settings separately.');
}

try {
  await seed();
  process.exit(0);
} catch (err) {
  console.error(err);
  process.exit(1);
}
