import 'package:equatable/equatable.dart';

/// Metaverse Ad Campaign Engine
/// Generates action-packed promotional content for metaverse platforms
/// Amplifies highlights and re-broadcasts with engagement hooks
class MetaverseAdCampaignEngine {
  static final MetaverseAdCampaignEngine _instance =
      MetaverseAdCampaignEngine._internal();

  factory MetaverseAdCampaignEngine() {
    return _instance;
  }

  MetaverseAdCampaignEngine._internal();

  final List<MetaverseAdCampaign> _activeCampaigns = [];
  final List<ContentHighlight> _highlights = [];

  /// Platform-specific ad configurations
  static const Map<String, AdPlatformConfig> platformConfigs = {
    'roblox': AdPlatformConfig(
      platform: 'Roblox',
      maxDuration: '30s',
      format: 'In-Game Overlay',
      audienceLimit: '500K+',
      emoji: '🎮',
    ),
    'fortnite': AdPlatformConfig(
      platform: 'Fortnite',
      maxDuration: '45s',
      format: 'Battle Pass Event',
      audienceLimit: '350K+ concurrent',
      emoji: '⚡',
    ),
    'decentraland': AdPlatformConfig(
      platform: 'Decentraland',
      maxDuration: '60s',
      format: 'Billboard + NFT Drop',
      audienceLimit: '100K+ daily',
      emoji: '🌐',
    ),
    'sandbox': AdPlatformConfig(
      platform: 'The Sandbox',
      maxDuration: '60s',
      format: 'Avatar Wearable + Game',
      audienceLimit: '150K+ active',
      emoji: '🏜️',
    ),
    'horizon': AdPlatformConfig(
      platform: 'Horizon Worlds',
      maxDuration: '45s',
      format: 'VR Immersive Experience',
      audienceLimit: '75K+ daily',
      emoji: '🥽',
    ),
  };

  /// Action-packed messaging templates
  static const List<String> adMessageTemplates = [
    '💥 ELITE ACTION INCOMING 💥 Watch the BEST matchups live RIGHT NOW on {platform}!',
    '⚡ NEXT LEVEL SKILLS ⚡ Champions are COMPETING on {platform} - JOIN THE ACTION!',
    '🔥 PURE ACTION 🔥 ALL HEART, ALL SKILL — Experience REAL sport energy on {platform}!',
    '🎯 PRECISION STRIKING 🎯 UNSTOPPABLE athletes competing NOW on {platform}!',
    '🏆 CHAMPIONSHIP VIBES 🏆 Witness the CLEANEST performances on {platform} TODAY!',
    '💪 PEAK PERFORMANCE 💪 Elite athletes PUSHING LIMITS on {platform} RIGHT NOW!',
    '🌟 LEGENDARY MATCHUPS 🌟 SEE IT FIRST on {platform} - LIVE ACTION GUARANTEE!',
    '🎬 CINEMATIC MOMENTS 🎬 Every bout is MOVIE-QUALITY on {platform} - WATCH NOW!',
  ];

  /// Get platform config by name
  static AdPlatformConfig? getPlatformConfig(String platform) {
    return platformConfigs[platform.toLowerCase()];
  }

  /// Generate action-packed ad campaign
  Future<MetaverseAdCampaign> generateAdCampaign({
    required String platform,
    required String contentTitle,
    required String contentDescription,
    String? fighterId,
    String category = 'spotlight',
  }) async {
    final config = getPlatformConfig(platform);
    if (config == null) {
      throw Exception('Platform "$platform" not recognized');
    }

    final adMessage = _generateActionPackedMessage(config, contentTitle);
    final highlights = _extractHighlights(contentTitle, contentDescription);
    final callToAction = _generateCTA(config);

    final campaign = MetaverseAdCampaign(
      id: 'campaign_${DateTime.now().millisecondsSinceEpoch}',
      platform: platform,
      title: contentTitle,
      description: contentDescription,
      adMessage: adMessage,
      highlights: highlights,
      callToAction: callToAction,
      config: config,
      fighterId: fighterId,
      createdAt: DateTime.now(),
      status: 'active',
      category: category,
      engagementScore: 0.0,
    );

    _activeCampaigns.add(campaign);
    return campaign;
  }

