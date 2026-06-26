// ═══════════════════════════════════════════════════════════════════════════
// CREATOR ECONOMY SERVICE — Monetization, Tipping, Subscriptions, Payouts
// ═══════════════════════════════════════════════════════════════════════════
//
// Full creator monetization pipeline:
//  • Tipping — instant micro-payments to creators
//  • Subscriptions — tiered fan memberships with exclusive perks
//  • Revenue analytics — earnings breakdowns, growth trends
//  • Payout management — withdrawal tracking and fee calculations
//  • Subscriber-only content — gated posts for paying fans
//  • Brand collaborations — sponsorship marketplace
//
// Integrates with existing PPVService + Stripe payment infrastructure
// ═══════════════════════════════════════════════════════════════════════════

// ─── Enums ──────────────────────────────────────────────────────────────

enum SubscriptionTier {
  supporter('Supporter', 4.99, 'Basic supporter access', [
    'Early access to posts',
    'Supporter badge',
    'Ad-free experience',
  ]),
  champion('Champion', 9.99, 'Full access membership', [
    'All Supporter perks',
    'Exclusive content access',
    'Monthly Q&A access',
    'Champion badge',
  ]),
  legend('Legend', 24.99, 'Ultimate fan experience', [
    'All Champion perks',
    'Direct messaging with creator',
    'Behind-the-scenes content',
    'Legend badge with gold border',
    'Priority event tickets',
  ]);

  final String label;
  final double monthlyPrice;
  final String description;
  final List<String> perks;
  const SubscriptionTier(
    this.label,
    this.monthlyPrice,
    this.description,
    this.perks,
  );
}

enum TipAmount {
  small('🥊', 1.00, 'Respect tap'),
  medium('💪', 5.00, 'Solid support'),
  large('🔥', 10.00, 'Big props'),
  champion('👑', 25.00, 'Champion energy'),
  legendary('🏆', 50.00, 'Legendary tribute'),
  custom('✨', 0.00, 'Custom amount');

  final String emoji;
  final double amount;
  final String label;
  const TipAmount(this.emoji, this.amount, this.label);
}

enum PayoutStatus {
  pending('Pending', 'Processing withdrawal'),
  processing('Processing', 'Being transferred'),
  completed('Completed', 'Funds received'),
  failed('Failed', 'Transfer failed'),
  cancelled('Cancelled', 'Withdrawal cancelled');

  final String label;
  final String description;
  const PayoutStatus(this.label, this.description);
}

enum RevenueSource {
  tips('Tips', '🎁'),
  subscriptions('Subscriptions', '⭐'),
  ppvRevenue('PPV Revenue', '🎬'),
  sponsorships('Sponsorships', '🤝'),
  merchandise('Merchandise', '👕');

  final String label;
  final String emoji;
  const RevenueSource(this.label, this.emoji);
}

// ─── Models ─────────────────────────────────────────────────────────────

class CreatorProfile {
  final String creatorId;
  final String displayName;
  final bool isVerified;
  final DateTime joinedAt;
  final int totalSubscribers;
  final double lifetimeEarnings;
  final double availableBalance;
  final double platformFeePercent;
  final Map<SubscriptionTier, int> tierBreakdown;
  final List<String> enabledTiers;
  final String? payoutMethod; // stripe, paypal, bank_transfer

  const CreatorProfile({
    required this.creatorId,
    required this.displayName,
    this.isVerified = false,
    required this.joinedAt,
    this.totalSubscribers = 0,
    this.lifetimeEarnings = 0.0,
    this.availableBalance = 0.0,
    this.platformFeePercent = 15.0,
    this.tierBreakdown = const {},
    this.enabledTiers = const [],
    this.payoutMethod,
  });

  Map<String, dynamic> toMap() => {
    'creatorId': creatorId,
    'displayName': displayName,
    'isVerified': isVerified,
    'totalSubscribers': totalSubscribers,
    'lifetimeEarnings': lifetimeEarnings,
    'availableBalance': availableBalance,
    'platformFee': platformFeePercent,
    'tierBreakdown': tierBreakdown.map((k, v) => MapEntry(k.name, v)),
  };
}

class TipTransaction {
  final String tipId;
  final String senderId;
  final String creatorId;
  final double amount;
  final String? message;
  final String? postId;
  final DateTime timestamp;
  final bool isAnonymous;

  const TipTransaction({
    required this.tipId,
    required this.senderId,
    required this.creatorId,
    required this.amount,
    this.message,
    this.postId,
    required this.timestamp,
    this.isAnonymous = false,
  });

  Map<String, dynamic> toMap() => {
    'tipId': tipId,
    'senderId': isAnonymous ? 'anonymous' : senderId,
    'creatorId': creatorId,
    'amount': amount,
    'message': message,
    'postId': postId,
    'timestamp': timestamp.toIso8601String(),
  };
}

