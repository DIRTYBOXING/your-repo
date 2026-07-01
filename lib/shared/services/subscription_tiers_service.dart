// ═══════════════════════════════════════════════════════════════════════════
// DFC SUBSCRIPTION TIERS SERVICE
// ═══════════════════════════════════════════════════════════════════════════
// Revenue foundation — 5 tiers from free to promoter
// Integrates with Stripe for billing
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Subscription tier levels
enum SubscriptionTier { free, warrior, coach, gym, promoter }

/// Feature flags for each tier
class TierFeatures {
  final int aiQuestionsPerDay;
  final bool unlimitedAI;
  final bool predictions;
  final bool trainingLog;
  final bool analytics;
  final int maxAthletes;
  final bool scheduling;
  final bool athleteDashboards;
  final bool sessionNotes;
  final bool unlimitedMembers;
  final bool classManagement;
  final bool revenueTracking;
  final bool eventCreation;
  final bool liveStreaming;
  final bool fighterContracts;
  final bool ticketSales;
  final bool prioritySupport;
  final bool verifiedBadge;
  final bool customBranding;

  const TierFeatures({
    this.aiQuestionsPerDay = 3,
    this.unlimitedAI = false,
    this.predictions = false,
    this.trainingLog = false,
    this.analytics = false,
    this.maxAthletes = 0,
    this.scheduling = false,
    this.athleteDashboards = false,
    this.sessionNotes = false,
    this.unlimitedMembers = false,
    this.classManagement = false,
    this.revenueTracking = false,
    this.eventCreation = false,
    this.liveStreaming = false,
    this.fighterContracts = false,
    this.ticketSales = false,
    this.prioritySupport = false,
    this.verifiedBadge = false,
    this.customBranding = false,
  });
}

/// Subscription tier definition
class SubscriptionTierDef {
  final SubscriptionTier tier;
  final String name;
  final String tagline;
  final double monthlyPrice;
  final double yearlyPrice;
  final String stripePriceIdMonthly;
  final String stripePriceIdYearly;
  final TierFeatures features;
  final List<String> highlights;
  final String emoji;
  final String colorHex;
  final String targetAudience;

  const SubscriptionTierDef({
    required this.tier,
    required this.name,
    required this.tagline,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.stripePriceIdMonthly,
    required this.stripePriceIdYearly,
    required this.features,
    required this.highlights,
    required this.emoji,
    required this.colorHex,
    required this.targetAudience,
  });

  bool get isFree => monthlyPrice == 0;
  double get yearlySavings => (monthlyPrice * 12) - yearlyPrice;
  int get yearlySavingsPercent => monthlyPrice > 0
      ? ((yearlySavings / (monthlyPrice * 12)) * 100).round()
      : 0;
}

/// ═══════════════════════════════════════════════════════════════════════════
/// SUBSCRIPTION TIERS SERVICE
/// ═══════════════════════════════════════════════════════════════════════════
class SubscriptionTiersService {
  static final SubscriptionTiersService _instance =
      SubscriptionTiersService._internal();
  factory SubscriptionTiersService() => _instance;
  SubscriptionTiersService._internal();

  final _db = FirebaseFirestore.instance;

