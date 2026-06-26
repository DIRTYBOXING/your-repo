"use strict";

const { admin, FieldValue, Timestamp } = require("../config");

const POSITIVE_SESSION_STATUSES = new Set([
  "active",
  "complete",
  "completed",
  "granted",
  "paid",
  "succeeded",
]);

const NEGATIVE_SESSION_STATUSES = new Set([
  "canceled",
  "cancelled",
  "expired",
  "failed",
  "inactive",
  "refunded",
  "revoked",
]);

function readDateTime(value) {
  if (!value) return null;
  if (typeof value.toDate === "function") {
    return value.toDate();
  }
  if (value instanceof Date) {
    return value;
  }
  if (typeof value === "string") {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }
  if (typeof value === "number") {
    return new Date(value);
  }
  return null;
}

function normalizeString(value) {
  if (value === undefined || value === null) return "";
  return value.toString().trim();
}

function normalizeStatus(value, fallback = "pending") {
  const normalized = normalizeString(value).toLowerCase();
  if (!normalized) {
    return fallback;
  }
  if (POSITIVE_SESSION_STATUSES.has(normalized)) {
    return "complete";
  }
  if (NEGATIVE_SESSION_STATUSES.has(normalized)) {
    return normalized;
  }
  return normalized;
}

function toNullableInt(value) {
  if (value === undefined || value === null || value === "") return null;
  const parsed = Number.parseInt(value, 10);
  return Number.isNaN(parsed) ? null : parsed;
}

function normalizeCurrency(value) {
  const normalized = normalizeString(value).toLowerCase();
  return normalized || "aud";
}

function buildTierKey({ tierKey, tierName, tierType, tierId }) {
  const normalizedTierKey = normalizeString(tierKey);
  if (normalizedTierKey) {
    return normalizedTierKey;
  }

  const normalizedTierName = normalizeString(tierName);
  if (normalizedTierName) {
    return normalizedTierName;
  }

  const normalizedTierType = normalizeString(tierType).toLowerCase();
  const normalizedTierId = toNullableInt(tierId);
  if (normalizedTierType && normalizedTierId !== null) {
    return `${normalizedTierType}_${normalizedTierId}`;
  }

  return null;
}

function setNormalizedStringField(target, field, value, transform) {
  const normalized = normalizeString(value);
  if (!normalized) {
    return;
  }

  target[field] =
    typeof transform === "function" ? transform(normalized) : normalized;
}

function setNullableField(target, field, value) {
  if (value === null || value === undefined) {
    return;
  }

  target[field] = value;
}

function setTimestampField(target, field, value) {
  if (!value) {
    return;
  }

  target[field] = Timestamp.fromDate(value);
}

function appendSourceFields(payload, { sourceEventId, canonicalPpvId }) {
  if (sourceEventId && sourceEventId !== canonicalPpvId) {
    payload.sourceEventId = sourceEventId;
  }
}

function appendTierFields(
  payload,
  {
    normalizedTierId,
    normalizedTierName,
    normalizedTierKey,
    normalizedTierType,
  },
) {
  setNullableField(payload, "tierId", normalizedTierId);
  setNullableField(payload, "tierName", normalizedTierName);
  setNullableField(payload, "tierKey", normalizedTierKey);
  setNullableField(payload, "tierType", normalizedTierType);
}

function appendPaymentFields(
  payload,
  {
    paymentMethod,
    paymentProvider,
    source,
    requestSource,
    checkoutSource,
    legacyPriceId,
    stripePaymentIntentId,
    stripeSessionId,
    finalSessionId,
    paypalOrderId,
    normalizedCreditsSpent,
    finalPromoterId,
    normalizedCumulativeBuys,
  },
) {
  setNormalizedStringField(payload, "paymentMethod", paymentMethod, (value) =>
    value.toLowerCase(),
  );
  setNormalizedStringField(
    payload,
    "paymentProvider",
    paymentProvider,
    (value) => value.toLowerCase(),
  );
  setNormalizedStringField(payload, "source", source);
  setNormalizedStringField(payload, "requestSource", requestSource);
  setNormalizedStringField(payload, "checkoutSource", checkoutSource);
  setNormalizedStringField(payload, "legacyPriceId", legacyPriceId);
  setNormalizedStringField(
    payload,
    "stripePaymentIntentId",
    stripePaymentIntentId,
  );
  setNormalizedStringField(payload, "paypalOrderId", paypalOrderId);
  setNullableField(payload, "creditsSpent", normalizedCreditsSpent);
  setNullableField(payload, "promoterId", finalPromoterId);
  setNullableField(payload, "cumulativeBuys", normalizedCumulativeBuys);

  const normalizedStripeSessionId = normalizeString(stripeSessionId);
  if (
    normalizedStripeSessionId &&
    normalizedStripeSessionId !== finalSessionId
  ) {
    payload.stripeSessionId = normalizedStripeSessionId;
  }
}

