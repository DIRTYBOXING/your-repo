// ═══════════════════════════════════════════════════════════════════════════
// DFC RECONCILIATION SERVICE — Event payout computation & CSV generation
// ═══════════════════════════════════════════════════════════════════════════
//
// computePpvSplit(buys)        → { dfcPct, dfcCut, promoterCut, reserve, payable }
// reconcileEvent(eventId)      → reads ledger, computes incremental splits, returns summary
// generateReconciliationCsv()  → returns CSV string for audit export
//
// Formula: DFC_pct = 30% + (min(buys, 10000) / 10000) × 20%
// Reserve: 2% of Net held for 14 days
// ═══════════════════════════════════════════════════════════════════════════

const { onCall } = require("firebase-functions/v2/https");
const { admin, db, REGION, Timestamp } = require("../config");
const crypto = require("node:crypto");

// ── Constants (must match ppv.js) ──────────────────────────────────────
const DFC_FEE_FLOOR = 0.3;
const DFC_FEE_CEILING = 0.5;
const DFC_MAX_EXPOSURE = 10000;
const RESERVE_PCT = 0.02;
const STRIPE_RATE = 0.029;
const STRIPE_FIXED = 30; // cents
const MAIN_PAYOUT_DELAY_DAYS = 14;
const RESERVE_RELEASE_DELAY_DAYS = 28;
const MAX_PROMOTER_EVENTS = 100;
const MAX_RECONCILIATIONS_PER_EVENT = 100;

const PAYOUT_STATES = Object.freeze({
  NOT_REQUESTED: "not_requested",
  REQUESTED: "requested",
  BLOCKED: "blocked",
  PROCESSING: "processing",
  COMPLETED: "completed",
  FAILED: "failed",
});

const RESERVE_RELEASE_STATES = Object.freeze({
  PENDING: "pending",
  RELEASED: "released",
  BLOCKED: "blocked",
});

function normalizeOptionalString(value) {
  if (typeof value !== "string") return null;
  const normalized = value.trim();
  return normalized || null;
}

function normalizeStatus(value) {
  return normalizeOptionalString(value)?.toLowerCase() || "";
}

function parseInteger(value) {
  const parsed = Number(value || 0);
  if (!Number.isFinite(parsed)) return 0;
  return Math.round(parsed);
}

function toDateValue(value) {
  if (!value) return null;
  if (typeof value?.toDate === "function") return value.toDate();
  if (value instanceof Date) return value;
  if (typeof value === "string") {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) {
      return parsed;
    }
  }
  return null;
}

function toTimestamp(value) {
  if (!value) return null;
  if (typeof value?.toDate === "function") return value;
  const resolved = toDateValue(value);
  return resolved ? Timestamp.fromDate(resolved) : null;
}

function addDays(date, days) {
  return new Date(date.getTime() + days * 24 * 60 * 60 * 1000);
}

function getEventData(snapshot) {
  if (!snapshot) return {};
  return typeof snapshot.data === "function"
    ? snapshot.data()
    : snapshot.data || {};
}

function getCanonicalEventId(snapshot, fallbackEventId) {
  const eventData = getEventData(snapshot);
  return (
    normalizeOptionalString(eventData.eventId) ||
    snapshot?.id ||
    fallbackEventId
  );
}

function buildEventLookupIds({ eventId, snapshot }) {
  const ids = new Set();
  if (normalizeOptionalString(eventId))
    ids.add(normalizeOptionalString(eventId));
  if (snapshot?.id) ids.add(snapshot.id);

  const eventData = getEventData(snapshot);
  const eventFieldId = normalizeOptionalString(eventData.eventId);
  if (eventFieldId) ids.add(eventFieldId);

  return [...ids.values()];
}

function getEventStartTime(eventData) {
  return (
    toDateValue(eventData.eventDate) ||
    toDateValue(eventData.date) ||
    toDateValue(eventData.startTime) ||
    new Date()
  );
}

function getPurchaseTimestamp(tx) {
  return (
    tx.createdAt?.toDate?.() ||
    tx.purchasedAt?.toDate?.() ||
    tx.grantedAt?.toDate?.() ||
    new Date()
  );
}

