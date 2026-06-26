import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/health_metrics_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HEALTH INTELLIGENCE ENGINE - QUANTUM-GRADE SIGNAL PROCESSING
/// ═══════════════════════════════════════════════════════════════════════════
///
/// This service transforms raw health metrics into actionable intelligence.
///
/// DATA FLOW:
/// ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
/// │  Raw Metrics    │───▶│  Signal Engine  │───▶│  Health Signal  │
/// │  (User Input)   │    │  (This Service) │    │  (AI-Ready)     │
/// └─────────────────┘    └─────────────────┘    └─────────────────┘
///                              │
///                              ▼
///                    ┌─────────────────┐
///                    │  AI Coach       │
///                    │  (Interprets)   │
///                    └─────────────────┘
///
/// RULES:
/// ✓ Deterministic calculations only
/// ✓ No AI inference in this layer
/// ✓ Clear thresholds from sports science
/// ✓ Always fails safe (assumes worst case on missing data)
/// ═══════════════════════════════════════════════════════════════════════════

class HealthIntelligenceEngine {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ═══ COLLECTION PATHS ═══
  static const String _metricsCollection = 'health_metrics';
  static const String _signalsCollection = 'health_signals';

  // ═══════════════════════════════════════════════════════════════════════════
  // CORE SIGNAL GENERATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Process raw metrics and generate a health signal
  Future<HealthSignal> processMetrics(HealthMetrics metrics) async {
    // Get historical data for trend analysis
    final history = await _getRecentMetrics(metrics.odUserId);

    // Calculate composite scores
    final recoveryScore = _calculateRecoveryScore(metrics, history);
    final trainingReadiness = _calculateTrainingReadiness(metrics, history);
    final fightReadiness = _calculateFightReadiness(metrics, history);
    final stressLoad = _calculateStressLoad(metrics, history);
    final fatigueIndex = _calculateFatigueIndex(metrics, history);

    // Assess risks
    final hydrationRisk = _assessHydrationRisk(metrics);
    final overtrainingRisk = _assessOvertrainingRisk(metrics, history);
    final sleepDebtRisk = _assessSleepDebtRisk(metrics, history);
    final weightCutRisk = _assessWeightCutRisk(metrics);
    final mentalHealthRisk = _assessMentalHealthRisk(metrics);

    // Determine overall risk
    final overallRisk = _determineOverallRisk(
      hydrationRisk,
      overtrainingRisk,
      sleepDebtRisk,
      weightCutRisk,
      mentalHealthRisk,
    );

    // Generate flags
    final flags = _generateFlags(metrics, history);

    // Calculate trends
    final trends = _calculateTrends(metrics, history);

    // Generate recommendations
    final recommendations = _generateRecommendations(
      metrics,
      flags,
      overallRisk,
    );

    // Check if escalation needed
    final needsEscalation = _checkEscalation(flags, overallRisk);

    // Create signal
    final signal = HealthSignal(
      id: '',
      odUserId: metrics.odUserId,
      signalDate: metrics.recordedAt,
      calculatedAt: DateTime.now(),
      recoveryScore: recoveryScore,
      trainingReadiness: trainingReadiness,
      fightReadiness: fightReadiness,
      stressLoad: stressLoad,
      fatigueIndex: fatigueIndex,
      overallRisk: overallRisk,
      hydrationRisk: hydrationRisk,
      overtrainingRisk: overtrainingRisk,
      sleepDebtRisk: sleepDebtRisk,
      weightCutRisk: weightCutRisk,
      mentalHealthRisk: mentalHealthRisk,
      activeFlags: flags,
      primaryRecommendation: recommendations.isNotEmpty
          ? recommendations.first
          : null,
      supportingRecommendations: recommendations.skip(1).toList(),
      hrvTrend: trends['hrv'],
      sleepTrend: trends['sleep'],
      weightTrend: trends['weight'],
      moodTrend: trends['mood'],
      energyTrend: trends['energy'],
      sourceMetricsId: metrics.id,
      requiresEscalation: needsEscalation,
    );

    // Persist signal
    final docRef = await _firestore
        .collection(_signalsCollection)
        .add(signal.toFirestore());

    return HealthSignal(
      id: docRef.id,
      odUserId: signal.odUserId,
      signalDate: signal.signalDate,
      calculatedAt: signal.calculatedAt,
      recoveryScore: signal.recoveryScore,
      trainingReadiness: signal.trainingReadiness,
      fightReadiness: signal.fightReadiness,
      stressLoad: signal.stressLoad,
      fatigueIndex: signal.fatigueIndex,
      overallRisk: signal.overallRisk,
      hydrationRisk: signal.hydrationRisk,
      overtrainingRisk: signal.overtrainingRisk,
      sleepDebtRisk: signal.sleepDebtRisk,
      weightCutRisk: signal.weightCutRisk,
      mentalHealthRisk: signal.mentalHealthRisk,
      activeFlags: signal.activeFlags,
      primaryRecommendation: signal.primaryRecommendation,
      supportingRecommendations: signal.supportingRecommendations,
      hrvTrend: signal.hrvTrend,
      sleepTrend: signal.sleepTrend,
      weightTrend: signal.weightTrend,
      moodTrend: signal.moodTrend,
      energyTrend: signal.energyTrend,
      sourceMetricsId: signal.sourceMetricsId,
      requiresEscalation: signal.requiresEscalation,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPOSITE SCORE CALCULATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculate recovery score (0.0 - 1.0)
  /// Based on sleep, HRV, stress, and soreness
  double _calculateRecoveryScore(
    HealthMetrics current,
    List<HealthMetrics> history,
  ) {
    double score = 0.5; // Default to moderate

    // Sleep contribution (40% weight)
    if (current.sleepHours != null) {
      final sleepScore = _normalizeValue(current.sleepHours!, 4, 9, 7);
      score = score * 0.6 + sleepScore * 0.4;
    }

    // HRV contribution (30% weight)
    if (current.heartRateVariability != null) {
      // Higher HRV = better recovery
      // Average for athletes: 50-100ms
      final hrvScore = _normalizeValue(
        current.heartRateVariability!,
        20,
        100,
        60,
      );
      score = score * 0.7 + hrvScore * 0.3;
    }

    // Stress contribution (15% weight) - inverse
    if (current.stressLevel != null) {
      final stressScore = 1.0 - (current.stressLevel! / 10.0);
      score = score * 0.85 + stressScore * 0.15;
    }

    // Soreness contribution (15% weight) - inverse
    if (current.muscleSOoreness != null) {
      final sorenessScore = 1.0 - (current.muscleSOoreness! / 10.0);
      score = score * 0.85 + sorenessScore * 0.15;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Calculate training readiness (0.0 - 1.0)
  double _calculateTrainingReadiness(
    HealthMetrics current,
    List<HealthMetrics> history,
  ) {
    final recovery = _calculateRecoveryScore(current, history);
    double score = recovery;

    // Energy level contribution
    if (current.energyLevel != null) {
      final energyScore = current.energyLevel! / 10.0;
      score = score * 0.7 + energyScore * 0.3;
    }

    // Hydration contribution
    if (current.hydrationPercentage != null) {
      final hydrationScore = _normalizeValue(
        current.hydrationPercentage!,
        40,
        80,
        65,
      );
      score = score * 0.9 + hydrationScore * 0.1;
    }

    // Recent training load penalty
    if (history.isNotEmpty) {
      final recentLoad =
          history
              .take(3)
              .map((m) => m.totalTrainingMinutes)
              .reduce((a, b) => a + b) /
          3;
      if (recentLoad > 180) {
        // High recent load reduces readiness
        score *= 0.85;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  /// Calculate fight readiness (0.0 - 1.0)
  double _calculateFightReadiness(
    HealthMetrics current,
    List<HealthMetrics> history,
  ) {
    final trainingReady = _calculateTrainingReadiness(current, history);
    double score = trainingReady;

    // Mental clarity contribution
    if (current.mentalClarity != null) {
      final clarityScore = current.mentalClarity! / 10.0;
      score = score * 0.8 + clarityScore * 0.2;
    }

    // Weight status contribution
    if (current.weightCutPhase != null) {
      switch (current.weightCutPhase!) {
        case WeightCutPhase.maintenance:
          score *= 1.0;
          break;
        case WeightCutPhase.waterLoading:
          score *= 0.95;
          break;
        case WeightCutPhase.waterReduction:
          score *= 0.8;
          break;
        case WeightCutPhase.finalCut:
          score *= 0.6;
          break;
        case WeightCutPhase.rehydration:
          score *= 0.7;
          break;
        case WeightCutPhase.postFight:
          score *= 0.5;
          break;
      }
    }

    // Mood contribution
    if (current.moodScore != null) {
      final moodScore = current.moodScore! / 10.0;
      score = score * 0.9 + moodScore * 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Calculate stress load (0.0 - 1.0)
  double _calculateStressLoad(
    HealthMetrics current,
    List<HealthMetrics> history,
  ) {
    double load = 0.3; // Base load

    // Direct stress input
    if (current.stressLevel != null) {
      load = current.stressLevel! / 10.0;
    }

    // Training intensity adds stress
    if (current.trainingIntensity != null) {
      load = load * 0.7 + (current.trainingIntensity! / 10.0) * 0.3;
    }

    // Sleep deprivation adds stress
    if (current.sleepHours != null && current.sleepHours! < 6) {
      load += 0.15;
    }

    // Weight cut adds stress
    if (current.weightCutPhase == WeightCutPhase.finalCut) {
      load += 0.2;
    }

    // Sparring adds stress
    if (current.sparringRounds != null && current.sparringRounds! > 0) {
      load += current.sparringRounds! * 0.05;
    }

    return load.clamp(0.0, 1.0);
  }

  /// Calculate fatigue index (0.0 - 1.0)
  double _calculateFatigueIndex(
    HealthMetrics current,
    List<HealthMetrics> history,
  ) {
    double fatigue = 0.2;

    // Accumulated training load from history
    if (history.isNotEmpty) {
      final totalLoad = history
          .map((m) => m.totalTrainingMinutes)
          .reduce((a, b) => a + b);
      // More than 10 hours in a week = high fatigue
      fatigue = (totalLoad / 600).clamp(0.0, 1.0);
    }

    // Poor sleep increases fatigue
    if (current.sleepHours != null && current.sleepHours! < 6) {
      fatigue += 0.2;
    }

    // Low HRV indicates fatigue
    if (current.heartRateVariability != null &&
        current.heartRateVariability! < 40) {
      fatigue += 0.15;
    }

    // Soreness indicates fatigue
    if (current.muscleSOoreness != null && current.muscleSOoreness! > 6) {
      fatigue += 0.1;
    }

    return fatigue.clamp(0.0, 1.0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RISK ASSESSMENTS
  // ═══════════════════════════════════════════════════════════════════════════

  RiskLevel _assessHydrationRisk(HealthMetrics metrics) {
    if (metrics.hydrationPercentage == null) {
      // Use water intake as proxy
      if (metrics.waterIntakeMl != null) {
        if (metrics.waterIntakeMl! < 1000) return RiskLevel.red;
        if (metrics.waterIntakeMl! < 2000) return RiskLevel.orange;
        if (metrics.waterIntakeMl! < 2500) return RiskLevel.amber;
        return RiskLevel.green;
      }
      return RiskLevel.amber; // Unknown = caution
    }

    switch (metrics.hydrationLevel!) {
      case HydrationLevel.critical:
        return RiskLevel.red;
      case HydrationLevel.low:
        return RiskLevel.orange;
      case HydrationLevel.moderate:
        return RiskLevel.amber;
      case HydrationLevel.optimal:
        return RiskLevel.green;
      case HydrationLevel.overhydrated:
        return RiskLevel.amber;
    }
  }

  RiskLevel _assessOvertrainingRisk(
    HealthMetrics current,
    List<HealthMetrics> history,
  ) {
    if (history.isEmpty) return RiskLevel.green;

    // Check for overtraining indicators
    int redFlags = 0;

    // High training volume
    final weeklyMinutes = history
        .map((m) => m.totalTrainingMinutes)
        .reduce((a, b) => a + b);
    if (weeklyMinutes > 900) {
      redFlags += 2; // >15 hours/week
    } else if (weeklyMinutes > 720) {
      redFlags += 1; // >12 hours/week
    }

    // Declining HRV
    final hrvs = history
        .where((m) => m.heartRateVariability != null)
        .map((m) => m.heartRateVariability!)
        .toList();
    if (hrvs.length >= 3) {
      final recent = hrvs.take(3).reduce((a, b) => a + b) / 3;
      final older = hrvs.skip(3).isEmpty
          ? recent
          : hrvs.skip(3).reduce((a, b) => a + b) / hrvs.skip(3).length;
      if (recent < older * 0.85) redFlags += 2;
    }

    // Persistent high soreness
    final sorenessScores = history
        .where((m) => m.muscleSOoreness != null)
        .map((m) => m.muscleSOoreness!)
        .toList();
    if (sorenessScores.length >= 3) {
      final avgSoreness =
          sorenessScores.reduce((a, b) => a + b) / sorenessScores.length;
      if (avgSoreness > 7) {
        redFlags += 2;
      } else if (avgSoreness > 5) {
        redFlags += 1;
      }
    }

    // Sleep deprivation
    final sleepHours = history
        .where((m) => m.sleepHours != null)
        .map((m) => m.sleepHours!)
        .toList();
    if (sleepHours.isNotEmpty) {
      final avgSleep = sleepHours.reduce((a, b) => a + b) / sleepHours.length;
      if (avgSleep < 6) {
        redFlags += 2;
      } else if (avgSleep < 7) {
        redFlags += 1;
      }
    }

    if (redFlags >= 5) return RiskLevel.red;
    if (redFlags >= 3) return RiskLevel.orange;
    if (redFlags >= 1) return RiskLevel.amber;
    return RiskLevel.green;
  }

  RiskLevel _assessSleepDebtRisk(
    HealthMetrics current,
    List<HealthMetrics> history,
  ) {
    final allSleep = [
      if (current.sleepHours != null) current.sleepHours!,
      ...history.where((m) => m.sleepHours != null).map((m) => m.sleepHours!),
    ];

    if (allSleep.isEmpty) return RiskLevel.amber;

    final avgSleep = allSleep.reduce((a, b) => a + b) / allSleep.length;
    final recentSleep = current.sleepHours ?? avgSleep;

    // Severe sleep debt
    if (recentSleep < 4 || avgSleep < 5) return RiskLevel.red;
    if (recentSleep < 5 || avgSleep < 6) return RiskLevel.orange;
    if (recentSleep < 6 || avgSleep < 7) return RiskLevel.amber;
    return RiskLevel.green;
  }

  RiskLevel _assessWeightCutRisk(HealthMetrics metrics) {
    if (metrics.weightCutPhase == null ||
        metrics.weightCutPhase == WeightCutPhase.maintenance) {
      return RiskLevel.green;
    }

    // Check cut rate
    if (metrics.isDangerousWeightCutRate) {
      return RiskLevel.red;
    }

    // Check phase-specific risks
    switch (metrics.weightCutPhase!) {
      case WeightCutPhase.finalCut:
        // Final cut is always elevated risk
        if (metrics.hydrationLevel == HydrationLevel.critical ||
            metrics.hydrationLevel == HydrationLevel.low) {
          return RiskLevel.red;
        }
        return RiskLevel.orange;
      case WeightCutPhase.waterReduction:
        return RiskLevel.amber;
      case WeightCutPhase.postFight:
        return RiskLevel.amber; // Recovery phase needs monitoring
      default:
        return RiskLevel.green;
    }
  }

  RiskLevel _assessMentalHealthRisk(HealthMetrics metrics) {
    int concerns = 0;

    // Low mood
    if (metrics.moodScore != null && metrics.moodScore! <= 3) {
      concerns += 2;
    } else if (metrics.moodScore != null && metrics.moodScore! <= 5) {
      concerns += 1;
    }

    // High stress
    if (metrics.stressLevel != null && metrics.stressLevel! >= 8) {
      concerns += 2;
    } else if (metrics.stressLevel != null && metrics.stressLevel! >= 6) {
      concerns += 1;
    }

    // Low energy
    if (metrics.energyLevel != null && metrics.energyLevel! <= 3) {
      concerns += 1;
    }

    // Poor mental clarity
    if (metrics.mentalClarity != null && metrics.mentalClarity! <= 3) {
      concerns += 1;
    }

    if (concerns >= 5) return RiskLevel.red;
    if (concerns >= 3) return RiskLevel.orange;
    if (concerns >= 1) return RiskLevel.amber;
    return RiskLevel.green;
  }

  RiskLevel _determineOverallRisk(
    RiskLevel hydration,
    RiskLevel overtraining,
    RiskLevel sleepDebt,
    RiskLevel weightCut,
    RiskLevel mentalHealth,
  ) {
    final risks = [hydration, overtraining, sleepDebt, weightCut, mentalHealth];

    // Any red = overall red
    if (risks.contains(RiskLevel.red)) return RiskLevel.red;

    // Multiple orange = red
    final orangeCount = risks.where((r) => r == RiskLevel.orange).length;
    if (orangeCount >= 2) return RiskLevel.red;
    if (orangeCount == 1) return RiskLevel.orange;

    // Multiple amber = orange
    final amberCount = risks.where((r) => r == RiskLevel.amber).length;
    if (amberCount >= 3) return RiskLevel.orange;
    if (amberCount >= 1) return RiskLevel.amber;

    return RiskLevel.green;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FLAG GENERATION
  // ═══════════════════════════════════════════════════════════════════════════

  List<String> _generateFlags(
    HealthMetrics current,
    List<HealthMetrics> history,
  ) {
    final flags = <String>[];

    // Sleep flags
    if (current.sleepHours != null) {
      if (current.sleepHours! < 4) {
        flags.add('severe_sleep_deprivation');
      } else if (current.sleepHours! < 6) {
        flags.add('low_sleep');
      }
    }

    // Hydration flags
    if (current.hydrationLevel == HydrationLevel.critical) {
      flags.add('severe_dehydration');
    } else if (current.hydrationLevel == HydrationLevel.low) {
      flags.add('dehydration_warning');
    }

    // HRV flags
    if (current.heartRateVariability != null) {
      if (current.heartRateVariability! < 30) {
        flags.add('critically_low_hrv');
      } else if (current.heartRateVariability! < 45) {
        flags.add('low_hrv');
      }
    }

    // Training load flags
    if (current.totalTrainingMinutes > 180) {
      flags.add('high_training_volume');
    }
    if (current.sparringRounds != null && current.sparringRounds! > 6) {
      flags.add('excessive_sparring');
    }

    // Weight cut flags
    if (current.isDangerousWeightCutRate) {
      flags.add('dangerous_weight_cut');
    }
    if (current.weightCutPhase == WeightCutPhase.finalCut) {
      flags.add('final_cut_phase');
    }

    // Mental health flags
    if (current.moodScore != null && current.moodScore! <= 2) {
      flags.add('crisis_support_needed');
    }
    if (current.stressLevel != null && current.stressLevel! >= 9) {
      flags.add('extreme_stress');
    }

    // Recovery flags
    if (current.muscleSOoreness != null && current.muscleSOoreness! >= 8) {
      flags.add('high_soreness');
    }

    // Accumulated fatigue from history
    if (history.length >= 5) {
      final avgEnergy =
          history
              .where((m) => m.energyLevel != null)
              .map((m) => m.energyLevel!)
              .fold(0, (a, b) => a + b) /
          max(1, history.where((m) => m.energyLevel != null).length);
      if (avgEnergy < 4) flags.add('accumulated_fatigue');
    }

    return flags;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TREND CALCULATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Map<String, double?> _calculateTrends(
    HealthMetrics current,
    List<HealthMetrics> history,
  ) {
    return {
      'hrv': _calculateTrend(
        current.heartRateVariability,
        history.map((m) => m.heartRateVariability).toList(),
      ),
      'sleep': _calculateTrend(
        current.sleepHours,
        history.map((m) => m.sleepHours).toList(),
      ),
      'weight': _calculateTrend(
        current.weight,
        history.map((m) => m.weight).toList(),
      ),
      'mood': _calculateTrend(
        current.moodScore?.toDouble(),
        history.map((m) => m.moodScore?.toDouble()).toList(),
      ),
      'energy': _calculateTrend(
        current.energyLevel?.toDouble(),
        history.map((m) => m.energyLevel?.toDouble()).toList(),
      ),
    };
  }

  double? _calculateTrend(double? current, List<double?> history) {
    if (current == null) return null;

    final validHistory = history
        .where((v) => v != null)
        .cast<double>()
        .toList();
    if (validHistory.isEmpty) return null;

    final avg = validHistory.reduce((a, b) => a + b) / validHistory.length;
    if (avg == 0) return null;

    // Return normalized trend (-1 to +1)
    return ((current - avg) / avg).clamp(-1.0, 1.0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECOMMENDATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  List<String> _generateRecommendations(
    HealthMetrics metrics,
    List<String> flags,
    RiskLevel overallRisk,
  ) {
    final recs = <String>[];

    // Crisis-level recommendations (always first)
    if (flags.contains('crisis_support_needed')) {
      recs.add(
        'Your wellbeing matters. Consider reaching out to a trusted person or support service.',
      );
    }
    if (flags.contains('severe_dehydration')) {
      recs.add(
        'Hydration is critically low. Prioritize fluid and electrolyte intake now.',
      );
    }
    if (flags.contains('dangerous_weight_cut')) {
      recs.add(
        'Weight loss rate is in a dangerous range. Consider slowing down the cut.',
      );
    }

    // High-risk recommendations
    if (flags.contains('severe_sleep_deprivation')) {
      recs.add(
        'Sleep debt is significant. Today is a recovery day, not a training day.',
      );
    }
    if (flags.contains('excessive_sparring')) {
      recs.add(
        'High sparring volume. Consider lighter technical work tomorrow.',
      );
    }

    // Moderate recommendations
    if (flags.contains('low_sleep')) {
      recs.add('Aim for 7-9 hours tonight to support recovery.');
    }
    if (flags.contains('low_hrv')) {
      recs.add(
        'HRV suggests your body is still recovering. Consider lower intensity today.',
      );
    }
    if (flags.contains('high_soreness')) {
      recs.add(
        'Muscle soreness is elevated. Active recovery or mobility work may help.',
      );
    }

    // General advice based on overall risk
    if (overallRisk == RiskLevel.green && recs.isEmpty) {
      recs.add(
        'Looking good. You\'re in a solid position to train as planned.',
      );
    }

    return recs;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ESCALATION CHECK
  // ═══════════════════════════════════════════════════════════════════════════

  bool _checkEscalation(List<String> flags, RiskLevel risk) {
    // Critical flags always escalate
    const escalationFlags = [
      'crisis_support_needed',
      'severe_dehydration',
      'dangerous_weight_cut',
      'severe_sleep_deprivation',
      'critically_low_hrv',
    ];

    if (flags.any((f) => escalationFlags.contains(f))) return true;
    if (risk == RiskLevel.red) return true;

    return false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Normalize a value to 0.0 - 1.0 scale
  double _normalizeValue(double value, double min, double max, double optimal) {
    if (value <= min) return 0.0;
    if (value >= max) return 1.0;
    if (value == optimal) return 1.0;

    if (value < optimal) {
      return (value - min) / (optimal - min);
    } else {
      return 1.0 - ((value - optimal) / (max - optimal));
    }
  }

  /// Get recent metrics for a user
  Future<List<HealthMetrics>> _getRecentMetrics(
    String userId, {
    int days = 7,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));

    final snapshot = await _firestore
        .collection(_metricsCollection)
        .where('userId', isEqualTo: userId)
        .where('recordedAt', isGreaterThan: Timestamp.fromDate(cutoff))
        .orderBy('recordedAt', descending: true)
        .limit(days * 2) // Allow for multiple entries per day
        .get();

    return snapshot.docs
        .map(HealthMetrics.fromFirestore)
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC QUERY METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get latest signal for a user
  Future<HealthSignal?> getLatestSignal(String userId) async {
    final snapshot = await _firestore
        .collection(_signalsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('signalDate', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return HealthSignal.fromFirestore(snapshot.docs.first);
  }

  /// Stream signals for real-time updates
  Stream<HealthSignal?> signalStream(String userId) {
    return _firestore
        .collection(_signalsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('signalDate', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return HealthSignal.fromFirestore(snapshot.docs.first);
        });
  }

  /// Get signal history for trends
  Future<List<HealthSignal>> getSignalHistory(
    String userId, {
    int days = 30,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));

    final snapshot = await _firestore
        .collection(_signalsCollection)
        .where('userId', isEqualTo: userId)
        .where('signalDate', isGreaterThan: Timestamp.fromDate(cutoff))
        .orderBy('signalDate', descending: true)
        .get();

    return snapshot.docs.map(HealthSignal.fromFirestore).toList();
  }
}
