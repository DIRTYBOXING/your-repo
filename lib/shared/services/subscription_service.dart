import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription_plan.dart';

/// Subscription tier levels
///
/// Designed for ethical access - core safety features always free
enum SubscriptionTier {
  /// Free forever - access to core safety, basic community, limited AI
  free,

  /// Fighter Pro - $9.99/month
  /// Full AI coach, training analytics, fight recommendations
  fighterPro,

  /// Coach/Mentor - $14.99/month
  /// Team management, mentor badge, enhanced discovery
  coachMentor,

  /// Promoter/Gym - $29.99/month
  /// Event promotion, fighter database, business analytics
  promoterGym,

  /// Legacy - Grandfathered early adopter pricing
  legacy,
}

/// Feature flags for each tier
class SubscriptionFeatures {
  // Core safety - ALWAYS FREE
  static const List<String> freeFeatures = [
    'recovery_support_access', // 24/7 recovery support access
    'basic_community_feed', // View FightWire, limited posts
    'basic_health_tracking', // Manual health logging
    'safety_alerts', // Receive safety broadcasts
    'basic_profile', // Create fighter profile
    'discovery_basic', // Find nearby gyms (no diamonds)
    'ai_coach_limited', // 5 AI interactions/day
  ];

  static const List<String> fighterProFeatures = [
    ...freeFeatures,
    'ai_coach_unlimited', // Unlimited AI interactions
    'training_analytics', // Full camp analytics
    'fight_recommendations', // AI-powered matchmaking
    'weight_cut_tracker', // Scientific weight management
    'recovery_insights', // Detailed recovery analysis
    'media_library', // Training video storage
    'signal_priority', // Priority in signal feed
    'export_reports', // PDF fight reports
  ];

  static const List<String> coachMentorFeatures = [
    ...fighterProFeatures,
    'mentor_diamond_badge', // Diamond marker on map
    'team_management', // Manage multiple fighters
    'athlete_analytics', // View team performance
    'schedule_management', // Class and session scheduling
    'enhanced_discovery', // Featured in discovery
    'mentor_messaging', // Direct mentor messaging
    'certification_display', // Show credentials
  ];

  static const List<String> promoterGymFeatures = [
    ...coachMentorFeatures,
    'event_creation', // Create and manage events
    'fighter_database', // Search all fighters
    'business_analytics', // Revenue and engagement stats
    'featured_events', // Priority event promotion
    'bulk_messaging', // Broadcast to followers
    'api_access', // API for integrations
    'white_label_options', // Custom branding
  ];

  static List<String> getFeatures(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return freeFeatures;
      case SubscriptionTier.fighterPro:
        return fighterProFeatures;
      case SubscriptionTier.coachMentor:
        return coachMentorFeatures;
      case SubscriptionTier.promoterGym:
      case SubscriptionTier.legacy:
        return promoterGymFeatures;
    }
  }
}

/// Subscription plan info
class SubscriptionPlan {
  final SubscriptionTier tier;
  final String name;
  final String description;
  final double monthlyPrice;
  final double yearlyPrice;
  final List<String> highlights;
  final String stripePriceIdMonthly;
  final String stripePriceIdYearly;

  const SubscriptionPlan({
    required this.tier,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.highlights,
    required this.stripePriceIdMonthly,
    required this.stripePriceIdYearly,
  });

