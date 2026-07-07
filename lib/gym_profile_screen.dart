import 'package:flutter/material.dart';

class GymProfileScreen extends StatelessWidget {
  final String gymId;

  const GymProfileScreen({super.key, required this.gymId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gym Profile')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.fitness_center, size: 72),
              const SizedBox(height: 12),
              Text(
                'Gym ID: $gymId',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Gym profile is temporarily replaced with a safe stub.',
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
