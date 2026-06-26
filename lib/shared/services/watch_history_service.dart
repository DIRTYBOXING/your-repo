import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A single watch entry — tracks what the user watched and where they stopped.
class WatchEntry {
  final String eventId;
  final String title;
  final String? thumbnailUrl;
  final Duration position;
  final Duration duration;
  final DateTime lastWatched;
  final bool completed;
  final String? sportType;
  final String? promotion;

  const WatchEntry({
    required this.eventId,
    required this.title,
    this.thumbnailUrl,
    required this.position,
    required this.duration,
    required this.lastWatched,
    this.completed = false,
    this.sportType,
    this.promotion,
  });

  double get progress =>
      duration.inSeconds > 0 ? position.inSeconds / duration.inSeconds : 0.0;

  bool get isResumable => !completed && progress > 0.02 && progress < 0.95;

  Map<String, dynamic> toMap() => {
    'eventId': eventId,
    'title': title,
    'thumbnailUrl': thumbnailUrl,
    'positionMs': position.inMilliseconds,
    'durationMs': duration.inMilliseconds,
    'lastWatched': Timestamp.fromDate(lastWatched),
    'completed': completed,
    'sportType': sportType,
    'promotion': promotion,
  };

  factory WatchEntry.fromMap(Map<String, dynamic> map) => WatchEntry(
    eventId: map['eventId'] ?? '',
    title: map['title'] ?? '',
    thumbnailUrl: map['thumbnailUrl'],
    position: Duration(milliseconds: map['positionMs'] ?? 0),
    duration: Duration(milliseconds: map['durationMs'] ?? 0),
    lastWatched: map['lastWatched'] is Timestamp
        ? (map['lastWatched'] as Timestamp).toDate()
        : DateTime.now(),
    completed: map['completed'] ?? false,
    sportType: map['sportType'],
    promotion: map['promotion'],
  );
}

/// Manages "Continue Watching" history — local-first with Firestore sync.
/// Every streaming platform has this. Now DFC does too.
class WatchHistoryService extends ChangeNotifier {
  static final WatchHistoryService _instance = WatchHistoryService._internal();
  factory WatchHistoryService() => _instance;
  WatchHistoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<WatchEntry> _history = [];
  bool _isLoaded = false;

  // ── Getters ───────────────────────────────────────────────────────────
  List<WatchEntry> get history => List.unmodifiable(_history);

  /// Only returns entries the user can resume (not completed, started watching).
  List<WatchEntry> get continueWatching =>
      _history.where((e) => e.isResumable).toList()
        ..sort((a, b) => b.lastWatched.compareTo(a.lastWatched));

  /// Recently completed (for "Watch Again" rail).
  List<WatchEntry> get recentlyWatched =>
      _history.where((e) => e.completed).toList()
        ..sort((a, b) => b.lastWatched.compareTo(a.lastWatched));

  bool get isLoaded => _isLoaded;

  // ── Init ──────────────────────────────────────────────────────────────

  /// Load history — local prefs first, then Firestore merge.
  Future<void> initialize() async {
    if (_isLoaded) return;

    // Load from local storage (instant)
    await _loadFromLocal();

    // Merge from Firestore (async, for cross-device sync)
    _loadFromFirestore();

    _isLoaded = true;
    notifyListeners();
  }

  // ── Record / Update ───────────────────────────────────────────────────

  /// Update watch position for an event. Called periodically during playback.
  Future<void> updateProgress({
    required String eventId,
    required String title,
    String? thumbnailUrl,
    required Duration position,
    required Duration duration,
    String? sportType,
    String? promotion,
  }) async {
    final isCompleted =
        duration.inSeconds > 0 &&
        position.inSeconds / duration.inSeconds > 0.95;

    final entry = WatchEntry(
      eventId: eventId,
      title: title,
      thumbnailUrl: thumbnailUrl,
      position: position,
      duration: duration,
      lastWatched: DateTime.now(),
      completed: isCompleted,
      sportType: sportType,
      promotion: promotion,
    );

    // Replace existing or add new
    _history.removeWhere((e) => e.eventId == eventId);
    _history.insert(0, entry);

    // Cap at 100 entries
    if (_history.length > 100) {
      _history.removeRange(100, _history.length);
    }

    notifyListeners();

    // Persist local + remote
    await _saveToLocal();
    _saveToFirestore(entry);
  }

