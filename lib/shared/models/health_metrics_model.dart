import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// HEALTH METRICS MODEL - ENTERPRISE GRADE
/// ═══════════════════════════════════════════════════════════════════════════
///
/// This is the RAW data layer. AI never writes here directly.
/// Data flows: Device/Manual → Metrics → Derived Signals → AI Interpretation
///
/// Supports:
/// - Manual input (always available)
/// - Phone sensors (camera HR, accelerometer)
/// - Wearables (Apple Watch, Garmin, Whoop, Oura)
/// ═══════════════════════════════════════════════════════════════════════════

/// Input source for metrics
enum MetricSource {
  manual, // User typed it
  phoneCamera, // HR from camera flash
  phoneMotion, // Activity from accelerometer
  appleWatch,
  garmin,
  whoop,
  oura,
  fitbit,
  polar,
  coros,
  unknown,
}

/// Hydration level categories
enum HydrationLevel {
  critical, // < 40% - DANGER
  low, // 40-55% - Warning
  moderate, // 55-70% - Needs attention
  optimal, // 70-85% - Good
  overhydrated, // > 85% - Possible issue
}

/// Weight cut phase
enum WeightCutPhase {
  maintenance, // Normal training weight
  waterLoading, // 7-10 days out, increasing water
  waterReduction, // 3-5 days out, decreasing water
  finalCut, // 24-48 hours, aggressive cut
  rehydration, // Post-weigh-in recovery
  postFight, // Recovery phase
}

/// Daily health metrics - RAW INPUT
class HealthMetrics extends Equatable {
  final String id;
  final String odUserId;
  final DateTime recordedAt;
  final MetricSource source;

  // ═══ VITAL SIGNS ═══
  final double? restingHeartRate; // BPM - morning measurement
  final double? heartRateVariability; // ms - HRV score
  final double? bloodOxygen; // SpO2 %
  final double? respiratoryRate; // Breaths per minute

  // ═══ BODY COMPOSITION ═══
  final double? weight; // kg
  final double? bodyFatPercentage; // %
  final double? muscleMass; // kg
  final double? visceralFat; // Score 1-59

  // ═══ HYDRATION & ELECTROLYTES ═══
  final double? hydrationPercentage; // %
  final double? waterIntakeMl; // ml consumed today
  final double? sodiumMg; // mg consumed
  final double? potassiumMg; // mg consumed
  final double? magnesiumMg; // mg consumed
  final bool? electrolyteSupplementTaken;

  // ═══ SLEEP ═══
  final double? sleepHours; // Total sleep
  final double? deepSleepHours; // Deep/slow wave
  final double? remSleepHours; // REM phase
  final int? sleepQualityScore; // 0-100
  final DateTime? sleepStart;
  final DateTime? sleepEnd;

  // ═══ TRAINING LOAD ═══
  final int? strikingMinutes;
  final int? grapplingMinutes;
  final int? conditioningMinutes;
  final int? sparringRounds;
  final int? perceivedExertion; // RPE 1-10
  final int? trainingIntensity; // 1-10 scale

  // ═══ SUBJECTIVE WELLNESS ═══
  final int? moodScore; // 1-10
  final int? energyLevel; // 1-10
  final int? stressLevel; // 1-10
  final int? muscleSOoreness; // 1-10
  final int? mentalClarity; // 1-10
  final String? notes; // Free text

  // ═══ WEIGHT CUT SPECIFIC ═══
  final WeightCutPhase? weightCutPhase;
  final double? targetWeight; // kg - fight weight
  final double? weightToLose; // kg remaining
  final int? daysUntilWeighIn;
  final double? dailyWeightLossRate; // kg/day

  // ═══ METADATA ═══
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isVerified; // Device-verified vs manual

