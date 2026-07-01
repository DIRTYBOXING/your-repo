import 'package:flutter/material.dart';

/// Analytics & Data Insights — DFC Admin
/// Access analytics, user growth, engagement, error logs.
class AnalyticsInsightsPage extends StatelessWidget {
  const AnalyticsInsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample analytics (replace with backend integration)
    final stats = [
      _Stat('Total Users', '1,234'),
      _Stat('Active Today', '321'),
      _Stat('Posts This Week', '87'),
      _Stat('Errors (24h)', '2'),
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'Analytics & Data Insights',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Platform analytics, user growth, engagement, and error logs.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ...stats.map(
            (s) => Card(
              color: Colors.deepPurple.shade800.withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(
                  Icons.bar_chart,
                  color: Colors.amber,
                  size: 32,
                ),
                title: Text(
                  s.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Text(
                  s.value,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat {
  final String label;
  final String value;
  _Stat(this.label, this.value);
}
