import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_tokens.dart';
// app_colors import removed — using design_tokens

/// ═══════════════════════════════════════════════════════════════════════════
/// FLOATING DFC ORB SYSTEM — Quick-action satellite menu
///
/// Main DFC orb floats with a Lissajous drift pattern.
/// Tap it → 5 satellite orbs fan out in an arc, each a shortcut button.
/// Tap a satellite → navigates to that screen and collapses.
/// Tap main orb again or anywhere → collapses.
/// Draggable. Each satellite has its own glow color.
/// ═══════════════════════════════════════════════════════════════════════════

/// Data model for a satellite quick-action button
class _SatelliteAction {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const _SatelliteAction({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });
}

class FloatingDFCOrb extends StatefulWidget {
  final double orbSize;

  const FloatingDFCOrb({super.key, this.orbSize = 48});

  @override
  State<FloatingDFCOrb> createState() => _FloatingDFCOrbState();
}

class _FloatingDFCOrbState extends State<FloatingDFCOrb>
    with TickerProviderStateMixin {
  // Drift animation
  late AnimationController _driftCtrl;
  // Glow pulse
  late AnimationController _glowCtrl;
  // Ring spin
  late AnimationController _ringCtrl;
  // Expand / collapse satellites
  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;

  bool _isExpanded = false;

  // Drag
  Offset? _dragOffset;
  bool _isDragging = false;

  // Quick-action satellites — 6 core shortcuts
  static const _actions = [
    _SatelliteAction(
      icon: Icons.psychology_alt,
      label: 'Coach',
      route: '/neural-coach',
      color: Color(0xFF00F5FF),
    ),
    _SatelliteAction(
      icon: Icons.analytics,
      label: 'Analytics',
      route: '/combat-analytics',
      color: Color(0xFF00FFF0),
    ),
    _SatelliteAction(
      icon: Icons.smart_toy,
      label: 'AI Brain',
      route: '/ai-brain',
      color: Color(0xFFFF00FF),
    ),
    _SatelliteAction(
      icon: Icons.fitness_center,
      label: 'Camp',
      route: '/fight-camp-tools',
      color: Color(0xFFFF9500),
    ),
    _SatelliteAction(
      icon: Icons.shield,
      label: 'Safety',
      route: '/fighter-safety',
      color: Color(0xFFFFD700),
    ),
    _SatelliteAction(
      icon: Icons.live_tv,
      label: 'IBC LIVE',
      route: '/ibc/live',
      color: Color(0xFFFF0040),
    ),
  ];

  @override
  void initState() {
    super.initState();

    _driftCtrl = AnimationController(
      duration: const Duration(seconds: 16),
      vsync: this,
    )..repeat();

    _glowCtrl = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _ringCtrl = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _expandCtrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnim = CurvedAnimation(
      parent: _expandCtrl,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _driftCtrl.dispose();
    _glowCtrl.dispose();
    _ringCtrl.dispose();
    _expandCtrl.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _expandCtrl.forward();
    } else {
      _expandCtrl.reverse();
    }
  }

  void _collapse() {
    if (_isExpanded) {
      setState(() => _isExpanded = false);
      _expandCtrl.reverse();
    }
  }

  void _navigateTo(String route) {
    _collapse();
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _driftCtrl,
        _glowCtrl,
        _ringCtrl,
        _expandAnim,
      ]),
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final maxH = constraints.maxHeight;

            // Guard: skip rendering when constraints are zero or infinite
            if (maxW <= widget.orbSize ||
                maxH <= widget.orbSize ||
                maxW.isInfinite ||
                maxH.isInfinite) {
              return const SizedBox.shrink();
            }

            // Lissajous drift (pause drift when expanded)
            final t = _driftCtrl.value * math.pi * 2;
            final driftScale =
                1.0 - _expandAnim.value; // stop drifting when open
            final driftX = math.sin(t) * (maxW * 0.10) * driftScale;
            final driftY = math.sin(t * 2) * (maxH * 0.05) * driftScale;

            // Base position: bottom-right
            final baseX = maxW - widget.orbSize - 24;
            final baseY = maxH - widget.orbSize - 90;

            final finalX = _isDragging ? _dragOffset!.dx : baseX + driftX;
            final finalY = _isDragging ? _dragOffset!.dy : baseY + driftY;

            final clampMaxX = (maxW - widget.orbSize).clamp(0.0, maxW);
            final clampMaxY = (maxH - widget.orbSize).clamp(0.0, maxH);
            final clampedX = finalX.clamp(0.0, clampMaxX);
            final clampedY = finalY.clamp(0.0, clampMaxY);

            return Stack(
              children: [
                // Dismiss overlay when expanded
                if (_isExpanded)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _collapse,
                      behavior: HitTestBehavior.translucent,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                    ),
                  ),

                // Satellite orbs (positioned relative to main orb)
                ..._buildSatellites(clampedX, clampedY, maxW, maxH),

                // Main DFC orb
                Positioned(
                  left: clampedX,
                  top: clampedY,
                  child: GestureDetector(
                    onTap: _toggleExpand,
                    onPanStart: (d) {
                      _collapse();
                      setState(() {
                        _isDragging = true;
                        _dragOffset = Offset(
                          d.globalPosition.dx - widget.orbSize / 2,
                          d.globalPosition.dy -
                              widget.orbSize / 2 -
                              MediaQuery.of(context).padding.top,
                        );
                      });
                    },
                    onPanUpdate: (d) {
                      setState(() {
                        _dragOffset = Offset(
                          d.globalPosition.dx - widget.orbSize / 2,
                          d.globalPosition.dy -
                              widget.orbSize / 2 -
                              MediaQuery.of(context).padding.top,
                        );
                      });
                    },
                    onPanEnd: (_) => setState(() => _isDragging = false),
                    child: _buildMainOrb(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── SATELLITE ORBS ──
  List<Widget> _buildSatellites(
    double orbX,
    double orbY,
    double maxW,
    double maxH,
  ) {
    // Fan out in an arc — direction adapts to screen position
    // If orb is bottom-right, fan upper-left. If bottom-left, fan upper-right, etc.
    final isRight = orbX > maxW / 2;
    final isBottom = orbY > maxH / 2;

    // Arc center angle (pointing away from nearest corner)
    double arcCenter;
    if (isRight && isBottom) {
      arcCenter = math.pi * 1.25; // upper-left
    } else if (!isRight && isBottom) {
      arcCenter = math.pi * 1.75; // upper-right
    } else if (isRight && !isBottom) {
      arcCenter = math.pi * 0.75; // lower-left
    } else {
      arcCenter = math.pi * 0.25; // lower-right
    }

    const arcSpread = math.pi * 0.85; // 153° total arc — roomy for 6 satellites
    final satelliteRadius = widget.orbSize * 2.0;
    final satSize = widget.orbSize * 0.7;

    return List.generate(_actions.length, (i) {
      final action = _actions[i];
      final fraction = _actions.length == 1
          ? 0.0
          : (i / (_actions.length - 1)) - 0.5; // -0.5 to 0.5
      final angle = arcCenter + fraction * arcSpread;

      final expandProgress = _expandAnim.value;
      final stagger = (expandProgress * (1.0 + i * 0.15)).clamp(0.0, 1.0);

      final dx = math.cos(angle) * satelliteRadius * stagger;
      final dy = math.sin(angle) * satelliteRadius * stagger;

      final satX = (orbX + widget.orbSize / 2 - satSize / 2 + dx).clamp(
        0.0,
        (maxW - satSize).clamp(0.0, maxW),
      );
      final satY = (orbY + widget.orbSize / 2 - satSize / 2 + dy).clamp(
        0.0,
        (maxH - satSize).clamp(0.0, maxH),
      );

      return Positioned(
        left: satX,
        top: satY,
        child: Opacity(
          opacity: stagger,
          child: Transform.scale(
            scale: stagger,
            child: _SatelliteOrb(
              size: satSize,
              action: action,
              glowPhase: _glowCtrl.value,
              onTap: () => _navigateTo(action.route),
            ),
          ),
        ),
      );
    });
  }

  // ── MAIN ORB ──
  Widget _buildMainOrb() {
    final glowPhase = _glowCtrl.value;
    final totalSize = widget.orbSize + 20; // room for glow

    return SizedBox(
      width: totalSize,
      height: totalSize,
      child: CustomPaint(
        painter: _OrbPainter(
          glowPhase: glowPhase,
          ringPhase: _ringCtrl.value,
          isExpanded: _isExpanded,
          expandProgress: _expandAnim.value,
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isExpanded
                ? Icon(
                    Icons.close,
                    key: const ValueKey('close'),
                    color: Colors.white.withValues(alpha: 0.8),
                    size: widget.orbSize * 0.35,
                  )
                : Text(
                    'DFC',
                    key: const ValueKey('dfc'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: widget.orbSize * 0.2,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: DesignTokens.neonCyan.withValues(
                            alpha: 0.6 + glowPhase * 0.4,
                          ),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SATELLITE ORB — Mini glowing button with icon + label
// ═════════════════════════════════════════════════════════════════════════════
class _SatelliteOrb extends StatelessWidget {
  final double size;
  final _SatelliteAction action;
  final double glowPhase;
  final VoidCallback onTap;

  const _SatelliteOrb({
    required this.size,
    required this.action,
    required this.glowPhase,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + 12,
        height: size + 20, // extra for label
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Orb
            SizedBox(
              width: size + 12,
              height: size + 12,
              child: CustomPaint(
                painter: _SatellitePainter(
                  color: action.color,
                  glowPhase: glowPhase,
                ),
                child: Center(
                  child: Icon(
                    action.icon,
                    color: action.color,
                    size: size * 0.45,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Label
            Text(
              action.label,
              style: TextStyle(
                color: action.color.withValues(alpha: 0.8),
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SATELLITE PAINTER — Small glowing sphere
// ═════════════════════════════════════════════════════════════════════════════
class _SatellitePainter extends CustomPainter {
  final Color color;
  final double glowPhase;

  _SatellitePainter({required this.color, required this.glowPhase});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Outer glow
    canvas.drawCircle(
      center,
      radius + 4 + glowPhase * 2,
      Paint()
        ..color = color.withValues(alpha: 0.15 + glowPhase * 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Glass fill
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 1.2,
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.04),
            const Color(0xFF0A1628).withValues(alpha: 0.85),
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    // Border
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.35 + glowPhase * 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _SatellitePainter old) =>
      old.glowPhase != glowPhase;
}

// ═════════════════════════════════════════════════════════════════════════════
// MAIN ORB PAINTER — Glowing sphere with hex + particle ring
// ═════════════════════════════════════════════════════════════════════════════
class _OrbPainter extends CustomPainter {
  final double glowPhase;
  final double ringPhase;
  final bool isExpanded;
  final double expandProgress;

  _OrbPainter({
    required this.glowPhase,
    required this.ringPhase,
    required this.isExpanded,
    required this.expandProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    _drawOuterGlow(canvas, center, radius);
    _drawGlassSphere(canvas, center, radius);
    _drawHexBorder(canvas, center, radius * 0.82);
    _drawParticleRing(canvas, center, radius);
  }

  void _drawOuterGlow(Canvas canvas, Offset center, double radius) {
    final glowRadius = radius + 4 + glowPhase * 5;
    final glowAlpha = 0.10 + glowPhase * 0.10;

    // Main cyan glow
    canvas.drawCircle(
      center,
      glowRadius,
      Paint()
        ..color = DesignTokens.neonCyan.withValues(alpha: glowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Magenta accent when expanded
    if (expandProgress > 0) {
      canvas.drawCircle(
        center,
        glowRadius * 1.1,
        Paint()
          ..color = const Color(
            0xFFFF00FF,
          ).withValues(alpha: 0.08 * expandProgress)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
    }
  }

  void _drawGlassSphere(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 1.2,
          colors: [
            Colors.white.withValues(alpha: 0.10),
            DesignTokens.neonCyan.withValues(alpha: 0.04),
            const Color(0xFF0A1628).withValues(alpha: 0.8),
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    // Specular highlight
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(-radius * 0.2, -radius * 0.25),
        width: radius * 0.5,
        height: radius * 0.25,
      ),
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(
                center: center + Offset(-radius * 0.2, -radius * 0.25),
                radius: radius * 0.25,
              ),
            ),
    );

    // Border
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = DesignTokens.neonCyan.withValues(
          alpha: 0.25 + glowPhase * 0.12,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawHexBorder(Canvas canvas, Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = DesignTokens.neonCyan.withValues(
          alpha: 0.10 + glowPhase * 0.06,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  void _drawParticleRing(Canvas canvas, Offset center, double radius) {
    const count = 6;
    final orbitR = radius + 2;

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * math.pi * 2 + ringPhase * math.pi * 2;
      final px = center.dx + math.cos(angle) * orbitR;
      final py = center.dy + math.sin(angle) * orbitR;

      final alpha = (0.25 + math.sin(angle + glowPhase * math.pi) * 0.35).clamp(
        0.0,
        1.0,
      );

      canvas.drawCircle(
        Offset(px, py),
        3,
        Paint()
          ..color = DesignTokens.neonCyan.withValues(alpha: alpha * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(
        Offset(px, py),
        1.0,
        Paint()..color = DesignTokens.neonCyan.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) =>
      old.glowPhase != glowPhase ||
      old.ringPhase != ringPhase ||
      old.expandProgress != expandProgress;
}
