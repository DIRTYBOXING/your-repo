import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/services/health_data_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PERFORMANCE LAB
/// Advanced analytics, charting, and historical telemetry trends.
/// ═══════════════════════════════════════════════════════════════════════════
class PerformanceLabScreen extends StatefulWidget {
  const PerformanceLabScreen({super.key});

  @override
  State<PerformanceLabScreen> createState() => _PerformanceLabScreenState();
}

class _PerformanceLabScreenState extends State<PerformanceLabScreen> {
  @override
  void initState() {
    super.initState();
    // Sync latest health data on load
    Future.microtask(() => context.read<HealthDataService>().syncHealthData());
  }

  @override
  Widget build(BuildContext context) {
    final health = context.watch<HealthDataService>().latestData;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'PERFORMANCE LAB',
          style: TextStyle(
            color: AppColors.neonCyan,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          physics: const BouncingScrollPhysics(),
          children: [
            // ── TOP STATS ──
            Row(
              children: [
                _buildStatCard(
                  'AVG HR',
                  '${health?.heartRate?.toInt() ?? '--'}',
                  'bpm',
                  AppColors.neonRed,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'HRV',
                  '${health?.hrv?.toInt() ?? '--'}',
                  'ms',
                  AppColors.neonCyan,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'SLEEP',
                  '${health?.sleepHours?.toStringAsFixed(1) ?? '--'}',
                  'hrs',
                  AppColors.neonPurple,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── TRAINING LOAD CHART ──
            const Text(
              '7-DAY TRAINING LOAD',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.neonBlue.withValues(alpha: 0.3),
                ),
              ),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 1,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 40),
                        FlSpot(1, 65),
                        FlSpot(2, 50),
                        FlSpot(3, 85),
                        FlSpot(4, 70),
                        FlSpot(5, 95),
                        FlSpot(6, 60),
                      ],
                      isCurved: true,
                      color: AppColors.neonBlue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.neonBlue.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── BIOMECHANICS MODULE ──
            const Text(
              'BIOMECHANICAL ASYMMETRY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.neonAmber.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.neonAmber.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.neonAmber,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'LEFT LEG DOMINANCE DETECTED',
                            style: TextStyle(
                              color: AppColors.neonAmber,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your Nvidia DeepStream sparring analysis shows a 14% power variance favouring your left leg during kicks. This asymmetry increases knee injury risk. Atlas recommends unilateral stability work today.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
