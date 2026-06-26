import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Login History Service — Track login events & active sessions
/// Like Facebook's "Where you're logged in" / "Login alerts"
/// Collection: login_history/{userId}/events/{docId}
/// Collection: active_sessions/{userId}/sessions/{sessionId}
/// ═══════════════════════════════════════════════════════════════════════════

class LoginEvent {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String method;       // 'email', 'google', 'facebook', 'apple'
  final String platform;     // 'web', 'android', 'ios', 'windows', 'macos'
  final String? ipAddress;
  final String? userAgent;
  final String? location;    // Approximate (city/country)
  final bool success;
  final String? failureReason;

  const LoginEvent({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.method,
    required this.platform,
    this.ipAddress,
    this.userAgent,
    this.location,
    this.success = true,
    this.failureReason,
  });

  factory LoginEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoginEvent(
      id: doc.id,
      userId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      method: data['method'] ?? 'unknown',
      platform: data['platform'] ?? 'unknown',
      ipAddress: data['ipAddress'],
      userAgent: data['userAgent'],
      location: data['location'],
      success: data['success'] ?? true,
      failureReason: data['failureReason'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'timestamp': FieldValue.serverTimestamp(),
    'method': method,
    'platform': platform,
    'ipAddress': ipAddress,
    'userAgent': userAgent,
    'location': location,
    'success': success,
    'failureReason': failureReason,
  };
}

class ActiveSession {
  final String id;
  final String userId;
  final String platform;
  final String? deviceName;
  final String? browser;
  final String? location;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final bool isCurrent;

  const ActiveSession({
    required this.id,
    required this.userId,
    required this.platform,
    this.deviceName,
    this.browser,
    this.location,
    required this.createdAt,
    required this.lastActiveAt,
    this.isCurrent = false,
  });

  factory ActiveSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActiveSession(
      id: doc.id,
      userId: data['userId'] ?? '',
      platform: data['platform'] ?? 'unknown',
      deviceName: data['deviceName'],
      browser: data['browser'],
      location: data['location'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActiveAt:
          (data['lastActiveAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'platform': platform,
    'deviceName': deviceName,
    'browser': browser,
    'location': location,
    'createdAt': FieldValue.serverTimestamp(),
    'lastActiveAt': FieldValue.serverTimestamp(),
  };
}

class LoginHistoryService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<LoginEvent> _events = [];
  List<LoginEvent> get events => _events;

  List<ActiveSession> _sessions = [];
  List<ActiveSession> get sessions => _sessions;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  // ═══════════════════════════════════════════════════════════════════════
  //  RECORD LOGIN
  // ═══════════════════════════════════════════════════════════════════════

  /// Record a login event. Call after successful/failed auth.
  Future<void> recordLogin({
    required String userId,
    required String method,
    required bool success,
    String? failureReason,
  }) async {
    try {
      final platform = _detectPlatform();

      await _db
          .collection('login_history')
          .doc(userId)
          .collection('events')
          .add({
            'userId': userId,
            'timestamp': FieldValue.serverTimestamp(),
            'method': method,
            'platform': platform,
            'success': success,
            'failureReason': failureReason,
          });

      // Trim old events — keep last 100
      final old = await _db
          .collection('login_history')
          .doc(userId)
          .collection('events')
          .orderBy('timestamp', descending: true)
          .limit(200)
          .get();

      if (old.docs.length > 100) {
        final batch = _db.batch();
        for (final doc in old.docs.skip(100)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // Update or create active session
      if (success) {
        await _upsertSession(userId, platform);
      }
    } catch (e) {
      debugPrint('LoginHistoryService: Failed to record login: $e');
    }
  }

  /// Record a logout event
  Future<void> recordLogout(String userId) async {
    try {
      final platform = _detectPlatform();

      await _db
          .collection('login_history')
          .doc(userId)
          .collection('events')
          .add({
            'userId': userId,
            'timestamp': FieldValue.serverTimestamp(),
            'method': 'logout',
            'platform': platform,
            'success': true,
          });

      // Remove current session
      await _removeSession(userId, platform);
    } catch (e) {
      debugPrint('LoginHistoryService: Failed to record logout: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  LOAD HISTORY
  // ═══════════════════════════════════════════════════════════════════════

  /// Load recent login events
  Future<void> loadHistory(String userId, {int limit = 50}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final snap = await _db
          .collection('login_history')
          .doc(userId)
          .collection('events')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      _events = snap.docs.map(LoginEvent.fromFirestore).toList();
    } catch (e) {
      _error = 'Failed to load login history: $e';
      debugPrint('LoginHistoryService: $_error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  ACTIVE SESSIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Load all active sessions ("Where you're logged in")
  Future<void> loadSessions(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final snap = await _db
          .collection('active_sessions')
          .doc(userId)
          .collection('sessions')
          .orderBy('lastActiveAt', descending: true)
          .limit(20)
          .get();

      final currentPlatform = _detectPlatform();
      _sessions = snap.docs.map((doc) {
        final session = ActiveSession.fromFirestore(doc);
        return ActiveSession(
          id: session.id,
          userId: session.userId,
          platform: session.platform,
          deviceName: session.deviceName,
          browser: session.browser,
          location: session.location,
          createdAt: session.createdAt,
          lastActiveAt: session.lastActiveAt,
          isCurrent: session.platform == currentPlatform,
        );
      }).toList();
    } catch (e) {
      _error = 'Failed to load sessions: $e';
      debugPrint('LoginHistoryService: $_error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// End a specific session (remote logout)
  Future<bool> endSession(String userId, String sessionId) async {
    try {
      await _db
          .collection('active_sessions')
          .doc(userId)
          .collection('sessions')
          .doc(sessionId)
          .delete();

      _sessions.removeWhere((s) => s.id == sessionId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to end session: $e';
      return false;
    }
  }

  /// End all sessions except current (like Facebook's "Log out of all sessions")
  Future<bool> endAllOtherSessions(String userId) async {
    try {
      final snap = await _db
          .collection('active_sessions')
          .doc(userId)
          .collection('sessions')
          .get();

      final currentPlatform = _detectPlatform();
      final batch = _db.batch();

      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['platform'] != currentPlatform) {
          batch.delete(doc.reference);
        }
      }

      await batch.commit();
      _sessions.removeWhere((s) => !s.isCurrent);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to end sessions: $e';
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  FAILED LOGIN DETECTION
  // ═══════════════════════════════════════════════════════════════════════

  /// Get count of recent failed logins (for security alerts)
  Future<int> getRecentFailedLogins(String userId, {int hours = 24}) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(hours: hours));
      final snap = await _db
          .collection('login_history')
          .doc(userId)
          .collection('events')
          .where('success', isEqualTo: false)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoff))
          .get();
      return snap.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  INTERNAL
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _upsertSession(String userId, String platform) async {
    try {
      // Use platform as doc ID so one session per platform
      final sessionRef = _db
          .collection('active_sessions')
          .doc(userId)
          .collection('sessions')
          .doc(platform);

      final existing = await sessionRef.get();
      if (existing.exists) {
        await sessionRef.update({
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
      } else {
        await sessionRef.set({
          'userId': userId,
          'platform': platform,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('LoginHistoryService: _upsertSession error: $e');
    }
  }

  Future<void> _removeSession(String userId, String platform) async {
    try {
      await _db
          .collection('active_sessions')
          .doc(userId)
          .collection('sessions')
          .doc(platform)
          .delete();
    } catch (_) {}
  }

  String _detectPlatform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'unknown';
    }
  }
}
