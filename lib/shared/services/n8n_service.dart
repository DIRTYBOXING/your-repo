import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Service that triggers content-brain workflows through Firebase Functions.
///
/// The app is intent-only. Firebase Functions owns routing to n8n, native
/// fallback execution, and workflow state updates.
class N8nService {
  N8nService()
    : _functions = FirebaseFunctions.instanceFor(
        region: 'australia-southeast1',
      );

  final FirebaseFunctions _functions;

  static bool isValidRemoteAssetUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) {
      return false;
    }

    return uri.scheme == 'https' || uri.scheme == 'http';
  }

  static List<String> normalizeRemoteAssetUrls(Iterable<String?> rawUrls) {
    final normalizedUrls = <String>[];
    final seenUrls = <String>{};

    for (final rawUrl in rawUrls) {
      final url = (rawUrl ?? '').trim();
      if (!isValidRemoteAssetUrl(url) || !seenUrls.add(url)) {
        continue;
      }
      normalizedUrls.add(url);
    }

    return normalizedUrls;
  }

  static String _firstValidAssetUrl(Iterable<String?> rawUrls) {
    for (final rawUrl in rawUrls) {
      final url = (rawUrl ?? '').trim();
      if (isValidRemoteAssetUrl(url)) {
        return url;
      }
    }

    return '';
  }

  static String _inferAssetType(String url) {
    final lowerUrl = url.toLowerCase();
    if (RegExp(r'\.svg(?:$|\?)').hasMatch(lowerUrl)) {
      return 'svg';
    }
    if (RegExp(r'\.(?:mp4|mov|m4v|webm|m3u8)(?:$|\?)').hasMatch(lowerUrl)) {
      return 'video';
    }
    return 'image';
  }

  Map<String, dynamic>? _buildMediaPlan({
    String? posterUrl,
    List<String>? assetUrls,
    Map<String, dynamic>? eventData,
  }) {
    final eventPayload = Map<String, dynamic>.from(eventData ?? const {});
    final eventMediaUrls = eventPayload['mediaUrls'] is List
        ? List<String?>.from(eventPayload['mediaUrls'] as List)
        : const <String?>[];

    final normalizedPosterUrl = _firstValidAssetUrl([
      posterUrl,
      eventPayload['posterUrl']?.toString(),
    ]);
    final normalizedAssetUrls = normalizeRemoteAssetUrls([
      normalizedPosterUrl,
      ...(assetUrls ?? const <String>[]),
      eventPayload['imageUrl']?.toString(),
      eventPayload['thumbnailUrl']?.toString(),
      ...eventMediaUrls,
    ]);

    if (normalizedPosterUrl.isEmpty && normalizedAssetUrls.isEmpty) {
      return null;
    }

    final primaryAssetUrl = normalizedAssetUrls.isNotEmpty
        ? normalizedAssetUrls.first
        : '';
    final primaryPreviewAssetUrl = _firstValidAssetUrl([
      normalizedPosterUrl,
      primaryAssetUrl,
    ]);
    final primaryPublishableAssetUrl = _firstValidAssetUrl(
      normalizedAssetUrls.where((url) => _inferAssetType(url) != 'svg'),
    );
    final thumbnailUrl = _firstValidAssetUrl([
      eventPayload['thumbnailUrl']?.toString(),
      normalizedPosterUrl,
      primaryPreviewAssetUrl,
      primaryPublishableAssetUrl,
    ]);

    return {
      if (normalizedPosterUrl.isNotEmpty) 'posterUrl': normalizedPosterUrl,
      if (primaryAssetUrl.isNotEmpty) 'primaryAssetUrl': primaryAssetUrl,
      if (primaryPreviewAssetUrl.isNotEmpty)
        'primaryPreviewAssetUrl': primaryPreviewAssetUrl,
      if (primaryPublishableAssetUrl.isNotEmpty)
        'primaryPublishableAssetUrl': primaryPublishableAssetUrl,
      if (thumbnailUrl.isNotEmpty) 'thumbnailUrl': thumbnailUrl,
      if (normalizedAssetUrls.isNotEmpty) 'assetUrls': normalizedAssetUrls,
      if (normalizedAssetUrls.isNotEmpty) 'mediaUrls': normalizedAssetUrls,
      if (normalizedAssetUrls.isNotEmpty)
        'assets': [
          for (var index = 0; index < normalizedAssetUrls.length; index++)
            {
              'url': normalizedAssetUrls[index],
              'role':
                  normalizedPosterUrl.isNotEmpty &&
                      normalizedAssetUrls[index] == normalizedPosterUrl
                  ? 'poster'
                  : index == 0
                  ? 'primary'
                  : 'supporting',
              'type': _inferAssetType(normalizedAssetUrls[index]),
              'order': index + 1,
            },
        ],
    };
  }

  Future<Map<String, dynamic>?> triggerContentBrain({
    required String webInput,
    String platform = 'all',
    String postType = 'text',
    String brandTone = 'hype',
    String audienceType = 'fans',
    String niche = 'general',
    String objective = 'engagement',
    bool autoPublish = false,
    bool autoDistribute = false,
    Map<String, dynamic>? eventData,
    String? posterUrl,
    List<String>? assetUrls,
  }) async {
    try {
      final mergedEventData = Map<String, dynamic>.from(eventData ?? const {});
      final mediaPlan = _buildMediaPlan(
        posterUrl: posterUrl,
        assetUrls: assetUrls,
        eventData: mergedEventData,
      );

      if (mediaPlan != null) {
        final plannedAssetUrls = mediaPlan['assetUrls'] is List
            ? List<String>.from(mediaPlan['assetUrls'] as List)
            : const <String>[];
        final plannedPosterUrl = mediaPlan['posterUrl']?.toString() ?? '';
        final plannedPrimaryAssetUrl =
            mediaPlan['primaryAssetUrl']?.toString() ?? '';
        final plannedThumbnailUrl = mediaPlan['thumbnailUrl']?.toString() ?? '';

        if (plannedPosterUrl.isNotEmpty) {
          mergedEventData['posterUrl'] = plannedPosterUrl;
        }
        if (plannedPrimaryAssetUrl.isNotEmpty) {
          mergedEventData['imageUrl'] ??= plannedPrimaryAssetUrl;
        }
        if (plannedThumbnailUrl.isNotEmpty) {
          mergedEventData['thumbnailUrl'] ??= plannedThumbnailUrl;
        }
        if (plannedAssetUrls.isNotEmpty) {
          mergedEventData['mediaUrls'] = plannedAssetUrls;
          mergedEventData['assetUrls'] = plannedAssetUrls;
        }
      }

      final callable = _functions.httpsCallable('triggerN8N');
      final result = await callable.call({
        'workflowType': 'content_brain',
        'payload': {
          'webInput': webInput,
          'platform': platform,
          'postType': postType,
          'brandTone': brandTone,
          'audienceType': audienceType,
          'niche': niche,
          'objective': objective,
          'autoPublish': autoPublish,
          'autoDistribute': autoDistribute,
          'eventData': mergedEventData,
          'mediaPlan': mediaPlan ?? const <String, dynamic>{},
        },
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      if (data['status'] == 'error') {
        debugPrint(
          'Content brain trigger failed: ${data['message'] ?? 'unknown error'}',
        );
        return null;
      }

      return data;
    } catch (e) {
      debugPrint('Content brain trigger ERROR: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getStreamingDoctrine({
    String requestedPlatform = 'all',
    String businessObjective = 'engagement',
    String monetizationModel = 'ppv',
    String latencySensitivity = 'standard',
    String audienceScale = 'global',
    String rightsTier = 'premium',
    String sport = 'combat',
  }) async {
    try {
      final callable = _functions.httpsCallable('streamingDoctrineV1');
      final result = await callable.call({
        'requestedPlatform': requestedPlatform,
        'businessObjective': businessObjective,
        'monetizationModel': monetizationModel,
        'latencySensitivity': latencySensitivity,
        'audienceScale': audienceScale,
        'rightsTier': rightsTier,
        'sport': sport,
      });

      return Map<String, dynamic>.from(result.data as Map);
    } catch (e) {
      debugPrint('Streaming doctrine fetch ERROR: $e');
      return null;
    }
  }

  /// Trigger the AI Content Brain to generate promotional content for a PPV event.
  ///
  /// Returns the response body from the backend workflow runner or null on failure.
  Future<Map<String, dynamic>?> promoteEventWithAI({
    required String eventTitle,
    required List<String> fighters,
    required String sport,
    String? promotion,
    String? eventId,
    String? posterUrl,
    List<String>? assetUrls,
    String brandTone = 'hype',
    String platform = 'all',
    String objective = 'engagement',
  }) async {
    return triggerContentBrain(
      webInput:
          '🔥 $eventTitle — ${fighters.join(" vs ")}! $sport action live on DFC.',
      platform: platform,
      brandTone: brandTone,
      niche: sport.toLowerCase(),
      objective: objective,
      eventData: {
        'eventId': eventId ?? 'ppv_${DateTime.now().millisecondsSinceEpoch}',
        'eventName': eventTitle,
        'title': eventTitle,
        'fighters': fighters,
        'sport': sport,
        'promotion': promotion,
      },
      posterUrl: posterUrl,
      assetUrls: assetUrls,
    );
  }
}
