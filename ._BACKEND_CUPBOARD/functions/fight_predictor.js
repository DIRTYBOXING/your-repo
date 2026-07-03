// ═══════════════════════════════════════════════════════════════════════════
// FIGHT PREDICTOR — Cloud Function Wrapper for Predictor Service
// ═══════════════════════════════════════════════════════════════════════════
//
// Thin Cloud Function that:
//   1. Validates input from Flutter app
//   2. Checks feature flag (fightPredictor)
//   3. Forwards to the predictor microservice (services/predictor)
//   4. Caches results in Firestore for re-use
//   5. Falls back to heuristic model if service is down
//
// Callable from Flutter via FirebaseFunctions.instance
// ═══════════════════════════════════════════════════════════════════════════

const { onCall } = require("firebase-functions/v2/https");
const { admin, db, REGION } = require("./config");

const PREDICTOR_URL = process.env.PREDICTOR_URL || "http://localhost:8090";
const CACHE_TTL_MS = 3600_000; // 1 hour

// ═══════════════════════════════════════════════════════════════════════════
// HEURISTIC FALLBACK — When predictor service is unreachable
// ═══════════════════════════════════════════════════════════════════════════

function heuristicPredict(fighterA, fighterB) {
  const aStrength =
    (fighterA.winRate || 0.5) * 0.35 +
    (fighterA.koRate || 0.2) * 0.15 +
    ((fighterA.strikesLandedPerMin || 4) / 10) * 0.15 +
    ((fighterA.takedownsPerFight || 1) / 5) * 0.1 +
    Math.min((fighterA.winStreak || 0) / 10, 1) * 0.1 +
    (1 - Math.max(0, (fighterA.age || 30) - 35) / 10) * 0.05 +
    (((fighterA.reach || 180) - 170) / 40) * 0.1;

  const bStrength =
    (fighterB.winRate || 0.5) * 0.35 +
    (fighterB.koRate || 0.2) * 0.15 +
    ((fighterB.strikesLandedPerMin || 4) / 10) * 0.15 +
    ((fighterB.takedownsPerFight || 1) / 5) * 0.1 +
    Math.min((fighterB.winStreak || 0) / 10, 1) * 0.1 +
    (1 - Math.max(0, (fighterB.age || 30) - 35) / 10) * 0.05 +
    (((fighterB.reach || 180) - 170) / 40) * 0.1;

  const total = aStrength + bStrength || 1;
  let winProb = aStrength / total;
  winProb = Math.max(0.05, Math.min(0.95, winProb));

  // Method split
  const avgKo = ((fighterA.koRate || 0.2) + (fighterB.koRate || 0.2)) / 2;
  const avgSub = ((fighterA.subRate || 0.1) + (fighterB.subRate || 0.1)) / 2;
  const koPct = Math.min(0.6, avgKo * 1.2);
  const subPct = Math.min(0.3, avgSub * 1.0);
  const decPct = Math.max(0.1, 1.0 - koPct - subPct);

  return {
    winProbability: +winProb.toFixed(4),
    method: {
      ko_tko: +koPct.toFixed(3),
      submission: +subPct.toFixed(3),
      decision: +decPct.toFixed(3),
    },
    expectedRounds: decPct > 0.5 ? 3.0 : 2.1,
    confidence: 0.45,
    model: "heuristic_fallback",
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// HTTP Client for Predictor Service
// ═══════════════════════════════════════════════════════════════════════════

async function callPredictorService(fighterA, fighterB, context = {}) {
  // Dynamic import for fetch (Node 18+)
  const response = await fetch(`${PREDICTOR_URL}/predict`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      fighter_a: fighterA,
      fighter_b: fighterB,
      ...context,
    }),
    signal: AbortSignal.timeout(10_000),
  });

  if (!response.ok) {
    throw new Error(`Predictor service returned ${response.status}`);
  }

  return response.json();
}

