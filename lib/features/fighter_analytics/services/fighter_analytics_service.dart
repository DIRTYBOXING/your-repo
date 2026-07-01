import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fighter_performance.dart';

/// Service to fetch and calculate fighter analytics and performance metrics
class FighterAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get comprehensive performance data for a fighter
  Future<FighterPerformance> getFighterPerformance(String fighterId) async {
    try {
      final doc = await _firestore
          .collection('fighter_stats')
          .doc(fighterId)
          .get();

      if (!doc.exists) {
        return FighterPerformance(fighterId: fighterId);
      }

      final data = doc.data() as Map<String, dynamic>;

      // Fetch recent fights
      final fightsSnap = await _firestore
          .collection('fights')
          .where('fighter_ids', arrayContains: fighterId)
          .orderBy('date', descending: true)
          .limit(10)
          .get();

      final recentFights = fightsSnap.docs
          .map((doc) => _parseFightRecord(doc.data()))
          .toList();

      return FighterPerformance(
        fighterId: fighterId,
        totalFights: data['total_fights'] as int? ?? 0,
        wins: data['wins'] as int? ?? 0,
        losses: data['losses'] as int? ?? 0,
        draws: data['draws'] as int? ?? 0,
        winRate: data['win_rate'] as double? ?? 0.0,
        knockouts: data['knockouts'] as int? ?? 0,
        submissions: data['submissions'] as int? ?? 0,
        decisions: data['decisions'] as int? ?? 0,
        avgRoundDuration: data['avg_round_duration'] as double? ?? 0.0,
        strikeAccuracy: data['strike_accuracy'] as double? ?? 0.0,
        takedownDefense: data['takedown_defense'] as double? ?? 0.0,
        controlTime: data['control_time'] as double? ?? 0.0,
        currentWinStreak: data['current_win_streak'] as int? ?? 0,
        longestWinStreak: data['longest_win_streak'] as int? ?? 0,
        lastFightDate: (data['last_fight_date'] as Timestamp?)?.toDate(),
        rating: data['rating'] as double? ?? 1500.0,
        recentFights: recentFights,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get performance trends over time
  Future<List<PerformanceTrend>> getPerformanceTrends(
    String fighterId, {
    int months = 12,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: months * 30));

      final fightsSnap = await _firestore
          .collection('fights')
          .where('fighter_ids', arrayContains: fighterId)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .orderBy('date', descending: false)
          .get();

      final trends = <PerformanceTrend>[];
      int cumulativeWins = 0;

      for (final doc in fightsSnap.docs) {
        final data = doc.data();
        final result = data['result'] as String?;

        if (result == 'WIN') cumulativeWins++;

        final date = (data['date'] as Timestamp?)?.toDate();
        if (date == null) continue;

        trends.add(
          PerformanceTrend(
            date: date,
            cumulativeWins: cumulativeWins,
            strikeAccuracy: data['strike_accuracy'] as double? ?? 0.0,
            takedownDefense: data['takedown_defense'] as double? ?? 0.0,
          ),
        );
      }

      return trends;
    } catch (e) {
      rethrow;
    }
  }

  /// Compare two fighters' stats
  Future<FighterComparison> compareFighters(
    String fighterId1,
    String fighterId2,
  ) async {
    try {
      final perf1 = await getFighterPerformance(fighterId1);
      final perf2 = await getFighterPerformance(fighterId2);

      return FighterComparison(fighter1: perf1, fighter2: perf2);
    } catch (e) {
      rethrow;
    }
  }

  FightRecord _parseFightRecord(Map<String, dynamic> data) {
    return FightRecord(
      fightId: data['id'] as String? ?? '',
      opponent: data['opponent'] as String? ?? '',
      result: data['result'] as String? ?? 'DRAW',
      method: data['method'] as String? ?? 'DECISION',
      roundEnded: data['round_ended'] as int? ?? 0,
      timeInRound: data['time_in_round'] as String? ?? '0:00',
      fightDate: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      event: data['event'] as String? ?? '',
      opponent1Strikes: data['opponent1_strikes'] as String? ?? '',
      opponent2Strikes: data['opponent2_strikes'] as String? ?? '',
    );
  }

  /// Stream live fighter ranking update
  Stream<List<FighterRanking>> streamFighterRankings(String division) {
    return _firestore
        .collection('rankings')
        .doc(division)
        .collection('fighters')
        .orderBy('rank', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => FighterRanking.fromFirestore(doc.data()))
              .toList(),
        );
  }
}

/// Performance trend for chart rendering
class PerformanceTrend {
  final DateTime date;
  final int cumulativeWins;
  final double strikeAccuracy;
  final double takedownDefense;

  PerformanceTrend({
    required this.date,
    required this.cumulativeWins,
    required this.strikeAccuracy,
    required this.takedownDefense,
  });
}

/// Fighter comparison data
class FighterComparison {
  final FighterPerformance fighter1;
  final FighterPerformance fighter2;

  FighterComparison({required this.fighter1, required this.fighter2});

  double get winRateDiff => fighter1.winRate - fighter2.winRate;
  double get strikeAccuracyDiff =>
      fighter1.strikeAccuracy - fighter2.strikeAccuracy;
  double get takedownDefenseDiff =>
      fighter1.takedownDefense - fighter2.takedownDefense;
  double get ratingDiff => fighter1.rating - fighter2.rating;
}

/// Fighter ranking data
class FighterRanking {
  final String fighterId;
  final String name;
  final int rank;
  final double rating;
  final int winsInDivision;
  final int lossesInDivision;

  FighterRanking({
    required this.fighterId,
    required this.name,
    required this.rank,
    required this.rating,
    required this.winsInDivision,
    required this.lossesInDivision,
  });

  factory FighterRanking.fromFirestore(Map<String, dynamic> data) {
    return FighterRanking(
      fighterId: data['fighter_id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      rank: data['rank'] as int? ?? 0,
      rating: data['rating'] as double? ?? 1500.0,
      winsInDivision: data['wins_in_division'] as int? ?? 0,
      lossesInDivision: data['losses_in_division'] as int? ?? 0,
    );
  }
}
