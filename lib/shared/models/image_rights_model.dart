import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Who owns the image
enum ImageOwnerType { dfc, promoter, fighter, org, stock, cc }

/// What license covers its use
enum ImageLicenseType { owned, promoUse, stock, cc, editorial }

/// Current moderation state — drives the entire approval gate
enum ImageApprovalStatus {
  pending, // Uploaded, awaiting admin review
  approved, // Cleared for public feeds, ads, social
  rejected, // Denied — never served publicly
  revoked, // Was approved, pulled via takedown/dispute
  expired, // License window ended — auto-gated
}

/// Where is this image allowed to appear
enum ImageUsageScope {
  feed, // Feed cards, article headers
  ads, // Paid advertising, social boost
  social, // DFC social channels, shares
  email, // Email campaigns, newsletters
  ppv, // PPV event pages and promotions
  editorial, // DFC editorial / news articles
  internal, // Admin-only, not public
}

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC IMAGE RIGHTS MODEL — Production-Grade Media Provenance
///
/// RULE: No image reaches a public surface unless status == approved.
/// Every image carries a full legal chain: who uploaded it, what attestation
/// they signed, who approved it, and an immutable audit trail ID.
///
/// Designed to make promoters trust the platform and protect DFC from
/// copyright claims, DMCA takedowns, and licensing disputes.
/// ═══════════════════════════════════════════════════════════════════════════
class ImageRightsModel extends Equatable {
  // ── Identity ────────────────────────────────────────────────────────────
  final String id;
  final String url;
  final String? storagePath; // Firebase Storage path for deletion
  final String? thumbnailUrl; // 300px thumbnail for admin previews
  final String fileName;
  final int? fileSizeBytes;
  final int? widthPx;
  final int? heightPx;
  final String? mimeType;

  // ── Ownership & Licensing ───────────────────────────────────────────────
  final ImageOwnerType ownerType;
  final String ownerName;
  final String ownerEmail;
  final ImageLicenseType licenseType;
  final String? licenseNotes;
  final DateTime? licenseExpiresAt; // null = perpetual
  final List<ImageUsageScope> allowedScopes;

  // ── Attestation (legal chain of custody) ────────────────────────────────
  final String attestationText; // Exact text the uploader agreed to
  final bool attestationSigned; // Must be true or upload is rejected
  final DateTime? attestationSignedAt;
  final String? attestationIp; // IP at time of upload (audit)

  // ── Provenance Links ────────────────────────────────────────────────────
  final String? sourceEventId;
  final String? sourceFighterId;
  final String? sourcePromotionId;
  final String? sourceArticleId;
  final List<String> tags;

  // ── Approval Pipeline ───────────────────────────────────────────────────
  final ImageApprovalStatus status;
  final String? approvedBy; // Admin UID who approved
  final DateTime? approvedAt;
  final String? rejectedBy;
  final DateTime? rejectedAt;
  final String? rejectionReason;

  // ── Takedown / Dispute ──────────────────────────────────────────────────
  final bool isTakenDown;
  final String? takedownReason;
  final DateTime? takenDownAt;
  final String? takedownRequestedBy; // Email of complainant
  final String? disputeId; // Links to image_disputes collection

  // ── Audit ───────────────────────────────────────────────────────────────
  final String uploadedBy; // UID of the uploader
  final String? auditLogId; // Immutable audit trail reference
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Usage Tracking ──────────────────────────────────────────────────────
  final int usageCount; // How many surfaces reference this image
  final List<String> usedInArticleIds;
  final List<String> usedInAdIds;

  const ImageRightsModel({
    required this.id,
    required this.url,
    this.storagePath,
    this.thumbnailUrl,
    this.fileName = '',
    this.fileSizeBytes,
    this.widthPx,
    this.heightPx,
    this.mimeType,
    required this.ownerType,
    required this.ownerName,
    this.ownerEmail = '',
    required this.licenseType,
    this.licenseNotes,
    this.licenseExpiresAt,
    this.allowedScopes = const [
      ImageUsageScope.feed,
      ImageUsageScope.social,
      ImageUsageScope.editorial,
    ],
    this.attestationText = '',
    this.attestationSigned = false,
    this.attestationSignedAt,
    this.attestationIp,
    this.sourceEventId,
    this.sourceFighterId,
    this.sourcePromotionId,
    this.sourceArticleId,
    this.tags = const [],
    this.status = ImageApprovalStatus.pending,
    this.approvedBy,
    this.approvedAt,
    this.rejectedBy,
    this.rejectedAt,
    this.rejectionReason,
    this.isTakenDown = false,
    this.takedownReason,
    this.takenDownAt,
    this.takedownRequestedBy,
    this.disputeId,
    required this.uploadedBy,
    this.auditLogId,
    required this.createdAt,
    required this.updatedAt,
    this.usageCount = 0,
    this.usedInArticleIds = const [],
    this.usedInAdIds = const [],
  });

