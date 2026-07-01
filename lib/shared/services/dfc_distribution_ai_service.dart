import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ═════════════════════════════════════════════════════════════════════════════
// DFC AI DISTRIBUTION ENGINE — Channel, Region, Timing & Pricing Intelligence
// ═════════════════════════════════════════════════════════════════════════════
//
// Learns from historical distribution_runs to recommend:
//   • Best channels per event type / region
//   • Optimal launch windows (time-of-day, day-of-week)
//   • Region-appropriate pricing tiers
//   • Ranked distribution plans with confidence scores
//
// Firestore Collections:
//   dfc_ai_plans/{eventId}           — saved distribution plans
//   dfc_ai_performance/{channelKey}  — channel performance signals
//
// ═════════════════════════════════════════════════════════════════════════════

// ── Models ──────────────────────────────────────────────────────────────────

enum SportType {
  mma,
  muayThai,
  boxing,
  kickboxing,
  wrestling,
  bjj,
  karate,
  judo,
  other,
}

enum DistributionTier {
  /// Free social blast — max reach, zero PPV gate
  socialBlast,

  /// Regional OTT push — medium reach, mid-tier revenue
  regionalOtt,

  /// Premium PPV — limited reach, maximum revenue
  premiumPpv,

  /// Global blast — every active channel simultaneously
  globalBlast,

  /// Gym network amplifier — target registered gyms and their followers
  gymNetwork,

  /// Fighter-owned channel push — DM fighters to share their own clips
  fighterPush,
}

class ChannelScore {
  final String channelId;
  final String channelName;
  final String region;
  final double confidenceScore; // 0.0-1.0
  final String rationale;
  final int estimatedReachK;
  final int estimatedRevenueCents;
  final String bestTimeUtc; // e.g. 'Saturday 18:00 UTC'

  const ChannelScore({
    required this.channelId,
    required this.channelName,
    required this.region,
    required this.confidenceScore,
    required this.rationale,
    required this.estimatedReachK,
    this.estimatedRevenueCents = 0,
    required this.bestTimeUtc,
  });

  Map<String, dynamic> toMap() => {
    'channelId': channelId,
    'channelName': channelName,
    'region': region,
    'confidenceScore': confidenceScore,
    'rationale': rationale,
    'estimatedReachK': estimatedReachK,
    'estimatedRevenueCents': estimatedRevenueCents,
    'bestTimeUtc': bestTimeUtc,
  };

  factory ChannelScore.fromMap(Map<String, dynamic> m) => ChannelScore(
    channelId: m['channelId'] ?? '',
    channelName: m['channelName'] ?? '',
    region: m['region'] ?? '',
    confidenceScore: (m['confidenceScore'] as num?)?.toDouble() ?? 0.0,
    rationale: m['rationale'] ?? '',
    estimatedReachK: m['estimatedReachK'] ?? 0,
    estimatedRevenueCents: m['estimatedRevenueCents'] ?? 0,
    bestTimeUtc: m['bestTimeUtc'] ?? '',
  );
}

class RegionRecommendation {
  final String regionCode;
  final String regionLabel;
  final String regionFlag;
  final double audienceFitScore; // 0.0-1.0
  final String sportAffinity; // e.g. "High (Muay Thai culture)"
  final String pricingTier; // 'budget' | 'mid' | 'premium'
  final int recommendedPriceCents;
  final String currency;

  const RegionRecommendation({
    required this.regionCode,
    required this.regionLabel,
    required this.regionFlag,
    required this.audienceFitScore,
    required this.sportAffinity,
    required this.pricingTier,
    required this.recommendedPriceCents,
    required this.currency,
  });
}

class LaunchWindowRecommendation {
  final String region;
  final String dayOfWeek; // 'Saturday'
  final String timeLocal; // '18:00'
  final String timeUtc; // 'Saturday 08:00 UTC'
  final String reasoning;
  final double score; // 0.0-1.0

