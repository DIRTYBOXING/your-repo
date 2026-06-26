// ═══════════════════════════════════════════════════════════════════════════
// FIGHTER MICRO-EARNINGS — Instant Revenue Share on Every PPV Transaction
// ═══════════════════════════════════════════════════════════════════════════
//
// When a PPV event is purchased, fighters on the card receive an automatic
// micro-payout to their connected Stripe account.
//
// Revenue Split:
//   DFC Platform Fee: sliding 30-50% (existing getDfcFeePercent)
//   Promoter Share:   remaining after DFC + fighter
//   Fighter Share:    20% of gross (paid first, off the top)
//
// Payout Flow:
//   1. grantPPVAccess fires (webhook after successful payment)
//   2. enqueueFighterEarnings() records earnings to Firestore
//   3. Scheduled processFighterPayouts() batches and transfers via Stripe Connect
//
// Collections:
//   fighter_earnings     → per-transaction ledger entries
//   fighter_wallets      → running balance per fighter
//   fighter_payouts      → completed Stripe Transfer records
//
// ═══════════════════════════════════════════════════════════════════════════

const { onCall } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { admin, db, REGION, stripe } = require("../config");

// Fighter gets 20% of every micro-transaction, off the top
const FIGHTER_SHARE_PERCENT = 0.2;

// Minimum payout threshold in cents (prevent Stripe dust transfers)
const MIN_PAYOUT_CENTS = 500; // $5.00

// ─── Record Fighter Earnings ─────────────────────────────────────────────
// Called internally after PPV access is granted.
// Looks up fights on the event card, splits earnings across fighters.

async function enqueueFighterEarnings({
  ppvId,
  amountCents,
  currency,
  paymentId,
  buyerUserId,
}) {
  if (!ppvId || !amountCents) return;

  try {
    // Look up the event to find fighter IDs on the card
    const eventDoc = await db.collection("ppv_events").doc(ppvId).get();
    if (!eventDoc.exists) {
      console.log(`No ppv_events doc for ${ppvId} — skipping fighter earnings`);
      return;
    }

    const eventData = eventDoc.data();
    const fights = eventData.fights || [];

    // Collect unique fighter IDs from the card
    const fighterIds = new Set();
    for (const fight of fights) {
      if (fight.fighter1Id) fighterIds.add(fight.fighter1Id);
      if (fight.fighter2Id) fighterIds.add(fight.fighter2Id);
      if (fight.redCornerId) fighterIds.add(fight.redCornerId);
      if (fight.blueCornerId) fighterIds.add(fight.blueCornerId);
    }

    if (fighterIds.size === 0) {
      console.log(`No fighters found on card for ${ppvId}`);
      return;
    }

    // Calculate per-fighter share
    const totalFighterPool = Math.round(amountCents * FIGHTER_SHARE_PERCENT);
    const perFighterCents = Math.max(
      1,
      Math.round(totalFighterPool / fighterIds.size),
    );

    const batch = db.batch();
    const timestamp = admin.firestore.FieldValue.serverTimestamp();

    for (const fighterId of fighterIds) {
      // ── Ledger entry (immutable audit trail) ──
      const earningRef = db.collection("fighter_earnings").doc();
      batch.set(earningRef, {
        fighterId,
        ppvId,
        paymentId,
        buyerUserId,
        grossAmountCents: amountCents,
        fighterShareCents: perFighterCents,
        currency: (currency || "AUD").toUpperCase(),
        status: "pending", // pending → batched → transferred
        createdAt: timestamp,
      });

      // ── Update running wallet balance ──
      const walletRef = db.collection("fighter_wallets").doc(fighterId);
      batch.set(
        walletRef,
        {
          fighterId,
          pendingBalanceCents:
            admin.firestore.FieldValue.increment(perFighterCents),
          lifetimeEarningsCents:
            admin.firestore.FieldValue.increment(perFighterCents),
          lastEarningAt: timestamp,
          currency: (currency || "AUD").toUpperCase(),
        },
        { merge: true },
      );
    }

    await batch.commit();
    console.log(
      `Fighter earnings queued: ${fighterIds.size} fighters × ${perFighterCents}c = ${totalFighterPool}c from ${ppvId}`,
    );
  } catch (err) {
    console.error("enqueueFighterEarnings error:", err);
  }
}

// ─── Get Fighter Wallet ──────────────────────────────────────────────────
const getFighterWallet = onCall({ region: REGION }, async (request) => {
  const { fighterId } = request.data;
  if (!fighterId) return { error: "Missing fighterId" };

  try {
    const walletDoc = await db
      .collection("fighter_wallets")
      .doc(fighterId)
      .get();
    if (!walletDoc.exists) {
      return {
        fighterId,
        pendingBalanceCents: 0,
        lifetimeEarningsCents: 0,
        totalPayoutsCents: 0,
        currency: "AUD",
      };
    }
    return walletDoc.data();
  } catch (err) {
    return { error: err.message };
  }
});

