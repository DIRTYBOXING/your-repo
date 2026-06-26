// ═══════════════════════════════════════════════════════════════════════════
// MAXIMUS PRIME — Video Streaming, PPV, Push Notifications, CDN
// ═══════════════════════════════════════════════════════════════════════════

const { onCall } = require("firebase-functions/v2/https");
const {
  admin,
  db,
  REGION,
  getMuxRuntimeConfig,
  withMuxSecrets,
} = require("../config");

// ─── Get Secure Stream URL ───────────────────────────────────────────────
const getSecureStreamUrl = onCall({ region: REGION }, async (request) => {
  const { streamId, quality, userId } = request.data;
  if (!streamId) return { error: "streamId required" };

  const authUserId = request.auth?.uid || userId;

  const streamDoc = await db.collection("live_streams").doc(streamId).get();
  if (!streamDoc.exists) return { error: "Stream not found" };

  const stream = streamDoc.data();

  // Check PPV access if required
  if (stream.isPPV) {
    if (!authUserId)
      return { error: "Authentication required for PPV content" };
    const purchaseSnap = await db
      .collection("ppv_purchases")
      .where("userId", "==", authUserId)
      .where("streamId", "==", streamId)
      .where("isActive", "==", true)
      .limit(1)
      .get();
    if (purchaseSnap.empty)
      return {
        error: "PPV access required",
        needsPurchase: true,
        priceCents: stream.ppvPriceCents,
      };
  }

  // Select URL based on quality
  let url = stream.streamUrl;
  const qualityMap = {
    sd480: "url480",
    hd720: "url720",
    hd1080: "url1080",
    uhd4k: "url4k",
  };
  if (quality && stream[qualityMap[quality]]) {
    url = stream[qualityMap[quality]];
  } else if (stream.hlsUrl) {
    url = stream.hlsUrl;
  }

  // Generate signed URL with expiration (1 hour)
  const expiresAt = Date.now() + 60 * 60 * 1000;
  const token = Buffer.from(
    `${streamId}:${authUserId || "anon"}:${expiresAt}`,
  ).toString("base64");

  return {
    url: `${url}${url.includes("?") ? "&" : "?"}token=${token}&expires=${expiresAt}`,
    quality: quality || "auto",
    expiresAt: new Date(expiresAt).toISOString(),
    type: stream.type || "hls",
  };
});

// ─── Initiate PPV Purchase ───────────────────────────────────────────────
const initiatePPVPurchase = onCall({ region: REGION }, async (request) => {
  const { userId, streamId, eventId } = request.data;
  if (!userId || !streamId) return { error: "userId and streamId required" };

  const streamDoc = await db.collection("live_streams").doc(streamId).get();
  if (!streamDoc.exists) return { error: "Stream not found" };

  const stream = streamDoc.data();
  if (!stream.isPPV) return { error: "Stream is not PPV" };

  const priceCents = stream.ppvPriceCents || 2999;

  // Check if already purchased
  const existingPurchase = await db
    .collection("ppv_purchases")
    .where("userId", "==", userId)
    .where("streamId", "==", streamId)
    .limit(1)
    .get();

  if (!existingPurchase.empty && existingPurchase.docs[0].data().isActive) {
    return {
      success: true,
      alreadyPurchased: true,
      purchaseId: existingPurchase.docs[0].id,
    };
  }

  // Create purchase record (pending payment)
  const purchaseRef = await db.collection("ppv_purchases").add({
    userId,
    streamId,
    eventId: eventId || stream.eventId || null,
    pricePaidCents: priceCents,
    accessLevel: "purchased",
    isActive: true,
    purchasedAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: null,
    paymentStatus: "pending",
  });

  // Update viewer metrics
  await db
    .collection("live_streams")
    .doc(streamId)
    .update({
      purchaseCount: admin.firestore.FieldValue.increment(1),
    })
    .catch(() => {});

  return {
    success: true,
    purchaseId: purchaseRef.id,
    priceCents,
    streamId,
  };
});

