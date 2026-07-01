// ═══════════════════════════════════════════════════════════════════════════
// MAXIMUS PRIME — Mux Live Stream Ingest Pipeline
// ═══════════════════════════════════════════════════════════════════════════
//
// Mux handles:
//   • RTMP ingest (promoter pushes OBS/vMix to rtmp://live.mux.com/app)
//   • ABR transcoding (360p → 4K, automatic)
//   • HLS delivery via global CDN
//   • Low-latency mode (sub-3s glass-to-glass)
//   • Signed playback URLs (JWT tokens)
//   • Automatic VOD asset creation from live streams
//   • Stream health monitoring & analytics
//
// Environment Variables (Firebase Secrets):
//   MUX_TOKEN_ID         — Mux API access token ID
//   MUX_TOKEN_SECRET     — Mux API secret key
//   MUX_SIGNING_KEY_ID   — Signing key for JWT playback tokens
//   MUX_SIGNING_PRIVATE_KEY — Base64-encoded RSA private key for JWT
//   MUX_WEBHOOK_SECRET   — Webhook signature verification secret
//
// ═══════════════════════════════════════════════════════════════════════════

const {
  onCall,
  onRequest,
  HttpsError,
} = require("firebase-functions/v2/https");
const {
  admin,
  db,
  REGION,
  getMuxRuntimeConfig,
  MUX_TOKEN_ID_PARAM,
  MUX_TOKEN_SECRET_PARAM,
  PPV_SMOKE_TOKEN_PARAM,
  withMuxSecrets,
  sgMail,
  FROM_EMAIL,
} = require("../config");
const crypto = require("node:crypto");
const {
  getCanonicalPpvAccessState,
  resolvePpvEventDocument,
} = require("../ppv/access_state");

// ─── Mux Client (lazy init) ─────────────────────────────────────────────
let muxClient = null;

function getMuxClient() {
  if (muxClient) return muxClient;

  const { tokenId, tokenSecret } = getMuxRuntimeConfig();
  if (!tokenId || !tokenSecret) return null;

  try {
    const Mux = require("@mux/mux-node");
    muxClient = new Mux({ tokenId, tokenSecret });
    return muxClient;
  } catch (e) {
    console.error("Mux SDK not available:", e.message);
    return null;
  }
}

function withMuxSmokeSecrets(options = {}) {
  const existingSecrets = Array.isArray(options.secrets) ? options.secrets : [];

  return {
    ...options,
    secrets: [
      ...new Set([
        ...existingSecrets,
        MUX_TOKEN_ID_PARAM,
        MUX_TOKEN_SECRET_PARAM,
      ]),
    ],
  };
}

function resolveOptionalSmokeToken() {
  const envToken = (process.env.PPV_SMOKE_TOKEN || "").trim();
  if (envToken) {
    return envToken;
  }

  try {
    return (PPV_SMOKE_TOKEN_PARAM.value() || "").trim();
  } catch {
    return "";
  }
}

// ─── JWT Signing for Playback Tokens ─────────────────────────────────────
function signPlaybackToken(playbackId, options = {}) {
  const { signingKeyId, signingPrivateKey: signingPrivateKeyBase64 } =
    getMuxRuntimeConfig();
  if (!signingKeyId || !signingPrivateKeyBase64) return null;

  try {
    const jwt = require("jsonwebtoken");
    const privateKey = Buffer.from(signingPrivateKeyBase64, "base64").toString(
      "ascii",
    );

    const payload = {
      sub: playbackId,
      aud: options.type || "v", // 'v' for video, 't' for thumbnail, 's' for storyboard
      exp: Math.floor(Date.now() / 1000) + (options.expSeconds || 21600), // 6 hours default
      kid: signingKeyId,
    };

    return jwt.sign(payload, privateKey, {
      algorithm: "RS256",
      keyid: signingKeyId,
    });
  } catch (e) {
    console.error("JWT signing failed:", e.message);
    return null;
  }
}

function getAccessDeniedMessage(reason, replay = false) {
  if (reason === "expired") {
    return replay
      ? "Your replay access has expired"
      : "Your PPV access has expired";
  }
  if (reason === "refunded") {
    return "Your PPV purchase was refunded";
  }
  if (reason === "revoked") {
    return replay
      ? "Your replay access was revoked"
      : "Your PPV access was revoked";
  }
  return replay ? "PPV access required for replay" : "PPV access required";
}

function toRuntimeDate(value) {
  if (!value) {
    return null;
  }
  if (typeof value.toDate === "function") {
    return value.toDate();
  }
  return new Date(value);
}

function normalizeText(value) {
  return typeof value === "string" ? value.trim() : "";
}

