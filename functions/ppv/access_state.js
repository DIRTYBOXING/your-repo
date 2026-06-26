const NEGATIVE_STATUSES = new Set([
  "canceled",
  "cancelled",
  "expired",
  "failed",
  "inactive",
  "refunded",
  "revoked",
]);

const POSITIVE_PURCHASE_STATUSES = new Set([
  "active",
  "complete",
  "completed",
  "granted",
  "paid",
  "succeeded",
]);

const POSITIVE_SESSION_STATUSES = new Set([
  "active",
  "complete",
  "completed",
  "granted",
  "paid",
  "succeeded",
]);

const INACTIVE_REASON_PRIORITY = {
  none: 0,
  expired: 1,
  revoked: 2,
  refunded: 3,
};

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

function normalizeStatus(value) {
  if (value === undefined || value === null) return null;
  const normalized = value.toString().trim().toLowerCase();
  return normalized || null;
}

function readLastUpdated(data = {}) {
  return (
    readDateTime(data.updatedAt) ||
    readDateTime(data.completedAt) ||
    readDateTime(data.purchasedAt) ||
    readDateTime(data.grantedAt) ||
    readDateTime(data.replayExpiredAt) ||
    readDateTime(data.expiredAt) ||
    readDateTime(data.createdAt) ||
    null
  );
}

function resolveInactiveReason(data = {}) {
  const status = normalizeStatus(data.status);
  const paymentStatus = normalizeStatus(data.paymentStatus);

  if (
    data.refunded === true ||
    status === "refunded" ||
    paymentStatus === "refunded"
  ) {
    return "refunded";
  }

  if (
    data.revoked === true ||
    status === "revoked" ||
    paymentStatus === "revoked"
  ) {
    return "revoked";
  }

  if (
    data.replayExpired === true ||
    status === "expired" ||
    paymentStatus === "expired"
  ) {
    return "expired";
  }

  if (data.isActive === false || data.accessGranted === false) {
    return "revoked";
  }

  if (
    (status && NEGATIVE_STATUSES.has(status)) ||
    (paymentStatus && NEGATIVE_STATUSES.has(paymentStatus))
  ) {
    if (status === "refunded" || paymentStatus === "refunded") {
      return "refunded";
    }
    if (status === "expired" || paymentStatus === "expired") {
      return "expired";
    }
    return "revoked";
  }

  const expiresAt = readDateTime(data.expiresAt);
  if (expiresAt && expiresAt < new Date()) {
    return "expired";
  }

  return null;
}

function isAccessRecordActive(data = {}) {
  return resolveInactiveReason(data) === null;
}

function isPurchaseRecordActive(data = {}) {
  if (resolveInactiveReason(data) !== null) {
    return false;
  }

  const status = normalizeStatus(data.status);
  const paymentStatus = normalizeStatus(data.paymentStatus);

  return (
    data.accessGranted === true ||
    (status && POSITIVE_PURCHASE_STATUSES.has(status)) ||
    (paymentStatus && POSITIVE_PURCHASE_STATUSES.has(paymentStatus))
  );
}

function isAuthoritativePurchaseRecord(data = {}) {
  const status = normalizeStatus(data.status);
  const paymentStatus = normalizeStatus(data.paymentStatus);

  return (
    data.accessGranted === true ||
    data.accessGranted === false ||
    data.isActive === false ||
    data.replayExpired === true ||
    data.refunded === true ||
    data.revoked === true ||
    !!readDateTime(data.expiresAt) ||
    !!(
      status &&
      (POSITIVE_PURCHASE_STATUSES.has(status) || NEGATIVE_STATUSES.has(status))
    ) ||
    !!(
      paymentStatus &&
      (POSITIVE_PURCHASE_STATUSES.has(paymentStatus) ||
        NEGATIVE_STATUSES.has(paymentStatus))
    )
  );
}

function isSessionRecordActive(data = {}) {
  if (resolveInactiveReason(data) !== null) {
    return false;
  }

  const status = normalizeStatus(data.status);
  const paymentStatus = normalizeStatus(data.paymentStatus);

  return (
    data.accessGranted === true ||
    (status && POSITIVE_SESSION_STATUSES.has(status)) ||
    (paymentStatus && POSITIVE_SESSION_STATUSES.has(paymentStatus))
  );
}

function isAuthoritativeSessionRecord(data = {}) {
  const status = normalizeStatus(data.status);
  const paymentStatus = normalizeStatus(data.paymentStatus);

  return (
    data.accessGranted === true ||
    data.accessGranted === false ||
    data.isActive === false ||
    data.replayExpired === true ||
    data.refunded === true ||
    data.revoked === true ||
    !!readDateTime(data.expiresAt) ||
    !!(
      status &&
      (POSITIVE_SESSION_STATUSES.has(status) || NEGATIVE_STATUSES.has(status))
    ) ||
    !!(
      paymentStatus &&
      (POSITIVE_SESSION_STATUSES.has(paymentStatus) ||
        NEGATIVE_STATUSES.has(paymentStatus))
    )
  );
}

