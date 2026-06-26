import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Campaign type — maps to different marketing strategies
enum MarketingCampaignType {
  social,
  email,
  seo,
  ppc,
  influencer,
  affiliate,
  content,
  event,
  retargeting,
  brand,
}

/// Campaign status lifecycle
enum CampaignStatus { draft, scheduled, active, paused, completed, archived }

/// Distribution channel
enum CampaignChannel {
  instagram,
  facebook,
  twitter,
  tiktok,
  youtube,
  linkedin,
  email,
  sms,
  push,
  web,
  inApp,
}

/// Full marketing campaign model — 30+ fields for enterprise-grade tracking.
/// Maps to Firestore `marketing_campaigns` collection.
class MarketingCampaignModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final MarketingCampaignType type;
  final CampaignStatus status;
  final List<CampaignChannel> channels;
  final String createdBy; // uid
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Scheduling
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final String? timezone;

  // Targeting
  final List<String> targetAudience; // e.g. ['fighters', 'fans', 'coaches']
  final List<String> targetRegions; // e.g. ['AU', 'US', 'UK']
  final int? targetAgeMin;
  final int? targetAgeMax;
  final List<String> targetSports; // e.g. ['MMA', 'Boxing', 'Muay Thai']

  // Budget
  final double budgetTotal;
  final double budgetSpent;
  final String currency;

  // Content
  final String? heroImageUrl;
  final String? videoUrl;
  final String? ctaText;
  final String? ctaUrl;
  final List<String> hashtags;
  final Map<String, String> platformCopy; // channel -> copy text

  // A/B Testing
  final bool isABTest;
  final String? abTestId;
  final String? variant; // 'A', 'B', 'C'

  // Metrics (written by pipeline)
  final int impressions;
  final int clicks;
  final int conversions;
  final int shares;
  final int likes;
  final double revenue;

  // Swarm integration
  final bool swarmPowered;
  final String? swarmAgentId;
  final int swarmContentCount;

  // Tags & notes
  final List<String> tags;
  final String? notes;

  const MarketingCampaignModel({
    required this.id,
    required this.title,
    this.description = '',
    this.type = MarketingCampaignType.social,
    this.status = CampaignStatus.draft,
    this.channels = const [],
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.scheduledStart,
    this.scheduledEnd,
    this.timezone,
    this.targetAudience = const [],
    this.targetRegions = const [],
    this.targetAgeMin,
    this.targetAgeMax,
    this.targetSports = const [],
    this.budgetTotal = 0,
    this.budgetSpent = 0,
    this.currency = 'USD',
    this.heroImageUrl,
    this.videoUrl,
    this.ctaText,
    this.ctaUrl,
    this.hashtags = const [],
    this.platformCopy = const {},
    this.isABTest = false,
    this.abTestId,
    this.variant,
    this.impressions = 0,
    this.clicks = 0,
    this.conversions = 0,
    this.shares = 0,
    this.likes = 0,
    this.revenue = 0,
    this.swarmPowered = false,
    this.swarmAgentId,
    this.swarmContentCount = 0,
    this.tags = const [],
    this.notes,
  });

  // ── Firestore serialization ──────────────────────────────────────

  factory MarketingCampaignModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return MarketingCampaignModel(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      type: MarketingCampaignType.values.firstWhere(
        (e) => e.name == d['type'],
        orElse: () => MarketingCampaignType.social,
      ),
      status: CampaignStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => CampaignStatus.draft,
      ),
      channels: (d['channels'] as List<dynamic>? ?? [])
          .map(
            (c) => CampaignChannel.values.firstWhere(
              (e) => e.name == c,
              orElse: () => CampaignChannel.web,
            ),
          )
          .toList(),
      createdBy: d['createdBy'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      scheduledStart: (d['scheduledStart'] as Timestamp?)?.toDate(),
      scheduledEnd: (d['scheduledEnd'] as Timestamp?)?.toDate(),
      timezone: d['timezone'],
      targetAudience: List<String>.from(d['targetAudience'] ?? []),
      targetRegions: List<String>.from(d['targetRegions'] ?? []),
      targetAgeMin: d['targetAgeMin'],
      targetAgeMax: d['targetAgeMax'],
      targetSports: List<String>.from(d['targetSports'] ?? []),
      budgetTotal: (d['budgetTotal'] ?? 0).toDouble(),
      budgetSpent: (d['budgetSpent'] ?? 0).toDouble(),
      currency: d['currency'] ?? 'USD',
      heroImageUrl: d['heroImageUrl'],
      videoUrl: d['videoUrl'],
      ctaText: d['ctaText'],
      ctaUrl: d['ctaUrl'],
      hashtags: List<String>.from(d['hashtags'] ?? []),
      platformCopy: Map<String, String>.from(d['platformCopy'] ?? {}),
      isABTest: d['isABTest'] ?? false,
      abTestId: d['abTestId'],
      variant: d['variant'],
      impressions: d['impressions'] ?? 0,
      clicks: d['clicks'] ?? 0,
      conversions: d['conversions'] ?? 0,
      shares: d['shares'] ?? 0,
      likes: d['likes'] ?? 0,
      revenue: (d['revenue'] ?? 0).toDouble(),
      swarmPowered: d['swarmPowered'] ?? false,
      swarmAgentId: d['swarmAgentId'],
      swarmContentCount: d['swarmContentCount'] ?? 0,
      tags: List<String>.from(d['tags'] ?? []),
      notes: d['notes'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'description': description,
    'type': type.name,
    'status': status.name,
    'channels': channels.map((c) => c.name).toList(),
    'createdBy': createdBy,
    'createdAt': Timestamp.fromDate(createdAt),
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    if (scheduledStart != null)
      'scheduledStart': Timestamp.fromDate(scheduledStart!),
    if (scheduledEnd != null) 'scheduledEnd': Timestamp.fromDate(scheduledEnd!),
    if (timezone != null) 'timezone': timezone,
    'targetAudience': targetAudience,
    'targetRegions': targetRegions,
    if (targetAgeMin != null) 'targetAgeMin': targetAgeMin,
    if (targetAgeMax != null) 'targetAgeMax': targetAgeMax,
    'targetSports': targetSports,
    'budgetTotal': budgetTotal,
    'budgetSpent': budgetSpent,
    'currency': currency,
    if (heroImageUrl != null) 'heroImageUrl': heroImageUrl,
    if (videoUrl != null) 'videoUrl': videoUrl,
    if (ctaText != null) 'ctaText': ctaText,
    if (ctaUrl != null) 'ctaUrl': ctaUrl,
    'hashtags': hashtags,
    'platformCopy': platformCopy,
    'isABTest': isABTest,
    if (abTestId != null) 'abTestId': abTestId,
    if (variant != null) 'variant': variant,
    'impressions': impressions,
    'clicks': clicks,
    'conversions': conversions,
    'shares': shares,
    'likes': likes,
    'revenue': revenue,
    'swarmPowered': swarmPowered,
    if (swarmAgentId != null) 'swarmAgentId': swarmAgentId,
    'swarmContentCount': swarmContentCount,
    'tags': tags,
    if (notes != null) 'notes': notes,
  };

  // ── Computed KPI getters ─────────────────────────────────────────

  double get ctr => impressions > 0 ? (clicks / impressions) * 100 : 0;
  double get conversionRate => clicks > 0 ? (conversions / clicks) * 100 : 0;
  double get budgetUtilization =>
      budgetTotal > 0 ? (budgetSpent / budgetTotal) * 100 : 0;
  double get costPerClick => clicks > 0 ? budgetSpent / clicks : 0;
  double get costPerConversion =>
      conversions > 0 ? budgetSpent / conversions : 0;
  double get roi =>
      budgetSpent > 0 ? ((revenue - budgetSpent) / budgetSpent) * 100 : 0;
  int get engagementTotal => clicks + shares + likes;

  MarketingCampaignModel copyWith({
    String? id,
    String? title,
    String? description,
    MarketingCampaignType? type,
    CampaignStatus? status,
    List<CampaignChannel>? channels,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    String? timezone,
    List<String>? targetAudience,
    List<String>? targetRegions,
    int? targetAgeMin,
    int? targetAgeMax,
    List<String>? targetSports,
    double? budgetTotal,
    double? budgetSpent,
    String? currency,
    String? heroImageUrl,
    String? videoUrl,
    String? ctaText,
    String? ctaUrl,
    List<String>? hashtags,
    Map<String, String>? platformCopy,
    bool? isABTest,
    String? abTestId,
    String? variant,
    int? impressions,
    int? clicks,
    int? conversions,
    int? shares,
    int? likes,
    double? revenue,
    bool? swarmPowered,
    String? swarmAgentId,
    int? swarmContentCount,
    List<String>? tags,
    String? notes,
  }) {
    return MarketingCampaignModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      channels: channels ?? this.channels,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      timezone: timezone ?? this.timezone,
      targetAudience: targetAudience ?? this.targetAudience,
      targetRegions: targetRegions ?? this.targetRegions,
      targetAgeMin: targetAgeMin ?? this.targetAgeMin,
      targetAgeMax: targetAgeMax ?? this.targetAgeMax,
      targetSports: targetSports ?? this.targetSports,
      budgetTotal: budgetTotal ?? this.budgetTotal,
      budgetSpent: budgetSpent ?? this.budgetSpent,
      currency: currency ?? this.currency,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      ctaText: ctaText ?? this.ctaText,
      ctaUrl: ctaUrl ?? this.ctaUrl,
      hashtags: hashtags ?? this.hashtags,
      platformCopy: platformCopy ?? this.platformCopy,
      isABTest: isABTest ?? this.isABTest,
      abTestId: abTestId ?? this.abTestId,
      variant: variant ?? this.variant,
      impressions: impressions ?? this.impressions,
      clicks: clicks ?? this.clicks,
      conversions: conversions ?? this.conversions,
      shares: shares ?? this.shares,
      likes: likes ?? this.likes,
      revenue: revenue ?? this.revenue,
      swarmPowered: swarmPowered ?? this.swarmPowered,
      swarmAgentId: swarmAgentId ?? this.swarmAgentId,
      swarmContentCount: swarmContentCount ?? this.swarmContentCount,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    type,
    status,
    channels,
    createdBy,
    createdAt,
    updatedAt,
    scheduledStart,
    scheduledEnd,
    targetAudience,
    targetRegions,
    budgetTotal,
    budgetSpent,
    impressions,
    clicks,
    conversions,
    shares,
    likes,
    revenue,
    swarmPowered,
    swarmContentCount,
    tags,
  ];
}

