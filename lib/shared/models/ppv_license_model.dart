import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV BROADCAST LICENSE MODEL
///
/// Full licensing pipeline for pay-per-view streaming rights.
/// Covers: territory, exclusivity, term, royalty/revenue share,
/// minimum guarantees, DRM/geo-blocking, ACMA compliance, sublicensing,
/// third-party rights clearance, and audit trail.
///
/// Every PPV event that goes live MUST have an approved PpvLicense.
/// No stream URL is set until license.isCleared == true.
/// ═══════════════════════════════════════════════════════════════════════════

// ── Enums ─────────────────────────────────────────────────────────────────

enum LicenseStatus {
  draft, // Term sheet stage — negotiation in progress
  pending, // Submitted for review
  approved, // Cleared by admin — stream can go live
  active, // Currently in term and streaming
  suspended, // Paused due to dispute or regulatory hold
  expired, // Term ended
  terminated, // Early termination by either party
}

enum ExclusivityType {
  exclusive, // Only DFC can stream in territory
  nonExclusive, // Multiple platforms can stream
  firstWindow, // DFC gets first broadcast window, then non-exclusive
}

enum RevenueModel {
  flatFee, // One-time payment for rights
  revenueShare, // Percentage of PPV sales
  hybrid, // Minimum guarantee + revenue share overage
  freeToAir, // No charge (promotional deal)
}

enum TerritoryScope {
  australia,
  newZealand,
  oceania, // AU + NZ + Pacific Islands
  asiaPacific,
  northAmerica,
  europe,
  global,
  custom, // Defined by customTerritories list
}

enum DrmRequirement {
  none,
  widevine,
  fairplay,
  playready,
  multiDrm, // All three
}

// ── Main Model ────────────────────────────────────────────────────────────

class PpvLicenseModel extends Equatable {
  // ── Identity ──
  final String id;
  final String ppvEventId; // Links to PPVEvent
  final String eventId; // Links to EventModel
  final String promoterId; // The rightsholder granting the license

  // ── Parties ──
  final String licenseeEntity; // "Data Fight Central Pty Ltd"
  final String licensorEntity; // Promoter / production company name
  final String licensorContact; // Licensor email or phone
  final String? licensorAbn; // Australian Business Number

  // ── Territory & Platform ──
  final TerritoryScope territory;
  final List<String> customTerritories; // Used when territory == custom
  final List<String> platforms; // ['web', 'ios', 'android', 'smartTv']
  final bool geoBlockingRequired;
  final List<String> blockedCountries; // ISO country codes to block

  // ── Exclusivity & Term ──
  final ExclusivityType exclusivity;
  final DateTime termStart;
  final DateTime termEnd;
  final bool autoRenew;
  final int? renewalTermDays;
  final DateTime? terminationNoticeDeadline;
  final String? terminationClause;

  // ── Commercial Terms ──
  final RevenueModel revenueModel;
  final int? flatFeeCents; // For flatFee model
  final double?
  revenueSharePct; // sliding 0.70-0.50 (promoter share based on exposure)
  final int? minimumGuaranteeCents; // For hybrid model
  final String currency;
  final String? paymentTerms; // e.g. "Net 30 after event"
  final bool auditRightsGranted;
  final String? reportingCadence; // e.g. "Weekly during active, monthly after"

  // ── Sublicensing ──
  final bool sublicensingAllowed;
  final List<String> approvedSublicensees; // e.g. ['Kayo', 'Stan Sport']

  // ── Third-Party Clearances ──
  final bool musicRightsCleared;
  final String? musicCueSheet; // URL to uploaded cue sheet
  final bool talentReleasesObtained;
  final bool archivalFootageCleared;
  final bool logosTrademarkCleared;
  final String? collectingSocietyRef; // e.g. Screenrights reference number

  // ── Technical Delivery ──
  final DrmRequirement drmRequirement;
  final String? ingestFormat; // e.g. "RTMP push to CDN endpoint"
  final String? cdnProvider;
  final bool watermarkingRequired;
  final String? deliverySlaNotes;
  final String? testingWindowNotes;

  // ── ACMA Compliance ──
  final bool acmaLicenseRequired;
  final String? acmaLicenseNumber;
  final bool acmaExemptionConfirmed;
  final String? regulatoryNotes;

  // ── Insurance ──
  final bool eventInsuranceConfirmed;
  final bool cyberInsuranceConfirmed;
  final String? insurancePolicyRef;

