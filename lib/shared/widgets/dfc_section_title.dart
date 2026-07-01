import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

/// Compact icon + title row for section headers.
class DfcSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final double iconSize;
  final double fontSize;
  final double letterSpacing;

  const DfcSectionTitle({
    super.key,
    required this.title,
    required this.icon,
    this.accent = DesignTokens.neonCyan,
    this.iconSize = 18,
    this.fontSize = 13,
    this.letterSpacing = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: accent, size: iconSize),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: letterSpacing,
          ),
        ),
      ],
    );
  }
}
