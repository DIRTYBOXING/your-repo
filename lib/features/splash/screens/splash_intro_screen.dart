import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/config/router_config.dart' as rc;
import '../../../shared/widgets/dfc_background.dart';
import '../../../shared/widgets/animated_dfc_logo.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SPLASH INTRO SCREEN — Cinematic DFC Entrance
/// Neon halo, shockwave ring, typewriter tagline, particle embers.
/// Intelligence is the new game of battle. The fight is won before a punch.
/// ═══════════════════════════════════════════════════════════════════════════

class SplashIntroScreen extends StatefulWidget {
  const SplashIntroScreen({super.key});

  @override
  State<SplashIntroScreen> createState() => _SplashIntroScreenState();
}

class _SplashIntroScreenState extends State<SplashIntroScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _ringCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _titleOpacity;
  late Animation<double> _taglineOpacity;
  late Animation<double> _ringExpand;
  late Animation<double> _ringFade;

  bool _navigated = false;

  static const _tagline =
      'Powered by Genie AI · The unstoppable promotional engine for combat sports.';

  @override
  void initState() {
    super.initState();

    // Master entry controller — 2.2s total sequence
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Logo: elastic scale in 0→800ms
    _logoScale = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.45, curve: ElasticOutCurve(0.6)),
    );

    // Title: fade in 600→1200ms
    _titleOpacity = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
    );

    // Tagline: fade in 900→1600ms
    _taglineOpacity = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.45, 0.8, curve: Curves.easeOut),
    );

    // Shockwave ring — fires once at 400ms
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _ringExpand = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut));
    _ringFade = Tween(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeIn));

    // Repeating pulse for neon halo
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Start the sequence
    _entryCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _ringCtrl.forward();
    });

    // Auto-navigate after 3s
    Future.delayed(const Duration(milliseconds: 3000), _goHome);
  }

  void _goHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.go(rc.RouterConfig.landingPath);
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: DFCBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Particle embers background
            CustomPaint(
              painter: _EmberPainter(repaint: _pulseCtrl),
              size: Size.infinite,
            ),

            // Main content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Neon halo + shockwave + logo
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsing neon halo
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (context, child) {
                            final pulse = _pulseCtrl.value;
                            return Container(
                              width: 170 + pulse * 10,
                              height: 170 + pulse * 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: DesignTokens.neonCyan.withValues(
                                      alpha: 0.15 + pulse * 0.12,
                                    ),
                                    blurRadius: 30 + pulse * 20,
                                    spreadRadius: 5 + pulse * 8,
                                  ),
                                  BoxShadow(
                                    color: DesignTokens.neonMagenta.withValues(
                                      alpha: 0.08 + pulse * 0.08,
                                    ),
                                    blurRadius: 50 + pulse * 15,
                                    spreadRadius: 2 + pulse * 5,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        // Shockwave ring
                        AnimatedBuilder(
                          animation: _ringCtrl,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _ShockwaveRingPainter(
                                expand: _ringExpand.value,
                                opacity: _ringFade.value,
                              ),
                              size: const Size(200, 200),
                            );
                          },
                        ),
                        // Logo with scale
                        ScaleTransition(
                          scale: _logoScale,
                          child: const AnimatedDfcLogo(size: 140, rotate: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title with shimmer
                  FadeTransition(
                    opacity: _titleOpacity,
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          colors: [
                            DesignTokens.neonCyan,
                            Colors.white,
                            DesignTokens.neonMagenta,
                            Colors.white,
                          ],
                          stops: [0.0, 0.3, 0.7, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcIn,
                      child: const Text(
                        'DATA FIGHT CENTRAL',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tagline fade-in
                  FadeTransition(
                    opacity: _taglineOpacity,
                    child: const Text(
                      _tagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white60,
                        letterSpacing: 0.5,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Powered-by line
                  FadeTransition(
                    opacity: _taglineOpacity,
                    child: const Text(
                      'DFC Pty Ltd  \u00B7  #1 Promotional Engine for Events & Fights',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white24,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Top-right skip button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 20,
              child: _SkipButton(onTap: _goHome),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shockwave ring that expands outward from center
// ═══════════════════════════════════════════════════════════════════════════════
class _ShockwaveRingPainter extends CustomPainter {
  final double expand;
  final double opacity;
  _ShockwaveRingPainter({required this.expand, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity < 0.01) return;
    final center = size.center(Offset.zero);
    final maxRadius = size.width * 0.8;
    final radius = expand * maxRadius;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * (1 - expand)
      ..color = DesignTokens.neonCyan.withValues(alpha: opacity * 0.6);
    canvas.drawCircle(center, radius, paint);
    // Second ring, slightly delayed
    if (expand > 0.15) {
      final inner = (expand - 0.15) * maxRadius;
      paint
        ..strokeWidth = 1.5 * (1 - expand)
        ..color = DesignTokens.neonMagenta.withValues(alpha: opacity * 0.3);
      canvas.drawCircle(center, inner, paint);
    }
  }

  @override
  bool shouldRepaint(_ShockwaveRingPainter old) =>
      old.expand != expand || old.opacity != opacity;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Floating ember particles
// ═══════════════════════════════════════════════════════════════════════════════
class _EmberPainter extends CustomPainter {
  _EmberPainter({required Listenable repaint}) : super(repaint: repaint);

  static final _embers = List.generate(35, (_) => _Ember());

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in _embers) {
      e.tick(size);
      final paint = Paint()
        ..color = e.color.withValues(alpha: e.alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(e.x, e.y), e.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _Ember {
  static final _rng = Random(42);
  double x = 0, y = 0, radius = 0, alpha = 0, speed = 0, drift = 0;
  Color color = DesignTokens.neonCyan;

  _Ember() {
    _randomize(const Size(400, 800), randomY: true);
  }

  void _randomize(Size size, {required bool randomY}) {
    x = _rng.nextDouble() * size.width;
    y = randomY ? _rng.nextDouble() * size.height : size.height + 10;
    radius = 1 + _rng.nextDouble() * 2.5;
    alpha = 0.1 + _rng.nextDouble() * 0.25;
    speed = 0.15 + _rng.nextDouble() * 0.5;
    drift = (_rng.nextDouble() - 0.5) * 0.4;
    color = [
      DesignTokens.neonCyan,
      DesignTokens.neonMagenta,
      DesignTokens.neonAmber,
      const Color(0xFFFF6B00),
    ][_rng.nextInt(4)];
  }

  void tick(Size size) {
    y -= speed;
    x += drift;
    alpha *= 0.998;
    if (y < -10 || alpha < 0.02) {
      _randomize(size, randomY: false);
    }
  }
}

class _SkipButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SkipButton({required this.onTap});

  @override
  State<_SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<_SkipButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: DesignTokens.animFast,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: _hovered ? 0.7 : 0.5),
            borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
            border: Border.all(
              color: AppTheme.textMuted.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Skip',
                style: TextStyle(
                  color: _hovered ? AppTheme.neonCyan : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.skip_next,
                color: _hovered ? AppTheme.neonCyan : AppTheme.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
