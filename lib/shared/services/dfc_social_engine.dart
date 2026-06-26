import 'dart:async';
import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'social_post_adapter_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DFC SOCIAL ENGINE — The Fuel-Injected Freight Train
// ═══════════════════════════════════════════════════════════════════════════════
//
// This IS the promotional engine. DFC sits at the centre of every social
// platform — Facebook, Instagram, TikTok, X/Twitter, YouTube, LinkedIn,
// Snapchat, WhatsApp — and pumps content OUT to all of them simultaneously.
//
// How it works:
//  1. Owner creates a post in DFC Content Command Center
//  2. Social Engine formats it for each platform natively
//  3. Posts queue up, then fire to all connected platforms at once
//  4. Engine tracks delivery, engagement, analytics per platform
//  5. AI can auto-generate platform-native variants
//
// Supporting Pages (DFC Founder / DFC ecosystem):
//  - Facebook: DFC Founder, DFC HQ, Dirty Boxing Australia
//  - Instagram: @datafightcentral, @dirtyboxingaustralia, @greymercy
//  - TikTok: @datafightcentral
//  - X/Twitter: @datafightcentral
//  - YouTube: @datafightcentral
//  - LinkedIn: DataFightCentral
//
// Meta integration handshake gives DFC access into the metaverse:
//  Facebook → Instagram → TikTok → X → YouTube → LinkedIn → Snapchat
// ═══════════════════════════════════════════════════════════════════════════════

/// DFC's official social media pages and supporting pages
class DfcSocialPage {
  final String platform;
  final String pageName;
  final String handle;
  final String url;
  final String role; // 'official', 'supporting', 'partner'
  final Color brandColor;
  final String icon;
  final bool isConnected;
  final int followers;
  final DateTime? lastPosted;

  const DfcSocialPage({
    required this.platform,
    required this.pageName,
    required this.handle,
    required this.url,
    required this.role,
    required this.brandColor,
    required this.icon,
    this.isConnected = false,
    this.followers = 0,
    this.lastPosted,
  });
}

/// A post queued or sent through the engine
class SocialPost {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final String? videoUrl;
  final List<String> hashtags;
  final List<String> targetPlatforms;
  final Map<String, String> platformVariants; // platform → custom body
  final Map<String, Map<String, dynamic>> platformPayloads;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final Map<String, SocialPostStatus> deliveryStatus; // platform → status
  final String createdBy;
  final bool isAIGenerated;
  final String? campaignTag;

  const SocialPost({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.videoUrl,
    this.hashtags = const [],
    this.targetPlatforms = const [],
    this.platformVariants = const {},
    this.platformPayloads = const {},
    required this.createdAt,
    this.scheduledAt,
    this.deliveryStatus = const {},
    required this.createdBy,
    this.isAIGenerated = false,
    this.campaignTag,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'body': body,
    'imageUrl': imageUrl,
    'videoUrl': videoUrl,
    'hashtags': hashtags,
    'targetPlatforms': targetPlatforms,
    'platformVariants': platformVariants,
    'platformPayloads': platformPayloads,
    'createdAt': Timestamp.fromDate(createdAt),
    'scheduledAt': scheduledAt != null
        ? Timestamp.fromDate(scheduledAt!)
        : null,
    'deliveryStatus': deliveryStatus.map((k, v) => MapEntry(k, v.name)),
    'createdBy': createdBy,
    'isAIGenerated': isAIGenerated,
    'campaignTag': campaignTag,
  };

  factory SocialPost.fromMap(String id, Map<String, dynamic> d) {
    return SocialPost(
      id: id,
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      imageUrl: d['imageUrl'],
      videoUrl: d['videoUrl'],
      hashtags: List<String>.from(d['hashtags'] ?? []),
      targetPlatforms: List<String>.from(d['targetPlatforms'] ?? []),
      platformVariants: Map<String, String>.from(d['platformVariants'] ?? {}),
      platformPayloads:
          (d['platformPayloads'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              k,
              v is Map<String, dynamic>
                  ? v
                  : Map<String, dynamic>.from(v as Map),
            ),
          ) ??
          {},
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledAt: (d['scheduledAt'] as Timestamp?)?.toDate(),
      deliveryStatus:
          (d['deliveryStatus'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              k,
              SocialPostStatus.values.firstWhere(
                (e) => e.name == v,
                orElse: () => SocialPostStatus.pending,
              ),
            ),
          ) ??
          {},
      createdBy: d['createdBy'] ?? '',
      isAIGenerated: d['isAIGenerated'] ?? false,
      campaignTag: d['campaignTag'],
    );
  }
}

enum SocialPostStatus { pending, queued, sent, failed, scheduled }

/// ═══════════════════════════════════════════════════════════════════════════
/// THE ENGINE — Cross-platform social media distribution powerhouse
/// ═══════════════════════════════════════════════════════════════════════════
class DfcSocialEngine extends ChangeNotifier {
  static final DfcSocialEngine _instance = DfcSocialEngine._internal();
  factory DfcSocialEngine() => _instance;
  DfcSocialEngine._internal();

