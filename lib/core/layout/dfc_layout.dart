import 'package:flutter/material.dart';

/// Layout helpers for keeping DFC content readable on wide screens.
class DfcLayout {
  DfcLayout._();

  /// Constrain [child] to a maximum content width and centre it.
  static Widget constrain({required Widget child, double maxWidth = 720}) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
