import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

/// Simple payment service for collecting money TODAY
/// Uses Stripe Payment Links (no backend code needed)
class QuickPaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stripe Payment Links (create these at dashboard.stripe.com)
  /// These work immediately - no coding required
  static const String fighterProfileSetup =
      'https://buy.stripe.com/YOUR_LINK_HERE';
  static const String coachDashboardSetup =
      'https://buy.stripe.com/YOUR_LINK_HERE';
  static const String fighterProMonthly =
      'https://buy.stripe.com/YOUR_LINK_HERE';

  /// Track payment request
  Future<String> createPaymentRequest({
    required String userId,
    required String productType,
    required double amount,
    required String description,
  }) async {
    final doc = await _firestore.collection('payment_requests').add({
      'userId': userId,
      'productType': productType,
      'amount': amount,
      'description': description,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  /// Send payment link
  Future<void> sendPaymentLink({
    required String email,
    required String productType,
    String? customMessage,
  }) async {
    String paymentUrl;

    switch (productType) {
      case 'fighter_profile':
        paymentUrl = fighterProfileSetup;
        break;
      case 'coach_dashboard':
        paymentUrl = coachDashboardSetup;
        break;
      case 'fighter_pro':
        paymentUrl = fighterProMonthly;
        break;
      default:
        throw Exception('Unknown product type');
    }

    // In real app, send via email service
    // For now, just copy/paste this link to send manually
    debugPrint('Payment link for $email: $paymentUrl');

    // Track outreach
    await _firestore.collection('payment_outreach').add({
      'email': email,
      'productType': productType,
      'message': customMessage,
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  /// Launch payment link in browser
  Future<void> openPaymentLink(String productType) async {
    String url;

    switch (productType) {
      case 'fighter_profile':
        url = fighterProfileSetup;
        break;
      case 'coach_dashboard':
        url = coachDashboardSetup;
        break;
      case 'fighter_pro':
        url = fighterProMonthly;
        break;
      default:
        throw Exception('Unknown product type');
    }

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  /// Mark payment as completed (manual verification for now)
  Future<void> markPaymentCompleted({
    required String paymentRequestId,
    required String stripePaymentId,
  }) async {
    await _firestore
        .collection('payment_requests')
        .doc(paymentRequestId)
        .update({
          'status': 'completed',
          'stripePaymentId': stripePaymentId,
          'completedAt': FieldValue.serverTimestamp(),
        });
  }

  /// Get payment stats
  Future<Map<String, dynamic>> getPaymentStats() async {
    final snapshot = await _firestore
        .collection('payment_requests')
        .where('status', isEqualTo: 'completed')
        .get();

    double totalRevenue = 0;
    final int totalSales = snapshot.docs.length;

    for (final doc in snapshot.docs) {
      totalRevenue += (doc.data()['amount'] as num).toDouble();
    }

    return {
      'totalRevenue': totalRevenue,
      'totalSales': totalSales,
      'averageOrderValue': totalSales > 0 ? totalRevenue / totalSales : 0,
    };
  }
}

/// Widget: Add payment button to any screen
class QuickPaymentButton extends StatelessWidget {
  final String productType;
  final String buttonText;
  final double amount;

  const QuickPaymentButton({
    super.key,
    required this.productType,
    required this.buttonText,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final service = QuickPaymentService();
        await service.openPaymentLink(productType);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
      child: Text(
        '$buttonText - \$$amount',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
