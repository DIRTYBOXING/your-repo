import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/widgets/dfc_card.dart';
import '../../../shared/widgets/dfc_cosmetic_widgets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ADS SPOTLIGHT SYSTEM — Advertiser campaign management & analytics
/// ═══════════════════════════════════════════════════════════════════════════
///
/// For brands, gyms, supplement companies, promoters who want to advertise
/// on the DFC platform. Shows ad packages, targeting, ROI, and creative tools.
/// ═══════════════════════════════════════════════════════════════════════════

class AdsSpotlightScreen extends StatefulWidget {
  const AdsSpotlightScreen({super.key});

  @override
  State<AdsSpotlightScreen> createState() => _AdsSpotlightScreenState();
}

class _AdsSpotlightScreenState extends State<AdsSpotlightScreen> {
  int _selectedPackageIndex = 1; // Default to "Growth" tier

  static const Color _redPrimary = Color(0xFFC62828);
  static const Color _redDark = Color(0xFF7B1A1A);
  static const Color _offWhite = Color(0xFFD0D0D0);
  static const Color _steel = Color(0xFF707070);

  final List<_AdPackage> _packages = [
    const _AdPackage(
      name: 'Starter',
      price: 9,
      period: '/month',
      color: _steel,
      impressions: '5K',
      placement: 'Feed only',
      targeting: 'Basic (region)',
      features: [
        'Banner ad in FightWire feed',
        'Basic analytics dashboard',
        'Regional targeting',
        'Email support',
      ],
    ),
    const _AdPackage(
      name: 'Growth',
      price: 29,
      period: '/month',
      color: _redPrimary,
      impressions: '25K',
      placement: 'Feed + Dashboard',
      targeting: 'Sport + Region',
      features: [
        'Banner + interstitial ads',
        'Dashboard sidebar placement',
        'Sport & region targeting',
        'A/B testing (2 creatives)',
        'Weekly performance report',
        'Priority email support',
      ],
      isPopular: true,
    ),
    const _AdPackage(
      name: 'Spotlight',
      price: 79,
      period: '/month',
      color: _redDark,
      impressions: '100K+',
      placement: 'All surfaces',
      targeting: 'Full stack',
      features: [
        'All ad placements (feed, dashboard, events, marketplace)',
        'Push notification sponsorship',
        'Event banner takeover',
        'Demographic + behavioral targeting',
        'Unlimited A/B testing',
        'Real-time analytics dashboard',
        'Dedicated account manager',
        'Brand profile page',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          const DFCCosmicBackground(
            particleCount: 6,
            primaryColor: Color(0xFF2A1010),
            secondaryColor: Color(0xFF1A1A1A),
          ),
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
                        const Text(
                          'ADS SPOTLIGHT',
                          style: TextStyle(
                            color: Color(0xFFE0E0E0),
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Put your brand in the ring. Reach fighters, fans, and promoters across the DFC ecosystem.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const DFCNeonDivider(
                          color: _redDark,
                          glowEffect: false,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Platform Stats ──
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: DFCSectionHeader(
                      title: 'PLATFORM REACH',
                      icon: Icons.trending_up,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        _buildStatBadge('12.4K', 'Active Users', _offWhite),
                        const SizedBox(width: 10),
                        _buildStatBadge('89K', 'Monthly Views', _redPrimary),
                        const SizedBox(width: 10),
                        _buildStatBadge('3.2%', 'Avg CTR', _redDark),
                      ],
                    ),
                  ),
                ),

                // ── Ad Packages ──
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: DFCSectionHeader(
                      title: 'AD PACKAGES',
                      icon: Icons.campaign_outlined,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 440,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      itemCount: _packages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: SizedBox(
                            width: 280,
                            child: _buildPackageCard(_packages[index], index),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // ── Targeting Options ──
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: DFCSectionHeader(
                      title: 'TARGETING',
                      icon: Icons.gps_fixed,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTargetPill('🥊 Boxing fans', _offWhite),
                        _buildTargetPill('🥋 MMA followers', _redPrimary),
                        _buildTargetPill('📍 By region', _steel),
                        _buildTargetPill('🏋️ Gym owners', _redDark),
                        _buildTargetPill('🎫 Event attendees', _offWhite),
                        _buildTargetPill('👤 Age group', _steel),
                        _buildTargetPill('📱 App section', _redPrimary),
                        _buildTargetPill('🏆 Fighter tier', _redDark),
                      ],
                    ),
                  ),
                ),

                // ── Ad Placements ──
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: DFCSectionHeader(
                      title: 'PLACEMENT ZONES',
                      icon: Icons.dashboard_customize_outlined,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      children: [
                        _buildPlacementRow(
                          'FightWire Feed',
                          'In-stream banners between posts',
                          Icons.feed_outlined,
                          _offWhite,
                        ),
                        const SizedBox(height: 8),
                        _buildPlacementRow(
                          'Dashboard Sidebar',
                          'Premium spot on fighter dashboard',
                          Icons.space_dashboard_outlined,
                          _redPrimary,
                        ),
                        const SizedBox(height: 8),
                        _buildPlacementRow(
                          'Event Pages',
                          'Banner on event detail screens',
                          Icons.event_outlined,
                          _redDark,
                        ),
                        const SizedBox(height: 8),
                        _buildPlacementRow(
                          'Marketplace',
                          'Featured listing spotlight',
                          Icons.storefront_outlined,
                          _steel,
                        ),
                        const SizedBox(height: 8),
                        _buildPlacementRow(
                          'Push Notifications',
                          'Sponsored push to targeted users',
                          Icons.notifications_active_outlined,
                          _redPrimary,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── CTA ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
                    child: DFCCard.action(
                      accent: _redPrimary,
                      ctaText: 'START ADVERTISING',
                      onTap: () async {
                        final uri = Uri(
                          scheme: 'mailto',
                          path: 'partners@datafightcentral.com',
                          queryParameters: {
                            'subject': 'DFC Advertising Enquiry',
                            'body': 'Hi DFC team,\n\nI\'m interested in advertising on Data Fight Central.\n\nBrand / Company: \nBudget range: \nTarget audience: \n\nPlease send me a media kit.\n',
                          },
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Email partners@datafightcentral.com for advertising packages'),
                              ),
                            );
                          }
                        }
                      },
                      child: Column(
                        children: [
                          const Text(
                            'Ready to spotlight your brand?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Contact our team for custom packages and enterprise solutions.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
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

  Widget _buildStatBadge(String value, String label, Color color) {
    return Expanded(
      child: DFCCard.stat(accent: color, statValue: value, statLabel: label),
    );
  }

  Widget _buildPackageCard(_AdPackage pkg, int index) {
    final selected = index == _selectedPackageIndex;
    return GestureDetector(
      onTap: () => setState(() => _selectedPackageIndex = index),
      child: DFCCard.glass(
        accent: pkg.color,
        hasTopGlow: selected,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  pkg.name.toUpperCase(),
                  style: TextStyle(
                    color: pkg.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                if (pkg.isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: pkg.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'POPULAR',
                      style: TextStyle(
                        color: pkg.color,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${pkg.price}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    pkg.period,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Quick stats
            Row(
              children: [
                _miniStat('📊', pkg.impressions, 'impressions'),
                const SizedBox(width: 12),
                _miniStat('📍', pkg.targeting, ''),
              ],
            ),

            const SizedBox(height: 14),

            Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
            const SizedBox(height: 12),

            // Features
            Expanded(
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: pkg.features
                    .map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check, color: pkg.color, size: 14),
                            const SizedBox(width: 6),
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
                    )
                    .toList(),
              ),
            ),

            const SizedBox(height: 10),

            // Select button
            SizedBox(
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? pkg.color.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? pkg.color.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.1),
                    width: 0.6,
                  ),
                ),
                child: Center(
                  child: Text(
                    selected ? 'SELECTED' : 'SELECT PLAN',
                    style: TextStyle(
                      color: selected
                          ? pkg.color
                          : Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String emoji, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          '$value ${label.isNotEmpty ? label : ''}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildTargetPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withValues(alpha: 0.8),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPlacementRow(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return DFCCard.glass(
      accent: color,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: color.withValues(alpha: 0.4),
            size: 20,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AD PACKAGE MODEL
// ─────────────────────────────────────────────────────────────────────────────

class _AdPackage {
  final String name;
  final int price;
  final String period;
  final Color color;
  final String impressions;
  final String placement;
  final String targeting;
  final List<String> features;
  final bool isPopular;

  const _AdPackage({
    required this.name,
    required this.price,
    required this.period,
    required this.color,
    required this.impressions,
    required this.placement,
    required this.targeting,
    required this.features,
    this.isPopular = false,
  });
}
