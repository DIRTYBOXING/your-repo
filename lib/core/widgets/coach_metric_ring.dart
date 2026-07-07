import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Circular progress ring used on the Smart Coach dashboard to show a single
/// biometric/readiness metric as a percentage.
class CoachMetricRing extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;

  const CoachMetricRing({
    super.key,
    required this.label,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 84,
          height: 84,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: CircularProgressIndicator(
                  value: percentage.clamp(0.0, 1.0),
                  strokeWidth: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                '${(percentage * 100).round()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: DesignTokens.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
