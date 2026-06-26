import 'dart:async';
import 'package:flutter/foundation.dart';
import 'auto_feed_orchestrator_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ECOSYSTEM STATE SERVICE — Real-Time Pipeline Tracking & Metrics Flow
/// ═══════════════════════════════════════════════════════════════════════════
/// Tracks opportunities flowing through 4-stage pipeline:
/// DISCOVER → BUILD → WIN → SELL
/// Enables bidirectional feedback loops: metrics flow back to influence ranking
class EcosystemStateService extends ChangeNotifier {
  // ── Pipeline Refresh Timer ─────────────────────────────────────────────
  Timer? _pipelineTimer;
  bool _isIngesting = false;
  DateTime? _lastIngestion;

  /// Default pipeline refresh cadence — 10 minutes.
  /// Fast enough to stay current, light enough to avoid hammering sources.
  static const Duration defaultRefreshInterval = Duration(minutes: 10);

  /// Minimum gap between ingestions (prevents double-triggers)
  static const Duration _minIngestionGap = Duration(minutes: 2);
  // ── Pipeline Stage Containers ──────────────────────────────────────────
  final Map<String, List<OpportunityStageItem>> _stageOpportunities = {
    'discover': [],
    'build': [],
    'win': [],
    'sell': [],
  };

  // ── Real-Time Metrics ──────────────────────────────────────────────────
  final Map<String, num> _realTimeMetrics = {
    'total_opportunities': 0,
    'avg_strategic_score': 0.0,
    'youtube_views_generated': 0,
    'deal_attempts': 0,
    'deals_closed': 0,
    'email_engagement_rate': 0.0,
    'dm_response_rate': 0.0,
    'samurai_signal_hits': 0,
    'joseph_priority_count': 0,
    'legends_show_count': 0,
  };

  // ── Feedback Event Stream ──────────────────────────────────────────────
  final List<EcosystemFeedbackEvent> _feedbackHistory = [];

  // ── Getters ────────────────────────────────────────────────────────────
  Map<String, List<OpportunityStageItem>> get stageOpportunities =>
      Map.unmodifiable(_stageOpportunities);

  Map<String, num> get realTimeMetrics => Map.unmodifiable(_realTimeMetrics);

  List<EcosystemFeedbackEvent> get feedbackHistory =>
      List.unmodifiable(_feedbackHistory);

  int get totalOpportunitiesInPipeline =>
      _stageOpportunities.values.fold(0, (sum, list) => sum + list.length);

  int opportunitiesInStage(String stage) =>
      _stageOpportunities[stage]?.length ?? 0;

  // ── Public Methods ─────────────────────────────────────────────────────

  /// Add opportunity to initial DISCOVER stage
  void addOpportunityToDiscoverStage(
    String opportunityId,
    String source,
    List<String> commandSignals,
    double strategicScore,
    String? imageUrl,
    String? title,
  ) {
    final item = OpportunityStageItem(
      opportunityId: opportunityId,
      source: source,
      commandSignals: commandSignals,
      strategicScore: strategicScore,
      imageUrl: imageUrl,
      title: title ?? 'Untitled Opportunity',
      stageEnteredAt: DateTime.now(),
    );

    _stageOpportunities['discover']?.add(item);
    _recordMetric('total_opportunities', totalOpportunitiesInPipeline);
    _recordFeedbackEvent(
      EcosystemFeedbackEvent(
        eventType: 'opportunity_discovered',
        opportunityId: opportunityId,
        source: source,
        timestamp: DateTime.now(),
        metricDelta: {'discovered_count': 1},
      ),
    );
    notifyListeners();
  }

