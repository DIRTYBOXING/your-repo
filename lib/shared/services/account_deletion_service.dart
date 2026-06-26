import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';

/// Cascade-deletes ALL user data across Firestore collections + Storage.
/// GDPR Article 17 · AU Privacy Principle 13 · Apple App Store Requirement 5.1.1
class AccountDeletionService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isDeleting = false;
  bool get isDeleting => _isDeleting;

  String _status = '';
  String get status => _status;

  double _progress = 0.0;
  double get progress => _progress;

  // All Firestore collections where user data may exist, keyed by userId field name
  static const Map<String, String> _userCollections = {
    'posts': 'authorId',
    'comments': 'authorId',
    'fightwire_posts': 'authorId',
    'messages': 'senderId',
    'conversations': 'participants', // array-contains
    'friend_requests': 'fromUserId',
    'user_connections': 'userId',
    'notifications': 'userId', // subcollection parent
    'reactions': 'userId',
    'saved_posts': 'userId',
    'stories': 'authorId',
    'story_highlights': 'userId',
    'watch_history': 'userId',
    'ppv_access': 'userId',
    'ppv_purchases': 'userId',
    'consents': 'userId',
    'audit_logs': 'userId',
    'export_packages': 'userId',
    'user_onboarding': 'userId',
    'fighter_stats': 'fighterId',
    'training_logs': 'userId',
    'wellness_logs': 'userId',
    'articles': 'authorId',
    'marketplace_listings': 'sellerId',
    'report_history': 'reporterId',
    'blocked_users': 'userId',
  };

  // Collections where userId appears in a different field (received items)
  static const Map<String, String> _receivedCollections = {
    'friend_requests': 'toUserId',
    'messages': 'receiverId',
  };

  /// Full cascade deletion — call BEFORE deleting Firebase Auth user.
  /// Returns true if all steps succeeded.
  Future<bool> deleteAllUserData(String userId) async {
    _isDeleting = true;
    _progress = 0.0;
    _status = 'Starting account deletion...';
    notifyListeners();

    try {
      final totalSteps =
          _userCollections.length +
          _receivedCollections.length +
          3; // storage + subcollections + user doc
      var completed = 0;

      // 1. Delete from each collection where user is author/owner
      for (final entry in _userCollections.entries) {
        _status = 'Removing ${entry.key}...';
        notifyListeners();

        if (entry.key == 'notifications') {
          // Subcollection pattern: notifications/{userId}/items
          await _deleteSubcollection('notifications/$userId/items');
          await _db.collection('notifications').doc(userId).delete();
        } else if (entry.value == 'participants') {
          // Array-contains query for conversations
          await _deleteByArrayContains(entry.key, entry.value, userId);
        } else {
          await _deleteByField(entry.key, entry.value, userId);
        }

        completed++;
        _progress = completed / totalSteps;
        notifyListeners();
      }

      // 2. Clean up received items (friend requests to this user, messages to this user)
      for (final entry in _receivedCollections.entries) {
        _status = 'Cleaning ${entry.key} (received)...';
        notifyListeners();

        await _deleteByField(entry.key, entry.value, userId);
        completed++;
        _progress = completed / totalSteps;
        notifyListeners();
      }

      // 3. Remove user references from other users' friend lists
      _status = 'Removing from friend lists...';
      notifyListeners();
      await _removeFromFriendLists(userId);

      // 4. Delete media from Firebase Storage
      _status = 'Deleting uploaded media...';
      notifyListeners();
      await _deleteUserStorage(userId);
      completed++;
      _progress = completed / totalSteps;
      notifyListeners();

      // 5. Delete the user document itself
      _status = 'Deleting user profile...';
      notifyListeners();
      await _db.collection(AppConstants.usersCollection).doc(userId).delete();
      completed++;
      _progress = completed / totalSteps;
      notifyListeners();

      // 6. Log the deletion for audit trail (anonymized)
      await _db.collection('deletion_audit').add({
        'deletedUserId': userId.hashCode.toString(), // anonymized
        'deletedAt': FieldValue.serverTimestamp(),
        'collectionsProcessed': _userCollections.keys.toList(),
        'status': 'completed',
      });

      _status = 'Account deleted successfully.';
      _progress = 1.0;
      notifyListeners();
      return true;
    } catch (e) {
      _status = 'Deletion failed: ${e.toString()}';
      notifyListeners();
      debugPrint('AccountDeletion error: $e');
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  /// Delete all docs in a collection where [field] == [userId]
  Future<void> _deleteByField(
    String collection,
    String field,
    String userId,
  ) async {
    const batchLimit = 400; // Firestore batch limit is 500, leave margin
    QuerySnapshot snapshot;

    do {
      snapshot = await _db
          .collection(collection)
          .where(field, isEqualTo: userId)
          .limit(batchLimit)
          .get();

      if (snapshot.docs.isEmpty) break;

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } while (snapshot.docs.length == batchLimit);
  }

  /// Delete docs where array field contains userId
  Future<void> _deleteByArrayContains(
    String collection,
    String field,
    String userId,
  ) async {
    final snapshot = await _db
        .collection(collection)
        .where(field, arrayContains: userId)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      // For conversations, remove user from participants rather than deleting
      final participants = List<String>.from(doc.data()[field] ?? []);
      if (participants.length <= 2) {
        // 1-on-1 conversation — delete entirely
        batch.delete(doc.reference);
      } else {
        // Group chat — just remove this user
        batch.update(doc.reference, {
          field: FieldValue.arrayRemove([userId]),
        });
      }
    }
    await batch.commit();
  }

  /// Delete all docs in a subcollection
  Future<void> _deleteSubcollection(String path) async {
    const batchLimit = 400;
    QuerySnapshot snapshot;

    do {
      snapshot = await _db.collection(path).limit(batchLimit).get();
      if (snapshot.docs.isEmpty) break;

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } while (snapshot.docs.length == batchLimit);
  }

  /// Remove userId from other users' connection documents
  Future<void> _removeFromFriendLists(String userId) async {
    // Remove where this user is the "friend" in someone else's connection
    final friendOf = await _db
        .collection('user_connections')
        .where('friendId', isEqualTo: userId)
        .get();

    if (friendOf.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in friendOf.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Delete all files in Firebase Storage under user paths
  Future<void> _deleteUserStorage(String userId) async {
    final prefixes = [
      'user_media/$userId/',
      'profile_photos/$userId/',
      'post_media/$userId/',
      'story_media/$userId/',
      'chat_media/$userId/',
    ];

    for (final prefix in prefixes) {
      try {
        final listResult = await _storage.ref(prefix).listAll();
        for (final item in listResult.items) {
          await item.delete();
        }
        // Also delete items in subdirectories
        for (final subDir in listResult.prefixes) {
          final subList = await subDir.listAll();
          for (final item in subList.items) {
            await item.delete();
          }
        }
      } catch (_) {
        // Prefix may not exist — that's fine
      }
    }
  }

  /// Re-authenticate user before deletion (required by Firebase for recent login)
  Future<bool> reauthenticate(String email, String password) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      debugPrint('Reauthentication failed: $e');
      return false;
    }
  }
}
