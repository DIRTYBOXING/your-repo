// ═══════════════════════════════════════════════════════════════════════════
// AI FUNCTIONS — Powered by Google Gemini
// ═══════════════════════════════════════════════════════════════════════════

const { onCall } = require("firebase-functions/v2/https");
const { REGION, geminiModel } = require("../config");

// ─── Helper Functions ────────────────────────────────────────────────────
async function askGemini(prompt, fallback) {
  if (!geminiModel) return fallback;
  try {
    const result = await geminiModel.generateContent(prompt);
    return result.response.text() || fallback;
  } catch (err) {
    console.error("Gemini API error:", err.message);
    return fallback;
  }
}

async function askGeminiJSON(prompt, fallback) {
  if (!geminiModel) return fallback;
  try {
    const result = await geminiModel.generateContent(prompt);
    let text = result.response.text().trim();
    text = text
      .replace(/^```(?:json)?\n?/i, "")
      .replace(/\n?```$/i, "")
      .trim();
    return JSON.parse(text);
  } catch (err) {
    console.error("Gemini JSON error:", err.message);
    return fallback;
  }
}

// ─── Fight Breakdown ─────────────────────────────────────────────────────
const generateFightBreakdown = onCall({ region: REGION }, async (request) => {
  const { fighterA, fighterB, event, fighterAStats, fighterBStats } =
    request.data || {};
  if (!fighterA || !fighterB)
    return { error: "fighterA and fighterB required" };

  const prompt = `You are an elite combat sports analyst for DataFightCentral.
Analyze this matchup and return ONLY valid JSON (no markdown).
Fighter A: ${fighterA}${fighterAStats ? " | Stats: " + fighterAStats : ""}
Fighter B: ${fighterB}${fighterBStats ? " | Stats: " + fighterBStats : ""}
${event ? "Event: " + event : ""}
Return JSON: {"winProbabilityA": <0-1>, "winProbabilityB": <0-1>, "roundByRoundSimulation": [...], "howABeatsB": "...", "howBBeatsA": "...", "fightIQInsights": "...", "predictedMethod": "...", "keyFactor": "..."}`;

  const fallback = {
    winProbabilityA: 0.5,
    winProbabilityB: 0.5,
    roundByRoundSimulation: [
      "R1: Feeling out",
      "R2: Tempo up",
      "R3: Championship rounds",
    ],
    howABeatsB: "Pressure and volume.",
    howBBeatsA: "Counters and movement.",
    fightIQInsights: "Solid fundamentals.",
    predictedMethod: "Decision",
    keyFactor: "Cardio",
  };

  return {
    breakdown: await askGeminiJSON(prompt, fallback),
    model: geminiModel ? "gemini-2.0-flash" : "fallback",
  };
});

// ─── Fighter Bio ─────────────────────────────────────────────────────────
const generateFighterBio = onCall({ region: REGION }, async (request) => {
  const { fighterName, stats, achievements, discipline } = request.data || {};
  if (!fighterName) return { error: "fighterName required" };

  const prompt = `Write a 150-word fighter biography for ${fighterName}. ${discipline ? "Discipline: " + discipline : ""} ${stats ? "Stats: " + stats : ""} ${achievements ? "Achievements: " + achievements : ""} Third person, action-oriented, for a combat sports platform.`;

  return {
    bio: await askGemini(prompt, fighterName + " is building their legacy."),
    model: geminiModel ? "gemini-2.0-flash" : "fallback",
  };
});

// ─── Suggest Matchup ─────────────────────────────────────────────────────
const suggestMatchup = onCall({ region: REGION }, async (request) => {
  const { fighterList, recentResults, weightClass, discipline } =
    request.data || {};

  const prompt = `Combat sports matchmaker. Suggest 3 matchups. Return ONLY JSON array. ${fighterList ? "Fighters: " + fighterList : ""} ${recentResults ? "Recent: " + recentResults : ""} ${weightClass ? "Class: " + weightClass : ""} ${discipline ? "Discipline: " + discipline : ""}
Return: [{"fighterA": "...", "fighterB": "...", "reason": "...", "excitementScore": <1-10>}]`;

  return {
    matchups: await askGeminiJSON(prompt, [
      {
        fighterA: "TBD",
        fighterB: "TBD",
        reason: "Needs data",
        excitementScore: 5,
      },
    ]),
    model: geminiModel ? "gemini-2.0-flash" : "fallback",
  };
});

