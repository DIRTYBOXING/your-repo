import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// BOT ORCHESTRATOR SERVICE — Central Registry & Lifecycle for ALL DFC Bots
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Manages the fleet of specialized bots:
///   • Warning Bots   — safety alerts, threat detection, policy violations
///   • Educating Bots — fight camp coach, sports science, nutrition mentor
///   • Advanced Bots  — fight predictions, AI breakdown, NLU assistant
///   • Promotional Bots — SEO, geo discovery, marketing campaigns
///
/// Architecture:
///   BotOrchestratorService
///     ├── registers bot definitions (BotDefinition)
///     ├── manages bot state (active/paused/disabled)
///     ├── routes user intents → correct bot
///     ├── enforces capability boundaries per role
///     ├── audits every bot action to Firestore
///     └── provides admin oversight via BotCommandCenter
///
/// Firestore:
///   bot_registry/{botId}         — Bot definition + config + enabled state
///   bot_actions/{actionId}       — Immutable audit log of every bot action
///   bot_conversations/{convId}   — Conversation history per user×bot
///
/// ═══════════════════════════════════════════════════════════════════════════

// ── Bot Types ──────────────────────────────────────────────────────────────

enum BotType { warning, educating, advanced, promotional }

enum BotStatus { active, paused, disabled, maintenance }

enum BotCapability {
  // Warning
  sendAlert,
  detectThreat,
  escalateToHuman,
  issueWarning,

  // Educating
  provideCoaching,
  generateTrainingPlan,
  nutritionAdvice,
  techniqueAnalysis,
  mentalHealthSupport,

  // Advanced
  predictFightOutcome,
  analyzeMatchup,
  simulateFight,
  naturalLanguageChat,
  scheduleContent,

  // Promotional
  generateSeoMeta,
  optimizeDiscoverability,
  geoTargetContent,
  runCampaign,
  trackEngagement,
}

// ── Data Models ────────────────────────────────────────────────────────────

class BotDefinition {
  final String id;
  final String displayName;
  final String description;
  final BotType type;
  final BotStatus status;
  final Set<BotCapability> capabilities;
  final String avatarEmoji;
  final Map<String, dynamic> config;
  final DateTime registeredAt;
  final DateTime? lastActiveAt;
  final int totalActions;

  const BotDefinition({
    required this.id,
    required this.displayName,
    required this.description,
    required this.type,
    this.status = BotStatus.active,
    required this.capabilities,
    this.avatarEmoji = '🤖',
    this.config = const {},
    required this.registeredAt,
    this.lastActiveAt,
    this.totalActions = 0,
  });