  static const List<SubscriptionPlan> allPlans = [
    SubscriptionPlan(
      tier: SubscriptionTier.free,
      name: 'Fighter Free',
      description: 'Core safety and community access forever',
      monthlyPrice: 0,
      yearlyPrice: 0,
      highlights: [
        'Crisis support access 24/7',
        'Basic community feed',
        'Find nearby gyms',
        '5 AI Coach interactions/day',
        'Safety alerts',
      ],
      stripePriceIdMonthly: '',
      stripePriceIdYearly: '',
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.fighterPro,
      name: 'Fighter Pro',
      description: 'Unlock your full potential',
      monthlyPrice: 9.99,
      yearlyPrice: 99.99,
      highlights: [
        'Unlimited AI Coach',
        'Full training analytics',
        'Fight recommendations',
        'Weight cut tracker',
        'Recovery insights',
        'Priority signal feed',
      ],
      stripePriceIdMonthly: 'price_1T7r4EPcqZu7NL6NlwqBwl37',
      stripePriceIdYearly: 'price_1T7r4PPcqZu7NL6NWzt4kWtr',
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.coachMentor,
      name: 'Coach & Mentor',
      description: 'Lead and inspire fighters',
      monthlyPrice: 14.99,
      yearlyPrice: 149.99,
      highlights: [
        'Everything in Fighter Pro',
        'Mentor Diamond Badge',
        'Team management',
        'Athlete analytics',
        'Enhanced discovery',
        'Direct mentor messaging',
      ],
      stripePriceIdMonthly: 'price_1T7r4XPcqZu7NL6NRQJevavp',
      stripePriceIdYearly: 'price_1T7r4aPcqZu7NL6NBc4JxJkc',
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.promoterGym,
      name: 'Promoter & Gym',
      description: 'Build your combat empire',
      monthlyPrice: 29.99,
      yearlyPrice: 299.99,
      highlights: [
        'Everything in Coach & Mentor',
        'Event creation & promotion',
        'Fighter database access',
        'Business analytics',
        'API access',
        'Bulk messaging',
      ],
      stripePriceIdMonthly: 'price_1T7r4dPcqZu7NL6NuGQNVc0V',
      stripePriceIdYearly: 'price_1T7r4gPcqZu7NL6NoAhqN5lZ',
    ),
  ];
}

/// User's subscription state
class UserSubscription {
  final String id;
  final String odUserId;
  final SubscriptionTier tier;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final bool isYearly;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final DateTime? trialEndDate;
  final bool isTrial;

  const UserSubscription({
    required this.id,
    required this.odUserId,
    required this.tier,
    required this.startDate,
    this.endDate,
    required this.isActive,
    this.isYearly = false,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.trialEndDate,
    this.isTrial = false,
  });

  factory UserSubscription.free(String userId) {
    return UserSubscription(
      id: 'free_$userId',
      odUserId: userId,
      tier: SubscriptionTier.free,
      startDate: DateTime.now(),
      isActive: true,
    );
  }

  factory UserSubscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserSubscription(
      id: doc.id,
      odUserId: data['userId'] ?? '',
      tier: SubscriptionTier.values.firstWhere(
        (t) => t.name == data['tier'],
        orElse: () => SubscriptionTier.free,
      ),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? false,
      isYearly: data['isYearly'] ?? false,
      stripeCustomerId: data['stripeCustomerId'],
      stripeSubscriptionId: data['stripeSubscriptionId'],
      trialEndDate: data['trialEndDate'] != null
          ? (data['trialEndDate'] as Timestamp).toDate()
          : null,
      isTrial: data['isTrial'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': odUserId,
      'tier': tier.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'isYearly': isYearly,
      'stripeCustomerId': stripeCustomerId,
      'stripeSubscriptionId': stripeSubscriptionId,
      'trialEndDate': trialEndDate != null
          ? Timestamp.fromDate(trialEndDate!)
          : null,
      'isTrial': isTrial,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Check if user has access to a specific feature
  bool hasFeature(String feature) {
    if (!isActive) return false;
    return SubscriptionFeatures.getFeatures(tier).contains(feature);
  }

  /// Days remaining in trial
  int? get trialDaysRemaining {
    if (!isTrial || trialEndDate == null) return null;
    return trialEndDate!.difference(DateTime.now()).inDays;
  }
}

/// Subscription service for managing user subscriptions
class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collection = 'subscriptions';
  static const String _plansCollection = 'subscription_plans';

  /// Get current user's subscription
  Future<UserSubscription> getCurrentSubscription() async {
    final user = _auth.currentUser;
    if (user == null) return UserSubscription.free('anonymous');

    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('startDate', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return UserSubscription.free(user.uid);
      }

      return UserSubscription.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      return UserSubscription.free(user.uid);
    }
  }

