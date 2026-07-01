import 'dart:async';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC REAL-TIME SCORING SERVICE — #111
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Powers live scoring overlays for fight broadcasts and in-app viewers.
///
/// Tracked Metrics Per Round:
///   • Significant strikes landed / attempted
///   • Takedowns landed / attempted
///   • Control time (seconds)
///   • Submission attempts
///   • Knockdowns
///   • Fouls & point deductions
///
/// Outputs:
///   • Live scorecard per judge (10-point must)
///   • Media scorecard
///   • Fan polling results
///   • Real-time strike/grappling heatmaps
///
/// ═══════════════════════════════════════════════════════════════════════════

class RoundStats {
  final int round;
  final String fighterId;
  int sigStrikesLanded;
  int sigStrikesAttempted;
  int takedownsLanded;
  int takedownsAttempted;
  int controlTimeSeconds;
  int submissionAttempts;
  int knockdowns;
  int fouls;
  int pointDeductions;

  RoundStats({
    required this.round,
    required this.fighterId,
    this.sigStrikesLanded = 0,
    this.sigStrikesAttempted = 0,
    this.takedownsLanded = 0,
    this.takedownsAttempted = 0,
    this.controlTimeSeconds = 0,
    this.submissionAttempts = 0,
    this.knockdowns = 0,
    this.fouls = 0,
    this.pointDeductions = 0,
  });

  double get strikingAccuracy =>
      sigStrikesAttempted > 0 ? sigStrikesLanded / sigStrikesAttempted : 0;

  double get takedownAccuracy =>
      takedownsAttempted > 0 ? takedownsLanded / takedownsAttempted : 0;
}

class JudgeScorecard {
  final String judgeName;
  final Map<int, Map<String, int>> roundScores; // round -> {fighterId: score}

  const JudgeScorecard({required this.judgeName, required this.roundScores});

  int totalForFighter(String fighterId) {
    int total = 0;
    for (final round in roundScores.values) {
      total += round[fighterId] ?? 0;
    }
    return total;
  }
}

class LiveFightScoring {
  final String fightId;
  final String fighterAId;
  final String fighterBId;
  int currentRound;
  bool isActive;
  final Map<int, RoundStats> fighterARounds; // round -> stats
  final Map<int, RoundStats> fighterBRounds;
  final List<JudgeScorecard> judgeScorecards;
  final Map<String, int> fanPoll; // fighterId -> votes

  LiveFightScoring({
    required this.fightId,
    required this.fighterAId,
    required this.fighterBId,
    this.currentRound = 1,
    this.isActive = false,
    Map<int, RoundStats>? fighterARounds,
    Map<int, RoundStats>? fighterBRounds,
    List<JudgeScorecard>? judgeScorecards,
    Map<String, int>? fanPoll,
  }) : fighterARounds = fighterARounds ?? {},
       fighterBRounds = fighterBRounds ?? {},
       judgeScorecards = judgeScorecards ?? [],
       fanPoll = fanPoll ?? {};
}

class RealtimeScoringService extends ChangeNotifier {
  static final RealtimeScoringService _instance =
      RealtimeScoringService._internal();
  factory RealtimeScoringService() => _instance;
  RealtimeScoringService._internal();

  bool _initialized = false;
  Timer? _broadcastTimer;

  final Map<String, LiveFightScoring> _activeFights = {};

  // ── Getters ──
  bool get initialized => _initialized;
  int get activeFightCount => _activeFights.length;

  LiveFightScoring? getFight(String fightId) => _activeFights[fightId];

