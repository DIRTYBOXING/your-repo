import 'package:flutter/material.dart';

/// Owner-Only Settings — DFC Admin
/// Controls/settings only visible to the owner.
class OwnerOnlySettingsPage extends StatelessWidget {
  const OwnerOnlySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample owner-only settings (replace with backend integration)
    final settings = [
      _Setting('Platform Branding', true),
      _Setting('Beta Features', false),
      _Setting('Admin Invite Codes', true),
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'Owner-Only Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'These controls are only visible to the platform owner.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ...settings.map(
            (s) => Card(
              color: Colors.deepPurple.shade800.withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: SwitchListTile(
                activeThumbColor: Colors.amber,
                title: Text(
                  s.name,
                  style: const TextStyle(color: Colors.white),
                ),
                value: s.enabled,
                onChanged: (val) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${s.name}: ${val ? "enabled" : "disabled"}',
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

class _Setting {
  final String name;
  final bool enabled;
  _Setting(this.name, this.enabled);
}
