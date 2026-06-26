import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ═════════════════════════════════════════════════════════════════════════════
// DFC QoE SERVICE — Per-Session Stream Quality Telemetry
// ═════════════════════════════════════════════════════════════════════════════
//
// Provides:
//   • Per-session metric ingestion (startup, rebuffer, bitrate, resolution)
//   • Session health scoring (0–100)
//   • Event-level QoE aggregation for ops dashboards
//   • Auto-remediation: rebuffer > threshold → CDN switch event
//   • Ops alert: high error rate → Firestore flag for ops review
//
// Firestore Collections:
//   qoe_sessions/{sessionId}/metrics/{metricId}  — raw metric entries
//   qoe_sessions/{sessionId}                     — session summary doc
//   qoe_alerts/{alertId}                         — ops alert queue
//   qoe_event_summaries/{eventId}                — aggregated event QoE
//
// ═════════════════════════════════════════════════════════════════════════════

// ── Enums ──────────────────────────────────────────────────────────────────

enum QoeMetricType {
  startupTime, // ms to first frame
  rebufferRatio, // 0.0–1.0
  bitrateDrop, // Kbps drop delta
  resolutionChange,
  playbackError,
  cdnSwitch,
  sessionEnd,
}

enum QoeAlertSeverity { low, medium, high, critical }

enum QoeAlertStatus { open, acknowledged, resolved }

// ── Models ─────────────────────────────────────────────────────────────────

class QoeMetric {
  final String sessionId;
  final QoeMetricType type;
  final double value;
  final String? detail;
  final DateTime timestamp;

  const QoeMetric({
    required this.sessionId,
    required this.type,
    required this.value,
    this.detail,
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() => {
    'sessionId': sessionId,
    'type': type.name,
    'value': value,
    'detail': detail,
    'timestamp': Timestamp.fromDate(timestamp),
  };

  factory QoeMetric.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return QoeMetric(
      sessionId: d['sessionId'] ?? '',
      type: QoeMetricType.values.firstWhere(
        (t) => t.name == (d['type'] ?? ''),
        orElse: () => QoeMetricType.playbackError,
      ),
      value: (d['value'] ?? 0).toDouble(),
      detail: d['detail'],
      timestamp: (d['timestamp'] as Timestamp).toDate(),
    );
  }
}

class SessionHealth {
  final String sessionId;
  final String? eventId;
  final String? userId;
  final double healthScore; // 0–100
  final int metricCount;
  final double avgStartupMs;
  final double avgRebufferRatio;
  final int errorCount;
  final int cdnSwitchCount;
  final DateTime lastUpdated;

  const SessionHealth({
    required this.sessionId,
    this.eventId,
    this.userId,
    required this.healthScore,
    required this.metricCount,
    required this.avgStartupMs,
    required this.avgRebufferRatio,
    required this.errorCount,
    required this.cdnSwitchCount,
    required this.lastUpdated,
  });

  String get healthLabel {
    if (healthScore >= 80) return 'Excellent';
    if (healthScore >= 60) return 'Good';
    if (healthScore >= 40) return 'Fair';
    return 'Poor';
  }

