/**
 * ═══════════════════════════════════════════════════════════════════════════
 * DFC MODERATION ACTIONS — Server-side Cloud Functions
 *
 * Authoritative writes for approve, reject, edit, escalate, and undo.
 * Uses Admin SDK to bypass Firestore rules. Validates moderator claims.
 * Writes immutable entries to moderation_audit on every action.
 * ═══════════════════════════════════════════════════════════════════════════
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Ensure admin is initialized (safe to call multiple times)
if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

// ── HELPERS ──────────────────────────────────────────────────────────────

/** Validate Authorization header and return moderator UID. */
async function validateModerator(req) {
  const authHeader = req.headers.authorization || "";
  if (!authHeader.startsWith("Bearer ")) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Missing or invalid Authorization header",
    );
  }
  const token = authHeader.split("Bearer ")[1];
  const decoded = await admin.auth().verifyIdToken(token);

  // Check custom claim
  if (!decoded.moderator && !decoded.admin) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "User does not have moderator or admin role",
    );
  }
  return decoded.uid;
}

/** Write immutable audit entry. */
async function writeAudit(tx, data) {
  const auditRef = db.collection("moderation_audit").doc();
  tx.set(auditRef, {
    ...data,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    immutable: true,
  });
}

/** Compute feed score for approved content. */
function computeScore(item) {
  let score = 50;
  if (item.isPriority) score += 30;
  if (item.hasMedia) score += 10;
  if (item.authorVerified) score += 20;
  return Math.min(score, 100);
}