// ─── Create Live Stream ──────────────────────────────────────────────────
// If Mux is configured, delegates to Mux for real RTMP ingest + HLS CDN.
// Otherwise falls back to stubbed DFC ingest URL.
const createLiveStream = onCall(
  withMuxSecrets({ region: REGION }),
  async (request) => {
    const {
      title,
      description,
      type,
      eventId,
      ppvEventId,
      fightId,
      isPPV,
      ppvPriceCents,
      scheduledStart,
      thumbnailUrl,
    } = request.data;
    if (!title) return { error: "title required" };

    const streamData = {
      title,
      description: description || "",
      type: type || "hls",
      status: "scheduled",
      streamUrl: "",
      hlsUrl: "",
      dashUrl: "",
      youtubeId: null,
      thumbnailUrl: thumbnailUrl || "",
      eventId: eventId || null,
      ppvEventId: ppvEventId || null,
      fightId: fightId || null,
      viewerCount: 0,
      isPPV: isPPV || false,
      ppvPriceCents: ppvPriceCents || 2999,
      scheduledStart: scheduledStart ? new Date(scheduledStart) : null,
      actualStart: null,
      endedAt: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: request.auth?.uid || "system",
      metadata: {},
    };

    // ── Try Mux first (real ingest) ──────────────────────────────────────
    const { tokenId, tokenSecret, signingKeyId } = getMuxRuntimeConfig();
    const hasMux = !!tokenId && !!tokenSecret;
    if (hasMux) {
      try {
        const Mux = require("@mux/mux-node");
        const mux = new Mux({
          tokenId,
          tokenSecret,
        });

        const useSignedPlayback = !!signingKeyId;
        const liveStream = await mux.video.liveStreams.create({
          playback_policy: [useSignedPlayback ? "signed" : "public"],
          new_asset_settings: {
            playback_policy: [useSignedPlayback ? "signed" : "public"],
            mp4_support: "standard",
          },
          latency_mode: "low",
          reconnect_window: 30,
          max_continuous_duration: 28800,
        });

        const streamKey = liveStream.stream_key;
        const playbackId = liveStream.playback_ids?.[0]?.id;
        const muxStreamId = liveStream.id;

        streamData.streamKey = streamKey;
        streamData.rtmpIngestUrl = `rtmp://global-live.mux.com:5222/app/${streamKey}`;
        streamData.hlsUrl = `https://stream.mux.com/${playbackId}.m3u8`;
        streamData.streamUrl = streamData.hlsUrl;
        streamData.muxStreamId = muxStreamId;
        streamData.muxPlaybackId = playbackId;
        streamData.streamProvider = "mux";

        const docRef = await db.collection("live_streams").add(streamData);

        if (ppvEventId) {
          await db
            .collection("ppv_events")
            .doc(ppvEventId)
            .set(
              {
                streamUrl: streamData.hlsUrl,
                streamStatus: "idle",
                streamProvider: "mux",
              },
              { merge: true },
            )
            .catch(() => {});
        }

        return {
          success: true,
          streamId: docRef.id,
          streamKey,
          rtmpIngestUrl: streamData.rtmpIngestUrl,
          hlsUrl: streamData.hlsUrl,
          playbackId,
          provider: "mux",
        };
      } catch (e) {
        console.error(
          "Mux stream creation failed, falling back to stub:",
          e.message,
        );
        // Fall through to stub if Mux fails
      }
    }

    // ── Fallback: stubbed DFC ingest URL ─────────────────────────────────
    const streamKey = `dfc_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    streamData.streamKey = streamKey;
    streamData.rtmpIngestUrl = `rtmp://ingest.datafightcentral.com/live/${streamKey}`;
    streamData.hlsUrl = `https://stream.datafightcentral.com/${streamKey}/master.m3u8`;
    streamData.streamUrl = streamData.hlsUrl;
    streamData.streamProvider = "stub";

    const docRef = await db.collection("live_streams").add(streamData);

    if (ppvEventId) {
      await db
        .collection("ppv_events")
        .doc(ppvEventId)
        .set(
          {
            streamUrl: streamData.hlsUrl,
            streamStatus: "rehearsal",
            streamProvider: "stub",
          },
          { merge: true },
        )
        .catch(() => {});
    }

    return {
      success: true,
      streamId: docRef.id,
      streamKey,
      rtmpIngestUrl: streamData.rtmpIngestUrl,
      hlsUrl: streamData.hlsUrl,
      provider: "stub",
    };
  },
);