function getRefundAmountCents(tx, priceCents) {
  const explicitRefund = Number(tx.refundAmountCents || 0);
  if (explicitRefund > 0) {
    return explicitRefund;
  }

  const status = normalizeStatus(tx.status);
  const paymentStatus = normalizeStatus(tx.paymentStatus);
  if (
    tx.refunded === true ||
    status === "refunded" ||
    paymentStatus === "refunded"
  ) {
    return priceCents;
  }

  return 0;
}

function isFullyRefunded(tx, priceCents) {
  if (tx.refunded === true) {
    return true;
  }

  const refundCents = getRefundAmountCents(tx, priceCents);
  return refundCents > 0 && refundCents >= priceCents;
}

function normalizePayoutState(value) {
  switch (normalizeStatus(value)) {
    case "requested":
      return PAYOUT_STATES.REQUESTED;
    case "processing":
      return PAYOUT_STATES.PROCESSING;
    case "completed":
    case "paid":
    case "transferred":
      return PAYOUT_STATES.COMPLETED;
    case "failed":
    case "error":
    case "rejected":
    case "transfer_failed":
      return PAYOUT_STATES.FAILED;
    case "blocked":
      return PAYOUT_STATES.BLOCKED;
    case "pending":
    case "scheduled":
    case "not_reconciled":
      return PAYOUT_STATES.NOT_REQUESTED;
    default:
      return "";
  }
}

function normalizeReserveReleaseState(value) {
  switch (normalizeStatus(value)) {
    case "released":
    case "completed":
      return RESERVE_RELEASE_STATES.RELEASED;
    case "blocked":
    case "failed":
      return RESERVE_RELEASE_STATES.BLOCKED;
    case "pending":
    default:
      return RESERVE_RELEASE_STATES.PENDING;
  }
}

async function requireAuth(request) {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new Error("Authentication required");
  }
  return uid;
}

async function loadUserData(uid) {
  const userDoc = await db.collection("users").doc(uid).get();
  return userDoc.exists ? userDoc.data() : {};
}

async function isAdminUid(uid, userData = null) {
  const resolvedUserData = userData || (await loadUserData(uid));
  return resolvedUserData.role === "admin" || resolvedUserData.isAdmin === true;
}

async function assertAdminOrPromoter(request, promoterId) {
  const uid = await requireAuth(request);
  const userData = await loadUserData(uid);
  const isAdmin = await isAdminUid(uid, userData);

  if (isAdmin || uid === promoterId || userData.promoterId === promoterId) {
    return { uid, userData, isAdmin };
  }

  throw new Error("Unauthorized");
}

async function getEventSnapshot(eventId) {
  const [eventSnap, ppvEventSnap] = await Promise.all([
    db.collection("events").doc(eventId).get(),
    db.collection("ppv_events").doc(eventId).get(),
  ]);

  if (eventSnap.exists) return eventSnap;
  if (ppvEventSnap.exists) return ppvEventSnap;

  const [eventQuery, ppvEventQuery] = await Promise.all([
    db.collection("events").where("eventId", "==", eventId).limit(1).get(),
    db.collection("ppv_events").where("eventId", "==", eventId).limit(1).get(),
  ]);

  if (!eventQuery.empty) return eventQuery.docs[0];
  if (!ppvEventQuery.empty) return ppvEventQuery.docs[0];

  return ppvEventSnap;
}

async function getPurchasesForEvent(eventLookupIds) {
  const lookupIds = Array.isArray(eventLookupIds)
    ? eventLookupIds
    : [eventLookupIds];
  const normalizedIds = lookupIds
    .map((value) => normalizeOptionalString(value))
    .filter(Boolean);

  const queries = [];
  for (const lookupId of normalizedIds) {
    queries.push(
      db.collection("ppv_purchases").where("ppvId", "==", lookupId).get(),
      db.collection("ppv_purchases").where("eventId", "==", lookupId).get(),
      db.collection("ppv_purchases").where("ppvEventId", "==", lookupId).get(),
    );
  }

  const snapshots = await Promise.all(queries);
  const mergedDocs = new Map();
  for (const snapshot of snapshots) {
    for (const doc of snapshot.docs) {
      mergedDocs.set(doc.id, doc);
    }
  }

  return [...mergedDocs.values()].sort((left, right) => {
    const leftTs = getPurchaseTimestamp(left.data()).getTime();
    const rightTs = getPurchaseTimestamp(right.data()).getTime();
    return leftTs - rightTs;
  });
}

