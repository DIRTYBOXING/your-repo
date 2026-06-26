import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../widgets/badge_strip.dart';
import '../services/badge_service.dart';

// ═══════════════════════════════════════════════════════════════════
//  FIGHT PREDICTION ARENA v2.0
//  "Predict the outcome. Prove you know the game."
//  Full dark theme · Fighter stats · AI analysis · Leaderboard
// ═══════════════════════════════════════════════════════════════════

class FighterVsFighterGameScreen extends StatefulWidget {
  const FighterVsFighterGameScreen({super.key});

  @override
  State<FighterVsFighterGameScreen> createState() =>
      _FighterVsFighterGameScreenState();
}

class _FighterVsFighterGameScreenState extends State<FighterVsFighterGameScreen>
    with TickerProviderStateMixin {
  final int _leaderboardRank = 42; // Placeholder, should be loaded from backend
  late AnimationController _vsController;
  late AnimationController _revealController;
  late Animation<double> _vsScale;
  int _selectedFightIndex = 0;
  String? _userPrediction; // fighter name
  String? _userMethod; // KO/TKO, Submission, Decision, Draw
  int? _userRound;
  bool _revealed = false;
  int _totalPoints = 847;
  int _streak = 3;

  // Fight card data
  final List<_FightMatchup> _fights = [
    const _FightMatchup(
      fighter1: _Fighter(
        name: 'Marcus Torres',
        record: '25-7-0',
        weightClass: 'Middleweight',
        style: 'Striker',
        power: 90,
        speed: 85,
        cardio: 88,
        ground: 78,
        chin: 88,
        iq: 92,
        flag: '🇦🇺',
        finishRate: 60,
        avgFightTime: '3:24 R3',
        recentForm: ['W', 'W', 'W', 'L', 'W'],
      ),
      fighter2: _Fighter(
        name: 'Pieter Van Zyl',
        record: '22-2-0',
        weightClass: 'Middleweight',
        style: 'Brawler',
        power: 92,
        speed: 80,
        cardio: 86,
        ground: 82,
        chin: 90,
        iq: 85,
        flag: '🇿🇦',
        finishRate: 72,
        avgFightTime: '3:12 R2',
        recentForm: ['W', 'W', 'W', 'W', 'W'],
      ),
      eventName: 'UFC 323 SYDNEY',
      aiPick: 'Pieter Van Zyl',
      aiMethod: 'KO/TKO',
      aiRound: 3,
      aiConfidence: 55,
      aiReasoning:
          'Van Zyl\'s relentless pressure and power (92) tests Whittaker\'s chin. '
          'Whittaker\'s superior IQ (92) keeps him competitive, but Van Zyl\'s '
          'cardio and volume become decisive in later rounds. Very close fight.',
    ),
    const _FightMatchup(
      fighter1: _Fighter(
        name: 'Stamp Fairtex',
        record: '73-19-5',
        weightClass: 'Atomweight',
        style: 'All-Rounder',
        power: 78,
        speed: 93,
        cardio: 90,
        ground: 80,
        chin: 82,
        iq: 89,
        flag: '🇹🇭',
        finishRate: 55,
        avgFightTime: '3:48 R2',
        recentForm: ['W', 'W', 'W', 'W', 'W'],
      ),
      fighter2: _Fighter(
        name: 'Ji-Yeon Park',
        record: '27-8-0',
        weightClass: 'Atomweight',
        style: 'Striker',
        power: 80,
        speed: 86,
        cardio: 82,
        ground: 75,
        chin: 84,
        iq: 83,
        flag: '🇰🇷',
        finishRate: 48,
        avgFightTime: '4:15 R3',
        recentForm: ['W', 'L', 'W', 'W', 'W'],
      ),
      eventName: 'ONE CHAMPIONSHIP 170',
      aiPick: 'Stamp Fairtex',
      aiMethod: 'Decision',
      aiConfidence: 68,
      aiReasoning:
          'Stamp\'s speed (93) and cardio (90) give her an edge over 3 rounds. '
          'Ji-Yeon Park\'s experience is dangerous, but Stamp\'s evolution into MMA '
          'and her fight IQ (89) should control the pace.',
    ),
    const _FightMatchup(
      fighter1: _Fighter(
        name: 'Mako Tua',
        record: '15-8-0',
        weightClass: 'Heavyweight',
        style: 'Brawler',
        power: 97,
        speed: 65,
        cardio: 60,
        ground: 55,
        chin: 88,
        iq: 68,
        flag: '🇦🇺',
        finishRate: 88,
        avgFightTime: '1:42 R1',
        recentForm: ['W', 'W', 'L', 'W', 'L'],
      ),
      fighter2: _Fighter(
        name: 'Antoine Marchand',
        record: '12-2-0',
        weightClass: 'Heavyweight',
        style: 'Counter-Striker',
        power: 85,
        speed: 82,
        cardio: 88,
        ground: 72,
        chin: 80,
        iq: 90,
        flag: '🇫🇷',
        finishRate: 65,
        avgFightTime: '3:20 R2',
        recentForm: ['W', 'W', 'W', 'W', 'L'],
      ),
      eventName: 'UFC FIGHT NIGHT PERTH',
      aiPick: 'Antoine Marchand',
      aiMethod: 'TKO',
      aiRound: 2,
      aiConfidence: 62,
      aiReasoning:
          'Tua has knockout power (97) but fades with cardio (60). Gane\'s '
          'technical striking and IQ (90) let him weather the storm and '
          'capitalize when Tua tires in round 2. Close fight — Tua always dangerous.',
    ),
    const _FightMatchup(
      fighter1: _Fighter(
        name: 'Tyler Reid',
        record: '26-4-0',
        weightClass: 'Featherweight',
        style: 'Striker',
        power: 82,
        speed: 88,
        cardio: 95,
        ground: 85,
        chin: 90,
        iq: 96,
        flag: '🇦🇺',
        finishRate: 46,
        avgFightTime: '4:30 R4',
        recentForm: ['W', 'W', 'W', 'L', 'L'],
      ),
      fighter2: _Fighter(
        name: 'Ilia Topuria',
        record: '26-7-0',
        weightClass: 'Featherweight',
        style: 'Muay Thai',
        power: 80,
        speed: 90,
        cardio: 96,
        ground: 72,
        chin: 92,
        iq: 88,
        flag: '🇺🇸',
        finishRate: 42,
        avgFightTime: '4:50 R4',
        recentForm: ['W', 'W', 'W', 'W', 'L'],
      ),
      eventName: 'UFC 323 SYDNEY',
      aiPick: 'Tyler Reid',
      aiMethod: 'Decision',
      aiConfidence: 56,
      aiReasoning:
          'Reid\'s IQ (96) and cardio (95) match perfectly against Nakamura. '
          'Both fighters have incredible chins. Reid\'s wrestling advantage (85 vs 72) '
          'could be the difference maker in a razor-close championship-level fight.',
      actualWinner: 'Tyler Reid',
      actualMethod: 'Split Decision',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _vsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _vsScale = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _vsController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _vsController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  _FightMatchup get _currentFight => _fights[_selectedFightIndex];

  void _submitPrediction() {
    if (_userPrediction == null || _userMethod == null) return;
    setState(() {
      _revealed = true;
      // Calculate points
      int earned = 0;
      if (_currentFight.actualWinner != null) {
        if (_userPrediction == _currentFight.actualWinner) {
          earned += 100;
          if (_userMethod == _currentFight.actualMethod) earned += 50;
          if (_userRound != null && _userRound == _currentFight.aiRound) {
            earned += 25;
          }
        }
      } else {
        // Fight hasn't happened — compare with AI
        if (_userPrediction == _currentFight.aiPick) earned += 50;
        if (_userMethod == _currentFight.aiMethod) earned += 25;
      }
      _totalPoints += earned;
      if (earned > 0) _streak++;
    });
    _revealController.forward();
  }

  void _nextFight() {
    setState(() {
      _selectedFightIndex = (_selectedFightIndex + 1) % _fights.length;
      _userPrediction = null;
      _userMethod = null;
      _userRound = null;
      _revealed = false;
    });
    _revealController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final unlockedBadges = BadgeService.getUnlockedBadges(
      _totalPoints,
      _streak,
      _leaderboardRank,
    );
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  BadgeStrip(badges: unlockedBadges),
                  _buildBody(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ─────────────────────────────────────────────────────
  Widget _buildHeader() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: DesignTokens.bgPrimary,
      expandedHeight: 140,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                DesignTokens.neonRed.withValues(alpha: 0.12),
                DesignTokens.bgPrimary,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 70, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF3366), Color(0xFFFF6B35)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: DesignTokens.neonRed.withValues(alpha: 0.4),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.sports_mma,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'PREDICTION ARENA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'Predict the outcome. Prove you know the game.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        // Points badge
        Container(
          margin: const EdgeInsets.only(right: 14, top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: DesignTokens.neonGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: DesignTokens.neonGold.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars, color: DesignTokens.neonGold, size: 16),
              const SizedBox(width: 4),
              Text(
                '$_totalPoints',
                style: const TextStyle(
                  color: DesignTokens.neonGold,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── BODY ──────────────────────────────────────────────────────
  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Stats strip
          _buildStatsStrip(),
          const SizedBox(height: 16),
          // Fight selector
          _buildFightSelector(),
          const SizedBox(height: 20),
          // VS Card
          _buildVSCard(),
          const SizedBox(height: 20),
          // Stat comparison
          _buildStatComparison(),
          const SizedBox(height: 20),
          // Your Prediction section
          if (!_revealed) ...[
            _buildPredictionForm(),
          ] else ...[
            _buildResultReveal(),
          ],
          const SizedBox(height: 20),
          // AI Analysis
          _buildAIAnalysis(),
          const SizedBox(height: 20),
          // Leaderboard preview
          _buildLeaderboardPreview(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStatsStrip() {
    return Row(
      children: [
        _stripChip(
          Icons.local_fire_department,
          '$_streak streak',
          DesignTokens.neonRed,
        ),
        const SizedBox(width: 8),
        _stripChip(
          Icons.emoji_events,
          '${_fights.length} fights',
          DesignTokens.neonAmber,
        ),
        const SizedBox(width: 8),
        _stripChip(Icons.leaderboard, '#42 ranked', DesignTokens.neonCyan),
      ],
    );
  }

  Widget _stripChip(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFightSelector() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _fights.length,
        itemBuilder: (context, i) {
          final selected = i == _selectedFightIndex;
          final fight = _fights[i];
          return GestureDetector(
            onTap: () {
              if (!_revealed) {
                setState(() {
                  _selectedFightIndex = i;
                  _userPrediction = null;
                  _userMethod = null;
                  _userRound = null;
                });
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected
                    ? DesignTokens.neonRed.withValues(alpha: 0.2)
                    : DesignTokens.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? DesignTokens.neonRed
                      : Colors.white.withValues(alpha: 0.06),
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'BOUT ${i + 1}',
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    fight.fighter1.weightClass,
                    style: TextStyle(
                      color: selected
                          ? Colors.white54
                          : Colors.white.withValues(alpha: 0.2),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVSCard() {
    final f1 = _currentFight.fighter1;
    final f2 = _currentFight.fighter2;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          // Event name
          Text(
            _currentFight.eventName,
            style: TextStyle(
              color: DesignTokens.neonRed.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          // Fighter row
          Row(
            children: [
              // Fighter 1
              Expanded(child: _buildFighterSide(f1, true)),
              // VS badge
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AnimatedBuilder(
                  animation: _vsScale,
                  builder: (context, _) => Transform.scale(
                    scale: _vsScale.value,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF3366), Color(0xFFFF6B35)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: DesignTokens.neonRed.withValues(alpha: 0.3),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'VS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Fighter 2
              Expanded(child: _buildFighterSide(f2, false)),
            ],
          ),
          const SizedBox(height: 14),
          // Quick info row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _infoChip(f1.style, DesignTokens.neonCyan),
              _infoChip(f1.weightClass, DesignTokens.neonAmber),
              _infoChip(f2.style, DesignTokens.neonMagenta),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFighterSide(_Fighter f, bool isLeft) {
    final selected = _userPrediction == f.name;
    return GestureDetector(
      onTap: _revealed ? null : () => setState(() => _userPrediction = f.name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? DesignTokens.neonGreen.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? DesignTokens.neonGreen : Colors.transparent,
            width: selected ? 1.5 : 0,
          ),
        ),
        child: Column(
          children: [
            // Avatar placeholder
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLeft
                      ? [
                          DesignTokens.neonCyan.withValues(alpha: 0.3),
                          DesignTokens.neonCyan.withValues(alpha: 0.1),
                        ]
                      : [
                          DesignTokens.neonMagenta.withValues(alpha: 0.3),
                          DesignTokens.neonMagenta.withValues(alpha: 0.1),
                        ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(f.flag, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              f.name.split('" ').last,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '"${f.name.split('"')[1]}"',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              f.record,
              style: const TextStyle(
                color: DesignTokens.neonGold,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            // Recent form
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: f.recentForm.map((r) {
                final isWin = r == 'W';
                return Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: isWin
                        ? DesignTokens.neonGreen.withValues(alpha: 0.2)
                        : DesignTokens.neonRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Center(
                    child: Text(
                      r,
                      style: TextStyle(
                        color: isWin
                            ? DesignTokens.neonGreen
                            : DesignTokens.neonRed,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (selected && !_revealed) ...[
              const SizedBox(height: 6),
              const Text(
                'YOUR PICK',
                style: TextStyle(
                  color: DesignTokens.neonGreen,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── STAT COMPARISON ──────────────────────────────────────────
  Widget _buildStatComparison() {
    final f1 = _currentFight.fighter1;
    final f2 = _currentFight.fighter2;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Text(
            'STAT COMPARISON',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 14),
          _statBar('Power', f1.power, f2.power, DesignTokens.neonRed),
          _statBar('Speed', f1.speed, f2.speed, DesignTokens.neonCyan),
          _statBar('Cardio', f1.cardio, f2.cardio, DesignTokens.neonGreen),
          _statBar('Ground', f1.ground, f2.ground, DesignTokens.neonMagenta),
          _statBar('Chin', f1.chin, f2.chin, DesignTokens.neonAmber),
          _statBar('Fight IQ', f1.iq, f2.iq, DesignTokens.neonGold),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStatLabel('Finish Rate', '${f1.finishRate}%'),
              _miniStatLabel('Avg Time', f1.avgFightTime),
              _miniStatLabel('Finish Rate', '${f2.finishRate}%'),
              _miniStatLabel('Avg Time', f2.avgFightTime),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBar(String label, int v1, int v2, Color color) {
    final total = v1 + v2;
    final ratio1 = total > 0 ? v1 / total : 0.5;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$v1',
                style: TextStyle(
                  color: v1 >= v2 ? color : Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              Text(
                '$v2',
                style: TextStyle(
                  color: v2 >= v1 ? color : Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 5,
            child: Row(
              children: [
                Expanded(
                  flex: (ratio1 * 100).toInt(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: v1 >= v2 ? color : color.withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: ((1 - ratio1) * 100).toInt(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: v2 >= v1 ? color : color.withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStatLabel(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  // ─── PREDICTION FORM ─────────────────────────────────────────
  Widget _buildPredictionForm() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _userPrediction != null
              ? DesignTokens.neonGreen.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR PREDICTION',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap a fighter above, then choose how and when',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          // Method selection
          const Text(
            'HOW DO THEY WIN?',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _methodChip('KO/TKO', Icons.flash_on, DesignTokens.neonRed),
              _methodChip(
                'Submission',
                Icons.handshake,
                DesignTokens.neonMagenta,
              ),
              _methodChip('Decision', Icons.gavel, DesignTokens.neonCyan),
              _methodChip('Draw', Icons.balance, DesignTokens.neonAmber),
            ],
          ),
          const SizedBox(height: 16),
          // Round selection
          if (_userMethod != null &&
              _userMethod != 'Decision' &&
              _userMethod != 'Draw') ...[
            const Text(
              'WHAT ROUND?',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) {
                final round = i + 1;
                final selected = _userRound == round;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _userRound = round),
                    child: Container(
                      margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? DesignTokens.neonGreen.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? DesignTokens.neonGreen
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'R$round',
                          style: TextStyle(
                            color: selected
                                ? DesignTokens.neonGreen
                                : Colors.white38,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
          ],
          // Submit button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_userPrediction != null && _userMethod != null)
                  ? _submitPrediction
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.neonGreen,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.06),
                disabledForegroundColor: Colors.white24,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'LOCK IN PREDICTION',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              _userPrediction != null && _userMethod != null
                  ? 'Points: +100 correct winner · +50 method · +25 round'
                  : 'Select a fighter and method to continue',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodChip(String label, IconData icon, Color color) {
    final selected = _userMethod == label;
    return GestureDetector(
      onTap: () => setState(() {
        _userMethod = label;
        if (label == 'Decision' || label == 'Draw') _userRound = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? color : Colors.white30, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── RESULT REVEAL ────────────────────────────────────────────
  Widget _buildResultReveal() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonGold.withValues(alpha: 0.08),
            DesignTokens.bgCard,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.neonGold.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Text(
            'PREDICTION LOCKED',
            style: TextStyle(
              color: DesignTokens.neonGold,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          // Your prediction
          _resultRow(
            'Your Pick',
            _userPrediction?.split('" ').last ?? '',
            DesignTokens.neonCyan,
          ),
          _resultRow('Method', _userMethod ?? '', DesignTokens.neonMagenta),
          if (_userRound != null)
            _resultRow('Round', 'Round $_userRound', DesignTokens.neonAmber),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),
          // AI prediction comparison
          _resultRow(
            'AI Pick',
            _currentFight.aiPick.split('" ').last,
            DesignTokens.neonGreen,
          ),
          _resultRow(
            'AI Method',
            _currentFight.aiMethod,
            DesignTokens.neonGreen,
          ),
          if (_currentFight.aiRound != null)
            _resultRow(
              'AI Round',
              'Round ${_currentFight.aiRound}',
              DesignTokens.neonGreen,
            ),
          _resultRow(
            'AI Confidence',
            '${_currentFight.aiConfidence}%',
            DesignTokens.neonGreen,
          ),
          if (_currentFight.actualWinner != null) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _userPrediction == _currentFight.actualWinner
                    ? DesignTokens.neonGreen.withValues(alpha: 0.1)
                    : DesignTokens.neonRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    _userPrediction == _currentFight.actualWinner
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: _userPrediction == _currentFight.actualWinner
                        ? DesignTokens.neonGreen
                        : DesignTokens.neonRed,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _userPrediction == _currentFight.actualWinner
                          ? 'CORRECT! Winner: ${_currentFight.actualWinner!.split('" ').last}'
                          : 'WRONG — Winner: ${_currentFight.actualWinner!.split('" ').last}',
                      style: TextStyle(
                        color: _userPrediction == _currentFight.actualWinner
                            ? DesignTokens.neonGreen
                            : DesignTokens.neonRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _nextFight,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.neonRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'NEXT FIGHT',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ─── AI ANALYSIS ──────────────────────────────────────────────
  Widget _buildAIAnalysis() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignTokens.neonGreen.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DesignTokens.neonGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: DesignTokens.neonGreen,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI FIGHT ANALYSIS',
                style: TextStyle(
                  color: DesignTokens.neonGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DesignTokens.neonGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_currentFight.aiConfidence}% CONFIDENCE',
                  style: const TextStyle(
                    color: DesignTokens.neonGreen,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _currentFight.aiReasoning,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _aiTag('Pick: ${_currentFight.aiPick.split('" ').last}'),
              const SizedBox(width: 6),
              _aiTag('Via ${_currentFight.aiMethod}'),
              if (_currentFight.aiRound != null) ...[
                const SizedBox(width: 6),
                _aiTag('R${_currentFight.aiRound}'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _aiTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── LEADERBOARD ──────────────────────────────────────────────
  Widget _buildLeaderboardPreview() {
    final leaders = [
      const _Leader('CageSage_MMA', 2340, 87),
      const _Leader('PredictorKing', 2180, 82),
      const _Leader('FightIQ_Pro', 1950, 79),
      const _Leader('CornerVoice', 1820, 76),
      const _Leader('StrikeOracle', 1690, 73),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.leaderboard,
                color: DesignTokens.neonGold,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'PREDICTION LEADERBOARD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                'You: #42',
                style: TextStyle(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...leaders.asMap().entries.map((e) {
            final i = e.key;
            final l = e.value;
            final colors = [
              DesignTokens.neonGold,
              const Color(0xFFC0C0C0),
              const Color(0xFFCD7F32),
              Colors.white38,
              Colors.white38,
            ];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '#${i + 1}',
                      style: TextStyle(
                        color: colors[i],
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.name,
                      style: TextStyle(
                        color: i < 3 ? Colors.white : Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${l.accuracy}%',
                    style: TextStyle(
                      color: DesignTokens.neonGreen.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${l.points} pts',
                    style: TextStyle(
                      color: colors[i],
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── DATA MODELS ────────────────────────────────────────────────

class _Fighter {
  final String name;
  final String record;
  final String weightClass;
  final String style;
  final int power;
  final int speed;
  final int cardio;
  final int ground;
  final int chin;
  final int iq;
  final String flag;
  final int finishRate;
  final String avgFightTime;
  final List<String> recentForm;

  const _Fighter({
    required this.name,
    required this.record,
    required this.weightClass,
    required this.style,
    required this.power,
    required this.speed,
    required this.cardio,
    required this.ground,
    required this.chin,
    required this.iq,
    required this.flag,
    required this.finishRate,
    required this.avgFightTime,
    required this.recentForm,
  });
}

class _FightMatchup {
  final _Fighter fighter1;
  final _Fighter fighter2;
  final String eventName;
  final String aiPick;
  final String aiMethod;
  final int? aiRound;
  final int aiConfidence;
  final String aiReasoning;
  final String? actualWinner;
  final String? actualMethod;

  const _FightMatchup({
    required this.fighter1,
    required this.fighter2,
    required this.eventName,
    required this.aiPick,
    required this.aiMethod,
    this.aiRound,
    required this.aiConfidence,
    required this.aiReasoning,
    this.actualWinner,
    this.actualMethod,
  });
}

class _Leader {
  final String name;
  final int points;
  final int accuracy;
  const _Leader(this.name, this.points, this.accuracy);
}
