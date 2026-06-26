import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DfcMotion {
  // For standard Navigator.push
  static PageRouteBuilder<T> slide<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final offsetAnim =
            Tween<Offset>(
              begin: const Offset(0.05, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutExpo),
            );

        final fadeAnim = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuad,
        );

        return FadeTransition(
          opacity: fadeAnim,
          child: SlideTransition(position: offsetAnim, child: child),
        );
      },
    );
  }

  // For GoRouter Shell transitions
  static CustomTransitionPage<T> slidePage<T>({
    required Widget child,
    LocalKey? key,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offsetAnim =
            Tween<Offset>(
              begin: const Offset(0.05, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutExpo),
            );

        final fadeAnim = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuad,
        );

        return FadeTransition(
          opacity: fadeAnim,
          child: SlideTransition(position: offsetAnim, child: child),
        );
      },
    );
  }

  static Widget fadeUpList(Widget child, Animation<double> animation) {
    final offsetAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    final fadeAnim = CurvedAnimation(parent: animation, curve: Curves.easeOut);

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(position: offsetAnim, child: child),
    );
  }
}
