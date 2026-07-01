import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeCheckoutService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static Future<bool> processPpvPayment(String eventId) async {
    try {
      // 1. Call Firebase Function to create PaymentIntent
      final callable = _functions.httpsCallable('createPpvPaymentIntent');
      final result = await callable.call({'eventId': eventId});

      final clientSecret = result.data['clientSecret'];
      if (clientSecret == null) throw Exception('Missing client secret');

      // 2. Initialize the Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Data Fight Central',
          style: ThemeMode.dark, // Keeps it Vogue/Cinematic
        ),
      );

      // 3. Present the Payment Sheet to the user
      await Stripe.instance.presentPaymentSheet();

      return true; // Payment succeeded
    } on StripeException catch (e) {
      print('Stripe Error: ${e.error.localizedMessage}');
      return false;
    } catch (e) {
      print('Payment Error: $e');
      return false;
    }
  }
}
