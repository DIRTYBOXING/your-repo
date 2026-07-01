import 'package:flutter/material.dart';

class DirectoryScreen extends StatelessWidget {
  const DirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050509),
      appBar: AppBar(
        title: const Text(
          'DIRECTORY',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF050509),
        elevation: 0,
        centerTitle: false,
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grid_view_rounded, size: 48, color: Color(0xFF7A7A8A)),
            SizedBox(height: 16),
            Text(
              'DIRECTORY COMING ONLINE',
              style: TextStyle(
                fontSize: 14,
                letterSpacing: 3,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Gyms, fighters, promotions and events\nwill populate this grid as the graph grows.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9A9AB5),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
