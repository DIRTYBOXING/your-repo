// ═══════════════════════════════════════════════════════════════════════════
// DFC LIVE PUBLISHER — WebSocket Livefeed + Auto-Recap + PPV Integration
// Facebook Live + Reddit Live Thread + TikTok Live — combined for fights.
// Real-time event updates, auto-generated recaps, inline PPV checkout.
// ═══════════════════════════════════════════════════════════════════════════

const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const fs = require("fs");
const http = require("http");
const path = require("path");
const { WebSocketServer, WebSocket } = require("ws");
const {
  initializeApp,
  cert,
  applicationDefault,
} = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const IORedis = require("ioredis");
const { v4: uuidv4 } = require("uuid");
const Stripe = require("stripe");

function loadLocalEnv() {
  const envCandidates = [
    path.resolve(process.cwd(), ".env"),
    path.resolve(__dirname, "..", ".env"),
    path.resolve(__dirname, "..", "..", "..", ".env"),
  ];

  for (const envPath of envCandidates) {
    if (!fs.existsSync(envPath)) {
      continue;
    }

    const lines = fs.readFileSync(envPath, "utf8").split(/\r?\n/);
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith("#")) {
        continue;
      }

      const separatorIndex = trimmed.indexOf("=");
      if (separatorIndex === -1) {
        continue;
      }

      const key = trimmed.slice(0, separatorIndex).trim();
      let value = trimmed.slice(separatorIndex + 1).trim();

      if (!key || process.env[key]) {
        continue;
      }

      if (
        (value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))
      ) {
        value = value.slice(1, -1);
      }

      process.env[key] = value;
    }

    return envPath;
  }

  return null;
}

const loadedEnvPath = loadLocalEnv();
if (loadedEnvPath) {
  console.log(`[env] Loaded variables from ${loadedEnvPath}`);
}

function resolveProjectId() {
  const explicitProjectId =
    process.env.GOOGLE_CLOUD_PROJECT ||
    process.env.GCLOUD_PROJECT ||
    process.env.FIREBASE_PROJECT_ID;
  if (explicitProjectId) {
    return explicitProjectId;
  }

  const storageBucket = process.env.FIREBASE_STORAGE_BUCKET || "";
  const bucketMatch = storageBucket.match(/^([^.]+)\.appspot\.com$/i);
  if (bucketMatch) {
    return bucketMatch[1];
  }

  return undefined;
}

const projectId = resolveProjectId();
if (projectId) {
  process.env.GOOGLE_CLOUD_PROJECT =
    process.env.GOOGLE_CLOUD_PROJECT || projectId;
  process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || projectId;
}

// ── Firebase Init ───────────────────────────────────────────────────────
function resolveFirebaseCredential() {
  const rawCredential = process.env.GOOGLE_APPLICATION_CREDENTIALS;

  const useDefaultCredential = () => {
    if (
      process.env.GOOGLE_APPLICATION_CREDENTIALS &&
      !fs.existsSync(process.env.GOOGLE_APPLICATION_CREDENTIALS) &&
      !process.env.GOOGLE_APPLICATION_CREDENTIALS.trim().startsWith("{")
    ) {
      delete process.env.GOOGLE_APPLICATION_CREDENTIALS;
    }
    return applicationDefault();
  };

  if (!rawCredential) {
    return useDefaultCredential();
  }

  try {
    if (rawCredential.trim().startsWith("{")) {
      return cert(JSON.parse(rawCredential));
    }

    if (fs.existsSync(rawCredential)) {
      return cert(JSON.parse(fs.readFileSync(rawCredential, "utf8")));
    }
  } catch (error) {
    console.warn(
      `[firebase] Invalid GOOGLE_APPLICATION_CREDENTIALS, falling back to application default credentials: ${error.message}`,
    );
    return useDefaultCredential();
  }

  console.warn(
    "[firebase] GOOGLE_APPLICATION_CREDENTIALS is not a valid JSON string or file path. Falling back to application default credentials.",
  );
  return useDefaultCredential();
}

initializeApp({
  credential: resolveFirebaseCredential(),
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
  projectId,
});
const db = getFirestore();
const useRedis = process.env.REDIS_REQUIRED === "true";
const localVoteCache = new Map();

function createLocalCacheClient() {
  return {
    mode: "memory",
    async get(key) {
      const entry = localVoteCache.get(key);
      if (!entry) {
        return null;
      }

      if (entry.expiresAt <= Date.now()) {
        localVoteCache.delete(key);
        return null;
      }

      return entry.value;
    },
    async set(key, value, exKeyword, ttlSeconds) {
      const expiresAt =
        exKeyword === "EX" && Number.isFinite(ttlSeconds)
          ? Date.now() + ttlSeconds * 1000
          : Number.MAX_SAFE_INTEGER;
      localVoteCache.set(key, { value, expiresAt });
      return "OK";
    },
  };
}

