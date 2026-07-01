import 'dart:convert';
import 'package:http/http.dart' as http;

/// Client for the canonical PPV checkout-session compat API.
///
/// Set base URL via --dart-define=DFC_PAYMENTS_BASE=https://your-url
class DfcPaymentClient {
  static const _base = String.fromEnvironment(
    'DFC_PAYMENTS_BASE',
    defaultValue: 'http://localhost:8080',
  );

  final http.Client _client;
  final String? Function() _tokenProvider;

  DfcPaymentClient({
    http.Client? client,
    required String? Function() tokenProvider,
  }) : _client = client ?? http.Client(),
       _tokenProvider = tokenProvider;

  Future<Map<String, String>> _headers() async {
    final h = <String, String>{'Content-Type': 'application/json'};
    final token = _tokenProvider();
    if (token != null) h['Authorization'] = 'Bearer $token';
    return h;
  }

  /// Create a canonical PPV checkout session.
  Future<Map<String, dynamic>> createPpvPurchase({
    required String userId,
    required String eventId,
    required String tier,
    String? promoCode,
    String? successUrl,
    String? cancelUrl,
    String? priceId,
  }) async {
    final url = Uri.parse('$_base/checkout');
    final res = await _client.post(
      url,
      headers: await _headers(),
      body: jsonEncode({
        'userId': userId,
        'eventId': eventId,
        'tier': tier,
        if (promoCode != null && promoCode.isNotEmpty) 'promoCode': promoCode,
        if (successUrl != null && successUrl.isNotEmpty)
          'successUrl': successUrl,
        if (cancelUrl != null && cancelUrl.isNotEmpty) 'cancelUrl': cancelUrl,
        if (priceId != null && priceId.isNotEmpty) 'priceId': priceId,
      }),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('createPpvPurchase failed: ${res.statusCode} ${res.body}');
  }

  /// Poll the canonical checkout session until entitlement is granted.
  Future<Map<String, dynamic>> waitForEntitlement({
    required String sessionId,
    int maxAttempts = 8,
  }) async {
    final token = _tokenProvider();
    final headers = <String, String>{};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    for (var i = 0; i < maxAttempts; i++) {
      final url = Uri.parse('$_base/orders/$sessionId');
      final res = await _client.get(url, headers: headers);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final status = (json['status'] ?? '').toString().trim().toLowerCase();
        final granted =
            json['granted'] == true ||
            json['accessGranted'] == true ||
            status == 'complete';
        if (granted) {
          return {...json, 'granted': true};
        }

        if (status == 'failed' ||
            status == 'expired' ||
            status == 'canceled' ||
            status == 'cancelled') {
          throw Exception(
            'Checkout session $sessionId ended with status: $status',
          );
        }
      }
      await Future.delayed(Duration(seconds: 1 << i));
    }
    throw Exception(
      'Entitlement not granted for checkout session $sessionId within $maxAttempts attempts',
    );
  }

  void dispose() => _client.close();
}
