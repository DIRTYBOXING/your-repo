/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT CAMP SERVICE - Dynamic Fight Countdown & Theme Engine
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Combat sports-focused countdown system that makes the app "alive":
/// - Fight date tracking and countdown
/// - Automatic theme phase transitions
/// - Fight week intensity scaling
/// - Training camp periodization alignment
/// - PPV event detection and alerts
///
/// Theme Phases:
///   90+ days = Base Camp (Neon Blue) - Foundation building
///   60-89 days = Fight Camp (Neon Green) - Progressive overload
///   14-59 days = Fight Week approaching (Neon Amber) - Intensification
///   0-13 days = Fight Week (Neon Red) - Peak & taper
///   Post-fight = Recovery Mode (Neon Purple) - Deload
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Fight Camp phase enumeration
enum FightCampPhase {
  baseCamp, // 90+ days - Foundation
  fightCamp, // 60-89 days - Building
  approaching, // 14-59 days - Intensifying
  fightWeek, // 0-13 days - Peak/Taper
  fightDay, // Day 0
  recovery, // Post-fight
  noFight, // No scheduled fight
}

/// Phase theme colors
class FightCampTheme {
  final Color primary;
  final Color accent;
  final Color glow;
  final String phaseName;
  final String phaseDescription;
  final IconData phaseIcon;
  final List<Color> gradientColors;

  const FightCampTheme({
    required this.primary,
    required this.accent,
    required this.glow,
    required this.phaseName,
    required this.phaseDescription,
    required this.phaseIcon,
    required this.gradientColors,
  });

  // Predefined themes for each phase
  static const baseCamp = FightCampTheme(
    primary: Color(0xFF00D4FF),
    accent: Color(0xFF0090FF),
    glow: Color(0xFF00D4FF),
    phaseName: 'BASE CAMP',
    phaseDescription: 'Foundation Building',
    phaseIcon: Icons.foundation,
    gradientColors: [Color(0xFF00D4FF), Color(0xFF0052D4)],
  );

  static const fightCamp = FightCampTheme(
    primary: Color(0xFF00FF88),
    accent: Color(0xFF00CC66),
    glow: Color(0xFF00FF88),
    phaseName: 'FIGHT CAMP',
    phaseDescription: 'Progressive Overload',
    phaseIcon: Icons.fitness_center,
    gradientColors: [Color(0xFF00FF88), Color(0xFF00AA55)],
  );

  static const approaching = FightCampTheme(
    primary: Color(0xFFFFB800),
    accent: Color(0xFFFF9500),
    glow: Color(0xFFFFB800),
    phaseName: 'APPROACHING',
    phaseDescription: 'Intensification Phase',
    phaseIcon: Icons.warning_amber_rounded,
    gradientColors: [Color(0xFFFFB800), Color(0xFFFF6B00)],
  );

  static const fightWeek = FightCampTheme(
    primary: Color(0xFFFF3366),
    accent: Color(0xFFFF0044),
    glow: Color(0xFFFF3366),
    phaseName: 'FIGHT WEEK',
    phaseDescription: 'Peak & Taper',
    phaseIcon: Icons.local_fire_department,
    gradientColors: [Color(0xFFFF3366), Color(0xFFFF0044)],
  );

  static const fightDay = FightCampTheme(
    primary: Color(0xFFFF0000),
    accent: Color(0xFFCC0000),
    glow: Color(0xFFFF0000),
    phaseName: 'FIGHT DAY',
    phaseDescription: 'GO TIME',
    phaseIcon: Icons.sports_mma,
    gradientColors: [Color(0xFFFF0000), Color(0xFFAA0000)],
  );

  static const recovery = FightCampTheme(
    primary: Color(0xFFAA66FF),
    accent: Color(0xFF8844CC),
    glow: Color(0xFFAA66FF),
    phaseName: 'RECOVERY',
    phaseDescription: 'Active Deload',
    phaseIcon: Icons.self_improvement,
    gradientColors: [Color(0xFFAA66FF), Color(0xFF6644AA)],
  );

