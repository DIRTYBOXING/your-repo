import 'package:flutter/material.dart';

/// Security & Owner Controls — DFC Admin
/// MFA, RBAC, lockdown, backups, owner-only settings.
class SecurityOwnerControlsPage extends StatelessWidget {
  const SecurityOwnerControlsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample controls (replace with backend integration)
    final controls = [
      _Control('Enable MFA', true),
      _Control('RBAC Active', true),
      _Control('Emergency Lockdown', false),
      _Control('Manual Backup', false),
      _Control('Owner-Only Settings', true),
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'Security & Owner Controls',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Critical security and owner-only controls. Use with caution.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ...controls.map(
            (c) => Card(
              color: Colors.deepPurple.shade800.withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: SwitchListTile(
                activeThumbColor: Colors.amber,
                title: Text(
                  c.name,
                  style: const TextStyle(color: Colors.white),
                ),
                value: c.enabled,
                onChanged: (val) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${c.name}: ${val ? "enabled" : "disabled"}',
                      ),
                      backgroundColor: Colors.deepPurple.shade700,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Control {
  final String name;
  final bool enabled;
  _Control(this.name, this.enabled);
}
