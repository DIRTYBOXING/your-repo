class SmartCoachModel {
  final String title;
  final String duration;
  final String description;
  final String opponent;
  final int winProbability;
  final String workloadStatus;

  SmartCoachModel({
    required this.title,
    required this.duration,
    required this.description,
    required this.opponent,
    required this.winProbability,
    required this.workloadStatus,
  });

  factory SmartCoachModel.fromJson(Map<String, dynamic> json) {
    return SmartCoachModel(
      title: json['title'] ?? 'ACTIVE RECOVERY',
      duration: json['duration'] ?? '45m',
      description:
          json['description'] ??
          'Mobility (30m), Zone 2 (45m). Optimized for elevated acute load.',
      opponent: json['opponent'] ?? 'Kai Johnson',
      winProbability: json['winProbability'] ?? 74,
      workloadStatus: json['workloadStatus'] ?? 'ELEVATED (High Risk)',
    );
  }
}
