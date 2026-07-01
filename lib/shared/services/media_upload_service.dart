import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../models/media_asset_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// 📸 MEDIA UPLOAD SERVICE — Production-Grade Photo/Video Upload
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Handles all media uploads for DFC:
/// • Post photos/videos
/// • Profile pictures
/// • Banner images
/// • Fight clips
/// • Story media
/// • Event posters
///
/// Features:
/// • Automatic image compression (max 1080p)
/// • Video thumbnail generation
/// • Progress tracking
/// • Multiple format support
/// • Firebase Storage integration
/// • Error handling & retry logic
///
/// Supported Formats:
/// Images: JPEG, PNG, HEIC, WebP
/// Videos: MP4, MOV, AVI
///
/// ═══════════════════════════════════════════════════════════════════════════
class MediaUploadService {
  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  static const String _mediaAssetsCollection = 'media_assets';
  static const String _mediaAuditLogsCollection = 'media_audit_logs';

  // Base URL for the DFC API server — override via env/config in production.
  static String get _apiBase => const String.fromEnvironment(
    'DFC_API_BASE',
    defaultValue: 'http://localhost:3000/api',
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // RESUMABLE UPLOAD SESSION — Matches server /api/uploads/sessions contract
  // ═══════════════════════════════════════════════════════════════════════════

  /// Start a resumable upload session on the DFC API server.
  ///
  /// [contentType] must be one of the allowed MIME types (image/jpeg, video/mp4, …).
  /// [fileSizeBytes] is used for server-side pre-validation.
  /// [sourceDevice] is optional metadata surfaced in the worker job payload.
  ///
  /// Returns [UploadSession] on success, throws [MediaUploadException] on failure.
  Future<UploadSession> startUploadSession({
    required String userId,
    required String contentType,
    required int fileSizeBytes,
    required String filename,
    Map<String, dynamic>? sourceDevice,
  }) async {
    final uri = Uri.parse('$_apiBase/uploads/sessions');
    final body = jsonEncode({
      'userId': userId,
      'contentType': contentType,
      'fileSizeBytes': fileSizeBytes,
      'filename': filename,
      'sourceDevice': ?sourceDevice,
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 201) {
      final err = _parseError(response);
      throw MediaUploadException('startUploadSession failed: $err');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return UploadSession.fromJson(json);
  }

  /// Poll for the current status of a resumable upload session.
  Future<UploadSession> getUploadSession(String uploadId) async {
    final uri = Uri.parse('$_apiBase/uploads/sessions/$uploadId');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      final err = _parseError(response);
      throw MediaUploadException('getUploadSession failed: $err');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return UploadSession.fromJson(json);
  }

  /// Request a pre-signed part URL for multipart upload.
  Future<String> requestPartUrl({
    required String uploadId,
    required int partNumber,
    required int partSizeBytes,
  }) async {
    final uri = Uri.parse('$_apiBase/uploads/sessions/$uploadId/parts');
    final body = jsonEncode({
      'partNumber': partNumber,
      'partSizeBytes': partSizeBytes,
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      final err = _parseError(response);
      throw MediaUploadException('requestPartUrl failed: $err');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['partUrl'] as String;
  }

  /// Mark a resumable session as complete and enqueue the media processing job.
  ///
  /// Returns the [UploadSession] with updated status and jobId.
  Future<UploadSession> completeUploadSession({
    required String uploadId,
    required String postId,
    String? checksum,
    List<Map<String, dynamic>>? parts,
  }) async {
    final uri = Uri.parse('$_apiBase/uploads/sessions/$uploadId/complete');
    final body = jsonEncode({
      'postId': postId,
      'checksum': ?checksum,
      'parts': ?parts,
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      final err = _parseError(response);
      throw MediaUploadException('completeUploadSession failed: $err');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return UploadSession.fromJson(json);
  }

  String _parseError(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['error']?.toString() ?? response.reasonPhrase ?? 'unknown';
    } catch (_) {
      return response.reasonPhrase ?? 'unknown';
    }
  }

  // Upload constraints
  static const int maxImageWidth = 1080;
  static const int maxImageHeight = 1920;
  static const int imageQuality = 85;
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const int maxVideoSizeBytes = 100 * 1024 * 1024; // 100 MB

  MediaUploadService({FirebaseStorage? storage, FirebaseFirestore? firestore})
    : _storage = storage ?? FirebaseStorage.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // IMAGE UPLOAD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Upload image with automatic compression
  Future<MediaUploadResult> uploadImage({
    required Uint8List imageBytes,
    required String userId,
    required MediaUploadType type,
    String? customPath,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return MediaUploadResult.error('Failed to decode image');
      }

      // Compress image
      final compressedBytes = await _compressImage(image);

      // Validate size
      if (compressedBytes.length > maxImageSizeBytes) {
        return MediaUploadResult.error(
          'Image too large after compression (max 5MB)',
        );
      }

      // Generate path
      final uploadPath = customPath ?? _generatePath(userId, type, 'jpg');

      // Upload to Firebase Storage
      final url = await _uploadToStorage(
        bytes: compressedBytes,
        path: uploadPath,
        contentType: 'image/jpeg',
        onProgress: onProgress,
      );

      if (kDebugMode) {
        debugPrint('📸 Image uploaded: $url');
      }

      return MediaUploadResult.success(
        url: url,
        path: uploadPath,
        type: MediaType.image,
        width: image.width,
        height: image.height,
        sizeBytes: compressedBytes.length,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Image upload failed: $e');
      }
      return MediaUploadResult.error('Upload failed: $e');
    }
  }

  /// Upload image from file path
  Future<MediaUploadResult> uploadImageFile({
    required File file,
    required String userId,
    required MediaUploadType type,
    String? customPath,
    Function(double progress)? onProgress,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      return uploadImage(
        imageBytes: bytes,
        userId: userId,
        type: type,
        customPath: customPath,
        onProgress: onProgress,
      );
    } catch (e) {
      return MediaUploadResult.error('Failed to read file: $e');
    }
  }

  /// Ingest a rights-aware image asset and persist auditable metadata.
  Future<MediaIngestionResult> ingestImageAsset({
    required Uint8List imageBytes,
    required String uploaderId,
    required MediaAssetKind kind,
    required String entityType,
    required String entityId,
    required String rightsOwner,
    required MediaRightsType rightsType,
    required String rightsDeclaration,
    String? eventId,
    String? uploaderRole,
    String? originalFileName,
    String? customPath,
    Function(double progress)? onProgress,
  }) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return MediaIngestionResult.error('Failed to decode image');
      }

      final compressedBytes = await _compressImage(image);
      if (compressedBytes.length > maxImageSizeBytes) {
        return MediaIngestionResult.error(
          'Image too large after compression (max 5MB)',
        );
      }

      final fileName = _normalizeFileName(
        originalFileName ?? '${kind.name}.jpg',
        fallbackExtension: 'jpg',
      );
      final storagePath =
          customPath ??
          _buildAssetPath(
            entityType: entityType,
            entityId: entityId,
            kind: kind,
            fileName: fileName,
          );

      final url = await _uploadToStorage(
        bytes: compressedBytes,
        path: storagePath,
        contentType: 'image/jpeg',
        onProgress: onProgress,
        customMetadata: {
          'entityType': entityType,
          'entityId': entityId,
          'eventId': eventId ?? '',
          'kind': kind.name,
          'rightsOwner': rightsOwner,
          'rightsType': rightsType.name,
          'uploaderId': uploaderId,
        },
      );

      final assetRef = _firestore.collection(_mediaAssetsCollection).doc();
      final now = DateTime.now();
      final asset = MediaAssetModel(
        id: assetRef.id,
        uploaderId: uploaderId,
        uploaderRole: uploaderRole,
        eventId: eventId,
        entityType: entityType,
        entityId: entityId,
        kind: kind,
        mediaType: MediaAssetType.image,
        downloadUrl: url,
        storagePath: storagePath,
        fileName: fileName,
        fileType: 'image/jpeg',
        fileSizeBytes: compressedBytes.length,
        width: image.width,
        height: image.height,
        aspectRatio: image.height == 0 ? null : image.width / image.height,
        rightsOwner: rightsOwner,
        rightsType: rightsType,
        rightsDeclaration: rightsDeclaration,
        hashMd5: crypto.md5.convert(imageBytes).toString(),
        hashSha256: crypto.sha256.convert(imageBytes).toString(),
        metadata: {
          'originalFileName': originalFileName,
          'ingestionSource': 'flutter_client',
          'compressed': true,
        },
        createdAt: now,
        updatedAt: now,
      );

      await assetRef.set(asset.toFirestore());
      await _writeAuditLog(
        asset: asset,
        action: 'ingested',
        extra: {'contentType': 'image/jpeg'},
      );

      return MediaIngestionResult.success(asset);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Asset ingestion failed: $e');
      }
      return MediaIngestionResult.error('Asset ingestion failed: $e');
    }
  }

  /// Ingest a rights-aware video asset and persist auditable metadata.
  Future<MediaIngestionResult> ingestVideoAsset({
    required File videoFile,
    required String uploaderId,
    required MediaAssetKind kind,
    required String entityType,
    required String entityId,
    required String rightsOwner,
    required MediaRightsType rightsType,
    required String rightsDeclaration,
    String? eventId,
    String? uploaderRole,
    String? originalFileName,
    String? customPath,
    Function(double progress)? onProgress,
  }) async {
    try {
      final fileSize = await videoFile.length();
      if (fileSize > maxVideoSizeBytes) {
        return MediaIngestionResult.error(
          'Video too large (max 100MB). Size: ${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB',
        );
      }

      final extension = path.extension(videoFile.path).toLowerCase();
      final normalizedExtension = extension.replaceFirst('.', '');
      final fileName = _normalizeFileName(
        originalFileName ?? path.basename(videoFile.path),
        fallbackExtension: normalizedExtension.isEmpty
            ? 'mp4'
            : normalizedExtension,
      );
      final storagePath =
          customPath ??
          _buildAssetPath(
            entityType: entityType,
            entityId: entityId,
            kind: kind,
            fileName: fileName,
          );

      final bytes = await videoFile.readAsBytes();
      final contentType =
          'video/${normalizedExtension.isEmpty ? 'mp4' : normalizedExtension}';
      final url = await _uploadToStorage(
        bytes: bytes,
        path: storagePath,
        contentType: contentType,
        onProgress: onProgress,
        customMetadata: {
          'entityType': entityType,
          'entityId': entityId,
          'eventId': eventId ?? '',
          'kind': kind.name,
          'rightsOwner': rightsOwner,
          'rightsType': rightsType.name,
          'uploaderId': uploaderId,
        },
      );

      final assetRef = _firestore.collection(_mediaAssetsCollection).doc();
      final now = DateTime.now();
      final asset = MediaAssetModel(
        id: assetRef.id,
        uploaderId: uploaderId,
        uploaderRole: uploaderRole,
        eventId: eventId,
        entityType: entityType,
        entityId: entityId,
        kind: kind,
        mediaType: MediaAssetType.video,
        downloadUrl: url,
        storagePath: storagePath,
        fileName: fileName,
        fileType: contentType,
        fileSizeBytes: fileSize,
        rightsOwner: rightsOwner,
        rightsType: rightsType,
        rightsDeclaration: rightsDeclaration,
        hashMd5: crypto.md5.convert(bytes).toString(),
        hashSha256: crypto.sha256.convert(bytes).toString(),
        metadata: {
          'originalFileName': originalFileName ?? path.basename(videoFile.path),
          'ingestionSource': 'flutter_client',
          'extension': normalizedExtension,
        },
        createdAt: now,
        updatedAt: now,
      );

      await assetRef.set(asset.toFirestore());
      await _writeAuditLog(
        asset: asset,
        action: 'ingested',
        extra: {'contentType': contentType},
      );

      return MediaIngestionResult.success(asset);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Video asset ingestion failed: $e');
      }
      return MediaIngestionResult.error('Video asset ingestion failed: $e');
    }
  }

