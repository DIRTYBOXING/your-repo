import 'package:cloud_firestore/cloud_firestore.dart';
import 'subscription_plan.dart';

class SubscriptionStatus {
  final String id;
  final String userId;
  final String planId;
  final String tier;
  final BillingCycle cycle;
  final bool active;
  final DateTime startDate;
  final DateTime? currentPeriodEnd;
  final String provider; // stripe/googlePay/paypal/applePay
  final String? providerCustomerId;
  final String? providerSubscriptionId;
  final List<String> entitlements; // feature flags granted

  const SubscriptionStatus({
    required this.id,
    required this.userId,
    required this.planId,
    required this.tier,
    required this.cycle,
    required this.active,
    required this.startDate,
    this.currentPeriodEnd,
    required this.provider,
    this.providerCustomerId,
    this.providerSubscriptionId,
    required this.entitlements,
  });

  factory SubscriptionStatus.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionStatus(
      id: doc.id,
      userId: data['userId'] ?? '',
      planId: data['planId'] ?? '',
      tier: data['tier'] ?? 'fan',
      cycle: _cycleFromString(data['cycle'] ?? 'monthly'),
      active: (data['active'] ?? false) as bool,
      startDate: (data['startDate'] as Timestamp).toDate(),
      currentPeriodEnd: data['currentPeriodEnd'] != null
          ? (data['currentPeriodEnd'] as Timestamp).toDate()
          : null,
      provider: data['provider'] ?? 'stripe',
      providerCustomerId: data['providerCustomerId'],
      providerSubscriptionId: data['providerSubscriptionId'],
      entitlements: (data['entitlements'] as List?)?.cast<String>() ?? const [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'planId': planId,
      'tier': tier,
      'cycle': cycle.name,
      'active': active,
      'startDate': Timestamp.fromDate(startDate),
      'currentPeriodEnd': currentPeriodEnd != null
          ? Timestamp.fromDate(currentPeriodEnd!)
          : null,
      'provider': provider,
      'providerCustomerId': providerCustomerId,
      'providerSubscriptionId': providerSubscriptionId,
      'entitlements': entitlements,
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
}
