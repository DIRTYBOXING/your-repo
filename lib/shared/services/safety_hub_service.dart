import 'package:cloud_firestore/cloud_firestore.dart';

/// ═══════════════════════════════════════════════════════════════════════
/// DFC Safety Hub Service
///
/// Centralized safety service for victim-safe features, panic buttons,
/// emergency contacts, anti-violence resources, and safe-space coordination.
/// Powers the Pink Shield emblem and safety-first mission.
///
/// Pillars:
///   1. Pink Shield Certification (victim-safe gym/mentor network)
///   2. Panic Alert + Emergency Contacts
///   3. Guardian Mode (walk-home tracking, auto check-in, responders)
///   4. Evidence Vault (incident recording, cloud-safe, audit trail)
///   5. Area Threat Intelligence (crowd-sourced + admin warnings)
///   6. Gym Safety Ratings
/// ═══════════════════════════════════════════════════════════════════════
class SafetyHubService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Pink Shield Certification ─────────────────────────────────────

  /// Check if a gym/mentor is Pink Shield certified (victim-safe).
  Future<bool> isPinkShieldCertified(String entityId) async {
    try {
      final doc = await _db
          .collection('pink_shield_certifications')
          .doc(entityId)
          .get();
      if (!doc.exists) return false;
      final data = doc.data();
      return data?['status'] == 'approved' &&
          (data?['expiresAt'] == null ||
              (data!['expiresAt'] as Timestamp).toDate().isAfter(
                DateTime.now(),
              ));
    } catch (_) {
      return false;
    }
  }

  /// Apply for Pink Shield certification (gym owners / mentors).
  Future<void> applyForPinkShield({
    required String entityId,
    required String entityType, // 'gym' | 'mentor'
    required String applicantId,
    required String safetyStatement,
  }) async {
    await _db.collection('pink_shield_applications').add({
      'entityId': entityId,
      'entityType': entityType,
      'applicantId': applicantId,
      'safetyStatement': safetyStatement,
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
      'reviewedAt': null,
      'reviewerId': null,
      'reason': null,
    });
  }

  /// Approve or deny Pink Shield application (admin only).
  Future<void> reviewPinkShieldApplication({
    required String applicationId,
    required bool approved,
    required String reviewerId,
    String? reason,
  }) async {
    final batch = _db.batch();

    final appRef = _db
        .collection('pink_shield_applications')
        .doc(applicationId);
    final appDoc = await appRef.get();
    final appData = appDoc.data();

    batch.update(appRef, {
      'status': approved ? 'approved' : 'denied',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewerId': reviewerId,
      'reason': reason,
    });

    if (approved && appData != null) {
      final certRef = _db
          .collection('pink_shield_certifications')
          .doc(appData['entityId']);
      batch.set(certRef, {
        'entityId': appData['entityId'],
        'entityType': appData['entityType'],
        'certifiedAt': FieldValue.serverTimestamp(),
        'certifiedBy': reviewerId,
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 365)),
        ),
        'status': 'approved',
      });
    }

    await batch.commit();
  }

  // ── Emergency & Panic ────────────────────────────────────────────

  /// Trigger silent panic alert — notifies emergency contacts and admins.
  Future<String> triggerPanicAlert({
    required String userId,
    double? latitude,
    double? longitude,
  }) async {
    // 1. Write alert to Firestore
    final alertRef = await _db.collection('panic_alerts').add({
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'triggeredAt': FieldValue.serverTimestamp(),
      'status': 'active', // active → responded → resolved
      'resolvedAt': null,
      'respondedBy': null,
    });

    // 2. Fetch emergency contacts and write notification docs
    final contacts = await getEmergencyContacts(userId);
    for (final contact in contacts) {
      await _db.collection('safety_notifications').add({
        'alertId': alertRef.id,
        'userId': userId,
        'contactName': contact.name,
        'contactPhone': contact.phone,
        'contactRelationship': contact.relationship,
        'latitude': latitude,
        'longitude': longitude,
        'type': 'panic_alert',
        'sentAt': FieldValue.serverTimestamp(),
        'acknowledged': false,
      });
    }

    // 3. Write to user's active alert reference for quick lookup
    await _db.collection('users').doc(userId).update({
      'activePanicAlert': alertRef.id,
      'lastPanicAt': FieldValue.serverTimestamp(),
    });

    return alertRef.id;
  }

  /// Resolve an active panic alert.
  Future<void> resolvePanicAlert({
    required String alertId,
    required String userId,
    String resolution = 'user_resolved',
  }) async {
    await _db.collection('panic_alerts').doc(alertId).update({
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolution': resolution,
    });
    await _db.collection('users').doc(userId).update({
      'activePanicAlert': null,
    });
  }

  /// Set emergency contacts for a user (max 3).
  Future<void> setEmergencyContacts({
    required String userId,
    required List<EmergencyContact> contacts,
  }) async {
    final contactsRef = _db
        .collection('users')
        .doc(userId)
        .collection('emergency_contacts');

    // Clear existing
    final existing = await contactsRef.get();
    for (final doc in existing.docs) {
      await doc.reference.delete();
    }

    // Write new (max 3)
    final limited = contacts.take(3).toList();
    for (final c in limited) {
      await contactsRef.add(c.toMap());
    }
  }

  /// Fetch emergency contacts for a user.
  Future<List<EmergencyContact>> getEmergencyContacts(String userId) async {
    try {
      final snap = await _db
          .collection('users')
          .doc(userId)
          .collection('emergency_contacts')
          .limit(3)
          .get();
      return snap.docs.map((d) => EmergencyContact.fromMap(d.data())).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Guardian Mode ────────────────────────────────────────────────

  /// Start Guardian Mode — walk-home tracking.
  /// Creates a session that expects periodic check-ins.
  /// If check-in is missed, escalates to emergency contacts.
  Future<String> startGuardianMode({
    required String userId,
    required double startLat,
    required double startLng,
    double? destinationLat,
    double? destinationLng,
    String? destinationName,
    int checkInIntervalMinutes = 5,
  }) async {
    final sessionRef = await _db.collection('guardian_sessions').add({
      'userId': userId,
      'startLat': startLat,
      'startLng': startLng,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'destinationName': destinationName,
      'checkInIntervalMinutes': checkInIntervalMinutes,
      'status': 'active', // active → arrived → expired → escalated
      'startedAt': FieldValue.serverTimestamp(),
      'lastCheckIn': FieldValue.serverTimestamp(),
      'nextCheckInDue': Timestamp.fromDate(
        DateTime.now().add(Duration(minutes: checkInIntervalMinutes)),
      ),
      'endedAt': null,
      'escalated': false,
      'locationHistory': [
        {'lat': startLat, 'lng': startLng, 'timestamp': Timestamp.now()},
      ],
    });

    await _db.collection('users').doc(userId).update({
      'activeGuardianSession': sessionRef.id,
    });

    return sessionRef.id;
  }

  /// Check in during Guardian Mode — resets the timer.
  Future<void> guardianCheckIn({
    required String sessionId,
    required double latitude,
    required double longitude,
  }) async {
    final ref = _db.collection('guardian_sessions').doc(sessionId);
    final doc = await ref.get();
    if (!doc.exists) return;

    final interval = (doc.data()?['checkInIntervalMinutes'] as int?) ?? 5;

    await ref.update({
      'lastCheckIn': FieldValue.serverTimestamp(),
      'nextCheckInDue': Timestamp.fromDate(
        DateTime.now().add(Duration(minutes: interval)),
      ),
      'locationHistory': FieldValue.arrayUnion([
        {'lat': latitude, 'lng': longitude, 'timestamp': Timestamp.now()},
      ]),
    });
  }

  /// End Guardian Mode — user arrived safely.
  Future<void> endGuardianMode({
    required String sessionId,
    required String userId,
    double? endLat,
    double? endLng,
  }) async {
    await _db.collection('guardian_sessions').doc(sessionId).update({
      'status': 'arrived',
      'endedAt': FieldValue.serverTimestamp(),
      'endLat': ?endLat,
      'endLng': ?endLng,
    });
    await _db.collection('users').doc(userId).update({
      'activeGuardianSession': null,
    });
  }

  /// Escalate a guardian session — missed check-in.
  Future<void> escalateGuardianSession({
    required String sessionId,
    required String userId,
  }) async {
    final doc = await _db.collection('guardian_sessions').doc(sessionId).get();
    if (!doc.exists) return;
    final data = doc.data()!;

    await _db.collection('guardian_sessions').doc(sessionId).update({
      'status': 'escalated',
      'escalated': true,
      'escalatedAt': FieldValue.serverTimestamp(),
    });

    // Trigger panic alert with last known location
    final history = data['locationHistory'] as List<dynamic>?;
    double? lat = data['startLat'] as double?;
    double? lng = data['startLng'] as double?;
    if (history != null && history.isNotEmpty) {
      final last = history.last as Map<String, dynamic>;
      lat = last['lat'] as double?;
      lng = last['lng'] as double?;
    }

    await triggerPanicAlert(userId: userId, latitude: lat, longitude: lng);
  }

  /// Stream guardian session updates (for live tracking UI).
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchGuardianSession(
    String sessionId,
  ) {
    return _db.collection('guardian_sessions').doc(sessionId).snapshots();
  }

  // ── Evidence Vault ───────────────────────────────────────────────

  /// Record an incident with evidence files.
  Future<String> createIncidentRecord({
    required String userId,
    required String
    incidentType, // 'harassment', 'assault', 'stalking', 'threat', 'other'
    required String description,
    double? latitude,
    double? longitude,
    String? locationDescription,
    List<String>? evidenceFileUrls, // Storage URLs for photos/video/audio
    bool isAnonymous = false,
    String? perpetratorDescription,
  }) async {
    final ref = await _db.collection('incident_records').add({
      'userId': isAnonymous ? 'anonymous' : userId,
      'reporterUserId': userId, // Always stored for audit
      'incidentType': incidentType,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'locationDescription': locationDescription,
      'evidenceFileUrls': evidenceFileUrls ?? [],
      'isAnonymous': isAnonymous,
      'perpetratorDescription': perpetratorDescription,
      'status': 'recorded', // recorded → reviewed → referred → closed
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'reviewedBy': null,
      'referredTo': null,
    });

    return ref.id;
  }

  /// Add evidence to an existing incident.
  Future<void> addEvidenceToIncident({
    required String incidentId,
    required List<String> newEvidenceUrls,
    String? note,
  }) async {
    await _db.collection('incident_records').doc(incidentId).update({
      'evidenceFileUrls': FieldValue.arrayUnion(newEvidenceUrls),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (note != null) {
      await _db
          .collection('incident_records')
          .doc(incidentId)
          .collection('audit_log')
          .add({
            'action': 'evidence_added',
            'note': note,
            'timestamp': FieldValue.serverTimestamp(),
            'fileCount': newEvidenceUrls.length,
          });
    }
  }

  /// Get all incidents for a user (for their personal evidence vault).
  Future<List<Map<String, dynamic>>> getUserIncidents(String userId) async {
    try {
      final snap = await _db
          .collection('incident_records')
          .where('reporterUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (_) {
      return [];
    }
  }

  /// Generate a shareable evidence package (for police/legal).
  Future<Map<String, dynamic>> generateEvidencePackage({
    required String incidentId,
    required String userId,
  }) async {
    final doc = await _db.collection('incident_records').doc(incidentId).get();
    if (!doc.exists) return {};

    final data = doc.data()!;
    final auditSnap = await _db
        .collection('incident_records')
        .doc(incidentId)
        .collection('audit_log')
        .orderBy('timestamp')
        .get();

    // Log the package generation for audit
    await _db
        .collection('incident_records')
        .doc(incidentId)
        .collection('audit_log')
        .add({
          'action': 'evidence_package_generated',
          'generatedBy': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });

    return {
      'incidentId': incidentId,
      'generatedAt': DateTime.now().toIso8601String(),
      'generatedBy': userId,
      'incidentType': data['incidentType'],
      'description': data['description'],
      'location': {
        'latitude': data['latitude'],
        'longitude': data['longitude'],
        'description': data['locationDescription'],
      },
      'evidenceFiles': data['evidenceFileUrls'] ?? [],
      'perpetratorDescription': data['perpetratorDescription'],
      'createdAt': (data['createdAt'] as Timestamp?)
          ?.toDate()
          .toIso8601String(),
      'auditTrail': auditSnap.docs
          .map(
            (d) => {
              'action': d.data()['action'],
              'timestamp': (d.data()['timestamp'] as Timestamp?)
                  ?.toDate()
                  .toIso8601String(),
              'note': d.data()['note'],
            },
          )
          .toList(),
      'platform': 'DataFightCentral',
      'disclaimer':
          'This evidence package was generated by DataFightCentral\'s Safety Hub. '
          'All timestamps are UTC. Files are stored securely in cloud storage. '
          'This document is intended for law enforcement or legal counsel.',
    };
  }

  // ── Anti-Violence Resources ──────────────────────────────────────

  /// Get curated list of anti-violence / victim support resources.
  List<SafetyResource> getAntiViolenceResources() {
    return const [
      // Australia
      SafetyResource(
        name: '1800RESPECT',
        phone: '1800 737 732',
        url: 'https://www.1800respect.org.au',
        description:
            'Australia\'s national DV & sexual assault helpline. 24/7.',
        country: 'AU',
      ),
      SafetyResource(
        name: 'Lifeline Australia',
        phone: '13 11 14',
        url: 'https://www.lifeline.org.au',
        description: 'Crisis support & suicide prevention. 24/7.',
        country: 'AU',
      ),
      // United States
      SafetyResource(
        name: 'National Domestic Violence Hotline',
        phone: '1-800-799-7233',
        url: 'https://www.thehotline.org',
        description: '24/7 confidential support for victims.',
        country: 'US',
      ),
      SafetyResource(
        name: 'RAINN',
        phone: '1-800-656-4673',
        url: 'https://www.rainn.org',
        description: 'Free, confidential 24/7 support.',
        country: 'US',
      ),
      // United Kingdom
      SafetyResource(
        name: 'National Domestic Abuse Helpline',
        phone: '0808 2000 247',
        url: 'https://www.nationaldahelpline.org.uk',
        description: 'UK 24-hour freephone helpline.',
        country: 'GB',
      ),
      // New Zealand
      SafetyResource(
        name: 'Women\'s Refuge NZ',
        phone: '0800 733 843',
        url: 'https://www.womensrefuge.org.nz',
        description: 'NZ crisis line for women & children.',
        country: 'NZ',
      ),
      // Global
      SafetyResource(
        name: 'Crisis Text Line',
        phone: 'Text HOME to 741741',
        url: 'https://www.crisistextline.org',
        description: 'Text-based crisis counseling.',
      ),
      SafetyResource(
        name: 'National Suicide Prevention Lifeline',
        phone: '988',
        url: 'https://988lifeline.org',
        description: '24/7 free and confidential support.',
        country: 'US',
      ),
    ];
  }

  // ── Gym Safety Rating ────────────────────────────────────────────

  /// Rate a gym's safety culture (1-5 stars).
  Future<void> rateGymSafety({
    required String userId,
    required String gymId,
    required int rating,
    String? comment,
  }) async {
    final ratingClamped = rating.clamp(1, 5);
    await _db
        .collection('gym_safety_ratings')
        .doc(gymId)
        .collection('ratings')
        .doc(userId)
        .set({
          'userId': userId,
          'rating': ratingClamped,
          'comment': comment,
          'createdAt': FieldValue.serverTimestamp(),
        });

    // Update aggregate
    final ratingsSnap = await _db
        .collection('gym_safety_ratings')
        .doc(gymId)
        .collection('ratings')
        .get();
    final total = ratingsSnap.docs.fold<int>(
      0,
      (acc, d) => acc + ((d.data()['rating'] as int?) ?? 0),
    );
    final count = ratingsSnap.docs.length;
    final average = count > 0 ? total / count : 0.0;

    await _db.collection('gym_safety_ratings').doc(gymId).set({
      'gymId': gymId,
      'averageRating': average,
      'totalRatings': count,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get average safety rating for a gym.
  Future<double> getGymSafetyRating(String gymId) async {
    try {
      final doc = await _db.collection('gym_safety_ratings').doc(gymId).get();
      if (!doc.exists) return 0.0;
      return (doc.data()?['averageRating'] as num?)?.toDouble() ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  // ── Public Safety & Threat Warnings ──────────────────────────────

  /// Get threat warnings for a specific location/area.
  Future<List<ThreatWarning>> getThreatWarnings({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
  }) async {
    try {
      final snap = await _db
          .collection('threat_warnings')
          .where('isActive', isEqualTo: true)
          .orderBy('startDate', descending: true)
          .limit(50)
          .get();

      return snap.docs.map((d) => ThreatWarning.fromMap(d.id, d.data())).where((
        w,
      ) {
        if (w.latitude == null || w.longitude == null) return true;
        final dlat = (w.latitude! - latitude).abs();
        final dlng = (w.longitude! - longitude).abs();
        final approxKm = (dlat * 111.0) + (dlng * 85.0);
        return approxKm <= (w.radiusKm ?? radiusKm);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Check threat level for an area based on demographics and intelligence.
  Future<ThreatLevel> checkAreaThreatLevel({
    required String city,
    required String country,
  }) async {
    try {
      // Check explicit area threat level document
      final doc = await _db
          .collection('area_threat_levels')
          .doc('${country}_${city.toLowerCase().replaceAll(' ', '_')}')
          .get();
      if (doc.exists) {
        final level = doc.data()?['threatLevel'] as String?;
        return ThreatLevel.values.firstWhere(
          (t) => t.name == level,
          orElse: () => ThreatLevel.low,
        );
      }

      // Check crowd-sourced concern density (last 30 days)
      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      final concerns = await _db
          .collection('area_concerns')
          .where('country', isEqualTo: country)
          .where('city', isEqualTo: city)
          .where('reportedAt', isGreaterThan: Timestamp.fromDate(cutoff))
          .get();

      final count = concerns.docs.length;
      if (count >= 20) return ThreatLevel.critical;
      if (count >= 10) return ThreatLevel.high;
      if (count >= 5) return ThreatLevel.medium;
      return ThreatLevel.low;
    } catch (_) {
      return ThreatLevel.low;
    }
  }

  /// Report a safety concern in an area (crowd-sourced intelligence).
  Future<void> reportAreaConcern({
    required String userId,
    required double latitude,
    required double longitude,
    required String concernType,
    required String description,
    bool isAnonymous = false,
  }) async {
    await _db.collection('area_concerns').add({
      'userId': isAnonymous ? 'anonymous' : userId,
      'reporterUserId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'concernType': concernType,
      'description': description,
      'isAnonymous': isAnonymous,
      'status': 'pending_review',
      'reportedAt': FieldValue.serverTimestamp(),
      'reviewedBy': null,
      'escalated': false,
    });

    // Check if area needs auto-escalation (5+ reports in last 7 days)
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final recentSnap = await _db
        .collection('area_concerns')
        .where('latitude', isGreaterThan: latitude - 0.05)
        .where('latitude', isLessThan: latitude + 0.05)
        .get();

    final nearby = recentSnap.docs.where((d) {
      final ts = d.data()['reportedAt'] as Timestamp?;
      if (ts == null) return false;
      return ts.toDate().isAfter(cutoff);
    }).length;

    if (nearby >= 5) {
      await _db.collection('admin_escalations').add({
        'type': 'area_concern_cluster',
        'latitude': latitude,
        'longitude': longitude,
        'concernType': concernType,
        'reportCount': nearby,
        'escalatedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    }
  }

  /// Get active threat warnings for user's current location.
  List<ThreatWarning> getActiveThreats({
    required String? userCity,
    required String? userCountry,
  }) {
    // Demo data - in production, fetch from Firestore + intelligence APIs
    return [
      ThreatWarning(
        id: 'tw_001',
        title: 'Religious Tension Alert',
        description:
            'Heightened tensions between communities reported in surrounding areas. Avoid large gatherings and politically sensitive locations.',
        threatLevel: ThreatLevel.medium,
        city: 'Example City',
        country: 'Example Country',
        categories: ['religious_tension', 'civil_unrest'],
        isActive: true,
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 7)),
      ),
      ThreatWarning(
        id: 'tw_002',
        title: 'Terrorism Risk Advisory',
        description:
            'Intelligence indicates potential for antisocial/terrorist activity in areas with high-density religious populations. Remain vigilant, report suspicious behavior to authorities.',
        threatLevel: ThreatLevel.high,
        country: 'Example Country',
        categories: ['terrorism', 'security'],
        isActive: true,
        startDate: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }

  /// Get safety recommendations for current threat level.
  List<String> getSafetyRecommendations(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.critical:
        return [
          '🚨 CRITICAL THREAT — Avoid Area Immediately',
          '🚨 Shelter In Place — Do Not Travel',
          '🚨 Contact Emergency Services: 000 / 911 / 999',
          '🚨 Monitor Official News & Government Alerts',
          '🚨 Have Emergency Exit Plan Ready',
        ];
      case ThreatLevel.high:
        return [
          '⚠️ HIGH THREAT — Exercise Extreme Caution',
          '⚠️ Avoid Large Crowds & Public Gatherings',
          '⚠️ Stay Alert to Surroundings at All Times',
          '⚠️ Share Your Location with Trusted Contacts',
          '⚠️ Have Guardian Mode Set Up & Ready',
          '⚠️ Report Suspicious Activity to Authorities',
        ];
      case ThreatLevel.medium:
        return [
          '⚠️ MEDIUM THREAT — Stay Vigilant',
          '💡 Avoid Politically/Religiously Sensitive Areas',
          '💡 Stay Informed via Official Sources',
          '💡 Have Emergency Contacts Ready',
          '💡 Trust Your Instincts — Leave if Uncomfortable',
        ];
      case ThreatLevel.low:
        return [
          '✅ LOW THREAT — Normal Precautions',
          '💡 Maintain General Awareness',
          '💡 Know Emergency Numbers for Your Area',
          '💡 Guardian Mode Available if Needed',
        ];
    }
  }
}

// ── Supporting Models ────────────────────────────────────────────────

class EmergencyContact {
  final String name;
  final String phone;
  final String relationship;

  const EmergencyContact({
    required this.name,
    required this.phone,
    required this.relationship,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'relationship': relationship,
  };

  factory EmergencyContact.fromMap(Map<String, dynamic> m) => EmergencyContact(
    name: m['name'] as String? ?? '',
    phone: m['phone'] as String? ?? '',
    relationship: m['relationship'] as String? ?? '',
  );
}

class SafetyResource {
  final String name;
  final String phone;
  final String url;
  final String description;
  final String country;

  const SafetyResource({
    required this.name,
    required this.phone,
    required this.url,
    required this.description,
    this.country = 'GLOBAL',
  });
}

// ── Threat Warning System Models ─────────────────────────────────────

enum ThreatLevel {
  low,
  medium,
  high,
  critical;

  String get displayName {
    switch (this) {
      case ThreatLevel.low:
        return 'LOW';
      case ThreatLevel.medium:
        return 'MEDIUM';
      case ThreatLevel.high:
        return 'HIGH';
      case ThreatLevel.critical:
        return 'CRITICAL';
    }
  }

  String get emoji {
    switch (this) {
      case ThreatLevel.low:
        return '✅';
      case ThreatLevel.medium:
        return '⚠️';
      case ThreatLevel.high:
        return '🚨';
      case ThreatLevel.critical:
        return '🆘';
    }
  }
}

class ThreatWarning {
  final String id;
  final String title;
  final String description;
  final ThreatLevel threatLevel;
  final String? city;
  final String country;
  final List<String>
  categories; // 'religious_tension', 'terrorism', 'civil_unrest', 'gang_activity', 'security'
  final bool isActive;
  final DateTime startDate;
  final DateTime? endDate; // null = ongoing
  final double? latitude;
  final double? longitude;
  final double? radiusKm;

  const ThreatWarning({
    required this.id,
    required this.title,
    required this.description,
    required this.threatLevel,
    this.city,
    required this.country,
    required this.categories,
    required this.isActive,
    required this.startDate,
    this.endDate,
    this.latitude,
    this.longitude,
    this.radiusKm,
  });

  factory ThreatWarning.fromMap(String id, Map<String, dynamic> m) {
    return ThreatWarning(
      id: id,
      title: m['title'] as String? ?? '',
      description: m['description'] as String? ?? '',
      threatLevel: ThreatLevel.values.firstWhere(
        (t) => t.name == (m['threatLevel'] as String?),
        orElse: () => ThreatLevel.low,
      ),
      city: m['city'] as String?,
      country: m['country'] as String? ?? '',
      categories: List<String>.from(m['categories'] ?? []),
      isActive: m['isActive'] as bool? ?? true,
      startDate: (m['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (m['endDate'] as Timestamp?)?.toDate(),
      latitude: (m['latitude'] as num?)?.toDouble(),
      longitude: (m['longitude'] as num?)?.toDouble(),
      radiusKm: (m['radiusKm'] as num?)?.toDouble(),
    );
  }

  bool get isNational => city == null;
  bool get isOngoing => endDate == null;

  String get locationDisplay {
    if (city != null) return '$city, $country';
    return country;
  }

  String get durationDisplay {
    if (isOngoing) return 'Ongoing';
    final now = DateTime.now();
    final daysRemaining = endDate!.difference(now).inDays;
    if (daysRemaining <= 0) return 'Expires today';
    return 'Active for $daysRemaining more days';
  }
}
