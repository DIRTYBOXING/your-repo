import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/creator_dashboard_controller.dart';
import '../models/clip_analytics_model.dart';

/// Detailed clip analytics screen
/// Shows deep-dive metrics for a specific clip
class ClipAnalyticsDetailScreen extends StatefulWidget {
  final String clipId;
  final ClipAnalytics? initialClip;

  const ClipAnalyticsDetailScreen({
    Key? key,
    required this.clipId,
    this.initialClip,
  }) : super(key: key);

  @override
  State<ClipAnalyticsDetailScreen> createState() =>
      _ClipAnalyticsDetailScreenState();
}

class _ClipAnalyticsDetailScreenState extends State<ClipAnalyticsDetailScreen> {
  late CreatorDashboardController _controller;
  ClipAnalytics? _clip;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = context.read<CreatorDashboardController>();
    _clip = widget.initialClip;
    _loadClipAnalytics();
  }

  Future<void> _loadClipAnalytics() async {
    final clip = await _controller.getClipAnalytics(widget.clipId);
    setState(() {
      _clip = clip ?? _clip;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('Clip Analytics'),
        backgroundColor: AppTheme.bgCard,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonCyan),
              ),
            )
          : _clip == null
          ? const Center(
              child: Text(
                'Clip not found',
                style: TextStyle(color: AppTheme.textError),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Clip Title and Type
                  Text(
                    _clip!.clipTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.neonCyan.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _clip!.clipType,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.neonCyan,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_clip!.isTrending)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.neonRed.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            children: [
                              Text('🔥 ', style: TextStyle(fontSize: 12)),
                              Text(
                                'TRENDING',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.neonRed,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Primary Metrics
                  _buildMetricsGrid(_clip!),

                  const SizedBox(height: 24),

                  // Engagement Section
                  _buildEngagementSection(_clip!),

                  const SizedBox(height: 24),

                  // Conversion Funnel
                  _buildConversionFunnel(_clip!),

                  const SizedBox(height: 24),

                  // Performance Score
                  _buildPerformanceScore(_clip!),

                  const SizedBox(height: 24),

                  // Fight Context
                  if (_clip!.fightId != null || _clip!.eventId != null)
                    _buildFightContext(_clip!),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricsGrid(ClipAnalytics clip) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildMetricTile('👁️ Views', clip.formattedViews(), AppTheme.neonCyan),
        _buildMetricTile('❤️ Likes', '${clip.likes}', AppTheme.neonRed),
        _buildMetricTile('↗️ Shares', '${clip.shares}', AppTheme.neonGreen),
        _buildMetricTile(
          '💰 Conversions',
          '${clip.conversions}',
          AppTheme.neonAmber,
        ),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementSection(ClipAnalytics clip) {
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
            'Engagement Metrics',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            'Engagement Ratio',
            '${(clip.engagementRatio * 100).toStringAsFixed(1)}%',
            AppTheme.neonCyan,
          ),
          const SizedBox(height: 8),
          _buildMetricRow(
            'Conversion Rate',
            '${clip.conversionRate.toStringAsFixed(2)}%',
            AppTheme.neonGreen,
          ),
          const SizedBox(height: 8),
          _buildMetricRow(
            'Trending Score',
            '${clip.trendingScore.toStringAsFixed(1)}/10',
            AppTheme.neonAmber,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildConversionFunnel(ClipAnalytics clip) {
    final views = clip.views.toDouble();
    final engagementRate = views > 0 ? (clip.likes + clip.shares) / views : 0;
    final conversionRate = (clip.likes + clip.shares) > 0
        ? clip.conversions / (clip.likes + clip.shares)
        : 0;

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
            'Conversion Funnel',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildFunnelStep('Views', views.toInt(), 1.0, AppTheme.neonCyan),
          const SizedBox(height: 8),
          _buildFunnelStep(
            'Engagement',
            (clip.likes + clip.shares),
            views > 0 ? engagementRate : 0,
            AppTheme.neonGreen,
          ),
          const SizedBox(height: 8),
          _buildFunnelStep(
            'Conversions',
            clip.conversions,
            (clip.likes + clip.shares) > 0 ? conversionRate : 0,
            AppTheme.neonRed,
          ),
        ],
      ),
    );
  }

  Widget _buildFunnelStep(String label, int count, double ratio, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              '$count (${(ratio * 100).toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceScore(ClipAnalytics clip) {
    // Calculate a composite score
    final engagementScore = clip.engagementRatio * 100;
    final conversionScore = clip.conversionRate * 10; // Normalize to 0-100
    final trendingScore = clip.trendingScore * 10; // Normalize to 0-100
    final overallScore =
        (engagementScore + conversionScore + trendingScore) / 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonAmber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Performance Score',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                Text(
                  overallScore.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neonAmber,
                  ),
                ),
                const Text(
                  'out of 100',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFightContext(ClipAnalytics clip) {
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
            'Fight Context',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (clip.fightId != null)
            Text(
              'Fight ID: ${clip.fightId}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          if (clip.eventId != null && clip.fightId != null)
            const SizedBox(height: 4),
          if (clip.eventId != null)
            Text(
              'Event ID: ${clip.eventId}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          if (clip.round != null && clip.fightId != null)
            const SizedBox(height: 4),
          if (clip.round != null)
            Text(
              'Round: ${clip.round}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
