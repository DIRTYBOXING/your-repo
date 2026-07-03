const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// Simple scoring function
function computeScore(post) {
  const now = Date.now();
  const publishedAt = post.publishedAt
    ? post.publishedAt.toMillis
      ? post.publishedAt.toMillis()
      : new Date(post.publishedAt).getTime()
    : now;
  const recency = Math.max(0, 1 - (now - publishedAt) / (1000 * 60 * 60 * 24)); // 0..1 over 24h
  const engagement = (post.reactions || 0) * 0.1 + (post.comments || 0) * 0.2;
  const authorTrust = post.authorTrust || 0.5; // 0..1
  const eventBoost =
    post.priorityTags && post.priorityTags.includes("event") ? 1.5 : 1.0;
  const editorialBoost =
    post.priorityTags && post.priorityTags.includes("featured") ? 1.2 : 1.0;
  const score =
    (recency * 0.4 + engagement * 0.3 + authorTrust * 0.3) *
    eventBoost *
    editorialBoost;
  return Math.round(score * 10000) / 10000;
}

exports.materializeRegionFeed = functions.firestore
  .document("posts/{postId}")
  .onWrite(async (change, context) => {
    const postId = context.params.postId;
    const before = change.before.exists ? change.before.data() : null;
    const after = change.after.exists ? change.after.data() : null;

    // If post deleted, remove from any region feed it belonged to
    if (!after && before && before.regionId) {
      const regionRef = db.doc(
        `regions/${before.regionId}/feedItems/${postId}`,
      );
      await regionRef.delete().catch(() => null);
      return null;
    }

    // If post exists
    if (after) {
      const status = after.status || "draft";
      const regionId = after.regionId || null;

      // If not approved or no region, ensure removal and exit
      if (status !== "approved" || !regionId) {
        if (before && before.regionId) {
          await db
            .doc(`regions/${before.regionId}/feedItems/${postId}`)
            .delete()
            .catch(() => null);
        }
        return null;
      }

      // Compute score and write feed item
      const score = computeScore(after);
      const feedItem = {
        postId,
        title: after.title || "",
        excerpt: after.excerpt || "",
        authorId: after.authorId || null,
        regionId,
        priorityTags: after.priorityTags || [],
        score,
        publishedAt:
          after.publishedAt || admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      const regionRef = db.doc(`regions/${regionId}/feedItems/${postId}`);
      await regionRef.set(feedItem, { merge: true });
      return null;
    }

    return null;
  });

// Test endpoint to create an approved post for validation
exports.testCreateApprovedPost = functions.https.onRequest(async (req, res) => {
  const secret = req.query.secret || req.headers["x-test-secret"];
  if (secret !== (functions.config().test || {}).secret) {
    return res.status(401).send("unauthorized");
  }

  const postId = `test-${Date.now()}`;
  const post = {
    title: "Test Approved Post",
    excerpt: "This is a test post for region feed materialization",
    authorId: "system-test",
    regionId: req.query.region || "logan",
    status: "approved",
    priorityTags: ["event"],
    reactions: 5,
    comments: 2,
    authorTrust: 0.8,
    publishedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await db.doc(`posts/${postId}`).set(post);
  return res.status(200).json({ ok: true, postId });
});
