class Fighter {
  Fighter({
    required this.id,
    required this.name,
    required this.rankScore,
    required this.pastPerformanceScore,
    required this.styleMatchupScore,
    required this.healthScore,
    required this.trainingCampScore,
  });

  final String id;
  final String name;
  final double rankScore;
  final double pastPerformanceScore;
  final double styleMatchupScore;
  final double healthScore;
  final double trainingCampScore;
}
