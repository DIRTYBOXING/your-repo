class WeightCutModel {
  final double currentWeight;
  final double targetWeight;
  final double waterIntake;
  final double waterTarget;
  final int carbsLimit;
  final int sodiumLimit;
  final String phase;

  WeightCutModel({
    required this.currentWeight,
    required this.targetWeight,
    required this.waterIntake,
    required this.waterTarget,
    required this.carbsLimit,
    required this.sodiumLimit,
    required this.phase,
  });

  factory WeightCutModel.fromJson(Map<String, dynamic> json) {
    return WeightCutModel(
      currentWeight: (json['currentWeight'] ?? 164.2).toDouble(),
      targetWeight: (json['targetWeight'] ?? 155.0).toDouble(),
      waterIntake: (json['waterIntake'] ?? 1.5).toDouble(),
      waterTarget: (json['waterTarget'] ?? 3.0).toDouble(),
      carbsLimit: json['carbsLimit'] ?? 30,
      sodiumLimit: json['sodiumLimit'] ?? 500,
      phase: json['phase'] ?? 'Water Loading (Day 3)',
    );
  }
}