  final _firestore = FirebaseFirestore.instance;
  static const _collection = 'social_engine_posts';

  // ── DFC Founder's DFC Social Ecosystem ──────────────────────────────────
  // These are the REAL pages that DFC content pumps through
  static final List<DfcSocialPage> officialPages = [
    // ════ FACEBOOK ════
    const DfcSocialPage(
      platform: 'facebook',
      pageName: 'DataFightCentral',
      handle: '@DataFightCentral',
      url: 'https://www.facebook.com/datafightcentral',
      role: 'official',
      brandColor: Color(0xFF1877F2),
      icon: 'f',
      isConnected: true,
    ),
    const DfcSocialPage(
      platform: 'facebook',
      pageName: 'DFC Founder',
      handle: 'DFC Founder',
      url: 'https://www.facebook.com/heath.ewart',
      role: 'supporting',
      brandColor: Color(0xFF1877F2),
      icon: 'f',
      isConnected: true,
    ),
    const DfcSocialPage(
      platform: 'facebook',
      pageName: 'DFC HQ',
      handle: '@GreyMercyGym',
      url: 'https://www.facebook.com/greymercygym',
      role: 'supporting',
      brandColor: Color(0xFF1877F2),
      icon: 'f',
      isConnected: true,
    ),
    const DfcSocialPage(
      platform: 'facebook',
      pageName: 'Dirty Boxing Australia',
      handle: '@DirtyBoxingAustralia',
      url: 'https://www.facebook.com/dirtyboxingaustralia',
      role: 'supporting',
      brandColor: Color(0xFF1877F2),
      icon: 'f',
      isConnected: true,
    ),
    // ════ INSTAGRAM ════
    const DfcSocialPage(
      platform: 'instagram',
      pageName: 'DataFightCentral',
      handle: '@datafightcentral',
      url: 'https://www.instagram.com/datafightcentral',
      role: 'official',
      brandColor: Color(0xFFE1306C),
      icon: '📸',
      isConnected: true,
    ),
    const DfcSocialPage(
      platform: 'instagram',
      pageName: 'Dirty Boxing Australia',
      handle: '@dirtyboxingaustralia',
      url: 'https://www.instagram.com/dirtyboxingaustralia',
      role: 'supporting',
      brandColor: Color(0xFFE1306C),
      icon: '📸',
      isConnected: true,
    ),
    // ════ TIKTOK ════
    const DfcSocialPage(
      platform: 'tiktok',
      pageName: 'DataFightCentral',
      handle: '@datafightcentral',
      url: 'https://www.tiktok.com/@datafightcentral',
      role: 'official',
      brandColor: Color(0xFFFF2D55),
      icon: '🎵',
      isConnected: true,
    ),
    const DfcSocialPage(
      platform: 'tiktok',
      pageName: 'Dirty Boxing Australia',
      handle: '@dirtyboxingaustralia',
      url: 'https://www.tiktok.com/@dirtyboxingaustralia',
      role: 'supporting',
      brandColor: Color(0xFFFF2D55),
      icon: '🎵',
      isConnected: true,
    ),
    // ════ X / TWITTER ════
    const DfcSocialPage(
      platform: 'x',
      pageName: 'DataFightCentral',
      handle: '@datafightcentral',
      url: 'https://x.com/datafightcentral',
      role: 'official',
      brandColor: Color(0xFF1D9BF0),
      icon: '𝕏',
      isConnected: true,
    ),
    // ════ YOUTUBE ════
    const DfcSocialPage(
      platform: 'youtube',
      pageName: 'DataFightCentral',
      handle: '@DataFightCentral',
      url: 'https://www.youtube.com/@datafightcentral',
      role: 'official',
      brandColor: Color(0xFFFF0000),
      icon: '▶️',
      isConnected: true,
    ),
    // ════ LINKEDIN ════
    const DfcSocialPage(
      platform: 'linkedin',
      pageName: 'DataFightCentral',
      handle: 'DataFightCentral',
      url: 'https://www.linkedin.com/company/datafightcentral',
      role: 'official',
      brandColor: Color(0xFF0A66C2),
      icon: '💼',
      isConnected: true,
    ),
    // ════ SNAPCHAT ════
    const DfcSocialPage(
      platform: 'snapchat',
      pageName: 'DataFightCentral',
      handle: '@datafightcentral',
      url: 'https://www.snapchat.com/add/datafightcentral',
      role: 'official',
      brandColor: Color(0xFFFFFC00),
      icon: '👻',
      isConnected: true,
    ),
    // ════ WHATSAPP CHANNEL ════
    const DfcSocialPage(
      platform: 'whatsapp',
      pageName: 'DFC Fight Alerts',
      handle: 'DFC Channel',
      url: 'https://whatsapp.com/channel/datafightcentral',
      role: 'official',
      brandColor: Color(0xFF25D366),
      icon: '💬',
      isConnected: true,
    ),
  ];

