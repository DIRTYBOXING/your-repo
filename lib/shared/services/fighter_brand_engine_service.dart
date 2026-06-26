import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC FIGHTER BRAND ENGINE — #117
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Builds and manages fighter personal brands end-to-end.
///
/// Features:
///   • Brand identity creation (colour palette, typography, voice)
///   • Logo generation metadata (symbols, initials, fight style)
///   • Social media templates & post scheduling blueprint
///   • Merchandise concept generator
///   • AI brand strategist — content calendar & growth plan
///   • Brand health scoring (engagement, reach, sentiment)
///
/// Firestore Collections:
///   fighter_brands/{fighterId}                — Brand profile
///   fighter_brands/{fighterId}/content_plans  — AI content calendars
///   fighter_brands/{fighterId}/merch          — Merchandise concepts
///
/// ═══════════════════════════════════════════════════════════════════════════

class BrandIdentity {
  final String fighterId;
  final String fighterName;
  final String nickname;
  final String tagline;
  final List<String> colorPalette; // hex codes
  final String typography; // font family
  final String brandVoice; // 'aggressive', 'humble', 'showman', 'warrior'
  final List<String> logoSymbols; // concepts for logo
  final double brandHealthScore; // 0.0 – 100.0

  const BrandIdentity({
    required this.fighterId,
    required this.fighterName,
    required this.nickname,
    required this.tagline,
    required this.colorPalette,
    required this.typography,
    required this.brandVoice,
    this.logoSymbols = const [],
    this.brandHealthScore = 50.0,
  });
}

class ContentPlan {
  final String id;
  final String fighterId;
  final String month;
  final List<ContentPost> posts;
  final String strategy;
  final double projectedGrowthPercent;

  const ContentPlan({
    required this.id,
    required this.fighterId,
    required this.month,
    required this.posts,
    required this.strategy,
    this.projectedGrowthPercent = 0,
  });
}

class ContentPost {
  final String platform;
  final String contentType; // 'training clip', 'behind scenes', 'fight promo'
  final String caption;
  final String dayOfWeek;
  final String timeSlot; // 'morning', 'afternoon', 'evening'

  const ContentPost({
    required this.platform,
    required this.contentType,
    required this.caption,
    required this.dayOfWeek,
    required this.timeSlot,
  });
}

class MerchConcept {
  final String id;
  final String fighterId;
  final String productType; // 'tshirt', 'hoodie', 'poster', 'cap'
  final String designDescription;
  final double estimatedPrice;
  final double estimatedMargin;

  const MerchConcept({
    required this.id,
    required this.fighterId,
    required this.productType,
    required this.designDescription,
    required this.estimatedPrice,
    required this.estimatedMargin,
  });
}

class FighterBrandEngineService extends ChangeNotifier {
  static final FighterBrandEngineService _instance =
      FighterBrandEngineService._internal();
  factory FighterBrandEngineService() => _instance;
  FighterBrandEngineService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _initialized = false;

  final Map<String, BrandIdentity> _brands = {};
  int _totalBrandsCreated = 0;

  // ── Getters ──
  bool get initialized => _initialized;
  int get totalBrandsCreated => _totalBrandsCreated;
  BrandIdentity? brandFor(String fighterId) => _brands[fighterId];

