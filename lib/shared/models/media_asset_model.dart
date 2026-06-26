import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum MediaAssetKind {
  poster,
  banner,
  fighterPhoto,
  replay,
  highlight,
  gymPhoto,
  profilePhoto,
  story,
  postMedia,
  genericImage,
  genericVideo,
}

enum MediaAssetType { image, video }

enum MediaRightsType { owned, licensed, permissioned, editorial }

enum MediaApprovalStatus { pendingReview, approved, rejected, quarantined }

enum MediaSafetyStatus { pending, cleared, flagged, blocked }

class MediaAssetModel extends Equatable {
  final String id;
  final String uploaderId;
  final String? uploaderRole;
  final String? eventId;
  final String entityType;
  final String entityId;
  final MediaAssetKind kind;
  final MediaAssetType mediaType;
  final String downloadUrl;
  final String storagePath;
  final String fileName;
  final String fileType;
  final int fileSizeBytes;
  final int? width;
  final int? height;
  final double? aspectRatio;
  final String rightsOwner;
  final MediaRightsType rightsType;
  final String rightsDeclaration;
  final String hashMd5;
  final String hashSha256;
  final MediaApprovalStatus approvalStatus;
  final MediaSafetyStatus safetyStatus;
  final bool approved;
  final String? approvedBy;
  final DateTime? approvedAt;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MediaAssetModel({
    required this.id,
    required this.uploaderId,
    this.uploaderRole,
    this.eventId,
    required this.entityType,
    required this.entityId,
    required this.kind,
    required this.mediaType,
    required this.downloadUrl,
    required this.storagePath,
    required this.fileName,
    required this.fileType,
    required this.fileSizeBytes,
    this.width,
    this.height,
    this.aspectRatio,
    required this.rightsOwner,
    required this.rightsType,
    required this.rightsDeclaration,
    required this.hashMd5,
    required this.hashSha256,
    this.approvalStatus = MediaApprovalStatus.pendingReview,
    this.safetyStatus = MediaSafetyStatus.pending,
    this.approved = false,
    this.approvedBy,
    this.approvedAt,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MediaAssetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    T enumValue<T extends Enum>(List<T> values, dynamic raw, T fallback) {
      final name = raw?.toString() ?? '';
      return values.firstWhere(
        (value) => value.name == name,
        orElse: () => fallback,
      );
    }

    return MediaAssetModel(
      id: doc.id,
      uploaderId: data['uploaderId']?.toString() ?? '',
      uploaderRole: data['uploaderRole']?.toString(),
      eventId: data['eventId']?.toString(),
      entityType: data['entityType']?.toString() ?? 'media',
      entityId: data['entityId']?.toString() ?? doc.id,
      kind: enumValue(
        MediaAssetKind.values,
        data['kind'],
        MediaAssetKind.genericImage,
      ),
      mediaType: enumValue(
        MediaAssetType.values,
        data['mediaType'],
        MediaAssetType.image,
      ),
      downloadUrl: data['downloadUrl']?.toString() ?? '',
      storagePath: data['storagePath']?.toString() ?? '',
      fileName: data['fileName']?.toString() ?? '',
      fileType: data['fileType']?.toString() ?? '',
      fileSizeBytes: (data['fileSizeBytes'] as num?)?.toInt() ?? 0,
      width: (data['width'] as num?)?.toInt(),
      height: (data['height'] as num?)?.toInt(),
      aspectRatio: (data['aspectRatio'] as num?)?.toDouble(),
      rightsOwner: data['rightsOwner']?.toString() ?? '',
      rightsType: enumValue(
        MediaRightsType.values,
        data['rightsType'],
        MediaRightsType.permissioned,
      ),
      rightsDeclaration: data['rightsDeclaration']?.toString() ?? '',
      hashMd5: data['hashMd5']?.toString() ?? '',
      hashSha256: data['hashSha256']?.toString() ?? '',
      approvalStatus: enumValue(
        MediaApprovalStatus.values,
        data['approvalStatus'],
        MediaApprovalStatus.pendingReview,
      ),
      safetyStatus: enumValue(
        MediaSafetyStatus.values,
        data['safetyStatus'],
        MediaSafetyStatus.pending,
      ),
      approved: data['approved'] == true,
      approvedBy: data['approvedBy']?.toString(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uploaderId': uploaderId,
      'uploaderRole': uploaderRole,
      'eventId': eventId,
      'entityType': entityType,
      'entityId': entityId,
      'kind': kind.name,
      'mediaType': mediaType.name,
      'downloadUrl': downloadUrl,
      'storagePath': storagePath,
      'fileName': fileName,
      'fileType': fileType,
      'fileSizeBytes': fileSizeBytes,
      'width': width,
      'height': height,
      'aspectRatio': aspectRatio,
      'rightsOwner': rightsOwner,
      'rightsType': rightsType.name,
      'rightsDeclaration': rightsDeclaration,
      'hashMd5': hashMd5,
      'hashSha256': hashSha256,
      'approvalStatus': approvalStatus.name,
      'safetyStatus': safetyStatus.name,
      'approved': approved,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  MediaAssetModel copyWith({
    String? id,
    String? uploaderId,
    String? uploaderRole,
    String? eventId,
    String? entityType,
    String? entityId,
    MediaAssetKind? kind,
    MediaAssetType? mediaType,
    String? downloadUrl,
    String? storagePath,
    String? fileName,
    String? fileType,
    int? fileSizeBytes,
    int? width,
    int? height,
    double? aspectRatio,
    String? rightsOwner,
    MediaRightsType? rightsType,
    String? rightsDeclaration,
    String? hashMd5,
    String? hashSha256,
    MediaApprovalStatus? approvalStatus,
    MediaSafetyStatus? safetyStatus,
    bool? approved,
    String? approvedBy,
    DateTime? approvedAt,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MediaAssetModel(
      id: id ?? this.id,
      uploaderId: uploaderId ?? this.uploaderId,
      uploaderRole: uploaderRole ?? this.uploaderRole,
      eventId: eventId ?? this.eventId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      kind: kind ?? this.kind,
      mediaType: mediaType ?? this.mediaType,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      storagePath: storagePath ?? this.storagePath,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      width: width ?? this.width,
      height: height ?? this.height,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      rightsOwner: rightsOwner ?? this.rightsOwner,
      rightsType: rightsType ?? this.rightsType,
      rightsDeclaration: rightsDeclaration ?? this.rightsDeclaration,
      hashMd5: hashMd5 ?? this.hashMd5,
      hashSha256: hashSha256 ?? this.hashSha256,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      safetyStatus: safetyStatus ?? this.safetyStatus,
      approved: approved ?? this.approved,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    uploaderId,
    eventId,
    entityType,
    entityId,
    kind,
    mediaType,
    downloadUrl,
    storagePath,
    fileName,
    fileType,
    fileSizeBytes,
    width,
    height,
    aspectRatio,
    rightsOwner,
    rightsType,
    hashMd5,
    hashSha256,
    approvalStatus,
    safetyStatus,
    approved,
    approvedBy,
    approvedAt,
    createdAt,
    updatedAt,
  ];
}
