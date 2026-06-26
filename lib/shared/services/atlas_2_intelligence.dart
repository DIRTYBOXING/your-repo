// ═══════════════════════════════════════════════════════════════════════════
// ATLAS 2.0 — CENTRAL INTELLIGENCE LAYER
// ═══════════════════════════════════════════════════════════════════════════
// The god-brain of DFC. Reads all engine outputs, correlates signals across
// domains, predicts outcomes, and optimizes the entire platform in real-time.
//
// ATLAS = Advanced Tactical Learning & Analysis System
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dfc_event_bus.dart';

/// ATLAS operational modes
enum AtlasMode {
  observer, // Read-only, gather signals
  advisor, // Provide recommendations
  autopilot, // Auto-execute optimizations
  emergency, // Crisis management mode
}

/// Signal domains ATLAS monitors
enum SignalDomain {
  combat, // Fight analysis, predictions, matchmaking
  health, // Wellness, recovery, injury risk
  training, // Load, periodization, readiness
  content, // Feed, posts, engagement
  social, // Graph, messaging, relationships
  commerce, // Payments, subscriptions, marketplace
  streaming, // Live events, PPV, viewership
  safety, // Moderation, trust, compliance
}

/// Insight severity levels
enum InsightSeverity { info, suggestion, warning, critical, emergency }

/// ═══════════════════════════════════════════════════════════════════════════
/// ATLAS INSIGHT — Actionable intelligence from the system
/// ═══════════════════════════════════════════════════════════════════════════
class AtlasInsight {
  final String id;
  final SignalDomain domain;
  final InsightSeverity severity;
  final String title;
  final String summary;
  final Map<String, dynamic> data;
  final List<AtlasAction> suggestedActions;
  final DateTime timestamp;
  final double confidence; // 0.0 - 1.0
  final String? targetUserId;
  final String? correlationId;

  AtlasInsight({
    String? id,
    required this.domain,
    required this.severity,
    required this.title,
    required this.summary,
    this.data = const {},
    this.suggestedActions = const [],
    this.confidence = 0.8,
    this.targetUserId,
    this.correlationId,
  }) : id = id ?? 'insight_${DateTime.now().millisecondsSinceEpoch}',
       timestamp = DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'domain': domain.name,
    'severity': severity.name,
    'title': title,
    'summary': summary,
    'data': data,
    'suggestedActions': suggestedActions.map((a) => a.toMap()).toList(),
    'timestamp': Timestamp.fromDate(timestamp),
    'confidence': confidence,
    'targetUserId': targetUserId,
    'correlationId': correlationId,
  };
}

/// Suggested action from ATLAS
class AtlasAction {
  final String id;
  final String label;
  final String targetEngine;
  final String eventType;
  final Map<String, dynamic> payload;
  final bool autoExecute;

  AtlasAction({
    required this.id,
    required this.label,
    required this.targetEngine,
    required this.eventType,
    this.payload = const {},
    this.autoExecute = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'targetEngine': targetEngine,
    'eventType': eventType,
    'payload': payload,
    'autoExecute': autoExecute,
  };
}

/// ═══════════════════════════════════════════════════════════════════════════
/// ATLAS PREDICTION — Forecasts from pattern analysis
/// ═══════════════════════════════════════════════════════════════════════════
class AtlasPrediction {
  final String id;
  final SignalDomain domain;
  final String predictionType;
  final String description;
  final double probability; // 0.0 - 1.0
  final DateTime predictedTime;
  final Map<String, dynamic> factors;
  final DateTime timestamp;

  AtlasPrediction({
    String? id,
    required this.domain,
    required this.predictionType,
    required this.description,
    required this.probability,
    required this.predictedTime,
    this.factors = const {},
  }) : id = id ?? 'pred_${DateTime.now().millisecondsSinceEpoch}',
       timestamp = DateTime.now();
}

/// ═══════════════════════════════════════════════════════════════════════════
/// ATLAS 2.0 — CENTRAL INTELLIGENCE
/// ═══════════════════════════════════════════════════════════════════════════
class Atlas2Intelligence with EventBusEngine {
  static final Atlas2Intelligence _instance = Atlas2Intelligence._internal();
  factory Atlas2Intelligence() => _instance;
  Atlas2Intelligence._internal();

  @override
  String get engineId => 'atlas_2';
  @override
  EventCategory get engineCategory => EventCategory.system;

  final _db = FirebaseFirestore.instance;
  final _bus = DFCEventBus();

