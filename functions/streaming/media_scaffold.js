"use strict";

const { onRequest } = require("firebase-functions/v2/https");
const { onObjectFinalized } = require("firebase-functions/v2/storage");
const { defineSecret } = require("firebase-functions/params");
const { admin, db, REGION } = require("../config");

const MEDIA_SMOKE_TOKEN_PARAM = defineSecret("MEDIA_SMOKE_TOKEN");

const DEFAULT_UPLOAD_FOLDER = "uploads";
const DEFAULT_UPLOAD_TTL_SECONDS = 60;
const DEFAULT_TRANSCODER_LOCATION = process.env.MEDIA_TRANSCODER_LOCATION || "australia-southeast1";
const DEFAULT_TRIGGER_BUCKET =
  (process.env.MEDIA_UPLOAD_BUCKET || "").trim() || "datafightcentral.appspot.com";

function resolveMediaSmokeToken() {
  const envToken = (process.env.MEDIA_SMOKE_TOKEN || "").trim();
  if (envToken) return envToken;
  try {
    return (MEDIA_SMOKE_TOKEN_PARAM.value() || "").trim();
  } catch {
    return "";
  }
}

function sanitizeFilename(name) {
  const trimmed = String(name || "upload.bin").trim();
  const safe = trimmed.replace(/[^a-zA-Z0-9._-]/g, "_");
  return safe.length > 0 ? safe : "upload.bin";
}

function sanitizeFolder(folder) {
  const trimmed = String(folder || DEFAULT_UPLOAD_FOLDER).trim().replace(/^\/+|\/+$/g, "");
  if (!trimmed) return DEFAULT_UPLOAD_FOLDER;
  return trimmed.replace(/\.\./g, "");
}

async function verifyCaller(req) {
  const smokeToken = resolveMediaSmokeToken();
  const providedSmokeToken = (req.headers["x-media-smoke-token"] || "").toString().trim();

  if (smokeToken && providedSmokeToken && providedSmokeToken === smokeToken) {
    return { ok: true, uid: "media-smoke" };
  }

  const authHeader = (req.headers.authorization || "").toString().trim();
  if (!authHeader.startsWith("Bearer ")) {
    return { ok: false, uid: null };
  }

  const idToken = authHeader.slice(7).trim();
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    return { ok: true, uid: decoded.uid };
  } catch {
    return { ok: false, uid: null };
  }
}

function mediaBucket() {
  const name = (process.env.MEDIA_UPLOAD_BUCKET || "").trim();
  return name ? admin.storage().bucket(name) : admin.storage().bucket();
}

async function createUploadUrl(req, res) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "method_not_allowed" });
  }

  const caller = await verifyCaller(req);
  if (!caller.ok) {
    return res.status(401).json({ error: "unauthorized" });
  }

  const filename = sanitizeFilename(req.body?.filename || "upload.bin");
  const folder = sanitizeFolder(req.body?.folder || DEFAULT_UPLOAD_FOLDER);
  const contentType = String(req.body?.contentType || "application/octet-stream").trim();
  const ttlSecondsRaw = Number.parseInt(String(req.body?.ttlSeconds || DEFAULT_UPLOAD_TTL_SECONDS), 10);
  const ttlSeconds = Number.isFinite(ttlSecondsRaw)
    ? Math.max(15, Math.min(ttlSecondsRaw, 300))
    : DEFAULT_UPLOAD_TTL_SECONDS;

  const key = `${folder}/${Date.now()}-${filename}`;
  const bucket = mediaBucket();
  const file = bucket.file(key);

  const [uploadUrl] = await file.getSignedUrl({
    version: "v4",
    action: "write",
    expires: Date.now() + ttlSeconds * 1000,
    contentType,
  });

  await db.collection("media_uploads").add({
    key,
    bucket: bucket.name,
    contentType,
    ttlSeconds,
    createdBy: caller.uid,
    status: "signed",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return res.status(200).json({
    uploadUrl,
    key,
    bucket: bucket.name,
    expiresAt: new Date(Date.now() + ttlSeconds * 1000).toISOString(),
  });
}

async function submitTranscoderJob(inputUri, outputUri) {
  const projectId =
    process.env.GCP_PROJECT ||
    process.env.GCLOUD_PROJECT ||
    process.env.GOOGLE_CLOUD_PROJECT ||
    "";

  if (!projectId) {
    return { submitted: false, reason: "missing_project_id" };
  }

  const credential = admin.app().options.credential;
  if (!credential || typeof credential.getAccessToken !== "function") {
    return { submitted: false, reason: "missing_access_token_provider" };
  }

  const tokenResp = await credential.getAccessToken();
  const accessToken = tokenResp?.access_token || tokenResp?.accessToken || "";
  if (!accessToken) {
    return { submitted: false, reason: "missing_access_token" };
  }

  const location = DEFAULT_TRANSCODER_LOCATION;
  const endpoint = `https://transcoder.googleapis.com/v1/projects/${projectId}/locations/${location}/jobs`;

  const payload = {
    inputUri,
    outputUri,
    config: {
      elementaryStreams: [
        {
          key: "video-stream",
          videoStream: {
            h264: {
              widthPixels: 1280,
              heightPixels: 720,
              bitrateBps: 3000000,
              frameRate: 30,
            },
          },
        },
        {
          key: "audio-stream",
          audioStream: {
            codec: "aac",
            bitrateBps: 128000,
          },
        },
      ],
      muxStreams: [
        {
          key: "hls-sd",
          container: "ts",
          elementaryStreams: ["video-stream", "audio-stream"],
        },
      ],
      manifests: [
        {
          fileName: "master.m3u8",
          type: "HLS",
          muxStreams: ["hls-sd"],
        },
      ],
    },
  };

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const errBody = await response.text();
    return { submitted: false, reason: "transcoder_api_error", detail: errBody };
  }

  const data = await response.json();
  return { submitted: true, jobName: data.name || null };
}

