const express = require("express");
const multer = require("multer");
const Stripe = require("stripe");
const upload = multer({ dest: "/tmp/uploads" });
const { v4: uuid } = require("uuid");
const router = express.Router();
const { generateOfferHandler } = require("../api/offers/generate");
const { generateCreativeHandler } = require("../api/creative/generate");
const { abRunnerRouter } = require("../api/offers/ab_runner");
const { createAnalyticsEmitRouter } = require("./api/analytics_emit");
const { consentMiddleware, requireConsent, getConsentState } = require("./middleware/consent");
const { createApiAuthMiddleware } = require("./middleware/auth");
const { forwardToMeta } = require("../functions/ads/meta_forward");
const featureFlags = require("./featureFlags");

let firestoreDb = null;

function getDb() {
  if (firestoreDb) return firestoreDb;

  try {
    const admin = require("firebase-admin");
    if (!admin.apps.length) {
      admin.initializeApp();
    }
    firestoreDb = admin.firestore();
  } catch {
    firestoreDb = null;
  }

  return firestoreDb;
}

// Apply consent parsing to every API request
router.use(consentMiddleware);
// Apply feature flag context to every API request (non-blocking — Firestore optional)
router.use(featureFlags.middleware);

const pendingJobs = [];
const orderStore = new Map();
const entitlementStore = new Map();
const purchaseStore = new Map();
const shakuraTickets = new Map();
const walletStore = new Map();
const walletTransactions = new Map();
const micropurchases = new Map();
const walletIdempotencyStore = new Map();
// Dead-letter queue: stores failed webhook attempts for manual or automated retry
const webhookDLQ = new Map(); // key = orderId, value = { attempts, lastError, payload, nextRetryAt }
const webhookForensics = [];
const MAX_WEBHOOK_ATTEMPTS = 3;
const STRIPE_API_KEY = process.env.STRIPE_SECRET_KEY || process.env.STRIPE_SECRET || "";
const STRIPE_WEBHOOK_SECRET = process.env.STRIPE_WEBHOOK_SECRET || "";
const CHECKOUT_BASE_URL = process.env.CHECKOUT_BASE_URL || "https://www.datafightcentral.com";
const PAYPAL_CLIENT_ID = process.env.PAYPAL_CLIENT_ID || "";
const PAYPAL_CLIENT_SECRET = process.env.PAYPAL_CLIENT_SECRET || "";
const PAYPAL_ENV = (process.env.PAYPAL_ENV || "sandbox").toLowerCase();
const PAYPAL_WEBHOOK_ID = process.env.PAYPAL_WEBHOOK_ID || "";
const PAYPAL_REQUIRE_WEBHOOK_VERIFY = process.env.PAYPAL_REQUIRE_WEBHOOK_VERIFY === "true";
const PAYPAL_WEBHOOK_VERIFY_BYPASS = process.env.PAYPAL_WEBHOOK_VERIFY_BYPASS === "true";
let stripeClient = null;
let paypalClient = null;
const rateLimitBuckets = new Map();
const requireApiAuth = createApiAuthMiddleware();

function getRequestId(req) {
  const fromHeader = req.headers["x-request-id"];
  if (typeof fromHeader === "string" && fromHeader.trim()) {
    return fromHeader.trim();
  }
  return uuid();
}

function getClientKey(req) {
  const forwarded = req.headers["x-forwarded-for"];
  if (typeof forwarded === "string" && forwarded.trim()) {
    return forwarded.split(",")[0].trim();
  }
  return req.ip || "unknown";
}

function buildHeadersSnippet(rawHeaders) {
  if (!Array.isArray(rawHeaders) || rawHeaders.length === 0) {
    return "";
  }
  return rawHeaders.slice(0, 12).join(";").slice(0, 240);
}

function recordWebhookSignatureFailure({ provider, reason, requestId, req }) {
  webhookForensics.push({
    ts: Date.now(),
    provider,
    reason,
    requestId,
    clientIp: getClientKey(req),
    headersSnippet: buildHeadersSnippet(req.rawHeaders),
  });
  if (webhookForensics.length > 200) {
    webhookForensics.shift();
  }
}

function parsePeriodMs(periodRaw) {
  const normalized = String(periodRaw || "1h").trim().toLowerCase();
  const match = /^(\d+)([mhd])$/.exec(normalized);
  if (!match) {
    return 60 * 60 * 1000;
  }
  const value = Number(match[1]);
  const unit = match[2];
  if (!Number.isFinite(value) || value <= 0) {
    return 60 * 60 * 1000;
  }
  if (unit === "m") return value * 60 * 1000;
  if (unit === "h") return value * 60 * 60 * 1000;
  return value * 24 * 60 * 60 * 1000;
}

function percentile(values, p) {
  if (!values.length) {
    return 0;
  }
  const sorted = [...values].sort((a, b) => a - b);
  const index = Math.min(
    sorted.length - 1,
    Math.max(0, Math.ceil((p / 100) * sorted.length) - 1),
  );
  return Math.round(sorted[index]);
}

function getOrCreateWallet(userId, currency = "USD") {
  const existing = walletStore.get(userId);
  if (existing) {
    return existing;
  }

  const wallet = {
    userId,
    balanceCents: 0,
    currency,
    updatedAt: new Date().toISOString(),
  };
  walletStore.set(userId, wallet);
  return wallet;
}

function createWalletTransaction({
  userId,
  type,
  provider = null,
  providerId = null,
  amountCents,
  currency = "USD",
  metadata = {},
}) {
  const id = walletTransactions.size + 1;
  const tx = {
    id,
    userId,
    type,
    provider,
    providerId,
    amountCents: Number(amountCents),
    currency,
    metadata,
    createdAt: new Date().toISOString(),
  };
  walletTransactions.set(id, tx);
  return tx;
}

function createMicropurchase({ userId, itemId, amountCents, currency, walletTxId, entitlementId }) {
  const id = micropurchases.size + 1;
  const purchase = {
    id,
    userId,
    itemId,
    amountCents: Number(amountCents),
    currency,
    walletTxId,
    entitlementId,
    createdAt: new Date().toISOString(),
  };
  micropurchases.set(id, purchase);
  return purchase;
}

function createRateLimiter({ keyPrefix, max, windowMs }) {
  return (req, res, next) => {
    const now = Date.now();
    const clientKey = `${keyPrefix}:${getClientKey(req)}`;
    const existing = rateLimitBuckets.get(clientKey);

    if (!existing || now >= existing.resetAt) {
      rateLimitBuckets.set(clientKey, { count: 1, resetAt: now + windowMs });
      return next();
    }

    if (existing.count >= max) {
      return res.status(429).json({
        error: "rate_limited",
        retryAfterMs: Math.max(0, existing.resetAt - now),
      });
    }

    existing.count += 1;
    return next();
  };
}

const aiSellRateLimiter = createRateLimiter({
  keyPrefix: "ai_sell",
  max: Number(process.env.AI_SELL_RATE_LIMIT_MAX || 30),
  windowMs: Number(process.env.AI_SELL_RATE_LIMIT_WINDOW_MS || 60_000),
});

const webhookRateLimiter = createRateLimiter({
  keyPrefix: "payment_webhook",
  max: Number(process.env.WEBHOOK_RATE_LIMIT_MAX || 120),
  windowMs: Number(process.env.WEBHOOK_RATE_LIMIT_WINDOW_MS || 60_000),
});

function getStripeClient() {
  if (!STRIPE_API_KEY) {
    return null;
  }
  if (!stripeClient) {
    stripeClient = new Stripe(STRIPE_API_KEY, { apiVersion: "2024-06-20" });
  }
  return stripeClient;
}

function getPayPalSdk() {
  try {
    return require("@paypal/checkout-server-sdk");
  } catch {
    return null;
  }
}

function getPayPalClient() {
  if (!PAYPAL_CLIENT_ID || !PAYPAL_CLIENT_SECRET) {
    return null;
  }
  if (paypalClient) {
    return paypalClient;
  }

  const sdk = getPayPalSdk();
  if (!sdk) {
    return null;
  }

  const environment = PAYPAL_ENV === "live"
    ? new sdk.core.LiveEnvironment(PAYPAL_CLIENT_ID, PAYPAL_CLIENT_SECRET)
    : new sdk.core.SandboxEnvironment(PAYPAL_CLIENT_ID, PAYPAL_CLIENT_SECRET);

  paypalClient = new sdk.core.PayPalHttpClient(environment);
  return paypalClient;
}

