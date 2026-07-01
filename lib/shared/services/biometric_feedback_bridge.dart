import 'readiness_score_engine.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// BIOMETRIC FEEDBACK BRIDGE — Wearable → Bot Intelligence Pipeline
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Translates raw wearable data (NormalizedHealthPayload) into actionable
/// coaching decisions. Bridges the gap between WearableApiConnectorService
/// (data collection) and bot services (actionable coaching).
///
/// Pipeline: Wearable → BiometricFeedbackBridge → ReadinessScoreEngine
///         → Decision → Bot action (ShidoInsight, CampCoach plan, etc.)
/// ═══════════════════════════════════════════════════════════════════════════

enum BiometricAlert {
  hrvCritical(
    'HRV Critical',
    'danger',
    'HRV below 30ms — parasympathetic recovery severely impaired',
  ),
  rhrElevated(
    'RHR Elevated',
    'warning',
    'Resting HR 10+ bpm above baseline — possible overtraining',
  ),
  sleepDebt(
    'Sleep Debt',
    'warning',
    'Cumulative sleep under 6h — cognitive and physical impairment risk',
  ),
  dehydrationRisk(
    'Dehydration Risk',
    'caution',
    'Markers suggest suboptimal hydration',
  ),
  overtrainingSpike(
    'Overtraining Spike',
    'danger',
    'ACWR > 1.5 — acute injury risk elevated',
  ),
  recoveryGreen(
    'Recovery Green',
    'positive',
    'All recovery markers within optimal ranges',
  ),
  peakWindow(
    'Peak Window',
    'positive',
    'Biometrics indicate a high-performance window — push hard',
  );

  final String label;
  final String severity; // danger, warning, caution, positive
  final String explanation;
  const BiometricAlert(this.label, this.severity, this.explanation);
}

class BiometricDecision {
  final String fighterId;
  final ReadinessResult readiness;
  final List<BiometricAlert> alerts;
  final TrainingModifier modifier;
  final List<BotDirective> botDirectives;
  final DateTime decidedAt;

  const BiometricDecision({
    required this.fighterId,
    required this.readiness,
    required this.alerts,
    required this.modifier,
    required this.botDirectives,
    required this.decidedAt,
  });

  Map<String, dynamic> toMap() => {
    'fighterId': fighterId,
    'readinessScore': readiness.overallScore,
    'zone': readiness.zone.label,
    'alerts': alerts.map((a) => a.label).toList(),
    'modifier': modifier.toMap(),
    'directiveCount': botDirectives.length,
    'decidedAt': decidedAt.toIso8601String(),
  };
}

class TrainingModifier {
  final double intensityMultiplier; // 0.0–1.5 (1.0 = normal)
  final double volumeMultiplier;
  final bool forceRestDay;
  final String?
  suggestedSessionType; // 'sparring', 'technical', 'cardio', 'rest', 'mobility'
  final int? maxDurationMinutes;

  const TrainingModifier({
    required this.intensityMultiplier,
    required this.volumeMultiplier,
    this.forceRestDay = false,
    this.suggestedSessionType,
    this.maxDurationMinutes,
  });

  Map<String, dynamic> toMap() => {
    'intensityMul': intensityMultiplier,
    'volumeMul': volumeMultiplier,
    'forceRest': forceRestDay,
    'sessionType': suggestedSessionType,
    'maxMinutes': maxDurationMinutes,
  };
}

enum BotDirectiveTarget { shido, campCoach, shakura, blotato, orchestrator }

class BotDirective {
  final BotDirectiveTarget target;
  final String action; // e.g. 'adjust_plan', 'send_alert', 'modify_nutrition'
  final Map<String, dynamic> payload;
  final String reason;

  const BotDirective({
    required this.target,
    required this.action,
    required this.payload,
    required this.reason,
  });
}

/// Raw biometric snapshot — matches NormalizedHealthPayload fields
class BeastBiometricSnapshot {
  final int? heartRate;
  final int? restingHR;
  final int? hrvMs;
  final int? spo2;
  final double? sleepHours;
  final double? deepSleepHours;
  final int? sleepScore;
  final int? recoveryScore;
  final int? readinessScore;
  final int? strainScore;
  final double? skinTemp;
  final double? respiratoryRate;
  final double? cortisol;
  final int? steps;
  final double? caloriesBurned;
  final double? activeMinutes;

  // Training context
  final double? trainingLoad7Day;
  final double? trainingLoad28Day;
  final int? baselineRHR;

