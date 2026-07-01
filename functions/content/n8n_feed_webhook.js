// ═══════════════════════════════════════════════════════════════════════════
// N8N FEED WEBHOOK — Direct HTTP intake for the DFC social feed
// ═══════════════════════════════════════════════════════════════════════════
//
// Accepts POST requests from n8n (or any authorized external system) and
// writes directly to the `posts` collection — making content appear in
// the user-facing feed immediately.
//
// The OG metadata enrichment (og_metadata.js) auto-triggers on post
// creation, so link previews are populated server-side for free.
//
// SECURITY:
//   - Requires X-DFC-Webhook-Key header matching N8N_FEED_WEBHOOK_KEY secret
//   - Input sanitized (no script tags, no javascript: URIs)
//   - Rate-limited to 50 posts per 15-minute window
//
// USAGE (from n8n HTTP Request node):
//   POST https://<region>-datafightcentral.cloudfunctions.net/n8nFeedWebhook
//   Headers: { "X-DFC-Webhook-Key": "<secret>", "Content-Type": "application/json" }
//   Body: { "content": "...", "authorName": "...", ... }
//
// ═══════════════════════════════════════════════════════════════════════════

const { onRequest } = require("firebase-functions/v2/https");
const { admin, db, REGION } = require("../config");

// ─── Webhook secret (set via: firebase functions:secrets:set N8N_FEED_WEBHOOK_KEY)
const WEBHOOK_KEY = process.env.N8N_FEED_WEBHOOK_KEY || "";

// ─── Rate limit state (in-memory, resets on cold start) ──────────────────
const rateLimitWindow = 15 * 60 * 1000; // 15 minutes
let rateLimitCounter = 0;
let rateLimitStart = Date.now();
const RATE_LIMIT_MAX = 50;

function checkRateLimit() {
  const now = Date.now();
  if (now - rateLimitStart > rateLimitWindow) {
    rateLimitCounter = 0;
    rateLimitStart = now;
  }
  rateLimitCounter++;
  return rateLimitCounter <= RATE_LIMIT_MAX;
}

// ─── Input sanitization ─────────────────────────────────────────────────
function sanitizeText(input) {
  if (!input || typeof input !== "string") return "";
  return input
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, "")
    .replace(/<iframe[^>]*>[\s\S]*?<\/iframe>/gi, "")
    .replace(/<embed[^>]*>/gi, "")
    .replace(/<object[^>]*>[\s\S]*?<\/object>/gi, "")
    .replace(/on\w+\s*=\s*["'][^"']*["']/gi, "")
    .replace(/javascript\s*:/gi, "")
    .trim();
}

function sanitizeUrl(url) {
  if (!url || typeof url !== "string") return "";
  const trimmed = url.trim();
  if (trimmed.toLowerCase().startsWith("javascript:")) return "";
  if (trimmed.toLowerCase().startsWith("data:")) return "";
  if (!trimmed.startsWith("http://") && !trimmed.startsWith("https://"))
    return "";
  return trimmed;
}

function sanitizeMediaUrls(urls) {
  if (!Array.isArray(urls)) return [];
  return urls
    .map(sanitizeUrl)
    .filter((u) => u.length > 0)
    .slice(0, 10); // Max 10 media items
}

// ─── Valid post types ────────────────────────────────────────────────────
const VALID_POST_TYPES = [
  "text",
  "announcement",
  "fight_card",
  "media",
  "event",
  "news",
  "promotion",
];
const VALID_VISIBILITY = ["public", "followers", "private"];

// ═══════════════════════════════════════════════════════════════════════════
// MAIN WEBHOOK HANDLER
// ═══════════════════════════════════════════════════════════════════════════

