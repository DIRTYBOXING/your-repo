import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/clip_analytics_model.dart';

/// Clip analytics card widget
/// Quick analytics summary for a single clip
class ClipAnalyticsCardWidget extends StatelessWidget {
  final ClipAnalytics clip;
  final VoidCallback? onTap;

  const ClipAnalyticsCardWidget({Key? key, required this.clip, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.neonCyan.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and trending badge
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
                          color: AppTheme.neonCyan.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          clip.clipType,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.neonCyan,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (clip.isTrending)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.neonRed.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text('🔥', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Key metrics row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricColumn('👁️', _formatNumber(clip.views), 'Views'),
                _buildMetricColumn('❤️', _formatNumber(clip.likes), 'Likes'),
                _buildMetricColumn('💰', '${clip.conversions}', 'Conv'),
                _buildMetricColumn(
                  '📈',
                  '${clip.trendingScore.toStringAsFixed(1)}',
                  'Score',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Conversion rate with bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Conversion',
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

            const SizedBox(height: 8),

            // Engagement ratio
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Engagement',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                Text(
                  '${(clip.engagementRatio * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neonCyan,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String emoji, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: AppTheme.textSecondary),
        ),
      ],
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
