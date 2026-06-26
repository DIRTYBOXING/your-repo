/// Client-side playback quality metrics — buffer events, quality switches,
/// error rates, and session-level stats written to Firestore for monitoring.
///
/// Collects metrics during a streaming session and flushes them to
/// `stream_analytics/{sessionId}` on pause, quality change, error, or leave.
library;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// A single buffering event.
class BufferEvent {
  final DateTime start;
  final DateTime end;
  Duration get duration => end.difference(start);
  BufferEvent({required this.start, required this.end});
}

/// Session-level playback metrics.
class PlaybackSession {
  final String sessionId;
  final String eventId;
  final String userId;
  final DateTime startedAt;
  DateTime? endedAt;

  String currentQuality = 'auto';
  int qualitySwitches = 0;
  int bufferCount = 0;
  Duration totalBufferTime = Duration.zero;
  int errorCount = 0;
  String? lastError;
  Duration watchTime = Duration.zero;
  double avgBitrateKbps = 0;

  final List<BufferEvent> _bufferEvents = [];
  List<BufferEvent> get bufferEvents => List.unmodifiable(_bufferEvents);

  PlaybackSession({
    required this.sessionId,
    required this.eventId,
    required this.userId,
    required this.startedAt,
  });

  void addBuffer(BufferEvent e) {
    _bufferEvents.add(e);
    bufferCount++;
    totalBufferTime += e.duration;
  }

  Map<String, dynamic> toFirestore() => {
    'sessionId': sessionId,
    'eventId': eventId,
    'userId': userId,
    'startedAt': Timestamp.fromDate(startedAt),
    'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
    'currentQuality': currentQuality,
    'qualitySwitches': qualitySwitches,
    'bufferCount': bufferCount,
    'totalBufferMs': totalBufferTime.inMilliseconds,
    'errorCount': errorCount,
    'lastError': lastError,
    'watchTimeMs': watchTime.inMilliseconds,
    'avgBitrateKbps': avgBitrateKbps,
    'platform': defaultTargetPlatform.name,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class PlaybackAnalyticsService extends ChangeNotifier {
  PlaybackAnalyticsService._();
  static final PlaybackAnalyticsService _instance =
      PlaybackAnalyticsService._();
  factory PlaybackAnalyticsService() => _instance;

  final _firestore = FirebaseFirestore.instance;

  PlaybackSession? _session;
  DateTime? _bufferStart;
  DateTime? _watchStart;
  Timer? _flushTimer;

  PlaybackSession? get session => _session;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ── Session Lifecycle ─────────────────────────────────────────────────

  /// Start a new analytics session for [eventId].
  void startSession(String eventId) {
    final uid = _uid ?? 'anonymous';
    final sessionId =
        '${eventId}_${uid}_${DateTime.now().millisecondsSinceEpoch}';

    _session = PlaybackSession(
      sessionId: sessionId,
      eventId: eventId,
      userId: uid,
      startedAt: DateTime.now(),
    );

    _watchStart = DateTime.now();

    // Auto-flush every 30 s
    _flushTimer = Timer.periodic(const Duration(seconds: 30), (_) => flush());

    notifyListeners();
  }

  /// End the session and flush final metrics.
  Future<void> endSession() async {
    if (_session == null) return;

    _accumulateWatchTime();
    _session!.endedAt = DateTime.now();
    await flush();

    _flushTimer?.cancel();
    _flushTimer = null;
    _session = null;
    _bufferStart = null;
    _watchStart = null;
    notifyListeners();
  }

  // ── Event Reporters ───────────────────────────────────────────────────

  /// Call when buffering starts.
  void onBufferStart() {
    _bufferStart = DateTime.now();
  }

  /// Call when buffering ends (playback resumes).
  void onBufferEnd() {
    final start = _bufferStart;
    if (start == null || _session == null) return;

    _session!.addBuffer(BufferEvent(start: start, end: DateTime.now()));
    _bufferStart = null;
    notifyListeners();
  }

  /// Call when video quality changes.
  void onQualityChange(String newQuality) {
    if (_session == null) return;
    if (_session!.currentQuality != newQuality) {
      _session!.qualitySwitches++;
      _session!.currentQuality = newQuality;
      notifyListeners();
    }
  }

  /// Call when a playback error occurs.
  void onError(String errorMessage) {
    if (_session == null) return;
    _session!.errorCount++;
    _session!.lastError = errorMessage;
    notifyListeners();
  }

  /// Update average bitrate (from player metadata).
  void updateBitrate(double kbps) {
    if (_session == null) return;
    _session!.avgBitrateKbps = kbps;
  }

  // ── Flush to Firestore ────────────────────────────────────────────────

  /// Write current metrics to Firestore.
  Future<void> flush() async {
    final s = _session;
    if (s == null) return;

    _accumulateWatchTime();

    await _firestore
        .collection('stream_analytics')
        .doc(s.sessionId)
        .set(s.toFirestore(), SetOptions(merge: true))
        .catchError((_) {});
  }

  void _accumulateWatchTime() {
    final start = _watchStart;
    if (start == null || _session == null) return;
    _session!.watchTime += DateTime.now().difference(start);
    _watchStart = DateTime.now();
  }

  // ── Cleanup ───────────────────────────────────────────────────────────

  @override
  void dispose() {
    _flushTimer?.cancel();
    super.dispose();
  }
}
