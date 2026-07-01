// ═══════════════════════════════════════════════════════════════════════════
// CONTENT MODERATION AI — Automated Safety & Quality Scoring
// ═══════════════════════════════════════════════════════════════════════════
//
// Multi-layered content safety pipeline:
//  • Toxicity scoring — hate speech, harassment, threats
//  • Spam detection — repetition, link farming, engagement bait
//  • Misinformation signals — unverified claims, sensationalism
//  • Context-aware severity — combat sport content gets tuned thresholds
//  • Appeals workflow — transparent decisions with human escalation
//
// Feeds moderation queue and auto-actions for the existing SocialService
// ═══════════════════════════════════════════════════════════════════════════

// ─── Enums ──────────────────────────────────────────────────────────────

enum ToxicityCategory {
  hateSpeed('Hate Speech', 0.95, 'Targeting identity groups'),
  harassment('Harassment', 0.90, 'Targeted personal attacks'),
  threat('Threat / Violence', 0.95, 'Credible threats of harm'),
  sexualContent('Sexual Content', 0.85, 'Explicit sexual material'),
  selfHarm('Self-Harm', 0.90, 'Content promoting self-injury'),
  spam('Spam', 0.70, 'Repetitive or deceptive content'),
  misinformation('Misinformation', 0.75, 'Unverified or false claims'),
  copyrightViolation('Copyright', 0.80, 'Unauthorized content use'),
  impersonation('Impersonation', 0.85, 'Pretending to be another person'),
  rageBait('Rage Bait', 0.60, 'Intentionally inflammatory');

  final String label;
  final double autoActionThreshold;
  final String description;
  const ToxicityCategory(
    this.label,
    this.autoActionThreshold,
    this.description,
  );
}

enum ModerationAction {
  approve('Approved', 'Content passed all checks'),
  flag('Flagged', 'Content flagged for human review'),
  restrict('Restricted', 'Visible only to author'),
  remove('Removed', 'Content removed from platform'),
  escalate('Escalated', 'Sent to trust & safety team'),
  warn('Warning Issued', 'Author received a warning');

  final String label;
  final String description;
  const ModerationAction(this.label, this.description);
}

enum ContentTrustLevel {
  trusted(85, 100, 'Verified creator with clean history'),
  standard(50, 84, 'Normal user with no violations'),
  watched(25, 49, 'User with recent violations'),
  restricted(0, 24, 'User under active moderation');

  final int minScore;
  final int maxScore;
  final String description;
  const ContentTrustLevel(this.minScore, this.maxScore, this.description);

  static ContentTrustLevel fromScore(double score) {
    final s = score.round();
    if (s >= 85) return trusted;
    if (s >= 50) return standard;
    if (s >= 25) return watched;
    return restricted;
  }
}

// ─── Models ─────────────────────────────────────────────────────────────

class ContentToModerate {
  final String contentId;
  final String authorId;
  final String textContent;
  final List<String> mediaUrls;
  final List<String> links;
  final String contentType; // post, comment, message, bio
  final DateTime createdAt;
  final double authorTrustScore;
  final int authorViolationCount;
  final bool isReported;
  final int reportCount;

  const ContentToModerate({
    required this.contentId,
    required this.authorId,
    required this.textContent,
    this.mediaUrls = const [],
    this.links = const [],
    this.contentType = 'post',
    required this.createdAt,
    this.authorTrustScore = 75.0,
    this.authorViolationCount = 0,
    this.isReported = false,
    this.reportCount = 0,
  });
}

class ToxicitySignal {
  final ToxicityCategory category;
  final double confidence;
  final String evidence;
  final bool triggeredAutoAction;

  const ToxicitySignal({
    required this.category,
    required this.confidence,
    required this.evidence,
    this.triggeredAutoAction = false,
  });

  Map<String, dynamic> toMap() => {
    'category': category.name,
    'confidence': confidence,
    'evidence': evidence,
    'autoAction': triggeredAutoAction,
  };
}

class ModerationDecision {
  final String contentId;
  final ModerationAction action;
  final List<ToxicitySignal> signals;
  final double overallSafetyScore;
  final ContentTrustLevel authorTrustLevel;
  final String reasoning;
  final bool requiresHumanReview;
  final DateTime decidedAt;
  final String? appealId;

  const ModerationDecision({
    required this.contentId,
    required this.action,
    required this.signals,
    required this.overallSafetyScore,
    required this.authorTrustLevel,
    required this.reasoning,
    this.requiresHumanReview = false,
    required this.decidedAt,
    this.appealId,
  });