  // ── Gate checks ─────────────────────────────────────────────────────────

  /// The ONE check every surface must call before showing this image.
  bool get isPublicReady =>
      status == ImageApprovalStatus.approved && !isTakenDown && !isExpired;

  bool get isExpired =>
      licenseExpiresAt != null && DateTime.now().isAfter(licenseExpiresAt!);

  bool get isPending => status == ImageApprovalStatus.pending;
  bool get isRejected => status == ImageApprovalStatus.rejected;
  bool get isRevoked => status == ImageApprovalStatus.revoked;

  bool canAppearIn(ImageUsageScope scope) =>
      isPublicReady && allowedScopes.contains(scope);

  @override
  List<Object?> get props => [id, url, ownerType, licenseType, status];

  // ── Attestation Templates ───────────────────────────────────────────────

  static const String uploaderAttestationText =
      'I confirm I own the rights to this image or I am authorised by the '
      'rights holder to grant DFC permission to use this image for promotion '
      'across the DFC website, social channels, email, and paid advertising. '
      'I understand DFC will rely on this attestation and I accept '
      'responsibility for any claims arising from misuse.';

  static const String promoterPermissionText =
      'By uploading this media to DFC I grant Data Fight Central a '
      'non-exclusive, worldwide, royalty-free license to use, reproduce, '
      'display, and distribute these assets for promotional purposes related '
      'to the event(s) listed. I confirm I have authority to grant this license.';

  // ── Firestore Serialization ─────────────────────────────────────────────

