// ═══════════════════════════════════════════════════════════════════════════
// DFC SOCIAL PUBLISHER — Autonomous Native Content Engine
// ═══════════════════════════════════════════════════════════════════════════
//
// THE ENGINE ROOM. Zero monthly costs. No n8n. No Blotato. No middlemen.
// Gemini AI → Direct Platform APIs → SendGrid → Firestore logging.
//
// REPLACES:
//   ✗ n8n Content Brain ($20/mo)     → Native Gemini 6-step pipeline
//   ✗ Blotato cross-post ($29/mo)    → Direct platform API calls
//   ✗ External webhooks              → Internal function calls
//
// PLATFORMS (10 megaphones + DFC home base):
//   1. Facebook        — Graph API v23.0 (Page posts)
//   2. Instagram       — Graph API (IG Content Publishing)
//   3. X/Twitter       — API v2
//   4. TikTok          — Connector queue (durable publish intent)
//   5. Threads         — Threads API
//   6. YouTube         — Community/manual + connector queue for media lanes
//   7. LinkedIn        — Share API
//   8. Bluesky         — AT Protocol (free, no OAuth)
//   9. Pinterest       — Connector queue (durable publish intent)
//  10. Email           — SendGrid blast
//
// FLOW:
//   Content In → Gemini AI Brain → Platform-specific variants →
//   Post to each platform → Log results → Return summary
//
// TRIGGERS (called by other functions):
//   - event_seeder.js     → publishToAllPlatforms() on new PPV event
//   - drip_scheduler.js   → publishToAllPlatforms() on countdown fire
//   - post_event.js       → publishToAllPlatforms() on replay/highlights
//   - Manual callable      → nativePublish (admin/promoter trigger)
//   - Scheduled            → scheduledContentPush (daily content)
//
// ═══════════════════════════════════════════════════════════════════════════

