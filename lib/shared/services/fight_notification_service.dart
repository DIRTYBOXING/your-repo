/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT NOTIFICATION SERVICE - Alerts, Alarms & PPV Notifications
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Two modes of operation:
///
/// 🥊 PERSONAL MODE (Training/Fighter)
///   - Morning HR check reminders
///   - Hydration alerts every 2 hours
///   - Weight check reminders (AM/PM)
///   - Sleep window notifications
///   - Training session reminders
///   - Recovery day prompts
///
/// 📺 FAN/PPV MODE
///   - Event day countdown alerts
///   - Main card starting notification
///   - Main event walkout alert (with vibration!)
///   - KO/Submission instant alert
///   - Post-fight press conference reminder
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Notification types
enum FightNotificationType {
  // Personal/Training
  morningHRCheck,
  hydrationReminder,
  weightCheck,
  sleepWindow,
  trainingReminder,
  recoveryDay,
  mealReminder,
  supplementReminder,

  // PPV/Fan Mode
  ppvCountdown,
  mainCardStarting,
  mainEventWalkout,
  fightResult,
  pressConference,

  // Fight Week Specific
  fightWeekStart,
  weighInReminder,
  fightDayMorning,
  fightTimeApproaching,
}

/// Notification priority levels
enum NotificationPriority {
  low,
  normal,
  high,
  critical, // Full-screen alert with vibration
}

/// Fight notification data
class FightNotification {
  final String id;
  final FightNotificationType type;
  final String title;
  final String body;
  final NotificationPriority priority;
  final DateTime? scheduledTime;
  final bool vibrate;
  final bool fullScreen;
  final String? actionRoute; // Navigation route when tapped
  final Map<String, dynamic>? payload;

  FightNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.priority = NotificationPriority.normal,
    this.scheduledTime,
    this.vibrate = true,
    this.fullScreen = false,
    this.actionRoute,
    this.payload,
  });
}

/// Vibration patterns
class VibrationPatterns {
  // Quick buzz for reminders
  static const List<int> reminder = [0, 100, 100, 100];

  // Longer pattern for important alerts
  static const List<int> alert = [0, 200, 100, 200, 100, 200];

  // Intense pattern for fight events
  static const List<int> fightEvent = [0, 500, 200, 500, 200, 500, 200, 500];

  // Critical - continuous heavy vibration
  static const List<int> critical = [
    0,
    1000,
    500,
    1000,
    500,
    1000,
    500,
    1000,
    500,
    1000,
  ];

  // Knockout celebration
  static const List<int> knockout = [
    0,
    300,
    100,
    300,
    100,
    300,
    100,
    600,
    200,
    600,
  ];
}

/// Full-screen alert configuration
class FullScreenAlert {
  final String title;
  final String subtitle;
  final Color primaryColor;
  final Color glowColor;
  final IconData icon;
  final bool pulseAnimation;
  final bool shakeEffect;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionLabel;

  FullScreenAlert({
    required this.title,
    required this.subtitle,
    this.primaryColor = const Color(0xFFFF3366),
    this.glowColor = const Color(0xFFFF3366),
    this.icon = Icons.notifications_active,
    this.pulseAnimation = true,
    this.shakeEffect = true,
    this.onDismiss,
    this.onAction,
    this.actionLabel,
  });
}

/// Fight Notification Service
class FightNotificationService extends ChangeNotifier {
  static final FightNotificationService _instance =
      FightNotificationService._internal();
  factory FightNotificationService() => _instance;
  FightNotificationService._internal();

  // State
  bool _isInitialized = false;
  bool _personalModeEnabled = true;
  bool _ppvModeEnabled = true;
  bool _vibrationEnabled = true;
  bool _fullScreenAlertsEnabled = true;

  // Scheduled notifications
  final List<FightNotification> _scheduledNotifications = [];
  final List<FightNotification> _notificationHistory = [];

  // Active full-screen alert
  FullScreenAlert? _activeFullScreenAlert;