const redis = useRedis
  ? new IORedis(process.env.REDIS_URL || "redis://localhost:6379")
  : createLocalCacheClient();
const redisMode = useRedis ? "redis" : "memory";

// ── Stripe Init (PPV Checkout) ──────────────────────────────────────────
const allowStripeLiveMode =
  (process.env.ALLOW_STRIPE_LIVE_MODE || "").trim().toLowerCase() === "true";
const stripeSecretKey = (process.env.STRIPE_SECRET_KEY || "").trim();
const stripe = (() => {
  if (!stripeSecretKey) {
    return null;
  }

  if (
    (stripeSecretKey.startsWith("sk_live_") ||
      stripeSecretKey.startsWith("rk_live_")) &&
    !allowStripeLiveMode
  ) {
    console.error(
      "[stripe] Live mode blocked. Set ALLOW_STRIPE_LIVE_MODE=true to enable live Stripe access.",
    );
    return null;
  }

  return new Stripe(stripeSecretKey, { apiVersion: "2024-12-18.acacia" });
})();

function readLocalEventFile(eventId) {
  const eventPath = path.resolve(
    __dirname,
    "..",
    "..",
    "..",
    "data",
    "events",
    `${eventId}.json`,
  );
  if (!fs.existsSync(eventPath)) {
    return null;
  }

  const event = JSON.parse(fs.readFileSync(eventPath, "utf8"));
  const numericPrice = Number.parseFloat(event.price);

  return {
    ...event,
    ppvPriceCents: Number.isFinite(numericPrice)
      ? Math.round(numericPrice * 100)
      : undefined,
    title: event.title || event.eventTitle || "DFC PPV Event",
  };
}

async function getPpvEvent(eventId) {
  try {
    const eventDoc = await db.collection("events").doc(eventId).get();
    if (eventDoc.exists) {
      return eventDoc.data();
    }
  } catch (error) {
    console.warn(
      `[ppv/event] Firestore lookup failed for ${eventId}: ${error.message}`,
    );
  }

  return readLocalEventFile(eventId);
}

function isLocalSmokeMode() {
  return process.env.PPV_SMOKE_MODE === "true";
}

function isLocalEnvironment() {
  const nodeEnv = (process.env.NODE_ENV || "development").toLowerCase();
  return nodeEnv !== "production";
}

function isTrustedLocalValue(value) {
  return ["127.0.0.1", "::1", "localhost", "::ffff:127.0.0.1"].includes(value);
}

function isTrustedLocalRequest(req) {
  const hostHeader = String(req.get("host") || "").split(":")[0];
  const forwardedHost = String(req.headers["x-forwarded-host"] || "")
    .split(",")[0]
    .trim()
    .split(":")[0];
  const forwardedFor = String(req.headers["x-forwarded-for"] || "")
    .split(",")[0]
    .trim();
  const remoteAddress = req.socket?.remoteAddress || req.ip || "";

  return [hostHeader, forwardedHost, forwardedFor, remoteAddress].some(
    (value) => isTrustedLocalValue(value),
  );
}

function isLocalSmokeRequest(req) {
  return (
    isLocalSmokeMode() && isLocalEnvironment() && isTrustedLocalRequest(req)
  );
}

function getRequestOrigin(req) {
  const forwardedProto = String(req.headers["x-forwarded-proto"] || "")
    .split(",")[0]
    .trim();
  const protocol = forwardedProto || req.protocol || "http";
  return `${protocol}://${req.get("host")}`;
}

function buildMuxPlaybackUrl(playbackId) {
  if (!playbackId) {
    return null;
  }

  const signingKeyId = process.env.MUX_SIGNING_KEY_ID;
  const signingPrivateKeyBase64 = process.env.MUX_SIGNING_PRIVATE_KEY;
  if (!signingKeyId || !signingPrivateKeyBase64) {
    return `https://stream.mux.com/${playbackId}.m3u8`;
  }

  try {
    const jwt = require("jsonwebtoken");
    const privateKey = Buffer.from(signingPrivateKeyBase64, "base64").toString(
      "ascii",
    );
    const token = jwt.sign(
      {
        sub: playbackId,
        aud: "v",
        exp: Math.floor(Date.now() / 1000) + 21600,
        kid: signingKeyId,
      },
      privateKey,
      { algorithm: "RS256", keyid: signingKeyId },
    );

    return `https://stream.mux.com/${playbackId}.m3u8?token=${token}`;
  } catch (error) {
    console.warn(
      `[mux] Failed to sign playback URL for ${playbackId}: ${error.message}`,
    );
    return `https://stream.mux.com/${playbackId}.m3u8`;
  }
}