  const LaunchWindowRecommendation({
    required this.region,
    required this.dayOfWeek,
    required this.timeLocal,
    required this.timeUtc,
    required this.reasoning,
    required this.score,
  });
}

class DistributionPlan {
  final String eventId;
  final String planName;
  final DistributionTier tier;
  final List<ChannelScore> rankedChannels;
  final List<RegionRecommendation> targetRegions;
  final LaunchWindowRecommendation launchWindow;
  final int projectedTotalReachK;
  final int projectedRevenueCents;
  final DateTime generatedAt;

  const DistributionPlan({
    required this.eventId,
    required this.planName,
    required this.tier,
    required this.rankedChannels,
    required this.targetRegions,
    required this.launchWindow,
    required this.projectedTotalReachK,
    required this.projectedRevenueCents,
    required this.generatedAt,
  });

  Map<String, dynamic> toFirestore() => {
    'eventId': eventId,
    'planName': planName,
    'tier': tier.name,
    'rankedChannels': rankedChannels.map((c) => c.toMap()).toList(),
    'projectedTotalReachK': projectedTotalReachK,
    'projectedRevenueCents': projectedRevenueCents,
    'generatedAt': Timestamp.fromDate(generatedAt),
  };
}

// ── Service ──────────────────────────────────────────────────────────────────

class DfcDistributionAiService extends ChangeNotifier {
  DfcDistributionAiService._();
  static final DfcDistributionAiService instance = DfcDistributionAiService._();
  factory DfcDistributionAiService() => instance;

  final _db = FirebaseFirestore.instance;

  // ── Channel Recommendations ──────────────────────────────────────────────

  /// Returns ranked channel recommendations for an event.
  /// Uses historical distribution_runs data to weight scores.
  /// Falls back to static priors when history is insufficient.
  Future<List<ChannelScore>> recommendChannels({
    required String eventId,
    required SportType sport,
    required List<String> targetRegions,
  }) async {
    if (eventId.trim().isEmpty) throw ArgumentError('eventId is required');

    try {
      // Pull historical run performance signals from Firestore
      final histSnap = await _db
          .collection('distribution_runs')
          .where('status', isEqualTo: 'sent')
          .limit(500)
          .get();

      final Map<String, _ChannelPerf> perf = {};
      for (final doc in histSnap.docs) {
        final d = doc.data();
        final ch = (d['channel'] as String? ?? '').toLowerCase();
        final reach = (d['actualReachK'] as num?)?.toInt() ?? 0;
        final revenue = (d['revenueCents'] as num?)?.toInt() ?? 0;
        perf.putIfAbsent(ch, () => _ChannelPerf(ch));
        perf[ch]!.addRun(reach, revenue);
      }

      final priors = _channelPriors(sport, targetRegions);

      // Blend priors with learned performance
      final scored = <ChannelScore>[];
      for (final prior in priors) {
        final learned = perf[prior.channelId];
        final learnedScore = learned != null ? learned.normalizedScore : 0.0;
        final blendedConfidence =
            (prior.confidenceScore * 0.6 + learnedScore * 0.4).clamp(0.0, 1.0);
        scored.add(
          ChannelScore(
            channelId: prior.channelId,
            channelName: prior.channelName,
            region: prior.region,
            confidenceScore: blendedConfidence,
            rationale: prior.rationale,
            estimatedReachK: learned != null
                ? (learned.avgReachK * 1.1).round()
                : prior.estimatedReachK,
            estimatedRevenueCents: learned != null
                ? learned.avgRevenueCents
                : prior.estimatedRevenueCents,
            bestTimeUtc: prior.bestTimeUtc,
          ),
        );
      }

      scored.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
      return scored;
    } catch (e) {
      debugPrint('[DfcAI] recommendChannels error: $e — using priors only');
      return _channelPriors(sport, targetRegions);
    }
  }

  /// Recommends optimal launch window for a given region.
  LaunchWindowRecommendation recommendLaunchWindow(String region) {
    return _launchWindowPriors[region.toLowerCase()] ??
        const LaunchWindowRecommendation(
          region: 'global',
          dayOfWeek: 'Saturday',
          timeLocal: '18:00',
          timeUtc: 'Saturday 08:00 UTC',
          reasoning:
              'Saturday evenings have the highest global PPV engagement across combat sports.',
          score: 0.75,
        );
  }

