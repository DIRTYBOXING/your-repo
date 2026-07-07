import 'package:flutter/material.dart';

class PromoterDashboardScreen extends StatelessWidget {
  const PromoterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promoter Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Promoter Dashboard (stub)', style: TextStyle(fontSize: 18)),
            SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.event),
                      title: Text('Upcoming Events'),
                      subtitle: Text('Placeholder. Restore event list widget.'),
                    ),
                    ListTile(
                      leading: Icon(Icons.attach_money),
                      title: Text('Revenue Summary'),
                      subtitle: Text('Placeholder. Restore revenue widget.'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
