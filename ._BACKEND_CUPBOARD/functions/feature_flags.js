// ═══════════════════════════════════════════════════════════════════════════
// FEATURE FLAGS — Firestore-backed Feature Gating System
// ═══════════════════════════════════════════════════════════════════════════
//
// Reads from `feature_flags` Firestore collection.
// Each flag doc has:
//   - enabled: boolean
//   - rolloutPercent: 0-100 (for gradual rollouts)
//   - allowedRoles: string[] (e.g. ['admin', 'promoter_pro'])
//   - allowedUsers: string[] (specific user IDs for testing)
//   - metadata: { description, owner, createdAt }
//
// Callable functions for the Flutter app + a scheduled audit.
// ═══════════════════════════════════════════════════════════════════════════

const { onCall } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { admin, db, REGION } = require("./config");

// ═══════════════════════════════════════════════════════════════════════════
// FLAG EVALUATION LOGIC
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Evaluate whether a flag is active for a given user context.
 */
function evaluateFlag(flagData, userId, userRole) {
  if (!flagData || !flagData.enabled) return false;

  // Explicit allowlist takes priority
  if (flagData.allowedUsers?.includes(userId)) return true;

  // Role-based gating
  if (flagData.allowedRoles?.length > 0) {
    if (!flagData.allowedRoles.includes(userRole)) return false;
  }

  // Percentage rollout (deterministic per-user hash)
  if (flagData.rolloutPercent !== undefined && flagData.rolloutPercent < 100) {
    const hash = simpleHash(userId + flagData.name);
    const bucket = hash % 100;
    if (bucket >= flagData.rolloutPercent) return false;
  }

  return true;
}

function simpleHash(str) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const chr = str.charCodeAt(i);
    hash = ((hash << 5) - hash + chr) | 0;
  }
  return Math.abs(hash);
}

// ═══════════════════════════════════════════════════════════════════════════
// CALLABLE: Get All Flags for User
// ═══════════════════════════════════════════════════════════════════════════

const getFeatureFlags = onCall({ region: REGION }, async (request) => {
  const { userId, userRole } = request.data || {};

  const flagsSnap = await db.collection("feature_flags").get();
  const flags = {};

  for (const doc of flagsSnap.docs) {
    const data = { ...doc.data(), name: doc.id };
    flags[doc.id] = evaluateFlag(data, userId || "", userRole || "free");
  }

  return { flags };
});

// ═══════════════════════════════════════════════════════════════════════════
// CALLABLE: Check Single Flag
// ═══════════════════════════════════════════════════════════════════════════

const checkFeatureFlag = onCall({ region: REGION }, async (request) => {
  const { flagName, userId, userRole } = request.data || {};

  if (!flagName) return { error: "flagName is required" };

  const flagDoc = await db.collection("feature_flags").doc(flagName).get();
  if (!flagDoc.exists) return { enabled: false, reason: "flag_not_found" };

  const data = { ...flagDoc.data(), name: flagDoc.id };
  const enabled = evaluateFlag(data, userId || "", userRole || "free");

  return { enabled, flagName };
});

// ═══════════════════════════════════════════════════════════════════════════
// CALLABLE: Update Flag (Admin Only)
// ═══════════════════════════════════════════════════════════════════════════

const updateFeatureFlag = onCall({ region: REGION }, async (request) => {
  const {
    flagName,
    enabled,
    rolloutPercent,
    allowedRoles,
    allowedUsers,
    description,
  } = request.data || {};

  if (!flagName) return { error: "flagName is required" };

  // Auth check — require admin
  const authUid = request.auth?.uid;
  if (!authUid) return { error: "Authentication required" };
  const userDoc = await db.collection("users").doc(authUid).get();
  if (!userDoc.exists || userDoc.data().role !== "admin") {
    return { error: "Admin access required" };
  }

  const update = {
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedBy: authUid,
  };
  if (enabled !== undefined) update.enabled = enabled;
  if (rolloutPercent !== undefined) update.rolloutPercent = rolloutPercent;
  if (allowedRoles !== undefined) update.allowedRoles = allowedRoles;
  if (allowedUsers !== undefined) update.allowedUsers = allowedUsers;
  if (description !== undefined) update.metadata = { description };

  await db
    .collection("feature_flags")
    .doc(flagName)
    .set(update, { merge: true });

  // Audit log
  await db.collection("feature_flag_audit").add({
    flagName,
    action: "update",
    changes: update,
    performedBy: authUid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { status: "ok", flagName };
});

// ═══════════════════════════════════════════════════════════════════════════
// CALLABLE: Seed Default Flags (run once during setup)
// ═══════════════════════════════════════════════════════════════════════════

const seedDefaultFlags = onCall({ region: REGION }, async (request) => {
  const authUid = request.auth?.uid;
  if (!authUid) return { error: "Authentication required" };
  const userDoc = await db.collection("users").doc(authUid).get();
  if (!userDoc.exists || userDoc.data().role !== "admin") {
    return { error: "Admin access required" };
  }

  const defaults = {
    dynamicPricing: {
      enabled: false,
      rolloutPercent: 0,
      allowedRoles: ["admin"],
      metadata: { description: "Demand-based PPV dynamic pricing engine" },
    },
    fightPredictor: {
      enabled: true,
      rolloutPercent: 100,
      metadata: { description: "AI fight outcome predictions on event pages" },
    },
    autoClipWorker: {
      enabled: true,
      rolloutPercent: 50,
      allowedRoles: ["admin", "promoter_pro"],
      metadata: {
        description: "Automatic highlight clip extraction from fight videos",
      },
    },
    antiFraud: {
      enabled: true,
      rolloutPercent: 100,
      metadata: { description: "Real-time transaction fraud detection" },
    },
    lowLatencyTier: {
      enabled: false,
      rolloutPercent: 0,
      allowedRoles: ["admin"],
      metadata: {
        description: "Sub-second WebRTC streaming tier for premium PPV",
      },
    },
    liveRoundPredictor: {
      enabled: false,
      rolloutPercent: 10,
      allowedRoles: ["admin", "promoter_pro"],
      metadata: {
        description: "Live round-by-round prediction updates during fights",
      },
    },
  };

  let seeded = 0;
  for (const [name, data] of Object.entries(defaults)) {
    const existing = await db.collection("feature_flags").doc(name).get();
    if (!existing.exists) {
      await db
        .collection("feature_flags")
        .doc(name)
        .set({
          ...data,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          createdBy: authUid,
        });
      seeded++;
    }
  }

  return { status: "ok", seeded, total: Object.keys(defaults).length };
});

// ═══════════════════════════════════════════════════════════════════════════
// SCHEDULED: Audit flag state daily (log snapshot for compliance)
// ═══════════════════════════════════════════════════════════════════════════

const auditFeatureFlags = onSchedule(
  { schedule: "every 24 hours", region: REGION, timeoutSeconds: 60 },
  async () => {
    const flagsSnap = await db.collection("feature_flags").get();
    const snapshot = {};
    for (const doc of flagsSnap.docs) {
      snapshot[doc.id] = {
        enabled: doc.data().enabled || false,
        rolloutPercent: doc.data().rolloutPercent || 0,
      };
    }

    await db.collection("feature_flag_audit").add({
      action: "daily_snapshot",
      snapshot,
      flagCount: flagsSnap.size,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(
      `[feature-flags] Daily audit: ${flagsSnap.size} flags captured`,
    );
  },
);

module.exports = {
  getFeatureFlags,
  checkFeatureFlag,
  updateFeatureFlag,
  seedDefaultFlags,
  auditFeatureFlags,
};
