import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/app_logger.dart';

/// Asset types that can be uploaded to Firebase Storage.
enum MediaAssetType {
  fighterPhoto,
  eventPoster,
  videoThumbnail,
  postMedia,
  gymPhoto,
}

/// Result returned after a successful upload.
class MediaUploadResult {
  const MediaUploadResult({
    required this.downloadUrl,
    required this.storagePath,
    required this.assetType,
    required this.fileSizeBytes,
  });

  final String downloadUrl;
  final String storagePath;
  final MediaAssetType assetType;
  final int fileSizeBytes;
}

/// Handles uploading fighter photos, event posters, video thumbnails, and post
/// media to Firebase Storage. Returns a download URL after each upload.
///
/// All paths are scoped under `media/<assetType>/<uid>/` so Firestore security
/// rules can enforce per-user write access.
class MediaAssetUploadService {
  MediaAssetUploadService({FirebaseStorage? storage, FirebaseAuth? auth})
    : _storage = storage ?? FirebaseStorage.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  static const int _maxFileSizeBytes = 50 * 1024 * 1024; // 50 MB

  // ─── Public API ────────────────────────────────────────────────────────

  /// Upload a file from a local [filePath] (mobile / desktop).
  ///
  /// Returns a [MediaUploadResult] on success.
  /// Throws [MediaUploadException] on validation or storage failure.
  Future<MediaUploadResult> uploadFile({
    required String filePath,
    required MediaAssetType assetType,
    String? fileName,
    void Function(double progress)? onProgress,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw MediaUploadException('File not found: $filePath');
    }

    final bytes = await file.readAsBytes();
    return _uploadBytes(
      bytes: bytes,
      assetType: assetType,
      fileName: fileName ?? _baseName(filePath),
      contentType: _inferContentType(filePath),
      onProgress: onProgress,
    );
  }

  /// Upload raw [bytes] (web / in-memory).
  ///
  /// [fileName] must include an extension so the content-type can be inferred.
  Future<MediaUploadResult> uploadBytes({
    required Uint8List bytes,
    required MediaAssetType assetType,
    required String fileName,
    String? contentType,
    void Function(double progress)? onProgress,
  }) {
    return _uploadBytes(
      bytes: bytes,
      assetType: assetType,
      fileName: fileName,
      contentType: contentType ?? _inferContentType(fileName),
      onProgress: onProgress,
    );
  }

  /// Delete an asset at [storagePath] (e.g. from a [MediaUploadResult]).
  Future<void> deleteAsset(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
      AppLogger.info('MediaAssetUploadService: deleted $storagePath');
    } on FirebaseException catch (e) {
      AppLogger.error('MediaAssetUploadService: delete failed — $e');
      throw MediaUploadException('Delete failed: ${e.message}', cause: e);
    }
  }

  // ─── Internal ──────────────────────────────────────────────────────────

  Future<MediaUploadResult> _uploadBytes({
    required List<int> bytes,
    required MediaAssetType assetType,
    required String fileName,
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    _assertAuthenticated();
    _assertFileSize(bytes.length);

    final uid = _auth.currentUser!.uid;
    final storagePath = _buildPath(uid, assetType, fileName);
    final ref = _storage.ref(storagePath);

    final metadata = SettableMetadata(
      contentType: contentType,
      customMetadata: {
        'uploadedBy': uid,
        'assetType': assetType.name,
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );

    try {
      AppLogger.info('MediaAssetUploadService: uploading to $storagePath');

      final task = ref.putData(Uint8List.fromList(bytes), metadata);

      if (onProgress != null) {
        task.snapshotEvents.listen((snapshot) {
          if (snapshot.totalBytes > 0) {
            onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
          }
        });
      }

      await task;
      final downloadUrl = await ref.getDownloadURL();

      AppLogger.info('MediaAssetUploadService: upload complete → $downloadUrl');

      return MediaUploadResult(
        downloadUrl: downloadUrl,
        storagePath: storagePath,
        assetType: assetType,
        fileSizeBytes: bytes.length,
      );
    } on FirebaseException catch (e) {
      AppLogger.error('MediaAssetUploadService: upload failed — $e');
      throw MediaUploadException('Upload failed: ${e.message}', cause: e);
    }
  }

  void _assertAuthenticated() {
    if (_auth.currentUser == null) {
      throw const MediaUploadException(
        'User must be signed in to upload assets.',
      );
    }
  }

  void _assertFileSize(int bytes) {
    if (bytes > _maxFileSizeBytes) {
      final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
      throw MediaUploadException(
        'File too large: ${mb}MB (max ${_maxFileSizeBytes ~/ (1024 * 1024)}MB).',
      );
    }
    if (bytes == 0) {
      throw const MediaUploadException('File is empty.');
    }
  }

  String _buildPath(String uid, MediaAssetType assetType, String fileName) {
    final folder = _folderFor(assetType);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final safe = _sanitizeFileName(fileName);
    return 'media/$folder/$uid/${ts}_$safe';
  }

  String _folderFor(MediaAssetType t) => switch (t) {
    MediaAssetType.fighterPhoto => 'fighter_photos',
    MediaAssetType.eventPoster => 'event_posters',
    MediaAssetType.videoThumbnail => 'video_thumbnails',
    MediaAssetType.postMedia => 'post_media',
    MediaAssetType.gymPhoto => 'gym_photos',
  };

  String _inferContentType(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'heic' => 'image/heic',
      _ => 'application/octet-stream',
    };
  }

  String _baseName(String path) {
    return path.replaceAll('\\', '/').split('/').last;
  }

  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[^\w.\-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }
}

/// Thrown when [MediaAssetUploadService] encounters a validation or
/// Firebase Storage error.
class MediaUploadException implements Exception {
  const MediaUploadException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'MediaUploadException: $message';
}
