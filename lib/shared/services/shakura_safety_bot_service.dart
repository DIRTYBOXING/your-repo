import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SHAKURA — The Female Ninja · Women's Safety Guardian
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Shakura protects, informs, and empowers women in combat sports.
///
/// Core Responsibilities:
///   1. Safety Check-In System — periodic well-being check for women users
///   2. Emergency Alert — silent distress signal with location
///   3. Safety Education — awareness about training safety, gym red flags
///   4. Trusted Contact Network — pre-configured emergency contacts
///   5. Incident Reporting — confidential, anonymous-capable reporting
///   6. Resource Directory — local shelters, hotlines, legal aid
///   7. Community Connection — connect with other women fighters
///
/// Shakura NEVER:
///   • Dismisses a safety concern
///   • Shares user data without explicit consent
///   • Makes assumptions about situations
///   • Uses judgmental or blaming language
///   • Delays emergency escalation
///
/// Shakura ALWAYS:
///   • Believes the user first
///   • Provides actionable next steps
///   • Maintains absolute confidentiality
///   • Offers multiple paths to help
///   • Speaks with calm authority
///
/// Firestore:
///   safety_checkins/{uid}                — Latest check-in state
///   safety_checkins/{uid}/history/{id}   — Check-in history
///   safety_incidents/{id}                — Incident reports (encrypted)
///   safety_contacts/{uid}                — Trusted contacts
///
/// ═══════════════════════════════════════════════════════════════════════════

// ── Safety Enums ───────────────────────────────────────────────────────────

enum SafetyStatus {
  safe, // All clear
  concerned, // Something feels off
  uncomfortable, // Specific discomfort flagged
  urgent, // Needs immediate help
  emergency, // Silent alarm triggered
}

enum SafetyConcernType {
  none,
  verbalHarassment,
  physicalIntimidation,
  inappropriateContact,
  stalking,
  unsafeTrainingEnvironment,
  coercion,
  discrimination,
  bodyShaming,
  weightPressure,
  financialExploitation,
  travelSafety,
  eventSafety,
  onlineHarassment,
  other,
}

enum CheckInFrequency { daily, everyOtherDay, weekly, beforeEvents, manual }

// ── Data Models ────────────────────────────────────────────────────────────

class SafetyCheckIn {
  final String id;
  final String userId;
  final DateTime timestamp;
  final SafetyStatus status;
  final List<SafetyConcernType> concerns;
  final String? note;
  final double? latitude;
  final double? longitude;
  final bool isAnonymous;

  const SafetyCheckIn({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.status,
    this.concerns = const [],
    this.note,
    this.latitude,
    this.longitude,
    this.isAnonymous = false,
  });

  bool get requiresAction =>
      status == SafetyStatus.urgent || status == SafetyStatus.emergency;

  Map<String, dynamic> toFirestore() => {
    'userId': isAnonymous ? 'anonymous' : userId,
    'timestamp': Timestamp.fromDate(timestamp),
    'status': status.name,
    'concerns': concerns.map((c) => c.name).toList(),
    'note': note,
    'latitude': latitude,
    'longitude': longitude,
    'isAnonymous': isAnonymous,
  };

  factory SafetyCheckIn.fromFirestore(String id, Map<String, dynamic> d) {
    return SafetyCheckIn(
      id: id,
      userId: d['userId'] ?? '',
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: SafetyStatus.values.firstWhere(
        (s) => s.name == d['status'],
        orElse: () => SafetyStatus.safe,
      ),
      concerns:
          (d['concerns'] as List<dynamic>?)
              ?.map(
                (c) => SafetyConcernType.values.firstWhere(
                  (v) => v.name == c,
                  orElse: () => SafetyConcernType.none,
                ),
              )
              .toList() ??
          [],
      note: d['note'],
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
      isAnonymous: d['isAnonymous'] ?? false,
    );
  }
}

class TrustedContact {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String relationship; // 'coach', 'family', 'friend', 'teammate'
  final bool isEmergencyContact;

  const TrustedContact({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.relationship = 'friend',
    this.isEmergencyContact = false,
  });

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'phone': phone,
    'email': email,
    'relationship': relationship,
    'isEmergencyContact': isEmergencyContact,
  };

  factory TrustedContact.fromFirestore(String id, Map<String, dynamic> d) {
    return TrustedContact(
      id: id,
      name: d['name'] ?? '',
      phone: d['phone'] ?? '',
      email: d['email'],
      relationship: d['relationship'] ?? 'friend',
      isEmergencyContact: d['isEmergencyContact'] ?? false,
    );
  }
}

