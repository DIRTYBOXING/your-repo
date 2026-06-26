// lib/features/image_gen/services/image_generation_service.dart
//
// AI Image Generation Service
// Supports Text-to-Image (DALL-E 3) and Image-to-Image (DALL-E 2 edits)
//
// SETUP: Pass your OpenAI API key at build time:
//   flutter run --dart-define=OPENAI_API_KEY=sk-your-key-here
//
// Or set it directly in _kApiKey below for development (do NOT commit real keys).

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ── Configure your API key ─────────────────────────────────────────────────
// Option A (recommended): pass via --dart-define at build/run time
// Option B: replace '' below with your key for quick dev testing only
const _kApiKey = String.fromEnvironment('OPENAI_API_KEY');

// ── Result model ───────────────────────────────────────────────────────────
class ImageGenResult {
  final bool success;
  final String? imageUrl;
  final Uint8List? imageBytes; // returned when b64_json is used
  final String? error;
  final String prompt;
  final ImageGenMode mode;

  const ImageGenResult({
    required this.success,
    required this.prompt,
    required this.mode,
    this.imageUrl,
    this.imageBytes,
    this.error,
  });

  bool get hasImage => imageUrl != null || imageBytes != null;
}

enum ImageGenMode { textToImage, imageToImage }

// ── Generation options ─────────────────────────────────────────────────────
enum ImageSize {
  square('1024x1024', '1:1'),
  portrait('1024x1792', '9:16'),
  landscape('1792x1024', '16:9');

  final String apiValue;
  final String label;
  const ImageSize(this.apiValue, this.label);
}

enum ImageStyle {
  vivid('vivid', 'Vivid'),
  natural('natural', 'Natural');

  final String apiValue;
  final String label;
  const ImageStyle(this.apiValue, this.label);
}

enum ImageQuality {
  standard('standard', 'Standard'),
  hd('hd', 'HD');

  final String apiValue;
  final String label;
  const ImageQuality(this.apiValue, this.label);
}

// ── Service ────────────────────────────────────────────────────────────────
class ImageGenerationService extends ChangeNotifier {
  bool _isLoading = false;
  ImageGenResult? _lastResult;
  String? _statusMessage;

  bool get isLoading => _isLoading;
  ImageGenResult? get lastResult => _lastResult;
  String? get statusMessage => _statusMessage;

  // ── Text → Image (DALL-E 3) ────────────────────────────────────────────
  Future<ImageGenResult> generateFromText({
    required String prompt,
    ImageSize size = ImageSize.square,
    ImageStyle style = ImageStyle.vivid,
    ImageQuality quality = ImageQuality.standard,
  }) async {
    _setLoading(true, 'Generating image from text…');

    try {
      if (_kApiKey.isEmpty) {
        // Demo mode: return a placeholder
        await Future.delayed(const Duration(seconds: 2));
        final result = ImageGenResult(
          success: true,
          prompt: prompt,
          mode: ImageGenMode.textToImage,
          imageUrl: 'assets/dfc_backgrounds/new_dfc_image_1.png',
        );
        _lastResult = result;
        _setLoading(
          false,
          'Done (demo mode — add OPENAI_API_KEY to enable real generation)',
        );
        return result;
      }

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/images/generations'),
        headers: {
          'Authorization': 'Bearer $_kApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'dall-e-3',
          'prompt': prompt,
          'n': 1,
          'size': size.apiValue,
          'style': style.apiValue,
          'quality': quality.apiValue,
          'response_format': 'url',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final url = data['data'][0]['url'] as String;
        final result = ImageGenResult(
          success: true,
          prompt: prompt,
          mode: ImageGenMode.textToImage,
          imageUrl: url,
        );
        _lastResult = result;
        _setLoading(false, 'Image generated!');
        return result;
      } else {
        final err = _parseError(response.body);
        final result = ImageGenResult(
          success: false,
          prompt: prompt,
          mode: ImageGenMode.textToImage,
          error: err,
        );
        _lastResult = result;
        _setLoading(false, 'Failed');
        return result;
      }
    } catch (e) {
      final result = ImageGenResult(
        success: false,
        prompt: prompt,
        mode: ImageGenMode.textToImage,
        error: e.toString(),
      );
      _lastResult = result;
      _setLoading(false, 'Error: $e');
      return result;
    }
  }

  // ── Image → Image (DALL-E 2 edits) ────────────────────────────────────
  // DALL-E 2 /edits requires a PNG with alpha (transparency) as the mask.
  // If no mask is provided the API treats the whole image as editable.
  Future<ImageGenResult> generateFromImage({
    required Uint8List imageBytes,
    required String prompt,
    ImageSize size = ImageSize.square,
  }) async {
    // DALL-E 2 image edits only support square sizes
    final apiSize = size == ImageSize.square ? '1024x1024' : '1024x1024';
    _setLoading(true, 'Transforming your image…');

    try {
      if (_kApiKey.isEmpty) {
        await Future.delayed(const Duration(seconds: 2));
        final result = ImageGenResult(
          success: true,
          prompt: prompt,
          mode: ImageGenMode.imageToImage,
          imageUrl: 'assets/dfc_backgrounds/dfc2_image_.png',
        );
        _lastResult = result;
        _setLoading(
          false,
          'Done (demo mode — add OPENAI_API_KEY to enable real generation)',
        );
        return result;
      }

      // Build multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.openai.com/v1/images/edits'),
      );
      request.headers['Authorization'] = 'Bearer $_kApiKey';
      request.fields['prompt'] = prompt;
      request.fields['n'] = '1';
      request.fields['size'] = apiSize;
      request.fields['response_format'] = 'url';
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'source.png',
        ),
      );

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final url = data['data'][0]['url'] as String;
        final result = ImageGenResult(
          success: true,
          prompt: prompt,
          mode: ImageGenMode.imageToImage,
          imageUrl: url,
        );
        _lastResult = result;
        _setLoading(false, 'Image transformed!');
        return result;
      } else {
        final err = _parseError(responseBody);
        final result = ImageGenResult(
          success: false,
          prompt: prompt,
          mode: ImageGenMode.imageToImage,
          error: err,
        );
        _lastResult = result;
        _setLoading(false, 'Failed');
        return result;
      }
    } catch (e) {
      final result = ImageGenResult(
        success: false,
        prompt: prompt,
        mode: ImageGenMode.imageToImage,
        error: e.toString(),
      );
      _lastResult = result;
      _setLoading(false, 'Error: $e');
      return result;
    }
  }

  void clearResult() {
    _lastResult = null;
    _statusMessage = null;
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  void _setLoading(bool loading, String? message) {
    _isLoading = loading;
    _statusMessage = message;
    notifyListeners();
  }

  String _parseError(String body) {
    try {
      final data = jsonDecode(body);
      return data['error']?['message'] ?? 'Unknown API error';
    } catch (_) {
      return 'API error (status code error)';
    }
  }
}