async function handleUploadFinalize(event) {
  const bucketName = event.bucket;
  const objectName = event.name;
  const contentType = event.contentType || "application/octet-stream";

  if (!bucketName || !objectName) {
    return;
  }

  const inputUri = `gs://${bucketName}/${objectName}`;
  const outputPrefix = `hls/${objectName}`;
  const outputUri = `gs://${bucketName}/${outputPrefix}/`;
  const manifestPath = `${outputPrefix}/master.m3u8`;

  const jobRef = await db.collection("transcode_jobs").add({
    inputUri,
    outputUri,
    manifestPath,
    sourceContentType: contentType,
    status: "queued",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  try {
    const submit = await submitTranscoderJob(inputUri, outputUri);
    await jobRef.set(
      {
        status: submit.submitted ? "submitted" : "queued",
        transcoderJobName: submit.jobName || null,
        submitReason: submit.reason || null,
        submitDetail: submit.detail || null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  } catch (error) {
    await jobRef.set(
      {
        status: "queued",
        submitReason: "transcoder_submit_exception",
        submitDetail: String(error?.message || error),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
}

async function mediaManifestStatus(req, res) {
  if (req.method !== "GET" && req.method !== "POST") {
    return res.status(405).json({ error: "method_not_allowed" });
  }

  const caller = await verifyCaller(req);
  if (!caller.ok) {
    return res.status(401).json({ error: "unauthorized" });
  }

  const keyFromQuery = (req.query?.key || "").toString().trim();
  const keyFromBody = (req.body?.key || "").toString().trim();
  const key = keyFromQuery || keyFromBody;

  if (!key) {
    return res.status(400).json({ error: "missing_key" });
  }

  const bucket = mediaBucket();
  const manifestPath = `hls/${key}/master.m3u8`;
  const [exists] = await bucket.file(manifestPath).exists();

  return res.status(200).json({
    key,
    bucket: bucket.name,
    manifestPath,
    manifestUri: `gs://${bucket.name}/${manifestPath}`,
    exists,
  });
}

const getMediaUploadUrl = onRequest(
  { region: REGION, cors: true, secrets: [MEDIA_SMOKE_TOKEN_PARAM] },
  createUploadUrl,
);

const getMediaManifestStatus = onRequest(
  { region: REGION, cors: true, secrets: [MEDIA_SMOKE_TOKEN_PARAM] },
  mediaManifestStatus,
);

const onMediaUploadFinalize = onObjectFinalized(
  { region: REGION, bucket: DEFAULT_TRIGGER_BUCKET },
  handleUploadFinalize,
);

module.exports = {
  getMediaUploadUrl,
  getMediaManifestStatus,
  onMediaUploadFinalize,
};
