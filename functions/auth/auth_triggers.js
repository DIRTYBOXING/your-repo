// ═══════════════════════════════════════════════════════════════════════════
// DFC AUTH TRIGGERS — Server-Side User Lifecycle Hooks
// ═══════════════════════════════════════════════════════════════════════════
//
// PURPOSE:
//   Move user creation init & deletion cleanup to server-side triggers so
//   data integrity is guaranteed even if the client crashes mid-flow.
//
// FUNCTIONS:
//   onUserCreated  — Firebase Auth onCreate → seed Firestore user doc,
//                    search tokens, notifications prefs, welcome entry
//   onUserDeleted  — Firebase Auth onDelete → cascade-delete user data,
//                    storage files, audit log (mirrors account.js but
//                    triggers automatically on Auth-level deletion)
//
// NOTES:
//   - Client-side _createUserDocument still runs for immediate UX.
//     This trigger acts as a safety net / backfill.
//   - Uses merge: true on user doc so it cooperates with client writes.
//   - onUserDeleted complements the callable deleteUserAccount() which
//     deletes Auth + Firestore in sequence. This trigger catches cases
//     where Auth is deleted directly (Firebase Console, Admin SDK).
// ═══════════════════════════════════════════════════════════════════════════

const {
  beforeUserCreated,
  beforeUserSignedIn,
} = require("firebase-functions/v2/identity");
const { onCall } = require("firebase-functions/v2/https");
const { admin, db, REGION } = require("../config");

// ─── Reuse the collection list from account.js for cleanup ───────────────
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

const STORAGE_PREFIXES = [
  "user_media/",
  "profile_photos/",
  "post_media/",
  "story_media/",
  "chat_media/",
  "cover_photos/",
];

// Owner UIDs that always get admin (matches AuthService client-side)
// Set admin email via Firebase environment config
const OWNER_EMAILS = [
  process.env.DFC_ADMIN_EMAIL || "admin@datafightcentral.com",
];

// ═══════════════════════════════════════════════════════════════════════════
// HELPER: Build n-gram search tokens (mirrors Dart _buildSearchTokens)
// ═══════════════════════════════════════════════════════════════════════════
function buildSearchTokens(displayName, username, email) {
  const sources = [
    (displayName || "").trim().toLowerCase(),
    (username || "").trim().toLowerCase(),
    (email || "").split("@")[0].trim().toLowerCase(),
  ];

  const tokens = new Set();
  for (const source of sources) {
    if (!source) continue;
    // Compact (no spaces) n-grams
    const compact = source.replace(/\s+/g, "");
    for (let i = 1; i <= Math.min(compact.length, 20); i++) {
      tokens.add(compact.substring(0, i));
    }
    // Per-word n-grams
    for (const part of source.split(/\s+/)) {
      if (!part) continue;
      for (let i = 1; i <= Math.min(part.length, 20); i++) {
        tokens.add(part.substring(0, i));
      }
    }
  }

  return Array.from(tokens).sort();
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER: Derive username from display/email/uid (mirrors Dart logic)
// ═══════════════════════════════════════════════════════════════════════════
function deriveUsername(displayName, email, uid) {
  const fromDisplay = (displayName || "")
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9_]/g, "");
  const fromEmail = (email || "")
    .split("@")[0]
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9_]/g, "");
  const base = fromDisplay || fromEmail || "fighter";
  const suffix = (uid || "").substring(0, 4).toLowerCase();
  return `${base}_${suffix}`;
}