// ─── Get Fighter Earnings History ────────────────────────────────────────
const getFighterEarnings = onCall({ region: REGION }, async (request) => {
  const { fighterId, limit: queryLimit } = request.data;
  if (!fighterId) return { error: "Missing fighterId" };

  try {
    const snap = await db
      .collection("fighter_earnings")
      .where("fighterId", "==", fighterId)
      .orderBy("createdAt", "desc")
      .limit(queryLimit || 50)
      .get();

    return {
      earnings: snap.docs.map((d) => ({ id: d.id, ...d.data() })),
      count: snap.size,
    };
  } catch (err) {
    return { error: err.message };
  }
});

// ─── Process Fighter Payouts (Scheduled — runs every 6 hours) ────────────
// Batches pending earnings and transfers to fighter's Stripe Connect account.
const processFighterPayouts = onSchedule(
  {
    schedule: "every 6 hours",
    region: REGION,
    timeoutSeconds: 300,
  },
  async () => {
    console.log("Processing fighter payouts...");

    try {
      // Find wallets with pending balance above threshold
      const walletsSnap = await db
        .collection("fighter_wallets")
        .where("pendingBalanceCents", ">=", MIN_PAYOUT_CENTS)
        .get();

      if (walletsSnap.empty) {
        console.log("No fighter wallets above payout threshold");
        return;
      }

      let payoutsProcessed = 0;
      let totalTransferred = 0;

      for (const walletDoc of walletsSnap.docs) {
        const wallet = walletDoc.data();
        const fighterId = wallet.fighterId;
        const amountCents = wallet.pendingBalanceCents;

        // Look up fighter's Stripe Connect account
        const fighterDoc = await db.collection("fighters").doc(fighterId).get();
        const stripeAccountId = fighterDoc.exists
          ? fighterDoc.data().stripeConnectAccountId
          : null;

        if (!stripeAccountId) {
          console.log(
            `Fighter ${fighterId} has no Stripe Connect account — skipping`,
          );
          continue;
        }

        try {
          // Create Stripe Transfer to fighter's connected account
          const transfer = await stripe.transfers.create({
            amount: amountCents,
            currency: (wallet.currency || "aud").toLowerCase(),
            destination: stripeAccountId,
            description: `DFC Fighter Earnings - ${fighterId}`,
            metadata: {
              fighterId,
              source: "dfc_fighter_micro_earnings",
              pendingBalance: amountCents.toString(),
            },
          });

          // Record payout
          await db.collection("fighter_payouts").add({
            fighterId,
            stripeTransferId: transfer.id,
            stripeAccountId,
            amountCents,
            currency: wallet.currency || "AUD",
            status: "completed",
            processedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // Reset pending balance, increment total payouts
          await walletDoc.ref.update({
            pendingBalanceCents:
              admin.firestore.FieldValue.increment(-amountCents),
            totalPayoutsCents:
              admin.firestore.FieldValue.increment(amountCents),
            lastPayoutAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // Mark individual earnings as transferred
          const earningsSnap = await db
            .collection("fighter_earnings")
            .where("fighterId", "==", fighterId)
            .where("status", "==", "pending")
            .get();

          const earningsBatch = db.batch();
          earningsSnap.docs.forEach((doc) => {
            earningsBatch.update(doc.ref, {
              status: "transferred",
              payoutId: transfer.id,
              transferredAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          });
          await earningsBatch.commit();

          payoutsProcessed++;
          totalTransferred += amountCents;
          console.log(
            `Payout complete: fighter=${fighterId}, amount=${amountCents}c, transfer=${transfer.id}`,
          );
        } catch (transferErr) {
          console.error(
            `Payout failed for fighter ${fighterId}:`,
            transferErr.message,
          );

          await db.collection("fighter_payouts").add({
            fighterId,
            stripeAccountId,
            amountCents,
            currency: wallet.currency || "AUD",
            status: "failed",
            error: transferErr.message,
            processedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      }

      console.log(
        `Fighter payouts complete: ${payoutsProcessed} processed, ${totalTransferred}c transferred`,
      );
    } catch (err) {
      console.error("processFighterPayouts error:", err);
    }
  },
);

module.exports = {
  enqueueFighterEarnings,
  getFighterWallet,
  getFighterEarnings,
  processFighterPayouts,
  FIGHTER_SHARE_PERCENT,
  MIN_PAYOUT_CENTS,
};
