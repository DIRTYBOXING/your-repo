import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// 🥷 NINJA MODERATION SERVICE — Invisible But Powerful
/// ═══════════════════════════════════════════════════════════════════════════
///
/// The Ninja protects the DFC ecosystem from:
/// • Toxicity and harassment
/// • Spam and bot accounts
/// • Fake profiles
/// • Abuse and bullying
/// • Inappropriate content
///
/// Actions (escalating severity):
/// 1. Auto-hide (shadow mute) — post invisible to others, visible to author
/// 2. Warning — notify user of violation
/// 3. Temporary mute — 24h-7d posting restriction
/// 4. Post removal — content deleted
/// 5. Temporary ban — 7d-30d account suspension
/// 6. Permanent ban — account terminated
///
/// Philosophy: "The Ninja protects the ecosystem."
/// Users see minimal friction, toxicity disappears quietly.
/// ═══════════════════════════════════════════════════════════════════════════
class NinjaModerationService {
  final FirebaseFirestore _firestore;

  NinjaModerationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // TOXICITY DETECTION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check content for toxicity (basic keyword detection)
  /// In production: Use ML API like Perspective API or AWS Comprehend
  Future<ContentModerationResult> analyzeContent({
    required String content,
    required String authorId,
  }) async {
    final contentLower = content.toLowerCase();

    // Check author's violation history
    final authorHistory = await _getUserViolationHistory(authorId);
    final trustScore = _calculateTrustScore(authorHistory);

    // Detect spam patterns
    if (_isSpam(content)) {
      return ContentModerationResult(
        action: ModerationAction.shadowMute,
        reason: 'Spam detected',
        severity: 0.8,
        trustScore: trustScore,
      );
    }

    // Detect toxic keywords (simplified — use ML in production)
    final toxicKeywords = [
      'hate',
      'kill',
      'die',
      'stupid',
      'idiot',
      'loser',
      'trash',
      'garbage',
      'pathetic',
      'worthless',
    ];

    int toxicCount = 0;
    for (final keyword in toxicKeywords) {
      if (contentLower.contains(keyword)) {
        toxicCount++;
      }
    }

    if (toxicCount >= 3) {
      return ContentModerationResult(
        action: ModerationAction.remove,
        reason: 'Toxic language detected',
        severity: 0.9,
        trustScore: trustScore,
      );
    } else if (toxicCount >= 1) {
      return ContentModerationResult(
        action: ModerationAction.warn,
        reason: 'Potentially toxic language',
        severity: 0.5,
        trustScore: trustScore,
      );
    }

    // Content passes moderation
    return ContentModerationResult(
      action: ModerationAction.allow,
      reason: 'Content approved',
      severity: 0.0,
      trustScore: trustScore,
    );
  }

  /// Detect spam patterns
  bool _isSpam(String content) {
    // Check for excessive caps
    final capsRatio =
        content
            .split('')
            .where((c) => c == c.toUpperCase() && c != c.toLowerCase())
            .length /
        content.length;
    if (capsRatio > 0.7 && content.length > 20) return true;

    // Check for repeated characters
    if (RegExp(r'(.)\1{4,}').hasMatch(content)) return true;

    // Check for excessive emojis
    final emojiCount = RegExp(
      r'[\u{1F600}-\u{1F64F}]',
      unicode: true,
    ).allMatches(content).length;
    if (emojiCount > 10) return true;

    // Check for URLs (potential phishing)
    if (RegExp(r'https?://|www\.').hasMatch(content.toLowerCase())) {
      // Allow known whitelisted domains
      final whitelist = [
        'youtube.com',
        'instagram.com',
        'twitter.com',
        'facebook.com',
      ];
      final hasWhitelistedDomain = whitelist.any(
        (domain) => content.toLowerCase().contains(domain),
      );
      if (!hasWhitelistedDomain) return true;
    }

    return false;
  }

