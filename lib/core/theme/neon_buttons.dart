import 'package:flutter/material.dart';

import 'glow_effects.dart';

class NeonGlowButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool small;

  const NeonGlowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.small = false
  });

  factory NeonGlowButton.small({required String label, required VoidCallback onPressed}) =>
      NeonGlowButton(label: label, onPressed: onPressed, small: true);

  @override
  Widget build(BuildContext context) {
    final padding = small ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6) : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF00F0FF), Color(0xFFEA00FF)]),
            borderRadius: BorderRadius.circular(8),
            boxShadow: NeonGlow.mediumCyan(),
          ),
          child: Text(label, style: textStyle),
        ),
      ),
    );
  }
}
