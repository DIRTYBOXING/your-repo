import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/engine_room_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC ENGINE ROOM — The Promotional Machine Visible Dashboard
/// ═══════════════════════════════════════════════════════════════════════════
///
/// A Tesla-grade control room where promoters watch the pipeline working:
///  - CONVEYOR STATUS: Live pipeline stage counts with flow animation
///  - HYPE RAMP: Countdown meters for upcoming events (proximity boost)
///  - ADRENALINE DUMP: Post-event media decay visualizer
///  - BALANCE GAUGES: Category/region exposure dials
///  - CONVEYOR LOG: Recent run telemetry with timing stats
///  - MANUAL CONTROLS: Force-run conveyor, trigger ingestion
///
/// All data is REAL — pulled from Firestore + Cloud Functions.
/// ═══════════════════════════════════════════════════════════════════════════

class EngineRoomScreen extends StatefulWidget {
  const EngineRoomScreen({super.key});

  @override
  State<EngineRoomScreen> createState() => _EngineRoomScreenState();
}

class _EngineRoomScreenState extends State<EngineRoomScreen>
    with TickerProviderStateMixin {
  final EngineRoomService _service = EngineRoomService();

  // State
  Map<String, dynamic> _health = {};
  Map<String, int> _pipelineCounts = {};
  List<Map<String, dynamic>> _conveyorRuns = [];
  List<Map<String, dynamic>> _upcomingEvents = [];
  List<Map<String, dynamic>> _recentEvents = [];
  bool _loading = true;
  bool _triggering = false;
  String? _lastTriggerResult;
  Timer? _refreshTimer;

  // Animations
  late AnimationController _pulseController;
  late AnimationController _conveyorController;

  // Subscriptions
  StreamSubscription? _runsSub;
  StreamSubscription? _upcomingSub;
  StreamSubscription? _recentSub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _conveyorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _loadData();
    _startStreams();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _loadData(),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _conveyorController.dispose();
    _refreshTimer?.cancel();
    _runsSub?.cancel();
    _upcomingSub?.cancel();
    _recentSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _service.getFeedHealth(),
      _service.getPipelineCounts(),
    ]);
    if (!mounted) return;
    setState(() {
      _health = results[0];
      _pipelineCounts = Map<String, int>.from(results[1]);
      _loading = false;
    });
  }

  void _startStreams() {
    _runsSub = _service.streamConveyorRuns(limit: 8).listen((runs) {
      if (mounted) setState(() => _conveyorRuns = runs);
    });
    _upcomingSub = _service.streamUpcomingEvents(limit: 6).listen((events) {
      if (mounted) setState(() => _upcomingEvents = events);
    });
    _recentSub = _service.streamRecentEvents(limit: 6).listen((events) {
      if (mounted) setState(() => _recentEvents = events);
    });
  }

  Future<void> _triggerConveyor() async {
    setState(() {
      _triggering = true;
      _lastTriggerResult = null;
    });
    final result = await _service.triggerWaterfall();
    if (!mounted) return;
    setState(() {
      _triggering = false;
      _lastTriggerResult = result.containsKey('error')
          ? 'ERROR: ${result['error']}'
          : 'Completed in ${result['elapsed']} — '
                'Promoted: ${_formatPromoted(result['promotion'])}';
    });
    _loadData(); // refresh stats
  }

  String _formatPromoted(dynamic promo) {
    if (promo == null) return '0';
    if (promo is Map) {
      final p = promo['promoted'] ?? promo;
      if (p is Map) {
        return 'B:${p['breaking'] ?? 0} F:${p['featured'] ?? 0} S:${p['standard'] ?? 0} R:${p['regional'] ?? 0}';
      }
    }
    return promo.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A14),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.neonCyan),
            )
          : CustomScrollView(
              slivers: [
                _buildHeader(),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildConveyorBelt(),
                      const SizedBox(height: 20),
                      _buildPipelineCounters(),
                      const SizedBox(height: 20),
                      _buildHypeRamp(),
                      const SizedBox(height: 20),
                      _buildAdrenalineDump(),
                      const SizedBox(height: 20),
                      _buildBalanceGauges(),
                      const SizedBox(height: 20),
                      _buildConveyorLog(),
                      const SizedBox(height: 20),
                      _buildControls(),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════

  SliverAppBar _buildHeader() {
    return SliverAppBar(
      expandedHeight: 80,
      pinned: true,
      backgroundColor: const Color(0xFF050A14),
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, _) => Icon(
                Icons.precision_manufacturing,
                color: AppTheme.neonCyan.withValues(
                  alpha: 0.6 + _pulseController.value * 0.4,
                ),
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'ENGINE ROOM',
              style: TextStyle(
                color: AppTheme.neonCyan,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.neonGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppTheme.neonGreen.withValues(alpha: 0.5),
                ),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  color: AppTheme.neonGreen,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CONVEYOR BELT ANIMATION — The pipeline flowing
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildConveyorBelt() {
    final stages = ['INTAKE', 'SCORE', 'PROMOTE', 'HYPE', 'DUMP', 'ARCHIVE'];
    final stageIcons = [
      Icons.download,
      Icons.analytics,
      Icons.trending_up,
      Icons.local_fire_department,
      Icons.photo_library,
      Icons.archive,
    ];
    final stageColors = [
      AppTheme.neonCyan,
      AppTheme.neonPurple,
      AppTheme.neonGreen,
      AppTheme.neonOrange,
      AppTheme.neonMagenta,
      Colors.grey,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('CONVEYOR BELT', Icons.conveyor_belt),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: AnimatedBuilder(
              animation: _conveyorController,
              builder: (_, _) => Row(
                children: List.generate(stages.length, (i) {
                  final isActive =
                      _conveyorController.value * stages.length > i &&
                      _conveyorController.value * stages.length < i + 1.5;
                  return Expanded(
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isActive
                                ? stageColors[i].withValues(alpha: 0.2)
                                : const Color(0xFF0D1B2A),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isActive
                                  ? stageColors[i]
                                  : stageColors[i].withValues(alpha: 0.3),
                              width: isActive ? 2 : 1,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: stageColors[i].withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            stageIcons[i],
                            color: stageColors[i],
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stages[i],
                          style: TextStyle(
                            color: isActive ? stageColors[i] : Colors.grey,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        if (i < stages.length - 1)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: stageColors[i].withValues(
                                alpha: isActive ? 0.5 : 0.1,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PIPELINE COUNTERS — Real-time article counts by stage
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildPipelineCounters() {
    final counters = [
      _CounterData(
        'NEW',
        _pipelineCounts['new'] ?? 0,
        AppTheme.neonCyan,
        Icons.fiber_new,
      ),
      _CounterData(
        'QUEUED',
        _pipelineCounts['queued'] ?? 0,
        AppTheme.neonOrange,
        Icons.queue,
      ),
      _CounterData(
        'PROMOTED',
        _pipelineCounts['promoted'] ?? 0,
        AppTheme.neonGreen,
        Icons.check_circle,
      ),
      _CounterData(
        'PUBLISHED',
        _pipelineCounts['published'] ?? 0,
        AppTheme.neonMagenta,
        Icons.public,
      ),
      _CounterData(
        'ARCHIVED',
        _pipelineCounts['archived'] ?? 0,
        Colors.grey,
        Icons.archive,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('PIPELINE STATUS', Icons.dashboard),
          const SizedBox(height: 12),
          Row(
            children: counters
                .map((c) => Expanded(child: _buildCounterTile(c)))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterTile(_CounterData counter) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: counter.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: counter.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(counter.icon, color: counter.color, size: 20),
          const SizedBox(height: 6),
          Text(
            counter.count.toString(),
            style: TextStyle(
              color: counter.color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            counter.label,
            style: TextStyle(
              color: counter.color.withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HYPE RAMP — Upcoming events with countdown + hype meter
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildHypeRamp() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neonOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'HYPE ENGINE — EVENT COUNTDOWN',
            Icons.local_fire_department,
            color: AppTheme.neonOrange,
          ),
          const SizedBox(height: 12),
          if (_upcomingEvents.isEmpty)
            _buildEmptyState('No upcoming events in pipeline', Icons.event_busy)
          else
            ..._upcomingEvents.map(_buildHypeEventCard),
        ],
      ),
    );
  }

  Widget _buildHypeEventCard(Map<String, dynamic> event) {
    final name = event['name'] ?? event['title'] ?? 'Unknown Event';
    final dateStr = event['eventDate'] ?? '';
    final sportType = event['sportType'] ?? 'MMA';
    final city = event['city'] ?? '';
    final country = event['country'] ?? '';

    DateTime? eventDate;
    try {
      eventDate = DateTime.parse(dateStr);
    } catch (_) {}

    final now = DateTime.now();
    final hoursUntil = eventDate != null
        ? eventDate.difference(now).inMinutes / 60.0
        : 999.0;

    // Hype multiplier (mirrors waterfall.js getHypeMultiplier)
    final hypeLevel = hoursUntil <= 0
        ? 1.0
        : hoursUntil <= 1
        ? 0.95
        : hoursUntil <= 6
        ? 0.75
        : hoursUntil <= 24
        ? 0.55
        : hoursUntil <= 72
        ? 0.35
        : hoursUntil <= 168
        ? 0.20
        : 0.05;

    final phase = hoursUntil <= 0
        ? 'LIVE'
        : hoursUntil <= 6
        ? 'IMMINENT'
        : hoursUntil <= 24
        ? 'FIGHT DAY'
        : hoursUntil <= 72
        ? 'FIGHT WEEK'
        : 'PROMO';

    final phaseColor = phase == 'LIVE'
        ? Colors.red
        : phase == 'IMMINENT'
        ? AppTheme.neonOrange
        : phase == 'FIGHT DAY'
        ? AppTheme.neonMagenta
        : phase == 'FIGHT WEEK'
        ? AppTheme.neonCyan
        : Colors.grey;

    final countdown = hoursUntil <= 0
        ? 'NOW'
        : hoursUntil < 1
        ? '${(hoursUntil * 60).round()}m'
        : hoursUntil < 24
        ? '${hoursUntil.round()}h'
        : '${(hoursUntil / 24).round()}d';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: phaseColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: phaseColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: phaseColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  phase,
                  style: TextStyle(
                    color: phaseColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                countdown,
                style: TextStyle(
                  color: phaseColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '$sportType • $city${country.isNotEmpty ? ", $country" : ""}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                'HYPE: ${(hypeLevel * 100).round()}%',
                style: TextStyle(
                  color: phaseColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Hype meter bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: hypeLevel,
              minHeight: 6,
              backgroundColor: phaseColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(phaseColor),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ADRENALINE DUMP — Post-event media decay visualizer
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildAdrenalineDump() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neonMagenta.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'ADRENALINE DUMP — POST-EVENT DECAY',
            Icons.photo_library,
            color: AppTheme.neonMagenta,
          ),
          const SizedBox(height: 12),
          if (_recentEvents.isEmpty)
            _buildEmptyState(
              'No recent events in dump phase',
              Icons.event_available,
            )
          else
            ..._recentEvents.map(_buildDumpEventCard),
        ],
      ),
    );
  }

  Widget _buildDumpEventCard(Map<String, dynamic> event) {
    final name = event['name'] ?? event['title'] ?? 'Unknown Event';
    final dateStr = event['eventDate'] ?? '';

    DateTime? eventDate;
    try {
      eventDate = DateTime.parse(dateStr);
    } catch (_) {}

    final now = DateTime.now();
    final hoursSince = eventDate != null
        ? now.difference(eventDate).inMinutes / 60.0
        : 0.0;

    // Dump intensity (mirrors waterfall.js getDumpIntensity)
    final intensity = hoursSince <= 1
        ? 1.0
        : hoursSince <= 3
        ? 0.90
        : hoursSince <= 6
        ? 0.75
        : hoursSince <= 12
        ? 0.55
        : hoursSince <= 24
        ? 0.35
        : hoursSince <= 48
        ? 0.20
        : hoursSince <= 72
        ? 0.10
        : 0.0;

    final phase = hoursSince <= 1
        ? 'ADRENALINE PEAK'
        : hoursSince <= 3
        ? 'HIGHLIGHT FLOOD'
        : hoursSince <= 6
        ? 'RECAP WAVE'
        : hoursSince <= 12
        ? 'MORNING AFTER'
        : hoursSince <= 24
        ? 'NEXT DAY'
        : hoursSince <= 48
        ? 'COOLING'
        : 'WIND DOWN';

    final elapsed = hoursSince < 1
        ? '${(hoursSince * 60).round()}m ago'
        : hoursSince < 24
        ? '${hoursSince.round()}h ago'
        : '${(hoursSince / 24).round()}d ago';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.neonMagenta.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.neonMagenta.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                color: AppTheme.neonMagenta.withValues(
                  alpha: 0.3 + intensity * 0.7,
                ),
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                elapsed,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.neonMagenta.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  phase,
                  style: const TextStyle(
                    color: AppTheme.neonMagenta,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'DUMP: ${(intensity * 100).round()}%',
                style: const TextStyle(
                  color: AppTheme.neonMagenta,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Decay bar (emptying out)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: intensity,
              minHeight: 6,
              backgroundColor: AppTheme.neonMagenta.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.neonMagenta,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _dumpPhaseLabel('Photos', intensity > 0.7),
              _dumpPhaseLabel('Highlights', intensity > 0.5),
              _dumpPhaseLabel('Recaps', intensity > 0.3),
              _dumpPhaseLabel('Analysis', intensity > 0.1),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dumpPhaseLabel(String label, bool active) {
    return Text(
      label,
      style: TextStyle(
        color: active
            ? AppTheme.neonMagenta
            : Colors.white.withValues(alpha: 0.2),
        fontSize: 9,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BALANCE GAUGES — Category/Region exposure dials
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildBalanceGauges() {
    final balance = _health['balance'] as Map<String, dynamic>? ?? {};
    final categories = Map<String, dynamic>.from(
      balance['categories'] as Map? ?? {},
    );
    final categoryCaps = Map<String, dynamic>.from(
      balance['categoryCaps'] as Map? ?? {},
    );
    final regions = Map<String, dynamic>.from(balance['regions'] as Map? ?? {});
    final tiers = Map<String, dynamic>.from(balance['tiers'] as Map? ?? {});

    final totalCat = categories.values.fold<num>(
      0,
      (a, b) => a + (b as num? ?? 0),
    );
    final totalReg = regions.values.fold<num>(
      0,
      (a, b) => a + (b as num? ?? 0),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'EXPOSURE BALANCE',
            Icons.balance,
            color: AppTheme.neonGreen,
          ),
          const SizedBox(height: 16),

          // Category gauges
          const Text(
            'CATEGORY MIX',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          ...categories.entries.map((e) {
            final pct = totalCat > 0 ? (e.value as num) / totalCat : 0.0;
            final cap = (categoryCaps[e.key] as num?)?.toDouble() ?? 0.3;
            final overCap = pct > cap;
            return _buildGaugeBar(
              e.key.toUpperCase(),
              pct.toDouble(),
              cap,
              overCap,
            );
          }),

          const SizedBox(height: 16),
          const Text(
            'REGION MIX',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          ...regions.entries.take(8).map((e) {
            final pct = totalReg > 0 ? (e.value as num) / totalReg : 0.0;
            return _buildGaugeBar(
              e.key.toUpperCase(),
              pct.toDouble(),
              0.35,
              pct > 0.35,
            );
          }),

          const SizedBox(height: 16),
          const Text(
            'TIER DISTRIBUTION',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTierChip('BREAKING', tiers['breaking'] ?? 0, Colors.red),
              _buildTierChip(
                'FEATURED',
                tiers['featured'] ?? 0,
                AppTheme.neonOrange,
              ),
              _buildTierChip(
                'STANDARD',
                tiers['standard'] ?? 0,
                AppTheme.neonCyan,
              ),
              _buildTierChip('REGIONAL', tiers['regional'] ?? 0, Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeBar(String label, double value, double cap, bool overCap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: overCap ? Colors.red : Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: value.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: AppTheme.neonGreen.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      overCap ? Colors.red : AppTheme.neonGreen,
                    ),
                  ),
                ),
                // Cap marker line
                Positioned(
                  left:
                      (cap.clamp(0.0, 1.0)) *
                      (MediaQuery.of(context).size.width - 160),
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: Colors.white38),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 40,
            child: Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                color: overCap ? Colors.red : Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierChip(String label, dynamic count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CONVEYOR LOG — Recent run telemetry
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildConveyorLog() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('CONVEYOR LOG', Icons.list_alt),
          const SizedBox(height: 12),
          if (_conveyorRuns.isEmpty)
            _buildEmptyState('No conveyor runs yet', Icons.history)
          else
            ..._conveyorRuns.map(_buildRunCard),
        ],
      ),
    );
  }

  Widget _buildRunCard(Map<String, dynamic> run) {
    final elapsed = run['elapsedSeconds'] ?? 0;
    final promo = run['promotion'] as Map<String, dynamic>? ?? {};
    final promoted = promo['promoted'] as Map<String, dynamic>? ?? {};
    final hype = run['hype'] as Map<String, dynamic>? ?? {};
    final dump = run['dump'] as Map<String, dynamic>? ?? {};
    final archive = run['archive'] as Map<String, dynamic>? ?? {};

    final ts = run['timestamp'];
    String timeStr = '';
    if (ts != null) {
      try {
        final date = ts is Map
            ? DateTime.fromMillisecondsSinceEpoch(
                ((ts['_seconds'] ?? 0) as int) * 1000,
              )
            : DateTime.parse(ts.toString());
        final ago = DateTime.now().difference(date);
        timeStr = ago.inMinutes < 60
            ? '${ago.inMinutes}m ago'
            : '${ago.inHours}h ago';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.play_circle,
            color: AppTheme.neonGreen.withValues(alpha: 0.6),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'B:${promoted['breaking'] ?? 0} F:${promoted['featured'] ?? 0} S:${promoted['standard'] ?? 0} R:${promoted['regional'] ?? 0}'
                  ' | Hype:${hype['boosted'] ?? 0} | Dump:${dump['dumped'] ?? 0} | Arch:${archive['archived'] ?? 0}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${elapsed}s',
                style: const TextStyle(
                  color: AppTheme.neonCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (timeStr.isNotEmpty)
                Text(
                  timeStr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 9,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CONTROLS — Manual conveyor trigger
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('MANUAL CONTROLS', Icons.settings),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _triggering ? null : _triggerConveyor,
              icon: _triggering
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(
                _triggering ? 'RUNNING CONVEYOR...' : 'FORCE RUN CONVEYOR BELT',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonCyan.withValues(alpha: 0.15),
                foregroundColor: AppTheme.neonCyan,
                side: const BorderSide(color: AppTheme.neonCyan),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          if (_lastTriggerResult != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _lastTriggerResult!.startsWith('ERROR')
                    ? Colors.red.withValues(alpha: 0.1)
                    : AppTheme.neonGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _lastTriggerResult!.startsWith('ERROR')
                      ? Colors.red.withValues(alpha: 0.3)
                      : AppTheme.neonGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _lastTriggerResult!,
                style: TextStyle(
                  color: _lastTriggerResult!.startsWith('ERROR')
                      ? Colors.red
                      : AppTheme.neonGreen,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _sectionTitle(
    String title,
    IconData icon, {
    Color color = AppTheme.neonCyan,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.2), size: 36),
          const SizedBox(height: 8),
          Text(
            msg,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterData {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _CounterData(this.label, this.count, this.color, this.icon);
}
