import 'package:flutter/material.dart';

/// Session Management — DFC Admin
/// Manage admin sessions, auto-expiry, and force logout on suspicious activity.
class SessionManagementPage extends StatelessWidget {
  const SessionManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample sessions (replace with backend integration)
    final sessions = [
      _Session('alice@dfc.com', 'Active', '2026-02-17 10:15', '192.168.1.10'),
      _Session('eve@dfc.com', 'Expired', '2026-02-16 23:00', '192.168.1.11'),
      _Session('bob@dfc.com', 'Suspicious', '2026-02-17 09:00', '203.0.113.42'),
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'Session Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Monitor and manage admin sessions. Expire or force logout as needed.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ...sessions.map(
            (s) => Card(
              color: s.status == 'Suspicious'
                  ? Colors.red.shade900.withValues(alpha: 0.8)
                  : Colors.deepPurple.shade800.withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(
                  Icons.computer,
                  color: s.status == 'Suspicious'
                      ? Colors.redAccent
                      : Colors.amber,
                  size: 28,
                ),
                title: Text(
                  '${s.user} (${s.status})',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Last Active: ${s.lastActive}\nIP: ${s.ip}',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: s.status == 'Active'
                    ? IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white70),
                        tooltip: 'Force Logout',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Session terminated for ${s.user}'),
                              backgroundColor: Colors.red.shade700,
                            ),
                          );
                        },
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Session {
  final String user;
  final String status;
  final String lastActive;
  final String ip;
  _Session(this.user, this.status, this.lastActive, this.ip);
}