  Map<String, dynamic> toMap() => {
    'contentId': contentId,
    'action': action.name,
    'safetyScore': overallSafetyScore,
    'trustLevel': authorTrustLevel.name,
    'reasoning': reasoning,
    'humanReview': requiresHumanReview,
    'signalCount': signals.length,
    'decidedAt': decidedAt.toIso8601String(),
    'signals': signals.map((s) => s.toMap()).toList(),
  };
}

class AppealRequest {
  final String appealId;
  final String contentId;
  final String authorId;
  final String reason;
  final DateTime submittedAt;
  final String status; // pending, approved, denied

  const AppealRequest({
    required this.appealId,
    required this.contentId,
    required this.authorId,
    required this.reason,
    required this.submittedAt,
    this.status = 'pending',
  });
}

// ─── Service ────────────────────────────────────────────────────────────

class ContentModerationAI {
  ContentModerationAI._();
  static final ContentModerationAI instance = ContentModerationAI._();

  // Pattern dictionaries for text analysis
  static const _hatePatterns = [
    'kill all',
    'die trash',
    'subhuman',
    'go back to',
    'not real people',
  ];

  static const _harassmentPatterns = [
    'you\'re worthless',
    'nobody likes you',
    'kill yourself',
    'ugly loser',
    'fat pig',
  ];

  static const _threatPatterns = [
    'i will find you',
    'gonna hurt you',
    'watch your back',
    'you\'re dead',
    'coming for you',
  ];

  static const _spamIndicators = [
    'click here',
    'free money',
    'limited offer',
    'act now',
    'dm me for',
    'follow for follow',
    'check my bio',
    '💰💰💰',
  ];

  static const _rageBaitIndicators = [
    'bet you won\'t share',
    'nobody is talking about',
    'they don\'t want you to know',
    'this will make you angry',
    'unpopular opinion',
  ];

  // Combat-sport specific allowlist — these terms should NOT be penalized
  static const _combatAllowlist = [
    'knockout',
    'ko',
    'tko',
    'submission',
    'chokehold',
    'armbar',
    'fight',
    'round',
    'strike',
    'punch',
    'kick',
    'takedown',
    'ground and pound',
    'rear naked choke',
    'triangle choke',
    'guillotine',
    'heel hook',
    'clinch',
    'uppercut',
    'hook',
    'jab',
    'cross',
    'elbow',
    'knee strike',
    'ring',
    'octagon',
    'cage',
    'bell',
    'corner',
    'referee',
    'decision',
    'split decision',
    'unanimous decision',
  ];

  final _appealQueue = <AppealRequest>[];
  final _decisionLog = <ModerationDecision>[];

  /// Analyze content and return a moderation decision.
  ModerationDecision analyze(ContentToModerate content) {
    final signals = <ToxicitySignal>[];
    final lowerText = content.textContent.toLowerCase();

    // Strip combat-context terms before toxic analysis
    final sanitized = _sanitizeCombatTerms(lowerText);

    // Run all toxicity detectors
    _detectHateSpeech(sanitized, signals);
    _detectHarassment(sanitized, signals);
    _detectThreats(sanitized, signals);
    _detectSpam(lowerText, content, signals);
    _detectRageBait(lowerText, signals);
    _detectMisinformation(lowerText, content, signals);
    _detectSelfHarm(sanitized, signals);

    // Calculate overall safety score (100 = perfectly safe)
    double safetyScore = 100.0;
    for (final signal in signals) {
      safetyScore -= signal.confidence * 30;
    }
    safetyScore = safetyScore.clamp(0, 100);

    // Adjust for author trust
    final trustLevel = ContentTrustLevel.fromScore(content.authorTrustScore);
    if (trustLevel == ContentTrustLevel.watched) {
      safetyScore -= 10;
    } else if (trustLevel == ContentTrustLevel.restricted) {
      safetyScore -= 20;
    }
    safetyScore = safetyScore.clamp(0, 100);

    // Report multiplier
    if (content.isReported && content.reportCount >= 3) {
      safetyScore -= 15;
      safetyScore = safetyScore.clamp(0, 100);
    }

    // Determine action
    final action = _determineAction(signals, safetyScore, trustLevel);
    final needsHuman =
        action == ModerationAction.flag ||
        action == ModerationAction.escalate ||
        (content.isReported && content.reportCount >= 5);

    final decision = ModerationDecision(
      contentId: content.contentId,
      action: action,
      signals: signals,
      overallSafetyScore: safetyScore,
      authorTrustLevel: trustLevel,
      reasoning: _generateReasoning(action, signals, safetyScore),
      requiresHumanReview: needsHuman,
      decidedAt: DateTime.now(),
    );

    _decisionLog.add(decision);
    return decision;
  }

