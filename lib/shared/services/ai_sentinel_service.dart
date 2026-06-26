import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// AI SENTINEL SERVICE — Platform-wide Content & User Protection Engine
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Multi-layer protection system:
///   Layer 1: Real-time content scanning (text, images, links)
///   Layer 2: Defamation detection (fighter & promoter protection)
///   Layer 3: Reputation scoring (user trust levels)
///   Layer 4: Athlete protection (targeted harassment detection)
///   Layer 5: Incident response (auto-escalation workflow)
///
/// Integrates with:
///   • AIModerationService — keyword + AI content checks
///   • NinjaModerationService — combat-specific filtering
///   • LiveChatService — real-time chat moderation
///   • SocialService — post & comment filtering
///   • PPVCommandChatService — event chat protection
///
/// Firestore collections:
///   sentinel_incidents/{incidentId}  — flagged content records
///   sentinel_scores/{userId}         — user reputation scores
///   sentinel_config/global           — detection thresholds/rules
///   sentinel_appeals/{appealId}      — user appeals
/// ═══════════════════════════════════════════════════════════════════════════

// ─── Enums ───────────────────────────────────────────────────────────────

enum ThreatLevel { none, low, medium, high, critical }

enum IncidentType {
  hate,
  harassment,
  defamation,
  impersonation,
  doxxing,
  spam,
  scam,
  explicitContent,
  threatOfViolence,
  matchFixing,
  copyrightViolation,
}

enum IncidentStatus { detected, reviewing, actioned, dismissed, appealed }

enum ContentSource { post, comment, chatMessage, ppvChat, profile, listing }

enum ActionTaken {
  none,
  warned,
  contentRemoved,
  muted,
  suspended,
  banned,
  escalatedToAdmin,
}

enum ReputationTier { trusted, neutral, watchlist, restricted, banned }

// ─── Models ──────────────────────────────────────────────────────────────

class SentinelIncident {
  final String id;
  final String contentId;
  final String contentText;
  final ContentSource source;
  final String reportedUserId;
  final String? reportedByUserId;
  final IncidentType type;
  final ThreatLevel threatLevel;
  final IncidentStatus status;
  final ActionTaken action;
  final double confidenceScore;
  final String? aiReasoning;
  final String? adminNotes;
  final DateTime detectedAt;
  final DateTime? resolvedAt;

  const SentinelIncident({
    required this.id,
    required this.contentId,
    required this.contentText,
    required this.source,
    required this.reportedUserId,
    this.reportedByUserId,
    required this.type,
    required this.threatLevel,
    this.status = IncidentStatus.detected,
    this.action = ActionTaken.none,
    required this.confidenceScore,
    this.aiReasoning,
    this.adminNotes,
    required this.detectedAt,
    this.resolvedAt,
  });

  Map<String, dynamic> toFirestore() => {
    'contentId': contentId,
    'contentText': contentText,
    'source': source.name,
    'reportedUserId': reportedUserId,
    'reportedByUserId': reportedByUserId,
    'type': type.name,
    'threatLevel': threatLevel.name,
    'status': status.name,
    'action': action.name,
    'confidenceScore': confidenceScore,
    'aiReasoning': aiReasoning,
    'adminNotes': adminNotes,
    'detectedAt': Timestamp.fromDate(detectedAt),
    'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
  };

