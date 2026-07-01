import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_library_item.dart';

/// AutoCaptionService — generates hype captions and SEO descriptions for DFC media.
/// Structured for Gemini Flash integration. Wire [_geminiApiKey] via dart-define or
/// Firebase Remote Config before enabling [useAi].
class AutoCaptionService {
  static final AutoCaptionService _instance = AutoCaptionService._internal();
  factory AutoCaptionService() => _instance;
  AutoCaptionService._internal();

  /// Set to true when Gemini API key is configured, or it auto-enables
  /// when GEMINI_API_KEY is passed via --dart-define.
  bool useAi = _geminiApiKey.isNotEmpty;

  static const _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns a short hype caption for a media item.
  /// Falls back to template-based generation when [useAi] is false.
  Future<String> generateHypeCaption(MediaLibraryItem item) async {
    if (useAi) {
      return _geminiCaption(item, mode: 'hype');
    }
    return _templateHypeCaption(item);
  }

  /// Returns an SEO-optimised description for a media item.
  Future<String> generateSeoDescription(MediaLibraryItem item) async {
    if (useAi) {
      return _geminiCaption(item, mode: 'seo');
    }
    return _templateSeoDescription(item);
  }

  /// Generates both hype caption and SEO description in one call.
  Future<CaptionResult> generateAll(MediaLibraryItem item) async {
    final hype = await generateHypeCaption(item);
    final seo = await generateSeoDescription(item);
    return CaptionResult(hypeCaption: hype, seoDescription: seo);
  }

  // ── Template generation (no API required) ─────────────────────────────────

  String _templateHypeCaption(MediaLibraryItem item) {
    final tags = item.tags.isNotEmpty ? item.tags : ['combat sports'];
    final subject = tags.first;
    final typeStr = item.type.toLowerCase();

    switch (typeStr) {
      case 'highlight':
        return '🔥 $subject — This is what ELITE looks like. #DFC #CombatSports';
      case 'training':
        return '💪 $subject putting in the work. Champions are made here. #DFC';
      case 'promo':
        return '⚡ $subject is ready. Are you? #DFC #FightNight';
      case 'interview':
        return '🎙️ $subject speaks — straight facts, no filter. #DFC';
      case 'event':
        return '🥊 $subject — Fight night incoming. Don\'t miss it. #DFC';
      default:
        return '🔥 $subject — Global combat sports. Only on DFC. #DataFightCentral';
    }
  }

  String _templateSeoDescription(MediaLibraryItem item) {
    final tags = item.tags.isNotEmpty ? item.tags : ['combat sports'];
    final subject = tags.first;
    final platform = item.platform;
    final type = item.type;

    return '$type content featuring $subject. '
        'Originally distributed via $platform. '
        'Track more ${tags.join(", ")} content on Data Fight Central — '
        'the global combat sports platform.';
  }

  // ── Gemini integration ─────────────────────────────────────────────────────

  /// Calls Gemini Flash to generate a caption. Falls back to template on failure.
  Future<String> _geminiCaption(
    MediaLibraryItem item, {
    required String mode,
  }) async {
    if (_geminiApiKey.isEmpty) {
      return mode == 'hype'
          ? _templateHypeCaption(item)
          : _templateSeoDescription(item);
    }

    final tags = item.tags.isNotEmpty ? item.tags.join(', ') : 'combat sports';
    final prompt = mode == 'hype'
        ? 'Write a 1-sentence hype caption for a ${item.type} featuring $tags. '
            'Max 120 chars. Combat sports tone. Include 2-3 relevant hashtags.'
        : 'Write an SEO meta description for a ${item.type} about $tags. '
            'Max 160 chars. Professional combat sports tone.';

    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        'gemini-2.0-flash:generateContent?key=$_geminiApiKey',
      );
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'maxOutputTokens': 80,
                'temperature': mode == 'hype' ? 0.9 : 0.4,
              },
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts =
              (candidates[0]['content']['parts'] as List<dynamic>?) ?? [];
          if (parts.isNotEmpty) {
            return (parts[0]['text'] as String).trim();
          }
        }
      }
    } catch (_) {
      // Fall through to template
    }

    return mode == 'hype'
        ? _templateHypeCaption(item)
        : _templateSeoDescription(item);
  }
}

/// Result bundle from [AutoCaptionService.generateAll].
class CaptionResult {
  final String hypeCaption;
  final String seoDescription;

  const CaptionResult({
    required this.hypeCaption,
    required this.seoDescription,
  });
}