  const HealthMetrics({
    required this.id,
    required this.odUserId,
    required this.recordedAt,
    this.source = MetricSource.manual,
    this.restingHeartRate,
    this.heartRateVariability,
    this.bloodOxygen,
    this.respiratoryRate,
    this.weight,
    this.bodyFatPercentage,
    this.muscleMass,
    this.visceralFat,
    this.hydrationPercentage,
    this.waterIntakeMl,
    this.sodiumMg,
    this.potassiumMg,
    this.magnesiumMg,
    this.electrolyteSupplementTaken,
    this.sleepHours,
    this.deepSleepHours,
    this.remSleepHours,
    this.sleepQualityScore,
    this.sleepStart,
    this.sleepEnd,
    this.strikingMinutes,
    this.grapplingMinutes,
    this.conditioningMinutes,
    this.sparringRounds,
    this.perceivedExertion,
    this.trainingIntensity,
    this.moodScore,
    this.energyLevel,
    this.stressLevel,
    this.muscleSOoreness,
    this.mentalClarity,
    this.notes,
    this.weightCutPhase,
    this.targetWeight,
    this.weightToLose,
    this.daysUntilWeighIn,
    this.dailyWeightLossRate,
    required this.createdAt,
    this.updatedAt,
    this.isVerified = false,
  });

  /// Calculate total training minutes
  int get totalTrainingMinutes {
    return (strikingMinutes ?? 0) +
        (grapplingMinutes ?? 0) +
        (conditioningMinutes ?? 0);
  }

  /// Get hydration level category
  HydrationLevel? get hydrationLevel {
    if (hydrationPercentage == null) return null;
    if (hydrationPercentage! < 40) return HydrationLevel.critical;
    if (hydrationPercentage! < 55) return HydrationLevel.low;
    if (hydrationPercentage! < 70) return HydrationLevel.moderate;
    if (hydrationPercentage! < 85) return HydrationLevel.optimal;
    return HydrationLevel.overhydrated;
  }

  /// Check if weight cut rate is dangerous (>1.5% body weight per day)
  bool get isDangerousWeightCutRate {
    if (weight == null || dailyWeightLossRate == null) return false;
    final percentPerDay = (dailyWeightLossRate! / weight!) * 100;
    return percentPerDay > 1.5;
  }

