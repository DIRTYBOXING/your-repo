import '../../api_service.dart';

class StripePaymentService {
  final ApiService _apiService = ApiService();

  Future<bool> purchasePpvPass(String eventId) async {
    try {
      // Keep backend intent creation so integrations continue to be exercised.
      final response = await _apiService.callFunction(
        'createPpvPaymentIntent',
        {'eventId': eventId},
      );

      final clientSecret = response['clientSecret'];

      if (clientSecret == null) {
        throw Exception('Failed to retrieve client secret from backend.');
      }

      // Local Stripe SDK flow is disabled until package wiring is restored.
      return false;
    } catch (e) {
      rethrow;
    }
  }
}
