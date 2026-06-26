import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Order status lifecycle
enum PromotionOrderStatus {
  draft,
  pendingPayment,
  paid,
  inProduction,
  delivering,
  delivered,
  completed,
  cancelled,
  refunded,
}

/// Factory service packages — what they're paying for
enum FactoryPackage {
  /// Regional blast — one country, one sport, email + social
  regionalBlast,

  /// International push — multi-country, full Factory pipeline
  internationalPush,

  /// PPV marketing campaign — full production package
  ppvCampaign,

  /// Custom — bespoke Factory run, pricing negotiated
  custom,
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PROMOTION ORDER MODEL — Paid Factory Services
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Gyms, fighters, and promoters pay DFC to use the Fight Factory machines:
///   • Email Cannon blasts to international audiences
///   • Social media pipeline across global platforms
///   • Content production (posters, trailers, highlight reels)
///   • SEO/algorithm push for discoverability
///   • Territory-targeted marketing (Asia-Pacific, Europe, Americas, etc.)
///
/// Pricing — SLIDING FEE ON RESULTS:
///   The order has a base package price (flat fee to start the machines),
///   plus the sliding agreement applies to any PPV/ticket revenue
///   generated from the Factory-driven exposure.
///
/// The Factory is owner-only. Users submit orders; DFC executes.
///
/// Firestore: promotion_orders/{orderId}
/// ═══════════════════════════════════════════════════════════════════════════
class PromotionOrder extends Equatable {
  final String id;
  final String userId; // Who's ordering
  final String? promotionName; // e.g. "UFC 310 Aus Push"
  final String? eventId; // Linked event (optional)
  final String? eventTitle;
  final FactoryPackage package;
  final PromotionOrderStatus status;

  // ── What they want ──
  final List<String> targetRegions; // ['AU', 'NZ', 'SG', 'JP']
  final List<String> targetPlatforms; // ['email', 'social', 'seo']
  final List<String> targetSports; // ['MMA', 'Boxing', 'BKFC']
  final String? briefDescription; // What they want promoted
  final List<String> contentUrls; // Poster/trailer/content links

  // ── Pricing ──
  final int basePriceCents; // Flat fee for Factory activation
  final String currency;
  final int? estimatedReachMin; // Estimated reach range
  final int? estimatedReachMax;

  // ── Sliding agreement on generated revenue ──
  // The DFC sliding fee (30–50%) applies to any PPV/ticket revenue
  // that comes from this Factory campaign's exposure.
  final int actualReach; // Tracked during delivery
  final int actualEngagements;
  final int generatedRevenueCents; // Revenue attributed to this campaign

  // ── Payment ──
  final String? stripePaymentIntentId;
  final String? stripeInvoiceId;
  final DateTime? paidAt;

  // ── Delivery tracking ──
  final DateTime? productionStartedAt;
  final DateTime? deliveredAt;
  final DateTime? completedAt;
  final String? deliveryNotes; // Owner notes on what was done
  final List<String> deliverables; // URLs to delivered content

  // ── Metadata ──
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PromotionOrder({
    required this.id,
    required this.userId,
    this.promotionName,
    this.eventId,
    this.eventTitle,
    this.package = FactoryPackage.regionalBlast,
    this.status = PromotionOrderStatus.draft,
    this.targetRegions = const [],
    this.targetPlatforms = const [],
    this.targetSports = const [],
    this.briefDescription,
    this.contentUrls = const [],
    this.basePriceCents = 0,
    this.currency = 'AUD',
    this.estimatedReachMin,
    this.estimatedReachMax,
    this.actualReach = 0,
    this.actualEngagements = 0,
    this.generatedRevenueCents = 0,
    this.stripePaymentIntentId,
    this.stripeInvoiceId,
    this.paidAt,
    this.productionStartedAt,
    this.deliveredAt,
    this.completedAt,
    this.deliveryNotes,
    this.deliverables = const [],
    required this.createdAt,
    this.updatedAt,
  });

