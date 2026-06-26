import 'package:flutter/material.dart';
import '../../../../dfc_theme.dart';
import '../controllers/notification_controller.dart';
import '../widgets/notification_list_item.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NotificationController()..loadNotifications();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('NOTIFICATIONS', style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => _controller.markAllAsRead(),
            child: const Text('MARK ALL READ', style: TextStyle(color: AppColors.accentCyan, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
          }
          if (_controller.notifications.isEmpty) {
            return const Center(child: Text("You're all caught up.", style: TextStyle(color: AppColors.textMuted)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _controller.notifications.length,
            itemBuilder: (context, index) {
              return NotificationListItem(notification: _controller.notifications[index]);
            },
          );
        },
      ),
    );
  }
}