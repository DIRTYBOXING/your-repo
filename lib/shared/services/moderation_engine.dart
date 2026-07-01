import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/content_policy.dart';
import '../models/media_asset_model.dart';
import '../models/moderation_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC MODERATION ENGINE — Unified 3-layer pipeline
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Layer 1: RULES (instant, client-side)
///   → Banned words, regex patterns, spam detection, length limits
///   → Result: pass / auto-reject
///
/// Layer 2: AI (async, Cloud Functions or local heuristics)
///   → Toxicity scoring, defamation detection, athlete protection
///   → Result: approve / flag-for-review / auto-reject
///
/// Layer 3: HUMAN (admin dashboard queue)
///   → Flagged content awaiting manual review
///   → Result: approve / reject with reason
///
/// Usage:
///   final engine = ModerationEngine();
///   final result = await engine.moderate(content: text, userId: uid, type: ModerationType.post);
///   if (result.blocked) { /* reject */ }
///   if (result.flagged) { /* queued for human review */ }
///   if (result.approved) { /* publish */ }

enum ModerationDecision { approved, flagged, rejected }

enum RejectionCategory {
  bannedContent,
  spam,
  toxicity,
  defamation,
  matchFixing,
  scam,
  harassment,
  explicitContent,
  platformViolation,
  manual,
}

/// The result of running content through the moderation pipeline.
class ModerationResult {
  final ModerationDecision decision;
  final RejectionCategory? category;
  final String? reason;
  final double toxicityScore;
  final double confidenceScore;
  final List<String> flaggedTerms;
  final String layer; // 'rules', 'ai', 'human'

  const ModerationResult({
    required this.decision,
    this.category,
    this.reason,
    this.toxicityScore = 0.0,
    this.confidenceScore = 1.0,
    this.flaggedTerms = const [],
    this.layer = 'rules',
  });

  bool get approved => decision == ModerationDecision.approved;
  bool get flagged => decision == ModerationDecision.flagged;
  bool get blocked => decision == ModerationDecision.rejected;

  static const clean = ModerationResult(
    decision: ModerationDecision.approved,
  );
}

