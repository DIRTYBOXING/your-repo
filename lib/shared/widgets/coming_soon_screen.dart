import 'package:flutter/material.dart';

/// Generic placeholder for routes whose real screen doesn't exist in the
/// repo yet. Keeps [AppRouter] compiling/navigable without fabricating
/// business logic for features that were never actually built.
class ComingSoonScreen extends StatelessWidget {
  final String title;

  const ComingSoonScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                '$title is coming soon',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