function readTierId(data = {}) {
  if (data.tierId === undefined || data.tierId === null || data.tierId === "") {
    return null;
  }

  const parsed = Number.parseInt(data.tierId, 10);
  return Number.isNaN(parsed) ? null : parsed;
}

function readTierName(data = {}) {
  return data.tierName || data.bundleName || data.tier || null;
}

function readTierKey(data = {}) {
  return data.tierKey || data.tierName || data.bundleName || data.tier || null;
}

function buildState({
  hasAccess = false,
  hasAny = false,
  reason = "none",
  purchaseId = null,
  lastUpdated = null,
  expiresAt = null,
  tierId = null,
  tierName = null,
  tierKey = null,
} = {}) {
  return {
    hasAccess,
    hasAny,
    reason: hasAccess ? "active" : reason || "none",
    purchaseId,
    lastUpdated,
    expiresAt,
    tierId,
    tierName,
    tierKey,
  };
}

function candidateFromData(
  data,
  { purchaseId, isPurchase = false, isSession = false },
) {
  const inactiveReason = resolveInactiveReason(data);
  let hasAccess = inactiveReason === null;
  if (isSession) {
    hasAccess = isSessionRecordActive(data);
  } else if (isPurchase) {
    hasAccess = isPurchaseRecordActive(data);
  }

  return {
    hasAccess,
    reason: hasAccess ? "active" : inactiveReason || "none",
    purchaseId,
    lastUpdated: readLastUpdated(data),
    expiresAt: readDateTime(data.expiresAt),
    tierId: readTierId(data),
    tierName: readTierName(data),
    tierKey: readTierKey(data),
    authoritative: isSession
      ? isAuthoritativeSessionRecord(data)
      : !isPurchase || isAuthoritativePurchaseRecord(data),
  };
}

function preferActiveState(current, candidate) {
  if (!current) {
    return buildState({ hasAny: true, ...candidate });
  }

  const currentTier = Number.isInteger(current.tierId) ? current.tierId : -1;
  const candidateTier = Number.isInteger(candidate.tierId)
    ? candidate.tierId
    : -1;
  if (candidateTier > currentTier) {
    return buildState({ hasAny: true, ...candidate });
  }
  if (candidateTier < currentTier) {
    return current;
  }

  const currentTime =
    current.lastUpdated instanceof Date ? current.lastUpdated.getTime() : 0;
  const candidateTime =
    candidate.lastUpdated instanceof Date ? candidate.lastUpdated.getTime() : 0;
  return candidateTime >= currentTime
    ? buildState({ hasAny: true, ...candidate })
    : current;
}

function preferInactiveState(current, candidate) {
  if (!current) return candidate;
  const currentPriority = INACTIVE_REASON_PRIORITY[current.reason] || 0;
  const candidatePriority = INACTIVE_REASON_PRIORITY[candidate.reason] || 0;
  if (candidatePriority > currentPriority) {
    return candidate;
  }
  if (candidatePriority < currentPriority) {
    return current;
  }

  const currentTime =
    current.lastUpdated instanceof Date ? current.lastUpdated.getTime() : 0;
  const candidateTime =
    candidate.lastUpdated instanceof Date ? candidate.lastUpdated.getTime() : 0;
  return candidateTime >= currentTime ? candidate : current;
}

function consumeCandidate(currentState, candidate) {
  if (!candidate.authoritative) {
    return currentState;
  }

  const nextState = {
    hasAny: true,
    bestInactive: preferInactiveState(currentState.bestInactive, candidate),
    active: currentState.active,
  };

  if (candidate.hasAccess) {
    nextState.active = preferActiveState(currentState.active, candidate);
  }

  return nextState;
}

async function getSessionCandidatesForLookup(db, userId, lookupId) {
  const sessionQuery = await db
    .collection("ppv_checkout_sessions")
    .where("userId", "==", userId)
    .where("ppvId", "==", lookupId)
    .limit(10)
    .get();

  const candidates = [];
  for (const doc of sessionQuery.docs) {
    const candidate = candidateFromData(doc.data() || {}, {
      purchaseId: doc.id,
      isSession: true,
    });
    if (candidate.authoritative) {
      candidates.push(candidate);
    }
  }

  return candidates;
}

async function getAccessCandidatesForLookup(db, userId, lookupId) {
  const [accessDoc, nestedAccessDoc, accessQuery] = await Promise.all([
    db.collection("ppv_access").doc(`${userId}_${lookupId}`).get(),
    db
      .collection("users")
      .doc(userId)
      .collection("ppv_access")
      .doc(lookupId)
      .get(),
    db
      .collection("ppv_access")
      .where("userId", "==", userId)
      .where("eventId", "==", lookupId)
      .limit(10)
      .get(),
  ]);

  const candidates = [];

  if (accessDoc.exists) {
    candidates.push(
      candidateFromData(accessDoc.data() || {}, {
        purchaseId: accessDoc.id,
        isPurchase: false,
      }),
    );
  }

  if (nestedAccessDoc.exists) {
    candidates.push(
      candidateFromData(nestedAccessDoc.data() || {}, {
        purchaseId: nestedAccessDoc.id,
        isPurchase: false,
      }),
    );
  }

  for (const doc of accessQuery.docs) {
    candidates.push(
      candidateFromData(doc.data() || {}, {
        purchaseId: doc.id,
        isPurchase: false,
      }),
    );
  }

  return candidates;
}

