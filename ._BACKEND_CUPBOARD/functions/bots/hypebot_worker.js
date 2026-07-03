// ═══════════════════════════════════════════════════════════════════════════
// HYPEBOT v2 — Publish Worker with TikTok, DM Seeding, Approval Gating
// No fake content. No demo data. Production-ready bot worker.
// ═══════════════════════════════════════════════════════════════════════════

const { onCall, onSchedule } = require("firebase-functions/v2/https");
const { onSchedule: onScheduleV2 } = require("firebase-functions/v2/scheduler");
const { admin, db, REGION, geminiModel } = require("../config");

const JOBS_COLLECTION = "atlas_jobs";
const APPROVALS_COLLECTION = "atlas_approvals";
const EVENTS_COLLECTION = "atlas_events";
const INFLUENCERS_COLLECTION = "influencers";
const DLQ_COLLECTION = "atlas_dlq";
const BOTS_COLLECTION = "ai_bots";

// Thresholds — configurable via Remote Config or env
const SPEND_APPROVAL_THRESHOLD = Number(
  process.env.SPEND_APPROVAL_THRESHOLD || 200,
);
const DM_APPROVAL_THRESHOLD = Number(process.env.DM_APPROVAL_THRESHOLD || 50);
const TIKTOK_RATE_PER_MIN = Number(process.env.TIKTOK_RATE_PER_MIN || 6);
const DM_RATE_PER_HOUR = Number(process.env.DM_RATE_PER_HOUR || 60);
const MAX_RETRIES = 3;

// ─── Rate Limiter (in-memory, resets per instance lifecycle) ─────────────
const rateBuckets = {
  tiktok: {
    tokens: TIKTOK_RATE_PER_MIN,
    lastRefill: Date.now(),
    interval: 60000,
    max: TIKTOK_RATE_PER_MIN,
  },
  dm: {
    tokens: DM_RATE_PER_HOUR,
    lastRefill: Date.now(),
    interval: 3600000,
    max: DM_RATE_PER_HOUR,
  },
};

function consumeToken(bucketName) {
  const bucket = rateBuckets[bucketName];
  if (!bucket) return false;
  const now = Date.now();
  const elapsed = now - bucket.lastRefill;
  if (elapsed >= bucket.interval) {
    bucket.tokens = bucket.max;
    bucket.lastRefill = now;
  }
  if (bucket.tokens > 0) {
    bucket.tokens--;
    return true;
  }
  return false;
}

