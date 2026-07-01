// ═══════════════════════════════════════════════════════════════════════════
// DFC UPLOAD SERVICE — Firebase Storage Presigned URLs
// Small promoter weapon: upload directly to CDN, no server bottleneck.
// Beats Facebook's upload pipeline — chunked, resumable, validated.
// ═══════════════════════════════════════════════════════════════════════════

const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const { initializeApp, cert } = require("firebase-admin/app");
const { getStorage } = require("firebase-admin/storage");
const { getFirestore } = require("firebase-admin/firestore");
const { v4: uuidv4 } = require("uuid");
const { Queue } = require("bullmq");
const IORedis = require("ioredis");

// ── Firebase Init ───────────────────────────────────────────────────────
initializeApp({
  credential: cert(process.env.GOOGLE_APPLICATION_CREDENTIALS),
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
});

const storage = getStorage();
const bucket = storage.bucket();
const db = getFirestore();
const redis = new IORedis(process.env.REDIS_URL || "redis://localhost:6379");

// ── Job Queues ──────────────────────────────────────────────────────────
const transcodeQueue = new Queue("video-transcode", { connection: redis });
const imagegenQueue = new Queue("imagegen", { connection: redis });

// ── Config ──────────────────────────────────────────────────────────────
const MAX_IMAGE_SIZE =
  (parseInt(process.env.MAX_IMAGE_SIZE_MB) || 25) * 1024 * 1024;
const MAX_VIDEO_SIZE =
  (parseInt(process.env.MAX_VIDEO_SIZE_MB) || 500) * 1024 * 1024;
const ALLOWED_IMAGE_TYPES = (
  process.env.ALLOWED_IMAGE_TYPES || "image/jpeg,image/png,image/webp"
).split(",");
const ALLOWED_VIDEO_TYPES = (
  process.env.ALLOWED_VIDEO_TYPES || "video/mp4,video/quicktime,video/webm"
).split(",");

// Tier upload limits per day
const TIER_LIMITS = {
  free: { images: 1, videos: 0, maxFileMB: 5 },
  fighter_free: { images: 3, videos: 1, maxFileMB: 25 },
  fighter_pro: { images: 10, videos: 5, maxFileMB: 100 },
  promoter_basic: { images: 25, videos: 10, maxFileMB: 250 },
  promoter_pro: { images: 100, videos: 50, maxFileMB: 500 },
  gym_pro: { images: 50, videos: 20, maxFileMB: 250 },
  enterprise: { images: 999, videos: 999, maxFileMB: 500 },
  admin: { images: 999, videos: 999, maxFileMB: 500 },
};

// ── Express App ─────────────────────────────────────────────────────────
const app = express();
app.use(helmet());
app.use(cors({ origin: true }));
app.use(express.json({ limit: "1mb" }));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

// ── Health Check ────────────────────────────────────────────────────────
app.get("/health", (_, res) =>
  res.json({ status: "ok", service: "dfc-upload" }),
);

