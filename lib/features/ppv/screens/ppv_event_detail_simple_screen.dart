import 'package:flutter/material.dart';
import '../api/ai_workflow_api.dart';

class PpvEventDetailScreen extends StatelessWidget {
  const PpvEventDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // In reality, pass this data in via the constructor
    const String title = 'Fury vs. Makhmudov';
    const String posterUrl = '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400.0,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: posterUrl.isNotEmpty
                  ? Image.network(
                      posterUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF1A0A2E), Colors.black],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.sports_mma,
                            color: Colors.white24,
                            size: 64,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF1A0A2E), Colors.black],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.sports_mma,
                          color: Colors.white24,
                          size: 64,
                        ),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fight Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tyson Fury takes on Arslanbek Makhmudov in a massive heavyweight clash.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[800],
                      ),
                      onPressed: () async {
                        try {
                          final api = WorkflowAutomationClient();
                          await api.createPpvEvent(
                            eventId: 'fury_makhmudov_2025',
                            eventName: title,
                            eventDate: DateTime.now().toIso8601String(),
                            fighters: const [
                              'Tyson Fury',
                              'Arslanbek Makhmudov',
                            ],
                            price: 49.99,
                            posterUrl: posterUrl,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'AI promo queued in DFC automation.',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'Trigger AI Promo',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
