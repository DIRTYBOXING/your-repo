import 'dart:math';

/// ═══════════════════════════════════════════════════════════════════════════
/// READINESS SCORE ENGINE — Daily Performance Readiness Intelligence
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Computes a single 0–100 Readiness Score from 6 biometric + lifestyle
/// pillars: Sleep, Recovery (HRV/RHR), Training Load (ACWR), Hydration,
/// Nutrition, and Mood/Stress. Each pillar is weighted and normalized.
///
/// Consumers: DashboardScreen, ShidoWisdomEngine, FightCampCoachBot
/// ═══════════════════════════════════════════════════════════════════════════

enum ReadinessPillar {
  sleep('Sleep', 0.25, '😴'),
  recovery('Recovery', 0.20, '💚'),
  trainingLoad('Training Load', 0.20, '🏋️'),
  hydration('Hydration', 0.12, '💧'),
  nutrition('Nutrition', 0.12, '🥗'),
  mood('Mood & Stress', 0.11, '🧠');

  final String label;
  final double weight;
  final String emoji;
  const ReadinessPillar(this.label, this.weight, this.emoji);
}

enum ReadinessZone {
  critical('Critical', 'Rest day recommended', 0, 30),
  low('Low', 'Light active recovery only', 30, 50),
  moderate('Moderate', 'Reduced intensity training', 50, 70),
  good('Good', 'Normal training load', 70, 85),
  peak('Peak', 'Push hard — you are primed', 85, 100);

  final String label;
  final String guidance;
  final double min;
  final double max;
  const ReadinessZone(this.label, this.guidance, this.min, this.max);

  static ReadinessZone fromScore(double score) {
    if (score >= peak.min) return peak;
    if (score >= good.min) return good;
    if (score >= moderate.min) return moderate;
    if (score >= low.min) return low;
    return critical;
  }
}

class PillarScore {
  final ReadinessPillar pillar;
  final double rawValue;
  final double normalizedScore; // 0–100
  final double weightedContribution; // pillar.weight * normalizedScore
  final String insight;

  const PillarScore({
    required this.pillar,
    required this.rawValue,
    required this.normalizedScore,
    required this.weightedContribution,
    required this.insight,
  });
}

class ReadinessResult {
  final double overallScore; // 0–100
  final ReadinessZone zone;
  final List<PillarScore> pillars;
  final List<String> recommendations;
  final DateTime computedAt;
  final String? topLimiter; // weakest pillar label

  const ReadinessResult({
    required this.overallScore,
    required this.zone,
    required this.pillars,
    required this.recommendations,
    required this.computedAt,
    this.topLimiter,
  });

  Map<String, dynamic> toMap() => {
    'overallScore': overallScore,
    'zone': zone.label,
    'zoneGuidance': zone.guidance,
    'pillars': pillars
        .map(
          (p) => {
            'pillar': p.pillar.label,
            'rawValue': p.rawValue,
            'score': p.normalizedScore,
            'weighted': p.weightedContribution,
            'insight': p.insight,
          },
        )
        .toList(),
    'recommendations': recommendations,
    'topLimiter': topLimiter,
    'computedAt': computedAt.toIso8601String(),
  };
}

class ReadinessInput {
  // Sleep
  final double? sleepHours;
  final int? sleepScore; // 0–100 from wearable
  final double? deepSleepHours;

  // Recovery
  final int? hrvMs;
  final int? restingHR;
  final int? baselineRHR; // personal baseline
  final int? recoveryScore; // 0–100 from WHOOP/Oura

  // Training load
  final double? trainingLoad7Day;
  final double? trainingLoad28Day;
  final int? daysSinceLastSession;

  // Hydration
  final double? waterIntakeLiters;
  final double? targetWaterLiters;

  // Nutrition
  final double? caloriesConsumed;
  final double? calorieTarget;
  final double? proteinGrams;
  final double? proteinTargetGrams;

  // Mood / stress
  final int? moodRating; // 1–10 self-reported
  final int? stressLevel; // 1–10 self-reported (10 = max stress)
  final double? cortisol; // from wearable if available

  const ReadinessInput({
    this.sleepHours,
    this.sleepScore,
    this.deepSleepHours,
    this.hrvMs,
    this.restingHR,
    this.baselineRHR,
    this.recoveryScore,
    this.trainingLoad7Day,
    this.trainingLoad28Day,
    this.daysSinceLastSession,
    this.waterIntakeLiters,
    this.targetWaterLiters,
    this.caloriesConsumed,
    this.calorieTarget,
    this.proteinGrams,
    this.proteinTargetGrams,
    this.moodRating,
    this.stressLevel,
    this.cortisol,
  });
}