  static const noFight = FightCampTheme(
    primary: Color(0xFF00D4FF),
    accent: Color(0xFF0090FF),
    glow: Color(0xFF00D4FF),
    phaseName: 'FREE TRAINING',
    phaseDescription: 'No Scheduled Fight',
    phaseIcon: Icons.calendar_today,
    gradientColors: [Color(0xFF00D4FF), Color(0xFF0052D4)],
  );
}

/// Scheduled fight/event
class ScheduledFight {
  final String id;
  final String eventName;
  final String opponent;
  final DateTime fightDate;
  final String venue;
  final String? organization; // UFC, ONE, Bellator, etc.
  final String? weightClass;
  final bool isPPV;
  final bool isMainEvent;
  final String? posterUrl;

  ScheduledFight({
    required this.id,
    required this.eventName,
    required this.opponent,
    required this.fightDate,
    required this.venue,
    this.organization,
    this.weightClass,
    this.isPPV = false,
    this.isMainEvent = false,
    this.posterUrl,
  });

  /// Days until fight (negative = past)
  int get daysUntil => fightDate.difference(DateTime.now()).inDays;

  /// Hours until fight
  int get hoursUntil => fightDate.difference(DateTime.now()).inHours;

  /// Is fight in the past
  bool get isPast => fightDate.isBefore(DateTime.now());

  /// Is fight today
  bool get isToday {
    final now = DateTime.now();
    return fightDate.year == now.year &&
        fightDate.month == now.month &&
        fightDate.day == now.day;
  }
}

/// PPV Event for fan mode
class PPVEvent {
  final String id;
  final String eventName;
  final DateTime eventDate;
  final String organization;
  final List<String> mainCard;
  final String? mainEvent;
  final bool isLive;
  final String? streamUrl;

  PPVEvent({
    required this.id,
    required this.eventName,
    required this.eventDate,
    required this.organization,
    required this.mainCard,
    this.mainEvent,
    this.isLive = false,
    this.streamUrl,
  });

  bool get isToday {
    final now = DateTime.now();
    return eventDate.year == now.year &&
        eventDate.month == now.month &&
        eventDate.day == now.day;
  }

  bool get isUpcoming => eventDate.isAfter(DateTime.now());
}

/// Fight Camp Controller - Core Service
class FightCampService extends ChangeNotifier {
  static final FightCampService _instance = FightCampService._internal();
  factory FightCampService() => _instance;
  FightCampService._internal();

  // State
  ScheduledFight? _nextFight;
  FightCampPhase _currentPhase = FightCampPhase.noFight;
  FightCampTheme _currentTheme = FightCampTheme.noFight;
  bool _autoThemeEnabled = true;
  FightCampPhase? _manualPhaseOverride;
  Timer? _countdownTimer;

  // PPV tracking
  final List<PPVEvent> _upcomingPPVs = [];
  PPVEvent? _livePPV;
  bool _fightShowModeEnabled = false;

  // Getters
  ScheduledFight? get nextFight => _nextFight;
  FightCampPhase get currentPhase => _currentPhase;
  FightCampTheme get currentTheme => _currentTheme;
  bool get autoThemeEnabled => _autoThemeEnabled;
  FightCampPhase? get manualOverride => _manualPhaseOverride;
  List<PPVEvent> get upcomingPPVs => List.unmodifiable(_upcomingPPVs);
  PPVEvent? get livePPV => _livePPV;
  bool get fightShowModeEnabled => _fightShowModeEnabled;

  /// Countdown getters
  int get daysUntilFight => _nextFight?.daysUntil ?? -1;
  int get hoursUntilFight => _nextFight?.hoursUntil ?? -1;
  bool get hasFightScheduled => _nextFight != null && !_nextFight!.isPast;
  bool get isFightDay => _nextFight?.isToday ?? false;

