/// ═══════════════════════════════════════════════════════════════════════════
/// SPORTS SCIENCE ENGINE — The Brain of Fighter Performance
/// ═══════════════════════════════════════════════════════════════════════════
///
/// THIS IS NOT JUST AI. THIS IS 39 YEARS OF FIGHTING KNOWLEDGE + SPORTS
/// SCIENCE + BIOMECHANICS + PHYSIOLOGY — TRANSFORMED INTO CODE.
///
/// "Pain is the greatest teacher. Struggle creates strength."
///
/// Energy Systems:
///   ATP-PC (0–10s, explosive power — the knockout punch)
///   Glycolytic (10s–2min, high intensity — the combination storm)
///   Oxidative (2min+, endurance — the championship rounds)
///
/// Biomechanics:
///   Force = Mass × Acceleration — but a fighter knows it's about
///   timing, angle, and kinetic chain from toe to fist.
///
/// Heart Rate Zones:
///   Resting → Zone 1 → Zone 2 → Zone 3 → Zone 4 → Zone 5 → Max
///   Recovery   Warm Up  Aerobic  Threshold  VO2Max   Redline
///
/// "The mind will quit a thousand times before your body does.
///  Don't let it." — Street Wisdom, 25 years to learn.
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'dart:math';
import 'package:flutter/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENUMS & CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

/// The three energy systems powering every movement in combat sports
enum EnergySystem {
  atpPc, // Phosphagen — 0-10s — KO power, explosive takedowns
  glycolytic, // Anaerobic — 10s-2min — Combination flurries, scrambles
  oxidative, // Aerobic — 2min+ — Pace, recovery between rounds
}

/// Heart rate training zones (Karvonen method with combat sport calibration)
enum HeartRateZone {
  resting, // Below zone 1 — full recovery
  zone1, // 50-60% HRR — Active recovery, warm-up
  zone2, // 60-70% HRR — Aerobic base, fat oxidation
  zone3, // 70-80% HRR — Tempo, lactate threshold approach
  zone4, // 80-90% HRR — VO2max, anaerobic threshold
  zone5, // 90-100% HRR — Redline, max effort bursts
}

/// Training periodization phases
enum PeriodizationPhase {
  anatomicalAdaptation, // GPP — build the chassis
  hypertrophy, // Build muscle armor
  maxStrength, // Peak force production
  powerConversion, // Strength → explosive power
  sportSpecific, // Skills under fatigue
  taper, // Unload for fight week
  competition, // Fight day
  activeRecovery, // Post-fight restoration
}

/// Biomechanical movement planes
enum MovementPlane {
  sagittal, // Forward/backward — jab, cross, knee
  frontal, // Side-to-side — lateral movement, hooks
  transverse, // Rotation — uppercuts, body kicks, spinning
}

/// Muscle fiber type dominance
enum FiberType {
  typeI, // Slow-twitch — endurance, steady output
  typeIIa, // Fast-twitch oxidative — power-endurance
  typeIIx, // Fast-twitch glycolytic — pure explosive power
}

/// Data input source for tracking
enum DataSource {
  smartDevice, // Wearable / connected device
  manualEntry, // Fighter types it in
  cameraHR, // Camera-based PPG heart rate
  aiEstimate, // AI-predicted from training patterns
  firestore, // Historical Firestore data
}

/// Recovery state assessment
enum RecoveryState {
  fullyRecovered, // Green — train hard
  adequate, // Light green — train normal
  moderate, // Yellow — reduce volume
  fatigued, // Orange — light work only
  overreached, // Red — rest or active recovery only
  overtrained, // Dark red — STOP. See a professional.
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

/// Complete biometric snapshot — unified from all data sources
class BiometricSnapshot {
  final DateTime timestamp;
  final DataSource source;

  // Heart Rate
  final int? heartRate; // Current BPM
  final int? restingHR; // Morning resting HR
  final int? maxHR; // Calculated or tested max HR
  final int? hrvMs; // Heart rate variability (ms, RMSSD)
  final double? hrvLnRmssd; // Natural log of RMSSD (more stable)

  // Recovery & Readiness
  final double? recoveryScore; // 0-100
  final double? readinessScore; // 0-100 (composite)
  final double? bodyBattery; // 0-100 (Garmin-style)
  final double? stressLevel; // 0-100 (lower = better)

  // Sleep
  final double? sleepHours;
  final int? sleepQuality; // 0-100
  final double? remHours; // REM sleep duration
  final double? deepSleepHours; // Deep/SWS duration

  // Body Composition
  final double? weight; // kg
  final double? bodyFatPercent;
  final double? muscleMass; // kg
  final double? hydrationPercent;

  // Activity
  final int? steps;
  final double? caloriesBurned;
  final double? activeMinutes;
  final double? vo2Max; // mL/kg/min
  final int? spo2; // Blood oxygen %
  final double? bodyTemp; // Celsius
  final double? respiratoryRate; // breaths/min

  // Subjective (manual)
  final double? rpe; // Rate of Perceived Exertion 1-10
  final double? moodScore; // 1-10
  final double? sorenessScore; // 1-10
  final double? painLevel; // 0-10
  final double? energyLevel; // 1-10
  final double? motivationScore; // 1-10

  const BiometricSnapshot({
    required this.timestamp,
    this.source = DataSource.manualEntry,
    this.heartRate,
    this.restingHR,
    this.maxHR,
    this.hrvMs,
    this.hrvLnRmssd,
    this.recoveryScore,
    this.readinessScore,
    this.bodyBattery,
    this.stressLevel,
    this.sleepHours,
    this.sleepQuality,
    this.remHours,
    this.deepSleepHours,
    this.weight,
    this.bodyFatPercent,
    this.muscleMass,
    this.hydrationPercent,
    this.steps,
    this.caloriesBurned,
    this.activeMinutes,
    this.vo2Max,
    this.spo2,
    this.bodyTemp,
    this.respiratoryRate,
    this.rpe,
    this.moodScore,
    this.sorenessScore,
    this.painLevel,
    this.energyLevel,
    this.motivationScore,
  });

