// ═══════════════════════════════════════════════════════════════════════════
// DFC UNIFIED EVENT BUS — Engine-to-Engine Communication Layer
// ═══════════════════════════════════════════════════════════════════════════
// All 25 engines communicate through this single event stream.
// Pub/Sub architecture with typed events, priority queues, and replay.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Event priority levels
enum EventPriority { critical, high, normal, low, background }

/// Event categories for routing
enum EventCategory {
  content, // Feed, posts, articles
  combat, // Fight analysis, predictions, matchmaking
  health, // Wellness, recovery, injury
  training, // Workouts, periodization, load
  social, // Friends, messaging, engagement
  payment, // Stripe, subscriptions, payouts
  streaming, // PPV, live events, CDN
  moderation, // Safety, trust, compliance
  notification, // Push, email, in-app
  analytics, // Metrics, tracking, insights
  swarm, // AI coordination, persona routing
  system, // Platform health, errors, logs
}

/// Base event class for the bus
class DFCEvent {
  final String id;
  final String source; // Engine that emitted the event
  final EventCategory category;
  final EventPriority priority;
  final String type; // Specific event type (e.g., 'content.created')
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final String? targetEngine; // Optional: route to specific engine
  final String? correlationId; // For event chains
  final int ttlSeconds; // Time-to-live
  final bool persist; // Write to Firestore

  DFCEvent({
    String? id,
    required this.source,
    required this.category,
    required this.type,
    required this.payload,
    this.priority = EventPriority.normal,
    this.targetEngine,
    this.correlationId,
    this.ttlSeconds = 300,
    this.persist = false,
  }) : id = id ?? '${DateTime.now().millisecondsSinceEpoch}_${source}_$type',
       timestamp = DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'source': source,
    'category': category.name,
    'priority': priority.name,
    'type': type,
    'payload': payload,
    'timestamp': Timestamp.fromDate(timestamp),
    'targetEngine': targetEngine,
    'correlationId': correlationId,
    'ttlSeconds': ttlSeconds,
  };

  factory DFCEvent.fromMap(Map<String, dynamic> map) => DFCEvent(
    id: map['id'],
    source: map['source'] ?? 'unknown',
    category: EventCategory.values.firstWhere(
      (e) => e.name == map['category'],
      orElse: () => EventCategory.system,
    ),
    priority: EventPriority.values.firstWhere(
      (e) => e.name == map['priority'],
      orElse: () => EventPriority.normal,
    ),
    type: map['type'] ?? 'unknown',
    payload: Map<String, dynamic>.from(map['payload'] ?? {}),
    targetEngine: map['targetEngine'],
    correlationId: map['correlationId'],
    ttlSeconds: map['ttlSeconds'] ?? 300,
  );
}

/// Subscription handle for cleanup
class EventSubscription {
  final String id;
  final String subscriberId;
  final EventCategory? category;
  final String? typePattern;
  final void Function(DFCEvent) handler;
  bool _active = true;

  EventSubscription({
    required this.id,
    required this.subscriberId,
    required this.handler,
    this.category,
    this.typePattern,
  });

  bool get isActive => _active;
  void cancel() => _active = false;
}

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC EVENT BUS — Singleton
/// ═══════════════════════════════════════════════════════════════════════════
class DFCEventBus {
  static final DFCEventBus _instance = DFCEventBus._internal();
  factory DFCEventBus() => _instance;
  DFCEventBus._internal();

  final _db = FirebaseFirestore.instance;

  // Event streams by priority
  final _criticalQueue = Queue<DFCEvent>();
  final _highQueue = Queue<DFCEvent>();
  final _normalQueue = Queue<DFCEvent>();
  final _lowQueue = Queue<DFCEvent>();
  final _backgroundQueue = Queue<DFCEvent>();

  // Subscriptions
  final Map<String, EventSubscription> _subscriptions = {};

  // Event history for replay (last 1000 events)
  final List<DFCEvent> _eventHistory = [];
  static const _maxHistory = 1000;

  // Metrics
  int _totalPublished = 0;
  int _totalDelivered = 0;
  int _totalDropped = 0;
  final Map<String, int> _eventCountBySource = {};
  final Map<String, int> _eventCountByCategory = {};

  // Processing
  Timer? _processTimer;
  bool _processing = false;

