import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
}
