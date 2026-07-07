import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';

/// Client for the Octane promo-video rendering pipeline.
/// Queues an async render job via Cloud Functions and returns the
/// resulting job/video reference once accepted.
class OctaneService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Queue a promo video render job for [eventId] using [images] as the
  /// source stills and [theme] as the visual style preset.
  /// Returns the render job's video URL (or job ID) once queued, or null
  /// if the request failed.
  Future<String?> generatePromoVideo({
    required String eventId,
    required List<File> images,
    required String theme,
  }) async {
    try {
      final callable = _functions.httpsCallable('queueOctaneRender');
      final result = await callable.call({
        'eventId': eventId,
        'imageCount': images.length,
        'theme': theme,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return data['videoUrl'] as String? ?? data['jobId'] as String?;
    } catch (e) {
      return null;
    }
  }
}
