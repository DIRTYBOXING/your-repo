import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../models/judge_score_models.dart';

/// Service to display achievement notifications with animations
/// Shows badge unlocks, rank ups, and perfect scores with confetti
class JudgeAchievementNotifier {
  /// Show badge unlock notification with haptic feedback
  static void showBadgeUnlock(BuildContext context, JudgeBadge badge) {
    HapticFeedback.heavyImpact();

    final (emoji, name, description) = _getBadgeDetails(badge);

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _AchievementPopup(
        icon: emoji,
        title: 'Badge Unlocked!',
        subtitle: name,
        description: description,
        color: Colors.amber,
        showConfetti: true,
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 4), overlayEntry.remove);
  }

  /// Show rank up notification with celebration
  static void showRankUp(BuildContext context, JudgeRank newRank) {
    HapticFeedback.mediumImpact();

    final (emoji, name, description) = _getRankDetails(newRank);

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _AchievementPopup(
        icon: emoji,
        title: 'Rank Up!',
        subtitle: name,
        description: description,
        color: Colors.cyanAccent,
        showConfetti: true,
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 4), overlayEntry.remove);
  }

  /// Show perfect score notification with confetti
  static void showPerfectScore(BuildContext context, int xpEarned) {
    HapticFeedback.heavyImpact();

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _AchievementPopup(
        icon: '🎯',
        title: 'Perfect Score!',
        subtitle: '+$xpEarned XP',
        description: 'Your score matched the official judges perfectly!',
        color: Colors.greenAccent,
        showConfetti: true,
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), overlayEntry.remove);
  }

  /// Show leaderboard climb notification
  static void showLeaderboardClimb(BuildContext context, int newPosition) {
    HapticFeedback.selectionClick();

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _AchievementPopup(
        icon: '📈',
        title: 'Moving Up!',
        subtitle: 'Rank #$newPosition',
        description: 'You\'re climbing the global leaderboard!',
        color: Colors.purpleAccent,
        showConfetti: false,
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), overlayEntry.remove);
  }

  static (String, String, String) _getBadgeDetails(JudgeBadge badge) {
    return switch (badge) {
      JudgeBadge.bronzeJudge => ('🥉', 'Bronze Judge', '50 correct rounds'),
      JudgeBadge.silverJudge => ('🥈', 'Silver Judge', '200 correct rounds'),
      JudgeBadge.goldJudge => ('🥇', 'Gold Judge', '500 correct rounds'),
      JudgeBadge.hallOfFame => (
        '🏆',
        'Hall of Fame',
        '1000 correct rounds + 95% accuracy',
      ),
      JudgeBadge.hotStreak => (
        '🔥',
        'Hot Streak',
        '10 correct rounds in a row',
      ),
      JudgeBadge.speedDemon => ('⚡', 'Speed Demon', '50 speed bonuses'),
      JudgeBadge.eagleEye => ('🎯', 'Eagle Eye', '20 exact matches'),
      JudgeBadge.perfectCard => (
        '💎',
        'Perfect Card',
        'All rounds correct in an event',
      ),
      JudgeBadge.controversialKing => (
        '👑',
        'Controversial King',
        '20 correct split-decision reads',
      ),
      JudgeBadge.knockoutCaller => (
        '💥',
        'Knockout Caller',
        '10 finish predictions',
      ),
    };
  }

  static (String, String, String) _getRankDetails(JudgeRank rank) {
    return switch (rank) {
      JudgeRank.rookie => ('🌱', 'Rookie Judge', 'Welcome to the judges table'),
      JudgeRank.bronze => ('🥉', 'Bronze Judge', 'Building consistency'),
      JudgeRank.silver => ('🥈', 'Silver Judge', 'Solid scoring instincts'),
      JudgeRank.gold => ('🥇', 'Gold Judge', 'Elite round-reading skills'),
      JudgeRank.champion => ('👑', 'Champion Judge', 'Top-tier expertise'),
      JudgeRank.hallOfFame => ('🏛️', 'Hall of Fame', 'Legendary judge status'),
    };
  }
}

class _AchievementPopup extends StatefulWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String description;
  final Color color;
  final bool showConfetti;

  const _AchievementPopup({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    required this.showConfetti,
  });

  @override
  State<_AchievementPopup> createState() => _AchievementPopupState();
}

class _AchievementPopupState extends State<_AchievementPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5)),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Confetti overlay
        if (widget.showConfetti)
          Positioned.fill(
            child: IgnorePointer(child: _ConfettiOverlay(color: widget.color)),
          ),

        // Achievement card
        Positioned(
          top: 80,
          left: 20,
          right: 20,
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.color.withValues(alpha: 0.9),
                          widget.color.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              widget.icon,
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.subtitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.description,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfettiOverlay extends StatefulWidget {
  final Color color;

  const _ConfettiOverlay({required this.color});

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Generate confetti particles
    for (int i = 0; i < 50; i++) {
      _particles.add(
        _ConfettiParticle(
          x: _random.nextDouble(),
          y: -0.1 - _random.nextDouble() * 0.2,
          vx: _random.nextDouble() * 2 - 1,
          vy: _random.nextDouble() * 3 + 2,
          rotation: _random.nextDouble() * math.pi * 2,
          color: [
            widget.color,
            Colors.white,
            Colors.amber,
            Colors.pink,
          ][_random.nextInt(4)],
        ),
      );
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ConfettiParticle {
  final double x;
  final double y;
  final double vx;
  final double vy;
  final double rotation;
  final Color color;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final x = particle.x * size.width + particle.vx * progress * 100;
      final y = particle.y * size.height + particle.vy * progress * 200;

      if (y > size.height) continue;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: (1 - progress) * 0.8)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation + progress * math.pi * 4);

      // Draw confetti piece (rectangle)
      canvas.drawRect(const Rect.fromLTWH(-5, -2, 10, 4), paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}
