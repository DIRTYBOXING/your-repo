import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT CAMP COACH BOT — Intelligent Companion for Fighters in Camp
/// ═══════════════════════════════════════════════════════════════════════════
///
/// NOT just automation. Real intelligence. Real wisdom.
///
/// This bot understands:
///   • The loneliness of being away from family during camp
///   • The crushing pressure of weight cuts
///   • The mental toll of fight week anxiety
///   • The need for structure when discipline is fading
///   • The difference between pushing through and breaking down
///
/// Architecture:
///   1. Daily Check-In Engine — mood/sleep/weight/motivation tracking
///   2. Adaptive Periodization — recommendations based on phase + biometrics
///   3. Loneliness & Separation Detection — coping strategies, not platitudes
///   4. Pressure Management — fight week / weight cut / media day
///   5. Motivation Engine — adapts to fighter state, never generic
///   6. Planning & Scheduling — keeps them on track without nagging
///   7. Pattern Recognition — overtraining, sleep debt, HRV decline
///
/// Firestore:
///   fight_camp_checkins/{odId}     — Daily check-in snapshots
///   fight_camp_journal/{odId}      — Private journal entries
///   fight_camp_plans/{odId}        — Active training plans
///
/// ═══════════════════════════════════════════════════════════════════════════

// ── Check-In Categories ────────────────────────────────────────────────────

enum CampMood {
  lockedIn, // Focused, energized, ready
  steady, // Solid, no complaints
  flat, // Low energy but functioning
  struggling, // Noticeable difficulty
  breaking, // Crisis-level distress
}

enum CampConcern {
  none,
  missingFamily,
  weightStress,
  injuryFear,
  opponentAnxiety,
  financialPressure,
  sleepIssues,
  lonelinessIsolation,
  motivationLoss,
  overtrainingFatigue,
  mediaPresssure,
  coachConflict,
  teammateTension,
}

enum FighterMindset {
  warrior, // "I'm built for this"
  disciplined, // "Process over feelings"
  anxious, // "What if I'm not ready"
  doubtful, // "Maybe this isn't for me"
  desperate, // "I just need to survive"
}

enum CampAdvisoryLevel {
  /// All clear — keep grinding
  green,

  /// Some flags — minor adjustments recommended
  yellow,

  /// Caution — reduce load, check in more
  orange,

  /// Alert — rest required, human support recommended
  red,

  /// Emergency — stop training, seek professional help
  black,
}

// ── Data Models ────────────────────────────────────────────────────────────

class DailyCheckIn {
  final String id;
  final String fighterId;
  final DateTime timestamp;
  final CampMood mood;
  final double sleepHours;
  final double sleepQuality; // 0-1
  final double weight; // kg
  final double targetWeight; // kg
  final double motivationScore; // 0-1
  final double energyLevel; // 0-1
  final double painLevel; // 0-1
  final double stressLevel; // 0-1
  final double homesickLevel; // 0-1
  final List<CampConcern> concerns;
  final FighterMindset mindset;
  final String? journalNote;
  final int daysUntilFight;

  const DailyCheckIn({
    required this.id,
    required this.fighterId,
    required this.timestamp,
    required this.mood,
    required this.sleepHours,
    required this.sleepQuality,
    required this.weight,
    required this.targetWeight,
    required this.motivationScore,
    required this.energyLevel,
    this.painLevel = 0,
    this.stressLevel = 0,
    this.homesickLevel = 0,
    this.concerns = const [],
    this.mindset = FighterMindset.disciplined,
    this.journalNote,
    this.daysUntilFight = -1,
  });

  double get weightDelta => weight - targetWeight;
  bool get isOverweight => weightDelta > 0;
  bool get isCriticalWeight => weightDelta > 3.0;
  bool get isSleepDeprived => sleepHours < 6.0;
  bool get isChronicSleepDebt => sleepHours < 5.0;
  bool get isHighStress => stressLevel > 0.7;
  bool get isHomesick => homesickLevel > 0.6;
  bool get isLowMotivation => motivationScore < 0.4;
  bool get isInPain => painLevel > 0.5;

  Map<String, dynamic> toFirestore() => {
    'fighterId': fighterId,
    'timestamp': Timestamp.fromDate(timestamp),
    'mood': mood.name,
    'sleepHours': sleepHours,
    'sleepQuality': sleepQuality,
    'weight': weight,
    'targetWeight': targetWeight,
    'motivationScore': motivationScore,
    'energyLevel': energyLevel,
    'painLevel': painLevel,
    'stressLevel': stressLevel,
    'homesickLevel': homesickLevel,
    'concerns': concerns.map((c) => c.name).toList(),
    'mindset': mindset.name,
    'journalNote': journalNote,
    'daysUntilFight': daysUntilFight,
  };

