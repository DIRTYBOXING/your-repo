import 'dart:async';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/image_assets.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/models/ppv_model.dart';
import '../../../shared/services/promoter_settlement_snapshot_service.dart';
import '../../../shared/widgets/workflow_run_status_panel.dart';
import '../../../shared/services/services.dart' hide PPVEvent, PPVService;
import '../../ppv/services/ppv_service.dart';
import '../services/promoter_readiness_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PROMOTER CONTROL ROOM — SpaceX Mission Control Grade
///
/// Layout (3-column + telemetry + pipeline + footer):
///   ┌──────────────────────────────────────────────────────────┐
///   │  HEADER — event title, status pill, env selector, health │
///   ├──────────────────────────────────────────────────────────┤
///   │  TELEMETRY STRIP — 6 live gauges with sparkline graphs   │
///   ├──────────────────────────────────────────────────────────┤
///   │  PIPELINE HEARTBEAT — animated flow with pulse stages    │
///   ├─────────┬──────────────────────────┬─────────────────────┤
///   │  LEFT   │   CENTRE (Live Canvas)   │      RIGHT          │
///   │  Events │   Hero poster + actions  │  Console + systems  │
///   │  List   │   Quick-launch grid      │  Toggles + gauges   │
///   ├─────────┴──────────────────────────┴─────────────────────┤
///   │  FOOTER — audit trail (scrollable)                       │
///   └──────────────────────────────────────────────────────────┘
/// ═══════════════════════════════════════════════════════════════════════════

// ─── Local Colors ──────────────────────────────────────────────────
const _kCyan = DesignTokens.neonCyan;
const _kMagenta = DesignTokens.neonMagenta;
const _kGreen = DesignTokens.neonGreen;
const _kAmber = DesignTokens.neonAmber;
const _kRed = DesignTokens.neonRed;
const _kGold = DesignTokens.neonGold;
const _kBg = DesignTokens.bgPrimary;
const _kPanel = DesignTokens.bgSecondary;
const _kCard = DesignTokens.bgCard;

class PromoterControlRoomScreen extends StatefulWidget {
  const PromoterControlRoomScreen({
    super.key,
    this.promoterId,
    this.promoterName,
    this.initialEventId,
  });

  final String? promoterId;
  final String? promoterName;
  final String? initialEventId;

  @override
  State<PromoterControlRoomScreen> createState() =>
      _PromoterControlRoomScreenState();
}

