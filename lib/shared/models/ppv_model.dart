import 'package:cloud_firestore/cloud_firestore.dart';

/// PPV Event Status
enum PPVStatus { announced, presale, onSale, live, replay, expired }

/// PPV Pricing Tier
enum PPVTier {
  standard, // Base price
  earlyBird, // Discounted early purchase
  premium, // Includes replay + bonus content
  vip, // Backstage access, exclusive angles, moderated chat
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV MODEL — Pay-Per-View Event for Combat Sports
/// ═══════════════════════════════════════════════════════════════════════════
///
/// DFC is the promotional engine. PPV is how promotions monetize.
/// Every fight event can optionally have a PPV attached to it.
///
/// Revenue model — SLIDING AGREEMENT:
///   • Standard PPV: $24.99–$79.99 (promoter sets price)
///   • DFC cut slides from 30% → 50% based on views/exposure
///   • Not fixed tiers — smooth linear interpolation
///   • Floor: 30% DFC at 0 buys (promoter keeps 70%)
///   • Ceiling: 50% DFC at 10,000+ buys (equal split)
///   • Premium & VIP tiers unlock replay, multi-cam, backstage content
///
/// ═══════════════════════════════════════════════════════════════════════════
class PPVEvent {
  final String id;
  final String eventId; // Links to EventModel
  final String promoterId; // Who owns the revenue
  final String title;
  final String? subtitle; // e.g. "Della Maddalena vs Prates"
  final String? description;
  final String? sport; // e.g. MMA, Boxing, BKFC, Muay Thai
  final String? promotion; // e.g. UFC, IBC, Brawl Stars
  final String? posterUrl;
  final bool isFinalPoster;
  final String? posterAssetKind;
  final String? trailerUrl; // YouTube/Vimeo trailer
  final DateTime eventDate;
  final DateTime? endTime; // When event ends (for scheduling/status)
  final DateTime? presaleStart;
  final DateTime? onSaleStart;
  final DateTime? replayExpiry; // How long replay is available
  final PPVStatus status;

  // Pricing (in cents to avoid floating point)
  final int standardPriceCents; // e.g. 4999 = $49.99
  final int? earlyBirdPriceCents;
  final int? premiumPriceCents;
  final int? vipPriceCents;
  final String currency; // AUD, USD, NZD, etc.

  // Streaming
  final String? streamUrl; // Live HLS/DASH stream URL (set at go-live)
  final String? replayUrl; // Replay stream URL (set after event)
  final String? muxStreamId; // Mux live stream ID (set by Cloud Functions)
  final String? muxPlaybackId; // Mux playback ID (set by Cloud Functions)
  final String? replayPlaybackId; // Mux VOD playback ID (set by webhook)
  final String? drmWidevineLicenseUrl; // Web/Android license server
  final String? drmFairplayLicenseUrl; // Safari/iOS/tvOS license server
  final String? drmFairplayCertificateUrl; // Optional FairPlay cert URL
  final bool replayAvailable; // Whether replay asset is ready
  final List<String> streamPlatforms; // ['DFC', 'TrillerTV+', 'Kayo']

  // Stats
  final int purchaseCount;
  final int peakViewers;
  final int totalRevenueCents;

  // Fight card
  final List<PPVFight> fightCard;

  // Ticket sales
  final String?
  ticketUrl; // External ticket sales link (e.g. Ticketek, Ticketmaster)

  // DFC platform config
  final double
  platformFeePct; // Default 0.30 (30% DFC — you built it, you earned it)
  final bool chatEnabled;
  final bool multiCamEnabled;
  final bool predictionsEnabled;

  /// Sponsor logos/names displayed on the PPV poster
  /// Each entry is a Map with {name, logoUrl} — logoUrl is optional.
  final List<Map<String, String>> sponsors;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PPVEvent({
    required this.id,
    required this.eventId,
    required this.promoterId,
    required this.title,
    this.subtitle,
    this.description,
    this.sport,
    this.promotion,
    this.posterUrl,
    this.isFinalPoster = false,
    this.posterAssetKind,
    this.trailerUrl,
    required this.eventDate,
    this.endTime,
    this.presaleStart,
    this.onSaleStart,
    this.replayExpiry,
    this.status = PPVStatus.announced,
    required this.standardPriceCents,
    this.earlyBirdPriceCents,
    this.premiumPriceCents,
    this.vipPriceCents,
    this.currency = 'AUD',
    this.streamUrl,
    this.replayUrl,
    this.muxStreamId,
    this.muxPlaybackId,
    this.replayPlaybackId,
    this.drmWidevineLicenseUrl,
    this.drmFairplayLicenseUrl,
    this.drmFairplayCertificateUrl,
    this.replayAvailable = false,
    this.streamPlatforms = const ['DFC'],
    this.purchaseCount = 0,
    this.peakViewers = 0,
    this.totalRevenueCents = 0,
    this.fightCard = const [],
    this.platformFeePct = 0.30,
    this.chatEnabled = true,
    this.multiCamEnabled = false,
    this.predictionsEnabled = true,
    this.ticketUrl,
    this.sponsors = const [],
    this.createdAt,
    this.updatedAt,
  });

