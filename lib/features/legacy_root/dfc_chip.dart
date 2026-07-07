import 'package:flutter/material.dart';

class DfcChip extends StatelessWidget {
  final String label;
  final Color color;

  const DfcChip({
    super.key,
    required this.label,
    this.color = const Color(0xFF00E0FF), // Default Cyan
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: color,
        ),
      ),
    );
  }
}
