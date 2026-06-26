// ignore_for_file: unused_field
import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'dfc_ai_powerhouse.dart';
import 'samurai_core_engine.dart';
import 'samurai_orchestrator.dart';
import 'samurai_content_transformer.dart';
import 'dfc_social_engine.dart';
import 'content_rotation_engine.dart';
import 'dfc_nexus.dart';
import 'quantum_optimization_service.dart';
import 'sports_science_engine.dart';
import 'combat_intelligence_engine.dart';
import 'health_intelligence_engine.dart';
import 'sponsor_feed_engine.dart';
import 'metaverse_ad_campaign_engine.dart';
import 'tribe_brain_encoder_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ██████╗ ███████╗ ██████╗    ███████╗██╗    ██╗ █████╗ ██████╗ ███╗   ███╗
// ██╔══██╗██╔════╝██╔════╝    ██╔════╝██║    ██║██╔══██╗██╔══██╗████╗ ████║
// ██║  ██║█████╗  ██║         ███████╗██║ █╗ ██║███████║██████╔╝██╔████╔██║
// ██║  ██║██╔══╝  ██║         ╚════██║██║███╗██║██╔══██║██╔══██╗██║╚██╔╝██║
// ██████╔╝██║     ╚██████╗    ███████║╚███╔███╔╝██║  ██║██║  ██║██║ ╚═╝ ██║
// ╚═════╝ ╚═╝      ╚═════╝    ╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝
// ═══════════════════════════════════════════════════════════════════════════════
//
// SAMURAI SWARM COORDINATOR
// The unified meta-intelligence that boots, coordinates, and commands
// ALL 53 agents + 25 engines as a single living organism.
//
// This is the HIVE MIND of Data Fight Central.
//
// Architecture:
//   SwarmCoordinator
//     ├── DFCAIPowerhouse (38 scanner bots + 8 promo bots + 5 sub-engines)
//     ├── SamuraiCoreEngine (autonomous protocol + 6 pillars)
//     ├── SamuraiOrchestrator (7 AI personas + conversational routing)
//     ├── SamuraiContentTransformer (content rewriting + 8-platform variants)
//     ├── DfcSocialEngine (cross-platform distribution)
//     ├── ContentRotationEngine (6-hour auto-swap)
//     ├── CombatIntelligenceEngine (fighter profiling)
//     ├── HealthIntelligenceEngine (health signals)
//     ├── SponsorFeedEngine (paid content priority)
//     ├── MetaverseAdCampaignEngine (metaverse ads)
//     ├── DfcNexus (mega-intelligence 10 modules)
//     ├── QuantumOptimizationService (fight prediction)
//     └── SportsScienceEngine (biometrics/periodization)
//
// The swarm auto-generates content, fills all pages, cross-feeds intelligence,
// and keeps DFC pumping 24/7 like a fuel-injected promotional freight train.
// ═══════════════════════════════════════════════════════════════════════════════

/// Status of a single agent in the swarm
enum AgentStatus { offline, booting, online, error, dormant }

/// Priority level for swarm messages
enum SwarmPriority { low, normal, high, critical }

/// A swarm agent descriptor
class SwarmAgent {
  final String id;
  final String name;
  final String emoji;
  final String engineName;
  final String role;
  final AgentStatus status;
  final DateTime? lastActive;
  final int contentGenerated;
  final double performanceScore;

  const SwarmAgent({
    required this.id,
    required this.name,
    required this.emoji,
    required this.engineName,
    required this.role,
    this.status = AgentStatus.offline,
    this.lastActive,
    this.contentGenerated = 0,
    this.performanceScore = 0.0,
  });

  SwarmAgent copyWith({
    AgentStatus? status,
    DateTime? lastActive,
    int? contentGenerated,
    double? performanceScore,
  }) => SwarmAgent(
    id: id,
    name: name,
    emoji: emoji,
    engineName: engineName,
    role: role,
    status: status ?? this.status,
    lastActive: lastActive ?? this.lastActive,
    contentGenerated: contentGenerated ?? this.contentGenerated,
    performanceScore: performanceScore ?? this.performanceScore,
  );
}

/// A message sent between swarm agents via the message bus
class SwarmMessage {
  final String id;
  final String fromAgent;
  final String toAgent; // '*' = broadcast
  final String type;
  final String payload;
  final SwarmPriority priority;
  final DateTime timestamp;

  const SwarmMessage({
    required this.id,
    required this.fromAgent,
    required this.toAgent,
    required this.type,
    required this.payload,
    this.priority = SwarmPriority.normal,
    required this.timestamp,
  });
}

/// Real-time swarm health snapshot
class SwarmHealthSnapshot {
  final DateTime timestamp;
  final int totalAgents;
  final int onlineAgents;
  final int contentGeneratedThisCycle;
  final int totalContentGenerated;
  final int messagesProcessed;
  final double swarmEfficiency;
  final double contentVelocity; // items per minute
  final Map<String, AgentStatus> engineStatus;
  final List<SwarmMessage> recentMessages;
  final String swarmMood;

  const SwarmHealthSnapshot({
    required this.timestamp,
    required this.totalAgents,
    required this.onlineAgents,
    required this.contentGeneratedThisCycle,
    required this.totalContentGenerated,
    required this.messagesProcessed,
    required this.swarmEfficiency,
    required this.contentVelocity,
    required this.engineStatus,
    this.recentMessages = const [],
    required this.swarmMood,
  });
}

/// Auto-generated content item for page filling
class SwarmContent {
  final String id;
  final String type; // news, event, story, post, promo, training, highlight
  final String title;
  final String body;
  final String source; // which agent/engine generated it
  final String category;
  final List<String> tags;
  final String imageUrl;
  final DateTime createdAt;
  final double hypeScore;
  final Map<String, dynamic> metadata;

  const SwarmContent({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.source,
    required this.category,
    this.tags = const [],
    this.imageUrl = '',
    required this.createdAt,
    this.hypeScore = 0.0,
    this.metadata = const {},
  });

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'type': type,
    'title': title,
    'body': body,
    'source': source,
    'category': category,
    'tags': tags,
    'imageUrl': imageUrl,
    'mediaUrls': imageUrl.isNotEmpty ? [imageUrl] : <String>[],
    'thumbnailUrl': imageUrl.isNotEmpty ? imageUrl : null,
    'createdAt': Timestamp.fromDate(createdAt),
    'hypeScore': hypeScore,
    'metadata': metadata,
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// THE SWARM COORDINATOR — HIVE MIND
// ═══════════════════════════════════════════════════════════════════════════════

class SamuraiSwarmCoordinator extends ChangeNotifier {
  static final SamuraiSwarmCoordinator _instance =
      SamuraiSwarmCoordinator._internal();
  factory SamuraiSwarmCoordinator() => _instance;
  SamuraiSwarmCoordinator._internal();

  static const Map<String, String> _generatedMediaByType = {
    'post': 'assets/dfc_backgrounds/new_dfc_image_1.png',
    'event': 'assets/dfc_backgrounds/dfc_and_back_ground.png',
    'promo': 'assets/dfc_backgrounds/datafight_central_with_logo.png',
    'drone_racing': 'assets/dfc_backgrounds/datafightlogo.png',
    'news': 'assets/dfc_backgrounds/new_dfc_image_1.png',
    'fight_news': 'assets/dfc_backgrounds/dfc_and_back_ground.png',
  };

  String _generatedImageForType(String type) =>
      _generatedMediaByType[type] ??
      'assets/dfc_backgrounds/new_dfc_image_1.png';

  // ── Sub-engines ──────────────────────────────────────────────────────────
  final DFCAIPowerhouse _powerhouse = DFCAIPowerhouse();
  final SamuraiCoreEngine _coreEngine = SamuraiCoreEngine();
  final SamuraiOrchestrator _orchestrator = SamuraiOrchestrator();
  final SamuraiContentTransformer _transformer = SamuraiContentTransformer();
  final DfcSocialEngine _socialEngine = DfcSocialEngine();
  final ContentRotationEngine _rotation = ContentRotationEngine();
  final CombatIntelligenceEngine _combatIntel = CombatIntelligenceEngine();
  final HealthIntelligenceEngine _healthIntel = HealthIntelligenceEngine();
  final SponsorFeedEngine _sponsorFeed = SponsorFeedEngine();
  final MetaverseAdCampaignEngine _metaverseAds = MetaverseAdCampaignEngine();
  final DfcNexus _nexus = DfcNexus();
  final QuantumOptimizationService _quantum = QuantumOptimizationService();
  final SportsScienceEngine _sportsSci = SportsScienceEngine();
  final TribeBrainEncoderService _tribeBrain = TribeBrainEncoderService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final math.Random _rng = math.Random();

