import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../shared/models/ppv_model.dart';

/// Compatibility alias — several screens reference `PPVService`.
typedef PPVService = PpvService;

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

  /// Live PPV events currently streaming.
  Stream<List<PPVEvent>> getLivePPVEvents({int limit = 10}) {
    return _db
        .collection('ppv_events')
        .where('status', isEqualTo: 'live')
        .orderBy('eventDate')
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => PPVEvent.fromFirestore(d)).toList(),
        );
  }

  /// PPV events available to browse/purchase.
  Stream<List<PPVEvent>> getAvailablePPVEvents({int limit = 20}) {
    return _db
        .collection('ppv_events')
        .where(
          'status',
          whereIn: ['upcoming', 'presale', 'onSale', 'announced', 'live'],
        )
        .orderBy('eventDate')
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => PPVEvent.fromFirestore(d)).toList(),
        );
  }

  /// Whether [userId] has purchased access to [eventId].
  Future<bool> hasAccess(String userId, String eventId) async {
    try {
      final snap = await _db
          .collection('ppv_purchases')
          .where('userId', isEqualTo: userId)
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Calls the secure Cloud Function to validate if the user can watch the stream
  Future<Map<String, dynamic>> checkPpvAndEnter(String eventId) async {
    final callable = _functions.httpsCallable('validatePpvAccess');
    final result = await callable.call({'eventId': eventId});
    return Map<String, dynamic>.from(result.data);
  }

  /// Fetch a single PPV event document by its own ID.
  Future<PPVEvent?> getPPVEvent(String ppvEventId) async {
    final doc = await _db.collection('ppv_events').doc(ppvEventId).get();
    if (!doc.exists) return null;
    return PPVEvent.fromFirestore(doc);
  }

  /// Fetch the PPV event linked to a given [EventModel] id, if one exists.
  /// If [promoterId] is provided, the result is only returned when it
  /// belongs to that promoter.
  Future<PPVEvent?> getPPVEventForEventId(
    String eventId, {
    String? promoterId,
  }) async {
    final snap = await _db
        .collection('ppv_events')
        .where('eventId', isEqualTo: eventId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final ppvEvent = PPVEvent.fromFirestore(snap.docs.first);
    if (promoterId != null && ppvEvent.promoterId != promoterId) return null;
    return ppvEvent;
  }

  /// Create a new PPV event document and return its generated ID.
  Future<String> createPPVEvent({
    required String eventId,
    required String promoterId,
    required String title,
    String? description,
    required DateTime eventDate,
    required int standardPriceCents,
    String? posterUrl,
    String? sport,
    String? promotion,
    String? streamUrl,
    String? trailerUrl,
    double? platformFeePct,
  }) async {
    final docRef = await _db.collection('ppv_events').add({
      'eventId': eventId,
      'promoterId': promoterId,
      'title': title,
      'description': description,
      'eventDate': Timestamp.fromDate(eventDate),
      'standardPriceCents': standardPriceCents,
      'posterUrl': posterUrl,
      'sport': sport,
      'promotion': promotion,
      if (streamUrl != null) 'streamUrl': streamUrl,
      if (trailerUrl != null) 'trailerUrl': trailerUrl,
      if (platformFeePct != null) 'platformFeePct': platformFeePct,
      'status': 'announced',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
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
