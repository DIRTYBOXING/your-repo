import 'package:cloud_firestore/cloud_firestore.dart';

/// EngagementTrackerService — Real-time engagement logging to Firestore.
/// Tracks views, likes, shares, clicks, navigation events, and dwell time.
/// Collection: `engagement_events`
/// Powers the Engagement Dashboard with real analytics data.
class EngagementTrackerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'engagement_events';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _db.collection(_collection);

  // ── TRACK EVENTS ─────────────────────────────────────────────────

  /// Track a content view (article, event, profile, etc.)
  Future<void> trackView({
    required String contentId,
    required String contentType, // post, event, profile, news, screen
    String? userId,
    int durationMs = 0,
    String? source, // feed, search, share, direct
  }) async {
    await _ref.add({
      'event': 'view',
      'contentId': contentId,
      'contentType': contentType,
      'userId': userId ?? 'anonymous',
      'durationMs': durationMs,
      'source': source ?? 'direct',
      'timestamp': FieldValue.serverTimestamp(),
      'date': _dateKey(DateTime.now()),
      'hour': DateTime.now().hour,
    });
  }

  /// Track an engagement action (like, share, comment, save, repost)
  Future<void> trackEngagement({
    required String contentId,
    required String contentType,
    required String action, // like, share, comment, save, repost, click
    String? userId,
    String? platform, // instagram, facebook, twitter, etc.
    Map<String, dynamic>? extra,
  }) async {
    await _ref.add({
      'event': action,
      'contentId': contentId,
      'contentType': contentType,
      'userId': userId ?? 'anonymous',
      'platform': ?platform,
      ...?extra,
      'timestamp': FieldValue.serverTimestamp(),
      'date': _dateKey(DateTime.now()),
      'hour': DateTime.now().hour,
    });
  }

  /// Track a navigation event (screen transition)
  Future<void> trackNavigation({
    required String screenName,
    String? fromScreen,
    String? userId,
  }) async {
    await _ref.add({
      'event': 'navigation',
      'screenName': screenName,
      'fromScreen': fromScreen,
      'userId': userId ?? 'anonymous',
      'timestamp': FieldValue.serverTimestamp(),
      'date': _dateKey(DateTime.now()),
      'hour': DateTime.now().hour,
    });
  }

  /// Track a click (CTA, link, button)
  Future<void> trackClick({
    required String elementId,
    required String elementType, // button, link, card, cta
    String? contentId,
    String? userId,
    String? targetUrl,
  }) async {
    await _ref.add({
      'event': 'click',
      'elementId': elementId,
      'elementType': elementType,
      'contentId': contentId,
      'userId': userId ?? 'anonymous',
      'targetUrl': ?targetUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'date': _dateKey(DateTime.now()),
      'hour': DateTime.now().hour,
    });
  }

  // ── QUERIES ───────────────────────────────────────────────────────

  /// Get engagement events for a specific date
  Stream<List<Map<String, dynamic>>> streamByDate(
    String dateKey, {
    int limit = 200,
  }) {
    return _ref
        .where('date', isEqualTo: dateKey)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  /// Get top content by engagement count in a date range
  Future<Map<String, int>> getTopContent({
    required DateTime start,
    required DateTime end,
    int limit = 20,
  }) async {
    final startKey = _dateKey(start);
    final endKey = _dateKey(end);

    final snap = await _ref
        .where('date', isGreaterThanOrEqualTo: startKey)
        .where('date', isLessThanOrEqualTo: endKey)
        .where('event', whereIn: ['view', 'like', 'share', 'click'])
        .limit(5000)
        .get();

    final counts = <String, int>{};
    for (final doc in snap.docs) {
      final contentId = doc.data()['contentId'] as String?;
      if (contentId != null && contentId.isNotEmpty) {
        counts[contentId] = (counts[contentId] ?? 0) + 1;
      }
    }

    // Sort by count descending
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sorted.take(limit));
  }

  /// Get hourly engagement heatmap for a date
  Future<Map<int, int>> getHourlyHeatmap(String dateKey) async {
    final snap = await _ref.where('date', isEqualTo: dateKey).limit(5000).get();

    final heatmap = <int, int>{};
    for (int h = 0; h < 24; h++) {
      heatmap[h] = 0;
    }
    for (final doc in snap.docs) {
      final hour = doc.data()['hour'] as int? ?? 0;
      heatmap[hour] = (heatmap[hour] ?? 0) + 1;
    }
    return heatmap;
  }

  /// Get event type breakdown
  Future<Map<String, int>> getEventBreakdown({
    required DateTime start,
    required DateTime end,
  }) async {
    final startKey = _dateKey(start);
    final endKey = _dateKey(end);

    final snap = await _ref
        .where('date', isGreaterThanOrEqualTo: startKey)
        .where('date', isLessThanOrEqualTo: endKey)
        .limit(5000)
        .get();

    final breakdown = <String, int>{};
    for (final doc in snap.docs) {
      final event = doc.data()['event'] as String? ?? 'unknown';
      breakdown[event] = (breakdown[event] ?? 0) + 1;
    }
    return breakdown;
  }

  /// Get total event count for a date range
  Future<int> getTotalEvents({
    required DateTime start,
    required DateTime end,
  }) async {
    final startKey = _dateKey(start);
    final endKey = _dateKey(end);

    final snap = await _ref
        .where('date', isGreaterThanOrEqualTo: startKey)
        .where('date', isLessThanOrEqualTo: endKey)
        .count()
        .get();

    return snap.count ?? 0;
  }

  // ── HELPERS ───────────────────────────────────────────────────────

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String todayKey() => _dateKey(DateTime.now());
}
