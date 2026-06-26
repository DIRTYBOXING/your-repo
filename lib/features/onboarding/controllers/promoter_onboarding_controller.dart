import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/models/promoter_commercial_profile.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/stripe_connect_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PROMOTER ONBOARDING CONTROLLER
/// Tracks 5-step onboarding: Identity → Terms → Stripe → Assets → Launch
/// Persists progress to Firestore so promoters can resume anytime.
/// ═══════════════════════════════════════════════════════════════════════════
class PromoterOnboardingController extends ChangeNotifier {
  PromoterOnboardingController({
    required this.authService,
    required this.stripeService,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final AuthService authService;
  final StripeConnectService stripeService;
  final FirebaseFirestore _firestore;

  // ── Step state ────────────────────────────────────────────────────
  int currentStep = 0;
  static const int totalSteps = 5;

  // Step 0: Organization Identity
  String promotionName = '';
  String contactEmail = '';
  String region = '';
  String website = '';
  String licenseNumber = '';

  // Step 1: Terms & Consent
  bool termsAccepted = false;
  bool ugcLicenseAccepted = false;
  bool promoterGuaranteeAccepted = false;
  bool refundPolicyAccepted = false;

  // Step 2: Stripe Connect
  bool stripeOnboarded = false;
  String? stripeAccountId;

  // Step 3: Assets uploaded
  bool heroImageUploaded = false;
  bool eventPosterUploaded = false;
  bool promoClipUploaded = false;
  bool consentFormsUploaded = false;
  String? consentToken;
  bool rightsIntakeStarted = false;
  bool rightsIntakeSubmitted = false;
  bool rightsIntakeApproved = false;
  String? rightsLicenseId;

  // Step 4: Launch (final confirm)
  bool finalConfirmAccepted = false;

  // ── Controller state ──────────────────────────────────────────────
  bool isSaving = false;
  bool isLoading = false;
  String? errorMessage;

  String? get uid => authService.firebaseUser?.uid;

  // ── Progress ──────────────────────────────────────────────────────
  double get progress => (currentStep + 1) / totalSteps;
  bool get isLastStep => currentStep == totalSteps - 1;

  bool get allTermsAccepted =>
      termsAccepted &&
      ugcLicenseAccepted &&
      promoterGuaranteeAccepted &&
      refundPolicyAccepted;

  int get assetsCompleted {
    int count = 0;
    if (heroImageUploaded) count++;
    if (eventPosterUploaded) count++;
    if (promoClipUploaded) count++;
    if (consentFormsUploaded) count++;
    return count;
  }

  /// Gate per step — determines if NEXT is enabled.
  bool get canContinue {
    switch (currentStep) {
      case 0: // Identity
        return promotionName.isNotEmpty && contactEmail.isNotEmpty;
      case 1: // Terms & Consent
        return allTermsAccepted;
      case 2: // Stripe Connect
        return stripeOnboarded;
      case 3: // Assets
        return heroImageUploaded && eventPosterUploaded;
      case 4: // Launch
        return finalConfirmAccepted;
      default:
        return false;
    }
  }

  /// Whether the entire onboarding is complete and the promoter can create events.
  bool get isFullyOnboarded =>
      allTermsAccepted && stripeOnboarded && heroImageUploaded;

  // ── Navigation ────────────────────────────────────────────────────
  void nextStep() {
    if (currentStep < totalSteps - 1 && canContinue) {
      currentStep++;
      _saveProgress();
      notifyListeners();
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < totalSteps) {
      currentStep = step;
      notifyListeners();
    }
  }

  // ── Step 0: Identity ──────────────────────────────────────────────
  void updatePromotionName(String value) {
    promotionName = value.trim();
    notifyListeners();
  }

  void updateContactEmail(String value) {
    contactEmail = value.trim();
    notifyListeners();
  }

  void updateRegion(String value) {
    region = value.trim();
    notifyListeners();
  }

  void updateWebsite(String value) {
    website = value.trim();
    notifyListeners();
  }

  void updateLicenseNumber(String value) {
    licenseNumber = value.trim();
    notifyListeners();
  }

  // ── Step 1: Consent toggles ──────────────────────────────────────
  void setTermsAccepted(bool value) {
    termsAccepted = value;
    notifyListeners();
  }

  void setUgcLicenseAccepted(bool value) {
    ugcLicenseAccepted = value;
    notifyListeners();
  }

  void setPromoterGuaranteeAccepted(bool value) {
    promoterGuaranteeAccepted = value;
    notifyListeners();
  }

  void setRefundPolicyAccepted(bool value) {
    refundPolicyAccepted = value;
    notifyListeners();
  }

  // ── Step 2: Stripe Connect ───────────────────────────────────────
  /// Call StripeConnectService to start hosted onboarding.
  /// Returns URL the UI should launch in a browser.
  Future<String?> startStripeOnboarding() async {
    final userId = uid;
    if (userId == null) return null;

    errorMessage = null;
    notifyListeners();

    final url = await stripeService.startOnboarding(
      userId: userId,
      email: contactEmail.isNotEmpty
          ? contactEmail
          : authService.userModel?.email ?? '',
      businessName: promotionName.isNotEmpty ? promotionName : null,
    );

    return url;
  }

  /// Check Stripe status after returning from hosted onboarding.
  Future<void> refreshStripeStatus() async {
    final userId = uid;
    if (userId == null) return;

    final status = await stripeService.checkStatus(userId);
    stripeOnboarded = status.chargesEnabled && status.payoutsEnabled;
    stripeAccountId = status.accountId;
    if (stripeOnboarded) {
      _saveProgress();
    }
    notifyListeners();
  }

  // ── Step 3: Asset flags ──────────────────────────────────────────
  void markHeroImageUploaded(bool value) {
    heroImageUploaded = value;
    notifyListeners();
  }

  void markEventPosterUploaded(bool value) {
    eventPosterUploaded = value;
    notifyListeners();
  }

  void markPromoClipUploaded(bool value) {
    promoClipUploaded = value;
    notifyListeners();
  }

  void markConsentFormsUploaded(bool value) {
    consentFormsUploaded = value;
    notifyListeners();
  }

  void setConsentToken(String token) {
    consentToken = token;
    notifyListeners();
  }

  // ── Step 4: Final confirm ────────────────────────────────────────
  void setFinalConfirmAccepted(bool value) {
    finalConfirmAccepted = value;
    notifyListeners();
  }

  // ── Persistence ──────────────────────────────────────────────────

  /// Load saved progress from Firestore.
  Future<void> loadProgress() async {
    final userId = uid;
    if (userId == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore
          .collection('promoter_onboarding')
          .doc(userId)
          .get();

      if (doc.exists) {
        final profile = PromoterCommercialProfile.fromMap(userId, doc.data()!);
        currentStep = profile.currentStep;
        promotionName = profile.promotionName;
        contactEmail = profile.contactEmail;
        region = profile.region;
        website = profile.website;
        licenseNumber = profile.licenseNumber;
        termsAccepted = profile.termsAccepted;
        ugcLicenseAccepted = profile.ugcLicenseAccepted;
        promoterGuaranteeAccepted = profile.promoterGuaranteeAccepted;
        refundPolicyAccepted = profile.refundPolicyAccepted;
        stripeOnboarded = profile.stripeOnboarded;
        stripeAccountId = profile.stripeAccountId;
        heroImageUploaded = profile.heroImageUploaded;
        eventPosterUploaded = profile.eventPosterUploaded;
        promoClipUploaded = profile.promoClipUploaded;
        consentFormsUploaded = profile.consentFormsUploaded;
        consentToken = profile.consentToken;
        rightsIntakeStarted = profile.rightsIntakeStarted;
        rightsIntakeSubmitted = profile.rightsIntakeSubmitted;
        rightsIntakeApproved = profile.rightsIntakeApproved;
        rightsLicenseId = profile.rightsLicenseId;
        finalConfirmAccepted = profile.finalConfirmAccepted;
      }

      // Also check Stripe status if we haven't confirmed it yet
      if (!stripeOnboarded) {
        await refreshStripeStatus();
      }
      await refreshRightsIntakeStatus();
    } catch (e) {
      debugPrint('PromoterOnboardingController.loadProgress error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Save current progress to Firestore.
  Future<void> _saveProgress() async {
    final userId = uid;
    if (userId == null) return;

    try {
      final profile = PromoterCommercialProfile(
        promoterId: userId,
        currentStep: currentStep,
        promotionName: promotionName,
        contactEmail: contactEmail,
        region: region,
        website: website,
        licenseNumber: licenseNumber,
        termsAccepted: termsAccepted,
        ugcLicenseAccepted: ugcLicenseAccepted,
        promoterGuaranteeAccepted: promoterGuaranteeAccepted,
        refundPolicyAccepted: refundPolicyAccepted,
        stripeOnboarded: stripeOnboarded,
        stripeAccountId: stripeAccountId,
        heroImageUploaded: heroImageUploaded,
        eventPosterUploaded: eventPosterUploaded,
        promoClipUploaded: promoClipUploaded,
        consentFormsUploaded: consentFormsUploaded,
        consentToken: consentToken,
        rightsIntakeStarted: rightsIntakeStarted,
        rightsIntakeSubmitted: rightsIntakeSubmitted,
        rightsIntakeApproved: rightsIntakeApproved,
        rightsLicenseId: rightsLicenseId,
        finalConfirmAccepted: finalConfirmAccepted,
      );
      await _firestore
          .collection('promoter_onboarding')
          .doc(userId)
          .set(profile.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('PromoterOnboardingController._saveProgress error: $e');
    }
  }

  Future<void> refreshRightsIntakeStatus() async {
    final userId = uid;
    if (userId == null) return;

    try {
      final snap = await _firestore
          .collection('ppv_licenses')
          .where('promoterId', isEqualTo: userId)
          .limit(5)
          .get();

      if (snap.docs.isEmpty) {
        rightsIntakeStarted = false;
        rightsIntakeSubmitted = false;
        rightsIntakeApproved = false;
        rightsLicenseId = null;
      } else {
        final docs = [...snap.docs]
          ..sort((a, b) {
            final aTs = a.data()['updatedAt'] as Timestamp?;
            final bTs = b.data()['updatedAt'] as Timestamp?;
            final aDate =
                aTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate =
                bTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
        final latest = docs.first;
        final status = latest.data()['status']?.toString() ?? 'draft';
        rightsLicenseId = latest.id;
        rightsIntakeStarted = true;
        rightsIntakeSubmitted = {
          'pending',
          'approved',
          'active',
        }.contains(status);
        rightsIntakeApproved = {'approved', 'active'}.contains(status);
      }

      await _saveProgress();
      notifyListeners();
    } catch (e) {
      debugPrint(
        'PromoterOnboardingController.refreshRightsIntakeStatus error: $e',
      );
    }
  }

  // ── Consent audit logging ────────────────────────────────────────

  /// Log each consent acceptance as an immutable audit record.
  /// Follows the pattern from UgcConsentService._logAuditEvent.
  Future<void> logConsentAudit({
    required String consentType,
    required String version,
    String? ipAddress,
  }) async {
    final userId = uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('promoter_onboarding')
          .doc(userId)
          .collection('consent_audit')
          .add({
            'userId': userId,
            'consentType': consentType,
            'version': version,
            'isGranted': true,
            'ipAddress': ipAddress,
            'promotionName': promotionName,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('PromoterOnboardingController.logConsentAudit error: $e');
    }
  }

  // ── Complete onboarding ──────────────────────────────────────────

  /// Finalize the promoter onboarding — writes to users collection,
  /// logs final audit, and marks promoter as verified.
  Future<bool> completeOnboarding() async {
    if (isSaving || !isFullyOnboarded || !finalConfirmAccepted) return false;

    final userId = uid;
    if (userId == null) {
      errorMessage = 'No authenticated user found.';
      notifyListeners();
      return false;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final batch = _firestore.batch();

      // 1. Mark promoter_onboarding as complete
      batch.set(
        _firestore.collection('promoter_onboarding').doc(userId),
        {
          'completedAt': FieldValue.serverTimestamp(),
          'isComplete': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 2. Update user document — set role to promoter, mark verified
      batch.update(_firestore.collection('users').doc(userId), {
        'businessVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'metadata': {
          'promoterOnboarding': {
            'promotionName': promotionName,
            'region': region,
            'stripeAccountId': stripeAccountId,
            'rightsLicenseId': rightsLicenseId,
            'rightsIntakeStarted': rightsIntakeStarted,
            'rightsIntakeApproved': rightsIntakeApproved,
            'completedAt': DateTime.now().toIso8601String(),
          },
        },
      });

      await batch.commit();

      // 3. Log final audit event
      await logConsentAudit(
        consentType: 'promoter_onboarding_complete',
        version: '1.0',
      );

      // 4. Refresh user profile so the app sees the update
      await authService.refreshUserProfile();

      return true;
    } catch (e) {
      errorMessage = 'Failed to complete onboarding: $e';
      debugPrint('PromoterOnboardingController.completeOnboarding error: $e');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
