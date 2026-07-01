import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC MESSENGER — Offline Outbox Queue
///
/// Persists messages that could not be sent (device offline / Firestore
/// unavailable) to SharedPreferences as a JSON list.  On reconnect, call
/// [flush] to drain the queue through the provided send callback.
///
/// Design:
///   • Each item is a `Map<String, dynamic>` matching MessagingService.sendMessage params.
///   • clientId is stored for idempotent delivery — the server/Firestore writes
///     are already idempotent so re-sending a queued item is safe.
///   • Queue is bounded to [maxQueueSize] items to prevent unbounded growth.
/// ═══════════════════════════════════════════════════════════════════════════
class OutboxQueue {
  static const _key = 'dfc_msg_outbox';
  static const int maxQueueSize = 200;

  /// Add one message payload to the persistent queue.
  static Future<void> enqueue(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final List<dynamic> queue = raw != null ? jsonDecode(raw) : [];
    if (queue.length >= maxQueueSize) queue.removeAt(0); // oldest first
    queue.add(payload);
    await prefs.setString(_key, jsonEncode(queue));
  }

  /// Read all queued items without removing them.
  static Future<List<Map<String, dynamic>>> peek() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final List<dynamic> queue = jsonDecode(raw);
    return queue.cast<Map<String, dynamic>>();
  }

  /// Returns true if the queue has any items waiting to be sent.
  static Future<bool> hasPending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return false;
    final List<dynamic> queue = jsonDecode(raw);
    return queue.isNotEmpty;
  }

  /// Drain the queue: call [sendFn] for each item in order.
  /// Items are removed only after [sendFn] succeeds (throws = keep in queue).
  static Future<int> flush(
    Future<void> Function(Map<String, dynamic> payload) sendFn,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return 0;

    final List<dynamic> queue = jsonDecode(raw);
    if (queue.isEmpty) return 0;

    int sent = 0;
    final remaining = <dynamic>[];
    for (final item in queue) {
      try {
        await sendFn(Map<String, dynamic>.from(item as Map));
        sent++;
      } catch (_) {
        remaining.add(item); // keep failed items for next flush
      }
    }

    if (remaining.isEmpty) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, jsonEncode(remaining));
    }
    return sent;
  }

  /// Wipe the entire queue (e.g. on sign-out).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
