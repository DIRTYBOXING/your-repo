// ═══════════════════════════════════════════════════════════════════════════
// STRIPE BILLING — FEATURES & ENTITLEMENTS
// ═══════════════════════════════════════════════════════════════════════════
// Feature-based access control using Stripe's Entitlements system.

const { onCall, onRequest } = require("firebase-functions/v2/https");
const {
  db,
  FieldValue,
  REGION,
  stripe,
  getStripe,
  withStripeSecret,
} = require("../config");

// ─────────────────────────────────────────────────────────────────────────────
// DFC FEATURE DEFINITIONS
// ─────────────────────────────────────────────────────────────────────────────
const DFC_FEATURES = {
  // Fighter Features
  basic_profile: { name: "Basic Profile", lookup_key: "basic_profile" },
  basic_analytics: { name: "Basic Analytics", lookup_key: "basic_analytics" },
  ai_coaching: { name: "AI Coaching", lookup_key: "ai_coaching" },
  video_analysis: { name: "Video Analysis", lookup_key: "video_analysis" },
  advanced_stats: { name: "Advanced Statistics", lookup_key: "advanced_stats" },
  training_plans: { name: "Training Plans", lookup_key: "training_plans" },
  // Promoter Features
  event_management: {
    name: "Event Management",
    lookup_key: "event_management",
  },
  live_streaming: { name: "Live Streaming", lookup_key: "live_streaming" },
  ppv_access: { name: "PPV Access", lookup_key: "ppv_access" },
  advanced_analytics: {
    name: "Advanced Analytics",
    lookup_key: "advanced_analytics",
  },
  storefront: { name: "Storefront", lookup_key: "storefront" },
  // Gym Features
  member_management: {
    name: "Member Management",
    lookup_key: "member_management",
  },
  scheduling: { name: "Scheduling", lookup_key: "scheduling" },
  gym_analytics: { name: "Gym Analytics", lookup_key: "gym_analytics" },
  // Premium/Universal Features
  priority_support: {
    name: "Priority Support",
    lookup_key: "priority_support",
  },
  api_access: { name: "API Access", lookup_key: "api_access" },
  white_label: { name: "White Label", lookup_key: "white_label" },
};

// Product tier definitions
const DFC_PRODUCT_TIERS = {
  fighter_free: {
    name: "Fighter Free",
    description: "Basic fighter profile and analytics",
    features: ["basic_profile", "basic_analytics"],
  },
  fighter_pro: {
    name: "Fighter Pro",
    description: "Advanced training for serious fighters",
    features: [
      "basic_profile",
      "basic_analytics",
      "ai_coaching",
      "video_analysis",
      "advanced_stats",
      "training_plans",
    ],
  },
  promoter_basic: {
    name: "Promoter Basic",
    description: "Event management essentials",
    features: ["event_management", "basic_analytics"],
  },
  promoter_pro: {
    name: "Promoter Pro",
    description: "Full promotion toolkit with streaming",
    features: [
      "event_management",
      "basic_analytics",
      "live_streaming",
      "ppv_access",
      "advanced_analytics",
      "storefront",
    ],
  },
  gym_basic: {
    name: "Gym Basic",
    description: "Member and schedule management",
    features: ["member_management", "scheduling"],
  },
  gym_pro: {
    name: "Gym Pro",
    description: "Complete gym management suite",
    features: [
      "member_management",
      "scheduling",
      "gym_analytics",
      "storefront",
      "advanced_analytics",
    ],
  },
  enterprise: {
    name: "Enterprise",
    description: "Full platform access with API",
    features: Object.keys(DFC_FEATURES),
  },
};