  factory SentinelIncident.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SentinelIncident(
      id: doc.id,
      contentId: d['contentId'] ?? '',
      contentText: d['contentText'] ?? '',
      source: ContentSource.values.firstWhere(
        (e) => e.name == d['source'],
        orElse: () => ContentSource.post,
      ),
      reportedUserId: d['reportedUserId'] ?? '',
      reportedByUserId: d['reportedByUserId'],
      type: IncidentType.values.firstWhere(
        (e) => e.name == d['type'],
        orElse: () => IncidentType.harassment,
      ),
      threatLevel: ThreatLevel.values.firstWhere(
        (e) => e.name == d['threatLevel'],
        orElse: () => ThreatLevel.low,
      ),
      status: IncidentStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => IncidentStatus.detected,
      ),
      action: ActionTaken.values.firstWhere(
        (e) => e.name == d['action'],
        orElse: () => ActionTaken.none,
      ),
      confidenceScore: (d['confidenceScore'] ?? 0).toDouble(),
      aiReasoning: d['aiReasoning'],
      adminNotes: d['adminNotes'],
      detectedAt: (d['detectedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (d['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class ReputationScore {
  final String userId;
  final double score; // 0.0 = worst, 100.0 = perfect
  final ReputationTier tier;
  final int totalIncidents;
  final int resolvedIncidents;
  final int warningCount;
  final int banCount;
  final DateTime lastUpdated;
  final List<String> flags;

  const ReputationScore({
    required this.userId,
    required this.score,
    required this.tier,
    this.totalIncidents = 0,
    this.resolvedIncidents = 0,
    this.warningCount = 0,
    this.banCount = 0,
    required this.lastUpdated,
    this.flags = const [],
  });

  Map<String, dynamic> toFirestore() => {
    'score': score,
    'tier': tier.name,
    'totalIncidents': totalIncidents,
    'resolvedIncidents': resolvedIncidents,
    'warningCount': warningCount,
    'banCount': banCount,
    'lastUpdated': Timestamp.fromDate(lastUpdated),
    'flags': flags,
  };

  factory ReputationScore.fromFirestore(String userId, DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReputationScore(
      userId: userId,
      score: (d['score'] ?? 75.0).toDouble(),
      tier: ReputationTier.values.firstWhere(
        (e) => e.name == d['tier'],
        orElse: () => ReputationTier.neutral,
      ),
      totalIncidents: d['totalIncidents'] ?? 0,
      resolvedIncidents: d['resolvedIncidents'] ?? 0,
      warningCount: d['warningCount'] ?? 0,
      banCount: d['banCount'] ?? 0,
      lastUpdated: (d['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      flags: List<String>.from(d['flags'] ?? []),
    );
  }
}

class AthleteProtectionProfile {
  final String fighterId;
  final String fighterName;
  final bool isProtected;
  final int defamationAttempts;
  final int harassmentAttempts;
  final int impersonationAttempts;
  final List<String> protectedTerms;
  final DateTime createdAt;

  const AthleteProtectionProfile({
    required this.fighterId,
    required this.fighterName,
    this.isProtected = true,
    this.defamationAttempts = 0,
    this.harassmentAttempts = 0,
    this.impersonationAttempts = 0,
    this.protectedTerms = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() => {
    'fighterName': fighterName,
    'isProtected': isProtected,
    'defamationAttempts': defamationAttempts,
    'harassmentAttempts': harassmentAttempts,
    'impersonationAttempts': impersonationAttempts,
    'protectedTerms': protectedTerms,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory AthleteProtectionProfile.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AthleteProtectionProfile(
      fighterId: doc.id,
      fighterName: d['fighterName'] ?? '',
      isProtected: d['isProtected'] ?? true,
      defamationAttempts: d['defamationAttempts'] ?? 0,
      harassmentAttempts: d['harassmentAttempts'] ?? 0,
      impersonationAttempts: d['impersonationAttempts'] ?? 0,
      protectedTerms: List<String>.from(d['protectedTerms'] ?? []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// ─── Detection Patterns ──────────────────────────────────────────────────

class _DetectionPatterns {
  static const defamationKeywords = [
    'fraud',
    'cheat',
    'rigged',
    'fixed fight',
    'took a dive',
    'juicing',
    'on steroids',
    'fake record',
    'padded record',
    'ducking',
    'coward',
    'bum',
    'can crusher',
  ];

  static const harassmentKeywords = [
    'kill yourself',
    'kys',
    'die',
    'threat',
    'doxx',
    'your address',
    'your family',
    'stalk',
    'swat',
    'expose',
    'leaked',
    'revenge',
  ];

  static const hateKeywords = [
    // Monitored patterns — actual slurs not stored in source
    'racist',
    'sexist',
    'homophob',
    'bigot',
    'supremac',
    'genocide',
  ];

  static const scamPatterns = [
    'free money',
    'guaranteed return',
    'send crypto',
    'wire transfer',
    'nigerian prince',
    'investment opportunity',
    'dm me for',
    'click this link',
    'verify your account',
  ];

  static const matchFixingPatterns = [
    'fix the fight',
    'throw the fight',
    'take a dive',
    'bet on',
    'insider tip',
    'guaranteed win',
    'rigged',
    'fixed outcome',
  ];
}

// ─── Service ─────────────────────────────────────────────────────────────

class AISentinelService extends ChangeNotifier {
  AISentinelService._();
  static final AISentinelService _instance = AISentinelService._();
  factory AISentinelService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Content Scanning ────────────────────────────────────────────────

  /// Scans content for threats. Returns threat assessment.
  Future<SentinelScanResult> scanContent({
    required String content,
    required String userId,
    required ContentSource source,
    String? targetFighterId,
  }) async {
    final lowerContent = content.toLowerCase();
    var maxThreat = ThreatLevel.none;
    IncidentType? detectedType;
    double confidence = 0.0;
    String? reasoning;

    // Layer 1: Hate speech
    for (final kw in _DetectionPatterns.hateKeywords) {
      if (lowerContent.contains(kw)) {
        maxThreat = ThreatLevel.high;
        detectedType = IncidentType.hate;
        confidence = 0.85;
        reasoning = 'Hate speech pattern detected: content contains "$kw"';
        break;
      }
    }

    // Layer 2: Harassment / threats
    if (maxThreat.index < ThreatLevel.high.index) {
      for (final kw in _DetectionPatterns.harassmentKeywords) {
        if (lowerContent.contains(kw)) {
          maxThreat = ThreatLevel.critical;
          detectedType = IncidentType.harassment;
          confidence = 0.90;
          reasoning = 'Harassment/threat pattern: content contains "$kw"';
          break;
        }
      }
    }

    // Layer 3: Defamation (especially for fighters)
    if (maxThreat.index < ThreatLevel.medium.index) {
      for (final kw in _DetectionPatterns.defamationKeywords) {
        if (lowerContent.contains(kw)) {
          maxThreat = ThreatLevel.medium;
          detectedType = IncidentType.defamation;
          confidence = 0.70;
          reasoning = 'Potential defamation: content contains "$kw"';

          if (targetFighterId != null) {
            maxThreat = ThreatLevel.high;
            confidence = 0.82;
            reasoning =
                'Defamation targeting registered fighter: "$kw" directed at fighter $targetFighterId';
          }
          break;
        }
      }
    }

    // Layer 4: Scam detection
    if (maxThreat == ThreatLevel.none) {
      for (final pattern in _DetectionPatterns.scamPatterns) {
        if (lowerContent.contains(pattern)) {
          maxThreat = ThreatLevel.medium;
          detectedType = IncidentType.scam;
          confidence = 0.75;
          reasoning = 'Scam pattern detected: "$pattern"';
          break;
        }
      }
    }

    // Layer 5: Match fixing
    if (maxThreat == ThreatLevel.none) {
      for (final pattern in _DetectionPatterns.matchFixingPatterns) {
        if (lowerContent.contains(pattern)) {
          maxThreat = ThreatLevel.high;
          detectedType = IncidentType.matchFixing;
          confidence = 0.80;
          reasoning = 'Match fixing indicator: "$pattern"';
          break;
        }
      }
    }

    // Log incident if threat detected
    if (maxThreat != ThreatLevel.none && detectedType != null) {
      await _logIncident(
        contentId: '${source.name}_${DateTime.now().millisecondsSinceEpoch}',
        contentText: content,
        source: source,
        reportedUserId: userId,
        type: detectedType,
        threatLevel: maxThreat,
        confidenceScore: confidence,
        aiReasoning: reasoning,
      );

      // Auto-action for critical threats
      if (maxThreat == ThreatLevel.critical) {
        await _autoAction(userId, detectedType);
      }
    }

    return SentinelScanResult(
      threatLevel: maxThreat,
      incidentType: detectedType,
      confidence: confidence,
      reasoning: reasoning,
      isBlocked: maxThreat.index >= ThreatLevel.high.index,
    );
  }

  /// Check if content should be blocked before posting
  Future<bool> shouldBlockContent(String content, String userId) async {
    final result = await scanContent(
      content: content,
      userId: userId,
      source: ContentSource.post,
    );
    return result.isBlocked;
  }

  // ─── Incident Management ─────────────────────────────────────────────

  Future<void> _logIncident({
    required String contentId,
    required String contentText,
    required ContentSource source,
    required String reportedUserId,
    String? reportedByUserId,
    required IncidentType type,
    required ThreatLevel threatLevel,
    required double confidenceScore,
    String? aiReasoning,
  }) async {
    final incident = SentinelIncident(
      id: '',
      contentId: contentId,
      contentText: contentText,
      source: source,
      reportedUserId: reportedUserId,
      reportedByUserId: reportedByUserId,
      type: type,
      threatLevel: threatLevel,
      confidenceScore: confidenceScore,
      aiReasoning: aiReasoning,
      detectedAt: DateTime.now(),
    );

    await _firestore
        .collection('sentinel_incidents')
        .add(incident.toFirestore());

    // Update user reputation
    await _adjustReputation(reportedUserId, threatLevel);

    notifyListeners();
  }

  /// Manual user report
  Future<void> reportContent({
    required String contentId,
    required String contentText,
    required ContentSource source,
    required String reportedUserId,
    required String reportedByUserId,
    required IncidentType type,
  }) async {
    await _logIncident(
      contentId: contentId,
      contentText: contentText,
      source: source,
      reportedUserId: reportedUserId,
      reportedByUserId: reportedByUserId,
      type: type,
      threatLevel: ThreatLevel.medium,
      confidenceScore: 0.5,
      aiReasoning: 'User-reported content',
    );
  }

  Stream<List<SentinelIncident>> streamIncidents({
    IncidentStatus? statusFilter,
    int limit = 50,
  }) {
    var query = _firestore
        .collection('sentinel_incidents')
        .orderBy('detectedAt', descending: true)
        .limit(limit);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.name);
    }

    return query.snapshots().map(
      (snap) =>
          snap.docs.map(SentinelIncident.fromFirestore).toList(),
    );
  }

  Future<void> resolveIncident(
    String incidentId,
    ActionTaken action, {
    String? adminNotes,
  }) async {
    await _firestore.collection('sentinel_incidents').doc(incidentId).update({
      'status': IncidentStatus.actioned.name,
      'action': action.name,
      'adminNotes': adminNotes,
      'resolvedAt': Timestamp.now(),
    });
    notifyListeners();
  }

  Future<void> dismissIncident(String incidentId, {String? reason}) async {
    await _firestore.collection('sentinel_incidents').doc(incidentId).update({
      'status': IncidentStatus.dismissed.name,
      'adminNotes': reason ?? 'Dismissed by admin',
      'resolvedAt': Timestamp.now(),
    });
    notifyListeners();
  }

  // ─── Reputation System ───────────────────────────────────────────────

  Future<ReputationScore> getUserReputation(String userId) async {
    final doc = await _firestore
        .collection('sentinel_scores')
        .doc(userId)
        .get();

    if (!doc.exists) {
      return ReputationScore(
        userId: userId,
        score: 75.0,
        tier: ReputationTier.neutral,
        lastUpdated: DateTime.now(),
      );
    }

    return ReputationScore.fromFirestore(userId, doc);
  }

  Future<void> _adjustReputation(String userId, ThreatLevel threat) async {
    final current = await getUserReputation(userId);
    final double penalty = switch (threat) {
      ThreatLevel.none => 0,
      ThreatLevel.low => -2,
      ThreatLevel.medium => -5,
      ThreatLevel.high => -15,
      ThreatLevel.critical => -30,
    };

    final newScore = (current.score + penalty).clamp(0.0, 100.0);
    final newTier = _tierFromScore(newScore);
    final newWarnings = threat.index >= ThreatLevel.medium.index
        ? current.warningCount + 1
        : current.warningCount;

    await _firestore.collection('sentinel_scores').doc(userId).set({
      'score': newScore,
      'tier': newTier.name,
      'totalIncidents': current.totalIncidents + 1,
      'resolvedIncidents': current.resolvedIncidents,
      'warningCount': newWarnings,
      'banCount': current.banCount,
      'lastUpdated': Timestamp.now(),
      'flags': current.flags,
    });
  }

  ReputationTier _tierFromScore(double score) {
    if (score >= 80) return ReputationTier.trusted;
    if (score >= 50) return ReputationTier.neutral;
    if (score >= 25) return ReputationTier.watchlist;
    if (score >= 10) return ReputationTier.restricted;
    return ReputationTier.banned;
  }

  // ─── Athlete Protection ──────────────────────────────────────────────

  Future<void> registerAthleteProtection({
    required String fighterId,
    required String fighterName,
    List<String> additionalTerms = const [],
  }) async {
    final nameParts = fighterName.toLowerCase().split(' ');
    final protectedTerms = [
      ...nameParts,
      fighterName.toLowerCase(),
      ...additionalTerms.map((t) => t.toLowerCase()),
    ];

    final profile = AthleteProtectionProfile(
      fighterId: fighterId,
      fighterName: fighterName,
      protectedTerms: protectedTerms,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('athlete_protection')
        .doc(fighterId)
        .set(profile.toFirestore());
  }

  Future<SentinelScanResult> scanForAthleteDefamation(
    String content,
    String userId,
  ) async {
    final lowerContent = content.toLowerCase();

    // Check against all protected athletes
    final protectedSnap = await _firestore
        .collection('athlete_protection')
        .get();

    for (final doc in protectedSnap.docs) {
      final profile = AthleteProtectionProfile.fromFirestore(doc);
      final nameMatch = profile.protectedTerms.any(
        lowerContent.contains,
      );

      if (nameMatch) {
        // Check if content also contains defamation keywords
        for (final kw in _DetectionPatterns.defamationKeywords) {
          if (lowerContent.contains(kw)) {
            await _logIncident(
              contentId: 'athlete_${DateTime.now().millisecondsSinceEpoch}',
              contentText: content,
              source: ContentSource.post,
              reportedUserId: userId,
              type: IncidentType.defamation,
              threatLevel: ThreatLevel.high,
              confidenceScore: 0.85,
              aiReasoning:
                  'Defamation against protected athlete ${profile.fighterName}: "$kw"',
            );

            // Increment defamation counter
            await _firestore
                .collection('athlete_protection')
                .doc(profile.fighterId)
                .update({'defamationAttempts': FieldValue.increment(1)});

            return SentinelScanResult(
              threatLevel: ThreatLevel.high,
              incidentType: IncidentType.defamation,
              confidence: 0.85,
              reasoning:
                  'Content defames protected athlete: ${profile.fighterName}',
              isBlocked: true,
            );
          }
        }
      }
    }

    return const SentinelScanResult(
      threatLevel: ThreatLevel.none,
      isBlocked: false,
    );
  }

  // ─── Auto-Actions ────────────────────────────────────────────────────

  Future<void> _autoAction(String userId, IncidentType type) async {
    final rep = await getUserReputation(userId);

    if (rep.score < 10 || rep.warningCount >= 5) {
      // Auto-ban repeat offenders
      await _firestore.collection('sentinel_scores').doc(userId).update({
        'tier': ReputationTier.banned.name,
        'banCount': FieldValue.increment(1),
        'flags': FieldValue.arrayUnion(['auto_banned_${type.name}']),
      });
    }
  }

  // ─── Dashboard Stats ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSentinelStats() async {
    final incidents = await _firestore.collection('sentinel_incidents').get();

    final int total = incidents.docs.length;
    int active = 0;
    int resolved = 0;
    final Map<String, int> byType = {};
    final Map<String, int> byThreat = {};

    for (final doc in incidents.docs) {
      final d = doc.data();
      final status = d['status'] ?? 'detected';
      if (status == 'actioned' || status == 'dismissed') {
        resolved++;
      } else {
        active++;
      }
      final type = d['type'] ?? 'unknown';
      byType[type] = (byType[type] ?? 0) + 1;
      final threat = d['threatLevel'] ?? 'low';
      byThreat[threat] = (byThreat[threat] ?? 0) + 1;
    }

    return {
      'totalIncidents': total,
      'activeIncidents': active,
      'resolvedIncidents': resolved,
      'byType': byType,
      'byThreat': byThreat,
    };
  }
}

// ─── Scan Result ─────────────────────────────────────────────────────────

class SentinelScanResult {
  final ThreatLevel threatLevel;
  final IncidentType? incidentType;
  final double confidence;
  final String? reasoning;
  final bool isBlocked;

  const SentinelScanResult({
    required this.threatLevel,
    this.incidentType,
    this.confidence = 0.0,
    this.reasoning,
    required this.isBlocked,
  });
}
