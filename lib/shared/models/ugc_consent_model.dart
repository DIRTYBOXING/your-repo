import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// License scope determining how UGC content may be used on DFC.
enum UgcLicenseScope {
  /// Organic feed only — no paid amplification
  organic,

  /// May be used in paid promotions (boosted reach)
  paid,

  /// May be used in paid ads (targeted delivery + promoter spend)
  ads,

  /// Full commercial license (organic + paid + ads + derivatives)
  commercial,
}

/// Status of a UGC consent record through its lifecycle.
enum UgcConsentStatus {
  /// Awaiting double opt-in confirmation email
  pendingConfirmation,

  /// Active and valid consent
  active,

  /// User revoked consent — content must be de-promoted
  revoked,

  /// Consent expired (past expiry_ts)
  expired,

  /// Admin or takedown request invalidated this consent
  invalidated,
}

/// Immutable UGC consent & rights record.
///
/// Stored in Firestore `ugc_consents/{consentId}`.
/// Every content submission that may be promoted or monetized must
/// have an active consent record.  Consent is scoped, versioned,
/// time-bounded, and fully auditable.
class UgcConsentModel extends Equatable {
  /// Firestore document ID
  final String id;

  /// DFC user ID of the content owner / uploader
  final String userId;

  /// Display name at time of consent (for audit trail)
  final String uploaderName;

  /// Email for double opt-in confirmation
  final String email;

  /// The content this consent covers (post / media)
  final String contentId;

  /// Direct URL to the media asset (image, video, audio)
  final String? mediaUrl;

  /// What the content may be used for
  final UgcLicenseScope licenseScope;

  /// Compensation description (e.g., 'none', 'rev-share 30%', '$50 flat')
  final String compensation;

  /// Current lifecycle status
  final UgcConsentStatus status;

  /// When consent becomes effective
  final DateTime startTs;

  /// When consent automatically expires (null = indefinite)
  final DateTime? expiryTs;

  /// Cryptographic token linking consent to confirmation email
  final String consentToken;

  /// IP address at time of consent grant (audit / provenance)
  final String? ipAddress;

  /// Timestamp of the digital signature / confirmation click
  final DateTime? signatureTs;

  /// Version of the UGC Submission Agreement the user consented to
  final String agreementVersion;

  /// Whether this consent may be used for brain-signal-targeted promotions
  final bool allowsNeuralTargeting;

  /// Free-form metadata (e.g., campaign tags, pilot info)
  final Map<String, dynamic>? metadata;

  final DateTime createdAt;
  final DateTime updatedAt;

  const UgcConsentModel({
    required this.id,
    required this.userId,
    required this.uploaderName,
    required this.email,
    required this.contentId,
    this.mediaUrl,
    required this.licenseScope,
    this.compensation = 'none',
    this.status = UgcConsentStatus.pendingConfirmation,
    required this.startTs,
    this.expiryTs,
    required this.consentToken,
    this.ipAddress,
    this.signatureTs,
    this.agreementVersion = '1.0',
    this.allowsNeuralTargeting = false,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Is this consent currently valid for use?
  bool get isActive {
    if (status != UgcConsentStatus.active) return false;
    if (expiryTs != null && DateTime.now().isAfter(expiryTs!)) return false;
    return true;
  }

  /// Can content be used in paid promotions?
  bool get allowsPaidPromotion =>
      isActive &&
      (licenseScope == UgcLicenseScope.paid ||
          licenseScope == UgcLicenseScope.ads ||
          licenseScope == UgcLicenseScope.commercial);

  /// Can content be used in targeted ad campaigns?
  bool get allowsAdCampaigns =>
      isActive &&
      (licenseScope == UgcLicenseScope.ads ||
          licenseScope == UgcLicenseScope.commercial);

  // ── Firestore serialization ──────────────────────────────────────

  factory UgcConsentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return UgcConsentModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      uploaderName: d['uploaderName'] ?? '',
      email: d['email'] ?? '',
      contentId: d['contentId'] ?? '',
      mediaUrl: d['mediaUrl'],
      licenseScope: UgcLicenseScope.values.firstWhere(
        (e) => e.name == d['licenseScope'],
        orElse: () => UgcLicenseScope.organic,
      ),
      compensation: d['compensation'] ?? 'none',
      status: UgcConsentStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => UgcConsentStatus.pendingConfirmation,
      ),
      startTs: (d['startTs'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryTs: (d['expiryTs'] as Timestamp?)?.toDate(),
      consentToken: d['consentToken'] ?? '',
      ipAddress: d['ipAddress'],
      signatureTs: (d['signatureTs'] as Timestamp?)?.toDate(),
      agreementVersion: d['agreementVersion'] ?? '1.0',
      allowsNeuralTargeting: d['allowsNeuralTargeting'] ?? false,
      metadata: d['metadata'] as Map<String, dynamic>?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'uploaderName': uploaderName,
    'email': email,
    'contentId': contentId,
    if (mediaUrl != null) 'mediaUrl': mediaUrl,
    'licenseScope': licenseScope.name,
    'compensation': compensation,
    'status': status.name,
    'startTs': Timestamp.fromDate(startTs),
    if (expiryTs != null) 'expiryTs': Timestamp.fromDate(expiryTs!),
    'consentToken': consentToken,
    if (ipAddress != null) 'ipAddress': ipAddress,
    if (signatureTs != null) 'signatureTs': Timestamp.fromDate(signatureTs!),
    'agreementVersion': agreementVersion,
    'allowsNeuralTargeting': allowsNeuralTargeting,
    if (metadata != null) 'metadata': metadata,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  UgcConsentModel copyWith({
    String? id,
    String? userId,
    String? uploaderName,
    String? email,
    String? contentId,
    String? mediaUrl,
    UgcLicenseScope? licenseScope,
    String? compensation,
    UgcConsentStatus? status,
    DateTime? startTs,
    DateTime? expiryTs,
    String? consentToken,
    String? ipAddress,
    DateTime? signatureTs,
    String? agreementVersion,
    bool? allowsNeuralTargeting,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UgcConsentModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    uploaderName: uploaderName ?? this.uploaderName,
    email: email ?? this.email,
    contentId: contentId ?? this.contentId,
    mediaUrl: mediaUrl ?? this.mediaUrl,
    licenseScope: licenseScope ?? this.licenseScope,
    compensation: compensation ?? this.compensation,
    status: status ?? this.status,
    startTs: startTs ?? this.startTs,
    expiryTs: expiryTs ?? this.expiryTs,
    consentToken: consentToken ?? this.consentToken,
    ipAddress: ipAddress ?? this.ipAddress,
    signatureTs: signatureTs ?? this.signatureTs,
    agreementVersion: agreementVersion ?? this.agreementVersion,
    allowsNeuralTargeting: allowsNeuralTargeting ?? this.allowsNeuralTargeting,
    metadata: metadata ?? this.metadata,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    userId,
    contentId,
    licenseScope,
    status,
    consentToken,
  ];
}
