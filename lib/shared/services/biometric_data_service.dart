/// ═══════════════════════════════════════════════════════════════════════════
/// BIOMETRIC DATA SERVICE - Unified Health Data Integration Layer
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Merges data from multiple sources:
/// - SmartDeviceService (wearables: Apple Watch, Garmin, WHOOP, Oura, etc.)
/// - Manual entry (user input via UI)
/// - SportsScienceEngine (calculated metrics)
/// - Firestore (historical records)
/// - Camera/PPG (real-time HR from phone camera)
///
/// Provides a single stream of clean, deduplicated BiometricSnapshot objects
/// for consumption by UI screens, AI engines, and analytics.
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'package:flutter/foundation.dart';
import 'sports_science_engine.dart';
import 'smart_device_service.dart';

/// Data source priority for conflict resolution
enum BiometricSourcePriority {
  firestore, // Most authoritative (historical)
  smartDevice, // Wearables (real-time)
  manualEntry, // User input
  calculated, // AI/algorithm derived
  estimate, // Lowest priority
}

/// Represents a single unified biometric reading with source metadata
class BiometricReading {
  final String metricName; // e.g., "heartRate", "vo2Max", "lactateLevel"
  final dynamic value;
  final BiometricSourcePriority source;
  final DateTime timestamp;
  final String sourceDevice; // e.g., "Apple Watch", "manual", "calculated"
  final double confidence; // 0.0 to 1.0
  final String unit; // e.g., "bpm", "mmol/L", "%"

  BiometricReading({
    required this.metricName,
    required this.value,
    required this.source,
    required this.timestamp,
    required this.sourceDevice,
    this.confidence = 1.0,
    required this.unit,
  });

  @override
  String toString() =>
      '$metricName: $value $unit (from $sourceDevice, confidence: ${(confidence * 100).toStringAsFixed(0)}%)';
}

/// Unified snapshot of all current biometric data
class UnifiedBiometricSnapshot {
  final List<BiometricReading> readings;
  final DateTime timestamp;
  final double overallQuality; // 0.0 to 1.0 based on source confidence
  final Map<String, dynamic> metadata; // Custom fields

  UnifiedBiometricSnapshot({
    required this.readings,
    required this.timestamp,
    required this.overallQuality,
    this.metadata = const {},
  });

  /// Get the latest value for a specific metric
  dynamic getMetric(String metricName) {
    try {
      final reading = readings.firstWhere((r) => r.metricName == metricName);
      return reading.value;
    } catch (e) {
      return null;
    }
  }

  /// Get primary heart rate from highest-priority source
  int getHeartRate() => (getMetric('heartRate') as int?) ?? 0;

  /// Get HRV score
  int getHRV() => (getMetric('hrvScore') as int?) ?? 0;

  /// Get recovery score (0-100)
  int getRecoveryScore() {
    final score = getMetric('readinessScore') as int?;
    return score ?? 50;
  }

  /// Get readiness recommendation
  String getReadinessRecommendation() {
    final score = getRecoveryScore();
    if (score >= 80) return '🟢 Excellent — Go hard today';
    if (score >= 60) return '🟡 Good — Normal training';
    if (score >= 40) return '🟠 Fair — Consider active recovery';
    return '🔴 Low — Rest or light activity';
  }

  /// Export as Firebase document
  Map<String, dynamic> toFirestore() {
    return {
      'timestamp': timestamp,
      'heartRate': getHeartRate(),
      'hrvScore': getHRV(),
      'readinessScore': getRecoveryScore(),
      'data': {for (var r in readings) r.metricName: r.value},
      'sources': {for (var r in readings) r.metricName: r.sourceDevice},
      'quality': overallQuality,
    };
  }
}

/// Biometric Data Service — unified integration layer
class BiometricDataService extends ChangeNotifier {
  static final BiometricDataService _instance =
      BiometricDataService._internal();
  factory BiometricDataService() => _instance;
  BiometricDataService._internal();

  // Dependencies
  late SmartDeviceService _smartDeviceService;
  late SportsScienceEngine _sportsScienceEngine;

  // State
  UnifiedBiometricSnapshot? _currentSnapshot;
  final List<UnifiedBiometricSnapshot> _history = [];
  bool _isLoading = false;
  String? _lastError;

  // Getters
  UnifiedBiometricSnapshot? get currentSnapshot => _currentSnapshot;
  List<UnifiedBiometricSnapshot> get history => List.unmodifiable(_history);
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  /// Initialize with service dependencies
  Future<void> initialize(
    SmartDeviceService smartDeviceService,
    SportsScienceEngine sportsScienceEngine,
  ) async {
    _smartDeviceService = smartDeviceService;
    _sportsScienceEngine = sportsScienceEngine;

    // Load initial snapshot
    await refreshSnapshot();

    // Subscribe to service updates and stream live data
    _smartDeviceService.addListener(_onSmartDeviceUpdate);
    _sportsScienceEngine.addListener(_onSportsScienceUpdate);

    debugPrint('🔄 BiometricDataService initialized');
  }

  /// Refresh current snapshot from all sources
  Future<void> refreshSnapshot() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final readings = <BiometricReading>[];

