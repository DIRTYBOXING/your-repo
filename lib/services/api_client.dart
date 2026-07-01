// lib/services/api_client.dart
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  ApiClient(this.baseUrl);

  Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = user == null ? null : await user.getIdToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (idToken != null) headers['Authorization'] = 'Bearer $idToken';
    return headers;
  }

  Future<http.Response> get(String path, {Map<String, String>? params}) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);
    return http.get(uri, headers: headers);
  }

  Future<http.Response> post(String path, Object body) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl$path');
    return http.post(uri, headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> put(String path, Object body) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl$path');
    return http.put(uri, headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> delete(String path) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl$path');
    return http.delete(uri, headers: headers);
  }
}
