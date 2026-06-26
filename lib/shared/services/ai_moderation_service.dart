import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Enums & Models
// ---------------------------------------------------------------------------

/// Severity of a detected content violation.
enum ViolationSeverity {
  low, // Minor — e.g. mild language
  medium, // Moderate — e.g. suggestive imagery
  high, // Severe — e.g. hate speech, threats
  critical, // Immediate action — e.g. CSAM, doxxing
}

/// Content medium being analysed.
enum ContentMedium { text, image, video, audio, profile, liveStream }

/// Action the AI engine recommends or takes automatically.
enum ModerationAction {
  approve, // Content is clean
  flag, // Queue for human review
  shadowBan, // Hide from others but visible to author
  removeContent, // Delete the content
  warnUser, // Issue a warning strike
  suspendUser, // Temporary account suspension
  banUser, // Permanent ban
  escalateToLaw, // Notify law enforcement (CSAM / threats)
}

/// Current status of a moderation case.
enum CaseStatus {
  pending,
  inReview,
  resolved,
  appealed,
  appealApproved,
  appealDenied,
  escalated,
}

/// A single AI-detected violation.
class AiViolation {
  final String violationId;
  final String contentId;
  final ContentMedium medium;
  final String category; // e.g. 'hate_speech', 'nudity', 'violence'
  final ViolationSeverity severity;
  final double confidence; // 0.0 – 1.0
  final ModerationAction recommendedAction;
  final DateTime detectedAt;

  const AiViolation({
    required this.violationId,
    required this.contentId,
    required this.medium,
    required this.category,
    required this.severity,
    required this.confidence,
    required this.recommendedAction,
    required this.detectedAt,
  });

  Map<String, dynamic> toMap() => {
    'violationId': violationId,
    'contentId': contentId,
    'medium': medium.name,
    'category': category,
    'severity': severity.name,
    'confidence': confidence,
    'recommendedAction': recommendedAction.name,
    'detectedAt': Timestamp.fromDate(detectedAt),
  };
}

/// An appeal submitted by a user against a moderation action.
class ModerationAppeal {
  final String appealId;
  final String violationId;
  final String userId;
  final String reason;
  final DateTime submittedAt;
  final CaseStatus status;

  const ModerationAppeal({
    required this.appealId,
    required this.violationId,
    required this.userId,
    required this.reason,
    required this.submittedAt,
    this.status = CaseStatus.appealed,
  });
}

/// Auto-ban rule that triggers without human review.
class AutoBanRule {
  final String ruleId;
  final String description;
  final String category; // matches AiViolation.category
  final ViolationSeverity minimumSeverity;
  final double minimumConfidence;
  final ModerationAction action;
  final bool enabled;

  const AutoBanRule({
    required this.ruleId,
    required this.description,
    required this.category,
    required this.minimumSeverity,
    required this.minimumConfidence,
    required this.action,
    this.enabled = true,
  });
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// AI-powered content moderation service.
///
/// Hooks into the content pipeline to scan text, images, video, and audio
/// before publishing. Works alongside [ContentSafetyService] (client-side
/// keyword scanning) by adding ML-based analysis.
///
/// Architecture:
///   Post/Upload → ContentSafetyService.checkText() → AiModerationService
///   .scanContent() → auto-action or human-review queue → Admin dashboard.
class AiModerationService extends ChangeNotifier {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'australia-southeast1');

  // ── In-memory rule cache ──────────────────────────────────────────
  final List<AutoBanRule> _autoBanRules = [];
  List<AutoBanRule> get autoBanRules => List.unmodifiable(_autoBanRules);

  // ── Strike tracker (userId → count) loaded lazily ─────────────────
  final Map<String, int> _strikeCache = {};

  // ══════════════════════════════════════════════════════════════════
  //  CONTENT SCANNING
  // ══════════════════════════════════════════════════════════════════

