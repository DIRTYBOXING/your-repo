import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../models/fight_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// EVENT & FIGHT SERVICE
/// Connects Promoters to Module 3 (Events, Fights)
/// ═══════════════════════════════════════════════════════════════════════════
class EventService extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;

  /// Create a new Event
  Future<String?> createEvent({
    required String promoterId,
    required String name,
    required DateTime date,
    required String location,
    String sportType = 'mma',
    String? posterUrl,
  }) async {
    try {
      final docRef = await _firestore.collection('events').add({
        'promoter_id': promoterId,
        'name': name,
        'date': date.toIso8601String(),
        'location': location,
        'sport_type': sportType,
        'status': 'draft',
        'poster_url': posterUrl,
        'created_at': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return docRef.id; // Returns the new Event ID
    } catch (e) {
      debugPrint('Error creating event: $e');
      return null;
    }
  }

  /// Add a Fight to an existing Event
  Future<String?> createFight({
    required String eventId,
    required String fighterAId,
    required String fighterBId,
    required String weightClass,
    int rounds = 3,
    bool isTitleFight = false,
  }) async {
    try {
      final docRef = await _firestore.collection('fights').add({
        'event_id': eventId,
        'fighter_a_id': fighterAId,
        'fighter_b_id': fighterBId,
        'weight_class': weightClass,
        'rounds': rounds,
        'is_title_fight': isTitleFight,
        'status': 'scheduled',
        'created_at': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return docRef.id; // Returns the new Fight ID
    } catch (e) {
      debugPrint('Error creating fight: $e');
      return null;
    }
  }

  /// Fetch the most recent events for a dashboard preview.
  Future<List<EventModel>> getUpcomingEvents({
    int limit = 10,
    String? sportType,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('events');
      if (sportType != null) {
        query = query.where('sportType', isEqualTo: sportType);
      }
      final snapshot = await query
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching upcoming events: $e');
      return [];
    }
  }

  /// Events flagged as featured for hero carousels.
  Future<List<EventModel>> getFeaturedEvents({int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('isFeatured', isEqualTo: true)
          .orderBy('eventDate')
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching featured events: $e');
      return [];
    }
  }

  /// Fetch a single event by ID.
  Future<EventModel?> getEvent(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();
      if (!doc.exists) return null;
      return EventModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error fetching event: $e');
      return null;
    }
  }

  /// Fetch events currently marked live.
  Future<List<EventModel>> getLiveEvents() async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('status', isEqualTo: 'live')
          .get();
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching live events: $e');
      return [];
    }
  }

  /// Create an event document from a full [EventModel].
  Future<String?> createEventDoc(EventModel event) async {
    try {
      final docRef = await _firestore
          .collection('events')
          .add(event.toFirestore());
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating event doc: $e');
      return null;
    }
  }

  /// Update the status of an existing event. Returns true on success.
  Future<bool> updateEventStatus(String eventId, EventStatus status) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating event status: $e');
      return false;
    }
  }

  /// Delete an event document. Returns true on success.
  Future<bool> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting event: $e');
      return false;
    }
  }

  /// Fetch the fight card (list of fights) for a given event.
  /// Returns a list of FightModel objects.
  Future<List<FightModel>> getEventFightCard(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('fights')
          .where('event_id', isEqualTo: eventId)
          .orderBy('created_at')
          .get();
      return snapshot.docs.map((doc) => FightModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching event fight card: $e');
      return [];
    }
  }

  /// Attach a poster asset to an event.
  /// Accepts either a String URL or a MediaAssetModel object.
  /// Returns true on success.
  Future<bool> attachPosterAsset(String eventId, Object posterAsset) async {
    try {
      final String posterUrl;
      if (posterAsset is String) {
        posterUrl = posterAsset;
      } else {
        // Assume it's a MediaAssetModel or similar object with a url property
        posterUrl =
            (posterAsset as dynamic).url?.toString() ?? posterAsset.toString();
      }
      await _firestore.collection('events').doc(eventId).update({
        'poster_url': posterUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error attaching poster asset: $e');
      return false;
    }
  }
}