async function getPurchaseCandidatesForLookup(db, userId, lookupId) {
  const [purchaseDoc, ...purchaseQueries] = await Promise.all([
    db.collection("ppv_purchases").doc(`${userId}_${lookupId}`).get(),
    db
      .collection("ppv_purchases")
      .where("userId", "==", userId)
      .where("ppvId", "==", lookupId)
      .limit(10)
      .get(),
    db
      .collection("ppv_purchases")
      .where("userId", "==", userId)
      .where("ppvEventId", "==", lookupId)
      .limit(10)
      .get(),
    db
      .collection("ppv_purchases")
      .where("userId", "==", userId)
      .where("eventId", "==", lookupId)
      .limit(10)
      .get(),
  ]);

  const candidates = [];

  if (purchaseDoc.exists) {
    const candidate = candidateFromData(purchaseDoc.data() || {}, {
      purchaseId: purchaseDoc.id,
      isPurchase: true,
    });
    if (candidate.authoritative) {
      candidates.push(candidate);
    }
  }

  for (const query of purchaseQueries) {
    for (const doc of query.docs) {
      const candidate = candidateFromData(doc.data() || {}, {
        purchaseId: doc.id,
        isPurchase: true,
      });
      if (candidate.authoritative) {
        candidates.push(candidate);
      }
    }
  }

  return candidates;
}

async function resolvePpvEventDocument(db, eventId) {
  if (!eventId) return null;

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

async function resolvePpvLookupIds(db, eventId) {
  const ids = new Set();
  const resolvedEvent = await resolvePpvEventDocument(db, eventId);

  if (resolvedEvent?.id) {
    ids.add(resolvedEvent.id);
  }
  if (resolvedEvent?.data?.eventId) {
    ids.add(resolvedEvent.data.eventId.toString());
  }
  if (eventId) {
    ids.add(eventId);
  }

  return Array.from(ids).filter(Boolean);
}

async function scanAccessState(db, userId, eventId) {
  const lookupIds = await resolvePpvLookupIds(db, eventId);
  let currentState = {
    hasAny: false,
    bestInactive: buildState({ hasAny: false }),
    active: null,
  };

  for (const lookupId of lookupIds) {
    const candidates = await getAccessCandidatesForLookup(db, userId, lookupId);
    for (const candidate of candidates) {
      currentState = consumeCandidate(currentState, candidate);
    }
  }

  if (currentState.active) {
    return currentState.active;
  }

  return buildState({
    hasAny: currentState.hasAny,
    ...currentState.bestInactive,
  });
}

async function scanSessionState(db, userId, eventId) {
  const lookupIds = await resolvePpvLookupIds(db, eventId);
  let currentState = {
    hasAny: false,
    bestInactive: buildState({ hasAny: false }),
    active: null,
  };

  for (const lookupId of lookupIds) {
    const candidates = await getSessionCandidatesForLookup(
      db,
      userId,
      lookupId,
    );
    for (const candidate of candidates) {
      currentState = consumeCandidate(currentState, candidate);
    }
  }

  if (currentState.active) {
    return currentState.active;
  }

  return buildState({
    hasAny: currentState.hasAny,
    ...currentState.bestInactive,
  });
}

async function scanPurchaseState(db, userId, eventId) {
  const lookupIds = await resolvePpvLookupIds(db, eventId);
  let currentState = {
    hasAny: false,
    bestInactive: buildState({ hasAny: false }),
    active: null,
  };

  for (const lookupId of lookupIds) {
    const candidates = await getPurchaseCandidatesForLookup(
      db,
      userId,
      lookupId,
    );
    for (const candidate of candidates) {
      currentState = consumeCandidate(currentState, candidate);
    }
  }

  if (currentState.active) {
    return currentState.active;
  }

  return buildState({
    hasAny: currentState.hasAny,
    ...currentState.bestInactive,
  });
}

async function getCanonicalPpvAccessState({ db, userId, eventId }) {
  if (!db || !userId || !eventId) {
    return buildState();
  }

  const sessionState = await scanSessionState(db, userId, eventId);
  if (sessionState.hasAny) {
    return sessionState;
  }

  const purchaseState = await scanPurchaseState(db, userId, eventId);
  if (purchaseState.hasAny) {
    return purchaseState;
  }

  const accessState = await scanAccessState(db, userId, eventId);
  if (accessState.hasAny) {
    return accessState;
  }

  return buildState();
}

module.exports = {
  getCanonicalPpvAccessState,
  isAccessRecordActive,
  isAuthoritativePurchaseRecord,
  isPurchaseRecordActive,
  isSessionRecordActive,
  readDateTime,
  resolveInactiveReason,
  resolvePpvEventDocument,
  resolvePpvLookupIds,
};