function buildLocationLabel(eventData = {}) {
  return [eventData.venue, eventData.city, eventData.state, eventData.country]
    .map((value) => normalizeText(value))
    .filter(Boolean)
    .join(", ");
}

function formatCredentialEventDate(value) {
  const date = toRuntimeDate(value);
  if (!date || Number.isNaN(date.getTime())) {
    return "TBC";
  }

  try {
    return new Intl.DateTimeFormat("en-AU", {
      dateStyle: "full",
      timeStyle: "short",
      timeZone: "Australia/Sydney",
    }).format(date);
  } catch {
    return date.toISOString();
  }
}

function buildMuxError(message, extra = {}) {
  return {
    error: message,
    ...extra,
  };
}

async function resolveRequestedEventContext(ppvEventId) {
  if (!ppvEventId) {
    return { event: null, eventId: null };
  }

  const event = await resolvePpvEventDocument(db, ppvEventId);
  return {
    event,
    eventId: event?.id || ppvEventId,
  };
}

async function findMuxStreamDocument({
  streamDocId,
  eventId,
  fallbackEventId,
}) {
  if (streamDocId) {
    const streamDoc = await db.collection("mux_streams").doc(streamDocId).get();
    return streamDoc.exists ? streamDoc : null;
  }

  const lookupEventId = eventId || fallbackEventId;
  if (!lookupEventId) {
    return null;
  }

  let streamSnap = await db
    .collection("mux_streams")
    .where("ppvEventId", "==", lookupEventId)
    .limit(1)
    .get();

  if (
    streamSnap.empty &&
    eventId &&
    fallbackEventId &&
    eventId !== fallbackEventId
  ) {
    streamSnap = await db
      .collection("mux_streams")
      .where("ppvEventId", "==", fallbackEventId)
      .limit(1)
      .get();
  }

  return streamSnap.empty ? null : streamSnap.docs[0];
}

function getEventAvailabilityError(eventDoc, { replay = false } = {}) {
  if (!eventDoc) {
    return null;
  }

  const eventStatus = (eventDoc.data.status || "").toLowerCase();
  if (eventStatus === "expired") {
    return replay
      ? buildMuxError("Replay window has expired", { expired: true })
      : buildMuxError("This PPV event has expired", { expired: true });
  }

  if (eventStatus === "announced" || eventStatus === "presale") {
    return replay
      ? buildMuxError("Replay is not available yet — event has not aired", {
          notStarted: true,
        })
      : buildMuxError("This PPV event has not started yet", {
          notStarted: true,
        });
  }

  if (!eventDoc.data.replayExpiry) {
    return null;
  }

  const expiryDate = toRuntimeDate(eventDoc.data.replayExpiry);
  if (expiryDate && expiryDate < new Date()) {
    return replay
      ? buildMuxError("Replay window has expired", { expired: true })
      : buildMuxError("This PPV event has expired", { expired: true });
  }

  return null;
}

async function requireMuxAccess(userId, eventId, replay = false) {
  const accessState = await getCanonicalPpvAccessState({
    db,
    userId,
    eventId,
  });

  if (accessState.hasAccess) {
    return null;
  }

  return buildMuxError(getAccessDeniedMessage(accessState.reason, replay), {
    needsPurchase: true,
    accessReason: accessState.reason,
  });
}

function buildPlaybackResponse(playbackId, stream) {
  if (stream.playbackPolicy !== "signed") {
    return {
      hlsUrl: `https://stream.mux.com/${playbackId}.m3u8`,
      thumbnailUrl: `https://image.mux.com/${playbackId}/thumbnail.webp`,
      status: stream.status,
      latencyMode: stream.latencyMode,
    };
  }

  const token = signPlaybackToken(playbackId, { expSeconds: 21600 });
  if (!token) {
    return null;
  }

  const thumbnailToken = signPlaybackToken(playbackId, {
    type: "t",
    expSeconds: 21600,
  });

  return {
    hlsUrl: `https://stream.mux.com/${playbackId}.m3u8?token=${token}`,
    thumbnailUrl: `https://image.mux.com/${playbackId}/thumbnail.webp?token=${thumbnailToken}`,
    status: stream.status,
    latencyMode: stream.latencyMode,
    expiresAt: new Date(Date.now() + 21600000).toISOString(),
  };
}

