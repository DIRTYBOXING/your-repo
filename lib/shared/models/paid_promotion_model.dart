import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Spend tier for paid promotions — determines badge display and fairness caps.
enum PromotionSpendTier {
  /// 0-50 AUD — grassroots / small-promoter boost
  grassroots,

  /// 50-200 AUD — regional promotion
  regional,

  /// 200-1000 AUD — national-level boost
  national,

  /// 1000+ AUD — headline / PPV-level amplification
  headline,
}

/// Status of a paid promotion through its lifecycle.
enum PaidPromotionStatus {
  /// Created but payment not yet completed
  pending,

  /// Stripe payment succeeded — promotion is live
  active,

  /// Promotion period ended
  completed,

  /// UGC consent revoked — promotion force-stopped
  consentRevoked,

  /// Refunded by promoter or dispute resolution
  refunded,

  /// Paused by admin/moderation
  paused,
}

/// A paid content promotion on DFC.
///
/// Stored in Firestore `paid_promotions/{promotionId}`.
///
/// Architecture:
///   - Funds flow directly to the promoter's Stripe Connect account.
///   - DFC collects `applicationFeeCents` via `application_fee_amount`.
///   - DFC never custodially holds customer funds.
///   - Every promoted item must show a "Paid Promotion" badge.
class PaidPromotionModel extends Equatable {
  /// Firestore document ID
  final String id;

  /// The content being promoted (maps to ugc_consents.contentId)
  final String contentId;

  /// Promoter who funded the promotion
  final String promoterId;

  /// Display name of the promoter (shown on badge)
  final String promoterName;

  /// Stripe Checkout session ID for this payment
  final String? stripeSessionId;

  /// Stripe PaymentIntent ID
  final String? stripePaymentIntentId;

  /// Total amount charged (in smallest currency unit — cents)
  final int amountCents;

  /// DFC platform fee collected via application_fee_amount (cents)
  final int applicationFeeCents;

  /// Currency code (ISO 4217)
  final String currency;

  /// Spend tier (determines badge display and fairness caps)
  final PromotionSpendTier spendTier;

  /// Current status
  final PaidPromotionStatus status;

  /// Must be true — every paid promotion requires visible labeling
  final bool labeled;

  /// Whether brain-signal ranking was used for this promotion
  final bool brainSignalUsed;

  /// When the promotion goes live
  final DateTime startTs;

  /// When the promotion ends
  final DateTime endTs;

  /// Impressions allocated to this promotion
  final int impressionsAllocated;

  /// Impressions actually served
  final int impressionsServed;

  /// Hash of ranking inputs used (for audit reproducibility)
  final String? rankingInputsHash;

  /// Reference to the UGC consent record that authorizes this promotion
  final String? ugcConsentId;

  final DateTime createdAt;
  final DateTime updatedAt;