  // Manual inputs
  final int? moodRating;
  final int? stressLevel;
  final double? waterIntakeLiters;
  final double? caloriesConsumed;
  final double? calorieTarget;
  final double? proteinGrams;
  final double? proteinTargetGrams;

  const BeastBiometricSnapshot({
    this.heartRate,
    this.restingHR,
    this.hrvMs,
    this.spo2,
    this.sleepHours,
    this.deepSleepHours,
    this.sleepScore,
    this.recoveryScore,
    this.readinessScore,
    this.strainScore,
    this.skinTemp,
    this.respiratoryRate,
    this.cortisol,
    this.steps,
    this.caloriesBurned,
    this.activeMinutes,
    this.trainingLoad7Day,
    this.trainingLoad28Day,
    this.baselineRHR,
    this.moodRating,
    this.stressLevel,
    this.waterIntakeLiters,
    this.caloriesConsumed,
    this.calorieTarget,
    this.proteinGrams,
    this.proteinTargetGrams,
  });
}

class BiometricFeedbackBridge {
  BiometricFeedbackBridge._();
  static final BiometricFeedbackBridge instance = BiometricFeedbackBridge._();

  final ReadinessScoreEngine _readinessEngine = ReadinessScoreEngine.instance;

  /// Process a biometric snapshot and produce coaching decisions
  BiometricDecision process({
    required String fighterId,
    required BeastBiometricSnapshot snapshot,
  }) {
    // Step 1: Convert snapshot to ReadinessInput
    final readinessInput = ReadinessInput(
      sleepHours: snapshot.sleepHours,
      sleepScore: snapshot.sleepScore,
      deepSleepHours: snapshot.deepSleepHours,
      hrvMs: snapshot.hrvMs,
      restingHR: snapshot.restingHR,
      baselineRHR: snapshot.baselineRHR,
      recoveryScore: snapshot.recoveryScore,
      trainingLoad7Day: snapshot.trainingLoad7Day,
      trainingLoad28Day: snapshot.trainingLoad28Day,
      waterIntakeLiters: snapshot.waterIntakeLiters,
      caloriesConsumed: snapshot.caloriesConsumed,
      calorieTarget: snapshot.calorieTarget,
      proteinGrams: snapshot.proteinGrams,
      proteinTargetGrams: snapshot.proteinTargetGrams,
      moodRating: snapshot.moodRating,
      stressLevel: snapshot.stressLevel,
      cortisol: snapshot.cortisol,
    );

    // Step 2: Compute readiness
    final readiness = _readinessEngine.compute(readinessInput);

    // Step 3: Detect biometric alerts
    final alerts = _detectAlerts(snapshot, readiness);

    // Step 4: Compute training modifier
    final modifier = _computeModifier(readiness, alerts);

    // Step 5: Generate bot directives
    final directives = _generateDirectives(readiness, alerts, modifier);

    return BiometricDecision(
      fighterId: fighterId,
      readiness: readiness,
      alerts: alerts,
      modifier: modifier,
      botDirectives: directives,
      decidedAt: DateTime.now(),
    );
  }

  List<BiometricAlert> _detectAlerts(
    BeastBiometricSnapshot snapshot,
    ReadinessResult readiness,
  ) {
    final alerts = <BiometricAlert>[];

    // HRV critical
    if (snapshot.hrvMs != null && snapshot.hrvMs! < 30) {
      alerts.add(BiometricAlert.hrvCritical);
    }

    // RHR elevated
    if (snapshot.restingHR != null && snapshot.baselineRHR != null) {
      if (snapshot.restingHR! - snapshot.baselineRHR! >= 10) {
        alerts.add(BiometricAlert.rhrElevated);
      }
    }

    // Sleep debt
    if (snapshot.sleepHours != null && snapshot.sleepHours! < 6) {
      alerts.add(BiometricAlert.sleepDebt);
    }

    // Overtraining
    if (snapshot.trainingLoad7Day != null &&
        snapshot.trainingLoad28Day != null) {
      final chronic = snapshot.trainingLoad28Day! / 4;
      if (chronic > 0) {
        final acwr = snapshot.trainingLoad7Day! / chronic;
        if (acwr > 1.5) {
          alerts.add(BiometricAlert.overtrainingSpike);
        }
      }
    }

    // Dehydration (inferred from low water intake)
    if (snapshot.waterIntakeLiters != null &&
        snapshot.waterIntakeLiters! < 1.5) {
      alerts.add(BiometricAlert.dehydrationRisk);
    }

    // Positive alerts
    if (readiness.overallScore >= 85 && alerts.isEmpty) {
      alerts.add(BiometricAlert.peakWindow);
    } else if (readiness.overallScore >= 70 &&
        !alerts.any((a) => a.severity == 'danger')) {
      alerts.add(BiometricAlert.recoveryGreen);
    }

    return alerts;
  }

