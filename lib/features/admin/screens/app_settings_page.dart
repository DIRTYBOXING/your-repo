import 'package:flutter/material.dart';

/// App Settings & Feature Toggles — DFC Admin
/// Toggle features, maintenance mode, update terms/privacy, manage integrations.
class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample settings (replace with backend integration)
    final settings = [
      _Setting('Maintenance Mode', true),
      _Setting('Enable Genie AI', true),
      _Setting('Show Opportunity Board', true),
      _Setting('Enable Payments', false),
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'App Settings & Feature Toggles',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Toggle features, maintenance mode, and manage integrations.',
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