// ─── Event Recap ─────────────────────────────────────────────────────────
const generateEventRecap = onCall({ region: REGION }, async (request) => {
  const { eventName, fightResults, highlights } = request.data || {};
  if (!eventName) return { error: "eventName required" };

  const prompt = `Write 200-word event recap for ${eventName}. ${fightResults ? "Results: " + fightResults : ""} ${highlights ? "Highlights: " + highlights : ""} Energetic, factual.`;

  return {
    recap: await askGemini(prompt, eventName + " delivered action."),
    model: geminiModel ? "gemini-2.0-flash" : "fallback",
  };
});

// ─── Comment Moderation ──────────────────────────────────────────────────
const moderateComment = onCall({ region: REGION }, async (request) => {
  const { commentText } = request.data || {};
  if (!commentText) return { decision: "approve", reason: "Empty" };

  const prompt = `Content moderator for combat sports. Review: "${commentText.slice(0, 500)}" Allow fight discussion, reject hate/threats/spam. Return JSON: {"decision": "approve|reject", "reason": "...", "confidence": <0-1>}`;

  return await askGeminiJSON(prompt, {
    decision: "approve",
    reason: "Default approve",
    confidence: 0.5,
  });
});

// ─── Fan Engagement Post ─────────────────────────────────────────────────
const generateFanEngagementPost = onCall(
  { region: REGION },
  async (request) => {
    const { topic, style, platform } = request.data || {};

    const prompt = `Create fan engagement post. Topic: ${topic || "combat sports"} Style: ${style || "hype"} ${platform ? "Platform: " + platform : ""} Under 280 chars, include CTA.`;

    return {
      post: await askGemini(prompt, "Who wins this fight? Drop your picks!"),
      model: geminiModel ? "gemini-2.0-flash" : "fallback",
    };
  },
);

// ─── Social Post ─────────────────────────────────────────────────────────
const generateSocialPost = onCall({ region: REGION }, async (request) => {
  const { event, fighter, fightDate, discipline, tone } = request.data || {};

  const toneGuides = {
    expert_coach: "Elite coach. Direct, technical.",
    motivational_coach: "Training coach. Motivational.",
    medical_advisor: "Medical advisor. Clinical.",
    hype_master: "Fight promoter. High energy.",
    analyst: "Fight analyst. Statistical.",
    default: "DataFightCentral. Professional.",
  };

  const prompt = `${toneGuides[tone] || toneGuides.default} Social post. ${fighter ? "Fighter: " + fighter : ""} ${event ? "Event: " + event : ""} ${fightDate ? "Date: " + fightDate : ""} ${discipline ? "Discipline: " + discipline : ""} Under 280 chars.`;

  return {
    post: await askGemini(prompt, (fighter || "Fight night") + " is coming."),
    model: geminiModel ? "gemini-2.0-flash" : "fallback",
  };
});

// ─── Promo Hype ──────────────────────────────────────────────────────────
const generatePromoHype = onCall({ region: REGION }, async (request) => {
  const { eventName, mainEvent, date, venue, discipline, fighters, context } =
    request.data || {};

  const prompt = `HypeBot — generate EXPLOSIVE hype. Event: ${eventName || "Fight Night"} Main: ${mainEvent || "TBA"} Date: ${date || "Soon"} Venue: ${venue || "TBA"} Fighters: ${fighters ? fighters.join(", ") : "Elite"} ${context || ""}
Return JSON: {"headline": "...", "body": "...", "hashtags": [...], "callToAction": "...", "hypeScore": <0-1>, "viralPotential": <0-1>, "platforms": [...]}`;

  const fallback = {
    headline: `🔥 ${eventName || "FIGHT NIGHT"}`,
    body: `${mainEvent || "Combat"} goes down ${date || "soon"}.`,
    hashtags: ["#DataFightCentral", "#FightHype"],
    callToAction: "Lock in now",
    hypeScore: 0.85,
    viralPotential: 0.8,
    platforms: ["twitter", "instagram"],
  };

  return {
    content: await askGeminiJSON(prompt, fallback),
    model: geminiModel ? "gemini-2.0-flash" : "fallback",
  };
});

// ─── Fighter Spotlight ───────────────────────────────────────────────────
const generateFighterSpotlight = onCall({ region: REGION }, async (request) => {
  const { fighterName, record, discipline, gym, achievements, style, country } =
    request.data || {};

  const prompt = `SpotlightBot — fighter profile. Fighter: ${fighterName || "Contender"} Record: ${record || "Building"} Discipline: ${discipline || "MMA"} Gym: ${gym || "Elite"} Achievements: ${achievements || "Wins"} Style: ${style || "Well-rounded"} Country: ${country || "International"}
Return JSON: {"headline": "...", "intro": "...", "body": "...", "keyStats": [...], "quote": "...", "hashtags": [...], "engagementScore": <0-1>}`;

  const fallback = {
    headline: `⭐ ${fighterName || "Contender"}`,
    intro: "World is watching.",
    body: `${fighterName || "Fighter"} building legacy.`,
    keyStats: ["Elite striker", "Iron chin"],
    quote: "I came to take over.",
    hashtags: ["#FighterSpotlight"],
    engagementScore: 0.82,
  };

  return {
    content: await askGeminiJSON(prompt, fallback),
    model: geminiModel ? "gemini-2.0-flash" : "fallback",
  };
});

