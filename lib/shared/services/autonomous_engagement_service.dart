import 'dart:math';

/// ═══════════════════════════════════════════════════════════════════════════
/// AUTONOMOUS ENGAGEMENT SERVICE — AI-Driven Social Engagement Bots
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Generates contextual engagement actions (reactions, comments, boosts)
/// on social feed posts using strategy rules and bot personas. Plugs into
/// BotOrchestratorService for audit and SocialService for feed access.
///
/// Each bot persona has a voice, expertise, and engagement style. Actions
/// are generated deterministically from content analysis — no external API
/// calls, safe for offline/demo mode.
/// ═══════════════════════════════════════════════════════════════════════════

enum EngagementActionType {
  react('React'),
  comment('Comment'),
  share('Share'),
  boost('Boost'),
  challengeReply('Challenge Reply');

  final String label;
  const EngagementActionType(this.label);
}

enum BotPersona {
  hypeMan(
    id: 'hype_man',
    name: 'HypeBot',
    emoji: '🔥',
    voice: 'High energy, fan-first, exclamation heavy',
    expertise: 'Main events, KOs, highlight reels',
  ),
  analyst(
    id: 'analyst',
    name: 'AnalystBot',
    emoji: '📊',
    voice: 'Measured, data-driven, uses stats',
    expertise: 'Fight breakdowns, records, matchup analysis',
  ),
  coach(
    id: 'coach',
    name: 'CoachBot',
    emoji: '🥊',
    voice: 'Technical, constructive, training focused',
    expertise: 'Technique, training, fight IQ, strategy',
  ),
  communityBuilder(
    id: 'community',
    name: 'CommunityBot',
    emoji: '🤝',
    voice: 'Welcoming, question-asking, inclusive',
    expertise: 'New members, events, local shows, participation',
  ),
  newsBreaker(
    id: 'news_breaker',
    name: 'NewsBreaker',
    emoji: '📰',
    voice: 'Urgent, factual, headline style',
    expertise: 'Fight news, matchup announcements, results',
  );

  final String id;
  final String name;
  final String emoji;
  final String voice;
  final String expertise;
  const BotPersona({
    required this.id,
    required this.name,
    required this.emoji,
    required this.voice,
    required this.expertise,
  });
}

class EngagementAction {
  final String actionId;
  final BotPersona persona;
  final EngagementActionType type;
  final String targetPostId;
  final String? commentText;
  final String? reactionType; // 'respect', 'warrior', 'champion', etc.
  final double confidenceScore; // 0–1
  final String reasoning;
  final DateTime generatedAt;

