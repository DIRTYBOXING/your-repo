// ═══════════════════════════════════════════════════════════════════════════
// DFC REFERRAL & POINTS SYSTEM SERVICE
// ═══════════════════════════════════════════════════════════════════════════
// Points-based viral loop — earn through referrals, unlock premium features
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Point earning actions
enum PointAction {
  // Acquisition
  referralSignup, // Someone signs up with your code
  referralSubscribes, // Your referral upgrades to paid
  // Engagement
  dailyLogin,
  shareContent,
  shareFighterCard,
  sharePrediction,
  firstPrediction,
  correctPrediction,
  createPost,
  receiveLike,
  receiveComment,

  // Profile
  completeProfile,
  verifyFighter,
  connectSocial,

  // Community
  helpfulAnswer,
  reportContent,
  eventCheckIn,
}

/// Point values for each action
const Map<PointAction, int> pointValues = {
  // Acquisition (highest value)
  PointAction.referralSignup: 500,
  PointAction.referralSubscribes: 1000,

  // Engagement
  PointAction.dailyLogin: 10,
  PointAction.shareContent: 25,
  PointAction.shareFighterCard: 50,
  PointAction.sharePrediction: 50,
  PointAction.firstPrediction: 100,
  PointAction.correctPrediction: 75,
  PointAction.createPost: 15,
  PointAction.receiveLike: 5,
  PointAction.receiveComment: 10,

  // Profile
  PointAction.completeProfile: 200,
  PointAction.verifyFighter: 500,
  PointAction.connectSocial: 100,

  // Community
  PointAction.helpfulAnswer: 50,
  PointAction.reportContent: 25,
  PointAction.eventCheckIn: 100,
};

/// Reward tiers
class RewardTier {
  final int pointsRequired;
  final String name;
  final String icon;
  final String reward;
  final String rewardType;
  final Map<String, dynamic>? rewardData;

  const RewardTier({
    required this.pointsRequired,
    required this.name,
    required this.icon,
    required this.reward,
    required this.rewardType,
    this.rewardData,
  });
}

/// All available reward tiers
const List<RewardTier> rewardTiers = [
  // Entry rewards
  RewardTier(
    pointsRequired: 100,
    name: 'Fighter Initiate',
    icon: '🥊',
    reward: 'Custom profile badge',
    rewardType: 'badge',
    rewardData: {'badgeId': 'initiate'},
  ),
  RewardTier(
    pointsRequired: 250,
    name: 'Ring Ready',
    icon: '🔔',
    reward: '5 bonus AI questions',
    rewardType: 'ai_credits',
    rewardData: {'credits': 5},
  ),

  // Bronze tier
  RewardTier(
    pointsRequired: 500,
    name: 'Bronze Warrior',
    icon: '🥉',
    reward: '1 week Warrior trial',
    rewardType: 'subscription_trial',
    rewardData: {'tier': 'warrior', 'days': 7},
  ),
  RewardTier(
    pointsRequired: 750,
    name: 'Corner Coach',
    icon: '🎯',
    reward: 'Exclusive training tips pack',
    rewardType: 'content_unlock',
    rewardData: {'packId': 'training_tips_v1'},
  ),

  // Silver tier
  RewardTier(
    pointsRequired: 1000,
    name: 'Silver Striker',
    icon: '🥈',
    reward: '15 bonus AI questions',
    rewardType: 'ai_credits',
    rewardData: {'credits': 15},
  ),
  RewardTier(
    pointsRequired: 1500,
    name: 'Fight Analyst',
    icon: '📊',
    reward: 'Predictions accuracy badge',
    rewardType: 'badge',
    rewardData: {'badgeId': 'analyst'},
  ),

  // Gold tier
  RewardTier(
    pointsRequired: 2000,
    name: 'Gold Champion',
    icon: '🥇',
    reward: '1 month Warrior free',
    rewardType: 'subscription_free',
    rewardData: {'tier': 'warrior', 'days': 30},
  ),
  RewardTier(
    pointsRequired: 3000,
    name: 'Combat Elite',
    icon: '⚔️',
    reward: 'DFC merchandise discount',
    rewardType: 'discount',
    rewardData: {'code': 'ELITE30', 'percent': 30},
  ),

  // Platinum tier
  RewardTier(
    pointsRequired: 5000,
    name: 'Platinum Legend',
    icon: '💎',
    reward: '3 months Warrior free',
    rewardType: 'subscription_free',
    rewardData: {'tier': 'warrior', 'days': 90},
  ),
  RewardTier(
    pointsRequired: 7500,
    name: 'Hall of Fame',
    icon: '🏆',
    reward: 'Lifetime verified badge + priority support',
    rewardType: 'lifetime_perk',
    rewardData: {'badge': 'hall_of_fame', 'support': true},
  ),

  // Ultimate tier
  RewardTier(
    pointsRequired: 10000,
    name: 'DFC OG',
    icon: '👑',
    reward: '1 year Warrior + exclusive OG badge',
    rewardType: 'subscription_free',
    rewardData: {'tier': 'warrior', 'days': 365, 'badge': 'og'},
  ),
];