const { onCall, onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { admin, db, REGION, geminiModel, sgMail } = require("../config");

// ─── Platform API Environment Variables ──────────────────────────────────
// Set via: firebase functions:secrets:set <KEY_NAME>
// These are READ at runtime from process.env — $0/month, you own the keys.
//
// Facebook + Instagram: FACEBOOK_TARGET_KEY, FACEBOOK_PAGE_ACCESS_TOKEN, FACEBOOK_PAGE_ID, IG_BUSINESS_ACCOUNT_ID
// Alternate page targets: FACEBOOK_GRAY_MERCY_*, FACEBOOK_DIRTY_BOXER_*, IG_GRAY_MERCY_*, IG_DIRTY_BOXER_*
// X/Twitter:            X_API_KEY, X_API_SECRET, X_ACCESS_TOKEN, X_ACCESS_SECRET
// Threads:              THREADS_USER_ID, THREADS_ACCESS_TOKEN
// TikTok + queue lanes: SOCIAL_CONNECTOR_QUEUE_ENABLED (optional kill switch)
// YouTube:              YOUTUBE_API_KEY (community posts are limited)
// LinkedIn:             LINKEDIN_ACCESS_TOKEN, LINKEDIN_ORG_ID
// Bluesky:              BLUESKY_HANDLE, BLUESKY_APP_PASSWORD
// Email:                SENDGRID_API_KEY (already configured ✅)

const DEFAULT_PUBLISH_PLATFORMS = [
  "facebook",
  "instagram",
  "x",
  "tiktok",
  "threads",
  "youtube",
  "youtube_shorts",
  "linkedin",
  "bluesky",
  "email",
];

const PLATFORM_ALIASES = {
  all: "all",
  fb: "facebook",
  ig: "instagram",
  twitter: "x",
  tweet: "x",
  x_twitter: "x",
  tik_tok: "tiktok",
  youtube_shorts: "youtube_shorts",
  youtube_short: "youtube_shorts",
  youtube_shorts_video: "youtube_shorts",
  shorts: "youtube_shorts",
  yt_shorts: "youtube_shorts",
  yt: "youtube",
  e_mail: "email",
  mail: "email",
};

const DEFAULT_META_TARGET_KEY = "datafightcentral";

const META_TARGETS = Object.freeze({
  datafightcentral: Object.freeze({
    key: "datafightcentral",
    label: "Data Fight Central",
    ownerProfile: "Heath Ewart",
    businessPortfolio: "Dirty Boxer Australia",
    targetType: "facebook_page",
    defaultTarget: true,
    pageIdDefault: "997025300171474",
    pageIdEnv: "FACEBOOK_PAGE_ID",
    accessTokenEnv: "FACEBOOK_PAGE_ACCESS_TOKEN",
    igBusinessAccountEnv: "IG_BUSINESS_ACCOUNT_ID",
  }),
  gray_mercy_gym: Object.freeze({
    key: "gray_mercy_gym",
    label: "Gray Mercy Gym",
    ownerProfile: "Heath Ewart",
    businessPortfolio: "Gray Mercy Gym",
    targetType: "facebook_page",
    pageIdEnv: "FACEBOOK_GRAY_MERCY_PAGE_ID",
    accessTokenEnv: "FACEBOOK_GRAY_MERCY_PAGE_ACCESS_TOKEN",
    igBusinessAccountEnv: "IG_GRAY_MERCY_BUSINESS_ACCOUNT_ID",
  }),
  dirty_boxer_australia: Object.freeze({
    key: "dirty_boxer_australia",
    label: "Dirty Boxer Australia",
    ownerProfile: "Heath Ewart",
    businessPortfolio: "Dirty Boxer Australia",
    targetType: "facebook_page",
    pageIdEnv: "FACEBOOK_DIRTY_BOXER_PAGE_ID",
    accessTokenEnv: "FACEBOOK_DIRTY_BOXER_PAGE_ACCESS_TOKEN",
    igBusinessAccountEnv: "IG_DIRTY_BOXER_BUSINESS_ACCOUNT_ID",
  }),
  heath_ewart: Object.freeze({
    key: "heath_ewart",
    label: "Heath Ewart",
    ownerProfile: "Heath Ewart",
    targetType: "facebook_profile",
    automationSupported: false,
    note: "Use this as the admin login identity only. Graph API publishing must target pages.",
  }),
});

const META_TARGET_ALIASES = Object.freeze({
  datafightcentral: "datafightcentral",
  data_fight_central: "datafightcentral",
  datafight: "datafightcentral",
  dfc: "datafightcentral",
  gray_mercy_gym: "gray_mercy_gym",
  grey_mercy_gym: "gray_mercy_gym",
  gray_mercy: "gray_mercy_gym",
  grey_mercy: "gray_mercy_gym",
  graymercygym: "gray_mercy_gym",
  greymercygym: "gray_mercy_gym",
  dirty_boxer_australia: "dirty_boxer_australia",
  dirty_boxer: "dirty_boxer_australia",
  dirtyboxeraustralia: "dirty_boxer_australia",
  heath_ewart: "heath_ewart",
  heath: "heath_ewart",
});

function normalizeMetaTargetKey(targetKey) {
  if (!targetKey) return "";

  const normalized = String(targetKey)
    .trim()
    .toLowerCase()
    .replaceAll(/[^a-z0-9]+/g, "_")
    .replaceAll(/^_+/g, "")
    .replaceAll(/_+$/g, "");

  return META_TARGET_ALIASES[normalized] || normalized;
}

function getEnvValue(name) {
  return name ? process.env[name] || "" : "";
}

function resolveMetaTarget(targetKey) {
  const normalized = normalizeMetaTargetKey(targetKey);
  return META_TARGETS[normalized] || META_TARGETS[DEFAULT_META_TARGET_KEY];
}

function buildMetaPublishOptions(contentInput = {}) {
  const overrides = extractMetaTargetOverrides(contentInput);

  return {
    metaTargetKey:
      overrides.metaTargetKey ||
      process.env.FACEBOOK_TARGET_KEY ||
      DEFAULT_META_TARGET_KEY,
    facebookPageId: overrides.facebookPageId,
    facebookAccessToken: overrides.facebookAccessToken,
    igBusinessAccountId: overrides.igBusinessAccountId,
  };
}

function extractMetaTargetOverrides(input = {}) {
  return {
    metaTargetKey: input.metaTargetKey || input.facebookTargetKey || "",
    facebookTargetKey: input.facebookTargetKey || input.metaTargetKey || "",
    facebookPageId: input.facebookPageId || "",
    facebookPageLabel: input.facebookPageLabel || "",
    facebookOwnerProfile: input.facebookOwnerProfile || "",
    facebookBusinessPortfolio: input.facebookBusinessPortfolio || "",
    facebookAccessToken: input.facebookAccessToken || "",
    igBusinessAccountId: input.igBusinessAccountId || "",
  };
}

function buildMetaTargetStatus() {
  const status = {};

  for (const target of Object.values(META_TARGETS)) {
    if (target.targetType !== "facebook_page") {
      status[target.key] = {
        label: target.label,
        ownerProfile: target.ownerProfile,
        businessPortfolio: target.businessPortfolio || "",
        targetType: target.targetType,
        automationSupported: false,
        note: target.note,
      };
      continue;
    }

    const pageId = getEnvValue(target.pageIdEnv) || target.pageIdDefault || "";
    const accessToken = getEnvValue(target.accessTokenEnv);
    const igBusinessAccountId = getEnvValue(target.igBusinessAccountEnv);

    status[target.key] = {
      label: target.label,
      ownerProfile: target.ownerProfile,
      businessPortfolio: target.businessPortfolio || "",
      targetType: target.targetType,
      defaultTarget: !!target.defaultTarget,
      connected: !!(pageId && accessToken),
      instagramConnected: !!(igBusinessAccountId && accessToken),
      pageId,
    };
  }

  return status;
}

function normalizePlatformName(platform) {
  if (!platform) return "";

  const normalized = String(platform)
    .trim()
    .toLowerCase()
    .replaceAll(/[\s-]+/g, "_");

  return PLATFORM_ALIASES[normalized] || normalized;
}

function normalizeRequestedPlatforms(platforms) {
  let rawPlatforms = [];
  if (Array.isArray(platforms)) {
    rawPlatforms = platforms;
  } else if (typeof platforms === "string" && platforms.trim()) {
    rawPlatforms = [platforms];
  }

  if (rawPlatforms.length === 0) {
    return [...DEFAULT_PUBLISH_PLATFORMS];
  }

  const normalized = [];

  for (const rawPlatform of rawPlatforms) {
    const platform = normalizePlatformName(rawPlatform);
    if (!platform) continue;
    if (platform === "all") {
      return [...DEFAULT_PUBLISH_PLATFORMS];
    }
    if (!normalized.includes(platform)) {
      normalized.push(platform);
    }
  }

  return normalized.length > 0 ? normalized : [...DEFAULT_PUBLISH_PLATFORMS];
}

function variantLookupOrder(platform) {
  switch (platform) {
    case "facebook":
      return ["facebook"];
    case "instagram":
      return ["instagram", "facebook"];
    case "x":
      return ["x", "twitter", "threads", "facebook"];
    case "tiktok":
      return ["tiktok", "instagram", "x", "facebook"];
    case "threads":
      return ["threads", "x", "facebook"];
    case "youtube":
      return ["youtube", "youtube_shorts", "facebook"];
    case "youtube_shorts":
      return ["youtube_shorts", "youtube", "tiktok", "instagram"];
    case "linkedin":
      return ["linkedin", "facebook"];
    case "bluesky":
      return ["bluesky", "x", "threads"];
    case "pinterest":
      return ["pinterest", "instagram", "facebook"];
    default:
      return [platform, "facebook"];
  }
}

function resolveVariantText(variants, platform, fallbackText) {
  for (const key of variantLookupOrder(platform)) {
    const value = variants[key];
    if (typeof value === "string" && value.trim().length > 0) {
      return value;
    }
  }

  return fallbackText;
}

function connectorQueueEnabled() {
  return process.env.SOCIAL_CONNECTOR_QUEUE_ENABLED !== "false";
}

async function queueConnectorPublish({
  platform,
  caption,
  mediaUrl,
  metadata = {},
}) {
  if (!connectorQueueEnabled()) {
    return {
      success: false,
      platform,
      deliveryState: "failed",
      error: "Connector publish queue disabled",
    };
  }

  const ref = await db.collection("connector_publish_queue").add({
    platform,
    caption,
    mediaUrl,
    metadata,
    status: "pending",
    retryCount: 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    success: true,
    platform,
    deliveryState: "queued",
    platformPostId: ref.id,
    queueId: ref.id,
  };
}

// ─── Platform Character Limits ───────────────────────────────────────────
const PLATFORM_LIMITS = {
  facebook: { maxLength: 63206, postType: "text+image", emoji: "📘" },
  instagram: { maxLength: 2200, postType: "image+caption", emoji: "📸" },
  x: { maxLength: 280, postType: "text+image", emoji: "🐦" },
  tiktok: { maxLength: 2200, postType: "video+caption", emoji: "🎵" },
  threads: { maxLength: 500, postType: "text+image", emoji: "🧵" },
  youtube: { maxLength: 5000, postType: "community", emoji: "📺" },
  youtube_shorts: { maxLength: 100, postType: "video+hook", emoji: "🎬" },
  linkedin: { maxLength: 3000, postType: "text+image", emoji: "💼" },
  bluesky: { maxLength: 300, postType: "text+image", emoji: "🦋" },
  pinterest: { maxLength: 500, postType: "image+pin", emoji: "📌" },
  email: { maxLength: 99999, postType: "html", emoji: "📧" },
};

// ─── Brand Tone Presets (from content_brain.js) ──────────────────────────
const TONE_PRESETS = {
  hype: "High energy, fight night electricity. Short punchy sentences. Use fire emojis sparingly.",
  analytical:
    "Data-driven, stat-heavy, fight IQ focused. No hype — just facts and breakdowns.",
  motivational:
    "Warrior mentality. Training grind. Overcome adversity. Personal transformation.",
  news: "Clean reporting. Who/what/when/where. Attribution matters. No editorializing.",
  edgy: "Hot takes. Controversial opinions. Challenge the mainstream. Provocative but never hateful.",
  underground:
    "Raw, unfiltered, gym-floor language. Insider terminology. No corporate polish.",
};

// ═══════════════════════════════════════════════════════════════════════════
// GEMINI AI BRAIN — 6-Step Content Generation Pipeline
// ═══════════════════════════════════════════════════════════════════════════
// Replaces the entire n8n Content Brain workflow (6 OpenAI nodes)
// with a single Gemini call that produces platform-specific variants.

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
    console.error("[SocialPublisher] Gemini error:", err.message);
    return fallback;
  }
}

