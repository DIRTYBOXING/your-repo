import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MARKET EXPORT ENGINE — Overseas Revenue Pipeline
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Takes AU/NZ fight content (War Room posters, conveyor belt output,
/// social engine posts) and packages it for international distribution.
///
/// Every exported piece injects PPV buy-links and regional pricing
/// to drive overseas revenue.
///
/// Pipeline: Source → Package → Localize → Inject PPV Link → Dispatch
///
/// Firestore Collections:
///   export_packages/{packageId}   — Queued/sent export payloads
///   export_analytics/{marketId}   — Conversion data per market region
///
/// ═══════════════════════════════════════════════════════════════════════════

// ─── Target Market Region ────────────────────────────────────────────────
class ExportMarket {
  final String id;
  final String name;
  final String regionCode; // AUNZ, SEA, NA, UK_EU, LATAM, AFRICA, JAPAN
  final String currency;
  final String currencySymbol;
  final String locale;
  final List<String> platforms; // primary platforms for this market
  final double ppvMultiplier; // price adjustment vs AUD baseline
  final bool isActive;

  const ExportMarket({
    required this.id,
    required this.name,
    required this.regionCode,
    required this.currency,
    required this.currencySymbol,
    required this.locale,
    required this.platforms,
    this.ppvMultiplier = 1.0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'regionCode': regionCode,
    'currency': currency,
    'currencySymbol': currencySymbol,
    'locale': locale,
    'platforms': platforms,
    'ppvMultiplier': ppvMultiplier,
    'isActive': isActive,
  };

  factory ExportMarket.fromMap(Map<String, dynamic> d) => ExportMarket(
    id: d['id'] ?? '',
    name: d['name'] ?? '',
    regionCode: d['regionCode'] ?? '',
    currency: d['currency'] ?? 'USD',
    currencySymbol: d['currencySymbol'] ?? r'$',
    locale: d['locale'] ?? 'en_US',
    platforms: List<String>.from(d['platforms'] ?? []),
    ppvMultiplier: (d['ppvMultiplier'] ?? 1.0).toDouble(),
    isActive: d['isActive'] ?? true,
  );
}

// ─── Export Package (a single content blast to a market) ─────────────────
enum ExportStatus { queued, processing, dispatched, delivered, failed }

class ExportPackage {
  final String id;
  final String sourceType; // 'war_room', 'conveyor_belt', 'social_engine'
  final String sourceId;
  final String title;
  final String body;
  final String? imageUrl;
  final String? videoUrl;
  final String ppvLink;
  final String ppvPrice; // localized price string e.g. "$9.99 USD"
  final ExportMarket market;
  final List<String> targetPlatforms;
  final Map<String, String> platformVariants; // platform → localized body
  final ExportStatus status;
  final DateTime createdAt;
  final DateTime? dispatchedAt;
  final String createdBy;
  final String? campaignTag;

  const ExportPackage({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.title,
    required this.body,
    this.imageUrl,
    this.videoUrl,
    required this.ppvLink,
    required this.ppvPrice,
    required this.market,
    required this.targetPlatforms,
    this.platformVariants = const {},
    this.status = ExportStatus.queued,
    required this.createdAt,
    this.dispatchedAt,
    required this.createdBy,
    this.campaignTag,
  });

  Map<String, dynamic> toMap() => {
    'sourceType': sourceType,
    'sourceId': sourceId,
    'title': title,
    'body': body,
    'imageUrl': imageUrl,
    'videoUrl': videoUrl,
    'ppvLink': ppvLink,
    'ppvPrice': ppvPrice,
    'market': market.toMap(),
    'targetPlatforms': targetPlatforms,
    'platformVariants': platformVariants,
    'status': status.name,
    'createdAt': Timestamp.fromDate(createdAt),
    'dispatchedAt': dispatchedAt != null
        ? Timestamp.fromDate(dispatchedAt!)
        : null,
    'createdBy': createdBy,
    'campaignTag': campaignTag,
  };

  factory ExportPackage.fromMap(String id, Map<String, dynamic> d) {
    return ExportPackage(
      id: id,
      sourceType: d['sourceType'] ?? '',
      sourceId: d['sourceId'] ?? '',
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      imageUrl: d['imageUrl'],
      videoUrl: d['videoUrl'],
      ppvLink: d['ppvLink'] ?? '',
      ppvPrice: d['ppvPrice'] ?? '',
      market: ExportMarket.fromMap(
        Map<String, dynamic>.from(d['market'] ?? {}),
      ),
      targetPlatforms: List<String>.from(d['targetPlatforms'] ?? []),
      platformVariants: Map<String, String>.from(d['platformVariants'] ?? {}),
      status: ExportStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => ExportStatus.queued,
      ),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dispatchedAt: (d['dispatchedAt'] as Timestamp?)?.toDate(),
      createdBy: d['createdBy'] ?? '',
      campaignTag: d['campaignTag'],
    );
  }
}

// ─── Export Analytics per Market ─────────────────────────────────────────
class ExportAnalytics {
  final String marketId;
  final int totalExports;
  final int totalDelivered;
  final int ppvClicks;
  final int ppvPurchases;
  final double revenueGenerated; // in AUD
  final DateTime lastExportAt;

  const ExportAnalytics({
    required this.marketId,
    this.totalExports = 0,
    this.totalDelivered = 0,
    this.ppvClicks = 0,
    this.ppvPurchases = 0,
    this.revenueGenerated = 0.0,
    required this.lastExportAt,
  });

  double get conversionRate =>
      ppvClicks > 0 ? (ppvPurchases / ppvClicks) * 100 : 0.0;

  factory ExportAnalytics.fromMap(Map<String, dynamic> d) => ExportAnalytics(
    marketId: d['marketId'] ?? '',
    totalExports: d['totalExports'] ?? 0,
    totalDelivered: d['totalDelivered'] ?? 0,
    ppvClicks: d['ppvClicks'] ?? 0,
    ppvPurchases: d['ppvPurchases'] ?? 0,
    revenueGenerated: (d['revenueGenerated'] ?? 0.0).toDouble(),
    lastExportAt: (d['lastExportAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

/// ═══════════════════════════════════════════════════════════════════════════
/// THE ENGINE
/// ═══════════════════════════════════════════════════════════════════════════
class MarketExportEngine extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  static const _packagesCol = 'export_packages';
  static const _analyticsCol = 'export_analytics';

  // ── State ──
  final List<ExportPackage> _packages = [];
  final Map<String, ExportAnalytics> _analytics = {};
  bool _isExporting = false;

  List<ExportPackage> get packages => List.unmodifiable(_packages);
  Map<String, ExportAnalytics> get analytics => Map.unmodifiable(_analytics);
  bool get isExporting => _isExporting;

  int get totalExported => _packages
      .where(
        (p) =>
            p.status == ExportStatus.dispatched ||
            p.status == ExportStatus.delivered,
      )
      .length;

  // ── Target Markets ─────────────────────────────────────────────────────
  static const List<ExportMarket> targetMarkets = [
    ExportMarket(
      id: 'aunz',
      name: 'Australia & New Zealand',
      regionCode: 'AUNZ',
      currency: 'AUD',
      currencySymbol: r'A$',
      locale: 'en_AU',
      platforms: ['facebook', 'instagram', 'tiktok', 'x', 'youtube'],
    ),
    ExportMarket(
      id: 'na',
      name: 'North America',
      regionCode: 'NA',
      currency: 'USD',
      currencySymbol: r'$',
      locale: 'en_US',
      platforms: ['instagram', 'tiktok', 'x', 'youtube', 'threads'],
      ppvMultiplier: 1.05,
    ),
    ExportMarket(
      id: 'uk_eu',
      name: 'United Kingdom & Europe',
      regionCode: 'UK_EU',
      currency: 'GBP',
      currencySymbol: '£',
      locale: 'en_GB',
      platforms: ['instagram', 'tiktok', 'x', 'youtube', 'threads'],
      ppvMultiplier: 0.85,
    ),
    ExportMarket(
      id: 'sea',
      name: 'Southeast Asia',
      regionCode: 'SEA',
      currency: 'THB',
      currencySymbol: '฿',
      locale: 'th_TH',
      platforms: ['facebook', 'tiktok', 'youtube', 'instagram'],
      ppvMultiplier: 0.55,
    ),
    ExportMarket(
      id: 'japan',
      name: 'Japan',
      regionCode: 'JAPAN',
      currency: 'JPY',
      currencySymbol: '¥',
      locale: 'ja_JP',
      platforms: ['youtube', 'x', 'instagram', 'tiktok'],
      ppvMultiplier: 0.75,
    ),
    ExportMarket(
      id: 'latam',
      name: 'Latin America',
      regionCode: 'LATAM',
      currency: 'BRL',
      currencySymbol: r'R$',
      locale: 'pt_BR',
      platforms: ['instagram', 'tiktok', 'youtube', 'facebook', 'whatsapp'],
      ppvMultiplier: 0.40,
    ),
    ExportMarket(
      id: 'africa',
      name: 'Africa',
      regionCode: 'AFRICA',
      currency: 'ZAR',
      currencySymbol: 'R',
      locale: 'en_ZA',
      platforms: ['facebook', 'whatsapp', 'youtube', 'tiktok', 'x'],
      ppvMultiplier: 0.35,
    ),
    ExportMarket(
      id: 'india',
      name: 'India',
      regionCode: 'INDIA',
      currency: 'INR',
      currencySymbol: '₹',
      locale: 'en_IN',
      platforms: ['youtube', 'instagram', 'whatsapp', 'facebook'],
      ppvMultiplier: 0.30,
    ),
  ];

  // ── PPV Pricing per Currency ───────────────────────────────────────────
  // Baseline: A$14.99 (standard single-event PPV)
  static const double _ppvBaselineAUD = 14.99;

  String localizedPpvPrice(ExportMarket market) {
    final adjusted = (_ppvBaselineAUD * market.ppvMultiplier);
    if (market.currency == 'JPY') {
      return '${market.currencySymbol}${adjusted.round()}';
    }
    return '${market.currencySymbol}${adjusted.toStringAsFixed(2)}';
  }

  // ── PPV Deep Link ──────────────────────────────────────────────────────
  static const String _ppvBaseUrl =
      'https://datafightcentral.web.app/ppv/store';

  String ppvLinkForMarket(ExportMarket market, {String? ppvEventId}) {
    final base = ppvEventId != null
        ? 'https://datafightcentral.web.app/ppv/event/$ppvEventId'
        : _ppvBaseUrl;
    return '$base?region=${market.regionCode}&currency=${market.currency}';
  }

  // ── Platform-specific Formatting ───────────────────────────────────────
  Map<String, String> _buildPlatformVariants(
    String body,
    ExportMarket market,
    String ppvLink,
    String ppvPrice,
  ) {
    final variants = <String, String>{};
    final ppvCta = '\n\nWatch LIVE PPV from $ppvPrice\n$ppvLink';
    final tags = '#DFC #CombatSports #FightNight #PPV';
    final regionTag = '#${market.regionCode.replaceAll('_', '')}';

    for (final platform in market.platforms) {
      switch (platform) {
        case 'facebook':
          variants[platform] =
              '$body$ppvCta\n\n$tags $regionTag\n\nPowered by DataFightCentral';
          break;
        case 'instagram':
          variants[platform] =
              '$body$ppvCta\n\n$tags $regionTag #MMA #Boxing #BareKnuckle #Kickboxing';
          break;
        case 'tiktok':
          final trimmed = body.length > 140
              ? '${body.substring(0, 137)}...'
              : body;
          variants[platform] = '$trimmed $tags $regionTag #FYP #FightTok';
          break;
        case 'x':
          final maxBody = body.length > 200
              ? '${body.substring(0, 197)}...'
              : body;
          variants[platform] = '$maxBody\n\nPPV $ppvPrice $ppvLink $tags';
          break;
        case 'youtube':
          variants[platform] =
              '$body$ppvCta\n\n$tags $regionTag\n\nSubscribe for fight coverage from Australia & New Zealand';
          break;
        case 'threads':
          final maxThreads = body.length > 450
              ? '${body.substring(0, 447)}...'
              : body;
          variants[platform] = '$maxThreads$ppvCta\n\n$tags';
          break;
        case 'bluesky':
          final maxBsky = body.length > 280
              ? '${body.substring(0, 277)}...'
              : body;
          variants[platform] = '$maxBsky\n\nPPV $ppvPrice\n$ppvLink';
          break;
        case 'rednote':
          variants[platform] =
              '$body\n\nPPV $ppvPrice\n$ppvLink\n\n$tags #RedNote';
          break;
        case 'whatsapp':
          variants[platform] =
              '*DFC FIGHT ALERT*\n\n$body\n\nWatch PPV from $ppvPrice\n$ppvLink';
          break;
        case 'linkedin':
          variants[platform] =
              '$body$ppvCta\n\n$tags\n\n#CombatSportsIndustry #SportsMarketing';
          break;
        default:
          variants[platform] = '$body$ppvCta';
      }
    }
    return variants;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // CORE API
  // ═════════════════════════════════════════════════════════════════════════

  /// Export a single content piece to a specific market
  Future<ExportPackage> exportToMarket({
    required String sourceType,
    required String sourceId,
    required String title,
    required String body,
    String? imageUrl,
    String? videoUrl,
    required ExportMarket market,
    String? ppvEventId,
    String? campaignTag,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'system';
    final ppvLink = ppvLinkForMarket(market, ppvEventId: ppvEventId);
    final ppvPrice = localizedPpvPrice(market);
    final variants = _buildPlatformVariants(body, market, ppvLink, ppvPrice);

    final docRef = _firestore.collection(_packagesCol).doc();
    final pkg = ExportPackage(
      id: docRef.id,
      sourceType: sourceType,
      sourceId: sourceId,
      title: title,
      body: body,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      ppvLink: ppvLink,
      ppvPrice: ppvPrice,
      market: market,
      targetPlatforms: market.platforms,
      platformVariants: variants,
      status: ExportStatus.dispatched,
      createdAt: DateTime.now(),
      dispatchedAt: DateTime.now(),
      createdBy: uid,
      campaignTag: campaignTag,
    );

    try {
      await docRef.set(pkg.toMap());
    } catch (e) {
      debugPrint('MarketExportEngine: save failed: $e');
    }

    _packages.insert(0, pkg);
    notifyListeners();
    return pkg;
  }

  /// Blast a content piece to ALL active markets at once
  Future<List<ExportPackage>> exportToAllMarkets({
    required String sourceType,
    required String sourceId,
    required String title,
    required String body,
    String? imageUrl,
    String? videoUrl,
    String? ppvEventId,
    String? campaignTag,
  }) async {
    _isExporting = true;
    notifyListeners();

    final results = <ExportPackage>[];
    for (final market in targetMarkets.where((m) => m.isActive)) {
      final pkg = await exportToMarket(
        sourceType: sourceType,
        sourceId: sourceId,
        title: title,
        body: body,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        market: market,
        ppvEventId: ppvEventId,
        campaignTag: campaignTag ?? 'global_blast',
      );
      results.add(pkg);
    }

    _isExporting = false;
    notifyListeners();
    return results;
  }

  /// Export from War Room poster directly
  Future<List<ExportPackage>> exportWarRoomPoster({
    required String posterId,
    required String eventTitle,
    required String promoBody,
    String? imageUrl,
    String? ppvEventId,
    List<String>? marketIds,
  }) async {
    final markets = marketIds != null
        ? targetMarkets.where((m) => marketIds.contains(m.id)).toList()
        : targetMarkets.where((m) => m.isActive).toList();

    _isExporting = true;
    notifyListeners();

    final results = <ExportPackage>[];
    for (final market in markets) {
      final pkg = await exportToMarket(
        sourceType: 'war_room',
        sourceId: posterId,
        title: eventTitle,
        body: promoBody,
        imageUrl: imageUrl,
        market: market,
        ppvEventId: ppvEventId,
        campaignTag: 'war_room_export',
      );
      results.add(pkg);
    }

    _isExporting = false;
    notifyListeners();
    return results;
  }

  /// Load export history from Firestore
  Future<void> loadHistory({int limit = 100}) async {
    try {
      final snap = await _firestore
          .collection(_packagesCol)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      _packages
        ..clear()
        ..addAll(snap.docs.map((d) => ExportPackage.fromMap(d.id, d.data())));
      notifyListeners();
    } catch (e) {
      debugPrint('MarketExportEngine: load history failed: $e');
    }
  }

  /// Load analytics per market
  Future<void> loadAnalytics() async {
    try {
      final snap = await _firestore.collection(_analyticsCol).get();
      _analytics.clear();
      for (final doc in snap.docs) {
        _analytics[doc.id] = ExportAnalytics.fromMap(doc.data());
      }
      notifyListeners();
    } catch (e) {
      debugPrint('MarketExportEngine: load analytics failed: $e');
    }
  }

  /// Get packages filtered by market
  List<ExportPackage> packagesForMarket(String marketId) =>
      _packages.where((p) => p.market.id == marketId).toList();

  /// Get packages filtered by source
  List<ExportPackage> packagesFromSource(String sourceType) =>
      _packages.where((p) => p.sourceType == sourceType).toList();
}
