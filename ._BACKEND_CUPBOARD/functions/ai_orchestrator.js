// ═══════════════════════════════════════════════════════════════════════════
// DFC AI ORCHESTRATOR
// Assigns, routes, and manages all AI bot tasks, ingestion, and reasoning chains
// ═══════════════════════════════════════════════════════════════════════════

const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall } = require("firebase-functions/v2/https");
const { admin, db, REGION } = require("./config");

// Firestore collection names
const TASKS_COLLECTION = "ai_tasks";
const BOTS_COLLECTION = "ai_bots";
const REASONING_COLLECTION = "reasoning_chains";
const PIPELINE_COLLECTION = "content_pipeline";
const INGESTED_COLLECTION = "ingested_content";

// ─────────────────────────────────────────────────────────────────────────────
// CONTENT LIMITS BY TIER — The Ringmaster's Throttle
// ─────────────────────────────────────────────────────────────────────────────
const TIER_LIMITS = {
  free: {
    imagesPerPost: 1,
    postsPerDay: 3,
    videosPerDay: 0,
    pipelinePriority: "low",
    aiAssists: 1,
  },
  fighter_free: {
    imagesPerPost: 1,
    postsPerDay: 5,
    videosPerDay: 1,
    pipelinePriority: "low",
    aiAssists: 2,
  },
  fighter_pro: {
    imagesPerPost: 5,
    postsPerDay: 20,
    videosPerDay: 5,
    pipelinePriority: "medium",
    aiAssists: 10,
  },
  promoter_basic: {
    imagesPerPost: 10,
    postsPerDay: 50,
    videosPerDay: 10,
    pipelinePriority: "medium",
    aiAssists: 25,
  },
  promoter_pro: {
    imagesPerPost: 25,
    postsPerDay: 200,
    videosPerDay: 50,
    pipelinePriority: "high",
    aiAssists: 100,
  },
  gym_basic: {
    imagesPerPost: 5,
    postsPerDay: 30,
    videosPerDay: 5,
    pipelinePriority: "medium",
    aiAssists: 15,
  },
  gym_pro: {
    imagesPerPost: 15,
    postsPerDay: 100,
    videosPerDay: 25,
    pipelinePriority: "high",
    aiAssists: 50,
  },
  enterprise: {
    imagesPerPost: 999,
    postsPerDay: 999,
    videosPerDay: 999,
    pipelinePriority: "critical",
    aiAssists: 999,
  },
  // Admin override — the Ringmaster
  admin: {
    imagesPerPost: 999,
    postsPerDay: 999,
    videosPerDay: 999,
    pipelinePriority: "critical",
    aiAssists: 999,
  },
};

