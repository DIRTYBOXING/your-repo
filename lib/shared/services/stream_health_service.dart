/// Client-side listener for Mux stream health updates written by the
/// webhook Cloud Function to `mux_streams/{docId}`.
///
/// Exposes real-time stream status, health indicators, and VOD readiness
/// so the UI can show "Live", "Reconnecting", "VOD Ready", etc.
library;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ── Enums ───────────────────────────────────────────────────────────────

enum StreamStatus {
  unknown,
  idle,
  connected,
  active, // live and broadcasting
  disconnected,
  error,
}

enum VodStatus { none, processing, ready, errored }

// ── Health Model ────────────────────────────────────────────────────────

class StreamHealth {
  final StreamStatus status;
  final VodStatus vodStatus;
  final String? playbackId;
  final String? vodAssetId;
  final String? vodPlaybackId;
  final DateTime? lastUpdated;
  final int? viewerCount;
  final String? errorMessage;

  const StreamHealth({
    this.status = StreamStatus.unknown,
    this.vodStatus = VodStatus.none,
    this.playbackId,
    this.vodAssetId,
    this.vodPlaybackId,
    this.lastUpdated,
    this.viewerCount,
    this.errorMessage,
  });

  bool get isLive => status == StreamStatus.active;
  bool get isVodReady => vodStatus == VodStatus.ready;

  factory StreamHealth.fromFirestore(Map<String, dynamic> data) {
    return StreamHealth(
      status: _parseStreamStatus(data['status'] as String?),
      vodStatus: _parseVodStatus(data['vodStatus'] as String?),
      playbackId: data['playbackId'] as String?,
      vodAssetId: data['vodAssetId'] as String?,
      vodPlaybackId: data['vodPlaybackId'] as String?,
      lastUpdated: (data['updatedAt'] as Timestamp?)?.toDate(),
      viewerCount: data['viewerCount'] as int?,
      errorMessage: data['error'] as String?,
    );
  }

  static StreamStatus _parseStreamStatus(String? s) => switch (s) {
    'idle' => StreamStatus.idle,
    'connected' => StreamStatus.connected,
    'active' => StreamStatus.active,
    'disconnected' => StreamStatus.disconnected,
    'error' => StreamStatus.error,
    _ => StreamStatus.unknown,
  };

  static VodStatus _parseVodStatus(String? s) => switch (s) {
    'processing' => VodStatus.processing,
    'ready' => VodStatus.ready,
    'errored' => VodStatus.errored,
    _ => VodStatus.none,
  };
}

// ── Service ─────────────────────────────────────────────────────────────

class StreamHealthService extends ChangeNotifier {
  StreamHealthService._();
  static final StreamHealthService _instance = StreamHealthService._();
  factory StreamHealthService() => _instance;

  final _firestore = FirebaseFirestore.instance;

  StreamHealth _health = const StreamHealth();
  StreamSubscription<DocumentSnapshot>? _sub;
  String? _activeStreamDocId;

  StreamHealth get health => _health;
  bool get isLive => _health.isLive;
  bool get isVodReady => _health.isVodReady;

  // ── Watch a Stream ────────────────────────────────────────────────────

  /// Start listening to health updates for [streamDocId].
  void watch(String streamDocId) {
    if (_activeStreamDocId == streamDocId) return;

    stop();
    _activeStreamDocId = streamDocId;

    _sub = _firestore
        .collection('mux_streams')
        .doc(streamDocId)
        .snapshots()
        .listen((snap) {
          final data = snap.data();
          if (data != null) {
            _health = StreamHealth.fromFirestore(data);
          } else {
            _health = const StreamHealth();
          }
          notifyListeners();
        });
  }

  /// Stop listening.
  void stop() {
    _sub?.cancel();
    _sub = null;
    _activeStreamDocId = null;
    _health = const StreamHealth();
    notifyListeners();
  }

  // ── Query Helpers ─────────────────────────────────────────────────────

  /// Get stream health for [eventId] by querying mux_streams where
  /// the ppvEventId field matches.
  Future<StreamHealth?> getHealthForEvent(String eventId) async {
    final snap = await _firestore
        .collection('mux_streams')
        .where('ppvEventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return StreamHealth.fromFirestore(snap.docs.first.data());
  }

  /// Watch by PPV event ID (finds the stream doc, then watches it).
  Future<void> watchEvent(String eventId) async {
    final snap = await _firestore
        .collection('mux_streams')
        .where('ppvEventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      watch(snap.docs.first.id);
    }
  }

  // ── Cleanup ───────────────────────────────────────────────────────────

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
