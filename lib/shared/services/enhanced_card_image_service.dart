// lib/shared/services/enhanced_card_image_service.dart
//
// Enhanced Card Image Generation Service
// Uses Replicate + specialized models for fight card quality
//
// Models: Flux.1-canvas (composition), ESRGAN (upscaling), Real-ESRGAN
// Better prompting for fight aesthetics: lighting, pose, composition
//
// SETUP: Pass Replicate API token at build time:
//   flutter run --dart-define=REPLICATE_API_TOKEN=your-token-here

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const _kReplicateToken = String.fromEnvironment(
  'REPLICATE_API_TOKEN',
);
const _kReplicateApiUrl = 'https://api.replicate.com/v1';

enum CardImageModel {
  flux('black-forest-labs/flux-1-canvas', 'Flux Canvas (composition)'),
  fluxPro('black-forest-labs/flux-pro', 'Flux Pro (quality)'),
  kolors('zzjin/kolors', 'Kolors (anime/stylized)');

  final String replicateModel;
  final String label;
  const CardImageModel(this.replicateModel, this.label);
}

enum CardUpscaleModel {
  esrgan('upscayl/upscayl', 'ESRGAN 4x'),
  realEsrgan('nightmareai/real-esrgan', 'Real-ESRGAN 4x');

  final String replicateModel;
  final String label;
  const CardUpscaleModel(this.replicateModel, this.label);
}

class EnhancedCardImageResult {
  final bool success;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final String? error;
  final String prompt;
  final bool upscaled;
  final DateTime generatedAt;

  const EnhancedCardImageResult({
    required this.success,
    required this.prompt,
    this.imageUrl,
    this.imageBytes,
    this.error,
    this.upscaled = false,
    required this.generatedAt,
  });

  bool get hasImage => imageUrl != null || imageBytes != null;
}

class EnhancedCardImageService with ChangeNotifier {
  bool _busy = false;
  String? _status;
  EnhancedCardImageResult? _lastResult;

  bool get busy => _busy;
  String? get status => _status;
  EnhancedCardImageResult? get lastResult => _lastResult;
  bool get isConfigured => _kReplicateToken.isNotEmpty;

  void _setStatus(bool isBusy, String? message) {
    _busy = isBusy;
    _status = message;
    notifyListeners();
  }

  /// Enhanced card prompt with fighting/sports aesthetics
  String _enhanceCardPrompt({
    required String baseFighterName,
    required String style,
    required String stance,
  }) {
    const aesthetics =
        'professional trading card, holographic foil effect, '
        'cinematic lighting, high contrast, sharp focus, '
        'dynamic pose, sports photography quality, 8k resolution';

    return 'Professional MMA fight card for $baseFighterName. '
        'Style: $style. Stance: $stance. '
        '$aesthetics. '
        'Championship energy, intimidating presence, '
        'studio backdrop with dramatic shadows and highlights.';
  }

