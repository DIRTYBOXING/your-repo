import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import 'friend_suggestions_engine.dart';

/// Seeds social connections and friend suggestions when a new user registers.
///
/// Call [seedNewUser] from AuthService after creating the user document,
/// and [prewarmSuggestions] from OnboardingController after onboarding completes.
class SocialOnboardingService {
  SocialOnboardingService({
    FirebaseFirestore? firestore,
    FriendSuggestionsEngine? suggestionsEngine,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _suggestionsEngine = suggestionsEngine ?? FriendSuggestionsEngine();

  final FirebaseFirestore _db;
  final FriendSuggestionsEngine _suggestionsEngine;

  /// Auto-connect the new user with the DFC seed account (first admin)
  /// and cache initial friend suggestions from real Firestore users.
  Future<void> seedNewUser(String uid, UserRole role) async {
    try {
      // 1. Find the DFC seed account (first admin user)
      final adminSnap = await _db
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .orderBy('createdAt')
          .limit(1)
          .get();

      if (adminSnap.docs.isNotEmpty && adminSnap.docs.first.id != uid) {
        final adminId = adminSnap.docs.first.id;
        await _createBidirectionalConnection(uid, adminId);
        // Auto-follow the founder (social graph) so their content
        // appears in the new user's "Following" feed immediately
        await _autoFollowFounder(uid, adminId);
        debugPrint('SocialOnboarding: seeded connection $uid ↔ $adminId');
      }

      // 2. Cache initial friend suggestions from real users
      await _cacheInitialSuggestions(uid, role);
    } catch (e) {
      // Non-blocking — social seeding should never prevent registration
      debugPrint('SocialOnboarding: seedNewUser failed (non-fatal): $e');
    }
  }

  /// Pre-warm friend suggestions after onboarding completes.
  /// Uses the suggestions engine which scores candidates based on
  /// mutual friends, activity, proximity, and interests.
  Future<void> prewarmSuggestions() async {
    try {
      await _suggestionsEngine.generateSuggestions(limit: 10);
      debugPrint('SocialOnboarding: suggestions pre-warmed');
    } catch (e) {
      debugPrint('SocialOnboarding: prewarmSuggestions failed (non-fatal): $e');
    }
  }

  /// Create a bidirectional connection between two users.
  Future<void> _createBidirectionalConnection(
    String userId,
    String friendId,
  ) async {
    final now = FieldValue.serverTimestamp();
    final batch = _db.batch();

    // Forward direction
    batch.set(
      _db.collection('connections').doc('${userId}_$friendId'),
      {
        'userId': userId,
        'friendId': friendId,
        'status': 'accepted',
        'createdAt': now,
        'source': 'auto_seed',
      },
    );

    // Reverse direction
    batch.set(
      _db.collection('connections').doc('${friendId}_$userId'),
      {
        'userId': friendId,
        'friendId': userId,
        'status': 'accepted',
        'createdAt': now,
        'source': 'auto_seed',
      },
    );

    await batch.commit();
  }

  /// Auto-follow the founder/admin in the social graph so their posts
  /// appear in the new user's "Following" feed tab from day one.
  /// This is the Zuckerberg "every new user follows the founder" pattern.
  Future<void> _autoFollowFounder(String userId, String founderId) async {
    await _db.collection('social_graph').doc('${userId}_$founderId').set({
      'userId': userId,
      'targetId': founderId,
      'type': 'following',
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'auto_seed',
    });
  }

  /// Fetch real users from Firestore and cache as initial suggestions
  /// for the new user. Falls back silently on error.
  Future<void> _cacheInitialSuggestions(String uid, UserRole role) async {
    final candidatesSnap = await _db
        .collection('users')
        .where(FieldPath.documentId, isNotEqualTo: uid)
        .limit(10)
        .get();

    if (candidatesSnap.docs.isEmpty) return;

    final suggestions = candidatesSnap.docs.map((doc) {
      final data = doc.data();
      return {
        'userId': doc.id,
        'userName': data['displayName'] ?? 'Unknown',
        'userPhotoUrl': data['photoUrl'] ?? data['photoURL'] ?? '',
        'userRole': data['role'] ?? 'fan',
        'score': 50.0, // Default seed score
        'mutualFriendsCount': 0,
        'reason': 'New to DFC',
        'cachedAt': FieldValue.serverTimestamp(),
      };
    }).toList();

    final batch = _db.batch();
    for (final s in suggestions) {
      batch.set(
        _db
            .collection('friend_suggestions')
            .doc('${uid}_${s['userId']}'),
        s,
      );
    }
    await batch.commit();

    debugPrint(
      'SocialOnboarding: cached ${suggestions.length} suggestions for $uid',
    );
  }
}
