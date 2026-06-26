import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FeatureFlagsService {
  FeatureFlagsService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? _defaultBaseUrl;

  static const String _defaultBaseUrl = String.fromEnvironment(
    'DFC_FLAGS_BASE',
    defaultValue: 'http://localhost:4000',
  );

  final http.Client _client;
  final String _baseUrl;

  Future<Map<String, bool>> fetchFlags({
    String? userId,
    String userRole = 'free',
  }) async {
    final uri = Uri.parse('$_baseUrl/api/flags');
    final response = await _client.get(
      uri,
      headers: {
        if (userId != null && userId.isNotEmpty) 'x-dfc-user-id': userId,
        'x-dfc-user-role': userRole,
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Feature flag fetch failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final rawFlags = decoded['flags'];
    if (rawFlags is! Map<String, dynamic>) {
      return const {};
    }

    return rawFlags.map((key, value) => MapEntry(key, value == true));
  }

  Future<bool> isEnabled(
    String flagName, {
    String? userId,
    String userRole = 'free',
  }) async {
    final flags = await fetchFlags(userId: userId, userRole: userRole);
    return flags[flagName] == true;
  }

  void dispose() {
    if (!kIsWeb) {
      _client.close();
      return;
    }
    _client.close();
  }
}
