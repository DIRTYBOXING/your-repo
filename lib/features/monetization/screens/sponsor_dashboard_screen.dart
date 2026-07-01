import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/widgets/dfc_card.dart';
import '../../../shared/widgets/dfc_cosmetic_widgets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SPONSOR DASHBOARD — Brand partnerships, ROI, fighter sponsorships
/// ═══════════════════════════════════════════════════════════════════════════
///
/// For sponsors who support fighters, events, or the platform itself.
/// Track brand exposure, manage sponsorship deals, see ROI analytics.
/// ═══════════════════════════════════════════════════════════════════════════

class SponsorDashboardScreen extends StatefulWidget {
  const SponsorDashboardScreen({super.key});

  @override
  State<SponsorDashboardScreen> createState() => _SponsorDashboardScreenState();
}

class _SponsorDashboardScreenState extends State<SponsorDashboardScreen> {
  int _selectedTier = 1;

  static const Color _accentPrimary = Color(0xFF35A8C7);
  static const Color _accentSecondary = Color(0xFF5E7396);
  static const Color _accentTertiary = Color(0xFF7B63B8);
  static const Color _accentSuccess = Color(0xFF4DBE74);
  static const Color _accentWarning = Color(0xFFC08D3B);

  final List<_SponsorTier> _tiers = [
    const _SponsorTier(
      name: 'Corner Sponsor',
      price: 199,
      period: '/month',
      color: _accentPrimary,
      icon: Icons.sports_mma,
      tagline: 'Support individual fighters',
      features: [
        'Sponsor up to 3 fighters',
        'Logo on fighter profile page',
        'Mentioned in fight announcements',
        'Monthly exposure report',
        'Direct message access to fighters',
        'Social media shoutout from fighters',
      ],
      stats: {'Avg Exposure': '8K views/mo', 'Fighter Pool': '500+'},
    ),
    const _SponsorTier(
      name: 'Event Sponsor',
      price: 999,
      period: '/event',
      color: _accentSecondary,
      icon: Icons.emoji_events_outlined,
      tagline: 'Brand your events',
      isPopular: true,
      features: [
        'Event title sponsorship',
        'Logo on all event materials',
        'Banner placement at venue',
        'In-app event page branding',
        'VIP passes (10 per event)',
        'Post-event analytics report',
        'Social media campaign included',
        'Ring announcer mentions',
      ],
      stats: {'Avg Attendance': '2.4K', 'Stream Viewers': '15K'},
    ),
    const _SponsorTier(
      name: 'Platform Partner',
      price: 4999,
      period: '/month',
      color: _accentTertiary,
      icon: Icons.handshake,
      tagline: 'Own the ecosystem',
      features: [
        'Platform-wide brand integration',
        'Custom branded section in app',
        'All event sponsorship included',
        'Unlimited fighter sponsorships',
        'Push notification campaigns',
        'Co-branded content creation',
        'Quarterly strategy sessions',
        'White-label analytics portal',
        'Exclusive promotional events',
        'DFC ambassador program access',
      ],
      stats: {'Total Reach': '89K/mo', 'Brand Recall': '72%'},
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      body: Stack(
        children: [
          const DFCCosmicBackground(particleCount: 14),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Header ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const Spacer(),
                            const DFCLogo(size: DFCLogoSize.small),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [_accentSecondary, _accentPrimary],
                          ).createShader(bounds),
                          child: const Text(
                            'SPONSOR DASHBOARD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Invest in fighters. Brand your events. Own the spotlight.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const DFCNeonDivider(color: _accentSecondary),
                      ],
                    ),
                  ),
                ),

