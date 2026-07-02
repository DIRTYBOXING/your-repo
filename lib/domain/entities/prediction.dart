class Prediction {
  Prediction({
    required this.eventId,
    required this.fighterAId,
    required this.fighterBId,
    required this.probabilityA,
    required this.probabilityB,
    required this.confidence,
    required this.modelVersion,
  });

  final String eventId;
  final String fighterAId;
  final String fighterBId;
  final double probabilityA;
  final double probabilityB;
  final double confidence;
  final String modelVersion;
}