  factory BotDefinition.fromMap(Map<String, dynamic> m) => BotDefinition(
    id: m['id'] ?? '',
    displayName: m['displayName'] ?? '',
    description: m['description'] ?? '',
    type: BotType.values.firstWhere(
      (t) => t.name == m['type'],
      orElse: () => BotType.educating,
    ),
    status: BotStatus.values.firstWhere(
      (s) => s.name == m['status'],
      orElse: () => BotStatus.active,
    ),
    capabilities:
        (m['capabilities'] as List<dynamic>?)
            ?.map(
              (c) => BotCapability.values.firstWhere(
                (b) => b.name == c,
                orElse: () => BotCapability.naturalLanguageChat,
              ),
            )
            .toSet() ??
        {},
    avatarEmoji: m['avatarEmoji'] ?? '🤖',
    config: Map<String, dynamic>.from(m['config'] ?? {}),
    registeredAt: (m['registeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    lastActiveAt: (m['lastActiveAt'] as Timestamp?)?.toDate(),
    totalActions: m['totalActions'] ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'displayName': displayName,
    'description': description,
    'type': type.name,
    'status': status.name,
    'capabilities': capabilities.map((c) => c.name).toList(),
    'avatarEmoji': avatarEmoji,
    'config': config,
    'registeredAt': Timestamp.fromDate(registeredAt),
    'lastActiveAt': lastActiveAt != null
        ? Timestamp.fromDate(lastActiveAt!)
        : null,
    'totalActions': totalActions,
  };

  bool get isActive => status == BotStatus.active;
  bool hasCapability(BotCapability cap) => capabilities.contains(cap);
}

/// Immutable audit record of a bot action.
class BotAction {
  final String actionId;
  final String botId;
  final String? userId;
  final String actionType;
  final String description;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final bool success;
  final String? errorMessage;

  const BotAction({
    required this.actionId,
    required this.botId,
    this.userId,
    required this.actionType,
    required this.description,
    this.payload = const {},
    required this.timestamp,
    this.success = true,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() => {
    'actionId': actionId,
    'botId': botId,
    'userId': userId,
    'actionType': actionType,
    'description': description,
    'payload': payload,
    'timestamp': Timestamp.fromDate(timestamp),
    'success': success,
    'errorMessage': errorMessage,
  };
}

// ── Orchestrator ───────────────────────────────────────────────────────────

class BotOrchestratorService extends ChangeNotifier {
  BotOrchestratorService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // In-memory registry
  final Map<String, BotDefinition> _bots = {};
  List<BotDefinition> get allBots => _bots.values.toList();
  List<BotDefinition> get activeBots =>
      _bots.values.where((b) => b.isActive).toList();
  List<BotDefinition> botsByType(BotType type) =>
      _bots.values.where((b) => b.type == type).toList();

  // ── INITIALIZATION ──────────────────────────────────────────────────────

  /// Load all bot definitions from Firestore (or seed defaults).
  Future<void> initialize() async {
    try {
      final snap = await _firestore.collection('bot_registry').get();
      if (snap.docs.isEmpty) {
        await _seedDefaultBots();
      } else {
        _bots.clear();
        for (final doc in snap.docs) {
          final bot = BotDefinition.fromMap(doc.data());
          _bots[bot.id] = bot;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('BotOrch: init error: $e');
      _seedLocalDefaults();
    }
  }

  // ── REGISTRY ────────────────────────────────────────────────────────────

  BotDefinition? getBot(String botId) => _bots[botId];

  /// Register a new bot (admin only).
  Future<void> registerBot(BotDefinition bot) async {
    _bots[bot.id] = bot;
    await _firestore.collection('bot_registry').doc(bot.id).set(bot.toMap());
    notifyListeners();
  }

  /// Update bot status (pause, disable, reactivate).
  Future<void> setBotStatus(String botId, BotStatus status) async {
    final existing = _bots[botId];
    if (existing == null) return;
    final updated = BotDefinition(
      id: existing.id,
      displayName: existing.displayName,
      description: existing.description,
      type: existing.type,
      status: status,
      capabilities: existing.capabilities,
      avatarEmoji: existing.avatarEmoji,
      config: existing.config,
      registeredAt: existing.registeredAt,
      lastActiveAt: DateTime.now(),
      totalActions: existing.totalActions,
    );
    _bots[botId] = updated;
    await _firestore.collection('bot_registry').doc(botId).update({
      'status': status.name,
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

  // ── ACTION AUDIT ────────────────────────────────────────────────────────

  /// Log every bot action to immutable audit trail.
  Future<void> logAction(BotAction action) async {
    try {
      await _firestore.collection('bot_actions').add(action.toMap());
      // Increment counter
      await _firestore.collection('bot_registry').doc(action.botId).update({
        'totalActions': FieldValue.increment(1),
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('BotOrch: logAction error: $e');
    }
  }

  /// Fetch recent actions for a bot (admin dashboard).
  Future<List<BotAction>> getRecentActions(
    String botId, {
    int limit = 20,
  }) async {
    try {
      final snap = await _firestore
          .collection('bot_actions')
          .where('botId', isEqualTo: botId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) {
        final m = d.data();
        return BotAction(
          actionId: d.id,
          botId: m['botId'] ?? botId,
          userId: m['userId'],
          actionType: m['actionType'] ?? '',
          description: m['description'] ?? '',
          payload: Map<String, dynamic>.from(m['payload'] ?? {}),
          timestamp: (m['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          success: m['success'] ?? true,
          errorMessage: m['errorMessage'],
        );
      }).toList();
    } catch (e) {
      debugPrint('BotOrch: getRecentActions error: $e');
      return [];
    }
  }

  // ── INTENT ROUTING ──────────────────────────────────────────────────────

  /// Route a user intent to the best-matching active bot.
  BotDefinition? routeIntent(BotCapability capability) {
    return activeBots.cast<BotDefinition?>().firstWhere(
      (b) => b!.hasCapability(capability),
      orElse: () => null,
    );
  }

  /// Route by bot type (for category-based UIs).
  List<BotDefinition> getActiveByType(BotType type) =>
      activeBots.where((b) => b.type == type).toList();

  // ── CONVERSATION MANAGEMENT ─────────────────────────────────────────────

  /// Save a conversation message for user↔bot.
  Future<void> saveMessage({
    required String botId,
    required String userId,
    required String role, // 'user' or 'bot'
    required String message,
  }) async {
    await _firestore
        .collection('bot_conversations')
        .doc('${userId}_$botId')
        .collection('messages')
        .add({
          'role': role,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  /// Stream conversation history.
  Stream<List<Map<String, dynamic>>> streamConversation({
    required String botId,
    required String userId,
    int limit = 50,
  }) {
    return _firestore
        .collection('bot_conversations')
        .doc('${userId}_$botId')
        .collection('messages')
        .orderBy('timestamp')
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  // ── STATS ───────────────────────────────────────────────────────────────

  /// Get aggregate stats across all bots.
  Map<String, dynamic> getFleetStats() {
    return {
      'totalBots': _bots.length,
      'activeBots': activeBots.length,
      'warningBots': botsByType(BotType.warning).length,
      'educatingBots': botsByType(BotType.educating).length,
      'advancedBots': botsByType(BotType.advanced).length,
      'promotionalBots': botsByType(BotType.promotional).length,
      'totalActions': _bots.values.fold<int>(
        0,
        (acc, b) => acc + b.totalActions,
      ),
    };
  }

  // ── SEEDING ─────────────────────────────────────────────────────────────

  Future<void> _seedDefaultBots() async {
    final defaults = _defaultBots;
    for (final bot in defaults) {
      _bots[bot.id] = bot;
      await _firestore.collection('bot_registry').doc(bot.id).set(bot.toMap());
    }
  }

  void _seedLocalDefaults() {
    _bots.clear();
    for (final bot in _defaultBots) {
      _bots[bot.id] = bot;
    }
  }

  List<BotDefinition> get _defaultBots => [
    // ── WARNING BOTS ──
    BotDefinition(
      id: 'sentinel',
      displayName: 'Sentinel',
      description:
          'Platform safety guardian. Detects threats, issues warnings, '
          'escalates critical incidents to human moderators.',
      type: BotType.warning,
      capabilities: {
        BotCapability.sendAlert,
        BotCapability.detectThreat,
        BotCapability.escalateToHuman,
        BotCapability.issueWarning,
      },
      avatarEmoji: '🛡️',
      registeredAt: DateTime(2025),
    ),

    // ── EDUCATING BOTS ──
    BotDefinition(
      id: 'shido',
      displayName: 'Samurai Shido',
      description:
          'Fight camp coach. Sports science, periodization, fight IQ, '
          'biomechanics, nutrition timing, recovery protocols.',
      type: BotType.educating,
      capabilities: {
        BotCapability.provideCoaching,
        BotCapability.generateTrainingPlan,
        BotCapability.nutritionAdvice,
        BotCapability.techniqueAnalysis,
        BotCapability.mentalHealthSupport,
      },
      avatarEmoji: '⚔️',
      registeredAt: DateTime(2025),
    ),
    BotDefinition(
      id: 'alma',
      displayName: 'Alma',
      description:
          'Nutrition & recovery specialist. Hydration protocols, '
          'weight cut science, supplement stacks, sleep optimization.',
      type: BotType.educating,
      capabilities: {
        BotCapability.nutritionAdvice,
        BotCapability.provideCoaching,
        BotCapability.mentalHealthSupport,
      },
      avatarEmoji: '🍎',
      registeredAt: DateTime(2025),
    ),
    BotDefinition(
      id: 'levi',
      displayName: 'Levi',
      description:
          'Strength & conditioning engine. Periodization cycles, '
          'power output tracking, VO₂max estimation, injury prevention.',
      type: BotType.educating,
      capabilities: {
        BotCapability.generateTrainingPlan,
        BotCapability.provideCoaching,
        BotCapability.techniqueAnalysis,
      },
      avatarEmoji: '💪',
      registeredAt: DateTime(2025),
    ),

    // ── ADVANCED BOTS ──
    BotDefinition(
      id: 'oracle',
      displayName: 'The Oracle',
      description:
          'Fight prediction engine. Monte Carlo simulation, style matchup '
          'analysis, odds calculation, round-by-round breakdown.',
      type: BotType.advanced,
      capabilities: {
        BotCapability.predictFightOutcome,
        BotCapability.analyzeMatchup,
        BotCapability.simulateFight,
        BotCapability.naturalLanguageChat,
      },
      avatarEmoji: '🔮',
      registeredAt: DateTime(2025),
    ),
    BotDefinition(
      id: 'posterboy',
      displayName: 'PosterBoy',
      description:
          'Creative chaos engine. AI art, poster generation, meme culture, '
          'and visual hype for fight promotions.',
      type: BotType.advanced,
      capabilities: {
        BotCapability.naturalLanguageChat,
        BotCapability.scheduleContent,
      },
      avatarEmoji: '🎨',
      registeredAt: DateTime(2025),
    ),

    // ── PROMOTIONAL BOTS ──
    BotDefinition(
      id: 'seo_hawk',
      displayName: 'SEO Hawk',
      description:
          'Autonomous SEO engine. Meta-tag generation, JSON-LD schema, '
          'canonical URLs, fighter/gym/event discoverability optimization.',
      type: BotType.promotional,
      capabilities: {
        BotCapability.generateSeoMeta,
        BotCapability.optimizeDiscoverability,
        BotCapability.trackEngagement,
      },
      avatarEmoji: '🦅',
      registeredAt: DateTime(2025),
    ),
    BotDefinition(
      id: 'geo_scout',
      displayName: 'Geo Scout',
      description:
          'Location intelligence bot. Gym discovery, event proximity, '
          'regional fight scene mapping, travel package suggestions.',
      type: BotType.promotional,
      capabilities: {
        BotCapability.geoTargetContent,
        BotCapability.optimizeDiscoverability,
        BotCapability.trackEngagement,
      },
      avatarEmoji: '🌍',
      registeredAt: DateTime(2025),
    ),
    BotDefinition(
      id: 'blotato',
      displayName: 'Blotato',
      description:
          'Viral content coach. Hook analysis, cross-platform optimization, '
          'audience targeting, engagement amplification.',
      type: BotType.promotional,
      capabilities: {
        BotCapability.runCampaign,
        BotCapability.trackEngagement,
        BotCapability.optimizeDiscoverability,
      },
      avatarEmoji: '🥔',
      registeredAt: DateTime(2025),
    ),
  ];
}
