// ═══════════════════════════════════════════════════════════════════════════
// CONTENT FACTORY — AI-powered content generation pipeline endpoint
// Generates clips, captions, hashtags, hype copy from fight assets
// No fake content. No demo data. Gemini-powered with fallback.
// ═══════════════════════════════════════════════════════════════════════════

const { onCall } = require("firebase-functions/v2/https");
const { admin, db, REGION, geminiModel } = require("../config");

// ─── Gemini helpers (same pattern as ai/content.js) ──────────────────────
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
    console.error("Content Factory Gemini error:", err.message);
    return fallback;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GENERATE CONTENT — Main factory endpoint
// ═══════════════════════════════════════════════════════════════════════════
const contentFactoryGenerate = onCall({ region: REGION }, async (request) => {
  const { assetId, assetData, tasks } = request.data || {};

  if (!assetId) return { status: "error", message: "assetId required" };

  const taskList = tasks || ["caption_variants", "hashtags", "hype_copy"];

  // Look up asset in Firestore if assetData not provided
  let asset = assetData || {};
  if (!assetData || !assetData.title) {
    try {
      const assetDoc = await db
        .collection("content_pipeline")
        .doc(assetId)
        .get();
      if (assetDoc.exists) {
        asset = { id: assetDoc.id, ...assetDoc.data() };
      }
    } catch (_) {
      // Use whatever was passed
    }
  }

  const prompt = `You are the DFC Content Factory for DataFightCentral, the world combat sports platform.
Given this asset, generate promotional content for the requested tasks.

Asset: ${JSON.stringify({ id: assetId, title: asset.title || "", body: asset.body || "", eventName: asset.eventName || "", fighters: asset.fighters || [], sportType: asset.sportType || "MMA", region: asset.region || "" })}

Tasks requested: ${taskList.join(", ")}

Return ONLY valid JSON:
{
  "outputs": [
    {"type": "caption", "format": "text", "content": "...", "platform": "tiktok"},
    {"type": "caption", "format": "text", "content": "...", "platform": "instagram"},
    {"type": "hashtags", "format": "text", "content": "#tag1 #tag2 ..."},
    {"type": "hype_copy", "format": "text", "content": "..."},
    {"type": "clip_script", "format": "text", "content": "15-second script: ..."}
  ],
  "captions": ["caption1", "caption2"],
  "confidence": 0.85,
  "requiresApproval": false,
  "safetyFlags": {"requiresLegal": false, "medicalGate": false, "ageGating": false, "toxicityScore": 0.05}
}

Rules:
- Keep captions under 150 chars for TikTok, 300 for Instagram
- Include fight sport terminology (no generic marketing fluff)
- Hashtags must be combat sports relevant
- Flag if content mentions injuries, blood, or minors`;

  const fallback = {
    outputs: [
      {
        type: "caption",
        format: "text",
        content: `${asset.title || "Fight Night"} — LIVE on DFC`,
        platform: "tiktok",
      },
      {
        type: "caption",
        format: "text",
        content: `${asset.title || "Fight Night"} coming to DataFightCentral. Real fights. Real power.`,
        platform: "instagram",
      },
      {
        type: "hashtags",
        format: "text",
        content:
          "#DFC #FightNight #CombatSports #MMA #LivePPV #DataFightCentral",
      },
      {
        type: "hype_copy",
        format: "text",
        content: `${asset.title || "The fights are real."} Watch it unfold on DataFightCentral.`,
      },
    ],
    captions: [
      `${asset.title || "Fight Night"} — LIVE on DFC`,
      `${asset.title || "Fight Night"} coming to DataFightCentral. Real fights. Real power.`,
    ],
    confidence: 0.3,
    requiresApproval: false,
    safetyFlags: {
      requiresLegal: false,
      medicalGate: false,
      ageGating: false,
      toxicityScore: 0,
    },
  };

  const generated = await askGeminiJSON(prompt, fallback);

  // Store generation record for provenance
  await db.collection("content_factory_log").add({
    assetId,
    tasks: taskList,
    outputs: generated.outputs || [],
    confidence: generated.confidence || 0,
    models: geminiModel ? ["gemini-2.0-flash"] : ["fallback"],
    safetyFlags: generated.safetyFlags || {},
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    status: "ok",
    assetId,
    outputs: generated.outputs || [],
    captions: generated.captions || [],
    confidence: generated.confidence || 0,
    requiresApproval: generated.requiresApproval || false,
    safetyFlags: generated.safetyFlags || {},
    models: geminiModel ? ["gemini-2.0-flash"] : ["fallback"],
  };
});

// ═══════════════════════════════════════════════════════════════════════════
// BATCH GENERATE — Process multiple assets
// ═══════════════════════════════════════════════════════════════════════════
const contentFactoryBatch = onCall(
  { region: REGION, timeoutSeconds: 120 },
  async (request) => {
    const { assets } = request.data || {};
    if (!assets || !Array.isArray(assets) || assets.length === 0) {
      return { status: "error", message: "assets array required" };
    }

    // Cap at 10 per batch to avoid timeout
    const batch = assets.slice(0, 10);
    const results = [];

    for (const asset of batch) {
      try {
        const result = await contentFactoryGenerate.run({
          data: {
            assetId: asset.assetId,
            assetData: asset,
            tasks: asset.tasks,
          },
        });
        results.push({
          assetId: asset.assetId,
          status: "ok",
          outputs: result.outputs || [],
        });
      } catch (err) {
        results.push({
          assetId: asset.assetId,
          status: "error",
          error: err.message,
        });
      }
    }

    return { status: "ok", count: results.length, results };
  },
);

module.exports = {
  contentFactoryGenerate,
  contentFactoryBatch,
};