class _PromoterControlRoomScreenState extends State<PromoterControlRoomScreen>
    with TickerProviderStateMixin {
  // ─── Services ────────────────────────────────────────────────────
  // ignore: unused_field
  final ContentPipelineService _pipeline = ContentPipelineService();
  // ignore: unused_field
  final ContentScannerEngine _scanner = ContentScannerEngine();
  // ignore: unused_field
  final WarRoomEngine _warRoom = WarRoomEngine();
  // ignore: unused_field
  final PromoterAIService _promoterAI = PromoterAIService();
  // ignore: unused_field
  final ContentPublisherService _publisher = ContentPublisherService();
  // ignore: unused_field
  final DfcSocialEngine _socialEngine = DfcSocialEngine();
  // ignore: unused_field
  final AutoFeedOrchestratorService _feedOrchestrator =
      AutoFeedOrchestratorService();
  final EventService _eventService = EventService();
  final PPVService _ppvService = PPVService();
  final PromoterReadinessService _readinessService = PromoterReadinessService();
  final PromoterSettlementSnapshotService _settlementService =
      PromoterSettlementSnapshotService();

  // ─── Animations ───────────────────────────────────────────────────
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;
  late final AnimationController _pipelineController;
  late final AnimationController _heartbeatController;
  late final AnimationController _gaugeController;

  // ─── Pipeline heartbeat data (simulated live telemetry) ───────────
  Timer? _telemetryTimer;
  final List<double> _ticketSalesData = [];
  final List<double> _revenueData = [];
  final List<double> _socialReachData = [];
  final List<double> _pipelineThroughputData = [];
  final List<double> _engagementData = [];
  final List<double> _conversionData = [];
  final _random = math.Random();

  // ─── State ────────────────────────────────────────────────────────
  String _environment = 'Production';
  int _selectedEventIndex = 0;
  bool _loading = true;
  bool _launchingStream = false;
  bool _resendingCredentials = false;
  String? _resolvedPromoterId;

  // System toggles (right panel) — expanded controls
  final Map<String, bool> _toggles = {
    'Content Crawler': true,
    'Social Bot': false,
    'Poster Engine': true,
    'Watchlist Monitor': true,
    'Auto-Boost': false,
    'Feed Orchestrator': true,
    'Ticket Scanner': true,
    'Revenue Tracker': true,
  };

  // Pipeline stage throughput (items/min)
  final Map<String, double> _pipelineStages = {
    'INTAKE': 0.0,
    'SCAN': 0.0,
    'TRANSFORM': 0.0,
    'QUEUE': 0.0,
    'DISTRIBUTE': 0.0,
    'TRACK': 0.0,
  };

  // Audit trail entries
  final List<_AuditEntry> _auditTrail = [];
  final Map<String, PromoterSettlementSnapshot> _settlementSnapshots = {};
  final Set<String> _settlementLoadingIds = <String>{};

  List<_ControlRoomEvent> _eventList = List<_ControlRoomEvent>.from(
    _demoEventList,
  );

  static final _demoEventList = <_ControlRoomEvent>[
    const _ControlRoomEvent(
      id: 'demo_event_16',
      name: 'Townsville Fight Show',
      date: 'Oct 25, 2026',
      status: _EventStatus.upcoming,
      headline: 'Aze Hepi vs Logan (QLD)',
      sport: 'BKFC',
      location: 'Townsville, Australia',
    ),
    const _ControlRoomEvent(
      id: 'demo_event_15',
      name: 'BKFC Townsville Debut',
      date: 'Apr 18, 2026',
      status: _EventStatus.upcoming,
      headline: 'Hepi vs Wisniewski',
      sport: 'BKFC',
      location: 'Townsville, Australia',
    ),
    _ControlRoomEvent(
      id: 'ultimate-legends-apr-2026',
      name: 'Ultimate Legends Test Lane — Jordan Roesler',
      date: 'Apr 24, 2026',
      status: _EventStatus.upcoming,
      headline: 'Jordan Roesler vs Conor Wallace',
      sport: 'Boxing',
      posterUrl: ImageAssets.ppvUltimateLegends2026Hero,
      location: 'Melbourne Pavilion, Melbourne, Australia',
      event: EventModel(
        id: 'ultimate-legends-apr-2026',
        promoterId: 'ultimate-legends',
        name: 'Ultimate Legends Fight Night: WBC Silver Australian Title',
        description:
            'Jordan Legends test lane for the promoter control room. Main event: Jordan Roesler vs Conor Wallace. Melbourne Pavilion, April 24 2026. Use this lane to validate PPV setup, stream credentials, playback, and replay flow before public event execution.',
        venue: 'Melbourne Pavilion',
        city: 'Melbourne',
        state: 'Victoria',
        country: 'Australia',
        eventDate: DateTime(2026, 4, 24, 18),
        mainCardTime: DateTime(2026, 4, 24, 18),
        sportType: 'boxing',
        posterUrl: ImageAssets.ppvUltimateLegends2026Hero,
        broadcastInfo: 'DFC PPV Test Lane / Mux rehearsal',
        ticketUrl: 'https://www.ultimatelegends.com.au',
        isFeatured: true,
        promotionName: 'Ultimate Legends Promotions',
      ),
    ),
    const _ControlRoomEvent(
      id: 'demo_event_3',
      name: 'Adelaide Combat Series 12',
      date: 'Mar 29, 2026',
      status: _EventStatus.upcoming,
      headline: 'Lucas vs Grima',
      sport: 'MMA',
      location: 'Adelaide, Australia',
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Health pill pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(_pulseController);

    // Pipeline flow animation (continuous)
    _pipelineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Heartbeat animation for pipeline nodes
    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // Gauge sweep animation
    _gaugeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Seed initial telemetry data
    _seedTelemetryData();

    // Start live telemetry timer (updates every 1.5s)
    _telemetryTimer = Timer.periodic(
      const Duration(milliseconds: 1500),
      (_) => _updateTelemetry(),
    );

    // Seed audit trail
    _auditTrail.addAll([
      const _AuditEntry(
        time: '14:32',
        action: 'Poster generated for Townsville Fight Show',
        type: _AuditType.info,
      ),
      const _AuditEntry(
        time: '14:28',
        action: 'Social post queued — Instagram + Facebook',
        type: _AuditType.success,
      ),
      const _AuditEntry(
        time: '14:15',
        action: 'Crawler scan complete — 3 new articles indexed',
        type: _AuditType.info,
      ),
      const _AuditEntry(
        time: '13:50',
        action: 'Watchlist alert: ticket sales threshold 80%',
        type: _AuditType.warning,
      ),
      const _AuditEntry(
        time: '13:20',
        action: 'Auto-Boost paused — budget limit reached',
        type: _AuditType.error,
      ),
    ]);

    _loadControlRoomData();
  }

  _ControlRoomEvent? get _selectedEvent {
    if (_eventList.isEmpty) return null;
    if (_selectedEventIndex < 0 || _selectedEventIndex >= _eventList.length) {
      _selectedEventIndex = 0;
    }
    return _eventList[_selectedEventIndex];
  }

  Future<void> _loadControlRoomData() async {
    final promoterId =
        widget.promoterId ?? FirebaseAuth.instance.currentUser?.uid;

    if (promoterId == null || promoterId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _resolvedPromoterId = null;
        _loading = false;
      });
      final fallbackEvent = _selectedEvent;
      if (fallbackEvent != null) {
        unawaited(_loadSettlementSnapshot(fallbackEvent, forceRefresh: true));
      }
      return;
    }

    final upcoming = await _eventService.getUpcomingEvents(limit: 40);
    final live = await _eventService.getLiveEvents();

    final byId = <String, EventModel>{
      for (final event in [...live, ...upcoming])
        if (event.promoterId == promoterId) event.id: event,
    };

    final events = byId.values.toList()
      ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

    final fallbackDemoEvents = _demoEventList
        .where((event) {
          final matchesInitialEvent =
              widget.initialEventId != null &&
              event.id == widget.initialEventId;
          final matchesPromoter =
              promoterId.isNotEmpty && event.event?.promoterId == promoterId;
          return matchesInitialEvent || matchesPromoter;
        })
        .toList(growable: false);

    if (events.isEmpty) {
      if (!mounted) return;
      final selectedIndex = fallbackDemoEvents.indexWhere(
        (event) => event.id == widget.initialEventId,
      );
      setState(() {
        _resolvedPromoterId = promoterId;
        _eventList = fallbackDemoEvents;
        _selectedEventIndex = selectedIndex >= 0 ? selectedIndex : 0;
        if (fallbackDemoEvents.isNotEmpty) {
          _syncTelemetryToEvent(fallbackDemoEvents[_selectedEventIndex]);
        }
        _loading = false;
      });
      if (fallbackDemoEvents.isNotEmpty) {
        unawaited(
          _loadSettlementSnapshot(
            fallbackDemoEvents[_selectedEventIndex],
            forceRefresh: true,
          ),
        );
      }
      return;
    }

    final resolvedEvents = <_ControlRoomEvent>[];
    for (final event in events) {
      final ppvEvent = await _ppvService.getPPVEventForEventId(
        event.id,
        promoterId: promoterId,
      );
      final readiness = await _readinessService.getPromoterReadiness(
        promoterId: promoterId,
        eventId: event.id,
      );
      resolvedEvents.add(
        _ControlRoomEvent.fromData(event, ppvEvent, readiness),
      );
    }

    int selectedIndex = 0;
    if (widget.initialEventId != null && widget.initialEventId!.isNotEmpty) {
      final idx = resolvedEvents.indexWhere(
        (event) => event.id == widget.initialEventId,
      );
      if (idx >= 0) {
        selectedIndex = idx;
      }
    }

    if (!mounted) return;
    setState(() {
      _resolvedPromoterId = promoterId;
      _eventList = resolvedEvents;
      _selectedEventIndex = selectedIndex;
      _syncTelemetryToEvent(resolvedEvents[selectedIndex]);
      _loading = false;
    });
    unawaited(
      _loadSettlementSnapshot(
        resolvedEvents[selectedIndex],
        forceRefresh: true,
      ),
    );
  }

  Future<void> _refreshSelectedEvent() async {
    final selectedEvent = _selectedEvent;
    final promoterId = _resolvedPromoterId;
    if (selectedEvent?.event == null ||
        promoterId == null ||
        promoterId.isEmpty) {
      return;
    }

    final event = await _eventService.getEvent(selectedEvent!.event!.id);
    if (event == null || !mounted) return;

    final ppvEvent = await _ppvService.getPPVEventForEventId(
      event.id,
      promoterId: promoterId,
    );
    final readiness = await _readinessService.getPromoterReadiness(
      promoterId: promoterId,
      eventId: event.id,
    );
    final refreshed = _ControlRoomEvent.fromData(event, ppvEvent, readiness);

    setState(() {
      _eventList[_selectedEventIndex] = refreshed;
      _syncTelemetryToEvent(refreshed);
    });
    unawaited(_loadSettlementSnapshot(refreshed, forceRefresh: true));
  }

  void _selectEvent(int index) {
    if (index < 0 || index >= _eventList.length) return;
    setState(() {
      _selectedEventIndex = index;
      _syncTelemetryToEvent(_eventList[index]);
    });
    unawaited(_loadSettlementSnapshot(_eventList[index]));
  }

  Future<void> _loadSettlementSnapshot(
    _ControlRoomEvent event, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _settlementSnapshots.containsKey(event.id)) {
      return;
    }
    if (_settlementLoadingIds.contains(event.id)) {
      return;
    }

    setState(() {
      _settlementLoadingIds.add(event.id);
    });

    try {
      final snapshot = await _settlementService.getSnapshot(
        eventId: event.id,
        ppvEvent: event.ppvEvent,
        fallbackEventName: event.event?.name ?? event.name,
        fallbackVenue: event.location,
        fallbackEventDate: event.event?.eventDate,
        fallbackPromoterName: event.event?.promotionName,
      );
      if (!mounted) return;
      setState(() {
        _settlementSnapshots[event.id] = snapshot;
        _settlementLoadingIds.remove(event.id);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _settlementLoadingIds.remove(event.id);
      });
    }
  }

  Future<void> _launchStreamForSelectedEvent() async {
    final selectedEvent = _selectedEvent;
    final promoterId = _resolvedPromoterId;
    if (selectedEvent?.event == null ||
        promoterId == null ||
        promoterId.isEmpty) {
      return;
    }

    final readiness = selectedEvent!.readiness;
    if (readiness != null && !readiness.eventCanGoLive) {
      final blocker = readiness.blockers.isNotEmpty
          ? readiness.blockers.first
          : 'Commercial readiness checks are not complete';
      _addAudit('Go-live blocked: $blocker', _AuditType.warning);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(blocker)));
      return;
    }

    setState(() => _launchingStream = true);
    try {
      var ppvEvent = selectedEvent.ppvEvent;
      if (ppvEvent == null) {
        final ppvEventId = await _ppvService.createPPVEvent(
          eventId: selectedEvent.event!.id,
          title: selectedEvent.event!.name,
          description:
              selectedEvent.event!.description ??
              'Live PPV stream for ${selectedEvent.event!.name}',
          eventDate: selectedEvent.event!.eventDate,
          standardPriceCents: 2999,
          posterUrl: selectedEvent.event!.primaryPosterUrl,
          sport: selectedEvent.event!.sportType,
          promotion: selectedEvent.event!.promotionName,
        );
        ppvEvent = await _ppvService.getPPVEvent(ppvEventId);
      }

      if (ppvEvent == null) {
        throw Exception('Unable to create a PPV event for this broadcast');
      }

      final config = await MuxStreamingService.createLiveStream(
        ppvEventId: ppvEvent.id,
        title: ppvEvent.title,
        testMode: _environment != 'Production',
      );

      if (config == null) {
        throw Exception('Unable to provision stream credentials');
      }

      _addAudit(
        config.isRehearsalMode
            ? 'Rehearsal stream credentials issued for ${selectedEvent.name}'
            : 'Stream credentials issued for ${selectedEvent.name}',
        _AuditType.success,
      );
      _addAudit(
        config.credentialsSent
            ? 'Credential pack sent to ${config.credentialDeliveryRecipient}'
            : 'Credential delivery needs follow-up: ${config.credentialDeliveryLabel}',
        config.credentialsSent ? _AuditType.success : _AuditType.warning,
      );
      if (mounted) {
        final snackMessage = config.isRehearsalMode
            ? (config.credentialsSent
                  ? 'Rehearsal lane ready and credential pack sent to ${config.credentialDeliveryRecipient}.'
                  : 'Rehearsal mode ready. Credential pack created, but operator follow-up is required.')
            : (config.credentialsSent
                  ? 'Stream credentials created and sent to ${config.credentialDeliveryRecipient}.'
                  : 'Stream credentials created. Email delivery needs operator follow-up.');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(snackMessage)));
      }
      await _refreshSelectedEvent();
    } catch (e) {
      _addAudit('Go-live failed: $e', _AuditType.error);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create stream: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _launchingStream = false);
      }
    }
  }

  Future<void> _disableSelectedStream() async {
    final streamDocId = _selectedEvent?.ppvEvent?.muxStreamId;
    if (streamDocId == null || streamDocId.isEmpty) return;

    final ok = await MuxStreamingService.disableStream(streamDocId);
    _addAudit(
      ok ? 'Stream disabled by operator' : 'Disable stream failed',
      ok ? _AuditType.warning : _AuditType.error,
    );
    if (ok) {
      await _refreshSelectedEvent();
    }
  }

  Future<void> _resendCredentialPackForSelectedEvent() async {
    final streamDocId = _selectedEvent?.ppvEvent?.muxStreamId;
    if (streamDocId == null || streamDocId.isEmpty) {
      return;
    }

    setState(() => _resendingCredentials = true);
    try {
      final delivery = await MuxStreamingService.resendCredentialPack(
        streamDocId,
      );
      final label = delivery?.label ?? 'Delivery pending';
      _addAudit(
        delivery?.sent == true
            ? 'Credential pack resent to ${delivery!.recipient}'
            : 'Credential resend needs follow-up: $label',
        delivery?.sent == true ? _AuditType.success : _AuditType.warning,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(label)));
      await _refreshSelectedEvent();
    } catch (e) {
      _addAudit('Credential resend failed: $e', _AuditType.error);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Credential resend failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _resendingCredentials = false);
      }
    }
  }

  Widget _buildPosterVisual(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPosterPlaceholder();
    }

    final isNetwork =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
    final image = isNetwork
        ? Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildPosterPlaceholder(),
          )
        : Image.asset(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildPosterPlaceholder(),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      child: image,
    );
  }

  Widget _buildPosterPlaceholder() {
    final selectedEvent = _selectedEvent;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kPanel, _kBg],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_size_select_actual_outlined,
              color: _kCyan.withValues(alpha: 0.3),
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'EVENT POSTER',
              style: TextStyle(
                color: _kCyan.withValues(alpha: 0.4),
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              selectedEvent?.name ?? 'No Event Selected',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _seedTelemetryData() {
    final initialEvent = _eventList.isNotEmpty ? _eventList.first : null;
    _syncTelemetryToEvent(initialEvent);
  }

  void _updateTelemetry() {
    if (!mounted) return;
    setState(() {
      _appendTelemetryTick(_selectedEvent);
    });
  }

  void _syncTelemetryToEvent(_ControlRoomEvent? event) {
    _ticketSalesData
      ..clear()
      ..addAll(_buildTelemetrySeries(_ticketBase(event), 12, 30));
    _revenueData
      ..clear()
      ..addAll(_buildTelemetrySeries(_revenueBase(event), 12, 24));
    _socialReachData
      ..clear()
      ..addAll(_buildTelemetrySeries(_reachBase(event), 12, 16));
    _pipelineThroughputData
      ..clear()
      ..addAll(_buildTelemetrySeries(_pipelineBase(event), 12, 8));
    _engagementData
      ..clear()
      ..addAll(_buildTelemetrySeries(_engagementBase(event), 12, 10));
    _conversionData
      ..clear()
      ..addAll(_buildTelemetrySeries(_conversionBase(event), 12, 6));

    _pipelineStages['INTAKE'] = _pipelineBase(event);
    _pipelineStages['SCAN'] = _readinessPercent(event) * 100;
    _pipelineStages['TRANSFORM'] = (_engagementBase(event) + 8).clamp(5, 100);
    _pipelineStages['QUEUE'] = (_conversionBase(event) * 1.8).clamp(5, 100);
    _pipelineStages['DISTRIBUTE'] = (_reachBase(event) * 0.92).clamp(5, 100);
    _pipelineStages['TRACK'] = (_ticketBase(event) / 1.2).clamp(5, 100);
  }

  void _appendTelemetryTick(_ControlRoomEvent? event) {
    void push(List<double> list, double base, double variance) {
      list.add(
        (base + (_random.nextDouble() * variance) - variance / 2)
            .clamp(0, 999999)
            .toDouble(),
      );
      if (list.length > 30) list.removeAt(0);
    }

    push(_ticketSalesData, _ticketBase(event), 8);
    push(_revenueData, _revenueBase(event), 5);
    push(_socialReachData, _reachBase(event), 4);
    push(_pipelineThroughputData, _pipelineBase(event), 3);
    push(_engagementData, _engagementBase(event), 4);
    push(_conversionData, _conversionBase(event), 2);

    for (final key in _pipelineStages.keys) {
      _pipelineStages[key] =
          (_pipelineStages[key]! + (_random.nextDouble() * 3 - 1.5)).clamp(
            5,
            100,
          );
    }
  }

  List<double> _buildTelemetrySeries(double base, int count, double variance) {
    return List<double>.generate(count, (index) {
      final drift = (count - index) * 0.45;
      return (base - drift + (_random.nextDouble() * variance) - variance / 2)
          .clamp(0, 999999)
          .toDouble();
    });
  }

  double _ticketBase(_ControlRoomEvent? event) {
    final purchases = event?.ppvEvent?.purchaseCount ?? 0;
    return purchases <= 0 ? 12 : purchases.toDouble().clamp(12, 100);
  }

  double _revenueBase(_ControlRoomEvent? event) {
    final revenue = event?.ppvEvent?.totalRevenue ?? 0;
    return revenue <= 0 ? 18 : (revenue / 150).clamp(18, 100).toDouble();
  }

  double _reachBase(_ControlRoomEvent? event) {
    final imageCount = event?.event?.imageIds.length ?? 0;
    final sponsorCount = event?.event?.sponsors.length ?? 0;
    final posterReady = event?.readiness?.mediaReady == true ? 18 : 0;
    return (28 + imageCount * 8 + sponsorCount * 10 + posterReady)
        .clamp(10, 100)
        .toDouble();
  }

  double _pipelineBase(_ControlRoomEvent? event) {
    return (55 + _readinessPercent(event) * 35).clamp(10, 100).toDouble();
  }

  double _engagementBase(_ControlRoomEvent? event) {
    final fightCount =
        event?.ppvEvent?.fightCard.length ?? event?.event?.fightIds.length ?? 0;
    final liveBoost = event?.status == _EventStatus.live ? 12 : 0;
    return (32 + fightCount * 6 + liveBoost).clamp(10, 100).toDouble();
  }

  double _conversionBase(_ControlRoomEvent? event) {
    final hasPpv = event?.ppvEvent != null ? 18 : 0;
    final hasStream = event?.ppvEvent?.muxStreamId?.isNotEmpty == true ? 14 : 0;
    return (12 + hasPpv + hasStream + _readinessPercent(event) * 30)
        .clamp(5, 100)
        .toDouble();
  }

  double _readinessPercent(_ControlRoomEvent? event) {
    final readiness = event?.readiness;
    if (readiness == null) return 0.25;

    var score = 0.0;
    if (readiness.profile.allTermsAccepted) score += 0.25;
    if (readiness.stripeReady) score += 0.25;
    if (readiness.mediaReady) score += 0.25;
    if (readiness.licenseCleared) score += 0.25;
    return score.clamp(0, 1);
  }

  String _compactCount(num value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  String _currencyShort(num value) {
    if (value >= 1000000) return '\$${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '\$${(value / 1000).toStringAsFixed(1)}K';
    return '\$${value.toStringAsFixed(0)}';
  }

  double _fillPercentFromSeries(List<double> values) {
    if (values.isEmpty) return 0.1;
    final latest = values.last;
    final maxValue = values.reduce(math.max);
    if (maxValue <= 0) return 0.1;
    return (latest / maxValue).clamp(0.08, 1.0);
  }

  String _currencyExact(num value) => '\$${value.toStringAsFixed(2)}';

  String _buildOperatorProofBrief(_ControlRoomEvent event) {
    final readiness = event.readiness;
    final settlement = _settlementSnapshots[event.id];
    final ppvEvent = event.ppvEvent;

    final foundationStates = <String>[
      'Event lane: ${event.event != null ? 'READY' : 'FALLBACK'}',
      'PPV lane: ${ppvEvent != null ? 'READY' : 'PENDING'}',
      'Stream credentials: ${(ppvEvent?.muxStreamId?.isNotEmpty == true || (ppvEvent?.streamUrl?.isNotEmpty == true)) ? 'ARMED' : 'PENDING'}',
      'Rights gate: ${readiness?.licenseCleared == true ? 'CLEARED' : 'PENDING'}',
      'Commercial gate: ${readiness?.eventCanGoLive == true ? 'GREEN' : 'BLOCKED'}',
      'Settlement proof: ${settlement?.confidenceLabel ?? 'SYNCING'}',
    ];

    final blockers = <String>[
      if (readiness != null && readiness.blockers.isNotEmpty)
        ...readiness.blockers.take(3)
      else if (ppvEvent?.muxStreamId?.isNotEmpty == true)
        'Live Mux credentials are armed for production broadcast.'
      else if (ppvEvent?.streamUrl?.isNotEmpty == true)
        'Rehearsal stream lane exists without Mux credentials.'
      else
        'No active blockers recorded in this snapshot.',
    ];

    return '''
DFC CONTROL ROOM PROOF
======================
Event: ${event.event?.name ?? event.name}
Headline: ${event.headline}
Location: ${event.location}
Date: ${event.date}

FOUNDATIONS
-----------
${foundationStates.join('\n')}

COMMERCIAL READINESS
--------------------
Stripe ready: ${readiness?.stripeReady == true ? 'YES' : 'NO'}
Media ready: ${readiness?.mediaReady == true ? 'YES' : 'NO'}
Rights cleared: ${readiness?.licenseCleared == true ? 'YES' : 'NO'}
Go-live allowed: ${readiness?.eventCanGoLive == true ? 'YES' : 'NO'}

SETTLEMENT
----------
Confidence: ${settlement?.confidenceLabel ?? 'SYNCING'}
Gross sales: ${_currencyExact(settlement?.grossSales ?? 0)}
Payable now: ${_currencyExact(settlement?.payableNow ?? 0)}
Verified buys: ${settlement?.totalPurchases ?? 0}
Refunds: ${settlement?.refundedPurchases ?? 0}
Revenue variance: ${_currencyExact((settlement?.revenueShareDelta ?? 0).abs())}
Payout status: ${settlement?.payoutStatusLabel ?? 'Awaiting Sync'}

BLOCKERS
--------
${blockers.map((blocker) => '- $blocker').join('\n')}
''';
  }

  Future<void> _copyOperatorProofBrief(_ControlRoomEvent event) async {
    await Clipboard.setData(
      ClipboardData(text: _buildOperatorProofBrief(event)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Control room proof brief copied')),
    );
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    _pulseController.dispose();
    _pipelineController.dispose();
    _heartbeatController.dispose();
    _gaugeController.dispose();
    super.dispose();
  }

  void _addAudit(String action, _AuditType type) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    setState(() {
      _auditTrail.insert(
        0,
        _AuditEntry(time: time, action: action, type: type),
      );
    });
  }

  // ─── BUILD ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 900;

    return Scaffold(
      backgroundColor: _kBg,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_kCyan),
              ),
            )
          : SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showTelemetry = constraints.maxHeight > 500;
                  return Column(
                    children: [
                      _buildHeader(),
                      if (showTelemetry) _buildTelemetryStrip(),
                      if (showTelemetry) _buildPipelineHeartbeat(),
                      Expanded(
                        child: isNarrow
                            ? _buildNarrowLayout()
                            : _buildWideLayout(),
                      ),
                      _buildAuditTrail(),
                    ],
                  );
                },
              ),
            ),
    );
  }

  // ═══ TELEMETRY STRIP — 6 live gauges with sparklines ═══════════════
  Widget _buildTelemetryStrip() {
    final selectedEvent = _selectedEvent;
    final ppvEvent = selectedEvent?.ppvEvent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kPanel.withValues(alpha: 0.7),
        border: Border(
          bottom: BorderSide(color: _kCyan.withValues(alpha: 0.08)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _telemetryGauge(
              'BUYERS',
              _compactCount((ppvEvent?.purchaseCount ?? 0).toDouble()),
              _ticketSalesData,
              _kGreen,
              _fillPercentFromSeries(_ticketSalesData),
            ),
            const SizedBox(width: 6),
            _telemetryGauge(
              'GROSS',
              _currencyShort(ppvEvent?.totalRevenue ?? 0),
              _revenueData,
              _kGold,
              _fillPercentFromSeries(_revenueData),
            ),
            const SizedBox(width: 6),
            _telemetryGauge(
              'ASSETS',
              '${selectedEvent?.event?.imageIds.length ?? 0}/${(selectedEvent?.event?.sponsors.length ?? 0) + (selectedEvent?.event?.imageIds.length ?? 0)}',
              _socialReachData,
              _kCyan,
              _fillPercentFromSeries(_socialReachData),
            ),
            const SizedBox(width: 6),
            _telemetryGauge(
              'READY',
              '${(_readinessPercent(selectedEvent) * 100).round()}%',
              _pipelineThroughputData,
              _kMagenta,
              _fillPercentFromSeries(_pipelineThroughputData),
            ),
            const SizedBox(width: 6),
            _telemetryGauge(
              'FIGHTS',
              _compactCount(
                ((ppvEvent?.fightCard.length ?? 0) > 0
                        ? ppvEvent!.fightCard.length
                        : (selectedEvent?.event?.fightIds.length ?? 0))
                    .toDouble(),
              ),
              _engagementData,
              _kAmber,
              _fillPercentFromSeries(_engagementData),
            ),
            const SizedBox(width: 6),
            _telemetryGauge(
              'STREAM',
              ppvEvent?.muxStreamId?.isNotEmpty == true
                  ? 'ARMED'
                  : (ppvEvent?.streamUrl?.isNotEmpty == true
                        ? 'REHEARSE'
                        : 'IDLE'),
              _conversionData,
              _kRed,
              _fillPercentFromSeries(_conversionData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _telemetryGauge(
    String label,
    String value,
    List<double> data,
    Color accent,
    double fillPercent,
  ) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Mini arc gauge
              SizedBox(
                width: 28,
                height: 28,
                child: AnimatedBuilder(
                  animation: _gaugeController,
                  builder: (_, _) => CustomPaint(
                    painter: _MiniGaugePainter(
                      percent:
                          fillPercent + (_gaugeController.value * 0.03 - 0.015),
                      color: accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: accent.withValues(alpha: 0.7),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        color: accent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Mini sparkline
          SizedBox(
            height: 22,
            width: double.infinity,
            child: data.length >= 2
                ? LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: data
                              .asMap()
                              .entries
                              .map((e) => FlSpot(e.key.toDouble(), e.value))
                              .toList(),
                          isCurved: true,
                          color: accent,
                          barWidth: 1.5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                accent.withValues(alpha: 0.2),
                                accent.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ═══ PIPELINE HEARTBEAT — animated flow between stages ═════════════
  Widget _buildPipelineHeartbeat() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _kBg,
        border: Border(
          bottom: BorderSide(color: _kMagenta.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.monitor_heart_outlined,
                color: _kMagenta.withValues(alpha: 0.6),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'PIPELINE HEARTBEAT',
                style: TextStyle(
                  color: _kMagenta.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _heartbeatController,
                builder: (_, _) => Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(
                      alpha: 0.4 + _heartbeatController.value * 0.6,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _kGreen.withValues(
                          alpha: _heartbeatController.value * 0.3,
                        ),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE',
                style: TextStyle(
                  color: _kGreen.withValues(alpha: 0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedBuilder(
                  animation: _pipelineController,
                  builder: (_, _) => CustomPaint(
                    size: Size(constraints.maxWidth, 48),
                    painter: _PipelineFlowPainter(
                      stages: _pipelineStages,
                      progress: _pipelineController.value,
                      heartbeat: _heartbeatController.value,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══ HEADER ══════════════════════════════════════════════════════════
  Widget _buildHeader() {
    final ev = _selectedEvent;
    final isNarrow = MediaQuery.of(context).size.width < 700;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        color: _kPanel,
        border: Border(
          bottom: BorderSide(color: _kCyan.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white70,
              size: 16,
            ),
            onPressed: () => context.pop(),
            tooltip: 'Back',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 6),
          // Title + headline
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isNarrow ? 'CONTROL ROOM' : 'PROMOTER CONTROL ROOM',
                        style: DFCTextStyles.title.copyWith(
                          fontSize: isNarrow ? 13 : 15,
                          letterSpacing: 1.2,
                          color: _kCyan,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusPill(ev?.status ?? _EventStatus.upcoming),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  ev == null
                      ? (widget.promoterName ??
                            'Load promoter events to start broadcast ops')
                      : '${ev.name} — ${ev.headline}',
                  style: DFCTextStyles.body.copyWith(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!isNarrow) ...[_envSelector(), const SizedBox(width: 8)],
          // Global health pill
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, a) => _healthPill(),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(_EventStatus status) {
    final Color c;
    final String label;
    switch (status) {
      case _EventStatus.live:
        c = _kGreen;
        label = 'LIVE';
      case _EventStatus.upcoming:
        c = _kAmber;
        label = 'UPCOMING';
      case _EventStatus.completed:
        c = Colors.white38;
        label = 'COMPLETED';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _envSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _environment,
          dropdownColor: _kPanel,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white38,
            size: 16,
          ),
          isDense: true,
          items: const [
            DropdownMenuItem(value: 'Production', child: Text('Production')),
            DropdownMenuItem(value: 'Staging', child: Text('Staging')),
            DropdownMenuItem(value: 'Demo', child: Text('Demo')),
          ],
          onChanged: (v) {
            if (v != null) {
              setState(() => _environment = v);
              _addAudit('Environment switched to $v', _AuditType.info);
            }
          },
        ),
      ),
    );
  }

  Widget _healthPill() {
    final readiness = _selectedEvent?.readiness;
    final isReady = readiness?.eventCanGoLive ?? false;
    final isChecking = readiness == null && _loading;
    final color = isChecking ? _kCyan : (isReady ? _kGreen : _kAmber);
    final label = isChecking
        ? 'CHECKING'
        : (isReady ? 'READY TO GO LIVE' : 'BLOCKED');
    return Opacity(
      opacity: _pulseAnim.value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══ WIDE LAYOUT (3 columns) ═════════════════════════════════════════
  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // LEFT — Event List
        SizedBox(width: 240, child: _buildEventList()),
        // Divider
        Container(width: 1, color: _kCyan.withValues(alpha: 0.08)),
        // CENTRE — Live Event Canvas
        Expanded(flex: 3, child: _buildLiveCanvas()),
        // Divider
        Container(width: 1, color: _kCyan.withValues(alpha: 0.08)),
        // RIGHT — Promoter Console
        SizedBox(width: 280, child: _buildConsolePanel()),
      ],
    );
  }

  // ═══ NARROW LAYOUT (stacked for mobile) ═══════════════════════════
  Widget _buildNarrowLayout() {
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      children: [
        // Horizontal event chip bar
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _eventList.length,
            separatorBuilder: (_, i) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final ev = _eventList[i];
              final selected = i == _selectedEventIndex;
              return ChoiceChip(
                label: SizedBox(
                  width: 148,
                  child: Text(
                    ev.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                selected: selected,
                selectedColor: _kCyan.withValues(alpha: 0.2),
                backgroundColor: _kCard,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                side: BorderSide(
                  color: selected
                      ? _kCyan.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.1),
                ),
                labelStyle: TextStyle(
                  color: selected ? _kCyan : Colors.white60,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
                onSelected: (_) => _selectEvent(i),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildLiveCanvas(),
        const SizedBox(height: 16),
        _buildConsolePanel(),
      ],
    );
  }

  // ═══ LEFT PANEL — Event List ═════════════════════════════════════════
  Widget _buildEventList() {
    return Container(
      color: _kPanel.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'EVENTS',
              style: TextStyle(
                color: _kCyan.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Expanded(
            child: _eventList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No promoter events found yet. Create an event, complete rights intake, and come back here to issue stream credentials.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _eventList.length,
                    itemBuilder: (context, i) {
                      final ev = _eventList[i];
                      final selected = i == _selectedEventIndex;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusSmall,
                            ),
                            onTap: () => _selectEvent(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? _kCyan.withValues(alpha: 0.08)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  DesignTokens.radiusSmall,
                                ),
                                border: Border.all(
                                  color: selected
                                      ? _kCyan.withValues(alpha: 0.3)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      _sportBadge(ev.sport),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          ev.name,
                                          style: TextStyle(
                                            color: selected
                                                ? Colors.white
                                                : Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${ev.date}  •  ${ev.headline}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.4,
                                      ),
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (ev.location != null &&
                                      ev.location!.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      ev.location!,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.28,
                                        ),
                                        fontSize: 10,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sportBadge(String sport) {
    final Color c;
    switch (sport.toUpperCase()) {
      case 'BKFC':
        c = _kRed;
      case 'MMA':
        c = _kCyan;
      case 'BOXING':
        c = _kGold;
      default:
        c = _kAmber;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Text(
        sport,
        style: TextStyle(
          color: c,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ═══ CENTRE — Live Event Canvas ═══════════════════════════════════
  Widget _buildLiveCanvas() {
    final ev = _selectedEvent;
    if (ev == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Control room will populate once this promoter has at least one live or upcoming event.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero poster area ──
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 260),
            decoration: GlassDecoration.card(hasGlow: true),
            child: Stack(
              children: [
                // Poster placeholder
                Positioned.fill(
                  child: _buildPosterVisual(
                    ev.event?.primaryPosterUrl ?? ev.posterUrl,
                  ),
                ),
                // Status badge overlay
                Positioned(top: 12, right: 12, child: _statusPill(ev.status)),
                // Date overlay
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ev.date,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Action Strip ──
          Text(
            'ACTIONS',
            style: TextStyle(
              color: _kCyan.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _actionButton(
                icon: Icons.live_tv,
                label: ev.ppvEvent == null
                    ? 'Create PPV Lane'
                    : 'Refresh PPV Lane',
                color: _kRed,
                onTap: _launchingStream ? () {} : _launchStreamForSelectedEvent,
              ),
              _actionButton(
                icon: Icons.verified_user_outlined,
                label: 'Rights Intake',
                color: _kAmber,
                onTap: () {
                  context.push(
                    '/promoter/rights-intake?eventId=${Uri.encodeComponent(ev.id)}${ev.ppvEvent != null ? '&ppvEventId=${Uri.encodeComponent(ev.ppvEvent!.id)}' : ''}',
                  );
                },
              ),
              _actionButton(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Settlement',
                color: _kGold,
                onTap: () {
                  context.push('/promoter/reconciliation', extra: ev.id);
                },
              ),
              _actionButton(
                icon: Icons.brush_outlined,
                label: 'Create Poster',
                color: _kMagenta,
                onTap: () {
                  _addAudit(
                    'Poster creation started for ${ev.name}',
                    _AuditType.info,
                  );
                  context.push(
                    '/promoter/poster-generator'
                    '?event=${Uri.encodeComponent(ev.name)}'
                    '&date=${Uri.encodeComponent(ev.date)}'
                    '&sport=${Uri.encodeComponent(ev.sport)}',
                  );
                },
              ),
              _actionButton(
                icon: Icons.outgoing_mail,
                label: 'Outreach HQ',
                color: _kCyan,
                onTap: () {
                  _addAudit(
                    'Outreach HQ opened for ${ev.name}',
                    _AuditType.info,
                  );
                  context.push('/promoter-outreach-hq');
                },
              ),
              _actionButton(
                icon: Icons.share_outlined,
                label: 'Push Social',
                color: _kGreen,
                onTap: () {
                  _addAudit(
                    'Social post preview opened for ${ev.name}',
                    _AuditType.info,
                  );
                  context.push(
                    '/facebook-post-preview'
                    '?event=${Uri.encodeComponent(ev.name)}'
                    '&date=${Uri.encodeComponent(ev.date)}',
                  );
                },
              ),
              _actionButton(
                icon: Icons.link,
                label: 'UTM Builder',
                color: _kAmber,
                onTap: () {
                  _addAudit(
                    'UTM builder opened for ${ev.name}',
                    _AuditType.info,
                  );
                  context.push('/utm-link-builder');
                },
              ),
              _actionButton(
                icon: Icons.calculate_outlined,
                label: 'Cost Estimator',
                color: _kGold,
                onTap: () {
                  _addAudit(
                    'Cost estimator opened for ${ev.name}',
                    _AuditType.info,
                  );
                  context.push('/marketing-cost-estimator');
                },
              ),
              _actionButton(
                icon: Icons.gavel,
                label: 'Contracts',
                color: DesignTokens.neonGreen,
                onTap: () {
                  _addAudit(
                    'Contract calculator opened for ${ev.name}',
                    _AuditType.info,
                  );
                  context.push('/sliding-contract-calculator');
                },
              ),
              _actionButton(
                icon: Icons.handshake,
                label: 'Deal Pipeline',
                color: DesignTokens.neonMagenta,
                onTap: () {
                  _addAudit('Deal pipeline opened', _AuditType.info);
                  context.push('/deal-pipeline');
                },
              ),
              _actionButton(
                icon: Icons.hub,
                label: 'Social HQ',
                color: DesignTokens.neonCyan,
                onTap: () {
                  _addAudit('Social Command Center opened', _AuditType.info);
                  context.push('/social-command-center');
                },
              ),
              _actionButton(
                icon: Icons.rocket_launch,
                label: 'Growth Engine',
                color: DesignTokens.neonGold,
                onTap: () {
                  _addAudit('Growth Engine opened', _AuditType.info);
                  context.push('/growth-engine-dashboard');
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Quick Stats Row (with sparkline graphs) ──
          Text(
            'EVENT METRICS',
            style: TextStyle(
              color: _kCyan.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metricCardWithGraph(
                  'PPV Buyers',
                  _compactCount((ev.ppvEvent?.purchaseCount ?? 0).toDouble()),
                  _kGreen,
                  _ticketSalesData,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricCardWithGraph(
                  'Gross Revenue',
                  _currencyShort(ev.ppvEvent?.totalRevenue ?? 0),
                  _kGold,
                  _revenueData,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricCardWithGraph(
                  'Media Assets',
                  '${ev.event?.imageIds.length ?? 0}',
                  _kCyan,
                  _socialReachData,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metricCardWithGraph(
                  'Readiness',
                  '${(_readinessPercent(ev) * 100).round()}%',
                  _kMagenta,
                  _engagementData,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricCardWithGraph(
                  'License',
                  ev.readiness?.licenseCleared == true ? 'Cleared' : 'Pending',
                  _kAmber,
                  _conversionData,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricCardWithGraph(
                  'Broadcast',
                  ev.ppvEvent?.muxStreamId?.isNotEmpty == true
                      ? 'Armed'
                      : 'Idle',
                  _kRed,
                  _pipelineThroughputData,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Metric card with embedded sparkline graph (replaces flat numbers)
  Widget _metricCardWithGraph(
    String label,
    String value,
    Color accent,
    List<double> data,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: GlassDecoration.card(accent: accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: DFCTextStyles.statNumber.copyWith(
                    color: accent,
                    fontSize: 18,
                  ),
                ),
              ),
              // Trend arrow
              Icon(
                Icons.trending_up_rounded,
                color: accent.withValues(alpha: 0.5),
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          // Sparkline graph
          SizedBox(
            height: 28,
            width: double.infinity,
            child: data.length >= 2
                ? LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: data
                              .asMap()
                              .entries
                              .map((e) => FlSpot(e.key.toDouble(), e.value))
                              .toList(),
                          isCurved: true,
                          color: accent,
                          barWidth: 1.5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                accent.withValues(alpha: 0.15),
                                accent.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ═══ RIGHT PANEL — Mission Control Console ═══════════════════════════
  Widget _buildConsolePanel() {
    final selectedEvent = _selectedEvent;
    return Container(
      color: _kPanel.withValues(alpha: 0.5),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedEvent != null) ...[
              _buildStreamOpsPanel(selectedEvent),
              const SizedBox(height: 20),
              _buildSettlementProofPanel(selectedEvent),
              const SizedBox(height: 20),
              _buildWorkflowStatusPanel(selectedEvent),
              const SizedBox(height: 20),
            ],
            // Section: System Status Gauges
            _sectionLabel('SYSTEM STATUS', _kCyan, Icons.speed),
            const SizedBox(height: 10),
            _systemGauge(
              'Crawler Engine',
              0.87,
              _kAmber,
              _toggles['Content Crawler'] ?? false,
            ),
            _systemGauge(
              'Social Pipeline',
              0.62,
              _kCyan,
              _toggles['Social Bot'] ?? false,
            ),
            _systemGauge(
              'Poster Renderer',
              0.94,
              _kMagenta,
              _toggles['Poster Engine'] ?? false,
            ),
            _systemGauge(
              'Feed Orchestrator',
              0.78,
              _kGreen,
              _toggles['Feed Orchestrator'] ?? false,
            ),
            const SizedBox(height: 20),

            // Section: Control Toggles (neatened blocks)
            _sectionLabel('CONTROL TOGGLES', _kMagenta, Icons.tune),
            const SizedBox(height: 10),
            ..._toggles.entries.map(_buildToggleRow),
            const SizedBox(height: 20),

            // Section: Quick Launch (clean, no chevrons)
            _sectionLabel('QUICK LAUNCH', _kGreen, Icons.rocket_launch),
            const SizedBox(height: 10),
            _quickLaunchButton(
              icon: Icons.rocket_launch,
              label: 'Launch Full Campaign',
              color: _kGreen,
              onTap: () =>
                  _addAudit('Full campaign launched', _AuditType.success),
            ),
            const SizedBox(height: 6),
            _quickLaunchButton(
              icon: Icons.sync,
              label: 'Sync All Platforms',
              color: _kCyan,
              onTap: () =>
                  _addAudit('Platform sync triggered', _AuditType.info),
            ),
            const SizedBox(height: 6),
            _quickLaunchButton(
              icon: Icons.analytics_outlined,
              label: 'Generate Report',
              color: _kAmber,
              onTap: () =>
                  _addAudit('Analytics report started', _AuditType.info),
            ),
            const SizedBox(height: 6),
            _quickLaunchButton(
              icon: Icons.pause_circle_outline,
              label: 'Kill All Systems',
              color: _kRed,
              onTap: () {
                setState(() {
                  for (final key in _toggles.keys) {
                    _toggles[key] = false;
                  }
                });
                _addAudit('ALL SYSTEMS HALTED by operator', _AuditType.error);
              },
            ),
            const SizedBox(height: 20),

            // Section: Active Alerts
            _sectionLabel('ALERTS', _kAmber, Icons.notifications_active),
            const SizedBox(height: 10),
            _alertTile('Ticket sales spike +23%', Icons.trending_up, _kGreen),
            _alertTile(
              'Sponsor logo approval pending',
              Icons.pending_actions,
              _kAmber,
            ),
            _alertTile(
              'Image rights — weigh-in photos',
              Icons.photo_library_outlined,
              _kRed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color.withValues(alpha: 0.5), size: 13),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSettlementProofPanel(_ControlRoomEvent event) {
    final snapshot = _settlementSnapshots[event.id];
    final isLoading = _settlementLoadingIds.contains(event.id);
    final accent = snapshot == null
        ? _kCyan
        : (snapshot.needsReview ? _kAmber : _kGreen);
    final readiness = event.readiness;

    Widget metric(String label, String value, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: accent,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'SETTLEMENT PROOF',
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              if (isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  snapshot?.confidenceLabel ?? 'SYNCING',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            snapshot?.confidenceDetail ??
                'Pulling purchase ledger and payout sync for this event.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FOUNDATION STATUS',
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.72),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _foundationChip(
                      'Event Lane',
                      event.event != null ? 'READY' : 'FALLBACK',
                      event.event != null ? _kGreen : _kAmber,
                    ),
                    _foundationChip(
                      'PPV',
                      event.ppvEvent != null ? 'READY' : 'PENDING',
                      event.ppvEvent != null ? _kGreen : _kAmber,
                    ),
                    _foundationChip(
                      'Rights',
                      readiness?.licenseCleared == true ? 'CLEARED' : 'PENDING',
                      readiness?.licenseCleared == true ? _kGreen : _kAmber,
                    ),
                    _foundationChip(
                      'Go Live',
                      readiness?.eventCanGoLive == true ? 'GREEN' : 'BLOCKED',
                      readiness?.eventCanGoLive == true ? _kGreen : _kRed,
                    ),
                    _foundationChip(
                      'Mux',
                      event.ppvEvent?.muxStreamId?.isNotEmpty == true
                          ? 'ARMED'
                          : (event.ppvEvent?.streamUrl?.isNotEmpty == true
                                ? 'REHEARSAL'
                                : 'WAITING'),
                      event.ppvEvent?.muxStreamId?.isNotEmpty == true
                          ? _kGreen
                          : (event.ppvEvent?.streamUrl?.isNotEmpty == true
                                ? _kCyan
                                : _kAmber),
                    ),
                    _foundationChip(
                      'Settlement',
                      snapshot?.confidenceLabel ?? 'SYNCING',
                      accent,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              metric(
                'Gross',
                _currencyExact(snapshot?.grossSales ?? 0),
                _kCyan,
              ),
              const SizedBox(width: 8),
              metric(
                'Payable',
                _currencyExact(snapshot?.payableNow ?? 0),
                _kGreen,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              metric('Buys', '${snapshot?.totalPurchases ?? 0}', _kGold),
              const SizedBox(width: 8),
              metric(
                'Variance',
                _currencyExact((snapshot?.revenueShareDelta ?? 0).abs()),
                snapshot?.needsReview == true ? _kAmber : _kMagenta,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  snapshot == null
                      ? 'Open the reconciliation board for the full ledger.'
                      : 'Payout status: ${snapshot.payoutStatusLabel} • Refunds: ${snapshot.refundedPurchases}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.46),
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  context.push('/promoter/reconciliation', extra: event.id);
                },
                child: Text(
                  'OPEN LEDGER',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _copyOperatorProofBrief(event),
                child: const Text(
                  'COPY PROOF',
                  style: TextStyle(
                    color: _kCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowStatusPanel(_ControlRoomEvent event) {
    final eventIds = <String>{event.id};
    final ppvEventId = event.ppvEvent?.id;
    if (ppvEventId != null && ppvEventId.isNotEmpty) {
      eventIds.add(ppvEventId);
    }

    return WorkflowRunStatusPanel(
      limit: 24,
      eventIds: eventIds,
      title: 'WORKFLOW TRAFFIC',
      subtitle:
          'Recent automation state for the selected event lane across promotion, PPV, prediction, and callback flows.',
      emptyStateText:
          'No workflow runs have been recorded for this event lane yet.',
    );
  }

  Widget _foundationChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// System gauge — thin horizontal bar with label + status dot
  Widget _systemGauge(String label, double percent, Color color, bool active) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? color : Colors.white24,
                    shape: BoxShape.circle,
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 4,
                            ),
                          ]
                        : [],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: active ? Colors.white70 : Colors.white30,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '${(percent * 100).toInt()}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: active ? percent : 0,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation<Color>(
                  active ? color : Colors.white24,
                ),
                minHeight: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(MapEntry<String, bool> entry) {
    final Color accent;
    final IconData icon;
    switch (entry.key) {
      case 'Content Crawler':
        accent = _kAmber;
        icon = Icons.travel_explore;
      case 'Social Bot':
        accent = _kCyan;
        icon = Icons.smart_toy_outlined;
      case 'Poster Engine':
        accent = _kMagenta;
        icon = Icons.brush_outlined;
      case 'Watchlist Monitor':
        accent = _kGold;
        icon = Icons.visibility_outlined;
      case 'Auto-Boost':
        accent = _kGreen;
        icon = Icons.bolt;
      case 'Feed Orchestrator':
        accent = DesignTokens.neonBlue;
        icon = Icons.hub_outlined;
      case 'Ticket Scanner':
        accent = _kAmber;
        icon = Icons.qr_code_scanner;
      case 'Revenue Tracker':
        accent = _kGold;
        icon = Icons.account_balance_wallet_outlined;
      default:
        accent = _kCyan;
        icon = Icons.settings;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: entry.value
              ? accent.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: entry.value
                ? accent.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: entry.value
                    ? accent.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: entry.value ? accent : Colors.white24,
                size: 13,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.key,
                style: TextStyle(
                  color: entry.value ? Colors.white : Colors.white30,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(
              height: 22,
              child: Switch(
                value: entry.value,
                activeThumbColor: accent,
                activeTrackColor: accent.withValues(alpha: 0.3),
                inactiveThumbColor: Colors.white24,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.06),
                onChanged: (v) {
                  setState(() => _toggles[entry.key] = v);
                  _addAudit(
                    '${entry.key} ${v ? "ONLINE" : "OFFLINE"}',
                    v ? _AuditType.success : _AuditType.warning,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Clean quick-launch button — boxed icon, no chevron
  Widget _quickLaunchButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _alertTile(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══ FOOTER — Audit Trail ════════════════════════════════════════════
  Widget _buildAuditTrail() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 100),
      decoration: BoxDecoration(
        color: _kPanel,
        border: Border(top: BorderSide(color: _kCyan.withValues(alpha: 0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text(
                  'AUDIT TRAIL',
                  style: TextStyle(
                    color: _kCyan.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_auditTrail.length} entries',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _auditTrail.length,
              itemBuilder: (context, i) {
                final entry = _auditTrail[i];
                final Color c;
                switch (entry.type) {
                  case _AuditType.info:
                    c = _kCyan;
                  case _AuditType.success:
                    c = _kGreen;
                  case _AuditType.warning:
                    c = _kAmber;
                  case _AuditType.error:
                    c = _kRed;
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.time,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.action,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamOpsPanel(_ControlRoomEvent selectedEvent) {
    final readiness = selectedEvent.readiness;
    final ppvEvent = selectedEvent.ppvEvent;
    final streamDocId = ppvEvent?.muxStreamId;
    final blocked = readiness != null && !readiness.eventCanGoLive;
    final hasProvisionedLane =
        ppvEvent?.muxStreamId?.isNotEmpty == true ||
        ppvEvent?.streamUrl?.isNotEmpty == true;
    final isRehearsalLane =
        ppvEvent?.muxStreamId?.isEmpty != false &&
        ppvEvent?.streamUrl?.isNotEmpty == true;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: blocked
              ? _kAmber.withValues(alpha: 0.3)
              : _kGreen.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('GO LIVE', blocked ? _kAmber : _kGreen, Icons.live_tv),
          const SizedBox(height: 10),
          Text(
            selectedEvent.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            readiness == null
                ? 'Checking commercial readiness...'
                : readiness.eventCanGoLive
                ? 'All required commercial gates are green. You can issue stream credentials.'
                : readiness.blockers.first,
            style: TextStyle(
              color: readiness?.eventCanGoLive == true
                  ? Colors.white70
                  : _kAmber,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          _buildStreamMetaRow('PPV Lane', ppvEvent?.id ?? 'Not created yet'),
          _buildStreamMetaRow(
            'Mode',
            isRehearsalLane
                ? 'Rehearsal lane without Mux'
                : (hasProvisionedLane
                      ? 'Production-capable'
                      : 'Awaiting credentials'),
          ),
          _buildStreamMetaRow(
            'Playback',
            ppvEvent?.muxPlaybackId ?? ppvEvent?.streamUrl ?? 'Not provisioned',
          ),
          if (streamDocId != null && streamDocId.isNotEmpty) ...[
            const SizedBox(height: 10),
            StreamBuilder<MuxStreamStatus>(
              stream: MuxStreamingService.watchStreamStatus(streamDocId),
              builder: (context, snapshot) {
                final status = snapshot.data;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStreamMetaRow('Status', status?.status ?? 'idle'),
                    _buildStreamMetaRow(
                      'Viewers',
                      '${status?.currentViewers ?? 0} current / ${status?.peakViewers ?? 0} peak',
                    ),
                    _buildStreamMetaRow(
                      'Replay',
                      status?.hasVod == true
                          ? 'ready'
                          : (status?.vodStatus ?? 'pending'),
                    ),
                    _buildStreamMetaRow(
                      'Delivery',
                      status?.credentialDeliveryLabel ?? 'Delivery pending',
                    ),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: (_launchingStream || blocked)
                    ? null
                    : _launchStreamForSelectedEvent,
                child: Text(
                  _launchingStream
                      ? 'Provisioning…'
                      : (isRehearsalLane
                            ? 'Refresh Rehearsal Lane'
                            : 'Create Stream Credentials'),
                ),
              ),
              OutlinedButton(
                onPressed: streamDocId == null || streamDocId.isEmpty
                    ? null
                    : _disableSelectedStream,
                child: const Text('Disable Stream'),
              ),
              OutlinedButton(
                onPressed:
                    streamDocId == null ||
                        streamDocId.isEmpty ||
                        _resendingCredentials
                    ? null
                    : _resendCredentialPackForSelectedEvent,
                child: Text(
                  _resendingCredentials
                      ? 'Resending…'
                      : 'Resend Credential Pack',
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  context.push(
                    '/promoter/rights-intake?eventId=${Uri.encodeComponent(selectedEvent.id)}${ppvEvent != null ? '&ppvEventId=${Uri.encodeComponent(ppvEvent.id)}' : ''}',
                  );
                },
                child: const Text('Open Rights Intake'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreamMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══ DATA MODELS ═════════════════════════════════════════════════════════

enum _EventStatus { live, upcoming, completed }

enum _AuditType { info, success, warning, error }

class _ControlRoomEvent {
  final String id;
  final String name;
  final String date;
  final _EventStatus status;
  final String headline;
  final String sport;
  final String? posterUrl;
  final String? location;
  final EventModel? event;
  final PPVEvent? ppvEvent;
  final PromoterReadinessSnapshot? readiness;

  const _ControlRoomEvent({
    required this.id,
    required this.name,
    required this.date,
    required this.status,
    required this.headline,
    required this.sport,
    this.posterUrl,
    this.location,
    this.event,
    this.ppvEvent,
    this.readiness,
  });

  factory _ControlRoomEvent.fromData(
    EventModel event,
    PPVEvent? ppvEvent,
    PromoterReadinessSnapshot readiness,
  ) {
    final status = switch (event.status) {
      EventStatus.live => _EventStatus.live,
      EventStatus.completed ||
      EventStatus.archived ||
      EventStatus.results => _EventStatus.completed,
      _ => _EventStatus.upcoming,
    };

    return _ControlRoomEvent(
      id: event.id,
      name: event.name,
      date:
          '${event.eventDate.day.toString().padLeft(2, '0')}/${event.eventDate.month.toString().padLeft(2, '0')}/${event.eventDate.year}',
      status: status,
      headline: event.promotionName ?? event.name,
      sport: event.sportType ?? 'Combat',
      posterUrl: event.primaryPosterUrl,
      location: event.fullLocation,
      event: event,
      ppvEvent: ppvEvent,
      readiness: readiness,
    );
  }
}

class _AuditEntry {
  final String time;
  final String action;
  final _AuditType type;

  const _AuditEntry({
    required this.time,
    required this.action,
    required this.type,
  });
}

// ═══ CUSTOM PAINTERS ═════════════════════════════════════════════════════

/// Mini arc gauge — shows a percentage as a colored arc (NASA instrument style)
class _MiniGaugePainter extends CustomPainter {
  final double percent;
  final Color color;

  _MiniGaugePainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    const startAngle = 2.4; // roughly 7 o'clock
    const sweepTotal = 4.3; // arc span

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      bgPaint,
    );

    // Filled arc
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal * percent.clamp(0, 1),
      false,
      fillPaint,
    );

    // Glow effect on tip
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final tipAngle = startAngle + sweepTotal * percent.clamp(0, 1);
    final tipX = center.dx + radius * math.cos(tipAngle);
    final tipY = center.dy + radius * math.sin(tipAngle);
    canvas.drawCircle(Offset(tipX, tipY), 2, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _MiniGaugePainter oldDelegate) =>
      oldDelegate.percent != percent;
}

/// Pipeline flow painter — animated horizontal flow with pulsing nodes
/// and flowing connection lines (like a heartbeat monitor between stages)
class _PipelineFlowPainter extends CustomPainter {
  final Map<String, double> stages;
  final double progress; // 0.0–1.0 animation cycle
  final double heartbeat; // 0.0–1.0 pulse cycle

  _PipelineFlowPainter({
    required this.stages,
    required this.progress,
    required this.heartbeat,
  });

  static const _stageColors = [
    _kCyan,
    _kAmber,
    _kMagenta,
    _kGold,
    _kGreen,
    _kRed,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final stageKeys = stages.keys.toList();
    if (stageKeys.isEmpty) return;

    final nodeCount = stageKeys.length;
    final sectionW = size.width / nodeCount;
    final centerY = size.height / 2;

    for (int i = 0; i < nodeCount; i++) {
      final cx = sectionW * i + sectionW / 2;
      final value = (stages[stageKeys[i]] ?? 50) / 100;
      final color = _stageColors[i % _stageColors.length];
      final pulseScale = 1.0 + heartbeat * 0.15 * value;

      // Draw connecting line to next node
      if (i < nodeCount - 1) {
        final nextCx = sectionW * (i + 1) + sectionW / 2;
        // Animated dash flow
        final linePaint = Paint()
          ..color = color.withValues(alpha: 0.2)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

        canvas.drawLine(
          Offset(cx + 14, centerY),
          Offset(nextCx - 14, centerY),
          linePaint,
        );

        // Flowing dot (packet traveling between nodes)
        final dotProgress = (progress + i * 0.15) % 1.0;
        final dotX = cx + 14 + (nextCx - cx - 28) * dotProgress;
        final dotPaint = Paint()
          ..color = color.withValues(alpha: 0.6 + dotProgress * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(Offset(dotX, centerY), 2.5, dotPaint);
      }

      // Node circle with pulse
      final nodeRadius = 10.0 * pulseScale;

      // Glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.15 + heartbeat * 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(cx, centerY), nodeRadius + 4, glowPaint);

      // Background circle
      final bgPaint = Paint()..color = color.withValues(alpha: 0.12);
      canvas.drawCircle(Offset(cx, centerY), nodeRadius, bgPaint);

      // Fill ring proportional to throughput
      final ringPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, centerY), radius: nodeRadius),
        -math.pi / 2,
        2 * math.pi * value,
        false,
        ringPaint,
      );

      // Label below
      final textPainter = TextPainter(
        text: TextSpan(
          text: stageKeys[i],
          style: TextStyle(
            color: color.withValues(alpha: 0.6),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(cx - textPainter.width / 2, centerY + nodeRadius + 4),
      );

      // Throughput % inside node
      final valuePainter = TextPainter(
        text: TextSpan(
          text: '${(value * 100).toInt()}',
          style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      valuePainter.paint(
        canvas,
        Offset(cx - valuePainter.width / 2, centerY - valuePainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PipelineFlowPainter oldDelegate) => true;
}
