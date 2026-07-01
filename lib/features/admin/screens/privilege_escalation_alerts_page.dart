import 'package:flutter/material.dart';

/// Privilege Escalation Alerts — DFC Admin
/// Notify owner if anyone tries to gain extra rights.
class PrivilegeEscalationAlertsPage extends StatelessWidget {
  const PrivilegeEscalationAlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample alerts (replace with backend integration)
    final alerts = [
      _Alert(
        'eve@dfc.com',
        'Tried to promote self to Owner',
        '2026-02-17 10:20',
      ),
      _Alert(
        'bob@dfc.com',
        'Attempted unauthorized access to payments',
        '2026-02-16 21:00',
      ),
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'Privilege Escalation Alerts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Owner is notified of all privilege escalation attempts.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ...alerts.map(
            (a) => Card(
              color: Colors.red.shade900.withValues(alpha: 0.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(
                  Icons.warning,
                  color: Colors.amber,
                  size: 28,
                ),
                title: Text(
                  a.action,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'By: ${a.user}\nAt: ${a.timestamp}',
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

class _Alert {
  final String user;
  final String action;
  final String timestamp;
  _Alert(this.user, this.action, this.timestamp);
}
