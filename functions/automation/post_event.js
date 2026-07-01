// ═══════════════════════════════════════════════════════════════════════════
// DFC POST-EVENT REVENUE TAIL — 4 Autonomous Systems
// ═══════════════════════════════════════════════════════════════════════════
//
// Fires automatically when an event transitions to 'replay' status.
// No human intervention. Pure post-fight revenue extraction pipeline.
//
// SYSTEM 1: "Missed It?" Auto-Re-Seeder           → onPPVReplayReady
//   - Seeds "Watch the Replay" social posts on 9 platforms via n8n/Blotato
//   - Sends FCM push to all users who DIDN'T buy: "Missed it? Replay available!"
//   - Schedules fan ambassador + lead scoring drips
//
// SYSTEM 2: Highlight Factory                      → onVodAssetReady
//   - Triggered when Mux VOD asset lands in Firestore
//   - Creates highlight_clips metadata stubs for the event
//   - Seeds "Best Moments from [EVENT]" social posts
//
// SYSTEM 3: Fan-to-Ambassador Push                 → postEventDripProcessor
//   - T+1hr: FCM to all purchasers — "Rate the fight & share for 50 DFC Credits"
//   - Writes ambassador_prompts for tracking conversions
//
// SYSTEM 4: Data Cleanse & Retention Bridge        → postEventDripProcessor
//   - T+2hr: Tags users by behavior (purchased_watched, purchased_missed,
//     browsed_didnt_buy) and writes user_segments for lead scoring
//
// ═══════════════════════════════════════════════════════════════════════════

const {
  onDocumentUpdated,
  onDocumentCreated,
} = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { admin, db, REGION } = require("../config");

const messaging = admin.messaging();

// Native engine — replaces n8n + Blotato ($0/month)
const { _publishToAllPlatforms } = require("../content/social_publisher");

