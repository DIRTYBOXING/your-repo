import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

// ═════════════════════════════════════════════════════════════════════════════
// DFC RIGHTS SERVICE — Global Rights & Entitlement Layer
// ═════════════════════════════════════════════════════════════════════════════
//
// Provides:
//   • Region-aware rights windows with allow/block lists
//   • Entitlement checks (time-window + geo enforcement)
//   • Playback token generation — stores SHA-256 hash ONLY (never raw token)
//   • Compliance event logging with takedown SLA tracking
//   • Anti-piracy: short-TTL, device-bound token concept
//
// Firestore Collections:
//   event_rights/{eventId}                      — rights configuration
//   playback_tokens/{tokenHash}                 — hash only, never raw
//   compliance_log/{eventId}/events/{docId}     — per-event audit trail
//
// ═════════════════════════════════════════════════════════════════════════════

// ── Enums ──────────────────────────────────────────────────────────────────

enum RightsStatus { active, expired, revoked, pending }

enum ComplianceEventType {
  tokenGenerated,
  tokenRevoked,
  entitlementGranted,
  entitlementDenied,
  takedownRequested,
  takedownCompleted,
  geoBlock,
  windowExpired,
  suspiciousActivity,
}

// ── Models ─────────────────────────────────────────────────────────────────

class EventRights {
  final String eventId;
  final List<String> allowedRegions; // ISO 3166-1 alpha-2, empty = allow all
  final List<String> blockedRegions;
  final DateTime windowStart;
  final DateTime windowEnd;
  final RightsStatus status;
  final String? promoterId;
  final DateTime updatedAt;

  const EventRights({
    required this.eventId,
    required this.allowedRegions,
    required this.blockedRegions,
    required this.windowStart,
    required this.windowEnd,
    required this.status,
    this.promoterId,
    required this.updatedAt,
  });

  bool get isActive => status == RightsStatus.active;

  bool isWindowOpen([DateTime? now]) {
    final t = now ?? DateTime.now().toUtc();
    return t.isAfter(windowStart) && t.isBefore(windowEnd);
  }

  bool isRegionAllowed(String region) {
    final r = region.toLowerCase();
    if (blockedRegions.map((e) => e.toLowerCase()).contains(r)) return false;
    if (allowedRegions.isEmpty) return true;
    return allowedRegions.map((e) => e.toLowerCase()).contains(r);
  }