  factory ImageRightsModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    return ImageRightsModel(
      id: doc.id,
      url: (d['url'] ?? '').toString(),
      storagePath: d['storagePath']?.toString(),
      thumbnailUrl: d['thumbnailUrl']?.toString(),
      fileName: (d['fileName'] ?? '').toString(),
      fileSizeBytes: d['fileSizeBytes'] as int?,
      widthPx: d['widthPx'] as int?,
      heightPx: d['heightPx'] as int?,
      mimeType: d['mimeType']?.toString(),
      ownerType: _ownerTypeFromString(d['ownerType']?.toString()),
      ownerName: (d['ownerName'] ?? '').toString(),
      ownerEmail: (d['ownerEmail'] ?? '').toString(),
      licenseType: _licenseFromString(d['licenseType']?.toString()),
      licenseNotes: d['licenseNotes']?.toString(),
      licenseExpiresAt: _toDate(d['licenseExpiresAt']),
      allowedScopes: _scopesFromList(d['allowedScopes']),
      attestationText: (d['attestationText'] ?? '').toString(),
      attestationSigned: d['attestationSigned'] as bool? ?? false,
      attestationSignedAt: _toDate(d['attestationSignedAt']),
      attestationIp: d['attestationIp']?.toString(),
      sourceEventId: d['sourceEventId']?.toString(),
      sourceFighterId: d['sourceFighterId']?.toString(),
      sourcePromotionId: d['sourcePromotionId']?.toString(),
      sourceArticleId: d['sourceArticleId']?.toString(),
      tags: List<String>.from(d['tags'] ?? []),
      status: _statusFromString(d['status']?.toString()),
      approvedBy: d['approvedBy']?.toString(),
      approvedAt: _toDate(d['approvedAt']),
      rejectedBy: d['rejectedBy']?.toString(),
      rejectedAt: _toDate(d['rejectedAt']),
      rejectionReason: d['rejectionReason']?.toString(),
      isTakenDown: d['isTakenDown'] as bool? ?? false,
      takedownReason: d['takedownReason']?.toString(),
      takenDownAt: _toDate(d['takenDownAt']),
      takedownRequestedBy: d['takedownRequestedBy']?.toString(),
      disputeId: d['disputeId']?.toString(),
      uploadedBy: (d['uploadedBy'] ?? '').toString(),
      auditLogId: d['auditLogId']?.toString(),
      createdAt: _toDate(d['createdAt']) ?? DateTime.now(),
      updatedAt: _toDate(d['updatedAt']) ?? DateTime.now(),
      usageCount: d['usageCount'] as int? ?? 0,
      usedInArticleIds: List<String>.from(d['usedInArticleIds'] ?? []),
      usedInAdIds: List<String>.from(d['usedInAdIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'url': url,
      'storagePath': storagePath,
      'thumbnailUrl': thumbnailUrl,
      'fileName': fileName,
      'fileSizeBytes': fileSizeBytes,
      'widthPx': widthPx,
      'heightPx': heightPx,
      'mimeType': mimeType,
      'ownerType': ownerType.name,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'licenseType': licenseType.name,
      'licenseNotes': licenseNotes,
      'licenseExpiresAt': _toTimestamp(licenseExpiresAt),
      'allowedScopes': allowedScopes.map((s) => s.name).toList(),
      'attestationText': attestationText,
      'attestationSigned': attestationSigned,
      'attestationSignedAt': _toTimestamp(attestationSignedAt),
      'attestationIp': attestationIp,
      'sourceEventId': sourceEventId,
      'sourceFighterId': sourceFighterId,
      'sourcePromotionId': sourcePromotionId,
      'sourceArticleId': sourceArticleId,
      'tags': tags,
      'status': status.name,
      'approvedBy': approvedBy,
      'approvedAt': _toTimestamp(approvedAt),
      'rejectedBy': rejectedBy,
      'rejectedAt': _toTimestamp(rejectedAt),
      'rejectionReason': rejectionReason,
      'isTakenDown': isTakenDown,
      'takedownReason': takedownReason,
      'takenDownAt': _toTimestamp(takenDownAt),
      'takedownRequestedBy': takedownRequestedBy,
      'disputeId': disputeId,
      'uploadedBy': uploadedBy,
      'auditLogId': auditLogId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'usageCount': usageCount,
      'usedInArticleIds': usedInArticleIds,
      'usedInAdIds': usedInAdIds,
    };
  }

  ImageRightsModel copyWith({
    String? id,
    String? url,
    String? storagePath,
    String? thumbnailUrl,
    String? fileName,
    int? fileSizeBytes,
    int? widthPx,
    int? heightPx,
    String? mimeType,
    ImageOwnerType? ownerType,
    String? ownerName,
    String? ownerEmail,
    ImageLicenseType? licenseType,
    String? licenseNotes,
    DateTime? licenseExpiresAt,
    List<ImageUsageScope>? allowedScopes,
    String? attestationText,
    bool? attestationSigned,
    DateTime? attestationSignedAt,
    String? attestationIp,
    String? sourceEventId,
    String? sourceFighterId,
    String? sourcePromotionId,
    String? sourceArticleId,
    List<String>? tags,
    ImageApprovalStatus? status,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectedBy,
    DateTime? rejectedAt,
    String? rejectionReason,
    bool? isTakenDown,
    String? takedownReason,
    DateTime? takenDownAt,
    String? takedownRequestedBy,
    String? disputeId,
    String? uploadedBy,
    String? auditLogId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? usageCount,
    List<String>? usedInArticleIds,
    List<String>? usedInAdIds,
  }) {
    return ImageRightsModel(
      id: id ?? this.id,
      url: url ?? this.url,
      storagePath: storagePath ?? this.storagePath,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      widthPx: widthPx ?? this.widthPx,
      heightPx: heightPx ?? this.heightPx,
      mimeType: mimeType ?? this.mimeType,
      ownerType: ownerType ?? this.ownerType,
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      licenseType: licenseType ?? this.licenseType,
      licenseNotes: licenseNotes ?? this.licenseNotes,
      licenseExpiresAt: licenseExpiresAt ?? this.licenseExpiresAt,
      allowedScopes: allowedScopes ?? this.allowedScopes,
      attestationText: attestationText ?? this.attestationText,
      attestationSigned: attestationSigned ?? this.attestationSigned,
      attestationSignedAt: attestationSignedAt ?? this.attestationSignedAt,
      attestationIp: attestationIp ?? this.attestationIp,
      sourceEventId: sourceEventId ?? this.sourceEventId,
      sourceFighterId: sourceFighterId ?? this.sourceFighterId,
      sourcePromotionId: sourcePromotionId ?? this.sourcePromotionId,
      sourceArticleId: sourceArticleId ?? this.sourceArticleId,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isTakenDown: isTakenDown ?? this.isTakenDown,
      takedownReason: takedownReason ?? this.takedownReason,
      takenDownAt: takenDownAt ?? this.takenDownAt,
      takedownRequestedBy: takedownRequestedBy ?? this.takedownRequestedBy,
      disputeId: disputeId ?? this.disputeId,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      auditLogId: auditLogId ?? this.auditLogId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      usageCount: usageCount ?? this.usageCount,
      usedInArticleIds: usedInArticleIds ?? this.usedInArticleIds,
      usedInAdIds: usedInAdIds ?? this.usedInAdIds,
    );
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  static DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static Timestamp? _toTimestamp(DateTime? dt) =>
      dt != null ? Timestamp.fromDate(dt) : null;

  static ImageOwnerType _ownerTypeFromString(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'promoter':
        return ImageOwnerType.promoter;
      case 'fighter':
        return ImageOwnerType.fighter;
      case 'org':
        return ImageOwnerType.org;
      case 'stock':
        return ImageOwnerType.stock;
      case 'cc':
        return ImageOwnerType.cc;
      default:
        return ImageOwnerType.dfc;
    }
  }

  static ImageLicenseType _licenseFromString(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'promo_use':
      case 'promouse':
        return ImageLicenseType.promoUse;
      case 'stock':
        return ImageLicenseType.stock;
      case 'cc':
        return ImageLicenseType.cc;
      case 'editorial':
        return ImageLicenseType.editorial;
      default:
        return ImageLicenseType.owned;
    }
  }

