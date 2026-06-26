"use strict";

const admin = require("firebase-admin");

const POSITIVE_STATUSES = new Set([
  "complete",
  "completed",
  "paid",
  "succeeded",
]);
const NEGATIVE_STATUSES = new Set([
  "canceled",
  "cancelled",
  "expired",
  "failed",
]);

function getDb() {
  return admin.firestore();
}

function sessionsCol() {
  return getDb().collection("ppv_checkout_sessions");
}

function ts() {
  return admin.firestore.FieldValue.serverTimestamp();
}

function toMillis(value) {
  if (!value) return 0;
  if (typeof value.toMillis === "function") {
    return value.toMillis();
  }
  if (value instanceof Date) {
    return value.getTime();
  }
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? 0 : parsed.getTime();
}

function normalizeStatus(raw) {
  if (!raw) return "unknown";
  const status = raw.toString().trim().toLowerCase();
  if (POSITIVE_STATUSES.has(status)) return "complete";
  if (NEGATIVE_STATUSES.has(status)) return "failed";
  return status || "unknown";
}

function toCheckoutSession(doc) {
  if (!doc?.exists) return null;
  const data = doc.data() || {};
  return {
    docId: doc.id,
    sessionId: data.sessionId || doc.id,
    userId: data.userId || null,
    ppvId: data.ppvId || data.eventId || null,
    priceId: data.priceId || null,
    status: normalizeStatus(data.status),
    createdAt: data.createdAt || null,
    completedAt: data.completedAt || null,
    stripePaymentIntentId: data.stripePaymentIntentId || null,
    source: data.source || null,
  };
}

async function findCheckoutSessionDoc(sessionId) {
  if (!sessionId) return null;

  const directDoc = await sessionsCol().doc(sessionId).get();
  if (directDoc.exists) {
    return directDoc;
  }

  const query = await sessionsCol()
    .where("sessionId", "==", sessionId)
    .limit(1)
    .get();

  if (query.empty) {
    return null;
  }

  return query.docs[0];
}

async function createPendingCheckoutSession({
  sessionId,
  userId,
  ppvId,
  priceId,
  source,
}) {
  if (!sessionId || !userId || !ppvId) {
    throw new Error("sessionId, userId, and ppvId are required");
  }

  await sessionsCol()
    .doc(sessionId)
    .set(
      {
        sessionId,
        userId,
        ppvId,
        priceId: priceId || null,
        status: "pending",
        source: source || "entitlements-service",
        createdAt: ts(),
        updatedAt: ts(),
      },
      { merge: true },
    );

  return true;
}

async function getCheckoutSession(sessionId) {
  const doc = await findCheckoutSessionDoc(sessionId);
  return toCheckoutSession(doc);
}

async function markSessionComplete(sessionId, payload = {}) {
  if (!sessionId) {
    throw new Error("sessionId is required");
  }

  const existingDoc = await findCheckoutSessionDoc(sessionId);
  const ref = existingDoc ? existingDoc.ref : sessionsCol().doc(sessionId);

  await ref.set(
    {
      sessionId,
      status: "complete",
      completedAt: ts(),
      updatedAt: ts(),
      ...payload,
    },
    { merge: true },
  );

  return true;
}

async function resolveEntitlement({ userId, ppvId, sessionId }) {
  if (!userId || !ppvId) {
    return null;
  }

  if (sessionId) {
    const session = await getCheckoutSession(sessionId);
    if (
      session &&
      session.userId === userId &&
      session.ppvId === ppvId &&
      session.status === "complete"
    ) {
      return session;
    }
  }

  const query = await sessionsCol()
    .where("userId", "==", userId)
    .where("ppvId", "==", ppvId)
    .limit(10)
    .get();

  const matches = query.docs
    .map(toCheckoutSession)
    .filter((session) => session?.status === "complete");

  if (!matches || matches.length == 0) {
    return null;
  }

  matches.sort((left, right) => {
    const leftTime = toMillis(left.completedAt) || toMillis(left.createdAt);
    const rightTime = toMillis(right.completedAt) || toMillis(right.createdAt);
    return rightTime - leftTime;
  });

  return matches[0];
}

module.exports = {
  createPendingCheckoutSession,
  getCheckoutSession,
  markSessionComplete,
  normalizeStatus,
  resolveEntitlement,
};
