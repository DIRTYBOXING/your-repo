import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/apex_operating_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC GROWTH FLYWHEEL ENGINE — Layer 7: DFC's Momentum
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Makes DFC *scale*. Tracks and accelerates the self-sustaining loop:
///
///   More fighters → more content → more fans → more revenue
///     → more promoters → more events → more fighters (repeat)
///
/// Subsystems:
///   • Flywheel metrics     — Track each stage of the cycle
///   • Network effects      — SocialGraphService, FriendSuggestions
///   • Referral loops       — ReferralPointsService
///   • Discovery loops      — DiscoveryService, FeedRanking
///   • Engagement loops     — EngagementTrackerService
///   • Ecosystem feedback   — EcosystemFeedbackEngine
///   • Viral amplification  — PromoterAI, BeastMode, SocialEngine
///
/// ═══════════════════════════════════════════════════════════════════════════

enum FlywheelStage { fighters, content, fans, revenue, promoters, events }

class DfcGrowthFlywheelEngine extends ChangeNotifier {
  static final DfcGrowthFlywheelEngine _instance =
      DfcGrowthFlywheelEngine._internal();
  factory DfcGrowthFlywheelEngine() => _instance;
  DfcGrowthFlywheelEngine._internal();

  bool _initialized = false;
  Timer? _measureTimer;
  DateTime? _lastMeasurement;
  int _flywheelRotations = 0;

  /// Current value at each flywheel stage.
  final Map<FlywheelStage, double> _stageValues = {
    FlywheelStage.fighters: 0,
    FlywheelStage.content: 0,
    FlywheelStage.fans: 0,
    FlywheelStage.revenue: 0,
    FlywheelStage.promoters: 0,
    FlywheelStage.events: 0,
  };

  /// Growth rate (% change period-over-period) per stage.
  final Map<FlywheelStage, double> _growthRates = {
    for (final s in FlywheelStage.values) s: 0.0,
  };

  /// Historical flywheel metrics for trend analysis.
  final List<FlywheelMetric> _history = [];

  // ── Getters ──
  bool get initialized => _initialized;
  int get flywheelRotations => _flywheelRotations;
  Map<FlywheelStage, double> get stageValues => Map.unmodifiable(_stageValues);
  Map<FlywheelStage, double> get growthRates => Map.unmodifiable(_growthRates);
  List<FlywheelMetric> get history => List.unmodifiable(_history);

  /// Overall flywheel velocity — average growth rate across all stages.
  double get velocity {
    if (_growthRates.isEmpty) return 0.0;
    return _growthRates.values.reduce((a, b) => a + b) / _growthRates.length;
  }

  /// Is the flywheel accelerating? (positive velocity)
  bool get isAccelerating => velocity > 0;

  double get overallScore => (velocity / 10.0).clamp(0.0, 1.0) + 0.5;

  ApexLayerStatus get layerStatus => ApexLayerStatus(
    layer: ApexLayer.growthFlywheel,
    health: isAccelerating
        ? LayerHealth.optimal
        : velocity == 0
        ? LayerHealth.degraded
        : LayerHealth.critical,
    score: overallScore.clamp(0.0, 1.0),
    activeSubsystems: _growthRates.values.where((r) => r > 0).length,
    totalSubsystems: FlywheelStage.values.length,
    lastHeartbeat: _lastMeasurement ?? DateTime.now(),
    statusMessage:
        'Velocity ${velocity.toStringAsFixed(1)}% · '
        '$_flywheelRotations rotations',
  );

  // ── Lifecycle ──

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Measure flywheel every 30 minutes.
    _measureTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      _measure();
    });

    debugPrint(
      '[GrowthFlywheel] Online — tracking '
      '${FlywheelStage.values.length} stages',
    );
    notifyListeners();
  }

  /// Update a stage's current value (called by services feeding the flywheel).
  void updateStage(FlywheelStage stage, double newValue) {
    final previous = _stageValues[stage] ?? 0;
    _stageValues[stage] = newValue;
    if (previous > 0) {
      _growthRates[stage] = ((newValue - previous) / previous) * 100;
    }

    _history.add(
      FlywheelMetric(
        stage: stage.name,
        value: newValue,
        growthRate: _growthRates[stage] ?? 0,
        measuredAt: DateTime.now(),
      ),
    );

    // Cap history at 1000 items.
    if (_history.length > 1000) {
      _history.removeRange(0, _history.length - 1000);
    }

    notifyListeners();
  }

  /// Record a full flywheel rotation (went through all 6 stages).
  void recordRotation() {
    _flywheelRotations++;
    debugPrint('[GrowthFlywheel] Rotation #$_flywheelRotations');
    notifyListeners();
  }

  @override
  void dispose() {
    _measureTimer?.cancel();
    super.dispose();
  }

  // ── Internal ──

  void _measure() {
    _lastMeasurement = DateTime.now();

    // Check if all stages have positive growth → full rotation.
    final allGrowing = _growthRates.values.every((r) => r > 0);
    if (allGrowing) {
      recordRotation();
    }

    debugPrint(
      '[GrowthFlywheel] Measurement — velocity '
      '${velocity.toStringAsFixed(1)}%',
    );
    notifyListeners();
  }
}
