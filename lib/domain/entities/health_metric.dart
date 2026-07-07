class HealthMetric {
  HealthMetric({
    required this.fighterId,
    required this.readiness,
    required this.recovery,
    required this.injuryRisk,
    required this.recordedAt,
  });

  final String fighterId;
  final double readiness;
  final double recovery;
  final double injuryRisk;
  final DateTime recordedAt;
}