class ReadinessScoreEngine {
  ReadinessScoreEngine._();
  static final ReadinessScoreEngine instance = ReadinessScoreEngine._();

  ReadinessResult compute(ReadinessInput input) {
    final pillarScores = <PillarScore>[
      _scoreSleep(input),
      _scoreRecovery(input),
      _scoreTrainingLoad(input),
      _scoreHydration(input),
      _scoreNutrition(input),
      _scoreMood(input),
    ];

    final overall = pillarScores.fold<double>(
      0.0,
      (sum, p) => sum + p.weightedContribution,
    );

    // Clamp to 0–100
    final clamped = overall.clamp(0.0, 100.0);
    final zone = ReadinessZone.fromScore(clamped);

    // Top limiter = lowest scoring pillar
    final sorted = List<PillarScore>.from(pillarScores)
      ..sort((a, b) => a.normalizedScore.compareTo(b.normalizedScore));
    final limiter = sorted.first;

    final recs = _generateRecommendations(pillarScores, zone, limiter);

    return ReadinessResult(
      overallScore: clamped,
      zone: zone,
      pillars: pillarScores,
      recommendations: recs,
      computedAt: DateTime.now(),
      topLimiter: limiter.pillar.label,
    );
  }

  // ── Sleep Pillar ──────────────────────────────────────────────────────

  PillarScore _scoreSleep(ReadinessInput input) {
    double score;
    String insight;

    if (input.sleepScore != null) {
      score = input.sleepScore!.toDouble().clamp(0, 100);
      insight = 'Wearable sleep score: ${input.sleepScore}';
    } else if (input.sleepHours != null) {
      // Optimal: 7–9h. <5h = terrible, >10h = slightly diminishing
      final h = input.sleepHours!;
      if (h >= 7 && h <= 9) {
        score = 80 + ((h - 7) / 2) * 20; // 80–100
      } else if (h >= 6) {
        score = 50 + ((h - 6) * 30); // 50–80
      } else if (h >= 5) {
        score = 20 + ((h - 5) * 30); // 20–50
      } else {
        score = max(0, h / 5 * 20); // 0–20
      }

      // Deep sleep bonus: if >1.5h deep sleep, +10
      if (input.deepSleepHours != null && input.deepSleepHours! >= 1.5) {
        score = min(100, score + 10);
      }
      insight = '${h.toStringAsFixed(1)}h sleep';
      if (input.deepSleepHours != null) {
        insight += ' (${input.deepSleepHours!.toStringAsFixed(1)}h deep)';
      }
    } else {
      score = 60; // neutral default
      insight = 'No sleep data — using baseline';
    }

    return PillarScore(
      pillar: ReadinessPillar.sleep,
      rawValue: input.sleepHours ?? input.sleepScore?.toDouble() ?? 0,
      normalizedScore: score,
      weightedContribution: score * ReadinessPillar.sleep.weight,
      insight: insight,
    );
  }

  // ── Recovery Pillar ───────────────────────────────────────────────────

  PillarScore _scoreRecovery(ReadinessInput input) {
    double score;
    String insight;

    if (input.recoveryScore != null) {
      score = input.recoveryScore!.toDouble().clamp(0, 100);
      insight = 'Wearable recovery: ${input.recoveryScore}%';
    } else {
      double hrvScore = 60;
      double rhrScore = 60;

      if (input.hrvMs != null) {
        final hrv = input.hrvMs!;
        // <30 critical, 30-50 low, 50-80 ok, >80 great
        if (hrv >= 80) {
          hrvScore = 90;
        } else if (hrv >= 50) {
          hrvScore = 60 + ((hrv - 50) / 30) * 30;
        } else if (hrv >= 30) {
          hrvScore = 30 + ((hrv - 30) / 20) * 30;
        } else {
          hrvScore = hrv / 30 * 30;
        }
      }

      if (input.restingHR != null) {
        final rhr = input.restingHR!;
        final baseline = input.baselineRHR ?? 60;
        final delta = rhr - baseline;
        // Elevated RHR = poor recovery
        if (delta <= 0) {
          rhrScore = 90;
        } else if (delta <= 5) {
          rhrScore = 70;
        } else if (delta <= 10) {
          rhrScore = 45;
        } else {
          rhrScore = 20;
        }
      }

      score = (hrvScore * 0.6 + rhrScore * 0.4);
      insight =
          'HRV: ${input.hrvMs ?? "N/A"}ms, RHR: ${input.restingHR ?? "N/A"}bpm';
    }

    return PillarScore(
      pillar: ReadinessPillar.recovery,
      rawValue: input.hrvMs?.toDouble() ?? input.recoveryScore?.toDouble() ?? 0,
      normalizedScore: score,
      weightedContribution: score * ReadinessPillar.recovery.weight,
      insight: insight,
    );
  }

