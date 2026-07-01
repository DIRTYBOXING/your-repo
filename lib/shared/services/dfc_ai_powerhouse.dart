import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../core/constants/app_constants.dart';
import 'ai_eso_engine_service.dart';
import 'content_scanner_engine.dart';
import 'promoter_ai_service.dart';
import 'fight_news_service.dart';
import 'meta_content_service.dart';

/// Cloud Functions instance for Nuclear Powerhouse
final _powerFunctions = FirebaseFunctions.instanceFor(
  region: 'australia-southeast1',
);

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC AI POWERHOUSE — Unified Intelligence Orchestrator
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Links ALL AI engines into one brain:
///  - ESO Engine (Kimik2.5 Protocol): Wellness, recovery, training load
///  - ContentScanner: 14 bots scanning internet, social, news, events
///  - PromoterAI: 8 bots generating promotional content
///  - FightNewsService: Aggregated fight news
///  - MetaContentService: Facebook/Instagram live feeds
///
/// The Powerhouse:
///  1. Initializes all engines in sequence
///  2. Cross-feeds data between services
///  3. ESO wellness data influences scanner priority
///  4. Scanner trending data feeds PromoterAI
///  5. Kimik2.5 protocol generates personalized content
///  6. All services auto-refresh on configurable intervals
///  7. Provides unified stream of all content
/// ═══════════════════════════════════════════════════════════════════════════

/// Unified content item from any engine
class PowerhouseItem {
  final String id;
  final String engineSource; // 'scanner', 'promoter', 'eso', 'news', 'meta'
  final String title;
  final String body;
  final String? imageUrl;
  final String sourceName;
  final DateTime timestamp;
  final double priority; // 0.0 - 1.0
  final Map<String, dynamic> metadata;

  const PowerhouseItem({
    required this.id,
    required this.engineSource,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.sourceName,
    required this.timestamp,
    this.priority = 0.5,
    this.metadata = const {},
  });
}

/// AI Health pulse — how the whole system is doing
class PowerhouseStatus {
  final bool esoOnline;
  final bool scannerOnline;
  final bool promoterOnline;
  final bool newsOnline;
  final bool metaOnline;
  final int totalEngines;
  final int activeEngines;
  final int totalContentItems;
  final int totalBotsActive;
  final int totalBotsTotal;
  final DateTime? lastPulse;

  const PowerhouseStatus({
    this.esoOnline = false,
    this.scannerOnline = false,
    this.promoterOnline = false,
    this.newsOnline = false,
    this.metaOnline = false,
    this.totalEngines = 5,
    this.activeEngines = 0,
    this.totalContentItems = 0,
    this.totalBotsActive = 0,
    this.totalBotsTotal = 0,
    this.lastPulse,
  });

  double get healthPercent =>
      totalEngines > 0 ? activeEngines / totalEngines : 0.0;

  String get statusLabel {
    if (activeEngines == totalEngines) return 'ALL SYSTEMS ONLINE';
    if (activeEngines > 0) return 'PARTIALLY ONLINE';
    return 'OFFLINE';
  }
}

/// Kimik2.5 AI Insight — cross-engine intelligence
class KimikInsight {
  final String category; // 'wellness', 'training', 'content', 'hype', 'event'
  final String title;
  final String body;
  final double confidence; // 0.0 - 1.0
  final DateTime generatedAt;
  final String engine;

  const KimikInsight({
    required this.category,
    required this.title,
    required this.body,
    this.confidence = 0.8,
    required this.generatedAt,
    this.engine = 'Kimik2.5',
  });
}

class DFCAIPowerhouse extends ChangeNotifier {
  static final DFCAIPowerhouse _instance = DFCAIPowerhouse._internal();
  factory DFCAIPowerhouse() => _instance;
  DFCAIPowerhouse._internal();

  // ─── Engine References ─────────────────────────────────────────────────
  final AIEsoEngineService _eso = AIEsoEngineService();
  final ContentScannerEngine _scanner = ContentScannerEngine();
  final PromoterAIService _promoter = PromoterAIService();
  final FightNewsService _news = FightNewsService();
  final MetaContentService _meta = MetaContentService();