function getReconciliationSortTime(data = {}) {
  return (
    toDateValue(data.reconciledAt) ||
    toDateValue(data.updatedAt) ||
    toDateValue(data.createdAt) ||
    toDateValue(data.eventStartTime) ||
    new Date(0)
  );
}

async function getLatestEventReconciliation(eventLookupIds) {
  const lookupIds = Array.isArray(eventLookupIds)
    ? eventLookupIds
    : [eventLookupIds];
  const normalizedIds = lookupIds
    .map((value) => normalizeOptionalString(value))
    .filter(Boolean);

  const queries = normalizedIds.map((lookupId) =>
    db
      .collection("reconciliations")
      .where("eventId", "==", lookupId)
      .limit(MAX_RECONCILIATIONS_PER_EVENT)
      .get(),
  );

  const snapshots = await Promise.all(queries);
  const mergedDocs = new Map();
  for (const snapshot of snapshots) {
    for (const doc of snapshot.docs) {
      mergedDocs.set(doc.id, doc);
    }
  }

  const reconciliations = [...mergedDocs.values()].sort(
    (left, right) =>
      getReconciliationSortTime(right.data()) -
      getReconciliationSortTime(left.data()),
  );

  return reconciliations[0] || null;
}

async function listReconciliationsForPromoter(
  promoterId,
  limit = MAX_PROMOTER_EVENTS,
) {
  const snapshot = await db
    .collection("reconciliations")
    .where("promoterId", "==", promoterId)
    .limit(limit)
    .get();

  return [...snapshot.docs].sort(
    (left, right) =>
      getReconciliationSortTime(right.data()) -
      getReconciliationSortTime(left.data()),
  );
}

// ── Pure split calculator ──────────────────────────────────────────────
function computePpvSplit(cumulativeBuys, netCents) {
  const capped = Math.min(Math.max(cumulativeBuys, 0), DFC_MAX_EXPOSURE);
  const dfcPct =
    DFC_FEE_FLOOR +
    (capped / DFC_MAX_EXPOSURE) * (DFC_FEE_CEILING - DFC_FEE_FLOOR);
  const dfcCutCents = Math.round(netCents * dfcPct);
  const promoterCutCents = netCents - dfcCutCents;
  const reserveCents = Math.round(netCents * RESERVE_PCT);
  const payableCents = Math.max(0, promoterCutCents - reserveCents);

  return {
    dfcPct: Math.round(dfcPct * 10000) / 10000,
    dfcCutCents,
    promoterCutCents,
    reserveCents,
    payableCents,
  };
}

function buildPayoutAuthority(
  previousData,
  totalPayableCents,
  reserveReleaseAt,
) {
  const previousState = normalizePayoutState(
    previousData.payoutState ||
      previousData.payoutStatus ||
      previousData.status,
  );
  const payoutState =
    previousState ||
    (totalPayableCents > 0
      ? PAYOUT_STATES.NOT_REQUESTED
      : PAYOUT_STATES.BLOCKED);
  const payoutFailureReason =
    normalizeOptionalString(
      previousData.payoutFailureReason || previousData.failureReason,
    ) ||
    (!previousState && totalPayableCents <= 0 ? "no_payable_balance" : null);

  return {
    payoutState,
    payoutAttemptCount: parseInteger(
      previousData.payoutAttemptCount || previousData.attemptCount,
    ),
    payoutLastAttemptAt: toTimestamp(previousData.payoutLastAttemptAt),
    payoutFailureReason,
    reserveReleaseState: normalizeReserveReleaseState(
      previousData.reserveReleaseState,
    ),
    reserveReleaseAt:
      toDateValue(
        previousData.reserveReleaseAt || previousData.reserveReleaseDate,
      ) || reserveReleaseAt,
    payoutRequestedAt: toTimestamp(previousData.payoutRequestedAt),
    payoutCompletedAt: toTimestamp(previousData.payoutCompletedAt),
    payoutFailedAt: toTimestamp(previousData.payoutFailedAt),
  };
}

