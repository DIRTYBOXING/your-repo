import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/creator_earnings_model.dart';

/// Earnings summary card widget
/// Displays key earnings metrics at a glance
class EarningsCardWidget extends StatelessWidget {
  final CreatorEarnings earnings;

  const EarningsCardWidget({Key? key, required this.earnings})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonGreen.withOpacity(0.15),
            AppTheme.neonCyan.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'This Month\'s Earnings',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${earnings.month}/${earnings.year}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.neonGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '\$${earnings.formattedEarnings()}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.neonGreen,
            ),
          ),
          const SizedBox(height: 16),
          // Metrics Grid
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            children: [
              _buildMetric(
                'Clips',
                '${earnings.clipsGenerated}',
                AppTheme.neonCyan,
              ),
              _buildMetric(
                'Conversion',
                earnings.formattedConversionRate(),
                AppTheme.neonAmber,
              ),
              _buildMetric(
                'Total Views',
                _formatViews(earnings.totalViews),
                AppTheme.neonGreen,
              ),
              _buildMetric(
                'Avg/Clip',
                '\$${earnings.avgEarningsPerClip?.toStringAsFixed(2) ?? "0"}',
                AppTheme.neonRed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.bgCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }
}
