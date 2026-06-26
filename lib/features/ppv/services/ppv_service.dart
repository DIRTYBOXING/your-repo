import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

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
}