// ─── Matchup Analysis ────────────────────────────────────────────────────
const generateMatchupAnalysis = onCall({ region: REGION }, async (request) => {
  const { fighter1, fighter2, discipline, stakes, event } = request.data || {};

  const prompt = `MatchmakerBot — fight analysis. Fighter1: ${fighter1 || "A"} Fighter2: ${fighter2 || "B"} Discipline: ${discipline || "MMA"} Stakes: ${stakes || "Main"} Event: ${event || "Fight Night"}
Return JSON: {"headline": "...", "analysis": "...", "fighter1Edge": [...], "fighter2Edge": [...], "prediction": "...", "confidence": <0-1>, "xFactor": "...", "hashtags": [...], "pollQuestion": "..."}`;

  const fallback = {
    headline: `🥊 ${fighter1 || "A"} vs ${fighter2 || "B"}`,
    analysis: "Styles make fights.",
    fighter1Edge: ["Power", "Experience"],
    fighter2Edge: ["Speed", "Cardio"],
    prediction: "War.",
    confidence: 0.65,
    xFactor: "First big shot sets tone.",
    hashtags: ["#FightPrediction"],
    pollQuestion: "Who wins?",
  };

  return {
    content: await askGeminiJSON(prompt, fallback),
    model: geminiModel ? "gemini-2.0-flash" : "fallback",
  };
});

// ─── Kimik Insight ───────────────────────────────────────────────────────
const generateKimikInsight = onCall({ region: REGION }, async (request) => {
  const {
    category,
    wellnessData,
    trainingLoad,
    trendingTopics,
    breakingNews,
    userContext,
  } = request.data || {};

  const prompt = `Kimik2.5 — AI intelligence. Category: ${category || "general"} Wellness: ${wellnessData ? JSON.stringify(wellnessData) : "Standard"} Training: ${trainingLoad ? JSON.stringify(trainingLoad) : "Moderate"} Trending: ${trendingTopics ? trendingTopics.join(", ") : "News"} Breaking: ${breakingNews || "None"} Context: ${userContext || "User"}
Return JSON: {"insight": "...", "recommendation": "...", "confidence": <0-1>, "priority": "critical|high|normal|low", "relatedTopics": [...], "dataPoints": [...], "nextAction": "..."}`;

  const fallback = {
    insight: "Systems optimal.",
    recommendation: "Continue trajectory.",
    confidence: 0.88,
    priority: "normal",
    relatedTopics: ["Training", "Recovery"],
    dataPoints: ["Online", "Active"],
    nextAction: "Monitor.",
  };

  return {
    content: await askGeminiJSON(prompt, fallback),
    model: geminiModel ? "gemini-2.0-flash" : "fallback",
  };
});

// ─── Competitor Intel ────────────────────────────────────────────────────
const generateCompetitorIntel = onCall({ region: REGION }, async (request) => {
  const { competitorName, platform, contentSample, marketSegment } =
    request.data || {};

  const prompt = `Competitor Intelligence. Competitor: ${competitorName || "Industry player"} Platform: ${platform || "Social"} Content: ${contentSample || "Fight content"} Market: ${marketSegment || "Combat sports"}
Return JSON: {"summary": "...", "strengths": [...], "weaknesses": [...], "opportunities": [...], "threatLevel": "low|medium|high", "recommendedCounterStrategy": "...", "contentGaps": [...], "actionItems": [...]}`;

  const fallback = {
    summary: "Standard competitor.",
    strengths: ["Established"],
    weaknesses: ["Generic"],
    opportunities: ["AI personalization"],
    threatLevel: "medium",
    recommendedCounterStrategy: "Outpace with AI.",
    contentGaps: ["Live coverage"],
    actionItems: ["Increase velocity"],
  };

  return {
    content: await askGeminiJSON(prompt, fallback),
    model: geminiModel ? "gemini-2.0-flash" : "fallback",
  };
});

