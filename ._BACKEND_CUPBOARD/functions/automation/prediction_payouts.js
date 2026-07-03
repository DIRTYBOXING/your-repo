// ═══════════════════════════════════════════════════════════════════════════
// DFC PREDICTION PAYOUT ENGINE
// ═══════════════════════════════════════════════════════════════════════════
//
// Two-phase system:
//
// PHASE 1: COLLECT — submitPrediction (callable)
//   Users submit their Adrenaline Gate predictions via the Flutter widget.
//   Stored in ppv_events/{ppvId}/predictions/{userId}.
//
// PHASE 2: SETTLE — onEventComplete (Firestore trigger)
//   When a PPV event transitions to 'replay' (or a manual 'complete' flag),
//   this reads the event's actual results, scores every prediction,
//   and awards DFC Credits to winners via credit_wallets atomic writes.
//
// Firestore:
//   ppv_events/{ppvId}/predictions/{userId}  — prediction doc
//   ppv_events/{ppvId}/results               — official fight results (manual)
//   credit_wallets/{userId}                  — balance incremented on win
//   credit_wallets/{userId}/transactions     — payout ledger entry
//   prediction_payouts/{ppvId}               — aggregate payout summary
//
// ═══════════════════════════════════════════════════════════════════════════

const { onCall } = require("firebase-functions/v2/https");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { admin, db, REGION } = require("../config");

// ═══════════════════════════════════════════════════════════════════════════
// CREDIT REWARD TIERS — How many credits per correct answer
// ═══════════════════════════════════════════════════════════════════════════

const REWARDS = {
  perCorrectAnswer: 10, // 10 DFC Credits per correct answer
  perfectBonus: 25, // bonus for getting ALL questions right
  maxCreditsPerEvent: 55, // 3 × 10 + 25 = 55 max
};

// ═══════════════════════════════════════════════════════════════════════════
// PHASE 1: SUBMIT PREDICTION (Callable)
// ═══════════════════════════════════════════════════════════════════════════
//
// Called from AdrenalineGateQuiz widget.
// Payload: { ppvId, ppvTitle, answers: { 0: "Fighter A", 1: "Yes", 2: "KO / TKO" } }
//
const submitPrediction = onCall({ region: REGION }, async (request) => {
  // Auth check
  if (!request.auth) {
    return { error: "Authentication required" };
  }

  const userId = request.auth.uid;
  const { ppvId, ppvTitle, answers } = request.data;

  if (!ppvId || !answers || typeof answers !== "object") {
    return { error: "ppvId and answers are required" };
  }

  // Check event exists and is still accepting predictions (must be before live)
  const eventDoc = await db.collection("ppv_events").doc(ppvId).get();
  if (!eventDoc.exists) {
    return { error: "Event not found" };
  }

  const eventData = eventDoc.data();
  const status = eventData.status || "";
  if (["live", "replay", "expired", "complete"].includes(status)) {
    return { error: "Predictions are closed — event has already started" };
  }

  // Check for duplicate submission
  const predRef = db
    .collection("ppv_events")
    .doc(ppvId)
    .collection("predictions")
    .doc(userId);

  const existing = await predRef.get();
  if (existing.exists) {
    return { error: "You already submitted a prediction for this event" };
  }

  // Write prediction
  await predRef.set({
    userId,
    ppvId,
    ppvTitle: ppvTitle || eventData.title || "",
    answers, // { 0: "Fighter A", 1: "Yes", 2: "KO / TKO" }
    submittedAt: admin.firestore.FieldValue.serverTimestamp(),
    scored: false,
    correctCount: 0,
    creditsAwarded: 0,
  });

  // Increment prediction counter on event
  await db
    .collection("ppv_events")
    .doc(ppvId)
    .update({
      predictionCount: admin.firestore.FieldValue.increment(1),
    })
    .catch(() => {});

  console.log(`[Predictions] User ${userId} submitted prediction for ${ppvId}`);

  return {
    status: "ok",
    message: "Prediction locked in! Results will be scored after the event.",
  };
});