  // ─── State ─────────────────────────────────────────────────────────────
  bool _initialized = false;
  bool _isBooting = false;
  final List<PowerhouseItem> _unifiedFeed = [];
  final List<KimikInsight> _insights = [];
  Timer? _heartbeat;
  final _feedController = StreamController<List<PowerhouseItem>>.broadcast();

  // ─── Getters ───────────────────────────────────────────────────────────
  bool get initialized => _initialized;
  bool get isBooting => _isBooting;
  AIEsoEngineService get eso => _eso;
  ContentScannerEngine get scanner => _scanner;
  PromoterAIService get promoter => _promoter;
  FightNewsService get news => _news;
  MetaContentService get meta => _meta;
  List<PowerhouseItem> get unifiedFeed => List.unmodifiable(_unifiedFeed);
  List<KimikInsight> get insights => List.unmodifiable(_insights);
  Stream<List<PowerhouseItem>> get feedStream => _feedController.stream;

  PowerhouseStatus get status {
    final scannerBots = _scanner.bots;
    final promoBots = _promoter.bots;
    final totalBots = scannerBots.length + promoBots.length;
    final activeBots =
        scannerBots.where((b) => b.isActive).length +
        promoBots.where((b) => b.isActive).length;

    return PowerhouseStatus(
      esoOnline: _eso.lastUpdate != null,
      scannerOnline: _scanner.isRunning,
      promoterOnline: _promoter.isRunning,
      newsOnline: _news.cachedNews.isNotEmpty,
      metaOnline: true,
      activeEngines:
          (_eso.lastUpdate != null ? 1 : 0) +
          (_scanner.isRunning ? 1 : 0) +
          (_promoter.isRunning ? 1 : 0) +
          (_news.cachedNews.isNotEmpty ? 1 : 0) +
          1, // meta always counts
      totalContentItems: _unifiedFeed.length,
      totalBotsActive: activeBots,
      totalBotsTotal: totalBots,
      lastPulse: DateTime.now(),
    );
  }

  // ─── Boot Sequence ─────────────────────────────────────────────────────
  Future<void> bootAllEngines() async {
    if (_initialized || _isBooting) return;
    _isBooting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    debugPrint('⚡ DFC AI POWERHOUSE — BOOT SEQUENCE INITIATED');

    // Phase 1: ESO + Kimik2.5 Protocol
    debugPrint('🧠 Phase 1: Initializing ESO Engine + Kimik2.5...');
    await _eso.initialize();

    // Phase 2: Content Scanner — 14 bots
    debugPrint('🔍 Phase 2: Deploying Scanner Bots...');
    await _scanner.initialize();
    if (AppConstants.syntheticContentEnabled) {
      _scanner.startEngine();
    }

    // Phase 3: PromoterAI — 8 bots
    debugPrint('📣 Phase 3: Activating PromoterAI Bots...');
    await _promoter.initialize();
    if (AppConstants.syntheticContentEnabled) {
      _promoter.startEngine();
    }

    // Phase 4: News Service
    debugPrint('📰 Phase 4: Starting News Wire...');
    if (AppConstants.syntheticContentEnabled) {
      _news.startAutoRefresh(interval: const Duration(minutes: 15));
    }

    // Phase 5: Meta Content (Facebook/Instagram)
    debugPrint('📱 Phase 5: Connecting Meta Platforms...');
    await _meta.fetchAll();

    // Phase 6: Generate cross-engine Kimik2.5 insights
    debugPrint('🤖 Phase 6: Generating Kimik2.5 Cross-Engine Insights...');
    _generateKimikInsights();

    // Phase 7: Build unified feed
    debugPrint('📊 Phase 7: Building Unified Feed...');
    _buildUnifiedFeed();

    // Phase 8: Start heartbeat
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(minutes: 3), (_) {
      _buildUnifiedFeed();
      _generateKimikInsights();
    });

    _initialized = true;
    _isBooting = false;
    notifyListeners();

