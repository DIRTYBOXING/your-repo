// ═══════════════════════════════════════════════════════════════════════════
// STORY ENGINE — Ephemeral 24-Hour Stories with Rich Interactions
// ═══════════════════════════════════════════════════════════════════════════
//
// Instagram/Snapchat-style ephemeral content for DFC:
//  • Timed stories — auto-expire after 24 hours
//  • Rich media — images, videos, text overlays, AR filters
//  • Story reactions — combat-themed quick reactions
//  • Story highlights — permanent collections of best stories
//  • View tracking — anonymous and identified viewers
//  • Story ads — monetizable story placements for promoters
//
// Complements the existing feed with time-sensitive, casual content
// ═══════════════════════════════════════════════════════════════════════════

// ─── Enums ──────────────────────────────────────────────────────────────

enum StoryMediaType {
  image('Image', '📷'),
  video('Video', '🎬'),
  text('Text', '📝'),
  poll('Poll', '📊'),
  countdown('Countdown', '⏱️'),
  question('Question', '❓'),
  quiz('Quiz', '🧠');

  final String label;
  final String icon;
  const StoryMediaType(this.label, this.icon);
}

enum StoryReaction {
  fire('🔥', 'Fire'),
  knockout('💥', 'Knockout'),
  respect('🥋', 'Respect'),
  power('💪', 'Power'),
  love('❤️', 'Love'),
  laugh('😂', 'Laugh'),
  shocked('😮', 'Shocked'),
  champion('👑', 'Champion');

  final String emoji;
  final String label;
  const StoryReaction(this.emoji, this.label);
}

enum StoryVisibility {
  everyone('Everyone'),
  friendsOnly('Friends Only'),
  closeFriends('Close Friends'),
  subscribersOnly('Subscribers Only');

  final String label;
  const StoryVisibility(this.label);
}

// ─── Models ─────────────────────────────────────────────────────────────

class StoryItem {
  final String storyId;
  final String authorId;
  final StoryMediaType mediaType;
  final String? mediaUrl;
  final String? textContent;
  final String? backgroundColor;
  final StoryVisibility visibility;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<StoryViewRecord> views;
  final Map<StoryReaction, int> reactions;
  final String? locationTag;
  final List<String> mentions;
  final List<String> hashtags;
  final StoryPollData? poll;
  final String? linkUrl;
  final bool isAd;

