class FeedItem {
  final String id;
  final String type; // 'event', 'fighter', 'gym', 'promotion', 'editorial'
  final String title;
  final String subtitle;
  final String imageUrl;
  final DateTime createdAt;

  FeedItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.createdAt,
  });

  factory FeedItem.fromMap(String id, Map<String, dynamic> data) {
    return FeedItem(
      id: id,
      type: data['type'] ?? 'post',
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
          : DateTime.now(),
    );
  }
}