  /// Submit an appeal for a moderation decision.
  AppealRequest submitAppeal({
    required String contentId,
    required String authorId,
    required String reason,
  }) {
    final appeal = AppealRequest(
      appealId: 'appeal_${DateTime.now().millisecondsSinceEpoch}',
      contentId: contentId,
      authorId: authorId,
      reason: reason,
      submittedAt: DateTime.now(),
    );
    _appealQueue.add(appeal);
    return appeal;
  }

  /// Get pending appeals count.
  int get pendingAppeals =>
      _appealQueue.where((a) => a.status == 'pending').length;

  /// Get moderation stats for dashboard.
  Map<String, dynamic> get stats {
    final total = _decisionLog.length;
    final approved = _decisionLog
        .where((d) => d.action == ModerationAction.approve)
        .length;
    final flagged = _decisionLog
        .where((d) => d.action == ModerationAction.flag)
        .length;
    final removed = _decisionLog
        .where((d) => d.action == ModerationAction.remove)
        .length;

    return {
      'totalReviewed': total,
      'approved': approved,
      'flagged': flagged,
      'removed': removed,
      'approvalRate': total > 0 ? (approved / total * 100) : 100.0,
      'pendingAppeals': pendingAppeals,
    };
  }

  // ─── Detectors ────────────────────────────────────────────────────────

  String _sanitizeCombatTerms(String text) {
    var sanitized = text;
    for (final term in _combatAllowlist) {
      sanitized = sanitized.replaceAll(term, '');
    }
    return sanitized;
  }

  void _detectHateSpeech(String text, List<ToxicitySignal> signals) {
    for (final pattern in _hatePatterns) {
      if (text.contains(pattern)) {
        signals.add(
          ToxicitySignal(
            category: ToxicityCategory.hateSpeed,
            confidence: 0.9,
            evidence: 'Matched hate speech pattern: "$pattern"',
            triggeredAutoAction: true,
          ),
        );
        return;
      }
    }
  }

  void _detectHarassment(String text, List<ToxicitySignal> signals) {
    for (final pattern in _harassmentPatterns) {
      if (text.contains(pattern)) {
        signals.add(
          ToxicitySignal(
            category: ToxicityCategory.harassment,
            confidence: 0.85,
            evidence: 'Matched harassment pattern: "$pattern"',
            triggeredAutoAction: true,
          ),
        );
        return;
      }
    }
  }

  void _detectThreats(String text, List<ToxicitySignal> signals) {
    for (final pattern in _threatPatterns) {
      if (text.contains(pattern)) {
        signals.add(
          ToxicitySignal(
            category: ToxicityCategory.threat,
            confidence: 0.88,
            evidence: 'Matched threat pattern: "$pattern"',
            triggeredAutoAction: true,
          ),
        );
        return;
      }
    }
  }

