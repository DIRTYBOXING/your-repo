import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Handles Stripe Checkout integrations for PPV Purchases.
class PpvPaymentService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Starts the Stripe checkout flow
  /// Passes userId and eventId as metadata so the webhook knows who paid for what.
  Future<bool> purchasePpvAccess(
    String userId,
    String eventId,
    double price,
  ) async {
    try {
      debugPrint(
        'Initiating Stripe checkout for User: $userId, Event: $eventId',
      );

      // 1. Call Cloud Function to create a PaymentIntent
      final callable = _functions.httpsCallable('createStripePaymentIntent');
      final response = await callable.call({
        'userId': userId,
        'eventId': eventId,
        'amount': (price * 100).toInt(), // Stripe expects cents
        'currency': 'usd',
      });

      final clientSecret = response.data['paymentIntent'];
      final ephemeralKey = response.data['ephemeralKey'];
      final customerId = response.data['customer'];

      if (clientSecret == null)
        throw Exception('Failed to retrieve client secret.');

      // 2. Initialize the Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          customerEphemeralKeySecret: ephemeralKey,
          customerId: customerId,
          merchantDisplayName: 'Data Fight Central',
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              background: Color(0xFF05060A),
              primary: Color(0xFF00E5FF),
              componentBackground: Color(0xFF0B0D13),
              componentBorder: Color(0xFF00E5FF),
            ),
          ),
        ),
      );

      // 3. Present the Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      debugPrint('Payment successful!');
      return true;
    } on StripeException catch (e) {
      debugPrint('Stripe Error: ${e.error.localizedMessage}');
      return false;
    } catch (e) {
      debugPrint('Payment failed: $e');
      return false;
    }
  }
}
