import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';

class PpvStorefrontService {
  PpvStorefrontService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  String get _baseUrl => AppConstants.ppvStorefrontBaseUrl;

  bool get isConfigured => _baseUrl.isNotEmpty;

  Future<Map<String, dynamic>> createOrder({
    required String eventId,
    required String tierId,
    required String userId,
    String? promoCode,
  }) async {
    if (!isConfigured) {
      throw Exception('PPV storefront base URL is not configured.');
    }

    final response = await _client.post(
      Uri.parse('$_baseUrl/createPpvStorefrontOrder'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'eventId': eventId,
        'tierId': tierId,
        'userId': userId,
        if (promoCode != null && promoCode.isNotEmpty) 'promoCode': promoCode,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'createPpvStorefrontOrder failed: ${response.statusCode} ${response.body}',
    );
  }

  Future<Map<String, dynamic>> confirmOrder({
    required String orderId,
    String? paymentIntentId,
    bool sandboxApproved = false,
  }) async {
    if (!isConfigured) {
      throw Exception('PPV storefront base URL is not configured.');
    }

    final response = await _client.post(
      Uri.parse('$_baseUrl/confirmPpvStorefrontOrder'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'orderId': orderId,
        if (paymentIntentId != null && paymentIntentId.isNotEmpty)
          'paymentIntentId': paymentIntentId,
        if (sandboxApproved) 'sandboxApproved': true,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'confirmPpvStorefrontOrder failed: ${response.statusCode} ${response.body}',
    );
  }

  void dispose() => _client.close();
}
