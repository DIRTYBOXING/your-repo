/// ═══════════════════════════════════════════════════════════════════════════
/// AI ESO ENGINE SERVICE - AI-Powered Wellness & Performance Predictions
/// ═══════════════════════════════════════════════════════════════════════════
///
/// The "Electronic Stability Optimization" engine that connects:
/// - Sleep patterns → Training readiness
/// - Heart rate variability → Recovery status
/// - Nutrition tracking → Energy optimization
/// - Training load → Adaptation predictions
///
/// Integrates with Kimik2.5 wellness protocol for holistic athlete management.
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'dart:async';
import 'package:flutter/widgets.dart';

/// Wellness snapshot at a point in time
class WellnessSnapshot {
  final DateTime timestamp;
  final double sleepScore; // 0-100
  final double recoveryScore; // 0-100
  final double readinessScore; // 0-100
  final double stressLevel; // 0-100
  final double hydrationLevel; // 0-100
  final int restingHR; // BPM
  final int hrvScore; // ms
  final double bodyBattery; // 0-100

  WellnessSnapshot({
    required this.timestamp,
    this.sleepScore = 75,
    this.recoveryScore = 80,
    this.readinessScore = 82,
    this.stressLevel = 35,
    this.hydrationLevel = 70,
    this.restingHR = 58,
    this.hrvScore = 65,
    this.bodyBattery = 78,
  });

  /// Overall wellness index (weighted average)
  double get overallIndex {
    return (sleepScore * 0.25) +
        (recoveryScore * 0.25) +
        (readinessScore * 0.2) +
        ((100 - stressLevel) * 0.15) +
        (hydrationLevel * 0.15);
  }

  /// Training recommendation based on wellness
  String get trainingRecommendation {
    if (overallIndex >= 85) return 'PEAK - Go hard today';
    if (overallIndex >= 70) return 'GOOD - Normal training';
    if (overallIndex >= 55) return 'MODERATE - Reduce intensity';
    if (overallIndex >= 40) return 'LOW - Light work only';
    return 'REST - Recovery day recommended';
  }
}

/// Training load metrics
class TrainingLoad {
  final double acute; // Last 7 days
  final double chronic; // Last 28 days
  final double ratio; // Acute:Chronic ratio
  final double monotony; // Training variation
  final double strain; // Overall strain

  TrainingLoad({
    required this.acute,
    required this.chronic,
    required this.ratio,
    required this.monotony,
    required this.strain,
  });

  /// Risk assessment based on ratio
  String get riskLevel {
    if (ratio < 0.8) return 'UNDERTRAINING';
    if (ratio <= 1.3) return 'OPTIMAL';
    if (ratio <= 1.5) return 'CAUTION';
    return 'HIGH RISK';
  }

  /// Color for risk level
  int get riskColorValue {
    if (ratio < 0.8) return 0xFF00D4FF; // Blue
    if (ratio <= 1.3) return 0xFF00FF88; // Green
    if (ratio <= 1.5) return 0xFFFFB800; // Amber
    return 0xFFFF3366; // Red
  }
}

/// Performance index prediction
class PerformanceIndex {
  final double current;
  final double predicted7Days;
  final double predicted30Days;
  final double peakPotential;
  final DateTime? predictedPeakDate;

  PerformanceIndex({
    required this.current,
    required this.predicted7Days,
    required this.predicted30Days,
    required this.peakPotential,
    this.predictedPeakDate,
  });

  /// Trend direction
  String get trend {
    if (predicted7Days > current) return 'IMPROVING';
    if (predicted7Days < current) return 'DECLINING';
    return 'STABLE';
  }
}

/// Kimik2.5 Protocol recommendations
class Kimik25Protocol {
  final String focusArea;
  final List<String> morningRoutine;
  final List<String> nutritionTips;
  final List<String> recoveryActions;
  final double complianceScore;

  Kimik25Protocol({
    required this.focusArea,
    required this.morningRoutine,
    required this.nutritionTips,
    required this.recoveryActions,
    this.complianceScore = 0,
  });
}

