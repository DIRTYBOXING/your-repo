import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/hydration_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/ai_eso_engine_service.dart';
import '../../../shared/services/share_service.dart';
import '../../genie/genie_api_service.dart';
import '../../genie/genie_persona.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHTLAB — Master Analytics & Intelligence Aggregator
/// Collects ALL data from graphs, charts, wellbeing, mood, energy, biometrics
/// One unified analytics page to read everything at a glance
/// ═══════════════════════════════════════════════════════════════════════════

class FightLabScreen extends StatefulWidget {
  const FightLabScreen({super.key});

  @override
  State<FightLabScreen> createState() => _FightLabScreenState();
}

class _FightLabScreenState extends State<FightLabScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _timeRange = '7D';

  late AIEsoEngineService _esoEngine;
  bool _depsInitialized = false;

  bool _loadingAiInsights = false;
  List<String> _aiInsights = const [];

  // ── NASA/Tesla Telemetry Animation Controllers ──
  late AnimationController _scanController; // Horizontal scan sweep
  late AnimationController _pulseController; // Live-indicator heartbeat
  late AnimationController _gridController; // Background grid drift
  late AnimationController _glowController; // Neon glow oscillation
  late AnimationController _dataRefreshController; // Data bar entrance
  Timer? _marketTimer;
  int _marketTick = 0;
  DateTime _marketNow = DateTime.now();

  GeniePersona get _shidoPersona => geniePersonas.firstWhere(
    (p) => p.id == 'shido',
    orElse: () => geniePersonas.last,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // NASA telemetry animation stack
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _dataRefreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _marketTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        _marketTick++;
        _marketNow = DateTime.now();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_depsInitialized) {
      _depsInitialized = true;
      _esoEngine = context.read<AIEsoEngineService>();
      _initServices();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scanController.dispose();
    _pulseController.dispose();
    _gridController.dispose();
    _glowController.dispose();
    _dataRefreshController.dispose();
    _marketTimer?.cancel();
    super.dispose();
  }

  int _pointsForRange() {
    switch (_timeRange) {
      case '24H':
        return 24;
      case '7D':
        return 7;
      case '30D':
        return 30;
      default:
        return 7;
    }
  }

  List<String> _timeLabels() {
    final points = _pointsForRange();
    final labels = List<String>.filled(points, '');

    if (_timeRange == '24H') {
      for (int i = 0; i < points; i++) {
        if (i % 4 != 0 && i != points - 1) continue;
        final dt = _marketNow.subtract(Duration(hours: points - 1 - i));
        labels[i] = '${dt.hour.toString().padLeft(2, '0')}:00';
      }
      return labels;
    }

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    if (_timeRange == '7D') {
      for (int i = 0; i < points; i++) {
        final dt = _marketNow.subtract(Duration(days: points - 1 - i));
        labels[i] = weekdays[(dt.weekday - 1).clamp(0, 6)];
      }
      return labels;
    }

    // 30D labels: every 5 days + last point for readability.
    for (int i = 0; i < points; i++) {
      if (i % 5 != 0 && i != points - 1) continue;
      final dt = _marketNow.subtract(Duration(days: points - 1 - i));
      labels[i] = '${dt.day}/${dt.month}';
    }
    return labels;
  }

  List<double> _marketSeries({
    required double base,
    required double amplitude,
    required double min,
    required double max,
    required int seed,
    double drift = 0,
  }) {
    final points = _pointsForRange();
    final series = <double>[];

    final rangeScale = _timeRange == '24H'
        ? 1.0
        : _timeRange == '7D'
        ? 0.8
        : 0.55;

    for (int i = 0; i < points; i++) {
      final t = (i + _marketTick).toDouble();
      final waveFast = sin((t + seed) * 0.62) * amplitude * 0.30;
      final waveSlow = sin((t + seed * 1.7) * 0.17) * amplitude * 0.70;
      final micro = sin((t + _marketNow.second) * 1.3) * amplitude * 0.08;
      final trend = drift * (i - points / 2);

      final value = base + (waveFast + waveSlow + micro) * rangeScale + trend;
      series.add(value.clamp(min, max));
    }

    return series;
  }

  Future<void> _initServices() async {
    // Ensure ESO engine has data; this is idempotent due to singleton pattern.
    await _esoEngine.initialize();
    await _fetchAiInsights();
    if (mounted) setState(() {});
  }

  Future<void> _fetchAiInsights() async {
    setState(() {
      _loadingAiInsights = true;
    });

    try {
      final text = await GenieApiService.askGenie(
        'You are Samurai Shido reviewing an MMA athlete\'s full FightLab: readiness, training load, sleep, stress, hydration, and weight cut. '
        'Give five ultra-concise, one-sentence insights (no numbering) about how they should adjust this week. Each insight on its own line.',
        persona: _shidoPersona,
      );

      if (!mounted) return;

      final lines = text
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      setState(() {
        _aiInsights = lines.take(5).toList();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingAiInsights = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      body: Stack(
        children: [
          // ── NASA Grid Background ──
          AnimatedBuilder(
            animation: _gridController,
            builder: (context, _) => CustomPaint(
              painter: _TelemetryGridPainter(phase: _gridController.value),
              size: Size.infinite,
            ),
          ),
          // ── Scan Line Sweep ──
          AnimatedBuilder(
            animation: _scanController,
            builder: (context, _) => Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height:
                    MediaQuery.of(context).size.height * _scanController.value,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      DesignTokens.neonCyan.withValues(alpha: 0.03),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.95, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildOverallScore(),
                _buildTimeRangeSelector(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildBiometricsTab(),
                      _buildMentalTab(),
                      _buildPerformanceTab(),
                      _buildTrendsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final glow = 0.08 + _glowController.value * 0.06;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignTokens.neonCyan.withValues(alpha: glow * 0.3),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              DesignTokens.neonCyan,
                              Color.lerp(
                                DesignTokens.neonCyan,
                                DesignTokens.neonMagenta,
                                _glowController.value,
                              )!,
                              DesignTokens.neonMagenta,
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'FIGHTLAB',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Animated LIVE badge with pulsing dot
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.neonGreen.withValues(
                                alpha: 0.1 + _pulseController.value * 0.08,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: DesignTokens.neonGreen.withValues(
                                  alpha: 0.3 + _pulseController.value * 0.2,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: DesignTokens.neonGreen.withValues(
                                    alpha: _pulseController.value * 0.15,
                                  ),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: DesignTokens.neonGreen,
                                    boxShadow: [
                                      BoxShadow(
                                        color: DesignTokens.neonGreen
                                            .withValues(alpha: 0.6),
                                        blurRadius:
                                            4 + _pulseController.value * 3,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: DesignTokens.neonGreen,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'TELEMETRY \u2022 ANALYTICS \u2022 INTELLIGENCE',
                          style: TextStyle(
                            color: DesignTokens.neonCyan.withValues(alpha: 0.4),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'v4.2.0',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.2),
                            fontSize: 8,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _showExportOptions,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DesignTokens.neonCyan.withValues(
                          alpha: glow * 0.5,
                        ),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.download,
                    color: DesignTokens.neonCyan,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════
  // OVERALL FIGHT-READINESS SCORE — NASA TELEMETRY GRADE
  // ═══════════════════════════════════════════════════════

  Widget _buildOverallScore() {
    final readiness = (_esoEngine.currentWellness?.readinessScore ?? 82)
        .toInt();
    final normalized = (readiness.clamp(0, 100)) / 100.0;
    final statusColor = readiness >= 80
        ? DesignTokens.neonGreen
        : readiness >= 60
        ? DesignTokens.neonAmber
        : DesignTokens.neonRed;
    final statusLabel = readiness >= 80
        ? 'OPTIMAL'
        : readiness >= 60
        ? 'MODERATE'
        : 'CRITICAL';

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _glowController]),
      builder: (context, _) {
        final pulse = _pulseController.value;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DesignTokens.neonCyan.withValues(alpha: 0.06 + pulse * 0.02),
                DesignTokens.neonMagenta.withValues(alpha: 0.03),
                const Color(0xFF020408).withValues(alpha: 0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: DesignTokens.neonCyan.withValues(
                alpha: 0.12 + pulse * 0.06,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.neonCyan.withValues(
                  alpha: 0.04 + pulse * 0.03,
                ),
                blurRadius: 20,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Animated Score Ring ──
              SizedBox(
                width: 88,
                height: 88,
                child: CustomPaint(
                  painter: _AnimatedScoreRingPainter(
                    score: normalized,
                    color: statusColor,
                    glowPhase: pulse,
                    sweepPhase: _glowController.value,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$readiness',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: statusColor.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, DesignTokens.neonCyan],
                      ).createShader(bounds),
                      child: const Text(
                        'Fight Readiness Index',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Composite telemetry from biometrics, training load, mood, sleep & recovery.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // ── Telemetry KPI Row ──
                    Row(
                      children: [
                        _telemetryKPI(
                          '↑ 4%',
                          'vs last wk',
                          DesignTokens.neonGreen,
                        ),
                        const SizedBox(width: 6),
                        _telemetryKPI(
                          'Peak',
                          'Thu 18:00',
                          DesignTokens.neonAmber,
                        ),
                        const SizedBox(width: 6),
                        _telemetryKPI('12d', 'to fight', DesignTokens.neonRed),
                        const SizedBox(width: 6),
                        _telemetryKPI('94', 'max score', DesignTokens.neonCyan),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _telemetryKPI(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // TIME RANGE
  // ═══════════════════════════════════════════════════════

  Widget _buildTimeRangeSelector() {
    final ranges = ['24H', '7D', '30D'];
    return Container(
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: ranges.map((r) {
          final sel = _timeRange == r;
          return GestureDetector(
            onTap: () => setState(() => _timeRange = r),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: sel
                    ? DesignTokens.neonCyan.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: sel
                      ? DesignTokens.neonCyan.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                r,
                style: TextStyle(
                  color: sel
                      ? DesignTokens.neonCyan
                      : Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // TAB BAR
  // ═══════════════════════════════════════════════════════

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: DesignTokens.neonCyan.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: DesignTokens.neonCyan,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'OVERVIEW'),
          Tab(text: 'BIOMETRICS'),
          Tab(text: 'MENTAL'),
          Tab(text: 'PERFORMANCE'),
          Tab(text: 'TRENDS'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // TAB 1 — OVERVIEW (all signals at a glance)
  // ═══════════════════════════════════════════════════════

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Body Signals', Icons.monitor_heart),
        _signalGrid([
          const _Signal(
            'Heart Rate',
            '68 bpm',
            'Resting',
            DesignTokens.neonRed,
            0.68,
            '↓ 2 bpm',
          ),
          const _Signal(
            'HRV',
            '52 ms',
            'Good',
            DesignTokens.neonGreen,
            0.72,
            '↑ 5 ms',
          ),
          const _Signal(
            'Blood O₂',
            '98%',
            'Normal',
            DesignTokens.neonCyan,
            0.98,
            'Stable',
          ),
          const _Signal(
            'Temperature',
            '36.6°C',
            'Normal',
            DesignTokens.neonAmber,
            0.82,
            '± 0.1°C',
          ),
          const _Signal(
            'Resp Rate',
            '14/min',
            'Calm',
            DesignTokens.neonGreen,
            0.78,
            '↓ 1/min',
          ),
          const _Signal(
            'Blood Pressure',
            '118/76',
            'Optimal',
            DesignTokens.neonCyan,
            0.88,
            'Stable',
          ),
        ]),
        const SizedBox(height: 16),
        _sectionTitle('Body Composition', Icons.accessibility_new),
        _signalGrid([
          const _Signal(
            'Weight',
            '73.7 kg / 162.4 lbs',
            '↓ 0.3 kg',
            DesignTokens.neonAmber,
            0.75,
            'Target: 70.3 kg',
          ),
          const _Signal(
            'Body Fat',
            '12.8%',
            'Athletic',
            DesignTokens.neonGreen,
            0.87,
            '↓ 0.3%',
          ),
          const _Signal(
            'Muscle Mass',
            '30.9 kg / 68.2 lbs',
            'Optimal',
            DesignTokens.neonCyan,
            0.90,
            '↑ 0.2 kg',
          ),
          const _Signal(
            'Hydration',
            '72%',
            'Good',
            DesignTokens.neonCyan,
            0.72,
            'Drink 500ml',
          ),
        ]),
        const SizedBox(height: 16),
        _sectionTitle('Energy & Recovery', Icons.battery_charging_full),
        _signalGrid([
          const _Signal(
            'Sleep',
            '7.2 hrs',
            'Good',
            DesignTokens.neonMagenta,
            0.80,
            '95% quality',
          ),
          const _Signal(
            'Recovery',
            '78%',
            'Ready',
            DesignTokens.neonGreen,
            0.78,
            '↑ 12%',
          ),
          const _Signal(
            'Stress Level',
            '32/100',
            'Low',
            DesignTokens.neonGreen,
            0.32,
            '↓ 8 pts',
          ),
          const _Signal(
            'Energy',
            '76/100',
            'Strong',
            DesignTokens.neonAmber,
            0.76,
            'Post-lunch dip',
          ),
          const _Signal(
            'Training Load',
            '680 AU',
            'Moderate',
            DesignTokens.neonAmber,
            0.65,
            '↓ 45 AU',
          ),
          const _Signal(
            'Fatigue Index',
            '28/100',
            'Fresh',
            DesignTokens.neonGreen,
            0.28,
            '↓ 6 pts',
          ),
        ]),
        const SizedBox(height: 16),
        _sectionTitle('Mental Wellbeing', Icons.psychology),
        _signalGrid([
          const _Signal(
            'Mood',
            '😊 4/5',
            'Positive',
            DesignTokens.neonGreen,
            0.80,
            '↑ from 3',
          ),
          const _Signal(
            'Motivation',
            '85/100',
            'High',
            DesignTokens.neonCyan,
            0.85,
            'Fight week',
          ),
          const _Signal(
            'Confidence',
            '78/100',
            'Strong',
            DesignTokens.neonAmber,
            0.78,
            'Steady',
          ),
          const _Signal(
            'Focus',
            '82/100',
            'Sharp',
            DesignTokens.neonCyan,
            0.82,
            '↑ 5 pts',
          ),
        ]),
        const SizedBox(height: 16),
        _buildAIInsightCard(),
        const SizedBox(height: 16),
        _buildRiskAlerts(),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // TAB 2 — BIOMETRICS (deep dive into body data)
  // ═══════════════════════════════════════════════════════

  Widget _buildBiometricsTab() {
    final labels = _timeLabels();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBioChart('Heart Rate Zones', DesignTokens.neonRed, [
          const _Zone('Rest', '50-60', 0.15, Colors.blue),
          const _Zone('Fat Burn', '60-70%', 0.30, DesignTokens.neonGreen),
          const _Zone('Cardio', '70-80%', 0.35, DesignTokens.neonAmber),
          const _Zone('Peak', '80-90%', 0.15, DesignTokens.neonRed),
          const _Zone('Max', '90-100%', 0.05, DesignTokens.neonMagenta),
        ]),
        const SizedBox(height: 12),
        _buildLineGraph(
          'HRV Trend ($_timeRange)',
          DesignTokens.neonGreen,
          _marketSeries(
            base: 52,
            amplitude: 10,
            min: 30,
            max: 90,
            seed: 11,
            drift: 0.02,
          ),
          labels,
        ),
        const SizedBox(height: 12),
        _buildLineGraph(
          'Resting Heart Rate ($_timeRange)',
          DesignTokens.neonRed,
          _marketSeries(
            base: 68,
            amplitude: 5,
            min: 50,
            max: 90,
            seed: 23,
            drift: -0.01,
          ),
          labels,
        ),
        const SizedBox(height: 12),
        _buildLineGraph(
          'Sleep Duration ($_timeRange)',
          DesignTokens.neonMagenta,
          _marketSeries(
            base: 7.1,
            amplitude: 1.1,
            min: 4.5,
            max: 9.2,
            seed: 37,
            drift: 0.005,
          ),
          labels,
        ),
        const SizedBox(height: 12),
        _buildSleepBreakdown(),
        const SizedBox(height: 12),
        _buildBodyCompChart(),
        const SizedBox(height: 12),
        _buildHydrationTracker(),
        const SizedBox(height: 12),
        _buildBPHistory(),
        const SizedBox(height: 12),
        _buildDeviceSourcesCard(),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // TAB 3 — MENTAL (mood, energy, attitude, wellbeing)
  // ═══════════════════════════════════════════════════════

  Widget _buildMentalTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMoodTimeline(),
        const SizedBox(height: 12),
        _buildEnergyLevels(),
        const SizedBox(height: 12),
        _buildAttitudeRadar(),
        const SizedBox(height: 12),
        _buildStressPattern(),
        const SizedBox(height: 12),
        _buildMentalScoreBreakdown(),
        const SizedBox(height: 12),
        _buildWellbeingSummary(),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // TAB 4 — PERFORMANCE (training, combat, fitness)
  // ═══════════════════════════════════════════════════════

  Widget _buildPerformanceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildLoadRecoveryChart(),
        const SizedBox(height: 12),
        _buildCombatStatsCards(),
        const SizedBox(height: 12),
        _buildWeightCutTracker(),
        const SizedBox(height: 12),
        _buildFitnessMetrics(),
        const SizedBox(height: 12),
        _buildSessionHistory(),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // TAB 5 — TRENDS (long-term analytics + predictions)
  // ═══════════════════════════════════════════════════════

  Widget _buildTrendsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTrendSummaryCards(),
        const SizedBox(height: 12),
        _buildCorrelationMatrix(),
        const SizedBox(height: 12),
        _buildPredictiveInsights(),
        const SizedBox(height: 12),
        _buildWeeklyCompare(),
        const SizedBox(height: 12),
        _buildDataSourcesInfo(),
        const SizedBox(height: 12),
        _buildAgeGateNotice(),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  // SHARED BUILDERS
  // ─────────────────────────────────────────────────────

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: DesignTokens.neonCyan, size: 16),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _signalGrid(List<_Signal> signals) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: signals.map(_signalTile).toList(),
    );
  }

  Widget _signalTile(_Signal s) {
    return Container(
      width: (MediaQuery.of(context).size.width - 48) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: s.color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                s.label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: s.color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            s.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                s.status,
                style: TextStyle(
                  color: s.color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                s.delta,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: s.progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation(
                s.color.withValues(alpha: 0.5),
              ),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonMagenta.withValues(alpha: 0.08),
            DesignTokens.neonCyan.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DesignTokens.neonMagenta.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: DesignTokens.neonMagenta,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'AI Fight Intelligence',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (_loadingAiInsights)
                Row(
                  children: [
                    const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          DesignTokens.neonMagenta,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Shido analyzing…',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 9,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'Powered by Samurai Shido',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 9,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_aiInsights.isEmpty && !_loadingAiInsights) ...[
            _aiInsightRow(
              '🟢',
              'HRV trending up +12% this week — recovery improving. Optimal for hard sparring sessions tomorrow.',
            ),
            _aiInsightRow(
              '🟡',
              'Sleep quality dropped Thursday (6.3 hrs). Consider earlier bedtime to maintain recovery trajectory.',
            ),
            _aiInsightRow(
              '🟢',
              'Weight cut on track at 0.5 kg/week. Current pace hits 70.3 kg by fight night with 3% body fat buffer.',
            ),
            _aiInsightRow(
              '🔵',
              'Stress levels lowest on morning training days. Consider shifting afternoon sessions earlier.',
            ),
            _aiInsightRow(
              '🟡',
              'Hydration averaged 68% this week — below 75% target. Set hourly reminders during camp.',
            ),
          ] else ...[
            for (var i = 0; i < _aiInsights.length; i++)
              _aiInsightRow(i.isEven ? '🟢' : '🟡', _aiInsights[i]),
          ],
          const SizedBox(height: 10),
          // Share FightLab insight
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.share, size: 14),
              label: const Text('Share Insight'),
              style: TextButton.styleFrom(
                foregroundColor: DesignTokens.neonCyan,
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                final readiness =
                    (_esoEngine.currentWellness?.readinessScore ?? 85).toInt();
                final insightText = _aiInsights.isNotEmpty
                    ? _aiInsights.first
                    : 'HRV trending up +12% this week — recovery improving.';
                ShareService.instance.shareFightLabInsight(
                  insightText: insightText,
                  readinessScore: readiness,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiInsightRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAlerts() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.neonRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DesignTokens.neonRed.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber,
                color: DesignTokens.neonRed,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'Risk Alerts',
                style: TextStyle(
                  color: DesignTokens.neonRed,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: DesignTokens.neonAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '2 active',
                  style: TextStyle(
                    color: DesignTokens.neonAmber,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _riskRow(
            Icons.water_drop,
            'Dehydration Risk',
            'Hydration below 70% for 3+ consecutive days',
            DesignTokens.neonAmber,
          ),
          _riskRow(
            Icons.bedtime,
            'Sleep Debt',
            'Accumulated 3.2 hrs sleep deficit this week',
            DesignTokens.neonAmber,
          ),
        ],
      ),
    );
  }

  Widget _riskRow(IconData icon, String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // BIOMETRICS TAB BUILDERS
  // ─────────────────────────────────────────────────────

  Widget _buildBioChart(String title, Color color, List<_Zone> zones) {
    return _labCard(
      title: title,
      icon: Icons.favorite,
      color: color,
      child: Column(
        children: zones.map((z) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    z.label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 50,
                  child: Text(
                    z.range,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 9,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: z.pct,
                      backgroundColor: Colors.white.withValues(alpha: 0.04),
                      valueColor: AlwaysStoppedAnimation(
                        z.color.withValues(alpha: 0.7),
                      ),
                      minHeight: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${(z.pct * 100).round()}%',
                  style: TextStyle(
                    color: z.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineGraph(
    String title,
    Color color,
    List<double> data,
    List<String> labels,
  ) {
    return _labCard(
      title: title,
      icon: Icons.show_chart,
      color: color,
      child: SizedBox(
        height: 120,
        child: CustomPaint(
          painter: _LineGraphPainter(data: data, labels: labels, color: color),
          size: Size.infinite,
        ),
      ),
    );
  }

  Widget _buildSleepBreakdown() {
    return _labCard(
      title: 'Sleep Stages',
      icon: Icons.bedtime,
      color: DesignTokens.neonMagenta,
      child: Column(
        children: [
          _sleepRow('Deep', '1.8 hrs', 0.25, const Color(0xFF1E3A8A)),
          _sleepRow('Light', '3.2 hrs', 0.44, const Color(0xFF60A5FA)),
          _sleepRow('REM', '1.5 hrs', 0.21, DesignTokens.neonMagenta),
          _sleepRow('Awake', '0.7 hrs', 0.10, DesignTokens.neonRed),
        ],
      ),
    );
  }

  Widget _sleepRow(String stage, String hrs, double pct, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              stage,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ),
          SizedBox(
            width: 55,
            child: Text(
              hrs,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: Colors.white.withValues(alpha: 0.04),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${(pct * 100).round()}%',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyCompChart() {
    final labels = _timeLabels();

    return _labCard(
      title: 'Body Composition Trend',
      icon: Icons.accessibility_new,
      color: DesignTokens.neonAmber,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _bodyCompStat('Weight', '162.4', 'lbs', DesignTokens.neonAmber),
              _bodyCompStat('Body Fat', '12.8', '%', DesignTokens.neonRed),
              _bodyCompStat('Muscle', '68.2', 'lbs', DesignTokens.neonGreen),
              _bodyCompStat('BMI', '22.4', '', DesignTokens.neonCyan),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: CustomPaint(
              painter: _LineGraphPainter(
                data: _marketSeries(
                  base: 162.4,
                  amplitude: 2.2,
                  min: 150,
                  max: 175,
                  seed: 71,
                  drift: -0.03,
                ),
                labels: labels,
                color: DesignTokens.neonAmber,
              ),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bodyCompStat(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (unit.isNotEmpty)
              Text(
                unit,
                style: TextStyle(
                  color: color.withValues(alpha: 0.5),
                  fontSize: 9,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildHydrationTracker() {
    // HydrationService singleton for intake and reminders
    final hydrationService = HydrationService();
    final intakeMl = hydrationService.waterIntakeMl;
    final goalMl = 3000;
    final percent = (intakeMl / goalMl).clamp(0, 1).toDouble();
    final remainingMl = (goalMl - intakeMl).clamp(0, goalMl);
    final enabled = hydrationService.remindersEnabled;

    return _labCard(
      title: 'Hydration Analysis',
      icon: Icons.water_drop,
      color: DesignTokens.neonCyan,
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 50,
                height: 50,
                child: Center(
                  child: Text('💧', style: TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today: ${(intakeMl / 1000).toStringAsFixed(2)}L / 3.0L',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: percent,
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        valueColor: const AlwaysStoppedAnimation(
                          DesignTokens.neonCyan,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${(percent * 100).toStringAsFixed(0)}% — ${(remainingMl / 1000).toStringAsFixed(2)}L remaining',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              // Hydration alert toggle
              Column(
                children: [
                  Switch(
                    value: enabled,
                    activeThumbColor: DesignTokens.neonCyan,
                    onChanged: (val) {
                      setState(() {
                        hydrationService.setReminderEnabled(val);
                      });
                    },
                  ),
                  Text(
                    'Alerts',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _hydrationStat('Avg / Day', '2.4L', DesignTokens.neonCyan),
              _hydrationStat('Electrolytes', '840mg', DesignTokens.neonAmber),
              _hydrationStat('Sweatloss Est.', '1.2L/hr', DesignTokens.neonRed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hydrationStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildBPHistory() {
    return _labCard(
      title: 'Blood Pressure Trends',
      icon: Icons.favorite_border,
      color: DesignTokens.neonRed,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _bpReading('Systolic', '118', 'mmHg', DesignTokens.neonRed),
              _bpReading('Diastolic', '76', 'mmHg', const Color(0xFF60A5FA)),
              _bpReading('Pulse', '68', 'bpm', DesignTokens.neonGreen),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignTokens.neonGreen.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: DesignTokens.neonGreen,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'Blood pressure in optimal range. No hypertension risk detected.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '⚡ Smart devices estimate BP via photoplethysmography (PPG) + machine learning from wrist/finger sensors.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 9,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bpReading(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 9,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceSourcesCard() {
    final devices = [
      const _Device(
        'Apple Watch',
        Icons.watch,
        DesignTokens.neonCyan,
        'HR, HRV, SpO₂, BP est., ECG',
      ),
      const _Device(
        'Garmin',
        Icons.fitness_center,
        DesignTokens.neonGreen,
        'HR, HRV, stress, body battery',
      ),
      const _Device(
        'Whoop 4.0',
        Icons.sensors,
        DesignTokens.neonAmber,
        'Strain, recovery, sleep, skin temp',
      ),
      const _Device(
        'Oura Ring',
        Icons.circle_outlined,
        DesignTokens.neonMagenta,
        'Sleep, readiness, temp, HRV',
      ),
      const _Device(
        'Smart Scale',
        Icons.line_weight,
        Colors.white70,
        'Weight, body fat, muscle mass, BMI',
      ),
      const _Device(
        'Phone Camera',
        Icons.camera,
        DesignTokens.neonRed,
        'HR via PPG, stress estimate',
      ),
    ];
    return _labCard(
      title: 'Data Sources & Capabilities',
      icon: Icons.devices,
      color: DesignTokens.neonCyan,
      child: Column(
        children: devices.map((d) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: d.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(d.icon, color: d.color, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        d.metrics,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Connected',
                    style: TextStyle(
                      color: DesignTokens.neonGreen,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // MENTAL TAB BUILDERS
  // ─────────────────────────────────────────────────────

  Widget _buildMoodTimeline() {
    final moods = [
      const _MoodEntry('Mon', '😊', 4, DesignTokens.neonGreen),
      const _MoodEntry('Tue', '😐', 3, DesignTokens.neonAmber),
      const _MoodEntry('Wed', '😊', 4, DesignTokens.neonGreen),
      const _MoodEntry('Thu', '😤', 2, DesignTokens.neonRed),
      const _MoodEntry('Fri', '😁', 5, DesignTokens.neonCyan),
      const _MoodEntry('Sat', '😊', 4, DesignTokens.neonGreen),
      const _MoodEntry('Sun', '😊', 4, DesignTokens.neonGreen),
    ];
    return _labCard(
      title: 'Mood Timeline',
      icon: Icons.emoji_emotions,
      color: DesignTokens.neonGreen,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: moods.map((m) {
              return Column(
                children: [
                  Text(m.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Container(
                    width: 24,
                    height: m.score * 10.0,
                    decoration: BoxDecoration(
                      color: m.color.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    m.day,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Average Mood: 3.7 / 5',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
              const Text(
                '↑ 0.3 from last week',
                style: TextStyle(
                  color: DesignTokens.neonGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyLevels() {
    final labels = _timeLabels();

    return _labCard(
      title: 'Energy Patterns ($_timeRange)',
      icon: Icons.bolt,
      color: DesignTokens.neonAmber,
      child: Column(
        children: [
          SizedBox(
            height: 100,
            child: CustomPaint(
              painter: _LineGraphPainter(
                data: _marketSeries(
                  base: 62,
                  amplitude: 20,
                  min: 20,
                  max: 100,
                  seed: 101,
                ),
                labels: labels,
                color: DesignTokens.neonAmber,
              ),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _energyStat('Peak', '10am-12pm', DesignTokens.neonGreen),
              _energyStat('Low', '2-4pm', DesignTokens.neonRed),
              _energyStat('Avg', '62/100', DesignTokens.neonAmber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _energyStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 9,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildAttitudeRadar() {
    final attrs = [
      const _AttrScore('Confidence', 0.78),
      const _AttrScore('Focus', 0.82),
      const _AttrScore('Aggression', 0.65),
      const _AttrScore('Calmness', 0.70),
      const _AttrScore('Resilience', 0.85),
      const _AttrScore('Discipline', 0.90),
    ];
    return _labCard(
      title: 'Fighter Mindset Radar',
      icon: Icons.psychology,
      color: DesignTokens.neonMagenta,
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _RadarPainter(attributes: attrs),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: attrs.map((a) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${a.label}: ${(a.value * 100).round()}%',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStressPattern() {
    final labels = _timeLabels();

    return _labCard(
      title: 'Stress Pattern Analysis',
      icon: Icons.waves,
      color: DesignTokens.neonRed,
      child: Column(
        children: [
          SizedBox(
            height: 80,
            child: CustomPaint(
              painter: _LineGraphPainter(
                data: _marketSeries(
                  base: 34,
                  amplitude: 14,
                  min: 10,
                  max: 90,
                  seed: 133,
                  drift: -0.01,
                ),
                labels: labels,
                color: DesignTokens.neonRed,
              ),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignTokens.neonGreen.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.trending_down,
                  color: DesignTokens.neonGreen,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Stress trending down 15% — breathing exercises and recovery days are working.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentalScoreBreakdown() {
    final scores = [
      const _MentalScore('Self-Confidence', 78, DesignTokens.neonCyan),
      const _MentalScore('Fight Motivation', 85, DesignTokens.neonGreen),
      const _MentalScore('Anxiety Level', 22, DesignTokens.neonGreen),
      const _MentalScore('Emotional Stability', 75, DesignTokens.neonAmber),
      const _MentalScore('Mental Toughness', 82, DesignTokens.neonCyan),
      const _MentalScore('Focus Duration', 70, DesignTokens.neonAmber),
    ];
    return _labCard(
      title: 'Mental Performance Metrics',
      icon: Icons.speed,
      color: DesignTokens.neonCyan,
      child: Column(
        children: scores.map((s) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    s.label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: s.value / 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.04),
                      valueColor: AlwaysStoppedAnimation(
                        s.color.withValues(alpha: 0.6),
                      ),
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${s.value}',
                  style: TextStyle(
                    color: s.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWellbeingSummary() {
    return _labCard(
      title: 'Overall Wellbeing Score',
      icon: Icons.spa,
      color: DesignTokens.neonGreen,
      child: Column(
        children: [
          SizedBox(
            height: 100,
            width: 100,
            child: CustomPaint(
              painter: _ScoreRingPainter(
                score: 0.76,
                color: DesignTokens.neonGreen,
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '76',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '/ 100',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Wellbeing is GOOD. You\'re in a strong mental state for fight preparation.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // PERFORMANCE TAB BUILDERS
  // ─────────────────────────────────────────────────────

  Widget _buildLoadRecoveryChart() {
    final labels = _timeLabels();

    return _labCard(
      title: 'Training Load vs Recovery',
      icon: Icons.fitness_center,
      color: DesignTokens.neonAmber,
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: _DualLinePainter(
                data1: _marketSeries(
                  base: 650,
                  amplitude: 90,
                  min: 300,
                  max: 900,
                  seed: 191,
                  drift: -0.4,
                ),
                data2: _marketSeries(
                  base: 76,
                  amplitude: 10,
                  min: 40,
                  max: 100,
                  seed: 223,
                  drift: 0.05,
                ),
                labels: labels,
                color1: DesignTokens.neonAmber,
                color2: DesignTokens.neonGreen,
              ),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 10, height: 3, color: DesignTokens.neonAmber),
              const SizedBox(width: 4),
              Text(
                'Load (AU)',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 16),
              Container(width: 10, height: 3, color: DesignTokens.neonGreen),
              const SizedBox(width: 4),
              Text(
                'Recovery %',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCombatStatsCards() {
    return _labCard(
      title: 'Combat Statistics',
      icon: Icons.sports_mma,
      color: DesignTokens.neonRed,
      child: Column(
        children: [
          Row(
            children: [
              _combatStat('Rounds', '247', DesignTokens.neonCyan),
              _combatStat('Strikes/min', '42.3', DesignTokens.neonRed),
              _combatStat('Win Rate', '78%', DesignTokens.neonGreen),
              _combatStat('KO Rate', '34%', DesignTokens.neonAmber),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _combatStat('TD Avg', '3.2/rd', DesignTokens.neonMagenta),
              _combatStat('Sub Rate', '22%', const Color(0xFF60A5FA)),
              _combatStat('Def Rate', '85%', DesignTokens.neonGreen),
              _combatStat('Camp Days', '38', DesignTokens.neonAmber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _combatStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightCutTracker() {
    return _labCard(
      title: 'Weight Cut Progress',
      icon: Icons.monitor_weight,
      color: DesignTokens.neonAmber,
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current',
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  Text(
                    '73.7 kg / 162.4 lbs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Icon(
                    Icons.arrow_forward,
                    color: DesignTokens.neonAmber,
                    size: 20,
                  ),
                  Text(
                    '3.4 kg to go',
                    style: TextStyle(
                      color: DesignTokens.neonAmber,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Target',
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  Text(
                    '70.3 kg / 155.0 lbs',
                    style: TextStyle(
                      color: DesignTokens.neonGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.60,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: const AlwaysStoppedAnimation(DesignTokens.neonAmber),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '60% complete — On pace for fight night at 0.5 kg/week',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFitnessMetrics() {
    return _labCard(
      title: 'Fitness Benchmarks',
      icon: Icons.trending_up,
      color: DesignTokens.neonGreen,
      child: Column(
        children: [
          _fitnessRow(
            'VO₂ Max',
            '48.2 ml/kg/min',
            0.80,
            DesignTokens.neonGreen,
          ),
          _fitnessRow(
            'Lactate Threshold',
            '172 bpm',
            0.75,
            DesignTokens.neonAmber,
          ),
          _fitnessRow('Grip Strength', '52 kg', 0.85, DesignTokens.neonCyan),
          _fitnessRow('Reaction Time', '0.21s', 0.90, DesignTokens.neonMagenta),
          _fitnessRow(
            'Power Output',
            '1,850W peak',
            0.78,
            DesignTokens.neonRed,
          ),
        ],
      ),
    );
  }

  Widget _fitnessRow(String label, String value, double pct, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: Colors.white.withValues(alpha: 0.04),
                valueColor: AlwaysStoppedAnimation(
                  color.withValues(alpha: 0.6),
                ),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionHistory() {
    final sessions = [
      const _Session('Sparring (5 rds)', 'Today 10am', 680, DesignTokens.neonRed),
      const _Session('S&C Circuit', 'Yesterday 2pm', 520, DesignTokens.neonAmber),
      const _Session('Pad Work + Drills', 'Mon 9am', 450, DesignTokens.neonGreen),
      const _Session('Grappling (NoGi)', 'Sun 11am', 600, DesignTokens.neonMagenta),
      const _Session('Recovery + Yoga', 'Sat 8am', 180, DesignTokens.neonCyan),
    ];
    return _labCard(
      title: 'Recent Sessions',
      icon: Icons.history,
      color: Colors.white70,
      child: Column(
        children: sessions.map((s) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 32,
                  decoration: BoxDecoration(
                    color: s.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        s.when,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${s.load} AU',
                  style: TextStyle(
                    color: s.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // TRENDS TAB BUILDERS
  // ─────────────────────────────────────────────────────

  Widget _buildTrendSummaryCards() {
    return _labCard(
      title: '30-Day Trend Summary',
      icon: Icons.auto_graph,
      color: DesignTokens.neonCyan,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _trendChip('Fitness ↑12%', DesignTokens.neonGreen),
          _trendChip('Sleep ↑8%', DesignTokens.neonGreen),
          _trendChip('Stress ↓15%', DesignTokens.neonGreen),
          _trendChip('Weight ↓2.2 kg', DesignTokens.neonAmber),
          _trendChip('Mood ↑0.5', DesignTokens.neonGreen),
          _trendChip('HRV ↑18%', DesignTokens.neonGreen),
          _trendChip('Recovery ↑10%', DesignTokens.neonGreen),
          _trendChip('Hydration ↓4%', DesignTokens.neonRed),
        ],
      ),
    );
  }

  Widget _trendChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCorrelationMatrix() {
    final correlations = [
      const _Correlation('Sleep → Recovery', 0.87, 'Strong positive'),
      const _Correlation('Stress → Performance', -0.62, 'Moderate negative'),
      const _Correlation('HRV → Readiness', 0.79, 'Strong positive'),
      const _Correlation('Training Load → Fatigue', 0.71, 'Moderate positive'),
      const _Correlation('Hydration → Energy', 0.55, 'Moderate positive'),
      const _Correlation('Mood → Motivation', 0.83, 'Strong positive'),
    ];
    return _labCard(
      title: 'AI Correlation Analysis',
      icon: Icons.auto_awesome,
      color: DesignTokens.neonMagenta,
      child: Column(
        children: correlations.map((c) {
          final isPositive = c.value > 0;
          final absVal = c.value.abs();
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    c.label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: absVal,
                      backgroundColor: Colors.white.withValues(alpha: 0.04),
                      valueColor: AlwaysStoppedAnimation(
                        isPositive
                            ? DesignTokens.neonGreen.withValues(alpha: 0.6)
                            : DesignTokens.neonRed.withValues(alpha: 0.6),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 36,
                  child: Text(
                    c.value.toStringAsFixed(2),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: isPositive
                          ? DesignTokens.neonGreen
                          : DesignTokens.neonRed,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPredictiveInsights() {
    return _labCard(
      title: 'Predictive Intelligence',
      icon: Icons.lightbulb,
      color: DesignTokens.neonGold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _predictionRow(
            '🎯',
            'Fight Night Readiness',
            '87% projected (up from 82%)',
            DesignTokens.neonGreen,
          ),
          _predictionRow(
            '⚖️',
            'Weight Target',
            '95% probability to make 155 by fight night',
            DesignTokens.neonGreen,
          ),
          _predictionRow(
            '⚡',
            'Peak Performance Window',
            'Thursday 10am-1pm (based on 30-day pattern)',
            DesignTokens.neonCyan,
          ),
          _predictionRow(
            '🛌',
            'Recovery Forecast',
            'Full recovery by Wednesday if load stays below 600 AU',
            DesignTokens.neonAmber,
          ),
          _predictionRow(
            '🧠',
            'Mental State Projection',
            'Confidence will peak at fight week if trend continues',
            DesignTokens.neonMagenta,
          ),
        ],
      ),
    );
  }

  Widget _predictionRow(String emoji, String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCompare() {
    return _labCard(
      title: 'Week-over-Week',
      icon: Icons.compare_arrows,
      color: DesignTokens.neonCyan,
      child: Column(
        children: [
          _compareRow('Training Vol', '3,420 AU', '3,180 AU', true),
          _compareRow('Avg Sleep', '7.2 hrs', '6.8 hrs', true),
          _compareRow('Avg HR', '68 bpm', '70 bpm', true),
          _compareRow('Stress Avg', '32', '38', true),
          _compareRow('Recovery Avg', '78%', '72%', true),
          _compareRow('Weight', '162.4', '163.5', true),
        ],
      ),
    );
  }

  Widget _compareRow(
    String metric,
    String thisWeek,
    String lastWeek,
    bool improved,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              metric,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              thisWeek,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              lastWeek,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 11,
              ),
            ),
          ),
          Icon(
            improved ? Icons.trending_up : Icons.trending_down,
            color: improved ? DesignTokens.neonGreen : DesignTokens.neonRed,
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildDataSourcesInfo() {
    return _labCard(
      title: 'Smart Device Biometric Capabilities',
      icon: Icons.info_outline,
      color: Colors.white70,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(
            'Heart Rate / HRV',
            'Optical PPG sensors on wrist/finger. Accuracy: ±2 bpm. Available on all smartwatches.',
          ),
          _infoRow(
            'Blood Oxygen (SpO₂)',
            'Red + infrared LED sensors. Available on Apple Watch 6+, Garmin, Samsung, Fitbit.',
          ),
          _infoRow(
            'Skin Temperature',
            'Infrared thermometer on Oura Ring, Whoop 4.0, Fitbit Sense. ±0.1°C accuracy.',
          ),
          _infoRow(
            'Blood Pressure',
            'Estimated via pulse wave analysis (PPG + ML). Samsung Galaxy Watch 5+ has FDA-cleared cuff-calibrated BP. Phone camera can estimate via fingertip PPG.',
          ),
          _infoRow(
            'Body Fat / BMI',
            'Bioelectrical impedance (BIA) via smart scales (Withings, Garmin Index). ±3% accuracy. Not available from wrist devices alone.',
          ),
          _infoRow(
            'Stress / Cortisol',
            'Estimated from HRV variance + electrodermal activity (EDA). Garmin, Fitbit, Samsung offer stress scores. Direct cortisol not yet consumer-available.',
          ),
          _infoRow(
            'Hydration',
            'Currently estimated from activity + environment + intake logging. No passive sensor yet consumer-ready. Research devices (Nix, Epicore) use sweat analysis.',
          ),
          _infoRow(
            'ECG / Arrhythmia',
            'Apple Watch Series 4+, Samsung Galaxy Watch, Withings Scanwatch. FDA/CE-cleared for atrial fibrillation detection.',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: DesignTokens.neonCyan,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            desc,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeGateNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.neonAmber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DesignTokens.neonAmber.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield, color: DesignTokens.neonAmber, size: 16),
              SizedBox(width: 6),
              Text(
                'Age & Safety Policy',
                style: TextStyle(
                  color: DesignTokens.neonAmber,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• FightLab is available to users aged 16 and over\n'
            '• Users under 18 have parental consent requirements for biometric data collection\n'
            '• No trolling, bullying, or indecent content is tolerated\n'
            '• All health data is encrypted and GDPR/COPPA compliant\n'
            '• Biometric readings are informational only — not medical advice\n'
            '• Always consult a medical professional before making health decisions',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 10,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.power, color: DesignTokens.neonCyan, size: 14),
              SizedBox(width: 6),
              Text(
                'Infrastructure & Power',
                style: TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '• Firebase Blaze Plan: ~\$200-500/mo at scale (Firestore, Auth, Functions, Storage)\n'
            '• Cloud Functions (Node.js): AI inference, real-time processing, push notifications\n'
            '• Gemini / Vertex AI: Fight intelligence ML models (\$50-200/mo for inference)\n'
            '• Firebase Hosting + CDN: Web app delivery (~\$25/mo)\n'
            '• Apple / Google Health APIs: Free (included in platform SDKs)\n'
            '• Wearable SDKs (Garmin, Whoop, etc.): Free developer access\n'
            '• Total estimated power: \$300-800/mo at 10K MAU, scaling with usage',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // CARD WRAPPER
  // ─────────────────────────────────────────────────────

  Widget _labCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12121A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Export FightLab Data',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _exportOption(
                Icons.picture_as_pdf,
                'Export as PDF Report',
                DesignTokens.neonRed,
              ),
              _exportOption(
                Icons.table_chart,
                'Export as CSV',
                DesignTokens.neonGreen,
              ),
              _exportOption(
                Icons.share,
                'Share Summary',
                DesignTokens.neonCyan,
              ),
              _exportOption(Icons.print, 'Print Report', Colors.white70),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exportOption(IconData icon, String label, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
      ),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label — this module is in development'),
            backgroundColor: const Color(0xFF1A1A2E),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════

class _ScoreRingPainter extends CustomPainter {
  final double score;
  final Color color;
  _ScoreRingPainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 4;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    // Score arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * score,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LineGraphPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final Color color;
  _LineGraphPainter({
    required this.data,
    required this.labels,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = data.reduce(max);
    final minVal = data.reduce(min);
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = i * size.width / (data.length - 1);
      final y =
          size.height - ((data[i] - minVal) / range) * (size.height * 0.85);
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Fill
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    // Dots
    for (final p in points) {
      canvas.drawCircle(p, 3, Paint()..color = color);
      canvas.drawCircle(p, 1.5, Paint()..color = Colors.white);
    }

    // Labels
    for (int i = 0; i < labels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 8,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          i * size.width / (data.length - 1) - tp.width / 2,
          size.height + 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DualLinePainter extends CustomPainter {
  final List<double> data1, data2;
  final List<String> labels;
  final Color color1, color2;
  _DualLinePainter({
    required this.data1,
    required this.data2,
    required this.labels,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawLine(canvas, size, data1, color1);
    _drawLine(canvas, size, data2, color2);
  }

  void _drawLine(Canvas canvas, Size size, List<double> data, Color color) {
    if (data.isEmpty) return;
    final maxVal = data.reduce(max);
    final minVal = data.reduce(min);
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * size.width / (data.length - 1);
      final y =
          size.height - ((data[i] - minVal) / range) * (size.height * 0.85);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RadarPainter extends CustomPainter {
  final List<_AttrScore> attributes;
  _RadarPainter({required this.attributes});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 20;
    final n = attributes.length;

    // Draw rings
    for (int ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      final ringPath = Path();
      for (int i = 0; i <= n; i++) {
        final angle = -pi / 2 + 2 * pi * (i % n) / n;
        final p = Offset(
          center.dx + r * cos(angle),
          center.dy + r * sin(angle),
        );
        if (i == 0) {
          ringPath.moveTo(p.dx, p.dy);
        } else {
          ringPath.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(
        ringPath,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.05)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    // Draw axes + labels
    for (int i = 0; i < n; i++) {
      final angle = -pi / 2 + 2 * pi * i / n;
      final end = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawLine(
        center,
        end,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.06)
          ..strokeWidth = 0.5,
      );

      final labelOffset = Offset(
        center.dx + (radius + 14) * cos(angle),
        center.dy + (radius + 14) * sin(angle),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: attributes[i].label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 8,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(labelOffset.dx - tp.width / 2, labelOffset.dy - tp.height / 2),
      );
    }

    // Draw data polygon
    final dataPath = Path();
    for (int i = 0; i <= n; i++) {
      final angle = -pi / 2 + 2 * pi * (i % n) / n;
      final r = radius * attributes[i % n].value;
      final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      if (i == 0) {
        dataPath.moveTo(p.dx, p.dy);
      } else {
        dataPath.lineTo(p.dx, p.dy);
      }
    }

    canvas.drawPath(
      dataPath,
      Paint()
        ..color = DesignTokens.neonCyan.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = DesignTokens.neonCyan.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Data points
    for (int i = 0; i < n; i++) {
      final angle = -pi / 2 + 2 * pi * i / n;
      final r = radius * attributes[i].value;
      final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      canvas.drawCircle(p, 3, Paint()..color = DesignTokens.neonCyan);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════

class _Signal {
  final String label, value, status, delta;
  final Color color;
  final double progress;
  const _Signal(
    this.label,
    this.value,
    this.status,
    this.color,
    this.progress,
    this.delta,
  );
}

class _Zone {
  final String label, range;
  final double pct;
  final Color color;
  const _Zone(this.label, this.range, this.pct, this.color);
}

class _Device {
  final String name, metrics;
  final IconData icon;
  final Color color;
  const _Device(this.name, this.icon, this.color, this.metrics);
}

class _MoodEntry {
  final String day, emoji;
  final int score;
  final Color color;
  const _MoodEntry(this.day, this.emoji, this.score, this.color);
}

class _MentalScore {
  final String label;
  final int value;
  final Color color;
  const _MentalScore(this.label, this.value, this.color);
}

class _AttrScore {
  final String label;
  final double value;
  const _AttrScore(this.label, this.value);
}

class _Correlation {
  final String label, desc;
  final double value;
  const _Correlation(this.label, this.value, this.desc);
}

class _Session {
  final String name, when;
  final int load;
  final Color color;
  const _Session(this.name, this.when, this.load, this.color);
}
// ══════════════════════════════════════════════════════════════════════════════
// ──  Custom Painters  ─────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _TelemetryGridPainter extends CustomPainter {
  final double phase;

  _TelemetryGridPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0x1A00FFFF) // Cyan with low alpha
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TelemetryGridPainter oldDelegate) {
    return phase != oldDelegate.phase;
  }
}

class _AnimatedScoreRingPainter extends CustomPainter {
  final double score;
  final Color color;
  final double glowPhase;
  final double sweepPhase;

  _AnimatedScoreRingPainter({
    required this.score,
    required this.color,
    required this.glowPhase,
    required this.sweepPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    // Score arc
    final scorePaint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * 3.14159 * score * sweepPhase;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // Start at top
      sweepAngle,
      false,
      scorePaint,
    );

    // Glow effect
    if (glowPhase > 0.5) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3 * (1.0 - glowPhase))
        ..strokeWidth = 8.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 / 2,
        sweepAngle,
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedScoreRingPainter oldDelegate) {
    return score != oldDelegate.score ||
        color != oldDelegate.color ||
        glowPhase != oldDelegate.glowPhase ||
        sweepPhase != oldDelegate.sweepPhase;
  }
}
