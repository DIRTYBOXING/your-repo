import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Horizontal telemetry bar shown at the top of the Smart Coach dashboard.
/// Displays live biometric readouts sourced from connected wearables.
class CoachTelemetryBar extends StatelessWidget {
  const CoachTelemetryBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.15),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TelemetryStat(
            icon: Icons.favorite,
            label: 'RESTING HR',
            value: '48 bpm',
            color: DesignTokens.neonRed,
          ),
          _TelemetryStat(
            icon: Icons.monitor_heart,
            label: 'HRV',
            value: '72 ms',
            color: DesignTokens.neonGreen,
          ),
          _TelemetryStat(
            icon: Icons.bolt,
            label: 'READINESS',
            value: 'HIGH',
            color: DesignTokens.neonCyan,
          ),
        ],
      ),
    );
  }
}

class _TelemetryStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TelemetryStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: DesignTokens.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
