import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service layer for communicating with the Atlas AI Backend.
/// Atlas hosts the multi-model AI engine (GPT, Claude, Gemini, Perplexity)
/// with automatic fallback chain.
class AtlasService {
  static const _baseUrl = String.fromEnvironment(
    'ATLAS_URL',
    defaultValue: 'http://localhost:8000',
  );

  final http.Client _client;

  AtlasService({http.Client? client}) : _client = client ?? http.Client() {
    if (kReleaseMode && _baseUrl.startsWith('http://')) {
      debugPrint('⚠️ AtlasService: using insecure HTTP in release mode!');
    }
  }

  // ─── Health Check ──────────────────────────────────────────────────────

  Future<bool> isHealthy() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── Chat (Atlas AI Coach) ─────────────────────────────────────────────

  /// Send a message to Atlas AI coach. Returns the assistant reply.
  /// Uses OpenAI GPT-4o-mini with Pinecone memory retrieval.
  Future<String> chat(
    String message, {
    required String sessionId,
    String? userId,
  }) async {
    final response = await _post('/chat', {
      'session_id': sessionId,
      'user_id': userId ?? 'anon',
      'message': message,
    });
    return response['reply'] as String? ?? '';
  }

  // ─── Multi-Model Generate ─────────────────────────────────────────────

  /// Generate text via the multi-model fallback chain.
  /// Models: gpt_5_nano → claude → gemini → gpt_5_2 → perplexity.
  Future<Map<String, dynamic>> generate(
    String prompt, {
    String? model,
    String? system,
    int maxTokens = 1024,
    double temperature = 0.7,
  }) async {
    return _post('/v1/generate', {
      'prompt': prompt,
      'model': ?model,
      'system': ?system,
      'max_tokens': maxTokens,
      'temperature': temperature,
    });
  }

  // ─── Content Moderation ────────────────────────────────────────────────

  /// Check text for safety via OpenAI Moderations API.
  Future<Map<String, dynamic>> moderate(String text) async {
    return _post('/v1/moderate', {'text': text});
  }

  // ─── Available Models ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> getModels() async {
    final response = await _client.get(Uri.parse('$_baseUrl/v1/models'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw AtlasException('Failed to fetch models: ${response.statusCode}');
  }

  // ─── PSYCHE Bot (Mental State Analysis) ────────────────────────────────

  Future<Map<String, dynamic>> analyzePsyche(
    Map<String, dynamic> payload,
  ) async {
    return _post('/v1/psyche/analyze', payload);
  }

  // ─── SCALES Bot (Weight Prediction) ────────────────────────────────────

  Future<Map<String, dynamic>> predictWeight(
    Map<String, dynamic> payload,
  ) async {
    return _post('/v1/scales/predict', payload);
  }

  // ─── SHIELD Bot (Injury Risk) ──────────────────────────────────────────

  Future<Map<String, dynamic>> assessInjuryRisk(
    Map<String, dynamic> payload,
  ) async {
    return _post('/v1/shield/assess', payload);
  }

  // ─── FUEL Bot (Nutrition) ──────────────────────────────────────────────

  Future<Map<String, dynamic>> planNutrition(
    Map<String, dynamic> payload,
  ) async {
    return _post('/v1/fuel/plan', payload);
  }

  // ─── Poster Captions ──────────────────────────────────────────────────

  /// Generate poster caption variants for the poster pipeline.
  Future<List<String>> generateCaptions(
    String prompt, {
    int numVariants = 3,
  }) async {
    final result = await _post('/caption', {
      'prompt': prompt,
      'num_variants': numVariants,
    });
    final variants = result['variants'];
    if (variants is List) {
      return variants.cast<String>();
    }
    return [];
  }

  // ─── Internal ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw AtlasException(
      'Atlas $path failed (${response.statusCode}): ${response.body}',
    );
  }

  void dispose() => _client.close();
}

class AtlasException implements Exception {
  final String message;
  AtlasException(this.message);

  @override
  String toString() => 'AtlasException: $message';
}
