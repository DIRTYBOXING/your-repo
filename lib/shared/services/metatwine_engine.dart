/// ═══════════════════════════════════════════════════════════════════════════
/// METATWINE ENGINE — DFC PLATFORM INTERTWINE ORCHESTRATOR
/// The Central Nervous System That Makes Every Service a Multiplier
/// ═══════════════════════════════════════════════════════════════════════════
///
/// MetaTwine is DFC's own creation — born from the intertwining of Meta's
/// open-source AI (TRIBE v2) with DFC's autonomous platform ecosystem.
/// DFC embraces Meta like family: every bot, every pipeline, every social
/// channel woven together into a self-automated AI-driven powerhouse.
///
/// Architecture:
///   ┌──────────────────────────────────────────────────────────────────┐
///   │                   METATWINE ORCHESTRATOR                        │
///   │                                                                  │
///   │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐          │
///   │  │ TRIBE   │  │ PSYCHE  │  │ SAMURAI │  │ ATLAS   │          │
///   │  │ Brain   │──│ Mental  │──│ Swarm   │──│ Command │          │
///   │  │ Encoder │  │ Mesh    │  │ Coord   │  │ Gate    │          │
///   │  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘          │
///   │       │            │            │            │                  │
///   │  ┌────▼────────────▼────────────▼────────────▼────┐           │
///   │  │         MULTIPLIER GRAPH ENGINE                 │           │
///   │  │  Feed × Brain × Social × PPV × Ads × Commerce  │           │
///   │  └────────────────────┬───────────────────────────┘           │
///   │                       │                                        │
///   │  ┌────────────────────▼───────────────────────────┐           │
///   │  │      GLOBAL PLATFORM PIPELINE REGISTRY          │           │
///   │  │  FB · IG · TikTok · YouTube · WeChat · LINE     │           │
///   │  │  ShareChat · Moj · Roposo · Likee · Snack       │           │
///   │  │  Bigo · Helo · Chingari · TamTam · DFC Native   │           │
///   │  └────────────────────┬───────────────────────────┘           │
///   │                       │                                        │
///   │  ┌────────────────────▼───────────────────────────┐           │
///   │  │      BOT CONTROL REGISTRY & CHAIN OF COMMAND    │           │
///   │  │  Strict role positions · No bot improvises       │           │
///   │  │  Human gate for high-risk · Audit every action   │           │
///   │  └────────────────────────────────────────────────┘           │
///   └──────────────────────────────────────────────────────────────────┘
///
/// Meta AI Collaboration Status: ACTIVE
/// Meta contacted DFC — interested in the technology and the builder.
/// This engine represents DFC as the first to utilise humology technology
/// with a human-AI interface at the intersection of combat sport and tech.
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS & CONSTANTS
// ═══════════════════════════════════════════════════════════════════════════

/// Every DFC subsystem that MetaTwine orchestrates
enum MetaTwineNode {
  // Neural & Brain
  tribeBrainEncoder,
  neuralMeshPsyche,
  combatIntelligence,

  // Swarm & Command
  samuraiSwarmCoordinator,
  samuraiCoreEngine,
  samuraiOrchestrator,
  atlasOrchestrator,
  swarm3Orchestrator,
  dfcNexus,

  // Content & Feed
  autoFeedOrchestrator,
  feedRankingEngine,
  contentScannerEngine,
  promoterAiService,
  contentSafetyService,
  moderationEngine,

  // Social & Community
  socialService,
  socialGraphService,
  socialConnectorService,
  liveChatService,
  matchmakingService,
  discoveryService,

  // Payment & Commerce
  paymentAuditService,
  ugcConsentService,
  stripeConnectService,
  paymentsService,
  nftCollectiblesService,
  fightMarketplace,
  ppvService,
  fightPassService,

  // AI & Bots
  dfcAiPowerhouse,
  samuraiService,
  aiCoachService,
  aiEsoEngine,

  // Health & Biometrics
  healthIntelligence,
  dfcWearablesEngine,
  sportsScienceEngine,
  bodyMonitorService,

  // Streaming & Media
  videoStreamingService,
  youtubeService,
  muxStreamingService,
  cdnMediaPipeline,

  // Events & News
  eventService,
  fightNewsService,
  liveFightTicker,

  // Promotion & Marketing
  promotionSequenceService,
  metaverseAdCampaignEngine,
  marketingAiService,
  emailBlastEngine,
  sponsorFeedEngine,

  // Analytics & Monitoring
  analyticsService,
  performanceService,

  // War Room & Admin
  warRoomEngine,
  warRoomOrchestration,

  // Global Distribution
  globalDistribution,
  globalPricing,
  globalRanking,
  globalSeo,

  // Safety
  safetyHub,
  chukyaRadar,

  // Meta AI Collaboration
  metaAiPartnership,
}

/// Bot autonomy level — strict chain of command
enum BotAutonomyLevel {
  manual, // Human triggers every action
  supervised, // Bot proposes, human approves
  guided, // Bot acts within guardrails, human reviews
  autonomous, // Bot acts freely within its role — no improvisation beyond role
}

/// Multiplier type — how two services amplify each other
enum MultiplierType {
  feedsInto, // Output of A becomes input to B
  amplifies, // A increases the effectiveness of B
  validates, // A verifies/gates the output of B
  monetizes, // A creates revenue from B's output
  distributes, // A pushes B's output to wider audience
  protects, // A safeguards B from risk/abuse
  learns, // A improves B through data/signal feedback
}

/// Global social platform region classification
enum PlatformRegion {
  western, // FB, IG, TikTok, YouTube, Twitter, Reddit, Snapchat
  eastAsian, // WeChat, Douyin, Bilibili, LINE, Kakao, Nico Nico
  southAsian, // ShareChat, Moj, Roposo, Chingari, Helo, Josh
  southeastAsian, // Likee, Bigo Live, Snack Video, TamTam
  middleEast, // Baaz, Sada, Arab social apps
  african, // Ayoba, 2go, Showmax Africa
  latin, // Kwai, RappiTV, Globoplay combat
  metaverse, // Horizon Worlds, Roblox, Fortnite, Decentraland
  dfcNative, // FightWire, DFC Feed, DFC PPV, DFC Social
  metaAi, // Meta AI partnership channel
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// A connection between two DFC services showing how they multiply each other
class MultiplierEdge {
  final MetaTwineNode from;
  final MetaTwineNode to;
  final MultiplierType type;
  final double weight; // 0.0–1.0 strength of connection
  final String description;

  const MultiplierEdge({
    required this.from,
    required this.to,
    required this.type,
    required this.weight,
    required this.description,
  });

  Map<String, dynamic> toMap() => {
    'from': from.name,
    'to': to.name,
    'type': type.name,
    'weight': weight,
    'description': description,
  };
}

/// A registered bot/agent with strict role assignment
class BotRegistration {
  final String botId;
  final String botName;
  final MetaTwineNode ownerNode;
  final BotAutonomyLevel autonomy;
  final List<String> permissions;
  final List<String> prohibitions;
  final bool requiresHumanGate;
  final DateTime registeredAt;
  final String roleDescription;

