import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// HTTP client for DFC Cloud Run API endpoints.
///
/// Set the base URL via --dart-define=DFC_API_BASE=https://your-url
/// or leave the default for local development.
class DfcApiClient {
  static const _base = String.fromEnvironment(
    'DFC_API_BASE',
    defaultValue: 'http://localhost:8080',
  );

  final http.Client _client;
  final String? Function() _tokenProvider;

  DfcApiClient({http.Client? client, required String? Function() tokenProvider})
    : _client = client ?? http.Client(),
      _tokenProvider = tokenProvider {
    // Warn if HTTP is used outside debug mode
    if (kReleaseMode && _base.startsWith('http://')) {
      debugPrint('⚠️ DfcApiClient: using insecure HTTP in release mode!');
    }
  }

  Future<Map<String, String>> _headers({bool json = false}) async {
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    final token = _tokenProvider();
    if (token != null) h['Authorization'] = 'Bearer $token';
    return h;
  }

  Future<Map<String, dynamic>> get(String path) async {
    final url = Uri.parse('$_base$path');
    final res = await _client.get(url, headers: await _headers());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('GET $path failed: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('$_base$path');
    final res = await _client.post(
      url,
      headers: await _headers(json: true),
      body: jsonEncode(body),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('POST $path failed: ${res.statusCode}');
  }

  // ── Convenience wrappers ─────────────────────────────────────

  Future<Map<String, dynamic>> fetchEvent(String eventId) =>
      get('/api/v1/events/$eventId');

  Future<Map<String, dynamic>> sendAssetRequest(
    String toEmail,
    Map<String, dynamic> payload,
  ) => post('/api/v1/outreach/asset-request', {
    'to': toEmail,
    'payload': payload,
  });

  Future<void> addToBucket({
    required String ownerId,
    required String itemType,
    required String itemId,
  }) async {
    await post('/api/v1/buckets', {
      'ownerId': ownerId,
      'itemType': itemType,
      'itemId': itemId,
    });
  }

  Future<Map<String, dynamic>> sendInboxReply(String threadId, String body) =>
      post('/api/v1/threads/$threadId/reply', {'body': body});

  void dispose() => _client.close();
}
