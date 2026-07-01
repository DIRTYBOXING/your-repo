import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'dfc_logo_backdrop.dart';

/// DFCBackground
///
/// Full-screen futuristic background using the neon hex / galaxy art
/// with the app's standard dark gradient overlay on top.
/// Now includes a subtle DFC logo watermark for branding.
class DFCBackground extends StatelessWidget {
  final Widget child;

  /// Set false to skip the logo watermark on this instance.
  final bool showLogo;

  const DFCBackground({super.key, required this.child, this.showLogo = true});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base image — DFC branded hex badge with cyan glow
        Container(
          color: const Color(0xFF030810),
          child: Center(
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                'assets/logos/DFC logo with cyan glow effect.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        // Dark neon gradient overlay for readability
        Container(decoration: const BoxDecoration(gradient: AppColors.bgGrad)),
        // DFC logo watermark
        if (showLogo) const DfcLogoBackdrop.center(),
        SafeArea(child: child),
      ],
    );
  }
}