  // ── Training Load Pillar ──────────────────────────────────────────────

  PillarScore _scoreTrainingLoad(ReadinessInput input) {
    double score;
    String insight;

    if (input.trainingLoad7Day != null && input.trainingLoad28Day != null) {
      final chronic = input.trainingLoad28Day! / 4;
      final acwr = chronic > 0 ? input.trainingLoad7Day! / chronic : 1.0;

      // Sweet spot: 0.8–1.3
      if (acwr >= 0.8 && acwr <= 1.3) {
        score = 80 + ((1.3 - (acwr - 1.05).abs()) / 0.5) * 20;
        score = score.clamp(80, 100);
      } else if (acwr < 0.8) {
        // Detraining risk
        score = 40 + (acwr / 0.8) * 40;
      } else if (acwr <= 1.5) {
        // Elevated risk
        score = 80 - ((acwr - 1.3) / 0.2) * 40;
        score = score.clamp(40, 80);
      } else {
        // Injury danger zone >1.5
        score = max(10, 40 - ((acwr - 1.5) * 60));
      }

      insight = 'ACWR: ${acwr.toStringAsFixed(2)}';
    } else if (input.daysSinceLastSession != null) {
      final days = input.daysSinceLastSession!;
      if (days == 0) {
        score = 60; // trained today, need recovery
      } else if (days == 1) {
        score = 85;
      } else if (days == 2) {
        score = 90;
      } else if (days <= 4) {
        score = 75;
      } else {
        score = 50; // too long off
      }
      insight = '$days days since last session';
    } else {
      score = 60;
      insight = 'No training load data';
    }

    return PillarScore(
      pillar: ReadinessPillar.trainingLoad,
      rawValue: input.trainingLoad7Day ?? 0,
      normalizedScore: score,
      weightedContribution: score * ReadinessPillar.trainingLoad.weight,
      insight: insight,
    );
  }

  // ── Hydration Pillar ──────────────────────────────────────────────────

  PillarScore _scoreHydration(ReadinessInput input) {
    double score;
    String insight;

    if (input.waterIntakeLiters != null) {
      final target = input.targetWaterLiters ?? 3.0;
      final ratio = input.waterIntakeLiters! / target;
      if (ratio >= 1.0) {
        score = 95;
      } else if (ratio >= 0.8) {
        score = 70 + (ratio - 0.8) / 0.2 * 25;
      } else if (ratio >= 0.5) {
        score = 30 + (ratio - 0.5) / 0.3 * 40;
      } else {
        score = ratio / 0.5 * 30;
      }
      insight =
          '${input.waterIntakeLiters!.toStringAsFixed(1)}L / ${target.toStringAsFixed(1)}L';
    } else {
      score = 60;
      insight = 'No hydration data';
    }

    return PillarScore(
      pillar: ReadinessPillar.hydration,
      rawValue: input.waterIntakeLiters ?? 0,
      normalizedScore: score,
      weightedContribution: score * ReadinessPillar.hydration.weight,
      insight: insight,
    );
  }

  // ── Nutrition Pillar ──────────────────────────────────────────────────

