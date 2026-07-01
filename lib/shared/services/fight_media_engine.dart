import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/dragon_brand.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT MEDIA ENGINE — Hybrid Platform Hub
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Combines short-video discovery, long-form monetization, visual commerce,
/// conversational reach, and private community membership into one engine.
///
/// Wired directly into the Promotion Powerhouse so every status change
/// becomes a lead-gen trigger and ad placement event.
///
/// Pipeline: STATUS CHANGE → AI CAPTION → PLATFORM FORMAT → LEAD CAPTURE
///
/// Firestore Collections:
///   fight_media_campaigns/{id}   — Campaign metadata + platform targets
///   fight_media_ads/{id}         — Individual ad creatives (per platform)
///   fight_media_leads/{id}       — Captured leads (email, source, utm)
///   fight_media_analytics/{id}   — Performance per platform per campaign
/// ═══════════════════════════════════════════════════════════════════════════

// ── Ad Creative ───────────────────────────────────────────────────────────
enum AdStatus {
  draft,
  captioning,
  formatting,
  ready,
  scheduled,
  live,
  paused,
  completed,
}

class FightMediaAd {
  final String id;
  final String campaignId;
  final String platform; // tiktok, youtube, instagram, x, discord
  final String title;
  final String caption;
  final String ctaText;
  final String ctaUrl;
  final String aspectRatio; // 9:16, 1:1, 16:9
  final String? sourceImageUrl;
  final String? sourceVideoUrl;
  final AdStatus status;
  final int impressions;
  final int clicks;
  final int conversions;
  final DateTime createdAt;
  final DateTime? scheduledAt;

  const FightMediaAd({
    required this.id,
    required this.campaignId,
    required this.platform,
    required this.title,
    this.caption = '',
    this.ctaText = 'Watch Now',
    this.ctaUrl = '',
    this.aspectRatio = '9:16',
    this.sourceImageUrl,
    this.sourceVideoUrl,
    this.status = AdStatus.draft,
    this.impressions = 0,
    this.clicks = 0,
    this.conversions = 0,
    required this.createdAt,
    this.scheduledAt,
  });

  double get ctr => impressions > 0 ? (clicks / impressions) * 100.0 : 0.0;
  double get cvr => clicks > 0 ? (conversions / clicks) * 100.0 : 0.0;

  FightMediaAd copyWith({
    AdStatus? status,
    int? impressions,
    int? clicks,
    int? conversions,
  }) => FightMediaAd(
    id: id,
    campaignId: campaignId,
    platform: platform,
    title: title,
    caption: caption,
    ctaText: ctaText,
    ctaUrl: ctaUrl,
    aspectRatio: aspectRatio,
    sourceImageUrl: sourceImageUrl,
    sourceVideoUrl: sourceVideoUrl,
    status: status ?? this.status,
    impressions: impressions ?? this.impressions,
    clicks: clicks ?? this.clicks,
    conversions: conversions ?? this.conversions,
    createdAt: createdAt,
    scheduledAt: scheduledAt,
  );

  Map<String, dynamic> toFirestore() => {
    'campaignId': campaignId,
    'platform': platform,
    'title': title,
    'caption': caption,
    'ctaText': ctaText,
    'ctaUrl': ctaUrl,
    'aspectRatio': aspectRatio,
    'sourceImageUrl': sourceImageUrl,
    'sourceVideoUrl': sourceVideoUrl,
    'status': status.name,
    'impressions': impressions,
    'clicks': clicks,
    'conversions': conversions,
    'createdAt': FieldValue.serverTimestamp(),
    'scheduledAt': scheduledAt != null
        ? Timestamp.fromDate(scheduledAt!)
        : null,
  };
}

// ── Campaign ──────────────────────────────────────────────────────────────
enum CampaignGoal { discovery, revenue, engagement, leadCapture, ticketSales }

