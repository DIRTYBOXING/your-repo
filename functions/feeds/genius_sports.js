// ═══════════════════════════════════════════════════════════════════════════
// DFC GENIUS SPORTS INTEGRATION — Live Data Pipeline Scaffold
// ═══════════════════════════════════════════════════════════════════════════
//
// PURPOSE: Connects DFC bots (AIRefereeAssistant, AIPredictiveBetting,
//          FightWire Feed) to Genius Sports' real-time fight data.
//
// HOW IT WORKS:
//   1. Authenticate via OAuth2 client_credentials grant
//   2. Subscribe to Ably channels for live "Updategram" messages
//   3. Parse match events and write to Firestore for bot consumption
//
// PREREQUISITES:
//   - Contact apikey@geniussports.com for clientId + clientSecret
//   - Set secrets: firebase functions:secrets:set GENIUS_CLIENT_ID
//                  firebase functions:secrets:set GENIUS_CLIENT_SECRET
//   - npm install ably (add to functions/package.json)
//
// ═══════════════════════════════════════════════════════════════════════════

const { onCall } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { admin, db, REGION } = require("../config");

// ═══════════════════════════════════════════════════════════════════════════
// CONFIGURATION — Set via Firebase secrets, never hardcode
// ═══════════════════════════════════════════════════════════════════════════
const GENIUS_AUTH_URL = "https://auth.api.geniussports.com/oauth2/token";
const GENIUS_API_BASE = "https://api.geniussports.com";
const GENIUS_AUDIENCE = "https://api.geniussports.com";

// Token cache (in-memory, refreshed on cold start or expiry)
let _cachedToken = null;
let _tokenExpiresAt = 0;

// ═══════════════════════════════════════════════════════════════════════════
// 1. AUTHENTICATION — OAuth2 client_credentials flow
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Obtain an access token from Genius Sports.
 * Caches the token in memory until expiry.
 */
