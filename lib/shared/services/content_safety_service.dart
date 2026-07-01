import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/content_policy.dart';

/// ═══════════════════════════════════════════════════════════════════════
/// DFC Content Safety Service
///
/// Client-side content moderation + Firestore-backed reports & blocks.
/// Keeps the platform clean, family-safe, and sport-focused.
/// ═══════════════════════════════════════════════════════════════════════
class ContentSafetyService extends ChangeNotifier {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static final _functions = FirebaseFunctions.instanceFor(
    region: 'australia-southeast1',
  );

  // ── Local blocked-user cache ──────────────────────────────────────
  final Set<String> _blockedUserIds = {};

  Set<String> get blockedUserIds => Set.unmodifiable(_blockedUserIds);

  // ══════════════════════════════════════════════════════════════════
  //  TEXT SCANNING
  // ══════════════════════════════════════════════════════════════════

  /// Checks user-generated text against flagged keyword patterns.
  /// Returns a [ContentCheckResult] with pass/fail and matched terms.
  ContentCheckResult checkText(String text) {
    if (text.trim().isEmpty) {
      return const ContentCheckResult(passed: true, flaggedTerms: []);
    }

    final lower = text.toLowerCase();
    final matched = <String>[];

    for (final pattern in ContentPolicy.flaggedKeywordPatterns) {
      if (lower.contains(pattern)) {
        matched.add(pattern);
      }
    }

    return ContentCheckResult(passed: matched.isEmpty, flaggedTerms: matched);
  }

  /// Quick boolean check — use for post/comment gates.
  bool isTextClean(String text) => checkText(text).passed;

  /// Content that was voluntarily shared to DFC by the rights holder
  /// (e.g. a promoter sharing a fight poster from Facebook/Instagram)
  /// is lawfully consented for promotional use and skips moderation.
  ContentCheckResult evaluateSharedContent({
    required bool sharedByOwner,
    String text = '',
  }) {
    if (sharedByOwner) {
      // Owner-shared content is promotion-cleared by consent.
      // Still run a minimal text scan so obviously illegal content is caught.
      final result = checkText(text);
      if (!result.passed) {
        return result; // Flag even owner content if it contains illegal terms.
      }
      return const ContentCheckResult(
        passed: true,
        flaggedTerms: [],
        // Caller can check this note to confirm shared-content path.
      );
    }
    return checkText(text);
  }

  /// Gemini-powered AI moderation via Cloud Function.
  /// Returns a structured result with decision, reason, and confidence.
  /// Falls back to the local keyword check if the CF is unavailable.
  Future<AIModerationResult> moderateWithAI(String text) async {
    // Fast local check first — reject obvious violations instantly
    final local = checkText(text);
    if (!local.passed) {
      return AIModerationResult(
        decision: 'reject',
        reason: 'Flagged terms: ${local.flaggedTerms.join(', ')}',
        confidence: 1.0,
      );
    }

    try {
      final callable = _functions.httpsCallable('moderateComment');
      final result = await callable.call<Map<String, dynamic>>({
        'commentText': text,
      });
      final data = result.data;
      return AIModerationResult(
        decision: (data['decision'] as String?) ?? 'approve',
        reason: (data['reason'] as String?) ?? '',
        confidence: (data['confidence'] as num?)?.toDouble() ?? 0.5,
      );
    } catch (e) {
      debugPrint('AI moderation CF error: $e');
      // Fallback: local check passed, so approve
      return const AIModerationResult(
        decision: 'approve',
        reason: 'AI unavailable — local check passed.',
        confidence: 0.5,
      );
    }
  }

  /// Content-only moderation guardrail.
  /// This never judges identity/background and only checks unsafe text patterns.
  ContentCheckResult evaluateContentOnly(String text) => checkText(text);

  // ══════════════════════════════════════════════════════════════════
  //  REPORTING
  // ══════════════════════════════════════════════════════════════════

  /// Report any type of content (post, comment, profile, message).
  Future<void> reportContent({
    required String reporterId,
    required String contentType, // 'post', 'comment', 'profile', 'message'
    required String contentId,
    required String reason,
    String? description,
    String? targetUserId,
  }) async {
    await _firestore.collection('content_reports').add({
      'reporterId': reporterId,
      'contentType': contentType,
      'contentId': contentId,
      'reason': reason,
      'description': description ?? '',
      'targetUserId': targetUserId ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
      'reviewedBy': null,
      'reviewedAt': null,
      'action': null,
    });
  }

  /// Convenience: report a post (matches existing SocialService API).
  Future<void> reportPost(
    String postId,
    String reporterId,
    String reason, {
    String? description,
    String? targetUserId,
  }) {
    return reportContent(
      reporterId: reporterId,
      contentType: 'post',
      contentId: postId,
      reason: reason,
      description: description,
      targetUserId: targetUserId,
    );
  }

