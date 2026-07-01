// ═══════════════════════════════════════════════════════════════════════════
// CHUKYA 3.0 — Police Validation Cloud Function
// ═══════════════════════════════════════════════════════════════════════════
// Validates restraining orders and stores hashed phone identifiers.
// Only callable by authenticated users with police_service custom claim.
// Raw phone numbers are NEVER stored — only HMAC-SHA256 hashes.
// ═══════════════════════════════════════════════════════════════════════════

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { admin, db, REGION } = require("../config");
const crypto = require("crypto");

// HMAC secret from environment — set via:
//   firebase functions:secrets:set CHUKYA_HMAC_SECRET
const HMAC_SECRET = process.env.CHUKYA_HMAC_SECRET || "";

function hmacPhone(normalizedPhone) {
  return crypto
    .createHmac("sha256", HMAC_SECRET)
    .update(normalizedPhone)
    .digest("hex");
}

// ─── Add Threat Profile ──────────────────────────────────────────────────
// Police-only callable that validates a restraining order case and stores
// a hashed phone identifier in the victim's watchlist.
exports.addThreatProfile = onCall({ region: REGION }, async (request) => {
  // Auth gate: must be police_service role
  if (!request.auth || request.auth.token.role !== "police_service") {
    throw new HttpsError(
      "permission-denied",
      "Only police service accounts can add threat profiles",
    );
  }

  const {
    victimId,
    caseRef,
    phoneNumber,
    offenderAlias,
    restrainingDistance,
    deviceCharacteristics,
  } = request.data;

  if (!victimId || !caseRef || !phoneNumber) {
    throw new HttpsError(
      "invalid-argument",
      "victimId, caseRef, and phoneNumber are required",
    );
  }

  // Normalize phone to digits only (E.164 recommended upstream)
  const normalized = phoneNumber.replace(/\D/g, "");
  if (normalized.length < 8) {
    throw new HttpsError(
      "invalid-argument",
      "Phone number too short after normalization",
    );
  }

  // Hash phone — raw number is NEVER stored
  const hashedPhone = hmacPhone(normalized);

  // Write to threat_watchlist
  const profileRef = db
    .collection("threat_watchlist")
    .doc(victimId)
    .collection("profiles")
    .doc();
  await profileRef.set({
    hashedPhone,
    caseRef,
    offenderAlias: offenderAlias || "Unknown",
    restrainingDistanceMeters: restrainingDistance || 200,
    deviceCharacteristics: deviceCharacteristics || {},
    policeValidated: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    addedBy: request.auth.uid,
  });

  // Audit log — immutable record of police action
  await db.collection("police_validations").add({
    victimId,
    caseRef,
    profileId: profileRef.id,
    addedBy: request.auth.uid,
    action: "add_threat_profile",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true, profileId: profileRef.id };
});

// ─── Revoke Threat Profile ───────────────────────────────────────────────
// Police-only callable to deactivate a threat profile (preserves record).
exports.revokeThreatProfile = onCall({ region: REGION }, async (request) => {
  if (!request.auth || request.auth.token.role !== "police_service") {
    throw new HttpsError(
      "permission-denied",
      "Only police service accounts can revoke profiles",
    );
  }

  const { victimId, profileId, reason } = request.data;
  if (!victimId || !profileId) {
    throw new HttpsError("invalid-argument", "victimId and profileId required");
  }

  await db
    .collection("threat_watchlist")
    .doc(victimId)
    .collection("profiles")
    .doc(profileId)
    .update({
      revoked: true,
      revokedAt: admin.firestore.FieldValue.serverTimestamp(),
      revokedBy: request.auth.uid,
      revokeReason: reason || "Order expired or rescinded",
    });

  // Audit log
  await db.collection("police_validations").add({
    victimId,
    profileId,
    addedBy: request.auth.uid,
    action: "revoke_threat_profile",
    reason: reason || "",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});