  // ── Computed ──

  double get basePrice => basePriceCents / 100.0;
  double get generatedRevenue => generatedRevenueCents / 100.0;

  bool get isPaid =>
      status != PromotionOrderStatus.draft &&
      status != PromotionOrderStatus.pendingPayment &&
      status != PromotionOrderStatus.cancelled;

  bool get isActive =>
      status == PromotionOrderStatus.inProduction ||
      status == PromotionOrderStatus.delivering;

  String get statusLabel => switch (status) {
    PromotionOrderStatus.draft => 'DRAFT',
    PromotionOrderStatus.pendingPayment => 'AWAITING PAYMENT',
    PromotionOrderStatus.paid => 'PAID — QUEUED',
    PromotionOrderStatus.inProduction => 'IN PRODUCTION',
    PromotionOrderStatus.delivering => 'DELIVERING',
    PromotionOrderStatus.delivered => 'DELIVERED',
    PromotionOrderStatus.completed => 'COMPLETED',
    PromotionOrderStatus.cancelled => 'CANCELLED',
    PromotionOrderStatus.refunded => 'REFUNDED',
  };

  String get packageLabel => switch (package) {
    FactoryPackage.regionalBlast => 'Regional Blast',
    FactoryPackage.internationalPush => 'International Push',
    FactoryPackage.ppvCampaign => 'PPV Campaign',
    FactoryPackage.custom => 'Custom Package',
  };

  /// Base package pricing (cents) — what the Factory charges upfront.
  static int packagePriceCents(FactoryPackage pkg) => switch (pkg) {
    FactoryPackage.regionalBlast => 9999, // $99.99
    FactoryPackage.internationalPush => 29999, // $299.99
    FactoryPackage.ppvCampaign => 49999, // $499.99
    FactoryPackage.custom => 0, // Negotiated
  };

  // ── Firestore ──