class FightMediaCampaign {
  final String id;
  final String eventTitle;
  final String? eventId;
  final CampaignGoal goal;
  final List<String> targetPlatforms;
  final int budgetCents; // 0 = organic only
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<FightMediaAd> ads;
  final int totalLeads;
  final int totalConversions;

  const FightMediaCampaign({
    required this.id,
    required this.eventTitle,
    this.eventId,
    this.goal = CampaignGoal.discovery,
    this.targetPlatforms = const ['tiktok', 'youtube', 'instagram'],
    this.budgetCents = 0,
    required this.createdAt,
    this.startDate,
    this.endDate,
    this.ads = const [],
    this.totalLeads = 0,
    this.totalConversions = 0,
  });

  Map<String, dynamic> toFirestore() => {
    'eventTitle': eventTitle,
    'eventId': eventId,
    'goal': goal.name,
    'targetPlatforms': targetPlatforms,
    'budgetCents': budgetCents,
    'createdAt': FieldValue.serverTimestamp(),
    'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
    'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    'totalLeads': totalLeads,
    'totalConversions': totalConversions,
  };
}

// ── Lead ──────────────────────────────────────────────────────────────────
class FightMediaLead {
  final String id;
  final String email;
  final String? name;
  final String source; // platform id
  final String campaignId;
  final String utmSource;
  final String utmMedium;
  final String utmCampaign;
  final DateTime capturedAt;
  final bool consentGiven;

  const FightMediaLead({
    required this.id,
    required this.email,
    this.name,
    required this.source,
    required this.campaignId,
    this.utmSource = '',
    this.utmMedium = '',
    this.utmCampaign = '',
    required this.capturedAt,
    this.consentGiven = true,
  });

  Map<String, dynamic> toFirestore() => {
    'email': email,
    'name': name,
    'source': source,
    'campaignId': campaignId,
    'utmSource': utmSource,
    'utmMedium': utmMedium,
    'utmCampaign': utmCampaign,
    'capturedAt': FieldValue.serverTimestamp(),
    'consentGiven': consentGiven,
  };
}

// ── PromoBot suggestion ──────────────────────────────────────────────────
class PromoBotSuggestion {
  final String id;
  final String type; // caption, cta, hashtag, schedule, format
  final String suggestion;
  final String reasoning;
  final double confidence;

  const PromoBotSuggestion({
    required this.id,
    required this.type,
    required this.suggestion,
    this.reasoning = '',
    this.confidence = 0.85,
  });
}

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT MEDIA ENGINE SERVICE
/// ═══════════════════════════════════════════════════════════════════════════
class FightMediaEngine with ChangeNotifier {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final _rng = math.Random();

  // ── State ──
  final List<FightMediaCampaign> _campaigns = [];
  final List<FightMediaAd> _ads = [];
  final List<FightMediaLead> _leads = [];
  final List<PromoBotSuggestion> _botSuggestions = [];
  final List<Map<String, dynamic>> _activityLog = [];
  final bool _isLoading = false;

  List<FightMediaCampaign> get campaigns => List.unmodifiable(_campaigns);
  List<FightMediaAd> get ads => List.unmodifiable(_ads);
  List<FightMediaLead> get leads => List.unmodifiable(_leads);
  List<PromoBotSuggestion> get botSuggestions =>
      List.unmodifiable(_botSuggestions);
  List<Map<String, dynamic>> get activityLog => List.unmodifiable(_activityLog);
  bool get isLoading => _isLoading;

  int get totalImpressions => _ads.fold(0, (s, a) => s + a.impressions);
  int get totalClicks => _ads.fold(0, (s, a) => s + a.clicks);
  int get totalConversions => _ads.fold(0, (s, a) => s + a.conversions);
  double get overallCTR =>
      totalImpressions > 0 ? (totalClicks / totalImpressions) * 100 : 0;

  // ═══════════════════════════════════════════════════════════════════
  // CAMPAIGN CREATION
  // ═══════════════════════════════════════════════════════════════════

