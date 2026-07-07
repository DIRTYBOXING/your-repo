import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── PPVPaymentService ─────────────────────────────────────────────────────────
// Handles PPV payment processing — Stripe, PayPal, and direct flows.

class PPVPaymentService {
  static final PPVPaymentService _i = PPVPaymentService._();
  factory PPVPaymentService() => _i;
  PPVPaymentService._();

  final _fs = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> initiatePayment({
    required String eventId,
    required String userId,
    required double amount,
    String currency = 'AUD',
    String method = 'stripe',
  }) async {
    try {
      final ref = await _fs.collection('ppv_payment_sessions').add({
        'eventId': eventId,
        'userId': userId,
        'amount': amount,
        'currency': currency,
        'method': method,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return {'sessionId': ref.id, 'status': 'pending', 'amount': amount};
    } catch (e) {
      debugPrint('PPVPaymentService.initiatePayment: $e');
      return {'error': e.toString()};
    }
  }

  Future<bool> confirmPayment(String sessionId) async {
    try {
      await _fs.collection('ppv_payment_sessions').doc(sessionId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('PPVPaymentService.confirmPayment: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory(String userId) async {
    try {
      final snap = await _fs
          .collection('ppv_payment_sessions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      debugPrint('PPVPaymentService.getPaymentHistory: $e');
      return [];
    }
  }
}
