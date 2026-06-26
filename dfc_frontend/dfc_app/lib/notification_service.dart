import '../models/notification_item_model.dart';

class NotificationService {
  Future<List<NotificationItemModel>> fetchNotifications() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      NotificationItemModel(
        id: 'n1',
        title: 'PAYOUT PROCESSED',
        message:
            '\$4,250.00 has been transferred to your connected bank account.',
        type: 'payment',
        timeAgo: '2m ago',
      ),
      NotificationItemModel(
        id: 'n2',
        title: 'LIVE EVENT STARTING',
        message: 'DFC 2: Redemption is now LIVE. Tap to enter the stream.',
        type: 'live',
        timeAgo: '15m ago',
      ),
      NotificationItemModel(
        id: 'n3',
        title: 'SYSTEM UPDATE',
        message:
            'Your smart coach blueprint has been recalibrated based on your recent Whoop recovery score.',
        type: 'system',
        timeAgo: '1h ago',
        isRead: true,
      ),
      NotificationItemModel(
        id: 'n4',
        title: 'NEW VAULT CONTENT',
        message:
            'Elite Sparring Team just dropped a new Grappling Masterclass.',
        type: 'training',
        timeAgo: 'Yesterday',
        isRead: true,
      ),
    ];
  }
}