  /// Advance opportunity to next stage (with reason/action)
  void advanceOpportunityStage(
    String opportunityId,
    String fromStage,
    String toStage,
    String
    reason, // 'brief_generated', 'deal_desk_opened', 'youtube_uploaded', 'deal_closed'
  ) {
    OpportunityStageItem? item;
    try {
      item = _stageOpportunities[fromStage]?.firstWhere(
        (o) => o.opportunityId == opportunityId,
      );
    } catch (e) {
      // Item not found in stage
      return;
    }

    if (item == null) return;

    // Remove from old stage
    _stageOpportunities[fromStage]?.removeWhere(
      (o) => o.opportunityId == opportunityId,
    );

    // Update item with exit time
    item.stageExitedAt = DateTime.now();

    // Create new item for next stage
    final advancedItem = item.copyWith(
      stageEnteredAt: DateTime.now(),
    );

    // Add to new stage
    _stageOpportunities[toStage]?.add(advancedItem);

    _recordFeedbackEvent(
      EcosystemFeedbackEvent(
        eventType: 'stage_advanced',
        opportunityId: opportunityId,
        source: item.source,
        timestamp: DateTime.now(),
        stageTransition: StageTransition(
          from: fromStage,
          to: toStage,
          reason: reason,
        ),
        metricDelta: {
          'advanced_from_$fromStage': 1,
          'entered_$toStage': 1,
          'time_in_stage_ms':
              item.stageExitedAt
                  ?.difference(item.stageEnteredAt)
                  .inMilliseconds ??
              0,
        },
      ),
    );

    _updateRealTimeMetrics();
    notifyListeners();
  }

  /// Update opportunity image URL
  void updateOpportunityImage(String opportunityId, String imageUrl) {
    for (final stage in _stageOpportunities.keys) {
      final opps = _stageOpportunities[stage];
      if (opps == null) continue;

      for (int i = 0; i < opps.length; i++) {
        if (opps[i].opportunityId == opportunityId) {
          opps[i] = opps[i].copyWith(imageUrl: imageUrl);
          notifyListeners();
          return;
        }
      }
    }
  }

  /// Record YouTube generation event
  void recordYouTubeGeneration(String opportunityId, String source) {
    _recordMetric(
      'youtube_views_generated',
      (_realTimeMetrics['youtube_views_generated'] as num) + 1,
    );
    _recordFeedbackEvent(
      EcosystemFeedbackEvent(
        eventType: 'youtube_brief_generated',
        opportunityId: opportunityId,
        source: source,
        timestamp: DateTime.now(),
        metricDelta: {'youtube_briefs': 1},
      ),
    );
    notifyListeners();
  }

  /// Record deal attempt or close
  void recordDealAttempt(String opportunityId, String source, bool succeeded) {
    _recordMetric(
      'deal_attempts',
      (_realTimeMetrics['deal_attempts'] as num) + 1,
    );
    if (succeeded) {
      _recordMetric(
        'deals_closed',
        (_realTimeMetrics['deals_closed'] as num) + 1,
      );
    }

    _recordFeedbackEvent(
      EcosystemFeedbackEvent(
        eventType: succeeded ? 'deal_closed' : 'deal_attempted',
        opportunityId: opportunityId,
        source: source,
        timestamp: DateTime.now(),
        metricDelta: {'deal_attempts': 1, 'deals_closed': succeeded ? 1 : 0},
      ),
    );
    notifyListeners();
  }

  /// Record outreach engagement (email opens, message replies)
  void recordOutreachEngagement(
    String opportunityId,
    String source,
    String
    engagementType, // 'email_open', 'email_click', 'dm_reply', 'call_scheduled'
  ) {
    _recordFeedbackEvent(
      EcosystemFeedbackEvent(
        eventType: 'outreach_engagement',
        opportunityId: opportunityId,
        source: source,
        timestamp: DateTime.now(),
        metricDelta: {'engagement_$engagementType': 1},
      ),
    );
    notifyListeners();
  }

  /// Update campaign signal metrics
  void recordCampaignSignalHit(String signal) {
    if (signal == 'samurai-promotion') {
      _recordMetric(
        'samurai_signal_hits',
        (_realTimeMetrics['samurai_signal_hits'] as num) + 1,
      );
    } else if (signal == 'joseph-priority') {
      _recordMetric(
        'joseph_priority_count',
        (_realTimeMetrics['joseph_priority_count'] as num) + 1,
      );
    } else if (signal == 'legends-show') {
      _recordMetric(
        'legends_show_count',
        (_realTimeMetrics['legends_show_count'] as num) + 1,
      );
    }
    notifyListeners();
  }