class ModerationEngine extends ChangeNotifier {
  ModerationEngine({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ─── CONFIG ────────────────────────────────────────────────────────────

  /// Max content length before auto-reject
  static const int maxPostLength = 2000;
  static const int maxCommentLength = 500;
  static const int maxQuestionLength = 500;

  /// Spam thresholds
  static const double _capsThreshold = 0.70;
  static const int _capsMinLength = 20;
  static const int _repeatedCharThreshold = 5;
  static const int _maxEmojiCount = 10;

  /// Toxicity score thresholds
  static const double _autoRejectThreshold = 0.85;
  static const double _flagForReviewThreshold = 0.45;

  /// Whitelisted domains for URL checking
  static const _whitelistedDomains = [
    'youtube.com',
    'youtu.be',
    'instagram.com',
    'twitter.com',
    'x.com',
    'facebook.com',
    'bkfc.com',
    'watch.bkfc.com',
    'ufc.com',
    'datafightcentral.com',
  ];

  // ─── LAYER 1: RULES ───────────────────────────────────────────────────

  /// Synchronous rule-based check. Instant, no network calls.
  ModerationResult checkRules(String content, ModerationType type) {
    if (content.trim().isEmpty) {
      return const ModerationResult(
        decision: ModerationDecision.rejected,
        category: RejectionCategory.platformViolation,
        reason: 'Content cannot be empty',
      );
    }

    // Length check
    final maxLen = type == ModerationType.post
        ? maxPostLength
        : maxCommentLength;
    if (content.length > maxLen) {
      return ModerationResult(
        decision: ModerationDecision.rejected,
        category: RejectionCategory.platformViolation,
        reason: 'Content exceeds $maxLen character limit',
      );
    }

    // Banned keywords (ContentPolicy.flaggedKeywordPatterns)
    final flagged = _checkBannedKeywords(content);
    if (flagged.isNotEmpty) {
      return ModerationResult(
        decision: ModerationDecision.rejected,
        category: RejectionCategory.bannedContent,
        reason: 'Contains prohibited content',
        flaggedTerms: flagged,
      );
    }

    // Spam detection
    final spamResult = _checkSpam(content);
    if (spamResult != null) return spamResult;

    // URL check — block non-whitelisted domains
    final urlResult = _checkUrls(content);
    if (urlResult != null) return urlResult;

    return ModerationResult.clean;
  }

  List<String> _checkBannedKeywords(String content) {
    final lower = content.toLowerCase();
    final flagged = <String>[];
    for (final keyword in ContentPolicy.flaggedKeywordPatterns) {
      if (lower.contains(keyword.toLowerCase())) {
        flagged.add(keyword);
      }
    }
    return flagged;
  }

  ModerationResult? _checkSpam(String content) {
    // Excessive caps
    if (content.length > _capsMinLength) {
      final upperCount = content.runes.where((r) {
        final c = String.fromCharCode(r);
        return c == c.toUpperCase() && c != c.toLowerCase();
      }).length;
      if (upperCount / content.length > _capsThreshold) {
        return const ModerationResult(
          decision: ModerationDecision.rejected,
          category: RejectionCategory.spam,
          reason: 'Excessive use of capital letters',
        );
      }
    }

    // Repeated characters (aaaaaaa)
    final repeatedPattern = RegExp(
      r'(.)\1{'
      '${_repeatedCharThreshold - 1}'
      r',}',
    );
    if (repeatedPattern.hasMatch(content)) {
      return const ModerationResult(
        decision: ModerationDecision.rejected,
        category: RejectionCategory.spam,
        reason: 'Content contains repeated characters (possible spam)',
      );
    }

    // Excessive emojis
    final emojiPattern = RegExp(
      r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}'
      r'\u{1F1E0}-\u{1F1FF}\u{2702}-\u{27B0}\u{FE00}-\u{FE0F}'
      r'\u{1F900}-\u{1F9FF}\u{200D}\u{20E3}]',
      unicode: true,
    );
    if (emojiPattern.allMatches(content).length > _maxEmojiCount) {
      return const ModerationResult(
        decision: ModerationDecision.rejected,
        category: RejectionCategory.spam,
        reason: 'Too many emojis',
      );
    }

    return null;
  }

  ModerationResult? _checkUrls(String content) {
    final urlPattern = RegExp(r'https?://([^\s/]+)');
    final matches = urlPattern.allMatches(content);
    for (final match in matches) {
      final domain = match.group(1)?.toLowerCase() ?? '';
      final isWhitelisted = _whitelistedDomains.any(
        (d) => domain == d || domain.endsWith('.$d'),
      );
      if (!isWhitelisted) {
        return ModerationResult(
          decision: ModerationDecision.flagged,
          category: RejectionCategory.spam,
          reason: 'Contains non-whitelisted URL: $domain',
          flaggedTerms: [domain],
        );
      }
    }
    return null;
  }

  // ─── LAYER 2: AI / HEURISTIC SCORING ──────────────────────────────────

  /// Async heuristic-based toxicity + category scoring.
  /// Uses local pattern detection (no Cloud Function dependency).
  Future<ModerationResult> scoreContent(String content) async {
    final lower = content.toLowerCase();
    double toxicity = 0.0;
    RejectionCategory? detectedCategory;
    String? detectedReason;
    final flagged = <String>[];

    // Toxicity keywords (weighted)
    const toxicKeywords = {
      'kill yourself': 1.0,
      'kys': 1.0,
      'go die': 0.95,
      'kill you': 0.95,
      'threat': 0.7,
      'doxx': 0.9,
      'your address': 0.8,
      'stalk': 0.85,
      'swat': 0.95,
      'hate': 0.4,
      'die': 0.35,
      'idiot': 0.25,
      'stupid': 0.2,
      'loser': 0.2,
      'trash': 0.25,
      'garbage': 0.2,
      'pathetic': 0.25,
      'worthless': 0.3,
    };

    for (final entry in toxicKeywords.entries) {
      if (lower.contains(entry.key)) {
        toxicity = toxicity < entry.value ? entry.value : toxicity;
        flagged.add(entry.key);
      }
    }

    if (toxicity >= 0.7) {
      detectedCategory = RejectionCategory.harassment;
      detectedReason = 'Harassment / threat detected';
    }

    // Defamation patterns (athlete protection)
    const defamationKeywords = [
      'fraud',
      'cheat',
      'rigged',
      'fixed fight',
      'took a dive',
      'juicing',
      'on steroids',
      'fake record',
      'padded record',
      'ducking',
      'can crusher',
    ];
    for (final kw in defamationKeywords) {
      if (lower.contains(kw)) {
        toxicity = toxicity < 0.6 ? 0.6 : toxicity;
        detectedCategory = RejectionCategory.defamation;
        detectedReason = 'Potential defamation detected';
        flagged.add(kw);
      }
    }

    // Match fixing patterns
    const matchFixingKeywords = [
      'fix the fight',
      'throw the fight',
      'take a dive',
      'insider tip',
      'guaranteed win',
      'fixed outcome',
    ];
    for (final kw in matchFixingKeywords) {
      if (lower.contains(kw)) {
        toxicity = toxicity < 0.8 ? 0.8 : toxicity;
        detectedCategory = RejectionCategory.matchFixing;
        detectedReason = 'Match fixing language detected';
        flagged.add(kw);
      }
    }

    // Scam patterns
    const scamKeywords = [
      'free money',
      'guaranteed return',
      'send crypto',
      'wire transfer',
      'investment opportunity',
      'dm me for',
      'click this link',
      'verify your account',
    ];
    for (final kw in scamKeywords) {
      if (lower.contains(kw)) {
        toxicity = toxicity < 0.65 ? 0.65 : toxicity;
        detectedCategory = RejectionCategory.scam;
        detectedReason = 'Scam language detected';
        flagged.add(kw);
      }
    }

    // Decision based on thresholds
    if (toxicity >= _autoRejectThreshold) {
      return ModerationResult(
        decision: ModerationDecision.rejected,
        category: detectedCategory ?? RejectionCategory.toxicity,
        reason: detectedReason ?? 'Toxicity score too high',
        toxicityScore: toxicity,
        confidenceScore: toxicity,
        flaggedTerms: flagged,
        layer: 'ai',
      );
    }

    if (toxicity >= _flagForReviewThreshold) {
      return ModerationResult(
        decision: ModerationDecision.flagged,
        category: detectedCategory ?? RejectionCategory.toxicity,
        reason: detectedReason ?? 'Content flagged for review',
        toxicityScore: toxicity,
        confidenceScore: toxicity,
        flaggedTerms: flagged,
        layer: 'ai',
      );
    }

    return ModerationResult(
      decision: ModerationDecision.approved,
      toxicityScore: toxicity,
      confidenceScore: 1.0 - toxicity,
      layer: 'ai',
    );
  }

  // ─── FULL PIPELINE ────────────────────────────────────────────────────

  /// Run content through the full 3-layer pipeline.
  /// Returns immediately for rule violations, queues for human review if flagged.
  Future<ModerationResult> moderate({
    required String content,
    required String userId,
    required ModerationType type,
    String? targetId,
  }) async {
    // Layer 1: Rules
    final rulesResult = checkRules(content, type);
    if (rulesResult.blocked) {
      await _logModerationAction(
        content: content,
        userId: userId,
        type: type,
        targetId: targetId,
        result: rulesResult,
      );
      return rulesResult;
    }

    // Layer 2: AI scoring
    final aiResult = await scoreContent(content);
    if (aiResult.blocked) {
      await _logModerationAction(
        content: content,
        userId: userId,
        type: type,
        targetId: targetId,
        result: aiResult,
      );
      return aiResult;
    }

    // Layer 2.5: Flagged → queue for human review (Layer 3)
    if (aiResult.flagged || rulesResult.flagged) {
      final flagResult = aiResult.flagged ? aiResult : rulesResult;
      await _queueForHumanReview(
        content: content,
        userId: userId,
        type: type,
        targetId: targetId,
        result: flagResult,
      );
      return flagResult;
    }

    // All clear
    return ModerationResult(
      decision: ModerationDecision.approved,
      toxicityScore: aiResult.toxicityScore,
      confidenceScore: aiResult.confidenceScore,
      layer: 'ai',
    );
  }

  // ─── LAYER 3: HUMAN REVIEW QUEUE ──────────────────────────────────────

  /// Stream pending items for the moderation dashboard.
  Stream<List<ModerationModel>> streamQueue({ModerationStatus? status}) {
    Query query = _firestore.collection('moderation');
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().map(
      (snap) =>
          snap.docs.map(ModerationModel.fromFirestore).toList(),
    );
  }

  /// Approve a queued item.
  Future<void> approve(String itemId, String moderatorId) async {
    await _firestore.collection('moderation').doc(itemId).update({
      'status': ModerationStatus.approved.name,
      'moderatedBy': moderatorId,
      'moderatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reject a queued item.
  Future<void> reject(String itemId, String moderatorId, String reason) async {
    await _firestore.collection('moderation').doc(itemId).update({
      'status': ModerationStatus.rejected.name,
      'moderatedBy': moderatorId,
      'moderatedAt': FieldValue.serverTimestamp(),
      'rejectionReason': reason,
    });
  }

  /// Get queue counts for dashboard stats.
  Future<Map<String, int>> getQueueStats() async {
    final snap = await _firestore.collection('moderation').get();
    int pending = 0, approved = 0, rejected = 0;
    for (final doc in snap.docs) {
      final status = doc.data()['status'] as String?;
      switch (status) {
        case 'pending':
          pending++;
          break;
        case 'approved':
          approved++;
          break;
        case 'rejected':
          rejected++;
          break;
      }
    }
    return {'pending': pending, 'approved': approved, 'rejected': rejected};
  }

  /// Stream media assets awaiting human review.
  Stream<List<MediaAssetModel>> streamMediaQueue() {
    return _firestore
        .collection('media_assets')
        .where(
          'approvalStatus',
          isEqualTo: MediaApprovalStatus.pendingReview.name,
        )
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(MediaAssetModel.fromFirestore)
              .toList(),
        );
  }

  Future<void> approveMediaAsset(String assetId, String moderatorId) async {
    await _firestore.collection('media_assets').doc(assetId).update({
      'approvalStatus': MediaApprovalStatus.approved.name,
      'safetyStatus': MediaSafetyStatus.cleared.name,
      'approved': true,
      'approvedBy': moderatorId,
      'approvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _firestore.collection('media_audit_logs').add({
      'assetId': assetId,
      'action': 'approved',
      'moderatorId': moderatorId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectMediaAsset(
    String assetId,
    String moderatorId,
    String reason,
  ) async {
    await _firestore.collection('media_assets').doc(assetId).update({
      'approvalStatus': MediaApprovalStatus.rejected.name,
      'safetyStatus': MediaSafetyStatus.blocked.name,
      'approved': false,
      'approvedBy': moderatorId,
      'approvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'rejectionReason': reason,
    });
    await _firestore.collection('media_audit_logs').add({
      'assetId': assetId,
      'action': 'rejected',
      'moderatorId': moderatorId,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> quarantineMediaAsset(
    String assetId,
    String moderatorId,
    String reason,
  ) async {
    await _firestore.collection('media_assets').doc(assetId).update({
      'approvalStatus': MediaApprovalStatus.quarantined.name,
      'safetyStatus': MediaSafetyStatus.flagged.name,
      'approved': false,
      'approvedBy': moderatorId,
      'approvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'quarantineReason': reason,
    });
    await _firestore.collection('media_audit_logs').add({
      'assetId': assetId,
      'action': 'quarantined',
      'moderatorId': moderatorId,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, int>> getMediaQueueStats() async {
    final snap = await _firestore.collection('media_assets').get();
    var pending = 0;
    var approved = 0;
    var rejected = 0;
    for (final doc in snap.docs) {
      final status = doc.data()['approvalStatus'] as String?;
      switch (status) {
        case 'approved':
          approved++;
          break;
        case 'rejected':
        case 'quarantined':
          rejected++;
          break;
        case 'pendingReview':
        default:
          pending++;
          break;
      }
    }
    return {
      'mediaPending': pending,
      'mediaApproved': approved,
      'mediaRejected': rejected,
    };
  }

  // ─── PRIVATE: LOGGING + QUEUING ───────────────────────────────────────

  Future<void> _logModerationAction({
    required String content,
    required String userId,
    required ModerationType type,
    String? targetId,
    required ModerationResult result,
  }) async {
    try {
      await _firestore.collection('moderation_logs').add({
        'content': content.length > 200
            ? '${content.substring(0, 200)}...'
            : content,
        'userId': userId,
        'type': type.name,
        'targetId': targetId,
        'decision': result.decision.name,
        'category': result.category?.name,
        'reason': result.reason,
        'toxicityScore': result.toxicityScore,
        'layer': result.layer,
        'flaggedTerms': result.flaggedTerms,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('ModerationEngine: Failed to log action: $e');
    }
  }

  Future<void> _queueForHumanReview({
    required String content,
    required String userId,
    required ModerationType type,
    String? targetId,
    required ModerationResult result,
  }) async {
    try {
      final item = ModerationModel(
        id: '', // Firestore will assign
        type: type,
        content: content,
        userId: userId,
        targetId: targetId,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('moderation').add(item.toFirestore());
    } catch (e) {
      debugPrint('ModerationEngine: Failed to queue for review: $e');
    }
  }

  // ─── DEMO DATA (for offline/demo mode) ─────────────────────────────

  static List<ModerationModel> get demoQueue => [
    ModerationModel(
      id: 'mod_1',
      type: ModerationType.comment,
      content: 'This fighter is trash, absolute garbage performance',
      userId: 'fan_001',
      targetId: 'post_123',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ModerationModel(
      id: 'mod_2',
      type: ModerationType.question,
      content: 'Hey Hepi, any insider tips on who wins the main event?',
      userId: 'fan_002',
      targetId: 'haze_hepi',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    ModerationModel(
      id: 'mod_3',
      type: ModerationType.post,
      content:
          'Check out this amazing deal at http://sketchy-site.com/free-money',
      userId: 'fan_003',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    ModerationModel(
      id: 'mod_4',
      type: ModerationType.comment,
      content: 'This fight was obviously rigged, everyone knows he took a dive',
      userId: 'fan_004',
      targetId: 'post_456',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ModerationModel(
      id: 'mod_5',
      type: ModerationType.question,
      content:
          'Sam, do you think supplements help? What do you recommend for recovery?',
      userId: 'fan_005',
      targetId: 'sam_soliman',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    ),
  ];
}
