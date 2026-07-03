const functions = require("firebase-functions");
const admin = require("firebase-admin");
if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

function simpleProfanityCheck(text) {
  const blocked = ["slur1", "slur2", "threatword1"];
  const lower = (text || "").toLowerCase();
  for (const b of blocked) if (lower.includes(b)) return true;
  return false;
}

exports.publishFighterReply = functions.firestore
  .document("fighters/{fighterId}/responses/{responseId}")
  .onCreate(async (snap, ctx) => {
    const data = snap.data();
    const fighterId = ctx.params.fighterId;
    const responseId = ctx.params.responseId;

    if (!data.publishRequested) return null;

    if (!data.text && !(data.media && data.media.length)) {
      await snap.ref.update({
        publishStatus: "rejected",
        publishReason: "empty",
      });
      return null;
    }

    const hasProfanity = simpleProfanityCheck(data.text || "");
    if (hasProfanity) {
      await snap.ref.update({
        publishStatus: "rejected",
        publishReason: "profanity",
      });
      await db.collection("moderation_audit").add({
        targetType: "response",
        targetId: responseId,
        action: "autoRejected",
        reason: "profanity detected",
        actor: "auto",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
      return null;
    }

    const postId = `post_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
    const post = {
      id: postId,
      title: data.title || `Reply from ${fighterId}`,
      body: data.text || "",
      media: data.media || [],
      authorId: fighterId,
      source: "fighterReply",
      sourceResponseId: responseId,
      regionId: data.regionId || null,
      status: "approved",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const postRef = db.doc(`posts/${postId}`);
    const auditRef = db.collection("moderation_audit").doc();
    await db.runTransaction(async (tx) => {
      tx.set(postRef, post);
      tx.set(auditRef, {
        targetType: "post",
        targetId: postId,
        action: "autoPublishedFromReply",
        reason: "fighter published reply",
        actor: fighterId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
      tx.update(snap.ref, {
        publishStatus: "published",
        publishAt: admin.firestore.FieldValue.serverTimestamp(),
        postId,
      });
    });

    return null;
  });
