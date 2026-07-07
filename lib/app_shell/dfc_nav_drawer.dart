import 'package:flutter/material.dart';

import '../core/config/feature_flags.dart';

class DfcNavDrawer extends StatelessWidget {
  const DfcNavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            const DrawerHeader(
              child: Row(
                children: <Widget>[
                  Icon(Icons.sports_mma, size: 48),
                  SizedBox(width: 12),
                  Text('DFC', style: TextStyle(fontSize: 24)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.of(context).pushNamed('/'),
            ),
            if (FeatureFlags.enablePPV)
              ListTile(
                leading: const Icon(Icons.live_tv),
                title: const Text('PPV Events'),
                onTap: () => Navigator.of(context).pushNamed('/ppv'),
              ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Rankings'),
              onTap: () => Navigator.of(context).pushNamed('/rankings'),
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Predictions'),
              onTap: () => Navigator.of(context).pushNamed('/predictions'),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.health_and_safety),
              title: const Text('Self Check'),
              onTap: () => Navigator.of(context).pushNamed('/self-check'),
            ),
          ],
        ),
      ),
    );
  }
}
