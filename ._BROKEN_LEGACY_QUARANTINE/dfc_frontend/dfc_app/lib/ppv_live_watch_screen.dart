import 'package:flutter/material.dart';

class PpvLiveWatchScreen extends StatelessWidget {
  final String eventId;

  const PpvLiveWatchScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('PPV Live'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.live_tv, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Live stream module is temporarily disabled for stabilization.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                'Event ID: $eventId',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
