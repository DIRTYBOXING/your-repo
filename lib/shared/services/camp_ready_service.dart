import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stats/camp_ready.dart';

/// Service for reading and writing fighter camp readiness data.
/// Reads from Firestore collection `camp_ready/{fighterId}`.
class CampReadyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream real-time camp updates for a specific fighter
  Stream<CampReady?> campStream(String fighterId) {
    return _firestore
        .collection('camp_ready')
        .doc(fighterId)
        .snapshots()
        .map((doc) => doc.exists ? CampReady.fromFirestore(doc) : null);
  }

  /// One-shot fetch of camp readiness
  Future<CampReady?> getCampReady(String fighterId) async {
    final doc = await _firestore.collection('camp_ready').doc(fighterId).get();
    return doc.exists ? CampReady.fromFirestore(doc) : null;
  }

  /// Get all fighters currently in camp (for dashboard/cards)
  Future<List<CampReady>> getActiveCamps() async {
    final snap = await _firestore
        .collection('camp_ready')
        .where('status', whereIn: ['in_camp', 'peak_week', 'weight_cut'])
        .orderBy('daysOut')
        .get();
    return snap.docs.map(CampReady.fromFirestore).toList();
  }

  /// Update camp data (used by coaching staff or wearable sync)
  Future<void> updateCampReady(CampReady camp) async {
    await _firestore
        .collection('camp_ready')
        .doc(camp.fighterId)
        .set(camp.toFirestore(), SetOptions(merge: true));
  }
}