  /// Merge with another snapshot (non-null values win)
  BiometricSnapshot merge(BiometricSnapshot other) {
    return BiometricSnapshot(
      timestamp: other.timestamp.isAfter(timestamp)
          ? other.timestamp
          : timestamp,
      source: other.source,
      heartRate: other.heartRate ?? heartRate,
      restingHR: other.restingHR ?? restingHR,
      maxHR: other.maxHR ?? maxHR,
      hrvMs: other.hrvMs ?? hrvMs,
      hrvLnRmssd: other.hrvLnRmssd ?? hrvLnRmssd,
      recoveryScore: other.recoveryScore ?? recoveryScore,
      readinessScore: other.readinessScore ?? readinessScore,
      bodyBattery: other.bodyBattery ?? bodyBattery,
      stressLevel: other.stressLevel ?? stressLevel,
      sleepHours: other.sleepHours ?? sleepHours,
      sleepQuality: other.sleepQuality ?? sleepQuality,
      remHours: other.remHours ?? remHours,
      deepSleepHours: other.deepSleepHours ?? deepSleepHours,
      weight: other.weight ?? weight,
      bodyFatPercent: other.bodyFatPercent ?? bodyFatPercent,
      muscleMass: other.muscleMass ?? muscleMass,
      hydrationPercent: other.hydrationPercent ?? hydrationPercent,
      steps: other.steps ?? steps,
      caloriesBurned: other.caloriesBurned ?? caloriesBurned,
      activeMinutes: other.activeMinutes ?? activeMinutes,
      vo2Max: other.vo2Max ?? vo2Max,
      spo2: other.spo2 ?? spo2,
      bodyTemp: other.bodyTemp ?? bodyTemp,
      respiratoryRate: other.respiratoryRate ?? respiratoryRate,
      rpe: other.rpe ?? rpe,
      moodScore: other.moodScore ?? moodScore,
      sorenessScore: other.sorenessScore ?? sorenessScore,
      painLevel: other.painLevel ?? painLevel,
      energyLevel: other.energyLevel ?? energyLevel,
      motivationScore: other.motivationScore ?? motivationScore,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'timestamp': timestamp.toIso8601String(),
    'source': source.name,
    'heartRate': heartRate,
    'restingHR': restingHR,
    'maxHR': maxHR,
    'hrvMs': hrvMs,
    'hrvLnRmssd': hrvLnRmssd,
    'recoveryScore': recoveryScore,
    'readinessScore': readinessScore,
    'bodyBattery': bodyBattery,
    'stressLevel': stressLevel,
    'sleepHours': sleepHours,
    'sleepQuality': sleepQuality,
    'remHours': remHours,
    'deepSleepHours': deepSleepHours,
    'weight': weight,
    'bodyFatPercent': bodyFatPercent,
    'muscleMass': muscleMass,
    'hydrationPercent': hydrationPercent,
    'steps': steps,
    'caloriesBurned': caloriesBurned,
    'activeMinutes': activeMinutes,
    'vo2Max': vo2Max,
    'spo2': spo2,
    'bodyTemp': bodyTemp,
    'respiratoryRate': respiratoryRate,
    'rpe': rpe,
    'moodScore': moodScore,
    'sorenessScore': sorenessScore,
    'painLevel': painLevel,
    'energyLevel': energyLevel,
    'motivationScore': motivationScore,
  };

  factory BiometricSnapshot.fromFirestore(Map<String, dynamic> data) {
    return BiometricSnapshot(
      timestamp: DateTime.parse(data['timestamp'] as String),
      source: DataSource.values.firstWhere(
        (e) => e.name == data['source'],
        orElse: () => DataSource.firestore,
      ),
      heartRate: data['heartRate'] as int?,
      restingHR: data['restingHR'] as int?,
      maxHR: data['maxHR'] as int?,
      hrvMs: data['hrvMs'] as int?,
      hrvLnRmssd: (data['hrvLnRmssd'] as num?)?.toDouble(),
      recoveryScore: (data['recoveryScore'] as num?)?.toDouble(),
      readinessScore: (data['readinessScore'] as num?)?.toDouble(),
      bodyBattery: (data['bodyBattery'] as num?)?.toDouble(),
      stressLevel: (data['stressLevel'] as num?)?.toDouble(),
      sleepHours: (data['sleepHours'] as num?)?.toDouble(),
      sleepQuality: data['sleepQuality'] as int?,
      remHours: (data['remHours'] as num?)?.toDouble(),
      deepSleepHours: (data['deepSleepHours'] as num?)?.toDouble(),
      weight: (data['weight'] as num?)?.toDouble(),
      bodyFatPercent: (data['bodyFatPercent'] as num?)?.toDouble(),
      muscleMass: (data['muscleMass'] as num?)?.toDouble(),
      hydrationPercent: (data['hydrationPercent'] as num?)?.toDouble(),
      steps: data['steps'] as int?,
      caloriesBurned: (data['caloriesBurned'] as num?)?.toDouble(),
      activeMinutes: (data['activeMinutes'] as num?)?.toDouble(),
      vo2Max: (data['vo2Max'] as num?)?.toDouble(),
      spo2: data['spo2'] as int?,
      bodyTemp: (data['bodyTemp'] as num?)?.toDouble(),
      respiratoryRate: (data['respiratoryRate'] as num?)?.toDouble(),
      rpe: (data['rpe'] as num?)?.toDouble(),
      moodScore: (data['moodScore'] as num?)?.toDouble(),
      sorenessScore: (data['sorenessScore'] as num?)?.toDouble(),
      painLevel: (data['painLevel'] as num?)?.toDouble(),
      energyLevel: (data['energyLevel'] as num?)?.toDouble(),
      motivationScore: (data['motivationScore'] as num?)?.toDouble(),
    );
  }
}

/// Energy system contribution for a training session
class EnergySystemProfile {
  final double atpPcPercent; // 0-100 — Phosphagen
  final double glycolyticPercent; // 0-100 — Anaerobic glycolysis
  final double oxidativePercent; // 0-100 — Aerobic
  final double totalEnergyKcal; // Estimated total energy expenditure
  final double lactateEstimate; // mmol/L estimated blood lactate
  final Duration timeInAtpPc;
  final Duration timeInGlycolytic;
  final Duration timeInOxidative;

  const EnergySystemProfile({
    required this.atpPcPercent,
    required this.glycolyticPercent,
    required this.oxidativePercent,
    this.totalEnergyKcal = 0,
    this.lactateEstimate = 0,
    this.timeInAtpPc = Duration.zero,
    this.timeInGlycolytic = Duration.zero,
    this.timeInOxidative = Duration.zero,
  });

  /// Dominant energy system for the session
  EnergySystem get dominant {
    if (atpPcPercent >= glycolyticPercent && atpPcPercent >= oxidativePercent) {
      return EnergySystem.atpPc;
    }
    if (glycolyticPercent >= oxidativePercent) return EnergySystem.glycolytic;
    return EnergySystem.oxidative;
  }
}

/// Heart rate zone breakdown for a session or time window
class HeartRateZoneProfile {
  final int restingHR;
  final int maxHR;
  final Map<HeartRateZone, Duration> timeInZone;
  final Map<HeartRateZone, double> percentInZone;
  final double trimp; // Training Impulse (Banister)
  final double epoc; // Excess post-exercise O₂ consumption (mL/kg)
  final double averageHR;
  final double peakHR;

  const HeartRateZoneProfile({
    required this.restingHR,
    required this.maxHR,
    this.timeInZone = const {},
    this.percentInZone = const {},
    this.trimp = 0,
    this.epoc = 0,
    this.averageHR = 0,
    this.peakHR = 0,
  });

  /// Heart Rate Reserve (Karvonen)
  int get hrReserve => maxHR - restingHR;

  /// Get the BPM boundaries for a given zone
  ({int lower, int upper}) zoneBounds(HeartRateZone zone) {
    final hrr = hrReserve;
    switch (zone) {
      case HeartRateZone.resting:
        return (lower: 0, upper: restingHR + (hrr * 0.50).round());
      case HeartRateZone.zone1:
        return (
          lower: restingHR + (hrr * 0.50).round(),
          upper: restingHR + (hrr * 0.60).round(),
        );
      case HeartRateZone.zone2:
        return (
          lower: restingHR + (hrr * 0.60).round(),
          upper: restingHR + (hrr * 0.70).round(),
        );
      case HeartRateZone.zone3:
        return (
          lower: restingHR + (hrr * 0.70).round(),
          upper: restingHR + (hrr * 0.80).round(),
        );
      case HeartRateZone.zone4:
        return (
          lower: restingHR + (hrr * 0.80).round(),
          upper: restingHR + (hrr * 0.90).round(),
        );
      case HeartRateZone.zone5:
        return (lower: restingHR + (hrr * 0.90).round(), upper: maxHR);
    }
  }
}

/// Biomechanical analysis of a movement or strike
class BiomechanicalAnalysis {
  final String movementName; // e.g. "Cross", "Roundhouse Kick"
  final MovementPlane primaryPlane;
  final List<MovementPlane> secondaryPlanes;

  // Force production chain
  final double estimatedForceNewtons; // Peak force estimate
  final double velocityMs; // Limb velocity m/s
  final double powerWatts; // F × v
  final double rateOfForceDev; // RFD — N/s (explosiveness)

  // Kinetic chain efficiency
  final double groundReactionForce; // % bodyweight
  final double hipRotationDegrees; // Rotational contribution
  final double trunkRotationDegrees;
  final double shoulderRotationDegrees;
  final double kineticChainEfficiency; // 0-100% (how well force transfers)

