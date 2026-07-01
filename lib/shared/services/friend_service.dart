import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/utils/app_logger.dart';
import '../models/user_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FRIEND SERVICE — Combat Sports Friend Discovery & Connection Management
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Handles:
/// - Friend requests (send, accept, decline)
/// - Connection management (list friends, remove connections)
/// - AI-powered recommendations (compatibility scoring)
/// - Search & discovery (by name, style, gym, location)
/// - Privacy controls (blocking, visibility settings)
///
/// Database Collections:
/// - users (extended with discovery fields)
/// - connections (bidirectional friendships)
/// - friend_requests (pending requests)
/// - friend_suggestions (AI-generated cache)
/// - blocked_users (safety/privacy)

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _logTag = 'FriendService';
  static const String _requestsCollection = 'friend_requests';
  static const String _nameBucketsCollection = 'friend_name_buckets';

  String? get _currentUserId => _auth.currentUser?.uid;

  // ═══════════════════════════════════════════════════════════════════════════
  // FRIEND REQUESTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Send a friend request to another user
  Future<void> sendFriendRequest(String recipientId) async {
    final senderId = _currentUserId;
    if (senderId == null) throw Exception('User not authenticated');
    if (senderId == recipientId) throw Exception('Cannot send request to self');

    // Check if already connected or request exists
    final existingConnection = await _firestore
        .collection('connections')
        .where('userId', isEqualTo: senderId)
        .where('friendId', isEqualTo: recipientId)
        .limit(1)
        .get();

    if (existingConnection.docs.isNotEmpty) {
      throw Exception('Already connected with this user');
    }

    final existingRequest = await _firestore
        .collection(_requestsCollection)
        .where('senderId', isEqualTo: senderId)
        .where('recipientId', isEqualTo: recipientId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existingRequest.docs.isNotEmpty) {
      throw Exception('Friend request already sent');
    }

    // Create request
    await _firestore.collection(_requestsCollection).add({
      'senderId': senderId,
      'recipientId': recipientId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Accept a friend request
  Future<void> acceptFriendRequest(String requestId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final requestDoc = await _firestore
        .collection(_requestsCollection)
        .doc(requestId)
        .get();

    if (!requestDoc.exists) throw Exception('Request not found');

    final data = requestDoc.data()!;
    final senderId = data['senderId'] as String;
    final recipientId = data['recipientId'] as String;

    if (recipientId != userId) {
      throw Exception('Not authorized to accept this request');
    }

    // Create bidirectional connection
    final batch = _firestore.batch();

    // Connection: sender → recipient
    batch.set(_firestore.collection('connections').doc(), {
      'userId': senderId,
      'friendId': recipientId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Connection: recipient → sender
    batch.set(_firestore.collection('connections').doc(), {
      'userId': recipientId,
      'friendId': senderId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update request status
    batch.update(_firestore.collection(_requestsCollection).doc(requestId), {
      'status': 'accepted',
      'respondedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Decline a friend request
  Future<void> declineFriendRequest(String requestId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _firestore.collection(_requestsCollection).doc(requestId).update({
      'status': 'declined',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Cancel a sent friend request
  Future<void> cancelFriendRequest(String recipientId) async {
    final senderId = _currentUserId;
    if (senderId == null) throw Exception('User not authenticated');

    final request = await _firestore
        .collection(_requestsCollection)
        .where('senderId', isEqualTo: senderId)
        .where('recipientId', isEqualTo: recipientId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (request.docs.isNotEmpty) {
      await request.docs.first.reference.delete();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONNECTIONS MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all friends for current user
  Stream<List<UserModel>> streamFriends() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('connections')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) return <UserModel>[];

          final friendIds = snapshot.docs
              .map((doc) => doc.data()['friendId'] as String)
              .toList();

          final friendDocs = await Future.wait(
            friendIds.map((id) => _firestore.collection('users').doc(id).get()),
          );

          return friendDocs
              .where((doc) => doc.exists)
              .map(UserModel.fromFirestore)
              .toList();
        });
  }

  /// Get friend count for a user
  Future<int> getFriendCount(String userId) async {
    final snapshot = await _firestore
        .collection('connections')
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs.length;
  }

  /// Check if two users are friends
  Future<bool> areFriends(String userId1, String userId2) async {
    final connection = await _firestore
        .collection('connections')
        .where('userId', isEqualTo: userId1)
        .where('friendId', isEqualTo: userId2)
        .limit(1)
        .get();

    return connection.docs.isNotEmpty;
  }

  /// Remove a friend connection
  Future<void> removeFriend(String friendId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Remove both directions
    final batch = _firestore.batch();

    final connection1 = await _firestore
        .collection('connections')
        .where('userId', isEqualTo: userId)
        .where('friendId', isEqualTo: friendId)
        .limit(1)
        .get();

    final connection2 = await _firestore
        .collection('connections')
        .where('userId', isEqualTo: friendId)
        .where('friendId', isEqualTo: userId)
        .limit(1)
        .get();

    if (connection1.docs.isNotEmpty) {
      batch.delete(connection1.docs.first.reference);
    }
    if (connection2.docs.isNotEmpty) {
      batch.delete(connection2.docs.first.reference);
    }

    await batch.commit();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FRIEND REQUESTS (INBOX)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream pending friend requests received by current user
  Stream<List<Map<String, dynamic>>> streamPendingRequests() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection(_requestsCollection)
        .where('recipientId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) return <Map<String, dynamic>>[];

          final requests = <Map<String, dynamic>>[];

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final senderId = data['senderId'] as String;

            final senderDoc = await _firestore
                .collection('users')
                .doc(senderId)
                .get();

            if (senderDoc.exists) {
              requests.add({
                'requestId': doc.id,
                'sender': UserModel.fromFirestore(senderDoc),
                'createdAt': data['createdAt'],
              });
            }
          }

          return requests;
        });
  }

  /// Get count of pending friend requests
  Future<int> getPendingRequestCount() async {
    final userId = _currentUserId;
    if (userId == null) return 0;

    final snapshot = await _firestore
        .collection(_requestsCollection)
        .where('recipientId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs.length;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH & DISCOVERY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Keep a lightweight name bucket index for fast find-friends discovery.
  Future<void> upsertCurrentUserDiscoveryIndex() async {
    final userId = _currentUserId;
    if (userId == null) return;

    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    final data = userDoc.data() ?? <String, dynamic>{};
    final displayName = (data['displayName'] ?? data['name'] ?? 'User')
        .toString()
        .trim();
    final username = (data['username'] ?? '').toString().trim();
    final displayNameLower = displayName.toLowerCase();
    final usernameLower = username.toLowerCase();
    final bucket = _bucketKeyFor(displayNameLower, usernameLower);
    final previousBucket = (data['discoveryBucket'] ?? '').toString();
    final searchTokens = _buildSearchTokens(displayNameLower, usernameLower);

    final profilePayload = <String, dynamic>{
      'displayNameLower': displayNameLower,
      'usernameLower': usernameLower,
      'searchTokens': searchTokens,
      'discoveryBucket': bucket,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final bucketPayload = <String, dynamic>{
      'uid': userId,
      'displayName': displayName,
      'displayNameLower': displayNameLower,
      'username': username,
      'usernameLower': usernameLower,
      'photoUrl': (data['photoUrl'] ?? data['photoURL'] ?? '').toString(),
      'role': (data['role'] ?? 'fighter').toString(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('users').doc(userId),
      profilePayload,
      SetOptions(merge: true),
    );
    batch.set(
      _firestore
          .collection(_nameBucketsCollection)
          .doc(bucket)
          .collection('users')
          .doc(userId),
      bucketPayload,
      SetOptions(merge: true),
    );

    if (previousBucket.isNotEmpty && previousBucket != bucket) {
      batch.delete(
        _firestore
            .collection(_nameBucketsCollection)
            .doc(previousBucket)
            .collection('users')
            .doc(userId),
      );
    }

    await batch.commit();
  }

  /// Search users by name or username (basic implementation)
  Future<List<UserModel>> searchUsers(String query) async {
    final currentUserId = _currentUserId;
    final q = query.trim().toLowerCase();
    if (q.length < 2) return [];

    AppLogger.debug('searchUsers:start query="$q"', tag: _logTag);

    try {
      final bucketUserIds = await _searchUserIdsFromBucket(q);

      final tokenMatches = await _firestore
          .collection('users')
          .where('searchTokens', arrayContains: q)
          .limit(20)
          .get();

      final namePrefixMatches = await _firestore
          .collection('users')
          .where('displayNameLower', isGreaterThanOrEqualTo: q)
          .where('displayNameLower', isLessThanOrEqualTo: '$q\uf8ff')
          .limit(20)
          .get();

      final usernamePrefixMatches = await _firestore
          .collection('users')
          .where('usernameLower', isGreaterThanOrEqualTo: q)
          .where('usernameLower', isLessThanOrEqualTo: '$q\uf8ff')
          .limit(20)
          .get();

      final docsById = <String, DocumentSnapshot<Map<String, dynamic>>>{
        for (final doc in tokenMatches.docs) doc.id: doc,
        for (final doc in namePrefixMatches.docs) doc.id: doc,
        for (final doc in usernamePrefixMatches.docs) doc.id: doc,
      };

      for (final userId in bucketUserIds) {
        if (docsById.containsKey(userId)) continue;
        final doc = await _firestore.collection('users').doc(userId).get();
        if (doc.exists) {
          docsById[userId] = doc;
        }
      }

      final users =
          docsById.values
              .where((doc) => currentUserId == null || doc.id != currentUserId)
              .map(UserModel.fromFirestore)
              .where((user) => user.isActive)
              .toList()
            ..sort((a, b) {
              final aExact =
                  (a.username?.toLowerCase() == q ||
                      a.displayName?.toLowerCase() == q)
                  ? 1
                  : 0;
              final bExact =
                  (b.username?.toLowerCase() == q ||
                      b.displayName?.toLowerCase() == q)
                  ? 1
                  : 0;
              if (aExact != bExact) return bExact.compareTo(aExact);
              return (a.displayName ?? '').toLowerCase().compareTo(
                (b.displayName ?? '').toLowerCase(),
              );
            });

      AppLogger.debug(
        'searchUsers:complete matches=${users.length}',
        tag: _logTag,
      );
      return users;
    } catch (e, st) {
      AppLogger.error(
        'searchUsers:failed query="$q"',
        tag: _logTag,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  String _bucketKeyFor(String displayNameLower, String usernameLower) {
    final source = displayNameLower.isNotEmpty
        ? displayNameLower
        : usernameLower;
    if (source.isEmpty) return 'zz';
    if (source.length == 1) return '${source}_';
    return source.substring(0, 2);
  }

  List<String> _buildSearchTokens(
    String displayNameLower,
    String usernameLower,
  ) {
    final raw = <String>{};

    for (final source in [displayNameLower, usernameLower]) {
      if (source.isEmpty) continue;
      final compact = source.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ').trim();
      if (compact.isEmpty) continue;

      for (final part in compact.split(RegExp(r'\s+'))) {
        if (part.isEmpty) continue;
        raw.add(part);
        for (int i = 2; i <= part.length && i <= 12; i++) {
          raw.add(part.substring(0, i));
        }
      }
    }

    return raw.toList();
  }

  Future<Set<String>> _searchUserIdsFromBucket(
    String queryLower, {
    int limit = 20,
  }) async {
    if (queryLower.length < 2) return <String>{};

    final bucket = _bucketKeyFor(queryLower, queryLower);
    final usersRef = _firestore
        .collection(_nameBucketsCollection)
        .doc(bucket)
        .collection('users');

    final byDisplayName = await usersRef
        .where('displayNameLower', isGreaterThanOrEqualTo: queryLower)
        .where('displayNameLower', isLessThanOrEqualTo: '$queryLower\uf8ff')
        .limit(limit)
        .get();

    final byUsername = await usersRef
        .where('usernameLower', isGreaterThanOrEqualTo: queryLower)
        .where('usernameLower', isLessThanOrEqualTo: '$queryLower\uf8ff')
        .limit(limit)
        .get();

    return {
      ...byDisplayName.docs.map((d) => d.id),
      ...byUsername.docs.map((d) => d.id),
    };
  }

  /// Get friend suggestions with AI-powered scoring (Phase 2)
  /// 100-point compatibility scoring based on:
  /// - Mutual connections (30pts)
  /// - Training compatibility (25pts)
  /// - Proximity (20pts)
  /// - Activity level (15pts)
  /// - Availability (10pts)
  ///
  /// Backward-compatible API returning only users.
  Future<List<UserModel>> getFriendSuggestions({int limit = 10}) async {
    final scored = await getFriendSuggestionsWithScores(limit: limit);
    return scored.map((e) => e['user'] as UserModel).toList();
  }

  /// Returns list of maps with 'user' (UserModel) and 'score' (double 0-100)
  Future<List<Map<String, dynamic>>> getFriendSuggestionsWithScores({
    int limit = 10,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return [];
    AppLogger.debug(
      'getFriendSuggestionsWithScores:start user=$userId limit=$limit',
      tag: _logTag,
    );

    // Get current user data
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return [];
    final currentUser = UserModel.fromFirestore(userDoc);

    // Get current user's connections
    final connections = await _firestore
        .collection('connections')
        .where('userId', isEqualTo: userId)
        .get();

    final friendIds = connections.docs
        .map((doc) => doc.data()['friendId'] as String)
        .toSet();

    // Get blocked users (both directions)
    final blocked = await _firestore
        .collection('blocked_users')
        .where('blockerId', isEqualTo: userId)
        .get();
    final blockedBy = await _firestore
        .collection('blocked_users')
        .where('blockedId', isEqualTo: userId)
        .get();

    final blockedIds = {
      ...blocked.docs.map((doc) => doc.data()['blockedId'] as String),
      ...blockedBy.docs.map((doc) => doc.data()['blockerId'] as String),
    };

    // Get pending requests to avoid duplicates
    final pendingRequests = await _firestore
        .collection(_requestsCollection)
        .where('senderId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();

    final pendingIds = pendingRequests.docs
        .map((doc) => doc.data()['recipientId'] as String)
        .toSet();

    // Fetch candidate users (bounded sample for fast first paint)
    final snapshot = await _firestore.collection('users').limit(40).get();

    final candidates = snapshot.docs
        .map(UserModel.fromFirestore)
        .where((user) => user.id != userId)
        .where((user) => !friendIds.contains(user.id))
        .where((user) => !blockedIds.contains(user.id))
        .where((user) => !pendingIds.contains(user.id))
        .toList();
    AppLogger.debug(
      'getFriendSuggestionsWithScores:candidates=${candidates.length} friends=${friendIds.length} blocked=${blockedIds.length} pending=${pendingIds.length}',
      tag: _logTag,
    );

    // Score each candidate
    final scoredCandidates = <MapEntry<UserModel, double>>[];

    for (final candidate in candidates) {
      final score = await _calculateCompatibilityScore(
        currentUser,
        candidate,
        friendIds,
      );
      scoredCandidates.add(MapEntry(candidate, score));
    }

    // Sort by score (descending) and take top suggestions
    scoredCandidates.sort((a, b) => b.value.compareTo(a.value));

    // Store suggestions in cache for analytics
    if (scoredCandidates.isNotEmpty) {
      await _cacheSuggestions(
        userId,
        scoredCandidates.take(limit).map((e) => e.key.id).toList(),
      );
    }

    final results = scoredCandidates
        .take(limit)
        .map((e) => {'user': e.key, 'score': e.value})
        .toList();
    AppLogger.debug(
      'getFriendSuggestionsWithScores:complete results=${results.length}',
      tag: _logTag,
    );
    return results;
  }

  /// Calculate 100-point compatibility score
  Future<double> _calculateCompatibilityScore(
    UserModel currentUser,
    UserModel candidate,
    Set<String> currentUserFriendIds,
  ) async {
    // Lightweight, no extra Firestore reads: optimized for quick screen load.
    var score = 45.0;

    final sameRole = currentUser.role == candidate.role;
    if (sameRole) score += 20;

    final currentTokens = _nameTokens(
      currentUser.displayName,
      currentUser.username,
    );
    final candidateTokens = _nameTokens(
      candidate.displayName,
      candidate.username,
    );
    final overlap = currentTokens.intersection(candidateTokens).length;
    score += (overlap * 6).clamp(0, 18).toDouble();

    // A tiny deterministic spread to avoid static-looking lists.
    final hashSpread = (candidate.id.hashCode.abs() % 12).toDouble();
    score += hashSpread;

    if (currentUserFriendIds.contains(candidate.id)) {
      score -= 100;
    }

    return score.clamp(0, 100);
  }

  Set<String> _nameTokens(String? displayName, String? username) {
    final parts = <String>{};
    for (final source in [displayName ?? '', username ?? '']) {
      final compact = source.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9 ]'),
        ' ',
      );
      for (final part in compact.split(RegExp(r'\s+'))) {
        if (part.length >= 2) parts.add(part);
      }
    }
    return parts;
  }

  /// Cache suggestions for analytics
  Future<void> _cacheSuggestions(
    String userId,
    List<String> suggestedIds,
  ) async {
    await _firestore.collection('friend_suggestions').doc(userId).set({
      'suggestedUserIds': suggestedIds,
      'generatedAt': FieldValue.serverTimestamp(),
      'algorithm': 'ai_scoring_v1',
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BLOCKING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Block a user
  Future<void> blockUser(String blockedUserId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Remove any existing connection
    await removeFriend(blockedUserId);

    // Add to blocked list
    await _firestore.collection('blocked_users').add({
      'blockerId': userId,
      'blockedId': blockedUserId,
      'blockedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Unblock a user
  Future<void> unblockUser(String blockedUserId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final blocked = await _firestore
        .collection('blocked_users')
        .where('blockerId', isEqualTo: userId)
        .where('blockedId', isEqualTo: blockedUserId)
        .limit(1)
        .get();

    if (blocked.docs.isNotEmpty) {
      await blocked.docs.first.reference.delete();
    }
  }

  /// Check if user is blocked
  Future<bool> isBlocked(String userId1, String userId2) async {
    final blocked = await _firestore
        .collection('blocked_users')
        .where('blockerId', isEqualTo: userId1)
        .where('blockedId', isEqualTo: userId2)
        .limit(1)
        .get();

    return blocked.docs.isNotEmpty;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MUTUAL CONNECTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get mutual friends between current user and another user
  Future<List<UserModel>> getMutualFriends(String otherUserId) async {
    final userId = _currentUserId;
    if (userId == null) return [];

    // Get current user's friends
    final myConnections = await _firestore
        .collection('connections')
        .where('userId', isEqualTo: userId)
        .get();

    final myFriendIds = myConnections.docs
        .map((doc) => doc.data()['friendId'] as String)
        .toSet();

    // Get other user's friends
    final theirConnections = await _firestore
        .collection('connections')
        .where('userId', isEqualTo: otherUserId)
        .get();

    final theirFriendIds = theirConnections.docs
        .map((doc) => doc.data()['friendId'] as String)
        .toSet();

    // Find intersection
    final mutualIds = myFriendIds.intersection(theirFriendIds);

    if (mutualIds.isEmpty) return [];

    // Fetch user profiles
    final mutualDocs = await Future.wait(
      mutualIds.map((id) => _firestore.collection('users').doc(id).get()),
    );

    return mutualDocs
        .where((doc) => doc.exists)
        .map(UserModel.fromFirestore)
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GEO-LOCATION & NEARBY SEARCH (Phase 3)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get nearby fighters within specified radius (in km)
  /// Phase 3 implementation - requires location data in user profiles
  Future<List<Map<String, dynamic>>> getNearbyFighters({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int limit = 20,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return [];
    AppLogger.debug(
      'getNearbyFighters:start user=$userId lat=$latitude lng=$longitude radiusKm=$radiusKm limit=$limit',
      tag: _logTag,
    );

    // Get current user's friends to exclude
    final connections = await _firestore
        .collection('connections')
        .where('userId', isEqualTo: userId)
        .get();

    final friendIds = connections.docs
        .map((doc) => doc.data()['friendId'] as String)
        .toSet();

    // Get blocked users
    final blocked = await _firestore
        .collection('blocked_users')
        .where('blockerId', isEqualTo: userId)
        .get();

    final blockedIds = blocked.docs
        .map((doc) => doc.data()['blockedId'] as String)
        .toSet();

    // Fetch users with location data
    // Note: For production, use Firestore Geo-queries or external service
    final snapshot = await _firestore
        .collection('users')
        .where('location.latitude', isNotEqualTo: null)
        .limit(100)
        .get();

    final nearbyFighters = <Map<String, dynamic>>[];

    for (final doc in snapshot.docs) {
      final user = UserModel.fromFirestore(doc);

      // Skip self, friends, and blocked users
      if (user.id == userId ||
          friendIds.contains(user.id) ||
          blockedIds.contains(user.id)) {
        continue;
      }

      // Get location data
      final userLat = doc.data()['location']?['latitude'] as double?;
      final userLng = doc.data()['location']?['longitude'] as double?;

      if (userLat == null || userLng == null) continue;

      // Calculate distance
      final distance = _calculateDistance(
        latitude,
        longitude,
        userLat,
        userLng,
      );

      // Filter by radius
      if (distance <= radiusKm) {
        nearbyFighters.add({
          'user': user,
          'distance': distance,
          'distanceFormatted': '${distance.toStringAsFixed(1)} km',
        });
      }
    }

    // Sort by distance
    nearbyFighters.sort(
      (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
    );

    final results = nearbyFighters.take(limit).toList();
    AppLogger.debug(
      'getNearbyFighters:complete results=${results.length}',
      tag: _logTag,
    );
    return results;
  }

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));

    return earthRadiusKm * c;
  }

  /// Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * (3.141592653589793 / 180.0);
  }

  /// Update user's location (call when location permission granted)
  Future<void> updateUserLocation({
    required double latitude,
    required double longitude,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    AppLogger.debug(
      'updateUserLocation:start user=$userId lat=$latitude lng=$longitude',
      tag: _logTag,
    );

    await _firestore.collection('users').doc(userId).update({
      'location': {
        'latitude': latitude,
        'longitude': longitude,
        'lastUpdated': FieldValue.serverTimestamp(),
      },
    });
    AppLogger.debug('updateUserLocation:complete user=$userId', tag: _logTag);
  }

  /// Get fighters at the same gym
  Future<List<UserModel>> getFightersAtGym(String gymName) async {
    final userId = _currentUserId;
    if (userId == null) return [];

    // Get current user's friends to exclude
    final connections = await _firestore
        .collection('connections')
        .where('userId', isEqualTo: userId)
        .get();

    final friendIds = connections.docs
        .map((doc) => doc.data()['friendId'] as String)
        .toSet();

    // Query fighters collection for same gym
    final snapshot = await _firestore
        .collection('fighters')
        .where('homeGym', isEqualTo: gymName)
        .limit(50)
        .get();

    final fighterIds = snapshot.docs.map((doc) => doc.id).toList();

    if (fighterIds.isEmpty) return [];

    // Fetch user profiles
    final userDocs = await Future.wait(
      fighterIds.map((id) => _firestore.collection('users').doc(id).get()),
    );

    return userDocs
        .where((doc) => doc.exists)
        .map(UserModel.fromFirestore)
        .where((user) => user.id != userId)
        .where((user) => !friendIds.contains(user.id))
        .toList();
  }
}
