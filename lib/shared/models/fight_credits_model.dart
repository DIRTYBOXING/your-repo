import 'package:cloud_firestore/cloud_firestore.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC FIGHT CREDITS — Micropayment wallet for pay-per-fight & pay-per-round
///
/// Users buy Credit Packs (single Stripe transaction) then spend credits
/// on individual fights/rounds. This avoids per-transaction card fees
/// (30¢ + 2.9%) destroying profit on $1–$2 micro-purchases.
///
/// Pack Tiers:
///   Starter   →  5 credits  =  A$5   (A$1.00/credit)
///   Fight Fan → 10 credits  =  A$9   (A$0.90/credit — 10% bonus)
///   War Chest → 25 credits  =  A$20  (A$0.80/credit — 20% bonus)
///   Legend    → 50 credits  =  A$35  (A$0.70/credit — 30% bonus)
///
/// Spend Rates:
///   Single Fight Stream     = 3 credits
///   Pay-Per-Round (live)    = 1 credit/round
///   Full Event Card         = 8 credits
///   Replay (48h window)     = 2 credits
///   Premium Analysis/AI     = 1 credit
/// ═══════════════════════════════════════════════════════════════════════════

/// A purchasable credit pack.
class CreditPack {
  final String id;
  final String name;
  final int credits;
  final int priceCentsAUD; // in cents
  final double pricePerCredit;
  final String? bonusLabel; // e.g. "10% BONUS"
  final String? stripePriceId;

  const CreditPack({
    required this.id,
    required this.name,
    required this.credits,
    required this.priceCentsAUD,
    required this.pricePerCredit,
    this.bonusLabel,
    this.stripePriceId,
  });

  double get priceAUD => priceCentsAUD / 100.0;

  static const starter = CreditPack(
    id: 'pack_starter',
    name: 'Starter',
    credits: 5,
    priceCentsAUD: 500,
    pricePerCredit: 1.00,
    stripePriceId: 'price_credits_starter',
  );

  static const fightFan = CreditPack(
    id: 'pack_fight_fan',
    name: 'Fight Fan',
    credits: 10,
    priceCentsAUD: 900,
    pricePerCredit: 0.90,
    bonusLabel: '10% BONUS',
    stripePriceId: 'price_credits_fight_fan',
  );

  static const warChest = CreditPack(
    id: 'pack_war_chest',
    name: 'War Chest',
    credits: 25,
    priceCentsAUD: 2000,
    pricePerCredit: 0.80,
    bonusLabel: '20% BONUS',
    stripePriceId: 'price_credits_war_chest',
  );

  static const legend = CreditPack(
    id: 'pack_legend',
    name: 'Legend',
    credits: 50,
    priceCentsAUD: 3500,
    pricePerCredit: 0.70,
    bonusLabel: '30% BONUS',
    stripePriceId: 'price_credits_legend',
  );

  static const List<CreditPack> allPacks = [
    starter,
    fightFan,
    warChest,
    legend,
  ];
}

/// What the user spent credits on.
enum CreditSpendType {
  singleFight,
  payPerRound,
  fullEventCard,
  replay,
  premiumAnalysis,
  tip,
}

/// Cost table for each spend type (in credits).
class CreditCosts {
  static const Map<CreditSpendType, int> costs = {
    CreditSpendType.singleFight: 3,
    CreditSpendType.payPerRound: 1,
    CreditSpendType.fullEventCard: 8,
    CreditSpendType.replay: 2,
    CreditSpendType.premiumAnalysis: 1,
    CreditSpendType.tip: 1, // minimum tip
  };

  static int costFor(CreditSpendType type) => costs[type] ?? 1;

  static String labelFor(CreditSpendType type) {
    switch (type) {
      case CreditSpendType.singleFight:
        return 'Single Fight';
      case CreditSpendType.payPerRound:
        return 'Per Round';
      case CreditSpendType.fullEventCard:
        return 'Full Event Card';
      case CreditSpendType.replay:
        return '48h Replay';
      case CreditSpendType.premiumAnalysis:
        return 'AI Analysis';
      case CreditSpendType.tip:
        return 'Tip Fighter';
    }
  }
}

/// A single credit transaction (purchase or spend).
class CreditTransaction {
  final String id;
  final String userId;
  final int amount; // positive = earned/bought, negative = spent
  final String description;
  final String? relatedEventId;
  final String? relatedFightId;
  final String? stripePaymentIntentId;
  final CreditSpendType? spendType;
  final DateTime createdAt;

  const CreditTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.description,
    this.relatedEventId,
    this.relatedFightId,
    this.stripePaymentIntentId,
    this.spendType,
    required this.createdAt,
  });

  bool get isPurchase => amount > 0;
  bool get isSpend => amount < 0;

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'amount': amount,
        'description': description,
        'relatedEventId': relatedEventId,
        'relatedFightId': relatedFightId,
        'stripePaymentIntentId': stripePaymentIntentId,
        'spendType': spendType?.name,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory CreditTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CreditTransaction(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: data['amount'] ?? 0,
      description: data['description'] ?? '',
      relatedEventId: data['relatedEventId'],
      relatedFightId: data['relatedFightId'],
      stripePaymentIntentId: data['stripePaymentIntentId'],
      spendType: data['spendType'] != null
          ? CreditSpendType.values.firstWhere(
              (e) => e.name == data['spendType'],
              orElse: () => CreditSpendType.singleFight,
            )
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// User's credit wallet state.
class CreditWallet {
  final String userId;
  final int balance;
  final int totalPurchased;
  final int totalSpent;
  final DateTime? lastPurchaseAt;
  final DateTime? lastSpendAt;

  const CreditWallet({
    required this.userId,
    required this.balance,
    this.totalPurchased = 0,
    this.totalSpent = 0,
    this.lastPurchaseAt,
    this.lastSpendAt,
  });

  bool canAfford(CreditSpendType type) =>
      balance >= CreditCosts.costFor(type);

  bool canAffordAmount(int credits) => balance >= credits;

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'balance': balance,
        'totalPurchased': totalPurchased,
        'totalSpent': totalSpent,
        'lastPurchaseAt':
            lastPurchaseAt != null ? Timestamp.fromDate(lastPurchaseAt!) : null,
        'lastSpendAt':
            lastSpendAt != null ? Timestamp.fromDate(lastSpendAt!) : null,
      };

  factory CreditWallet.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CreditWallet(
      userId: doc.id,
      balance: data['balance'] ?? 0,
      totalPurchased: data['totalPurchased'] ?? 0,
      totalSpent: data['totalSpent'] ?? 0,
      lastPurchaseAt: (data['lastPurchaseAt'] as Timestamp?)?.toDate(),
      lastSpendAt: (data['lastSpendAt'] as Timestamp?)?.toDate(),
    );
  }

  factory CreditWallet.empty(String userId) => CreditWallet(
        userId: userId,
        balance: 0,
      );
}
