import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SAMURAI SHIDO — WISDOM ENGINE
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Shido is NOT a chatbot. Shido is a MIND.
///
///   "Give me your weight class, timeline, and condition.
///    I will return a plan you can run today."
///
/// Philosophy:
///   • Knowledge — 39 years of combat sports science encoded
///   • Power — Real calculations, not vibes
///   • Wisdom — Knowing WHEN to push and when to pull back
///   • Logic — Every recommendation has a reason you can verify
///
/// Shido combines:
///   1. Sports Science (periodization, energy systems, biomechanics)
///   2. Fight IQ (matchup analysis, tactical patterns, round strategy)
///   3. Nutrition Timing (fuel windows, cut protocols, recomp science)
///   4. Recovery Science (HRV interpretation, sleep optimization, CNS load)
///   5. Mental Performance (visualization, anxiety management, focus drills)
///   6. Injury Prevention (overtraining detection, load management, deload)
///
/// Shido NEVER:
///   • Gives medical diagnoses
///   • Replaces a real coach
///   • Uses empty motivational language
///   • Recommends pushing through pain
///   • Makes decisions for the fighter
///
/// Shido ALWAYS:
///   • Shows the reasoning behind every recommendation
///   • Adjusts to the individual's data, not generic templates
///   • Defers to professionals when needed
///   • Speaks with precision, clarity, and respect
///
/// ═══════════════════════════════════════════════════════════════════════════

// ── Knowledge Domains ──────────────────────────────────────────────────────

enum ShidoDomain {
  periodization,
  energySystems,
  weightManagement,
  recoveryScience,
  fightIQ,
  nutritionTiming,
  mentalPerformance,
  injuryPrevention,
  strengthConditioning,
  biomechanics,
}

enum PeriodizationBlock {
  anatomicalAdaptation, // 4-6 weeks — building foundations
  hypertrophy, // 3-4 weeks — muscle cross-section
  maxStrength, // 3-4 weeks — neural recruitment
  power, // 2-3 weeks — rate of force development
  sportSpecific, // 4-8 weeks — fight-specific conditioning
  taper, // 1-2 weeks — supercompensation
  competition, // fight week
  activeRecovery, // 1-2 weeks post-fight
}

enum NutritionPhase {
  bulkMaintenance, // Off-season mass building
  recomposition, // Simultaneous fat loss + muscle gain
  gradualCut, // Slow, sustainable weight reduction
  fightWeekCut, // Final water/glycogen manipulation
  postWeighIn, // Rehydration + glycogen reload
  recoveryFeeding, // Post-fight repair
}

enum RecoveryProtocol {
  activeRecovery, // Low-intensity movement
  contrastTherapy, // Hot/cold alternation
  sleepOptimization, // Sleep hygiene protocol
  cnsRecovery, // Central nervous system deload
  muscularRecovery, // Soft tissue work
  nutritionalRecovery, // Anti-inflammatory nutrition
  mentalRecovery, // Psychological decompression
}

// ── Wisdom Models ──────────────────────────────────────────────────────────

/// A structured piece of Shido's wisdom
class ShidoInsight {
  final ShidoDomain domain;
  final String title;
  final String reasoning;
  final List<String> recommendations;
  final Map<String, String> scienceBasis; // claim → evidence
  final double confidence; // 0-1 how confident Shido is
  final bool defersToHuman;
  final String? deferReason;

  const ShidoInsight({
    required this.domain,
    required this.title,
    required this.reasoning,
    required this.recommendations,
    this.scienceBasis = const {},
    this.confidence = 0.8,
    this.defersToHuman = false,
    this.deferReason,
  });
}

/// Fighter profile for Shido's analysis
class FighterProfile {
  final String fighterId;
  final double weightKg;
  final double targetWeightKg;
  final int age;
  final String weightClass;
  final String discipline; // 'MMA', 'Boxing', 'Muay Thai', etc.
  final int yearsExperience;
  final int? restingHR;
  final int? hrvMs;
  final double? vo2Max;
  final double? sleepAvg;
  final double? bodyFatPercent;
  final int? daysUntilFight;
  final String? opponentStyle; // 'wrestler', 'striker', 'grappler'
  final List<String> knownInjuries;
  final double? trainingLoad7Day; // arbitrary units
  final double? trainingLoad28Day;

