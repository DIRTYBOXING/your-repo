// ═══════════════════════════════════════════════════════════════════════════
// SWARM 3.0 — AUTONOMOUS HIVE MIND UPGRADE
// ═══════════════════════════════════════════════════════════════════════════
// Next-generation swarm orchestration with:
//   • Self-healing agent recovery
//   • Persistent memory & learning
//   • Autonomy modes (manual/guided/autonomous)
//   • ATLAS 2.0 integration for coordinated intelligence
//   • Event Bus communication backbone
//
// Wraps and enhances SamuraiSwarmCoordinator.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dfc_event_bus.dart';
import 'atlas_2_intelligence.dart';
import 'samurai_swarm_coordinator.dart';

/// Swarm autonomy levels
enum SwarmAutonomy {
  manual, // Human triggers all actions
  guided, // Swarm suggests, human approves
  supervised, // Swarm acts, human can override
  autonomous, // Full auto-pilot
}

/// Agent health state for self-healing
enum AgentHealth { healthy, degraded, failing, dead }

/// Learning signal types
enum LearningSignal { success, failure, timeout, userFeedback }

/// ═══════════════════════════════════════════════════════════════════════════
/// AGENT MEMORY — What each agent remembers
/// ═══════════════════════════════════════════════════════════════════════════
class AgentMemory {
  final String agentId;
  final List<String> recentActions;
  final Map<String, int> actionSuccessCounts;
  final Map<String, int> actionFailureCounts;
  final Map<String, double> learnedWeights;
  final DateTime lastUpdated;

