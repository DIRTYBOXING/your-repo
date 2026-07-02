import 'package:flutter/material.dart';

class PpvOperatorDashboardScreen extends StatelessWidget {
  final String eventId;

  const PpvOperatorDashboardScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PPV Operator Dashboard ($eventId)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'PPV Operator Dashboard (stub)',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.live_tv),
              title: const Text('Active PPV Events'),
              subtitle: const Text(
                'Placeholder list. Restore full implementation in follow-up.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Placeholder action')),
              );
            },
            child: const Text('Run Smoke Test'),
          ),
        ],
      ),
    );
  }
}
