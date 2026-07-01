// lib/shared/services/gemini_image_service.dart
//
// Gemini Image Generation Service
// Uses Google Gemini API for text-to-image and image-to-image generation.
//
// SETUP: Pass your Gemini API key at build time:
//   flutter run --dart-define=GEMINI_API_KEY=your-key-here
//
// Models supported:
//   - gemini-2.0-flash-preview-image-generation  (default, fast)
//   - imagen-3.0-generate-002  (higher quality, text-to-image only)

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ── API key from dart-define ───────────────────────────────────────────────
const _kGeminiKey = String.fromEnvironment('GEMINI_API_KEY');

// ── Base URL ───────────────────────────────────────────────────────────────
const _kBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';

// ── Available models ───────────────────────────────────────────────────────
enum GeminiImageModel {
  flash('gemini-2.0-flash-preview-image-generation', 'Gemini Flash (fast)'),
  imagen('imagen-3.0-generate-002', 'Imagen 3 (quality)');

  final String id;
  final String label;
  const GeminiImageModel(this.id, this.label);
}

// ── Aspect ratios ──────────────────────────────────────────────────────────
enum GeminiAspectRatio {
  square('1:1', '1:1'),
  portrait('9:16', '9:16'),
  landscape('16:9', '16:9'),
  poster('3:4', '3:4');

  final String apiValue;
  final String label;
  const GeminiAspectRatio(this.apiValue, this.label);
}

// ── Result ─────────────────────────────────────────────────────────────────
class GeminiImageResult {
  final bool success;
  final Uint8List? imageBytes;
  final String? mimeType;
  final String? error;
  final String prompt;

  const GeminiImageResult({
    required this.success,
    required this.prompt,
    this.imageBytes,
    this.mimeType,
    this.error,
  });

  bool get hasImage => imageBytes != null && imageBytes!.isNotEmpty;
}

// ── Service ────────────────────────────────────────────────────────────────
class GeminiImageService with ChangeNotifier {
  bool _busy = false;
  String? _status;
  GeminiImageResult? _lastResult;

  bool get busy => _busy;
  String? get status => _status;
  GeminiImageResult? get lastResult => _lastResult;
  bool get isConfigured => _kGeminiKey.isNotEmpty;

  // ── Text → Image (Gemini Flash with image output) ─────────────────────
  Future<GeminiImageResult> generateFromText({
    required String prompt,
    GeminiImageModel model = GeminiImageModel.flash,
    GeminiAspectRatio aspect = GeminiAspectRatio.square,
  }) async {
    _setStatus(true, 'Generating image with Gemini…');

    if (_kGeminiKey.isEmpty) {
      final result = GeminiImageResult(
        success: false,
        prompt: prompt,
        error:
            'GEMINI_API_KEY not configured. '
            'Run with --dart-define=GEMINI_API_KEY=your-key',
      );
      _lastResult = result;
      _setStatus(false, 'No API key');
      return result;
    }

    try {
      if (model == GeminiImageModel.imagen) {
        return await _generateWithImagen(prompt: prompt, aspect: aspect);
      }
      return await _generateWithGeminiFlash(
        prompt: prompt,
        model: model,
        aspect: aspect,
      );
    } catch (e) {
      final result = GeminiImageResult(
        success: false,
        prompt: prompt,
        error: e.toString(),
      );
      _lastResult = result;
      _setStatus(false, 'Error: $e');
      return result;
    }
  }

