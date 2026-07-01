import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../feed/screens/feed_screen.dart';
import '../../action/screens/action_zone_screen.dart';
import '../widgets/social_media_widget.dart';
import '../../../shared/services/social_platform_config_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ADRENALINE GATEWAY — The DFC Social Media App Experience
/// ═══════════════════════════════════════════════════════════════════════════
/// Fighters connect with fans. Fans connect with fighters. Everyone creates
/// a better, healthier ecosystem. No keyboard warriors. No degrading athletes.
/// Adrenaline is the gateway to good health and wellbeing.
/// ═══════════════════════════════════════════════════════════════════════════
class AdrenalineGatewayScreen extends StatelessWidget {
  const AdrenalineGatewayScreen({super.key});

  static const _bg = Color(0xFF030810);
  static const _card = Color(0xFF0A1228);
  static const _cyan = Color(0xFF00E5FF);
  static const _green = Color(0xFF00E676);
  static const _purple = Color(0xFFD500F9);
  static const _amber = Color(0xFFFFAB00);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ───────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF0A0A23),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'ADRENALINE GATEWAY',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0D47A1),
                      Color(0xFF1A0033),
                      Color(0xFF000000),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 40),
                      const Icon(Icons.bolt, color: _cyan, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'FIGHTERS + FANS + HEALTH',
                        style: TextStyle(
                          color: _cyan.withAlpha(200),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Ecosystem Mission Banner ───────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D2137), Color(0xFF0A1228)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _cyan.withAlpha(60)),
              ),
              child: Column(
                children: [
                  const Text(
                    'THE DFC PROMISE',
                    style: TextStyle(
                      color: _cyan,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    SocialPlatformConfigService.ecosystemMission,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: SocialPlatformConfigService.communityPillars
                        .map(_pillarChip)
                        .toList(),
                  ),
                ],
              ),
            ),
          ),

          // ── Adrenaline Health Benefits Grid ────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'ADRENALINE AS MEDICINE',
                      style: TextStyle(
                        color: _green,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  ..._buildBenefitCards(),
                ],
              ),
            ),
          ),

          // ── Quick-Connect Actions — Fan <-> Fighter ────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CONNECT',
                    style: TextStyle(
                      color: _cyan,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _connectTile(
                          context,
                          icon: Icons.sports_mma,
                          title: 'Find Fighters',
                          subtitle: 'Discover & follow athletes',
                          color: _cyan,
                          route: '/explore',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _connectTile(
                          context,
                          icon: Icons.message_outlined,
                          title: 'Messages',
                          subtitle: 'Talk to your community',
                          color: _purple,
                          route: '/messaging',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _connectTile(
                          context,
                          icon: Icons.favorite_outline,
                          title: 'Wellness Hub',
                          subtitle: 'Health, recovery & support',
                          color: _green,
                          route: '/wellness',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _connectTile(
                          context,
                          icon: Icons.people_outline,
                          title: 'Friends',
                          subtitle: 'Your fight community',
                          color: _amber,
                          route: '/friends',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Zero Tolerance Banner ──────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0000),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF1744).withAlpha(80),
                ),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield, color: Color(0xFFFF1744), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'ZERO TOLERANCE',
                        style: TextStyle(
                          color: Color(0xFFFF1744),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...SocialPlatformConfigService.zeroTolerancePolicies.map(
                    (policy) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('  ', style: TextStyle(fontSize: 10)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              policy,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
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
          ),

          // ── Social Sidebar (inline on mobile, sidebar on wide) ─────
          if (!isWide) const SliverToBoxAdapter(child: SocialMediaWidget()),

          // ── Feed + Action Zone ─────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 16),
              child: FeedScreen(),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 24, bottom: 32),
              child: ActionZoneScreen(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Benefit cards from config ────────────────────────────────────────
  static List<Widget> _buildBenefitCards() {
    const colors = [
      _cyan,
      _green,
      _purple,
      _amber,
      Color(0xFFFF4081),
      Color(0xFF2979FF),
    ];
    var i = 0;
    return SocialPlatformConfigService.adrenalineGatewayBenefits.entries.map((
      e,
    ) {
      final color = colors[i % colors.length];
      i++;
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.bolt, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.key.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e.value,
                    style: const TextStyle(
                      color: Colors.white60,
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
    }).toList();
  }

  // ── Pillar chip ─────────────────────────────────────────────────────
  static Widget _pillarChip(String text) {
    final parts = text.split(' — ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _cyan.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cyan.withAlpha(40)),
      ),
      child: Text(
        parts.first,
        style: const TextStyle(
          color: _cyan,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }

  // ── Connect tile (quick-nav) ────────────────────────────────────────
  static Widget _connectTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withAlpha(120),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