  factory SessionHealth.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SessionHealth(
      sessionId: doc.id,
      eventId: d['eventId'],
      userId: d['userId'],
      healthScore: (d['healthScore'] ?? 100).toDouble(),
      metricCount: (d['metricCount'] ?? 0) as int,
      avgStartupMs: (d['avgStartupMs'] ?? 0).toDouble(),
      avgRebufferRatio: (d['avgRebufferRatio'] ?? 0).toDouble(),
      errorCount: (d['errorCount'] ?? 0) as int,
      cdnSwitchCount: (d['cdnSwitchCount'] ?? 0) as int,
      lastUpdated: (d['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'eventId': eventId,
    'userId': userId,
    'healthScore': healthScore,
    'metricCount': metricCount,
    'avgStartupMs': avgStartupMs,
    'avgRebufferRatio': avgRebufferRatio,
    'errorCount': errorCount,
    'cdnSwitchCount': cdnSwitchCount,
    'lastUpdated': FieldValue.serverTimestamp(),
  };
}

class QoeAlert {
  final String alertId;
  final String? eventId;
  final String? sessionId;
  final QoeAlertSeverity severity;
  final QoeAlertStatus status;
  final String message;
  final String trigger; // e.g. 'rebuffer_threshold', 'error_rate'
  final DateTime createdAt;

  const QoeAlert({
    required this.alertId,
    this.eventId,
    this.sessionId,
    required this.severity,
    required this.status,
    required this.message,
    required this.trigger,
    required this.createdAt,
  });

  factory QoeAlert.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return QoeAlert(
      alertId: doc.id,
      eventId: d['eventId'],
      sessionId: d['sessionId'],
      severity: QoeAlertSeverity.values.firstWhere(
        (s) => s.name == (d['severity'] ?? 'medium'),
        orElse: () => QoeAlertSeverity.medium,
      ),
      status: QoeAlertStatus.values.firstWhere(
        (s) => s.name == (d['status'] ?? 'open'),
        orElse: () => QoeAlertStatus.open,
      ),
      message: d['message'] ?? '',
      trigger: d['trigger'] ?? '',
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'eventId': eventId,
    'sessionId': sessionId,
    'severity': severity.name,
    'status': status.name,
    'message': message,
    'trigger': trigger,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

class EventQoeSummary {
  final String eventId;
  final int totalSessions;
  final double avgHealthScore;
  final double avgStartupMs;
  final double avgRebufferRatio;
  final int totalErrors;
  final int totalCdnSwitches;
  final DateTime updatedAt;

  const EventQoeSummary({
    required this.eventId,
    required this.totalSessions,
    required this.avgHealthScore,
    required this.avgStartupMs,
    required this.avgRebufferRatio,
    required this.totalErrors,
    required this.totalCdnSwitches,
    required this.updatedAt,
  });

  factory EventQoeSummary.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return EventQoeSummary(
      eventId: doc.id,
      totalSessions: (d['totalSessions'] ?? 0) as int,
      avgHealthScore: (d['avgHealthScore'] ?? 100).toDouble(),
      avgStartupMs: (d['avgStartupMs'] ?? 0).toDouble(),
      avgRebufferRatio: (d['avgRebufferRatio'] ?? 0).toDouble(),
      totalErrors: (d['totalErrors'] ?? 0) as int,
      totalCdnSwitches: (d['totalCdnSwitches'] ?? 0) as int,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// ── Thresholds ──────────────────────────────────────────────────────────────

class _Thresholds {
  static const double rebufferCritical = 0.15; // >15% rebuffer → CDN switch
  static const double rebufferHigh = 0.08; // >8% → high alert
  static const double startupSlowMs = 5000; // >5s startup → alert
  static const int errorRateHigh = 5; // >5 errors/session → flag ops
}

// ── Service ────────────────────────────────────────────────────────────────

class DfcQoeService extends ChangeNotifier {
  DfcQoeService._();
  static final DfcQoeService instance = DfcQoeService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _sessionsCol = 'qoe_sessions';
  static const String _alertsCol = 'qoe_alerts';
  static const String _summariesCol = 'qoe_event_summaries';

  // In-memory session accumulators keyed by sessionId
  final Map<String, _SessionAccumulator> _accumulators = {};

  // ── Metric Ingestion ──────────────────────────────────────────────────

  /// Log a single QoE metric for a session. Auto-triggers remediation.
  Future<void> logSessionMetric({
    required String sessionId,
    required QoeMetricType type,
    required double value,
    String? eventId,
    String? userId,
    String? detail,
  }) async {
    assert(sessionId.isNotEmpty, 'sessionId required');
    try {
      final metric = QoeMetric(
        sessionId: sessionId,
        type: type,
        value: value,
        detail: detail,
        timestamp: DateTime.now().toUtc(),
      );

      // Write metric subcollection
      await _db
          .collection(_sessionsCol)
          .doc(sessionId)
          .collection('metrics')
          .add(metric.toFirestore());

      // Update in-memory accumulator
      final acc = _accumulators.putIfAbsent(
        sessionId,
        () => _SessionAccumulator(
          sessionId: sessionId,
          eventId: eventId,
          userId: userId,
        ),
      );
      acc.ingest(metric);

      // Persist updated session summary
      final health = acc.computeHealth();
      await _db
          .collection(_sessionsCol)
          .doc(sessionId)
          .set(health.toFirestore(), SetOptions(merge: true));

      // Auto-remediation checks
      await _runRemediations(acc, health, metric);

      notifyListeners();
    } catch (e) {
      debugPrint('[DfcQoeService] logSessionMetric error: $e');
    }
  }

  // ── Session Health ────────────────────────────────────────────────────

  /// Get current health snapshot for a session.
  Future<SessionHealth?> getSessionHealth(String sessionId) async {
    // Prefer in-memory accumulator if available
    final acc = _accumulators[sessionId];
    if (acc != null) return acc.computeHealth();

    try {
      final doc = await _db.collection(_sessionsCol).doc(sessionId).get();
      if (!doc.exists) return null;
      return SessionHealth.fromFirestore(doc);
    } catch (e) {
      debugPrint('[DfcQoeService] getSessionHealth error: $e');
      return null;
    }
  }

  Stream<SessionHealth?> streamSessionHealth(String sessionId) {
    return _db
        .collection(_sessionsCol)
        .doc(sessionId)
        .snapshots()
        .map((doc) => doc.exists ? SessionHealth.fromFirestore(doc) : null)
        .handleError((e) {
          debugPrint('[DfcQoeService] streamSessionHealth error: $e');
          return null;
        });
  }

  // ── Event QoE Summary ─────────────────────────────────────────────────

  /// Get aggregated QoE summary for an event.
  Future<EventQoeSummary?> getEventQoeSummary(String eventId) async {
    try {
      final doc = await _db.collection(_summariesCol).doc(eventId).get();
      if (!doc.exists) return null;
      return EventQoeSummary.fromFirestore(doc);
    } catch (e) {
      debugPrint('[DfcQoeService] getEventQoeSummary error: $e');
      return null;
    }
  }

  Stream<EventQoeSummary?> streamEventQoeSummary(String eventId) {
    return _db
        .collection(_summariesCol)
        .doc(eventId)
        .snapshots()
        .map((doc) => doc.exists ? EventQoeSummary.fromFirestore(doc) : null)
        .handleError((e) {
          debugPrint('[DfcQoeService] streamEventQoeSummary error: $e');
          return null;
        });
  }

  // ── Ops Alerts ────────────────────────────────────────────────────────

  Stream<List<QoeAlert>> streamOpenAlerts({int limit = 50}) {
    return _db
        .collection(_alertsCol)
        .where('status', isEqualTo: QoeAlertStatus.open.name)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(QoeAlert.fromFirestore).toList())
        .handleError((e) {
          debugPrint('[DfcQoeService] streamOpenAlerts error: $e');
          return <QoeAlert>[];
        });
  }

  Future<void> acknowledgeAlert(String alertId) async {
    try {
      await _db.collection(_alertsCol).doc(alertId).set({
        'status': QoeAlertStatus.acknowledged.name,
      }, SetOptions(merge: true));
      notifyListeners();
    } catch (e) {
      debugPrint('[DfcQoeService] acknowledgeAlert error: $e');
    }
  }

  // ── Auto-Remediation ──────────────────────────────────────────────────

  Future<void> _runRemediations(
    _SessionAccumulator acc,
    SessionHealth health,
    QoeMetric latest,
  ) async {
    // 1. Critical rebuffer → trigger CDN switch event
    if (latest.type == QoeMetricType.rebufferRatio &&
        latest.value > _Thresholds.rebufferCritical) {
      await _createAlert(
        eventId: acc.eventId,
        sessionId: acc.sessionId,
        severity: QoeAlertSeverity.critical,
        message:
            'Rebuffer ratio ${(latest.value * 100).toStringAsFixed(1)}% exceeded critical threshold — CDN switch recommended',
        trigger: 'rebuffer_threshold',
      );
      // Log the remediation as a metric
      await _db
          .collection(_sessionsCol)
          .doc(acc.sessionId)
          .collection('metrics')
          .add(
            QoeMetric(
              sessionId: acc.sessionId,
              type: QoeMetricType.cdnSwitch,
              value: 1,
              detail: 'auto_remediation',
              timestamp: DateTime.now().toUtc(),
            ).toFirestore(),
          );
    }
    // 2. High rebuffer → alert
    else if (latest.type == QoeMetricType.rebufferRatio &&
        latest.value > _Thresholds.rebufferHigh) {
      await _createAlert(
        eventId: acc.eventId,
        sessionId: acc.sessionId,
        severity: QoeAlertSeverity.high,
        message:
            'Rebuffer ratio ${(latest.value * 100).toStringAsFixed(1)}% — stream quality degraded',
        trigger: 'rebuffer_high',
      );
    }

    // 3. Slow startup → alert
    if (latest.type == QoeMetricType.startupTime &&
        latest.value > _Thresholds.startupSlowMs) {
      await _createAlert(
        eventId: acc.eventId,
        sessionId: acc.sessionId,
        severity: QoeAlertSeverity.medium,
        message:
            'Slow startup: ${latest.value.toStringAsFixed(0)}ms exceeds ${_Thresholds.startupSlowMs.toStringAsFixed(0)}ms threshold',
        trigger: 'slow_startup',
      );
    }

    // 4. High error rate → flag ops
    if (health.errorCount >= _Thresholds.errorRateHigh) {
      await _createAlert(
        eventId: acc.eventId,
        sessionId: acc.sessionId,
        severity: QoeAlertSeverity.high,
        message:
            '${health.errorCount} playback errors in session — ops review required',
        trigger: 'error_rate',
      );
    }
  }

  Future<void> _createAlert({
    String? eventId,
    String? sessionId,
    required QoeAlertSeverity severity,
    required String message,
    required String trigger,
  }) async {
    try {
      final alert = QoeAlert(
        alertId: '',
        eventId: eventId,
        sessionId: sessionId,
        severity: severity,
        status: QoeAlertStatus.open,
        message: message,
        trigger: trigger,
        createdAt: DateTime.now().toUtc(),
      );
      await _db.collection(_alertsCol).add(alert.toFirestore());
    } catch (e) {
      debugPrint('[DfcQoeService] _createAlert error: $e');
    }
  }

  // ── Demo Data ─────────────────────────────────────────────────────────

  List<SessionHealth> get demoSessions => [
    SessionHealth(
      sessionId: 'demo_session_001',
      eventId: 'demo_event_001',
      userId: 'user_au_001',
      healthScore: 94.0,
      metricCount: 42,
      avgStartupMs: 1200,
      avgRebufferRatio: 0.01,
      errorCount: 0,
      cdnSwitchCount: 0,
      lastUpdated: DateTime.now().toUtc(),
    ),
    SessionHealth(
      sessionId: 'demo_session_002',
      eventId: 'demo_event_001',
      userId: 'user_us_002',
      healthScore: 61.0,
      metricCount: 28,
      avgStartupMs: 3800,
      avgRebufferRatio: 0.09,
      errorCount: 2,
      cdnSwitchCount: 1,
      lastUpdated: DateTime.now().toUtc(),
    ),
    SessionHealth(
      sessionId: 'demo_session_003',
      eventId: 'demo_event_002',
      userId: 'user_gb_003',
      healthScore: 38.0,
      metricCount: 15,
      avgStartupMs: 6500,
      avgRebufferRatio: 0.18,
      errorCount: 6,
      cdnSwitchCount: 2,
      lastUpdated: DateTime.now().toUtc(),
    ),
  ];

  List<QoeAlert> get demoAlerts => [
    QoeAlert(
      alertId: 'alert_001',
      eventId: 'demo_event_002',
      sessionId: 'demo_session_003',
      severity: QoeAlertSeverity.critical,
      status: QoeAlertStatus.open,
      message:
          'Rebuffer ratio 18% exceeded critical threshold — CDN switch recommended',
      trigger: 'rebuffer_threshold',
      createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 3)),
    ),
    QoeAlert(
      alertId: 'alert_002',
      eventId: 'demo_event_001',
      sessionId: 'demo_session_002',
      severity: QoeAlertSeverity.medium,
      status: QoeAlertStatus.acknowledged,
      message: 'Slow startup: 3800ms exceeds 3000ms threshold',
      trigger: 'slow_startup',
      createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 12)),
    ),
  ];
}

// ── Internal accumulator ───────────────────────────────────────────────────

class _SessionAccumulator {
  final String sessionId;
  final String? eventId;
  final String? userId;