  // ── Attestation & Approval ──
  final LicenseStatus status;
  final bool licensorAttestationSigned;
  final DateTime? licensorAttestationAt;
  final String? approvedBy; // Admin UID
  final DateTime? approvedAt;
  final String? rejectionReason;
  final String? suspensionReason;

  // ── Chain of Title ──
  final String? chainOfTitleDocUrl; // Upload of signed chain-of-title
  final String? signedLicenseDocUrl; // Upload of executed license agreement
  final String? talentReleaseDocUrl;
  final List<String> supportingDocUrls;

  // ── Audit ──
  final String createdBy; // UID of who drafted the license
  final DateTime createdAt;
  final DateTime updatedAt;

  const PpvLicenseModel({
    required this.id,
    required this.ppvEventId,
    required this.eventId,
    required this.promoterId,
    this.licenseeEntity = 'Data Fight Central Pty Ltd',
    required this.licensorEntity,
    required this.licensorContact,
    this.licensorAbn,
    this.territory = TerritoryScope.australia,
    this.customTerritories = const [],
    this.platforms = const ['web', 'ios', 'android'],
    this.geoBlockingRequired = true,
    this.blockedCountries = const [],
    this.exclusivity = ExclusivityType.nonExclusive,
    required this.termStart,
    required this.termEnd,
    this.autoRenew = false,
    this.renewalTermDays,
    this.terminationNoticeDeadline,
    this.terminationClause,
    this.revenueModel = RevenueModel.hybrid,
    this.flatFeeCents,
    this.revenueSharePct,
    this.minimumGuaranteeCents,
    this.currency = 'AUD',
    this.paymentTerms,
    this.auditRightsGranted = true,
    this.reportingCadence,
    this.sublicensingAllowed = false,
    this.approvedSublicensees = const [],
    this.musicRightsCleared = false,
    this.musicCueSheet,
    this.talentReleasesObtained = false,
    this.archivalFootageCleared = false,
    this.logosTrademarkCleared = false,
    this.collectingSocietyRef,
    this.drmRequirement = DrmRequirement.multiDrm,
    this.ingestFormat,
    this.cdnProvider,
    this.watermarkingRequired = true,
    this.deliverySlaNotes,
    this.testingWindowNotes,
    this.acmaLicenseRequired = false,
    this.acmaLicenseNumber,
    this.acmaExemptionConfirmed = false,
    this.regulatoryNotes,
    this.eventInsuranceConfirmed = false,
    this.cyberInsuranceConfirmed = false,
    this.insurancePolicyRef,
    this.status = LicenseStatus.draft,
    this.licensorAttestationSigned = false,
    this.licensorAttestationAt,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.suspensionReason,
    this.chainOfTitleDocUrl,
    this.signedLicenseDocUrl,
    this.talentReleaseDocUrl,
    this.supportingDocUrls = const [],
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, ppvEventId, status];

  // ── Gate Check ──────────────────────────────────────────────────────────

  /// True when the license is fully cleared and the stream can go live.
  bool get isCleared =>
      status == LicenseStatus.approved || status == LicenseStatus.active;

  /// True when all third-party rights are confirmed cleared.
  bool get thirdPartyRightsOk =>
      musicRightsCleared &&
      talentReleasesObtained &&
      archivalFootageCleared &&
      logosTrademarkCleared;

  /// True when regulatory requirements are satisfied.
  bool get regulatoryOk =>
      !acmaLicenseRequired ||
      (acmaLicenseNumber != null && acmaLicenseNumber!.isNotEmpty) ||
      acmaExemptionConfirmed;

  /// True when insurance is in place.
  bool get insuranceOk => eventInsuranceConfirmed && cyberInsuranceConfirmed;

  /// Readiness score (0.0–1.0) for the license pipeline UI.
  double get readinessScore {
    int checks = 0;
    int passed = 0;

    checks++;
    if (licensorAttestationSigned) passed++;
    checks++;
    if (thirdPartyRightsOk) passed++;
    checks++;
    if (regulatoryOk) passed++;
    checks++;
    if (insuranceOk) passed++;
    checks++;
    if (chainOfTitleDocUrl != null) passed++;
    checks++;
    if (signedLicenseDocUrl != null) passed++;
    checks++;
    if (isCleared) passed++;

    return checks > 0 ? passed / checks : 0;
  }

  /// Term sheet summary for display.
  static const String termSheetTemplate = '''
DFC PPV LICENCE TERM SHEET
═══════════════════════════
Licensor: [PROMOTER / RIGHTS HOLDER]
Licensee: Data Fight Central Pty Ltd
Event: [EVENT NAME]
Territory: Australia (primary), with option for global
Platforms: DFC Web, iOS, Android apps
Exclusivity: [Exclusive / Non-Exclusive / First Window]
Term: [Start Date] to [End Date], with [auto-renew / no auto-renew]
Revenue Model: Sliding Agreement — 30% DFC floor → 50% DFC ceiling based on exposure
             Promoter starts at 70% revenue; DFC share slides up with views/buys
             No hard tier jumps — smooth linear scale (minimum guarantee: \$[X])
Payment Terms: Net 30 after event date
Sublicensing: [Permitted to approved partners / Not permitted]
DRM: Multi-DRM (Widevine + FairPlay + PlayReady)
Geo-Blocking: Enabled (territory-restricted)
ACMA: [License #X / Exempt under Schedule 2]
Insurance: Event liability + Cyber/E&O required
Reporting: Weekly during active broadcast, monthly post-event
Audit Rights: Granted, 30 days notice
Takedown: Immediate on verified DMCA/rights dispute
Governing Law: Queensland, Australia
''';

  // ── Firestore ───────────────────────────────────────────────────────────

  factory PpvLicenseModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return PpvLicenseModel(
      id: doc.id,
      ppvEventId: _s(d['ppvEventId']),
      eventId: _s(d['eventId']),
      promoterId: _s(d['promoterId']),
      licenseeEntity:
          d['licenseeEntity']?.toString() ?? 'Data Fight Central Pty Ltd',
      licensorEntity: _s(d['licensorEntity']),
      licensorContact: _s(d['licensorContact']),
      licensorAbn: d['licensorAbn']?.toString(),
      territory: _territoryFromString(d['territory']?.toString()),
      customTerritories: List<String>.from(d['customTerritories'] ?? []),
      platforms: List<String>.from(d['platforms'] ?? ['web', 'ios', 'android']),
      geoBlockingRequired: d['geoBlockingRequired'] as bool? ?? true,
      blockedCountries: List<String>.from(d['blockedCountries'] ?? []),
      exclusivity: _exclusivityFromString(d['exclusivity']?.toString()),
      termStart: _toDate(d['termStart']) ?? DateTime.now(),
      termEnd:
          _toDate(d['termEnd']) ?? DateTime.now().add(const Duration(days: 30)),
      autoRenew: d['autoRenew'] as bool? ?? false,
      renewalTermDays: (d['renewalTermDays'] as num?)?.toInt(),
      terminationNoticeDeadline: _toDate(d['terminationNoticeDeadline']),
      terminationClause: d['terminationClause']?.toString(),
      revenueModel: _revenueModelFromString(d['revenueModel']?.toString()),
      flatFeeCents: (d['flatFeeCents'] as num?)?.toInt(),
      revenueSharePct: (d['revenueSharePct'] as num?)?.toDouble(),
      minimumGuaranteeCents: (d['minimumGuaranteeCents'] as num?)?.toInt(),
      currency: d['currency']?.toString() ?? 'AUD',
      paymentTerms: d['paymentTerms']?.toString(),
      auditRightsGranted: d['auditRightsGranted'] as bool? ?? true,
      reportingCadence: d['reportingCadence']?.toString(),
      sublicensingAllowed: d['sublicensingAllowed'] as bool? ?? false,
      approvedSublicensees: List<String>.from(d['approvedSublicensees'] ?? []),
      musicRightsCleared: d['musicRightsCleared'] as bool? ?? false,
      musicCueSheet: d['musicCueSheet']?.toString(),
      talentReleasesObtained: d['talentReleasesObtained'] as bool? ?? false,
      archivalFootageCleared: d['archivalFootageCleared'] as bool? ?? false,
      logosTrademarkCleared: d['logosTrademarkCleared'] as bool? ?? false,
      collectingSocietyRef: d['collectingSocietyRef']?.toString(),
      drmRequirement: _drmFromString(d['drmRequirement']?.toString()),
      ingestFormat: d['ingestFormat']?.toString(),
      cdnProvider: d['cdnProvider']?.toString(),
      watermarkingRequired: d['watermarkingRequired'] as bool? ?? true,
      deliverySlaNotes: d['deliverySlaNotes']?.toString(),
      testingWindowNotes: d['testingWindowNotes']?.toString(),
      acmaLicenseRequired: d['acmaLicenseRequired'] as bool? ?? false,
      acmaLicenseNumber: d['acmaLicenseNumber']?.toString(),
      acmaExemptionConfirmed: d['acmaExemptionConfirmed'] as bool? ?? false,
      regulatoryNotes: d['regulatoryNotes']?.toString(),
      eventInsuranceConfirmed: d['eventInsuranceConfirmed'] as bool? ?? false,
      cyberInsuranceConfirmed: d['cyberInsuranceConfirmed'] as bool? ?? false,
      insurancePolicyRef: d['insurancePolicyRef']?.toString(),
      status: _statusFromString(d['status']?.toString()),
      licensorAttestationSigned:
          d['licensorAttestationSigned'] as bool? ?? false,
      licensorAttestationAt: _toDate(d['licensorAttestationAt']),
      approvedBy: d['approvedBy']?.toString(),
      approvedAt: _toDate(d['approvedAt']),
      rejectionReason: d['rejectionReason']?.toString(),
      suspensionReason: d['suspensionReason']?.toString(),
      chainOfTitleDocUrl: d['chainOfTitleDocUrl']?.toString(),
      signedLicenseDocUrl: d['signedLicenseDocUrl']?.toString(),
      talentReleaseDocUrl: d['talentReleaseDocUrl']?.toString(),
      supportingDocUrls: List<String>.from(d['supportingDocUrls'] ?? []),
      createdBy: _s(d['createdBy']),
      createdAt: _toDate(d['createdAt']) ?? DateTime.now(),
      updatedAt: _toDate(d['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'ppvEventId': ppvEventId,
    'eventId': eventId,
    'promoterId': promoterId,
    'licenseeEntity': licenseeEntity,
    'licensorEntity': licensorEntity,
    'licensorContact': licensorContact,
    'licensorAbn': licensorAbn,
    'territory': territory.name,
    'customTerritories': customTerritories,
    'platforms': platforms,
    'geoBlockingRequired': geoBlockingRequired,
    'blockedCountries': blockedCountries,
    'exclusivity': exclusivity.name,
    'termStart': Timestamp.fromDate(termStart),
    'termEnd': Timestamp.fromDate(termEnd),
    'autoRenew': autoRenew,
    'renewalTermDays': renewalTermDays,
    'terminationNoticeDeadline': terminationNoticeDeadline != null
        ? Timestamp.fromDate(terminationNoticeDeadline!)
        : null,
    'terminationClause': terminationClause,
    'revenueModel': revenueModel.name,
    'flatFeeCents': flatFeeCents,
    'revenueSharePct': revenueSharePct,
    'minimumGuaranteeCents': minimumGuaranteeCents,
    'currency': currency,
    'paymentTerms': paymentTerms,
    'auditRightsGranted': auditRightsGranted,
    'reportingCadence': reportingCadence,
    'sublicensingAllowed': sublicensingAllowed,
    'approvedSublicensees': approvedSublicensees,
    'musicRightsCleared': musicRightsCleared,
    'musicCueSheet': musicCueSheet,
    'talentReleasesObtained': talentReleasesObtained,
    'archivalFootageCleared': archivalFootageCleared,
    'logosTrademarkCleared': logosTrademarkCleared,
    'collectingSocietyRef': collectingSocietyRef,
    'drmRequirement': drmRequirement.name,
    'ingestFormat': ingestFormat,
    'cdnProvider': cdnProvider,
    'watermarkingRequired': watermarkingRequired,
    'deliverySlaNotes': deliverySlaNotes,
    'testingWindowNotes': testingWindowNotes,
    'acmaLicenseRequired': acmaLicenseRequired,
    'acmaLicenseNumber': acmaLicenseNumber,
    'acmaExemptionConfirmed': acmaExemptionConfirmed,
    'regulatoryNotes': regulatoryNotes,
    'eventInsuranceConfirmed': eventInsuranceConfirmed,
    'cyberInsuranceConfirmed': cyberInsuranceConfirmed,
    'insurancePolicyRef': insurancePolicyRef,
    'status': status.name,
    'licensorAttestationSigned': licensorAttestationSigned,
    'licensorAttestationAt': licensorAttestationAt != null
        ? Timestamp.fromDate(licensorAttestationAt!)
        : null,
    'approvedBy': approvedBy,
    'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
    'rejectionReason': rejectionReason,
    'suspensionReason': suspensionReason,
    'chainOfTitleDocUrl': chainOfTitleDocUrl,
    'signedLicenseDocUrl': signedLicenseDocUrl,
    'talentReleaseDocUrl': talentReleaseDocUrl,
    'supportingDocUrls': supportingDocUrls,
    'createdBy': createdBy,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  // ── Helpers ─────────────────────────────────────────────────────────────

  static String _s(dynamic v) => v?.toString() ?? '';

  static DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static LicenseStatus _statusFromString(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'pending':
        return LicenseStatus.pending;
      case 'approved':
        return LicenseStatus.approved;
      case 'active':
        return LicenseStatus.active;
      case 'suspended':
        return LicenseStatus.suspended;
      case 'expired':
        return LicenseStatus.expired;
      case 'terminated':
        return LicenseStatus.terminated;
      default:
        return LicenseStatus.draft;
    }
  }

  static TerritoryScope _territoryFromString(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'newzealand':
        return TerritoryScope.newZealand;
      case 'oceania':
        return TerritoryScope.oceania;
      case 'asiapacific':
        return TerritoryScope.asiaPacific;
      case 'northamerica':
        return TerritoryScope.northAmerica;
      case 'europe':
        return TerritoryScope.europe;
      case 'global':
        return TerritoryScope.global;
      case 'custom':
        return TerritoryScope.custom;
      default:
        return TerritoryScope.australia;
    }
  }

  static ExclusivityType _exclusivityFromString(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'exclusive':
        return ExclusivityType.exclusive;
      case 'firstwindow':
        return ExclusivityType.firstWindow;
      default:
        return ExclusivityType.nonExclusive;
    }
  }

  static RevenueModel _revenueModelFromString(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'flatfee':
        return RevenueModel.flatFee;
      case 'revenueshare':
        return RevenueModel.revenueShare;
      case 'freetoair':
        return RevenueModel.freeToAir;
      default:
        return RevenueModel.hybrid;
    }
  }