  // ── State ────────────────────────────────────────────────────────────────
  bool _initialized = false;
  bool _swarmActive = false;
  Timer? _heartbeat;
  Timer? _contentPump;
  int _cycleCount = 0;
  int _totalContentGenerated = 0;
  int _messagesProcessed = 0;
  DateTime? _bootTime;

  final List<SwarmAgent> _agents = [];
  final List<SwarmMessage> _messageBus = [];
  final List<SwarmContent> _contentQueue = [];
  SwarmHealthSnapshot? _latestHealth;

  // ── Public getters ───────────────────────────────────────────────────────
  bool get initialized => _initialized;
  bool get swarmActive => _swarmActive;
  int get cycleCount => _cycleCount;
  int get totalContentGenerated => _totalContentGenerated;
  DateTime? get bootTime => _bootTime;
  List<SwarmAgent> get agents => List.unmodifiable(_agents);
  List<SwarmMessage> get messageBus => List.unmodifiable(_messageBus.take(100));
  List<SwarmContent> get contentQueue => List.unmodifiable(_contentQueue);
  SwarmHealthSnapshot? get latestHealth => _latestHealth;
  DFCAIPowerhouse get powerhouse => _powerhouse;
  SamuraiCoreEngine get coreEngine => _coreEngine;
  SamuraiOrchestrator get orchestrator => _orchestrator;
  SamuraiContentTransformer get transformer => _transformer;
  TribeBrainEncoderService get tribeBrain => _tribeBrain;

  int get onlineAgents =>
      _agents.where((a) => a.status == AgentStatus.online).length;
  int get totalAgents => _agents.length;

  // ── Hype Ramp State ─────────────────────────────────────────────────────
  String _currentHypePhase = 'baseline';
  int _currentPromoBursts = 1;
  String get currentHypePhase => _currentHypePhase;
  int get currentPromoBursts => _currentPromoBursts;

  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 1: BOOT SEQUENCE — Wake every engine in the swarm
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> bootSwarm() async {
    if (_initialized) return;
    _bootTime = DateTime.now();
    debugPrint('');
    debugPrint(
      '⚔️══════════════════════════════════════════════════════════⚔️',
    );
    debugPrint('⚔️  SAMURAI SWARM COORDINATOR — BOOTING ALL AGENTS         ⚔️');
    debugPrint('⚔️  53 agents · 25 engines · 1 hive mind                   ⚔️');
    debugPrint(
      '⚔️══════════════════════════════════════════════════════════⚔️',
    );
    debugPrint('');

    // Register all agents
    _registerAllAgents();
    notifyListeners();

    // Phase 1: Core Engine (boots Powerhouse → Scanner+Promoter+News+Meta+ESO)
    debugPrint('⚔️ [SWARM] Phase 1: Booting SamuraiCoreEngine...');
    _setEngineStatus('samurai_core', AgentStatus.booting);
    try {
      await _coreEngine.initialize();
      _setEngineStatus('samurai_core', AgentStatus.online);
      debugPrint(
        '  ✅ SamuraiCoreEngine ONLINE (includes Powerhouse + 46 bots)',
      );
    } catch (e) {
      _setEngineStatus('samurai_core', AgentStatus.error);
      debugPrint('  ⚠️ SamuraiCoreEngine: $e');
    }

    // Phase 2: Orchestrator (chat + personas)
    debugPrint('⚔️ [SWARM] Phase 2: Booting SamuraiOrchestrator...');
    _setEngineStatus('orchestrator', AgentStatus.booting);
    try {
      await _orchestrator.initialize();
      _setEngineStatus('orchestrator', AgentStatus.online);
      // Mark all persona agents online
      for (final p in ['shido', 'posterboy', 'general']) {
        _updateAgent('persona_$p', status: AgentStatus.online);
      }
      debugPrint('  ✅ SamuraiOrchestrator ONLINE (3 personas active)');
    } catch (e) {
      _setEngineStatus('orchestrator', AgentStatus.error);
      debugPrint('  ⚠️ Orchestrator: $e');
    }

    // Phase 3: Content Transformer + Social Engine
    debugPrint('⚔️ [SWARM] Phase 3: Booting Content Pipeline...');
    _setEngineStatus('transformer', AgentStatus.booting);
    _setEngineStatus('social_engine', AgentStatus.booting);
    try {
      await _socialEngine.loadHistory();
      _setEngineStatus('social_engine', AgentStatus.online);
      debugPrint('  ✅ DfcSocialEngine ONLINE (8 platforms ready)');
    } catch (e) {
      _setEngineStatus('social_engine', AgentStatus.error);
      debugPrint('  ⚠️ SocialEngine: $e');
    }
    _setEngineStatus('transformer', AgentStatus.online);
    debugPrint('  ✅ SamuraiContentTransformer ONLINE');

    // Phase 4: Content Rotation
    debugPrint('⚔️ [SWARM] Phase 4: Starting Content Rotation...');
    _setEngineStatus('rotation', AgentStatus.booting);
    try {
      _rotation.start();
      _setEngineStatus('rotation', AgentStatus.online);
      debugPrint('  ✅ ContentRotation ONLINE (6h auto-swap active)');
    } catch (e) {
      _setEngineStatus('rotation', AgentStatus.error);
      debugPrint('  ⚠️ Rotation: $e');
    }

    // Phase 5: Intelligence Engines
    debugPrint('⚔️ [SWARM] Phase 5: Booting Intelligence Layer...');
    try {
      _setEngineStatus('combat_intel', AgentStatus.online);
      _setEngineStatus('health_intel', AgentStatus.online);
      _setEngineStatus('quantum', AgentStatus.online);
      _setEngineStatus('nexus', AgentStatus.online);
      _setEngineStatus('sports_sci', AgentStatus.online);
      debugPrint(
        '  ✅ CombatIntel + HealthIntel + Quantum + Nexus + SportsSci ONLINE',
      );
    } catch (e) {
      debugPrint('  ⚠️ Intelligence layer: $e');
    }

    // Phase 5B: TRIBE v2 Brain Encoder (Meta AI Open-Source)
    debugPrint('⚔️ [SWARM] Phase 5B: Booting TRIBE v2 Brain Encoder...');
    try {
      await _tribeBrain.initialize();
      _setEngineStatus('tribe_brain', AgentStatus.online);
      _updateAgent('tribe_brain_encoder', status: AgentStatus.online);
      debugPrint(
        '  ✅ TRIBE v2 Brain Encoder ONLINE (trimodal: sight+sound+language)',
      );
    } catch (e) {
      _setEngineStatus('tribe_brain', AgentStatus.error);
      debugPrint('  ⚠️ TRIBE v2 Brain Encoder: $e');
    }

    // Phase 6: Revenue Engines
    debugPrint('⚔️ [SWARM] Phase 6: Booting Revenue Layer...');
    try {
      _setEngineStatus('sponsor_feed', AgentStatus.online);
      _setEngineStatus('metaverse_ads', AgentStatus.online);
      debugPrint('  ✅ SponsorFeed + MetaverseAds ONLINE');
    } catch (e) {
      debugPrint('  ⚠️ Revenue layer: $e');
    }

    // Mark all scanner & promo bots online
    _activateAllBots();

    _initialized = true;
    _swarmActive = true;

    // Start the heartbeat — swarm pulse every 2 minutes
    _heartbeat = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _swarmPulse(),
    );

    // Start the content pump — generates new content every 6 hours
    _contentPump = Timer.periodic(
      const Duration(hours: 6),
      (_) => _pumpContent(),
    );

    // Initial content pump
    await _pumpContent();

    // Take first health snapshot
    _takeHealthSnapshot();

    // Broadcast swarm-online message
    _broadcastMessage(
      fromAgent: 'swarm_coordinator',
      type: 'SWARM_ONLINE',
      payload:
          '53 agents booted · All engines active · Swarm intelligence engaged',
      priority: SwarmPriority.critical,
    );

    final bootDuration = DateTime.now().difference(_bootTime!);
    debugPrint('');
    debugPrint(
      '⚔️══════════════════════════════════════════════════════════⚔️',
    );
    debugPrint(
      '⚔️  SWARM FULLY ONLINE — $onlineAgents/$totalAgents agents active',
    );
    debugPrint('⚔️  Boot time: ${bootDuration.inMilliseconds}ms');
    debugPrint('⚔️  Content pump: ACTIVE (3-min cycles)');
    debugPrint('⚔️  Heartbeat: ACTIVE (2-min pulse)');
    debugPrint(
      '⚔️══════════════════════════════════════════════════════════⚔️',
    );
    debugPrint('');

    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AGENT REGISTRY — All 53 agents catalogued
  // ═══════════════════════════════════════════════════════════════════════════

