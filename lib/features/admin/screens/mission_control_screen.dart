import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/adrenaline_theme.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MISSION CONTROL — NASA-Style Streaming Operations Dashboard
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Three Command Decks:
///   TOP    — The Arena: Global viewer heatmap + CCV
///   MIDDLE — The Pipeline: Latency gauge, rebuffer %, bitrate chart
///   BOTTOM — The Treasury: Revenue ticker, purchases, payouts
///
/// ═══════════════════════════════════════════════════════════════════════════
class MissionControlScreen extends StatefulWidget {
  const MissionControlScreen({super.key});

  @override
  State<MissionControlScreen> createState() => _MissionControlScreenState();
}

class _MissionControlScreenState extends State<MissionControlScreen>
    with TickerProviderStateMixin {
  Timer? _refreshTimer;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  // ── Simulated real-time metrics (replace with Mux Data API in production) ──
  double _latencyMs = 2400;
  int _ccv = 0;
  int _peakCcv = 0;
  double _rebufferPct = 0.0;
  double _bitrateKbps = 0;
  String _streamStatus = 'IDLE';
  double _revenueAud = 0;
  int _purchaseCount = 0;
  final List<FlSpot> _latencyHistory = [];
  final List<FlSpot> _ccvHistory = [];
  final List<FlSpot> _bitrateHistory = [];
  int _tickCount = 0;

  // Region viewer counts
  final Map<String, int> _regionViewers = {
    'Melbourne': 0,
    'Sydney': 0,
    'Brisbane': 0,
    'Perth': 0,
    'Auckland': 0,
    'Wellington': 0,
    'Lahore': 0,
    'Mumbai': 0,
    'Los Angeles': 0,
    'London': 0,
  };

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Refresh metrics every 2 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _simulateMetricsTick();
    });
  }

  void _simulateMetricsTick() {
    // In production: call Mux Real-Time API + Firestore listeners
    // For now: show realistic simulation data
    final rng = math.Random();
    setState(() {
      _tickCount++;
      // Latency jitter around 2.4s (low-latency HLS target)
      _latencyMs = 2000 + rng.nextDouble() * 800;
      _latencyHistory.add(FlSpot(_tickCount.toDouble(), _latencyMs));
      if (_latencyHistory.length > 60) _latencyHistory.removeAt(0);

      // CCV ramp (simulates viewers joining)
      if (_streamStatus == 'LIVE') {
        _ccv = math.min(_ccv + rng.nextInt(5), 500);
        if (_ccv > _peakCcv) _peakCcv = _ccv;
        _rebufferPct = rng.nextDouble() * 0.3;
        _bitrateKbps = 3500 + rng.nextDouble() * 1500;
        _revenueAud = _purchaseCount * 2.50;

        // Distribute viewers across regions
        for (final key in _regionViewers.keys) {
          _regionViewers[key] = rng.nextInt((_ccv * 0.3).toInt().clamp(1, 200));
        }
      }
      _ccvHistory.add(FlSpot(_tickCount.toDouble(), _ccv.toDouble()));
      if (_ccvHistory.length > 60) _ccvHistory.removeAt(0);
      _bitrateHistory.add(FlSpot(_tickCount.toDouble(), _bitrateKbps));
      if (_bitrateHistory.length > 60) _bitrateHistory.removeAt(0);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) => Icon(
                Icons.radar,
                color: _streamStatus == 'LIVE'
                    ? AdrenalineTheme.electricCrimson.withValues(
                        alpha: _pulse.value,
                      )
                    : DesignTokens.neonCyan.withValues(alpha: _pulse.value),
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'MISSION CONTROL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(width: 12),
            _statusBadge(),
          ],
        ),
        actions: [
          // Simulate LIVE toggle
          TextButton.icon(
            onPressed: () {
              setState(() {
                if (_streamStatus == 'LIVE') {
                  _streamStatus = 'IDLE';
                  _ccv = 0;
                } else {
                  _streamStatus = 'LIVE';
                  _purchaseCount = 47; // seed demo purchases
                }
              });
            },
            icon: Icon(
              _streamStatus == 'LIVE' ? Icons.stop_circle : Icons.play_circle,
              color: _streamStatus == 'LIVE'
                  ? AdrenalineTheme.electricCrimson
                  : DesignTokens.neonCyan,
              size: 20,
            ),
            label: Text(
              _streamStatus == 'LIVE' ? 'STOP SIM' : 'START SIM',
              style: TextStyle(
                color: _streamStatus == 'LIVE'
                    ? AdrenalineTheme.electricCrimson
                    : DesignTokens.neonCyan,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ═══ DECK 1: THE ARENA ═══
            _sectionLabel(
              'THE ARENA',
              Icons.public,
              'Global Viewer Intelligence',
            ),
            const SizedBox(height: 8),
            _buildArenaDeck(),
            const SizedBox(height: 20),

            // ═══ DECK 2: THE PIPELINE ═══
            _sectionLabel(
              'THE PIPELINE',
              Icons.speed,
              'Technical Health & Latency',
            ),
            const SizedBox(height: 8),
            _buildPipelineDeck(),
            const SizedBox(height: 20),

            // ═══ DECK 3: THE TREASURY ═══
            _sectionLabel(
              'THE TREASURY',
              Icons.account_balance,
              'Revenue & Payouts',
            ),
            const SizedBox(height: 8),
            _buildTreasuryDeck(),
            const SizedBox(height: 20),

            // ═══ DECK 4: REGION HEATMAP ═══
            _sectionLabel(
              'GLOBAL DEPLOYMENT',
              Icons.location_on,
              'AU/NZ/Emerging Markets',
            ),
            const SizedBox(height: 8),
            _buildRegionDeck(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS BADGE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _statusBadge() {
    final isLive = _streamStatus == 'LIVE';
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isLive
              ? AdrenalineTheme.electricCrimson.withValues(
                  alpha: _pulse.value * 0.4,
                )
              : Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLive ? AdrenalineTheme.electricCrimson : Colors.grey,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLive)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AdrenalineTheme.electricCrimson,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AdrenalineTheme.electricCrimson.withValues(
                        alpha: _pulse.value,
                      ),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            if (isLive) const SizedBox(width: 6),
            Text(
              _streamStatus,
              style: TextStyle(
                color: isLive ? AdrenalineTheme.electricCrimson : Colors.grey,
                fontSize: 11,
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
  // SECTION LABEL
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _sectionLabel(String title, IconData icon, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: DesignTokens.neonCyan, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: DesignTokens.neonCyan,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DECK 1: THE ARENA — CCV, Peak, Viewer Map
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildArenaDeck() {
    return _glowCard(
      child: Column(
        children: [
          // Big KPI row
          Row(
            children: [
              Expanded(
                child: _bigKPI('CCV', _ccv.toString(), DesignTokens.neonCyan),
              ),
              Expanded(
                child: _bigKPI(
                  'PEAK',
                  _peakCcv.toString(),
                  AdrenalineTheme.electricCrimson,
                ),
              ),
              Expanded(
                child: _bigKPI(
                  'REGIONS',
                  _regionViewers.values.where((v) => v > 0).length.toString(),
                  Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // CCV line chart
          SizedBox(
            height: 120,
            child: _ccvHistory.length < 2
                ? const Center(
                    child: Text(
                      'Waiting for data...',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _ccvHistory,
                          isCurved: true,
                          color: DesignTokens.neonCyan,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: DesignTokens.neonCyan.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            'CONCURRENT VIEWERS — LIVE TREND',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DECK 2: THE PIPELINE — Latency, Rebuffer, Bitrate
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPipelineDeck() {
    return _glowCard(
      child: Column(
        children: [
          // Gauges row
          Row(
            children: [
              Expanded(child: _latencyGauge()),
              const SizedBox(width: 16),
              Expanded(child: _rebufferGauge()),
              const SizedBox(width: 16),
              Expanded(child: _bitrateGauge()),
            ],
          ),
          const SizedBox(height: 16),
          // Latency line chart
          SizedBox(
            height: 100,
            child: _latencyHistory.length < 2
                ? const Center(
                    child: Text(
                      'Waiting for latency data...',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _latencyHistory,
                          isCurved: true,
                          color: _latencyMs < 3000
                              ? Colors.green
                              : Colors.orange,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color:
                                (_latencyMs < 3000
                                        ? Colors.green
                                        : Colors.orange)
                                    .withValues(alpha: 0.08),
                          ),
                        ),
                      ],
                      minY: 0,
                      maxY: 6000,
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(Colors.green, '< 3s (TARGET)'),
              const SizedBox(width: 16),
              _legendDot(Colors.orange, '3-5s (ACCEPTABLE)'),
              const SizedBox(width: 16),
              _legendDot(Colors.red, '> 5s (CRITICAL)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _latencyGauge() {
    final color = _latencyMs < 3000
        ? Colors.green
        : _latencyMs < 5000
        ? Colors.orange
        : Colors.red;
    return _gaugeWidget(
      label: 'GLASS-TO-GLASS',
      value: '${(_latencyMs / 1000).toStringAsFixed(1)}s',
      color: color,
      fill: (_latencyMs / 6000).clamp(0.0, 1.0),
    );
  }

  Widget _rebufferGauge() {
    final color = _rebufferPct < 0.1
        ? Colors.green
        : _rebufferPct < 0.5
        ? Colors.orange
        : Colors.red;
    return _gaugeWidget(
      label: 'REBUFFER %',
      value: '${_rebufferPct.toStringAsFixed(2)}%',
      color: color,
      fill: (_rebufferPct / 1.0).clamp(0.0, 1.0),
    );
  }

  Widget _bitrateGauge() {
    return _gaugeWidget(
      label: 'BITRATE',
      value: _bitrateKbps > 0
          ? '${(_bitrateKbps / 1000).toStringAsFixed(1)} Mbps'
          : '—',
      color: DesignTokens.neonCyan,
      fill: (_bitrateKbps / 6000).clamp(0.0, 1.0),
    );
  }

  Widget _gaugeWidget({
    required String label,
    required String value,
    required Color color,
    required double fill,
  }) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CustomPaint(
            painter: _ArcGaugePainter(fill: fill, color: color),
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DECK 3: THE TREASURY — Revenue, Purchases, Fighter Payout
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTreasuryDeck() {
    final fighterPayout = _revenueAud * 0.20; // 20% fighter share
    final promoterPayout = _revenueAud * 0.55; // 55% promoter share
    final dfcRevenue = _revenueAud * 0.25; // 25% DFC platform

    return _glowCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _bigKPI(
                  'REVENUE',
                  '\$${_revenueAud.toStringAsFixed(2)}',
                  Colors.green,
                ),
              ),
              Expanded(
                child: _bigKPI(
                  'PURCHASES',
                  _purchaseCount.toString(),
                  DesignTokens.neonCyan,
                ),
              ),
              Expanded(
                child: _bigKPI(
                  'AVG PRICE',
                  _purchaseCount > 0
                      ? '\$${(_revenueAud / _purchaseCount).toStringAsFixed(2)}'
                      : '—',
                  Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Payout split bar
          _payoutBar(
            'ROESLER (Fighter)',
            fighterPayout,
            AdrenalineTheme.electricCrimson,
          ),
          const SizedBox(height: 8),
          _payoutBar(
            'ULTIMATE LEGENDS (Promoter)',
            promoterPayout,
            Colors.amber,
          ),
          const SizedBox(height: 8),
          _payoutBar('DFC PLATFORM', dfcRevenue, DesignTokens.neonCyan),
          const SizedBox(height: 12),
          // Bitrate chart
          SizedBox(
            height: 80,
            child: _bitrateHistory.length < 2
                ? const SizedBox.shrink()
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _bitrateHistory,
                          isCurved: true,
                          color: Colors.amber.withValues(alpha: 0.6),
                          barWidth: 1.5,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.amber.withValues(alpha: 0.05),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _payoutBar(String label, double amount, Color color) {
    final maxRevenue = _revenueAud > 0 ? _revenueAud : 1.0;
    return Row(
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (amount / maxRevenue).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DECK 4: REGION HEATMAP
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRegionDeck() {
    final sortedRegions = _regionViewers.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _glowCard(
      child: Column(
        children: [
          for (final entry in sortedRegions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: _regionRow(entry.key, entry.value),
            ),
        ],
      ),
    );
  }

  Widget _regionRow(String region, int viewers) {
    final maxViewers = _ccv > 0 ? _ccv.toDouble() : 1.0;
    final heat = (viewers / maxViewers).clamp(0.0, 1.0);
    final color = Color.lerp(
      Colors.grey,
      AdrenalineTheme.electricCrimson,
      heat,
    )!;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: viewers > 0 ? color : Colors.grey.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            boxShadow: viewers > 0
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 100,
          child: Text(
            region,
            style: TextStyle(
              color: Colors.white.withValues(alpha: viewers > 0 ? 0.9 : 0.3),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: heat,
              backgroundColor: Colors.white.withValues(alpha: 0.04),
              valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.6)),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 40,
          child: Text(
            viewers.toString(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _bigKPI(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _glowCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.neonCyan.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ARC GAUGE PAINTER — Circular arc gauge
// ═══════════════════════════════════════════════════════════════════════════
class _ArcGaugePainter extends CustomPainter {
  final double fill;
  final Color color;

  _ArcGaugePainter({required this.fill, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    const startAngle = 2.4; // ~135 degrees
    const sweepTotal = 4.0; // ~230 degrees arc

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
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
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal * fill.clamp(0.0, 1.0),
      false,
      fillPaint,
    );

    // Glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal * fill.clamp(0.0, 1.0),
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcGaugePainter oldDelegate) {
    return oldDelegate.fill != fill || oldDelegate.color != color;
  }
}