/// User points summary
class UserPointsSummary {
  final int totalPoints;
  final int lifetimePoints;
  final int referralCount;
  final int subscriptionReferrals;
  final String referralCode;
  final List<String> unlockedRewards;
  final DateTime? lastEarnedAt;

  UserPointsSummary({
    required this.totalPoints,
    required this.lifetimePoints,
    required this.referralCount,
    required this.subscriptionReferrals,
    required this.referralCode,
    required this.unlockedRewards,
    this.lastEarnedAt,
  });

  factory UserPointsSummary.empty(String referralCode) => UserPointsSummary(
    totalPoints: 0,
    lifetimePoints: 0,
    referralCount: 0,
    subscriptionReferrals: 0,
    referralCode: referralCode,
    unlockedRewards: [],
  );

  RewardTier? get currentTier {
    for (int i = rewardTiers.length - 1; i >= 0; i--) {
      if (lifetimePoints >= rewardTiers[i].pointsRequired) {
        return rewardTiers[i];
      }
    }
    return null;
  }

  RewardTier? get nextTier {
    for (final tier in rewardTiers) {
      if (lifetimePoints < tier.pointsRequired) {
        return tier;
      }
    }
    return null;
  }

  int get pointsToNextTier {
    final next = nextTier;
    if (next == null) return 0;
    return next.pointsRequired - lifetimePoints;
  }

