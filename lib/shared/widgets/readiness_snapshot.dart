import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// READINESS SNAPSHOT - Body readiness at a glance
/// Shows: HR, HRV, Sleep, Hydration, Stress, Overall Score
/// ═══════════════════════════════════════════════════════════════════════════
class ReadinessSnapshot extends StatelessWidget {
  final int restingHR;
  final int hrv;
  final int sleepQuality;
  final int hydration;
  final int stress;
  final int overallScore;

  const ReadinessSnapshot({
    super.key,
    this.restingHR = 62,
    this.hrv = 45,
    this.sleepQuality = 78,
    this.hydration = 85,
    this.stress = 35,
    this.overallScore = 82,
  });

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return AppTheme.neonCyan;
    if (score >= 40) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Body Readiness',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getScoreColor(overallScore).withValues(alpha: 0.3),
                      _getScoreColor(overallScore).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getScoreColor(overallScore).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite,
                      color: _getScoreColor(overallScore),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$overallScore%',
                      style: TextStyle(
                        color: _getScoreColor(overallScore),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Metrics Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Resting HR',
                  '$restingHR',
                  'bpm',
                  Icons.favorite_outline,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  'HRV',
                  '$hrv',
                  'ms',
                  Icons.show_chart,
                  AppTheme.neonCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Sleep',
                  '$sleepQuality',
                  '%',
                  Icons.bedtime_outlined,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  'Hydration',
                  '$hydration',
                  '%',
                  Icons.water_drop_outlined,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Stress Level',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    _getStressLabel(stress),
                    style: TextStyle(
                      color: _getStressColor(stress),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: stress / 100,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStressColor(stress),
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStressLabel(int stress) {
    if (stress < 30) return 'Low';
    if (stress < 60) return 'Moderate';
    if (stress < 80) return 'High';
    return 'Very High';
  }

  Color _getStressColor(int stress) {
    if (stress < 30) return Colors.green;
    if (stress < 60) return Colors.amber;
    if (stress < 80) return Colors.orange;
    return Colors.red;
  }
}
