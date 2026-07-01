// ═══════════════════════════════════════════════════════════════════════════
// DFC NINJA CHAT — Gemini-powered AI messaging bot
// Called by the Flutter app via httpsCallable('askNinja')
// Falls back to keyword engine on the client if this CF is unavailable.
// ═══════════════════════════════════════════════════════════════════════════

"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { admin, db, REGION, geminiModel } = require("../config");

// ── System prompt — DFC Ninja identity ───────────────────────────────────
const NINJA_SYSTEM_PROMPT = `You are the DFC Ninja — the intelligent, compassionate AI brain of DataFightCentral (DFC), the world's premier combat sports platform.

IDENTITY:
- Your male persona is: DFC Ninja (direct, knowledgeable, confident)
- Your female persona is: Shakura — Queen of the DFC (empowering, warm, fierce)
- You adapt based on the persona parameter passed to you.
- You are not a generic chatbot. You are deeply embedded in combat sports culture.

KNOWLEDGE AREAS (be precise and confident):
- MMA: UFC, ONE Championship, Bellator/PFL, BKFC, regional promotions worldwide
- Boxing: WBC, WBA, IBF, WBO, WBF, IBA champions; current rankings; pound-for-pound lists
- Kickboxing: Glory, K-1 history, Muay Thai circuits
- BJJ/Grappling: ADCC, Gordon Ryan, recent submission grappling scene
- Wrestling: Collegiate, freestyle, Greco-Roman crossovers to MMA
- Fighter stats, records, camps, weight classes, upcoming bouts
- Training: periodisation, strength & conditioning, weight cuts, recovery protocols
- Nutrition: fight camp cutting, hydration, performance nutrition
- Mental performance: visualization, pressure handling, flow states
- DFC Platform: Feed (FightWire), PPV events, AI Coach (Shido), maps/gyms, social features
- Promoter tools: DFC promotion management, fight cards, licensing
- Career development: signing with promotions, ranking systems, sponsorships

DFC PLATFORM NAVIGATION:
- Feed tab → FightWire social feed, posts, stories
- PPV tab → Live events, upcoming cards, purchase, replay
- Explore tab → Fighter directory, gym finder, global map
- Network tab → Friends, groups, messaging
- Profile tab → Account, purchases, fighter identity
- Atlas → DFC's AI fight intelligence (for deeper analysis)
- AI Coach Shido → Personalized training plans

TONE:
- Direct, concise, authoritative. Never waffle.
- Warm to newcomers, focused for professionals.
- Use "we" when referring to DFC — you are part of it.
- No emojis unless the user uses them first.
- Short responses preferred (2-4 sentences). Go longer only when the topic demands it.
- If you don't know something specific, say so honestly, then redirect to what you do know.

GUARDRAILS:
- Never fabricate fight results, records, or statistics.
- If asked about live/recent results you cannot verify, say: "I don't have live data on that — check the PPV tab or the official promotion site for the latest."
- Stay on-topic: combat sports, training, DFC platform, fighter careers.
- If asked about non-combat topics, redirect professionally.`;

// ── Rate limiting (per-user, per-session) ────────────────────────────────
const _requestTimestamps = new Map(); // userId → [timestamp]
const RATE_LIMIT_WINDOW_MS = 60_000;
const RATE_LIMIT_MAX_REQUESTS = 8;

function checkRateLimit(userId) {
  const now = Date.now();
  const timestamps = (_requestTimestamps.get(userId) || []).filter(
    (t) => now - t < RATE_LIMIT_WINDOW_MS,
  );
  if (timestamps.length >= RATE_LIMIT_MAX_REQUESTS) return false;
  timestamps.push(now);
  _requestTimestamps.set(userId, timestamps);
  return true;
}

