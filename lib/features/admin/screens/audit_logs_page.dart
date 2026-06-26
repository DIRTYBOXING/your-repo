import 'package:flutter/material.dart';

/// Audit Logs — DFC Admin
/// View all admin/user actions, with timestamps and IPs.

class AuditLogsPage extends StatelessWidget {
  const AuditLogsPage({super.key});

  // Simulated admin check (replace with real auth/role check)
  bool isAdmin(BuildContext context) {
    // Admin check — returns true until RBAC auth wired
    return true;
  }

  Future<List<_AuditLog>> _fetchLogs() async {
    // Simulated backend call — replace with Firestore query
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      _AuditLog(
        'user1@dfc.com',
        'Banned user',
        '2026-02-17T10:12:00Z',
        '192.168.1.10',
      ),
      _AuditLog(
        'user2@dfc.com',
        'Promoted user to Admin',
        '2026-02-17T09:55:00Z',
        '192.168.1.11',
      ),
      _AuditLog(
        'user3@dfc.com',
        'Reset own password',
        '2026-02-16T22:01:00Z',
        '192.168.1.12',
      ),
    ];
  }

  String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return 'REDACTED';
    final name = parts[0];
    final domain = parts[1].split('.').first;
    return '${name[0]}***@$domain';
  }

  String maskIp(String ip) => '${ip.split('.').take(3).join('.')}.***';

  Widget _buildLogCard(BuildContext context, _AuditLog log) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const Icon(
          Icons.event_note,
          color: Colors.amber,
          size: 28,
          semanticLabel: 'Audit event',
        ),
        title: Text(
          log.action,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          'By: ${maskEmail(log.user)}\nAt: ${log.timestamp}\nIP: ${maskIp(log.ip)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        onTap: () {
          // Optionally show details modal
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isAdmin(context)) {
      return const Scaffold(
        body: Center(child: Text('Access denied: Admins only.')),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text(
          'Audit Logs',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<_AuditLog>>(
        future: _fetchLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading logs: ${snapshot.error}'));
          }
          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return const Center(child: Text('No audit logs found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: logs.length + 2,
            itemBuilder: (context, i) {
              if (i == 0) {
                return const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All admin/user actions are logged for security and compliance.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 16),
                  ],
                );
              }
              if (i == logs.length + 1) {
                // Pagination placeholder
                return const SizedBox.shrink();
              }
              return _buildLogCard(context, logs[i - 1]);
            },
          );
        },
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
