import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/dfc_wearables_engine.dart';
import '../../../shared/widgets/dfc_chart_helpers.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC COMBAT SENSOR SCREEN — Real-Time Fight Analytics Dashboard
/// ═══════════════════════════════════════════════════════════════════════════
///
///   TAB 1 — LIVE:      real-time punch speed, power, G-force, combo tracking
///   TAB 2 — DEVICES:   combat-specific wearables (gloves, mouthguard, trackers)
///   TAB 3 — HISTORY:   session logs, personal bests, trend charts
/// ═══════════════════════════════════════════════════════════════════════════
class DFCCombatSensorScreen extends StatefulWidget {
  const DFCCombatSensorScreen({super.key});

  @override
  State<DFCCombatSensorScreen> createState() => _DFCCombatSensorScreenState();
}

class _DFCCombatSensorScreenState extends State<DFCCombatSensorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<RealDevice> get _combatDevices => DFCWearablesEngine.availableDevices
      .where((d) => d.category == DeviceCategory.combatSensor)
      .toList();

  List<RealDevice> get _futureCombatDevices => DFCWearablesEngine.futureDevices
      .where((d) => d.category == DeviceCategory.combatSensor)
      .toList();

  // Simulated live session data
  late final List<double> _punchSpeeds;
  late final List<double> _punchForces;
  late final List<double> _gForceReadings;
  late final List<_RoundSummary> _sessionHistory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final rng = math.Random(42);
    _punchSpeeds = List.generate(30, (i) => 15 + rng.nextDouble() * 30);
    _punchForces = List.generate(30, (i) => 200 + rng.nextDouble() * 600);
    _gForceReadings = List.generate(30, (i) => 5 + rng.nextDouble() * 50);
    _sessionHistory = List.generate(12, (i) {
      return _RoundSummary(
        round: i + 1,
        punches: 20 + rng.nextInt(40),
        avgSpeed: 18 + rng.nextDouble() * 15,
        maxForce: 300 + rng.nextDouble() * 500,
        maxG: 10 + rng.nextDouble() * 40,
        combos: rng.nextInt(8),
        concussionRisk: rng.nextDouble() * 0.3,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLiveTab(),
                _buildDevicesTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────

  Widget _buildHeader() {
    const dragonRed = Color(0xFFFF2A2A);
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            dragonRed.withValues(alpha: 0.08),
            DesignTokens.neonAmber.withValues(alpha: 0.04),
            DesignTokens.bgPrimary,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  dragonRed.withValues(alpha: 0.3),
                  DesignTokens.neonAmber.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: dragonRed.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.sports_mma, color: dragonRed, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COMBAT SENSORS',
                  style: TextStyle(
                    color: dragonRed,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  '${_combatDevices.length} devices  •  '
                  'Real-time strike analytics',
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    const dragonRed = Color(0xFFFF2A2A);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: GlassDecoration.card(accent: dragonRed),
      child: TabBar(
        controller: _tabController,
        indicatorColor: dragonRed,
        indicatorWeight: 2.5,
        labelColor: dragonRed,
        unselectedLabelColor: DesignTokens.textMuted,
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
        tabs: const [
          Tab(text: 'LIVE'),
          Tab(text: 'DEVICES'),
          Tab(text: 'HISTORY'),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // TAB 1: LIVE COMBAT DATA
  // ══════════════════════════════════════════════════════════════════

  Widget _buildLiveTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildLiveStats(),
        const SizedBox(height: 16),
        _sectionLabel('PUNCH SPEED (mph)', DesignTokens.neonCyan),
        const SizedBox(height: 6),
        _buildSpeedChart(),
        const SizedBox(height: 16),
        _sectionLabel('IMPACT FORCE (N)', const Color(0xFFFF2A2A)),
        const SizedBox(height: 6),
        _buildForceChart(),
        const SizedBox(height: 16),
        _sectionLabel('G-FORCE', DesignTokens.neonAmber),
        const SizedBox(height: 6),
        _buildGForceChart(),
        const SizedBox(height: 16),
        _buildConcussionGauge(),
      ],
    );
  }

  Widget _buildLiveStats() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            'AVG SPEED',
            '${_punchSpeeds.reduce((a, b) => a + b) ~/ _punchSpeeds.length} mph',
            DesignTokens.neonCyan,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            'MAX FORCE',
            '${_punchForces.reduce(math.max).round()} N',
            const Color(0xFFFF2A2A),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            'PEAK G',
            '${_gForceReadings.reduce(math.max).toStringAsFixed(1)}g',
            DesignTokens.neonAmber,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            'COMBOS',
            '${_sessionHistory.length}',
            DesignTokens.neonGreen,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: GlassDecoration.card(accent: accent),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedChart() {
    final spots = _punchSpeeds
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    return Container(
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: GlassDecoration.card(),
      child: DFCAreaChart(
        height: 130,
        legend: const [
          DFCLegendItem(label: 'Speed (mph)', color: DesignTokens.neonCyan),
        ],
        lines: [
          DFCGradientFill.lineWithGradient(
            spots: spots,
          ),
        ],
      ),
    );
  }

  Widget _buildForceChart() {
    const dragonRed = Color(0xFFFF2A2A);
    return Container(
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: GlassDecoration.card(accent: dragonRed),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(
              color: Colors.white.withValues(alpha: 0.05),
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
            topTitles: const AxisTitles(
              
            ),
            rightTitles: const AxisTitles(
              
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _punchForces.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value,
                  width: 6,
                  color: dragonRed.withValues(alpha: 0.8),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    topRight: Radius.circular(2),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGForceChart() {
    final spots = _gForceReadings
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    return Container(
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: GlassDecoration.card(accent: DesignTokens.neonAmber),
      child: DFCAreaChart(
        height: 130,
        legend: const [
          DFCLegendItem(label: 'G-Force', color: DesignTokens.neonAmber),
        ],
        lines: [
          DFCGradientFill.lineWithGradient(
            spots: spots,
            color: DesignTokens.neonAmber,
          ),
        ],
      ),
    );
  }

  Widget _buildConcussionGauge() {
    final peakG = _gForceReadings.reduce(math.max);
    // Simplified risk: < 25g = low, 25-40g = moderate, > 40g = high
    final risk = peakG < 25
        ? 'LOW'
        : peakG < 40
        ? 'MODERATE'
        : 'HIGH';
    final riskColor = peakG < 25
        ? DesignTokens.neonGreen
        : peakG < 40
        ? DesignTokens.neonAmber
        : DesignTokens.neonRed;
    final riskPct = (peakG / 60).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecoration.card(accent: riskColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: riskColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'CONCUSSION RISK INDICATOR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                  border: Border.all(color: riskColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  risk,
                  style: TextStyle(
                    color: riskColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: riskPct,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation(riskColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Peak impact: ${peakG.toStringAsFixed(1)}g  •  '
            'Threshold: 25g (caution) / 40g (danger)',
            style: const TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 10,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Based on real-time accelerometer data from combat sensors. '
            'Medical evaluation recommended above 40g sustained impacts.',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // TAB 2: COMBAT DEVICES
  // ══════════════════════════════════════════════════════════════════

  Widget _buildDevicesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCombatBanner(),
        const SizedBox(height: 16),
        _sectionLabel('AVAILABLE NOW', const Color(0xFFFF2A2A)),
        ..._combatDevices.map(_buildDeviceCard),
        if (_futureCombatDevices.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionLabel('2029-2030 ROADMAP', DesignTokens.neonMagenta),
          ..._futureCombatDevices.map(_buildDeviceCard),
        ],
        const SizedBox(height: 16),
        _buildMetricsExplainer(),
      ],
    );
  }

  Widget _buildCombatBanner() {
    const dragonRed = Color(0xFFFF2A2A);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            dragonRed.withValues(alpha: 0.08),
            DesignTokens.neonAmber.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: dragonRed.withValues(alpha: 0.2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_mma, color: dragonRed, size: 20),
              SizedBox(width: 8),
              Text(
                'COMBAT-GRADE SENSOR TECH',
                style: TextStyle(
                  color: dragonRed,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'DFC combat sensors measure punch speed, impact force, G-force, '
            'and concussion risk in real time via BLE 5.3. Data feeds directly '
            'into your fighter profile, corner coaching tools, and safety systems.',
            style: TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(RealDevice device) {
    const dragonRed = Color(0xFFFF2A2A);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: GlassDecoration.card(accent: dragonRed),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(device.imageEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            device.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (device.dfcVerified) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: dragonRed.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DFC VERIFIED',
                              style: TextStyle(
                                color: dragonRed,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${device.manufacturer}  •  ${device.priceRange}',
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (!device.availableNow)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonMagenta.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusPill,
                    ),
                  ),
                  child: Text(
                    '${device.releaseYear}',
                    style: const TextStyle(
                      color: DesignTokens.neonMagenta,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Metrics
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: device.metrics.map((m) {
              final isImpact =
                  m.toLowerCase().contains('force') ||
                  m.toLowerCase().contains('speed') ||
                  m.toLowerCase().contains('impact') ||
                  m.toLowerCase().contains('g-force') ||
                  m.toLowerCase().contains('concussion');
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isImpact
                      ? dragonRed.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(6),
                  border: isImpact
                      ? Border.all(color: dragonRed.withValues(alpha: 0.25))
                      : null,
                ),
                child: Text(
                  m,
                  style: TextStyle(
                    color: isImpact ? dragonRed : DesignTokens.textSecondary,
                    fontSize: 10,
                    fontWeight: isImpact ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Protocol + sample rate
          Row(
            children: [
              ...device.protocols.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _protoColor(p).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      p.displayName,
                      style: TextStyle(
                        color: _protoColor(p),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (device.maxSampleRateHz > 0) ...[
                const Icon(
                  Icons.speed,
                  size: 12,
                  color: DesignTokens.textMuted,
                ),
                const SizedBox(width: 3),
                Text(
                  '${device.maxSampleRateHz}Hz',
                  style: const TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsExplainer() {
    final metrics = [
      {
        'name': 'Punch Speed',
        'unit': 'mph / m/s',
        'desc': 'Accelerometer-derived hand velocity at point of impact.',
        'icon': Icons.speed,
        'color': DesignTokens.neonCyan,
      },
      {
        'name': 'Impact Force',
        'unit': 'Newtons (N)',
        'desc': 'Force transmitted at contact. Pro heavyweights: 3,000-5,000N.',
        'icon': Icons.flash_on,
        'color': const Color(0xFFFF2A2A),
      },
      {
        'name': 'G-Force',
        'unit': 'g',
        'desc':
            'Head acceleration. Medical threshold: 25g (caution), 40g+ (danger).',
        'icon': Icons.warning_amber,
        'color': DesignTokens.neonAmber,
      },
      {
        'name': 'Concussion Risk',
        'unit': '0-100%',
        'desc':
            'Composite score from cumulative G-force, impact count, and duration.',
        'icon': Icons.health_and_safety,
        'color': DesignTokens.neonRed,
      },
      {
        'name': 'Combo Index',
        'unit': 'count',
        'desc':
            'Sequential strikes within 1.5s window. Measures combination fluency.',
        'icon': Icons.format_list_numbered,
        'color': DesignTokens.neonGreen,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecoration.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: DesignTokens.neonCyan, size: 18),
              SizedBox(width: 8),
              Text(
                'WHAT WE MEASURE',
                style: TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...metrics.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    m['icon'] as IconData,
                    color: m['color'] as Color,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              m['name'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              m['unit'] as String,
                              style: TextStyle(
                                color: (m['color'] as Color).withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          m['desc'] as String,
                          style: const TextStyle(
                            color: DesignTokens.textMuted,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
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

  // ══════════════════════════════════════════════════════════════════
  // TAB 3: SESSION HISTORY
  // ══════════════════════════════════════════════════════════════════

  Widget _buildHistoryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPersonalBests(),
        const SizedBox(height: 16),
        _sectionLabel('SPEED TREND (last 12 rounds)', DesignTokens.neonCyan),
        const SizedBox(height: 6),
        _buildSpeedTrendChart(),
        const SizedBox(height: 16),
        _sectionLabel('FORCE TREND', const Color(0xFFFF2A2A)),
        const SizedBox(height: 6),
        _buildForceTrendChart(),
        const SizedBox(height: 16),
        _sectionLabel('SESSION LOG', DesignTokens.neonAmber),
        const SizedBox(height: 6),
        ..._sessionHistory.reversed.map(_buildRoundCard),
      ],
    );
  }

  Widget _buildPersonalBests() {
    final maxSpeed = _sessionHistory.map((r) => r.avgSpeed).reduce(math.max);
    final maxForce = _sessionHistory.map((r) => r.maxForce).reduce(math.max);
    final maxG = _sessionHistory.map((r) => r.maxG).reduce(math.max);
    final totalPunches = _sessionHistory
        .map((r) => r.punches)
        .reduce((a, b) => a + b);

    return Row(
      children: [
        Expanded(
          child: _statCard(
            'TOP SPEED',
            '${maxSpeed.toStringAsFixed(1)} mph',
            DesignTokens.neonCyan,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            'MAX FORCE',
            '${maxForce.round()} N',
            const Color(0xFFFF2A2A),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            'PEAK G',
            '${maxG.toStringAsFixed(1)}g',
            DesignTokens.neonAmber,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard('TOTAL', '$totalPunches', DesignTokens.neonGreen),
        ),
      ],
    );
  }

  Widget _buildSpeedTrendChart() {
    final spots = _sessionHistory
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.avgSpeed))
        .toList();
    return Container(
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: GlassDecoration.card(),
      child: DFCAreaChart(
        height: 130,
        legend: const [
          DFCLegendItem(label: 'Avg Speed', color: DesignTokens.neonCyan),
        ],
        lines: [
          DFCGradientFill.lineWithGradient(
            spots: spots,
          ),
        ],
      ),
    );
  }

  Widget _buildForceTrendChart() {
    const dragonRed = Color(0xFFFF2A2A);
    return Container(
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: GlassDecoration.card(accent: dragonRed),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(
              color: Colors.white.withValues(alpha: 0.05),
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Text(
                  'R${v.toInt() + 1}',
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
            topTitles: const AxisTitles(
              
            ),
            rightTitles: const AxisTitles(
              
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _sessionHistory.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.maxForce,
                  width: 14,
                  color: dragonRed.withValues(alpha: 0.7),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(3),
                    topRight: Radius.circular(3),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRoundCard(_RoundSummary round) {
    final riskColor = round.concussionRisk < 0.1
        ? DesignTokens.neonGreen
        : round.concussionRisk < 0.2
        ? DesignTokens.neonAmber
        : DesignTokens.neonRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: GlassDecoration.card(),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFF2A2A).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'R${round.round}',
              style: const TextStyle(
                color: Color(0xFFFF2A2A),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${round.punches} punches  •  '
                  '${round.combos} combos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Avg ${round.avgSpeed.toStringAsFixed(1)} mph  •  '
                  'Max ${round.maxForce.round()}N  •  '
                  '${round.maxG.toStringAsFixed(1)}g',
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: riskColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: riskColor.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────

  Widget _sectionLabel(String text, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Color _protoColor(WearableProtocol p) {
    switch (p) {
      case WearableProtocol.ble53:
        return DesignTokens.neonCyan;
      case WearableProtocol.uwb:
        return DesignTokens.neonGreen;
      case WearableProtocol.wifi6:
        return DesignTokens.neonAmber;
      case WearableProtocol.lteM:
        return DesignTokens.neonRed;
      case WearableProtocol.nbIot:
        return const Color(0xFF888888);
      case WearableProtocol.ant:
        return DesignTokens.neonMagenta;
      case WearableProtocol.usb:
        return DesignTokens.neonBlue;
    }
  }
}

class _RoundSummary {
  final int round;
  final int punches;
  final double avgSpeed;
  final double maxForce;
  final double maxG;
  final int combos;
  final double concussionRisk;

  const _RoundSummary({
    required this.round,
    required this.punches,
    required this.avgSpeed,
    required this.maxForce,
    required this.maxG,
    required this.combos,
    required this.concussionRisk,
  });
}
