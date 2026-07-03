// ═══════════════════════════════════════════════════════════════════════════
// PIPELINE SYNC — Connects Event Manager stages to Atlas Orchestrator
// POST-style callable: accepts eventId, assetIds, stages, CTAs, priority
// Routes to correct bots at each stage of the pipeline.
// ═══════════════════════════════════════════════════════════════════════════

const { onCall } = require("firebase-functions/v2/https");
const { FieldValue } = require("firebase-admin/firestore");
const { admin, db, REGION } = require("../config");

const serverTimestamp = () => FieldValue.serverTimestamp();

const JOBS_COLLECTION = "atlas_jobs";
const PIPELINE_COLLECTION = "content_pipeline";

// Stage → bot + task mapping (mirrors atlas_orchestrator_service.dart)
const STAGE_BOT_MAP = {
  warroom: [
    {
      botId: "hype_bot_v2",
      tasks: ["generate_clips", "generate_captions", "hashtags"],
    },
  ],
  review: [
    {
      botId: "guardian_bot_v1",
      tasks: ["safety_moderation", "toxicity_check"],
    },
  ],
  marketPrep: [
    {
      botId: "campaign_bot_v1",
      tasks: ["schedule_posts", "platform_formatting"],
    },
    { botId: "trend_bot_v1", tasks: ["trend_analysis", "optimal_timing"] },
  ],
  export: [
    {
      botId: "viral_bot_v1",
      tasks: ["micro_influencer_seeds", "cross_platform_push"],
    },
    {
      botId: "analytics_bot_v1",
      tasks: ["roas_calculation", "reach_estimation"],
    },
  ],
};

// ═══════════════════════════════════════════════════════════════════════════
// SYNC TO PIPELINE — Main endpoint
// ═══════════════════════════════════════════════════════════════════════════
const pipelineSync = onCall({ region: REGION }, async (request) => {
  const {
    eventId,
    assetIds,
    stages,
    priority,
    metadata,
    publishPlatforms,
    microInfluencers,
    estimatedSpendUsd,
  } = request.data || {};

  if (!eventId) return { status: "error", message: "eventId required" };
  if (!assetIds || !Array.isArray(assetIds) || assetIds.length === 0) {
    return { status: "error", message: "assetIds array required" };
  }

  const stageList = stages || ["warroom"];
  const jobPriority = priority || "normal";
  const jobsCreated = [];

  const batch = db.batch();

  for (const assetId of assetIds) {
    // Update pipeline doc stage
    const pipelineRef = db.collection(PIPELINE_COLLECTION).doc(assetId);
    const pipelineDoc = await pipelineRef.get();
    if (pipelineDoc.exists) {
      batch.update(pipelineRef, {
        stage: stageList[0],
        updatedAt: serverTimestamp(),
        stageHistory: FieldValue.arrayUnion({
          stage: stageList[0],
          timestamp: new Date().toISOString(),
          trigger: "pipeline_sync",
        }),
      });
    }

    // Create jobs for each stage
    for (const stage of stageList) {
      const botConfigs = STAGE_BOT_MAP[stage];
      if (!botConfigs) {
        console.warn(`Unknown stage: ${stage}`);
        continue;
      }

      for (const config of botConfigs) {
        const jobRef = db.collection(JOBS_COLLECTION).doc();
        const jobData = {
          assignedBot: config.botId,
          eventId,
          assetId,
          stage,
          tasks: config.tasks,
          priority: jobPriority,
          status: "pending",
          title: metadata?.title || "",
          eventName: metadata?.eventName || "",
          publishPlatforms: publishPlatforms || ["tiktok", "instagram"],
          microInfluencers: microInfluencers || [],
          estimatedSpendUsd: estimatedSpendUsd || 0,
          requiresLegal: metadata?.requiresLegal || false,
          metadata: metadata || {},
          retryCount: 0,
          createdAt: serverTimestamp(),
        };
        batch.set(jobRef, jobData);
        jobsCreated.push({
          jobId: jobRef.id,
          bot: config.botId,
          stage,
          tasks: config.tasks,
        });
      }
    }
  }

  await batch.commit();

  // Log pipeline sync event
  await db.collection("atlas_events").add({
    type: "pipeline_sync",
    eventId,
    assetCount: assetIds.length,
    stages: stageList,
    jobsCreated: jobsCreated.length,
    priority: jobPriority,
    emittedAt: serverTimestamp(),
  });

  return {
    status: "ok",
    eventId,
    assetCount: assetIds.length,
    jobsCreated: jobsCreated.length,
    jobs: jobsCreated,
  };
});

// ═══════════════════════════════════════════════════════════════════════════
// SEED JOB — Quick single-asset injection for DM outreach / viral seeding
// ═══════════════════════════════════════════════════════════════════════════
const pipelineSeedJob = onCall({ region: REGION }, async (request) => {
  const {
    assetId,
    channels,
    microInfluencers,
    geoTargets,
    eventName,
    consentText,
    dmTemplate,
    estimatedSpendUsd,
  } = request.data || {};

  if (!assetId) return { status: "error", message: "assetId required" };

  const channelList = channels || ["tiktok", "instagram"];
  const influencerCount = microInfluencers || 10;
  const geo = geoTargets || ["Brisbane", "Auckland"];

  // Create viral bot + hype bot jobs
  const batch = db.batch();
  const jobsCreated = [];

  // HypeBot job for content generation
  const hypeRef = db.collection(JOBS_COLLECTION).doc();
  batch.set(hypeRef, {
    assignedBot: "hype_bot_v2",
    assetId,
    stage: "export",
    tasks: ["generate_clips", "generate_captions", "dm_outreach_copy"],
    status: "pending",
    eventName: eventName || "",
    publishPlatforms: channelList,
    estimatedSpendUsd: estimatedSpendUsd || 0,
    dmTemplate:
      dmTemplate || "Hey {handle}, early access to {event}. DM us for a pass.",
    consentText: consentText || "",
    metadata: { geoTargets: geo, influencerTarget: influencerCount },
    retryCount: 0,
    createdAt: serverTimestamp(),
  });
  jobsCreated.push({ jobId: hypeRef.id, bot: "hype_bot_v2" });

  // Viral bot job for distribution seeding
  const viralRef = db.collection(JOBS_COLLECTION).doc();
  batch.set(viralRef, {
    assignedBot: "viral_bot_v1",
    assetId,
    stage: "export",
    tasks: ["micro_influencer_seeds"],
    status: "pending",
    eventName: eventName || "",
    channels: channelList,
    geoTargets: geo,
    influencerTarget: influencerCount,
    metadata: { consentText: consentText || "" },
    retryCount: 0,
    createdAt: serverTimestamp(),
  });
  jobsCreated.push({ jobId: viralRef.id, bot: "viral_bot_v1" });

  await batch.commit();

  return {
    status: "ok",
    assetId,
    channels: channelList,
    geoTargets: geo,
    jobsCreated: jobsCreated.length,
    jobs: jobsCreated,
  };
});

module.exports = {
  pipelineSync,
  pipelineSeedJob,
};
