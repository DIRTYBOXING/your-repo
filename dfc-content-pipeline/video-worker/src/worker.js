// ═══════════════════════════════════════════════════════════════════════════
// DFC VIDEO WORKER — FFmpeg Transcoding Pipeline
// Instagram/TikTok-grade: MP4 (H.264) + WebM (VP9) + Thumbnails + HLS
// ═══════════════════════════════════════════════════════════════════════════

const { Worker } = require("bullmq");
const IORedis = require("ioredis");
const { initializeApp, cert } = require("firebase-admin/app");
const { getStorage } = require("firebase-admin/storage");
const { getFirestore } = require("firebase-admin/firestore");
const ffmpeg = require("fluent-ffmpeg");
const { v4: uuidv4 } = require("uuid");
const fs = require("fs");
const path = require("path");
const os = require("os");

// Internal callback for the DFC API server — used to push variant URLs back
// into the job record and trigger feed delivery.
const INTERNAL_CALLBACK_URL =
  process.env.INTERNAL_CALLBACK_URL || "http://localhost:3000/internal/media-complete";

// ── Firebase Init ───────────────────────────────────────────────────────
initializeApp({
  credential: cert(process.env.GOOGLE_APPLICATION_CREDENTIALS),
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
});

const storage = getStorage();
const bucket = storage.bucket();
const db = getFirestore();
const redis = new IORedis(process.env.REDIS_URL || "redis://localhost:6379");

// ── Transcode Profiles (like TikTok — multiple quality tiers) ───────────
const PROFILES = {
  sd480: { width: 854, height: 480, videoBitrate: "800k", audioBitrate: "96k" },
  hd720: {
    width: 1280,
    height: 720,
    videoBitrate: "2500k",
    audioBitrate: "128k",
  },
  hd1080: {
    width: 1920,
    height: 1080,
    videoBitrate: "5000k",
    audioBitrate: "192k",
  },
};

const THUMBNAIL_TIMES = ["00:00:01", "00:00:03", "00:00:05"];

// ── Temp directory ──────────────────────────────────────────────────────
const TMP_DIR = path.join(os.tmpdir(), "dfc-transcode");
if (!fs.existsSync(TMP_DIR)) fs.mkdirSync(TMP_DIR, { recursive: true });

