import 'package:cloud_firestore/cloud_firestore.dart';

/// Revenue Split Model
class RevenueShare {
  final String id;
  final String ppvEventId;
  final String promoterId;
  final double totalRevenue;
  final double promoterAmount;
  final double platformAmount;
  final int totalPurchases;
  final PayoutStatus payoutStatus;
  final DateTime? paidOutAt;

  RevenueShare({
    required this.id,
    required this.ppvEventId,
    required this.promoterId,
    required this.totalRevenue,
    required this.promoterAmount,
    required this.platformAmount,
    required this.totalPurchases,
    this.payoutStatus = PayoutStatus.pending,
    this.paidOutAt,
  });

  factory RevenueShare.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RevenueShare(
      id: doc.id,
      ppvEventId: data['ppvEventId'] ?? '',
      promoterId: data['promoterId'] ?? '',
      totalRevenue: (data['totalRevenue'] as num).toDouble(),
      promoterAmount: (data['promoterAmount'] as num).toDouble(),
      platformAmount: (data['platformAmount'] as num).toDouble(),
      totalPurchases: data['totalPurchases'] ?? 0,
      payoutStatus: PayoutStatus.values.firstWhere(
        (e) => e.toString() == 'PayoutStatus.${data['payoutStatus']}',
        orElse: () => PayoutStatus.pending,
      ),
      paidOutAt: data['paidOutAt'] != null
          ? (data['paidOutAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ppvEventId': ppvEventId,
      'promoterId': promoterId,
      'totalRevenue': totalRevenue,
      'promoterAmount': promoterAmount,
      'platformAmount': platformAmount,
      'totalPurchases': totalPurchases,
      'payoutStatus': payoutStatus.toString().split('.').last,
      'paidOutAt': paidOutAt != null ? Timestamp.fromDate(paidOutAt!) : null,
    };
  }
}

enum PayoutStatus { pending, processing, completed, failed }
