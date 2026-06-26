import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../features/genie/genie_api_service.dart';
import '../models/event_manager_model.dart';
import 'gemini_image_service.dart';

class EventPromoCardPackage {
  final String title;
  final String date;
  final String style;
  final String border;
  final String overlay;
  final String hypeText;
  final String imagePrompt;
  final String? imageUrl;
  final DateTime createdAt;

  const EventPromoCardPackage({
    required this.title,
    required this.date,
    required this.style,
    required this.border,
    required this.overlay,
    required this.hypeText,
    required this.imagePrompt,
    required this.createdAt,
    this.imageUrl,
  });
}

class EventPromoCardService with ChangeNotifier {
  bool _busy = false;
  String? _lastError;
  EventPromoCardPackage? _latestCard;

  bool get busy => _busy;
  String? get lastError => _lastError;
  EventPromoCardPackage? get latestCard => _latestCard;

  Future<EventPromoCardPackage> generateEventPromoCard({
    required String eventTitle,
    required String eventDate,
    required List<FightCardEvent> lineup,
    String? promotionTone,
    String? posterTemplate,
    List<Uint8List>? referenceImages,
    List<String>? referenceImageNotes,
    String? posterMode,
  }) async {
    _busy = true;
    _lastError = null;
    notifyListeners();

    try {
      final combo = await GenieApiService.generateCreativeCombo(
        description: '$eventTitle $eventDate',
      );

      final topFights = lineup
          .take(3)
          .map((fight) => '${fight.fighterA} vs ${fight.fighterB}')
          .join(' | ');

      final prompt = _buildPosterPrompt(
        eventTitle: eventTitle,
        eventDate: eventDate,
        style: combo.suggestedStyle,
        promotionTone: promotionTone,
        posterTemplate: posterTemplate,
        topFights: topFights,
        referenceImageNotes: referenceImageNotes,
        posterMode: posterMode,
      );

      final generatedImageUrl = await _generateWithNanoBanna(
        prompt: prompt,
        style: combo.suggestedStyle,
        referenceImages: referenceImages,
        referenceImageNotes: referenceImageNotes,
        posterMode: posterMode,
      );

      final package = EventPromoCardPackage(
        title: eventTitle,
        date: eventDate,
        style: combo.suggestedStyle,
        border: combo.border,
        overlay: combo.overlay,
        hypeText: combo.hypeText,
        imagePrompt: prompt,
        imageUrl: generatedImageUrl,
        createdAt: DateTime.now(),
      );

      _latestCard = package;
      return package;
    } catch (e) {
      _lastError = e.toString();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  String _buildPosterPrompt({
    required String eventTitle,
    required String eventDate,
    required String style,
    required String topFights,
    String? promotionTone,
    String? posterTemplate,
    List<String>? referenceImageNotes,
    String? posterMode,
  }) {
    final tone = (promotionTone == null || promotionTone.trim().isEmpty)
        ? 'high-energy professional fight night'
        : promotionTone.trim();

    final templateLine =
        (posterTemplate == null || posterTemplate.trim().isEmpty)
        ? ''
        : 'Template style: ${posterTemplate.trim()}. ';

    final modeLine = (posterMode == null || posterMode.trim().isEmpty)
        ? ''
        : 'Poster layout mode: ${posterMode.trim()}. ';

    final refLine = (referenceImageNotes == null || referenceImageNotes.isEmpty)
        ? ''
        : 'Reference photos provided. Notes: ${referenceImageNotes.where((e) => e.trim().isNotEmpty).join(' | ')}. ';

    return 'Create a premium MMA/boxing event poster for "$eventTitle" on "$eventDate". '
        'Top fights: $topFights. Visual style: $style. Tone: $tone. '
        '$templateLine'
        '$modeLine'
        '$refLine'
        'Use bold typography zones, sponsor-safe layout, dramatic arena lighting. '
        'If reference photos are provided, keep likeness consistent and do not invent extra fighters. '
        'No gore, no hateful content.';
  }

  Future<String?> _generateWithNanoBanna({
    required String prompt,
    required String style,
    List<Uint8List>? referenceImages,
    List<String>? referenceImageNotes,
    String? posterMode,
  }) async {
    const endpoint = String.fromEnvironment(
      'NANO_BANNA_ENDPOINT',
    );
    const apiKey = String.fromEnvironment(
      'NANO_BANNA_API_KEY',
    );

    // ── Try custom Nano Banna endpoint first ─────────────────────────
    if (endpoint.isNotEmpty) {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (apiKey.isNotEmpty) {
        headers['Authorization'] = 'Bearer $apiKey';
      }

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: headers,
            body: jsonEncode({
              'prompt': prompt,
              'style': style,
              'size': '1080x1350',
              'safeMode': true,
              if (posterMode != null && posterMode.trim().isNotEmpty)
                'posterMode': posterMode.trim(),
              if (referenceImages != null && referenceImages.isNotEmpty)
                'referenceImages': referenceImages
                    .map(base64Encode)
                    .toList(growable: false),
              if (referenceImageNotes != null && referenceImageNotes.isNotEmpty)
                'referenceImageNotes': referenceImageNotes
                    .where((e) => e.trim().isNotEmpty)
                    .toList(growable: false),
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Nano Banna request failed (${response.statusCode})');
      }

      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        final direct = data['imageUrl'] ?? data['url'];
        if (direct is String && direct.isNotEmpty) {
          return direct;
        }

        final items = data['data'];
        if (items is List && items.isNotEmpty) {
          final first = items.first;
          if (first is Map<String, dynamic>) {
            final nested = first['url'] ?? first['imageUrl'];
            if (nested is String && nested.isNotEmpty) {
              return nested;
            }
          }
        }
      }

      return null;
    }

    // ── Fallback: use Gemini API for poster generation ───────────────
    final gemini = GeminiImageService();
    if (!gemini.isConfigured) {
      return null; // No Gemini key either — widget render fallback
    }

    final result = await gemini.generatePoster(
      prompt: prompt,
      referenceImages: referenceImages,
      referenceImageNotes: referenceImageNotes,
    );

    if (result.success && result.hasImage) {
      // Convert bytes to a data URI so the caller can display it
      final b64 = base64Encode(result.imageBytes!);
      final mime = result.mimeType ?? 'image/png';
      return 'data:$mime;base64,$b64';
    }

    return null;
  }
}