// ─────────────────────────────────────────────────────────────────────────────
// CONTENT LIMITS BY TIER — The Ringmaster's Control Panel
// ─────────────────────────────────────────────────────────────────────────────
// Free = 1 photo, limited posting. Higher tiers = pump harder with less effort.
const TIER_CONTENT_LIMITS = {
  free: {
    imagesPerPost: 1,
    postsPerDay: 3,
    videosPerDay: 0,
    videoMaxSeconds: 0,
    pipelineAccess: false,
    scheduledPosts: 0,
    targetPlatforms: 1,
    aiGenerationsPerDay: 0,
    storageBytes: 50 * 1024 * 1024, // 50 MB
  },
  fighter_free: {
    imagesPerPost: 1,
    postsPerDay: 5,
    videosPerDay: 1,
    videoMaxSeconds: 30,
    pipelineAccess: false,
    scheduledPosts: 0,
    targetPlatforms: 2,
    aiGenerationsPerDay: 3,
    storageBytes: 100 * 1024 * 1024, // 100 MB
  },
  fighter_pro: {
    imagesPerPost: 5,
    postsPerDay: 20,
    videosPerDay: 5,
    videoMaxSeconds: 180,
    pipelineAccess: true,
    scheduledPosts: 10,
    targetPlatforms: 4,
    aiGenerationsPerDay: 50,
    storageBytes: 1024 * 1024 * 1024, // 1 GB
  },
  promoter_basic: {
    imagesPerPost: 3,
    postsPerDay: 10,
    videosPerDay: 2,
    videoMaxSeconds: 60,
    pipelineAccess: true,
    scheduledPosts: 5,
    targetPlatforms: 3,
    aiGenerationsPerDay: 20,
    storageBytes: 500 * 1024 * 1024, // 500 MB
  },
  promoter_pro: {
    imagesPerPost: 10,
    postsPerDay: 100,
    videosPerDay: 20,
    videoMaxSeconds: 600,
    pipelineAccess: true,
    scheduledPosts: 50,
    targetPlatforms: 6,
    aiGenerationsPerDay: 200,
    storageBytes: 10 * 1024 * 1024 * 1024, // 10 GB
  },
  gym_basic: {
    imagesPerPost: 3,
    postsPerDay: 10,
    videosPerDay: 2,
    videoMaxSeconds: 120,
    pipelineAccess: false,
    scheduledPosts: 5,
    targetPlatforms: 2,
    aiGenerationsPerDay: 10,
    storageBytes: 500 * 1024 * 1024, // 500 MB
  },
  gym_pro: {
    imagesPerPost: 10,
    postsPerDay: 50,
    videosPerDay: 10,
    videoMaxSeconds: 300,
    pipelineAccess: true,
    scheduledPosts: 25,
    targetPlatforms: 4,
    aiGenerationsPerDay: 100,
    storageBytes: 5 * 1024 * 1024 * 1024, // 5 GB
  },
  enterprise: {
    imagesPerPost: 50,
    postsPerDay: -1, // unlimited
    videosPerDay: -1, // unlimited
    videoMaxSeconds: 3600, // 1 hour
    pipelineAccess: true,
    scheduledPosts: -1, // unlimited
    targetPlatforms: -1, // all
    aiGenerationsPerDay: -1, // unlimited
    storageBytes: -1, // unlimited
  },
};

function getUsageDateKey() {
  return new Date().toISOString().split("T")[0];
}

function getDefaultUsage() {
  return {
    postsToday: 0,
    videosToday: 0,
    aiGenerationsToday: 0,
    imagesUploadedToday: 0,
  };
}

function determineTierFromFeatures(activeFeatures = []) {
  let tier = "free";
  let matchedFeatureCount = 0;

  for (const [tierKey, tierDef] of Object.entries(DFC_PRODUCT_TIERS)) {
    const hasFullTierAccess = tierDef.features.every((feature) =>
      activeFeatures.includes(feature),
    );
    if (hasFullTierAccess && tierDef.features.length > matchedFeatureCount) {
      tier = tierKey;
      matchedFeatureCount = tierDef.features.length;
    }
  }

  return tier;
}

