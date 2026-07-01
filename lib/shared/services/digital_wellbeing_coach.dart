// ═══════════════════════════════════════════════════════════════════════════
// DIGITAL WELLBEING COACH — Smart Usage Monitoring & Wellness Nudges
// ═══════════════════════════════════════════════════════════════════════════
//
// Monitors app usage patterns and delivers contextual nudges for:
//  • Screen breaks after extended sessions
//  • Healthy habit reminders (hydration, movement, sleep)
//  • Training/rest balance awareness
//  • Social media consumption alerts
//  • Positive reinforcement for good habits
//
// Philosophy: Non-intrusive, evidence-based, respects user autonomy.
// Always explains WHY, never nags. User can snooze/dismiss.
// ═══════════════════════════════════════════════════════════════════════════

enum NudgeType {
  screenBreak('Screen Break', '👁️', 'rest'),
  hydration('Hydration', '💧', 'health'),
  movement('Movement', '🏃', 'health'),
  sleepReminder('Sleep Reminder', '🌙', 'recovery'),
  socialLimit('Social Limit', '📱', 'balance'),
  trainingReminder('Training Reminder', '🥊', 'performance'),
  positiveReinforcement('Great Job', '⭐', 'motivation'),
  breathwork('Breathwork', '🧘', 'recovery'),
  postureCheck('Posture Check', '🪑', 'health'),
  nutritionWindow('Nutrition Window', '🍽️', 'nutrition');

  final String label;
  final String emoji;
  final String category;
  const NudgeType(this.label, this.emoji, this.category);
}

enum NudgePriority { low, medium, high }

class WellbeingNudge {
  final String nudgeId;
  final NudgeType type;
  final NudgePriority priority;
  final String title;
  final String message;
  final String? scienceBasis;
  final DateTime triggeredAt;
  final Duration? snoozeOption;
  final bool dismissed;

  const WellbeingNudge({
    required this.nudgeId,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    this.scienceBasis,
    required this.triggeredAt,
    this.snoozeOption = const Duration(minutes: 30),
    this.dismissed = false,
  });

  Map<String, dynamic> toMap() => {
    'nudgeId': nudgeId,
    'type': type.label,
    'priority': priority.name,
    'title': title,
    'message': message,
    'scienceBasis': scienceBasis,
    'triggeredAt': triggeredAt.toIso8601String(),
  };
}

class UsageSession {
  final DateTime startTime;
  DateTime lastActiveTime;
  Duration totalActive;
  int screenTaps;
  int feedScrolls;
  int postsViewed;
  int postsCreated;
  int trainingScreenViews;
  int socialScreenViews;

  UsageSession({
    required this.startTime,
    DateTime? lastActiveTime,
    this.totalActive = Duration.zero,
    this.screenTaps = 0,
    this.feedScrolls = 0,
    this.postsViewed = 0,
    this.postsCreated = 0,
    this.trainingScreenViews = 0,
    this.socialScreenViews = 0,
  }) : lastActiveTime = lastActiveTime ?? startTime;

  Duration get sessionLength => lastActiveTime.difference(startTime);

  double get socialRatio {
    final total = trainingScreenViews + socialScreenViews;
    return total > 0 ? socialScreenViews / total : 0;
  }
}

class WellbeingProfile {
  final Duration dailyScreenTarget;
  final Duration breakInterval;
  final int targetWaterGlasses;
  final Duration sleepGoalTime; // e.g. Duration(hours: 22) = 10pm
  final bool breathworkEnabled;
  final bool postureCheckEnabled;

  const WellbeingProfile({
    this.dailyScreenTarget = const Duration(hours: 2),
    this.breakInterval = const Duration(minutes: 45),
    this.targetWaterGlasses = 8,
    this.sleepGoalTime = const Duration(hours: 22),
    this.breathworkEnabled = true,
    this.postureCheckEnabled = true,
  });
}

class DailyWellbeingSummary {
  final DateTime date;
  final Duration totalScreenTime;
  final int nudgesTriggered;
  final int nudgesDismissed;
  final int nudgesActedOn;
  final double wellbeingScore; // 0–100
  final List<String> highlights;
  final List<String> improvementAreas;

  const DailyWellbeingSummary({
    required this.date,
    required this.totalScreenTime,
    required this.nudgesTriggered,
    required this.nudgesDismissed,
    required this.nudgesActedOn,
    required this.wellbeingScore,
    required this.highlights,
    required this.improvementAreas,
  });

  Map<String, dynamic> toMap() => {
    'date': date.toIso8601String(),
    'screenMinutes': totalScreenTime.inMinutes,
    'nudgesTriggered': nudgesTriggered,
    'nudgesDismissed': nudgesDismissed,
    'nudgesActedOn': nudgesActedOn,
    'wellbeingScore': wellbeingScore,
    'highlights': highlights,
    'improvementAreas': improvementAreas,
  };
}

class DigitalWellbeingCoach {
  DigitalWellbeingCoach._();
  static final DigitalWellbeingCoach instance = DigitalWellbeingCoach._();

