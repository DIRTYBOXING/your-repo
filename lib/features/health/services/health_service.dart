class HealthService {
  Future<Map<String, dynamic>> loadCampReadiness(String fighterId) async {
    return {
      'fighterId': fighterId,
      'readiness': 0.0,
      'recovery': 0.0,
      'injuryRisk': 0.0,
    };
  }
}
