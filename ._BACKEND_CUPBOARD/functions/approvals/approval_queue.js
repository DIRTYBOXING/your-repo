const admin = require("firebase-admin");
const db = admin.firestore();

/**
 * Create a new approval request
 * data = { userId, action, details }
 */
exports.createApproval = async (data) => {
  const ref = db.collection("agent_approvals").doc();
  await ref.set({
    ...data,
    status: "pending",
    createdAt: Date.now()
  });
  return { id: ref.id };
};

/**
 * Get all pending approvals
 */
exports.getPendingApprovals = async () => {
  const snap = await db.collection("agent_approvals")
    .where("status", "==", "pending")
    .get();

  return snap.docs.map(d => ({
    id: d.id,
    ...d.data()
  }));
};

/**
 * Resolve an approval request
 * resolution = "approved" or "denied"
 */
exports.resolveApproval = async (id, resolution) => {
  await db.collection("agent_approvals").doc(id).update({
    status: resolution,
    resolvedAt: Date.now()
  });

  return { id, status: resolution };
};
