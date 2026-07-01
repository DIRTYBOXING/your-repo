// ═══════════════════════════════════════════════════════════════════════════
// VIDEO MODERATION — Auto-flag new short videos on creation via Firestore trigger
// ═══════════════════════════════════════════════════════════════════════════

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { admin, db, REGION } = require("../config");

// ─── Banned keywords for title/description (combat context aware) ────────
const BANNED_PATTERNS = [
  /\b(porn|xxx|nude|naked)\b/i,
  /\b(drug\s*deal|sell(ing)?\s+drugs?)\b/i,
  /\b(doxx|swat(t?)ing)\b/i,
  /\b(kill\s+(yourself|himself|herself))\b/i,
  /\b(child\s*(abuse|porn))\b/i,
];

function containsBannedContent(text) {
  if (!text || typeof text !== "string") return null;
  for (const pattern of BANNED_PATTERNS) {
    if (pattern.test(text)) return pattern.toString();
  }
  return null;
}

// ─── Trigger: new video in short_videos ──────────────────────────────────
exports.moderateNewVideo = onDocumentCreated(
  { document: "short_videos/{videoId}", region: REGION },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const videoId = event.params.videoId;
    const titleCheck = containsBannedContent(data.title || "");
    const descCheck = containsBannedContent(data.description || "");

    const flagReason = titleCheck
      ? `Title matched banned pattern: ${titleCheck}`
      : descCheck
        ? `Description matched banned pattern: ${descCheck}`
        : null;

    if (flagReason) {
      // Auto-flag and add to moderation queue
      const batch = db.batch();

      batch.update(snap.ref, {
        isFlagged: true,
        flagReason,
        moderatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      batch.set(db.collection("moderation_queue").doc(), {
        type: "short_video",
        contentId: videoId,
        contentRef: `short_videos/${videoId}`,
        creatorId: data.creatorId || null,
        reason: flagReason,
        status: "pending",
        autoFlagged: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await batch.commit();
      console.log(
        `[moderateNewVideo] Auto-flagged video ${videoId}: ${flagReason}`,
      );
    } else {
      console.log(`[moderateNewVideo] Video ${videoId} passed text moderation`);
    }
  },
);

// ─── Trigger: report threshold auto-escalation ──────────────────────────
exports.escalateReportedContent = onDocumentCreated(
  { document: "content_reports/{reportId}", region: REGION },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const report = snap.data();
    const { contentType, contentId } = report;

    if (!contentType || !contentId) return;

    // Count total reports for this content
    const reportsSnap = await db
      .collection("content_reports")
      .where("contentId", "==", contentId)
      .where("contentType", "==", contentType)
      .get();

    const reportCount = reportsSnap.size;

    // Auto-escalate at 3+ reports
    if (reportCount >= 3) {
      const collectionName =
        contentType === "short_video"
          ? "short_videos"
          : contentType === "post"
            ? "posts"
            : contentType === "comment"
              ? "comments"
              : null;

      if (collectionName) {
        const contentRef = db.collection(collectionName).doc(contentId);
        const contentDoc = await contentRef.get();

        if (contentDoc.exists) {
          await contentRef.update({
            isFlagged: true,
            flagReason: `Auto-escalated: ${reportCount} user reports`,
            reportCount,
          });
        }
      }

      // Create escalation record
      await db.collection("escalations").add({
        contentType,
        contentId,
        reportCount,
        reason: `Auto-escalated: ${reportCount} user reports`,
        status: "pending",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(
        `[escalateReportedContent] Auto-escalated ${contentType}/${contentId} with ${reportCount} reports`,
      );
    }
  },
);
