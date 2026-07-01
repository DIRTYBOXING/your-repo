import 'package:flutter/material.dart';

/// Rate Limiting & Brute Force Protection — DFC Admin
/// Prevent automated attacks and monitor suspicious activity.
class RateLimitingPage extends StatelessWidget {
  const RateLimitingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample rate limiting rules (replace with backend integration)
    final rules = [
      _RateRule('Login Attempts', '5 per 10 min'),
      _RateRule('Password Reset', '3 per hour'),
      _RateRule('API Requests', '1000 per day'),
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'Rate Limiting & Brute Force Protection',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Configure rate limits to prevent abuse and automated attacks.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ...rules.map(
            (r) => Card(
              color: Colors.deepPurple.shade800.withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.speed, color: Colors.amber, size: 28),
                title: Text(
                  r.name,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Limit: ${r.limit}',
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
                          'Edit ${r.name}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        content: Text(
                          'Current limit: ${r.limit}',
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
                                  content: Text('${r.name} updated'),
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

class _RateRule {
  final String name;
  final String limit;
  _RateRule(this.name, this.limit);
}
