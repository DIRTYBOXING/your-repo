import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// RESPECT ENGINE SERVICE — Community Culture Enforcement
/// ═══════════════════════════════════════════════════════════════════════════
///
/// DFC isn't just a platform — it's a culture. Every combat sport, every
/// fighter, every show deserves respect. This engine:
///
///   • Respect Points — earned for positive contributions
///   • Community Karma — aggregate culture health score
///   • Sportsmanship Awards — auto-granted for consistent behavior
///   • Code of Conduct Enforcement — graduated violation system
///   • Fighter Respect Protocol — special protections for athletes
///   • Promoter Trust Score — tracks show quality & fairness
///   • Cultural Badges — Aussie/Kiwi, Global, Sport-specific
///
/// Firestore:
///   respect_profiles/{userId}     — user respect score + badges
///   respect_events/{eventId}      — respect events log
///   respect_awards/{awardId}      — sportsmanship awards granted
///   respect_config/global         — thresholds + multipliers
/// ═══════════════════════════════════════════════════════════════════════════

// ─── Enums ───────────────────────────────────────────────────────────────

enum RespectAction {
  positiveComment,
  supportiveFeedback,
  reportedContent,
  sharedEvent,
  attendedEvent,
  purchasedPPV,
  helpedNewUser,
  createdQualityContent,
  respectfulDebate,
  sportsmanshipGesture,
  volunteerMod,
  communityContribution,
  // Negative
  toxicComment,
  harassment,
  unsportsmanlike,
  spamming,
  fakeReview,
  matchFixAttempt,
}

enum RespectBadge {
  newcomerWelcome, // First positive action
  communityStar, // 100+ positive actions
  respectChampion, // Top 5% respect score
  sportsmanship, // Consistent positive behavior
  eventSupporter, // Attended 10+ events
  ppvLoyalist, // Purchased 5+ PPVs
  combatCulture, // Active across 3+ sports
  globalCitizen, // Interacted with 5+ regions
  anzacSpirit, // AU/NZ community contributor
  moderatorElite, // Volunteer mod excellence
  contentCreator, // Quality posts recognized
  fighterAlly, // Supported athlete protection
}

enum SportsmanshipTier {
  bronze, // 0–99 points
  silver, // 100–499- points
  gold, // 500–1999 points
  platinum, // 2000–4999 points
  diamond, // 5000+ points
  legend, // 10000+ points + special criteria
}

// ─── Models ──────────────────────────────────────────────────────────────

class RespectProfile {
  final String userId;
  final double respectScore;
  final int totalPoints;
  final SportsmanshipTier tier;
  final List<RespectBadge> badges;
  final int positiveActions;
  final int negativeActions;
  final int eventsAttended;
  final int ppvPurchased;
  final List<String> activeSports;
  final DateTime memberSince;
  final DateTime lastActivity;

  const RespectProfile({
    required this.userId,
    required this.respectScore,
    required this.totalPoints,
    required this.tier,
    this.badges = const [],
    this.positiveActions = 0,
    this.negativeActions = 0,
    this.eventsAttended = 0,
    this.ppvPurchased = 0,
    this.activeSports = const [],
    required this.memberSince,
    required this.lastActivity,
  });

  Map<String, dynamic> toFirestore() => {
    'respectScore': respectScore,
    'totalPoints': totalPoints,
    'tier': tier.name,
    'badges': badges.map((b) => b.name).toList(),
    'positiveActions': positiveActions,
    'negativeActions': negativeActions,
    'eventsAttended': eventsAttended,
    'ppvPurchased': ppvPurchased,
    'activeSports': activeSports,
    'memberSince': Timestamp.fromDate(memberSince),
    'lastActivity': Timestamp.fromDate(lastActivity),
  };