// ── CampaignVariant ──────────────────────────────────────────────────────────

/// A single A/B test variant of a [MarketingCampaignModel].
/// Maps to Firestore `campaign_variants/{variantId}`.
///
/// The parent campaign document links variants via [abTestId].
/// The winning variant is promoted by setting [isWinner] = true.
class CampaignVariant extends Equatable {
  final String id;
  final String campaignId;

  /// Short label used for identification: 'A', 'B', 'C', etc.
  final String label;
  final String description;

  // Content overrides for this variant
  final String? heroImageUrl;
  final String? ctaText;
  final String? ctaUrl;

  /// Per-channel copy, keyed by [CampaignChannel.name].
  final Map<String, String> platformCopy;

  // Metrics written by pipeline
  final int impressions;
  final int clicks;
  final int conversions;

  /// Set to true when this variant is declared the winner.
  final bool isWinner;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const CampaignVariant({
    required this.id,
    required this.campaignId,
    required this.label,
    this.description = '',
    this.heroImageUrl,
    this.ctaText,
    this.ctaUrl,
    this.platformCopy = const {},
    this.impressions = 0,
    this.clicks = 0,
    this.conversions = 0,
    this.isWinner = false,
    required this.createdAt,
    this.updatedAt,
  });

  // ── Computed KPIs ───────────────────────────────────────────────────────

