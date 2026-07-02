import 'package:flutter/material.dart';

import '../widgets/p4p_ladder_widget.dart';

class RankingsDashboardScreen extends StatelessWidget {
  const RankingsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(padding: EdgeInsets.all(12), child: P4PLadderWidget()),
    );
  }
}
