import 'package:flutter/material.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/constants/theme_mode.dart';
import '../../core/theme/app_colors.dart';

/// Badge showing current theme mode with accent color
class DfcModeBadge extends StatelessWidget {
  const DfcModeBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DfcThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: ThemeController.gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: ThemeController.accent.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            ThemeController.label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.bg,
              letterSpacing: 1,
            ),
          ),
        );
      },
    );
  }
}
