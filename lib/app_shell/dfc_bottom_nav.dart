import 'package:flutter/material.dart';

class DfcBottomNav extends StatelessWidget {
  const DfcBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onTap,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: 'PPV'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Rankings'),
      ],
    );
  }
}