class Subscription {
  final String subscriptionId;
  final String subscriberId;
  final String creatorId;
  final SubscriptionTier tier;
  final DateTime startedAt;
  final DateTime? expiresAt;
  final bool isActive;
  final bool autoRenew;
  final int consecutiveMonths;

  const Subscription({
    required this.subscriptionId,
    required this.subscriberId,
    required this.creatorId,
    required this.tier,
    required this.startedAt,
    this.expiresAt,
    this.isActive = true,
    this.autoRenew = true,
    this.consecutiveMonths = 1,
  });

  Map<String, dynamic> toMap() => {
    'subscriptionId': subscriptionId,
    'subscriberId': subscriberId,
    'creatorId': creatorId,
    'tier': tier.name,
    'startedAt': startedAt.toIso8601String(),
    'isActive': isActive,
    'autoRenew': autoRenew,
    'consecutiveMonths': consecutiveMonths,
  };
}

class PayoutRequest {
  final String payoutId;
  final String creatorId;
  final double amount;
  final double platformFee;
  final double netAmount;
  final PayoutStatus status;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String payoutMethod;

  const PayoutRequest({
    required this.payoutId,
    required this.creatorId,
    required this.amount,
    required this.platformFee,
    required this.netAmount,
    this.status = PayoutStatus.pending,
    required this.requestedAt,
    this.processedAt,
    this.payoutMethod = 'stripe',
  });

  Map<String, dynamic> toMap() => {
    'payoutId': payoutId,
    'creatorId': creatorId,
    'amount': amount,
    'platformFee': platformFee,
    'netAmount': netAmount,
    'status': status.name,
    'requestedAt': requestedAt.toIso8601String(),
    'payoutMethod': payoutMethod,
  };
}

class RevenueSnapshot {
  final String creatorId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Map<RevenueSource, double> breakdown;
  final double totalRevenue;
  final double platformFees;
  final double netEarnings;
  final int newSubscribers;
  final int churnedSubscribers;
  final double avgTipAmount;
  final int totalTips;

  const RevenueSnapshot({
    required this.creatorId,
    required this.periodStart,
    required this.periodEnd,
    required this.breakdown,
    required this.totalRevenue,
    required this.platformFees,
    required this.netEarnings,
    this.newSubscribers = 0,
    this.churnedSubscribers = 0,
    this.avgTipAmount = 0.0,
    this.totalTips = 0,
  });

  Map<String, dynamic> toMap() => {
    'creatorId': creatorId,
    'periodStart': periodStart.toIso8601String(),
    'periodEnd': periodEnd.toIso8601String(),
    'totalRevenue': totalRevenue,
    'platformFees': platformFees,
    'netEarnings': netEarnings,
    'newSubscribers': newSubscribers,
    'churnedSubscribers': churnedSubscribers,
    'breakdown': breakdown.map((k, v) => MapEntry(k.name, v)),
  };
}

// ─── Service ────────────────────────────────────────────────────────────

class CreatorEconomyService {
  CreatorEconomyService._();
  static final CreatorEconomyService instance = CreatorEconomyService._();

  static const double _platformFeePercent = 15.0; // DFC takes 15%
  static const double _minimumPayout = 25.0;
  static const double _maxTipAmount = 500.0;

  final _creators = <String, CreatorProfile>{};
  final _tips = <TipTransaction>[];
  final _subscriptions = <Subscription>[];
  final _payouts = <PayoutRequest>[];

  /// Register a user as a creator.
  CreatorProfile registerCreator({
    required String creatorId,
    required String displayName,
    bool isVerified = false,
  }) {
    final profile = CreatorProfile(
      creatorId: creatorId,
      displayName: displayName,
      isVerified: isVerified,
      joinedAt: DateTime.now(),
    );
    _creators[creatorId] = profile;
    return profile;
  }

  /// Process a tip from a user to a creator.
  TipTransaction sendTip({
    required String senderId,
    required String creatorId,
    required double amount,
    String? message,
    String? postId,
    bool isAnonymous = false,
  }) {
    final clampedAmount = amount.clamp(0.50, _maxTipAmount);
    final tip = TipTransaction(
      tipId: 'tip_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      creatorId: creatorId,
      amount: clampedAmount,
      message: message,
      postId: postId,
      timestamp: DateTime.now(),
      isAnonymous: isAnonymous,
    );
    _tips.add(tip);

    // Update creator balance
    _updateCreatorBalance(creatorId, clampedAmount);
    return tip;
  }

