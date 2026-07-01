import 'package:flutter/material.dart';

/// Tutorial dialog shown to first-time judge scorers
/// Explains the scoring system, XP progression, and rewards
class JudgeTutorialDialog extends StatefulWidget {
  const JudgeTutorialDialog({super.key});

  @override
  State<JudgeTutorialDialog> createState() => _JudgeTutorialDialogState();
}

class _JudgeTutorialDialogState extends State<JudgeTutorialDialog> {
  int _currentPage = 0;
  final _pageController = PageController();

  final _pages = const [
    _TutorialPage(
      icon: Icons.gavel,
      iconColor: Colors.amber,
      title: "Welcome, Judge!",
      description:
          "Score each round like a real MMA judge using the 10-point must system. Compare your scores with the pros!",
      feature: "Score fights in real-time",
    ),
    _TutorialPage(
      icon: Icons.military_tech,
      iconColor: Colors.cyanAccent,
      title: "Earn XP & Climb Ranks",
      description:
          "Earn XP for accurate scoring. Perfect matches earn bonus XP! Rise from Rookie to Hall of Fame Judge.",
      feature:
          "+10 XP per correct score\n+25 XP for perfect matches\n+5 XP speed bonus",
    ),
    _TutorialPage(
      icon: Icons.emoji_events,
      iconColor: Colors.yellowAccent,
      title: "Unlock Epic Badges",
      description:
          "Collect 10 unique badges as you master the art of scoring. From Bronze Gavel to Perfect Vision!",
      feature: "🥉 Bronze Gavel\n🏆 Golden Eye\n💎 Diamond Judge",
    ),
    _TutorialPage(
      icon: Icons.leaderboard,
      iconColor: Colors.deepPurple,
      title: "Compete Globally",
      description:
          "Climb the global leaderboard and compete with judges worldwide. Show your expertise!",
      feature:
          "Global & Event rankings\nReal-time updates\nTop 100 leaderboard",
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.cyanAccent.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),

            // Page view
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: _pages,
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Colors.cyanAccent
                          : Colors.white30,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text(
                        'Back',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  else
                    const SizedBox(width: 80),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _pages.length - 1) {
                        Navigator.of(context).pop(true); // Mark as completed
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? "Let's Go!" : 'Next',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialPage extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String feature;

  const _TutorialPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.feature,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [iconColor.withValues(alpha: 0.3), Colors.transparent],
              ),
              border: Border.all(color: iconColor, width: 3),
            ),
            child: Icon(icon, size: 50, color: iconColor),
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Feature box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              feature,
              style: TextStyle(
                color: iconColor,
                fontSize: 14,
                height: 1.8,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
