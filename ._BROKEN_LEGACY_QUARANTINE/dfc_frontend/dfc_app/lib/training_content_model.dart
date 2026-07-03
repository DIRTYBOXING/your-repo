class TrainingContentModel {
  final String id;
  final String creatorId;
  final String title;
  final String description;
  final String thumbnailUrl;
  final bool isPremium;
  final String category;
  final String duration;
  final String scope; // the entitlement requirement

  TrainingContentModel({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.isPremium,
    required this.category,
    required this.duration,
    required this.scope,
  });

  factory TrainingContentModel.fromJson(Map<String, dynamic> json) =>
      TrainingContentModel(
        id: json['id'] ?? '',
        creatorId: json['creatorId'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        thumbnailUrl: json['thumbnailUrl'] ?? '',
        isPremium: json['isPremium'] ?? false,
        category: json['category'] ?? 'GENERAL',
        duration: json['duration'] ?? '00:00',
        scope: json['scope'] ?? 'public',
      );
}
