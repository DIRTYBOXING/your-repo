import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PAYPAL PAYMENT SERVICE — PayPal Orders + Capture
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Flow:
///   1. Call createOrder() → gets PayPal approval URL
///   2. User completes payment on PayPal hosted page
///   3. PayPal redirects back → call captureOrder()
///   4. Firestore records updated, access granted
///
/// Works alongside Stripe — users choose their preferred payment method.
/// ═══════════════════════════════════════════════════════════════════════════
class PayPalService with ChangeNotifier {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'australia-southeast1',
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isProcessing = false;
  String? _error;
  String? _lastOrderId;

  bool get isProcessing => _isProcessing;
  String? get error => _error;
  String? get lastOrderId => _lastOrderId;

  /// Create a PayPal order and open the approval URL in the browser.
  ///
  /// Returns the PayPal order ID if successful, null on failure.
  Future<String?> createOrder({
    required String userId,
    required int amountCents,
    required String currency,
    required String productType,
    String? productId,
    String? productName,
  }) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      final callable = _functions.httpsCallable('createPayPalOrder');
      final result = await callable.call({
        'userId': userId,
        'amountCents': amountCents,
        'currency': currency,
        'productType': productType,
        'productId': productId,
        'productName': productName,
        'successUrl': 'https://datafightcentral.web.app/payment-success',
        'cancelUrl': 'https://datafightcentral.web.app/payment-cancelled',
      });

      final data = Map<String, dynamic>.from(result.data as Map);

      if (data.containsKey('error')) {
        _error = data['error'] as String;
        return null;
      }

      final orderId = data['orderId'] as String?;
      final approvalUrl = data['approvalUrl'] as String?;
      _lastOrderId = orderId;

      if (approvalUrl != null) {
        final uri = Uri.parse(approvalUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _error = 'Could not open PayPal checkout page.';
          return null;
        }
      }

      return orderId;
    } catch (e) {
      _error = 'PayPal order failed: $e';
      debugPrint(_error);
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Capture a PayPal order after user approval.
  ///
  /// Call this when the user returns from PayPal to finalize the payment.
  Future<bool> captureOrder({
    required String orderId,
    required String userId,
  }) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      final callable = _functions.httpsCallable('capturePayPalOrder');
      final result = await callable.call({
        'orderId': orderId,
        'userId': userId,
      });

      final data = Map<String, dynamic>.from(result.data as Map);

      if (data.containsKey('error')) {
        _error = data['error'] as String;
        return false;
      }

      return data['status'] == 'COMPLETED';
    } catch (e) {
      _error = 'PayPal capture failed: $e';
      debugPrint(_error);
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Check if a PayPal order was completed (poll Firestore).
  Future<bool> isOrderCompleted(String orderId) async {
    try {
      final doc = await _firestore
          .collection('paypal_orders')
          .doc(orderId)
          .get();
      return doc.exists && doc.data()?['status'] == 'COMPLETED';
    } catch (e) {
      debugPrint('PayPal order check failed: $e');
      return false;
    }
  }

  /// Purchase Fight Credits via PayPal.
  Future<String?> purchaseCredits({
    required String userId,
    required int amountCents,
    required int creditAmount,
    String currency = 'AUD',
  }) async {
    return createOrder(
      userId: userId,
      amountCents: amountCents,
      currency: currency,
      productType: 'credits',
      productId: 'credits_$creditAmount',
      productName: 'DFC Fight Credits ($creditAmount)',
    );
  }
}
