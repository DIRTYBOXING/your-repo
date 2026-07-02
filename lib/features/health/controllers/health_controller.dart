import '../services/health_service.dart';

class HealthController {
  HealthController(this.service);

  final HealthService service;

  Future<Map<String, dynamic>> load(String fighterId) => service.loadCampReadiness(fighterId);
}
