// ═══════════════════════════════════════════════════════════════════════════
// INFLUENCER — Upload, consent capture, verification endpoints
// Real consent flow for micro-influencer DM seeding campaigns.
// ═══════════════════════════════════════════════════════════════════════════

const { onCall } = require("firebase-functions/v2/https");
const { FieldValue } = require("firebase-admin/firestore");
const { admin, db, REGION } = require("../config");

const serverTimestamp = () => FieldValue.serverTimestamp();

const INFLUENCERS_COLLECTION = "influencers";
const CONSENT_COLLECTION = "influencer_consent";

// Valid platforms for influencer records
const VALID_PLATFORMS = new Set([
  "tiktok",
  "instagram",
  "x",
  "youtube",
  "discord",
]);

function buildInfluencerDocId(platform, handle) {
  return `${platform.toLowerCase()}_${handle.replaceAll(/\W/g, "")}`;
}

// ═══════════════════════════════════════════════════════════════════════════
// UPLOAD CSV ROWS — Validates schema and stores influencer records
// ═══════════════════════════════════════════════════════════════════════════
const influencerUpload = onCall({ region: REGION }, async (request) => {
  const { rows } = request.data || {};
  if (!rows || !Array.isArray(rows) || rows.length === 0) {
    return {
      status: "error",
      message: "rows array required (parsed CSV rows)",
    };
  }

  // Cap per batch to prevent abuse
  if (rows.length > 500) {
    return { status: "error", message: "Maximum 500 rows per upload" };
  }

  const results = { accepted: 0, rejected: 0, missingConsent: 0, errors: [] };
  const batch = db.batch();
  let batchCount = 0;

  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];

    // Validate required fields
    if (
      !row.handle ||
      typeof row.handle !== "string" ||
      row.handle.trim().length === 0
    ) {
      results.rejected++;
      results.errors.push({ row: i, reason: "missing or invalid handle" });
      continue;
    }

    if (!row.platform || !VALID_PLATFORMS.has(row.platform.toLowerCase())) {
      results.rejected++;
      results.errors.push({
        row: i,
        reason: `invalid platform: ${row.platform}`,
      });
      continue;
    }

    // Sanitize handle
    const handle = row.handle.trim();

    // Check consent
    const hasConsent = row.consent === true || row.consent === "true";
    if (!hasConsent) {
      results.missingConsent++;
    }

    const ref = db
      .collection(INFLUENCERS_COLLECTION)
      .doc(buildInfluencerDocId(row.platform, handle));
    batch.set(
      ref,
      {
        handle,
        platform: row.platform.toLowerCase(),
        displayName: row.displayName || "",
        email: row.email || "",
        phone: row.phone || "",
        timezone: row.timezone || "",
        geo: row.geo || "",
        country: row.country || "",
        consent: hasConsent,
        consentTimestamp: row.consentTimestamp || null,
        consentId: row.consentId || null,
        engagementScore: Number(row.engagementScore) || 0,
        avgViews: Number(row.avgViews) || 0,
        notes: row.notes || "",
        tier: row.tier || "standard",
        status: hasConsent ? "active" : "pending_consent",
        uploadedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      },
      { merge: true },
    );

    results.accepted++;
    batchCount++;

    // Firestore batch limit is 500 writes
    if (batchCount >= 499) {
      await batch.commit();
      batchCount = 0;
    }
  }

  if (batchCount > 0) {
    await batch.commit();
  }

  return {
    status: "ok",
    total: rows.length,
    accepted: results.accepted,
    rejected: results.rejected,
    missingConsent: results.missingConsent,
    errors: results.errors.slice(0, 20), // Cap error list
  };
});

// ═══════════════════════════════════════════════════════════════════════════
// CONSENT CAPTURE — Stores explicit consent record linked to influencer
// ═══════════════════════════════════════════════════════════════════════════
const influencerConsent = onCall({ region: REGION }, async (request) => {
  const {
    handle,
    platform,
    displayName,
    contact,
    consent,
    consentTimestamp,
    consentScope,
    consentText,
    signedBy,
    signedMethod,
  } = request.data || {};

  if (!handle || !platform) {
    return { status: "error", message: "handle and platform required" };
  }

  if (consent !== true) {
    return { status: "error", message: "consent must be true for capture" };
  }

  if (
    !consentScope ||
    !Array.isArray(consentScope) ||
    consentScope.length === 0
  ) {
    return {
      status: "error",
      message:
        'consentScope array required (e.g. ["dm_seeding", "paid_campaigns"])',
    };
  }

  if (!signedBy || !signedMethod) {
    return {
      status: "error",
      message: "signedBy and signedMethod required for legal compliance",
    };
  }

  // Create consent record
  const consentRef = await db.collection(CONSENT_COLLECTION).add({
    handle,
    platform: platform.toLowerCase(),
    displayName: displayName || "",
    contact: contact || {},
    consent: true,
    consentTimestamp: consentTimestamp || new Date().toISOString(),
    consentScope,
    consentText: consentText || "",
    signedBy,
    signedMethod,
    revokedAt: null,
    status: "active",
    createdAt: serverTimestamp(),
  });

  // Update influencer record with consentId
  const influencerDocId = buildInfluencerDocId(platform, handle);
  await db
    .collection(INFLUENCERS_COLLECTION)
    .doc(influencerDocId)
    .set(
      {
        handle,
        platform: platform.toLowerCase(),
        displayName: displayName || "",
        consent: true,
        consentId: consentRef.id,
        consentTimestamp: consentTimestamp || new Date().toISOString(),
        status: "active",
        updatedAt: serverTimestamp(),
      },
      { merge: true },
    );

  return {
    status: "ok",
    consentId: consentRef.id,
    handle,
    platform: platform.toLowerCase(),
  };
});