  /// Factory from Firestore
  factory HealthMetrics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HealthMetrics(
      id: doc.id,
      odUserId: data['userId'] ?? '',
      recordedAt: (data['recordedAt'] as Timestamp).toDate(),
      source: MetricSource.values.firstWhere(
        (s) => s.name == data['source'],
        orElse: () => MetricSource.manual,
      ),
      restingHeartRate: (data['restingHeartRate'] as num?)?.toDouble(),
      heartRateVariability: (data['heartRateVariability'] as num?)?.toDouble(),
      bloodOxygen: (data['bloodOxygen'] as num?)?.toDouble(),
      respiratoryRate: (data['respiratoryRate'] as num?)?.toDouble(),
      weight: (data['weight'] as num?)?.toDouble(),
      bodyFatPercentage: (data['bodyFatPercentage'] as num?)?.toDouble(),
      muscleMass: (data['muscleMass'] as num?)?.toDouble(),
      visceralFat: (data['visceralFat'] as num?)?.toDouble(),
      hydrationPercentage: (data['hydrationPercentage'] as num?)?.toDouble(),
      waterIntakeMl: (data['waterIntakeMl'] as num?)?.toDouble(),
      sodiumMg: (data['sodiumMg'] as num?)?.toDouble(),
      potassiumMg: (data['potassiumMg'] as num?)?.toDouble(),
      magnesiumMg: (data['magnesiumMg'] as num?)?.toDouble(),
      electrolyteSupplementTaken: data['electrolyteSupplementTaken'] as bool?,
      sleepHours: (data['sleepHours'] as num?)?.toDouble(),
      deepSleepHours: (data['deepSleepHours'] as num?)?.toDouble(),
      remSleepHours: (data['remSleepHours'] as num?)?.toDouble(),
      sleepQualityScore: data['sleepQualityScore'] as int?,
      sleepStart: data['sleepStart'] != null
          ? (data['sleepStart'] as Timestamp).toDate()
          : null,
      sleepEnd: data['sleepEnd'] != null
          ? (data['sleepEnd'] as Timestamp).toDate()
          : null,
      strikingMinutes: data['strikingMinutes'] as int?,
      grapplingMinutes: data['grapplingMinutes'] as int?,
      conditioningMinutes: data['conditioningMinutes'] as int?,
      sparringRounds: data['sparringRounds'] as int?,
      perceivedExertion: data['perceivedExertion'] as int?,
      trainingIntensity: data['trainingIntensity'] as int?,
      moodScore: data['moodScore'] as int?,
      energyLevel: data['energyLevel'] as int?,
      stressLevel: data['stressLevel'] as int?,
      muscleSOoreness: data['muscleSoreness'] as int?,
      mentalClarity: data['mentalClarity'] as int?,
      notes: data['notes'] as String?,
      weightCutPhase: data['weightCutPhase'] != null
          ? WeightCutPhase.values.firstWhere(
              (p) => p.name == data['weightCutPhase'],
              orElse: () => WeightCutPhase.maintenance,
            )
          : null,
      targetWeight: (data['targetWeight'] as num?)?.toDouble(),
      weightToLose: (data['weightToLose'] as num?)?.toDouble(),
      daysUntilWeighIn: data['daysUntilWeighIn'] as int?,
      dailyWeightLossRate: (data['dailyWeightLossRate'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isVerified: data['isVerified'] ?? false,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': odUserId,
      'recordedAt': Timestamp.fromDate(recordedAt),
      'source': source.name,
      'restingHeartRate': restingHeartRate,
      'heartRateVariability': heartRateVariability,
      'bloodOxygen': bloodOxygen,
      'respiratoryRate': respiratoryRate,
      'weight': weight,
      'bodyFatPercentage': bodyFatPercentage,
      'muscleMass': muscleMass,
      'visceralFat': visceralFat,
      'hydrationPercentage': hydrationPercentage,
      'waterIntakeMl': waterIntakeMl,
      'sodiumMg': sodiumMg,
      'potassiumMg': potassiumMg,
      'magnesiumMg': magnesiumMg,
      'electrolyteSupplementTaken': electrolyteSupplementTaken,
      'sleepHours': sleepHours,
      'deepSleepHours': deepSleepHours,
      'remSleepHours': remSleepHours,
      'sleepQualityScore': sleepQualityScore,
      'sleepStart': sleepStart != null ? Timestamp.fromDate(sleepStart!) : null,
      'sleepEnd': sleepEnd != null ? Timestamp.fromDate(sleepEnd!) : null,
      'strikingMinutes': strikingMinutes,
      'grapplingMinutes': grapplingMinutes,
      'conditioningMinutes': conditioningMinutes,
      'sparringRounds': sparringRounds,
      'perceivedExertion': perceivedExertion,
      'trainingIntensity': trainingIntensity,
      'moodScore': moodScore,
      'energyLevel': energyLevel,
      'stressLevel': stressLevel,
      'muscleSoreness': muscleSOoreness,
      'mentalClarity': mentalClarity,
      'notes': notes,
      'weightCutPhase': weightCutPhase?.name,
      'targetWeight': targetWeight,
      'weightToLose': weightToLose,
      'daysUntilWeighIn': daysUntilWeighIn,
      'dailyWeightLossRate': dailyWeightLossRate,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isVerified': isVerified,
    };
  }

  @override
  List<Object?> get props => [
    id,
    odUserId,
    recordedAt,
    source,
    restingHeartRate,
    heartRateVariability,
    weight,
    hydrationPercentage,
    sleepHours,
    moodScore,
    weightCutPhase,
  ];
}

/// ═══════════════════════════════════════════════════════════════════════════
/// DERIVED SIGNAL - AI-READY INTERPRETATION LAYER
/// ═══════════════════════════════════════════════════════════════════════════
///
/// This is calculated FROM HealthMetrics by deterministic rules.
/// AI reads this layer, never the raw metrics directly.
/// ═══════════════════════════════════════════════════════════════════════════

/// Risk level for any metric
enum RiskLevel {
  green, // All clear, optimal
  amber, // Attention needed, monitor
  orange, // Elevated risk, action recommended
  red, // Critical, immediate intervention
}

/// Derived health signal
class HealthSignal extends Equatable {
  final String id;
  final String odUserId;
  final DateTime signalDate;
  final DateTime calculatedAt;