  // ── Lifecycle ──

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    debugPrint('[BrandEngine] Online — fighter branding active');
    notifyListeners();
  }

  // ── Brand Creation ──

  Future<BrandIdentity> createBrand({
    required String fighterId,
    required String name,
    required String nickname,
    required String fightingStyle,
  }) async {
    final identity = BrandIdentity(
      fighterId: fighterId,
      fighterName: name,
      nickname: nickname,
      tagline: _generateTagline(nickname, fightingStyle),
      colorPalette: _generatePalette(fightingStyle),
      typography: _selectTypography(fightingStyle),
      brandVoice: _determineBrandVoice(fightingStyle),
      logoSymbols: _generateLogoSymbols(nickname, fightingStyle),
    );

    _brands[fighterId] = identity;
    _totalBrandsCreated++;

    await _firestore.collection('fighter_brands').doc(fighterId).set({
      'fighterName': identity.fighterName,
      'nickname': identity.nickname,
      'tagline': identity.tagline,
      'colorPalette': identity.colorPalette,
      'typography': identity.typography,
      'brandVoice': identity.brandVoice,
      'logoSymbols': identity.logoSymbols,
      'brandHealthScore': identity.brandHealthScore,
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint(
      '[BrandEngine] Brand created: "$nickname" — '
      '${identity.brandVoice} voice',
    );
    notifyListeners();
    return identity;
  }

  // ── Content Calendar ──

  ContentPlan generateContentPlan(String fighterId, String month) {
    final brand = _brands[fighterId];
    if (brand == null) {
      return ContentPlan(
        id: 'plan_empty',
        fighterId: fighterId,
        month: month,
        posts: [],
        strategy: 'No brand profile found',
      );
    }

    final posts = <ContentPost>[
      ContentPost(
        platform: 'instagram',
        contentType: 'training clip',
        caption:
            '${brand.nickname} grinding. Fight week loading. ${brand.tagline}',
        dayOfWeek: 'Monday',
        timeSlot: 'morning',
      ),
      ContentPost(
        platform: 'tiktok',
        contentType: 'behind scenes',
        caption: 'Day in the life of ${brand.nickname}',
        dayOfWeek: 'Wednesday',
        timeSlot: 'evening',
      ),
      ContentPost(
        platform: 'youtube',
        contentType: 'fight promo',
        caption: '${brand.fighterName} — the road to the title',
        dayOfWeek: 'Friday',
        timeSlot: 'afternoon',
      ),
      ContentPost(
        platform: 'twitter',
        contentType: 'fight promo',
        caption: 'Prediction: ${brand.nickname} by finish. Who agrees?',
        dayOfWeek: 'Saturday',
        timeSlot: 'evening',
      ),
    ];

    return ContentPlan(
      id: 'plan_${fighterId}_$month',
      fighterId: fighterId,
      month: month,
      posts: posts,
      strategy: 'Build hype through training content & authentic behind-scenes',
      projectedGrowthPercent: 8.5,
    );
  }

  // ── Merch Concepts ──

  List<MerchConcept> generateMerchConcepts(String fighterId) {
    final brand = _brands[fighterId];
    if (brand == null) return [];

    return [
      MerchConcept(
        id: 'merch_tshirt_$fighterId',
        fighterId: fighterId,
        productType: 'tshirt',
        designDescription:
            '"${brand.nickname}" bold text with ${brand.logoSymbols.join(" + ")} graphic',
        estimatedPrice: 35.00,
        estimatedMargin: 0.55,
      ),
      MerchConcept(
        id: 'merch_hoodie_$fighterId',
        fighterId: fighterId,
        productType: 'hoodie',
        designDescription:
            'Back print: ${brand.tagline}. Front: small ${brand.nickname} crest',
        estimatedPrice: 65.00,
        estimatedMargin: 0.50,
      ),
      MerchConcept(
        id: 'merch_poster_$fighterId',
        fighterId: fighterId,
        productType: 'poster',
        designDescription:
            'Fight night poster — ${brand.colorPalette.first} dominant, cinematic style',
        estimatedPrice: 20.00,
        estimatedMargin: 0.70,
      ),
    ];
  }

  // ── Brand Health ──

  double assessBrandHealth(
    String fighterId, {
    int followers = 0,
    double engagementRate = 0,
    int merchSales = 0,
    double sentimentScore = 0.5,
  }) {
    double score = 0;
    score += (followers.clamp(0, 1000000) / 1000000) * 25;
    score += engagementRate.clamp(0, 0.10) / 0.10 * 25;
    score += (merchSales.clamp(0, 1000) / 1000) * 25;
    score += sentimentScore * 25;
    return score.clamp(0, 100);
  }

  // ── Internal ──

  String _generateTagline(String nickname, String style) {
    if (style.contains('striker')) return '"$nickname" — Lights Out on Demand';
    if (style.contains('grappler')) return '"$nickname" — Tap or Nap';
    if (style.contains('wrestler')) return '"$nickname" — Ground Control';
    return '"$nickname" — Built Different';
  }

  List<String> _generatePalette(String style) {
    if (style.contains('striker')) return ['#FF0000', '#1A1A1A', '#FFFFFF'];
    if (style.contains('grappler')) return ['#0066CC', '#1A1A1A', '#FFFFFF'];
    if (style.contains('wrestler')) return ['#FFD700', '#1A1A1A', '#FFFFFF'];
    return ['#00FF88', '#1A1A1A', '#FFFFFF'];
  }

  String _selectTypography(String style) {
    if (style.contains('striker')) return 'Impact';
    if (style.contains('grappler')) return 'Oswald';
    return 'Bebas Neue';
  }

  String _determineBrandVoice(String style) {
    if (style.contains('striker')) return 'aggressive';
    if (style.contains('grappler')) return 'calculated';
    if (style.contains('showman')) return 'showman';
    return 'warrior';
  }

  List<String> _generateLogoSymbols(String nickname, String style) {
    final symbols = <String>[nickname.split(' ').first.toUpperCase()];
    if (style.contains('striker')) symbols.add('fist');
    if (style.contains('grappler')) symbols.add('triangle');
    if (style.contains('wrestler')) symbols.add('shield');
    symbols.add('crown');
    return symbols;
  }
}