  /// Returns region-specific pricing recommendations.
  List<RegionRecommendation> recommendRegions({
    required SportType sport,
    required List<String> candidateRegions,
  }) {
    return candidateRegions
        .map((r) => _regionPriors[r.toLowerCase()])
        .whereType<RegionRecommendation>()
        .toList()
      ..sort((a, b) => b.audienceFitScore.compareTo(a.audienceFitScore));
  }

  /// Generates a complete distribution plan and persists it to Firestore.
  Future<DistributionPlan> getDistributionPlan({
    required String eventId,
    required SportType sport,
    required DistributionTier tier,
    required List<String> targetRegions,
  }) async {
    if (eventId.trim().isEmpty) throw ArgumentError('eventId is required');

    final channels = await recommendChannels(
      eventId: eventId,
      sport: sport,
      targetRegions: targetRegions,
    );

    final regions = recommendRegions(
      sport: sport,
      candidateRegions: targetRegions,
    );

    final primaryRegion = targetRegions.isNotEmpty
        ? targetRegions.first
        : 'global';
    final window = recommendLaunchWindow(primaryRegion);

    final plan = DistributionPlan(
      eventId: eventId.trim(),
      planName: _tierLabel(tier),
      tier: tier,
      rankedChannels: channels.take(8).toList(),
      targetRegions: regions,
      launchWindow: window,
      projectedTotalReachK: channels.fold(0, (s, c) => s + c.estimatedReachK),
      projectedRevenueCents: channels.fold(
        0,
        (s, c) => s + c.estimatedRevenueCents,
      ),
      generatedAt: DateTime.now(),
    );

    // Persist plan
    try {
      await _db
          .collection('dfc_ai_plans')
          .doc(eventId.trim())
          .set(plan.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[DfcAI] persist plan error (non-fatal): $e');
    }

    return plan;
  }

  // ── Static Knowledge Base ────────────────────────────────────────────────

  String _tierLabel(DistributionTier tier) =>
      const {
        'socialBlast': 'Social Blast',
        'regionalOtt': 'Regional OTT Push',
        'premiumPpv': 'Premium PPV',
        'globalBlast': 'Global Blast',
        'gymNetwork': 'Gym Network Amplifier',
        'fighterPush': 'Fighter Channel Push',
      }[tier.name] ??
      tier.name;

  List<ChannelScore> _channelPriors(SportType sport, List<String> regions) {
    final bool hasApac = regions.any(
      (r) => ['au', 'jp', 'th', 'ph', 'sg', 'my', 'id_', 'apac'].contains(r),
    );
    final bool hasLatam = regions.any(
      (r) => ['br', 'ar', 'co', 'mx'].contains(r),
    );
    final bool hasUk = regions.any((r) => ['gb'].contains(r));
    final bool hasMena = regions.any((r) => ['ae', 'sa', 'qa'].contains(r));
    final bool hasAfrica = regions.any(
      (r) => ['ng', 'za', 'ke', 'gh'].contains(r),
    );

    final priors = <ChannelScore>[
      const ChannelScore(
        channelId: 'dfc',
        channelName: 'DataFightCentral PPV',
        region: 'global',
        confidenceScore: 0.95,
        rationale: 'Primary PPV platform — always include.',
        estimatedReachK: 8,
        estimatedRevenueCents: 200000,
        bestTimeUtc: 'Saturday 08:00 UTC',
      ),
      const ChannelScore(
        channelId: 'youtube',
        channelName: 'YouTube',
        region: 'global',
        confidenceScore: 0.90,
        rationale: 'Highest global reach for fight content discovery.',
        estimatedReachK: 80,
        bestTimeUtc: 'Saturday 17:00 UTC',
      ),
      const ChannelScore(
        channelId: 'instagram',
        channelName: 'Instagram',
        region: 'global',
        confidenceScore: 0.85,
        rationale: 'Hype clips and fighter reels drive PPV curiosity.',
        estimatedReachK: 45,
        bestTimeUtc: 'Friday 20:00 UTC',
      ),
      const ChannelScore(
        channelId: 'tiktok',
        channelName: 'TikTok',
        region: 'global',
        confidenceScore: 0.82,
        rationale: 'Viral fight clips convert Gen-Z into PPV buyers.',
        estimatedReachK: 120,
        bestTimeUtc: 'Friday 18:00 UTC',
      ),
      if (hasApac)
        const ChannelScore(
          channelId: 'kayo',
          channelName: 'Kayo Sports',
          region: 'au',
          confidenceScore: 0.80,
          rationale:
              'Australia\'s dominant combat sports streaming platform. High PPV conversion.',
          estimatedReachK: 25,
          estimatedRevenueCents: 120000,
          bestTimeUtc: 'Sunday 07:00 UTC',
        ),
      if (hasApac && sport == SportType.muayThai)
        const ChannelScore(
          channelId: 'one_fc',
          channelName: 'ONE Championship',
          region: 'apac',
          confidenceScore: 0.85,
          rationale:
              'ONE Championship dominates Muay Thai and MMA in APAC. Perfect sport fit.',
          estimatedReachK: 40,
          estimatedRevenueCents: 150000,
          bestTimeUtc: 'Friday 12:00 UTC',
        ),
      if (hasApac)
        const ChannelScore(
          channelId: 'abema',
          channelName: 'Abema (Japan)',
          region: 'jp',
          confidenceScore: 0.75,
          rationale: 'Japan\'s #1 digital broadcaster for combat sports.',
          estimatedReachK: 30,
          estimatedRevenueCents: 90000,
          bestTimeUtc: 'Saturday 10:00 UTC',
        ),
      if (hasUk)
        const ChannelScore(
          channelId: 'bt_sport',
          channelName: 'TNT Sports (BT)',
          region: 'gb',
          confidenceScore: 0.78,
          rationale: 'UK\'s primary broadcast partner for boxing and MMA.',
          estimatedReachK: 35,
          estimatedRevenueCents: 180000,
          bestTimeUtc: 'Saturday 19:00 UTC',
        ),
      if (hasUk)
        const ChannelScore(
          channelId: 'dazn',
          channelName: 'DAZN',
          region: 'eu',
          confidenceScore: 0.76,
          rationale: 'European PPV leader. Strong boxing catalog builds trust.',
          estimatedReachK: 28,
          estimatedRevenueCents: 160000,
          bestTimeUtc: 'Saturday 19:00 UTC',
        ),
      if (hasMena)
        const ChannelScore(
          channelId: 'shahid',
          channelName: 'Shahid',
          region: 'ae',
          confidenceScore: 0.72,
          rationale: 'MENA\'s dominant premium OTT — high-spend audience.',
          estimatedReachK: 20,
          estimatedRevenueCents: 140000,
          bestTimeUtc: 'Friday 18:00 UTC',
        ),
      if (hasAfrica)
        const ChannelScore(
          channelId: 'supersport',
          channelName: 'SuperSport',
          region: 'za',
          confidenceScore: 0.70,
          rationale: 'Africa\'s biggest combat sports broadcaster.',
          estimatedReachK: 22,
          estimatedRevenueCents: 80000,
          bestTimeUtc: 'Saturday 17:00 UTC',
        ),
      if (hasLatam)
        const ChannelScore(
          channelId: 'combate',
          channelName: 'Combate',
          region: 'br',
          confidenceScore: 0.73,
          rationale:
              'Brazil\'s dedicated combat sports channel — highly loyal fans.',
          estimatedReachK: 18,
          estimatedRevenueCents: 60000,
          bestTimeUtc: 'Saturday 21:00 UTC',
        ),
      const ChannelScore(
        channelId: 'facebook',
        channelName: 'Facebook',
        region: 'global',
        confidenceScore: 0.68,
        rationale:
            'Older demographic. Good for shared fight hype and event pages.',
        estimatedReachK: 30,
        bestTimeUtc: 'Saturday 15:00 UTC',
      ),
      const ChannelScore(
        channelId: 'fite_tv',
        channelName: 'FITE TV',
        region: 'us',
        confidenceScore: 0.74,
        rationale:
            'Dedicated combat sports PPV marketplace. Pre-qualified buyers.',
        estimatedReachK: 15,
        estimatedRevenueCents: 130000,
        bestTimeUtc: 'Saturday 22:00 UTC',
      ),
    ];

    return priors;
  }

  static const Map<String, LaunchWindowRecommendation> _launchWindowPriors = {
    'au': LaunchWindowRecommendation(
      region: 'au',
      dayOfWeek: 'Saturday',
      timeLocal: '20:00 AEST',
      timeUtc: 'Saturday 10:00 UTC',
      reasoning:
          'Australian fight fans peak on Saturday nights. AEST 20:00 maximises live viewership.',
      score: 0.92,
    ),
    'us': LaunchWindowRecommendation(
      region: 'us',
      dayOfWeek: 'Saturday',
      timeLocal: '18:00 ET',
      timeUtc: 'Saturday 23:00 UTC',
      reasoning:
          'North American PPV tradition: Saturday prime time. Prelims at 18:00, main card 22:00.',
      score: 0.95,
    ),
    'gb': LaunchWindowRecommendation(
      region: 'gb',
      dayOfWeek: 'Saturday',
      timeLocal: '19:00 GMT',
      timeUtc: 'Saturday 19:00 UTC',
      reasoning: 'UK boxing tradition — Saturday evening main events.',
      score: 0.88,
    ),
    'ae': LaunchWindowRecommendation(
      region: 'ae',
      dayOfWeek: 'Friday',
      timeLocal: '21:00 GST',
      timeUtc: 'Friday 17:00 UTC',
      reasoning:
          'Friday is the weekend in MENA. Friday evenings capture peak viewership.',
      score: 0.85,
    ),
    'jp': LaunchWindowRecommendation(
      region: 'jp',
      dayOfWeek: 'Saturday',
      timeLocal: '19:00 JST',
      timeUtc: 'Saturday 10:00 UTC',
      reasoning: 'Japanese fight fans follow weekend evening programming.',
      score: 0.80,
    ),
    'br': LaunchWindowRecommendation(
      region: 'br',
      dayOfWeek: 'Saturday',
      timeLocal: '21:00 BRT',
      timeUtc: 'Sunday 00:00 UTC',
      reasoning:
          'Brazilian fans stay up late for fights. Late Saturday prime time.',
      score: 0.82,
    ),
    'ph': LaunchWindowRecommendation(
      region: 'ph',
      dayOfWeek: 'Saturday',
      timeLocal: '20:00 PHT',
      timeUtc: 'Saturday 12:00 UTC',
      reasoning:
          'Philippines has strong mobile fight viewership on weekend evenings.',
      score: 0.78,
    ),
    'ng': LaunchWindowRecommendation(
      region: 'ng',
      dayOfWeek: 'Saturday',
      timeLocal: '19:00 WAT',
      timeUtc: 'Saturday 18:00 UTC',
      reasoning:
          'Nigeria\'s growing fight audience peaks on Saturday evenings.',
      score: 0.72,
    ),
  };

  static const Map<String, RegionRecommendation> _regionPriors = {
    'au': RegionRecommendation(
      regionCode: 'au',
      regionLabel: 'Australia',
      regionFlag: '🇦🇺',
      audienceFitScore: 0.92,
      sportAffinity: 'Very High (MMA, Kickboxing, Boxing)',
      pricingTier: 'premium',
      recommendedPriceCents: 2999,
      currency: 'AUD',
    ),
    'us': RegionRecommendation(
      regionCode: 'us',
      regionLabel: 'United States',
      regionFlag: '🇺🇸',
      audienceFitScore: 0.95,
      sportAffinity: 'Very High (MMA, Boxing)',
      pricingTier: 'premium',
      recommendedPriceCents: 4999,
      currency: 'USD',
    ),
    'gb': RegionRecommendation(
      regionCode: 'gb',
      regionLabel: 'United Kingdom',
      regionFlag: '🇬🇧',
      audienceFitScore: 0.88,
      sportAffinity: 'High (Boxing, MMA)',
      pricingTier: 'premium',
      recommendedPriceCents: 1999,
      currency: 'GBP',
    ),
    'th': RegionRecommendation(
      regionCode: 'th',
      regionLabel: 'Thailand',
      regionFlag: '🇹🇭',
      audienceFitScore: 0.93,
      sportAffinity: 'Extreme (Muay Thai national sport)',
      pricingTier: 'budget',
      recommendedPriceCents: 299,
      currency: 'THB',
    ),
    'ph': RegionRecommendation(
      regionCode: 'ph',
      regionLabel: 'Philippines',
      regionFlag: '🇵🇭',
      audienceFitScore: 0.87,
      sportAffinity: 'High (Boxing — Pacquiao effect)',
      pricingTier: 'budget',
      recommendedPriceCents: 199,
      currency: 'PHP',
    ),
    'br': RegionRecommendation(
      regionCode: 'br',
      regionLabel: 'Brazil',
      regionFlag: '🇧🇷',
      audienceFitScore: 0.90,
      sportAffinity: 'Very High (MMA, BJJ origin)',
      pricingTier: 'budget',
      recommendedPriceCents: 999,
      currency: 'BRL',
    ),
    'ng': RegionRecommendation(
      regionCode: 'ng',
      regionLabel: 'Nigeria',
      regionFlag: '🇳🇬',
      audienceFitScore: 0.75,
      sportAffinity: 'Growing (Boxing, MMA)',
      pricingTier: 'budget',
      recommendedPriceCents: 100,
      currency: 'USD',
    ),
    'ae': RegionRecommendation(
      regionCode: 'ae',
      regionLabel: 'UAE / Middle East',
      regionFlag: '🇦🇪',
      audienceFitScore: 0.80,
      sportAffinity: 'High (Boxing, MMA, Muay Thai)',
      pricingTier: 'premium',
      recommendedPriceCents: 3999,
      currency: 'AED',
    ),
    'jp': RegionRecommendation(
      regionCode: 'jp',
      regionLabel: 'Japan',
      regionFlag: '🇯🇵',
      audienceFitScore: 0.84,
      sportAffinity: 'High (MMA, Kickboxing, Karate)',
      pricingTier: 'mid',
      recommendedPriceCents: 1500,
      currency: 'JPY',
    ),
    'in_': RegionRecommendation(
      regionCode: 'in_',
      regionLabel: 'India',
      regionFlag: '🇮🇳',
      audienceFitScore: 0.78,
      sportAffinity: 'Growing (Boxing, Kabaddi crossover)',
      pricingTier: 'budget',
      recommendedPriceCents: 149,
      currency: 'INR',
    ),
  };
}

// ── Internal Performance Tracker ────────────────────────────────────────────

class _ChannelPerf {
  final String channelId;
  int _runs = 0;
  int _totalReachK = 0;
  int _totalRevenueCents = 0;

  _ChannelPerf(this.channelId);

  void addRun(int reachK, int revenueCents) {
    _runs++;
    _totalReachK += reachK;
    _totalRevenueCents += revenueCents;
  }

  int get avgReachK => _runs == 0 ? 0 : (_totalReachK / _runs).round();
  int get avgRevenueCents =>
      _runs == 0 ? 0 : (_totalRevenueCents / _runs).round();

  /// 0.0-1.0 score normalised relative to a 100K reach ceiling.
  double get normalizedScore =>
      (avgReachK / 100.0).clamp(0.0, 1.0) * 0.7 +
      (avgRevenueCents / 1000000.0).clamp(0.0, 1.0) * 0.3;
}
