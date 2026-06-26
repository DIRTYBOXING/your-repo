import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/fighter_performance.dart';
import '../services/fighter_analytics_service.dart';
import '../../../core/theme/app_theme.dart';

class FighterAnalyticsDashboard extends StatefulWidget {
  final String fighterId;

  const FighterAnalyticsDashboard({super.key, required this.fighterId});

  @override
  State<FighterAnalyticsDashboard> createState() =>
      _FighterAnalyticsDashboardState();
}

class _FighterAnalyticsDashboardState extends State<FighterAnalyticsDashboard> {
  late final FighterAnalyticsService _analyticsService;
  late Future<FighterPerformance> _performanceFuture;

  @override
  void initState() {
    super.initState();
    _analyticsService = FighterAnalyticsService();
    _performanceFuture = _analyticsService.getFighterPerformance(
      widget.fighterId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: _buildAppBar(),
      body: FutureBuilder<FighterPerformance>(
        future: _performanceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading analytics: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text(
                'No analytics data available yet.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final performance = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsOverview(performance),
                const SizedBox(height: 24),
                _buildWinRateCard(performance),
                const SizedBox(height: 20),
                _buildMethodBreakdown(performance),
                const SizedBox(height: 20),
                _buildAccuracyMetrics(performance),
                const SizedBox(height: 20),
                _buildStrengthsAndWeaknesses(performance),
                const SizedBox(height: 20),
                _buildRecentFights(performance),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('FIGHTER ANALYTICS'),
      backgroundColor: AppTheme.cardBackground,
      foregroundColor: AppTheme.neonCyan,
      elevation: 0,
      centerTitle: true,
    );
  }

  Widget _buildStatsOverview(FighterPerformance perf) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonCyan.withValues(alpha: 0.1),
            AppTheme.neonMagenta.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatCard(
                label: 'Total Fights',
                value: perf.totalFights.toString(),
                color: AppTheme.neonCyan,
              ),
              _StatCard(
                label: 'Wins',
                value: perf.wins.toString(),
                color: AppTheme.neonGreen,
              ),
              _StatCard(
                label: 'Losses',
                value: perf.losses.toString(),
                color: AppTheme.errorColor,
              ),
              _StatCard(
                label: 'Draws',
                value: perf.draws.toString(),
                color: AppTheme.neonOrange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatCard(
                label: 'Current Streak',
                value: perf.currentWinStreak.toString(),
                color: AppTheme.neonMagenta,
              ),
              _StatCard(
                label: 'Best Streak',
                value: perf.longestWinStreak.toString(),
                color: AppTheme.neonPurple,
              ),
              _StatCard(
                label: 'Rating',
                value: perf.rating.toStringAsFixed(0),
                color: AppTheme.neonCyan,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWinRateCard(FighterPerformance perf) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WIN RATE TREND',
            style: TextStyle(
              color: AppTheme.neonCyan,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(
                  rightTitles: AxisTitles(
                    
                  ),
                  topTitles: AxisTitles(
                    
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateWinRateSpots(perf),
                    isCurved: true,
                    color: AppTheme.neonCyan,
                    barWidth: 3,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Win Rate: ${perf.winRate.toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodBreakdown(FighterPerformance perf) {
    final total = perf.knockouts + perf.submissions + perf.decisions;
    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WIN METHOD BREAKDOWN',
            style: TextStyle(
              color: AppTheme.neonCyan,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MethodBar(
                  label: 'KO',
                  count: perf.knockouts,
                  total: total,
                  color: AppTheme.errorColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MethodBar(
                  label: 'SUB',
                  count: perf.submissions,
                  total: total,
                  color: AppTheme.neonMagenta,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MethodBar(
                  label: 'DEC',
                  count: perf.decisions,
                  total: total,
                  color: AppTheme.neonCyan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyMetrics(FighterPerformance perf) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonPurple.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COMBAT METRICS',
            style: TextStyle(
              color: AppTheme.neonPurple,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _MetricBar(
            label: 'Strike Accuracy',
            percentage: perf.strikeAccuracy,
            color: AppTheme.neonCyan,
          ),
          const SizedBox(height: 12),
          _MetricBar(
            label: 'Takedown Defense',
            percentage: perf.takedownDefense,
            color: AppTheme.neonGreen,
          ),
          const SizedBox(height: 12),
          _MetricBar(
            label: 'Octagon Control',
            percentage: perf.controlTime,
            color: AppTheme.neonMagenta,
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthsAndWeaknesses(FighterPerformance perf) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonOrange.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROFILE ANALYSIS',
            style: TextStyle(
              color: AppTheme.neonOrange,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          if (perf.knockouts > perf.submissions)
            const _ProfileTag(
              label: '🥊 STRIKER',
              description: 'Specialized in striking and KO finishes',
              color: AppTheme.errorColor,
            )
          else
            const _ProfileTag(
              label: '🔗 GRAPPLER',
              description: 'Specialized in submissions and wrestling',
              color: AppTheme.neonMagenta,
            ),
          const SizedBox(height: 10),
          if (perf.strikeAccuracy > 50)
            const _ProfileTag(
              label: '⚡ ACCURATE',
              description: 'High strike accuracy and precision',
              color: AppTheme.neonCyan,
            ),
          if (perf.takedownDefense > 70)
            const _ProfileTag(
              label: '🛡️ DEFENSIVE',
              description: 'Strong takedown defense',
              color: AppTheme.neonGreen,
            ),
        ],
      ),
    );
  }

  Widget _buildRecentFights(FighterPerformance perf) {
    if (perf.recentFights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RECENT FIGHTS',
            style: TextStyle(
              color: AppTheme.neonCyan,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...perf.recentFights.take(5).map((fight) {
            final resultColor = fight.result == 'WIN'
                ? AppTheme.neonGreen
                : fight.result == 'LOSS'
                ? AppTheme.errorColor
                : AppTheme.neonOrange;

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'vs ${fight.opponent}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            fight.event,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: resultColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: resultColor),
                          ),
                          child: Text(
                            '${fight.result} - ${fight.method}',
                            style: TextStyle(
                              color: resultColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'R${fight.roundEnded} ${fight.timeInRound}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.white.withValues(alpha: 0.1)),
                const SizedBox(height: 12),
              ],
            );
          }),
        ],
      ),
    );
  }

  List<FlSpot> _generateWinRateSpots(FighterPerformance perf) {
    // Generate sample data for the chart
    return [
      const FlSpot(1, 50),
      const FlSpot(2, 55),
      const FlSpot(3, 60),
      const FlSpot(4, 58),
      const FlSpot(5, 65),
      const FlSpot(6, 70),
    ];
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _MethodBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0
        ? ((count / total) * 100).clamp(0.0, 100.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$label: $count (${percentage.toStringAsFixed(0)}%)',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MetricBar extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;

  const _MetricBar({
    required this.label,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final safePercentage = percentage.clamp(0.0, 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              '${safePercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: safePercentage / 100,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _ProfileTag extends StatelessWidget {
  final String label;
  final String description;
  final Color color;

  const _ProfileTag({
    required this.label,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
