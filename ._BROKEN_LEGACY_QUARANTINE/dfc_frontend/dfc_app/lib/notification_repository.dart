import '../../api_service.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final ApiService api;
  NotificationRepository({required this.api});

  Future<List<NotificationModel>> getNotifications() async {
    final data = await api.callFunction("getNotifications");
    final list = data["notifications"] as List<dynamic>? ?? [];
    return list
        .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> markAllAsRead() async {
    // V12: Hits the cloud function to batch update all unread documents
    await api.callFunction("markNotificationsRead");
  }
}
