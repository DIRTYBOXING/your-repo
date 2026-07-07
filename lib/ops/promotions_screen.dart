// lib/ops/promotions_screen.dart
import 'package:flutter/material.dart';

import '../services/api_client.dart';

class OpsPromotionsScreen extends StatefulWidget {
  final ApiClient api;
  const OpsPromotionsScreen({required this.api, Key? key}) : super(key: key);

  @override
  State<OpsPromotionsScreen> createState() => _OpsPromotionsScreenState();
}

class _OpsPromotionsScreenState extends State<OpsPromotionsScreen> {
  final _title = TextEditingController();
  bool _loading = false;

  Future<void> _createPromo() async {
    setState(() {
      _loading = true;
    });
    final payload = {
      'title': _title.text,
      'start_at': DateTime.now().toUtc().toIso8601String(),
      'end_at': DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 30))
          .toIso8601String(),
      'priority': 1000,
      'channels': ['home_feed'],
      'status': 'active',
    };
    await widget.api.post('/api/v1/admin/promotions', payload);
    setState(() {
      _loading = false;
      _title.clear();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Promo created')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ops Promotions')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Promo title'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _createPromo,
              child: const Text('Create Promo'),
            ),
          ],
        ),
      ),
    );
  }
}