  /// Amplify content highlights for maximum engagement
  Future<List<ContentHighlight>> amplifyContentHighlights(
    List<String> contentTitles,
  ) async {
    final amplified = <ContentHighlight>[];

    for (final title in contentTitles) {
      final highlight = ContentHighlight(
        id: 'highlight_${DateTime.now().millisecondsSinceEpoch}_${contentTitles.indexOf(title)}',
        originalTitle: title,
        amplifiedTitle: _magnifyTitle(title),
        keyPoints: _extractKeyPoints(title),
        emotionalHook: _generateEmotionalHook(title),
        engagementMagnifier:
            2.5 + (contentTitles.indexOf(title) * 0.15), // 2.5x to 4.0x
        amplificationLevel: 'MAXIMUM',
        createdAt: DateTime.now(),
      );

      amplified.add(highlight);
      _highlights.add(highlight);
    }

    return amplified;
  }

  /// Broadcast amplified content across metaverse platforms
  Future<List<BroadcastResult>> broadcastAmplifiedContent(
    ContentHighlight highlight,
    List<String> platforms,
  ) async {
    final results = <BroadcastResult>[];

    for (final platform in platforms) {
      final config = getPlatformConfig(platform);
      if (config == null) continue;

      final campaign = await generateAdCampaign(
        platform: platform,
        contentTitle: highlight.amplifiedTitle,
        contentDescription: highlight.keyPoints.join(' • '),
        category: 'highlight_broadcast',
      );

      final result = BroadcastResult(
        id: 'broadcast_${DateTime.now().millisecondsSinceEpoch}',
        highlightId: highlight.id,
        campaignId: campaign.id,
        platform: platform,
        amplifiedTitle: highlight.amplifiedTitle,
        audienceReach: config.audienceLimit,
        magnificationFactor: highlight.engagementMagnifier,
        broadcastTime: DateTime.now(),
        expectedEngagement: _estimateEngagement(config, highlight),
        status: 'live',
      );

      results.add(result);
    }

    return results;
  }

  /// Get active campaigns
  List<MetaverseAdCampaign> getActiveCampaigns({String? platform}) {
    if (platform == null) return _activeCampaigns;
    return _activeCampaigns.where((c) => c.platform == platform).toList();
  }

  /// Get all highlights
  List<ContentHighlight> getAllHighlights() => _highlights;

  /// Get top performing highlights
  List<ContentHighlight> getTopHighlights({int limit = 5}) {
    final sorted = [..._highlights]
      ..sort((a, b) => b.engagementMagnifier.compareTo(a.engagementMagnifier));
    return sorted.take(limit).toList();
  }

  // ===== PRIVATE HELPERS =====

  String _generateActionPackedMessage(
    AdPlatformConfig config,
    String contentTitle,
  ) {
    final template =
        adMessageTemplates[DateTime.now().millisecond %
            adMessageTemplates.length];
    return template.replaceFirst('{platform}', config.platform);
  }

  List<String> _extractHighlights(String title, String description) {
    final highlights = <String>[];

    if (title.contains('Championship') || title.contains('Tournament')) {
      highlights.add('🏆 Championship-Level Competition');
    }
    if (title.contains('KO') || title.contains('Knockout')) {
      highlights.add('⚡ Explosive Finishes');
    }
    if (title.contains('Women') || title.contains('Elite')) {
      highlights.add('👑 Elite Fighter Showcase');
    }
    if (title.contains('VR') || title.contains('Immersive')) {
      highlights.add('🥽 Next-Gen VR Experience');
    }
    if (title.contains('Virtual') || title.contains('Digital')) {
      highlights.add('🌐 Digital Arena Innovation');
    }
    if (title.contains('Live')) {
      highlights.add('🔴 LIVE ACTION - No Replays');
    }

    if (highlights.isEmpty) {
      highlights.add('✨ Premium Fight Content');
    }

    return highlights;
  }

  String _generateCTA(AdPlatformConfig config) {
    return 'JOIN ON ${config.platform.toUpperCase()} → 10x MORE ACTION GUARANTEED ⚡';
  }

  String _magnifyTitle(String title) {
    final magnifiers = [
      'ULTIMATE: ',
      'EXTREME: ',
      'PEAK: ',
      'LEGENDARY: ',
      'UNREAL: ',
      'INCREDIBLE: ',
      'PURE: ',
    ];

    final magnifier = magnifiers[title.hashCode % magnifiers.length];

    // Add intensity markers
    final intensity = '🔥 ⚡ 💥 ';
    return '$intensity$magnifier$title → NOW ON METAVERSE 🌐';
  }