const n8nFeedWebhook = onRequest(
  {
    region: REGION,
    memory: "256MiB",
    timeoutSeconds: 30,
    cors: false, // Server-to-server only
  },
  async (req, res) => {
    // ── Method check ──
    if (req.method !== "POST") {
      res.status(405).json({ error: "POST only" });
      return;
    }

    // ── Auth check ──
    const providedKey = req.headers["x-dfc-webhook-key"] || "";
    if (!WEBHOOK_KEY) {
      console.error("[n8nFeedWebhook] N8N_FEED_WEBHOOK_KEY not configured");
      res.status(503).json({
        error: "Webhook not configured — set N8N_FEED_WEBHOOK_KEY secret",
      });
      return;
    }

    if (providedKey !== WEBHOOK_KEY) {
      console.warn("[n8nFeedWebhook] Unauthorized attempt");
      res.status(401).json({ error: "Invalid webhook key" });
      return;
    }

    // ── Rate limit ──
    if (!checkRateLimit()) {
      res
        .status(429)
        .json({ error: "Rate limit exceeded — max 50 posts per 15 minutes" });
      return;
    }

    // ── Parse body ──
    const {
      content,
      authorName,
      authorId,
      authorRole,
      authorAvatarUrl,
      postType,
      mediaUrls,
      thumbnailUrl,
      location,
      visibility,
      linkPreviewUrl,
      linkPreviewTitle,
      linkPreviewDescription,
      linkPreviewImage,
      linkPreviewDomain,
      tags,
      isVerified,
      // Batch mode: array of posts
      posts,
    } = req.body;

    // ── Batch mode ──
    if (Array.isArray(posts) && posts.length > 0) {
      if (posts.length > 25) {
        res.status(400).json({ error: "Batch max 25 posts" });
        return;
      }

      const results = [];
      for (const post of posts) {
        try {
          const postId = await writePost(post);
          results.push({ status: "ok", postId });
        } catch (err) {
          results.push({ status: "error", error: err.message });
        }
      }

      console.log(
        `[n8nFeedWebhook] Batch: ${results.filter((r) => r.status === "ok").length}/${posts.length} posts written`,
      );
      res.status(200).json({ status: "ok", mode: "batch", results });
      return;
    }

    // ── Single post mode ──
    if (!content || typeof content !== "string" || content.trim().length < 3) {
      res.status(400).json({ error: "content is required (min 3 characters)" });
      return;
    }

    try {
      const postId = await writePost({
        content,
        authorName,
        authorId,
        authorRole,
        authorAvatarUrl,
        postType,
        mediaUrls,
        thumbnailUrl,
        location,
        visibility,
        linkPreviewUrl,
        linkPreviewTitle,
        linkPreviewDescription,
        linkPreviewImage,
        linkPreviewDomain,
        tags,
        isVerified,
      });

      console.log(`[n8nFeedWebhook] Post created: ${postId}`);
      res.status(201).json({ status: "ok", postId });
    } catch (err) {
      console.error("[n8nFeedWebhook] Error:", err.message);
      res.status(500).json({ error: "Failed to create post" });
    }
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// WRITE POST — Constructs and persists a post to Firestore `posts` collection
// ═══════════════════════════════════════════════════════════════════════════

async function writePost(data) {
  const safeContent = sanitizeText(data.content || "");
  if (safeContent.length < 3)
    throw new Error("Content too short after sanitization");

  const safePostType = VALID_POST_TYPES.includes(data.postType)
    ? data.postType
    : "text";
  const safeVisibility = VALID_VISIBILITY.includes(data.visibility)
    ? data.visibility
    : "public";
  const safeMedia = sanitizeMediaUrls(data.mediaUrls);

  const postDoc = {
    // Core
    userId: sanitizeText(data.authorId || "dfc_auto_feed"),
    content: safeContent,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),

    // Author metadata
    userDisplayName: sanitizeText(data.authorName || "DFC Auto Feed"),
    userRole: sanitizeText(data.authorRole || "platform"),
    userAvatarUrl: sanitizeUrl(data.authorAvatarUrl || ""),
    isVerified: data.isVerified === true,

    // Post type & visibility
    postType: safePostType,
    visibility: safeVisibility,

    // Media
    mediaUrls: safeMedia,
    thumbnailUrl: sanitizeUrl(
      data.thumbnailUrl || (safeMedia.length > 0 ? safeMedia[0] : ""),
    ),

    // Location
    location: sanitizeText(data.location || ""),

    // Engagement (start at zero)
    likes: 0,
    likedBy: [],
    bookmarkedBy: [],
    commentCount: 0,
    shareCount: 0,

    // Combat reactions
    respectCount: 0,
    strongCount: 0,
    supportCount: 0,
    warriorCount: 0,
    championCount: 0,
    reactions: {},

    // Link preview (client fields — OG enrichment will auto-run via og_metadata.js)
    linkPreviewUrl: sanitizeUrl(data.linkPreviewUrl || ""),
    linkPreviewTitle: sanitizeText(data.linkPreviewTitle || ""),
    linkPreviewDescription: sanitizeText(data.linkPreviewDescription || ""),
    linkPreviewImage: sanitizeUrl(data.linkPreviewImage || ""),
    linkPreviewDomain: sanitizeText(data.linkPreviewDomain || ""),

    // Source tracking
    source: "n8n_webhook",
    isEdited: false,
    editedAt: null,
  };

  const ref = await db.collection("posts").add(postDoc);
  return ref.id;
}

module.exports = {
  n8nFeedWebhook,
};