  // ── Lifecycle ──

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Broadcast scoring updates every 2 seconds during active fights.
    _broadcastTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _broadcastUpdates();
    });

    debugPrint('[RealtimeScoring] Online — live overlay system active');
    notifyListeners();
  }

  // ── Fight Session Management ──

  void startFight(String fightId, String fighterAId, String fighterBId) {
    _activeFights[fightId] = LiveFightScoring(
      fightId: fightId,
      fighterAId: fighterAId,
      fighterBId: fighterBId,
      isActive: true,
    );
    _activeFights[fightId]!.fighterARounds[1] = RoundStats(
      round: 1,
      fighterId: fighterAId,
    );
    _activeFights[fightId]!.fighterBRounds[1] = RoundStats(
      round: 1,
      fighterId: fighterBId,
    );
    debugPrint('[RealtimeScoring] Fight started: $fightId');
    notifyListeners();
  }

  void endRound(String fightId) {
    final fight = _activeFights[fightId];
    if (fight == null) return;
    fight.currentRound++;
    fight.fighterARounds[fight.currentRound] = RoundStats(
      round: fight.currentRound,
      fighterId: fight.fighterAId,
    );
    fight.fighterBRounds[fight.currentRound] = RoundStats(
      round: fight.currentRound,
      fighterId: fight.fighterBId,
    );
    debugPrint('[RealtimeScoring] Round ${fight.currentRound} started');
    notifyListeners();
  }

  void endFight(String fightId) {
    final fight = _activeFights[fightId];
    if (fight == null) return;
    fight.isActive = false;
    debugPrint('[RealtimeScoring] Fight ended: $fightId');
    notifyListeners();
  }

  // ── Stat Recording ──

  void recordStrike(String fightId, String fighterId, {bool landed = true}) {
    final fight = _activeFights[fightId];
    if (fight == null || !fight.isActive) return;

    final stats = _getActiveRoundStats(fight, fighterId);
    if (stats == null) return;

    stats.sigStrikesAttempted++;
    if (landed) stats.sigStrikesLanded++;
    notifyListeners();
  }

  void recordTakedown(String fightId, String fighterId, {bool landed = true}) {
    final fight = _activeFights[fightId];
    if (fight == null || !fight.isActive) return;

    final stats = _getActiveRoundStats(fight, fighterId);
    if (stats == null) return;

    stats.takedownsAttempted++;
    if (landed) stats.takedownsLanded++;
    notifyListeners();
  }

  void recordControlTime(String fightId, String fighterId, int seconds) {
    final fight = _activeFights[fightId];
    if (fight == null || !fight.isActive) return;

    final stats = _getActiveRoundStats(fight, fighterId);
    if (stats == null) return;

    stats.controlTimeSeconds += seconds;
    notifyListeners();
  }

  void recordKnockdown(String fightId, String fighterId) {
    final fight = _activeFights[fightId];
    if (fight == null || !fight.isActive) return;

    final stats = _getActiveRoundStats(fight, fighterId);
    if (stats == null) return;

    stats.knockdowns++;
    notifyListeners();
  }

  void recordSubmissionAttempt(String fightId, String fighterId) {
    final fight = _activeFights[fightId];
    if (fight == null || !fight.isActive) return;

    final stats = _getActiveRoundStats(fight, fighterId);
    if (stats == null) return;

    stats.submissionAttempts++;
    notifyListeners();
  }

  // ── AI Auto-Score (10-Point Must) ──

  /// Auto-generate a 10-point must scorecard for the current round.
  Map<String, int> autoScoreRound(String fightId, int round) {
    final fight = _activeFights[fightId];
    if (fight == null) return {};

    final aStats = fight.fighterARounds[round];
    final bStats = fight.fighterBRounds[round];
    if (aStats == null || bStats == null) return {};

    double aScore = 0;
    double bScore = 0;

    // Striking
    aScore += aStats.sigStrikesLanded * 0.5;
    bScore += bStats.sigStrikesLanded * 0.5;
    // Grappling
    aScore += aStats.takedownsLanded * 2;
    bScore += bStats.takedownsLanded * 2;
    // Control
    aScore += aStats.controlTimeSeconds * 0.02;
    bScore += bStats.controlTimeSeconds * 0.02;
    // Knockdowns (huge)
    aScore += aStats.knockdowns * 5;
    bScore += bStats.knockdowns * 5;
    // Deductions
    aScore -= aStats.pointDeductions;
    bScore -= bStats.pointDeductions;

    // 10-point must. Winner gets 10, loser gets 9 (or 8 for domination).
    if (aScore > bScore) {
      final margin = aScore - bScore;
      return {fight.fighterAId: 10, fight.fighterBId: margin > 10 ? 8 : 9};
    } else if (bScore > aScore) {
      final margin = bScore - aScore;
      return {fight.fighterAId: margin > 10 ? 8 : 9, fight.fighterBId: 10};
    }
    return {fight.fighterAId: 10, fight.fighterBId: 10};
  }

  // ── Fan Poll ──

  void castFanVote(String fightId, String fighterId) {
    final fight = _activeFights[fightId];
    if (fight == null) return;
    fight.fanPoll[fighterId] = (fight.fanPoll[fighterId] ?? 0) + 1;
    notifyListeners();
  }

  @override
  void dispose() {
    _broadcastTimer?.cancel();
    super.dispose();
  }

  // ── Internal ──

  RoundStats? _getActiveRoundStats(LiveFightScoring fight, String fighterId) {
    if (fighterId == fight.fighterAId) {
      return fight.fighterARounds[fight.currentRound];
    } else if (fighterId == fight.fighterBId) {
      return fight.fighterBRounds[fight.currentRound];
    }
    return null;
  }

  void _broadcastUpdates() {
    final active = _activeFights.values.where((f) => f.isActive).length;
    if (active > 0) {
      debugPrint('[RealtimeScoring] Broadcasting $active active fights');
    }
  }
}