// ═══════════════════════════════════════════════════════════════════════════
// PHASE 2: SCORE & PAY OUT (Firestore Trigger)
// ═══════════════════════════════════════════════════════════════════════════
//
// Fires when ppv_events/{ppvId} is updated.
// Triggers on:
//   - resultsPublished == true (set manually or by pipeline after event ends)
//
// The event doc must have a `results` map:
//   results: { 0: "Fighter B", 1: "No - Early Finish", 2: "KO / TKO" }
// (Keys match the Adrenaline Gate question indices)
//
const onResultsPublished = onDocumentUpdated(
  {
    document: "ppv_events/{ppvId}",
    region: REGION,
  },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const ppvId = event.params.ppvId;

    // Only fire when resultsPublished flips from false/undefined to true
    if (before.resultsPublished === true) return;
    if (after.resultsPublished !== true) return;

    const results = after.results;
    if (!results || typeof results !== "object") {
      console.error(
        `[Predictions] resultsPublished=true but no results map on ${ppvId}`,
      );
      return;
    }

    console.log(`[Predictions] Scoring predictions for ${ppvId}...`);

    // Fetch all predictions for this event
    const predsSnap = await db
      .collection("ppv_events")
      .doc(ppvId)
      .collection("predictions")
      .where("scored", "==", false)
      .get();

    if (predsSnap.empty) {
      console.log(`[Predictions] No unscored predictions for ${ppvId}`);
      return;
    }

    const title = after.title || after.name || "PPV Event";
    let totalScored = 0;
    let totalCreditsAwarded = 0;
    let perfectCount = 0;

    // Process in batches of 500 (Firestore batch limit)
    const predictions = predsSnap.docs;
    for (let i = 0; i < predictions.length; i += 400) {
      const chunk = predictions.slice(i, i + 400);
      const batch = db.batch();

      for (const predDoc of chunk) {
        const pred = predDoc.data();
        const answers = pred.answers || {};

        // Score each answer
        let correctCount = 0;
        const resultKeys = Object.keys(results);
        for (const key of resultKeys) {
          if (answers[key] === results[key]) {
            correctCount++;
          }
        }

        // Calculate credits
        let credits = correctCount * REWARDS.perCorrectAnswer;
        const isPerfect =
          correctCount === resultKeys.length && resultKeys.length > 0;
        if (isPerfect) {
          credits += REWARDS.perfectBonus;
          perfectCount++;
        }

        // Update prediction doc with score
        batch.update(predDoc.ref, {
          scored: true,
          correctCount,
          totalQuestions: resultKeys.length,
          isPerfect,
          creditsAwarded: credits,
          scoredAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Award credits to user's wallet (if any earned)
        if (credits > 0) {
          const walletRef = db.collection("credit_wallets").doc(pred.userId);

          // Increment balance
          batch.set(
            walletRef,
            {
              balance: admin.firestore.FieldValue.increment(credits),
              totalEarned: admin.firestore.FieldValue.increment(credits),
              lastEarnedAt: admin.firestore.FieldValue.serverTimestamp(),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true },
          );

          // Write transaction ledger entry
          const txRef = walletRef.collection("transactions").doc();
          batch.set(txRef, {
            type: "prediction_payout",
            amount: credits,
            direction: "credit",
            description: isPerfect
              ? `🏆 Perfect prediction — ${title} (+${REWARDS.perfectBonus} bonus!)`
              : `🎯 ${correctCount}/${resultKeys.length} correct — ${title}`,
            ppvId,
            eventTitle: title,
            correctCount,
            totalQuestions: resultKeys.length,
            isPerfect,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          totalCreditsAwarded += credits;
        }

        totalScored++;
      }

      await batch.commit();
      console.log(
        `[Predictions] Batch scored: ${chunk.length} predictions (offset ${i})`,
      );
    }

    // Write aggregate payout summary
    await db.collection("prediction_payouts").doc(ppvId).set({
      ppvId,
      eventTitle: title,
      totalPredictions: totalScored,
      totalCreditsAwarded,
      perfectPredictions: perfectCount,
      resultsUsed: results,
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update event doc
    await db
      .collection("ppv_events")
      .doc(ppvId)
      .update({
        predictionsScored: true,
        predictionsScoredAt: admin.firestore.FieldValue.serverTimestamp(),
        totalPredictionsScored: totalScored,
        totalPredictionCreditsAwarded: totalCreditsAwarded,
        perfectPredictionCount: perfectCount,
      })
      .catch(() => {});

    console.log(
      `[Predictions] ✅ Scored ${totalScored} predictions for ${ppvId}: ` +
        `${totalCreditsAwarded} credits awarded, ${perfectCount} perfect scores`,
    );
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// EXPORTS
// ═══════════════════════════════════════════════════════════════════════════
module.exports = {
  submitPrediction,
  onResultsPublished,
};
