import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../features/creator/models/creator_profile_model.dart';
import '../../features/creator/models/creator_earnings_model.dart';
import '../../features/creator/models/clip_analytics_model.dart';
import '../../features/creator/models/creator_insights_model.dart';

/// Hero creator test data seeder
/// Creates Kai Reeves (creatorId: hero_creator_test_001) with realistic mock data
class CreatorHeroSeeder {
  static const String heroCreatorId = 'hero_creator_test_001';
  static const String heroCreatorName = 'Kai Reeves';

  /// Get mock hero creator profile
  static CreatorProfile getMockHeroProfile() {
    return CreatorProfile(
      creatorId: heroCreatorId,
      displayName: heroCreatorName,
      bio: 'Combat analyst. Clips. Strategy.',
      avatarUrl: 'https://via.placeholder.com/200?text=Kai+Reeves',
      followerCount: 8750,
      rank: 42,
      trendingScore: 7.8,
      joinedDate: DateTime(2023, 6, 15),
      isVerified: true,
      website: 'https://example.com/kai',
      socialHandle: '@kai_reeves_combat',
    );
  }

  /// Get mock hero creator earnings for current month
  static CreatorEarnings getMockHeroEarnings() {
    final now = DateTime.now();
    return CreatorEarnings(
      creatorId: heroCreatorId,
      month: now.month,
      year: now.year,
      totalEarnings: 2450.50,
      clipsGenerated: 12,
      totalViews: 285000,
      totalLikes: 18450,
      totalShares: 5280,
      totalConversions: 485,
      conversionRate: 2.87,
      avgEarningsPerClip: 204.21,
      nextPayoutDate: DateTime.now().add(const Duration(days: 5)),
      payoutProcessed: false,
    );
  }

  /// Get mock hero creator clips (3-5 realistic clips)
  static List<ClipAnalytics> getMockHeroClips() {
    return [
      ClipAnalytics(
        clipId: 'clip_001_hero',
        creatorId: heroCreatorId,
        clipTitle: 'Submission Breakdown: Rear Naked Choke Escape',
        clipType: 'submission',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        views: 125000,
        likes: 8950,
        shares: 2340,
        comments: 450,
        conversions: 287,
        earningsFromClip: 875.50,
        trendingScore: 8.4,
        isTrending: true,
        conversionRate: 3.45,
        fightId: 'fight_123',
        eventId: 'event_456',
        round: 2,
      ),
      ClipAnalytics(
        clipId: 'clip_002_hero',
        creatorId: heroCreatorId,
        clipTitle: 'Knockout Science: Hand Speed Analysis',
        clipType: 'knockout',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        views: 95000,
        likes: 7200,
        shares: 1890,
        comments: 320,
        conversions: 152,
        earningsFromClip: 462.30,
        trendingScore: 7.2,
        isTrending: true,
        conversionRate: 2.18,
        fightId: 'fight_124',
        eventId: 'event_456',
        round: 1,
      ),
      ClipAnalytics(
        clipId: 'clip_003_hero',
        creatorId: heroCreatorId,
        clipTitle: 'Footwork Mastery: How Pros Control Distance',
        clipType: 'technique',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        views: 65000,
        likes: 4100,
        shares: 980,
        comments: 210,
        conversions: 46,
        earningsFromClip: 140.20,
        trendingScore: 5.8,
        isTrending: false,
        conversionRate: 0.94,
        fightId: 'fight_125',
        eventId: 'event_457',
        round: null,
      ),
      ClipAnalytics(
        clipId: 'clip_004_hero',
        creatorId: heroCreatorId,
        clipTitle: 'Comeback Story: From 0-2 to Champion Path',
        clipType: 'narrative',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        views: 150000,
        likes: 12500,
        shares: 3200,
        comments: 680,
        conversions: 312,
        earningsFromClip: 950.15,
        trendingScore: 8.9,
        isTrending: true,
        conversionRate: 2.88,
        fightId: null,
        eventId: 'event_458',
        round: null,
      ),
      ClipAnalytics(
        clipId: 'clip_005_hero',
        creatorId: heroCreatorId,
        clipTitle: 'Live Reaction: UFC Main Event Upset',
        clipType: 'reaction',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        views: 210000,
        likes: 14800,
        shares: 4100,
        comments: 920,
        conversions: 198,
        earningsFromClip: 602.50,
        trendingScore: 6.5,
        isTrending: false,
        conversionRate: 1.55,
        fightId: 'fight_126',
        eventId: 'event_459',
        round: null,
      ),
    ];
  }