  /// Create a campaign and auto-generate ads for each target platform
  Future<FightMediaCampaign> createCampaign({
    required String eventTitle,
    String? eventId,
    CampaignGoal goal = CampaignGoal.discovery,
    List<String>? platforms,
    int budgetCents = 0,
  }) async {
    final id = 'fmc_${DateTime.now().millisecondsSinceEpoch}';
    final targetPlatforms = platforms ?? ['tiktok', 'youtube', 'instagram'];

    final campaign = FightMediaCampaign(
      id: id,
      eventTitle: eventTitle,
      eventId: eventId,
      goal: goal,
      targetPlatforms: targetPlatforms,
      budgetCents: budgetCents,
      createdAt: DateTime.now(),
    );

    _campaigns.insert(0, campaign);

    // Auto-generate one ad per platform with correct aspect ratio
    for (final platformId in targetPlatforms) {
      final config = DragonBrand.platforms[platformId];
      final adId = 'fma_${DateTime.now().millisecondsSinceEpoch}_$platformId';
      final ad = FightMediaAd(
        id: adId,
        campaignId: id,
        platform: platformId,
        title: eventTitle,
        caption: _generateCaption(eventTitle, platformId),
        ctaText: _ctaForGoal(goal),
        ctaUrl:
            'https://datafightcentral.web.app/ppv?utm_source=$platformId&utm_campaign=$id',
        aspectRatio: config?.aspectRatio ?? '16:9',
        status: AdStatus.captioning,
        createdAt: DateTime.now(),
      );
      _ads.add(ad);
    }

    _log(
      'CAMPAIGN CREATED',
      '$eventTitle → ${targetPlatforms.length} platforms',
    );

    // Persist
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await _firestore.collection('fight_media_campaigns').doc(id).set({
          ...campaign.toFirestore(),
          'promoterId': uid,
        });
      }
    } catch (_) {}

    notifyListeners();
    return campaign;
  }

  // ═══════════════════════════════════════════════════════════════════
  // PIPELINE SYNC — Status change triggers ad production
  // ═══════════════════════════════════════════════════════════════════

  /// Called by Promotion Powerhouse when media status changes
  /// DRAFT→REVIEW: triggers AI captioning + 3 format variants
  /// REVIEW→LIVE: triggers lead capture card creation
  /// LIVE→BOOSTED: triggers ad scheduling across platforms
  /// BOOSTED→EXPORTED: triggers global market distribution
  Future<void> syncToPipeline({
    required String itemId,
    required String title,
    required String fromStage,
    required String toStage,
    String? imageUrl,
    String? eventId,
  }) async {
    _log('PIPELINE SYNC', '$title: $fromStage → $toStage');

    switch (toStage) {
      case 'review':
        // AI captioning + 3 platform format variants
        await _generateAdVariants(
          title: title,
          imageUrl: imageUrl,
          campaignId: itemId,
        );
        break;
      case 'live':
        // Create lead capture card
        _botSuggestions.insert(
          0,
          PromoBotSuggestion(
            id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
            type: 'lead_capture',
            suggestion:
                'Create pre-sale landing page for "$title" with email capture modal',
            reasoning:
                'Items going LIVE need lead capture to build retargeting audience',
            confidence: 0.92,
          ),
        );
        break;
      case 'boosted':
        // Schedule ads across platforms
        for (final ad in _ads.where(
          (a) => a.campaignId == itemId || a.title == title,
        )) {
          final idx = _ads.indexOf(ad);
          _ads[idx] = ad.copyWith(status: AdStatus.scheduled);
        }
        _log(
          'ADS SCHEDULED',
          '${_ads.where((a) => a.title == title).length} ads queued',
        );
        break;
      case 'exported':
        // Mark ads as live for global distribution
        for (final ad in _ads.where(
          (a) => a.campaignId == itemId || a.title == title,
        )) {
          final idx = _ads.indexOf(ad);
          _ads[idx] = ad.copyWith(status: AdStatus.live);
        }
        _log('ADS LIVE', '$title exported to global markets');
        break;
    }

    notifyListeners();
  }

  /// Generate 3 ad format variants (9:16, 1:1, 16:9) for a piece of content
  Future<void> _generateAdVariants({
    required String title,
    String? imageUrl,
    String? campaignId,
  }) async {
    final formats = DragonBrand.adFormats.values.toList();
    for (final format in formats) {
      final adId = 'fma_${DateTime.now().millisecondsSinceEpoch}_${format.id}';
      _ads.add(
        FightMediaAd(
          id: adId,
          campaignId: campaignId ?? 'pipeline',
          platform: format.platforms.first,
          title: title,
          caption: _generateCaption(title, format.platforms.first),
          ctaText: 'Get Tickets',
          ctaUrl:
              'https://datafightcentral.web.app/ppv?utm_source=${format.platforms.first}',
          aspectRatio: '${format.width}:${format.height}',
          sourceImageUrl: imageUrl,
          status: AdStatus.ready,
          createdAt: DateTime.now(),
        ),
      );
    }
    _log('AD VARIANTS', '3 formats generated for "$title"');
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  // LEAD CAPTURE
  // ═══════════════════════════════════════════════════════════════════

  /// Capture a lead with explicit consent
  Future<void> captureLead({
    required String email,
    String? name,
    required String source,
    required String campaignId,
    String utmSource = '',
    String utmMedium = '',
    String utmCampaign = '',
  }) async {
    final id = 'fml_${DateTime.now().millisecondsSinceEpoch}';
    final lead = FightMediaLead(
      id: id,
      email: email,
      name: name,
      source: source,
      campaignId: campaignId,
      utmSource: utmSource,
      utmMedium: utmMedium,
      utmCampaign: utmCampaign,
      capturedAt: DateTime.now(),
    );
    _leads.add(lead);
    _log('LEAD CAPTURED', '$email via $source');

    try {
      await _firestore
          .collection('fight_media_leads')
          .doc(id)
          .set(lead.toFirestore());
    } catch (_) {}

    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  // PROMO BOT — AI suggestions for captions, CTAs, scheduling
  // ═══════════════════════════════════════════════════════════════════

  /// Generate PromoBot suggestions for a given event/content
  void generateBotSuggestions(String eventTitle) {
    _botSuggestions.clear();

    // Caption suggestions per platform
    for (final entry in DragonBrand.platforms.entries) {
      _botSuggestions.add(
        PromoBotSuggestion(
          id: 'bot_cap_${entry.key}',
          type: 'caption',
          suggestion: _generateCaption(eventTitle, entry.key),
          reasoning:
              '${entry.value.name}: optimized for ${entry.value.strength.toLowerCase()}',
          confidence: 0.8 + _rng.nextDouble() * 0.18,
        ),
      );
    }

    // CTA suggestions
    final ctas = [
      'Get Your Tickets Before They\'re Gone',
      'Watch the Full Fight Card Live',
      'Join Dragon Pass for Early Access',
      'Pre-Order PPV — Save 25%',
      'Follow the Beast — Never Miss a Fight',
    ];
    for (int i = 0; i < ctas.length; i++) {
      _botSuggestions.add(
        PromoBotSuggestion(
          id: 'bot_cta_$i',
          type: 'cta',
          suggestion: ctas[i],
          reasoning: 'High-converting CTA variant ${i + 1}',
          confidence: 0.75 + _rng.nextDouble() * 0.2,
        ),
      );
    }

    // Hashtag suggestions
    _botSuggestions.add(
      const PromoBotSuggestion(
        id: 'bot_hash_1',
        type: 'hashtag',
        suggestion:
            '#DFC #FightNight #UnleashTheBeast #MMA #Boxing #PPV #LiveFight',
        reasoning: 'Core brand + sport + action hashtags for maximum discovery',
        confidence: 0.9,
      ),
    );

    // Scheduling suggestions
    _botSuggestions.add(
      const PromoBotSuggestion(
        id: 'bot_sched_1',
        type: 'schedule',
        suggestion:
            'Post TikTok at 7pm AEST (peak Gen Z), YouTube at 12pm (lunch traffic), Instagram at 6pm (commute)',
        reasoning:
            'Platform-specific peak engagement windows for AU/NZ timezone',
        confidence: 0.88,
      ),
    );

    // Format suggestions
    _botSuggestions.add(
      const PromoBotSuggestion(
        id: 'bot_fmt_1',
        type: 'format',
        suggestion:
            'Lead with knockout clip (3s hook) → fighter walkout → ticket CTA overlay → Dragon crest reveal',
        reasoning:
            'Short-form formula: hook in 1-3s, story in 10-15s, CTA in last 5s',
        confidence: 0.91,
      ),
    );

    _log('PROMO BOT', '${_botSuggestions.length} suggestions generated');
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  // PLATFORM ANALYTICS SIMULATION
  // ═══════════════════════════════════════════════════════════════════

  /// Simulate ad performance tick (call periodically for demo)
  void tickAnalytics() {
    for (int i = 0; i < _ads.length; i++) {
      if (_ads[i].status == AdStatus.live) {
        _ads[i] = _ads[i].copyWith(
          impressions: _ads[i].impressions + _rng.nextInt(500),
          clicks: _ads[i].clicks + _rng.nextInt(30),
          conversions: _ads[i].conversions + _rng.nextInt(5),
        );
      }
    }
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════

  String _generateCaption(String eventTitle, String platformId) {
    final templates = {
      'tiktok': [
        '🔥 $eventTitle is LIVE — who\'s winning this? Drop your pick 👇 #DFC #UnleashTheBeast',
        'This fight card is STACKED 🥊 $eventTitle — link in bio for tickets #FightNight',
        'POV: You\'re ringside at $eventTitle 🐉 #DFC #MMA #Boxing',
      ],
      'youtube': [
        '$eventTitle — Full Fight Card Breakdown | Data Fight Central',
        'EXCLUSIVE: $eventTitle Preview + Predictions | DFC Analysis',
        '$eventTitle — Every Fight, Every Round | DFC Live Coverage',
      ],
      'instagram': [
        '🐉 $eventTitle — Swipe for the full card → Link in bio for tickets',
        'The beast awakens. $eventTitle is coming. Are you ready? 🔥',
        'Fight night energy. $eventTitle — tap to shop merch + get tickets',
      ],
      'x': [
        '🚨 $eventTitle is OFFICIAL. Full card dropping now. Who you got? 🥊🐉',
        'JUST ANNOUNCED: $eventTitle — tickets on sale NOW via @datafightcentral',
        'The Dragon roars. $eventTitle — this one\'s going to be special 🔥',
      ],
      'discord': [
        '🐉 Dragon Pass holders get EARLY ACCESS to $eventTitle tickets. Check #exclusive-drops',
        'AMA LIVE: $eventTitle fight week Q&A starting in #voice-lounge',
      ],
    };
    final options = templates[platformId] ?? templates['tiktok']!;
    return options[_rng.nextInt(options.length)];
  }

  String _ctaForGoal(CampaignGoal goal) {
    switch (goal) {
      case CampaignGoal.discovery:
        return 'Watch Now';
      case CampaignGoal.revenue:
        return 'Buy PPV';
      case CampaignGoal.engagement:
        return 'Join the Conversation';
      case CampaignGoal.leadCapture:
        return 'Get Early Access';
      case CampaignGoal.ticketSales:
        return 'Get Tickets';
    }
  }

  void _log(String action, String detail) {
    _activityLog.insert(0, {
      'action': action,
      'detail': detail,
      'time': DateTime.now(),
    });
    if (_activityLog.length > 100) _activityLog.removeLast();
    debugPrint('[FightMedia] $action: $detail');
  }
}
