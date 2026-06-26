import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PROFILE SERVICE
/// Handles identity reads/writes for Fighters, Gyms, and Promoters.
/// ═══════════════════════════════════════════════════════════════════════════
class ProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetch the private profile data for the current authenticated user
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final fighterDoc = await _db.collection('fighters').doc(user.uid).get();

      return {
        'user': userDoc.data(),
        'fighter': fighterDoc.exists ? fighterDoc.data() : null,
      };
    } catch (e) {
      debugPrint('Error fetching current user profile: $e');
      return null;
    }
  }

  /// Update the current user's profile and fighter stats
  Future<bool> updateProfile({
    String? displayName,
    String? bio,
    String? weightClass,
    String? stance,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final batch = _db.batch();

      if (displayName != null) {
        batch.update(_db.collection('users').doc(user.uid), {
          'displayName': displayName,
        });
      }

      if (bio != null || weightClass != null || stance != null) {
        final fighterRef = _db.collection('fighters').doc(user.uid);
        final updates = <String, dynamic>{};
        if (bio != null) updates['bio'] = bio;
        if (weightClass != null) updates['weightClass'] = weightClass;
        if (stance != null) updates['stance'] = stance;

        batch.set(fighterRef, updates, SetOptions(merge: true));
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  /// Fetch a public fighter profile by their ID
  Future<Map<String, dynamic>?> getPublicFighterProfile(
    String fighterId,
  ) async {
    try {
      final userDoc = await _db.collection('users').doc(fighterId).get();
      final fighterDoc = await _db.collection('fighters').doc(fighterId).get();
      // Return merged data for the public showcase
      return {...?userDoc.data(), ...?fighterDoc.data()};
    } catch (e) {
      debugPrint('Error fetching public profile: $e');
      return null;
    }
  }
}