  /// Get mock hero creator insights
  static CreatorInsights getMockHeroInsights() {
    return CreatorInsights(
      creatorId: heroCreatorId,
      topClipTypes: ['submission', 'knockout', 'narrative'],
      bestPostHours: [19, 14, 21, 12, 18],
      avgConversionRate: 2.20,
      platformAvgConversionRate: 1.85,
      recommendations: [
        'Your submission clips convert 45% better than average — keep focusing on technical breakdowns.',
        'Post between 6PM-10PM UTC for maximum engagement with your audience.',
        'Try more narrative-driven clips like your "Comeback Story" — they\'re trending 52% above your average.',
      ],
      opportunities: [
        'UFC PPV card this weekend — create predictions and live reactions to capitalize on the hype.',
        'Trending topic: MMA weight cutting — create a science breakdown to ride the wave.',
        'Collaborate with top strikers — your technique content pairs well with their highlight reels.',
      ],
      benchmarkVsCreators: 18.92, // 18.92% above average
      recommendationScore: 92,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get mock badges (2 unlocked)
  static List<String> getMockHeroBadges() {
    return [
      'bronze', // 10 clips
      'silver', // 100 clips
    ];
  }

  /// Get mock ranking info
  static Map<String, dynamic> getMockHeroRanking() {
    return {
      'rank': 42,
      'trendingScore': 7.8,
      'percentile': '98.2',
      'rankStatus': '⭐ TOP 100',
    };
  }

  /// Seed hero creator to Firestore (Phase 2B)
  static Future<void> seedHeroCreatorToFirestore(
    FirebaseFirestore firestore,
  ) async {
    try {
      debugPrint('🌱 Seeding hero creator: $heroCreatorId...');

      // Create profile doc
      await firestore
          .collection('creator_dashboards')
          .doc(heroCreatorId)
          .collection('profile')
          .doc('info')
          .set(getMockHeroProfile().toFirestore());

      // Create earnings doc
      final earnings = getMockHeroEarnings();
      await firestore
          .collection('creator_dashboards')
          .doc(heroCreatorId)
          .collection('earnings')
          .doc('${earnings.month}_${earnings.year}')
          .set(earnings.toFirestore());

      // Create clips
      for (final clip in getMockHeroClips()) {
        await firestore
            .collection('creator_dashboards')
            .doc(heroCreatorId)
            .collection('clips')
            .doc(clip.clipId)
            .set(clip.toFirestore());
      }

      // Create badges
      await firestore
          .collection('creator_dashboards')
          .doc(heroCreatorId)
          .collection('badges')
          .doc('unlocked')
          .set({
            'badges': getMockHeroBadges(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Create ranking
      final ranking = getMockHeroRanking();
      await firestore
          .collection('creator_dashboards')
          .doc(heroCreatorId)
          .collection('ranking')
          .doc('global')
          .set({
            'rank': ranking['rank'],
            'trendingScore': ranking['trendingScore'],
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Create insights
      await firestore
          .collection('creator_dashboards')
          .doc(heroCreatorId)
          .collection('insights')
          .doc('latest')
          .set(getMockHeroInsights().toFirestore());

      debugPrint('✅ Hero creator seeded successfully');
    } catch (e) {
      debugPrint('❌ Error seeding hero creator: $e');
      rethrow;
    }
  }

  /// Alias for seedHeroCreatorToFirestore()
  /// Seeds hero creator to Firestore (Phase 2B)
  static Future<void> seedHeroCreator({FirebaseFirestore? firestore}) async {
    await seedHeroCreatorToFirestore(firestore ?? FirebaseFirestore.instance);
  }
}