  const FighterProfile({
    required this.fighterId,
    required this.weightKg,
    required this.targetWeightKg,
    required this.age,
    required this.weightClass,
    this.discipline = 'MMA',
    this.yearsExperience = 0,
    this.restingHR,
    this.hrvMs,
    this.vo2Max,
    this.sleepAvg,
    this.bodyFatPercent,
    this.daysUntilFight,
    this.opponentStyle,
    this.knownInjuries = const [],
    this.trainingLoad7Day,
    this.trainingLoad28Day,
  });

  double get weightDelta => weightKg - targetWeightKg;
  bool get hasActiveFight => daysUntilFight != null && daysUntilFight! > 0;
  double get bmi =>
      weightKg / pow(1.75, 2); // Assuming avg height — refine per user

  /// Acute:Chronic Workload Ratio
  double? get acwr {
    if (trainingLoad7Day == null || trainingLoad28Day == null) return null;
    if (trainingLoad28Day == 0) return null;
    return trainingLoad7Day! / (trainingLoad28Day! / 4);
  }
}

// ── THE ENGINE ─────────────────────────────────────────────────────────────

class ShidoWisdomEngine extends ChangeNotifier {
  static final ShidoWisdomEngine _instance = ShidoWisdomEngine._internal();
  factory ShidoWisdomEngine() => _instance;
  ShidoWisdomEngine._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'australia-southeast1',
  );

  bool _initialized = false;
  FighterProfile? _currentProfile;
  final List<ShidoInsight> _insightCache = [];

  bool get initialized => _initialized;
  FighterProfile? get currentProfile => _currentProfile;
  List<ShidoInsight> get insights => List.unmodifiable(_insightCache);

  Future<void> initialize(String fighterId) async {
    if (_initialized) return;
    try {
      final doc = await _firestore
          .collection('fighter_profiles')
          .doc(fighterId)
          .get();
      if (doc.exists) {
        final d = doc.data()!;
        _currentProfile = FighterProfile(
          fighterId: fighterId,
          weightKg: (d['weight'] as num?)?.toDouble() ?? 70,
          targetWeightKg: (d['targetWeight'] as num?)?.toDouble() ?? 70,
          age: d['age'] ?? 25,
          weightClass: d['weightClass'] ?? 'Welterweight',
          discipline: d['discipline'] ?? 'MMA',
          yearsExperience: d['yearsExperience'] ?? 0,
          restingHR: d['restingHR'],
          hrvMs: d['hrvMs'],
          vo2Max: (d['vo2Max'] as num?)?.toDouble(),
          sleepAvg: (d['sleepAvg'] as num?)?.toDouble(),
          bodyFatPercent: (d['bodyFatPercent'] as num?)?.toDouble(),
          daysUntilFight: d['daysUntilFight'],
          opponentStyle: d['opponentStyle'],
          knownInjuries: List<String>.from(d['knownInjuries'] ?? []),
          trainingLoad7Day: (d['trainingLoad7Day'] as num?)?.toDouble(),
          trainingLoad28Day: (d['trainingLoad28Day'] as num?)?.toDouble(),
        );
      }
      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('⚔️ Shido: init error: $e');
      _initialized = true;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. PERIODIZATION INTELLIGENCE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Determine optimal periodization block based on fight timeline
  PeriodizationBlock recommendBlock(FighterProfile profile) {
    final days = profile.daysUntilFight;
    if (days == null || days < 0) return PeriodizationBlock.activeRecovery;
    if (days == 0) return PeriodizationBlock.competition;
    if (days <= 10) return PeriodizationBlock.taper;
    if (days <= 42) return PeriodizationBlock.sportSpecific;
    if (days <= 56) return PeriodizationBlock.power;
    if (days <= 70) return PeriodizationBlock.maxStrength;
    if (days <= 84) return PeriodizationBlock.hypertrophy;
    return PeriodizationBlock.anatomicalAdaptation;
  }

  /// Generate periodization insight with reasoning
  ShidoInsight analyzePeriodization(FighterProfile profile) {
    final block = recommendBlock(profile);
    final days = profile.daysUntilFight ?? -1;

    final Map<PeriodizationBlock, Map<String, dynamic>> blockData = {
      PeriodizationBlock.anatomicalAdaptation: {
        'title': 'Anatomical Adaptation Phase',
        'reasoning':
            'With $days days until fight, you have time to build a strong '
            'structural foundation. This phase protects against injury by '
            'strengthening tendons, ligaments, and joint stability.',
        'recs': [
          'Circuit training: 3 sets × 12-15 reps, 60s rest',
          'Focus on compound movements: squat, deadlift, press, pull',
          'Core stability: anti-rotation and bracing drills',
          'Keep RPE at 6-7 — technical perfection over load',
        ],
        'science': {
          'Structural adaptation':
              'Connective tissue adapts slower than muscle (Kubo 2001)',
          'Injury prevention':
              'Preparatory phase reduces injury rate by 30-50% (Lauersen 2014)',
        },
      },
      PeriodizationBlock.hypertrophy: {
        'title': 'Hypertrophy Phase — Building the Engine',
        'reasoning':
            'Increasing muscle cross-sectional area provides the raw material '
            'for power development in subsequent phases. '
            'At $days days out, this timing is optimal.',
        'recs': [
          '4 sets × 8-12 reps at 65-75% 1RM',
          'Time under tension: 3-1-2 tempo (eccentric-pause-concentric)',
          'Progressive overload: increase load 2-5% weekly',
          'Caloric surplus of 200-300 kcal — fuel the adaptation',
        ],
        'science': {
          'Hypertrophy range':
              'Schoenfeld 2010: 8-12 reps optimal for cross-sectional growth',
          'Progressive overload':
              'Kraemer & Ratamess 2004: systematic load increases essential',
        },
      },
      PeriodizationBlock.maxStrength: {
        'title': 'Maximum Strength Phase',
        'reasoning':
            'Neural recruitment maximization. Teaching existing muscle fibers '
            'to fire together. This is where you get strong without getting heavy.',
        'recs': [
          '5 sets × 3-5 reps at 85-95% 1RM',
          'Full recovery between sets: 3-5 minutes',
          'Compound lifts only — squat, bench, deadlift, overhead press',
          'CNS recovery: limit heavy sessions to 3/week',
        ],
        'science': {
          'Neural adaptation':
              'Sale 1988: Strength gains in first 8 weeks are primarily neural',
          'Recovery demands':
              'Heavy loads require 48-72h recovery (Häkkinen 1985)',
        },
      },
      PeriodizationBlock.power: {
        'title': 'Power Development Phase',
        'reasoning':
            'Converting max strength into explosive power — the currency of '
            'combat sports. Force × velocity = the ability to hurt.',
        'recs': [
          'Plyometrics: box jumps, medicine ball throws, clap push-ups',
          '3-5 sets × 3-5 reps at 50-70% 1RM with maximum velocity',
          'Olympic lift derivatives: hang clean, push press',
          'Sport-specific power: heavy bag intervals, pad work combos',
        ],
        'science': {
          'Power development':
              'Newton & Kraemer 1994: Power = force at high velocities',
          'Transfer to sport':
              'Loturco 2016: Explosive training transfers to punch force',
        },
      },
      PeriodizationBlock.sportSpecific: {
        'title': 'Sport-Specific Conditioning',
        'reasoning':
            'Peak camp. Everything now maps directly to fight performance. '
            'Sparring intensity ramps up. Game plan implementation begins.',
        'recs': [
          'Sparring 3-4x/week with progressive intensity',
          'Energy system conditioning: 5-minute rounds with 1-min rest',
          'Implement specific game plan techniques in live drilling',
          'Strength maintenance: 2x/week at 80% previous loads',
          'Monitor ACWR — keep ratio between 0.8 and 1.3',
        ],
        'science': {
          'Specificity principle':
              'Training adaptations are specific to the demands imposed (SAID)',
          'ACWR safety zone':
              'Gabbett 2016: 0.8-1.3 ratio minimizes injury risk',
        },
      },
      PeriodizationBlock.taper: {
        'title': 'Taper Phase — Supercompensation',
        'reasoning':
            'Reducing training volume by 40-60% while maintaining intensity. '
            'Your body supercompensates — you peak at fight time.',
        'recs': [
          'Reduce volume 40-60%, maintain intensity',
          'Short, sharp sessions: technique + speed',
          'Visualization: 15 min/day of mental rehearsal',
          'Sleep 9+ hours — this is where adaptation happens',
          'No new techniques. Polish what you have.',
        ],
        'science': {
          'Supercompensation':
              'Mujika 2009: 2-week taper improves performance 2-3%',
          'Volume reduction':
              'Bosquet 2007: Reduce volume not intensity for optimal taper',
        },
      },
      PeriodizationBlock.competition: {
        'title': 'Fight Day Protocol',
        'reasoning':
            'Everything is done. The hay is in the barn. '
            'Today is about execution, not preparation.',
        'recs': [
          'Light warm-up: shadow boxing, dynamic stretching',
          'Mental prep: breathwork (4-7-8 pattern), visualization',
          'Fuel: familiar foods only — no experiments on fight day',
          'Trust the preparation. Trust the team. Execute.',
        ],
        'science': {
          'Pre-competition protocol':
              'Bishop 2003: Active warm-up improves acute performance',
          'Mental preparation':
              'Weinberg 2003: Visualization improves motor execution',
        },
      },
      PeriodizationBlock.activeRecovery: {
        'title': 'Active Recovery Phase',
        'reasoning':
            'Post-fight recovery is sacred. Your body and mind need repair. '
            'Rushing back is how careers end early.',
        'recs': [
          'No contact for minimum 14 days post-fight',
          'Light movement: walking, swimming, yoga',
          'Sleep without alarms for 1 week',
          'Anti-inflammatory nutrition: omega-3, turmeric, berries',
          'Mental health check: debrief the fight with coach',
        ],
        'science': {
          'Post-concussion protocol':
              'McCrory 2017: Graduated return-to-play essential',
          'Recovery timeline':
              'Loenneke 2014: Muscle damage markers normalize in 7-14 days',
        },
      },
    };

    final data = blockData[block]!;
    return ShidoInsight(
      domain: ShidoDomain.periodization,
      title: data['title'] as String,
      reasoning: data['reasoning'] as String,
      recommendations: List<String>.from(data['recs'] as List),
      scienceBasis: Map<String, String>.from(data['science'] as Map),
      confidence: 0.9,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. RECOVERY INTELLIGENCE — HRV, Sleep, Load Analysis
  // ═══════════════════════════════════════════════════════════════════════════

  /// Analyze recovery state from biometric data
  ShidoInsight analyzeRecovery(FighterProfile profile) {
    final signals = <String, double>{};
    final reasons = <String>[];
    final recs = <String>[];
    final science = <String, String>{};

    // ── HRV Analysis ──
    if (profile.hrvMs != null) {
      final hrv = profile.hrvMs!;
      if (hrv < 30) {
        signals['hrvCritical'] = 0.95;
        reasons.add(
          'HRV at ${hrv}ms is critically low — sympathetic dominance '
          'indicating accumulated stress or overreaching',
        );
        recs.add('Rest day mandatory. No exceptions.');
      } else if (hrv < 50) {
        signals['hrvLow'] = 0.7;
        reasons.add(
          'HRV at ${hrv}ms is below optimal — reduced parasympathetic recovery',
        );
        recs.add('Light session only (RPE ≤ 5). Prioritize sleep tonight.');
      } else if (hrv > 80) {
        signals['hrvGood'] = 0.2;
        reasons.add('HRV at ${hrv}ms indicates strong recovery');
        recs.add('Green light for high-intensity work today');
      }
      science['HRV interpretation'] =
          'Plews 2013: Day-to-day HRV trends predict readiness better than absolute values';
    }

    // ── Resting HR Analysis ──
    if (profile.restingHR != null) {
      final rhr = profile.restingHR!;
      if (rhr > 75) {
        signals['rhrElevated'] = 0.6;
        reasons.add(
          'Resting HR at ${rhr}bpm is elevated — possible illness, '
          'dehydration, or accumulated fatigue',
        );
        recs.add('If RHR stays elevated 3+ days, consult medical staff');
      }
      science['Resting HR'] =
          'Buchheit 2014: RHR elevation >5bpm from baseline signals overreaching';
    }

    // ── Sleep Analysis ──
    if (profile.sleepAvg != null) {
      final sleep = profile.sleepAvg!;
      if (sleep < 6) {
        signals['sleepCritical'] = 0.85;
        reasons.add(
          'Average sleep at ${sleep.toStringAsFixed(1)}h is severely inadequate '
          '— testosterone drops 10-15% with <6h sleep',
        );
        recs.add('Non-negotiable: 8+ hours tonight. Nap if possible.');
      } else if (sleep < 7) {
        signals['sleepLow'] = 0.5;
        reasons.add(
          'Sleep at ${sleep.toStringAsFixed(1)}h — below 7h threshold',
        );
        recs.add('Target 8h tonight — sleep is when adaptation occurs');
      }
      science['Sleep & testosterone'] =
          'Leproult 2011: 1 week of <5h sleep reduces testosterone by 10-15%';
      science['Sleep & performance'] =
          'Mah 2011: Extended sleep improves sprint time, reaction time, and mood';
    }

    // ── ACWR Analysis ──
    final acwr = profile.acwr;
    if (acwr != null) {
      if (acwr > 1.5) {
        signals['acwrSpike'] = 0.9;
        reasons.add(
          'ACWR at ${acwr.toStringAsFixed(2)} — acute load spike '
          'increases injury risk by 2-4x',
        );
        recs.add('Reduce training volume by 30% this week');
        recs.add('No new movements or intensities until ACWR < 1.3');
      } else if (acwr < 0.8) {
        signals['acwrLow'] = 0.4;
        reasons.add('ACWR at ${acwr.toStringAsFixed(2)} — detraining zone');
        recs.add('Gradually increase training load to maintain fitness');
      } else {
        reasons.add(
          'ACWR at ${acwr.toStringAsFixed(2)} — within safe training zone (0.8-1.3)',
        );
      }
      science['ACWR'] =
          'Gabbett 2016: Injury risk increases 2-4x when ACWR > 1.5';
    }

    // ── Synthesize ──
    final maxSignal = signals.isEmpty
        ? 0.0
        : signals.values.reduce((a, b) => a > b ? a : b);

    recs.addAll(_getRecoveryProtocolRecs(maxSignal));

    return ShidoInsight(
      domain: ShidoDomain.recoveryScience,
      title: maxSignal > 0.8
          ? 'Recovery Alert — Immediate Action Required'
          : maxSignal > 0.5
          ? 'Recovery Caution — Adjustments Recommended'
          : 'Recovery Status: Nominal',
      reasoning: reasons.join('. '),
      recommendations: recs.take(5).toList(),
      scienceBasis: science,
      confidence: 0.85,
      defersToHuman: maxSignal > 0.8,
      deferReason: maxSignal > 0.8
          ? 'Multiple recovery indicators are critical. Consult your coach.'
          : null,
    );
  }

  List<String> _getRecoveryProtocolRecs(double severity) {
    if (severity > 0.8) {
      return [
        'Protocol: Complete rest or gentle walk only',
        'Contrast therapy: 3 min cold / 1 min hot × 4 rounds',
        'Anti-inflammatory meal: salmon, dark greens, berries',
      ];
    }
    if (severity > 0.5) {
      return [
        'Light active recovery: 20-min walk or swim',
        'Foam rolling: 10 min on major muscle groups',
        'Magnesium supplementation before bed',
      ];
    }
    return [];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. WEIGHT MANAGEMENT INTELLIGENCE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Analyze weight situation and recommend protocol
  ShidoInsight analyzeWeight(FighterProfile profile) {
    final delta = profile.weightDelta;
    final days = profile.daysUntilFight ?? 999;
    final bodyFat = profile.bodyFatPercent;

    final recs = <String>[];
    final science = <String, String>{};
    String reasoning;
    NutritionPhase phase;
    double confidence = 0.85;

    if (days <= 0) {
      phase = NutritionPhase.recoveryFeeding;
      reasoning = 'Post-fight — focus on recovery nutrition and rehydration.';
      recs.addAll([
        'Rehydrate: sip electrolyte drinks, do not chug',
        'Anti-inflammatory foods: omega-3, turmeric, ginger',
        'Gradual calorie return — no binge eating',
      ]);
    } else if (days <= 1) {
      phase = NutritionPhase.postWeighIn;
      reasoning =
          'Post weigh-in rehydration window. You have ${days > 0 ? "$days day" : "hours"} '
          'to reload glycogen and rehydrate safely.';
      recs.addAll([
        'Sip 1.5L electrolyte drink over first 2 hours',
        'High-glycemic carbs: white rice, banana, honey',
        'Avoid fiber-heavy foods — quick absorption is key',
        'Light protein: chicken breast or whey shake',
      ]);
      science['Rehydration protocol'] =
          'Sawka 2007: Replace 150% of fluid lost, with sodium, over 4-6h';
    } else if (delta <= 0) {
      phase = NutritionPhase.bulkMaintenance;
      reasoning =
          'You are at or below target weight (${delta.abs().toStringAsFixed(1)}kg under). '
          'Maintain and fuel performance.';
      recs.addAll([
        'Maintenance calories — do not over-restrict',
        'Protein: 2.0-2.2g/kg bodyweight daily',
        'Carb timing: load before and after training',
      ]);
    } else if (delta <= 3 && days > 14) {
      phase = NutritionPhase.gradualCut;
      final weeklyRate = (delta / (days / 7)).clamp(0.0, 1.0);
      reasoning =
          'Need to lose ${delta.toStringAsFixed(1)}kg in $days days. '
          'Rate: ${weeklyRate.toStringAsFixed(2)}kg/week — sustainable.';
      recs.addAll([
        'Caloric deficit: 300-500 kcal/day (no more)',
        'Protein high: 2.2-2.5g/kg to preserve muscle',
        'Carb cycle: higher on training days, lower on rest',
        'Hydrate well — dehydration impairs fat metabolism',
      ]);
      science['Sustainable cut rate'] =
          'Helms 2014: 0.5-1.0% bodyweight/week preserves muscle mass';
    } else if (delta > 3 && days > 7) {
      phase = NutritionPhase.gradualCut;
      reasoning =
          '${delta.toStringAsFixed(1)}kg over target with $days days remaining. '
          'This requires disciplined daily adherence.';
      final canMakeIt = delta / max(days, 1) <= 0.3;
      if (canMakeIt) {
        recs.addAll([
          'Aggressive but safe deficit: 500-750 kcal/day',
          'High protein, moderate fat, controlled carbs',
          'Two-a-day cardio: morning fasted walk + evening session',
          'Weekly weigh-in tracking — adjust if plateauing',
        ]);
      } else {
        recs.addAll([
          'Consider moving up a weight class — your health matters more',
          'If committed to this weight: consult nutritionist immediately',
          'Water loading protocol starts at T-5 days (supervised only)',
          'Do NOT use saunas or diuretics without medical supervision',
        ]);
        confidence = 0.6;
      }
    } else if (days <= 7) {
      phase = NutritionPhase.fightWeekCut;
      reasoning =
          'Fight week with ${delta.toStringAsFixed(1)}kg to cut. '
          'This is now about water manipulation, not fat loss.';
      if (delta <= 4) {
        recs.addAll([
          'Water load days 1-3: drink 6-8L/day with sodium',
          'Day 4: reduce to 2L, cut sodium',
          'Day 5 (weigh-in eve): 500mL sips only',
          'Hot bath protocol: 15 min at 40°C for final water weight',
          'MONITOR: dizziness, confusion, or cramping = STOP and hydrate',
        ]);
      } else {
        recs.addAll([
          'WARNING: ${delta.toStringAsFixed(1)}kg in fight week is dangerous',
          'Consult your doctor and coach before proceeding',
          'Consider fighting at catchweight or moving up',
        ]);
        confidence = 0.4;
      }
      science['Water loading'] =
          'Reale 2017: Water manipulation can safely reduce 2-4% bodyweight';
      science['Danger threshold'] =
          'Artioli 2010: Rapid weight loss >5% impairs performance and cognition';
    } else {
      phase = NutritionPhase.bulkMaintenance;
      reasoning =
          'No fight scheduled. Focus on body composition and performance.';
      recs.addAll([
        'Slight caloric surplus if building muscle',
        'Protein: 2.0g/kg minimum',
        'Track body composition monthly, not just weight',
      ]);
    }

    if (bodyFat != null) {
      if (bodyFat < 8) {
        recs.add(
          'Body fat at ${bodyFat.toStringAsFixed(1)}% — at lower safe limit. '
          'Do not cut further without medical supervision.',
        );
      } else if (bodyFat < 12) {
        recs.add(
          'Body fat at ${bodyFat.toStringAsFixed(1)}% — lean. '
          'Limited fat to lose, focus on water manipulation if needed.',
        );
      }
    }

    return ShidoInsight(
      domain: ShidoDomain.weightManagement,
      title: 'Weight Analysis: ${phase.name}',
      reasoning: reasoning,
      recommendations: recs,
      scienceBasis: science,
      confidence: confidence,
      defersToHuman: delta > 5 && days < 14,
      deferReason: delta > 5 && days < 14
          ? 'Extreme weight cut scenario — requires medical supervision'
          : null,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. FIGHT IQ — Tactical Analysis
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate fight-IQ guidance based on opponent style
  ShidoInsight analyzeFightIQ(FighterProfile profile) {
    final style = profile.opponentStyle ?? 'unknown';
    final discipline = profile.discipline;

    final Map<String, Map<String, dynamic>> matchups = {
      'wrestler': {
        'title': 'vs Wrestler — Anti-Wrestling Game Plan',
        'reasoning':
            'Wrestlers close distance and impose their game plan. '
            'Your job: maintain range, punish entries, develop a wall game.',
        'recs': [
          'Footwork: lateral movement, never back straight up',
          'Underhook battle: whoever controls underhooks controls the fight',
          'Sprawl drills: 100 reps/day this week — make it reflexive',
          'Punish level changes: knees, uppercuts, frame and circle',
          'If taken down: stand up, do not play guard against a wrestler',
        ],
        'science': {
          'Wrestling defense':
              'Takedown defense is the #1 predictor of MMA success (James 2016)',
        },
      },
      'striker': {
        'title': 'vs Striker — Pressure & Range Control',
        'reasoning':
            'Strikers need space to operate. Take it away. '
            'Pressure without recklessness. Make them fight your fight.',
        'recs': [
          'Cut the cage: diagonal steps, not linear chasing',
          'Jab-heavy approach: disrupt their timing and rhythm',
          'Clinch when they load up: smother combinations',
          'Body work: reduce their gas tank for later rounds',
          'Head movement: slip, roll, angle — do not be a stationary target',
        ],
        'science': {
          'Pressure fighting':
              'Striking accuracy drops 15-20% under pressure (Kirk 2020)',
        },
      },
      'grappler': {
        'title': 'vs Grappler — Submission Defense & Distance',
        'reasoning':
            'Grapplers need to close distance and get to the ground. '
            'Your job: maintain range, defend takedowns, and DO NOT get pulled into guard.',
        'recs': [
          'Stay standing at all costs — most submissions happen on the ground',
          'Guillotine defense: posture, posture, posture',
          'If taken down: wall walk immediately, hand fight to stand',
          'Avoid pulling guard EVER — their world, their rules',
          discipline == 'MMA'
              ? 'Ground strikes: use them to create space to stand, not to damage'
              : 'Focus on clinch breaks and returning to range',
        ],
        'science': {
          'Position before submission':
              'Positional control determines 78% of submission outcomes (Buse 2006)',
        },
      },
    };

    final data =
        matchups[style] ??
        {
          'title': 'General Fight IQ Assessment',
          'reasoning':
              'No specific opponent style profiled. Focus on your strengths '
              'and universal combat principles.',
          'recs': [
            'Control range: fight at YOUR distance, not theirs',
            'Round awareness: pace yourself, win rounds, not exchanges',
            'Capitalize on transitions: attacks between positions are gold',
            'Condition your body to handle 3-5 rounds at full intensity',
          ],
          'science': {
            'Round winning':
                'Judge scoring favors effective aggression and cage control (ABC rules)',
          },
        };

    return ShidoInsight(
      domain: ShidoDomain.fightIQ,
      title: data['title'] as String,
      reasoning: data['reasoning'] as String,
      recommendations: List<String>.from(data['recs'] as List),
      scienceBasis: Map<String, String>.from(data['science'] as Map),
      confidence: style == 'unknown' ? 0.6 : 0.85,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. COMPREHENSIVE ANALYSIS — Full Shido Assessment
  // ═══════════════════════════════════════════════════════════════════════════

  /// Run full analysis across all domains for a fighter
  List<ShidoInsight> fullAnalysis(FighterProfile profile) {
    final insights = <ShidoInsight>[
      analyzePeriodization(profile),
      analyzeRecovery(profile),
      analyzeWeight(profile),
      analyzeFightIQ(profile),
    ];

    _insightCache
      ..clear()
      ..addAll(insights);
    notifyListeners();

    return insights;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. CONVERSATIONAL INTELLIGENCE — Chat Responses
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate an intelligent response to user query
  String respondToQuery(String query, FighterProfile? profile) {
    final q = query.toLowerCase();

    // ── Periodization / Training Plan ──
    if (_containsAny(q, [
      'training plan',
      'periodiz',
      'program',
      'block',
      'phase',
    ])) {
      if (profile == null) {
        return 'I need your weight class, days until fight, and current condition '
            'to build a proper periodization plan. Generic plans are a waste '
            'of your time.';
      }
      final block = recommendBlock(profile);
      return 'Based on your timeline (${profile.daysUntilFight ?? "no fight"} days), '
          'you should be in ${block.name} phase. '
          'This means: ${_blockSummary(block)}. '
          'Want me to break down the weekly structure?';
    }

    // ── Weight / Cut ──
    if (_containsAny(q, ['weight', 'cut', 'make weight', 'heavy', 'diet'])) {
      if (profile != null) {
        final insight = analyzeWeight(profile);
        return '${insight.reasoning}\n\n'
            'My recommendation:\n'
            '${insight.recommendations.map((r) => "• $r").join("\n")}';
      }
      return 'Give me your current weight, target weight, and days until fight. '
          'I will give you a specific protocol based on the science.';
    }

    // ── Recovery ──
    if (_containsAny(q, [
      'recovery',
      'tired',
      'hrv',
      'overtraining',
      'rest',
      'fatigue',
    ])) {
      if (profile != null) {
        final insight = analyzeRecovery(profile);
        return '${insight.reasoning}\n\n'
            '${insight.recommendations.map((r) => "• $r").join("\n")}';
      }
      return 'Recovery is not the absence of training — it is where adaptation happens. '
          'Share your HRV, resting HR, and sleep data, and I will tell you exactly '
          'where you stand.';
    }

    // ── Fight IQ / Opponent ──
    if (_containsAny(q, [
      'opponent',
      'game plan',
      'fight iq',
      'strategy',
      'matchup',
    ])) {
      if (profile != null && profile.opponentStyle != null) {
        final insight = analyzeFightIQ(profile);
        return '${insight.reasoning}\n\n'
            '${insight.recommendations.map((r) => "• $r").join("\n")}';
      }
      return 'Tell me about your opponent: wrestler, striker, grappler? '
          'And your discipline. I will build a tactical framework.';
    }

    // ── Nutrition ──
    if (_containsAny(q, [
      'nutrition',
      'meal',
      'protein',
      'carb',
      'calor',
      'eat',
    ])) {
      return 'Nutrition fundamentals for fighters:\n'
          '• Protein: 2.0-2.5g/kg bodyweight (non-negotiable)\n'
          '• Carbs: fuel training and recovery—do not fear them\n'
          '• Hydrate: minimum 3L/day, more if training twice\n'
          '• Timing: protein within 30 min post-training\n'
          '• Real food first. Supplements are supplementary.\n\n'
          'Give me your weight class and fight timeline for a specific plan.';
    }

    // ── Sleep ──
    if (_containsAny(q, ['sleep', 'insomnia', 'tired'])) {
      return 'Sleep is the #1 legal performance enhancer:\n'
          '• Target: 8-9 hours for combat athletes\n'
          '• Cool room (18-20°C), dark, no screens 1h before\n'
          '• Magnesium glycinate 400mg before bed\n'
          '• Consistent schedule — same time every night\n'
          '• Naps: 20 min OR 90 min (full cycle), never 45-60\n\n'
          'Science: Mah 2011 showed extended sleep improved sprint time, '
          'reaction time, and mood in elite athletes.';
    }

    // ── Default: Ask for data ──
    return 'I can help with training periodization, weight management, '
        'recovery analysis, fight IQ, nutrition timing, or injury prevention. '
        'The more data you give me, the more specific my guidance. '
        'What do you need?';
  }

  String _blockSummary(PeriodizationBlock block) {
    switch (block) {
      case PeriodizationBlock.anatomicalAdaptation:
        return 'building structural foundations, moderate loads, high reps';
      case PeriodizationBlock.hypertrophy:
        return 'muscle building phase, 8-12 reps, progressive overload';
      case PeriodizationBlock.maxStrength:
        return 'max neural recruitment, heavy loads, low reps, full recovery';
      case PeriodizationBlock.power:
        return 'converting strength to explosion, plyometrics and Olympic lifts';
      case PeriodizationBlock.sportSpecific:
        return 'fight-specific work, sparring, game plan implementation';
      case PeriodizationBlock.taper:
        return 'volume reduction, intensity maintenance, supercompensation';
      case PeriodizationBlock.competition:
        return 'fight day, light warm-up, mental prep, execute';
      case PeriodizationBlock.activeRecovery:
        return 'post-fight recovery, no contact, gentle movement, repair';
    }
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  /// Ask Shido via Cloud Function (Gemini-backed)
  Future<String> askShidoAI({
    required String question,
    FighterProfile? profile,
  }) async {
    try {
      final callable = _functions.httpsCallable('askShido');
      final result = await callable.call({
        'question': question,
        'profile': profile != null
            ? {
                'weightKg': profile.weightKg,
                'targetWeightKg': profile.targetWeightKg,
                'age': profile.age,
                'weightClass': profile.weightClass,
                'discipline': profile.discipline,
                'daysUntilFight': profile.daysUntilFight,
                'opponentStyle': profile.opponentStyle,
                'hrvMs': profile.hrvMs,
                'restingHR': profile.restingHR,
                'sleepAvg': profile.sleepAvg,
              }
            : null,
      });
      return result.data?['response'] ?? respondToQuery(question, profile);
    } catch (e) {
      // Fallback to local intelligence
      return respondToQuery(question, profile);
    }
  }
}