  const BotRegistration({
    required this.botId,
    required this.botName,
    required this.ownerNode,
    required this.autonomy,
    required this.permissions,
    required this.prohibitions,
    required this.requiresHumanGate,
    required this.registeredAt,
    required this.roleDescription,
  });

  Map<String, dynamic> toFirestore() => {
    'botId': botId,
    'botName': botName,
    'ownerNode': ownerNode.name,
    'autonomy': autonomy.name,
    'permissions': permissions,
    'prohibitions': prohibitions,
    'requiresHumanGate': requiresHumanGate,
    'registeredAt': Timestamp.fromDate(registeredAt),
    'roleDescription': roleDescription,
  };

  factory BotRegistration.fromFirestore(Map<String, dynamic> m) {
    return BotRegistration(
      botId: m['botId'] as String? ?? '',
      botName: m['botName'] as String? ?? '',
      ownerNode: MetaTwineNode.values.firstWhere(
        (v) => v.name == m['ownerNode'],
        orElse: () => MetaTwineNode.dfcAiPowerhouse,
      ),
      autonomy: BotAutonomyLevel.values.firstWhere(
        (v) => v.name == m['autonomy'],
        orElse: () => BotAutonomyLevel.supervised,
      ),
      permissions: List<String>.from(m['permissions'] ?? []),
      prohibitions: List<String>.from(m['prohibitions'] ?? []),
      requiresHumanGate: m['requiresHumanGate'] as bool? ?? true,
      registeredAt:
          (m['registeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      roleDescription: m['roleDescription'] as String? ?? '',
    );
  }
}

/// A global platform pipeline connector
class PlatformPipeline {
  final String platformId;
  final String platformName;
  final PlatformRegion region;
  final String country;
  final String language;
  final bool isActive;
  final bool isCombatRelevant;
  final double trustScore;
  final List<String> contentTypes; // fight_clip, news, live, ugc, reels, shorts
  final String apiEndpoint;
  final DateTime addedAt;

  const PlatformPipeline({
    required this.platformId,
    required this.platformName,
    required this.region,
    required this.country,
    required this.language,
    required this.isActive,
    required this.isCombatRelevant,
    required this.trustScore,
    required this.contentTypes,
    required this.apiEndpoint,
    required this.addedAt,
  });

  Map<String, dynamic> toFirestore() => {
    'platformId': platformId,
    'platformName': platformName,
    'region': region.name,
    'country': country,
    'language': language,
    'isActive': isActive,
    'isCombatRelevant': isCombatRelevant,
    'trustScore': trustScore,
    'contentTypes': contentTypes,
    'apiEndpoint': apiEndpoint,
    'addedAt': Timestamp.fromDate(addedAt),
  };

  factory PlatformPipeline.fromFirestore(Map<String, dynamic> m) {
    return PlatformPipeline(
      platformId: m['platformId'] as String? ?? '',
      platformName: m['platformName'] as String? ?? '',
      region: PlatformRegion.values.firstWhere(
        (v) => v.name == m['region'],
        orElse: () => PlatformRegion.dfcNative,
      ),
      country: m['country'] as String? ?? '',
      language: m['language'] as String? ?? 'en',
      isActive: m['isActive'] as bool? ?? false,
      isCombatRelevant: m['isCombatRelevant'] as bool? ?? false,
      trustScore: (m['trustScore'] as num?)?.toDouble() ?? 0.5,
      contentTypes: List<String>.from(m['contentTypes'] ?? []),
      apiEndpoint: m['apiEndpoint'] as String? ?? '',
      addedAt: (m['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Snapshot of the entire MetaTwine system health
class MetaTwineHealthSnapshot {
  final int totalNodes;
  final int activeNodes;
  final int totalBots;
  final int activeBots;
  final int totalPlatforms;
  final int activePlatforms;
  final int totalMultiplierEdges;
  final double systemMultiplierScore;
  final Map<String, double> nodeHealthMap;
  final DateTime timestamp;

  const MetaTwineHealthSnapshot({
    required this.totalNodes,
    required this.activeNodes,
    required this.totalBots,
    required this.activeBots,
    required this.totalPlatforms,
    required this.activePlatforms,
    required this.totalMultiplierEdges,
    required this.systemMultiplierScore,
    required this.nodeHealthMap,
    required this.timestamp,
  });

  double get healthPercent => totalNodes > 0 ? activeNodes / totalNodes : 0;
  bool get isHealthy => healthPercent > 0.7;

  Map<String, dynamic> toFirestore() => {
    'totalNodes': totalNodes,
    'activeNodes': activeNodes,
    'totalBots': totalBots,
    'activeBots': activeBots,
    'totalPlatforms': totalPlatforms,
    'activePlatforms': activePlatforms,
    'totalMultiplierEdges': totalMultiplierEdges,
    'systemMultiplierScore': systemMultiplierScore,
    'nodeHealthMap': nodeHealthMap,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}

/// Audit record for every MetaTwine inter-service action
class MetaTwineAuditEntry {
  final String id;
  final MetaTwineNode sourceNode;
  final MetaTwineNode targetNode;
  final String action;
  final String outcome;
  final bool humanApproved;
  final String botId;
  final DateTime timestamp;

  const MetaTwineAuditEntry({
    required this.id,
    required this.sourceNode,
    required this.targetNode,
    required this.action,
    required this.outcome,
    required this.humanApproved,
    required this.botId,
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'sourceNode': sourceNode.name,
    'targetNode': targetNode.name,
    'action': action,
    'outcome': outcome,
    'humanApproved': humanApproved,
    'botId': botId,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// METATWINE ENGINE — THE ORCHESTRATOR
// ═══════════════════════════════════════════════════════════════════════════

class MetaTwineEngine extends ChangeNotifier {
  static final MetaTwineEngine _instance = MetaTwineEngine._internal();
  factory MetaTwineEngine() => _instance;
  MetaTwineEngine._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── State ─────────────────────────────────────────────────────────
  bool _initialized = false;
  bool get initialized => _initialized;

  final Map<MetaTwineNode, double> _nodeHealth = {};
  final List<MultiplierEdge> _multiplierGraph = [];
  final Map<String, BotRegistration> _botRegistry = {};
  final List<PlatformPipeline> _platformPipelines = [];
  final List<MetaTwineAuditEntry> _auditLog = [];

  // ─── Initialization ────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('[MetaTwine] Booting DFC MetaTwine Orchestrator...');

    // Step 1: Build the multiplier graph — how every service amplifies every other
    _buildMultiplierGraph();

    // Step 2: Register all bots with strict chain of command
    _registerAllBots();

    // Step 3: Load global platform pipelines
    _loadPlatformPipelines();

    // Step 4: Initialize node health tracking
    for (final node in MetaTwineNode.values) {
      _nodeHealth[node] = 1.0; // Start healthy
    }

    // Step 5: Persist initial state to Firestore
    await _persistHealth();

    _initialized = true;
    debugPrint(
      '[MetaTwine] MetaTwine online. '
      '${_multiplierGraph.length} multiplier edges, '
      '${_botRegistry.length} bots registered, '
      '${_platformPipelines.length} platform pipelines active.',
    );
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  // MULTIPLIER GRAPH — How Every Service Amplifies Every Other
  // ═══════════════════════════════════════════════════════════════════

  List<MultiplierEdge> get multiplierGraph =>
      List.unmodifiable(_multiplierGraph);

  void _buildMultiplierGraph() {
    _multiplierGraph.clear();
    _multiplierGraph.addAll([
      // ── TRIBE Brain → Feed Ranking (Brain signals guide content order)
      const MultiplierEdge(
        from: MetaTwineNode.tribeBrainEncoder,
        to: MetaTwineNode.feedRankingEngine,
        type: MultiplierType.feedsInto,
        weight: 0.90,
        description:
            'Brain activation predictions drive 10% of feed ranking weight',
      ),
      // ── TRIBE Brain → PSYCHE Neural Mesh (Brain state enriches mental analysis)
      const MultiplierEdge(
        from: MetaTwineNode.tribeBrainEncoder,
        to: MetaTwineNode.neuralMeshPsyche,
        type: MultiplierType.amplifies,
        weight: 0.85,
        description:
            'Trimodal brain predictions enhance PSYCHE mental state analysis with 5 brain fields',
      ),
      // ── TRIBE Brain → Wearables (EEG calibration from brain encoder)
      const MultiplierEdge(
        from: MetaTwineNode.tribeBrainEncoder,
        to: MetaTwineNode.dfcWearablesEngine,
        type: MultiplierType.learns,
        weight: 0.80,
        description:
            'TRIBE predictions calibrate EEG brainwave data from wearable sensors',
      ),
      // ── Feed Ranking → Social (Ranked feed drives engagement quality)
      const MultiplierEdge(
        from: MetaTwineNode.feedRankingEngine,
        to: MetaTwineNode.socialService,
        type: MultiplierType.amplifies,
        weight: 0.75,
        description:
            'Smart ranking increases quality engagement and time on platform',
      ),
      // ── Content Scanner → Auto Feed (Ingested content normalizes into feed)
      const MultiplierEdge(
        from: MetaTwineNode.contentScannerEngine,
        to: MetaTwineNode.autoFeedOrchestrator,
        type: MultiplierType.feedsInto,
        weight: 0.95,
        description:
            'Multi-source content scanner pipes normalized items into unified feed',
      ),
      // ── Auto Feed → Feed Ranking (Normalized feed gets ranked)
      const MultiplierEdge(
        from: MetaTwineNode.autoFeedOrchestrator,
        to: MetaTwineNode.feedRankingEngine,
        type: MultiplierType.feedsInto,
        weight: 0.90,
        description: 'Auto feed aggregation provides ranked content pool',
      ),
      // ── UGC Consent → Payment Audit (Consent gates promotions)
      const MultiplierEdge(
        from: MetaTwineNode.ugcConsentService,
        to: MetaTwineNode.paymentAuditService,
        type: MultiplierType.validates,
        weight: 1.00,
        description:
            'Content cannot be promoted without active double-opt-in UGC consent',
      ),
      // ── Payment Audit → Stripe Connect (Promotion payments flow through Connect)
      const MultiplierEdge(
        from: MetaTwineNode.paymentAuditService,
        to: MetaTwineNode.stripeConnectService,
        type: MultiplierType.monetizes,
        weight: 0.95,
        description:
            'Paid promotions create revenue via Stripe Connect direct charges',
      ),
      // ── Promoter AI → Feed (AI-generated promos enter the feed pipeline)
      const MultiplierEdge(
        from: MetaTwineNode.promoterAiService,
        to: MetaTwineNode.autoFeedOrchestrator,
        type: MultiplierType.feedsInto,
        weight: 0.70,
        description:
            '8 promo bots generate content that enters auto feed pipeline',
      ),
      // ── Social Graph → Feed Ranking (Relationship strength drives 35% of ranking)
      const MultiplierEdge(
        from: MetaTwineNode.socialGraphService,
        to: MetaTwineNode.feedRankingEngine,
        type: MultiplierType.amplifies,
        weight: 0.95,
        description:
            'Relationship strength is the #1 ranking factor at 35% weight',
      ),
      // ── Analytics → TRIBE Brain (Engagement data calibrates brain predictions)
      const MultiplierEdge(
        from: MetaTwineNode.analyticsService,
        to: MetaTwineNode.tribeBrainEncoder,
        type: MultiplierType.learns,
        weight: 0.60,
        description:
            'Real engagement data feeds back to improve brain prediction accuracy',
      ),
      // ── Samurai Swarm → All Engines (Swarm orchestrates boot and health)
      const MultiplierEdge(
        from: MetaTwineNode.samuraiSwarmCoordinator,
        to: MetaTwineNode.dfcAiPowerhouse,
        type: MultiplierType.amplifies,
        weight: 0.85,
        description:
            'Swarm coordinator manages 13 sub-engines including AI powerhouse',
      ),
      // ── Atlas Orchestrator → All Bots (Job queue and human gates)
      const MultiplierEdge(
        from: MetaTwineNode.atlasOrchestrator,
        to: MetaTwineNode.samuraiSwarmCoordinator,
        type: MultiplierType.validates,
        weight: 0.90,
        description:
            'Atlas gates high-risk actions through human approval workflow',
      ),
      // ── Content Safety → Moderation (Safety validates before publish)
      const MultiplierEdge(
        from: MetaTwineNode.contentSafetyService,
        to: MetaTwineNode.moderationEngine,
        type: MultiplierType.protects,
        weight: 1.00,
        description:
            'Content safety screening required before moderation engine publishes',
      ),
      // ── PPV → Stripe (PPV purchases monetize through payments)
      const MultiplierEdge(
        from: MetaTwineNode.ppvService,
        to: MetaTwineNode.paymentsService,
        type: MultiplierType.monetizes,
        weight: 0.90,
        description:
            'PPV event purchases drive direct revenue through payment rails',
      ),
      // ── Wearables → Health Intelligence (Sensor data feeds health analysis)
      const MultiplierEdge(
        from: MetaTwineNode.dfcWearablesEngine,
        to: MetaTwineNode.healthIntelligence,
        type: MultiplierType.feedsInto,
        weight: 0.85,
        description:
            'BLE/UWB wearable sensor streams feed into health intelligence engine',
      ),
      // ── Health → Combat Intelligence (Health data informs fight analysis)
      const MultiplierEdge(
        from: MetaTwineNode.healthIntelligence,
        to: MetaTwineNode.combatIntelligence,
        type: MultiplierType.amplifies,
        weight: 0.70,
        description:
            'Health metrics enrich fighter profiling and matchup predictions',
      ),
      // ── Combat Intelligence → AI Coach (Analysis powers coaching)
      const MultiplierEdge(
        from: MetaTwineNode.combatIntelligence,
        to: MetaTwineNode.aiCoachService,
        type: MultiplierType.feedsInto,
        weight: 0.80,
        description:
            'Fighter profiles and technique analysis drive AI coaching recommendations',
      ),
      // ── Marketing AI → Email Blast (Marketing triggers email campaigns)
      const MultiplierEdge(
        from: MetaTwineNode.marketingAiService,
        to: MetaTwineNode.emailBlastEngine,
        type: MultiplierType.distributes,
        weight: 0.65,
        description:
            'AI marketing decisions trigger targeted email blasts for events and promos',
      ),
      // ── Video Streaming → CDN Pipeline (Live streams go through CDN)
      const MultiplierEdge(
        from: MetaTwineNode.videoStreamingService,
        to: MetaTwineNode.cdnMediaPipeline,
        type: MultiplierType.distributes,
        weight: 0.90,
        description:
            'Live fight streams distributed through multi-CDN pipeline',
      ),
      // ── Chukya Radar → Safety Hub (Threat detection feeds safety)
      const MultiplierEdge(
        from: MetaTwineNode.chukyaRadar,
        to: MetaTwineNode.safetyHub,
        type: MultiplierType.protects,
        weight: 0.95,
        description:
            'Chukya proximity/threat radar feeds into centralized safety hub',
      ),
      // ── Global Distribution → Global Pricing (Distribution informs pricing)
      const MultiplierEdge(
        from: MetaTwineNode.globalDistribution,
        to: MetaTwineNode.globalPricing,
        type: MultiplierType.amplifies,
        weight: 0.70,
        description:
            'Regional distribution data shapes dynamic pricing by geography',
      ),
      // ── Meta AI Partnership → TRIBE Brain (Meta AI improves brain models)
      const MultiplierEdge(
        from: MetaTwineNode.metaAiPartnership,
        to: MetaTwineNode.tribeBrainEncoder,
        type: MultiplierType.learns,
        weight: 0.95,
        description:
            'Meta AI collaboration feeds latest open-source model improvements into TRIBE',
      ),
      // ── Meta AI → Content Scanner (Meta platform APIs for content ingestion)
      const MultiplierEdge(
        from: MetaTwineNode.metaAiPartnership,
        to: MetaTwineNode.contentScannerEngine,
        type: MultiplierType.amplifies,
        weight: 0.80,
        description:
            'Meta Graph API integration for FB/IG content pipeline enrichment',
      ),
      // ── Meta AI → Promoter AI (Meta ad intelligence for promotion generation)
      const MultiplierEdge(
        from: MetaTwineNode.metaAiPartnership,
        to: MetaTwineNode.promoterAiService,
        type: MultiplierType.amplifies,
        weight: 0.75,
        description:
            'Meta ad optimization signals improve DFC promoter AI content quality',
      ),
      // ── PSYCHE → AI Coach (Mental state drives coaching tone)
      const MultiplierEdge(
        from: MetaTwineNode.neuralMeshPsyche,
        to: MetaTwineNode.aiCoachService,
        type: MultiplierType.feedsInto,
        weight: 0.75,
        description:
            'PSYCHE mental state analysis adapts AI coaching intensity and style',
      ),
      // ── War Room → All Systems (Admin oversight and kill switch)
      const MultiplierEdge(
        from: MetaTwineNode.warRoomEngine,
        to: MetaTwineNode.samuraiSwarmCoordinator,
        type: MultiplierType.validates,
        weight: 1.00,
        description:
            'War Room maintains admin oversight and emergency kill switch for all systems',
      ),
      // ── Sponsor Feed → Feed Ranking (Sponsored content enters ranking)
      const MultiplierEdge(
        from: MetaTwineNode.sponsorFeedEngine,
        to: MetaTwineNode.feedRankingEngine,
        type: MultiplierType.monetizes,
        weight: 0.70,
        description:
            'Sponsor content enters feed ranking with promotion transparency badges',
      ),
      // ── Discovery → Social Graph (Discovery drives new connections)
      const MultiplierEdge(
        from: MetaTwineNode.discoveryService,
        to: MetaTwineNode.socialGraphService,
        type: MultiplierType.amplifies,
        weight: 0.60,
        description: 'Fighter and gym discovery drives social graph expansion',
      ),
      // ── Fight News → Content Scanner (News feeds scanner pipeline)
      const MultiplierEdge(
        from: MetaTwineNode.fightNewsService,
        to: MetaTwineNode.contentScannerEngine,
        type: MultiplierType.feedsInto,
        weight: 0.80,
        description:
            'Fight news aggregator feeds into multi-source content scanner',
      ),
      // ── Metaverse Ad Campaign → Global Distribution (Ads go global)
      const MultiplierEdge(
        from: MetaTwineNode.metaverseAdCampaignEngine,
        to: MetaTwineNode.globalDistribution,
        type: MultiplierType.distributes,
        weight: 0.75,
        description:
            'Metaverse ad campaigns distribute through global channels',
      ),
    ]);
  }

  /// Get all edges where a given node is source or target
  List<MultiplierEdge> getEdgesForNode(MetaTwineNode node) {
    return _multiplierGraph
        .where((e) => e.from == node || e.to == node)
        .toList();
  }

  /// Calculate total multiplier effect for a node (sum of outgoing weights)
  double getNodeMultiplierPower(MetaTwineNode node) {
    final outgoing = _multiplierGraph.where((e) => e.from == node);
    if (outgoing.isEmpty) return 0;
    return outgoing.fold<double>(0, (acc, e) => acc + e.weight);
  }

  /// Total system multiplier score (sum of all edge weights)
  double get systemMultiplierScore {
    return _multiplierGraph.fold<double>(0, (acc, e) => acc + e.weight);
  }

  // ═══════════════════════════════════════════════════════════════════
  // BOT CONTROL REGISTRY — Strict Chain of Responsibility
  // ═══════════════════════════════════════════════════════════════════

  Map<String, BotRegistration> get botRegistry =>
      Map.unmodifiable(_botRegistry);

  void _registerAllBots() {
    _botRegistry.clear();
    final now = DateTime.now();

    // ── Content Scanner Bots (14 sources)
    _registerBot(
      BotRegistration(
        botId: 'scanner_facebook',
        botName: 'Facebook Combat Crawler',
        ownerNode: MetaTwineNode.contentScannerEngine,
        autonomy: BotAutonomyLevel.guided,
        permissions: ['scan_public_pages', 'extract_metadata', 'cache_content'],
        prohibitions: [
          'post_content',
          'message_users',
          'access_private_groups',
        ],
        requiresHumanGate: false,
        registeredAt: now,
        roleDescription:
            'Scans public Facebook pages/groups for combat sport content',
      ),
    );
    _registerBot(
      BotRegistration(
        botId: 'scanner_instagram',
        botName: 'Instagram Fight Scout',
        ownerNode: MetaTwineNode.contentScannerEngine,
        autonomy: BotAutonomyLevel.guided,
        permissions: [
          'scan_public_profiles',
          'extract_hashtag_content',
          'cache_stories',
        ],
        prohibitions: ['follow_users', 'like_posts', 'comment', 'access_dms'],
        requiresHumanGate: false,
        registeredAt: now,
        roleDescription: 'Scans public Instagram fight accounts and hashtags',
      ),
    );
    _registerBot(
      BotRegistration(
        botId: 'scanner_tiktok',
        botName: 'TikTok Fight Tracker',
        ownerNode: MetaTwineNode.contentScannerEngine,
        autonomy: BotAutonomyLevel.guided,
        permissions: ['scan_public_feed', 'extract_trending', 'cache_embeds'],
        prohibitions: ['create_videos', 'comment', 'duet', 'follow'],
        requiresHumanGate: false,
        registeredAt: now,
        roleDescription:
            'Tracks trending TikTok fight content via RSS and embeds',
      ),
    );
    _registerBot(
      BotRegistration(
        botId: 'scanner_youtube',
        botName: 'YouTube Combat Monitor',
        ownerNode: MetaTwineNode.contentScannerEngine,
        autonomy: BotAutonomyLevel.guided,
        permissions: ['scan_channels', 'extract_metadata', 'cache_thumbnails'],
        prohibitions: ['upload_videos', 'comment', 'subscribe_channels'],
        requiresHumanGate: false,
        registeredAt: now,
        roleDescription:
            'Monitors YouTube combat sport channels and trending clips',
      ),
    );

    // ── South Asian Pipeline Bots
    _registerBot(
      BotRegistration(
        botId: 'scanner_sharechat',
        botName: 'ShareChat Desi Fight Crawler',
        ownerNode: MetaTwineNode.contentScannerEngine,
        autonomy: BotAutonomyLevel.guided,
        permissions: [
          'scan_public_feed',
          'extract_regional_content',
          'cache_clips',
        ],
        prohibitions: ['post_content', 'comment', 'message_users'],
        requiresHumanGate: false,
        registeredAt: now,
        roleDescription:
            'Scans ShareChat for Indian combat sport content in Hindi/regional languages',
      ),
    );
    _registerBot(
      BotRegistration(
        botId: 'scanner_moj',
        botName: 'Moj Indian Combat Scout',
        ownerNode: MetaTwineNode.contentScannerEngine,
        autonomy: BotAutonomyLevel.guided,
        permissions: ['scan_trending', 'extract_short_video', 'cache_metadata'],
        prohibitions: ['create_content', 'interact_users'],
        requiresHumanGate: false,
        registeredAt: now,
        roleDescription:
            'Tracks Moj (India TikTok alternative) for pehlwani, boxing, MMA clips',
      ),
    );
    _registerBot(
      BotRegistration(
        botId: 'scanner_chingari',
        botName: 'Chingari Desi Fight Tracker',
        ownerNode: MetaTwineNode.contentScannerEngine,
        autonomy: BotAutonomyLevel.guided,
        permissions: ['scan_trending', 'extract_clips', 'cache_content'],
        prohibitions: ['create_content', 'interact_users'],
        requiresHumanGate: false,
        registeredAt: now,
        roleDescription:
            'Tracks Chingari for Indian and Pakistani martial arts content',
      ),
    );

    // ── Promoter AI Bots (8 bot army)
    for (final bot in [
      (
        'promo_hype',
        'HypeBot',
        'Generates hype and countdown content for events',
      ),
      (
        'promo_spotlight',
        'SpotlightBot',
        'Highlights individual fighter achievements',
      ),
      (
        'promo_matchmaker',
        'MatchmakerBot',
        'Creates compelling matchup analysis content',
      ),
      (
        'promo_trend',
        'TrendBot',
        'Identifies and amplifies trending combat topics',
      ),
      (
        'promo_campaign',
        'CampaignBot',
        'Manages multi-day promotional campaigns',
      ),
      (
        'promo_event',
        'EventBot',
        'Generates event-specific promotional material',
      ),
      (
        'promo_viral',
        'ViralBot',
        'Crafts shareable highlight and reaction content',
      ),
      (
        'promo_analytics',
        'AnalyticsBot',
        'Generates performance reports and insights',
      ),
    ]) {
      _registerBot(
        BotRegistration(
          botId: bot.$1,
          botName: bot.$2,
          ownerNode: MetaTwineNode.promoterAiService,
          autonomy: BotAutonomyLevel.guided,
          permissions: [
            'generate_content',
            'read_analytics',
            'suggest_schedule',
          ],
          prohibitions: [
            'publish_without_review',
            'modify_pricing',
            'access_payments',
          ],
          requiresHumanGate: false,
          registeredAt: now,
          roleDescription: bot.$3,
        ),
      );
    }

    // ── Neural & Brain Bots
    _registerBot(
      BotRegistration(
        botId: 'tribe_encoder',
        botName: 'TRIBE v2 Brain Encoder',
        ownerNode: MetaTwineNode.tribeBrainEncoder,
        autonomy: BotAutonomyLevel.guided,
        permissions: [
          'analyze_content',
          'predict_brain_response',
          'cache_predictions',
        ],
        prohibitions: [
          'access_raw_eeg',
          'share_predictions_externally',
          'modify_user_data',
        ],
        requiresHumanGate: false,
        registeredAt: now,
        roleDescription:
            'Predicts brain activation from trimodal content input via Atlas Backend',
      ),
    );
    _registerBot(
      BotRegistration(
        botId: 'psyche_analyzer',
        botName: 'PSYCHE Mental State Analyzer',
        ownerNode: MetaTwineNode.neuralMeshPsyche,
        autonomy: BotAutonomyLevel.supervised,
        permissions: [
          'analyze_mood',
          'predict_mental_state',
          'generate_insight',
        ],
        prohibitions: [
          'diagnose_conditions',
          'prescribe_treatment',
          'share_health_data',
        ],
        requiresHumanGate: true,
        registeredAt: now,
        roleDescription:
            'Analyzes fighter mental state from mood entries and brain signals — human-gated for health safety',
      ),
    );

    // ── Payment & Consent Bots
    _registerBot(
      BotRegistration(
        botId: 'consent_guardian',
        botName: 'UGC Consent Guardian',
        ownerNode: MetaTwineNode.ugcConsentService,
        autonomy: BotAutonomyLevel.autonomous,
        permissions: ['verify_consent', 'revoke_expired', 'audit_log'],
        prohibitions: [
          'grant_consent_on_behalf',
          'modify_terms',
          'bypass_double_opt_in',
        ],
        requiresHumanGate: false,
        registeredAt: now,
        roleDescription:
            'Enforces UGC consent lifecycle — cannot be overridden by other bots',
      ),
    );
    _registerBot(
      BotRegistration(
        botId: 'fairness_enforcer',
        botName: 'Promotion Fairness Enforcer',
        ownerNode: MetaTwineNode.paymentAuditService,
        autonomy: BotAutonomyLevel.autonomous,
        permissions: [
          'check_promoter_cap',
          'allocate_impressions',
          'force_stop_promotion',
        ],
        prohibitions: ['create_payments', 'modify_pricing', 'bypass_consent'],
        requiresHumanGate: false,
        registeredAt: now,
        roleDescription:
            'Enforces 25% max promoter share cap and baseline impression allocation',
      ),
    );

    // ── Meta AI Collaboration Bot
    _registerBot(
      BotRegistration(
        botId: 'meta_ai_liaison',
        botName: 'Meta AI Partnership Liaison',
        ownerNode: MetaTwineNode.metaAiPartnership,
        autonomy: BotAutonomyLevel.supervised,
        permissions: [
          'sync_model_updates',
          'report_performance',
          'request_api_access',
        ],
        prohibitions: [
          'share_user_data',
          'grant_data_access',
          'modify_privacy_settings',
        ],
        requiresHumanGate: true,
        registeredAt: now,
        roleDescription:
            'Manages Meta AI collaboration — model updates, API sync, performance reporting',
      ),
    );

    // ── Samurai Command Bots
    _registerBot(
      BotRegistration(
        botId: 'shido_brain',
        botName: 'Shido — DFC Heart & Soul',
        ownerNode: MetaTwineNode.samuraiOrchestrator,
        autonomy: BotAutonomyLevel.guided,
        permissions: [
          'route_intents',
          'coach_users',
          'generate_wisdom',
          'emotional_intelligence',
        ],
        prohibitions: [
          'access_payments',
          'modify_content',
          'improvise_outside_role',
        ],
        requiresHumanGate: false,
        registeredAt: now,
        roleDescription:
            'Primary AI persona — direct, actionable coaching language, no shallow behavior',
      ),
    );
    _registerBot(
      BotRegistration(
        botId: 'war_room_admin',
        botName: 'War Room Command',
        ownerNode: MetaTwineNode.warRoomEngine,
        autonomy: BotAutonomyLevel.supervised,
        permissions: [
          'kill_switch',
          'emergency_stop',
          'approve_high_risk',
          'audit_all',
        ],
        prohibitions: [
          'auto_approve_payments',
          'bypass_consent',
          'disable_safety',
        ],
        requiresHumanGate: true,
        registeredAt: now,
        roleDescription:
            'War Room admin control — emergency kill switch, always human-gated',
      ),
    );
  }

  void _registerBot(BotRegistration bot) {
    _botRegistry[bot.botId] = bot;
  }

  /// Check if a bot is allowed to perform an action
  bool isBotAllowed(String botId, String action) {
    final bot = _botRegistry[botId];
    if (bot == null) return false;
    if (bot.prohibitions.contains(action)) return false;
    return bot.permissions.contains(action);
  }

  /// Check if an action requires human approval
  bool requiresHumanGate(String botId) {
    return _botRegistry[botId]?.requiresHumanGate ?? true;
  }

  // ═══════════════════════════════════════════════════════════════════
  // GLOBAL PLATFORM PIPELINE REGISTRY
  // Facebook · Instagram · TikTok · YouTube + Asian · South Asian ·
  // Pakistani · Punjabi · Indian platforms for global content pipeline
  // ═══════════════════════════════════════════════════════════════════

  List<PlatformPipeline> get platformPipelines =>
      List.unmodifiable(_platformPipelines);

  List<PlatformPipeline> getPlatformsByRegion(PlatformRegion region) {
    return _platformPipelines.where((p) => p.region == region).toList();
  }

  List<PlatformPipeline> getActivePlatforms() {
    return _platformPipelines.where((p) => p.isActive).toList();
  }

  List<PlatformPipeline> getCombatRelevantPlatforms() {
    return _platformPipelines
        .where((p) => p.isActive && p.isCombatRelevant)
        .toList();
  }

  void _loadPlatformPipelines() {
    _platformPipelines.clear();
    final now = DateTime.now();

    _platformPipelines.addAll([
      // ── WESTERN (Meta Family + Major Western)
      PlatformPipeline(
        platformId: 'facebook',
        platformName: 'Facebook / Meta',
        region: PlatformRegion.western,
        country: 'US',
        language: 'en',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.85,
        contentTypes: ['fight_clip', 'news', 'live', 'ugc', 'event'],
        apiEndpoint: 'graph.facebook.com/v19.0',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'instagram',
        platformName: 'Instagram / Meta',
        region: PlatformRegion.western,
        country: 'US',
        language: 'en',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.85,
        contentTypes: ['reels', 'stories', 'fight_clip', 'ugc', 'highlights'],
        apiEndpoint: 'graph.instagram.com/v19.0',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'tiktok',
        platformName: 'TikTok',
        region: PlatformRegion.western,
        country: 'US',
        language: 'en',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.75,
        contentTypes: ['shorts', 'fight_clip', 'ugc', 'trending'],
        apiEndpoint: 'open.tiktokapis.com/v2',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'youtube',
        platformName: 'YouTube',
        region: PlatformRegion.western,
        country: 'US',
        language: 'en',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.90,
        contentTypes: [
          'fight_clip',
          'live',
          'highlights',
          'training',
          'analysis',
        ],
        apiEndpoint: 'youtube.googleapis.com/v3',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'twitter',
        platformName: 'X / Twitter',
        region: PlatformRegion.western,
        country: 'US',
        language: 'en',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.70,
        contentTypes: ['news', 'live_updates', 'highlights', 'opinions'],
        apiEndpoint: 'api.twitter.com/2',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'reddit',
        platformName: 'Reddit',
        region: PlatformRegion.western,
        country: 'US',
        language: 'en',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.75,
        contentTypes: ['discussion', 'fight_clip', 'analysis', 'news'],
        apiEndpoint: 'oauth.reddit.com',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'linkedin',
        platformName: 'LinkedIn',
        region: PlatformRegion.western,
        country: 'US',
        language: 'en',
        isActive: true,
        isCombatRelevant: false,
        trustScore: 0.80,
        contentTypes: ['business', 'partnerships', 'industry_news'],
        apiEndpoint: 'api.linkedin.com/v2',
        addedAt: now,
      ),

      // ── EAST ASIAN PLATFORMS
      PlatformPipeline(
        platformId: 'wechat',
        platformName: 'WeChat / Weixin',
        region: PlatformRegion.eastAsian,
        country: 'CN',
        language: 'zh',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.80,
        contentTypes: ['fight_clip', 'news', 'live', 'ugc'],
        apiEndpoint: 'api.weixin.qq.com',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'douyin',
        platformName: 'Douyin (China TikTok)',
        region: PlatformRegion.eastAsian,
        country: 'CN',
        language: 'zh',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.75,
        contentTypes: ['shorts', 'fight_clip', 'wushu', 'sanda', 'mma'],
        apiEndpoint: 'open.douyin.com',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'bilibili',
        platformName: 'Bilibili',
        region: PlatformRegion.eastAsian,
        country: 'CN',
        language: 'zh',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.80,
        contentTypes: ['fight_clip', 'analysis', 'live', 'training'],
        apiEndpoint: 'api.bilibili.com',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'weibo',
        platformName: 'Weibo',
        region: PlatformRegion.eastAsian,
        country: 'CN',
        language: 'zh',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.70,
        contentTypes: ['news', 'opinions', 'fight_clip', 'trending'],
        apiEndpoint: 'api.weibo.com/2',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'line',
        platformName: 'LINE',
        region: PlatformRegion.eastAsian,
        country: 'JP',
        language: 'ja',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.80,
        contentTypes: ['news', 'fight_clip', 'live'],
        apiEndpoint: 'api.line.me/v2',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'kakao',
        platformName: 'KakaoTalk / Daum',
        region: PlatformRegion.eastAsian,
        country: 'KR',
        language: 'ko',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.80,
        contentTypes: ['news', 'fight_clip', 'live'],
        apiEndpoint: 'kapi.kakao.com',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'niconico',
        platformName: 'Nico Nico Douga',
        region: PlatformRegion.eastAsian,
        country: 'JP',
        language: 'ja',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.75,
        contentTypes: ['fight_clip', 'live', 'judo', 'karate', 'sumo'],
        apiEndpoint: 'api.nicovideo.jp',
        addedAt: now,
      ),

      // ── SOUTH ASIAN PLATFORMS (India, Pakistan, Bangladesh, Punjab)
      PlatformPipeline(
        platformId: 'sharechat',
        platformName: 'ShareChat (India Facebook)',
        region: PlatformRegion.southAsian,
        country: 'IN',
        language: 'hi',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.70,
        contentTypes: [
          'fight_clip',
          'ugc',
          'kushti',
          'pehlwani',
          'boxing',
          'mma',
        ],
        apiEndpoint: 'api.sharechat.com',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'moj',
        platformName: 'Moj (India TikTok)',
        region: PlatformRegion.southAsian,
        country: 'IN',
        language: 'hi',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.70,
        contentTypes: [
          'shorts',
          'fight_clip',
          'kushti',
          'pehlwani',
          'trending',
        ],
        apiEndpoint: 'api.mojapp.in',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'josh',
        platformName: 'Josh (India Short Video)',
        region: PlatformRegion.southAsian,
        country: 'IN',
        language: 'hi',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.65,
        contentTypes: ['shorts', 'fight_clip', 'ugc', 'trending'],
        apiEndpoint: 'api.myjosh.in',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'roposo',
        platformName: 'Roposo',
        region: PlatformRegion.southAsian,
        country: 'IN',
        language: 'hi',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.65,
        contentTypes: ['shorts', 'fight_clip', 'ugc'],
        apiEndpoint: 'api.roposo.com',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'chingari',
        platformName: 'Chingari',
        region: PlatformRegion.southAsian,
        country: 'IN',
        language: 'hi',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.65,
        contentTypes: ['shorts', 'fight_clip', 'ugc', 'martial_arts'],
        apiEndpoint: 'api.chingari.io',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'helo',
        platformName: 'Helo',
        region: PlatformRegion.southAsian,
        country: 'IN',
        language: 'hi',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.60,
        contentTypes: ['ugc', 'fight_clip', 'news'],
        apiEndpoint: 'api.helo-app.com',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'takatak',
        platformName: 'MX TakaTak',
        region: PlatformRegion.southAsian,
        country: 'IN',
        language: 'hi',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.65,
        contentTypes: ['shorts', 'fight_clip', 'ugc'],
        apiEndpoint: 'api.mxtakatak.com',
        addedAt: now,
      ),
      // Pakistani & Punjabi Platforms
      PlatformPipeline(
        platformId: 'daraz_live',
        platformName: 'Daraz Live (Pakistan)',
        region: PlatformRegion.southAsian,
        country: 'PK',
        language: 'ur',
        isActive: true,
        isCombatRelevant: false,
        trustScore: 0.60,
        contentTypes: ['live', 'events', 'ugc'],
        apiEndpoint: 'api.daraz.pk',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'bigo_pk',
        platformName: 'Bigo Live Pakistan',
        region: PlatformRegion.southAsian,
        country: 'PK',
        language: 'ur',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.55,
        contentTypes: ['live', 'fight_clip', 'ugc', 'pehlwani'],
        apiEndpoint: 'api.bigo.tv',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'snack_pk',
        platformName: 'Snack Video Pakistan',
        region: PlatformRegion.southAsian,
        country: 'PK',
        language: 'ur',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.55,
        contentTypes: ['shorts', 'fight_clip', 'ugc', 'kabaddi'],
        apiEndpoint: 'api.snackvideo.com',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'likee_pk',
        platformName: 'Likee Pakistan',
        region: PlatformRegion.southAsian,
        country: 'PK',
        language: 'ur',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.55,
        contentTypes: ['shorts', 'fight_clip', 'ugc'],
        apiEndpoint: 'api.likee.video',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'tiktok_pk',
        platformName: 'TikTok Pakistan / Punjabi',
        region: PlatformRegion.southAsian,
        country: 'PK',
        language: 'pa',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.70,
        contentTypes: [
          'shorts',
          'fight_clip',
          'ugc',
          'pehlwani',
          'kushti',
          'kabaddi',
        ],
        apiEndpoint: 'open.tiktokapis.com/v2',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'facebook_pk',
        platformName: 'Facebook Pakistan (Urdu/Punjabi Pages)',
        region: PlatformRegion.southAsian,
        country: 'PK',
        language: 'ur',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.75,
        contentTypes: ['fight_clip', 'news', 'live', 'ugc', 'pehlwani'],
        apiEndpoint: 'graph.facebook.com/v19.0',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'youtube_pk',
        platformName: 'YouTube Pakistan / Punjabi',
        region: PlatformRegion.southAsian,
        country: 'PK',
        language: 'pa',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.80,
        contentTypes: [
          'fight_clip',
          'live',
          'highlights',
          'kushti',
          'pehlwani',
        ],
        apiEndpoint: 'youtube.googleapis.com/v3',
        addedAt: now,
      ),

      // ── SOUTHEAST ASIAN PLATFORMS
      PlatformPipeline(
        platformId: 'likee',
        platformName: 'Likee',
        region: PlatformRegion.southeastAsian,
        country: 'SG',
        language: 'en',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.60,
        contentTypes: ['shorts', 'fight_clip', 'muay_thai', 'silat'],
        apiEndpoint: 'api.likee.video',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'bigo',
        platformName: 'Bigo Live',
        region: PlatformRegion.southeastAsian,
        country: 'SG',
        language: 'en',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.60,
        contentTypes: ['live', 'fight_clip', 'muay_thai', 'events'],
        apiEndpoint: 'api.bigo.tv',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'snack_video',
        platformName: 'Snack Video',
        region: PlatformRegion.southeastAsian,
        country: 'ID',
        language: 'id',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.55,
        contentTypes: ['shorts', 'fight_clip', 'pencak_silat'],
        apiEndpoint: 'api.snackvideo.com',
        addedAt: now,
      ),

      // ── MIDDLE EAST
      PlatformPipeline(
        platformId: 'tamtam',
        platformName: 'TamTam',
        region: PlatformRegion.middleEast,
        country: 'RU',
        language: 'ar',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.60,
        contentTypes: ['news', 'fight_clip', 'ugc'],
        apiEndpoint: 'api.tamtam.chat',
        addedAt: now,
      ),

      // ── METAVERSE
      PlatformPipeline(
        platformId: 'horizon_worlds',
        platformName: 'Meta Horizon Worlds',
        region: PlatformRegion.metaverse,
        country: 'US',
        language: 'en',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.80,
        contentTypes: ['vr_experience', 'live_event', 'training_sim'],
        apiEndpoint: 'horizon.meta.com/api',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'roblox',
        platformName: 'Roblox',
        region: PlatformRegion.metaverse,
        country: 'US',
        language: 'en',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.70,
        contentTypes: ['game_experience', 'fight_sim', 'events'],
        apiEndpoint: 'apis.roblox.com',
        addedAt: now,
      ),

      // ── DFC NATIVE
      PlatformPipeline(
        platformId: 'fightwire',
        platformName: 'FightWire (DFC Native Feed)',
        region: PlatformRegion.dfcNative,
        country: 'AU',
        language: 'en',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 1.00,
        contentTypes: [
          'fight_clip',
          'news',
          'live',
          'ugc',
          'ppv',
          'training',
          'analysis',
        ],
        apiEndpoint: 'dfc.internal/fightwire',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'dfc_social',
        platformName: 'DFC Social Feed',
        region: PlatformRegion.dfcNative,
        country: 'AU',
        language: 'en',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 1.00,
        contentTypes: [
          'posts',
          'stories',
          'ugc',
          'gym_content',
          'fighter_updates',
        ],
        apiEndpoint: 'dfc.internal/social',
        addedAt: now,
      ),
      PlatformPipeline(
        platformId: 'dfc_ppv',
        platformName: 'DFC PPV / Fight Pass',
        region: PlatformRegion.dfcNative,
        country: 'AU',
        language: 'en',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 1.00,
        contentTypes: ['ppv_event', 'fight_pass', 'replay', 'live'],
        apiEndpoint: 'dfc.internal/ppv',
        addedAt: now,
      ),
      // FightPipe — DFC's official YouTube channel (first-party, trust 1.00)
      PlatformPipeline(
        platformId: 'fightpipe_youtube',
        platformName: 'FightPipe YouTube (DFC Official)',
        region: PlatformRegion.dfcNative,
        country: 'AU',
        language: 'en',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 1.00,
        contentTypes: [
          'fight_clip',
          'highlight',
          'live',
          'ppv_preview',
          'analysis',
          'press_conference',
        ],
        apiEndpoint: 'youtube.com/@FightPipe',
        addedAt: now,
      ),
      // DFC Facebook — DFC's official Facebook page (first-party, trust 1.00)
      PlatformPipeline(
        platformId: 'dfc_facebook',
        platformName: 'DFC Facebook Official Page',
        region: PlatformRegion.dfcNative,
        country: 'AU',
        language: 'en',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 1.00,
        contentTypes: [
          'event_post',
          'fight_announcement',
          'fan_engagement',
          'ugc',
          'live',
        ],
        apiEndpoint: 'facebook.com/datafightcentral',
        addedAt: now,
      ),

      // ── META AI PARTNERSHIP CHANNEL
      PlatformPipeline(
        platformId: 'meta_ai',
        platformName: 'Meta AI Collaboration',
        region: PlatformRegion.metaAi,
        country: 'US',
        language: 'en',
        isActive: true,
        isCombatRelevant: true,
        trustScore: 0.95,
        contentTypes: [
          'model_updates',
          'api_sync',
          'research',
          'brain_prediction',
        ],
        apiEndpoint: 'ai.meta.com/api/v1',
        addedAt: now,
      ),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════
  // SYSTEM HEALTH & MONITORING
  // ═══════════════════════════════════════════════════════════════════

  /// Get current health snapshot
  MetaTwineHealthSnapshot getHealthSnapshot() {
    return MetaTwineHealthSnapshot(
      totalNodes: MetaTwineNode.values.length,
      activeNodes: _nodeHealth.values.where((h) => h > 0.5).length,
      totalBots: _botRegistry.length,
      activeBots: _botRegistry.values
          .where((b) => b.autonomy != BotAutonomyLevel.manual)
          .length,
      totalPlatforms: _platformPipelines.length,
      activePlatforms: _platformPipelines.where((p) => p.isActive).length,
      totalMultiplierEdges: _multiplierGraph.length,
      systemMultiplierScore: systemMultiplierScore,
      nodeHealthMap: Map.from(_nodeHealth.map((k, v) => MapEntry(k.name, v))),
      timestamp: DateTime.now(),
    );
  }

  /// Update health for a specific node
  void updateNodeHealth(MetaTwineNode node, double health) {
    _nodeHealth[node] = health.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Get health for a specific node
  double getNodeHealth(MetaTwineNode node) => _nodeHealth[node] ?? 0;

  // ═══════════════════════════════════════════════════════════════════
  // AUDIT TRAIL — Every Inter-Service Action Logged
  // ═══════════════════════════════════════════════════════════════════

  Future<void> logAction({
    required MetaTwineNode source,
    required MetaTwineNode target,
    required String action,
    required String outcome,
    required String botId,
    bool humanApproved = false,
  }) async {
    final entry = MetaTwineAuditEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}_${source.name}_${target.name}',
      sourceNode: source,
      targetNode: target,
      action: action,
      outcome: outcome,
      humanApproved: humanApproved,
      botId: botId,
      timestamp: DateTime.now(),
    );
    _auditLog.add(entry);

    // Persist to Firestore
    try {
      await _firestore
          .collection('metatwine_audit')
          .doc(entry.id)
          .set(entry.toFirestore());
    } catch (e) {
      debugPrint('[MetaTwine] Audit write failed: $e');
    }
  }

  List<MetaTwineAuditEntry> get recentAudit => _auditLog.length > 100
      ? _auditLog.sublist(_auditLog.length - 100)
      : List.from(_auditLog);

  // ═══════════════════════════════════════════════════════════════════
  // PERSIST STATE
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _persistHealth() async {
    try {
      final snapshot = getHealthSnapshot();
      await _firestore
          .collection('metatwine_state')
          .doc('health')
          .set(snapshot.toFirestore());
    } catch (e) {
      debugPrint('[MetaTwine] Health persist failed: $e');
    }
  }

  /// Persist full bot registry to Firestore
  Future<void> persistBotRegistry() async {
    try {
      final batch = _firestore.batch();
      for (final entry in _botRegistry.entries) {
        batch.set(
          _firestore.collection('metatwine_bots').doc(entry.key),
          entry.value.toFirestore(),
        );
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[MetaTwine] Bot registry persist failed: $e');
    }
  }

  /// Persist all platform pipelines to Firestore
  Future<void> persistPlatformPipelines() async {
    try {
      final batch = _firestore.batch();
      for (final platform in _platformPipelines) {
        batch.set(
          _firestore.collection('metatwine_platforms').doc(platform.platformId),
          platform.toFirestore(),
        );
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[MetaTwine] Platform persist failed: $e');
    }
  }
}