// ═══════════════════════════════════════════════════════════════════════════
// TRANSCODE WORKER
// ═══════════════════════════════════════════════════════════════════════════
const transcodeWorker = new Worker(
  "video-transcode",
  async (job) => {
    const { uploadId, storagePath, userId } = job.data;
    const jobDir = path.join(TMP_DIR, uuidv4());
    fs.mkdirSync(jobDir, { recursive: true });

    const inputPath = path.join(jobDir, "input");
    const variants = {};

    try {
      console.log(`[transcode] Starting job ${job.id} for upload ${uploadId}`);
      await updateStatus(uploadId, "processing", { progress: 0 });

      // ── Download original from Firebase Storage ─────────────────────
      const file = bucket.file(storagePath);
      await file.download({ destination: inputPath });
      console.log(`[transcode] Downloaded ${storagePath}`);
      await updateStatus(uploadId, "processing", { progress: 10 });

      // ── Get video metadata ──────────────────────────────────────────
      const metadata = await getVideoMetadata(inputPath);
      console.log(
        `[transcode] Input: ${metadata.width}x${metadata.height}, ${metadata.duration}s`,
      );

      // ── Generate thumbnails ─────────────────────────────────────────
      const thumbnails = await generateThumbnails(inputPath, jobDir);
      const thumbUrl = await uploadFile(
        thumbnails[0],
        `transcoded/${userId}/${uploadId}/thumb.jpg`,
        "image/jpeg",
      );
      await updateStatus(uploadId, "processing", {
        progress: 20,
        thumbnailUrl: thumbUrl,
      });
      console.log(`[transcode] Thumbnails generated`);

      // ── Generate OG image (1200x630) for social previews ────────────
      const ogPath = path.join(jobDir, "og-1200x630.jpg");
      await generateOgImage(inputPath, ogPath);
      const ogUrl = await uploadFile(
        ogPath,
        `transcoded/${userId}/${uploadId}/og-1200x630.jpg`,
        "image/jpeg",
      );
      await updateStatus(uploadId, "processing", {
        progress: 25,
        ogImageUrl: ogUrl,
      });
      console.log(`[transcode] OG image generated → ${ogUrl}`);

      // ── Transcode to each profile ───────────────────────────────────
      let profileIdx = 0;
      for (const [name, profile] of Object.entries(PROFILES)) {
        // Skip profiles larger than the source
        if (
          profile.width > metadata.width &&
          profile.height > metadata.height
        ) {
          console.log(`[transcode] Skipping ${name} — source is smaller`);
          continue;
        }

        const mp4Path = path.join(jobDir, `${name}.mp4`);
        await transcodeToMp4(inputPath, mp4Path, profile);

        const mp4Url = await uploadFile(
          mp4Path,
          `transcoded/${userId}/${uploadId}/${name}.mp4`,
          "video/mp4",
        );
        variants[name] = { url: mp4Url, format: "mp4", ...profile };

        profileIdx++;
        const progress =
          25 + Math.round((profileIdx / Object.keys(PROFILES).length) * 60);
        await updateStatus(uploadId, "processing", { progress });
        console.log(`[transcode] ${name} complete → ${mp4Url}`);
      }

      // ── Generate WebM for web players ───────────────────────────────
      const webmPath = path.join(jobDir, "web.webm");
      await transcodeToWebm(inputPath, webmPath, PROFILES.hd720);
      const webmUrl = await uploadFile(
        webmPath,
        `transcoded/${userId}/${uploadId}/web.webm`,
        "video/webm",
      );
      variants.webm = { url: webmUrl, format: "webm" };
      await updateStatus(uploadId, "processing", { progress: 90 });

      // ── Finalize ────────────────────────────────────────────────────
      await db
        .collection("media_uploads")
        .doc(uploadId)
        .update({
          status: "ready",
          variants,
          thumbnailUrl: thumbUrl,
          ogImageUrl: ogUrl,
          duration: metadata.duration,
          resolution: `${metadata.width}x${metadata.height}`,
          transcodedAt: new Date(),
        });

      // ── Notify DFC API server so the job record and feed delivery update ──
      try {
        await notifyMediaComplete({
          jobId: job.id,
          uploadId,
          postId: job.data.postId,
          variants,
          ogImageUrl: ogUrl,
          thumbnailUrl: thumbUrl,
        });
      } catch (callbackErr) {
        // Non-fatal: Firestore is already updated; log and continue.
        console.warn(`[transcode] Callback to API server failed: ${callbackErr.message}`);
      }

      console.log(
        `[transcode] Job ${job.id} COMPLETE — ${Object.keys(variants).length} variants`,
      );
      return { uploadId, variants: Object.keys(variants) };
    } catch (err) {
      console.error(`[transcode] Job ${job.id} FAILED:`, err.message);
      await updateStatus(uploadId, "failed", { error: err.message });
      throw err;
    } finally {
      // ── Cleanup temp files ──────────────────────────────────────────
      fs.rmSync(jobDir, { recursive: true, force: true });
    }
  },
  {
    connection: redis,
    concurrency: 2,
    limiter: { max: 4, duration: 60000 },
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// TRANSCODE FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════

function getVideoMetadata(inputPath) {
  return new Promise((resolve, reject) => {
    ffmpeg.ffprobe(inputPath, (err, data) => {
      if (err) return reject(err);
      const video = data.streams.find((s) => s.codec_type === "video");
      resolve({
        width: video?.width || 1920,
        height: video?.height || 1080,
        duration: parseFloat(data.format?.duration || "0"),
        codec: video?.codec_name || "unknown",
      });
    });
  });
}

function transcodeToMp4(input, output, profile) {
  return new Promise((resolve, reject) => {
    ffmpeg(input)
      .videoCodec("libx264")
      .audioCodec("aac")
      .videoBitrate(profile.videoBitrate)
      .audioBitrate(profile.audioBitrate)
      .size(`${profile.width}x?`)
      .autopad()
      .outputOptions([
        "-preset",
        "fast",
        "-crf",
        "23",
        "-movflags",
        "+faststart",
      ])
      .output(output)
      .on("end", resolve)
      .on("error", reject)
      .run();
  });
}

function transcodeToWebm(input, output, profile) {
  return new Promise((resolve, reject) => {
    ffmpeg(input)
      .videoCodec("libvpx-vp9")
      .audioCodec("libopus")
      .videoBitrate(profile.videoBitrate)
      .size(`${profile.width}x?`)
      .autopad()
      .outputOptions(["-deadline", "good", "-cpu-used", "2"])
      .output(output)
      .on("end", resolve)
      .on("error", reject)
      .run();
  });
}

function generateThumbnails(input, outDir) {
  return new Promise((resolve, reject) => {
    const outputs = [];
    ffmpeg(input)
      .screenshots({
        timestamps: THUMBNAIL_TIMES,
        folder: outDir,
        filename: "thumb_%i.jpg",
        size: "640x?",
      })
      .on("end", () => {
        const files = THUMBNAIL_TIMES.map((_, i) =>
          path.join(outDir, `thumb_${i + 1}.jpg`),
        ).filter((f) => fs.existsSync(f));
        resolve(files.length > 0 ? files : [path.join(outDir, "thumb_1.jpg")]);
      })
      .on("error", reject);
  });
}

function generateOgImage(input, outputPath) {
  return new Promise((resolve, reject) => {
    ffmpeg(input)
      .seekInput(3)
      .frames(1)
      .outputOptions([
        "-vf",
        "scale=1200:630:force_original_aspect_ratio=decrease,pad=1200:630:(ow-iw)/2:(oh-ih)/2:color=black",
      ])
      .output(outputPath)
      .on("end", () => resolve(outputPath))
      .on("error", reject)
      .run();
  });
}

async function uploadFile(localPath, remotePath, contentType) {
  const file = bucket.file(remotePath);
  await bucket.upload(localPath, {
    destination: remotePath,
    metadata: { contentType },
  });
  await file.makePublic();
  return `https://storage.googleapis.com/${bucket.name}/${remotePath}`;
}

async function updateStatus(uploadId, status, extra = {}) {
  const update = { status, updatedAt: new Date(), ...extra };
  await db.collection("media_uploads").doc(uploadId).update(update);
}

// ── Internal callback → DFC API server ─────────────────────────────────
async function notifyMediaComplete({ jobId, uploadId, postId, variants, ogImageUrl, thumbnailUrl }) {
  const body = JSON.stringify({
    jobId,
    uploadId,
    postId: postId || null,
    status: "complete",
    variants,
    ogImageUrl: ogImageUrl || null,
    thumbnailUrl: thumbnailUrl || null,
  });

  const response = await fetch(INTERNAL_CALLBACK_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body,
  });

  if (!response.ok) {
    const text = await response.text().catch(() => "");
    throw new Error(`HTTP ${response.status}: ${text}`);
  }
}

// ── Graceful shutdown ───────────────────────────────────────────────────
process.on("SIGTERM", async () => {
  console.log("[transcode] Shutting down...");
  await transcodeWorker.close();
  process.exit(0);
});

console.log("🎬 DFC Video Worker running — waiting for transcode jobs...");