async function buildReconciliationSnapshot({
  eventId,
  eventDoc,
  reconciledBy = null,
}) {
  const resolvedEventDoc = eventDoc || (await getEventSnapshot(eventId));
  if (!resolvedEventDoc.exists) {
    throw new Error("Event not found");
  }

  const eventData = getEventData(resolvedEventDoc);
  const canonicalEventId = getCanonicalEventId(resolvedEventDoc, eventId);
  const eventLookupIds = buildEventLookupIds({
    eventId: canonicalEventId,
    snapshot: resolvedEventDoc,
  });
  const [purchaseDocs, latestReconciliation] = await Promise.all([
    getPurchasesForEvent(eventLookupIds),
    getLatestEventReconciliation(eventLookupIds),
  ]);

  let cumulativeBuys = 0;
  let totalGrossCents = 0;
  let totalNetCents = 0;
  let totalRefundedCents = 0;
  let totalStripeFeeCents = 0;
  let totalDfcCents = 0;
  let totalPromoterCents = 0;
  const csvRows = [];

  const header =
    "tx_id,ts,buyer_country,product_type,price_cents,stripe_fee_cents,net_cents,cumulative_buys,dfc_pct,dfc_cut_cents,promoter_cut_cents,reserve_cents,payable_promoter_cents";
  csvRows.push(header);

  for (const doc of purchaseDocs) {
    const tx = doc.data();
    const priceCents = parseInteger(tx.priceCents || tx.amountCents);
    const stripeFeeCents = Math.round(priceCents * STRIPE_RATE) + STRIPE_FIXED;
    const refundCents = getRefundAmountCents(tx, priceCents);
    const isRefund = isFullyRefunded(tx, priceCents);
    const netCents = Math.max(0, priceCents - stripeFeeCents - refundCents);

    totalGrossCents += priceCents;
    totalNetCents += netCents;
    totalRefundedCents += refundCents;
    totalStripeFeeCents += stripeFeeCents;

    if (!isRefund && netCents > 0) {
      cumulativeBuys += 1;
    }

    const split = computePpvSplit(cumulativeBuys, netCents);
    totalDfcCents += split.dfcCutCents;
    totalPromoterCents += split.promoterCutCents;

    const ts = getPurchaseTimestamp(tx);
    csvRows.push(
      [
        doc.id,
        ts.toISOString(),
        tx.buyerCountry || "unknown",
        tx.productType || "PPV",
        priceCents,
        stripeFeeCents,
        netCents,
        cumulativeBuys,
        (split.dfcPct * 100).toFixed(2) + "%",
        split.dfcCutCents,
        split.promoterCutCents,
        split.reserveCents,
        split.payableCents,
      ].join(","),
    );
  }

  const totalReserveCents = Math.round(totalPromoterCents * RESERVE_PCT);
  const totalPayableCents = Math.max(0, totalPromoterCents - totalReserveCents);
  const eventStartTime = getEventStartTime(eventData);
  const payoutEligibleAt = addDays(eventStartTime, MAIN_PAYOUT_DELAY_DAYS);
  const reserveReleaseAt = addDays(eventStartTime, RESERVE_RELEASE_DELAY_DAYS);
  const previousData = latestReconciliation?.data?.() || {};
  const authority = buildPayoutAuthority(
    previousData,
    totalPayableCents,
    reserveReleaseAt,
  );
  const reconciledAt = Timestamp.fromDate(new Date());
  const csvString = csvRows.join("\n");
  const checksum = crypto.createHash("sha256").update(csvString).digest("hex");

  const record = {
    payoutId: `event_settlement__${canonicalEventId}`,
    eventId: canonicalEventId,
    eventName: eventData.name || eventData.title || canonicalEventId,
    promoterId: eventData.promoterId || "",
    payoutType: "main",
    amountCents: totalPayableCents,
    totalGrossCents,
    totalNetCents,
    totalRefundedCents,
    totalPayableCents,
    totalBuys: cumulativeBuys,
    totalDfcCents,
    totalPromoterCents,
    totalReserveCents,
    totalStripeFeesCents,
    checksum,
    csvRowCount: csvRows.length - 1,
    reconciledBy: reconciledBy || previousData.reconciledBy || null,
    reconciledAt,
    eventStartTime: toTimestamp(eventStartTime),
    payoutEligibleAt: toTimestamp(payoutEligibleAt),
    payoutState: authority.payoutState,
    payoutStatus: authority.payoutState,
    payoutAttemptCount: authority.payoutAttemptCount,
    payoutLastAttemptAt: authority.payoutLastAttemptAt,
    payoutFailureReason: authority.payoutFailureReason,
    reserveReleaseState: authority.reserveReleaseState,
    reserveReleaseAt: toTimestamp(authority.reserveReleaseAt),
    reserveReleaseDate: toTimestamp(authority.reserveReleaseAt),
    payoutRequestedAt: authority.payoutRequestedAt,
    payoutCompletedAt: authority.payoutCompletedAt,
    payoutFailedAt: authority.payoutFailedAt,
    updatedAt: reconciledAt,
    createdAt: previousData.createdAt || reconciledAt,
    source: "functions/stripe/reconciliation",
  };

  return {
    eventData,
    canonicalEventId,
    eventLookupIds,
    latestReconciliation,
    record,
    checksum,
  };
}

