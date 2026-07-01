import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Consent type enumeration
enum ConsentType {
  termsOfService,
  privacyPolicy,
  dataProcessing,
  marketingEmails,
  pushNotifications,
  analyticsTracking,
  thirdPartySharing,
  medicalDisclosure,
  mediaRelease,
  combatSportsRisk,

  /// EEG / brain-signal data collection from wearables
  eegDataCollection,

  /// Brain-derived signals used for personalized feed ranking
  neuralFeedPersonalization,

  /// Brain-signal data used for paid promotion targeting
  neuralPromotionTargeting,

  /// Brain-signal data shared with researchers / analytics
  neuralResearchAnalytics,

  /// UGC content submitted for paid promotion on DFC
  ugcPaidPromotion,
}

/// Consent model for GDPR and Australian Privacy Principles compliance
class ConsentModel extends Equatable {
  final String id;
  final String userId;
  final ConsentType consentType;
  final bool isGranted;
  final String version; // Document version consented to
  final String? ipAddress;
  final String? userAgent;
  final String? deviceId;
  final Map<String, dynamic>? metadata;
  final DateTime grantedAt;
  final DateTime? revokedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConsentModel({
    required this.id,
    required this.userId,
    required this.consentType,
    required this.isGranted,
    required this.version,
    this.ipAddress,
    this.userAgent,
    this.deviceId,
    this.metadata,
    required this.grantedAt,
    this.revokedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Is consent currently active
  bool get isActive => isGranted && revokedAt == null;

  /// Display name for consent type
  String get displayName {
    switch (consentType) {
      case ConsentType.termsOfService:
        return 'Terms of Service';
      case ConsentType.privacyPolicy:
        return 'Privacy Policy';
      case ConsentType.dataProcessing:
        return 'Data Processing';
      case ConsentType.marketingEmails:
        return 'Marketing Emails';
      case ConsentType.pushNotifications:
        return 'Push Notifications';
      case ConsentType.analyticsTracking:
        return 'Analytics Tracking';
      case ConsentType.thirdPartySharing:
        return 'Third Party Sharing';
      case ConsentType.medicalDisclosure:
        return 'Medical Disclosure';
      case ConsentType.mediaRelease:
        return 'Media Release';
      case ConsentType.combatSportsRisk:
        return 'Combat Sports Risk Acknowledgement';
      case ConsentType.eegDataCollection:
        return 'EEG / Brain-Signal Data Collection';
      case ConsentType.neuralFeedPersonalization:
        return 'Neural Feed Personalization';
      case ConsentType.neuralPromotionTargeting:
        return 'Neural Promotion Targeting';
      case ConsentType.neuralResearchAnalytics:
        return 'Neural Research & Analytics';
      case ConsentType.ugcPaidPromotion:
        return 'UGC Paid Promotion';
    }
  }

  factory ConsentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConsentModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      consentType: ConsentType.values.firstWhere(
        (t) => t.name == data['consentType'],
        orElse: () => ConsentType.termsOfService,
      ),
      isGranted: data['isGranted'] ?? false,
      version: data['version'] ?? '1.0',
      ipAddress: data['ipAddress'],
      userAgent: data['userAgent'],
      deviceId: data['deviceId'],
      metadata: data['metadata'],
      grantedAt: (data['grantedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      revokedAt: (data['revokedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'consentType': consentType.name,
      'isGranted': isGranted,
      'version': version,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'deviceId': deviceId,
      'metadata': metadata,
      'grantedAt': Timestamp.fromDate(grantedAt),
      'revokedAt': revokedAt != null ? Timestamp.fromDate(revokedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ConsentModel copyWith({
    String? id,
    String? userId,
    ConsentType? consentType,
    bool? isGranted,
    String? version,
    String? ipAddress,
    String? userAgent,
    String? deviceId,
    Map<String, dynamic>? metadata,
    DateTime? grantedAt,
    DateTime? revokedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConsentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      consentType: consentType ?? this.consentType,
      isGranted: isGranted ?? this.isGranted,
      version: version ?? this.version,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      deviceId: deviceId ?? this.deviceId,
      metadata: metadata ?? this.metadata,
      grantedAt: grantedAt ?? this.grantedAt,
      revokedAt: revokedAt ?? this.revokedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, consentType, isGranted, version];
}

/// Data export request model for GDPR data portability
class DataExportRequestModel extends Equatable {
  final String id;
  final String userId;
  final String status; // pending, processing, completed, failed, expired
  final String format; // json, csv
  final List<String> dataCategories; // profile, posts, comments, etc.
  final String? downloadUrl;
  final DateTime? expiresAt;
  final String? errorMessage;
  final DateTime requestedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DataExportRequestModel({
    required this.id,
    required this.userId,
    this.status = 'pending',
    this.format = 'json',
    this.dataCategories = const [],
    this.downloadUrl,
    this.expiresAt,
    this.errorMessage,
    required this.requestedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Is download available
  bool get isDownloadAvailable {
    if (status != 'completed' || downloadUrl == null) return false;
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }

  factory DataExportRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DataExportRequestModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      status: data['status'] ?? 'pending',
      format: data['format'] ?? 'json',
      dataCategories: List<String>.from(data['dataCategories'] ?? []),
      downloadUrl: data['downloadUrl'],
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      errorMessage: data['errorMessage'],
      requestedAt:
          (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'status': status,
      'format': format,
      'dataCategories': dataCategories,
      'downloadUrl': downloadUrl,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'errorMessage': errorMessage,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  List<Object?> get props => [id, userId, status, format];
}

/// Data deletion request model for GDPR right to erasure
class DataDeletionRequestModel extends Equatable {
  final String id;
  final String userId;
  final String status; // pending, processing, completed, failed
  final String reason;
  final bool deleteAllData;
  final List<String> dataCategoriesToDelete;
  final String? verificationCode;
  final bool isVerified;
  final DateTime? verifiedAt;
  final DateTime? scheduledDeletionDate;
  final DateTime? completedAt;
  final String? errorMessage;
  final DateTime requestedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DataDeletionRequestModel({
    required this.id,
    required this.userId,
    this.status = 'pending',
    required this.reason,
    this.deleteAllData = true,
    this.dataCategoriesToDelete = const [],
    this.verificationCode,
    this.isVerified = false,
    this.verifiedAt,
    this.scheduledDeletionDate,
    this.completedAt,
    this.errorMessage,
    required this.requestedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DataDeletionRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DataDeletionRequestModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      status: data['status'] ?? 'pending',
      reason: data['reason'] ?? '',
      deleteAllData: data['deleteAllData'] ?? true,
      dataCategoriesToDelete: List<String>.from(
        data['dataCategoriesToDelete'] ?? [],
      ),
      verificationCode: data['verificationCode'],
      isVerified: data['isVerified'] ?? false,
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
      scheduledDeletionDate: (data['scheduledDeletionDate'] as Timestamp?)
          ?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      errorMessage: data['errorMessage'],
      requestedAt:
          (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'status': status,
      'reason': reason,
      'deleteAllData': deleteAllData,
      'dataCategoriesToDelete': dataCategoriesToDelete,
      'verificationCode': verificationCode,
      'isVerified': isVerified,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'scheduledDeletionDate': scheduledDeletionDate != null
          ? Timestamp.fromDate(scheduledDeletionDate!)
          : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'errorMessage': errorMessage,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  List<Object?> get props => [id, userId, status, deleteAllData];
}
