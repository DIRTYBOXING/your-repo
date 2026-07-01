class SearchResultModel {
  final String id;
  final String title;
  final String subtitle;
  final String type;
  final String imageUrl;
  final String metadata;
  final String extra;

  SearchResultModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.imageUrl,
    required this.metadata,
    required this.extra,
  });

  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    return SearchResultModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      type: json['type'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      metadata: json['metadata'] ?? '',
      extra: json['extra'] ?? '',
    );
  }
}