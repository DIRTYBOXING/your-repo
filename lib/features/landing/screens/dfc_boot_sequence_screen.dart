import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_logos.dart';
import '../../../shared/services/auth_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC BOOT SEQUENCE — Cinematic System Initialization
///
/// A cyberpunk boot screen that plays once when the app first loads.
/// Hexagonal scan lines sweep across the hero image while terminal-style
/// system initialization text types out. Ends with a glitch reveal of the
/// full DFC logo and "SYSTEM ONLINE" before routing to the main app.
///
/// Sequence:
///  Phase 0 (0.0–0.15): Black screen → scan line sweep begins
///  Phase 1 (0.15–0.45): Terminal text types out initialization log
///  Phase 2 (0.45–0.65): Hero image fades in with radial glow
///  Phase 3 (0.65–0.80): Glitch flicker + "SYSTEM ONLINE" stamp
///  Phase 4 (0.80–1.0): Everything pulses bright → fade to route
/// ═══════════════════════════════════════════════════════════════════════════

class DfcBootSequenceScreen extends StatefulWidget {
  const DfcBootSequenceScreen({super.key});

  @override
  State<DfcBootSequenceScreen> createState() => _DfcBootSequenceScreenState();
}

class _DfcBootSequenceScreenState extends State<DfcBootSequenceScreen>
    with TickerProviderStateMixin {
  late AnimationController _masterCtrl;
  late AnimationController _scanCtrl;
  late AnimationController _glitchCtrl;
  late AnimationController _pulseCtrl;

  final _rng = math.Random();
  bool _showSystemOnline = false;
  bool _heroVisible = false;
  bool _routeTriggered = false;
  int _terminalLineIndex = 0;
  double _glitchOffset = 0;

  // Terminal boot log — the hacker vibes
  static const _bootLog = [
    '[DFC-CORE] Initializing neural combat network...',
    '[DFC-CORE] Loading fighter telemetry databases...',
    '[DFC-MAPS] Dark map overlay: ARMED',
    '[DFC-SHIELD] Pink Shield protocol: ACTIVE',
    '[DFC-FEED] Auto-feed orchestrator: ONLINE',
    '[DFC-AI] Shido Intelligence Engine v7.2: READY',
    '[DFC-ODDS] Betting odds aggregator: 12 sportsbooks synced',
    '[DFC-PPV] Pay-per-view grid: LOCKED',
    '[DFC-SAFETY] Guardian Mode SOS: STANDING BY',
    '[DFC-NET] Global gym network: 23 locations indexed',
    '[DFC-CRYPTO] Secure handshake: ████████ VERIFIED',
    '[SYSTEM] All subsystems nominal.',
    '[SYSTEM] >>> DATAFIGHT CENTRAL: ONLINE <<<',
  ];

  @override
  void initState() {
    super.initState();

    // Master timeline — drives the whole sequence
    _masterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6500),
    );

    // Scan lines sweep
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Glitch flicker
    _glitchCtrl =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 120),
        )..addListener(() {
          if (mounted) {
            setState(() {
              _glitchOffset = (_rng.nextDouble() - 0.5) * 8;
            });
          }
        });

    // Glow pulse
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _masterCtrl.addListener(_onMasterTick);
    _masterCtrl.forward();

    // Skip boot animation if already authenticated, or auto-enter as guest
    // when running on localhost / emulator so dev always sees the platform.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final auth = context.read<AuthService>();
        if (auth.isAuthenticated && !auth.needsOnboarding) {
          _routeTriggered = true;
          context.go('/home');
          return;
        }
        // Auto-guest on local dev so the platform is immediately visible
        final uri = Uri.base;
        final isLocal = uri.host == 'localhost' || uri.host == '127.0.0.1';
        if (isLocal && !auth.isAuthenticated) {
          auth.enableEmergencyLocalSession(
            emailHint: 'dev@datafightcentral.app',
          );
          _routeTriggered = true;
          context.go('/home');
        }
      } catch (_) {}
    });
  }

  void _onMasterTick() {
    final v = _masterCtrl.value;

    // Terminal text progression (phase 1: 0.10–0.50)
    if (v >= 0.10 && v <= 0.55) {
      final progress = ((v - 0.10) / 0.45).clamp(0.0, 1.0);
      final targetLine = (progress * _bootLog.length).floor();
      if (targetLine != _terminalLineIndex && mounted) {
        setState(() => _terminalLineIndex = targetLine);
      }
    } else if (v > 0.55 && _terminalLineIndex != _bootLog.length) {
      if (mounted) setState(() => _terminalLineIndex = _bootLog.length);
    }

    // Hero image reveal (phase 2: 0.45)
    if (v >= 0.45 && !_heroVisible) {
      if (mounted) setState(() => _heroVisible = true);
    }

    // Glitch phase (0.60–0.75)
    if (v >= 0.60 && v <= 0.75) {
      if (!_glitchCtrl.isAnimating) _glitchCtrl.repeat();
    } else if (v > 0.75 && _glitchCtrl.isAnimating) {
      _glitchCtrl.stop();
      if (mounted) setState(() => _glitchOffset = 0);
    }

    // SYSTEM ONLINE stamp (phase 3: 0.70)
    if (v >= 0.70 && !_showSystemOnline) {
      if (mounted) setState(() => _showSystemOnline = true);
    }

    // Route out (phase 4: 0.95)
    if (v >= 0.95 && !_routeTriggered) {
      _routeTriggered = true;
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        // On localhost auto-enter guest so dev sees the platform immediately
        final uri = Uri.base;
        final isLocal = uri.host == 'localhost' || uri.host == '127.0.0.1';
        if (isLocal) {
          try {
            final auth = context.read<AuthService>();
            if (!auth.isAuthenticated) {
              auth.enableEmergencyLocalSession(
                emailHint: 'dev@datafightcentral.app',
              );
            }
          } catch (_) {}
          context.go('/home');
        } else {
          context.go('/landing');
        }
      });
    }
  }

  @override
  void dispose() {
    _masterCtrl.dispose();
    _scanCtrl.dispose();
    _glitchCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // Tap to skip
        onTap: () {
          if (!_routeTriggered) {
            _routeTriggered = true;
            context.go('/landing');
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 0: Deep space background
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.2,
                  colors: [Color(0xFF0A1628), Color(0xFF020408)],
                ),
              ),
            ),

            // Layer 1: Scan lines
            AnimatedBuilder(
              animation: _scanCtrl,
              builder: (context, _) {
                return CustomPaint(
                  size: size,
                  painter: _ScanLinePainter(
                    progress: _scanCtrl.value,
                    intensity: _masterCtrl.value.clamp(0.0, 1.0),
                  ),
                );
              },
            ),

            // Layer 2: Hero image with glow reveal
            if (_heroVisible)
              AnimatedOpacity(
                opacity: _heroVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                child: Transform.translate(
                  offset: Offset(_glitchOffset, 0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Radial glow behind the image
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (context, _) {
                          return Container(
                            width: size.width * 0.8,
                            height: size.width * 0.5,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(200),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.neonCyan.withValues(
                                    alpha: 0.15 + _pulseCtrl.value * 0.1,
                                  ),
                                  blurRadius: 120 + _pulseCtrl.value * 40,
                                  spreadRadius: 40,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      // The actual hero image — DFC hex badge with cyan glow
                      Image.asset(
                        'assets/logos/DFC logo with cyan glow effect.png',
                        width: size.width * 0.65,
                        fit: BoxFit.contain,
                        errorBuilder: (_, e, s) => _fallbackHeroWidget(),
                      ),
                    ],
                  ),
                ),
              ),

            // Layer 3: Terminal boot log
            Positioned(
              left: 20,
              bottom: size.height * 0.12,
              right: 20,
              child: _buildTerminalLog(),
            ),

            // Layer 4: SYSTEM ONLINE stamp
            if (_showSystemOnline)
              Center(
                child: Transform.translate(
                  offset: Offset(0, size.height * 0.28),
                  child: _buildSystemOnlineStamp(),
                ),
              ),

            // Layer 5: Hex grid overlay (subtle)
            CustomPaint(
              size: size,
              painter: _HexGridPainter(
                opacity: (_masterCtrl.value * 0.12).clamp(0.0, 0.12),
              ),
            ),

            // Layer 6: Vignette
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  radius: 1.0,
                ),
              ),
            ),

            // Layer 7: Top-left DFC identifier
            Positioned(
              top: 40,
              left: 20,
              child: AnimatedOpacity(
                opacity: _masterCtrl.value > 0.05 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.neonCyan,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonCyan.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'DFC-CORE v7.2',
                      style: TextStyle(
                        color: AppColors.neonCyan.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Layer 8: Skip hint
            if (!_showSystemOnline)
              Positioned(
                bottom: 30,
                right: 20,
                child: AnimatedOpacity(
                  opacity: _masterCtrl.value > 0.15 ? 0.4 : 0.0,
                  duration: const Duration(milliseconds: 800),
                  child: const Text(
                    'TAP TO SKIP',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                      fontFamily: 'monospace',
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),

            // Final flash overlay
            if (_masterCtrl.value > 0.90)
              AnimatedOpacity(
                opacity: _masterCtrl.value > 0.92 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(color: Colors.black),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackHeroWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          AppLogos.icon,
          width: 120,
          height: 120,
          errorBuilder: (_, e, s) => const Icon(
            Icons.hexagon_outlined,
            size: 120,
            color: AppColors.neonCyan,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'DATAFIGHT\nCENTRAL',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 6,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildTerminalLog() {
    final visibleLines = _bootLog.sublist(
      0,
      _terminalLineIndex.clamp(0, _bootLog.length),
    );

    // Only show last 6 lines to keep it tight
    final displayLines = visibleLines.length > 6
        ? visibleLines.sublist(visibleLines.length - 6)
        : visibleLines;

    return AnimatedOpacity(
      opacity: _masterCtrl.value > 0.08 && _masterCtrl.value < 0.85 ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < displayLines.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  displayLines[i],
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    height: 1.4,
                    color:
                        displayLines[i].contains('ONLINE') ||
                            displayLines[i].contains('READY') ||
                            displayLines[i].contains('ACTIVE') ||
                            displayLines[i].contains('ARMED') ||
                            displayLines[i].contains('VERIFIED') ||
                            displayLines[i].contains('LOCKED')
                        ? AppColors.neonCyan
                        : displayLines[i].contains('>>>')
                        ? const Color(0xFF00FF88)
                        : Colors.white.withValues(alpha: 0.65),
                    fontWeight: displayLines[i].contains('>>>')
                        ? FontWeight.w900
                        : FontWeight.w400,
                  ),
                ),
              ),
            // Blinking cursor
            if (_terminalLineIndex < _bootLog.length)
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, child) => Opacity(
                  opacity: _pulseCtrl.value > 0.5 ? 1.0 : 0.0,
                  child: Container(
                    width: 7,
                    height: 12,
                    color: AppColors.neonCyan,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemOnlineStamp() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, child) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: const Color(
                    0xFF00FF88,
                  ).withValues(alpha: 0.6 + _pulseCtrl.value * 0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF00FF88,
                    ).withValues(alpha: 0.2 + _pulseCtrl.value * 0.15),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Text(
                '▶ SYSTEM ONLINE',
                style: TextStyle(
                  color: Color(0xFF00FF88),
                  fontSize: 16,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Animated horizontal scan lines that sweep down the screen
class _ScanLinePainter extends CustomPainter {
  final double progress;
  final double intensity;

  _ScanLinePainter({required this.progress, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity < 0.01) return;

    final paint = Paint()
      ..color = AppColors.neonCyan.withValues(alpha: 0.04 * intensity)
      ..strokeWidth = 1.0;

    // Horizontal scan lines
    const lineSpacing = 3.0;
    for (double y = 0; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Moving bright scan line
    final scanY = (progress * size.height * 1.3) % (size.height + 100) - 50;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          AppColors.neonCyan.withValues(alpha: 0.15 * intensity),
          AppColors.neonCyan.withValues(alpha: 0.3 * intensity),
          AppColors.neonCyan.withValues(alpha: 0.15 * intensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 30, size.width, 60));

    canvas.drawRect(Rect.fromLTWH(0, scanY - 30, size.width, 60), scanPaint);
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) =>
      progress != oldDelegate.progress || intensity != oldDelegate.intensity;
}

/// Subtle hexagonal grid overlay
class _HexGridPainter extends CustomPainter {
  final double opacity;

  _HexGridPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity < 0.005) return;

    final paint = Paint()
      ..color = AppColors.neonCyan.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const hexSize = 60.0;
    final hexWidth = hexSize * 1.732; // sqrt(3)
    final hexHeight = hexSize * 2;

    for (
      double row = -1;
      row * hexHeight * 0.75 < size.height + hexHeight;
      row++
    ) {
      for (double col = -1; col * hexWidth < size.width + hexWidth; col++) {
        final offsetX = (row.toInt() % 2 == 0) ? 0.0 : hexWidth / 2;
        final cx = col * hexWidth + offsetX;
        final cy = row * hexHeight * 0.75;

        _drawHex(canvas, cx, cy, hexSize * 0.95, paint);
      }
    }
  }

  void _drawHex(Canvas canvas, double cx, double cy, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 6;
      final x = cx + size * math.cos(angle);
      final y = cy + size * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HexGridPainter oldDelegate) =>
      opacity != oldDelegate.opacity;
}