  /// All available tiers
  static const List<SubscriptionTierDef> tiers = [
    // FREE
    SubscriptionTierDef(
      tier: SubscriptionTier.free,
      name: 'Free',
      tagline: 'Get started with DFC',
      monthlyPrice: 0,
      yearlyPrice: 0,
      stripePriceIdMonthly: '',
      stripePriceIdYearly: '',
      emoji: '👊',
      colorHex: '#6B7280', // Gray
      targetAudience: 'Fans & Casual Users',
      highlights: [
        'Full social feed access',
        'Fighter profiles & records',
        '3 AI questions per day',
        'Community forums',
        'Event calendar',
      ],
      features: TierFeatures(
        
      ),
    ),

    // WARRIOR
    SubscriptionTierDef(
      tier: SubscriptionTier.warrior,
      name: 'Warrior',
      tagline: 'Train like a champion',
      monthlyPrice: 7.99,
      yearlyPrice: 79.99,
      stripePriceIdMonthly: 'price_1T7r4EPcqZu7NL6NlwqBwl37',
      stripePriceIdYearly: 'price_1T7r4EPcqZu7NL6NlwqBwl37',
      emoji: '⚔️',
      colorHex: '#00D9FF', // Neon Cyan
      targetAudience: 'Active Fighters',
      highlights: [
        'Unlimited Shido AI coaching',
        'Fight predictions & analysis',
        'Personal training log',
        'Performance analytics',
        'Verified fighter badge',
        'Priority feed placement',
      ],
      features: TierFeatures(
        aiQuestionsPerDay: -1, // Unlimited
        unlimitedAI: true,
        predictions: true,
        trainingLog: true,
        analytics: true,
        verifiedBadge: true,
      ),
    ),

    // COACH
    SubscriptionTierDef(
      tier: SubscriptionTier.coach,
      name: 'Coach',
      tagline: 'Build champions',
      monthlyPrice: 29.99,
      yearlyPrice: 299.99,
      stripePriceIdMonthly: 'price_1T7r4XPcqZu7NL6NRQJevavp',
      stripePriceIdYearly: 'price_1T7r4XPcqZu7NL6NRQJevavp',
      emoji: '🎯',
      colorHex: '#FF6B35', // Orange
      targetAudience: 'Professional Coaches',
      highlights: [
        'Everything in Warrior',
        'Manage up to 10 athletes',
        'Session scheduling',
        'Athlete dashboards',
        'Training session notes',
        'Team performance reports',
        'Coach verified badge',
      ],
      features: TierFeatures(
        aiQuestionsPerDay: -1,
        unlimitedAI: true,
        predictions: true,
        trainingLog: true,
        analytics: true,
        maxAthletes: 10,
        scheduling: true,
        athleteDashboards: true,
        sessionNotes: true,
        verifiedBadge: true,
      ),
    ),

    // GYM
    SubscriptionTierDef(
      tier: SubscriptionTier.gym,
      name: 'Gym',
      tagline: 'Run your empire',
      monthlyPrice: 79.99,
      yearlyPrice: 799.99,
      stripePriceIdMonthly: 'price_1T7r4dPcqZu7NL6NuGQNVc0V',
      stripePriceIdYearly: 'price_1T7r4dPcqZu7NL6NuGQNVc0V',
      emoji: '🏟️',
      colorHex: '#A855F7', // Purple
      targetAudience: 'Gym Owners',
      highlights: [
        'Everything in Coach',
        'Unlimited members',
        'Class scheduling & management',
        'Revenue tracking & reports',
        'Member check-in system',
        'Gym profile page',
        'Custom branding',
        'Priority support',
      ],
      features: TierFeatures(
        aiQuestionsPerDay: -1,
        unlimitedAI: true,
        predictions: true,
        trainingLog: true,
        analytics: true,
        maxAthletes: -1, // Unlimited
        scheduling: true,
        athleteDashboards: true,
        sessionNotes: true,
        unlimitedMembers: true,
        classManagement: true,
        revenueTracking: true,
        prioritySupport: true,
        verifiedBadge: true,
        customBranding: true,
      ),
    ),

    // PROMOTER
    SubscriptionTierDef(
      tier: SubscriptionTier.promoter,
      name: 'Promoter',
      tagline: 'Build the show',
      monthlyPrice: 199.00,
      yearlyPrice: 1999.00,
      stripePriceIdMonthly: 'price_1T7r4dPcqZu7NL6NuGQNVc0V',
      stripePriceIdYearly: 'price_1T7r4dPcqZu7NL6NuGQNVc0V',
      emoji: '🎬',
      colorHex: '#EAB308', // Gold
      targetAudience: 'Event Promoters',
      highlights: [
        'Everything in Gym',
        'Event creation & management',
        'Live streaming (PPV ready)',
        'Fighter contract management',
        'Ticket sales integration',
        'Matchmaking tools',
        'Event analytics',
        'White-label options',
        'Dedicated account manager',
      ],
      features: TierFeatures(
        aiQuestionsPerDay: -1,
        unlimitedAI: true,
        predictions: true,
        trainingLog: true,
        analytics: true,
        maxAthletes: -1,
        scheduling: true,
        athleteDashboards: true,
        sessionNotes: true,
        unlimitedMembers: true,
        classManagement: true,
        revenueTracking: true,
        eventCreation: true,
        liveStreaming: true,
        fighterContracts: true,
        ticketSales: true,
        prioritySupport: true,
        verifiedBadge: true,
        customBranding: true,
      ),
    ),
  ];

  /// Get tier by enum
  static SubscriptionTierDef getTier(SubscriptionTier tier) {
    return tiers.firstWhere((t) => t.tier == tier);
  }

