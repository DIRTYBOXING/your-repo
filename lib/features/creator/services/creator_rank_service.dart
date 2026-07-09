import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'creator_firestore_adapter.dart';

/// Creator ranking system
/// Calculates and manages creator ranks based on earnings, clips, engagement
class CreatorRankService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CreatorFirestoreAdapter _adapter;

  CreatorRankService() {
    _adapter = CreatorFirestoreAdapter();
  }

  /// Get global rank for a creator
  Future<int> getCreatorRank(String creatorId) async {
    try {
      final doc = await _firestore
          .collection('creator_dashboards')
          .doc(creatorId)
          .collection('ranking')
          .doc('global')
          .get();

      return doc.data()?['rank'] ?? 9999;
    } catch (e) {
      debugPrint('❌ Error getting creator rank: $e');
      return 9999;
    }
  }

  /// Subscribe to ranking stream (Phase 2B)
  Stream<Map<String, dynamic>?> getRankingStream(String creatorId) {
    return _adapter.rankingStream(creatorId);
  }

  /// Get top creators (leaderboard)
  /// Note: Requires a cloud function or backend service to maintain leaderboard
  Future<List<Map<String, dynamic>>> getTopCreators({
    int limit = 50,
    String sortBy = 'earnings', // earnings, followers, trendingScore
  }) async {
    try {
      // Fetch from leaderboard collection (maintained by backend service)
      final snapshot = await _firestore
          .collection('creator_leaderboards')
          .doc('global')
          .collection('rankings')
          .orderBy(sortBy, descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'creatorId': data['creatorId'] ?? '',
          'displayName': data['displayName'] ?? '',
          'rank': data['rank'] ?? 9999,
          'earnings': data['earnings'] ?? 0.0,
          'followers': data['followers'] ?? 0,
          'trendingScore': data['trendingScore'] ?? 0.0,
          'avatarUrl': data['avatarUrl'],
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting top creators: $e');
      return [];
    }
  }

  /// Get creator rank by category
  Future<int> getCreatorRankByCategory(
    String creatorId,
    String category, // analysts, fighters, coaches, etc.
  ) async {
    try {
      final doc = await _firestore
          .collection('creator_dashboards')
          .doc(creatorId)
          .collection('ranking')
          .doc('category_$category')
          .get();

      return doc.data()?['rank'] ?? 9999;
    } catch (e) {
      debugPrint('❌ Error getting creator rank by category: $e');
      return 9999;
    }
  }

  /// Calculate trending score for a creator (Phase 2B — uses real Firestore clips)
  Future<double> calculateTrendingScore(String creatorId) async {
    try {
      // Fetch recent clips from creator's clips collection
      final clipsSnapshot = await _firestore
          .collection('creator_dashboards')
          .doc(creatorId)
          .collection('clips')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      if (clipsSnapshot.docs.isEmpty) return 0.0;

      // Calculate weighted trending score from recent clips
      var totalScore = 0.0;
      for (final doc in clipsSnapshot.docs) {
        final trendingScore =
            (doc.data()['trendingScore'] as num?)?.toDouble() ?? 0.0;
        totalScore += trendingScore;
      }

      final avgScore = totalScore / clipsSnapshot.docs.length;
      return avgScore.clamp(0.0, 10.0);
    } catch (e) {
      debugPrint('❌ Error calculating trending score: $e');
      return 0.0;
    }
  }

  /// Get creator ranking info (rank, percentile, nearby creators)
  Future<Map<String, dynamic>> getCreatorRankingInfo(String creatorId) async {
    try {
      final rank = await getCreatorRank(creatorId);
      final trendingScore = await calculateTrendingScore(creatorId);

      // Get total creator count for percentile calculation
      final totalCreatorsSnapshot = await _firestore
          .collection('creator_dashboards')
          .count()
          .get();
      final totalCreators = totalCreatorsSnapshot.count ?? 10000;

      // Calculate percentile
      final percentile = ((totalCreators - rank) / totalCreators) * 100;

      // Get nearby creators (rank - 2 to rank + 2)
      final nearbySnapshot = await _firestore
          .collectionGroup('ranking')
          .where('rank', isGreaterThanOrEqualTo: rank - 2)
          .where('rank', isLessThanOrEqualTo: rank + 2)
          .orderBy('rank')
          .get();

      final nearbyCreators = nearbySnapshot.docs
          .map((doc) => doc.data()['displayName'] ?? 'Unknown')
          .toList();

      return {
        'rank': rank,
        'trendingScore': trendingScore,
        'percentile': percentile.toStringAsFixed(1),
        'totalCreators': totalCreators,
        'nearbyCreators': nearbyCreators,
        'rankStatus': _getRankStatus(rank),
      };
    } catch (e) {
      debugPrint('❌ Error getting ranking info: $e');
      return {};
    }
  }

  /// Update creator rank (called by admin/backend)
  Future<void> updateCreatorRank(String creatorId, int newRank) async {
    try {
      await _firestore
          .collection('creator_dashboards')
          .doc(creatorId)
          .collection('ranking')
          .doc('global')
          .set({
            'creatorId': creatorId,
            'rank': newRank,
            'updatedAt': FieldValue.serverTimestamp(),
            'globalRanking': true,
          }, SetOptions(merge: true));

      notifyListeners();
      debugPrint('✅ Updated rank for $creatorId: $newRank');
    } catch (e) {
      debugPrint('❌ Error updating creator rank: $e');
    }
  }

  /// Recalculate all creator ranks
  Future<void> recalculateAllRanks() async {
    try {
      debugPrint('🔄 Recalculating all creator ranks...');

      // Get all creators sorted by performance
      final snapshot = await _firestore.collection('creator_dashboards').get();

      // Sort by earnings + followers + trending
      final creators = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'creatorId': doc.id,
          'earnings': (data['totalEarnings'] ?? 0.0) as double,
          'followers': (data['followerCount'] ?? 0) as int,
          'trending': (data['trendingScore'] ?? 0.0) as double,
        };
      }).toList();

      // Calculate performance score and sort
      creators.sort((a, b) {
        final scoreA =
            (a['earnings'] as double) * 0.5 +
            (a['followers'] as int) * 0.1 +
            (a['trending'] as double) * 10;
        final scoreB =
            (b['earnings'] as double) * 0.5 +
            (b['followers'] as int) * 0.1 +
            (b['trending'] as double) * 10;
        return scoreB.compareTo(scoreA);
      });

      // Write updated ranks
      var batch = _firestore.batch();
      for (int i = 0; i < creators.length; i++) {
        final creatorId = creators[i]['creatorId'] as String;
        final newRank = i + 1;

        batch.set(
          _firestore
              .collection('creator_dashboards')
              .doc(creatorId)
              .collection('ranking')
              .doc('global'),
          {'rank': newRank, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );

        // Batch write every 50 documents
        if ((i + 1) % 50 == 0) {
          await batch.commit();
          batch = _firestore.batch();
        }
      }

      await batch.commit();
      debugPrint('✅ Ranks recalculated for ${creators.length} creators');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error recalculating ranks: $e');
    }
  }

  /// Get rank status badge
  String _getRankStatus(int rank) {
    if (rank <= 10) return '🏆 ELITE';
    if (rank <= 100) return '⭐ TOP 100';
    if (rank <= 500) return '🌟 TOP 500';
    if (rank <= 1000) return '💪 TOP 1K';
    return '📈 RISING';
  }
}
