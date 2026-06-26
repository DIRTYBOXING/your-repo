import 'package:equatable/equatable.dart';

class Donation extends Equatable {
  final String id;
  final String campaignId;
  final String donorId;
  final double amount;
  final DateTime donatedAt;

  const Donation({
    required this.id,
    required this.campaignId,
    required this.donorId,
    required this.amount,
    required this.donatedAt,
  });

  factory Donation.fromMap(Map<String, dynamic> map, String id) {
    return Donation(
      id: id,
      campaignId: map['campaignId'] ?? '',
      donorId: map['donorId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      donatedAt: DateTime.parse(
        map['donatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'campaignId': campaignId,
      'donorId': donorId,
      'amount': amount,
      'donatedAt': donatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, campaignId, donorId, amount, donatedAt];
}