  factory PromotionOrder.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? ts(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return PromotionOrder(
      id: doc.id,
      userId: d['userId']?.toString() ?? '',
      promotionName: d['promotionName']?.toString(),
      eventId: d['eventId']?.toString(),
      eventTitle: d['eventTitle']?.toString(),
      package: FactoryPackage.values.firstWhere(
        (e) => e.name == d['package'],
        orElse: () => FactoryPackage.regionalBlast,
      ),
      status: PromotionOrderStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => PromotionOrderStatus.draft,
      ),
      targetRegions: List<String>.from(d['targetRegions'] ?? []),
      targetPlatforms: List<String>.from(d['targetPlatforms'] ?? []),
      targetSports: List<String>.from(d['targetSports'] ?? []),
      briefDescription: d['briefDescription']?.toString(),
      contentUrls: List<String>.from(d['contentUrls'] ?? []),
      basePriceCents: (d['basePriceCents'] as num?)?.toInt() ?? 0,
      currency: d['currency']?.toString() ?? 'AUD',
      estimatedReachMin: (d['estimatedReachMin'] as num?)?.toInt(),
      estimatedReachMax: (d['estimatedReachMax'] as num?)?.toInt(),
      actualReach: (d['actualReach'] as num?)?.toInt() ?? 0,
      actualEngagements: (d['actualEngagements'] as num?)?.toInt() ?? 0,
      generatedRevenueCents: (d['generatedRevenueCents'] as num?)?.toInt() ?? 0,
      stripePaymentIntentId: d['stripePaymentIntentId']?.toString(),
      stripeInvoiceId: d['stripeInvoiceId']?.toString(),
      paidAt: ts(d['paidAt']),
      productionStartedAt: ts(d['productionStartedAt']),
      deliveredAt: ts(d['deliveredAt']),
      completedAt: ts(d['completedAt']),
      deliveryNotes: d['deliveryNotes']?.toString(),
      deliverables: List<String>.from(d['deliverables'] ?? []),
      createdAt: ts(d['createdAt']) ?? DateTime.now(),
      updatedAt: ts(d['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    if (promotionName != null) 'promotionName': promotionName,
    if (eventId != null) 'eventId': eventId,
    if (eventTitle != null) 'eventTitle': eventTitle,
    'package': package.name,
    'status': status.name,
    'targetRegions': targetRegions,
    'targetPlatforms': targetPlatforms,
    'targetSports': targetSports,
    if (briefDescription != null) 'briefDescription': briefDescription,
    'contentUrls': contentUrls,
    'basePriceCents': basePriceCents,
    'currency': currency,
    if (estimatedReachMin != null) 'estimatedReachMin': estimatedReachMin,
    if (estimatedReachMax != null) 'estimatedReachMax': estimatedReachMax,
    'actualReach': actualReach,
    'actualEngagements': actualEngagements,
    'generatedRevenueCents': generatedRevenueCents,
    if (stripePaymentIntentId != null)
      'stripePaymentIntentId': stripePaymentIntentId,
    if (stripeInvoiceId != null) 'stripeInvoiceId': stripeInvoiceId,
    if (paidAt != null) 'paidAt': Timestamp.fromDate(paidAt!),
    if (productionStartedAt != null)
      'productionStartedAt': Timestamp.fromDate(productionStartedAt!),
    if (deliveredAt != null) 'deliveredAt': Timestamp.fromDate(deliveredAt!),
    if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
    if (deliveryNotes != null) 'deliveryNotes': deliveryNotes,
    'deliverables': deliverables,
    'createdAt': Timestamp.fromDate(createdAt),
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
  };

  PromotionOrder copyWith({
    String? id,
    String? userId,
    String? promotionName,
    String? eventId,
    String? eventTitle,
    FactoryPackage? package,
    PromotionOrderStatus? status,
    List<String>? targetRegions,
    List<String>? targetPlatforms,
    List<String>? targetSports,
    String? briefDescription,
    List<String>? contentUrls,
    int? basePriceCents,
    String? currency,
    int? estimatedReachMin,
    int? estimatedReachMax,
    int? actualReach,
    int? actualEngagements,
    int? generatedRevenueCents,
    String? stripePaymentIntentId,
    String? stripeInvoiceId,
    DateTime? paidAt,
    DateTime? productionStartedAt,
    DateTime? deliveredAt,
    DateTime? completedAt,
    String? deliveryNotes,
    List<String>? deliverables,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PromotionOrder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      promotionName: promotionName ?? this.promotionName,
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      package: package ?? this.package,
      status: status ?? this.status,
      targetRegions: targetRegions ?? this.targetRegions,
      targetPlatforms: targetPlatforms ?? this.targetPlatforms,
      targetSports: targetSports ?? this.targetSports,
      briefDescription: briefDescription ?? this.briefDescription,
      contentUrls: contentUrls ?? this.contentUrls,
      basePriceCents: basePriceCents ?? this.basePriceCents,
      currency: currency ?? this.currency,
      estimatedReachMin: estimatedReachMin ?? this.estimatedReachMin,
      estimatedReachMax: estimatedReachMax ?? this.estimatedReachMax,
      actualReach: actualReach ?? this.actualReach,
      actualEngagements: actualEngagements ?? this.actualEngagements,
      generatedRevenueCents:
          generatedRevenueCents ?? this.generatedRevenueCents,
      stripePaymentIntentId:
          stripePaymentIntentId ?? this.stripePaymentIntentId,
      stripeInvoiceId: stripeInvoiceId ?? this.stripeInvoiceId,
      paidAt: paidAt ?? this.paidAt,
      productionStartedAt: productionStartedAt ?? this.productionStartedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      completedAt: completedAt ?? this.completedAt,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      deliverables: deliverables ?? this.deliverables,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    promotionName,
    eventId,
    package,
    status,
    basePriceCents,
    actualReach,
    generatedRevenueCents,
    createdAt,
  ];
}