// ── Main callable ─────────────────────────────────────────────────────────
exports.askNinja = onCall(
  {
    region: REGION,
    cors: true,
    enforceAppCheck: false,
  },
  async (request) => {
    const { message, persona = "neutral", history = [] } = request.data || {};
    const userId = request.auth?.uid || "anonymous";

    if (
      !message ||
      typeof message !== "string" ||
      message.trim().length === 0
    ) {
      throw new HttpsError("invalid-argument", "message is required");
    }

    const trimmedMessage = message.trim().slice(0, 2000);

    // Rate limit
    if (!checkRateLimit(userId)) {
      throw new HttpsError(
        "resource-exhausted",
        "Too many requests. Slow down.",
      );
    }

    // Try Gemini if model is available
    if (geminiModel) {
      try {
        const systemBlock =
          NINJA_SYSTEM_PROMPT +
          (persona === "female"
            ? "\n\nIMPORTANT: You are presenting as Shakura for this conversation."
            : "");

        // Build conversation history for context
        const contextMessages = [];
        if (Array.isArray(history) && history.length > 0) {
          const recentHistory = history.slice(-6); // last 3 exchanges
          for (const h of recentHistory) {
            if (h.role === "user") contextMessages.push(`User: ${h.text}`);
            if (h.role === "ninja") contextMessages.push(`Ninja: ${h.text}`);
          }
        }

        const fullPrompt =
          contextMessages.length > 0
            ? `${systemBlock}\n\n--- CONVERSATION HISTORY ---\n${contextMessages.join("\n")}\n\n--- CURRENT MESSAGE ---\nUser: ${trimmedMessage}\nNinja:`
            : `${systemBlock}\n\nUser: ${trimmedMessage}\nNinja:`;

        const result = await geminiModel.generateContent(fullPrompt);
        const text =
          result.response?.candidates?.[0]?.content?.parts?.[0]?.text?.trim();

        if (text && text.length > 0) {
          // Log usage for analytics (best-effort)
          db.collection("ninja_chat_logs")
            .add({
              userId,
              persona,
              messageLength: trimmedMessage.length,
              replyLength: text.length,
              model: "gemini-2.0-flash",
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
            })
            .catch(() => {});

          return { reply: text, source: "gemini" };
        }
      } catch (err) {
        // Log and fall through to keyword engine
        console.warn("Ninja Gemini error:", err.message);
      }
    }

    // Fallback: keyword engine (mirrored from Flutter client for consistency)
    return {
      reply: _keywordFallback(trimmedMessage, persona),
      source: "keyword",
    };
  },
);

