import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/fightwire_post.dart';
import '../models/dfc_campaign.dart';

/// NightChill Integration Service
///
/// Integrates NightChill partnership content into the DFC ecosystem:
/// - Trauma recovery support posts
/// - Sobriety milestones and support
/// - Mental health resources
/// - Pink Shield campaign integration (🛡️)
/// - Coffee Campaign community support (☕)
/// - Safe space content moderation
///
/// NightChill focuses on healing and recovery for combat athletes and community
/// members dealing with trauma, addiction, and mental health challenges.
class NightChillIntegrationService {
  final FirebaseFirestore _firestore;
  final String? nightChillApiKey;
  final String? nightChillApiUrl;

  NightChillIntegrationService({
    FirebaseFirestore? firestore,
    this.nightChillApiKey,
    this.nightChillApiUrl,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetch NightChill partnership content
  Future<List<FightWirePost>> fetchNightChillContent({int limit = 10}) async {
    try {
      // Fetch from Firestore (content synced from NightChill API)
      final snapshot = await _firestore
          .collection('posts')
          .where('source', isEqualTo: 'nightchill')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(FightWirePost.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error fetching NightChill content: $e');
      return [];
    }
  }

  /// Sync NightChill content from API (if available)
  Future<void> syncNightChillContent() async {
    if (nightChillApiUrl == null || nightChillApiKey == null) {
      debugPrint('NightChill API credentials not configured');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$nightChillApiUrl/api/content/recent'),
        headers: {
          'Authorization': 'Bearer $nightChillApiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final posts = data['posts'] as List<dynamic>;

        // Convert to FightWirePost and store in Firestore
        for (final postData in posts) {
          await _syncSinglePost(postData as Map<String, dynamic>);
        }

        debugPrint('✅ NightChill content synced: ${posts.length} posts');
      } else {
        debugPrint('❌ NightChill API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error syncing NightChill content: $e');
    }
  }

  /// Sync a single post from NightChill
  Future<void> _syncSinglePost(Map<String, dynamic> postData) async {
    try {
      final post = FightWirePost(
        id: postData['id'] as String,
        authorId: postData['authorId'] as String,
        authorName: postData['authorName'] as String,
        authorRole: (postData['authorRole'] as String?) ?? 'fan',
        authorAvatarUrl: postData['authorAvatar'] as String?,
        content: postData['content'] as String,
        type: _mapNightChillPostType(postData['type'] as String),
        source: PostSource.nightchill,
        createdAt: DateTime.parse(postData['timestamp'] as String),
        campaignId: postData['campaignId'] as String?,
        mediaUrls:
            ((postData['mediaUrls'] as List<dynamic>?)
                ?.map((url) => url as String)
                .toList()) ??
            const <String>[],
        communityTrustScore: 0.85, // NightChill content is pre-moderated
        impactMetrics:
            postData['metadata'] as Map<String, dynamic>? ?? const {},
        isSocialImpact: (postData['campaignId'] as String?) != null,
      );

      // Store in Firestore
      await _firestore.collection('posts').doc(post.id).set(post.toFirestore());
    } catch (e) {
      debugPrint('Error syncing single NightChill post: $e');
    }
  }

  /// Map NightChill post types to DFC post types
  FightWirePostType _mapNightChillPostType(String nightChillType) {
    switch (nightChillType.toLowerCase()) {
      case 'recovery':
      case 'support':
        return FightWirePostType.knowledge;
      case 'milestone':
        return FightWirePostType.announcement;
      case 'event':
        return FightWirePostType.event;
      case 'campaign':
        return FightWirePostType.charity;
      default:
        return FightWirePostType.knowledge;
    }
  }

  /// Get Pink Shield campaign posts (trauma recovery)
  Future<List<FightWirePost>> getPinkShieldPosts({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('campaignId', isEqualTo: 'pink_shield')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(FightWirePost.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error fetching Pink Shield posts: $e');
      return [];
    }
  }

  /// Get Coffee Campaign posts (community support)
  Future<List<FightWirePost>> getCoffeeCampaignPosts({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('campaignId', isEqualTo: 'coffee_campaign')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(FightWirePost.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error fetching Coffee Campaign posts: $e');
      return [];
    }
  }

  /// Create a sobriety milestone post
  Future<String?> createSobrietyMilestone({
    required String userId,
    required String userName,
    required int daysSober,
    String? message,
    String? userAvatar,
  }) async {
    try {
      final post = FightWirePost(
        id: '',
        authorId: userId,
        authorName: userName,
        authorRole: 'fan',
        authorAvatarUrl: userAvatar,
        content: message ?? '🌙 $daysSober days sober. One day at a time. 💪',
        type: FightWirePostType.announcement,
        source: PostSource.nightchill,
        createdAt: DateTime.now(),
        campaignId: 'nightchill',
        communityTrustScore: 0.9,
        impactMetrics: {'milestoneType': 'sobriety', 'daysSober': daysSober},
        isSocialImpact: true,
      );

      final docRef = await _firestore
          .collection('posts')
          .add(post.toFirestore());

      // Award badge if milestone is significant
      if (daysSober == 30 ||
          daysSober == 90 ||
          daysSober == 180 ||
          daysSober == 365) {
        await _awardSobrietyBadge(userId, daysSober);
      }

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating sobriety milestone: $e');
      return null;
    }
  }

  /// Award sobriety milestone badge
  Future<void> _awardSobrietyBadge(String userId, int daysSober) async {
    try {
      String badgeName;
      if (daysSober >= 365) {
        badgeName = 'Sober Warrior - 1 Year';
      } else if (daysSober >= 180) {
        badgeName = 'Sober Warrior - 6 Months';
      } else if (daysSober >= 90) {
        badgeName = 'Sober Warrior - 90 Days';
      } else {
        badgeName = 'Sober Warrior - 30 Days';
      }

      await _firestore.collection('users').doc(userId).update({
        'badges': FieldValue.arrayUnion([badgeName]),
      });

      debugPrint('✅ Awarded badge: $badgeName to user $userId');
    } catch (e) {
      debugPrint('Error awarding sobriety badge: $e');
    }
  }

  /// Create a trauma recovery support post
  Future<String?> createRecoveryPost({
    required String userId,
    required String userName,
    required String content,
    String? userAvatar,
    bool anonymous = false,
  }) async {
    try {
      final post = FightWirePost(
        id: '',
        authorId: userId,
        authorName: anonymous ? 'Anonymous Warrior' : userName,
        authorRole: 'fan',
        authorAvatarUrl: anonymous ? null : userAvatar,
        content: '🛡️ $content',
        type: FightWirePostType.knowledge,
        source: PostSource.nightchill,
        createdAt: DateTime.now(),
        campaignId: 'pink_shield',
        communityTrustScore: 0.9,
        impactMetrics: {
          'supportType': 'trauma_recovery',
          'anonymous': anonymous,
        },
        isSocialImpact: true,
      );

      final docRef = await _firestore
          .collection('posts')
          .add(post.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating recovery post: $e');
      return null;
    }
  }

  /// Get mental health resources
  Future<List<Map<String, dynamic>>> getMentalHealthResources({
    String? region, // 'AU' for Australia, 'NZ' for New Zealand
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('mental_health_resources')
          .where('active', isEqualTo: true);

      if (region != null) {
        query = query.where('region', isEqualTo: region);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error fetching mental health resources: $e');
      return [];
    }
  }

  /// Report a concern for NightChill moderators
  Future<bool> reportConcern({
    required String reporterId,
    required String concernType, // 'self_harm', 'crisis', 'support_needed'
    required String description,
    String? relatedUserId,
    String? relatedPostId,
  }) async {
    try {
      await _firestore.collection('nightchill_concerns').add({
        'reporterId': reporterId,
        'concernType': concernType,
        'description': description,
        'relatedUserId': relatedUserId,
        'relatedPostId': relatedPostId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'priority': concernType == 'crisis' ? 'urgent' : 'normal',
      });

      // Send urgent notification if crisis
      if (concernType == 'crisis') {
        await _notifyNightChillModerators(reporterId, description);
      }

      return true;
    } catch (e) {
      debugPrint('Error reporting concern: $e');
      return false;
    }
  }

  /// Notify NightChill moderators of urgent concerns
  Future<void> _notifyNightChillModerators(
    String reporterId,
    String description,
  ) async {
    try {
      // Send notification to moderators topic
      await _firestore.collection('notifications').add({
        'topic': 'nightchill_moderators',
        'title': '🚨 Urgent: Crisis Report',
        'body':
            'A user has reported a crisis situation. Immediate attention required.',
        'priority': 'high',
        'timestamp': FieldValue.serverTimestamp(),
        'sent': false,
        'data': {'reporterId': reporterId, 'type': 'crisis'},
      });
    } catch (e) {
      debugPrint('Error notifying moderators: $e');
    }
  }

  /// Get campaign statistics for NightChill campaigns
  Future<Map<String, dynamic>> getCampaignStats(String campaignId) async {
    try {
      final campaignDoc = await _firestore
          .collection('campaigns')
          .doc(campaignId)
          .get();

      if (!campaignDoc.exists) {
        return {};
      }

      final campaign = DfcCampaign.fromFirestore(campaignDoc);

      // Get post count
      final postsCount = await _firestore
          .collection('posts')
          .where('campaignId', isEqualTo: campaignId)
          .count()
          .get();

      // Get donation stats
      final donationsSnap = await _firestore
          .collection('donations')
          .where('campaignId', isEqualTo: campaignId)
          .get();

      return {
        'campaignId': campaign.id,
        'name': campaign.name,
        'type': campaign.type.toString(),
        'goalAmount': campaign.goalAmount,
        'raisedAmount': campaign.raisedAmount,
        'progressPercentage': campaign.progressPercentage,
        'beneficiaries': campaign.beneficiaries,
        'postsCount': postsCount.count,
        'donationsCount': donationsSnap.docs.length,
        'status': campaign.status.toString(),
      };
    } catch (e) {
      debugPrint('Error fetching campaign stats: $e');
      return {};
    }
  }
}