// ─── Update Stream Status ────────────────────────────────────────────────
const updateStreamStatus = onCall({ region: REGION }, async (request) => {
  const { streamId, status, streamUrl, hlsUrl, youtubeId } = request.data;
  if (!streamId || !status) return { error: "streamId and status required" };

  const updates = { status };
  if (status === "live")
    updates.actualStart = admin.firestore.FieldValue.serverTimestamp();
  if (status === "ended" || status === "vod")
    updates.endedAt = admin.firestore.FieldValue.serverTimestamp();
  if (streamUrl) updates.streamUrl = streamUrl;
  if (hlsUrl) updates.hlsUrl = hlsUrl;
  if (youtubeId) updates.youtubeId = youtubeId;

  await db.collection("live_streams").doc(streamId).update(updates);

  return { success: true, streamId, status };
});

// ─── Send Push Notification ──────────────────────────────────────────────
const sendPushNotification = onCall({ region: REGION }, async (request) => {
  const { userIds, topic, title, body, data, imageUrl, priority } =
    request.data;
  if (!title || !body) return { error: "title and body required" };
  if (!userIds && !topic) return { error: "userIds or topic required" };

  let fcmAdmin;
  try {
    fcmAdmin = admin.messaging();
  } catch (_) {
    return { error: "Firebase Messaging not configured" };
  }

  const notification = { title, body };
  if (imageUrl) notification.imageUrl = imageUrl;

  const androidConfig = {
    priority: priority === "urgent" ? "high" : "normal",
    notification: { ...notification, channelId: "dfc_main" },
  };
  const apnsConfig = {
    payload: { aps: { alert: notification, sound: "default", badge: 1 } },
  };

  let successCount = 0;
  let failureCount = 0;

  // Send to topic
  if (topic) {
    try {
      await fcmAdmin.send({
        topic,
        notification,
        data: data || {},
        android: androidConfig,
        apns: apnsConfig,
      });
      successCount++;
    } catch (e) {
      console.error("Push to topic failed:", e.message);
      failureCount++;
    }
  }

  // Send to specific users
  if (userIds && Array.isArray(userIds)) {
    const tokens = [];
    for (const userId of userIds.slice(0, 500)) {
      const tokenDoc = await db.collection("fcm_tokens").doc(userId).get();
      if (tokenDoc.exists && tokenDoc.data().token) {
        tokens.push(tokenDoc.data().token);
      }
    }

    if (tokens.length > 0) {
      const messages = tokens.map((token) => ({
        token,
        notification,
        data: data || {},
        android: androidConfig,
        apns: apnsConfig,
      }));

      const response = await fcmAdmin.sendEach(messages);
      successCount += response.successCount;
      failureCount += response.failureCount;
    }
  }

  // Log notification
  await db.collection("push_notifications_log").add({
    title,
    body,
    topic,
    userCount: userIds?.length || 0,
    successCount,
    failureCount,
    sentAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true, successCount, failureCount };
});

// ─── Send Test Push Notification ─────────────────────────────────────────
const sendTestPushNotification = onCall({ region: REGION }, async (request) => {
  const { userId } = request.data;
  if (!userId) return { error: "userId required" };

  const tokenDoc = await db.collection("fcm_tokens").doc(userId).get();
  if (!tokenDoc.exists || !tokenDoc.data().token) {
    return { error: "No FCM token found for user" };
  }

  let fcmAdmin;
  try {
    fcmAdmin = admin.messaging();
    await fcmAdmin.send({
      token: tokenDoc.data().token,
      notification: {
        title: "🥊 DFC Test",
        body: "Push notifications are working!",
      },
      data: { type: "test", timestamp: Date.now().toString() },
    });
    return { success: true };
  } catch (e) {
    return { error: e.message };
  }
});

// ─── Process CDN Media ───────────────────────────────────────────────────
const processCDNMedia = onCall({ region: REGION }, async (request) => {
  const { mediaId, originalUrl, storagePath, type, fileSize, metadata } =
    request.data;
  if (!mediaId || !originalUrl)
    return { error: "mediaId and originalUrl required" };

  const cdnBase = "https://storage.googleapis.com/datafightcentral.appspot.com";
  const variants = {};
  let thumbnailUrl = null;

  if (type === "image") {
    const basePath = storagePath.replace(/\.[^/.]+$/, "");
    variants.thumbnail = `${cdnBase}/${basePath}_thumb.webp`;
    variants.small = `${cdnBase}/${basePath}_400.webp`;
    variants.medium = `${cdnBase}/${basePath}_800.webp`;
    variants.large = `${cdnBase}/${basePath}_1200.webp`;
    variants.original = originalUrl;
    thumbnailUrl = variants.thumbnail;
  } else if (type === "video") {
    const basePath = storagePath.replace(/\.[^/.]+$/, "");
    variants.preview = `${cdnBase}/${basePath}_preview.mp4`;
    variants.sd480 = `${cdnBase}/${basePath}_480.mp4`;
    variants.hd720 = `${cdnBase}/${basePath}_720.mp4`;
    variants.hd1080 = `${cdnBase}/${basePath}_1080.mp4`;
    variants.original = originalUrl;
    thumbnailUrl = `${cdnBase}/${basePath}_thumb.jpg`;
  }

  const mediaData = {
    id: mediaId,
    originalUrl,
    storagePath,
    type,
    status: "ready",
    variants,
    thumbnailUrl,
    fileSize: fileSize || 0,
    mimeType: metadata?.contentType || "application/octet-stream",
    uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
    metadata: metadata || {},
  };

  await db.collection("cdn_media").doc(mediaId).set(mediaData);

  return {
    success: true,
    media: { ...mediaData, uploadedAt: new Date().toISOString() },
  };
});

// ─── Generate Signed Media URL ───────────────────────────────────────────
const generateSignedMediaUrl = onCall({ region: REGION }, async (request) => {
  const { mediaId, expirationSeconds } = request.data;
  if (!mediaId) return { error: "mediaId required" };

  const mediaDoc = await db.collection("cdn_media").doc(mediaId).get();
  if (!mediaDoc.exists) return { error: "Media not found" };

  const media = mediaDoc.data();
  const expiration = Date.now() + (expirationSeconds || 3600) * 1000;
  const token = Buffer.from(`${mediaId}:${expiration}`).toString("base64");

  const signedUrl = `${media.originalUrl}${media.originalUrl.includes("?") ? "&" : "?"}token=${token}&expires=${expiration}`;

  return { signedUrl, expiresAt: new Date(expiration).toISOString() };
});

// ─── Broadcast Fight Update ──────────────────────────────────────────────
const broadcastFightUpdate = onCall({ region: REGION }, async (request) => {
  const { fightId, updateType, payload } = request.data;
  if (!fightId || !updateType)
    return { error: "fightId and updateType required" };

  // Write to realtime updates collection
  const updateRef = await db.collection("fight_updates").add({
    fightId,
    type: updateType,
    payload: payload || {},
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Clean up old updates (keep last 100)
  const oldUpdates = await db
    .collection("fight_updates")
    .where("fightId", "==", fightId)
    .orderBy("timestamp", "desc")
    .offset(100)
    .limit(50)
    .get();

  if (!oldUpdates.empty) {
    const batch = db.batch();
    oldUpdates.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  }

  // Send push notification for major events
  const majorEvents = ["knockout", "submission", "decision", "roundEnd"];
  if (majorEvents.includes(updateType)) {
    try {
      const fcmAdmin = admin.messaging();
      await fcmAdmin.send({
        topic: `fight_${fightId}`,
        notification: {
          title: `🥊 ${updateType.toUpperCase()}`,
          body: payload?.description || "Major event in the fight!",
        },
        data: { fightId, updateType, ...payload },
      });
    } catch (e) {
      console.error("Push notification failed:", e.message);
    }
  }

  return { success: true, updateId: updateRef.id };
});

module.exports = {
  getSecureStreamUrl,
  initiatePPVPurchase,
  createLiveStream,
  updateStreamStatus,
  sendPushNotification,
  sendTestPushNotification,
  processCDNMedia,
  generateSignedMediaUrl,
  broadcastFightUpdate,
};
