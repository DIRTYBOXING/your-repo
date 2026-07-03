// ═══════════════════════════════════════════════════════════════════════════
// SOCIAL POST API — Authenticated post creation + personalized feed
// ═══════════════════════════════════════════════════════════════════════════
//
// createSocialPost  – Callable: creates a post and optionally links a
//                     media_upload doc so the client can upload→post in
//                     one atomic flow.
//
// getPersonalizedFeed – Callable: returns posts from users the caller
//                       follows, ordered by creation date with cursor
//                       pagination.
//
// ═══════════════════════════════════════════════════════════════════════════

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { admin, db, REGION } = require("../config");

// ─── Input Sanitization ──────────────────────────────────────────────────

function sanitizeText(input) {
  if (!input || typeof input !== "string") return "";
  return input
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, "")
    .replace(/<iframe[^>]*>[\s\S]*?<\/iframe>/gi, "")
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
// CREATE SOCIAL POST
// ═══════════════════════════════════════════════════════════════════════════

const createSocialPost = onCall(
  {
    region: REGION,
    memory: "256MiB",
    timeoutSeconds: 30,
  },
  async (request) => {
    // Auth required
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in to create posts.");
    }

    const uid = request.auth.uid;
    const data = request.data || {};

    const content = sanitizeText(data.content || "");
    if (content.length < 1) {
      throw new HttpsError("invalid-argument", "Post content is required.");
    }
    if (content.length > 5000) {
      throw new HttpsError(
        "invalid-argument",
        "Post content exceeds 5 000 characters.",
      );
    }

    const postType = VALID_POST_TYPES.includes(data.postType)
      ? data.postType
      : "text";
    const visibility = VALID_VISIBILITY.includes(data.visibility)
      ? data.visibility
      : "public";
    const mediaUploadId = data.mediaUploadId || null;

    // Fetch author profile
    const userDoc = await db.collection("users").doc(uid).get();
    const profile = userDoc.exists ? userDoc.data() : {};

    // Build the post document (matches existing schema from n8n webhook)
    const postDoc = {
      userId: uid,
      content,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),

      userDisplayName: profile.displayName || "DFC User",
      userRole: profile.role || "user",
      userAvatarUrl: profile.avatarUrl || profile.photoURL || "",
      isVerified: profile.isVerified === true,

      postType,
      visibility,

      mediaUrls: [],
      thumbnailUrl: "",

      location: sanitizeText(data.location || ""),

      likes: 0,
      likedBy: [],
      bookmarkedBy: [],
      commentCount: 0,
      shareCount: 0,

      respectCount: 0,
      strongCount: 0,
      supportCount: 0,
      warriorCount: 0,
      championCount: 0,
      reactions: {},

      linkPreviewUrl: sanitizeUrl(data.linkPreviewUrl || ""),
      linkPreviewTitle: "",
      linkPreviewDescription: "",
      linkPreviewImage: "",
      linkPreviewDomain: "",

      source: "app",
      isEdited: false,
      editedAt: null,
    };

    // ── Atomic media link ────────────────────────────────────────────
    // If the client provides a mediaUploadId, link its URLs into the post
    // and stamp the media_uploads doc with the resulting postId.
    if (mediaUploadId) {
      const mediaRef = db.collection("media_uploads").doc(mediaUploadId);
      const mediaDoc = await mediaRef.get();

      if (mediaDoc.exists) {
        const md = mediaDoc.data();
        // Only link if the media belongs to this user
        if (md.userId === uid) {
          if (md.thumbnailUrl) postDoc.thumbnailUrl = md.thumbnailUrl;
          if (md.ogImageUrl) postDoc.linkPreviewImage = md.ogImageUrl;
          // Collect variant URLs
          if (md.variants && typeof md.variants === "object") {
            const urls = Object.values(md.variants)
              .map((v) => v.url)
              .filter(Boolean);
            if (urls.length > 0) postDoc.mediaUrls = urls;
          }
          // Fallback: use the original URL if no variants yet (still processing)
          if (postDoc.mediaUrls.length === 0 && md.originalUrl) {
            postDoc.mediaUrls = [md.originalUrl];
          }
          postDoc.postType =
            md.contentType === "video" ? "media" : postDoc.postType;
        }
      }
    }

    // ── Write post ───────────────────────────────────────────────────
    const postRef = await db.collection("posts").add(postDoc);

    // Back-link the media doc
    if (mediaUploadId) {
      await db
        .collection("media_uploads")
        .doc(mediaUploadId)
        .update({ postId: postRef.id })
        .catch(() => {}); // non-critical
    }

    console.log(`[createSocialPost] ${uid} → ${postRef.id}`);
    return { postId: postRef.id };
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// PERSONALIZED FEED
// ═══════════════════════════════════════════════════════════════════════════
// Returns posts from users the caller follows, plus their own posts,
// ordered by newest-first with cursor pagination via `startAfter`.

const getPersonalizedFeed = onCall(
  {
    region: REGION,
    memory: "256MiB",
    timeoutSeconds: 30,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in to view your feed.");
    }

    const uid = request.auth.uid;
    const limit = Math.min(
      Math.max(parseInt(request.data?.limit, 10) || 20, 1),
      50,
    );
    const cursorISO = request.data?.startAfter || null;

    // ── Gather the set of author UIDs to include ─────────────────────
    const followSnap = await db
      .collection("follows")
      .where("followerId", "==", uid)
      .select("followingId")
      .limit(500)
      .get();

    const authorIds = new Set([uid]);
    for (const doc of followSnap.docs) {
      const fid = doc.data().followingId;
      if (fid) authorIds.add(fid);
    }

    // Firestore `in` queries support max 30 values — chunk if needed
    const authorArray = [...authorIds];
    const chunks = [];
    for (let i = 0; i < authorArray.length; i += 30) {
      chunks.push(authorArray.slice(i, i + 30));
    }

    // ── Query posts from each chunk and merge ────────────────────────
    let allPosts = [];

    for (const chunk of chunks) {
      let q = db
        .collection("posts")
        .where("userId", "in", chunk)
        .where("visibility", "in", ["public", "followers"])
        .orderBy("createdAt", "desc");

      if (cursorISO) {
        const cursorDate = new Date(cursorISO);
        if (!isNaN(cursorDate.getTime())) {
          q = q.startAfter(admin.firestore.Timestamp.fromDate(cursorDate));
        }
      }

      q = q.limit(limit);
      const snap = await q.get();
      for (const doc of snap.docs) {
        allPosts.push({ id: doc.id, ...doc.data() });
      }
    }

    // ── Sort merged results and trim to limit ────────────────────────
    allPosts.sort((a, b) => {
      const ta = a.createdAt?._seconds || 0;
      const tb = b.createdAt?._seconds || 0;
      return tb - ta;
    });
    allPosts = allPosts.slice(0, limit);

    // Convert Timestamps for JSON transport
    const posts = allPosts.map((p) => ({
      ...p,
      createdAt: p.createdAt?._seconds
        ? new Date(p.createdAt._seconds * 1000).toISOString()
        : null,
      editedAt: p.editedAt?._seconds
        ? new Date(p.editedAt._seconds * 1000).toISOString()
        : null,
    }));

    const nextCursor =
      posts.length === limit ? posts[posts.length - 1].createdAt : null;

    return { posts, nextCursor };
  },
);

// ═══════════════════════════════════════════════════════════════════════════
module.exports = { createSocialPost, getPersonalizedFeed };