// ─── Email Campaign ──────────────────────────────────────────────────────
const generateEmailCampaign = onCall({ region: REGION }, async (request) => {
  const { campaignType, targetAudience, event, promotion, callToAction } =
    request.data || {};

  const prompt = `Email Marketing AI. Type: ${campaignType || "event_promotion"} Audience: ${targetAudience || "Fight fans"} Event: ${event || "Fight night"} Promo: ${promotion || "Standard"} CTA: ${callToAction || "Watch now"}
Return JSON: {"subjectLine": "...", "preheader": "...", "headline": "...", "body": "...", "bulletPoints": [...], "ctaButton": "...", "ctaUrl": "...", "urgencyElement": "...", "predictedOpenRate": <0-1>, "predictedClickRate": <0-1>}`;

  const fallback = {
    subjectLine: "🔥 Fight Night Alert",
    preheader: "Biggest matchups going down.",
    headline: "FIGHT NIGHT",
    body: "Elite action awaits.",
    bulletPoints: ["Breakdown", "Coverage", "Updates"],
    ctaButton: "WATCH NOW",
    ctaUrl: "/events",
    urgencyElement: "Limited time",
    predictedOpenRate: 0.35,
    predictedClickRate: 0.12,
  };

  return {
    content: await askGeminiJSON(prompt, fallback),
    model: geminiModel ? "gemini-2.0-flash" : "fallback",
  };
});

// ─── E-commerce Strategy ─────────────────────────────────────────────────
const generateEcommerceStrategy = onCall(
  { region: REGION },
  async (request) => {
    const { productType, targetMarket, pricePoint, competitor, season } =
      request.data || {};

    const prompt = `E-commerce Strategy. Product: ${productType || "PPV/merch"} Market: ${targetMarket || "Fight fans"} Price: ${pricePoint || "Mid-range"} Competitor: ${competitor || "Standard"} Season: ${season || "Regular"}
Return JSON: {"pricingRecommendation": "...", "bundleIdeas": [...], "urgencyTactics": [...], "upsellOpportunities": [...], "promotionIdeas": [...], "targetRevenue": "...", "conversionTips": [...], "competitiveEdge": "..."}`;

    const fallback = {
      pricingRecommendation: "Competitive with early-bird.",
      bundleIdeas: ["Event + merch"],
      urgencyTactics: ["Limited access"],
      upsellOpportunities: ["VIP"],
      promotionIdeas: ["Flash sale"],
      targetRevenue: "Above market",
      conversionTips: ["Clear CTA"],
      competitiveEdge: "AI personalization",
    };

    return {
      content: await askGeminiJSON(prompt, fallback),
      model: geminiModel ? "gemini-2.0-flash" : "fallback",
    };
  },
);

// ─── Conveyor Belt Process ───────────────────────────────────────────────
const conveyorBeltProcess = onCall({ region: REGION }, async (request) => {
  const { rawContent, contentType, sourceUrl, priority } = request.data || {};

  const prompt = `Content Conveyor Belt. Raw: ${rawContent || "Content"} Type: ${contentType || "news"} Source: ${sourceUrl || "Unknown"} Priority: ${priority || "normal"}
Return JSON: {"processedTitle": "...", "processedBody": "...", "summary": "...", "tags": [...], "category": "news|event|fighter|analysis", "sentiment": "positive|neutral|negative", "relevanceScore": <0-1>, "publishReady": true/false, "suggestedPlatforms": [...], "engagementPrediction": <0-1>}`;

  const fallback = {
    processedTitle: rawContent ? rawContent.substring(0, 80) : "Fight News",
    processedBody: rawContent || "Processed.",
    summary: "Update.",
    tags: ["mma", "combat"],
    category: "news",
    sentiment: "neutral",
    relevanceScore: 0.75,
    publishReady: true,
    suggestedPlatforms: ["feed", "social"],
    engagementPrediction: 0.65,
  };

  return {
    content: await askGeminiJSON(prompt, fallback),
    model: geminiModel ? "gemini-2.0-flash" : "fallback",
  };
});

// ─── Wolverine Regenerate ────────────────────────────────────────────────
const wolverineRegenerate = onCall({ region: REGION }, async (request) => {
  const { failedContentId, originalPrompt, errorType, retryCount } =
    request.data || {};

  const prompt = `Wolverine Protocol — self-healing. FailedID: ${failedContentId || "unknown"} Original: ${originalPrompt || "Generate content"} Error: ${errorType || "timeout"} Retry: ${retryCount || 1}
Return JSON: {"regeneratedContent": "...", "healingApplied": [...], "confidenceScore": <0-1>, "systemStatus": "healed|partial|critical", "preventiveMeasures": [...], "nextRetryDelay": 0}`;

  const fallback = {
    regeneratedContent: "Recovered successfully.",
    healingApplied: ["Simplified"],
    confidenceScore: 0.9,
    systemStatus: "healed",
    preventiveMeasures: ["Cache enabled"],
    nextRetryDelay: 0,
  };

  return {
    content: await askGeminiJSON(prompt, fallback),
    model: geminiModel ? "gemini-2.0-flash" : "fallback",
  };
});

