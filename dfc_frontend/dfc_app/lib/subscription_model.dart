class SubscriptionModel {
  final String tier;
  final List<String> perks;
  final double monthlyPrice;
  final String renewalDate;

  SubscriptionModel({
    required this.tier,
    required this.perks,
    required this.monthlyPrice,
    required this.renewalDate,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      SubscriptionModel(
        tier: json['tier'] ?? 'FREE',
        perks: List<String>.from(json['perks'] ?? []),
        monthlyPrice: (json['monthlyPrice'] ?? 0).toDouble(),
        renewalDate: json['renewalDate'] ?? '',
      );
}