  TrainingModifier _computeModifier(
    ReadinessResult readiness,
    List<BiometricAlert> alerts,
  ) {
    final hasDanger = alerts.any((a) => a.severity == 'danger');
    final hasWarning = alerts.any((a) => a.severity == 'warning');

    if (hasDanger) {
      return const TrainingModifier(
        intensityMultiplier: 0.0,
        volumeMultiplier: 0.0,
        forceRestDay: true,
        suggestedSessionType: 'rest',
        maxDurationMinutes: 0,
      );
    }

    switch (readiness.zone) {
      case ReadinessZone.critical:
        return const TrainingModifier(
          intensityMultiplier: 0.2,
          volumeMultiplier: 0.2,
          forceRestDay: true,
          suggestedSessionType: 'rest',
          maxDurationMinutes: 20,
        );
      case ReadinessZone.low:
        return const TrainingModifier(
          intensityMultiplier: 0.4,
          volumeMultiplier: 0.4,
          suggestedSessionType: 'mobility',
          maxDurationMinutes: 30,
        );
      case ReadinessZone.moderate:
        return TrainingModifier(
          intensityMultiplier: hasWarning ? 0.6 : 0.7,
          volumeMultiplier: 0.7,
          suggestedSessionType: 'technical',
          maxDurationMinutes: 60,
        );
      case ReadinessZone.good:
        return const TrainingModifier(
          intensityMultiplier: 1.0,
          volumeMultiplier: 1.0,
          suggestedSessionType: 'sparring',
          maxDurationMinutes: 90,
        );
      case ReadinessZone.peak:
        return const TrainingModifier(
          intensityMultiplier: 1.2,
          volumeMultiplier: 1.1,
          suggestedSessionType: 'sparring',
          maxDurationMinutes: 120,
        );
    }
  }

  List<BotDirective> _generateDirectives(
    ReadinessResult readiness,
    List<BiometricAlert> alerts,
    TrainingModifier modifier,
  ) {
    final directives = <BotDirective>[];

    // Shido: always gets readiness data for periodization adjustment
    directives.add(
      BotDirective(
        target: BotDirectiveTarget.shido,
        action: 'adjust_periodization',
        payload: {
          'readinessScore': readiness.overallScore,
          'zone': readiness.zone.label,
          'intensityMul': modifier.intensityMultiplier,
          'topLimiter': readiness.topLimiter,
        },
        reason:
            'Auto-adjust periodization based on readiness ${readiness.overallScore.toStringAsFixed(0)}',
      ),
    );

    // Camp Coach: training plan adjustment
    directives.add(
      BotDirective(
        target: BotDirectiveTarget.campCoach,
        action: 'modify_session',
        payload: {
          'sessionType': modifier.suggestedSessionType,
          'maxMinutes': modifier.maxDurationMinutes,
          'volumeMul': modifier.volumeMultiplier,
          'forceRest': modifier.forceRestDay,
        },
        reason: 'Training modifier from biometric bridge',
      ),
    );

    // Shakura: safety alerts for danger conditions
    for (final alert in alerts.where((a) => a.severity == 'danger')) {
      directives.add(
        BotDirective(
          target: BotDirectiveTarget.shakura,
          action: 'send_safety_alert',
          payload: {
            'alert': alert.label,
            'severity': alert.severity,
            'explanation': alert.explanation,
          },
          reason: 'Biometric danger detected: ${alert.label}',
        ),
      );
    }

    // Blotato: nutrition adjustment when nutrition pillar is low
    final nutritionPillar = readiness.pillars
        .where((p) => p.pillar == ReadinessPillar.nutrition)
        .firstOrNull;
    if (nutritionPillar != null && nutritionPillar.normalizedScore < 50) {
      directives.add(
        BotDirective(
          target: BotDirectiveTarget.blotato,
          action: 'modify_nutrition',
          payload: {
            'nutritionScore': nutritionPillar.normalizedScore,
            'insight': nutritionPillar.insight,
          },
          reason: 'Nutrition pillar below threshold',
        ),
      );
    }

    return directives;
  }
}
