import 'package:cloud_firestore/cloud_firestore.dart';

/// A single audit log entry written by a promotion worker.
/// Maps to Firestore `promotion_logs/{logId}` (server-write only).
class PromotionLogModel {
  final String id;
  final String campaignId;
  final String market;
  final String channel;
  final String workerId;
  final String action;
  final Map<String, dynamic> details;
  final DateTime? timestamp;

  const PromotionLogModel({
    required this.id,
    required this.campaignId,
    required this.market,
    required this.channel,
    required this.workerId,
    required this.action,
    required this.details,
    this.timestamp,
  });

  factory PromotionLogModel.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    return PromotionLogModel(
      id: doc.id,
      campaignId: m['campaign_id'] as String? ?? '',
      market: m['market'] as String? ?? '',
      channel: m['channel'] as String? ?? '',
      workerId: m['worker_id'] as String? ?? '',
      action: m['action'] as String? ?? '',
      details: m['details'] as Map<String, dynamic>? ?? {},
      timestamp: (m['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}
