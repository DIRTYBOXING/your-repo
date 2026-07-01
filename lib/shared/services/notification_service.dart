import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

/// Service for managing in-app notifications in Firestore.
///
/// Collection: `notifications/{userId}/items/{notificationId}`
class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // COLLECTION REFERENCES
  // ═══════════════════════════════════════════════════════════════════════════

  CollectionReference _itemsRef(String userId) =>
      _db.collection('notifications').doc(userId).collection('items');

  // ═══════════════════════════════════════════════════════════════════════════
  // READ
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream all notifications for a user, ordered by newest first
  Stream<List<NotificationModel>> streamNotifications(
    String userId, {
    int limit = 50,
  }) {
    return _itemsRef(userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map(NotificationModel.fromFirestore).toList(),
        );
  }

  /// One-shot fetch of all notifications
  Future<List<NotificationModel>> getNotifications(
    String userId, {
    int limit = 50,
  }) async {
    final snap = await _itemsRef(
      userId,
    ).orderBy('createdAt', descending: true).limit(limit).get();
    return snap.docs.map(NotificationModel.fromFirestore).toList();
  }

  /// Count of unread notifications (stream)
  Stream<int> streamUnreadCount(String userId) {
    return _itemsRef(
      userId,
    ).where('isRead', isEqualTo: false).snapshots().map((snap) => snap.size);
  }

  /// Count of unread notifications (one-shot)
  Future<int> getUnreadCount(String userId) async {
    final snap = await _itemsRef(
      userId,
    ).where('isRead', isEqualTo: false).get();
    return snap.size;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WRITE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create a new notification for a user
  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? actionRoute,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    Map<String, dynamic>? metadata,
  }) async {
    final ref = _itemsRef(userId).doc();
    final notification = NotificationModel(
      id: ref.id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      actionRoute: actionRoute,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      metadata: metadata,
      createdAt: DateTime.now(),
    );
    await ref.set(notification.toFirestore());
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    await _itemsRef(userId).doc(notificationId).update({'isRead': true});
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    final snap = await _itemsRef(
      userId,
    ).where('isRead', isEqualTo: false).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Delete a single notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    await _itemsRef(userId).doc(notificationId).delete();
  }

  /// Delete all notifications for a user
  Future<void> clearAll(String userId) async {
    final snap = await _itemsRef(userId).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEED — Welcome notifications for new users
  // ═══════════════════════════════════════════════════════════════════════════

  /// Seed initial welcome notifications for a new user
  Future<void> seedWelcome(String userId, {String? role}) async {
    await createNotification(
      userId: userId,
      type: NotificationType.general,
      title: 'Welcome to DataFight Central! 🥊',
      body:
          'Your combat sports journey starts here. Explore the dashboard, connect with fighters, and build your profile.',
      actionRoute: '/dashboard',
    );

    await createNotification(
      userId: userId,
      type: NotificationType.databankUpdate,
      title: 'Complete Your Profile',
      body:
          'Add your fight stats, weight class, and training info to get matched with opponents.',
      actionRoute: '/profile/edit',
    );

    if (role == 'fighter' || role == null) {
      await createNotification(
        userId: userId,
        type: NotificationType.fightOffer,
        title: 'Register in the DataBank',
        body:
            'List yourself in the DFC Fighter DataBank so promoters and matchmakers can find you.',
        actionRoute: '/databank',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FCM — Push Notification Token Registration
  // ═══════════════════════════════════════════════════════════════════════════

  /// Register FCM token for the current device. Call after login.
  Future<void> registerFcmToken(String userId) async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission (no-op on web if already granted)
      final settings = await messaging.requestPermission(
        
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCM: User denied push notification permission');
        return;
      }

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('FCM: No token available');
        return;
      }

      // Store token under user's device tokens
      await _db
          .collection('users')
          .doc(userId)
          .collection('fcm_tokens')
          .doc(token)
          .set({
            'token': token,
            'platform': defaultTargetPlatform.name,
            'createdAt': FieldValue.serverTimestamp(),
            'isWeb': kIsWeb,
          });

      debugPrint('FCM: Token registered for user $userId');

      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) {
        _db
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .doc(newToken)
            .set({
              'token': newToken,
              'platform': defaultTargetPlatform.name,
              'createdAt': FieldValue.serverTimestamp(),
              'isWeb': kIsWeb,
            });
      });
    } catch (e) {
      debugPrint('FCM registration failed: $e');
    }
  }

  /// Remove the current device's FCM token on logout.
  Future<void> unregisterFcmToken(String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _db
            .collection('users')
            .doc(userId)
            .collection('fcm_tokens')
            .doc(token)
            .delete();
      }
    } catch (e) {
      debugPrint('FCM unregister failed: $e');
    }
  }
}
