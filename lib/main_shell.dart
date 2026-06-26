import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ── Core Modules ──
import 'directory_screen.dart';
import 'feed_screen.dart';
import 'social_graph_screen.dart';
import 'fighter_profile_screen.dart';
import 'gym_profile_screen.dart';
import 'event_profile_screen.dart';
import 'chat_room_screen.dart';
import 'dm_screen.dart';

// Temporary placeholders for tabs not yet fully built out as root screens
class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: Text('Events Tab', style: TextStyle(color: Colors.white)),
  );
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: Text('Messages Tab', style: TextStyle(color: Colors.white)),
  );
}

// ── Global Router Configuration ──
final dfcRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainShell(currentUserId: 'USER123'),
    ),
    GoRoute(
      path: '/fighter/:id',
      builder: (context, state) =>
          FighterProfileScreen(fighterId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/gym/:id',
      builder: (context, state) =>
          GymProfileScreen(gymId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/event/:id',
      builder: (context, state) =>
          EventProfileScreen(eventId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/chat/:roomId/:userId',
      builder: (context, state) => ChatRoomScreen(
        roomId: state.pathParameters['roomId']!,
        userId: state.pathParameters['userId']!,
      ),
    ),
    GoRoute(
      path: '/dm/:roomId/:userId',
      builder: (context, state) => DmScreen(
        roomId: state.pathParameters['roomId']!,
        userId: state.pathParameters['userId']!,
      ),
    ),
  ],
);

class MainShell extends ConsumerStatefulWidget {
  final String currentUserId;
  const MainShell({super.key, required this.currentUserId});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Mount all core modules into the shell
    _screens = [
      // TAB 0: FEED (Placeholder until FeedEngine is dropped)
      const AiFeedScreen(),
      // TAB 1: DIRECTORY & MAPS (Module 7)
      const DirectoryScreen(),
      // TAB 2: EVENTS + PPV (Module 5)
      const EventsScreen(),
      // TAB 3: MESSAGING (Module 6)
      const MessagesScreen(),
      // TAB 4: SOCIAL GRAPH / PROFILE (Module 8)
      SocialGraphScreen(currentUserId: widget.currentUserId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      // IndexedStack keeps module states alive when switching tabs
      body: IndexedStack(index: _currentIndex, children: _screens),
      extendBody: true, // Allows content to flow under the glass dock
      bottomNavigationBar: _buildGlassmorphicDock(),
    );
  }

  Widget _buildGlassmorphicDock() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 90, // Taller for modern gesture-nav phones
          padding: const EdgeInsets.only(bottom: 10), // Safe area padding
          decoration: BoxDecoration(
            color: const Color(0xFF05060A).withValues(alpha: 0.65),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                0,
                Icons.dynamic_feed,
                'FEED',
                const Color(0xFF00E5FF),
              ),
              _buildNavItem(
                1,
                Icons.public,
                'DISCOVER',
                const Color(0xFF00E676),
              ),
              _buildNavItem(
                2,
                Icons.calendar_month,
                'EVENTS',
                const Color(0xFFFFD600),
              ),
              _buildNavItem(
                3,
                Icons.forum_outlined,
                'COMMS',
                const Color(0xFF9C6FFF),
              ),
              _buildNavItem(
                4,
                Icons.memory,
                'NETWORK',
                const Color(0xFFFF007A),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    Color accentColor,
  ) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? accentColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? accentColor.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? accentColor : Colors.white54,
              size: isActive ? 24 : 22,
            ),
            const SizedBox(height: 4),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: isActive
                  ? Text(
                      label,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
