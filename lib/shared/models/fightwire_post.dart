import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHTWIRE POST MODEL — 2030 Social Feed Architecture
/// Supports 8 content types, multi-source feeds, trust scoring, campaigns
/// ═══════════════════════════════════════════════════════════════════════════

class FightWirePost extends Equatable {
  // ─── Identity ─────────────────────────────────────────────────────────────
  final String id;
  final String authorId;
  final String authorName;
  final String authorRole; // fighter/coach/promoter/gym/fan/sponsor
  final bool isVerified;
  final String? authorAvatarUrl;

  // ─── Relationships ────────────────────────────────────────────────────────
  final String? gymId;
  final String? gymName;
  final String? weightClass;
  final String? discipline; // mma/boxing/muaythai/bjj/etc
  final String? location;
  final double? lat;
  final double? lng;

  // ─── Content ──────────────────────────────────────────────────────────────
  final FightWirePostType type;
  final String content;
  final List<String> mediaUrls;
  final List<String> hashtags;
  final List<String> mentions;

  // ─── Engagement ───────────────────────────────────────────────────────────
  final int likesCount;
  final int commentsCount;
  final int sharesCount;

  // Combat-specific reactions (DFC 2030)
  final int respectCount; // 🥋 Respect
  final int strongCount; // 💪 Power
  final int supportCount; // ❤️ Support
  final int warriorCount; // 🔥 Fire
  final int championCount; // 👑 Legend

  // ─── Meta ─────────────────────────────────────────────────────────────────
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? eventDate;
  final bool isPinned;
  final bool isSponsored;
  final String? sponsorName;
  final String? sponsorLogoUrl;

  // ─── Safety & Trust ───────────────────────────────────────────────────────
  final double communityTrustScore; // 0.0 - 1.0
  final bool isReported;
  final int reportCount;
  final bool isModerated;
  final String? moderationReason;

  // ─── Business Layer ───────────────────────────────────────────────────────
  final String? marketplaceItemId;
  final String? eventId;
  final String? opportunityType; // sponsor/coach/sparring/venue/fight
  final Map<String, dynamic>? opportunityDetails;

  // ─── Social Impact (NightChill / DFC Foundation) ──────────────────────────
  final bool isSocialImpact;
  final String? campaignId;
  final CampaignType? campaignType;
  final Map<String, dynamic>? impactMetrics;

  // ─── Source Metadata ──────────────────────────────────────────────────────
  final PostSource source; // dfc_native/nightchill/ibc/espn/partner/ai
  final String? sourceLabel;
  final String? sourceColor;

  // ─── Relevance Scoring (computed) ─────────────────────────────────────────
  final double relevanceScore; // Calculated by feed algorithm

  // ─── Visibility ───────────────────────────────────────────────────────────
  final PostVisibility visibility;
  final List<String>? visibleToUserIds;
  final List<String>? visibleToRoles;