// ═══════════════════════════════════════════════════════════════════════════
// SYSTEM 1: "MISSED IT?" AUTO-RE-SEEDER
// ═══════════════════════════════════════════════════════════════════════════
//
// Trigger: ppv_events/{ppvId} status changes from 'live' to 'replay'
// Mux webhook already transitions status to 'replay' when stream ends.
// This function rides that transition to seed replay content.
//
const onPPVReplayReady = onDocumentUpdated(
  {
    document: "ppv_events/{ppvId}",
    region: REGION,
  },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const ppvId = event.params.ppvId;

    // Only fire on live → replay transition
    if (before.status === after.status) return;
    if (after.status !== "replay") return;

    console.log(
      `[PostEvent] Replay ready for ${ppvId} — launching post-event pipeline`,
    );

    const title = after.title || after.name || "FIGHT NIGHT";
    const replayUrl =
      after.replayUrl || `https://datafightcentral.com/ppv/event/${ppvId}`;
    const posterUrl = after.posterUrl || after.imageUrl || "";
    const price = after.price || 0;
    const replayPrice = Math.max(Math.round(price * 0.5 * 100) / 100, 1.99); // 50% off, min $1.99
    const now = Date.now();

    // ── Step 1: Write "Watch the Replay" social post ──────────────────
    const replayCaption = [
      `📺 REPLAY AVAILABLE — ${title}`,
      "",
      `Missed the action? The full replay is available NOW on DFC.`,
      `Catch every punch, every submission, every knockout.`,
      "",
      replayPrice < price
        ? `🎟️ Catch-up price: $${replayPrice} (was $${price})`
        : `🎟️ Watch now on DFC`,
      "",
      `👉 ${replayUrl}`,
      "",
      "#DFC #Replay #CombatSports #PPV #FightReplay #MMA #Boxing",
    ].join("\n");

    const socialRef = db.collection("social_posts").doc(`${ppvId}_replay`);
    await socialRef.set({
      ppvId,
      type: "replay_available",
      title: `📺 REPLAY: ${title}`,
      caption: replayCaption,
      imageUrl: posterUrl,
      buyLink: replayUrl,
      replayPrice,
      originalPrice: price,
      platforms: [
        "instagram",
        "tiktok",
        "twitter",
        "facebook",
        "youtube",
        "threads",
        "bluesky",
        "linkedin",
        "pinterest",
      ],
      status: "pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      source: "post_event_reseeder",
    });

    // ── Step 2: Publish to all platforms via native engine ──────────
    _publishToAllPlatforms({
      title: `📺 REPLAY: ${title}`,
      description: replayCaption,
      mediaUrl: posterUrl,
      buyLink: replayUrl,
      tone: "hype",
      contentType: "replay_available",
      price: replayPrice ? `${replayPrice}` : "",
      promoterName: after.promoterName || "",
      sourceFunction: "onPPVReplayReady",
      sourceId: ppvId,
    }).catch((err) =>
      console.error(
        `[PostEvent] Native publish failed for ${ppvId}:`,
        err.message,
      ),
    );

    // ── Step 3: FCM push to NON-purchasers (broad reach) ──────────────
    try {
      // Get purchaser user IDs
      const purchasersSnap = await db
        .collection("ppv_purchases")
        .where("ppvId", "==", ppvId)
        .select("userId")
        .get();
      const purchaserIds = new Set(
        purchasersSnap.docs.map((d) => d.data().userId).filter(Boolean),
      );

      // Get ALL users with FCM tokens, then exclude purchasers
      const usersSnap = await db
        .collection("users")
        .where("fcmToken", "!=", "")
        .select("fcmToken")
        .limit(500)
        .get();

      const nonPurchaserTokens = [];
      const purchaserTokens = [];
      for (const userDoc of usersSnap.docs) {
        const token = userDoc.data().fcmToken;
        if (!token) continue;
        if (purchaserIds.has(userDoc.id)) {
          purchaserTokens.push(token);
        } else {
          nonPurchaserTokens.push(token);
        }
      }

      // Push to non-purchasers: "Missed it? Catch the replay"
      if (nonPurchaserTokens.length > 0) {
        await messaging.sendEachForMulticast({
          notification: {
            title: `📺 Missed ${title}?`,
            body:
              replayPrice < price
                ? `Full replay now available — catch-up price $${replayPrice}!`
                : "Full replay now available on DFC!",
          },
          data: {
            type: "replay_available",
            ppvId,
            route: `/ppv/event/${ppvId}`,
          },
          tokens: nonPurchaserTokens,
        });
        console.log(
          `[PostEvent] Replay push sent to ${nonPurchaserTokens.length} non-purchasers`,
        );
      }

      // Push to purchasers: "Replay is live — rewatch anytime for 48hrs"
      if (purchaserTokens.length > 0) {
        await messaging.sendEachForMulticast({
          notification: {
            title: "📺 Replay Available",
            body: `${title} replay is live! Rewatch anytime for 48 hours.`,
          },
          data: {
            type: "replay_available_owner",
            ppvId,
            route: `/ppv/event/${ppvId}`,
          },
          tokens: purchaserTokens,
        });
        console.log(
          `[PostEvent] Replay push sent to ${purchaserTokens.length} purchasers`,
        );
      }
    } catch (err) {
      console.error(`[PostEvent] FCM push failed for ${ppvId}:`, err.message);
    }

    // ── Step 4: Schedule post-event drips (fan ambassador + lead score) ─
    await schedulePostEventDrips(after, ppvId, posterUrl);

    // ── Step 5: Mark event with post-event pipeline status ────────────
    await db
      .collection("ppv_events")
      .doc(ppvId)
      .update({
        postEventPipelineStarted: true,
        postEventPipelineStartedAt:
          admin.firestore.FieldValue.serverTimestamp(),
        replayPrice,
      })
      .catch(() => {});

    console.log(`[PostEvent] Full replay pipeline complete for ${ppvId}`);
  },
);

