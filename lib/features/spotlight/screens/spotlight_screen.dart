import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SPOTLIGHT — Fighter / Gym / Event of the Week
/// Netflix-level editorial curation with rotating spotlights, hero cards,
/// and community voting. The front-page billboard of combat sports.
/// ═══════════════════════════════════════════════════════════════════════════
class SpotlightScreen extends StatefulWidget {
  const SpotlightScreen({super.key});

  @override
  State<SpotlightScreen> createState() => _SpotlightScreenState();
}

class _SpotlightScreenState extends State<SpotlightScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final PageController _heroController;
  Timer? _autoScrollTimer;
  int _currentHeroPage = 0;

  // Demo spotlight data
  final List<_SpotlightEntry> _heroSpotlights = [
    const _SpotlightEntry(
      id: 'fighter-week',
      type: SpotlightType.fighter,
      title: 'FIGHTER OF THE WEEK',
      name: 'Stamp Fairtex',
      subtitle: 'ONE Atomweight World Champion',
      location: '🇹🇭 Bangkok, Thailand',
      stat1Label: 'Record',
      stat1Value: '67-18-5',
      stat2Label: 'KO Rate',
      stat2Value: '38%',
      stat3Label: 'Titles',
      stat3Value: '3',
      quote: '"Train hard, fight easy. Every day is a chance to evolve."',
      accentColor: AppTheme.neonCyan,
      icon: Icons.sports_mma,
    ),
    const _SpotlightEntry(
      id: 'gym-week',
      type: SpotlightType.gym,
      title: 'GYM OF THE WEEK',
      name: 'Tiger Muay Thai',
      subtitle: 'World-Class Training Facility',
      location: '🇹🇭 Phuket, Thailand',
      stat1Label: 'Fighters',
      stat1Value: '200+',
      stat2Label: 'Champions',
      stat2Value: '12',
      stat3Label: 'Disciplines',
      stat3Value: '8',
      quote: 'Home of champions from MMA, Muay Thai, Boxing, and BJJ.',
      accentColor: AppTheme.neonMagenta,
      icon: Icons.fitness_center,
    ),
    const _SpotlightEntry(
      id: 'event-week',
      type: SpotlightType.event,
      title: 'EVENT OF THE WEEK',
      name: 'IBC 03: Gold Coast',
      subtitle: 'Live from Gold Coast Convention Centre',
      location: '🇦🇺 Gold Coast, Australia',
      stat1Label: 'Bouts',
      stat1Value: '12',
      stat2Label: 'PPV Price',
      stat2Value: '\$24.99',
      stat3Label: 'Countries',
      stat3Value: '6',
      quote: 'The biggest combat sports event to hit the Gold Coast.',
      accentColor: AppTheme.neonOrange,
      icon: Icons.stadium,
    ),
    const _SpotlightEntry(
      id: 'moment-week',
      type: SpotlightType.moment,
      title: 'VIRAL MOMENT',
      name: 'Flying Knee KO — Round 1',
      subtitle: 'Most replayed highlight this week',
      location: '🌍 Global Trending',
      stat1Label: 'Views',
      stat1Value: '2.4M',
      stat2Label: 'Shares',
      stat2Value: '89K',
      stat3Label: 'Reactions',
      stat3Value: '412K',
      quote: 'The knockout that stopped the internet.',
      accentColor: AppTheme.neonGreen,
      icon: Icons.local_fire_department,
    ),
  ];

  final List<_SpotlightEntry> _risingStars = [
    const _SpotlightEntry(
      id: 'rising-1',
      type: SpotlightType.fighter,
      title: 'RISING',
      name: 'Jai Opetaia',
      subtitle: 'IBF Cruiserweight Champion',
      location: '🇦🇺 Sydney, Australia',
      stat1Label: 'Record',
      stat1Value: '24-0',
      stat2Label: 'KOs',
      stat2Value: '19',
      stat3Label: 'Rank',
      stat3Value: '#1',
      accentColor: AppTheme.neonCyan,
      icon: Icons.trending_up,
    ),
    const _SpotlightEntry(
      id: 'rising-2',
      type: SpotlightType.fighter,
      title: 'RISING',
      name: 'Denice Zamboanga',
      subtitle: 'ONE Atomweight Contender',
      location: '🇵🇭 Manila, Philippines',
      stat1Label: 'Record',
      stat1Value: '10-3',
      stat2Label: 'Finish Rate',
      stat2Value: '70%',
      stat3Label: 'Streak',
      stat3Value: '3W',
      accentColor: AppTheme.neonMagenta,
      icon: Icons.trending_up,
    ),
    const _SpotlightEntry(
      id: 'rising-3',
      type: SpotlightType.fighter,
      title: 'RISING',
      name: 'Shara Magomedov',
      subtitle: 'UFC Middleweight Prospect',
      location: '🇷🇺 Dagestan, Russia',
      stat1Label: 'Record',
      stat1Value: '14-0',
      stat2Label: 'KOs',
      stat2Value: '10',
      stat3Label: 'Debut',
      stat3Value: '2024',
      accentColor: AppTheme.neonGreen,
      icon: Icons.trending_up,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _heroController = PageController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      _currentHeroPage = (_currentHeroPage + 1) % _heroSpotlights.length;
      _heroController.animateToPage(
        _currentHeroPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _tabController.dispose();
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            _buildHeader(context),
            // ── Tabs ──
            Container(
              color: AppTheme.secondaryBackground,
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'This Week'),
                  Tab(text: 'Rising Stars'),
                  Tab(text: 'Hall of Fame'),
                ],
                labelColor: AppTheme.neonCyan,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.neonCyan,
              ),
            ),
            // ── Content ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildThisWeekTab(),
                  _buildRisingStarsTab(),
                  _buildHallOfFameTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(left: 4, right: 8),
            child: Image.asset(
              'assets/logos/dfc_icon_transparent.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.star, color: Colors.cyanAccent, size: 20),
            ),
          ),
          IconButton(
            tooltip: 'Back',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
          ),
          const Text(
            '🏆 SPOTLIGHT',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.neonCyan.withValues(alpha: 0.3),
                  AppTheme.neonMagenta.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'WEEKLY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── This Week Tab ──────────────────────────────────────────────────────

  Widget _buildThisWeekTab() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Hero carousel
        SizedBox(
          height: 340,
          child: PageView.builder(
            controller: _heroController,
            itemCount: _heroSpotlights.length,
            onPageChanged: (i) => setState(() => _currentHeroPage = i),
            itemBuilder: (context, index) =>
                _buildHeroCard(_heroSpotlights[index]),
          ),
        ),
        // Page indicators
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _heroSpotlights.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _currentHeroPage ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: i == _currentHeroPage
                      ? _heroSpotlights[i].accentColor
                      : Colors.grey.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ),
        // Community vote section
        _buildVoteSection(),
        const SizedBox(height: 16),
        // Quick stats
        _buildQuickStats(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHeroCard(_SpotlightEntry entry) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            entry.accentColor.withValues(alpha: 0.15),
            AppTheme.cardBackground,
            AppTheme.primaryBackground,
          ],
        ),
        border: Border.all(
          color: entry.accentColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: entry.accentColor.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: entry.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: entry.accentColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(entry.icon, size: 14, color: entry.accentColor),
                      const SizedBox(width: 6),
                      Text(
                        entry.title,
                        style: TextStyle(
                          color: entry.accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  entry.location,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Name
            Text(
              entry.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              entry.subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const Spacer(),
            // Quote
            if (entry.quote != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.quote!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const Spacer(),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatPill(
                  entry.stat1Label,
                  entry.stat1Value,
                  entry.accentColor,
                ),
                _buildStatPill(
                  entry.stat2Label,
                  entry.stat2Value,
                  entry.accentColor,
                ),
                _buildStatPill(
                  entry.stat3Label,
                  entry.stat3Value,
                  entry.accentColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color accent) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: accent,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildVoteSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.how_to_vote, color: AppTheme.neonCyan, size: 18),
              SizedBox(width: 8),
              Text(
                'COMMUNITY VOTE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Who should be next week\'s Fighter of the Week?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          _buildVoteOption('Jai Opetaia', '🇦🇺', 0.42, AppTheme.neonCyan),
          const SizedBox(height: 6),
          _buildVoteOption(
            'Denice Zamboanga',
            '🇵🇭',
            0.31,
            AppTheme.neonMagenta,
          ),
          const SizedBox(height: 6),
          _buildVoteOption('Shara Magomedov', '🇷🇺', 0.27, AppTheme.neonGreen),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '1,247 votes this week',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteOption(String name, String flag, double pct, Color color) {
    return Row(
      children: [
        Text(flag, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(pct * 100).toInt()}%',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neonMagenta.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 THIS WEEK IN NUMBERS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildWeekStat('Events', '47', AppTheme.neonCyan),
              _buildWeekStat('Bouts', '312', AppTheme.neonMagenta),
              _buildWeekStat('Countries', '23', AppTheme.neonGreen),
              _buildWeekStat('KOs', '89', AppTheme.neonOrange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ── Rising Stars Tab ───────────────────────────────────────────────────

  Widget _buildRisingStarsTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.neonCyan.withValues(alpha: 0.1),
                AppTheme.neonMagenta.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.2)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🚀 RISING STARS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Fighters gaining momentum across DFC this week',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ..._risingStars.asMap().entries.map(
          (e) => _buildRisingStarCard(e.key + 1, e.value),
        ),
      ],
    );
  }

  Widget _buildRisingStarCard(int rank, _SpotlightEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: entry.accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  entry.accentColor.withValues(alpha: 0.3),
                  entry.accentColor.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: entry.accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${entry.location} • ${entry.subtitle}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.stat1Value,
                style: TextStyle(
                  color: entry.accentColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                entry.stat1Label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Hall of Fame Tab ───────────────────────────────────────────────────

  Widget _buildHallOfFameTab() {
    final legends = [
      const _LegendEntry(
        'Amanda Nunes',
        '🇧🇷',
        '23-5',
        'GOAT of Women\'s MMA',
        AppTheme.neonCyan,
      ),
      const _LegendEntry(
        'Buakaw Banchamek',
        '🇹🇭',
        '241-24-12',
        'Muay Thai Legend',
        AppTheme.neonOrange,
      ),
      const _LegendEntry(
        'Manny Pacquiao',
        '🇵🇭',
        '62-8-2',
        '8-Division World Champion',
        AppTheme.neonMagenta,
      ),
      const _LegendEntry(
        'Fedor Emelianenko',
        '🇷🇺',
        '40-6',
        'Last Emperor of MMA',
        AppTheme.neonGreen,
      ),
      const _LegendEntry(
        'Cris Cyborg',
        '🇧🇷',
        '27-2',
        'Most Dominant Female Striker',
        AppTheme.neonCyan,
      ),
      const _LegendEntry(
        'Saenchai',
        '🇹🇭',
        '300+',
        'Living Muay Thai Deity',
        AppTheme.neonOrange,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.neonOrange.withValues(alpha: 0.1),
                AppTheme.neonMagenta.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.neonOrange.withValues(alpha: 0.2),
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🏛️ HALL OF FAME',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Legends who shaped combat sports history',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...legends.map(_buildLegendCard),
      ],
    );
  }

  Widget _buildLegendCard(_LegendEntry legend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: legend.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: legend.color.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(legend.flag, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  legend.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  legend.title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: legend.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              legend.record,
              style: TextStyle(
                color: legend.color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data Models ─────────────────────────────────────────────────────────

enum SpotlightType { fighter, gym, event, moment }

class _SpotlightEntry {
  final String id;
  final SpotlightType type;
  final String title;
  final String name;
  final String subtitle;
  final String location;
  final String stat1Label;
  final String stat1Value;
  final String stat2Label;
  final String stat2Value;
  final String stat3Label;
  final String stat3Value;
  final String? quote;
  final Color accentColor;
  final IconData icon;

  const _SpotlightEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.name,
    required this.subtitle,
    required this.location,
    required this.stat1Label,
    required this.stat1Value,
    required this.stat2Label,
    required this.stat2Value,
    required this.stat3Label,
    required this.stat3Value,
    this.quote,
    required this.accentColor,
    required this.icon,
  });
}

class _LegendEntry {
  final String name;
  final String flag;
  final String record;
  final String title;
  final Color color;

  const _LegendEntry(this.name, this.flag, this.record, this.title, this.color);
}
