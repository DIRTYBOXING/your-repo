import 'package:flutter/foundation.dart';
import '../models/notification_item_model.dart';
import '../services/notification_service.dart';

class NotificationController extends ChangeNotifier {
  final _service = NotificationService();

  bool isLoading = true;
  List<NotificationItemModel> notifications = [];

  Future<void> loadNotifications() async {
    isLoading = true;
    notifyListeners();
    notifications = await _service.fetchNotifications();
    isLoading = false;
    notifyListeners();
  }

  void markAllAsRead() {
    notifications = notifications.map((n) => NotificationItemModel(
      id: n.id, title: n.title, message: n.message,
      type: n.type, timeAgo: n.timeAgo, isRead: true,
    )).toList();
    notifyListeners();
    // Silently sync with backend
  }
}