import '../entities/health_metric.dart';

abstract class HealthRepository {
  Future<HealthMetric?> getLatestMetric(String fighterId);
  Future<void> saveMetric(HealthMetric metric);
}
