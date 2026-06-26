import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC FIGHTER CAREER ENGINE — #115
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Long-term career planning and trajectory modeling for fighters.
///
/// Features:
///   • Career phase identification (prospect, contender, champion, veteran)
///   • Skill development roadmaps
///   • Fight booking recommendations (who to fight next, and when)
///   • Trajectory prediction (peak years, decline, retirement window)
///   • AI career advisor (camp suggestions, style changes, weight class)
///
/// Firestore Collections:
///   fighter_careers/{fighterId}             — Career plans
///   fighter_careers/{fighterId}/milestones  — Career milestones
///
/// ═══════════════════════════════════════════════════════════════════════════

enum CareerPhase {
  prospect,
  rising,
  contender,
  gatekeeper,
  champion,
  veteran,
  retired,
}

class CareerProfile {
  final String fighterId;
  final String name;
  final CareerPhase phase;
  final int proFights;
  final int wins;
  final int losses;
  final int draws;
  final int age;
  final String currentWeightClass;
  final List<String> styleTags; // e.g. 'pressure fighter', 'counter striker'
  final int yearsActive;
  final DateTime? proDebutDate;

  const CareerProfile({
    required this.fighterId,
    required this.name,
    required this.phase,
    required this.proFights,
    required this.wins,
    required this.losses,
    this.draws = 0,
    required this.age,
    required this.currentWeightClass,
    this.styleTags = const [],
    required this.yearsActive,
    this.proDebutDate,
  });

  double get winRate => proFights > 0 ? wins / proFights : 0;
}

class CareerMilestone {
  final String id;
  final String description;
  final bool achieved;
  final DateTime? achievedDate;
  final DateTime? targetDate;

  const CareerMilestone({
    required this.id,
    required this.description,
    this.achieved = false,
    this.achievedDate,
    this.targetDate,
  });
}

class CareerRecommendation {
  final String fighterId;
  final CareerPhase currentPhase;
  final CareerPhase projectedPeakPhase;
  final int estimatedPeakAge;
  final int estimatedRetirementAge;
  final String nextFightRecommendation;
  final String? weightClassAdvice;
  final String? styleAdvice;
  final List<String> skillDevelopmentPriorities;
  final List<CareerMilestone> upcomingMilestones;
  final double careerHealthScore; // 0.0 – 1.0
  final DateTime assessedAt;

  const CareerRecommendation({
    required this.fighterId,
    required this.currentPhase,
    required this.projectedPeakPhase,
    required this.estimatedPeakAge,
    required this.estimatedRetirementAge,
    required this.nextFightRecommendation,
    this.weightClassAdvice,
    this.styleAdvice,
    required this.skillDevelopmentPriorities,
    required this.upcomingMilestones,
    required this.careerHealthScore,
    required this.assessedAt,
  });
}

class FighterCareerEngineService extends ChangeNotifier {
  static final FighterCareerEngineService _instance =
      FighterCareerEngineService._internal();
  factory FighterCareerEngineService() => _instance;
  FighterCareerEngineService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _initialized = false;

  final Map<String, CareerProfile> _profiles = {};
  int _totalAssessments = 0;

  // ── Getters ──
  bool get initialized => _initialized;
  int get totalAssessments => _totalAssessments;
  CareerProfile? profileFor(String fighterId) => _profiles[fighterId];

