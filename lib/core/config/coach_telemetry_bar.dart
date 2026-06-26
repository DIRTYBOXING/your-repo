import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

class CoachTelemetryBar extends StatelessWidget {
  const CoachTelemetryBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TelemetryStat('CNS READINESS', '94%', DesignTokens.neonGreen),
          _TelemetryStat('MUSCLE STRAIN', 'MODERATE', DesignTokens.neonAmber),
          _TelemetryStat('HYDRATION', 'OPTIMAL', DesignTokens.neonCyan),
        ],
      ),
    );
  }
}

class _TelemetryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TelemetryStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: DesignTokens.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