  static DrmRequirement _drmFromString(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'none':
        return DrmRequirement.none;
      case 'widevine':
        return DrmRequirement.widevine;
      case 'fairplay':
        return DrmRequirement.fairplay;
      case 'playready':
        return DrmRequirement.playready;
      default:
        return DrmRequirement.multiDrm;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROMOTER DOCUMENT CHECKLIST
// ═══════════════════════════════════════════════════════════════════════════
//
// DFC is a PLATFORM / DISTRIBUTOR — it does NOT run events.
// Promoters are responsible for all event-level compliance.
// DFC's own obligations are minimal (ABN, ToS, Privacy, Disclaimers).
//
// This checklist defines what DFC requires FROM promoters before a PPV
// licence can be approved. Used in onboarding screens, email requests,
// and the admin approval dashboard.
// ═══════════════════════════════════════════════════════════════════════════

enum DocPriority { required, recommended, optional }

enum DocOwner { dfc, promoter }

class PromoterDocumentItem {
  final String id;
  final String title;
  final String description;
  final DocPriority priority;
  final DocOwner owner; // Who is responsible for supplying this
  final String? templateUrl; // Link to DFC template if available

  const PromoterDocumentItem({
    required this.id,
    required this.title,
    required this.description,
    this.priority = DocPriority.required,
    this.owner = DocOwner.promoter,
    this.templateUrl,
  });
}

class PromoterDocumentChecklist {
  // ═══════════════════════════════════════════════════════════════════
  // DFC PLATFORM DOCS — what DFC itself needs to operate.
  // DFC is a platform/distributor, NOT an event organiser.
  // These are already in place or in progress.
  // ═══════════════════════════════════════════════════════════════════
  static const List<PromoterDocumentItem> dfcPlatformDocs = [
    PromoterDocumentItem(
      id: 'dfc_abn',
      title: 'DFC ABN / Business Registration',
      description:
          'Australian Business Number for Data Fight Central. '
          'Required for Stripe Connect payouts, GST invoicing, and '
          'all promoter agreements. This is the ONLY hard compliance '
          'requirement DFC carries as a platform.',
      owner: DocOwner.dfc,
    ),
    PromoterDocumentItem(
      id: 'dfc_terms_of_service',
      title: 'Platform Terms of Service',
      description:
          'DFC Terms of Service governing all platform users, promoters, '
          'and viewers. Already published and embedded in the app. '
          'Covers acceptable use, liability limitations, DMCA, '
          'and dispute resolution.',
      owner: DocOwner.dfc,
    ),
    PromoterDocumentItem(
      id: 'dfc_privacy_policy',
      title: 'Privacy Policy',
      description:
          'DFC Privacy Policy compliant with Australian Privacy Act, '
          'GDPR (for international users), and platform store requirements. '
          'Already published and embedded in the app.',
      owner: DocOwner.dfc,
    ),
    PromoterDocumentItem(
      id: 'dfc_disclaimers',
      title: 'Platform Disclaimers & Liability Shield',
      description:
          'All combat sports risk disclaimers, viewer assumption of risk, '
          'no-medical-advice declarations, and content liability waivers. '
          'Already built into platform onboarding and event pages.',
      owner: DocOwner.dfc,
    ),
    PromoterDocumentItem(
      id: 'dfc_trademark',
      title: 'DFC Trademark Registration',
      description:
          'Trademark application for "Data Fight Central" / "DFC" '
          'name and logo. 3-month processing timeline from IP Australia. '
          'Platform can operate while pending. File under Class 41 '
          '(entertainment services) and Class 38 (streaming/telecoms).',
      priority: DocPriority.recommended,
      owner: DocOwner.dfc,
    ),
    PromoterDocumentItem(
      id: 'dfc_cyber_insurance',
      title: 'Cyber / E&O Insurance (Platform-Level)',
      description:
          'DFC platform coverage for data breaches, streaming outages, '
          'and content delivery errors. This is DFC\'s responsibility '
          'as infrastructure operator — NOT the promoter\'s. '
          'Recommended \$2M AUD minimum.',
      priority: DocPriority.optional,
      owner: DocOwner.dfc,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════
  // PROMOTER OBLIGATIONS — docs the PROMOTER must supply to DFC
  // before their event can go live on the platform.
  // DFC does NOT run events — promoters carry all event-level
  // compliance. DFC collects these for liability protection.
  // ═══════════════════════════════════════════════════════════════════
  static const List<PromoterDocumentItem> items = [
    // ── Chain of Title ──
    PromoterDocumentItem(
      id: 'chain_of_title',
      title: 'Chain of Title',
      description:
          'PROMOTER must provide a signed document proving they own or '
          'control the broadcast rights for the event. Must trace from '
          'original content creator through to the party granting the licence. '
          'If the promoter IS the original rights holder, a statutory '
          'declaration of ownership is acceptable. DFC does not run events — '
          'this is the promoter\'s responsibility.',
    ),

    // ── Talent Releases ──
    PromoterDocumentItem(
      id: 'talent_releases',
      title: 'Talent Release Forms (all fighters)',
      description:
          'PROMOTER must obtain signed releases from every fighter, corner '
          'person, and ring personality appearing on the broadcast. Must '
          'grant DFC distribution rights to stream, archive, and use '
          'likeness in promotional materials. Minors (under 18) require '
          'parent/guardian co-signature. Promoter bears full responsibility.',
    ),

    // ── Music Cue Sheet ──
    PromoterDocumentItem(
      id: 'music_cue_sheet',
      title: 'Music Cue Sheet',
      description:
          'Complete list of every music track used in the broadcast: '
          'walk-out music, intro themes, bumper music, highlight reel tracks. '
          'Columns: Track Title, Artist, Composer, Publisher, Duration, '
          'Usage (walk-out / background / theme), Licence Type '
          '(sync / blanket / royalty-free).',
    ),

    // ── Music Licence Proof ──
    PromoterDocumentItem(
      id: 'music_licence',
      title: 'Music Licence / APRA Clearance',
      description:
          'Proof of sync licence or APRA AMCOS blanket licence covering '
          'all tracks on the cue sheet. For royalty-free music, provide '
          'download receipts or licence certificates. DFC will not clear '
          'a broadcast with unlicensed music — takedown risk is too high.',
    ),

    // ── Event Insurance ──
    PromoterDocumentItem(
      id: 'event_insurance',
      title: 'Event Liability Insurance Certificate',
      description:
          'PROMOTER must supply certificate of currency for public liability '
          'insurance covering the live event. Minimum \$10M AUD coverage '
          'for combat sports. Must name Data Fight Central as an additional '
          'insured or interested party for the broadcast period. '
          'DFC is the distributor, not the event organiser — the promoter '
          'carries event-level liability.',
    ),

    // ── ACMA Declaration ──
    PromoterDocumentItem(
      id: 'acma_declaration',
      title: 'ACMA Compliance Declaration',
      description:
          'PROMOTER must confirm either: (a) an ACMA broadcasting licence '
          'number, or (b) exemption under Broadcasting Services Act '
          'Schedule 2 (internet-only content services). DFC provides a '
          'template statutory declaration for option (b). As a platform '
          'DFC distributes content — regulatory compliance is on the '
          'promoter/event organiser.',
    ),

    // ── ABN / Business Registration ──
    PromoterDocumentItem(
      id: 'abn_registration',
      title: 'Promoter ABN / Business Registration',
      description:
          'PROMOTER must provide their Australian Business Number (or '
          'international equivalent). Required for Stripe Connect '
          'onboarding and tax compliance. International promoters: '
          'provide equivalent tax ID (EIN for US, Company Number for '
          'UK, etc.). Separate from DFC\'s own ABN.',
    ),

    // ── Signed Licence Agreement ──
    PromoterDocumentItem(
      id: 'signed_licence',
      title: 'Signed DFC PPV Licence Agreement',
      description:
          'The executed licence agreement based on the term sheet. '
          'Both parties must sign before stream URL is provisioned. '
          'DFC will countersign within 48 hours of promoter signature.',
    ),

    // ── Event Poster / Key Art ──
    PromoterDocumentItem(
      id: 'event_poster',
      title: 'Event Poster / Key Art (High-Res)',
      description:
          'Minimum 1920x1080 PNG or JPEG, 300dpi for print. '
          'Used for PPV store listing, social media, email blasts, '
          'and DFC homepage feature. Must not contain unlicensed '
          'logos, watermarks, or third-party IP without clearance.',
    ),

    // ── Fight Card ──
    PromoterDocumentItem(
      id: 'fight_card',
      title: 'Complete Fight Card',
      description:
          'Full bout order with: fighter names, weight classes, '
          'fight type (title / main / co-main / prelim), '
          'number of rounds, rule set. Needed for PPV listing '
          'and predictions engine.',
    ),

    // ── Fighter Photos / Bios ──
    PromoterDocumentItem(
      id: 'fighter_assets',
      title: 'Fighter Photos & Bios',
      description:
          'Headshot photo (min 512x512) and short bio (50-100 words) '
          'for each fighter on the card. Used for PPV fight card display '
          'and social media promotion. Bios should include record, '
          'team, and fighting style.',
      priority: DocPriority.recommended,
    ),

    // ── Trailer / Promo Video ──
    PromoterDocumentItem(
      id: 'promo_video',
      title: 'Trailer / Promo Video',
      description:
          'Event hype trailer, 30-90 seconds, MP4 H.264 minimum 1080p. '
          'Used on PPV store page and social campaigns. '
          'Must own or licence all footage and music within.',
      priority: DocPriority.recommended,
    ),

    // ── Venue / Streaming Tech Info ──
    PromoterDocumentItem(
      id: 'venue_tech',
      title: 'Venue & Streaming Technical Sheet',
      description:
          'Venue name, address, internet bandwidth (min 20 Mbps up), '
          'camera setup (single / multi-cam), encoding hardware/software, '
          'backup stream plan. DFC provides an RTMP ingest endpoint '
          'and can advise on OBS/vMix settings.',
      priority: DocPriority.recommended,
    ),

    // ── Archival Footage Clearance ──
    PromoterDocumentItem(
      id: 'archival_clearance',
      title: 'Archival Footage Clearance',
      description:
          'If the broadcast includes replays, historical footage, '
          'or highlight reels from prior events, provide clearance '
          'documentation for each clip. Not needed if all footage '
          'is from the current event only.',
      priority: DocPriority.optional,
    ),

    // ── Logo / Trademark Licence ──
    PromoterDocumentItem(
      id: 'logo_trademark',
      title: 'Logo / Trademark Usage Licence',
      description:
          'Written permission to display sponsor logos, federation '
          'marks, or third-party brand imagery on the broadcast. '
          'Not needed for the promoter\'s own brand. Required if '
          'co-branding with sanctioning bodies (WBC, IBF, etc.).',
      priority: DocPriority.optional,
    ),

    // ── Tax Form ──
    PromoterDocumentItem(
      id: 'tax_form',
      title: 'Tax Declaration (W-8BEN / GST Registration)',
      description:
          'Australian promoters: GST registration status. '
          'International promoters: W-8BEN (for US tax treaty) '
          'or equivalent withholding declaration. Required before '
          'first payout is processed via Stripe Connect.',
    ),
  ];

  /// Generate a text checklist from a PpvLicenseModel, marking what's done.
  /// Shows both DFC platform status and promoter obligations.
  static String generateChecklist(PpvLicenseModel license) {
    final buf = StringBuffer();
    buf.writeln('═══════════════════════════════════════════════════════');
    buf.writeln('DFC PPV BROADCAST COMPLIANCE CHECKLIST');
    buf.writeln('═══════════════════════════════════════════════════════');
    buf.writeln('Promoter: ${license.licensorEntity}');
    buf.writeln('Event:    ${license.ppvEventId}');
    buf.writeln();
    buf.writeln('NOTE: DFC is a PLATFORM / DISTRIBUTOR. DFC does NOT');
    buf.writeln('run events. Promoters carry all event-level compliance.');
    buf.writeln('─' * 55);
    buf.writeln();

    // ── Section 1: DFC Platform Status ──
    buf.writeln('▶ DFC PLATFORM REQUIREMENTS (DFC\'s own docs)');
    buf.writeln('  These are DFC\'s responsibility, not the promoter\'s.');
    buf.writeln();
    for (final item in dfcPlatformDocs) {
      // DFC's own docs — mark all as done except trademark (in progress)
      final done = item.id != 'dfc_trademark';
      final icon = done ? '✓' : '⏳';
      final tag = switch (item.priority) {
        DocPriority.required => '[REQUIRED]',
        DocPriority.recommended => '[IN PROGRESS]',
        DocPriority.optional => '[OPTIONAL]',
      };
      buf.writeln('  $icon  $tag ${item.title}');
    }
    buf.writeln();
    buf.writeln('─' * 55);
    buf.writeln();

    // ── Section 2: Promoter Obligations ──
    buf.writeln('▶ PROMOTER OBLIGATIONS (promoter must supply these)');
    buf.writeln('  DFC collects these for liability protection before');
    buf.writeln(
      '  broadcast approval. All are the promoter\'s responsibility.',
    );
    buf.writeln();

    // Map of document IDs to their completed status from the license
    final statusMap = <String, bool>{
      'chain_of_title': license.chainOfTitleDocUrl != null,
      'talent_releases': license.talentReleasesObtained,
      'music_cue_sheet': license.musicCueSheet != null,
      'music_licence': license.musicRightsCleared,
      'event_insurance': license.eventInsuranceConfirmed,
      // cyber insurance removed from promoter obligations — it's DFC's platform-level concern
      'acma_declaration': license.regulatoryOk,
      'abn_registration': license.licensorAbn != null,
      'signed_licence': license.signedLicenseDocUrl != null,
      'event_poster': true, // Tracked separately in event model
      'fight_card': true, // Tracked separately in PPV model
      'fighter_assets': true, // Best effort
      'promo_video': true, // Optional
      'venue_tech': true, // Pre-event
      'archival_clearance': license.archivalFootageCleared,
      'logo_trademark': license.logosTrademarkCleared,
      'tax_form': true, // Tracked in Stripe Connect
    };

    for (final item in items) {
      final done = statusMap[item.id] ?? false;
      final icon = done ? '✓' : '✗';
      final tag = switch (item.priority) {
        DocPriority.required => '[REQUIRED]',
        DocPriority.recommended => '[RECOMMENDED]',
        DocPriority.optional => '[OPTIONAL]',
      };
      buf.writeln('  $icon  $tag ${item.title}');
      buf.writeln(
        '     ${item.description.substring(0, item.description.length.clamp(0, 80))}...',
      );
      buf.writeln();
    }

    // Summary
    final requiredItems = items.where(
      (i) => i.priority == DocPriority.required,
    );
    final requiredDone = requiredItems
        .where((i) => statusMap[i.id] == true)
        .length;
    buf.writeln('─' * 55);
    buf.writeln(
      'Promoter Required Docs: $requiredDone / ${requiredItems.length} complete',
    );
    buf.writeln(
      'Overall Readiness: ${(license.readinessScore * 100).toStringAsFixed(0)}%',
    );
    buf.writeln();
    buf.writeln(
      'DFC Platform Status: ABN ✓ | ToS ✓ | Privacy ✓ | Disclaimers ✓ | Trademark ⏳ | Cyber Ins ○',
    );

    return buf.toString();
  }
}