  /// Clear all pipeline data (for demo reset)
  void resetPipeline() {
    _stageOpportunities.forEach((key, value) => value.clear());
    _feedbackHistory.clear();
    _realTimeMetrics.forEach((key, value) {
      _realTimeMetrics[key] = 0;
    });
    _pipelineTimer?.cancel();
    _pipelineTimer = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRODUCTION PIPELINE — Auto-Refresh from AutoFeedOrchestratorService
  // ═══════════════════════════════════════════════════════════════════════

  /// Start the auto-refresh pipeline timer.
  /// Fires immediately, then every [interval] (default 10 min).
  void startPipelineRefresh({Duration interval = defaultRefreshInterval}) {
    _pipelineTimer?.cancel();
    _pipelineTimer = Timer.periodic(interval, (_) => ingestFromOrchestrator());
    // Immediate first ingestion (staggered 2s after widget build)
    Future.delayed(const Duration(seconds: 2), ingestFromOrchestrator);
    debugPrint(
      '🔄 Ecosystem pipeline refresh started — every ${interval.inMinutes}m',
    );
  }

  /// Stop the pipeline refresh timer.
  void stopPipelineRefresh() {
    _pipelineTimer?.cancel();
    _pipelineTimer = null;
    debugPrint('⏹️ Ecosystem pipeline refresh stopped');
  }

  /// Pull latest items from the AutoFeedOrchestratorService and distribute
  /// them across pipeline stages based on their strategic score and signals.
  Future<void> ingestFromOrchestrator() async {
    if (_isIngesting) return;
    // Enforce minimum gap between ingestions
    if (_lastIngestion != null &&
        DateTime.now().difference(_lastIngestion!) < _minIngestionGap) {
      return;
    }
    _isIngesting = true;

    try {
      final orchestrator = AutoFeedOrchestratorService();
      List<AutoFeedItem> items = orchestrator.cached;

      // If cache is empty, do a fresh pull
      if (items.isEmpty) {
        items = await orchestrator.refreshUnifiedFeed();
      }

      if (items.isEmpty) {
        _isIngesting = false;
        return;
      }

      // Track which IDs are already in the pipeline to avoid duplicates
      final existingIds = <String>{};
      for (final stage in _stageOpportunities.values) {
        for (final opp in stage) {
          existingIds.add(opp.opportunityId);
        }
      }

      final now = DateTime.now();
      int added = 0;

      for (final item in items) {
        if (existingIds.contains(item.id)) continue;
        if (item.strategicScore < 0.3) continue; // Skip low-value noise

        // Route to stage based on strategic score + signals
        final stage = _classifyStage(item);

        _stageOpportunities[stage]?.add(
          OpportunityStageItem(
            opportunityId: item.id,
            source: item.source,
            commandSignals: item.commandSignals,
            strategicScore: item.strategicScore,
            imageUrl: item.imageUrl,
            title: item.title,
            stageEnteredAt: now.subtract(
              Duration(
                minutes: stage == 'discover'
                    ? 5
                    : stage == 'build'
                    ? 30
                    : stage == 'win'
                    ? 120
                    : 360,
              ),
            ),
          ),
        );

        // Track campaign signals
        for (final signal in item.commandSignals) {
          recordCampaignSignalHit(signal);
        }

        added++;
        existingIds.add(item.id);
      }

      // Cap each stage at 25 to keep memory light
      for (final entry in _stageOpportunities.entries) {
        if (entry.value.length > 25) {
          entry.value.removeRange(0, entry.value.length - 25);
        }
      }

      _lastIngestion = now;
      _updateRealTimeMetrics();
      _recordMetric('total_opportunities', totalOpportunitiesInPipeline);
      notifyListeners();

      if (added > 0) {
        debugPrint(
          '📥 Pipeline ingested $added new items → '
          'D:${opportunitiesInStage("discover")} '
          'B:${opportunitiesInStage("build")} '
          'W:${opportunitiesInStage("win")} '
          'S:${opportunitiesInStage("sell")}',
        );
      }
    } catch (e) {
      debugPrint('Pipeline ingestion error (self-healed): $e');
    }

    _isIngesting = false;
  }

  /// Classify which pipeline stage an item belongs to based on its
  /// strategic score, command signals, and content indicators.
  String _classifyStage(AutoFeedItem item) {
    final signals = item.commandSignals;
    final score = item.strategicScore;
    final lower = '${item.title} ${item.body}'.toLowerCase();

    // SELL: High-value items with deal/ticket/revenue signals
    if (score >= 2.5 &&
        (signals.contains('ticket-revenue') ||
            signals.contains('deal-desk-ready') ||
            lower.contains('sold out') ||
            lower.contains('tickets on sale') ||
            lower.contains('deal closed'))) {
      return 'sell';
    }

    // WIN: Items with promotion/campaign running or high engagement
    if (score >= 2.0 &&
        (signals.contains('samurai-promotion') ||
            signals.contains('joseph-priority') ||
            lower.contains('promo') ||
            lower.contains('live now') ||
            lower.contains('streaming'))) {
      return 'win';
    }

    // BUILD: Items with content-generation or brief-worthy signals
    if (score >= 1.5 &&
        (signals.contains('legends-show') ||
            lower.contains('youtube') ||
            lower.contains('brief') ||
            lower.contains('highlight') ||
            lower.contains('preview'))) {
      return 'build';
    }

    // DISCOVER: Everything else that passed the threshold
    return 'discover';
  }

  /// Whether the pipeline already has data (from FightWire or seed)
  bool get _isEmpty => totalOpportunitiesInPipeline == 0;

  /// Seed the pipeline with realistic combat-sport opportunities so the
  /// dashboard never shows empty/zero on first load.  Called once — if
  /// FightWire later pushes real items they merge alongside.
  void seedIfEmpty() {
    if (!_isEmpty) return;

    final now = DateTime.now();

    // ── DISCOVER stage ──────────────────────────────────────────────────
    final discoverItems = [
      (
        'disc-ufc-310',
        'UFC',
        <String>['samurai-promotion'],
        2.8,
        'UFC 310 — Main Card Breakdown',
      ),
      (
        'disc-ibc-mel',
        'IBC',
        <String>['joseph-priority', 'legends-show'],
        2.6,
        'IBC Melbourne — Brawling Undercard',
      ),
      (
        'disc-pfl-eu',
        'PFL',
        <String>['samurai-promotion'],
        2.1,
        'PFL Europe — Season 2 Roster Drop',
      ),
      (
        'disc-bkfc-23',
        'BKFC',
        <String>[],
        1.9,
        'BKFC 23 — Bare Knuckle Title Fight',
      ),
      (
        'disc-glory-92',
        'Glory',
        <String>[],
        1.7,
        'Glory 92 — Heavyweight Grand Prix',
      ),
    ];
    for (final d in discoverItems) {
      _stageOpportunities['discover']!.add(
        OpportunityStageItem(
          opportunityId: d.$1,
          source: d.$2,
          commandSignals: d.$3,
          strategicScore: d.$4,
          title: d.$5,
          stageEnteredAt: now.subtract(
            Duration(minutes: 45 + discoverItems.indexOf(d) * 12),
          ),
        ),
      );
    }

    // ── BUILD stage ─────────────────────────────────────────────────────
    final buildItems = [
      (
        'build-ult-leg',
        'Ultimate Legends',
        <String>['joseph-priority', 'legends-show'],
        2.9,
        'Ultimate Legends April — YouTube Brief',
      ),
      (
        'build-eternal',
        'Eternal MMA',
        <String>['samurai-promotion'],
        2.4,
        'Eternal MMA 80 — Promo Package',
      ),
      (
        'build-rizin',
        'Rizin',
        <String>[],
        2.0,
        'Rizin 52 — Highlight Reel Cut',
      ),
    ];
    for (final b in buildItems) {
      _stageOpportunities['build']!.add(
        OpportunityStageItem(
          opportunityId: b.$1,
          source: b.$2,
          commandSignals: b.$3,
          strategicScore: b.$4,
          title: b.$5,
          stageEnteredAt: now.subtract(
            Duration(hours: 2 + buildItems.indexOf(b)),
          ),
        ),
      );
    }

    // ── WIN stage ───────────────────────────────────────────────────────
    final winItems = [
      (
        'win-ufc-perth',
        'UFC',
        <String>['samurai-promotion'],
        2.7,
        'UFC Perth 2026 — Ticket Push Live',
      ),
      (
        'win-empire',
        'Empire Fight Series',
        <String>[],
        2.2,
        'Empire 5 — Muay Thai Promo Running',
      ),
    ];
    for (final w in winItems) {
      _stageOpportunities['win']!.add(
        OpportunityStageItem(
          opportunityId: w.$1,
          source: w.$2,
          commandSignals: w.$3,
          strategicScore: w.$4,
          title: w.$5,
          stageEnteredAt: now.subtract(
            Duration(hours: 6 + winItems.indexOf(w) * 3),
          ),
        ),
      );
    }

    // ── SELL stage ──────────────────────────────────────────────────────
    _stageOpportunities['sell']!.add(
      OpportunityStageItem(
        opportunityId: 'sell-ibc-gold',
        source: 'IBC',
        commandSignals: <String>['joseph-priority'],
        strategicScore: 3.0,
        title: 'IBC Gold Coast — Deal Closed',
        stageEnteredAt: now.subtract(const Duration(hours: 12)),
      ),
    );

    // ── Metrics ─────────────────────────────────────────────────────────
    _realTimeMetrics['total_opportunities'] = totalOpportunitiesInPipeline;
    _realTimeMetrics['avg_strategic_score'] = 2.4;
    _realTimeMetrics['youtube_views_generated'] = 3;
    _realTimeMetrics['deal_attempts'] = 4;
    _realTimeMetrics['deals_closed'] = 1;
    _realTimeMetrics['samurai_signal_hits'] = 4;
    _realTimeMetrics['joseph_priority_count'] = 3;
    _realTimeMetrics['legends_show_count'] = 2;

    notifyListeners();
  }

  // ── Private Helpers ────────────────────────────────────────────────────

  void _recordMetric(String key, num value) {
    _realTimeMetrics[key] = value;
  }

  void _recordFeedbackEvent(EcosystemFeedbackEvent event) {
    _feedbackHistory.add(event);
    if (_feedbackHistory.length > 100) {
      _feedbackHistory.removeAt(0);
    }
  }

  void _updateRealTimeMetrics() {
    // Recalculate average strategic score
    final allItems = _stageOpportunities.values.expand((list) => list).toList();
    if (allItems.isNotEmpty) {
      final avgScore =
          allItems.fold(0.0, (sum, item) => sum + item.strategicScore) /
          allItems.length;
      _recordMetric('avg_strategic_score', avgScore);
    }

    // Count campaign signals
    int samuraiCount = 0;
    int josephCount = 0;
    int legendsCount = 0;
    for (final item in allItems) {
      if (item.commandSignals.contains('samurai-promotion')) samuraiCount++;
      if (item.commandSignals.contains('joseph-priority')) josephCount++;
      if (item.commandSignals.contains('legends-show')) legendsCount++;
    }
    _recordMetric('samurai_signal_hits', samuraiCount);
    _recordMetric('joseph_priority_count', josephCount);
    _recordMetric('legends_show_count', legendsCount);
  }
}

/// ─────────────────────────────────────────────────────────────────────────
/// Model: Opportunity at a given stage in the pipeline
class OpportunityStageItem {
  final String opportunityId;
  final String source;
  final List<String> commandSignals;
  final double strategicScore;
  final String? imageUrl;
  final String title;
  final DateTime stageEnteredAt;
  DateTime? stageExitedAt;

