import 'package:equatable/equatable.dart';

/// ═════════════════════════════════════════════════════════════════════════
/// PPV STOREFRONT PRESENTATION MODELS
/// ═════════════════════════════════════════════════════════════════════════
/// Mobile-optimized models for rendering PPV events, pricing tiers, and
/// fight cards without heavy Firestore document overhead.

/// PPV pricing tier option (Standard, Premium, VIP, etc.)
class PPVPricingTier extends Equatable {
  final String id;
  final String title;
  final String priceLabel; // e.g. "$49.99"
  final String description;
  final List<String> features;
  final int priceAUD;
  final bool isRecommended;

  const PPVPricingTier({
    required this.id,
    required this.title,
    required this.priceLabel,
    required this.description,
    required this.features,
    required this.priceAUD,
    this.isRecommended = false,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    priceLabel,
    description,
    features,
    priceAUD,
    isRecommended,
  ];

  factory PPVPricingTier.fromFirestore(Map<String, dynamic> data) {
    final amountCents = (data['amountCents'] as num?)?.toInt() ?? 0;
    final priceAUD = amountCents;
    final dollarAmount = (priceAUD / 100).toStringAsFixed(2);

    return PPVPricingTier(
      id: data['id'] as String? ?? 'standard',
      title: data['title'] as String? ?? 'Standard',
      priceLabel: '\$$dollarAmount AUD',
      description: data['description'] as String? ?? 'Event access',
      features: List<String>.from(data['features'] as List? ?? []),
      priceAUD: priceAUD,
      isRecommended: (data['isRecommended'] as bool?) ?? false,
    );
  }
}

/// Single fight on the PPV card
class PPVFightPreview extends Equatable {
  final String fighterId1;
  final String fighterId2;
  final String fighter1Name;
  final String fighter2Name;
  final String? fighter1ImageUrl;
  final String? fighter2ImageUrl;
  final String weightClass;
  final String? mainTitle; // "MAIN EVENT", "CO-MAIN", etc
  final int? order;

  const PPVFightPreview({
    required this.fighterId1,
    required this.fighterId2,
    required this.fighter1Name,
    required this.fighter2Name,
    this.fighter1ImageUrl,
    this.fighter2ImageUrl,
    required this.weightClass,
    this.mainTitle,
    this.order,
  });

  @override
  List<Object?> get props => [
    fighterId1,
    fighterId2,
    fighter1Name,
    fighter2Name,
    fighter1ImageUrl,
    fighter2ImageUrl,
    weightClass,
    mainTitle,
    order,
  ];

  factory PPVFightPreview.fromMap(Map<String, dynamic> data) {
    return PPVFightPreview(
      fighterId1: data['fighterId1'] as String? ?? '',
      fighterId2: data['fighterId2'] as String? ?? '',
      fighter1Name: data['fighter1Name'] as String? ?? 'Fighter 1',
      fighter2Name: data['fighter2Name'] as String? ?? 'Fighter 2',
      fighter1ImageUrl: data['fighter1ImageUrl'] as String?,
      fighter2ImageUrl: data['fighter2ImageUrl'] as String?,
      weightClass: data['weightClass'] as String? ?? 'Open Weight',
      mainTitle: data['mainTitle'] as String?,
      order: data['order'] as int?,
    );
  }
}

/// Full PPV event for storefront display
class PPVStorefrontEvent extends Equatable {
  final String id;
  final String title;
  final String? subtitle;
  final String? description;
  final String? promotion; // UFC, Bellator, etc
  final String? sportType; // MMA, Boxing, etc
  final DateTime eventDate;
  final String? posterUrl;
  final String? heroImageUrl;
  final List<PPVPricingTier> pricingTiers;
  final List<PPVFightPreview> fightCard;
  final int? peakViewers;
  final String eventStatus; // announced, presale, onSale, live, replay, expired
  final String? trailerUrl;
  final bool hasDrmProtection;
  final bool hasReplayAccess;
  final bool hasMultiCam;

  const PPVStorefrontEvent({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    this.promotion,
    this.sportType,
    required this.eventDate,
    this.posterUrl,
    this.heroImageUrl,
    required this.pricingTiers,
    required this.fightCard,
    this.peakViewers,
    required this.eventStatus,
    this.trailerUrl,
    this.hasDrmProtection = true,
    this.hasReplayAccess = true,
    this.hasMultiCam = false,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    subtitle,
    description,
    promotion,
    sportType,
    eventDate,
    posterUrl,
    heroImageUrl,
    pricingTiers,
    fightCard,
    peakViewers,
    eventStatus,
    trailerUrl,
    hasDrmProtection,
    hasReplayAccess,
    hasMultiCam,
  ];

  factory PPVStorefrontEvent.fromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
    final pricingTiersData =
        (data['pricingTiers'] as Map<String, dynamic>?) ?? {};
    final pricingTiers =
        pricingTiersData.entries
            .map(
              (e) => PPVPricingTier.fromFirestore({
                'id': e.key,
                ...(e.value as Map<String, dynamic>),
              }),
            )
            .toList()
          ..sort((a, b) => a.priceAUD.compareTo(b.priceAUD));

    final fightCardData =
        (data['fightCard'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final fightCard = fightCardData
        .asMap()
        .entries
        .map((e) => PPVFightPreview.fromMap({'order': e.key, ...e.value}))
        .toList();

    return PPVStorefrontEvent(
      id: docId,
      title: data['title'] as String? ?? 'Event Title',
      subtitle: data['subtitle'] as String?,
      description: data['description'] as String?,
      promotion: data['promotion'] as String?,
      sportType: data['sportType'] as String?,
      eventDate: data['eventDate'] != null
          ? DateTime.parse(data['eventDate'] as String)
          : DateTime.now(),
      posterUrl: data['posterUrl'] as String?,
      heroImageUrl: data['heroImageUrl'] as String?,
      pricingTiers: pricingTiers.isEmpty
          ? [
              const PPVPricingTier(
                id: 'standard',
                title: 'Standard',
                priceLabel: '\$49.99 AUD',
                description: 'Event access',
                features: ['Live stream', 'Standard quality'],
                priceAUD: 4999,
              ),
            ]
          : pricingTiers,
      fightCard: fightCard,
      peakViewers: data['peakViewers'] as int?,
      eventStatus: data['eventStatus'] as String? ?? 'onSale',
      trailerUrl: data['trailerUrl'] as String?,
      hasDrmProtection: (data['hasDrmProtection'] as bool?) ?? true,
      hasReplayAccess: (data['hasReplayAccess'] as bool?) ?? true,
      hasMultiCam: (data['hasMultiCam'] as bool?) ?? false,
    );
  }

  /// Get default tier (usually the recommended one, or middle tier)
  PPVPricingTier getDefaultTier() {
    final recommended = pricingTiers.firstWhere(
      (t) => t.isRecommended,
      orElse: () => pricingTiers[pricingTiers.length ~/ 2],
    );
    return recommended;
  }
}
