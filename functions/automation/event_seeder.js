// ═══════════════════════════════════════════════════════════════════════════
// DFC EVENT AUTO-SEEDER — Zero-Touch Social Distribution Pipeline
// ═══════════════════════════════════════════════════════════════════════════
//
// FLOW:
//   1. New ppv_events doc created → Firestore trigger fires
//   2. Generates dynamic poster URL (Cloudinary overlay on bgHero template)
//   3. Writes to social_posts staging collection (internal feed)
//   4. Pings n8n webhook with event metadata → n8n seeds to 9 platforms via Blotato
//   5. Sends FCM push notification to all registered users
//   6. Updates event doc with seeding status + poster URL
//
// EXTERNAL DEPS (configured outside this codebase):
//   - n8n instance with Blotato community node (@blotato/n8n-nodes-blotato)
//   - Blotato Pro account + API key
//   - Google Sheet (TITLE, MEDIA_URL, CAPTION, STATUS, FIGHT_ID columns)
//   - N8N_WEBHOOK_URL env var pointing to the n8n webhook trigger
//   - CLOUDINARY_CLOUD_NAME env var for poster generation
// ═══════════════════════════════════════════════════════════════════════════

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, onRequest } = require("firebase-functions/v2/https");
const { admin, db, REGION } = require("../config");

// Native engine — replaces n8n + Blotato ($0/month)
const { _publishToAllPlatforms } = require("../content/social_publisher");

const messaging = admin.messaging();

// ─── Cloudinary Dynamic Poster URL Generator ─────────────────────────────
// Generates a branded poster by overlaying event metadata onto the DFC
// bgHero template using Cloudinary's URL-based transformations.
// No SDK needed — pure URL construction.
function buildPosterUrl(eventData) {
  const cloudName = process.env.CLOUDINARY_CLOUD_NAME || "datafightcentral";
  const baseImage = "dfc_backgrounds/bgHero"; // Cloudinary public ID

  const title = (eventData.name || eventData.title || "FIGHT NIGHT")
    .replace(/[^a-zA-Z0-9 ]/g, "")
    .substring(0, 60);
  const price = eventData.price ? `$${eventData.price}` : "PPV";
  const dateStr = eventData.eventDate
    ? new Date(eventData.eventDate._seconds * 1000).toLocaleDateString(
        "en-AU",
        {
          month: "short",
          day: "numeric",
          year: "numeric",
        },
      )
    : "";

  // Cloudinary URL-based text overlay transformation
  // l_text: = text overlay, co_white = color, g_south = gravity
  const titleOverlay = `l_text:Arial_60_bold:${encodeURIComponent(title)},co_white,g_north,y_120`;
  const priceOverlay = `l_text:Arial_48_bold:${encodeURIComponent(price)},co_rgb:00ff88,g_south,y_180`;
  const dateOverlay = dateStr
    ? `l_text:Arial_36:${encodeURIComponent(dateStr)},co_white,g_south,y_120`
    : "";

  const transforms = [
    "w_1080,h_1350,c_fill", // Instagram-ready 4:5
    titleOverlay,
    priceOverlay,
    dateOverlay,
    "q_auto,f_auto", // auto quality + format
  ]
    .filter(Boolean)
    .join("/");

  return `https://res.cloudinary.com/${cloudName}/image/upload/${transforms}/${baseImage}.jpg`;
}

// ─── Build caption with deep link to PPV checkout ────────────────────────
function buildCaption(eventData, eventId) {
  const title = eventData.name || eventData.title || "FIGHT NIGHT";
  const price = eventData.price ? `$${eventData.price}` : "";
  const promoter = eventData.promoterName
    ? ` | Presented by ${eventData.promoterName}`
    : "";
  const dateStr = eventData.eventDate
    ? new Date(eventData.eventDate._seconds * 1000).toLocaleDateString(
        "en-AU",
        {
          weekday: "short",
          month: "short",
          day: "numeric",
        },
      )
    : "";

  return [
    `🥊 ${title}`,
    dateStr ? `📅 ${dateStr}` : "",
    price ? `🎟️ Watch LIVE on PPV for only ${price}` : "",
    promoter,
    "",
    `🔗 Buy your ticket: https://datafightcentral.com/ppv/event/${eventId}`,
    "",
    "#DFC #PPV #CombatSports #MMA #Boxing #LiveFight",
  ]
    .filter(Boolean)
    .join("\n");
}

