import 'package:flutter/material.dart';
import '../../core/theme/theme_controller.dart';

/// A circular orb-style action button with neon glow.
class DfcOrbActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  const DfcOrbActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeController.accent;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [c, c.withValues(alpha: 0.6)]),
          boxShadow: [
            BoxShadow(
              color: c.withValues(alpha: 0.3),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
