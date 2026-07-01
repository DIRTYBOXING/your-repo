import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/utils/app_logger.dart';
import '../models/user_model.dart';

/// Firestore-backed user profile service.
///
/// This service is intentionally narrow: it handles role-aware profile reads and
/// writes for the `users` collection so screens/controllers don't duplicate
/// query and timestamp logic.
class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _usersCollection = 'users';

  String? get currentUserId => _auth.currentUser?.uid;

  Future<UserModel?> getProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      AppLogger.error(
        'Failed to fetch user profile',
        error: e,
        tag: 'UserProfileService',
      );
      return null;
    }
  }

  Future<UserModel?> getCurrentProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;
    return getProfile(uid);
  }

  Stream<UserModel?> watchProfile(String userId) {
    return _firestore.collection(_usersCollection).doc(userId).snapshots().map((
      doc,
    ) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  Future<bool> saveProfile(UserModel profile) async {
    try {
      final now = DateTime.now();
      final payload = profile.copyWith(updatedAt: now).toFirestore();
      await _firestore
          .collection(_usersCollection)
          .doc(profile.id)
          .set(payload, SetOptions(merge: true));
      return true;
    } catch (e) {
      AppLogger.error(
        'Failed to save user profile',
        error: e,
        tag: 'UserProfileService',
      );
      return false;
    }
  }

  Future<bool> updateRole({
    required String userId,
    required UserRole role,
  }) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).set({
        'role': role.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      AppLogger.error(
        'Failed to update user role',
        error: e,
        tag: 'UserProfileService',
      );
      return false;
    }
  }

  Future<bool> completeOnboarding(
    String userId, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).set({
        'onboardingCompleted': true,
        if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      AppLogger.error(
        'Failed to complete onboarding',
        error: e,
        tag: 'UserProfileService',
      );
      return false;
    }
  }

  Future<List<UserModel>> listUsersByRole(
    UserRole role, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('role', isEqualTo: role.name)
          .where('isActive', isEqualTo: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .where((doc) => doc.data().isNotEmpty)
          .map(UserModel.fromFirestore)
          .toList();
    } catch (e) {
      AppLogger.error(
        'Failed to list users by role',
        error: e,
        tag: 'UserProfileService',
      );
      return [];
    }
  }
}
