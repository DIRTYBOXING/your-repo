import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../models/friend_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';

/// Whether the app was launched with Firebase emulator support.
const bool _useFirebaseEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');

/// Relationship status between two users
enum RelationshipStatus { none, pending, friend, blocked, follower }

/// ═══════════════════════════════════════════════════════════════════════════
/// ENHANCED FRIENDS SERVICE — Complete Social Network Management
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Handles:
/// - Friend requests (send, accept, reject, cancel)
/// - Friend management (list, remove, block)
/// - Friend counts and statistics
/// - Online status and last active
/// - Connection strength scoring
/// - Friend suggestions with AI
/// - Mutual friends discovery
/// - Friend activity tracking
/// ═══════════════════════════════════════════════════════════════════════════
class EnhancedFriendsService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Set<String> _handledDemoRequestIds = <String>{};
  Stream<int>? _pendingRequestCountStream;
  String? _pendingRequestCountUserId;
  Stream<int>? _friendCountStream;
  String? _friendCountUserId;

  static const String _connectionsCollection = 'connections';
  static const String _requestsCollection = 'friend_requests';
  static const String _suggestionsCollection = 'friend_suggestions';

  String _photoUrlFromUserData(Map<String, dynamic> data) =>
      (data['photoUrl'] ?? data['photoURL'] ?? '').toString();

  String _displayNameFromUserData(Map<String, dynamic> data) =>
      (data['displayName'] ?? data['name'] ?? 'Unknown').toString();

  String? get currentUserId => _auth.currentUser?.uid;

  /// Auth is considered enabled when the constant says so OR when running
  /// against the Firebase emulator (emulator provides real auth).
  static bool get _effectiveAuthEnabled =>
      AppConstants.authEnabled || _useFirebaseEmulator;

  bool get _useDemoData =>
      !_effectiveAuthEnabled ||
      AppConstants.guestMode ||
      (_auth.currentUser == null && !_useFirebaseEmulator) ||
      (_auth.currentUser?.isAnonymous == true && !_useFirebaseEmulator);

  // ═══════════════════════════════════════════════════════════════════════════
  // FRIEND REQUESTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Send a friend request with optional message
  Future<void> sendFriendRequest({
    required String recipientId,
    String? message,
  }) async {
    final senderId = currentUserId;
    if (senderId == null) throw Exception('User not authenticated');
    if (senderId == recipientId) {
      throw Exception('Cannot send request to self');
    }

    // Demo mode — accept immediately without Firestore
    final user = _auth.currentUser;
    if (user != null && user.isAnonymous) {
      AppLogger.info(
        'Demo friend request sent: $senderId → $recipientId',
        tag: 'EnhancedFriendsService',
      );
      notifyListeners();
      return;
    }

    // Check if already friends
    final existingConnection = await areFriends(senderId, recipientId);
    if (existingConnection) throw Exception('Already friends');

    // Check if request already exists
    final existingRequest = await _db
        .collection(_requestsCollection)
        .where('senderId', isEqualTo: senderId)
        .where('recipientId', isEqualTo: recipientId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existingRequest.docs.isNotEmpty) {
      throw Exception('Friend request already sent');
    }

    // Get sender info
    final senderDoc = await _db.collection('users').doc(senderId).get();
    final senderData = senderDoc.data() ?? {};

    // Get mutual friends
    final mutualFriends = await getMutualFriends(senderId, recipientId);

    // Create request
    final request = FriendRequest(
      id: _db.collection(_requestsCollection).doc().id,
      senderId: senderId,
      senderName: _displayNameFromUserData(senderData),
      senderPhotoUrl: _photoUrlFromUserData(senderData),
      senderRole: senderData['role'] ?? 'fighter',
      recipientId: recipientId,
      message: message,
      mutualFriendsCount: mutualFriends.length,
      mutualFriendIds: mutualFriends,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );

    await _db
        .collection(_requestsCollection)
        .doc(request.id)
        .set(request.toFirestore());

    // Notify recipient about the incoming friend request
    _emitNotification(
      recipientId: recipientId,
      type: NotificationType.friendRequest,
      title: 'New friend request',
      body: '${_displayNameFromUserData(senderData)} sent you a friend request',
      actionRoute: '/friend-requests',
      senderId: senderId,
      senderName: _displayNameFromUserData(senderData),
      senderAvatar: _photoUrlFromUserData(senderData),
    );

    AppLogger.info(
      'Friend request sent: $senderId → $recipientId',
      tag: 'EnhancedFriendsService',
    );
    notifyListeners();
  }

  /// Accept a friend request
  Future<void> acceptFriendRequest(String requestId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    if (requestId.startsWith('demo_req_')) {
      _handledDemoRequestIds.add(requestId);
      AppLogger.info(
        'Demo friend request accepted: $requestId',
        tag: 'EnhancedFriendsService',
      );
      notifyListeners();
      return;
    }

    final requestDoc = await _db
        .collection(_requestsCollection)
        .doc(requestId)
        .get();
    if (!requestDoc.exists) {
      throw Exception('This request is no longer available');
    }

    final request = FriendRequest.fromFirestore(requestDoc);
    if (request.recipientId != userId) {
      throw Exception('Not authorized to accept this request');
    }

    if (request.status != 'pending') {
      throw Exception('This request is no longer available');
    }

    // Get both users' data
    final senderDoc = await _db.collection('users').doc(request.senderId).get();
    final recipientDoc = await _db.collection('users').doc(userId).get();

    final senderData = senderDoc.data() ?? {};
    final recipientData = recipientDoc.data() ?? {};

    final batch = _db.batch();

    // Create bidirectional friendship
    final connection1 = Friend(
      id: '${request.senderId}_$userId',
      userId: request.senderId,
      friendId: userId,
      friendName: _displayNameFromUserData(recipientData),
      friendPhotoUrl: _photoUrlFromUserData(recipientData),
      friendRole: recipientData['role'] ?? 'fighter',
      connectedAt: DateTime.now(),
      mutualFriends: request.mutualFriendsCount,
    );

    final connection2 = Friend(
      id: '${userId}_${request.senderId}',
      userId: userId,
      friendId: request.senderId,
      friendName: _displayNameFromUserData(senderData),
      friendPhotoUrl: _photoUrlFromUserData(senderData),
      friendRole: senderData['role'] ?? 'fighter',
      connectedAt: DateTime.now(),
      mutualFriends: request.mutualFriendsCount,
    );

    batch.set(
      _db.collection(_connectionsCollection).doc(connection1.id),
      connection1.toFirestore(),
    );
    batch.set(
      _db.collection(_connectionsCollection).doc(connection2.id),
      connection2.toFirestore(),
    );

    // Update request status
    batch.update(_db.collection(_requestsCollection).doc(requestId), {
      'status': 'accepted',
      'respondedAt': FieldValue.serverTimestamp(),
    });

    // Update friend counts
    batch.set(_db.collection('users').doc(request.senderId), {
      'friendCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
    batch.set(_db.collection('users').doc(userId), {
      'friendCount': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await batch.commit();

    // Notify the sender that their request was accepted
    _emitNotification(
      recipientId: request.senderId,
      type: NotificationType.friendRequestAccepted,
      title: 'Friend request accepted',
      body:
          '${_displayNameFromUserData(recipientData)} accepted your friend request',
      actionRoute: '/user/$userId',
      senderId: userId,
      senderName: _displayNameFromUserData(recipientData),
      senderAvatar: _photoUrlFromUserData(recipientData),
    );

    AppLogger.info(
      'Friend request accepted: ${request.senderId} ↔ $userId',
      tag: 'EnhancedFriendsService',
    );
    notifyListeners();
  }

  /// Reject a friend request
  Future<void> rejectFriendRequest(String requestId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    if (requestId.startsWith('demo_req_')) {
      _handledDemoRequestIds.add(requestId);
      AppLogger.info(
        'Demo friend request rejected: $requestId',
        tag: 'EnhancedFriendsService',
      );
      notifyListeners();
      return;
    }

    final requestDoc = await _db
        .collection(_requestsCollection)
        .doc(requestId)
        .get();
    if (!requestDoc.exists) {
      throw Exception('This request is no longer available');
    }

    final request = FriendRequest.fromFirestore(requestDoc);
    if (request.recipientId != userId) {
      throw Exception('Not authorized to reject this request');
    }

    await _db.collection(_requestsCollection).doc(requestId).update({
      'status': 'rejected',
      'respondedAt': FieldValue.serverTimestamp(),
    });

    AppLogger.info(
      'Friend request rejected: ${request.senderId} → $userId',
      tag: 'EnhancedFriendsService',
    );
    notifyListeners();
  }

  /// Cancel a sent friend request
  Future<void> cancelFriendRequest(String recipientId) async {
    final senderId = currentUserId;
    if (senderId == null) throw Exception('User not authenticated');

    final requestQuery = await _db
        .collection(_requestsCollection)
        .where('senderId', isEqualTo: senderId)
        .where('recipientId', isEqualTo: recipientId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (requestQuery.docs.isEmpty) throw Exception('Request not found');

    await requestQuery.docs.first.reference.delete();

    AppLogger.info(
      'Friend request cancelled: $senderId → $recipientId',
      tag: 'EnhancedFriendsService',
    );
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FRIEND MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get friend count for a user
  Future<int> getFriendCount(String userId) async {
    if (_useDemoData) return _demoFriends.length;
    try {
      final snapshot = await _db
          .collection(_connectionsCollection)
          .where('userId', isEqualTo: userId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error('Error getting friend count', error: e);
      return 0;
    }
  }

  /// Stream friend count for current user
  Stream<int> streamFriendCount() {
    final userId = currentUserId;
    if (userId == null) return Stream.value(0);
    if (_useDemoData) return Stream.value(_demoFriends.length);

    if (_friendCountStream != null && _friendCountUserId == userId) {
      return _friendCountStream!;
    }

    final stream = _db
        .collection(_connectionsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((_) => 0)
        .asBroadcastStream();

    _friendCountUserId = userId;
    _friendCountStream = stream;
    return stream;
  }

  /// Stream of friends for a user
  Stream<List<Friend>> streamFriends(String userId) {
    if (_useDemoData) return Stream.value(_demoFriends);

    return _db
        .collection(_connectionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('connectedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(Friend.fromFirestore).toList(),
        )
        .handleError((_) => <Friend>[]);
  }

  /// Stream of pending friend requests
  Stream<List<FriendRequest>> streamPendingRequests() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);
    if (_useDemoData) return Stream.value(const <FriendRequest>[]);

    return _db
        .collection(_requestsCollection)
        .where('recipientId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map(FriendRequest.fromFirestore)
              .where((req) => !req.isExpired)
              .toList();
          return requests
              .where((req) => !_handledDemoRequestIds.contains(req.id))
              .toList();
        })
        .handleError((_) => const <FriendRequest>[]);
  }

  /// Stream of pending requests sent by current user.
  Stream<List<FriendRequest>> streamSentPendingRequests() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);
    if (_useDemoData) return Stream.value(const <FriendRequest>[]);

    return _db
        .collection(_requestsCollection)
        .where('senderId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(FriendRequest.fromFirestore)
              .where((req) => !req.isExpired)
              .toList(),
        )
        .handleError((_) => <FriendRequest>[]);
  }

  /// Stream pending request count
  Stream<int> streamPendingRequestCount() {
    final userId = currentUserId;
    if (userId == null) return Stream.value(0);
    if (_useDemoData) return Stream.value(0);

    if (_pendingRequestCountStream != null &&
        _pendingRequestCountUserId == userId) {
      return _pendingRequestCountStream!;
    }

    final stream = _db
        .collection(_requestsCollection)
        .where('recipientId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(FriendRequest.fromFirestore)
              .where((req) => !req.isExpired)
              .length;
        })
        .handleError((_) => 0)
        .asBroadcastStream();

    _pendingRequestCountUserId = userId;
    _pendingRequestCountStream = stream;
    return stream;
  }

  /// Remove a friend
  Future<void> removeFriend(String friendId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final batch = _db.batch();

    // Delete both directions
    batch.delete(
      _db.collection(_connectionsCollection).doc('${userId}_$friendId'),
    );
    batch.delete(
      _db.collection(_connectionsCollection).doc('${friendId}_$userId'),
    );

    // Update friend counts
    batch.update(_db.collection('users').doc(userId), {
      'friendCount': FieldValue.increment(-1),
    });
    batch.update(_db.collection('users').doc(friendId), {
      'friendCount': FieldValue.increment(-1),
    });

    await batch.commit();

    AppLogger.info(
      'Friend removed: $userId ↔ $friendId',
      tag: 'EnhancedFriendsService',
    );
    notifyListeners();
  }

  /// Check if two users are friends
  Future<bool> areFriends(String userId1, String userId2) async {
    final doc = await _db
        .collection(_connectionsCollection)
        .doc('${userId1}_$userId2')
        .get();
    return doc.exists;
  }

  /// Get mutual friends between two users
  Future<List<String>> getMutualFriends(String userId1, String userId2) async {
    try {
      final friends1 = await _db
          .collection(_connectionsCollection)
          .where('userId', isEqualTo: userId1)
          .get();

      final friends2 = await _db
          .collection(_connectionsCollection)
          .where('userId', isEqualTo: userId2)
          .get();

      final friendIds1 = friends1.docs
          .map((doc) => doc.data()['friendId'] as String)
          .toSet();
      final friendIds2 = friends2.docs
          .map((doc) => doc.data()['friendId'] as String)
          .toSet();

      return friendIds1.intersection(friendIds2).toList();
    } catch (e) {
      AppLogger.error('Error getting mutual friends', error: e);
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ONLINE STATUS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Update user's online status
  Future<void> setOnlineStatus(bool isOnline) async {
    final userId = currentUserId;
    if (userId == null) return;
    if (_useDemoData) return;

    await _db.collection('users').doc(userId).update({
      'isOnline': isOnline,
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  /// Get online friends
  Stream<List<String>> streamOnlineFriends() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return streamFriends(userId).asyncMap((friends) async {
      final onlineFriends = <String>[];
      for (final friend in friends) {
        if (friend.isOnline) {
          onlineFriends.add(friend.friendId);
        }
      }
      return onlineFriends;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FRIEND SUGGESTIONS — Will be expanded in Friend Suggestions Engine
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get basic friend suggestions (placeholder for full algorithm)
  Future<List<UserModel>> getFriendSuggestions({int limit = 10}) async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      // This is a basic implementation
      // Full algorithm will be in FriendSuggestionsEngine
      final suggestions = await _db
          .collection(_suggestionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('score', descending: true)
          .limit(limit)
          .get();

      final userIds = suggestions.docs
          .map((doc) => doc.data()['suggestedUserId'] as String)
          .toList();

      final users = <UserModel>[];
      for (final id in userIds) {
        final userDoc = await _db.collection('users').doc(id).get();
        if (userDoc.exists) {
          users.add(UserModel.fromFirestore(userDoc));
        }
      }

      return users;
    } catch (e) {
      AppLogger.error('Error getting friend suggestions', error: e);
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Search users for new friends
  Future<List<UserModel>> searchUsers(String query, {int limit = 20}) async {
    final userId = currentUserId;
    final q = query.trim().toLowerCase();
    if (userId == null || q.length < 2) return [];

    try {
      final tokenMatches = await _db
          .collection('users')
          .where('searchTokens', arrayContains: q)
          .limit(limit)
          .get();

      final namePrefixMatches = await _db
          .collection('users')
          .where('displayNameLower', isGreaterThanOrEqualTo: q)
          .where('displayNameLower', isLessThanOrEqualTo: '$q\uf8ff')
          .limit(limit)
          .get();

      final usernamePrefixMatches = await _db
          .collection('users')
          .where('usernameLower', isGreaterThanOrEqualTo: q)
          .where('usernameLower', isLessThanOrEqualTo: '$q\uf8ff')
          .limit(limit)
          .get();

      final docsById = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
        for (final doc in tokenMatches.docs) doc.id: doc,
        for (final doc in namePrefixMatches.docs) doc.id: doc,
        for (final doc in usernamePrefixMatches.docs) doc.id: doc,
      };

      return docsById.values
          .where((doc) => doc.id != userId)
          .map(UserModel.fromFirestore)
          .where((user) => user.isActive)
          .toList();
    } catch (e) {
      AppLogger.error('Error searching users', error: e);
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RELATIONSHIP STATUS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check relationship status between current user and another user.
  /// Uses the unified `connections` and `friend_requests` collections.
  Future<RelationshipStatus> getRelationshipStatus(String otherUserId) async {
    try {
      final uid = currentUserId;
      if (uid == null) return RelationshipStatus.none;

      // Check if already friends
      if (await areFriends(uid, otherUserId)) {
        return RelationshipStatus.friend;
      }

      // Check for pending request (either direction)
      final sentQuery = await _db
          .collection(_requestsCollection)
          .where('senderId', isEqualTo: uid)
          .where('recipientId', isEqualTo: otherUserId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (sentQuery.docs.isNotEmpty) return RelationshipStatus.pending;

      final receivedQuery = await _db
          .collection(_requestsCollection)
          .where('senderId', isEqualTo: otherUserId)
          .where('recipientId', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (receivedQuery.docs.isNotEmpty) return RelationshipStatus.pending;

      return RelationshipStatus.none;
    } catch (e) {
      AppLogger.error('Error checking relationship status', error: e);
      return RelationshipStatus.none;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BLOCK & MUTE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Block a user — removes friendship, cancels pending requests, prevents
  /// future contact. Writes a `blocked` connection record.
  Future<void> blockUser(String targetUserId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final batch = _db.batch();

    // Remove existing friendship (both directions)
    batch.delete(
      _db.collection(_connectionsCollection).doc('${userId}_$targetUserId'),
    );
    batch.delete(
      _db.collection(_connectionsCollection).doc('${targetUserId}_$userId'),
    );

    // Write block record
    batch.set(_db.collection('blocked_users').doc('${userId}_$targetUserId'), {
      'blockerId': userId,
      'blockedId': targetUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Also cancel any pending requests between the two users
    final pending = await _db
        .collection(_requestsCollection)
        .where('senderId', whereIn: [userId, targetUserId])
        .get();
    for (final doc in pending.docs) {
      final data = doc.data();
      final recipientId = data['recipientId'] as String?;
      if (recipientId == userId || recipientId == targetUserId) {
        await doc.reference.update({'status': 'cancelled'});
      }
    }

    AppLogger.info(
      'User blocked: $userId → $targetUserId',
      tag: 'EnhancedFriendsService',
    );
    notifyListeners();
  }

  /// Unblock a user
  Future<void> unblockUser(String targetUserId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _db
        .collection('blocked_users')
        .doc('${userId}_$targetUserId')
        .delete();

    AppLogger.info(
      'User unblocked: $userId → $targetUserId',
      tag: 'EnhancedFriendsService',
    );
    notifyListeners();
  }

  /// Check if a user is blocked
  Future<bool> isBlocked(String targetUserId) async {
    final userId = currentUserId;
    if (userId == null) return false;

    final doc = await _db
        .collection('blocked_users')
        .doc('${userId}_$targetUserId')
        .get();
    return doc.exists;
  }

  /// Mute a user — hides their posts from feed, suppresses notifications.
  Future<void> muteUser(String targetUserId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _db.collection('muted_users').doc('${userId}_$targetUserId').set({
      'muterId': userId,
      'mutedId': targetUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    AppLogger.info(
      'User muted: $userId → $targetUserId',
      tag: 'EnhancedFriendsService',
    );
    notifyListeners();
  }

  /// Unmute a user
  Future<void> unmuteUser(String targetUserId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _db.collection('muted_users').doc('${userId}_$targetUserId').delete();

    AppLogger.info(
      'User unmuted: $userId → $targetUserId',
      tag: 'EnhancedFriendsService',
    );
    notifyListeners();
  }

  /// Check if a user is muted
  Future<bool> isMuted(String targetUserId) async {
    final userId = currentUserId;
    if (userId == null) return false;

    final doc = await _db
        .collection('muted_users')
        .doc('${userId}_$targetUserId')
        .get();
    return doc.exists;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTIFICATION HELPER
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fire-and-forget notification write to `notifications/{recipientId}/items`
  void _emitNotification({
    required String recipientId,
    required NotificationType type,
    required String title,
    required String body,
    String? actionRoute,
    String? senderId,
    String? senderName,
    String? senderAvatar,
  }) {
    final ref = _db
        .collection('notifications')
        .doc(recipientId)
        .collection('items')
        .doc();
    final notification = NotificationModel(
      id: ref.id,
      userId: recipientId,
      type: type,
      title: title,
      body: body,
      actionRoute: actionRoute,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      createdAt: DateTime.now(),
    );
    ref.set(notification.toFirestore()).catchError((e) {
      AppLogger.error('Failed to emit notification', error: e);
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEMO DATA — Shown when Firestore has no connections
  // ═══════════════════════════════════════════════════════════════════════════

  static final List<Friend> _demoFriends = [
    Friend(
      id: 'demo_conn_1',
      userId: 'emergency_local_session',
      friendId: 'demo_user_jordan',
      friendName: 'Jordan Roesler',
      isOnline: true,
      connectedAt: DateTime(2026, 3, 15),
      connectionStrength: 92,
      mutualFriends: 4,
      sharedInterests: const ['Boxing', 'Super Welterweight', 'Melbourne'],
    ),
    Friend(
      id: 'demo_conn_2',
      userId: 'emergency_local_session',
      friendId: 'demo_user_joshy',
      friendName: 'Joshy Bomber Richards',
      isOnline: true,
      connectedAt: DateTime(2026, 3, 24),
      connectionStrength: 78,
      mutualFriends: 2,
      sharedInterests: const ['Boxing', 'Melbourne', 'SHDW Boxing Gym'],
    ),
    Friend(
      id: 'demo_conn_3',
      userId: 'emergency_local_session',
      friendId: 'demo_user_joey',
      friendName: 'Joey Demicoli',
      friendRole: 'promoter',
      lastActive: DateTime.now().subtract(const Duration(hours: 2)),
      connectedAt: DateTime(2026, 1, 10),
      connectionStrength: 95,
      mutualFriends: 8,
      sharedInterests: const ['Boxing', 'Promotions', 'Ultimate Legends'],
    ),
    Friend(
      id: 'demo_conn_4',
      userId: 'emergency_local_session',
      friendId: 'demo_user_karim',
      friendName: 'Karim Maatalla',
      lastActive: DateTime.now().subtract(const Duration(hours: 5)),
      connectedAt: DateTime(2026, 2, 20),
      connectionStrength: 70,
      mutualFriends: 3,
      sharedInterests: const ['Boxing', 'Melbourne'],
    ),
    Friend(
      id: 'demo_conn_5',
      userId: 'emergency_local_session',
      friendId: 'demo_user_stephanie',
      friendName: 'Stephanie Lee Cutting',
      isOnline: true,
      connectedAt: DateTime(2026, 3),
      connectionStrength: 82,
      mutualFriends: 5,
      sharedInterests: const ['Boxing', 'Women\'s Boxing'],
    ),
    Friend(
      id: 'demo_conn_6',
      userId: 'emergency_local_session',
      friendId: 'demo_user_dylan',
      friendName: 'Dylan Birdo',
      lastActive: DateTime.now().subtract(const Duration(minutes: 30)),
      connectedAt: DateTime(2026, 3, 10),
      connectionStrength: 74,
      mutualFriends: 2,
      sharedInterests: const ['K1 Kickboxing', 'Melbourne'],
    ),
    Friend(
      id: 'demo_conn_7',
      userId: 'emergency_local_session',
      friendId: 'demo_user_sumire',
      friendName: 'Sumire Yamanaka',
      lastActive: DateTime.now().subtract(const Duration(hours: 1)),
      connectedAt: DateTime(2026, 4, 5),
      connectionStrength: 60,
      mutualFriends: 1,
      sharedInterests: const ['Boxing', 'Atomweight', 'Tokyo'],
    ),
    Friend(
      id: 'demo_conn_8',
      userId: 'emergency_local_session',
      friendId: 'demo_user_john',
      friendName: 'John Scida',
      friendRole: 'promoter',
      lastActive: DateTime.now().subtract(const Duration(hours: 8)),
      connectedAt: DateTime(2025, 12),
      connectionStrength: 88,
      mutualFriends: 6,
      sharedInterests: const [
        'Boxing',
        'Promotions',
        'Ultimate Legends',
        'Melbourne',
      ],
    ),
  ];
}
