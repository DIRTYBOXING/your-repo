import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_logos.dart';
import '../../core/theme/theme_controller.dart';

class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({super.key});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _rotateController;
  late final AnimationController _entryController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _scaleEntry;
  late final Animation<double> _fadeEntry;

  @override
  void initState() {
    super.initState();

    // ENHANCED: Multi-layer pulsing glow for dramatic effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 20.0, end: 50.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Slow rotate on the hub icon
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Entry animation
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleEntry = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeEntry = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController,
        _rotateController,
        _entryController,
        ThemeController.mode, // Listen to theme changes
      ]),
      builder: (context, child) {
        final accent = ThemeController.accent;
        return FadeTransition(
          opacity: _fadeEntry,
          child: ScaleTransition(
            scale: _scaleEntry,
            child: SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // LAYER 1: Outer glow pulse (widest/softest)
                  Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(
                            alpha: _pulseAnimation.value * 0.35,
                          ),
                          blurRadius: _glowAnimation.value * 1.5,
                          spreadRadius: _glowAnimation.value * 0.5,
                        ),
                      ],
                    ),
                  ),
                  // LAYER 2: Mid glow pulse (medium blur)
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(
                            alpha: _pulseAnimation.value * 0.5,
                          ),
                          blurRadius: _glowAnimation.value * 0.8,
                          spreadRadius: _glowAnimation.value * 0.2,
                        ),
                      ],
                    ),
                  ),
                  // LAYER 3: Inner glow pulse (tight, bright)
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(
                            alpha: _pulseAnimation.value * 0.6,
                          ),
                          blurRadius: _glowAnimation.value * 0.4,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  // DFC Neon Logo - Layered for depth
                  // 1. Original Image for detail
                  Image.asset(
                    AppLogos.neon,
                    width: 135,
                    height: 135,
                    errorBuilder: (c, o, s) =>
                        Icon(Icons.sports_mma, size: 80, color: accent),
                  ),
                  // 2. Enhanced Glowing Layer (tinted pulse with blend mode)
                  Opacity(
                    opacity: _pulseAnimation.value * 0.7,
                    child: Image.asset(
                      AppLogos.neon,
                      width: 135,
                      height: 135,
                      color: accent,
                      colorBlendMode: BlendMode.screen,
                      errorBuilder: (c, o, s) => const SizedBox(),
                    ),
                  ),
                  // Rotating hub icon (futuristic tech element)
                  Transform.rotate(
                    angle: _rotateController.value * 2 * math.pi,
                    child: Icon(
                      Icons.hub,
                      size: 38,
                      color:
                          (Color.lerp(
                                    accent,
                                    AppColors.neonGreen,
                                    _pulseAnimation.value,
                                  ) ??
                                  accent)
                              .withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
