import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC RESPONSIVE ENGINE
/// Seamlessly adapts the Combat OS shell across Mobile, Tablet, and Desktop web.
/// ═══════════════════════════════════════════════════════════════════════════
class DfcResponsive extends StatelessWidget {
  final Widget mobile;
  final Widget desktop;
  final Widget? tablet;

  const DfcResponsive({
    super.key,
    required this.mobile,
    required this.desktop,
    this.tablet,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 800;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 800 &&
      MediaQuery.of(context).size.width < 1200;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return desktop;
        } else if (constraints.maxWidth >= 800) {
          return tablet ?? desktop;
        } else {
          return mobile;
        }
      },
    );
  }
}