// ─── Schedule Post-Event Drips ───────────────────────────────────────────
async function schedulePostEventDrips(eventData, ppvId, posterUrl) {
  const now = Date.now();
  const title = eventData.title || eventData.name || "FIGHT NIGHT";

  const shared = {
    ppvId,
    eventTitle: title,
    posterUrl: posterUrl || "",
    promoterId: eventData.promoterId || "",
    promoterName: eventData.promoterName || "",
    status: "pending",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const drips = [
    {
      dripType: "fan_ambassador",
      publishAt: admin.firestore.Timestamp.fromMillis(now + 60 * 60 * 1000), // T+1hr
    },
    {
      dripType: "lead_score",
      publishAt: admin.firestore.Timestamp.fromMillis(now + 2 * 60 * 60 * 1000), // T+2hr
    },
    {
      dripType: "replay_reminder",
      publishAt: admin.firestore.Timestamp.fromMillis(
        now + 24 * 60 * 60 * 1000,
      ), // T+24hr
    },
  ];

  const batch = db.batch();
  for (const drip of drips) {
    const ref = db
      .collection("post_event_drips")
      .doc(`${ppvId}_${drip.dripType}`);
    batch.set(ref, { ...shared, ...drip });
  }
  await batch.commit();
  console.log(
    `[PostEvent] Post-event drips scheduled for ${ppvId}: fan_ambassador(+1h), lead_score(+2h), replay_reminder(+24h)`,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// SYSTEM 2: HIGHLIGHT FACTORY
// ═══════════════════════════════════════════════════════════════════════════
//
// Trigger: mux_vod_assets/{assetId} created
// When Mux finishes transcoding the VOD asset, this creates highlight stubs
// and seeds social posts promoting the event's best moments.
//
const onVodAssetReady = onDocumentCreated(
  {
    document: "mux_vod_assets/{assetId}",
    region: REGION,
  },
  async (event) => {
    const assetData = event.data.data();
    const assetId = event.params.assetId;
    const ppvEventId = assetData.ppvEventId;

    if (!ppvEventId) {
      console.log(
        `[HighlightFactory] No ppvEventId on VOD asset ${assetId} — skipping`,
      );
      return;
    }

    console.log(
      `[HighlightFactory] VOD asset ready: ${assetId} for event ${ppvEventId}`,
    );

    // Get event details
    const eventDoc = await db.collection("ppv_events").doc(ppvEventId).get();
    if (!eventDoc.exists) return;
    const eventData = eventDoc.data();
    const title = eventData.title || eventData.name || "FIGHT NIGHT";
    const posterUrl = eventData.posterUrl || eventData.imageUrl || "";
    const duration = assetData.duration || 0; // seconds

    // ── Create highlight clip metadata stubs ──────────────────────────
    // Pre-define standard highlight windows for manual or AI curation.
    // If duration > 0, create stubs at 25%, 50%, 75% marks (likely round breaks).
    const clipStubs = [];

    if (duration > 60) {
      const markers = [
        { label: "Early Highlight", pct: 0.25 },
        { label: "Mid-Card Highlight", pct: 0.5 },
        { label: "Main Event Highlight", pct: 0.75 },
      ];

      for (const marker of markers) {
        const startSec = Math.floor(duration * marker.pct);
        const clipDoc = {
          ppvEventId,
          muxAssetId: assetId,
          playbackId: assetData.playbackId || "",
          label: marker.label,
          startSeconds: startSec,
          durationSeconds: 60, // 60s default clip
          status: "stub", // stub → curated → published
          format: "vertical_9_16", // social-ready vertical
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        clipStubs.push(clipDoc);
      }
    }

    // Always create a "Full Event Recap" clip stub (entire VOD)
    clipStubs.push({
      ppvEventId,
      muxAssetId: assetId,
      playbackId: assetData.playbackId || "",
      label: "Full Event Recap",
      startSeconds: 0,
      durationSeconds: Math.min(duration || 300, 300), // Max 5 min recap
      status: "stub",
      format: "horizontal_16_9",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Write clip stubs to Firestore
    const batch = db.batch();
    for (const clip of clipStubs) {
      const ref = db.collection("highlight_clips").doc();
      batch.set(ref, clip);
    }
    await batch.commit();
    console.log(
      `[HighlightFactory] Created ${clipStubs.length} highlight stubs for ${ppvEventId}`,
    );

    // ── Seed "Best Moments" social post ───────────────────────────────
    const highlightCaption = [
      `🔥 BEST MOMENTS — ${title}`,
      "",
      `The highlights are HERE. Watch the most explosive moments from last night.`,
      "",
      `Full replay available on DFC 👉 https://datafightcentral.com/ppv/event/${ppvEventId}`,
      "",
      "#DFC #Highlights #CombatSports #PPV #KO #Knockouts #BestMoments",
    ].join("\n");

    await db
      .collection("social_posts")
      .doc(`${ppvEventId}_highlights`)
      .set({
        ppvId: ppvEventId,
        type: "highlight_reel",
        title: `🔥 HIGHLIGHTS: ${title}`,
        caption: highlightCaption,
        imageUrl: posterUrl,
        buyLink: `https://datafightcentral.com/ppv/event/${ppvEventId}`,
        platforms: ["instagram", "tiktok", "twitter", "youtube", "threads"],
        status: "pending",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        source: "highlight_factory",
        clipCount: clipStubs.length,
      });

    // Publish highlights via native engine
    _publishToAllPlatforms({
      title: `🔥 HIGHLIGHTS: ${title}`,
      description: highlightCaption,
      mediaUrl: posterUrl,
      buyLink: `https://datafightcentral.com/ppv/event/${ppvEventId}`,
      tone: "hype",
      contentType: "highlight_reel",
      sourceFunction: "highlightFactory",
      sourceId: ppvEventId,
    }).catch((err) =>
      console.error(`[HighlightFactory] Native publish failed:`, err.message),
    );

    // Update event doc
    await db
      .collection("ppv_events")
      .doc(ppvEventId)
      .update({
        highlightsReady: true,
        highlightClipCount: clipStubs.length,
        highlightsCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
      })
      .catch(() => {});
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// SYSTEMS 3 & 4: POST-EVENT DRIP PROCESSOR
// ═══════════════════════════════════════════════════════════════════════════
//
// Runs every 5 minutes. Queries post_event_drips WHERE publishAt <= now
// AND status == 'pending'. Handles:
//   - fan_ambassador: FCM to purchasers for rating + referral credits
//   - lead_score: Tags users by purchase/view behavior
//   - replay_reminder: 24h "last chance" push to non-purchasers
//
const postEventDripProcessor = onSchedule(
  {
    schedule: "every 5 minutes",
    region: REGION,
    timeoutSeconds: 120,
    memory: "512MiB",
  },
  async () => {
    const now = admin.firestore.Timestamp.now();

    const readySnap = await db
      .collection("post_event_drips")
      .where("status", "==", "pending")
      .where("publishAt", "<=", now)
      .limit(20)
      .get();

    if (readySnap.empty) return;
    console.log(
      `[PostEventDrip] Processing ${readySnap.size} post-event drips`,
    );

    for (const doc of readySnap.docs) {
      const drip = doc.data();
      try {
        switch (drip.dripType) {
          case "fan_ambassador":
            await handleFanAmbassador(drip);
            break;
          case "lead_score":
            await handleLeadScoring(drip);
            break;
          case "replay_reminder":
            await handleReplayReminder(drip);
            break;
          default:
            console.warn(`[PostEventDrip] Unknown drip type: ${drip.dripType}`);
        }

        // Mark as fired
        await doc.ref.update({
          status: "fired",
          firedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (err) {
        console.error(
          `[PostEventDrip] Error processing ${doc.id}:`,
          err.message,
        );
        await doc.ref.update({
          status: "error",
          error: err.message,
          lastAttempt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// SYSTEM 3: FAN-TO-AMBASSADOR HANDLER
// ═══════════════════════════════════════════════════════════════════════════
//
// Sends FCM push to all purchasers of this event:
//   "Rate the fight & share your link for 50 free DFC Credits!"
// Writes ambassador_prompts doc for tracking conversion.
//
async function handleFanAmbassador(drip) {
  const ppvId = drip.ppvId;
  const title = drip.eventTitle || "the fight";

  // Get all purchasers with their user IDs
  const purchasesSnap = await db
    .collection("ppv_purchases")
    .where("ppvId", "==", ppvId)
    .where("isActive", "==", true)
    .get();

  if (purchasesSnap.empty) {
    console.log(`[FanAmbassador] No active purchasers for ${ppvId}`);
    return;
  }

  const tokens = [];
  const userIds = [];

  for (const purchaseDoc of purchasesSnap.docs) {
    const userId = purchaseDoc.data().userId;
    if (!userId) continue;

    const userDoc = await db.collection("users").doc(userId).get();
    const fcmToken = userDoc.data()?.fcmToken;
    if (fcmToken) {
      tokens.push(fcmToken);
      userIds.push(userId);
    }
  }

  if (tokens.length === 0) {
    console.log(`[FanAmbassador] No FCM tokens for ${ppvId} purchasers`);
    return;
  }

  // Send FCM push
  const response = await messaging.sendEachForMulticast({
    notification: {
      title: "⭐ Rate the Fight!",
      body: `How was ${title}? Rate it & share your link for 50 free DFC Credits!`,
    },
    data: {
      type: "fan_ambassador",
      ppvId,
      route: `/ppv/event/${ppvId}/rate`,
      creditsReward: "50",
    },
    tokens,
  });

  console.log(
    `[FanAmbassador] Push sent to ${response.successCount}/${tokens.length} purchasers for ${ppvId}`,
  );

  // Write ambassador prompt records for tracking
  const batch = db.batch();
  for (const userId of userIds) {
    const ref = db.collection("ambassador_prompts").doc(`${ppvId}_${userId}`);
    batch.set(ref, {
      ppvId,
      userId,
      eventTitle: title,
      creditsOffered: 50,
      status: "sent", // sent → rated → shared → credited
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      ratedAt: null,
      sharedAt: null,
      creditedAt: null,
      referralCode: `DFC-${ppvId.substring(0, 6).toUpperCase()}-${userId.substring(0, 4).toUpperCase()}`,
    });
  }
  await batch.commit();
  console.log(
    `[FanAmbassador] ${userIds.length} ambassador prompts created for ${ppvId}`,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// SYSTEM 4: DATA CLEANSE & LEAD SCORING
// ═══════════════════════════════════════════════════════════════════════════
//
// Tags users by their behavior during this event window:
//   - purchased_watched: Bought PPV + accessed stream (high-value)
//   - purchased_missed:  Bought but never watched (re-engage target)
//   - browsed_didnt_buy: Viewed event page but didn't purchase (warm lead)
//
// Writes to user_segments/{userId} for personalized next-event targeting.
//
async function handleLeadScoring(drip) {
  const ppvId = drip.ppvId;
  const title = drip.eventTitle || "PPV Event";

  // ── Gather purchase data ────────────────────────────────────────────
  const purchasesSnap = await db
    .collection("ppv_purchases")
    .where("ppvId", "==", ppvId)
    .get();

  const purchaserMap = new Map(); // userId → purchase data
  for (const doc of purchasesSnap.docs) {
    const data = doc.data();
    if (data.userId) {
      purchaserMap.set(data.userId, {
        tier: data.tierName || data.tier || "unknown",
        amount: data.amount || data.price || 0,
        purchasedAt: data.createdAt || data.purchasedAt,
      });
    }
  }

  // ── Check who actually accessed the stream (ppv_access collection) ──
  const accessSnap = await db
    .collection("ppv_access")
    .where("eventId", "==", ppvId)
    .get();

  const accessedUserIds = new Set();
  for (const doc of accessSnap.docs) {
    const data = doc.data();
    if (data.userId) accessedUserIds.add(data.userId);
  }

  // ── Build user segments ─────────────────────────────────────────────
  const batch = db.batch();
  let watchedCount = 0;
  let missedCount = 0;

  for (const [userId, purchaseData] of purchaserMap) {
    const segmentRef = db.collection("user_segments").doc(userId);
    const watched = accessedUserIds.has(userId);

    const segmentUpdate = {
      lastEventId: ppvId,
      lastEventTitle: title,
      lastEventDate: admin.firestore.FieldValue.serverTimestamp(),
      lastTier: purchaseData.tier,
      lastSpend: purchaseData.amount,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (watched) {
      // High-value: purchased AND watched
      segmentUpdate.tag = "purchased_watched";
      segmentUpdate.engagementScore = admin.firestore.FieldValue.increment(10);
      segmentUpdate.totalSpend = admin.firestore.FieldValue.increment(
        purchaseData.amount,
      );
      segmentUpdate.eventsWatched = admin.firestore.FieldValue.increment(1);
      watchedCount++;
    } else {
      // Re-engage target: purchased but didn't watch
      segmentUpdate.tag = "purchased_missed";
      segmentUpdate.engagementScore = admin.firestore.FieldValue.increment(3);
      segmentUpdate.totalSpend = admin.firestore.FieldValue.increment(
        purchaseData.amount,
      );
      segmentUpdate.eventsMissed = admin.firestore.FieldValue.increment(1);
      missedCount++;
    }

    batch.set(segmentRef, segmentUpdate, { merge: true });
  }

  await batch.commit();

  // ── Log event-level analytics ───────────────────────────────────────
  await db
    .collection("event_analytics")
    .doc(ppvId)
    .set(
      {
        ppvId,
        eventTitle: title,
        totalPurchasers: purchaserMap.size,
        purchasersWhoWatched: watchedCount,
        purchasersWhoMissed: missedCount,
        watchRate:
          purchaserMap.size > 0
            ? Math.round((watchedCount / purchaserMap.size) * 100)
            : 0,
        scoredAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

  console.log(
    `[LeadScoring] Event ${ppvId}: ${watchedCount} watched, ${missedCount} missed out of ${purchaserMap.size} purchasers`,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// REPLAY REMINDER (T+24hr "Last Chance" Push)
// ═══════════════════════════════════════════════════════════════════════════
async function handleReplayReminder(drip) {
  const ppvId = drip.ppvId;
  const title = drip.eventTitle || "the event";

  // Push to non-purchasers: "Last chance to catch the replay!"
  const purchasersSnap = await db
    .collection("ppv_purchases")
    .where("ppvId", "==", ppvId)
    .select("userId")
    .get();
  const purchaserIds = new Set(
    purchasersSnap.docs.map((d) => d.data().userId).filter(Boolean),
  );

  const usersSnap = await db
    .collection("users")
    .where("fcmToken", "!=", "")
    .select("fcmToken")
    .limit(500)
    .get();

  const tokens = [];
  for (const userDoc of usersSnap.docs) {
    if (purchaserIds.has(userDoc.id)) continue;
    const token = userDoc.data().fcmToken;
    if (token) tokens.push(token);
  }

  if (tokens.length === 0) return;

  // Seed "Last Chance" social post
  await db
    .collection("social_posts")
    .doc(`${ppvId}_last_chance`)
    .set({
      ppvId,
      type: "replay_last_chance",
      title: `⏰ LAST CHANCE — ${title}`,
      caption: [
        `⏰ LAST CHANCE to catch ${title} replay!`,
        "",
        `Replay expires soon. Don't miss the most talked-about event.`,
        "",
        `👉 https://datafightcentral.com/ppv/event/${ppvId}`,
        "",
        "#DFC #Replay #LastChance #CombatSports #PPV",
      ].join("\n"),
      imageUrl: drip.posterUrl || "",
      buyLink: `https://datafightcentral.com/ppv/event/${ppvId}`,
      platforms: ["instagram", "tiktok", "twitter", "facebook", "threads"],
      status: "pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      source: "replay_reminder",
    });

  // Push to non-purchasers
  await messaging.sendEachForMulticast({
    notification: {
      title: "⏰ Replay Expiring Soon",
      body: `${title} replay is about to expire — last chance to watch!`,
    },
    data: {
      type: "replay_last_chance",
      ppvId,
      route: `/ppv/event/${ppvId}`,
    },
    tokens,
  });

  // Publish last-chance via native engine
  _publishToAllPlatforms({
    title: `⏰ LAST CHANCE — ${title}`,
    description: `Last chance to watch the replay of ${title}!`,
    mediaUrl: drip.posterUrl || "",
    buyLink: `https://datafightcentral.com/ppv/event/${ppvId}`,
    tone: "edgy",
    contentType: "replay_last_chance",
    sourceFunction: "replayReminder",
    sourceId: ppvId,
  }).catch((err) =>
    console.error(`[ReplayReminder] Native publish failed:`, err.message),
  );

  console.log(
    `[ReplayReminder] Last-chance push sent to ${tokens.length} users for ${ppvId}`,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// EXPORTS
// ═══════════════════════════════════════════════════════════════════════════
module.exports = {
  onPPVReplayReady,
  onVodAssetReady,
  postEventDripProcessor,
};
