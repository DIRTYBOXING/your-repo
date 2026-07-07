import 'package:flutter/material.dart';

class P4PLadderWidget extends StatelessWidget {
  const P4PLadderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> ladder = List<String>.generate(
      10,
      (int i) => 'Fighter ${i + 1}',
    );

    return Card(
      child: Column(
        children: <Widget>[
          const ListTile(title: Text('Pound for Pound Ladder')),
          ...ladder.map((String fighter) => ListTile(title: Text(fighter))),
        ],
      ),
    );
  }
}
