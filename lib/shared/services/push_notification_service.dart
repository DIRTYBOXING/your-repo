import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PUSH NOTIFICATION SERVICE — FCM Integration for Re-engagement & Alerts
/// ═══════════════════════════════════════════════════════════════════════════

final _firestore = FirebaseFirestore.instance;
final _functions = FirebaseFunctions.instanceFor(
  region: 'australia-southeast1',
);
final _messaging = FirebaseMessaging.instance;

enum NotificationType {
  fightStart,
  fightEnd,
  roundUpdate,
  knockoutAlert,
  ppvReminder,
  eventStart,
  newContent,
  socialMention,
  predictionResult,
  achievement,
  systemAlert,
}

enum NotificationPriority { low, normal, high, urgent }

class PushNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final NotificationPriority priority;
  final DateTime sentAt;
  final bool isRead;
  final String? imageUrl;
  final String? actionUrl;

  const PushNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    this.priority = NotificationPriority.normal,
    required this.sentAt,
    this.isRead = false,
    this.imageUrl,
    this.actionUrl,
  });

  factory PushNotification.fromMap(Map<String, dynamic> map) =>
      PushNotification(
        id: map['id'] ?? '',
        type: NotificationType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => NotificationType.systemAlert,
        ),
        title: map['title'] ?? '',
        body: map['body'] ?? '',
        data: Map<String, dynamic>.from(map['data'] ?? {}),
        priority: NotificationPriority.values.firstWhere(
          (p) => p.name == map['priority'],
          orElse: () => NotificationPriority.normal,
        ),
        sentAt: (map['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isRead: map['isRead'] ?? false,
        imageUrl: map['imageUrl'],
        actionUrl: map['actionUrl'],
      );

  factory PushNotification.fromRemoteMessage(
    RemoteMessage message,
  ) => PushNotification(
    id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    type: NotificationType.values.firstWhere(
      (t) => t.name == message.data['type'],
      orElse: () => NotificationType.systemAlert,
    ),
    title: message.notification?.title ?? message.data['title'] ?? '',
    body: message.notification?.body ?? message.data['body'] ?? '',
    data: message.data,
    priority: NotificationPriority.values.firstWhere(
      (p) => p.name == message.data['priority'],
      orElse: () => NotificationPriority.normal,
    ),
    sentAt: message.sentTime ?? DateTime.now(),
    imageUrl:
        message.notification?.android?.imageUrl ??
        message.notification?.apple?.imageUrl,
    actionUrl: message.data['actionUrl'],
  );
}

class NotificationPreferences {
  bool fightAlerts;
  bool eventReminders;
  bool socialMentions;
  bool predictionResults;
  bool marketplaceUpdates;
  bool systemAlerts;
  bool quietHoursEnabled;
  int quietHoursStart; // 0-23
  int quietHoursEnd;

  NotificationPreferences({
    this.fightAlerts = true,
    this.eventReminders = true,
    this.socialMentions = true,
    this.predictionResults = true,
    this.marketplaceUpdates = false,
    this.systemAlerts = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 7,
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) =>
      NotificationPreferences(
        fightAlerts: map['fightAlerts'] ?? true,
        eventReminders: map['eventReminders'] ?? true,
        socialMentions: map['socialMentions'] ?? true,
        predictionResults: map['predictionResults'] ?? true,
        marketplaceUpdates: map['marketplaceUpdates'] ?? false,
        systemAlerts: map['systemAlerts'] ?? true,
        quietHoursEnabled: map['quietHoursEnabled'] ?? false,
        quietHoursStart: map['quietHoursStart'] ?? 22,
        quietHoursEnd: map['quietHoursEnd'] ?? 7,
      );

  Map<String, dynamic> toMap() => {
    'fightAlerts': fightAlerts,
    'eventReminders': eventReminders,
    'socialMentions': socialMentions,
    'predictionResults': predictionResults,
    'marketplaceUpdates': marketplaceUpdates,
    'systemAlerts': systemAlerts,
    'quietHoursEnabled': quietHoursEnabled,
    'quietHoursStart': quietHoursStart,
    'quietHoursEnd': quietHoursEnd,
  };
}

class PushNotificationService with ChangeNotifier {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  String? _fcmToken;
  String? _userId;
  NotificationPreferences _preferences = NotificationPreferences();
  final List<PushNotification> _recentNotifications = [];
  int _unreadCount = 0;
  StreamSubscription<RemoteMessage>? _foregroundSub;

