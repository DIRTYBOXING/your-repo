import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/ugc_consent_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC UGC CONSENT SERVICE — Content Rights, Revocation & Audit
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Manages the lifecycle of user-generated content consent on DFC:
///
///   1. Submit consent (double opt-in pending)
///   2. Confirm consent (token verification → active)
///   3. Check consent status before promotion
///   4. Revoke consent (de-promote within 48h SLA)
///   5. Expire consent (auto-expire past expiryTs)
///   6. Audit trail (immutable append-only log)
///
/// Firestore collections:
///   ugc_consents/{consentId}       — Consent records
///   ugc_audit/{auditId}            — Immutable audit events
///
/// DFC holds NO funds. Consent records only govern content usage rights.
/// Payment flows are handled by StripeConnectService + PaidPromotionModel.
///
/// ═══════════════════════════════════════════════════════════════════════════
class UgcConsentService {
  final FirebaseFirestore _firestore;

  UgcConsentService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Collection references ─────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _consents =>
      _firestore.collection('ugc_consents');

  CollectionReference<Map<String, dynamic>> get _audit =>
      _firestore.collection('ugc_audit');

  // ═══════════════════════════════════════════════════════════════════
  // SUBMIT CONSENT (Step 1: double opt-in pending)
  // ═══════════════════════════════════════════════════════════════════

