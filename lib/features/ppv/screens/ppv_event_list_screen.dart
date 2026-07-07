import 'package:flutter/material.dart';

class PpvEventListScreen extends StatelessWidget {
  const PpvEventListScreen({super.key});

  List<Map<String, String>> _sampleEvents() {
    return <Map<String, String>>[
      <String, String>{'id': 'evt1', 'title': 'DFC 101: Main Card'},
      <String, String>{'id': 'evt2', 'title': 'DFC 102: Undercard'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> events = _sampleEvents();

    return Scaffold(
      appBar: AppBar(title: const Text('PPV Events')),
      body: ListView.builder(
        itemCount: events.length,
        itemBuilder: (BuildContext context, int index) {
          final Map<String, String> event = events[index];
          return Card(
            child: ListTile(
              title: Text(event['title'] ?? ''),
              onTap: () => Navigator.of(
                context,
              ).pushNamed('/ppv/watch', arguments: event['id']),
            ),
          );
        },
      ),
    );
  }
}
