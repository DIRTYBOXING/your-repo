import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class PromoterCommercialProfile extends Equatable {
  final String promoterId;
  final int currentStep;
  final String promotionName;
  final String contactEmail;
  final String region;
  final String website;
  final String licenseNumber;
  final bool termsAccepted;
  final bool ugcLicenseAccepted;
  final bool promoterGuaranteeAccepted;
  final bool refundPolicyAccepted;
  final bool stripeOnboarded;
  final String? stripeAccountId;
  final bool heroImageUploaded;
  final bool eventPosterUploaded;
  final bool promoClipUploaded;
  final bool consentFormsUploaded;
  final String? consentToken;
  final bool rightsIntakeStarted;
  final bool rightsIntakeSubmitted;
  final bool rightsIntakeApproved;
  final String? rightsLicenseId;
  final bool finalConfirmAccepted;
  final bool isComplete;
  final DateTime? completedAt;
  final DateTime? updatedAt;

  const PromoterCommercialProfile({
    required this.promoterId,
    this.currentStep = 0,
    this.promotionName = '',
    this.contactEmail = '',
    this.region = '',
    this.website = '',
    this.licenseNumber = '',
    this.termsAccepted = false,
    this.ugcLicenseAccepted = false,
    this.promoterGuaranteeAccepted = false,
    this.refundPolicyAccepted = false,
    this.stripeOnboarded = false,
    this.stripeAccountId,
    this.heroImageUploaded = false,
    this.eventPosterUploaded = false,
    this.promoClipUploaded = false,
    this.consentFormsUploaded = false,
    this.consentToken,
    this.rightsIntakeStarted = false,
    this.rightsIntakeSubmitted = false,
    this.rightsIntakeApproved = false,
    this.rightsLicenseId,
    this.finalConfirmAccepted = false,
    this.isComplete = false,
    this.completedAt,
    this.updatedAt,
  });

  factory PromoterCommercialProfile.empty(String promoterId) {
    return PromoterCommercialProfile(promoterId: promoterId);
  }

  bool get allTermsAccepted =>
      termsAccepted &&
      ugcLicenseAccepted &&
      promoterGuaranteeAccepted &&
      refundPolicyAccepted;

  bool get requiredAssetsReady => heroImageUploaded && eventPosterUploaded;

  bool get onboardingReady => allTermsAccepted && stripeOnboarded;

  bool get commercialReady => onboardingReady && requiredAssetsReady;

  bool get rightsReady => rightsIntakeStarted;

  int get assetsCompleted {
    var count = 0;
    if (heroImageUploaded) count++;
    if (eventPosterUploaded) count++;
    if (promoClipUploaded) count++;
    if (consentFormsUploaded) count++;
    return count;
  }

  factory PromoterCommercialProfile.fromMap(
    String promoterId,
    Map<String, dynamic> data,
  ) {
    DateTime? toDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return PromoterCommercialProfile(
      promoterId: promoterId,
      currentStep: (data['currentStep'] as int?) ?? 0,
      promotionName: (data['promotionName'] as String?) ?? '',
      contactEmail: (data['contactEmail'] as String?) ?? '',
      region: (data['region'] as String?) ?? '',
      website: (data['website'] as String?) ?? '',
      licenseNumber: (data['licenseNumber'] as String?) ?? '',
      termsAccepted: (data['termsAccepted'] as bool?) ?? false,
      ugcLicenseAccepted: (data['ugcLicenseAccepted'] as bool?) ?? false,
      promoterGuaranteeAccepted:
          (data['promoterGuaranteeAccepted'] as bool?) ?? false,
      refundPolicyAccepted: (data['refundPolicyAccepted'] as bool?) ?? false,
      stripeOnboarded: (data['stripeOnboarded'] as bool?) ?? false,
      stripeAccountId: data['stripeAccountId'] as String?,
      heroImageUploaded: (data['heroImageUploaded'] as bool?) ?? false,
      eventPosterUploaded: (data['eventPosterUploaded'] as bool?) ?? false,
      promoClipUploaded: (data['promoClipUploaded'] as bool?) ?? false,
      consentFormsUploaded: (data['consentFormsUploaded'] as bool?) ?? false,
      consentToken: data['consentToken'] as String?,
      rightsIntakeStarted: (data['rightsIntakeStarted'] as bool?) ?? false,
      rightsIntakeSubmitted: (data['rightsIntakeSubmitted'] as bool?) ?? false,
      rightsIntakeApproved: (data['rightsIntakeApproved'] as bool?) ?? false,
      rightsLicenseId: data['rightsLicenseId'] as String?,
      finalConfirmAccepted: (data['finalConfirmAccepted'] as bool?) ?? false,
      isComplete: (data['isComplete'] as bool?) ?? false,
      completedAt: toDate(data['completedAt']),
      updatedAt: toDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'currentStep': currentStep,
      'promotionName': promotionName,
      'contactEmail': contactEmail,
      'region': region,
      'website': website,
      'licenseNumber': licenseNumber,
      'termsAccepted': termsAccepted,
      'ugcLicenseAccepted': ugcLicenseAccepted,
      'promoterGuaranteeAccepted': promoterGuaranteeAccepted,
      'refundPolicyAccepted': refundPolicyAccepted,
      'stripeOnboarded': stripeOnboarded,
      'stripeAccountId': stripeAccountId,
      'heroImageUploaded': heroImageUploaded,
      'eventPosterUploaded': eventPosterUploaded,
      'promoClipUploaded': promoClipUploaded,
      'consentFormsUploaded': consentFormsUploaded,
      'consentToken': consentToken,
      'rightsIntakeStarted': rightsIntakeStarted,
      'rightsIntakeSubmitted': rightsIntakeSubmitted,
      'rightsIntakeApproved': rightsIntakeApproved,
      'rightsLicenseId': rightsLicenseId,
      'finalConfirmAccepted': finalConfirmAccepted,
      'isComplete': isComplete,
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [
    promoterId,
    currentStep,
    promotionName,
    contactEmail,
    region,
    website,
    licenseNumber,
    termsAccepted,
    ugcLicenseAccepted,
    promoterGuaranteeAccepted,
    refundPolicyAccepted,
    stripeOnboarded,
    stripeAccountId,
    heroImageUploaded,
    eventPosterUploaded,
    promoClipUploaded,
    consentFormsUploaded,
    consentToken,
    rightsIntakeStarted,
    rightsIntakeSubmitted,
    rightsIntakeApproved,
    rightsLicenseId,
    finalConfirmAccepted,
    isComplete,
    completedAt,
    updatedAt,
  ];
}