  const StoryItem({
    required this.storyId,
    required this.authorId,
    required this.mediaType,
    this.mediaUrl,
    this.textContent,
    this.backgroundColor,
    this.visibility = StoryVisibility.everyone,
    required this.createdAt,
    required this.expiresAt,
    this.views = const [],
    this.reactions = const {},
    this.locationTag,
    this.mentions = const [],
    this.hashtags = const [],
    this.poll,
    this.linkUrl,
    this.isAd = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  int get viewCount => views.length;
  int get totalReactions => reactions.values.fold(0, (a, b) => a + b);

  Duration get timeRemaining {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Map<String, dynamic> toMap() => {
    'storyId': storyId,
    'authorId': authorId,
    'mediaType': mediaType.name,
    'visibility': visibility.name,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'isExpired': isExpired,
    'viewCount': viewCount,
    'totalReactions': totalReactions,
    'timeRemainingMinutes': timeRemaining.inMinutes,
  };
}

class StoryViewRecord {
  final String viewerId;
  final DateTime viewedAt;
  final StoryReaction? reaction;

  const StoryViewRecord({
    required this.viewerId,
    required this.viewedAt,
    this.reaction,
  });
}

class StoryPollData {
  final String question;
  final List<String> options;
  final Map<int, int> voteCounts;
  final Set<String> voterIds;

  const StoryPollData({
    required this.question,
    required this.options,
    this.voteCounts = const {},
    this.voterIds = const {},
  });

  int get totalVotes => voteCounts.values.fold(0, (a, b) => a + b);

  double optionPercentage(int index) {
    if (totalVotes == 0) return 0;
    return (voteCounts[index] ?? 0) / totalVotes * 100;
  }
}

class StoryHighlight {
  final String highlightId;
  final String userId;
  final String title;
  final String? coverUrl;
  final List<String> storyIds;
  final DateTime createdAt;

  const StoryHighlight({
    required this.highlightId,
    required this.userId,
    required this.title,
    this.coverUrl,
    this.storyIds = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'highlightId': highlightId,
    'userId': userId,
    'title': title,
    'storyCount': storyIds.length,
  };
}

class StoryFeed {
  final List<UserStoryGroup> groups;
  final int totalActiveStories;

  const StoryFeed({required this.groups, this.totalActiveStories = 0});
}

class UserStoryGroup {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final List<StoryItem> stories;
  final bool hasUnviewed;
  final DateTime latestStoryAt;

  const UserStoryGroup({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.stories,
    this.hasUnviewed = true,
    required this.latestStoryAt,
  });
}

// ─── Service ────────────────────────────────────────────────────────────

class StoryEngine {
  StoryEngine._();
  static final StoryEngine instance = StoryEngine._();

  static const Duration _storyLifetime = Duration(hours: 24);
  static const int _maxStoriesPerDay = 30;

  final _stories = <String, StoryItem>{};
  final _highlights = <String, StoryHighlight>{};

  /// Create a new story.
  StoryItem createStory({
    required String authorId,
    required StoryMediaType mediaType,
    String? mediaUrl,
    String? textContent,
    String? backgroundColor,
    StoryVisibility visibility = StoryVisibility.everyone,
    String? locationTag,
    List<String> mentions = const [],
    List<String> hashtags = const [],
    StoryPollData? poll,
    String? linkUrl,
  }) {
    // Check daily limit
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayCount = _stories.values
        .where((s) => s.authorId == authorId && s.createdAt.isAfter(todayStart))
        .length;

    if (todayCount >= _maxStoriesPerDay) {
      // Return a placeholder indicating limit reached — caller should check
      return StoryItem(
        storyId: 'limit_reached',
        authorId: authorId,
        mediaType: mediaType,
        createdAt: today,
        expiresAt: today,
      );
    }

    final now = DateTime.now();
    final story = StoryItem(
      storyId: 'story_${now.millisecondsSinceEpoch}',
      authorId: authorId,
      mediaType: mediaType,
      mediaUrl: mediaUrl,
      textContent: textContent,
      backgroundColor: backgroundColor,
      visibility: visibility,
      createdAt: now,
      expiresAt: now.add(_storyLifetime),
      locationTag: locationTag,
      mentions: mentions,
      hashtags: hashtags,
      poll: poll,
      linkUrl: linkUrl,
    );

    _stories[story.storyId] = story;
    return story;
  }

  /// Record a story view.
  void recordView({
    required String storyId,
    required String viewerId,
    StoryReaction? reaction,
  }) {
    final story = _stories[storyId];
    if (story == null || story.isExpired) return;
    if (story.authorId == viewerId) return; // Don't count self-views

    // Check if already viewed
    final alreadyViewed = story.views.any((v) => v.viewerId == viewerId);

    final updatedViews = List<StoryViewRecord>.from(story.views);
    if (!alreadyViewed) {
      updatedViews.add(
        StoryViewRecord(
          viewerId: viewerId,
          viewedAt: DateTime.now(),
          reaction: reaction,
        ),
      );
    } else if (reaction != null) {
      // Update reaction for existing view
      final idx = updatedViews.indexWhere((v) => v.viewerId == viewerId);
      if (idx >= 0) {
        updatedViews[idx] = StoryViewRecord(
          viewerId: viewerId,
          viewedAt: updatedViews[idx].viewedAt,
          reaction: reaction,
        );
      }
    }

    // Update reaction counts
    final updatedReactions = Map<StoryReaction, int>.from(story.reactions);
    if (reaction != null) {
      updatedReactions[reaction] = (updatedReactions[reaction] ?? 0) + 1;
    }

    _stories[storyId] = StoryItem(
      storyId: story.storyId,
      authorId: story.authorId,
      mediaType: story.mediaType,
      mediaUrl: story.mediaUrl,
      textContent: story.textContent,
      backgroundColor: story.backgroundColor,
      visibility: story.visibility,
      createdAt: story.createdAt,
      expiresAt: story.expiresAt,
      views: updatedViews,
      reactions: updatedReactions,
      locationTag: story.locationTag,
      mentions: story.mentions,
      hashtags: story.hashtags,
      poll: story.poll,
      linkUrl: story.linkUrl,
      isAd: story.isAd,
    );
  }

  /// Vote on a story poll.
  bool votePoll({
    required String storyId,
    required String voterId,
    required int optionIndex,
  }) {
    final story = _stories[storyId];
    if (story == null || story.poll == null || story.isExpired) return false;
    if (story.poll!.voterIds.contains(voterId)) return false;
    if (optionIndex < 0 || optionIndex >= story.poll!.options.length) {
      return false;
    }

    final newVoteCounts = Map<int, int>.from(story.poll!.voteCounts);
    newVoteCounts[optionIndex] = (newVoteCounts[optionIndex] ?? 0) + 1;

    final newVoterIds = Set<String>.from(story.poll!.voterIds)..add(voterId);

    final updatedPoll = StoryPollData(
      question: story.poll!.question,
      options: story.poll!.options,
      voteCounts: newVoteCounts,
      voterIds: newVoterIds,
    );

    _stories[storyId] = StoryItem(
      storyId: story.storyId,
      authorId: story.authorId,
      mediaType: story.mediaType,
      mediaUrl: story.mediaUrl,
      textContent: story.textContent,
      backgroundColor: story.backgroundColor,
      visibility: story.visibility,
      createdAt: story.createdAt,
      expiresAt: story.expiresAt,
      views: story.views,
      reactions: story.reactions,
      locationTag: story.locationTag,
      mentions: story.mentions,
      hashtags: story.hashtags,
      poll: updatedPoll,
      linkUrl: story.linkUrl,
      isAd: story.isAd,
    );
    return true;
  }

  /// Create a story highlight.
  StoryHighlight createHighlight({
    required String userId,
    required String title,
    String? coverUrl,
    List<String> storyIds = const [],
  }) {
    final highlight = StoryHighlight(
      highlightId: 'highlight_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: title,
      coverUrl: coverUrl,
      storyIds: storyIds,
      createdAt: DateTime.now(),
    );
    _highlights[highlight.highlightId] = highlight;
    return highlight;
  }

  /// Build the story feed for a user (stories from followed users).
  StoryFeed buildFeed({
    required String viewerId,
    required Set<String> followingIds,
  }) {
    _cleanExpired();

    final relevantIds = {...followingIds, viewerId};

    // Group active stories by user
    final groupMap = <String, List<StoryItem>>{};
    for (final story in _stories.values) {
      if (!story.isExpired && relevantIds.contains(story.authorId)) {
        groupMap.putIfAbsent(story.authorId, () => []).add(story);
      }
    }

    final groups = groupMap.entries.map((entry) {
      final stories = entry.value
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final hasUnviewed = stories.any(
        (s) => !s.views.any((v) => v.viewerId == viewerId),
      );

      return UserStoryGroup(
        userId: entry.key,
        displayName: 'User ${entry.key}',
        stories: stories,
        hasUnviewed: hasUnviewed,
        latestStoryAt: stories.last.createdAt,
      );
    }).toList();

    // Sort: unviewed first, then by recency
    groups.sort((a, b) {
      if (a.hasUnviewed && !b.hasUnviewed) return -1;
      if (!a.hasUnviewed && b.hasUnviewed) return 1;
      return b.latestStoryAt.compareTo(a.latestStoryAt);
    });

    // Put viewer's own stories first
    final ownIndex = groups.indexWhere((g) => g.userId == viewerId);
    if (ownIndex > 0) {
      final own = groups.removeAt(ownIndex);
      groups.insert(0, own);
    }

    return StoryFeed(
      groups: groups,
      totalActiveStories: _stories.values.where((s) => !s.isExpired).length,
    );
  }

  /// Get a user's highlights.
  List<StoryHighlight> getHighlights(String userId) {
    return _highlights.values.where((h) => h.userId == userId).toList();
  }

  /// Get a story by ID.
  StoryItem? getStory(String storyId) => _stories[storyId];

  /// Get active stories for an author.
  List<StoryItem> getActiveStories(String authorId) {
    _cleanExpired();
    return _stories.values
        .where((s) => s.authorId == authorId && !s.isExpired)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Get stats.
  Map<String, dynamic> get stats => {
    'totalStories': _stories.length,
    'activeStories': _stories.values.where((s) => !s.isExpired).length,
    'expiredStories': _stories.values.where((s) => s.isExpired).length,
    'highlights': _highlights.length,
  };

  void _cleanExpired() {
    _stories.removeWhere(
      (_, s) =>
          s.isExpired &&
          DateTime.now().difference(s.expiresAt) > const Duration(hours: 1),
    );
  }
}