async function resolveReplaySource(eventId) {
  const [eventDoc, ppvEventDoc, vaultVodDoc, localEvent] = await Promise.all([
    db.collection("events").doc(eventId).get(),
    db.collection("ppv_events").doc(eventId).get(),
    db.collection("vault_vod").doc(eventId).get(),
    Promise.resolve(readLocalEventFile(eventId)),
  ]);

  const eventData = eventDoc.exists ? eventDoc.data() : null;
  const ppvEventData = ppvEventDoc.exists ? ppvEventDoc.data() : null;
  const vaultVodData = vaultVodDoc.exists ? vaultVodDoc.data() : null;

  const replayPath =
    eventData?.replayVideoPath ||
    ppvEventData?.replayVideoPath ||
    localEvent?.replayVideoPath;
  if (replayPath) {
    return { type: "storage", replayPath, source: "storage_replay_path" };
  }

  const configuredReplayUrl =
    ppvEventData?.replayUrl || eventData?.replayUrl || localEvent?.replayUrl;
  if (configuredReplayUrl) {
    return {
      type: "url",
      replayUrl: configuredReplayUrl,
      source: "configured_replay_url",
    };
  }

  const playbackId =
    ppvEventData?.replayPlaybackId ||
    ppvEventData?.muxPlaybackId ||
    eventData?.replayPlaybackId ||
    eventData?.muxPlaybackId ||
    vaultVodData?.vodPlaybackId;

  if (playbackId) {
    return {
      type: "url",
      replayUrl: buildMuxPlaybackUrl(playbackId),
      source: "mux_playback_id",
    };
  }

  const streamSnap = await db
    .collection("mux_streams")
    .where("ppvEventId", "==", eventId)
    .limit(1)
    .get();

  if (!streamSnap.empty) {
    const streamData = streamSnap.docs[0].data();
    const streamPlaybackId =
      streamData.vodPlaybackId || streamData.muxPlaybackId;
    if (streamPlaybackId) {
      return {
        type: "url",
        replayUrl: buildMuxPlaybackUrl(streamPlaybackId),
        source: "mux_stream_playback_id",
      };
    }
  }

  return null;
}

async function grantPpvAccess({ eventId, userId, sessionId, paymentIntentId }) {
  const expiresAt = new Date(Date.now() + 48 * 60 * 60 * 1000);
  const accessPayload = {
    userId,
    eventId,
    grantedAt: new Date(),
    expiresAt,
    source: "stripe_checkout",
    stripePaymentIntentId: paymentIntentId || null,
  };

  const purchasesSnap = await db
    .collection("ppv_purchases")
    .where("stripeSessionId", "==", sessionId)
    .limit(1)
    .get();

  if (!purchasesSnap.empty) {
    await purchasesSnap.docs[0].ref.update({
      eventId,
      ppvId: eventId,
      status: "completed",
      paidAt: new Date(),
      stripePaymentIntentId: paymentIntentId || null,
      accessGranted: true,
      expiresAt,
    });
  }

  await db
    .collection("ppv_access")
    .doc(`${userId}_${eventId}`)
    .set(accessPayload);
  await db
    .collection("users")
    .doc(userId)
    .collection("ppv_access")
    .doc(eventId)
    .set({
      eventId,
      grantedAt: accessPayload.grantedAt,
      expiresAt,
      source: "stripe_checkout",
      stripePaymentIntentId: paymentIntentId || null,
    });

  const canonicalCountSnap = await db
    .collection("ppv_purchases")
    .where("ppvId", "==", eventId)
    .where("status", "==", "completed")
    .count()
    .get();

  broadcastToEvent(eventId, {
    type: "ppv_purchase",
    userId,
    totalBuys: canonicalCountSnap.data().count,
  });

  return { expiresAt, totalBuys: canonicalCountSnap.data().count };
}

async function hasActiveLegacyPpvAccess({ eventId, userId }) {
  const now = new Date();

  const accessDoc = await db
    .collection("ppv_access")
    .doc(`${userId}_${eventId}`)
    .get();
  if (accessDoc.exists) {
    const accessData = accessDoc.data();
    if (!accessData.expiresAt || accessData.expiresAt.toDate() >= now) {
      return true;
    }
  }

  const nestedAccessDoc = await db
    .collection("users")
    .doc(userId)
    .collection("ppv_access")
    .doc(eventId)
    .get();
  if (nestedAccessDoc.exists) {
    const nestedAccessData = nestedAccessDoc.data();
    if (
      !nestedAccessData.expiresAt ||
      nestedAccessData.expiresAt.toDate() >= now
    ) {
      return true;
    }
  }

  const purchaseSnaps = await Promise.all([
    db
      .collection("ppv_purchases")
      .where("userId", "==", userId)
      .where("ppvId", "==", eventId)
      .where("status", "==", "completed")
      .limit(5)
      .get(),
    db
      .collection("ppv_purchases")
      .where("userId", "==", userId)
      .where("eventId", "==", eventId)
      .where("status", "==", "completed")
      .limit(5)
      .get(),
  ]);

  return purchaseSnaps.some((snapshot) =>
    snapshot.docs.some((doc) => {
      const purchaseData = doc.data();
      if (!purchaseData.expiresAt) {
        return true;
      }

      return purchaseData.expiresAt.toDate() >= now;
    }),
  );
}