/**
 * AI Content Brain — Generates platform-optimized content variants
 *
 * @param {string} contentInput.title - Event/content title
 * @param {string} contentInput.description - Description or body text
 * @param {string} contentInput.mediaUrl - Image/video URL
 * @param {string} contentInput.buyLink - Purchase/action link
 * @param {string} contentInput.tone - Brand tone preset key
 * @param {string} contentInput.contentType - ppv_promo|countdown|results|news|highlight
 * @returns {Object} Platform-keyed content variants
 */
async function generateContentVariants(contentInput) {
  const {
    title = "FIGHT NIGHT",
    description = "",
    mediaUrl = "",
    mediaPlan = {},
    buyLink = "",
    tone = "hype",
    contentType = "ppv_promo",
    price = "",
    eventDate = "",
    promoterName = "",
    fighters = [],
  } = contentInput;
  const mediaAssetUrls = Array.isArray(mediaPlan.assetUrls)
    ? mediaPlan.assetUrls.filter(
        (url) => typeof url === "string" && url.trim().length > 0,
      )
    : [];
  const mediaAssetTypes = Array.isArray(mediaPlan.assets)
    ? [...new Set(mediaPlan.assets.map((asset) => asset?.type).filter(Boolean))]
    : [];
  const hasSourceAssets = mediaAssetUrls.length > 0;
  const sourceAssetLabel =
    mediaAssetUrls.length === 1 ? "source asset" : "source assets";
  let mediaSummary = "No media";
  if (hasSourceAssets) {
    mediaSummary = `Yes (${mediaAssetUrls.length} ${sourceAssetLabel} attached)`;
  } else if (mediaUrl) {
    mediaSummary = "Yes (image/poster attached)";
  }

  const toneInstruction = TONE_PRESETS[tone] || TONE_PRESETS.hype;

  const prompt = `You are the DFC Content Brain — the AI engine for DataFightCentral, the world's combat sports platform.

TASK: Generate social media posts for ALL platforms from this content.

INPUT:
- Title: ${title}
- Type: ${contentType}
- Description: ${description}
- Price: ${price}
- Event Date: ${eventDate}
- Promoter: ${promoterName}
- Fighters: ${fighters.join(", ") || "TBA"}
- Buy Link: ${buyLink}
- Media: ${mediaSummary}
- Publishable Media: ${mediaUrl || mediaPlan.primaryPublishableAssetUrl ? "Yes" : "No"}
- Asset Types: ${mediaAssetTypes.length > 0 ? mediaAssetTypes.join(", ") : "None"}
- Source Asset URLs: ${hasSourceAssets ? mediaAssetUrls.join(", ") : "None"}

BRAND TONE: ${toneInstruction}

PLATFORM REQUIREMENTS:
- facebook: Up to 63,206 chars. Longer form, storytelling. Include buy link.
- instagram: Up to 2,200 chars. Visual-first caption. Hashtag heavy (20-30). Include CTA.
- x: EXACTLY under 280 chars. Punchy, urgent. Include link if room.
- tiktok: Under 2,200 chars. Hook in the first sentence. Feels like a fight clip caption.
- threads: Under 500 chars. Conversational, community feel.
- youtube: Under 5,000 chars. Community post style. Engagement question.
- youtube_shorts: Under 100 chars. Short hook/title for a vertical clip.
- linkedin: Under 3,000 chars. Professional angle — business of combat sports.
- bluesky: Under 300 chars. Clean, direct, fight community tone.
- pinterest: Under 500 chars. Image-led promo copy with a clean CTA.
- email_subject: Under 60 chars. High open-rate subject line.
- email_body: HTML email body. Bold headline, image placeholder, CTA button, unsubscribe link.

Return ONLY valid JSON:
{
  "facebook": "post text here...",
  "instagram": "caption with #hashtags...",
  "x": "short punchy tweet...",
  "tiktok": "vertical clip caption...",
  "threads": "thread post...",
  "youtube": "community post...",
  "youtube_shorts": "short clip hook...",
  "linkedin": "professional post...",
  "bluesky": "short post...",
  "pinterest": "pin copy...",
  "email_subject": "subject line",
  "email_body": "<html>email body</html>",
  "hashtags": ["#DFC", "#CombatSports", "..."],
  "viralScore": 0.85,
  "emotionalFrame": "excitement|urgency|fomo|pride|curiosity"
}

RULES:
- Every post MUST include the buy link where platform allows
- Never use generic marketing — this is COMBAT SPORTS, be authentic
- No lies, no fake stats, no fabricated quotes
- Hashtags must be real, trending combat sports tags
- Email must have proper HTML with inline styles`;

  const fallback = _buildFallbackContent(contentInput);
  return await askGeminiJSON(prompt, fallback);
}

/**
 * Fallback content when Gemini is unavailable — still posts, just not AI-optimized
 */