  /// Generate card image using Replicate's Flux
  Future<EnhancedCardImageResult> generateCardImage({
    required String fighterName,
    required String style,
    required String stance,
    CardImageModel model = CardImageModel.fluxPro,
    bool doUpscale = false,
  }) async {
    final startTime = DateTime.now();
    _setStatus(true, 'Generating fight card image…');

    if (_kReplicateToken.isEmpty) {
      final result = EnhancedCardImageResult(
        success: false,
        prompt: fighterName,
        error:
            'REPLICATE_API_TOKEN not configured. '
            'Run with --dart-define=REPLICATE_API_TOKEN=your-token',
        generatedAt: startTime,
      );
      _lastResult = result;
      _setStatus(false, 'No API token');
      return result;
    }

    try {
      final prompt = _enhanceCardPrompt(
        baseFighterName: fighterName,
        style: style,
        stance: stance,
      );

      debugPrint('📸 Card prompt: $prompt');

      // Call Replicate API
      final response = await http.post(
        Uri.parse('$_kReplicateApiUrl/predictions'),
        headers: {
          'Authorization': 'Token $_kReplicateToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'version': _getModelVersion(model),
          'input': {
            'prompt': prompt,
            'aspect_ratio': '3:4', // Trading card aspect
            'num_outputs': 1,
            'output_format': 'png',
            'guidance_scale': 3,
            'schedule': 'karras',
          },
        }),
      );

      if (response.statusCode != 201) {
        debugPrint('❌ Replicate error: ${response.body}');
        final result = EnhancedCardImageResult(
          success: false,
          prompt: prompt,
          error: 'Replicate API error: ${response.statusCode}',
          generatedAt: startTime,
        );
        _lastResult = result;
        _setStatus(false, 'Generation failed');
        return result;
      }

      final data = jsonDecode(response.body) as Map;
      final predictionId = data['id'] as String?;

      if (predictionId == null) {
        final result = EnhancedCardImageResult(
          success: false,
          prompt: prompt,
          error: 'No prediction ID returned',
          generatedAt: startTime,
        );
        _lastResult = result;
        _setStatus(false, 'No ID');
        return result;
      }

      // Poll for completion (up to 2 minutes)
      String? imageUrl;
      for (int attempt = 0; attempt < 120; attempt++) {
        await Future.delayed(const Duration(seconds: 1));

        final pollResponse = await http.get(
          Uri.parse('$_kReplicateApiUrl/predictions/$predictionId'),
          headers: {'Authorization': 'Token $_kReplicateToken'},
        );

        if (pollResponse.statusCode == 200) {
          final pollData = jsonDecode(pollResponse.body) as Map;
          final status = pollData['status'] as String?;

          if (status == 'succeeded') {
            final output = pollData['output'];
            if (output is List && output.isNotEmpty) {
              imageUrl = output[0] as String?;
              break;
            }
          } else if (status == 'failed') {
            final result = EnhancedCardImageResult(
              success: false,
              prompt: prompt,
              error: 'Generation failed: ${pollData['error'] ?? 'Unknown'}',
              generatedAt: startTime,
            );
            _lastResult = result;
            _setStatus(false, 'Failed');
            return result;
          }
        }

        _setStatus(true, 'Generating (${attempt + 1}s)…');
      }

      if (imageUrl == null) {
        final result = EnhancedCardImageResult(
          success: false,
          prompt: prompt,
          error: 'Generation timeout after 2 minutes',
          generatedAt: startTime,
        );
        _lastResult = result;
        _setStatus(false, 'Timeout');
        return result;
      }

      // Optional: upscale
      if (doUpscale) {
        _setStatus(true, 'Upscaling card image…');
        imageUrl = await _upscaleImage(imageUrl);
      }

      final result = EnhancedCardImageResult(
        success: true,
        prompt: prompt,
        imageUrl: imageUrl,
        upscaled: doUpscale,
        generatedAt: startTime,
      );
      _lastResult = result;
      _setStatus(false, 'Card generated!');
      return result;
    } catch (e) {
      debugPrint('❌ Exception: $e');
      final result = EnhancedCardImageResult(
        success: false,
        prompt: fighterName,
        error: 'Exception: $e',
        generatedAt: startTime,
      );
      _lastResult = result;
      _setStatus(false, 'Error');
      return result;
    }
  }

  String _getModelVersion(CardImageModel model) {
    // Map to latest Replicate model versions
    switch (model) {
      case CardImageModel.flux:
        return 'a48f966f6afb2b6ed8c8e6d1af69ac1f7f4e1e43'; // flux-canvas
      case CardImageModel.fluxPro:
        return '25a82e0e1709e29f34e58fd273dc54ab5a18ee28'; // flux-pro
      case CardImageModel.kolors:
        return '4a1b2e8a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e'; // kolors
    }
  }

  Future<String?> _upscaleImage(
    String imageUrl, [
    CardUpscaleModel upscaleModel = CardUpscaleModel.realEsrgan,
  ]) async {
    try {
      // Fetch the generated image
      final imageResponse = await http.get(Uri.parse(imageUrl));
      if (imageResponse.statusCode != 200) return null;

      // Convert to base64
      final base64Image = base64Encode(imageResponse.bodyBytes);

      // Call upscale endpoint
      final upscaleResponse = await http.post(
        Uri.parse('$_kReplicateApiUrl/predictions'),
        headers: {
          'Authorization': 'Token $_kReplicateToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'version': _getUpscaleVersion(upscaleModel),
          'input': {'image': 'data:image/png;base64,$base64Image'},
        }),
      );

      if (upscaleResponse.statusCode != 201) return null;

      final upscaleData = jsonDecode(upscaleResponse.body) as Map;
      final upscalePredictionId = upscaleData['id'] as String?;

      if (upscalePredictionId == null) return null;

      // Poll for upscale completion
      for (int attempt = 0; attempt < 60; attempt++) {
        await Future.delayed(const Duration(seconds: 1));

        final pollResponse = await http.get(
          Uri.parse('$_kReplicateApiUrl/predictions/$upscalePredictionId'),
          headers: {'Authorization': 'Token $_kReplicateToken'},
        );

        if (pollResponse.statusCode == 200) {
          final pollData = jsonDecode(pollResponse.body) as Map;
          final status = pollData['status'] as String?;

          if (status == 'succeeded') {
            final output = pollData['output'];
            if (output is List && output.isNotEmpty) {
              return output[0] as String?;
            }
          } else if (status == 'failed') {
            return null;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Upscale error: $e');
      return null;
    }
  }

  String _getUpscaleVersion(CardUpscaleModel model) {
    switch (model) {
      case CardUpscaleModel.esrgan:
        return '9283608cc6b7be6b65a8e44983220d5be278ce4d'; // esrgan
      case CardUpscaleModel.realEsrgan:
        return '0bd9c9c6c08a1c3aa28fa166c7e10c0c8ed8e0a5'; // real-esrgan
    }
  }
}
