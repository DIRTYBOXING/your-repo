import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/adrenaline_theme.dart';
import '../../../widgets/fight_pipe_painter.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// VISUAL ENGINE ROOM — "Open Kitchen" Industrial Pipeline Dashboard
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Watch your fight data cook in real time. Every pipe, tank, and gauge
/// visualizes the live DFC pipeline — from OBS ingest to global delivery.
///
///  ┌─────────┐    ┌──────────┐    ┌─────────┐    ┌──────────┐
///  │ INTAKE  │━━━▸│TRANSCODE │━━━▸│  EDGE   │━━━▸│ VIEWERS  │
///  │ OBS/SRT │    │  TANK    │    │  CDN    │    │  GLOBAL  │
///  └─────────┘    └──────────┘    └─────────┘    └──────────┘
///       ↑              ↑              ↑              ↑
///   Bitrate PSI    Liquid Fire    Latency PSI     CCV Volume
///
///  ┌───────────────────────────────────────────────────────────┐
///  │              n8n BRAIN PIPELINE (6 stages)               │
///  │  Webhook → Gemini AI → Prepare → Facebook → Email → ✓   │
///  └───────────────────────────────────────────────────────────┘
///
/// ═══════════════════════════════════════════════════════════════════════════
class VisualEngineRoomScreen extends StatefulWidget {
  const VisualEngineRoomScreen({super.key});

  @override
  State<VisualEngineRoomScreen> createState() => _VisualEngineRoomScreenState();
}