async function persistReconciliationSnapshot(options) {
  const snapshot = await buildReconciliationSnapshot(options);
  const reconRef = db.collection("reconciliations").doc();
  await reconRef.set(snapshot.record);

  return {
    ...snapshot,
    reconciliationId: reconRef.id,
    reconciliationRef: reconRef,
  };
}

function buildCanonicalPayoutDocument({
  payoutId,
  promoterId,
  eventName,
  reconciliationData,
  existingData,
  status,
  failureReason,
  connectedAccountId,
  stripeAccountReady,
}) {
  const now = Timestamp.fromDate(new Date());
  const requestedAt = existingData.payoutRequestedAt || now;

  return {
    payoutId,
    eventId: reconciliationData.eventId,
    eventName:
      eventName || reconciliationData.eventName || reconciliationData.eventId,
    promoterId,
    creatorId: promoterId,
    payoutType: "main",
    amountCents: parseInteger(reconciliationData.totalPayableCents),
    totalGrossCents: parseInteger(reconciliationData.totalGrossCents),
    totalNetCents: parseInteger(reconciliationData.totalNetCents),
    totalRefundedCents: parseInteger(reconciliationData.totalRefundedCents),
    totalPayableCents: parseInteger(reconciliationData.totalPayableCents),
    status,
    payoutState: status,
    attemptCount: parseInteger(
      existingData.attemptCount ||
        existingData.payoutAttemptCount ||
        reconciliationData.payoutAttemptCount,
    ),
    payoutAttemptCount: parseInteger(
      existingData.payoutAttemptCount ||
        existingData.attemptCount ||
        reconciliationData.payoutAttemptCount,
    ),
    failureReason: failureReason,
    payoutFailureReason: failureReason,
    reserveReleaseState: stripeAccountReady
      ? normalizeReserveReleaseState(reconciliationData.reserveReleaseState)
      : RESERVE_RELEASE_STATES.BLOCKED,
    reserveReleaseAt: toTimestamp(
      reconciliationData.reserveReleaseAt ||
        reconciliationData.reserveReleaseDate,
    ),
    payoutRequestedAt: requestedAt,
    payoutCompletedAt: toTimestamp(existingData.payoutCompletedAt),
    payoutFailedAt: toTimestamp(existingData.payoutFailedAt),
    reconciledAt: toTimestamp(reconciliationData.reconciledAt) || now,
    eventStartTime: toTimestamp(reconciliationData.eventStartTime),
    connectedAccountId: connectedAccountId || null,
    stripeAccountReady,
    payoutMethod: "bank_transfer",
    method: "bank_transfer",
    description: `Event Settlement · ${eventName || reconciliationData.eventName || reconciliationData.eventId}`,
    reconciliationId:
      reconciliationData.reconciliationId ||
      existingData.reconciliationId ||
      null,
    source: "functions/stripe/reconciliation",
    createdAt: existingData.createdAt || now,
    updatedAt: now,
  };
}

function buildPromoterEventMaps(promoterEventDocs) {
  const eventAliasToPrimaryId = {};
  const eventNames = {};

  for (const eventDoc of promoterEventDocs) {
    const eventData = eventDoc.data();
    const primaryEventId = eventDoc.id;
    const aliasEventId = normalizeOptionalString(eventData.eventId);
    const eventName = eventData.title || eventData.name || primaryEventId;

    eventAliasToPrimaryId[primaryEventId] = primaryEventId;
    eventNames[primaryEventId] = eventName;
    if (aliasEventId) {
      eventAliasToPrimaryId[aliasEventId] = primaryEventId;
      eventNames[aliasEventId] = eventName;
    }
  }

  return { eventAliasToPrimaryId, eventNames };
}