function _buildFallbackContent(input) {
  const { title, buyLink, price, description } = input;
  const t = title || "FIGHT NIGHT";
  const link = buyLink || "https://datafightcentral.com";
  const priceTag = price ? ` — PPV $${price}` : "";
  const desc = description ? ` ${description}` : "";
  const fallbackEmailBody = desc || "The fights are real. The platform is DFC.";
  const priceMarkup = price
    ? `<p style="text-align:center;font-size:24px;color:#00ff88;font-weight:bold;">PPV $${price}</p>`
    : "";

  return {
    facebook: `🥊 ${t}${priceTag}\n\n${desc}\n\n🎟️ Watch LIVE: ${link}\n\n#DFC #CombatSports #PPV #FightNight`,
    instagram: `🥊 ${t}${priceTag}\n\n${desc}\n\n🎟️ Link in bio or tap: ${link}\n\n#DFC #CombatSports #PPV #MMA #Boxing #FightNight #LivePPV #DataFightCentral #FightWeek #KnockOut #Warrior #CombatArts #FightFans #MMAFighting #BoxingDay #BKFC #BareKnuckle #UFC #Bellator #ONE`,
    x: `🥊 ${t}${priceTag} — LIVE on @DataFightCentral\n\n${link}`,
    tiktok: `🥊 ${t}${priceTag}\n${desc}\n\nFull fight-night link: ${link}`,
    threads: `🥊 ${t} is coming.${priceTag}\n\nWho's watching? 👀\n\n${link}`,
    youtube: `🥊 ${t}${priceTag}\n\n${desc}\n\nWho wins this card? Drop your predictions below 👇\n\n🎟️ ${link}`,
    youtube_shorts: `🥊 ${t}${priceTag} | Watch on DFC`,
    linkedin: `Combat sports update: ${t}${priceTag}\n\n${desc}\n\nThe combat sports industry continues to grow — and DataFightCentral is at the center.\n\n${link}`,
    bluesky: `🥊 ${t}${priceTag} — LIVE on DFC\n\n${link}`,
    pinterest: `🥊 ${t}${priceTag}\n\n${desc}\n\nWatch and replay on DFC: ${link}`,
    email_subject: `🥊 ${t} — Don't Miss This Fight`,
    email_body: `<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;background:#111;color:#fff;padding:20px;border-radius:12px;"><h1 style="color:#00ff88;text-align:center;">🥊 ${t}</h1><p style="text-align:center;font-size:18px;">${fallbackEmailBody}</p>${priceMarkup}<div style="text-align:center;margin:20px 0;"><a href="${link}" style="background:#00ff88;color:#000;padding:15px 40px;text-decoration:none;border-radius:8px;font-weight:bold;font-size:18px;">WATCH NOW</a></div><p style="text-align:center;font-size:12px;color:#666;">DataFightCentral — The Promoter of Promoters<br/><a href="https://datafightcentral.com/unsubscribe" style="color:#666;">Unsubscribe</a></p></div>`,
    hashtags: [
      "#DFC",
      "#CombatSports",
      "#PPV",
      "#MMA",
      "#Boxing",
      "#FightNight",
      "#DataFightCentral",
    ],
    viralScore: 0.3,
    emotionalFrame: "excitement",
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// PLATFORM PUBLISHERS — Direct API calls to each platform
// ═══════════════════════════════════════════════════════════════════════════
// Each returns { success: bool, platformPostId: string, error?: string }

// ─── 1. FACEBOOK — Graph API v23.0 ──────────────────────────────────────
async function postToFacebook(text, mediaUrl, options = {}) {
  const target = resolveMetaTarget(options.metaTargetKey);

  if (target.targetType !== "facebook_page") {
    return {
      success: false,
      platform: "facebook",
      facebookTargetKey: target.key,
      facebookTargetLabel: target.label,
      targetOwnerProfile: target.ownerProfile,
      error:
        target.note || `Facebook target ${target.label} is not publishable`,
    };
  }

  const pageId =
    options.facebookPageId ||
    getEnvValue(target.pageIdEnv) ||
    target.pageIdDefault ||
    "";
  const token =
    options.facebookAccessToken || getEnvValue(target.accessTokenEnv);
  if (!pageId || !token) {
    return {
      success: false,
      error: `Facebook target ${target.label} is not configured`,
      platform: "facebook",
      facebookTargetKey: target.key,
      facebookTargetLabel: target.label,
      facebookBusinessPortfolio: target.businessPortfolio || "",
      facebookPageId: pageId,
      targetOwnerProfile: target.ownerProfile,
    };
  }

  try {
    let endpoint, body;

    if (
      mediaUrl &&
      (mediaUrl.includes(".jpg") ||
        mediaUrl.includes(".png") ||
        mediaUrl.includes("cloudinary"))
    ) {
      // Photo post
      endpoint = `https://graph.facebook.com/v23.0/${pageId}/photos`;
      body = JSON.stringify({
        url: mediaUrl,
        message: text,
        access_token: token,
      });
    } else {
      // Text post (or video link)
      endpoint = `https://graph.facebook.com/v23.0/${pageId}/feed`;
      body = JSON.stringify({ message: text, access_token: token });
    }

    const res = await fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body,
    });

    const data = await res.json();
    if (data.error) throw new Error(data.error.message);

    return {
      success: true,
      platform: "facebook",
      platformPostId: data.id || data.post_id,
      facebookTargetKey: target.key,
      facebookTargetLabel: target.label,
      facebookBusinessPortfolio: target.businessPortfolio || "",
      facebookPageId: pageId,
      targetOwnerProfile: target.ownerProfile,
    };
  } catch (err) {
    return {
      success: false,
      platform: "facebook",
      error: err.message,
      facebookTargetKey: target.key,
      facebookTargetLabel: target.label,
      facebookBusinessPortfolio: target.businessPortfolio || "",
      facebookPageId: pageId,
      targetOwnerProfile: target.ownerProfile,
    };
  }
}

// ─── 2. INSTAGRAM — Graph API Content Publishing ─────────────────────────
async function postToInstagram(caption, mediaUrl, options = {}) {
  const target = resolveMetaTarget(options.metaTargetKey);

  if (target.targetType !== "facebook_page") {
    return {
      success: false,
      platform: "instagram",
      instagramTargetKey: target.key,
      instagramTargetLabel: target.label,
      instagramBusinessPortfolio: target.businessPortfolio || "",
      targetOwnerProfile: target.ownerProfile,
      error:
        target.note || `Instagram target ${target.label} is not publishable`,
    };
  }

  const igAccountId =
    options.igBusinessAccountId || getEnvValue(target.igBusinessAccountEnv);
  const token =
    options.facebookAccessToken || getEnvValue(target.accessTokenEnv);
  if (!igAccountId || !token) {
    return {
      success: false,
      error: `Instagram target ${target.label} is not configured`,
      platform: "instagram",
      instagramTargetKey: target.key,
      instagramTargetLabel: target.label,
      instagramBusinessPortfolio: target.businessPortfolio || "",
      targetOwnerProfile: target.ownerProfile,
    };
  }

  if (!mediaUrl)
    return {
      success: false,
      error: "Instagram requires an image",
      platform: "instagram",
    };

  try {
    // Step 1: Create media container
    const createRes = await fetch(
      `https://graph.facebook.com/v23.0/${igAccountId}/media`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          image_url: mediaUrl,
          caption,
          access_token: token,
        }),
      },
    );
    const createData = await createRes.json();
    if (createData.error) throw new Error(createData.error.message);

    const containerId = createData.id;

    // Step 2: Publish the container
    const publishRes = await fetch(
      `https://graph.facebook.com/v23.0/${igAccountId}/media_publish`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          creation_id: containerId,
          access_token: token,
        }),
      },
    );
    const publishData = await publishRes.json();
    if (publishData.error) throw new Error(publishData.error.message);

    return {
      success: true,
      platform: "instagram",
      platformPostId: publishData.id,
      instagramTargetKey: target.key,
      instagramTargetLabel: target.label,
      instagramBusinessPortfolio: target.businessPortfolio || "",
      igBusinessAccountId: igAccountId,
      targetOwnerProfile: target.ownerProfile,
    };
  } catch (err) {
    return {
      success: false,
      platform: "instagram",
      error: err.message,
      instagramTargetKey: target.key,
      instagramTargetLabel: target.label,
      instagramBusinessPortfolio: target.businessPortfolio || "",
      igBusinessAccountId: igAccountId,
      targetOwnerProfile: target.ownerProfile,
    };
  }
}

// ─── 3. X / TWITTER — API v2 ────────────────────────────────────────────
async function postToX(text) {
  const apiKey = process.env.X_API_KEY;
  const apiSecret = process.env.X_API_SECRET;
  const accessToken = process.env.X_ACCESS_TOKEN;
  const accessSecret = process.env.X_ACCESS_SECRET;
  if (!apiKey || !accessToken)
    return { success: false, error: "X/Twitter not configured", platform: "x" };

  try {
    // OAuth 1.0a signature for X API v2
    const { createHmac, randomBytes } = require("node:crypto");
    const timestamp = Math.floor(Date.now() / 1000).toString();
    const nonce = randomBytes(16).toString("hex");

    const params = {
      oauth_consumer_key: apiKey,
      oauth_nonce: nonce,
      oauth_signature_method: "HMAC-SHA1",
      oauth_timestamp: timestamp,
      oauth_token: accessToken,
      oauth_version: "1.0",
    };

    // Build signature base string
    const paramString = Object.keys(params)
      .sort((left, right) => left.localeCompare(right))
      .map((k) => `${encodeURIComponent(k)}=${encodeURIComponent(params[k])}`)
      .join("&");

    const baseString = `POST&${encodeURIComponent("https://api.twitter.com/2/tweets")}&${encodeURIComponent(paramString)}`;
    const signingKey = `${encodeURIComponent(apiSecret)}&${encodeURIComponent(accessSecret)}`;
    const signature = createHmac("sha1", signingKey)
      .update(baseString)
      .digest("base64");

    params.oauth_signature = signature;

    const authHeader =
      "OAuth " +
      Object.keys(params)
        .sort((left, right) => left.localeCompare(right))
        .map(
          (k) => `${encodeURIComponent(k)}="${encodeURIComponent(params[k])}"`,
        )
        .join(", ");

    const res = await fetch("https://api.twitter.com/2/tweets", {
      method: "POST",
      headers: {
        Authorization: authHeader,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ text: text.substring(0, 280) }),
    });

    const data = await res.json();
    if (data.errors) throw new Error(data.errors[0]?.message || "X API error");

    return { success: true, platform: "x", platformPostId: data.data?.id };
  } catch (err) {
    return { success: false, platform: "x", error: err.message };
  }
}

