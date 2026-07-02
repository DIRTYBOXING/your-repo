import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/services/social_platform_config_service.dart';
import '../../../core/theme/glass_panel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DFC SOCIAL CONNECTORS
// Strategy: We don't spam — we produce genuine high-IQ content that fits each
// platform's native culture, powered by AI that understands context, timing
// and human emotion. Honest about what DFC is. Powerful about why it matters.
// ─────────────────────────────────────────────────────────────────────────────
class SocialConnectorsScreen extends StatefulWidget {
  const SocialConnectorsScreen({super.key});
  @override
  State<SocialConnectorsScreen> createState() => _SocialConnectorsScreenState();
}

class _SocialConnectorsScreenState extends State<SocialConnectorsScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _pulseCtrl;
  late TabController _tabCtrl;
  int _promoIndex = 0;

  static const _cyan = Color(0xFF00E5FF);
  static const _green = Color(0xFF00E676);
  static const _purple = Color(0xFFD500F9);
  static const _amber = Color(0xFFFFAB00);
  static const _red = Color(0xFFFF1744);
  static const _blue = Color(0xFF2979FF);
  static const _pink = Color(0xFFFF4081);
  static const _bg = Color(0xFF030810);
  static const _card = Color(0xFF080F1E);

  // ── Platform definitions (from centralized config service) ──────────────
  final _platforms = SocialPlatformConfigService.platforms
      .map(
        (p) => _Platform(
          p.name,
          p.icon,
          p.color,
          p.tagline,
          p.strategy,
          p.plays,
          p.handle,
        ),
      )
      .toList();

  // ── AI Promo drops (from centralized config service) ────────────────────
  final _promos = SocialPlatformConfigService.promoCampaigns
      .map((p) => _Promo(p.title, p.body, p.cta, p.color))
      .toList();

  // ── AI Toggles (from centralized config service) ──────────────────────────
  final Map<String, bool> _aiToggles = Map<String, bool>.from(
    SocialPlatformConfigService.defaultAiToggles,
  );

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _tabCtrl = TabController(length: 5, vsync: this);
    // auto-advance carousel
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return false;
      setState(() => _promoIndex = (_promoIndex + 1) % _promos.length);
      return true;
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _pulseCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (_, _) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(math.sin(_bgCtrl.value * math.pi) * 0.4, -0.3),
              radius: 1.8,
              colors: const [
                Color(0xFF001230),
                Color(0xFF030810),
                Color(0xFF0A0018),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _appBar(),
                _promoCarousel(),
                _tabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _fightOrgsTab(),
                      _platformsTab(),
                      _aiEngineTab(),
                      _infrastructureTab(),
                      _honestyTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── APP BAR ────────────────────────────────────────────────────────────────
  Widget _appBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go('/home'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white54,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SOCIAL COMMAND',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'DFC × Meta × TikTok × X × YouTube',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go('/metaverse-hub'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A00E0), Color(0xFFD500F9)],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: _purple.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Text(
                'METAVERSE ▶',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── PROMO CAROUSEL ─────────────────────────────────────────────────────────
  Widget _promoCarousel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, _) {
          final p = _promos[_promoIndex];
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Container(
              key: ValueKey(_promoIndex),
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    p.color.withValues(alpha: 0.18),
                    p.color.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: p.color.withValues(
                    alpha: 0.45 + 0.2 * _pulseCtrl.value,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          style: TextStyle(
                            color: p.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.subtitle,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _handlePromoCta(p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: p.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: p.color.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        p.cta,
                        style: TextStyle(
                          color: p.color,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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

  void _handlePromoCta(_Promo promo) {
    final title = promo.title.toLowerCase();
    if (title.contains('joseph') || title.contains('legends')) {
      context.go('/social-connectors');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joseph + Legends push mode is live.')),
      );
      return;
    }
    if (title.contains('fight night') || title.contains('tickets')) {
      context.go('/ppv/store');
      return;
    }
    if (title.contains('ai') || title.contains('predictor')) {
      context.go('/ai-brain');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${promo.cta} — queued in Social Command')),
    );
  }

  // ── TAB BAR ────────────────────────────────────────────────────────────────
  Widget _tabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: TabBar(
          controller: _tabCtrl,
          labelStyle: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 8),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          indicator: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFFD500F9)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'FIGHT ORGS'),
            Tab(text: 'PLATFORMS'),
            Tab(text: 'AI ENGINE'),
            Tab(text: 'INFRA'),
            Tab(text: 'HONESTY'),
          ],
        ),
      ),
    );
  }

  // ── TAB 0: FIGHT ORGS ─────────────────────────────────────────────────────
  Widget _fightOrgsTab() {
    // Each org: emoji, name, tagline, accentColor, social handles (platform→handle)
    // Reads from centralized SocialPlatformConfigService
    final orgs = SocialPlatformConfigService.fightOrgs
        .map(
          (o) => _FightOrg(
            o.emoji,
            o.name,
            o.fullName,
            o.strategy,
            o.color,
            o.socials,
            o.partnerRole,
          ),
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_red.withValues(alpha: 0.12), _card],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _red.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🥊', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DFC × FIGHT WORLD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Cross-promoting with every major org, worldwide',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'DFC is not a competitor to UFC, ONE, Bellator or any major org. We are the connective infrastructure of the global fight world — giving every fighter at every level the same digital tools, audience access and sponsorship opportunities that only champions used to get.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 10),
              // Quick stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statCol('10+', 'Org Partners', _cyan),
                  _statCol('50+', 'Countries', _green),
                  _statCol('1B+', 'Combined Reach', _amber),
                  _statCol('∞', 'Fighter Stories', _purple),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildGetMoreEngine(),
        const SizedBox(height: 14),
        // Org strategy subtitle
        const Text(
          'PARTNER ORGANISATIONS',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 9,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap any org to see their social handles, DFC partnership strategy and how we cross-promote their fighters and events.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 9,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        ...orgs.map(_orgCard),
      ],
    );
  }

  Widget _buildGetMoreEngine() {
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      gradient: LinearGradient(
        colors: [_cyan.withValues(alpha: 0.12), _card],
      ),
      borderRadius: BorderRadius.circular(14),
      borderColor: _cyan.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GET MORE - GROWTH ENGINE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Use this flow daily: post hero clip -> push Legends teaser -> route to DFC PPV offers.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _actionChip(
                  label: 'Push Legends',
                  color: _amber,
                  onTap: () => context.go('/ppv/store'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionChip(
                  label: 'Find Talent',
                  color: _green,
                  onTap: () => context.go('/explore'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionChip(
                  label: 'Build Posts',
                  color: _purple,
                  onTap: () => context.go('/social-connectors'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildUsWatchPartyScheduler(),
          const SizedBox(height: 10),
          _buildCampaignMetricChips(),
          const SizedBox(height: 12),
          _copyReadyPost(
            title: 'Ultimate Legends Push Copy',
            copy:
                'Legends coming up. Ultimate Legends Promotions are bringing elite action Apr 24. Follow now and lock in your PPV access early.',
          ),
          const SizedBox(height: 8),
          _copyReadyPost(
            title: 'Share Legends Copy',
            copy:
                'Share Legends is where real fighter stories drop first. Watch the build-up, support the talent, then catch the full card live on DFC.',
          ),
          const SizedBox(height: 8),
          _copyReadyPost(
            title: 'Bunty Boxer Copy',
            copy:
                'Bunty Boxer spotlight: discipline, heart, and elite work. Tap in now, share the movement, and follow upcoming event drops.',
          ),
          const SizedBox(height: 8),
          _copyReadyPost(
            title: 'Down Under Domino Effect Copy',
            copy:
                'America, tune into Australia fight night. When U.S. fans watch Down Under cards, fighters get global reach, sponsors move in, and the whole scene grows faster.',
          ),
          const SizedBox(height: 8),
          _copyReadyPost(
            title: 'US Prime-Time Relay Copy',
            copy:
                'U.S. watch parties for Aussie fight cards start now. Watch, share highlights, and back the next generation rising from Australia to the world.',
          ),
          const SizedBox(height: 8),
          _copyReadyPost(
            title: 'Ultimate Legends Tribute Copy',
            copy:
                'Respect to TEAM ULTIMATE, John Scida and the whole promotion crew. They gave people a real shot and passed on the promotion game with heart. This movement is built on that leadership.',
          ),
        ],
      ),
    );
  }

  Widget _buildUsWatchPartyScheduler() {
    final zones = [
      ('PT', '6:00 PM'),
      ('MT', '7:00 PM'),
      ('CT', '8:00 PM'),
      ('ET', '9:00 PM'),
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'US WATCH-PARTY RELAY',
            style: TextStyle(
              color: _green,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: zones
                .map(
                  (z) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _green.withValues(alpha: 0.28)),
                    ),
                    child: Text(
                      '${z.$1}: ${z.$2}',
                      style: const TextStyle(
                        color: _green,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _launchUsaRelay,
              icon: const Icon(Icons.rocket_launch, size: 16),
              label: const Text('Launch USA Relay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _launchUsaRelay() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'USA relay launched: PT/MT/CT/ET watch-party sequence activated.',
        ),
      ),
    );
    context.go('/ppv/store');
  }

  Widget _buildCampaignMetricChips() {
    final chips = [
      ('US Views', '24K+'),
      ('Shares', '3.1K'),
      ('PPV CVR', '7.8%'),
      ('Sponsor Leads', '42'),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips
          .map(
            (c) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: _amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: _amber.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${c.$1}: ${c.$2}',
                style: const TextStyle(
                  color: _amber,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _actionChip({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _copyReadyPost({required String title, required String copy}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copy template ready.')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _cyan.withValues(alpha: 0.35)),
                  ),
                  child: const Text(
                    'USE',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            copy,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 9,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _orgCard(_FightOrg org) {
    return GestureDetector(
      onTap: () => _showOrgDetail(org),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [org.color.withValues(alpha: 0.1), _card],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: org.color.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            // Icon bubble
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: org.color.withValues(alpha: 0.15),
                border: Border.all(color: org.color.withValues(alpha: 0.35)),
              ),
              child: Center(
                child: Text(org.emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    org.name,
                    style: TextStyle(
                      color: org.color,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    org.fullName,
                    style: const TextStyle(color: Colors.white38, fontSize: 8),
                  ),
                  const SizedBox(height: 3),
                  // Social platform chips
                  Wrap(
                    spacing: 4,
                    children: org.socials.keys
                        .take(4)
                        .map(
                          (platform) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: org.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: org.color.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              platform,
                              style: TextStyle(
                                color: org.color.withValues(alpha: 0.8),
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: org.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: org.color.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    'PARTNER',
                    style: TextStyle(
                      color: org.color,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white24,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOrgDetail(_FightOrg org) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                org.color.withValues(alpha: 0.14),
                const Color(0xFF060D1A),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: org.color.withValues(alpha: 0.3)),
          ),
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(22),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(org.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          org.name,
                          style: TextStyle(
                            color: org.color,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          org.fullName,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white38),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: org.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: org.color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'DFC STRATEGY: ${org.partnerRole}',
                  style: TextStyle(
                    color: org.color,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                org.strategy,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'SOCIAL CHANNELS TO CROSS-PROMOTE:',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              ...org.socials.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: org.color.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            e.key,
                            style: TextStyle(
                              color: org.color,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          e.value,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: org.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'FOLLOW',
                            style: TextStyle(
                              color: org.color,
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: org.color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: org.color.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HOW DFC CROSS-PROMOTES ${org.name}:',
                      style: TextStyle(
                        color: org.color,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...[
                      'Share ${org.name} event results to DFC community feed instantly',
                      'Profile ${org.name} fighters on DFC — stats, records, fight history',
                      'Alert DFC fans when their tracked fighters compete in ${org.name}',
                      'AI fight predictions for ${org.name} events published on DFC',
                      'Sponsor connect: link DFC sponsors to ${org.name} fighter partnerships',
                    ].map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 5, right: 8),
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: org.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 10,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        org.color.withValues(alpha: 0.3),
                        org.color.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: org.color.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'ACTIVATE ${org.name} PARTNERSHIP →',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── TAB 1: PLATFORMS ──────────────────────────────────────────────────────
  Widget _platformsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _platforms.length,
      itemBuilder: (_, i) => _platformCard(_platforms[i]),
    );
  }

  Widget _platformCard(_Platform p) {
    return GestureDetector(
      onTap: () => _showPlatformDetail(p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [p.color.withValues(alpha: 0.1), _card],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: p.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: p.color.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: Text(
                  p.icon,
                  style: TextStyle(fontSize: p.icon.length == 1 ? 18 : 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: TextStyle(
                      color: p.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    p.tagline,
                    style: const TextStyle(color: Colors.white38, fontSize: 9),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: p.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: p.color.withValues(alpha: 0.35)),
              ),
              child: const Text(
                'VIEW ▶',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlatformDetail(_Platform p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                p.color.withValues(alpha: 0.12),
                const Color(0xFF060D1A),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: p.color.withValues(alpha: 0.3)),
          ),
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(p.icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: TextStyle(
                          color: p.color,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        p.tagline,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                p.strategy,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'DFC CONTENT PILLARS ON THIS PLATFORM:',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              ...p.pillars.map(
                (pillar) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: p.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        pillar,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Colors.white38, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      p.handle,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        p.color.withValues(alpha: 0.3),
                        p.color.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.color.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'CONNECT ${p.name.toUpperCase()} →',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: p.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── TAB 2: AI ENGINE ──────────────────────────────────────────────────────
  Widget _aiEngineTab() {
    final capabilities = [
      const _AiCap(
        '🧠',
        'Platform-Native Tone Matching',
        'Writes like a human on each platform. TikTok captions ≠ LinkedIn posts ≠ X threads. AI studies what actually performs, then replicates — without mimicking.',
        _cyan,
      ),
      const _AiCap(
        '📊',
        'Performance Prediction Engine',
        "Before posting, the AI scores each piece of content on predicted engagement. Only publish what's expected to perform above platform average.",
        _green,
      ),
      const _AiCap(
        '⏰',
        'Optimal Timing Intelligence',
        'Analyses when your specific audience is online across all 8 platforms. Schedules content to hit each platform at its peak engagement window.',
        _amber,
      ),
      const _AiCap(
        '🎯',
        'Audience Segmentation AI',
        'Knows that the DFC fan on TikTok is 19 years old and wants raw training clips. The DFC fan on LinkedIn is 35 and wants fighter career stats.',
        _purple,
      ),
      const _AiCap(
        '🔥',
        'Viral Moment Detector',
        'Real-time scanner across DFC data — when a fighter posts a PB, or a fight result drops, the AI writes and queues the content in under 60 seconds.',
        _red,
      ),
      const _AiCap(
        '📝',
        'Long-Form Content Generator',
        "Produces fight previews, post-fight analysis, fighter profiles and sponsor reports. Always factual, always sourced from DFC's own verified data.",
        _blue,
      ),
      const _AiCap(
        '🚫',
        'Anti-Spam Protection',
        'Hard limits on posting frequency per platform. AI refuses to publish duplicate content across platforms. No carpet-bombing audiences.',
        _pink,
      ),
      const _AiCap(
        '🔗',
        'Cross-Platform Story Arcs',
        'A fight week has a beginning, middle and end. AI writes a cohesive story that evolves across all platforms simultaneously — each version native to that platform.',
        Color(0xFFFF6D00),
      ),
      const _AiCap(
        '⚔️',
        'SAMURAI - Trust & Brand Discipline',
        'Protects brand integrity, verifies campaign quality, and ensures every post supports healthy community values and long-term trust.',
        Color(0xFF00E5FF),
      ),
      const _AiCap(
        '🥷',
        'NINJA - Fast Opportunity Strikes',
        'Detects trending moments in India and launches rapid, culturally-tuned posts for fighters, gyms and promoters within minutes.',
        Color(0xFF00E676),
      ),
      const _AiCap(
        '🧛',
        'VAMPIRES - Revenue Energy Engine',
        'Finds high-conversion audience clusters and routes them into singles, main-event and full-card offers without spamming.',
        Color(0xFFFF1744),
      ),
      const _AiCap(
        '👻',
        'GHOST - Silent Retention Loops',
        'Runs low-friction reminders, watch-party nudges and comeback prompts so inactive fans re-engage before event day.',
        Color(0xFFD500F9),
      ),
      const _AiCap(
        '🐞',
        'BUG FETCH - System Recovery & Fixes',
        'Crawls campaign links, media paths and funnel steps to catch broken flows early and auto-surface fix actions for the ops team.',
        Color(0xFFFFAB00),
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader(
          'AI CONTENT INTELLIGENCE',
          'Blending in is not deception — it is understanding each platform\'s culture and speaking its language fluently.',
          _cyan,
        ),
        const SizedBox(height: 12),
        ...capabilities.map(
          (c) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [c.color.withValues(alpha: 0.08), _card],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.color.withValues(alpha: 0.22)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.title,
                        style: TextStyle(
                          color: c.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.desc,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _sectionHeader(
          'AI TOGGLES',
          'Configure exactly what the AI does on your behalf. Always opt-in. Always transparent.',
          Colors.white38,
        ),
        const SizedBox(height: 10),
        ..._aiToggles.entries.map(
          (e) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    e.key,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ),
                Switch(
                  value: e.value,
                  activeThumbColor: _cyan,
                  onChanged: (v) => setState(() => _aiToggles[e.key] = v),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── TAB 3: INFRASTRUCTURE ─────────────────────────────────────────────────
  Widget _infrastructureTab() {
    final layers = [
      const _InfraLayer(
        '🔥',
        'FIREBASE + GOOGLE CLOUD',
        'Tier',
        'Auth, Firestore, Functions, Storage, Analytics — all hosted on Google Cloud. Real-time sync across all platforms. 99.99% uptime. Scales to 10M users automatically.',
        [
          ' Firestore real-time DB',
          ' Cloud Functions (Node.js)',
          ' Firebase Auth + Google Sign-In',
          ' Cloud Storage (media)',
          ' Firebase Analytics',
        ],
        _cyan,
      ),
      const _InfraLayer(
        '🤖',
        'GENKIT AI LAYER',
        'Intelligence',
        'DFC\'s own AI pipeline powered by Genkit + Gemini. All content AI runs through this layer — captions, fight predictions, health plans, opponent analysis. Every output is logged, auditable.',
        [
          ' Gemini 2.0 Flash integration',
          ' Custom fight analysis models',
          ' Health + nutrition AI',
          ' Content generation pipeline',
          ' Explainable AI outputs',
        ],
        _green,
      ),
      const _InfraLayer(
        '📱',
        'FLUTTER CROSS-PLATFORM',
        'Frontend',
        'One codebase — iOS, Android, Web, desktop. Every screen live and working. Provider + GoRouter for state + navigation. Offline-capable with local data sync.',
        [
          ' Flutter 3.x (null safety)',
          ' Provider state management',
          ' GoRouter navigation',
          ' Offline-first architecture',
          ' Adaptive UI for all screens',
        ],
        _amber,
      ),
      const _InfraLayer(
        '🔐',
        'SECURITY ARCHITECTURE',
        'Protection',
        'Firestore security rules verify every read/write server-side. JWT auth on all API calls. GDPR/CCPA compliant. User data encrypted at rest. No third-party data sharing.',
        [
          ' Firestore security rules',
          ' JWT token validation',
          ' Data encryption at rest',
          ' GDPR + CCPA compliance',
          ' Consent logging',
        ],
        _purple,
      ),
      const _InfraLayer(
        '📡',
        'SOCIAL API LAYER',
        'Distribution',
        'Official OAuth integrations with each platform — no scraping, no bots, no ToS violations. DFC publishes through official developer APIs only. Everything above board.',
        [
          ' Facebook Graph API',
          ' Instagram Basic Display',
          ' TikTok Content Posting',
          ' YouTube Data API v3',
          ' X API v2 (Elevated)',
        ],
        _blue,
      ),
      const _InfraLayer(
        '💰',
        'PAYMENT + COMMERCE',
        'Revenue',
        'Stripe for payments, Apple/Google Pay, ticket sales, sponsorship invoicing. Transparent fee structure. Fighters get paid within 48h of event. All financials auditable.',
        [
          ' Stripe payment processing',
          ' Apple + Google Pay',
          ' Ticket sales engine',
          ' Sponsorship billing',
          ' Fighter payout automation',
        ],
        _pink,
      ),
      const _InfraLayer(
        '🇮🇳',
        'INDIA HATCH LAB',
        'Growth Program',
        'A local-first activation layer to hatch new creators, fighters, promoters and gyms into a healthy digital economy using verified social funnels and AI copilots.',
        [
          ' Regional creator onboarding tracks',
          ' City-by-city fight community pods',
          ' Singles + main-event local pricing playbooks',
          ' Sponsor-to-gym micro-commerce bridges',
          ' AI squad workflows (Samurai/Ninja/Vampires/Ghost/Bug Fetch)',
        ],
        Color(0xFF00E676),
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader(
          'TECHNICAL INFRASTRUCTURE',
          'Built to scale. Built to last. Every component chosen for reliability and honest performance — no vaporware.',
          _blue,
        ),
        const SizedBox(height: 12),
        ...layers.map(
          (l) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [l.color.withValues(alpha: 0.1), _card],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: l.color.withValues(alpha: 0.25)),
            ),
            child: Theme(
              data: ThemeData(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                leading: Text(l.icon, style: const TextStyle(fontSize: 22)),
                title: Text(
                  l.title,
                  style: TextStyle(
                    color: l.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: Text(
                  l.tier,
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.desc,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: l.items
                              .map(
                                (item) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: l.color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: l.color.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      color: l.color.withValues(alpha: 0.8),
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_cyan.withValues(alpha: 0.08), _card],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _cyan.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statCol('99.99%', 'Uptime SLA', _green),
                  _statCol('<200ms', 'Global Latency', _cyan),
                  _statCol('10M+', 'User Capacity', _amber),
                  _statCol('256-bit', 'Encryption', _purple),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── TAB 4: HONESTY ────────────────────────────────────────────────────────
  Widget _honestyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader(
          'DFC TRANSPARENCY PLEDGE',
          'We will never deceive, manipulate or exploit. This is the non-negotiable foundation of everything DFC builds.',
          _green,
        ),
        const SizedBox(height: 12),
        _honestyCard(
          '📊',
          'We tell you exactly how our AI works',
          'Every AI action on your behalf is logged in your activity feed. You can review, undo and understand every decision.',
          _green,
        ),
        _honestyCard(
          '💰',
          'Fees are clear before you agree to anything',
          'No hidden charges. No feature bait-and-switch. The price you see is the price you pay. DFC makes money when fighters win.',
          _amber,
        ),
        _honestyCard(
          '🚫',
          'We will never buy fake followers or engagement',
          "DFC's social growth is organic. We build real audiences through real content. Fake metrics damage everyone in the long run.",
          _red,
        ),
        _honestyCard(
          '🔐',
          'Your data belongs to you',
          'You can export your entire DFC data profile at any time. You can delete your account completely. No dark patterns. No retention traps.',
          _purple,
        ),
        _honestyCard(
          '🤖',
          'AI outputs are labelled',
          'When the AI writes a caption or generates a fight analysis, it is marked as AI-assisted. We do not pretend AI is a human.',
          _cyan,
        ),
        _honestyCard(
          '⚖️',
          'We do not take sides in fights — we report facts',
          'Fight results, records, stats — all sourced from verified officials. No inflated records, no suppressed losses.',
          _blue,
        ),
        _honestyCard(
          '🌍',
          'Repower Humanity donations go where we say',
          'Every charitable donation processed through DFC is tracked on-chain and reported quarterly. No diversion, no vague "admin costs".',
          const Color(0xFFFF6D00),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 2,
              colors: [_green.withValues(alpha: 0.12), _card],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _green.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Text(
                'OUR PROMISE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '"DFC is built by people who love fighting and hate broken systems. We built this because fight sports deserves better — better pay for fighters, fairer promotions, honest media, real community. If we ever break this promise, call us out. We mean it."',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                  height: 1.65,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '— The DFC Team',
                style: TextStyle(
                  color: _green,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────
  Widget _sectionHeader(String title, String sub, Color col) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: col,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sub,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _honestyCard(String icon, String title, String body, Color col) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [col.withValues(alpha: 0.08), _card]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: col,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
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

  Widget _statCol(String val, String lbl, Color col) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            color: col,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(lbl, style: const TextStyle(color: Colors.white38, fontSize: 8)),
      ],
    );
  }
}

// ── DATA CLASSES ──────────────────────────────────────────────────────────────
class _Platform {
  final String name, icon, tagline, strategy, handle;
  final List<String> pillars;
  final Color color;
  const _Platform(
    this.name,
    this.icon,
    this.color,
    this.tagline,
    this.strategy,
    this.pillars,
    this.handle,
  );
}

class _Promo {
  final String title, subtitle, cta;
  final Color color;
  const _Promo(this.title, this.subtitle, this.cta, this.color);
}

class _AiCap {
  final String icon, title, desc;
  final Color color;
  const _AiCap(this.icon, this.title, this.desc, this.color);
}

class _InfraLayer {
  final String icon, title, tier, desc;
  final List<String> items;
  final Color color;
  const _InfraLayer(
    this.icon,
    this.title,
    this.tier,
    this.desc,
    this.items,
    this.color,
  );
}

class _FightOrg {
  final String emoji, name, fullName, strategy, partnerRole;
  final Map<String, String> socials;
  final Color color;
  const _FightOrg(
    this.emoji,
    this.name,
    this.fullName,
    this.strategy,
    this.color,
    this.socials,
    this.partnerRole,
  );
}
