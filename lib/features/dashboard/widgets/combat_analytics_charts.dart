import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/stats/combat_stats.dart';
import '../../../shared/services/wearable_api_connector_service.dart';

/// Real fl_chart-powered analytics panels for the DFC dashboard.
/// Renders ACWR trend, recovery radar, strike accuracy, and sleep/HRV charts
/// from live CombatStats + NormalizedHealthPayload data.

// ── ACWR Trend Line Chart ────────────────────────────────────────────────

class AcwrTrendChart extends StatelessWidget {
  final List<double> acwrValues; // 7+ days of ACWR readings
  final double dangerThreshold;

  const AcwrTrendChart({
    super.key,
    required this.acwrValues,
    this.dangerThreshold = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    if (acwrValues.isEmpty) {
      return const _EmptyChartPlaceholder(label: 'ACWR Trend');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: DesignTokens.neonCyan, size: 20),
              const SizedBox(width: 8),
              const Text(
                'ACWR Trend',
                style: TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _AcwrStatusBadge(current: acwrValues.last),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 0.5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        'D${value.toInt() + 1}',
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    
                  ),
                  rightTitles: const AxisTitles(
                    
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: (acwrValues.reduce((a, b) => a > b ? a : b) + 0.5).clamp(
                  2.0,
                  3.0,
                ),
                lineBarsData: [
                  // ACWR line
                  LineChartBarData(
                    spots: acwrValues
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: DesignTokens.neonGreen,
                    barWidth: 3,
                    dotData: FlDotData(
                      getDotPainter: (spot, xPercentage, bar, index) =>
                          FlDotCirclePainter(
                            radius: 3,
                            color: spot.y > dangerThreshold
                                ? DesignTokens.neonRed
                                : DesignTokens.neonGreen,
                            strokeWidth: 1,
                            strokeColor: Colors.white24,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: DesignTokens.neonGreen.withValues(alpha: 0.08),
                    ),
                  ),
                  // Danger threshold line
                  LineChartBarData(
                    spots: [
                      FlSpot(0, dangerThreshold),
                      FlSpot(
                        (acwrValues.length - 1).toDouble(),
                        dangerThreshold,
                      ),
                    ],
                    color: DesignTokens.neonRed.withValues(alpha: 0.5),
                    barWidth: 1,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AcwrStatusBadge extends StatelessWidget {
  final double current;
  const _AcwrStatusBadge({required this.current});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    if (current < 0.8) {
      color = DesignTokens.neonAmber;
      label = 'UNDERTRAINED';
    } else if (current <= 1.3) {
      color = DesignTokens.neonGreen;
      label = 'SWEET SPOT';
    } else if (current <= 1.5) {
      color = DesignTokens.neonAmber;
      label = 'CAUTION';
    } else {
      color = DesignTokens.neonRed;
      label = 'DANGER';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '${current.toStringAsFixed(2)} — $label',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Strike Accuracy Bar Chart ────────────────────────────────────────────

class StrikeAccuracyChart extends StatelessWidget {
  final CombatStats stats;

  const StrikeAccuracyChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignTokens.neonAmber.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sports_mma, color: DesignTokens.neonAmber, size: 20),
              SizedBox(width: 8),
              Text(
                'Combat Accuracy',
                style: TextStyle(
                  color: DesignTokens.neonAmber,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                gridData: FlGridData(
                  horizontalInterval: 25,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}%',
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0:
                            return const Text(
                              'Strikes',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            );
                          case 1:
                            return const Text(
                              'Takedowns',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            );
                          case 2:
                            return const Text(
                              'Win Rate',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            );
                          default:
                            return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    
                  ),
                  rightTitles: const AxisTitles(
                    
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _bar(0, stats.accuracy, DesignTokens.neonCyan),
                  _bar(1, stats.takedownAccuracy, DesignTokens.neonGreen),
                  _bar(2, stats.winRate * 100, DesignTokens.neonAmber),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _bar(int x, double value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value.clamp(0, 100),
          color: color,
          width: 28,
          borderRadius: BorderRadius.circular(6),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: color.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }
}

// ── Recovery & Vitals Radar Chart ────────────────────────────────────────

class RecoveryRadarChart extends StatelessWidget {
  final NormalizedHealthPayload? healthData;

  const RecoveryRadarChart({super.key, this.healthData});

  @override
  Widget build(BuildContext context) {
    if (healthData == null) {
      return const _EmptyChartPlaceholder(label: 'Recovery Radar');
    }

    final h = healthData!;
    // Normalize each metric to 0-1 range
    final recoveryNorm = (h.recoveryScore ?? 0) / 100;
    final readinessNorm = (h.readinessScore ?? 0) / 100;
    final sleepNorm = ((h.sleepHours ?? 0) / 9).clamp(0.0, 1.0);
    final hrvNorm = ((h.hrvMs ?? 0) / 120).clamp(0.0, 1.0);
    final spo2Norm = ((h.spo2 ?? 90) - 90) / 10; // 90-100 mapped to 0-1

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignTokens.neonMagenta.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.radar, color: DesignTokens.neonMagenta, size: 20),
              SizedBox(width: 8),
              Text(
                'Recovery Radar',
                style: TextStyle(
                  color: DesignTokens.neonMagenta,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                titlePositionPercentageOffset: 0.2,
                dataSets: [
                  RadarDataSet(
                    fillColor: DesignTokens.neonMagenta.withValues(alpha: 0.15),
                    borderColor: DesignTokens.neonMagenta,
                    borderWidth: 2,
                    entryRadius: 3,
                    dataEntries: [
                      RadarEntry(value: recoveryNorm),
                      RadarEntry(value: readinessNorm),
                      RadarEntry(value: sleepNorm),
                      RadarEntry(value: hrvNorm),
                      RadarEntry(value: spo2Norm.clamp(0.0, 1.0)),
                    ],
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                tickBorderData: BorderSide(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                tickCount: 4,
                ticksTextStyle: const TextStyle(color: Colors.white24, fontSize: 8),
                titleTextStyle: const TextStyle(color: Colors.white54, fontSize: 10),
                getTitle: (index, _) {
                  switch (index) {
                    case 0:
                      return const RadarChartTitle(text: 'Recovery');
                    case 1:
                      return const RadarChartTitle(text: 'Readiness');
                    case 2:
                      return const RadarChartTitle(text: 'Sleep');
                    case 3:
                      return const RadarChartTitle(text: 'HRV');
                    case 4:
                      return const RadarChartTitle(text: 'SpO₂');
                    default:
                      return const RadarChartTitle(text: '');
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sleep & HRV Dual-Axis Line Chart ─────────────────────────────────────

class SleepHrvChart extends StatelessWidget {
  final List<double> sleepHours; // 7 days
  final List<int> hrvValues; // 7 days

  const SleepHrvChart({
    super.key,
    required this.sleepHours,
    required this.hrvValues,
  });

  @override
  Widget build(BuildContext context) {
    if (sleepHours.isEmpty && hrvValues.isEmpty) {
      return const _EmptyChartPlaceholder(label: 'Sleep & HRV');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.neonBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bedtime, color: DesignTokens.neonBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'Sleep & HRV (7-Day)',
                style: TextStyle(
                  color: DesignTokens.neonBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              _LegendDot(color: DesignTokens.neonBlue, label: 'Sleep (hrs)'),
              SizedBox(width: 16),
              _LegendDot(color: DesignTokens.neonGreen, label: 'HRV (ms)'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        'D${value.toInt() + 1}',
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    
                  ),
                  rightTitles: const AxisTitles(
                    
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 12,
                lineBarsData: [
                  // Sleep hours
                  if (sleepHours.isNotEmpty)
                    LineChartBarData(
                      spots: sleepHours
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: DesignTokens.neonBlue,
                      barWidth: 2.5,
                      belowBarData: BarAreaData(
                        show: true,
                        color: DesignTokens.neonBlue.withValues(alpha: 0.06),
                      ),
                    ),
                  // HRV (scaled: divide by 15 to fit 0-12 axis alongside sleep)
                  if (hrvValues.isNotEmpty)
                    LineChartBarData(
                      spots: hrvValues
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value / 15.0))
                          .toList(),
                      isCurved: true,
                      color: DesignTokens.neonGreen,
                      barWidth: 2.5,
                      dashArray: [4, 3],
                    ),
                ],
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    // 7-hour sleep target
                    HorizontalLine(
                      y: 7,
                      color: DesignTokens.neonBlue.withValues(alpha: 0.3),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: TextStyle(
                          color: DesignTokens.neonBlue.withValues(alpha: 0.5),
                          fontSize: 9,
                        ),
                        labelResolver: (_) => '7hr target',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Win/Loss Pie Chart ───────────────────────────────────────────────────

class WinLossPieChart extends StatelessWidget {
  final CombatStats stats;

  const WinLossPieChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.wins + stats.losses;
    if (total == 0) {
      return const _EmptyChartPlaceholder(label: 'Win/Loss Record');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignTokens.neonGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: DesignTokens.neonGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Record — ${stats.wins}W ${stats.losses}L ${stats.knockouts}KO',
                style: const TextStyle(
                  color: DesignTokens.neonGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 30,
                sections: [
                  PieChartSectionData(
                    value: stats.wins.toDouble(),
                    color: DesignTokens.neonGreen,
                    title: '${stats.wins}W',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    radius: 40,
                  ),
                  if (stats.knockouts > 0)
                    PieChartSectionData(
                      value: stats.knockouts.toDouble(),
                      color: DesignTokens.neonAmber,
                      title: '${stats.knockouts}KO',
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      radius: 40,
                    ),
                  PieChartSectionData(
                    value: stats.losses.toDouble(),
                    color: DesignTokens.neonRed,
                    title: '${stats.losses}L',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    radius: 40,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ───────────────────────────────────────────────────────

class _EmptyChartPlaceholder extends StatelessWidget {
  final String label;
  const _EmptyChartPlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bar_chart, color: Colors.white24, size: 32),
            const SizedBox(height: 8),
            Text(
              '$label — No data yet',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const Text(
              'Connect a device or log a session to see charts',
              style: TextStyle(color: Colors.white24, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}