// ─── Live Fight Commentary ───────────────────────────────────────────────
const generateLiveFightCommentary = onCall(
  { region: REGION },
  async (request) => {
    const { fightId, currentRound, fighter1, fighter2, recentAction } =
      request.data || {};

    const prompt = `Live fight commentator. Fight: ${fightId || "Live"} Round: ${currentRound || 1} ${fighter1 || "Fighter 1"} vs ${fighter2 || "Fighter 2"} Action: ${recentAction || "Engaging"} Generate short, punchy commentary. Return JSON: {"commentary": "...", "excitement": <0-1>, "keyMoment": true/false}`;

    const fallback = {
      commentary: "The action continues!",
      excitement: 0.7,
      keyMoment: false,
    };

    return await askGeminiJSON(prompt, fallback);
  },
);

// ─── Live Prediction ─────────────────────────────────────────────────────
const generateLivePrediction = onCall({ region: REGION }, async (request) => {
  const { fighter1, fighter2, currentRound, scores, momentum } =
    request.data || {};

  const prompt = `Live prediction analyst. ${fighter1 || "F1"} vs ${fighter2 || "F2"} Round: ${currentRound || 1} Scores: ${scores ? JSON.stringify(scores) : "Even"} Momentum: ${momentum || "neutral"}
Return JSON: {"winProbabilityA": <0-1>, "winProbabilityB": <0-1>, "predictedOutcome": "...", "confidence": <0-1>}`;

  const fallback = {
    winProbabilityA: 0.5,
    winProbabilityB: 0.5,
    predictedOutcome: "Could go either way",
    confidence: 0.5,
  };

  return await askGeminiJSON(prompt, fallback);
});

// ─── Fight Prediction ────────────────────────────────────────────────────
const generateFightPrediction = onCall({ region: REGION }, async (request) => {
  const {
    fighter1,
    fighter2,
    fighter1Record,
    fighter2Record,
    discipline,
    event,
  } = request.data || {};

  const prompt = `Pre-fight prediction. ${fighter1 || "F1"} (${fighter1Record || "Record"}) vs ${fighter2 || "F2"} (${fighter2Record || "Record"}) Discipline: ${discipline || "MMA"} Event: ${event || "Fight Night"}
Return JSON: {"winner": "...", "method": "KO/TKO|Submission|Decision", "roundPrediction": <1-5>, "confidence": <0-1>, "breakdown": "...", "upsetPotential": <0-1>}`;

  const fallback = {
    winner: fighter1 || "Fighter 1",
    method: "Decision",
    roundPrediction: 3,
    confidence: 0.6,
    breakdown: "Close competitive fight expected.",
    upsetPotential: 0.3,
  };

  return await askGeminiJSON(prompt, fallback);
});

// ─── Chat Moderation ─────────────────────────────────────────────────────
const moderateChatMessage = onCall({ region: REGION }, async (request) => {
  const { message, userId, context } = request.data || {};
  if (!message) return { allow: true, reason: "Empty" };

  const prompt = `Live chat moderator for fight stream. Message: "${message.slice(0, 300)}" User: ${userId || "Anonymous"} Context: ${context || "Live fight"} Allow passionate discussion, mild trash talk. Block serious threats, slurs, spam.
Return JSON: {"allow": true/false, "reason": "...", "severity": "none|mild|severe", "autoMute": true/false}`;

  const fallback = {
    allow: true,
    reason: "Default allow",
    severity: "none",
    autoMute: false,
  };

  return await askGeminiJSON(prompt, fallback);
});

module.exports = {
  generateFightBreakdown,
  generateFighterBio,
  suggestMatchup,
  generateEventRecap,
  moderateComment,
  generateFanEngagementPost,
  generateSocialPost,
  generatePromoHype,
  generateFighterSpotlight,
  generateMatchupAnalysis,
  generateKimikInsight,
  generateCompetitorIntel,
  generateEmailCampaign,
  generateEcommerceStrategy,
  conveyorBeltProcess,
  wolverineRegenerate,
  generateLiveFightCommentary,
  generateLivePrediction,
  generateFightPrediction,
  moderateChatMessage,
};
