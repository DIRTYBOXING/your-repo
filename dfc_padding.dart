import 'package:flutter/material.dart';
import 'dfc_spacing.dart';

class DfcPadding extends StatelessWidget {
  final Widget child;
  const DfcPadding({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DfcSpacing.safeSide,
        vertical: DfcSpacing.md,
      ),
      child: child,
    );
  }
}
