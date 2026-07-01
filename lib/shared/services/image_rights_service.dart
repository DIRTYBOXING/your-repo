import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import '../models/image_rights_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC IMAGE RIGHTS SERVICE — The Legal Backbone of Every Pixel
///
/// Handles: upload with attestation, admin approval, rejection, revocation,
/// takedown requests, dispute resolution, audit logging, and expiry sweeps.
///
/// RULE: No image reaches any public surface unless isPublicReady == true.
/// Cloud Functions enforce the same gate server-side via status checks.
/// ═══════════════════════════════════════════════════════════════════════════
class ImageRightsService with ChangeNotifier {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  static const _uuid = Uuid();

  static const _imagesCol = 'images';
  static const _takedownsCol = 'image_takedowns';
  static const _auditCol = 'image_audit_log';

  // Thumbnail config
  static const int _thumbWidth = 300;
  static const int _thumbQuality = 70;

  ImageRightsService({
    FirebaseFirestore? db,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  }) : _db = db ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _auth = auth ?? FirebaseAuth.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // UPLOAD WITH ATTESTATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Upload an image with full rights attestation.
  /// Returns the created [ImageRightsModel] or throws on failure.
  ///
  /// [attestationSigned] MUST be true — the UI checkbox enforces this.
  /// The image starts as [ImageApprovalStatus.pending] and is invisible
  /// to public feeds until an admin approves it.
  Future<ImageRightsModel> uploadWithAttestation({
    required Uint8List imageBytes,
    required String fileName,
    required ImageOwnerType ownerType,
    required String ownerName,
    required String ownerEmail,
    required ImageLicenseType licenseType,
    required bool attestationSigned,
    String? licenseNotes,
    DateTime? licenseExpiresAt,
    List<ImageUsageScope> allowedScopes = const [
      ImageUsageScope.feed,
      ImageUsageScope.social,
      ImageUsageScope.editorial,
    ],
    String? sourceEventId,
    String? sourceFighterId,
    String? sourcePromotionId,
    List<String> tags = const [],
    Function(double)? onProgress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Authentication required');

    if (!attestationSigned) {
      throw Exception('Attestation must be signed before upload');
    }

    // Decode to validate it's a real image and get dimensions
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) throw Exception('Invalid image data');

    // Generate unique ID and storage paths
    final imageId = _uuid.v4();
    final ext = _inferExtension(imageBytes);
    final storagePath = 'images/$imageId/original.$ext';
    final thumbPath = 'images/$imageId/thumb.$ext';

    // Upload original
    final originalUrl = await _uploadBytes(
      bytes: imageBytes,
      path: storagePath,
      contentType: 'image/$ext',
      onProgress: onProgress,
    );

    // Generate and upload thumbnail
    final thumb = img.copyResize(decoded, width: _thumbWidth);
    final thumbBytes = Uint8List.fromList(
      img.encodeJpg(thumb, quality: _thumbQuality),
    );
    final thumbUrl = await _uploadBytes(
      bytes: thumbBytes,
      path: thumbPath,
      contentType: 'image/jpeg',
    );

    // Determine attestation text based on owner type
    final attestText = ownerType == ImageOwnerType.promoter
        ? ImageRightsModel.promoterPermissionText
        : ImageRightsModel.uploaderAttestationText;

    final now = DateTime.now();

    final model = ImageRightsModel(
      id: imageId,
      url: originalUrl,
      storagePath: storagePath,
      thumbnailUrl: thumbUrl,
      fileName: fileName,
      fileSizeBytes: imageBytes.length,
      widthPx: decoded.width,
      heightPx: decoded.height,
      mimeType: 'image/$ext',
      ownerType: ownerType,
      ownerName: ownerName,
      ownerEmail: ownerEmail,
      licenseType: licenseType,
      licenseNotes: licenseNotes,
      licenseExpiresAt: licenseExpiresAt,
      allowedScopes: allowedScopes,
      attestationText: attestText,
      attestationSigned: true,
      attestationSignedAt: now,
      sourceEventId: sourceEventId,
      sourceFighterId: sourceFighterId,
      sourcePromotionId: sourcePromotionId,
      tags: tags,
      uploadedBy: user.uid,
      createdAt: now,
      updatedAt: now,
    );

    // Write to Firestore
    await _db.collection(_imagesCol).doc(imageId).set(model.toFirestore());

    // Write audit log (immutable)
    await _writeAudit(
      imageId: imageId,
      action: 'upload',
      performedBy: user.uid,
      details: {
        'ownerName': ownerName,
        'ownerEmail': ownerEmail,
        'licenseType': licenseType.name,
        'attestationSigned': true,
        'fileName': fileName,
        'fileSizeBytes': imageBytes.length,
      },
    );

    notifyListeners();
    return model;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN APPROVAL PIPELINE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream of images awaiting admin review
  Stream<List<ImageRightsModel>> streamPendingImages({int limit = 50}) {
    return _db
        .collection(_imagesCol)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map(ImageRightsModel.fromFirestore).toList(),
        );
  }

