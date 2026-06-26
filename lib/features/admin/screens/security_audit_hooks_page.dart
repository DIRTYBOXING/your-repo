import 'package:flutter/material.dart';

/// Security Audit Hooks — DFC Admin
/// Schedule and review regular security audits, penetration tests, and code reviews.
class SecurityAuditHooksPage extends StatelessWidget {
  const SecurityAuditHooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample audit schedule (replace with backend integration)
    final audits = [
      _Audit('Penetration Test', '2026-03-01', 'Scheduled'),
      _Audit('Dependency Scan', '2026-02-10', 'Completed'),
      _Audit('Code Review', '2026-02-01', 'Completed'),
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'Security Audit Hooks',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Schedule and review security audits and code reviews.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ...audits.map(
            (a) => Card(
              color: a.status == 'Scheduled'
                  ? Colors.amber.shade900.withValues(alpha: 0.8)
                  : Colors.deepPurple.shade800.withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(
                  Icons.security,
                  color: Colors.amber,
                  size: 28,
                ),
                title: Text(
                  a.name,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Date: ${a.date}\nStatus: ${a.status}',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: Colors.deepPurple.shade900,
                        title: Text(
                          'Edit ${a.name}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        content: Text(
                          'Date: ${a.date}\nStatus: ${a.status}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${a.name} schedule updated'),
                                  backgroundColor: Colors.deepPurple.shade700,
                                ),
                              );
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Audit {
  final String name;
  final String date;
  final String status;
  _Audit(this.name, this.date, this.status);
}