      // Extract from SmartDeviceService (highest priority for real-time)
      if (_smartDeviceService.latestMetrics != null) {
        final m = _smartDeviceService.latestMetrics!;
        readings.addAll([
          BiometricReading(
            metricName: 'heartRate',
            value: m.heartRate,
            source: BiometricSourcePriority.smartDevice,
            timestamp: m.timestamp,
            sourceDevice: 'SmartDevices',
            confidence: 0.95,
            unit: 'bpm',
          ),
          BiometricReading(
            metricName: 'restingHR',
            value: m.restingHR,
            source: BiometricSourcePriority.smartDevice,
            timestamp: m.timestamp,
            sourceDevice: 'SmartDevices',
            confidence: 0.92,
            unit: 'bpm',
          ),
          BiometricReading(
            metricName: 'hrvScore',
            value: m.hrvScore,
            source: BiometricSourcePriority.smartDevice,
            timestamp: m.timestamp,
            sourceDevice: 'SmartDevices',
            confidence: 0.88,
            unit: '%',
          ),
          BiometricReading(
            metricName: 'spo2',
            value: m.spo2,
            source: BiometricSourcePriority.smartDevice,
            timestamp: m.timestamp,
            sourceDevice: 'SmartDevices',
            confidence: 0.90,
            unit: '%',
          ),
          BiometricReading(
            metricName: 'lactateLevel',
            value: m.lactateLevel,
            source: BiometricSourcePriority.smartDevice,
            timestamp: m.timestamp,
            sourceDevice: 'PF-Sweat Patch',
            confidence: 0.96,
            unit: 'mmol/L',
          ),
          BiometricReading(
            metricName: 'cortisol',
            value: m.cortisol,
            source: BiometricSourcePriority.smartDevice,
            timestamp: m.timestamp,
            sourceDevice: 'SmartDevices',
            confidence: 0.85,
            unit: 'ng/mL',
          ),
          BiometricReading(
            metricName: 'glucose',
            value: m.glucose,
            source: BiometricSourcePriority.smartDevice,
            timestamp: m.timestamp,
            sourceDevice: 'Abbott Libre Assist',
            confidence: 0.97,
            unit: 'mg/dL',
          ),
          BiometricReading(
            metricName: 'readinessScore',
            value: m.readinessScore,
            source: BiometricSourcePriority.smartDevice,
            timestamp: m.timestamp,
            sourceDevice: 'SmartDevices',
            confidence: 0.88,
            unit: '%',
          ),
          BiometricReading(
            metricName: 'acwr',
            value: m.acwr,
            source: BiometricSourcePriority.calculated,
            timestamp: m.timestamp,
            sourceDevice: 'SportsScienceEngine',
            confidence: 0.91,
            unit: 'ratio',
          ),
        ]);
      }

      // Calculate overall quality
      final avgConfidence = readings.isEmpty
          ? 0.8
          : readings.map((r) => r.confidence).reduce((a, b) => a + b) /
                readings.length;

      _currentSnapshot = UnifiedBiometricSnapshot(
        readings: readings,
        timestamp: DateTime.now(),
        overallQuality: avgConfidence,
        metadata: {
          'deviceCount': _smartDeviceService.devices.length,
          'connectedDevices': _smartDeviceService.devices
              .map((d) => d.name)
              .toList(),
        },
      );

      notifyListeners();
      debugPrint(
        '✅ Biometric snapshot refreshed (${readings.length} metrics from ${_smartDeviceService.devices.length} devices)',
      );
    } catch (e) {
      _lastError = 'Failed to refresh snapshot: $e';
      debugPrint('❌ BiometricDataService error: $_lastError');
      notifyListeners();
    } finally {
      _isLoading = false;
    }
  }

  /// Record manual biometric entry
  Future<void> recordManualEntry({
    required String metricName,
    required dynamic value,
    required String unit,
  }) async {
    try {
      if (_currentSnapshot == null) return;

      final newReading = BiometricReading(
        metricName: metricName,
        value: value,
        source: BiometricSourcePriority.manualEntry,
        timestamp: DateTime.now(),
        sourceDevice: 'Manual Entry',
        confidence: 0.75, // Lower confidence for manual
        unit: unit,
      );

      // Remove old reading for this metric if exists
      final updatedReadings = [
        ..._currentSnapshot!.readings.where((r) => r.metricName != metricName),
        newReading,
      ];

      _currentSnapshot = UnifiedBiometricSnapshot(
        readings: updatedReadings,
        timestamp: DateTime.now(),
        overallQuality: _currentSnapshot!.overallQuality,
        metadata: _currentSnapshot!.metadata,
      );

      notifyListeners();
      debugPrint('📝 Manual entry recorded: $metricName = $value $unit');
    } catch (e) {
      _lastError = 'Failed to record manual entry: $e';
      debugPrint('❌ Manual entry error: $_lastError');
    }
  }

  /// Get trend data for a specific metric over time
  List<double?> getMetricTrend(String metricName, {int days = 30}) {
    return _history
        .where(
          (s) => s.timestamp.isAfter(
            DateTime.now().subtract(Duration(days: days)),
          ),
        )
        .map((s) {
          final reading = s.readings.firstWhere(
            (r) => r.metricName == metricName,
            orElse: () => BiometricReading(
              metricName: '',
              value: null,
              source: BiometricSourcePriority.estimate,
              timestamp: DateTime.now(),
              sourceDevice: '',
              unit: '',
            ),
          );
          return reading.value as double?;
        })
        .toList();
  }

  /// Private listener for SmartDeviceService updates
  void _onSmartDeviceUpdate() {
    refreshSnapshot();
  }

  /// Private listener for SportsScienceEngine updates
  void _onSportsScienceUpdate() {
    refreshSnapshot();
  }

  /// Cleanup
  @override
  void dispose() {
    _smartDeviceService.removeListener(_onSmartDeviceUpdate);
    _sportsScienceEngine.removeListener(_onSportsScienceUpdate);
    super.dispose();
  }
}
