import 'package:flutter/material.dart';

/// Audit Trails — DFC Admin
/// Immutable log of all admin/user actions with timestamps and IPs.
class AuditTrailsPage extends StatelessWidget {
  const AuditTrailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample audit logs (replace with backend integration)
    final logs = [
      _AuditLog(
        'alice@dfc.com',
        'Banned user bob@dfc.com',
        '2026-02-17 10:12',
        '192.168.1.10',
      ),
      _AuditLog(
        'eve@dfc.com',
        'Promoted user alice@dfc.com to Admin',
        '2026-02-17 09:55',
        '192.168.1.11',
      ),
      _AuditLog(
        'bob@dfc.com',
        'Reset own password',
        '2026-02-16 22:01',
        '192.168.1.12',
      ),
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'Audit Trails',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'All admin/user actions are logged and immutable for security and compliance.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ...logs.map(
            (log) => Card(
              color: Colors.deepPurple.shade800.withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(
                  Icons.event_note,
                  color: Colors.amber,
                  size: 28,
                ),
                title: Text(
                  log.action,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'By: ${log.user}\nAt: ${log.timestamp}\nIP: ${log.ip}',
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

class _AuditLog {
  final String user;
  final String action;
  final String timestamp;
  final String ip;
  _AuditLog(this.user, this.action, this.timestamp, this.ip);
}
