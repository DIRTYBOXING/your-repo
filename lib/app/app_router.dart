import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/config/router_config.dart' as legacy_router;

class AppRouter {
  AppRouter._();

  static GoRouter? _cachedRouter;

  /// Returns a singleton GoRouter, creating it only on the first call.
  /// GoRouter's own `refreshListenable` handles auth-state changes
  /// without needing a full router rebuild.
  static GoRouter getRouter(BuildContext context) {
    _cachedRouter ??= legacy_router.RouterConfig.getRouter(context);
    return _cachedRouter!;
  }

  /// Reset the cached router (call on sign-out to start fresh).
  static void reset() {
    _cachedRouter?.dispose();
    _cachedRouter = null;
  }
}
