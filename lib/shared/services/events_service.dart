import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<EventModel>> streamUpcoming({int limit = 10}) {
    return _firestore.collection('events').snapshots().map((snap) {
      final now = DateTime.now().toUtc();
      final filtered =
          snap.docs.where((doc) {
            final data = doc.data();
            final date = _extractDate(data);
            if (date == null || !date.isAfter(now)) return false;
            return _isUpcomingLikeStatus(data['status']);
          }).toList()..sort((a, b) {
            final ad =
                _extractDate(a.data()) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bd =
                _extractDate(b.data()) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return ad.compareTo(bd);
          });

      return filtered.take(limit).map(EventModel.fromFirestore).toList();
    });
  }

  Future<List<EventModel>> fetchPromotions({int limit = 10}) async {
    final snap = await _firestore
        .collection('promotions')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(EventModel.fromFirestore).toList();
  }

  /// Batch upload events to Firestore
  Future<void> uploadEventsBatch(List<EventModel> events) async {
    final batch = _firestore.batch();
    final eventsCollection = _firestore.collection('events');
    for (final event in events) {
      final docRef = eventsCollection.doc();
      batch.set(docRef, event.toFirestore());
    }
    await batch.commit();
  }

  DateTime? _extractDate(Map<String, dynamic> data) {
    final dynamic raw = data['eventDate'] ?? data['date'];
    if (raw is Timestamp) return raw.toDate().toUtc();
    if (raw is DateTime) return raw.toUtc();
    if (raw is String) return DateTime.tryParse(raw)?.toUtc();
    return null;
  }

  bool _isUpcomingLikeStatus(dynamic statusRaw) {
    final status = statusRaw?.toString().trim().toLowerCase();
    if (status == null || status.isEmpty) return true;
    return status == 'upcoming' ||
        status == 'announced' ||
        status == 'on_sale' ||
        status == 'onsale';
  }
}