function buildLatestReconciliationMap(
  promoterReconciliations,
  eventAliasToPrimaryId,
) {
  const latestReconciliationByEventId = new Map();

  for (const doc of promoterReconciliations) {
    const eventIdFromRecon =
      normalizeOptionalString(doc.data().eventId) || doc.id;
    const primaryEventId =
      eventAliasToPrimaryId[eventIdFromRecon] || eventIdFromRecon;
    if (!latestReconciliationByEventId.has(primaryEventId)) {
      latestReconciliationByEventId.set(primaryEventId, doc);
    }
  }

  return latestReconciliationByEventId;
}

async function ensureEventReconciliation({
  eventDoc,
  accessUid,
  latestReconciliationByEventId,
  eventAliasToPrimaryId,
}) {
  const canonicalEventId = getCanonicalEventId(eventDoc, eventDoc.id);
  const primaryEventId =
    eventAliasToPrimaryId[canonicalEventId] || canonicalEventId;
  let reconciliationDoc =
    latestReconciliationByEventId.get(primaryEventId) || null;

  if (!reconciliationDoc) {
    const persisted = await persistReconciliationSnapshot({
      eventId: canonicalEventId,
      eventDoc,
      reconciledBy: accessUid,
    });
    reconciliationDoc = {
      id: persisted.reconciliationId,
      ref: persisted.reconciliationRef,
      data: () => ({
        ...persisted.record,
        reconciliationId: persisted.reconciliationId,
      }),
    };
    latestReconciliationByEventId.set(primaryEventId, reconciliationDoc);
  }

  return {
    canonicalEventId,
    primaryEventId,
    reconciliationDoc,
  };
}

async function syncPromoterEventPayoutRequest({
  eventDoc,
  promoterId,
  accessUid,
  eventNames,
  eventAliasToPrimaryId,
  latestReconciliationByEventId,
  stripeAccountReady,
  connectedAccountId,
}) {
  const { canonicalEventId, primaryEventId, reconciliationDoc } =
    await ensureEventReconciliation({
      eventDoc,
      accessUid,
      latestReconciliationByEventId,
      eventAliasToPrimaryId,
    });

  const reconciliationData = reconciliationDoc.data();
  const payoutId = `event_settlement__${canonicalEventId}`;
  const payoutRequestRef = db.collection("payout_requests").doc(payoutId);
  const payoutRequestSnap = await payoutRequestRef.get();
  const payoutRequestData = payoutRequestSnap.exists
    ? payoutRequestSnap.data()
    : {};
  const effectivePayoutState = normalizePayoutState(
    payoutRequestData.payoutState ||
      payoutRequestData.status ||
      reconciliationData.payoutState ||
      reconciliationData.payoutStatus,
  );
  const eventName =
    eventNames[primaryEventId] ||
    reconciliationData.eventName ||
    canonicalEventId;
  const totalPayableCents = parseInteger(reconciliationData.totalPayableCents);

  if (
    [
      PAYOUT_STATES.COMPLETED,
      PAYOUT_STATES.PROCESSING,
      PAYOUT_STATES.REQUESTED,
    ].includes(effectivePayoutState)
  ) {
    return {
      disposition: "skipped",
      payout: {
        payoutId,
        eventId: canonicalEventId,
        eventName,
        status: effectivePayoutState,
        totalPayableCents,
        skipped: true,
      },
    };
  }

  if (totalPayableCents <= 0) {
    const blockedAt = Timestamp.fromDate(new Date());
    await reconciliationDoc.ref.set(
      {
        payoutState: PAYOUT_STATES.BLOCKED,
        payoutStatus: PAYOUT_STATES.BLOCKED,
        payoutFailureReason: "no_payable_balance",
        updatedAt: blockedAt,
      },
      { merge: true },
    );

    return {
      disposition: "blocked",
      payout: {
        payoutId,
        eventId: canonicalEventId,
        eventName,
        status: PAYOUT_STATES.BLOCKED,
        totalPayableCents,
        failureReason: "no_payable_balance",
      },
    };
  }

  const status = stripeAccountReady
    ? PAYOUT_STATES.REQUESTED
    : PAYOUT_STATES.BLOCKED;
  const failureReason = stripeAccountReady ? null : "no_connected_account";
  const payoutDocument = buildCanonicalPayoutDocument({
    payoutId,
    promoterId,
    eventName,
    reconciliationData: {
      ...reconciliationData,
      reconciliationId: reconciliationDoc.id,
    },
    existingData: payoutRequestData,
    status,
    failureReason,
    connectedAccountId,
    stripeAccountReady,
  });

  await payoutRequestRef.set(payoutDocument, { merge: true });
  await reconciliationDoc.ref.set(
    {
      payoutState: status,
      payoutStatus: status,
      payoutAttemptCount: payoutDocument.payoutAttemptCount,
      payoutFailureReason: failureReason,
      payoutRequestedAt: payoutDocument.payoutRequestedAt,
      reserveReleaseState: payoutDocument.reserveReleaseState,
      reserveReleaseAt: payoutDocument.reserveReleaseAt,
      updatedAt: payoutDocument.updatedAt,
    },
    { merge: true },
  );

  return {
    disposition: status === PAYOUT_STATES.REQUESTED ? "requested" : "blocked",
    payout: {
      payoutId,
      eventId: canonicalEventId,
      eventName: payoutDocument.eventName,
      status,
      totalPayableCents,
      failureReason,
    },
  };
}

