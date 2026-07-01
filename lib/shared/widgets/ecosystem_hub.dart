import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class EcosystemHubNode {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? accentColor;

  const EcosystemHubNode({
    required this.label,
    required this.icon,
    required this.onTap,
    this.accentColor,
  });
}

class EcosystemHub extends StatelessWidget {
  final String centerLabel;
  final IconData centerIcon;
  final List<EcosystemHubNode> nodes;
  final double height;

  const EcosystemHub({
    super.key,
    required this.centerLabel,
    required this.centerIcon,
    required this.nodes,
    this.height = 250,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.surfaceColor),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;

            final size = Size(maxWidth, height);

            const nodeDiameter = 58.0;
            const centerDiameter = 86.0;

            final center = Offset(size.width / 2, size.height / 2);
            final radius =
                (math.min(size.width, size.height) / 2) -
                (nodeDiameter / 2) -
                6;

            final nodeCenters = <Offset>[];
            for (var i = 0; i < nodes.length; i++) {
              final angle = (-math.pi / 2) + (2 * math.pi * (i / nodes.length));
              nodeCenters.add(
                Offset(
                  center.dx + radius * math.cos(angle),
                  center.dy + radius * math.sin(angle),
                ),
              );
            }

            return SizedBox(
              height: height,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _HubLinksPainter(
                          center: center,
                          nodeCenters: nodeCenters,
                          nodeColors: nodes
                              .map((n) => n.accentColor ?? colorScheme.primary)
                              .toList(growable: false),
                          glow: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  // Center node
                  Positioned(
                    left: center.dx - centerDiameter / 2,
                    top: center.dy - centerDiameter / 2,
                    width: centerDiameter,
                    height: centerDiameter,
                    child: _HubCenterNode(label: centerLabel, icon: centerIcon),
                  ),
                  // Outer nodes
                  for (var i = 0; i < nodes.length; i++)
                    Positioned(
                      left: nodeCenters[i].dx - nodeDiameter / 2,
                      top: nodeCenters[i].dy - nodeDiameter / 2,
                      width: nodeDiameter,
                      height: nodeDiameter,
                      child: _HubOuterNode(
                        label: nodes[i].label,
                        icon: nodes[i].icon,
                        accentColor:
                            nodes[i].accentColor ?? colorScheme.primary,
                        onTap: nodes[i].onTap,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HubCenterNode extends StatelessWidget {
  final String label;
  final IconData icon;

  const _HubCenterNode({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.35),
            colorScheme.secondary.withValues(alpha: 0.20),
            AppTheme.cardBackground,
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colorScheme.primary, size: 26),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubOuterNode extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _HubOuterNode({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.secondaryBackground,
            shape: BoxShape.circle,
            border: Border.all(color: accentColor.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.14),
                blurRadius: 14,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: accentColor, size: 18),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
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

class _HubLinksPainter extends CustomPainter {
  final Offset center;
  final List<Offset> nodeCenters;
  final List<Color> nodeColors;
  final Color glow;

  _HubLinksPainter({
    required this.center,
    required this.nodeCenters,
    required this.nodeColors,
    required this.glow,
  }) : assert(nodeCenters.length == nodeColors.length);

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // Center pulse point
    final centerDot = Paint()..color = glow.withValues(alpha: 0.25);
    canvas.drawCircle(center, 2.2, centerDot);

    for (var i = 0; i < nodeCenters.length; i++) {
      final color = nodeColors[i];
      glowPaint.color = color.withValues(alpha: 0.12);
      base.color = color.withValues(alpha: 0.28);

      canvas.drawLine(center, nodeCenters[i], glowPaint);
      canvas.drawLine(center, nodeCenters[i], base);

      // Endpoint glow
      final endpointGlow = Paint()
        ..color = color.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      final endpoint = Paint()..color = color.withValues(alpha: 0.45);
      canvas.drawCircle(nodeCenters[i], 6, endpointGlow);
      canvas.drawCircle(nodeCenters[i], 2.8, endpoint);
    }
  }

  @override
  bool shouldRepaint(covariant _HubLinksPainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.nodeCenters != nodeCenters ||
        oldDelegate.nodeColors != nodeColors ||
        oldDelegate.glow != glow;
  }
}
