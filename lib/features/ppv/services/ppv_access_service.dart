import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../shared/models/ppv_model.dart';

const bool _useFirebaseEmulatorForPpvAccess = bool.fromEnvironment(
  'USE_FIREBASE_EMULATOR',
);

class DrmPlaybackToken {
  const DrmPlaybackToken({required this.token, required this.expiresInSeconds});

  final String token;
  final int expiresInSeconds;
}

/// Service to resolve PPV access against the canonical backend state.
class PPVAccessService {
  PPVAccessService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _functions = functions;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  FirebaseFunctions? _functions;
  static const Set<String> _negativeStatuses = {
    'canceled',
    'cancelled',
    'expired',
    'failed',
    'inactive',
    'refunded',
    'revoked',
  };
  static const Set<String> _positiveSessionStatuses = {
    'active',
    'complete',
    'completed',
    'granted',
    'paid',
    'succeeded',
  };

  FirebaseFunctions get _firebaseFunctions => _functions ??=
      FirebaseFunctions.instanceFor(region: 'australia-southeast1');

  Uri? _buildHttpFunctionUri(String functionName) {
    final projectId = Firebase.app().options.projectId.trim();
    if (projectId.isEmpty) {
      return null;
    }

    if (_useFirebaseEmulatorForPpvAccess) {
      final emulatorHost = kIsWeb ? '127.0.0.1' : '10.0.2.2';
      return Uri.parse(
        'http://$emulatorHost:5001/$projectId/australia-southeast1/$functionName',
      );
    }

    return Uri.parse(
      'https://australia-southeast1-$projectId.cloudfunctions.net/$functionName',
    );
  }