  String? get fcmToken => _fcmToken;
  NotificationPreferences get preferences => _preferences;
  List<PushNotification> get recentNotifications =>
      List.unmodifiable(_recentNotifications);
  int get unreadCount => _unreadCount;

  Future<void> initialize(String userId) async {
    _userId = userId;
    debugPrint('🔔 PushNotificationService: Initializing...');

    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        
      );
      debugPrint(
        'PushNotificationService: Permission status: ${settings.authorizationStatus}',
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        _fcmToken = await _messaging.getToken();
        debugPrint(
          'PushNotificationService: FCM Token: ${_fcmToken?.substring(0, 20)}...',
        );

        // Save token to Firestore
        if (_fcmToken != null) {
          await _saveTokenToFirestore();
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          _saveTokenToFirestore();
        });

        // Listen for foreground messages
        _foregroundSub = FirebaseMessaging.onMessage.listen(
          _handleForegroundMessage,
        );

        // Load preferences
        await _loadPreferences();

        // Load recent notifications
        await _loadRecentNotifications();
      }
    } catch (e) {
      debugPrint('PushNotificationService: Init failed: $e');
    }

    notifyListeners();
  }

  Future<void> _saveTokenToFirestore() async {
    if (_userId == null || _fcmToken == null) return;
    await _firestore.collection('fcm_tokens').doc(_userId).set({
      'token': _fcmToken,
      'platform': defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _loadPreferences() async {
    if (_userId == null) return;
    final doc = await _firestore
        .collection('notification_preferences')
        .doc(_userId)
        .get();
    if (doc.exists) {
      _preferences = NotificationPreferences.fromMap(doc.data()!);
    }
  }

  Future<void> _loadRecentNotifications() async {
    if (_userId == null) return;
    final snap = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('notifications')
        .orderBy('sentAt', descending: true)
        .limit(50)
        .get();
    _recentNotifications.clear();
    for (final doc in snap.docs) {
      _recentNotifications.add(
        PushNotification.fromMap({...doc.data(), 'id': doc.id}),
      );
    }
    _unreadCount = _recentNotifications.where((n) => !n.isRead).length;
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
      'PushNotificationService: Foreground message: ${message.notification?.title}',
    );
    final notification = PushNotification.fromRemoteMessage(message);
    _recentNotifications.insert(0, notification);
    if (_recentNotifications.length > 100) _recentNotifications.removeLast();
    _unreadCount++;
    notifyListeners();

    // Store in Firestore
    if (_userId != null) {
      _firestore
          .collection('users')
          .doc(_userId)
          .collection('notifications')
          .add({
            'type': notification.type.name,
            'title': notification.title,
            'body': notification.body,
            'data': notification.data,
            'priority': notification.priority.name,
            'sentAt': FieldValue.serverTimestamp(),
            'isRead': false,
            'imageUrl': notification.imageUrl,
            'actionUrl': notification.actionUrl,
          });
    }
  }

  Future<void> updatePreferences(NotificationPreferences newPrefs) async {
    _preferences = newPrefs;
    if (_userId != null) {
      await _firestore
          .collection('notification_preferences')
          .doc(_userId)
          .set(newPrefs.toMap());
    }
    notifyListeners();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  Future<void> markAsRead(String notificationId) async {
    final idx = _recentNotifications.indexWhere((n) => n.id == notificationId);
    if (idx >= 0 && !_recentNotifications[idx].isRead) {
      _unreadCount = (_unreadCount - 1).clamp(0, 999);
      if (_userId != null) {
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('notifications')
            .doc(notificationId)
            .update({'isRead': true});
      }
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    if (_userId != null) {
      final batch = _firestore.batch();
      for (final n in _recentNotifications.where((n) => !n.isRead)) {
        batch.update(
          _firestore
              .collection('users')
              .doc(_userId)
              .collection('notifications')
              .doc(n.id),
          {'isRead': true},
        );
      }
      await batch.commit();
    }
    _unreadCount = 0;
    notifyListeners();
  }

  Future<bool> sendTestNotification() async {
    try {
      final callable = _functions.httpsCallable('sendTestPushNotification');
      final result = await callable.call<Map<String, dynamic>>({
        'userId': _userId,
      });
      return result.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _foregroundSub?.cancel();
    super.dispose();
  }
}