  AgentMemory({
    required this.agentId,
    this.recentActions = const [],
    this.actionSuccessCounts = const {},
    this.actionFailureCounts = const {},
    this.learnedWeights = const {},
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  double getSuccessRate(String action) {
    final success = actionSuccessCounts[action] ?? 0;
    final failure = actionFailureCounts[action] ?? 0;
    final total = success + failure;
    return total > 0 ? success / total : 0.5;
  }

  AgentMemory recordAction(String action, LearningSignal signal) {
    final newRecentActions = [...recentActions, action];
    if (newRecentActions.length > 100) newRecentActions.removeAt(0);

    final newSuccess = Map<String, int>.from(actionSuccessCounts);
    final newFailure = Map<String, int>.from(actionFailureCounts);

    if (signal == LearningSignal.success) {
      newSuccess[action] = (newSuccess[action] ?? 0) + 1;
    } else if (signal == LearningSignal.failure ||
        signal == LearningSignal.timeout) {
      newFailure[action] = (newFailure[action] ?? 0) + 1;
    }

    return AgentMemory(
      agentId: agentId,
      recentActions: newRecentActions,
      actionSuccessCounts: newSuccess,
      actionFailureCounts: newFailure,
      learnedWeights: learnedWeights,
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'agentId': agentId,
    'recentActions': recentActions,
    'actionSuccessCounts': actionSuccessCounts,
    'actionFailureCounts': actionFailureCounts,
    'learnedWeights': learnedWeights,
    'lastUpdated': Timestamp.fromDate(lastUpdated),
  };

  factory AgentMemory.fromMap(Map<String, dynamic> map) => AgentMemory(
    agentId: map['agentId'] ?? '',
    recentActions: List<String>.from(map['recentActions'] ?? []),
    actionSuccessCounts: Map<String, int>.from(
      map['actionSuccessCounts'] ?? {},
    ),
    actionFailureCounts: Map<String, int>.from(
      map['actionFailureCounts'] ?? {},
    ),
    learnedWeights: Map<String, double>.from(map['learnedWeights'] ?? {}),
    lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

/// ═══════════════════════════════════════════════════════════════════════════
/// SELF-HEALING RECORD — Tracks recovery attempts
/// ═══════════════════════════════════════════════════════════════════════════
class HealingRecord {
  final String agentId;
  final DateTime detectedAt;
  final AgentHealth priorHealth;
  final String healingAction;
  final bool successful;
  final DateTime? resolvedAt;

  HealingRecord({
    required this.agentId,
    required this.detectedAt,
    required this.priorHealth,
    required this.healingAction,
    this.successful = false,
    this.resolvedAt,
  });

  Map<String, dynamic> toMap() => {
    'agentId': agentId,
    'detectedAt': Timestamp.fromDate(detectedAt),
    'priorHealth': priorHealth.name,
    'healingAction': healingAction,
    'successful': successful,
    'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
  };
}

/// ═══════════════════════════════════════════════════════════════════════════
/// SWARM 3.0 — THE NEXT EVOLUTION
/// ═══════════════════════════════════════════════════════════════════════════
class Swarm3 with EventBusEngine {
  static final Swarm3 _instance = Swarm3._internal();
  factory Swarm3() => _instance;
  Swarm3._internal();

  @override
  String get engineId => 'swarm_3';
  @override
  EventCategory get engineCategory => EventCategory.swarm;

  final _db = FirebaseFirestore.instance;
  final _bus = DFCEventBus();
  // ignore: unused_field
  final _atlas = Atlas2Intelligence();
  // ignore: unused_field
  late SamuraiSwarmCoordinator _coordinator;

  // State
  bool _running = false;
  SwarmAutonomy _autonomy = SwarmAutonomy.guided;
  Timer? _healthTimer;
  Timer? _learningTimer;
  Timer? _healingTimer;

  // Agent health tracking
  final Map<String, AgentHealth> _agentHealth = {};
  final Map<String, DateTime> _lastHeartbeat = {};
  final Map<String, int> _consecutiveFailures = {};
  static const _failureThreshold = 3;
  static const _heartbeatTimeout = Duration(minutes: 2);

  // Memory system
  final Map<String, AgentMemory> _agentMemory = {};
  bool _memoryLoaded = false;

  // Self-healing
  final List<HealingRecord> _healingHistory = [];
  final Map<String, int> _healingAttempts = {};
  static const _maxHealingAttempts = 5;

  // Metrics
  int _totalRecoveries = 0;
  int _learningCycles = 0;
  int _autonomousActions = 0;

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Boot Swarm 3.0
  Future<void> boot({
    SwarmAutonomy autonomy = SwarmAutonomy.guided,
    required SamuraiSwarmCoordinator coordinator,
  }) async {
    if (_running) return;
    _running = true;
    _autonomy = autonomy;
    _coordinator = coordinator;

    // Load persistent memory
    await _loadMemory();

    // Subscribe to swarm events
    listenToEvents(category: EventCategory.swarm, onEvent: _handleSwarmEvent);

    // Subscribe to ATLAS insights
    listenToEvents(category: EventCategory.system, onEvent: _handleSystemEvent);

    // Initialize agent health from current swarm state
    _initializeAgentHealth();

    // Start health monitoring
    _healthTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkAgentHealth(),
    );

    // Start learning cycle
    _learningTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _runLearningCycle(),
    );

    // Start self-healing loop
    _healingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _runHealingCycle(),
    );

    await emitEvent('swarm.3.booted', {
      'autonomy': autonomy.name,
      'agentCount': _agentHealth.length,
      'memoryLoaded': _memoryLoaded,
    }, priority: EventPriority.high);

    debugPrint(
      '[SWARM 3.0] Booted — ${_agentHealth.length} agents, $autonomy autonomy',
    );
  }

  /// Shutdown Swarm 3.0
  Future<void> shutdown() async {
    _running = false;
    _healthTimer?.cancel();
    _learningTimer?.cancel();
    _healingTimer?.cancel();
    disposeEngineSubscriptions();

    // Persist memory
    await _saveMemory();

    await emitEvent('swarm.3.shutdown', {
      'totalRecoveries': _totalRecoveries,
      'learningCycles': _learningCycles,
    });

    debugPrint('[SWARM 3.0] Shutdown — $_totalRecoveries recoveries made');
  }

  void _initializeAgentHealth() {
    // Initialize all known agents as healthy
    final knownAgents = [
      'dfc_ai_powerhouse',
      'samurai_core_engine',
      'samurai_orchestrator',
      'content_transformer',
      'social_engine',
      'content_rotation',
      'combat_intelligence',
      'health_intelligence',
      'sponsor_feed',
      'metaverse_ads',
      'dfc_nexus',
      'quantum_optimizer',
      'sports_science',
      // Add more agent IDs as needed
    ];

    for (final agentId in knownAgents) {
      _agentHealth[agentId] = AgentHealth.healthy;
      _lastHeartbeat[agentId] = DateTime.now();
      _consecutiveFailures[agentId] = 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EVENT HANDLING
  // ═══════════════════════════════════════════════════════════════════════════

  void _handleSwarmEvent(DFCEvent event) {
    final source = event.source;

    // Record heartbeat
    _lastHeartbeat[source] = DateTime.now();

    // Track success/failure
    if (event.type.contains('completed') || event.type.contains('success')) {
      _consecutiveFailures[source] = 0;
      _recordLearning(source, event.type, LearningSignal.success);

      if (_agentHealth[source] == AgentHealth.degraded) {
        _agentHealth[source] = AgentHealth.healthy;
        debugPrint('[SWARM 3.0] Agent $source recovered to healthy');
      }
    } else if (event.type.contains('error') || event.type.contains('failed')) {
      _consecutiveFailures[source] = (_consecutiveFailures[source] ?? 0) + 1;
      _recordLearning(source, event.type, LearningSignal.failure);

      if (_consecutiveFailures[source]! >= _failureThreshold) {
        _markAgentDegraded(source);
      }
    }
  }

  void _handleSystemEvent(DFCEvent event) {
    // Listen for ATLAS insights
    if (event.type == 'atlas.insight.generated') {
      _processAtlasInsight(event.payload);
    }
  }

  void _processAtlasInsight(Map<String, dynamic> insight) {
    // ignore: unused_local_variable
    final severity = insight['severity'] as String?;
    final actions = insight['suggestedActions'] as List<dynamic>?;

    if (_autonomy == SwarmAutonomy.autonomous && actions != null) {
      // Auto-execute suggested actions
      for (final action in actions) {
        if (action is Map<String, dynamic> && action['autoExecute'] == true) {
          _executeAutonomousAction(
            action['targetEngine'] as String? ?? '',
            action['eventType'] as String? ?? '',
            action['payload'] as Map<String, dynamic>? ?? {},
          );
        }
      }
    }
  }

  Future<void> _executeAutonomousAction(
    String targetEngine,
    String eventType,
    Map<String, dynamic> payload,
  ) async {
    _autonomousActions++;

    await _bus.emit('swarm_3', eventType, {
      ...payload,
      '_autonomousAction': true,
      '_targetEngine': targetEngine,
    });

    debugPrint('[SWARM 3.0] Autonomous action: $eventType -> $targetEngine');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SELF-HEALING
  // ═══════════════════════════════════════════════════════════════════════════

  void _markAgentDegraded(String agentId) {
    final priorHealth = _agentHealth[agentId] ?? AgentHealth.healthy;

    if (priorHealth != AgentHealth.degraded &&
        priorHealth != AgentHealth.failing) {
      _agentHealth[agentId] = AgentHealth.degraded;

      emitEvent('swarm.agent.degraded', {
        'agentId': agentId,
        'failures': _consecutiveFailures[agentId],
      }, priority: EventPriority.high);

      debugPrint('[SWARM 3.0] Agent $agentId marked degraded');
    }
  }

  void _runHealingCycle() {
    if (!_running) return;

    for (final entry in _agentHealth.entries) {
      final agentId = entry.key;
      final health = entry.value;

      if (health == AgentHealth.degraded || health == AgentHealth.failing) {
        _attemptHealing(agentId, health);
      }
    }
  }

  void _attemptHealing(String agentId, AgentHealth priorHealth) {
    final attempts = _healingAttempts[agentId] ?? 0;

    if (attempts >= _maxHealingAttempts) {
      _agentHealth[agentId] = AgentHealth.dead;
      emitEvent('swarm.agent.dead', {'agentId': agentId});
      debugPrint(
        '[SWARM 3.0] Agent $agentId marked dead after $attempts attempts',
      );
      return;
    }

    _healingAttempts[agentId] = attempts + 1;

    // Determine healing strategy
    final strategy = _determineHealingStrategy(agentId, priorHealth, attempts);

    final record = HealingRecord(
      agentId: agentId,
      detectedAt: DateTime.now(),
      priorHealth: priorHealth,
      healingAction: strategy,
    );
    _healingHistory.add(record);

    // Execute healing action
    _executeHealingAction(agentId, strategy);
  }

  String _determineHealingStrategy(
    String agentId,
    AgentHealth health,
    int attempts,
  ) {
    if (attempts == 0) {
      return 'soft_reset';
    } else if (attempts == 1) {
      return 'clear_queue';
    } else if (attempts == 2) {
      return 'reduce_load';
    } else if (attempts == 3) {
      return 'hard_reset';
    } else {
      return 'escalate_human';
    }
  }

  void _executeHealingAction(String agentId, String strategy) {
    switch (strategy) {
      case 'soft_reset':
        _bus.emit('swarm_3', 'agent.restart', {
          'agentId': agentId,
          'mode': 'soft',
        });
        break;

      case 'clear_queue':
        _bus.emit('swarm_3', 'agent.queue.clear', {'agentId': agentId});
        break;

      case 'reduce_load':
        _bus.emit('swarm_3', 'agent.load.reduce', {
          'agentId': agentId,
          'reduceFactor': 0.5,
        });
        break;

      case 'hard_reset':
        _bus.emit('swarm_3', 'agent.restart', {
          'agentId': agentId,
          'mode': 'hard',
        });
        break;

      case 'escalate_human':
        emitEvent('swarm.agent.escalated', {
          'agentId': agentId,
          'message': 'Agent requires manual intervention',
        }, priority: EventPriority.critical);
        break;
    }

    debugPrint(
      '[SWARM 3.0] Healing $agentId with $strategy (attempt ${_healingAttempts[agentId]})',
    );
  }

  void _checkAgentHealth() {
    final now = DateTime.now();

    for (final entry in _lastHeartbeat.entries) {
      final agentId = entry.key;
      final lastBeat = entry.value;
      final elapsed = now.difference(lastBeat);

      if (elapsed > _heartbeatTimeout &&
          _agentHealth[agentId] == AgentHealth.healthy) {
        _markAgentDegraded(agentId);
      }
    }
  }

  /// Confirm an agent recovered (call after healing succeeds)
  void confirmRecovery(String agentId) {
    _agentHealth[agentId] = AgentHealth.healthy;
    _consecutiveFailures[agentId] = 0;
    _healingAttempts[agentId] = 0;
    _lastHeartbeat[agentId] = DateTime.now();
    _totalRecoveries++;

    emitEvent('swarm.agent.recovered', {'agentId': agentId});
    debugPrint('[SWARM 3.0] Agent $agentId confirmed recovered');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEARNING SYSTEM
  // ═══════════════════════════════════════════════════════════════════════════

  void _recordLearning(String agentId, String action, LearningSignal signal) {
    var memory = _agentMemory[agentId] ?? AgentMemory(agentId: agentId);
    memory = memory.recordAction(action, signal);
    _agentMemory[agentId] = memory;
  }

  void _runLearningCycle() {
    if (!_running) return;
    _learningCycles++;

    // Analyze patterns across all agents
    final successPatterns = <String, int>{};
    final failurePatterns = <String, int>{};

    for (final memory in _agentMemory.values) {
      for (final entry in memory.actionSuccessCounts.entries) {
        successPatterns[entry.key] =
            (successPatterns[entry.key] ?? 0) + entry.value;
      }
      for (final entry in memory.actionFailureCounts.entries) {
        failurePatterns[entry.key] =
            (failurePatterns[entry.key] ?? 0) + entry.value;
      }
    }

    // Identify problematic patterns
    for (final entry in failurePatterns.entries) {
      final action = entry.key;
      final failures = entry.value;
      final successes = successPatterns[action] ?? 0;
      final total = failures + successes;

      if (total > 10 && failures / total > 0.3) {
        emitEvent('swarm.pattern.problematic', {
          'action': action,
          'failureRate': failures / total,
          'totalOccurrences': total,
        });
      }
    }

    // Save memory periodically
    if (_learningCycles % 6 == 0) {
      // Every 30 minutes
      _saveMemory();
    }
  }

  Future<void> _loadMemory() async {
    try {
      final snapshot = await _db.collection('swarm_memory').get();
      for (final doc in snapshot.docs) {
        final memory = AgentMemory.fromMap(doc.data());
        _agentMemory[memory.agentId] = memory;
      }
      _memoryLoaded = true;
      debugPrint('[SWARM 3.0] Loaded memory for ${_agentMemory.length} agents');
    } catch (e) {
      debugPrint('[SWARM 3.0] Memory load failed: $e');
    }
  }

  Future<void> _saveMemory() async {
    try {
      final batch = _db.batch();
      for (final entry in _agentMemory.entries) {
        final ref = _db.collection('swarm_memory').doc(entry.key);
        batch.set(ref, entry.value.toMap());
      }
      await batch.commit();
      debugPrint('[SWARM 3.0] Saved memory for ${_agentMemory.length} agents');
    } catch (e) {
      debugPrint('[SWARM 3.0] Memory save failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTONOMY CONTROL
  // ═══════════════════════════════════════════════════════════════════════════

  void setAutonomy(SwarmAutonomy level) {
    _autonomy = level;
    emitEvent('swarm.autonomy.changed', {'level': level.name});
    debugPrint('[SWARM 3.0] Autonomy set to ${level.name}');
  }

  /// Request approval for an action (in guided mode)
  Future<bool> requestApproval({
    required String action,
    required String description,
    required Map<String, dynamic> payload,
  }) async {
    if (_autonomy == SwarmAutonomy.autonomous ||
        _autonomy == SwarmAutonomy.supervised) {
      return true; // Auto-approve
    }

    // In guided/manual mode, emit request and wait
    await emitEvent('swarm.approval.requested', {
      'action': action,
      'description': description,
      'payload': payload,
    });

    // In real implementation, this would await user response
    // For now, return true for supervised mode
    return _autonomy == SwarmAutonomy.supervised;
  }

  /// Grant approval for a pending action
  void grantApproval(String actionId) {
    _bus.emit('swarm_3', 'swarm.approval.granted', {'actionId': actionId});
  }

  /// Deny approval for a pending action
  void denyApproval(String actionId, {String? reason}) {
    _bus.emit('swarm_3', 'swarm.approval.denied', {
      'actionId': actionId,
      'reason': reason,
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════════

  SwarmAutonomy get autonomy => _autonomy;
  bool get isRunning => _running;
  Map<String, AgentHealth> get agentHealth => Map.unmodifiable(_agentHealth);
  List<HealingRecord> get healingHistory => List.unmodifiable(_healingHistory);

  /// Get health summary
  Map<String, int> getHealthSummary() {
    final summary = <String, int>{};
    for (final health in AgentHealth.values) {
      summary[health.name] = _agentHealth.values
          .where((h) => h == health)
          .length;
    }
    return summary;
  }

  /// Get agent memory
  AgentMemory? getAgentMemory(String agentId) => _agentMemory[agentId];

  /// Get learning insights for an agent
  Map<String, double> getAgentSuccessRates(String agentId) {
    final memory = _agentMemory[agentId];
    if (memory == null) return {};

    final rates = <String, double>{};
    final allActions = {
      ...memory.actionSuccessCounts.keys,
      ...memory.actionFailureCounts.keys,
    };

    for (final action in allActions) {
      rates[action] = memory.getSuccessRate(action);
    }
    return rates;
  }

  /// Get full swarm metrics
  Map<String, dynamic> getMetrics() => {
    'running': _running,
    'autonomy': _autonomy.name,
    'totalAgents': _agentHealth.length,
    'healthSummary': getHealthSummary(),
    'totalRecoveries': _totalRecoveries,
    'learningCycles': _learningCycles,
    'autonomousActions': _autonomousActions,
    'memoryLoadedAgents': _agentMemory.length,
    'healingHistoryCount': _healingHistory.length,
  };

  /// Force healing attempt on specific agent
  void forceHeal(String agentId) {
    final health = _agentHealth[agentId] ?? AgentHealth.healthy;
    _attemptHealing(agentId, health);
  }

  /// Clear memory for an agent (reset learning)
  void clearAgentMemory(String agentId) {
    _agentMemory.remove(agentId);
    _db.collection('swarm_memory').doc(agentId).delete();
  }
}
