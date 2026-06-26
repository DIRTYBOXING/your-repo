// ═══════════════════════════════════════════════════════════════════════════
// DFC DRIP-FEED SCHEDULER — Autonomous Pre-Event Social Distribution
// ═══════════════════════════════════════════════════════════════════════════
//
// PATTERN: Pre-scheduled document polling (efficient, indexed)
//
//   1. When a ppv_event is created, event_seeder.js writes 3 drip_posts docs
//      with exact `publishAt` timestamps (T-24h, T-6h, T-10min)
//   2. This scheduler runs every 5 minutes
//   3. Queries drip_posts WHERE publishAt <= now AND status == 'pending'
//   4. For each ready doc: writes to social_posts, pings n8n, sends FCM
//   5. Marks doc as 'fired' (idempotent — never fires twice)
//
// COST: ~1 Firestore read per run when nothing is due (empty index scan).
//       Only spends writes when posts actually fire.
// ═══════════════════════════════════════════════════════════════════════════

const { onSchedule } = require("firebase-functions/v2/scheduler");
const { admin, db, REGION } = require("../config");

// Native engine — replaces n8n + Blotato ($0/month)
const { _publishToAllPlatforms } = require("../content/social_publisher");

const messaging = admin.messaging();

// ─── Drip Post Types ─────────────────────────────────────────────────────
const DRIP_TEMPLATES = {
  hype_clip: {
    emoji: "🔥",
    prefix: "COUNTDOWN",
    body: (title, timeLabel) =>
      `${title} is ${timeLabel} away! Who's ready? 🥊💥`,
    hashtags: "#DFC #PPV #Countdown #CombatSports #FightWeek",
  },
  poster_drop: {
    emoji: "🎨",
    prefix: "OFFICIAL POSTER",
    body: (title) =>
      `The official poster for ${title} just dropped. This card is STACKED. 🔥`,
    hashtags: "#DFC #PPV #FightCard #CombatSports #MMA #Boxing",
  },
  live_now: {
    emoji: "🔴",
    prefix: "LIVE NOW",
    body: (title) =>
      `${title} is LIVE! Don't miss a single punch. Stream NOW on DFC. 🥊`,
    hashtags: "#DFC #PPV #LiveNow #CombatSports #WatchLive",
  },
};

// ═══════════════════════════════════════════════════════════════════════════
// SCHEDULED FUNCTION — Runs every 5 minutes
// ═══════════════════════════════════════════════════════════════════════════
const dripFeedProcessor = onSchedule(
  {
    schedule: "every 5 minutes",
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async () => {
    const now = admin.firestore.Timestamp.now();

    // Query only docs that are due AND haven't fired yet
    const readySnap = await db
      .collection("drip_posts")
      .where("status", "==", "pending")
      .where("publishAt", "<=", now)
      .orderBy("publishAt")
      .limit(20) // Process up to 20 per run (safety cap)
      .get();

    if (readySnap.empty) return; // Nothing due — costs 1 read total

    console.log(`[DripScheduler] ${readySnap.size} drip post(s) ready to fire`);

    const batch = db.batch();

    for (const doc of readySnap.docs) {
      const drip = doc.data();
      const template =
        DRIP_TEMPLATES[drip.dripType] || DRIP_TEMPLATES.hype_clip;

      try {
        // ── Build caption from template ──
        const timeLabel = drip.timeLabel || "";
        const title = drip.eventTitle || "FIGHT NIGHT";
        const bodyText =
          drip.dripType === "live_now"
            ? template.body(title)
            : template.body(title, timeLabel);

        const buyLink = `https://datafightcentral.com/ppv/event/${drip.ppvId}`;
        const caption = [
          `${template.emoji} ${template.prefix}`,
          bodyText,
          "",
          `🎟️ Get your ticket: ${buyLink}`,
          "",
          template.hashtags,
        ].join("\n");

        // ── Write to social_posts (internal feed + n8n pickup) ──
        const socialRef = db.collection("social_posts").doc();
        batch.set(socialRef, {
          type: `drip_${drip.dripType}`,
          ppvId: drip.ppvId,
          title,
          caption,
          mediaUrl: drip.posterUrl || "",
          thumbnailUrl: drip.posterUrl || "",
          price: drip.price || 0,
          promoterId: drip.promoterId || "",
          promoterName: drip.promoterName || "",
          targetPlatforms: [
            "instagram",
            "tiktok",
            "youtube_shorts",
            "facebook",
            "x",
            "threads",
            "linkedin",
            "bluesky",
            "pinterest",
          ],
          status: "ready_to_post",
          dripType: drip.dripType,
          dripScheduledFor: drip.publishAt,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // ── Mark drip_post as fired ──
        batch.update(doc.ref, {
          status: "fired",
          firedAt: admin.firestore.FieldValue.serverTimestamp(),
          socialPostId: socialRef.id,
        });

        // ── Publish via native engine (replaces n8n webhook) ──
        _publishToAllPlatforms({
          title,
          description: bodyText,
          mediaUrl: drip.posterUrl || "",
          buyLink,
          tone: "hype",
          contentType: `drip_${drip.dripType}`,
          price: drip.price ? `${drip.price}` : "",
          promoterName: drip.promoterName || "",
          sourceFunction: "drip_scheduler",
          sourceId: drip.ppvId,
        }).catch((err) =>
          console.warn(
            `[DripScheduler] Native publish failed for ${drip.ppvId}:`,
            err.message,
          ),
        );

        // ── FCM push for live_now type ──
        if (drip.dripType === "live_now") {
          await sendLiveNowPush(drip.ppvId, title, drip.posterUrl);
        }

        console.log(
          `[DripScheduler] ✅ Fired ${drip.dripType} for ${drip.ppvId} (scheduled ${drip.publishAt.toDate().toISOString()})`,
        );
      } catch (err) {
        console.error(
          `[DripScheduler] ❌ Failed to fire ${doc.id}:`,
          err.message,
        );
        batch.update(doc.ref, {
          status: "error",
          error: err.message,
          firedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
    console.log(
      `[DripScheduler] Batch committed — ${readySnap.size} drip(s) processed`,
    );
  },
);

// ─── FCM Push for LIVE NOW ───────────────────────────────────────────────
async function sendLiveNowPush(ppvId, title, posterUrl) {
  try {
    // Notify all users (not just purchasers — it's a hype moment)
    const usersSnap = await db
      .collection("users")
      .where("fcmToken", "!=", null)
      .limit(500)
      .get();

    const tokens = usersSnap.docs.map((d) => d.data().fcmToken).filter(Boolean);

    if (tokens.length === 0) return;

    await messaging.sendEachForMulticast({
      notification: {
        title: "🔴 LIVE NOW",
        body: `${title} is streaming! Don't miss a punch.`,
        imageUrl: posterUrl || undefined,
      },
      data: {
        type: "drip_live_now",
        ppvId,
        route: `/ppv/${ppvId}/watch`,
      },
      android: { priority: "high", notification: { channelId: "dfc_events" } },
      apns: { payload: { aps: { "mutable-content": 1, sound: "default" } } },
      tokens,
    });

    console.log(
      `[DripScheduler] LIVE NOW push sent to ${tokens.length} devices for ${ppvId}`,
    );
  } catch (err) {
    console.warn(`[DripScheduler] FCM failed for ${ppvId}:`, err.message);
  }
}

module.exports = {
  dripFeedProcessor,
};