class _VisualEngineRoomScreenState extends State<VisualEngineRoomScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ──
  late AnimationController _flowCtrl; // Pipe flow animation
  late AnimationController _pulseCtrl; // Junction/glow pulse
  late AnimationController _tankCtrl; // Tank bubble animation
  late AnimationController _brainCtrl; // n8n brain stage progression

  Timer? _metricsTimer;

  // ── Pipeline state ──
  bool _isLive = false;
  int _activeStage = -1; // n8n brain active stage (-1 = idle)

  // ── Metrics (simulated — wire to Mux Data API in production) ──
  double _ingestBitrateKbps = 0;
  double _latencyMs = 0;
  double _rebufferPct = 0;
  int _ccv = 0;
  int _peakCcv = 0;
  double _tankLevel = 0; // Transcode buffer fill 0→1
  double _edgePressure = 0; // CDN pressure 0→1
  int _packetsThrough = 0;
  double _revenueAud = 0;
  int _n8nJobsProcessed = 0;

  // ── Pipeline stages ──
  static const _pipelineStages = [
    _PipeStation('INTAKE', 'OBS / SRT', Icons.videocam, Color(0xFF00F5FF)),
    _PipeStation(
      'TRANSCODE',
      'Mux Low-Lat',
      Icons.local_fire_department,
      Color(0xFFFF6B00),
    ),
    _PipeStation(
      'EDGE CDN',
      'HLS Delivery',
      Icons.cell_tower,
      Color(0xFF00FF88),
    ),
    _PipeStation('VIEWERS', 'Global Glass', Icons.groups, Color(0xFFFFD700)),
  ];

  // ── n8n Brain stages (from the attached workflow) ──
  static const _brainStages = [
    _BrainNode('WEBHOOK', Icons.webhook, Color(0xFF00F5FF)),
    _BrainNode('GEMINI AI', Icons.auto_awesome, Color(0xFF9D00FF)),
    _BrainNode('PREPARE', Icons.build_circle, Color(0xFFFFB800)),
    _BrainNode('FACEBOOK', Icons.share, Color(0xFF1877F2)),
    _BrainNode('EMAIL', Icons.email, Color(0xFF00FF88)),
    _BrainNode('RESPOND', Icons.check_circle, Color(0xFFFF1744)),
  ];

  @override
  void initState() {
    super.initState();

    _flowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _tankCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _brainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _metricsTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_isLive) _tickMetrics();
    });
  }

  void _tickMetrics() {
    final rng = math.Random();
    setState(() {
      _ingestBitrateKbps = 3500 + rng.nextDouble() * 2000;
      _latencyMs = 1800 + rng.nextDouble() * 1200;
      _rebufferPct = rng.nextDouble() * 0.35;
      _ccv = math.min(_ccv + rng.nextInt(8), 800);
      if (_ccv > _peakCcv) _peakCcv = _ccv;
      _tankLevel = 0.3 + rng.nextDouble() * 0.5;
      _edgePressure = (_latencyMs / 5000).clamp(0.0, 1.0);
      _packetsThrough += 30 + rng.nextInt(50);
      _revenueAud += rng.nextDouble() * 5;
    });
  }

  void _toggleLive() {
    setState(() {
      _isLive = !_isLive;
      if (!_isLive) {
        _ccv = 0;
        _ingestBitrateKbps = 0;
        _latencyMs = 0;
        _rebufferPct = 0;
        _tankLevel = 0;
        _edgePressure = 0;
      }
    });
  }

  void _fireN8nBrain() {
    _activeStage = 0;
    _brainCtrl.reset();
    _brainCtrl.forward();
    _brainCtrl.addListener(() {
      final newStage = (_brainCtrl.value * _brainStages.length).floor();
      if (newStage != _activeStage && newStage < _brainStages.length) {
        setState(() => _activeStage = newStage);
      }
    });
    _brainCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _activeStage = _brainStages.length; // all done
          _n8nJobsProcessed++;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _activeStage = -1);
        });
      }
    });
  }

  @override
  void dispose() {
    _metricsTimer?.cancel();
    _flowCtrl.dispose();
    _pulseCtrl.dispose();
    _tankCtrl.dispose();
    _brainCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ═══ THE PIPELINE — Visual flowing pipe network ═══
            _deckLabel(
              'THE PIPELINE',
              Icons.plumbing,
              'Melbourne Pavilion → Global Edge',
            ),
            const SizedBox(height: 12),
            _buildPipelineNetwork(),
            const SizedBox(height: 24),

            // ═══ PRESSURE GAUGES — NASA PSI meters ═══
            _deckLabel('PRESSURE GAUGES', Icons.speed, 'System Vitals'),
            const SizedBox(height: 12),
            _buildPressureGauges(),
            const SizedBox(height: 24),

            // ═══ THE FURNACE — Processing tank with liquid fire ═══
            _deckLabel(
              'THE FURNACE',
              Icons.local_fire_department,
              'Transcode Chamber',
            ),
            const SizedBox(height: 12),
            _buildFurnace(),
            const SizedBox(height: 24),

            // ═══ n8n BRAIN — Content pipeline visualization ═══
            _deckLabel('DFC BRAIN', Icons.psychology, 'n8n Content Automation'),
            const SizedBox(height: 12),
            _buildBrainPipeline(),
            const SizedBox(height: 24),

            // ═══ STEAM COUNTER — Throughput metrics ═══
            _deckLabel('STEAM WORKS', Icons.analytics, 'Throughput & Revenue'),
            const SizedBox(height: 12),
            _buildSteamWorks(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════════════════
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: DesignTokens.bgPrimary,
      elevation: 0,
      title: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, _) => Icon(
              Icons.engineering,
              color: _isLive
                  ? AdrenalineTheme.electricCrimson.withValues(
                      alpha: 0.5 + _pulseCtrl.value * 0.5,
                    )
                  : DesignTokens.neonCyan.withValues(
                      alpha: 0.5 + _pulseCtrl.value * 0.3,
                    ),
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'ENGINE ROOM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(width: 12),
          _liveChip(),
        ],
      ),
      actions: [
        // Ignition switch
        TextButton.icon(
          onPressed: _toggleLive,
          icon: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, _) => Icon(
              _isLive ? Icons.power_settings_new : Icons.power_off,
              color: _isLive
                  ? AdrenalineTheme.electricCrimson.withValues(
                      alpha: 0.6 + _pulseCtrl.value * 0.4,
                    )
                  : Colors.grey,
              size: 20,
            ),
          ),
          label: Text(
            _isLive ? 'KILL ENGINE' : 'IGNITION',
            style: TextStyle(
              color: _isLive
                  ? AdrenalineTheme.electricCrimson
                  : DesignTokens.neonCyan,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _liveChip() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: _isLive
              ? AdrenalineTheme.electricCrimson.withValues(
                  alpha: _pulseCtrl.value * 0.3,
                )
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isLive
                ? AdrenalineTheme.electricCrimson.withValues(alpha: 0.6)
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLive) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AdrenalineTheme.electricCrimson,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AdrenalineTheme.electricCrimson.withValues(
                        alpha: _pulseCtrl.value,
                      ),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              _isLive ? 'COMBUSTING' : 'COLD',
              style: TextStyle(
                color: _isLive ? AdrenalineTheme.electricCrimson : Colors.grey,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DECK LABEL
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _deckLabel(String title, IconData icon, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: DesignTokens.neonCyan, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: DesignTokens.neonCyan,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. THE PIPELINE — 4-station flowing pipe network
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPipelineNetwork() {
    return _industrialCard(
      child: Column(
        children: [
          // Station labels
          Row(
            children: _pipelineStages
                .map((s) => Expanded(child: _stationLabel(s)))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Pipe network — junctions connected by flowing pipes
          SizedBox(
            height: 80,
            child: AnimatedBuilder(
              animation: Listenable.merge([_flowCtrl, _pulseCtrl]),
              builder: (_, _) => LayoutBuilder(
                builder: (_, constraints) {
                  final w = constraints.maxWidth;
                  final segW = w / _pipelineStages.length;
                  final junctions = List.generate(
                    _pipelineStages.length,
                    (i) => Offset(segW * i + segW / 2, 40),
                  );

                  return Stack(
                    children: [
                      // Flowing pipes between junctions
                      for (var i = 0; i < junctions.length - 1; i++)
                        Positioned(
                          left: junctions[i].dx,
                          top: 28,
                          width: junctions[i + 1].dx - junctions[i].dx,
                          height: 24,
                          child: CustomPaint(
                            painter: PipeFlowPainter(
                              flowPhase: _flowCtrl.value,
                              intensity: _isLive
                                  ? 0.7 + (_ingestBitrateKbps / 10000)
                                  : 0.1,
                              pipeColor: _pipelineStages[i].color,
                              isActive: _isLive,
                              strokeWidth: 5,
                            ),
                            size: Size.infinite,
                          ),
                        ),

                      // Junction nodes
                      for (var i = 0; i < junctions.length; i++)
                        Positioned(
                          left: junctions[i].dx - 20,
                          top: junctions[i].dy - 20,
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: CustomPaint(
                              painter: PipeJunctionPainter(
                                color: _pipelineStages[i].color,
                                pulseValue: _pulseCtrl.value,
                                isActive: _isLive,
                                isError: _isLive && i == 2 && _latencyMs > 4000,
                              ),
                              child: Center(
                                child: Icon(
                                  _pipelineStages[i].icon,
                                  color: _isLive
                                      ? _pipelineStages[i].color.withValues(
                                          alpha: 0.9,
                                        )
                                      : Colors.grey.withValues(alpha: 0.4),
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Mini-metrics under each station
          Row(
            children: [
              Expanded(
                child: _stationMetric(
                  '${(_ingestBitrateKbps / 1000).toStringAsFixed(1)} Mbps',
                  _isLive ? DesignTokens.neonCyan : Colors.grey,
                ),
              ),
              Expanded(
                child: _stationMetric(
                  _isLive ? 'PROCESSING' : 'IDLE',
                  _isLive ? const Color(0xFFFF6B00) : Colors.grey,
                ),
              ),
              Expanded(
                child: _stationMetric(
                  '${(_latencyMs / 1000).toStringAsFixed(1)}s',
                  _isLive
                      ? (_latencyMs < 3000
                            ? DesignTokens.neonGreen
                            : AdrenalineTheme.warningOrange)
                      : Colors.grey,
                ),
              ),
              Expanded(
                child: _stationMetric(
                  '$_ccv CCV',
                  _isLive ? const Color(0xFFFFD700) : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stationLabel(_PipeStation s) {
    return Column(
      children: [
        Text(
          s.name,
          style: TextStyle(
            color: _isLive ? s.color : Colors.grey.withValues(alpha: 0.5),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          s.subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.25),
            fontSize: 8,
          ),
        ),
      ],
    );
  }

  Widget _stationMetric(String value, Color color) {
    return Text(
      value,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. PRESSURE GAUGES — PSI meters for system vitals
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPressureGauges() {
    return _industrialCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Bitrate PSI
          PressureGaugeWidget(
            label: 'INGEST PSI',
            valueText: _isLive
                ? '${(_ingestBitrateKbps / 1000).toStringAsFixed(1)}\nMbps'
                : '—',
            value: (_ingestBitrateKbps / 6000).clamp(0.0, 1.0),
            dangerThreshold: 0.9,
            warningThreshold: 0.7,
            size: 110,
          ),

          // Latency PSI
          PressureGaugeWidget(
            label: 'LATENCY PSI',
            valueText: _isLive
                ? '${(_latencyMs / 1000).toStringAsFixed(1)}s'
                : '—',
            value: (_latencyMs / 5000).clamp(0.0, 1.0),
            dangerThreshold: 0.6, // > 3s = danger
            warningThreshold: 0.4, // > 2s = warning
            normalColor: DesignTokens.neonGreen,
            size: 110,
          ),

          // CCV Volume
          PressureGaugeWidget(
            label: 'CCV VOLUME',
            valueText: _isLive ? '$_ccv' : '—',
            value: (_ccv / 500).clamp(0.0, 1.0),
            dangerThreshold: 0.95, // capacity warning
            warningThreshold: 0.8,
            normalColor: const Color(0xFFFFD700),
            size: 110,
          ),

          // Rebuffer Risk
          PressureGaugeWidget(
            label: 'REBUFFER %',
            valueText: _isLive ? '${_rebufferPct.toStringAsFixed(2)}%' : '—',
            value: (_rebufferPct / 1.0).clamp(0.0, 1.0),
            dangerThreshold: 0.5,
            warningThreshold: 0.2,
            normalColor: DesignTokens.neonGreen,
            size: 110,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. THE FURNACE — Processing tank with bubbling liquid
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFurnace() {
    return _industrialCard(
      child: Row(
        children: [
          // Intake pipe → Tank
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _miniLabel('INGEST PIPE'),
                const SizedBox(height: 6),
                SizedBox(
                  height: 30,
                  child: AnimatedBuilder(
                    animation: _flowCtrl,
                    builder: (_, _) => CustomPaint(
                      painter: PipeFlowPainter(
                        flowPhase: _flowCtrl.value,
                        intensity: _isLive ? 0.8 : 0.1,
                        isActive: _isLive,
                        strokeWidth: 8,
                        waypoints: const [
                          Offset(0, 0.5),
                          Offset(0.5, 0.3),
                          Offset(1.0, 0.5),
                        ],
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isLive ? 'FLOWING' : 'DRY',
                  style: TextStyle(
                    color: _isLive ? DesignTokens.neonCyan : Colors.grey,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          // The Tank
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _miniLabel('TRANSCODE CHAMBER'),
                const SizedBox(height: 6),
                AnimatedBuilder(
                  animation: _tankCtrl,
                  builder: (_, _) => CustomPaint(
                    painter: TankPainter(
                      level: _isLive ? _tankLevel : 0.0,
                      bubblePhase: _tankCtrl.value,
                      liquidColor: _isLive
                          ? Color.lerp(
                              DesignTokens.neonCyan,
                              AdrenalineTheme.electricCrimson,
                              _tankLevel,
                            )!
                          : DesignTokens.neonCyan,
                      isProcessing: _isLive,
                    ),
                    size: const Size(double.infinity, 130),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, _) => Text(
                    _isLive ? '🔥 LIQUID FIRE ACTIVE' : 'CHAMBER COLD',
                    style: TextStyle(
                      color: _isLive
                          ? AdrenalineTheme.electricCrimson.withValues(
                              alpha: 0.6 + _pulseCtrl.value * 0.4,
                            )
                          : Colors.grey.withValues(alpha: 0.4),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Output pipe → CDN
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _miniLabel('CDN OUTPUT'),
                const SizedBox(height: 6),
                SizedBox(
                  height: 30,
                  child: AnimatedBuilder(
                    animation: _flowCtrl,
                    builder: (_, _) => CustomPaint(
                      painter: PipeFlowPainter(
                        flowPhase: _flowCtrl.value,
                        intensity: _isLive ? 0.7 : 0.1,
                        pipeColor: DesignTokens.neonGreen,
                        isActive: _isLive,
                        strokeWidth: 8,
                        waypoints: const [
                          Offset(0, 0.5),
                          Offset(0.5, 0.7),
                          Offset(1.0, 0.5),
                        ],
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isLive ? 'DELIVERING' : 'STANDBY',
                  style: TextStyle(
                    color: _isLive ? DesignTokens.neonGreen : Colors.grey,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. DFC BRAIN — n8n pipeline visualization
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBrainPipeline() {
    return _industrialCard(
      child: Column(
        children: [
          // Brain node chain
          SizedBox(
            height: 90,
            child: AnimatedBuilder(
              animation: Listenable.merge([_flowCtrl, _pulseCtrl]),
              builder: (_, _) => LayoutBuilder(
                builder: (_, constraints) {
                  final w = constraints.maxWidth;
                  final nodeW = w / _brainStages.length;

                  return Stack(
                    children: [
                      // Connecting pipes between brain nodes
                      for (var i = 0; i < _brainStages.length - 1; i++)
                        Positioned(
                          left: nodeW * i + nodeW / 2 + 16,
                          top: 32,
                          width: nodeW - 32,
                          height: 16,
                          child: CustomPaint(
                            painter: PipeFlowPainter(
                              flowPhase: _flowCtrl.value,
                              intensity: _activeStage > i ? 0.9 : 0.1,
                              pipeColor: _brainStages[i].color,
                              isActive: _activeStage > i,
                              strokeWidth: 3,
                            ),
                            size: Size.infinite,
                          ),
                        ),

                      // Brain nodes
                      for (var i = 0; i < _brainStages.length; i++)
                        Positioned(
                          left: nodeW * i + nodeW / 2 - 18,
                          top: 22,
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: CustomPaint(
                              painter: PipeJunctionPainter(
                                color: _brainStages[i].color,
                                pulseValue: _activeStage == i
                                    ? _pulseCtrl.value
                                    : 0.3,
                                isActive: _activeStage >= i,
                              ),
                              child: Center(
                                child: Icon(
                                  _brainStages[i].icon,
                                  color: _activeStage >= i
                                      ? _brainStages[i].color
                                      : Colors.grey.withValues(alpha: 0.3),
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Stage labels
                      for (var i = 0; i < _brainStages.length; i++)
                        Positioned(
                          left: nodeW * i,
                          top: 64,
                          width: nodeW,
                          child: Text(
                            _brainStages[i].name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _activeStage >= i
                                  ? _brainStages[i].color.withValues(alpha: 0.9)
                                  : Colors.white.withValues(alpha: 0.2),
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Fire button + status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Fire n8n brain button
              GestureDetector(
                onTap: _activeStage == -1 ? _fireN8nBrain : null,
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, _) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _activeStage == -1
                          ? DesignTokens.neonCyan.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _activeStage == -1
                            ? DesignTokens.neonCyan.withValues(
                                alpha: 0.4 + _pulseCtrl.value * 0.3,
                              )
                            : Colors.grey.withValues(alpha: 0.2),
                      ),
                      boxShadow: _activeStage == -1
                          ? [
                              BoxShadow(
                                color: DesignTokens.neonCyan.withValues(
                                  alpha: _pulseCtrl.value * 0.2,
                                ),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _activeStage == -1 ? Icons.bolt : Icons.hourglass_top,
                          color: _activeStage == -1
                              ? DesignTokens.neonCyan
                              : Colors.grey,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _activeStage == -1
                              ? 'FIRE BRAIN'
                              : _activeStage >= _brainStages.length
                              ? 'COMPLETE ✓'
                              : 'PROCESSING...',
                          style: TextStyle(
                            color: _activeStage == -1
                                ? DesignTokens.neonCyan
                                : Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '$_n8nJobsProcessed jobs processed',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. STEAM WORKS — Throughput counters + revenue
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSteamWorks() {
    return _industrialCard(
      child: Row(
        children: [
          _steamCounter(
            'PACKETS',
            _formatNum(_packetsThrough),
            DesignTokens.neonCyan,
          ),
          _steamDivider(),
          _steamCounter(
            'PEAK CCV',
            _peakCcv.toString(),
            const Color(0xFFFFD700),
          ),
          _steamDivider(),
          _steamCounter(
            'REVENUE',
            '\$${_revenueAud.toStringAsFixed(2)}',
            DesignTokens.neonGreen,
          ),
          _steamDivider(),
          _steamCounter(
            'BRAIN JOBS',
            '$_n8nJobsProcessed',
            DesignTokens.neonPurple,
          ),
          _steamDivider(),
          _steamCounter(
            'EDGE PSI',
            '${(_edgePressure * 100).toStringAsFixed(0)}%',
            _edgePressure > 0.6
                ? AdrenalineTheme.electricCrimson
                : DesignTokens.neonGreen,
          ),
        ],
      ),
    );
  }

  Widget _steamCounter(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _steamDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withValues(alpha: 0.06),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _industrialCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.neonCyan.withValues(alpha: 0.03),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _miniLabel(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.3),
        fontSize: 8,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
      ),
    );
  }

  String _formatNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ── Data classes ──
class _PipeStation {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _PipeStation(this.name, this.subtitle, this.icon, this.color);
}

class _BrainNode {
  final String name;
  final IconData icon;
  final Color color;
  const _BrainNode(this.name, this.icon, this.color);
}