async function cacheMuxVodAsset({
  muxAssetId,
  playbackId,
  liveStreamId,
  duration,
  maxResolution,
  mp4Support,
  status,
  ppvEventId,
}) {
  await db
    .collection("mux_vod_assets")
    .doc(muxAssetId)
    .set(
      {
        muxAssetId,
        playbackId: playbackId || null,
        muxLiveStreamId: liveStreamId || null,
        duration: duration || null,
        maxResolution: maxResolution || null,
        mp4Support: mp4Support || null,
        status,
        ppvEventId: ppvEventId || null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
}

async function resolveVodPlayback(vodAssetId, resolvedPpvEventId) {
  const vodDoc = await db.collection("mux_vod_assets").doc(vodAssetId).get();
  if (vodDoc.exists) {
    return {
      playbackId: vodDoc.data().playbackId,
      duration: vodDoc.data().duration || null,
      error: null,
    };
  }

  const mux = getMuxClient();
  if (!mux) {
    return { playbackId: null, duration: null, error: "Mux not configured" };
  }

  const asset = await mux.video.assets.retrieve(vodAssetId);
  const playbackId = asset.playback_ids?.[0]?.id;

  if (playbackId) {
    await cacheMuxVodAsset({
      muxAssetId: vodAssetId,
      playbackId,
      liveStreamId: asset.live_stream_id,
      duration: asset.duration,
      maxResolution: asset.max_stored_resolution,
      mp4Support: asset.mp4_support,
      status: asset.status,
      ppvEventId: resolvedPpvEventId,
    });
  }

  return {
    playbackId,
    duration: asset.duration || null,
    error: null,
  };
}

function buildVodReplayResponse(playbackId, duration) {
  const token = signPlaybackToken(playbackId, { expSeconds: 21600 });
  const thumbnailToken = signPlaybackToken(playbackId, {
    type: "t",
    expSeconds: 21600,
  });

  return {
    hlsUrl: token
      ? `https://stream.mux.com/${playbackId}.m3u8?token=${token}`
      : `https://stream.mux.com/${playbackId}.m3u8`,
    thumbnailUrl: thumbnailToken
      ? `https://image.mux.com/${playbackId}/thumbnail.webp?token=${thumbnailToken}`
      : `https://image.mux.com/${playbackId}/thumbnail.webp`,
    duration,
    type: "vod",
  };
}

function verifyMuxWebhookRequest(req, webhookSecret) {
  if (!webhookSecret) {
    return null;
  }

  const signature = req.headers["mux-signature"];
  if (!signature) {
    console.warn("Mux webhook: missing signature header");
    return { statusCode: 401, body: "Unauthorized" };
  }

  try {
    const parts = Object.fromEntries(
      signature.split(",").map((part) => part.split("=")),
    );
    const timestamp = parts.t;
    const expectedSig = parts.v1;
    const payload = `${timestamp}.${typeof req.body === "string" ? req.body : JSON.stringify(req.body)}`;
    const computedSig = crypto
      .createHmac("sha256", webhookSecret)
      .update(payload)
      .digest("hex");

    if (computedSig !== expectedSig) {
      console.warn("Mux webhook: signature mismatch");
      return { statusCode: 401, body: "Invalid signature" };
    }

    const webhookAge = Math.abs(
      Date.now() / 1000 - Number.parseInt(timestamp, 10),
    );
    if (webhookAge > 300) {
      console.warn("Mux webhook: timestamp too old");
      return { statusCode: 401, body: "Webhook expired" };
    }

    return null;
  } catch (error) {
    console.error("Mux webhook signature verification failed:", error);
    return { statusCode: 401, body: "Signature verification error" };
  }
}

async function findMuxStreamByMuxStreamId(muxStreamId) {
  const snap = await db
    .collection("mux_streams")
    .where("muxStreamId", "==", muxStreamId)
    .limit(1)
    .get();

  return snap.empty ? null : snap.docs[0];
}

async function updateLinkedPpvEvent(ppvEventId, updates) {
  if (!ppvEventId) {
    return;
  }

  await db
    .collection("ppv_events")
    .doc(ppvEventId)
    .update(updates)
    .catch(() => {});
}

async function handleMuxStreamActive(eventData) {
  const streamDoc = await findMuxStreamByMuxStreamId(eventData.id);
  if (!streamDoc) {
    return;
  }

  await streamDoc.ref.update({
    status: "active",
    muxActiveAssetId: eventData.active_asset_id || null,
    wentLiveAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const streamData = streamDoc.data();
  await updateLinkedPpvEvent(streamData.ppvEventId, {
    streamStatus: "live",
    actualStartTime: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Stream ${eventData.id} is now LIVE`);
}

async function handleMuxStreamIdle(eventData) {
  const streamDoc = await findMuxStreamByMuxStreamId(eventData.id);
  if (!streamDoc) {
    return;
  }

  await streamDoc.ref.update({
    status: "idle",
    endedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const streamData = streamDoc.data();
  await updateLinkedPpvEvent(streamData.ppvEventId, {
    streamStatus: "ended",
  });

  console.log(`Stream ${eventData.id} is now IDLE`);
}

async function handleMuxAssetReady(eventData) {
  const muxAssetId = eventData.id;
  const playbackId = eventData.playback_ids?.[0]?.id;
  const liveStreamId = eventData.live_stream_id;

  await cacheMuxVodAsset({
    muxAssetId,
    playbackId,
    liveStreamId,
    duration: eventData.duration,
    maxResolution: eventData.max_stored_resolution,
    mp4Support: eventData.mp4_support,
    status: eventData.status,
    ppvEventId: null,
  });

  if (!liveStreamId) {
    console.log(`VOD asset ${muxAssetId} ready (playback: ${playbackId})`);
    return;
  }

  const streamDoc = await findMuxStreamByMuxStreamId(liveStreamId);
  if (!streamDoc) {
    console.log(`VOD asset ${muxAssetId} ready (playback: ${playbackId})`);
    return;
  }

  await streamDoc.ref.update({
    vodAssetId: muxAssetId,
    vodPlaybackId: playbackId || null,
    vodStatus: eventData.status,
  });

  const streamData = streamDoc.data();
  if (streamData.ppvEventId && playbackId) {
    await updateLinkedPpvEvent(streamData.ppvEventId, {
      replayUrl: `https://stream.mux.com/${playbackId}.m3u8`,
      replayPlaybackId: playbackId,
      replayAvailable: true,
      vodStatus: "ready",
      status: "replay",
    });
  }

  console.log(`VOD asset ${muxAssetId} ready (playback: ${playbackId})`);
}

async function processMuxWebhookEvent(eventType, eventData) {
  switch (eventType) {
    case "video.live_stream.active":
      await handleMuxStreamActive(eventData);
      return;
    case "video.live_stream.idle":
      await handleMuxStreamIdle(eventData);
      return;
    case "video.asset.live_stream_completed":
    case "video.asset.ready":
      await handleMuxAssetReady(eventData);
      return;
    default:
      console.log(`Mux webhook: unhandled event type ${eventType}`);
  }
}

async function resolvePromoterCredentialContext(ppvEventId) {
  const ppvDoc = await db.collection("ppv_events").doc(ppvEventId).get();
  if (!ppvDoc.exists) {
    return null;
  }

  const ppvData = ppvDoc.data() || {};
  const eventId = normalizeText(ppvData.eventId);

  let eventData = {};
  if (eventId) {
    try {
      const eventDoc = await db.collection("events").doc(eventId).get();
      if (eventDoc.exists) {
        eventData = eventDoc.data() || {};
      }
    } catch (e) {
      console.warn(
        "resolvePromoterCredentialContext event lookup failed:",
        e.message,
      );
    }
  }

  let recipientEmail =
    normalizeText(ppvData.promoterEmail) ||
    normalizeText(ppvData.contactEmail) ||
    normalizeText(eventData.promoterEmail) ||
    normalizeText(eventData.contactEmail);

  let recipientName =
    normalizeText(ppvData.promoterName) ||
    normalizeText(ppvData.promotion) ||
    normalizeText(eventData.promotionName) ||
    "Promoter";

  const promoterId =
    normalizeText(ppvData.promoterId) || normalizeText(eventData.promoterId);

  if (promoterId) {
    try {
      const userDoc = await db.collection("users").doc(promoterId).get();
      if (userDoc.exists) {
        const userData = userDoc.data() || {};
        recipientEmail = recipientEmail || normalizeText(userData.email);
        if (recipientName === "Promoter") {
          recipientName =
            normalizeText(userData.displayName) ||
            normalizeText(userData.username) ||
            recipientName;
        }
      }
    } catch (e) {
      console.warn(
        "resolvePromoterCredentialContext user lookup failed:",
        e.message,
      );
    }
  }

  return {
    recipientEmail,
    recipientName,
    eventTitle:
      normalizeText(ppvData.title) ||
      normalizeText(eventData.name) ||
      ppvEventId,
    promotionName:
      normalizeText(ppvData.promotion) ||
      normalizeText(eventData.promotionName) ||
      "Data Fight Central",
    eventDateLabel: formatCredentialEventDate(
      ppvData.eventDate || eventData.eventDate,
    ),
    locationLabel: buildLocationLabel(eventData),
  };
}

async function sendPromoterCredentialPack({
  ppvEventId,
  title,
  streamKey,
  rtmpIngestUrl,
  srtIngestUrl,
  hlsPlaybackUrl,
  playbackId,
  latencyMode,
  testMode,
}) {
  const context = await resolvePromoterCredentialContext(ppvEventId);
  if (!context) {
    return {
      status: "skipped",
      recipient: null,
      error: "PPV event not found for credential delivery",
    };
  }

  if (!sgMail) {
    return {
      status: "skipped",
      recipient: context.recipientEmail || null,
      error: "SendGrid is not configured",
    };
  }

  if (!context.recipientEmail) {
    return {
      status: "skipped",
      recipient: null,
      error: "No promoter email found for this PPV owner",
    };
  }

  const eventTitle = normalizeText(title) || context.eventTitle;
  const modeLabel = testMode ? "Rehearsal" : "Production";
  const message = [
    `Hi ${context.recipientName},`,
    "",
    `DFC has provisioned ${modeLabel.toLowerCase()} stream credentials for "${eventTitle}".`,
    "",
    `Promotion: ${context.promotionName}`,
    `Event date: ${context.eventDateLabel}`,
    `Location: ${context.locationLabel || "TBC"}`,
    `Latency mode: ${latencyMode}`,
    "",
    "Broadcast pack:",
    `- Stream key: ${streamKey}`,
    `- RTMP ingest URL: ${rtmpIngestUrl}`,
    `- SRT ingest URL: ${srtIngestUrl || "Not issued for this lane"}`,
    `- Playback ID: ${playbackId || "Pending"}`,
    `- HLS monitor URL: ${hlsPlaybackUrl || "Pending after go-live"}`,
    "",
    "Use these credentials in OBS or vMix only.",
    "Do not request, share, or forward raw Mux API keys. DFC owns and protects all platform secrets.",
    `If you need support before doors open, reply to ${FROM_EMAIL}.`,
    "",
    "Data Fight Central",
    FROM_EMAIL,
  ].join("\n");

  try {
    await sgMail.send({
      to: context.recipientEmail,
      from: { email: FROM_EMAIL, name: "Data Fight Central" },
      subject: `${modeLabel} stream credentials - ${eventTitle}`,
      text: message,
    });

    return {
      status: "sent",
      recipient: context.recipientEmail,
      error: null,
    };
  } catch (e) {
    console.error("sendPromoterCredentialPack error:", e);
    return {
      status: "failed",
      recipient: context.recipientEmail,
      error: e.message,
    };
  }
}

async function persistCredentialDeliveryState({
  streamRef,
  ppvEventId,
  credentialDelivery,
}) {
  const credentialDeliveryUpdate = {
    credentialDeliveryStatus: credentialDelivery.status,
    credentialDeliveryRecipient: credentialDelivery.recipient || null,
    credentialDeliveryError: credentialDelivery.error || null,
    credentialDeliveryUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (credentialDelivery.status === "sent") {
    credentialDeliveryUpdate.credentialDeliverySentAt =
      admin.firestore.FieldValue.serverTimestamp();
  }

  await streamRef.set(credentialDeliveryUpdate, { merge: true });

  if (ppvEventId) {
    await db
      .collection("ppv_events")
      .doc(ppvEventId)
      .set(
        {
          credentialDeliveryStatus: credentialDelivery.status,
          credentialDeliveryRecipient: credentialDelivery.recipient || null,
          credentialDeliveryError: credentialDelivery.error || null,
          credentialDeliveryUpdatedAt:
            admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      )
      .catch(() => {});
  }
}

const testMuxAuth = onCall(
  withMuxSmokeSecrets({ region: REGION }),
  async (request) => {
    const payload = request.data || {};
    const providedSmokeToken = payload.smokeToken;

    if (providedSmokeToken != null && typeof providedSmokeToken !== "string") {
      throw new HttpsError("invalid-argument", "smokeToken must be a string");
    }

    const expectedSmokeToken = resolveOptionalSmokeToken();
    if (
      expectedSmokeToken &&
      providedSmokeToken?.trim() !== expectedSmokeToken
    ) {
      throw new HttpsError("permission-denied", "Invalid smoke token");
    }

    const { tokenId, tokenSecret } = getMuxRuntimeConfig();
    if (!tokenId || !tokenSecret) {
      throw new HttpsError(
        "failed-precondition",
        "Mux runtime secrets are not configured",
      );
    }

    const mux = getMuxClient();
    if (!mux) {
      throw new HttpsError("internal", "Mux client unavailable");
    }

    try {
      const assetPage = await mux.video.assets.list({ limit: 1 });
      const assetCount = Array.isArray(assetPage?.data)
        ? assetPage.data.length
        : 0;

      return {
        auth: "ok",
        reachable: true,
        assetCount,
        timestamp: new Date().toISOString(),
      };
    } catch (error) {
      console.error(
        "testMuxAuth error:",
        error instanceof Error ? error.message : error,
      );
      throw new HttpsError("internal", "Mux auth probe failed");
    }
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// CREATE MUX LIVE STREAM
// ═══════════════════════════════════════════════════════════════════════════
//
// Creates a Mux live stream with:
//   • Low-latency mode for combat events
//   • Automatic 1080p + lower renditions
//   • Reconnect window (30s for OBS drops)
//   • Automatic MP4 support for VOD replays
//   • Signed playback (requires JWT token to watch)
//
const createMuxLiveStream = onCall(
  withMuxSecrets({ region: REGION }),
  async (request) => {
    const { ppvEventId, title, lowLatency, testMode } = request.data;
    if (!ppvEventId || !title) {
      return { error: "ppvEventId and title required" };
    }

    const mux = getMuxClient();
    if (!mux) {
      return {
        error: "Mux not configured. Set MUX_TOKEN_ID and MUX_TOKEN_SECRET.",
      };
    }

    try {
      const latencyMode = lowLatency === false ? "standard" : "low";

      // Determine playback policy
      const { signingKeyId } = getMuxRuntimeConfig();
      const useSignedPlayback = !!signingKeyId;

      const liveStream = await mux.video.liveStreams.create({
        playback_policy: [useSignedPlayback ? "signed" : "public"],
        new_asset_settings: {
          playback_policy: [useSignedPlayback ? "signed" : "public"],
          // Auto-generate MP4 for VOD replay after stream ends
          mp4_support: "standard",
        },
        // Low-latency for combat (sub-3s glass-to-glass)
        latency_mode: latencyMode,
        // Allow OBS to reconnect after network drops
        reconnect_window: 30,
        // Maximum resolution (default 1080p, promoter can upgrade to 4K)
        max_continuous_duration: 28800, // 8 hours max
        test: testMode || false,
      });

      // Extract connection details
      const streamKey = liveStream.stream_key;
      const playbackId = liveStream.playback_ids?.[0]?.id;
      const muxStreamId = liveStream.id;

      // Build RTMP ingest URL
      const rtmpIngestUrl = `rtmp://global-live.mux.com:5222/app/${streamKey}`;
      // SRT ingest (lower latency alternative)
      const srtIngestUrl = `srt://global-live.mux.com:5222?streamid=${streamKey}`;

      // Build HLS playback URL
      let hlsPlaybackUrl = `https://stream.mux.com/${playbackId}.m3u8`;
      let signedToken = null;
      if (useSignedPlayback && playbackId) {
        signedToken = signPlaybackToken(playbackId, { expSeconds: 21600 });
        hlsPlaybackUrl = `https://stream.mux.com/${playbackId}.m3u8?token=${signedToken}`;
      }

      // Persist to Firestore
      const streamRef = db.collection("mux_streams").doc();
      await streamRef.set({
        muxStreamId,
        muxPlaybackId: playbackId,
        ppvEventId,
        title,
        streamKey, // Promoter needs this for OBS
        rtmpIngestUrl,
        srtIngestUrl,
        hlsPlaybackUrl: `https://stream.mux.com/${playbackId}.m3u8`, // Unsigned base URL
        playbackPolicy: useSignedPlayback ? "signed" : "public",
        latencyMode,
        status: "idle", // idle → active → idle → disabled
        isTest: testMode || false,
        currentViewers: 0,
        peakViewers: 0,
        createdBy: request.auth?.uid || "system",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update the PPV event with stream reference
      if (ppvEventId) {
        await db
          .collection("ppv_events")
          .doc(ppvEventId)
          .update({
            muxStreamId: streamRef.id,
            muxPlaybackId: playbackId,
            streamUrl: `https://stream.mux.com/${playbackId}.m3u8`,
            streamStatus: "idle",
          })
          .catch(() => {
            // PPV doc might not exist yet — that's fine
          });
      }

      const credentialDelivery = await sendPromoterCredentialPack({
        ppvEventId,
        title,
        streamKey,
        rtmpIngestUrl,
        srtIngestUrl,
        hlsPlaybackUrl: `https://stream.mux.com/${playbackId}.m3u8`,
        playbackId,
        latencyMode,
        testMode: testMode || false,
      });

      await persistCredentialDeliveryState({
        streamRef,
        ppvEventId,
        credentialDelivery,
      });

      return {
        success: true,
        streamDocId: streamRef.id,
        muxStreamId,
        playbackId,
        streamKey,
        rtmpIngestUrl,
        srtIngestUrl,
        hlsPlaybackUrl,
        signedToken: useSignedPlayback ? signedToken : null,
        latencyMode,
        credentialDeliveryStatus: credentialDelivery.status,
        credentialDeliveryRecipient: credentialDelivery.recipient || null,
        credentialDeliveryError: credentialDelivery.error || null,
      };
    } catch (e) {
      console.error("createMuxLiveStream error:", e);
      return { error: `Mux stream creation failed: ${e.message}` };
    }
  },
);

const resendMuxCredentialPack = onCall(
  withMuxSecrets({ region: REGION }),
  async (request) => {
    const { streamDocId } = request.data;
    if (!streamDocId) {
      return { error: "streamDocId required" };
    }

    try {
      const streamRef = db.collection("mux_streams").doc(streamDocId);
      const streamDoc = await streamRef.get();
      if (!streamDoc.exists) {
        return { error: "Stream not found" };
      }

      const streamData = streamDoc.data() || {};
      if (!streamData.ppvEventId) {
        return { error: "PPV event not found for stream" };
      }

      const credentialDelivery = await sendPromoterCredentialPack({
        ppvEventId: streamData.ppvEventId,
        title: streamData.title,
        streamKey: streamData.streamKey,
        rtmpIngestUrl: streamData.rtmpIngestUrl,
        srtIngestUrl: streamData.srtIngestUrl,
        hlsPlaybackUrl: streamData.hlsPlaybackUrl,
        playbackId: streamData.muxPlaybackId,
        latencyMode: streamData.latencyMode || "low",
        testMode: Boolean(streamData.isTest),
      });

      await persistCredentialDeliveryState({
        streamRef,
        ppvEventId: streamData.ppvEventId,
        credentialDelivery,
      });

      return {
        success: credentialDelivery.status === "sent",
        credentialDeliveryStatus: credentialDelivery.status,
        credentialDeliveryRecipient: credentialDelivery.recipient || null,
        credentialDeliveryError: credentialDelivery.error || null,
      };
    } catch (e) {
      console.error("resendMuxCredentialPack error:", e);
      return { error: `Credential resend failed: ${e.message}` };
    }
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// GET SIGNED PLAYBACK URL
// ═══════════════════════════════════════════════════════════════════════════
//
// Returns a fresh JWT-signed HLS URL for an authenticated viewer.
// Called by the Flutter app after PPV purchase is verified.
//
const getMuxPlaybackUrl = onCall(
  withMuxSecrets({ region: REGION }),
  async (request) => {
    const { streamDocId, ppvEventId } = request.data;
    const userId = request.auth?.uid;
    if (!userId) return { error: "Authentication required" };
    if (!streamDocId && !ppvEventId)
      return { error: "streamDocId or ppvEventId required" };

    try {
      const { eventId: resolvedRequestedEventId } =
        await resolveRequestedEventContext(ppvEventId);
      const streamDoc = await findMuxStreamDocument({
        streamDocId,
        eventId: resolvedRequestedEventId,
        fallbackEventId: ppvEventId,
      });

      if (!streamDoc) {
        return buildMuxError("Stream not found");
      }

      const stream = streamDoc.data();
      const accessEventId = stream.ppvEventId || resolvedRequestedEventId;
      if (!accessEventId) {
        return buildMuxError("PPV event not found for stream");
      }

      const streamEvent = await resolvePpvEventDocument(db, accessEventId);
      const availabilityError = getEventAvailabilityError(streamEvent);
      if (availabilityError) {
        return availabilityError;
      }

      const accessError = await requireMuxAccess(userId, accessEventId);
      if (accessError) {
        return accessError;
      }

      const playbackId = stream.muxPlaybackId;
      if (!playbackId) return buildMuxError("Stream has no playback ID");

      const playbackResponse = buildPlaybackResponse(playbackId, stream);
      if (!playbackResponse) {
        return buildMuxError("Signing keys not configured");
      }

      return playbackResponse;
    } catch (e) {
      console.error("getMuxPlaybackUrl error:", e);
      return { error: `Failed to get playback URL: ${e.message}` };
    }
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// DISABLE / DELETE MUX STREAM
// ═══════════════════════════════════════════════════════════════════════════
const disableMuxStream = onCall(
  withMuxSecrets({ region: REGION }),
  async (request) => {
    const { streamDocId } = request.data;
    if (!streamDocId) return { error: "streamDocId required" };

    const mux = getMuxClient();
    if (!mux) return { error: "Mux not configured" };

    try {
      const streamDoc = await db
        .collection("mux_streams")
        .doc(streamDocId)
        .get();
      if (!streamDoc.exists) return { error: "Stream not found" };

      const stream = streamDoc.data();

      // Disable the Mux live stream (stops ingest, keeps asset for VOD)
      await mux.video.liveStreams.disable(stream.muxStreamId);

      await db.collection("mux_streams").doc(streamDocId).update({
        status: "disabled",
        disabledAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: true, status: "disabled" };
    } catch (e) {
      console.error("disableMuxStream error:", e);
      return { error: `Failed to disable stream: ${e.message}` };
    }
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// GET STREAM STATUS
// ═══════════════════════════════════════════════════════════════════════════
const getMuxStreamStatus = onCall(
  withMuxSecrets({ region: REGION }),
  async (request) => {
    const { streamDocId } = request.data;
    if (!streamDocId) return { error: "streamDocId required" };

    const mux = getMuxClient();
    if (!mux) return { error: "Mux not configured" };

    try {
      const streamDoc = await db
        .collection("mux_streams")
        .doc(streamDocId)
        .get();
      if (!streamDoc.exists) return { error: "Stream not found" };

      const stream = streamDoc.data();
      const muxStream = await mux.video.liveStreams.retrieve(
        stream.muxStreamId,
      );

      // Sync status back to Firestore
      const newStatus = muxStream.status; // 'idle' | 'active' | 'disabled'
      if (newStatus !== stream.status) {
        await db
          .collection("mux_streams")
          .doc(streamDocId)
          .update({
            status: newStatus,
            muxActiveAssetId: muxStream.active_asset_id || null,
          });
      }

      return {
        status: newStatus,
        activeAssetId: muxStream.active_asset_id || null,
        recentAssetIds: muxStream.recent_asset_ids || [],
        reconnectWindow: muxStream.reconnect_window,
        maxContinuousDuration: muxStream.max_continuous_duration,
      };
    } catch (e) {
      console.error("getMuxStreamStatus error:", e);
      return { error: `Failed to get stream status: ${e.message}` };
    }
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// GET VOD REPLAY (after stream ends, Mux auto-creates asset)
// ═══════════════════════════════════════════════════════════════════════════
const getMuxVodReplay = onCall(
  withMuxSecrets({ region: REGION }),
  async (request) => {
    const { ppvEventId } = request.data;
    const userId = request.auth?.uid;
    if (!userId) return { error: "Authentication required" };
    if (!ppvEventId) return { error: "ppvEventId required" };

    try {
      const { event: resolvedEvent, eventId: resolvedPpvEventId } =
        await resolveRequestedEventContext(ppvEventId);
      const availabilityError = getEventAvailabilityError(resolvedEvent, {
        replay: true,
      });
      if (availabilityError) {
        return availabilityError;
      }

      const accessError = await requireMuxAccess(
        userId,
        resolvedPpvEventId,
        true,
      );
      if (accessError) {
        return accessError;
      }

      const streamDoc = await findMuxStreamDocument({
        eventId: resolvedPpvEventId,
        fallbackEventId: ppvEventId,
      });
      if (!streamDoc) return buildMuxError("No stream found for this event");

      const stream = streamDoc.data();
      const vodAssetId = stream.vodAssetId || stream.muxActiveAssetId;
      if (!vodAssetId) return buildMuxError("VOD replay not ready yet");

      const vodPlayback = await resolveVodPlayback(
        vodAssetId,
        resolvedPpvEventId,
      );
      if (vodPlayback.error) {
        return buildMuxError(vodPlayback.error);
      }

      if (!vodPlayback.playbackId)
        return buildMuxError("Playback not available");

      return buildVodReplayResponse(
        vodPlayback.playbackId,
        vodPlayback.duration,
      );
    } catch (e) {
      console.error("getMuxVodReplay error:", e);
      return { error: `Failed to get VOD replay: ${e.message}` };
    }
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// MUX WEBHOOK HANDLER (HTTP endpoint — NOT onCall)
// ═══════════════════════════════════════════════════════════════════════════
//
// Mux sends webhooks for stream lifecycle events:
//   video.live_stream.active     → Stream went live
//   video.live_stream.idle       → Stream stopped
//   video.live_stream.connected  → OBS connected to RTMP
//   video.live_stream.disconnected → OBS disconnected
//   video.asset.live_stream_completed → VOD asset ready from live
//   video.asset.ready            → Asset transcoding complete
//
const muxWebhook = onRequest(
  withMuxSecrets({ region: REGION }),
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const { webhookSecret } = getMuxRuntimeConfig();
    const verificationError = verifyMuxWebhookRequest(req, webhookSecret);
    if (verificationError) {
      res.status(verificationError.statusCode).send(verificationError.body);
      return;
    }

    const event = req.body;
    const eventType = event?.type;
    const eventData = event?.data;

    if (!eventType || !eventData) {
      res.status(400).send("Invalid webhook payload");
      return;
    }

    console.log(
      `Mux webhook: ${eventType}`,
      JSON.stringify(eventData).substring(0, 200),
    );

    try {
      await processMuxWebhookEvent(eventType, eventData);

      res.status(200).json({ received: true });
    } catch (e) {
      console.error(`Mux webhook processing error for ${eventType}:`, e);
      res.status(500).json({ error: "Webhook processing failed" });
    }
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// EXPORTS
// ═══════════════════════════════════════════════════════════════════════════
module.exports = {
  testMuxAuth,
  createMuxLiveStream,
  resendMuxCredentialPack,
  getMuxPlaybackUrl,
  disableMuxStream,
  getMuxStreamStatus,
  getMuxVodReplay,
  muxWebhook,
};