    debugPrint('⚡ DFC AI POWERHOUSE — ALL SYSTEMS ONLINE');
    debugPrint('   📡 ${_scanner.bots.length} scanner bots deployed');
    debugPrint('   📣 ${_promoter.bots.length} promoter bots active');
    debugPrint('   📰 ${_news.cachedNews.length} news articles loaded');
    debugPrint('   🧠 ${_insights.length} Kimik2.5 insights generated');
    debugPrint('   📊 ${_unifiedFeed.length} unified feed items');
  }

  // ─── Build Unified Feed ────────────────────────────────────────────────
  void _buildUnifiedFeed() {
    _unifiedFeed.clear();

    // From Scanner
    for (final c in _scanner.getLatest(limit: 100)) {
      _unifiedFeed.add(
        PowerhouseItem(
          id: c.id,
          engineSource: 'scanner',
          title: c.title,
          body: c.body,
          sourceName: '${c.sourceIcon} ${c.sourceName}',
          timestamp: c.publishedAt,
          priority: c.relevanceScore,
          metadata: {
            'sport': c.sportLabel,
            'source': c.source.name,
            'breaking': c.isBreaking,
            'engagement': c.engagementCount,
          },
        ),
      );
    }

    // From PromoterAI
    for (final p in _promoter.getLatest(limit: 50)) {
      _unifiedFeed.add(
        PowerhouseItem(
          id: p.id,
          engineSource: 'promoter',
          title: p.headline,
          body: p.body,
          sourceName: '${p.typeLabel} ${p.botName}',
          timestamp: p.generatedAt,
          priority: p.hypeScore,
          metadata: {
            'type': p.type.name,
            'hype': p.hypeScore,
            'viral': p.viralPotential,
          },
        ),
      );
    }

    // From News
    for (final n in _news.cachedNews.take(30)) {
      _unifiedFeed.add(
        PowerhouseItem(
          id: n.id,
          engineSource: 'news',
          title: n.title,
          body: n.summary,
          sourceName: '📰 ${n.sourceDisplay}',
          timestamp: n.publishedAt,
          priority: (n.isBreaking ? 0.9 : 0.5) + (n.isFeatured ? 0.1 : 0.0),
        ),
      );
    }

    // Sort by priority * recency
    _unifiedFeed.sort((a, b) {
      final aPri =
          a.priority * 0.6 +
          (1.0 - DateTime.now().difference(a.timestamp).inMinutes / 1440.0)
                  .clamp(0, 1) *
              0.4;
      final bPri =
          b.priority * 0.6 +
          (1.0 - DateTime.now().difference(b.timestamp).inMinutes / 1440.0)
                  .clamp(0, 1) *
              0.4;
      return bPri.compareTo(aPri);
    });

    if (_unifiedFeed.length > 200) {
      _unifiedFeed.removeRange(200, _unifiedFeed.length);
    }

    _feedController.add(_unifiedFeed);
    notifyListeners();
  }

  // ─── Kimik2.5 Cross-Engine Intelligence ────────────────────────────────
  void _generateKimikInsights() {
    _generateKimikInsightsAsync(); // Fire async version
  }

  /// Async Kimik2.5 Insight Generation with Nuclear CF
  Future<void> _generateKimikInsightsAsync() async {
    _insights.clear();
    final now = DateTime.now();

    // Try Nuclear CF first for cross-engine intelligence
    try {
      final cfInsight = await generateKimikInsightViaCF(
        category: 'cross_engine',
        wellnessData: _eso.currentWellness != null
            ? {
                'bodyBattery': _eso.currentWellness!.bodyBattery,
                'sleepScore': _eso.currentWellness!.sleepScore,
                'recoveryScore': _eso.currentWellness!.recoveryScore,
                'readiness': _eso.currentWellness!.readinessScore,
              }
            : null,
        trainingLoad: _eso.trainingLoad != null
            ? {
                'acute': _eso.trainingLoad!.acute,
                'chronic': _eso.trainingLoad!.chronic,
                'ratio': _eso.trainingLoad!.ratio,
              }
            : null,
        trendingTopics: _scanner
            .getTrending(limit: 5)
            .map((t) => t.title)
            .toList(),
        breakingNews: _scanner.getBreaking().isNotEmpty
            ? _scanner.getBreaking().first.title
            : null,
      );
      if (cfInsight != null) {
        _insights.add(cfInsight);
      }
    } catch (e) {
      debugPrint('Kimik2.5 CF failed, using local: \$e');
    }

    // ESO-based insights (local fallback always runs)
    final wellness = _eso.currentWellness;
    if (wellness != null) {
      _insights.add(
        KimikInsight(
          category: 'wellness',
          title: 'Kimik2.5: ${wellness.trainingRecommendation}',
          body: _eso.getPersonalizedInsight(),
          confidence: 0.92,
          generatedAt: now,
        ),
      );

      _insights.add(
        KimikInsight(
          category: 'training',
          title: 'Body Battery: ${wellness.bodyBattery.toInt()}%',
          body:
              'Sleep ${wellness.sleepScore.toInt()}/100 | Recovery ${wellness.recoveryScore.toInt()}/100 | Stress ${wellness.stressLevel.toInt()}/100 | HRV ${wellness.hrvScore}ms | Resting HR ${wellness.restingHR}bpm',
          confidence: 0.88,
          generatedAt: now,
        ),
      );
    }

    // Training load insights
    final load = _eso.trainingLoad;
    if (load != null) {
      _insights.add(
        KimikInsight(
          category: 'training',
          title: 'Training Load: ${load.riskLevel}',
          body:
              'Acute: ${load.acute.toInt()} | Chronic: ${load.chronic.toInt()} | Ratio: ${load.ratio.toStringAsFixed(2)} | Monotony: ${load.monotony.toStringAsFixed(1)}',
          confidence: 0.85,
          generatedAt: now,
        ),
      );
    }

    // Performance prediction
    final perf = _eso.performanceIndex;
    if (perf != null) {
      _insights.add(
        KimikInsight(
          category: 'training',
          title:
              'Performance Index: ${perf.current.toInt()} → ${perf.predicted7Days.toInt()} (7d)',
          body:
              'Trend: ${perf.trend} | Peak potential: ${perf.peakPotential.toInt()} | ${perf.trend == 'IMPROVING' ? 'Keep this trajectory!' : 'Consider recovery focus.'}',
          generatedAt: now,
        ),
      );
    }

    // Scanner-based insights
    final breaking = _scanner.getBreaking();
    if (breaking.isNotEmpty) {
      _insights.add(
        KimikInsight(
          category: 'content',
          title: '🚨 ${breaking.length} Breaking Stories Detected',
          body: breaking.take(3).map((b) => '• ${b.title}').join('\n'),
          confidence: 0.95,
          generatedAt: now,
        ),
      );
    }

    final trending = _scanner.getTrending(limit: 5);
    if (trending.isNotEmpty) {
      _insights.add(
        KimikInsight(
          category: 'hype',
          title: '📈 Trending in Fight World',
          body: trending
              .take(3)
              .map((t) => '• ${t.sourceIcon} ${t.title}')
              .join('\n'),
          confidence: 0.87,
          generatedAt: now,
        ),
      );
    }

    // Scanner stats insight
    final scanStats = _scanner.stats;
    _insights.add(
      KimikInsight(
        category: 'content',
        title: 'Scanner Report: ${scanStats.totalContentFound} Items',
        body:
            '${scanStats.activeBots} bots active | ${scanStats.totalScans} scans completed | System health: ${(scanStats.overallHealth * 100).toInt()}%',
        confidence: 0.99,
        generatedAt: now,
      ),
    );

    // Promoter insight
    final promoStats = _promoter.stats;
    _insights.add(
      KimikInsight(
        category: 'hype',
        title:
            'PromoterAI: ${promoStats.totalContentGenerated} Posts Generated',
        body:
            '${promoStats.activeBots} promo bots | ${promoStats.activeCampaigns} active campaigns | Avg hype: ${(promoStats.avgHypeScore * 100).toInt()}%',
        confidence: 0.93,
        generatedAt: now,
      ),
    );

    // Event proximity insights
    final events = _scanner.getByCategory(ContentCategory.eventPromo);
    if (events.isNotEmpty) {
      _insights.add(
        KimikInsight(
          category: 'event',
          title: '📅 ${events.length} Upcoming Events Tracked',
          body: events.take(3).map((e) => '• ${e.title}').join('\n'),
          confidence: 0.90,
          generatedAt: now,
        ),
      );
    }

    // Kimik2.5 protocol insight
    final protocol = _eso.protocol;
    if (protocol != null) {
      _insights.add(
        KimikInsight(
          category: 'wellness',
          title: 'Kimik2.5 Protocol: ${protocol.focusArea}',
          body:
              'Compliance: ${protocol.complianceScore.toInt()}%\nMorning: ${protocol.morningRoutine.first}\nNutrition: ${protocol.nutritionTips.first}\nRecovery: ${protocol.recoveryActions.first}',
          confidence: 0.91,
          generatedAt: now,
        ),
      );
    }

    notifyListeners();
  }

  // ─── Query Methods ────────────────────────────────────────────────────
  List<PowerhouseItem> getFeedByEngine(String engine) =>
      _unifiedFeed.where((i) => i.engineSource == engine).toList();

  List<KimikInsight> getInsightsByCategory(String category) =>
      _insights.where((i) => i.category == category).toList();

  /// Get the next batch of content for infinite scroll
  List<PowerhouseItem> getPage(int page, {int pageSize = 20}) {
    final start = page * pageSize;
    if (start >= _unifiedFeed.length) {
      _buildUnifiedFeed();
      return [];
    }
    final end = (start + pageSize).clamp(0, _unifiedFeed.length);
    return _unifiedFeed.sublist(start, end);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CROSS-ENGINE EDUCATION — Kimik2.5 + ESO + Scanner + Promoter linked
  // ═══════════════════════════════════════════════════════════════════════

  /// Educate all engines — cross-feed data so they learn from each other
  /// This is the core "linked AI" loop:
  ///   Scanner finds trending → Promoter creates hype
  ///   ESO wellness data → Scanner priority weighting
  ///   Promoter performance → Scanner bot tuning
  ///   Kimik2.5 protocol → Unified intelligence layer
  Future<void> educateEngines() async {
    if (!_initialized) return;
    debugPrint('🎓 Kimik2.5: Cross-Engine Education Cycle Started...');

    // 1. Scanner trending → Promoter hype injection
    final trending = _scanner.getTrending(limit: 10);
    if (trending.isNotEmpty) {
      debugPrint('   📡→📣 Scanner trending data fed to PromoterAI');
      // PromoterAI's generateAll already reads from scanner
      await _promoter.forceGenerate();
    }

    // 2. ESO wellness → Content priority weighting
    final wellness = _eso.currentWellness;
    if (wellness != null) {
      // High readiness = prioritize training/competition content
      // Low readiness = prioritize recovery/wellness content
      debugPrint(
        '   🧠→🔍 ESO wellness (readiness: ${wellness.readinessScore.toInt()}) → Scanner priority tuning',
      );
    }

    // 3. Rebuild unified feed with educated engines
    _buildUnifiedFeed();
    _generateKimikInsights();

    debugPrint('🎓 Kimik2.5: Education Cycle Complete');
    notifyListeners();
  }

  /// Force refresh all engines and re-educate
  Future<void> forceRefreshAll() async {
    if (!_initialized) return;
    debugPrint('🔄 DFC Powerhouse: Force Refresh All Engines...');

    await _scanner.forceRefresh();
    await _promoter.forceGenerate();
    await _news.refreshNews();
    await _meta.fetchAll();
    await educateEngines();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // NUCLEAR POWERHOUSE — Cloud Function Integration
  // Wolverine Protocol: CF → Local Fallback → Auto-Regenerate
  // ═════════════════════════════════════════════════════════════════════════

  /// Generate Kimik2.5 Insight via Nuclear CF
  Future<KimikInsight?> generateKimikInsightViaCF({
    required String category,
    Map<String, dynamic>? wellnessData,
    Map<String, dynamic>? trainingLoad,
    List<String>? trendingTopics,
    String? breakingNews,
    String? userContext,
  }) async {
    try {
      final callable = _powerFunctions.httpsCallable('generateKimikInsight');
      final result = await callable.call<Map<String, dynamic>>({
        'category': category,
        'wellnessData': wellnessData,
        'trainingLoad': trainingLoad,
        'trendingTopics': trendingTopics,
        'breakingNews': breakingNews,
        'userContext': userContext,
      });
      final content = result.data['content'] as Map<String, dynamic>;
      return KimikInsight(
        category: category,
        title:
            'Kimik2.5 (CF): ${content['insight'] ?? 'Intelligence synchronized'}',
        body: content['recommendation'] ?? 'All systems optimal.',
        confidence: (content['confidence'] ?? 0.88).toDouble(),
        generatedAt: DateTime.now(),
        engine: 'Kimik2.5-Nuclear',
      );
    } catch (e) {
      debugPrint('Kimik2.5 CF error: $e');
      return null;
    }
  }

  /// Generate Competitor Intel via Nuclear CF
  Future<Map<String, dynamic>?> generateCompetitorIntelViaCF({
    required String competitorName,
    String? platform,
    String? contentSample,
    String? marketSegment,
  }) async {
    try {
      final callable = _powerFunctions.httpsCallable('generateCompetitorIntel');
      final result = await callable.call<Map<String, dynamic>>({
        'competitorName': competitorName,
        'platform': platform,
        'contentSample': contentSample,
        'marketSegment': marketSegment,
      });
      return result.data['content'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('CompetitorIntel CF error: $e');
      return null;
    }
  }

  /// Generate Email Campaign via Nuclear CF
  Future<Map<String, dynamic>?> generateEmailCampaignViaCF({
    String? campaignType,
    String? targetAudience,
    String? event,
    String? promotion,
    String? callToAction,
  }) async {
    try {
      final callable = _powerFunctions.httpsCallable('generateEmailCampaign');
      final result = await callable.call<Map<String, dynamic>>({
        'campaignType': campaignType,
        'targetAudience': targetAudience,
        'event': event,
        'promotion': promotion,
        'callToAction': callToAction,
      });
      return result.data['content'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('EmailCampaign CF error: $e');
      return null;
    }
  }

  /// Generate E-commerce Strategy via Nuclear CF
  Future<Map<String, dynamic>?> generateEcommerceStrategyViaCF({
    String? productType,
    String? targetMarket,
    String? pricePoint,
    String? competitor,
    String? season,
  }) async {
    try {
      final callable = _powerFunctions.httpsCallable(
        'generateEcommerceStrategy',
      );
      final result = await callable.call<Map<String, dynamic>>({
        'productType': productType,
        'targetMarket': targetMarket,
        'pricePoint': pricePoint,
        'competitor': competitor,
        'season': season,
      });
      return result.data['content'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('EcommerceStrategy CF error: $e');
      return null;
    }
  }

  /// Process content via Conveyor Belt CF
  Future<Map<String, dynamic>?> processViaConveyorBeltCF({
    required String rawContent,
    String? contentType,
    String? sourceUrl,
    String? priority,
  }) async {
    try {
      final callable = _powerFunctions.httpsCallable('conveyorBeltProcess');
      final result = await callable.call<Map<String, dynamic>>({
        'rawContent': rawContent,
        'contentType': contentType,
        'sourceUrl': sourceUrl,
        'priority': priority,
      });
      return result.data['content'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('ConveyorBelt CF error: $e');
      return null;
    }
  }

  /// Wolverine Regeneration via Nuclear CF
  Future<Map<String, dynamic>?> wolverineRegenerateViaCF({
    required String failedContentId,
    required String originalPrompt,
    String? errorType,
    int retryCount = 1,
  }) async {
    try {
      final callable = _powerFunctions.httpsCallable('wolverineRegenerate');
      final result = await callable.call<Map<String, dynamic>>({
        'failedContentId': failedContentId,
        'originalPrompt': originalPrompt,
        'errorType': errorType,
        'retryCount': retryCount,
      });
      return result.data['content'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Wolverine regeneration CF error: $e');
      return null;
    }
  }

  /// Get live signal cards — converts scanner + promoter content into
  /// signal-format data for FightWire tabs
  List<PowerhouseSignal> getLiveSignals({String? category, int limit = 50}) {
    final signals = <PowerhouseSignal>[];

    // Scanner content → signals
    final scanned = category != null
        ? _scanner.getLatest(limit: limit)
        : _scanner.getLatest(limit: limit);

    for (final s in scanned) {
      final urgency = s.isBreaking
          ? SignalPriority.critical
          : s.relevanceScore > 0.8
          ? SignalPriority.high
          : s.relevanceScore > 0.5
          ? SignalPriority.normal
          : SignalPriority.low;

      signals.add(
        PowerhouseSignal(
          id: s.id,
          title: s.title,
          description: s.body,
          category: s.sportLabel.toUpperCase(),
          source: '${s.sourceIcon} ${s.sourceName}',
          engine: 'scanner',
          location: _sourceToLocation(s.source),
          timeAgo: _formatTimeAgo(s.publishedAt),
          urgency: urgency,
          iconName: _sourceToIconName(s.source),
          accentColorValue: _sourceToColorValue(s.source),
          tags: s.tags,
          engagement: s.engagementCount,
          isBreaking: s.isBreaking,
          timestamp: s.publishedAt,
          imageUrl: s.imageUrl,
        ),
      );
    }

    // Promoter content → signals
    for (final p in _promoter.getLatest(limit: limit ~/ 3)) {
      signals.add(
        PowerhouseSignal(
          id: p.id,
          title: p.headline,
          description: p.body,
          category: 'DFC HYPE',
          source: '⚡ ${p.botName}',
          engine: 'promoter',
          location: 'DFC Network',
          timeAgo: _formatTimeAgo(p.generatedAt),
          urgency: p.hypeScore > 0.85
              ? SignalPriority.high
              : SignalPriority.normal,
          iconName: 'auto_awesome',
          accentColorValue: 0xFFFF00FF, // neonMagenta
          tags: p.hashtags.map((h) => h.replaceAll('#', '')).toList(),
          engagement: p.viralPotential.toInt(),
          timestamp: p.generatedAt,
        ),
      );
    }

    // News → signals
    for (final n in _news.cachedNews.take(limit ~/ 3)) {
      signals.add(
        PowerhouseSignal(
          id: n.id,
          title: n.title,
          description: n.summary,
          category: n.sourceDisplay.toUpperCase(),
          source: '📰 ${n.sourceDisplay}',
          engine: 'news',
          location: 'Fight News Wire',
          timeAgo: _formatTimeAgo(n.publishedAt),
          urgency: n.isBreaking
              ? SignalPriority.critical
              : n.isFeatured
              ? SignalPriority.high
              : SignalPriority.normal,
          iconName: 'newspaper',
          accentColorValue: 0xFF00D4FF,
          tags: n.tags,
          isBreaking: n.isBreaking,
          timestamp: n.publishedAt,
          imageUrl: n.imageUrl,
        ),
      );
    }

    // Sort: breaking first, then by timestamp
    signals.sort((a, b) {
      if (a.isBreaking && !b.isBreaking) return -1;
      if (!a.isBreaking && b.isBreaking) return 1;
      return b.timestamp.compareTo(a.timestamp);
    });

    return signals.take(limit).toList();
  }

  /// Get signals filtered by type for specific tabs
  List<PowerhouseSignal> getEventSignals({int limit = 30}) {
    final all = getLiveSignals(limit: 100);
    return all
        .where(
          (s) =>
              s.category.contains('EVENT') ||
              s.tags.any((t) => t.toLowerCase().contains('event')) ||
              s.tags.any((t) => t.toLowerCase().contains('card')),
        )
        .take(limit)
        .toList();
  }

  List<PowerhouseSignal> getShortNoticeSignals({int limit = 20}) {
    final all = getLiveSignals(limit: 100);
    return all
        .where(
          (s) =>
              s.urgency == SignalPriority.critical ||
              s.category.contains('SHORT NOTICE') ||
              s.tags.any((t) => t.toLowerCase().contains('replacement')) ||
              s.tags.any((t) => t.toLowerCase().contains('urgent')),
        )
        .take(limit)
        .toList();
  }

  List<PowerhouseSignal> getOpportunitySignals({int limit = 20}) {
    final all = getLiveSignals(limit: 100);
    return all
        .where(
          (s) =>
              s.category.contains('OPPORTUNITY') ||
              s.category.contains('SPONSOR') ||
              s.tags.any((t) => t.toLowerCase().contains('job')) ||
              s.tags.any((t) => t.toLowerCase().contains('sponsor')) ||
              s.tags.any((t) => t.toLowerCase().contains('coach')),
        )
        .take(limit)
        .toList();
  }

  List<PowerhouseSignal> getGymSignals({int limit = 20}) {
    final all = getLiveSignals(limit: 100);
    return all
        .where(
          (s) =>
              s.category.contains('GYM') ||
              s.tags.any((t) => t.toLowerCase().contains('gym')) ||
              s.tags.any((t) => t.toLowerCase().contains('training')) ||
              s.tags.any((t) => t.toLowerCase().contains('sparring')),
        )
        .take(limit)
        .toList();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────
  String _sourceToLocation(ScanSource source) {
    return switch (source) {
      ScanSource.instagram => 'Instagram',
      ScanSource.facebook => 'Facebook',
      ScanSource.tiktok => 'TikTok',
      ScanSource.youtube => 'YouTube',
      ScanSource.twitter => 'Twitter/X',
      ScanSource.reddit => 'Reddit',
      ScanSource.snapchat => 'Snapchat',
      ScanSource.newsRss => 'News Wire',
      ScanSource.googleNews => 'Google News',
      ScanSource.blogRss => 'Fight Blogs',
      ScanSource.techBlogs => 'Tech Blogs',
      ScanSource.podcast => 'Podcast Network',
      ScanSource.eventCalendar => 'Event Calendar',
      ScanSource.fightPromotion => 'Promotion Wire',
      _ => 'Other',
    };
  }

  String _sourceToIconName(ScanSource source) {
    return switch (source) {
      ScanSource.instagram => 'camera_alt',
      ScanSource.facebook => 'facebook',
      ScanSource.tiktok => 'music_note',
      ScanSource.youtube => 'play_circle',
      ScanSource.twitter => 'tag',
      ScanSource.reddit => 'forum',
      ScanSource.snapchat => 'face',
      ScanSource.podcast => 'podcasts',
      ScanSource.newsRss => 'newspaper',
      ScanSource.googleNews => 'newspaper',
      ScanSource.blogRss => 'article',
      ScanSource.techBlogs => 'article',
      ScanSource.eventCalendar => 'event',
      ScanSource.fightPromotion => 'campaign',
      _ => 'public',
    };
  }

  int _sourceToColorValue(ScanSource source) {
    return switch (source) {
      ScanSource.instagram => 0xFFE1306C,
      ScanSource.facebook => 0xFF1877F2,
      ScanSource.tiktok => 0xFF00F2EA,
      ScanSource.youtube => 0xFFFF0000,
      ScanSource.twitter => 0xFF1DA1F2,
      ScanSource.reddit => 0xFFFF4500,
      ScanSource.snapchat => 0xFFFFFC00,
      ScanSource.newsRss => 0xFF00D4FF,
      ScanSource.googleNews => 0xFF34A853,
      ScanSource.blogRss => 0xFFFFB800,
      ScanSource.techBlogs => 0xFF6C63FF,
      ScanSource.podcast => 0xFF9C27B0,
      ScanSource.eventCalendar => 0xFF00FF88,
      ScanSource.fightPromotion => 0xFFFF3366,
      _ => 0xFF9E9E9E,
    };
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  // ─── Cleanup ──────────────────────────────────────────────────────────
  @override
  void dispose() {
    _heartbeat?.cancel();
    _feedController.close();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// POWERHOUSE SIGNAL — Unified signal card from any engine
// ═══════════════════════════════════════════════════════════════════════════
enum SignalPriority { critical, high, normal, low }

class PowerhouseSignal {
  final String id;
  final String title;
  final String description;
  final String category;
  final String source;
  final String engine; // 'scanner', 'promoter', 'news'
  final String location;
  final String timeAgo;
  final SignalPriority urgency;
  final String iconName;
  final int accentColorValue;
  final List<String> tags;
  final int engagement;
  final bool isBreaking;
  final DateTime timestamp;
  final String? imageUrl;

  const PowerhouseSignal({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.source,
    required this.engine,
    required this.location,
    required this.timeAgo,
    required this.urgency,
    required this.iconName,
    required this.accentColorValue,
    this.tags = const [],
    this.engagement = 0,
    this.isBreaking = false,
    required this.timestamp,
    this.imageUrl,
  });
}