  void _detectSpam(
    String text,
    ContentToModerate content,
    List<ToxicitySignal> signals,
  ) {
    int spamScore = 0;
    final matchedIndicators = <String>[];

    for (final indicator in _spamIndicators) {
      if (text.contains(indicator)) {
        spamScore++;
        matchedIndicators.add(indicator);
      }
    }

    // Excessive links
    if (content.links.length > 3) {
      spamScore += 2;
      matchedIndicators.add('excessive links (${content.links.length})');
    }

    // ALL CAPS detection
    final upperRatio = text.isEmpty
        ? 0.0
        : text.runes
                  .where(
                    (r) =>
                        String.fromCharCode(r).toUpperCase() ==
                            String.fromCharCode(r) &&
                        String.fromCharCode(r).toLowerCase() !=
                            String.fromCharCode(r),
                  )
                  .length /
              text.length;
    if (upperRatio > 0.6 && text.length > 20) {
      spamScore++;
      matchedIndicators.add('excessive caps');
    }

    // Excessive emoji
    final emojiPattern = RegExp(
      r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2702}-\u{27B0}\u{FE00}-\u{FE0F}\u{1F900}-\u{1F9FF}]',
      unicode: true,
    );
    final emojiCount = emojiPattern.allMatches(text).length;
    if (emojiCount > 10) {
      spamScore++;
      matchedIndicators.add('emoji flood ($emojiCount)');
    }

    if (spamScore >= 2) {
      signals.add(
        ToxicitySignal(
          category: ToxicityCategory.spam,
          confidence: (spamScore / 5).clamp(0.5, 1.0),
          evidence: 'Spam indicators: ${matchedIndicators.join(", ")}',
          triggeredAutoAction: spamScore >= 3,
        ),
      );
    }
  }

  void _detectRageBait(String text, List<ToxicitySignal> signals) {
    int rageBaitScore = 0;
    for (final indicator in _rageBaitIndicators) {
      if (text.contains(indicator)) rageBaitScore++;
    }
    if (rageBaitScore >= 1) {
      signals.add(
        ToxicitySignal(
          category: ToxicityCategory.rageBait,
          confidence: (rageBaitScore * 0.3).clamp(0.3, 0.9),
          evidence: 'Rage bait language detected ($rageBaitScore indicators)',
        ),
      );
    }
  }

  void _detectMisinformation(
    String text,
    ContentToModerate content,
    List<ToxicitySignal> signals,
  ) {
    // Sensationalist claim patterns
    final sensationalist = [
      'breaking:',
      'confirmed:',
      'sources say',
      'insider report',
      '100% true',
      'guaranteed',
    ];

    int misInfoScore = 0;
    for (final pattern in sensationalist) {
      if (text.contains(pattern)) misInfoScore++;
    }

    // Unverified author making bold claims
    if (misInfoScore > 0 && content.authorTrustScore < 50) {
      signals.add(
        ToxicitySignal(
          category: ToxicityCategory.misinformation,
          confidence: (misInfoScore * 0.25).clamp(0.3, 0.8),
          evidence:
              'Unverified author with sensationalist language ($misInfoScore patterns)',
        ),
      );
    }
  }

  void _detectSelfHarm(String text, List<ToxicitySignal> signals) {
    final selfHarmPatterns = [
      'want to die',
      'end it all',
      'not worth living',
      'cut myself',
    ];
    for (final pattern in selfHarmPatterns) {
      if (text.contains(pattern)) {
        signals.add(
          const ToxicitySignal(
            category: ToxicityCategory.selfHarm,
            confidence: 0.85,
            evidence: 'Self-harm language detected — escalate to safety team',
            triggeredAutoAction: true,
          ),
        );
        return;
      }
    }
  }

  // ─── Decision Logic ───────────────────────────────────────────────────

  ModerationAction _determineAction(
    List<ToxicitySignal> signals,
    double safetyScore,
    ContentTrustLevel trustLevel,
  ) {
    // Any auto-action signal → remove or escalate
    final autoActions = signals.where((s) => s.triggeredAutoAction);
    if (autoActions.isNotEmpty) {
      final hasSelfHarm = autoActions.any(
        (s) => s.category == ToxicityCategory.selfHarm,
      );
      if (hasSelfHarm) return ModerationAction.escalate;

      final hasSevere = autoActions.any(
        (s) =>
            s.category == ToxicityCategory.hateSpeed ||
            s.category == ToxicityCategory.threat,
      );
      if (hasSevere) return ModerationAction.remove;

      return ModerationAction.restrict;
    }

    // Score-based decisions
    if (safetyScore >= 80) return ModerationAction.approve;
    if (safetyScore >= 60) {
      return trustLevel == ContentTrustLevel.trusted
          ? ModerationAction.approve
          : ModerationAction.flag;
    }
    if (safetyScore >= 40) return ModerationAction.flag;
    if (safetyScore >= 20) return ModerationAction.restrict;
    return ModerationAction.remove;
  }

  String _generateReasoning(
    ModerationAction action,
    List<ToxicitySignal> signals,
    double safetyScore,
  ) {
    if (signals.isEmpty) {
      return 'Content passed all safety checks (score: ${safetyScore.toStringAsFixed(1)}).';
    }

    final categories = signals.map((s) => s.category.label).toSet().join(', ');
    switch (action) {
      case ModerationAction.approve:
        return 'Low-confidence signals detected ($categories) but content approved based on overall safety score.';
      case ModerationAction.flag:
        return 'Content flagged for review: $categories. Safety score: ${safetyScore.toStringAsFixed(1)}.';
      case ModerationAction.restrict:
        return 'Content restricted due to: $categories. Only visible to author pending review.';
      case ModerationAction.remove:
        return 'Content removed for violating community guidelines: $categories.';
      case ModerationAction.escalate:
        return 'Content escalated to trust & safety team: $categories. Immediate attention required.';
      case ModerationAction.warn:
        return 'Warning issued for borderline content: $categories.';
    }
  }
}