// ═══════════════════════════════════════════════════════════════════════════
// 1. FIRESTORE TRIGGER — New PPV Event Created
// ═══════════════════════════════════════════════════════════════════════════
const onNewPPVEvent = onDocumentCreated(
  {
    document: "ppv_events/{ppvId}",
    region: REGION,
  },
  async (event) => {
    const eventData = event.data.data();
    const ppvId = event.params.ppvId;

    // Skip if this event was already seeded (idempotency guard)
    if (
      eventData.seedingStatus === "seeded" ||
      eventData.seedingStatus === "seeding"
    ) {
      console.log(`[EventSeeder] ${ppvId} already seeded/seeding — skipping`);
      return;
    }

    console.log(
      `[EventSeeder] New PPV event detected: ${ppvId} — "${eventData.name || eventData.title}"`,
    );

    try {
      // Mark as seeding immediately (prevents duplicate triggers)
      await event.data.ref.update({
        seedingStatus: "seeding",
        seedingStartedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // ── Step 1: Generate dynamic poster URL ──
      const posterUrl = buildPosterUrl(eventData);

      // ── Step 2: Write poster URL back to event doc ──
      await event.data.ref.update({
        promo_poster_url: posterUrl,
      });

      // ── Step 3: Write to social_posts staging collection ──
      const caption = buildCaption(eventData, ppvId);
      const socialPostRef = await db.collection("social_posts").add({
        type: "ppv_promo",
        ppvId,
        title: eventData.name || eventData.title || "FIGHT NIGHT",
        caption,
        mediaUrl: posterUrl,
        thumbnailUrl: eventData.thumbnailUrl || posterUrl,
        price: eventData.price || 0,
        promoterId: eventData.promoterId || "",
        promoterName: eventData.promoterName || "",
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
        seedingStatus: "pending",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // ── Step 4: Publish to all platforms via NATIVE engine (no n8n) ──
      let publishResult = null;
      try {
        publishResult = await _publishToAllPlatforms({
          title: eventData.name || eventData.title || "FIGHT NIGHT",
          description: (eventData.description || "").substring(0, 500),
          mediaUrl: posterUrl,
          buyLink: `https://datafightcentral.com/ppv/event/${ppvId}`,
          tone: "hype",
          contentType: "ppv_promo",
          price: eventData.price ? `${eventData.price}` : "",
          promoterName: eventData.promoterName || "",
          sourceFunction: "event_seeder",
          sourceId: ppvId,
        });

        console.log(
          `[EventSeeder] Native publish complete: ${publishResult.successCount}✅ ${publishResult.failCount}❌`,
        );
        await db.collection("social_posts").doc(socialPostRef.id).update({
          seedingStatus: "native_published",
          publishResult,
          publishedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (publishErr) {
        // Publishing failure is non-fatal — the social_posts doc still exists
        console.warn(
          `[EventSeeder] Native publish failed for ${ppvId}:`,
          publishErr.message,
        );
        await db.collection("social_posts").doc(socialPostRef.id).update({
          seedingStatus: "publish_failed",
          publishError: publishErr.message,
        });
      }

      // ── Step 5: Send FCM push to all registered users ──
      await sendNewEventPush(eventData, ppvId, posterUrl);

      // ── Step 6: Schedule drip-feed posts (T-24h, T-6h, T-10min) ──
      await scheduleDripPosts(eventData, ppvId, posterUrl);

      // ── Step 7: Update event with final seeding status ──
      await event.data.ref.update({
        seedingStatus: "seeded",
        seedingCompletedAt: admin.firestore.FieldValue.serverTimestamp(),
        socialPostId: socialPostRef.id,
      });

      console.log(`[EventSeeder] ✅ Full pipeline complete for ${ppvId}`);
    } catch (err) {
      console.error(`[EventSeeder] ❌ Pipeline failed for ${ppvId}:`, err);
      await event.data.ref
        .update({
          seedingStatus: "error",
          seedingError: err.message,
        })
        .catch(() => {});
    }
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// 2. FCM PUSH — "New Fight Added!" broadcast to all users
// ═══════════════════════════════════════════════════════════════════════════
async function sendNewEventPush(eventData, ppvId, posterUrl) {
  try {
    // Get all users with FCM tokens (batch of 500 per multicast limit)
    const usersSnap = await db
      .collection("users")
      .where("fcmToken", "!=", null)
      .limit(500)
      .get();

    if (usersSnap.empty) {
      console.log("[EventSeeder] No FCM tokens registered — skipping push");
      return;
    }

    const tokens = usersSnap.docs
      .map((doc) => doc.data().fcmToken)
      .filter(Boolean);

    if (tokens.length === 0) return;

    const title = eventData.name || eventData.title || "FIGHT NIGHT";
    const price = eventData.price ? `$${eventData.price}` : "";

    await messaging.sendEachForMulticast({
      notification: {
        title: "🥊 New Fight Added!",
        body: `${title}${price ? ` — PPV ${price}` : ""}. Get early bird tickets now!`,
        imageUrl: posterUrl,
      },
      data: {
        type: "new_ppv_event",
        ppvId,
        route: `/ppv/event/${ppvId}`,
      },
      android: {
        priority: "high",
        notification: { channelId: "dfc_events" },
      },
      apns: {
        payload: {
          aps: { "mutable-content": 1, sound: "default" },
        },
      },
      tokens,
    });

    console.log(
      `[EventSeeder] FCM push sent to ${tokens.length} devices for ${ppvId}`,
    );
  } catch (fcmErr) {
    // FCM failure is non-fatal
    console.warn("[EventSeeder] FCM push failed:", fcmErr.message);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. N8N POST-BACK — HTTP endpoint for n8n to report seeding results
// ═══════════════════════════════════════════════════════════════════════════
// After Blotato seeds the post, n8n calls this function with the live
// social media URLs. Updates both the event doc and social_posts doc.
// Uses onRequest (not onCall) because n8n sends a raw HTTP POST.
const n8nPostBack = onRequest(
  { region: REGION, cors: true },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    try {
      const {
        eventId,
        socialPostId,
        platforms, // { instagram: 'https://...', tiktok: 'https://...', ... }
        status, // 'posted' | 'partial' | 'failed'
      } = req.body;

      if (!eventId || !socialPostId) {
        res
          .status(400)
          .json({ error: "eventId and socialPostId are required" });
        return;
      }

      const updates = {
        seedingStatus: status === "posted" ? "seeded_live" : status,
        socialLinks: platforms || {},
        n8nCompletedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // Update the social_posts staging doc (merge: create if missing)
      await db
        .collection("social_posts")
        .doc(socialPostId)
        .set(
          {
            eventId,
            status: status === "posted" ? "posted" : status,
            platformLinks: platforms || {},
            postedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );

      // Update the PPV event with social proof links (merge: safe on existing doc)
      await db
        .collection("ppv_events")
        .doc(eventId)
        .set(updates, { merge: true });

      console.log(
        `[n8nPostBack] Event ${eventId} updated: ${status}, platforms: ${Object.keys(platforms || {}).length}`,
      );

      res.status(200).json({
        status: "ok",
        message: `Event ${eventId} social seeding status updated to ${status}`,
      });
    } catch (err) {
      console.error("[n8nPostBack] Error:", err.message);
      res.status(500).json({ error: err.message });
    }
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// 4. MANUAL SEED — Re-trigger seeding for an existing event (admin tool)
// ═══════════════════════════════════════════════════════════════════════════
const manualSeedEvent = onCall({ region: REGION }, async (request) => {
  const { ppvId } = request.data;
  if (!ppvId) return { error: "ppvId is required" };

  const eventDoc = await db.collection("ppv_events").doc(ppvId).get();
  if (!eventDoc.exists) return { error: "Event not found" };

  const eventData = eventDoc.data();
  const posterUrl = buildPosterUrl(eventData);
  const caption = buildCaption(eventData, ppvId);

  // Publish via native engine (no n8n needed)
  const publishResult = await _publishToAllPlatforms({
    title: eventData.name || eventData.title || "FIGHT NIGHT",
    description: (eventData.description || "").substring(0, 500),
    mediaUrl: posterUrl,
    buyLink: `https://datafightcentral.com/ppv/event/${ppvId}`,
    tone: "hype",
    contentType: "ppv_promo",
    price: eventData.price ? `${eventData.price}` : "",
    promoterName: eventData.promoterName || "",
    sourceFunction: "manualSeedEvent",
    sourceId: ppvId,
  });

  await eventDoc.ref.update({
    seedingStatus: "reseeding",
    promo_poster_url: posterUrl,
    reseedTriggeredAt: admin.firestore.FieldValue.serverTimestamp(),
    publishResult,
  });

  return {
    status: "ok",
    posterUrl,
    publishResult,
    message: `Re-seed triggered for ${ppvId}`,
  };
});

// ═══════════════════════════════════════════════════════════════════════════
// 5. DRIP-FEED SCHEDULING — Pre-schedule 3 posts at creation time
// ═══════════════════════════════════════════════════════════════════════════
// Writes to `drip_posts` collection with exact `publishAt` timestamps.
// The drip_scheduler.js function picks them up when they're due.
async function scheduleDripPosts(eventData, ppvId, posterUrl) {
  const eventDate = eventData.eventDate || eventData.startTime;
  if (!eventDate) {
    console.log(
      `[EventSeeder] No eventDate/startTime — skipping drip scheduling for ${ppvId}`,
    );
    return;
  }

  // Convert Firestore Timestamp to JS Date
  const eventMs =
    typeof eventDate.toDate === "function"
      ? eventDate.toDate().getTime()
      : typeof eventDate._seconds === "number"
        ? eventDate._seconds * 1000
        : new Date(eventDate).getTime();

  if (isNaN(eventMs)) {
    console.warn(
      `[EventSeeder] Invalid eventDate — skipping drip scheduling for ${ppvId}`,
    );
    return;
  }

  const title = eventData.name || eventData.title || "FIGHT NIGHT";
  const shared = {
    ppvId,
    eventTitle: title,
    posterUrl: posterUrl || "",
    price: eventData.price || 0,
    promoterId: eventData.promoterId || "",
    promoterName: eventData.promoterName || "",
    status: "pending",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const drips = [
    {
      dripType: "hype_clip",
      publishAt: admin.firestore.Timestamp.fromMillis(
        eventMs - 24 * 60 * 60 * 1000,
      ),
      timeLabel: "24 hours",
    },
    {
      dripType: "poster_drop",
      publishAt: admin.firestore.Timestamp.fromMillis(
        eventMs - 6 * 60 * 60 * 1000,
      ),
      timeLabel: "6 hours",
    },
    {
      dripType: "live_now",
      publishAt: admin.firestore.Timestamp.fromMillis(eventMs - 10 * 60 * 1000),
      timeLabel: "10 minutes",
    },
  ];

  const batch = db.batch();
  const now = Date.now();

  for (const drip of drips) {
    // Skip drips whose time has already passed (event created after window)
    if (drip.publishAt.toMillis() <= now) {
      console.log(
        `[EventSeeder] Skipping ${drip.dripType} — already past for ${ppvId}`,
      );
      continue;
    }
    const ref = db.collection("drip_posts").doc(`${ppvId}_${drip.dripType}`);
    batch.set(ref, { ...shared, ...drip });
  }

  await batch.commit();
  console.log(`[EventSeeder] Drip posts scheduled for ${ppvId}`);
}

module.exports = {
  onNewPPVEvent,
  n8nPostBack,
  manualSeedEvent,
};