  List<String> _extractKeyPoints(String title) {
    final points = <String>[];

    if (title.length > 50) {
      points.add('📹 Extended Cut Available');
    }
    points.add('🎯 Multi-Platform Replay');
    points.add('💎 Premium Quality');
    points.add('🚀 Trending Now');

    return points;
  }

  String _generateEmotionalHook(String title) {
    final hooks = [
      'Feel the ENERGY like never before',
      'This is what REAL athletic excellence looks like',
      'Witness history in the making',
      'Experience pure adrenaline rush',
      'See greatness unfold LIVE',
      'Pure skill. Pure heart. Pure action.',
    ];

    return hooks[title.hashCode % hooks.length];
  }

  String _estimateEngagement(
    AdPlatformConfig config,
    ContentHighlight highlight,
  ) {
    // Parse audience limit (e.g., "500K+" → 500000)
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(config.audienceLimit);
    int baseAudience = 100000;
    if (match != null) {
      baseAudience = int.parse(match.group(1)!) * 1000;
    }

    // Estimate engagement with magnification
    final estimated = (baseAudience * highlight.engagementMagnifier * 0.15)
        .toInt();
    return '$estimated+ engaged users';
  }
}

/// Ad Platform Configuration
class AdPlatformConfig extends Equatable {
  final String platform;
  final String maxDuration;
  final String format;
  final String audienceLimit;
  final String emoji;

  const AdPlatformConfig({
    required this.platform,
    required this.maxDuration,
    required this.format,
    required this.audienceLimit,
    required this.emoji,
  });

  @override
  List<Object?> get props => [
    platform,
    maxDuration,
    format,
    audienceLimit,
    emoji,
  ];
}

/// Metaverse Ad Campaign
class MetaverseAdCampaign extends Equatable {
  final String id;
  final String platform;
  final String title;
  final String description;
  final String adMessage;
  final List<String> highlights;
  final String callToAction;
  final AdPlatformConfig config;
  final String? fighterId;
  final DateTime createdAt;
  final String status; // 'active', 'pending', 'completed'
  final String category;
  final double engagementScore;

  const MetaverseAdCampaign({
    required this.id,
    required this.platform,
    required this.title,
    required this.description,
    required this.adMessage,
    required this.highlights,
    required this.callToAction,
    required this.config,
    this.fighterId,
    required this.createdAt,
    required this.status,
    required this.category,
    required this.engagementScore,
  });

  @override
  List<Object?> get props => [
    id,
    platform,
    title,
    description,
    adMessage,
    highlights,
    callToAction,
    config,
    fighterId,
    createdAt,
    status,
    category,
    engagementScore,
  ];
}

/// Content Highlight for Amplification
class ContentHighlight extends Equatable {
  final String id;
  final String originalTitle;
  final String amplifiedTitle;
  final List<String> keyPoints;
  final String emotionalHook;
  final double engagementMagnifier; // 2.5x to 4.0x
  final String amplificationLevel; // 'MAXIMUM', 'HIGH', 'MEDIUM'
  final DateTime createdAt;

  const ContentHighlight({
    required this.id,
    required this.originalTitle,
    required this.amplifiedTitle,
    required this.keyPoints,
    required this.emotionalHook,
    required this.engagementMagnifier,
    required this.amplificationLevel,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    originalTitle,
    amplifiedTitle,
    keyPoints,
    emotionalHook,
    engagementMagnifier,
    amplificationLevel,
    createdAt,
  ];
}

/// Broadcast Result
class BroadcastResult extends Equatable {
  final String id;
  final String highlightId;
  final String campaignId;
  final String platform;
  final String amplifiedTitle;
  final String audienceReach;
  final double magnificationFactor;
  final DateTime broadcastTime;
  final String expectedEngagement;
  final String status; // 'live', 'pending', 'completed'

  const BroadcastResult({
    required this.id,
    required this.highlightId,
    required this.campaignId,
    required this.platform,
    required this.amplifiedTitle,
    required this.audienceReach,
    required this.magnificationFactor,
    required this.broadcastTime,
    required this.expectedEngagement,
    required this.status,
  });

  @override
  List<Object?> get props => [
    id,
    highlightId,
    campaignId,
    platform,
    amplifiedTitle,
    audienceReach,
    magnificationFactor,
    broadcastTime,
    expectedEngagement,
    status,
  ];
}