                // ── Why Sponsor ──
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: DFCSectionHeader(
                      title: 'WHY SPONSOR ON DFC',
                      icon: Icons.insights,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        _buildWhyCard(
                          '🎯',
                          'Targeted',
                          'Reach real fight fans, not bots',
                          _accentPrimary,
                        ),
                        const SizedBox(width: 10),
                        _buildWhyCard(
                          '📈',
                          'Measurable',
                          'Real-time ROI tracking',
                          _accentSuccess,
                        ),
                        const SizedBox(width: 10),
                        _buildWhyCard(
                          '🤝',
                          'Authentic',
                          'Community-driven exposure',
                          _accentSecondary,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Sponsor Tiers ──
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: DFCSectionHeader(
                      title: 'SPONSORSHIP TIERS',
                      icon: Icons.layers_outlined,
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: _buildTierCard(_tiers[index], index),
                    );
                  }, childCount: _tiers.length),
                ),

                // ── ROI Preview ──
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: DFCSectionHeader(
                      title: 'ROI SNAPSHOT',
                      icon: Icons.analytics_outlined,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: DFCCard.glass(
                      accent: _accentSecondary,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _roiMetric('Brand Views', '142K', _accentPrimary),
                              _roiMetric(
                                'Click-Throughs',
                                '4.8K',
                                _accentSuccess,
                              ),
                              _roiMetric(
                                'Conversions',
                                '312',
                                _accentSecondary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _roiMetric('Avg CTR', '3.4%', _accentWarning),
                              _roiMetric(
                                'Cost/Click',
                                '\$0.42',
                                _accentTertiary,
                              ),
                              _roiMetric('ROI', '340%', _accentSuccess),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Sponsored Fighters Showcase ──
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: DFCSectionHeader(
                      title: 'FEATURED FIGHTERS',
                      icon: Icons.people_outline,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      children: [
                        _buildFighterSpotlight(
                          'Marcus "The Machine" Rivera',
                          '12-2-0',
                          _accentPrimary,
                        ),
                        _buildFighterSpotlight(
                          'Aisha "Lightning" Okonkwo',
                          '8-1-0',
                          _accentTertiary,
                        ),
                        _buildFighterSpotlight(
                          'Jake "Iron Wall" Chen',
                          '15-3-1',
                          _accentSecondary,
                        ),
                        _buildFighterSpotlight(
                          'Sofia "La Tormenta" Reyes',
                          '10-0-0',
                          _accentSuccess,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── CTA ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
                    child: DFCCard.banner(
                      accent: _accentTertiary,
                      onTap: () async {
                        final uri = Uri(
                          scheme: 'mailto',
                          path: 'partners@datafightcentral.com',
                          queryParameters: {
                            'subject': 'DFC Sponsorship Application',
                            'body': 'Hi DFC team,\n\nI\'d like to apply to become a DFC Sponsor.\n\nBrand / Company: \nWebsite: \nSponsor level interest: \n\nPlease send me the sponsorship prospectus.\n',
                          },
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Email partners@datafightcentral.com to apply',
                                ),
                                backgroundColor: _accentTertiary.withValues(
                                  alpha: 0.85,
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      child: Column(
                        children: [
                          const Text(
                            'Become a DFC Sponsor',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Join brands like yours that are changing the fight game.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _accentSecondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _accentSecondary.withValues(alpha: 0.5),
                                width: 0.6,
                              ),
                            ),
                            child: const Text(
                              'GET STARTED',
                              style: TextStyle(
                                color: _accentSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildWhyCard(String emoji, String title, String desc, Color color) {
    return Expanded(
      child: DFCCard.glass(
        accent: color,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              desc,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard(_SponsorTier tier, int index) {
    final selected = index == _selectedTier;
    return GestureDetector(
      onTap: () => setState(() => _selectedTier = index),
      child: DFCCard.glass(
        accent: tier.color,
        hasTopGlow: selected,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tier.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(tier.icon, color: tier.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            tier.name.toUpperCase(),
                            style: TextStyle(
                              color: tier.color,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          if (tier.isPopular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: tier.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'POPULAR',
                                style: TextStyle(
                                  color: tier.color,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        tier.tagline,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${tier.price}',
                      style: TextStyle(
                        color: tier.color,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      tier.period,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Stats row
            if (tier.stats.isNotEmpty)
              Row(
                children: tier.stats.entries
                    .map(
                      (e) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: tier.color.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.value,
                                style: TextStyle(
                                  color: tier.color,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                e.key,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),

            const SizedBox(height: 12),

            // Features
            ...tier.features
                .take(selected ? tier.features.length : 4)
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: tier.color,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            f,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

            if (!selected && tier.features.length > 4)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+${tier.features.length - 4} more features →',
                  style: TextStyle(
                    color: tier.color.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _roiMetric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFighterSpotlight(String name, String record, Color color) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      child: DFCCard.glass(
        accent: color,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              record,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SponsorTier {
  final String name;
  final int price;
  final String period;
  final Color color;
  final IconData icon;
  final String tagline;
  final List<String> features;
  final Map<String, String> stats;
  final bool isPopular;

  const _SponsorTier({
    required this.name,
    required this.price,
    required this.period,
    required this.color,
    required this.icon,
    required this.tagline,
    required this.features,
    this.stats = const {},
    this.isPopular = false,
  });
}
