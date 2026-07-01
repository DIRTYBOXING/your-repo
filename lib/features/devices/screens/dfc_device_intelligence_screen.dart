import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/dfc_wearables_engine.dart';
import '../../../shared/widgets/dfc_chart_helpers.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC DEVICE INTELLIGENCE SCREEN — Educational Smart Device Dashboard
/// ═══════════════════════════════════════════════════════════════════════════
///
/// ChartIQ-grade data visualization + real device registry + protocol
/// education.  Three tabs:
///   1. DEVICES  — filterable 45+ device gallery with specs
///   2. ANALYTICS — live biometric charts (line, bar, pie)
///   3. PROTOCOLS — educational protocol comparison + banned list
/// ═══════════════════════════════════════════════════════════════════════════
class DFCDeviceIntelligenceScreen extends StatefulWidget {
  const DFCDeviceIntelligenceScreen({super.key});

  @override
  State<DFCDeviceIntelligenceScreen> createState() =>
      _DFCDeviceIntelligenceScreenState();
}

class _DFCDeviceIntelligenceScreenState
    extends State<DFCDeviceIntelligenceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _engine = DFCWearablesEngine();
  DeviceCategory? _selectedCategory;
  bool _showFuture = false;

  // Simulated 7-day chart data
  late final List<double> _hrData;
  late final List<double> _hrvData;
  late final List<double> _sleepData;
  late final List<double> _strainData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _engine.initialize();
    _generateChartData();
  }

  void _generateChartData() {
    final rng = math.Random(42);
    _hrData = List.generate(28, (i) => 58 + rng.nextDouble() * 42);
    _hrvData = List.generate(28, (i) => 25 + rng.nextDouble() * 55);
    _sleepData = List.generate(7, (i) => 5.5 + rng.nextDouble() * 3.0);
    _strainData = List.generate(7, (i) => 4 + rng.nextDouble() * 14);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<RealDevice> get _filteredDevices {
    final source = _showFuture
        ? DFCWearablesEngine.futureDevices
        : DFCWearablesEngine.availableDevices;
    if (_selectedCategory == null) return source;
    return source.where((d) => d.category == _selectedCategory).toList();
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
                _buildDevicesTab(),
                _buildAnalyticsTab(),
                _buildProtocolsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.neonCyan.withValues(alpha: 0.08),
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
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DEVICE INTELLIGENCE',
                  style: TextStyle(
                    color: DesignTokens.neonCyan,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                Text(
                  '${DFCWearablesEngine.availableDevices.length} devices NOW  •  '
                  '${DFCWearablesEngine.futureDevices.length} roadmap  •  '
                  '${DFCWearablesEngine.protocolSpecs.length} protocols',
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: DesignTokens.neonGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
              border: Border.all(
                color: DesignTokens.neonGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: DesignTokens.neonGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: DesignTokens.neonGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: GlassDecoration.card(),
      child: TabBar(
        controller: _tabController,
        indicatorColor: DesignTokens.neonCyan,
        indicatorWeight: 2.5,
        labelColor: DesignTokens.neonCyan,
        unselectedLabelColor: DesignTokens.textMuted,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
        tabs: const [
          Tab(text: 'DEVICES'),
          Tab(text: 'ANALYTICS'),
          Tab(text: 'PROTOCOLS'),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // TAB 1: DEVICES — Filterable device gallery
  // ══════════════════════════════════════════════════════════════════

  Widget _buildDevicesTab() {
    final devices = _filteredDevices;
    return Column(
      children: [
        _buildCategoryFilter(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: devices.length,
            itemBuilder: (context, i) => _buildDeviceCard(devices[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: [
          _filterChip('ALL', null),
          _filterChip('2030', null, isFuture: true),
          ...DeviceCategory.values.map(
            (c) => _filterChip(c.emoji, c, tooltip: c.displayName),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    String label,
    DeviceCategory? cat, {
    bool isFuture = false,
    String? tooltip,
  }) {
    final isActive = isFuture
        ? _showFuture
        : (label == 'ALL'
              ? _selectedCategory == null && !_showFuture
              : _selectedCategory == cat && !_showFuture);

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: tooltip ?? label,
        child: GestureDetector(
          onTap: () {
            setState(() {
              if (isFuture) {
                _showFuture = !_showFuture;
                if (_showFuture) _selectedCategory = null;
              } else {
                _showFuture = false;
                _selectedCategory = cat;
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? DesignTokens.neonCyan.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
              border: Border.all(
                color: isActive
                    ? DesignTokens.neonCyan.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isActive
                    ? DesignTokens.neonCyan
                    : DesignTokens.textMuted,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceCard(RealDevice device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: GlassDecoration.card(
        accent: device.dfcVerified
            ? DesignTokens.neonGreen
            : DesignTokens.neonCyan,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: emoji + name + verified badge + price
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
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (device.dfcVerified) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.neonGreen.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DFC ✓',
                              style: TextStyle(
                                color: DesignTokens.neonGreen,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${device.manufacturer}  •  ${device.category.displayName}',
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    device.priceRange,
                    style: const TextStyle(
                      color: DesignTokens.neonAmber,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (device.rating > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: DesignTokens.neonAmber,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          device.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: DesignTokens.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  if (!device.availableNow)
                    Text(
                      '${device.releaseYear}',
                      style: const TextStyle(
                        color: DesignTokens.neonMagenta,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Protocol chips
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: device.protocols.map((p) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _protocolColor(p).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _protocolColor(p).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  p.displayName,
                  style: TextStyle(
                    color: _protocolColor(p),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Metrics row
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: device.metrics.map((m) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  m,
                  style: const TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 10,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Specs row
          Row(
            children: [
              _specBadge(Icons.speed, '${device.maxSampleRateHz} Hz'),
              const SizedBox(width: 8),
              _specBadge(Icons.battery_full, '${device.batteryDays}d'),
              if (device.apiEndpoint != null) ...[
                const SizedBox(width: 8),
                _specBadge(Icons.api, 'API'),
              ],
              const Spacer(),
              if (device.availableNow)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusPill,
                    ),
                  ),
                  child: const Text(
                    'BUY NOW',
                    style: TextStyle(
                      color: DesignTokens.neonCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonMagenta.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusPill,
                    ),
                  ),
                  child: const Text(
                    'ROADMAP',
                    style: TextStyle(
                      color: DesignTokens.neonMagenta,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _specBadge(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: DesignTokens.textMuted),
        const SizedBox(width: 3),
        Text(
          value,
          style: const TextStyle(
            color: DesignTokens.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // TAB 2: ANALYTICS — ChartIQ-grade live data visualization
  // ══════════════════════════════════════════════════════════════════

  Widget _buildAnalyticsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('HEART RATE — 7 Day Trend', DesignTokens.neonRed),
        const SizedBox(height: 8),
        _buildHRChart(),
        const SizedBox(height: 20),

        _buildSectionTitle('HRV — Recovery Index', DesignTokens.neonGreen),
        const SizedBox(height: 8),
        _buildHRVChart(),
        const SizedBox(height: 20),

        _buildSectionTitle('DEVICE CATEGORY BREAKDOWN', DesignTokens.neonCyan),
        const SizedBox(height: 8),
        _buildCategoryPieChart(),
        const SizedBox(height: 20),

        _buildSectionTitle('SLEEP HOURS — Weekly', DesignTokens.neonMagenta),
        const SizedBox(height: 8),
        _buildSleepBarChart(),
        const SizedBox(height: 20),

        _buildSectionTitle(
          'TRAINING STRAIN — Weekly Load',
          DesignTokens.neonAmber,
        ),
        const SizedBox(height: 8),
        _buildStrainChart(),
        const SizedBox(height: 20),

        _buildSectionTitle(
          'PROTOCOL LATENCY COMPARISON',
          DesignTokens.neonCyan,
        ),
        const SizedBox(height: 8),
        _buildLatencyBarChart(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSectionTitle(String title, Color accent) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: accent,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildHRChart() {
    final spots = _hrData
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: GlassDecoration.card(accent: DesignTokens.neonRed),
      child: LineChart(
        LineChartData(
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
                interval: 4,
                getTitlesWidget: (v, _) => Text(
                  '${(v / 4).round()}d',
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text(
                  '${v.round()}',
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: 10,
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
          lineTouchData: DFCTooltipStyle.touchData(
            indicatorColor: DesignTokens.neonRed,
          ),
          lineBarsData: [
            DFCGradientFill.lineWithGradient(
              spots: spots,
              color: DesignTokens.neonRed,
            ),
          ],
          minY: 50,
          maxY: 110,
        ),
        duration: DesignTokens.animNormal,
      ),
    );
  }

  Widget _buildHRVChart() {
    final spots = _hrvData
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: GlassDecoration.card(accent: DesignTokens.neonGreen),
      child: DFCAreaChart(
        height: 170,
        legend: const [
          DFCLegendItem(label: 'HRV (ms)', color: DesignTokens.neonGreen),
        ],
        lines: [
          DFCGradientFill.lineWithGradient(
            spots: spots,
            color: DesignTokens.neonGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPieChart() {
    final categoryCount = <DeviceCategory, int>{};
    for (final d in DFCWearablesEngine.availableDevices) {
      categoryCount[d.category] = (categoryCount[d.category] ?? 0) + 1;
    }
    final entries = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final colors = [
      DesignTokens.neonCyan,
      DesignTokens.neonMagenta,
      DesignTokens.neonGreen,
      DesignTokens.neonAmber,
      DesignTokens.neonRed,
      DesignTokens.neonBlue,
      DesignTokens.neonGold,
      const Color(0xFFAA66FF),
      const Color(0xFF66FFAA),
      const Color(0xFFFF66AA),
      const Color(0xFF6699FF),
      const Color(0xFFFF9966),
      const Color(0xFF99FF66),
      const Color(0xFF9966FF),
      const Color(0xFF66AAFF),
      const Color(0xFFFFAA66),
    ];

    return Container(
      height: 260,
      padding: const EdgeInsets.all(12),
      decoration: GlassDecoration.card(),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 36,
                sections: entries.asMap().entries.map((e) {
                  final idx = e.key;
                  final entry = e.value;
                  return PieChartSectionData(
                    value: entry.value.toDouble(),
                    title: '${entry.value}',
                    color: colors[idx % colors.length],
                    radius: 50,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.asMap().entries.map((e) {
                final idx = e.key;
                final entry = e.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors[idx % colors.length],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${entry.key.emoji} ${entry.key.displayName}',
                          style: const TextStyle(
                            color: DesignTokens.textSecondary,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${entry.value}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepBarChart() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: GlassDecoration.card(accent: DesignTokens.neonMagenta),
      child: BarChart(
        BarChartData(
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => const Color(0xE0121828),
              getTooltipItem: (group, _, rod, _) {
                return BarTooltipItem(
                  '${_sleepData[group.x].toStringAsFixed(1)}h',
                  const TextStyle(
                    color: DesignTokens.neonMagenta,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
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
                  days[v.toInt() % 7],
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) => Text(
                  '${v.round()}h',
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: 10,
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
          barGroups: _sleepData.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value,
                  width: 18,
                  color: DesignTokens.neonMagenta.withValues(alpha: 0.7),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 10,
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
              ],
            );
          }).toList(),
          maxY: 10,
        ),
      ),
    );
  }

  Widget _buildStrainChart() {
    final spots = _strainData
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: GlassDecoration.card(accent: DesignTokens.neonAmber),
      child: DFCAreaChart(
        height: 150,
        legend: const [
          DFCLegendItem(label: 'Strain Score', color: DesignTokens.neonAmber),
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

  Widget _buildLatencyBarChart() {
    final protocols = DFCWearablesEngine.protocolSpecs.entries.toList();
    final latencies = protocols.map((e) {
      final l = e.value['latency'] as String;
      return double.tryParse(l.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 10;
    }).toList();

    final pColors = [
      DesignTokens.neonCyan,
      DesignTokens.neonGreen,
      DesignTokens.neonAmber,
      DesignTokens.neonRed,
      const Color(0xFF888888),
      DesignTokens.neonMagenta,
    ];

    return Container(
      height: 220,
      padding: const EdgeInsets.all(12),
      decoration: GlassDecoration.card(),
      child: BarChart(
        BarChartData(
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => const Color(0xE0121828),
              getTooltipItem: (group, _, rod, _) {
                final name = protocols[group.x].key;
                return BarTooltipItem(
                  '$name\n< ${rod.toY.round()}ms',
                  const TextStyle(
                    color: DesignTokens.neonCyan,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
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
                reservedSize: 40,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx >= protocols.length) return const SizedBox.shrink();
                  return RotatedBox(
                    quarterTurns: 1,
                    child: Text(
                      protocols[idx].key,
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 9,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text(
                  '${v.round()}ms',
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
          barGroups: latencies.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value,
                  width: 20,
                  color: pColors[e.key % pColors.length].withValues(alpha: 0.7),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // TAB 3: PROTOCOLS — Educational protocol deep-dive
  // ══════════════════════════════════════════════════════════════════

  Widget _buildProtocolsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildEducationalBanner(),
        const SizedBox(height: 16),
        _buildSectionTitle('APPROVED PROTOCOLS', DesignTokens.neonGreen),
        const SizedBox(height: 8),
        ...DFCWearablesEngine.protocolSpecs.entries.map(_buildProtocolCard),
        const SizedBox(height: 20),
        _buildSectionTitle('BANNED PROTOCOLS', DesignTokens.neonRed),
        const SizedBox(height: 8),
        ...DFCWearablesEngine.bannedProtocols.map(_buildBannedCard),
        const SizedBox(height: 20),
        _buildSectionTitle(
          'WHY MESH FAILS — Educational',
          DesignTokens.neonAmber,
        ),
        const SizedBox(height: 8),
        _buildMeshExplanation(),
        const SizedBox(height: 20),
        _buildSectionTitle(
          'PROTOCOL USE CASES — When to Use What',
          DesignTokens.neonCyan,
        ),
        const SizedBox(height: 8),
        _buildUseCaseMatrix(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildEducationalBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.neonCyan.withValues(alpha: 0.08),
            DesignTokens.neonMagenta.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school, color: DesignTokens.neonCyan, size: 20),
              SizedBox(width: 8),
              Text(
                'PROTOCOL EDUCATION',
                style: TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'DFC devices use BLE 5.3, UWB, WiFi 6/7, LTE-M, and NB-IoT — '
            'never mesh protocols like Z-Wave or Zigbee. '
            'Mesh networks cannot support real-time safety alerts, '
            'combat sensor data, or health monitoring at the frequency and '
            'reliability our athletes require.',
            style: TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Safety-critical data requires < 50ms latency with zero silent '
            'failures. Every protocol below has been verified for DFC use.',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolCard(MapEntry<String, Map<String, dynamic>> entry) {
    final name = entry.key;
    final spec = entry.value;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: GlassDecoration.card(accent: DesignTokens.neonGreen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DesignTokens.neonGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  name,
                  style: const TextStyle(
                    color: DesignTokens.neonGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  spec['status'] as String,
                  style: const TextStyle(
                    color: DesignTokens.neonCyan,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _protocolSpecRow('Throughput', spec['maxThroughput'] as String),
          _protocolSpecRow('Range', spec['range'] as String),
          _protocolSpecRow('Latency', spec['latency'] as String),
          _protocolSpecRow('Power', spec['powerDraw'] as String),
          _protocolSpecRow('Sample Rate', spec['sampleRate'] as String),
          const SizedBox(height: 6),
          Text(
            spec['useCase'] as String,
            style: const TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _protocolSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: DesignTokens.textMuted,
                fontSize: 11,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannedCard(Map<String, String> banned) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: GlassDecoration.card(accent: DesignTokens.neonRed),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.block, color: DesignTokens.neonRed, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banned['name']!,
                  style: const TextStyle(
                    color: DesignTokens.neonRed,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  banned['reason']!,
                  style: const TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeshExplanation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecoration.card(accent: DesignTokens.neonAmber),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber,
                color: DesignTokens.neonAmber,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'WHY MESH NETWORKS FAIL FOR COMBAT/SAFETY',
                style: TextStyle(
                  color: DesignTokens.neonAmber,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _educationPoint(
            '1',
            'Max 5-second sample rate',
            'Z-Wave/Zigbee mesh cannot exceed 5s polling without destroying the network. '
                'Combat sensors need 100+ readings/sec.',
          ),
          _educationPoint(
            '2',
            'Silent failures under load',
            'When one device spams the mesh, other devices fail silently. '
                'No route map means no diagnostics — dangerous for safety alerts.',
          ),
          _educationPoint(
            '3',
            'Unpredictable latency',
            'Mesh routing adds 50–500ms per hop. A panic alert through 3 mesh hops '
                'could take over a second — lives depend on milliseconds.',
          ),
          _educationPoint(
            '4',
            'No real-time health monitoring',
            'Continuous glucose, HRV, ECG, and SpO2 require sub-second updates. '
                'Mesh protocols physically cannot deliver this.',
          ),
          _educationPoint(
            '5',
            'Combat impact detection impossible',
            'A punch lands in 40ms. By the time mesh routes the data, '
                'the round could be over. BLE 5.3 delivers in < 3ms.',
          ),
        ],
      ),
    );
  }

  Widget _educationPoint(String number, String title, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DesignTokens.neonAmber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: DesignTokens.neonAmber,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
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
    );
  }

  Widget _buildUseCaseMatrix() {
    final matrix = [
      {
        'use': 'Panic / SOS Alert',
        'best': 'LTE-M',
        'alt': 'BLE 5.3',
        'why': 'Works without WiFi/BLE, direct cellular',
      },
      {
        'use': 'Punch Speed Tracking',
        'best': 'UWB',
        'alt': 'BLE 5.3',
        'why': '< 1ms latency, cm-precision spatial',
      },
      {
        'use': 'Heart Rate Continuous',
        'best': 'BLE 5.3',
        'alt': 'ANT+',
        'why': 'Low power, 3ms latency, always-on',
      },
      {
        'use': 'Video Upload / Replay',
        'best': 'WiFi 6/7',
        'alt': 'LTE-M',
        'why': 'High bandwidth for HD video',
      },
      {
        'use': 'Sleep Monitoring',
        'best': 'BLE 5.3',
        'alt': 'WiFi 6',
        'why': 'Ultra-low power, all-night operation',
      },
      {
        'use': 'Gym Environment',
        'best': 'WiFi 6',
        'alt': 'NB-IoT',
        'why': 'Air quality, temp, CO2 — always-on',
      },
      {
        'use': 'Concussion Detection',
        'best': 'UWB',
        'alt': 'BLE 5.3',
        'why': 'Needs 200Hz+ sampling + sub-ms latency',
      },
      {
        'use': 'Guardian Walk-Home',
        'best': 'LTE-M',
        'alt': 'BLE 5.3',
        'why': 'Works outdoors, no WiFi dependency',
      },
    ];

    return Container(
      decoration: GlassDecoration.card(),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: DesignTokens.neonCyan.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(DesignTokens.radiusMedium),
                topRight: Radius.circular(DesignTokens.radiusMedium),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'USE CASE',
                    style: TextStyle(
                      color: DesignTokens.neonCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'BEST',
                    style: TextStyle(
                      color: DesignTokens.neonGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'ALT',
                    style: TextStyle(
                      color: DesignTokens.neonAmber,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rows
          ...matrix.map((row) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          row['use']!,
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
                          row['best']!,
                          style: const TextStyle(
                            color: DesignTokens.neonGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          row['alt']!,
                          style: const TextStyle(
                            color: DesignTokens.neonAmber,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row['why']!,
                    style: const TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _protocolColor(WearableProtocol p) {
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
