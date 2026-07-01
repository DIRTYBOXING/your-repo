import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC CHART HELPERS — Legends, tooltips, gradient fills, sparklines
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Reusable chart decoration layer on top of fl_chart.
///   DFCChartLegend    — horizontal legend strip
///   DFCTooltipStyle   — standard touch tooltip config
///   DFCGradientFill   — gradient below-curve fill presets
///   DFCSparkline      — tiny inline sparkline widget
///   DFCAreaChart      — full area chart with gradient + tooltip + legend
/// ═══════════════════════════════════════════════════════════════════════════

// ─── Legend ──────────────────────────────────────────────────────────────

class DFCLegendItem {
  final String label;
  final Color color;
  const DFCLegendItem({required this.label, required this.color});
}

class DFCChartLegend extends StatelessWidget {
  final List<DFCLegendItem> items;
  const DFCChartLegend({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: DesignTokens.fontSizeCaption,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ─── Tooltip Style ──────────────────────────────────────────────────────

class DFCTooltipStyle {
  DFCTooltipStyle._();

  /// Standard fl_chart tooltip configuration
  static LineTouchData touchData({
    Color? tooltipBgColor,
    Color? indicatorColor,
  }) {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => tooltipBgColor ?? const Color(0xE0121828),
        tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        getTooltipItems: (spots) => spots.map((spot) {
          return LineTooltipItem(
            spot.y.toStringAsFixed(1),
            TextStyle(
              color: spot.bar.color ?? AppTheme.neonCyan,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          );
        }).toList(),
      ),
      getTouchedSpotIndicator: (barData, spotIndexes) {
        return spotIndexes.map((i) {
          return TouchedSpotIndicatorData(
            FlLine(
              color: (indicatorColor ?? AppTheme.neonCyan).withValues(
                alpha: 0.4,
              ),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
            FlDotData(
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: bar.color ?? AppTheme.neonCyan,
                  strokeWidth: 2,
                  strokeColor: AppTheme.primaryBackground,
                );
              },
            ),
          );
        }).toList();
      },
    );
  }
}

// ─── Gradient Fill Presets ───────────────────────────────────────────────

class DFCGradientFill {
  DFCGradientFill._();

  /// Below-curve gradient from accent → transparent
  static List<Color> belowLine(Color accent) => [
    accent.withValues(alpha: 0.25),
    accent.withValues(alpha: 0.0),
  ];

  /// Standard gradient stops
  static const List<double> stops = [0.0, 1.0];

  /// Create a LineChartBarData with gradient fill
  static LineChartBarData lineWithGradient({
    required List<FlSpot> spots,
    Color color = AppTheme.neonCyan,
    double barWidth = 2.5,
    bool curved = true,
    bool showDots = false,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: curved,
      color: color,
      barWidth: barWidth,
      isStrokeCapRound: true,
      dotData: FlDotData(show: showDots),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: belowLine(color),
          stops: stops,
        ),
      ),
    );
  }
}

// ─── Sparkline ──────────────────────────────────────────────────────────

/// Tiny inline sparkline chart — no axes, no labels, just the curve
class DFCSparkline extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double height;
  final double width;
  final double strokeWidth;

  const DFCSparkline({
    super.key,
    required this.data,
    this.color = AppTheme.neonCyan,
    this.height = 32,
    this.width = 80,
    this.strokeWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return SizedBox(width: width, height: height);

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    return SizedBox(
      width: width,
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            DFCGradientFill.lineWithGradient(
              spots: spots,
              color: color,
              barWidth: strokeWidth,
            ),
          ],
        ),
        duration: DesignTokens.animNormal,
      ),
    );
  }
}

// ─── Full Area Chart ────────────────────────────────────────────────────

/// Complete area chart with gradient fill, tooltips, and optional legend
class DFCAreaChart extends StatelessWidget {
  final List<LineChartBarData> lines;
  final List<DFCLegendItem>? legend;
  final double height;
  final FlTitlesData? titlesData;
  final FlGridData? gridData;

  const DFCAreaChart({
    super.key,
    required this.lines,
    this.legend,
    this.height = 200,
    this.titlesData,
    this.gridData,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (legend != null) ...[
          DFCChartLegend(items: legend!),
          const SizedBox(height: DesignTokens.spacingM),
        ],
        SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              gridData:
                  gridData ??
                  FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.surfaceColor.withValues(alpha: 0.5),
                      strokeWidth: 0.5,
                    ),
                  ),
              titlesData: titlesData ?? const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: DFCTooltipStyle.touchData(),
              lineBarsData: lines,
            ),
            duration: DesignTokens.animNormal,
          ),
        ),
      ],
    );
  }
}