  WellbeingProfile _profile = const WellbeingProfile();
  UsageSession? _currentSession;
  final List<WellbeingNudge> _todayNudges = [];
  DateTime? _lastBreakNudge;
  DateTime? _lastHydrationNudge;
  int _waterGlassesToday = 0;

  WellbeingProfile get profile => _profile;
  List<WellbeingNudge> get todayNudges => List.unmodifiable(_todayNudges);
  UsageSession? get currentSession => _currentSession;

  void updateProfile(WellbeingProfile p) => _profile = p;

  /// Start tracking a new session
  void startSession() {
    _currentSession = UsageSession(startTime: DateTime.now());
  }

  /// Record a screen interaction
  void recordInteraction({
    String? screenName,
    bool isFeedScroll = false,
    bool isPostView = false,
    bool isPostCreate = false,
  }) {
    if (_currentSession == null) startSession();
    final session = _currentSession!;
    session.lastActiveTime = DateTime.now();
    session.screenTaps++;
    if (isFeedScroll) session.feedScrolls++;
    if (isPostView) session.postsViewed++;
    if (isPostCreate) session.postsCreated++;

    if (screenName != null) {
      if (_isSocialScreen(screenName)) {
        session.socialScreenViews++;
      } else if (_isTrainingScreen(screenName)) {
        session.trainingScreenViews++;
      }
    }

    session.totalActive = session.sessionLength;
  }

  /// Log hydration
  void logWaterGlass() => _waterGlassesToday++;

  /// Check if any nudges should fire
  List<WellbeingNudge> checkNudges() {
    final nudges = <WellbeingNudge>[];
    final now = DateTime.now();
    final session = _currentSession;

    if (session == null) return nudges;

    // Screen break nudge
    if (_shouldNudgeBreak(session, now)) {
      nudges.add(
        WellbeingNudge(
          nudgeId: 'break_${now.millisecondsSinceEpoch}',
          type: NudgeType.screenBreak,
          priority: session.sessionLength > const Duration(hours: 1)
              ? NudgePriority.high
              : NudgePriority.medium,
          title: 'Time for a screen break',
          message:
              'You\'ve been active for ${session.sessionLength.inMinutes} minutes. '
              'A 5-minute break helps reduce eye strain and mental fatigue.',
          scienceBasis:
              'Ophthalmology research shows the 20-20-20 rule (every 20 min, look 20 ft away for 20 sec) reduces digital eye strain by 50%.',
          triggeredAt: now,
        ),
      );
      _lastBreakNudge = now;
    }

    // Hydration nudge
    if (_shouldNudgeHydration(now)) {
      final remaining = _profile.targetWaterGlasses - _waterGlassesToday;
      if (remaining > 0) {
        nudges.add(
          WellbeingNudge(
            nudgeId: 'hydrate_${now.millisecondsSinceEpoch}',
            type: NudgeType.hydration,
            priority: remaining > 4 ? NudgePriority.medium : NudgePriority.low,
            title: 'Stay hydrated',
            message:
                '$remaining glasses to go today. Hydration improves reaction time and cognitive performance.',
            scienceBasis:
                '2% dehydration reduces cognitive performance by up to 20% and physical output by 10% (Cheuvront & Kenefick, 2014).',
            triggeredAt: now,
          ),
        );
        _lastHydrationNudge = now;
      }
    }

    // Social media consumption alert
    if (session.socialRatio > 0.7 && session.socialScreenViews > 10) {
      nudges.add(
        WellbeingNudge(
          nudgeId: 'social_${now.millisecondsSinceEpoch}',
          type: NudgeType.socialLimit,
          priority: NudgePriority.medium,
          title: 'Social feed check-in',
          message:
              'You\'ve spent most of this session on social content. '
              'Want to check your training dashboard instead?',
          triggeredAt: now,
        ),
      );
    }

    // Sleep reminder (evening only)
    if (_shouldNudgeSleep(now)) {
      nudges.add(
        WellbeingNudge(
          nudgeId: 'sleep_${now.millisecondsSinceEpoch}',
          type: NudgeType.sleepReminder,
          priority: NudgePriority.high,
          title: 'Wind down time',
          message:
              'Your sleep goal is approaching. Blue light from screens suppresses melatonin — '
              'consider switching to night mode or wrapping up.',
          scienceBasis:
              'Evening blue light exposure delays melatonin onset by ~90 minutes and reduces REM sleep quality (Harvard Health, 2020).',
          triggeredAt: now,
        ),
      );
    }

    // Breathwork suggestion after heavy session
    if (_profile.breathworkEnabled &&
        session.sessionLength > const Duration(minutes: 30) &&
        session.screenTaps > 100) {
      nudges.add(
        WellbeingNudge(
          nudgeId: 'breath_${now.millisecondsSinceEpoch}',
          type: NudgeType.breathwork,
          priority: NudgePriority.low,
          title: 'Quick reset: box breathing',
          message:
              'Try 4 cycles of box breathing (4s in, 4s hold, 4s out, 4s hold). '
              'Activates parasympathetic nervous system in under 2 minutes.',
          triggeredAt: now,
        ),
      );
    }

    // Posture check
    if (_profile.postureCheckEnabled &&
        session.sessionLength > const Duration(minutes: 20)) {
      nudges.add(
        WellbeingNudge(
          nudgeId: 'posture_${now.millisecondsSinceEpoch}',
          type: NudgeType.postureCheck,
          priority: NudgePriority.low,
          title: 'Posture check',
          message:
              'Roll shoulders back, chin tucked, spine neutral. '
              'Good posture reduces neck strain and improves breathing efficiency.',
          triggeredAt: now,
        ),
      );
    }

    // Positive reinforcement
    if (session.trainingScreenViews > session.socialScreenViews &&
        session.trainingScreenViews > 5) {
      nudges.add(
        WellbeingNudge(
          nudgeId: 'positive_${now.millisecondsSinceEpoch}',
          type: NudgeType.positiveReinforcement,
          priority: NudgePriority.low,
          title: 'Training-focused session',
          message:
              'Great work — you\'re spending more time on training content than scrolling. '
              'Focused athletes perform 15% better on fight night.',
          triggeredAt: now,
        ),
      );
    }

    _todayNudges.addAll(nudges);
    return nudges;
  }

