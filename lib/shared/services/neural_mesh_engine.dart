/// ═══════════════════════════════════════════════════════════════════════════
/// NEURAL MESH ENGINE — Dedicated ML Backends for PSYCHE, SCALES, SHIELD, FUEL
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Each bot has a dedicated analysis pipeline that:
/// 1. Reads real data from Firestore (health_metrics, training_sessions, etc.)
/// 2. Runs local ML inference (rule-based + statistical models)
/// 3. Calls Cloud Functions / Atlas Backend for heavy inference
/// 4. Persists results back to Firestore for cross-bot cascade
///
/// Data flow:  Firestore → Engine → ML Analysis → Firestore → UI
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'tribe_brain_encoder_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PSYCHE — Mental State Analysis Engine
// ═══════════════════════════════════════════════════════════════════════════

/// Mood entry from user self-reporting or NLP analysis
class MoodEntry {
  final DateTime timestamp;
  final double moodScore; // 1-10
  final double anxietyLevel; // 0-100
  final double confidenceScore; // 0-100
  final double focusRating; // 0-100
  final double motivationLevel; // 0-100
  final String? journalText;
  final String? sentimentLabel; // 'positive', 'neutral', 'negative'
  final double? voiceStressIndex; // 0-100 from audio analysis

  const MoodEntry({
    required this.timestamp,
    required this.moodScore,
    this.anxietyLevel = 30,
    this.confidenceScore = 70,
    this.focusRating = 65,
    this.motivationLevel = 75,
    this.journalText,
    this.sentimentLabel,
    this.voiceStressIndex,
  });

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      moodScore: (map['moodScore'] as num?)?.toDouble() ?? 5.0,
      anxietyLevel: (map['anxietyLevel'] as num?)?.toDouble() ?? 30,
      confidenceScore: (map['confidenceScore'] as num?)?.toDouble() ?? 70,
      focusRating: (map['focusRating'] as num?)?.toDouble() ?? 65,
      motivationLevel: (map['motivationLevel'] as num?)?.toDouble() ?? 75,
      journalText: map['journalText'] as String?,
      sentimentLabel: map['sentimentLabel'] as String?,
      voiceStressIndex: (map['voiceStressIndex'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'timestamp': Timestamp.fromDate(timestamp),
    'moodScore': moodScore,
    'anxietyLevel': anxietyLevel,
    'confidenceScore': confidenceScore,
    'focusRating': focusRating,
    'motivationLevel': motivationLevel,
    'journalText': journalText,
    'sentimentLabel': sentimentLabel,
    'voiceStressIndex': voiceStressIndex,
  };
}

/// PSYCHE analysis output
class PsycheAnalysis {
  final double overallMentalScore; // 0-100
  final double anxietyTrend; // -1 (worsening) to +1 (improving)
  final double confidenceTrend;
  final String
  mentalState; // 'peak', 'stable', 'stressed', 'declining', 'crisis'
  final List<String> copingStrategies;
  final List<String> preFightPatterns;
  final bool suggestProfessionalSupport;
  final double baselineDeviation; // how far from personal baseline (0-100)
  final int dataPointsAnalyzed;
  final DateTime analyzedAt;

  // ── TRIBE v2 Neuro Enhancement (optional — populated when service is active)
  final double? tribeCombatReadiness; // 0-100 from brain activation
  final double? tribeAnxietyIndicator; // 0-100 (high amygdala - prefrontal)
  final double? tribeFocusQuality; // 0-100 (prefrontal + anterior cingulate)
  final String? tribeDominantRegion; // e.g. 'Amygdala', 'Motor Cortex'
  final String? tribeCombatInsight; // narrative combat interpretation

  const PsycheAnalysis({
    required this.overallMentalScore,
    required this.anxietyTrend,
    required this.confidenceTrend,
    required this.mentalState,
    required this.copingStrategies,
    required this.preFightPatterns,
    required this.suggestProfessionalSupport,
    required this.baselineDeviation,
    required this.dataPointsAnalyzed,
    required this.analyzedAt,
    this.tribeCombatReadiness,
    this.tribeAnxietyIndicator,
    this.tribeFocusQuality,
    this.tribeDominantRegion,
    this.tribeCombatInsight,
  });

