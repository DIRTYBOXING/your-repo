const { ppvCommerceMetrics } = require("../../server/monitoring/server/metrics");

const FALLBACK_OFFERS = ({
  eventId,
  eventTitle,
  basePriceCents,
  sportType,
  location,
}) => {
  const fullShow = Number(basePriceCents) || 2999;
  return {
    eventId,
    generatedAt: new Date().toISOString(),
    engine: "fallback",
    offers: [
      {
        id: `offer-${eventId}-ppv`,
        type: "ppv_full_show",
        uiLabel: "Buy Full Show",
        title: `${eventTitle} Full Show`,
        description: `Live ${sportType || "combat sports"} event from ${location || "the arena"}.`,
        priceCents: fullShow,
        aiScore: 0.78,
        predictedConversion: 0.12,
        active: true,
        requiresReview: true,
        reviewStatus: "pending",
      },
      {
        id: `offer-${eventId}-highlight`,
        type: "highlight_pack",
        uiLabel: "Buy Highlights",
        title: `${eventTitle} Highlights`,
        description: "Fast replay bundle with finishes, knockdowns, and social-ready clips.",
        priceCents: Math.round(fullShow * 0.35),
        aiScore: 0.68,
        predictedConversion: 0.18,
        active: true,
        requiresReview: true,
        reviewStatus: "pending",
      },
      {
        id: `offer-${eventId}-tourism`,
        type: "tourism_bundle",
        uiLabel: "Fight Weekend Bundle",
        title: `${eventTitle} Fight Weekend`,
        description: "PPV plus venue district perks, sponsor perks, and travel upsell copy.",
        priceCents: Math.round(fullShow * 1.6),
        aiScore: 0.84,
        predictedConversion: 0.06,
        active: true,
        requiresReview: true,
        reviewStatus: "pending",
      },
    ],
  };
};

async function askForOffers(prompt) {
  try {
    const { GoogleGenerativeAI } = require("@google/generative-ai");
    const key = (process.env.GEMINI_KEY || "").trim();
    if (!key) return null;
    const genAI = new GoogleGenerativeAI(key);
    const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });
    const result = await model.generateContent(prompt);
    const text = result.response
      .text()
      .trim()
      .replace(/^```(?:json)?\n?/i, "")
      .replace(/\n?```$/i, "")
      .trim();
    return JSON.parse(text);
  } catch {
    return null;
  }
}

async function generateOfferHandler(req, res) {
  const startedAt = Date.now();
  const {
    eventId,
    eventTitle,
    description,
    basePriceCents,
    sportType,
    location,
    promoterId,
    audience = {},
  } = req.body || {};

  if (!eventId || !eventTitle || !basePriceCents) {
    return res.status(400).json({
      error: "eventId, eventTitle, and basePriceCents are required",
    });
  }

  const fallback = FALLBACK_OFFERS({
    eventId,
    eventTitle,
    basePriceCents,
    sportType,
    location,
  });

  const prompt = `You are DFC's AI Offer Engine. Return JSON only with this exact schema:
{
  "eventId": "${eventId}",
  "generatedAt": "ISO_DATE",
  "engine": "gemini",
  "offers": [
    {
      "id": "string",
      "type": "ppv_full_show|highlight_pack|tourism_bundle|poster_bundle|gym_bundle|sponsor_bundle",
      "uiLabel": "string",
      "title": "string",
      "description": "string",
      "priceCents": 0,
      "aiScore": 0.0,
      "predictedConversion": 0.0,
      "active": true,
      "requiresReview": true,
      "reviewStatus": "pending"
    }
  ]
}
Event title: ${eventTitle}
Description: ${description || ""}
Base price cents: ${basePriceCents}
Sport type: ${sportType || "MMA"}
Location: ${location || "Australia"}
Promoter: ${promoterId || "unknown"}
Audience: ${JSON.stringify(audience)}
Generate exactly 4 offers tuned for DFC PPV, posters, gyms, and tourism upsell. Use realistic pricing relative to basePriceCents.`;

  const generated = (await askForOffers(prompt)) || fallback;
  if (ppvCommerceMetrics?.offerGenerationMs) {
    ppvCommerceMetrics.offerGenerationMs.observe(
      { path: generated.engine || "fallback" },
      Date.now() - startedAt,
    );
  }
  return res.json({
    ...generated,
    requiresReview: true,
    reviewStatus: "pending",
    reviewMode: "admin_required",
  });
}

module.exports = {
  generateOfferHandler,
};
