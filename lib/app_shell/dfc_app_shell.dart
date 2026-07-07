import 'package:flutter/material.dart';

import 'dfc_bottom_nav.dart';
import 'dfc_nav_drawer.dart';

class DfcAppShell extends StatefulWidget {
  const DfcAppShell({super.key, required this.child});

  final Widget child;

  @override
  State<DfcAppShell> createState() => _DfcAppShellState();
}

class _DfcAppShellState extends State<DfcAppShell> {
  int _selectedIndex = 0;

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DFC Combat OS')),
      drawer: const DfcNavDrawer(),
      body: widget.child,
      bottomNavigationBar: DfcBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