  /// Generate daily wellbeing summary
  DailyWellbeingSummary generateDailySummary() {
    final session = _currentSession;
    final totalScreen = session?.totalActive ?? Duration.zero;

    final dismissed = _todayNudges.where((n) => n.dismissed).length;
    final acted = _todayNudges.length - dismissed;

    final highlights = <String>[];
    final improvements = <String>[];

    // Screen time assessment
    if (totalScreen <= _profile.dailyScreenTarget) {
      highlights.add(
        'Screen time within target (${totalScreen.inMinutes}min / ${_profile.dailyScreenTarget.inMinutes}min)',
      );
    } else {
      improvements.add(
        'Screen time exceeded target by ${(totalScreen - _profile.dailyScreenTarget).inMinutes} minutes',
      );
    }

    // Hydration
    if (_waterGlassesToday >= _profile.targetWaterGlasses) {
      highlights.add(
        'Hit hydration target: $_waterGlassesToday / ${_profile.targetWaterGlasses} glasses',
      );
    } else {
      improvements.add(
        'Hydration gap: $_waterGlassesToday / ${_profile.targetWaterGlasses} glasses',
      );
    }

    // Social balance
    if (session != null && session.socialRatio < 0.5) {
      highlights.add('Good social/training balance');
    } else if (session != null && session.socialRatio > 0.7) {
      improvements.add(
        'High social scrolling ratio — try redirecting to training content',
      );
    }

    // Wellbeing score
    double score = 60; // baseline
    if (totalScreen <= _profile.dailyScreenTarget) score += 15;
    if (_waterGlassesToday >= _profile.targetWaterGlasses) score += 10;
    if (session != null && session.socialRatio < 0.5) score += 10;
    if (acted > dismissed) score += 5;
    score = score.clamp(0, 100);

    return DailyWellbeingSummary(
      date: DateTime.now(),
      totalScreenTime: totalScreen,
      nudgesTriggered: _todayNudges.length,
      nudgesDismissed: dismissed,
      nudgesActedOn: acted,
      wellbeingScore: score,
      highlights: highlights,
      improvementAreas: improvements,
    );
  }

  /// Reset for new day
  void resetDaily() {
    _todayNudges.clear();
    _waterGlassesToday = 0;
    _currentSession = null;
    _lastBreakNudge = null;
    _lastHydrationNudge = null;
  }

  // ── Private helpers ───────────────────────────────────────────────────

  bool _shouldNudgeBreak(UsageSession session, DateTime now) {
    if (session.sessionLength < _profile.breakInterval) return false;
    if (_lastBreakNudge != null &&
        now.difference(_lastBreakNudge!) < _profile.breakInterval) {
      return false;
    }
    return true;
  }

  bool _shouldNudgeHydration(DateTime now) {
    if (_lastHydrationNudge != null &&
        now.difference(_lastHydrationNudge!) < const Duration(hours: 1)) {
      return false;
    }
    // Only during waking hours
    return now.hour >= 7 && now.hour <= 22;
  }

  bool _shouldNudgeSleep(DateTime now) {
    final sleepHour = _profile.sleepGoalTime.inHours;
    // Nudge 30 min before sleep goal
    return now.hour == sleepHour - 1 && now.minute >= 30 ||
        now.hour == sleepHour;
  }

  bool _isSocialScreen(String name) {
    const social = ['feed', 'social', 'post', 'comment', 'profile', 'chat'];
    return social.any((s) => name.toLowerCase().contains(s));
  }

  bool _isTrainingScreen(String name) {
    const training = [
      'dashboard',
      'training',
      'camp',
      'workout',
      'stats',
      'performance',
    ];
    return training.any((s) => name.toLowerCase().contains(s));
  }
}