  /// Ingest a rights-aware video asset from bytes for web-compatible flows.
  Future<MediaIngestionResult> ingestVideoBytesAsset({
    required Uint8List videoBytes,
    required String uploaderId,
    required MediaAssetKind kind,
    required String entityType,
    required String entityId,
    required String rightsOwner,
    required MediaRightsType rightsType,
    required String rightsDeclaration,
    String? eventId,
    String? uploaderRole,
    String? originalFileName,
    String? customPath,
    Function(double progress)? onProgress,
  }) async {
    try {
      if (videoBytes.length > maxVideoSizeBytes) {
        return MediaIngestionResult.error(
          'Video too large (max 100MB). Size: ${(videoBytes.length / 1024 / 1024).toStringAsFixed(1)}MB',
        );
      }

      final fileName = _normalizeFileName(
        originalFileName ?? '${kind.name}.mp4',
        fallbackExtension: 'mp4',
      );
      final extension = path.extension(fileName).replaceFirst('.', '');
      final contentType = 'video/${extension.isEmpty ? 'mp4' : extension}';
      final storagePath =
          customPath ??
          _buildAssetPath(
            entityType: entityType,
            entityId: entityId,
            kind: kind,
            fileName: fileName,
          );

      final url = await _uploadToStorage(
        bytes: videoBytes,
        path: storagePath,
        contentType: contentType,
        onProgress: onProgress,
        customMetadata: {
          'entityType': entityType,
          'entityId': entityId,
          'eventId': eventId ?? '',
          'kind': kind.name,
          'rightsOwner': rightsOwner,
          'rightsType': rightsType.name,
          'uploaderId': uploaderId,
        },
      );

      final assetRef = _firestore.collection(_mediaAssetsCollection).doc();
      final now = DateTime.now();
      final asset = MediaAssetModel(
        id: assetRef.id,
        uploaderId: uploaderId,
        uploaderRole: uploaderRole,
        eventId: eventId,
        entityType: entityType,
        entityId: entityId,
        kind: kind,
        mediaType: MediaAssetType.video,
        downloadUrl: url,
        storagePath: storagePath,
        fileName: fileName,
        fileType: contentType,
        fileSizeBytes: videoBytes.length,
        rightsOwner: rightsOwner,
        rightsType: rightsType,
        rightsDeclaration: rightsDeclaration,
        hashMd5: crypto.md5.convert(videoBytes).toString(),
        hashSha256: crypto.sha256.convert(videoBytes).toString(),
        metadata: {
          'originalFileName': originalFileName,
          'ingestionSource': 'flutter_client',
          'extension': extension,
        },
        createdAt: now,
        updatedAt: now,
      );

      await assetRef.set(asset.toFirestore());
      await _writeAuditLog(
        asset: asset,
        action: 'ingested',
        extra: {'contentType': contentType},
      );

      return MediaIngestionResult.success(asset);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Video byte asset ingestion failed: $e');
      }
      return MediaIngestionResult.error(
        'Video byte asset ingestion failed: $e',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VIDEO UPLOAD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Upload video with validation
  Future<MediaUploadResult> uploadVideo({
    required File videoFile,
    required String userId,
    required MediaUploadType type,
    String? customPath,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Validate file size
      final fileSize = await videoFile.length();
      if (fileSize > maxVideoSizeBytes) {
        return MediaUploadResult.error(
          'Video too large (max 100MB). Size: ${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB',
        );
      }

      // Get file extension
      final extension = path.extension(videoFile.path).toLowerCase();
      final validExtensions = ['.mp4', '.mov', '.avi'];
      if (!validExtensions.contains(extension)) {
        return MediaUploadResult.error(
          'Invalid video format. Supported: MP4, MOV, AVI',
        );
      }

      // Generate path
      final uploadPath =
          customPath ?? _generatePath(userId, type, extension.substring(1));

      // Read file bytes
      final bytes = await videoFile.readAsBytes();

      // Upload to Firebase Storage
      final url = await _uploadToStorage(
        bytes: bytes,
        path: uploadPath,
        contentType: 'video/${extension.substring(1)}',
        onProgress: onProgress,
      );

      if (kDebugMode) {
        debugPrint('🎥 Video uploaded: $url');
      }

      return MediaUploadResult.success(
        url: url,
        path: uploadPath,
        type: MediaType.video,
        sizeBytes: fileSize,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Video upload failed: $e');
      }
      return MediaUploadResult.error('Upload failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROFILE IMAGES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Upload profile picture (square crop)
  Future<MediaUploadResult> uploadProfilePicture({
    required Uint8List imageBytes,
    required String userId,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return MediaUploadResult.error('Failed to decode image');
      }

      // Crop to square
      final size = image.width < image.height ? image.width : image.height;
      final cropped = img.copyCrop(
        image,
        x: (image.width - size) ~/ 2,
        y: (image.height - size) ~/ 2,
        width: size,
        height: size,
      );

      // Resize to 512x512
      final resized = img.copyResize(cropped, width: 512, height: 512);

      // Compress
      final compressedBytes = Uint8List.fromList(
        img.encodeJpg(resized, quality: imageQuality),
      );

      // Upload
      final path = 'users/$userId/profile.jpg';
      final url = await _uploadToStorage(
        bytes: compressedBytes,
        path: path,
        contentType: 'image/jpeg',
        onProgress: onProgress,
      );

      if (kDebugMode) {
        debugPrint('📸 Profile picture uploaded: $url');
      }

      return MediaUploadResult.success(
        url: url,
        path: path,
        type: MediaType.image,
        width: 512,
        height: 512,
        sizeBytes: compressedBytes.length,
      );
    } catch (e) {
      return MediaUploadResult.error('Profile upload failed: $e');
    }
  }

  /// Upload banner image (16:9 aspect ratio)
  Future<MediaUploadResult> uploadBannerImage({
    required Uint8List imageBytes,
    required String userId,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return MediaUploadResult.error('Failed to decode image');
      }

      // Resize to 1920x1080 (16:9)
      final resized = img.copyResize(image, width: 1920, height: 1080);

      // Compress
      final compressedBytes = Uint8List.fromList(
        img.encodeJpg(resized, quality: imageQuality),
      );

      // Upload
      final path = 'users/$userId/banner.jpg';
      final url = await _uploadToStorage(
        bytes: compressedBytes,
        path: path,
        contentType: 'image/jpeg',
        onProgress: onProgress,
      );

      if (kDebugMode) {
        debugPrint('📸 Banner image uploaded: $url');
      }

      return MediaUploadResult.success(
        url: url,
        path: path,
        type: MediaType.image,
        width: 1920,
        height: 1080,
        sizeBytes: compressedBytes.length,
      );
    } catch (e) {
      return MediaUploadResult.error('Banner upload failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BATCH UPLOAD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Upload multiple images (e.g., post carousel)
  Future<List<MediaUploadResult>> uploadMultipleImages({
    required List<Uint8List> imageBytesList,
    required String userId,
    required MediaUploadType type,
    Function(int index, double progress)? onProgress,
  }) async {
    final results = <MediaUploadResult>[];

    for (var i = 0; i < imageBytesList.length; i++) {
      final result = await uploadImage(
        imageBytes: imageBytesList[i],
        userId: userId,
        type: type,
        onProgress: (progress) => onProgress?.call(i, progress),
      );
      results.add(result);
    }

    return results;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DELETE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Delete media file
  Future<bool> deleteMedia(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
      if (kDebugMode) {
        debugPrint('🗑️ Deleted: $storagePath');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Delete failed: $e');
      }
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Compress image to target size
  Future<Uint8List> _compressImage(img.Image image) async {
    // Calculate resize dimensions
    int width = image.width;
    int height = image.height;

    if (width > maxImageWidth || height > maxImageHeight) {
      final widthRatio = maxImageWidth / width;
      final heightRatio = maxImageHeight / height;
      final ratio = widthRatio < heightRatio ? widthRatio : heightRatio;

      width = (width * ratio).round();
      height = (height * ratio).round();
    }

    // Resize
    final resized = img.copyResize(image, width: width, height: height);

    // Encode as JPEG
    return Uint8List.fromList(img.encodeJpg(resized, quality: imageQuality));
  }

  /// Upload bytes to Firebase Storage
  Future<String> _uploadToStorage({
    required Uint8List bytes,
    required String path,
    required String contentType,
    Function(double progress)? onProgress,
    Map<String, String>? customMetadata,
  }) async {
    final ref = _storage.ref(path);

    // Create upload task
    final uploadTask = ref.putData(
      bytes,
      SettableMetadata(
        contentType: contentType,
        customMetadata: customMetadata,
      ),
    );

    // Track progress
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    // Wait for completion
    await uploadTask;

    // Get download URL
    return await ref.getDownloadURL();
  }

  /// Generate unique storage path
  String _generatePath(String userId, MediaUploadType type, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueId = _uuid.v4().substring(0, 8);
    return '${type.path}/$userId/${timestamp}_$uniqueId.$extension';
  }

  String _buildAssetPath({
    required String entityType,
    required String entityId,
    required MediaAssetKind kind,
    required String fileName,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueId = _uuid.v4().substring(0, 8);
    return 'media/$entityType/$entityId/${kind.name}/${timestamp}_${uniqueId}_$fileName';
  }

  String _normalizeFileName(
    String rawName, {
    required String fallbackExtension,
  }) {
    final trimmed = rawName.trim();
    final withFallback = trimmed.isEmpty
        ? 'upload.$fallbackExtension'
        : trimmed;
    final sanitized = withFallback.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    if (sanitized.contains('.')) return sanitized;
    return '$sanitized.$fallbackExtension';
  }

  Future<void> _writeAuditLog({
    required MediaAssetModel asset,
    required String action,
    Map<String, dynamic>? extra,
  }) async {
    await _firestore.collection(_mediaAuditLogsCollection).add({
      'assetId': asset.id,
      'action': action,
      'entityType': asset.entityType,
      'entityId': asset.entityId,
      'eventId': asset.eventId,
      'kind': asset.kind.name,
      'mediaType': asset.mediaType.name,
      'uploaderId': asset.uploaderId,
      'rightsOwner': asset.rightsOwner,
      'rightsType': asset.rightsType.name,
      'approved': asset.approved,
      'createdAt': FieldValue.serverTimestamp(),
      'extra': extra,
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// Upload result
class MediaUploadResult {
  final bool success;
  final String? url;
  final String? path;
  final MediaType? type;
  final int? width;
  final int? height;
  final int? sizeBytes;
  final String? error;

  MediaUploadResult._({
    required this.success,
    this.url,
    this.path,
    this.type,
    this.width,
    this.height,
    this.sizeBytes,
    this.error,
  });

  factory MediaUploadResult.success({
    required String url,
    required String path,
    required MediaType type,
    int? width,
    int? height,
    int? sizeBytes,
  }) {
    return MediaUploadResult._(
      success: true,
      url: url,
      path: path,
      type: type,
      width: width,
      height: height,
      sizeBytes: sizeBytes,
    );
  }

  factory MediaUploadResult.error(String error) {
    return MediaUploadResult._(success: false, error: error);
  }

  /// Human-readable file size
  String get fileSizeFormatted {
    if (sizeBytes == null) return 'Unknown';
    final kb = sizeBytes! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}

class MediaIngestionResult {
  final bool success;
  final MediaAssetModel? asset;
  final String? error;

  const MediaIngestionResult._({required this.success, this.asset, this.error});

  factory MediaIngestionResult.success(MediaAssetModel asset) {
    return MediaIngestionResult._(success: true, asset: asset);
  }

  factory MediaIngestionResult.error(String error) {
    return MediaIngestionResult._(success: false, error: error);
  }
}

/// Media type
enum MediaType { image, video }

/// Upload type determines storage path
enum MediaUploadType {
  post('posts'),
  profile('profiles'),
  story('stories'),
  event('events'),
  gym('gyms'),
  campaign('campaigns'),
  message('messages');

  final String path;
  const MediaUploadType(this.path);
}

// ═══════════════════════════════════════════════════════════════════════════
// RESUMABLE SESSION MODEL
// ═══════════════════════════════════════════════════════════════════════════

/// Status lifecycle of a resumable upload session.
enum UploadSessionStatus { created, uploading, complete, failed }

/// Represents one resumable upload session returned by /api/uploads/sessions.
class UploadSession {
  final String uploadId;
  final String userId;
  final String contentType;
  final int fileSizeBytes;
  final String key;
  final UploadSessionStatus status;
  final String? jobId;
  final DateTime createdAt;

  const UploadSession({
    required this.uploadId,
    required this.userId,
    required this.contentType,
    required this.fileSizeBytes,
    required this.key,
    required this.status,
    this.jobId,
    required this.createdAt,
  });

  factory UploadSession.fromJson(Map<String, dynamic> json) => UploadSession(
    uploadId: json['uploadId'] as String? ?? json['id'] as String? ?? '',
    userId: json['userId'] as String? ?? '',
    contentType: json['contentType'] as String? ?? '',
    fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
    key: json['key'] as String? ?? '',
    status: UploadSessionStatus.values.firstWhere(
      (s) => s.name == (json['status'] as String? ?? 'created'),
      orElse: () => UploadSessionStatus.created,
    ),
    jobId: json['jobId'] as String?,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );
}

/// Thrown when a resumable session API call fails.
class MediaUploadException implements Exception {
  final String message;
  const MediaUploadException(this.message);

  @override
  String toString() => 'MediaUploadException: $message';
}
