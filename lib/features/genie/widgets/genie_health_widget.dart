import 'package:flutter/material.dart';
import '../../../shared/services/health_service.dart';
import 'package:provider/provider.dart';

/// GenieHealthWidget displays app health status and Genie advice.
class GenieHealthWidget extends StatelessWidget {
  const GenieHealthWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthService>(
      builder: (context, health, _) {
        return Card(
          color: health.isHealthy ? Colors.green[100] : Colors.red[100],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  health.isHealthy ? 'App Health: Good' : 'App Health: Issue',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (health.lastError.isNotEmpty)
                  Text(
                    'Last Error: ${health.lastError}',
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Shido Advice:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  health.genieAdvice,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
