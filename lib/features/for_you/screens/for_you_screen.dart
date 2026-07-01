import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FOR YOU — Netflix-level Personalised Discovery
/// 10-factor ranking engine (relationship 40%, gym 15%, location 10%, etc.)
/// powers every card. Surfaces fighters, events, content, and training
/// opportunities algorithmically — not chronologically.
/// ═══════════════════════════════════════════════════════════════════════════
class ForYouScreen extends StatefulWidget {
  const ForYouScreen({super.key});

  @override
  State<ForYouScreen> createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Demo personalised data - in production this comes from FeedRankingEngine
  final List<_ForYouCard> _fighterRecs = [
    const _ForYouCard(
      id: 'rec-1',
      title: 'Stamp Fairtex',
      subtitle: 'ONE Atomweight Champion',
      reason: 'Trains Muay Thai like you • 93% match',
      location: '🇹🇭 Bangkok',
      matchScore: 0.93,
      category: 'Fighter',
      accent: AppTheme.neonCyan,
      icon: Icons.sports_mma,
    ),
    const _ForYouCard(
      id: 'rec-2',
      title: 'Robert Whittaker',
      subtitle: 'UFC Middleweight',
      reason: 'Same region — Australia & NZ • 88% match',
      location: '🇦🇺 Sydney',
      matchScore: 0.88,
      category: 'Fighter',
      accent: AppTheme.neonCyan,
      icon: Icons.sports_mma,
    ),
    const _ForYouCard(
      id: 'rec-3',
      title: 'Denice Zamboanga',
      subtitle: 'ONE Atomweight Contender',
      reason: 'Your gym follows her • 82% match',
      location: '🇵🇭 Manila',
      matchScore: 0.82,
      category: 'Fighter',
      accent: AppTheme.neonCyan,
      icon: Icons.sports_mma,
    ),
  ];

  final List<_ForYouCard> _eventRecs = [
    const _ForYouCard(
      id: 'evt-1',
      title: 'IBC 03: Gold Coast',
      subtitle: 'Dec 14, 2025 • 12 Bouts',
      reason: 'Near your location • fighters you follow',
      location: '🇦🇺 Gold Coast',
      matchScore: 0.96,
      category: 'Event',
      accent: AppTheme.neonOrange,
      icon: Icons.stadium,
    ),
    const _ForYouCard(
      id: 'evt-2',
      title: 'UFC 310: Pantoja vs Asakura',
      subtitle: 'Flyweight Championship',
      reason: 'Trending globally • MMA discipline match',
      location: '🇺🇸 Las Vegas',
      matchScore: 0.85,
      category: 'Event',
      accent: AppTheme.neonOrange,
      icon: Icons.stadium,
    ),
    const _ForYouCard(
      id: 'evt-3',
      title: 'ONE Fight Night 28',
      subtitle: 'Muay Thai Super Series',
      reason: 'Your style: Muay Thai • 79% match',
      location: '🇹🇭 Bangkok',
      matchScore: 0.79,
      category: 'Event',
      accent: AppTheme.neonOrange,
      icon: Icons.stadium,
    ),
  ];

  final List<_ForYouCard> _trainingRecs = [
    const _ForYouCard(
      id: 'trn-1',
      title: 'Tiger Muay Thai',
      subtitle: 'World-class Muay Thai facility',
      reason: 'Your discipline • top-rated in Asia-Pacific',
      location: '🇹🇭 Phuket',
      matchScore: 0.91,
      category: 'Gym',
      accent: AppTheme.neonMagenta,
      icon: Icons.fitness_center,
    ),
    const _ForYouCard(
      id: 'trn-2',
      title: 'City Kickboxing',
      subtitle: 'MMA • Kickboxing • Wrestling',
      reason: 'Nearest elite gym • 2 champions train here',
      location: '🇳🇿 Auckland',
      matchScore: 0.87,
      category: 'Gym',
      accent: AppTheme.neonMagenta,
      icon: Icons.fitness_center,
    ),
    const _ForYouCard(
      id: 'trn-3',
      title: '5-Round Cardio Kickboxing',
      subtitle: 'Coach Mendez Program',
      reason: 'Matches your fight camp phase',
      location: '🌍 Online',
      matchScore: 0.84,
      category: 'Program',
      accent: AppTheme.neonGreen,
      icon: Icons.play_circle_fill,
    ),
  ];

