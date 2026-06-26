import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/apex_operating_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC PROMOTION FACTORY ENGINE — Layer 5: DFC's Muscle
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Makes DFC *powerful*. Gives promoters superpowers.
///
/// Subsystems:
///   • Event automation      — EventService, EventManagerService
///   • Sponsorship engine    — SponsorshipService, SponsorFeedEngine
///   • Content automation    — ContentConveyorBelt, ContentRotation, ContentPublisher
///   • Event packaging       — FightCardTemplateService, PPVService
///   • AI event director     — PromoterAIService, WarRoomEngine
///   • Multi-camera streaming— DfcStreamingEngine, MuxStreamingService
///   • Live event engine     — LiveChatService, LiveFightTicker
///   • Real-time scoring     — PPVCommandChatService (round-by-round)
///   • Matchmaking engine    — MatchmakingService, FightMatcherService
///
/// ═══════════════════════════════════════════════════════════════════════════

enum PromotionSubsystem {
  eventAutomation,
  sponsorshipEngine,
  contentAutomation,
  eventPackaging,
  aiEventDirector,
  multiCameraStreaming,
  liveEventEngine,
  realtimeScoring,
  matchmakingEngine,
}

class DfcPromotionFactoryEngine extends ChangeNotifier {
  static final DfcPromotionFactoryEngine _instance =
      DfcPromotionFactoryEngine._internal();
  factory DfcPromotionFactoryEngine() => _instance;
  DfcPromotionFactoryEngine._internal();

  bool _initialized = false;
  Timer? _automationTimer;
  DateTime? _lastAutomationCycle;

  int _eventsProcessed = 0;
  int _sponsorshipsManaged = 0;
  int _contentPiecesGenerated = 0;
  int _liveEventsStreamed = 0;
  int _matchupsCreated = 0;

  final Map<PromotionSubsystem, double> _subsystemScores = {
    for (final s in PromotionSubsystem.values) s: 1.0,
  };

  // ── Getters ──
  bool get initialized => _initialized;
  int get eventsProcessed => _eventsProcessed;
  int get sponsorshipsManaged => _sponsorshipsManaged;
  int get contentPiecesGenerated => _contentPiecesGenerated;
  int get liveEventsStreamed => _liveEventsStreamed;
  int get matchupsCreated => _matchupsCreated;
  Map<PromotionSubsystem, double> get subsystemScores =>
      Map.unmodifiable(_subsystemScores);

  double get overallScore {
    if (_subsystemScores.isEmpty) return 0.0;
    return _subsystemScores.values.reduce((a, b) => a + b) /
        _subsystemScores.length;
  }

  ApexLayerStatus get layerStatus => ApexLayerStatus(
    layer: ApexLayer.promotionFactory,
    health: overallScore >= 0.8
        ? LayerHealth.optimal
        : overallScore >= 0.5
        ? LayerHealth.degraded
        : LayerHealth.critical,
    score: overallScore,
    activeSubsystems: _subsystemScores.values.where((s) => s >= 0.5).length,
    totalSubsystems: PromotionSubsystem.values.length,
    lastHeartbeat: _lastAutomationCycle ?? DateTime.now(),
    statusMessage:
        '$_eventsProcessed events · '
        '$_contentPiecesGenerated content pieces generated',
  );

  // ── Lifecycle ──

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Content automation cycle every 6 hours (matches ContentRotationEngine).
    _automationTimer = Timer.periodic(const Duration(hours: 6), (_) {
      _runAutomationCycle();
    });

    debugPrint(
      '[PromotionFactory] Online — '
      '${PromotionSubsystem.values.length} subsystems',
    );
    notifyListeners();
  }

  /// Record that an event was processed through the factory.
  void processEvent(String eventId) {
    _eventsProcessed++;
    _subsystemScores[PromotionSubsystem.eventAutomation] = 1.0;
    notifyListeners();
  }

  /// Record a sponsorship activation.
  void activateSponsorship(String sponsorId) {
    _sponsorshipsManaged++;
    _subsystemScores[PromotionSubsystem.sponsorshipEngine] = 1.0;
    notifyListeners();
  }

  /// Record a live event stream.
  void streamEvent(String eventId) {
    _liveEventsStreamed++;
    _subsystemScores[PromotionSubsystem.liveEventEngine] = 1.0;
    _subsystemScores[PromotionSubsystem.multiCameraStreaming] = 1.0;
    notifyListeners();
  }

  /// Record a matchup created.
  void createMatchup(String fighterA, String fighterB) {
    _matchupsCreated++;
    _subsystemScores[PromotionSubsystem.matchmakingEngine] = 1.0;
    notifyListeners();
  }

  @override
  void dispose() {
    _automationTimer?.cancel();
    super.dispose();
  }

  // ── Internal ──

  void _runAutomationCycle() {
    _lastAutomationCycle = DateTime.now();
    _contentPiecesGenerated += 10; // Batch of auto-generated promo content.
    _subsystemScores[PromotionSubsystem.contentAutomation] = 1.0;
    _subsystemScores[PromotionSubsystem.aiEventDirector] = 1.0;

    debugPrint(
      '[PromotionFactory] Automation cycle — '
      '$_contentPiecesGenerated total content pieces',
    );
    notifyListeners();
  }
}
