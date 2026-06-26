import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/utils/app_logger.dart';
import '../models/user_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FRIEND SUGGESTIONS ENGINE — AI-Powered Friend Recommendations
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Scoring Algorithm (0-100):
///
/// 1. MUTUAL FRIENDS (40 points max)
///    - 1-2 mutual: 15 pts
///    - 3-5 mutual: 25 pts
///    - 6-10 mutual: 35 pts
///    - 11+ mutual: 40 pts
///
/// 2. ACTIVITY COMPATIBILITY (30 points max)
///    - Fighting style match: 10 pts
///    - Similar weight class: 8 pts
///    - Experience level match: 7 pts
///    - Training frequency match: 5 pts
///
/// 3. GYM PROXIMITY (20 points max)
///    - Same gym: 20 pts
///    - Within 5 mi: 15 pts
///    - Within 10 mi: 10 pts
///    - Within 25 mi: 5 pts
///
/// 4. SHARED INTERESTS (10 points max)
///    - Each shared interest: 2 pts (max 5 interests)
/// ═══════════════════════════════════════════════════════════════════════════
class FriendSuggestionsEngine {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _photoUrlFromUserData(Map<String, dynamic> data) =>
      (data['photoUrl'] ?? data['photoURL'] ?? '').toString();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  static const int _maxSuggestions = 50;
  static const int _minimumScore = 20; // Only suggest if score >= 20

  // ═══════════════════════════════════════════════════════════════════════════
  // MAIN SUGGESTION GENERATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate friend suggestions with scoring
  Future<List<FriendSuggestion>> generateSuggestions({
    int limit = 20,
    Position? userPosition,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get current user data
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) return [];
      final userData = userDoc.data()!;

      // Get user's friends to exclude
      final friendsQuery = await _db
          .collection('connections')
          .where('userId', isEqualTo: userId)
          .get();
      final friendIds = friendsQuery.docs
          .map((doc) => doc.data()['friendId'] as String)
          .toSet();

      // Get pending requests to exclude
      final sentRequests = await _db
          .collection('friend_requests')
          .where('senderId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      final requestedIds = sentRequests.docs
          .map((doc) => doc.data()['recipientId'] as String)
          .toSet();

      // Get candidate users (exclude self, friends, and pending requests)
      final candidatesQuery = await _db
          .collection('users')
          .where(FieldPath.documentId, isNotEqualTo: userId)
          .limit(_maxSuggestions)
          .get();

      final candidates = candidatesQuery.docs
          .where(
            (doc) =>
                !friendIds.contains(doc.id) && !requestedIds.contains(doc.id),
          )
          .map(UserModel.fromFirestore)
          .toList();

      // Score each candidate
      final suggestions = <FriendSuggestion>[];
      for (final candidate in candidates) {
        final score = await _calculateTotalScore(
          userId: userId,
          userData: userData,
          candidateId: candidate.id,
          candidateData: candidate,
          userPosition: userPosition,
          friendIds: friendIds,
        );

        if (score >= _minimumScore) {
          suggestions.add(
            FriendSuggestion(
              userId: candidate.id,
              userName: candidate.displayName ?? 'Unknown',
              userPhotoUrl: candidate.photoUrl ?? '',
              userRole: candidate.role.name,
              score: score,
              mutualFriendsCount: await _getMutualFriendsCount(
                userId,
                candidate.id,
                friendIds,
              ),
              reason: _getTopReason(score),
            ),
          );
        }
      }

      // Sort by score descending
      suggestions.sort((a, b) => b.score.compareTo(a.score));

      // Save to cache for quick retrieval
      await _cacheSuggestions(userId, suggestions.take(limit).toList());

      return suggestions.take(limit).toList();
    } catch (e) {
      AppLogger.error('Error generating friend suggestions', error: e);
      return [];
    }
  }