  // Joint angles at impact
  final Map<String, double> jointAngles; // e.g. {'elbow': 165, 'knee': 170}

  // Muscle activation pattern
  final List<MuscleActivation> muscleActivations;

  // Fiber type demand
  final FiberType primaryFiberDemand;

  const BiomechanicalAnalysis({
    required this.movementName,
    required this.primaryPlane,
    this.secondaryPlanes = const [],
    this.estimatedForceNewtons = 0,
    this.velocityMs = 0,
    this.powerWatts = 0,
    this.rateOfForceDev = 0,
    this.groundReactionForce = 0,
    this.hipRotationDegrees = 0,
    this.trunkRotationDegrees = 0,
    this.shoulderRotationDegrees = 0,
    this.kineticChainEfficiency = 0,
    this.jointAngles = const {},
    this.muscleActivations = const [],
    this.primaryFiberDemand = FiberType.typeIIx,
  });
}

/// Muscle activation during a movement
class MuscleActivation {
  final String muscleName;
  final double activationPercent; // 0-100% of MVC
  final String role; // 'agonist', 'antagonist', 'stabilizer', 'synergist'
  final FiberType dominantFiber;

  const MuscleActivation({
    required this.muscleName,
    required this.activationPercent,
    this.role = 'agonist',
    this.dominantFiber = FiberType.typeIIx,
  });
}

/// Training session with full sports science metrics
class ScienceSession {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String sessionType; // e.g. "Sparring", "Pad Work", "S&C"
  final DataSource source;

  // Core metrics
  final EnergySystemProfile energyProfile;
  final HeartRateZoneProfile hrZoneProfile;
  final double trainingLoad; // sRPE × duration (AU)
  final double rpe; // Session RPE (1-10)

  // Physiological response
  final double caloriesBurned;
  final double peakLactateEstimate; // mmol/L
  final Duration recoveryTime; // Estimated time to full recovery

  // Subjective
  final double moodBefore;
  final double moodAfter;
  final String? notes;

  const ScienceSession({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.sessionType,
    this.source = DataSource.manualEntry,
    required this.energyProfile,
    required this.hrZoneProfile,
    this.trainingLoad = 0,
    this.rpe = 5,
    this.caloriesBurned = 0,
    this.peakLactateEstimate = 0,
    this.recoveryTime = Duration.zero,
    this.moodBefore = 5,
    this.moodAfter = 5,
    this.notes,
  });

  Duration get duration => endTime.difference(startTime);
}

/// Acute:Chronic Workload Ratio analysis
class ACWRAnalysis {
  final double acuteLoad; // Last 7 days (AU)
  final double chronicLoad; // Last 28 days rolling average (AU)
  final double ratio; // ACWR
  final double monotony; // SD of daily load / mean
  final double strain; // Weekly load × monotony
  final RecoveryState riskLevel;
  final String recommendation;
  final List<double> dailyLoads; // Last 28 days for graphing

  const ACWRAnalysis({
    required this.acuteLoad,
    required this.chronicLoad,
    required this.ratio,
    this.monotony = 0,
    this.strain = 0,
    this.riskLevel = RecoveryState.adequate,
    this.recommendation = '',
    this.dailyLoads = const [],
  });
}

/// Performance prediction with confidence intervals
class PerformancePrediction {
  final double currentLevel; // 0-100
  final double predicted7Day;
  final double predicted14Day;
  final double predicted28Day;
  final double peakPotential;
  final DateTime estimatedPeakDate;
  final double confidencePercent; // How sure we are
  final String trend; // 'improving', 'plateauing', 'declining'
  final List<String> limitingFactors;
  final List<String> strengths;

