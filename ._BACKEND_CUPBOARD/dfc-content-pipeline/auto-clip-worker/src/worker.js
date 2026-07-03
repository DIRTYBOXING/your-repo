// ═══════════════════════════════════════════════════════════════════════════
// DFC AUTO-CLIP WORKER — AI Highlight Extraction Pipeline
// Consumes "auto-clip" BullMQ jobs, analyses audio/visual peaks,
// extracts top-N highlight segments via FFmpeg, uploads to Storage.
// ═══════════════════════════════════════════════════════════════════════════

const { Worker, Queue } = require("bullmq");
const { makeRedisConnectionFromEnv } = require("./redis-connection");
const { createLogger } = require("../../../shared/logger");
const log = createLogger("auto-clip-worker");
const {
  initializeApp,
  cert,
  applicationDefault,
} = require("firebase-admin/app");
const { getStorage } = require("firebase-admin/storage");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const ffmpeg = require("fluent-ffmpeg");
const { v4: uuidv4 } = require("uuid");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");

// ── Firebase Init ───────────────────────────────────────────────────────
// Set REQUIRE_FIREBASE=true in production to fail the container if Firebase
// cannot initialize (Docker healthcheck reads /tmp/dfc-worker-ready).
const REQUIRE_FIREBASE = process.env.REQUIRE_FIREBASE === "true";
const READY_FILE = "/tmp/dfc-worker-ready";

let storage, bucket, db;
try {
  const firebaseCredentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const hasCredentialFile =
    !!firebaseCredentialsPath &&
    fs.existsSync(firebaseCredentialsPath) &&
    fs.statSync(firebaseCredentialsPath).isFile();

  if (hasCredentialFile) {
    initializeApp({
      credential: cert(firebaseCredentialsPath),
      storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
    });
  } else {
    // Try application default credentials
    initializeApp({
      credential: applicationDefault(),
      storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
    });
  }
  storage = getStorage();
  bucket = storage.bucket();
  db = getFirestore();
  log.info("firebase_initialized", {
    bucket: process.env.FIREBASE_STORAGE_BUCKET,
  });
  fs.writeFileSync(READY_FILE, "firebase_initialized\n");
} catch (err) {
  // In production (REQUIRE_FIREBASE=true) crash the container so the
  // orchestrator/healthcheck detects the bad credential immediately.
  if (REQUIRE_FIREBASE) {
    log.error("firebase_init_failed_fatal", { reason: err.message });
    process.exit(1);
  }
  // In dev/local: keep the worker online in offline mode.
  log.warn("firebase_init_failed", { reason: err.message, mode: "offline" });
  // Create stub objects so the worker doesn't crash on missing Firebase services
  storage = null;
  bucket = null;
  db = null;
  fs.writeFileSync(READY_FILE, "offline\n");
}
const connection = makeRedisConnectionFromEnv();

// ── Dead-letter queue ───────────────────────────────────────────────────
// Failed jobs that exhaust retries land here for inspection + manual replay.
const dlq = new Queue("auto-clip-dlq", {
  connection: makeRedisConnectionFromEnv(),
});

// ── Config ──────────────────────────────────────────────────────────────
const TMP_DIR = path.join(os.tmpdir(), "dfc-autoclip");
if (!fs.existsSync(TMP_DIR)) fs.mkdirSync(TMP_DIR, { recursive: true });

const MAX_CLIPS = Number(process.env.MAX_CLIPS || 5);
const CLIP_DURATION = Number(process.env.CLIP_DURATION || 15); // seconds
const CLIP_FORMAT = "mp4";
const MIN_PEAK_GAP = 20; // seconds between peaks to avoid overlapping clips

// ═══════════════════════════════════════════════════════════════════════════
// AUDIO ANALYSIS — Detect crowd-roar / impact peaks via volume spikes
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Analyze audio volume across the video to find peaks.
 * Returns array of { time, db } sorted by loudness descending.
 */