async function resolveEntitlementSubject(userId) {
  const v2Doc = await db.collection("connected_accounts_v2").doc(userId).get();
  const stripeAccountId = v2Doc.exists ? v2Doc.data().stripeAccountId : null;
  if (stripeAccountId) {
    return { stripeId: stripeAccountId, idType: "account" };
  }

  const custDoc = await db.collection("stripe_customers").doc(userId).get();
  const stripeCustomerId = custDoc.exists
    ? custDoc.data().stripeCustomerId
    : null;
  if (stripeCustomerId) {
    return { stripeId: stripeCustomerId, idType: "customer" };
  }

  return { stripeId: null, idType: null };
}

async function listActiveEntitlementsForSubject(stripeId, idType) {
  if (idType === "account") {
    return stripe.entitlements.activeEntitlements.list({
      customer_account: stripeId,
      limit: 100,
    });
  }

  return stripe.entitlements.activeEntitlements.list({
    customer: stripeId,
    limit: 100,
  });
}

function mapEntitlementFeatures(entitlements) {
  return entitlements.data
    .map((entitlement) => entitlement.feature.lookup_key)
    .filter(Boolean);
}

function mapEntitlementDetails(entitlements) {
  return entitlements.data.map((entitlement) => ({
    id: entitlement.id,
    featureId: entitlement.feature.id,
    lookupKey: entitlement.feature.lookup_key,
  }));
}