// ═══════════════════════════════════════════════════════════════════════════
// CALLABLE: Predict Fight Outcome
// ═══════════════════════════════════════════════════════════════════════════

const predictFight = onCall(
  { region: REGION, timeoutSeconds: 30 },
  async (request) => {
    const {
      fighterA,
      fighterB,
      eventId,
      isTitleFight,
      scheduledRounds,
      oddsA,
      oddsB,
    } = request.data || {};

    if (!fighterA || !fighterB) {
      return { error: "fighterA and fighterB profiles are required" };
    }

    // Check feature flag
    const flagDoc = await db
      .collection("feature_flags")
      .doc("fightPredictor")
      .get();
    if (flagDoc.exists && flagDoc.data()?.enabled === false) {
      return { error: "Fight predictor is currently disabled" };
    }

    // Check cache
    const cacheKey = `${fighterA.name || ""}_vs_${fighterB.name || ""}_${eventId || "general"}`;
    const cacheDoc = await db
      .collection("prediction_cache")
      .doc(cacheKey)
      .get();
    if (cacheDoc.exists) {
      const cached = cacheDoc.data();
      const age = Date.now() - (cached.cachedAt?.toDate?.()?.getTime() || 0);
      if (age < CACHE_TTL_MS) {
        return { ...cached.prediction, cached: true };
      }
    }

    // Try predictor service
    let prediction;
    let source = "predictor_service";

    try {
      prediction = await callPredictorService(fighterA, fighterB, {
        is_title_fight: isTitleFight || false,
        scheduled_rounds: scheduledRounds || 3,
        odds_a: oddsA,
        odds_b: oddsB,
      });
    } catch (err) {
      console.warn(
        `[fight-predictor] Service unavailable, using heuristic: ${err.message}`,
      );
      prediction = heuristicPredict(fighterA, fighterB);
      source = "heuristic_fallback";
    }

    // Cache result
    await db
      .collection("prediction_cache")
      .doc(cacheKey)
      .set({
        prediction,
        source,
        eventId: eventId || null,
        fighterAName: fighterA.name || null,
        fighterBName: fighterB.name || null,
        cachedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    // Log for analytics
    await db.collection("prediction_logs").add({
      eventId: eventId || null,
      fighterA: fighterA.name || null,
      fighterB: fighterB.name || null,
      prediction,
      source,
      userId: request.auth?.uid || "anonymous",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { ...prediction, source, cached: false };
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// CALLABLE: Get Live Round Prediction (during active fights)
// ═══════════════════════════════════════════════════════════════════════════

const predictLiveRound = onCall(
  { region: REGION, timeoutSeconds: 15 },
  async (request) => {
    const { fighterA, fighterB, round, scores, eventId } = request.data || {};

    if (!fighterA || !fighterB || !round) {
      return { error: "fighterA, fighterB, and round are required" };
    }

    // Check feature flag
    const flagDoc = await db
      .collection("feature_flags")
      .doc("liveRoundPredictor")
      .get();
    if (!flagDoc.exists || !flagDoc.data()?.enabled) {
      return { error: "Live round predictor is currently disabled" };
    }

    try {
      const response = await fetch(`${PREDICTOR_URL}/predict/live`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          fighter_a: fighterA,
          fighter_b: fighterB,
          current_round: round,
          round_scores: scores || [],
          is_title_fight: request.data.isTitleFight || false,
          scheduled_rounds: request.data.scheduledRounds || 3,
        }),
        signal: AbortSignal.timeout(5_000),
      });

      if (!response.ok) throw new Error(`${response.status}`);
      const result = await response.json();

      // Log live prediction
      await db.collection("live_prediction_logs").add({
        eventId: eventId || null,
        round,
        prediction: result,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return result;
    } catch (err) {
      console.warn(`[fight-predictor] Live prediction failed: ${err.message}`);
      return { error: "Live predictor temporarily unavailable" };
    }
  },
);

module.exports = {
  predictFight,
  predictLiveRound,
};