// ── Express + HTTP + WS ────────────────────────────────────────────────
const app = express();
app.use(helmet());
app.use(cors({ origin: true }));
const localDemoReplayPath = path.resolve(
  __dirname,
  "..",
  "..",
  "..",
  "assets",
  "videos",
  "promo_video.mp4",
);
const jsonParser = express.json({ limit: "1mb" });
app.use((req, res, next) => {
  if (req.path === "/api/stripe/webhook") {
    return next();
  }
  return jsonParser(req, res, next);
});

app.get("/api/local-demo-replay.mp4", (req, res) => {
  if (!isLocalSmokeRequest(req) || !fs.existsSync(localDemoReplayPath)) {
    return res.status(404).json({ error: "Not found" });
  }

  return res.sendFile(localDemoReplayPath);
});

const server = http.createServer(app);
const wss = new WebSocketServer({ server, path: "/ws/live" });

// ═══════════════════════════════════════════════════════════════════════════
// CHANNEL STATE — Track active event channels and subscribers
// ═══════════════════════════════════════════════════════════════════════════
const channels = new Map(); // eventId → Set<WebSocket>

wss.on("connection", (ws, req) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const eventId = url.searchParams.get("eventId");
  const userId = url.searchParams.get("userId");

  if (!eventId) {
    ws.close(4000, "eventId query param required");
    return;
  }

  // Subscribe to event channel
  if (!channels.has(eventId)) channels.set(eventId, new Set());
  channels.get(eventId).add(ws);

  console.log(
    `[ws] ${userId || "anon"} joined event ${eventId} (${channels.get(eventId).size} viewers)`,
  );

  // Send current viewer count to all in channel
  broadcastViewerCount(eventId);

  ws.on("close", () => {
    const ch = channels.get(eventId);
    if (ch) {
      ch.delete(ws);
      if (ch.size === 0) channels.delete(eventId);
      else broadcastViewerCount(eventId);
    }
  });

  ws.on("error", () => {
    const ch = channels.get(eventId);
    if (ch) ch.delete(ws);
  });
});

function broadcastToEvent(eventId, payload) {
  const ch = channels.get(eventId);
  if (!ch) return 0;
  const msg = JSON.stringify(payload);
  let sent = 0;
  for (const ws of ch) {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(msg);
      sent++;
    }
  }
  return sent;
}

function broadcastViewerCount(eventId) {
  const count = channels.get(eventId)?.size || 0;
  broadcastToEvent(eventId, { type: "viewer_count", count });
}

function toIsoString(value) {
  if (!value) return new Date().toISOString();

  if (typeof value.toDate === "function") {
    return value.toDate().toISOString();
  }

  if (value instanceof Date) {
    return value.toISOString();
  }

  const parsed = new Date(value);
  if (!Number.isNaN(parsed.getTime())) {
    return parsed.toISOString();
  }

  return new Date().toISOString();
}

