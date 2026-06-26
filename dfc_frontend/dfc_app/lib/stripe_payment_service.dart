import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../api_service.dart';

class StripePaymentService {
  final ApiService _apiService = ApiService();

  Future<bool> purchasePpvPass(String eventId) async {
    try {
      // 1. Call your Cloud Function to create a PaymentIntent
      final response = await _apiService.callFunction(
        'createPpvPaymentIntent',
        {'eventId': eventId},
      );

      final clientSecret = response['clientSecret'];
      final ephemeralKey = response['ephemeralKey'];
      final customerId = response['customer'];

      if (clientSecret == null) {
        throw Exception("Failed to retrieve client secret from backend.");
      }

      // 2. Initialize the native Stripe Payment Sheet with DFC colors
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          customerEphemeralKeySecret: ephemeralKey,
          customerId: customerId,
          merchantDisplayName: 'Data Fight Central',
          style: ThemeMode.dark,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Colors.cyanAccent,
              background: Color(0xFF05060A),
            ),
          ),
        ),
      );

      // 3. Present the Payment Sheet to the user
      await Stripe.instance.presentPaymentSheet();

      // If we reach this line, the payment was successful
      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return false; // User dismissed the sheet
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}