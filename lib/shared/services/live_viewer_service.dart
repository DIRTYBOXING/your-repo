/// Real-time viewer count via Firestore presence — replaces simulated counts.
///
/// Each viewer writes a heartbeat doc to `ppv_events/{eventId}/viewers/{uid}`.
/// A Firestore snapshot listener on that subcollection gives the true count.
/// Stale heartbeats (>30 s) are pruned client-side on read; a Cloud Function
/// can do the same server-side for accuracy at scale.
library;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class LiveViewerService extends ChangeNotifier {
  LiveViewerService._();
  static final LiveViewerService _instance = LiveViewerService._();
  factory LiveViewerService() => _instance;

  final _firestore = FirebaseFirestore.instance;

  Future<String?> _resolvePpvDocumentId(String eventId) async {
    try {
      final directDoc = await _firestore
          .collection('ppv_events')
          .doc(eventId)
          .get();
      if (directDoc.exists) {
        return directDoc.id;
      }

      final eventIdSnapshot = await _firestore
          .collection('ppv_events')
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();
      if (eventIdSnapshot.docs.isNotEmpty) {
        return eventIdSnapshot.docs.first.id;
      }
    } catch (_) {}

    return null;
  }

  // ── State ─────────────────────────────────────────────────────────────

  String? _activeEventId;
  int _viewerCount = 0;
  Timer? _heartbeat;
  StreamSubscription<QuerySnapshot>? _countSub;

  int get viewerCount => _viewerCount;
  String? get activeEventId => _activeEventId;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _viewersCol(String eventId) =>
      _firestore.collection('ppv_events').doc(eventId).collection('viewers');

  // ── Join / Leave ──────────────────────────────────────────────────────

  /// Start tracking viewer presence for [eventId].
  Future<void> join(String eventId) async {
    // Clean up any previous session
    await leave();

    final resolvedEventId = await _resolvePpvDocumentId(eventId);
    if (resolvedEventId == null || resolvedEventId.isEmpty) {
      _viewerCount = 0;
      notifyListeners();
      return;
    }

    _activeEventId = resolvedEventId;
    final uid = _uid;
    if (uid == null) {
      // Anonymous — still listen to count but don't write presence
      _listenToCount(resolvedEventId);
      return;
    }

    // Write initial presence doc
    await _viewersCol(resolvedEventId).doc(uid).set({
      'uid': uid,
      'joinedAt': FieldValue.serverTimestamp(),
      'lastHeartbeat': FieldValue.serverTimestamp(),
      'platform': defaultTargetPlatform.name,
    });

    // Heartbeat every 15 s
    _heartbeat = Timer.periodic(const Duration(seconds: 15), (_) {
      _viewersCol(resolvedEventId)
          .doc(uid)
          .update({'lastHeartbeat': FieldValue.serverTimestamp()})
          .catchError((_) {});
    });

    _listenToCount(resolvedEventId);
  }

  /// Stop tracking — remove presence doc and cancel listeners.
  Future<void> leave() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    _countSub?.cancel();
    _countSub = null;

    final eventId = _activeEventId;
    final uid = _uid;
    if (eventId != null && uid != null) {
      await _viewersCol(eventId).doc(uid).delete().catchError((_) {});
    }

    _activeEventId = null;
    _viewerCount = 0;
    notifyListeners();
  }

  // ── Real-time Count ───────────────────────────────────────────────────

  void _listenToCount(String eventId) {
    // Listen to the viewers subcollection size
    _countSub = _viewersCol(eventId).snapshots().listen((snap) {
      // Only count docs with a heartbeat within the last 30 s
      final cutoff = DateTime.now().subtract(const Duration(seconds: 30));
      int alive = 0;
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final ts = data?['lastHeartbeat'] as Timestamp?;
        if (ts == null || ts.toDate().isAfter(cutoff)) {
          alive++;
        }
      }
      _viewerCount = alive;
      notifyListeners();
    });
  }

  // ── Cleanup ───────────────────────────────────────────────────────────

  @override
  void dispose() {
    _heartbeat?.cancel();
    _countSub?.cancel();
    super.dispose();
  }
}