  factory DailyCheckIn.fromFirestore(String id, Map<String, dynamic> d) {
    return DailyCheckIn(
      id: id,
      fighterId: d['fighterId'] ?? '',
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mood: CampMood.values.firstWhere(
        (m) => m.name == d['mood'],
        orElse: () => CampMood.steady,
      ),
      sleepHours: (d['sleepHours'] as num?)?.toDouble() ?? 7,
      sleepQuality: (d['sleepQuality'] as num?)?.toDouble() ?? 0.7,
      weight: (d['weight'] as num?)?.toDouble() ?? 70,
      targetWeight: (d['targetWeight'] as num?)?.toDouble() ?? 70,
      motivationScore: (d['motivationScore'] as num?)?.toDouble() ?? 0.7,
      energyLevel: (d['energyLevel'] as num?)?.toDouble() ?? 0.7,
      painLevel: (d['painLevel'] as num?)?.toDouble() ?? 0,
      stressLevel: (d['stressLevel'] as num?)?.toDouble() ?? 0,
      homesickLevel: (d['homesickLevel'] as num?)?.toDouble() ?? 0,
      concerns:
          (d['concerns'] as List<dynamic>?)
              ?.map(
                (c) => CampConcern.values.firstWhere(
                  (v) => v.name == c,
                  orElse: () => CampConcern.none,
                ),
              )
              .toList() ??
          [],
      mindset: FighterMindset.values.firstWhere(
        (m) => m.name == d['mindset'],
        orElse: () => FighterMindset.disciplined,
      ),
      journalNote: d['journalNote'],
      daysUntilFight: d['daysUntilFight'] ?? -1,
    );
  }
}

/// Structured guidance from the Fight Camp Coach
class CampGuidance {
  final CampAdvisoryLevel level;
  final String headline;
  final String message;
  final List<String> actions;
  final List<String> affirmations;
  final bool suggestHumanContact;
  final String? humanContactType; // 'coach', 'family', 'therapist', 'doctor'
  final Map<String, dynamic> context;

  const CampGuidance({
    required this.level,
    required this.headline,
    required this.message,
    required this.actions,
    this.affirmations = const [],
    this.suggestHumanContact = false,
    this.humanContactType,
    this.context = const {},
  });
}

/// Weekly trend analysis
class CampTrendAnalysis {
  final double avgMood; // 0-1 mapped from CampMood
  final double avgSleep;
  final double avgMotivation;
  final double avgEnergy;
  final double avgStress;
  final double weightTrend; // positive = gaining, negative = losing
  final double sleepDebt; // cumulative hours below 7
  final int consecutiveLowDays;
  final List<CampConcern> recurringConcerns;
  final String trendDirection; // 'improving', 'stable', 'declining', 'critical'

  const CampTrendAnalysis({
    required this.avgMood,
    required this.avgSleep,
    required this.avgMotivation,
    required this.avgEnergy,
    required this.avgStress,
    required this.weightTrend,
    required this.sleepDebt,
    required this.consecutiveLowDays,
    required this.recurringConcerns,
    required this.trendDirection,
  });
}

// ── THE ENGINE ─────────────────────────────────────────────────────────────

/// Fight Camp Coach Bot — Your corner when you have no corner.
///
/// PHILOSOPHY:
/// - A fighter in camp is a human being under extraordinary pressure.
/// - Loneliness, weight cuts, injury fear, and family separation are REAL.
/// - This bot does not motivate with empty slogans.
/// - It provides STRUCTURE when discipline is fading.
/// - It provides WARMTH when isolation is creeping in.
/// - It provides LOGIC when emotions are taking over.
/// - It ALWAYS defers to human support when distress is genuine.
///
/// RULES (NON-NEGOTIABLE):
/// 1. Never tell a fighter to "push through" pain
/// 2. Never dismiss emotional distress
/// 3. Never replace a real coach, doctor, or therapist
/// 4. Always acknowledge the sacrifice of being away from family
/// 5. Always use calm, grounded language — no hype, no platitudes
/// 6. Always track patterns — one bad day is normal, five is a signal
class FightCampCoachBotService extends ChangeNotifier {
  static final FightCampCoachBotService _instance =
      FightCampCoachBotService._internal();
  factory FightCampCoachBotService() => _instance;
  FightCampCoachBotService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State
  List<DailyCheckIn> _recentCheckIns = [];
  CampTrendAnalysis? _currentTrend;
  CampAdvisoryLevel _advisoryLevel = CampAdvisoryLevel.green;
  bool _initialized = false;

