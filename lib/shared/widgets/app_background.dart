import 'package:flutter/material.dart';
import '../../core/theme/theme_controller.dart';

/// A full-screen animated background that responds to fight camp theme changes.
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.mode,
      builder: (ctx, _) {
        return Container(
          decoration: BoxDecoration(gradient: ThemeController.gradient),
          child: Stack(
            children: [
              // subtle texture layers (images may be missing in repo)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.03,
                  child: Image.asset(
                    'assets/textures/octagon_tiles.png',
                    fit: BoxFit.cover,
                    errorBuilder: (c, o, s) => const SizedBox(),
                  ),
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0.06,
                  child: Image.asset(
                    'assets/textures/carbon_fiber.png',
                    fit: BoxFit.cover,
                    errorBuilder: (c, o, s) => const SizedBox(),
                  ),
                ),
              ),
              // glow fog overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topLeft,
                        radius: 1.2,
                        colors: [
                          ThemeController.accent.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // subtle noise
              Positioned.fill(
                child: Opacity(
                  opacity: 0.06,
                  child: Image.asset(
                    'assets/textures/noise.png',
                    fit: BoxFit.cover,
                    repeat: ImageRepeat.repeat,
                    errorBuilder: (c, o, s) => const SizedBox(),
                  ),
                ),
              ),
              // child content
              child,
            ],
          ),
        );
      },
    );
  }
}
