import 'package:flutter/material.dart';
import '../../../core/constants/stripe_config.dart';
import '../../../shared/widgets/dfc_card.dart';
import '../../../shared/widgets/dfc_cosmetic_widgets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHTER PRO PRICING — Training AI, intelligence, marketplace, analytics
/// ═══════════════════════════════════════════════════════════════════════════
///
/// For fighters who want to level up. Combat intelligence, training plans,
/// opponent analysis, performance tracking, and career tools.
/// ═══════════════════════════════════════════════════════════════════════════

class FighterProPricingScreen extends StatefulWidget {
  const FighterProPricingScreen({super.key});

  @override
  State<FighterProPricingScreen> createState() =>
      _FighterProPricingScreenState();
}

class _FighterProPricingScreenState extends State<FighterProPricingScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTier = 1;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          const DFCCosmicBackground(particleCount: 30),
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
                            colors: [Colors.white, Color(0xFFFF1744)],
                          ).createShader(bounds),
                          child: const Text(
                            'FIGHTER PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Train smarter. Fight harder. Every tool a champion needs.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const DFCNeonDivider(color: Color(0xFFFF1744)),
                      ],
                    ),
                  ),
                ),

                // ── Hero Stats ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        _heroStat(
                          '2,400+',
                          'Active Fighters',
                          const Color(0xFFFF1744),
                        ),
                        const SizedBox(width: 10),
                        _heroStat('89%', 'Win Rate Improvement', Colors.white),
                        const SizedBox(width: 10),
                        _heroStat(
                          '4.9★',
                          'User Rating',
                          const Color(0xFFFF1744),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Core Features ──
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: DFCSectionHeader(
                      title: 'WHAT YOU GET',
                      icon: Icons.sports_mma,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 190,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      children: [
                        _featureShowcase(
                          Icons.psychology,
                          'Combat AI',
                          'Style analysis, opponent breakdowns, fight IQ scoring',
                          const Color(0xFFFF1744),
                        ),
                        _featureShowcase(
                          Icons.fitness_center,
                          'Smart Training',
                          'AI-generated training plans tailored to your style',
                          Colors.white,
                        ),
                        _featureShowcase(
                          Icons.analytics_outlined,
                          'Performance',
                          'Track every metric: strikes, combos, cardio, power',
                          const Color(0xFFFF1744),
                        ),
                        _featureShowcase(
                          Icons.storefront_outlined,
                          'Marketplace',
                          'Equipment deals, trainer connections, gym access',
                          Colors.white,
                        ),
                        _featureShowcase(
                          Icons.group_outlined,
                          'Community',
                          'Sparring partners, fight camps, skill sharing',
                          const Color(0xFFFF1744),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Pricing Tiers ──
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: DFCSectionHeader(
                      title: 'CHOOSE YOUR LEVEL',
                      icon: Icons.trending_up,
                    ),
                  ),
                ),

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
                      title: 'FEATURE BREAKDOWN',
                      icon: Icons.view_list_outlined,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _buildFeatureTable(),
                  ),
                ),

                // ── Social proof ──
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: DFCSectionHeader(
                      title: 'FIGHTER STORIES',
                      icon: Icons.auto_awesome,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 180,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      children: [
                        _testimonialCard(
                          'Marcus R.',
                          'Amateur Boxer',
                          'The AI told me my jab was 40ms slower from southpaw. Fixed it in 2 weeks. Won my next 3 fights.',
                          const Color(0xFFFF1744),
                        ),
                        _testimonialCard(
                          'Aisha O.',
                          'MMA Pro',
                          'Opponent analysis showed his takedown defense drops in round 3. Game plan worked perfectly.',
                          Colors.white,
                        ),
                        _testimonialCard(
                          'Jake C.',
                          'Kickboxer',
                          'Went from local shows to ranked regional contender in 8 months using DFC training plans.',
                          const Color(0xFFFF1744),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── CTA ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF1744).withValues(
                                  alpha: 0.1 + _pulseController.value * 0.1,
                                ),
                                blurRadius: 20 + _pulseController.value * 10,
                                spreadRadius: -4,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: DFCCard.action(
                        accent: const Color(0xFFFF1744),
                        ctaText: 'START 7-DAY FREE TRIAL',
                        onTap: () {
                          DfcStripeLinks.openPaymentLink(
                            DfcStripeLinks.fighterProMonthly,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Opening Fighter Pro checkout...',
                              ),
                              backgroundColor: const Color(
                                0xFFFF1744,
                              ).withValues(alpha: 0.85),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            const Text(
                              'Ready to Level Up?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '7-day free trial. No commitment. Cancel anytime.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _trustBadge(Icons.lock_outline, 'Secure'),
                                const SizedBox(width: 16),
                                _trustBadge(
                                  Icons.credit_card_off,
                                  'No card needed',
                                ),
                                const SizedBox(width: 16),
                                _trustBadge(
                                  Icons.cancel_outlined,
                                  'Cancel anytime',
                                ),
                              ],
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

  List<_FighterTier> _getTiers() => [
    const _FighterTier(
      name: 'Free',
      price: 0,
      color: Colors.white,
      icon: Icons.sports_martial_arts,
      tagline: 'Get started. Always free.',
      highlights: [
        'Basic fighter profile',
        'Community feed access',
        'Limited fight stats',
        'Public marketplace listings',
        '1 training insight/week',
      ],
    ),
    const _FighterTier(
      name: 'Fighter Pro',
      price: 9.99,
      color: Color(0xFFFF1744),
      icon: Icons.bolt,
      tagline: 'Every tool to win',
      isPopular: true,
      highlights: [
        'Full Combat AI engine access',
        'Unlimited training plans',
        'Opponent style analysis',
        'Performance tracking + trends',
        'Fight IQ scoring',
        'Priority marketplace access',
        'Corner advice generator',
        'Sparring partner matching',
      ],
    ),
    const _FighterTier(
      name: 'Elite Camp',
      price: 24.99,
      color: Colors.white,
      icon: Icons.emoji_events,
      tagline: 'Built for champions & teams',
      highlights: [
        'Everything in Fighter Pro',
        'Team/camp management (up to 10)',
        'Video analysis upload',
        'Custom training periodization',
        'Fight camp scheduling',
        'Nutrition tracking integration',
        'Career analytics dashboard',
        'Sponsor visibility boost',
        'Direct promoter messaging',
        'Priority event sign-ups',
      ],
    ),
  ];

  Widget _heroStat(String value, String label, Color color) {
    return Expanded(
      child: DFCCard.stat(accent: color, statValue: value, statLabel: label),
    );
  }

  Widget _featureShowcase(
    IconData icon,
    String title,
    String desc,
    Color color,
  ) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: DFCCard.glass(
        accent: color,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard(_FighterTier tier, int index) {
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
                                'MOST POPULAR',
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
                      tier.price == 0
                          ? 'FREE'
                          : '\$${tier.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: tier.color,
                        fontSize: tier.price == 0 ? 20 : 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (tier.price > 0)
                      Text(
                        '/month',
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

  Widget _buildFeatureTable() {
    final rows = [
      const _FRow('Fighter profile', ['Basic', 'Enhanced', 'Premium']),
      const _FRow('Training plans', ['1/week', 'Unlimited', 'Unlimited']),
      const _FRow('Combat AI analysis', ['—', '✓', '✓']),
      const _FRow('Opponent breakdown', ['—', '✓', '✓']),
      const _FRow('Fight IQ scoring', ['—', '✓', '✓']),
      const _FRow('Performance trends', ['—', '✓', '✓']),
      const _FRow('Corner advice', ['—', '✓', '✓']),
      const _FRow('Video analysis', ['—', '—', '✓']),
      const _FRow('Team management', ['—', '—', 'Up to 10']),
      const _FRow('Nutrition tracking', ['—', '—', '✓']),
      const _FRow('Sponsor visibility', ['—', '—', 'Boosted']),
      const _FRow('Promoter messaging', ['—', '—', 'Direct']),
    ];

    final colors = [Colors.white, const Color(0xFFFF1744), Colors.white];

    return DFCCard.glass(
      accent: Colors.white.withValues(alpha: 0.3),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(flex: 3, child: SizedBox()),
              ...List.generate(
                3,
                (i) => Expanded(
                  flex: 2,
                  child: Text(
                    ['FREE', 'PRO', 'ELITE'][i],
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

  Widget _testimonialCard(String name, String role, String quote, Color color) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      child: DFCCard.glass(
        accent: color,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.format_quote, color: color, size: 20),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                '"$quote"',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              role,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trustBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _FighterTier {
  final String name;
  final double price;
  final Color color;
  final IconData icon;
  final String tagline;
  final List<String> highlights;
  final bool isPopular;

  const _FighterTier({
    required this.name,
    required this.price,
    required this.color,
    required this.icon,
    required this.tagline,
    required this.highlights,
    this.isPopular = false,
  });
}

class _FRow {
  final String feature;
  final List<String> values;

  const _FRow(this.feature, this.values);
}
