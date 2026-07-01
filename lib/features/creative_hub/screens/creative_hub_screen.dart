import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/constants/app_logos.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CREATIVE HUB — Glass Morphism · AI Tools · Content Creation · Media
/// Showcase Gallery · Trending · Community Highlights
/// ═══════════════════════════════════════════════════════════════════════════

const _kCyan = Color(0xFF00F5FF);
const _kMagenta = Color(0xFFFF0080);
const _kGreen = Color(0xFF00E676);
const _kAmber = Color(0xFFFFB800);
const _kGold = Color(0xFFFFD700);
const _kBlue = Color(0xFF2979FF);
const _kRed = Color(0xFFFF5252);
const _kPanel = Color(0xFF0D1B2A);

class CreativeHubScreen extends StatefulWidget {
  const CreativeHubScreen({super.key});
  @override
  State<CreativeHubScreen> createState() => _CreativeHubScreenState();
}

class _CreativeHubScreenState extends State<CreativeHubScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTool = -1;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  static const _tools = [
    _CreativeTool(
      'PosterBoy',
      'AI poster & flyer generator',
      Icons.image,
      _kMagenta,
      '/promoter/create-campaign',
      enabled: true,
    ),
    _CreativeTool(
      'Fighter Cards',
      'Generate AI trading cards',
      Icons.style,
      _kCyan,
      '',
      enabled: true,
    ),
    _CreativeTool(
      'Event Posters',
      'Design fight night promos',
      Icons.event,
      _kAmber,
      '/promoter/event-manager',
      enabled: true,
    ),
    _CreativeTool(
      'Social Content',
      'Create posts & stories',
      Icons.share,
      _kGreen,
      '',
      enabled: true,
    ),
    _CreativeTool(
      'Video Highlights',
      'Promo video editor — 6 pics → fight video',
      Icons.movie,
      _kBlue,
      '/promo-video-editor',
      enabled: true,
    ),
    _CreativeTool(
      'Brand Kit',
      'Logos, colors & templates',
      Icons.palette,
      _kGold,
      '',
      enabled: true,
    ),
  ];

  // ── Demo showcase gallery ─────────────────────────────────────────
  static const _showcaseItems = [
    _ShowcaseItem(
      'DFC Main Card Poster',
      '@dfc_studio',
      '2.4K',
      _kMagenta,
      Icons.image,
      '',
    ),
    _ShowcaseItem(
      'Champion Trading Card',
      '@dfc_cards',
      '1.8K',
      _kCyan,
      Icons.style,
      '',
    ),
    _ShowcaseItem(
      'Event Promo Concept',
      '@dfc_events',
      '3.1K',
      _kAmber,
      Icons.event,
      '',
    ),
    _ShowcaseItem(
      'Fight Night Reel',
      '@dfc_reels',
      '5.6K',
      _kBlue,
      Icons.movie,
      '',
    ),
    _ShowcaseItem(
      'Muay Thai Spirit',
      '@dfc_gallery',
      '4.2K',
      _kGreen,
      Icons.photo_camera,
      '',
    ),
    _ShowcaseItem(
      'BKFC London Hero',
      '@dfc_bareknuckle',
      '1.5K',
      _kRed,
      Icons.camera_alt,
      '',
    ),
  ];

  // ── Trending challenges ───────────────────────────────────────────
  static const _challenges = [
    _Challenge(
      '🥊 #FightPosterChallenge',
      'Design your dream fight card — 847 entries',
      _kMagenta,
      '3d left',
    ),
    _Challenge(
      '🎨 #NeonWarrior',
      'Create a neon-lit fighter portrait — 1.2K entries',
      _kCyan,
      '5d left',
    ),
    _Challenge(
      '📸 #GymLife',
      'Best training photo of the week — 634 entries',
      _kGreen,
      '1d left',
    ),
    _Challenge(
      '🎬 #KOoftheMonth',
      'Edit the craziest KO clip — 423 entries',
      _kBlue,
      '6d left',
    ),
  ];

  // ── Community creators ────────────────────────────────────────────
  static const _topCreators = [
    _Creator('Top Creator', '@dfc_featured', '14.2K', [_kCyan, _kMagenta]),
    _Creator('Rising Star', '@dfc_rising', '11.7K', [_kMagenta, _kRed]),
    _Creator('Fight Artist', '@fight_visuals', '9.4K', [_kGold, _kAmber]),
    _Creator('Combat Creative', '@combat_creative', '8.1K', [_kGreen, _kCyan]),
    _Creator('Ring Designs', '@ring_designs', '7.3K', [_kBlue, _kCyan]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: _kPanel.withValues(alpha: 0.95),
            title: Row(
              children: [
                Image.asset(
                  AppLogos.icon,
                  width: 22,
                  height: 22,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.auto_awesome,
                    color: _kMagenta,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [_kMagenta, _kCyan],
                  ).createShader(b),
                  child: const Text(
                    'CREATIVE HUB',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              indicatorColor: _kMagenta,
              labelColor: _kMagenta,
              unselectedLabelColor: Colors.white38,
              labelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'CREATE'),
                Tab(text: 'SHOWCASE'),
                Tab(text: 'TRENDING'),
                Tab(text: 'CREATORS'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildCreateTab(),
            _buildShowcaseTab(),
            _buildTrendingTab(),
            _buildCreatorsTab(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 1 — CREATE (tools + recent + inspiration)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildCreateTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHero(),
        const SizedBox(height: 20),
        _sectionLabel('AI TOOLS', Icons.auto_awesome),
        const SizedBox(height: 10),
        ..._tools.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildToolCard(e.key, e.value),
          ),
        ),
        const SizedBox(height: 20),
        _sectionLabel('QUICK STATS', Icons.bar_chart),
        const SizedBox(height: 10),
        _buildQuickStats(),
        const SizedBox(height: 20),
        _sectionLabel('RECENT CREATIONS', Icons.history),
        const SizedBox(height: 10),
        _buildRecentGrid(),
        const SizedBox(height: 20),
        _sectionLabel('PRO TIPS', Icons.lightbulb),
        const SizedBox(height: 10),
        _buildInspirationRow(),
        const SizedBox(height: 80),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 2 — SHOWCASE GALLERY
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildShowcaseTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Featured showcase banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _kGold.withValues(alpha: 0.12),
                _kMagenta.withValues(alpha: 0.06),
                _kPanel,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kGold.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events, color: _kGold, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SHOWCASE OF THE WEEK',
                      style: TextStyle(
                        color: _kGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Community-created fight art, posters & content',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Showcase grid
        ..._showcaseItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildShowcaseCard(item),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildShowcaseCard(_ShowcaseItem item) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildSafeShowcaseArt(item),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: item.accent.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.icon, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        const Text(
                          'FEATURED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 12,
                  right: 12,
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [item.accent, _kCyan]),
                  ),
                  child: Center(
                    child: Text(
                      item.creator[1].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.creator,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
                Icon(
                  Icons.favorite,
                  color: _kRed.withValues(alpha: 0.7),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  item.likes,
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
    );
  }

  Widget _buildSafeShowcaseArt(_ShowcaseItem item) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            item.accent.withValues(alpha: 0.32),
            _kPanel,
            _kBlue.withValues(alpha: 0.18),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -28,
            right: -14,
            child: Icon(
              item.icon,
              color: Colors.white.withValues(alpha: 0.08),
              size: 140,
            ),
          ),
          Positioned(
            bottom: -12,
            left: -10,
            child: Icon(
              item.icon,
              color: item.accent.withValues(alpha: 0.2),
              size: 92,
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: item.accent.withValues(alpha: 0.45)),
              ),
              child: Text(
                'DFC DEMO ART',
                style: TextStyle(
                  color: item.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 3 — TRENDING CHALLENGES
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildTrendingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionLabel('ACTIVE CHALLENGES', Icons.local_fire_department),
        const SizedBox(height: 12),
        ..._challenges.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildChallengeCard(c),
          ),
        ),
        const SizedBox(height: 20),
        _sectionLabel('TRENDING TAGS', Icons.tag),
        const SizedBox(height: 12),
        _buildTrendingTags(),
        const SizedBox(height: 20),
        _sectionLabel('WEEKLY LEADERBOARD', Icons.leaderboard),
        const SizedBox(height: 12),
        _buildLeaderboard(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildChallengeCard(_Challenge c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_fire_department,
                  color: c.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      style: TextStyle(
                        color: c.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      c.subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  c.deadline,
                  style: TextStyle(
                    color: c.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [c.accent, c.accent.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ENTER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingTags() {
    final tags = [
      ('#FightArt', _kMagenta, '12.4K'),
      ('#UFCPoster', _kCyan, '8.7K'),
      ('#MuayThaiLife', _kAmber, '6.2K'),
      ('#BJJFlow', _kGreen, '5.9K'),
      ('#FighterCards', _kBlue, '4.8K'),
      ('#KnockoutEdit', _kRed, '3.5K'),
      ('#GymGrind', _kGold, '2.9K'),
      ('#CombatSport', _kCyan, '2.1K'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((t) {
        final (tag, color, count) = t;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tag,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                count,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLeaderboard() {
    final leaders = [
      ('1', 'Marcus Cole', '24.8K pts', _kGold),
      ('2', 'Yuki Tanaka', '21.3K pts', const Color(0xFFC0C0C0)),
      ('3', 'Sarah Blackwood', '18.6K pts', const Color(0xFFCD7F32)),
      ('4', 'Diego Santos', '15.2K pts', Colors.white38),
      ('5', 'Ali Hassan', '12.9K pts', Colors.white38),
    ];
    return Column(
      children: leaders.map((l) {
        final (rank, name, pts, color) = l;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    rank,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                pts,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 4 — TOP CREATORS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildCreatorsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionLabel('TOP CREATORS', Icons.star),
        const SizedBox(height: 12),
        ..._topCreators.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildCreatorCard(e.key, e.value),
          ),
        ),
        const SizedBox(height: 20),
        _sectionLabel('CREATOR SPOTLIGHT', Icons.auto_awesome),
        const SizedBox(height: 12),
        _buildSpotlight(),
        const SizedBox(height: 20),
        _sectionLabel('BECOME A CREATOR', Icons.rocket_launch),
        const SizedBox(height: 12),
        _buildBecomeCreator(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildCreatorCard(int i, _Creator c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.gradient[0].withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: c.gradient),
            ),
            child: Center(
              child: Text(
                c.name[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      c.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: _kCyan, size: 14),
                  ],
                ),
                Text(
                  c.handle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                c.followers,
                style: TextStyle(
                  color: c.gradient[0],
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'followers',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: c.gradient[0].withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.gradient[0].withValues(alpha: 0.25)),
            ),
            child: Text(
              'Follow',
              style: TextStyle(
                color: c.gradient[0],
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotlight() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kMagenta.withValues(alpha: 0.08),
            _kCyan.withValues(alpha: 0.04),
            _kPanel,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kMagenta.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [_kMagenta, _kCyan]),
                ),
                child: const Center(
                  child: Text(
                    'M',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text(
                          'Marcus Cole',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.verified, color: _kGold, size: 16),
                      ],
                    ),
                    Text(
                      '@ronin_designs · Fighter / Artist',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"I started designing fight posters for my gym in Phuket. Now brands from UFC to ONE reach out. DFC\'s AI tools cut my design time from hours to minutes."',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _spotStat('248', 'Creations', _kMagenta),
              const SizedBox(width: 12),
              _spotStat('14.2K', 'Followers', _kCyan),
              const SizedBox(width: 12),
              _spotStat('89K', 'Total Likes', _kGold),
            ],
          ),
        ],
      ),
    );
  }

  Widget _spotStat(String value, String label, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: c,
              fontSize: 13,
              fontWeight: FontWeight.w800,
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
      ),
    );
  }

  Widget _buildBecomeCreator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kGreen.withValues(alpha: 0.08),
            _kCyan.withValues(alpha: 0.04),
            _kPanel,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kGreen.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'JOIN THE CREATOR PROGRAM',
            style: TextStyle(
              color: _kGreen,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Monetize your fight art. Get featured. Earn royalties on NFT drops and marketplace sales.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _creatorPerk(Icons.monetization_on, 'Earn', _kGold),
              const SizedBox(width: 10),
              _creatorPerk(Icons.star, 'Featured', _kMagenta),
              const SizedBox(width: 10),
              _creatorPerk(Icons.groups, 'Community', _kCyan),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_kGreen, _kCyan]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'APPLY',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _creatorPerk(IconData icon, String label, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SHARED WIDGETS — Hero · Tool card · Stats · Recent · Tips
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _kMagenta.withValues(alpha: 0.12),
            _kCyan.withValues(alpha: 0.06),
            _kPanel,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kMagenta.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(color: _kMagenta.withValues(alpha: 0.05), blurRadius: 24),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _kMagenta.withValues(alpha: 0.2),
                  _kCyan.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: _kMagenta, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI CREATION STUDIO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Design posters, cards, promos & social with AI',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final stats = [
      ('12.4K', 'Total\nCreations', _kMagenta),
      ('847', 'Active\nCreators', _kCyan),
      ('28.6K', 'Community\nLikes', _kGold),
      ('156', 'This\nWeek', _kGreen),
    ];
    return Row(
      children: stats.map((s) {
        final (value, label, color) = s;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 8,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildToolCard(int index, _CreativeTool tool) {
    final isSelected = _selectedTool == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTool = index);
        if (tool.route.isNotEmpty) {
          context.push(tool.route);
        } else {
          showModalBottomSheet(
            context: context,
            backgroundColor: _kPanel,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Icon(tool.icon, color: tool.color, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    tool.name.toUpperCase(),
                    style: TextStyle(
                      color: tool.color,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI-powered ${tool.description.toLowerCase()}. Upload your content and let our engine create professional results in seconds.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(tool.icon, color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text('${tool.name} workspace launching soon!'),
                              ],
                            ),
                            backgroundColor: tool.color.withValues(alpha: 0.9),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tool.color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'LAUNCH WORKSPACE',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tool.color.withValues(alpha: isSelected ? 0.12 : 0.04),
              Colors.white.withValues(alpha: 0.01),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tool.color.withValues(alpha: isSelected ? 0.3 : 0.08),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tool.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(tool.icon, color: tool.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tool.name.toUpperCase(),
                    style: TextStyle(
                      color: tool.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    tool.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: tool.color.withValues(alpha: 0.3),
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentGrid() {
    final items = [
      ('UFC 313 Poster', _kMagenta, Icons.image, '2h ago'),
      ('Aliyev Card', _kCyan, Icons.style, '5h ago'),
      ('ONE 170 Promo', _kAmber, Icons.event, '1d ago'),
      ('Training Reel', _kGreen, Icons.movie, '2d ago'),
      ('Brand Banner', _kGold, Icons.palette, '3d ago'),
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final (label, color, icon, time) = items[i];
          return Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color.withValues(alpha: 0.5), size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInspirationRow() {
    final tips = [
      (
        '🎯',
        'Use bold contrasting colors for fight posters — red + cyan pops on dark backgrounds',
      ),
      (
        '⚡',
        'Add neon glow effects for premium look — DFC\'s AI engine generates them automatically',
      ),
      (
        '🏆',
        'Include fighter stats and records on trading cards — fans love data-driven art',
      ),
      (
        '📱',
        'Design in 1080×1080 for Instagram, 1920×1080 for YouTube thumbnails',
      ),
      (
        '🔥',
        'Trending style: Dark backgrounds + metallic text + fighter silhouettes',
      ),
    ];

    return Column(
      children: tips.map((tip) {
        final (emoji, text) = tip;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: _kCyan,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, color: _kCyan.withValues(alpha: 0.4), size: 14),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────

class _CreativeTool {
  final String name, description, route;
  final IconData icon;
  final Color color;
  final bool enabled;
  const _CreativeTool(
    this.name,
    this.description,
    this.icon,
    this.color,
    this.route, {
    this.enabled = false,
  });
}

class _ShowcaseItem {
  final String title, creator, likes, imageUrl;
  final Color accent;
  final IconData icon;
  const _ShowcaseItem(
    this.title,
    this.creator,
    this.likes,
    this.accent,
    this.icon,
    this.imageUrl,
  );
}

class _Challenge {
  final String title, subtitle, deadline;
  final Color accent;
  const _Challenge(this.title, this.subtitle, this.accent, this.deadline);
}

class _Creator {
  final String name, handle, followers;
  final List<Color> gradient;
  const _Creator(this.name, this.handle, this.followers, this.gradient);
}
