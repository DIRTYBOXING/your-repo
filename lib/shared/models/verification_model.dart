import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Verification status
enum VerificationStatus { pending, approved, rejected, expired }

/// Verification type
enum VerificationType {
  identity,
  fighter,
  coach,
  gym,
  promoter,
  sponsor,
  medical,
  insurance,
}

/// Verification model for verifying user identities and roles
class VerificationModel extends Equatable {
  final String id;
  final String userId;
  final VerificationType verificationType;
  final VerificationStatus status;
  final List<String> documentUrls;
  final String? documentType; // passport, license, certificate, etc.
  final Map<String, dynamic>? extractedData;
  final String? rejectionReason;
  final String? notes;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? expiresAt;
  final int attemptCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VerificationModel({
    required this.id,
    required this.userId,
    required this.verificationType,
    this.status = VerificationStatus.pending,
    this.documentUrls = const [],
    this.documentType,
    this.extractedData,
    this.rejectionReason,
    this.notes,
    this.reviewedBy,
    this.reviewedAt,
    this.expiresAt,
    this.attemptCount = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Is verification currently valid
  bool get isValid {
    if (status != VerificationStatus.approved) return false;
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }

  /// Display name for verification type
  String get displayName {
    switch (verificationType) {
      case VerificationType.identity:
        return 'Identity Verification';
      case VerificationType.fighter:
        return 'Fighter Verification';
      case VerificationType.coach:
        return 'Coach Certification';
      case VerificationType.gym:
        return 'Gym Registration';
      case VerificationType.promoter:
        return 'Promoter License';
      case VerificationType.sponsor:
        return 'Business Verification';
      case VerificationType.medical:
        return 'Medical Clearance';
      case VerificationType.insurance:
        return 'Insurance Verification';
    }
  }

  factory VerificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VerificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      verificationType: VerificationType.values.firstWhere(
        (t) => t.name == data['verificationType'],
        orElse: () => VerificationType.identity,
      ),
      status: VerificationStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => VerificationStatus.pending,
      ),
      documentUrls: List<String>.from(data['documentUrls'] ?? []),
      documentType: data['documentType'],
      extractedData: data['extractedData'],
      rejectionReason: data['rejectionReason'],
      notes: data['notes'],
      reviewedBy: data['reviewedBy'],
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      attemptCount: data['attemptCount'] ?? 1,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'verificationType': verificationType.name,
      'status': status.name,
      'documentUrls': documentUrls,
      'documentType': documentType,
      'extractedData': extractedData,
      'rejectionReason': rejectionReason,
      'notes': notes,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'attemptCount': attemptCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  VerificationModel copyWith({
    String? id,
    String? userId,
    VerificationType? verificationType,
    VerificationStatus? status,
    List<String>? documentUrls,
    String? documentType,
    Map<String, dynamic>? extractedData,
    String? rejectionReason,
    String? notes,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? expiresAt,
    int? attemptCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VerificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      verificationType: verificationType ?? this.verificationType,
      status: status ?? this.status,
      documentUrls: documentUrls ?? this.documentUrls,
      documentType: documentType ?? this.documentType,
      extractedData: extractedData ?? this.extractedData,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      notes: notes ?? this.notes,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      attemptCount: attemptCount ?? this.attemptCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, verificationType, status];
}

/// Audit log model for tracking important actions
class AuditLogModel extends Equatable {
  final String id;
  final String userId;
  final String action; // e.g., login, logout, profile_update, consent_change
  final String entityType; // user, fighter, event, etc.
  final String? entityId;
  final Map<String, dynamic>? previousData;
  final Map<String, dynamic>? newData;
  final String? ipAddress;
  final String? userAgent;
  final String? deviceId;
  final String? sessionId;
  final bool isSuccessful;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const AuditLogModel({
    required this.id,
    required this.userId,
    required this.action,
    required this.entityType,
    this.entityId,
    this.previousData,
    this.newData,
    this.ipAddress,
    this.userAgent,
    this.deviceId,
    this.sessionId,
    this.isSuccessful = true,
    this.errorMessage,
    this.metadata,
    required this.createdAt,
  });

  factory AuditLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLogModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      action: data['action'] ?? '',
      entityType: data['entityType'] ?? '',
      entityId: data['entityId'],
      previousData: data['previousData'],
      newData: data['newData'],
      ipAddress: data['ipAddress'],
      userAgent: data['userAgent'],
      deviceId: data['deviceId'],
      sessionId: data['sessionId'],
      isSuccessful: data['isSuccessful'] ?? true,
      errorMessage: data['errorMessage'],
      metadata: data['metadata'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'previousData': previousData,
      'newData': newData,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'deviceId': deviceId,
      'sessionId': sessionId,
      'isSuccessful': isSuccessful,
      'errorMessage': errorMessage,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [id, userId, action, entityType, createdAt];
}