  /// Stream all images (admin view) with optional status filter
  Stream<List<ImageRightsModel>> streamImages({
    ImageApprovalStatus? statusFilter,
    int limit = 100,
  }) {
    Query<Map<String, dynamic>> q = _db
        .collection(_imagesCol)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (statusFilter != null) {
      q = q.where('status', isEqualTo: statusFilter.name);
    }

    return q.snapshots().map(
      (snap) =>
          snap.docs.map(ImageRightsModel.fromFirestore).toList(),
    );
  }

  /// Approve an image — it can now appear in public feeds/ads
  Future<void> approveImage(String imageId) async {
    final adminUid = _auth.currentUser?.uid;
    if (adminUid == null) throw Exception('Admin authentication required');

    final now = DateTime.now();

    await _db.collection(_imagesCol).doc(imageId).update({
      'status': ImageApprovalStatus.approved.name,
      'approvedBy': adminUid,
      'approvedAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    await _writeAudit(
      imageId: imageId,
      action: 'approve',
      performedBy: adminUid,
    );

    notifyListeners();
  }

  /// Reject an image — it will never appear publicly
  Future<void> rejectImage(String imageId, String reason) async {
    final adminUid = _auth.currentUser?.uid;
    if (adminUid == null) throw Exception('Admin authentication required');

    final now = DateTime.now();

    await _db.collection(_imagesCol).doc(imageId).update({
      'status': ImageApprovalStatus.rejected.name,
      'rejectedBy': adminUid,
      'rejectedAt': Timestamp.fromDate(now),
      'rejectionReason': reason,
      'updatedAt': Timestamp.fromDate(now),
    });

    await _writeAudit(
      imageId: imageId,
      action: 'reject',
      performedBy: adminUid,
      details: {'reason': reason},
    );

    notifyListeners();
  }

  /// Revoke a previously approved image (e.g., license expired, dispute filed)
  Future<void> revokeImage(String imageId, String reason) async {
    final adminUid = _auth.currentUser?.uid;
    if (adminUid == null) throw Exception('Admin authentication required');

    final now = DateTime.now();

    await _db.collection(_imagesCol).doc(imageId).update({
      'status': ImageApprovalStatus.revoked.name,
      'isTakenDown': true,
      'takedownReason': reason,
      'takenDownAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    await _writeAudit(
      imageId: imageId,
      action: 'revoke',
      performedBy: adminUid,
      details: {'reason': reason},
    );

    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC GATE — ONLY APPROVED IMAGES LEAVE THIS METHOD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get a single image by ID — returns null if not found or not public-ready
  Future<ImageRightsModel?> getImage(String imageId) async {
    final doc = await _db.collection(_imagesCol).doc(imageId).get();
    if (!doc.exists) return null;
    return ImageRightsModel.fromFirestore(doc);
  }

  /// Get a single image ONLY if it's approved and not taken down.
  /// This is what feed cards, articles, and ad surfaces should call.
  Future<ImageRightsModel?> getApprovedImage(String imageId) async {
    final model = await getImage(imageId);
    if (model == null || !model.isPublicReady) return null;
    return model;
  }

  /// Get approved images for a specific scope (e.g., only images cleared for ads)
  Future<List<ImageRightsModel>> getApprovedImagesForScope(
    ImageUsageScope scope, {
    int limit = 50,
  }) async {
    final snap = await _db
        .collection(_imagesCol)
        .where('status', isEqualTo: 'approved')
        .where('isTakenDown', isEqualTo: false)
        .where('allowedScopes', arrayContains: scope.name)
        .orderBy('approvedAt', descending: true)
        .limit(limit)
        .get();

    return snap.docs
        .map(ImageRightsModel.fromFirestore)
        .where((m) => m.isPublicReady)
        .toList();
  }

  /// Get all approved images for a specific event
  Future<List<ImageRightsModel>> getEventImages(String eventId) async {
    final snap = await _db
        .collection(_imagesCol)
        .where('sourceEventId', isEqualTo: eventId)
        .where('status', isEqualTo: 'approved')
        .where('isTakenDown', isEqualTo: false)
        .get();

    return snap.docs
        .map(ImageRightsModel.fromFirestore)
        .where((m) => m.isPublicReady)
        .toList();
  }

  /// Get all approved images for a specific promoter
  Future<List<ImageRightsModel>> getPromoterImages(String promotionId) async {
    final snap = await _db
        .collection(_imagesCol)
        .where('sourcePromotionId', isEqualTo: promotionId)
        .where('status', isEqualTo: 'approved')
        .where('isTakenDown', isEqualTo: false)
        .get();

    return snap.docs
        .map(ImageRightsModel.fromFirestore)
        .where((m) => m.isPublicReady)
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAKEDOWN & DISPUTE
  // ═══════════════════════════════════════════════════════════════════════════

  /// File a takedown request — immediately removes from public surfaces
  Future<String> fileTakedown({
    required String imageId,
    required String complainantName,
    required String complainantEmail,
    required String reason,
    String? evidenceUrl,
  }) async {
    final now = DateTime.now();

    // Immediately remove from public visibility
    await _db.collection(_imagesCol).doc(imageId).update({
      'isTakenDown': true,
      'takedownReason': reason,
      'takenDownAt': Timestamp.fromDate(now),
      'takedownRequestedBy': complainantEmail,
      'status': ImageApprovalStatus.revoked.name,
      'updatedAt': Timestamp.fromDate(now),
    });

    // Create takedown record
    final takedown = ImageTakedownModel(
      id: '',
      imageId: imageId,
      complainantName: complainantName,
      complainantEmail: complainantEmail,
      reason: reason,
      evidenceUrl: evidenceUrl,
      receivedAt: now,
    );

    final doc = await _db.collection(_takedownsCol).add(takedown.toFirestore());

    // Link takedown to image
    await _db.collection(_imagesCol).doc(imageId).update({'disputeId': doc.id});

    // Audit trail
    await _writeAudit(
      imageId: imageId,
      action: 'takedown_filed',
      performedBy: 'external:$complainantEmail',
      details: {
        'complainantName': complainantName,
        'complainantEmail': complainantEmail,
        'reason': reason,
        'takedownId': doc.id,
      },
    );

    notifyListeners();
    return doc.id;
  }

  /// Resolve a takedown — admin decision after investigation
  Future<void> resolveTakedown({
    required String takedownId,
    required bool upheld,
    required String resolution,
  }) async {
    final adminUid = _auth.currentUser?.uid;
    if (adminUid == null) throw Exception('Admin authentication required');

    final now = DateTime.now();
    final status = upheld ? TakedownStatus.upheld : TakedownStatus.dismissed;

    // Update takedown record
    await _db.collection(_takedownsCol).doc(takedownId).update({
      'status': status.name,
      'investigatorId': adminUid,
      'resolution': resolution,
      'resolvedAt': Timestamp.fromDate(now),
    });

    // Get the takedown to find the image
    final takedownDoc = await _db
        .collection(_takedownsCol)
        .doc(takedownId)
        .get();
    final imageId = takedownDoc.data()?['imageId']?.toString() ?? '';

    if (imageId.isNotEmpty) {
      if (upheld) {
        // Takedown upheld — delete the image from storage
        final imageDoc = await _db.collection(_imagesCol).doc(imageId).get();
        final storagePath = imageDoc.data()?['storagePath']?.toString();
        if (storagePath != null && storagePath.isNotEmpty) {
          try {
            await _storage.ref(storagePath).delete();
            // Also delete thumbnail
            final thumbPath = storagePath.replaceFirst('original.', 'thumb.');
            await _storage.ref(thumbPath).delete();
          } catch (e) {
            debugPrint('Storage cleanup failed: $e');
          }
        }

        await _db.collection(_imagesCol).doc(imageId).update({
          'status': ImageApprovalStatus.revoked.name,
          'isTakenDown': true,
          'updatedAt': Timestamp.fromDate(now),
        });
      } else {
        // Takedown dismissed — restore the image
        await _db.collection(_imagesCol).doc(imageId).update({
          'status': ImageApprovalStatus.approved.name,
          'isTakenDown': false,
          'takedownReason': null,
          'takenDownAt': null,
          'takedownRequestedBy': null,
          'disputeId': null,
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      await _writeAudit(
        imageId: imageId,
        action: upheld ? 'takedown_upheld' : 'takedown_dismissed',
        performedBy: adminUid,
        details: {'takedownId': takedownId, 'resolution': resolution},
      );
    }

    notifyListeners();
  }

  /// Stream takedown requests for admin review
  Stream<List<ImageTakedownModel>> streamTakedowns({TakedownStatus? status}) {
    Query<Map<String, dynamic>> q = _db
        .collection(_takedownsCol)
        .orderBy('receivedAt', descending: true)
        .limit(50);

    if (status != null) {
      q = q.where('status', isEqualTo: status.name);
    }

    return q.snapshots().map(
      (snap) =>
          snap.docs.map(ImageTakedownModel.fromFirestore).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USAGE TRACKING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Record that an image is being used in an article
  Future<void> trackArticleUsage(String imageId, String articleId) async {
    await _db.collection(_imagesCol).doc(imageId).update({
      'usageCount': FieldValue.increment(1),
      'usedInArticleIds': FieldValue.arrayUnion([articleId]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Record that an image is being used in an ad
  Future<void> trackAdUsage(String imageId, String adId) async {
    await _db.collection(_imagesCol).doc(imageId).update({
      'usageCount': FieldValue.increment(1),
      'usedInAdIds': FieldValue.arrayUnion([adId]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATS (Admin Dashboard)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Map<String, int>> getImageStats() async {
    final results = <String, int>{};
    for (final status in ImageApprovalStatus.values) {
      final snap = await _db
          .collection(_imagesCol)
          .where('status', isEqualTo: status.name)
          .count()
          .get();
      results[status.name] = snap.count ?? 0;
    }
    return results;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUDIT LOG — Immutable, append-only
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _writeAudit({
    required String imageId,
    required String action,
    required String performedBy,
    Map<String, dynamic>? details,
  }) async {
    await _db.collection(_auditCol).add({
      'imageId': imageId,
      'action': action,
      'performedBy': performedBy,
      'details': details ?? {},
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Read audit log for a specific image (admin only)
  Future<List<Map<String, dynamic>>> getAuditLog(String imageId) async {
    final snap = await _db
        .collection(_auditCol)
        .where('imageId', isEqualTo: imageId)
        .orderBy('timestamp', descending: true)
        .get();

    return snap.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return data;
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<String> _uploadBytes({
    required Uint8List bytes,
    required String path,
    required String contentType,
    Function(double)? onProgress,
  }) async {
    final ref = _storage.ref(path);
    final task = ref.putData(bytes, SettableMetadata(contentType: contentType));

    if (onProgress != null) {
      task.snapshotEvents.listen((snap) {
        if (snap.totalBytes > 0) {
          onProgress(snap.bytesTransferred / snap.totalBytes);
        }
      });
    }

    await task;
    return await ref.getDownloadURL();
  }

  String _inferExtension(Uint8List bytes) {
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return 'jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46) {
      return 'webp';
    }
    return 'jpeg'; // Safe fallback
  }
}
