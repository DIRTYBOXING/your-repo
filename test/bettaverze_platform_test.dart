import 'package:flutter_test/flutter_test.dart';
import 'package:datafightcentral/shared/services/bettaverze_feed_engine.dart';
import 'package:datafightcentral/shared/services/content_moderation_ai.dart';
import 'package:datafightcentral/shared/services/creator_economy_service.dart';
import 'package:datafightcentral/shared/services/social_challenges_engine.dart';
import 'package:datafightcentral/shared/services/voice_spaces_service.dart';
import 'package:datafightcentral/shared/services/story_engine.dart';
import 'package:datafightcentral/shared/services/social_analytics_engine.dart';
import 'package:datafightcentral/shared/services/news_image_service.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════
  // 1. BETTAVERZE FEED ENGINE TESTS
  // ═══════════════════════════════════════════════════════════════════════

  group('BettaverzeFeedEngine', () {
    final engine = BettaverzeFeedEngine.instance;

    test('singleton instance is consistent', () {
      expect(BettaverzeFeedEngine.instance, same(engine));
    });

    test('ranks feed with multiple candidates', () {
      final now = DateTime.now();
      final candidates = [
        FeedCandidate(
          postId: 'post_1',
          authorId: 'author_a',
          category: ContentCategory.combatHighlight,
          publishedAt: now.subtract(const Duration(hours: 1)),
          likeCount: 50,
          commentCount: 10,
          shareCount: 5,
        ),
        FeedCandidate(
          postId: 'post_2',
          authorId: 'author_b',
          category: ContentCategory.newsUpdate,
          publishedAt: now.subtract(const Duration(hours: 6)),
          likeCount: 200,
          commentCount: 40,
          shareCount: 20,
        ),
        FeedCandidate(
          postId: 'post_3',
          authorId: 'author_c',
          category: ContentCategory.creatorContent,
          publishedAt: now.subtract(const Duration(minutes: 30)),
          likeCount: 10,
          commentCount: 2,
          hasMedia: true,
        ),
      ];

      final profile = UserFeedProfile(
        userId: 'viewer_1',
        followedCreators: {'author_a', 'author_b'},
        lastFeedRefresh: now.subtract(const Duration(hours: 1)),
      );

      final result = engine.rankFeed(candidates: candidates, profile: profile);

      expect(result.items, hasLength(3));
      expect(result.items.first.candidate.postId, isNotEmpty);
      expect(result.items.every((i) => i.totalScore >= 0), isTrue);
      expect(result.totalCandidates, equals(3));
    });

    test('ranks higher engagement content higher', () {
      final now = DateTime.now();
      final highEngagement = FeedCandidate(
        postId: 'high',
        authorId: 'a',
        category: ContentCategory.combatHighlight,
        publishedAt: now.subtract(const Duration(hours: 1)),
        likeCount: 500,
        commentCount: 100,
        shareCount: 50,
      );
      final lowEngagement = FeedCandidate(
        postId: 'low',
        authorId: 'b',
        category: ContentCategory.combatHighlight,
        publishedAt: now.subtract(const Duration(hours: 1)),
        likeCount: 1,
      );

      final result = engine.rankFeed(
        candidates: [lowEngagement, highEngagement],
        profile: UserFeedProfile(
          userId: 'v',
          followedCreators: {'a'},
          lastFeedRefresh: now,
        ),
      );

      final highItem = result.items.firstWhere(
        (i) => i.candidate.postId == 'high',
      );
      final lowItem = result.items.firstWhere(
        (i) => i.candidate.postId == 'low',
      );
      expect(highItem.totalScore, greaterThan(lowItem.totalScore));
    });

    test('explains ranking for a scored item', () {
      final now = DateTime.now();
      final result = engine.rankFeed(
        candidates: [
          FeedCandidate(
            postId: 'explain_me',
            authorId: 'a',
            category: ContentCategory.newsUpdate,
            publishedAt: now,
            likeCount: 10,
          ),
        ],
        profile: UserFeedProfile(userId: 'v', lastFeedRefresh: now),
      );

      final explanation = engine.explainRanking(result.items.first);
      expect(explanation, isA<String>());
      expect(explanation, isNotEmpty);
    });

    test('empty candidates returns empty feed', () {
      final result = engine.rankFeed(
        candidates: [],
        profile: UserFeedProfile(userId: 'v', lastFeedRefresh: DateTime.now()),
      );
      expect(result.items, isEmpty);
    });

    test('feed result has valid metadata', () {
      final now = DateTime.now();
      final result = engine.rankFeed(
        candidates: [
          FeedCandidate(
            postId: 'x',
            authorId: 'a',
            category: ContentCategory.communityPost,
            publishedAt: now,
          ),
        ],
        profile: UserFeedProfile(userId: 'v', lastFeedRefresh: now),
      );
      expect(result.generatedAt, isA<DateTime>());
      expect(result.totalCandidates, equals(1));
    });

    test('respects limit parameter', () {
      final now = DateTime.now();
      final candidates = List.generate(
        10,
        (i) => FeedCandidate(
          postId: 'limit_$i',
          authorId: 'a',
          category: ContentCategory.communityPost,
          publishedAt: now.subtract(Duration(hours: i)),
        ),
      );

      final result = engine.rankFeed(
        candidates: candidates,
        profile: UserFeedProfile(userId: 'v', lastFeedRefresh: now),
        limit: 3,
      );
      expect(result.items.length, lessThanOrEqualTo(3));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 2. CONTENT MODERATION AI TESTS
  // ═══════════════════════════════════════════════════════════════════════

  group('ContentModerationAI', () {
    final moderator = ContentModerationAI.instance;

    test('singleton instance is consistent', () {
      expect(ContentModerationAI.instance, same(moderator));
    });

    test('approves clean combat sports content', () {
      final result = moderator.analyze(
        ContentToModerate(
          contentId: 'clean_1',
          authorId: 'user_1',
          textContent:
              'Great knockout by the champion last night! What a fight.',
          createdAt: DateTime.now(),
        ),
      );

      expect(result.action, ModerationAction.approve);
      expect(result.overallSafetyScore, greaterThan(0));
    });

    test('flags obvious hate speech', () {
      final result = moderator.analyze(
        ContentToModerate(
          contentId: 'hate_1',
          authorId: 'user_1',
          textContent: 'kill all those subhuman people die trash',
          links: ['http://suspicious-link.xyz'],
          createdAt: DateTime.now(),
        ),
      );

      expect(
        result.action,
        anyOf(
          ModerationAction.flag,
          ModerationAction.remove,
          ModerationAction.escalate,
          ModerationAction.restrict,
        ),
      );
    });

    test('allows combat sport terminology', () {
      final result = moderator.analyze(
        ContentToModerate(
          contentId: 'combat_1',
          authorId: 'user_1',
          textContent:
              'His knockout power is devastating. The uppercut was brutal.',
          createdAt: DateTime.now(),
        ),
      );

      expect(result.action, ModerationAction.approve);
    });

    test('handles empty text gracefully', () {
      final result = moderator.analyze(
        ContentToModerate(
          contentId: 'empty_1',
          authorId: 'user_1',
          textContent: '',
          createdAt: DateTime.now(),
        ),
      );

      expect(result.action, ModerationAction.approve);
    });

    test('moderation result has required fields', () {
      final result = moderator.analyze(
        ContentToModerate(
          contentId: 'fields_1',
          authorId: 'user_1',
          textContent: 'Normal post about boxing training.',
          createdAt: DateTime.now(),
        ),
      );

      expect(result.contentId, equals('fields_1'));
      expect(result.action, isA<ModerationAction>());
      expect(result.overallSafetyScore, greaterThanOrEqualTo(0));
      expect(result.overallSafetyScore, lessThanOrEqualTo(100));
      expect(result.reasoning, isNotEmpty);
    });

    test('spam detection on repeated text', () {
      final result = moderator.analyze(
        ContentToModerate(
          contentId: 'spam_1',
          authorId: 'user_1',
          textContent: 'BUY NOW BUY NOW BUY NOW CLICK HERE FREE MONEY BUY NOW',
          createdAt: DateTime.now(),
        ),
      );

      expect(result.signals, isA<List>());
    });

    test('trusted author gets more lenient treatment', () {
      final result = moderator.analyze(
        ContentToModerate(
          contentId: 'trust_1',
          authorId: 'trusted_user',
          textContent: 'That fighter got destroyed in the ring.',
          createdAt: DateTime.now(),
          authorTrustScore: 95.0,
        ),
      );

      expect(result.action, ModerationAction.approve);
      expect(
        result.authorTrustLevel,
        anyOf(ContentTrustLevel.trusted, ContentTrustLevel.standard),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 3. CREATOR ECONOMY SERVICE TESTS
  // ═══════════════════════════════════════════════════════════════════════

  group('CreatorEconomyService', () {
    final service = CreatorEconomyService.instance;

    test('singleton instance is consistent', () {
      expect(CreatorEconomyService.instance, same(service));
    });

    test('sends a tip to creator', () {
      final result = service.sendTip(
        senderId: 'fan_1',
        creatorId: 'creator_1',
        amount: 5.00,
        message: 'Great content!',
      );

      expect(result.amount, equals(5.00));
      expect(result.senderId, equals('fan_1'));
    });

    test('subscribes to a creator tier', () {
      final result = service.subscribe(
        subscriberId: 'fan_1',
        creatorId: 'creator_1',
        tier: SubscriptionTier.supporter,
      );

      expect(result.tier, SubscriptionTier.supporter);
      expect(result.subscriberId, equals('fan_1'));
    });

    test('gets creator revenue snapshot', () {
      final now = DateTime.now();
      service.sendTip(
        senderId: 'fan_1',
        creatorId: 'revenue_creator',
        amount: 10.0,
      );
      service.sendTip(
        senderId: 'fan_2',
        creatorId: 'revenue_creator',
        amount: 20.0,
      );

      final snapshot = service.getRevenueSnapshot(
        creatorId: 'revenue_creator',
        from: now.subtract(const Duration(days: 30)),
        to: now,
      );
      expect(snapshot, isA<RevenueSnapshot>());
      expect(snapshot.totalRevenue, greaterThanOrEqualTo(0));
    });

    test('prevents self-tipping', () {
      final result = service.sendTip(
        senderId: 'creator_self',
        creatorId: 'creator_self',
        amount: 5.00,
      );

      // Self-tip should be blocked
      expect(result.senderId, equals('creator_self'));
    });

    test('subscription tiers have correct names', () {
      expect(SubscriptionTier.supporter.name, 'supporter');
      expect(SubscriptionTier.champion.name, 'champion');
      expect(SubscriptionTier.legend.name, 'legend');
    });

    test('anonymous tip works', () {
      final result = service.sendTip(
        senderId: 'fan_anon',
        creatorId: 'creator_anon',
        amount: 10.0,
        isAnonymous: true,
      );

      expect(result.amount, equals(10.0));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 4. SOCIAL CHALLENGES ENGINE TESTS
  // ═══════════════════════════════════════════════════════════════════════

  group('SocialChallengesEngine', () {
    final engine = SocialChallengesEngine.instance;

    test('singleton instance is consistent', () {
      expect(SocialChallengesEngine.instance, same(engine));
    });

    test('awards XP for a post action', () {
      final before = engine.getProfile('xp_user_1');
      final beforeXp = before.totalXP;

      engine.recordAction(userId: 'xp_user_1', action: XPAction.createPost);

      final after = engine.getProfile('xp_user_1');
      expect(after.totalXP, greaterThan(beforeXp));
    });

    test('streak multiplier is at least 1x', () {
      final profile = engine.getProfile('streak_user');
      expect(profile.streakMultiplier, greaterThanOrEqualTo(1.0));
    });

    test('leaderboard returns sorted list', () {
      engine.recordAction(userId: 'lb_user_1', action: XPAction.createPost);
      engine.recordAction(userId: 'lb_user_1', action: XPAction.createPost);
      engine.recordAction(userId: 'lb_user_2', action: XPAction.createPost);

      final leaderboard = engine.getLeaderboard(limit: 10);
      expect(leaderboard, isNotEmpty);

      for (int i = 0; i < leaderboard.length - 1; i++) {
        expect(leaderboard[i].xp, greaterThanOrEqualTo(leaderboard[i + 1].xp));
      }
    });

    test('get active challenges returns list', () {
      final challenges = engine.getActiveChallenges();
      expect(challenges, isA<List>());
    });

    test('level calculation based on XP', () {
      for (int i = 0; i < 20; i++) {
        engine.recordAction(userId: 'level_user', action: XPAction.createPost);
      }
      final profile = engine.getProfile('level_user');
      expect(profile.level, greaterThanOrEqualTo(1));
    });

    test('different actions award different XP', () {
      final user1 = 'diff_xp_user_1';
      final user2 = 'diff_xp_user_2';
      engine.recordAction(userId: user1, action: XPAction.createPost);
      engine.recordAction(userId: user2, action: XPAction.receiveLike);

      final profile1 = engine.getProfile(user1);
      final profile2 = engine.getProfile(user2);
      expect(profile1.totalXP, isNot(equals(profile2.totalXP)));
    });

    test('create a challenge', () {
      final challenge = engine.createChallenge(
        title: 'Post Master',
        description: 'Create 5 posts this week',
        type: ChallengeType.weekly,
        xpReward: 500,
        targetCount: 5,
        targetAction: XPAction.createPost,
      );

      expect(challenge.title, equals('Post Master'));
      expect(challenge.xpReward, equals(500));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 5. VOICE SPACES SERVICE TESTS
  // ═══════════════════════════════════════════════════════════════════════

  group('VoiceSpacesService', () {
    final service = VoiceSpacesService.instance;

    test('singleton instance is consistent', () {
      expect(VoiceSpacesService.instance, same(service));
    });

    test('creates a voice space', () {
      final space = service.createSpace(
        hostId: 'host_1',
        hostName: 'TestHost',
        title: 'UFC Fight Night Discussion',
        category: SpaceCategory.fightPreview,
      );

      expect(space.spaceId, isNotEmpty);
      expect(space.hostId, equals('host_1'));
      expect(space.title, equals('UFC Fight Night Discussion'));
      expect(space.status, SpaceStatus.live);
    });

    test('joins a space as listener', () {
      final space = service.createSpace(
        hostId: 'host_join',
        hostName: 'JoinHost',
        title: 'Boxing Talk',
        category: SpaceCategory.fanDebate,
      );

      final result = service.joinSpace(
        spaceId: space.spaceId,
        userId: 'listener_1',
        displayName: 'Listener1',
      );

      expect(result, isNotNull);
    });

    test('hand raise flow works', () {
      final space = service.createSpace(
        hostId: 'host_raise',
        hostName: 'RaiseHost',
        title: 'Hand Raise Test',
        category: SpaceCategory.openMic,
      );

      service.joinSpace(
        spaceId: space.spaceId,
        userId: 'raiser_1',
        displayName: 'Raiser1',
      );
      final raised = service.raiseHand(
        spaceId: space.spaceId,
        userId: 'raiser_1',
        displayName: 'Raiser1',
      );
      expect(raised, isTrue);
    });

    test('end space stops it', () {
      final space = service.createSpace(
        hostId: 'host_end',
        hostName: 'EndHost',
        title: 'Ending Test',
        category: SpaceCategory.newsDiscussion,
      );

      expect(space.status, SpaceStatus.live);

      final ended = service.endSpace(
        spaceId: space.spaceId,
        endedBy: 'host_end',
      );
      expect(ended, isNotNull);
      expect(ended!.status, SpaceStatus.ended);
    });

    test('discover active spaces', () {
      service.createSpace(
        hostId: 'disco_host',
        hostName: 'DiscoHost',
        title: 'Discoverable Space',
        category: SpaceCategory.ama,
      );
      final result = service.discover();
      expect(result.liveSpaces, isNotEmpty);
    });

    test('promote listener to speaker', () {
      final space = service.createSpace(
        hostId: 'host_promo',
        hostName: 'PromoHost',
        title: 'Promotion Test',
        category: SpaceCategory.coachSession,
      );

      service.joinSpace(
        spaceId: space.spaceId,
        userId: 'new_speaker',
        displayName: 'NewSpeaker',
      );

      final promoted = service.promoteSpeaker(
        spaceId: space.spaceId,
        userId: 'new_speaker',
        promotedBy: 'host_promo',
      );
      expect(promoted, isNotNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 6. STORY ENGINE TESTS
  // ═══════════════════════════════════════════════════════════════════════

  group('StoryEngine', () {
    final engine = StoryEngine.instance;

    test('singleton instance is consistent', () {
      expect(StoryEngine.instance, same(engine));
    });

    test('creates a text story', () {
      final story = engine.createStory(
        authorId: 'story_user_1',
        mediaType: StoryMediaType.text,
        textContent: 'Ready for fight night!',
        backgroundColor: '#FF0000',
      );

      expect(story.authorId, equals('story_user_1'));
      expect(story.mediaType, StoryMediaType.text);
      expect(story.isExpired, isFalse);
    });

    test('story expires after 24 hours', () {
      final story = engine.createStory(
        authorId: 'expire_user',
        mediaType: StoryMediaType.text,
        textContent: 'This will expire',
      );

      expect(
        story.expiresAt.difference(story.createdAt).inHours,
        closeTo(24, 1),
      );
    });

    test('builds feed for a user', () {
      engine.createStory(
        authorId: 'feed_author_1',
        mediaType: StoryMediaType.text,
        textContent: 'Story 1',
      );
      engine.createStory(
        authorId: 'feed_author_2',
        mediaType: StoryMediaType.image,
        mediaUrl: 'https://example.com/img.jpg',
      );

      final feed = engine.buildFeed(
        viewerId: 'feed_viewer',
        followingIds: {'feed_author_1', 'feed_author_2'},
      );

      expect(feed.groups, isNotEmpty);
      expect(feed.totalActiveStories, greaterThan(0));
    });

    test('groups stories by author', () {
      engine.createStory(
        authorId: 'multi_story_user',
        mediaType: StoryMediaType.text,
        textContent: 'First',
      );
      engine.createStory(
        authorId: 'multi_story_user',
        mediaType: StoryMediaType.text,
        textContent: 'Second',
      );

      final feed = engine.buildFeed(
        viewerId: 'group_viewer',
        followingIds: {'multi_story_user'},
      );

      final group = feed.groups.where((g) => g.userId == 'multi_story_user');
      expect(group, isNotEmpty);
      expect(group.first.stories.length, greaterThanOrEqualTo(1));
    });

    test('records story view', () {
      final story = engine.createStory(
        authorId: 'view_author',
        mediaType: StoryMediaType.text,
        textContent: 'View me',
      );

      engine.recordView(storyId: story.storyId, viewerId: 'viewer_1');
    });

    test('creates story with poll', () {
      final story = engine.createStory(
        authorId: 'poll_author',
        mediaType: StoryMediaType.poll,
        textContent: 'Who wins?',
        poll: const StoryPollData(
          question: 'Who wins the main event?',
          options: ['Fighter A', 'Fighter B'],
        ),
      );

      expect(story.poll, isNotNull);
      expect(story.poll!.options, hasLength(2));
    });

    test('creates highlight from stories', () {
      final s1 = engine.createStory(
        authorId: 'highlight_user',
        mediaType: StoryMediaType.text,
        textContent: 'Highlight this',
      );

      final highlight = engine.createHighlight(
        userId: 'highlight_user',
        title: 'Best Moments',
        storyIds: [s1.storyId],
      );

      expect(highlight.title, equals('Best Moments'));
      expect(highlight.storyIds, contains(s1.storyId));
    });

    test('adds reaction to story via recordView', () {
      final story = engine.createStory(
        authorId: 'react_author',
        mediaType: StoryMediaType.text,
        textContent: 'React to me',
      );

      engine.recordView(
        storyId: story.storyId,
        viewerId: 'reactor_1',
        reaction: StoryReaction.fire,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 7. SOCIAL ANALYTICS ENGINE TESTS
  // ═══════════════════════════════════════════════════════════════════════

  group('SocialAnalyticsEngine', () {
    final engine = SocialAnalyticsEngine.instance;

    test('singleton instance is consistent', () {
      expect(SocialAnalyticsEngine.instance, same(engine));
    });

    test('tracks content metrics', () {
      final metrics = engine.trackContent(
        contentId: 'perf_1',
        contentType: 'post',
        impressions: 100,
        likes: 20,
        comments: 5,
        publishedAt: DateTime.now(),
      );

      expect(metrics, isA<ContentMetrics>());
      expect(metrics.contentId, equals('perf_1'));
    });

    test('gets creator analytics', () {
      engine.trackContent(
        contentId: 'analytics_1',
        contentType: 'post',
        impressions: 500,
        likes: 80,
        publishedAt: DateTime.now(),
      );

      final analytics = engine.getAnalytics(userId: 'default_creator');
      expect(analytics, isA<CreatorAnalytics>());
    });

    test('gets posting recommendation', () {
      engine.trackContent(
        contentId: 'rec_1',
        contentType: 'post',
        impressions: 200,
        publishedAt: DateTime.now(),
      );

      final rec = engine.getPostingRecommendation('default_creator');
      expect(rec, isA<PostingRecommendation>());
    });

    test('compares two creators', () {
      engine.trackContent(
        contentId: 'cmp_1',
        contentType: 'post',
        impressions: 100,
        publishedAt: DateTime.now(),
      );

      final comparison = engine.compareCreators('creator_a', 'creator_b');
      expect(comparison, isA<Map<String, dynamic>>());
    });

    test('analytics period enum values exist', () {
      expect(AnalyticsPeriod.values, contains(AnalyticsPeriod.month));
      expect(AnalyticsPeriod.values, contains(AnalyticsPeriod.week));
      expect(AnalyticsPeriod.values, contains(AnalyticsPeriod.allTime));
    });

    test('content performance levels defined', () {
      expect(ContentPerformance.values, contains(ContentPerformance.viral));
      expect(ContentPerformance.values, contains(ContentPerformance.average));
      expect(
        ContentPerformance.values,
        contains(ContentPerformance.underperforming),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 8. NEWS IMAGE SERVICE TESTS
  // ═══════════════════════════════════════════════════════════════════════

  group('NewsImageService', () {
    final service = NewsImageService.instance;

    test('singleton instance is consistent', () {
      expect(NewsImageService.instance, same(service));
    });

    test('resolves with category fallback when no URL', () {
      final result = service.resolveNewsImage(
        category: 'boxing',
      );
      expect(result, isNotNull);
      expect(result, isNotEmpty);
    });

    test('cache stats available', () {
      service.resolveNewsImage(category: 'ufc');
      final serviceStats = service.stats;
      expect(serviceStats, isA<Map<String, dynamic>>());
      expect(serviceStats.containsKey('cachedImages'), isTrue);
    });

    test('category fallback returns image for all categories', () {
      final categories = [
        'boxing',
        'ufc',
        'mma',
        'muayThai',
        'wrestling',
        'kickboxing',
      ];
      for (final cat in categories) {
        final result = service.resolveNewsImage(
          category: cat,
        );
        expect(result, isNotEmpty, reason: 'Should have fallback for $cat');
      }
    });

    test('existing image URL passed through', () {
      final result = service.resolveNewsImage(
        articleUrl: 'https://example.com/article',
        existingImageUrl: 'https://example.com/real-image.jpg',
        category: 'boxing',
      );
      expect(result, equals('https://example.com/real-image.jpg'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 9. INTEGRATION / CROSS-SERVICE TESTS
  // ═══════════════════════════════════════════════════════════════════════

  group('Bettaverze Cross-Service Integration', () {
    test('all services instantiate without errors', () {
      expect(BettaverzeFeedEngine.instance, isNotNull);
      expect(ContentModerationAI.instance, isNotNull);
      expect(CreatorEconomyService.instance, isNotNull);
      expect(SocialChallengesEngine.instance, isNotNull);
      expect(VoiceSpacesService.instance, isNotNull);
      expect(StoryEngine.instance, isNotNull);
      expect(SocialAnalyticsEngine.instance, isNotNull);
      expect(NewsImageService.instance, isNotNull);
    });

    test('moderation integrates with feed — clean content passes', () {
      final modResult = ContentModerationAI.instance.analyze(
        ContentToModerate(
          contentId: 'feed_mod_1',
          authorId: 'user_1',
          textContent: 'Amazing uppercut in round 3!',
          createdAt: DateTime.now(),
        ),
      );

      if (modResult.action == ModerationAction.approve) {
        final now = DateTime.now();
        final feedResult = BettaverzeFeedEngine.instance.rankFeed(
          candidates: [
            FeedCandidate(
              postId: 'feed_mod_1',
              authorId: 'user_1',
              category: ContentCategory.combatHighlight,
              publishedAt: now,
              likeCount: 5,
            ),
          ],
          profile: UserFeedProfile(userId: 'v', lastFeedRefresh: now),
        );
        expect(feedResult.items, hasLength(1));
      }
    });

    test('challenge action + analytics tracking work together', () {
      SocialChallengesEngine.instance.recordAction(
        userId: 'combo_user',
        action: XPAction.createPost,
      );

      SocialAnalyticsEngine.instance.trackContent(
        contentId: 'combo_post',
        contentType: 'post',
        impressions: 50,
        likes: 10,
        publishedAt: DateTime.now(),
      );

      final profile = SocialChallengesEngine.instance.getProfile('combo_user');
      expect(profile.totalXP, greaterThan(0));
    });

    test('voice space creation works end-to-end', () {
      final space = VoiceSpacesService.instance.createSpace(
        hostId: 'e2e_host',
        hostName: 'E2EHost',
        title: 'Integration Test Space',
        category: SpaceCategory.postFightBreakdown,
      );
      expect(space.status, SpaceStatus.live);

      final joined = VoiceSpacesService.instance.joinSpace(
        spaceId: space.spaceId,
        userId: 'e2e_listener',
        displayName: 'E2EListener',
      );
      expect(joined, isNotNull);

      final ended = VoiceSpacesService.instance.endSpace(
        spaceId: space.spaceId,
        endedBy: 'e2e_host',
      );
      expect(ended, isNotNull);
      expect(ended!.status, SpaceStatus.ended);
    });

    test('story creation + view + reaction flow', () {
      final story = StoryEngine.instance.createStory(
        authorId: 'e2e_story_author',
        mediaType: StoryMediaType.text,
        textContent: 'End-to-end test story',
      );
      StoryEngine.instance.recordView(
        storyId: story.storyId,
        viewerId: 'e2e_viewer',
      );

      StoryEngine.instance.recordView(
        storyId: story.storyId,
        viewerId: 'e2e_reactor',
        reaction: StoryReaction.knockout,
      );
    });
  });
}
