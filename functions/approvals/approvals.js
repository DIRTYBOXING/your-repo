// ═══════════════════════════════════════════════════════════════════════════
// WAR ROOM APPROVALS — API for DM/Publish/Spend approval flow
// Surfaces pending approvals, decision capture, escalation, audit trail
// ═══════════════════════════════════════════════════════════════════════════

const { onCall } = require("firebase-functions/v2/https");
const { admin, db, REGION } = require("../config");

const APPROVALS_COLLECTION = "atlas_approvals";
const JOBS_COLLECTION = "atlas_jobs";
const AUDIT_COLLECTION = "atlas_audit";
const EVENTS_COLLECTION = "atlas_events";

// Valid decisions
const VALID_DECISIONS = ["approve", "reject", "request_changes", "escalate"];
const ESCALATION_TARGETS = ["legal", "medical", "admin"];

// ═══════════════════════════════════════════════════════════════════════════
// LIST APPROVALS — Filtered by status, type, region
// ═══════════════════════════════════════════════════════════════════════════
const approvalsList = onCall({ region: REGION }, async (request) => {
  const { status, type, limit: queryLimit } = request.data || {};

  let query = db.collection(APPROVALS_COLLECTION);

  if (status) {
    query = query.where("status", "==", status);
  } else {
    query = query.where("status", "==", "pending");
  }

  if (type) {
    query = query.where("type", "==", type);
  }

  const maxResults = Math.min(queryLimit || 50, 100);
  const snap = await query.orderBy("createdAt", "desc").limit(maxResults).get();

  const tickets = snap.docs.map((doc) => ({
    ticketId: doc.id,
    ...doc.data(),
    createdAt: doc.data().createdAt?.toDate?.()?.toISOString() || null,
  }));

  return {
    status: "ok",
    count: tickets.length,
    tickets,
  };
});

// ═══════════════════════════════════════════════════════════════════════════
// GET APPROVAL DETAIL — Full ticket payload with provenance and outputs
// ═══════════════════════════════════════════════════════════════════════════
const approvalsDetail = onCall({ region: REGION }, async (request) => {
  const { ticketId } = request.data || {};
  if (!ticketId) return { status: "error", message: "ticketId required" };

  const doc = await db.collection(APPROVALS_COLLECTION).doc(ticketId).get();
  if (!doc.exists) return { status: "error", message: "Ticket not found" };

  const data = doc.data();

  // Fetch related job data
  let jobData = null;
  if (data.jobId) {
    const jobDoc = await db.collection(JOBS_COLLECTION).doc(data.jobId).get();
    if (jobDoc.exists) jobData = { jobId: jobDoc.id, ...jobDoc.data() };
  }

  // Fetch audit trail for this ticket
  const auditSnap = await db
    .collection(AUDIT_COLLECTION)
    .where("ticketId", "==", ticketId)
    .orderBy("timestamp", "desc")
    .limit(20)
    .get();
  const auditTrail = auditSnap.docs.map((d) => ({
    ...d.data(),
    timestamp: d.data().timestamp?.toDate?.()?.toISOString() || null,
  }));

  return {
    status: "ok",
    ticket: {
      ticketId: doc.id,
      ...data,
      createdAt: data.createdAt?.toDate?.()?.toISOString() || null,
    },
    job: jobData,
    auditTrail,
  };
});