async function cacheUserEntitlements(userId, payload, extraFields = {}) {
  await db
    .collection("user_entitlements")
    .doc(userId)
    .set(
      {
        ...payload,
        ...extraFields,
        lastChecked: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
}

async function resolveUserIdByStripeId(stripeId) {
  const v2Query = await db
    .collection("connected_accounts_v2")
    .where("stripeAccountId", "==", stripeId)
    .limit(1)
    .get();
  if (!v2Query.empty) {
    return v2Query.docs[0].id;
  }

  const v1Query = await db
    .collection("stripe_customers")
    .where("stripeCustomerId", "==", stripeId)
    .limit(1)
    .get();
  return v1Query.empty ? null : v1Query.docs[0].id;
}

function extractActiveFeaturesFromSummary(summary) {
  return (
    summary.entitlements?.data
      ?.map((entitlement) => entitlement.feature?.lookup_key)
      .filter(Boolean) || []
  );
}

async function syncEntitlementSummary(summary, eventId) {
  const stripeId = summary.customer_account || summary.customer;
  if (!stripeId) {
    return false;
  }

  const userId = await resolveUserIdByStripeId(stripeId);
  if (!userId) {
    return false;
  }

  const activeFeatures = extractActiveFeaturesFromSummary(summary);
  const tier = determineTierFromFeatures(activeFeatures);

  await cacheUserEntitlements(
    userId,
    { stripeId, activeFeatures, tier },
    { lastUpdatedByWebhook: FieldValue.serverTimestamp() },
  );

  await db.collection("entitlement_logs").add({
    userId,
    stripeId,
    activeFeatures,
    tier,
    eventId,
    timestamp: FieldValue.serverTimestamp(),
  });

  return true;
}

async function getTierLimitsAndUsage(userId) {
  const entDoc = await db.collection("user_entitlements").doc(userId).get();
  const tier = entDoc.exists ? entDoc.data().tier || "free" : "free";
  const limits = TIER_CONTENT_LIMITS[tier] || TIER_CONTENT_LIMITS.free;
  const today = getUsageDateKey();
  const usageDoc = await db
    .collection("user_daily_usage")
    .doc(`${userId}_${today}`)
    .get();
  const usage = usageDoc.exists
    ? { ...getDefaultUsage(), ...usageDoc.data() }
    : getDefaultUsage();

  return { tier, limits, usage, today };
}

function buildUpgradeMessage(tier) {
  return tier === "free" || tier.endsWith("_free")
    ? "Upgrade to unlock more content power!"
    : "Upgrade to Enterprise for unlimited access.";
}

function collectContentLimitViolations({
  contentType,
  imageCount,
  videoSeconds,
  limits,
  usage,
  tier,
}) {
  const violations = [];

  if (imageCount && imageCount > limits.imagesPerPost) {
    violations.push(
      `Max ${limits.imagesPerPost} images per post (tier: ${tier})`,
    );
  }

  if (
    contentType === "post" &&
    limits.postsPerDay !== -1 &&
    usage.postsToday >= limits.postsPerDay
  ) {
    violations.push(
      `Daily post limit reached: ${limits.postsPerDay} posts (tier: ${tier})`,
    );
  }

  if (
    contentType === "video" &&
    limits.videosPerDay !== -1 &&
    usage.videosToday >= limits.videosPerDay
  ) {
    violations.push(
      `Daily video limit reached: ${limits.videosPerDay} videos (tier: ${tier})`,
    );
  }

  if (videoSeconds && videoSeconds > limits.videoMaxSeconds) {
    violations.push(
      `Max video duration: ${limits.videoMaxSeconds}s (tier: ${tier})`,
    );
  }

  if (contentType === "pipeline" && !limits.pipelineAccess) {
    violations.push(
      `Pipeline access requires upgraded tier (current: ${tier})`,
    );
  }

  return violations;
}

function collectPipelineGateViolations({
  imageUrls,
  videoSeconds,
  targetPlatforms,
  limits,
  usage,
}) {
  const violations = [];
  const imageCount = Array.isArray(imageUrls) ? imageUrls.length : 0;
  const platformCount = Array.isArray(targetPlatforms)
    ? targetPlatforms.length
    : 1;

  if (imageCount > limits.imagesPerPost) {
    violations.push(
      `Max ${limits.imagesPerPost} images (you have ${imageCount})`,
    );
  }

  if (videoSeconds && videoSeconds > limits.videoMaxSeconds) {
    violations.push(
      `Max video: ${limits.videoMaxSeconds}s (yours: ${videoSeconds}s)`,
    );
  }

  if (limits.targetPlatforms !== -1 && platformCount > limits.targetPlatforms) {
    violations.push(
      `Max ${limits.targetPlatforms} platforms (you selected ${platformCount})`,
    );
  }

  if (limits.postsPerDay !== -1 && usage.postsToday >= limits.postsPerDay) {
    violations.push(`Daily limit reached: ${limits.postsPerDay} posts`);
  }

  return violations;
}

// ─────────────────────────────────────────────────────────────────────────────
// INITIALIZE FEATURES IN STRIPE
// ─────────────────────────────────────────────────────────────────────────────
const initializeStripeFeatures = onCall(
  withStripeSecret({ region: REGION }),
  async () => {
    if (!getStripe()) return { error: "Stripe not configured" };

    const results = { created: [], existing: [], errors: [] };

    for (const [key, feature] of Object.entries(DFC_FEATURES)) {
      try {
        const existing = await stripe.entitlements.features.list({
          lookup_key: feature.lookup_key,
          limit: 1,
        });
        if (existing.data.length > 0) {
          results.existing.push(key);
          continue;
        }

        const created = await stripe.entitlements.features.create({
          name: feature.name,
          lookup_key: feature.lookup_key,
        });
        results.created.push({ key, id: created.id });

        await db.collection("stripe_features").doc(key).set({
          stripeFeatureId: created.id,
          name: feature.name,
          lookupKey: feature.lookup_key,
          createdAt: FieldValue.serverTimestamp(),
        });
      } catch (err) {
        results.errors.push({ key, error: err.message });
      }
    }

    return {
      success: true,
      summary: {
        created: results.created.length,
        existing: results.existing.length,
        errors: results.errors.length,
      },
      details: results,
    };
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// CREATE PRODUCT WITH FEATURES
// ─────────────────────────────────────────────────────────────────────────────
const createProductWithFeatures = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    if (!getStripe()) return { error: "Stripe not configured" };

    const {
      tierKey,
      customName,
      customDescription,
      customFeatures,
      priceInCents,
      currency,
      billingInterval,
    } = request.data;

    try {
      let productName, productDescription, featureKeys;

      if (tierKey && DFC_PRODUCT_TIERS[tierKey]) {
        const tier = DFC_PRODUCT_TIERS[tierKey];
        productName = customName || tier.name;
        productDescription = customDescription || tier.description;
        featureKeys = tier.features;
      } else if (customName && customFeatures) {
        productName = customName;
        productDescription = customDescription || "";
        featureKeys = customFeatures;
      } else {
        return { error: "Provide tierKey or customName with customFeatures" };
      }

      const product = await stripe.products.create({
        name: productName,
        description: productDescription,
        metadata: {
          tierKey: tierKey || "custom",
          featureCount: String(featureKeys.length),
        },
      });

      const price = await stripe.prices.create({
        product: product.id,
        unit_amount: priceInCents || 0,
        currency: (currency || "aud").toLowerCase(),
        recurring:
          priceInCents > 0
            ? { interval: billingInterval || "month" }
            : undefined,
      });

      const attachedFeatures = [];
      for (const featureKey of featureKeys) {
        const featureDoc = await db
          .collection("stripe_features")
          .doc(featureKey)
          .get();
        if (!featureDoc.exists) continue;

        try {
          await stripe.products.createFeature(product.id, {
            entitlement_feature: featureDoc.data().stripeFeatureId,
          });
          attachedFeatures.push(featureKey);
        } catch (err) {
          console.error(`Failed to attach ${featureKey}:`, err.message);
        }
      }

      await db
        .collection("stripe_products")
        .doc(product.id)
        .set({
          stripeProductId: product.id,
          stripePriceId: price.id,
          name: productName,
          description: productDescription,
          tierKey: tierKey || "custom",
          features: attachedFeatures,
          priceInCents: priceInCents || 0,
          currency: (currency || "aud").toLowerCase(),
          billingInterval: billingInterval || "month",
          createdAt: FieldValue.serverTimestamp(),
        });

      return {
        success: true,
        productId: product.id,
        priceId: price.id,
        name: productName,
        attachedFeatures,
      };
    } catch (err) {
      console.error("Error creating product:", err);
      return { error: err.message };
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// GET ACTIVE ENTITLEMENTS
// ─────────────────────────────────────────────────────────────────────────────
const getActiveEntitlements = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    if (!getStripe()) return { error: "Stripe not configured" };

    const { userId } = request.data;
    if (!userId) return { error: "userId is required" };

    try {
      const { stripeId, idType } = await resolveEntitlementSubject(userId);
      if (!stripeId)
        return {
          success: true,
          userId,
          entitlements: [],
          features: [],
          tier: "free",
        };

      const entitlements = await listActiveEntitlementsForSubject(
        stripeId,
        idType,
      );
      const activeFeatures = mapEntitlementFeatures(entitlements);
      const tier = determineTierFromFeatures(activeFeatures);

      await cacheUserEntitlements(userId, {
        stripeId,
        idType,
        activeFeatures,
        tier,
      });

      return {
        success: true,
        userId,
        stripeId,
        entitlements: mapEntitlementDetails(entitlements),
        features: activeFeatures,
        tier,
      };
    } catch (err) {
      console.error("Error getting entitlements:", err);
      return { error: err.message };
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// CHECK FEATURE ACCESS
// ─────────────────────────────────────────────────────────────────────────────
const checkFeatureAccess = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    const { userId, featureKey } = request.data;
    if (!userId || !featureKey)
      return { error: "userId and featureKey required" };

    try {
      const cacheDoc = await db
        .collection("user_entitlements")
        .doc(userId)
        .get();
      if (cacheDoc.exists) {
        const cached = cacheDoc.data();
        const cacheAge = Date.now() - (cached.lastChecked?.toMillis() || 0);
        if (cacheAge < 5 * 60 * 1000) {
          return {
            success: true,
            hasAccess: cached.activeFeatures?.includes(featureKey) || false,
            cached: true,
            tier: cached.tier,
          };
        }
      }

      const result = await getActiveEntitlements.run({ data: { userId } });
      if (result.error) return { error: result.error };

      return {
        success: true,
        hasAccess: result.features?.includes(featureKey) || false,
        cached: false,
        tier: result.tier,
      };
    } catch (err) {
      console.error("Error checking access:", err);
      return { error: err.message };
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// WEBHOOK: ENTITLEMENT EVENTS
// ─────────────────────────────────────────────────────────────────────────────
const stripeEntitlementWebhook = onRequest(
  withStripeSecret({ region: REGION }),
  async (req, res) => {
    if (!getStripe()) return res.status(500).send("Stripe not configured");
    if (req.method !== "POST")
      return res.status(405).send("Method not allowed");

    const sig = req.headers["stripe-signature"];
    const webhookSecret = (
      process.env.STRIPE_WEBHOOK_SECRET_ENTITLEMENTS || ""
    ).trim();
    if (!webhookSecret)
      return res.status(500).send("Webhook secret not configured");

    let event;
    try {
      event = stripe.webhooks.constructEvent(
        req.rawBody || req.body,
        sig,
        webhookSecret,
      );
    } catch (err) {
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    try {
      if (event.type === "entitlements.active_entitlement_summary.updated") {
        await syncEntitlementSummary(event.data.object, event.id);
      }
      return res.status(200).send("OK");
    } catch (err) {
      console.error("Entitlement webhook error:", err);
      return res.status(500).send(`Error: ${err.message}`);
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// LIST PRODUCT TIERS
// ─────────────────────────────────────────────────────────────────────────────
const listProductTiers = onCall(
  withStripeSecret({ region: REGION }),
  async () => {
    try {
      const productsSnapshot = await db
        .collection("stripe_products")
        .orderBy("createdAt", "desc")
        .get();
      const products = productsSnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      const tiers = Object.entries(DFC_PRODUCT_TIERS).map(([key, tier]) => ({
        tierKey: key,
        name: tier.name,
        description: tier.description,
        featureCount: tier.features.length,
        features: tier.features,
      }));

      return {
        success: true,
        products,
        availableTiers: tiers,
        allFeatures: Object.entries(DFC_FEATURES).map(([key, f]) => ({
          key,
          name: f.name,
          lookupKey: f.lookup_key,
        })),
      };
    } catch (err) {
      console.error("Error listing tiers:", err);
      return { error: err.message };
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// GET USER CONTENT LIMITS — The Pipeline Gatekeeper
// ─────────────────────────────────────────────────────────────────────────────
const getUserContentLimits = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    const { userId } = request.data;
    if (!userId) return { error: "userId is required" };

    try {
      const { tier, limits, usage } = await getTierLimitsAndUsage(userId);

      return {
        success: true,
        userId,
        tier,
        limits,
        usage,
        remaining: {
          posts:
            limits.postsPerDay === -1
              ? "unlimited"
              : Math.max(0, limits.postsPerDay - usage.postsToday),
          videos:
            limits.videosPerDay === -1
              ? "unlimited"
              : Math.max(0, limits.videosPerDay - usage.videosToday),
          aiGenerations:
            limits.aiGenerationsPerDay === -1
              ? "unlimited"
              : Math.max(
                  0,
                  limits.aiGenerationsPerDay - usage.aiGenerationsToday,
                ),
        },
        canAccessPipeline: limits.pipelineAccess,
      };
    } catch (err) {
      console.error("Error getting content limits:", err);
      return { error: err.message };
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// CHECK CONTENT LIMIT — Gate before posting
// ─────────────────────────────────────────────────────────────────────────────
const checkContentLimit = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    const { userId, contentType, imageCount, videoSeconds } = request.data;
    if (!userId) return { error: "userId is required" };

    try {
      const { tier, limits, usage } = await getTierLimitsAndUsage(userId);
      const violations = collectContentLimitViolations({
        contentType,
        imageCount,
        videoSeconds,
        limits,
        usage,
        tier,
      });

      if (violations.length > 0) {
        return {
          success: false,
          allowed: false,
          tier,
          violations,
          upgradeMessage: buildUpgradeMessage(tier),
        };
      }

      return { success: true, allowed: true, tier, limits };
    } catch (err) {
      console.error("Error checking content limit:", err);
      return { error: err.message };
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// RECORD CONTENT USAGE — Track daily consumption
// ─────────────────────────────────────────────────────────────────────────────
const recordContentUsage = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    const { userId, contentType, imageCount } = request.data;
    if (!userId) return { error: "userId is required" };

    try {
      const today = getUsageDateKey();
      const docRef = db
        .collection("user_daily_usage")
        .doc(`${userId}_${today}`);

      const increment = FieldValue.increment(1);
      const updates = { lastUpdated: FieldValue.serverTimestamp() };

      if (contentType === "post") updates.postsToday = increment;
      if (contentType === "video") updates.videosToday = increment;
      if (contentType === "ai_generation")
        updates.aiGenerationsToday = increment;
      if (imageCount)
        updates.imagesUploadedToday = FieldValue.increment(imageCount);

      await docRef.set(updates, { merge: true });

      return { success: true, recorded: contentType, date: today };
    } catch (err) {
      console.error("Error recording usage:", err);
      return { error: err.message };
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// PIPELINE GATE — Full validation before pipeline injection
// ─────────────────────────────────────────────────────────────────────────────
const pipelineGate = onCall(
  withStripeSecret({ region: REGION }),
  async (request) => {
    const { userId, imageUrls, videoSeconds, targetPlatforms } = request.data;
    if (!userId) return { error: "userId is required" };

    try {
      const { tier, limits, usage, today } =
        await getTierLimitsAndUsage(userId);

      // Pipeline access check
      if (!limits.pipelineAccess) {
        return {
          success: false,
          allowed: false,
          reason: "PIPELINE_LOCKED",
          message: `Pipeline access requires Pro tier or higher. Current tier: ${tier}`,
          upgradeRequired: true,
        };
      }

      const violations = collectPipelineGateViolations({
        imageUrls,
        videoSeconds,
        targetPlatforms,
        limits,
        usage,
      });

      if (violations.length > 0) {
        return {
          success: false,
          allowed: false,
          reason: "LIMIT_EXCEEDED",
          tier,
          violations,
          limits,
        };
      }

      // All clear — record usage and approve
      const increment = FieldValue.increment(1);
      await db.collection("user_daily_usage").doc(`${userId}_${today}`).set(
        {
          postsToday: increment,
          lastUpdated: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      return {
        success: true,
        allowed: true,
        tier,
        message: "PIPELINE UNLOCKED — Content cleared for injection.",
        firepower: {
          imagesAllowed: limits.imagesPerPost,
          platformsAllowed:
            limits.targetPlatforms === -1
              ? "unlimited"
              : limits.targetPlatforms,
          remainingPostsToday:
            limits.postsPerDay === -1
              ? "unlimited"
              : limits.postsPerDay - usage.postsToday - 1,
        },
      };
    } catch (err) {
      console.error("Pipeline gate error:", err);
      return { error: err.message };
    }
  },
);

module.exports = {
  initializeStripeFeatures,
  createProductWithFeatures,
  getActiveEntitlements,
  checkFeatureAccess,
  stripeEntitlementWebhook,
  listProductTiers,
  getUserContentLimits,
  checkContentLimit,
  recordContentUsage,
  pipelineGate,
  DFC_FEATURES,
  DFC_PRODUCT_TIERS,
  TIER_CONTENT_LIMITS,
};