  // Hydration tracker
  Timer? _hydrationTimer;
  int _hydrationCount = 0;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get personalModeEnabled => _personalModeEnabled;
  bool get ppvModeEnabled => _ppvModeEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get fullScreenAlertsEnabled => _fullScreenAlertsEnabled;
  List<FightNotification> get scheduledNotifications =>
      List.unmodifiable(_scheduledNotifications);
  List<FightNotification> get notificationHistory =>
      List.unmodifiable(_notificationHistory);
  FullScreenAlert? get activeFullScreenAlert => _activeFullScreenAlert;
  int get hydrationCount => _hydrationCount;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request notification permissions
    await _requestPermissions();

    // Set up default training notifications
    _setupDefaultTrainingNotifications();

    _isInitialized = true;
    debugPrint('🔔 Fight Notification Service initialized');
    notifyListeners();
  }

  /// Request necessary permissions
  Future<void> _requestPermissions() async {
    // In a real app, this would request:
    // - Notification permissions
    // - Vibration permissions
    // - Full-screen intent permissions (Android)
    // - Critical alert permissions (iOS)
    debugPrint('🔔 Requesting notification permissions...');
  }

  /// Set up default training notifications
  void _setupDefaultTrainingNotifications() {
    // Morning HR check at 6:30 AM
    scheduleDailyNotification(
      type: FightNotificationType.morningHRCheck,
      title: '💓 Morning HR Check',
      body: 'Record your resting heart rate while still in bed',
      hour: 6,
      minute: 30,
    );

    // Weight check at 7:00 AM
    scheduleDailyNotification(
      type: FightNotificationType.weightCheck,
      title: '⚖️ Morning Weigh-In',
      body: 'Step on the scale before eating or drinking',
      hour: 7,
      minute: 0,
    );

    // Sleep window at 10:00 PM
    scheduleDailyNotification(
      type: FightNotificationType.sleepWindow,
      title: '😴 Sleep Window',
      body: 'Wind down for optimal recovery. Lights out in 30 minutes.',
      hour: 22,
      minute: 0,
    );
  }

  /// Schedule a daily recurring notification
  void scheduleDailyNotification({
    required FightNotificationType type,
    required String title,
    required String body,
    required int hour,
    required int minute,
    NotificationPriority priority = NotificationPriority.normal,
  }) {
    final notification = FightNotification(
      id: '${type.name}_daily_${hour}_$minute',
      type: type,
      title: title,
      body: body,
      priority: priority,
      scheduledTime: _getNextOccurrence(hour, minute),
    );

    _scheduledNotifications.add(notification);
    debugPrint('🔔 Scheduled: $title at $hour:$minute');
  }

  /// Get next occurrence of a time
  DateTime _getNextOccurrence(int hour, int minute) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  /// Start hydration reminders (every 2 hours)
  void startHydrationReminders() {
    _hydrationTimer?.cancel();
    _hydrationCount = 0;

    _hydrationTimer = Timer.periodic(const Duration(hours: 2), (_) {
      _triggerHydrationReminder();
    });

    debugPrint('💧 Hydration reminders started');
    notifyListeners();
  }

  /// Stop hydration reminders
  void stopHydrationReminders() {
    _hydrationTimer?.cancel();
    _hydrationTimer = null;
    debugPrint('💧 Hydration reminders stopped');
    notifyListeners();
  }

  /// Trigger a hydration reminder
  void _triggerHydrationReminder() {
    _hydrationCount++;

    showNotification(
      FightNotification(
        id: 'hydration_$_hydrationCount',
        type: FightNotificationType.hydrationReminder,
        title: '💧 Hydration Check',
        body: 'Time to drink water! Stay at optimal hydration levels.',
      ),
    );
  }

  /// Log hydration (when user drinks water)
  void logHydration() {
    _hydrationCount++;
    notifyListeners();
    debugPrint('💧 Hydration logged: $_hydrationCount');
  }

  /// Show an immediate notification
  void showNotification(FightNotification notification) {
    _notificationHistory.add(notification);

    // Handle vibration
    if (notification.vibrate && _vibrationEnabled) {
      _triggerVibration(notification.priority);
    }

    // Handle full-screen alert
    if (notification.fullScreen && _fullScreenAlertsEnabled) {
      _showFullScreenAlert(notification);
    }

    notifyListeners();
    debugPrint('🔔 Notification: ${notification.title}');
  }

  /// Trigger vibration based on priority
  Future<void> _triggerVibration(NotificationPriority priority) async {
    List<int> pattern;

    switch (priority) {
      case NotificationPriority.low:
        pattern = VibrationPatterns.reminder;
        break;
      case NotificationPriority.normal:
        pattern = VibrationPatterns.reminder;
        break;
      case NotificationPriority.high:
        pattern = VibrationPatterns.alert;
        break;
      case NotificationPriority.critical:
        pattern = VibrationPatterns.critical;
        break;
    }

    // Use HapticFeedback for basic vibration
    for (int i = 0; i < pattern.length; i += 2) {
      if (i > 0) {
        await Future.delayed(Duration(milliseconds: pattern[i - 1]));
      }
      HapticFeedback.heavyImpact();
    }
  }

  /// Show full-screen alert
  void _showFullScreenAlert(FightNotification notification) {
    Color getColorForType(FightNotificationType type) {
      switch (type) {
        case FightNotificationType.mainEventWalkout:
          return const Color(0xFFFF3366);
        case FightNotificationType.fightResult:
          return const Color(0xFF00FF88);
        case FightNotificationType.fightWeekStart:
          return const Color(0xFFFFB800);
        default:
          return const Color(0xFF00D4FF);
      }
    }

    _activeFullScreenAlert = FullScreenAlert(
      title: notification.title,
      subtitle: notification.body,
      primaryColor: getColorForType(notification.type),
      glowColor: getColorForType(notification.type),
      icon: _getIconForType(notification.type),
      pulseAnimation: notification.priority == NotificationPriority.critical,
      shakeEffect: notification.type == FightNotificationType.mainEventWalkout,
    );

    notifyListeners();
  }

  /// Get icon for notification type
  IconData _getIconForType(FightNotificationType type) {
    switch (type) {
      case FightNotificationType.morningHRCheck:
        return Icons.favorite;
      case FightNotificationType.hydrationReminder:
        return Icons.water_drop;
      case FightNotificationType.weightCheck:
        return Icons.monitor_weight;
      case FightNotificationType.sleepWindow:
        return Icons.bedtime;
      case FightNotificationType.trainingReminder:
        return Icons.fitness_center;
      case FightNotificationType.recoveryDay:
        return Icons.self_improvement;
      case FightNotificationType.mealReminder:
        return Icons.restaurant;
      case FightNotificationType.supplementReminder:
        return Icons.medication;
      case FightNotificationType.ppvCountdown:
        return Icons.timer;
      case FightNotificationType.mainCardStarting:
        return Icons.tv;
      case FightNotificationType.mainEventWalkout:
        return Icons.sports_mma;
      case FightNotificationType.fightResult:
        return Icons.emoji_events;
      case FightNotificationType.pressConference:
        return Icons.mic;
      case FightNotificationType.fightWeekStart:
        return Icons.local_fire_department;
      case FightNotificationType.weighInReminder:
        return Icons.monitor_weight_outlined;
      case FightNotificationType.fightDayMorning:
        return Icons.wb_sunny;
      case FightNotificationType.fightTimeApproaching:
        return Icons.alarm;
    }
  }

  /// Dismiss active full-screen alert
  void dismissFullScreenAlert() {
    _activeFullScreenAlert?.onDismiss?.call();
    _activeFullScreenAlert = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PPV / FAN MODE NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Schedule PPV event notifications
  void schedulePPVNotifications({
    required String eventName,
    required DateTime eventTime,
    required String mainEvent,
  }) {
    // 1 day before
    final oneDayBefore = eventTime.subtract(const Duration(days: 1));
    _scheduledNotifications.add(
      FightNotification(
        id: 'ppv_1day_${eventName.hashCode}',
        type: FightNotificationType.ppvCountdown,
        title: '🥊 Tomorrow: $eventName',
        body: 'Main Event: $mainEvent',
        scheduledTime: oneDayBefore,
      ),
    );

    // 1 hour before main card
    final oneHourBefore = eventTime.subtract(const Duration(hours: 1));
    _scheduledNotifications.add(
      FightNotification(
        id: 'ppv_1hour_${eventName.hashCode}',
        type: FightNotificationType.ppvCountdown,
        title: '⏰ 1 Hour Until $eventName',
        body: 'Get your snacks ready!',
        priority: NotificationPriority.high,
        scheduledTime: oneHourBefore,
      ),
    );

    // Main card starting
    _scheduledNotifications.add(
      FightNotification(
        id: 'ppv_start_${eventName.hashCode}',
        type: FightNotificationType.mainCardStarting,
        title: '🔴 LIVE NOW: $eventName',
        body: 'Main card is starting!',
        priority: NotificationPriority.critical,
        scheduledTime: eventTime,
        fullScreen: true,
      ),
    );

    debugPrint('📺 PPV notifications scheduled for $eventName');
    notifyListeners();
  }

  /// Trigger main event walkout alert (real-time)
  void triggerMainEventWalkout(String fighterName) {
    showNotification(
      FightNotification(
        id: 'walkout_${DateTime.now().millisecondsSinceEpoch}',
        type: FightNotificationType.mainEventWalkout,
        title: '🚨 MAIN EVENT WALKOUT',
        body: '$fighterName is walking to the cage!',
        priority: NotificationPriority.critical,
        fullScreen: true,
      ),
    );

    // Heavy vibration pattern
    _triggerKnockoutVibration();
  }

  /// Trigger fight result notification
  void triggerFightResult({
    required String winner,
    required String method,
    required String round,
  }) {
    showNotification(
      FightNotification(
        id: 'result_${DateTime.now().millisecondsSinceEpoch}',
        type: FightNotificationType.fightResult,
        title: '🏆 $winner WINS!',
        body: 'Via $method in Round $round',
        priority: NotificationPriority.high,
        fullScreen: true,
      ),
    );

    _triggerKnockoutVibration();
  }

  /// Trigger knockout celebration vibration
  Future<void> _triggerKnockoutVibration() async {
    for (final duration in VibrationPatterns.knockout) {
      if (duration == 0) continue;
      HapticFeedback.heavyImpact();
      await Future.delayed(Duration(milliseconds: duration));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIGHT WEEK SPECIFIC NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Schedule fight week notifications for a fighter
  void scheduleFightWeekNotifications({
    required DateTime fightDate,
    required String opponent,
    required String weightClass,
  }) {
    // Fight week start (7 days before)
    final fightWeekStart = fightDate.subtract(const Duration(days: 7));
    _scheduledNotifications.add(
      FightNotification(
        id: 'fightweek_start',
        type: FightNotificationType.fightWeekStart,
        title: '🔥 FIGHT WEEK BEGINS',
        body: 'One week until $opponent. Time to taper and peak.',
        priority: NotificationPriority.high,
        scheduledTime: fightWeekStart,
      ),
    );

    // Weigh-in reminder (day before)
    final weighInDay = fightDate.subtract(const Duration(days: 1));
    _scheduledNotifications.add(
      FightNotification(
        id: 'weighin_reminder',
        type: FightNotificationType.weighInReminder,
        title: '⚖️ Weigh-In Tomorrow',
        body: 'Target: $weightClass. Final cut tonight.',
        priority: NotificationPriority.high,
        scheduledTime: weighInDay,
      ),
    );

    // Fight day morning
    final fightDayMorning = DateTime(
      fightDate.year,
      fightDate.month,
      fightDate.day,
      7,
    );
    _scheduledNotifications.add(
      FightNotification(
        id: 'fightday_morning',
        type: FightNotificationType.fightDayMorning,
        title: '☀️ FIGHT DAY',
        body: 'Today you face $opponent. Trust your preparation.',
        priority: NotificationPriority.critical,
        scheduledTime: fightDayMorning,
        fullScreen: true,
      ),
    );

    debugPrint('🥊 Fight week notifications scheduled');
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SETTINGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Toggle personal mode
  void setPersonalMode(bool enabled) {
    _personalModeEnabled = enabled;
    notifyListeners();
  }

  /// Toggle PPV mode
  void setPPVMode(bool enabled) {
    _ppvModeEnabled = enabled;
    notifyListeners();
  }

  /// Toggle vibration
  void setVibration(bool enabled) {
    _vibrationEnabled = enabled;
    notifyListeners();
  }

  /// Toggle full-screen alerts
  void setFullScreenAlerts(bool enabled) {
    _fullScreenAlertsEnabled = enabled;
    notifyListeners();
  }

  /// Clear all scheduled notifications
  void clearAllScheduled() {
    _scheduledNotifications.clear();
    notifyListeners();
  }

  /// Clear notification history
  void clearHistory() {
    _notificationHistory.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _hydrationTimer?.cancel();
    super.dispose();
  }
}