  /// Create a new UGC consent record in pending state.
  /// Returns the consent token to embed in the confirmation email.
  Future<String?> submitConsent({
    required String userId,
    required String uploaderName,
    required String email,
    required String contentId,
    String? mediaUrl,
    UgcLicenseScope licenseScope = UgcLicenseScope.organic,
    String compensation = 'none',
    Duration? validFor,
    bool allowsNeuralTargeting = false,
    String? ipAddress,
  }) async {
    try {
      final now = DateTime.now();
      final token = _generateConsentToken();
      final expiryTs = validFor != null ? now.add(validFor) : null;

      final consent = UgcConsentModel(
        id: '',
        userId: userId,
        uploaderName: uploaderName,
        email: email,
        contentId: contentId,
        mediaUrl: mediaUrl,
        licenseScope: licenseScope,
        compensation: compensation,
        startTs: now,
        expiryTs: expiryTs,
        consentToken: token,
        ipAddress: ipAddress,
        allowsNeuralTargeting: allowsNeuralTargeting,
        createdAt: now,
        updatedAt: now,
      );

      await _consents.add(consent.toFirestore());

      await _logAuditEvent(
        userId: userId,
        contentId: contentId,
        action: 'consent_submitted',
        details: {
          'licenseScope': licenseScope.name,
          'compensation': compensation,
          'allowsNeuralTargeting': allowsNeuralTargeting,
        },
      );

      debugPrint('UgcConsentService: consent submitted for content $contentId');
      return token;
    } catch (e) {
      debugPrint('UgcConsentService.submitConsent error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // CONFIRM CONSENT (Step 2: double opt-in verification)
  // ═══════════════════════════════════════════════════════════════════

  /// Verify the consent token and activate the consent record.
  /// Called when user clicks the confirmation link in the opt-in email.
  Future<bool> confirmConsent({
    required String consentToken,
    String? ipAddress,
  }) async {
    try {
      final snap = await _consents
          .where('consentToken', isEqualTo: consentToken)
          .where('status', isEqualTo: UgcConsentStatus.pendingConfirmation.name)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        debugPrint('UgcConsentService: invalid or already-used token');
        return false;
      }

      final doc = snap.docs.first;
      final now = DateTime.now();

      await doc.reference.update({
        'status': UgcConsentStatus.active.name,
        'signatureTs': Timestamp.fromDate(now),
        'ipAddress': ?ipAddress,
        'updatedAt': Timestamp.fromDate(now),
      });

      await _logAuditEvent(
        userId: doc.data()['userId'] ?? '',
        contentId: doc.data()['contentId'] ?? '',
        action: 'consent_confirmed',
        details: {'consentToken': consentToken},
      );

      return true;
    } catch (e) {
      debugPrint('UgcConsentService.confirmConsent error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // CHECK CONSENT (Gate before promotion)
  // ═══════════════════════════════════════════════════════════════════

  /// Check if content has active consent for the given license scope.
  /// Must be called before creating a paid promotion.
  Future<UgcConsentModel?> getActiveConsent(String contentId) async {
    try {
      final snap = await _consents
          .where('contentId', isEqualTo: contentId)
          .where('status', isEqualTo: UgcConsentStatus.active.name)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;

      final consent = UgcConsentModel.fromFirestore(snap.docs.first);

      // Auto-expire if past expiryTs
      if (consent.expiryTs != null &&
          DateTime.now().isAfter(consent.expiryTs!)) {
        await _expireConsent(snap.docs.first.reference, consent);
        return null;
      }

      return consent;
    } catch (e) {
      debugPrint('UgcConsentService.getActiveConsent error: $e');
      return null;
    }
  }

  /// Check if content is cleared for paid promotion specifically.
  Future<bool> isContentClearedForPromotion(String contentId) async {
    final consent = await getActiveConsent(contentId);
    return consent?.allowsPaidPromotion ?? false;
  }

  /// Check if content allows brain-signal-targeted promotions.
  Future<bool> allowsNeuralTargeting(String contentId) async {
    final consent = await getActiveConsent(contentId);
    return consent?.isActive == true && consent!.allowsNeuralTargeting;
  }

  // ═══════════════════════════════════════════════════════════════════
  // REVOKE CONSENT (User-initiated takedown)
  // ═══════════════════════════════════════════════════════════════════

  /// Revoke consent for a specific content item.
  /// Triggers de-promotion workflow (48-hour SLA).
  Future<bool> revokeConsent({
    required String userId,
    required String contentId,
    String? reason,
  }) async {
    try {
      final snap = await _consents
          .where('userId', isEqualTo: userId)
          .where('contentId', isEqualTo: contentId)
          .where('status', isEqualTo: UgcConsentStatus.active.name)
          .get();

      if (snap.docs.isEmpty) return false;

      final now = DateTime.now();
      final batch = _firestore.batch();

      for (final doc in snap.docs) {
        batch.update(doc.reference, {
          'status': UgcConsentStatus.revoked.name,
          'updatedAt': Timestamp.fromDate(now),
          'metadata': {
            ...?(doc.data()['metadata'] as Map<String, dynamic>?),
            'revocationReason': reason,
            'revokedAt': now.toIso8601String(),
          },
        });
      }

      batch.commit();

      await _logAuditEvent(
        userId: userId,
        contentId: contentId,
        action: 'consent_revoked',
        details: {'reason': reason, 'docsAffected': snap.docs.length},
      );

      debugPrint(
        'UgcConsentService: revoked ${snap.docs.length} consent(s) for content $contentId',
      );
      return true;
    } catch (e) {
      debugPrint('UgcConsentService.revokeConsent error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // QUERY CONSENTS
  // ═══════════════════════════════════════════════════════════════════

  /// Get all consent records for a specific user.
  Future<List<UgcConsentModel>> getUserConsents(String userId) async {
    try {
      final snap = await _consents
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snap.docs
          .map(UgcConsentModel.fromFirestore)
          .toList();
    } catch (e) {
      debugPrint('UgcConsentService.getUserConsents error: $e');
      return [];
    }
  }

  /// Get all active consents for content that can be promoted.
  Future<List<UgcConsentModel>> getPromotableContent() async {
    try {
      final snap = await _consents
          .where('status', isEqualTo: UgcConsentStatus.active.name)
          .where(
            'licenseScope',
            whereIn: [
              UgcLicenseScope.paid.name,
              UgcLicenseScope.ads.name,
              UgcLicenseScope.commercial.name,
            ],
          )
          .get();

      return snap.docs
          .map(UgcConsentModel.fromFirestore)
          .where((c) => c.isActive) // double check expiry client-side
          .toList();
    } catch (e) {
      debugPrint('UgcConsentService.getPromotableContent error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // INTERNAL HELPERS
  // ═══════════════════════════════════════════════════════════════════

  /// Auto-expire a consent record that has passed its expiryTs.
  Future<void> _expireConsent(
    DocumentReference ref,
    UgcConsentModel consent,
  ) async {
    await ref.update({
      'status': UgcConsentStatus.expired.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
    await _logAuditEvent(
      userId: consent.userId,
      contentId: consent.contentId,
      action: 'consent_expired',
      details: {'expiryTs': consent.expiryTs?.toIso8601String()},
    );
  }

  /// Append an immutable audit event to ugc_audit collection.
  Future<void> _logAuditEvent({
    required String userId,
    required String contentId,
    required String action,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _audit.add({
        'userId': userId,
        'contentId': contentId,
        'action': action,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('UgcConsentService._logAuditEvent error: $e');
    }
  }

  /// Generate a cryptographically-sufficient consent token.
  String _generateConsentToken() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
