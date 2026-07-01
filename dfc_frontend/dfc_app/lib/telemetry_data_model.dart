class TelemetryDataModel {
  final double punchVelocity; // mph or m/s
  final double punchAccuracy; // percentage
  final int punchesThrown;
  final int headMovementCount; // slips, weaves, bobs
  final double reactionTime; // milliseconds
  final String hitMissRatio;
  final int heartRate;
  final String fatigueLevel; // Optimal, Moderate, High

  TelemetryDataModel({
    required this.punchVelocity,
    required this.punchAccuracy,
    required this.punchesThrown,
    required this.headMovementCount,
    required this.reactionTime,
    required this.hitMissRatio,
    required this.heartRate,
    required this.fatigueLevel,
  });

  // The "Bionic Score" - an aggregate combat efficiency rating
  int get bionicScore => ((punchAccuracy * 100) + (1000 / reactionTime) + (headMovementCount / 2)).clamp(0, 100).toInt();
}