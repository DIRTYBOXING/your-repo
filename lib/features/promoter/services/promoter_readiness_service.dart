import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/event_model.dart';
import '../../../shared/models/promoter_commercial_profile.dart';
import '../../../shared/models/ppv_license_model.dart';
import '../../../shared/services/media_visibility_service.dart';
import '../../../shared/services/stripe_connect_service.dart';
import '../../../shared/services/ppv_license_service.dart';

class PromoterReadinessService {
  PromoterReadinessService({
    FirebaseFirestore? firestore,
    StripeConnectService? stripeConnectService,
    PpvLicenseService? licenseService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _stripeConnectService = stripeConnectService ?? StripeConnectService(),
       _licenseService = licenseService ?? PpvLicenseService();

  final FirebaseFirestore _firestore;
  final StripeConnectService _stripeConnectService;
  final PpvLicenseService _licenseService;
  late final MediaVisibilityService _mediaVisibilityService =
      MediaVisibilityService(firestore: _firestore);

  Future<PromoterCommercialProfile> getCommercialProfile(
    String promoterId,
  ) async {
    final doc = await _firestore
        .collection('promoter_onboarding')
        .doc(promoterId)
        .get();
    if (!doc.exists) {
      return PromoterCommercialProfile.empty(promoterId);
    }
    return PromoterCommercialProfile.fromMap(
      promoterId,
      doc.data() ?? const {},
    );
  }

  Future<PromoterReadinessSnapshot> getPromoterReadiness({
    required String promoterId,
    String? eventId,
  }) async {
    final profile = await getCommercialProfile(promoterId);

    ConnectAccountStatus? stripeStatus;
    try {
      stripeStatus = await _stripeConnectService.checkStatus(promoterId);
    } catch (_) {}

    EventModel? event;
    PpvLicenseModel? license;
    if (eventId != null && eventId.isNotEmpty) {
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (eventDoc.exists) {
        event = EventModel.fromFirestore(eventDoc);
      }
      license = await _licenseService.getLicenseForEventId(eventId);
    }

    final stripeReady =
        stripeStatus?.readyToProcessPayments ?? profile.stripeOnboarded;
    final mediaReady = event == null
        ? profile.requiredAssetsReady
        : await _mediaVisibilityService.hasApprovedEventMedia(event);

    final blockers = <String>[];
    if (!profile.allTermsAccepted) {
      blockers.add('Accept promoter commercial terms');
    }
    if (!stripeReady) {
      blockers.add('Complete Stripe Connect onboarding');
    }
    if (!mediaReady) {
      blockers.add('Add approved poster and banner media');
    }
    if (event != null && license == null) {
      blockers.add('Create a rights intake record for this event');
    }
    if (license != null && !license.thirdPartyRightsOk) {
      blockers.add('Clear third-party rights and talent releases');
    }
    if (license != null && !license.insuranceOk) {
      blockers.add('Confirm event and cyber insurance');
    }
    if (license != null && !license.isCleared) {
      blockers.add('Submit and approve PPV rights intake');
    }

    return PromoterReadinessSnapshot(
      promoterId: promoterId,
      profile: profile,
      stripeReady: stripeReady,
      stripeAccountId: stripeStatus?.accountId ?? profile.stripeAccountId,
      event: event,
      license: license,
      mediaReady: mediaReady,
      blockers: blockers,
    );
  }
}

class PromoterReadinessSnapshot {
  const PromoterReadinessSnapshot({
    required this.promoterId,
    required this.profile,
    required this.stripeReady,
    required this.stripeAccountId,
    required this.event,
    required this.license,
    required this.mediaReady,
    required this.blockers,
  });

  final String promoterId;
  final PromoterCommercialProfile profile;
  final bool stripeReady;
  final String? stripeAccountId;
  final EventModel? event;
  final PpvLicenseModel? license;
  final bool mediaReady;
  final List<String> blockers;

  bool get onboardingReady => profile.allTermsAccepted && stripeReady;
  bool get hasLicenseDraft => license != null;
  bool get licenseCleared => license?.isCleared ?? false;
  bool get eventCanGoLive => onboardingReady && mediaReady && licenseCleared;
}