  /// Mark event as completed.
  Future<void> markCompleted(String eventId) async {
    final idx = _history.indexWhere((e) => e.eventId == eventId);
    if (idx == -1) return;

    final old = _history[idx];
    final updated = WatchEntry(
      eventId: old.eventId,
      title: old.title,
      thumbnailUrl: old.thumbnailUrl,
      position: old.duration,
      duration: old.duration,
      lastWatched: DateTime.now(),
      completed: true,
      sportType: old.sportType,
      promotion: old.promotion,
    );

    _history[idx] = updated;
    notifyListeners();

    await _saveToLocal();
    _saveToFirestore(updated);
  }

  /// Remove an entry from history.
  Future<void> removeEntry(String eventId) async {
    _history.removeWhere((e) => e.eventId == eventId);
    notifyListeners();

    await _saveToLocal();
    _removeFromFirestore(eventId);
  }

  /// Clear all history.
  Future<void> clearAll() async {
    _history.clear();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('dfc_watch_history');
  }

  /// Get resume position for a specific event.
  Duration? getResumePosition(String eventId) {
    final entry = _history.where((e) => e.eventId == eventId).firstOrNull;
    if (entry == null || entry.completed) return null;
    return entry.position;
  }

  // ── Local Persistence ─────────────────────────────────────────────────

  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('dfc_watch_history') ?? [];
      // Each entry stored as pipe-delimited: eventId|title|posMs|durMs|timestamp|completed|thumb|sport|promo
      for (final line in raw) {
        final parts = line.split('|');
        if (parts.length < 6) continue;
        _history.add(
          WatchEntry(
            eventId: parts[0],
            title: parts[1],
            position: Duration(milliseconds: int.tryParse(parts[2]) ?? 0),
            duration: Duration(milliseconds: int.tryParse(parts[3]) ?? 0),
            lastWatched: DateTime.fromMillisecondsSinceEpoch(
              int.tryParse(parts[4]) ?? 0,
            ),
            completed: parts[5] == '1',
            thumbnailUrl: parts.length > 6 ? parts[6] : null,
            sportType: parts.length > 7 ? parts[7] : null,
            promotion: parts.length > 8 ? parts[8] : null,
          ),
        );
      }
    } catch (_) {
      // Graceful degradation — local storage optional
    }
  }

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lines = _history
          .take(50)
          .map(
            (e) =>
                '${e.eventId}|${e.title}|${e.position.inMilliseconds}|${e.duration.inMilliseconds}|${e.lastWatched.millisecondsSinceEpoch}|${e.completed ? 1 : 0}|${e.thumbnailUrl ?? ''}|${e.sportType ?? ''}|${e.promotion ?? ''}',
          )
          .toList();
      await prefs.setStringList('dfc_watch_history', lines);
    } catch (_) {}
  }

  // ── Firestore Sync ────────────────────────────────────────────────────

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  void _loadFromFirestore() {
    final uid = _userId;
    if (uid == null) return;

    _firestore
        .collection('users')
        .doc(uid)
        .collection('watch_history')
        .orderBy('lastWatched', descending: true)
        .limit(50)
        .get()
        .then((snap) {
          for (final doc in snap.docs) {
            final remote = WatchEntry.fromMap(doc.data());
            // Only add if not already present or if remote is newer
            final localIdx = _history.indexWhere(
              (e) => e.eventId == remote.eventId,
            );
            if (localIdx == -1) {
              _history.add(remote);
            } else if (remote.lastWatched.isAfter(
              _history[localIdx].lastWatched,
            )) {
              _history[localIdx] = remote;
            }
          }
          _history.sort((a, b) => b.lastWatched.compareTo(a.lastWatched));
          notifyListeners();
        })
        .catchError((_) {});
  }

  void _saveToFirestore(WatchEntry entry) {
    final uid = _userId;
    if (uid == null) return;

    _firestore
        .collection('users')
        .doc(uid)
        .collection('watch_history')
        .doc(entry.eventId)
        .set(entry.toMap(), SetOptions(merge: true))
        .catchError((_) {});
  }

  void _removeFromFirestore(String eventId) {
    final uid = _userId;
    if (uid == null) return;

    _firestore
        .collection('users')
        .doc(uid)
        .collection('watch_history')
        .doc(eventId)
        .delete()
        .catchError((_) {});
  }
}
