import 'package:flutter/material.dart';

/// Payment Integration Settings — DFC Admin
/// Integrate with Stripe/PayPal (PCI-compliant, tokenized only).
class PaymentIntegrationStubsPage extends StatefulWidget {
  const PaymentIntegrationStubsPage({super.key});

  @override
  State<PaymentIntegrationStubsPage> createState() =>
      _PaymentIntegrationStubsPageState();
}

class _PaymentIntegrationStubsPageState
    extends State<PaymentIntegrationStubsPage> {
  late final TextEditingController _webhookController;
  late final TextEditingController _merchantController;
  final List<_Provider> _providers = [
    _Provider('Stripe', true),
    _Provider('PayPal', true),
  ];

  @override
  void initState() {
    super.initState();
    _webhookController = TextEditingController();
    _merchantController = TextEditingController();
  }

  @override
  void dispose() {
    _webhookController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'Payment Integration Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Integrate with PCI-compliant payment providers. No card data stored.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ..._providers.map(
            (p) => Card(
              color: Colors.deepPurple.shade800.withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: SwitchListTile(
                activeThumbColor: Colors.amber,
                title: Text(
                  p.name,
                  style: const TextStyle(color: Colors.white),
                ),
                value: p.enabled,
                onChanged: (val) {
                  setState(() {
                    p.enabled = val;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _webhookController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Webhook Endpoint',
              labelStyle: TextStyle(color: Colors.white70),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _merchantController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Apple Merchant ID',
              labelStyle: TextStyle(color: Colors.white70),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _saveStubConfig,
            icon: const Icon(Icons.save),
            label: const Text('Save Integration Settings'),
          ),
        ],
      ),
    );
  }

  void _saveStubConfig() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Payment settings saved')));
  }
}

class _Provider {
  final String name;
  bool enabled;
  _Provider(this.name, this.enabled);
}