  // State
  AtlasMode _mode = AtlasMode.observer;
  bool _running = false;
  Timer? _analysisTimer;
  Timer? _healthTimer;

  // Signal buffers (rolling windows)
  final Map<SignalDomain, List<DFCEvent>> _signalBuffers = {};
  static const _bufferSize = 500;

  // Insights & predictions
  final List<AtlasInsight> _insights = [];
  final List<AtlasPrediction> _predictions = [];
  static const _maxInsights = 200;

  // Platform health scores
  final Map<String, double> _engineHealthScores = {};
  final Map<SignalDomain, double> _domainHealthScores = {};
  double _overallHealthScore = 1.0;

  // Pattern memory
  final Map<String, int> _patternCounts = {};
  final Map<String, DateTime> _patternLastSeen = {};

  // Metrics
  int _eventsProcessed = 0;
  int _insightsGenerated = 0;
  int _predictionsGenerated = 0;
  int _actionsExecuted = 0;

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Boot ATLAS
  Future<void> boot({AtlasMode mode = AtlasMode.observer}) async {
    if (_running) return;
    _running = true;
    _mode = mode;

    // Initialize signal buffers
    for (final domain in SignalDomain.values) {
      _signalBuffers[domain] = [];
    }

    // Subscribe to all event categories
    for (final category in EventCategory.values) {
      listenToEvents(category: category, onEvent: _processEvent);
    }

    // Start analysis loop
    _analysisTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _runAnalysisCycle(),
    );

    // Start health monitoring
    _healthTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _runHealthCheck(),
    );

    await emitEvent('atlas.booted', {
      'mode': mode.name,
      'timestamp': DateTime.now().toIso8601String(),
    }, priority: EventPriority.high);