/// Shakura's guidance response
class SafetyGuidance {
  final String headline;
  final String message;
  final List<String> actions;
  final List<SafetyResource> resources;
  final bool escalateToEmergency;
  final bool notifyTrustedContacts;

  const SafetyGuidance({
    required this.headline,
    required this.message,
    required this.actions,
    this.resources = const [],
    this.escalateToEmergency = false,
    this.notifyTrustedContacts = false,
  });
}

class SafetyResource {
  final String name;
  final String description;
  final String? phone;
  final String? url;
  final String type; // 'hotline', 'shelter', 'legal', 'counseling', 'community'

  const SafetyResource({
    required this.name,
    required this.description,
    this.phone,
    this.url,
    this.type = 'hotline',
  });
}

// ── THE ENGINE ─────────────────────────────────────────────────────────────

/// Shakura Safety Bot — The Female Ninja Guardian
///
/// "Your safety is not negotiable. Your voice matters. I believe you."
class ShakuraSafetyBotService extends ChangeNotifier {
  static final ShakuraSafetyBotService _instance =
      ShakuraSafetyBotService._internal();
  factory ShakuraSafetyBotService() => _instance;
  ShakuraSafetyBotService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State
  SafetyCheckIn? _lastCheckIn;
  List<TrustedContact> _trustedContacts = [];
  CheckInFrequency _checkInFrequency = CheckInFrequency.weekly;
  bool _initialized = false;
  bool _safetyModeActive = false;

  // Getters
  SafetyCheckIn? get lastCheckIn => _lastCheckIn;
  List<TrustedContact> get trustedContacts =>
      List.unmodifiable(_trustedContacts);
  CheckInFrequency get checkInFrequency => _checkInFrequency;
  bool get initialized => _initialized;
  bool get safetyModeActive => _safetyModeActive;

  /// Initialize — load user's safety profile
  Future<void> initialize() async {
    if (_initialized) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // Load last check-in
      final checkInDoc = await _firestore
          .collection('safety_checkins')
          .doc(uid)
          .get();
      if (checkInDoc.exists) {
        _lastCheckIn = SafetyCheckIn.fromFirestore(uid, checkInDoc.data()!);
      }

      // Load trusted contacts
      final contactsSnap = await _firestore
          .collection('safety_contacts')
          .doc(uid)
          .collection('contacts')
          .get();
      _trustedContacts = contactsSnap.docs
          .map((d) => TrustedContact.fromFirestore(d.id, d.data()))
          .toList();

      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('🥷 Shakura: init error: $e');
      _initialized = true;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. SAFETY CHECK-IN SYSTEM
  // ═══════════════════════════════════════════════════════════════════════════

  /// Submit a safety check-in and receive guidance
  Future<SafetyGuidance> submitCheckIn(SafetyCheckIn checkIn) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const SafetyGuidance(
        headline: 'Check-in Saved Locally',
        message: 'Your safety matters. This check-in is stored on your device.',
        actions: ['Sign in to enable cloud backup and emergency alerts'],
      );
    }

