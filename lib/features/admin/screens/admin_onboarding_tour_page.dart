import 'package:flutter/material.dart';

/// Admin Onboarding Tour — DFC Admin
/// Guide new admins through key features and best practices.
class AdminOnboardingTourPage extends StatelessWidget {
  const AdminOnboardingTourPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample onboarding steps (replace with backend integration)
    final steps = [
      _Step('Welcome', 'Get started with the DFC Admin Dashboard.'),
      _Step('User Management', 'Learn to manage users and roles.'),
      _Step('Security', 'Understand security controls and best practices.'),
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'Admin Onboarding Tour',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Guide new admins through key features and best practices.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ...steps.map(
            (s) => Card(
              color: Colors.deepPurple.shade800.withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.tour, color: Colors.amber, size: 28),
                title: Text(
                  s.title,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  s.body,
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

class _Step {
  final String title;
  final String body;
  _Step(this.title, this.body);
}
