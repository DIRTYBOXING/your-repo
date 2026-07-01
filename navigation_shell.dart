import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import your existing core screens here
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/events_screen.dart';
import '../../features/admin/screens/fighters_screen.dart';

class DfcNavigationShell extends StatefulWidget {
  const DfcNavigationShell({super.key});

  @override
  State<DfcNavigationShell> createState() => _DfcNavigationShellState();
}

class _DfcNavigationShellState extends State<DfcNavigationShell> {
  int _currentIndex = 0;

  // The screens mounted inside the global UI frame
  final List<Widget> _screens = const [
    Center(
      child: Text(
        'HOME / FEED\n(Future Module)',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white38, letterSpacing: 2),
      ),
    ),
    EventsScreen(),
    FightersScreen(),
    AdminDashboardScreen(),
  ];

  void _onItemTapped(int index) {
    if (_currentIndex == index) return;

    HapticFeedback.lightImpact(); // Premium tactile feel on tab switch
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02030A),
      // extendBody ensures the screens flow underneath the blurred floating nav bar
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildGlassNavigationBar(),
    );
  }

  Widget _buildGlassNavigationBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 32.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF05060A).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                _buildNavItem(1, Icons.event_outlined, Icons.event, 'Events'),
                _buildNavItem(
                  2,
                  Icons.sports_mma_outlined,
                  Icons.sports_mma,
                  'Fighters',
                ),
                _buildNavItem(
                  3,
                  Icons.dashboard_outlined,
                  Icons.dashboard,
                  'Admin',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData unselectedIcon,
    IconData selectedIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? Colors.cyanAccent : Colors.white54;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutExpo,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.cyanAccent.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: color,
              size: 26,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              // Neon glowing dot indicator
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.cyanAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent,
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