async function analyzeAudioPeaks(inputPath) {
  return new Promise((resolve, reject) => {
    const volumes = [];

    ffmpeg(inputPath)
      .audioFilters("volumedetect")
      .outputOptions("-f", "null")
      .output(process.platform === "win32" ? "NUL" : "/dev/null")
      .on("stderr", (line) => {
        // Parse metered per-frame dB from astats or similar
        const match = line.match(
          /\[Parsed_volumedetect.*\]\s*mean_volume:\s*([-\d.]+)\s*dB/,
        );
        if (match) {
          volumes.push({ meanDb: Number.parseFloat(match[1]) });
        }
      })
      .on("end", () => resolve(volumes))
      .on("error", reject)
      .run();
  });
}

/**
 * Segment-based loudness analysis: split into windows and rank by energy.
 */
async function analyzeSegmentLoudness(inputPath, duration, windowSize = 5) {
  const segments = [];
  const numWindows = Math.floor(duration / windowSize);

  for (let i = 0; i < numWindows; i++) {
    const startTime = i * windowSize;
    const loudness = await measureSegmentLoudness(
      inputPath,
      startTime,
      windowSize,
    );
    segments.push({ time: startTime, loudness });
  }

  // Sort descending by loudness
  segments.sort((a, b) => b.loudness - a.loudness);
  return segments;
}

