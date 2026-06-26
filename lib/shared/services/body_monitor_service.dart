import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;

/// ═══════════════════════════════════════════════════════════════════════════
/// BODY MONITOR SERVICE — Weight, Fluid & Body Composition Tracker
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Tracks: weight, body fat %, muscle mass, fluid intake & losses,
///         transpiration rates during weight cuts.
/// Sources: manual input + smart device sync.
/// AI: Integrates with HealthIntelligenceEngine for analysis.
/// Export: Generates HTML reports for email / print.
///
/// Firestore path: users/{uid}/body_monitor/{docId}
/// ═══════════════════════════════════════════════════════════════════════════

// ─── Input source ──────────────────────────────────────────────
enum MonitorSource {
  manual,
  appleWatch,
  garmin,
  whoop,
  ouraRing,
  smartScale,
  fitbit,
  googleFit,
  polar,
  coros,
  smartGloves,
  sensorMouthguard,
  aiHeadgear,
  chestStrap,
}

extension MonitorSourceX on MonitorSource {
  String get label {
    switch (this) {
      case MonitorSource.manual:
        return 'Manual Entry';
      case MonitorSource.appleWatch:
        return 'Apple Watch';
      case MonitorSource.garmin:
        return 'Garmin';
      case MonitorSource.whoop:
        return 'WHOOP';
      case MonitorSource.ouraRing:
        return 'Oura Ring';
      case MonitorSource.smartScale:
        return 'Smart Scale';
      case MonitorSource.fitbit:
        return 'Fitbit';
      case MonitorSource.googleFit:
        return 'Google Fit';
      case MonitorSource.polar:
        return 'Polar';
      case MonitorSource.coros:
        return 'COROS';
      case MonitorSource.smartGloves:
        return 'Smart Gloves';
      case MonitorSource.sensorMouthguard:
        return 'Sensor Mouthguard';
      case MonitorSource.aiHeadgear:
        return 'AI Headgear';
      case MonitorSource.chestStrap:
        return 'Chest Strap';
    }
  }

  String get icon {
    switch (this) {
      case MonitorSource.manual:
        return '✏️';
      case MonitorSource.appleWatch:
        return '⌚';
      case MonitorSource.garmin:
        return '🏃';
      case MonitorSource.whoop:
        return '💪';
      case MonitorSource.ouraRing:
        return '💍';
      case MonitorSource.smartScale:
        return '⚖️';
      case MonitorSource.fitbit:
        return '📱';
      case MonitorSource.googleFit:
        return '🟢';
      case MonitorSource.polar:
        return '❤️';
      case MonitorSource.coros:
        return '🔵';
      case MonitorSource.smartGloves:
        return '🥊';
      case MonitorSource.sensorMouthguard:
        return '🦷';
      case MonitorSource.aiHeadgear:
        return '🪖';
      case MonitorSource.chestStrap:
        return '🫀';
    }
  }
}

// ─── Fluid type ────────────────────────────────────────────────
enum FluidType {
  water,
  electrolyteWater,
  sportsDrink,
  proteinShake,
  juice,
  coffee,
  other,
}

extension FluidTypeX on FluidType {
  String get label {
    switch (this) {
      case FluidType.water:
        return 'Water';
      case FluidType.electrolyteWater:
        return 'Electrolyte Water';
      case FluidType.sportsDrink:
        return 'Sports Drink';
      case FluidType.proteinShake:
        return 'Protein Shake';
      case FluidType.juice:
        return 'Juice';
      case FluidType.coffee:
        return 'Coffee';
      case FluidType.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case FluidType.water:
        return '💧';
      case FluidType.electrolyteWater:
        return '⚡💧';
      case FluidType.sportsDrink:
        return '🧃';
      case FluidType.proteinShake:
        return '🥤';
      case FluidType.juice:
        return '🍊';
      case FluidType.coffee:
        return '☕';
      case FluidType.other:
        return '🫗';
    }
  }
}

// ─── Weight cut phase (mirrors existing enum) ──────────────────
enum WeightPhase {
  maintenance,
  waterLoading,
  waterReduction,
  finalCut,
  rehydration,
  postFight,
}

extension WeightPhaseX on WeightPhase {
  String get label {
    switch (this) {
      case WeightPhase.maintenance:
        return 'Maintenance';
      case WeightPhase.waterLoading:
        return 'Water Loading';
      case WeightPhase.waterReduction:
        return 'Water Reduction';
      case WeightPhase.finalCut:
        return 'Final Cut';
      case WeightPhase.rehydration:
        return 'Rehydration';
      case WeightPhase.postFight:
        return 'Post-Fight';
    }
  }

