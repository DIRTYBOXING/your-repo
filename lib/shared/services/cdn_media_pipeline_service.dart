import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CDN MEDIA PIPELINE SERVICE — Fast Video/Image Delivery & Processing
/// ═══════════════════════════════════════════════════════════════════════════

final _firestore = FirebaseFirestore.instance;
final _functions = FirebaseFunctions.instanceFor(
  region: 'australia-southeast1',
);
final _storage = FirebaseStorage.instance;

enum MediaType { image, video, audio, document }

enum MediaStatus { uploading, processing, ready, error, archived }

enum ImageSize { thumbnail, small, medium, large, original }

enum VideoQuality { preview, sd480, hd720, hd1080, uhd4k }

class CDNMedia {
  final String id;
  final String originalUrl;
  final Map<String, String> variants; // Size/quality -> URL
  final MediaType type;
  final MediaStatus status;
  final String? thumbnailUrl;
  final int fileSize;
  final int? width;
  final int? height;
  final int? durationMs;
  final String mimeType;
  final DateTime uploadedAt;
  final Map<String, dynamic> metadata;

  const CDNMedia({
    required this.id,
    required this.originalUrl,
    this.variants = const {},
    required this.type,
    required this.status,
    this.thumbnailUrl,
    required this.fileSize,
    this.width,
    this.height,
    this.durationMs,
    required this.mimeType,
    required this.uploadedAt,
    this.metadata = const {},
  });

  factory CDNMedia.fromMap(Map<String, dynamic> map) => CDNMedia(
    id: map['id'] ?? '',
    originalUrl: map['originalUrl'] ?? '',
    variants: Map<String, String>.from(map['variants'] ?? {}),
    type: MediaType.values.firstWhere(
      (t) => t.name == map['type'],
      orElse: () => MediaType.image,
    ),
    status: MediaStatus.values.firstWhere(
      (s) => s.name == map['status'],
      orElse: () => MediaStatus.processing,
    ),
    thumbnailUrl: map['thumbnailUrl'],
    fileSize: map['fileSize'] ?? 0,
    width: map['width'],
    height: map['height'],
    durationMs: map['durationMs'],
    mimeType: map['mimeType'] ?? 'application/octet-stream',
    uploadedAt: (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'originalUrl': originalUrl,
    'variants': variants,
    'type': type.name,
    'status': status.name,
    'thumbnailUrl': thumbnailUrl,
    'fileSize': fileSize,
    'width': width,
    'height': height,
    'durationMs': durationMs,
    'mimeType': mimeType,
    'metadata': metadata,
  };

  String getUrl({ImageSize? imageSize, VideoQuality? videoQuality}) {
    if (type == MediaType.image && imageSize != null) {
      return variants[imageSize.name] ?? originalUrl;
    }
    if (type == MediaType.video && videoQuality != null) {
      return variants[videoQuality.name] ?? originalUrl;
    }
    return originalUrl;
  }

  String get bestThumbnail =>
      thumbnailUrl ?? variants['thumbnail'] ?? originalUrl;
}

class UploadProgress {
  final String mediaId;
  final double progress;
  final int bytesTransferred;
  final int totalBytes;
  final MediaStatus status;
  final String? errorMessage;

  const UploadProgress({
    required this.mediaId,
    required this.progress,
    required this.bytesTransferred,
    required this.totalBytes,
    required this.status,
    this.errorMessage,
  });
}

class CDNMediaPipelineService with ChangeNotifier {
  static final CDNMediaPipelineService _instance =
      CDNMediaPipelineService._internal();
  factory CDNMediaPipelineService() => _instance;
  CDNMediaPipelineService._internal();

  final Map<String, UploadTask> _activeUploads = {};
  final Map<String, UploadProgress> _uploadProgress = {};
  final Map<String, CDNMedia> _mediaCache = {};

  Map<String, UploadProgress> get uploadProgress =>
      Map.unmodifiable(_uploadProgress);

  // CDN base URLs for different regions/providers
  static const Map<String, String> _cdnEndpoints = {
    'default': 'https://storage.googleapis.com/datafightcentral.appspot.com',
    'fast': 'https://cdn.datafightcentral.com',
    'video': 'https://video.datafightcentral.com',
  };

  /// Upload media file and trigger CDN processing
  Future<CDNMedia?> uploadMedia({
    required String path,
    required Uint8List data,
    required MediaType type,
    String? contentType,
    Map<String, dynamic>? metadata,
    void Function(UploadProgress)? onProgress,
  }) async {
    final mediaId = DateTime.now().millisecondsSinceEpoch.toString();
    final storagePath = '${type.name}s/$path';

    try {
      final ref = _storage.ref().child(storagePath);
      final uploadMetadata = SettableMetadata(
        contentType: contentType ?? _getMimeType(path, type),
        customMetadata: {
          'mediaId': mediaId,
          'type': type.name,
          ...?metadata?.map((k, v) => MapEntry(k, v.toString())),
        },
      );

      final uploadTask = ref.putData(data, uploadMetadata);
      _activeUploads[mediaId] = uploadTask;

      // Track progress
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = UploadProgress(
          mediaId: mediaId,
          progress: snapshot.bytesTransferred / snapshot.totalBytes,
          bytesTransferred: snapshot.bytesTransferred,
          totalBytes: snapshot.totalBytes,
          status: snapshot.state == TaskState.success
              ? MediaStatus.processing
              : snapshot.state == TaskState.error
              ? MediaStatus.error
              : MediaStatus.uploading,
        );
        _uploadProgress[mediaId] = progress;
        onProgress?.call(progress);
        notifyListeners();
      });

