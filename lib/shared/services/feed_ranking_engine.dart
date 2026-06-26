import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fightwire_post.dart';
import '../models/user_relationship.dart';
import '../models/user_model.dart';
import 'tribe_brain_encoder_service.dart';

/// Feed Ranking Engine - Smart algorithm for FightWire Feed
///
/// Implements 10-factor ranking algorithm that prioritizes relevance over addiction:
/// 1. Relationship strength (40% weight)
/// 2. Shared gym affiliation (15% weight)
/// 3. Location proximity (10% weight)
/// 4. Training style match (8% weight)
/// 5. Engagement quality (10% weight)
/// 6. Trending momentum (5% weight)
/// 7. Content type relevance (5% weight)
/// 8. Trust score (4% weight)
/// 9. Recency (2% weight)
/// 10. Impact potential (1% weight)
///
/// This creates an Instagram + LinkedIn + ESPN + Discord hybrid that spreads
/// opportunity, not toxicity.
class FeedRankingEngine {
  final FirebaseFirestore _firestore;

  // Ranking weights (must sum to 1.0)
  static const double relationshipWeight = 0.35;
  static const double gymWeight = 0.13;
  static const double locationWeight = 0.09;
  static const double trainingStyleWeight = 0.07;
  static const double engagementWeight = 0.09;
  static const double trendingWeight = 0.05;
  static const double contentTypeWeight = 0.05;
  static const double trustWeight = 0.04;
  static const double recencyWeight = 0.02;
  static const double impactWeight = 0.01;
  static const double brainEngagementWeight = 0.10;

