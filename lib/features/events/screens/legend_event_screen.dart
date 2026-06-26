import 'package:flutter/material.dart';

class LegendEventScreen extends StatelessWidget {
  final String legendName;
  final String eventTitle;
  final String eventDate;
  final String eventDescription;

  const LegendEventScreen({
    super.key,
    required this.legendName,
    required this.eventTitle,
    required this.eventDate,
    required this.eventDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(eventTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Legend: $legendName',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Date: $eventDate',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              eventDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
