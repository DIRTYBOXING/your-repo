import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHTER & GYM ENGINE SERVICE
/// Connects Flutter to Module 2 (Fighters, Gyms) + Google + NVIDIA
/// ═══════════════════════════════════════════════════════════════════════════
class FighterGymService extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;

  /// Fetch a Fighter's Profile and their Gym details
  Future<Map<String, dynamic>?> getFighterWithGym(String fighterId) async {
    try {
      final fighterDoc = await _firestore
          .collection('fighters')
          .doc(fighterId)
          .get();
      if (!fighterDoc.exists) return null;

      final fighterData = fighterDoc.data()!;
      final gymId = fighterData['gym_id'] ?? fighterData['gymId'];

      if (gymId != null) {
        final gymDoc = await _firestore.collection('gyms').doc(gymId).get();
        if (gymDoc.exists) fighterData['gyms'] = gymDoc.data();
      }
      return fighterData;
    } catch (e) {
      debugPrint('Error fetching fighter: $e');
      return null;
    }
  }

  /// GOOGLE INTEGRATION: Search for a gym using Google Places API
  Future<void> linkGymToGooglePlace(String gymId, String googlePlaceId) async {
    // This connects the gym in your DB directly to Google Maps coordinates
    await _firestore.collection('gyms').doc(gymId).update({
      'google_place_id': googlePlaceId,
    });
    notifyListeners();
  }

  /// NVIDIA INTEGRATION: Trigger DeepStream Video Analysis
  Future<void> analyzeSparringVideo(String fighterId, String videoUrl) async {
    // 1. Verify fighter has NVIDIA tracking enabled in DB
    final fighterDoc = await _firestore
        .collection('fighters')
        .doc(fighterId)
        .get();

    if (fighterDoc.exists &&
        fighterDoc.data()?['nvidia_tracking_enabled'] == true) {
      debugPrint('Routing video to NVIDIA TensorRT pipeline...');
      // TODO: Call Google Cloud Run endpoint which houses the NVIDIA DeepStream/CUDA logic
      // It will return punch velocity, biomechanics, and asymmetry data back to the DB.
    } else {
      debugPrint('NVIDIA tracking not enabled for this fighter.');
    }
  }
}
