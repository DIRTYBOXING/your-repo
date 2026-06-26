import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC+ STREAMING COMPARISON — Why DFC Beats the Giants
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Visual comparison: DFC+ vs Paramount+, ESPN+, DAZN, UFC Fight Pass
/// Shows price, content, features, and why DFC is the combat sports home.
///
/// "They charge more. We deliver more. For the culture."
/// ═══════════════════════════════════════════════════════════════════════════
class DFCStreamingComparisonScreen extends StatefulWidget {
  const DFCStreamingComparisonScreen({super.key});

  @override
  State<DFCStreamingComparisonScreen> createState() =>
      _DFCStreamingComparisonScreenState();
}

class _DFCStreamingComparisonScreenState
    extends State<DFCStreamingComparisonScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(child: _buildHero()),
          SliverToBoxAdapter(child: _buildPriceComparison()),
          SliverToBoxAdapter(child: _buildFeatureMatrix()),
          SliverToBoxAdapter(child: _buildWhyDFC()),
          SliverToBoxAdapter(child: _buildPPVComparison()),
          SliverToBoxAdapter(child: _buildTestimonials()),
          SliverToBoxAdapter(child: _buildCTA()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Prices shown reflect publicly available pricing as of March 2026. '
                'DFC streams licensed content from partner promotions only. '
                'Third-party platform names and pricing are provided for comparison purposes. '
                'All trademarks belong to their respective owners.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // ── App Bar ──

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: DesignTokens.bgPrimary.withValues(alpha: 0.95),
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      title: const Row(
        children: [
          Icon(Icons.bolt, color: DesignTokens.neonCyan, size: 22),
          SizedBox(width: 8),
          Text(
            'DFC+ Price Comparison',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Section ──

  Widget _buildHero() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.neonCyan.withValues(alpha: 0.12),
            DesignTokens.neonMagenta.withValues(alpha: 0.08),
            DesignTokens.bgPrimary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, _) => Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DesignTokens.neonCyan.withValues(
                      alpha: 0.3 * _pulseAnim.value,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Center(
                child: Text(
                  'DFC+',
                  style: TextStyle(
                    color: DesignTokens.neonCyan,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'THE AFFORDABLE ALTERNATIVE\nFOR COMBAT SPORTS FANS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Major platforms charge \$12–\$25/month for general sports.\nDFC is built exclusively for combat sports — from \$2.99/month.',
            textAlign: TextAlign.center,
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

  // ── Price Comparison ──

  Widget _buildPriceComparison() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('MONTHLY PRICE COMPARISON', Icons.attach_money),
          const SizedBox(height: 12),
          _buildPriceBar('DFC+ Fighter Pro', 2.99, DesignTokens.neonCyan, true),
          _buildPriceBar(
            'UFC Fight Pass',
            9.99,
            const Color(0xFFD32F2F),
            false,
          ),
          _buildPriceBar('ESPN+', 11.99, const Color(0xFFFF6F00), false),
          _buildPriceBar('Paramount+', 12.99, const Color(0xFF1565C0), false),
          _buildPriceBar('DAZN', 24.99, const Color(0xFF212121), false),
          _buildPriceBar(
            'PPV (Single UFC)',
            79.99,
            const Color(0xFF880E4F),
            false,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignTokens.neonGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: DesignTokens.neonGreen.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.savings,
                  color: DesignTokens.neonGreen,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'DFC+ saves you up to \$264/year vs major platforms — and you get combat sports tools, AI coaching, social feed, licensed partner PPV access, marketplace & more. Regional pricing available for 100+ countries.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPriceBar(String name, double price, Color color, bool isDFC) {
    final maxPrice = 79.99;
    final barWidth = (price / maxPrice).clamp(0.05, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: isDFC ? DesignTokens.neonCyan : Colors.white70,
                  fontSize: 12,
                  fontWeight: isDFC ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
              Text(
                '\$${price.toStringAsFixed(2)}/mo',
                style: TextStyle(
                  color: isDFC ? DesignTokens.neonCyan : Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(
                height: isDFC ? 10 : 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, _) => FractionallySizedBox(
                  widthFactor: barWidth,
                  child: Container(
                    height: isDFC ? 10 : 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDFC
                            ? [DesignTokens.neonCyan, DesignTokens.neonGreen]
                            : [color, color.withValues(alpha: 0.6)],
                      ),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: isDFC
                          ? [
                              BoxShadow(
                                color: DesignTokens.neonCyan.withValues(
                                  alpha: 0.4 * _pulseAnim.value,
                                ),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Feature Matrix ──

  Widget _buildFeatureMatrix() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('WHAT YOU ACTUALLY GET', Icons.compare_arrows),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                _matrixHeader(),
                ..._features.asMap().entries.map((e) {
                  return _matrixRow(e.value, e.key.isEven);
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _matrixHeader() {
    const platforms = ['DFC+', 'ESPN+', 'DAZN', 'P+'];
    const colors = [
      DesignTokens.neonCyan,
      Color(0xFFFF6F00),
      Color(0xFF9E9E9E),
      Color(0xFF1565C0),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 4,
            child: Text(
              'FEATURE',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ...List.generate(platforms.length, (i) {
            return Expanded(
              flex: 2,
              child: Text(
                platforms[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors[i],
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _matrixRow(_FeatureRow f, bool even) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: even ? Colors.transparent : Colors.white.withValues(alpha: 0.02),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              f.name,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
          Expanded(flex: 2, child: _featureIcon(f.dfc)),
          Expanded(flex: 2, child: _featureIcon(f.espn)),
          Expanded(flex: 2, child: _featureIcon(f.dazn)),
          Expanded(flex: 2, child: _featureIcon(f.paramount)),
        ],
      ),
    );
  }

  Widget _featureIcon(String val) {
    if (val == '✓') {
      return const Icon(
        Icons.check_circle,
        size: 16,
        color: DesignTokens.neonGreen,
      );
    }
    if (val == '—') {
      return Icon(
        Icons.remove_circle_outline,
        size: 16,
        color: Colors.white.withValues(alpha: 0.2),
      );
    }
    return Text(
      val,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white60,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ── Why DFC Section ──

  Widget _buildWhyDFC() {
    final reasons = [
      const _Reason(
        icon: Icons.sports_mma,
        title: 'COMBAT SPORTS ONLY',
        body:
            'ESPN+ gives you 80% ball sports. Paramount+ gives you reality TV. DAZN dropped half its roster. DFC is 100% combat sports — UFC, MMA, Brawling, Boxing, Muay Thai, Kickboxing, Bare Knuckle, Wrestling, and more. Every discipline. Every promotion.',
        color: DesignTokens.neonRed,
      ),
      const _Reason(
        icon: Icons.psychology,
        title: 'AI FIGHT INTELLIGENCE',
        body:
            'No other streaming platform has AI coaching, style clash prediction, combat analytics, or training intelligence built in. DFC doesn\'t just show fights — it makes you smarter about them.',
        color: DesignTokens.neonCyan,
      ),
      const _Reason(
        icon: Icons.people,
        title: 'SOCIAL + COMMUNITY',
        body:
            'FightWire feed, messaging, friends, fighter profiles, gym discovery, event finder — a full social network for combat sports. Paramount+ has zero community. ESPN+ has zero social. We have it all.',
        color: DesignTokens.neonMagenta,
      ),
      const _Reason(
        icon: Icons.storefront,
        title: 'MARKETPLACE + PROMOTER TOOLS',
        body:
            'Sell gear. Post events. Book trainers. Manage fighter rosters. Create PPV events with Stripe Connect payouts. No other streaming app is also a business platform for the fight game.',
        color: DesignTokens.neonAmber,
      ),
      const _Reason(
        icon: Icons.public,
        title: 'GLOBAL REGIONAL PRICING',
        body:
            'Netflix charges \$6.99 in Nigeria. We charge \$0.99. Real pricing for real people in 100+ countries across 4 income tiers. Plus loyalty discounts up to 25% off. The fight game is global — our pricing matches.',
        color: DesignTokens.neonGreen,
      ),
      const _Reason(
        icon: Icons.rocket_launch,
        title: 'PROMOTER-FIRST PPV',
        body:
            'Promoters keep 85% of PPV revenue. Stripe Connect instant payouts. Create events, set tiered pricing, go live — all from one dashboard. UFC takes everything from promoters. We give it back.',
        color: Color(0xFFFF6600),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('WHY DFC WINS', Icons.emoji_events),
          const SizedBox(height: 12),
          ...reasons.map(_buildReasonCard),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildReasonCard(_Reason r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: r.color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: r.color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: r.color.withValues(alpha: 0.12),
            ),
            child: Icon(r.icon, color: r.color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.title,
                  style: TextStyle(
                    color: r.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  r.body,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
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

  // ── PPV Comparison ──

  Widget _buildPPVComparison() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('PPV PRICE COMPARISON', Icons.live_tv),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                _ppvRow('UFC Main Card PPV', '\$79.99', Colors.red),
                _ppvRow(
                  'Boxing Championship (DAZN)',
                  '\$59.99',
                  const Color(0xFF9E9E9E),
                ),
                _ppvRow(
                  'Bellator / PFL PPV',
                  '\$49.99',
                  const Color(0xFF1565C0),
                ),
                const Divider(color: Colors.white12, height: 20),
                _ppvRow(
                  'DFC: IBC Championships',
                  '\$29.99',
                  DesignTokens.neonCyan,
                ),
                _ppvRow(
                  'DFC: Ultimate Legends',
                  '\$24.99',
                  DesignTokens.neonCyan,
                ),
                _ppvRow('DFC: Regional MMA', '\$19.99', DesignTokens.neonCyan),
                _ppvRow(
                  'DFC: Early Bird Pricing',
                  '\$14.99',
                  DesignTokens.neonGreen,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'DFC promoters keep 85% of PPV revenue.\nUFC promoters keep 0%. Think about that.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: DesignTokens.neonCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _ppvRow(String name, String price, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              price,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Testimonials / Social Proof ──

  Widget _buildTestimonials() {
    final quotes = [
      const _Quote(
        'Danny Mac — IBC Founder',
        'DFC gave us the distribution and streaming infrastructure that would have cost us \$500K to build. Now our events reach 12 countries.',
        Icons.verified,
        Color(0xFFFF6600),
      ),
      const _Quote(
        'Joey Demicoli — Ultimate Legends',
        '30 years in fight promotion and I\'ve never had a platform that gives us 85% of PPV rev AND handles the tech. This changes everything.',
        Icons.verified,
        DesignTokens.neonGreen,
      ),
      const _Quote(
        'Independent Promoter',
        'I was paying \$15K per event for streaming alone. DFC is \$9.99/month and they handle the PPV, tickets, marketing AND social. No brainer.',
        Icons.person,
        DesignTokens.neonCyan,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('WHAT PROMOTERS SAY', Icons.format_quote),
          const SizedBox(height: 12),
          ...quotes.map(_buildQuoteCard),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(_Quote q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: q.color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(q.icon, color: q.color, size: 18),
              const SizedBox(width: 8),
              Text(
                q.name,
                style: TextStyle(
                  color: q.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '"${q.text}"',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── CTA ──

  Widget _buildCTA() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, _) => Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: DesignTokens.neonCyan.withValues(
                      alpha: 0.3 * _pulseAnim.value,
                    ),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push('/access-pass'),
                  child: const Column(
                    children: [
                      Text(
                        'START YOUR DFC+ ACCESS PASS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'From \$0.99/month · Cancel anytime · 100+ countries',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQuickLink('PPV Hub', Icons.live_tv, '/ppv'),
              const SizedBox(width: 12),
              _buildQuickLink(
                'Plans',
                Icons.workspace_premium,
                '/subscription',
              ),
              const SizedBox(width: 12),
              _buildQuickLink('Membership', Icons.diamond, '/membership'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLink(String label, IconData icon, String route) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: DesignTokens.neonCyan, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: DesignTokens.neonCyan, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATA
  // ═══════════════════════════════════════════════════════════════════════════

  static final List<_FeatureRow> _features = [
    const _FeatureRow('Live PPV Events', '✓', '✓', '✓', 'Some'),
    const _FeatureRow('Combat Sports Focus', '100%', '~15%', '~60%', '~5%'),
    const _FeatureRow('AI Fight Coaching', '✓', '—', '—', '—'),
    const _FeatureRow('Fight Analytics', '✓', '—', '—', '—'),
    const _FeatureRow('Social Feed', '✓', '—', '—', '—'),
    const _FeatureRow('Messaging / Friends', '✓', '—', '—', '—'),
    const _FeatureRow('Fighter Profiles', '✓', '—', '—', '—'),
    const _FeatureRow('Marketplace', '✓', '—', '—', '—'),
    const _FeatureRow('Event Finder / Maps', '✓', '—', '—', '—'),
    const _FeatureRow('Promoter Dashboard', '✓', '—', '—', '—'),
    const _FeatureRow('PPV Revenue to Promoter', '85%', '0%', '~30%', '0%'),
    const _FeatureRow('Regional Pricing', '✓', '—', 'Some', '—'),
    const _FeatureRow('Loyalty Discounts', 'Up to 25%', '—', '—', '—'),
    const _FeatureRow('Gym Discovery', '✓', '—', '—', '—'),
    const _FeatureRow('Training Programs', '✓', '—', '—', '—'),
    const _FeatureRow('Wellness Tracking', '✓', '—', '—', '—'),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════════════════════

class _FeatureRow {
  final String name;
  final String dfc;
  final String espn;
  final String dazn;
  final String paramount;

  const _FeatureRow(this.name, this.dfc, this.espn, this.dazn, this.paramount);
}

class _Reason {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const _Reason({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });
}

class _Quote {
  final String name;
  final String text;
  final IconData icon;
  final Color color;

  const _Quote(this.name, this.text, this.icon, this.color);
}