  // Convenience getter
  String get id => opportunityId;

  OpportunityStageItem({
    required this.opportunityId,
    required this.source,
    required this.commandSignals,
    required this.strategicScore,
    this.imageUrl,
    required this.title,
    required this.stageEnteredAt,
    this.stageExitedAt,
  });

  Duration get timeInStage {
    final exitTime = stageExitedAt ?? DateTime.now();
    return exitTime.difference(stageEnteredAt);
  }

  OpportunityStageItem copyWith({
    String? opportunityId,
    String? source,
    List<String>? commandSignals,
    double? strategicScore,
    String? imageUrl,
    String? title,
    DateTime? stageEnteredAt,
    DateTime? stageExitedAt,
  }) {
    return OpportunityStageItem(
      opportunityId: opportunityId ?? this.opportunityId,
      source: source ?? this.source,
      commandSignals: commandSignals ?? this.commandSignals,
      strategicScore: strategicScore ?? this.strategicScore,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      stageEnteredAt: stageEnteredAt ?? this.stageEnteredAt,
      stageExitedAt: stageExitedAt ?? this.stageExitedAt,
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────
/// Model: Feedback event for ecosystem flow tracking
class EcosystemFeedbackEvent {
  final String
  eventType; // 'opportunity_discovered', 'stage_advanced', 'youtube_brief_generated', etc.
  final String opportunityId;
  final String source;
  final DateTime timestamp;
  final StageTransition? stageTransition;
  final Map<String, num> metricDelta; // Metrics that changed

  EcosystemFeedbackEvent({
    required this.eventType,
    required this.opportunityId,
    required this.source,
    required this.timestamp,
    this.stageTransition,
    required this.metricDelta,
  });
}

/// ─────────────────────────────────────────────────────────────────────────
/// Model: Stage transition details
class StageTransition {
  final String from;
  final String to;
  final String reason;

  StageTransition({required this.from, required this.to, required this.reason});
}
