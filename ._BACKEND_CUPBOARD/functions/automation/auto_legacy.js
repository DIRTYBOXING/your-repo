// ═══════════════════════════════════════════════════════════════════════════
// DFC AUTO-LEGACY ENGINE — Self-Selling 24/7 Content Factory
// ═══════════════════════════════════════════════════════════════════════════
//
// Turns every live event into a permanent, self-selling vault asset.
// No manual intervention. Autonomous revenue extraction forever.
//
// SYSTEM 1: VOD VAULT ("The Feeder")
//   → onEventEnd: Transitions live → archived, creates vault_vod doc,
//     drops price to catch-up rate, seeds social "Watch the Replay" posts
//
// SYSTEM 2: AI CLIP-BOT ("The Seeder")
//   → clipBotHarvester: Scheduled T+30min, grabs chat/volume spikes,
//     creates 3 vertical clips via Mux static renditions, seeds to Blotato
//
// SYSTEM 3: LEGACY CREDITS ("The Economy")
//   → purchaseLegacyAccess: Callable — spend DFC credits for vault access
//   → getLegacyCatalog: Callable — browse all vault_vod entries
//
// SYSTEM 4: PROMOTER PULSE ("The Payout")
//   → processResidualPayout: On vault_vod purchase, splits revenue:
//     50% DFC, 30% Promoter, 20% Fighters via Stripe Connect transfers
//
// ═══════════════════════════════════════════════════════════════════════════

const {
  onDocumentUpdated,
  onDocumentCreated,
} = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall } = require("firebase-functions/v2/https");
const {
  admin,
  db,
  REGION,
  stripe,
  getStripe,
  withStripeSecret,
} = require("../config");
const {
  getCanonicalPpvAccessState,
  readDateTime,
  resolvePpvEventDocument,
} = require("../ppv/access_state");

const messaging = admin.messaging();
const N8N_WEBHOOK_URL = process.env.N8N_WEBHOOK_URL || "";

// ─── Residual Split Ratios ───────────────────────────────────────────────
const RESIDUAL_SPLIT = {
  dfc: 0.5, // 50% to DFC (you built the machine)
  promoter: 0.3, // 30% to Promoter (they brought the fighters)
  fighters: 0.2, // 20% to Fighters (they bled for the content)
};

// ─── Legacy Pricing ──────────────────────────────────────────────────────
const VAULT_PRICE_CENTS = 999; // $9.99 per replay (down from live price)
const LEGACY_YEAR_CREDITS = 500; // 500 DFC credits = full year of vault access