  // Getters
  List<DailyCheckIn> get recentCheckIns => List.unmodifiable(_recentCheckIns);
  CampTrendAnalysis? get currentTrend => _currentTrend;
  CampAdvisoryLevel get advisoryLevel => _advisoryLevel;
  bool get initialized => _initialized;

  /// Initialize — load recent check-ins and compute trends
  Future<void> initialize() async {
    if (_initialized) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snap = await _firestore
          .collection('fight_camp_checkins')
          .where('fighterId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .limit(14)
          .get();

      _recentCheckIns = snap.docs
          .map((d) => DailyCheckIn.fromFirestore(d.id, d.data()))
          .toList();

      if (_recentCheckIns.length >= 3) {
        _currentTrend = _analyzeTrend(_recentCheckIns);
        _advisoryLevel = _computeAdvisoryLevel(
          _recentCheckIns.first,
          _currentTrend!,
        );
      }

      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('⚔️ FightCampCoach: init error: $e');
      _initialized = true;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. DAILY CHECK-IN ENGINE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Submit daily check-in and receive immediate guidance
  Future<CampGuidance> submitCheckIn(DailyCheckIn checkIn) async {
    try {
      final docRef = await _firestore
          .collection('fight_camp_checkins')
          .add(checkIn.toFirestore());

      final saved = DailyCheckIn(
        id: docRef.id,
        fighterId: checkIn.fighterId,
        timestamp: checkIn.timestamp,
        mood: checkIn.mood,
        sleepHours: checkIn.sleepHours,
        sleepQuality: checkIn.sleepQuality,
        weight: checkIn.weight,
        targetWeight: checkIn.targetWeight,
        motivationScore: checkIn.motivationScore,
        energyLevel: checkIn.energyLevel,
        painLevel: checkIn.painLevel,
        stressLevel: checkIn.stressLevel,
        homesickLevel: checkIn.homesickLevel,
        concerns: checkIn.concerns,
        mindset: checkIn.mindset,
        journalNote: checkIn.journalNote,
        daysUntilFight: checkIn.daysUntilFight,
      );

      _recentCheckIns.insert(0, saved);
      if (_recentCheckIns.length > 14) _recentCheckIns.removeLast();

      if (_recentCheckIns.length >= 3) {
        _currentTrend = _analyzeTrend(_recentCheckIns);
        _advisoryLevel = _computeAdvisoryLevel(saved, _currentTrend!);
      }

      notifyListeners();
      return generateGuidance(saved, _currentTrend);
    } catch (e) {
      debugPrint('⚔️ FightCampCoach: checkIn error: $e');
      return generateGuidance(checkIn, null);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. INTELLIGENCE ENGINE — Pattern Recognition & Guidance
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate intelligent guidance based on current state + trends
  CampGuidance generateGuidance(
    DailyCheckIn current,
    CampTrendAnalysis? trend,
  ) {
    // Collect all active signals
    final signals = <String, double>{};
    final concerns = <String>[];

    // ── Sleep Analysis ──
    if (current.isChronicSleepDebt) {
      signals['criticalSleep'] = 0.9;
      concerns.add('chronic sleep deprivation');
    } else if (current.isSleepDeprived) {
      signals['lowSleep'] = 0.6;
    }

    if (trend != null && trend.sleepDebt > 10) {
      signals['sleepDebtAccumulated'] = 0.8;
      concerns.add(
        'accumulated sleep debt of ${trend.sleepDebt.toStringAsFixed(1)} hours',
      );
    }

    // ── Weight Analysis ──
    if (current.isCriticalWeight && current.daysUntilFight > 0) {
      final daysLeft = current.daysUntilFight;
      final kgPerDay = current.weightDelta / max(daysLeft, 1);
      if (kgPerDay > 0.5) {
        signals['dangerousWeightCut'] = 0.95;
        concerns.add(
          'need to lose ${current.weightDelta.toStringAsFixed(1)}kg '
          'in $daysLeft days (${kgPerDay.toStringAsFixed(2)}kg/day)',
        );
      } else {
        signals['weightBehind'] = 0.6;
      }
    } else if (current.isOverweight) {
      signals['overweight'] = 0.4;
    }

    // ── Mental State Analysis ──
    if (current.mood == CampMood.breaking) {
      signals['mentalCrisis'] = 1.0;
      concerns.add('fighter reporting crisis-level distress');
    } else if (current.mood == CampMood.struggling) {
      signals['mentalStruggle'] = 0.7;
    }

    if (current.isLowMotivation) {
      signals['motivationDrop'] = 0.6;
    }

    if (current.mindset == FighterMindset.desperate) {
      signals['desperateMindset'] = 0.85;
      concerns.add('desperate mindset — risk of reckless behavior');
    }

    // ── Isolation & Homesickness ──
    if (current.isHomesick) {
      signals['homesick'] = current.homesickLevel;
      if (current.homesickLevel > 0.8) {
        concerns.add('severe homesickness');
      }
    }

    if (current.concerns.contains(CampConcern.lonelinessIsolation)) {
      signals['isolation'] = 0.7;
    }

    if (current.concerns.contains(CampConcern.missingFamily)) {
      signals['missingFamily'] = 0.65;
    }

    // ── Pain & Injury ──
    if (current.isInPain) {
      signals['pain'] = current.painLevel;
      if (current.painLevel > 0.7) {
        concerns.add('significant pain reported');
      }
    }

    // ── Overtraining Detection ──
    if (current.energyLevel < 0.3 && current.stressLevel > 0.7) {
      signals['overtrained'] = 0.8;
      concerns.add('low energy + high stress = overtraining pattern');
    }

    // ── Trend-Based Signals ──
    if (trend != null) {
      if (trend.consecutiveLowDays >= 3) {
        signals['multiDayDecline'] = 0.75;
        concerns.add('${trend.consecutiveLowDays} consecutive low days');
      }
      if (trend.trendDirection == 'critical') {
        signals['criticalTrend'] = 0.9;
      } else if (trend.trendDirection == 'declining') {
        signals['decliningTrend'] = 0.65;
      }
    }

    // ── Compute Advisory Level ──
    final maxSignal = signals.isEmpty
        ? 0.0
        : signals.values.reduce((a, b) => a > b ? a : b);

    CampAdvisoryLevel level;
    if (maxSignal >= 0.95) {
      level = CampAdvisoryLevel.black;
    } else if (maxSignal >= 0.8) {
      level = CampAdvisoryLevel.red;
    } else if (maxSignal >= 0.6) {
      level = CampAdvisoryLevel.orange;
    } else if (maxSignal >= 0.4) {
      level = CampAdvisoryLevel.yellow;
    } else {
      level = CampAdvisoryLevel.green;
    }

    // ── Generate Response ──
    return _buildGuidance(level, current, trend, signals, concerns);
  }

  CampGuidance _buildGuidance(
    CampAdvisoryLevel level,
    DailyCheckIn current,
    CampTrendAnalysis? trend,
    Map<String, double> signals,
    List<String> concerns,
  ) {
    switch (level) {
      case CampAdvisoryLevel.black:
        return _buildBlackGuidance(current, signals, concerns);
      case CampAdvisoryLevel.red:
        return _buildRedGuidance(current, signals, concerns);
      case CampAdvisoryLevel.orange:
        return _buildOrangeGuidance(current, trend, signals);
      case CampAdvisoryLevel.yellow:
        return _buildYellowGuidance(current, trend, signals);
      case CampAdvisoryLevel.green:
        return _buildGreenGuidance(current, trend);
    }
  }

  CampGuidance _buildBlackGuidance(
    DailyCheckIn current,
    Map<String, double> signals,
    List<String> concerns,
  ) {
    final actions = <String>[
      'Stop training immediately — this is not weakness, it is wisdom',
      'Contact your head coach and be completely honest',
    ];
    String humanType = 'coach';

    if (signals.containsKey('mentalCrisis')) {
      actions.add(
        'Reach out to someone you trust — family, friend, or counselor',
      );
      actions.add(
        'You are not your fight record. You are a human being who matters.',
      );
      humanType = 'therapist';
    }

    if (signals.containsKey('dangerousWeightCut')) {
      actions.add('Consult your doctor about safe weight management options');
      actions.add('Missing weight is better than destroying your body');
      humanType = 'doctor';
    }

    return CampGuidance(
      level: CampAdvisoryLevel.black,
      headline: 'FULL STOP — Your Health Comes First',
      message:
          'I see multiple serious signals today. '
          'This is not about the fight — this is about you, the person. '
          '${concerns.join(". ")}. '
          'The bravest thing a fighter can do is protect themselves.',
      actions: actions,
      affirmations: [
        'Strength is knowing when to pause',
        'No fight is worth more than your wellbeing',
        'You have already proven your courage by showing up to camp',
      ],
      suggestHumanContact: true,
      humanContactType: humanType,
    );
  }

  CampGuidance _buildRedGuidance(
    DailyCheckIn current,
    Map<String, double> signals,
    List<String> concerns,
  ) {
    final actions = <String>[];

    if (signals.containsKey('overtrained')) {
      actions.addAll([
        'Active recovery only today — walk, light stretch, breathing',
        'No sparring until energy returns above baseline',
        'Add 30 minutes to sleep tonight — non-negotiable',
      ]);
    }

    if (signals.containsKey('homesick') || signals.containsKey('isolation')) {
      actions.addAll([
        'Schedule a video call with family tonight',
        'Share a meal with a teammate — isolation feeds on itself',
        'Write down three things you are grateful they support you in',
      ]);
    }

    if (signals.containsKey('desperateMindset')) {
      actions.addAll([
        'Rewrite your fight intention: what are you fighting FOR, not against',
        'Talk to your coach about adjusting the game plan',
        'One round at a time. Not the whole fight.',
      ]);
    }

    if (actions.isEmpty) {
      actions.addAll([
        'Reduce training intensity by 40% today',
        'Prioritize sleep and nutrition above all else',
        'Check in with your coach — be honest about how you feel',
      ]);
    }

    return CampGuidance(
      level: CampAdvisoryLevel.red,
      headline: 'Recovery Mode — Listen to Your Body',
      message:
          'Your body and mind are sending clear signals. '
          'This is not failure — this is data. '
          'The best fighters know that recovery IS training.',
      actions: actions,
      affirmations: [
        'Rest builds the foundation that performance stands on',
        'Every champion has had days like this',
        'You are investing in fight night by recovering now',
      ],
      suggestHumanContact: true,
      humanContactType: 'coach',
    );
  }

  CampGuidance _buildOrangeGuidance(
    DailyCheckIn current,
    CampTrendAnalysis? trend,
    Map<String, double> signals,
  ) {
    final actions = <String>[];

    if (signals.containsKey('lowSleep') ||
        signals.containsKey('sleepDebtAccumulated')) {
      actions.addAll([
        'Sleep target tonight: ${(current.sleepHours + 1.5).toStringAsFixed(1)} hours minimum',
        'No screens 30 minutes before bed',
        'Cool room, dark room, no alarms if possible',
      ]);
    }

    if (signals.containsKey('weightBehind')) {
      actions.addAll([
        'Review nutrition plan with your nutritionist',
        'Track water intake — hydration helps weight management',
        'Avoid panic cutting — steady is faster than crash',
      ]);
    }

    if (signals.containsKey('motivationDrop')) {
      actions.addAll([
        'Watch film of your best performance',
        'Remind yourself why you started this camp',
        'Set one small goal for today — just one — and crush it',
      ]);
    }

    if (signals.containsKey('missingFamily')) {
      actions.add('Call home tonight. Hearing their voices is medicine.');
    }

    if (actions.isEmpty) {
      actions.addAll([
        'Reduce intensity by 20% and focus on technique',
        'Hydrate aggressively — your body is asking for it',
        'Journal for 5 minutes tonight — get thoughts out of your head',
      ]);
    }

    return CampGuidance(
      level: CampAdvisoryLevel.orange,
      headline: 'Adjust & Adapt',
      message:
          'A few indicators are elevated. Nothing alarming on its own, '
          'but together they tell a story. '
          'Small adjustments now prevent big problems later.',
      actions: actions,
      affirmations: [
        'Smart fighters adapt. That is exactly what you are doing.',
        'Camp is a marathon, not a sprint',
      ],
    );
  }

  CampGuidance _buildYellowGuidance(
    DailyCheckIn current,
    CampTrendAnalysis? trend,
    Map<String, double> signals,
  ) {
    final actions = <String>[];

    if (current.daysUntilFight > 0 && current.daysUntilFight <= 7) {
      // FIGHT WEEK
      actions.addAll([
        'Taper sessions — technique only, no new skills',
        'Visualize the game plan for 10 minutes today',
        'Hydrate and fuel — you are loading the weapon',
      ]);
    } else if (current.daysUntilFight > 7 && current.daysUntilFight <= 21) {
      // APPROACHING
      actions.addAll([
        'Sparring is about sharpening, not surviving',
        'Review opponent footage — look for patterns, not fear',
        'Keep weight management on track — no heroic cuts later',
      ]);
    } else {
      // BASE / FIGHT CAMP
      actions.addAll([
        'Good camp is boring camp. Stay consistent.',
        'Focus on recovery quality as much as training quality',
        'Track one personal metric to beat this week',
      ]);
    }

    return CampGuidance(
      level: CampAdvisoryLevel.yellow,
      headline: 'Stay the Course',
      message:
          'Minor flags but nothing major. Keep doing what you are doing '
          'with a few small adjustments.',
      actions: actions,
      affirmations: [
        'Consistency beats intensity every time',
        'You are exactly where you need to be',
      ],
    );
  }

  CampGuidance _buildGreenGuidance(
    DailyCheckIn current,
    CampTrendAnalysis? trend,
  ) {
    final actions = <String>[];

    if (current.daysUntilFight > 0 && current.daysUntilFight <= 3) {
      actions.addAll([
        'You are ready. Trust your preparation.',
        'Light movement only — save it for the cage',
        'Eat clean, sleep early, breathe deep',
        'Visualize victory. See yourself performing, not just winning.',
      ]);
    } else if (current.daysUntilFight > 0 && current.daysUntilFight <= 7) {
      actions.addAll([
        'Taper week — polish, don\'t build',
        'Mental rehearsal: game plan rounds 1, 2, 3',
        'Enjoy the process — you earned this camp',
      ]);
    } else {
      actions.addAll([
        'Green across the board. Outstanding.',
        'Push the session today — you have the reserves',
        'Bank extra sleep — it pays dividends later in camp',
      ]);
    }

    return CampGuidance(
      level: CampAdvisoryLevel.green,
      headline: 'Locked In',
      message:
          'Everything is tracking well. Your body and mind are aligned. '
          'This is what good camp feels like.',
      actions: actions,
      affirmations: [
        'Hard work is working. The numbers prove it.',
        'This is your time. Own it.',
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. TREND ANALYSIS — The Real Intelligence
  // ═══════════════════════════════════════════════════════════════════════════

  CampTrendAnalysis _analyzeTrend(List<DailyCheckIn> checkIns) {
    if (checkIns.isEmpty) {
      return const CampTrendAnalysis(
        avgMood: 0.5,
        avgSleep: 7,
        avgMotivation: 0.5,
        avgEnergy: 0.5,
        avgStress: 0.3,
        weightTrend: 0,
        sleepDebt: 0,
        consecutiveLowDays: 0,
        recurringConcerns: [],
        trendDirection: 'stable',
      );
    }

    final last7 = checkIns.take(7).toList();

    // Mood mapping: breaking=0.0, struggling=0.25, flat=0.5, steady=0.75, lockedIn=1.0
    double moodToScore(CampMood mood) {
      switch (mood) {
        case CampMood.breaking:
          return 0.0;
        case CampMood.struggling:
          return 0.25;
        case CampMood.flat:
          return 0.5;
        case CampMood.steady:
          return 0.75;
        case CampMood.lockedIn:
          return 1.0;
      }
    }

    final avgMood =
        last7.map((c) => moodToScore(c.mood)).reduce((a, b) => a + b) /
        last7.length;
    final avgSleep =
        last7.map((c) => c.sleepHours).reduce((a, b) => a + b) / last7.length;
    final avgMotivation =
        last7.map((c) => c.motivationScore).reduce((a, b) => a + b) /
        last7.length;
    final avgEnergy =
        last7.map((c) => c.energyLevel).reduce((a, b) => a + b) / last7.length;
    final avgStress =
        last7.map((c) => c.stressLevel).reduce((a, b) => a + b) / last7.length;

    // Weight trend (kg/day over last 7 entries)
    double weightTrend = 0;
    if (last7.length >= 2) {
      weightTrend =
          (last7.first.weight - last7.last.weight) / max(last7.length - 1, 1);
    }

    // Sleep debt (hours below 7 accumulated)
    double sleepDebt = 0;
    for (final c in last7) {
      if (c.sleepHours < 7) sleepDebt += (7 - c.sleepHours);
    }

    // Consecutive low days (mood <= flat OR motivation < 0.4)
    int consecutiveLow = 0;
    for (final c in last7) {
      if (moodToScore(c.mood) <= 0.5 || c.motivationScore < 0.4) {
        consecutiveLow++;
      } else {
        break;
      }
    }

    // Recurring concerns
    final concernCounts = <CampConcern, int>{};
    for (final c in last7) {
      for (final concern in c.concerns) {
        concernCounts[concern] = (concernCounts[concern] ?? 0) + 1;
      }
    }
    final recurring = concernCounts.entries
        .where((e) => e.value >= 3)
        .map((e) => e.key)
        .toList();

    // Trend direction
    String direction;
    final composite = (avgMood + avgMotivation + avgEnergy - avgStress) / 3;
    if (composite < 0.2) {
      direction = 'critical';
    } else if (composite < 0.4) {
      direction = 'declining';
    } else if (composite < 0.65) {
      direction = 'stable';
    } else {
      direction = 'improving';
    }

    return CampTrendAnalysis(
      avgMood: avgMood,
      avgSleep: avgSleep,
      avgMotivation: avgMotivation,
      avgEnergy: avgEnergy,
      avgStress: avgStress,
      weightTrend: weightTrend,
      sleepDebt: sleepDebt,
      consecutiveLowDays: consecutiveLow,
      recurringConcerns: recurring,
      trendDirection: direction,
    );
  }

  CampAdvisoryLevel _computeAdvisoryLevel(
    DailyCheckIn current,
    CampTrendAnalysis trend,
  ) {
    int score = 0;

    // Current state
    if (current.mood == CampMood.breaking) score += 5;
    if (current.mood == CampMood.struggling) score += 3;
    if (current.isChronicSleepDebt) score += 3;
    if (current.isSleepDeprived) score += 1;
    if (current.isCriticalWeight) score += 3;
    if (current.isHighStress) score += 2;
    if (current.isLowMotivation) score += 2;
    if (current.isInPain) score += 2;
    if (current.isHomesick) score += 1;
    if (current.mindset == FighterMindset.desperate) score += 3;

    // Trends
    if (trend.trendDirection == 'critical') score += 4;
    if (trend.trendDirection == 'declining') score += 2;
    if (trend.consecutiveLowDays >= 5) score += 3;
    if (trend.consecutiveLowDays >= 3) score += 1;
    if (trend.sleepDebt > 14) score += 2;

    if (score >= 10) return CampAdvisoryLevel.black;
    if (score >= 7) return CampAdvisoryLevel.red;
    if (score >= 4) return CampAdvisoryLevel.orange;
    if (score >= 2) return CampAdvisoryLevel.yellow;
    return CampAdvisoryLevel.green;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. PHASE-SPECIFIC COACHING INTELLIGENCE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get phase-aware training guidance
  List<String> getPhaseGuidance(int daysUntilFight) {
    if (daysUntilFight < 0) {
      return [
        'Recovery phase — gentle movement, real food, deep sleep',
        'Reflect on what went well. Even in loss, there are lessons.',
        'Reconnect with family and friends. You earned it.',
        'No training decisions for 48 hours. Let your body tell you when.',
      ];
    }

    if (daysUntilFight == 0) {
      return [
        'Today is the day. You are ready.',
        'Light warm-up only. Preserve everything for the cage.',
        'Trust your preparation. Trust your team. Trust yourself.',
        'Breathe. The hard work is done. Now you perform.',
      ];
    }

    if (daysUntilFight <= 3) {
      return [
        'Final taper. Technique shadow work only.',
        'Mental rehearsal: visualize rounds 1-3 in detail',
        'Dial in nutrition and hydration',
        'Early to bed. Sleep is your secret weapon.',
      ];
    }

    if (daysUntilFight <= 7) {
      return [
        'Fight week. No new techniques — polish what you have.',
        'Light sparring only if your coach approves',
        'Begin water load protocol if applicable',
        'Media obligations: stay calm, professional, controlled',
        'Game plan review with coach — commit to the A-plan',
      ];
    }

    if (daysUntilFight <= 14) {
      return [
        'Final hard sparring this week, then taper begins',
        'Weight check: you should be within 5% of target',
        'Sharpen combinations and entries',
        'Address any lingering injuries NOW with physio',
      ];
    }

    if (daysUntilFight <= 42) {
      return [
        'Peak camp. This is where the fight is won.',
        'Progressive sparring with game plan focus',
        'Strength training in power/speed phase',
        'Weight management: steady, no panic cuts',
        'Recovery is training. Treat it seriously.',
      ];
    }

    return [
      'Base building phase. Foundations matter.',
      'Build aerobic capacity — long, steady sessions',
      'Address technical weaknesses',
      'Strength training: hypertrophy and structural balance',
      'Sleep 8+ hours. Your body is adapting.',
    ];
  }

  /// Get motivation message based on fighter state
  String getMotivationMessage(DailyCheckIn checkIn) {
    if (checkIn.mood == CampMood.breaking) {
      return 'It is okay to not be okay. You are under immense pressure, '
          'and feeling this does not make you weak. Talk to someone you trust. '
          'The fight will still be there when you are ready.';
    }

    if (checkIn.isHomesick) {
      return 'Missing your family is not a distraction — it is proof that '
          'you are doing this for something bigger than yourself. '
          'Call them tonight. Their voices will remind you why.';
    }

    if (checkIn.mindset == FighterMindset.anxious) {
      return 'Anxiety before a fight is your body preparing, not failing. '
          'Every great fighter feels this. The difference is that great '
          'fighters channel it. Breathe. Focus on what you control.';
    }

    if (checkIn.isLowMotivation) {
      return 'Motivation is a wave — it comes and goes. '
          'Discipline is the anchor. You do not need to feel inspired. '
          'You need to show up. And you did, by checking in.';
    }

    if (checkIn.mood == CampMood.lockedIn) {
      return 'This is it. This is the zone. '
          'Do not question it, do not chase it. Just ride it. '
          'Your body and mind are aligned. Make the most of today.';
    }

    return 'Another day in camp. Another step forward. '
        'You are building something that cannot be taken from you: '
        'discipline, resilience, and the knowledge that you gave everything.';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. COMPANION MESSAGING — Contextual Responses
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate an intelligent response to a fighter's message
  String generateResponse(String userMessage, DailyCheckIn? lastCheckIn) {
    final msg = userMessage.toLowerCase();

    // ── Family / Homesick ──
    if (_containsAny(msg, [
      'miss',
      'family',
      'home',
      'kids',
      'wife',
      'husband',
      'partner',
      'lonely',
      'alone',
      'isolated',
    ])) {
      return 'Being away from the people you love is one of the hardest parts '
          'of camp. It is not weakness — it is human. Schedule a call tonight. '
          'Let them know how you are feeling. Their support is part of your corner.';
    }

    // ── Weight / Cut ──
    if (_containsAny(msg, [
      'weight',
      'cut',
      'heavy',
      'scale',
      'dehydrat',
      'sweat',
      'sauna',
      'water load',
    ])) {
      final weightContext = lastCheckIn != null && lastCheckIn.isOverweight
          ? ' You are ${lastCheckIn.weightDelta.toStringAsFixed(1)}kg over target. '
                'That is manageable with a disciplined approach.'
          : '';
      return 'Weight management is a science, not a punishment.$weightContext '
          'Small, consistent efforts beat heroic cuts every time. '
          'Stay hydrated, eat clean, trust the process. '
          'If you are struggling, talk to your nutritionist before making changes.';
    }

    // ── Pain / Injury ──
    if (_containsAny(msg, [
      'hurt',
      'pain',
      'injury',
      'sore',
      'tweak',
      'snap',
      'pull',
      'tear',
      'broken',
    ])) {
      return 'Pain is information, not an obstacle to push through. '
          'If something feels wrong, get it checked by a professional TODAY. '
          'Training through injury does not make you tough — it makes the injury worse. '
          'The smartest fighters protect their bodies.';
    }

    // ── Motivation / Doubt ──
    if (_containsAny(msg, [
      'quit',
      'give up',
      'can\'t',
      'doubt',
      'not ready',
      'why am i',
      'point',
      'worth it',
    ])) {
      return 'Doubt is a visitor in every fighter\'s camp. It does not live here. '
          'You are still standing. You are still training. That IS the answer. '
          'Remember: your opponent has these same doubts. '
          'The difference is what you do with them.';
    }

    // ── Sleep ──
    if (_containsAny(msg, [
      'sleep',
      'insomnia',
      'can\'t sleep',
      'tired',
      'exhausted',
      'fatigue',
      'wired',
    ])) {
      return 'Sleep is when your body actually builds what training tears down. '
          'If you cannot sleep: dim lights 1 hour before, no phones in bed, '
          'cool room (18-20°C), and try box breathing (4-4-4-4). '
          'If it persists more than 3 nights, talk to a professional.';
    }

    // ── Anxiety / Nerves ──
    if (_containsAny(msg, [
      'nervous',
      'anxi',
      'scared',
      'fear',
      'worry',
      'panic',
      'stress',
      'overwhelm',
    ])) {
      return 'Pre-fight nerves are your body loading the weapon. '
          'Every fighter who has ever competed has felt exactly what you feel. '
          'Channel it: breathe in for 4, hold for 4, out for 6. '
          'Focus on process, not outcome. One round at a time.';
    }

    // ── Default — Supportive ──
    return 'I hear you. Camp is a pressure cooker, and sometimes you just need '
        'to say what you are feeling. That takes courage. '
        'What would help most right now? '
        'I can talk about training, weight, recovery, or just listen.';
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  /// Stream check-in history for charts
  Stream<List<DailyCheckIn>> streamCheckIns(
    String fighterId, {
    int limit = 30,
  }) {
    return _firestore
        .collection('fight_camp_checkins')
        .where('fighterId', isEqualTo: fighterId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => DailyCheckIn.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

}