async function getPayPalAccessToken() {
  if (!PAYPAL_CLIENT_ID || !PAYPAL_CLIENT_SECRET) {
    return null;
  }

  const oauthUrl = PAYPAL_ENV === "live"
    ? "https://api.paypal.com/v1/oauth2/token"
    : "https://api.sandbox.paypal.com/v1/oauth2/token";
  const basicToken = Buffer.from(`${PAYPAL_CLIENT_ID}:${PAYPAL_CLIENT_SECRET}`).toString("base64");

  const response = await fetch(oauthUrl, {
    method: "POST",
    headers: {
      Authorization: `Basic ${basicToken}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: "grant_type=client_credentials",
  });

  if (!response.ok) {
    return null;
  }

  const payload = await response.json();
  return payload.access_token || null;
}

async function verifyPayPalWebhookSignature(headers, eventBody) {
  if (PAYPAL_WEBHOOK_VERIFY_BYPASS) {
    return true;
  }

  if (!PAYPAL_WEBHOOK_ID) {
    return false;
  }

  const accessToken = await getPayPalAccessToken();
  if (!accessToken) {
    return false;
  }

  const verifyUrl = PAYPAL_ENV === "live"
    ? "https://api.paypal.com/v1/notifications/verify-webhook-signature"
    : "https://api.sandbox.paypal.com/v1/notifications/verify-webhook-signature";

  const verificationPayload = {
    auth_algo: headers["paypal-auth-algo"],
    cert_url: headers["paypal-cert-url"],
    transmission_id: headers["paypal-transmission-id"],
    transmission_sig: headers["paypal-transmission-sig"],
    transmission_time: headers["paypal-transmission-time"],
    webhook_id: PAYPAL_WEBHOOK_ID,
    webhook_event: eventBody,
  };

  const response = await fetch(verifyUrl, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(verificationPayload),
  });

  if (!response.ok) {
    return false;
  }

  const payload = await response.json();
  return payload.verification_status === "SUCCESS";
}

function parseAmountCents(value) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return null;
  }
  return Math.round(parsed * 100);
}

function parseWholeCents(value) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return null;
  }
  return Math.round(parsed);
}

function extractPayPalEventDetails(body) {
  if (!body || typeof body !== "object") {
    return null;
  }

  // Backward-compatible internal payload for local testing.
  if (body.eventId && body.userId) {
    return {
      eventId: Number(body.eventId),
      userId: body.userId,
      amountCents: parseWholeCents(body.amountCents),
      status: body.status || "paid",
      providerId: body.orderId || body.id || null,
    };
  }

  const eventType = body.event_type;
  const resource = body.resource || {};
  if (!["PAYMENT.CAPTURE.COMPLETED", "CHECKOUT.ORDER.APPROVED"].includes(eventType)) {
    return null;
  }

  const metadataParts = String(resource.custom_id || "")
    .split(";")
    .map((part) => part.trim())
    .filter(Boolean);
  const metadata = {};
  for (const part of metadataParts) {
    const [key, value] = part.split("=");
    if (key && value) {
      metadata[key] = value;
    }
  }

  return {
    eventId: Number(metadata.eventId || resource.invoice_id || 0),
    userId: metadata.userId || null,
    amountCents: parseAmountCents(resource.amount?.value),
    status: "paid",
    providerId: resource.id || body.id || null,
  };
}

function getWebhookBodyString(req) {
  if (Buffer.isBuffer(req.body)) {
    return req.body.toString("utf8");
  }
  if (typeof req.body === "string") {
    return req.body;
  }
  return JSON.stringify(req.body || {});
}

function extractPaymentDetails(body) {
  if (!body || typeof body !== "object") {
    return null;
  }

  // Stripe Checkout session completed.
  if (body.type === "checkout.session.completed") {
    const session = body.data?.object || {};
    return {
      provider: "stripe",
      sessionId: session.id || null,
      eventId: Number(session.metadata?.eventId),
      userId: session.metadata?.userId,
      amountCents: Number(session.amount_total || 0),
      status: session.payment_status || "paid",
      sku: session.metadata?.sku || null,
    };
  }

  // Stripe PaymentIntent succeeded.
  if (body.type === "payment_intent.succeeded") {
    const intent = body.data?.object || {};
    return {
      provider: "stripe",
      sessionId: intent.id || null,
      eventId: Number(intent.metadata?.eventId),
      userId: intent.metadata?.userId,
      amountCents: Number(intent.amount || 0),
      status: intent.status || "succeeded",
      sku: intent.metadata?.sku || null,
    };
  }

  // Backward-compatible internal payload.
  return {
    provider: body.provider || "internal",
    sessionId: body.sessionId || null,
    eventId: Number(body.eventId),
    userId: body.userId,
    amountCents: Number(body.amountCents || 0),
    status: body.status || "paid",
    sku: body.sku || null,
  };
}

function walletSummary() {
  let totalBalanceCents = 0;
  for (const wallet of walletStore.values()) {
    totalBalanceCents += Number(wallet.balanceCents || 0);
  }

  return {
    wallets: walletStore.size,
    totalBalanceCents,
    transactions: walletTransactions.size,
    micropurchases: micropurchases.size,
  };
}

function computePurchaseSuccessRate() {
  if (orderStore.size === 0) {
    return 100;
  }
  let succeeded = 0;
  for (const order of orderStore.values()) {
    if (order.status === "succeeded" || order.status === "paid") {
      succeeded += 1;
    }
  }
  return Number(((succeeded / orderStore.size) * 100).toFixed(1));
}

function buildSeriesBucketMap(size) {
  const now = Date.now();
  const bucketMs = 60 * 60 * 1000;
  const buckets = [];
  for (let index = size - 1; index >= 0; index -= 1) {
    const bucketStart = now - (index * bucketMs);
    buckets.push({
      ts: new Date(bucketStart).toISOString(),
      purchases: 0,
      walletTopups: 0,
      walletSpend: 0,
    });
  }
  return { bucketMs, buckets };
}

function assignToSeriesBucket(createdAt, bucketMs, buckets) {
  const ts = Date.parse(createdAt || "");
  if (!Number.isFinite(ts)) {
    return -1;
  }
  const oldestTs = Date.parse(buckets[0]?.ts || "");
  if (!Number.isFinite(oldestTs) || ts < oldestTs) {
    return -1;
  }
  const index = Math.floor((ts - oldestTs) / bucketMs);
  if (index < 0 || index >= buckets.length) {
    return -1;
  }
  return index;
}

// Shared state (posts, mediaJobs, audit) used by both this router and internalRoutes
const { posts, mediaJobs, audit, uploadSessions } = require("./apiState");
const { ppvCommerceMetrics } = require("./monitoring/server/metrics");
const { runReconciliation, resolveMismatch, getLatestRun } = require("./jobs/reconciliation");

const ALLOWED_UPLOAD_TYPES = Object.freeze({
  "image/jpeg": { kind: "image" },
  "image/png": { kind: "image" },
  "image/webp": { kind: "image" },
  "image/gif": { kind: "image" },
  "video/mp4": { kind: "video" },
  "video/quicktime": { kind: "video" },
  "video/x-msvideo": { kind: "video" },
  "video/webm": { kind: "video" },
});
const MEDIA_LIMITS = Object.freeze({
  imageMaxBytes: 25 * 1024 * 1024,
  videoMaxBytes: 2 * 1024 * 1024 * 1024,
  maxImageWidth: 8192,
  maxImageHeight: 8192,
  maxVideoWidth: 3840,
  maxVideoHeight: 3840,
  maxVideoDurationMs: 6 * 60 * 60 * 1000,
  defaultPartSizeBytes: 8 * 1024 * 1024,
  minMultipartPartSizeBytes: 5 * 1024 * 1024,
  maxPartCount: 10000,
  sessionTtlMs: 24 * 60 * 60 * 1000,
  maxJobAttempts: 5,
});

function normalizeContentType(contentType) {
  return String(contentType || "")
    .split(";")[0]
    .trim()
    .toLowerCase();
}

function sanitizeFilename(filename) {
  const sanitized = String(filename || "upload")
    .trim()
    .replace(/[^a-zA-Z0-9._-]/g, "_")
    .slice(0, 160);
  return sanitized || "upload";
}

function parsePositiveInteger(value) {
  if (value == null || value === "") {
    return null;
  }
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return null;
  }
  return Math.round(parsed);
}

function deriveAspectRatio(width, height) {
  if (!width || !height) {
    return null;
  }
  return Number((width / height).toFixed(4));
}

function getUploadTypeSpec(contentType) {
  return ALLOWED_UPLOAD_TYPES[normalizeContentType(contentType)] || null;
}

function buildSignedUploadUrl(key, expiresIn, extraQuery = {}) {
  const S3_BUCKET = process.env.S3_UPLOAD_BUCKET || "dfc-uploads";
  const S3_REGION = process.env.AWS_REGION || "us-east-1";
  const baseUrl = process.env.S3_SIGNED_URL_BASE
    ? `${process.env.S3_SIGNED_URL_BASE}/${key}`
    : `https://${S3_BUCKET}.s3.${S3_REGION}.amazonaws.com/${key}`;
  const query = new URLSearchParams({
    ...(process.env.S3_SIGNED_URL_BASE ? {} : { stub: "1" }),
    "X-Amz-Expires": String(expiresIn),
    ...Object.fromEntries(
      Object.entries(extraQuery).filter(([, value]) => value != null),
    ),
  });
  return `${baseUrl}?${query.toString()}`;
}

function buildVariantPlan(kind, metadata) {
  if (kind === "image") {
    return [320, 640, 1080, 1440].map((width) => ({
      id: `img_${width}`,
      kind: "image",
      format: metadata.contentType,
      width,
      fit: "cover",
      purpose: width <= 640 ? "feed" : "detail",
    }));
  }

  const sourceHeight = metadata.height || 1080;
  const ladder = [
    { id: "video_poster", kind: "image", format: "image/jpeg", width: 640, purpose: "poster" },
    { id: "video_preview", kind: "video", format: "video/mp4", width: 480, height: 854, bitrateKbps: 900, purpose: "preview" },
    { id: "video_480p", kind: "video", format: "video/mp4", width: 854, height: 480, bitrateKbps: 1400, purpose: "feed" },
    { id: "video_720p", kind: "video", format: "video/mp4", width: 1280, height: 720, bitrateKbps: 2800, purpose: "feed" },
    { id: "video_adaptive", kind: "manifest", format: "application/x-mpegURL", purpose: "adaptive" },
  ];

  if (sourceHeight >= 1080) {
    ladder.splice(4, 0, {
      id: "video_1080p",
      kind: "video",
      format: "video/mp4",
      width: 1920,
      height: 1080,
      bitrateKbps: 5000,
      purpose: "detail",
    });
  }

  return ladder;
}

function normalizeUploadMetadata(payload, { requireSizeBytes = false } = {}) {
  const contentType = normalizeContentType(payload.contentType);
  const typeSpec = getUploadTypeSpec(contentType);
  if (!typeSpec) {
    throw new Error("Unsupported file type");
  }

  const sizeBytes = parsePositiveInteger(payload.sizeBytes);
  if (requireSizeBytes && !sizeBytes) {
    throw new Error("sizeBytes is required");
  }

  const width = parsePositiveInteger(payload.width);
  const height = parsePositiveInteger(payload.height);
  const durationMs = parsePositiveInteger(payload.durationMs);
  const chunkSizeBytes = parsePositiveInteger(payload.chunkSizeBytes);
  const checksum = typeof payload.checksum === "string" ? payload.checksum.trim().slice(0, 256) : null;
  const sourceDevice = typeof payload.sourceDevice === "string"
    ? payload.sourceDevice.trim().slice(0, 120)
    : null;
  const resumable = payload.resumable !== false;

  if (width && height) {
    const maxWidth = typeSpec.kind === "image" ? MEDIA_LIMITS.maxImageWidth : MEDIA_LIMITS.maxVideoWidth;
    const maxHeight = typeSpec.kind === "image" ? MEDIA_LIMITS.maxImageHeight : MEDIA_LIMITS.maxVideoHeight;
    if (width > maxWidth || height > maxHeight) {
      throw new Error("Media dimensions exceed supported limits");
    }
  }

  if (typeSpec.kind === "video" && durationMs && durationMs > MEDIA_LIMITS.maxVideoDurationMs) {
    throw new Error("Video duration exceeds supported limits");
  }

  if (sizeBytes) {
    const maxBytes = typeSpec.kind === "image" ? MEDIA_LIMITS.imageMaxBytes : MEDIA_LIMITS.videoMaxBytes;
    if (sizeBytes > maxBytes) {
      throw new Error("Media file exceeds supported size limits");
    }
  }

  return {
    contentType,
    mediaKind: typeSpec.kind,
    sizeBytes,
    width,
    height,
    durationMs,
    checksum,
    sourceDevice,
    resumable,
    chunkSizeBytes,
    aspectRatio: deriveAspectRatio(width, height),
  };
}

function pruneExpiredUploadSessions() {
  const now = Date.now();
  for (const uploadId of Object.keys(uploadSessions)) {
    const session = uploadSessions[uploadId];
    if (session?.expiresAt && Date.parse(session.expiresAt) <= now) {
      delete uploadSessions[uploadId];
    }
  }
}

function createUploadSession(payload, options = {}) {
  const filename = String(payload.filename || "").trim();
  const userId = String(payload.userId || "").trim();
  if (!filename || !userId) {
    throw new Error("filename, contentType, and userId are required");
  }

  pruneExpiredUploadSessions();

  const metadata = normalizeUploadMetadata(payload, options);
  const uploadId = uuid();
  const safeFilename = sanitizeFilename(filename);
  const key = `uploads/originals/${userId}/${uploadId}_${safeFilename}`;
  const expiresAt = new Date(Date.now() + MEDIA_LIMITS.sessionTtlMs).toISOString();
  const preferredPartSize = Math.max(
    MEDIA_LIMITS.minMultipartPartSizeBytes,
    metadata.chunkSizeBytes || MEDIA_LIMITS.defaultPartSizeBytes,
  );
  const partsTotal = metadata.resumable && metadata.sizeBytes
    ? Math.max(1, Math.ceil(metadata.sizeBytes / preferredPartSize))
    : 1;

  if (partsTotal > MEDIA_LIMITS.maxPartCount) {
    throw new Error("Upload would exceed supported multipart count");
  }

  const session = {
    id: uploadId,
    uploadId,
    userId,
    filename,
    safeFilename,
    key,
    status: partsTotal > 1 ? "initialized" : "ready_for_upload",
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    expiresAt,
    partSizeBytes: partsTotal > 1 ? preferredPartSize : null,
    partsTotal,
    completedParts: [],
    linkedPostIds: [],
    metadata: {
      ...metadata,
      variants: buildVariantPlan(metadata.mediaKind, metadata),
    },
  };

  uploadSessions[uploadId] = session;
  return session;
}

function buildUploadSessionResponse(session, { includeParts = false, partNumbers } = {}) {
  const expiresIn = Math.max(1, Math.round((Date.parse(session.expiresAt) - Date.now()) / 1000));
  const requestedPartNumbers = Array.isArray(partNumbers) && partNumbers.length
    ? partNumbers
    : [1];

  return {
    uploadId: session.uploadId,
    status: session.status,
    userId: session.userId,
    key: session.key,
    mediaKind: session.metadata.mediaKind,
    contentType: session.metadata.contentType,
    sizeBytes: session.metadata.sizeBytes,
    width: session.metadata.width,
    height: session.metadata.height,
    durationMs: session.metadata.durationMs,
    aspectRatio: session.metadata.aspectRatio,
    resumable: session.partsTotal > 1,
    partSizeBytes: session.partSizeBytes,
    partsTotal: session.partsTotal,
    completedParts: session.completedParts,
    variants: session.metadata.variants,
    expiresAt: session.expiresAt,
    expiresIn,
    signedUrl: session.partsTotal === 1 ? buildSignedUploadUrl(session.key, expiresIn) : null,
    parts: includeParts
      ? requestedPartNumbers.map((partNumber) => ({
          partNumber,
          signedUrl: buildSignedUploadUrl(session.key, expiresIn, { partNumber }),
          expiresIn,
          headers: {
            "content-type": session.metadata.contentType,
            "x-upload-id": session.uploadId,
          },
        }))
      : undefined,
  };
}

function getUploadSession(uploadId) {
  pruneExpiredUploadSessions();
  if (!uploadId || !Object.hasOwn(uploadSessions, uploadId)) {
    return null;
  }
  return uploadSessions[uploadId];
}

function getUploadSessionByKey(key) {
  pruneExpiredUploadSessions();
  for (const uploadId of Object.keys(uploadSessions)) {
    const session = uploadSessions[uploadId];
    if (session?.key === key) {
      return session;
    }
  }
  return null;
}

function buildPostMediaRecord(uploadSession, fallbackKey) {
  if (!uploadSession && !fallbackKey) {
    return null;
  }

  if (!uploadSession) {
    return {
      uploadId: null,
      key: fallbackKey,
      contentType: null,
      mediaKind: null,
      sizeBytes: null,
      width: null,
      height: null,
      durationMs: null,
      aspectRatio: null,
      variants: [],
      uploadStatus: "unknown",
      sourceDevice: null,
      checksum: null,
    };
  }

  return {
    uploadId: uploadSession.uploadId,
    key: uploadSession.key,
    contentType: uploadSession.metadata.contentType,
    mediaKind: uploadSession.metadata.mediaKind,
    sizeBytes: uploadSession.metadata.sizeBytes,
    width: uploadSession.metadata.width,
    height: uploadSession.metadata.height,
    durationMs: uploadSession.metadata.durationMs,
    aspectRatio: uploadSession.metadata.aspectRatio,
    variants: uploadSession.metadata.variants,
    uploadStatus: uploadSession.status,
    sourceDevice: uploadSession.metadata.sourceDevice,
    checksum: uploadSession.metadata.checksum,
  };
}

function buildMediaJobPayload({ jobId, postId, postRecord, uploadSession }) {
  const media = postRecord.media || null;
  return {
    contractVersion: "2026-05-05.media-v1",
    jobId,
    postId,
    callbacks: {
      completePath: "/internal/media-complete",
      secretEnvVar: "WORKER_CALLBACK_SECRET",
    },
    source: {
      uploadId: media?.uploadId || uploadSession?.uploadId || null,
      key: media?.key || uploadSession?.key || null,
      contentType: media?.contentType || uploadSession?.metadata.contentType || null,
      mediaKind: media?.mediaKind || uploadSession?.metadata.mediaKind || null,
      sizeBytes: media?.sizeBytes || uploadSession?.metadata.sizeBytes || null,
      width: media?.width || uploadSession?.metadata.width || null,
      height: media?.height || uploadSession?.metadata.height || null,
      durationMs: media?.durationMs || uploadSession?.metadata.durationMs || null,
      checksum: media?.checksum || uploadSession?.metadata.checksum || null,
      sourceDevice: media?.sourceDevice || uploadSession?.metadata.sourceDevice || null,
      uploadStatus: media?.uploadStatus || uploadSession?.status || "unknown",
    },
    transforms: {
      variants: media?.variants || uploadSession?.metadata.variants || [],
      extractPosterFrame: (media?.mediaKind || uploadSession?.metadata.mediaKind) === "video",
      normalizeOrientation: true,
    },
    moderation: {
      required: true,
      profile: (media?.mediaKind || uploadSession?.metadata.mediaKind) === "video" ? "video_safe_publish" : "image_safe_publish",
    },
  };
}

function queueMediaProcessingJob({ postId, postRecord, uploadSession }) {
  const jobId = uuid();
  const canProcessNow = !uploadSession || uploadSession.status === "uploaded" || uploadSession.status === "attached";
  mediaJobs[jobId] = {
    jobId,
    postId,
    uploadId: uploadSession?.uploadId || postRecord.media?.uploadId || null,
    mediaKey: postRecord.media?.key || uploadSession?.key || null,
    status: canProcessNow ? "queued" : "awaiting_upload",
    attempts: 0,
    maxAttempts: MEDIA_LIMITS.maxJobAttempts,
    retryEligible: true,
    nextAttemptAt: Date.now(),
    enqueuedAt: Date.now(),
    payload: buildMediaJobPayload({ jobId, postId, postRecord, uploadSession }),
  };
  return jobId;
}

function releaseAwaitingJobsForUpload(uploadId) {
  for (const jobId of Object.keys(mediaJobs)) {
    const job = mediaJobs[jobId];
    if (job.uploadId === uploadId && job.status === "awaiting_upload") {
      job.status = "queued";
      job.nextAttemptAt = Date.now();
      job.updatedAt = Date.now();
      if (job.payload?.source) {
        job.payload.source.uploadStatus = "uploaded";
      }
    }
  }
}

router.get("/kpis", (req, res) => {
  const wallet = walletSummary();
  const successRate = computePurchaseSuccessRate();

  res.json({
    alertLatency: 120,
    p95Latency: 2500,
    successRate,
    activeEngines: 12,
    commerce: {
      orders: orderStore.size,
      purchases: purchaseStore.size,
      entitlements: entitlementStore.size,
      webhookDlqDepth: webhookDLQ.size,
      purchaseSuccessRate: successRate,
    },
    wallet,
    updatedAt: new Date().toISOString(),
  });
});

router.get("/kpis/series", (req, res) => {
  const hours = Math.min(Math.max(Number(req.query.hours || 24), 1), 168);
  const { bucketMs, buckets } = buildSeriesBucketMap(hours);

  for (const purchase of purchaseStore.values()) {
    const index = assignToSeriesBucket(purchase.createdAt, bucketMs, buckets);
    if (index >= 0) {
      buckets[index].purchases += 1;
    }
  }

  for (const tx of walletTransactions.values()) {
    const index = assignToSeriesBucket(tx.createdAt, bucketMs, buckets);
    if (index < 0) {
      continue;
    }
    if (tx.type === "topup") {
      buckets[index].walletTopups += 1;
    }
    if (tx.type === "debit") {
      buckets[index].walletSpend += 1;
    }
  }

  return res.json({
    hours,
    series: buckets,
  });
});

router.get("/kpis/summary", (req, res) => {
  const period = typeof req.query.period === "string"
    ? req.query.period
    : "1h";
  const periodMs = parsePeriodMs(period);
  const cutoff = Date.now() - periodMs;

  const recentOrders = [...orderStore.values()].filter((entry) =>
    Date.parse(entry.createdAt || "") >= cutoff,
  );
  const recentPurchases = [...purchaseStore.values()].filter((entry) =>
    Date.parse(entry.createdAt || "") >= cutoff,
  );
  const recentWalletTopups = [...walletTransactions.values()].filter((entry) =>
    entry.type === "topup" && Date.parse(entry.createdAt || "") >= cutoff,
  );
  const recentWalletPurchases = [...micropurchases.values()].filter((entry) =>
    Date.parse(entry.createdAt || "") >= cutoff,
  );

  const recentMediaDurations = Object.values(mediaJobs)
    .filter(
      (job) =>
        job &&
        Number.isFinite(job.enqueuedAt) &&
        Number.isFinite(job.completedAt) &&
        job.completedAt >= cutoff,
    )
    .map((job) => Math.max(0, Number(job.completedAt) - Number(job.enqueuedAt)));

  const recentForensics = webhookForensics
    .filter((entry) => entry.ts >= cutoff)
    .slice(-50)
    .reverse();

  const recentSignatureFailures = recentForensics.length;
  const checkoutSessions = recentOrders.length;
  const checkoutSuccesses = recentPurchases.length;
  const successRate = checkoutSessions > 0
    ? Number((checkoutSuccesses / checkoutSessions).toFixed(4))
    : 1;

  return res.json({
    period,
    generatedAt: new Date().toISOString(),
    checkout: {
      sessions: checkoutSessions,
      successes: checkoutSuccesses,
      successRate,
      webhookSignatureFailures: recentSignatureFailures,
    },
    wallet: {
      topups: recentWalletTopups.length,
      purchases: recentWalletPurchases.length,
      balanceCents: [...walletStore.values()].reduce(
        (sum, wallet) => sum + Number(wallet.balanceCents || 0),
        0,
      ),
    },
    poster: {
      jobsReady: Object.values(mediaJobs).filter(
        (job) => job?.status === "ready" && Number(job.completedAt) >= cutoff,
      ).length,
      jobsFailed: Object.values(mediaJobs).filter(
        (job) => job?.status === "failed" && Number(job.completedAt) >= cutoff,
      ).length,
      p95Ms: percentile(recentMediaDurations, 95),
      errors: Object.values(mediaJobs).filter(
        (job) => job?.status === "failed" && Number(job.completedAt) >= cutoff,
      ).length,
    },
    forensics: {
      recentWebhookFailures: recentForensics,
    },
  });
});

router.post("/offers/generate", express.json(), generateOfferHandler);
router.post("/creative/generate", express.json(), generateCreativeHandler);
router.use("/offers/ab", abRunnerRouter);
router.use(
  "/analytics",
  createAnalyticsEmitRouter({ audit, ppvCommerceMetrics, forwardToMeta, getConsentState })
);

// ── Admin: approve offer ────────────────────────────────────────────────────
router.post("/offers/approve", express.json(), (req, res) => {
  const { offerId, reviewerId } = req.body || {};
  if (!offerId) return res.status(400).json({ error: "offerId required" });
  res.json({
    offerId,
    reviewStatus: "approved",
    requiresReview: false,
    active: true,
    published: true,
    publishedAt: new Date().toISOString(),
    reviewedBy: reviewerId || "admin",
  });
});

// ── Admin: approve creative ─────────────────────────────────────────────────
router.post("/creative/approve", express.json(), (req, res) => {
  const { templateId, reviewerId } = req.body || {};
  if (!templateId) return res.status(400).json({ error: "templateId required" });
  res.json({
    templateId,
    reviewStatus: "approved",
    requiresReview: false,
    published: true,
    publishedAt: new Date().toISOString(),
    reviewedBy: reviewerId || "admin",
  });
});

router.post("/orders/create", express.json(), (req, res) => {
  const {
    eventId,
    userId,
    amountCents,
    tierId,
    promotionId = null,
  } = req.body || {};

  if (!eventId || !userId || amountCents == null || !tierId) {
    return res.status(400).json({
      error: "eventId, userId, amountCents, and tierId are required",
    });
  }

  const orderId = uuid();
  const paymentIntentId = `pi_${uuid().replaceAll("-", "")}`;
  orderStore.set(orderId, {
    orderId,
    paymentIntentId,
    eventId,
    userId,
    amountCents: Number(amountCents),
    tierId,
    promotionId,
    status: "requires_confirmation",
    createdAt: new Date().toISOString(),
  });
  ppvCommerceMetrics.purchaseAttempts.inc({ source: "api_orders_create" });

  return res.status(201).json({
    orderId,
    paymentIntentId,
    paymentLink: `/checkout/${orderId}`,
    status: "requires_confirmation",
  });
});

router.post("/orders/webhook", express.json(), (req, res) => {
  const { orderId, paymentIntentId, eventId, userId, status } = req.body || {};
  const order = orderId ? orderStore.get(orderId) : null;

  const resolvedOrder = order || {
    orderId: orderId || uuid(),
    paymentIntentId: paymentIntentId || `pi_${uuid().replaceAll("-", "")}`,
    eventId,
    userId,
    status: status || "succeeded",
  };

  if (!resolvedOrder.eventId || !resolvedOrder.userId) {
    // Push to DLQ on validation failure
    const dlqKey = resolvedOrder.orderId;
    const existing = webhookDLQ.get(dlqKey) || { attempts: 0 };
    if (existing.attempts < MAX_WEBHOOK_ATTEMPTS) {
      webhookDLQ.set(dlqKey, {
        attempts: existing.attempts + 1,
        lastError: "Missing eventId or userId",
        payload: req.body,
        enqueuedAt: existing.enqueuedAt || new Date().toISOString(),
        nextRetryAt: new Date(Date.now() + (existing.attempts + 1) * 30_000).toISOString(),
      });
    }
    ppvCommerceMetrics.webhookErrors.inc({ reason: "missing_order_identity" });
    ppvCommerceMetrics.dlqSize.set({ status: "memory" }, webhookDLQ.size);
    return res.status(400).json({
      error: "Resolved order must include eventId and userId",
      dlq: true,
    });
  }

  resolvedOrder.status = status || "succeeded";
  orderStore.set(resolvedOrder.orderId, resolvedOrder);

  if (resolvedOrder.status === "succeeded") {
    ppvCommerceMetrics.purchaseSuccess.inc({ source: "api_orders_webhook" });
    // Remove from DLQ on success
    webhookDLQ.delete(resolvedOrder.orderId);
    ppvCommerceMetrics.dlqSize.set({ status: "memory" }, webhookDLQ.size);
  }

  const entitlementKey = `${resolvedOrder.userId}_${resolvedOrder.eventId}`;
  const entitlement = {
    id: entitlementKey,
    userId: resolvedOrder.userId,
    eventId: resolvedOrder.eventId,
    purchaseId: resolvedOrder.orderId,
    accessType: "ppv",
    status: "active",
    createdAt: new Date().toISOString(),
  };
  entitlementStore.set(entitlementKey, entitlement);
  ppvCommerceMetrics.entitlementGranted.inc({ source: "api_orders_webhook" });

  return res.json({
    ok: true,
    orderId: resolvedOrder.orderId,
    entitlementId: entitlement.id,
    status: entitlement.status,
  });
});

// ── Webhook DLQ: inspect and retry failed webhooks ─────────────────────────
router.get("/orders/webhook/dlq", (_req, res) => {
  const items = [...webhookDLQ.entries()].map(([key, val]) => ({
    orderId: key,
    ...val,
  }));
  res.json({ count: items.length, items });
});

router.post("/orders/webhook/retry", express.json(), (req, res) => {
  const { orderId } = req.body || {};
  if (!orderId) return res.status(400).json({ error: "orderId required" });
  const item = webhookDLQ.get(orderId);
  if (!item) return res.status(404).json({ error: "Not in DLQ" });
  if (item.attempts >= MAX_WEBHOOK_ATTEMPTS) {
    ppvCommerceMetrics.webhookErrors.inc({ reason: "max_retry_reached" });
    return res.status(409).json({ error: "Max retry attempts reached", item });
  }
  // Re-enqueue by delegating back through the same handler logic
  item.attempts += 1;
  item.nextRetryAt = new Date(Date.now() + item.attempts * 30_000).toISOString();
  webhookDLQ.set(orderId, item);
  // Simulate re-processing the payload
  const { eventId, userId } = item.payload || {};
  if (eventId && userId) {
    const entitlementKey = `${userId}_${eventId}`;
    entitlementStore.set(entitlementKey, {
      id: entitlementKey,
      userId,
      eventId,
      purchaseId: orderId,
      accessType: "ppv",
      status: "active",
      createdAt: new Date().toISOString(),
      retriedAt: new Date().toISOString(),
    });
    ppvCommerceMetrics.entitlementGranted.inc({ source: "dlq_retry" });
    webhookDLQ.delete(orderId);
    ppvCommerceMetrics.dlqSize.set({ status: "memory" }, webhookDLQ.size);
    return res.json({ ok: true, orderId, retried: true, entitlementKey });
  }
  ppvCommerceMetrics.webhookErrors.inc({ reason: "retry_payload_invalid" });
  return res.status(422).json({ error: "Payload still invalid", item });
});

router.post("/split/calc", express.json(), (req, res) => {
  const { saleAmount, rate = 0.2 } = req.body || {};
  if (saleAmount == null) {
    return res.status(400).json({ error: "saleAmount is required" });
  }

  const numericAmount = Number(saleAmount);
  const platformShare = Math.round(numericAmount * Number(rate));
  return res.json({
    saleAmount: numericAmount,
    platformShare,
    promoterShare: numericAmount - platformShare,
  });
});

router.post("/ppv/create-session", requireApiAuth, express.json(), async (req, res) => {
  const { eventId, priceCents, currency = "USD", userId } = req.body || {};
  if (!eventId || priceCents == null) {
    return res.status(400).json({
      error: "eventId and priceCents are required",
    });
  }

  const resolvedUserId = userId || req.authUserId || "guest";
  if (req.authUserId && resolvedUserId !== req.authUserId) {
    return res.status(403).json({ error: "user mismatch" });
  }

  const sessionId = `cs_${uuid().replaceAll("-", "")}`;
  const sku = `PPV-${eventId}`;
  let checkoutUrl = `https://checkout.example/checkout?session=${sessionId}&sku=${sku}`;

  const stripe = getStripeClient();
  if (stripe) {
    try {
      const session = await stripe.checkout.sessions.create({
        mode: "payment",
        success_url: `${CHECKOUT_BASE_URL}/checkout/success?session_id={CHECKOUT_SESSION_ID}`,
        cancel_url: `${CHECKOUT_BASE_URL}/checkout/cancel`,
        line_items: [
          {
            quantity: 1,
            price_data: {
              currency: String(currency).toLowerCase(),
              unit_amount: Number(priceCents),
              product_data: {
                name: `DFC PPV Event ${eventId}`,
              },
            },
          },
        ],
        metadata: {
          eventId: String(eventId),
          userId: String(resolvedUserId),
          sku,
        },
      });
      checkoutUrl = session.url || checkoutUrl;
    } catch {
      // Keep fallback URL for local or non-Stripe lanes.
    }
  }

  orderStore.set(sessionId, {
    id: sessionId,
    eventId,
    userId: resolvedUserId,
    priceCents: Number(priceCents),
    currency,
    status: "pending",
    createdAt: new Date().toISOString(),
  });

  ppvCommerceMetrics.purchaseAttempts.inc({ source: "api_ppv_create_session" });
  ppvCommerceMetrics.checkoutSessions.inc({
    provider: stripe ? "stripe" : "stub",
    source: "api_ppv_create_session",
  });
  return res.status(201).json({
    sessionId,
    checkoutUrl,
    sku,
    provider: stripe ? "stripe" : "stub",
    status: "pending",
  });
});

router.post("/wallet/topup", requireApiAuth, express.json(), async (req, res) => {
  const {
    userId,
    amountCents,
    currency = "USD",
    provider = "stripe",
    idempotencyKey,
  } = req.body || {};

  if (!userId || amountCents == null) {
    return res.status(400).json({ error: "userId and amountCents are required" });
  }
  if (Number(amountCents) <= 0) {
    return res.status(400).json({ error: "amountCents must be greater than 0" });
  }
  if (!idempotencyKey) {
    return res.status(400).json({ error: "idempotencyKey is required" });
  }
  if (req.authUserId && req.authUserId !== userId) {
    return res.status(403).json({ error: "user mismatch" });
  }

  const idemKey = `wallet_topup:${userId}:${idempotencyKey}`;
  if (walletIdempotencyStore.has(idemKey)) {
    return res.json(walletIdempotencyStore.get(idemKey));
  }

  const wallet = getOrCreateWallet(userId, currency);
  const walletTx = createWalletTransaction({
    userId,
    type: "topup_pending",
    provider,
    amountCents,
    currency: wallet.currency,
    metadata: { idempotencyKey },
  });

  let checkoutUrl = `${CHECKOUT_BASE_URL}/wallet/topup?walletTxId=${walletTx.id}`;
  if (provider === "stripe") {
    const stripe = getStripeClient();
    if (stripe) {
      try {
        const session = await stripe.checkout.sessions.create({
          mode: "payment",
          success_url: `${CHECKOUT_BASE_URL}/wallet/success?session_id={CHECKOUT_SESSION_ID}`,
          cancel_url: `${CHECKOUT_BASE_URL}/wallet/cancel`,
          line_items: [
            {
              quantity: 1,
              price_data: {
                currency: String(currency).toLowerCase(),
                unit_amount: Number(amountCents),
                product_data: { name: `DFC Wallet Topup ${userId}` },
              },
            },
          ],
          metadata: {
            userId,
            walletTxId: String(walletTx.id),
            mode: "wallet_topup",
          },
        });
        checkoutUrl = session.url || checkoutUrl;
      } catch {
        // Keep fallback URL for local/dev.
      }
    }
  }

  if (provider === "paypal") {
    checkoutUrl = `${CHECKOUT_BASE_URL}/wallet/topup/paypal?walletTxId=${walletTx.id}`;
  }

  const responsePayload = {
    ok: true,
    walletTxId: walletTx.id,
    userId,
    amountCents: Number(amountCents),
    currency: wallet.currency,
    provider,
    checkoutUrl,
  };
  ppvCommerceMetrics.walletTopup.inc({ provider, source: "api_wallet_topup" });
  walletIdempotencyStore.set(idemKey, responsePayload);
  return res.status(201).json(responsePayload);
});

router.post("/wallet/topup/confirm", webhookRateLimiter, express.json(), (req, res) => {
  const {
    userId,
    walletTxId,
    provider = "stripe",
    providerId = null,
    amountCents,
    currency = "USD",
    idempotencyKey,
    status = "completed",
  } = req.body || {};

  if (!userId || !walletTxId || amountCents == null) {
    return res.status(400).json({ error: "userId, walletTxId, and amountCents are required" });
  }
  if (!idempotencyKey) {
    return res.status(400).json({ error: "idempotencyKey is required" });
  }

  const idemKey = `wallet_topup_confirm:${userId}:${idempotencyKey}`;
  if (walletIdempotencyStore.has(idemKey)) {
    return res.json(walletIdempotencyStore.get(idemKey));
  }

  if (status !== "completed") {
    return res.status(400).json({ error: "topup not completed" });
  }

  const wallet = getOrCreateWallet(userId, currency);
  wallet.balanceCents += Number(amountCents);
  wallet.updatedAt = new Date().toISOString();
  walletStore.set(userId, wallet);

  const tx = createWalletTransaction({
    userId,
    type: "topup",
    provider,
    providerId,
    amountCents,
    currency: wallet.currency,
    metadata: { walletTxId },
  });

  const responsePayload = {
    ok: true,
    wallet: { ...wallet },
    transaction: tx,
  };
  ppvCommerceMetrics.walletBalanceCents.set(
    { user: userId, currency: wallet.currency },
    wallet.balanceCents,
  );
  walletIdempotencyStore.set(idemKey, responsePayload);
  return res.json(responsePayload);
});

router.post("/wallet/purchase", requireApiAuth, express.json(), (req, res) => {
  const {
    userId,
    itemId,
    amountCents,
    currency = "USD",
    idempotencyKey,
  } = req.body || {};

  if (!userId || !itemId || amountCents == null) {
    return res.status(400).json({ error: "userId, itemId, and amountCents are required" });
  }
  if (!idempotencyKey) {
    return res.status(400).json({ error: "idempotencyKey is required" });
  }
  if (Number(amountCents) <= 0) {
    return res.status(400).json({ error: "amountCents must be greater than 0" });
  }
  if (req.authUserId && req.authUserId !== userId) {
    return res.status(403).json({ error: "user mismatch" });
  }

  const idemKey = `wallet_purchase:${userId}:${idempotencyKey}`;
  if (walletIdempotencyStore.has(idemKey)) {
    return res.json(walletIdempotencyStore.get(idemKey));
  }

  const wallet = getOrCreateWallet(userId, currency);
  if (wallet.balanceCents < Number(amountCents)) {
    return res.status(402).json({ error: "insufficient_funds" });
  }

  wallet.balanceCents -= Number(amountCents);
  wallet.updatedAt = new Date().toISOString();
  walletStore.set(userId, wallet);

  const debitTx = createWalletTransaction({
    userId,
    type: "debit",
    amountCents,
    currency: wallet.currency,
    metadata: { itemId },
  });

  const entitlementKey = `${userId}_${itemId}`;
  const entitlement = {
    id: entitlementKey,
    userId,
    eventId: itemId,
    purchaseId: debitTx.id,
    accessType: "micro",
    status: "active",
    grantedAt: new Date().toISOString(),
  };
  entitlementStore.set(entitlementKey, entitlement);

  const micropurchase = createMicropurchase({
    userId,
    itemId,
    amountCents,
    currency: wallet.currency,
    walletTxId: debitTx.id,
    entitlementId: entitlement.id,
  });

  const responsePayload = {
    ok: true,
    wallet: { ...wallet },
    transaction: debitTx,
    micropurchase,
    entitlement,
  };
  ppvCommerceMetrics.walletSpend.inc({ source: "api_wallet_purchase" });
  ppvCommerceMetrics.walletBalanceCents.set(
    { user: userId, currency: wallet.currency },
    wallet.balanceCents,
  );
  walletIdempotencyStore.set(idemKey, responsePayload);
  return res.json(responsePayload);
});

router.get("/wallet/:userId", requireApiAuth, (req, res) => {
  const { userId } = req.params;
  if (req.authUserId && req.authUserId !== userId) {
    return res.status(403).json({ error: "user mismatch" });
  }

  const wallet = getOrCreateWallet(userId);
  const transactions = [...walletTransactions.values()]
    .filter((tx) => tx.userId === userId)
    .sort((a, b) => (a.id < b.id ? 1 : -1))
    .slice(0, 50);

  return res.json({
    userId,
    balanceCents: wallet.balanceCents,
    currency: wallet.currency,
    updatedAt: wallet.updatedAt,
    transactions,
  });
});

router.post("/paypal/create-order", requireApiAuth, express.json(), async (req, res) => {
  const { eventId, amountCents, currency = "USD", userId } = req.body || {};
  if (!eventId || amountCents == null) {
    return res.status(400).json({ error: "eventId and amountCents are required" });
  }

  const resolvedUserId = userId || req.authUserId || "guest";
  if (req.authUserId && resolvedUserId !== req.authUserId) {
    return res.status(403).json({ error: "user mismatch" });
  }

  const orderId = `paypal_${uuid().replaceAll("-", "")}`;
  const fallbackApproveUrl = `${CHECKOUT_BASE_URL}/checkout/paypal?orderId=${orderId}`;
  const paypal = getPayPalClient();

  if (!paypal) {
    ppvCommerceMetrics.checkoutSessions.inc({
      provider: "paypal_stub",
      source: "api_paypal_create_order",
    });
    return res.status(201).json({
      id: orderId,
      status: "CREATED",
      provider: "paypal_stub",
      links: [
        { rel: "approve", href: fallbackApproveUrl, method: "GET" },
      ],
    });
  }

  const sdk = getPayPalSdk();
  const request = new sdk.orders.OrdersCreateRequest();
  request.prefer("return=representation");
  request.requestBody({
    intent: "CAPTURE",
    purchase_units: [
      {
        reference_id: `PPV-${eventId}`,
        custom_id: `eventId=${eventId};userId=${resolvedUserId}`,
        amount: {
          currency_code: String(currency).toUpperCase(),
          value: (Number(amountCents) / 100).toFixed(2),
        },
      },
    ],
    application_context: {
      return_url: `${CHECKOUT_BASE_URL}/pay/paypal/return`,
      cancel_url: `${CHECKOUT_BASE_URL}/pay/cancel`,
    },
  });

  try {
    const order = await paypal.execute(request);
    ppvCommerceMetrics.checkoutSessions.inc({
      provider: "paypal",
      source: "api_paypal_create_order",
    });
    return res.status(201).json({
      id: order.result.id,
      status: order.result.status,
      provider: "paypal",
      links: order.result.links || [],
    });
  } catch (error) {
    return res.status(502).json({
      error: "paypal_create_order_failed",
      message: error?.message || "unable to create paypal order",
    });
  }
});

router.post("/paypal/capture", requireApiAuth, express.json(), async (req, res) => {
  const entitlementStartedAt = Date.now();
  const { orderId, eventId, userId, amountCents } = req.body || {};
  if (!orderId || !eventId) {
    return res.status(400).json({ error: "orderId and eventId are required" });
  }

  const resolvedUserId = userId || req.authUserId;
  if (!resolvedUserId) {
    return res.status(400).json({ error: "userId is required" });
  }
  if (req.authUserId && req.authUserId !== resolvedUserId) {
    return res.status(403).json({ error: "user mismatch" });
  }

  let capturePayload = { id: orderId, status: "COMPLETED" };
  const paypal = getPayPalClient();
  if (paypal) {
    try {
      const sdk = getPayPalSdk();
      const request = new sdk.orders.OrdersCaptureRequest(orderId);
      request.requestBody({});
      const capture = await paypal.execute(request);
      capturePayload = capture.result || capturePayload;
    } catch (error) {
      return res.status(502).json({
        error: "paypal_capture_failed",
        message: error?.message || "unable to capture paypal order",
      });
    }
  }

  const purchaseId = `purchase_${uuid().replaceAll("-", "")}`;
  const purchase = {
    id: purchaseId,
    sessionId: orderId,
    eventId: Number(eventId),
    userId: resolvedUserId,
    amountCents: Number(amountCents || 0),
    status: "paid",
    sku: `PPV-${eventId}`,
    provider: "paypal",
    providerId: capturePayload.id || orderId,
    createdAt: new Date().toISOString(),
  };
  purchaseStore.set(purchaseId, purchase);

  const entitlementKey = `${resolvedUserId}_${eventId}`;
  const entitlement = {
    id: entitlementKey,
    userId: resolvedUserId,
    eventId: Number(eventId),
    purchaseId,
    accessType: "ppv",
    status: "active",
    grantedAt: new Date().toISOString(),
  };
  entitlementStore.set(entitlementKey, entitlement);

  ppvCommerceMetrics.purchaseSuccess.inc({ source: "api_paypal_capture" });
  ppvCommerceMetrics.checkoutSuccess.inc({
    provider: "paypal",
    source: "api_paypal_capture",
  });
  ppvCommerceMetrics.entitlementGranted.inc({ source: "api_paypal_capture" });
  ppvCommerceMetrics.entitlementGrantLatencySeconds.observe(
    { provider: "paypal", source: "api_paypal_capture" },
    (Date.now() - entitlementStartedAt) / 1000,
  );

  return res.json({ ok: true, provider: "paypal", capture: capturePayload, entitlement });
});

router.post("/paypal/webhook", webhookRateLimiter, express.json(), async (req, res) => {
  const entitlementStartedAt = Date.now();
  const requestId = getRequestId(req);
  const verified = await verifyPayPalWebhookSignature(req.headers, req.body || {});

  if (PAYPAL_REQUIRE_WEBHOOK_VERIFY && !verified) {
    ppvCommerceMetrics.webhookVerification.inc({ provider: "paypal", result: "invalid" });
    ppvCommerceMetrics.webhookErrors.inc({ reason: "paypal_signature_invalid" });
    ppvCommerceMetrics.webhookSignatureFailures.inc({
      provider: "paypal",
      reason: "invalid_signature",
    });
    recordWebhookSignatureFailure({
      provider: "paypal",
      reason: "invalid_signature",
      requestId,
      req,
    });
    console.warn("paypal_signature_invalid", {
      requestId,
      ip: getClientKey(req),
      rawHeaders: req.rawHeaders,
    });
    return res.status(400).json({ error: "invalid paypal signature" });
  }
  ppvCommerceMetrics.webhookVerification.inc({ provider: "paypal", result: "valid" });

  const payment = extractPayPalEventDetails(req.body || {});
  if (!payment?.eventId || !payment?.userId || !payment?.amountCents) {
    ppvCommerceMetrics.webhookErrors.inc({ reason: "paypal_payload_invalid" });
    return res.status(400).json({
      error: "eventId, userId, and amountCents are required",
    });
  }

  const purchaseId = `purchase_${uuid().replaceAll("-", "")}`;
  const purchase = {
    id: purchaseId,
    sessionId: payment.providerId,
    eventId: payment.eventId,
    userId: payment.userId,
    amountCents: payment.amountCents,
    status: payment.status,
    sku: `PPV-${payment.eventId}`,
    provider: "paypal",
    providerId: payment.providerId,
    createdAt: new Date().toISOString(),
  };
  purchaseStore.set(purchaseId, purchase);

  const entitlementKey = `${payment.userId}_${payment.eventId}`;
  const entitlement = {
    id: entitlementKey,
    userId: payment.userId,
    eventId: payment.eventId,
    purchaseId,
    accessType: "ppv",
    status: "active",
    grantedAt: new Date().toISOString(),
  };
  entitlementStore.set(entitlementKey, entitlement);

  ppvCommerceMetrics.purchaseSuccess.inc({ source: "api_paypal_webhook" });
  ppvCommerceMetrics.checkoutSuccess.inc({
    provider: "paypal",
    source: "api_paypal_webhook",
  });
  ppvCommerceMetrics.entitlementGranted.inc({ source: "api_paypal_webhook" });
  ppvCommerceMetrics.entitlementGrantLatencySeconds.observe(
    { provider: "paypal", source: "api_paypal_webhook" },
    (Date.now() - entitlementStartedAt) / 1000,
  );
  return res.json({ ok: true, verified, purchase, entitlement });
});

router.post("/webhook/payment", webhookRateLimiter, express.raw({ type: "application/json" }), (req, res) => {
  const entitlementStartedAt = Date.now();
  const stripe = getStripeClient();
  const rawBody = getWebhookBodyString(req);
  const signature = req.headers["stripe-signature"];
  const requestId = getRequestId(req);

  if (stripe && STRIPE_WEBHOOK_SECRET && !signature) {
    ppvCommerceMetrics.webhookVerification.inc({ provider: "stripe", result: "missing" });
    ppvCommerceMetrics.webhookErrors.inc({ reason: "stripe_signature_missing" });
    ppvCommerceMetrics.webhookSignatureFailures.inc({
      provider: "stripe",
      reason: "missing_signature",
    });
    recordWebhookSignatureFailure({
      provider: "stripe",
      reason: "missing_signature",
      requestId,
      req,
    });
    console.warn("stripe_signature_missing", {
      requestId,
      ip: getClientKey(req),
      rawHeaders: req.rawHeaders,
    });
    return res.status(400).json({ error: "missing stripe signature" });
  }

  let payload;
  if (stripe && STRIPE_WEBHOOK_SECRET && signature) {
    try {
      payload = stripe.webhooks.constructEvent(rawBody, signature, STRIPE_WEBHOOK_SECRET);
      ppvCommerceMetrics.webhookVerification.inc({ provider: "stripe", result: "valid" });
    } catch {
      ppvCommerceMetrics.webhookVerification.inc({ provider: "stripe", result: "invalid" });
      ppvCommerceMetrics.webhookErrors.inc({ reason: "stripe_signature_invalid" });
      ppvCommerceMetrics.webhookSignatureFailures.inc({
        provider: "stripe",
        reason: "invalid_signature",
      });
      recordWebhookSignatureFailure({
        provider: "stripe",
        reason: "invalid_signature",
        requestId,
        req,
      });
      console.warn("stripe_signature_invalid", {
        requestId,
        ip: getClientKey(req),
        rawHeaders: req.rawHeaders,
      });
      return res.status(400).json({ error: "invalid stripe signature" });
    }
  } else {
    try {
      payload = JSON.parse(rawBody || "{}");
      ppvCommerceMetrics.webhookVerification.inc({ provider: "stripe", result: "bypass" });
    } catch {
      ppvCommerceMetrics.webhookErrors.inc({ reason: "stripe_payload_invalid" });
      return res.status(400).json({ error: "invalid webhook payload" });
    }
  }

  const payment = extractPaymentDetails(payload);
  if (!payment?.eventId || !payment?.userId) {
    ppvCommerceMetrics.webhookErrors.inc({ reason: "stripe_event_missing_identity" });
    return res.status(400).json({ error: "eventId and userId are required" });
  }

  const purchaseId = `purchase_${uuid().replaceAll("-", "")}`;
  const purchase = {
    id: purchaseId,
    sessionId: payment.sessionId,
    eventId: payment.eventId,
    userId: payment.userId,
    amountCents: payment.amountCents,
    status: payment.status,
    sku: payment.sku,
    provider: payment.provider,
    createdAt: new Date().toISOString(),
  };
  purchaseStore.set(purchaseId, purchase);

  const entitlementKey = `${payment.userId}_${payment.eventId}`;
  const entitlement = {
    id: entitlementKey,
    userId: payment.userId,
    eventId: payment.eventId,
    purchaseId,
    accessType: "ppv",
    status: "active",
    grantedAt: new Date().toISOString(),
  };
  entitlementStore.set(entitlementKey, entitlement);

  ppvCommerceMetrics.purchaseSuccess.inc({ source: "api_webhook_payment" });
  ppvCommerceMetrics.checkoutSuccess.inc({
    provider: "stripe",
    source: "api_webhook_payment",
  });
  ppvCommerceMetrics.entitlementGranted.inc({ source: "api_webhook_payment" });
  ppvCommerceMetrics.entitlementGrantLatencySeconds.observe(
    { provider: "stripe", source: "api_webhook_payment" },
    (Date.now() - entitlementStartedAt) / 1000,
  );
  return res.json({ ok: true, purchase, entitlement });
});

router.get("/purchases", (_req, res) => {
  return res.json({
    count: purchaseStore.size,
    purchases: [...purchaseStore.values()],
  });
});

router.get("/entitlements/:userId", (req, res) => {
  const entitlements = [...entitlementStore.values()].filter(
    (entry) => entry.userId === req.params.userId,
  );

  return res.json({
    userId: req.params.userId,
    count: entitlements.length,
    entitlements,
  });
});

router.post("/ai/sell", aiSellRateLimiter, express.json(), (req, res) => {
  const { eventId, audience, offer = {} } = req.body || {};
  if (!eventId) {
    return res.status(400).json({ error: "eventId is required" });
  }

  const title = offer.title || `Event ${eventId}`;
  const link = offer.link || `https://www.datafightcentral.com/ppv/${eventId}`;
  const price = offer.price == null ? "available now" : `$${offer.price}`;
  const subject = `Don't miss ${title} - PPV tickets on sale now`;
  const sms = `Live tonight: ${title}. Get PPV access now: ${link}`;
  const push = `Your favorite fighter is on the card tonight - watch live on DFC`;

  return res.json({
    eventId,
    audience: audience || "unspecified",
    offer: {
      ...offer,
      checkoutHint: price,
    },
    messages: {
      emailSubject: subject,
      sms,
      push,
    },
  });
});

router.get("/shakura/welcome", (_req, res) => {
  return res.json({
    type: "message",
    from: "shakura@dfc",
    text: "Hi - I'm Shakura, your DFC guide. I can help set up your profile, create an event, or sell PPV. Type 'help' or click the Help button to get started. If this is a legal or safety issue, type 'legal' and I'll collect the required details securely.",
  });
});

router.post("/shakura/legal-intake", express.json(), (req, res) => {
  const { urls, proofOfOwnership, contactEmail, jurisdiction } = req.body || {};
  if (!urls || !proofOfOwnership || !contactEmail || !jurisdiction) {
    return res.status(400).json({
      error: "urls, proofOfOwnership, contactEmail, and jurisdiction are required",
    });
  }

  const ticketId = `legal_${uuid().replaceAll("-", "")}`;
  const ticket = {
    id: ticketId,
    queue: "legal",
    escalations: ["security@datafightcentral.com", "legal@datafightcentral.com"],
    createdAt: new Date().toISOString(),
    urls,
    proofOfOwnership,
    contactEmail,
    jurisdiction,
    status: "queued",
  };
  shakuraTickets.set(ticketId, ticket);

  return res.status(201).json({
    ok: true,
    ticketId,
    status: ticket.status,
    queue: ticket.queue,
  });
});

router.get("/shakura/tickets", (_req, res) => {
  return res.json({
    count: shakuraTickets.size,
    tickets: [...shakuraTickets.values()],
  });
});

router.get("/entitlement/:userId/:eventId", (req, res) => {
  const entitlementKey = `${req.params.userId}_${req.params.eventId}`;
  const entitlement = entitlementStore.get(entitlementKey);
  if (!entitlement) {
    return res.status(404).json({ hasAccess: false });
  }

  ppvCommerceMetrics.watchStarted.inc({ source: "api_entitlement_lookup" });
  return res.json({
    hasAccess: true,
    entitlement,
  });
});

router.post("/upload", upload.single("file"), (req, res) => {
  const id = uuid();
  // in production: checksum, virus scan, store in object store
  audit.push({ id: uuid(), action: "upload", user: "admin", ts: Date.now() });
  res.json({ uploadId: id, scanStatus: "clean" });
});

router.post("/jobs", express.json(), (req, res) => {
  const job = {
    id: uuid(),
    name: req.body.name || "job",
    status: "queued",
    createdAt: Date.now(),
  };
  pendingJobs.push(job);
  audit.push({
    id: uuid(),
    action: "create_job",
    jobId: job.id,
    user: "admin",
    ts: Date.now(),
  });
  res.json({ jobId: job.id, status: "queued" });
});

router.get("/jobs/pending", (req, res) => {
  res.json({
    jobs: pendingJobs.map((j) => ({
      id: j.id,
      name: j.name,
      waitMinutes: Math.floor((Date.now() - j.createdAt) / 60000),
    })),
  });
});

router.post("/jobs/:id/promote", express.json(), (req, res) => {
  const id = req.params.id;
  const idx = pendingJobs.findIndex((j) => j.id === id);
  if (idx >= 0) pendingJobs.splice(idx, 1);
  audit.push({
    id: uuid(),
    action: "promote",
    jobId: id,
    approver: req.body.approverId || "unknown",
    ts: Date.now(),
  });
  res.json({ jobId: id, status: "promoted", promotedAt: Date.now() });
});

router.post("/commands", express.json(), (req, res) => {
  const cmdId = uuid();
  audit.push({
    id: uuid(),
    action: "command",
    command: req.body.command,
    target: req.body.targetId,
    user: req.body.requestedBy || "ui",
    ts: Date.now(),
  });
  // broadcast ack to WS clients
  const { broadcast } = require("./wsServer");
  broadcast({
    type: "command_ack",
    commandId: cmdId,
    status: "accepted",
    ts: Date.now(),
  });
  res.json({ commandId: cmdId, status: "accepted" });
});

router.get("/audit", (req, res) => {
  res.json({ entries: audit.slice(-100).reverse() });
});

router.post("/uploads/sessions", express.json(), (req, res) => {
  try {
    const session = createUploadSession(req.body || {}, { requireSizeBytes: true });
    audit.push({
      id: uuid(),
      action: "uploads/session_created",
      uploadId: session.uploadId,
      userId: session.userId,
      mediaKind: session.metadata.mediaKind,
      partsTotal: session.partsTotal,
      ts: Date.now(),
    });
    return res.status(201).json(buildUploadSessionResponse(session, {
      includeParts: session.partsTotal > 1,
      partNumbers: session.partsTotal > 1 ? [1] : undefined,
    }));
  } catch (error) {
    return res.status(400).json({ error: error.message || "invalid upload session request" });
  }
});

router.get("/uploads/sessions/:uploadId", (req, res) => {
  const session = getUploadSession(req.params.uploadId);
  if (!session) {
    return res.status(404).json({ error: "Upload session not found" });
  }
  return res.json(buildUploadSessionResponse(session));
});

router.post("/uploads/sessions/:uploadId/parts", express.json(), (req, res) => {
  const session = getUploadSession(req.params.uploadId);
  if (!session) {
    return res.status(404).json({ error: "Upload session not found" });
  }

  if (session.partsTotal <= 1) {
    return res.status(409).json({ error: "Upload session does not require multipart URLs" });
  }

  const partNumbers = Array.isArray(req.body?.partNumbers) && req.body.partNumbers.length
    ? req.body.partNumbers.map((value) => Number(value)).filter((value) => Number.isInteger(value) && value >= 1 && value <= session.partsTotal)
    : [1];

  if (!partNumbers.length) {
    return res.status(400).json({ error: "partNumbers must contain valid part indexes" });
  }

  session.status = "uploading";
  session.updatedAt = new Date().toISOString();
  return res.json(buildUploadSessionResponse(session, { includeParts: true, partNumbers }));
});

router.post("/uploads/sessions/:uploadId/complete", express.json(), (req, res) => {
  const session = getUploadSession(req.params.uploadId);
  if (!session) {
    return res.status(404).json({ error: "Upload session not found" });
  }

  const uploadedParts = Array.isArray(req.body?.uploadedParts)
    ? req.body.uploadedParts
        .map((value) => Number(value))
        .filter((value) => Number.isInteger(value) && value >= 1 && value <= session.partsTotal)
    : [];

  if (session.partsTotal > 1 && uploadedParts.length !== session.partsTotal) {
    return res.status(400).json({
      error: "uploadedParts must include every uploaded multipart segment before completion",
    });
  }

  session.completedParts = session.partsTotal > 1 ? uploadedParts : [1];
  session.status = "uploaded";
  session.updatedAt = new Date().toISOString();
  releaseAwaitingJobsForUpload(session.uploadId);

  audit.push({
    id: uuid(),
    action: "uploads/session_completed",
    uploadId: session.uploadId,
    userId: session.userId,
    ts: Date.now(),
  });

  return res.json(buildUploadSessionResponse(session));
});

// ═══════════════════════════════════════════════════════════════════════════
// POST /api/uploads/sign — Return a pre-signed S3 URL for direct browser upload
// Body: { filename, contentType, userId }
// Returns: { uploadId, signedUrl, key, expiresIn }
// ═══════════════════════════════════════════════════════════════════════════
router.post("/uploads/sign", express.json(), (req, res) => {
  try {
    const session = createUploadSession(req.body || {}, { requireSizeBytes: false });
    audit.push({
      id: uuid(),
      action: "uploads/sign",
      userId: session.userId,
      uploadId: session.uploadId,
      mediaKind: session.metadata.mediaKind,
      ts: Date.now(),
    });
    return res.json(buildUploadSessionResponse(session, {
      includeParts: session.partsTotal > 1,
      partNumbers: session.partsTotal > 1 ? [1] : undefined,
    }));
  } catch (error) {
    return res.status(400).json({
      error: error.message || "filename, contentType, and userId are required",
      allowed: Object.keys(ALLOWED_UPLOAD_TYPES),
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// POST /api/posts — Create a post record and enqueue media-processing job
// Body: { userId, content, uploadId?, key? }
// Returns: { postId, status, jobId? }
// ═══════════════════════════════════════════════════════════════════════════
router.post("/posts", express.json(), (req, res) => {
  const { userId, content, uploadId, key } = req.body || {};
  if (!userId) {
    return res.status(400).json({ error: "userId is required" });
  }

  const uploadSession = uploadId ? getUploadSession(uploadId) : getUploadSessionByKey(key);
  if (uploadId && !uploadSession) {
    return res.status(400).json({ error: "uploadId is unknown or expired" });
  }

  const postId = uuid();
  const hasMedia = Boolean(key || uploadId);
  const mediaRecord = buildPostMediaRecord(uploadSession, key || uploadSession?.key || null);
  const mediaStatus = hasMedia
    ? uploadSession && uploadSession.status !== "uploaded"
      ? "uploading"
      : "pending"
    : "none";

  posts[postId] = {
    id: postId,
    userId,
    content: content || "",
    mediaKey: mediaRecord?.key || key || null,
    uploadId: mediaRecord?.uploadId || uploadId || null,
    media: mediaRecord,
    mediaStatus,
    ogImageUrl: null,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };

  if (uploadSession) {
    if (!uploadSession.linkedPostIds.includes(postId)) {
      uploadSession.linkedPostIds.push(postId);
    }
    if (uploadSession.status === "uploaded") {
      uploadSession.status = "attached";
    }
    uploadSession.updatedAt = new Date().toISOString();
  }

  let jobId = null;
  if (hasMedia) {
    jobId = queueMediaProcessingJob({
      postId,
      postRecord: posts[postId],
      uploadSession,
    });
    // In production: push to Redis/SQS queue for the media worker
    audit.push({
      id: uuid(),
      action: "media_job_enqueued",
      postId,
      jobId,
      uploadId: mediaRecord?.uploadId || null,
      mediaKey: mediaRecord?.key || null,
      jobStatus: mediaJobs[jobId].status,
      ts: Date.now(),
    });
  }

  audit.push({
    id: uuid(),
    action: "post_created",
    postId,
    userId,
    ts: Date.now(),
  });
  return res.status(201).json({ postId, status: mediaStatus, jobId });
});

router.get("/media-jobs/:jobId", (req, res) => {
  const job = mediaJobs[req.params.jobId];
  if (!job) {
    return res.status(404).json({ error: "Media job not found" });
  }
  return res.json(job);
});

router.post("/media-jobs/:jobId/retry", express.json(), (req, res) => {
  const job = mediaJobs[req.params.jobId];
  if (!job) {
    return res.status(404).json({ error: "Media job not found" });
  }

  if (job.attempts >= job.maxAttempts) {
    job.retryEligible = false;
    return res.status(409).json({ error: "Media job retry limit reached", job });
  }

  job.attempts += 1;
  job.status = "queued";
  job.nextAttemptAt = Date.now();
  job.updatedAt = Date.now();
  job.lastRetryReason = typeof req.body?.reason === "string"
    ? req.body.reason.trim().slice(0, 240)
    : "manual_retry";

  audit.push({
    id: uuid(),
    action: "media_job_retry",
    jobId: job.jobId,
    postId: job.postId,
    attempt: job.attempts,
    ts: Date.now(),
  });

  return res.json({ ok: true, job });
});

// ═══════════════════════════════════════════════════════════════════════════
// GET /api/posts/:id — Fetch a single post record (used by test harness)
// ═══════════════════════════════════════════════════════════════════════════
router.get("/posts/:id", (req, res) => {
  const id = req.params.id;
  if (!Object.hasOwn(posts, id))
    return res.status(404).json({ error: "Post not found" });
  return res.json(posts[id]);
});

// ── POST /api/consent ───────────────────────────────────────────────────────
// Persists a versioned consent snapshot and sets the dfc_consent cookie used by middleware.
router.post("/consent", express.json(), async (req, res) => {
  const { userId, sessionId, version = "1.0", source = "web" } = req.body || {};
  const incomingConsent = req.body?.consent;

  if (!userId && !sessionId) {
    return res.status(400).json({ error: "userId or sessionId required" });
  }

  const normalizedConsent = typeof incomingConsent === "boolean"
    ? {
        analytics: incomingConsent,
        advertising: incomingConsent,
        functional: true,
        ts: new Date().toISOString(),
      }
    : {
        analytics: incomingConsent?.analytics !== false,
        advertising: incomingConsent?.advertising === true,
        functional: incomingConsent?.functional !== false,
        ts: incomingConsent?.ts || new Date().toISOString(),
      };

  const record = {
    userId: userId || null,
    sessionId: sessionId || null,
    consent: normalizedConsent,
    version,
    source,
    createdAt: new Date().toISOString(),
  };

  const db = getDb();
  if (db) {
    await db.collection("consents").add(record);
  }

  audit.push({ ts: Date.now(), action: "consent_update", ...record });

  const encodedConsent = Buffer.from(JSON.stringify(normalizedConsent)).toString("base64");
  res.cookie("dfc_consent", encodedConsent, {
    httpOnly: false,
    sameSite: "lax",
    maxAge: 365 * 24 * 60 * 60 * 1000,
  });

  return res.json({ ok: true, consent: normalizedConsent, persisted: Boolean(db) });
});

// ── POST /api/attribution/attach ─────────────────────────────────────────────
// Persist ad click IDs to user/session for later purchase attribution
router.post("/attribution/attach", express.json(), (req, res) => {
  const { userId, sessionId, gclid, fbclid, fbc, fbp, utmSource, utmCampaign } = req.body || {};
  if (!userId && !sessionId) {
    return res.status(400).json({ error: "userId or sessionId required" });
  }
  const record = {
    userId, sessionId, gclid, fbclid, fbc, fbp, utmSource, utmCampaign,
    attachedAt: new Date().toISOString(),
  };
  // In production: write to Firestore attribution/{userId} with TTL
  audit.push({ ts: Date.now(), action: "attribution_attach", ...record });
  return res.json({ ok: true, attachedAt: record.attachedAt });
});

// ── POST /api/ads/meta/forward ────────────────────────────────────────────────
// Explicit server-side Meta CAPI forward (admin/server use only; requires advertising consent)
router.post("/ads/meta/forward", express.json(), requireConsent(["advertising"]), async (req, res) => {
  try {
    const result = await forwardToMeta(req.body);
    return res.json({ ok: true, result });
  } catch (err) {
    return res.status(502).json({ error: "Meta CAPI forward failed", detail: err.message });
  }
});

// ── GET /api/flags — evaluated feature flags for calling user ──────────────
router.get("/flags", async (req, res) => {
  await featureFlags.refresh();
  const userId = req.headers["x-dfc-user-id"] || "";
  const userRole = req.headers["x-dfc-user-role"] || "free";
  return res.json({
    flags: featureFlags.getAll({ userId, userRole }),
    userId,
    ts: new Date().toISOString(),
  });
});

// ── Admin: Reconciliation ───────────────────────────────────────────────────

// GET /api/admin/reconciliation/latest — return the latest run + open mismatches
router.get("/admin/reconciliation/latest", (_req, res) => {
  const { run, mismatches } = getLatestRun();
  if (!run) {
    return res.json({ run: null, mismatches: [], message: "No reconciliation runs yet. POST /api/admin/reconciliation/run to trigger." });
  }
  const open = mismatches.filter((m) => m.status === "open");
  const resolved = mismatches.filter((m) => m.status === "resolved");
  return res.json({ run, openCount: open.length, resolvedCount: resolved.length, mismatches });
});

// POST /api/admin/reconciliation/run — trigger an on-demand reconciliation
router.post("/admin/reconciliation/run", express.json(), (req, res) => {
  try {
    const result = runReconciliation(purchaseStore, walletTransactions);
    return res.status(201).json(result);
  } catch (err) {
    return res.status(500).json({ error: "reconciliation_failed", detail: err?.message });
  }
});

// POST /api/admin/reconciliation/resolve/:id — mark a mismatch as resolved
router.post("/admin/reconciliation/resolve/:id", express.json(), (req, res) => {
  const { resolvedBy, notes } = req.body || {};
  if (!resolvedBy) {
    return res.status(400).json({ error: "resolvedBy is required" });
  }
  const { ok, mismatch } = resolveMismatch(req.params.id, { resolvedBy, notes: notes || null });
  if (!ok) {
    return res.status(404).json({ error: "Mismatch not found" });
  }
  audit.push({ ts: Date.now(), action: "reconciliation_resolve", mismatchId: req.params.id, resolvedBy });
  return res.json({ ok: true, mismatch });
});

module.exports = router;
