import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Payments & API Key Management — DFC Admin
/// Integrate with Stripe/PayPal, create/revoke API keys.
class PaymentsApiKeysPage extends StatefulWidget {
  const PaymentsApiKeysPage({super.key});

  @override
  State<PaymentsApiKeysPage> createState() => _PaymentsApiKeysPageState();
}

class _PaymentsApiKeysPageState extends State<PaymentsApiKeysPage> {
  final List<_ApiKey> _apiKeys = [
    _ApiKey('Live key stored in Stripe dashboard', 'Active', '2026-02-17'),
    _ApiKey('Test key stored in Stripe dashboard', 'Revoked', '2026-01-10'),
  ];

  int _keyCounter = 457;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'Payments & API Key Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Integrate with Stripe/PayPal. Manage API keys for integrations.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ..._apiKeys.map(
            (k) => Card(
              color: k.status == 'Revoked'
                  ? Colors.red.shade900.withValues(alpha: 0.8)
                  : Colors.deepPurple.shade800.withValues(alpha: 0.95),
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
                title: Text(k.key, style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  'Status: ${k.status}\nCreated: ${k.created}',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  color: Colors.deepPurple.shade900,
                  onSelected: (action) {
                    if (action == 'revoke') {
                      _revokeKey(k);
                    }
                    if (action == 'copy') {
                      _copyKey(k.key);
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (k.status != 'Revoked')
                      const PopupMenuItem(
                        value: 'revoke',
                        child: Text('Revoke Key'),
                      ),
                    const PopupMenuItem(value: 'copy', child: Text('Copy Key')),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple.shade700,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Create New API Key'),
            onPressed: _createNewKey,
          ),
        ],
      ),
    );
  }

  Future<void> _copyKey(String key) async {
    await Clipboard.setData(ClipboardData(text: key));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API key copied to clipboard')),
    );
  }

  void _revokeKey(_ApiKey key) {
    setState(() {
      key.status = 'Revoked';
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('API key revoked')));
  }

  void _createNewKey() {
    setState(() {
      _keyCounter += 1;
      final date = DateTime.now();
      final dateString =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      _apiKeys.insert(
        0,
        _ApiKey('Test key record #$_keyCounter', 'Active', dateString),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('New API key created (stub mode)')),
    );
  }
}

class _ApiKey {
  final String key;
  String status;
  final String created;
  _ApiKey(this.key, this.status, this.created);
}
