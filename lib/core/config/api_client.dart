import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../logic/failure.dart';
import '../logic/result.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC BASE API CLIENT (BLUE TIER)
/// ═══════════════════════════════════════════════════════════════════════════
/// A robust, production-grade HTTP client.
/// Handles headers, token injection, timeout configurations, and safely maps
/// all network exceptions into our unified Result/Failure monad.
/// ═══════════════════════════════════════════════════════════════════════════
class ApiClient {
  final String baseUrl;
  final http.Client _client;
  final Duration timeout;

  ApiClient({
    required this.baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  /// GET Request
  Future<Result<dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    String? token,
  }) async {
    return _safeCall(
      () => _client
          .get(
            Uri.parse('$baseUrl$endpoint'),
            headers: _buildHeaders(headers, token),
          )
          .timeout(timeout),
    );
  }

  /// POST Request
  Future<Result<dynamic>> post(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    String? token,
  }) async {
    return _safeCall(
      () => _client
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: _buildHeaders(headers, token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout),
    );
  }

  /// PUT Request
  Future<Result<dynamic>> put(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    String? token,
  }) async {
    return _safeCall(
      () => _client
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: _buildHeaders(headers, token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout),
    );
  }

  /// DELETE Request
  Future<Result<dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
    String? token,
  }) async {
    return _safeCall(
      () => _client
          .delete(
            Uri.parse('$baseUrl$endpoint'),
            headers: _buildHeaders(headers, token),
          )
          .timeout(timeout),
    );
  }

  // ─── INTERNAL HELPERS ──────────────────────────────────────────────────

  Map<String, String> _buildHeaders(
    Map<String, String>? customHeaders,
    String? token,
  ) {
    final headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    };
    if (token != null) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    return headers;
  }

  Future<Result<dynamic>> _safeCall(
    Future<http.Response> Function() call,
  ) async {
    try {
      final response = await call();
      return _handleResponse(response);
    } on SocketException catch (e) {
      return Err(
        Failure(
          'No internet connection. Please check your network.',
          code: 'network_error',
          exception: e,
        ),
      );
    } on TimeoutException catch (e) {
      return Err(
        Failure(
          'The connection timed out. Please try again.',
          code: 'timeout',
          exception: e,
        ),
      );
    } catch (e) {
      return Err(
        Failure(
          'An unexpected network error occurred.',
          code: 'unknown',
          exception: e,
        ),
      );
    }
  }

  Result<dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return const Success(null);
      try {
        return Success(jsonDecode(response.body));
      } catch (e) {
        return Err(
          Failure(
            'Failed to parse server response.',
            code: 'parse_error',
            exception: e,
          ),
        );
      }
    } else {
      String message = 'Server Error';
      try {
        final body = jsonDecode(response.body);
        message = body['message'] ?? body['error'] ?? message;
      } catch (_) {
        message = response.body.isNotEmpty ? response.body : message;
      }
      return Err(
        Failure(
          message,
          code: 'http_${response.statusCode}',
          exception: response.body,
        ),
      );
    }
  }
}