    debugPrint('[ATLAS 2.0] Booted in ${mode.name} mode');
  }

  /// Shutdown ATLAS
  Future<void> shutdown() async {
    _running = false;
    _analysisTimer?.cancel();
    _healthTimer?.cancel();
    disposeEngineSubscriptions();

    await emitEvent('atlas.shutdown', {
      'eventsProcessed': _eventsProcessed,
      'insightsGenerated': _insightsGenerated,
    });

    debugPrint('[ATLAS 2.0] Shutdown — $_eventsProcessed events processed');
  }

  /// Change operational mode
  void setMode(AtlasMode mode) {
    _mode = mode;
    emitEvent('atlas.mode.changed', {'mode': mode.name});
    debugPrint('[ATLAS 2.0] Mode changed to ${mode.name}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EVENT PROCESSING
  // ═══════════════════════════════════════════════════════════════════════════

  void _processEvent(DFCEvent event) {
    _eventsProcessed++;

    // Route to appropriate signal buffer
    final domain = _categoryToDomain(event.category);
    final buffer = _signalBuffers[domain];
    if (buffer != null) {
      buffer.add(event);
      if (buffer.length > _bufferSize) {
        buffer.removeAt(0);
      }
    }

    // Track patterns
    final pattern = '${event.source}:${event.type}';
    _patternCounts[pattern] = (_patternCounts[pattern] ?? 0) + 1;
    _patternLastSeen[pattern] = DateTime.now();

    // Update engine health
    if (event.type.contains('error') || event.type.contains('failed')) {
      _engineHealthScores[event.source] =
          ((_engineHealthScores[event.source] ?? 1.0) * 0.9).clamp(0.0, 1.0);
    } else if (event.type.contains('success') ||
        event.type.contains('completed')) {
      _engineHealthScores[event.source] = math.min(
        1.0,
        (_engineHealthScores[event.source] ?? 0.8) + 0.02,
      );
    }

    // Check for immediate alerts
    _checkImmediateAlerts(event);
  }

  SignalDomain _categoryToDomain(EventCategory category) {
    switch (category) {
      case EventCategory.combat:
        return SignalDomain.combat;
      case EventCategory.health:
        return SignalDomain.health;
      case EventCategory.training:
        return SignalDomain.training;
      case EventCategory.content:
        return SignalDomain.content;
      case EventCategory.social:
        return SignalDomain.social;
      case EventCategory.payment:
        return SignalDomain.commerce;
      case EventCategory.streaming:
        return SignalDomain.streaming;
      case EventCategory.moderation:
        return SignalDomain.safety;
      default:
        return SignalDomain.content;
    }
  }

  void _checkImmediateAlerts(DFCEvent event) {
    // Critical payment failures
    if (event.type == DFCEvents.paymentFailed) {
      _generateInsight(
        domain: SignalDomain.commerce,
        severity: InsightSeverity.warning,
        title: 'Payment Failed',
        summary: 'A payment has failed and may require attention.',
        data: event.payload,
        targetUserId: event.payload['userId'],
      );
    }

    // Moderation safety alerts
    if (event.type == DFCEvents.safetyAlert) {
      _generateInsight(
        domain: SignalDomain.safety,
        severity: InsightSeverity.critical,
        title: 'Safety Alert Triggered',
        summary: 'Content or user behavior requires immediate review.',
        data: event.payload,
      );
    }

    // Injury reports
    if (event.type == DFCEvents.injuryReported) {
      _generateInsight(
        domain: SignalDomain.health,
        severity: InsightSeverity.critical,
        title: 'Injury Reported',
        summary:
            'A fighter has reported an injury. Training load should be adjusted.',
        data: event.payload,
        targetUserId: event.payload['fighterId'],
        suggestedActions: [
          AtlasAction(
            id: 'action_pause_training',
            label: 'Pause Training Plan',
            targetEngine: 'sports_science_engine',
            eventType: 'training.plan.pause',
            payload: {'fighterId': event.payload['fighterId']},
          ),
        ],
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ANALYSIS CYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  void _runAnalysisCycle() {
    if (!_running) return;

    // Cross-domain correlation
    _analyzeHealthTrainingCorrelation();
    _analyzeSocialEngagement();
    _analyzeContentPerformance();
    _analyzeCombatReadiness();
    _analyzeCommercePatterns();

    // Predictive analysis
    _generatePredictions();

    // Auto-execute if in autopilot mode
    if (_mode == AtlasMode.autopilot) {
      _executeAutoActions();
    }
  }

  void _analyzeHealthTrainingCorrelation() {
    final healthSignals = _signalBuffers[SignalDomain.health] ?? [];
    final trainingSignals = _signalBuffers[SignalDomain.training] ?? [];

    if (healthSignals.isEmpty || trainingSignals.isEmpty) return;

    // Look for overtraining patterns
    final recentHealth = healthSignals
        .where((e) => DateTime.now().difference(e.timestamp).inHours < 24)
        .toList();

    final lowReadinessCount = recentHealth
        .where((e) => (e.payload['readinessScore'] ?? 100) < 50)
        .length;

    final highLoadCount = trainingSignals
        .where(
          (e) =>
              DateTime.now().difference(e.timestamp).inHours < 24 &&
              (e.payload['loadScore'] ?? 0) > 80,
        )
        .length;

    if (lowReadinessCount > 2 && highLoadCount > 3) {
      _generateInsight(
        domain: SignalDomain.training,
        severity: InsightSeverity.warning,
        title: 'Overtraining Risk Detected',
        summary:
            'High training load combined with low recovery scores. Consider reducing intensity.',
        data: {
          'lowReadinessCount': lowReadinessCount,
          'highLoadCount': highLoadCount,
        },
        suggestedActions: [
          AtlasAction(
            id: 'action_reduce_load',
            label: 'Reduce Training Load',
            targetEngine: 'sports_science_engine',
            eventType: 'training.load.reduce',
            payload: {'reduceFactor': 0.7},
          ),
        ],
      );
    }
  }

  void _analyzeSocialEngagement() {
    final socialSignals = _signalBuffers[SignalDomain.social] ?? [];
    // ignore: unused_local_variable
    final contentSignals = _signalBuffers[SignalDomain.content] ?? [];

    if (socialSignals.length < 10) return;

    // Detect engagement spikes
    final recentEngagement = socialSignals
        .where((e) => DateTime.now().difference(e.timestamp).inMinutes < 30)
        .length;

    if (recentEngagement > 50) {
      _generateInsight(
        domain: SignalDomain.social,
        severity: InsightSeverity.info,
        title: 'Engagement Spike Detected',
        summary: 'Social activity is above normal. Good time to post content.',
        data: {'recentEngagement': recentEngagement},
        confidence: 0.85,
      );
    }
  }

  void _analyzeContentPerformance() {
    final contentSignals = _signalBuffers[SignalDomain.content] ?? [];

    final flaggedCount = contentSignals
        .where((e) => e.type == DFCEvents.contentFlagged)
        .length;

    if (flaggedCount > 5) {
      _generateInsight(
        domain: SignalDomain.safety,
        severity: InsightSeverity.warning,
        title: 'High Content Flag Rate',
        summary:
            'Multiple content items have been flagged. Review moderation settings.',
        data: {'flaggedCount': flaggedCount},
      );
    }
  }

  void _analyzeCombatReadiness() {
    final combatSignals = _signalBuffers[SignalDomain.combat] ?? [];
    final healthSignals = _signalBuffers[SignalDomain.health] ?? [];

    // Look for upcoming fights with low readiness
    final upcomingFights = combatSignals
        .where((e) => e.type == DFCEvents.fightScheduled)
        .toList();

    for (final fight in upcomingFights) {
      final fighterId = fight.payload['fighterId'];
      final fighterHealth = healthSignals
          .where((e) => e.payload['fighterId'] == fighterId)
          .lastOrNull;

      if (fighterHealth != null) {
        final readiness = fighterHealth.payload['readinessScore'] ?? 100;
        if (readiness < 60) {
          _generateInsight(
            domain: SignalDomain.combat,
            severity: InsightSeverity.warning,
            title: 'Low Readiness Before Fight',
            summary: 'Fighter has low readiness score with upcoming bout.',
            data: {
              'fighterId': fighterId,
              'readiness': readiness,
              'fightDate': fight.payload['date'],
            },
            targetUserId: fighterId,
          );
        }
      }
    }
  }

  void _analyzeCommercePatterns() {
    final commerceSignals = _signalBuffers[SignalDomain.commerce] ?? [];

    final failedPayments = commerceSignals
        .where(
          (e) =>
              e.type == DFCEvents.paymentFailed &&
              DateTime.now().difference(e.timestamp).inHours < 24,
        )
        .length;

    final successfulPayments = commerceSignals
        .where(
          (e) =>
              e.type == DFCEvents.paymentSucceeded &&
              DateTime.now().difference(e.timestamp).inHours < 24,
        )
        .length;

    final totalPayments = failedPayments + successfulPayments;
    if (totalPayments > 10) {
      final failureRate = failedPayments / totalPayments;
      if (failureRate > 0.1) {
        _generateInsight(
          domain: SignalDomain.commerce,
          severity: InsightSeverity.warning,
          title: 'Elevated Payment Failure Rate',
          summary:
              'Payment failure rate is ${(failureRate * 100).toStringAsFixed(1)}%. Check Stripe configuration.',
          data: {
            'failedPayments': failedPayments,
            'successfulPayments': successfulPayments,
            'failureRate': failureRate,
          },
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PREDICTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  void _generatePredictions() {
    // Predict engagement peaks
    final socialActivity = _signalBuffers[SignalDomain.social]?.length ?? 0;
    final contentActivity = _signalBuffers[SignalDomain.content]?.length ?? 0;

    if (socialActivity > 30 && contentActivity > 20) {
      _predictions.add(
        AtlasPrediction(
          domain: SignalDomain.social,
          predictionType: 'engagement_peak',
          description: 'High probability of engagement spike in next 2 hours',
          probability: 0.72,
          predictedTime: DateTime.now().add(const Duration(hours: 2)),
          factors: {
            'socialActivity': socialActivity,
            'contentActivity': contentActivity,
          },
        ),
      );
      _predictionsGenerated++;
    }

    // Trim old predictions
    _predictions.removeWhere(
      (p) => DateTime.now().difference(p.timestamp).inHours > 24,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INSIGHTS
  // ═══════════════════════════════════════════════════════════════════════════

  void _generateInsight({
    required SignalDomain domain,
    required InsightSeverity severity,
    required String title,
    required String summary,
    Map<String, dynamic> data = const {},
    List<AtlasAction> suggestedActions = const [],
    double confidence = 0.8,
    String? targetUserId,
    String? correlationId,
  }) {
    final insight = AtlasInsight(
      domain: domain,
      severity: severity,
      title: title,
      summary: summary,
      data: data,
      suggestedActions: suggestedActions,
      confidence: confidence,
      targetUserId: targetUserId,
      correlationId: correlationId,
    );

    _insights.add(insight);
    _insightsGenerated++;

    // Trim old insights
    if (_insights.length > _maxInsights) {
      _insights.removeAt(0);
    }

    // Emit insight event
    emitEvent(
      'atlas.insight.generated',
      insight.toMap(),
      priority: severity == InsightSeverity.critical
          ? EventPriority.high
          : EventPriority.normal,
    );

    // Persist critical insights
    if (severity == InsightSeverity.critical ||
        severity == InsightSeverity.emergency) {
      _db.collection('atlas_insights').doc(insight.id).set(insight.toMap());
    }

    debugPrint('[ATLAS 2.0] Insight: $title (${severity.name})');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTO ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  void _executeAutoActions() {
    for (final insight in _insights) {
      for (final action in insight.suggestedActions) {
        if (action.autoExecute) {
          _bus.emit(
            'atlas_2',
            action.eventType,
            action.payload,
            category: _domainToCategory(insight.domain),
          );
          _actionsExecuted++;
          debugPrint('[ATLAS 2.0] Auto-executed: ${action.label}');
        }
      }
    }
  }

  EventCategory _domainToCategory(SignalDomain domain) {
    switch (domain) {
      case SignalDomain.combat:
        return EventCategory.combat;
      case SignalDomain.health:
        return EventCategory.health;
      case SignalDomain.training:
        return EventCategory.training;
      case SignalDomain.content:
        return EventCategory.content;
      case SignalDomain.social:
        return EventCategory.social;
      case SignalDomain.commerce:
        return EventCategory.payment;
      case SignalDomain.streaming:
        return EventCategory.streaming;
      case SignalDomain.safety:
        return EventCategory.moderation;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEALTH CHECK
  // ═══════════════════════════════════════════════════════════════════════════

  void _runHealthCheck() {
    // Calculate domain health scores
    for (final domain in SignalDomain.values) {
      final buffer = _signalBuffers[domain] ?? [];
      final errorCount = buffer
          .where((e) => e.type.contains('error') || e.type.contains('failed'))
          .length;
      final total = buffer.length;

      _domainHealthScores[domain] = total > 0
          ? ((total - errorCount) / total).clamp(0.0, 1.0)
          : 1.0;
    }

    // Calculate overall health
    final engineScores = _engineHealthScores.values;
    final domainScores = _domainHealthScores.values;

    _overallHealthScore = engineScores.isNotEmpty || domainScores.isNotEmpty
        ? ([...engineScores, ...domainScores].reduce((a, b) => a + b) /
                  (engineScores.length + domainScores.length))
              .clamp(0.0, 1.0)
        : 1.0;

    // Alert if health is low
    if (_overallHealthScore < 0.7) {
      _generateInsight(
        domain: SignalDomain.content, // System
        severity: InsightSeverity.warning,
        title: 'Platform Health Degraded',
        summary:
            'Overall health score is ${(_overallHealthScore * 100).toStringAsFixed(1)}%.',
        data: {
          'overallHealth': _overallHealthScore,
          'engineScores': _engineHealthScores,
          'domainScores': _domainHealthScores.map(
            (k, v) => MapEntry(k.name, v),
          ),
        },
      );
    }

    emitEvent('atlas.health.checked', {
      'overallHealth': _overallHealthScore,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════════

  AtlasMode get mode => _mode;
  bool get isRunning => _running;
  double get healthScore => _overallHealthScore;
  List<AtlasInsight> get recentInsights => List.unmodifiable(_insights);
  List<AtlasPrediction> get predictions => List.unmodifiable(_predictions);

  /// Get insights for a specific user
  List<AtlasInsight> getInsightsForUser(String userId) =>
      _insights.where((i) => i.targetUserId == userId).toList();

  /// Get insights by severity
  List<AtlasInsight> getInsightsBySeverity(InsightSeverity severity) =>
      _insights.where((i) => i.severity == severity).toList();

  /// Get insights by domain
  List<AtlasInsight> getInsightsByDomain(SignalDomain domain) =>
      _insights.where((i) => i.domain == domain).toList();

  /// Execute a suggested action
  Future<void> executeAction(AtlasAction action) async {
    await _bus.emit('atlas_2', action.eventType, action.payload);
    _actionsExecuted++;
  }

  /// Get full metrics
  Map<String, dynamic> getMetrics() => {
    'mode': _mode.name,
    'running': _running,
    'eventsProcessed': _eventsProcessed,
    'insightsGenerated': _insightsGenerated,
    'predictionsGenerated': _predictionsGenerated,
    'actionsExecuted': _actionsExecuted,
    'overallHealth': _overallHealthScore,
    'engineHealth': _engineHealthScores,
    'domainHealth': _domainHealthScores.map((k, v) => MapEntry(k.name, v)),
    'signalBufferSizes': _signalBuffers.map(
      (k, v) => MapEntry(k.name, v.length),
    ),
    'patternCount': _patternCounts.length,
  };

  /// Get top patterns
  List<MapEntry<String, int>> getTopPatterns({int limit = 20}) {
    final sorted = _patternCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }
}