  factory EventRights.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return EventRights(
      eventId: doc.id,
      allowedRegions: List<String>.from(d['allowedRegions'] ?? []),
      blockedRegions: List<String>.from(d['blockedRegions'] ?? []),
      windowStart: (d['windowStart'] as Timestamp).toDate(),
      windowEnd: (d['windowEnd'] as Timestamp).toDate(),
      status: RightsStatus.values.firstWhere(
        (s) => s.name == (d['status'] ?? 'active'),
        orElse: () => RightsStatus.active,
      ),
      promoterId: d['promoterId'],
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'allowedRegions': allowedRegions,
    'blockedRegions': blockedRegions,
    'windowStart': Timestamp.fromDate(windowStart),
    'windowEnd': Timestamp.fromDate(windowEnd),
    'status': status.name,
    'promoterId': promoterId,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class PlaybackTokenRecord {
  final String tokenHash; // SHA-256 of raw token — never store raw
  final String eventId;
  final String userId;
  final String region;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final bool revoked;

  const PlaybackTokenRecord({
    required this.tokenHash,
    required this.eventId,
    required this.userId,
    required this.region,
    required this.issuedAt,
    required this.expiresAt,
    this.revoked = false,
  });

  bool get isValid => !revoked && DateTime.now().toUtc().isBefore(expiresAt);

  factory PlaybackTokenRecord.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PlaybackTokenRecord(
      tokenHash: doc.id,
      eventId: d['eventId'] ?? '',
      userId: d['userId'] ?? '',
      region: d['region'] ?? '',
      issuedAt: (d['issuedAt'] as Timestamp).toDate(),
      expiresAt: (d['expiresAt'] as Timestamp).toDate(),
      revoked: d['revoked'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'eventId': eventId,
    'userId': userId,
    'region': region,
    'issuedAt': Timestamp.fromDate(issuedAt),
    'expiresAt': Timestamp.fromDate(expiresAt),
    'revoked': revoked,
  };
}

class ComplianceEvent {
  final String eventId;
  final ComplianceEventType type;
  final String? userId;
  final String? region;
  final String? detail;
  final DateTime timestamp;

  const ComplianceEvent({
    required this.eventId,
    required this.type,
    this.userId,
    this.region,
    this.detail,
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() => {
    'eventId': eventId,
    'type': type.name,
    'userId': userId,
    'region': region,
    'detail': detail,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}

class EntitlementResult {
  final bool allowed;
  final String reason;

  const EntitlementResult({required this.allowed, required this.reason});

  static const denied_geoBlock = EntitlementResult(
    allowed: false,
    reason: 'geo_block',
  );
  static const denied_windowClosed = EntitlementResult(
    allowed: false,
    reason: 'window_closed',
  );
  static const denied_revoked = EntitlementResult(
    allowed: false,
    reason: 'rights_revoked',
  );
  static const denied_notFound = EntitlementResult(
    allowed: false,
    reason: 'rights_not_found',
  );
  static const granted = EntitlementResult(
    allowed: true,
    reason: 'entitlement_granted',
  );
}

// ── Service ────────────────────────────────────────────────────────────────

class DfcRightsService extends ChangeNotifier {
  DfcRightsService._();
  static final DfcRightsService instance = DfcRightsService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _rightsCol = 'event_rights';
  static const String _tokensCol = 'playback_tokens';
  static const String _complianceCol = 'compliance_log';

  // Token TTL: 4 hours default — short-lived for anti-piracy
  static const Duration _defaultTokenTtl = Duration(hours: 4);

  // ── Rights Management ─────────────────────────────────────────────────

  /// Set or update rights for an event. Idempotent via merge.
  Future<void> setEventRights({
    required String eventId,
    required DateTime windowStart,
    required DateTime windowEnd,
    List<String> allowedRegions = const [],
    List<String> blockedRegions = const [],
    String? promoterId,
    RightsStatus status = RightsStatus.active,
  }) async {
    assert(eventId.isNotEmpty, 'eventId required');
    assert(
      windowEnd.isAfter(windowStart),
      'windowEnd must be after windowStart',
    );
    try {
      final rights = EventRights(
        eventId: eventId,
        allowedRegions: allowedRegions,
        blockedRegions: blockedRegions,
        windowStart: windowStart,
        windowEnd: windowEnd,
        status: status,
        promoterId: promoterId,
        updatedAt: DateTime.now().toUtc(),
      );
      await _db
          .collection(_rightsCol)
          .doc(eventId)
          .set(rights.toFirestore(), SetOptions(merge: true));
      notifyListeners();
    } catch (e) {
      debugPrint('[DfcRightsService] setEventRights error: $e');
      rethrow;
    }
  }

  /// Revoke rights for an event immediately.
  Future<void> revokeEventRights(String eventId, {String? reason}) async {
    try {
      await _db.collection(_rightsCol).doc(eventId).set({
        'status': RightsStatus.revoked.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await logComplianceEvent(
        eventId: eventId,
        type: ComplianceEventType.takedownRequested,
        detail: reason ?? 'rights_revoked',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('[DfcRightsService] revokeEventRights error: $e');
      rethrow;
    }
  }

  /// Fetch current rights for an event. Returns null if not found.
  Future<EventRights?> getEventRights(String eventId) async {
    try {
      final doc = await _db.collection(_rightsCol).doc(eventId).get();
      if (!doc.exists) return null;
      return EventRights.fromFirestore(doc);
    } catch (e) {
      debugPrint('[DfcRightsService] getEventRights error: $e');
      return null;
    }
  }

  Stream<EventRights?> streamEventRights(String eventId) {
    return _db
        .collection(_rightsCol)
        .doc(eventId)
        .snapshots()
        .map((doc) => doc.exists ? EventRights.fromFirestore(doc) : null)
        .handleError((e) {
          debugPrint('[DfcRightsService] streamEventRights error: $e');
          return null;
        });
  }

  // ── Entitlement Checks ────────────────────────────────────────────────

  /// Check if a user in a given region is entitled to view an event.
  Future<EntitlementResult> checkEntitlement(
    String eventId,
    String region,
  ) async {
    try {
      final rights = await getEventRights(eventId);
      if (rights == null) {
        await logComplianceEvent(
          eventId: eventId,
          type: ComplianceEventType.entitlementDenied,
          region: region,
          detail: 'rights_not_found',
        );
        return EntitlementResult.denied_notFound;
      }

      if (rights.status == RightsStatus.revoked) {
        await logComplianceEvent(
          eventId: eventId,
          type: ComplianceEventType.entitlementDenied,
          region: region,
          detail: 'rights_revoked',
        );
        return EntitlementResult.denied_revoked;
      }

      if (!rights.isWindowOpen()) {
        await logComplianceEvent(
          eventId: eventId,
          type: ComplianceEventType.windowExpired,
          region: region,
        );
        return EntitlementResult.denied_windowClosed;
      }

      if (!rights.isRegionAllowed(region)) {
        await logComplianceEvent(
          eventId: eventId,
          type: ComplianceEventType.geoBlock,
          region: region,
        );
        return EntitlementResult.denied_geoBlock;
      }

      await logComplianceEvent(
        eventId: eventId,
        type: ComplianceEventType.entitlementGranted,
        region: region,
      );
      return EntitlementResult.granted;
    } catch (e) {
      debugPrint('[DfcRightsService] checkEntitlement error: $e');
      return EntitlementResult.denied_notFound;
    }
  }

  // ── Playback Tokens ───────────────────────────────────────────────────

  /// Generate a short-TTL playback token. Returns the raw token to the caller
  /// once; only a SHA-256 hash is persisted in Firestore.
  Future<String?> generatePlaybackToken({
    required String eventId,
    required String userId,
    required String region,
    Duration ttl = _defaultTokenTtl,
  }) async {
    try {
      // Verify entitlement before issuing token
      final entitlement = await checkEntitlement(eventId, region);
      if (!entitlement.allowed) {
        debugPrint('[DfcRightsService] token denied: ${entitlement.reason}');
        return null;
      }

      final now = DateTime.now().toUtc();
      final expiresAt = now.add(ttl);

      // Build raw token — never stored
      final rawToken =
          '${eventId}_${userId}_${region}_${now.millisecondsSinceEpoch}';
      final tokenHash = sha256.convert(utf8.encode(rawToken)).toString();

      final record = PlaybackTokenRecord(
        tokenHash: tokenHash,
        eventId: eventId,
        userId: userId,
        region: region,
        issuedAt: now,
        expiresAt: expiresAt,
      );

      // Store only the hash
      await _db
          .collection(_tokensCol)
          .doc(tokenHash)
          .set(record.toFirestore(), SetOptions(merge: true));

      await logComplianceEvent(
        eventId: eventId,
        type: ComplianceEventType.tokenGenerated,
        userId: userId,
        region: region,
        detail: 'ttl=${ttl.inMinutes}m',
      );

      return rawToken;
    } catch (e) {
      debugPrint('[DfcRightsService] generatePlaybackToken error: $e');
      return null;
    }
  }

  /// Validate a raw token by hashing and checking Firestore record.
  Future<bool> validatePlaybackToken(String rawToken) async {
    try {
      final tokenHash = sha256.convert(utf8.encode(rawToken)).toString();
      final doc = await _db.collection(_tokensCol).doc(tokenHash).get();
      if (!doc.exists) return false;
      final record = PlaybackTokenRecord.fromFirestore(doc);
      return record.isValid;
    } catch (e) {
      debugPrint('[DfcRightsService] validatePlaybackToken error: $e');
      return false;
    }
  }

  /// Revoke a specific token by its hash.
  Future<void> revokeToken(String tokenHash, {String? eventId}) async {
    try {
      await _db.collection(_tokensCol).doc(tokenHash).set({
        'revoked': true,
      }, SetOptions(merge: true));
      if (eventId != null) {
        await logComplianceEvent(
          eventId: eventId,
          type: ComplianceEventType.tokenRevoked,
          detail: tokenHash.substring(0, 8), // partial hash for log only
        );
      }
    } catch (e) {
      debugPrint('[DfcRightsService] revokeToken error: $e');
    }
  }

  // ── Compliance Logging ────────────────────────────────────────────────

  /// Append an immutable compliance event to the event's audit trail.
  Future<void> logComplianceEvent({
    required String eventId,
    required ComplianceEventType type,
    String? userId,
    String? region,
    String? detail,
  }) async {
    try {
      final event = ComplianceEvent(
        eventId: eventId,
        type: type,
        userId: userId,
        region: region,
        detail: detail,
        timestamp: DateTime.now().toUtc(),
      );
      await _db
          .collection(_complianceCol)
          .doc(eventId)
          .collection('events')
          .add(event.toFirestore());
    } catch (e) {
      // Compliance logging must never crash the caller
      debugPrint('[DfcRightsService] logComplianceEvent error: $e');
    }
  }

  Stream<List<ComplianceEvent>> streamComplianceLog(String eventId) {
    return _db
        .collection(_complianceCol)
        .doc(eventId)
        .collection('events')
        .orderBy('timestamp', descending: true)
        .limit(200)
        .snapshots()
        .map(
          (s) => s.docs.map((doc) {
            final d = doc.data();
            return ComplianceEvent(
              eventId: d['eventId'] ?? eventId,
              type: ComplianceEventType.values.firstWhere(
                (t) => t.name == (d['type'] ?? ''),
                orElse: () => ComplianceEventType.suspiciousActivity,
              ),
              userId: d['userId'],
              region: d['region'],
              detail: d['detail'],
              timestamp: (d['timestamp'] as Timestamp).toDate(),
            );
          }).toList(),
        )
        .handleError((e) {
          debugPrint('[DfcRightsService] streamComplianceLog error: $e');
          return <ComplianceEvent>[];
        });
  }

  // ── Demo Data ─────────────────────────────────────────────────────────

  List<EventRights> get demoRights => [
    EventRights(
      eventId: 'demo_event_001',
      allowedRegions: ['au', 'nz', 'us', 'gb'],
      blockedRegions: [],
      windowStart: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
      windowEnd: DateTime.now().toUtc().add(const Duration(hours: 5)),
      status: RightsStatus.active,
      promoterId: 'promoter_001',
      updatedAt: DateTime.now().toUtc(),
    ),
    EventRights(
      eventId: 'demo_event_002',
      allowedRegions: [],
      blockedRegions: ['cn', 'ru'],
      windowStart: DateTime.now().toUtc().add(const Duration(hours: 2)),
      windowEnd: DateTime.now().toUtc().add(const Duration(hours: 8)),
      status: RightsStatus.pending,
      promoterId: 'promoter_002',
      updatedAt: DateTime.now().toUtc(),
    ),
    EventRights(
      eventId: 'demo_event_003',
      allowedRegions: ['au'],
      blockedRegions: [],
      windowStart: DateTime.now().toUtc().subtract(const Duration(days: 2)),
      windowEnd: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
      status: RightsStatus.expired,
      promoterId: 'promoter_001',
      updatedAt: DateTime.now().toUtc(),
    ),
  ];
}