function measureSegmentLoudness(inputPath, start, duration) {
  return new Promise((resolve, reject) => {
    let maxVol = -Infinity;
    ffmpeg(inputPath)
      .seekInput(start)
      .duration(duration)
      .audioFilters(
        "astats=metadata=1:reset=1,ametadata=print:key=lavfi.astats.Overall.RMS_level",
      )
      .outputOptions("-f", "null")
      .output(process.platform === "win32" ? "NUL" : "/dev/null")
      .on("stderr", (line) => {
        const match = line.match(/lavfi\.astats\.Overall\.RMS_level=([-\d.]+)/);
        if (match) {
          const db = Number.parseFloat(match[1]);
          if (db > maxVol) maxVol = db;
        }
      })
      .on("end", () => resolve(maxVol === -Infinity ? -100 : maxVol))
      .on("error", () => resolve(-100))
      .run();
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// SCENE CHANGE DETECTION — Find visual cuts / high-motion moments
// ═══════════════════════════════════════════════════════════════════════════

async function detectSceneChanges(inputPath) {
  return new Promise((resolve, reject) => {
    const scenes = [];
    ffmpeg(inputPath)
      .videoFilters(String.raw`select=gt(scene\,0.4),showinfo`)
      .outputOptions("-f", "null")
      .output(process.platform === "win32" ? "NUL" : "/dev/null")
      .on("stderr", (line) => {
        const match = line.match(/pts_time:([\d.]+)/);
        if (match) scenes.push(Number.parseFloat(match[1]));
      })
      .on("end", () => resolve(scenes))
      .on("error", reject)
      .run();
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// PEAK SELECTION — Merge audio + visual signals, pick top N non-overlapping
// ═══════════════════════════════════════════════════════════════════════════

function selectClipTimestamps(audioSegments, sceneChanges, duration, maxClips) {
  // Score each audio segment; boost segments near scene changes
  const scored = audioSegments.map((seg) => {
    const nearestScene = sceneChanges.reduce((best, sc) => {
      const dist = Math.abs(sc - seg.time);
      return Math.min(dist, best);
    }, Infinity);
    const sceneBoost = nearestScene < 8 ? (8 - nearestScene) * 2 : 0;
    return { time: seg.time, score: seg.loudness + sceneBoost };
  });

  scored.sort((a, b) => b.score - a.score);

  // Greedily pick non-overlapping clips
  const selected = [];
  for (const candidate of scored) {
    if (selected.length >= maxClips) break;
    const tooClose = selected.some(
      (s) => Math.abs(s.time - candidate.time) < MIN_PEAK_GAP,
    );
    if (tooClose) continue;

    // Ensure clip doesn't overflow video
    const clipStart = Math.max(0, candidate.time - CLIP_DURATION / 2);
    if (clipStart + CLIP_DURATION > duration) continue;

    selected.push({ time: clipStart, score: candidate.score });
  }

  // Sort by time for chronological ordering
  selected.sort((a, b) => a.time - b.time);
  return selected;
}

// ═══════════════════════════════════════════════════════════════════════════
// CLIP EXTRACTION — FFmpeg re-encode each highlight at TikTok grade
// ═══════════════════════════════════════════════════════════════════════════

async function extractClip(inputPath, start, outputPath) {
  return new Promise((resolve, reject) => {
    ffmpeg(inputPath)
      .seekInput(start)
      .duration(CLIP_DURATION)
      .videoCodec("libx264")
      .audioCodec("aac")
      .outputOptions([
        "-preset fast",
        "-crf 22",
        "-movflags +faststart",
        "-pix_fmt yuv420p",
      ])
      .output(outputPath)
      .on("end", resolve)
      .on("error", reject)
      .run();
  });
}

async function generateClipThumbnail(clipPath, outputPath) {
  return new Promise((resolve, reject) => {
    ffmpeg(clipPath)
      .screenshots({
        timestamps: ["00:00:02"],
        filename: path.basename(outputPath),
        folder: path.dirname(outputPath),
        size: "640x360",
      })
      .on("end", resolve)
      .on("error", reject);
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// UPLOAD HELPERS
// ═══════════════════════════════════════════════════════════════════════════

async function uploadFile(localPath, storageDest, contentType) {
  if (!bucket) {
    log.warn("firebase_upload_skipped", { dest: storageDest });
    return `mock://offline/${storageDest}`;
  }
  await bucket.upload(localPath, {
    destination: storageDest,
    metadata: {
      contentType,
      metadata: { firebaseStorageDownloadTokens: uuidv4() },
    },
  });
  const f = bucket.file(storageDest);
  const [meta] = await f.getMetadata();
  const token = meta.metadata?.firebaseStorageDownloadTokens;
  return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(storageDest)}?alt=media&token=${token}`;
}

function getVideoMetadata(inputPath) {
  return new Promise((resolve, reject) => {
    ffmpeg.ffprobe(inputPath, (err, metadata) => {
      if (err) return reject(err);
      const video =
        metadata.streams.find((s) => s.codec_type === "video") || {};
      resolve({
        duration: Number.parseFloat(metadata.format.duration) || 0,
        width: video.width || 0,
        height: video.height || 0,
        bitrate: Number.parseInt(metadata.format.bit_rate, 10) || 0,
      });
    });
  });
}

async function updateStatus(docId, status, extra = {}) {
  if (!db) {
    log.warn("firebase_status_skipped", { docId, status });
    return;
  }
  await db
    .collection("auto_clips")
    .doc(docId)
    .set(
      { status, updatedAt: FieldValue.serverTimestamp(), ...extra },
      { merge: true },
    );
}

// ═══════════════════════════════════════════════════════════════════════════
// CLEANUP
// ═══════════════════════════════════════════════════════════════════════════

function cleanupDir(dir) {
  if (fs.existsSync(dir)) {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BULLMQ AUTO-CLIP WORKER
// ═══════════════════════════════════════════════════════════════════════════

// ── Job options: retry 3× with exponential back-off, then DLQ ──────────
const JOB_OPTIONS = {
  attempts: 3,
  backoff: { type: "exponential", delay: 5000 },
};

const clipWorker = new Worker(
  "auto-clip",
  async (job) => {
    const { clipJobId, storagePath, eventId, maxClips } = job.data;
    const jobLog = log.child(job.id);
    const jobDir = path.join(TMP_DIR, uuidv4());
    fs.mkdirSync(jobDir, { recursive: true });

    const inputPath = path.join(jobDir, "source");
    const effectiveMax = maxClips || MAX_CLIPS;

    try {
      jobLog.info("job_started", {
        clipJobId,
        storagePath,
        eventId,
        attempt: job.attemptsMade + 1,
      });
      await updateStatus(clipJobId, "processing", { progress: 0 });

      // 1. Download source
      if (bucket) {
        const file = bucket.file(storagePath);
        await file.download({ destination: inputPath });
        jobLog.info("source_downloaded", { storagePath });
      } else {
        jobLog.warn("source_download_skipped", {
          storagePath,
          mode: "offline",
        });
        // Create a dummy placeholder file so analysis can proceed
        fs.writeFileSync(inputPath, Buffer.alloc(0));
      }
      await updateStatus(clipJobId, "processing", { progress: 10 });

      // 2. Get metadata
      const meta = await getVideoMetadata(inputPath);
      jobLog.info("source_metadata", {
        width: meta.width,
        height: meta.height,
        duration_s: meta.duration,
      });

      if (meta.duration < CLIP_DURATION + 5) {
        jobLog.warn("video_too_short", { duration_s: meta.duration });
        await updateStatus(clipJobId, "completed", {
          progress: 100,
          clips: [],
          reason: "Video too short",
        });
        return;
      }

      // 3. Analyze audio peaks
      jobLog.info("analyzing_audio_peaks", {});
      const audioSegments = await analyzeSegmentLoudness(
        inputPath,
        meta.duration,
      );
      await updateStatus(clipJobId, "processing", { progress: 30 });

      // 4. Detect scene changes
      jobLog.info("detecting_scene_changes", {});
      const sceneChanges = await detectSceneChanges(inputPath);
      await updateStatus(clipJobId, "processing", { progress: 45 });

      // 5. Select top highlight timestamps
      const timestamps = selectClipTimestamps(
        audioSegments,
        sceneChanges,
        meta.duration,
        effectiveMax,
      );
      jobLog.info("highlights_selected", { count: timestamps.length });
      await updateStatus(clipJobId, "processing", { progress: 50 });

      // 6. Extract clips
      const clips = [];
      for (let i = 0; i < timestamps.length; i++) {
        const ts = timestamps[i];
        const clipFilename = `highlight_${i + 1}.${CLIP_FORMAT}`;
        const clipPath = path.join(jobDir, clipFilename);
        const thumbPath = path.join(jobDir, `highlight_${i + 1}_thumb.jpg`);

        jobLog.info("extracting_clip", {
          index: i + 1,
          total: timestamps.length,
          time_s: ts.time,
        });
        await extractClip(inputPath, ts.time, clipPath);
        await generateClipThumbnail(clipPath, thumbPath);

        // Upload
        const storageBase = `auto-clips/${eventId}/${clipJobId}`;
        const clipUrl = await uploadFile(
          clipPath,
          `${storageBase}/${clipFilename}`,
          "video/mp4",
        );
        const thumbUrl = await uploadFile(
          thumbPath,
          `${storageBase}/highlight_${i + 1}_thumb.jpg`,
          "image/jpeg",
        );

        clips.push({
          index: i + 1,
          startTime: ts.time,
          duration: CLIP_DURATION,
          score: ts.score,
          clipUrl,
          thumbnailUrl: thumbUrl,
        });

        const progress = 50 + Math.round(((i + 1) / timestamps.length) * 45);
        await updateStatus(clipJobId, "processing", { progress });
      }

      // 7. Finalize
      await updateStatus(clipJobId, "completed", {
        progress: 100,
        clipCount: clips.length,
        clips,
        sourceMetadata: meta,
        completedAt: FieldValue.serverTimestamp(),
      });

      jobLog.info("job_completed", { clipJobId, clips: clips.length });
      return { clips: clips.length };
    } catch (err) {
      jobLog.error("job_failed", {
        clipJobId,
        error: err.message,
        attempt: job.attemptsMade + 1,
        maxAttempts: JOB_OPTIONS.attempts,
      });
      await updateStatus(clipJobId, "failed", { error: err.message });
      throw err;
    } finally {
      cleanupDir(jobDir);
    }
  },
  {
    connection,
    concurrency: Number(process.env.CLIP_CONCURRENCY || 2),
    limiter: { max: 4, duration: 60_000 },
  },
);

clipWorker.on("completed", (job, result) => {
  log.info("queue_job_completed", { jobId: job.id, clips: result?.clips });
});

clipWorker.on("failed", async (job, err) => {
  const exhausted = job && job.attemptsMade >= JOB_OPTIONS.attempts;
  log.error("queue_job_failed", {
    jobId: job?.id,
    error: err.message,
    exhausted,
  });

  // Move to DLQ after all retries are exhausted
  if (exhausted && job) {
    try {
      await dlq.add(
        "failed-job",
        {
          ...job.data,
          failedReason: err.message,
          failedAt: new Date().toISOString(),
        },
        { removeOnComplete: false },
      );
      log.warn("job_moved_to_dlq", { jobId: job.id });
    } catch (dlqErr) {
      log.error("dlq_write_failed", { jobId: job.id, error: dlqErr.message });
    }
  }
});

clipWorker.on("error", (err) =>
  log.error("worker_error", { error: err.message }),
);

log.info("worker_online", {
  queue: "auto-clip",
  concurrency: Number(process.env.CLIP_CONCURRENCY || 2),
});