// ── Event reconciliation (Firestore-backed) ────────────────────────────
const reconcileEvent = onCall({ region: REGION }, async (request) => {
  const { eventId } = request.data;
  if (!eventId) return { error: "eventId required" };

  try {
    const uid = await requireAuth(request);
    const eventDoc = await getEventSnapshot(eventId);
    if (!eventDoc.exists) return { error: "Event not found" };

    const eventData = getEventData(eventDoc);
    if (normalizeOptionalString(eventData.promoterId)) {
      await assertAdminOrPromoter(request, eventData.promoterId);
    }

    const persisted = await persistReconciliationSnapshot({
      eventId,
      eventDoc,
      reconciledBy: uid,
    });

    return {
      reconciliationId: persisted.reconciliationId,
      totalBuys: persisted.record.totalBuys,
      totalGrossCents: persisted.record.totalGrossCents,
      totalNetCents: persisted.record.totalNetCents,
      totalRefundedCents: persisted.record.totalRefundedCents,
      totalDfcCents: persisted.record.totalDfcCents,
      totalPromoterCents: persisted.record.totalPromoterCents,
      totalReserveCents: persisted.record.totalReserveCents,
      totalPayableCents: persisted.record.totalPayableCents,
      payoutState: persisted.record.payoutState,
      reserveReleaseAt:
        toDateValue(persisted.record.reserveReleaseAt)?.toISOString() || null,
      checksum: persisted.checksum,
      csvRowCount: persisted.record.csvRowCount,
    };
  } catch (error) {
    return { error: error.message || "Reconciliation failed" };
  }
});

// ── Get event summary (read-only for promoter dashboard) ───────────────
const getEventSummary = onCall({ region: REGION }, async (request) => {
  const { eventId } = request.data;
  if (!eventId) return { error: "eventId required" };

  try {
    await requireAuth(request);
    const eventDoc = await getEventSnapshot(eventId);
    if (!eventDoc.exists) return { error: "Event not found" };

    const eventData = getEventData(eventDoc);
    if (normalizeOptionalString(eventData.promoterId)) {
      await assertAdminOrPromoter(request, eventData.promoterId);
    }

    const eventLookupIds = buildEventLookupIds({
      eventId: getCanonicalEventId(eventDoc, eventId),
      snapshot: eventDoc,
    });
    const latestReconciliation =
      await getLatestEventReconciliation(eventLookupIds);

    if (latestReconciliation) {
      const recon = latestReconciliation.data();
      return {
        source: "reconciliation",
        ...recon,
        reconciledAt: toDateValue(recon.reconciledAt)?.toISOString() || null,
        reserveReleaseAt:
          toDateValue(
            recon.reserveReleaseAt || recon.reserveReleaseDate,
          )?.toISOString() || null,
        eventStartTime:
          toDateValue(recon.eventStartTime)?.toISOString() || null,
      };
    }

    const preview = await buildReconciliationSnapshot({ eventId, eventDoc });
    return {
      source: "live",
      ...preview.record,
      reconciledAt:
        toDateValue(preview.record.reconciledAt)?.toISOString() || null,
      reserveReleaseAt:
        toDateValue(
          preview.record.reserveReleaseAt || preview.record.reserveReleaseDate,
        )?.toISOString() || null,
      eventStartTime:
        toDateValue(preview.record.eventStartTime)?.toISOString() || null,
    };
  } catch (error) {
    return { error: error.message || "Unable to load event summary" };
  }
});

