import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/theme/design_tokens.dart';
import '../../../core/constants/image_assets.dart';
import '../../../shared/widgets/liquid_fire_overlay.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC HERO BANNER — Kayo Sports–style hero section
///
/// Full-width dramatic banner with real background image, gradient overlay,
/// centered headline text, and a CTA button.
/// ═══════════════════════════════════════════════════════════════════════════
class DFCHeroBanner extends StatelessWidget {
  final VoidCallback? onGetStarted;

  const DFCHeroBanner({super.key, this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;
    final isCompact = width < 380;

    return Container(
      width: double.infinity,
      height: isWide ? 360 : (isCompact ? 272 : 300),
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 4),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-bleed background image ──
          Image.asset(
            ImageAssets.bgHero,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, _, _) =>
                Container(color: const Color(0xFF0B1829)),
          ),

          // ── Dark gradient overlay for text readability ──
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.55),
                  const Color(0xFF050A14).withValues(alpha: 0.85),
                  const Color(0xFF050A14),
                ],
                stops: const [0.0, 0.4, 0.75, 1.0],
              ),
            ),
          ),

          // ── Liquid Fire ambience (subtle adrenaline glow) ──
          const Positioned.fill(
            child: LiquidFireOverlay(
              winProbability: 0.3,
              threshold: 0.1,
              child: SizedBox.expand(),
            ),
          ),

          // ── Neon accent glow behind text ──
          Positioned(
            top: isWide ? 40 : 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: isWide ? 500 : 360,
                height: isWide ? 200 : 160,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      DesignTokens.neonCyan.withValues(alpha: 0.10),
                      DesignTokens.neonMagenta.withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // ── Center content ──
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo badge — larger with glow ring
                  Container(
                    width: isWide ? 72 : 56,
                    height: isWide ? 72 : 56,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.35),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      ImageAssets.dfcLogoGlow,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.sports_mma,
                        color: DesignTokens.neonCyan,
                        size: isWide ? 48 : 36,
                      ),
                    ),
                  ),

                  // Headline
                  Text(
                    'Stream Partner Fights\nLive & On-Demand',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isWide ? 34 : (isCompact ? 22 : 26),
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.7),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // CTA button
                  GestureDetector(
                    onTap: onGetStarted,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [DesignTokens.neonCyan, Color(0xFF00C8CC)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: DesignTokens.neonCyan.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Explore Events',
                        style: TextStyle(
                          color: Color(0xFF050A14),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isCompact ? 10 : 14),

                  // Discipline chips
                  Text(
                    'MMA  •  Boxing  •  BKFC  •  Kickboxing  •  Muay Thai',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: isCompact ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom fade to feed background ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 40,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xFF050A14)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
