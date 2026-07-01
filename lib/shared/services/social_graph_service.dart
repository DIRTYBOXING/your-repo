import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SOCIAL GRAPH SERVICE — Find Friends, Follow Fighters, Build Community
/// ═══════════════════════════════════════════════════════════════════════════

final _firestore = FirebaseFirestore.instance;

enum RelationType { following, follower, friend, blocked, muted }

enum SuggestionReason {
  mutualFriends,
  sameGym,
  sameFavorites,
  sameLocation,
  trending,
}

class SocialConnection {
  final String id;
  final String userId;
  final String targetId;
  final RelationType type;
  final DateTime createdAt;

  const SocialConnection({
    required this.id,
    required this.userId,
    required this.targetId,
    required this.type,
    required this.createdAt,
  });

  factory SocialConnection.fromMap(Map<String, dynamic> map) =>
      SocialConnection(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        targetId: map['targetId'] ?? '',
        type: RelationType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => RelationType.following,
        ),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

class FriendSuggestion {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final SuggestionReason reason;
  final int mutualCount;
  final double score;

  const FriendSuggestion({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.reason,
    this.mutualCount = 0,
    this.score = 0.5,
  });
}

class SocialGraphService with ChangeNotifier {
  static final SocialGraphService _instance = SocialGraphService._internal();
  factory SocialGraphService() => _instance;
  SocialGraphService._internal();

  bool _initialized = false;
  final List<SocialConnection> _following = [];
  final List<SocialConnection> _followers = [];
  final List<FriendSuggestion> _suggestions = [];

  bool get initialized => _initialized;
  List<SocialConnection> get following => List.unmodifiable(_following);
  List<SocialConnection> get followers => List.unmodifiable(_followers);
  List<FriendSuggestion> get suggestions => List.unmodifiable(_suggestions);
  int get followingCount => _following.length;
  int get followersCount => _followers.length;

  Future<void> initialize(String userId) async {
    if (_initialized) return;
    debugPrint('🌐 SocialGraphService: Initializing...');
    await Future.wait([
      _loadFollowing(userId),
      _loadFollowers(userId),
      _loadSuggestions(userId),
    ]);
    _initialized = true;
    notifyListeners();
  }

  Future<void> _loadFollowing(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('social_graph')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'following')
          .limit(500)
          .get();
      _following.clear();
      for (final doc in snapshot.docs) {
        _following.add(SocialConnection.fromMap({...doc.data(), 'id': doc.id}));
      }
    } catch (e) {
      debugPrint('SocialGraphService: Load following failed: $e');
    }
  }

  Future<void> _loadFollowers(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('social_graph')
          .where('targetId', isEqualTo: userId)
          .where('type', isEqualTo: 'following')
          .limit(500)
          .get();
      _followers.clear();
      for (final doc in snapshot.docs) {
        _followers.add(SocialConnection.fromMap({...doc.data(), 'id': doc.id}));
      }
    } catch (e) {
      debugPrint('SocialGraphService: Load followers failed: $e');
    }
  }

  Future<void> _loadSuggestions(String userId) async {
    _suggestions.clear();
    _suggestions.addAll([
      const FriendSuggestion(
        userId: 'fighter_1',
        displayName: 'Alex "The Beast" Santos',
        reason: SuggestionReason.trending,
        mutualCount: 12,
        score: 0.95,
      ),
      const FriendSuggestion(
        userId: 'fighter_2',
        displayName: 'Maria "Thunder" Rodriguez',
        reason: SuggestionReason.sameFavorites,
        mutualCount: 8,
        score: 0.88,
      ),
      const FriendSuggestion(
        userId: 'user_x',
        displayName: 'Fight Fan Mike',
        reason: SuggestionReason.mutualFriends,
        mutualCount: 5,
        score: 0.75,
      ),
    ]);
  }

  Future<void> follow(String userId, String targetId) async {
    try {
      await _firestore.collection('social_graph').add({
        'userId': userId,
        'targetId': targetId,
        'type': 'following',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _following.add(
        SocialConnection(
          id: '',
          userId: userId,
          targetId: targetId,
          type: RelationType.following,
          createdAt: DateTime.now(),
        ),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('SocialGraphService: Follow failed: $e');
    }
  }

  Future<void> unfollow(String userId, String targetId) async {
    try {
      final snapshot = await _firestore
          .collection('social_graph')
          .where('userId', isEqualTo: userId)
          .where('targetId', isEqualTo: targetId)
          .where('type', isEqualTo: 'following')
          .get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      _following.removeWhere((c) => c.targetId == targetId);
      notifyListeners();
    } catch (e) {
      debugPrint('SocialGraphService: Unfollow failed: $e');
    }
  }

  bool isFollowing(String targetId) =>
      _following.any((c) => c.targetId == targetId);

  Future<List<String>> getMutualFollowers(
    String userId,
    String otherUserId,
  ) async {
    try {
      final myFollowing = await _firestore
          .collection('social_graph')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'following')
          .get();
      final theirFollowing = await _firestore
          .collection('social_graph')
          .where('userId', isEqualTo: otherUserId)
          .where('type', isEqualTo: 'following')
          .get();
      final mySet = myFollowing.docs
          .map((d) => d.data()['targetId'] as String)
          .toSet();
      final theirSet = theirFollowing.docs
          .map((d) => d.data()['targetId'] as String)
          .toSet();
      return mySet.intersection(theirSet).toList();
    } catch (e) {
      return [];
    }
  }
}
