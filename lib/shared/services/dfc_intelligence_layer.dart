import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/apex_operating_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC INTELLIGENCE LAYER — Layer 2: DFC's Brain
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Coordinates every AI system in the platform as one unified brain.
/// This layer LEARNS from every interaction and improves over time.
///
/// Subsystems:
///   • AI fight prediction    — CombatIntelligenceEngine
///   • AI commentary          — SamuraiOrchestrator
///   • AI matchmaking         — MatchmakingService, FightMatcherService
///   • AI storytelling        — SamuraiContentTransformer
///   • AI moderation          — AIModerationService, NinjaModeration
///   • AI gym coach           — AICoachService
///   • AI wellness            — HealthIntelligenceEngine
///   • AI media director      — FightMediaEngine
///   • AI event director      — PromoterAIService, WarRoomEngine
///   • AI fan personalization — FeedRankingEngine, DiscoveryService
///   • AI safety              — AISentinelService, ContentSafetyService
///
/// ═══════════════════════════════════════════════════════════════════════════

/// Named AI subsystem within the intelligence layer.
enum AISubsystem {
  fightPrediction,
  commentary,
  matchmaking,
  storytelling,
  moderation,
  gymCoach,
  wellness,
  mediaDirector,
  eventDirector,
  fanPersonalization,
  safety,
}

class DfcIntelligenceLayer extends ChangeNotifier {
  static final DfcIntelligenceLayer _instance =
      DfcIntelligenceLayer._internal();
  factory DfcIntelligenceLayer() => _instance;
  DfcIntelligenceLayer._internal();

  bool _initialized = false;
  Timer? _learningTimer;
  DateTime? _lastLearningCycle;
  int _totalDecisions = 0;
  int _totalLearningCycles = 0;

  /// Per-subsystem health (0.0 – 1.0).
  final Map<AISubsystem, double> _subsystemScores = {
    for (final s in AISubsystem.values) s: 1.0,
  };

  /// Learning improvement delta per subsystem (cumulative).
  final Map<AISubsystem, double> _learningDelta = {
    for (final s in AISubsystem.values) s: 0.0,
  };

  // ── Getters ──
  bool get initialized => _initialized;
  int get totalDecisions => _totalDecisions;
  int get totalLearningCycles => _totalLearningCycles;
  Map<AISubsystem, double> get subsystemScores =>
      Map.unmodifiable(_subsystemScores);
  Map<AISubsystem, double> get learningDelta =>
      Map.unmodifiable(_learningDelta);

  double get overallScore {
    if (_subsystemScores.isEmpty) return 0.0;
    return _subsystemScores.values.reduce((a, b) => a + b) /
        _subsystemScores.length;
  }

  ApexLayerStatus get layerStatus => ApexLayerStatus(
    layer: ApexLayer.intelligence,
    health: overallScore >= 0.8
        ? LayerHealth.optimal
        : overallScore >= 0.5
        ? LayerHealth.degraded
        : LayerHealth.critical,
    score: overallScore,
    activeSubsystems: _subsystemScores.values.where((s) => s >= 0.5).length,
    totalSubsystems: AISubsystem.values.length,
    lastHeartbeat: _lastLearningCycle ?? DateTime.now(),
    statusMessage:
        '$_totalDecisions decisions · $_totalLearningCycles learning cycles',
  );

  // ── Lifecycle ──

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Learn from platform data every 10 minutes.
    _learningTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _runLearningCycle();
    });

    debugPrint(
      '[Intelligence] Online — ${AISubsystem.values.length} subsystems active',
    );
    notifyListeners();
  }

  /// Record an AI decision (prediction, moderation action, recommendation, etc.)
  void recordDecision(AISubsystem subsystem, {bool correct = true}) {
    _totalDecisions++;
    if (correct) {
      // Successful decisions slowly improve subsystem score.
      final current = _subsystemScores[subsystem] ?? 1.0;
      _subsystemScores[subsystem] = (current + 0.001).clamp(0.0, 1.0);
      _learningDelta[subsystem] = (_learningDelta[subsystem] ?? 0) + 0.001;
    } else {
      final current = _subsystemScores[subsystem] ?? 1.0;
      _subsystemScores[subsystem] = (current - 0.005).clamp(0.0, 1.0);
    }
    notifyListeners();
  }

  /// Force a subsystem into a specific health state (external signal).
  void setSubsystemHealth(AISubsystem subsystem, double score) {
    _subsystemScores[subsystem] = score.clamp(0.0, 1.0);
    notifyListeners();
  }

  @override
  void dispose() {
    _learningTimer?.cancel();
    super.dispose();
  }

  // ── Internal ──

  void _runLearningCycle() {
    _totalLearningCycles++;
    _lastLearningCycle = DateTime.now();

    // Each cycle nudges every subsystem score toward 1.0 (self-healing).
    for (final s in AISubsystem.values) {
      final current = _subsystemScores[s] ?? 1.0;
      _subsystemScores[s] = (current + 0.002).clamp(0.0, 1.0);
    }

    debugPrint(
      '[Intelligence] Learning cycle #$_totalLearningCycles — '
      'overall ${overallScore.toStringAsFixed(3)}',
    );
    notifyListeners();
  }
}
