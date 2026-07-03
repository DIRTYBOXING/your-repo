class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int? unlockedAt;
  final int progress;
  final int target;

  bool get isUnlocked => unlockedAt != null || progress >= target;

  AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.unlockedAt,
    this.progress = 0,
    this.target = 1,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) =>
      AchievementModel(
        id: json['id'] ?? '',
        title: json['title'] ?? 'Unknown Achievement',
        description: json['description'] ?? '',
        icon: json['icon'] ?? 'emoji_events',
        unlockedAt: json['unlockedAt'],
        progress: json['progress'] ?? 0,
        target: json['target'] ?? 1,
      );
}