// ═══════════════════════════════════════════════════════════════════════════
// DECISION — Approve, reject, request changes, or escalate
// ═══════════════════════════════════════════════════════════════════════════
const approvalsDecision = onCall({ region: REGION }, async (request) => {
  const { ticketId, decision, reviewerId, comments, budgetOverrideUsd } =
    request.data || {};

  if (!ticketId) return { status: "error", message: "ticketId required" };
  if (!decision || !VALID_DECISIONS.includes(decision)) {
    return {
      status: "error",
      message: `decision must be one of: ${VALID_DECISIONS.join(", ")}`,
    };
  }
  if (!reviewerId) return { status: "error", message: "reviewerId required" };
  if (decision === "reject" && (!comments || comments.trim().length === 0)) {
    return {
      status: "error",
      message: "Rejection requires a reason in comments",
    };
  }

  const ticketRef = db.collection(APPROVALS_COLLECTION).doc(ticketId);
  const ticketDoc = await ticketRef.get();
  if (!ticketDoc.exists)
    return { status: "error", message: "Ticket not found" };

  const ticketData = ticketDoc.data();

  // Role check: legal-required tickets need legal role
  if (ticketData.requiresLegal && decision === "approve") {
    // In production, verify reviewerId has legal role via auth claims
    // For now, log the requirement
    console.log(`Legal approval by ${reviewerId} for ticket ${ticketId}`);
  }

  // Safety flag acknowledgement check
  if (decision === "approve" && ticketData.safetyFlags) {
    const flags = ticketData.safetyFlags;
    if (flags.requiresLegal || flags.medicalGate || flags.ageGating) {
      // Approval goes through but is logged as safety-acknowledged
      console.log(
        `Safety flags acknowledged by ${reviewerId}: legal=${flags.requiresLegal}, medical=${flags.medicalGate}, age=${flags.ageGating}`,
      );
    }
  }

  const newStatus =
    decision === "approve"
      ? "approved"
      : decision === "reject"
        ? "rejected"
        : decision === "request_changes"
          ? "changes_requested"
          : "escalated";

  // Update ticket
  await ticketRef.update({
    status: newStatus,
    decision,
    reviewerId,
    comments: comments || "",
    budgetOverrideUsd: budgetOverrideUsd || null,
    decidedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Write immutable audit record
  await db.collection(AUDIT_COLLECTION).add({
    ticketId,
    jobId: ticketData.jobId || null,
    action: `approval_${decision}`,
    reviewerId,
    comments: comments || "",
    budgetOverrideUsd: budgetOverrideUsd || null,
    previousStatus: ticketData.status,
    newStatus,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  // If approved, update the associated job to resume processing
  if (decision === "approve" && ticketData.jobId) {
    await db
      .collection(JOBS_COLLECTION)
      .doc(ticketData.jobId)
      .update({
        status: "approved",
        approvedBy: reviewerId,
        approvedAt: admin.firestore.FieldValue.serverTimestamp(),
        budgetOverrideUsd: budgetOverrideUsd || null,
      });
  }

  // If rejected, mark job as rejected
  if (decision === "reject" && ticketData.jobId) {
    await db.collection(JOBS_COLLECTION).doc(ticketData.jobId).update({
      status: "rejected",
      rejectedBy: reviewerId,
      rejectionReason: comments,
      rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  // Emit event
  await db.collection(EVENTS_COLLECTION).add({
    type: "approval_decision",
    ticketId,
    jobId: ticketData.jobId || null,
    decision,
    reviewerId,
    emittedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    status: "ok",
    ticketId,
    decision,
    newStatus,
  };
});

// ═══════════════════════════════════════════════════════════════════════════
// ESCALATE — Route to Legal, Medical, or Admin
// ═══════════════════════════════════════════════════════════════════════════
const approvalsEscalate = onCall({ region: REGION }, async (request) => {
  const { ticketId, to, reason, escalatedBy } = request.data || {};

  if (!ticketId) return { status: "error", message: "ticketId required" };
  if (!to || !ESCALATION_TARGETS.includes(to)) {
    return {
      status: "error",
      message: `to must be one of: ${ESCALATION_TARGETS.join(", ")}`,
    };
  }
  if (!reason)
    return { status: "error", message: "reason required for escalation" };

  const ticketRef = db.collection(APPROVALS_COLLECTION).doc(ticketId);
  const ticketDoc = await ticketRef.get();
  if (!ticketDoc.exists)
    return { status: "error", message: "Ticket not found" };

  // Update ticket
  await ticketRef.update({
    status: "escalated",
    escalatedTo: to,
    escalationReason: reason,
    escalatedBy: escalatedBy || "system",
    escalatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Audit
  await db.collection(AUDIT_COLLECTION).add({
    ticketId,
    jobId: ticketDoc.data().jobId || null,
    action: `escalated_to_${to}`,
    escalatedBy: escalatedBy || "system",
    reason,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Event
  await db.collection(EVENTS_COLLECTION).add({
    type: "approval_escalated",
    ticketId,
    escalatedTo: to,
    reason,
    emittedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    status: "ok",
    ticketId,
    escalatedTo: to,
    message: `Ticket escalated to ${to}`,
  };
});

// ═══════════════════════════════════════════════════════════════════════════
// STATS — Approval queue health metrics
// ═══════════════════════════════════════════════════════════════════════════
const approvalsStats = onCall({ region: REGION }, async () => {
  const pendingSnap = await db
    .collection(APPROVALS_COLLECTION)
    .where("status", "==", "pending")
    .count()
    .get();
  const approvedSnap = await db
    .collection(APPROVALS_COLLECTION)
    .where("status", "==", "approved")
    .count()
    .get();
  const rejectedSnap = await db
    .collection(APPROVALS_COLLECTION)
    .where("status", "==", "rejected")
    .count()
    .get();
  const escalatedSnap = await db
    .collection(APPROVALS_COLLECTION)
    .where("status", "==", "escalated")
    .count()
    .get();

  return {
    status: "ok",
    pending: pendingSnap.data().count,
    approved: approvedSnap.data().count,
    rejected: rejectedSnap.data().count,
    escalated: escalatedSnap.data().count,
  };
});

module.exports = {
  approvalsList,
  approvalsDetail,
  approvalsDecision,
  approvalsEscalate,
  approvalsStats,
};