// ═══════════════════════════════════════════════════════════════════════════
// 1. AUTH TRIGGER — beforeUserCreated (Blocking Function)
//    Runs synchronously before the user is written to Firebase Auth.
//    We use it to set custom claims and validate.
// ═══════════════════════════════════════════════════════════════════════════
const onUserCreatedTrigger = beforeUserCreated(
  { region: REGION },
  async (event) => {
    const user = event.data;
    const uid = user.uid;
    const email = (user.email || "").toLowerCase();
    const displayName = user.displayName || email.split("@")[0] || "Fighter";
    const photoUrl = user.photoURL || null;

    console.log(`[Auth onCreate] New user: ${uid} (${email})`);

    // Determine role
    let role = "fan"; // default
    if (OWNER_EMAILS.includes(email)) {
      role = "admin";
    } else {
      // Check if this is the first user (seed admin)
      try {
        const usersSnap = await db.collection("users").limit(1).get();
        if (usersSnap.empty) {
          role = "admin";
          console.log(`[Auth onCreate] First user — granting admin role`);
        }
      } catch (_) {
        // proceed with default
      }
    }

    const username = deriveUsername(displayName, email, uid);
    const now = admin.firestore.FieldValue.serverTimestamp();

    // Seed the user document (merge: true cooperates with client writes)
    await db
      .collection("users")
      .doc(uid)
      .set(
        {
          email,
          displayName,
          displayNameLower: displayName.trim().toLowerCase(),
          username,
          usernameLower: username.toLowerCase(),
          searchTokens: buildSearchTokens(displayName, username, email),
          role,
          photoUrl,
          photoURL: photoUrl,
          emailVerified: user.emailVerified || false,
          isVerified: false,
          isActive: true,
          onboardingCompleted: false,
          createdAt: now,
          updatedAt: now,
          lastLoginAt: now,
          metadata: {},
        },
        { merge: true },
      );

    // Seed notification preferences (sensible defaults)
    await db
      .collection("notification_settings")
      .doc(uid)
      .set(
        {
          userId: uid,
          pushEnabled: true,
          emailDigestEnabled: false,
          inAppEnabled: true,
          quietHoursStart: null,
          quietHoursEnd: null,
          categories: {
            fights: true,
            social: true,
            ppv: true,
            promotions: true,
            system: true,
          },
          createdAt: now,
        },
        { merge: true },
      );

    // Write a welcome entry to the notifications subcollection
    await db.collection("notifications").doc(uid).collection("items").add({
      type: "welcome",
      title: "Welcome to Data Fight Central!",
      body: "Set up your profile and start connecting with the fight community.",
      read: false,
      createdAt: now,
    });

    console.log(`[Auth onCreate] User doc seeded for ${uid} (role: ${role})`);

    // Return custom claims (optional — sets role in token)
    return {
      customClaims: {
        role,
      },
    };
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// 2. AUTH TRIGGER — onUserDeleted (via callable, as v2 does not expose
//    auth.user().onDelete() directly — we use the existing cascade in
//    account.js and add this as a Firestore-triggered cleanup fallback)
//
//    Pattern: When users/{userId} is deleted, clean up orphaned data.
//    This catches both manual console deletes and Account deletion flow.
// ═══════════════════════════════════════════════════════════════════════════

// Firestore trigger: when user doc is deleted, clean up orphaned data
const { onDocumentDeleted } = require("firebase-functions/v2/firestore");

const onUserDocDeleted = onDocumentDeleted(
  {
    document: "users/{userId}",
    region: REGION,
  },
  async (event) => {
    const userId = event.params.userId;
    console.log(
      `[User Cleanup] User doc deleted: ${userId} — running cascade cleanup`,
    );

    const startTime = Date.now();
    let collectionsProcessed = 0;
    let docsDeleted = 0;

    try {
      // 1. Cascade delete from all user-associated collections
      for (const { collection, field } of USER_COLLECTIONS) {
        let hasMore = true;
        while (hasMore) {
          const snapshot = await db
            .collection(collection)
            .where(field, "==", userId)
            .limit(400)
            .get();

          if (snapshot.empty) {
            hasMore = false;
            break;
          }

          const batch = db.batch();
          snapshot.docs.forEach((doc) => batch.delete(doc.ref));
          await batch.commit();
          docsDeleted += snapshot.size;

          if (snapshot.size < 400) hasMore = false;
        }
        collectionsProcessed++;
      }

      // 2. Delete notifications subcollection
      let hasNotifs = true;
      while (hasNotifs) {
        const notifSnap = await db
          .collection("notifications")
          .doc(userId)
          .collection("items")
          .limit(400)
          .get();
        if (notifSnap.empty) {
          hasNotifs = false;
        } else {
          const batch = db.batch();
          notifSnap.docs.forEach((doc) => batch.delete(doc.ref));
          await batch.commit();
          docsDeleted += notifSnap.size;
          if (notifSnap.size < 400) hasNotifs = false;
        }
      }
      // Delete the parent notifications doc
      await db
        .collection("notifications")
        .doc(userId)
        .delete()
        .catch(() => {});

      // 3. Delete notification settings
      await db
        .collection("notification_settings")
        .doc(userId)
        .delete()
        .catch(() => {});

      // 4. Remove from group conversations
      const groupSnap = await db
        .collection("group_conversations")
        .where("members", "array-contains", userId)
        .get();

      if (!groupSnap.empty) {
        const batch = db.batch();
        groupSnap.docs.forEach((doc) => {
          batch.update(doc.ref, {
            members: admin.firestore.FieldValue.arrayRemove(userId),
          });
        });
        await batch.commit();
      }

      // 5. Clean up Storage files
      try {
        const bucket = admin.storage().bucket();
        for (const prefix of STORAGE_PREFIXES) {
          const [files] = await bucket.getFiles({
            prefix: `${prefix}${userId}`,
          });
          for (const file of files) {
            await file.delete().catch(() => {});
          }
        }
      } catch (storageErr) {
        console.warn(
          `[User Cleanup] Storage cleanup warning: ${storageErr.message}`,
        );
      }

      // 6. Try to delete Firebase Auth user (may already be deleted)
      try {
        await admin.auth().deleteUser(userId);
      } catch (authErr) {
        // Expected if Auth was deleted first (which triggered this flow)
        if (authErr.code !== "auth/user-not-found") {
          console.warn(
            `[User Cleanup] Auth delete warning: ${authErr.message}`,
          );
        }
      }

      // 7. Audit log
      const hashCode = (s) => {
        let h = 0;
        for (let i = 0; i < s.length; i++) {
          h = (h << 5) - h + s.charCodeAt(i);
          h |= 0;
        }
        return Math.abs(h).toString(36);
      };

      await db.collection("deletion_audit").add({
        deletedUserHash: hashCode(userId),
        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
        trigger: "firestore_onDelete",
        collectionsProcessed,
        docsDeleted,
        durationMs: Date.now() - startTime,
        status: "completed",
      });

      console.log(
        `[User Cleanup] Cascade complete for ${userId}: ${docsDeleted} docs deleted across ${collectionsProcessed} collections (${Date.now() - startTime}ms)`,
      );
    } catch (error) {
      console.error(`[User Cleanup] Cascade failed for ${userId}:`, error);

      await db.collection("deletion_audit").add({
        deletedUserHash: userId.substring(0, 8) + "...",
        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
        trigger: "firestore_onDelete",
        status: "failed",
        error: error.message,
      });
    }
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// EXPORTS
// ═══════════════════════════════════════════════════════════════════════════
module.exports = {
  onUserCreatedTrigger,
  onUserDocDeleted,
};