  /// Refresh suggestions (call periodically or after friend changes)
  Future<void> refreshSuggestions({Position? userPosition}) async {
    final userId = currentUserId;
    if (userId == null) return;

    await generateSuggestions(userPosition: userPosition);

    AppLogger.info(
      'Friend suggestions refreshed for user: $userId',
      tag: 'FriendSuggestionsEngine',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCORING ALGORITHMS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculate total compatibility score (0-100)
  Future<double> _calculateTotalScore({
    required String userId,
    required Map<String, dynamic> userData,
    required String candidateId,
    required UserModel candidateData,
    required Position? userPosition,
    required Set<String> friendIds,
  }) async {
    double total = 0.0;

    // 1. MUTUAL FRIENDS (40 pts max)
    total += await _scoreMutualFriends(userId, candidateId, friendIds);

    // 2. ACTIVITY COMPATIBILITY (30 pts max)
    total += _scoreActivityCompatibility(userData, candidateData);

    // 3. GYM PROXIMITY (20 pts max)
    if (userPosition != null) {
      total += await _scoreProximity(userPosition, candidateData);
    }

    // 4. SHARED INTERESTS (10 pts max)
    total += _scoreSharedInterests(userData, candidateData);

    return total.clamp(0.0, 100.0);
  }

  /// Score based on mutual friends (40 pts max)
  Future<double> _scoreMutualFriends(
    String userId,
    String candidateId,
    Set<String> userFriendIds,
  ) async {
    try {
      // Get candidate's friends
      final candidateFriendsQuery = await _db
          .collection('connections')
          .where('userId', isEqualTo: candidateId)
          .get();

      final candidateFriendIds = candidateFriendsQuery.docs
          .map((doc) => doc.data()['friendId'] as String)
          .toSet();

      // Count mutual friends
      final mutualCount = userFriendIds.intersection(candidateFriendIds).length;

      // Score based on count
      if (mutualCount >= 11) return 40.0;
      if (mutualCount >= 6) return 35.0;
      if (mutualCount >= 3) return 25.0;
      if (mutualCount >= 1) return 15.0;
      return 0.0;
    } catch (e) {
      AppLogger.error('Error scoring mutual friends', error: e);
      return 0.0;
    }
  }

  /// Score based on activity compatibility (30 pts max)
  double _scoreActivityCompatibility(
    Map<String, dynamic> userData,
    UserModel candidate,
  ) {
    double score = 0.0;

    // Fighting style match (10 pts)
    final userStyle = userData['fightingStyle'] as String?;
    final candidateStyle = candidate.role.name; // Using role as proxy for style
    if (userStyle != null && userStyle == candidateStyle) {
      score += 10.0;
    }

    // Weight class similarity (8 pts)
    final userWeight = userData['weightClass'] as String?;
    final candidateWeight =
        (candidate.metadata?['weightClass'] ??
                candidate.metadata?['stats']?['weightClass'])
            as String?;
    if (userWeight != null && candidateWeight != null) {
      if (userWeight == candidateWeight) {
        score += 8.0;
      } else if (_isAdjacentWeightClass(userWeight, candidateWeight)) {
        score += 4.0;
      }
    }

    // Experience level match (7 pts)
    final userExp = userData['experienceLevel'] as String?;
    final candidateExp =
        (candidate.metadata?['experienceLevel'] ??
                candidate.metadata?['stats']?['experienceLevel'])
            as String?;
    if (userExp != null && candidateExp != null) {
      if (userExp == candidateExp) {
        score += 7.0;
      } else if (_isAdjacentExperience(userExp, candidateExp)) {
        score += 3.0;
      }
    }

    // Training frequency match (5 pts)
    final userFreq = userData['trainingFrequency'] as int?;
    final candidateFreq =
        (candidate.metadata?['trainingFrequency'] ??
                candidate.metadata?['stats']?['trainingFrequency'])
            as int?;
    if (userFreq != null && candidateFreq != null) {
      final diff = (userFreq - candidateFreq).abs();
      if (diff == 0) {
        score += 5.0;
      } else if (diff <= 1) {
        score += 3.0;
      } else if (diff <= 2) {
        score += 1.0;
      }
    }

    return score;
  }

  /// Score based on gym proximity (20 pts max)
  Future<double> _scoreProximity(
    Position userPosition,
    UserModel candidate,
  ) async {
    try {
      final candidateGym =
          (candidate.metadata?['primaryGym'] ??
                  candidate.metadata?['stats']?['primaryGym'])
              as String?;
      if (candidateGym == null) return 0.0;

      // Get gym location
      final gymDoc = await _db.collection('gyms').doc(candidateGym).get();
      if (!gymDoc.exists) return 0.0;

      final gymData = gymDoc.data()!;
      final gymLat = gymData['latitude'] as double?;
      final gymLng = gymData['longitude'] as double?;

      if (gymLat == null || gymLng == null) return 0.0;

      // Calculate distance
      final distance =
          Geolocator.distanceBetween(
            userPosition.latitude,
            userPosition.longitude,
            gymLat,
            gymLng,
          ) /
          1609.34; // Convert meters to miles

      // Score based on distance
      if (distance <= 0.5) return 20.0; // Same gym area
      if (distance <= 5.0) return 15.0;
      if (distance <= 10.0) return 10.0;
      if (distance <= 25.0) return 5.0;
      return 0.0;
    } catch (e) {
      AppLogger.error('Error scoring proximity', error: e);
      return 0.0;
    }
  }

  /// Score based on shared interests (10 pts max)
  double _scoreSharedInterests(
    Map<String, dynamic> userData,
    UserModel candidate,
  ) {
    final userInterests =
        (userData['interests'] as List<dynamic>?)?.cast<String>().toSet() ?? {};

    final candidateInterests =
        ((candidate.metadata?['interests'] ??
                    candidate.metadata?['stats']?['interests'])
                as List<dynamic>?)
            ?.cast<String>()
            .toSet() ??
        {};

    if (userInterests.isEmpty || candidateInterests.isEmpty) return 0.0;

    final sharedCount = userInterests.intersection(candidateInterests).length;
    return math.min(
      sharedCount * 2.0,
      10.0,
    ); // 2 pts per shared interest, max 10
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<int> _getMutualFriendsCount(
    String userId,
    String candidateId,
    Set<String> userFriendIds,
  ) async {
    try {
      final candidateFriendsQuery = await _db
          .collection('connections')
          .where('userId', isEqualTo: candidateId)
          .get();

      final candidateFriendIds = candidateFriendsQuery.docs
          .map((doc) => doc.data()['friendId'] as String)
          .toSet();

      return userFriendIds.intersection(candidateFriendIds).length;
    } catch (e) {
      return 0;
    }
  }

  String _getTopReason(double score) {
    if (score >= 80) return 'Highly compatible';
    if (score >= 60) return 'Great match';
    if (score >= 40) return 'Good potential friend';
    return 'May have shared interests';
  }

  bool _isAdjacentWeightClass(String class1, String class2) {
    const weightClasses = [
      'Flyweight',
      'Bantamweight',
      'Featherweight',
      'Lightweight',
      'Welterweight',
      'Middleweight',
      'Light Heavyweight',
      'Heavyweight',
    ];

    final index1 = weightClasses.indexOf(class1);
    final index2 = weightClasses.indexOf(class2);

    if (index1 == -1 || index2 == -1) return false;
    return (index1 - index2).abs() == 1;
  }

  bool _isAdjacentExperience(String exp1, String exp2) {
    const levels = ['Beginner', 'Intermediate', 'Advanced', 'Professional'];

    final index1 = levels.indexOf(exp1);
    final index2 = levels.indexOf(exp2);

    if (index1 == -1 || index2 == -1) return false;
    return (index1 - index2).abs() == 1;
  }

  /// Cache suggestions to Firestore for quick retrieval
  Future<void> _cacheSuggestions(
    String userId,
    List<FriendSuggestion> suggestions,
  ) async {
    try {
      final batch = _db.batch();

      // Clear old suggestions
      final oldSuggestions = await _db
          .collection('friend_suggestions')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in oldSuggestions.docs) {
        batch.delete(doc.reference);
      }

      // Add new suggestions
      for (final suggestion in suggestions) {
        final docRef = _db.collection('friend_suggestions').doc();
        batch.set(docRef, {
          'userId': userId,
          'suggestedUserId': suggestion.userId,
          'score': suggestion.score,
          'mutualFriendsCount': suggestion.mutualFriendsCount,
          'reason': suggestion.reason,
          'generatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      AppLogger.error('Error caching suggestions', error: e);
    }
  }

  /// Get cached suggestions (fast retrieval)
  Future<List<FriendSuggestion>> getCachedSuggestions({int limit = 20}) async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      final snapshot = await _db
          .collection('friend_suggestions')
          .where('userId', isEqualTo: userId)
          .orderBy('score', descending: true)
          .limit(limit)
          .get();

      final suggestions = <FriendSuggestion>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final suggestedUserId = data['suggestedUserId'] as String;

        // Get user details
        final userDoc = await _db
            .collection('users')
            .doc(suggestedUserId)
            .get();
        if (!userDoc.exists) continue;

        final userData = userDoc.data()!;
        suggestions.add(
          FriendSuggestion(
            userId: suggestedUserId,
            userName: userData['displayName'] ?? 'Unknown',
            userPhotoUrl: _photoUrlFromUserData(userData),
            userRole: userData['role'] ?? 'fighter',
            score: (data['score'] as num).toDouble(),
            mutualFriendsCount: data['mutualFriendsCount'] as int,
            reason: data['reason'] as String,
          ),
        );
      }

      return suggestions;
    } catch (e) {
      AppLogger.error('Error getting cached suggestions', error: e);
      return [];
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// FRIEND SUGGESTION MODEL
/// ═══════════════════════════════════════════════════════════════════════════
class FriendSuggestion {
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String userRole;
  final double score;
  final int mutualFriendsCount;
  final String reason;

  const FriendSuggestion({
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.userRole,
    required this.score,
    required this.mutualFriendsCount,
    required this.reason,
  });
}