  PillarScore _scoreNutrition(ReadinessInput input) {
    double score;
    String insight;

    if (input.caloriesConsumed != null && input.calorieTarget != null) {
      final calRatio = input.caloriesConsumed! / input.calorieTarget!;
      double calScore;
      // Within 10% of target = good
      if (calRatio >= 0.9 && calRatio <= 1.1) {
        calScore = 90;
      } else if (calRatio >= 0.7) {
        calScore = 50 + (calRatio - 0.7) / 0.2 * 40;
      } else {
        calScore = calRatio / 0.7 * 50;
      }

      double proteinScore = 60;
      if (input.proteinGrams != null && input.proteinTargetGrams != null) {
        final pRatio = input.proteinGrams! / input.proteinTargetGrams!;
        proteinScore = pRatio >= 1.0 ? 95 : (pRatio * 95).clamp(0, 95);
      }

      score = calScore * 0.6 + proteinScore * 0.4;
      insight =
          '${input.caloriesConsumed!.toInt()} / ${input.calorieTarget!.toInt()} kcal';
    } else {
      score = 60;
      insight = 'No nutrition data';
    }

    return PillarScore(
      pillar: ReadinessPillar.nutrition,
      rawValue: input.caloriesConsumed ?? 0,
      normalizedScore: score,
      weightedContribution: score * ReadinessPillar.nutrition.weight,
      insight: insight,
    );
  }

  // ── Mood & Stress Pillar ──────────────────────────────────────────────

  PillarScore _scoreMood(ReadinessInput input) {
    double score;
    String insight;

    if (input.moodRating != null || input.stressLevel != null) {
      final moodScore = input.moodRating != null
          ? (input.moodRating! / 10) * 100
          : 60.0;
      final stressScore = input.stressLevel != null
          ? ((10 - input.stressLevel!) / 10) * 100
          : 60.0;

      score = moodScore * 0.5 + stressScore * 0.5;

      final parts = <String>[];
      if (input.moodRating != null) parts.add('Mood: ${input.moodRating}/10');
      if (input.stressLevel != null) {
        parts.add('Stress: ${input.stressLevel}/10');
      }
      insight = parts.join(', ');
    } else if (input.cortisol != null) {
      // Cortisol: healthy morning ~10-20 µg/dL, >25 = stressed
      final c = input.cortisol!;
      if (c <= 15) {
        score = 90;
      } else if (c <= 20) {
        score = 70;
      } else if (c <= 25) {
        score = 50;
      } else {
        score = max(10, 50 - (c - 25) * 4);
      }
      insight = 'Cortisol: ${c.toStringAsFixed(1)} µg/dL';
    } else {
      score = 60;
      insight = 'No mood/stress data';
    }

    return PillarScore(
      pillar: ReadinessPillar.mood,
      rawValue: input.moodRating?.toDouble() ?? 0,
      normalizedScore: score,
      weightedContribution: score * ReadinessPillar.mood.weight,
      insight: insight,
    );
  }

  // ── Recommendation Generator ──────────────────────────────────────────

  List<String> _generateRecommendations(
    List<PillarScore> pillars,
    ReadinessZone zone,
    PillarScore limiter,
  ) {
    final recs = <String>[];

    // Zone-level guidance
    switch (zone) {
      case ReadinessZone.critical:
        recs.add('Complete rest day — prioritize sleep and hydration');
        break;
      case ReadinessZone.low:
        recs.add('Light activity only: walking, stretching, mobility work');
        break;
      case ReadinessZone.moderate:
        recs.add('Train at 60-70% intensity — focus on technique over power');
        break;
      case ReadinessZone.good:
        recs.add('Normal training — follow your program');
        break;
      case ReadinessZone.peak:
        recs.add('You\'re primed — push hard, this is a green-light day');
        break;
    }

    // Pillar-specific notes for low scores
    for (final p in pillars) {
      if (p.normalizedScore < 50) {
        switch (p.pillar) {
          case ReadinessPillar.sleep:
            recs.add(
              'Sleep deficit detected — aim for 8+ hours tonight, limit screens before bed',
            );
            break;
          case ReadinessPillar.recovery:
            recs.add(
              'Recovery low — consider contrast therapy, reduce training volume today',
            );
            break;
          case ReadinessPillar.trainingLoad:
            recs.add(
              'Training load imbalanced — adjust volume to stay in ACWR sweet spot (0.8–1.3)',
            );
            break;
          case ReadinessPillar.hydration:
            recs.add(
              'Dehydrated — drink 500mL now and continue sipping throughout the day',
            );
            break;
          case ReadinessPillar.nutrition:
            recs.add(
              'Nutritional gap — prioritize protein intake and hit calorie targets',
            );
            break;
          case ReadinessPillar.mood:
            recs.add(
              'Elevated stress — try 10 min breathwork or meditation before training',
            );
            break;
        }
      }
    }

    if (recs.length == 1) {
      recs.add('All pillars looking solid — maintain your routine');
    }

    return recs;
  }
}
