import 'dart:async';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC DEBOUNCER — Prevents Firestore hammering on rapid user input
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Usage:
///   final _debouncer = DFCDebouncer(milliseconds: 400);
///
///   TextField(onChanged: (val) {
///     _debouncer.run(() => _performSearch(val));
///   })
///
///   // Cancel on dispose:
///   _debouncer.cancel();
/// ═══════════════════════════════════════════════════════════════════════════

class DFCDebouncer {
  final int milliseconds;
  Timer? _timer;

  DFCDebouncer({this.milliseconds = 400});

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  bool get isActive => _timer?.isActive ?? false;
}

/// Throttler — ensures action runs at most once per interval
class DFCThrottler {
  final int milliseconds;
  DateTime? _lastRun;

  DFCThrottler({this.milliseconds = 1000});

  void run(void Function() action) {
    final now = DateTime.now();
    if (_lastRun == null ||
        now.difference(_lastRun!).inMilliseconds >= milliseconds) {
      _lastRun = now;
      action();
    }
  }
}
