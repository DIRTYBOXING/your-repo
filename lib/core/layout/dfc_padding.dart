import 'package:flutter/material.dart';

/// Standard horizontal screen padding wrapper for DFC screens.
class DfcPadding extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const DfcPadding({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(padding: padding, child: child);
  }
}
