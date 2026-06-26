import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HydrationService {
  DateTime? _lastReminderTime;
  int _waterIntakeMl = 0;

  DateTime? get lastReminderTime => _lastReminderTime;
  int get waterIntakeMl => _waterIntakeMl;
  void logWaterIntake(int ml) {
    _waterIntakeMl += ml;
  }

  void resetWaterIntake() {
    _waterIntakeMl = 0;
  }

  static final HydrationService _instance = HydrationService._internal();
  factory HydrationService() => _instance;
  HydrationService._internal();

  Timer? _reminderTimer;
  Duration _interval = const Duration(hours: 1);

  bool _enabled = false;
  bool get remindersEnabled => _enabled;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        const InitializationSettings(
          android: initializationSettingsAndroid,
          // Windows notifications not required for initial release
        );
    try {
      await _notifications.initialize(settings: initializationSettings);
    } catch (e) {
      debugPrint('HydrationService init warning: $e');
      // Non-critical; reminders can still function without system notifications
    }
  }

  void setReminderEnabled(bool enabled) {
    _enabled = enabled;
    if (enabled) {
      _startReminder();
    } else {
      _reminderTimer?.cancel();
    }
  }

  void setInterval(Duration interval) {
    _interval = interval;
    if (_enabled) {
      _startReminder();
    }
  }

  void _startReminder() {
    _reminderTimer?.cancel();
    _reminderTimer = Timer.periodic(_interval, (_) => _showReminder());
  }

  Future<void> _showReminder() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'hydration_channel',
          'Hydration Reminders',
          channelDescription: 'Reminds users to drink water',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('water_reminder'),
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _notifications.show(
      id: 0,
      title: 'Hydration Reminder',
      body: 'Time to drink water!',
      notificationDetails: platformChannelSpecifics,
    );
    _lastReminderTime = DateTime.now();
  }
}