  // ═══ COMPOSITE SCORES (0.0 - 1.0) ═══
  final double recoveryScore; // Overall recovery readiness
  final double trainingReadiness; // Ready to train hard?
  final double fightReadiness; // Ready to compete?
  final double stressLoad; // Cumulative stress
  final double fatigueIndex; // Accumulated fatigue

  // ═══ RISK ASSESSMENTS ═══
  final RiskLevel overallRisk;
  final RiskLevel hydrationRisk;
  final RiskLevel overtrainingRisk;
  final RiskLevel sleepDebtRisk;
  final RiskLevel weightCutRisk;
  final RiskLevel mentalHealthRisk;

  // ═══ FLAGS (SPECIFIC CONCERNS) ═══
  final List<String> activeFlags;
  // Examples: "low_sleep", "high_stress", "rapid_weight_loss",
  //           "low_hrv", "overtraining", "dehydration_warning"

  // ═══ RECOMMENDATIONS ═══
  final String? primaryRecommendation;
  final List<String> supportingRecommendations;

  // ═══ TRENDS (vs 7-day average) ═══
  final double? hrvTrend; // -1.0 to +1.0
  final double? sleepTrend;
  final double? weightTrend;
  final double? moodTrend;
  final double? energyTrend;

  // ═══ METADATA ═══
  final String? sourceMetricsId; // Link to raw metrics
  final bool requiresEscalation; // Needs human review
  final bool isAcknowledged; // User has seen this

  const HealthSignal({
    required this.id,
    required this.odUserId,
    required this.signalDate,
    required this.calculatedAt,
    required this.recoveryScore,
    required this.trainingReadiness,
    required this.fightReadiness,
    required this.stressLoad,
    required this.fatigueIndex,
    required this.overallRisk,
    required this.hydrationRisk,
    required this.overtrainingRisk,
    required this.sleepDebtRisk,
    required this.weightCutRisk,
    required this.mentalHealthRisk,
    this.activeFlags = const [],
    this.primaryRecommendation,
    this.supportingRecommendations = const [],
    this.hrvTrend,
    this.sleepTrend,
    this.weightTrend,
    this.moodTrend,
    this.energyTrend,
    this.sourceMetricsId,
    this.requiresEscalation = false,
    this.isAcknowledged = false,
  });

  /// Get the highest risk level
  RiskLevel get highestRisk {
    final risks = [
      overallRisk,
      hydrationRisk,
      overtrainingRisk,
      sleepDebtRisk,
      weightCutRisk,
      mentalHealthRisk,
    ];
    if (risks.contains(RiskLevel.red)) return RiskLevel.red;
    if (risks.contains(RiskLevel.orange)) return RiskLevel.orange;
    if (risks.contains(RiskLevel.amber)) return RiskLevel.amber;
    return RiskLevel.green;
  }

  /// Check if any critical flags
  bool get hasCriticalFlags {
    const criticalFlags = [
      'severe_dehydration',
      'dangerous_weight_cut',
      'crisis_support_needed',
      'extreme_fatigue',
      'medical_attention_required',
    ];
    return activeFlags.any((f) => criticalFlags.contains(f));
  }