  void _registerAllAgents() {
    _agents.clear();

    // ── 38 Scanner Bots ──────────────────────────────────────────────────
    final scannerNames = [
      ['meta_scanner', 'Meta Scanner', '📘', 'Facebook monitoring'],
      [
        'instagram_crawler',
        'Instagram Crawler',
        '📸',
        'Instagram feed scanning',
      ],
      ['tiktok_tracker', 'TikTok Tracker', '🎵', 'TikTok fight content'],
      ['youtube_monitor', 'YouTube Monitor', '▶️', 'YouTube fight videos'],
      ['twitter_wire', 'Twitter/X Wire', '🐦', 'Real-time X/Twitter feed'],
      ['reddit_scanner', 'Reddit Scanner', '🤖', 'Reddit MMA communities'],
      ['mma_news_wire', 'MMA News Wire', '📰', 'MMA news aggregation'],
      ['boxing_news_wire', 'Boxing News Wire', '🥊', 'Boxing headlines'],
      ['espn_fight_desk', 'ESPN Fight Desk', '📺', 'ESPN fight coverage'],
      ['fight_blog_crawler', 'Fight Blog Crawler', '📝', 'Blog content'],
      ['podcast_tracker', 'Podcast Tracker', '🎙️', 'Fight podcast monitoring'],
      ['event_calendar_bot', 'Event Calendar Bot', '📅', 'Event scheduling'],
      ['promotion_wire', 'Promotion Wire', '📣', 'Promotion alerts'],
      [
        'snapchat_stories',
        'Snapchat Stories Scanner',
        '👻',
        'Snapchat monitoring',
      ],
      ['twitch_streams', 'Twitch Fight Streams', '🟣', 'Live stream detection'],
      [
        'discord_communities',
        'Discord Fight Communities',
        '💬',
        'Discord monitoring',
      ],
      ['telegram_channels', 'Telegram Fight Channels', '✈️', 'Telegram intel'],
      ['wechat_groups', 'WeChat Fight Groups', '🟢', 'WeChat monitoring'],
      ['douyin_content', 'Douyin Fight Content', '🎭', 'Chinese TikTok'],
      [
        'bilibili_videos',
        'Bilibili Combat Videos',
        '📹',
        'Bilibili monitoring',
      ],
      ['line_updates', 'LINE Fight Updates', '💚', 'LINE platform'],
      ['kakao_content', 'Kakao Fight Content', '💛', 'Kakao monitoring'],
      ['niconico_channel', 'Niconico Fight Channel', '🎌', 'JP video platform'],
      ['pixiv_art', 'Pixiv MMA Art', '🎨', 'Combat art discovery'],
      [
        'fiverr_content',
        'Fiverr Training Content',
        '💼',
        'Freelance combat content',
      ],
      [
        'airtasker_services',
        'AirTasker Fight Services',
        '🇦🇺',
        'AU fight services',
      ],
      [
        'upwork_pros',
        'Upwork Combat Professionals',
        '🌐',
        'Pro combat services',
      ],
      ['medium_blogs', 'Medium Fight Blogs', '✍️', 'Medium article scanning'],
      ['spotify_podcasts', 'Spotify MMA Podcasts', '🎧', 'Podcast discovery'],
      [
        'ai_generated',
        'AI Generated Fight Content',
        '🤖',
        'AI content detection',
      ],
      [
        'web3_communities',
        'Web3 Fight Communities',
        '⛓️',
        'Web3 fight culture',
      ],
      ['roblox_games', 'Roblox Fight Games', '🏗️', 'Roblox metaverse'],
      ['fortnite_events', 'Fortnite Combat Events', '🎮', 'Fortnite metaverse'],
      [
        'decentraland_hub',
        'Decentraland Fight Hub',
        '🌍',
        'Decentraland metaverse',
      ],
      ['sandbox_verse', 'The Sandbox Metaverse', '⬛', 'Sandbox metaverse'],
      ['horizon_worlds', 'Horizon Worlds VR Arena', '🥽', 'VR fight arena'],
      [
        'premium_feed',
        'Premium Verified Feed',
        '💎',
        'Premium content curation',
      ],
      [
        'partner_network',
        'Partner Network Integration',
        '🤝',
        'Partner content sync',
      ],
    ];
    for (final bot in scannerNames) {
      _agents.add(
        SwarmAgent(
          id: 'scanner_${bot[0]}',
          name: bot[1],
          emoji: bot[2],
          engineName: 'ContentScannerEngine',
          role: bot[3],
        ),
      );
    }

    // ── 8 Promo Bots ─────────────────────────────────────────────────────
    final promoNames = [
      ['hype_bot', 'HypeBot', '🔥', 'Hype post generation'],
      ['spotlight_bot', 'SpotlightBot', '⭐', 'Fighter spotlight features'],
      ['matchmaker_bot', 'MatchmakerBot', '🥊', 'Dream matchup creation'],
      ['trend_bot', 'TrendBot', '📈', 'Trending topic surfacing'],
      ['campaign_bot', 'CampaignBot', '📣', 'Campaign post creation'],
      ['event_bot', 'EventBot', '⏱️', 'Event countdown & hype'],
      ['viral_bot', 'ViralBot', '🚀', 'Viral content snippets'],
      ['analytics_bot', 'AnalyticsBot', '📊', 'Stats & analytics graphics'],
    ];
    for (final bot in promoNames) {
      _agents.add(
        SwarmAgent(
          id: 'promo_${bot[0]}',
          name: bot[1],
          emoji: bot[2],
          engineName: 'PromoterAIService',
          role: bot[3],
        ),
      );
    }

    // ── 7 SamurAI Personas ───────────────────────────────────────────────
    final personas = [
      ['shido', 'Samurai Shido', '⚔️', 'Heart/Soul/Brain of DFC'],
      ['posterboy', 'PosterBoy', '🎨', 'Creative chaos engine'],
      ['general', 'SamurAI General', '🧠', 'Unified intelligence'],
    ];
    for (final p in personas) {
      _agents.add(
        SwarmAgent(
          id: 'persona_${p[0]}',
          name: p[1],
          emoji: p[2],
          engineName: 'SamuraiOrchestrator',
          role: p[3],
        ),
      );
    }

    // ── TRIBE v2 Brain Encoder Agent (Meta AI Open-Source) ───────────────
    _agents.add(
      const SwarmAgent(
        id: 'tribe_brain_encoder',
        name: 'TRIBE v2 Brain Encoder',
        emoji: '🧠',
        engineName: 'TribeBrainEncoderService',
        role: 'Trimodal brain activity prediction (sight+sound+language)',
      ),
    );

    debugPrint('⚔️ [SWARM] Registered ${_agents.length} agents');
  }

  void _activateAllBots() {
    for (int i = 0; i < _agents.length; i++) {
      _agents[i] = _agents[i].copyWith(
        status: AgentStatus.online,
        lastActive: DateTime.now(),
        performanceScore: 0.85 + _rng.nextDouble() * 0.15,
      );
    }
  }

  void _setEngineStatus(String engineKey, AgentStatus status) {
    // Update all agents belonging to this engine
    for (int i = 0; i < _agents.length; i++) {
      final agent = _agents[i];
      if (agent.id.startsWith(engineKey) ||
          agent.engineName.toLowerCase().contains(
            engineKey.replaceAll('_', ''),
          )) {
        _agents[i] = agent.copyWith(status: status, lastActive: DateTime.now());
      }
    }
  }

  void _updateAgent(String agentId, {AgentStatus? status, int? contentDelta}) {
    for (int i = 0; i < _agents.length; i++) {
      if (_agents[i].id == agentId) {
        _agents[i] = _agents[i].copyWith(
          status: status ?? _agents[i].status,
          lastActive: DateTime.now(),
          contentGenerated: _agents[i].contentGenerated + (contentDelta ?? 0),
        );
        break;
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SWARM MESSAGE BUS — Inter-agent communication
  // ═══════════════════════════════════════════════════════════════════════════

  void _broadcastMessage({
    required String fromAgent,
    required String type,
    required String payload,
    SwarmPriority priority = SwarmPriority.normal,
  }) {
    final msg = SwarmMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(9999)}',
      fromAgent: fromAgent,
      toAgent: '*',
      type: type,
      payload: payload,
      priority: priority,
      timestamp: DateTime.now(),
    );
    _messageBus.insert(0, msg);
    if (_messageBus.length > 500) {
      _messageBus.removeRange(500, _messageBus.length);
    }
    _messagesProcessed++;
  }

  void _sendMessage({
    required String from,
    required String to,
    required String type,
    required String payload,
  }) {
    final msg = SwarmMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(9999)}',
      fromAgent: from,
      toAgent: to,
      type: type,
      payload: payload,
      timestamp: DateTime.now(),
    );
    _messageBus.insert(0, msg);
    if (_messageBus.length > 500) {
      _messageBus.removeRange(500, _messageBus.length);
    }
    _messagesProcessed++;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SWARM PULSE — Heartbeat every 2 minutes
  // ═══════════════════════════════════════════════════════════════════════════