  /// Get user's violation history
  Future<List<Map<String, dynamic>>> _getUserViolationHistory(
    String userId,
  ) async {
    final snapshot = await _firestore
        .collection('moderation_violations')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Calculate user trust score (0.0 - 1.0)
  /// Lower score = more violations
  double _calculateTrustScore(List<Map<String, dynamic>> violations) {
    if (violations.isEmpty) return 1.0;

    // Recent violations count more
    final now = DateTime.now();
    double penaltyScore = 0.0;

    for (final violation in violations) {
      final timestamp = (violation['timestamp'] as Timestamp).toDate();
      final daysSince = now.difference(timestamp).inDays;

      // Decay penalty over time (violations older than 90 days ignored)
      if (daysSince > 90) continue;

      final severity = violation['severity'] as double? ?? 0.5;
      final timeDecay = 1.0 - (daysSince / 90.0);
      penaltyScore += severity * timeDecay;
    }

    // Convert penalty to trust score
    final trustScore = (1.0 - (penaltyScore / 10.0)).clamp(0.0, 1.0);
    return trustScore;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MODERATION ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Shadow mute a post (invisible to others, visible to author)
  Future<void> shadowMutePost(String postId, String reason) async {
    await _firestore.collection('posts').doc(postId).update({
      'shadowMuted': true,
      'moderationReason': reason,
      'moderatedAt': FieldValue.serverTimestamp(),
    });

    if (kDebugMode) {
      debugPrint('🥷 Ninja: Shadow muted post $postId — $reason');
    }
  }

  /// Warn user about content violation
  Future<void> warnUser({
    required String userId,
    required String postId,
    required String reason,
  }) async {
    await _firestore.collection('moderation_warnings').add({
      'userId': userId,
      'postId': postId,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
      'acknowledged': false,
    });

    // Create notification for user
    await _firestore.collection('notifications').add({
      'userId': userId,
      'type': 'moderation_warning',
      'title': 'Content Warning',
      'message': 'The Ninja has detected a potential issue: $reason',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    if (kDebugMode) {
      debugPrint('🥷 Ninja: Warned user $userId — $reason');
    }
  }

  /// Remove a post
  Future<void> removePost(String postId, String reason) async {
    await _firestore.collection('posts').doc(postId).update({
      'removed': true,
      'moderationReason': reason,
      'moderatedAt': FieldValue.serverTimestamp(),
    });

    if (kDebugMode) {
      debugPrint('🥷 Ninja: Removed post $postId — $reason');
    }
  }

  /// Temporarily mute a user (restrict posting)
  Future<void> muteUser({
    required String userId,
    required int durationDays,
    required String reason,
  }) async {
    final muteUntil = DateTime.now().add(Duration(days: durationDays));

    await _firestore.collection('users').doc(userId).update({
      'muted': true,
      'muteUntil': Timestamp.fromDate(muteUntil),
      'muteReason': reason,
    });

    // Log violation
    await _logViolation(
      userId: userId,
      action: 'mute',
      reason: reason,
      severity: 0.7,
      durationDays: durationDays,
    );

    if (kDebugMode) {
      debugPrint('🥷 Ninja: Muted user $userId for $durationDays days — $reason');
    }
  }

  /// Temporarily ban a user (account suspension)
  Future<void> banUser({
    required String userId,
    required int durationDays,
    required String reason,
  }) async {
    final banUntil = DateTime.now().add(Duration(days: durationDays));

    await _firestore.collection('users').doc(userId).update({
      'banned': true,
      'banUntil': Timestamp.fromDate(banUntil),
      'banReason': reason,
    });

    // Log violation
    await _logViolation(
      userId: userId,
      action: 'ban',
      reason: reason,
      severity: 0.9,
      durationDays: durationDays,
    );

    if (kDebugMode) {
      debugPrint('🥷 Ninja: Banned user $userId for $durationDays days — $reason');
    }
  }

  /// Permanently ban a user
  Future<void> permanentBan({
    required String userId,
    required String reason,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'banned': true,
      'permanentBan': true,
      'banReason': reason,
      'bannedAt': FieldValue.serverTimestamp(),
    });

    // Log violation
    await _logViolation(
      userId: userId,
      action: 'permanent_ban',
      reason: reason,
      severity: 1.0,
    );

    if (kDebugMode) {
      debugPrint('🥷 Ninja: PERMANENT BAN for user $userId — $reason');
    }
  }

  /// Log moderation violation
  Future<void> _logViolation({
    required String userId,
    required String action,
    required String reason,
    required double severity,
    int? durationDays,
  }) async {
    await _firestore.collection('moderation_violations').add({
      'userId': userId,
      'action': action,
      'reason': reason,
      'severity': severity,
      'durationDays': durationDays,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USER REPORTING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Report a post or user
  Future<void> reportContent({
    required String reporterId,
    required String contentId,
    required ReportType type,
    required String reason,
    String? details,
  }) async {
    await _firestore.collection('reports').add({
      'reporterId': reporterId,
      'contentId': contentId,
      'type': type.name,
      'reason': reason,
      'details': details,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Auto-trigger review if multiple reports on same content
    final reportCount = await _getReportCount(contentId);
    if (reportCount >= 3) {
      await _triggerAutoReview(contentId);
    }
  }

  Future<int> _getReportCount(String contentId) async {
    final snapshot = await _firestore
        .collection('reports')
        .where('contentId', isEqualTo: contentId)
        .where('status', isEqualTo: 'pending')
        .get();
    return snapshot.docs.length;
  }

  Future<void> _triggerAutoReview(String contentId) async {
    // Flag for manual review by moderation team
    await _firestore.collection('moderation_queue').add({
      'contentId': contentId,
      'priority': 'high',
      'reason': 'Multiple user reports',
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (kDebugMode) {
      debugPrint(
        '🥷 Ninja: Flagged $contentId for manual review (multiple reports)',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHECK USER STATUS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if user is currently muted or banned
  Future<UserModerationStatus> getUserStatus(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return UserModerationStatus(
        isMuted: false,
        isBanned: false,
        trustScore: 1.0,
      );
    }

    final data = userDoc.data()!;
    final now = DateTime.now();

    // Check mute status
    bool isMuted = data['muted'] as bool? ?? false;
    if (isMuted && data['muteUntil'] != null) {
      final muteUntil = (data['muteUntil'] as Timestamp).toDate();
      if (now.isAfter(muteUntil)) {
        isMuted = false;
        // Clear expired mute
        await _firestore.collection('users').doc(userId).update({
          'muted': false,
          'muteUntil': FieldValue.delete(),
        });
      }
    }

    // Check ban status
    bool isBanned = data['banned'] as bool? ?? false;
    final permanentBan = data['permanentBan'] as bool? ?? false;
    if (isBanned && !permanentBan && data['banUntil'] != null) {
      final banUntil = (data['banUntil'] as Timestamp).toDate();
      if (now.isAfter(banUntil)) {
        isBanned = false;
        // Clear expired ban
        await _firestore.collection('users').doc(userId).update({
          'banned': false,
          'banUntil': FieldValue.delete(),
        });
      }
    }

    // Calculate trust score
    final violations = await _getUserViolationHistory(userId);
    final trustScore = _calculateTrustScore(violations);

    return UserModerationStatus(
      isMuted: isMuted,
      isBanned: isBanned,
      isPermanentBan: permanentBan,
      trustScore: trustScore,
      muteReason: data['muteReason'] as String?,
      banReason: data['banReason'] as String?,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

class ContentModerationResult {
  final ModerationAction action;
  final String reason;
  final double severity; // 0.0 - 1.0
  final double trustScore; // 0.0 - 1.0

  ContentModerationResult({
    required this.action,
    required this.reason,
    required this.severity,
    required this.trustScore,
  });

  bool get shouldBlock => action != ModerationAction.allow;
}

enum ModerationAction {
  allow, // Content passes
  warn, // Warning to user
  shadowMute, // Auto-hide post
  remove, // Delete post
  mute, // Restrict posting
  ban, // Suspend account
}

enum ReportType { post, comment, user, message }

class UserModerationStatus {
  final bool isMuted;
  final bool isBanned;
  final bool isPermanentBan;
  final double trustScore;
  final String? muteReason;
  final String? banReason;

  UserModerationStatus({
    required this.isMuted,
    required this.isBanned,
    this.isPermanentBan = false,
    required this.trustScore,
    this.muteReason,
    this.banReason,
  });

  bool get canPost => !isMuted && !isBanned;
  bool get canInteract => !isBanned;
}
