import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ── Core Modules ──
import 'directory_screen.dart';
import 'features/feed/screens/feed_screen.dart';
import 'features/social/screens/social_feed_screen.dart';
import 'features/events/screens/events_screen.dart';
import 'features/messaging/screens/inbox_screen.dart';

// Temporary placeholders for profile screens
class FighterProfileScreen extends StatelessWidget {
  final String fighterId;
  const FighterProfileScreen({super.key, required this.fighterId});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Fighter $fighterId')),
    body: const Center(
      child: Text('Fighter Profile', style: TextStyle(color: Colors.white)),
    ),
  );
}

class GymProfileScreen extends StatelessWidget {
  final String gymId;
  const GymProfileScreen({super.key, required this.gymId});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Gym $gymId')),
    body: const Center(
      child: Text('Gym Profile', style: TextStyle(color: Colors.white)),
    ),
  );
}

class EventProfileScreen extends StatelessWidget {
  final String eventId;
  const EventProfileScreen({super.key, required this.eventId});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Event $eventId')),
    body: const Center(
      child: Text('Event Profile', style: TextStyle(color: Colors.white)),
    ),
  );
}

class ChatRoomScreen extends StatelessWidget {
  final String roomId;
  final String userId;
  const ChatRoomScreen({super.key, required this.roomId, required this.userId});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Chat $roomId')),
    body: const Center(
      child: Text('Chat Room', style: TextStyle(color: Colors.white)),
    ),
  );
}

class DmScreen extends StatelessWidget {
  final String roomId;
  final String userId;
  const DmScreen({super.key, required this.roomId, required this.userId});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('DM $roomId')),
    body: const Center(
      child: Text('Direct Message', style: TextStyle(color: Colors.white)),
    ),
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

class MainShell extends StatefulWidget {
  final String currentUserId;
  const MainShell({super.key, required this.currentUserId});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Mount all core modules into the shell
    _screens = [
      // TAB 0: FEED
      const FeedScreen(),
      // TAB 1: DIRECTORY & MAPS
      const DirectoryScreen(),
      // TAB 2: EVENTS + PPV
      const EventsScreen(),
      // TAB 3: MESSAGING
      const InboxScreen(),
      // TAB 4: SOCIAL FEED
      const SocialFeedScreen(),
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
          color: isActive
              ? accentColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? accentColor.withValues(alpha: 0.5)
                : Colors.transparent,
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