  // ── Computed ──

  double get standardPrice => standardPriceCents / 100.0;
  double get earlyBirdPrice =>
      (earlyBirdPriceCents ?? standardPriceCents) / 100.0;
  double get premiumPrice => (premiumPriceCents ?? standardPriceCents) / 100.0;
  double get vipPrice => (vipPriceCents ?? standardPriceCents) / 100.0;
  double get totalRevenue => totalRevenueCents / 100.0;
  double get promoterRevenue => totalRevenue * (1 - platformFeePct);
  double get platformRevenue => totalRevenue * platformFeePct;

  /// Sliding DFC fee based on actual buy count / exposure.
  /// Smoothly interpolates from 30% (floor) to 50% (ceiling at 10k buys).
  /// This is a sliding agreement — no hard tier jumps.
  double get slidingDfcFee => calculateSlidingFee(purchaseCount);
  double get slidingPromoterRevenue => totalRevenue * (1 - slidingDfcFee);
  double get slidingPlatformRevenue => totalRevenue * slidingDfcFee;

  /// Static sliding fee calculator — can be used anywhere.
  /// [exposure] = buy count, view count, or any exposure metric.
  /// Returns DFC fee as a decimal (0.30 – 0.50).
  static double calculateSlidingFee(int exposure) {
    const double floor = 0.30;
    const double ceiling = 0.50;
    const int maxExposure = 10000;
    if (exposure <= 0) return floor;
    if (exposure >= maxExposure) return ceiling;
    // Linear interpolation — smooth slide, no hard jumps
    return floor + (ceiling - floor) * (exposure / maxExposure);
  }

  bool get isPresale =>
      presaleStart != null &&
      DateTime.now().isAfter(presaleStart!) &&
      status == PPVStatus.presale;
  bool get isOnSale =>
      status == PPVStatus.onSale || status == PPVStatus.presale;
  bool get isLive => status == PPVStatus.live;
  bool get hasReplay => replayUrl != null && status == PPVStatus.replay;
  bool get hasDrmPlaybackConfig =>
      (drmWidevineLicenseUrl?.trim().isNotEmpty ?? false) ||
      (drmFairplayLicenseUrl?.trim().isNotEmpty ?? false);

  List<String> get fightersNormalized {
    final fighters = <String>{};
    for (final fight in fightCard) {
      if (fight.fighter1Name.trim().isNotEmpty) {
        fighters.add(fight.fighter1Name.trim());
      }
      if (fight.fighter2Name.trim().isNotEmpty) {
        fighters.add(fight.fighter2Name.trim());
      }
    }

    if (fighters.isNotEmpty) {
      return fighters.toList(growable: false);
    }

    final fallback = subtitle ?? title;
    return fallback
        .split(RegExp(r'vs\.?|v\.?|,|/|—|-', caseSensitive: false))
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
  }

  String get priceDisplay {
    final price = isPresale ? earlyBirdPrice : standardPrice;
    return '\$${price.toStringAsFixed(2)} $currency';
  }

