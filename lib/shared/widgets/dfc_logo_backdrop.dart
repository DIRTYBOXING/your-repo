import 'package:flutter/material.dart';
import '../../core/constants/app_logos.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC LOGO BACKDROP — Subtle watermark / hero badge for screen backgrounds.
///
/// Usage:
///   Stack(children: [ DfcLogoBackdrop(), ...yourContent ])
///   Stack(children: [ DfcLogoBackdrop.topRight(), ...content ])
///   Stack(children: [ DfcLogoBackdrop.hero(), ...content ])
/// ═══════════════════════════════════════════════════════════════════════════
class DfcLogoBackdrop extends StatelessWidget {
  /// How transparent the logo is (0 = invisible, 1 = full).
  final double opacity;

  /// Size of the logo image.
  final double size;

  /// Where to place it within the parent Stack.
  final Alignment alignment;

  /// Optional offset from the aligned position.
  final Offset offset;

  /// If true, applies a subtle blur-tint behind the logo for depth.
  final bool showGlow;

  /// Glow colour (defaults to neon cyan).
  final Color glowColor;

  const DfcLogoBackdrop({
    super.key,
    this.opacity = 0.06,
    this.size = 280,
    this.alignment = Alignment.center,
    this.offset = Offset.zero,
    this.showGlow = true,
    this.glowColor = const Color(0xFF00F5FF),
  });

  /// Centred watermark — very faint, large.
  const DfcLogoBackdrop.center({
    super.key,
    this.opacity = 0.05,
    this.size = 320,
    this.alignment = Alignment.center,
    this.offset = Offset.zero,
    this.showGlow = true,
    this.glowColor = const Color(0xFF00F5FF),
  });

  /// Top-right corner badge.
  const DfcLogoBackdrop.topRight({
    super.key,
    this.opacity = 0.045,
    this.size = 200,
    this.alignment = Alignment.topRight,
    this.offset = const Offset(40, -30),
    this.showGlow = false,
    this.glowColor = const Color(0xFF00F5FF),
  });

  /// Bottom-left corner badge.
  const DfcLogoBackdrop.bottomLeft({
    super.key,
    this.opacity = 0.04,
    this.size = 180,
    this.alignment = Alignment.bottomLeft,
    this.offset = const Offset(-30, 40),
    this.showGlow = false,
    this.glowColor = const Color(0xFF00F5FF),
  });

  /// Larger, slightly brighter hero behind a header area.
  const DfcLogoBackdrop.hero({
    super.key,
    this.opacity = 0.09,
    this.size = 360,
    this.alignment = Alignment.topCenter,
    this.offset = const Offset(0, -40),
    this.showGlow = true,
    this.glowColor = const Color(0xFF00F5FF),
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: alignment,
          child: Transform.translate(offset: offset, child: _logoImage()),
        ),
      ),
    );
  }

  Widget _logoImage() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Optional glow
        if (showGlow)
          Container(
            width: size * 0.5,
            height: size * 0.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: opacity * 2),
                  blurRadius: size * 0.35,
                  spreadRadius: size * 0.08,
                ),
              ],
            ),
          ),
        // Logo
        Opacity(
          opacity: opacity,
          child: Image.asset(
            AppLogos.icon,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