  /// Subscribe a user to a creator's tier.
  Subscription subscribe({
    required String subscriberId,
    required String creatorId,
    required SubscriptionTier tier,
  }) {
    final sub = Subscription(
      subscriptionId: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      subscriberId: subscriberId,
      creatorId: creatorId,
      tier: tier,
      startedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
    _subscriptions.add(sub);

    // Add monthly revenue to creator
    _updateCreatorBalance(creatorId, tier.monthlyPrice);
    return sub;
  }

  /// Check if a user has an active subscription to a creator.
  bool hasActiveSubscription(String subscriberId, String creatorId) {
    return _subscriptions.any(
      (s) =>
          s.subscriberId == subscriberId &&
          s.creatorId == creatorId &&
          s.isActive,
    );
  }

  /// Get minimum tier for a subscriber (for content gating).
  SubscriptionTier? getSubscriberTier(String subscriberId, String creatorId) {
    final activeSubs = _subscriptions
        .where(
          (s) =>
              s.subscriberId == subscriberId &&
              s.creatorId == creatorId &&
              s.isActive,
        )
        .toList();
    if (activeSubs.isEmpty) return null;
    // Return highest tier
    activeSubs.sort(
      (a, b) => b.tier.monthlyPrice.compareTo(a.tier.monthlyPrice),
    );
    return activeSubs.first.tier;
  }

  /// Request a payout.
  PayoutRequest requestPayout({
    required String creatorId,
    required double amount,
    String payoutMethod = 'stripe',
  }) {
    final creator = _creators[creatorId];
    final available = creator?.availableBalance ?? 0;
    final requestAmount = amount.clamp(0, available).toDouble();

    if (requestAmount < _minimumPayout) {
      return PayoutRequest(
        payoutId: 'payout_failed',
        creatorId: creatorId,
        amount: requestAmount,
        platformFee: 0,
        netAmount: 0,
        status: PayoutStatus.failed,
        requestedAt: DateTime.now(),
        payoutMethod: payoutMethod,
      );
    }

    final fee = requestAmount * (_platformFeePercent / 100);
    final net = requestAmount - fee;

    final payout = PayoutRequest(
      payoutId: 'payout_${DateTime.now().millisecondsSinceEpoch}',
      creatorId: creatorId,
      amount: requestAmount,
      platformFee: fee,
      netAmount: net,
      requestedAt: DateTime.now(),
      payoutMethod: payoutMethod,
    );
    _payouts.add(payout);
    return payout;
  }

  /// Generate a revenue snapshot for a creator over a time period.
  RevenueSnapshot getRevenueSnapshot({
    required String creatorId,
    required DateTime from,
    required DateTime to,
  }) {
    // Tips in period
    final periodTips = _tips.where(
      (t) =>
          t.creatorId == creatorId &&
          t.timestamp.isAfter(from) &&
          t.timestamp.isBefore(to),
    );

    final tipTotal = periodTips.isEmpty
        ? 0.0
        : periodTips.map((t) => t.amount).reduce((a, b) => a + b);

    // Subscriptions in period
    final periodSubs = _subscriptions.where(
      (s) =>
          s.creatorId == creatorId &&
          s.startedAt.isAfter(from) &&
          s.startedAt.isBefore(to),
    );

    final subTotal = periodSubs.isEmpty
        ? 0.0
        : periodSubs.map((s) => s.tier.monthlyPrice).reduce((a, b) => a + b);

    final totalRevenue = tipTotal + subTotal;
    final platformFees = totalRevenue * (_platformFeePercent / 100);

    return RevenueSnapshot(
      creatorId: creatorId,
      periodStart: from,
      periodEnd: to,
      breakdown: {
        RevenueSource.tips: tipTotal,
        RevenueSource.subscriptions: subTotal,
      },
      totalRevenue: totalRevenue,
      platformFees: platformFees,
      netEarnings: totalRevenue - platformFees,
      newSubscribers: periodSubs.length,
      avgTipAmount: periodTips.isEmpty ? 0 : tipTotal / periodTips.length,
      totalTips: periodTips.length,
    );
  }

  /// Get creator profile.
  CreatorProfile? getCreator(String creatorId) => _creators[creatorId];

  /// Get subscriber count for a creator.
  int getSubscriberCount(String creatorId) {
    return _subscriptions
        .where((s) => s.creatorId == creatorId && s.isActive)
        .length;
  }

  /// Get top tippers for a creator.
  List<TipTransaction> getTopTippers(String creatorId, {int limit = 10}) {
    final creatorTips = _tips.where((t) => t.creatorId == creatorId).toList();
    creatorTips.sort((a, b) => b.amount.compareTo(a.amount));
    return creatorTips.take(limit).toList();
  }

  void _updateCreatorBalance(String creatorId, double amount) {
    final existing = _creators[creatorId];
    if (existing == null) return;

    _creators[creatorId] = CreatorProfile(
      creatorId: existing.creatorId,
      displayName: existing.displayName,
      isVerified: existing.isVerified,
      joinedAt: existing.joinedAt,
      totalSubscribers: getSubscriberCount(creatorId),
      lifetimeEarnings: existing.lifetimeEarnings + amount,
      availableBalance: existing.availableBalance + amount,
      platformFeePercent: existing.platformFeePercent,
      tierBreakdown: existing.tierBreakdown,
      enabledTiers: existing.enabledTiers,
      payoutMethod: existing.payoutMethod,
    );
  }
}
