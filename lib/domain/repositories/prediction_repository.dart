import '../entities/fighter.dart';

abstract class PredictionRepository {
  Future<List<Fighter>> getFightersForEvent(String eventId);
  Future<Map<String, double>> getStatsForEvent(String eventId);
}
