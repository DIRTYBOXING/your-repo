import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Metric Tile Widget
/// Compact display for individual health metrics (HR, HRV, SpO2, etc.)
class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color? color;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tileColor = color ?? AppTheme.neonCyan;

    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tileColor.withValues(alpha: 0.7), size: 18),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}