// ─── 4. TIKTOK — Connector Queue ────────────────────────────────────────
async function postToTikTok(text, mediaUrl, metadata = {}) {
  if (!mediaUrl) {
    return {
      success: false,
      platform: "tiktok",
      deliveryState: "failed",
      error: "TikTok requires media for publish queue",
    };
  }

  return queueConnectorPublish({
    platform: "tiktok",
    caption: text.substring(0, PLATFORM_LIMITS.tiktok.maxLength),
    mediaUrl,
    metadata,
  });
}

// ─── 5. THREADS — Threads Publishing API ─────────────────────────────────
async function postToThreads(text, mediaUrl) {
  const userId = process.env.THREADS_USER_ID;
  const token = process.env.THREADS_ACCESS_TOKEN;
  if (!userId || !token)
    return {
      success: false,
      error: "Threads not configured",
      platform: "threads",
    };

  try {
    const body = { text: text.substring(0, 500), access_token: token };
    if (mediaUrl) {
      body.media_type = "IMAGE";
      body.image_url = mediaUrl;
    } else {
      body.media_type = "TEXT";
    }

    // Step 1: Create container
    const createRes = await fetch(
      `https://graph.threads.net/v1.0/${userId}/threads`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      },
    );
    const createData = await createRes.json();
    if (createData.error) throw new Error(createData.error.message);

    // Step 2: Publish
    const publishRes = await fetch(
      `https://graph.threads.net/v1.0/${userId}/threads_publish`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          creation_id: createData.id,
          access_token: token,
        }),
      },
    );
    const publishData = await publishRes.json();
    if (publishData.error) throw new Error(publishData.error.message);

    return {
      success: true,
      platform: "threads",
      platformPostId: publishData.id,
    };
  } catch (err) {
    return { success: false, platform: "threads", error: err.message };
  }
}

// ─── 6. YOUTUBE — Community/manual + connector queue ─────────────────────
async function postToYouTube(text, mediaUrl, metadata = {}) {
  const apiKey = process.env.YOUTUBE_API_KEY;

  if (mediaUrl) {
    return queueConnectorPublish({
      platform: "youtube",
      caption: text.substring(0, PLATFORM_LIMITS.youtube.maxLength),
      mediaUrl,
      metadata: {
        ...metadata,
        publishMode: "connector_queue",
      },
    });
  }

  if (!apiKey) {
    return {
      success: false,
      error: "YouTube not configured for community publishing",
      platform: "youtube",
      deliveryState: "failed",
    };
  }

  // YouTube Data API doesn't support creating community posts programmatically yet
  // Store for manual posting or future API support
  return {
    success: false,
    platform: "youtube",
    deliveryState: "manual",
    error: "Stored as pending — YouTube community posts API limited",
    pendingManual: true,
    content: text.substring(0, 5000),
  };
}

// ─── 7. YOUTUBE SHORTS — Connector Queue ────────────────────────────────
async function postToYouTubeShorts(text, mediaUrl, metadata = {}) {
  if (!mediaUrl) {
    return {
      success: false,
      platform: "youtube_shorts",
      deliveryState: "failed",
      error: "YouTube Shorts requires media for publish queue",
    };
  }

  return queueConnectorPublish({
    platform: "youtube_shorts",
    caption: text.substring(0, PLATFORM_LIMITS.youtube_shorts.maxLength),
    mediaUrl,
    metadata,
  });
}

// ─── 8. LINKEDIN — Share API v2 ─────────────────────────────────────────
async function postToLinkedIn(text, mediaUrl) {
  const token = process.env.LINKEDIN_ACCESS_TOKEN;
  const orgId = process.env.LINKEDIN_ORG_ID;
  if (!token)
    return {
      success: false,
      error: "LinkedIn not configured",
      platform: "linkedin",
    };

  try {
    const author = orgId ? `urn:li:organization:${orgId}` : "urn:li:person:me";

    const postBody = {
      author,
      lifecycleState: "PUBLISHED",
      specificContent: {
        "com.linkedin.ugc.ShareContent": {
          shareCommentary: { text: text.substring(0, 3000) },
          shareMediaCategory: mediaUrl ? "ARTICLE" : "NONE",
          ...(mediaUrl
            ? {
                media: [
                  {
                    status: "READY",
                    originalUrl: mediaUrl,
                  },
                ],
              }
            : {}),
        },
      },
      visibility: { "com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC" },
    };

    const res = await fetch("https://api.linkedin.com/v2/ugcPosts", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
        "X-Restli-Protocol-Version": "2.0.0",
      },
      body: JSON.stringify(postBody),
    });

    const data = await res.json();
    if (res.status >= 400)
      throw new Error(data.message || `LinkedIn API ${res.status}`);

    return { success: true, platform: "linkedin", platformPostId: data.id };
  } catch (err) {
    return { success: false, platform: "linkedin", error: err.message };
  }
}

// ─── 9. BLUESKY — AT Protocol (FREE — no OAuth, just app password) ──────
async function postToBluesky(text) {
  const handle = process.env.BLUESKY_HANDLE;
  const appPassword = process.env.BLUESKY_APP_PASSWORD;
  if (!handle || !appPassword)
    return {
      success: false,
      error: "Bluesky not configured",
      platform: "bluesky",
    };

  try {
    // Step 1: Create session (login)
    const sessionRes = await fetch(
      "https://bsky.social/xrpc/com.atproto.server.createSession",
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ identifier: handle, password: appPassword }),
      },
    );
    const session = await sessionRes.json();
    if (session.error) throw new Error(session.message || session.error);

    // Step 2: Create post
    const postRes = await fetch(
      "https://bsky.social/xrpc/com.atproto.repo.createRecord",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${session.accessJwt}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          repo: session.did,
          collection: "app.bsky.feed.post",
          record: {
            text: text.substring(0, 300),
            createdAt: new Date().toISOString(),
            langs: ["en"],
          },
        }),
      },
    );
    const postData = await postRes.json();
    if (postData.error) throw new Error(postData.message || postData.error);

    return { success: true, platform: "bluesky", platformPostId: postData.uri };
  } catch (err) {
    return { success: false, platform: "bluesky", error: err.message };
  }
}

// ─── 10. PINTEREST — Connector Queue ─────────────────────────────────────
async function postToPinterest(text, mediaUrl, metadata = {}) {
  if (!mediaUrl) {
    return {
      success: false,
      platform: "pinterest",
      deliveryState: "failed",
      error: "Pinterest requires media for publish queue",
    };
  }

  return queueConnectorPublish({
    platform: "pinterest",
    caption: text.substring(0, PLATFORM_LIMITS.pinterest.maxLength),
    mediaUrl,
    metadata,
  });
}