  const PerformancePrediction({
    required this.currentLevel,
    required this.predicted7Day,
    required this.predicted14Day,
    required this.predicted28Day,
    required this.peakPotential,
    required this.estimatedPeakDate,
    this.confidencePercent = 50,
    this.trend = 'stable',
    this.limitingFactors = const [],
    this.strengths = const [],
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// THE ENGINE
// ─────────────────────────────────────────────────────────────────────────────

/// Sports Science Engine — The brain powering all performance analytics
///
/// Combines exercise physiology, biomechanics, periodization theory,
/// and AI-driven pattern recognition to keep fighters alive, well,
/// and optimized.
class SportsScienceEngine extends ChangeNotifier {
  static final SportsScienceEngine _instance = SportsScienceEngine._internal();
  factory SportsScienceEngine() => _instance;
  SportsScienceEngine._internal();

  // ── State ──
  bool _initialized = false;
  BiometricSnapshot? _latestBiometrics;
  final List<BiometricSnapshot> _biometricHistory = [];
  final List<ScienceSession> _sessionHistory = [];
  ACWRAnalysis? _currentACWR;
  PerformancePrediction? _currentPrediction;
  HeartRateZoneProfile? _currentHRProfile;
  EnergySystemProfile? _lastEnergyProfile;
  RecoveryState _recoveryState = RecoveryState.fullyRecovered;
  final PeriodizationPhase _currentPhase = PeriodizationPhase.sportSpecific;

  // ── Getters ──
  bool get initialized => _initialized;
  BiometricSnapshot? get latestBiometrics => _latestBiometrics;
  List<BiometricSnapshot> get biometricHistory =>
      List.unmodifiable(_biometricHistory);
  List<ScienceSession> get sessionHistory => List.unmodifiable(_sessionHistory);
  ACWRAnalysis? get currentACWR => _currentACWR;
  PerformancePrediction? get currentPrediction => _currentPrediction;
  HeartRateZoneProfile? get currentHRProfile => _currentHRProfile;
  EnergySystemProfile? get lastEnergyProfile => _lastEnergyProfile;
  RecoveryState get recoveryState => _recoveryState;
  PeriodizationPhase get currentPhase => _currentPhase;

  /// Initialize with demo or Firestore data
  Future<void> initialize() async {
    if (_initialized) return;

    _seedDemoBiometrics();
    _seedDemoSessions();
    _calculateACWR();
    _calculateHRProfile();
    _predictPerformance();
    _assessRecovery();

    _initialized = true;

    // Defer notification to avoid setState-during-build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    debugPrint(
      '🔬 Sports Science Engine initialized — '
      '${_biometricHistory.length} biometric records, '
      '${_sessionHistory.length} sessions loaded',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEART RATE SCIENCE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculate max HR using multiple formulas and return best estimate
  /// Tanaka (2001): 208 - 0.7 × age — more accurate than 220-age
  /// Gellish (2007): 207 - 0.7 × age
  /// Combat sport adjustment: +3 BPM (adrenaline/fight-or-flight factor)
  int estimateMaxHR(int age) {
    final tanaka = (208 - 0.7 * age).round();
    final gellish = (207 - 0.7 * age).round();
    final average = ((tanaka + gellish) / 2).round();
    return average + 3; // Combat sport adrenaline adjustment
  }

  /// Calculate heart rate zones using Karvonen method
  /// More accurate than simple % of max HR because it accounts for
  /// resting HR (fitness level)
  HeartRateZoneProfile calculateHRZones({
    required int restingHR,
    required int maxHR,
    List<int>? heartRateStream,
  }) {
    final hrr = maxHR - restingHR;

    // If we have a heart rate stream, compute zone distribution
    final Map<HeartRateZone, Duration> timeInZone = {};
    final Map<HeartRateZone, double> percentInZone = {};
    double avgHR = 0;
    double peakHR = 0;
    double trimp = 0;

    if (heartRateStream != null && heartRateStream.isNotEmpty) {
      // Initialize zone durations
      for (final zone in HeartRateZone.values) {
        timeInZone[zone] = Duration.zero;
      }

      double hrSum = 0;
      int peakBpm = 0;

      for (final hr in heartRateStream) {
        hrSum += hr;
        if (hr > peakBpm) peakBpm = hr;

        // Determine which zone this HR falls in
        final zone = _classifyHRZone(hr, restingHR, hrr);
        timeInZone[zone] = timeInZone[zone]! + const Duration(seconds: 5);
        // ^^ Assuming 5-second sampling interval (standard for most wearables)
      }

      avgHR = hrSum / heartRateStream.length;
      peakHR = peakBpm.toDouble();

      // Calculate percentages
      final totalSeconds = heartRateStream.length * 5;
      for (final zone in HeartRateZone.values) {
        percentInZone[zone] = totalSeconds > 0
            ? (timeInZone[zone]!.inSeconds / totalSeconds) * 100
            : 0;
      }

      // TRIMP (Banister's Training Impulse)
      // TRIMP = duration(min) × ΔHR ratio × weighting
      final durationMin = totalSeconds / 60.0;
      final deltaHR = (avgHR - restingHR) / hrr;
      // Male weighting: e^(1.92 × ΔHR)
      trimp = durationMin * deltaHR * exp(1.92 * deltaHR);
    }

    return HeartRateZoneProfile(
      restingHR: restingHR,
      maxHR: maxHR,
      timeInZone: timeInZone,
      percentInZone: percentInZone,
      trimp: trimp,
      averageHR: avgHR,
      peakHR: peakHR,
    );
  }

  HeartRateZone _classifyHRZone(int hr, int restingHR, int hrr) {
    final percent = (hr - restingHR) / hrr;
    if (percent < 0.50) return HeartRateZone.resting;
    if (percent < 0.60) return HeartRateZone.zone1;
    if (percent < 0.70) return HeartRateZone.zone2;
    if (percent < 0.80) return HeartRateZone.zone3;
    if (percent < 0.90) return HeartRateZone.zone4;
    return HeartRateZone.zone5;
  }

  /// Zone descriptions for fighters
  static const Map<HeartRateZone, Map<String, String>> zoneDescriptions = {
    HeartRateZone.resting: {
      'name': 'Recovery',
      'intensity': 'Rest / Very Light',
      'fightContext': 'Between rounds recovery, post-fight',
      'benefit': 'Parasympathetic activation, tissue repair',
      'example': 'Walking cool-down, stretching',
    },
    HeartRateZone.zone1: {
      'name': 'Warm-Up',
      'intensity': '50-60% HRR',
      'fightContext': 'Shadow boxing at 30% pace',
      'benefit': 'Fat oxidation, aerobic base, active recovery',
      'example': 'Light shadow boxing, technical drills',
    },
    HeartRateZone.zone2: {
      'name': 'Aerobic Base',
      'intensity': '60-70% HRR',
      'fightContext': 'Steady pad work, light sparring',
      'benefit': 'Mitochondrial density, capillary growth',
      'example': 'Roadwork, sustained bag work, flow rolling',
    },
    HeartRateZone.zone3: {
      'name': 'Tempo / Threshold',
      'intensity': '70-80% HRR',
      'fightContext': 'Hard paced rounds, wrestling exchanges',
      'benefit': 'Lactate clearance, sustained power output',
      'example': 'Thai pad rounds, hard sparring, live wrestling',
    },
    HeartRateZone.zone4: {
      'name': 'VO2max',
      'intensity': '80-90% HRR',
      'fightContext': 'Championship round pace, constant pressure',
      'benefit': 'Max oxygen uptake, anaerobic threshold push',
      'example': 'HIIT rounds, intense sparring, competition pace',
    },
    HeartRateZone.zone5: {
      'name': 'Redline',
      'intensity': '90-100% HRR',
      'fightContext': 'Going for the finish, fight-ending sequences',
      'benefit': 'Max power output, neuromuscular recruitment',
      'example': '10-second bursts, explosive combos, scrambles',
    },
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENERGY SYSTEMS SCIENCE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculate energy system contribution based on exercise parameters
  ///
  /// Based on Gastin (2001) model updated with combat sport research:
  /// - ATP-PC dominant: 0-10s maximal effort
  /// - Glycolytic dominant: 10s-2min high intensity
  /// - Oxidative dominant: >2min sustained
  ///
  /// Combat sports use ALL THREE simultaneously — the ratio shifts
  /// based on round duration, work:rest ratio, and intensity.
  EnergySystemProfile calculateEnergyProfile({
    required String sessionType,
    required int durationMinutes,
    required double avgIntensityPercent, // 0-100
    double workRestRatio = 1.0, // e.g. 2:1 = 2.0
  }) {
    double atpPc = 0;
    double glycolytic = 0;
    double oxidative = 0;

    // Base calculation from Gastin (2001) + combat sport adaptation
    if (durationMinutes <= 1) {
      // Very short — heavily ATP-PC + glycolytic
      atpPc = 40 + (avgIntensityPercent * 0.3);
      glycolytic = 35 + (avgIntensityPercent * 0.2);
      oxidative = 100 - atpPc - glycolytic;
    } else if (durationMinutes <= 5) {
      // 1-5 min — typical round length, mixed system
      atpPc = 20 + (avgIntensityPercent * 0.15);
      glycolytic = 30 + (avgIntensityPercent * 0.25);
      oxidative = 100 - atpPc - glycolytic;
    } else if (durationMinutes <= 15) {
      // 5-15 min — multi-round work, oxidative gains importance
      atpPc = 10 + (avgIntensityPercent * 0.1);
      glycolytic = 25 + (avgIntensityPercent * 0.15);
      oxidative = 100 - atpPc - glycolytic;
    } else {
      // 15+ min — endurance dominant
      atpPc = 5 + (avgIntensityPercent * 0.05);
      glycolytic = 15 + (avgIntensityPercent * 0.1);
      oxidative = 100 - atpPc - glycolytic;
    }

    // Work:rest ratio adjustment — higher ratio = more glycolytic
    if (workRestRatio > 2.0) {
      glycolytic += 5;
      oxidative -= 5;
    } else if (workRestRatio < 0.5) {
      atpPc += 5;
      glycolytic -= 3;
      oxidative -= 2;
    }

    // Session type modifiers
    switch (sessionType.toLowerCase()) {
      case 'sparring':
        atpPc += 5;
        glycolytic += 5;
        oxidative -= 10;
        break;
      case 'pad work':
      case 'padwork':
        atpPc += 8;
        glycolytic += 3;
        oxidative -= 11;
        break;
      case 'bag work':
        glycolytic += 5;
        oxidative -= 5;
        break;
      case 'wrestling':
      case 'grappling':
        glycolytic += 8;
        oxidative += 2;
        atpPc -= 10;
        break;
      case 'running':
      case 'roadwork':
        oxidative += 15;
        atpPc -= 10;
        glycolytic -= 5;
        break;
      case 's&c':
      case 'weights':
      case 'strength':
        atpPc += 15;
        glycolytic += 5;
        oxidative -= 20;
        break;
      case 'hiit':
      case 'sprints':
        atpPc += 10;
        glycolytic += 10;
        oxidative -= 20;
        break;
    }

    // Normalize to 100%
    final total = atpPc + glycolytic + oxidative;
    atpPc = (atpPc / total) * 100;
    glycolytic = (glycolytic / total) * 100;
    oxidative = (oxidative / total) * 100;

    // Clamp
    atpPc = atpPc.clamp(0, 100);
    glycolytic = glycolytic.clamp(0, 100);
    oxidative = oxidative.clamp(0, 100);

    // Estimate caloric expenditure
    // MET-based: combat sports ~8-12 METs depending on intensity
    final mets = 6 + (avgIntensityPercent / 100) * 8; // 6-14 MET range
    final kcal = mets * 80 * (durationMinutes / 60); // Assuming 80kg fighter

    // Estimate peak blood lactate based on glycolytic contribution
    final lactate = 1.0 + (glycolytic / 100) * 14; // 1-15 mmol/L range

    return EnergySystemProfile(
      atpPcPercent: atpPc,
      glycolyticPercent: glycolytic,
      oxidativePercent: oxidative,
      totalEnergyKcal: kcal,
      lactateEstimate: lactate,
      timeInAtpPc: Duration(minutes: (durationMinutes * atpPc / 100).round()),
      timeInGlycolytic: Duration(
        minutes: (durationMinutes * glycolytic / 100).round(),
      ),
      timeInOxidative: Duration(
        minutes: (durationMinutes * oxidative / 100).round(),
      ),
    );
  }

  /// Combat sport energy system demands — reference profiles
  static const Map<String, Map<String, double>> sportEnergyDemands = {
    'Boxing (3min rounds)': {'atpPc': 25, 'glycolytic': 40, 'oxidative': 35},
    'MMA (5min rounds)': {'atpPc': 20, 'glycolytic': 35, 'oxidative': 45},
    'Wrestling (3×2min)': {'atpPc': 15, 'glycolytic': 45, 'oxidative': 40},
    'Muay Thai (3min rounds)': {'atpPc': 22, 'glycolytic': 38, 'oxidative': 40},
    'BJJ (5-10min)': {'atpPc': 10, 'glycolytic': 35, 'oxidative': 55},
    'Kickboxing (3min rounds)': {
      'atpPc': 23,
      'glycolytic': 37,
      'oxidative': 40,
    },
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // BIOMECHANICS ENGINE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Analyze the biomechanics of common combat sport strikes
  /// Based on published kinematic research + 39 years of coaching wisdom
  BiomechanicalAnalysis analyzeStrike(
    String strikeName, {
    double bodyWeightKg = 80,
  }) {
    switch (strikeName.toLowerCase()) {
      case 'jab':
        return BiomechanicalAnalysis(
          movementName: 'Jab',
          primaryPlane: MovementPlane.sagittal,
          estimatedForceNewtons: bodyWeightKg * 4.5, // ~360N for 80kg
          velocityMs: 8.5,
          powerWatts: bodyWeightKg * 4.5 * 8.5,
          rateOfForceDev: 12000, // Very fast RFD
          groundReactionForce: 1.2, // 120% bodyweight
          hipRotationDegrees: 15,
          trunkRotationDegrees: 20,
          shoulderRotationDegrees: 35,
          kineticChainEfficiency: 65,
          jointAngles: {'shoulder': 90, 'elbow': 170, 'wrist': 180},
          muscleActivations: [
            const MuscleActivation(
              muscleName: 'Anterior Deltoid',
              activationPercent: 85,
            ),
            const MuscleActivation(
              muscleName: 'Triceps',
              activationPercent: 75,
            ),
            const MuscleActivation(
              muscleName: 'Serratus Anterior',
              activationPercent: 60,
              role: 'synergist',
            ),
            const MuscleActivation(
              muscleName: 'Rectus Abdominis',
              activationPercent: 40,
              role: 'stabilizer',
            ),
            const MuscleActivation(
              muscleName: 'Gastrocnemius',
              activationPercent: 55,
              role: 'synergist',
              dominantFiber: FiberType.typeIIa,
            ),
          ],
        );

      case 'cross':
      case 'straight right':
      case 'right cross':
        return BiomechanicalAnalysis(
          movementName: 'Cross',
          primaryPlane: MovementPlane.sagittal,
          secondaryPlanes: [MovementPlane.transverse],
          estimatedForceNewtons: bodyWeightKg * 7.5, // ~600N — the power shot
          velocityMs: 10.2,
          powerWatts: bodyWeightKg * 7.5 * 10.2,
          rateOfForceDev: 14000,
          groundReactionForce: 1.8, // Heavy rear foot drive
          hipRotationDegrees: 45, // Major hip rotation
          trunkRotationDegrees: 40,
          shoulderRotationDegrees: 50,
          kineticChainEfficiency: 80, // Full chain engagement
          jointAngles: {'hip': 165, 'shoulder': 85, 'elbow': 175, 'wrist': 180},
          muscleActivations: [
            const MuscleActivation(
              muscleName: 'Posterior Deltoid',
              activationPercent: 80,
            ),
            const MuscleActivation(
              muscleName: 'Pectoralis Major',
              activationPercent: 70,
            ),
            const MuscleActivation(
              muscleName: 'Internal Obliques',
              activationPercent: 85,
            ),
            const MuscleActivation(
              muscleName: 'Gluteus Maximus',
              activationPercent: 90,
              dominantFiber: FiberType.typeIIa,
            ),
            const MuscleActivation(
              muscleName: 'Gastrocnemius',
              activationPercent: 75,
              role: 'synergist',
              dominantFiber: FiberType.typeIIa,
            ),
            const MuscleActivation(
              muscleName: 'Quadriceps',
              activationPercent: 65,
              role: 'synergist',
            ),
          ],
        );

      case 'hook':
      case 'left hook':
        return BiomechanicalAnalysis(
          movementName: 'Hook',
          primaryPlane: MovementPlane.transverse,
          secondaryPlanes: [MovementPlane.frontal],
          estimatedForceNewtons: bodyWeightKg * 8.0, // ~640N — devastating
          velocityMs: 11.0,
          powerWatts: bodyWeightKg * 8.0 * 11.0,
          rateOfForceDev: 15000,
          groundReactionForce: 1.6,
          hipRotationDegrees: 55, // Maximum rotation
          trunkRotationDegrees: 50,
          shoulderRotationDegrees: 60,
          kineticChainEfficiency: 75,
          jointAngles: {'elbow': 90, 'shoulder': 70, 'hip': 160},
          muscleActivations: [
            const MuscleActivation(
              muscleName: 'Internal Obliques',
              activationPercent: 95,
            ),
            const MuscleActivation(
              muscleName: 'External Obliques',
              activationPercent: 85,
            ),
            const MuscleActivation(
              muscleName: 'Gluteus Medius',
              activationPercent: 70,
            ),
            const MuscleActivation(
              muscleName: 'Biceps Brachii',
              activationPercent: 60,
              role: 'stabilizer',
            ),
            const MuscleActivation(
              muscleName: 'Forearm Flexors',
              activationPercent: 80,
              role: 'stabilizer',
            ),
          ],
        );

      case 'uppercut':
        return BiomechanicalAnalysis(
          movementName: 'Uppercut',
          primaryPlane: MovementPlane.sagittal,
          secondaryPlanes: [MovementPlane.transverse],
          estimatedForceNewtons: bodyWeightKg * 6.5,
          velocityMs: 9.0,
          powerWatts: bodyWeightKg * 6.5 * 9.0,
          rateOfForceDev: 13500,
          groundReactionForce: 1.5,
          hipRotationDegrees: 35,
          trunkRotationDegrees: 30,
          shoulderRotationDegrees: 40,
          kineticChainEfficiency: 72,
          jointAngles: {'elbow': 95, 'shoulder': 60, 'knee': 155},
          muscleActivations: [
            const MuscleActivation(
              muscleName: 'Biceps Brachii',
              activationPercent: 75,
            ),
            const MuscleActivation(
              muscleName: 'Anterior Deltoid',
              activationPercent: 80,
            ),
            const MuscleActivation(
              muscleName: 'Quadriceps',
              activationPercent: 70,
              role: 'synergist',
            ),
            const MuscleActivation(
              muscleName: 'Erector Spinae',
              activationPercent: 65,
              role: 'synergist',
            ),
            const MuscleActivation(
              muscleName: 'Rectus Abdominis',
              activationPercent: 55,
              role: 'stabilizer',
            ),
          ],
        );

      case 'roundhouse kick':
      case 'round kick':
        return BiomechanicalAnalysis(
          movementName: 'Roundhouse Kick',
          primaryPlane: MovementPlane.transverse,
          secondaryPlanes: [MovementPlane.frontal, MovementPlane.sagittal],
          estimatedForceNewtons: bodyWeightKg * 12.0, // ~960N — devastating
          velocityMs: 14.0, // Shin velocity
          powerWatts: bodyWeightKg * 12.0 * 14.0,
          rateOfForceDev: 18000,
          groundReactionForce: 2.5, // Massive ground reaction
          hipRotationDegrees: 120, // Full hip turnover
          trunkRotationDegrees: 60,
          shoulderRotationDegrees: 30,
          kineticChainEfficiency: 85, // Long kinetic chain
          jointAngles: {'hip': 140, 'knee': 170, 'ankle': 120},
          muscleActivations: [
            const MuscleActivation(
              muscleName: 'Hip Flexors (Iliopsoas)',
              activationPercent: 95,
            ),
            const MuscleActivation(
              muscleName: 'Quadriceps',
              activationPercent: 90,
            ),
            const MuscleActivation(
              muscleName: 'Gluteus Maximus',
              activationPercent: 85,
            ),
            const MuscleActivation(
              muscleName: 'Internal Obliques',
              activationPercent: 80,
            ),
            const MuscleActivation(
              muscleName: 'Gastrocnemius (pivot)',
              activationPercent: 75,
              role: 'stabilizer',
            ),
            const MuscleActivation(
              muscleName: 'Adductors',
              activationPercent: 70,
              role: 'synergist',
            ),
          ],
        );

      case 'knee':
      case 'clinch knee':
        return BiomechanicalAnalysis(
          movementName: 'Clinch Knee',
          primaryPlane: MovementPlane.sagittal,
          estimatedForceNewtons: bodyWeightKg * 9.0,
          velocityMs: 7.5,
          powerWatts: bodyWeightKg * 9.0 * 7.5,
          rateOfForceDev: 16000,
          groundReactionForce: 1.8,
          hipRotationDegrees: 20,
          trunkRotationDegrees: 15,
          shoulderRotationDegrees: 10,
          kineticChainEfficiency: 78,
          jointAngles: {'hip': 110, 'knee': 80},
          muscleActivations: [
            const MuscleActivation(
              muscleName: 'Hip Flexors',
              activationPercent: 95,
            ),
            const MuscleActivation(
              muscleName: 'Rectus Abdominis',
              activationPercent: 85,
            ),
            const MuscleActivation(
              muscleName: 'Quadriceps',
              activationPercent: 70,
              role: 'synergist',
            ),
            const MuscleActivation(
              muscleName: 'Latissimus Dorsi',
              activationPercent: 60,
              role: 'synergist',
            ),
          ],
          primaryFiberDemand: FiberType.typeIIa,
        );

      default:
        return BiomechanicalAnalysis(
          movementName: strikeName,
          primaryPlane: MovementPlane.sagittal,
          estimatedForceNewtons: bodyWeightKg * 5.0,
          velocityMs: 8.0,
          powerWatts: bodyWeightKg * 5.0 * 8.0,
          kineticChainEfficiency: 60,
        );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TRAINING LOAD & PERIODIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculate ACWR (Acute:Chronic Workload Ratio)
  /// The gold standard for injury risk prediction in sports science
  /// Sweet spot: 0.8-1.3 | Danger zone: >1.5 | Too low: <0.8
  void _calculateACWR() {
    if (_sessionHistory.isEmpty) {
      _currentACWR = const ACWRAnalysis(
        acuteLoad: 0,
        chronicLoad: 0,
        ratio: 1.0,
        riskLevel: RecoveryState.fullyRecovered,
        recommendation: 'No training data yet. Start logging sessions.',
      );
      return;
    }

    final now = DateTime.now();
    final last7Days = _sessionHistory.where(
      (s) => s.startTime.isAfter(now.subtract(const Duration(days: 7))),
    );
    final last28Days = _sessionHistory.where(
      (s) => s.startTime.isAfter(now.subtract(const Duration(days: 28))),
    );

    final acuteLoad = last7Days.fold<double>(
      0,
      (sum, s) => sum + s.trainingLoad,
    );
    final chronicLoad =
        last28Days.fold<double>(0, (sum, s) => sum + s.trainingLoad) / 4;

    final ratio = chronicLoad > 0 ? acuteLoad / chronicLoad : 1.0;

    // Daily loads for graphing (last 28 days)
    final dailyLoads = <double>[];
    for (int i = 27; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final dayLoad = _sessionHistory
          .where(
            (s) =>
                s.startTime.isAfter(dayStart) && s.startTime.isBefore(dayEnd),
          )
          .fold<double>(0, (sum, s) => sum + s.trainingLoad);
      dailyLoads.add(dayLoad);
    }

    // Monotony: mean / SD of daily loads
    final mean =
        dailyLoads.fold<double>(0, (s, v) => s + v) / dailyLoads.length;
    final variance =
        dailyLoads.fold<double>(0, (s, v) => s + pow(v - mean, 2)) /
        dailyLoads.length;
    final sd = sqrt(variance);
    final monotony = sd > 0 ? mean / sd : 0.0;
    final strain = acuteLoad * monotony;

    // Risk levels
    RecoveryState risk;
    String recommendation;
    if (ratio > 1.5) {
      risk = RecoveryState.overreached;
      recommendation =
          '⚠️ ACWR is ${ratio.toStringAsFixed(2)} — HIGH spike risk. '
          'Reduce training load by 30-40% this week. "Rest is a weapon." — Samurai Shido';
    } else if (ratio > 1.3) {
      risk = RecoveryState.fatigued;
      recommendation =
          '🟡 ACWR is ${ratio.toStringAsFixed(2)} — approaching danger zone. '
          'Moderate intensity. Focus on technique over volume.';
    } else if (ratio >= 0.8) {
      risk = RecoveryState.adequate;
      recommendation =
          '✅ ACWR is ${ratio.toStringAsFixed(2)} — sweet spot. '
          'Training load is well managed. Continue current plan.';
    } else {
      risk = RecoveryState.fullyRecovered;
      recommendation =
          '🔵 ACWR is ${ratio.toStringAsFixed(2)} — undertrained. '
          'Gradually increase volume by 10-15% per week.';
    }

    _currentACWR = ACWRAnalysis(
      acuteLoad: acuteLoad,
      chronicLoad: chronicLoad,
      ratio: ratio,
      monotony: monotony,
      strain: strain,
      riskLevel: risk,
      recommendation: recommendation,
      dailyLoads: dailyLoads,
    );
  }

  /// Calculate performance prediction using fitness-fatigue model (Banister)
  void _predictPerformance() {
    final biometrics = _latestBiometrics;
    if (biometrics == null) {
      _currentPrediction = PerformancePrediction(
        currentLevel: 50,
        predicted7Day: 52,
        predicted14Day: 54,
        predicted28Day: 56,
        peakPotential: 85,
        estimatedPeakDate: DateTime.now().add(const Duration(days: 60)),
      );
      return;
    }

    // Composite current level from available metrics
    double level = 50;
    int factors = 0;
    final List<String> strengths = [];
    final List<String> limiters = [];

    if (biometrics.recoveryScore != null) {
      level += (biometrics.recoveryScore! - 50) * 0.3;
      factors++;
      if (biometrics.recoveryScore! > 75) strengths.add('Strong recovery');
      if (biometrics.recoveryScore! < 40) limiters.add('Poor recovery');
    }
    if (biometrics.hrvMs != null) {
      // HRV > 50ms is generally good for athletes
      level += (biometrics.hrvMs! - 40) * 0.4;
      factors++;
      if (biometrics.hrvMs! > 60) {
        strengths.add('High HRV — parasympathetic dominance');
      }
      if (biometrics.hrvMs! < 30) limiters.add('Low HRV — accumulated fatigue');
    }
    if (biometrics.sleepQuality != null) {
      level += (biometrics.sleepQuality! - 50) * 0.2;
      factors++;
      if (biometrics.sleepQuality! > 80) strengths.add('Quality sleep');
      if (biometrics.sleepQuality! < 50) limiters.add('Poor sleep quality');
    }
    if (biometrics.vo2Max != null) {
      // Elite combat athletes: 55-65 mL/kg/min
      level += (biometrics.vo2Max! - 45) * 0.3;
      factors++;
      if (biometrics.vo2Max! > 55) strengths.add('Elite aerobic capacity');
    }

    level = level.clamp(10, 100);

    // ACWR impact on prediction
    final acwr = _currentACWR;
    double acwrModifier = 0;
    if (acwr != null) {
      if (acwr.ratio >= 0.8 && acwr.ratio <= 1.3) {
        acwrModifier = 2; // Optimal loading → positive trend
      } else if (acwr.ratio > 1.5) {
        acwrModifier = -5; // Overreaching → performance drop incoming
        limiters.add(
          'Training load spike (ACWR ${acwr.ratio.toStringAsFixed(1)})',
        );
      }
    }

    final trend = acwrModifier > 0
        ? 'improving'
        : acwrModifier < 0
        ? 'declining'
        : 'stable';

    _currentPrediction = PerformancePrediction(
      currentLevel: level,
      predicted7Day: (level + acwrModifier * 1).clamp(10, 100),
      predicted14Day: (level + acwrModifier * 2).clamp(10, 100),
      predicted28Day: (level + acwrModifier * 3).clamp(10, 100),
      peakPotential: (level + 20).clamp(50, 100),
      estimatedPeakDate: DateTime.now().add(
        Duration(days: acwrModifier >= 0 ? 21 : 42),
      ),
      confidencePercent: (40 + factors * 12).clamp(30, 95).toDouble(),
      trend: trend,
      strengths: strengths,
      limitingFactors: limiters,
    );
  }

  /// Assess current recovery state from latest biometrics
  void _assessRecovery() {
    final bio = _latestBiometrics;
    if (bio == null) {
      _recoveryState = RecoveryState.adequate;
      return;
    }

    double score = 70; // Baseline

    // HRV is the #1 recovery indicator
    if (bio.hrvMs != null) {
      if (bio.hrvMs! > 65) {
        score += 10;
      } else if (bio.hrvMs! > 50) {
        score += 5;
      } else if (bio.hrvMs! < 30) {
        score -= 15;
      } else if (bio.hrvMs! < 40) {
        score -= 8;
      }
    }

    // Resting HR — elevated = incomplete recovery
    if (bio.restingHR != null) {
      if (bio.restingHR! > 75) {
        score -= 10; // Elevated
      } else if (bio.restingHR! < 55) {
        score += 5; // Athlete-level low
      }
    }

    // Sleep quality
    if (bio.sleepQuality != null) {
      if (bio.sleepQuality! > 80) {
        score += 8;
      } else if (bio.sleepQuality! < 50) {
        score -= 10;
      }
    }

    // Sleep duration
    if (bio.sleepHours != null) {
      if (bio.sleepHours! >= 8) {
        score += 5;
      } else if (bio.sleepHours! < 6) {
        score -= 12;
      }
    }

    // Soreness
    if (bio.sorenessScore != null) {
      score -= (bio.sorenessScore! - 3) * 3; // Above 3/10 starts hurting score
    }

    // Mood/energy
    if (bio.moodScore != null && bio.moodScore! < 4) score -= 5;
    if (bio.energyLevel != null && bio.energyLevel! < 4) score -= 5;

    score = score.clamp(0, 100);

    if (score >= 85) {
      _recoveryState = RecoveryState.fullyRecovered;
    } else if (score >= 70) {
      _recoveryState = RecoveryState.adequate;
    } else if (score >= 55) {
      _recoveryState = RecoveryState.moderate;
    } else if (score >= 35) {
      _recoveryState = RecoveryState.fatigued;
    } else if (score >= 15) {
      _recoveryState = RecoveryState.overreached;
    } else {
      _recoveryState = RecoveryState.overtrained;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATA INPUT — Smart Device + Manual + Camera
  // ═══════════════════════════════════════════════════════════════════════════

  /// Record a new biometric snapshot (from any source)
  void recordBiometrics(BiometricSnapshot snapshot) {
    _biometricHistory.add(snapshot);

    // Merge with latest
    if (_latestBiometrics != null) {
      _latestBiometrics = _latestBiometrics!.merge(snapshot);
    } else {
      _latestBiometrics = snapshot;
    }

    _assessRecovery();
    _predictPerformance();
    notifyListeners();
  }

  /// Record a training session with full sports science analysis
  void recordSession(ScienceSession session) {
    _sessionHistory.add(session);
    _lastEnergyProfile = session.energyProfile;
    _calculateACWR();
    _predictPerformance();
    notifyListeners();
  }

  /// Manual input: quick RPE + duration session log
  ScienceSession logQuickSession({
    required String type,
    required int durationMinutes,
    required double rpe,
    double moodBefore = 5,
    double moodAfter = 5,
    String? notes,
    List<int>? heartRateStream,
  }) {
    final now = DateTime.now();
    final restingHR = _latestBiometrics?.restingHR ?? 60;
    final maxHR = _latestBiometrics?.maxHR ?? 190;

    // Calculate energy profile
    final intensityPercent = rpe * 10; // RPE 7 → 70%
    final energy = calculateEnergyProfile(
      sessionType: type,
      durationMinutes: durationMinutes,
      avgIntensityPercent: intensityPercent,
    );

    // Calculate HR zones if stream available
    final hrProfile = calculateHRZones(
      restingHR: restingHR,
      maxHR: maxHR,
      heartRateStream: heartRateStream,
    );

    // Training load (sRPE method): RPE × duration in minutes
    final trainingLoad = rpe * durationMinutes;

    final session = ScienceSession(
      id: 'session_${now.millisecondsSinceEpoch}',
      startTime: now.subtract(Duration(minutes: durationMinutes)),
      endTime: now,
      sessionType: type,
      energyProfile: energy,
      hrZoneProfile: hrProfile,
      trainingLoad: trainingLoad,
      rpe: rpe,
      caloriesBurned: energy.totalEnergyKcal,
      peakLactateEstimate: energy.lactateEstimate,
      recoveryTime: Duration(hours: (trainingLoad / 100 * 12).round()),
      moodBefore: moodBefore,
      moodAfter: moodAfter,
      notes: notes,
    );

    recordSession(session);
    return session;
  }

  /// Calculate HR profile from latest data
  void _calculateHRProfile() {
    final restingHR = _latestBiometrics?.restingHR ?? 58;
    final maxHR = _latestBiometrics?.maxHR ?? 190;
    _currentHRProfile = calculateHRZones(restingHR: restingHR, maxHR: maxHR);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEMO DATA SEEDING
  // ═══════════════════════════════════════════════════════════════════════════

  void _seedDemoBiometrics() {
    final rng = Random(42);
    final now = DateTime.now();

    // Generate 30 days of morning biometrics
    for (int i = 29; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayVariance = sin(i * 0.3) * 5; // Natural wave pattern

      _biometricHistory.add(
        BiometricSnapshot(
          timestamp: DateTime(day.year, day.month, day.day, 6, 30),
          source: DataSource.smartDevice,
          restingHR: (58 + dayVariance + rng.nextInt(6) - 3).round().clamp(
            45,
            80,
          ),
          maxHR: 190,
          hrvMs: (52 + dayVariance * 1.5 + rng.nextInt(10) - 5).round().clamp(
            20,
            90,
          ),
          recoveryScore: (72 + dayVariance + rng.nextDouble() * 10).clamp(
            30,
            100,
          ),
          readinessScore: (68 + dayVariance * 0.8 + rng.nextDouble() * 8).clamp(
            25,
            100,
          ),
          bodyBattery: (65 + dayVariance + rng.nextDouble() * 12).clamp(
            10,
            100,
          ),
          stressLevel: (40 - dayVariance * 0.5 + rng.nextDouble() * 15).clamp(
            5,
            95,
          ),
          sleepHours: 6.5 + rng.nextDouble() * 2.5,
          sleepQuality: (70 + dayVariance + rng.nextInt(15)).round().clamp(
            30,
            100,
          ),
          remHours: 1.2 + rng.nextDouble() * 0.8,
          deepSleepHours: 1.0 + rng.nextDouble() * 1.0,
          weight: 80.0 + rng.nextDouble() * 2 - 1,
          bodyFatPercent: 12.0 + rng.nextDouble() * 2 - 1,
          hydrationPercent: 55 + rng.nextDouble() * 10,
          vo2Max: 52.0 + dayVariance * 0.2,
          spo2: (97 + rng.nextInt(3)).clamp(94, 100),
          bodyTemp: 36.4 + rng.nextDouble() * 0.4,
          steps: 5000 + rng.nextInt(8000),
          moodScore: (6.5 + dayVariance * 0.3 + rng.nextDouble() * 2).clamp(
            1,
            10,
          ),
          energyLevel: (6.0 + dayVariance * 0.3 + rng.nextDouble() * 2).clamp(
            1,
            10,
          ),
          sorenessScore: (4.0 - dayVariance * 0.2 + rng.nextDouble() * 3).clamp(
            1,
            10,
          ),
        ),
      );
    }

    _latestBiometrics = _biometricHistory.last;
  }

  void _seedDemoSessions() {
    final rng = Random(42);
    final now = DateTime.now();

    final sessionTypes = [
      'Sparring',
      'Pad Work',
      'Bag Work',
      'Wrestling',
      'Running',
      'S&C',
      'Shadow Boxing',
      'BJJ',
      'HIIT',
      'Yoga',
    ];

    // Generate 28 days of training sessions (1-2 per day, some rest days)
    for (int i = 27; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));

      // Rest days (roughly 2 per week)
      if (i % 7 == 0 || i % 7 == 4) continue;

      // First session
      final type1 = sessionTypes[rng.nextInt(sessionTypes.length)];
      final dur1 = 30 + rng.nextInt(60);
      final rpe1 = 5.0 + rng.nextDouble() * 4;

      final energy1 = calculateEnergyProfile(
        sessionType: type1,
        durationMinutes: dur1,
        avgIntensityPercent: rpe1 * 10,
      );

      _sessionHistory.add(
        ScienceSession(
          id: 'demo_${i}_1',
          startTime: DateTime(day.year, day.month, day.day, 9),
          endTime: DateTime(
            day.year,
            day.month,
            day.day,
            9,
          ).add(Duration(minutes: dur1)),
          sessionType: type1,
          source: DataSource.smartDevice,
          energyProfile: energy1,
          hrZoneProfile: const HeartRateZoneProfile(restingHR: 58, maxHR: 190),
          trainingLoad: rpe1 * dur1,
          rpe: rpe1,
          caloriesBurned: energy1.totalEnergyKcal,
          peakLactateEstimate: energy1.lactateEstimate,
          moodBefore: 5 + rng.nextDouble() * 3,
          moodAfter: 6 + rng.nextDouble() * 3,
        ),
      );

      // Second session (50% chance)
      if (rng.nextBool()) {
        final type2 = sessionTypes[rng.nextInt(sessionTypes.length)];
        final dur2 = 20 + rng.nextInt(40);
        final rpe2 = 4.0 + rng.nextDouble() * 4;

        final energy2 = calculateEnergyProfile(
          sessionType: type2,
          durationMinutes: dur2,
          avgIntensityPercent: rpe2 * 10,
        );

        _sessionHistory.add(
          ScienceSession(
            id: 'demo_${i}_2',
            startTime: DateTime(day.year, day.month, day.day, 16),
            endTime: DateTime(
              day.year,
              day.month,
              day.day,
              16,
            ).add(Duration(minutes: dur2)),
            sessionType: type2,
            source: DataSource.smartDevice,
            energyProfile: energy2,
            hrZoneProfile: const HeartRateZoneProfile(restingHR: 58, maxHR: 190),
            trainingLoad: rpe2 * dur2,
            rpe: rpe2,
            caloriesBurned: energy2.totalEnergyKcal,
            peakLactateEstimate: energy2.lactateEstimate,
            moodBefore: 5 + rng.nextDouble() * 3,
            moodAfter: 6 + rng.nextDouble() * 3,
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GRAPH DATA HELPERS — Feed the charts
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get resting HR trend (last N days)
  List<({DateTime date, double value})> getRestingHRTrend({int days = 30}) {
    return _biometricHistory
        .where((b) => b.restingHR != null)
        .map((b) => (date: b.timestamp, value: b.restingHR!.toDouble()))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get HRV trend
  List<({DateTime date, double value})> getHRVTrend({int days = 30}) {
    return _biometricHistory
        .where((b) => b.hrvMs != null)
        .map((b) => (date: b.timestamp, value: b.hrvMs!.toDouble()))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get recovery score trend
  List<({DateTime date, double value})> getRecoveryTrend({int days = 30}) {
    return _biometricHistory
        .where((b) => b.recoveryScore != null)
        .map((b) => (date: b.timestamp, value: b.recoveryScore!))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get sleep trend
  List<({DateTime date, double value})> getSleepTrend({int days = 30}) {
    return _biometricHistory
        .where((b) => b.sleepHours != null)
        .map((b) => (date: b.timestamp, value: b.sleepHours!))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get training load per day (for bar chart)
  List<({DateTime date, double value})> getDailyLoadTrend({int days = 28}) {
    final now = DateTime.now();
    final result = <({DateTime date, double value})>[];
    for (int i = days - 1; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final dayLoad = _sessionHistory
          .where(
            (s) =>
                s.startTime.isAfter(dayStart) && s.startTime.isBefore(dayEnd),
          )
          .fold<double>(0, (sum, s) => sum + s.trainingLoad);
      result.add((date: dayStart, value: dayLoad));
    }
    return result;
  }

  /// Get weight trend
  List<({DateTime date, double value})> getWeightTrend({int days = 30}) {
    return _biometricHistory
        .where((b) => b.weight != null)
        .map((b) => (date: b.timestamp, value: b.weight!))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get body battery / readiness trend
  List<({DateTime date, double value})> getReadinessTrend({int days = 30}) {
    return _biometricHistory
        .where((b) => b.readinessScore != null)
        .map((b) => (date: b.timestamp, value: b.readinessScore!))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get energy system distribution over last N sessions
  List<({String type, double atpPc, double glycolytic, double oxidative})>
  getEnergySystemBreakdown({int sessions = 10}) {
    return _sessionHistory.reversed
        .take(sessions)
        .map(
          (s) => (
            type: s.sessionType,
            atpPc: s.energyProfile.atpPcPercent,
            glycolytic: s.energyProfile.glycolyticPercent,
            oxidative: s.energyProfile.oxidativePercent,
          ),
        )
        .toList()
        .reversed
        .toList();
  }

  /// Get stress vs recovery correlation data
  List<({DateTime date, double stress, double recovery})>
  getStressRecoveryCorrelation({int days = 14}) {
    return _biometricHistory
        .where((b) => b.stressLevel != null && b.recoveryScore != null)
        .map(
          (b) => (
            date: b.timestamp,
            stress: b.stressLevel!,
            recovery: b.recoveryScore!,
          ),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get mood trend (before/after training)
  List<({DateTime date, double before, double after})> getMoodTrend({
    int sessions = 14,
  }) {
    return _sessionHistory.reversed
        .take(sessions)
        .map(
          (s) => (date: s.startTime, before: s.moodBefore, after: s.moodAfter),
        )
        .toList()
        .reversed
        .toList();
  }
}
