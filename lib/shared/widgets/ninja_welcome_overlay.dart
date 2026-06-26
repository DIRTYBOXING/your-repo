import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// NINJA WELCOME OVERLAY — The DFC Ninja drops in, delivers the message,
/// and vanishes. Full-screen glassmorphism overlay with haptic feedback,
/// neon glow lighting effects, and auto-dismiss.
/// ═══════════════════════════════════════════════════════════════════════════
class NinjaWelcomeOverlay extends StatefulWidget {
  final VoidCallback onDismissed;
  const NinjaWelcomeOverlay({super.key, required this.onDismissed});

  @override
  State<NinjaWelcomeOverlay> createState() => _NinjaWelcomeOverlayState();
}

class _NinjaWelcomeOverlayState extends State<NinjaWelcomeOverlay>
    with TickerProviderStateMixin {
  // Master fade (entire overlay)
  late AnimationController _masterFade;
  late Animation<double> _masterOpacity;

  // Ninja entrance slide + scale
  late AnimationController _ninjaEntrance;
  late Animation<Offset> _ninjaSlide;
  late Animation<double> _ninjaScale;

  // Text reveal cascade
  late AnimationController _textReveal;
  late Animation<double> _headlineOpacity;
  late Animation<double> _bodyOpacity;
  late Animation<double> _ctaOpacity;

  // Neon pulse glow
  late AnimationController _glowPulse;
  late Animation<double> _glowIntensity;

  // Exit sequence
  late AnimationController _exitController;
  late Animation<double> _exitOpacity;
  late Animation<double> _exitScale;

  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();

    // ── Master fade-in ───────────────────────────────────────────────────
    _masterFade = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _masterOpacity = CurvedAnimation(
      parent: _masterFade,
      curve: Curves.easeOut,
    );

    // ── Ninja entrance — drops from above with elastic bounce ───────────
    _ninjaEntrance = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _ninjaSlide = Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _ninjaEntrance, curve: Curves.elasticOut),
        );
    _ninjaScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ninjaEntrance, curve: Curves.elasticOut),
    );

    // ── Text cascade reveal ─────────────────────────────────────────────
    _textReveal = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _headlineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textReveal,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );
    _bodyOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textReveal,
        curve: const Interval(0.3, 0.65, curve: Curves.easeOut),
      ),
    );
    _ctaOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textReveal,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    // ── Neon glow pulse ─────────────────────────────────────────────────
    _glowPulse = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );
    _glowIntensity = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _glowPulse, curve: Curves.easeInOut));
    _glowPulse.repeat(reverse: true);

    // ── Exit animation ──────────────────────────────────────────────────
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _exitOpacity = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeIn));
    _exitScale = Tween<double>(
      begin: 1.0,
      end: 0.6,
    ).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeIn));

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Haptic: arrival impact (skip on web — requires user gesture)
    if (!kIsWeb) HapticFeedback.mediumImpact();

    // Phase 1: Backdrop fade in
    _masterFade.forward();
    await Future.delayed(const Duration(milliseconds: 300));

    // Phase 2: Ninja drops in
    if (!kIsWeb) HapticFeedback.lightImpact();
    _ninjaEntrance.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    // Phase 3: Text cascade
    if (!kIsWeb) HapticFeedback.selectionClick();
    _textReveal.forward();

    // Auto-dismiss after 8 seconds (ninja vanishes)
    _autoDismiss = Timer(const Duration(seconds: 8), _ninjaVanish);
  }

  Future<void> _ninjaVanish() async {
    _autoDismiss?.cancel();
    // Haptic: departure (skip on web — may fire without user gesture)
    if (!kIsWeb) HapticFeedback.lightImpact();
    await _exitController.forward();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _masterFade.dispose();
    _ninjaEntrance.dispose();
    _textReveal.dispose();
    _glowPulse.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _masterOpacity,
        _exitOpacity,
        _exitScale,
        _glowIntensity,
      ]),
      builder: (context, _) {
        return Opacity(
          opacity: _masterOpacity.value * _exitOpacity.value,
          child: Transform.scale(
            scale: _exitScale.value,
            child: GestureDetector(
              onTap: _ninjaVanish,
              behavior: HitTestBehavior.opaque,
              child: Material(
                color: Colors.transparent,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // ── Frosted glass backdrop ───────────────────────────
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        color: const Color(0xFF050A14).withValues(alpha: 0.85),
                      ),
                    ),
                    // ── Neon glow ring (pulsing) ─────────────────────────
                    Center(
                      child: Container(
                        width: 340,
                        height: 340,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.neonCyan.withValues(
                                alpha: _glowIntensity.value * 0.5,
                              ),
                              blurRadius: 80,
                              spreadRadius: 20,
                            ),
                            BoxShadow(
                              color: AppTheme.neonPurple.withValues(
                                alpha: _glowIntensity.value * 0.3,
                              ),
                              blurRadius: 120,
                              spreadRadius: 40,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // ── Main content card ────────────────────────────────
                    SafeArea(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ── Ninja icon entrance ────────────────────
                              SlideTransition(
                                position: _ninjaSlide,
                                child: ScaleTransition(
                                  scale: _ninjaScale,
                                  child: Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.neonCyan.withValues(
                                            alpha: 0.9,
                                          ),
                                          AppTheme.neonPurple.withValues(
                                            alpha: 0.9,
                                          ),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.neonCyan.withValues(
                                            alpha: 0.5,
                                          ),
                                          blurRadius: 24,
                                          spreadRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '🥷',
                                        style: TextStyle(fontSize: 44),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // ── Headline ──────────────────────────────
                              FadeTransition(
                                opacity: _headlineOpacity,
                                child: const Text(
                                  'Welcome to DataFight Central',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              FadeTransition(
                                opacity: _headlineOpacity,
                                child: ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [
                                      AppTheme.neonCyan,
                                      AppTheme.neonPurple,
                                    ],
                                  ).createShader(bounds),
                                  child: const Text(
                                    'THE NINJA HAS ARRIVED',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 3.0,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ── Body message ──────────────────────────
                              FadeTransition(
                                opacity: _bodyOpacity,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.white.withValues(alpha: 0.06),
                                    border: Border.all(
                                      color: AppTheme.neonCyan.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: const Column(
                                    children: [
                                      Text(
                                        'Your front-row seat to live combat sports '
                                        'is officially active. Stream Pay-Per-View '
                                        'events, access world-class training content, '
                                        'and connect with the global fight community '
                                        '— all at prices that respect your corner.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                          height: 1.6,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Flexible payment options including Afterpay '
                                        'and PayPay are available so you never miss '
                                        'a fight when it matters most.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 13,
                                          height: 1.5,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ── CTA / closing ─────────────────────────
                              FadeTransition(
                                opacity: _ctaOpacity,
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _featurePill(
                                          '🎬 PPV',
                                          AppTheme.neonCyan,
                                        ),
                                        const SizedBox(width: 8),
                                        _featurePill(
                                          '🥊 Training',
                                          AppTheme.neonPurple,
                                        ),
                                        const SizedBox(width: 8),
                                        _featurePill(
                                          '💳 Afterpay',
                                          const Color(0xFF00FF88),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Welcome — and thank you for joining the movement.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppTheme.neonCyan.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Tap anywhere to continue',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.35,
                                        ),
                                        fontSize: 11,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _featurePill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