// ── Deterministic promoter payout requests ─────────────────────────────
const requestPromoterPayouts = onCall({ region: REGION }, async (request) => {
  try {
    const actorUid = await requireAuth(request);
    const actorData = await loadUserData(actorUid);
    const promoterId =
      normalizeOptionalString(request.data?.promoterId) ||
      normalizeOptionalString(actorData.promoterId) ||
      actorUid;

    const access = await assertAdminOrPromoter(request, promoterId);
    const [connectedSnap, promoterEventsSnap, promoterReconciliations] =
      await Promise.all([
        db.collection("connected_accounts_v2").doc(promoterId).get(),
        db
          .collection("ppv_events")
          .where("promoterId", "==", promoterId)
          .limit(MAX_PROMOTER_EVENTS)
          .get(),
        listReconciliationsForPromoter(promoterId, MAX_PROMOTER_EVENTS),
      ]);

    const connectedData = connectedSnap.exists ? connectedSnap.data() : {};
    const connectedAccountId = normalizeOptionalString(
      connectedData.stripeAccountId,
    );
    const stripeAccountReady = Boolean(
      connectedAccountId &&
      (connectedData.onboardingComplete === true ||
        connectedData.status === "active"),
    );

    const { eventAliasToPrimaryId, eventNames } = buildPromoterEventMaps(
      promoterEventsSnap.docs,
    );
    const latestReconciliationByEventId = buildLatestReconciliationMap(
      promoterReconciliations,
      eventAliasToPrimaryId,
    );

    let requestedCount = 0;
    let blockedCount = 0;
    let skippedCount = 0;
    const payouts = [];

    for (const eventDoc of promoterEventsSnap.docs) {
      const outcome = await syncPromoterEventPayoutRequest({
        eventDoc,
        promoterId,
        accessUid: access.uid,
        eventNames,
        eventAliasToPrimaryId,
        latestReconciliationByEventId,
        stripeAccountReady,
        connectedAccountId,
      });

      if (outcome.disposition === "requested") {
        requestedCount += 1;
      } else if (outcome.disposition === "blocked") {
        blockedCount += 1;
      } else {
        skippedCount += 1;
      }

      payouts.push(outcome.payout);
    }

    return {
      promoterId,
      requestedCount,
      blockedCount,
      skippedCount,
      stripeAccountReady,
      connectedAccountId,
      payouts,
    };
  } catch (error) {
    return { error: error.message || "Unable to request promoter payouts" };
  }
});

// ── Projection endpoint ────────────────────────────────────────────────
const getProjection = onCall({ region: REGION }, async (request) => {
  const { currentBuys, additionalBuys, priceCents } = request.data;
  if (currentBuys == null || additionalBuys == null) {
    return { error: "currentBuys and additionalBuys required" };
  }

  const price = priceCents || 2000;
  const projectedBuys = (currentBuys || 0) + (additionalBuys || 0);
  const stripeFeePer = Math.round(price * STRIPE_RATE) + STRIPE_FIXED;
  const netPerBuy = price - stripeFeePer;

  const currentSplit = computePpvSplit(currentBuys, currentBuys * netPerBuy);
  const projectedSplit = computePpvSplit(
    projectedBuys,
    projectedBuys * netPerBuy,
  );

  return {
    current: { buys: currentBuys, ...currentSplit },
    projected: { buys: projectedBuys, ...projectedSplit },
    incrementalPromoterCents:
      projectedSplit.payableCents - currentSplit.payableCents,
  };
});

module.exports = {
  computePpvSplit,
  reconcileEvent,
  getEventSummary,
  getProjection,
  requestPromoterPayouts,
};
