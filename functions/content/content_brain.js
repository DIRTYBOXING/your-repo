// ═══════════════════════════════════════════════════════════════════════════
// DFC CONTENT BRAIN — n8n ↔ Firebase Bridge Functions
// ═══════════════════════════════════════════════════════════════════════════
//
// TWO FUNCTIONS:
//
// 1. triggerContentBrain (onCall)
//    → DFC app / admin triggers content generation
//    → Sends request to n8n Content Brain webhook
//    → Stores request in ai_content_requests collection
//    → n8n processes and responds synchronously (or via callback)
//
// 2. n8nContentCallback (onRequest)
//    → n8n posts generated content back (for async mode)
//    → Stores in ai_generated_content collection
//    → Optionally auto-publishes to social_posts + social_engine_posts
//    → Optionally forwards to Blotato for cross-platform distribution
//
// COLLECTIONS:
//   ai_content_requests  — Track all generation requests
//   ai_generated_content — Store all generated content
//   social_posts         — Internal DFC feed (drip_scheduler pattern)
//   social_engine_posts  — Blotato cross-platform distribution
//
// ═══════════════════════════════════════════════════════════════════════════

const { onCall, onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { admin, db, REGION } = require("../config");

// Native engine fallback — when n8n isn't configured, use the native publisher
const {
  _publishToAllPlatforms,
  _generateContentVariants,
} = require("./social_publisher");

// ─── n8n Configuration (optional — native engine is the primary now) ─────
const N8N_CONTENT_BRAIN_URL = process.env.N8N_CONTENT_BRAIN_URL || "";
const N8N_API_KEY = process.env.N8N_API_KEY || "";

function workflowRunRef(requestId) {
  return db.collection("workflow_runs").doc(requestId);
}

async function writeWorkflowRun(requestId, payload) {
  await workflowRunRef(requestId).set(
    {
      requestId,
      ...payload,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

function normalizeUrlList(values = []) {
  const urls = [];
  const seen = new Set();

  for (const rawValue of values) {
    const value = String(rawValue || "").trim();
    if (
      !value ||
      (!value.startsWith("http://") && !value.startsWith("https://"))
    ) {
      continue;
    }
    if (seen.has(value)) {
      continue;
    }
    seen.add(value);
    urls.push(value);
  }

  return urls;
}

function firstNonEmptyString(values = []) {
  for (const rawValue of values) {
    const value = String(rawValue || "").trim();
    if (value) {
      return value;
    }
  }

  return "";
}

function inferMediaAssetType(url = "") {
  const normalizedUrl = String(url || "").toLowerCase();
  if (!normalizedUrl) {
    return "unknown";
  }
  if (/\.svg(?:$|\?)/i.test(normalizedUrl)) {
    return "svg";
  }
  if (/\.(mp4|mov|m4v|webm|m3u8)(?:$|\?)/i.test(normalizedUrl)) {
    return "video";
  }
  return "image";
}

function buildNormalizedMediaPlan({ eventData = {}, mediaPlan = {} } = {}) {
  const safeEventData =
    eventData && typeof eventData === "object" ? eventData : {};
  const safeMediaPlan =
    mediaPlan && typeof mediaPlan === "object" ? mediaPlan : {};

  const eventMediaUrls = Array.isArray(safeEventData.mediaUrls)
    ? safeEventData.mediaUrls
    : [];
  const eventAssetUrls = Array.isArray(safeEventData.assetUrls)
    ? safeEventData.assetUrls
    : [];
  const mediaPlanUrls = Array.isArray(safeMediaPlan.mediaUrls)
    ? safeMediaPlan.mediaUrls
    : [];
  const mediaPlanAssetUrls = Array.isArray(safeMediaPlan.assetUrls)
    ? safeMediaPlan.assetUrls
    : [];

  const posterUrl = firstNonEmptyString([
    safeMediaPlan.posterUrl,
    safeEventData.posterUrl,
    safeEventData.imageUrl,
    safeEventData.thumbnailUrl,
  ]);

  const assetUrls = normalizeUrlList([
    posterUrl,
    safeMediaPlan.primaryAssetUrl,
    safeMediaPlan.primaryPreviewAssetUrl,
    safeMediaPlan.primaryPublishableAssetUrl,
    safeMediaPlan.thumbnailUrl,
    ...mediaPlanAssetUrls,
    ...mediaPlanUrls,
    safeEventData.imageUrl,
    safeEventData.thumbnailUrl,
    ...eventAssetUrls,
    ...eventMediaUrls,
  ]);

  const resolvedPosterUrl = firstNonEmptyString([posterUrl, assetUrls[0]]);
  const primaryAssetUrl = firstNonEmptyString([
    safeMediaPlan.primaryAssetUrl,
    safeMediaPlan.primaryPreviewAssetUrl,
    resolvedPosterUrl,
    assetUrls[0],
  ]);
  const primaryPreviewAssetUrl = firstNonEmptyString([
    safeMediaPlan.primaryPreviewAssetUrl,
    resolvedPosterUrl,
    primaryAssetUrl,
    assetUrls[0],
  ]);
  const primaryPublishableAssetUrl = firstNonEmptyString([
    safeMediaPlan.primaryPublishableAssetUrl,
    ...assetUrls.filter((url) => inferMediaAssetType(url) !== "svg"),
  ]);
  const thumbnailUrl = firstNonEmptyString([
    safeMediaPlan.thumbnailUrl,
    safeEventData.thumbnailUrl,
    resolvedPosterUrl,
    primaryPreviewAssetUrl,
    primaryPublishableAssetUrl,
  ]);

  return {
    posterUrl: resolvedPosterUrl,
    primaryAssetUrl,
    primaryPreviewAssetUrl,
    primaryPublishableAssetUrl,
    thumbnailUrl,
    assetUrls,
    mediaUrls: assetUrls,
    assets: assetUrls.map((url, index) => {
      let role = "supporting";
      if (resolvedPosterUrl && url === resolvedPosterUrl) {
        role = "poster";
      } else if (index === 0) {
        role = "primary";
      }

      return {
        url,
        role,
        type: inferMediaAssetType(url),
        order: index + 1,
      };
    }),
  };
}

function mergeEventDataWithMediaPlan(eventData = {}, mediaPlan = {}) {
  const mergedEventData = {
    ...(eventData && typeof eventData === "object" ? eventData : {}),
  };

  if (mediaPlan.posterUrl) {
    mergedEventData.posterUrl = mediaPlan.posterUrl;
  }
  if (mediaPlan.primaryAssetUrl) {
    mergedEventData.imageUrl =
      mergedEventData.imageUrl || mediaPlan.primaryAssetUrl;
  }
  if (mediaPlan.thumbnailUrl) {
    mergedEventData.thumbnailUrl =
      mergedEventData.thumbnailUrl || mediaPlan.thumbnailUrl;
  }
  if (Array.isArray(mediaPlan.assetUrls) && mediaPlan.assetUrls.length > 0) {
    mergedEventData.mediaUrls = mediaPlan.assetUrls;
    mergedEventData.assetUrls = mediaPlan.assetUrls;
  }

  return mergedEventData;
}

function buildContentBrainInput(
  webInput,
  eventData,
  brandTone,
  objective,
  mediaPlan = {},
) {
  const normalizedMediaPlan = buildNormalizedMediaPlan({
    eventData,
    mediaPlan,
  });
  const mergedEventData = mergeEventDataWithMediaPlan(
    eventData,
    normalizedMediaPlan,
  );

  return {
    title:
      mergedEventData.title ||
      mergedEventData.eventName ||
      webInput.substring(0, 80),
    description: webInput,
    mediaUrl: normalizedMediaPlan.primaryPublishableAssetUrl || "",
    posterUrl: normalizedMediaPlan.posterUrl || "",
    thumbnailUrl: normalizedMediaPlan.thumbnailUrl || "",
    mediaUrls: normalizedMediaPlan.assetUrls || [],
    mediaPlan: normalizedMediaPlan,
    buyLink: mergedEventData.buyLink || "",
    tone: brandTone,
    contentType: objective,
    price: mergedEventData.price || "",
    promoterName: mergedEventData.promoterName || "",
    fighters: Array.isArray(mergedEventData.fighters)
      ? mergedEventData.fighters
      : [],
  };
}

function normalizeNativeVariantsToGeneratedContent(
  variants,
  requestData,
  mediaPlan = {},
) {
  const {
    platform = "all",
    postType = "text",
    brandTone = "hype",
  } = requestData;

  const requestedPlatforms =
    platform === "all"
      ? [
          "facebook",
          "instagram",
          "x",
          "threads",
          "youtube",
          "linkedin",
          "bluesky",
        ]
      : [platform];

  const posts = requestedPlatforms
    .map((platformKey) => ({
      platform: platformKey,
      caption: variants[platformKey] || "",
      postType,
      best_time_to_post: "",
      mediaUrl:
        mediaPlan.primaryPreviewAssetUrl || mediaPlan.primaryAssetUrl || "",
      mediaUrls: mediaPlan.assetUrls || [],
      thumbnailUrl: mediaPlan.thumbnailUrl || "",
    }))
    .filter((post) => post.caption);

  return {
    posts,
    headline: variants.email_subject || "",
    summary: posts[0]?.caption || requestData.webInput || "",
    viralScore: variants.viralScore || 0,
    toneSummary: brandTone,
    suggestedMedia:
      mediaPlan.primaryPreviewAssetUrl || mediaPlan.primaryAssetUrl || "",
    suggestedMediaAssets: mediaPlan.assetUrls || [],
    mediaPlan,
    pipeline: {
      engine: "native_gemini",
      source: "content_brain_native_fallback",
    },
    emotionalFrame: variants.emotionalFrame || "",
    hashtags: variants.hashtags || [],
  };
}

async function persistGeneratedContent({
  requestId,
  userId,
  generatedContent,
  autoPublish,
  autoDistribute,
  source,
  executionMode,
  requestPlatform,
}) {
  const generatedMediaPlan =
    generatedContent.mediaPlan && typeof generatedContent.mediaPlan === "object"
      ? generatedContent.mediaPlan
      : undefined;
  const normalizedGeneratedMediaPlanInput = generatedMediaPlan
    ? {
        ...generatedMediaPlan,
        posterUrl: generatedContent.suggestedMedia || "",
        assetUrls: generatedContent.suggestedMediaAssets || [],
      }
    : {
        posterUrl: generatedContent.suggestedMedia || "",
        assetUrls: generatedContent.suggestedMediaAssets || [],
      };
  const normalizedMediaPlan = buildNormalizedMediaPlan({
    mediaPlan: normalizedGeneratedMediaPlanInput,
  });

  const contentDocId = `content_${requestId}`;
  await db
    .collection("ai_generated_content")
    .doc(contentDocId)
    .set({
      requestId,
      userId,
      source,
      generatedAt: admin.firestore.FieldValue.serverTimestamp(),
      content: generatedContent,
      posts: generatedContent.posts || [],
      headline: generatedContent.headline || "",
      summary: generatedContent.summary || "",
      viralScore: generatedContent.viralScore || 0,
      toneSummary: generatedContent.toneSummary || "",
      suggestedMedia:
        generatedContent.suggestedMedia ||
        normalizedMediaPlan.primaryPreviewAssetUrl ||
        "",
      suggestedMediaAssets:
        generatedContent.suggestedMediaAssets ||
        normalizedMediaPlan.assetUrls ||
        [],
      mediaPlan: normalizedMediaPlan,
      mediaUrl:
        normalizedMediaPlan.primaryPreviewAssetUrl ||
        normalizedMediaPlan.primaryAssetUrl ||
        "",
      mediaUrls: normalizedMediaPlan.assetUrls || [],
      thumbnailUrl: normalizedMediaPlan.thumbnailUrl || "",
      pipeline: generatedContent.pipeline || {},
      emotionalFrame: generatedContent.emotionalFrame || "",
      autoPublish,
      autoDistribute,
      published: false,
      distributed: false,
    });

  await db.collection("ai_content_requests").doc(requestId).update({
    status: "completed",
    contentDocId,
    completedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await writeWorkflowRun(requestId, {
    status: "completed",
    executionMode,
    contentDocId,
    completedAt: admin.firestore.FieldValue.serverTimestamp(),
    lastCallbackAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  if (
    autoPublish &&
    generatedContent.posts &&
    generatedContent.posts.length > 0
  ) {
    const primaryPost = generatedContent.posts[0];
    await db.collection("social_posts").add({
      type: "ai_generated",
      sourceService: "content_brain",
      requestId,
      caption: primaryPost.caption || generatedContent.summary || "",
      title: generatedContent.headline || "",
      mediaUrl:
        normalizedMediaPlan.primaryPreviewAssetUrl ||
        normalizedMediaPlan.primaryAssetUrl ||
        "",
      mediaUrls: normalizedMediaPlan.assetUrls || [],
      thumbnailUrl: normalizedMediaPlan.thumbnailUrl || "",
      mediaPlan: normalizedMediaPlan,
      targetPlatforms: generatedContent.posts
        .map((p) => p.platform)
        .filter(Boolean),
      status: "ready_to_post",
      viralScore: generatedContent.viralScore || 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      autoGenerated: true,
    });

    await db.collection("ai_generated_content").doc(contentDocId).update({
      published: true,
    });
  }

  if (
    autoDistribute &&
    generatedContent.posts &&
    generatedContent.posts.length > 0
  ) {
    for (const post of generatedContent.posts) {
      await db.collection("social_engine_posts").add({
        userId,
        caption: post.caption || "",
        hashtags: _extractHashtags(post.caption || ""),
        postType: post.postType || "text",
        targetPlatforms: [post.platform || requestPlatform],
        status: "pending_manual",
        sourceService: "content_brain",
        requestId,
        mediaUrl:
          normalizedMediaPlan.primaryPreviewAssetUrl ||
          normalizedMediaPlan.primaryAssetUrl ||
          "",
        mediaUrls: normalizedMediaPlan.assetUrls || [],
        thumbnailUrl: normalizedMediaPlan.thumbnailUrl || "",
        mediaPlan: normalizedMediaPlan,
        viralScore: generatedContent.viralScore || 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await db.collection("ai_generated_content").doc(contentDocId).update({
      distributed: true,
    });
  }

  return contentDocId;
}

async function runNativeContentBrain({
  requestId,
  requestData,
  executionMode = "native_gemini",
  source = "native_gemini",
}) {
  await db.collection("ai_content_requests").doc(requestId).update({
    status: "processing",
    engine: "native_gemini",
  });
  await writeWorkflowRun(requestId, {
    status: "processing",
    executionMode,
  });

  const contentBrainInput = buildContentBrainInput(
    requestData.webInput,
    requestData.eventData,
    requestData.brandTone,
    requestData.objective,
    requestData.mediaPlan,
  );
  const enrichedRequestData = {
    ...requestData,
    eventData: mergeEventDataWithMediaPlan(
      requestData.eventData || {},
      contentBrainInput.mediaPlan || {},
    ),
  };
  const variants = await Promise.resolve(
    _generateContentVariants(contentBrainInput),
  );
  const generatedContent = normalizeNativeVariantsToGeneratedContent(
    variants,
    enrichedRequestData,
    contentBrainInput.mediaPlan,
  );

  const contentDocId = await persistGeneratedContent({
    requestId,
    userId: requestData.userId,
    generatedContent,
    autoPublish: requestData.autoPublish,
    autoDistribute: requestData.autoDistribute,
    source,
    executionMode,
    requestPlatform: requestData.platform,
  });

  let publishResult = null;
  if (requestData.autoPublish || requestData.autoDistribute) {
    publishResult = await Promise.resolve(
      _publishToAllPlatforms({
        ...contentBrainInput,
        sourceFunction: "triggerContentBrain_native",
        sourceId: requestId,
      }),
    );

    await db.collection("ai_generated_content").doc(contentDocId).update({
      published: true,
      distributed: true,
      publishResult,
    });
  }

  return {
    status: "success",
    engine: "native_gemini",
    requestId,
    contentDocId,
    content: generatedContent,
    publishResult,
  };
}

// ─── Platform → Post Type mapping ───────────────────────────────────────
const PLATFORM_DEFAULTS = {
  instagram: { postType: "carousel", maxCaptionLength: 2200 },
  tiktok: { postType: "short", maxCaptionLength: 2200 },
  youtube: { postType: "short", maxCaptionLength: 5000 },
  linkedin: { postType: "text", maxCaptionLength: 3000 },
  x: { postType: "text", maxCaptionLength: 280 },
  threads: { postType: "text", maxCaptionLength: 500 },
  facebook: { postType: "text", maxCaptionLength: 63206 },
  bluesky: { postType: "text", maxCaptionLength: 300 },
  pinterest: { postType: "image", maxCaptionLength: 500 },
};

// ─── Brand Tone Presets ──────────────────────────────────────────────────
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

const STREAMING_DOCTRINE_V1 = Object.freeze({
  objective: "streaming_doctrine_v1",
  doctrineVersion: "v1",
  northStar:
    "Win combat streaming by owning the event lane end-to-end: ingest, entitlement, playback, replay, and clip velocity.",
  defaultPrimaryPlatform:
    "Mux live ingest with signed HLS playback on DFC-owned surfaces",
  defaultSecondaryPlatforms: [
    "SRT and RTMP contribution feeds for venue and production workflows",
    "Replay and clip factory for immediate post-event monetization",
    "WebRTC premium tier only when the lowLatencyTier flag is actively enabled",
  ],
  nonNegotiables: [
    "DFC-owned playback stays primary for PPV, premium replays, and rights-sensitive programming.",
    "External social and partner platforms are acquisition lanes, not the canonical paid watch surface.",
    "Never claim sub-second delivery unless lowLatencyTier is actually enabled and monitored.",
    "Rights, entitlement, DRM posture, and replay readiness are part of the product, not afterthoughts.",
  ],
});

async function readFeatureFlagDoc(flagName) {
  try {
    const snapshot = await db.collection("feature_flags").doc(flagName).get();
    return snapshot.exists ? snapshot.data() || {} : null;
  } catch (error) {
    console.warn(
      `[ContentBrain] Failed to read feature flag ${flagName}:`,
      error.message,
    );
    return null;
  }
}

function buildStreamingDoctrinePayload(input = {}, options = {}) {
  const {
    requestedPlatform = "all",
    businessObjective = "engagement",
    monetizationModel = "ppv",
    latencySensitivity = "standard",
    audienceScale = "global",
    rightsTier = "premium",
    sport = "combat",
  } = input;
  const { lowLatencyEnabled = false } = options;

  const normalizedRequestedPlatform = String(
    requestedPlatform || "all",
  ).toLowerCase();
  const normalizedObjective = String(
    businessObjective || "engagement",
  ).toLowerCase();
  const normalizedMonetization = String(
    monetizationModel || "ppv",
  ).toLowerCase();
  const normalizedLatency = String(
    latencySensitivity || "standard",
  ).toLowerCase();
  const normalizedAudienceScale = String(
    audienceScale || "global",
  ).toLowerCase();
  const normalizedRightsTier = String(rightsTier || "premium").toLowerCase();
  const normalizedSport = String(sport || "combat").toLowerCase();

  let primaryPlatform = "Mux live ingest + signed HLS playback";
  const secondaryPlatforms = [
    "SRT/RTMP contribution feeds",
    "Replay and clip factory",
  ];
  const operatorNotes = [
    "Default every PPV and premium live card to DFC-owned playback with entitlement checks and signed playback tokens.",
    "Treat startup speed, replay speed, and rights enforcement as one operating surface instead of separate teams.",
    "Push clips and syndication outward only after the owned watch surface and replay lane are healthy.",
  ];
  const riskFlags = [];

  const isRevenueSensitive =
    normalizedMonetization === "ppv" ||
    normalizedMonetization === "subscription";
  const isInteractiveNeed =
    normalizedLatency === "ultra_low" ||
    normalizedLatency === "interactive" ||
    normalizedLatency === "sub_second";

  if (isInteractiveNeed) {
    if (lowLatencyEnabled) {
      primaryPlatform = "WebRTC premium room with Mux HLS fallback";
      secondaryPlatforms.unshift("Signed HLS fallback lane");
      operatorNotes.unshift(
        "Use the WebRTC premium room only for products where latency changes value, such as corners, judges, betting, or VIP watch-alongs.",
      );
    } else {
      riskFlags.push("low_latency_tier_disabled");
      operatorNotes.unshift(
        "Ultra-low-latency was requested, but lowLatencyTier is disabled. Stay truthful: optimize HLS start-up and avoid fake sub-second positioning.",
      );
    }
  }

  if (
    isRevenueSensitive ||
    normalizedRightsTier === "premium" ||
    normalizedRightsTier === "exclusive"
  ) {
    secondaryPlatforms.push("DRM and entitlement guardrail lane");
    operatorNotes.push(
      "Premium cards and replay libraries should flow through entitlements, signed playback, DRM posture, and session observability.",
    );
  }

  if (
    normalizedAudienceScale === "global" ||
    normalizedAudienceScale === "mass"
  ) {
    secondaryPlatforms.push("Multi-bitrate HLS and edge cache posture");
    operatorNotes.push(
      "Global distribution means resilience first: codec ladder, edge delivery, and rapid replay publishing outrank vanity platform spread.",
    );
  }

  if (
    normalizedRequestedPlatform !== "all" &&
    normalizedRequestedPlatform !== "dfc"
  ) {
    riskFlags.push("external_platform_requested");
    operatorNotes.push(
      `Requested platform ${normalizedRequestedPlatform} should be treated as an acquisition lane. Keep the paid or canonical watch experience on DFC-owned playback.`,
    );
  }

  if (normalizedObjective === "conversion") {
    operatorNotes.push(
      "Conversion-focused campaigns should bias toward the owned checkout, entitlement, and replay path instead of broadcasting watch intent outward.",
    );
  }

  if (normalizedSport !== "combat" && normalizedSport !== "general") {
    operatorNotes.push(
      `Current doctrine was tuned for combat-sports pacing and monetization. Validate ${normalizedSport} assumptions before widening automation claims.`,
    );
  }

  const messagingKey =
    isInteractiveNeed && lowLatencyEnabled
      ? "DFC wins by pairing premium low-latency rooms with a revenue-safe HLS main lane instead of pretending one protocol solves every show."
      : "DFC wins by controlling ingest, entitlements, playback, replay, and clip speed inside one combat-native stack.";

  return {
    ...STREAMING_DOCTRINE_V1,
    primaryPlatform,
    secondaryPlatforms: [...new Set(secondaryPlatforms)],
    messagingKey,
    operatorNotes,
    riskFlags: [...new Set(riskFlags)],
    featureFlags: {
      lowLatencyTier: lowLatencyEnabled,
    },
    appliedInputs: {
      requestedPlatform: normalizedRequestedPlatform,
      businessObjective: normalizedObjective,
      monetizationModel: normalizedMonetization,
      latencySensitivity: normalizedLatency,
      audienceScale: normalizedAudienceScale,
      rightsTier: normalizedRightsTier,
      sport: normalizedSport,
    },
    generatedAt: new Date().toISOString(),
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// FUNCTION 1: triggerContentBrain — Kick off AI content generation
// ═══════════════════════════════════════════════════════════════════════════
const triggerContentBrain = onCall(
  {
    region: REGION,
    memory: "512MiB",
    timeoutSeconds: 120,
  },
  async (request) => {
    return executeContentBrain(request);
  },
);

const streamingDoctrineV1 = onCall(
  {
    region: REGION,
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async (request) => {
    if (!request.auth) {
      return { status: "error", message: "Authentication required" };
    }

    const lowLatencyFlag = await readFeatureFlagDoc("lowLatencyTier");
    const lowLatencyEnabled = Boolean(lowLatencyFlag?.enabled);

    return {
      status: "success",
      ...buildStreamingDoctrinePayload(request.data || {}, {
        lowLatencyEnabled,
      }),
    };
  },
);

async function executeContentBrain(request) {
  // Auth check — must be logged in
  if (!request.auth) {
    return { status: "error", message: "Authentication required" };
  }

  const {
    webInput,
    platform = "all",
    postType = "text",
    brandTone = "hype",
    audienceType = "fans",
    niche = "general",
    objective = "engagement",
    eventData: rawEventData = {},
    mediaPlan: rawMediaPlan = {},
    autoPublish = false,
    autoDistribute = false,
  } = request.data;

  const normalizedMediaPlan = buildNormalizedMediaPlan({
    eventData: rawEventData,
    mediaPlan: rawMediaPlan,
  });
  const eventData = mergeEventDataWithMediaPlan(
    rawEventData,
    normalizedMediaPlan,
  );

  if (!webInput || webInput.trim().length < 5) {
    return {
      status: "error",
      message: "webInput must be at least 5 characters",
    };
  }

  const requestId =
    request.data.requestId ||
    `brain_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;

  // ── Store the request ──
  const requestDoc = {
    requestId,
    userId: request.auth.uid,
    webInput: webInput.slice(0, 2000),
    platform,
    postType,
    brandTone,
    audienceType,
    niche,
    objective,
    eventData,
    mediaPlan: normalizedMediaPlan,
    autoPublish,
    autoDistribute,
    status: "pending",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await db.collection("ai_content_requests").doc(requestId).set(requestDoc);
  await writeWorkflowRun(requestId, {
    workflowType: "content_brain",
    status: "pending",
    attemptCount: 1,
    userId: request.auth.uid,
    eventId: eventData.eventId || null,
    source: "triggerContentBrain",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    lastError: null,
  });

  const contentBrainRequest = {
    requestId,
    userId: request.auth.uid,
    webInput: requestDoc.webInput,
    platform,
    postType,
    brandTone,
    audienceType,
    niche,
    objective,
    eventData,
    mediaPlan: normalizedMediaPlan,
    autoPublish,
    autoDistribute,
  };

  // ── Use native engine when n8n is not configured ──
  if (!N8N_CONTENT_BRAIN_URL) {
    console.log(
      `[ContentBrain] n8n not configured — using NATIVE Gemini engine for ${requestId}`,
    );
    return runNativeContentBrain({
      requestId,
      requestData: contentBrainRequest,
    });
  }

  try {
    const callbackUrl = `https://${REGION}-datafightcentral.cloudfunctions.net/n8nContentCallback`;

    const n8nPayload = {
      webInput: requestDoc.webInput,
      platform,
      postType,
      brandTone,
      audienceType,
      niche,
      objective,
      eventData,
      mediaPlan: normalizedMediaPlan,
      requestId,
      callbackUrl,
    };

    const response = await fetch(N8N_CONTENT_BRAIN_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...(N8N_API_KEY ? { Authorization: `Bearer ${N8N_API_KEY}` } : {}),
      },
      body: JSON.stringify(n8nPayload),
    });

    if (!response.ok) {
      const errorText = await response.text();
      const shouldFallbackToNative =
        response.status >= 500 || response.status === 404;

      if (shouldFallbackToNative) {
        console.warn(
          `[ContentBrain] n8n returned ${response.status} — falling back to native Gemini for ${requestId}`,
        );
        await writeWorkflowRun(requestId, {
          status: "fallback",
          executionMode: "n8n_fallback_native",
          lastError: `n8n returned ${response.status}: ${errorText.slice(0, 500)}`,
        });
        return runNativeContentBrain({
          requestId,
          requestData: contentBrainRequest,
          executionMode: "n8n_fallback_native",
          source: "n8n_fallback_native",
        });
      }

      await db
        .collection("ai_content_requests")
        .doc(requestId)
        .update({
          status: "failed",
          error: `n8n returned ${response.status}: ${errorText.slice(0, 500)}`,
        });
      await writeWorkflowRun(requestId, {
        status: "failed",
        executionMode: "n8n",
        lastError: `n8n returned ${response.status}: ${errorText.slice(0, 500)}`,
      });
      return {
        status: "error",
        message: "Content brain request failed",
        requestId,
      };
    }

    await writeWorkflowRun(requestId, {
      status: "processing",
      executionMode: "n8n",
    });

    // n8n responds synchronously with generated content
    const generatedContent = await response.json();

    const contentDocId = await persistGeneratedContent({
      requestId,
      userId: request.auth.uid,
      generatedContent,
      autoPublish,
      autoDistribute,
      source: "n8n_content_brain",
      executionMode: "n8n",
      requestPlatform: platform,
    });

    return {
      status: "success",
      requestId,
      contentDocId,
      content: generatedContent,
    };
  } catch (err) {
    console.error("[ContentBrain] Error:", err.message);
    console.warn(
      `[ContentBrain] Falling back to native Gemini after fetch error for ${requestId}`,
    );
    await writeWorkflowRun(requestId, {
      status: "fallback",
      executionMode: "n8n_fallback_native",
      lastError: err.message,
    });
    return runNativeContentBrain({
      requestId,
      requestData: contentBrainRequest,
      executionMode: "n8n_fallback_native",
      source: "n8n_fallback_native",
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FUNCTION 2: n8nContentCallback — Async callback from n8n
// ═══════════════════════════════════════════════════════════════════════════
const n8nContentCallback = onRequest(
  {
    region: REGION,
    memory: "256MiB",
    timeoutSeconds: 30,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "POST only" });
      return;
    }

    const {
      requestId,
      posts,
      headline,
      summary,
      viralScore,
      toneSummary,
      suggestedMedia,
      suggestedMediaAssets,
      mediaPlan: callbackMediaPlan,
      assetUrls,
      mediaUrls,
      posterUrl,
      pipeline,
    } = req.body;

    if (!requestId) {
      res.status(400).json({ error: "requestId required" });
      return;
    }

    // Verify the request exists
    const requestSnap = await db
      .collection("ai_content_requests")
      .doc(requestId)
      .get();
    if (!requestSnap.exists) {
      res.status(404).json({ error: "Request not found" });
      return;
    }

    const requestData = requestSnap.data();
    const requestMediaPlan =
      requestData.mediaPlan && typeof requestData.mediaPlan === "object"
        ? requestData.mediaPlan
        : undefined;
    const callbackMediaPlanInput = requestMediaPlan
      ? {
          ...requestMediaPlan,
          ...(callbackMediaPlan && typeof callbackMediaPlan === "object"
            ? callbackMediaPlan
            : {}),
          posterUrl: firstNonEmptyString([
            posterUrl,
            suggestedMedia,
            callbackMediaPlan && typeof callbackMediaPlan === "object"
              ? callbackMediaPlan.posterUrl
              : "",
            requestData.mediaPlan?.posterUrl,
          ]),
          assetUrls: [
            ...(Array.isArray(suggestedMediaAssets)
              ? suggestedMediaAssets
              : []),
            ...(Array.isArray(assetUrls) ? assetUrls : []),
            ...(Array.isArray(mediaUrls) ? mediaUrls : []),
          ],
        }
      : {
          ...(callbackMediaPlan && typeof callbackMediaPlan === "object"
            ? callbackMediaPlan
            : {}),
          posterUrl: firstNonEmptyString([
            posterUrl,
            suggestedMedia,
            callbackMediaPlan && typeof callbackMediaPlan === "object"
              ? callbackMediaPlan.posterUrl
              : "",
            requestData.mediaPlan?.posterUrl,
          ]),
          assetUrls: [
            ...(Array.isArray(suggestedMediaAssets)
              ? suggestedMediaAssets
              : []),
            ...(Array.isArray(assetUrls) ? assetUrls : []),
            ...(Array.isArray(mediaUrls) ? mediaUrls : []),
          ],
        };
    const normalizedCallbackMediaPlan = buildNormalizedMediaPlan({
      eventData: requestData.eventData || {},
      mediaPlan: callbackMediaPlanInput,
    });

    // Store the generated content
    const contentDocId = `content_${requestId}`;
    await db
      .collection("ai_generated_content")
      .doc(contentDocId)
      .set({
        requestId,
        userId: requestData.userId,
        source: "n8n_content_brain_callback",
        generatedAt: admin.firestore.FieldValue.serverTimestamp(),
        content: req.body,
        posts: posts || [],
        headline: headline || "",
        summary: summary || "",
        viralScore: viralScore || 0,
        toneSummary: toneSummary || "",
        suggestedMedia:
          suggestedMedia ||
          normalizedCallbackMediaPlan.primaryPreviewAssetUrl ||
          "",
        suggestedMediaAssets:
          suggestedMediaAssets || normalizedCallbackMediaPlan.assetUrls || [],
        mediaPlan: normalizedCallbackMediaPlan,
        mediaUrl:
          normalizedCallbackMediaPlan.primaryPreviewAssetUrl ||
          normalizedCallbackMediaPlan.primaryAssetUrl ||
          "",
        mediaUrls: normalizedCallbackMediaPlan.assetUrls || [],
        thumbnailUrl: normalizedCallbackMediaPlan.thumbnailUrl || "",
        pipeline: pipeline || {},
        autoPublish: requestData.autoPublish || false,
        autoDistribute: requestData.autoDistribute || false,
        published: false,
        distributed: false,
      });

    // Update request status
    await db.collection("ai_content_requests").doc(requestId).update({
      status: "completed",
      contentDocId,
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await writeWorkflowRun(requestId, {
      status: "completed",
      executionMode: "n8n_callback",
      contentDocId,
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastCallbackAt: admin.firestore.FieldValue.serverTimestamp(),
      lastError: null,
    });

    // Auto-publish if flagged
    if (requestData.autoPublish && posts && posts.length > 0) {
      const primaryPost = posts[0];
      await db.collection("social_posts").add({
        type: "ai_generated",
        sourceService: "content_brain",
        requestId,
        caption: primaryPost.caption || summary || "",
        title: headline || "",
        mediaUrl:
          normalizedCallbackMediaPlan.primaryPreviewAssetUrl ||
          normalizedCallbackMediaPlan.primaryAssetUrl ||
          "",
        mediaUrls: normalizedCallbackMediaPlan.assetUrls || [],
        thumbnailUrl: normalizedCallbackMediaPlan.thumbnailUrl || "",
        mediaPlan: normalizedCallbackMediaPlan,
        targetPlatforms: posts.map((p) => p.platform).filter(Boolean),
        status: "ready_to_post",
        viralScore: viralScore || 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        autoGenerated: true,
      });
    }

    console.log(
      `[ContentBrain] Callback received for ${requestId} — ${(posts || []).length} posts generated`,
    );
    res.status(200).json({ status: "ok", contentDocId });
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// FUNCTION 3: contentBrainScheduler — Auto-generate content on schedule
// ═══════════════════════════════════════════════════════════════════════════
//
// Runs every 6 hours. Scans upcoming events and generates social content.
//
const contentBrainScheduler = onSchedule(
  {
    schedule: "every 6 hours",
    region: REGION,
    timeoutSeconds: 120,
    memory: "512MiB",
  },
  async () => {
    if (!N8N_CONTENT_BRAIN_URL) {
      console.log(
        "[ContentBrainScheduler] N8N_CONTENT_BRAIN_URL not set — skipping",
      );
      return;
    }

    const now = new Date();
    const in7Days = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

    // Find upcoming events that haven't had content generated yet
    const eventsSnap = await db
      .collection("ppv_events")
      .where("eventDate", ">=", admin.firestore.Timestamp.fromDate(now))
      .where("eventDate", "<=", admin.firestore.Timestamp.fromDate(in7Days))
      .limit(10)
      .get();

    if (eventsSnap.empty) {
      console.log("[ContentBrainScheduler] No upcoming events in 7-day window");
      return;
    }

    let generated = 0;

    for (const doc of eventsSnap.docs) {
      const event = doc.data();
      const eventId = doc.id;

      // Skip if we already generated content for this event today
      const existingSnap = await db
        .collection("ai_content_requests")
        .where("eventData.eventId", "==", eventId)
        .where("status", "==", "completed")
        .orderBy("createdAt", "desc")
        .limit(1)
        .get();

      if (!existingSnap.empty) {
        const lastGen = existingSnap.docs[0].data();
        const lastGenTime = lastGen.createdAt?.toDate?.() || new Date(0);
        const hoursSinceLast =
          (now.getTime() - lastGenTime.getTime()) / (1000 * 60 * 60);
        if (hoursSinceLast < 12) continue; // Skip if generated in last 12 hours
      }

      // Determine what type of content to generate based on proximity
      const eventDate = event.eventDate?.toDate?.() || new Date();
      const hoursUntilEvent =
        (eventDate.getTime() - now.getTime()) / (1000 * 60 * 60);

      let brandTone;
      let webInput = "";
      const schedulerPosterUrl = firstNonEmptyString([
        event.promo_poster_url,
        event.posterUrl,
        event.thumbnailUrl,
      ]);
      const schedulerMediaUrls = normalizeUrlList([
        schedulerPosterUrl,
        event.thumbnailUrl,
      ]);

      if (hoursUntilEvent <= 6) {
        brandTone = "hype";
        webInput = `FIGHT DAY CONTENT: ${event.title || "Fight Night"} is happening in ${Math.round(hoursUntilEvent)} hours! ${event.sport || "Combat Sports"}. Main event: ${event.mainEvent || event.title}. Price: $${((event.standardPriceCents || 0) / 100).toFixed(2)} AUD. Generate maximum hype content.`;
      } else if (hoursUntilEvent <= 48) {
        brandTone = "edgy";
        webInput = `FIGHT WEEK CONTENT: ${event.title || "Fight Night"} is ${Math.round(hoursUntilEvent / 24)} days away. ${event.sport || "Combat Sports"}. Generate fight week countdown content with predictions and hot takes.`;
      } else {
        brandTone = "analytical";
        webInput = `PRE-FIGHT ANALYSIS: ${event.title || "Fight Night"} is coming on ${eventDate.toLocaleDateString("en-AU")}. ${event.sport || "Combat Sports"}. ${event.description || ""}. Generate analytical preview content.`;
      }

      try {
        const requestId = `sched_${eventId}_${Date.now()}`;
        const callbackUrl = `https://${REGION}-datafightcentral.cloudfunctions.net/n8nContentCallback`;

        const payload = {
          webInput,
          platform: "all",
          postType: "text",
          brandTone,
          audienceType: "fans",
          niche:
            event.sport?.toLowerCase().replaceAll(/\s+/g, "_") || "general",
          objective: "engagement",
          eventData: {
            eventId,
            title: event.title || "",
            sport: event.sport || "",
            eventDate: eventDate.toISOString(),
            promotion: event.promotion || "",
            priceCents: event.standardPriceCents || 0,
            mainEvent: event.mainEvent || "",
            posterUrl: schedulerPosterUrl,
            thumbnailUrl: event.thumbnailUrl || schedulerPosterUrl,
            mediaUrls: schedulerMediaUrls,
          },
          mediaPlan: buildNormalizedMediaPlan({
            eventData: {
              posterUrl: schedulerPosterUrl,
              thumbnailUrl: event.thumbnailUrl || schedulerPosterUrl,
              mediaUrls: schedulerMediaUrls,
            },
          }),
          requestId,
          callbackUrl,
        };

        // Store request
        await db.collection("ai_content_requests").doc(requestId).set({
          requestId,
          userId: "system_scheduler",
          webInput,
          platform: "all",
          postType: "text",
          brandTone,
          audienceType: "fans",
          niche: payload.niche,
          objective: "engagement",
          eventData: payload.eventData,
          mediaPlan: payload.mediaPlan,
          autoPublish: true,
          autoDistribute: false,
          status: "pending",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Fire to n8n
        const response = await fetch(N8N_CONTENT_BRAIN_URL, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            ...(N8N_API_KEY ? { Authorization: `Bearer ${N8N_API_KEY}` } : {}),
          },
          body: JSON.stringify(payload),
        });

        if (response.ok) {
          const content = await response.json();
          const contentDocId = `content_${requestId}`;
          const contentMediaPlan =
            content.mediaPlan && typeof content.mediaPlan === "object"
              ? content.mediaPlan
              : undefined;
          const schedulerMediaPlanInput = contentMediaPlan
            ? {
                ...contentMediaPlan,
                posterUrl: content.suggestedMedia || "",
                assetUrls: content.suggestedMediaAssets || [],
              }
            : {
                posterUrl: content.suggestedMedia || "",
                assetUrls: content.suggestedMediaAssets || [],
              };
          const schedulerContentMediaPlan = buildNormalizedMediaPlan({
            eventData: payload.eventData,
            mediaPlan: schedulerMediaPlanInput,
          });

          await db
            .collection("ai_generated_content")
            .doc(contentDocId)
            .set({
              requestId,
              userId: "system_scheduler",
              source: "content_brain_scheduler",
              generatedAt: admin.firestore.FieldValue.serverTimestamp(),
              content,
              posts: content.posts || [],
              headline: content.headline || "",
              summary: content.summary || "",
              viralScore: content.viralScore || 0,
              suggestedMedia:
                content.suggestedMedia ||
                schedulerContentMediaPlan.primaryPreviewAssetUrl ||
                "",
              suggestedMediaAssets:
                content.suggestedMediaAssets ||
                schedulerContentMediaPlan.assetUrls ||
                [],
              mediaPlan: schedulerContentMediaPlan,
              mediaUrl:
                schedulerContentMediaPlan.primaryPreviewAssetUrl ||
                schedulerContentMediaPlan.primaryAssetUrl ||
                "",
              mediaUrls: schedulerContentMediaPlan.assetUrls || [],
              thumbnailUrl: schedulerContentMediaPlan.thumbnailUrl || "",
              published: false,
              distributed: false,
            });

          // Auto-publish to internal feed
          if (content.posts && content.posts.length > 0) {
            const primaryPost = content.posts[0];
            await db.collection("social_posts").add({
              type: "ai_generated",
              sourceService: "content_brain_scheduler",
              requestId,
              eventId,
              caption: primaryPost.caption || content.summary || "",
              title: content.headline || "",
              mediaUrl:
                schedulerContentMediaPlan.primaryPreviewAssetUrl ||
                schedulerContentMediaPlan.primaryAssetUrl ||
                "",
              mediaUrls: schedulerContentMediaPlan.assetUrls || [],
              thumbnailUrl: schedulerContentMediaPlan.thumbnailUrl || "",
              mediaPlan: schedulerContentMediaPlan,
              targetPlatforms: content.posts
                .map((p) => p.platform)
                .filter(Boolean),
              status: "ready_to_post",
              viralScore: content.viralScore || 0,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              autoGenerated: true,
            });
          }

          await db.collection("ai_content_requests").doc(requestId).update({
            status: "completed",
            contentDocId,
            completedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          generated++;
          console.log(
            `[ContentBrainScheduler] Generated content for ${event.title} (${eventId})`,
          );
        } else {
          console.warn(
            `[ContentBrainScheduler] n8n failed for ${eventId}: ${response.status}`,
          );
          await db
            .collection("ai_content_requests")
            .doc(requestId)
            .update({
              status: "failed",
              error: `n8n ${response.status}`,
            });
        }
      } catch (err) {
        console.error(
          `[ContentBrainScheduler] Error for ${eventId}:`,
          err.message,
        );
      }
    }

    console.log(
      `[ContentBrainScheduler] Run complete — generated ${generated} content pieces`,
    );
  },
);

// ─── Helper: Extract hashtags from caption ───────────────────────────────
function _extractHashtags(text) {
  const matches = text.match(/#\w+/g);
  return matches ? [...new Set(matches)] : [];
}

module.exports = {
  triggerContentBrain,
  n8nContentCallback,
  contentBrainScheduler,
  executeContentBrain,
  streamingDoctrineV1,
};