  /// Report a user profile.
  Future<void> reportUser({
    required String reporterId,
    required String targetUserId,
    required String reason,
    String? description,
  }) {
    return reportContent(
      reporterId: reporterId,
      contentType: 'profile',
      contentId: targetUserId,
      reason: reason,
      description: description,
      targetUserId: targetUserId,
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  BLOCKING
  // ══════════════════════════════════════════════════════════════════

  /// Load blocked users for a given user from Firestore.
  Future<void> loadBlockedUsers(String userId) async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('blocked_users')
          .get();

      _blockedUserIds.clear();
      for (final doc in snap.docs) {
        _blockedUserIds.add(doc.id);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ContentSafetyService: failed to load blocked users: $e');
    }
  }

  /// Block a user.
  Future<void> blockUser({
    required String currentUserId,
    required String targetUserId,
    String? reason,
  }) async {
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blocked_users')
        .doc(targetUserId)
        .set({
          'blockedAt': FieldValue.serverTimestamp(),
          'reason': reason ?? '',
        });

    _blockedUserIds.add(targetUserId);
    notifyListeners();
  }

  /// Unblock a user.
  Future<void> unblockUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blocked_users')
        .doc(targetUserId)
        .delete();

    _blockedUserIds.remove(targetUserId);
    notifyListeners();
  }

  /// Whether a user is blocked locally.
  bool isBlocked(String userId) => _blockedUserIds.contains(userId);

  // ══════════════════════════════════════════════════════════════════
  //  USER-FACING MUTE (hide from MY feed, no admin action)
  // ══════════════════════════════════════════════════════════════════

  final Set<String> _mutedUserIds = {};

  bool isMuted(String userId) => _mutedUserIds.contains(userId);

  /// Mute a user — their posts are hidden from the current user's feed.
  Future<void> muteUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('muted_users')
        .doc(targetUserId)
        .set({'mutedAt': FieldValue.serverTimestamp()});

    _mutedUserIds.add(targetUserId);
    notifyListeners();
  }

  /// Unmute a user.
  Future<void> unmuteUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('muted_users')
        .doc(targetUserId)
        .delete();

    _mutedUserIds.remove(targetUserId);
    notifyListeners();
  }

  /// Load muted users for the current user.
  Future<void> loadMutedUsers(String userId) async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('muted_users')
          .get();
      _mutedUserIds.clear();
      for (final doc in snap.docs) {
        _mutedUserIds.add(doc.id);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load muted users: $e');
    }
  }

  /// Get detailed list of muted users.
  Future<List<Map<String, dynamic>>> getMutedUsersDetailed(
    String userId,
  ) async {
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('muted_users')
        .orderBy('mutedAt', descending: true)
        .get();
    return snap.docs.map((doc) => {'userId': doc.id, ...doc.data()}).toList();
  }

  /// Get the list of blocked user docs (with metadata).
  Future<List<Map<String, dynamic>>> getBlockedUsersDetailed(
    String userId,
  ) async {
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('blocked_users')
        .orderBy('blockedAt', descending: true)
        .get();

    return snap.docs.map((doc) => {'userId': doc.id, ...doc.data()}).toList();
  }

  // ══════════════════════════════════════════════════════════════════
  //  CONTENT FLAGS (for auto-detected violations)
  // ══════════════════════════════════════════════════════════════════

  /// Auto-flag content detected by client-side or AI scanner.
  Future<void> flagContent({
    required String contentType,
    required String contentId,
    required List<String> matchedTerms,
    String? authorId,
  }) async {
    await _firestore.collection('content_flags').add({
      'contentType': contentType,
      'contentId': contentId,
      'matchedTerms': matchedTerms,
      'authorId': authorId ?? '',
      'flaggedAt': FieldValue.serverTimestamp(),
      'reviewed': false,
    });
  }

  // ══════════════════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════════════════

  /// Returns the list of report reason labels from ContentPolicy.
  List<String> get reportReasons => ContentPolicy.reportReasons;

  /// Returns prohibited categories for display.
  List<String> get prohibitedCategories => ContentPolicy.prohibitedCategories;

  /// Returns inclusive community principles for UI display.
  List<String> get inclusiveCommunityPrinciples =>
      ContentPolicy.inclusiveCommunityPrinciples;
}

/// Result of a text content check.
class ContentCheckResult {
  final bool passed;
  final List<String> flaggedTerms;

  const ContentCheckResult({required this.passed, required this.flaggedTerms});

  @override
  String toString() =>
      'ContentCheckResult(passed: $passed, flagged: $flaggedTerms)';
}

/// Result from AI-powered moderation via Gemini Cloud Function.
class AIModerationResult {
  final String decision; // 'approve' or 'reject'
  final String reason;
  final double confidence; // 0.0 - 1.0

  const AIModerationResult({
    required this.decision,
    required this.reason,
    required this.confidence,
  });

  bool get approved => decision == 'approve';
}
