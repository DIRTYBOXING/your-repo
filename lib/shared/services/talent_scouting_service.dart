import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC TALENT SCOUTING AI — #109
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Finds the next champions by analyzing multi-signal fighter data.
///
/// Inputs:
///   • Amateur footage analysis (fight results, performance metrics)
///   • Social media presence (follower growth, engagement rate)
///   • Fight stats (win rate, finish rate, style diversity)
///   • Gym reputation (coach quality, alumni success)
///   • Coach feedback (training reports, readiness assessments)
///
/// Outputs:
///   • Prospect ranking (1–100)
///   • Breakout potential score
///   • Marketability score
///   • Skill ceiling estimate
///   • Contract readiness assessment
///
/// Firestore Collections:
///   talent_scouts/{scoutId}           — Scouting reports
///   talent_prospects/{prospectId}     — Prospect profiles
///
/// ═══════════════════════════════════════════════════════════════════════════

class TalentProspect {
  final String fighterId;
  final String name;
  final double prospectRank; // 1–100
  final double breakoutPotential; // 0.0 – 1.0
  final double marketability; // 0.0 – 1.0
  final double skillCeiling; // 0.0 – 10.0
  final bool contractReady;
  final Map<String, double> signalScores;
  final DateTime assessedAt;

  const TalentProspect({
    required this.fighterId,
    required this.name,
    required this.prospectRank,
    required this.breakoutPotential,
    required this.marketability,
    required this.skillCeiling,
    required this.contractReady,
    required this.signalScores,
    required this.assessedAt,
  });
}

class ScoutingInput {
  final String fighterId;
  final int wins;
  final int losses;
  final double finishRate;
  final int socialFollowers;
  final double socialEngagementRate;
  final double gymReputation; // 0.0 – 10.0
  final double coachRating; // 0.0 – 5.0
  final String? coachFeedback;
  final int amateurFights;
  final double trainingConsistency; // 0.0 – 1.0

  const ScoutingInput({
    required this.fighterId,
    required this.wins,
    required this.losses,
    this.finishRate = 0,
    this.socialFollowers = 0,
    this.socialEngagementRate = 0,
    this.gymReputation = 5.0,
    this.coachRating = 3.0,
    this.coachFeedback,
    this.amateurFights = 0,
    this.trainingConsistency = 0.5,
  });

  double get winRate => (wins + losses) > 0 ? wins / (wins + losses) : 0;
}

class TalentScoutingService extends ChangeNotifier {
  static final TalentScoutingService _instance =
      TalentScoutingService._internal();
  factory TalentScoutingService() => _instance;
  TalentScoutingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _initialized = false;
  Timer? _scoutTimer;

  final List<TalentProspect> _prospects = [];
  int _totalAssessments = 0;

  // ── Getters ──
  bool get initialized => _initialized;
  int get totalAssessments => _totalAssessments;
  List<TalentProspect> get prospects => List.unmodifiable(_prospects);

  List<TalentProspect> get topProspects =>
      (List<TalentProspect>.from(_prospects)
            ..sort((a, b) => a.prospectRank.compareTo(b.prospectRank)))
          .take(20)
          .toList();

  // ── Lifecycle ──

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Run scouting sweep every hour.
    _scoutTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _runScoutingSweep();
    });

    debugPrint('[TalentScout] Online — AI scouting active');
    notifyListeners();
  }

  // ── Core Assessment ──

  /// Assess a fighter and generate a TalentProspect report.
  TalentProspect assessFighter(String name, ScoutingInput input) {
    _totalAssessments++;

    // Weighted scoring algorithm.
    const weights = {
      'fightRecord': 0.25,
      'finishRate': 0.10,
      'socialPresence': 0.15,
      'gymReputation': 0.15,
      'coachRating': 0.10,
      'experience': 0.10,
      'consistency': 0.15,
    };

    final signals = <String, double>{
      'fightRecord': input.winRate * 100,
      'finishRate': input.finishRate * 100,
      'socialPresence': _socialScore(
        input.socialFollowers,
        input.socialEngagementRate,
      ),
      'gymReputation': input.gymReputation * 10,
      'coachRating': input.coachRating * 20,
      'experience': (input.amateurFights.clamp(0, 30) / 30.0) * 100,
      'consistency': input.trainingConsistency * 100,
    };

    double totalScore = 0;
    for (final key in weights.keys) {
      totalScore += (signals[key] ?? 0) * (weights[key] ?? 0);
    }

    final breakout = (totalScore / 100).clamp(0.0, 1.0);
    final market = _marketabilityScore(input);
    final ceiling = _skillCeilingEstimate(input);
    final contractReady = totalScore >= 70 && input.wins >= 5;

    // Prospect rank: 1 = best, 100 = worst. Invert the score.
    final rank = ((1 - breakout) * 99 + 1).clamp(1.0, 100.0);

    final prospect = TalentProspect(
      fighterId: input.fighterId,
      name: name,
      prospectRank: rank,
      breakoutPotential: breakout,
      marketability: market,
      skillCeiling: ceiling,
      contractReady: contractReady,
      signalScores: signals,
      assessedAt: DateTime.now(),
    );

    // Update or add prospect.
    _prospects.removeWhere((p) => p.fighterId == input.fighterId);
    _prospects.add(prospect);

    // Persist to Firestore.
    _persistProspect(prospect);

    debugPrint(
      '[TalentScout] Assessed $name — '
      'rank ${rank.toStringAsFixed(0)}, breakout ${(breakout * 100).toStringAsFixed(0)}%',
    );
    notifyListeners();
    return prospect;
  }

  @override
  void dispose() {
    _scoutTimer?.cancel();
    super.dispose();
  }

  // ── Internal ──

  double _socialScore(int followers, double engagementRate) {
    // Log scale for followers (10k+ = high score), weighted by engagement.
    if (followers <= 0) return 0;
    final followerScore = (followers.clamp(0, 1000000) / 1000000 * 50).clamp(
      0.0,
      50.0,
    );
    final engagementScore = (engagementRate * 50).clamp(0.0, 50.0);
    return followerScore + engagementScore;
  }

  double _marketabilityScore(ScoutingInput input) {
    // Marketability = social following + finish rate (exciting fights) + win rate.
    final social =
        _socialScore(input.socialFollowers, input.socialEngagementRate) / 100;
    final exciting = input.finishRate;
    final winning = input.winRate;
    return ((social * 0.4 + exciting * 0.35 + winning * 0.25)).clamp(0.0, 1.0);
  }

  double _skillCeilingEstimate(ScoutingInput input) {
    // Estimate 0–10 based on age of career and consistency.
    final base = input.gymReputation;
    final bonus = input.trainingConsistency * 3;
    final winBonus = input.winRate * 2;
    return (base + bonus + winBonus).clamp(0.0, 10.0);
  }

  Future<void> _persistProspect(TalentProspect prospect) async {
    try {
      await _firestore
          .collection('talent_prospects')
          .doc(prospect.fighterId)
          .set({
            'name': prospect.name,
            'prospectRank': prospect.prospectRank,
            'breakoutPotential': prospect.breakoutPotential,
            'marketability': prospect.marketability,
            'skillCeiling': prospect.skillCeiling,
            'contractReady': prospect.contractReady,
            'signalScores': prospect.signalScores,
            'assessedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('[TalentScout] Persist error: $e');
    }
  }

  void _runScoutingSweep() {
    debugPrint('[TalentScout] Sweep — ${_prospects.length} prospects tracked');
    notifyListeners();
  }
}
