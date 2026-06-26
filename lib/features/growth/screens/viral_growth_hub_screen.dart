import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// VIRAL GROWTH HUB — Leaderboards • Badges • Social Proof • Shareable Cards
// The engagement flywheel that turns fans into promoters
// ═══════════════════════════════════════════════════════════════════════════════

class ViralGrowthHubScreen extends StatefulWidget {
  const ViralGrowthHubScreen({super.key});

  @override
  State<ViralGrowthHubScreen> createState() => _ViralGrowthHubScreenState();
}

class _ViralGrowthHubScreenState extends State<ViralGrowthHubScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _confettiCtrl;

  final int _userPoints = 847;
  final int _userStreak = 3;
  final int _userRank = 42;
  final String _userTier = 'Silver';
  int _selectedBadge = -1;
  int _activePollIndex = 0;

  static const _cyan = Color(0xFF00E5FF);
  static const _red = Color(0xFFFF1744);
  static const _gold = Color(0xFFFFD600);
  static const _green = Color(0xFF00E676);
  static const _purple = Color(0xFF9C6FFF);
  static const _magenta = Color(0xFFFF4081);

  // ── Leaderboard data (Firestore-ready structure) ──────────────────────
  static const _leaderboard = [
    _LeaderEntry(
      rank: 1,
      name: 'CageSage_MMA',
      points: 12840,
      accuracy: 87,
      streak: 14,
      tier: 'Diamond',
      flag: '🇺🇸',
      avatar: '🥇',
    ),
    _LeaderEntry(
      rank: 2,
      name: 'PredictorKing',
      points: 11580,
      accuracy: 84,
      streak: 11,
      tier: 'Diamond',
      flag: '🇬🇧',
      avatar: '🥈',
    ),
    _LeaderEntry(
      rank: 3,
      name: 'FightIQ_Pro',
      points: 10250,
      accuracy: 81,
      streak: 8,
      tier: 'Platinum',
      flag: '🇧🇷',
      avatar: '🥉',
    ),
    _LeaderEntry(
      rank: 4,
      name: 'CornerVoice',
      points: 9820,
      accuracy: 79,
      streak: 6,
      tier: 'Platinum',
      flag: '🇦🇺',
      avatar: '🏅',
    ),
    _LeaderEntry(
      rank: 5,
      name: 'StrikeOracle',
      points: 8690,
      accuracy: 76,
      streak: 5,
      tier: 'Gold',
      flag: '🇯🇵',
      avatar: '🏅',
    ),
    _LeaderEntry(
      rank: 6,
      name: 'TapOrNap_OG',
      points: 7420,
      accuracy: 74,
      streak: 4,
      tier: 'Gold',
      flag: '🇮🇪',
      avatar: '🏅',
    ),
    _LeaderEntry(
      rank: 7,
      name: 'DecisionBot',
      points: 6810,
      accuracy: 72,
      streak: 7,
      tier: 'Gold',
      flag: '🇳🇿',
      avatar: '🏅',
    ),
    _LeaderEntry(
      rank: 8,
      name: 'SubmissionHunter',
      points: 5990,
      accuracy: 70,
      streak: 3,
      tier: 'Silver',
      flag: '🇷🇺',
      avatar: '🏅',
    ),
    _LeaderEntry(
      rank: 9,
      name: 'MatWizard',
      points: 5340,
      accuracy: 68,
      streak: 2,
      tier: 'Silver',
      flag: '🇹🇭',
      avatar: '🏅',
    ),
    _LeaderEntry(
      rank: 10,
      name: 'OctagonEye',
      points: 4780,
      accuracy: 66,
      streak: 5,
      tier: 'Silver',
      flag: '🇲🇽',
      avatar: '🏅',
    ),
  ];

  // ── Badges catalogue ──────────────────────────────────────────────────
  static const _badges = [
    _Badge(
      id: 'first_pick',
      name: 'First Pick',
      icon: '🎯',
      desc: 'Make your first prediction',
      unlockReq: 'Make 1 prediction',
      tier: 'Bronze',
      color: Color(0xFFCD7F32),
    ),
    _Badge(
      id: 'streak_3',
      name: 'Hot Streak',
      icon: '🔥',
      desc: '3 correct in a row',
      unlockReq: '3-win streak',
      tier: 'Bronze',
      color: Color(0xFFCD7F32),
    ),
    _Badge(
      id: 'streak_5',
      name: 'On Fire',
      icon: '💥',
      desc: '5 correct in a row',
      unlockReq: '5-win streak',
      tier: 'Silver',
      color: Color(0xFF9C6FFF),
    ),
    _Badge(
      id: 'streak_10',
      name: 'Untouchable',
      icon: '⚡',
      desc: '10 correct in a row',
      unlockReq: '10-win streak',
      tier: 'Gold',
      color: Color(0xFFFFD600),
    ),
    _Badge(
      id: 'points_500',
      name: 'Rising Star',
      icon: '⭐',
      desc: 'Earn 500 points',
      unlockReq: '500 points',
      tier: 'Bronze',
      color: Color(0xFFCD7F32),
    ),
    _Badge(
      id: 'points_1000',
      name: 'Contender',
      icon: '🏆',
      desc: 'Earn 1,000 points',
      unlockReq: '1,000 points',
      tier: 'Silver',
      color: Color(0xFF9C6FFF),
    ),
    _Badge(
      id: 'points_5000',
      name: 'Champion',
      icon: '👑',
      desc: 'Earn 5,000 points',
      unlockReq: '5,000 points',
      tier: 'Gold',
      color: Color(0xFFFFD600),
    ),
    _Badge(
      id: 'points_10000',
      name: 'GOAT',
      icon: '🐐',
      desc: 'Earn 10,000 points',
      unlockReq: '10,000 points',
      tier: 'Diamond',
      color: Color(0xFF00E5FF),
    ),
    _Badge(
      id: 'method_master',
      name: 'Method Master',
      icon: '🎪',
      desc: 'Predict exact method 5 times',
      unlockReq: '5 exact methods',
      tier: 'Gold',
      color: Color(0xFFFFD600),
    ),
    _Badge(
      id: 'round_prophet',
      name: 'Round Prophet',
      icon: '🔮',
      desc: 'Predict exact round 3 times',
      unlockReq: '3 exact rounds',
      tier: 'Gold',
      color: Color(0xFFFFD600),
    ),
    _Badge(
      id: 'upset_caller',
      name: 'Upset Caller',
      icon: '🫨',
      desc: 'Correctly pick 3 underdogs',
      unlockReq: '3 upset wins',
      tier: 'Silver',
      color: Color(0xFF9C6FFF),
    ),
    _Badge(
      id: 'ko_specialist',
      name: 'KO Specialist',
      icon: '💣',
      desc: 'Predict 5 KO/TKO finishes',
      unlockReq: '5 KO picks correct',
      tier: 'Silver',
      color: Color(0xFF9C6FFF),
    ),
    _Badge(
      id: 'sub_artist',
      name: 'Sub Artist',
      icon: '🪢',
      desc: 'Predict 5 submission wins',
      unlockReq: '5 sub picks correct',
      tier: 'Silver',
      color: Color(0xFF9C6FFF),
    ),
    _Badge(
      id: 'social_warrior',
      name: 'Social Warrior',
      icon: '📢',
      desc: 'Share 5 predictions',
      unlockReq: '5 shares',
      tier: 'Bronze',
      color: Color(0xFFCD7F32),
    ),
    _Badge(
      id: 'recruiter',
      name: 'Recruiter',
      icon: '🤝',
      desc: 'Refer 3 friends',
      unlockReq: '3 referrals',
      tier: 'Gold',
      color: Color(0xFFFFD600),
    ),
    _Badge(
      id: 'top_10',
      name: 'Elite 10',
      icon: '🏅',
      desc: 'Reach top 10 on leaderboard',
      unlockReq: 'Top 10 rank',
      tier: 'Diamond',
      color: Color(0xFF00E5FF),
    ),
  ];

  // ── Live polls ────────────────────────────────────────────────────────
  static const _polls = [
    _FanPoll(
      question: 'Who wins the main event?',
      optionA: 'Makhachev',
      optionB: 'Volkanovski',
      votesA: 6742,
      votesB: 4128,
      flagA: '🇷🇺',
      flagB: '🇦🇺',
      endTime: 'Closes in 2h',
    ),
    _FanPoll(
      question: 'Fight of the Night?',
      optionA: 'Torres vs Van Zyl',
      optionB: 'Pereira vs Ankalaev',
      votesA: 3891,
      votesB: 5234,
      flagA: '🥊',
      flagB: '⚡',
      endTime: 'Closes in 4h',
    ),
    _FanPoll(
      question: 'Method of victory — main event?',
      optionA: 'Finish',
      optionB: 'Decision',
      votesA: 5123,
      votesB: 3456,
      flagA: '💥',
      flagB: '📋',
      endTime: 'Closes in 2h',
    ),
  ];

  // ── Activity feed (social proof) ──────────────────────────────────────
  static const _activityFeed = [
    _Activity(
      'CageSage_MMA',
      'predicted Makhachev by Decision',
      '2m ago',
      '🎯',
    ),
    _Activity('FightIQ_Pro', 'earned the GOAT badge', '5m ago', '🐐'),
    _Activity('PredictorKing', 'hit a 12-win streak!', '8m ago', '🔥'),
    _Activity('CornerVoice', 'shared their prediction card', '11m ago', '📢'),
    _Activity('StrikeOracle', 'called the upset — +250 pts!', '14m ago', '🫨'),
    _Activity(
      'TapOrNap_OG',
      'voted in "Fight of the Night" poll',
      '18m ago',
      '🗳️',
    ),
    _Activity('OctagonEye', 'unlocked Method Master badge', '22m ago', '🎪'),
    _Activity('MatWizard', 'climbed to #9 on the leaderboard', '25m ago', '📈'),
    _Activity(
      'DecisionBot',
      'predicted 7 fights correctly tonight',
      '30m ago',
      '⚡',
    ),
    _Activity(
      'SubmissionHunter',
      'shared a fight clip — 142 views',
      '35m ago',
      '🎬',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _pulseCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030810),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildUserStats(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildLeaderboardTab(),
                  _buildBadgesTab(),
                  _buildPollsTab(),
                  _buildActivityTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        border: Border(
          bottom: BorderSide(color: _cyan.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white54,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, _) => Icon(
              Icons.rocket_launch,
              color: _magenta.withValues(alpha: 0.6 + _pulseCtrl.value * 0.4),
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VIRAL GROWTH HUB',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'Compete · Collect · Share · Rise',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _green.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, size: 10, color: _green),
                const SizedBox(width: 3),
                Text(
                  '${_leaderboard.length * 142} ACTIVE',
                  style: const TextStyle(
                    color: _green,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USER STATS BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildUserStats() {
    final tierColor = _tierColor(_userTier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF0A1628), tierColor.withValues(alpha: 0.05)],
        ),
        border: Border(
          bottom: BorderSide(color: tierColor.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statPill('⚡ $_userPoints', 'POINTS', _cyan),
          _statPill('🔥 $_userStreak', 'STREAK', _red),
          _statPill('#$_userRank', 'RANK', _gold),
          _statPill('💎 $_userTier', 'TIER', tierColor),
          _badgeCount(),
        ],
      ),
    );
  }

  Widget _statPill(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.5),
            fontSize: 7,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _badgeCount() {
    final unlocked = _badges
        .where(
          (b) =>
              (b.id == 'first_pick') ||
              (b.id == 'streak_3' && _userStreak >= 3) ||
              (b.id == 'points_500' && _userPoints >= 500),
        )
        .length;
    return Column(
      children: [
        Text(
          '$unlocked/${_badges.length}',
          style: const TextStyle(
            color: _purple,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          'BADGES',
          style: TextStyle(
            color: _purple.withValues(alpha: 0.5),
            fontSize: 7,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: _magenta,
        labelColor: _magenta,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.leaderboard, size: 16), text: 'LEADERBOARD'),
          Tab(icon: Icon(Icons.military_tech, size: 16), text: 'BADGES'),
          Tab(icon: Icon(Icons.how_to_vote, size: 16), text: 'POLLS'),
          Tab(icon: Icon(Icons.rss_feed, size: 16), text: 'ACTIVITY'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1 — LEADERBOARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLeaderboardTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _leaderboard.length + 1, // +1 for "Your position" card
      itemBuilder: (_, i) {
        if (i == _leaderboard.length) return _buildYourPosition();
        return _buildLeaderRow(_leaderboard[i]);
      },
    );
  }

  Widget _buildLeaderRow(_LeaderEntry e) {
    final isTop3 = e.rank <= 3;
    final rankColor = e.rank == 1
        ? _gold
        : e.rank == 2
        ? Colors.white70
        : e.rank == 3
        ? const Color(0xFFCD7F32)
        : Colors.white38;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isTop3
            ? rankColor.withValues(alpha: 0.06)
            : const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isTop3
              ? rankColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              e.avatar,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('${e.flag} ', style: const TextStyle(fontSize: 12)),
                    Text(
                      e.name,
                      style: TextStyle(
                        color: rankColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _tierBadge(e.tier),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${e.points} pts',
                      style: TextStyle(
                        color: _cyan.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${e.accuracy}% acc',
                      style: TextStyle(
                        color: _green.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '🔥 ${e.streak}',
                      style: TextStyle(
                        color: _red.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '#${e.rank}',
            style: TextStyle(
              color: rankColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYourPosition() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _purple.withValues(alpha: 0.08),
            _cyan.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _purple.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('😎', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'YOU',
                      style: TextStyle(
                        color: _purple,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _tierBadge(_userTier),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '$_userPoints pts',
                      style: TextStyle(
                        color: _cyan.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '🔥 $_userStreak streak',
                      style: TextStyle(
                        color: _red.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '#$_userRank',
            style: const TextStyle(
              color: _purple,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierBadge(String tier) {
    final c = _tierColor(tier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        tier.toUpperCase(),
        style: TextStyle(
          color: c,
          fontSize: 7,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'Diamond':
        return _cyan;
      case 'Platinum':
        return Colors.white70;
      case 'Gold':
        return _gold;
      case 'Silver':
        return _purple;
      default:
        return const Color(0xFFCD7F32);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2 — BADGES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBadgesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trophy room header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _gold.withValues(alpha: 0.06),
                  _purple.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _gold.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                const Text(
                  '🏆 TROPHY ROOM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_badges.where(_isBadgeUnlocked).length} of ${_badges.length} unlocked',
                  style: TextStyle(
                    color: _gold.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Badge grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: _badges.length,
            itemBuilder: (_, i) => _buildBadgeTile(_badges[i], i),
          ),

          // Selected badge detail
          if (_selectedBadge >= 0) ...[
            const SizedBox(height: 16),
            _buildBadgeDetail(_badges[_selectedBadge]),
          ],
        ],
      ),
    );
  }

  bool _isBadgeUnlocked(_Badge b) {
    if (b.id == 'first_pick') return true;
    if (b.id == 'streak_3' && _userStreak >= 3) return true;
    if (b.id == 'points_500' && _userPoints >= 500) return true;
    return false;
  }

  Widget _buildBadgeTile(_Badge b, int index) {
    final unlocked = _isBadgeUnlocked(b);
    final selected = _selectedBadge == index;

    return GestureDetector(
      onTap: () =>
          setState(() => _selectedBadge = _selectedBadge == index ? -1 : index),
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? b.color.withValues(alpha: 0.12)
              : unlocked
              ? const Color(0xFF0A1628)
              : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? b.color.withValues(alpha: 0.5)
                : unlocked
                ? b.color.withValues(alpha: 0.2)
                : Colors.white10,
          ),
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              unlocked ? b.icon : '🔒',
              style: TextStyle(
                fontSize: 22,
                color: unlocked ? null : Colors.white24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              b.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unlocked ? Colors.white : Colors.white24,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeDetail(_Badge b) {
    final unlocked = _isBadgeUnlocked(b);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: b.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(b.icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.name,
                      style: TextStyle(
                        color: b.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      b.desc,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: unlocked
                      ? _green.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  unlocked ? '✅ UNLOCKED' : '🔒 LOCKED',
                  style: TextStyle(
                    color: unlocked ? _green : Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _tierBadge(b.tier),
              const Spacer(),
              Text(
                'Requirement: ${b.unlockReq}',
                style: const TextStyle(color: Colors.white38, fontSize: 9),
              ),
            ],
          ),
          if (unlocked) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '📢 Shared "${b.name}" badge to your feed!',
                      ),
                      backgroundColor: const Color(0xFF1A2744),
                    ),
                  );
                },
                icon: const Icon(Icons.share, size: 14),
                label: const Text('SHARE ACHIEVEMENT'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _magenta,
                  side: BorderSide(color: _magenta.withValues(alpha: 0.4)),
                  textStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3 — FAN POLLS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPollsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _polls.length,
      itemBuilder: (_, i) => _buildPollCard(_polls[i], i),
    );
  }

  Widget _buildPollCard(_FanPoll poll, int index) {
    final totalVotes = poll.votesA + poll.votesB;
    final pctA = totalVotes > 0 ? poll.votesA / totalVotes : 0.5;
    final pctB = 1.0 - pctA;
    final voted = _activePollIndex == index; // Placeholder voted state

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _purple.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.how_to_vote, color: _purple, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  poll.question,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                poll.endTime,
                style: TextStyle(
                  color: _red.withValues(alpha: 0.6),
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Option A
          GestureDetector(
            onTap: () => setState(() => _activePollIndex = index),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(poll.flagA, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          poll.optionA,
                          style: TextStyle(
                            color: voted ? _cyan : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${(pctA * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: _cyan,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pctA,
                      backgroundColor: Colors.white10,
                      color: _cyan.withValues(alpha: 0.5),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Option B
          GestureDetector(
            onTap: () => setState(() => _activePollIndex = index),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(poll.flagB, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        poll.optionB,
                        style: TextStyle(
                          color: voted ? _red : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${(pctB * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: _red,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pctB,
                    backgroundColor: Colors.white10,
                    color: _red.withValues(alpha: 0.5),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${_formatNumber(totalVotes)} votes',
                style: const TextStyle(color: Colors.white38, fontSize: 9),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📢 Poll shared!'),
                      backgroundColor: Color(0xFF1A2744),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _magenta,
                  side: BorderSide(color: _magenta.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 28),
                  textStyle: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                child: const Text('SHARE POLL'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 4 — ACTIVITY FEED (Social Proof)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActivityTab() {
    return Column(
      children: [
        // Social proof banner
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _magenta.withValues(alpha: 0.08),
                _cyan.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _magenta.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _proofStat(_formatNumber(14200), 'PREDICTIONS\nTONIGHT', _cyan),
              _proofStat(_formatNumber(2340), 'ACTIVE\nNOW', _green),
              _proofStat('89%', 'ENGAGEMENT\nRATE', _magenta),
              _proofStat(_formatNumber(847), 'SHARES\nTODAY', _gold),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Live feed
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _activityFeed.length,
            itemBuilder: (_, i) => _buildActivityRow(_activityFeed[i]),
          ),
        ),
      ],
    );
  }

  Widget _proofStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color.withValues(alpha: 0.5),
            fontSize: 7,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityRow(_Activity a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Text(a.icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 11, height: 1.3),
                children: [
                  TextSpan(
                    text: '${a.user} ',
                    style: const TextStyle(color: _cyan, fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: a.action,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
          Text(
            a.time,
            style: const TextStyle(color: Colors.white24, fontSize: 9),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

class _LeaderEntry {
  final int rank, points, accuracy, streak;
  final String name, tier, flag, avatar;
  const _LeaderEntry({
    required this.rank,
    required this.name,
    required this.points,
    required this.accuracy,
    required this.streak,
    required this.tier,
    required this.flag,
    required this.avatar,
  });
}

class _Badge {
  final String id, name, icon, desc, unlockReq, tier;
  final Color color;
  const _Badge({
    required this.id,
    required this.name,
    required this.icon,
    required this.desc,
    required this.unlockReq,
    required this.tier,
    required this.color,
  });
}

class _FanPoll {
  final String question, optionA, optionB, flagA, flagB, endTime;
  final int votesA, votesB;
  const _FanPoll({
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.votesA,
    required this.votesB,
    required this.flagA,
    required this.flagB,
    required this.endTime,
  });
}

class _Activity {
  final String user, action, time, icon;
  const _Activity(this.user, this.action, this.time, this.icon);
}
