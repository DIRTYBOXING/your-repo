import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/utils/app_logger.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// RELATIONSHIPS SERVICE - Friend Requests, Followers, Blocking
/// ═══════════════════════════════════════════════════════════════════════════
/// Manages user relationships: friends, followers, friend requests, blocks
/// ═══════════════════════════════════════════════════════════════════════════

enum RelationshipStatus { none, pending, friend, blocked, follower }

class RelationshipsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _connectionsCollection = 'user_connections';
  static const String _requestsCollection = 'friend_requests';

  /// Send friend request to another user
  Future<bool> sendFriendRequest(String targetUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final requestId = '${currentUser.uid}_$targetUserId';

      await _firestore.collection(_requestsCollection).doc(requestId).set({
        'fromId': currentUser.uid,
        'toId': targetUserId,
        'status': 'pending', // pending, accepted, rejected
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info(
        'Friend request sent: ${currentUser.uid} -> $targetUserId',
        tag: 'RelationshipsService',
      );
      return true;
    } catch (e) {
      AppLogger.error(
        'Error sending friend request',
        error: e,
        tag: 'RelationshipsService',
      );
      return false;
    }
  }

  /// Accept a friend request
  Future<bool> acceptFriendRequest(String fromUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final requestId = '${fromUserId}_${currentUser.uid}';

      // Update request status
      await _firestore.collection(_requestsCollection).doc(requestId).update({
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create friendship record (bidirectional)
      await _firestore
          .collection(_connectionsCollection)
          .doc('${currentUser.uid}_$fromUserId')
          .set({
            'userId1': currentUser.uid,
            'userId2': fromUserId,
            'type': 'friend',
            'connectedAt': FieldValue.serverTimestamp(),
          });

      await _firestore
          .collection(_connectionsCollection)
          .doc('${fromUserId}_${currentUser.uid}')
          .set({
            'userId1': fromUserId,
            'userId2': currentUser.uid,
            'type': 'friend',
            'connectedAt': FieldValue.serverTimestamp(),
          });

      AppLogger.info(
        'Friend request accepted: $fromUserId <> ${currentUser.uid}',
        tag: 'RelationshipsService',
      );
      return true;
    } catch (e) {
      AppLogger.error(
        'Error accepting friend request',
        error: e,
        tag: 'RelationshipsService',
      );
      return false;
    }
  }

  /// Reject a friend request
  Future<bool> rejectFriendRequest(String fromUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final requestId = '${fromUserId}_${currentUser.uid}';

      await _firestore.collection(_requestsCollection).doc(requestId).update({
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info(
        'Friend request rejected: $fromUserId',
        tag: 'RelationshipsService',
      );
      return true;
    } catch (e) {
      AppLogger.error(
        'Error rejecting friend request',
        error: e,
        tag: 'RelationshipsService',
      );
      return false;
    }
  }

  /// Get pending friend requests FOR the current user
  Future<List<String>> getPendingRequests() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final snapshot = await _firestore
          .collection(_requestsCollection)
          .where('toId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['fromId'] as String)
          .toList();
    } catch (e) {
      AppLogger.error(
        'Error fetching pending requests',
        error: e,
        tag: 'RelationshipsService',
      );
      return [];
    }
  }

  /// Stream of pending friend requests (real-time)
  Stream<int> pendingRequestCountStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(0);

    return _firestore
        .collection(_requestsCollection)
        .where('toId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((e) {
          AppLogger.error(
            'Error in pending request stream',
            error: e,
            tag: 'RelationshipsService',
          );
          return 0;
        });
  }

  /// Stream pending requester user IDs for current user
  Stream<List<String>> pendingRequestsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(const <String>[]);

    return _firestore
        .collection(_requestsCollection)
        .where('toId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data()['fromId'] as String)
              .toList(),
        )
        .handleError((e) {
          AppLogger.error(
            'Error in pending requests stream',
            error: e,
            tag: 'RelationshipsService',
          );
          return <String>[];
        });
  }

  /// Get all friends of a user
  Future<List<String>> getFriends(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_connectionsCollection)
          .where('userId1', isEqualTo: userId)
          .where('type', isEqualTo: 'friend')
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['userId2'] as String)
          .toList();
    } catch (e) {
      AppLogger.error(
        'Error fetching friends',
        error: e,
        tag: 'RelationshipsService',
      );
      return [];
    }
  }

  /// Stream friend user IDs for a given user
  Stream<List<String>> friendsStream(String userId) {
    return _firestore
        .collection(_connectionsCollection)
        .where('userId1', isEqualTo: userId)
        .where('type', isEqualTo: 'friend')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data()['userId2'] as String)
              .toList(),
        )
        .handleError((e) {
          AppLogger.error(
            'Error in friends stream',
            error: e,
            tag: 'RelationshipsService',
          );
          return <String>[];
        });
  }

  /// Check relationship status between current user and another user
  Future<RelationshipStatus> getRelationshipStatus(String otherUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return RelationshipStatus.none;

      // Check if already friends
      final friendDoc = await _firestore
          .collection(_connectionsCollection)
          .doc('${currentUser.uid}_$otherUserId')
          .get();

      if (friendDoc.exists && friendDoc.data()?['type'] == 'friend') {
        return RelationshipStatus.friend;
      }

      // Check for pending request (current user sent)
      final sentRequest = await _firestore
          .collection(_requestsCollection)
          .doc('${currentUser.uid}_$otherUserId')
          .get();

      if (sentRequest.exists && sentRequest.data()?['status'] == 'pending') {
        return RelationshipStatus.pending;
      }

      // Check for pending request (other user sent)
      final receivedRequest = await _firestore
          .collection(_requestsCollection)
          .doc('${otherUserId}_${currentUser.uid}')
          .get();

      if (receivedRequest.exists &&
          receivedRequest.data()?['status'] == 'pending') {
        return RelationshipStatus.pending;
      }

      // Check if blocked
      final blockedDoc = await _firestore
          .collection(_connectionsCollection)
          .doc('${currentUser.uid}_$otherUserId')
          .get();

      if (blockedDoc.exists && blockedDoc.data()?['type'] == 'blocked') {
        return RelationshipStatus.blocked;
      }

      return RelationshipStatus.none;
    } catch (e) {
      AppLogger.error(
        'Error checking relationship status',
        error: e,
        tag: 'RelationshipsService',
      );
      return RelationshipStatus.none;
    }
  }

  /// Follow a user (asymmetric relationship)
  Future<bool> followUser(String targetUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      await _firestore
          .collection(_connectionsCollection)
          .doc('${currentUser.uid}_$targetUserId')
          .set({
            'userId1': currentUser.uid,
            'userId2': targetUserId,
            'type': 'follower',
            'followedAt': FieldValue.serverTimestamp(),
          });

      AppLogger.info(
        'User followed: $targetUserId',
        tag: 'RelationshipsService',
      );
      return true;
    } catch (e) {
      AppLogger.error(
        'Error following user',
        error: e,
        tag: 'RelationshipsService',
      );
      return false;
    }
  }

  /// Unfollow a user
  Future<bool> unfollowUser(String targetUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      await _firestore
          .collection(_connectionsCollection)
          .doc('${currentUser.uid}_$targetUserId')
          .delete();

      AppLogger.info(
        'User unfollowed: $targetUserId',
        tag: 'RelationshipsService',
      );
      return true;
    } catch (e) {
      AppLogger.error(
        'Error unfollowing user',
        error: e,
        tag: 'RelationshipsService',
      );
      return false;
    }
  }

  /// Block a user
  Future<bool> blockUser(String targetUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Remove friendship if exists
      // Remove follower relationship if exists

      await _firestore
          .collection(_connectionsCollection)
          .doc('${currentUser.uid}_$targetUserId')
          .set({
            'userId1': currentUser.uid,
            'userId2': targetUserId,
            'type': 'blocked',
            'blockedAt': FieldValue.serverTimestamp(),
          });

      AppLogger.info(
        'User blocked: $targetUserId',
        tag: 'RelationshipsService',
      );
      return true;
    } catch (e) {
      AppLogger.error(
        'Error blocking user',
        error: e,
        tag: 'RelationshipsService',
      );
      return false;
    }
  }

  /// Unblock a user
  Future<bool> unblockUser(String targetUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      await _firestore
          .collection(_connectionsCollection)
          .doc('${currentUser.uid}_$targetUserId')
          .delete();

      AppLogger.info(
        'User unblocked: $targetUserId',
        tag: 'RelationshipsService',
      );
      return true;
    } catch (e) {
      AppLogger.error(
        'Error unblocking user',
        error: e,
        tag: 'RelationshipsService',
      );
      return false;
    }
  }

  /// Get count of friends
  Future<int> getFriendCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_connectionsCollection)
          .where('userId1', isEqualTo: userId)
          .where('type', isEqualTo: 'friend')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error(
        'Error fetching friend count',
        error: e,
        tag: 'RelationshipsService',
      );
      return 0;
    }
  }

  /// Get count of followers
  Future<int> getFollowerCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_connectionsCollection)
          .where('userId2', isEqualTo: userId)
          .where('type', isEqualTo: 'follower')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.error(
        'Error fetching follower count',
        error: e,
        tag: 'RelationshipsService',
      );
      return 0;
    }
  }

  /// Remove a friend
  Future<bool> removeFriend(String friendUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Remove bidirectional friendship
      await _firestore
          .collection(_connectionsCollection)
          .doc('${currentUser.uid}_$friendUserId')
          .delete();
      await _firestore
          .collection(_connectionsCollection)
          .doc('${friendUserId}_${currentUser.uid}')
          .delete();

      AppLogger.info(
        'Friend removed: $friendUserId',
        tag: 'RelationshipsService',
      );
      return true;
    } catch (e) {
      AppLogger.error(
        'Error removing friend',
        error: e,
        tag: 'RelationshipsService',
      );
      return false;
    }
  }
}
