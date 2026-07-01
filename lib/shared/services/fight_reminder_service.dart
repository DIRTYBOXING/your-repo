import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reminder timing options — how far before the event to alert.
enum ReminderOffset { atStart, min15, min30, hour1, hour3, day1, week1 }

extension ReminderOffsetX on ReminderOffset {
  Duration get duration {
    switch (this) {
      case ReminderOffset.atStart:
        return Duration.zero;
      case ReminderOffset.min15:
        return const Duration(minutes: 15);
      case ReminderOffset.min30:
        return const Duration(minutes: 30);
      case ReminderOffset.hour1:
        return const Duration(hours: 1);
      case ReminderOffset.hour3:
        return const Duration(hours: 3);
      case ReminderOffset.day1:
        return const Duration(days: 1);
      case ReminderOffset.week1:
        return const Duration(days: 7);
    }
  }

  String get label {
    switch (this) {
      case ReminderOffset.atStart:
        return 'At start';
      case ReminderOffset.min15:
        return '15 min before';
      case ReminderOffset.min30:
        return '30 min before';
      case ReminderOffset.hour1:
        return '1 hour before';
      case ReminderOffset.hour3:
        return '3 hours before';
      case ReminderOffset.day1:
        return '1 day before';
      case ReminderOffset.week1:
        return '1 week before';
    }
  }
}

/// A scheduled fight reminder.
class FightReminder {
  final String eventId;
  final String eventTitle;
  final DateTime eventTime;
  final ReminderOffset offset;
  final int notificationId;

  const FightReminder({
    required this.eventId,
    required this.eventTitle,
    required this.eventTime,
    required this.offset,
    required this.notificationId,
  });

  DateTime get alertTime => eventTime.subtract(offset.duration);

  Map<String, dynamic> toMap() => {
    'eventId': eventId,
    'eventTitle': eventTitle,
    'eventTime': Timestamp.fromDate(eventTime),
    'offset': offset.name,
    'notificationId': notificationId,
  };

  factory FightReminder.fromMap(Map<String, dynamic> map) => FightReminder(
    eventId: map['eventId'] ?? '',
    eventTitle: map['eventTitle'] ?? '',
    eventTime: map['eventTime'] is Timestamp
        ? (map['eventTime'] as Timestamp).toDate()
        : DateTime.now(),
    offset: ReminderOffset.values.firstWhere(
      (o) => o.name == map['offset'],
      orElse: () => ReminderOffset.hour1,
    ),
    notificationId: map['notificationId'] ?? 0,
  );
}

/// Schedules local push notifications before fight events.
/// Every streaming platform does "Remind Me" — now DFC does too.
class FightReminderService extends ChangeNotifier {
  static final FightReminderService _instance =
      FightReminderService._internal();
  factory FightReminderService() => _instance;
  FightReminderService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<FightReminder> _reminders = [];
  bool _isInitialized = false;
  int _nextNotificationId = 1000;

  // Default reminder offsets when user taps "Remind Me"
  static const List<ReminderOffset> defaultOffsets = [
    ReminderOffset.hour1,
    ReminderOffset.min15,
  ];

  // ── Getters ───────────────────────────────────────────────────────────
  List<FightReminder> get reminders => List.unmodifiable(_reminders);
  bool get isInitialized => _isInitialized;

  /// Check if a reminder is set for a specific event.
  bool hasReminder(String eventId) =>
      _reminders.any((r) => r.eventId == eventId);

  /// Get all reminders for a specific event.
  List<FightReminder> remindersForEvent(String eventId) =>
      _reminders.where((r) => r.eventId == eventId).toList();

  // ── Init ──────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize notification plugin
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Load saved reminders
    await _loadReminders();

    // Clean up past reminders
    _prunePastReminders();