  String get emoji {
    switch (this) {
      case WeightPhase.maintenance:
        return '🟢';
      case WeightPhase.waterLoading:
        return '🔵';
      case WeightPhase.waterReduction:
        return '🟡';
      case WeightPhase.finalCut:
        return '🔴';
      case WeightPhase.rehydration:
        return '💚';
      case WeightPhase.postFight:
        return '✅';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WEIGHT LOG ENTRY
// ═══════════════════════════════════════════════════════════════════════════
class WeightLog {
  final String id;
  final DateTime timestamp;
  final double weightLbs; // stored in lbs
  final double? bodyFatPercent;
  final double? muscleMassLbs;
  final double? visceralFat;
  final double? boneMassLbs;
  final double? bmi;
  final MonitorSource source;
  final String notes;

  const WeightLog({
    required this.id,
    required this.timestamp,
    required this.weightLbs,
    this.bodyFatPercent,
    this.muscleMassLbs,
    this.visceralFat,
    this.boneMassLbs,
    this.bmi,
    this.source = MonitorSource.manual,
    this.notes = '',
  });

  double get weightKg => weightLbs * 0.453592;

  Map<String, dynamic> toFirestore() => {
    'timestamp': Timestamp.fromDate(timestamp),
    'weightLbs': weightLbs,
    'bodyFatPercent': bodyFatPercent,
    'muscleMassLbs': muscleMassLbs,
    'visceralFat': visceralFat,
    'boneMassLbs': boneMassLbs,
    'bmi': bmi,
    'source': source.name,
    'notes': notes,
  };

  factory WeightLog.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return WeightLog(
      id: doc.id,
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weightLbs: (d['weightLbs'] as num?)?.toDouble() ?? 0,
      bodyFatPercent: (d['bodyFatPercent'] as num?)?.toDouble(),
      muscleMassLbs: (d['muscleMassLbs'] as num?)?.toDouble(),
      visceralFat: (d['visceralFat'] as num?)?.toDouble(),
      boneMassLbs: (d['boneMassLbs'] as num?)?.toDouble(),
      bmi: (d['bmi'] as num?)?.toDouble(),
      source: MonitorSource.values.firstWhere(
        (e) => e.name == d['source'],
        orElse: () => MonitorSource.manual,
      ),
      notes: d['notes'] as String? ?? '',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FLUID LOG ENTRY
// ═══════════════════════════════════════════════════════════════════════════
class FluidLog {
  final String id;
  final DateTime timestamp;
  final double amountMl;
  final FluidType type;
  final bool isLoss; // false=intake, true=loss (transpiration, sweat, urine)
  final MonitorSource source;
  final String notes;

  const FluidLog({
    required this.id,
    required this.timestamp,
    required this.amountMl,
    this.type = FluidType.water,
    this.isLoss = false,
    this.source = MonitorSource.manual,
    this.notes = '',
  });

  double get amountOz => amountMl / 29.5735;

  Map<String, dynamic> toFirestore() => {
    'timestamp': Timestamp.fromDate(timestamp),
    'amountMl': amountMl,
    'type': type.name,
    'isLoss': isLoss,
    'source': source.name,
    'notes': notes,
  };

  factory FluidLog.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FluidLog(
      id: doc.id,
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      amountMl: (d['amountMl'] as num?)?.toDouble() ?? 0,
      type: FluidType.values.firstWhere(
        (e) => e.name == d['type'],
        orElse: () => FluidType.water,
      ),
      isLoss: d['isLoss'] as bool? ?? false,
      source: MonitorSource.values.firstWhere(
        (e) => e.name == d['source'],
        orElse: () => MonitorSource.manual,
      ),
      notes: d['notes'] as String? ?? '',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EYE CHECK LOG ENTRY (Safety Checkpoint)
// ═══════════════════════════════════════════════════════════════════════════
class EyeCheckLog {
  final String id;
  final DateTime timestamp;
  final double leftPupilSizeMm;
  final double rightPupilSizeMm;
  final double reactionTimeMs;
  final bool hasRedness;
  final bool hasAnisocoria; // Unequal pupil sizes
  final MonitorSource source;
  final String notes;

  const EyeCheckLog({
    required this.id,
    required this.timestamp,
    required this.leftPupilSizeMm,
    required this.rightPupilSizeMm,
    required this.reactionTimeMs,
    this.hasRedness = false,
    this.hasAnisocoria = false,
    this.source = MonitorSource.manual,
    this.notes = '',
  });

  Map<String, dynamic> toFirestore() => {
    'timestamp': Timestamp.fromDate(timestamp),
    'leftPupilSizeMm': leftPupilSizeMm,
    'rightPupilSizeMm': rightPupilSizeMm,
    'reactionTimeMs': reactionTimeMs,
    'hasRedness': hasRedness,
    'hasAnisocoria': hasAnisocoria,
    'source': source.name,
    'notes': notes,
  };

  factory EyeCheckLog.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return EyeCheckLog(
      id: doc.id,
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      leftPupilSizeMm: (d['leftPupilSizeMm'] as num?)?.toDouble() ?? 0,
      rightPupilSizeMm: (d['rightPupilSizeMm'] as num?)?.toDouble() ?? 0,
      reactionTimeMs: (d['reactionTimeMs'] as num?)?.toDouble() ?? 0,
      hasRedness: d['hasRedness'] as bool? ?? false,
      hasAnisocoria: d['hasAnisocoria'] as bool? ?? false,
      source: MonitorSource.values.firstWhere(
        (e) => e.name == d['source'],
        orElse: () => MonitorSource.manual,
      ),
      notes: d['notes'] as String? ?? '',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DAILY BODY SNAPSHOT — AI-aggregated daily summary
// ═══════════════════════════════════════════════════════════════════════════
class DailyBodySnapshot {
  final DateTime date;
  final double? morningWeight;
  final double? eveningWeight;
  final double? bodyFatPercent;
  final double totalFluidIntakeMl;
  final double totalFluidLossMl;
  final double netFluidBalanceMl;
  final double? transpirationRateMlPerHour;
  final WeightPhase phase;
  final double? targetWeightLbs;
  final double? weightChangeFromYesterday;
  final String aiInsight;

  const DailyBodySnapshot({
    required this.date,
    this.morningWeight,
    this.eveningWeight,
    this.bodyFatPercent,
    this.totalFluidIntakeMl = 0,
    this.totalFluidLossMl = 0,
    this.netFluidBalanceMl = 0,
    this.transpirationRateMlPerHour,
    this.phase = WeightPhase.maintenance,
    this.targetWeightLbs,
    this.weightChangeFromYesterday,
    this.aiInsight = '',
  });

  double get hydrationPercentEstimate {
    if (totalFluidIntakeMl <= 0) return 50.0;
    // Rough estimate: healthy is ~3500ml/day
    final ratio = totalFluidIntakeMl / 3500.0;
    return (ratio * 100).clamp(0, 100);
  }

  String get hydrationStatus {
    final pct = hydrationPercentEstimate;
    if (pct < 30) return '🔴 CRITICAL';
    if (pct < 50) return '🟠 LOW';
    if (pct < 70) return '🟡 MODERATE';
    if (pct < 90) return '🟢 OPTIMAL';
    return '🔵 HIGH';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BODY MONITOR SERVICE
// ═══════════════════════════════════════════════════════════════════════════
class BodyMonitorService extends ChangeNotifier {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  // Current state
  List<WeightLog> _weightLogs = [];
  List<FluidLog> _fluidLogs = [];
  List<EyeCheckLog> _eyeCheckLogs = [];
  DailyBodySnapshot? _todaySnapshot;
  List<DailyBodySnapshot> _weekSnapshots = [];
  bool _loading = false;
  WeightPhase _currentPhase = WeightPhase.maintenance;
  double? _targetWeight;

  // Getters
  List<WeightLog> get weightLogs => _weightLogs;
  List<FluidLog> get fluidLogs => _fluidLogs;
  List<EyeCheckLog> get eyeCheckLogs => _eyeCheckLogs;
  DailyBodySnapshot? get todaySnapshot => _todaySnapshot;
  List<DailyBodySnapshot> get weekSnapshots => _weekSnapshots;
  bool get loading => _loading;
  WeightPhase get currentPhase => _currentPhase;
  double? get targetWeight => _targetWeight;

  // Latest weight
  double? get latestWeight =>
      _weightLogs.isNotEmpty ? _weightLogs.first.weightLbs : null;
  double? get latestBodyFat =>
      _weightLogs.isNotEmpty ? _weightLogs.first.bodyFatPercent : null;

  // Today's fluid total
  double get todayFluidIntake => _fluidLogs
      .where((f) => !f.isLoss)
      .fold(0.0, (runningTotal, f) => runningTotal + f.amountMl);
  double get todayFluidLoss => _fluidLogs
      .where((f) => f.isLoss)
      .fold(0.0, (runningTotal, f) => runningTotal + f.amountMl);
  double get netFluidBalance => todayFluidIntake - todayFluidLoss;

  // Firestore refs
  CollectionReference _weightCol(String uid) =>
      _fs.collection('users').doc(uid).collection('weight_logs');
  CollectionReference _fluidCol(String uid) =>
      _fs.collection('users').doc(uid).collection('fluid_logs');
  CollectionReference _eyeCheckCol(String uid) =>
      _fs.collection('users').doc(uid).collection('eye_check_logs');

  // ─── SET WEIGHT CUT TARGET ──────────────────────────────────
  void setTarget(double targetLbs, WeightPhase phase) {
    _targetWeight = targetLbs;
    _currentPhase = phase;
    notifyListeners();
  }

  // ─── LOAD TODAY'S DATA ──────────────────────────────────────
  Future<void> loadToday(String uid) async {
    _loading = true;
    notifyListeners();

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    try {
      final wSnap = await _weightCol(uid)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThan: Timestamp.fromDate(end))
          .orderBy('timestamp', descending: true)
          .get();
      _weightLogs = wSnap.docs.map(WeightLog.fromFirestore).toList();

      final fSnap = await _fluidCol(uid)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThan: Timestamp.fromDate(end))
          .orderBy('timestamp', descending: true)
          .get();
      _fluidLogs = fSnap.docs.map(FluidLog.fromFirestore).toList();

      final eSnap = await _eyeCheckCol(uid)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThan: Timestamp.fromDate(end))
          .orderBy('timestamp', descending: true)
          .get();
      _eyeCheckLogs = eSnap.docs
          .map(EyeCheckLog.fromFirestore)
          .toList();
    } catch (_) {
      _weightLogs = _demoWeightLogs();
      _fluidLogs = _demoFluidLogs();
      _eyeCheckLogs = _demoEyeCheckLogs();
    }

    _todaySnapshot = _buildSnapshot(now, _weightLogs, _fluidLogs);
    _loading = false;
    notifyListeners();
  }

  // ─── LOAD WEEK ──────────────────────────────────────────────
  Future<void> loadWeek(String uid) async {
    final now = DateTime.now();
    // Build snapshots for last 7 days
    _weekSnapshots = [];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      _weekSnapshots.add(_buildDemoSnapshot(day, i));
    }
    notifyListeners();
  }

  // ─── LOG WEIGHT (manual) ────────────────────────────────────
  Future<void> logWeight(
    String uid, {
    required double weightLbs,
    double? bodyFatPercent,
    double? muscleMassLbs,
    MonitorSource source = MonitorSource.manual,
    String notes = '',
  }) async {
    final log = WeightLog(
      id: '',
      timestamp: DateTime.now(),
      weightLbs: weightLbs,
      bodyFatPercent: bodyFatPercent,
      muscleMassLbs: muscleMassLbs,
      source: source,
      notes: notes,
    );
    try {
      await _weightCol(uid).add(log.toFirestore());
    } catch (e) {
      debugPrint('BodyMonitorService.logWeight error: $e');
    }
    await loadToday(uid);
  }

  // ─── LOG FLUID (manual) ─────────────────────────────────────
  Future<void> logFluid(
    String uid, {
    required double amountMl,
    FluidType type = FluidType.water,
    bool isLoss = false,
    MonitorSource source = MonitorSource.manual,
    String notes = '',
  }) async {
    final log = FluidLog(
      id: '',
      timestamp: DateTime.now(),
      amountMl: amountMl,
      type: type,
      isLoss: isLoss,
      source: source,
      notes: notes,
    );
    try {
      await _fluidCol(uid).add(log.toFirestore());
    } catch (e) {
      debugPrint('BodyMonitorService.logFluid error: $e');
    }
    await loadToday(uid);
  }

  // ─── DELETE WEIGHT LOG ──────────────────────────────────────
  Future<void> deleteWeightLog(String uid, String logId) async {
    try {
      await _weightCol(uid).doc(logId).delete();
    } catch (e) {
      debugPrint('BodyMonitorService.deleteWeightLog error: $e');
    }
    _weightLogs.removeWhere((l) => l.id == logId);
    notifyListeners();
  }

  // ─── DELETE FLUID LOG ───────────────────────────────────────
  Future<void> deleteFluidLog(String uid, String logId) async {
    try {
      await _fluidCol(uid).doc(logId).delete();
    } catch (e) {
      debugPrint('BodyMonitorService.deleteFluidLog error: $e');
    }
    _fluidLogs.removeWhere((l) => l.id == logId);
    notifyListeners();
  }

  // ─── LOG EYE CHECK (Safety Checkpoint) ──────────────────────
  Future<void> logEyeCheck(
    String uid, {
    required double leftPupilSizeMm,
    required double rightPupilSizeMm,
    required double reactionTimeMs,
    bool hasRedness = false,
    bool hasAnisocoria = false,
    MonitorSource source = MonitorSource.manual,
    String notes = '',
  }) async {
    final log = EyeCheckLog(
      id: '',
      timestamp: DateTime.now(),
      leftPupilSizeMm: leftPupilSizeMm,
      rightPupilSizeMm: rightPupilSizeMm,
      reactionTimeMs: reactionTimeMs,
      hasRedness: hasRedness,
      hasAnisocoria: hasAnisocoria,
      source: source,
      notes: notes,
    );
    try {
      await _eyeCheckCol(uid).add(log.toFirestore());
    } catch (e) {
      debugPrint('BodyMonitorService.logEyeCheck error: $e');
    }
    await loadToday(uid);
  }

  // ─── DELETE EYE CHECK LOG ───────────────────────────────────
  Future<void> deleteEyeCheckLog(String uid, String logId) async {
    try {
      await _eyeCheckCol(uid).doc(logId).delete();
    } catch (e) {
      debugPrint('BodyMonitorService.deleteEyeCheckLog error: $e');
    }
    _eyeCheckLogs.removeWhere((l) => l.id == logId);
    notifyListeners();
  }

  // ─── SYNC FROM DEVICE ──────────────────────────────────────
  Future<void> syncFromDevice(String uid, MonitorSource device) async {
    // In production, call SmartDeviceService.syncAll() and parse data
    // For now, simulate device sync
    await logWeight(
      uid,
      weightLbs: 161.8 + (math.Random().nextDouble() * 2 - 1),
      bodyFatPercent: 12.4 + (math.Random().nextDouble() * 1 - 0.5),
      muscleMassLbs: 142.5,
      source: device,
      notes: 'Synced from ${device.label}',
    );
  }

  // ─── COMPUTE TRANSPIRATION RATE ─────────────────────────────
  double? computeTranspirationRate(
    double preWorkoutWeightLbs,
    double postWorkoutWeightLbs,
    int workoutMinutes,
    double fluidConsumedMlDuringWorkout,
  ) {
    if (workoutMinutes <= 0) return null;
    final weightLostLbs = preWorkoutWeightLbs - postWorkoutWeightLbs;
    final weightLostMl = weightLostLbs * 453.592; // 1 lb ≈ 453ml water
    final totalSweatLoss = weightLostMl + fluidConsumedMlDuringWorkout;
    return (totalSweatLoss / workoutMinutes) * 60; // ml/hour
  }

  // ─── GENERATE EXPORT HTML ──────────────────────────────────
  String generateExportHtml({
    required String fighterName,
    required List<DailyBodySnapshot> snapshots,
    required List<WeightLog> recentWeights,
    required List<FluidLog> recentFluids,
  }) {
    final buf = StringBuffer();
    buf.writeln('<!DOCTYPE html><html><head>');
    buf.writeln(
      '<meta charset="UTF-8"><title>Body Monitor Report — $fighterName</title>',
    );
    buf.writeln('<style>');
    buf.writeln(
      'body{font-family:system-ui;background:#0a0a0a;color:#e0e0e0;padding:20px;}',
    );
    buf.writeln(
      'h1{color:#00e5ff;border-bottom:2px solid #00e5ff;padding-bottom:10px;}',
    );
    buf.writeln('h2{color:#76ff03;margin-top:24px;}');
    buf.writeln('table{width:100%;border-collapse:collapse;margin:12px 0;}');
    buf.writeln(
      'th,td{padding:8px 12px;border:1px solid #333;text-align:left;}',
    );
    buf.writeln('th{background:#1a1a2e;color:#00e5ff;}');
    buf.writeln('tr:nth-child(even){background:#111;}');
    buf.writeln(
      '.metric{display:inline-block;background:#1a1a2e;border:1px solid #00e5ff;border-radius:8px;padding:12px 16px;margin:6px;text-align:center;min-width:120px;}',
    );
    buf.writeln(
      '.metric .value{font-size:24px;font-weight:bold;color:#00e5ff;}',
    );
    buf.writeln(
      '.metric .label{font-size:11px;color:#888;text-transform:uppercase;}',
    );
    buf.writeln(
      '.alert{background:#ff1744;color:white;padding:8px;border-radius:4px;margin:4px 0;}',
    );
    buf.writeln('</style></head><body>');

    // Header
    buf.writeln('<h1>⚖️ BODY MONITOR REPORT</h1>');
    buf.writeln('<p><strong>Fighter:</strong> $fighterName</p>');
    buf.writeln(
      '<p><strong>Generated:</strong> ${DateTime.now().toString().substring(0, 16)}</p>',
    );

    // Current metrics
    if (recentWeights.isNotEmpty) {
      final latest = recentWeights.first;
      buf.writeln('<h2>📊 Current Metrics</h2>');
      buf.writeln('<div>');
      buf.writeln(
        '<div class="metric"><div class="value">${latest.weightLbs.toStringAsFixed(1)} lbs</div><div class="label">Weight</div></div>',
      );
      if (latest.bodyFatPercent != null) {
        buf.writeln(
          '<div class="metric"><div class="value">${latest.bodyFatPercent!.toStringAsFixed(1)}%</div><div class="label">Body Fat</div></div>',
        );
      }
      if (latest.muscleMassLbs != null) {
        buf.writeln(
          '<div class="metric"><div class="value">${latest.muscleMassLbs!.toStringAsFixed(1)} lbs</div><div class="label">Muscle Mass</div></div>',
        );
      }
      buf.writeln('</div>');
    }

    // Weight history table
    if (recentWeights.isNotEmpty) {
      buf.writeln('<h2>⚖️ Weight History</h2>');
      buf.writeln(
        '<table><tr><th>Date/Time</th><th>Weight (lbs)</th><th>Body Fat %</th><th>Source</th><th>Notes</th></tr>',
      );
      for (final w in recentWeights.take(30)) {
        buf.writeln(
          '<tr><td>${w.timestamp.toString().substring(0, 16)}</td><td>${w.weightLbs.toStringAsFixed(1)}</td><td>${w.bodyFatPercent?.toStringAsFixed(1) ?? '—'}</td><td>${w.source.label}</td><td>${w.notes}</td></tr>',
        );
      }
      buf.writeln('</table>');
    }

    // Fluid log table
    if (recentFluids.isNotEmpty) {
      buf.writeln('<h2>💧 Fluid Log</h2>');
      buf.writeln(
        '<table><tr><th>Time</th><th>Amount (ml)</th><th>Type</th><th>In/Out</th><th>Source</th></tr>',
      );
      for (final f in recentFluids.take(50)) {
        buf.writeln(
          '<tr><td>${f.timestamp.toString().substring(11, 16)}</td><td>${f.amountMl.toStringAsFixed(0)}</td><td>${f.type.label}</td><td>${f.isLoss ? "LOSS" : "INTAKE"}</td><td>${f.source.label}</td></tr>',
        );
      }
      buf.writeln('</table>');
    }

    // Daily snapshots
    if (snapshots.isNotEmpty) {
      buf.writeln('<h2>📅 Daily Snapshots</h2>');
      buf.writeln(
        '<table><tr><th>Date</th><th>AM Weight</th><th>PM Weight</th><th>Fluid In</th><th>Fluid Out</th><th>Net</th><th>Phase</th><th>AI Insight</th></tr>',
      );
      for (final s in snapshots) {
        buf.writeln(
          '<tr><td>${s.date.toString().substring(0, 10)}</td><td>${s.morningWeight?.toStringAsFixed(1) ?? '—'}</td><td>${s.eveningWeight?.toStringAsFixed(1) ?? '—'}</td><td>${s.totalFluidIntakeMl.toStringAsFixed(0)}ml</td><td>${s.totalFluidLossMl.toStringAsFixed(0)}ml</td><td>${s.netFluidBalanceMl.toStringAsFixed(0)}ml</td><td>${s.phase.label}</td><td>${s.aiInsight}</td></tr>',
        );
      }
      buf.writeln('</table>');
    }

    buf.writeln(
      '<p style="color:#555;margin-top:30px;font-size:11px;">Generated by Data Fight Central — Body Monitor AI</p>',
    );
    buf.writeln('</body></html>');
    return buf.toString();
  }

  // ─── GENERATE AI WEIGHT-CUT ANALYSIS ────────────────────────
  Map<String, dynamic> analyzeWeightCut(
    List<WeightLog> logs,
    double targetLbs,
    DateTime fightDate,
  ) {
    if (logs.isEmpty) {
      return {
        'status': 'No data',
        'riskLevel': 'UNKNOWN',
        'recommendation': 'Start logging weight to enable AI analysis.',
      };
    }

    final latest = logs.first.weightLbs;
    final toCut = latest - targetLbs;
    final daysLeft = fightDate.difference(DateTime.now()).inDays;
    final dailyRate = daysLeft > 0 ? toCut / daysLeft : toCut;

    String risk;
    String recommendation;

    if (dailyRate > 2.0) {
      risk = '🔴 CRITICAL';
      recommendation =
          'Daily weight loss rate of ${dailyRate.toStringAsFixed(1)} lbs/day is DANGEROUS. '
          'Consider moving up a weight class or consult a nutritionist immediately.';
    } else if (dailyRate > 1.5) {
      risk = '🟠 HIGH';
      recommendation =
          'Aggressive cut needed (${dailyRate.toStringAsFixed(1)} lbs/day). '
          'Begin water manipulation protocol. Monitor kidney markers closely.';
    } else if (dailyRate > 0.8) {
      risk = '🟡 MODERATE';
      recommendation =
          'Manageable cut (${dailyRate.toStringAsFixed(1)} lbs/day). '
          'Stay disciplined with diet. Increase cardio slightly.';
    } else if (toCut <= 0) {
      risk = '🟢 ON WEIGHT';
      recommendation =
          'You\'re at or below target weight. Focus on maintaining.';
    } else {
      risk = '🟢 COMFORTABLE';
      recommendation =
          'Comfortable timeline (${dailyRate.toStringAsFixed(2)} lbs/day). '
          'Keep steady progression. No extreme measures needed.';
    }

    // Calculate 7-day trend
    double? weeklyTrend;
    if (logs.length >= 2) {
      final recent = logs.first.weightLbs;
      final older = logs.length >= 7 ? logs[6].weightLbs : logs.last.weightLbs;
      weeklyTrend = recent - older;
    }

    return {
      'currentWeight': latest,
      'targetWeight': targetLbs,
      'toCut': toCut,
      'daysLeft': daysLeft,
      'dailyRate': dailyRate,
      'riskLevel': risk,
      'recommendation': recommendation,
      'weeklyTrend': weeklyTrend,
    };
  }

  // ─── BUILD DAILY SNAPSHOT ──────────────────────────────────
  DailyBodySnapshot _buildSnapshot(
    DateTime date,
    List<WeightLog> weights,
    List<FluidLog> fluids,
  ) {
    final intake = fluids
        .where((f) => !f.isLoss)
        .fold(0.0, (runningTotal, f) => runningTotal + f.amountMl);
    final loss = fluids
        .where((f) => f.isLoss)
        .fold(0.0, (runningTotal, f) => runningTotal + f.amountMl);

    double? morning;
    double? evening;
    for (final w in weights) {
      if (w.timestamp.hour < 12) {
        morning ??= w.weightLbs;
      } else {
        evening ??= w.weightLbs;
      }
    }

    return DailyBodySnapshot(
      date: date,
      morningWeight:
          morning ?? (weights.isNotEmpty ? weights.first.weightLbs : null),
      eveningWeight: evening,
      bodyFatPercent: weights.isNotEmpty ? weights.first.bodyFatPercent : null,
      totalFluidIntakeMl: intake,
      totalFluidLossMl: loss,
      netFluidBalanceMl: intake - loss,
      phase: _currentPhase,
      targetWeightLbs: _targetWeight,
      aiInsight: _generateInsight(morning, evening, intake, loss),
    );
  }

  String _generateInsight(double? am, double? pm, double intake, double loss) {
    final buf = StringBuffer();
    if (am != null && pm != null) {
      final diff = pm - am;
      buf.write(
        'Weight fluctuation: ${diff > 0 ? "+" : ""}${diff.toStringAsFixed(1)} lbs today. ',
      );
    }
    if (intake < 1500) {
      buf.write('⚠️ Low fluid intake — increase water consumption. ');
    } else if (intake > 4000) {
      buf.write('Water loading phase detected. ');
    }
    if (loss > 0 && intake > 0) {
      final ratio = loss / intake;
      if (ratio > 0.8) {
        buf.write('🔴 High transpiration rate — dehydration risk! ');
      }
    }
    if (buf.isEmpty) buf.write('Tracking on schedule. Stay consistent.');
    return buf.toString();
  }

  // ─── DEMO DATA ────────────────────────────────────────────
  List<WeightLog> _demoWeightLogs() {
    final now = DateTime.now();
    return [
      WeightLog(
        id: 'dw_1',
        timestamp: DateTime(now.year, now.month, now.day, 6, 30),
        weightLbs: 162.4,
        bodyFatPercent: 12.3,
        muscleMassLbs: 142.5,
        source: MonitorSource.smartScale,
        notes: 'Morning weigh-in (fasted)',
      ),
      WeightLog(
        id: 'dw_2',
        timestamp: DateTime(now.year, now.month, now.day, 18),
        weightLbs: 164.1,
        bodyFatPercent: 12.3,
        source: MonitorSource.smartScale,
        notes: 'Evening weigh-in',
      ),
    ];
  }

  List<FluidLog> _demoFluidLogs() {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day);
    return [
      FluidLog(
        id: 'df_1',
        timestamp: d.add(const Duration(hours: 6)),
        amountMl: 500,
        notes: 'Wake-up hydration',
      ),
      FluidLog(
        id: 'df_2',
        timestamp: d.add(const Duration(hours: 7, minutes: 30)),
        amountMl: 350,
        type: FluidType.electrolyteWater,
        notes: 'During morning training',
      ),
      FluidLog(
        id: 'df_3',
        timestamp: d.add(const Duration(hours: 7, minutes: 30)),
        amountMl: 800,
        isLoss: true,
        notes: 'Estimated sweat loss — boxing session',
      ),
      FluidLog(
        id: 'df_4',
        timestamp: d.add(const Duration(hours: 10)),
        amountMl: 500,
        type: FluidType.proteinShake,
        notes: 'Post-strength shake',
      ),
      FluidLog(
        id: 'df_5',
        timestamp: d.add(const Duration(hours: 12)),
        amountMl: 750,
        notes: 'Lunch hydration',
      ),
      FluidLog(
        id: 'df_6',
        timestamp: d.add(const Duration(hours: 14, minutes: 30)),
        amountMl: 650,
        isLoss: true,
        notes: 'Estimated sweat loss — BJJ session',
      ),
      FluidLog(
        id: 'df_7',
        timestamp: d.add(const Duration(hours: 15)),
        amountMl: 500,
        type: FluidType.electrolyteWater,
        notes: 'Post-grappling recovery',
      ),
      FluidLog(
        id: 'df_8',
        timestamp: d.add(const Duration(hours: 17)),
        amountMl: 350,
        notes: 'Afternoon sip',
      ),
    ];
  }

  List<EyeCheckLog> _demoEyeCheckLogs() {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day);
    return [
      EyeCheckLog(
        id: 'de_1',
        timestamp: d.add(const Duration(hours: 6, minutes: 45)),
        leftPupilSizeMm: 3.2,
        rightPupilSizeMm: 3.2,
        reactionTimeMs: 210,
        source: MonitorSource.aiHeadgear,
        notes: 'Morning baseline check. Normal reactivity.',
      ),
      EyeCheckLog(
        id: 'de_2',
        timestamp: d.add(const Duration(hours: 15, minutes: 30)),
        leftPupilSizeMm: 3.5,
        rightPupilSizeMm: 3.5,
        reactionTimeMs: 245,
        hasRedness: true,
        notes:
            'Post-sparring check. Slight redness, reaction time slightly elevated but within safe limits.',
      ),
    ];
  }

  DailyBodySnapshot _buildDemoSnapshot(DateTime day, int daysAgo) {
    final r = math.Random(day.day);
    final baseWeight = 162.0 + r.nextDouble() * 3;
    return DailyBodySnapshot(
      date: day,
      morningWeight: baseWeight - 0.5,
      eveningWeight: baseWeight + 1.2,
      bodyFatPercent: 12.0 + r.nextDouble() * 0.8,
      totalFluidIntakeMl: 2500 + r.nextDouble() * 1500,
      totalFluidLossMl: 1200 + r.nextDouble() * 800,
      netFluidBalanceMl: 1000 + r.nextDouble() * 500,
      transpirationRateMlPerHour: 500 + r.nextDouble() * 300,
      targetWeightLbs: 155.0,
      weightChangeFromYesterday: daysAgo > 0
          ? -(0.2 + r.nextDouble() * 0.3)
          : null,
      aiInsight: daysAgo == 0
          ? 'On track. Maintain hydration protocol.'
          : 'Steady progress — ${(baseWeight - 155).toStringAsFixed(1)} lbs to target.',
    );
  }
}
