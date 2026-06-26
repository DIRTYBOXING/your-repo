import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC BACKGROUND REMOVAL SERVICE — Flutter client for bg-removal-worker
///
/// Calls the U²-Net Cloud Run service to remove backgrounds from images.
/// Used by poster generator, fighter cutouts, and collectible card builder.
/// ═══════════════════════════════════════════════════════════════════════════

class BackgroundRemovalService {
  BackgroundRemovalService._();
  static final BackgroundRemovalService _instance =
      BackgroundRemovalService._();
  factory BackgroundRemovalService() => _instance;

  // Default to localhost for dev; override at startup
  String _baseUrl = 'http://localhost:8080';
  String? _apiKey;

  void configure({required String baseUrl, String? apiKey}) {
    _baseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    _apiKey = apiKey;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{};
    final key = _apiKey;
    if (key != null) headers['X-Api-Key'] = key;
    return headers;
  }

  /// Remove background from a single image.
  /// Returns transparent PNG bytes, or null on failure.
  Future<Uint8List?> removeBackground({
    required Uint8List imageBytes,
    required String filename,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/remove-background/');
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(_headers)
        ..files.add(
          http.MultipartFile.fromBytes('file', imageBytes, filename: filename),
        );

      final response = await request.send();
      if (response.statusCode == 200) {
        return await response.stream.toBytes();
      }
      debugPrint('BG removal failed: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('BG removal error: $e');
      return null;
    }
  }

  /// Remove backgrounds from multiple images.
  /// Returns ZIP bytes containing transparent PNGs.
  Future<Uint8List?> removeBackgroundBatch({
    required List<Uint8List> images,
    required List<String> filenames,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/remove-background/batch/');
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(_headers);

      for (int i = 0; i < images.length; i++) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            images[i],
            filename: filenames[i],
          ),
        );
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        return await response.stream.toBytes();
      }
      debugPrint('Batch BG removal failed: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Batch BG removal error: $e');
      return null;
    }
  }

  /// Check service health.
  Future<bool> isHealthy() async {
    try {
      final resp = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: _headers,
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