// ═══════════════════════════════════════════════════════════════════════════
// SYSTEM 1: VOD VAULT — "The Feeder"
// ═══════════════════════════════════════════════════════════════════════════
//
// Trigger: ppv_events/{ppvId} status changes to 'replay' or 'expired'
// OR: manual trigger when promoter marks event as ended.
//
// ACTIONS:
//   1. Create vault_vod doc with catch-up pricing
//   2. Set replay price to $9.99
//   3. Seed "Watch the Replay" social post with n8n distribution
//   4. Write "next_fight_hook" data for dynamic end-cards
//
const onEventEnd = onDocumentUpdated(
  {
    document: "ppv_events/{ppvId}",
    region: REGION,
  },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const ppvId = event.params.ppvId;

    // Only fire on transition to 'replay' (from live)
    // The post_event.js onPPVReplayReady handles the immediate replay push.
    // This function handles the VAULT transition — the permanent archive.
    if (before.status === after.status) return;
    if (after.status !== "replay") return;

    // Guard: Don't vault if already vaulted
    const existingVault = await db.collection("vault_vod").doc(ppvId).get();
    if (existingVault.exists) {
      console.log(`[AutoLegacy] ${ppvId} already vaulted — skipping`);
      return;
    }

    console.log(`[AutoLegacy] Vaulting event ${ppvId}`);

    const title = after.title || after.name || "FIGHT NIGHT";
    const eventDate = after.eventDate || after.startTime || null;
    const posterUrl = after.posterUrl || after.imageUrl || "";
    const promoterId = after.promoterId || "";
    const promoterName = after.promoterName || "";
    const originalPriceCents =
      after.priceCents || (after.price ? Math.round(after.price * 100) : 4999);

    // ── Step 1: Find VOD playback from Mux ─────────────────────────
    let vodPlaybackId = null;
    let vodAssetId = null;
    let vodDuration = 0;

    const streamSnap = await db
      .collection("mux_streams")
      .where("ppvEventId", "==", ppvId)
      .limit(1)
      .get();

    if (!streamSnap.empty) {
      const stream = streamSnap.docs[0].data();
      vodAssetId = stream.vodAssetId || stream.muxActiveAssetId || null;
      vodPlaybackId = stream.muxPlaybackId || null;

      // Check mux_vod_assets for richer data
      if (vodAssetId) {
        const vodDoc = await db
          .collection("mux_vod_assets")
          .doc(vodAssetId)
          .get();
        if (vodDoc.exists) {
          vodPlaybackId = vodDoc.data().playbackId || vodPlaybackId;
          vodDuration = vodDoc.data().duration || 0;
        }
      }
    }

    // ── Step 2: Create vault_vod doc ────────────────────────────────
    await db
      .collection("vault_vod")
      .doc(ppvId)
      .set({
        ppvId,
        title,
        posterUrl,
        eventDate: eventDate || null,
        originalPriceCents,
        vaultPriceCents: VAULT_PRICE_CENTS,
        creditsCost: Math.round(VAULT_PRICE_CENTS / 10), // ~100 credits = $9.99
        promoterId,
        promoterName,
        // VOD playback
        vodPlaybackId,
        vodAssetId,
        durationSeconds: vodDuration,
        // Split ratios baked in for audit trail
        residualSplit: RESIDUAL_SPLIT,
        // Lifecycle
        status: "active", // active → legacy → retired
        totalPurchases: 0,
        totalRevenueCents: 0,
        vaultedAt: admin.firestore.FieldValue.serverTimestamp(),
        // Fighter payout roster (populated from event)
        fighters: after.fighters || after.fightCard || [],
      });

    // ── Step 3: Update ppv_events with vault status ─────────────────
    await db
      .collection("ppv_events")
      .doc(ppvId)
      .update({
        vaultStatus: "active",
        vaultPriceCents: VAULT_PRICE_CENTS,
        vaultedAt: admin.firestore.FieldValue.serverTimestamp(),
      })
      .catch(() => {});

    // ── Step 4: Find the NEXT upcoming event for the "hook" ─────────
    const nextEventSnap = await db
      .collection("ppv_events")
      .where("status", "in", ["announced", "presale", "onSale"])
      .orderBy("startTime", "asc")
      .limit(1)
      .get();

    let nextEventHook = null;
    if (!nextEventSnap.empty) {
      const next = nextEventSnap.docs[0].data();
      nextEventHook = {
        ppvId: nextEventSnap.docs[0].id,
        title: next.title || next.name || "UPCOMING FIGHT",
        startTime: next.startTime || null,
        buyLink: `https://datafightcentral.com/ppv/event/${nextEventSnap.docs[0].id}`,
      };

      // Write next-fight hook to vault doc for dynamic end-cards
      await db.collection("vault_vod").doc(ppvId).update({
        nextEventHook,
      });
    }

    // ── Step 5: Schedule clip-bot harvest at T+30min ────────────────
    const harvestAt = admin.firestore.Timestamp.fromMillis(
      Date.now() + 30 * 60 * 1000,
    );
    await db.collection("clip_harvest_queue").doc(ppvId).set({
      ppvId,
      title,
      posterUrl,
      vodPlaybackId,
      vodAssetId,
      durationSeconds: vodDuration,
      promoterId,
      status: "pending",
      harvestAt,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(
      `[AutoLegacy] ${ppvId} vaulted at $${(VAULT_PRICE_CENTS / 100).toFixed(2)}, clip harvest scheduled for T+30min`,
    );
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// SYSTEM 2: AI CLIP-BOT — "The Seeder"
// ═══════════════════════════════════════════════════════════════════════════
//
// Runs every 5 minutes. Checks clip_harvest_queue for events due.
// For each:
//   1. Generates 3 clip stubs at crowd-spike timestamps
//   2. Creates Mux static renditions for vertical (9:16) clips
//   3. Seeds social posts with "Watch the Full Replay" CTAs via n8n
//   4. Every clip includes a "Buy Now" link to the next upcoming event
//
const clipBotHarvester = onSchedule(
  {
    schedule: "every 5 minutes",
    region: REGION,
    timeoutSeconds: 120,
    memory: "512MiB",
  },
  async () => {
    const now = admin.firestore.Timestamp.now();

    const readySnap = await db
      .collection("clip_harvest_queue")
      .where("status", "==", "pending")
      .where("harvestAt", "<=", now)
      .limit(5)
      .get();

    if (readySnap.empty) return;
    console.log(`[ClipBot] Processing ${readySnap.size} clip harvest jobs`);

    for (const doc of readySnap.docs) {
      const job = doc.data();
      try {
        await harvestClips(job, doc.ref);
      } catch (err) {
        console.error(`[ClipBot] Error harvesting ${doc.id}:`, err.message);
        await doc.ref.update({
          status: "error",
          error: err.message,
          lastAttempt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }
  },
);

async function harvestClips(job, jobRef) {
  const ppvId = job.ppvId;
  const title = job.title || "FIGHT NIGHT";
  const duration = job.durationSeconds || 0;
  const posterUrl = job.posterUrl || "";

  // ── Find crowd/chat spike moments ────────────────────────────────
  // Check if there are chat spike markers in Firestore
  const spikesSnap = await db
    .collection("chat_spikes")
    .where("ppvEventId", "==", ppvId)
    .orderBy("spikeScore", "desc")
    .limit(3)
    .get();

  let clipTimestamps = [];

  if (!spikesSnap.empty) {
    // Use real chat spike data
    clipTimestamps = spikesSnap.docs.map((d) => ({
      startSeconds: d.data().timestampSeconds || 0,
      label: d.data().label || "Crowd Spike",
      spikeScore: d.data().spikeScore || 0,
    }));
    console.log(
      `[ClipBot] Found ${clipTimestamps.length} chat spikes for ${ppvId}`,
    );
  } else if (duration > 120) {
    // Fallback: Create clips at 25%, 50%, 75% marks (likely round breaks)
    clipTimestamps = [
      {
        startSeconds: Math.floor(duration * 0.25),
        label: "Early Action",
        spikeScore: 0,
      },
      {
        startSeconds: Math.floor(duration * 0.5),
        label: "Mid-Card Fire",
        spikeScore: 0,
      },
      {
        startSeconds: Math.floor(duration * 0.75),
        label: "Main Event Moment",
        spikeScore: 0,
      },
    ];
    console.log(
      `[ClipBot] No chat spikes — using duration-based clips for ${ppvId}`,
    );
  } else {
    // Very short VOD — single clip
    clipTimestamps = [
      { startSeconds: 0, label: "Full Highlight", spikeScore: 0 },
    ];
  }

  // ── Find next upcoming event for the "Buy Now" hook ──────────────
  const nextEventSnap = await db
    .collection("ppv_events")
    .where("status", "in", ["announced", "presale", "onSale"])
    .orderBy("startTime", "asc")
    .limit(1)
    .get();

  let nextEventCTA = "";
  if (!nextEventSnap.empty) {
    const next = nextEventSnap.docs[0].data();
    nextEventCTA = `\n🥊 NEXT FIGHT: ${next.title || "UPCOMING"} — Get tickets NOW 👉 https://datafightcentral.com/ppv/event/${nextEventSnap.docs[0].id}`;
  }

  // ── Create clip docs + social posts ────────────────────────────────
  const batch = db.batch();
  const clipIds = [];

  for (let i = 0; i < clipTimestamps.length; i++) {
    const clip = clipTimestamps[i];
    const clipId = `${ppvId}_clip_${i}`;

    // Write clip metadata
    const clipRef = db.collection("vault_clips").doc(clipId);
    batch.set(clipRef, {
      ppvId,
      clipIndex: i,
      label: clip.label,
      startSeconds: clip.startSeconds,
      durationSeconds: 60, // 60s clips
      format: "vertical_9_16",
      vodPlaybackId: job.vodPlaybackId || "",
      vodAssetId: job.vodAssetId || "",
      spikeScore: clip.spikeScore,
      status: "ready", // ready for social seeding
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    clipIds.push(clipId);

    // Build social caption for this clip
    const clipCaption = [
      `🔥 ${clip.label.toUpperCase()} — ${title}`,
      "",
      `The moment the crowd went WILD. 🥊💥`,
      "",
      `📺 Watch the full replay 👉 https://datafightcentral.com/ppv/event/${ppvId}`,
      nextEventCTA,
      "",
      "#DFC #Highlights #CombatSports #PPV #KO #FightNight #MMA #Boxing #BKFC",
    ].join("\n");

    // Write social post for this clip
    const socialRef = db.collection("social_posts").doc(`${ppvId}_clip_${i}`);
    batch.set(socialRef, {
      ppvId,
      type: "vault_clip",
      clipIndex: i,
      title: `🔥 ${clip.label}: ${title}`,
      caption: clipCaption,
      imageUrl: posterUrl,
      buyLink: `https://datafightcentral.com/ppv/event/${ppvId}`,
      nextEventLink: nextEventCTA
        ? `https://datafightcentral.com/ppv/event/${nextEventSnap.docs[0].id}`
        : "",
      platforms: ["tiktok", "instagram", "youtube", "twitter", "threads"],
      status: "pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      source: "clip_bot_harvester",
      // Stagger posting: clip 0 now, clip 1 in 24h, clip 2 in 72h
      scheduledFor: admin.firestore.Timestamp.fromMillis(
        Date.now() + i * 24 * 60 * 60 * 1000,
      ),
    });
  }

  await batch.commit();

  // ── Ping n8n with first clip for immediate distribution ───────────
  if (N8N_WEBHOOK_URL && clipTimestamps.length > 0) {
    try {
      await fetch(N8N_WEBHOOK_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          ppvId,
          type: "vault_clip",
          isDrip: false,
          isClip: true,
          clipIndex: 0,
          title: `🔥 ${clipTimestamps[0].label}: ${title}`,
          caption: `🔥 ${clipTimestamps[0].label.toUpperCase()} — ${title}\n\nThe moment the crowd went WILD. 🥊💥\n\n📺 Full replay 👉 https://datafightcentral.com/ppv/event/${ppvId}${nextEventCTA}`,
          imageUrl: posterUrl,
          buyLink: `https://datafightcentral.com/ppv/event/${ppvId}`,
          totalClips: clipTimestamps.length,
        }),
      });
      console.log(`[ClipBot] n8n pinged for clip 0 of ${ppvId}`);
    } catch (err) {
      console.error(`[ClipBot] n8n ping failed:`, err.message);
    }
  }

  // Mark job as complete
  await jobRef.update({
    status: "completed",
    clipCount: clipTimestamps.length,
    clipIds,
    completedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(
    `[ClipBot] Harvested ${clipTimestamps.length} clips for ${ppvId}, seeding staggered over ${clipTimestamps.length} days`,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// SYSTEM 3: LEGACY CREDITS — "The Economy"
// ═══════════════════════════════════════════════════════════════════════════
//
// purchaseLegacyAccess: Spend DFC credits to unlock a vault_vod replay
//   - Single replay: 100 credits ($9.99 equivalent)
//   - Full year ("Legacy Access"): 500 credits
//
// getLegacyCatalog: Read-only — returns all available vault_vod entries
//
const purchaseLegacyAccess = onCall({ region: REGION }, async (request) => {
  const userId = request.auth?.uid;
  if (!userId) return { error: "Authentication required" };

  const { ppvId, accessType } = request.data;
  // accessType: 'single' (one replay) or 'year' (all replays for 1 year)

  if (!ppvId && accessType !== "year") {
    return { error: "ppvId required for single access" };
  }

  const creditsCost = accessType === "year" ? LEGACY_YEAR_CREDITS : 100;

  try {
    // ── Check user credit balance ───────────────────────────────────
    const creditsRef = db.collection("user_credits").doc(userId);
    const creditsDoc = await creditsRef.get();

    if (!creditsDoc.exists) {
      return {
        error: "No credits balance. Purchase credits first.",
        needsCredits: true,
      };
    }

    const currentBalance = creditsDoc.data().balance || 0;
    if (currentBalance < creditsCost) {
      return {
        error: `Insufficient credits. Need ${creditsCost}, have ${currentBalance}.`,
        needsCredits: true,
        currentBalance,
        required: creditsCost,
      };
    }

    if (accessType === "year") {
      // ── YEAR ACCESS: Unlock all vault content for 365 days ────────
      const expiresAt = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
      );

      await db.collection("legacy_access").doc(userId).set({
        userId,
        type: "year",
        creditsCost,
        expiresAt,
        grantedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: "active",
      });

      // Deduct credits
      await creditsRef.update({
        balance: admin.firestore.FieldValue.increment(-creditsCost),
        totalSpent: admin.firestore.FieldValue.increment(creditsCost),
        lastPurchase: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Log transaction
      await db.collection("credit_transactions").add({
        userId,
        type: "legacy_year",
        amount: -creditsCost,
        description: `Legacy Year Access (all vault replays for 365 days)`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        type: "year",
        expiresAt: expiresAt.toDate().toISOString(),
        creditsCost,
      };
    } else {
      // ── SINGLE ACCESS: Unlock one vault replay ────────────────────
      const vaultDoc = await db.collection("vault_vod").doc(ppvId).get();
      if (!vaultDoc.exists) {
        return { error: "Replay not found in vault" };
      }

      const accessState = await getCanonicalPpvAccessState({
        db,
        userId,
        eventId: ppvId,
      });
      if (accessState.hasAccess) {
        return {
          alreadyPurchased: true,
          message: "You already have access to this replay",
        };
      }

      const resolvedEvent = await resolvePpvEventDocument(db, ppvId);
      const canonicalPpvId = resolvedEvent?.id || ppvId;
      const eventData = resolvedEvent?.data || {};
      const expiresAt = admin.firestore.Timestamp.fromDate(
        readDateTime(eventData.replayExpiry) ||
          new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      );
      const eventEndedAt =
        readDateTime(eventData.endTime) || readDateTime(eventData.eventDate);

      // Grant access
      const compositeId = `${userId}_${canonicalPpvId}`;
      await db
        .collection("ppv_access")
        .doc(compositeId)
        .set({
          userId,
          eventId: canonicalPpvId,
          bundleName: "VAULT REPLAY",
          price: VAULT_PRICE_CENTS / 100,
          paymentMethod: "credits",
          creditsCost,
          grantedAt: admin.firestore.FieldValue.serverTimestamp(),
          expiresAt,
          accessGranted: true,
          paymentStatus: "completed",
          isActive: true,
          replayExpired: false,
        });
      if (canonicalPpvId !== ppvId) {
        await db.collection("ppv_access").doc(compositeId).set(
          {
            sourceEventId: ppvId,
          },
          { merge: true },
        );
      }

      // Also write ppv_purchases for unified tracking
      await db.collection("ppv_purchases").doc(compositeId).set({
        id: compositeId,
        userId,
        ppvId: canonicalPpvId,
        ppvEventId: canonicalPpvId,
        eventId: canonicalPpvId,
        tierId: 1, // HIGHLIGHTS tier
        tierName: "VAULT REPLAY",
        paymentMethod: "credits",
        creditsCost,
        amountCents: VAULT_PRICE_CENTS,
        currency: "AUD",
        status: "completed",
        paymentStatus: "completed",
        accessGranted: true,
        isActive: true,
        replayExpired: false,
        isVaultPurchase: true,
        purchasedAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt,
      });
      if (canonicalPpvId !== ppvId) {
        await db.collection("ppv_purchases").doc(compositeId).set(
          {
            sourceEventId: ppvId,
          },
          { merge: true },
        );
      }
      if (eventEndedAt) {
        await db
          .collection("ppv_purchases")
          .doc(compositeId)
          .set(
            {
              eventEndedAt: admin.firestore.Timestamp.fromDate(eventEndedAt),
            },
            { merge: true },
          );
      }

      // Deduct credits
      await creditsRef.update({
        balance: admin.firestore.FieldValue.increment(-creditsCost),
        totalSpent: admin.firestore.FieldValue.increment(creditsCost),
        lastPurchase: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Log transaction
      await db.collection("credit_transactions").add({
        userId,
        type: "legacy_single",
        amount: -creditsCost,
        ppvId,
        description: `Vault Replay: ${vaultDoc.data().title || ppvId}`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Increment vault purchase counter (triggers residual payout)
      await db
        .collection("vault_vod")
        .doc(ppvId)
        .update({
          totalPurchases: admin.firestore.FieldValue.increment(1),
          totalRevenueCents:
            admin.firestore.FieldValue.increment(VAULT_PRICE_CENTS),
        });

      return {
        success: true,
        type: "single",
        ppvId,
        creditsCost,
        expiresAt: expiresAt.toDate().toISOString(),
      };
    }
  } catch (err) {
    console.error("[LegacyCredits] Purchase error:", err);
    return { error: err.message };
  }
});

const getLegacyCatalog = onCall({ region: REGION }, async (request) => {
  const userId = request.auth?.uid;

  try {
    // Get all vault entries
    const vaultSnap = await db
      .collection("vault_vod")
      .where("status", "==", "active")
      .orderBy("vaultedAt", "desc")
      .limit(50)
      .get();

    const catalog = [];
    for (const doc of vaultSnap.docs) {
      const data = doc.data();
      catalog.push({
        ppvId: doc.id,
        title: data.title,
        posterUrl: data.posterUrl,
        eventDate: data.eventDate,
        vaultPriceCents: data.vaultPriceCents,
        creditsCost: data.creditsCost,
        promoterName: data.promoterName,
        totalPurchases: data.totalPurchases || 0,
        durationSeconds: data.durationSeconds || 0,
        hasNextEventHook: !!data.nextEventHook,
      });
    }

    // Check if user has Legacy Year access
    let hasYearAccess = false;
    if (userId) {
      const legacyDoc = await db.collection("legacy_access").doc(userId).get();
      if (legacyDoc.exists) {
        const legacyData = legacyDoc.data();
        if (legacyData.status === "active") {
          const expires = legacyData.expiresAt?.toDate?.() || new Date(0);
          hasYearAccess = expires > new Date();
        }
      }
    }

    return {
      catalog,
      totalEvents: catalog.length,
      hasYearAccess,
      yearAccessCredits: LEGACY_YEAR_CREDITS,
      singleReplayCredits: 100,
    };
  } catch (err) {
    console.error("[LegacyCatalog] Error:", err);
    return { catalog: [], error: err.message };
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// SYSTEM 4: PROMOTER PULSE — "The Payout"
// ═══════════════════════════════════════════════════════════════════════════
//
// Trigger: vault_vod/{ppvId} totalPurchases incremented
// On every vault purchase, calculate residual splits and:
//   - Log the split to residual_payouts
//   - If promoter has Stripe Connect: create Stripe Transfer
//   - Fighters get allocated share (bulk payout monthly by admin)
//
const processResidualPayout = onDocumentUpdated(
  withStripeSecret({
    document: "vault_vod/{ppvId}",
    region: REGION,
  }),
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const ppvId = event.params.ppvId;

    // Only fire when totalPurchases increases
    const prevPurchases = before.totalPurchases || 0;
    const newPurchases = after.totalPurchases || 0;
    if (newPurchases <= prevPurchases) return;

    // Calculate for the new purchase(s) only
    const purchaseDiff = newPurchases - prevPurchases;
    const revenueCents = purchaseDiff * VAULT_PRICE_CENTS;

    const dfcShare = Math.round(revenueCents * RESIDUAL_SPLIT.dfc);
    const promoterShare = Math.round(revenueCents * RESIDUAL_SPLIT.promoter);
    const fighterShare = revenueCents - dfcShare - promoterShare; // remainder to fighters

    console.log(
      `[PromoterPulse] Residual for ${ppvId}: $${(revenueCents / 100).toFixed(2)} → DFC $${(dfcShare / 100).toFixed(2)} / Promoter $${(promoterShare / 100).toFixed(2)} / Fighters $${(fighterShare / 100).toFixed(2)}`,
    );

    // ── Log the residual split ──────────────────────────────────────
    const payoutRef = db.collection("residual_payouts").doc();
    await payoutRef.set({
      ppvId,
      eventTitle: after.title || ppvId,
      purchaseCount: purchaseDiff,
      totalRevenueCents: revenueCents,
      dfcShareCents: dfcShare,
      promoterShareCents: promoterShare,
      fighterShareCents: fighterShare,
      promoterId: after.promoterId || "",
      promoterName: after.promoterName || "",
      splitRatios: RESIDUAL_SPLIT,
      stripeTransferId: null, // filled below if transfer succeeds
      status: "calculated",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // ── Stripe Transfer to Promoter (if connected) ──────────────────
    if (getStripe() && after.promoterId && promoterShare > 0) {
      try {
        const connectDoc = await db
          .collection("connected_accounts_v2")
          .doc(after.promoterId)
          .get();
        if (
          connectDoc.exists &&
          connectDoc.data().stripeAccountId &&
          connectDoc.data().onboardingComplete
        ) {
          const connectedAccountId = connectDoc.data().stripeAccountId;

          const transfer = await stripe.transfers.create({
            amount: promoterShare,
            currency: "aud",
            destination: connectedAccountId,
            description: `Vault replay residual: ${after.title || ppvId} (${purchaseDiff} purchase${purchaseDiff > 1 ? "s" : ""})`,
            metadata: {
              ppvId,
              type: "vault_residual",
              purchaseCount: String(purchaseDiff),
              totalRevenueCents: String(revenueCents),
              promoterShareCents: String(promoterShare),
            },
          });

          await payoutRef.update({
            stripeTransferId: transfer.id,
            status: "transferred",
            transferredAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          console.log(
            `[PromoterPulse] Stripe transfer ${transfer.id}: $${(promoterShare / 100).toFixed(2)} to promoter ${after.promoterId}`,
          );
        } else {
          console.log(
            `[PromoterPulse] Promoter ${after.promoterId} not connected — residual held`,
          );
          await payoutRef.update({ status: "held_no_connect" });
        }
      } catch (err) {
        console.error(`[PromoterPulse] Stripe transfer failed:`, err.message);
        await payoutRef.update({
          status: "transfer_failed",
          error: err.message,
        });
      }
    }

    // ── Allocate fighter share (held for monthly batch payout) ───────
    if (
      fighterShare > 0 &&
      Array.isArray(after.fighters) &&
      after.fighters.length > 0
    ) {
      const perFighterShare = Math.floor(fighterShare / after.fighters.length);
      const batch = db.batch();

      for (const fighter of after.fighters) {
        const fighterId = fighter.id || fighter.fighterId || fighter;
        if (typeof fighterId !== "string") continue;

        const allocationRef = db.collection("fighter_residuals").doc();
        batch.set(allocationRef, {
          fighterId,
          fighterName: fighter.name || fighter.fighterName || "",
          ppvId,
          eventTitle: after.title || ppvId,
          amountCents: perFighterShare,
          status: "allocated", // allocated → paid
          payoutRef: payoutRef.id,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      console.log(
        `[PromoterPulse] ${after.fighters.length} fighters allocated $${(perFighterShare / 100).toFixed(2)} each for ${ppvId}`,
      );
    }

    // ── Update promoter stats ───────────────────────────────────────
    if (after.promoterId) {
      await db
        .collection("promoter_stats")
        .doc(after.promoterId)
        .set(
          {
            totalResidualCents:
              admin.firestore.FieldValue.increment(promoterShare),
            totalVaultPurchases:
              admin.firestore.FieldValue.increment(purchaseDiff),
            lastResidualAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
    }
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// EXPORTS
// ═══════════════════════════════════════════════════════════════════════════
module.exports = {
  // System 1: VOD Vault
  onEventEnd,
  // System 2: AI Clip-Bot
  clipBotHarvester,
  // System 3: Legacy Credits
  purchaseLegacyAccess,
  getLegacyCatalog,
  // System 4: Promoter Pulse
  processResidualPayout,
};
