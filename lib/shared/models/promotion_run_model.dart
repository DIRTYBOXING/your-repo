import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Lifecycle status for a single promotion job execution.
enum PromotionRunStatus { pending, processing, done, error }

/// Result payload written by the promotion worker after execution.
class PromotionRunResult {
  final bool delivered;
  final int clicks;
  final int sales;
  final String? errorMessage;

  const PromotionRunResult({
    required this.delivered,
    this.clicks = 0,
    this.sales = 0,
    this.errorMessage,
  });

  factory PromotionRunResult.fromMap(Map<String, dynamic> m) {
    return PromotionRunResult(
      delivered: m['delivered'] as bool? ?? false,
      clicks: (m['clicks'] as num?)?.toInt() ?? 0,
      sales: (m['sales'] as num?)?.toInt() ?? 0,
      errorMessage: m['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'delivered': delivered,
    'clicks': clicks,
    'sales': sales,
    if (errorMessage != null) 'errorMessage': errorMessage,
  };
}

/// Single execution record for a campaign promotion job.
/// Maps to Firestore `promotion_runs/{runId}`.
class PromotionRunModel extends Equatable {
  final String id;
  final String campaignId;
  final String? mediaId;
  final String market;
  final String channel;
  final PromotionRunStatus status;
  final PromotionRunResult? result;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int attempts;
  final String? posterUrl;
  final String? caption;

  const PromotionRunModel({
    required this.id,
    required this.campaignId,
    this.mediaId,
    required this.market,
    required this.channel,
    required this.status,
    this.result,
    this.startedAt,
    this.finishedAt,
    this.attempts = 0,
    this.posterUrl,
    this.caption,
  });

  factory PromotionRunModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final m = doc.data()!;
    return PromotionRunModel(
      id: doc.id,
      campaignId: m['campaignId'] as String? ?? '',
      mediaId: m['mediaId'] as String?,
      market: m['market'] as String? ?? 'AU',
      channel: m['channel'] as String? ?? 'site',
      status: PromotionRunStatus.values.firstWhere(
        (s) => s.name == (m['status'] as String?),
        orElse: () => PromotionRunStatus.pending,
      ),
      result: m['result'] is Map
          ? PromotionRunResult.fromMap(
              Map<String, dynamic>.from(m['result'] as Map),
            )
          : null,
      startedAt: (m['started_at'] as Timestamp?)?.toDate(),
      finishedAt: (m['finished_at'] as Timestamp?)?.toDate(),
      attempts: (m['attempts'] as num?)?.toInt() ?? 0,
      posterUrl: m['posterUrl'] as String?,
      caption: m['caption'] as String?,
    );
  }

  bool get isError => status == PromotionRunStatus.error;
  bool get isDone => status == PromotionRunStatus.done;

  Map<String, dynamic> toFirestore() => {
    'campaignId': campaignId,
    if (mediaId != null) 'mediaId': mediaId,
    'market': market,
    'channel': channel,
    'status': status.name,
    if (result != null) 'result': result!.toMap(),
    if (startedAt != null) 'started_at': Timestamp.fromDate(startedAt!),
    if (finishedAt != null) 'finished_at': Timestamp.fromDate(finishedAt!),
    'attempts': attempts,
    if (posterUrl != null) 'posterUrl': posterUrl,
    if (caption != null) 'caption': caption,
  };

  PromotionRunModel copyWith({
    String? id,
    String? campaignId,
    String? mediaId,
    String? market,
    String? channel,
    PromotionRunStatus? status,
    PromotionRunResult? result,
    DateTime? startedAt,
    DateTime? finishedAt,
    int? attempts,
    String? posterUrl,
    String? caption,
  }) {
    return PromotionRunModel(
      id: id ?? this.id,
      campaignId: campaignId ?? this.campaignId,
      mediaId: mediaId ?? this.mediaId,
      market: market ?? this.market,
      channel: channel ?? this.channel,
      status: status ?? this.status,
      result: result ?? this.result,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      attempts: attempts ?? this.attempts,
      posterUrl: posterUrl ?? this.posterUrl,
      caption: caption ?? this.caption,
    );
  }

  @override
  List<Object?> get props => [
    id,
    campaignId,
    mediaId,
    market,
    channel,
    status,
    attempts,
    posterUrl,
    caption,
  ];
}
