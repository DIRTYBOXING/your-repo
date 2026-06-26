import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// AI & CONTENT SERVICE
/// Connects Flutter to Module 6 (Social Feed, AI Insights, Telemetry)
/// ═══════════════════════════════════════════════════════════════════════════
class AiContentService extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;

  /// Fetch the main global feed (News, Promos, Clips)
  Future<List<Map<String, dynamic>>> getMainFeed() async {
    try {
      final snap = await _firestore
          .collection('feed_posts')
          .orderBy('priority', descending: true)
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();

      // Manually resolve relational profile data since NoSQL lacks SQL joins
      List<Map<String, dynamic>> posts = [];
      for (var doc in snap.docs) {
        final data = doc.data();
        final authorId = data['author_id'] ?? data['authorId'];
        if (authorId != null) {
          final profileDoc = await _firestore
              .collection('users')
              .doc(authorId)
              .get();
          if (profileDoc.exists) {
            data['profiles'] = {
              'display_name': profileDoc.data()?['displayName'] ?? 'Fighter',
              'avatar_url':
                  profileDoc.data()?['photoUrl'] ??
                  profileDoc.data()?['avatar_url'],
            };
          }
        }
        posts.add(data);
      }
      return posts;
    } catch (e) {
      debugPrint('Error fetching feed: $e');
      return [];
    }
  }

  /// Fetch AI Insights for a specific fighter (Used in Neural Coach)
  Future<List<Map<String, dynamic>>> getFighterInsights(
    String fighterId,
  ) async {
    try {
      final snap = await _firestore
          .collection('ai_insights')
          .where('fighter_id', isEqualTo: fighterId)
          .orderBy('created_at', descending: true)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('Error fetching AI insights: $e');
      return [];
    }
  }
}
