import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/clip_analytics_model.dart';

/// Engagement gauge widget
/// Displays overall engagement metrics across clips
class EngagementGaugeWidget extends StatelessWidget {
  final List<ClipAnalytics> recentClips;

  const EngagementGaugeWidget({Key? key, required this.recentClips})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (recentClips.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.neonCyan.withOpacity(0.2)),
        ),
        child: const Center(
          child: Text(
            'No clips yet',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ),
      );
    }

    // Calculate aggregate metrics
    final totalViews = recentClips.fold<int>(
      0,
      (sum, clip) => sum + clip.views,
    );
    final totalLikes = recentClips.fold<int>(
      0,
      (sum, clip) => sum + clip.likes,
    );
    final totalShares = recentClips.fold<int>(
      0,
      (sum, clip) => sum + clip.shares,
    );
    final totalConversions = recentClips.fold<int>(
      0,
      (sum, clip) => sum + clip.conversions,
    );

    final avgEngagement = totalViews > 0
        ? (totalLikes + totalShares) / totalViews
        : 0;
    final avgConversion = (totalLikes + totalShares) > 0
        ? totalConversions / (totalLikes + totalShares)
        : 0;
    final avgTrending =
        recentClips.fold<double>(0, (sum, clip) => sum + clip.trendingScore) /
        recentClips.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Engagement Overview',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Main Gauge
          Center(
            child: _buildGaugeChart(avgEngagement, avgConversion, avgTrending),
          ),
          const SizedBox(height: 16),
          // Metrics Grid
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: [
              _buildMetricCard(
                'Engagement',
                '${(avgEngagement * 100).toStringAsFixed(1)}%',
                AppTheme.neonCyan,
              ),
              _buildMetricCard(
                'Conversion',
                '${(avgConversion * 100).toStringAsFixed(1)}%',
                AppTheme.neonGreen,
              ),
              _buildMetricCard(
                'Trending Avg',
                '${avgTrending.toStringAsFixed(1)}/10',
                AppTheme.neonAmber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeChart(
    double engagement,
    double conversion,
    double trending,
  ) {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.neonCyan.withOpacity(0.05),
              border: Border.all(
                color: AppTheme.neonCyan.withOpacity(0.2),
                width: 2,
              ),
            ),
          ),
          // Engagement arc
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: engagement.clamp(0.0, 1.0),
              strokeWidth: 6,
              backgroundColor: AppTheme.neonCyan.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.neonCyan,
              ),
            ),
          ),
          // Center text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(engagement * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neonCyan,
                ),
              ),
              const Text(
                'Engagement',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