    _isInitialized = true;
    notifyListeners();
  }

  // ── Schedule / Cancel ─────────────────────────────────────────────────

  /// Set a reminder for an event with default offsets (1hr + 15min before).
  Future<void> setReminder({
    required String eventId,
    required String eventTitle,
    required DateTime eventTime,
    List<ReminderOffset>? offsets,
  }) async {
    final reminderOffsets = offsets ?? defaultOffsets;

    for (final offset in reminderOffsets) {
      final alertTime = eventTime.subtract(offset.duration);

      // Don't schedule if alert time is in the past
      if (alertTime.isBefore(DateTime.now())) continue;

      final notifId = _nextNotificationId++;
      final reminder = FightReminder(
        eventId: eventId,
        eventTitle: eventTitle,
        eventTime: eventTime,
        offset: offset,
        notificationId: notifId,
      );

      _reminders.add(reminder);

      // Schedule local notification
      await _scheduleNotification(reminder);
    }

    notifyListeners();
    await _saveReminders();
    _syncToFirestore();
  }

  /// Cancel all reminders for an event.
  Future<void> cancelReminder(String eventId) async {
    final toCancel = _reminders.where((r) => r.eventId == eventId).toList();

    for (final r in toCancel) {
      await _notifications.cancel(id: r.notificationId);
    }

    _reminders.removeWhere((r) => r.eventId == eventId);
    notifyListeners();
    await _saveReminders();
  }

  /// Toggle reminder for an event (set if not set, cancel if set).
  Future<bool> toggleReminder({
    required String eventId,
    required String eventTitle,
    required DateTime eventTime,
  }) async {
    if (hasReminder(eventId)) {
      await cancelReminder(eventId);
      return false;
    } else {
      await setReminder(
        eventId: eventId,
        eventTitle: eventTitle,
        eventTime: eventTime,
      );
      return true;
    }
  }

  // ── Notification Scheduling ───────────────────────────────────────────

  Future<void> _scheduleNotification(FightReminder reminder) async {
    if (kIsWeb) return; // Local notifications not supported on web

    const androidDetails = AndroidNotificationDetails(
      'dfc_fight_reminders',
      'Fight Reminders',
      channelDescription: 'Alerts before fight events start',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final body = reminder.offset == ReminderOffset.atStart
        ? '${reminder.eventTitle} is starting NOW!'
        : '${reminder.eventTitle} starts in ${reminder.offset.label.replaceAll(' before', '')}';

    // Use show() for immediate or schedule via zonedSchedule in production
    // For now, store the alert time and use a timer fallback
    final delay = reminder.alertTime.difference(DateTime.now());
    if (delay.isNegative) return;

    if (delay.inSeconds < 5) {
      await _notifications.show(
        id: reminder.notificationId,
        title: 'Fight Alert',
        body: body,
        notificationDetails: details,
      );
    } else {
      // For longer delays, use a timer (in production, use zonedSchedule)
      Timer(delay, () {
        _notifications.show(
          id: reminder.notificationId,
          title: 'Fight Alert',
          body: body,
          notificationDetails: details,
        );
      });
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Navigate to event detail — handled by notification routing in app
    debugPrint('[FightReminder] Notification tapped: ${response.payload}');
  }

  // ── Persistence ───────────────────────────────────────────────────────

  Future<void> _loadReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('dfc_fight_reminders') ?? [];
      for (final line in raw) {
        final parts = line.split('|');
        if (parts.length < 5) continue;
        _reminders.add(
          FightReminder(
            eventId: parts[0],
            eventTitle: parts[1],
            eventTime: DateTime.fromMillisecondsSinceEpoch(
              int.tryParse(parts[2]) ?? 0,
            ),
            offset: ReminderOffset.values.firstWhere(
              (o) => o.name == parts[3],
              orElse: () => ReminderOffset.hour1,
            ),
            notificationId: int.tryParse(parts[4]) ?? 0,
          ),
        );
        _nextNotificationId = (_reminders.last.notificationId + 1).clamp(
          1000,
          999999,
        );
      }
    } catch (_) {}
  }

  Future<void> _saveReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lines = _reminders
          .map(
            (r) =>
                '${r.eventId}|${r.eventTitle}|${r.eventTime.millisecondsSinceEpoch}|${r.offset.name}|${r.notificationId}',
          )
          .toList();
      await prefs.setStringList('dfc_fight_reminders', lines);
    } catch (_) {}
  }

  void _prunePastReminders() {
    final now = DateTime.now();
    _reminders.removeWhere((r) => r.alertTime.isBefore(now));
  }

  void _syncToFirestore() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    for (final r in _reminders) {
      _firestore
          .collection('users')
          .doc(uid)
          .collection('fight_reminders')
          .doc('${r.eventId}_${r.offset.name}')
          .set(r.toMap(), SetOptions(merge: true))
          .catchError((_) {});
    }
  }
}
