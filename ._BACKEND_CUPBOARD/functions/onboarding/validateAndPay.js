// ═══════════════════════════════════════════════════════════════════════════
// PROMOTER GATEKEEPER — Validation, Consent, Audit, Launch Gate
// No promoter goes live without passing every check.
// ═══════════════════════════════════════════════════════════════════════════

const { onCall } = require("firebase-functions/v2/https");
const { admin, db, REGION, stripe } = require("../config");

// ─────────────────────────────────────────────────────────────────────────────
// validatePromoterAndCheckout
//
// Master gate: verifies onboarding completion, consent token, Stripe status,
// legal acceptance, and logs an immutable audit trail before allowing launch.
//
// Called from Flutter PromoterService before any event/promotion goes live.
// ─────────────────────────────────────────────────────────────────────────────
const validatePromoterAndCheckout = onCall(
  { region: REGION },
  async (request) => {
    // ── Auth Guard ──────────────────────────────────────────────────────────
    if (!request.auth) {
      return { error: "Authentication required", code: "UNAUTHENTICATED" };
    }

    const uid = request.auth.uid;
    const { eventId, action } = request.data || {};

    if (!action) {
      return {
        error: "action is required (validate | launch)",
        code: "MISSING_ACTION",
      };
    }

    try {
      // ── Fetch onboarding progress ───────────────────────────────────────
      const onboardingRef = db.collection("promoter_onboarding").doc(uid);
      const onboardingSnap = await onboardingRef.get();

      if (!onboardingSnap.exists) {
        return {
          validated: false,
          code: "NO_ONBOARDING",
          message:
            "Promoter onboarding not started. Complete all steps before launching.",
        };
      }

      const onboarding = onboardingSnap.data();

      // ── Fetch user profile ──────────────────────────────────────────────
      const userSnap = await db.collection("users").doc(uid).get();
      const userData = userSnap.exists ? userSnap.data() : {};

      // ── Fetch Stripe Connect status ─────────────────────────────────────
      const connectSnap = await db
        .collection("connected_accounts_v2")
        .doc(uid)
        .get();
      const connectData = connectSnap.exists ? connectSnap.data() : {};

      // ── Master Gate Checks ──────────────────────────────────────────────
      const checks = {
        onboardingComplete: onboarding.isComplete === true,
        termsAccepted: onboarding.termsAccepted === true,
        ugcLicenseAccepted: onboarding.ugcLicenseAccepted === true,
        promoterGuaranteeAccepted:
          onboarding.promoterGuaranteeAccepted === true,
        refundPolicyAccepted: onboarding.refundPolicyAccepted === true,
        hasConsentToken: !!onboarding.consentToken,
        stripeOnboarded: onboarding.stripeOnboarded === true,
        stripeAccountLinked: !!connectData.stripeAccountId,
        stripeActive:
          connectData.onboardingComplete === true ||
          connectData.status === "active",
        heroImageUploaded: onboarding.heroImageUploaded === true,
      };

      const allPassed = Object.values(checks).every((v) => v === true);

      // ── Build failure reasons ───────────────────────────────────────────
      const failures = [];
      if (!checks.onboardingComplete) failures.push("Onboarding not completed");
      if (!checks.termsAccepted) failures.push("Terms of service not accepted");
      if (!checks.ugcLicenseAccepted) failures.push("UGC license not accepted");
      if (!checks.promoterGuaranteeAccepted)
        failures.push("Promoter guarantee not accepted");
      if (!checks.refundPolicyAccepted)
        failures.push("Refund policy not accepted");
      if (!checks.hasConsentToken) failures.push("Consent token missing");
      if (!checks.stripeOnboarded)
        failures.push("Stripe onboarding not completed");
      if (!checks.stripeAccountLinked)
        failures.push("Stripe account not linked");
      if (!checks.stripeActive) failures.push("Stripe account not active");
      if (!checks.heroImageUploaded) failures.push("Hero image not uploaded");

      // ── Immutable Audit Log ─────────────────────────────────────────────
      const ipAddress =
        request.rawRequest?.ip ||
        request.rawRequest?.headers?.["x-forwarded-for"] ||
        "unknown";

      const auditEntry = {
        action: action,
        uid: uid,
        eventId: eventId || null,
        checks: checks,
        allPassed: allPassed,
        failures: failures,
        ipAddress: ipAddress,
        userAgent: request.rawRequest?.headers?.["user-agent"] || "unknown",
        consentToken: onboarding.consentToken || null,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        serverTime: new Date().toISOString(),
      };

      // Write immutable audit to subcollection
      await onboardingRef.collection("audit").add(auditEntry);

      // Also write to top-level audit collection for admin dashboards
      await db.collection("promoter_audit_trail").add({
        ...auditEntry,
        displayName: userData.displayName || null,
        email: userData.email || null,
      });

      // ── Return validation result ────────────────────────────────────────
      if (!allPassed) {
        return {
          validated: false,
          code: "GATE_FAILED",
          checks: checks,
          failures: failures,
          message: `Validation failed: ${failures.join(", ")}`,
        };
      }

      // ── If action is 'launch' and Stripe is configured, create checkout ─
      if (action === "launch" && stripe && eventId) {
        const eventSnap = await db.collection("events").doc(eventId).get();
        if (!eventSnap.exists) {
          return {
            validated: true,
            code: "EVENT_NOT_FOUND",
            message: "Event document not found",
          };
        }

        const eventData = eventSnap.data();
        const stripeAccountId = connectData.stripeAccountId;

        // Log launch attempt
        await onboardingRef.collection("audit").add({
          action: "launch_checkout_initiated",
          uid: uid,
          eventId: eventId,
          stripeAccountId: stripeAccountId,
          ipAddress: ipAddress,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          serverTime: new Date().toISOString(),
        });

        return {
          validated: true,
          code: "GATE_PASSED",
          checks: checks,
          stripeAccountId: stripeAccountId,
          eventTitle:
            eventData.title || eventData.eventName || "Untitled Event",
          message: "All gates passed. Promoter cleared for launch.",
        };
      }

      return {
        validated: true,
        code: "GATE_PASSED",
        checks: checks,
        message: "All gates passed. Promoter validated.",
      };
    } catch (err) {
      console.error("[validatePromoterAndCheckout] Error:", err);

      // Log error to audit trail
      try {
        await db.collection("promoter_audit_trail").add({
          action: "validation_error",
          uid: uid,
          eventId: eventId || null,
          error: err.message,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          serverTime: new Date().toISOString(),
        });
      } catch (_) {
        // Silent — don't let audit logging failure mask the original error
      }

      return {
        validated: false,
        code: "INTERNAL_ERROR",
        message: "Server error during validation. Try again.",
      };
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// getPromoterGateStatus
//
// Lightweight read-only check — returns current gate status without logging.
// Used by Flutter UI to show/disable launch buttons in real time.
// ─────────────────────────────────────────────────────────────────────────────
const getPromoterGateStatus = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    return { error: "Authentication required", code: "UNAUTHENTICATED" };
  }

  const uid = request.auth.uid;

  try {
    const [onboardingSnap, connectSnap] = await Promise.all([
      db.collection("promoter_onboarding").doc(uid).get(),
      db.collection("connected_accounts_v2").doc(uid).get(),
    ]);

    if (!onboardingSnap.exists) {
      return { gateOpen: false, reason: "Onboarding not started" };
    }

    const ob = onboardingSnap.data();
    const cn = connectSnap.exists ? connectSnap.data() : {};

    const gateOpen =
      ob.isComplete === true &&
      ob.termsAccepted === true &&
      ob.ugcLicenseAccepted === true &&
      ob.promoterGuaranteeAccepted === true &&
      ob.refundPolicyAccepted === true &&
      !!ob.consentToken &&
      ob.stripeOnboarded === true &&
      !!cn.stripeAccountId &&
      (cn.onboardingComplete === true || cn.status === "active") &&
      ob.heroImageUploaded === true;

    return {
      gateOpen: gateOpen,
      checks: {
        onboardingComplete: ob.isComplete === true,
        allTermsAccepted:
          ob.termsAccepted === true &&
          ob.ugcLicenseAccepted === true &&
          ob.promoterGuaranteeAccepted === true &&
          ob.refundPolicyAccepted === true,
        hasConsentToken: !!ob.consentToken,
        stripeReady: ob.stripeOnboarded === true && !!cn.stripeAccountId,
        stripeActive: cn.onboardingComplete === true || cn.status === "active",
        heroImageUploaded: ob.heroImageUploaded === true,
      },
    };
  } catch (err) {
    console.error("[getPromoterGateStatus] Error:", err);
    return { gateOpen: false, reason: "Error checking gate status" };
  }
});

module.exports = {
  validatePromoterAndCheckout,
  getPromoterGateStatus,
};
