import 'dart:async';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PLATFORM HEALTH SERVICE — Self-Healing Internal Diagnostics
/// ═══════════════════════════════════════════════════════════════════════════
///
/// MANDATE: The platform is ALWAYS the first priority. Customers are live.
/// Every service call, feed load, and widget render is wrapped in self-heal
/// logic so the app never shows a blank screen or crashes to the user.
///
/// DESIGN:
/// • Type-safe feed filtering (never let mixed types crash a cast)
/// • Automatic retry with exponential backoff for transient failures
/// • Circuit breaker pattern: after N failures, skip the failing service
///   and serve cached/fallback data instead of blocking the UI
/// • Centralized error ledger for real-time internal diagnostics
/// • Zero user-facing errors — every failure degrades gracefully
///
/// ═══════════════════════════════════════════════════════════════════════════
class PlatformHealthService extends ChangeNotifier {
  PlatformHealthService._();
  static final PlatformHealthService instance = PlatformHealthService._();

  // ── Error Ledger ─────────────────────────────────────────────────────
  final List<_HealthEvent> _events = [];
  final Map<String, _CircuitState> _circuits = {};

  /// Public summary of recent health events for UI display.
  List<Map<String, String>> get recentEventSummaries => _events
      .take(200)
      .map(
        (e) => {
          'tag': e.tag,
          'message': e.message,
          'severity': e.severity.name,
          'time': e.timestamp.toIso8601String(),
        },
      )
      .toList();

  int get errorCount =>
      _events.where((e) => e.severity == _Severity.error).length;

  int get warnCount =>
      _events.where((e) => e.severity == _Severity.warn).length;

  int get healCount =>
      _events.where((e) => e.severity == _Severity.healed).length;

  bool get healthy => _circuits.values.every((c) => !c.open);

  /// Human-readable status string for UI health badges.
  String get statusLabel {
    if (healthy) return 'ALL SYSTEMS OPERATIONAL';
    final openCount = _circuits.values.where((c) => c.open).length;
    return '$openCount CIRCUIT(S) OPEN — DEGRADED';
  }

  // ── Self-Heal Wrapper ────────────────────────────────────────────────

  /// Execute [action] with automatic retry, circuit breaker, and fallback.
  /// [tag] identifies the subsystem (e.g. 'social_feed', 'dashboard_news').
  /// [fallback] is returned when all retries fail or the circuit is open.
  Future<T> guard<T>({
    required String tag,
    required Future<T> Function() action,
    required T fallback,
    int maxRetries = 2,
  }) async {
    final circuit = _circuits.putIfAbsent(tag, _CircuitState.new);

    // If circuit is open, serve fallback immediately (don't hammer a dead service).
    if (circuit.open) {
      _log(tag, 'Circuit open — serving fallback', _Severity.warn);
      // Attempt half-open probe every 60s.
      if (DateTime.now().difference(circuit.openedAt!).inSeconds > 60) {
        circuit.halfOpen = true;
      } else {
        return fallback;
      }
    }

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final result = await action();

        // Success — reset circuit.
        if (circuit.failures > 0 || circuit.halfOpen) {
          _log(
            tag,
            'Self-healed after ${circuit.failures} failure(s)',
            _Severity.healed,
          );
          circuit.reset();
        }
        return result;
      } catch (e, st) {
        circuit.failures++;
        _log(
          tag,
          'Attempt ${attempt + 1}/${maxRetries + 1} failed: $e',
          _Severity.error,
          st,
        );

        // Open circuit after 3 consecutive failures.
        if (circuit.failures >= 3) {
          circuit.open = true;
          circuit.openedAt = DateTime.now();
          _log(tag, 'CIRCUIT OPENED — too many failures', _Severity.error);
          return fallback;
        }

        // Exponential backoff before retry (200ms, 600ms).
        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 200 * (attempt + 1)));
        }
      }
    }

    return fallback;
  }

  /// Synchronous guard for widget builders — catches throw during build.
  T guardSync<T>({
    required String tag,
    required T Function() builder,
    required T fallback,
  }) {
    try {
      return builder();
    } catch (e, st) {
      _log(tag, 'Sync build error: $e', _Severity.error, st);
      return fallback;
    }
  }

  /// Type-safe list filter — replaces dangerous `.cast<T>()` calls.
  /// Filters a mixed `List<dynamic>` keeping only items of type [T].
  List<T> safeCast<T>(List<dynamic> items, {String tag = 'safeCast'}) {
    final safe = <T>[];
    for (final item in items) {
      if (item is T) {
        safe.add(item);
      } else {
        _log(
          tag,
          'Filtered out ${item.runtimeType} (expected $T)',
          _Severity.warn,
        );
      }
    }
    return safe;
  }

  /// Reset all circuits and clear event log (e.g. on user login).
  void resetAll() {
    _circuits.forEach((_, c) => c.reset());
    _events.clear();
    notifyListeners();
  }

  // ── Internal ─────────────────────────────────────────────────────────
  void _log(String tag, String message, _Severity severity, [StackTrace? st]) {
    final event = _HealthEvent(
      tag: tag,
      message: message,
      severity: severity,
      timestamp: DateTime.now(),
    );
    _events.insert(0, event);
    if (_events.length > 500) _events.removeLast();

    // Always print to console for debugging.
    final prefix = switch (severity) {
      _Severity.error => '❌',
      _Severity.warn => '⚠️',
      _Severity.healed => '✅',
      _Severity.info => 'ℹ️',
    };
    debugPrint('$prefix [PlatformHealth/$tag] $message');
    if (st != null && kDebugMode) {
      debugPrint(st.toString().split('\n').take(5).join('\n'));
    }
    notifyListeners();
  }
}

// ── Internal Models ──────────────────────────────────────────────────────
enum _Severity { error, warn, healed, info }

class _HealthEvent {
  final String tag;
  final String message;
  final _Severity severity;
  final DateTime timestamp;
  const _HealthEvent({
    required this.tag,
    required this.message,
    required this.severity,
    required this.timestamp,
  });
}

class _CircuitState {
  int failures = 0;
  bool open = false;
  bool halfOpen = false;
  DateTime? openedAt;
  void reset() {
    failures = 0;
    open = false;
    halfOpen = false;
    openedAt = null;
  }
}
