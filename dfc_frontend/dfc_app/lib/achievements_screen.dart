 no misssing parts fully functional import 'package:flutter/material.dart';
import 'api_service.dart';
import 'achievement_controller.dart';
import 'achievement_model.dart';
import 'achievement_repository.dart';
import 'achievement_state.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late final AchievementController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AchievementController(
      repo: AchievementRepository(api: ApiService()),
    )..loadAchievements();
  }

  @override
  void dispose() {
    _controller.dispose();Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            DestinationScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            // ─── HEADER ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'ACHIEVEMENTS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── ACHIEVEMENTS LIST ───────────────────────────────────────────
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  final state = _controller.state;

                  if (state is AchievementInitial ||
                      state is AchievementLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.amberAccent,
                      ),
                    );
                  }
                  if (state is AchievementError) {
                    return Center(
                      child: Text(
                        'Error: ${state.message}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }
                  if (state is AchievementLoaded) {
                    if (state.achievements.isEmpty) {
                      return const Center(
                        child: Text(
                          'No achievements found.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: _controller.loadAchievements,
                      color: Colors.amberAccent,
                      backgroundColor: const Color(0xFF0A0E17),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        itemCount: state.achievements.length,
                        itemBuilder: (context, index) {
                          return _buildAchievementCard(
                            state.achievements[index],
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(AchievementModel a) {
    final bool unlocked = a.isUnlocked;
    final Color accentColor = unlocked ? Colors.amberAccent : Colors.white24;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E17),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked
              ? Colors.amberAccent.withValues(alpha: 0.5)
              : Colors.white10,
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: Colors.amberAccent.withValues(alpha: 0.1),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.emoji_events, color: accentColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  style: TextStyle(
                    color: unlocked ? Colors.white : Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  a.description,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                if (!unlocked && a.target > 1) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: a.progress / a.target,
                      backgroundColor: Colors.white10,
                      color: Colors.cyanAccent,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${a.progress} / ${a.target}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (unlocked)
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
        ],
      ),
    );
  }
}