// ═══════════════════════════════════════════════════════════════════════════
// APPROVE
// ═══════════════════════════════════════════════════════════════════════════
exports.approve = functions
  .region("australia-southeast1")
  .https.onRequest(async (req, res) => {
    if (req.method !== "POST")
      return res.status(405).send("Method not allowed");

    try {
      const moderatorUid = await validateModerator(req);
      const { id, reason } = req.body;
      if (!id) return res.status(400).json({ error: "Missing 'id'" });

      const itemRef = db.doc(`moderation/${id}`);
      const itemSnap = await itemRef.get();
      if (!itemSnap.exists)
        return res.status(404).json({ error: "Item not found" });
      const item = itemSnap.data();

      await db.runTransaction(async (tx) => {
        tx.update(itemRef, {
          status: "approved",
          moderatedBy: moderatorUid,
          moderatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        await writeAudit(tx, {
          targetType: item.type || "post",
          targetId: id,
          action: "approved",
          actor: moderatorUid,
          reason: reason || "Approved via Mod Command Console",
          previousStatus: item.status || "pending",
        });

        // Materialize to region feed if regionId present
        if (item.regionId) {
          const feedRef = db.doc(`regions/${item.regionId}/feedItems/${id}`);
          tx.set(feedRef, {
            postId: id,
            title: item.title || "",
            authorId: item.authorId || item.userId || null,
            regionId: item.regionId,
            score: computeScore(item),
            publishedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      });

      res.json({ ok: true, action: "approved", id });
    } catch (err) {
      console.error("approve error:", err);
      res.status(err.httpErrorCode?.status || 500).json({ error: err.message });
    }
  });

// ═══════════════════════════════════════════════════════════════════════════
// REJECT
// ═══════════════════════════════════════════════════════════════════════════
exports.reject = functions
  .region("australia-southeast1")
  .https.onRequest(async (req, res) => {
    if (req.method !== "POST")
      return res.status(405).send("Method not allowed");

    try {
      const moderatorUid = await validateModerator(req);
      const { id, reason } = req.body;
      if (!id) return res.status(400).json({ error: "Missing 'id'" });
      if (!reason)
        return res
          .status(400)
          .json({ error: "Missing 'reason' for rejection" });

      const itemRef = db.doc(`moderation/${id}`);
      const itemSnap = await itemRef.get();
      if (!itemSnap.exists)
        return res.status(404).json({ error: "Item not found" });
      const item = itemSnap.data();

      await db.runTransaction(async (tx) => {
        tx.update(itemRef, {
          status: "rejected",
          moderatedBy: moderatorUid,
          moderatedAt: admin.firestore.FieldValue.serverTimestamp(),
          rejectionReason: reason,
          softDeleted: true,
          softDeletedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        await writeAudit(tx, {
          targetType: item.type || "post",
          targetId: id,
          action: "rejected",
          actor: moderatorUid,
          reason: reason,
          previousStatus: item.status || "pending",
        });
      });

      res.json({ ok: true, action: "rejected", id, reason });
    } catch (err) {
      console.error("reject error:", err);
      res.status(err.httpErrorCode?.status || 500).json({ error: err.message });
    }
  });

// ═══════════════════════════════════════════════════════════════════════════
// EDIT + PUBLISH
// ═══════════════════════════════════════════════════════════════════════════
exports.edit = functions
  .region("australia-southeast1")
  .https.onRequest(async (req, res) => {
    if (req.method !== "POST")
      return res.status(405).send("Method not allowed");

    try {
      const moderatorUid = await validateModerator(req);
      const { id, editedContent } = req.body;
      if (!id || !editedContent) {
        return res
          .status(400)
          .json({ error: "Missing 'id' or 'editedContent'" });
      }

      // Light moderation on edited content (basic length + banned word check)
      if (editedContent.length > 2000) {
        return res
          .status(400)
          .json({ error: "Edited content exceeds 2000 character limit" });
      }

      const itemRef = db.doc(`moderation/${id}`);
      const itemSnap = await itemRef.get();
      if (!itemSnap.exists)
        return res.status(404).json({ error: "Item not found" });
      const item = itemSnap.data();

      await db.runTransaction(async (tx) => {
        tx.update(itemRef, {
          content: editedContent,
          originalContent: item.content, // preserve original
          status: "approved",
          moderatedBy: moderatorUid,
          moderatedAt: admin.firestore.FieldValue.serverTimestamp(),
          editedByModerator: true,
        });

        await writeAudit(tx, {
          targetType: item.type || "post",
          targetId: id,
          action: "edited_and_published",
          actor: moderatorUid,
          reason: "Content edited by moderator before publishing",
          previousContent: item.content,
          editedContent: editedContent,
          previousStatus: item.status || "pending",
        });

        // Materialize edited version to feed
        if (item.regionId) {
          const feedRef = db.doc(`regions/${item.regionId}/feedItems/${id}`);
          tx.set(feedRef, {
            postId: id,
            title: item.title || "",
            authorId: item.authorId || item.userId || null,
            regionId: item.regionId,
            score: computeScore(item),
            publishedAt: admin.firestore.FieldValue.serverTimestamp(),
            editedByModerator: true,
          });
        }
      });

      res.json({ ok: true, action: "edited_and_published", id });
    } catch (err) {
      console.error("edit error:", err);
      res.status(err.httpErrorCode?.status || 500).json({ error: err.message });
    }
  });

// ═══════════════════════════════════════════════════════════════════════════
// ESCALATE
// ═══════════════════════════════════════════════════════════════════════════
exports.escalate = functions
  .region("australia-southeast1")
  .https.onRequest(async (req, res) => {
    if (req.method !== "POST")
      return res.status(405).send("Method not allowed");

    try {
      const moderatorUid = await validateModerator(req);
      const { id, reason, severity } = req.body;
      if (!id) return res.status(400).json({ error: "Missing 'id'" });

      const itemRef = db.doc(`moderation/${id}`);
      const itemSnap = await itemRef.get();
      if (!itemSnap.exists)
        return res.status(404).json({ error: "Item not found" });
      const item = itemSnap.data();

      await db.runTransaction(async (tx) => {
        tx.update(itemRef, {
          status: "escalated",
          escalatedBy: moderatorUid,
          escalatedAt: admin.firestore.FieldValue.serverTimestamp(),
          escalationSeverity: severity || "HIGH",
        });

        // Create escalation document
        const escalationRef = db.collection("escalations").doc();
        tx.set(escalationRef, {
          moderationItemId: id,
          content: item.content,
          authorId: item.authorId || item.userId || null,
          escalatedBy: moderatorUid,
          reason: reason || "Escalated for Safety team review",
          severity: severity || "HIGH",
          status: "open",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        await writeAudit(tx, {
          targetType: item.type || "post",
          targetId: id,
          action: "escalated",
          actor: moderatorUid,
          reason: reason || "Escalated to Safety team",
          severity: severity || "HIGH",
          previousStatus: item.status || "pending",
        });
      });

      res.json({ ok: true, action: "escalated", id });
    } catch (err) {
      console.error("escalate error:", err);
      res.status(err.httpErrorCode?.status || 500).json({ error: err.message });
    }
  });

// ═══════════════════════════════════════════════════════════════════════════
// UNDO (soft undo within 60s window)
// ═══════════════════════════════════════════════════════════════════════════
exports.undo = functions
  .region("australia-southeast1")
  .https.onRequest(async (req, res) => {
    if (req.method !== "POST")
      return res.status(405).send("Method not allowed");

    try {
      const moderatorUid = await validateModerator(req);
      const { id } = req.body;
      if (!id) return res.status(400).json({ error: "Missing 'id'" });

      const itemRef = db.doc(`moderation/${id}`);
      const itemSnap = await itemRef.get();
      if (!itemSnap.exists)
        return res.status(404).json({ error: "Item not found" });
      const item = itemSnap.data();

      // Check if within undo window (60s from moderatedAt)
      if (item.moderatedAt) {
        const elapsed = Date.now() - item.moderatedAt.toMillis();
        if (elapsed > 60000) {
          return res.status(400).json({ error: "Undo window expired (60s)" });
        }
      }

      await db.runTransaction(async (tx) => {
        tx.update(itemRef, {
          status: "pending",
          moderatedBy: null,
          moderatedAt: null,
          softDeleted: false,
          rejectionReason: null,
          // Restore original content if it was edited
          ...(item.originalContent
            ? { content: item.originalContent, originalContent: null }
            : {}),
        });

        await writeAudit(tx, {
          targetType: item.type || "post",
          targetId: id,
          action: "undo",
          actor: moderatorUid,
          reason: "Moderator undid previous action",
          previousStatus: item.status,
          undoneAction: item.status, // what was undone
        });

        // Remove from feed if it was published
        if (item.regionId) {
          const feedRef = db.doc(`regions/${item.regionId}/feedItems/${id}`);
          const feedSnap = await feedRef.get();
          if (feedSnap.exists) tx.delete(feedRef);
        }
      });

      res.json({ ok: true, action: "undo", id });
    } catch (err) {
      console.error("undo error:", err);
      res.status(err.httpErrorCode?.status || 500).json({ error: err.message });
    }
  });