  final List<double> _startupTimes = [];
  final List<double> _rebufferRatios = [];
  int _errorCount = 0;
  int _cdnSwitchCount = 0;
  int _metricCount = 0;

  _SessionAccumulator({required this.sessionId, this.eventId, this.userId});

  void ingest(QoeMetric metric) {
    _metricCount++;
    switch (metric.type) {
      case QoeMetricType.startupTime:
        _startupTimes.add(metric.value);
        break;
      case QoeMetricType.rebufferRatio:
        _rebufferRatios.add(metric.value);
        break;
      case QoeMetricType.playbackError:
        _errorCount++;
        break;
      case QoeMetricType.cdnSwitch:
        _cdnSwitchCount++;
        break;
      default:
        break;
    }
  }

  SessionHealth computeHealth() {
    final avgStartup = _startupTimes.isEmpty
        ? 0.0
        : _startupTimes.reduce((a, b) => a + b) / _startupTimes.length;
    final avgRebuffer = _rebufferRatios.isEmpty
        ? 0.0
        : _rebufferRatios.reduce((a, b) => a + b) / _rebufferRatios.length;

    // Score: start at 100, deduct for bad signals
    double score = 100.0;
    if (avgStartup > 5000) {
      score -= 20;
    } else if (avgStartup > 3000)
      score -= 10;
    if (avgRebuffer > 0.15) {
      score -= 30;
    } else if (avgRebuffer > 0.08)
      score -= 15;
    else if (avgRebuffer > 0.03)
      score -= 5;
    score -= _errorCount * 5.0;
    score -= _cdnSwitchCount * 3.0;
    score = score.clamp(0.0, 100.0);

    return SessionHealth(
      sessionId: sessionId,
      eventId: eventId,
      userId: userId,
      healthScore: score,
      metricCount: _metricCount,
      avgStartupMs: avgStartup,
      avgRebufferRatio: avgRebuffer,
      errorCount: _errorCount,
      cdnSwitchCount: _cdnSwitchCount,
      lastUpdated: DateTime.now().toUtc(),
    );
  }
}