  const EngagementAction({
    required this.actionId,
    required this.persona,
    required this.type,
    required this.targetPostId,
    this.commentText,
    this.reactionType,
    required this.confidenceScore,
    required this.reasoning,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() => {
    'actionId': actionId,
    'persona': persona.id,
    'type': type.label,
    'targetPostId': targetPostId,
    'commentText': commentText,
    'reactionType': reactionType,
    'confidence': confidenceScore,
    'reasoning': reasoning,
    'generatedAt': generatedAt.toIso8601String(),
  };
}

class PostContext {
  final String postId;
  final String content;
  final String postType; // 'text', 'image', 'video', 'article'
  final String authorId;
  final bool authorVerified;
  final int likes;
  final int comments;
  final int shares;
  final List<String> tags;
  final DateTime createdAt;

  const PostContext({
    required this.postId,
    required this.content,
    required this.postType,
    required this.authorId,
    this.authorVerified = false,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.tags = const [],
    required this.createdAt,
  });
}

class EngagementStrategy {
  final double engagementRate; // target hourly actions per 100 posts
  final double commentRatio; // fraction of actions that are comments
  final double reactionRatio;
  final double boostRatio;
  final int maxActionsPerPost;
  final Duration cooldownPerPost;

  const EngagementStrategy({
    this.engagementRate = 15,
    this.commentRatio = 0.4,
    this.reactionRatio = 0.45,
    this.boostRatio = 0.15,
    this.maxActionsPerPost = 2,
    this.cooldownPerPost = const Duration(hours: 4),
  });
}

class AutonomousEngagementService {
  AutonomousEngagementService._();
  static final AutonomousEngagementService instance =
      AutonomousEngagementService._();

  final _rng = Random(42);
  final _recentActions = <String, DateTime>{}; // postId → lastActionTime
  EngagementStrategy _strategy = const EngagementStrategy();

  EngagementStrategy get strategy => _strategy;
  void updateStrategy(EngagementStrategy s) => _strategy = s;

  /// Generate engagement actions for a batch of posts
  List<EngagementAction> generateActions(List<PostContext> posts) {
    final actions = <EngagementAction>[];
    final now = DateTime.now();

    for (final post in posts) {
      // Cooldown check
      final lastAction = _recentActions[post.postId];
      if (lastAction != null &&
          now.difference(lastAction) < _strategy.cooldownPerPost) {
        continue;
      }

      // Pick best persona for this content
      final persona = _selectPersona(post);

      // Decide action type based on strategy ratios and content
      final actionType = _decideActionType(post);

      // Generate the action
      final action = _buildAction(post, persona, actionType);
      if (action.confidenceScore >= 0.4) {
        actions.add(action);
        _recentActions[post.postId] = now;
      }
    }

    return actions;
  }

  /// Generate a context-aware comment for a specific post
  EngagementAction generateComment(PostContext post) {
    final persona = _selectPersona(post);
    return _buildAction(post, persona, EngagementActionType.comment);
  }

  BotPersona _selectPersona(PostContext post) {
    final text = post.content.toLowerCase();

    // Match content to persona expertise
    if (_containsAny(text, ['knockout', 'ko', 'finish', 'highlight', 'wow'])) {
      return BotPersona.hypeMan;
    }
    if (_containsAny(text, ['stats', 'record', 'streak', 'ranking', 'odds'])) {
      return BotPersona.analyst;
    }
    if (_containsAny(text, [
      'training',
      'technique',
      'drill',
      'camp',
      'sparring',
    ])) {
      return BotPersona.coach;
    }
    if (_containsAny(text, [
      'fight announced',
      'breaking',
      'news',
      'confirmed',
      'signed',
    ])) {
      return BotPersona.newsBreaker;
    }
    if (_containsAny(text, ['welcome', 'first', 'debut', 'join', 'event'])) {
      return BotPersona.communityBuilder;
    }

    // Default to hype or community based on engagement level
    return post.likes > 50 ? BotPersona.hypeMan : BotPersona.communityBuilder;
  }

  EngagementActionType _decideActionType(PostContext post) {
    final r = _rng.nextDouble();
    if (r < _strategy.reactionRatio) return EngagementActionType.react;
    if (r < _strategy.reactionRatio + _strategy.commentRatio) {
      return EngagementActionType.comment;
    }
    return EngagementActionType.boost;
  }

  EngagementAction _buildAction(
    PostContext post,
    BotPersona persona,
    EngagementActionType type,
  ) {
    String? commentText;
    String? reactionType;
    double confidence;
    String reasoning;

    switch (type) {
      case EngagementActionType.react:
        reactionType = _pickReaction(post);
        confidence = 0.8;
        reasoning = 'Auto-react: ${persona.name} reacting to ${post.postType}';
        break;

      case EngagementActionType.comment:
        commentText = _generateComment(post, persona);
        confidence = 0.65;
        reasoning =
            '${persona.name} comment: content matched ${persona.expertise}';
        break;

      case EngagementActionType.boost:
        confidence = post.authorVerified ? 0.75 : 0.5;
        reasoning =
            'Boost: verified=${post.authorVerified}, persona=${persona.name}';
        break;

      case EngagementActionType.share:
        confidence = post.likes > 20 ? 0.7 : 0.3;
        reasoning = 'Share: engagement level ${post.likes} likes';
        break;

      case EngagementActionType.challengeReply:
        commentText = _generateChallengeReply(post, persona);
        confidence = 0.55;
        reasoning = 'Challenge reply by ${persona.name}';
        break;
    }

    return EngagementAction(
      actionId:
          '${persona.id}_${post.postId}_${DateTime.now().millisecondsSinceEpoch}',
      persona: persona,
      type: type,
      targetPostId: post.postId,
      commentText: commentText,
      reactionType: reactionType,
      confidenceScore: confidence,
      reasoning: reasoning,
      generatedAt: DateTime.now(),
    );
  }

  String _pickReaction(PostContext post) {
    final text = post.content.toLowerCase();
    if (_containsAny(text, ['knockout', 'ko', 'finish', 'highlight'])) {
      return 'warrior';
    }
    if (_containsAny(text, ['respect', 'legend', 'tribute', 'honor'])) {
      return 'respect';
    }
    if (_containsAny(text, ['champion', 'title', 'belt', 'gold'])) {
      return 'champion';
    }
    if (_containsAny(text, ['training', 'grind', 'hard work', 'camp'])) {
      return 'strong';
    }
    return 'support';
  }

  String _generateComment(PostContext post, BotPersona persona) {
    final templates = _commentTemplates[persona] ?? _defaultTemplates;
    final idx = post.postId.hashCode.abs() % templates.length;
    return templates[idx];
  }

  String _generateChallengeReply(PostContext post, BotPersona persona) {
    final templates = [
      'Great point — but have you considered the counter-strategy?',
      'Interesting take! Love seeing different perspectives in combat sports.',
      'The numbers tell a different story — let\'s break it down.',
    ];
    return templates[post.postId.hashCode.abs() % templates.length];
  }

  bool _containsAny(String text, List<String> keywords) =>
      keywords.any((kw) => text.contains(kw));

  static const _commentTemplates = <BotPersona, List<String>>{
    BotPersona.hypeMan: [
      'This is INSANE! What a moment for combat sports! 🔥',
      'Absolutely electric! This is why we love this sport!',
      'LETS GOOO! That was unbelievable!',
      'No words. Just pure combat sports energy right there.',
      'This is what it\'s all about — heart, skill, and POWER!',
    ],
    BotPersona.analyst: [
      'Interesting matchup data here — the striking differential tells the story.',
      'If you look at the fight stats, the volume advantage was key.',
      'The numbers back this up — 73% takedown defense is elite level.',
      'Statistical edge: the fighter who controlled distance won 4 of 5 rounds.',
      'Worth noting: fighters with this profile historically finish 62% of bouts.',
    ],
    BotPersona.coach: [
      'Great technique on display — notice the level change timing.',
      'The footwork here is textbook. Aspiring fighters, study this.',
      'Training tip: this combination works because of the setup jab angle.',
      'Perfect example of fight IQ — reading the opponent\'s rhythm.',
      'The defensive movement here saved the fight. Position before submission.',
    ],
    BotPersona.communityBuilder: [
      'Love seeing this community grow! Who else is watching this weekend?',
      'Welcome to the fight family! What got you into combat sports?',
      'This is what makes our community special. Respect to everyone involved.',
      'Tag a training partner who needs to see this!',
      'Support your local shows — they\'re the foundation of this sport.',
    ],
    BotPersona.newsBreaker: [
      'BREAKING: This changes the landscape of the division.',
      'CONFIRMED: Big implications for the upcoming card.',
      'JUST IN: The fight world reacts to this development.',
      'OFFICIAL: This matchup is one fans have been waiting for.',
      'UPDATE: Sources indicate this will shake up the rankings.',
    ],
  };

  static const _defaultTemplates = [
    'Great content! The DFC community loves this.',
    'This is what combat sports is all about.',
    'Fantastic post — keep sharing with the community!',
  ];
}
