import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

enum FightModeSignalType { walkout, mainEvent, knockout }

class FightModeSignal {
  final FightModeSignalType type;
  final String eventId;
  final String source;

  const FightModeSignal({
    required this.type,
    required this.eventId,
    required this.source,
  });
}

/// PPV Notification Service
/// Sends vibration + flashing alerts for walkouts and main events
class PPVNotificationService {
  static final PPVNotificationService _instance =
      PPVNotificationService._internal();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<FightModeSignal> _fightModeSignalController =
      StreamController<FightModeSignal>.broadcast();
  bool _isInitialized = false;

  PPVNotificationService._internal();

  factory PPVNotificationService() {
    return _instance;
  }

  Stream<FightModeSignal> get fightModeSignals =>
      _fightModeSignalController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Firebase Cloud Messaging
    await _firebaseMessaging.requestPermission(
      announcement: true,
      criticalAlert: true,
    );

    // Local Notifications
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings(
          
        );

    final initSettings = const InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        if (response.payload != null) {
          _handleLocalNotificationTap(response.payload!);
        }
      },
    );

    // Handle notification taps and foreground notifications.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Send walkout alert with vibration
  Future<void> sendWalkoutAlert({
    required String eventId,
    required String fighterName,
    required String opponent,
    required Duration hapticDuration,
  }) async {
    final burstMs = hapticDuration.inMilliseconds.clamp(80, 400);

    // Vibration pattern: short bursts for excitement
    await Vibration.vibrate(duration: burstMs, amplitude: 255);
    await Future.delayed(const Duration(milliseconds: 100));
    await Vibration.vibrate(duration: burstMs, amplitude: 255);
    await Future.delayed(const Duration(milliseconds: 100));
    await Vibration.vibrate(duration: burstMs, amplitude: 255);

    // Local notification with sound
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'ppv_walkout',
          'PPV Walkouts',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          sound: RawResourceAndroidNotificationSound('notification_alert'),
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_alert.wav',
      interruptionLevel: InterruptionLevel.critical,
    );

    await _localNotifications.show(
      id: eventId.hashCode,
      title: '🥊 WALKOUT!',
      body: '$fighterName vs $opponent - GET TO THE SCREEN NOW!',
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: 'ppv_event:$eventId',
    );

    _emitFightModeSignal(
      FightModeSignal(
        type: FightModeSignalType.walkout,
        eventId: eventId,
        source: 'local_walkout',
      ),
    );
  }

  /// Send main event alert with heavy vibration
  Future<void> sendMainEventAlert({
    required String eventId,
    required String mainFighter,
    required String mainOpponent,
  }) async {
    // HEAVY vibration for main event (adrenaline mode)
    await Vibration.vibrate(amplitude: 255);
    await Future.delayed(const Duration(milliseconds: 200));
    await Vibration.vibrate(duration: 300, amplitude: 255);
    await Future.delayed(const Duration(milliseconds: 200));
    await Vibration.vibrate(duration: 200, amplitude: 255);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'ppv_main_event',
          'Main Event Alerts',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          sound: RawResourceAndroidNotificationSound('main_event_alert'),
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'main_event_alert.wav',
      interruptionLevel: InterruptionLevel.critical,
    );

    await _localNotifications.show(
      id: '${eventId}_main'.hashCode,
      title: '🔥 MAIN EVENT!',
      body: '$mainFighter vs $mainOpponent - MAIN EVENT STARTING NOW!',
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: 'ppv_main:$eventId',
    );

    _emitFightModeSignal(
      FightModeSignal(
        type: FightModeSignalType.mainEvent,
        eventId: eventId,
        source: 'local_main_event',
      ),
    );
  }

  /// Send round start alert
  Future<void> sendRoundAlert({
    required String eventId,
    required String fighterName,
    required int roundNumber,
  }) async {
    // Quick triple vibration for each round
    for (int i = 0; i < roundNumber; i++) {
      await Vibration.vibrate(duration: 50, amplitude: 200);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'ppv_round',
          'Round Alerts',
          importance: Importance.high,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('round_alert'),
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'round_alert.wav',
    );

    await _localNotifications.show(
      id: '${eventId}_round_$roundNumber'.hashCode,
      title: 'Round $roundNumber',
      body: '$fighterName - Match is on!',
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: 'ppv_round:$eventId:$roundNumber',
    );
  }

  /// KO/TKO Alert - Maximum vibration intensity
  Future<void> sendKOAlert({
    required String eventId,
    required String winner,
    required String method,
    required String time,
  }) async {
    // INTENSE knockout vibration
    await Vibration.vibrate(duration: 300, amplitude: 255);
    await Future.delayed(const Duration(milliseconds: 100));
    await Vibration.vibrate(duration: 200, amplitude: 255);
    await Future.delayed(const Duration(milliseconds: 100));
    await Vibration.vibrate(amplitude: 255);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'ppv_ko',
          'KO Alerts',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          sound: RawResourceAndroidNotificationSound('ko_alert'),
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'ko_alert.wav',
      interruptionLevel: InterruptionLevel.critical,
    );

    await _localNotifications.show(
      id: '${eventId}_ko'.hashCode,
      title: '💥 KNOCKOUT!',
      body: '$winner wins by $method at $time',
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: 'ppv_ko:$eventId',
    );

    _emitFightModeSignal(
      FightModeSignal(
        type: FightModeSignalType.knockout,
        eventId: eventId,
        source: 'local_knockout',
      ),
    );
  }

  Future<void> triggerFightModeHypePulse() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;

    await Vibration.vibrate(duration: 110, amplitude: 255);
    await Future.delayed(const Duration(milliseconds: 60));
    await Vibration.vibrate(duration: 110, amplitude: 255);
    await Future.delayed(const Duration(milliseconds: 80));
    await Vibration.vibrate(duration: 170, amplitude: 255);
  }

  /// Fight Mode KO pulse: reusable high-intensity vibration pattern for live UI.
  Future<void> triggerFightModeKnockoutPulse() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;

    await Vibration.vibrate(duration: 160, amplitude: 255);
    await Future.delayed(const Duration(milliseconds: 70));
    await Vibration.vibrate(duration: 120, amplitude: 255);
    await Future.delayed(const Duration(milliseconds: 70));
    await Vibration.vibrate(duration: 220, amplitude: 255);
    await Future.delayed(const Duration(milliseconds: 90));
    await Vibration.vibrate(duration: 320, amplitude: 255);
  }

  /// Preview/test a full walkout alert from Fight Mode settings.
  Future<void> triggerFightModeWalkoutPreview(String eventId) async {
    await sendWalkoutAlert(
      eventId: eventId,
      fighterName: 'Walkout Alert',
      opponent: 'Open the stream now',
      hapticDuration: const Duration(milliseconds: 140),
    );
  }

  /// Preview/test a main-event alert from Fight Mode settings.
  Future<void> triggerFightModeMainEventPreview(String eventId) async {
    await sendMainEventAlert(
      eventId: eventId,
      mainFighter: 'Main Event',
      mainOpponent: 'Starting now',
    );
  }

  /// Submission Alert
  Future<void> sendSubmissionAlert({
    required String eventId,
    required String winner,
    required String submission,
    required String time,
  }) async {
    // Rapid submission vibration pattern
    await Vibration.vibrate(duration: 150, amplitude: 255);
    await Future.delayed(const Duration(milliseconds: 50));
    await Vibration.vibrate(duration: 150, amplitude: 255);
    await Future.delayed(const Duration(milliseconds: 50));
    await Vibration.vibrate(duration: 300, amplitude: 255);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'ppv_submission',
          'Submission Alerts',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('submission_alert'),
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'submission_alert.wav',
      interruptionLevel: InterruptionLevel.critical,
    );

    await _localNotifications.show(
      id: '${eventId}_sub'.hashCode,
      title: '🔒 SUBMISSION!',
      body: '$winner - $submission at $time',
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: 'ppv_sub:$eventId',
    );
  }

  /// Decision Alert
  Future<void> sendDecisionAlert({
    required String eventId,
    required String winner,
    required String decision,
  }) async {
    // Celebratory vibration pattern
    await Vibration.vibrate(duration: 100, amplitude: 200);
    await Future.delayed(const Duration(milliseconds: 150));
    await Vibration.vibrate(duration: 100, amplitude: 200);
    await Future.delayed(const Duration(milliseconds: 150));
    await Vibration.vibrate(duration: 200, amplitude: 255);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'ppv_decision',
          'Decision Alerts',
          importance: Importance.high,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('decision_alert'),
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'decision_alert.wav',
    );

    await _localNotifications.show(
      id: '${eventId}_decision'.hashCode,
      title: '🏆 DECISION!',
      body: '$winner - $decision',
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: 'ppv_decision:$eventId',
    );
  }

  /// Enable/Disable notifications for specific event
  Future<void> subscribeToEventAlerts(String eventId) async {
    await _firebaseMessaging.subscribeToTopic('ppv_event_$eventId');
    await _firebaseMessaging.subscribeToTopic('ppv_walkouts');
    await _firebaseMessaging.subscribeToTopic('ppv_main_events');
  }

  Future<void> unsubscribeFromEventAlerts(String eventId) async {
    await _firebaseMessaging.unsubscribeFromTopic('ppv_event_$eventId');
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    final signal = _extractSignalFromRemoteMessage(message);
    if (signal != null) {
      _emitFightModeSignal(signal);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final signal = _extractSignalFromRemoteMessage(message);
    if (signal != null) {
      _emitFightModeSignal(signal);
    }
  }

  /// Handle local notification tap
  void _handleLocalNotificationTap(String payload) {
    final parts = payload.split(':');
    if (parts.length < 2) return;

    if (parts.first == 'ppv_event') {
      _emitFightModeSignal(
        FightModeSignal(
          type: FightModeSignalType.walkout,
          eventId: parts[1],
          source: 'local_tap',
        ),
      );
    } else if (parts.first == 'ppv_main') {
      _emitFightModeSignal(
        FightModeSignal(
          type: FightModeSignalType.mainEvent,
          eventId: parts[1],
          source: 'local_tap',
        ),
      );
    } else if (parts.first == 'ppv_ko') {
      _emitFightModeSignal(
        FightModeSignal(
          type: FightModeSignalType.knockout,
          eventId: parts[1],
          source: 'local_tap',
        ),
      );
    }
  }

  FightModeSignal? _extractSignalFromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final payload = (data['payload'] ?? data['type'] ?? data['alertType'] ?? '')
        .toString()
        .toLowerCase();
    final eventId =
        (data['eventId'] ?? data['ppvEventId'] ?? data['event_id'] ?? '')
            .toString();

    if (payload.contains('walkout') || payload.contains('ppv_event')) {
      return FightModeSignal(
        type: FightModeSignalType.walkout,
        eventId: eventId,
        source: 'remote',
      );
    }

    if (payload.contains('main') ||
        payload.contains('main_event') ||
        payload.contains('ppv_main')) {
      return FightModeSignal(
        type: FightModeSignalType.mainEvent,
        eventId: eventId,
        source: 'remote',
      );
    }

    if (payload.contains('ko') ||
        payload.contains('knockout') ||
        payload.contains('ppv_ko')) {
      return FightModeSignal(
        type: FightModeSignalType.knockout,
        eventId: eventId,
        source: 'remote',
      );
    }

    final title = (message.notification?.title ?? '').toLowerCase();
    if (title.contains('walkout')) {
      return FightModeSignal(
        type: FightModeSignalType.walkout,
        eventId: eventId,
        source: 'remote_title',
      );
    }
    if (title.contains('main event')) {
      return FightModeSignal(
        type: FightModeSignalType.mainEvent,
        eventId: eventId,
        source: 'remote_title',
      );
    }
    if (title.contains('ko') || title.contains('knockout')) {
      return FightModeSignal(
        type: FightModeSignalType.knockout,
        eventId: eventId,
        source: 'remote_title',
      );
    }

    return null;
  }

  void _emitFightModeSignal(FightModeSignal signal) {
    if (!_fightModeSignalController.isClosed) {
      _fightModeSignalController.add(signal);
    }
  }

  /// Request permission to send notifications
  Future<bool> requestNotificationPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      announcement: true,
      criticalAlert: true,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Get FCM token for backend targeting
  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }
}
