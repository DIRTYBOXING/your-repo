import '../entities/ranking.dart';

abstract class RankingsRepository {
  Future<List<Ranking>> getDivisionRankings(String division);
  Future<void> saveDivisionRankings(String division, List<Ranking> rankings);
}
