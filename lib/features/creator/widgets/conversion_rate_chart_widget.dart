import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/clip_analytics_model.dart';

/// Conversion rate chart widget
/// Visualizes conversion trends across clips
class ConversionRateChartWidget extends StatelessWidget {
  final List<ClipAnalytics> clips;

  const ConversionRateChartWidget({Key? key, required this.clips})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (clips.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.neonGreen.withOpacity(0.2)),
        ),
        child: const Center(
          child: Text(
            'No conversion data yet',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ),
      );
    }

    // Sort clips by creation date (most recent first)
    final sortedClips = List<ClipAnalytics>.from(clips)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Take last 10 clips for chart
    final chartClips = sortedClips.take(10).toList();

    // Find min and max conversion rates
    final conversions = chartClips.map((c) => c.conversionRate).toList();
    final maxConversion = conversions.isEmpty
        ? 10.0
        : conversions.reduce((a, b) => a > b ? a : b);
    final minConversion = conversions.isEmpty
        ? 0.0
        : conversions.reduce((a, b) => a < b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Conversion Rate Trend',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Chart
          SizedBox(height: 150, child: _buildChart(chartClips, maxConversion)),
          const SizedBox(height: 16),
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatTile(
                'Avg',
                '${(conversions.reduce((a, b) => a + b) / conversions.length).toStringAsFixed(2)}%',
                AppTheme.neonCyan,
              ),
              _buildStatTile(
                'High',
                '${maxConversion.toStringAsFixed(2)}%',
                AppTheme.neonGreen,
              ),
              _buildStatTile(
                'Low',
                '${minConversion.toStringAsFixed(2)}%',
                AppTheme.neonAmber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<ClipAnalytics> clips, double maxConversion) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: clips.asMap().entries.map((entry) {
        final clip = entry.value;
        final normalizedHeight = (clip.conversionRate / maxConversion).clamp(
          0.0,
          1.0,
        );
        final barHeight = normalizedHeight * 120;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Tooltip
                Tooltip(
                  message:
                      '${clip.clipTitle}\n${clip.conversionRate.toStringAsFixed(2)}%',
                  child: Container(
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: AppTheme.neonGreen,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Label
                Text(
                  '${clip.conversionRate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 8,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
