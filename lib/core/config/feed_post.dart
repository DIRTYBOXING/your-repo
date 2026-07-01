class FeedPost {
  final String id;
  final String authorName;
  final String authorRole; // fighter, coach, fan, org
  final String content;
  final String? mediaUrl;
  final DateTime createdAt;
  final bool isEventLinked;
  final String? eventId;
  final bool passedSafety; // GREEN flag from moderation

  FeedPost({
    required this.id,
    required this.authorName,
    required this.authorRole,
    required this.content,
    this.mediaUrl,
    required this.createdAt,
    required this.isEventLinked,
    this.eventId,
    required this.passedSafety,
  });
}
