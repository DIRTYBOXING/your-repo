import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SAKURA — The Silent Safety Ninja
///
/// Female-only overlay that appears once in the Wellness section to quietly
/// educate about the Guardian Mode safety button. Designed for women who may
/// be in domestic violence situations — discreet, fast, leaves no trace.
/// Appears, educates briefly, and vanishes like a ninja.
/// ═══════════════════════════════════════════════════════════════════════════
class SakuraSafetyOverlay extends StatefulWidget {
  final VoidCallback onDismissed;
  const SakuraSafetyOverlay({super.key, required this.onDismissed});

  @override
  State<SakuraSafetyOverlay> createState() => _SakuraSafetyOverlayState();
}

class _SakuraSafetyOverlayState extends State<SakuraSafetyOverlay>
    with TickerProviderStateMixin {
  // Master fade
  late AnimationController _masterFade;
  late Animation<double> _masterOpacity;

  // Sakura entrance
  late AnimationController _sakuraEntrance;
  late Animation<Offset> _sakuraSlide;
  late Animation<double> _sakuraScale;

  // Text cascade
  late AnimationController _textReveal;
  late Animation<double> _headlineOpacity;
  late Animation<double> _bodyOpacity;
  late Animation<double> _ctaOpacity;

  // Pink glow pulse
  late AnimationController _glowPulse;
  late Animation<double> _glowIntensity;

  // Exit
  late AnimationController _exitController;
  late Animation<double> _exitOpacity;
  late Animation<double> _exitScale;

  Timer? _autoDismiss;

  static const _sakuraPink = Color(0xFFFF69B4);
  static const _deepRose = Color(0xFFE91E63);
  static const _safeGreen = Color(0xFF00E676);

  @override
  void initState() {
    super.initState();

    _masterFade = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _masterOpacity = CurvedAnimation(
      parent: _masterFade,
      curve: Curves.easeOut,
    );

    _sakuraEntrance = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _sakuraSlide = Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _sakuraEntrance, curve: Curves.elasticOut),
        );
    _sakuraScale = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _sakuraEntrance, curve: Curves.elasticOut),
    );

    _textReveal = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _headlineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textReveal,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    _bodyOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textReveal,
        curve: const Interval(0.25, 0.6, curve: Curves.easeOut),
      ),
    );
    _ctaOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textReveal,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );

    _glowPulse = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _glowIntensity = Tween<double>(
      begin: 0.2,
      end: 0.6,
    ).animate(CurvedAnimation(parent: _glowPulse, curve: Curves.easeInOut));
    _glowPulse.repeat(reverse: true);

    _exitController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _exitOpacity = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeIn));
    _exitScale = Tween<double>(
      begin: 1.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeIn));

    _startSequence();
  }

  Future<void> _startSequence() async {
    if (!kIsWeb) HapticFeedback.lightImpact();

    _masterFade.forward();
    await Future.delayed(const Duration(milliseconds: 250));

    if (!kIsWeb) HapticFeedback.selectionClick();
    _sakuraEntrance.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    _textReveal.forward();

    // Auto-vanish after 10 seconds — the ninja disappears
    _autoDismiss = Timer(const Duration(seconds: 10), _sakuraVanish);
  }

  Future<void> _sakuraVanish() async {
    _autoDismiss?.cancel();
    if (!kIsWeb) HapticFeedback.lightImpact();
    await _exitController.forward();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _masterFade.dispose();
    _sakuraEntrance.dispose();
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
              onTap: _sakuraVanish,
              behavior: HitTestBehavior.opaque,
              child: Material(
                color: Colors.transparent,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Frosted backdrop
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        color: const Color(0xFF0A0008).withValues(alpha: 0.88),
                      ),
                    ),
                    // Pink safety glow
                    Center(
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _sakuraPink.withValues(
                                alpha: _glowIntensity.value * 0.4,
                              ),
                              blurRadius: 80,
                              spreadRadius: 20,
                            ),
                            BoxShadow(
                              color: _deepRose.withValues(
                                alpha: _glowIntensity.value * 0.2,
                              ),
                              blurRadius: 120,
                              spreadRadius: 40,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Content
                    SafeArea(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Sakura ninja icon
                              SlideTransition(
                                position: _sakuraSlide,
                                child: ScaleTransition(
                                  scale: _sakuraScale,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          _sakuraPink.withValues(alpha: 0.9),
                                          _deepRose.withValues(alpha: 0.9),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _sakuraPink.withValues(
                                            alpha: 0.5,
                                          ),
                                          blurRadius: 20,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '\u{1F338}',
                                        style: TextStyle(fontSize: 38),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Headline
                              FadeTransition(
                                opacity: _headlineOpacity,
                                child: Column(
                                  children: [
                                    const Text(
                                      'Sakura',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ShaderMask(
                                      shaderCallback: (bounds) =>
                                          const LinearGradient(
                                            colors: [_sakuraPink, _deepRose],
                                          ).createShader(bounds),
                                      child: const Text(
                                        'YOUR SILENT GUARDIAN',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 3.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Body message — discreet and empowering
                              FadeTransition(
                                opacity: _bodyOpacity,
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: Colors.white.withValues(alpha: 0.05),
                                    border: Border.all(
                                      color: _sakuraPink.withValues(
                                        alpha: 0.15,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.shield,
                                            color: _sakuraPink.withValues(
                                              alpha: 0.8,
                                            ),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          const Expanded(
                                            child: Text(
                                              'A hidden safety feature lives inside '
                                              'your Wellness section.',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                height: 1.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      const Text(
                                        'If you or someone you love is in a domestic '
                                        'situation, the Guardian Mode button connects '
                                        'you silently to help — no trace, no alerts '
                                        'on your screen. It looks like a wellness '
                                        'tracker. Only you know what it really does.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 13,
                                          height: 1.6,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          color: _safeGreen.withValues(
                                            alpha: 0.08,
                                          ),
                                          border: Border.all(
                                            color: _safeGreen.withValues(
                                              alpha: 0.2,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.security,
                                              color: _safeGreen.withValues(
                                                alpha: 0.8,
                                              ),
                                              size: 14,
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                'This ninja saves lives.',
                                                style: TextStyle(
                                                  color: _safeGreen.withValues(
                                                    alpha: 0.9,
                                                  ),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Feature pills
                              FadeTransition(
                                opacity: _ctaOpacity,
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _pill(
                                          '\u{1F6E1}\u{FE0F} Guardian Mode',
                                          _sakuraPink,
                                        ),
                                        const SizedBox(width: 8),
                                        _pill(
                                          '\u{1F49C} Silent SOS',
                                          _deepRose,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _pill(
                                          '\u{1F338} No Trace',
                                          AppTheme.neonCyan,
                                        ),
                                        const SizedBox(width: 8),
                                        _pill(
                                          '\u{2764}\u{FE0F} You Are Safe',
                                          _safeGreen,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Tap anywhere to continue',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                        fontSize: 11,
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

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
