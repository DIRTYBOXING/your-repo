import 'package:flutter/material.dart';

/// Admin Notifications & Alerts — DFC Admin
/// Receive and manage admin notifications and alerts.
class AdminNotificationsAlertsPage extends StatelessWidget {
  const AdminNotificationsAlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample notifications (replace with backend integration)
    final notifications = [
      _Notification(
        'System Health Warning',
        'Error rate exceeded 1%',
        '2026-02-17 10:30',
      ),
      _Notification(
        'User Report',
        'alice@dfc.com reported inappropriate content',
        '2026-02-17 09:45',
      ),
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'Admin Notifications & Alerts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Receive and manage admin notifications and alerts.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ...notifications.map(
            (n) => Card(
              color: Colors.deepPurple.shade800.withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(
                  Icons.notifications,
                  color: Colors.amber,
                  size: 28,
                ),
                title: Text(
                  n.title,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${n.body}\nAt: ${n.timestamp}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notification {
  final String title;
  final String body;
  final String timestamp;
  _Notification(this.title, this.body, this.timestamp);
}