  final List<_ForYouCard> _contentRecs = [
    const _ForYouCard(
      id: 'cnt-1',
      title: 'Flying Knee KO Breakdown',
      subtitle: '2.4M views • Trending',
      reason: 'Based on clips you watched',
      location: '🌍 Global',
      matchScore: 0.94,
      category: 'Highlight',
      accent: AppTheme.neonGreen,
      icon: Icons.play_arrow,
    ),
    const _ForYouCard(
      id: 'cnt-2',
      title: 'Whittaker vs. Adesanya Analysis',
      subtitle: 'Article • 8 min read',
      reason: 'You follow both fighters',
      location: '🌍 FightWire',
      matchScore: 0.86,
      category: 'Article',
      accent: AppTheme.neonGreen,
      icon: Icons.article,
    ),
    const _ForYouCard(
      id: 'cnt-3',
      title: 'Muay Thai Clinch Masterclass',
      subtitle: 'Video • Saenchai Training',
      reason: 'Your discipline + skill gap detected',
      location: '🇹🇭 Bangkok',
      matchScore: 0.81,
      category: 'Training',
      accent: AppTheme.neonGreen,
      icon: Icons.school,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            // Algorithm banner
            _buildAlgorithmBanner(),
            // Tabs
            Container(
              color: AppTheme.secondaryBackground,
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Fighters'),
                  Tab(text: 'Events'),
                  Tab(text: 'Training'),
                  Tab(text: 'Content'),
                ],
                labelColor: AppTheme.neonCyan,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.neonCyan,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRecList(_fighterRecs),
                  _buildRecList(_eventRecs),
                  _buildRecList(_trainingRecs),
                  _buildRecList(_contentRecs),
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
              errorBuilder: (_, _, _) => const Icon(
                Icons.auto_awesome,
                color: Colors.cyanAccent,
                size: 20,
              ),
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
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppTheme.neonCyan, AppTheme.neonMagenta],
            ).createShader(bounds),
            child: const Text(
              'FOR YOU',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.tune,
              color: AppTheme.neonCyan.withValues(alpha: 0.7),
              size: 20,
            ),
            onPressed: () => _showPreferencesSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAlgorithmBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonCyan.withValues(alpha: 0.08),
            AppTheme.neonMagenta.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: AppTheme.neonCyan.withValues(alpha: 0.8),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ranked by relationship strength, gym affiliation, location, training style & more',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecList(List<_ForYouCard> cards) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: cards.length,
      itemBuilder: (context, index) => _buildRecCard(cards[index], index + 1),
    );
  }

  Widget _buildRecCard(_ForYouCard card, int rank) {
    final pct = (card.matchScore * 100).toInt();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: card.accent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: card.accent.withValues(alpha: 0.08), blurRadius: 12),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: rank + category + match score
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: card.accent.withValues(alpha: 0.15),
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        color: card.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: card.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(card.icon, size: 12, color: card.accent),
                      const SizedBox(width: 4),
                      Text(
                        card.category,
                        style: TextStyle(
                          color: card.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Match score badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        card.accent.withValues(alpha: 0.25),
                        card.accent.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$pct% MATCH',
                    style: TextStyle(
                      color: card.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Title + subtitle
            Text(
              card.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              card.subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            // Location
            Text(
              card.location,
              style: TextStyle(
                color: card.accent.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            // Reason bar
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: card.accent.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      card.reason,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Match quality bar
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: card.matchScore,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation(card.accent),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPreferencesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Algorithm Preferences',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _buildPrefSlider('Relationship Weight', 0.40, AppTheme.neonCyan),
            _buildPrefSlider('Gym Affiliation', 0.15, AppTheme.neonMagenta),
            _buildPrefSlider('Location Proximity', 0.10, AppTheme.neonGreen),
            _buildPrefSlider('Training Style', 0.08, AppTheme.neonOrange),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '10-factor ranking • Spreads opportunity, not toxicity',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildPrefSlider(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(value * 100).toInt()}%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data Model ──────────────────────────────────────────────────────────

class _ForYouCard {
  final String id;
  final String title;
  final String subtitle;
  final String reason;
  final String location;
  final double matchScore;
  final String category;
  final Color accent;
  final IconData icon;

  const _ForYouCard({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.reason,
    required this.location,
    required this.matchScore,
    required this.category,
    required this.accent,
    required this.icon,
  });
}
