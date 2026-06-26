import 'package:flutter/material.dart';

/// ADMIN CONTROL PANEL — Only visible to admin users
class AdminControlScreen extends StatelessWidget {
  const AdminControlScreen({super.key});

  static const _actions = <(IconData, String, String, Color)>[
    (
      Icons.people,
      'User Management',
      'Ban, promote, suspend, view user logs',
      Colors.amber,
    ),
    (
      Icons.shield,
      'Content Moderation',
      'Review flagged posts, approve media',
      Color(0xFF00D9FF),
    ),
    (
      Icons.security,
      'Roles & Permissions',
      'RBAC editor — custom roles and access',
      Color(0xFFFF00FF),
    ),
    (
      Icons.list_alt,
      'Audit Logs',
      'Full trail of admin and user actions',
      Colors.orange,
    ),
    (
      Icons.bar_chart,
      'Analytics & Growth',
      'User metrics, engagement, funnel data',
      Color(0xFF00D9FF),
    ),
    (
      Icons.health_and_safety,
      'System Health',
      'Uptime, error rates, Firestore latency',
      Colors.green,
    ),
    (
      Icons.payment,
      'Payments & Stripe',
      'Promoter payouts, API keys, subscriptions',
      Color(0xFF635BFF),
    ),
    (
      Icons.lock,
      'Security Controls',
      'MFA, encryption, session management',
      Colors.amber,
    ),
    (
      Icons.smart_toy,
      'AI Moderation',
      'Content flags, auto-ban rules, appeals',
      Color(0xFF9D00FF),
    ),
    (
      Icons.favorite,
      'Pink Shield Reviews',
      'Gym/mentor safety applications',
      Color(0xFFFF69B4),
    ),
    (
      Icons.warning,
      'Emergency Lockdown',
      'Kill switch, freeze accounts, disable features',
      Colors.red,
    ),
    (
      Icons.gavel,
      'GDPR/Legal Compliance',
      'Data export requests, deletion queue, consent',
      Colors.teal,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Control Panel'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withValues(alpha: 0.15),
                  Colors.deepPurple.shade900.withValues(alpha: 0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.amber,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin Controls — Owner Only',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All actions are logged and monitored. RBAC enforced.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ..._actions.map(
            (a) => _AdminTile(
              icon: a.$1,
              title: a.$2,
              subtitle: a.$3,
              color: a.$4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.deepPurple.shade800.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white38,
          size: 16,
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title — opening...'),
              backgroundColor: color.withValues(alpha: 0.9),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}
