import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:datafightcentral/shared/models/promotion_model.dart';
import 'package:datafightcentral/shared/models/event_model.dart';

class PromoterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'australia-southeast1',
  );

  // --- Gatekeeper ---

  /// Server-side validation: calls Cloud Function to verify all promoter gates.
  /// Returns the full gate result map from validatePromoterAndCheckout.
  Future<Map<String, dynamic>> validatePromoterGate({
    required String action,
    String? eventId,
  }) async {
    try {
      final callable = _functions.httpsCallable('validatePromoterAndCheckout');
      final result = await callable.call<dynamic>({
        'action': action,
        'eventId': eventId,
      });
      return Map<String, dynamic>.from(result.data as Map);
    } catch (e) {
      debugPrint('Error calling validatePromoterAndCheckout: $e');
      return {
        'validated': false,
        'code': 'CALL_FAILED',
        'message': 'Could not reach validation server: $e',
      };
    }
  }

  /// Lightweight gate status check (no audit logging).
  Future<Map<String, dynamic>> getGateStatus() async {
    try {
      final callable = _functions.httpsCallable('getPromoterGateStatus');
      final result = await callable.call<dynamic>({});
      return Map<String, dynamic>.from(result.data as Map);
    } catch (e) {
      debugPrint('Error calling getPromoterGateStatus: $e');
      return {'gateOpen': false, 'reason': 'Could not reach server: $e'};
    }
  }

  // --- Promotions ---

  Future<List<PromotionModel>> getPromotions(String advertiserId) async {
    try {
      final snapshot = await _firestore
          .collection('ads')
          .where('advertiserId', isEqualTo: advertiserId)
          .orderBy('startDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return PromotionModel(
          id: doc.id,
          advertiserId: data['advertiserId'],
          type: _parseType(data['type']),
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          mediaUrl: data['mediaUrl'],
          targetUrl: data['targetUrl'],
          radiusKm: (data['radiusKm'] as num?)?.toDouble(),
          targetLocation: data['targetLocation'],
          status: _parseStatus(data['status']),
          startDate: (data['startDate'] as Timestamp).toDate(),
          endDate: (data['endDate'] as Timestamp).toDate(),
          budget: data['budget'] ?? 0,
          metrics: Map<String, int>.from(data['metrics'] ?? {}),
        );
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Error fetching promotions: $e');
      return [];
    }
  }

  Future<void> createPromotion(Map<String, dynamic> data) async {
    // ── Server-side gate: must pass all checks before writing ──────────
    final gate = await validatePromoterGate(action: 'validate');
    if (gate['validated'] != true) {
      throw Exception(
        gate['message'] ??
            'Promoter validation failed. Complete onboarding first.',
      );
    }

    await _firestore.collection('ads').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'metrics': {'impressions': 0, 'clicks': 0},
    });
  }

  // --- Events ---

  Future<List<EventModel>> getMyEvents(String promoterId) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('promoterId', isEqualTo: promoterId)
          .orderBy('eventDate', descending: true)
          .get();

      // Use unified factory to deserialize events consistently
      return snapshot.docs.map(EventModel.fromFirestore).toList();
    } catch (e) {
      return [];
    }
  }

  // --- Analytics ---

  Future<Map<String, dynamic>> getDashboardStats(String promoterId) async {
    // In a real app, this would be a Cloud Function aggregation or a separate analytic query
    // Simulating aggregation
    return {
      'totalImpressions': 12500,
      'activeCampaigns': 3,
      'ticketSales': 450,
      'revenue': 12500.00,
    };
  }

  PromotionType _parseType(String? val) {
    return PromotionType.values.firstWhere(
      (e) => e.toString().split('.').last == val,
      orElse: () => PromotionType.gymPromo,
    );
  }

  PromotionStatus _parseStatus(String? val) {
    return PromotionStatus.values.firstWhere(
      (e) => e.toString().split('.').last == val,
      orElse: () => PromotionStatus.pending,
    );
  }
}