  /// Initialize the event bus
  void init() {
    _processTimer?.cancel();
    _processTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _processQueues(),
    );
    debugPrint('[EventBus] Initialized — processing every 50ms');
  }

  /// Shutdown the event bus
  void shutdown() {
    _processTimer?.cancel();
    _subscriptions.clear();
    debugPrint('[EventBus] Shutdown — $_totalPublished events processed');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLISH
  // ═══════════════════════════════════════════════════════════════════════════

  /// Publish an event to the bus
  Future<void> publish(DFCEvent event) async {
    _totalPublished++;
    _eventCountBySource[event.source] =
        (_eventCountBySource[event.source] ?? 0) + 1;
    _eventCountByCategory[event.category.name] =
        (_eventCountByCategory[event.category.name] ?? 0) + 1;

    // Add to appropriate queue
    switch (event.priority) {
      case EventPriority.critical:
        _criticalQueue.add(event);
        break;
      case EventPriority.high:
        _highQueue.add(event);
        break;
      case EventPriority.normal:
        _normalQueue.add(event);
        break;
      case EventPriority.low:
        _lowQueue.add(event);
        break;
      case EventPriority.background:
        _backgroundQueue.add(event);
        break;
    }

    // Track history
    _eventHistory.add(event);
    if (_eventHistory.length > _maxHistory) {
      _eventHistory.removeAt(0);
    }

    // Persist if requested
    if (event.persist) {
      try {
        await _db.collection('event_bus').doc(event.id).set(event.toMap());
      } catch (e) {
        debugPrint('[EventBus] Persist failed: $e');
      }
    }

    // Critical events processed immediately
    if (event.priority == EventPriority.critical) {
      _processQueues();
    }
  }

  /// Publish multiple events as a batch
  Future<void> publishBatch(List<DFCEvent> events) async {
    for (final event in events) {
      await publish(event);
    }
  }

  /// Quick publish helper
  Future<void> emit(
    String source,
    String type,
    Map<String, dynamic> payload, {
    EventCategory category = EventCategory.system,
    EventPriority priority = EventPriority.normal,
    String? correlationId,
  }) async {
    await publish(
      DFCEvent(
        source: source,
        category: category,
        type: type,
        payload: payload,
        priority: priority,
        correlationId: correlationId,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBSCRIBE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Subscribe to events
  EventSubscription subscribe({
    required String subscriberId,
    required void Function(DFCEvent) onEvent,
    EventCategory? category,
    String? typePattern,
  }) {
    final subId = '${subscriberId}_${DateTime.now().millisecondsSinceEpoch}';
    final subscription = EventSubscription(
      id: subId,
      subscriberId: subscriberId,
      handler: onEvent,
      category: category,
      typePattern: typePattern,
    );
    _subscriptions[subId] = subscription;
    debugPrint(
      '[EventBus] +Subscription: $subscriberId (category=$category, pattern=$typePattern)',
    );
    return subscription;
  }

  /// Unsubscribe
  void unsubscribe(EventSubscription subscription) {
    subscription.cancel();
    _subscriptions.remove(subscription.id);
    debugPrint('[EventBus] -Subscription: ${subscription.subscriberId}');
  }

  /// Unsubscribe all for a subscriber
  void unsubscribeAll(String subscriberId) {
    _subscriptions.removeWhere((_, sub) {
      if (sub.subscriberId == subscriberId) {
        sub.cancel();
        return true;
      }
      return false;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROCESSING
  // ═══════════════════════════════════════════════════════════════════════════

  void _processQueues() {
    if (_processing) return;
    _processing = true;

    try {
      // Process in priority order
      _processQueue(_criticalQueue, limit: 100);
      _processQueue(_highQueue, limit: 50);
      _processQueue(_normalQueue, limit: 20);
      _processQueue(_lowQueue);
      _processQueue(_backgroundQueue, limit: 5);
    } finally {
      _processing = false;
    }
  }

  void _processQueue(Queue<DFCEvent> queue, {int limit = 10}) {
    int processed = 0;
    while (queue.isNotEmpty && processed < limit) {
      final event = queue.removeFirst();

      // Check TTL
      final age = DateTime.now().difference(event.timestamp).inSeconds;
      if (age > event.ttlSeconds) {
        _totalDropped++;
        continue;
      }

      // Deliver to subscribers
      for (final sub in _subscriptions.values) {
        if (!sub.isActive) continue;

        // Filter by category
        if (sub.category != null && sub.category != event.category) continue;

        // Filter by type pattern
        if (sub.typePattern != null && !event.type.contains(sub.typePattern!)) {
          continue;
        }

        // Filter by target engine
        if (event.targetEngine != null &&
            event.targetEngine != sub.subscriberId) {
          continue;
        }

        try {
          sub.handler(event);
          _totalDelivered++;
        } catch (e) {
          debugPrint('[EventBus] Handler error (${sub.subscriberId}): $e');
        }
      }

      processed++;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY & REPLAY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get recent events by category
  List<DFCEvent> getRecentEvents({
    EventCategory? category,
    String? source,
    int limit = 50,
  }) {
    return _eventHistory
        .where((e) {
          if (category != null && e.category != category) return false;
          if (source != null && e.source != source) return false;
          return true;
        })
        .take(limit)
        .toList();
  }

  /// Replay events to a subscriber
  void replayEvents({
    required String subscriberId,
    required void Function(DFCEvent) onEvent,
    EventCategory? category,
    Duration? since,
  }) {
    final cutoff = since != null ? DateTime.now().subtract(since) : null;
    for (final event in _eventHistory) {
      if (cutoff != null && event.timestamp.isBefore(cutoff)) continue;
      if (category != null && event.category != category) continue;
      onEvent(event);
    }
  }

  /// Get events by correlation ID (event chain)
  List<DFCEvent> getEventChain(String correlationId) {
    return _eventHistory
        .where((e) => e.correlationId == correlationId)
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // METRICS
  // ═══════════════════════════════════════════════════════════════════════════

  Map<String, dynamic> getMetrics() => {
    'totalPublished': _totalPublished,
    'totalDelivered': _totalDelivered,
    'totalDropped': _totalDropped,
    'activeSubscriptions': _subscriptions.length,
    'queuedCritical': _criticalQueue.length,
    'queuedHigh': _highQueue.length,
    'queuedNormal': _normalQueue.length,
    'queuedLow': _lowQueue.length,
    'queuedBackground': _backgroundQueue.length,
    'historySize': _eventHistory.length,
    'bySource': _eventCountBySource,
    'byCategory': _eventCountByCategory,
  };

  /// Health check
  bool get isHealthy {
    final criticalBacklog = _criticalQueue.length;
    final highBacklog = _highQueue.length;
    return criticalBacklog < 100 && highBacklog < 500;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ENGINE BASE MIXIN — For engines to integrate with the bus
// ═══════════════════════════════════════════════════════════════════════════
mixin EventBusEngine {
  final DFCEventBus _bus = DFCEventBus();
  final List<EventSubscription> _engineSubscriptions = [];

  String get engineId;
  EventCategory get engineCategory;

  /// Emit an event from this engine
  Future<void> emitEvent(
    String type,
    Map<String, dynamic> payload, {
    EventPriority priority = EventPriority.normal,
    String? correlationId,
    bool persist = false,
  }) async {
    await _bus.publish(
      DFCEvent(
        source: engineId,
        category: engineCategory,
        type: type,
        payload: payload,
        priority: priority,
        correlationId: correlationId,
        persist: persist,
      ),
    );
  }

  /// Subscribe to events
  void listenToEvents({
    EventCategory? category,
    String? typePattern,
    required void Function(DFCEvent) onEvent,
  }) {
    final sub = _bus.subscribe(
      subscriberId: engineId,
      category: category,
      typePattern: typePattern,
      onEvent: onEvent,
    );
    _engineSubscriptions.add(sub);
  }

  /// Cleanup subscriptions
  void disposeEngineSubscriptions() {
    for (final sub in _engineSubscriptions) {
      _bus.unsubscribe(sub);
    }
    _engineSubscriptions.clear();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STANDARD EVENT TYPES — Typed events for common operations
// ═══════════════════════════════════════════════════════════════════════════
abstract class DFCEvents {
  // Content events
  static const contentCreated = 'content.created';
  static const contentUpdated = 'content.updated';
  static const contentDeleted = 'content.deleted';
  static const contentPublished = 'content.published';
  static const contentFlagged = 'content.flagged';

  // Combat events
  static const fightScheduled = 'combat.fight.scheduled';
  static const fightStarted = 'combat.fight.started';
  static const fightEnded = 'combat.fight.ended';
  static const predictionMade = 'combat.prediction.made';
  static const matchmakingRequested = 'combat.matchmaking.requested';

  // Health events
  static const healthMetricRecorded = 'health.metric.recorded';
  static const recoveryAlert = 'health.recovery.alert';
  static const injuryReported = 'health.injury.reported';
  static const readinessCalculated = 'health.readiness.calculated';

  // Training events
  static const workoutLogged = 'training.workout.logged';
  static const periodChanged = 'training.period.changed';
  static const loadAlert = 'training.load.alert';
  static const campStarted = 'training.camp.started';

  // Social events
  static const friendAdded = 'social.friend.added';
  static const messageReceived = 'social.message.received';
  static const engagementSpiked = 'social.engagement.spiked';
  static const userOnboarded = 'social.user.onboarded';

  // Payment events
  static const paymentSucceeded = 'payment.succeeded';
  static const paymentFailed = 'payment.failed';
  static const subscriptionCreated = 'subscription.created';
  static const subscriptionCanceled = 'subscription.canceled';
  static const payoutProcessed = 'payment.payout.processed';

  // Streaming events
  static const streamStarted = 'streaming.started';
  static const streamEnded = 'streaming.ended';
  static const viewerJoined = 'streaming.viewer.joined';
  static const ppvPurchased = 'streaming.ppv.purchased';

  // Moderation events
  static const contentReviewed = 'moderation.content.reviewed';
  static const userWarned = 'moderation.user.warned';
  static const userBanned = 'moderation.user.banned';
  static const safetyAlert = 'moderation.safety.alert';

  // Swarm events
  static const agentSpawned = 'swarm.agent.spawned';
  static const agentCompleted = 'swarm.agent.completed';
  static const agentFailed = 'swarm.agent.failed';
  static const swarmOptimized = 'swarm.optimized';
  static const personaRouted = 'swarm.persona.routed';

  // System events
  static const engineStarted = 'system.engine.started';
  static const engineStopped = 'system.engine.stopped';
  static const engineError = 'system.engine.error';
  static const healthCheckPassed = 'system.health.passed';
  static const healthCheckFailed = 'system.health.failed';
}
