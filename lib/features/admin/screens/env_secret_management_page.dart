import 'package:flutter/material.dart';

/// Environment Variable Secret Management — DFC Admin
/// Never hardcode secrets or keys in code. Manage via environment variables.
class EnvSecretManagementPage extends StatelessWidget {
  const EnvSecretManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample secrets (replace with backend integration)
    final secrets = [
      _Secret('STRIPE_API_KEY', '************'),
      _Secret('FIREBASE_CONFIG', '************'),
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'Environment Variable Secret Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Manage secrets and API keys securely via environment variables.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ...secrets.map(
            (s) => Card(
              color: Colors.deepPurple.shade800.withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(
                  Icons.vpn_key,
                  color: Colors.amber,
                  size: 28,
                ),
                title: Text(
                  s.name,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Value: ${s.value}',
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
                          'Edit ${s.name}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          'Secrets are managed via environment variables.\nUpdate in your CI/CD or Firebase console.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
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

class _Secret {
  final String name;
  final String value;
  _Secret(this.name, this.value);
}
