// ═══════════════════════════════════════════════════════════════════════════
// ACCOUNT MANAGEMENT — Delete Account + Data Export
// GDPR Art. 17 · AU Privacy Act · Apple 5.1.1 · Google Play Policy
// ═══════════════════════════════════════════════════════════════════════════

const { onCall } = require("firebase-functions/v2/https");
const { admin, db, REGION } = require("../config");

const storage = admin.storage();

// ─── All DFC Firestore collections where user data lives ─────────────────
const USER_COLLECTIONS = [
  { collection: "posts", field: "authorId" },
  { collection: "comments", field: "authorId" },
  { collection: "fightwire_posts", field: "authorId" },
  { collection: "messages", field: "senderId" },
  { collection: "messages", field: "receiverId" },
  { collection: "friend_requests", field: "fromUserId" },
  { collection: "friend_requests", field: "toUserId" },
  { collection: "user_connections", field: "userId" },
  { collection: "user_connections", field: "friendId" },
  { collection: "reactions", field: "userId" },
  { collection: "saved_posts", field: "userId" },
  { collection: "stories", field: "authorId" },
  { collection: "story_highlights", field: "userId" },
  { collection: "watch_history", field: "userId" },
  { collection: "ppv_access", field: "userId" },
  { collection: "ppv_purchases", field: "userId" },
  { collection: "consents", field: "userId" },
  { collection: "user_onboarding", field: "userId" },
  { collection: "fighter_stats", field: "fighterId" },
  { collection: "training_logs", field: "userId" },
  { collection: "wellness_logs", field: "userId" },
  { collection: "articles", field: "authorId" },
  { collection: "marketplace_listings", field: "sellerId" },
  { collection: "report_history", field: "reporterId" },
  { collection: "blocked_users", field: "userId" },
  { collection: "export_packages", field: "userId" },
];

// Storage prefixes where user media lives
const STORAGE_PREFIXES = [
  "user_media/",
  "profile_photos/",
  "post_media/",
  "story_media/",
  "chat_media/",
];

// ═══════════════════════════════════════════════════════════════════════════
// deleteUserAccount — Full cascade delete
// ═══════════════════════════════════════════════════════════════════════════
exports.deleteUserAccount = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new Error("User must be authenticated.");
  }

  const userId = request.auth.uid;

  try {
    // 1. Cascade delete Firestore documents
    await deleteUserFirestoreData(userId);

    // 2. Delete notifications subcollection
    await deleteSubcollection(`notifications/${userId}/items`);
    await db.collection("notifications").doc(userId).delete();

    // 3. Remove from group conversations (don't delete, just remove member)
    await removeFromGroupConversations(userId);

    // 4. Delete media from Firebase Storage
    await deleteUserStorageFiles(userId);

    // 5. Delete the user profile document
    await db.collection("users").doc(userId).delete();

    // 6. Delete Firebase Auth account
    await admin.auth().deleteUser(userId);

    // 7. Audit log (anonymized)
    await db.collection("deletion_audit").add({
      deletedUserHash: hashCode(userId),
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
      collectionsProcessed: USER_COLLECTIONS.map((c) => c.collection),
      status: "completed",
    });

    return {
      status: "ok",
      message: "Account and all associated data deleted permanently.",
    };
  } catch (error) {
    console.error("deleteUserAccount error:", error);

    // Log failed deletion for manual follow-up
    await db.collection("deletion_audit").add({
      deletedUserHash: hashCode(userId),
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: "failed",
      error: error.message,
    });

    throw new Error("Failed to delete account. Please contact support.");
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// exportUserData — Gather all user data for GDPR export
// ═══════════════════════════════════════════════════════════════════════════
exports.exportUserData = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new Error("User must be authenticated.");
  }

  const userId = request.auth.uid;

  try {
    const exportData = {
      exportDate: new Date().toISOString(),
      userId,
      format: "DFC_DATA_EXPORT_v1",
    };

    // Gather user profile
    const userDoc = await db.collection("users").doc(userId).get();
    if (userDoc.exists) {
      const data = userDoc.data();
      // Redact sensitive internal fields
      delete data.passwordHash;
      delete data.internalFlags;
      exportData.profile = data;
    }

    // Gather from each collection
    for (const { collection, field } of USER_COLLECTIONS) {
      const key = `${collection}_${field}`;
      const snapshot = await db
        .collection(collection)
        .where(field, "==", userId)
        .get();

      if (!snapshot.empty) {
        if (!exportData[collection]) exportData[collection] = [];
        snapshot.forEach((doc) => {
          exportData[collection].push({ id: doc.id, ...doc.data() });
        });
      }
    }

    // Gather notifications subcollection
    const notifSnapshot = await db
      .collection(`notifications/${userId}/items`)
      .orderBy("createdAt", "desc")
      .limit(500)
      .get();

    if (!notifSnapshot.empty) {
      exportData.notifications = [];
      notifSnapshot.forEach((doc) => {
        exportData.notifications.push({ id: doc.id, ...doc.data() });
      });
    }

    // Store export for download
    const exportRef = await db.collection("export_packages").add({
      userId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24h
      status: "ready",
      dataSize: JSON.stringify(exportData).length,
    });

    return {
      status: "ok",
      exportId: exportRef.id,
      data: exportData,
      message: "Data export ready. Download within 24 hours.",
    };
  } catch (error) {
    console.error("exportUserData error:", error);
    throw new Error("Failed to export data. Please try again.");
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════

async function deleteUserFirestoreData(userId) {
  for (const { collection, field } of USER_COLLECTIONS) {
    let hasMore = true;

    while (hasMore) {
      const snapshot = await db
        .collection(collection)
        .where(field, "==", userId)
        .limit(400) // Stay under 500 batch limit
        .get();

      if (snapshot.empty) {
        hasMore = false;
        break;
      }

      const batch = db.batch();
      snapshot.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();

      hasMore = snapshot.size === 400;
    }
  }
}

async function deleteSubcollection(path) {
  let hasMore = true;

  while (hasMore) {
    const snapshot = await db.collection(path).limit(400).get();

    if (snapshot.empty) {
      hasMore = false;
      break;
    }

    const batch = db.batch();
    snapshot.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();

    hasMore = snapshot.size === 400;
  }
}

async function removeFromGroupConversations(userId) {
  const snapshot = await db
    .collection("conversations")
    .where("participants", "array-contains", userId)
    .get();

  if (snapshot.empty) return;

  const batch = db.batch();
  snapshot.forEach((doc) => {
    const participants = doc.data().participants || [];
    if (participants.length <= 2) {
      // 1-on-1: delete the conversation
      batch.delete(doc.ref);
    } else {
      // Group: just remove user
      batch.update(doc.ref, {
        participants: admin.firestore.FieldValue.arrayRemove(userId),
      });
    }
  });

  await batch.commit();
}

async function deleteUserStorageFiles(userId) {
  const bucket = storage.bucket();

  for (const prefix of STORAGE_PREFIXES) {
    try {
      const [files] = await bucket.getFiles({ prefix: `${prefix}${userId}/` });

      if (files.length === 0) continue;

      const deletePromises = files.map((file) => file.delete());
      await Promise.all(deletePromises);

      console.log(`Deleted ${files.length} files from ${prefix}${userId}/`);
    } catch (err) {
      // Prefix may not exist — continue
      console.warn(`Storage cleanup skip: ${prefix}${userId}/`, err.message);
    }
  }
}

function hashCode(str) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = (hash << 5) - hash + char;
    hash |= 0;
  }
  return hash.toString();
}