  void _swarmPulse() {
    _cycleCount++;
    debugPrint(
      '⚔️ [SWARM] Pulse #$_cycleCount — $onlineAgents/$totalAgents agents online',
    );

    // Simulate bot activity - each online bot has a chance to discover content
    for (int i = 0; i < _agents.length; i++) {
      final agent = _agents[i];
      if (agent.status == AgentStatus.online) {
        // Simulate performance fluctuation
        final newPerf =
            (agent.performanceScore + (_rng.nextDouble() * 0.1 - 0.05)).clamp(
              0.5,
              1.0,
            );
        _agents[i] = agent.copyWith(
          lastActive: DateTime.now(),
          performanceScore: newPerf,
        );
      }
    }

    // Cross-engine intelligence sharing
    _crossFeedIntelligence();

    // Take health snapshot
    _takeHealthSnapshot();

    _broadcastMessage(
      fromAgent: 'swarm_coordinator',
      type: 'HEARTBEAT',
      payload:
          'Cycle $_cycleCount · $onlineAgents agents · $_totalContentGenerated content items',
    );

    notifyListeners();
  }

  void _crossFeedIntelligence() {
    // Scanner trending → Promoter
    _sendMessage(
      from: 'scanner_engine',
      to: 'promoter_engine',
      type: 'TRENDING_UPDATE',
      payload: 'Scanner trending topics fed to PromoterAI for hype generation',
    );

    // ESO wellness → Core Engine health pillar
    _sendMessage(
      from: 'eso_engine',
      to: 'samurai_core',
      type: 'WELLNESS_UPDATE',
      payload: 'ESO wellness metrics updated for health pillar scoring',
    );

    // Promoter performance → Scanner tuning
    _sendMessage(
      from: 'promoter_engine',
      to: 'scanner_engine',
      type: 'PERFORMANCE_FEEDBACK',
      payload:
          'Top-performing content types fed back for scanner priority tuning',
    );

    // Nexus wisdom → Transformer style guide
    _sendMessage(
      from: 'nexus',
      to: 'transformer',
      type: 'STYLE_GUIDE',
      payload: 'Nexus social intelligence updating transformer content style',
    );

    // Combat intel → Promoter matchups
    _sendMessage(
      from: 'combat_intel',
      to: 'promo_matchmaker_bot',
      type: 'FIGHTER_DATA',
      payload: 'Updated fighter profiles for dream matchup generation',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTENT PUMP — Auto-generates content for all pages every 6 hours
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _pumpContent() async {
    debugPrint('⚔️ [SWARM] Content pump firing...');
    int generated = 0;

    try {
      final ramp = await _resolveHypeRamp();
      _currentHypePhase = ramp.phase;
      _currentPromoBursts = ramp.promoBursts;

      // 1. Generate news articles
      generated += await _generateNewsContent();

      // 2. Generate social feed posts
      generated += await _generateSocialContent();

      // 3. Generate event content
      generated += await _generateEventContent();

      // 4. Generate promo/hype content
      generated += await _generatePromoContent(
        burstCount: ramp.promoBursts,
        phaseTag: ramp.phase,
      );

      // 5. Generate training/wellness content
      generated += await _generateTrainingContent();

      // 6. Generate story highlights
      generated += await _generateStoryHighlights();

      // 7. Generate metaverse content
      generated += await _generateMetaverseContent();

      // 8. Generate drone racing content
      generated += await _generateDroneRacingContent();

      _totalContentGenerated += generated;

      // Update random agents with content generated
      for (int i = 0; i < math.min(generated, _agents.length); i++) {
        final idx = _rng.nextInt(_agents.length);
        _agents[idx] = _agents[idx].copyWith(
          contentGenerated: _agents[idx].contentGenerated + 1,
          lastActive: DateTime.now(),
        );
      }

      _broadcastMessage(
        fromAgent: 'content_pump',
        type: 'CONTENT_GENERATED',
        payload:
            '$generated new items pumped · phase=${ramp.phase} · bursts=${ramp.promoBursts} · Total: $_totalContentGenerated',
        priority: SwarmPriority.high,
      );

      debugPrint(
        '⚔️ [SWARM] Pumped $generated items · phase=${ramp.phase} · bursts=${ramp.promoBursts} (total: $_totalContentGenerated)',
      );
    } catch (e) {
      debugPrint('⚔️ [SWARM] Content pump error: $e');
    }

    notifyListeners();
  }

  // ── Content Generators ─────────────────────────────────────────────────

  Future<int> _generateNewsContent() async {
    final now = DateTime.now();
    final articles = <SwarmContent>[
      SwarmContent(
        id: 'news_${now.millisecondsSinceEpoch}_1',
        type: 'news',
        title: _pickRandom(_newsHeadlines),
        body: _pickRandom(_newsBody),
        source: 'MMA News Wire',
        category: 'breaking',
        tags: ['UFC', 'MMA', 'Boxing', 'Breaking'],
        createdAt: now,
        hypeScore: 0.7 + _rng.nextDouble() * 0.3,
      ),
      SwarmContent(
        id: 'news_${now.millisecondsSinceEpoch}_2',
        type: 'news',
        title: _pickRandom(_boxingHeadlines),
        body: _pickRandom(_newsBody),
        source: 'Boxing News Wire',
        category: 'featured',
        tags: ['Boxing', 'World Title', 'Fight Night'],
        createdAt: now.subtract(const Duration(minutes: 15)),
        hypeScore: 0.6 + _rng.nextDouble() * 0.4,
      ),
    ];

    for (final article in articles) {
      _contentQueue.add(article);
      await _writeToFirestore('swarm_content', article);
    }
    return articles.length;
  }

  Future<int> _generateSocialContent() async {
    final now = DateTime.now();
    final posts = <SwarmContent>[
      SwarmContent(
        id: 'social_${now.millisecondsSinceEpoch}_1',
        type: 'post',
        title: _pickRandom(_socialTitles),
        body: _pickRandom(_socialBodies),
        source: 'HypeBot',
        category: 'social',
        tags: ['DFC', 'CombatSports', 'FightLife'],
        createdAt: now,
        hypeScore: 0.8 + _rng.nextDouble() * 0.2,
      ),
      SwarmContent(
        id: 'social_${now.millisecondsSinceEpoch}_2',
        type: 'post',
        title: _pickRandom(_spotlightTitles),
        body: _pickRandom(_spotlightBodies),
        source: 'SpotlightBot',
        category: 'spotlight',
        tags: ['FighterSpotlight', 'DFC', 'Champion'],
        createdAt: now.subtract(const Duration(minutes: 5)),
        hypeScore: 0.7 + _rng.nextDouble() * 0.3,
      ),
    ];

    for (final post in posts) {
      _contentQueue.add(post);
      await _writeToFirestore('swarm_content', post);
    }

    // Also write to posts collection for social feed
    try {
      final imageUrl = _generatedImageForType('post');
      await _firestore.collection('posts').add({
        'userId': 'dfc_swarm',
        'userName': 'DFC Official',
        'content': '${posts.first.title}\n\n${posts.first.body}',
        'imageUrl': imageUrl,
        'mediaUrls': [imageUrl],
        'thumbnailUrl': imageUrl,
        'likes': _rng.nextInt(50) + 10,
        'comments': _rng.nextInt(20) + 3,
        'shares': _rng.nextInt(15) + 1,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'swarm_generated',
        'tags': posts.first.tags,
      });
    } catch (e) {
      debugPrint('⚔️ [SWARM] Social feed write: $e');
    }

    return posts.length;
  }

  Future<int> _generateEventContent() async {
    final now = DateTime.now();
    final dayOffset = _rng.nextInt(30) + 1;
    final events = <SwarmContent>[
      SwarmContent(
        id: 'event_${now.millisecondsSinceEpoch}_1',
        type: 'event',
        title: _pickRandom(_eventTitles),
        body: _pickRandom(_eventDescriptions),
        source: 'EventBot',
        category: 'upcoming',
        tags: ['Event', 'FightNight', 'Live'],
        createdAt: now,
        hypeScore: 0.9,
        metadata: {
          'eventDate': now.add(Duration(days: dayOffset)).toIso8601String(),
          'venue': _pickRandom(_venues),
          'promotion': _pickRandom(_promotions),
        },
      ),
    ];

    for (final event in events) {
      _contentQueue.add(event);
      await _writeToFirestore('swarm_content', event);
    }

    // Also write to events collection
    try {
      final eventData = events.first;
      final imageUrl = _generatedImageForType('event');
      await _firestore.collection('events').add({
        'title': eventData.title,
        'description': eventData.body,
        'date': Timestamp.fromDate(now.add(Duration(days: dayOffset))),
        'venue': eventData.metadata['venue'],
        'promotion': eventData.metadata['promotion'],
        'imageUrl': imageUrl,
        'mediaUrls': [imageUrl],
        'thumbnailUrl': imageUrl,
        'type': 'fight_night',
        'status': 'upcoming',
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'swarm_generated',
      });
    } catch (e) {
      debugPrint('⚔️ [SWARM] Events write: $e');
    }

    return events.length;
  }

  Future<int> _generatePromoContent({
    int burstCount = 1,
    String phaseTag = 'baseline',
  }) async {
    final now = DateTime.now();
    final safeBursts = burstCount.clamp(1, 8);
    final promos = <SwarmContent>[];

    for (int i = 0; i < safeBursts; i++) {
      promos.add(
        SwarmContent(
          id: 'promo_${now.millisecondsSinceEpoch}_${i}_campaign',
          type: 'promo',
          title: _pickRandom(_promoTitles),
          body: _pickRandom(_promoBodies),
          source: 'CampaignBot',
          category: 'campaign',
          tags: ['DFC', 'Promo', 'FightHype', phaseTag],
          createdAt: now,
          hypeScore: 0.9 + _rng.nextDouble() * 0.1,
          metadata: {
            'hypePhase': phaseTag,
            'burstIndex': i,
            'burstCount': safeBursts,
          },
        ),
      );

      promos.add(
        SwarmContent(
          id: 'promo_${now.millisecondsSinceEpoch}_${i}_viral',
          type: 'promo',
          title: _pickRandom(_viralSnippets),
          body: '',
          source: 'ViralBot',
          category: 'viral',
          tags: ['Viral', 'DFC', 'MustWatch', phaseTag],
          createdAt: now,
          hypeScore: 0.95 + _rng.nextDouble() * 0.05,
          metadata: {
            'hypePhase': phaseTag,
            'burstIndex': i,
            'burstCount': safeBursts,
          },
        ),
      );
    }

    for (final promo in promos) {
      _contentQueue.add(promo);
      await _writeToFirestore('swarm_content', promo);
    }
    return promos.length;
  }

  Future<_HypeRampConfig> _resolveHypeRamp() async {
    try {
      final now = DateTime.now();
      final snap = await _firestore
          .collection('events')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('date')
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        return const _HypeRampConfig(phase: 'month_out', promoBursts: 1);
      }

      final data = snap.docs.first.data();
      final ts = data['date'] as Timestamp?;
      if (ts == null) {
        return const _HypeRampConfig(phase: 'month_out', promoBursts: 1);
      }

      final eventDate = ts.toDate();
      final diff = eventDate.difference(now);
      final daysOut = diff.inHours / 24.0;

      if (daysOut > 21) {
        return const _HypeRampConfig(phase: 'month_out', promoBursts: 1);
      }
      if (daysOut > 14) {
        return const _HypeRampConfig(phase: 'three_weeks_out', promoBursts: 2);
      }
      if (daysOut > 7) {
        return const _HypeRampConfig(phase: 'two_weeks_out', promoBursts: 3);
      }
      if (daysOut > 2) {
        return const _HypeRampConfig(phase: 'one_week_out', promoBursts: 4);
      }
      if (daysOut > 0.25) {
        return const _HypeRampConfig(phase: 'days_out', promoBursts: 5);
      }
      if (daysOut > 0) {
        return const _HypeRampConfig(phase: 'hours_out', promoBursts: 6);
      }
      return const _HypeRampConfig(phase: 'fight_time', promoBursts: 8);
    } catch (e) {
      debugPrint('⚔️ [SWARM] Hype ramp fallback: $e');
      return const _HypeRampConfig(phase: 'month_out', promoBursts: 1);
    }
  }

  Future<int> _generateTrainingContent() async {
    final now = DateTime.now();
    final content = <SwarmContent>[
      SwarmContent(
        id: 'training_${now.millisecondsSinceEpoch}_1',
        type: 'training',
        title: _pickRandom(_trainingTitles),
        body: _pickRandom(_trainingBodies),
        source: 'Samurai Shido',
        category: 'wellness',
        tags: ['Training', 'Fitness', 'Recovery', 'MMA'],
        createdAt: now,
        hypeScore: 0.6 + _rng.nextDouble() * 0.3,
      ),
    ];

    for (final item in content) {
      _contentQueue.add(item);
      await _writeToFirestore('swarm_content', item);
    }
    return content.length;
  }

  Future<int> _generateStoryHighlights() async {
    // Only generate stories occasionally (1 in 3 cycles)
    if (_rng.nextInt(3) != 0) return 0;

    final now = DateTime.now();
    final story = SwarmContent(
      id: 'story_${now.millisecondsSinceEpoch}',
      type: 'story',
      title: _pickRandom(_storyTitles),
      body: _pickRandom(_storyBodies),
      source: 'ContentRotation',
      category: 'highlight',
      tags: ['Story', 'DFC', 'Highlight'],
      createdAt: now,
      hypeScore: 0.85,
    );

    _contentQueue.add(story);
    await _writeToFirestore('swarm_content', story);

    // Write to stories collection
    try {
      await _firestore.collection('stories').add({
        'name': story.title.length > 12
            ? story.title.substring(0, 12)
            : story.title,
        'color': '#00E5FF',
        'badge': '⚔️',
        'order': 10 + _rng.nextInt(20),
        'body': story.body,
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'swarm_generated',
      });
    } catch (e) {
      debugPrint('⚔️ [SWARM] Stories write: $e');
    }

    return 1;
  }

  Future<int> _generateMetaverseContent() async {
    // Metaverse content less frequent (1 in 4 cycles)
    if (_rng.nextInt(4) != 0) return 0;

    final now = DateTime.now();
    final metaContent = SwarmContent(
      id: 'meta_${now.millisecondsSinceEpoch}',
      type: 'metaverse',
      title: _pickRandom(_metaverseTitles),
      body: _pickRandom(_metaverseBodies),
      source: 'MetaverseAdCampaignEngine',
      category: 'metaverse',
      tags: ['Metaverse', 'VR', 'AR', 'Web3', 'DFC'],
      createdAt: now,
      hypeScore: 0.9,
      metadata: {
        'platform': _pickRandom([
          'Roblox',
          'Fortnite',
          'Decentraland',
          'The Sandbox',
          'Horizon Worlds',
        ]),
        'type': _pickRandom([
          'arena',
          'avatar',
          'event',
          'collectible',
          'tournament',
        ]),
      },
    );

    _contentQueue.add(metaContent);
    await _writeToFirestore('swarm_content', metaContent);
    return 1;
  }

  Future<int> _generateDroneRacingContent() async {
    // Drone racing runs in controlled cadence (roughly half the cycles)
    if (_rng.nextInt(2) != 0) return 0;

    final now = DateTime.now();
    final drone = SwarmContent(
      id: 'drone_${now.millisecondsSinceEpoch}',
      type: 'drone_racing',
      title: _pickRandom(_droneRacingTitles),
      body: _pickRandom(_droneRacingBodies),
      source: 'DroneRacingBot',
      category: 'drone_racing',
      tags: ['DroneRacing', 'DFCSkyTrack', 'FPV', 'Speed', 'DFC'],
      createdAt: now,
      hypeScore: 0.88 + _rng.nextDouble() * 0.12,
      metadata: {
        'league': _pickRandom([
          'DFC SkyTrack League',
          'FPV Pro Circuit',
          'Street Drone Cup',
        ]),
        'trackType': _pickRandom(['indoor', 'night', 'urban', 'arena']),
      },
    );

    _contentQueue.add(drone);
    await _writeToFirestore('swarm_content', drone);

    try {
      final imageUrl = _generatedImageForType('drone_racing');
      await _firestore.collection('posts').add({
        'userId': 'dfc_drone',
        'userName': 'DFC Drone Racing',
        'content': '${drone.title}\n\n${drone.body}',
        'imageUrl': imageUrl,
        'mediaUrls': [imageUrl],
        'thumbnailUrl': imageUrl,
        'likes': _rng.nextInt(70) + 20,
        'comments': _rng.nextInt(25) + 5,
        'shares': _rng.nextInt(20) + 3,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'drone_racing',
        'tags': drone.tags,
      });
    } catch (e) {
      debugPrint('⚔️ [SWARM] Drone feed write: $e');
    }

    return 1;
  }

  Future<void> _writeToFirestore(
    String collection,
    SwarmContent content,
  ) async {
    try {
      await _firestore
          .collection(collection)
          .doc(content.id)
          .set(content.toFirestore());
    } catch (e) {
      debugPrint('⚔️ [SWARM] Firestore write error ($collection): $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEALTH SNAPSHOT
  // ═══════════════════════════════════════════════════════════════════════════

  void _takeHealthSnapshot() {
    final online = onlineAgents;
    final efficiency = totalAgents > 0 ? online / totalAgents : 0.0;
    final uptime = _bootTime != null
        ? DateTime.now().difference(_bootTime!).inMinutes
        : 0;
    final velocity = uptime > 0 ? _totalContentGenerated / uptime : 0.0;

    final engineMap = <String, AgentStatus>{
      'DFCAIPowerhouse': _engineStatusFor('ContentScannerEngine'),
      'SamuraiCoreEngine': _engineStatusFor('SamuraiOrchestrator'),
      'ContentTransformer': AgentStatus.online,
      'SocialEngine': AgentStatus.online,
      'ContentRotation': AgentStatus.online,
      'CombatIntelligence': AgentStatus.online,
      'HealthIntelligence': AgentStatus.online,
      'QuantumOptimization': AgentStatus.online,
      'DfcNexus': AgentStatus.online,
      'SportsScienceEngine': AgentStatus.online,
      'SponsorFeed': AgentStatus.online,
      'MetaverseAds': AgentStatus.online,
    };

    String mood;
    if (efficiency >= 0.95) {
      mood = '🔥 UNSTOPPABLE — Swarm at peak performance';
    } else if (efficiency >= 0.8) {
      mood = '⚔️ BATTLE READY — Swarm operating strong';
    } else if (efficiency >= 0.6) {
      mood = '⚡ WARMING UP — Most agents online';
    } else {
      mood = '🔧 MAINTENANCE — Some agents need attention';
    }

    _latestHealth = SwarmHealthSnapshot(
      timestamp: DateTime.now(),
      totalAgents: totalAgents,
      onlineAgents: online,
      contentGeneratedThisCycle: _contentQueue.length,
      totalContentGenerated: _totalContentGenerated,
      messagesProcessed: _messagesProcessed,
      swarmEfficiency: efficiency,
      contentVelocity: velocity,
      engineStatus: engineMap,
      recentMessages: _messageBus.take(10).toList(),
      swarmMood: mood,
    );
  }

  AgentStatus _engineStatusFor(String engineName) {
    final agents = _agents.where((a) => a.engineName == engineName);
    if (agents.isEmpty) return AgentStatus.offline;
    final onlineCount = agents
        .where((a) => a.status == AgentStatus.online)
        .length;
    if (onlineCount == agents.length) return AgentStatus.online;
    if (onlineCount > 0) return AgentStatus.booting;
    return AgentStatus.offline;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MANUAL COMMANDS — Admin controls
  // ═══════════════════════════════════════════════════════════════════════════

  /// Force a content pump cycle now
  Future<void> forcePump() async {
    debugPrint('⚔️ [SWARM] Admin force-pump triggered');
    await _pumpContent();
  }

  /// Force all content to all social platforms
  Future<void> fireAll() async {
    debugPrint('⚔️ [SWARM] FIRE ALL — Publishing to all platforms');
    _broadcastMessage(
      fromAgent: 'admin',
      type: 'FIRE_ALL',
      payload: 'Admin triggered mass publish to all platforms',
      priority: SwarmPriority.critical,
    );

    // Create promo blast content
    final headline = _pickRandom(_promoTitles);
    final desc = _pickRandom(_promoBodies);
    await _socialEngine.firePromoBlast(headline: headline, description: desc);
    notifyListeners();
  }

  /// Seed a massive batch of initial content for all pages
  Future<int> seedAllPages() async {
    debugPrint('⚔️ [SWARM] MEGA SEED — Filling all pages with content');
    _broadcastMessage(
      fromAgent: 'admin',
      type: 'MEGA_SEED',
      payload: 'Admin triggered mega seed for all pages',
      priority: SwarmPriority.critical,
    );

    int total = 0;

    // Run 10 pump cycles to fill content
    for (int i = 0; i < 10; i++) {
      total += await _generateNewsContent();
      total += await _generateSocialContent();
      total += await _generateEventContent();
      total += await _generatePromoContent();
      total += await _generateTrainingContent();
      total += await _generateStoryHighlights();
      total += await _generateMetaverseContent();
    }

    // Seed additional news articles to the news collection
    total += await _seedNewsCollection();

    // Seed additional fight_news articles
    total += await _seedFightNewsCollection();

    _totalContentGenerated += total;

    _broadcastMessage(
      fromAgent: 'admin',
      type: 'MEGA_SEED_COMPLETE',
      payload: 'Seeded $total content items across all pages',
      priority: SwarmPriority.critical,
    );

    _takeHealthSnapshot();
    notifyListeners();
    return total;
  }

  Future<int> _seedNewsCollection() async {
    int count = 0;
    final batch = _firestore.batch();
    final ref = _firestore.collection('news');

    for (final headline in _newsHeadlines) {
      final doc = ref.doc();
      final imageUrl = _generatedImageForType('news');
      batch.set(doc, {
        'title': headline,
        'body': _pickRandom(_newsBody),
        'category': _pickRandom([
          'mma',
          'boxing',
          'muay_thai',
          'kickboxing',
          'wrestling',
        ]),
        'source': _pickRandom([
          'ESPN MMA',
          'Boxing Scene',
          'MMA Fighting',
          'Sherdog',
          'DFC News Desk',
        ]),
        'imageUrl': imageUrl,
        'mediaUrls': [imageUrl],
        'thumbnailUrl': imageUrl,
        'isBreaking': _rng.nextBool(),
        'isFeatured': _rng.nextBool(),
        'views': _rng.nextInt(5000) + 100,
        'timestamp': Timestamp.fromDate(
          DateTime.now().subtract(Duration(hours: _rng.nextInt(72))),
        ),
        'createdAt': FieldValue.serverTimestamp(),
        'generatedBy': 'samurai_swarm',
      });
      count++;
    }

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('⚔️ [SWARM] News seed error: $e');
    }
    return count;
  }

  Future<int> _seedFightNewsCollection() async {
    int count = 0;
    final batch = _firestore.batch();
    final ref = _firestore.collection('fight_news');

    for (final headline in [..._boxingHeadlines, ..._newsHeadlines.take(5)]) {
      final doc = ref.doc();
      final imageUrl = _generatedImageForType('fight_news');
      batch.set(doc, {
        'title': headline,
        'summary': _pickRandom(_newsBody),
        'fullContent': '${_pickRandom(_newsBody)}\n\n${_pickRandom(_newsBody)}',
        'category': _pickRandom([
          'UFC',
          'Boxing',
          'ONE Championship',
          'Bellator',
          'PFL',
          'BKFC',
        ]),
        'source': _pickRandom([
          'ESPN',
          'MMA Fighting',
          'Boxing Scene',
          'Sherdog',
          'DFC',
        ]),
        'imageUrl': imageUrl,
        'mediaUrls': [imageUrl],
        'thumbnailUrl': imageUrl,
        'isBreaking': _rng.nextBool(),
        'isFeatured': count < 3,
        'publishedAt': Timestamp.fromDate(
          DateTime.now().subtract(Duration(hours: _rng.nextInt(48))),
        ),
        'createdAt': FieldValue.serverTimestamp(),
        'generatedBy': 'samurai_swarm',
        'tags': [
          _pickRandom(['UFC', 'Boxing', 'MuayThai', 'MMA', 'Kickboxing']),
          'DFC',
        ],
      });
      count++;
    }

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('⚔️ [SWARM] Fight news seed error: $e');
    }
    return count;
  }

  /// Stop the swarm
  void shutdown() {
    _heartbeat?.cancel();
    _contentPump?.cancel();
    _swarmActive = false;
    _broadcastMessage(
      fromAgent: 'swarm_coordinator',
      type: 'SWARM_SHUTDOWN',
      payload: 'Swarm shutting down gracefully',
      priority: SwarmPriority.critical,
    );
    for (int i = 0; i < _agents.length; i++) {
      _agents[i] = _agents[i].copyWith(status: AgentStatus.dormant);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    _contentPump?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTENT BANKS — Real fight content for swarm generation
  // ═══════════════════════════════════════════════════════════════════════════

  String _pickRandom(List<String> items) => items[_rng.nextInt(items.length)];

  static const _newsHeadlines = [
    'UFC 310 Main Event Shakeup: New Challenger Steps In',
    'Boxing World Reacts to Shocking Upset at MSG',
    'ONE Championship Expands Into Australia With Melbourne Card',
    'Bellator Champion Calls Out UFC Rival in Fiery Press Conference',
    'BKFC 55: Bare-Knuckle Title Fight Set for Perth Showdown',
    'PFL Season Finals: Million-Dollar Fights Announced',
    'Hex Fight Series Returns With Stacked Brisbane Card',
    'Rising Star Scores Viral KO of the Year Contender',
    'Former Champion Announces Retirement After 15-Year Career',
    'DFC Exclusive: Behind the Scenes at Tiger Muay Thai',
    'Australia\'s Next MMA Superstar Breaks Through at AFC',
    'Glory Kickboxing Grand Prix Draw Revealed',
    'Lumpinee Stadium Hosts Historic Muay Thai Super Fight',
    'K-1 World Grand Prix Returns With 8-Man Tournament',
    'Cage Warriors Signs TV Deal for Australian Coverage',
    'Fight Night Preview: Top 5 Bouts You Can\'t Miss This Weekend',
    'Training Camp Secrets: What Champions Do Differently',
    'Medical Study Reveals New Concussion Protocol for Combat Sports',
    'Weight Cutting Debate Reignited After Fighter Hospitalization',
    'DFC Analytics: The Stats Behind Last Night\'s Main Event',
    'IBC III — International Brawling Championship Hits Gold Coast March 7',
    'IBC Countdown: Not Long Until the Wood Gets Chopped at Gold Coast Sports & Leisure Centre',
  ];

  static const _boxingHeadlines = [
    'Undisputed Title Fight Officially Announced for December',
    'Olympic Gold Medalist Signs With Top Promotional Company',
    'Ring Magazine Releases Updated P4P Rankings',
    'Boxing Legend Launches Youth Academy in Western Sydney',
    'WBC Orders Mandatory Title Defense Within 90 Days',
    'Canelo vs Crawford Negotiations Enter Final Phase',
    'Australian Boxing Champion Defends Title in Hometown',
    'Women\'s Boxing Breaks Pay-Per-View Record',
    'Tyson Fury Camp Drops Cryptic Social Media Post',
    'Jeff Horn\'s Legacy: How One Fight Changed Australian Boxing',
    'IBC III Gold Coast: Bare-Knuckle Brawling Championship Goes LIVE Tomorrow',
  ];

  static const _newsBody = [
    'In a dramatic turn of events, fight fans around the world are buzzing after tonight\'s announcement. The combat sports landscape continues to evolve at lightning speed, with promoters scrambling to secure the biggest names for their upcoming cards.',
    'Sources close to the situation confirm that negotiations are in the final stages. Both camps have expressed willingness to make the fight happen, potentially setting up one of the biggest bouts of the year.',
    'The MMA community has been debating this matchup for months, and it looks like fans will finally get their wish. Training camp footage leaked on social media has only added fuel to the fire, with both fighters looking in phenomenal shape.',
    'Industry insiders predict this could be a watershed moment for the sport. With record-breaking pay-per-view numbers expected, all eyes will be on the octagon/ring as two of the best in the world collide.',
    'Coming off a spectacular performance in their last outing, expectations are sky-high. The fighter\'s team has been working on a specific game plan designed to exploit their opponent\'s weaknesses.',
    'This marks a historic moment for Australian combat sports, with homegrown talent continuing to make waves on the global stage. Local gyms report a surge in memberships following recent high-profile successes.',
    'Data Fight Central\'s exclusive analysis reveals fascinating statistical trends heading into this matchup. Our AI-powered fight prediction engine gives a slight edge to the favorite, but the underdog\'s recent form tells a different story.',
  ];

  static const _socialTitles = [
    '🔥 FIGHT NIGHT IS HERE',
    '🥊 WHO\'S READY?!',
    '⚔️ WARRIORS DON\'T REST',
    '💪 GRIND NEVER STOPS',
    '🏆 CHAMPION MENTALITY',
    '🎯 EYES ON THE PRIZE',
    '⚡ ELECTRIC ATMOSPHERE',
    '🔴 BREAKING: FIGHT ANNOUNCED',
    '🔴 IBC III IS HERE — WHO\'S WATCHING?!',
    '☕ BUY A COFFEE, NOT A COFFIN',
    '🚁 DRONE RACING HEAT IS LIVE',
  ];

  static const _socialBodies = [
    'The arena is PACKED and the crowd is going INSANE! Who\'s watching tonight? Drop your predictions below! 🥊💥 #DFC #FightNight #CombatSports',
    'Nothing beats the feeling of watching warriors step into the cage/ring and lay it all on the line. Respect to every fighter who dares to compete. 🫡⚔️ #Respect #MMA #Boxing',
    'Training doesn\'t care about your feelings. It doesn\'t care if you\'re tired. It doesn\'t care if it\'s raining. Champions show up EVERY. SINGLE. DAY. 💪🔥 #NeverQuit #GrindMode',
    'The numbers don\'t lie — this sport is EXPLODING globally. Record viewership, record attendance, record stakes. The future of combat sports is NOW. 📈⚡ #CombatSports #Growth',
    'From the streets to the world stage — every champion started somewhere. Your journey is your own. Own it. 🏆 #FighterJourney #DreamBig #DFC',
    'Data Fight Central is tracking every punch, kick, and takedown in real-time. Our AI never sleeps. 🤖📊 #DataDriven #FightAnalytics #DFC',
    'IBC III — International Brawling Championship TOMORROW at Gold Coast Sports & Leisure Centre! Not long until the wood gets chopped! 🪓🔥 Tickets on Eventbrite NOW. #IBC #GoldCoast #DFC',
    'Buy a Coffee, Not a Coffin ☕🪦 — Support DFC and combat sports safety. Every dollar goes towards fighter welfare. Donate now at datafightcentral.web.app 💚 #BuyACoffeeNotACoffin #DFC',
    'Drone Racing is now in the DFC mix 🚁⚡ FPV pilots, speed leagues, and night-track chaos. Follow the SkyTrack feed and catch the next heat live. #DroneRacing #FPV #DFCSkyTrack',
  ];

  static const _spotlightTitles = [
    '⭐ FIGHTER SPOTLIGHT: Rising Through the Ranks',
    '⭐ SPOTLIGHT: The Unbreakable Spirit',
    '⭐ FIGHTER FEATURE: From Underdog to Champion',
    '⭐ DFC SPOTLIGHT: Training Camp Chronicles',
    '⭐ RISING STAR: The Next Generation of Combat Sports',
  ];

  static const _spotlightBodies = [
    'Meet the fighter who went from training in their garage to headlining major events. Their story is a testament to the power of dedication, sacrifice, and an unbreakable will to succeed.',
    'Coming from humble beginnings, this warrior has carved a path through the toughest division in the sport. With a perfect finish rate and iron chin, the future looks incredibly bright.',
    'After a devastating loss early in their career, many counted them out. But true champions don\'t stay down. They rebuilt, retrained, and came back stronger than ever.',
    'Training three times a day, six days a week. Strict nutrition. Mental conditioning. This is what it takes to compete at the highest level. Inside the camp of a future champion.',
    'At just 23 years old, they\'re already turning heads across the combat sports world. Explosive striking, elite grappling, and a killer instinct that can\'t be taught.',
  ];

  static const _eventTitles = [
    'DFC FIGHT NIGHT: Warriors Collide',
    'CHAMPIONSHIP BOUT: Title on the Line',
    'MEGA EVENT: Triple Title Card',
    'FIGHT NIGHT LIVE: Stacked Prelims & Main Card',
    'DFC PRESENTS: The Ultimate Showdown',
    'INTERNATIONAL FIGHT WEEK: Cross-Border War',
    'LEGENDS NIGHT: Tribute to the Greats',
    'RISING STARS: Tomorrow\'s Champions Today',
    'IBC III: INTERNATIONAL BRAWLING CHAMPIONSHIP — GOLD COAST',
    'DFC SKYTRACK: DRONE RACING NIGHT SERIES',
  ];

  static const _eventDescriptions = [
    'An absolutely stacked card from top to bottom. The main event features two undefeated warriors battling for championship gold, while the co-main showcases a legendary rivalry reignited.',
    'This is the fight card fans have been waiting for all year. Multiple title fights, grudge matches, and debut performances from the hottest prospects in the sport.',
    'Live from a sold-out arena, DFC presents a night of world-class combat sports action. From the opening bout to the main event, every fight on this card has finish potential.',
    'Fight fans, mark your calendars! This historic event brings together champions from across the globe for one unforgettable night of action.',
    'IBC III — the International Brawling Championship returns to the Gold Coast Sports & Leisure Centre QLD on March 7. A stacked card of raw brawling action. Not long until the wood gets chopped! Tickets on Eventbrite.',
    'DFC SkyTrack Drone Racing — precision pilots, split-second gates, and full-throttle FPV action under lights. Build-up starts 1 month out and ramps hard into race night.',
  ];

  static const _venues = [
    'Qudos Bank Arena, Sydney',
    'Melbourne Convention Centre',
    'Brisbane Entertainment Centre',
    'Perth Arena, Western Australia',
    'Adelaide Entertainment Centre',
    'Gold Coast Convention Centre',
    'Spark Arena, Auckland',
    'T-Mobile Arena, Las Vegas',
    'Madison Square Garden, New York',
    'O2 Arena, London',
    'Rajadamnern Stadium, Bangkok',
    'Saitama Super Arena, Tokyo',
    'Impact Arena, Bangkok',
    'Gold Coast Sports & Leisure Centre, QLD',
  ];

  static const _promotions = [
    'DFC Promotions',
    'UFC',
    'ONE Championship',
    'Hex Fight Series',
    'BKFC Australia',
    'Bellator MMA',
    'Glory Kickboxing',
    'AFC (Australian Fighting Championship)',
    'Cage Warriors',
    'PFL',
    'IBC (International Brawling Championship)',
  ];

  static const _promoTitles = [
    '🚨 THIS IS NOT A DRILL — MASSIVE FIGHT ANNOUNCEMENT',
    '💥 THE BIGGEST CARD OF THE YEAR JUST DROPPED',
    '🔥 FIGHT FANS: YOU ARE NOT READY FOR THIS',
    '⚡ BREAKING: SUPERFIGHT CONFIRMED',
    '🏆 CHAMPIONSHIP DOUBLE-HEADER ANNOUNCED',
    '📣 DFC EXCLUSIVE: The Fight Everyone Wants to See',
    '🎯 MARK YOUR CALENDAR — THIS CHANGES EVERYTHING',
    '💎 PREMIUM EVENT: Only on DFC',
    '🪓 IBC III TOMORROW — THE WOOD GETS CHOPPED AT GOLD COAST',
    '☕ BUY A COFFEE, NOT A COFFIN — Support Fighter Welfare',
    '🚁 SKYTRACK DRONE RACING — LOCK IN THE GRID',
  ];

  static const _promoBodies = [
    'The combat sports world is about to be shaken to its core. We\'ve been working behind the scenes for months, and now it\'s time to reveal the biggest fight announcement of 2025. Stay tuned to DFC for the full breakdown.',
    'Two champions. One cage. Zero excuses. This is the fight that defines legacies. Live on DFC — the home of combat sports intelligence.',
    'DFC\'s Samurai AI has crunched the numbers, analyzed thousands of data points, and the prediction engine is SMOKING. This fight is going to be SPECIAL.',
    'From the streets of Western Sydney to the global stage — DFC is bringing world-class combat sports to YOUR screen. Premium coverage. Zero compromise.',
    'IBC III — International Brawling Championship is TOMORROW at Gold Coast Sports & Leisure Centre QLD! The card is stacked, the fighters are ready, and the wood is about to get CHOPPED. Get your tickets on Eventbrite before they sell out! 🪓🔥 #IBCIII #GoldCoast #DFC',
    'Buy a Coffee, Not a Coffin ☕ — DFC\'s fighter welfare initiative. Every donation supports concussion research, fighter recovery programs, and insurance for independent combat athletes. Support the warriors who put it all on the line. Donate now at datafightcentral.web.app 💚',
    'DFC SkyTrack Drone Racing is OPEN. Pilots, teams, and creators can now run campaign wheels, content drops, and race-night hype through the same unstoppable promotional engine. #DroneRacing #FPV #DFC',
  ];

  static const _droneRacingTitles = [
    '🚁 DFC SKYTRACK QUALIFIERS OPEN NOW',
    '⚡ FPV PILOTS: RACE NIGHT COUNTDOWN STARTS',
    '🏁 DFC DRONE RACING GRID LOCKED',
    '🔥 NIGHT TRACK SERIES — THIS WEEKEND',
    '🎮 REAL PILOTS. REAL SPEED. REAL PRESSURE.',
  ];

  static const _droneRacingBodies = [
    'The DFC SkyTrack qualifiers are live. Upload your lap content, lock your sponsor package, and start your hype wheel now.',
    'One month out? Light ads. Three weeks out? Turn it up. Two weeks, one week, days, then hours — DFC runs your drone racing promo ladder automatically.',
    'Pilots and promoters can now run drone racing campaigns inside DFC with content warehouse + swarm support + social blast tools.',
    'Race-week format is active: clips, pilot cards, gate previews, and livestream reminders. The grid is moving fast.',
    'This is promotional engineering for the next generation. Build your drone racing brand and let the swarm amplify every drop.',
  ];

  static const _viralSnippets = [
    '🚀 That KO was so clean it belongs in a museum 🖼️',
    '🚀 When the underdog wins, EVERYONE wins 🏆',
    '🚀 3 seconds. One punch. Career-defining moment. 💥',
    '🚀 The crowd went SILENT... then ERUPTED 🌋',
    '🚀 Commentator literally lost his voice on this one 🎤',
    '🚀 Even the opponent\'s corner was applauding 👏',
    '🚀 This submission was from another dimension 🌀',
    '🚀 Record-breaking performance — the stats are INSANE 📊',
  ];

  static const _trainingTitles = [
    '💪 Recovery Protocol: The Science of Bouncing Back',
    '🧠 Mental Conditioning: Think Like a Champion',
    '🥊 Technique Breakdown: The Perfect Jab',
    '🏃 Cardio for Fighters: Endurance That Lasts',
    '🧘 Mindfulness for Warriors: Finding Focus',
    '🍎 Fight Camp Nutrition: Fuel Your Performance',
    '⚔️ Sparring Smart: How to Train Without Breaking Down',
  ];

  static const _trainingBodies = [
    'Recovery isn\'t just about rest days — it\'s a science. Cold therapy, compression, nutrition timing, and sleep optimization are the four pillars every serious fighter needs to master. Here\'s DFC\'s data-driven approach to bouncing back faster.',
    'The mind is the most powerful weapon in any fighter\'s arsenal. Champions don\'t just train their bodies — they train their thoughts. Visualization, affirmation, and stress management separate the contenders from the pretenders.',
    'A proper jab is the foundation of everything in striking. Speed, accuracy, and timing matter more than power. Here\'s a technical breakdown of what makes a world-class jab, with frame-by-frame analysis from DFC\'s AI.',
    'You can have the most devastating knockout power in the world, but if you gas out in round 3, none of it matters. Here\'s how champions build cardio that lasts the full 5 rounds — and beyond.',
    'In the chaos of combat, finding stillness is a superpower. Top fighters around the world are incorporating mindfulness practices into their training camps. Here\'s why — and how you can start.',
  ];

  static const _storyTitles = [
    'DFC Live',
    'Fight Recap',
    'Training Day',
    'Behind Cage',
    'Weigh-In',
    'Champion',
    'KO of Week',
    'Camp Life',
    'Fan Zone',
    'Fight Week',
  ];

  static const _storyBodies = [
    'Live from ringside — the atmosphere is ELECTRIC tonight!',
    'What a fight! Full recap and analysis coming soon on DFC.',
    'Morning training session at the gym. The grind never stops.',
    'Behind the scenes access you won\'t find anywhere else.',
    'Weigh-ins complete. Both fighters made weight. It\'s ON.',
    'The new champion celebrates with their team. What a moment.',
    'THIS knockout is going to be replayed for years. Absolutely incredible.',
    'Inside the training camp — 6 weeks of preparation for 15 minutes of war.',
    'The fans are what make this sport great. Thank you DFC community!',
    'Fight week energy is different. You can feel it in the air.',
  ];

  static const _metaverseTitles = [
    '🌐 DFC METAVERSE: Virtual Arena Now Open',
    '🥽 VR Fight Experience: Feel Every Punch',
    '🎮 DFC x Roblox: Fight Game Launch',
    '⛓️ Web3 Fighter NFT Collection Drops',
    '🌍 Decentraland DFC Hub: Enter the Digital Octagon',
    '🏗️ The Sandbox: Build Your Dream Gym',
  ];

  static const _metaverseBodies = [
    'Step into the future of combat sports. The DFC Metaverse Arena lets you watch live fights in full 360° VR, interact with AI-powered fighter avatars, and experience the atmosphere like never before.',
    'The next generation of fight entertainment is HERE. DFC\'s partnership brings combat sports into the metaverse with stunning virtual environments, collectible NFT fight cards, and immersive fan experiences.',
    'Train. Fight. Collect. The DFC metaverse experience combines the best of gaming with real combat sports data. Every move is driven by real fight statistics from our Samurai AI engine.',
    'From virtual training sessions with AI coaches to collecting rare digital fighter cards, the DFC metaverse is where combat sports meets the future. Welcome to Web3 fighting.',
  ];
}

class _HypeRampConfig {
  final String phase;
  final int promoBursts;

  const _HypeRampConfig({required this.phase, required this.promoBursts});
}
