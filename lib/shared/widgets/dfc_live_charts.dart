/// ═══════════════════════════════════════════════════════════════════════════
/// DFC LIVE CHARTS - Production-Grade Real-Time Visualization Widgets
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Advanced, animated charts for athlete biometrics, energy systems, HR zones,
/// training load, recovery, and performance prediction. Uses fl_chart + custom
/// painters for maximum visual impact with neon DFC theme.
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';

/// Neon line chart for time-series metrics (HR, HRV, resting HR, glucose, etc.)
class NeonLineChart extends StatelessWidget {
  final String title;
  final List<double> data;
  final String unit;
  final Color lineColor;
  final Color gradientStart;
  final Color gradientEnd;
  final double minValue;
  final double maxValue;
  final int? touchedIndex;
  final Function(int?)? onTouched;
  final bool showGrid;

  const NeonLineChart({
    super.key,
    required this.title,
    required this.data,
    required this.unit,
    this.lineColor = const Color(0xFF00D4FF),
    this.gradientStart = const Color(0xFF00D4FF),
    this.gradientEnd = const Color(0xFF0099CC),
    this.minValue = 0,
    this.maxValue = 100,
    this.touchedIndex,
    this.onTouched,
    this.showGrid = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lineColor.withValues(alpha: 0.3)),
        // gradient background
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            lineColor.withValues(alpha: 0.05),
            lineColor.withValues(alpha: 0.02),
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Chart
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: showGrid,
                  drawVerticalLine: false,
                  horizontalInterval: (maxValue - minValue) / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: lineColor.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    
                  ),
                  topTitles: const AxisTitles(
                    
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (data.length / 4).ceil().toDouble(),
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: lineColor.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (maxValue - minValue) / 4,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: TextStyle(
                          color: lineColor.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                minY: minValue,
                maxY: maxValue,
                lineBarsData: [
                  LineChartBarData(
                    spots: data
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [gradientStart, gradientEnd],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          gradientStart.withValues(alpha: 0.2),
                          gradientEnd.withValues(alpha: 0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        return LineTooltipItem(
                          '${barSpot.y.toStringAsFixed(1)} $unit',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          // Stats footer
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(
                label: 'Latest',
                value: data.last.toStringAsFixed(1),
                unit: unit,
                color: lineColor,
              ),
              _StatItem(
                label: 'Avg',
                value: (data.reduce((a, b) => a + b) / data.length)
                    .toStringAsFixed(1),
                unit: unit,
                color: lineColor,
              ),
              _StatItem(
                label: 'Max',
                value: data.reduce((a, b) => a > b ? a : b).toStringAsFixed(1),
                unit: unit,
                color: lineColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Stat display item for chart footers
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Heart Rate Zone visualization (donut chart showing time in each zone)
class HeartRateZoneDonut extends StatelessWidget {
  final Map<String, double> zonePercentages; // Zone name -> % of time
  final Map<String, Color> zoneColors;
  final int centerValue; // Value to display in middle

  const HeartRateZoneDonut({
    super.key,
    required this.zonePercentages,
    required this.zoneColors,
    this.centerValue = 78,
  });

  @override
  Widget build(BuildContext context) {
    final sections = <PieChartSectionData>[];
    zonePercentages.forEach((zone, percentage) {
      sections.add(
        PieChartSectionData(
          color: zoneColors[zone] ?? Colors.grey,
          value: percentage,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 48,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    });

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.neonCyan.withValues(alpha: 0.3),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.neonCyan.withValues(alpha: 0.05),
            AppTheme.neonCyan.withValues(alpha: 0.02),
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Heart Rate Zone Distribution',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: sections,
                    startDegreeOffset: -90,
                    centerSpaceRadius: 50,
                  ),
                ),
                // Center value
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$centerValue',
                      style: const TextStyle(
                        color: AppTheme.neonCyan,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'bpm',
                      style: TextStyle(
                        color: AppTheme.neonCyan.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: zonePercentages.entries.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: zoneColors[e.key],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${e.key}: ${e.value.toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// ACWR (Acute:Chronic Workload Ratio) injury risk gauge
class ACWRGauge extends StatelessWidget {
  final double acwr; // Acute:Chronic ratio
  final double safeMin; // Typically 0.8
  final double safeMax; // Typically 1.3
  final bool showRecommendation;

  const ACWRGauge({
    super.key,
    required this.acwr,
    this.safeMin = 0.8,
    this.safeMax = 1.3,
    this.showRecommendation = true,
  });

  String get riskLevel {
    if (acwr < safeMin) return 'Low Load';
    if (acwr > safeMax) return '⚠️ High Load';
    return 'Optimal';
  }

  Color get gaugeColor {
    if (acwr < safeMin) return AppTheme.neonGreen;
    if (acwr > safeMax) return AppTheme.neonOrange;
    return AppTheme.neonCyan;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gaugeColor.withValues(alpha: 0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gaugeColor.withValues(alpha: 0.05),
            gaugeColor.withValues(alpha: 0.02),
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Workload Ratio (ACWR)',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text(
                  acwr.toStringAsFixed(2),
                  style: TextStyle(
                    color: gaugeColor,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  riskLevel,
                  style: TextStyle(
                    color: gaugeColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Gauge bar
          Container(
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(
                color: gaugeColor.withValues(alpha: 0.3),
              ),
            ),
            child: Stack(
              children: [
                // Safe zone indicators
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.neonGreen.withValues(alpha: 0.3),
                        AppTheme.neonCyan.withValues(alpha: 0.3),
                        AppTheme.neonOrange.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
                // Current position indicator
                Positioned(
                  left: _normalizeAcwr(acwr) * (100 - 8) / 100,
                  child: Container(
                    width: 8,
                    height: 16,
                    decoration: BoxDecoration(
                      color: gaugeColor,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: gaugeColor.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Low',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
              const Text(
                'Optimal',
                style: TextStyle(
                  color: AppTheme.neonCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'High',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Normalize ACWR (0.5 to 2.0) to 0-1 range
  double _normalizeAcwr(double value) {
    const min = 0.5;
    const max = 2.0;
    return ((value - min) / (max - min)).clamp(0, 1);
  }
}

/// Recovery readiness composite score gauge
class RecoveryScoreGauge extends StatelessWidget {
  final int score; // 0-100
  final String subtitle;

  const RecoveryScoreGauge({
    super.key,
    required this.score,
    this.subtitle = 'Recovery Readiness',
  });

  Color get scoreColor {
    if (score >= 80) return AppTheme.neonGreen;
    if (score >= 60) return AppTheme.neonCyan;
    if (score >= 40) return AppTheme.neonOrange;
    return AppTheme.neonMagenta;
  }

  String get recommendation {
    if (score >= 80) return '✓ Ready to train hard';
    if (score >= 60) return '◐ Normal training OK';
    if (score >= 40) return '◑ Active recovery recommended';
    return '✗ Rest day needed';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scoreColor.withValues(alpha: 0.05),
            scoreColor.withValues(alpha: 0.02),
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          // Circular gauge
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '/100',
                      style: TextStyle(
                        color: scoreColor.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            recommendation,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scoreColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Energy system breakdown (ATP-PC vs Glycolytic vs Oxidative)
class EnergySystemChart extends StatelessWidget {
  final double atpPcPercent;
  final double glycolyticPercent;
  final double oxidativePercent;

  const EnergySystemChart({
    super.key,
    required this.atpPcPercent,
    required this.glycolyticPercent,
    required this.oxidativePercent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.neonMagenta.withValues(alpha: 0.3),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.neonMagenta.withValues(alpha: 0.05),
            AppTheme.neonMagenta.withValues(alpha: 0.02),
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Energy System Usage',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          // Stacked bars
          Column(
            children: [
              _EnergyBar(
                label: 'ATP-PC (Immediate)',
                percentage: atpPcPercent,
                color: AppTheme.neonOrange,
              ),
              const SizedBox(height: 12),
              _EnergyBar(
                label: 'Glycolytic (Minutes)',
                percentage: glycolyticPercent,
                color: AppTheme.neonCyan,
              ),
              const SizedBox(height: 12),
              _EnergyBar(
                label: 'Oxidative (Aerobic)',
                percentage: oxidativePercent,
                color: AppTheme.neonGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Single energy system bar
class _EnergyBar extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;

  const _EnergyBar({
    required this.label,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 12,
            ),
          ),
        ),
      ],
    );
  }
}
