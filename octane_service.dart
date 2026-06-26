import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC OCTANE VIDEO ENGINE
/// Uploads raw assets to Firebase Storage and triggers Cloud Video Rendering.
/// ═══════════════════════════════════════════════════════════════════════════
class OctaneService {
  final _storage = FirebaseStorage.instance;
  final _functions = FirebaseFunctions.instance;

  /// Uploads images and requests a generated video
  Future<String?> generatePromoVideo({
    required String eventId,
    required List<File> images,
    required String theme, // e.g., 'neon_underground', 'samurai_spirit'
  }) async {
    try {
      List<String> uploadedUrls = [];

      // 1. Upload raw images to Firebase Storage
      for (int i = 0; i < images.length; i++) {
        final ref = _storage.ref().child('octane_raw/$eventId/img_$i.jpg');
        final uploadTask = await ref.putFile(images[i]);
        final url = await uploadTask.ref.getDownloadURL();
        uploadedUrls.add(url);
      }

      debugPrint(
        '✅ Octane: Successfully uploaded ${uploadedUrls.length} assets. Triggering render...',
      );

      // 2. Call the Cloud Function to initiate rendering
      final callable = _functions.httpsCallable('renderOctanePromo');
      final result = await callable.call({
        'eventId': eventId,
        'theme': theme,
        'imageUrls': uploadedUrls,
      });

      final videoUrl = result.data['videoUrl'] as String?;
      debugPrint('🎬 Octane: Render complete! Video URL: $videoUrl');

      return videoUrl;
    } catch (e) {
      debugPrint('❌ Octane Render Failed: $e');
      return null;
    }
  }
}