  /// Formatted countdown string
  String get countdownString {
    if (_nextFight == null) return 'NO FIGHT SCHEDULED';
    if (_nextFight!.isPast) return 'FIGHT COMPLETED';

    final days = _nextFight!.daysUntil;
    final hours = _nextFight!.hoursUntil % 24;

    if (days == 0) {
      if (hours <= 0) return 'FIGHT TIME!';
      return '$hours HOURS';
    }
    if (days == 1) return '1 DAY, $hours HRS';
    if (days < 7) return '$days DAYS, $hours HRS';

    final weeks = days ~/ 7;
    final remainingDays = days % 7;
    if (weeks < 4) {
      return '$weeks WKS, $remainingDays DAYS';
    }

    return '$days DAYS';
  }

  /// Initialize the Fight Camp service
  Future<void> initialize() async {
    await _loadFightData();

    _startCountdownTimer();
    _updatePhase();

    debugPrint('🥊 Fight Camp Service initialized');
    Future.microtask(notifyListeners);
  }

  /// Load fight data from Firestore
  Future<void> _loadFightData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Load user's next scheduled fight
      final fightSnap = await FirebaseFirestore.instance
          .collection('scheduled_fights')
          .where('userId', isEqualTo: uid)
          .where(
            'fightDate',
            isGreaterThan: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 14)),
            ),
          )
          .orderBy('fightDate')
          .limit(1)
          .get();

      if (fightSnap.docs.isNotEmpty) {
        final doc = fightSnap.docs.first;
        final d = doc.data();
        _nextFight = ScheduledFight(
          id: doc.id,
          eventName: d['eventName'] ?? '',
          opponent: d['opponent'] ?? 'TBD',
          fightDate: (d['fightDate'] as Timestamp).toDate(),
          venue: d['venue'] ?? '',
          organization: d['organization'],
          weightClass: d['weightClass'],
          isPPV: d['isPPV'] ?? false,
          isMainEvent: d['isMainEvent'] ?? false,
          posterUrl: d['posterUrl'],
        );
      }

      // Load upcoming PPV events
      final ppvSnap = await FirebaseFirestore.instance
          .collection('ppv_events')
          .where('eventDate', isGreaterThan: Timestamp.now())
          .orderBy('eventDate')
          .limit(10)
          .get();

      _upcomingPPVs.clear();
      for (final doc in ppvSnap.docs) {
        final d = doc.data();
        _upcomingPPVs.add(
          PPVEvent(
            id: doc.id,
            eventName: d['eventName'] ?? '',
            eventDate: (d['eventDate'] as Timestamp).toDate(),
            organization: d['organization'] ?? '',
            mainCard: List<String>.from(d['mainCard'] ?? []),
            mainEvent: d['mainEvent'],
            isLive: d['isLive'] ?? false,
            streamUrl: d['streamUrl'],
          ),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Fight Camp load error: $e');
    }
  }

  /// Start real-time countdown timer
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updatePhase();
      notifyListeners();
    });
  }

  /// Update the current phase based on fight date
  void _updatePhase() {
    if (_manualPhaseOverride != null) {
      _currentPhase = _manualPhaseOverride!;
      _currentTheme = _getThemeForPhase(_currentPhase);
      return;
    }

    if (_nextFight == null) {
      _currentPhase = FightCampPhase.noFight;
      _currentTheme = FightCampTheme.noFight;
      return;
    }

    final days = _nextFight!.daysUntil;

    if (days < 0) {
      // Post-fight recovery
      if (days > -14) {
        _currentPhase = FightCampPhase.recovery;
      } else {
        _currentPhase = FightCampPhase.noFight;
      }
    } else if (days == 0) {
      _currentPhase = FightCampPhase.fightDay;
    } else if (days <= 13) {
      _currentPhase = FightCampPhase.fightWeek;
    } else if (days <= 59) {
      _currentPhase = FightCampPhase.approaching;
    } else if (days <= 89) {
      _currentPhase = FightCampPhase.fightCamp;
    } else {
      _currentPhase = FightCampPhase.baseCamp;
    }

    _currentTheme = _getThemeForPhase(_currentPhase);
  }

  /// Get theme for a specific phase
  FightCampTheme _getThemeForPhase(FightCampPhase phase) {
    switch (phase) {
      case FightCampPhase.baseCamp:
        return FightCampTheme.baseCamp;
      case FightCampPhase.fightCamp:
        return FightCampTheme.fightCamp;
      case FightCampPhase.approaching:
        return FightCampTheme.approaching;
      case FightCampPhase.fightWeek:
        return FightCampTheme.fightWeek;
      case FightCampPhase.fightDay:
        return FightCampTheme.fightDay;
      case FightCampPhase.recovery:
        return FightCampTheme.recovery;
      case FightCampPhase.noFight:
        return FightCampTheme.noFight;
    }
  }

  /// Schedule a new fight
  void scheduleFight(ScheduledFight fight) {
    _nextFight = fight;
    _updatePhase();
    notifyListeners();
    debugPrint('🥊 Fight scheduled: ${fight.eventName} vs ${fight.opponent}');
  }

  /// Clear scheduled fight
  void clearFight() {
    _nextFight = null;
    _updatePhase();
    notifyListeners();
    debugPrint('🥊 Fight cleared');
  }

  /// Toggle auto theme
  void setAutoTheme(bool enabled) {
    _autoThemeEnabled = enabled;
    if (enabled) {
      _manualPhaseOverride = null;
      _updatePhase();
    }
    notifyListeners();
  }

  /// Set manual phase override
  void setManualPhase(FightCampPhase? phase) {
    _manualPhaseOverride = phase;
    _autoThemeEnabled = phase == null;
    _updatePhase();
    notifyListeners();
  }

  /// Enable fight show mode (PPV viewing)
  void enableFightShowMode(PPVEvent? event) {
    _fightShowModeEnabled = true;
    _livePPV = event;
    notifyListeners();
    debugPrint('📺 Fight Show Mode enabled: ${event?.eventName}');
  }

  /// Disable fight show mode
  void disableFightShowMode() {
    _fightShowModeEnabled = false;
    _livePPV = null;
    notifyListeners();
    debugPrint('📺 Fight Show Mode disabled');
  }

  /// Get intensity multiplier for training (1.0 = normal)
  double get trainingIntensityMultiplier {
    switch (_currentPhase) {
      case FightCampPhase.baseCamp:
        return 0.7;
      case FightCampPhase.fightCamp:
        return 1.0;
      case FightCampPhase.approaching:
        return 1.2;
      case FightCampPhase.fightWeek:
        return 0.8; // Taper
      case FightCampPhase.fightDay:
        return 0.3; // Minimal
      case FightCampPhase.recovery:
        return 0.5;
      case FightCampPhase.noFight:
        return 0.8;
    }
  }

  /// Get phase-specific training recommendations
  List<String> get phaseRecommendations {
    switch (_currentPhase) {
      case FightCampPhase.baseCamp:
        return [
          'Focus on building aerobic base',
          'Technical drilling - high volume, low intensity',
          'Strength training - hypertrophy phase',
          'Address weaknesses in game',
        ];
      case FightCampPhase.fightCamp:
        return [
          'Progressive sparring intensity',
          'Implement game plan specifics',
          'Strength training - power phase',
          'Increase conditioning volume',
        ];
      case FightCampPhase.approaching:
        return [
          'Peak sparring sessions',
          'Sharpen combinations and setups',
          'Maintain weight management',
          'Mental preparation and visualization',
        ];
      case FightCampPhase.fightWeek:
        return [
          'Light technical work only',
          'Focus on recovery and sleep',
          'Final weight cut management',
          'Mental readiness and confidence',
        ];
      case FightCampPhase.fightDay:
        return [
          'Stay relaxed and focused',
          'Light movement and stretching',
          'Eat and hydrate properly',
          'Trust your preparation',
        ];
      case FightCampPhase.recovery:
        return [
          'Active recovery - light movement',
          'Address any injuries',
          'Mental decompression',
          'Celebrate and evaluate performance',
        ];
      case FightCampPhase.noFight:
        return [
          'Maintain base fitness',
          'Work on skill development',
          'Stay ready for opportunities',
          'Enjoy the process',
        ];
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