  double get ctr => impressions > 0 ? (clicks / impressions) * 100 : 0;
  double get conversionRate => clicks > 0 ? (conversions / clicks) * 100 : 0;

  // ── Firestore serialization ─────────────────────────────────────────────

  factory CampaignVariant.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return CampaignVariant(
      id: doc.id,
      campaignId: d['campaignId'] as String? ?? '',
      label: d['label'] as String? ?? 'A',
      description: d['description'] as String? ?? '',
      heroImageUrl: d['heroImageUrl'] as String?,
      ctaText: d['ctaText'] as String?,
      ctaUrl: d['ctaUrl'] as String?,
      platformCopy: Map<String, String>.from(d['platformCopy'] as Map? ?? {}),
      impressions: (d['impressions'] as num?)?.toInt() ?? 0,
      clicks: (d['clicks'] as num?)?.toInt() ?? 0,
      conversions: (d['conversions'] as num?)?.toInt() ?? 0,
      isWinner: d['isWinner'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'campaignId': campaignId,
    'label': label,
    'description': description,
    if (heroImageUrl != null) 'heroImageUrl': heroImageUrl,
    if (ctaText != null) 'ctaText': ctaText,
    if (ctaUrl != null) 'ctaUrl': ctaUrl,
    'platformCopy': platformCopy,
    'impressions': impressions,
    'clicks': clicks,
    'conversions': conversions,
    'isWinner': isWinner,
    'createdAt': Timestamp.fromDate(createdAt),
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
  };

  CampaignVariant copyWith({
    String? id,
    String? campaignId,
    String? label,
    String? description,
    String? heroImageUrl,
    String? ctaText,
    String? ctaUrl,
    Map<String, String>? platformCopy,
    int? impressions,
    int? clicks,
    int? conversions,
    bool? isWinner,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CampaignVariant(
      id: id ?? this.id,
      campaignId: campaignId ?? this.campaignId,
      label: label ?? this.label,
      description: description ?? this.description,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      ctaText: ctaText ?? this.ctaText,
      ctaUrl: ctaUrl ?? this.ctaUrl,
      platformCopy: platformCopy ?? this.platformCopy,
      impressions: impressions ?? this.impressions,
      clicks: clicks ?? this.clicks,
      conversions: conversions ?? this.conversions,
      isWinner: isWinner ?? this.isWinner,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    campaignId,
    label,
    impressions,
    clicks,
    conversions,
    isWinner,
    createdAt,
  ];
}