  /// Factory from Firestore
  factory HealthSignal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HealthSignal(
      id: doc.id,
      odUserId: data['userId'] ?? '',
      signalDate: (data['signalDate'] as Timestamp).toDate(),
      calculatedAt: (data['calculatedAt'] as Timestamp).toDate(),
      recoveryScore: (data['recoveryScore'] as num).toDouble(),
      trainingReadiness: (data['trainingReadiness'] as num).toDouble(),
      fightReadiness: (data['fightReadiness'] as num).toDouble(),
      stressLoad: (data['stressLoad'] as num).toDouble(),
      fatigueIndex: (data['fatigueIndex'] as num).toDouble(),
      overallRisk: RiskLevel.values.firstWhere(
        (r) => r.name == data['overallRisk'],
        orElse: () => RiskLevel.green,
      ),
      hydrationRisk: RiskLevel.values.firstWhere(
        (r) => r.name == data['hydrationRisk'],
        orElse: () => RiskLevel.green,
      ),
      overtrainingRisk: RiskLevel.values.firstWhere(
        (r) => r.name == data['overtrainingRisk'],
        orElse: () => RiskLevel.green,
      ),
      sleepDebtRisk: RiskLevel.values.firstWhere(
        (r) => r.name == data['sleepDebtRisk'],
        orElse: () => RiskLevel.green,
      ),
      weightCutRisk: RiskLevel.values.firstWhere(
        (r) => r.name == data['weightCutRisk'],
        orElse: () => RiskLevel.green,
      ),
      mentalHealthRisk: RiskLevel.values.firstWhere(
        (r) => r.name == data['mentalHealthRisk'],
        orElse: () => RiskLevel.green,
      ),
      activeFlags: List<String>.from(data['activeFlags'] ?? []),
      primaryRecommendation: data['primaryRecommendation'] as String?,
      supportingRecommendations: List<String>.from(
        data['supportingRecommendations'] ?? [],
      ),
      hrvTrend: (data['hrvTrend'] as num?)?.toDouble(),
      sleepTrend: (data['sleepTrend'] as num?)?.toDouble(),
      weightTrend: (data['weightTrend'] as num?)?.toDouble(),
      moodTrend: (data['moodTrend'] as num?)?.toDouble(),
      energyTrend: (data['energyTrend'] as num?)?.toDouble(),
      sourceMetricsId: data['sourceMetricsId'] as String?,
      requiresEscalation: data['requiresEscalation'] ?? false,
      isAcknowledged: data['isAcknowledged'] ?? false,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': odUserId,
      'signalDate': Timestamp.fromDate(signalDate),
      'calculatedAt': Timestamp.fromDate(calculatedAt),
      'recoveryScore': recoveryScore,
      'trainingReadiness': trainingReadiness,
      'fightReadiness': fightReadiness,
      'stressLoad': stressLoad,
      'fatigueIndex': fatigueIndex,
      'overallRisk': overallRisk.name,
      'hydrationRisk': hydrationRisk.name,
      'overtrainingRisk': overtrainingRisk.name,
      'sleepDebtRisk': sleepDebtRisk.name,
      'weightCutRisk': weightCutRisk.name,
      'mentalHealthRisk': mentalHealthRisk.name,
      'activeFlags': activeFlags,
      'primaryRecommendation': primaryRecommendation,
      'supportingRecommendations': supportingRecommendations,
      'hrvTrend': hrvTrend,
      'sleepTrend': sleepTrend,
      'weightTrend': weightTrend,
      'moodTrend': moodTrend,
      'energyTrend': energyTrend,
      'sourceMetricsId': sourceMetricsId,
      'requiresEscalation': requiresEscalation,
      'isAcknowledged': isAcknowledged,
    };
  }

  @override
  List<Object?> get props => [
    id,
    odUserId,
    signalDate,
    overallRisk,
    recoveryScore,
    activeFlags,
  ];
}