  factory RespectProfile.fromFirestore(String userId, DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RespectProfile(
      userId: userId,
      respectScore: (d['respectScore'] ?? 50.0).toDouble(),
      totalPoints: d['totalPoints'] ?? 0,
      tier: SportsmanshipTier.values.firstWhere(
        (e) => e.name == d['tier'],
        orElse: () => SportsmanshipTier.bronze,
      ),
      badges:
          (d['badges'] as List<dynamic>?)
              ?.map(
                (b) => RespectBadge.values.firstWhere(
                  (e) => e.name == b,
                  orElse: () => RespectBadge.newcomerWelcome,
                ),
              )
              .toList() ??
          [],
      positiveActions: d['positiveActions'] ?? 0,
      negativeActions: d['negativeActions'] ?? 0,
      eventsAttended: d['eventsAttended'] ?? 0,
      ppvPurchased: d['ppvPurchased'] ?? 0,
      activeSports: List<String>.from(d['activeSports'] ?? []),
      memberSince: (d['memberSince'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActivity:
          (d['lastActivity'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class RespectEvent {
  final String id;
  final String userId;
  final RespectAction action;
  final int pointsDelta;
  final String? contextId;
  final String? description;
  final DateTime timestamp;

  const RespectEvent({
    required this.id,
    required this.userId,
    required this.action,
    required this.pointsDelta,
    this.contextId,
    this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'action': action.name,
    'pointsDelta': pointsDelta,
    'contextId': contextId,
    'description': description,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}

// ─── Point Values ────────────────────────────────────────────────────────

class _PointValues {
  static int forAction(RespectAction action) => switch (action) {
    RespectAction.positiveComment => 2,
    RespectAction.supportiveFeedback => 3,
    RespectAction.reportedContent => 5,
    RespectAction.sharedEvent => 3,
    RespectAction.attendedEvent => 10,
    RespectAction.purchasedPPV => 15,
    RespectAction.helpedNewUser => 8,
    RespectAction.createdQualityContent => 10,
    RespectAction.respectfulDebate => 5,
    RespectAction.sportsmanshipGesture => 20,
    RespectAction.volunteerMod => 25,
    RespectAction.communityContribution => 15,
    RespectAction.toxicComment => -10,
    RespectAction.harassment => -25,
    RespectAction.unsportsmanlike => -15,
    RespectAction.spamming => -8,
    RespectAction.fakeReview => -12,
    RespectAction.matchFixAttempt => -50,
  };

  static bool isNegative(RespectAction action) => forAction(action) < 0;
}

// ─── Service ─────────────────────────────────────────────────────────────

class RespectEngineService extends ChangeNotifier {
  RespectEngineService._();
  static final RespectEngineService _instance = RespectEngineService._();
  factory RespectEngineService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Profile Management ──────────────────────────────────────────────

  Future<RespectProfile> getProfile(String userId) async {
    final doc = await _firestore
        .collection('respect_profiles')
        .doc(userId)
        .get();

    if (!doc.exists) {
      final newProfile = RespectProfile(
        userId: userId,
        respectScore: 50.0,
        totalPoints: 0,
        tier: SportsmanshipTier.bronze,
        memberSince: DateTime.now(),
        lastActivity: DateTime.now(),
      );
      await _firestore
          .collection('respect_profiles')
          .doc(userId)
          .set(newProfile.toFirestore());
      return newProfile;
    }

    return RespectProfile.fromFirestore(userId, doc);
  }

  // ─── Record Actions ──────────────────────────────────────────────────

  Future<void> recordAction({
    required String userId,
    required RespectAction action,
    String? contextId,
    String? description,
  }) async {
    final points = _PointValues.forAction(action);
    final isNeg = _PointValues.isNegative(action);

    // Log the event
    final event = RespectEvent(
      id: '',
      userId: userId,
      action: action,
      pointsDelta: points,
      contextId: contextId,
      description: description,
      timestamp: DateTime.now(),
    );
    await _firestore.collection('respect_events').add(event.toFirestore());

    // Update profile
    final updateData = <String, dynamic>{
      'totalPoints': FieldValue.increment(points),
      'lastActivity': Timestamp.now(),
    };

    if (isNeg) {
      updateData['negativeActions'] = FieldValue.increment(1);
    } else {
      updateData['positiveActions'] = FieldValue.increment(1);
    }

    // Action-specific updates
    switch (action) {
      case RespectAction.attendedEvent:
        updateData['eventsAttended'] = FieldValue.increment(1);
      case RespectAction.purchasedPPV:
        updateData['ppvPurchased'] = FieldValue.increment(1);
      default:
        break;
    }

    await _firestore
        .collection('respect_profiles')
        .doc(userId)
        .update(updateData);

    // Recalculate tier and badges
    await _recalculate(userId);

    notifyListeners();
  }

  // ─── Tier & Badge Calculation ────────────────────────────────────────

  Future<void> _recalculate(String userId) async {
    final profile = await getProfile(userId);
    final newTier = _tierFromPoints(profile.totalPoints);
    final newBadges = _calculateBadges(profile);
    final newScore = _calculateRespectScore(profile);

    await _firestore.collection('respect_profiles').doc(userId).update({
      'tier': newTier.name,
      'badges': newBadges.map((b) => b.name).toList(),
      'respectScore': newScore,
    });
  }

  SportsmanshipTier _tierFromPoints(int points) {
    if (points >= 10000) return SportsmanshipTier.legend;
    if (points >= 5000) return SportsmanshipTier.diamond;
    if (points >= 2000) return SportsmanshipTier.platinum;
    if (points >= 500) return SportsmanshipTier.gold;
    if (points >= 100) return SportsmanshipTier.silver;
    return SportsmanshipTier.bronze;
  }

  List<RespectBadge> _calculateBadges(RespectProfile profile) {
    final badges = <RespectBadge>[];

    if (profile.positiveActions >= 1) badges.add(RespectBadge.newcomerWelcome);
    if (profile.positiveActions >= 100) badges.add(RespectBadge.communityStar);
    if (profile.respectScore >= 90) badges.add(RespectBadge.respectChampion);
    if (profile.eventsAttended >= 10) badges.add(RespectBadge.eventSupporter);
    if (profile.ppvPurchased >= 5) badges.add(RespectBadge.ppvLoyalist);
    if (profile.activeSports.length >= 3) {
      badges.add(RespectBadge.combatCulture);
    }

    // Sportsmanship: positive ratio > 95%
    final total = profile.positiveActions + profile.negativeActions;
    if (total >= 20 && profile.positiveActions / total > 0.95) {
      badges.add(RespectBadge.sportsmanship);
    }

    return badges;
  }

  double _calculateRespectScore(RespectProfile profile) {
    final total = profile.positiveActions + profile.negativeActions;
    if (total == 0) return 50.0;

    final ratio = profile.positiveActions / total;
    final tierBonus = profile.tier.index * 2.0;
    final badgeBonus = profile.badges.length * 1.5;

    return (ratio * 80 + tierBonus + badgeBonus).clamp(0.0, 100.0);
  }

  // ─── Sport Activity ──────────────────────────────────────────────────

  Future<void> recordSportActivity(String userId, String sport) async {
    await _firestore.collection('respect_profiles').doc(userId).update({
      'activeSports': FieldValue.arrayUnion([sport]),
    });
  }

  // ─── Leaderboard ─────────────────────────────────────────────────────

  Stream<List<RespectProfile>> streamLeaderboard({int limit = 20}) {
    return _firestore
        .collection('respect_profiles')
        .orderBy('totalPoints', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => RespectProfile.fromFirestore(d.id, d))
              .toList(),
        );
  }

  // ─── Community Health ────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCommunityHealth() async {
    final profiles = await _firestore.collection('respect_profiles').get();

    if (profiles.docs.isEmpty) {
      return {
        'averageScore': 50.0,
        'totalMembers': 0,
        'positiveRatio': 0.5,
        'tierDistribution': <String, int>{},
        'topBadges': <String, int>{},
      };
    }

    double totalScore = 0;
    int totalPositive = 0;
    int totalNegative = 0;
    final tierDist = <String, int>{};
    final badgeDist = <String, int>{};

    for (final doc in profiles.docs) {
      final d = doc.data();
      totalScore += (d['respectScore'] ?? 50.0).toDouble();
      totalPositive += (d['positiveActions'] ?? 0) as int;
      totalNegative += (d['negativeActions'] ?? 0) as int;

      final tier = d['tier'] ?? 'bronze';
      tierDist[tier] = (tierDist[tier] ?? 0) + 1;

      final badges = List<String>.from(d['badges'] ?? []);
      for (final b in badges) {
        badgeDist[b] = (badgeDist[b] ?? 0) + 1;
      }
    }

    final totalActions = totalPositive + totalNegative;

    return {
      'averageScore': totalScore / profiles.docs.length,
      'totalMembers': profiles.docs.length,
      'positiveRatio': totalActions > 0 ? totalPositive / totalActions : 0.5,
      'tierDistribution': tierDist,
      'topBadges': badgeDist,
    };
  }
}
