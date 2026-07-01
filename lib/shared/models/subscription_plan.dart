import 'package:cloud_firestore/cloud_firestore.dart';

enum BillingCycle { weekly, fortnightly, monthly, yearly }

enum PaymentProvider { stripe, googlePay, paypal, applePay }

class SubscriptionPlanModel {
  final String id;
  final String tier; // e.g. fighter, promoter, supporter, fan
  final String name;
  final String description;
  final BillingCycle cycle;
  final int priceCents; // 999 = $9.99
  final bool active;
  final Map<PaymentProvider, String> providerPriceIds;
  final List<String> features;

  const SubscriptionPlanModel({
    required this.id,
    required this.tier,
    required this.name,
    required this.description,
    required this.cycle,
    required this.priceCents,
    required this.active,
    required this.providerPriceIds,
    required this.features,
  });

  factory SubscriptionPlanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionPlanModel(
      id: doc.id,
      tier: data['tier'] ?? 'fan',
      name: data['name'] ?? 'Plan',
      description: data['description'] ?? '',
      cycle: _cycleFromString(data['cycle'] ?? 'monthly'),
      priceCents: (data['priceCents'] ?? 0) as int,
      active: (data['active'] ?? true) as bool,
      providerPriceIds: _providerIdsFrom(data['providerPriceIds'] ?? {}),
      features: (data['features'] as List?)?.cast<String>() ?? const [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tier': tier,
      'name': name,
      'description': description,
      'cycle': cycle.name,
      'priceCents': priceCents,
      'active': active,
      'providerPriceIds': providerPriceIds.map((k, v) => MapEntry(k.name, v)),
      'features': features,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static BillingCycle _cycleFromString(String s) {
    switch (s) {
      case 'weekly':
        return BillingCycle.weekly;
      case 'fortnightly':
        return BillingCycle.fortnightly;
      case 'yearly':
        return BillingCycle.yearly;
      case 'monthly':
      default:
        return BillingCycle.monthly;
    }
  }

  static Map<PaymentProvider, String> _providerIdsFrom(Map raw) {
    final map = <PaymentProvider, String>{};
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      final value = entry.value?.toString() ?? '';
      switch (key) {
        case 'stripe':
          map[PaymentProvider.stripe] = value;
          break;
        case 'googlePay':
          map[PaymentProvider.googlePay] = value;
          break;
        case 'paypal':
          map[PaymentProvider.paypal] = value;
          break;
        case 'applePay':
          map[PaymentProvider.applePay] = value;
          break;
      }
    }
    return map;
  }
}