function appendLifecycleFields(
  payload,
  { finalExpiresAt, finalEventEndedAt, normalizedStatus },
) {
  setTimestampField(payload, "expiresAt", finalExpiresAt);
  setTimestampField(payload, "eventEndedAt", finalEventEndedAt);

  if (normalizedStatus === "complete") {
    payload.completedAt = FieldValue.serverTimestamp();
    payload.purchasedAt = FieldValue.serverTimestamp();
  }
}

async function resolvePpvEventDocument(db, eventId) {
  if (!db || !eventId) return null;

  const directDoc = await db.collection("ppv_events").doc(eventId).get();
  if (directDoc.exists) {
    return {
      id: directDoc.id,
      data: directDoc.data() || {},
      ref: directDoc.ref,
    };
  }

  const eventIdSnapshot = await db
    .collection("ppv_events")
    .where("eventId", "==", eventId)
    .limit(1)
    .get();
  if (!eventIdSnapshot.empty) {
    const doc = eventIdSnapshot.docs[0];
    return { id: doc.id, data: doc.data() || {}, ref: doc.ref };
  }

  return null;
}

async function resolveCanonicalPpvPurchaseContext(db, eventId) {
  const resolvedEvent = await resolvePpvEventDocument(db, eventId);
  const canonicalPpvId = resolvedEvent?.id || eventId;
  const eventData = resolvedEvent?.data || {};
  const expiresAt =
    readDateTime(eventData.replayExpiry) ||
    new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
  const eventEndedAt =
    readDateTime(eventData.endTime) || readDateTime(eventData.eventDate);

  return {
    canonicalPpvId,
    sourceEventId: eventId,
    eventData,
    expiresAt,
    eventEndedAt,
    promoterId: eventData.promoterId || null,
  };
}

function buildCanonicalSessionId({
  sessionId,
  stripeSessionId,
  stripePaymentIntentId,
  paypalOrderId,
  paymentMethod,
  paymentProvider,
  userId,
  ppvId,
}) {
  if (sessionId) {
    return sessionId;
  }
  if (stripeSessionId) {
    return stripeSessionId;
  }
  if (stripePaymentIntentId) {
    return `legacy_pi_${stripePaymentIntentId}`;
  }
  if (paypalOrderId) {
    return `paypal_${paypalOrderId}`;
  }

  const normalizedProvider =
    normalizeString(paymentProvider).toLowerCase() ||
    normalizeString(paymentMethod).toLowerCase() ||
    "ppv";
  return `${normalizedProvider}_${userId}_${ppvId}`;
}

