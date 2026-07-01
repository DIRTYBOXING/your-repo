import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/judge_score_models.dart';
import '../services/judge_score_service.dart';
import '../widgets/judge_podium_widgets.dart';
import '../../../shared/widgets/dfc_network_image.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// JUDGE LEADERBOARD SCREEN — Rankings, Stats, Badges
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Show top judges globally or per-event with full stats breakdown.
/// User's own profile card at top with XP progress, rank, badges.
///
/// Route: /ppv/judge-leaderboard
///
/// Tabs:
///   • Global — All-time best judges
///   • This Event — Event-specific rankings
///   • My Stats — Personal judge profile
/// ═══════════════════════════════════════════════════════════════════════════
class JudgeLeaderboardScreen extends StatefulWidget {
  final String? eventId;

  const JudgeLeaderboardScreen({super.key, this.eventId});

  @override
  State<JudgeLeaderboardScreen> createState() => _JudgeLeaderboardScreenState();
}

class _JudgeLeaderboardScreenState extends State<JudgeLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  final JudgeScoreService _judgeService = JudgeScoreService();
  late TabController _tabController;

  JudgeProfile? _userProfile;
  List<JudgeLeaderboardEntry> _globalLeaderboard = [];
  List<JudgeLeaderboardEntry> _eventLeaderboard = [];
  bool _loadingProfile = true;
  bool _loadingGlobal = true;
  bool _loadingEvent = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.eventId != null ? 3 : 2,
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        final profile = await _judgeService.getUserProfile(userId);
        if (mounted) {
          setState(() {
            _userProfile = profile;
            _loadingProfile = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _loadingProfile = false;
          });
        }
      }
    }

    try {
      final global = await _judgeService.getGlobalLeaderboard(limit: 100);
      if (mounted) {
        setState(() {
          _globalLeaderboard = global;
          _loadingGlobal = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingGlobal = false;
        });
      }
    }

    if (widget.eventId != null) {
      try {
        final event = await _judgeService.getEventLeaderboard(
          eventId: widget.eventId!,
          limit: 100,
        );
        if (mounted) {
          setState(() {
            _eventLeaderboard = event;
            _loadingEvent = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _loadingEvent = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Judge Leaderboard'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.white54,
          tabs: [
            const Tab(text: 'Global'),
            if (widget.eventId != null) const Tab(text: 'This Event'),
            const Tab(text: 'My Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboardTab(_globalLeaderboard, _loadingGlobal),
          if (widget.eventId != null)
            _buildLeaderboardTab(_eventLeaderboard, _loadingEvent),
          _buildMyStatsTab(),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab(
    List<JudgeLeaderboardEntry> entries,
    bool loading,
  ) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      );
    }

    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'No judges yet. Be the first!',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    // Get top 3 for podium
    final top3 = entries.take(3).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length + 1, // +1 for podium widget
      itemBuilder: (context, index) {
        // First item is the podium
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: JudgePodiumWidget(top3: top3),
          );
        }

        // Rest are leaderboard cards
        final entry = entries[index - 1]; // Adjust for podium offset
        return _buildLeaderboardCard(entry);
      },
    );
  }

  Widget _buildLeaderboardCard(JudgeLeaderboardEntry entry) {
    Color positionColor = Colors.white54;
    IconData? medal;

    if (entry.position == 1) {
      positionColor = const Color(0xFFFFD700); // Gold
      medal = Icons.emoji_events;
    } else if (entry.position == 2) {
      positionColor = const Color(0xFFC0C0C0); // Silver
      medal = Icons.emoji_events;
    } else if (entry.position == 3) {
      positionColor = const Color(0xFFCD7F32); // Bronze
      medal = Icons.emoji_events;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade900, Colors.grey.shade800],
        ),
        borderRadius: BorderRadius.circular(12),
        border: entry.position <= 3
            ? Border.all(color: positionColor, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Position
          SizedBox(
            width: 40,
            child: Column(
              children: [
                if (medal != null)
                  Icon(medal, color: positionColor, size: 28)
                else
                  Text(
                    '#${entry.position}',
                    style: TextStyle(
                      color: positionColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          DfcCircleAvatar(
            imageUrl: entry.photoUrl,
            radius: 24,
            backgroundColor: Colors.grey.shade700,
            fallbackIconColor: Colors.white54,
          ),
          const SizedBox(width: 12),
          // Name & Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatPill('${entry.totalXP} XP', Colors.cyanAccent),
                    const SizedBox(width: 8),
                    _buildStatPill(
                      '${entry.accuracy.toStringAsFixed(1)}%',
                      Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Rank badge
          _buildRankBadge(entry.rank),
        ],
      ),
    );
  }

  Widget _buildMyStatsTab() {
    if (_loadingProfile) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      );
    }

    if (_userProfile == null) {
      return const Center(
        child: Text(
          'Score your first round to start your judge journey!',
          style: TextStyle(color: Colors.white54),
          textAlign: TextAlign.center,
        ),
      );
    }

    final profile = _userProfile!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.cyanAccent.withValues(alpha: 0.2),
                  Colors.purple.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                AnimatedRankBadge(rank: profile.rank),
                const SizedBox(height: 12),
                Text(
                  _getRankName(profile.rank),
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${profile.totalXP} XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                StreakIndicator(streak: profile.currentStreak),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn(
                      '${profile.accuracy.toStringAsFixed(1)}%',
                      'Accuracy',
                    ),
                    _buildStatColumn('${profile.correctRounds}', 'Correct'),
                    _buildStatColumn('${profile.currentStreak}', 'Streak'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Badges
          const Text(
            'Badges',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (profile.badges.isEmpty)
            const Text(
              'No badges yet. Keep judging to earn them!',
              style: TextStyle(color: Colors.white54),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: profile.badges.map(_buildBadgeIcon).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRankBadge(JudgeRank rank, {double size = 32}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getRankColor(rank),
        shape: BoxShape.circle,
        border: Border.all(
          color: _getRankColor(rank).withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Icon(_getRankIcon(rank), color: Colors.white, size: size * 0.6),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBadgeIcon(JudgeBadge badge) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_getBadgeEmoji(badge), style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 2),
          Text(
            _getBadgeShortName(badge),
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getRankColor(JudgeRank rank) {
    switch (rank) {
      case JudgeRank.rookie:
        return Colors.grey;
      case JudgeRank.bronze:
        return const Color(0xFFCD7F32);
      case JudgeRank.silver:
        return const Color(0xFFC0C0C0);
      case JudgeRank.gold:
        return const Color(0xFFFFD700);
      case JudgeRank.champion:
        return Colors.purple;
      case JudgeRank.hallOfFame:
        return Colors.red;
    }
  }

  IconData _getRankIcon(JudgeRank rank) {
    switch (rank) {
      case JudgeRank.rookie:
        return Icons.person;
      case JudgeRank.bronze:
      case JudgeRank.silver:
      case JudgeRank.gold:
        return Icons.military_tech;
      case JudgeRank.champion:
        return Icons.emoji_events;
      case JudgeRank.hallOfFame:
        return Icons.stars;
    }
  }

  String _getRankName(JudgeRank rank) {
    switch (rank) {
      case JudgeRank.rookie:
        return 'Rookie Judge';
      case JudgeRank.bronze:
        return 'Bronze Judge';
      case JudgeRank.silver:
        return 'Silver Judge';
      case JudgeRank.gold:
        return 'Gold Judge';
      case JudgeRank.champion:
        return 'Champion Judge';
      case JudgeRank.hallOfFame:
        return 'Hall of Fame';
    }
  }

  String _getBadgeEmoji(JudgeBadge badge) {
    switch (badge) {
      case JudgeBadge.bronzeJudge:
        return '🥉';
      case JudgeBadge.silverJudge:
        return '🥈';
      case JudgeBadge.goldJudge:
        return '🥇';
      case JudgeBadge.hallOfFame:
        return '🏆';
      case JudgeBadge.hotStreak:
        return '🔥';
      case JudgeBadge.eagleEye:
        return '🎯';
      case JudgeBadge.speedDemon:
        return '⚡';
      case JudgeBadge.perfectCard:
        return '💎';
      case JudgeBadge.controversialKing:
        return '👑';
      case JudgeBadge.knockoutCaller:
        return '💥';
    }
  }

  String _getBadgeShortName(JudgeBadge badge) {
    switch (badge) {
      case JudgeBadge.bronzeJudge:
        return 'Bronze';
      case JudgeBadge.silverJudge:
        return 'Silver';
      case JudgeBadge.goldJudge:
        return 'Gold';
      case JudgeBadge.hallOfFame:
        return 'HOF';
      case JudgeBadge.hotStreak:
        return 'Hot';
      case JudgeBadge.eagleEye:
        return 'Eagle';
      case JudgeBadge.speedDemon:
        return 'Speed';
      case JudgeBadge.perfectCard:
        return 'Perfect';
      case JudgeBadge.controversialKing:
        return 'King';
      case JudgeBadge.knockoutCaller:
        return 'KO';
    }
  }
}
