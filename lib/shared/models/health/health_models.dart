class HealthLog {
  final String userId;
  final DateTime date;
  final int sleepHours;
  final double weight;
  final int heartRate;
  final int stressLevel;
  final int hydrationLevel;
  final int trainingIntensity;
  final String mood;

  HealthLog({
    required this.userId,
    required this.date,
    required this.sleepHours,
    required this.weight,
    required this.heartRate,
    required this.stressLevel,
    required this.hydrationLevel,
    required this.trainingIntensity,
    required this.mood,
  });
}

class AIInsight {
  final String userId;
  final String insightType;
  final String insight;
  final DateTime date;

  AIInsight({
    required this.userId,
    required this.insightType,
    required this.insight,
    required this.date,
  });
}
