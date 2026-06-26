import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'social_platform_specs.dart';
import 'social_post_adapter_service.dart';

/// Cross-platform social distribution service.
///
/// Publishes DFC content to: LinkedIn, TikTok, YouTube, Threads,
/// Bluesky, Pinterest, Instagram, Twitter/X, Facebook
/// via Blotato API (Cloud Function proxy) or n8n fallback.
///
/// Plan-based limits:
///   Free    → 0 posts/day (upgrade required)
///   Warrior → 3 posts/day, 4 platforms max
///   Coach   → 10 posts/day, 6 platforms max
///   Gym     → 25 posts/day, all 9 platforms
///   Promoter→ unlimited, all 9 platforms + scheduling
class CrossPlatformPostingService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'australia-southeast1',
  );

  static const _postsCol = 'social_engine_posts';
  static const _usageCol = 'social_posting_usage';

  // ── All supported platforms ──
  static const supportedPlatforms = [
    SocialPlatform.tiktok,
    SocialPlatform.instagram,
    SocialPlatform.youtube,
    SocialPlatform.facebook,
    SocialPlatform.xTwitter,
    SocialPlatform.linkedin,
    SocialPlatform.threads,
    SocialPlatform.bluesky,
    SocialPlatform.pinterest,
  ];

  // ── Plan-based Limits ──
  static const Map<String, PostingLimits> tierLimits = {
    'free': PostingLimits(postsPerDay: 0, maxPlatforms: 0, canSchedule: false),
    'warrior': PostingLimits(
      postsPerDay: 3,
      maxPlatforms: 4,
      canSchedule: false,
    ),
    'coach': PostingLimits(postsPerDay: 10, maxPlatforms: 6, canSchedule: true),
    'gym': PostingLimits(postsPerDay: 25, maxPlatforms: 9, canSchedule: true),
    'promoter': PostingLimits(
      postsPerDay: -1,
      maxPlatforms: 9,
      canSchedule: true,
    ),
  };

  /// Get limits for a tier (defaults to free)
  static PostingLimits limitsForTier(String tier) =>
      tierLimits[tier.toLowerCase()] ?? tierLimits['free']!;

  /// Platforms available for a tier (sorted by priority)
  static List<SocialPlatform> platformsForTier(String tier) {
    final limits = limitsForTier(tier);
    return supportedPlatforms.take(limits.maxPlatforms).toList();
  }

  // ─── Check Usage ──────────────────────────────────────────────────────
  Future<PostingUsage> getUsageToday(String userId) async {
    final today = _todayKey();
    final doc = await _firestore
        .collection(_usageCol)
        .doc('${userId}_$today')
        .get();
    if (!doc.exists) return PostingUsage(userId: userId, date: today);
    final data = doc.data()!;
    return PostingUsage(
      userId: userId,
      date: today,
      postsToday: data['postsToday'] as int? ?? 0,
      platformsUsed: List<String>.from(data['platformsUsed'] ?? []),
    );
  }

  Future<void> _incrementUsage(String userId, List<String> platforms) async {
    final today = _todayKey();
    final docRef = _firestore.collection(_usageCol).doc('${userId}_$today');
    await docRef.set({
      'userId': userId,
      'date': today,
      'postsToday': FieldValue.increment(1),
      'platformsUsed': FieldValue.arrayUnion(platforms),
      'lastPostAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _todayKey() {
    final now = DateTime.now().toUtc();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Check if a user can post (returns null if OK, or error message)
  Future<String?> canPost({
    required String userId,
    required String tier,
    required int platformCount,
  }) async {
    final limits = limitsForTier(tier);
    if (limits.postsPerDay == 0) {
      return 'Upgrade to Warrior or above to publish across platforms.';
    }
    if (platformCount > limits.maxPlatforms) {
      return 'Your $tier plan allows ${limits.maxPlatforms} platforms. '
          'Upgrade to unlock more.';
    }
    if (limits.postsPerDay > 0) {
      final usage = await getUsageToday(userId);
      if (usage.postsToday >= limits.postsPerDay) {
        return 'Daily limit reached (${limits.postsPerDay} posts/day on $tier plan). '
            'Resets at midnight UTC.';
      }
    }
    return null; // Good to go
  }

  Future<Map<String, dynamic>> publishNormalizedPost({
    required String userId,
    required String tier,
    required String caption,
    List<String> hashtags = const [],
    required NormalizedPostMedia media,
    List<SocialPlatform>? platforms,
    DateTime? scheduledAt,
    Map<String, String> platformCaptions = const {},
  }) async {
    final selected = platforms ?? platformsForTier(tier);
    final targetPlatforms = selected.map((p) => p.apiKey).toList();

    final block = await canPost(
      userId: userId,
      tier: tier,
      platformCount: selected.length,
    );
    if (block != null) throw PostingLimitException(block);

    final perPlatformBlock = await checkPerPlatformLimits(userId, selected);
    if (perPlatformBlock != null) throw PostingLimitException(perPlatformBlock);

    final draft = SocialPostMediaAdapter.buildOutboundDraft(
      caption: caption,
      hashtags: hashtags,
      media: media,
      targetPlatforms: targetPlatforms,
      platformCaptions: platformCaptions,
    );

    final overflows = <SocialPlatform, int>{};
    for (final platform in selected) {
      final payload = draft.payloadFor(platform.apiKey);
      final spec = platformSpecs[platform];
      if (payload == null || spec == null) {
        continue;
      }
      final overflow = payload.caption.length - spec.maxCaptionLength;
      if (overflow > 0) {
        overflows[platform] = overflow;
      }
    }

    if (overflows.isNotEmpty) {
      final worst = overflows.entries.first;
      throw PostingLimitException(
        'Caption is ${worst.value} chars over the '
        '${platformSpecs[worst.key]!.maxCaptionLength}-char limit '
        'for ${worst.key.label}. Shorten it or deselect that platform.',
      );
    }

    final callable = _functions.httpsCallable('publishViaBlotatoCrosspost');
    final result = await callable.call<dynamic>(
      draft.toCallablePayload(
        targetPlatforms: targetPlatforms,
        scheduledAt: scheduledAt,
      ),
    );

    await _incrementUsage(userId, targetPlatforms);
    await _incrementPlatformUsage(userId, targetPlatforms);

    final data = result.data as Map<String, dynamic>? ?? {};
    notifyListeners();
    return data;
  }

  // ─── Publish to All Platforms ──────────────────────────────────────────
  Future<Map<String, dynamic>> publishToAll({
    required String userId,
    required String tier,
    required String videoUrl,
    required String caption,
    List<String> hashtags = const [],
    List<SocialPlatform>? platforms,
    DateTime? scheduledAt,
  }) async {
    return publishNormalizedPost(
      userId: userId,
      tier: tier,
      caption: caption,
      hashtags: hashtags,
      media: SocialPostMediaAdapter.normalizeFields(externalVideoUrl: videoUrl),
      platforms: platforms,
      scheduledAt: scheduledAt,
    );
  }

  // ─── Unified Publish (text / image / video / carousel) ─────────────────
  Future<Map<String, dynamic>> publishContent({
    required String userId,
    required String tier,
    required PostType postType,
    required String caption,
    String? mediaUrl,
    List<String>? mediaUrls, // for carousels
    List<String> hashtags = const [],
    List<SocialPlatform>? platforms,
    DateTime? scheduledAt,
  }) async {
    final normalizedMedia = SocialPostMediaAdapter.normalizeFields(
      mediaUrls:
          mediaUrls ??
          (_usesDirectMediaUrls(postType, mediaUrl)
              ? <String>[mediaUrl!]
              : const <String>[]),
      externalVideoUrl: _usesExternalVideoUrl(postType, mediaUrl)
          ? mediaUrl
          : null,
    );

    return publishNormalizedPost(
      userId: userId,
      tier: tier,
      caption: caption,
      hashtags: hashtags,
      media: normalizedMedia,
      platforms: platforms,
      scheduledAt: scheduledAt,
    );
  }

  // ─── Per-Platform Daily Rate Limits (Blotato-enforced) ─────────────────
  Future<String?> checkPerPlatformLimits(
    String userId,
    List<SocialPlatform> platforms,
  ) async {
    final today = _todayKey();
    for (final p in platforms) {
      final spec = platformSpecs[p];
      if (spec == null) continue;
      final doc = await _firestore
          .collection('social_platform_usage')
          .doc('${userId}_${p.apiKey}_$today')
          .get();
      final count = (doc.data()?['count'] as int?) ?? 0;
      if (count >= spec.maxPostsPerDay) {
        return '${p.label} limit reached ($count/${spec.maxPostsPerDay} '
            'posts today). Try again tomorrow.';
      }
    }
    return null;
  }

  Future<void> _incrementPlatformUsage(
    String userId,
    List<String> platformKeys,
  ) async {
    final today = _todayKey();
    final batch = _firestore.batch();
    for (final key in platformKeys) {
      final ref = _firestore
          .collection('social_platform_usage')
          .doc('${userId}_${key}_$today');
      batch.set(ref, {
        'userId': userId,
        'platform': key,
        'date': today,
        'count': FieldValue.increment(1),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  // ─── Schedule for Later ────────────────────────────────────────────────
  Future<String> scheduleNormalizedPost({
    required String userId,
    required String tier,
    required String caption,
    required NormalizedPostMedia media,
    required DateTime scheduledAt,
    List<String> hashtags = const [],
    List<SocialPlatform>? platforms,
    Map<String, String> platformCaptions = const {},
  }) async {
    final limits = limitsForTier(tier);
    if (!limits.canSchedule) {
      throw const PostingLimitException(
        'Scheduling requires Coach plan or above. Upgrade to unlock.',
      );
    }

    final selected = platforms ?? platformsForTier(tier);
    final targetPlatforms = selected.map((p) => p.apiKey).toList();

    final block = await canPost(
      userId: userId,
      tier: tier,
      platformCount: selected.length,
    );
    if (block != null) throw PostingLimitException(block);

    final draft = SocialPostMediaAdapter.buildOutboundDraft(
      caption: caption,
      hashtags: hashtags,
      media: media,
      targetPlatforms: targetPlatforms,
      platformCaptions: platformCaptions,
    );
    final scheduledPayload = draft.toCallablePayload(
      targetPlatforms: targetPlatforms,
      scheduledAt: scheduledAt,
    );

    final doc = await _firestore.collection(_postsCol).add({
      'userId': userId,
      'videoUrl': media.primaryVideoUrl ?? media.externalVideoUrl ?? '',
      'mediaUrl': scheduledPayload['mediaUrl'],
      'mediaUrls': scheduledPayload['mediaUrls'] ?? const <String>[],
      'mediaTypes': media.mediaTypes,
      'thumbnailUrl': media.thumbnailUrl,
      'externalVideoUrl': media.externalVideoUrl,
      'caption': caption,
      'hashtags': hashtags,
      'postType': scheduledPayload['postType'],
      'platformPayloads': scheduledPayload['platformPayloads'],
      'targetPlatforms': targetPlatforms,
      'status': 'scheduled',
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _incrementUsage(userId, targetPlatforms);
    notifyListeners();
    return doc.id;
  }

  Future<String> schedulePost({
    required String userId,
    required String tier,
    required String videoUrl,
    required String caption,
    required DateTime scheduledAt,
    List<String> hashtags = const [],
    List<SocialPlatform>? platforms,
  }) async {
    return scheduleNormalizedPost(
      userId: userId,
      tier: tier,
      caption: caption,
      hashtags: hashtags,
      media: SocialPostMediaAdapter.normalizeFields(externalVideoUrl: videoUrl),
      scheduledAt: scheduledAt,
      platforms: platforms,
    );
  }

  // ─── Get Post Queue ────────────────────────────────────────────────────
  Stream<List<SocialPost>> getPostQueue(String userId) {
    return _firestore
        .collection(_postsCol)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => SocialPost.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  // ─── Cancel Scheduled Post ─────────────────────────────────────────────
  Future<void> cancelPost(String postId) async {
    await _firestore.collection(_postsCol).doc(postId).update({
      'status': 'cancelled',
    });
    notifyListeners();
  }

  // ─── Retry Failed Post ─────────────────────────────────────────────────
  Future<void> retryPost(String postId) async {
    await _firestore.collection(_postsCol).doc(postId).update({
      'status': 'pending',
      'retryAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

  bool _usesExternalVideoUrl(PostType postType, String? mediaUrl) {
    if (mediaUrl == null || mediaUrl.isEmpty) {
      return false;
    }
    return postType == PostType.video ||
        postType == PostType.reel ||
        postType == PostType.story ||
        postType == PostType.short_;
  }

  bool _usesDirectMediaUrls(PostType postType, String? mediaUrl) {
    if (mediaUrl == null || mediaUrl.isEmpty) {
      return false;
    }
    return postType == PostType.image || postType == PostType.carousel;
  }
}

// ─── Platform Enum ───────────────────────────────────────────────────────

enum SocialPlatform {
  tiktok,
  instagram,
  youtube,
  facebook,
  xTwitter,
  linkedin,
  threads,
  bluesky,
  pinterest,
}

extension SocialPlatformExt on SocialPlatform {
  String get label {
    switch (this) {
      case SocialPlatform.tiktok:
        return 'TikTok';
      case SocialPlatform.instagram:
        return 'Instagram';
      case SocialPlatform.youtube:
        return 'YouTube Shorts';
      case SocialPlatform.facebook:
        return 'Facebook';
      case SocialPlatform.xTwitter:
        return 'X / Twitter';
      case SocialPlatform.linkedin:
        return 'LinkedIn';
      case SocialPlatform.threads:
        return 'Threads';
      case SocialPlatform.bluesky:
        return 'Bluesky';
      case SocialPlatform.pinterest:
        return 'Pinterest';
    }
  }

  String get apiKey {
    switch (this) {
      case SocialPlatform.tiktok:
        return 'tiktok';
      case SocialPlatform.instagram:
        return 'instagram';
      case SocialPlatform.youtube:
        return 'youtube';
      case SocialPlatform.facebook:
        return 'facebook';
      case SocialPlatform.xTwitter:
        return 'twitter';
      case SocialPlatform.linkedin:
        return 'linkedin';
      case SocialPlatform.threads:
        return 'threads';
      case SocialPlatform.bluesky:
        return 'bluesky';
      case SocialPlatform.pinterest:
        return 'pinterest';
    }
  }

  String get iconAsset {
    switch (this) {
      case SocialPlatform.tiktok:
        return 'assets/icons/tiktok.png';
      case SocialPlatform.instagram:
        return 'assets/icons/instagram.png';
      case SocialPlatform.youtube:
        return 'assets/icons/youtube.png';
      case SocialPlatform.facebook:
        return 'assets/icons/facebook.png';
      case SocialPlatform.xTwitter:
        return 'assets/icons/twitter.png';
      case SocialPlatform.linkedin:
        return 'assets/icons/linkedin.png';
      case SocialPlatform.threads:
        return 'assets/icons/threads.png';
      case SocialPlatform.bluesky:
        return 'assets/icons/bluesky.png';
      case SocialPlatform.pinterest:
        return 'assets/icons/pinterest.png';
    }
  }
}

// ─── Social Post Model ───────────────────────────────────────────────────

class SocialPost {
  final String id;
  final String userId;
  final String videoUrl;
  final String caption;
  final List<String> hashtags;
  final List<String> targetPlatforms;
  final String status;
  final Map<String, dynamic> results;
  final DateTime? scheduledAt;
  final DateTime? createdAt;

  const SocialPost({
    required this.id,
    required this.userId,
    required this.videoUrl,
    required this.caption,
    this.hashtags = const [],
    this.targetPlatforms = const [],
    this.status = 'pending',
    this.results = const {},
    this.scheduledAt,
    this.createdAt,
  });

  factory SocialPost.fromFirestore(String id, Map<String, dynamic> data) {
    return SocialPost(
      id: id,
      userId: data['userId'] as String? ?? '',
      videoUrl: data['videoUrl'] as String? ?? '',
      caption: data['caption'] as String? ?? '',
      hashtags: List<String>.from(data['hashtags'] ?? []),
      targetPlatforms: List<String>.from(data['targetPlatforms'] ?? []),
      status: data['status'] as String? ?? 'pending',
      results: data['results'] as Map<String, dynamic>? ?? {},
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  bool get isScheduled => status == 'scheduled';
  bool get isDistributed => status == 'distributed';
  bool get isFailed =>
      results.values.any((r) => (r as Map?)?['status'] == 'failed');
}

// ─── Plan Limits ─────────────────────────────────────────────────────────

class PostingLimits {
  final int postsPerDay; // -1 = unlimited
  final int maxPlatforms;
  final bool canSchedule;

  const PostingLimits({
    required this.postsPerDay,
    required this.maxPlatforms,
    required this.canSchedule,
  });

  bool get isUnlimited => postsPerDay < 0;
  bool get isBlocked => postsPerDay == 0;
}

class PostingUsage {
  final String userId;
  final String date;
  final int postsToday;
  final List<String> platformsUsed;

  const PostingUsage({
    required this.userId,
    required this.date,
    this.postsToday = 0,
    this.platformsUsed = const [],
  });

  int remaining(int limit) =>
      limit < 0 ? 999 : (limit - postsToday).clamp(0, limit);
}

class PostingLimitException implements Exception {
  final String message;
  const PostingLimitException(this.message);
  @override
  String toString() => message;
}