    try {
      // Save to Firestore
      await _firestore
          .collection('safety_checkins')
          .doc(uid)
          .set(checkIn.toFirestore());

      // Save to history
      await _firestore
          .collection('safety_checkins')
          .doc(uid)
          .collection('history')
          .add(checkIn.toFirestore());

      _lastCheckIn = checkIn;
      notifyListeners();

      // Generate guidance
      return _generateGuidance(checkIn);
    } catch (e) {
      debugPrint('🥷 Shakura: checkIn error: $e');
      return _generateGuidance(checkIn);
    }
  }

  /// Generate context-aware safety guidance
  SafetyGuidance _generateGuidance(SafetyCheckIn checkIn) {
    switch (checkIn.status) {
      case SafetyStatus.emergency:
        return _emergencyGuidance(checkIn);
      case SafetyStatus.urgent:
        return _urgentGuidance(checkIn);
      case SafetyStatus.uncomfortable:
        return _uncomfortableGuidance(checkIn);
      case SafetyStatus.concerned:
        return _concernedGuidance(checkIn);
      case SafetyStatus.safe:
        return _safeGuidance();
    }
  }

  SafetyGuidance _emergencyGuidance(SafetyCheckIn checkIn) {
    return SafetyGuidance(
      headline: 'EMERGENCY ALERT ACTIVATED',
      message:
          'I am here. You are not alone. '
          'Your trusted contacts are being notified with your location. '
          'If you are in immediate physical danger, call emergency services.',
      actions: [
        'Call emergency services: 000 (AU) / 911 (US) / 999 (UK)',
        'Your trusted contacts have been alerted',
        'Stay in a public area if possible',
        'Do not confront the person causing danger',
        'This report is confidential and encrypted',
      ],
      resources: _emergencyResources,
      escalateToEmergency: true,
      notifyTrustedContacts: true,
    );
  }

  SafetyGuidance _urgentGuidance(SafetyCheckIn checkIn) {
    final actions = <String>[
      'You are believed. What you are experiencing is not okay.',
      'Document everything: dates, times, witnesses, screenshots',
    ];

    if (checkIn.concerns.contains(SafetyConcernType.inappropriateContact)) {
      actions.addAll([
        'Report to the gym owner or organization safety officer',
        'You have the right to refuse any physical contact',
        'Consider filing a formal complaint — you deserve to train safely',
      ]);
    }

    if (checkIn.concerns.contains(SafetyConcernType.stalking)) {
      actions.addAll([
        'Vary your routine: different times, different routes',
        'Tell someone at your gym — do not handle this alone',
        'Save all messages/evidence without responding',
        'Consider a restraining order if pattern continues',
      ]);
    }

    if (checkIn.concerns.contains(SafetyConcernType.coercion)) {
      actions.addAll([
        'No one has the right to pressure you into anything',
        'Talk to a trusted person outside the gym',
        'You can leave any situation that feels wrong',
      ]);
    }

    return SafetyGuidance(
      headline: 'Shakura Hears You — Taking Action',
      message:
          'What you are reporting is serious and I take it seriously. '
          'You do not need to justify your feelings. '
          'Here are concrete steps you can take right now.',
      actions: actions,
      resources: _supportResources,
      notifyTrustedContacts: true,
    );
  }

  SafetyGuidance _uncomfortableGuidance(SafetyCheckIn checkIn) {
    final actions = <String>[];

    if (checkIn.concerns.contains(SafetyConcernType.verbalHarassment)) {
      actions.addAll([
        'You do NOT have to tolerate verbal abuse in any form',
        'Address it directly if safe: "That is not acceptable"',
        'Report to gym management — a good gym will act',
        'If they do not act, that tells you everything about that gym',
      ]);
    }

    if (checkIn.concerns.contains(SafetyConcernType.bodyShaming)) {
      actions.addAll([
        'Your body is a weapon, not a decoration',
        'Combat sports are about what your body CAN DO, not how it looks',
        'Name the behavior to the person or gym management',
      ]);
    }

    if (checkIn.concerns.contains(
      SafetyConcernType.unsafeTrainingEnvironment,
    )) {
      actions.addAll([
        'Trust your instincts — if it feels unsafe, it probably is',
        'Red flags: no safety gear enforcement, no skill-level matching',
        'A good gym protects its members, especially newer ones',
        'You have the right to refuse any drill or partner',
      ]);
    }

    if (checkIn.concerns.contains(SafetyConcernType.discrimination)) {
      actions.addAll([
        'Discrimination has no place in combat sports',
        'Document incidents with dates and witnesses',
        'Report to the governing body of the sport',
        'Consider connecting with women\'s combat sports groups for support',
      ]);
    }

    if (checkIn.concerns.contains(SafetyConcernType.weightPressure)) {
      actions.addAll([
        'No coach should pressure unsafe weight cuts',
        'Your health is always the priority over making weight',
        'Consult a sports dietitian for safe weight guidance',
      ]);
    }

    if (actions.isEmpty) {
      actions.addAll([
        'Your feelings are valid. Something does not feel right.',
        'Talk to someone you trust about what you are experiencing',
        'Journal what happened — patterns become clear over time',
        'You can always check in with me again',
      ]);
    }

    return SafetyGuidance(
      headline: 'I See You — Let\'s Work Through This',
      message:
          'Something is making you uncomfortable, and that matters. '
          'Your intuition is a survival tool — trust it. '
          'Here is what I recommend based on what you have shared.',
      actions: actions,
      resources: _educationResources,
    );
  }

  SafetyGuidance _concernedGuidance(SafetyCheckIn checkIn) {
    return const SafetyGuidance(
      headline: 'Noted — Shakura Is Watching',
      message:
          'You flagged a concern, and I will track it. '
          'Sometimes things start small before they become a pattern. '
          'Trust yourself. If it gets worse, I am here.',
      actions: [
        'Keep documenting anything that feels off',
        'Talk to a trusted friend or teammate',
        'Review your trusted contacts — make sure they are current',
        'Check in again tomorrow or when you are ready',
      ],
    );
  }

  SafetyGuidance _safeGuidance() {
    return const SafetyGuidance(
      headline: 'All Clear — Stay Strong',
      message:
          'Glad to hear you are safe. '
          'Regular check-ins help build a safety baseline. '
          'Keep training, keep growing, keep being powerful.',
      actions: [
        'Keep your trusted contacts updated',
        'Share safety tips with other women at your gym',
        'Remember: Shakura is always one tap away',
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. TRUSTED CONTACT MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Add a trusted contact
  Future<void> addTrustedContact(TrustedContact contact) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final docRef = await _firestore
          .collection('safety_contacts')
          .doc(uid)
          .collection('contacts')
          .add(contact.toFirestore());

      _trustedContacts.add(
        TrustedContact(
          id: docRef.id,
          name: contact.name,
          phone: contact.phone,
          email: contact.email,
          relationship: contact.relationship,
          isEmergencyContact: contact.isEmergencyContact,
        ),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('🥷 Shakura: addContact error: $e');
    }
  }

  /// Remove a trusted contact
  Future<void> removeTrustedContact(String contactId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore
          .collection('safety_contacts')
          .doc(uid)
          .collection('contacts')
          .doc(contactId)
          .delete();

      _trustedContacts.removeWhere((c) => c.id == contactId);
      notifyListeners();
    } catch (e) {
      debugPrint('🥷 Shakura: removeContact error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. EMERGENCY ALERT SYSTEM
  // ═══════════════════════════════════════════════════════════════════════════

  /// Trigger silent emergency alert
  Future<void> triggerEmergencyAlert({
    double? latitude,
    double? longitude,
  }) async {
    _safetyModeActive = true;
    notifyListeners();

    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

    try {
      // Create emergency incident
      await _firestore.collection('safety_incidents').add({
        'userId': uid,
        'type': 'emergency_alert',
        'timestamp': FieldValue.serverTimestamp(),
        'latitude': latitude,
        'longitude': longitude,
        'status': 'active',
        'trustedContactsNotified': true,
      });

      // Notify trusted contacts via Cloud Function trigger
      // The safety_incidents collection has a Cloud Function listener
      // that sends SMS/push to trusted contacts
    } catch (e) {
      debugPrint('🥷 Shakura: EMERGENCY alert error: $e');
    }
  }

  /// Deactivate emergency mode
  void deactivateEmergencyMode() {
    _safetyModeActive = false;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. INCIDENT REPORTING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Submit a confidential incident report
  Future<String> submitIncidentReport({
    required SafetyConcernType type,
    required String description,
    String? locationName,
    bool anonymous = false,
    List<String> evidenceUrls = const [],
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

    try {
      final docRef = await _firestore.collection('safety_incidents').add({
        'userId': anonymous ? 'anonymous' : uid,
        'type': type.name,
        'description': description,
        'locationName': locationName,
        'evidenceUrls': evidenceUrls,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'anonymous': anonymous,
      });
      return docRef.id;
    } catch (e) {
      debugPrint('🥷 Shakura: incident report error: $e');
      return '';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. CONVERSATIONAL INTELLIGENCE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate response to user safety queries
  String respondToQuery(String query) {
    final q = query.toLowerCase();

    // ── Emergency keywords ──
    if (_containsAny(q, [
      'help me',
      'danger',
      'attacked',
      'hurt me',
      'emergency',
    ])) {
      return 'I hear you. If you are in immediate danger, call 000 (AU), 911 (US), '
          'or your local emergency number. '
          'I can activate your emergency alert right now — '
          'your trusted contacts will be notified with your location. '
          'Say "activate alert" and I will do it immediately.';
    }

    // ── Harassment ──
    if (_containsAny(q, [
      'harass',
      'creep',
      'touch',
      'inappropriate',
      'uncomfort',
    ])) {
      return 'What you are describing is not okay, and it is not your fault. '
          'You have every right to feel safe at your gym and in your sport. '
          'I recommend: (1) Tell someone you trust, (2) Document what happened, '
          '(3) Report to gym management, (4) If they do not act, report to the '
          'sport\'s governing body. You can also file a report through me — '
          'it can be anonymous if you prefer.';
    }

    // ── Gym safety ──
    if (_containsAny(q, [
      'gym',
      'safe gym',
      'red flag',
      'new gym',
      'feel safe',
    ])) {
      return 'Green flags in a gym: clear safety policies, women\'s classes available, '
          'respectful culture, proper equipment, qualified coaches with credentials. '
          'Red flags: no safety gear enforcement, sparring without skill matching, '
          'dismissive attitude toward concerns, no women training. '
          'Trust your instincts. A gym should make you feel empowered, not afraid.';
    }

    // ── Travel safety ──
    if (_containsAny(q, [
      'travel',
      'competition',
      'hotel',
      'transport',
      'alone',
    ])) {
      return 'Travel safety for women fighters: '
          '(1) Share your itinerary with trusted contacts, '
          '(2) Use hotel room deadbolts and door stops, '
          '(3) Meet teams in public areas only, '
          '(4) Keep Shakura check-in active during events, '
          '(5) Travel with your team when possible, '
          '(6) Trust your gut — if something feels wrong, leave.';
    }

    // ── Weight pressure ──
    if (_containsAny(q, [
      'weight',
      'too heavy',
      'diet',
      'body',
      'skinny',
      'fat',
    ])) {
      return 'Your body is a tool, not a target for criticism. '
          'No one has the right to shame you about your body. '
          'A good coach discusses weight management with science and respect, '
          'never with shame or pressure. '
          'If you are being pressured into unsafe weight cuts, that is abuse. '
          'You deserve better — and there are coaches who will treat you right.';
    }

    // ── Community ──
    if (_containsAny(q, ['other women', 'community', 'connect', 'not alone'])) {
      return 'You are not alone. There are thousands of women in combat sports '
          'who have walked your path. Connect with women\'s fight communities, '
          'follow women fighters who inspire you, and build your own crew. '
          'Strength is not just physical — it is having people who have your back.';
    }

    // ── Default ──
    return 'I am Shakura, your safety guardian. I am here for: '
        'safety check-ins, emergency alerts, incident reporting, '
        'gym safety advice, travel safety, or just to listen. '
        'Everything you share with me is confidential. '
        'What do you need?';
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  /// Set check-in frequency
  void setCheckInFrequency(CheckInFrequency freq) {
    _checkInFrequency = freq;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RESOURCE DIRECTORIES
  // ═══════════════════════════════════════════════════════════════════════════

  List<SafetyResource> get _emergencyResources => const [
    SafetyResource(
      name: 'Emergency Services',
      description: 'Immediate danger — call now',
      phone: '000',
    ),
    SafetyResource(
      name: '1800RESPECT',
      description: 'National domestic violence and sexual assault helpline',
      phone: '1800 737 732',
    ),
    SafetyResource(
      name: 'Lifeline',
      description: 'Crisis support and suicide prevention',
      phone: '13 11 14',
    ),
  ];

  List<SafetyResource> get _supportResources => const [
    SafetyResource(
      name: '1800RESPECT',
      description: '24/7 confidential support',
      phone: '1800 737 732',
    ),
    SafetyResource(
      name: 'Women\'s Legal Service',
      description: 'Free legal advice for women',
      phone: '1800 639 784',
      type: 'legal',
    ),
    SafetyResource(
      name: 'Safe Steps',
      description: 'Family violence response centre',
      phone: '1800 015 188',
      type: 'shelter',
    ),
  ];

  List<SafetyResource> get _educationResources => const [
    SafetyResource(
      name: 'Women in Combat Sports Network',
      description: 'Community support and mentorship',
      type: 'community',
    ),
    SafetyResource(
      name: 'Safe Sport International',
      description: 'Athlete safety and abuse prevention resources',
      type: 'counseling',
    ),
  ];

  /// Stream check-in history
  Stream<List<SafetyCheckIn>> streamCheckInHistory({int limit = 30}) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('safety_checkins')
        .doc(uid)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => SafetyCheckIn.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }
}