      // Wait for completion
      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();

      // Trigger CDN processing via Cloud Function
      final cdnMedia = await _triggerCDNProcessing(
        mediaId: mediaId,
        originalUrl: downloadUrl,
        storagePath: storagePath,
        type: type,
        fileSize: data.length,
        metadata: metadata,
      );

      if (cdnMedia != null) {
        _mediaCache[mediaId] = cdnMedia;
      }

      _activeUploads.remove(mediaId);
      return cdnMedia;
    } catch (e) {
      debugPrint('CDNMediaPipelineService: Upload failed: $e');
      _uploadProgress[mediaId] = UploadProgress(
        mediaId: mediaId,
        progress: 0,
        bytesTransferred: 0,
        totalBytes: data.length,
        status: MediaStatus.error,
        errorMessage: e.toString(),
      );
      notifyListeners();
      return null;
    }
  }

  Future<CDNMedia?> _triggerCDNProcessing({
    required String mediaId,
    required String originalUrl,
    required String storagePath,
    required MediaType type,
    required int fileSize,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final callable = _functions.httpsCallable('processCDNMedia');
      final result = await callable.call<Map<String, dynamic>>({
        'mediaId': mediaId,
        'originalUrl': originalUrl,
        'storagePath': storagePath,
        'type': type.name,
        'fileSize': fileSize,
        'metadata': metadata,
      });

      if (result.data['media'] != null) {
        return CDNMedia.fromMap(result.data['media'] as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('CDNMediaPipelineService: CDN processing failed: $e');
    }

    // Return basic media object if processing fails
    return CDNMedia(
      id: mediaId,
      originalUrl: originalUrl,
      type: type,
      status: MediaStatus.ready,
      fileSize: fileSize,
      mimeType: _getMimeType(storagePath, type),
      uploadedAt: DateTime.now(),
      metadata: metadata ?? {},
    );
  }

  /// Get optimized URL for media delivery
  String getOptimizedUrl(
    String mediaId, {
    ImageSize? imageSize,
    VideoQuality? videoQuality,
  }) {
    final cached = _mediaCache[mediaId];
    if (cached != null) {
      return cached.getUrl(imageSize: imageSize, videoQuality: videoQuality);
    }
    return '${_cdnEndpoints['default']}/$mediaId';
  }

  /// Fetch media info from Firestore
  Future<CDNMedia?> getMediaInfo(String mediaId) async {
    if (_mediaCache.containsKey(mediaId)) return _mediaCache[mediaId];

    try {
      final doc = await _firestore.collection('cdn_media').doc(mediaId).get();
      if (doc.exists) {
        final media = CDNMedia.fromMap({...doc.data()!, 'id': doc.id});
        _mediaCache[mediaId] = media;
        return media;
      }
    } catch (e) {
      debugPrint('CDNMediaPipelineService: Get media info failed: $e');
    }
    return null;
  }

  /// Generate signed URL for private content
  Future<String?> getSignedUrl(
    String mediaId, {
    Duration expiration = const Duration(hours: 1),
  }) async {
    try {
      final callable = _functions.httpsCallable('generateSignedMediaUrl');
      final result = await callable.call<Map<String, dynamic>>({
        'mediaId': mediaId,
        'expirationSeconds': expiration.inSeconds,
      });
      return result.data['signedUrl'] as String?;
    } catch (e) {
      debugPrint('CDNMediaPipelineService: Get signed URL failed: $e');
      return null;
    }
  }

  /// Cancel active upload
  void cancelUpload(String mediaId) {
    _activeUploads[mediaId]?.cancel();
    _activeUploads.remove(mediaId);
    _uploadProgress.remove(mediaId);
    notifyListeners();
  }

  /// Clear media cache
  void clearCache() {
    _mediaCache.clear();
  }

  String _getMimeType(String path, MediaType type) {
    final ext = path.split('.').last.toLowerCase();
    switch (type) {
      case MediaType.image:
        return {
              'jpg': 'image/jpeg',
              'jpeg': 'image/jpeg',
              'png': 'image/png',
              'gif': 'image/gif',
              'webp': 'image/webp',
            }[ext] ??
            'image/jpeg';
      case MediaType.video:
        return {
              'mp4': 'video/mp4',
              'webm': 'video/webm',
              'mov': 'video/quicktime',
              'm3u8': 'application/x-mpegURL',
            }[ext] ??
            'video/mp4';
      case MediaType.audio:
        return {
              'mp3': 'audio/mpeg',
              'wav': 'audio/wav',
              'aac': 'audio/aac',
            }[ext] ??
            'audio/mpeg';
      case MediaType.document:
        return {'pdf': 'application/pdf', 'doc': 'application/msword'}[ext] ??
            'application/octet-stream';
    }
  }
}
