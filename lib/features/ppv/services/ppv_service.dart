import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../../../shared/models/ppv_model.dart';

/// Handles PPV Event feeds, watch history, and access validation.
class PpvService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Returns the featured hero event
  Future<QuerySnapshot> getHeroEvent() {
    return _db
        .collection('ppvEvents')
        .where('isFeatured', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .orderBy('startTime')
        .limit(1)
        .get();
  }

  /// Returns upcoming PPV events as a stream (used by social feed).
  Stream<List<PPVEvent>> getUpcomingPPVEvents({int limit = 10}) {
    return _db
        .collection('ppv_events')
        .where(
          'status',
          whereIn: ['upcoming', 'presale', 'onSale', 'announced'],
        )
        .orderBy('eventDate')
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => PPVEvent.fromFirestore(d)).toList(),
        );
  }

  /// Returns a stream of PPV events by category
  Stream<QuerySnapshot> getPpvRow(String category) {
    return _db
        .collection('ppvEvents')
        .where('categories', arrayContains: category)
        .orderBy('startTime', descending: false)
        .snapshots();
  }

  /// Returns the "Continue Watching" history for a user
  Stream<QuerySnapshot> getContinueWatching(String userId) {
    return _db
        .collection('watchHistory')
        .where('userId', isEqualTo: userId)
        .orderBy('lastWatchedAt', descending: true)
        .limit(10)
        .snapshots();
  }

  /// Calls the secure Cloud Function to validate if the user can watch the stream
  Future<Map<String, dynamic>> checkPpvAndEnter(String eventId) async {
    final callable = _functions.httpsCallable('validatePpvAccess');
    final result = await callable.call({'eventId': eventId});
    return Map<String, dynamic>.from(result.data);
  }

  // ── Promoter-specific streams ──────────────────────────────────────────────
  Stream<List<PPVEvent>> getPromoterEvents(String promoterId) {
    return _db
        .collection('ppv_events')
        .where('promoterId', isEqualTo: promoterId)
        .orderBy('eventDate', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => PPVEvent.fromFirestore(d)).toList(),
        );
  }

  Stream<double> getPromoterTotalRevenue(String promoterId) {
    return _db
        .collection('revenue_events')
        .where('promoterId', isEqualTo: promoterId)
        .snapshots()
        .map(
          (snap) => snap.docs.fold<double>(
            0,
            (sum, d) => sum + ((d.data()['amount'] ?? 0) as num).toDouble(),
          ),
        );
  }

  Future<void> updateEventStatus(String eventId, PPVStatus status) async {
    await _db.collection('ppv_events').doc(eventId).update({
      'status': status.name,
    });
  }

  /// Returns a PPV purchase (called from payment widgets).
  Future<void> purchasePPV({
    required String ppvEventId,
    String? paymentIntentId,
    String? paymentMethod,
    PPVTier? tier,
    int? pricePaidCents,
  }) async {
    await _db.collection('ppv_purchases').add({
      'eventId': ppvEventId,
      'paymentIntentId': paymentIntentId,
      'paymentMethod': paymentMethod,
      'tier': tier,
      'pricePaidCents': pricePaidCents,
      'status': 'completed',
      'purchasedAt': FieldValue.serverTimestamp(),
    });
  }
}