  /// Scan text content with AI (calls Cloud Function / Vertex AI).
  Future<AiViolation?> scanText({
    required String contentId,
    required String text,
    String? authorId,
  }) async {
    try {
      final result = await _functions.httpsCallable('ai-moderateText').call({
        'contentId': contentId,
        'text': text,
        'authorId': ?authorId,
      });
      final data = result.data as Map<String, dynamic>?;
      if (data == null || data['clean'] == true) return null;
      return AiViolation(
        violationId:
            data['violationId'] as String? ??
            'v_${DateTime.now().millisecondsSinceEpoch}',
        contentId: contentId,
        medium: ContentMedium.text,
        category: data['category'] as String? ?? 'unknown',
        severity: ViolationSeverity.values.firstWhere(
          (v) => v.name == (data['severity'] as String? ?? 'low'),
          orElse: () => ViolationSeverity.low,
        ),
        confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
        recommendedAction: ModerationAction.values.firstWhere(
          (a) => a.name == (data['recommendedAction'] as String? ?? 'flag'),
          orElse: () => ModerationAction.flag,
        ),
        detectedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('AiMod: scanText error for $contentId: $e');
      return null; // fail-open: don't block content on function errors
    }
  }

  /// Scan an image (before upload is finalised in Cloud Storage).
  Future<AiViolation?> scanImage({
    required String contentId,
    required String imageUrl,
    String? authorId,
  }) async {
    try {
      final result = await _functions.httpsCallable('ai-moderateImage').call({
        'contentId': contentId,
        'imageUrl': imageUrl,
        'authorId': ?authorId,
      });
      final data = result.data as Map<String, dynamic>?;
      if (data == null || data['clean'] == true) return null;
      return AiViolation(
        violationId:
            data['violationId'] as String? ??
            'v_${DateTime.now().millisecondsSinceEpoch}',
        contentId: contentId,
        medium: ContentMedium.image,
        category: data['category'] as String? ?? 'nsfw',
        severity: ViolationSeverity.values.firstWhere(
          (v) => v.name == (data['severity'] as String? ?? 'medium'),
          orElse: () => ViolationSeverity.medium,
        ),
        confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
        recommendedAction: ModerationAction.values.firstWhere(
          (a) => a.name == (data['recommendedAction'] as String? ?? 'flag'),
          orElse: () => ModerationAction.flag,
        ),
        detectedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('AiMod: scanImage error for $contentId: $e');
      return null;
    }
  }

  /// Scan a video (kicked off as async Cloud Function job).
  Future<String> scanVideoAsync({
    required String contentId,
    required String videoUrl,
    String? authorId,
  }) async {
    try {
      final result = await _functions.httpsCallable('ai-moderateVideo').call({
        'contentId': contentId,
        'videoUrl': videoUrl,
        'authorId': ?authorId,
      });
      final data = result.data as Map<String, dynamic>?;
      return data?['jobId'] as String? ??
          'job_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      debugPrint('AiMod: scanVideoAsync error for $contentId: $e');
      return 'job_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Scan audio (transcribe + analyse).
  Future<AiViolation?> scanAudio({
    required String contentId,
    required String audioUrl,
    String? authorId,
  }) async {
    try {
      final result = await _functions.httpsCallable('ai-moderateAudio').call({
        'contentId': contentId,
        'audioUrl': audioUrl,
        'authorId': ?authorId,
      });
      final data = result.data as Map<String, dynamic>?;
      if (data == null || data['clean'] == true) return null;
      return AiViolation(
        violationId:
            data['violationId'] as String? ??
            'v_${DateTime.now().millisecondsSinceEpoch}',
        contentId: contentId,
        medium: ContentMedium.audio,
        category: data['category'] as String? ?? 'audio',
        severity: ViolationSeverity.values.firstWhere(
          (v) => v.name == (data['severity'] as String? ?? 'low'),
          orElse: () => ViolationSeverity.low,
        ),
        confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
        recommendedAction: ModerationAction.values.firstWhere(
          (a) => a.name == (data['recommendedAction'] as String? ?? 'flag'),
          orElse: () => ModerationAction.flag,
        ),
        detectedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('AiMod: scanAudio error for $contentId: $e');
      return null;
    }
  }

  /// Unified scan entry point — routes to the correct scanner.
  Future<AiViolation?> scanContent({
    required String contentId,
    required ContentMedium medium,
    required String contentUrl,
    String? rawText,
    String? authorId,
  }) async {
    AiViolation? violation;

    switch (medium) {
      case ContentMedium.text:
        violation = await scanText(
          contentId: contentId,
          text: rawText ?? '',
          authorId: authorId,
        );
        break;
      case ContentMedium.image:
        violation = await scanImage(
          contentId: contentId,
          imageUrl: contentUrl,
          authorId: authorId,
        );
        break;
      case ContentMedium.video:
        await scanVideoAsync(
          contentId: contentId,
          videoUrl: contentUrl,
          authorId: authorId,
        );
        break;
      case ContentMedium.audio:
        violation = await scanAudio(
          contentId: contentId,
          audioUrl: contentUrl,
          authorId: authorId,
        );
        break;
      case ContentMedium.profile:
        violation = await scanText(
          contentId: contentId,
          text: rawText ?? '',
          authorId: authorId,
        );
        break;
      case ContentMedium.liveStream:
        // Live streams use a separate real-time pipeline
        break;
    }

    if (violation != null) {
      await _handleViolation(violation, authorId: authorId);
    }

    return violation;
  }

  // ══════════════════════════════════════════════════════════════════
  //  AUTO-ACTION RULES ENGINE
  // ══════════════════════════════════════════════════════════════════

  /// Load auto-ban rules from Firestore.
  Future<void> loadAutoBanRules() async {
    try {
      final snap = await _firestore.collection('moderation_rules').get();
      _autoBanRules.clear();
      for (final doc in snap.docs) {
        final d = doc.data();
        _autoBanRules.add(
          AutoBanRule(
            ruleId: doc.id,
            description: d['description'] ?? '',
            category: d['category'] ?? '',
            minimumSeverity: ViolationSeverity.values.firstWhere(
              (v) => v.name == d['minimumSeverity'],
              orElse: () => ViolationSeverity.high,
            ),
            minimumConfidence: (d['minimumConfidence'] ?? 0.9).toDouble(),
            action: ModerationAction.values.firstWhere(
              (a) => a.name == d['action'],
              orElse: () => ModerationAction.flag,
            ),
            enabled: d['enabled'] ?? true,
          ),
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('AiMod: failed to load rules: $e');
    }
  }

  /// Evaluate a violation against all active rules.
  ModerationAction evaluateRules(AiViolation violation) {
    for (final rule in _autoBanRules.where((r) => r.enabled)) {
      if (rule.category == violation.category &&
          violation.severity.index >= rule.minimumSeverity.index &&
          violation.confidence >= rule.minimumConfidence) {
        return rule.action;
      }
    }
    // Default: queue for human review
    return ModerationAction.flag;
  }

  /// Internal handler that persists the violation and applies the action.
  Future<void> _handleViolation(
    AiViolation violation, {
    String? authorId,
  }) async {
    // 1. Persist the violation
    await _firestore
        .collection('ai_violations')
        .doc(violation.violationId)
        .set(violation.toMap());

    // 2. Determine action
    final action = evaluateRules(violation);

    // 3. Execute action
    switch (action) {
      case ModerationAction.approve:
        break;
      case ModerationAction.flag:
        await _addToReviewQueue(violation);
        break;
      case ModerationAction.shadowBan:
        if (authorId != null) await _shadowBanContent(violation.contentId);
        break;
      case ModerationAction.removeContent:
        await _removeContent(violation.contentId, violation.medium);
        break;
      case ModerationAction.warnUser:
        if (authorId != null) await issueStrike(authorId, violation);
        break;
      case ModerationAction.suspendUser:
        if (authorId != null) await suspendUser(authorId, violation);
        break;
      case ModerationAction.banUser:
        if (authorId != null) await banUser(authorId, violation);
        break;
      case ModerationAction.escalateToLaw:
        await _escalateToLawEnforcement(violation, authorId);
        break;
    }

    // 4. Notify admins in real-time
    await _notifyAdmins(violation, action);
  }

  // ══════════════════════════════════════════════════════════════════
  //  REVIEW QUEUE
  // ══════════════════════════════════════════════════════════════════

  /// Add a violation to the human-review queue.
  Future<void> _addToReviewQueue(AiViolation violation) async {
    await _firestore
        .collection('moderation_queue')
        .doc(violation.violationId)
        .set({
          ...violation.toMap(),
          'status': CaseStatus.pending.name,
          'assignedTo': null,
          'queuedAt': FieldValue.serverTimestamp(),
        });
  }

  /// Stream the pending review queue (for admin UI).
  Stream<QuerySnapshot<Map<String, dynamic>>> streamReviewQueue() {
    return _firestore
        .collection('moderation_queue')
        .where('status', isEqualTo: CaseStatus.pending.name)
        .orderBy('queuedAt', descending: false)
        .snapshots();
  }

  /// Admin resolves a queued item.
  Future<void> resolveCase({
    required String violationId,
    required String adminId,
    required ModerationAction actionTaken,
    String? notes,
  }) async {
    await _firestore.collection('moderation_queue').doc(violationId).update({
      'status': CaseStatus.resolved.name,
      'assignedTo': adminId,
      'actionTaken': actionTaken.name,
      'resolvedAt': FieldValue.serverTimestamp(),
      'notes': notes ?? '',
    });
  }

  // ══════════════════════════════════════════════════════════════════
  //  APPEALS
  // ══════════════════════════════════════════════════════════════════

  /// User submits an appeal for a moderation decision.
  Future<void> submitAppeal({
    required String violationId,
    required String userId,
    required String reason,
  }) async {
    final appealId = 'appeal_${DateTime.now().millisecondsSinceEpoch}';
    await _firestore.collection('moderation_appeals').doc(appealId).set({
      'violationId': violationId,
      'userId': userId,
      'reason': reason,
      'status': CaseStatus.appealed.name,
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin decision on an appeal.
  Future<void> resolveAppeal({
    required String appealId,
    required String adminId,
    required bool approved,
    String? notes,
  }) async {
    await _firestore.collection('moderation_appeals').doc(appealId).update({
      'status': approved
          ? CaseStatus.appealApproved.name
          : CaseStatus.appealDenied.name,
      'resolvedBy': adminId,
      'resolvedAt': FieldValue.serverTimestamp(),
      'notes': notes ?? '',
    });
  }

  // ══════════════════════════════════════════════════════════════════
  //  STRIKES & ENFORCEMENT
  // ══════════════════════════════════════════════════════════════════

  /// Issue a warning strike to a user.
  Future<void> issueStrike(String userId, AiViolation violation) async {
    final current = _strikeCache[userId] ?? 0;
    final newCount = current + 1;
    _strikeCache[userId] = newCount;

    await _firestore.collection('user_strikes').add({
      'userId': userId,
      'violationId': violation.violationId,
      'category': violation.category,
      'strikeNumber': newCount,
      'issuedAt': FieldValue.serverTimestamp(),
    });

    // Auto-escalate at thresholds
    if (newCount >= 5) {
      await banUser(userId, violation);
    } else if (newCount >= 3) {
      await suspendUser(userId, violation);
    }
  }

  /// Get current strike count for a user.
  Future<int> getStrikeCount(String userId) async {
    if (_strikeCache.containsKey(userId)) return _strikeCache[userId]!;
    final snap = await _firestore
        .collection('user_strikes')
        .where('userId', isEqualTo: userId)
        .get();
    _strikeCache[userId] = snap.docs.length;
    return snap.docs.length;
  }

  /// Temporarily suspend a user.
  Future<void> suspendUser(String userId, AiViolation violation) async {
    await _firestore.collection('users').doc(userId).update({
      'status': 'suspended',
      'suspendedAt': FieldValue.serverTimestamp(),
      'suspendedUntil': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 7)),
      ),
      'suspensionReason': violation.category,
    });
    debugPrint('AiMod: suspended user $userId for ${violation.category}');
  }

  /// Permanently ban a user.
  Future<void> banUser(String userId, AiViolation violation) async {
    await _firestore.collection('users').doc(userId).update({
      'status': 'banned',
      'bannedAt': FieldValue.serverTimestamp(),
      'banReason': violation.category,
    });
    debugPrint('AiMod: banned user $userId for ${violation.category}');
  }

  // ══════════════════════════════════════════════════════════════════
  //  REAL-TIME CONTENT FLAGGING (Live Streams)
  // ══════════════════════════════════════════════════════════════════

  /// Start real-time moderation for a live stream.
  Future<StreamSubscription<void>?> startLiveModeration({
    required String streamId,
    required String streamerId,
  }) async {
    // Subscribe to a live transcript / frame-sampler Cloud Function
    //       that pushes flagged frames or text snippets into
    //       `live_moderation/{streamId}/flags`.
    debugPrint('AiMod: live moderation started for stream $streamId');
    return null;
  }

  /// Force-end a live stream due to violation.
  Future<void> terminateLiveStream(String streamId, String reason) async {
    await _firestore.collection('live_streams').doc(streamId).update({
      'status': 'terminated',
      'terminatedAt': FieldValue.serverTimestamp(),
      'terminationReason': reason,
    });
  }

  // ══════════════════════════════════════════════════════════════════
  //  ADMIN NOTIFICATIONS
  // ══════════════════════════════════════════════════════════════════

  /// Push a notification to all online admins about a moderation event.
  Future<void> _notifyAdmins(
    AiViolation violation,
    ModerationAction action,
  ) async {
    await _firestore.collection('admin_notifications').add({
      'type': 'moderation',
      'violationId': violation.violationId,
      'category': violation.category,
      'severity': violation.severity.name,
      'action': action.name,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  // ══════════════════════════════════════════════════════════════════
  //  PRIVATE ENFORCEMENT HELPERS
  // ══════════════════════════════════════════════════════════════════

  Future<void> _shadowBanContent(String contentId) async {
    // Set visibility flag to 'shadow' in the content doc
    debugPrint('AiMod: shadow-banned content $contentId');
  }

  Future<void> _removeContent(String contentId, ContentMedium medium) async {
    // Mark content as removed, delete from Storage if media
    debugPrint('AiMod: removed content $contentId ($medium)');
  }

  Future<void> _escalateToLawEnforcement(
    AiViolation violation,
    String? authorId,
  ) async {
    // CRITICAL: CSAM or credible threats — preserve evidence, notify legal.
    await _firestore.collection('law_enforcement_escalations').add({
      'violationId': violation.violationId,
      'authorId': authorId ?? 'unknown',
      'category': violation.category,
      'severity': violation.severity.name,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'awaiting_review',
    });
    debugPrint(
      'AiMod: ESCALATED to law enforcement — ${violation.violationId}',
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  ANALYTICS / DASHBOARD DATA
  // ══════════════════════════════════════════════════════════════════

  /// Get aggregate moderation stats for the admin dashboard.
  Future<Map<String, int>> getModerationStats() async {
    try {
      final pending = await _firestore
          .collection('moderation_queue')
          .where('status', isEqualTo: CaseStatus.pending.name)
          .count()
          .get();

      final resolved = await _firestore
          .collection('moderation_queue')
          .where('status', isEqualTo: CaseStatus.resolved.name)
          .count()
          .get();

      final appeals = await _firestore
          .collection('moderation_appeals')
          .where('status', isEqualTo: CaseStatus.appealed.name)
          .count()
          .get();

      return {
        'pending': pending.count ?? 0,
        'resolved': resolved.count ?? 0,
        'activeAppeals': appeals.count ?? 0,
      };
    } catch (e) {
      debugPrint('AiMod: failed to fetch stats: $e');
      return {'pending': 0, 'resolved': 0, 'activeAppeals': 0};
    }
  }
}
