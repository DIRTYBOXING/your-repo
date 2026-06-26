import 'package:flutter/material.dart';

/// Admin Help & Documentation — DFC Admin
/// Access help, documentation, and support resources.
class AdminHelpDocumentationPage extends StatelessWidget {
  const AdminHelpDocumentationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample help topics (replace with backend integration)
    final topics = [
      _Topic('User Management', 'How to ban, promote, and manage users.'),
      _Topic('Content Moderation', 'How to review and moderate posts.'),
      _Topic('Security', 'Best practices for platform security.'),
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'Admin Help & Documentation',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Access help, documentation, and support resources.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ...topics.map(
            (t) => Card(
              color: Colors.deepPurple.shade800.withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.help, color: Colors.amber, size: 28),
                title: Text(
                  t.title,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  t.body,
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

class _Topic {
  final String title;
  final String body;
  _Topic(this.title, this.body);
}
