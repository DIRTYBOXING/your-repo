import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_logos.dart';
import '../../../core/theme/design_tokens.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// HOW WE WORK — DFC Value Showcase & Service Overview
//
// This is the single page that tells every visitor exactly what DFC does,
// how we power promotions across all channels, subscription tiers with
// bang-for-buck, and why we're the promotional workhorse — not a competitor.
//
// STRUCTURE:
//  1. Hero banner — Mission statement with particle background
//  2. "We Are The Promotional Workhorse" manifesto
//  3. How We Work Across All Channels — multi-channel exposure grid
//  4. What You Get — platform pillars (8 feature categories)
//  5. Proof In Our Productions — results & statsbar
//  6. Who We Serve — role cards (Fighter/Promoter/Fan/Coach/Gym/Sponsor)
//  7. Subscription Tiers — bang-for-buck pricing comparison
//  8. The Adrenaline Path — philosophy section (life through sport)
//  9. CTA — Join / Explore
// ═══════════════════════════════════════════════════════════════════════════════

class HowWeWorkScreen extends StatefulWidget {
  const HowWeWorkScreen({super.key});

  @override
  State<HowWeWorkScreen> createState() => _HowWeWorkScreenState();
}

class _HowWeWorkScreenState extends State<HowWeWorkScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _shimmerCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  static const _cyan = DesignTokens.neonCyan;
  static const _green = DesignTokens.neonGreen;
  static const _magenta = DesignTokens.neonMagenta;
  static const _amber = DesignTokens.neonAmber;
  static const _red = DesignTokens.neonRed;
  static const _gold = DesignTokens.neonGold;
  static const _bg = DesignTokens.bgPrimary;
  static const _bgCard = DesignTokens.bgCard;
  static const _bgSec = DesignTokens.bgSecondary;

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w > 800;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            pinned: true,
            backgroundColor: _bg.withValues(alpha: 0.95),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: _cyan),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/landing'),
            ),
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    AppLogos.icon,
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'HOW WE WORK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            actions: [
              Semantics(
                label: 'data-test=how-we-work-cta-view-plans',
                child: TextButton(
                  onPressed: () => context.push('/subscription'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_cyan, _green]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'VIEW PLANS',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHeroBanner(isWide),
                _buildManifesto(isWide),
                _buildChannelsSection(isWide),
                _buildPlatformPillars(isWide),
                _buildProofSection(isWide),
                _buildWhoWeServe(isWide),
                _buildPricingSection(isWide),
                _buildAdrenalinePath(isWide),
                _buildFinalCTA(isWide),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. HERO BANNER — Mission Statement
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeroBanner(bool isWide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 60 : 20,
        vertical: isWide ? 80 : 50,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_bg, Color(0xFF0A1628), Color(0xFF0D1520)],
        ),
      ),
      child: Column(
        children: [
          // Glow ring
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, _) => Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _cyan.withValues(alpha: _pulse.value),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _cyan.withValues(alpha: _pulse.value * 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.hub, color: _cyan, size: 48),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Semantics(
            label: 'data-test=how-we-work-hero-headline',
            child: Text(
              'DATA FIGHT CENTRAL',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isWide ? 42 : 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [_cyan, _green, _cyan],
                  ).createShader(const Rect.fromLTWH(0, 0, 400, 50)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'THE PROMOTIONAL WORKHORSE\nOF COMBAT SPORTS',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isWide ? 20 : 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Text(
              'We don\'t compete with anyone. We power the entire ecosystem.\n'
              'Every promoter, every fighter, every event, every fan — '
              'we give you the platform, the tools, and the exposure '
              'to make your vision a reality.\n\n'
              'DFC does not custody promoter payouts. Funds are processed via '
              'payment rails and paid out to the promoter\'s connected account '
              'per settlement policy.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isWide ? 16 : 13,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. MANIFESTO — "We Are The Promotional Workhorse"
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildManifesto(bool isWide) {
    final statements = [
      const _ManifestoItem(
        icon: Icons.handshake,
        color: _green,
        title: 'WE EMBRACE EVERYONE',
        body:
            'Every promotion, every show, every event — from local grassroots '
            'fight nights to world-class championship bouts. We don\'t pick sides. '
            'We power YOUR vision across all channels.',
      ),
      const _ManifestoItem(
        icon: Icons.campaign,
        color: _cyan,
        title: 'YOUR PROMOTIONAL ENGINE',
        body:
            'DFC is the machine behind your media. We handle fight cards, promo '
            'videos, social reach, event analytics, fighter databases, and audience '
            'engagement — so you can focus on putting on a show.',
      ),
      const _ManifestoItem(
        icon: Icons.public,
        color: _amber,
        title: 'ALL MEDIA. ALL PLATFORMS.',
        body:
            'Web, mobile, social feeds, live streams, PPV, fight wire, newsletters, '
            'embeddable widgets — we push your content everywhere your audience lives. '
            'One upload, maximum exposure.',
      ),
      const _ManifestoItem(
        icon: Icons.favorite,
        color: _red,
        title: 'WE LOVE COMBAT SPORTS',
        body:
            'This isn\'t a corporate play. DFC was built by people who live this sport. '
            'We exist to elevate fighters, empower promoters, connect fans, and grow '
            'the combat sports community worldwide.',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 60 : 16, vertical: 40),
      color: _bgSec,
      child: Column(
        children: [
          _sectionBadge('OUR MISSION', _green),
          const SizedBox(height: 8),
          Text(
            'We Are The Promotional Workhorse',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isWide ? 28 : 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 30),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: statements
                  .map((s) => Expanded(child: _manifestoCard(s)))
                  .toList(),
            )
          else
            ...statements.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _manifestoCard(s),
              ),
            ),
        ],
      ),
    );
  }

  Widget _manifestoCard(_ManifestoItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            item.title,
            style: TextStyle(
              color: item.color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. HOW WE WORK ACROSS ALL CHANNELS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildChannelsSection(bool isWide) {
    final channels = [
      const _ChannelItem(
        Icons.language,
        'WEB PLATFORM',
        'Full-featured web app at datafightcentral.com — profiles, events, feed, maps, marketplace',
        _cyan,
      ),
      const _ChannelItem(
        Icons.phone_android,
        'MOBILE APP',
        'Native iOS & Android experience — train, compete, connect on the go',
        _green,
      ),
      const _ChannelItem(
        Icons.live_tv,
        'LIVE STREAMING',
        'PPV broadcasts, live event coverage, real-time fight commentary',
        _red,
      ),
      const _ChannelItem(
        Icons.newspaper,
        'FIGHTWIRE NEWS',
        'Breaking combat sports news, fight results, industry intel 24/7',
        _amber,
      ),
      const _ChannelItem(
        Icons.people,
        'SOCIAL FEED',
        'Community-driven content — posts, media, reactions, follow fighters',
        _magenta,
      ),
      const _ChannelItem(
        Icons.smart_display,
        'VIDEO & MEDIA',
        'Promo videos, highlight reels, walkout footage, behind the scenes',
        Color(0xFF4A9EFF),
      ),
      const _ChannelItem(
        Icons.map_outlined,
        'GLOBAL FIGHT MAP',
        'Discover gyms, events, fighters, promotions worldwide on Earth Map',
        _gold,
      ),
      const _ChannelItem(
        Icons.psychology,
        'AI INTELLIGENCE',
        'Samurai Shido AI — fight predictions, coaching insights, pattern analysis',
        Color(0xFF9D00FF),
      ),
      const _ChannelItem(
        Icons.store,
        'MARKETPLACE',
        'Buy, sell, trade — gear, services, fight bookings, sponsorships',
        _green,
      ),
      const _ChannelItem(
        Icons.campaign,
        'PROMO ENGINE',
        'Marketing HQ, SEO tools, social queue, QR promos, content calendar',
        _cyan,
      ),
      const _ChannelItem(
        Icons.analytics,
        'COMBAT ANALYTICS',
        'Performance dashboards, fight stats, training metrics, wellness tracking',
        _amber,
      ),
      const _ChannelItem(
        Icons.workspace_premium,
        'EVENT MANAGEMENT',
        'Create events, manage rosters, sell tickets, broadcast signals',
        _red,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 60 : 16, vertical: 40),
      color: _bg,
      child: Column(
        children: [
          _sectionBadge('MULTI-CHANNEL', _cyan),
          const SizedBox(height: 8),
          Text(
            'Getting You Exposure Across\nEvery Channel That Matters',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isWide ? 28 : 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'One platform. Maximum reach. Your content goes everywhere.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 30),
          LayoutBuilder(
            builder: (ctx, constraints) {
              final cols = constraints.maxWidth > 900
                  ? 4
                  : constraints.maxWidth > 600
                  ? 3
                  : 2;
              final cardWidth = (constraints.maxWidth - (cols - 1) * 12) / cols;
              // Group into rows for equal-height cards
              final rows = <List<_ChannelItem>>[];
              for (var i = 0; i < channels.length; i += cols) {
                rows.add(
                  channels.sublist(
                    i,
                    i + cols > channels.length ? channels.length : i + cols,
                  ),
                );
              }
              return Column(
                children: rows.asMap().entries.map((entry) {
                  final row = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: entry.key < rows.length - 1 ? 12 : 0,
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: row.asMap().entries.map((cardEntry) {
                          return Padding(
                            padding: EdgeInsets.only(
                              right: cardEntry.key < row.length - 1 ? 12 : 0,
                            ),
                            child: SizedBox(
                              width: cardWidth,
                              child: _channelCard(cardEntry.value),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _channelCard(_ChannelItem ch) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ch.color.withValues(alpha: 0.15), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ch.icon, color: ch.color, size: 26),
          const SizedBox(height: 10),
          Text(
            ch.title,
            style: TextStyle(
              color: ch.color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              ch.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. PLATFORM PILLARS — What You Get
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPlatformPillars(bool isWide) {
    final pillars = [
      const _PillarItem(
        'FIGHT INTELLIGENCE',
        'AI-powered fight predictions, style clash analysis, combat analytics, '
            'performance dashboards, and Samurai Shido — your personal AI coach.',
        Icons.psychology,
        _cyan,
        ['/ai-brain', '/fightlab', '/combat-analytics', '/fight-predictor'],
      ),
      const _PillarItem(
        'TRAINING & WELLNESS',
        'Full training load tracking, fight camp planning, recovery hub, '
            'mental health tools, body monitoring, sleep/HRV/stress metrics.',
        Icons.fitness_center,
        _green,
        ['/fight-camp-tools', '/recovery', '/wellness', '/health-dashboard'],
      ),
      const _PillarItem(
        'EVENTS & MEDIA',
        'Create & manage fight events, PPV broadcasting, ticket sales, '
            'fight cards, promo video editing, live streaming, and drone coverage.',
        Icons.stadium,
        _red,
        ['/events', '/ppv', '/promo-video-editor', '/fight-card-builder'],
      ),
      const _PillarItem(
        'SOCIAL & COMMUNITY',
        'Social feed, FightWire news, messaging, creative hub, fan zones, '
            'user search, follow system, and community-driven content.',
        Icons.people,
        _magenta,
        ['/feed', '/fightwire', '/messaging', '/creative-hub'],
      ),
      const _PillarItem(
        'BUSINESS & GROWTH',
        'Marketing HQ, SEO engine, sponsor dashboards, promoter tools, '
            'ad spotlight, partnership portal, work & job opportunities.',
        Icons.trending_up,
        _amber,
        ['/marketing-hq', '/work', '/partnerships', '/promoter'],
      ),
      const _PillarItem(
        'DISCOVERY & MAPS',
        'Global fight map, gym finder, event discovery, mentor map, '
            'resource hub, and social connectors to find your tribe worldwide.',
        Icons.explore,
        _gold,
        ['/earth-map', '/discovery', '/mentor-map', '/fight-events'],
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 60 : 16, vertical: 40),
      color: _bgSec,
      child: Column(
        children: [
          _sectionBadge('PLATFORM', _magenta),
          const SizedBox(height: 8),
          Text(
            'Everything You Need.\nOne Platform.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isWide ? 28 : 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '120+ features across 6 core pillars',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 30),
          LayoutBuilder(
            builder: (ctx, constraints) {
              final cols = constraints.maxWidth > 900
                  ? 3
                  : constraints.maxWidth > 600
                  ? 2
                  : 1;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: pillars
                    .map(
                      (p) => SizedBox(
                        width: (constraints.maxWidth - (cols - 1) * 14) / cols,
                        child: _pillarCard(p),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _pillarCard(_PillarItem p) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: p.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(p.icon, color: p.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  p.title,
                  style: TextStyle(
                    color: p.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            p.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: p.routes
                .map(
                  (r) => GestureDetector(
                    onTap: () => context.push(r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: p.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: p.color.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        r
                            .replaceAll('/', '')
                            .replaceAll('-', ' ')
                            .toUpperCase(),
                        style: TextStyle(
                          color: p.color.withValues(alpha: 0.8),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. PROOF IN OUR PRODUCTIONS — Stats & Results
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProofSection(bool isWide) {
    final stats = [
      const _StatItem('847+', 'LIVE EVENTS', Icons.stadium, _red),
      const _StatItem('24.3K', 'FIGHTERS', Icons.sports_mma, _cyan),
      const _StatItem('1.2K', 'PROMOTERS', Icons.campaign, _magenta),
      const _StatItem('3.8K', 'GYMS', Icons.fitness_center, _green),
      const _StatItem('156', 'FIGHT CARDS', Icons.grid_view, _amber),
      const _StatItem('61%', 'KO RATE', Icons.flash_on, _red),
      const _StatItem('120+', 'FEATURES', Icons.apps, _cyan),
      const _StatItem('12', 'CHANNELS', Icons.hub, _gold),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 60 : 16, vertical: 50),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A1628), Color(0xFF0F1E35), Color(0xFF0A1628)],
        ),
      ),
      child: Column(
        children: [
          _sectionBadge('PROOF', _gold),
          const SizedBox(height: 8),
          Text(
            'The Proof Is In Our Productions',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isWide ? 28 : 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Real numbers. Real community. Real results.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 30),
          LayoutBuilder(
            builder: (ctx, constraints) {
              final cols = constraints.maxWidth > 900
                  ? 4
                  : constraints.maxWidth > 600
                  ? 4
                  : 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: stats
                    .map(
                      (s) => SizedBox(
                        width: (constraints.maxWidth - (cols - 1) * 12) / cols,
                        child: _statCard(s),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 30),
          Container(
            constraints: const BoxConstraints(maxWidth: 700),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cyan.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                const Icon(Icons.format_quote, color: _cyan, size: 28),
                const SizedBox(height: 12),
                Text(
                  '"We don\'t ask promoters to choose us over someone else. '
                  'We ask them to let us be the engine behind what they already do. '
                  'Every show deserves world-class production tools — '
                  'DFC makes that accessible to everyone."',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '— DATA FIGHT CENTRAL',
                  style: TextStyle(
                    color: _cyan.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(_StatItem s) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: s.color.withValues(alpha: 0.2), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: s.color.withValues(alpha: _pulse.value * 0.06),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(s.icon, color: s.color, size: 22),
            const SizedBox(height: 8),
            Text(
              s.value,
              style: TextStyle(
                color: s.color,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              s.label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. WHO WE SERVE — Role Cards
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildWhoWeServe(bool isWide) {
    final roles = [
      const _RoleItem(
        'FIGHTER',
        'Performance dashboards, AI coaching, fight predictions, training '
            'analytics, wellness tracking, sponsorship access, fight camp tools.',
        Icons.sports_mma,
        _cyan,
        'From \$9.99/mo',
        '/fighter-pro-pricing',
      ),
      const _RoleItem(
        'PROMOTER',
        'Event creation, roster management, matchmaking AI, ticket management, '
            'revenue analytics, marketing tools, signal broadcasting.',
        Icons.campaign,
        _magenta,
        'From \$29.99/mo',
        '/promoter-pricing',
      ),
      const _RoleItem(
        'FAN & SUPPORTER',
        'Ad-free experience, behind-the-scenes access, early event presale, '
            'support your favourite fighters, exclusive content, supporter badge.',
        Icons.favorite,
        _red,
        'From \$4.99/mo',
        '/subscription',
      ),
      const _RoleItem(
        'COACH & MENTOR',
        'Training program management, fighter development analytics, gym '
            'administration, athlete wellness monitoring, booking & scheduling.',
        Icons.school,
        _amber,
        'From \$14.99/mo',
        '/subscription',
      ),
      const _RoleItem(
        'GYM & FACILITY',
        'Gym listing & discovery, events hosting, fighter recruitment, '
            'membership management, facility analytics, startup consulting.',
        Icons.fitness_center,
        Color(0xFF9D00FF),
        'From \$29.99/mo',
        '/promoter-pricing',
      ),
      const _RoleItem(
        'SPONSOR & BRAND',
        'Fighter sponsorship, event sponsorship, platform advertising, '
            'brand visibility, audience analytics, ROI tracking.',
        Icons.diamond,
        _gold,
        'From \$199/mo',
        '/sponsor-dashboard',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 60 : 16, vertical: 40),
      color: _bgSec,
      child: Column(
        children: [
          _sectionBadge('FOR EVERYONE', _red),
          const SizedBox(height: 8),
          Text(
            'Built For Every Role\nIn Combat Sports',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isWide ? 28 : 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We love everyone. Every role has a home on DFC.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 30),
          LayoutBuilder(
            builder: (ctx, constraints) {
              final cols = constraints.maxWidth > 900
                  ? 3
                  : constraints.maxWidth > 600
                  ? 2
                  : 1;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: roles
                    .map(
                      (r) => SizedBox(
                        width: (constraints.maxWidth - (cols - 1) * 14) / cols,
                        child: _roleCard(r),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _roleCard(_RoleItem r) {
    return GestureDetector(
      onTap: () => context.push(r.pricingRoute),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: r.color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: r.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(r.icon, color: r.color, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.title,
                        style: TextStyle(
                          color: r.color,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: r.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          r.price,
                          style: TextStyle(
                            color: r.color,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: r.color.withValues(alpha: 0.4),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              r.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. PRICING COMPARISON — Bang For Buck
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPricingSection(bool isWide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 60 : 16, vertical: 40),
      color: _bg,
      child: Column(
        children: [
          _sectionBadge('BANG FOR BUCK', _green),
          const SizedBox(height: 8),
          Text(
            'More Value Per Dollar Than\nAnything In Combat Sports',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isWide ? 28 : 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 30),

          // Comparison cards
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _pricingTierCard(
                    'FREE ACCESS',
                    'FREE',
                    'forever',
                    Colors.grey,
                    [
                      'Browse events & news',
                      'View fighter profiles',
                      'Community feed access',
                      'FightWire news feed',
                      'Basic fight history (last 5)',
                      'Global fight map browsing',
                    ],
                    false,
                    '/access-pass',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _pricingTierCard(
                    'FIGHTER PRO',
                    '\$9.99',
                    '/month',
                    _cyan,
                    [
                      'Everything in Free +',
                      'Full performance dashboard',
                      'AI fight analysis & predictions',
                      'Smart device integration',
                      'Training load analytics',
                      'Mental health & recovery tools',
                      'Fight camp planning',
                      'Work & sponsorship access',
                      'Priority matchmaking',
                      'Ad-free experience',
                      'Marketplace posting',
                      'Trainer discovery & booking',
                    ],
                    true,
                    '/subscription',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _pricingTierCard(
                    'PROMOTER CMD',
                    '\$29.99',
                    '/month',
                    _magenta,
                    [
                      'Everything in Fighter Pro +',
                      'Event creation & management',
                      'Fighter database & recruiting',
                      'Advanced matchmaking engine',
                      'Ticket & pass management',
                      'Revenue analytics',
                      'Marketing & SEO tools',
                      'Signal broadcasting',
                      'Gym startup tools',
                      'Custom branding options',
                      'API access',
                      'Dedicated support',
                    ],
                    false,
                    '/subscription',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _pricingTierCard(
                    'SUPPORTER',
                    '\$4.99',
                    '/month',
                    _gold,
                    [
                      'Everything in Free +',
                      'Ad-free experience',
                      'Behind-the-scenes content',
                      'Early event access & presale',
                      'Support favourite fighters',
                      'Supporter badge',
                      'Exclusive community access',
                    ],
                    false,
                    '/subscription',
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                _pricingTierCard(
                  'FIGHTER PRO',
                  '\$9.99',
                  '/month',
                  _cyan,
                  [
                    'Everything in Free +',
                    'Full performance dashboard',
                    'AI fight analysis & predictions',
                    'Smart device integration',
                    'Training load analytics',
                    'Mental health & recovery tools',
                    'Fight camp planning',
                    'Work & sponsorship access',
                    'Priority matchmaking',
                    'Ad-free experience',
                    'Marketplace posting',
                    'Trainer discovery & booking',
                  ],
                  true,
                  '/subscription',
                ),
                const SizedBox(height: 14),
                _pricingTierCard(
                  'PROMOTER CMD',
                  '\$29.99',
                  '/month',
                  _magenta,
                  [
                    'Everything in Fighter Pro +',
                    'Event creation & management',
                    'Fighter database & recruiting',
                    'Advanced matchmaking engine',
                    'Ticket & pass management',
                    'Revenue analytics',
                    'Marketing & SEO tools',
                    'Signal broadcasting',
                    'Gym startup tools',
                    'Dedicated support',
                  ],
                  false,
                  '/subscription',
                ),
                const SizedBox(height: 14),
                _pricingTierCard(
                  'SUPPORTER',
                  '\$4.99',
                  '/month',
                  _gold,
                  [
                    'Everything in Free +',
                    'Ad-free experience',
                    'Behind-the-scenes content',
                    'Early event access & presale',
                    'Support favourite fighters',
                    'Supporter badge',
                  ],
                  false,
                  '/subscription',
                ),
                const SizedBox(height: 14),
                _pricingTierCard(
                  'FREE ACCESS',
                  'FREE',
                  'forever',
                  Colors.grey,
                  [
                    'Browse events & news',
                    'View fighter profiles',
                    'Community feed access',
                    'FightWire news feed',
                    'Basic fight history (last 5)',
                  ],
                  false,
                  '/access-pass',
                ),
              ],
            ),

          const SizedBox(height: 30),

          // ROI Comparison
          Container(
            constraints: const BoxConstraints(maxWidth: 700),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _green.withValues(alpha: 0.08),
                  _cyan.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _green.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Text(
                  '💰 REAL VALUE COMPARISON',
                  style: TextStyle(
                    color: _green,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                _comparisonRow(
                  'Average gym membership',
                  '\$50–\$150/mo',
                  Colors.red.shade300,
                ),
                _comparisonRow(
                  'Personal trainer',
                  '\$200–\$500/mo',
                  Colors.red.shade300,
                ),
                _comparisonRow(
                  'Fight analyst / corner team',
                  '\$100–\$300/session',
                  Colors.red.shade300,
                ),
                _comparisonRow(
                  'Event management software',
                  '\$99–\$499/mo',
                  Colors.red.shade300,
                ),
                const Divider(color: Colors.white24, height: 24),
                _comparisonRow('DFC Fighter Pro', '\$9.99/mo', _green),
                _comparisonRow('DFC Promoter Command', '\$29.99/mo', _green),
                _comparisonRow('DFC Daily cost', '\$0.33/day', _cyan),
                const SizedBox(height: 12),
                Text(
                  'AI coaching + analytics + events + social + marketplace\n'
                  'ALL included. No hidden fees. Cancel anytime.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pricingTierCard(
    String name,
    String price,
    String period,
    Color color,
    List<String> features,
    bool popular,
    String route,
  ) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: popular ? color : color.withValues(alpha: 0.2),
            width: popular ? 2 : 1,
          ),
          boxShadow: popular
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (popular)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, _green]),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'MOST POPULAR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            Text(
              name,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      period,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      f.startsWith('Everything')
                          ? Icons.arrow_upward
                          : Icons.check_circle,
                      color: f.startsWith('Everything')
                          ? _amber
                          : color.withValues(alpha: 0.7),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: popular
                      ? LinearGradient(colors: [color, _green])
                      : null,
                  color: popular ? null : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: popular
                      ? null
                      : Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  price == 'FREE'
                      ? 'GET STARTED FREE'
                      : 'START 7-DAY FREE TRIAL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: popular ? Colors.black : color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _comparisonRow(String label, String price, Color priceColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          Text(
            price,
            style: TextStyle(
              color: priceColor,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 8. THE ADRENALINE PATH — Philosophy
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAdrenalinePath(bool isWide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 20, vertical: 50),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_bgSec, Color(0xFF0A1230), _bgSec],
        ),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, _) => Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _red.withValues(alpha: _pulse.value),
                    _amber.withValues(alpha: _pulse.value),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _red.withValues(alpha: _pulse.value * 0.3),
                    blurRadius: 25,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'THE ADRENALINE PATH',
            style: TextStyle(
              fontSize: isWide ? 14 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
              color: _amber,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Navigate Life Through\nAdrenaline Sports',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isWide ? 30 : 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Text(
              'We use adrenaline sports to navigate life\'s toughest journeys. '
              'Combat sports aren\'t just about fighting — they\'re about '
              'discipline, resilience, community, and discovering your full '
              'potential in a broken world.\n\n'
              'DFC exists to channel that adrenaline into something greater. '
              'Better training. Better mental health. Better connections. '
              'A better life. Whether you\'re a fighter in the cage, a promoter '
              'building shows, or a fan finding your tribe — this platform '
              'is your path to living at full potential.\n\n'
              'We embrace ALL combat sports. Boxing. MMA. Muay Thai. BJJ. '
              'Wrestling. Kickboxing. Bare knuckle. Every discipline. '
              'Every level. From your first amateur bout to world championship '
              'nights. DFC is the engine that powers it all.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: isWide ? 15 : 13,
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: 30),
          // Discipline chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children:
                [
                      'BOXING',
                      'MMA',
                      'MUAY THAI',
                      'BJJ',
                      'WRESTLING',
                      'KICKBOXING',
                      'BARE KNUCKLE',
                      'KARATE',
                      'JUDO',
                      'SAMBO',
                      'SANDA',
                      'LETHWEI',
                    ]
                    .map(
                      (d) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _red.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          d,
                          style: TextStyle(
                            color: _red.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 9. FINAL CTA
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFinalCTA(bool isWide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 60 : 20, vertical: 50),
      color: _bg,
      child: Column(
        children: [
          Text(
            'READY TO JOIN THE\nPROMOTIONAL REVOLUTION?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isWide ? 30 : 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Free to start. No credit card required. Cancel anytime.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => context.push('/register'),
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, _) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_cyan, _green]),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: _cyan.withValues(alpha: _pulse.value * 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.rocket_launch,
                          color: Colors.black,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'JOIN DFC FREE',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => context.push('/subscription'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _cyan, width: 1.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.diamond, color: _cyan, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'VIEW PLANS',
                        style: TextStyle(
                          color: _cyan,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            'DATAFIGHTCENTRAL.COM',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '© 2026 Data Fight Central. All rights reserved.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED COMPONENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _sectionBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════════════════════════

class _ManifestoItem {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _ManifestoItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

class _ChannelItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  const _ChannelItem(this.icon, this.title, this.description, this.color);
}

class _PillarItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> routes;
  const _PillarItem(
    this.title,
    this.description,
    this.icon,
    this.color,
    this.routes,
  );
}

class _StatItem {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatItem(this.value, this.label, this.icon, this.color);
}

class _RoleItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String price;
  final String pricingRoute;
  const _RoleItem(
    this.title,
    this.description,
    this.icon,
    this.color,
    this.price,
    this.pricingRoute,
  );
}