async function buildCanonicalPpvCheckoutSessionRecord({
  db,
  sessionId,
  stripeSessionId,
  stripePaymentIntentId,
  paypalOrderId,
  userId,
  ppvId,
  tierId,
  tierName,
  tierKey,
  tierType,
  amountCents,
  originalAmountCents,
  discountCents,
  currency,
  paymentMethod,
  paymentProvider,
  status = "complete",
  paymentStatus,
  source,
  requestSource,
  checkoutSource,
  legacyPriceId,
  creditsSpent,
  accessGranted = true,
  isActive = true,
  replayExpired = false,
  expiresAt,
  eventEndedAt,
  promoterId,
  cumulativeBuys,
}) {
  if (!db || !userId || !ppvId) {
    throw new Error("db, userId, and ppvId are required");
  }

  const context = await resolveCanonicalPpvPurchaseContext(db, ppvId);
  const canonicalPpvId = context.canonicalPpvId;
  const finalSessionId = buildCanonicalSessionId({
    sessionId,
    stripeSessionId,
    stripePaymentIntentId,
    paypalOrderId,
    paymentMethod,
    paymentProvider,
    userId,
    ppvId: canonicalPpvId,
  });

  const normalizedTierId = toNullableInt(tierId);
  const normalizedTierName = normalizeString(tierName) || null;
  const normalizedTierType = normalizeString(tierType).toLowerCase() || null;
  const normalizedTierKey = buildTierKey({
    tierKey,
    tierName: normalizedTierName,
    tierType: normalizedTierType,
    tierId: normalizedTierId,
  });
  const normalizedAmountCents = toNullableInt(amountCents) ?? 0;
  const normalizedOriginalAmountCents =
    toNullableInt(originalAmountCents) ?? normalizedAmountCents;
  const normalizedDiscountCents =
    toNullableInt(discountCents) ??
    Math.max(0, normalizedOriginalAmountCents - normalizedAmountCents);
  const normalizedCreditsSpent = toNullableInt(creditsSpent);
  const normalizedCumulativeBuys = toNullableInt(cumulativeBuys);
  const normalizedStatus = normalizeStatus(status, "complete");
  const normalizedPaymentStatus = normalizeStatus(
    paymentStatus,
    normalizedStatus === "complete" ? "succeeded" : normalizedStatus,
  );
  const finalExpiresAt = expiresAt || context.expiresAt;
  const finalEventEndedAt = eventEndedAt || context.eventEndedAt;
  const finalPromoterId = promoterId || context.promoterId;

  const payload = {
    sessionId: finalSessionId,
    userId,
    ppvId: canonicalPpvId,
    eventId: canonicalPpvId,
    amountCents: normalizedAmountCents,
    originalAmountCents: normalizedOriginalAmountCents,
    discountCents: normalizedDiscountCents,
    currency: normalizeCurrency(currency),
    status: normalizedStatus,
    paymentStatus: normalizedPaymentStatus,
    accessGranted,
    isActive,
    replayExpired,
    updatedAt: FieldValue.serverTimestamp(),
  };

  appendSourceFields(payload, {
    sourceEventId: context.sourceEventId,
    canonicalPpvId,
  });
  appendTierFields(payload, {
    normalizedTierId,
    normalizedTierName,
    normalizedTierKey,
    normalizedTierType,
  });
  appendPaymentFields(payload, {
    paymentMethod,
    paymentProvider,
    source,
    requestSource,
    checkoutSource,
    legacyPriceId,
    stripePaymentIntentId,
    stripeSessionId,
    finalSessionId,
    paypalOrderId,
    normalizedCreditsSpent,
    finalPromoterId,
    normalizedCumulativeBuys,
  });
  appendLifecycleFields(payload, {
    finalExpiresAt,
    finalEventEndedAt,
    normalizedStatus,
  });

  return {
    sessionId: finalSessionId,
    payload,
    canonicalPpvId,
    sourceEventId: context.sourceEventId,
    expiresAt: finalExpiresAt,
    eventEndedAt: finalEventEndedAt,
    promoterId: finalPromoterId,
  };
}

async function upsertCanonicalPpvCheckoutSession(details) {
  const { db } = details;
  const sessionRecord = await buildCanonicalPpvCheckoutSessionRecord(details);
  const sessionRef = db
    .collection("ppv_checkout_sessions")
    .doc(sessionRecord.sessionId);
  const existingDoc = await sessionRef.get();
  const creationFields = existingDoc.exists
    ? {}
    : { createdAt: FieldValue.serverTimestamp() };

  await sessionRef.set(
    {
      ...sessionRecord.payload,
      ...creationFields,
    },
    { merge: true },
  );

  return {
    ...sessionRecord,
    ref: sessionRef,
  };
}

module.exports = {
  buildCanonicalPpvCheckoutSessionRecord,
  normalizeStatus,
  resolveCanonicalPpvPurchaseContext,
  upsertCanonicalPpvCheckoutSession,
};
