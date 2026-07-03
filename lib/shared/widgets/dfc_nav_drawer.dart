import 'package:flutter/material.dart';

class DFCNavDrawer extends StatelessWidget {
  final ValueChanged<int>? onTabSelected;
  const DFCNavDrawer({super.key, this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              child: Row(
                children: const [
                  Icon(Icons.sports_mma, size: 40),
                  SizedBox(width: 12),
                  Text(
                    'DFC',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.of(context).pushNamed('/'),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Events Map'),
              onTap: () => Navigator.of(context).pushNamed('/maps'),
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('Gyms'),
              onTap: () => Navigator.of(context).pushNamed('/gyms'),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ],
        ),
      ),
    );
  }
}
