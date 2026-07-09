import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/clip_analytics_model.dart';

/// Trending clip card widget
/// Displays a summary of a trending clip
class TrendingClipCardWidget extends StatelessWidget {
  final ClipAnalytics clip;
  final VoidCallback? onTap;

  const TrendingClipCardWidget({Key? key, required this.clip, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.neonRed.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and type
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clip.clipTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.neonRed.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥 ', style: TextStyle(fontSize: 11)),
                            Text(
                              'TRENDING',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.neonRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Trending Score
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.neonAmber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      Text(
                        clip.trendingScore.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neonAmber,
                        ),
                      ),
                      Text(
                        '/10',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Metrics
            GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              children: [
                _buildMetric(
                  '👁️',
                  _formatNumber(clip.views),
                  'Views',
                  AppTheme.neonCyan,
                ),
                _buildMetric(
                  '❤️',
                  _formatNumber(clip.likes),
                  'Likes',
                  AppTheme.neonRed,
                ),
                _buildMetric(
                  '↗️',
                  _formatNumber(clip.shares),
                  'Shares',
                  AppTheme.neonGreen,
                ),
                _buildMetric(
                  '💰',
                  _formatNumber(clip.conversions),
                  'Conv',
                  AppTheme.neonAmber,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Conversion Rate Progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Conversion Rate',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '${clip.conversionRate.toStringAsFixed(2)}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neonGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (clip.conversionRate / 10).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: AppTheme.neonGreen.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.neonGreen,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String emoji, String value, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(fontSize: 8, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