  double get progressToNextTier {
    final current = currentTier;
    final next = nextTier;
    if (next == null) return 1.0;

    final currentThreshold = current?.pointsRequired ?? 0;
    final range = next.pointsRequired - currentThreshold;
    final progress = lifetimePoints - currentThreshold;

    return (progress / range).clamp(0.0, 1.0);
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// REFERRAL POINTS SERVICE
/// ═══════════════════════════════════════════════════════════════════════════
class ReferralPointsService {
  static final ReferralPointsService _instance =
      ReferralPointsService._internal();
  factory ReferralPointsService() => _instance;
  ReferralPointsService._internal();

  final _db = FirebaseFirestore.instance;

  /// Generate unique referral code for user
  String generateReferralCode(String userId) {
    final prefix = userId.substring(0, 4).toUpperCase();
    final random = DateTime.now().millisecondsSinceEpoch.toString().substring(
      8,
    );
    return 'DFC$prefix$random';
  }

  /// Get user's points summary
  Future<UserPointsSummary> getUserPoints(String userId) async {
    try {
      final doc = await _db.collection('user_points').doc(userId).get();

      if (!doc.exists) {
        final code = generateReferralCode(userId);
        await _initializeUserPoints(userId, code);
        return UserPointsSummary.empty(code);
      }

      final data = doc.data()!;
      return UserPointsSummary(
        totalPoints: data['totalPoints'] as int? ?? 0,
        lifetimePoints: data['lifetimePoints'] as int? ?? 0,
        referralCount: data['referralCount'] as int? ?? 0,
        subscriptionReferrals: data['subscriptionReferrals'] as int? ?? 0,
        referralCode:
            data['referralCode'] as String? ?? generateReferralCode(userId),
        unlockedRewards: List<String>.from(data['unlockedRewards'] ?? []),
        lastEarnedAt: (data['lastEarnedAt'] as Timestamp?)?.toDate(),
      );
    } catch (e) {
      debugPrint('[ReferralPoints] Error getting points: $e');
      return UserPointsSummary.empty(generateReferralCode(userId));
    }
  }

  /// Initialize points for new user
  Future<void> _initializeUserPoints(String userId, String referralCode) async {
    await _db.collection('user_points').doc(userId).set({
      'totalPoints': 0,
      'lifetimePoints': 0,
      'referralCount': 0,
      'subscriptionReferrals': 0,
      'referralCode': referralCode,
      'unlockedRewards': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Also store referral code mapping
    await _db.collection('referral_codes').doc(referralCode).set({
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Award points for an action
  Future<int> awardPoints(
    String userId,
    PointAction action, {
    String? metadata,
  }) async {
    final points = pointValues[action] ?? 0;
    if (points == 0) return 0;

    try {
      // Update points
      await _db.collection('user_points').doc(userId).set({
        'totalPoints': FieldValue.increment(points),
        'lifetimePoints': FieldValue.increment(points),
        'lastEarnedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Log the earning
      await _db
          .collection('user_points')
          .doc(userId)
          .collection('history')
          .add({
            'action': action.name,
            'points': points,
            'metadata': metadata,
            'createdAt': FieldValue.serverTimestamp(),
          });

      debugPrint('[ReferralPoints] Awarded $points points for ${action.name}');

      // Check for new tier unlocks
      await _checkTierUnlocks(userId);

      return points;
    } catch (e) {
      debugPrint('[ReferralPoints] Error awarding points: $e');
      return 0;
    }
  }

  /// Process referral signup
  Future<void> processReferral(String newUserId, String referralCode) async {
    try {
      // Find the referrer
      final codeDoc = await _db
          .collection('referral_codes')
          .doc(referralCode)
          .get();
      if (!codeDoc.exists) {
        debugPrint('[ReferralPoints] Invalid referral code: $referralCode');
        return;
      }

      final referrerId = codeDoc.data()!['userId'] as String;

      // Award points to referrer
      await awardPoints(
        referrerId,
        PointAction.referralSignup,
        metadata: newUserId,
      );

      // Update referral count
      await _db.collection('user_points').doc(referrerId).update({
        'referralCount': FieldValue.increment(1),
      });

      // Track the referral relationship
      await _db.collection('referrals').add({
        'referrerId': referrerId,
        'referredId': newUserId,
        'code': referralCode,
        'hasSubscribed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
        '[ReferralPoints] Processed referral: $referrerId -> $newUserId',
      );
    } catch (e) {
      debugPrint('[ReferralPoints] Error processing referral: $e');
    }
  }

  /// Process when a referred user subscribes
  Future<void> processReferralSubscription(String subscriberId) async {
    try {
      // Find the referral relationship
      final query = await _db
          .collection('referrals')
          .where('referredId', isEqualTo: subscriberId)
          .where('hasSubscribed', isEqualTo: false)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return;

      final referral = query.docs.first;
      final referrerId = referral.data()['referrerId'] as String;

      // Award bonus points
      await awardPoints(
        referrerId,
        PointAction.referralSubscribes,
        metadata: subscriberId,
      );

      // Update stats
      await _db.collection('user_points').doc(referrerId).update({
        'subscriptionReferrals': FieldValue.increment(1),
      });

      // Mark referral as subscribed
      await referral.reference.update({'hasSubscribed': true});

      debugPrint(
        '[ReferralPoints] Referral subscription bonus awarded to $referrerId',
      );
    } catch (e) {
      debugPrint('[ReferralPoints] Error processing referral subscription: $e');
    }
  }

  /// Check and process tier unlocks
  Future<void> _checkTierUnlocks(String userId) async {
    final summary = await getUserPoints(userId);

    for (final tier in rewardTiers) {
      if (summary.lifetimePoints >= tier.pointsRequired &&
          !summary.unlockedRewards.contains(tier.name)) {
        // Unlock the reward
        await _db.collection('user_points').doc(userId).update({
          'unlockedRewards': FieldValue.arrayUnion([tier.name]),
        });

        // Create notification
        await _db.collection('notifications').add({
          'userId': userId,
          'type': 'reward_unlocked',
          'title': '${tier.icon} New Reward Unlocked!',
          'body': 'You\'ve reached ${tier.name}! ${tier.reward}',
          'data': tier.rewardData,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Apply the reward
        await _applyReward(userId, tier);
      }
    }
  }

  /// Apply a tier reward
  Future<void> _applyReward(String userId, RewardTier tier) async {
    switch (tier.rewardType) {
      case 'ai_credits':
        final credits = tier.rewardData?['credits'] as int? ?? 0;
        await _db.collection('users').doc(userId).update({
          'bonusAICredits': FieldValue.increment(credits),
        });
        break;

      case 'subscription_trial':
      case 'subscription_free':
        final days = tier.rewardData?['days'] as int? ?? 0;
        final endDate = DateTime.now().add(Duration(days: days));
        await _db.collection('subscriptions').doc(userId).set({
          'tier': tier.rewardData?['tier'] ?? 'warrior',
          'source': 'points_reward',
          'rewardTier': tier.name,
          'expiresAt': Timestamp.fromDate(endDate),
        }, SetOptions(merge: true));
        break;

      case 'badge':
        final badgeId = tier.rewardData?['badgeId'] as String?;
        if (badgeId != null) {
          await _db.collection('users').doc(userId).update({
            'badges': FieldValue.arrayUnion([badgeId]),
          });
        }
        break;

      case 'discount':
        // Store discount code for user
        final discountKey = tier.rewardData?['code'] as String? ?? 'REWARD';
        await _db.collection('user_discounts').doc(userId).set({
          discountKey: {
            'percent': tier.rewardData?['percent'],
            'source': tier.name,
            'createdAt': FieldValue.serverTimestamp(),
          },
        }, SetOptions(merge: true));
        break;
    }
  }

  /// Spend points (for future point marketplace)
  Future<bool> spendPoints(String userId, int amount, String reason) async {
    final summary = await getUserPoints(userId);
    if (summary.totalPoints < amount) return false;

    try {
      await _db.collection('user_points').doc(userId).update({
        'totalPoints': FieldValue.increment(-amount),
      });

      await _db
          .collection('user_points')
          .doc(userId)
          .collection('history')
          .add({
            'action': 'spend',
            'points': -amount,
            'reason': reason,
            'createdAt': FieldValue.serverTimestamp(),
          });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 20}) async {
    final query = await _db
        .collection('user_points')
        .orderBy('lifetimePoints', descending: true)
        .limit(limit)
        .get();

    return query.docs.map((doc) => {'userId': doc.id, ...doc.data()}).toList();
  }

  /// Get referral link
  String getReferralLink(String referralCode) {
    return 'https://datafightcentral.com/join?ref=$referralCode';
  }

  /// Get share text
  String getShareText(String referralCode) {
    return '🥊 Join me on DataFight Central - the combat sports OS!\n\n'
        'Use my code: $referralCode\n'
        '${getReferralLink(referralCode)}\n\n'
        '#DFC #MMA #Boxing #CombatSports';
  }
}
