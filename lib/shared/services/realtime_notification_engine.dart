import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// 📬 REALTIME NOTIFICATION ENGINE — Push + In-App Notifications
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Handles all notification types for DFC Super Feed:
/// • New friend request
/// • Post liked/commented
/// • Fight announced
/// • Event invite
/// • Campaign update
/// • Message received
/// • Training partner request
/// • Gym update
///
/// Supports:
/// • Push notifications (Firebase Cloud Messaging)
/// • In-app notifications
/// • Local notifications
/// • Notification badges
/// • Deep linking to content
///
/// ═══════════════════════════════════════════════════════════════════════════
class RealtimeNotificationEngine {
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications;

  static const String _fcmTopic = 'all_users';

  RealtimeNotificationEngine({
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _fcm = messaging ?? FirebaseMessaging.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Initialize push notifications
  Future<void> initialize({
    required String userId,
    required Function(String route, Map<String, dynamic>? data)
    onNotificationTap,
  }) async {
    // Request permission
    final settings = await _fcm.requestPermission(
      
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      if (kDebugMode) {
        debugPrint('📬 Notification permission denied');
      }
      return;
    }

    // Get FCM token
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveFCMToken(userId, token);
    }

    // Subscribe to all users topic
    await _fcm.subscribeToTopic(_fcmTopic);

    // Initialize local notifications
    await _initializeLocalNotifications(onNotificationTap);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message, onNotificationTap);
    });

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message, onNotificationTap);
    });

    // Handle notification opened from terminated state
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage, onNotificationTap);
    }

    if (kDebugMode) {
      debugPrint('📬 Notification Engine initialized for user $userId');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications(
    Function(String route, Map<String, dynamic>? data) onNotificationTap,
  ) async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) {
          // Parse payload and navigate
          final parts = payload.split('|');
          final route = parts.first;
          final data = parts.length > 1 ? {'id': parts[1]} : null;
          onNotificationTap(route, data);
        }
      },
    );
  }

  /// Save FCM token to Firestore
  Future<void> _saveFCMToken(String userId, String token) async {
    await _firestore.collection('user_tokens').doc(userId).set({
      'token': token,
      'platform': defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEND NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Send notification when someone likes your post
  Future<void> notifyPostLiked({
    required String postAuthorId,
    required String likerId,
    required String likerName,
    required String postId,
    String? likerAvatar,
  }) async {
    await _createNotification(
      userId: postAuthorId,
      type: DFCNotificationType.postLiked,
      title: 'New Reaction',
      body: '$likerName reacted to your post',
      actionRoute: '/post/$postId',
      senderId: likerId,
      senderName: likerName,
      senderAvatar: likerAvatar,
      metadata: {'postId': postId},
    );
  }

  /// Send notification when someone comments on your post
  Future<void> notifyPostCommented({
    required String postAuthorId,
    required String commenterId,
    required String commenterName,
    required String postId,
    required String commentPreview,
    String? commenterAvatar,
  }) async {
    await _createNotification(
      userId: postAuthorId,
      type: DFCNotificationType.postCommented,
      title: 'New Comment',
      body: '$commenterName: $commentPreview',
      actionRoute: '/post/$postId',
      senderId: commenterId,
      senderName: commenterName,
      senderAvatar: commenterAvatar,
      metadata: {'postId': postId},
    );
  }

  /// Send notification for new friend request
  Future<void> notifyFriendRequest({
    required String recipientId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
  }) async {
    await _createNotification(
      userId: recipientId,
      type: DFCNotificationType.friendRequest,
      title: 'New Friend Request',
      body: '$senderName wants to connect',
      actionRoute: '/friend-requests',
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
    );
  }

  /// Send notification when friend request is accepted
  Future<void> notifyFriendRequestAccepted({
    required String recipientId,
    required String accepterId,
    required String accepterName,
    String? accepterAvatar,
  }) async {
    await _createNotification(
      userId: recipientId,
      type: DFCNotificationType.friendAccepted,
      title: 'Friend Request Accepted',
      body: '$accepterName accepted your friend request',
      actionRoute: '/friends',
      senderId: accepterId,
      senderName: accepterName,
      senderAvatar: accepterAvatar,
    );
  }

  /// Send notification for new message
  Future<void> notifyNewMessage({
    required String recipientId,
    required String senderId,
    required String senderName,
    required String messagePreview,
    required String conversationId,
    String? senderAvatar,
  }) async {
    await _createNotification(
      userId: recipientId,
      type: DFCNotificationType.messageReceived,
      title: senderName,
      body: messagePreview,
      actionRoute: '/messages/$conversationId',
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      metadata: {'conversationId': conversationId},
    );
  }

  /// Send notification for fight announced
  Future<void> notifyFightAnnounced({
    required String fighterId,
    required String promoterName,
    required String opponentName,
    required String eventName,
    required String eventId,
    required DateTime eventDate,
  }) async {
    await _createNotification(
      userId: fighterId,
      type: DFCNotificationType.fightAnnounced,
      title: 'Fight Announced! 🥊',
      body: 'You vs $opponentName at $eventName on ${_formatDate(eventDate)}',
      actionRoute: '/events/$eventId',
      metadata: {'eventId': eventId, 'eventDate': eventDate.toIso8601String()},
    );
  }

  /// Send notification for event invite
  Future<void> notifyEventInvite({
    required String recipientId,
    required String senderId,
    required String senderName,
    required String eventName,
    required String eventId,
    String? senderAvatar,
  }) async {
    await _createNotification(
      userId: recipientId,
      type: DFCNotificationType.eventInvite,
      title: 'Event Invitation',
      body: '$senderName invited you to $eventName',
      actionRoute: '/events/$eventId',
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      metadata: {'eventId': eventId},
    );
  }

  /// Send notification for training invite
  Future<void> notifyTrainingInvite({
    required String recipientId,
    required String senderId,
    required String senderName,
    required String gymName,
    required DateTime trainingDate,
    String? senderAvatar,
  }) async {
    await _createNotification(
      userId: recipientId,
      type: DFCNotificationType.trainingInvite,
      title: 'Training Invitation',
      body:
          '$senderName invited you to train at $gymName on ${_formatDate(trainingDate)}',
      actionRoute: '/friends',
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      metadata: {
        'gymName': gymName,
        'trainingDate': trainingDate.toIso8601String(),
      },
    );
  }

  /// Send notification for campaign update
  Future<void> notifyCampaignUpdate({
    required List<String> recipientIds,
    required String campaignName,
    required String update,
    required String campaignId,
  }) async {
    for (final recipientId in recipientIds) {
      await _createNotification(
        userId: recipientId,
        type: DFCNotificationType.campaignUpdate,
        title: '$campaignName Update',
        body: update,
        actionRoute: '/campaigns/$campaignId',
        metadata: {'campaignId': campaignId},
      );
    }
  }

  /// Send notification for post shared
  Future<void> notifyPostShared({
    required String postAuthorId,
    required String sharerId,
    required String sharerName,
    required String postId,
    String? sharerAvatar,
  }) async {
    await _createNotification(
      userId: postAuthorId,
      type: DFCNotificationType.postShared,
      title: 'Post Shared',
      body: '$sharerName shared your post',
      actionRoute: '/post/$postId',
      senderId: sharerId,
      senderName: sharerName,
      senderAvatar: sharerAvatar,
      metadata: {'postId': postId},
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create notification in Firestore and send push
  Future<void> _createNotification({
    required String userId,
    required DFCNotificationType type,
    required String title,
    required String body,
    String? actionRoute,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    Map<String, dynamic>? metadata,
  }) async {
    // Save to Firestore
    final notificationRef = _firestore
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .doc();

    await notificationRef.set({
      'type': type.name,
      'title': title,
      'body': body,
      'actionRoute': actionRoute,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'metadata': metadata,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Send push notification
    await _sendPushNotification(
      userId: userId,
      title: title,
      body: body,
      actionRoute: actionRoute,
      metadata: metadata,
    );
  }

  /// Send push notification via FCM
  Future<void> _sendPushNotification({
    required String userId,
    required String title,
    required String body,
    String? actionRoute,
    Map<String, dynamic>? metadata,
  }) async {
    // Get user's FCM token
    final tokenDoc = await _firestore
        .collection('user_tokens')
        .doc(userId)
        .get();
    if (!tokenDoc.exists) return;

    final token = tokenDoc.data()?['token'] as String?;
    if (token == null) return;

    // In production, call Firebase Cloud Functions to send push
    // For now, just log
    if (kDebugMode) {
      debugPrint('📬 Sending push to $userId: $title - $body');
    }

    // Note: Actual FCM sending requires backend Cloud Function
    // This is handled server-side to keep API keys secure
  }

  /// Handle foreground message (show local notification)
  Future<void> _handleForegroundMessage(
    RemoteMessage message,
    Function(String route, Map<String, dynamic>? data) onNotificationTap,
  ) async {
    final notification = message.notification;
    if (notification == null) return;

    // Show local notification
    const androidDetails = AndroidNotificationDetails(
      'dfc_channel',
      'DFC Notifications',
      channelDescription: 'DataFight Central notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final route = message.data['route'] as String?;
    final payload = route != null ? '$route|${message.data['id'] ?? ''}' : null;

    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  /// Handle notification tap
  void _handleNotificationTap(
    RemoteMessage message,
    Function(String route, Map<String, dynamic>? data) onNotificationTap,
  ) {
    final route = message.data['route'] as String?;
    if (route != null) {
      final metadata = Map<String, dynamic>.from(message.data);
      metadata.remove('route');
      onNotificationTap(route, metadata.isNotEmpty ? metadata : null);
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // READ NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream user's notifications
  Stream<List<Map<String, dynamic>>> streamNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  /// Get unread count
  Stream<int> streamUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  /// Mark notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Mark all as read
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Delete notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .doc(notificationId)
        .delete();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════

  /// Unsubscribe from topics
  Future<void> dispose() async {
    await _fcm.unsubscribeFromTopic(_fcmTopic);
  }
}

/// DFC-specific notification types
enum DFCNotificationType {
  postLiked,
  postCommented,
  postShared,
  friendRequest,
  friendAccepted,
  messageReceived,
  fightAnnounced,
  eventInvite,
  trainingInvite,
  campaignUpdate,
  gymUpdate,
  sparringRequest,
  moderationWarning,
}