  /// Stream current user's subscription
  Stream<UserSubscription> subscriptionStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(UserSubscription.free('anonymous'));
    }

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .where('isActive', isEqualTo: true)
        .orderBy('startDate', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return UserSubscription.free(user.uid);
          }
          return UserSubscription.fromFirestore(snapshot.docs.first);
        });
  }

  /// Check if user has access to feature
  Future<bool> hasFeature(String feature) async {
    final sub = await getCurrentSubscription();
    return sub.hasFeature(feature);
  }

  /// Start a free trial (7 days of Fighter Pro)
  Future<UserSubscription?> startTrial() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // Check if user already had a trial
    final existingTrials = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .where('isTrial', isEqualTo: true)
        .get();

    if (existingTrials.docs.isNotEmpty) {
      throw Exception('You have already used your free trial');
    }

    final trial = UserSubscription(
      id: '',
      odUserId: user.uid,
      tier: SubscriptionTier.fighterPro,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
      isActive: true,
      isTrial: true,
      trialEndDate: DateTime.now().add(const Duration(days: 7)),
    );

    final docRef = await _firestore
        .collection(_collection)
        .add(trial.toFirestore());

    return UserSubscription(
      id: docRef.id,
      odUserId: trial.odUserId,
      tier: trial.tier,
      startDate: trial.startDate,
      endDate: trial.endDate,
      isActive: trial.isActive,
      isTrial: trial.isTrial,
      trialEndDate: trial.trialEndDate,
    );
  }

  /// Create checkout session (returns URL to Stripe checkout)
  /// In production, this would call a Cloud Function
  Future<String?> createCheckoutSession({
    required SubscriptionPlan plan,
    required bool isYearly,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be logged in to subscribe');

    // This would call a Cloud Function that creates a Stripe checkout session
    // using plan.stripePriceIdYearly or plan.stripePriceIdMonthly.

    // Cloud Function would:
    // 1. Get or create Stripe customer
    // 2. Create checkout session with priceId
    // 3. Return checkout URL

    // Stripe not yet configured — return null to indicate no session
    return null;
  }

  /// Handle successful payment (called by webhook)
  Future<void> activateSubscription({
    required String userId,
    required SubscriptionTier tier,
    required String stripeCustomerId,
    required String stripeSubscriptionId,
    required bool isYearly,
    required DateTime endDate,
  }) async {
    // Deactivate any existing subscriptions
    final existing = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    for (final doc in existing.docs) {
      await doc.reference.update({'isActive': false});
    }

    // Create new subscription
    final subscription = UserSubscription(
      id: '',
      odUserId: userId,
      tier: tier,
      startDate: DateTime.now(),
      endDate: endDate,
      isActive: true,
      isYearly: isYearly,
      stripeCustomerId: stripeCustomerId,
      stripeSubscriptionId: stripeSubscriptionId,
    );

    await _firestore.collection(_collection).add(subscription.toFirestore());
  }

  /// Cancel subscription (will remain active until end of billing period)
  Future<void> cancelSubscription() async {
    final sub = await getCurrentSubscription();
    if (sub.tier == SubscriptionTier.free) return;

    // This would call Stripe to cancel
    // For now, just mark as canceling
    if (sub.stripeSubscriptionId != null) {
      await _firestore.collection(_collection).doc(sub.id).update({
        'canceledAt': FieldValue.serverTimestamp(),
        // Subscription remains active until endDate
      });
    }
  }

  /// Get all plans
  List<SubscriptionPlan> getPlans() => SubscriptionPlan.allPlans;

  /// Fetch plans from Firestore (preferred if seeded)
  Future<List<SubscriptionPlanModel>> fetchPlans({String? tier}) async {
    Query query = _firestore.collection(_plansCollection);
    if (tier != null) {
      query = query.where('tier', isEqualTo: tier);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map(SubscriptionPlanModel.fromFirestore)
        .toList();
  }

  /// Calculate yearly savings
  double getYearlySavings(SubscriptionPlan plan) {
    return (plan.monthlyPrice * 12) - plan.yearlyPrice;
  }

  /// Subscribe via chosen provider (stub; calls PaymentsService on client)
  Future<void> subscribeWithProvider({
    required String planId,
    required String provider, // stripe/googlePay/paypal/applePay
    required bool isActive,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be logged in to subscribe');

    await _firestore.collection(_collection).add({
      'userId': user.uid,
      'planId': planId,
      'active': isActive,
      'startDate': Timestamp.now(),
      'provider': provider,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