/// AI ESO Engine Service
class AIEsoEngineService extends ChangeNotifier {
  static final AIEsoEngineService _instance = AIEsoEngineService._internal();
  factory AIEsoEngineService() => _instance;
  AIEsoEngineService._internal();

  // State
  WellnessSnapshot? _currentWellness;
  TrainingLoad? _trainingLoad;
  PerformanceIndex? _performanceIndex;
  Kimik25Protocol? _protocol;
  bool _isProcessing = false;
  DateTime? _lastUpdate;

  // Getters
  WellnessSnapshot? get currentWellness => _currentWellness;
  TrainingLoad? get trainingLoad => _trainingLoad;
  PerformanceIndex? get performanceIndex => _performanceIndex;
  Kimik25Protocol? get protocol => _protocol;
  bool get isProcessing => _isProcessing;
  DateTime? get lastUpdate => _lastUpdate;

  /// Initialize the ESO Engine
  Future<void> initialize() async {
    _isProcessing = true;
    // Defer notification to avoid setState-during-build conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());

    // Simulate AI processing
    await Future.delayed(const Duration(milliseconds: 500));

    // Load demo data
    _currentWellness = WellnessSnapshot(
      timestamp: DateTime.now(),
      sleepScore: 82,
      recoveryScore: 78,
      readinessScore: 85,
      stressLevel: 28,
      hydrationLevel: 75,
      restingHR: 56,
      hrvScore: 72,
      bodyBattery: 84,
    );

    _trainingLoad = TrainingLoad(
      acute: 2450,
      chronic: 2200,
      ratio: 1.11,
      monotony: 1.4,
      strain: 3430,
    );

    _performanceIndex = PerformanceIndex(
      current: 78.5,
      predicted7Days: 81.2,
      predicted30Days: 85.0,
      peakPotential: 92.0,
      predictedPeakDate: DateTime.now().add(const Duration(days: 45)),
    );

    _protocol = Kimik25Protocol(
      focusArea: 'RECOVERY OPTIMIZATION',
      morningRoutine: [
        '5 min breathwork (4-7-8 pattern)',
        'Cold exposure 2 min',
        'Mobility flow 10 min',
        'Hydrate 500ml + electrolytes',
      ],
      nutritionTips: [
        'Increase protein to 2.2g/kg today',
        'Add anti-inflammatory foods (turmeric, ginger)',
        'Pre-workout: Complex carbs 2hrs before',
        'Post-workout: 40g protein within 30min',
      ],
      recoveryActions: [
        'Foam roll hip flexors (tight from yesterday)',
        'Ice bath or contrast therapy',
        'Sleep target: 8.5 hours tonight',
        'Limit screen time after 9pm',
      ],
      complianceScore: 73,
    );

    _lastUpdate = DateTime.now();
    _isProcessing = false;
    notifyListeners();

    debugPrint('🤖 AI ESO Engine initialized');
  }

  /// Refresh all metrics
  Future<void> refresh() async {
    await initialize();
  }

  /// Get personalized insight
  String getPersonalizedInsight() {
    if (_currentWellness == null) return 'No data available';

    final wellness = _currentWellness!;
    final load = _trainingLoad;

    if (wellness.sleepScore < 60) {
      return '😴 Sleep quality was low. Consider lighter training today.';
    }
    if (load != null && load.ratio > 1.4) {
      return '⚠️ Training load is spiking. Watch for overreaching signs.';
    }
    if (wellness.stressLevel > 70) {
      return '🧘 High stress detected. Prioritize recovery activities.';
    }
    if (wellness.overallIndex >= 85) {
      return '🔥 You\'re in peak condition. Push hard today!';
    }

    return '✅ Metrics look balanced. Train as planned.';
  }

  /// Predict performance for a specific date
  double predictPerformance(DateTime date) {
    if (_performanceIndex == null) return 0;

    final daysAhead = date.difference(DateTime.now()).inDays;
    final current = _performanceIndex!.current;
    final potential = _performanceIndex!.peakPotential;

    // Simple linear interpolation toward peak
    final progress = (daysAhead / 60).clamp(0.0, 1.0);
    return current + ((potential - current) * progress);
  }
}
