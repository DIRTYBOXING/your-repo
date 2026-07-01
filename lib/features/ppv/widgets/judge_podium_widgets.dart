import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/judge_score_models.dart';
import '../../../shared/widgets/dfc_network_image.dart';

/// Animated podium widget showing top 3 judges with medals and glow effects
class JudgePodiumWidget extends StatefulWidget {
  final List<JudgeLeaderboardEntry> top3;

  const JudgePodiumWidget({super.key, required this.top3});

  @override
  State<JudgePodiumWidget> createState() => _JudgePodiumWidgetState();
}

class _JudgePodiumWidgetState extends State<JudgePodiumWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowPulse = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure we have at least 3 entries (pad with nulls if needed)
    final first = widget.top3.isNotEmpty ? widget.top3[0] : null;
    final second = widget.top3.length > 1 ? widget.top3[1] : null;
    final third = widget.top3.length > 2 ? widget.top3[2] : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                'Top Judges',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Podium
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd Place
              if (second != null)
                _PodiumPosition(
                  entry: second,
                  position: 2,
                  height: 100,
                  color: const Color(0xFFC0C0C0), // Silver
                  glowPulse: _glowPulse,
                )
              else
                const SizedBox(width: 100),

              // 1st Place (tallest)
              if (first != null)
                _PodiumPosition(
                  entry: first,
                  position: 1,
                  height: 140,
                  color: const Color(0xFFFFD700), // Gold
                  glowPulse: _glowPulse,
                )
              else
                const SizedBox(width: 100),

              // 3rd Place
              if (third != null)
                _PodiumPosition(
                  entry: third,
                  position: 3,
                  height: 80,
                  color: const Color(0xFFCD7F32), // Bronze
                  glowPulse: _glowPulse,
                )
              else
                const SizedBox(width: 100),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumPosition extends StatelessWidget {
  final JudgeLeaderboardEntry entry;
  final int position;
  final double height;
  final Color color;
  final Animation<double> glowPulse;

  const _PodiumPosition({
    required this.entry,
    required this.position,
    required this.height,
    required this.color,
    required this.glowPulse,
  });

  String get medalEmoji => switch (position) {
    1 => '🥇',
    2 => '🥈',
    3 => '🥉',
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Medal and avatar
        Stack(
          alignment: Alignment.topRight,
          children: [
            // Avatar with glow
            AnimatedBuilder(
              animation: glowPulse,
              builder: (context, child) {
                return Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: glowPulse.value * 0.6),
                        blurRadius: 20 * glowPulse.value,
                        spreadRadius: 5 * glowPulse.value,
                      ),
                    ],
                  ),
                  child: DfcCircleAvatar(
                    imageUrl: entry.photoUrl,
                    radius: 30,
                    backgroundColor: color,
                    fallbackText: entry.displayName[0].toUpperCase(),
                    fallbackTextStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                );
              },
            ),

            // Medal badge
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(
                  child: Text(medalEmoji, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Name
        SizedBox(
          width: 90,
          child: Text(
            entry.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(height: 4),

        // XP
        Text(
          '${entry.totalXP} XP',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        // Podium stand
        AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.bounceOut,
          width: 80,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withValues(alpha: 0.6)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '#$position',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 4)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Animated rank badge with pulsing glow effect
class AnimatedRankBadge extends StatefulWidget {
  final JudgeRank rank;
  final double size;

  const AnimatedRankBadge({super.key, required this.rank, this.size = 80});

  @override
  State<AnimatedRankBadge> createState() => _AnimatedRankBadgeState();
}

class _AnimatedRankBadgeState extends State<AnimatedRankBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulse = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  (String, Color) get rankDetails => switch (widget.rank) {
    JudgeRank.rookie => ('🌱', Colors.green),
    JudgeRank.bronze => ('🥉', const Color(0xFFCD7F32)),
    JudgeRank.silver => ('🥈', const Color(0xFFC0C0C0)),
    JudgeRank.gold => ('🥇', const Color(0xFFFFD700)),
    JudgeRank.champion => ('👑', Colors.purple),
    JudgeRank.hallOfFame => ('🏛️', Colors.cyanAccent),
  };

  @override
  Widget build(BuildContext context) {
    final (emoji, color) = rankDetails;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulse.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color.withValues(alpha: 0.3), Colors.transparent],
              ),
              border: Border.all(color: color, width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 20 * _pulse.value,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(emoji, style: TextStyle(fontSize: widget.size * 0.5)),
            ),
          ),
        );
      },
    );
  }
}

/// Animated streak indicator with fire effects
class StreakIndicator extends StatefulWidget {
  final int streak;

  const StreakIndicator({super.key, required this.streak});

  @override
  State<StreakIndicator> createState() => _StreakIndicatorState();
}

class _StreakIndicatorState extends State<StreakIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get streakColor {
    if (widget.streak >= 10) return Colors.red;
    if (widget.streak >= 5) return Colors.orange;
    return Colors.amber;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.streak == 0) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [streakColor, streakColor.withValues(alpha: 0.6)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: streakColor.withValues(alpha: 0.5),
                blurRadius: 10 + 5 * math.sin(_controller.value * math.pi * 2),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: 1.0 + 0.2 * math.sin(_controller.value * math.pi * 2),
                child: const Text('🔥', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.streak} Streak',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