  PPVEvent copyWith({
    String? id,
    String? eventId,
    String? promoterId,
    String? title,
    String? subtitle,
    String? description,
    String? sport,
    String? promotion,
    String? posterUrl,
    bool? isFinalPoster,
    String? posterAssetKind,
    String? trailerUrl,
    DateTime? eventDate,
    DateTime? endTime,
    DateTime? presaleStart,
    DateTime? onSaleStart,
    DateTime? replayExpiry,
    PPVStatus? status,
    int? standardPriceCents,
    int? earlyBirdPriceCents,
    int? premiumPriceCents,
    int? vipPriceCents,
    String? currency,
    String? streamUrl,
    String? replayUrl,
    String? muxStreamId,
    String? muxPlaybackId,
    String? replayPlaybackId,
    String? drmWidevineLicenseUrl,
    String? drmFairplayLicenseUrl,
    String? drmFairplayCertificateUrl,
    bool? replayAvailable,
    List<String>? streamPlatforms,
    int? purchaseCount,
    int? peakViewers,
    int? totalRevenueCents,
    List<PPVFight>? fightCard,
    String? ticketUrl,
    double? platformFeePct,
    bool? chatEnabled,
    bool? multiCamEnabled,
    bool? predictionsEnabled,
    List<Map<String, String>>? sponsors,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PPVEvent(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      promoterId: promoterId ?? this.promoterId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      sport: sport ?? this.sport,
      promotion: promotion ?? this.promotion,
      posterUrl: posterUrl ?? this.posterUrl,
      isFinalPoster: isFinalPoster ?? this.isFinalPoster,
      posterAssetKind: posterAssetKind ?? this.posterAssetKind,
      trailerUrl: trailerUrl ?? this.trailerUrl,
      eventDate: eventDate ?? this.eventDate,
      endTime: endTime ?? this.endTime,
      presaleStart: presaleStart ?? this.presaleStart,
      onSaleStart: onSaleStart ?? this.onSaleStart,
      replayExpiry: replayExpiry ?? this.replayExpiry,
      status: status ?? this.status,
      standardPriceCents: standardPriceCents ?? this.standardPriceCents,
      earlyBirdPriceCents: earlyBirdPriceCents ?? this.earlyBirdPriceCents,
      premiumPriceCents: premiumPriceCents ?? this.premiumPriceCents,
      vipPriceCents: vipPriceCents ?? this.vipPriceCents,
      currency: currency ?? this.currency,
      streamUrl: streamUrl ?? this.streamUrl,
      replayUrl: replayUrl ?? this.replayUrl,
      muxStreamId: muxStreamId ?? this.muxStreamId,
      muxPlaybackId: muxPlaybackId ?? this.muxPlaybackId,
      replayPlaybackId: replayPlaybackId ?? this.replayPlaybackId,
      drmWidevineLicenseUrl:
          drmWidevineLicenseUrl ?? this.drmWidevineLicenseUrl,
      drmFairplayLicenseUrl:
          drmFairplayLicenseUrl ?? this.drmFairplayLicenseUrl,
      drmFairplayCertificateUrl:
          drmFairplayCertificateUrl ?? this.drmFairplayCertificateUrl,
      replayAvailable: replayAvailable ?? this.replayAvailable,
      streamPlatforms: streamPlatforms ?? this.streamPlatforms,
      purchaseCount: purchaseCount ?? this.purchaseCount,
      peakViewers: peakViewers ?? this.peakViewers,
      totalRevenueCents: totalRevenueCents ?? this.totalRevenueCents,
      fightCard: fightCard ?? this.fightCard,
      ticketUrl: ticketUrl ?? this.ticketUrl,
      platformFeePct: platformFeePct ?? this.platformFeePct,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      multiCamEnabled: multiCamEnabled ?? this.multiCamEnabled,
      predictionsEnabled: predictionsEnabled ?? this.predictionsEnabled,
      sponsors: sponsors ?? this.sponsors,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get statusLabel {
    switch (status) {
      case PPVStatus.announced:
        return 'ANNOUNCED';
      case PPVStatus.presale:
        return 'PRESALE LIVE';
      case PPVStatus.onSale:
        return 'ON SALE NOW';
      case PPVStatus.live:
        return '🔴 LIVE NOW';
      case PPVStatus.replay:
        return 'REPLAY AVAILABLE';
      case PPVStatus.expired:
        return 'EXPIRED';
    }
  }

  // ── Firestore ──

  factory PPVEvent.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};

    PPVStatus statusFromString(String? s) {
      switch ((s ?? '').toLowerCase()) {
        case 'presale':
          return PPVStatus.presale;
        case 'onsale':
          return PPVStatus.onSale;
        case 'live':
          return PPVStatus.live;
        case 'replay':
          return PPVStatus.replay;
        case 'expired':
          return PPVStatus.expired;
        default:
          return PPVStatus.announced;
      }
    }

    DateTime? ts(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return PPVEvent(
      id: doc.id,
      eventId: d['eventId']?.toString() ?? '',
      promoterId: d['promoterId']?.toString() ?? '',
      title: d['title']?.toString() ?? '',
      subtitle: d['subtitle']?.toString(),
      description: d['description']?.toString(),
      posterUrl: d['posterUrl']?.toString(),
      isFinalPoster: d['isFinalPoster'] as bool? ?? false,
      posterAssetKind: d['posterAssetKind']?.toString(),
      trailerUrl: d['trailerUrl']?.toString(),
      sport: d['sport']?.toString(),
      promotion: d['promotion']?.toString(),
      eventDate: ts(d['eventDate']) ?? DateTime.now(),
      endTime: ts(d['endTime']),
      presaleStart: ts(d['presaleStart']),
      onSaleStart: ts(d['onSaleStart']),
      replayExpiry: ts(d['replayExpiry']),
      status: statusFromString(d['status']?.toString()),
      standardPriceCents: (d['standardPriceCents'] as num?)?.toInt() ?? 0,
      earlyBirdPriceCents: (d['earlyBirdPriceCents'] as num?)?.toInt(),
      premiumPriceCents: (d['premiumPriceCents'] as num?)?.toInt(),
      vipPriceCents: (d['vipPriceCents'] as num?)?.toInt(),
      currency: d['currency']?.toString() ?? 'AUD',
      streamUrl: d['streamUrl']?.toString(),
      replayUrl: d['replayUrl']?.toString(),
      muxStreamId: d['muxStreamId']?.toString(),
      muxPlaybackId: d['muxPlaybackId']?.toString(),
      replayPlaybackId: d['replayPlaybackId']?.toString(),
      drmWidevineLicenseUrl: d['drmWidevineLicenseUrl']?.toString(),
      drmFairplayLicenseUrl: d['drmFairplayLicenseUrl']?.toString(),
      drmFairplayCertificateUrl: d['drmFairplayCertificateUrl']?.toString(),
      replayAvailable: d['replayAvailable'] as bool? ?? false,
      streamPlatforms: List<String>.from(d['streamPlatforms'] ?? ['DFC']),
      purchaseCount: (d['purchaseCount'] as num?)?.toInt() ?? 0,
      peakViewers: (d['peakViewers'] as num?)?.toInt() ?? 0,
      totalRevenueCents: (d['totalRevenueCents'] as num?)?.toInt() ?? 0,
      fightCard:
          (d['fightCard'] as List?)
              ?.map((f) => PPVFight.fromMap(f as Map<String, dynamic>))
              .toList() ??
          [],
      platformFeePct: (d['platformFeePct'] as num?)?.toDouble() ?? 0.30,
      chatEnabled: d['chatEnabled'] as bool? ?? true,
      multiCamEnabled: d['multiCamEnabled'] as bool? ?? false,
      predictionsEnabled: d['predictionsEnabled'] as bool? ?? true,
      ticketUrl: d['ticketUrl']?.toString(),
      sponsors:
          (d['sponsors'] as List?)
              ?.map((s) => Map<String, String>.from(s as Map))
              .toList() ??
          const [],
      createdAt: ts(d['createdAt']),
      updatedAt: ts(d['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'eventId': eventId,
    'promoterId': promoterId,
    'title': title,
    'subtitle': subtitle,
    'description': description,
    'posterUrl': posterUrl,
    'isFinalPoster': isFinalPoster,
    if (posterAssetKind != null) 'posterAssetKind': posterAssetKind,
    'trailerUrl': trailerUrl,
    'sport': sport,
    'promotion': promotion,
    'eventDate': Timestamp.fromDate(eventDate),
    if (endTime != null) 'endTime': Timestamp.fromDate(endTime!),
    if (presaleStart != null) 'presaleStart': Timestamp.fromDate(presaleStart!),
    if (onSaleStart != null) 'onSaleStart': Timestamp.fromDate(onSaleStart!),
    if (replayExpiry != null) 'replayExpiry': Timestamp.fromDate(replayExpiry!),
    'status': status.name,
    'standardPriceCents': standardPriceCents,
    'earlyBirdPriceCents': earlyBirdPriceCents,
    'premiumPriceCents': premiumPriceCents,
    'vipPriceCents': vipPriceCents,
    'currency': currency,
    'streamUrl': streamUrl,
    'replayUrl': replayUrl,
    if (muxStreamId != null) 'muxStreamId': muxStreamId,
    if (muxPlaybackId != null) 'muxPlaybackId': muxPlaybackId,
    if (replayPlaybackId != null) 'replayPlaybackId': replayPlaybackId,
    if (drmWidevineLicenseUrl != null)
      'drmWidevineLicenseUrl': drmWidevineLicenseUrl,
    if (drmFairplayLicenseUrl != null)
      'drmFairplayLicenseUrl': drmFairplayLicenseUrl,
    if (drmFairplayCertificateUrl != null)
      'drmFairplayCertificateUrl': drmFairplayCertificateUrl,
    'replayAvailable': replayAvailable,
    'streamPlatforms': streamPlatforms,
    'purchaseCount': purchaseCount,
    'peakViewers': peakViewers,
    'totalRevenueCents': totalRevenueCents,
    'fightCard': fightCard.map((f) => f.toMap()).toList(),
    'platformFeePct': platformFeePct,
    'chatEnabled': chatEnabled,
    'multiCamEnabled': multiCamEnabled,
    'predictionsEnabled': predictionsEnabled,
    if (ticketUrl != null) 'ticketUrl': ticketUrl,
    if (sponsors.isNotEmpty) 'sponsors': sponsors,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

/// Individual fight on a PPV card
class PPVFight {
  final String fightId;
  final String fighter1Name;
  final String fighter2Name;
  final String weightClass;
  final int rounds;
  final bool isMainEvent;
  final bool isTitleFight;
  final String? result; // e.g. "KO R2 3:42"

  const PPVFight({
    required this.fightId,
    required this.fighter1Name,
    required this.fighter2Name,
    required this.weightClass,
    this.rounds = 3,
    this.isMainEvent = false,
    this.isTitleFight = false,
    this.result,
  });

  factory PPVFight.fromMap(Map<String, dynamic> m) => PPVFight(
    fightId: m['fightId']?.toString() ?? '',
    fighter1Name: m['fighter1Name']?.toString() ?? '',
    fighter2Name: m['fighter2Name']?.toString() ?? '',
    weightClass: m['weightClass']?.toString() ?? '',
    rounds: (m['rounds'] as num?)?.toInt() ?? 3,
    isMainEvent: m['isMainEvent'] as bool? ?? false,
    isTitleFight: m['isTitleFight'] as bool? ?? false,
    result: m['result']?.toString(),
  );

  Map<String, dynamic> toMap() => {
    'fightId': fightId,
    'fighter1Name': fighter1Name,
    'fighter2Name': fighter2Name,
    'weightClass': weightClass,
    'rounds': rounds,
    'isMainEvent': isMainEvent,
    'isTitleFight': isTitleFight,
    if (result != null) 'result': result,
  };
}

/// PPV Purchase record — tracks who bought what
class PPVPurchase {
  final String id;
  final String userId;
  final String ppvEventId;
  final PPVTier tier;
  final int pricePaidCents;
  final String currency;
  final String paymentMethod; // 'stripe', 'apple_pay', 'google_pay'
  final String? paymentIntentId; // Stripe payment intent
  final String status; // 'completed', 'refunded', 'pending'
  final DateTime purchasedAt;
  final DateTime? refundedAt;

  const PPVPurchase({
    required this.id,
    required this.userId,
    required this.ppvEventId,
    required this.tier,
    required this.pricePaidCents,
    this.currency = 'AUD',
    required this.paymentMethod,
    this.paymentIntentId,
    this.status = 'completed',
    required this.purchasedAt,
    this.refundedAt,
  });

  double get pricePaid => pricePaidCents / 100.0;

  factory PPVPurchase.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? ts(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    PPVTier tierFromString(String? s) {
      switch ((s ?? '').toLowerCase()) {
        case 'earlybird':
          return PPVTier.earlyBird;
        case 'premium':
          return PPVTier.premium;
        case 'vip':
          return PPVTier.vip;
        default:
          return PPVTier.standard;
      }
    }

    return PPVPurchase(
      id: doc.id,
      userId: d['userId']?.toString() ?? '',
      ppvEventId: d['ppvEventId']?.toString() ?? d['ppvId']?.toString() ?? '',
      tier: tierFromString(d['tier']?.toString() ?? d['tierName']?.toString()),
      pricePaidCents:
          (d['pricePaidCents'] as num?)?.toInt() ??
          (d['amountCents'] as num?)?.toInt() ??
          ((d['amount'] as num?)?.toDouble() ?? 0).round(),
      currency: d['currency']?.toString() ?? 'AUD',
      paymentMethod: d['paymentMethod']?.toString() ?? '',
      paymentIntentId:
          d['paymentIntentId']?.toString() ??
          d['stripePaymentId']?.toString() ??
          d['stripePaymentIntentId']?.toString(),
      status: d['status']?.toString() ?? 'completed',
      purchasedAt:
          ts(d['purchasedAt']) ??
          ts(d['paidAt']) ??
          ts(d['completedAt']) ??
          ts(d['createdAt']) ??
          ts(d['updatedAt']) ??
          DateTime.now(),
      refundedAt: ts(d['refundedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'ppvEventId': ppvEventId,
    'tier': tier.name,
    'pricePaidCents': pricePaidCents,
    'currency': currency,
    'paymentMethod': paymentMethod,
    'paymentIntentId': paymentIntentId,
    'status': status,
    'purchasedAt': Timestamp.fromDate(purchasedAt),
    if (refundedAt != null) 'refundedAt': Timestamp.fromDate(refundedAt!),
  };
}