  // ── Image → Image (Gemini Flash with reference image) ─────────────────
  Future<GeminiImageResult> generateFromImage({
    required Uint8List imageBytes,
    required String prompt,
    GeminiAspectRatio aspect = GeminiAspectRatio.square,
  }) async {
    _setStatus(true, 'Transforming image with Gemini…');

    if (_kGeminiKey.isEmpty) {
      final result = GeminiImageResult(
        success: false,
        prompt: prompt,
        error: 'GEMINI_API_KEY not configured.',
      );
      _lastResult = result;
      _setStatus(false, 'No API key');
      return result;
    }

    try {
      final url = Uri.parse(
        '$_kBaseUrl/models/${GeminiImageModel.flash.id}:generateContent?key=$_kGeminiKey',
      );

      final body = {
        'contents': [
          {
            'parts': [
              {
                'inlineData': {
                  'mimeType': 'image/png',
                  'data': base64Encode(imageBytes),
                },
              },
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'responseModalities': ['TEXT', 'IMAGE'],
          'responseMimeType': 'text/plain',
        },
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      return _parseGeminiResponse(response, prompt);
    } catch (e) {
      final result = GeminiImageResult(
        success: false,
        prompt: prompt,
        error: e.toString(),
      );
      _lastResult = result;
      _setStatus(false, 'Error: $e');
      return result;
    }
  }

  // ── Generate poster with reference images (for PosterBoy) ─────────────
  Future<GeminiImageResult> generatePoster({
    required String prompt,
    List<Uint8List>? referenceImages,
    List<String>? referenceImageNotes,
    GeminiAspectRatio aspect = GeminiAspectRatio.poster,
  }) async {
    _setStatus(true, 'Generating poster with Gemini…');

    if (_kGeminiKey.isEmpty) {
      final result = GeminiImageResult(
        success: false,
        prompt: prompt,
        error: 'GEMINI_API_KEY not configured.',
      );
      _lastResult = result;
      _setStatus(false, 'No API key');
      return result;
    }

    try {
      final parts = <Map<String, dynamic>>[];

      // Add reference images inline
      if (referenceImages != null) {
        for (int i = 0; i < referenceImages.length; i++) {
          parts.add({
            'inlineData': {
              'mimeType': 'image/png',
              'data': base64Encode(referenceImages[i]),
            },
          });
          final note =
              (referenceImageNotes != null &&
                  i < referenceImageNotes.length &&
                  referenceImageNotes[i].trim().isNotEmpty)
              ? referenceImageNotes[i].trim()
              : 'Reference image ${i + 1}';
          parts.add({'text': note});
        }
      }

      // Add the main prompt last
      parts.add({'text': prompt});

      final url = Uri.parse(
        '$_kBaseUrl/models/${GeminiImageModel.flash.id}:generateContent?key=$_kGeminiKey',
      );

      final body = {
        'contents': [
          {'parts': parts},
        ],
        'generationConfig': {
          'responseModalities': ['TEXT', 'IMAGE'],
          'responseMimeType': 'text/plain',
        },
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 90));

      return _parseGeminiResponse(response, prompt);
    } catch (e) {
      final result = GeminiImageResult(
        success: false,
        prompt: prompt,
        error: e.toString(),
      );
      _lastResult = result;
      _setStatus(false, 'Error: $e');
      return result;
    }
  }

  // ── Imagen 3 (higher quality text-to-image) ──────────────────────────
  Future<GeminiImageResult> _generateWithImagen({
    required String prompt,
    GeminiAspectRatio aspect = GeminiAspectRatio.square,
  }) async {
    final url = Uri.parse(
      '$_kBaseUrl/models/${GeminiImageModel.imagen.id}:predict?key=$_kGeminiKey',
    );

    final body = {
      'instances': [
        {'prompt': prompt},
      ],
      'parameters': {
        'sampleCount': 1,
        'aspectRatio': aspect.apiValue,
        'personGeneration': 'allow_adult',
      },
    };

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final predictions = data['predictions'];
      if (predictions is List && predictions.isNotEmpty) {
        final b64 = predictions[0]['bytesBase64Encoded'];
        final mime = predictions[0]['mimeType'] ?? 'image/png';
        if (b64 is String && b64.isNotEmpty) {
          final bytes = base64Decode(b64);
          final result = GeminiImageResult(
            success: true,
            prompt: prompt,
            imageBytes: Uint8List.fromList(bytes),
            mimeType: mime,
          );
          _lastResult = result;
          _setStatus(false, 'Image generated with Imagen 3!');
          return result;
        }
      }
      final result = GeminiImageResult(
        success: false,
        prompt: prompt,
        error: 'No image in Imagen response',
      );
      _lastResult = result;
      _setStatus(false, 'Imagen returned no image');
      return result;
    }

    final err = _parseApiError(response.body);
    final result = GeminiImageResult(
      success: false,
      prompt: prompt,
      error: err,
    );
    _lastResult = result;
    _setStatus(false, 'Imagen failed');
    return result;
  }

  // ── Gemini Flash with image output modality ──────────────────────────
  Future<GeminiImageResult> _generateWithGeminiFlash({
    required String prompt,
    GeminiImageModel model = GeminiImageModel.flash,
    GeminiAspectRatio aspect = GeminiAspectRatio.square,
  }) async {
    final url = Uri.parse(
      '$_kBaseUrl/models/${model.id}:generateContent?key=$_kGeminiKey',
    );

    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'responseModalities': ['TEXT', 'IMAGE'],
        'responseMimeType': 'text/plain',
      },
    };

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    return _parseGeminiResponse(response, prompt);
  }

  // ── Parse Gemini generateContent response ────────────────────────────
  GeminiImageResult _parseGeminiResponse(
    http.Response response,
    String prompt,
  ) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'];
      if (candidates is List && candidates.isNotEmpty) {
        final parts = candidates[0]['content']?['parts'];
        if (parts is List) {
          for (final part in parts) {
            if (part is Map<String, dynamic> &&
                part.containsKey('inlineData')) {
              final inlineData = part['inlineData'];
              final b64 = inlineData['data'];
              final mime = inlineData['mimeType'] ?? 'image/png';
              if (b64 is String && b64.isNotEmpty) {
                final bytes = base64Decode(b64);
                final result = GeminiImageResult(
                  success: true,
                  prompt: prompt,
                  imageBytes: Uint8List.fromList(bytes),
                  mimeType: mime,
                );
                _lastResult = result;
                _setStatus(false, 'Image generated with Gemini!');
                return result;
              }
            }
          }
        }
      }

      // Model responded but no image found in parts
      final result = GeminiImageResult(
        success: false,
        prompt: prompt,
        error:
            'Gemini returned text but no image. '
            'Try a more descriptive prompt.',
      );
      _lastResult = result;
      _setStatus(false, 'No image in response');
      return result;
    }

    final err = _parseApiError(response.body);
    final result = GeminiImageResult(
      success: false,
      prompt: prompt,
      error: err,
    );
    _lastResult = result;
    _setStatus(false, 'Generation failed');
    return result;
  }

  // ── Helpers ──────────────────────────────────────────────────────────
  void _setStatus(bool busy, String? msg) {
    _busy = busy;
    _status = msg;
    notifyListeners();
  }

  void clear() {
    _lastResult = null;
    _status = null;
    notifyListeners();
  }

  String _parseApiError(String body) {
    try {
      final data = jsonDecode(body);
      final err = data['error'];
      if (err is Map<String, dynamic>) {
        return err['message'] ?? 'Unknown Gemini API error';
      }
      return 'Gemini API error';
    } catch (_) {
      return 'Gemini API error (could not parse response)';
    }
  }
}
