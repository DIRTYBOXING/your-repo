class NotificationItemModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'payment', 'live', 'system', 'training'
  final String timeAgo;
  final bool isRead;

  NotificationItemModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timeAgo,
    this.isRead = false,
  });
}