  const PaidPromotionModel({
    required this.id,
    required this.contentId,
    required this.promoterId,
    required this.promoterName,
    this.stripeSessionId,
    this.stripePaymentIntentId,
    required this.amountCents,
    required this.applicationFeeCents,
    this.currency = 'AUD',
    required this.spendTier,
    this.status = PaidPromotionStatus.pending,
    this.labeled = true,
    this.brainSignalUsed = false,
    required this.startTs,
    required this.endTs,
    this.impressionsAllocated = 0,
    this.impressionsServed = 0,
    this.rankingInputsHash,
    this.ugcConsentId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Is the promotion currently running?
  bool get isLive {
    if (status != PaidPromotionStatus.active) return false;
    final now = DateTime.now();
    return now.isAfter(startTs) && now.isBefore(endTs);
  }

  /// Delivery rate (served / allocated)
  double get deliveryRate =>
      impressionsAllocated > 0 ? impressionsServed / impressionsAllocated : 0.0;

  /// Display label for the promotion badge
  String get badgeLabel {
    if (brainSignalUsed) return 'Paid Promotion · Neural Ranked';
    return 'Paid Promotion';
  }

  // ── Firestore serialization ──────────────────────────────────────

  factory PaidPromotionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return PaidPromotionModel(
      id: doc.id,
      contentId: d['contentId'] ?? '',
      promoterId: d['promoterId'] ?? '',
      promoterName: d['promoterName'] ?? '',
      stripeSessionId: d['stripeSessionId'],
      stripePaymentIntentId: d['stripePaymentIntentId'],
      amountCents: d['amountCents'] ?? 0,
      applicationFeeCents: d['applicationFeeCents'] ?? 0,
      currency: d['currency'] ?? 'AUD',
      spendTier: PromotionSpendTier.values.firstWhere(
        (e) => e.name == d['spendTier'],
        orElse: () => PromotionSpendTier.grassroots,
      ),
      status: PaidPromotionStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => PaidPromotionStatus.pending,
      ),
      labeled: d['labeled'] ?? true,
      brainSignalUsed: d['brainSignalUsed'] ?? false,
      startTs: (d['startTs'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTs: (d['endTs'] as Timestamp?)?.toDate() ?? DateTime.now(),
      impressionsAllocated: d['impressionsAllocated'] ?? 0,
      impressionsServed: d['impressionsServed'] ?? 0,
      rankingInputsHash: d['rankingInputsHash'],
      ugcConsentId: d['ugcConsentId'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'contentId': contentId,
    'promoterId': promoterId,
    'promoterName': promoterName,
    if (stripeSessionId != null) 'stripeSessionId': stripeSessionId,
    if (stripePaymentIntentId != null)
      'stripePaymentIntentId': stripePaymentIntentId,
    'amountCents': amountCents,
    'applicationFeeCents': applicationFeeCents,
    'currency': currency,
    'spendTier': spendTier.name,
    'status': status.name,
    'labeled': labeled,
    'brainSignalUsed': brainSignalUsed,
    'startTs': Timestamp.fromDate(startTs),
    'endTs': Timestamp.fromDate(endTs),
    'impressionsAllocated': impressionsAllocated,
    'impressionsServed': impressionsServed,
    if (rankingInputsHash != null) 'rankingInputsHash': rankingInputsHash,
    if (ugcConsentId != null) 'ugcConsentId': ugcConsentId,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  PaidPromotionModel copyWith({
    String? id,
    String? contentId,
    String? promoterId,
    String? promoterName,
    String? stripeSessionId,
    String? stripePaymentIntentId,
    int? amountCents,
    int? applicationFeeCents,
    String? currency,
    PromotionSpendTier? spendTier,
    PaidPromotionStatus? status,
    bool? labeled,
    bool? brainSignalUsed,
    DateTime? startTs,
    DateTime? endTs,
    int? impressionsAllocated,
    int? impressionsServed,
    String? rankingInputsHash,
    String? ugcConsentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PaidPromotionModel(
    id: id ?? this.id,
    contentId: contentId ?? this.contentId,
    promoterId: promoterId ?? this.promoterId,
    promoterName: promoterName ?? this.promoterName,
    stripeSessionId: stripeSessionId ?? this.stripeSessionId,
    stripePaymentIntentId: stripePaymentIntentId ?? this.stripePaymentIntentId,
    amountCents: amountCents ?? this.amountCents,
    applicationFeeCents: applicationFeeCents ?? this.applicationFeeCents,
    currency: currency ?? this.currency,
    spendTier: spendTier ?? this.spendTier,
    status: status ?? this.status,
    labeled: labeled ?? this.labeled,
    brainSignalUsed: brainSignalUsed ?? this.brainSignalUsed,
    startTs: startTs ?? this.startTs,
    endTs: endTs ?? this.endTs,
    impressionsAllocated: impressionsAllocated ?? this.impressionsAllocated,
    impressionsServed: impressionsServed ?? this.impressionsServed,
    rankingInputsHash: rankingInputsHash ?? this.rankingInputsHash,
    ugcConsentId: ugcConsentId ?? this.ugcConsentId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    contentId,
    promoterId,
    spendTier,
    status,
    stripePaymentIntentId,
  ];
}