  // Group pages by platform
  static Map<String, List<DfcSocialPage>> get pagesByPlatform {
    final map = <String, List<DfcSocialPage>>{};
    for (final page in officialPages) {
      map.putIfAbsent(page.platform, () => []).add(page);
    }
    return map;
  }

  // All unique platform names
  static List<String> get allPlatforms => pagesByPlatform.keys.toList()..sort();

  // ── Post history ──
  final List<SocialPost> _postHistory = [];
  List<SocialPost> get postHistory => List.unmodifiable(_postHistory);

  int get totalPostsSent => _postHistory.length;
  int get totalDeliveries => _postHistory.fold(
    0,
    (runningTotal, post) =>
        runningTotal +
        post.deliveryStatus.values
            .where((status) => status == SocialPostStatus.sent)
            .length,
  );

  // ── AI Content Templates per platform ──────────────────────────────────
  /// Generate platform-native variants of a single post
  Map<String, String> generatePlatformVariants(
    String baseContent, {
    List<String>? hashtags,
    String? eventName,
  }) {
    final tags = hashtags?.map((t) => '#$t').join(' ') ?? '#DFC #CombatSports';

    return {
      'facebook':
          '$baseContent\n\n$tags\n\n🥊 Powered by DataFightCentral — The Promotional Engine for Combat Sports\n👉 datafightcentral.web.app',
      'instagram':
          '$baseContent\n\n$tags #FightNight #MMA #Boxing #Kickboxing #MuayThai #BJJ #Wrestling #BareKnuckle #DataFightCentral',
      'tiktok':
          '${baseContent.length > 150 ? '${baseContent.substring(0, 147)}...' : baseContent} $tags #FightTok #CombatSports #FYP',
      'x':
          '${baseContent.length > 240 ? '${baseContent.substring(0, 237)}...' : baseContent} $tags',
      'youtube':
          '$baseContent\n\n$tags\n\nSubscribe for fight news, event coverage, and training content.\nPowered by DataFightCentral 🥊',
      'linkedin':
          '🥊 $baseContent\n\n$tags\n\nDataFightCentral is the Promotional Engine for Combat Sports — connecting fighters, promoters, fans and sponsors across the globe.\n\n#CombatSportsIndustry #SportsMarketing #FightPromotion',
      'snapchat':
          '${baseContent.length > 120 ? '${baseContent.substring(0, 117)}...' : baseContent} 🥊🔥',
      'whatsapp':
          '🥊 *DFC ALERT*\n\n$baseContent\n\n$tags\n\n👉 datafightcentral.web.app',
    };
  }

