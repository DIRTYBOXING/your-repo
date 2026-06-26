// ═══════════════════════════════════════════════════════════════════════════
// DFC IMAGE RIGHTS — Firebase Cloud Functions
//
// Server-side enforcement of the image rights pipeline:
// • Admin approval/rejection/revocation
// • Public takedown filing (DMCA-ready)
// • License expiry sweep (scheduled)
// • Image stats for admin dashboard
// • Audit trail querying
//
// RULE: No image is served unless status === 'approved' && !isTakenDown
// ═══════════════════════════════════════════════════════════════════════════

const { onCall } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { admin, db, REGION } = require("../config");

const IMAGES_COL = "images";
const TAKEDOWNS_COL = "image_takedowns";
const AUDIT_COL = "image_audit_log";

// ─── Helpers ─────────────────────────────────────────────────────────────

async function writeAudit(imageId, action, performedBy, details = {}) {
  await db.collection(AUDIT_COL).add({
    imageId,
    action,
    performedBy,
    details,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function requireAdmin(request) {
  if (!request.auth) throw new Error("Authentication required");
  const userDoc = await db.collection("users").doc(request.auth.uid).get();
  if (!userDoc.exists || userDoc.data().role !== "admin") {
    throw new Error("Admin access required");
  }
  return request.auth.uid;
}

// ═══════════════════════════════════════════════════════════════════════════
// ADMIN: APPROVE IMAGE
// ═══════════════════════════════════════════════════════════════════════════

const imageApprove = onCall({ region: REGION }, async (request) => {
  const adminUid = await requireAdmin(request);
  const { imageId } = request.data;

  if (!imageId) return { status: "error", message: "imageId required" };

  const imageRef = db.collection(IMAGES_COL).doc(imageId);
  const imageDoc = await imageRef.get();
  if (!imageDoc.exists) return { status: "error", message: "Image not found" };

  const now = admin.firestore.Timestamp.now();

  await imageRef.update({
    status: "approved",
    approvedBy: adminUid,
    approvedAt: now,
    updatedAt: now,
  });

  await writeAudit(imageId, "approve", adminUid);

  return {
    status: "ok",
    imageId,
    message: "Image approved for public use",
  };
});

// ═══════════════════════════════════════════════════════════════════════════
// ADMIN: REJECT IMAGE
// ═══════════════════════════════════════════════════════════════════════════

const imageReject = onCall({ region: REGION }, async (request) => {
  const adminUid = await requireAdmin(request);
  const { imageId, reason } = request.data;

  if (!imageId || !reason) {
    return { status: "error", message: "imageId and reason required" };
  }

  const imageRef = db.collection(IMAGES_COL).doc(imageId);
  const imageDoc = await imageRef.get();
  if (!imageDoc.exists) return { status: "error", message: "Image not found" };

  const now = admin.firestore.Timestamp.now();

  await imageRef.update({
    status: "rejected",
    rejectedBy: adminUid,
    rejectedAt: now,
    rejectionReason: reason,
    updatedAt: now,
  });

  await writeAudit(imageId, "reject", adminUid, { reason });

  return {
    status: "ok",
    imageId,
    message: "Image rejected",
  };
});

// ═══════════════════════════════════════════════════════════════════════════
// ADMIN: REVOKE PREVIOUSLY APPROVED IMAGE
// ═══════════════════════════════════════════════════════════════════════════

const imageRevoke = onCall({ region: REGION }, async (request) => {
  const adminUid = await requireAdmin(request);
  const { imageId, reason } = request.data;

  if (!imageId || !reason) {
    return { status: "error", message: "imageId and reason required" };
  }

  const imageRef = db.collection(IMAGES_COL).doc(imageId);
  const now = admin.firestore.Timestamp.now();

  await imageRef.update({
    status: "revoked",
    isTakenDown: true,
    takedownReason: reason,
    takenDownAt: now,
    updatedAt: now,
  });

  await writeAudit(imageId, "revoke", adminUid, { reason });

  return {
    status: "ok",
    imageId,
    message: "Image revoked from all public surfaces",
  };
});

// ═══════════════════════════════════════════════════════════════════════════
// PUBLIC: FILE TAKEDOWN REQUEST (DMCA-ready)
// ═══════════════════════════════════════════════════════════════════════════

const imageTakedownRequest = onCall({ region: REGION }, async (request) => {
  const { imageId, complainantName, complainantEmail, reason, evidenceUrl } =
    request.data;

  if (!imageId || !complainantName || !complainantEmail || !reason) {
    return {
      status: "error",
      message:
        "imageId, complainantName, complainantEmail, and reason required",
    };
  }

  const imageRef = db.collection(IMAGES_COL).doc(imageId);
  const imageDoc = await imageRef.get();
  if (!imageDoc.exists) return { status: "error", message: "Image not found" };

  const now = admin.firestore.Timestamp.now();

  // Immediately remove from public
  await imageRef.update({
    isTakenDown: true,
    takedownReason: reason,
    takenDownAt: now,
    takedownRequestedBy: complainantEmail,
    status: "revoked",
    updatedAt: now,
  });

  // Create takedown record
  const takedownRef = await db.collection(TAKEDOWNS_COL).add({
    imageId,
    complainantName,
    complainantEmail,
    reason,
    evidenceUrl: evidenceUrl || null,
    status: "received",
    investigatorId: null,
    resolution: null,
    receivedAt: now,
    resolvedAt: null,
  });

  // Link to image
  await imageRef.update({ disputeId: takedownRef.id });

  await writeAudit(imageId, "takedown_filed", `external:${complainantEmail}`, {
    complainantName,
    complainantEmail,
    reason,
    takedownId: takedownRef.id,
  });

  return {
    status: "ok",
    takedownId: takedownRef.id,
    message:
      "Takedown received. Image removed from public surfaces immediately. We will investigate within 24 hours.",
  };
});

// ═══════════════════════════════════════════════════════════════════════════
// ADMIN: RESOLVE TAKEDOWN
// ═══════════════════════════════════════════════════════════════════════════

const imageTakedownResolve = onCall({ region: REGION }, async (request) => {
  const adminUid = await requireAdmin(request);
  const { takedownId, upheld, resolution } = request.data;

  if (!takedownId || upheld === undefined || !resolution) {
    return {
      status: "error",
      message: "takedownId, upheld (bool), and resolution required",
    };
  }

  const takedownRef = db.collection(TAKEDOWNS_COL).doc(takedownId);
  const takedownDoc = await takedownRef.get();
  if (!takedownDoc.exists) {
    return { status: "error", message: "Takedown not found" };
  }

  const takedownData = takedownDoc.data();
  const imageId = takedownData.imageId;
  const now = admin.firestore.Timestamp.now();
  const status = upheld ? "upheld" : "dismissed";

  await takedownRef.update({
    status,
    investigatorId: adminUid,
    resolution,
    resolvedAt: now,
  });

  if (upheld) {
    // Delete from storage if possible
    const imageDoc = await db.collection(IMAGES_COL).doc(imageId).get();
    if (imageDoc.exists) {
      const storagePath = imageDoc.data().storagePath;
      if (storagePath) {
        try {
          await admin.storage().bucket().file(storagePath).delete();
          const thumbPath = storagePath.replace("original.", "thumb.");
          await admin.storage().bucket().file(thumbPath).delete();
        } catch (e) {
          console.warn("Storage cleanup failed:", e.message);
        }
      }

      await db.collection(IMAGES_COL).doc(imageId).update({
        status: "revoked",
        isTakenDown: true,
        updatedAt: now,
      });
    }
  } else {
    // Restore the image
    await db.collection(IMAGES_COL).doc(imageId).update({
      status: "approved",
      isTakenDown: false,
      takedownReason: null,
      takenDownAt: null,
      takedownRequestedBy: null,
      disputeId: null,
      updatedAt: now,
    });
  }

  await writeAudit(
    imageId,
    upheld ? "takedown_upheld" : "takedown_dismissed",
    adminUid,
    { takedownId, resolution },
  );

  return {
    status: "ok",
    takedownId,
    imageId,
    decision: status,
    message: upheld
      ? "Takedown upheld — image permanently removed"
      : "Takedown dismissed — image restored to public",
  };
});

// ═══════════════════════════════════════════════════════════════════════════
// ADMIN: GET IMAGE STATS
// ═══════════════════════════════════════════════════════════════════════════

const imageStats = onCall({ region: REGION }, async (request) => {
  await requireAdmin(request);

  const statuses = ["pending", "approved", "rejected", "revoked", "expired"];
  const counts = {};

  for (const s of statuses) {
    const snap = await db
      .collection(IMAGES_COL)
      .where("status", "==", s)
      .count()
      .get();
    counts[s] = snap.data().count;
  }

  const takedownSnap = await db
    .collection(TAKEDOWNS_COL)
    .where("status", "==", "received")
    .count()
    .get();
  counts.pendingTakedowns = takedownSnap.data().count;

  return { status: "ok", counts };
});

// ═══════════════════════════════════════════════════════════════════════════
// ADMIN: GET AUDIT LOG FOR IMAGE
// ═══════════════════════════════════════════════════════════════════════════

const imageAuditLog = onCall({ region: REGION }, async (request) => {
  await requireAdmin(request);
  const { imageId } = request.data;

  if (!imageId) return { status: "error", message: "imageId required" };

  const snap = await db
    .collection(AUDIT_COL)
    .where("imageId", "==", imageId)
    .orderBy("timestamp", "desc")
    .limit(100)
    .get();

  const entries = snap.docs.map((d) => ({
    id: d.id,
    ...d.data(),
    timestamp: d.data().timestamp?.toDate?.()?.toISOString() || null,
  }));

  return { status: "ok", entries };
});

// ═══════════════════════════════════════════════════════════════════════════
// SCHEDULED: LICENSE EXPIRY SWEEP (runs daily)
// ═══════════════════════════════════════════════════════════════════════════

const imageExpirySweep = onSchedule(
  { schedule: "every 24 hours", region: REGION },
  async () => {
    const now = admin.firestore.Timestamp.now();
    const expiredSnap = await db
      .collection(IMAGES_COL)
      .where("status", "==", "approved")
      .where("licenseExpiresAt", "<=", now)
      .get();

    let count = 0;
    const batch = db.batch();

    for (const doc of expiredSnap.docs) {
      batch.update(doc.ref, {
        status: "expired",
        updatedAt: now,
      });
      count++;
    }

    if (count > 0) {
      await batch.commit();

      // Audit each expiry
      for (const doc of expiredSnap.docs) {
        await writeAudit(doc.id, "license_expired", "system", {
          licenseExpiresAt: doc
            .data()
            .licenseExpiresAt?.toDate?.()
            ?.toISOString(),
        });
      }
    }

    console.log(`Image expiry sweep: ${count} images expired`);
    return null;
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// EXPORTS
// ═══════════════════════════════════════════════════════════════════════════

module.exports = {
  imageApprove,
  imageReject,
  imageRevoke,
  imageTakedownRequest,
  imageTakedownResolve,
  imageStats,
  imageAuditLog,
  imageExpirySweep,
};
