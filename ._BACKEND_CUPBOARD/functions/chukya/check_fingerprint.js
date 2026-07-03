// ═══════════════════════════════════════════════════════════════════════════
// CHUKYA 3.0 — Fingerprint Check Cloud Function
// ═══════════════════════════════════════════════════════════════════════════
// Compares device fingerprint from a victim's phone against hashed
// watchlist entries using weighted fuzzy matching.
//
// Scoring weights:
//   0.60 — hashed phone match (strong)
//   0.20 — manufacturer data hash overlap
//   0.15 — device name similarity
//   0.10 — RSSI histogram similarity (cosine)
//
// Returns { caseRef, confidence } if confidence >= 0.8, else null.
// ═══════════════════════════════════════════════════════════════════════════

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { admin, db, REGION } = require("../config");

// ── Similarity Helpers ───────────────────────────────────────────────────

/**
 * Cosine similarity on RSSI histogram bucket vectors.
 */
function rssiHistogramSimilarity(a, b) {
  if (!a || !b) return 0;
  const keys = new Set([...Object.keys(a), ...Object.keys(b)]);
  let dot = 0,
    normA = 0,
    normB = 0;
  keys.forEach((k) => {
    const va = a[k] || 0;
    const vb = b[k] || 0;
    dot += va * vb;
    normA += va * va;
    normB += vb * vb;
  });
  if (normA === 0 || normB === 0) return 0;
  return dot / (Math.sqrt(normA) * Math.sqrt(normB));
}

/**
 * Simple bigram-based string similarity (0–1).
 * Avoids external dependency on string-similarity package.
 */
function stringSimilarity(a, b) {
  if (!a || !b) return 0;
  a = a.toLowerCase().trim();
  b = b.toLowerCase().trim();
  if (a === b) return 1;
  if (a.length < 2 || b.length < 2) return 0;

  const bigrams = (s) => {
    const set = new Map();
    for (let i = 0; i < s.length - 1; i++) {
      const bg = s.substring(i, i + 2);
      set.set(bg, (set.get(bg) || 0) + 1);
    }
    return set;
  };

  const bgrA = bigrams(a);
  const bgrB = bigrams(b);
  let intersection = 0;
  bgrA.forEach((count, bg) => {
    if (bgrB.has(bg)) intersection += Math.min(count, bgrB.get(bg));
  });

  return (2.0 * intersection) / (a.length + b.length - 2);
}

// ── Main Function ────────────────────────────────────────────────────────

exports.chukyaCheckFingerprint = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  const fingerprint = request.data?.fingerprint;
  if (!fingerprint) {
    throw new HttpsError("invalid-argument", "Missing fingerprint payload");
  }

  const devicePhoneHash = fingerprint.phoneHash || null;
  const victimId = request.data.victimId || request.auth.uid;

  // Query profiles for this victim (scoped, not global scan)
  let profilesSnap;
  if (victimId) {
    profilesSnap = await db
      .collection("threat_watchlist")
      .doc(victimId)
      .collection("profiles")
      .where("revoked", "!=", true)
      .get()
      .catch(() => null);

    // Fallback if revoked field doesn't exist on docs
    if (!profilesSnap || profilesSnap.empty) {
      profilesSnap = await db
        .collection("threat_watchlist")
        .doc(victimId)
        .collection("profiles")
        .get();
    }
  } else {
    // Should not happen in production — always scope to victim
    return null;
  }

  if (!profilesSnap || profilesSnap.empty) return null;

  let bestMatch = null;

  for (const doc of profilesSnap.docs) {
    const profile = doc.data();
    if (profile.revoked === true) continue;

    let score = 0;

    // 1. Hashed phone strong match (0.60 weight)
    if (
      devicePhoneHash &&
      profile.hashedPhone &&
      devicePhoneHash === profile.hashedPhone
    ) {
      score += 0.6;
    }

    // 2. Manufacturer data hash overlap (up to 0.20)
    const profileManHashes =
      profile.deviceCharacteristics?.manufacturerHashes || [];
    const deviceManHashes = fingerprint.manufacturerHashes || [];
    const manOverlap = deviceManHashes.filter((h) =>
      profileManHashes.includes(h),
    ).length;
    if (manOverlap > 0) {
      score += Math.min(0.2, 0.05 * manOverlap);
    }

    // 3. Device name similarity (up to 0.15)
    const profileNames = profile.deviceCharacteristics?.names || [];
    const deviceNames = fingerprint.names || [];
    let nameScore = 0;
    for (const dn of deviceNames) {
      for (const pn of profileNames) {
        const sim = stringSimilarity(dn, pn);
        if (sim > 0.6) nameScore = Math.max(nameScore, sim);
      }
    }
    score += nameScore * 0.15;

    // 4. RSSI histogram cosine similarity (up to 0.10)
    const histSim = rssiHistogramSimilarity(
      profile.deviceCharacteristics?.rssiHistogram || {},
      fingerprint.rssiHistogram || {},
    );
    score += histSim * 0.1;

    // Track best
    const confidence = Math.min(1.0, score);
    if (confidence > (bestMatch?.confidence || 0)) {
      bestMatch = {
        profileId: doc.id,
        caseRef: profile.caseRef,
        confidence,
      };
    }
  }

  // Only return matches above threshold
  if (bestMatch && bestMatch.confidence >= 0.8) {
    // Audit: log the match event (no PII, just metadata)
    await db.collection("chukya_match_audit").add({
      victimId,
      profileId: bestMatch.profileId,
      confidence: bestMatch.confidence,
      deviceCount: fingerprint.deviceCount || 0,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { caseRef: bestMatch.caseRef, confidence: bestMatch.confidence };
  }

  return null;
});