// ─────────────────────────────────────────────────────────────────────────────
// GET USER LIMITS — Check what a user can do
// ─────────────────────────────────────────────────────────────────────────────
const getUserLimits = onCall({ region: REGION }, async (request) => {
  const { userId } = request.data;
  if (!userId) return { error: "userId required" };

  try {
    // Check if admin
    const userDoc = await db.collection("users").doc(userId).get();
    if (userDoc.exists && userDoc.data().role === "admin") {
      return {
        success: true,
        userId,
        tier: "admin",
        limits: TIER_LIMITS.admin,
      };
    }

    // Get user's subscription tier
    const entDoc = await db.collection("user_entitlements").doc(userId).get();
    const tier = entDoc.exists ? entDoc.data().tier || "free" : "free";

    // Get today's usage
    const today = new Date().toISOString().split("T")[0];
    const usageDoc = await db
      .collection("user_daily_usage")
      .doc(`${userId}_${today}`)
      .get();
    const usage = usageDoc.exists
      ? usageDoc.data()
      : { posts: 0, videos: 0, aiAssists: 0 };

    const limits = TIER_LIMITS[tier] || TIER_LIMITS.free;

    return {
      success: true,
      userId,
      tier,
      limits,
      usage,
      remaining: {
        posts: Math.max(0, limits.postsPerDay - (usage.posts || 0)),
        videos: Math.max(0, limits.videosPerDay - (usage.videos || 0)),
        aiAssists: Math.max(0, limits.aiAssists - (usage.aiAssists || 0)),
      },
    };
  } catch (err) {
    return { error: err.message };
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// CHECK CONTENT ALLOWED — Gate before pipeline intake
// ─────────────────────────────────────────────────────────────────────────────
const checkContentAllowed = onCall({ region: REGION }, async (request) => {
  const { userId, contentType, imageCount } = request.data;
  if (!userId) return { error: "userId required" };

  try {
    const limitsResult = await getUserLimits.run({ data: { userId } });
    if (limitsResult.error) return limitsResult;

    const { limits, remaining, tier } = limitsResult;

    // Check image limit
    if ((imageCount || 0) > limits.imagesPerPost) {
      return {
        allowed: false,
        reason: `Your ${tier} tier allows ${limits.imagesPerPost} image(s) per post. Upgrade to increase.`,
        tier,
        limits,
      };
    }

    // Check daily post limit
    if (contentType !== "video" && remaining.posts <= 0) {
      return {
        allowed: false,
        reason: `Daily post limit reached (${limits.postsPerDay}/day). Resets at midnight UTC.`,
        tier,
        limits,
      };
    }

    // Check daily video limit
    if (contentType === "video" && remaining.videos <= 0) {
      return {
        allowed: false,
        reason: `Daily video limit reached (${limits.videosPerDay}/day). Resets at midnight UTC.`,
        tier,
        limits,
      };
    }

    return {
      allowed: true,
      tier,
      limits,
      remaining,
      priority: limits.pipelinePriority,
    };
  } catch (err) {
    return { error: err.message };
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// RECORD USAGE — Track after successful pipeline intake
// ─────────────────────────────────────────────────────────────────────────────
const recordUsage = onCall({ region: REGION }, async (request) => {
  const { userId, contentType } = request.data;
  if (!userId) return { error: "userId required" };

  const today = new Date().toISOString().split("T")[0];
  const docRef = db.collection("user_daily_usage").doc(`${userId}_${today}`);

  const field = contentType === "video" ? "videos" : "posts";
  await docRef.set(
    {
      [field]: admin.firestore.FieldValue.increment(1),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return { success: true };
});

// ─────────────────────────────────────────────────────────────────────────────
// ORCHESTRATOR: Assign tasks to bots (every 1 min)
// ─────────────────────────────────────────────────────────────────────────────
const assignTasks = onSchedule(
  { schedule: "every 1 minutes", region: REGION },
  async () => {
    const unassignedTasks = await db
      .collection(TASKS_COLLECTION)
      .where("status", "==", "pending")
      .limit(50)
      .get();
    const botsSnap = await db
      .collection(BOTS_COLLECTION)
      .where("active", "==", true)
      .get();
    const bots = botsSnap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

    if (bots.length === 0) return;

    const batch = db.batch();
    let assigned = 0;

    for (const taskDoc of unassignedTasks.docs) {
      const bot = bots[assigned % bots.length]; // Round-robin
      batch.update(taskDoc.ref, {
        status: "assigned",
        botId: bot.id,
        assignedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      assigned++;
    }

    if (assigned > 0) await batch.commit();
    console.log(
      `Orchestrator: Assigned ${assigned} tasks to ${bots.length} bots`,
    );
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// INGESTION: Push new content into the pipeline (every 2 min)
// ─────────────────────────────────────────────────────────────────────────────
const ingestContent = onSchedule(
  { schedule: "every 2 minutes", region: REGION },
  async () => {
    const newContent = await db
      .collection(INGESTED_COLLECTION)
      .where("status", "==", "new")
      .limit(100)
      .get();
    if (newContent.empty) return;

    const batch = db.batch();
    let ingested = 0;

    for (const doc of newContent.docs) {
      const content = doc.data();

      // Push to content_pipeline at INTAKE stage
      const pipelineRef = db.collection(PIPELINE_COLLECTION).doc();
      batch.set(pipelineRef, {
        stage: "intake",
        contentType: content.type || "post",
        title: content.title || "Untitled",
        body: content.body || content.content || "",
        imageUrl: content.imageUrl || null,
        videoUrl: content.videoUrl || null,
        sourceId: doc.id,
        createdBy: content.createdBy || "orchestrator",
        targetPlatforms: content.targetPlatforms || [
          "instagram",
          "tiktok",
          "twitter",
          "facebook",
        ],
        metadata: content.metadata || {},
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        stageHistory: [
          { stage: "intake", timestamp: new Date().toISOString() },
        ],
        retryCount: 0,
        error: null,
        priority: content.priority || "medium",
      });

      // Mark source as processed
      batch.update(doc.ref, {
        status: "ingested",
        ingestedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      ingested++;
    }

    await batch.commit();
    console.log(`Orchestrator: Ingested ${ingested} items into pipeline`);
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// REASONING CHAIN: Process multi-bot decisions (every 5 min)
// ─────────────────────────────────────────────────────────────────────────────
const runReasoningChain = onSchedule(
  { schedule: "every 5 minutes", region: REGION },
  async () => {
    const chains = await db
      .collection(REASONING_COLLECTION)
      .where("status", "==", "pending")
      .limit(20)
      .get();
    if (chains.empty) return;

    const batch = db.batch();
    for (const doc of chains.docs) {
      batch.update(doc.ref, {
        status: "complete",
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    console.log(`Orchestrator: Completed ${chains.size} reasoning chains`);
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// HEARTBEAT: Register orchestrator as alive (every 24 hours)
// ─────────────────────────────────────────────────────────────────────────────
const registerOrchestrator = onSchedule(
  { schedule: "every 24 hours", region: REGION },
  async () => {
    await db.collection(BOTS_COLLECTION).doc("orchestrator").set(
      {
        id: "orchestrator",
        name: "DFC Orchestrator",
        type: "orchestrator",
        active: true,
        lastSeen: admin.firestore.FieldValue.serverTimestamp(),
        version: "2.0",
      },
      { merge: true },
    );
    console.log("Orchestrator: Heartbeat registered");
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// EXPORTS
// ─────────────────────────────────────────────────────────────────────────────
module.exports = {
  // Tier limits system
  getUserLimits,
  checkContentAllowed,
  recordUsage,
  TIER_LIMITS,
  // Scheduled orchestration
  assignTasks,
  ingestContent,
  runReasoningChain,
  registerOrchestrator,
};