  DateTime? _readDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }

  bool _isRecordInactive(Map<String, dynamic> data) {
    final status = data['status']?.toString().trim().toLowerCase();
    final paymentStatus = data['paymentStatus']
        ?.toString()
        .trim()
        .toLowerCase();

    if (data['isActive'] == false ||
        data['replayExpired'] == true ||
        data['accessGranted'] == false) {
      return true;
    }

    if ((status != null && _negativeStatuses.contains(status)) ||
        (paymentStatus != null && _negativeStatuses.contains(paymentStatus))) {
      return true;
    }

    final expiresAt = _readDateTime(data['expiresAt']);
    return expiresAt != null && expiresAt.isBefore(DateTime.now());
  }

  bool _isSessionRecordActive(Map<String, dynamic> data) {
    if (_isRecordInactive(data)) {
      return false;
    }

    final status = data['status']?.toString().trim().toLowerCase();
    final paymentStatus = data['paymentStatus']
        ?.toString()
        .trim()
        .toLowerCase();

    return data['accessGranted'] == true ||
        (status != null && _positiveSessionStatuses.contains(status)) ||
        (paymentStatus != null &&
            _positiveSessionStatuses.contains(paymentStatus));
  }

  bool _isPurchaseRecordActive(Map<String, dynamic> data) {
    if (_isRecordInactive(data)) {
      return false;
    }

    final status = data['status']?.toString().trim().toLowerCase();
    final paymentStatus = data['paymentStatus']
        ?.toString()
        .trim()
        .toLowerCase();

    return data['accessGranted'] == true ||
        (status != null && _positiveSessionStatuses.contains(status)) ||
        (paymentStatus != null &&
            _positiveSessionStatuses.contains(paymentStatus));
  }

  bool _isAccessRecordActive(Map<String, dynamic> data) {
    return !_isRecordInactive(data);
  }

  bool _isAuthoritativeSessionRecord(Map<String, dynamic> data) {
    final status = data['status']?.toString().trim().toLowerCase();
    final paymentStatus = data['paymentStatus']
        ?.toString()
        .trim()
        .toLowerCase();

    return data['accessGranted'] == true ||
        data['accessGranted'] == false ||
        data['isActive'] == false ||
        data['replayExpired'] == true ||
        data['refunded'] == true ||
        data['revoked'] == true ||
        _readDateTime(data['expiresAt']) != null ||
        (status != null &&
            (_positiveSessionStatuses.contains(status) ||
                _negativeStatuses.contains(status))) ||
        (paymentStatus != null &&
            (_positiveSessionStatuses.contains(paymentStatus) ||
                _negativeStatuses.contains(paymentStatus)));
  }

  bool _isAuthoritativePurchaseRecord(Map<String, dynamic> data) {
    final status = data['status']?.toString().trim().toLowerCase();
    final paymentStatus = data['paymentStatus']
        ?.toString()
        .trim()
        .toLowerCase();

    return data['accessGranted'] == true ||
        data['accessGranted'] == false ||
        data['isActive'] == false ||
        data['replayExpired'] == true ||
        data['refunded'] == true ||
        data['revoked'] == true ||
        _readDateTime(data['expiresAt']) != null ||
        (status != null &&
            (_positiveSessionStatuses.contains(status) ||
                _negativeStatuses.contains(status))) ||
        (paymentStatus != null &&
            (_positiveSessionStatuses.contains(paymentStatus) ||
                _negativeStatuses.contains(paymentStatus)));
  }

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

  Future<Set<String>> _resolvePpvLookupIds(String eventId) async {
    final ids = <String>{};

    final canonicalDocId = await _resolvePpvDocumentId(eventId);
    if (canonicalDocId != null && canonicalDocId.isNotEmpty) {
      ids.add(canonicalDocId);
    }

    ids.add(eventId);

    try {
      final directDoc = await _firestore
          .collection('ppv_events')
          .doc(eventId)
          .get();
      if (directDoc.exists) {
        ids.add(directDoc.id);
        final rawEventId = directDoc.data()?['eventId']?.toString();
        if (rawEventId != null && rawEventId.isNotEmpty) {
          ids.add(rawEventId);
        }
      }

      final eventIdSnapshot = await _firestore
          .collection('ppv_events')
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();
      if (eventIdSnapshot.docs.isNotEmpty) {
        ids.add(eventIdSnapshot.docs.first.id);
      }
    } catch (_) {}

    ids.removeWhere((value) => value.isEmpty);
    return ids;
  }

  Future<_PpvRecordState> _sessionRecordState({
    required String userId,
    required String eventId,
  }) async {
    final lookupIds = await _resolvePpvLookupIds(eventId);
    var hasAny = false;

    for (final lookupId in lookupIds) {
      final sessionQuery = await _firestore
          .collection('ppv_checkout_sessions')
          .where('userId', isEqualTo: userId)
          .where('ppvId', isEqualTo: lookupId)
          .limit(5)
          .get();

      final authoritativeDocs = sessionQuery.docs
          .where((doc) => _isAuthoritativeSessionRecord(doc.data()))
          .toList();
      if (authoritativeDocs.isNotEmpty) {
        hasAny = true;
        if (authoritativeDocs.any(
          (doc) => _isSessionRecordActive(doc.data()),
        )) {
          return const _PpvRecordState(hasAny: true, hasActive: true);
        }
      }
    }

    return _PpvRecordState(hasAny: hasAny, hasActive: false);
  }

  Future<_PpvRecordState> _purchaseRecordState({
    required String userId,
    required String eventId,
  }) async {
    final lookupIds = await _resolvePpvLookupIds(eventId);
    var hasAny = false;

    for (final lookupId in lookupIds) {
      final directPurchase = _firestore
          .collection('ppv_purchases')
          .doc('${userId}_$lookupId')
          .get();
      final purchaseQueries = await Future.wait([
        directPurchase,
        _firestore
            .collection('ppv_purchases')
            .where('userId', isEqualTo: userId)
            .where('ppvId', isEqualTo: lookupId)
            .limit(10)
            .get(),
        _firestore
            .collection('ppv_purchases')
            .where('userId', isEqualTo: userId)
            .where('ppvEventId', isEqualTo: lookupId)
            .limit(10)
            .get(),
        _firestore
            .collection('ppv_purchases')
            .where('userId', isEqualTo: userId)
            .where('eventId', isEqualTo: lookupId)
            .limit(10)
            .get(),
      ]);

      final directDoc =
          purchaseQueries[0] as DocumentSnapshot<Map<String, dynamic>>;
      final queryDocs = purchaseQueries
          .skip(1)
          .cast<QuerySnapshot<Map<String, dynamic>>>()
          .expand((snapshot) => snapshot.docs);

      final candidates = <Map<String, dynamic>>[];
      if (directDoc.exists) {
        candidates.add(directDoc.data()!);
      }
      candidates.addAll(queryDocs.map((doc) => doc.data()));

      final authoritativeDocs = candidates
          .where(_isAuthoritativePurchaseRecord)
          .toList();
      if (authoritativeDocs.isNotEmpty) {
        hasAny = true;
        if (authoritativeDocs.any(_isPurchaseRecordActive)) {
          return const _PpvRecordState(hasAny: true, hasActive: true);
        }
      }
    }

    return _PpvRecordState(hasAny: hasAny, hasActive: false);
  }

  Future<_PpvRecordState> _accessRecordState({
    required String userId,
    required String eventId,
  }) async {
    final lookupIds = await _resolvePpvLookupIds(eventId);
    var hasAny = false;

    for (final lookupId in lookupIds) {
      final accessReads = await Future.wait([
        _firestore.collection('ppv_access').doc('${userId}_$lookupId').get(),
        _firestore
            .collection('users')
            .doc(userId)
            .collection('ppv_access')
            .doc(lookupId)
            .get(),
        _firestore
            .collection('ppv_access')
            .where('userId', isEqualTo: userId)
            .where('eventId', isEqualTo: lookupId)
            .limit(10)
            .get(),
      ]);

      final directDoc =
          accessReads[0] as DocumentSnapshot<Map<String, dynamic>>;
      final nestedDoc =
          accessReads[1] as DocumentSnapshot<Map<String, dynamic>>;
      final queryDocs =
          (accessReads[2] as QuerySnapshot<Map<String, dynamic>>).docs;

      final candidates = <Map<String, dynamic>>[];
      if (directDoc.exists) {
        candidates.add(directDoc.data()!);
      }
      if (nestedDoc.exists) {
        candidates.add(nestedDoc.data()!);
      }
      candidates.addAll(queryDocs.map((doc) => doc.data()));

      if (candidates.isNotEmpty) {
        hasAny = true;
        if (candidates.any(_isAccessRecordActive)) {
          return const _PpvRecordState(hasAny: true, hasActive: true);
        }
      }
    }

    return _PpvRecordState(hasAny: hasAny, hasActive: false);
  }

  Future<_PpvRecordState> _entitlementRecordState({
    required String userId,
    required String eventId,
  }) async {
    final lookupIds = await _resolvePpvLookupIds(eventId);
    var hasAny = false;

    for (final lookupId in lookupIds) {
      final reads = await Future.wait([
        _firestore.collection('entitlements').doc('${userId}_$lookupId').get(),
        _firestore
            .collection('entitlements')
            .where('userId', isEqualTo: userId)
            .where('eventId', isEqualTo: lookupId)
            .limit(5)
            .get(),
      ]);

      final directDoc = reads[0] as DocumentSnapshot<Map<String, dynamic>>;
      final queryDocs = (reads[1] as QuerySnapshot<Map<String, dynamic>>).docs;

      final candidates = <Map<String, dynamic>>[];
      if (directDoc.exists) {
        candidates.add(directDoc.data()!);
      }
      candidates.addAll(queryDocs.map((doc) => doc.data()));

      if (candidates.isNotEmpty) {
        hasAny = true;
        final isActive = candidates.any((data) {
          if (_isRecordInactive(data)) {
            return false;
          }

          final hasAccess = data['hasAccess'];
          if (hasAccess is bool) {
            return hasAccess;
          }

          return data['accessGranted'] == true || data['isActive'] == true;
        });
        if (isActive) {
          return const _PpvRecordState(hasAny: true, hasActive: true);
        }
      }
    }

    return _PpvRecordState(hasAny: hasAny, hasActive: false);
  }

  Future<bool?> _canonicalAccessDecision({
    required String userId,
    required String eventId,
  }) async {
    try {
      final result = await _firebaseFunctions
          .httpsCallable('checkPPVAccess')
          .call({'userId': userId, 'ppvId': eventId});

      final rawData = result.data;
      if (rawData is! Map) {
        return null;
      }

      final data = Map<String, dynamic>.from(rawData);
      if (data['error'] != null) {
        return null;
      }

      final hasAccess = data['hasAccess'];
      return hasAccess is bool ? hasAccess : null;
    } on FirebaseFunctionsException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _fallbackAccessDecision({
    required String userId,
    required String eventId,
  }) async {
    final entitlementState = await _entitlementRecordState(
      userId: userId,
      eventId: eventId,
    );
    if (entitlementState.hasAny) {
      return entitlementState.hasActive;
    }

    final sessionState = await _sessionRecordState(
      userId: userId,
      eventId: eventId,
    );
    if (sessionState.hasAny) {
      return sessionState.hasActive;
    }

    final purchaseState = await _purchaseRecordState(
      userId: userId,
      eventId: eventId,
    );
    if (purchaseState.hasAny) {
      return purchaseState.hasActive;
    }

    final accessState = await _accessRecordState(
      userId: userId,
      eventId: eventId,
    );
    return accessState.hasAny && accessState.hasActive;
  }

  Future<bool> hasAccessForUser(String userId, String eventId) async {
    final canonicalDecision = await _canonicalAccessDecision(
      userId: userId,
      eventId: eventId,
    );
    if (canonicalDecision != null) {
      return canonicalDecision;
    }

    return _fallbackAccessDecision(userId: userId, eventId: eventId);
  }

  /// Grant access after successful payment
  Future<void> grantAccess({
    required String eventId,
    required String bundleName,
    required double price,
    required String stripePaymentId,
  }) async {
    throw UnsupportedError(
      'Client-side PPV access grants are retired. Access is granted by canonical checkout completion only.',
    );
  }

  /// Check if user has access to a specific event
  Future<bool> hasAccess(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    return hasAccessForUser(user.uid, eventId);
  }

  /// Live stream of access status. Firestore writes wake the stream, but the
  /// final access decision is resolved through the canonical backend callable
  /// when it is available.
  Stream<bool> accessStream(String eventId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    final controller = StreamController<bool>.broadcast();
    final subscriptions = <StreamSubscription>[];

    Future<void> refresh() async {
      final hasAccess = await hasAccessForUser(user.uid, eventId);

      if (!controller.isClosed) {
        controller.add(hasAccess);
      }
    }

    Future<void> bind() async {
      final lookupIds = await _resolvePpvLookupIds(eventId);

      for (final lookupId in lookupIds) {
        subscriptions.add(
          _firestore
              .collection('ppv_checkout_sessions')
              .where('userId', isEqualTo: user.uid)
              .where('ppvId', isEqualTo: lookupId)
              .limit(1)
              .snapshots()
              .listen(
                (_) => unawaited(refresh()),
                onError: controller.addError,
              ),
        );
      }

      await refresh();
    }

    unawaited(bind());

    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };

    return controller.stream.distinct();
  }

  /// Get all PPV purchases for current user
  Future<List<Map<String, dynamic>>> getMyPurchases() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final query = await _firestore
        .collection('ppv_checkout_sessions')
        .where('userId', isEqualTo: user.uid)
        .limit(100)
        .get();
    final purchases = query.docs.map((doc) => doc.data()).toList();
    purchases.sort((left, right) {
      final leftTime =
          _readDateTime(left['completedAt']) ??
          _readDateTime(left['purchasedAt']) ??
          _readDateTime(left['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final rightTime =
          _readDateTime(right['completedAt']) ??
          _readDateTime(right['purchasedAt']) ??
          _readDateTime(right['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return rightTime.compareTo(leftTime);
    });
    return purchases;
  }

  /// Resolve a short-lived playback URL for protected PPV media.
  ///
  /// Returns null when entitlement is missing or when the backend does not
  /// expose a signed URL for this event.
  Future<String?> fetchSignedPlaybackUrl(String eventId) async {
    final user = _auth.currentUser;
    if (user == null || eventId.trim().isEmpty) {
      return null;
    }

    try {
      final result = await _firebaseFunctions
          .httpsCallable('getPpvSignedVideoUrl')
          .call({'eventId': eventId});
      final rawData = result.data;
      if (rawData is! Map) {
        return null;
      }

      final data = Map<String, dynamic>.from(rawData);
      final url = data['signedUrl']?.toString();
      if (url == null || url.isEmpty) {
        return null;
      }

      return url;
    } on FirebaseFunctionsException catch (error) {
      debugPrint(
        'PPV signed playback URL unavailable for $eventId: ${error.code} ${error.message}',
      );
      return null;
    } catch (error) {
      debugPrint('PPV signed playback URL failed for $eventId: $error');
      return null;
    }
  }

  Future<DrmPlaybackToken?> fetchDrmPlaybackToken(
    PPVEvent event, {
    String device = 'web',
  }) async {
    final user = _auth.currentUser;
    if (user == null ||
        event.id.trim().isEmpty ||
        !event.hasDrmPlaybackConfig) {
      return null;
    }

    final uri = _buildHttpFunctionUri('drmTokenApi');
    if (uri == null) {
      return null;
    }

    try {
      final idToken = await user.getIdToken();
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'eventId': event.id,
          'device': device,
          'scope': 'playback',
        }),
      );

      if (response.statusCode != 200) {
        debugPrint(
          'PPV DRM token unavailable for ${event.id}: '
          '${response.statusCode} ${response.body}',
        );
        return null;
      }

      final raw = jsonDecode(response.body);
      if (raw is! Map<String, dynamic>) {
        return null;
      }

      final token = raw['token']?.toString();
      final expiresIn = (raw['expiresIn'] as num?)?.toInt() ?? 0;
      if (token == null || token.isEmpty || expiresIn <= 0) {
        return null;
      }

      return DrmPlaybackToken(token: token, expiresInSeconds: expiresIn);
    } catch (error) {
      debugPrint('PPV DRM token fetch failed for ${event.id}: $error');
      return null;
    }
  }
}

class _PpvRecordState {
  final bool hasAny;
  final bool hasActive;

  const _PpvRecordState({required this.hasAny, required this.hasActive});
}
