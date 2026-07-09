import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/creator_dashboard_controller.dart';
import '../models/creator_insights_model.dart';

/// AI-powered insights and recommendations screen
class CreatorInsightsScreen extends StatefulWidget {
  final String creatorId;

  const CreatorInsightsScreen({Key? key, required this.creatorId})
    : super(key: key);

  @override
  State<CreatorInsightsScreen> createState() => _CreatorInsightsScreenState();
}

class _CreatorInsightsScreenState extends State<CreatorInsightsScreen> {
  late CreatorDashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = context.read<CreatorDashboardController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('AI Insights'),
        backgroundColor: AppTheme.bgCard,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Consumer<CreatorDashboardController>(
        builder: (context, controller, _) {
          if (controller.insights == null) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonCyan),
              ),
            );
          }

          final insights = controller.insights!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recommendations Score
                _buildScoreCard(insights),

                const SizedBox(height: 24),

                // Key Recommendations
                _buildRecommendationsSection(insights),

                const SizedBox(height: 24),

                // Top Clip Types
                _buildTopClipTypesSection(insights),

                const SizedBox(height: 24),

                // Best Post Hours
                _buildBestPostHoursSection(insights),

                const SizedBox(height: 24),

                // Performance Benchmark
                _buildBenchmarkSection(insights),

                const SizedBox(height: 24),

                // Trending Opportunities
                _buildOpportunitiesSection(insights),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreCard(CreatorInsights insights) {
    final score = insights.recommendationScore;
    final confidence = score >= 80
        ? 'High'
        : score >= 60
        ? 'Medium'
        : 'Low';
    final confidenceColor = score >= 80
        ? AppTheme.neonGreen
        : score >= 60
        ? AppTheme.neonAmber
        : AppTheme.neonRed;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonCyan.withOpacity(0.15),
            AppTheme.neonAmber.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'Insights Confidence',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$score%',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neonCyan,
                    ),
                  ),
                  Text(
                    confidence,
                    style: TextStyle(
                      fontSize: 12,
                      color: confidenceColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.neonCyan.withOpacity(0.1),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 3,
                    backgroundColor: AppTheme.neonCyan.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.neonCyan,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(CreatorInsights insights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Recommendations',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...insights.recommendations.map((rec) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildRecommendationTile(rec),
          );
        }),
      ],
    );
  }

  Widget _buildRecommendationTile(String recommendation) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.neonCyan.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopClipTypesSection(CreatorInsights insights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Performing Clip Types',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...insights.topClipTypes.asMap().entries.map((entry) {
          final index = entry.key;
          final clipType = entry.value;
          final colors = [
            AppTheme.neonGreen,
            AppTheme.neonCyan,
            AppTheme.neonAmber,
          ];
          final color = colors[index % colors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    clipType,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBestPostHoursSection(CreatorInsights insights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Best Times to Post',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.neonCyan.withOpacity(0.2)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: insights.bestPostHours.map((hour) {
              final ampm = hour >= 12
                  ? '${hour == 12 ? 12 : hour - 12}PM'
                  : '${hour == 0 ? 12 : hour}AM';

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.neonCyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.neonCyan.withOpacity(0.5)),
                ),
                child: Text(
                  ampm,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.neonCyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBenchmarkSection(CreatorInsights insights) {
    final benchmark = insights.benchmarkVsCreators;
    final isAboveAverage = insights.isAboveAverage;
    final performanceMultiplier = insights.performanceMultiplier;

    Color statusColor = isAboveAverage
        ? AppTheme.neonGreen
        : AppTheme.neonAmber;
    String statusText = isAboveAverage
        ? '📈 Above Average'
        : '📊 Below Average';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance vs Peers',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                Text(
                  '${benchmark.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your average conversion is ${performanceMultiplier.toStringAsFixed(2)}x the typical creator',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunitiesSection(CreatorInsights insights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trending Opportunities',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...insights.opportunities.map((opportunity) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.neonRed.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      opportunity,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