  FeedRankingEngine({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Calculate overall relevance score for a post
  Future<double> calculateRelevanceScore({
    required FightWirePost post,
    required UserModel currentUser,
    required List<UserRelationship> relationships,
    GeoPoint? userLocation,
  }) async {
    double score = 0.0;

    // 1. Relationship strength
    score +=
        _calculateRelationshipScore(post, currentUser, relationships) *
        relationshipWeight;

    // 2. Shared gym affiliation
    score += _calculateGymScore(post, currentUser) * gymWeight;

    // 3. Location proximity
    if (userLocation != null && post.lat != null && post.lng != null) {
      score += _calculateLocationScore(post, userLocation) * locationWeight;
    }

    // 4. Training style match
    score +=
        _calculateTrainingStyleScore(post, currentUser) * trainingStyleWeight;

    // 5. Engagement quality
    score += _calculateEngagementScore(post) * engagementWeight;

    // 6. Trending momentum
    score += _calculateTrendingScore(post) * trendingWeight;

    // 7. Content type relevance
    score += _calculateContentTypeScore(post, currentUser) * contentTypeWeight;

    // 8. Trust score
    score += post.communityTrustScore * trustWeight;

    // 9. Recency
    score += _calculateRecencyScore(post) * recencyWeight;

    // 10. Impact potential
    score += _calculateImpactScore(post) * impactWeight;

    // 11. TRIBE v2 Brain Engagement — neural resonance scoring
    score += await _calculateBrainEngagementScore(post) * brainEngagementWeight;

    return score.clamp(0.0, 1.0);
  }

  /// 1. Relationship strength score
  double _calculateRelationshipScore(
    FightWirePost post,
    UserModel currentUser,
    List<UserRelationship> relationships,
  ) {
    // Find relationship with post author
    final relationship = relationships.firstWhere(
      (r) => r.targetUserId == post.authorId || r.userId == post.authorId,
      orElse: () => UserRelationship(
        id: '',
        userId: currentUser.id,
        targetUserId: post.authorId,
        type: RelationshipType.following,
        connectionStrength: 0.15,
        createdAt: DateTime.now(),
      ),
    );

    return relationship.connectionStrength;
  }

  /// 2. Shared gym affiliation score
  double _calculateGymScore(FightWirePost post, UserModel currentUser) {
    final currentUserGymId = currentUser.metadata?['gymId'] as String?;
    if (currentUserGymId == null || post.gymId == null) return 0.0;

    // Same gym = high relevance
    if (currentUserGymId == post.gymId) return 1.0;

    // Add gym network/affiliation logic for partner gyms
    return 0.0;
  }

  /// 3. Location proximity score
  double _calculateLocationScore(FightWirePost post, GeoPoint userLocation) {
    if (post.lat == null || post.lng == null) return 0.0;

    final distanceInMeters = _distanceInMeters(
      userLocation.latitude,
      userLocation.longitude,
      post.lat!,
      post.lng!,
    );

    // Score based on distance
    // 0-5 km: 1.0
    // 5-20 km: 0.7
    // 20-50 km: 0.4
    // 50-100 km: 0.2
    // 100+ km: 0.0
    if (distanceInMeters < 5000) return 1.0;
    if (distanceInMeters < 20000) return 0.7;
    if (distanceInMeters < 50000) return 0.4;
    if (distanceInMeters < 100000) return 0.2;
    return 0.0;
  }

  /// 4. Training style match score
  double _calculateTrainingStyleScore(
    FightWirePost post,
    UserModel currentUser,
  ) {
    final styles = _userFightingStyles(currentUser);
    if (styles.isEmpty) {
      return 0.5; // Neutral if user hasn't specified styles
    }

    // Check if post mentions user's training styles
    final contentLower = post.content.toLowerCase();
    int styleMatches = 0;

    for (final style in styles) {
      if (contentLower.contains(style.toLowerCase())) {
        styleMatches++;
      }
    }

    if (styleMatches == 0) return 0.3; // Some relevance to all combat sports
    if (styleMatches == 1) return 0.7;
    return 1.0; // Multiple style matches = highly relevant
  }

  /// 5. Engagement quality score
  double _calculateEngagementScore(FightWirePost post) {
    // Weighted engagement based on combat-specific reactions
    final totalReactions =
        post.respectCount +
        post.warriorCount +
        post.championCount +
        post.strongCount;

    final engagementRate =
        totalReactions /
        (post.likesCount + post.commentsCount + post.sharesCount + 1);

    // Higher weight for quality reactions (respect, champion)
    final qualityScore =
        (post.respectCount * 1.5 +
            post.championCount * 1.3 +
            post.warriorCount * 1.1 +
            post.strongCount) /
        (totalReactions + 1);

    // Combine engagement rate and quality
    return ((engagementRate * 0.6) + (qualityScore * 0.4)).clamp(0.0, 1.0);
  }

  /// 6. Trending momentum score
  double _calculateTrendingScore(FightWirePost post) {
    final now = DateTime.now();
    final postAge = now.difference(post.createdAt);

    if (postAge.inHours > 48) return 0.0; // Not trending if older than 48h

    // Calculate velocity (engagement per hour)
    final totalEngagement =
        post.respectCount +
        post.warriorCount +
        post.championCount +
        post.strongCount +
        post.commentsCount;
    final velocity = totalEngagement / (postAge.inHours + 1);

    // Normalize velocity to 0-1 scale
    // Assume 10 engagements/hour is maximum trending
    return (velocity / 10.0).clamp(0.0, 1.0);
  }

  /// 7. Content type relevance score
  double _calculateContentTypeScore(FightWirePost post, UserModel currentUser) {
    // Score based on user's interests and role
    final Map<FightWirePostType, double> relevanceMap = {
      FightWirePostType.training:
          _isInterested(currentUser, ['training', 'athlete']) ? 1.0 : 0.7,
      FightWirePostType.fight: _isInterested(currentUser, ['fights', 'events'])
          ? 1.0
          : 0.8,
      FightWirePostType.event:
          _isInterested(currentUser, ['events', 'community']) ? 1.0 : 0.7,
      FightWirePostType.gym: _isInterested(currentUser, ['gyms', 'training'])
          ? 1.0
          : 0.6,
      FightWirePostType.opportunity:
          _isInterested(currentUser, ['business', 'career']) ? 1.0 : 0.5,
      FightWirePostType.marketplace:
          _isInterested(currentUser, ['gear', 'shopping']) ? 0.8 : 0.4,
      FightWirePostType.charity:
          _isInterested(currentUser, ['community', 'giving']) ? 0.9 : 0.7,
      FightWirePostType.knowledge: 0.8, // Always valuable
      FightWirePostType.announcement: 0.7, // Moderately important
      FightWirePostType.sparringRequest:
          _isInterested(currentUser, ['training', 'sparring']) ? 1.0 : 0.3,
      FightWirePostType.livestream: 0.9, // High priority for live content
    };

    return relevanceMap[post.type] ?? 0.5;
  }

  /// Helper: Check if user is interested in topics
  bool _isInterested(UserModel user, List<String> topics) {
    // Implement user interests/preferences system
    // For now, check user role and bio
    final bioLower = user.bio?.toLowerCase() ?? '';
    for (final topic in topics) {
      if (bioLower.contains(topic.toLowerCase())) return true;
    }
    return false;
  }

  /// 8. Trust score is directly from post.communityTrustScore

  /// 9. Recency score
  double _calculateRecencyScore(FightWirePost post) {
    final now = DateTime.now();
    final age = now.difference(post.createdAt);

    // Decay curve: fresh content gets bonus
    // 0-1h: 1.0
    // 1-6h: 0.8
    // 6-24h: 0.5
    // 24-72h: 0.3
    // 72h+: 0.1
    if (age.inHours < 1) return 1.0;
    if (age.inHours < 6) return 0.8;
    if (age.inHours < 24) return 0.5;
    if (age.inHours < 72) return 0.3;
    return 0.1;
  }

  /// 10. Impact potential score
  double _calculateImpactScore(FightWirePost post) {
    // Campaign posts have high impact potential
    if (post.campaignId != null) return 1.0;

    // Opportunity posts create value
    if (post.type == FightWirePostType.opportunity) return 0.9;

    // Charity and community posts
    if (post.type == FightWirePostType.charity) return 0.8;

    // Knowledge sharing
    if (post.type == FightWirePostType.knowledge) return 0.7;

    // Events bring people together
    if (post.type == FightWirePostType.event) return 0.6;

    return 0.5; // Default impact
  }

  /// 11. TRIBE v2 Brain Engagement — neural resonance scoring
  Future<double> _calculateBrainEngagementScore(FightWirePost post) async {
    try {
      final tribe = TribeBrainEncoderService();
      if (!tribe.initialized) return 0.5; // neutral if not booted

      // Map FightWirePostType to TRIBE content type
      final contentType = switch (post.type) {
        FightWirePostType.fight => 'fight_clip',
        FightWirePostType.training => 'training',
        FightWirePostType.event => 'promo',
        FightWirePostType.knowledge => 'corner_audio',
        FightWirePostType.livestream => 'highlight',
        _ => 'fight_clip',
      };

      final prediction = await tribe.predictBrainResponse(
        contentId: post.id,
        contentType: contentType,
        textContent: post.content,
        mediaUrl: post.mediaUrls.isNotEmpty ? post.mediaUrls.first : null,
      );
      // Normalize resonanceScore (0-100) to 0.0-1.0
      return (prediction.resonanceScore / 100).clamp(0.0, 1.0);
    } catch (_) {
      return 0.5; // neutral fallback
    }
  }

  /// Rank a list of posts for a user's feed
  Future<List<FightWirePost>> rankFeed({
    required List<FightWirePost> posts,
    required UserModel currentUser,
    required List<UserRelationship> relationships,
    GeoPoint? userLocation,
  }) async {
    // Calculate scores for all posts
    final scoredPosts = <MapEntry<FightWirePost, double>>[];

    for (final post in posts) {
      final score = await calculateRelevanceScore(
        post: post,
        currentUser: currentUser,
        relationships: relationships,
        userLocation: userLocation,
      );
      scoredPosts.add(MapEntry(post, score));
    }

    // Sort by score descending
    scoredPosts.sort((a, b) => b.value.compareTo(a.value));

    // Return ranked posts
    return scoredPosts.map((entry) => entry.key).toList();
  }

  /// Get personalized feed with FRIEND-FIRST PRIORITY
  ///
  /// Feed Priority (Like Water 🌊):
  /// 1. Friends posts (mutual connections)
  /// 2. Followed fighters (athletes you follow)
  /// 3. Local gyms (within 20km)
  /// 4. Promotions (verified promoters)
  /// 5. Global content (everything else)
  Future<List<FightWirePost>> getPersonalizedFeed({
    required String userId,
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    // Fetch user data
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return [];
    final currentUser = UserModel.fromFirestore(userDoc);

    // Fetch user relationships
    final relationshipsSnap = await _firestore
        .collection('user_relationships')
        .where('userId', isEqualTo: userId)
        .get();
    final relationships = relationshipsSnap.docs
        .map(UserRelationship.fromFirestore)
        .toList();

    // Get user's location if available
    GeoPoint? userLocation;
    if (currentUser.metadata != null) {
      final lat = currentUser.metadata!['latitude'] as double?;
      final lng = currentUser.metadata!['longitude'] as double?;
      if (lat != null && lng != null) {
        userLocation = GeoPoint(lat, lng);
      }
    }

    // Fetch recent posts (last 7 days) from network
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    Query<Map<String, dynamic>> query = _firestore
        .collection('posts')
        .where('timestamp', isGreaterThan: sevenDaysAgo)
        .orderBy('timestamp', descending: true)
        .limit(limit * 5); // Fetch more to ensure each tier has content

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final postsSnap = await query.get();
    final allPosts = postsSnap.docs.map(FightWirePost.fromFirestore).toList();

    // ═══════════════════════════════════════════════════════════════════════
    // FRIEND-FIRST FEED PRIORITY SYSTEM 🌊
    // ═══════════════════════════════════════════════════════════════════════

    // Get friend IDs (mutual connections)
    final friendIds = relationships
        .where((r) => r.type == RelationshipType.friend && r.isMutual)
        .map((r) => r.targetUserId)
        .toSet();

    // Get followed fighter IDs
    final followedFighterIds = relationships
        .where(
          (r) =>
              r.type == RelationshipType.following ||
              r.type == RelationshipType.fan,
        )
        .map((r) => r.targetUserId)
        .toSet();

    // Separate posts into priority tiers
    final tier1Friends = <FightWirePost>[];
    final tier2Fighters = <FightWirePost>[];
    final tier3LocalGyms = <FightWirePost>[];
    final tier4Promotions = <FightWirePost>[];
    final tier5Global = <FightWirePost>[];

    for (final post in allPosts) {
      // Tier 1: Friends posts (HIGHEST PRIORITY)
      if (friendIds.contains(post.authorId)) {
        tier1Friends.add(post);
      }
      // Tier 2: Followed fighters
      else if (followedFighterIds.contains(post.authorId) &&
          (post.authorRole == 'fighter' || post.authorRole == 'coach')) {
        tier2Fighters.add(post);
      }
      // Tier 3: Local gyms (within 20km)
      else if (post.gymId != null &&
          userLocation != null &&
          post.lat != null &&
          post.lng != null) {
        final distance = _distanceInMeters(
          userLocation.latitude,
          userLocation.longitude,
          post.lat!,
          post.lng!,
        );
        if (distance < 20000) {
          tier3LocalGyms.add(post);
        } else {
          tier5Global.add(post);
        }
      }
      // Tier 4: Promotions (verified promoters)
      else if (post.authorRole == 'promoter' && post.isVerified) {
        tier4Promotions.add(post);
      }
      // Tier 5: Everything else
      else {
        tier5Global.add(post);
      }
    }

    // Rank posts within each tier using the 10-factor algorithm
    final rankedTier1 = await rankFeed(
      posts: tier1Friends,
      currentUser: currentUser,
      relationships: relationships,
      userLocation: userLocation,
    );
    final rankedTier2 = await rankFeed(
      posts: tier2Fighters,
      currentUser: currentUser,
      relationships: relationships,
      userLocation: userLocation,
    );
    final rankedTier3 = await rankFeed(
      posts: tier3LocalGyms,
      currentUser: currentUser,
      relationships: relationships,
      userLocation: userLocation,
    );
    final rankedTier4 = await rankFeed(
      posts: tier4Promotions,
      currentUser: currentUser,
      relationships: relationships,
      userLocation: userLocation,
    );
    final rankedTier5 = await rankFeed(
      posts: tier5Global,
      currentUser: currentUser,
      relationships: relationships,
      userLocation: userLocation,
    );

    // Combine tiers in order: Friends → Followed → Local → Promos → Global
    final finalFeed = [
      ...rankedTier1,
      ...rankedTier2,
      ...rankedTier3,
      ...rankedTier4,
      ...rankedTier5,
    ];

    // Return top N posts
    return finalFeed.take(limit).toList();
  }

  static List<String> _userFightingStyles(UserModel user) {
    final raw = user.metadata?['fightingStyles'];
    if (raw is List) {
      return raw.whereType<String>().toList();
    }
    return const [];
  }

  static double _distanceInMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degree) => degree * pi / 180.0;
}