  static ImageApprovalStatus _statusFromString(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'approved':
        return ImageApprovalStatus.approved;
      case 'rejected':
        return ImageApprovalStatus.rejected;
      case 'revoked':
        return ImageApprovalStatus.revoked;
      case 'expired':
        return ImageApprovalStatus.expired;
      default:
        return ImageApprovalStatus.pending;
    }
  }

  static List<ImageUsageScope> _scopesFromList(dynamic v) {
    if (v is! List) {
      return [
        ImageUsageScope.feed,
        ImageUsageScope.social,
        ImageUsageScope.editorial,
      ];
    }
    return v.map<ImageUsageScope>((e) {
      switch (e.toString().toLowerCase()) {
        case 'ads':
          return ImageUsageScope.ads;
        case 'social':
          return ImageUsageScope.social;
        case 'email':
          return ImageUsageScope.email;
        case 'ppv':
          return ImageUsageScope.ppv;
        case 'editorial':
          return ImageUsageScope.editorial;
        case 'internal':
          return ImageUsageScope.internal;
        default:
          return ImageUsageScope.feed;
      }
    }).toList();
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// IMAGE TAKEDOWN REQUEST — When someone claims copyright infringement
/// ═══════════════════════════════════════════════════════════════════════════
enum TakedownStatus { received, investigating, upheld, dismissed, restored }

class ImageTakedownModel extends Equatable {
  final String id;
  final String imageId;
  final String complainantName;
  final String complainantEmail;
  final String reason;
  final String? evidenceUrl;
  final TakedownStatus status;
  final String? investigatorId;
  final String? resolution;
  final DateTime receivedAt;
  final DateTime? resolvedAt;

  const ImageTakedownModel({
    required this.id,
    required this.imageId,
    required this.complainantName,
    required this.complainantEmail,
    required this.reason,
    this.evidenceUrl,
    this.status = TakedownStatus.received,
    this.investigatorId,
    this.resolution,
    required this.receivedAt,
    this.resolvedAt,
  });

  @override
  List<Object?> get props => [id, imageId, status];

  factory ImageTakedownModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ImageTakedownModel(
      id: doc.id,
      imageId: (d['imageId'] ?? '').toString(),
      complainantName: (d['complainantName'] ?? '').toString(),
      complainantEmail: (d['complainantEmail'] ?? '').toString(),
      reason: (d['reason'] ?? '').toString(),
      evidenceUrl: d['evidenceUrl']?.toString(),
      status: _statusFromString(d['status']?.toString()),
      investigatorId: d['investigatorId']?.toString(),
      resolution: d['resolution']?.toString(),
      receivedAt: ImageRightsModel._toDate(d['receivedAt']) ?? DateTime.now(),
      resolvedAt: ImageRightsModel._toDate(d['resolvedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'imageId': imageId,
      'complainantName': complainantName,
      'complainantEmail': complainantEmail,
      'reason': reason,
      'evidenceUrl': evidenceUrl,
      'status': status.name,
      'investigatorId': investigatorId,
      'resolution': resolution,
      'receivedAt': Timestamp.fromDate(receivedAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }

  static TakedownStatus _statusFromString(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'investigating':
        return TakedownStatus.investigating;
      case 'upheld':
        return TakedownStatus.upheld;
      case 'dismissed':
        return TakedownStatus.dismissed;
      case 'restored':
        return TakedownStatus.restored;
      default:
        return TakedownStatus.received;
    }
  }
}
