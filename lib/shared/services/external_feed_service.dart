import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class ExternalFeedResult {
  final bool success;
  final String? errorMessage;
  final String? postId;

  ExternalFeedResult({required this.success, this.errorMessage, this.postId});
}

/// Service for cross-posting DFC content to external platforms.
///
/// INTEGRATION STATUS:
/// - Facebook: Requires App Review + pages_manage_posts permission
/// - YouTube: Requires YouTube Data API v3 + OAuth consent
/// - Instagram: Requires Instagram Graph API via Facebook Business
///
/// All integrations route through Cloud Functions for API key security.
class ExternalFeedService {
  static final _functions = FirebaseFunctions.instanceFor(
    region: 'australia-southeast1',
  );

  static Future<ExternalFeedResult> sendToPlatform({
    required String platform,
    required String region,
    required Map<String, dynamic> eventData,
  }) async {
    try {
      switch (platform) {
        case 'Facebook':
          return await _sendToFacebook(eventData, region);
        case 'YouTube':
          return await _sendToYouTube(eventData, region);
        case 'Instagram':
          return await _sendToInstagram(eventData, region);
        default:
          return ExternalFeedResult(
            success: false,
            errorMessage: 'Platform "$platform" not supported',
          );
      }
    } catch (e) {
      debugPrint('[ExternalFeed] Error posting to $platform: $e');
      return ExternalFeedResult(success: false, errorMessage: e.toString());
    }
  }

  /// Facebook Graph API integration via Cloud Function.
  /// Requires: FACEBOOK_PAGE_ID, FACEBOOK_ACCESS_TOKEN in functions/.env
  static Future<ExternalFeedResult> _sendToFacebook(
    Map<String, dynamic> eventData,
    String region,
  ) async {
    try {
      final callable = _functions.httpsCallable('postToFacebook');
      final result = await callable.call<Map<String, dynamic>>({
        'eventData': eventData,
        'region': region,
      });
      final postId = result.data['postId'] as String?;
      return ExternalFeedResult(success: true, postId: postId);
    } catch (e) {
      debugPrint('[ExternalFeed] Facebook CF not configured: $e');
      // Graceful fallback — log intent but don't block
      return ExternalFeedResult(
        success: false,
        errorMessage: 'Facebook integration pending setup',
      );
    }
  }

  /// YouTube Data API v3 integration via Cloud Function.
  /// Requires: YOUTUBE_API_KEY, YOUTUBE_CHANNEL_ID in functions/.env
  static Future<ExternalFeedResult> _sendToYouTube(
    Map<String, dynamic> eventData,
    String region,
  ) async {
    try {
      final callable = _functions.httpsCallable('postToYouTube');
      final result = await callable.call<Map<String, dynamic>>({
        'eventData': eventData,
        'region': region,
      });
      final postId = result.data['videoId'] as String?;
      return ExternalFeedResult(success: true, postId: postId);
    } catch (e) {
      debugPrint('[ExternalFeed] YouTube CF not configured: $e');
      return ExternalFeedResult(
        success: false,
        errorMessage: 'YouTube integration pending setup',
      );
    }
  }

  /// Instagram Graph API integration via Cloud Function.
  /// Requires: INSTAGRAM_BUSINESS_ID, FACEBOOK_ACCESS_TOKEN in functions/.env
  static Future<ExternalFeedResult> _sendToInstagram(
    Map<String, dynamic> eventData,
    String region,
  ) async {
    try {
      final callable = _functions.httpsCallable('postToInstagram');
      final result = await callable.call<Map<String, dynamic>>({
        'eventData': eventData,
        'region': region,
      });
      final postId = result.data['mediaId'] as String?;
      return ExternalFeedResult(success: true, postId: postId);
    } catch (e) {
      debugPrint('[ExternalFeed] Instagram CF not configured: $e');
      return ExternalFeedResult(
        success: false,
        errorMessage: 'Instagram integration pending setup',
      );
    }
  }
}