// ─── Emit observability event to Firestore ───────────────────────────────
async function emitEvent(event) {
  try {
    await db.collection(EVENTS_COLLECTION).add({
      ...event,
      emittedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (err) {
    console.error("emitEvent error", err.message);
  }
}

// ─── Dead Letter Queue ───────────────────────────────────────────────────
async function sendToDLQ(jobId, reason, details) {
  await db.collection(DLQ_COLLECTION).add({
    jobId,
    reason,
    details: typeof details === "string" ? details : JSON.stringify(details),
    bot: "HypeBot_v2",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await emitEvent({ type: "dlq_entry", bot: "HypeBot_v2", jobId, reason });
}

// ─── Content Factory call (Gemini-powered) ───────────────────────────────
async function generateContentVariants(assetData, tasks) {
  const outputs = [];
  const models = [];
  let confidence = 0.5;

  if (geminiModel) {
    try {
      const prompt = `You are the DFC Content Factory. Given this fight asset, generate promotional content.
Asset: ${JSON.stringify(assetData)}
Tasks: ${tasks.join(", ")}

Return ONLY valid JSON with this structure:
{
  "outputs": [{"type": "caption", "format": "text", "content": "..."},{"type": "hashtags", "format": "text", "content": "..."}],
  "confidence": 0.85
}`;
      const result = await geminiModel.generateContent(prompt);
      let text = result.response.text().trim();
      text = text
        .replace(/^```(?:json)?\n?/i, "")
        .replace(/\n?```$/i, "")
        .trim();
      const parsed = JSON.parse(text);
      outputs.push(...(parsed.outputs || []));
      confidence = parsed.confidence || 0.8;
      models.push("gemini-2.0-flash");
    } catch (err) {
      console.error("Content Factory Gemini error:", err.message);
      // Fallback outputs
      outputs.push(
        {
          type: "caption",
          format: "text",
          content: assetData.title || "Fight Night — Watch LIVE",
        },
        {
          type: "hashtags",
          format: "text",
          content: "#DFC #FightNight #CombatSports #LivePPV",
        },
      );
      models.push("fallback");
      confidence = 0.3;
    }
  } else {
    outputs.push(
      {
        type: "caption",
        format: "text",
        content: assetData.title || "Fight Night — Watch LIVE",
      },
      {
        type: "hashtags",
        format: "text",
        content: "#DFC #FightNight #CombatSports #LivePPV",
      },
    );
    models.push("fallback");
    confidence = 0.3;
  }

  return { outputs, models, confidence };
}

// ─── TikTok Publish (connector endpoint — calls your real connector) ─────
async function publishToTikTok(clipData, caption, metadata) {
  if (!consumeToken("tiktok")) {
    throw new Error("RATE_LIMITED: TikTok publish rate exceeded");
  }
  // Write publish intent to Firestore for connector pickup
  const ref = await db.collection("connector_publish_queue").add({
    platform: "tiktok",
    clipUrl: clipData.url || clipData.content || "",
    caption,
    metadata,
    status: "pending",
    retryCount: 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { id: ref.id, status: "queued" };
}

// ─── DM Seeding (consent-gated, rate-limited) ────────────────────────────
async function sendDMToInfluencer(handle, message, metadata) {
  if (!consumeToken("dm")) {
    throw new Error("RATE_LIMITED: DM rate exceeded");
  }
  // Verify consent exists in Firestore
  const consentSnap = await db
    .collection(INFLUENCERS_COLLECTION)
    .where("handle", "==", handle)
    .where("consent", "==", true)
    .limit(1)
    .get();

  if (consentSnap.empty) {
    console.log("Skipping DM — no valid consent for", handle);
    return { id: null, status: "skipped_no_consent" };
  }

  // Queue DM for connector pickup
  const ref = await db.collection("connector_dm_queue").add({
    platform: metadata.platform || "tiktok",
    handle,
    message,
    metadata,
    status: "pending",
    retryCount: 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { id: ref.id, status: "queued" };
}

// ─── Enqueue for War Room approval ───────────────────────────────────────
async function enqueueApproval(jobId, payload) {
  const ref = await db.collection(APPROVALS_COLLECTION).add({
    jobId,
    ...payload,
    status: "pending",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await emitEvent({
    type: "approval_enqueued",
    bot: "HypeBot_v2",
    jobId,
    ticketId: ref.id,
  });
  return ref.id;
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN JOB PROCESSOR
// ═══════════════════════════════════════════════════════════════════════════
async function processJob(jobDoc) {
  const job = jobDoc.data();
  const jobId = jobDoc.id;
  console.log("HypeBot_v2 processing job", jobId, "asset", job.assetId);

  // Mark as processing
  await jobDoc.ref.update({
    status: "processing",
    processingBot: "HypeBot_v2",
    processingStartedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  try {
    // 1. Generate content variants
    const tasks = job.tasks || ["caption_variants", "hashtags", "hype_copy"];
    const cf = await generateContentVariants(
      {
        title: job.title || "",
        assetId: job.assetId,
        eventName: job.eventName || "",
      },
      tasks,
    );

    const provenance = { models: cf.models, confidence: cf.confidence };

    // 2. Determine if approval is needed
    const estimatedSpendUsd = job.estimatedSpendUsd || 0;
    const microInfluencers = job.microInfluencers || [];
    const requiresLegal = job.requiresLegal || false;

    const approvalNeeded =
      estimatedSpendUsd >= SPEND_APPROVAL_THRESHOLD ||
      requiresLegal ||
      (microInfluencers.length > 0 &&
        estimatedSpendUsd >= DM_APPROVAL_THRESHOLD) ||
      cf.confidence < 0.4;

    // 3. Write results back to job
    await jobDoc.ref.update({
      status: approvalNeeded ? "awaiting_approval" : "completed",
      outputs: cf.outputs,
      provenance,
      requiresApproval: approvalNeeded,
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await emitEvent({
      type: "bot_action",
      bot: "HypeBot_v2",
      action: "processed_job",
      jobId,
      assetId: job.assetId,
      confidence: cf.confidence,
    });

    // 4. If approval needed, enqueue and stop
    if (approvalNeeded) {
      await enqueueApproval(jobId, {
        requester: "HypeBot_v2",
        type: microInfluencers.length > 0 ? "dm_publish" : "publish",
        assetId: job.assetId,
        assetTitle: job.title || job.eventName || "Untitled",
        estimatedSpendUsd,
        influencerCount: microInfluencers.length,
        requiresLegal,
        provenance,
        outputs: cf.outputs,
        rationale: `Approval required: spend=$${estimatedSpendUsd}, legal=${requiresLegal}, influencers=${microInfluencers.length}, confidence=${cf.confidence}`,
      });
      return { jobId, status: "awaiting_approval" };
    }

    // 5. Publish to platforms
    const publishPlatforms = job.publishPlatforms || ["tiktok"];
    for (const platform of publishPlatforms) {
      if (platform === "tiktok") {
        const clip =
          cf.outputs.find((o) => o.type === "clip") || cf.outputs[0] || {};
        const caption = cf.outputs.find((o) => o.type === "caption");
        try {
          const pub = await publishToTikTok(
            clip,
            caption ? caption.content : "",
            { jobId, provenance },
          );
          await emitEvent({
            type: "publish",
            platform: "tiktok",
            jobId,
            publishId: pub.id,
          });
        } catch (err) {
          console.error("TikTok publish failed", err.message);
          if (err.message.includes("RATE_LIMITED")) {
            await jobDoc.ref.update({
              status: "rate_limited",
              retryAfter: new Date(Date.now() + 60000).toISOString(),
            });
          } else {
            const retryCount = (job.retryCount || 0) + 1;
            if (retryCount >= MAX_RETRIES) {
              await sendToDLQ(jobId, "tiktok_publish_failed", err.message);
            } else {
              await jobDoc.ref.update({ status: "retry", retryCount });
            }
          }
        }
      }
      // Other platforms can be added here following the same pattern
    }

    // 6. DM seeding to micro-influencers (consent-gated)
    if (microInfluencers.length > 0) {
      const dmTemplate =
        job.dmTemplate ||
        "Hey {handle}, early access to {event}. DM us to claim a pass.";
      for (const influencer of microInfluencers) {
        if (!influencer.consent) {
          console.log(
            "Skipping influencer without consent:",
            influencer.handle,
          );
          await emitEvent({
            type: "dm_skipped",
            jobId,
            handle: influencer.handle,
            reason: "no_consent",
          });
          continue;
        }
        const message = dmTemplate
          .replace("{handle}", influencer.handle)
          .replace("{event}", job.eventName || "Fight Night");
        try {
          const dmRes = await sendDMToInfluencer(influencer.handle, message, {
            jobId,
            platform: influencer.platform || "tiktok",
            provenance,
          });
          await emitEvent({
            type: "dm_sent",
            jobId,
            handle: influencer.handle,
            dmId: dmRes.id,
            status: dmRes.status,
          });
        } catch (err) {
          console.error("DM send failed for", influencer.handle, err.message);
          await emitEvent({
            type: "dm_failed",
            jobId,
            handle: influencer.handle,
            error: err.message,
          });
        }
      }
    }

    return { jobId, status: "completed" };
  } catch (err) {
    console.error("HypeBot processJob error", jobId, err.message);
    const retryCount = (job.retryCount || 0) + 1;
    if (retryCount >= MAX_RETRIES) {
      await jobDoc.ref.update({ status: "failed" });
      await sendToDLQ(jobId, "process_error", err.message);
    } else {
      await jobDoc.ref.update({
        status: "retry",
        retryCount,
        lastError: err.message,
      });
    }
    return { jobId, status: "error", error: err.message };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCHEDULED WORKER — Polls for HypeBot jobs every 2 minutes
// ═══════════════════════════════════════════════════════════════════════════
const hypebotWorkerPoll = onScheduleV2(
  { schedule: "every 2 minutes", region: REGION, timeoutSeconds: 120 },
  async () => {
    // Fetch pending jobs assigned to HypeBot
    const pendingJobs = await db
      .collection(JOBS_COLLECTION)
      .where("assignedBot", "==", "hype_bot_v2")
      .where("status", "in", ["pending", "retry"])
      .orderBy("createdAt")
      .limit(5)
      .get();

    if (pendingJobs.empty) return;

    console.log(`HypeBot_v2: processing ${pendingJobs.size} jobs`);
    for (const doc of pendingJobs.docs) {
      await processJob(doc);
    }
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// CALLABLE — Manual trigger for a single job (War Room use)
// ═══════════════════════════════════════════════════════════════════════════
const hypebotProcessJob = onCall({ region: REGION }, async (request) => {
  const { jobId } = request.data;
  if (!jobId) return { status: "error", message: "jobId required" };

  const jobDoc = await db.collection(JOBS_COLLECTION).doc(jobId).get();
  if (!jobDoc.exists) return { status: "error", message: "Job not found" };

  return processJob(jobDoc);
});

// ═══════════════════════════════════════════════════════════════════════════
// BOT REGISTRATION — Keeps bot record alive in ai_bots collection
// ═══════════════════════════════════════════════════════════════════════════
const hypebotRegister = onScheduleV2(
  { schedule: "every 24 hours", region: REGION },
  async () => {
    await db
      .collection(BOTS_COLLECTION)
      .doc("hype_bot_v2")
      .set(
        {
          id: "hype_bot_v2",
          name: "HypeBot v2",
          type: "publish_worker",
          capabilities: [
            "content_generation",
            "tiktok_publish",
            "dm_seeding",
            "approval_gating",
          ],
          rateLimits: {
            tiktokPerMin: TIKTOK_RATE_PER_MIN,
            dmPerHour: DM_RATE_PER_HOUR,
          },
          thresholds: {
            spendApproval: SPEND_APPROVAL_THRESHOLD,
            dmApproval: DM_APPROVAL_THRESHOLD,
          },
          active: true,
          version: "2.0",
          lastSeen: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
  },
);

module.exports = {
  hypebotWorkerPoll,
  hypebotProcessJob,
  hypebotRegister,
};
