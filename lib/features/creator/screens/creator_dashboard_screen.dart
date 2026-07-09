import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/creator_dashboard_controller.dart';
import '../widgets/earnings_card_widget.dart';
import '../widgets/trending_clip_card_widget.dart';
import '../widgets/engagement_gauge_widget.dart';
import '../widgets/badge_progress_widget.dart';

/// Main Creator Dashboard Screen
/// Displays overview of earnings, clips, engagement, and badges
class CreatorDashboardScreen extends StatefulWidget {
  final String creatorId;

  const CreatorDashboardScreen({Key? key, required this.creatorId})
    : super(key: key);

  @override
  State<CreatorDashboardScreen> createState() => _CreatorDashboardScreenState();
}

class _CreatorDashboardScreenState extends State<CreatorDashboardScreen> {
  late CreatorDashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = context.read<CreatorDashboardController>();
    _controller.initializeDashboard(widget.creatorId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('Creator Dashboard'),
        backgroundColor: AppTheme.bgCard,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.refreshDashboard(widget.creatorId);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: Consumer<CreatorDashboardController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonCyan),
              ),
            );
          }

          if (controller.error != null) {
            return Center(
              child: Text(
                'Error: ${controller.error}',
                style: const TextStyle(color: AppTheme.textError),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Creator Profile Header
                if (controller.profile != null)
                  _buildProfileHeader(controller.profile!),

                const SizedBox(height: 24),

                // Key Metrics Section
                _buildKeyMetricsSection(controller),

                const SizedBox(height: 24),

                // Earnings Card
                if (controller.currentMonthEarnings != null)
                  EarningsCardWidget(
                    earnings: controller.currentMonthEarnings!,
                  ),

                const SizedBox(height: 24),

                // Engagement Gauge
                EngagementGaugeWidget(recentClips: controller.recentClips),

                const SizedBox(height: 24),

                // Trending Clips Section
                _buildTrendingClipsSection(controller),

                const SizedBox(height: 24),

                // Badge Progress Section
                BadgeProgressWidget(badgeProgress: controller.badgeProgress),

                const SizedBox(height: 24),

                // Insights Section
                if (controller.insights != null)
                  _buildInsightsSection(controller.insights!),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(dynamic profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Avatar
          if (profile.avatarUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.network(
                profile.avatarUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.neonCyan.withOpacity(0.2),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.person, color: AppTheme.neonCyan),
            ),
          const SizedBox(width: 16),
          // Profile Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      profile.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (profile.isVerified) const SizedBox(width: 8),
                    if (profile.isVerified)
                      const Icon(
                        Icons.verified,
                        color: AppTheme.neonCyan,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '🏆 Rank #${profile.rank}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.neonAmber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsSection(CreatorDashboardController controller) {
    final earnings = controller.currentMonthEarnings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Metrics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildMetricCard(
              '📊 Clips',
              '${controller.recentClips.length}',
              AppTheme.neonCyan,
            ),
            _buildMetricCard(
              '💰 This Month',
              '\$${earnings?.formattedEarnings() ?? "0"}',
              AppTheme.neonGreen,
            ),
            _buildMetricCard(
              '👥 Followers',
              '${controller.profile?.followerCount ?? 0}',
              AppTheme.neonRed,
            ),
            _buildMetricCard(
              '⭐ Trending',
              '${(controller.profile?.trendingScore ?? 0).toStringAsFixed(1)}/10',
              AppTheme.neonAmber,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
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
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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

  Widget _buildTrendingClipsSection(CreatorDashboardController controller) {
    final trendingClips = controller.recentClips
        .where((clip) => clip.isTrending)
        .take(3)
        .toList();

    if (trendingClips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trending Clips',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...trendingClips.map((clip) => TrendingClipCardWidget(clip: clip)),
      ],
    );
  }

  Widget _buildInsightsSection(dynamic insights) {
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
            'AI Insights',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...insights.recommendations
              .take(3)
              .map(
                (rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rec,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
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
}