// ── Keyword fallback (mirrors expanded Flutter engine) ────────────────────
function _keywordFallback(text, persona) {
  const lower = text.toLowerCase().trim();
  const isQueen = persona === "female";
  const intro = isQueen ? "Shakura here." : "Ninja here.";

  if (/^(hi|hello|hey|sup|yo|greetings)(\s|$)/.test(lower)) {
    return isQueen
      ? "Hey queen. I am Shakura — your DFC Ninja. What do you need today?"
      : "Hey. I am the DFC Ninja. Ask me anything about fights, training, or the platform.";
  }

  if (
    lower.includes("ppv") ||
    lower.includes("pay per view") ||
    (lower.includes("buy") && lower.includes("fight"))
  ) {
    return `${intro} Head to the PPV tab for live events, upcoming cards, and replay access. We support tiered pricing — fan, VIP, and platinum passes.`;
  }

  if (lower.includes("ufc") || lower.includes("mma")) {
    return `${intro} We cover UFC, ONE Championship, PFL, Bellator, and regional MMA worldwide. Check the Explore tab for fighter profiles and rankings.`;
  }

  if (
    lower.includes("train") ||
    lower.includes("coach") ||
    lower.includes("workout") ||
    lower.includes("drill")
  ) {
    return `${intro} AI Coach Shido builds personalised training plans based on your weight class, discipline, and fight timeline. Open the AI Coach tab.`;
  }

  if (
    lower.includes("gym") ||
    lower.includes("club") ||
    lower.includes("map")
  ) {
    return `${intro} The Explore tab has a full gym map — search by discipline, location, and DFC tier. Filter by MMA, boxing, BJJ, Muay Thai, and more.`;
  }

  if (
    lower.includes("fight") ||
    lower.includes("event") ||
    lower.includes("card") ||
    lower.includes("schedule")
  ) {
    return `${intro} Upcoming fights are in the PPV tab. Live events pulse red. Tap any card for full bout breakdown, odds context, and purchase options.`;
  }

  if (
    lower.includes("messag") ||
    lower.includes("inbox") ||
    lower.includes("dm") ||
    lower.includes("chat")
  ) {
    return `${intro} You are already in DFC Messenger. Use the search icon to find and message any DFC member, promoter, or fighter directly.`;
  }

  if (
    lower.includes("friend") ||
    lower.includes("follow") ||
    lower.includes("connect") ||
    lower.includes("people")
  ) {
    return `${intro} Go to the Network tab to find friends, send requests, and grow your combat sports circle. The People You May Know feed updates based on your discipline and region.`;
  }

  if (
    lower.includes("post") ||
    lower.includes("feed") ||
    lower.includes("social") ||
    lower.includes("fightwire")
  ) {
    return `${intro} FightWire is the main feed — tap the Feed tab to post updates, fight predictions, clips, and interact with the DFC community worldwide.`;
  }

  if (
    lower.includes("profile") ||
    lower.includes("account") ||
    lower.includes("settings")
  ) {
    return `${intro} Your profile is the last tab on the bottom nav. Manage your fighter identity, purchases, verification status, and account settings there.`;
  }

  if (
    lower.includes("rank") ||
    lower.includes("champion") ||
    lower.includes("belt") ||
    lower.includes("title")
  ) {
    return `${intro} DFC tracks rankings across all divisions and promotions. Go to Explore → Rankings for current pound-for-pound and divisional standings.`;
  }

  if (
    lower.includes("weight") ||
    lower.includes("cut") ||
    lower.includes("rehydrat")
  ) {
    return `${intro} Weight management is a serious topic. AI Coach Shido has a structured weight cut protocol — gradual deficit, water manipulation, and full rehydration plans. Ask Shido for your weight class.`;
  }

  if (
    lower.includes("nutrition") ||
    lower.includes("diet") ||
    lower.includes("eat") ||
    lower.includes("food")
  ) {
    return `${intro} Fight camp nutrition is covered in the AI Coach section. Shido tailors macros around your training load, weight class, and fight date.`;
  }

  if (
    lower.includes("sponsor") ||
    lower.includes("brand") ||
    lower.includes("deal") ||
    lower.includes("money")
  ) {
    return `${intro} DFC's monetization tools help fighters attract sponsors and promoters. See the Revenue Wallet and Promoter Portal in your profile menu.`;
  }

  if (
    lower.includes("promoter") ||
    lower.includes("promotion") ||
    lower.includes("event organis")
  ) {
    return `${intro} Promoters get their own command panel — fight card builder, ticket management, broadcast tools, and fighter signing flow. Open the Promoter Portal from the menu.`;
  }

  if (
    lower.includes("stream") ||
    lower.includes("watch") ||
    lower.includes("live") ||
    lower.includes("replay")
  ) {
    return `${intro} DFC streams are powered by Mux — broadcast quality with sub-second latency. Buy any PPV event and the stream is in your library permanently.`;
  }

  if (
    lower.includes("thank") ||
    lower.includes("appreciate") ||
    lower.includes("cheers") ||
    lower.includes("love")
  ) {
    return isQueen
      ? "Always here for you, queen. DFC has your back — always."
      : "Anytime. That is what I am here for.";
  }

  if (
    lower.includes("help") ||
    lower.includes("what can you do") ||
    lower.includes("?")
  ) {
    return "$intro Here is what I cover:\n• PPV events — live, upcoming, replay\n• Fighter rankings and records\n• Gym finder — global map\n• AI Coach Shido — training plans\n• FightWire — social feed\n• Promoter and sponsor tools\n• Messenger and friends\n\nJust ask.";
  }

  return `${intro} I am here for anything fight-related — events, fighters, training, the platform. What do you need?`;
}
