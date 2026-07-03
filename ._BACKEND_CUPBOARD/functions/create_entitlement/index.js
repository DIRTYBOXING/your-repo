const { onCall } = require("firebase-functions/v2/https");
const { admin, db, REGION } = require("../config");

const createEntitlement = onCall({ region: REGION }, async (request) => {
  const {
    userId,
    eventId,
    amountCents,
    tierId,
    platformShare,
    promoterShare,
    purchaseType,
    purchaseId,
    requestId,
    promotionId,
    metadata,
  } = request.data || {};

  if (!userId || !eventId || amountCents == null || !tierId) {
    return {
      status: "error",
      message:
        "Missing required fields: userId, eventId, amountCents, tierId",
    };
  }

  const entitlementId = `${userId}_${eventId}`;
  const entitlementRef = db.collection("entitlements").doc(entitlementId);
  const purchaseRecordId = purchaseId || entitlementId;
  const purchaseRecordRef = db.collection("ppv_purchases").doc(purchaseRecordId);

  const [entitlementSnap, purchaseSnap] = await Promise.all([
    entitlementRef.get(),
    purchaseRecordRef.get(),
  ]);

  const resolvedRequestId = requestId || purchaseId || entitlementId;
  const resolvedSource = metadata?.source || "checkout_webhook";
  await entitlementRef.set({
    userId,
    eventId,
    amountCents: Number(amountCents),
    tierId,
    purchaseType: purchaseType || "ppv",
    accessType: purchaseType || "ppv",
    purchaseId: purchaseId || null,
    promotionId: promotionId || null,
    platformShare: platformShare == null ? null : Number(platformShare),
    promoterShare: promoterShare == null ? null : Number(promoterShare),
    hasAccess: true,
    isActive: true,
    status: "active",
    createdBy: "createEntitlement",
    requestId: resolvedRequestId,
    source: resolvedSource,
    metadata: metadata || {},
    createdAt:
      entitlementSnap.exists && entitlementSnap.data()?.createdAt
        ? entitlementSnap.data().createdAt
        : admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  await purchaseRecordRef.set({
    userId,
    ppvEventId: eventId,
    eventId,
    tierId,
    purchaseType: purchaseType || "ppv",
    promotionId: promotionId || null,
    amountCents: Number(amountCents),
    platformShare: platformShare == null ? null : Number(platformShare),
    promoterShare: promoterShare == null ? null : Number(promoterShare),
    accessGranted: true,
    status: "completed",
    paymentStatus: "succeeded",
    requestId: resolvedRequestId,
    source: resolvedSource,
    createdBy: "createEntitlement",
    purchasedAt:
      purchaseSnap.exists && purchaseSnap.data()?.purchasedAt
        ? purchaseSnap.data().purchasedAt
        : admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    metadata: metadata || {},
  }, { merge: true });

  const isIdempotent = entitlementSnap.exists;
  logMetric(isIdempotent ? "entitlement_idempotent" : "entitlement_granted", {
    userId,
    eventId,
    tierId,
    source: resolvedSource,
    purchaseType: purchaseType || "ppv",
    amountCents: Number(amountCents),
  });

  return {
    status: "ok",
    entitlementId,
  };
});

// ── Structured metric log helper ──────────────────────────────────────────────
// Cloud Monitoring can extract log-based metrics from these JSON entries.
// Create a log-based metric in GCP Console filtering on:
//   jsonPayload.metric = "entitlement_granted" (or "entitlement_idempotent")
function logMetric(metric, labels = {}) {
  console.log(
    JSON.stringify({
      severity: "INFO",
      metric,
      service: "createEntitlement",
      ...labels,
      ts: new Date().toISOString(),
    })
  );
}

module.exports = {
  createEntitlement,
};
