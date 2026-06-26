import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// DFC Social Impact & Mentoring Campaign Model
/// These campaigns focus on awareness, mentoring, and social impact.
class SocialCampaign extends Equatable {
  final String id;
  final String name;
  final String description;
  final String category; // mental_health, health_awareness, charity, mentoring
  final String assetPath; // Path to campaign image
  final String tagline;
  final DateTime launchDate;
  final String status; // active, draft, completed
  final String targetAudience; // men, women, general
  final List<String> tags;
  final String? callToAction; // Button text or CTA
  final String? ctaLink; // Link for CTA button

  const SocialCampaign({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.assetPath,
    required this.tagline,
    required this.launchDate,
    this.status = 'active',
    this.targetAudience = 'general',
    this.tags = const [],
    this.callToAction,
    this.ctaLink,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    category,
    assetPath,
    tagline,
    launchDate,
    status,
    targetAudience,
    tags,
    callToAction,
    ctaLink,
  ];

  /// DFC Men's Mental Health Mentoring Campaign
  /// Teaches men to rebuild courage, confidence, and mental resilience
  static final mensHealthCampaign = SocialCampaign(
    id: 'mens_mental_health_2025',
    name: 'Men\'s Mental Health Mentoring',
    description:
        'A mentoring program designed to help men rebuild courage, confidence, and mental resilience. Victims and survivors find safe paths to rediscover their strength. Teaching men to be men again.',
    category: 'mental_health',
    assetPath: 'assets/campaigns/dfc_mens_mental_health.svg',
    tagline: 'Teach Men to Be Men Again',
    launchDate: DateTime(2025, 3),
    targetAudience: 'men',
    tags: const [
      'mentoring',
      'mental_health',
      'resilience',
      'recovery',
      'nightchill',
    ],
    callToAction: 'Learn More',
    ctaLink: '/mentoring/mens',
  );

  /// DFC Women's Health & Breast Cancer Awareness Campaign
  /// Empowering women survivors to rebuild courage and reclaim strength
  static final womensHealthCampaign = SocialCampaign(
    id: 'womens_health_awareness_2025',
    name: 'Women\'s Health & Breast Cancer Awareness',
    description:
        'Empowering women survivors to rebuild courage and reclaim their strength. A safe space for those who can\'t walk into traditional gyms, rebuilding confidence one step at a time. Dedicated to those lost to breast cancer.',
    category: 'health_awareness',
    assetPath: 'assets/campaigns/dfc_womens_health_shield.svg',
    tagline: 'Rebuilding Courage, Reclaiming Strength',
    launchDate: DateTime(2025, 2, 15),
    targetAudience: 'women',
    tags: const ['health', 'breast_cancer', 'awareness', 'empowerment', 'recovery'],
    callToAction: 'Join the Community',
    ctaLink: '/womens-health',
  );

  /// Breast Cancer Awareness Month Badge Campaign
  /// Pink ribbon badge for spreading awareness
  static final breastCancerAwarenessMonth = SocialCampaign(
    id: 'breast_cancer_awareness_month_2025',
    name: 'Breast Cancer Awareness Month Badge',
    description:
        'A simple, powerful badge campaign for Breast Cancer Awareness Month. Share the pink ribbon and spread hope to everyone fighting breast cancer.',
    category: 'health_awareness',
    assetPath: 'assets/campaigns/dfc_breast_cancer_badge.svg',
    tagline: 'Wear Pink, Spread Hope',
    launchDate: DateTime(2025, 10),
    tags: const ['health', 'breast_cancer', 'awareness', 'badge', 'october'],
    callToAction: 'Join the Movement',
    ctaLink: '/breast-cancer-awareness',
  );

  /// DFC Charity Campaign - Change a Child's Future
  /// \$1 can provide food, shelter, and education for struggling children
  static final charityChildrensCampaign = SocialCampaign(
    id: 'dfc_charity_2025',
    name: 'DFC Charity - Change a Child\'s Future',
    description:
        '\$1 can change a child\'s future. Your donation helps provide struggling Australian and New Zealand children with safe homes, food, and education. Every dollar matters.',
    category: 'charity',
    assetPath: 'assets/campaigns/dfc_gold_coin_charity.svg',
    tagline: '\$1 CAN CHANGE A CHILD\'S FUTURE',
    launchDate: DateTime(2025, 1, 15),
    tags: const ['charity', 'children', 'education', 'donations', 'impact'],
    callToAction: 'Donate Now',
    ctaLink: '/donate',
  );

  /// Buy a Coffee, Not a Coffin Campaign
  /// Mentoring message: invest in life and recovery, not death
  static final buyACoffeeNotACoffinCampaign = SocialCampaign(
    id: 'coffee_not_coffin_2025',
    name: 'Buy a Coffee, Not a Coffin',
    description:
        'A powerful mentoring message: invest in life, not death. Support the DFC mentoring programs that help people choose hope, connection, and recovery over despair. Every coffee donation supports mentoring.',
    category: 'mentoring',
    assetPath: 'assets/campaigns/dfc_coffee_not_coffin.svg',
    tagline: 'BUY A COFFEE, NOT A COFFIN',
    launchDate: DateTime(2025, 2),
    tags: const ['mentoring', 'recovery', 'support', 'awareness', 'mental-health'],
    callToAction: 'Support Recovery',
    ctaLink: '/support-recovery',
  );

  /// Get all active campaigns
  static List<SocialCampaign> getAllCampaigns() => [
    mensHealthCampaign,
    womensHealthCampaign,
    breastCancerAwarenessMonth,
    charityChildrensCampaign,
    buyACoffeeNotACoffinCampaign,
  ];

  /// Get campaigns by category
  static List<SocialCampaign> getCampaignsByCategory(String category) =>
      getAllCampaigns().where((c) => c.category == category).toList();

  /// Get campaigns by target audience
  static List<SocialCampaign> getCampaignsByAudience(String audience) =>
      getAllCampaigns().where((c) => c.targetAudience == audience).toList();

  /// Get active campaigns only
  static List<SocialCampaign> getActiveCampaigns() =>
      getAllCampaigns().where((c) => c.status == 'active').toList();

  /// Returns a widget rendering this campaign's SVG asset with a fallback.
  /// Uses local bundled SVG by default; falls back to a placeholder icon.
  Widget campaignImage({double width = 120}) {
    if (assetPath.endsWith('.svg')) {
      return SvgPicture.asset(
        assetPath,
        width: width,
        height: width,
        placeholderBuilder: (_) => SizedBox(
          width: width,
          height: width,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }
    return Image.asset(
      assetPath,
      width: width,
      height: width,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.campaign, size: width * 0.6),
    );
  }
}