function buildCanonicalEventResponse(eventId, eventData) {
  let priceCents = 0;
  if (Number.isFinite(Number(eventData?.ppvPriceCents))) {
    priceCents = Number(eventData.ppvPriceCents);
  } else if (Number.isFinite(Number(eventData?.priceCents))) {
    priceCents = Number(eventData.priceCents);
  } else if (Number.isFinite(Number(eventData?.price))) {
    priceCents = Math.round(Number(eventData.price) * 100);
  }

  const currency = String(eventData?.currency || "USD").toUpperCase();
  const venue = {
    name: eventData?.venueName || eventData?.venue || "TBA Venue",
    city: eventData?.venueCity || eventData?.city || null,
    country: eventData?.venueCountry || eventData?.country || null,
    lat: Number.isFinite(Number(eventData?.venueLat))
      ? Number(eventData.venueLat)
      : null,
    lng: Number.isFinite(Number(eventData?.venueLng))
      ? Number(eventData.venueLng)
      : null,
  };

  const eventPathId = String(eventData?.eventId || eventId);
  const manifestPath =
    eventData?.manifestPath ||
    eventData?.hlsManifestPath ||
    eventData?.masterManifestPath ||
    `events/${eventPathId}/master.m3u8`;
  const cdnHost =
    process.env.CDN_EDGE_HOST ||
    process.env.STAGING_BASE ||
    "edge-us.cdn.dfc.example.com";
  const normalizedHost = String(cdnHost)
    .replace(/^https?:\/\//i, "")
    .replace(/\/$/, "");
  const manifestUrl =
    eventData?.manifestUrl ||
    `https://${normalizedHost}/${manifestPath.replace(/^\/+/, "")}`;

  return {
    eventId: eventPathId,
    title: eventData?.title || eventData?.eventTitle || "DFC PPV Event",
    posterUrl: eventData?.posterUrl || eventData?.imageUrl || "",
    price: Number((priceCents / 100).toFixed(2)),
    currency,
    entitlementRequired: true,
    status: eventData?.status || "announced",
    venue,
    playback: {
      manifestUrl,
      protocols: ["hls", "dash", "cmaf"],
      cdnHost: normalizedHost,
    },
    updatedAt: toIsoString(
      eventData?.updatedAt || eventData?.lastUpdated || eventData?.createdAt,
    ),
  };
}

async function loadCanonicalEventRecord(eventId) {
  const [eventsDoc, ppvDoc] = await Promise.all([
    db.collection("events").doc(eventId).get(),
    db.collection("ppv_events").doc(eventId).get(),
  ]);

  if (eventsDoc.exists) {
    return eventsDoc.data();
  }

  if (ppvDoc.exists) {
    return ppvDoc.data();
  }

  return readLocalEventFile(eventId);
}

// ═══════════════════════════════════════════════════════════════════════════
// HEALTH & STATUS
// ═══════════════════════════════════════════════════════════════════════════
app.get("/health", (_, res) =>
  res.json({
    status: "ok",
    service: "dfc-live-publisher",
    cache: redisMode,
    smokeMode: isLocalSmokeMode() && isLocalEnvironment(),
    activeChannels: channels.size,
    totalViewers: Array.from(channels.values()).reduce(
      (sum, ch) => sum + ch.size,
      0,
    ),
  }),
);

// Canonical event payload for page truth.
// GET /api/events/:id
app.get("/api/events/:id", async (req, res) => {
  try {
    const eventId = req.params.id;
    if (!eventId) {
      return res.status(400).json({ error: "event id required" });
    }

    const eventRecord = await loadCanonicalEventRecord(eventId);
    if (!eventRecord) {
      return res.status(404).json({ error: "Event not found" });
    }

    return res.json(buildCanonicalEventResponse(eventId, eventRecord));
  } catch (error) {
    console.error(
      `[events] Failed to resolve canonical event payload: ${error.message}`,
    );
    return res.status(500).json({ error: "Failed to fetch event" });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// POST /api/events/:id/live — Publish a live update (round-by-round, etc.)
// This is the promoter/journalist endpoint — every update goes to all fans.
// ═══════════════════════════════════════════════════════════════════════════
app.post("/api/events/:id/live", async (req, res) => {
  try {
    const eventId = req.params.id;
    const { text, authorId, authorName, updateType, metadata } = req.body;

    if (!text) return res.status(400).json({ error: "text is required" });

    // ── Valid update types (like Reddit flair + Facebook post types) ──
    const validTypes = [
      "round_update", // Round-by-round commentary
      "result", // Fight result (KO, TKO, Decision, etc.)
      "walkout", // Fighter entrance
      "stats", // Round stats
      "breaking", // Breaking news during event
      "quote", // Interview/ringside quote
      "injury", // Medical stoppage or injury
      "controversy", // Controversial decision/moment
      "ppv_promo", // PPV buy CTA
      "sponsor", // Sponsor message
      "prediction", // AI/coach prediction
      "fan_poll", // Live fan poll
      "highlight", // Highlight clip link
    ];

    const type = validTypes.includes(updateType) ? updateType : "round_update";

    // ── Save to Firestore ───────────────────────────────────────────
    const update = {
      eventId,
      text,
      authorId: authorId || "system",
      authorName: authorName || "DFC Live",
      updateType: type,
      metadata: metadata || {},
      timestamp: FieldValue.serverTimestamp(),
      sequence: Date.now(), // For ordering
    };

    const docRef = await db.collection("live_updates").add(update);

    // ── Broadcast to WebSocket subscribers ──────────────────────────
    const sent = broadcastToEvent(eventId, {
      type: "live_update",
      id: docRef.id,
      ...update,
      timestamp: new Date().toISOString(),
    });

    // ── Increment update count on event ─────────────────────────────
    await db
      .collection("events")
      .doc(eventId)
      .update({
        liveUpdateCount: FieldValue.increment(1),
        lastLiveUpdate: FieldValue.serverTimestamp(),
        isLive: true,
      })
      .catch(() => {});

    console.log(`[live] Update for event ${eventId} → ${sent} viewers`);

    return res.status(202).json({
      status: "published",
      updateId: docRef.id,
      viewersReached: sent,
    });
  } catch (err) {
    console.error("[live] Error:", err);
    return res.status(500).json({ error: "Failed to publish live update" });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// POST /api/events/:id/end — End live event + trigger auto-recap
// ═══════════════════════════════════════════════════════════════════════════
app.post("/api/events/:id/end", async (req, res) => {
  try {
    const eventId = req.params.id;
    const { mainResult, eventTitle } = req.body;

    // ── Mark event as ended ─────────────────────────────────────────
    await db
      .collection("events")
      .doc(eventId)
      .update({
        isLive: false,
        endedAt: FieldValue.serverTimestamp(),
        mainResult: mainResult || null,
      })
      .catch(() => {});

    // ── Fetch all live updates for this event ───────────────────────
    const updatesSnap = await db
      .collection("live_updates")
      .where("eventId", "==", eventId)
      .orderBy("sequence", "asc")
      .get();

    const updates = updatesSnap.docs.map((d) => d.data());

    // ── Auto-generate recap article ─────────────────────────────────
    const recap = generateRecap(eventTitle || eventId, updates, mainResult);

    const articleRef = await db.collection("feed_content").add({
      title: recap.title,
      body: recap.body,
      category: "recap",
      eventId,
      authorId: "system",
      authorName: "DFC Auto-Recap",
      status: "published",
      featured: true,
      sourceType: "auto_recap",
      tags: ["recap", "results", "live"],
      publishedAt: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
    });

    // ── Notify channel ──────────────────────────────────────────────
    broadcastToEvent(eventId, {
      type: "event_ended",
      mainResult,
      recapArticleId: articleRef.id,
    });

    console.log(
      `[live] Event ${eventId} ended — recap article ${articleRef.id}`,
    );

    return res.json({
      status: "ended",
      recapArticleId: articleRef.id,
      updatesCount: updates.length,
    });
  } catch (err) {
    console.error("[live/end] Error:", err);
    return res.status(500).json({ error: "Failed to end event" });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// GET /api/events/:id/live — Fetch live update history (REST fallback)
// ═══════════════════════════════════════════════════════════════════════════
app.get("/api/events/:id/live", async (req, res) => {
  try {
    const eventId = req.params.id;
    const limit = Math.min(parseInt(req.query.limit) || 50, 200);
    const after = req.query.after; // sequence number for pagination

    let query = db
      .collection("live_updates")
      .where("eventId", "==", eventId)
      .orderBy("sequence", "desc")
      .limit(limit);

    if (after) query = query.where("sequence", "<", parseInt(after));

    const snap = await query.get();
    const updates = snap.docs.map((d) => ({ id: d.id, ...d.data() }));

    return res.json({
      eventId,
      updates,
      count: updates.length,
      viewerCount: channels.get(eventId)?.size || 0,
    });
  } catch (err) {
    return res.status(500).json({ error: "Failed to fetch updates" });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// POST /api/events/:id/poll — Create a live fan poll (like Instagram polls)
// ═══════════════════════════════════════════════════════════════════════════
app.post("/api/events/:id/poll", async (req, res) => {
  try {
    const eventId = req.params.id;
    const { question, options, durationSeconds = 120 } = req.body;

    if (!question || !options || options.length < 2) {
      return res
        .status(400)
        .json({ error: "question and at least 2 options required" });
    }

    const pollId = uuidv4();
    const poll = {
      pollId,
      eventId,
      question,
      options: options.map((o) => ({ text: o, votes: 0 })),
      expiresAt: new Date(Date.now() + durationSeconds * 1000),
      createdAt: new Date(),
      status: "active",
    };

    await db.collection("live_polls").doc(pollId).set(poll);

    broadcastToEvent(eventId, { type: "poll", ...poll });

    // Auto-close poll after duration
    setTimeout(async () => {
      const pollDoc = await db.collection("live_polls").doc(pollId).get();
      if (pollDoc.exists && pollDoc.data().status === "active") {
        await db
          .collection("live_polls")
          .doc(pollId)
          .update({ status: "closed" });
        broadcastToEvent(eventId, {
          type: "poll_closed",
          pollId,
          results: pollDoc.data().options,
        });
      }
    }, durationSeconds * 1000);

    return res.json({ status: "created", pollId });
  } catch (err) {
    return res.status(500).json({ error: "Failed to create poll" });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// POST /api/events/:id/poll/:pollId/vote — Vote on a live poll
// ═══════════════════════════════════════════════════════════════════════════
app.post("/api/events/:id/poll/:pollId/vote", async (req, res) => {
  try {
    const { pollId } = req.params;
    const { optionIndex, userId } = req.body;

    if (optionIndex === undefined || !userId) {
      return res.status(400).json({ error: "optionIndex and userId required" });
    }

    // Check if user already voted (stored in Redis for speed)
    const voteKey = `poll:${pollId}:${userId}`;
    const alreadyVoted = await redis.get(voteKey);
    if (alreadyVoted) return res.status(409).json({ error: "Already voted" });

    const pollRef = db.collection("live_polls").doc(pollId);
    const pollDoc = await pollRef.get();
    if (!pollDoc.exists || pollDoc.data().status !== "active") {
      return res.status(410).json({ error: "Poll is closed" });
    }

    // Increment vote
    const options = pollDoc.data().options;
    if (optionIndex < 0 || optionIndex >= options.length) {
      return res.status(400).json({ error: "Invalid option index" });
    }
    options[optionIndex].votes++;
    await pollRef.update({ options });
    await redis.set(voteKey, "1", "EX", 86400);

    broadcastToEvent(req.params.id, {
      type: "poll_update",
      pollId,
      options,
    });

    return res.json({ status: "voted" });
  } catch (err) {
    return res.status(500).json({ error: "Vote failed" });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// POST /api/events/:id/ppv/checkout — One-tap PPV checkout (Stripe)
// ═══════════════════════════════════════════════════════════════════════════
app.post("/api/events/:id/ppv/checkout", async (req, res) => {
  try {
    if (!stripe)
      return res.status(503).json({ error: "Stripe not configured" });

    const eventId = req.params.id;
    const { userId, email, successUrl, cancelUrl } = req.body;

    if (!userId || !email) {
      return res.status(400).json({ error: "userId and email required" });
    }

    const event = await getPpvEvent(eventId);
    if (!event) return res.status(404).json({ error: "Event not found" });

    const priceInCents = event.ppvPriceCents || 4999; // default $49.99
    const eventTitle = event.title || "DFC PPV Event";

    if (await hasActiveLegacyPpvAccess({ eventId, userId })) {
      return res.json({ status: "already_purchased", accessGranted: true });
    }

    // Create Stripe Checkout Session
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ["card"],
      customer_email: email,
      line_items: [
        {
          price_data: {
            currency: "usd",
            product_data: {
              name: `PPV: ${eventTitle}`,
              description: `Live stream + 48hr replay access`,
              metadata: { eventId },
            },
            unit_amount: priceInCents,
          },
          quantity: 1,
        },
      ],
      mode: "payment",
      success_url:
        successUrl ||
        `https://datafightcentral.com/ppv/${eventId}/watch?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: cancelUrl || `https://datafightcentral.com/ppv/${eventId}`,
      metadata: { eventId, userId },
    });

    // Record pending purchase
    await db.collection("ppv_purchases").add({
      userId,
      eventId,
      ppvId: eventId,
      stripeSessionId: session.id,
      status: "pending",
      accessGranted: false,
      amount: priceInCents,
      createdAt: new Date(),
    });

    return res.json({
      status: "checkout_created",
      checkoutUrl: session.url,
      sessionId: session.id,
    });
  } catch (err) {
    console.error("[ppv/checkout] Error:", err);
    const response = { error: "Checkout failed" };
    if (process.env.NODE_ENV !== "production") {
      response.detail = err.message;
    }
    return res.status(500).json(response);
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// POST /api/stripe/webhook — Stripe webhook for PPV payment confirmation
// ═══════════════════════════════════════════════════════════════════════════
app.post(
  "/api/stripe/webhook",
  express.raw({ type: "application/json" }),
  async (req, res) => {
    try {
      if (!stripe) return res.status(503).send();

      const sig = req.headers["stripe-signature"];
      const webhookSecret = isLocalSmokeRequest(req)
        ? process.env.STRIPE_WEBHOOK_SECRET_LOCAL ||
          process.env.STRIPE_WEBHOOK_SECRET
        : process.env.STRIPE_WEBHOOK_SECRET;
      let event;

      if (webhookSecret && sig) {
        event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
      } else {
        event = req.body;
      }

      if (event.type === "checkout.session.completed") {
        const session = event.data.object;
        const { eventId, userId } = session.metadata;
        await grantPpvAccess({
          eventId,
          userId,
          sessionId: session.id,
          paymentIntentId: session.payment_intent || null,
        });

        console.log(
          `[ppv] Purchase completed: user ${userId}, event ${eventId}`,
        );
      }

      res.json({ received: true });
    } catch (err) {
      console.error("[stripe/webhook] Error:", err.message);
      res.status(400).send(`Webhook error: ${err.message}`);
    }
  },
);

app.post("/api/events/:id/ppv/smoke-complete", async (req, res) => {
  try {
    if (!isLocalSmokeRequest(req)) {
      return res.status(404).json({ error: "Not found" });
    }

    const eventId = req.params.id;
    const { userId, sessionId } = req.body || {};
    if (!userId || !sessionId) {
      return res.status(400).json({ error: "userId and sessionId required" });
    }

    await grantPpvAccess({
      eventId,
      userId,
      sessionId,
      paymentIntentId: "smoke_payment_intent",
    });
    return res.json({ status: "smoke_completed", eventId, userId });
  } catch (err) {
    console.error("[ppv/smoke-complete] Error:", err);
    return res
      .status(500)
      .json({ error: "Smoke completion failed", detail: err.message });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// GET /api/events/:id/ppv/access — Check if user has PPV access
// ═══════════════════════════════════════════════════════════════════════════
app.get("/api/events/:id/ppv/access", async (req, res) => {
  try {
    const eventId = req.params.id;
    const userId = req.query.userId;
    if (!userId)
      return res.status(400).json({ error: "userId query param required" });

    let accessDoc = await db
      .collection("ppv_access")
      .doc(`${userId}_${eventId}`)
      .get();
    let data = accessDoc.exists ? accessDoc.data() : null;

    if (!accessDoc.exists) {
      accessDoc = await db
        .collection("users")
        .doc(userId)
        .collection("ppv_access")
        .doc(eventId)
        .get();
      data = accessDoc.exists ? accessDoc.data() : null;
    }

    if (!accessDoc.exists || !data) {
      return res.json({ hasAccess: false });
    }

    const now = new Date();
    const expired = data.expiresAt && data.expiresAt.toDate() < now;

    return res.json({
      hasAccess: !expired,
      expired,
      grantedAt: data.grantedAt,
      expiresAt: data.expiresAt,
    });
  } catch (err) {
    return res.status(500).json({ error: "Access check failed" });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// GET /api/events/:id/replay — Signed replay URL (48hr window)
// ═══════════════════════════════════════════════════════════════════════════
app.get("/api/events/:id/replay", async (req, res) => {
  try {
    const eventId = req.params.id;
    const userId = req.query.userId;
    if (!userId) return res.status(400).json({ error: "userId required" });

    // Verify access
    let accessDoc = await db
      .collection("ppv_access")
      .doc(`${userId}_${eventId}`)
      .get();
    let data = accessDoc.exists ? accessDoc.data() : null;

    if (!accessDoc.exists) {
      accessDoc = await db
        .collection("users")
        .doc(userId)
        .collection("ppv_access")
        .doc(eventId)
        .get();
      data = accessDoc.exists ? accessDoc.data() : null;
    }

    if (!accessDoc.exists || !data) {
      return res
        .status(403)
        .json({ error: "No PPV access — purchase required" });
    }

    if (data.expiresAt && data.expiresAt.toDate() < new Date()) {
      return res
        .status(403)
        .json({ error: "PPV replay window expired (48hrs)" });
    }

    const replaySource = await resolveReplaySource(eventId);

    if (replaySource?.type === "url") {
      return res.json({
        replayUrl: replaySource.replayUrl,
        expiresIn: 3600,
        source: replaySource.source,
      });
    }

    if (replaySource?.type === "storage") {
      const { getStorage } = require("firebase-admin/storage");
      const bucket = getStorage().bucket();
      const [signedUrl] = await bucket
        .file(replaySource.replayPath)
        .getSignedUrl({
          version: "v4",
          action: "read",
          expires: Date.now() + 60 * 60 * 1000,
        });

      return res.json({
        replayUrl: signedUrl,
        expiresIn: 3600,
        source: replaySource.source,
      });
    }

    if (isLocalSmokeRequest(req) && fs.existsSync(localDemoReplayPath)) {
      return res.json({
        replayUrl: `${getRequestOrigin(req)}/api/local-demo-replay.mp4`,
        expiresIn: 3600,
        source: "local_demo_asset",
      });
    }

    return res.status(404).json({ error: "Replay not yet available" });
  } catch (err) {
    console.error("[replay] Error:", err);
    return res.status(500).json({ error: "Replay URL generation failed" });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// AUTO-RECAP GENERATOR
// Converts live bullets into a polished article (like Reddit post summaries)
// ═══════════════════════════════════════════════════════════════════════════
function generateRecap(eventTitle, updates, mainResult) {
  const results = updates.filter((u) => u.updateType === "result");
  const rounds = updates.filter((u) => u.updateType === "round_update");
  const quotes = updates.filter((u) => u.updateType === "quote");
  const highlights = updates.filter((u) => u.updateType === "highlight");

  let body = "";

  // Lede
  if (mainResult) {
    body += `${mainResult}\n\n`;
  }
  body += `${eventTitle} delivered ${updates.length} moments of action. `;
  body += `Here's everything that happened.\n\n`;

  // Results section
  if (results.length > 0) {
    body += `## Results\n\n`;
    results.forEach((r) => {
      body += `- ${r.text}\n`;
    });
    body += "\n";
  }

  // Key rounds
  if (rounds.length > 0) {
    body += `## Round-by-Round Highlights\n\n`;
    rounds.slice(-10).forEach((r) => {
      body += `${r.text}\n\n`;
    });
  }

  // Quotes
  if (quotes.length > 0) {
    body += `## Quotes\n\n`;
    quotes.forEach((q) => {
      body += `> "${q.text}" — ${q.authorName || "Ringside"}\n\n`;
    });
  }

  // CTA
  body += `---\n\n`;
  body += `Watch the replay and full highlights on Data Fight Central.\n`;

  return {
    title: mainResult
      ? `${eventTitle} Results: ${mainResult}`
      : `${eventTitle} — Full Results & Recap`,
    body,
  };
}

// ── Start Server ────────────────────────────────────────────────────────
const PORT = process.env.PORT || 4003;
server.listen(PORT, () => {
  console.log(`📡 DFC Live Publisher running on port ${PORT}`);
  console.log(`   WebSocket: ws://localhost:${PORT}/ws/live?eventId=xxx`);
  console.log(`   REST API:  http://localhost:${PORT}/api/events/:id/live`);
});