  /// Get tier by name
  static SubscriptionTierDef? getTierByName(String name) {
    try {
      return tiers.firstWhere(
        (t) => t.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Check if user has feature access
  Future<bool> hasFeature(String userId, String featureName) async {
    final userTier = await getUserTier(userId);
    final tierDef = getTier(userTier);

    switch (featureName) {
      case 'unlimitedAI':
        return tierDef.features.unlimitedAI;
      case 'predictions':
        return tierDef.features.predictions;
      case 'trainingLog':
        return tierDef.features.trainingLog;
      case 'analytics':
        return tierDef.features.analytics;
      case 'scheduling':
        return tierDef.features.scheduling;
      case 'eventCreation':
        return tierDef.features.eventCreation;
      case 'liveStreaming':
        return tierDef.features.liveStreaming;
      default:
        return false;
    }
  }

  /// Get user's current tier
  Future<SubscriptionTier> getUserTier(String userId) async {
    try {
      final doc = await _db.collection('subscriptions').doc(userId).get();
      if (!doc.exists) return SubscriptionTier.free;

      final data = doc.data()!;
      final tierName = data['tier'] as String? ?? 'free';

      return SubscriptionTier.values.firstWhere(
        (t) => t.name == tierName,
        orElse: () => SubscriptionTier.free,
      );
    } catch (e) {
      debugPrint('[SubscriptionTiers] Error getting user tier: $e');
      return SubscriptionTier.free;
    }
  }

  /// Get remaining AI questions for today
  Future<int> getRemainingAIQuestions(String userId) async {
    final tier = await getUserTier(userId);
    final tierDef = getTier(tier);

    if (tierDef.features.unlimitedAI) return -1; // Unlimited

    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month}-${today.day}';

      final doc = await _db
          .collection('ai_usage')
          .doc(userId)
          .collection('daily')
          .doc(dateKey)
          .get();

      final used = doc.data()?['questions'] as int? ?? 0;
      return (tierDef.features.aiQuestionsPerDay - used).clamp(
        0,
        tierDef.features.aiQuestionsPerDay,
      );
    } catch (e) {
      return tierDef.features.aiQuestionsPerDay;
    }
  }

  /// Record AI question usage
  Future<void> recordAIQuestion(String userId) async {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';

    await _db
        .collection('ai_usage')
        .doc(userId)
        .collection('daily')
        .doc(dateKey)
        .set({
          'questions': FieldValue.increment(1),
          'lastUsed': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  /// Upgrade user tier (after Stripe payment)
  Future<void> upgradeTier({
    required String userId,
    required SubscriptionTier tier,
    required String stripeSubscriptionId,
    required bool isYearly,
  }) async {
    await _db.collection('subscriptions').doc(userId).set({
      'tier': tier.name,
      'stripeSubscriptionId': stripeSubscriptionId,
      'isYearly': isYearly,
      'startedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Update user document
    await _db.collection('users').doc(userId).update({
      'subscriptionTier': tier.name,
      'isPro': tier != SubscriptionTier.free,
    });
  }

  /// Cancel subscription
  Future<void> cancelSubscription(String userId) async {
    await _db.collection('subscriptions').doc(userId).update({
      'cancelledAt': FieldValue.serverTimestamp(),
      'status': 'cancelled',
    });
  }

  /// Get upgrade path (what's next for user)
  static SubscriptionTierDef? getUpgradePath(SubscriptionTier currentTier) {
    final currentIndex = tiers.indexWhere((t) => t.tier == currentTier);
    if (currentIndex < tiers.length - 1) {
      return tiers[currentIndex + 1];
    }
    return null;
  }

  /// Compare two tiers
  static List<String> compareTiers(SubscriptionTier from, SubscriptionTier to) {
    final fromDef = getTier(from);
    final toDef = getTier(to);
    final newFeatures = <String>[];

    if (!fromDef.features.unlimitedAI && toDef.features.unlimitedAI) {
      newFeatures.add('Unlimited AI coaching');
    }
    if (!fromDef.features.predictions && toDef.features.predictions) {
      newFeatures.add('Fight predictions');
    }
    if (!fromDef.features.trainingLog && toDef.features.trainingLog) {
      newFeatures.add('Training log');
    }
    if (!fromDef.features.scheduling && toDef.features.scheduling) {
      newFeatures.add('Session scheduling');
    }
    if (fromDef.features.maxAthletes < toDef.features.maxAthletes) {
      newFeatures.add(
        'Manage ${toDef.features.maxAthletes == -1 ? "unlimited" : toDef.features.maxAthletes} athletes',
      );
    }
    if (!fromDef.features.eventCreation && toDef.features.eventCreation) {
      newFeatures.add('Event creation');
    }
    if (!fromDef.features.liveStreaming && toDef.features.liveStreaming) {
      newFeatures.add('Live streaming');
    }

    return newFeatures;
  }
}