  // ── Lifecycle ──

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    debugPrint('[CareerEngine] Online — trajectory modeling active');
    notifyListeners();
  }

  // ── Career Assessment ──

  CareerRecommendation assessCareer(CareerProfile profile) {
    _totalAssessments++;
    _profiles[profile.fighterId] = profile;

    final phase = _identifyPhase(profile);
    final peakAge = _estimatePeakAge(profile);
    final retirementAge = _estimateRetirementAge(profile);
    final nextFight = _recommendNextFight(profile, phase);
    final weightAdvice = _weightClassAdvice(profile);
    final styleAdvice = _styleAdvice(profile, phase);
    final skillPriorities = _skillPriorities(profile, phase);
    final milestones = _generateMilestones(profile, phase);
    final healthScore = _careerHealthScore(profile, phase);

    final recommendation = CareerRecommendation(
      fighterId: profile.fighterId,
      currentPhase: phase,
      projectedPeakPhase: phase == CareerPhase.champion
          ? CareerPhase.champion
          : CareerPhase.contender,
      estimatedPeakAge: peakAge,
      estimatedRetirementAge: retirementAge,
      nextFightRecommendation: nextFight,
      weightClassAdvice: weightAdvice,
      styleAdvice: styleAdvice,
      skillDevelopmentPriorities: skillPriorities,
      upcomingMilestones: milestones,
      careerHealthScore: healthScore,
      assessedAt: DateTime.now(),
    );

    _persist(recommendation);

    debugPrint(
      '[CareerEngine] ${profile.name}: phase=$phase, '
      'peak age=$peakAge, health=${(healthScore * 100).toStringAsFixed(0)}%',
    );
    notifyListeners();
    return recommendation;
  }

  // ── Internal AI Logic ──

  CareerPhase _identifyPhase(CareerProfile p) {
    if (p.proFights == 0) return CareerPhase.prospect;
    if (p.proFights <= 5 && p.winRate >= 0.6) return CareerPhase.rising;
    if (p.proFights <= 5 && p.winRate < 0.6) return CareerPhase.prospect;
    if (p.phase == CareerPhase.champion) return CareerPhase.champion;
    if (p.proFights >= 20 && p.age >= 35) return CareerPhase.veteran;
    if (p.proFights >= 15 && p.winRate < 0.5) return CareerPhase.gatekeeper;
    if (p.winRate >= 0.7 && p.proFights >= 8) return CareerPhase.contender;
    return CareerPhase.rising;
  }

  int _estimatePeakAge(CareerProfile p) {
    // MMA fighters typically peak 28–33.
    return p.styleTags.contains('wrestler')
        ? 32 // Wrestlers peak later
        : p.styleTags.contains('striker')
        ? 29 // Strikers peak earlier
        : 30;
  }

  int _estimateRetirementAge(CareerProfile p) {
    return _estimatePeakAge(p) + 5;
  }

  String _recommendNextFight(CareerProfile p, CareerPhase phase) {
    switch (phase) {
      case CareerPhase.prospect:
        return 'Take fights against opponents with similar experience (3–5 pro fights)';
      case CareerPhase.rising:
        return 'Step up in competition — target a ranked opponent to break into top 15';
      case CareerPhase.contender:
        return 'Target top 5 opponent for title eliminator positioning';
      case CareerPhase.champion:
        return 'Defend against mandatory challenger or pursue superfight';
      case CareerPhase.gatekeeper:
        return 'Consider a style-favorable matchup to rebuild momentum';
      case CareerPhase.veteran:
        return 'Legacy fights or mentoring role — prioritize health';
      case CareerPhase.retired:
        return 'Transition to coaching, commentary, or promotional roles';
    }
  }

  String? _weightClassAdvice(CareerProfile p) {
    // Simple heuristic: if on a losing streak, consider weight class change.
    if (p.losses > p.wins && p.proFights >= 5) {
      return 'Consider moving to a different weight class — current division '
          'may not be optimal for your body composition';
    }
    return null;
  }

  String? _styleAdvice(CareerProfile p, CareerPhase phase) {
    if (phase == CareerPhase.gatekeeper) {
      return 'Diversify your offensive tools — add wrestling or submission game '
          'to become less predictable';
    }
    if (phase == CareerPhase.veteran) {
      return 'Focus on ring IQ and timing over explosive athleticism';
    }
    return null;
  }

  List<String> _skillPriorities(CareerProfile p, CareerPhase phase) {
    final priorities = <String>[];
    if (phase == CareerPhase.prospect || phase == CareerPhase.rising) {
      priorities.addAll(['Conditioning', 'Fundamentals', 'Fight IQ']);
    }
    if (phase == CareerPhase.contender) {
      priorities.addAll([
        'Game planning',
        'Style adaptability',
        'Mental fortitude',
      ]);
    }
    if (phase == CareerPhase.champion) {
      priorities.addAll([
        'Innovation',
        'Recovery optimization',
        'Anti-wrestling',
      ]);
    }
    return priorities;
  }

  List<CareerMilestone> _generateMilestones(
    CareerProfile p,
    CareerPhase phase,
  ) {
    final milestones = <CareerMilestone>[];
    if (p.wins < 10) {
      milestones.add(
        const CareerMilestone(
          id: 'win_10',
          description: 'Reach 10 professional wins',
        ),
      );
    }
    if (phase != CareerPhase.champion) {
      milestones.add(
        const CareerMilestone(
          id: 'title_shot',
          description: 'Earn a title shot',
        ),
      );
    }
    if (p.proFights < 20) {
      milestones.add(
        const CareerMilestone(
          id: 'fights_20',
          description: 'Complete 20 professional bouts',
        ),
      );
    }
    return milestones;
  }

  double _careerHealthScore(CareerProfile p, CareerPhase phase) {
    double score = 1.0;
    // Recent losses penalty.
    score -= (p.losses / (p.proFights > 0 ? p.proFights : 1)) * 0.3;
    // Age penalty for fighters past projected peak.
    final peak = _estimatePeakAge(p);
    if (p.age > peak) score -= (p.age - peak) * 0.05;
    // Phase bonus/penalty.
    if (phase == CareerPhase.champion) score += 0.1;
    if (phase == CareerPhase.gatekeeper) score -= 0.1;
    return score.clamp(0.0, 1.0);
  }

  Future<void> _persist(CareerRecommendation rec) async {
    try {
      await _firestore.collection('fighter_careers').doc(rec.fighterId).set({
        'currentPhase': rec.currentPhase.name,
        'peakAge': rec.estimatedPeakAge,
        'retirementAge': rec.estimatedRetirementAge,
        'careerHealth': rec.careerHealthScore,
        'assessedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[CareerEngine] Persist error: $e');
    }
  }
}
