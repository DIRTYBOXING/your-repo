import 'package:flutter/material.dart';

// ── DFC Responsive Layout Helper ─────────────────────────────────────────────

class DfcResponsive {
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > 900;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width > 600 &&
      MediaQuery.of(context).size.width <= 900;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width <= 600;

  static double horizontalPadding(BuildContext context) {
    if (isDesktop(context)) return 120;
    if (isTablet(context)) return 48;
    return 20;
  }

  static int gridCrossAxisCount(
    BuildContext context, {
    int desktop = 3,
    int tablet = 2,
    int mobile = 1,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
}