// ═══════════════════════════════════════════════════════════════════════════
// REVOKE CONSENT — Honors opt-out immediately
// ═══════════════════════════════════════════════════════════════════════════
const influencerRevokeConsent = onCall({ region: REGION }, async (request) => {
  const { handle, platform, consentId, reason } = request.data || {};

  if (!handle || !platform) {
    return { status: "error", message: "handle and platform required" };
  }

  // Revoke the consent record
  if (consentId) {
    await db
      .collection(CONSENT_COLLECTION)
      .doc(consentId)
      .update({
        status: "revoked",
        revokedAt: serverTimestamp(),
        revokeReason: reason || "user_requested",
      });
  }

  // Also revoke any active consent records for this handle
  const activeConsents = await db
    .collection(CONSENT_COLLECTION)
    .where("handle", "==", handle)
    .where("platform", "==", platform.toLowerCase())
    .where("status", "==", "active")
    .get();

  const batch = db.batch();
  for (const doc of activeConsents.docs) {
    batch.update(doc.ref, {
      status: "revoked",
      revokedAt: serverTimestamp(),
      revokeReason: reason || "user_requested",
    });
  }

  // Update influencer record
  const influencerDocId = buildInfluencerDocId(platform, handle);
  batch.update(db.collection(INFLUENCERS_COLLECTION).doc(influencerDocId), {
    consent: false,
    consentId: null,
    status: "consent_revoked",
    updatedAt: serverTimestamp(),
  });

  await batch.commit();

  return {
    status: "ok",
    handle,
    platform: platform.toLowerCase(),
    message: "Consent revoked. No further DMs will be sent.",
  };
});

// ═══════════════════════════════════════════════════════════════════════════
// VERIFY CONSENT — Background verification before DM seeding
// ═══════════════════════════════════════════════════════════════════════════
const influencerVerifyConsent = onCall({ region: REGION }, async (request) => {
  const { handles } = request.data || {};

  if (!handles || !Array.isArray(handles) || handles.length === 0) {
    return {
      status: "error",
      message: "handles array required [{handle, platform}]",
    };
  }

  const results = [];
  for (const item of handles) {
    if (!item.handle || !item.platform) {
      results.push({
        handle: item.handle,
        platform: item.platform,
        valid: false,
        reason: "missing_fields",
      });
      continue;
    }

    const docId = buildInfluencerDocId(item.platform, item.handle);
    const doc = await db.collection(INFLUENCERS_COLLECTION).doc(docId).get();

    if (!doc.exists) {
      results.push({
        handle: item.handle,
        platform: item.platform,
        valid: false,
        reason: "not_found",
      });
      continue;
    }

    const data = doc.data();
    if (!data.consent || data.status === "consent_revoked") {
      results.push({
        handle: item.handle,
        platform: item.platform,
        valid: false,
        reason: "no_active_consent",
      });
      continue;
    }

    // Verify consentId exists in consent collection
    if (data.consentId) {
      const consentDoc = await db
        .collection(CONSENT_COLLECTION)
        .doc(data.consentId)
        .get();
      if (!consentDoc.exists || consentDoc.data().status !== "active") {
        results.push({
          handle: item.handle,
          platform: item.platform,
          valid: false,
          reason: "consent_record_invalid",
        });
        continue;
      }
    }

    results.push({
      handle: item.handle,
      platform: item.platform,
      valid: true,
      consentId: data.consentId,
    });
  }

  return {
    status: "ok",
    total: handles.length,
    valid: results.filter((r) => r.valid).length,
    invalid: results.filter((r) => !r.valid).length,
    results,
  };
});

module.exports = {
  influencerUpload,
  influencerConsent,
  influencerRevokeConsent,
  influencerVerifyConsent,
};
