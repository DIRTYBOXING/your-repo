import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/constants/stripe_config.dart';
import '../../../shared/widgets/dfc_card.dart';
import '../../../shared/widgets/dfc_cosmetic_widgets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PROMOTER PRICING — Event promotion, matchmaking, broadcasting packages
/// ═══════════════════════════════════════════════════════════════════════════
///
/// For promoters who run shows. Ticket selling, card building, streaming,
/// fighter management, and analytics at three tiers.
/// ═══════════════════════════════════════════════════════════════════════════

class PromoterPricingScreen extends StatefulWidget {
  const PromoterPricingScreen({super.key});

  @override
  State<PromoterPricingScreen> createState() => _PromoterPricingScreenState();
}

class _PromoterPricingScreenState extends State<PromoterPricingScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTier = 1;
  bool _isAnnual = false;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          const DFCCosmicBackground(particleCount: 25),
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
                            colors: [
                              DesignTokens.neonRed,
                              DesignTokens.neonAmber,
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'PROMOTER COMMAND',
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
                          'Run shows like a boss. Build cards. Sell tickets. Stream worldwide.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const DFCNeonDivider(color: DesignTokens.neonRed),
                      ],
                    ),
                  ),
                ),

                // ── Billing toggle ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 0.6,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _billingTab('Monthly', !_isAnnual),
                            _billingTab('Annual (Save 20%)', _isAnnual),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Pricing tiers ──
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: DFCSectionHeader(
                      title: 'CHOOSE YOUR TIER',
                      icon: Icons.rocket_launch_outlined,
                    ),
                  ),
                ),

                // Tier cards
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final tiers = _getTiers();
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: _buildTierCard(tiers[index], index),
                    );
                  }, childCount: 3),
                ),

                // ── Feature comparison ──
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 28, 20, 0),
                    child: DFCSectionHeader(
                      title: 'FULL COMPARISON',
                      icon: Icons.compare_arrows,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _buildComparisonTable(),
                  ),
                ),

                // ── Testimonial ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: DFCCard.glass(
                      accent: DesignTokens.neonAmber,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.format_quote,
                            color: DesignTokens.neonAmber,
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '"DFC Promoter Command changed how I run shows. Sold 400 more tickets last quarter and the fight card builder saved me 10 hours per event."',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '— Tony Russo, East Coast Promotions',
                            style: TextStyle(
                              color: DesignTokens.neonAmber.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── CTA ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                    child: AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: DesignTokens.neonRed.withValues(
                                  alpha: 0.15 + _glowController.value * 0.1,
                                ),
                                blurRadius: 20 + _glowController.value * 10,
                                spreadRadius: -4,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: DFCCard.action(
                        accent: DesignTokens.neonRed,
                        ctaText: 'START FREE TRIAL',
                        onTap: () {
                          DfcStripeLinks.openPaymentLink(
                            _isAnnual
                                ? DfcStripeLinks.promoterGymYearly
                                : DfcStripeLinks.promoterGymMonthly,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Opening Promoter checkout...',
                              ),
                              backgroundColor: DesignTokens.neonRed.withValues(
                                alpha: 0.85,
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Column(
                          children: [
                            Text(
                              '14-Day Free Trial',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'No credit card required. Cancel anytime.',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
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

  List<_PromoterTier> _getTiers() {
    final multiplier = _isAnnual ? 0.8 : 1.0;
    return [
      _PromoterTier(
        name: 'Local Show',
        price: (29.99 * multiplier).round(),
        period: _isAnnual ? '/month (billed annually)' : '/month',
        color: DesignTokens.neonCyan,
        icon: Icons.location_on_outlined,
        tagline: 'For hometown promoters getting started',
        highlights: [
          '1 event/month',
          'Up to 200 tickets',
          'Basic fight card builder',
          'Ticket scanning app',
          'Email support',
        ],
      ),
      _PromoterTier(
        name: 'Regional Pro',
        price: (99.99 * multiplier).round(),
        period: _isAnnual ? '/month (billed annually)' : '/month',
        color: DesignTokens.neonAmber,
        icon: Icons.map_outlined,
        tagline: 'Multiple events, bigger reach',
        isPopular: true,
        highlights: [
          'Up to 4 events/month',
          'Unlimited tickets',
          'Advanced card builder + matchmaking',
          'Live streaming integration',
          'Post-event analytics',
          'DFC marketplace visibility',
          'Priority support',
        ],
      ),
      _PromoterTier(
        name: 'Command Center',
        price: (299.99 * multiplier).round(),
        period: _isAnnual ? '/month (billed annually)' : '/month',
        color: DesignTokens.neonRed,
        icon: Icons.military_tech,
        tagline: 'Full-scale promotion empire',
        highlights: [
          'Unlimited events',
          'Multi-venue managements',
          'PPV streaming + revenue share',
          'AI matchmaking engine',
          'White-label ticket pages',
          'Sponsor management tools',
          'Fighter contract tracking',
          'Revenue forecasting',
          'Dedicated success manager',
          'API access for integrations',
        ],
      ),
    ];
  }

  Widget _billingTab(String label, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _isAnnual = label.contains('Annual')),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? DesignTokens.neonRed.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? DesignTokens.neonRed
                : Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTierCard(_PromoterTier tier, int index) {
    final selected = index == _selectedTier;
    return GestureDetector(
      onTap: () => setState(() => _selectedTier = index),
      child: DFCCard.glass(
        accent: tier.color,
        hasTopGlow: selected,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                                'BEST VALUE',
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
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...tier.highlights
                .take(selected ? tier.highlights.length : 4)
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
            if (!selected && tier.highlights.length > 4)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+${tier.highlights.length - 4} more →',
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

  Widget _buildComparisonTable() {
    final rows = [
      const _CompRow('Events per month', ['1', '4', '∞']),
      const _CompRow('Ticket capacity', ['200', 'Unlimited', 'Unlimited']),
      const _CompRow('Fight card builder', ['Basic', 'Advanced', 'AI-powered']),
      const _CompRow('Live streaming', ['—', '✓', 'PPV']),
      const _CompRow('Analytics', ['Basic', 'Advanced', 'Enterprise']),
      const _CompRow('Matchmaking', ['Manual', 'Assisted', 'AI engine']),
      const _CompRow('Sponsor tools', ['—', 'Basic', 'Full suite']),
      const _CompRow('Fighter contracts', ['—', '—', '✓']),
      const _CompRow('API access', ['—', '—', '✓']),
      const _CompRow('Support', ['Email', 'Priority', 'Dedicated']),
    ];

    final colors = [
      DesignTokens.neonCyan,
      DesignTokens.neonAmber,
      DesignTokens.neonRed,
    ];

    return DFCCard.glass(
      accent: Colors.white.withValues(alpha: 0.3),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Expanded(flex: 3, child: SizedBox()),
              ...List.generate(
                3,
                (i) => Expanded(
                  flex: 2,
                  child: Text(
                    ['LOCAL', 'REGIONAL', 'COMMAND'][i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors[i],
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      row.feature,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  ...List.generate(
                    3,
                    (i) => Expanded(
                      flex: 2,
                      child: Text(
                        row.values[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: row.values[i] == '—'
                              ? Colors.white.withValues(alpha: 0.2)
                              : row.values[i] == '✓'
                              ? colors[i]
                              : Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: row.values[i] == '✓'
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoterTier {
  final String name;
  final int price;
  final String period;
  final Color color;
  final IconData icon;
  final String tagline;
  final List<String> highlights;
  final bool isPopular;

  const _PromoterTier({
    required this.name,
    required this.price,
    required this.period,
    required this.color,
    required this.icon,
    required this.tagline,
    required this.highlights,
    this.isPopular = false,
  });
}

class _CompRow {
  final String feature;
  final List<String> values;

  const _CompRow(this.feature, this.values);
}
