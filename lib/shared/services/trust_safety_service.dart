import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// TRUST & SAFETY SERVICE — Community Protection System
/// Calculates trust scores, detects toxicity, manages reports
/// ═══════════════════════════════════════════════════════════════════════════

class TrustSafetyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Trust Score Calculation ──────────────────────────────────────────────

  /// Calculate community trust score for a user (0.0 - 1.0)
  Future<double> calculateTrustScore(String userId) async {
    double score = 0.5; // Start at neutral

    try {
      // Get user document
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0.3; // New/unknown user

      final data = userDoc.data()!;

      // Factor 1: Account age (max +0.15)
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null) {
        final daysSinceCreation = DateTime.now().difference(createdAt).inDays;
        score += (daysSinceCreation / 365 * 0.15).clamp(0, 0.15);
      }

      // Factor 2: Training logs (max +0.15)
      final trainingLogCount = await _firestore
          .collection('training_logs')
          .where('userId', isEqualTo: userId)
          .count()
          .get();
      score += (((trainingLogCount.count ?? 0) / 50) * 0.15).clamp(0, 0.15);

      // Factor 3: Positive engagements (max +0.20)
      final postsCount = await _firestore
          .collection('fightwire_posts')
          .where('authorId', isEqualTo: userId)
          .where('isReported', isEqualTo: false)
          .count()
          .get();
      score += (((postsCount.count ?? 0) / 20) * 0.20).clamp(0, 0.20);

      // Factor 4: Event participation (max +0.15)
      final eventParticipation = await _firestore
          .collection('event_participants')
          .where('userId', isEqualTo: userId)
          .count()
          .get();
      score += (((eventParticipation.count ?? 0) / 10) * 0.15).clamp(0, 0.15);

      // Factor 5: Verified status (+0.20)
      if (data['verified'] == true) {
        score += 0.20;
      }

      // Penalty: Report history (subtract up to -0.40)
      final reportCount = data['reportCount'] ?? 0;
      score -= (reportCount * 0.05).clamp(0, 0.40);

      return score.clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('Error calculating trust score: $e');
      return 0.5; // Default on error
    }
  }

  // ─── User Verification ────────────────────────────────────────────────────

  /// Verify user identity
  Future<bool> verifyUser(
    String userId,
    VerificationType type, {
    Map<String, dynamic>? evidence,
  }) async {
    try {
      await _firestore.collection('verification_requests').add({
        'userId': userId,
        'type': type.name,
        'evidence': evidence,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      // In production, this would trigger manual review
      // For now, auto-approve some types
      if (type == VerificationType.email) {
        await _firestore.collection('users').doc(userId).update({
          'verified': true,
          'verifiedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }

      return false; // Pending manual review
    } catch (e) {
      debugPrint('Error verifying user: $e');
      return false;
    }
  }

  // ─── Toxicity Detection ───────────────────────────────────────────────────

  /// Detect toxic content using basic pattern matching
  /// In production, use AI moderation API (Perspective API, OpenAI Moderation)
  bool detectToxicity(String content) {
    final lowerContent = content.toLowerCase();

    // Profanity list (abbreviated for demo)
    final profanityList = [
      'hate',
      'kill',
      'die',
      'idiot',
      'stupid',
      'loser',
      // Add comprehensive list from content_policy.dart
    ];

    // Harassment patterns
    final harassmentPatterns = [
      RegExp(r'you\s+are\s+(a\s+)?trash'),
      RegExp(r'go\s+die'),
      RegExp(r'kill\s+yourself'),
    ];

    // Check profanity
    for (final word in profanityList) {
      if (lowerContent.contains(word)) {
        return true;
      }
    }

    // Check harassment patterns
    for (final pattern in harassmentPatterns) {
      if (pattern.hasMatch(lowerContent)) {
        return true;
      }
    }

    // Spam detection (excessive caps, repeated characters)
    final capsRatio =
        content.replaceAll(RegExp(r'[^A-Z]'), '').length / content.length;
    if (capsRatio > 0.7 && content.length > 20) {
      return true; // Excessive caps = spam
    }

    return false;
  }

  /// Advanced toxicity score (0.0 - 1.0)
  double getToxicityScore(String content) {
    final lowerContent = content.toLowerCase();
    double score = 0.0;

    // Profanity weight
    final profanityCount = [
      'hate',
      'kill',
      'die',
      'idiot',
      'stupid',
    ].where(lowerContent.contains).length;
    score += profanityCount * 0.15;

    // Harassment patterns
    if (RegExp(r'(you|u)\s+(r|are)\s+trash').hasMatch(lowerContent)) {
      score += 0.30;
    }

    // Excessive caps
    final capsRatio =
        content.replaceAll(RegExp(r'[^A-Z]'), '').length /
        (content.isNotEmpty ? content.length : 1);
    if (capsRatio > 0.5) {
      score += 0.20;
    }

    return score.clamp(0.0, 1.0);
  }

  // ─── Content Moderation ───────────────────────────────────────────────────

  /// Automatically limit reach of toxic users
  Future<void> limitReach(String userId, String reason) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isLimited': true,
        'limitReason': reason,
        'limitedAt': FieldValue.serverTimestamp(),
      });

      // Update trust score
      final currentTrust = await calculateTrustScore(userId);
      await _firestore.collection('users').doc(userId).update({
        'trustScore': currentTrust * 0.5, // Cut trust in half
      });

      // Log moderation action
      await _firestore.collection('moderation_logs').add({
        'userId': userId,
        'action': 'limit_reach',
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error limiting user reach: $e');
    }
  }

  /// Handle content report
  Future<void> handleReport(
    String contentId,
    String reporterId,
    ReportReason reason, {
    String? details,
  }) async {
    try {
      // Create report
      await _firestore.collection('reports').add({
        'contentId': contentId,
        'reporterId': reporterId,
        'reason': reason.name,
        'details': details,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Get content and increment report count
      final contentDoc = await _firestore
          .collection('fightwire_posts')
          .doc(contentId)
          .get();
      if (contentDoc.exists) {
        final currentReports = contentDoc.data()?['reportCount'] ?? 0;
        final newReports = currentReports + 1;

        await _firestore.collection('fightwire_posts').doc(contentId).update({
          'reportCount': newReports,
          'isReported': true,
        });

        // Auto-hide if threshold reached
        if (newReports >= 5) {
          await _autoHideContent(contentId, 'Multiple reports received');
        }

        // Suspend user if many reports
        final authorId = contentDoc.data()?['authorId'];
        if (authorId != null) {
          await _checkUserReports(authorId);
        }
      }
    } catch (e) {
      debugPrint('Error handling report: $e');
    }
  }

  Future<void> _autoHideContent(String contentId, String reason) async {
    await _firestore.collection('fightwire_posts').doc(contentId).update({
      'isModerated': true,
      'moderationReason': reason,
      'moderatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _checkUserReports(String userId) async {
    final userReportedPosts = await _firestore
        .collection('fightwire_posts')
        .where('authorId', isEqualTo: userId)
        .where('isReported', isEqualTo: true)
        .count()
        .get();

    if ((userReportedPosts.count ?? 0) >= 10) {
      await _suspendUser(userId, 'Excessive reported content');
    }
  }

  Future<void> _suspendUser(String userId, String reason) async {
    await _firestore.collection('users').doc(userId).update({
      'isSuspended': true,
      'suspensionReason': reason,
      'suspendedAt': FieldValue.serverTimestamp(),
    });

    // Notify user
    await _firestore.collection('notifications').add({
      'userId': userId,
      'type': 'account_suspended',
      'title': 'Account Suspended',
      'message': 'Your account has been suspended: $reason',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Safety Score Calculation ─────────────────────────────────────────────

  /// Calculate user safety score (inverse of risk)
  Future<double> calculateUserSafetyScore(String userId) async {
    double safetyScore = 1.0; // Start safe

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0.5;

      final data = userDoc.data()!;

      // Reports received (penalty)
      final reportCount = data['reportCount'] ?? 0;
      safetyScore -= (reportCount * 0.05).clamp(0, 0.40);

      // Content violations
      final violations = data['contentViolations'] ?? 0;
      safetyScore -= (violations * 0.10).clamp(0, 0.50);

      // Community feedback (trust score)
      final trustScore = data['trustScore'] ?? 0.5;
      safetyScore = (safetyScore + trustScore) / 2;

      // Verification boosts safety
      if (data['verified'] == true) {
        safetyScore = (safetyScore * 1.2).clamp(0, 1.0);
      }

      return safetyScore.clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('Error calculating safety score: $e');
      return 0.5;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════

enum VerificationType {
  email,
  phone,
  fighter, // Competition records verification
  gym, // Business registration
  promoter, // Event history
  coach, // Certification
  identity, // Government ID
}

enum ReportReason {
  spam,
  harassment,
  hate,
  violence,
  nudity,
  falseInfo,
  scam,
  impersonation,
  other,
}