  const FightWirePost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    this.isVerified = false,
    this.authorAvatarUrl,
    this.gymId,
    this.gymName,
    this.weightClass,
    this.discipline,
    this.location,
    this.lat,
    this.lng,
    required this.type,
    required this.content,
    this.mediaUrls = const [],
    this.hashtags = const [],
    this.mentions = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.respectCount = 0,
    this.strongCount = 0,
    this.supportCount = 0,
    this.warriorCount = 0,
    this.championCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.eventDate,
    this.isPinned = false,
    this.isSponsored = false,
    this.sponsorName,
    this.sponsorLogoUrl,
    this.communityTrustScore = 0.5,
    this.isReported = false,
    this.reportCount = 0,
    this.isModerated = false,
    this.moderationReason,
    this.marketplaceItemId,
    this.eventId,
    this.opportunityType,
    this.opportunityDetails,
    this.isSocialImpact = false,
    this.campaignId,
    this.campaignType,
    this.impactMetrics,
    this.source = PostSource.dfcNative,
    this.sourceLabel,
    this.sourceColor,
    this.relevanceScore = 0.5,
    this.visibility = PostVisibility.public,
    this.visibleToUserIds,
    this.visibleToRoles,
  });

  @override
  List<Object?> get props => [
    id,
    authorId,
    type,
    content,
    createdAt,
    likesCount,
    commentsCount,
    sharesCount,
    relevanceScore,
  ];

  // ─── Firestore Serialization ──────────────────────────────────────────────

  factory FightWirePost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FightWirePost(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorRole: data['authorRole'] ?? 'fan',
      isVerified: data['isVerified'] ?? false,
      authorAvatarUrl: data['authorAvatarUrl'],
      gymId: data['gymId'],
      gymName: data['gymName'],
      weightClass: data['weightClass'],
      discipline: data['discipline'],
      location: data['location'],
      lat: data['lat']?.toDouble(),
      lng: data['lng']?.toDouble(),
      type: FightWirePostType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => FightWirePostType.training,
      ),
      content: data['content'] ?? '',
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      hashtags: List<String>.from(data['hashtags'] ?? []),
      mentions: List<String>.from(data['mentions'] ?? []),
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      sharesCount: data['sharesCount'] ?? 0,
      respectCount: data['respectCount'] ?? 0,
      strongCount: data['strongCount'] ?? 0,
      supportCount: data['supportCount'] ?? 0,
      warriorCount: data['warriorCount'] ?? 0,
      championCount: data['championCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      eventDate: data['eventDate'] != null
          ? (data['eventDate'] as Timestamp).toDate()
          : null,
      isPinned: data['isPinned'] ?? false,
      isSponsored: data['isSponsored'] ?? false,
      sponsorName: data['sponsorName'],
      sponsorLogoUrl: data['sponsorLogoUrl'],
      communityTrustScore: data['communityTrustScore']?.toDouble() ?? 0.5,
      isReported: data['isReported'] ?? false,
      reportCount: data['reportCount'] ?? 0,
      isModerated: data['isModerated'] ?? false,
      moderationReason: data['moderationReason'],
      marketplaceItemId: data['marketplaceItemId'],
      eventId: data['eventId'],
      opportunityType: data['opportunityType'],
      opportunityDetails: data['opportunityDetails'],
      isSocialImpact: data['isSocialImpact'] ?? false,
      campaignId: data['campaignId'],
      campaignType: data['campaignType'] != null
          ? CampaignType.values.firstWhere(
              (e) => e.name == data['campaignType'],
              orElse: () => CampaignType.goldCoin,
            )
          : null,
      impactMetrics: data['impactMetrics'],
      source: PostSource.values.firstWhere(
        (e) => e.name == data['source'],
        orElse: () => PostSource.dfcNative,
      ),
      sourceLabel: data['sourceLabel'],
      sourceColor: data['sourceColor'],
      relevanceScore: data['relevanceScore']?.toDouble() ?? 0.5,
      visibility: PostVisibility.values.firstWhere(
        (e) => e.name == data['visibility'],
        orElse: () => PostVisibility.public,
      ),
      visibleToUserIds: data['visibleToUserIds'] != null
          ? List<String>.from(data['visibleToUserIds'])
          : null,
      visibleToRoles: data['visibleToRoles'] != null
          ? List<String>.from(data['visibleToRoles'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'isVerified': isVerified,
      'authorAvatarUrl': authorAvatarUrl,
      'gymId': gymId,
      'gymName': gymName,
      'weightClass': weightClass,
      'discipline': discipline,
      'location': location,
      'lat': lat,
      'lng': lng,
      'type': type.name,
      'content': content,
      'mediaUrls': mediaUrls,
      'hashtags': hashtags,
      'mentions': mentions,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'respectCount': respectCount,
      'strongCount': strongCount,
      'supportCount': supportCount,
      'warriorCount': warriorCount,
      'championCount': championCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'eventDate': eventDate != null ? Timestamp.fromDate(eventDate!) : null,
      'isPinned': isPinned,
      'isSponsored': isSponsored,
      'sponsorName': sponsorName,
      'sponsorLogoUrl': sponsorLogoUrl,
      'communityTrustScore': communityTrustScore,
      'isReported': isReported,
      'reportCount': reportCount,
      'isModerated': isModerated,
      'moderationReason': moderationReason,
      'marketplaceItemId': marketplaceItemId,
      'eventId': eventId,
      'opportunityType': opportunityType,
      'opportunityDetails': opportunityDetails,
      'isSocialImpact': isSocialImpact,
      'campaignId': campaignId,
      'campaignType': campaignType?.name,
      'impactMetrics': impactMetrics,
      'source': source.name,
      'sourceLabel': sourceLabel,
      'sourceColor': sourceColor,
      'relevanceScore': relevanceScore,
      'visibility': visibility.name,
      'visibleToUserIds': visibleToUserIds,
      'visibleToRoles': visibleToRoles,
    };
  }

  // ─── Convenience Methods ──────────────────────────────────────────────────

  int get totalEngagement =>
      likesCount +
      commentsCount +
      sharesCount +
      respectCount +
      warriorCount +
      championCount +
      strongCount;

  bool get hasMedia => mediaUrls.isNotEmpty;

  bool get isEvent => type == FightWirePostType.event;

  bool get isCampaign => isSocialImpact && campaignId != null;

  bool get isOpportunity =>
      type == FightWirePostType.opportunity && opportunityType != null;

  bool get isSparringRequest => type == FightWirePostType.sparringRequest;

  FightWirePost copyWith({
    String? id,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    int? respectCount,
    int? warriorCount,
    int? championCount,
    int? strongCount,
    double? relevanceScore,
    double? communityTrustScore,
    bool? isReported,
    int? reportCount,
    bool? isModerated,
    String? moderationReason,
  }) {
    return FightWirePost(
      id: id ?? this.id,
      authorId: authorId,
      authorName: authorName,
      authorRole: authorRole,
      isVerified: isVerified,
      authorAvatarUrl: authorAvatarUrl,
      gymId: gymId,
      gymName: gymName,
      weightClass: weightClass,
      discipline: discipline,
      location: location,
      lat: lat,
      lng: lng,
      type: type,
      content: content,
      mediaUrls: mediaUrls,
      hashtags: hashtags,
      mentions: mentions,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      respectCount: respectCount ?? this.respectCount,
      warriorCount: warriorCount ?? this.warriorCount,
      championCount: championCount ?? this.championCount,
      strongCount: strongCount ?? this.strongCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      eventDate: eventDate,
      isPinned: isPinned,
      isSponsored: isSponsored,
      sponsorName: sponsorName,
      sponsorLogoUrl: sponsorLogoUrl,
      communityTrustScore: communityTrustScore ?? this.communityTrustScore,
      isReported: isReported ?? this.isReported,
      reportCount: reportCount ?? this.reportCount,
      isModerated: isModerated ?? this.isModerated,
      moderationReason: moderationReason ?? this.moderationReason,
      marketplaceItemId: marketplaceItemId,
      eventId: eventId,
      opportunityType: opportunityType,
      opportunityDetails: opportunityDetails,
      isSocialImpact: isSocialImpact,
      campaignId: campaignId,
      campaignType: campaignType,
      impactMetrics: impactMetrics,
      source: source,
      sourceLabel: sourceLabel,
      sourceColor: sourceColor,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      visibility: visibility,
      visibleToUserIds: visibleToUserIds,
      visibleToRoles: visibleToRoles,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════

enum FightWirePostType {
  training, // Training clips, workout logs
  fight, // Fight announcements, results
  event, // Event promotions, fight cards
  gym, // Gym updates, class schedules
  opportunity, // Sponsorship, coaching, partnerships
  marketplace, // Gear, services, tickets
  charity, // Gold Coin, Pink Shield, Coffee campaigns
  knowledge, // Coaching tips, technique breakdowns
  announcement, // General updates
  sparringRequest, // Looking for sparring partners
  livestream, // Live video streams
}

enum PostSource {
  dfcNative, // Original DFC content
  nightchill, // NightChill partnership
  ibc, // IBC partnership
  espn, // ESPN feed
  partner, // Other partners
  ai, // AI-generated content
}

enum CampaignType {
  pinkShield, // 🛡️ Trauma recovery support
  goldCoin, // 🪙 Poverty & underprivileged youth
  coffee, // ☕ Community connection "Buy a Coffee Not a Coffin"
  nightchill, // 🌙 NightChill sobriety programs
  youth, // 🎓 Youth training scholarships
  custom, // Custom campaigns
}

enum PostVisibility {
  public, // Everyone can see
  friends, // Friends only
  gym, // Gym members only
  private, // Author only
  custom, // Custom user list
}
