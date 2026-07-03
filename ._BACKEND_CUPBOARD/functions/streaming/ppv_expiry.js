// ═══════════════════════════════════════════════════════════════════════════
// PPV REPLAY EXPIRY — Automated cleanup of expired access windows
// Runs on schedule to revoke replay access after the configured window.
// ═══════════════════════════════════════════════════════════════════════════

const { onSchedule } = require("firebase-functions/v2/scheduler");
const { admin, db, REGION } = require("../config");
const {
  resolvePpvEventDocument,
  resolvePpvLookupIds,
} = require("../ppv/access_state");

// Default replay window: 48 hours
const REPLAY_WINDOW_MS = 48 * 60 * 60 * 1000;

// ─── Scheduled: Expire PPV Replay Access ─────────────────────────────────
// Runs every hour, finds purchases past the replay window, marks inactive.
const expirePPVReplays = onSchedule(
  {
    schedule: "every 1 hours",
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
  },
  async () => {
    const now = new Date();
    const cutoff = new Date(now.getTime() - REPLAY_WINDOW_MS);
    const writer = db.bulkWriter();
    const touchedPaths = new Set();
    const processedEventIds = new Set();
    let count = 0;

    writer.onWriteError((error) => {
      console.error("ppv_expiry write error:", error);
      return false;
    });

    const setMerge = (ref, data) => {
      if (touchedPaths.has(ref.path)) {
        return;
      }
      touchedPaths.add(ref.path);
      writer.set(ref, data, { merge: true });
      count++;
    };

    const revokePurchaseDoc = (ref) => {
      setMerge(ref, {
        isActive: false,
        replayExpired: true,
        replayExpiredAt: admin.firestore.FieldValue.serverTimestamp(),
        status: "expired",
      });
    };

    const revokeUserAccess = (userId, lookupIds) => {
      if (!userId) {
        return;
      }

      for (const lookupId of lookupIds) {
        setMerge(db.collection("ppv_access").doc(`${userId}_${lookupId}`), {
          isActive: false,
          replayExpired: true,
          replayExpiredAt: admin.firestore.FieldValue.serverTimestamp(),
          expiredAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        setMerge(
          db
            .collection("users")
            .doc(userId)
            .collection("ppv_access")
            .doc(lookupId),
          {
            isActive: false,
            replayExpired: true,
            replayExpiredAt: admin.firestore.FieldValue.serverTimestamp(),
            expiredAt: admin.firestore.FieldValue.serverTimestamp(),
          },
        );
      }
    };

    const revokeEventFamily = async (eventId) => {
      if (!eventId || processedEventIds.has(eventId)) {
        return;
      }
      processedEventIds.add(eventId);

      const lookupIds = await resolvePpvLookupIds(db, eventId);
      if (lookupIds.length === 0) {
        return;
      }

      const resolvedEvent = await resolvePpvEventDocument(db, eventId);
      if (resolvedEvent?.ref) {
        setMerge(resolvedEvent.ref, {
          status: "expired",
          replayAvailable: false,
        });
      }

      const purchaseFields = ["ppvId", "ppvEventId", "eventId"];
      for (const lookupId of lookupIds) {
        for (const field of purchaseFields) {
          const purchaseSnap = await db
            .collection("ppv_purchases")
            .where(field, "==", lookupId)
            .limit(250)
            .get();

          for (const purchaseDoc of purchaseSnap.docs) {
            const purchaseData = purchaseDoc.data();
            revokePurchaseDoc(purchaseDoc.ref);
            revokeUserAccess(purchaseData.userId, lookupIds);
          }
        }

        const accessSnap = await db
          .collection("ppv_access")
          .where("eventId", "==", lookupId)
          .limit(250)
          .get();

        for (const accessDoc of accessSnap.docs) {
          const accessData = accessDoc.data();
          setMerge(accessDoc.ref, {
            isActive: false,
            replayExpired: true,
            replayExpiredAt: admin.firestore.FieldValue.serverTimestamp(),
            expiredAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          revokeUserAccess(accessData.userId, lookupIds);
        }
      }
    };

    const expiredEventsSnap = await db
      .collection("ppv_events")
      .where("replayExpiry", "<=", admin.firestore.Timestamp.fromDate(now))
      .limit(100)
      .get();

    for (const eventDoc of expiredEventsSnap.docs) {
      await revokeEventFamily(eventDoc.id);
    }

    const legacyExpiredSnap = await db
      .collection("ppv_purchases")
      .where("isActive", "==", true)
      .where("eventEndedAt", "<=", admin.firestore.Timestamp.fromDate(cutoff))
      .limit(250)
      .get();

    for (const purchaseDoc of legacyExpiredSnap.docs) {
      const purchaseData = purchaseDoc.data();
      revokePurchaseDoc(purchaseDoc.ref);

      const legacyEventId =
        purchaseData.ppvId || purchaseData.ppvEventId || purchaseData.eventId;
      if (legacyEventId) {
        await revokeEventFamily(legacyEventId);
      } else if (purchaseData.userId) {
        revokeUserAccess(purchaseData.userId, [purchaseDoc.id]);
      }
    }

    await writer.close();

    if (count === 0) {
      console.log("ppv_expiry: No expired replays to process.");
      return;
    }

    console.log(`ppv_expiry: Expired ${count} replay access records.`);
  },
);

module.exports = { expirePPVReplays };