// ═══════════════════════════════════════════════════════════════════════════
// POST /api/upload/presign — Get a signed upload URL
// Client uploads DIRECTLY to Firebase Storage (no server bottleneck)
// ═══════════════════════════════════════════════════════════════════════════
app.post("/api/upload/presign", async (req, res) => {
  try {
    const { filename, contentType, fileSizeBytes, userId, userTier, purpose } =
      req.body;

    // ── Validate required fields ────────────────────────────────────
    if (!filename || !contentType || !userId) {
      return res
        .status(400)
        .json({ error: "filename, contentType, and userId are required" });
    }

    // ── Determine media type ────────────────────────────────────────
    const isImage = ALLOWED_IMAGE_TYPES.includes(contentType);
    const isVideo = ALLOWED_VIDEO_TYPES.includes(contentType);
    if (!isImage && !isVideo) {
      return res.status(400).json({
        error: "Unsupported file type",
        allowed: [...ALLOWED_IMAGE_TYPES, ...ALLOWED_VIDEO_TYPES],
      });
    }

    // ── Enforce tier limits ─────────────────────────────────────────
    const tier = TIER_LIMITS[userTier] || TIER_LIMITS.free;
    const maxSize = tier.maxFileMB * 1024 * 1024;
    if (fileSizeBytes && fileSizeBytes > maxSize) {
      return res.status(413).json({
        error: `File too large for ${userTier || "free"} tier`,
        maxMB: tier.maxFileMB,
      });
    }
    if (fileSizeBytes && isImage && fileSizeBytes > MAX_IMAGE_SIZE) {
      return res.status(413).json({
        error: "Image exceeds maximum size",
        maxMB: MAX_IMAGE_SIZE / 1024 / 1024,
      });
    }
    if (fileSizeBytes && isVideo && fileSizeBytes > MAX_VIDEO_SIZE) {
      return res.status(413).json({
        error: "Video exceeds maximum size",
        maxMB: MAX_VIDEO_SIZE / 1024 / 1024,
      });
    }

    // ── Check daily upload count ────────────────────────────────────
    const today = new Date().toISOString().split("T")[0];
    const dailyKey = `uploads:${userId}:${today}`;
    const mediaKey = isVideo ? "videos" : "images";
    const currentCount = parseInt(
      (await redis.hget(dailyKey, mediaKey)) || "0",
    );
    const limit = isVideo ? tier.videos : tier.images;

    if (currentCount >= limit) {
      return res.status(429).json({
        error: `Daily ${mediaKey} upload limit reached`,
        limit,
        current: currentCount,
        tier: userTier || "free",
      });
    }

    // ── Generate signed URL ─────────────────────────────────────────
    const ext = filename.split(".").pop()?.toLowerCase() || "bin";
    const safeFilename = filename.replace(/[^a-zA-Z0-9._-]/g, "_");
    const storagePath = `uploads/${userId}/${today}/${uuidv4()}_${safeFilename}`;

    const file = bucket.file(storagePath);
    const [signedUrl] = await file.getSignedUrl({
      version: "v4",
      action: "write",
      expires: Date.now() + 15 * 60 * 1000, // 15 minutes
      contentType,
    });

    // ── Create upload record in Firestore ───────────────────────────
    const uploadDoc = await db.collection("media_uploads").add({
      userId,
      filename: safeFilename,
      storagePath,
      contentType,
      mediaType: isVideo ? "video" : "image",
      fileSizeBytes: fileSizeBytes || null,
      purpose: purpose || "general",
      status: "pending", // pending → uploaded → processing → ready → failed
      tier: userTier || "free",
      createdAt: new Date(),
      publicUrl: null,
      thumbnailUrl: null,
      variants: {},
    });

    // ── Increment daily counter ─────────────────────────────────────
    await redis.hincrby(dailyKey, mediaKey, 1);
    await redis.expire(dailyKey, 86400);

    return res.json({
      uploadId: uploadDoc.id,
      signedUrl,
      storagePath,
      expiresIn: 900,
      mediaType: isVideo ? "video" : "image",
    });
  } catch (err) {
    console.error("[upload/presign] Error:", err);
    return res.status(500).json({ error: "Failed to generate upload URL" });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// POST /api/upload/confirm — Client confirms upload complete
// Triggers transcoding for video, thumbnail gen for images
// ═══════════════════════════════════════════════════════════════════════════
app.post("/api/upload/confirm", async (req, res) => {
  try {
    const { uploadId, userId } = req.body;
    if (!uploadId || !userId) {
      return res.status(400).json({ error: "uploadId and userId required" });
    }

    const docRef = db.collection("media_uploads").doc(uploadId);
    const doc = await docRef.get();
    if (!doc.exists) return res.status(404).json({ error: "Upload not found" });

    const data = doc.data();
    if (data.userId !== userId)
      return res.status(403).json({ error: "Not your upload" });

    // ── Generate public URL ─────────────────────────────────────────
    const file = bucket.file(data.storagePath);
    await file.makePublic();
    const publicUrl = `https://storage.googleapis.com/${bucket.name}/${data.storagePath}`;

    await docRef.update({
      status: "uploaded",
      publicUrl,
      uploadedAt: new Date(),
    });

    // ── Enqueue post-processing jobs ────────────────────────────────
    if (data.mediaType === "video") {
      await transcodeQueue.add(
        "transcode",
        {
          uploadId,
          storagePath: data.storagePath,
          contentType: data.contentType,
          userId,
        },
        { attempts: 3, backoff: { type: "exponential", delay: 5000 } },
      );

      await docRef.update({ status: "processing" });
    }

    if (data.mediaType === "image") {
      // Auto-generate social card variants
      await imagegenQueue.add(
        "thumbnails",
        {
          uploadId,
          storagePath: data.storagePath,
          publicUrl,
          userId,
        },
        { attempts: 2, backoff: { type: "exponential", delay: 3000 } },
      );

      await docRef.update({ status: "ready" }); // Images are ready immediately
    }

    return res.json({
      status: "confirmed",
      uploadId,
      publicUrl,
      processing: data.mediaType === "video",
    });
  } catch (err) {
    console.error("[upload/confirm] Error:", err);
    return res.status(500).json({ error: "Failed to confirm upload" });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// GET /api/upload/status/:id — Check upload + processing status
// ═══════════════════════════════════════════════════════════════════════════
app.get("/api/upload/status/:id", async (req, res) => {
  try {
    const doc = await db.collection("media_uploads").doc(req.params.id).get();
    if (!doc.exists) return res.status(404).json({ error: "Not found" });

    const data = doc.data();
    return res.json({
      uploadId: doc.id,
      status: data.status,
      mediaType: data.mediaType,
      publicUrl: data.publicUrl,
      thumbnailUrl: data.thumbnailUrl,
      variants: data.variants || {},
      createdAt: data.createdAt,
    });
  } catch (err) {
    return res.status(500).json({ error: "Failed to get status" });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// CREATOR TOOLKIT — Onboarding kit + caption packs + upload specs
// ═══════════════════════════════════════════════════════════════════════════

const CAPTION_PACKS = {
  ppv_promo: [
    "Live PPV — {event} tonight. One tap to buy.",
    "Who's next? Watch the finish live on DFC.",
    "Neural Coach had this fight at {probability}% — see why.",
    "{creator} goes live with exclusive warmups — PPV bundle available.",
    "Missed it? Replay available now — buy the main event.",
    "Limited replays sold — grab yours before they close.",
  ],
  hype: [
    "This one is PERSONAL. {fighter1} vs {fighter2} — {date}.",
    "The biggest card in {promotion} history. Don't miss it.",
    "Training camp footage you won't see anywhere else.",
    "Behind the scenes at {location} — fight week starts NOW.",
  ],
  post_fight: [
    "That was INSANE. Full recap dropping shortly.",
    "{winner} just shocked the world. Full breakdown inside.",
    "Round {round} finish — did you call it?",
    "The stats don't lie. See the complete breakdown.",
  ],
  creator_intro: [
    "New to DFC? Here's what I bring to the table.",
    "Follow for daily combat content — news, analysis, predictions.",
    "Gym life + fight content every day. Let's build this.",
  ],
};

const UPLOAD_SPECS = {
  highlight_clip: {
    format: "MP4 (H.264)",
    duration: "30–90 seconds",
    resolution: "1080×1920 (vertical) or 1920×1080 (landscape)",
    maxSize: "100MB",
    tips: "Best moments only. Start with the hook. No dead air.",
  },
  full_fight: {
    format: "MP4 (H.264)",
    duration: "Up to 45 minutes",
    resolution: "1920×1080 minimum",
    maxSize: "500MB",
    tips: "Include intros and walkouts for atmosphere.",
  },
  training_clip: {
    format: "MP4 (H.264)",
    duration: "15–60 seconds",
    resolution: "Any (vertical preferred)",
    maxSize: "50MB",
    tips: "Good lighting. Show technique clearly. Add music post-upload.",
  },
  photo: {
    format: "JPEG/PNG/WebP",
    resolution: "2048×2048 recommended",
    maxSize: "25MB",
    tips: "High contrast, good lighting. Avoid busy backgrounds.",
  },
  story: {
    format: "MP4 or Image",
    resolution: "1080×1920",
    maxSize: "25MB",
    tips: "Vertical only. Add text overlays for engagement.",
  },
};

// GET /api/creator/toolkit — Full onboarding kit
app.get("/api/creator/toolkit", (req, res) => {
  res.json({
    uploadSpecs: UPLOAD_SPECS,
    captionPacks: CAPTION_PACKS,
    quickTips: [
      "Shoot vertical (9:16) for maximum feed engagement",
      "First 3 seconds matter — start with the hook",
      "Post at 6pm local time for peak engagement",
      "Use 3–5 hashtags: #DFC #CombatSports + sport-specific",
      "Reply to every comment for first 30 minutes",
      'Cross-post your DFC content to Instagram/TikTok with a "full version on DFC" CTA',
    ],
    revenueInfo: {
      ppvSplit: "70/30 (creator keeps 70%) for first 90 days",
      payoutSchedule: "Weekly for first month, then bi-weekly",
      minimumPayout: "$25 USD",
      bonuses: "Top 10 creators get guaranteed minimums + paid ad support",
    },
  });
});

// GET /api/creator/captions/:pack — Get caption templates for a pack
app.get("/api/creator/captions/:pack", (req, res) => {
  const pack = CAPTION_PACKS[req.params.pack];
  if (!pack) {
    return res
      .status(404)
      .json({ error: "Unknown pack", available: Object.keys(CAPTION_PACKS) });
  }
  return res.json({ pack: req.params.pack, captions: pack });
});

// POST /api/creator/captions/fill — Fill template variables
app.post("/api/creator/captions/fill", (req, res) => {
  const { pack: packName, variables } = req.body;
  const pack = CAPTION_PACKS[packName];
  if (!pack) {
    return res
      .status(404)
      .json({ error: "Unknown pack", available: Object.keys(CAPTION_PACKS) });
  }

  const filled = pack.map((template) => {
    let result = template;
    for (const [key, value] of Object.entries(variables || {})) {
      result = result.replace(new RegExp(`\\{${key}\\}`, "g"), value);
    }
    return result;
  });

  return res.json({ pack: packName, captions: filled });
});

// ═══════════════════════════════════════════════════════════════════════════
// POST /api/upload/moderate — Content moderation & flagging
// Keyword flagging, age-gating, rights confirmation.
// ═══════════════════════════════════════════════════════════════════════════
const FLAGGED_KEYWORDS = {
  medical: [
    "concussion",
    "tbi",
    "brain damage",
    "death",
    "coma",
    "cardiac arrest",
  ],
  defamation: ["fraud", "scam", "steroids confirmed", "rigged", "fixed fight"],
  copyright: ["ppv rip", "full fight free", "pirated", "leaked stream"],
  violence: [
    "real street fight",
    "knockout compilation unsanctioned",
    "prison fight",
  ],
};

app.post("/api/upload/moderate", async (req, res) => {
  try {
    const {
      uploadId,
      title,
      description,
      tags,
      userId,
      ageRating,
      rightsConfirmed,
    } = req.body;

    if (!uploadId || !userId) {
      return res.status(400).json({ error: "uploadId and userId required" });
    }

    const flags = [];
    const textToScan =
      `${title || ""} ${description || ""} ${(tags || []).join(" ")}`.toLowerCase();

    // Keyword scan
    for (const [category, keywords] of Object.entries(FLAGGED_KEYWORDS)) {
      for (const kw of keywords) {
        if (textToScan.includes(kw)) {
          flags.push({
            category,
            keyword: kw,
            severity: category === "copyright" ? "high" : "medium",
          });
        }
      }
    }

    // Age gating
    const resolvedAgeRating = ageRating || "standard";
    if (resolvedAgeRating === "18+" && !rightsConfirmed) {
      flags.push({
        category: "age_gate",
        severity: "high",
        reason: "18+ content requires rights confirmation",
      });
    }

    // Determine moderation status
    const highSeverity = flags.filter((f) => f.severity === "high").length;
    let moderationStatus = "approved";
    if (highSeverity > 0) moderationStatus = "rejected";
    else if (flags.length > 0) moderationStatus = "review";

    // Update Firestore upload doc
    await db
      .collection("uploads")
      .doc(uploadId)
      .update({
        moderation: {
          status: moderationStatus,
          flags,
          ageRating: resolvedAgeRating,
          rightsConfirmed: !!rightsConfirmed,
          moderatedAt: new Date(),
          autoModerated: true,
        },
      });

    // If rejected, remove from public feeds
    if (moderationStatus === "rejected") {
      await db
        .collection("uploads")
        .doc(uploadId)
        .update({ publicVisible: false });
    }

    return res.json({
      uploadId,
      moderationStatus,
      flagCount: flags.length,
      flags,
      ageRating: resolvedAgeRating,
    });
  } catch (err) {
    console.error("[moderate] Error:", err);
    return res.status(500).json({ error: "Moderation failed" });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// POST /api/upload/moderate/appeal — User appeal of flagged content
// ═══════════════════════════════════════════════════════════════════════════
app.post("/api/upload/moderate/appeal", async (req, res) => {
  try {
    const { uploadId, userId, reason } = req.body;
    if (!uploadId || !userId || !reason) {
      return res
        .status(400)
        .json({ error: "uploadId, userId, and reason required" });
    }

    const uploadDoc = await db.collection("uploads").doc(uploadId).get();
    if (!uploadDoc.exists)
      return res.status(404).json({ error: "Upload not found" });

    const upload = uploadDoc.data();
    if (upload.userId !== userId) {
      return res.status(403).json({ error: "Not your upload" });
    }

    await db.collection("moderation_appeals").add({
      uploadId,
      userId,
      reason,
      previousStatus: upload.moderation?.status,
      flags: upload.moderation?.flags || [],
      status: "pending",
      createdAt: new Date(),
    });

    return res.json({ status: "appeal_submitted", uploadId });
  } catch (err) {
    return res.status(500).json({ error: "Appeal submission failed" });
  }
});

// ── Start Server ────────────────────────────────────────────────────────
const PORT = process.env.PORT || 4001;
app.listen(PORT, () => {
  console.log(`🥊 DFC Upload Service running on port ${PORT}`);
});