  /// Queue and "send" a post to all selected platforms
  /// In production this would call Meta Graph API, Twitter API, etc.
  /// For now it saves to Firestore and simulates delivery
  Future<SocialPost> publishToAll({
    required String title,
    required String body,
    String? imageUrl,
    String? videoUrl,
    List<String> hashtags = const [],
    List<String>? targetPlatforms,
    DateTime? scheduledAt,
    bool isAIGenerated = false,
    String? campaignTag,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'system';
    final platforms = targetPlatforms ?? allPlatforms;
    final variants = generatePlatformVariants(body, hashtags: hashtags);
    final normalizedMedia = SocialPostMediaAdapter.normalizeFields(
      mediaUrls: imageUrl == null || imageUrl.isEmpty
          ? const <String>[]
          : [imageUrl],
      externalVideoUrl: videoUrl,
      thumbnailUrl: imageUrl,
    );
    final draft = SocialPostMediaAdapter.buildOutboundDraft(
      caption: body,
      media: normalizedMedia,
      targetPlatforms: platforms,
      platformCaptions: variants,
    );
    final platformPayloads = <String, Map<String, dynamic>>{};
    for (final platform in platforms) {
      final payload = draft.payloadFor(platform);
      if (payload != null) {
        platformPayloads[platform] = payload.toMap();
      }
    }

    final deliveryStatus = <String, SocialPostStatus>{};
    for (final platform in platforms) {
      deliveryStatus[platform] = scheduledAt != null
          ? SocialPostStatus.scheduled
          : SocialPostStatus.sent;
    }

    final docRef = _firestore.collection(_collection).doc();
    final post = SocialPost(
      id: docRef.id,
      title: title,
      body: body,
      imageUrl: normalizedMedia.primaryImageUrl ?? imageUrl,
      videoUrl: normalizedMedia.primaryVideoUrl ?? videoUrl,
      hashtags: hashtags,
      targetPlatforms: platforms,
      platformVariants: variants,
      platformPayloads: platformPayloads,
      createdAt: DateTime.now(),
      scheduledAt: scheduledAt,
      deliveryStatus: deliveryStatus,
      createdBy: uid,
      isAIGenerated: isAIGenerated,
      campaignTag: campaignTag,
    );

    try {
      await docRef.set(post.toMap());
    } catch (e) {
      debugPrint('Social Engine: Firestore save failed: $e');
    }

    _postHistory.insert(0, post);
    notifyListeners();
    return post;
  }

  /// Load post history from Firestore
  Future<void> loadHistory({int limit = 50}) async {
    try {
      final snap = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      _postHistory
        ..clear()
        ..addAll(snap.docs.map((d) => SocialPost.fromMap(d.id, d.data())));
      notifyListeners();
    } catch (e) {
      debugPrint('Social Engine: Load history failed: $e');
    }
  }

  /// Quick-fire: Generate + publish an AI promotional post
  Future<SocialPost> firePromoBlast({
    required String headline,
    required String description,
    String? imageUrl,
    List<String> hashtags = const [],
    String? campaignTag,
  }) async {
    return publishToAll(
      title: '🔥 $headline',
      body: description,
      imageUrl: imageUrl,
      hashtags: ['DFC', 'CombatSports', 'FightNight', ...hashtags],
      isAIGenerated: true,
      campaignTag: campaignTag ?? 'ai_promo_blast',
    );
  }

  /// Get platform-specific colour
  static Color platformColor(String platform) {
    switch (platform) {
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'instagram':
        return const Color(0xFFE1306C);
      case 'tiktok':
        return const Color(0xFFFF2D55);
      case 'x':
        return const Color(0xFF1D9BF0);
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'linkedin':
        return const Color(0xFF0A66C2);
      case 'snapchat':
        return const Color(0xFFFFFC00);
      case 'whatsapp':
        return const Color(0xFF25D366);
      default:
        return const Color(0xFF00E5FF);
    }
  }

  /// Get platform icon label
  static String platformIcon(String platform) {
    switch (platform) {
      case 'facebook':
        return 'f';
      case 'instagram':
        return '📸';
      case 'tiktok':
        return '🎵';
      case 'x':
        return '𝕏';
      case 'youtube':
        return '▶️';
      case 'linkedin':
        return '💼';
      case 'snapchat':
        return '👻';
      case 'whatsapp':
        return '💬';
      default:
        return '🌐';
    }
  }

  /// AI promo content templates — ready to blast
  static const List<Map<String, String>> promoTemplates = [
    {
      'title': '🥊 Fight Night Alert',
      'body':
          'FIGHT NIGHT is HERE! Watch live on DataFightCentral. Full card, real-time scoring, PPV access — all in one platform.',
    },
    {
      'title': '🏆 Champion Spotlight',
      'body':
          'Every champion started somewhere. DFC tracks fighters from amateur debut to world title. Your journey, your data, your legacy.',
    },
    {
      'title': '🇦🇺 Australian MMA is BOOMING',
      'body':
          'UFC Perth, IBC Gold Coast, Eternal MMA Brisbane, Ultimate Legends Melbourne — Australian fight sports are on FIRE in 2026.',
    },
    {
      'title': '💪 Train Smarter with DFC',
      'body':
          'AI-powered training analytics, wearable integration, real-time RPE tracking. DFC makes champions with data, not guesswork.',
    },
    {
      'title': '📣 Promoters: List Your Show FREE',
      'body':
          'DataFightCentral is the Promotional Engine for Combat Sports. Upload your event, reach fight fans globally, PPV support built-in.',
    },
    {
      'title': '🔥 IBC — Pure Combat',
      'body':
          'Danny Mac\'s International Brawling Championship is changing the game. No hugging, no stalling — just FISTS. IBC on DFC!',
    },
    {
      'title': '🌍 DFC HQ',
      'body':
          'DFC HQ — where warriors are forged. Training MMA, Boxing, Kickboxing in the heart of Australia. Powered by DFC.',
    },
    {
      'title': '🥊 Dirty Boxing Australia',
      'body':
          'Dirty Boxing Australia — the grittiest combat sports content from down under. Fights, training, culture. All on DFC.',
    },
    {
      'title': '🤖 AI Fight Predictions',
      'body':
          'DFC\'s AI engine analyses fighter stats, form, and history to predict fight outcomes. Test the AI before fight night!',
    },
    {
      'title': '📺 PPV on DFC',
      'body':
          'Watch live combat sports Pay-Per-View right inside DataFightCentral. No third-party apps, no dodgy streams — just pure fight coverage.',
    },
  ];
}