// ─── 11. EMAIL — SendGrid Blast ──────────────────────────────────────────
async function sendEmailBlast(subject, htmlBody, listTag) {
  if (!sgMail)
    return {
      success: false,
      error: "SendGrid not configured",
      platform: "email",
    };

  try {
    // Get subscriber emails from Firestore
    const subsSnap = await db
      .collection("email_subscribers")
      .where("active", "==", true)
      .limit(1000)
      .get();

    if (subsSnap.empty) {
      // Fallback: get users who opted into emails
      const usersSnap = await db
        .collection("users")
        .where("emailNotifications", "==", true)
        .limit(1000)
        .get();

      if (usersSnap.empty) {
        return {
          success: false,
          error: "No subscribers found",
          platform: "email",
        };
      }

      const emails = usersSnap.docs
        .map((d) => d.data().email)
        .filter(Boolean)
        .filter((e) => e.includes("@"));

      if (emails.length === 0) {
        return {
          success: false,
          error: "No valid email addresses",
          platform: "email",
        };
      }

      // SendGrid batch (up to 1000 per call)
      const msg = {
        to: emails,
        from: { email: "info@datafightcentral.com", name: "DataFight Central" },
        subject,
        html: htmlBody,
        trackingSettings: {
          clickTracking: { enable: true },
          openTracking: { enable: true },
        },
      };

      await sgMail.sendMultiple(msg);
      return { success: true, platform: "email", sent: emails.length };
    }

    const emails = subsSnap.docs
      .map((d) => d.data().email)
      .filter(Boolean)
      .filter((e) => e.includes("@"));

    if (emails.length === 0) {
      return {
        success: false,
        error: "No valid subscriber emails",
        platform: "email",
      };
    }

    const msg = {
      to: emails,
      from: { email: "info@datafightcentral.com", name: "DataFight Central" },
      subject,
      html: htmlBody,
      trackingSettings: {
        clickTracking: { enable: true },
        openTracking: { enable: true },
      },
    };

    await sgMail.sendMultiple(msg);
    return { success: true, platform: "email", sent: emails.length };
  } catch (err) {
    return { success: false, platform: "email", error: err.message };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MASTER PUBLISH — The Engine Room
// ═══════════════════════════════════════════════════════════════════════════
// This is the main function. Everything else feeds into this.
// Call it from event_seeder, drip_scheduler, manual trigger, etc.

/**
 * Publish content to all configured platforms
 *
 * @param {Object} contentInput
 * @param {string} contentInput.title - Content title
 * @param {string} contentInput.description - Description text
 * @param {string} contentInput.mediaUrl - Image/poster URL
 * @param {string} contentInput.buyLink - Purchase link
 * @param {string} contentInput.tone - Tone preset (hype/news/edgy/etc)
 * @param {string} contentInput.contentType - ppv_promo|countdown|results|news
 * @param {string[]} contentInput.platforms - Specific platforms (or all)
 * @param {string} contentInput.sourceFunction - Which function triggered this
 * @param {string} contentInput.sourceId - Event/content ID for tracing
 * @returns {Object} Results per platform
 */
async function publishToAllPlatforms(contentInput) {
  const startTime = Date.now();
  const publishId = `pub_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
  const mediaPlan =
    contentInput.mediaPlan && typeof contentInput.mediaPlan === "object"
      ? contentInput.mediaPlan
      : {};
  const publishableMediaUrl =
    contentInput.mediaUrl || mediaPlan.primaryPublishableAssetUrl || "";
  const previewMediaUrl =
    mediaPlan.primaryPreviewAssetUrl ||
    mediaPlan.primaryAssetUrl ||
    publishableMediaUrl ||
    contentInput.mediaUrl ||
    "";
  const mediaUrls = Array.isArray(mediaPlan.assetUrls)
    ? mediaPlan.assetUrls
    : [];

  console.log(`[SocialPublisher] ═══ ENGINE START: ${publishId} ═══`);
  console.log(`[SocialPublisher] Title: "${contentInput.title}"`);
  console.log(
    `[SocialPublisher] Source: ${contentInput.sourceFunction || "manual"}`,
  );

  // ── Step 1: Generate AI content variants ──
  console.log(
    "[SocialPublisher] Step 1/4 — Gemini AI Brain generating content...",
  );
  const variants = await Promise.resolve(generateContentVariants(contentInput));

  // ── Step 2: Determine which platforms to post to ──
  const requestedPlatforms = normalizeRequestedPlatforms(
    contentInput.platforms,
  );

  console.log(
    `[SocialPublisher] Step 2/4 — Publishing to ${requestedPlatforms.length} platforms...`,
  );

  // ── Step 3: Fire to all platforms in parallel ──
  const results = {};
  const promises = [];
  const metaPublishOptions = buildMetaPublishOptions(contentInput);

  for (const platform of requestedPlatforms) {
    const text = resolveVariantText(
      variants,
      platform,
      contentInput.description || contentInput.title || "DFC publish payload",
    );
    const mediaUrl = publishableMediaUrl;
    const publishMetadata = {
      publishId,
      title: contentInput.title || "",
      sourceFunction: contentInput.sourceFunction || "manual",
      sourceId: contentInput.sourceId || "",
      buyLink: contentInput.buyLink || "",
      posterUrl: mediaPlan.posterUrl || "",
      thumbnailUrl: mediaPlan.thumbnailUrl || "",
      assetUrls: mediaUrls,
      mediaPlan,
    };

    switch (platform) {
      case "facebook":
        promises.push(
          postToFacebook(text, mediaUrl, metaPublishOptions).then(
            (r) => (results.facebook = r),
          ),
        );
        break;
      case "instagram":
        promises.push(
          postToInstagram(text, mediaUrl, metaPublishOptions).then(
            (r) => (results.instagram = r),
          ),
        );
        break;
      case "x":
        promises.push(postToX(text).then((r) => (results.x = r)));
        break;
      case "tiktok":
        promises.push(
          postToTikTok(text, mediaUrl, publishMetadata).then(
            (r) => (results.tiktok = r),
          ),
        );
        break;
      case "threads":
        promises.push(
          postToThreads(text, mediaUrl).then((r) => (results.threads = r)),
        );
        break;
      case "youtube":
        promises.push(
          postToYouTube(text, mediaUrl, publishMetadata).then(
            (r) => (results.youtube = r),
          ),
        );
        break;
      case "youtube_shorts":
        promises.push(
          postToYouTubeShorts(text, mediaUrl, publishMetadata).then(
            (r) => (results.youtube_shorts = r),
          ),
        );
        break;
      case "linkedin":
        promises.push(
          postToLinkedIn(text, mediaUrl).then((r) => (results.linkedin = r)),
        );
        break;
      case "bluesky":
        promises.push(postToBluesky(text).then((r) => (results.bluesky = r)));
        break;
      case "pinterest":
        promises.push(
          postToPinterest(text, mediaUrl, publishMetadata).then(
            (r) => (results.pinterest = r),
          ),
        );
        break;
      case "email":
        promises.push(
          sendEmailBlast(
            variants.email_subject || `🥊 ${contentInput.title}`,
            variants.email_body || `<p>${text}</p>`,
            contentInput.contentType || "general",
          ).then((r) => (results.email = r)),
        );
        break;
      default:
        results[platform] = {
          success: false,
          platform,
          deliveryState: "failed",
          error: `Unsupported platform: ${platform}`,
        };
        break;
    }
  }

  await Promise.allSettled(promises);

  // ── Step 4: Log everything to Firestore ──
  const publishedCount = Object.values(results).filter(
    (r) => r.success && (r.deliveryState || "published") === "published",
  ).length;
  const queuedCount = Object.values(results).filter(
    (r) => r.success && r.deliveryState === "queued",
  ).length;
  const manualCount = Object.values(results).filter(
    (r) => r.pendingManual || r.deliveryState === "manual",
  ).length;
  const successCount = publishedCount + queuedCount;
  const failCount = Object.values(results).filter(
    (r) => !r.success && !r.pendingManual && r.deliveryState !== "manual",
  ).length;
  const elapsed = Date.now() - startTime;

  console.log(`[SocialPublisher] Step 3/4 — Logging to Firestore...`);

  const logDoc = {
    publishId,
    title: contentInput.title || "",
    contentType: contentInput.contentType || "general",
    sourceFunction: contentInput.sourceFunction || "manual",
    sourceId: contentInput.sourceId || "",
    mediaUrl: publishableMediaUrl,
    previewMediaUrl,
    mediaUrls,
    mediaPlan,
    buyLink: contentInput.buyLink || "",
    tone: contentInput.tone || "hype",
    platforms: requestedPlatforms,
    results,
    aiVariants: variants,
    viralScore: variants.viralScore || 0,
    emotionalFrame: variants.emotionalFrame || "",
    publishedCount,
    queuedCount,
    manualCount,
    successCount,
    failCount,
    totalPlatforms: requestedPlatforms.length,
    elapsedMs: elapsed,
    geminiUsed: !!geminiModel,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await db.collection("social_publish_log").add(logDoc);

  let socialEngineStatus = "failed";
  if (publishedCount > 0) {
    socialEngineStatus = "published";
  } else if (queuedCount > 0) {
    socialEngineStatus = "queued";
  } else if (manualCount > 0) {
    socialEngineStatus = "pending_manual";
  }

  // Also write to social_engine_posts for the app UI to display
  await db.collection("social_engine_posts").add({
    publishId,
    title: contentInput.title || "",
    caption: variants.facebook || contentInput.description || "",
    mediaUrl: previewMediaUrl,
    mediaUrls,
    thumbnailUrl: mediaPlan.thumbnailUrl || previewMediaUrl,
    mediaPlan,
    platforms: requestedPlatforms,
    status: socialEngineStatus,
    results,
    sourceFunction: contentInput.sourceFunction || "manual",
    publishedCount,
    queuedCount,
    manualCount,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(
    `[SocialPublisher] ═══ ENGINE DONE: ${publishId} — ${publishedCount} published, ${queuedCount} queued, ${manualCount} manual, ${failCount} failed in ${elapsed}ms ═══`,
  );

  return {
    publishId,
    publishedCount,
    queuedCount,
    manualCount,
    successCount,
    failCount,
    totalPlatforms: requestedPlatforms.length,
    results,
    viralScore: variants.viralScore || 0,
    elapsedMs: elapsed,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// CALLABLE FUNCTIONS — Exposed to the app and admin panel
// ═══════════════════════════════════════════════════════════════════════════

// ─── Manual Publish — Admin/Promoter triggers a blast ────────────────────
const nativePublish = onCall(
  { region: REGION, timeoutSeconds: 120, memory: "512MiB" },
  async (request) => {
    if (!request.auth)
      return { status: "error", message: "Authentication required" };

    const metaTargetOverrides = extractMetaTargetOverrides(request.data || {});

    const {
      title,
      description,
      mediaUrl,
      mediaPlan = {},
      buyLink,
      tone = "hype",
      contentType = "general",
      platforms,
    } = request.data;

    if (!title) return { status: "error", message: "title is required" };

    const result = await Promise.resolve(
      publishToAllPlatforms({
        title,
        description: description || "",
        mediaUrl: mediaUrl || "",
        mediaPlan,
        buyLink: buyLink || "",
        tone,
        contentType,
        platforms,
        sourceFunction: "nativePublish",
        sourceId: `manual_${request.auth.uid}`,
        ...metaTargetOverrides,
      }),
    );

    return { status: "ok", ...result };
  },
);

// ─── Native Content Brain — Replaces triggerContentBrain (no n8n) ────────
const nativeContentBrain = onCall(
  { region: REGION, timeoutSeconds: 120, memory: "512MiB" },
  async (request) => {
    if (!request.auth)
      return { status: "error", message: "Authentication required" };

    const metaTargetOverrides = extractMetaTargetOverrides(request.data || {});

    const {
      webInput,
      platform = "all",
      brandTone = "hype",
      contentType = "general",
      autoPublish = false,
      eventData = {},
      mediaPlan = {},
    } = request.data;

    if (!webInput || webInput.trim().length < 5) {
      return {
        status: "error",
        message: "webInput must be at least 5 characters",
      };
    }

    const requestId = `brain_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;

    // Store the request
    await db
      .collection("ai_content_requests")
      .doc(requestId)
      .set({
        requestId,
        userId: request.auth.uid,
        webInput: webInput.slice(0, 2000),
        platform,
        brandTone,
        contentType,
        autoPublish,
        eventData,
        mediaPlan,
        metaTargetKey:
          metaTargetOverrides.metaTargetKey ||
          process.env.FACEBOOK_TARGET_KEY ||
          DEFAULT_META_TARGET_KEY,
        facebookTargetKey: metaTargetOverrides.facebookTargetKey,
        facebookPageId: metaTargetOverrides.facebookPageId,
        facebookPageLabel: metaTargetOverrides.facebookPageLabel,
        facebookOwnerProfile: metaTargetOverrides.facebookOwnerProfile,
        facebookBusinessPortfolio:
          metaTargetOverrides.facebookBusinessPortfolio,
        igBusinessAccountId: metaTargetOverrides.igBusinessAccountId,
        status: "processing",
        engine: "native_gemini",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    // Generate content via Gemini
    const variants = await Promise.resolve(
      generateContentVariants({
        title: eventData.title || webInput.substring(0, 80),
        description: webInput,
        mediaUrl:
          mediaPlan.primaryPublishableAssetUrl || eventData.posterUrl || "",
        mediaPlan,
        buyLink: eventData.buyLink || "",
        tone: brandTone,
        contentType,
        price: eventData.price || "",
        promoterName: eventData.promoterName || "",
      }),
    );

    // Store generated content
    const contentDocId = `content_${requestId}`;
    await db
      .collection("ai_generated_content")
      .doc(contentDocId)
      .set({
        requestId,
        userId: request.auth.uid,
        source: "native_gemini",
        generatedAt: admin.firestore.FieldValue.serverTimestamp(),
        content: variants,
        headline: variants.email_subject || "",
        suggestedMedia:
          mediaPlan.primaryPreviewAssetUrl || mediaPlan.primaryAssetUrl || "",
        suggestedMediaAssets: mediaPlan.assetUrls || [],
        mediaPlan,
        mediaUrl:
          mediaPlan.primaryPreviewAssetUrl || mediaPlan.primaryAssetUrl || "",
        mediaUrls: mediaPlan.assetUrls || [],
        thumbnailUrl: mediaPlan.thumbnailUrl || "",
        viralScore: variants.viralScore || 0,
        emotionalFrame: variants.emotionalFrame || "",
        autoPublish,
        metaTargetKey:
          metaTargetOverrides.metaTargetKey ||
          process.env.FACEBOOK_TARGET_KEY ||
          DEFAULT_META_TARGET_KEY,
        facebookTargetKey: metaTargetOverrides.facebookTargetKey,
        facebookPageId: metaTargetOverrides.facebookPageId,
        facebookPageLabel: metaTargetOverrides.facebookPageLabel,
        facebookOwnerProfile: metaTargetOverrides.facebookOwnerProfile,
        facebookBusinessPortfolio:
          metaTargetOverrides.facebookBusinessPortfolio,
        igBusinessAccountId: metaTargetOverrides.igBusinessAccountId,
        published: false,
      });

    // Update request status
    await db.collection("ai_content_requests").doc(requestId).update({
      status: "completed",
      contentDocId,
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Auto-publish if requested
    let publishResult = null;
    if (autoPublish) {
      publishResult = await Promise.resolve(
        publishToAllPlatforms({
          title: eventData.title || webInput.substring(0, 80),
          description: webInput,
          mediaUrl:
            mediaPlan.primaryPublishableAssetUrl || eventData.posterUrl || "",
          mediaPlan,
          buyLink: eventData.buyLink || "",
          tone: brandTone,
          contentType,
          sourceFunction: "nativeContentBrain",
          sourceId: requestId,
          ...metaTargetOverrides,
        }),
      );

      await db.collection("ai_generated_content").doc(contentDocId).update({
        published: true,
        publishResult,
      });
    }

    return {
      status: "success",
      requestId,
      contentDocId,
      content: variants,
      viralScore: variants.viralScore || 0,
      publishResult,
    };
  },
);

// ─── Platform Status Check — Which platforms are connected? ──────────────
const checkPlatformStatus = onCall({ region: REGION }, async () => {
  const defaultMetaTarget = resolveMetaTarget(
    process.env.FACEBOOK_TARGET_KEY || DEFAULT_META_TARGET_KEY,
  );
  const defaultFacebookConnected =
    defaultMetaTarget.targetType === "facebook_page" &&
    !!(
      getEnvValue(defaultMetaTarget.pageIdEnv) &&
      getEnvValue(defaultMetaTarget.accessTokenEnv)
    );
  const defaultInstagramConnected =
    defaultMetaTarget.targetType === "facebook_page" &&
    !!(
      getEnvValue(defaultMetaTarget.igBusinessAccountEnv) &&
      getEnvValue(defaultMetaTarget.accessTokenEnv)
    );

  return {
    status: "ok",
    engine: "native",
    monthlyCost: "$0",
    aiModel: geminiModel ? "gemini-2.0-flash" : "fallback",
    platforms: {
      facebook: {
        connected: defaultFacebookConnected,
        emoji: "📘",
        target: defaultMetaTarget.label,
        ownerProfile: defaultMetaTarget.ownerProfile,
        businessPortfolio: defaultMetaTarget.businessPortfolio || "",
        pageId:
          getEnvValue(defaultMetaTarget.pageIdEnv) ||
          defaultMetaTarget.pageIdDefault ||
          "",
      },
      instagram: {
        connected: defaultInstagramConnected,
        emoji: "📸",
        target: defaultMetaTarget.label,
        ownerProfile: defaultMetaTarget.ownerProfile,
        businessPortfolio: defaultMetaTarget.businessPortfolio || "",
      },
      x: {
        connected: !!(process.env.X_API_KEY && process.env.X_ACCESS_TOKEN),
        emoji: "🐦",
      },
      tiktok: {
        connected: false,
        emoji: "🎵",
        queuedPublishing: connectorQueueEnabled(),
        note: connectorQueueEnabled()
          ? "Connector queue ready. Publishing is queued until an external TikTok worker confirms delivery."
          : "Connector queue disabled",
      },
      threads: {
        connected: !!(
          process.env.THREADS_USER_ID && process.env.THREADS_ACCESS_TOKEN
        ),
        emoji: "🧵",
      },
      youtube: {
        connected: !!process.env.YOUTUBE_API_KEY,
        emoji: "📺",
        queuedPublishing: connectorQueueEnabled(),
        note: connectorQueueEnabled()
          ? "Community posts remain limited. Media lanes can be queued for connector publishing."
          : "Community posts API limited",
      },
      youtube_shorts: {
        connected: false,
        emoji: "🎬",
        queuedPublishing: connectorQueueEnabled(),
        note: connectorQueueEnabled()
          ? "Shorts are queued for connector publishing."
          : "Connector queue disabled",
      },
      linkedin: { connected: !!process.env.LINKEDIN_ACCESS_TOKEN, emoji: "💼" },
      bluesky: {
        connected: !!(
          process.env.BLUESKY_HANDLE && process.env.BLUESKY_APP_PASSWORD
        ),
        emoji: "🦋",
      },
      pinterest: {
        connected: false,
        emoji: "📌",
        queuedPublishing: connectorQueueEnabled(),
        note: connectorQueueEnabled()
          ? "Pins are queued for connector publishing."
          : "Connector queue disabled",
      },
      email: { connected: !!sgMail, emoji: "📧" },
    },
    metaTargets: buildMetaTargetStatus(),
    geminiActive: !!geminiModel,
    sendgridActive: !!sgMail,
  };
});

// ─── Scheduled Daily Content Push (optional — auto-generates daily post) ─
const scheduledContentPush = onSchedule(
  {
    schedule: "every day 09:00",
    region: REGION,
    timeoutSeconds: 120,
    memory: "512MiB",
    timeZone: "Australia/Brisbane",
  },
  async () => {
    console.log("[SocialPublisher] ═══ DAILY SCHEDULED PUSH ═══");

    // Find upcoming events to promote
    const now = admin.firestore.Timestamp.now();
    const weekFromNow = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    );

    const upcomingSnap = await db
      .collection("ppv_events")
      .where("eventDate", ">=", now)
      .where("eventDate", "<=", weekFromNow)
      .orderBy("eventDate")
      .limit(3)
      .get();

    if (upcomingSnap.empty) {
      console.log(
        "[SocialPublisher] No upcoming events this week — skipping daily push",
      );
      return;
    }

    for (const doc of upcomingSnap.docs) {
      const event = doc.data();
      const ppvId = doc.id;
      const metaTargetOverrides = extractMetaTargetOverrides(event);

      await Promise.resolve(
        publishToAllPlatforms({
          title: event.name || event.title || "FIGHT NIGHT",
          description: event.description || "",
          mediaUrl: event.promo_poster_url || event.thumbnailUrl || "",
          buyLink: `https://datafightcentral.com/ppv/event/${ppvId}`,
          tone: "hype",
          contentType: "daily_promo",
          price: event.price ? `${event.price}` : "",
          promoterName: event.promoterName || "",
          sourceFunction: "scheduledContentPush",
          sourceId: ppvId,
          ...metaTargetOverrides,
        }),
      );
    }

    console.log(
      `[SocialPublisher] Daily push complete — promoted ${upcomingSnap.size} events`,
    );
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// EXPORTS — Module pattern matching functions/index.js
// ═══════════════════════════════════════════════════════════════════════════
module.exports = {
  // Callable functions (exposed to app + admin)
  nativePublish,
  nativeContentBrain,
  checkPlatformStatus,

  // Scheduled function
  scheduledContentPush,

  // Internal function (called by event_seeder, drip_scheduler, etc.)
  // These are NOT Cloud Functions — they're just exported JS functions
  _publishToAllPlatforms: publishToAllPlatforms,
  _generateContentVariants: generateContentVariants,
};
