import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ppv_license_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV LICENSE SERVICE
///
/// Full lifecycle management for PPV broadcast licenses.
/// Pipeline: draft → pending → approved → active → (expired|terminated)
///
/// Only platform admins (owner) can approve/reject/suspend.
/// Promoters can draft and submit.
/// ═══════════════════════════════════════════════════════════════════════════

class PpvLicenseService {
  final FirebaseFirestore _db;

  PpvLicenseService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _licenses =>
      _db.collection('ppv_licenses');

  CollectionReference<Map<String, dynamic>> get _auditLog =>
      _db.collection('ppv_license_audit');

  // ── Create / Draft ──────────────────────────────────────────────────────

  /// Create a new license draft. Returns the new document ID.
  Future<String> createLicense({
    required PpvLicenseModel license,
    required String userId,
  }) async {
    final doc = _licenses.doc();
    final data = license.toFirestore();
    data['id'] = doc.id;
    data['createdBy'] = userId;
    data['status'] = LicenseStatus.draft.name;
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await doc.set(data);
    await _writeAudit(doc.id, userId, 'created', 'License draft created');
    return doc.id;
  }

  /// Update a license in draft or pending status.
  Future<void> updateLicense({
    required String licenseId,
    required Map<String, dynamic> updates,
    required String userId,
  }) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _licenses.doc(licenseId).update(updates);
    await _writeAudit(
      licenseId,
      userId,
      'updated',
      'Fields updated: ${updates.keys.join(', ')}',
    );
  }

  // ── Status Transitions ─────────────────────────────────────────────────

  /// Promoter submits draft for admin review.
  Future<void> submitForReview({
    required String licenseId,
    required String userId,
  }) async {
    await _licenses.doc(licenseId).update({
      'status': LicenseStatus.pending.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _writeAudit(licenseId, userId, 'submitted', 'Submitted for review');
  }

  /// Admin approves the license.
  Future<void> approveLicense({
    required String licenseId,
    required String adminId,
  }) async {
    await _licenses.doc(licenseId).update({
      'status': LicenseStatus.approved.name,
      'approvedBy': adminId,
      'approvedAt': FieldValue.serverTimestamp(),
      'rejectionReason': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _writeAudit(licenseId, adminId, 'approved', 'License approved');
  }

  /// Admin rejects the license back to draft.
  Future<void> rejectLicense({
    required String licenseId,
    required String adminId,
    required String reason,
  }) async {
    await _licenses.doc(licenseId).update({
      'status': LicenseStatus.draft.name,
      'rejectionReason': reason,
      'approvedBy': null,
      'approvedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _writeAudit(licenseId, adminId, 'rejected', reason);
  }

  /// Activate a previously approved license (stream is live).
  Future<void> activateLicense({
    required String licenseId,
    required String adminId,
  }) async {
    await _licenses.doc(licenseId).update({
      'status': LicenseStatus.active.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _writeAudit(licenseId, adminId, 'activated', 'License now active');
  }

  /// Suspend a license (dispute or regulatory hold).
  Future<void> suspendLicense({
    required String licenseId,
    required String adminId,
    required String reason,
  }) async {
    await _licenses.doc(licenseId).update({
      'status': LicenseStatus.suspended.name,
      'suspensionReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _writeAudit(licenseId, adminId, 'suspended', reason);
  }

  /// Terminate a license early.
  Future<void> terminateLicense({
    required String licenseId,
    required String adminId,
    required String reason,
  }) async {
    await _licenses.doc(licenseId).update({
      'status': LicenseStatus.terminated.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _writeAudit(licenseId, adminId, 'terminated', reason);
  }

  // ── Queries ─────────────────────────────────────────────────────────────

  /// Get a single license by ID.
  Future<PpvLicenseModel?> getLicense(String licenseId) async {
    final doc = await _licenses.doc(licenseId).get();
    if (!doc.exists) return null;
    return PpvLicenseModel.fromFirestore(doc);
  }

  /// Get the license for a specific PPV event.
  Future<PpvLicenseModel?> getLicenseForEvent(String ppvEventId) async {
    final snap = await _licenses
        .where('ppvEventId', isEqualTo: ppvEventId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return PpvLicenseModel.fromFirestore(snap.docs.first);
  }

  /// Get the license for a specific source event.
  Future<PpvLicenseModel?> getLicenseForEventId(String eventId) async {
    final snap = await _licenses
        .where('eventId', isEqualTo: eventId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return PpvLicenseModel.fromFirestore(snap.docs.first);
  }

  /// Stream all licenses pending admin review.
  Stream<List<PpvLicenseModel>> streamPendingLicenses() {
    return _licenses
        .where('status', isEqualTo: LicenseStatus.pending.name)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PpvLicenseModel.fromFirestore).toList());
  }

  /// Stream all licenses for a specific promoter.
  Stream<List<PpvLicenseModel>> streamPromoterLicenses(String promoterId) {
    return _licenses
        .where('promoterId', isEqualTo: promoterId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PpvLicenseModel.fromFirestore).toList());
  }

  /// Stream active licenses (for monitoring dashboard).
  Stream<List<PpvLicenseModel>> streamActiveLicenses() {
    return _licenses
        .where('status', isEqualTo: LicenseStatus.active.name)
        .snapshots()
        .map((snap) => snap.docs.map(PpvLicenseModel.fromFirestore).toList());
  }

  /// List all licenses (admin view) by status.
  Future<List<PpvLicenseModel>> listLicenses({
    LicenseStatus? status,
    int limit = 50,
  }) async {
    Query<Map<String, dynamic>> q = _licenses;
    if (status != null) {
      q = q.where('status', isEqualTo: status.name);
    }
    final snap = await q
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(PpvLicenseModel.fromFirestore).toList();
  }

  // ── Readiness Gate ──────────────────────────────────────────────────────

  /// Check if a PPV event's license is fully cleared for streaming.
  Future<bool> isEventClearedForStream(String ppvEventId) async {
    final license = await getLicenseForEvent(ppvEventId);
    if (license == null) return false;
    return license.isCleared &&
        license.thirdPartyRightsOk &&
        license.regulatoryOk &&
        license.insuranceOk;
  }

  // ── Expiry Sweep (called by scheduled function) ─────────────────────────

  /// Mark active licenses past termEnd as expired.
  Future<int> sweepExpiredLicenses() async {
    final now = Timestamp.fromDate(DateTime.now());
    final snap = await _licenses
        .where('status', isEqualTo: LicenseStatus.active.name)
        .where('termEnd', isLessThan: now)
        .get();

    int count = 0;
    for (final doc in snap.docs) {
      await doc.reference.update({
        'status': LicenseStatus.expired.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _writeAudit(
        doc.id,
        'SYSTEM',
        'expired',
        'Term ended automatically',
      );
      count++;
    }
    return count;
  }

  // ── Stats ───────────────────────────────────────────────────────────────

  Future<Map<String, int>> getLicenseStats() async {
    final snap = await _licenses.get();
    final stats = <String, int>{
      'total': snap.docs.length,
      'draft': 0,
      'pending': 0,
      'approved': 0,
      'active': 0,
      'suspended': 0,
      'expired': 0,
      'terminated': 0,
    };
    for (final doc in snap.docs) {
      final status = doc.data()['status']?.toString() ?? 'draft';
      stats[status] = (stats[status] ?? 0) + 1;
    }
    return stats;
  }

  // ── Audit Trail ─────────────────────────────────────────────────────────

  Future<void> _writeAudit(
    String licenseId,
    String userId,
    String action,
    String detail,
  ) async {
    await _auditLog.add({
      'licenseId': licenseId,
      'userId': userId,
      'action': action,
      'detail': detail,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Fetch audit trail for a license.
  Future<List<Map<String, dynamic>>> getAuditTrail(String licenseId) async {
    final snap = await _auditLog
        .where('licenseId', isEqualTo: licenseId)
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FILLED TERM SHEET GENERATOR
  // ═══════════════════════════════════════════════════════════════════════

  /// Generate a populated PPV Licence Term Sheet from a license record.
  /// Returns a formatted string ready for display, PDF, or email.
  static String generateTermSheet(PpvLicenseModel l) {
    final exclusivityLabel = switch (l.exclusivity) {
      ExclusivityType.exclusive => 'Exclusive',
      ExclusivityType.nonExclusive => 'Non-Exclusive',
      ExclusivityType.firstWindow =>
        'First Window (DFC premiere, then non-exclusive)',
    };

    final revenueLabel = switch (l.revenueModel) {
      RevenueModel.flatFee =>
        'Flat Fee: \$${(l.flatFeeCents ?? 0) / 100} ${l.currency}',
      RevenueModel.revenueShare =>
        'Sliding Revenue Share: 30% DFC floor \u2192 50% DFC ceiling '
            '(based on exposure). Promoter starts at 70%.',
      RevenueModel.hybrid =>
        'Hybrid: Minimum Guarantee \$${(l.minimumGuaranteeCents ?? 0) / 100} '
            '${l.currency} + Sliding Revenue Share (30\u201350% DFC, performance-based)',
      RevenueModel.freeToAir => 'Free-to-Air / Promotional (no charge)',
    };

    final territoryLabel = switch (l.territory) {
      TerritoryScope.australia => 'Australia',
      TerritoryScope.newZealand => 'New Zealand',
      TerritoryScope.oceania => 'Oceania (AU, NZ, Pacific Islands)',
      TerritoryScope.asiaPacific => 'Asia-Pacific',
      TerritoryScope.northAmerica => 'North America',
      TerritoryScope.europe => 'Europe',
      TerritoryScope.global => 'Global (worldwide)',
      TerritoryScope.custom => l.customTerritories.join(', '),
    };

    final drmLabel = switch (l.drmRequirement) {
      DrmRequirement.none => 'None',
      DrmRequirement.widevine => 'Widevine L1',
      DrmRequirement.fairplay => 'FairPlay Streaming',
      DrmRequirement.playready => 'PlayReady',
      DrmRequirement.multiDrm => 'Multi-DRM (Widevine + FairPlay + PlayReady)',
    };

    final f = _dateStr;

    return '''
\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550
DFC PPV BROADCAST LICENCE \u2014 TERM SHEET
Data Fight Central Pty Ltd
\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550

1. PARTIES
   Licensee: ${l.licenseeEntity}
   Licensor: ${l.licensorEntity}
   Contact:  ${l.licensorContact}
   ABN:      ${l.licensorAbn ?? 'Not provided'}

2. EVENT
   PPV Event ID: ${l.ppvEventId}
   Event ID:     ${l.eventId}

3. TERRITORY & PLATFORMS
   Territory:    $territoryLabel
   Platforms:    ${l.platforms.join(', ')}
   Geo-Blocking: ${l.geoBlockingRequired ? 'REQUIRED' : 'Not required'}
   ${l.blockedCountries.isNotEmpty ? 'Blocked:      ${l.blockedCountries.join(", ")}' : ''}

4. EXCLUSIVITY & TERM
   Exclusivity: $exclusivityLabel
   Term Start:  ${f(l.termStart)}
   Term End:    ${f(l.termEnd)}
   Auto-Renew:  ${l.autoRenew ? 'Yes (${l.renewalTermDays ?? 30} days)' : 'No'}
   ${l.terminationClause != null ? 'Termination:  ${l.terminationClause}' : ''}

5. COMMERCIAL TERMS \u2014 SLIDING AGREEMENT
   Revenue Model: $revenueLabel

   --- DFC Sliding Scale ---
   The DFC platform fee slides smoothly based on exposure:
     \u2022 Floor:   30% DFC at 0 buys  (promoter keeps 70%)
     \u2022 Ceiling: 50% DFC at 10,000+ buys  (equal split)
     \u2022 Between: Linear interpolation \u2014 no hard tier jumps
     \u2022 Example: 2,500 buys = 35% DFC | 5,000 = 40% | 7,500 = 45%

   Payment Terms: ${l.paymentTerms ?? 'Net 30 after event date'}
   Audit Rights:  ${l.auditRightsGranted ? 'Granted (30 days notice)' : 'Not granted'}
   Reporting:     ${l.reportingCadence ?? 'Weekly during active broadcast, monthly post-event'}

6. SUBLICENSING
   Allowed: ${l.sublicensingAllowed ? 'Yes' : 'No'}
   ${l.approvedSublicensees.isNotEmpty ? 'Approved Partners: ${l.approvedSublicensees.join(", ")}' : ''}

7. THIRD-PARTY RIGHTS CLEARANCE
   Music Rights:         ${l.musicRightsCleared ? '\u2713 CLEARED' : '\u2717 PENDING'}
   Talent Releases:      ${l.talentReleasesObtained ? '\u2713 OBTAINED' : '\u2717 PENDING'}
   Archival Footage:     ${l.archivalFootageCleared ? '\u2713 CLEARED' : '\u2717 PENDING'}
   Logos / Trademarks:   ${l.logosTrademarkCleared ? '\u2713 CLEARED' : '\u2717 PENDING'}
   ${l.collectingSocietyRef != null ? 'Collecting Society: ${l.collectingSocietyRef}' : ''}

8. TECHNICAL DELIVERY
   DRM:           $drmLabel
   Watermarking:  ${l.watermarkingRequired ? 'Required' : 'Not required'}
   Ingest Format: ${l.ingestFormat ?? 'RTMP push to DFC CDN endpoint'}
   CDN:           ${l.cdnProvider ?? 'DFC Global CDN'}

9. REGULATORY COMPLIANCE
   ACMA License Required: ${l.acmaLicenseRequired ? 'Yes' : 'No (exempt under BSA Schedule 2)'}
   ${l.acmaLicenseNumber != null ? 'ACMA License #: ${l.acmaLicenseNumber}' : ''}
   ${l.acmaExemptionConfirmed ? 'ACMA Exemption: Confirmed' : ''}

10. INSURANCE
    Event Liability: ${l.eventInsuranceConfirmed ? '\u2713 CONFIRMED' : '\u2717 PENDING'}
    Cyber / E&O:    ${l.cyberInsuranceConfirmed ? '\u2713 CONFIRMED' : '\u2717 PENDING'}
    ${l.insurancePolicyRef != null ? 'Policy Ref: ${l.insurancePolicyRef}' : ''}

11. DOCUMENTS ON FILE
    Chain of Title:     ${l.chainOfTitleDocUrl != null ? '\u2713 Uploaded' : '\u2717 Missing'}
    Signed License:     ${l.signedLicenseDocUrl != null ? '\u2713 Uploaded' : '\u2717 Missing'}
    Talent Releases:    ${l.talentReleaseDocUrl != null ? '\u2713 Uploaded' : '\u2717 Missing'}
    Supporting Docs:    ${l.supportingDocUrls.length} file(s)

12. ATTESTATION
    Licensor Signed: ${l.licensorAttestationSigned ? '\u2713 ${f(l.licensorAttestationAt)}' : '\u2717 Not yet signed'}

13. READINESS SCORE: ${(l.readinessScore * 100).toStringAsFixed(0)}%

14. GOVERNING LAW
    State of Queensland, Australia. Disputes resolved via
    mediation first, then Queensland courts.

\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
Generated by DFC License Engine
''';
  }

  static String _dateStr(DateTime? dt) =>
      dt != null ? '${dt.day}/${dt.month}/${dt.year}' : 'TBD';
}