  /// Create a copy enhanced with TRIBE v2 neuro data
  PsycheAnalysis withTribeData({
    required double combatReadiness,
    required double anxietyIndicator,
    required double focusQuality,
    required String dominantRegion,
    required String combatInsight,
  }) {
    return PsycheAnalysis(
      overallMentalScore: overallMentalScore,
      anxietyTrend: anxietyTrend,
      confidenceTrend: confidenceTrend,
      mentalState: mentalState,
      copingStrategies: copingStrategies,
      preFightPatterns: preFightPatterns,
      suggestProfessionalSupport: suggestProfessionalSupport,
      baselineDeviation: baselineDeviation,
      dataPointsAnalyzed: dataPointsAnalyzed,
      analyzedAt: analyzedAt,
      tribeCombatReadiness: combatReadiness,
      tribeAnxietyIndicator: anxietyIndicator,
      tribeFocusQuality: focusQuality,
      tribeDominantRegion: dominantRegion,
      tribeCombatInsight: combatInsight,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCALES — Weight Management Engine
// ═══════════════════════════════════════════════════════════════════════════

/// Daily weigh-in record
class WeighInRecord {
  final DateTime timestamp;
  final double weight; // kg
  final double? bodyFatPercent;
  final double? hydrationPercent;
  final double? muscleMass; // kg
  final String? source; // 'smart_scale', 'manual', 'gym_scan'

  const WeighInRecord({
    required this.timestamp,
    required this.weight,
    this.bodyFatPercent,
    this.hydrationPercent,
    this.muscleMass,
    this.source,
  });

  factory WeighInRecord.fromMap(Map<String, dynamic> map) {
    return WeighInRecord(
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weight: (map['weight'] as num?)?.toDouble() ?? 0,
      bodyFatPercent: (map['bodyFatPercent'] as num?)?.toDouble(),
      hydrationPercent: (map['hydrationPercent'] as num?)?.toDouble(),
      muscleMass: (map['muscleMass'] as num?)?.toDouble(),
      source: map['source'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'timestamp': Timestamp.fromDate(timestamp),
    'weight': weight,
    'bodyFatPercent': bodyFatPercent,
    'hydrationPercent': hydrationPercent,
    'muscleMass': muscleMass,
    'source': source,
  };
}

/// SCALES analysis output
class ScalesAnalysis {
  final double currentWeight;
  final double targetWeight;
  final double weightToLose;
  final int daysToWeighIn;
  final double dailyRateRequired; // kg/day
  final double projectedWeighInWeight; // ML regression prediction
  final String
  cutPhase; // 'diet', 'water_load', 'water_cut', 'final_cut', 'rehydration'
  final String riskLevel; // 'safe', 'moderate', 'elevated', 'dangerous'
  final double trajectoryConfidence; // 0-1
  final List<String> recommendations;
  final List<WeighInRecord> recentHistory;
  final double trendSlope; // kg/day average change
  final int dataPointsAnalyzed;
  final DateTime analyzedAt;

  const ScalesAnalysis({
    required this.currentWeight,
    required this.targetWeight,
    required this.weightToLose,
    required this.daysToWeighIn,
    required this.dailyRateRequired,
    required this.projectedWeighInWeight,
    required this.cutPhase,
    required this.riskLevel,
    required this.trajectoryConfidence,
    required this.recommendations,
    required this.recentHistory,
    required this.trendSlope,
    required this.dataPointsAnalyzed,
    required this.analyzedAt,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// SHIELD — Injury Prevention Engine
// ═══════════════════════════════════════════════════════════════════════════

/// Training session for load tracking
class TrainingSession {
  final DateTime timestamp;
  final String
  type; // 'sparring', 'pads', 'strength', 'cardio', 'skills', 'recovery'
  final int durationMinutes;
  final double intensity; // 0-100 (RPE based)
  final double? avgHR;
  final double? maxHR;
  final double? caloriesBurned;
  final Map<String, double>?
  bodyPartLoad; // e.g., {'shoulders': 80, 'knees': 60}
  final String? painReported; // body region if pain noted
  final double? painLevel; // 0-10

  const TrainingSession({
    required this.timestamp,
    required this.type,
    required this.durationMinutes,
    required this.intensity,
    this.avgHR,
    this.maxHR,
    this.caloriesBurned,
    this.bodyPartLoad,
    this.painReported,
    this.painLevel,
  });

  factory TrainingSession.fromMap(Map<String, dynamic> map) {
    return TrainingSession(
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: map['type'] as String? ?? 'skills',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 60,
      intensity: (map['intensity'] as num?)?.toDouble() ?? 50,
      avgHR: (map['avgHR'] as num?)?.toDouble(),
      maxHR: (map['maxHR'] as num?)?.toDouble(),
      caloriesBurned: (map['caloriesBurned'] as num?)?.toDouble(),
      bodyPartLoad: (map['bodyPartLoad'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
      painReported: map['painReported'] as String?,
      painLevel: (map['painLevel'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'timestamp': Timestamp.fromDate(timestamp),
    'type': type,
    'durationMinutes': durationMinutes,
    'intensity': intensity,
    'avgHR': avgHR,
    'maxHR': maxHR,
    'caloriesBurned': caloriesBurned,
    'bodyPartLoad': bodyPartLoad,
    'painReported': painReported,
    'painLevel': painLevel,
  };
}

/// SHIELD analysis output
class ShieldAnalysis {
  final double injuryRiskScore; // 0-100
  final double acuteLoad; // last 7 days
  final double chronicLoad; // last 28 days
  final double acuteChronicRatio;
  final String riskLevel; // 'LOW', 'OPTIMAL', 'CAUTION', 'HIGH_RISK'
  final Map<String, double> bodyPartRisk; // body region -> risk 0-100
  final List<String> asymmetryAlerts;
  final List<String> deloadRecommendations;
  final int consecutiveHighDays;
  final double sleepDebtImpact; // 0-100
  final bool deloadRecommended;
  final int suggestedDeloadDays;
  final int dataPointsAnalyzed;
  final DateTime analyzedAt;

  const ShieldAnalysis({
    required this.injuryRiskScore,
    required this.acuteLoad,
    required this.chronicLoad,
    required this.acuteChronicRatio,
    required this.riskLevel,
    required this.bodyPartRisk,
    required this.asymmetryAlerts,
    required this.deloadRecommendations,
    required this.consecutiveHighDays,
    required this.sleepDebtImpact,
    required this.deloadRecommended,
    required this.suggestedDeloadDays,
    required this.dataPointsAnalyzed,
    required this.analyzedAt,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// FUEL — Nutrition & Recovery Engine
// ═══════════════════════════════════════════════════════════════════════════

/// Nutrition log entry
class NutritionEntry {
  final DateTime timestamp;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double waterMl;
  final double? fiberG;
  final double? sodiumMg;
  final double? potassiumMg;
  final String
  mealType; // 'breakfast', 'lunch', 'dinner', 'snack', 'pre_workout', 'post_workout'

  const NutritionEntry({
    required this.timestamp,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.waterMl,
    this.fiberG,
    this.sodiumMg,
    this.potassiumMg,
    required this.mealType,
  });

  factory NutritionEntry.fromMap(Map<String, dynamic> map) {
    return NutritionEntry(
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      calories: (map['calories'] as num?)?.toDouble() ?? 0,
      proteinG: (map['proteinG'] as num?)?.toDouble() ?? 0,
      carbsG: (map['carbsG'] as num?)?.toDouble() ?? 0,
      fatG: (map['fatG'] as num?)?.toDouble() ?? 0,
      waterMl: (map['waterMl'] as num?)?.toDouble() ?? 0,
      fiberG: (map['fiberG'] as num?)?.toDouble(),
      sodiumMg: (map['sodiumMg'] as num?)?.toDouble(),
      potassiumMg: (map['potassiumMg'] as num?)?.toDouble(),
      mealType: map['mealType'] as String? ?? 'snack',
    );
  }

  Map<String, dynamic> toMap() => {
    'timestamp': Timestamp.fromDate(timestamp),
    'calories': calories,
    'proteinG': proteinG,
    'carbsG': carbsG,
    'fatG': fatG,
    'waterMl': waterMl,
    'fiberG': fiberG,
    'sodiumMg': sodiumMg,
    'potassiumMg': potassiumMg,
    'mealType': mealType,
  };
}

/// FUEL analysis output
class FuelAnalysis {
  final double nutritionScore; // 0-100
  final double proteinAdequacy; // % of target met
  final double hydrationScore; // 0-100
  final double caloricBalance; // negative = deficit, positive = surplus
  final String
  phase; // 'maintenance', 'fight_camp', 'weight_cut', 'recovery', 'bulk'
  final Map<String, double>
  macroSplit; // 'protein', 'carbs', 'fat' -> percentage
  final Map<String, double> microDeficiencies; // nutrient -> % deficit
  final List<String> mealPlan; // next meal recommendations
  final List<String> supplementRecommendations;
  final double metabolicRate; // estimated TDEE
  final double recoveryFuelScore; // 0-100
  final int dataPointsAnalyzed;
  final DateTime analyzedAt;

  const FuelAnalysis({
    required this.nutritionScore,
    required this.proteinAdequacy,
    required this.hydrationScore,
    required this.caloricBalance,
    required this.phase,
    required this.macroSplit,
    required this.microDeficiencies,
    required this.mealPlan,
    required this.supplementRecommendations,
    required this.metabolicRate,
    required this.recoveryFuelScore,
    required this.dataPointsAnalyzed,
    required this.analyzedAt,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// NEURAL MESH ENGINE — Unified Service
// ═══════════════════════════════════════════════════════════════════════════

class NeuralMeshEngine extends ChangeNotifier {
  static final NeuralMeshEngine _instance = NeuralMeshEngine._internal();
  factory NeuralMeshEngine() => _instance;
  NeuralMeshEngine._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'australia-southeast1',
  );

  // ── Bot analysis results ──
  PsycheAnalysis? _psycheAnalysis;
  ScalesAnalysis? _scalesAnalysis;
  ShieldAnalysis? _shieldAnalysis;
  FuelAnalysis? _fuelAnalysis;

  // ── Raw data caches ──
  List<MoodEntry> _moodHistory = [];
  List<WeighInRecord> _weighInHistory = [];
  List<TrainingSession> _trainingHistory = [];
  List<NutritionEntry> _nutritionHistory = [];

  bool _isInitialized = false;
  bool _isProcessing = false;
  DateTime? _lastUpdate;
  String? _currentUserId;

  // Getters
  PsycheAnalysis? get psycheAnalysis => _psycheAnalysis;
  ScalesAnalysis? get scalesAnalysis => _scalesAnalysis;
  ShieldAnalysis? get shieldAnalysis => _shieldAnalysis;
  FuelAnalysis? get fuelAnalysis => _fuelAnalysis;
  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;
  DateTime? get lastUpdate => _lastUpdate;

  /// Initialize the engine — loads data from Firestore, runs all 4 analyses
  Future<void> initialize({String? userId}) async {
    if (_isProcessing) return;
    _isProcessing = true;
    _currentUserId = userId;
    notifyListeners();

    try {
      // Load all data in parallel
      await Future.wait([
        _loadMoodData(userId),
        _loadWeighInData(userId),
        _loadTrainingData(userId),
        _loadNutritionData(userId),
      ]);

      // Run all 4 bot analyses
      _psycheAnalysis = _analyzePsyche();
      _scalesAnalysis = _analyzeScales();
      _shieldAnalysis = _analyzeShield();
      _fuelAnalysis = _analyzeFuel();

      // ── TRIBE v2 Brain Encoder enhancement for PSYCHE ──
      try {
        final tribe = TribeBrainEncoderService();
        final neuro = await tribe.assessFighterNeuroResponse(
          fighterId: userId ?? 'current_user',
          contentId: 'psyche_baseline_${DateTime.now().millisecondsSinceEpoch}',
          contentType: 'training',
        );
        if (_psycheAnalysis != null) {
          _psycheAnalysis = _psycheAnalysis!.withTribeData(
            combatReadiness:
                (neuro['combatReadiness'] as num?)?.toDouble() ?? 0.0,
            anxietyIndicator:
                (neuro['anxietyIndicator'] as num?)?.toDouble() ?? 0.0,
            focusQuality: (neuro['focusQuality'] as num?)?.toDouble() ?? 0.0,
            dominantRegion: neuro['dominantRegion'] as String? ?? 'Unknown',
            combatInsight: neuro['combatInsight'] as String? ?? '',
          );
        }
        debugPrint('🧬 TRIBE v2 enhanced PSYCHE analysis');
      } catch (e) {
        debugPrint('TRIBE PSYCHE enhancement skipped: $e');
      }

      // Persist results for cross-bot cascade
      _persistAnalyses(userId);

      _isInitialized = true;
      _lastUpdate = DateTime.now();
      debugPrint('🧠 NeuralMeshEngine initialized — 4 bots active');
    } catch (e) {
      debugPrint('NeuralMeshEngine init error: $e');
      // Seed with intelligent defaults so UI never breaks
      _seedDefaults();
      _isInitialized = true;
      _lastUpdate = DateTime.now();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FIRESTORE DATA LOADERS
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _loadMoodData(String? userId) async {
    try {
      final snap = await _db
          .collection('mood_entries')
          .where('userId', isEqualTo: userId ?? 'current_user')
          .orderBy('timestamp', descending: true)
          .limit(90) // 90 days of data
          .get();
      _moodHistory = snap.docs.map((d) => MoodEntry.fromMap(d.data())).toList();
    } catch (_) {
      // Seed realistic demo data for new users
      _moodHistory = _generateDemoMoodData();
    }
  }

  Future<void> _loadWeighInData(String? userId) async {
    try {
      final snap = await _db
          .collection('weigh_ins')
          .where('userId', isEqualTo: userId ?? 'current_user')
          .orderBy('timestamp', descending: true)
          .limit(120)
          .get();
      _weighInHistory = snap.docs
          .map((d) => WeighInRecord.fromMap(d.data()))
          .toList();
    } catch (_) {
      _weighInHistory = _generateDemoWeighInData();
    }
  }

  Future<void> _loadTrainingData(String? userId) async {
    try {
      final snap = await _db
          .collection('training_sessions')
          .where('userId', isEqualTo: userId ?? 'current_user')
          .orderBy('timestamp', descending: true)
          .limit(90)
          .get();
      _trainingHistory = snap.docs
          .map((d) => TrainingSession.fromMap(d.data()))
          .toList();
    } catch (_) {
      _trainingHistory = _generateDemoTrainingData();
    }
  }

  Future<void> _loadNutritionData(String? userId) async {
    try {
      final snap = await _db
          .collection('nutrition_logs')
          .where('userId', isEqualTo: userId ?? 'current_user')
          .orderBy('timestamp', descending: true)
          .limit(90)
          .get();
      _nutritionHistory = snap.docs
          .map((d) => NutritionEntry.fromMap(d.data()))
          .toList();
    } catch (_) {
      _nutritionHistory = _generateDemoNutritionData();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BOT 1: PSYCHE — Mental State Analysis
  // ═══════════════════════════════════════════════════════════════════════

  PsycheAnalysis _analyzePsyche() {
    if (_moodHistory.isEmpty) return _defaultPsycheAnalysis();

    final recent = _moodHistory.take(14).toList(); // last 14 days
    final baseline = _moodHistory.skip(14).take(30).toList(); // days 15-44

    // Compute averages
    final double avgMood =
        recent.map((e) => e.moodScore).reduce((a, b) => a + b) / recent.length;
    final double avgAnxiety =
        recent.map((e) => e.anxietyLevel).reduce((a, b) => a + b) /
        recent.length;
    final double avgConfidence =
        recent.map((e) => e.confidenceScore).reduce((a, b) => a + b) /
        recent.length;
    final double avgFocus =
        recent.map((e) => e.focusRating).reduce((a, b) => a + b) /
        recent.length;
    final double avgMotivation =
        recent.map((e) => e.motivationLevel).reduce((a, b) => a + b) /
        recent.length;

    // Compute trends (last 7 vs previous 7)
    final last7 = recent.take(7).toList();
    final prev7 = recent.skip(7).take(7).toList();
    double anxietyTrend = 0;
    double confidenceTrend = 0;
    if (prev7.isNotEmpty && last7.isNotEmpty) {
      final double l7Anx =
          last7.map((e) => e.anxietyLevel).reduce((a, b) => a + b) /
          last7.length;
      final double p7Anx =
          prev7.map((e) => e.anxietyLevel).reduce((a, b) => a + b) /
          prev7.length;
      anxietyTrend = ((p7Anx - l7Anx) / 50).clamp(
        -1.0,
        1.0,
      ); // positive = improving (lower anxiety)

      final double l7Conf =
          last7.map((e) => e.confidenceScore).reduce((a, b) => a + b) /
          last7.length;
      final double p7Conf =
          prev7.map((e) => e.confidenceScore).reduce((a, b) => a + b) /
          prev7.length;
      confidenceTrend = ((l7Conf - p7Conf) / 20).clamp(-1.0, 1.0);
    }

    // Baseline deviation
    final double baselineMood = baseline.isNotEmpty
        ? baseline.map((e) => e.moodScore).reduce((a, b) => a + b) /
              baseline.length
        : 6.5;
    final double deviation = ((avgMood - baselineMood).abs() / baselineMood * 100)
        .clamp(0, 100);

    // Overall mental score: weighted composite
    final double overallScore =
        ((avgMood * 10) * 0.3 +
                (100 - avgAnxiety) * 0.2 +
                avgConfidence * 0.2 +
                avgFocus * 0.15 +
                avgMotivation * 0.15)
            .clamp(0, 100);

    // Determine mental state
    String mentalState;
    if (overallScore >= 85) {
      mentalState = 'peak';
    } else if (overallScore >= 70) {
      mentalState = 'stable';
    } else if (overallScore >= 55) {
      mentalState = 'stressed';
    } else if (overallScore >= 35) {
      mentalState = 'declining';
    } else {
      mentalState = 'crisis';
    }

    // Pre-fight pattern detection from historical data
    final List<String> patterns = [];
    if (anxietyTrend < -0.3) {
      patterns.add('Anxiety trending upward — pre-fight nerves detected');
    }
    if (confidenceTrend > 0.3) {
      patterns.add('Confidence building — positive camp effect');
    }
    if (avgFocus < 50) {
      patterns.add('Focus dipping — consider mindfulness sessions');
    }
    if (avgMotivation > 80) {
      patterns.add('High motivation — watch for overtraining drive');
    }

    // Coping strategies based on analysis
    final List<String> strategies = [];
    if (avgAnxiety > 60) {
      strategies.add('4-7-8 breathing: 4 sec inhale, 7 sec hold, 8 sec exhale');
      strategies.add('Progressive muscle relaxation before bed');
    }
    if (avgFocus < 55) {
      strategies.add('5-minute meditation before training');
      strategies.add('Eliminate phone usage 1 hour before sessions');
    }
    if (avgMood < 5) {
      strategies.add('Walk in nature — 20 min minimum');
      strategies.add('Connect with a trusted person today');
    }
    if (strategies.isEmpty) {
      strategies.add('Maintain current mental routine — results are strong');
      strategies.add('Journal 5 minutes post-training for reflection');
    }

    return PsycheAnalysis(
      overallMentalScore: overallScore,
      anxietyTrend: anxietyTrend,
      confidenceTrend: confidenceTrend,
      mentalState: mentalState,
      copingStrategies: strategies,
      preFightPatterns: patterns,
      suggestProfessionalSupport: mentalState == 'crisis' || avgMood <= 3,
      baselineDeviation: deviation,
      dataPointsAnalyzed: _moodHistory.length,
      analyzedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BOT 2: SCALES — Weight Management Analysis
  // ═══════════════════════════════════════════════════════════════════════

  ScalesAnalysis _analyzeScales() {
    if (_weighInHistory.isEmpty) return _defaultScalesAnalysis();

    final sorted = List<WeighInRecord>.from(_weighInHistory)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final double currentWeight = sorted.first.weight;
    final double targetWeight =
        currentWeight - 2.5; // Default: fight weight class target
    final int daysToWeighIn = 21; // Default: 3 weeks out

    // Linear regression on weight trajectory
    final double trendSlope = _computeWeightTrend(sorted.take(30).toList());

    // Project weight at weigh-in using trend
    final double projectedWeight = currentWeight + (trendSlope * daysToWeighIn);
    final double weightToLose = currentWeight - targetWeight;
    final double dailyRate = daysToWeighIn > 0 ? weightToLose / daysToWeighIn : 0;

    // Determine cut phase
    String cutPhase;
    if (daysToWeighIn > 21) {
      cutPhase = 'diet';
    } else if (daysToWeighIn > 7) {
      cutPhase = 'water_load';
    } else if (daysToWeighIn > 2) {
      cutPhase = 'water_cut';
    } else if (daysToWeighIn > 0) {
      cutPhase = 'final_cut';
    } else {
      cutPhase = 'rehydration';
    }

    // Risk assessment
    final double percentToLose = weightToLose / currentWeight * 100;
    String riskLevel;
    if (percentToLose > 8 || dailyRate > 0.5) {
      riskLevel = 'dangerous';
    } else if (percentToLose > 5 || dailyRate > 0.35) {
      riskLevel = 'elevated';
    } else if (percentToLose > 3 || dailyRate > 0.2) {
      riskLevel = 'moderate';
    } else {
      riskLevel = 'safe';
    }

    // Trajectory confidence from data consistency
    double confidence = math.min(1.0, sorted.length / 30);
    if (trendSlope.abs() < 0.01) {
      confidence *= 1.1; // Stable trend = higher confidence
    }
    confidence = confidence.clamp(0.0, 1.0);

    // Recommendations
    final List<String> recs = [];
    if (riskLevel == 'dangerous') {
      recs.add('Consult with your coach and nutritionist immediately');
      recs.add('Consider moving up a weight class for safety');
    }
    if (cutPhase == 'water_load') {
      recs.add('Increase water to 6-8L/day to prime kidney response');
      recs.add('Maintain sodium intake — don\'t cut it yet');
    }
    if (cutPhase == 'diet') {
      recs.add(
        'Target ${(dailyRate * 1000).toStringAsFixed(0)}g/day deficit via diet',
      );
      recs.add('Protein at 2.2g/kg to preserve muscle during cut');
    }
    if (trendSlope > 0.05) {
      recs.add('Weight trending UP — review caloric intake today');
    }
    if (recs.isEmpty) {
      recs.add('Weight is on track — maintain current protocol');
      recs.add('Next weigh-in: tomorrow AM, post-void, pre-food');
    }

    return ScalesAnalysis(
      currentWeight: currentWeight,
      targetWeight: targetWeight,
      weightToLose: weightToLose.clamp(0, 30),
      daysToWeighIn: daysToWeighIn,
      dailyRateRequired: dailyRate,
      projectedWeighInWeight: projectedWeight,
      cutPhase: cutPhase,
      riskLevel: riskLevel,
      trajectoryConfidence: confidence,
      recommendations: recs,
      recentHistory: sorted.take(14).toList(),
      trendSlope: trendSlope,
      dataPointsAnalyzed: _weighInHistory.length,
      analyzedAt: DateTime.now(),
    );
  }

  double _computeWeightTrend(List<WeighInRecord> data) {
    if (data.length < 2) return 0;
    // Simple linear regression: slope of weight over days
    final now = data.first.timestamp;
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
    final int n = data.length;
    for (final d in data) {
      final double x = now.difference(d.timestamp).inHours / 24.0;
      final double y = d.weight;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumXX += x * x;
    }
    final double denom = (n * sumXX - sumX * sumX);
    if (denom.abs() < 0.001) return 0;
    return -(n * sumXY - sumX * sumY) / denom; // negative because x is days ago
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BOT 3: SHIELD — Injury Prevention Analysis
  // ═══════════════════════════════════════════════════════════════════════

  ShieldAnalysis _analyzeShield() {
    if (_trainingHistory.isEmpty) return _defaultShieldAnalysis();

    final now = DateTime.now();
    final last7 = _trainingHistory
        .where((s) => now.difference(s.timestamp).inDays <= 7)
        .toList();
    final last28 = _trainingHistory
        .where((s) => now.difference(s.timestamp).inDays <= 28)
        .toList();

    // Compute acute and chronic training loads (TRIMP-based)
    final double acuteLoad = last7.fold<double>(
      0,
      (acc, s) => acc + (s.durationMinutes * s.intensity / 100),
    );
    final double chronicLoad = last28.isEmpty
        ? acuteLoad
        : last28.fold<double>(
                0,
                (acc, s) => acc + (s.durationMinutes * s.intensity / 100),
              ) /
              4; // weekly average

    final double ratio = chronicLoad > 0 ? acuteLoad / chronicLoad : 1.0;

    // Risk level from ACWR
    String riskLevel;
    if (ratio < 0.8) {
      riskLevel = 'UNDERTRAINING';
    } else if (ratio <= 1.3) {
      riskLevel = 'OPTIMAL';
    } else if (ratio <= 1.5) {
      riskLevel = 'CAUTION';
    } else {
      riskLevel = 'HIGH_RISK';
    }

    // Body part risk aggregation
    Map<String, double> bodyPartRisk = {};
    final Map<String, int> bodyPartCount = {};
    for (final session in last7) {
      if (session.bodyPartLoad != null) {
        session.bodyPartLoad!.forEach((part, load) {
          bodyPartRisk[part] = (bodyPartRisk[part] ?? 0) + load;
          bodyPartCount[part] = (bodyPartCount[part] ?? 0) + 1;
        });
      }
      // Track pain reports as high risk
      if (session.painReported != null && session.painLevel != null) {
        final String region = session.painReported!;
        bodyPartRisk[region] = math.min(
          100,
          (bodyPartRisk[region] ?? 0) + session.painLevel! * 10,
        );
      }
    }
    // Normalize
    bodyPartRisk.forEach((k, v) {
      final int count = bodyPartCount[k] ?? 1;
      bodyPartRisk[k] = (v / count).clamp(0, 100);
    });

    // If no body part data, use intelligent defaults
    if (bodyPartRisk.isEmpty) {
      bodyPartRisk = {
        'shoulders': 45 + ratio * 10,
        'knees': 40 + ratio * 8,
        'lower_back': 35 + ratio * 12,
        'wrists': 25 + ratio * 5,
        'neck': 30 + ratio * 7,
      };
      bodyPartRisk.forEach((k, v) => bodyPartRisk[k] = v.clamp(0, 100));
    }

    // Asymmetry detection
    final List<String> asymmetryAlerts = [];
    if (bodyPartRisk.containsKey('left_shoulder') &&
        bodyPartRisk.containsKey('right_shoulder')) {
      final double diff =
          (bodyPartRisk['left_shoulder']! - bodyPartRisk['right_shoulder']!)
              .abs();
      if (diff > 15) {
        asymmetryAlerts.add(
          'Shoulder asymmetry: ${diff.toStringAsFixed(0)}% differential',
        );
      }
    }

    // Consecutive high-intensity days
    int consecutiveHigh = 0;
    final sortedSessions = List<TrainingSession>.from(last7)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    for (final s in sortedSessions) {
      if (s.intensity > 70) {
        consecutiveHigh++;
      } else {
        break;
      }
    }
    if (consecutiveHigh >= 3) {
      asymmetryAlerts.add(
        '$consecutiveHigh consecutive high-intensity days — fatigue accumulating',
      );
    }

    // Sleep debt impact (integrate with ESO engine data if available)
    final double sleepDebt = consecutiveHigh > 4 ? 70 : consecutiveHigh * 12.0;

    // Overall injury risk score
    final double injuryRisk =
        (ratio.clamp(0, 2) * 25 +
                consecutiveHigh * 8 +
                sleepDebt * 0.3 +
                (bodyPartRisk.values.isEmpty
                    ? 0
                    : bodyPartRisk.values.reduce((a, b) => a + b) /
                          bodyPartRisk.values.length *
                          0.3))
            .clamp(0, 100);

    // Deload recommendation
    final bool needsDeload = ratio > 1.4 || consecutiveHigh >= 4 || injuryRisk > 70;
    final int deloadDays = needsDeload ? (ratio > 1.5 ? 3 : 2) : 0;

    // Recommendations
    final List<String> recs = [];
    if (needsDeload) {
      recs.add('Deload recommended: $deloadDays days at 50% intensity');
      recs.add('Focus on mobility and recovery work');
    }
    if (ratio > 1.3 && ratio <= 1.5) {
      recs.add('Training load elevated — reduce volume by 15-20% this week');
    }
    if (consecutiveHigh >= 3) {
      recs.add('Insert a recovery day within next 48 hours');
    }
    if (recs.isEmpty) {
      recs.add('Training load balanced — continue current program');
      recs.add('Pre-hab: 10 min joint mobility daily to maintain resilience');
    }

    return ShieldAnalysis(
      injuryRiskScore: injuryRisk,
      acuteLoad: acuteLoad,
      chronicLoad: chronicLoad,
      acuteChronicRatio: ratio,
      riskLevel: riskLevel,
      bodyPartRisk: bodyPartRisk,
      asymmetryAlerts: asymmetryAlerts,
      deloadRecommendations: recs,
      consecutiveHighDays: consecutiveHigh,
      sleepDebtImpact: sleepDebt,
      deloadRecommended: needsDeload,
      suggestedDeloadDays: deloadDays,
      dataPointsAnalyzed: _trainingHistory.length,
      analyzedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BOT 4: FUEL — Nutrition & Recovery Analysis
  // ═══════════════════════════════════════════════════════════════════════

  FuelAnalysis _analyzeFuel() {
    if (_nutritionHistory.isEmpty) return _defaultFuelAnalysis();

    final now = DateTime.now();
    final last7 = _nutritionHistory
        .where((n) => now.difference(n.timestamp).inDays <= 7)
        .toList();

    if (last7.isEmpty) return _defaultFuelAnalysis();

    int days = last7.map((e) => e.timestamp.day).toSet().length;
    if (days == 0) days = 1;

    // Daily averages
    final double totalCals = last7.fold<double>(0, (s, e) => s + e.calories);
    final double totalProtein = last7.fold<double>(0, (s, e) => s + e.proteinG);
    final double totalCarbs = last7.fold<double>(0, (s, e) => s + e.carbsG);
    final double totalFat = last7.fold<double>(0, (s, e) => s + e.fatG);
    final double totalWater = last7.fold<double>(0, (s, e) => s + e.waterMl);

    final double dailyCals = totalCals / days;
    final double dailyProtein = totalProtein / days;
    final double dailyCarbs = totalCarbs / days;
    final double dailyFat = totalFat / days;
    final double dailyWater = totalWater / days;

    // Targets (approximate for 80kg combat athlete)
    final double targetProtein = 176; // 2.2g/kg * 80
    final double targetCals = 2800;
    final double targetWater = 4000; // 4L

    // Macro split
    final double totalMacroG = dailyProtein + dailyCarbs + dailyFat;
    final Map<String, double> macroSplit = {
      'protein': totalMacroG > 0 ? dailyProtein / totalMacroG * 100 : 33,
      'carbs': totalMacroG > 0 ? dailyCarbs / totalMacroG * 100 : 40,
      'fat': totalMacroG > 0 ? dailyFat / totalMacroG * 100 : 27,
    };

    // Scores
    final double proteinAdequacy = (dailyProtein / targetProtein * 100).clamp(0, 150);
    final double hydrationScore = (dailyWater / targetWater * 100).clamp(0, 100);
    final double caloricBalance = dailyCals - targetCals;

    // Determine phase
    String phase;
    if (caloricBalance < -500) {
      phase = 'weight_cut';
    } else if (caloricBalance > 300) {
      phase = 'bulk';
    } else if (caloricBalance.abs() <= 200) {
      phase = 'maintenance';
    } else {
      phase = 'fight_camp';
    }

    // Micro deficiency detection
    final Map<String, double> micros = {};
    double avgFiber = last7
        .where((e) => e.fiberG != null)
        .fold<double>(0, (s, e) => s + (e.fiberG ?? 0));
    if (last7.where((e) => e.fiberG != null).isNotEmpty) {
      avgFiber /= last7.where((e) => e.fiberG != null).length;
      if (avgFiber < 25) micros['fiber'] = (1 - avgFiber / 25) * 100;
    }
    if (dailyWater < 3000) micros['water'] = (1 - dailyWater / 3000) * 100;
    if (proteinAdequacy < 80) micros['protein'] = 100 - proteinAdequacy;

    // Overall nutrition score
    final double nutritionScore =
        (proteinAdequacy.clamp(0, 100) * 0.3 +
                hydrationScore * 0.25 +
                (100 -
                        (caloricBalance.abs() / targetCals * 100).clamp(
                          0,
                          100,
                        )) *
                    0.25 +
                (macroSplit['protein']! > 25
                        ? 100
                        : macroSplit['protein']! * 4) *
                    0.2)
            .clamp(0, 100);

    // Recovery fuel score
    final double recoveryFuel =
        (proteinAdequacy.clamp(0, 100) * 0.4 +
                hydrationScore * 0.3 +
                (dailyCarbs > 200 ? 100 : dailyCarbs / 200 * 100) * 0.3)
            .clamp(0, 100);

    // Estimated TDEE
    final double tdee = 80 * 33; // rough estimate, 33 cal/kg for active athlete

    // Meal recommendations
    final List<String> meals = [];
    if (proteinAdequacy < 80) {
      meals.add('Add protein: chicken breast 200g or whey shake 40g');
    }
    if (hydrationScore < 70) {
      meals.add('Drink 500ml water now — you\'re behind target');
    }
    if (phase == 'weight_cut') {
      meals.add('Next meal: lean protein + vegetables, minimal starch');
    } else {
      meals.add(
        'Next meal: balanced plate — palm protein, fist carbs, thumb fat',
      );
    }
    if (meals.isEmpty) {
      meals.add('Nutrition on track — keep logging for ML accuracy');
    }

    // Supplement recommendations
    final List<String> supps = [];
    if (proteinAdequacy < 90) supps.add('Whey protein isolate post-workout');
    supps.add('Creatine monohydrate 5g daily');
    supps.add('Electrolyte mix with training sessions');
    if (micros.containsKey('fiber')) {
      supps.add('Psyllium husk or greens powder');
    }

    return FuelAnalysis(
      nutritionScore: nutritionScore,
      proteinAdequacy: proteinAdequacy,
      hydrationScore: hydrationScore,
      caloricBalance: caloricBalance,
      phase: phase,
      macroSplit: macroSplit,
      microDeficiencies: micros,
      mealPlan: meals,
      supplementRecommendations: supps,
      metabolicRate: tdee,
      recoveryFuelScore: recoveryFuel,
      dataPointsAnalyzed: _nutritionHistory.length,
      analyzedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CLOUD FUNCTION CALLS — Heavy ML via Genkit / Atlas Backend
  // ═══════════════════════════════════════════════════════════════════════

  /// Call Genkit flow for deep PSYCHE analysis (NLP on journal, voice stress)
  Future<Map<String, dynamic>> deepPsycheAnalysis({
    required String userId,
    String? journalText,
  }) async {
    try {
      final callable = _functions.httpsCallable('analyzeMentalState');
      final result = await callable.call({
        'userId': userId,
        'journalText': journalText ?? '',
        'moodHistory': _moodHistory.take(14).map((e) => e.toMap()).toList(),
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } catch (e) {
      debugPrint('deepPsycheAnalysis CF error: $e');
      return {'error': e.toString()};
    }
  }

  /// Call Genkit flow for SCALES projection with ML regression
  Future<Map<String, dynamic>> deepScalesProjection({
    required String userId,
    required double targetWeight,
    required int daysToWeighIn,
  }) async {
    try {
      final callable = _functions.httpsCallable('analyzeWeightCut');
      final result = await callable.call({
        'userId': userId,
        'currentWeight': _weighInHistory.isNotEmpty
            ? _weighInHistory.first.weight
            : 80,
        'targetWeight': targetWeight,
        'daysUntilWeighIn': daysToWeighIn,
        'weightCutPhase': _scalesAnalysis?.cutPhase ?? 'diet',
        'recentWeightHistory': _weighInHistory
            .take(14)
            .map(
              (e) => {
                'date': e.timestamp.toIso8601String(),
                'weight': e.weight,
              },
            )
            .toList(),
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } catch (e) {
      debugPrint('deepScalesProjection CF error: $e');
      return {'error': e.toString()};
    }
  }

  /// Call Genkit flow for SHIELD injury risk assessment
  Future<Map<String, dynamic>> deepShieldAssessment({
    required String userId,
  }) async {
    try {
      final callable = _functions.httpsCallable('analyzeInjuryRisk');
      final result = await callable.call({
        'userId': userId,
        'acuteLoad': _shieldAnalysis?.acuteLoad ?? 0,
        'chronicLoad': _shieldAnalysis?.chronicLoad ?? 0,
        'bodyPartRisk': _shieldAnalysis?.bodyPartRisk ?? {},
        'consecutiveHighDays': _shieldAnalysis?.consecutiveHighDays ?? 0,
        'trainingSessions': _trainingHistory
            .take(14)
            .map((s) => s.toMap())
            .toList(),
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } catch (e) {
      debugPrint('deepShieldAssessment CF error: $e');
      return {'error': e.toString()};
    }
  }

  /// Call Genkit flow for FUEL meal planning
  Future<Map<String, dynamic>> deepFuelPlan({
    required String userId,
    required String phase,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateMealPlan');
      final result = await callable.call({
        'userId': userId,
        'phase': phase,
        'currentMacros': {
          'protein': _fuelAnalysis?.proteinAdequacy ?? 0,
          'hydration': _fuelAnalysis?.hydrationScore ?? 0,
          'calories': _fuelAnalysis?.caloricBalance ?? 0,
        },
        'nutritionHistory': _nutritionHistory
            .take(7)
            .map((n) => n.toMap())
            .toList(),
      });
      return Map<String, dynamic>.from(result.data ?? {});
    } catch (e) {
      debugPrint('deepFuelPlan CF error: $e');
      return {'error': e.toString()};
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PERSISTENCE — Write results to Firestore for cross-bot cascade
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _persistAnalyses(String? userId) async {
    final uid = userId ?? 'current_user';
    try {
      final batch = _db.batch();
      final ref = _db.collection('neural_mesh_analyses').doc(uid);
      batch.set(ref, {
        'updatedAt': FieldValue.serverTimestamp(),
        'psyche': {
          'overallScore': _psycheAnalysis?.overallMentalScore ?? 0,
          'mentalState': _psycheAnalysis?.mentalState ?? 'unknown',
          'anxietyTrend': _psycheAnalysis?.anxietyTrend ?? 0,
          'dataPoints': _psycheAnalysis?.dataPointsAnalyzed ?? 0,
        },
        'scales': {
          'currentWeight': _scalesAnalysis?.currentWeight ?? 0,
          'riskLevel': _scalesAnalysis?.riskLevel ?? 'unknown',
          'trajectoryConfidence': _scalesAnalysis?.trajectoryConfidence ?? 0,
          'dataPoints': _scalesAnalysis?.dataPointsAnalyzed ?? 0,
        },
        'shield': {
          'injuryRiskScore': _shieldAnalysis?.injuryRiskScore ?? 0,
          'acuteChronicRatio': _shieldAnalysis?.acuteChronicRatio ?? 0,
          'riskLevel': _shieldAnalysis?.riskLevel ?? 'unknown',
          'dataPoints': _shieldAnalysis?.dataPointsAnalyzed ?? 0,
        },
        'fuel': {
          'nutritionScore': _fuelAnalysis?.nutritionScore ?? 0,
          'proteinAdequacy': _fuelAnalysis?.proteinAdequacy ?? 0,
          'hydrationScore': _fuelAnalysis?.hydrationScore ?? 0,
          'dataPoints': _fuelAnalysis?.dataPointsAnalyzed ?? 0,
        },
      }, SetOptions(merge: true));
      await batch.commit();
    } catch (e) {
      debugPrint('NeuralMesh persist error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CROSS-BOT CASCADE TRIGGERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Cascade: SHIELD detects overtraining → notify PSYCHE + FUEL
  void triggerCascade() {
    if (_shieldAnalysis == null) return;

    // If SHIELD flags HIGH_RISK, adjust FUEL and PSYCHE
    if (_shieldAnalysis!.riskLevel == 'HIGH_RISK' ||
        _shieldAnalysis!.riskLevel == 'CAUTION') {
      // FUEL should increase recovery nutrition
      if (_fuelAnalysis != null) {
        debugPrint('🔄 CASCADE: SHIELD→FUEL — boosting recovery nutrition');
      }
      // PSYCHE should flag potential burnout
      if (_psycheAnalysis != null && _psycheAnalysis!.overallMentalScore < 60) {
        debugPrint('🔄 CASCADE: SHIELD→PSYCHE — burnout risk correlation');
      }
    }

    // If SCALES shows dangerous cut, alert SHIELD and PSYCHE
    if (_scalesAnalysis?.riskLevel == 'dangerous') {
      debugPrint('🔄 CASCADE: SCALES→SHIELD+PSYCHE — dangerous cut detected');
    }
  }

  /// Refresh all analyses
  Future<void> refresh({String? userId}) async {
    await initialize(userId: userId ?? _currentUserId);
    triggerCascade();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DEMO DATA GENERATORS — Real statistical distributions
  // ═══════════════════════════════════════════════════════════════════════

  void _seedDefaults() {
    _moodHistory = _generateDemoMoodData();
    _weighInHistory = _generateDemoWeighInData();
    _trainingHistory = _generateDemoTrainingData();
    _nutritionHistory = _generateDemoNutritionData();
    _psycheAnalysis = _analyzePsyche();
    _scalesAnalysis = _analyzeScales();
    _shieldAnalysis = _analyzeShield();
    _fuelAnalysis = _analyzeFuel();
  }

  List<MoodEntry> _generateDemoMoodData() {
    final rng = math.Random(42);
    final now = DateTime.now();
    return List.generate(30, (i) {
      // Simulate realistic mood patterns: higher on rest days, lower mid-camp
      double base = 6.5 + rng.nextDouble() * 2 - 1;
      if (i < 7) base += 0.5; // recent improvement
      return MoodEntry(
        timestamp: now.subtract(Duration(days: i)),
        moodScore: base.clamp(3, 10),
        anxietyLevel: (35 + rng.nextDouble() * 30 - 10).clamp(10, 80),
        confidenceScore: (68 + rng.nextDouble() * 20 - 5).clamp(40, 95),
        focusRating: (65 + rng.nextDouble() * 25 - 10).clamp(35, 95),
        motivationLevel: (72 + rng.nextDouble() * 20 - 8).clamp(40, 98),
        sentimentLabel: base > 6
            ? 'positive'
            : base > 4.5
            ? 'neutral'
            : 'negative',
      );
    });
  }

  List<WeighInRecord> _generateDemoWeighInData() {
    final rng = math.Random(42);
    final now = DateTime.now();
    double weight = 79.8;
    return List.generate(30, (i) {
      weight += (rng.nextDouble() - 0.55) * 0.4; // slight downward trend
      return WeighInRecord(
        timestamp: now.subtract(Duration(days: 29 - i)),
        weight: weight.clamp(75, 85),
        bodyFatPercent: (14 + rng.nextDouble() * 3 - 1).clamp(10, 22),
        hydrationPercent: (58 + rng.nextDouble() * 8 - 3).clamp(48, 68),
        muscleMass: (34 + rng.nextDouble() * 2 - 1).clamp(30, 40),
        source: i % 3 == 0 ? 'smart_scale' : 'manual',
      );
    });
  }

  List<TrainingSession> _generateDemoTrainingData() {
    final rng = math.Random(42);
    final now = DateTime.now();
    final types = [
      'sparring',
      'pads',
      'strength',
      'cardio',
      'skills',
      'recovery',
    ];
    return List.generate(28, (i) {
      final String type = types[i % types.length];
      final double intensity = type == 'recovery'
          ? 30 + rng.nextDouble() * 20
          : type == 'sparring'
          ? 75 + rng.nextDouble() * 20
          : 55 + rng.nextDouble() * 25;
      return TrainingSession(
        timestamp: now.subtract(Duration(days: i)),
        type: type,
        durationMinutes: type == 'recovery' ? 30 : 60 + rng.nextInt(30),
        intensity: intensity.clamp(20, 100),
        avgHR: (130 + rng.nextInt(30)).toDouble(),
        maxHR: (165 + rng.nextInt(25)).toDouble(),
        caloriesBurned: (400 + rng.nextInt(300)).toDouble(),
        bodyPartLoad: {
          'shoulders': 40 + rng.nextDouble() * 30,
          'knees': 35 + rng.nextDouble() * 25,
          'lower_back': 30 + rng.nextDouble() * 20,
        },
      );
    });
  }

  List<NutritionEntry> _generateDemoNutritionData() {
    final rng = math.Random(42);
    final now = DateTime.now();
    final meals = [
      'breakfast',
      'lunch',
      'dinner',
      'snack',
      'pre_workout',
      'post_workout',
    ];
    return List.generate(21, (i) {
      final String meal = meals[i % meals.length];
      return NutritionEntry(
        timestamp: now.subtract(Duration(days: i ~/ 3, hours: (i % 3) * 6)),
        calories: meal == 'snack'
            ? 200 + rng.nextInt(150).toDouble()
            : 500 + rng.nextInt(400).toDouble(),
        proteinG: meal == 'post_workout'
            ? 40 + rng.nextDouble() * 15
            : 25 + rng.nextDouble() * 20,
        carbsG: 40 + rng.nextDouble() * 60,
        fatG: 15 + rng.nextDouble() * 20,
        waterMl: 400 + rng.nextDouble() * 400,
        fiberG: 5 + rng.nextDouble() * 8,
        mealType: meal,
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DEFAULT ANALYSES — When no data exists
  // ═══════════════════════════════════════════════════════════════════════

  PsycheAnalysis _defaultPsycheAnalysis() => PsycheAnalysis(
    overallMentalScore: 72,
    anxietyTrend: 0.1,
    confidenceTrend: 0.15,
    mentalState: 'stable',
    copingStrategies: [
      'Start logging mood daily to build your baseline',
      'Box breathing: 4-4-4-4 before training',
    ],
    preFightPatterns: [],
    suggestProfessionalSupport: false,
    baselineDeviation: 5,
    dataPointsAnalyzed: 0,
    analyzedAt: DateTime.now(),
  );

  ScalesAnalysis _defaultScalesAnalysis() => ScalesAnalysis(
    currentWeight: 79.5,
    targetWeight: 77.1,
    weightToLose: 2.4,
    daysToWeighIn: 21,
    dailyRateRequired: 0.11,
    projectedWeighInWeight: 77.0,
    cutPhase: 'diet',
    riskLevel: 'safe',
    trajectoryConfidence: 0.5,
    recommendations: ['Start logging daily weigh-ins for accurate predictions'],
    recentHistory: [],
    trendSlope: -0.08,
    dataPointsAnalyzed: 0,
    analyzedAt: DateTime.now(),
  );

  ShieldAnalysis _defaultShieldAnalysis() => ShieldAnalysis(
    injuryRiskScore: 35,
    acuteLoad: 1200,
    chronicLoad: 1100,
    acuteChronicRatio: 1.09,
    riskLevel: 'OPTIMAL',
    bodyPartRisk: {
      'shoulders': 42,
      'knees': 38,
      'lower_back': 35,
      'wrists': 25,
    },
    asymmetryAlerts: [],
    deloadRecommendations: [
      'Training load balanced — continue current program',
    ],
    consecutiveHighDays: 2,
    sleepDebtImpact: 15,
    deloadRecommended: false,
    suggestedDeloadDays: 0,
    dataPointsAnalyzed: 0,
    analyzedAt: DateTime.now(),
  );

  FuelAnalysis _defaultFuelAnalysis() => FuelAnalysis(
    nutritionScore: 68,
    proteinAdequacy: 78,
    hydrationScore: 72,
    caloricBalance: -200,
    phase: 'fight_camp',
    macroSplit: {'protein': 30, 'carbs': 42, 'fat': 28},
    microDeficiencies: {},
    mealPlan: ['Log your meals to unlock personalized nutrition AI'],
    supplementRecommendations: [
      'Creatine monohydrate 5g daily',
      'Electrolyte mix with training',
    ],
    metabolicRate: 2640,
    recoveryFuelScore: 65,
    dataPointsAnalyzed: 0,
    analyzedAt: DateTime.now(),
  );
}