async function getGeniusToken() {
  if (_cachedToken && Date.now() < _tokenExpiresAt) {
    return _cachedToken;
  }

  const clientId = process.env.GENIUS_CLIENT_ID;
  const clientSecret = process.env.GENIUS_CLIENT_SECRET;

  if (!clientId || !clientSecret) {
    throw new Error(
      "Genius Sports credentials not configured. " +
        "Run: firebase functions:secrets:set GENIUS_CLIENT_ID && " +
        "firebase functions:secrets:set GENIUS_CLIENT_SECRET",
    );
  }

  // Dynamic import to avoid crash when axios isn't installed yet
  const axios = require("axios");
  const response = await axios.post(GENIUS_AUTH_URL, {
    grant_type: "client_credentials",
    client_id: clientId,
    client_secret: clientSecret,
    audience: GENIUS_AUDIENCE,
  });

  _cachedToken = response.data.access_token;
  // Expire 5 minutes before actual expiry for safety
  const expiresIn = (response.data.expires_in || 3600) - 300;
  _tokenExpiresAt = Date.now() + expiresIn * 1000;

  return _cachedToken;
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. UPDATEGRAM PARSER — Normalize Genius match events for DFC bots
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Parse a Genius Sports "Updategram" message into DFC-normalized format.
 * Updategrams contain match state changes: scores, events, status updates.
 *
 * @param {Object} updategram - Raw Genius Sports message
 * @returns {Object} Normalized DFC event object
 */
function parseUpdategram(updategram) {
  const { matchId, sportId, eventType, data, timestamp } = updategram;

  // Base normalized event
  const dfcEvent = {
    source: "genius_sports",
    matchId: matchId || null,
    sportId: sportId || null,
    eventType: normalizeEventType(eventType),
    timestamp: timestamp || new Date().toISOString(),
    raw: updategram, // Keep raw for debugging
  };

  // Parse combat-specific events
  switch (dfcEvent.eventType) {
    case "knockdown":
      dfcEvent.fighter = data?.fighter || null;
      dfcEvent.round = data?.round || null;
      dfcEvent.timeInRound = data?.timeInRound || null;
      break;

    case "round_end":
      dfcEvent.round = data?.round || null;
      dfcEvent.scores = data?.scores || [];
      break;

    case "match_result":
      dfcEvent.winner = data?.winner || null;
      dfcEvent.method = data?.method || null; // KO, TKO, Decision, Sub
      dfcEvent.round = data?.round || null;
      break;

    case "odds_update":
      dfcEvent.market = data?.market || null;
      dfcEvent.odds = data?.odds || {};
      break;

    case "strike_stats":
      dfcEvent.fighter = data?.fighter || null;
      dfcEvent.significantStrikes = data?.significantStrikes || 0;
      dfcEvent.takedowns = data?.takedowns || 0;
      break;

    default:
      dfcEvent.payload = data || {};
  }

  return dfcEvent;
}

/**
 * Map Genius event types to DFC-standard types used by bots.
 */
function normalizeEventType(geniusType) {
  const mapping = {
    Knockdown: "knockdown",
    RoundEnd: "round_end",
    MatchResult: "match_result",
    MatchComplete: "match_result",
    OddsUpdate: "odds_update",
    StrikeStatistics: "strike_stats",
    MatchStart: "match_start",
    MatchSuspend: "match_suspend",
    StatusChange: "status_change",
  };
  return mapping[geniusType] || geniusType?.toLowerCase() || "unknown";
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. FIRESTORE WRITER — Persist live events for bot consumption
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Write a parsed event to Firestore for DFC bots to consume.
 * Bots listen to `live_fight_events/{matchId}/events` collection.
 */
async function writeLiveEvent(dfcEvent) {
  if (!dfcEvent.matchId) return;

  const eventRef = db
    .collection("live_fight_events")
    .doc(dfcEvent.matchId)
    .collection("events");

  await eventRef.add({
    ...dfcEvent,
    processedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Also update the match summary doc for quick reads
  await db.collection("live_fight_events").doc(dfcEvent.matchId).set(
    {
      lastEvent: dfcEvent.eventType,
      lastUpdate: admin.firestore.FieldValue.serverTimestamp(),
      matchId: dfcEvent.matchId,
      sportId: dfcEvent.sportId,
    },
    { merge: true },
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. ABLY LISTENER — Real-time channel subscription (when keys are ready)
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Subscribe to Genius Sports Ably channel for live match updates.
 * Call this from a long-running process (e.g., Cloud Run) rather than
 * a Cloud Function due to execution time limits.
 *
 * For Cloud Functions, use the scheduled poller (below) instead.
 */
async function startAblyListener(matchId) {
  let Ably;
  try {
    Ably = require("ably");
  } catch {
    console.error("ably package not installed. Run: npm install ably");
    return;
  }

  const token = await getGeniusToken();

  const client = new Ably.Realtime({
    authCallback: async (tokenParams, callback) => {
      try {
        const freshToken = await getGeniusToken();
        callback(null, { token: freshToken });
      } catch (err) {
        callback(err, null);
      }
    },
  });

  const channel = client.channels.get(`match:${matchId}`);

  channel.subscribe("updategram", async (message) => {
    try {
      const parsed = parseUpdategram(message.data);
      await writeLiveEvent(parsed);
      console.log(
        `[GeniusSports] Processed ${parsed.eventType} for match ${matchId}`,
      );
    } catch (err) {
      console.error(`[GeniusSports] Error processing updategram:`, err);
    }
  });

  console.log(`[GeniusSports] Listening to match:${matchId}`);
  return client;
}

// ═══════════════════════════════════════════════════════════════════════════
// 5. CLOUD FUNCTIONS — Exposed endpoints
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Callable: Fetch match summary from Genius Sports API on demand.
 * Used by FightWire to generate instant news headlines.
 */
const fetchGeniusMatchSummary = onCall({ region: REGION }, async (request) => {
  const { matchId } = request.data;
  if (!matchId) throw new Error("matchId is required");

  const token = await getGeniusToken();
  const axios = require("axios");
  const response = await axios.get(
    `${GENIUS_API_BASE}/v3/matches/${matchId}/summary`,
    { headers: { Authorization: `Bearer ${token}` } },
  );

  // Write to Firestore for caching
  await db
    .collection("genius_match_summaries")
    .doc(matchId)
    .set({
      ...response.data,
      fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

  return response.data;
});

/**
 * Scheduled: Poll active matches every 2 minutes during live events.
 * Fallback for when Ably real-time isn't connected.
 */
const pollGeniusLiveMatches = onSchedule(
  {
    schedule: "every 2 minutes",
    region: REGION,
    timeoutSeconds: 60,
  },
  async () => {
    // Check if there are any active matches to poll
    const activeMatches = await db
      .collection("live_fight_events")
      .where("status", "==", "live")
      .get();

    if (activeMatches.empty) {
      console.log("[GeniusSports] No active matches to poll");
      return;
    }

    const token = await getGeniusToken();
    const axios = require("axios");

    for (const doc of activeMatches.docs) {
      const { matchId } = doc.data();
      if (!matchId) continue;

      try {
        const response = await axios.get(
          `${GENIUS_API_BASE}/v3/matches/${matchId}/state`,
          { headers: { Authorization: `Bearer ${token}` } },
        );

        if (response.data) {
          const parsed = parseUpdategram({
            matchId,
            eventType: "StatusChange",
            data: response.data,
            timestamp: new Date().toISOString(),
          });
          await writeLiveEvent(parsed);
        }
      } catch (err) {
        console.error(
          `[GeniusSports] Poll error for match ${matchId}:`,
          err.message,
        );
      }
    }
  },
);

/**
 * Callable: Receive Genius Sports V3 Integration Service push messages.
 * Set this function's URL as your "Listener URL" in Genius Sports config.
 */
const geniusSportsWebhook = onCall({ region: REGION }, async (request) => {
  const message = request.data;

  if (!message || !message.matchId) {
    console.warn("[GeniusSports] Received empty webhook");
    return { status: "ignored" };
  }

  const parsed = parseUpdategram(message);
  await writeLiveEvent(parsed);

  return { status: "processed", eventType: parsed.eventType };
});

// ═══════════════════════════════════════════════════════════════════════════
// 6. SYNC GENIUS STATS — Aggregated live stats for Flutter StreamBuilder
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Scheduled: Every 1 minute during live events.
 * Fetches per-fighter strike, takedown, and odds data from Genius Sports
 * and writes a single merged doc to `live_stats/{eventId}` for the Flutter
 * FighterProfileScreen StreamBuilder.
 *
 * Schema written:
 *   live_stats/{eventId} {
 *     redCorner:  { name, strikes, takedowns, liveOdds },
 *     blueCorner: { name, strikes, takedowns, liveOdds },
 *     round: int,
 *     clockSeconds: int,
 *     matchStatus: string,
 *     lastUpdated: Timestamp
 *   }
 */
const syncGeniusStats = onSchedule(
  {
    schedule: "every 1 minutes",
    region: REGION,
    timeoutSeconds: 55,
    secrets: ["GENIUS_CLIENT_ID", "GENIUS_CLIENT_SECRET"],
  },
  async () => {
    // Only run when there are live PPV events
    const liveEvents = await db
      .collection("ppv_events")
      .where("status", "==", "live")
      .get();

    if (liveEvents.empty) {
      console.log("[syncGeniusStats] No live PPV events — skipping.");
      return;
    }

    let token;
    try {
      token = await getGeniusToken();
    } catch (err) {
      console.error("[syncGeniusStats] Auth failed:", err.message);
      return;
    }

    const axios = require("axios");

    for (const eventDoc of liveEvents.docs) {
      const eventData = eventDoc.data();
      const geniusMatchId = eventData.geniusMatchId;

      if (!geniusMatchId) {
        console.log(
          `[syncGeniusStats] Event ${eventDoc.id} has no geniusMatchId — skipping.`,
        );
        continue;
      }

      try {
        // Fetch live match statistics from Genius Sports V3 API
        const response = await axios.get(
          `${GENIUS_API_BASE}/v3/matches/${geniusMatchId}/statistics`,
          { headers: { Authorization: `Bearer ${token}` } },
        );

        const stats = response.data;
        const fighters = stats.competitors || stats.fighters || [];
        const red = fighters[0] || {};
        const blue = fighters[1] || {};

        // Fetch live odds if available
        let odds = {};
        try {
          const oddsResp = await axios.get(
            `${GENIUS_API_BASE}/v3/matches/${geniusMatchId}/odds`,
            { headers: { Authorization: `Bearer ${token}` } },
          );
          odds = oddsResp.data || {};
        } catch {
          // Odds endpoint may not be available for all events
        }

        const liveDoc = {
          redCorner: {
            name: red.name || eventData.redCornerName || "Red Corner",
            strikes: red.significantStrikes ?? red.totalStrikes ?? 0,
            takedowns: red.takedowns ?? red.takedownsLanded ?? 0,
            liveOdds: odds.homeOdds ?? odds.redOdds ?? null,
          },
          blueCorner: {
            name: blue.name || eventData.blueCornerName || "Blue Corner",
            strikes: blue.significantStrikes ?? blue.totalStrikes ?? 0,
            takedowns: blue.takedowns ?? blue.takedownsLanded ?? 0,
            liveOdds: odds.awayOdds ?? odds.blueOdds ?? null,
          },
          round: stats.currentRound ?? stats.round ?? 0,
          clockSeconds: stats.clockSeconds ?? stats.timeRemaining ?? 0,
          matchStatus: stats.status || "live",
          eventId: eventDoc.id,
          geniusMatchId,
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        };

        await db
          .collection("live_stats")
          .doc(eventDoc.id)
          .set(liveDoc, { merge: true });

        console.log(
          `[syncGeniusStats] Updated live_stats/${eventDoc.id}: ` +
            `R${liveDoc.round} — ${liveDoc.redCorner.name} ` +
            `${liveDoc.redCorner.strikes}str/${liveDoc.redCorner.takedowns}td vs ` +
            `${liveDoc.blueCorner.name} ` +
            `${liveDoc.blueCorner.strikes}str/${liveDoc.blueCorner.takedowns}td`,
        );
      } catch (err) {
        console.error(
          `[syncGeniusStats] Error for event ${eventDoc.id} (match ${geniusMatchId}):`,
          err.message,
        );
      }
    }
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// EXPORTS
// ═══════════════════════════════════════════════════════════════════════════
module.exports = {
  fetchGeniusMatchSummary,
  pollGeniusLiveMatches,
  geniusSportsWebhook,
  syncGeniusStats,
  // Utility exports for other modules (e.g., waterfall.js)
  getGeniusToken,
  parseUpdategram,
  startAblyListener,
};
