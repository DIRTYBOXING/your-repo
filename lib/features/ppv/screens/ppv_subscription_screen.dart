import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/router_constants.dart' as rc;
import '../../../core/constants/stripe_config.dart';
import '../../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV SUBSCRIPTION SCREEN — Kayo Sports-Quality Tier Selection
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Matches Kayo Sports pricing page: clean tiers, green CTA, dark theme,
/// feature comparison, promotional intro pricing.
///
/// Tiers:
///   • DFC Basic (Free)    — News feed, fighter profiles, limited highlights
///   • DFC Standard        — All replays, full event library, no live PPV
///   • DFC Premium         — Live PPV included, 4K, multi-cam, exclusive content
///
/// Route: /ppv/subscribe
/// ═══════════════════════════════════════════════════════════════════════════
class PPVSubscriptionScreen extends StatefulWidget {
  const PPVSubscriptionScreen({super.key});

  @override
  State<PPVSubscriptionScreen> createState() => _PPVSubscriptionScreenState();
}

class _PPVSubscriptionScreenState extends State<PPVSubscriptionScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTier = 1; // 0=Basic, 1=Standard, 2=Premium
  late AnimationController _glowCtrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glow = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          _buildHeroBanner(),
          _buildTierCards(),
          _buildFeatureComparison(),
          _buildSportLogos(),
          _buildFAQ(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'DFC Fight Pass provides access to PPV events from licensed partner promotions. '
                'Content availability varies by region and partnership agreements. '
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
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ── App Bar ──
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: DesignTokens.bgPrimary,
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(rc.RouteConstants.home);
          }
        },
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [DesignTokens.neonRed, DesignTokens.neonMagenta],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.live_tv, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const Text(
            'DFC PPV',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Banner (Kayo-style promotional) ──
  SliverToBoxAdapter _buildHeroBanner() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0A2E), Color(0xFF0D1B2A)],
          ),
          border: Border.all(
            color: DesignTokens.neonCyan.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          children: [
            // DFC logo badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DesignTokens.neonCyan.withValues(alpha: 0.2),
                    DesignTokens.neonMagenta.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                'DFC FIGHT PASS',
                style: TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Every Partner Fight.\nEvery Round.\nLive & On Demand.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Stream live PPV events from DFC partner promotions,\nreplays, exclusive interviews, and growing combat sports content.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Promotional pricing
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: DesignTokens.neonGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DesignTokens.neonGreen.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                'Get your first month for just \$1',
                style: TextStyle(
                  color: DesignTokens.neonGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tier Cards (Kayo Premium / Standard / Basic) ──
  SliverToBoxAdapter _buildTierCards() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _buildTierCard(
              index: 2,
              name: 'Premium',
              tagline: 'Special DFC Offer',
              originalPrice: '\$24.99',
              promoPrice: '\$1',
              priceNote: '/month AUD',
              promoNote: 'for the first month then \$24.99/month AUD',
              ctaText: 'Continue with Premium',
              ctaColor: DesignTokens.neonGreen,
              features: [
                'Watch in up to 4K',
                'Watch on 2 screens at the same time',
                'All DFC partner live PPV events included',
                'Multi-camera angles',
                'Exclusive fighter interviews',
                'Ad-free experience',
              ],
              isPopular: true,
            ),
            const SizedBox(height: 16),
            _buildTierCard(
              index: 1,
              name: 'Standard',
              tagline: null,
              originalPrice: null,
              promoPrice: '\$14.99',
              priceNote: '/month AUD',
              promoNote: null,
              ctaText: 'Continue with Standard',
              ctaColor: Colors.white,
              features: [
                'Watch in up to HD',
                'Watch on 1 screen',
                'PPV events at discounted rate',
                'Full replay library',
                'Fighter profiles & stats',
              ],
              isPopular: false,
            ),
            const SizedBox(height: 16),
            _buildTierCard(
              index: 0,
              name: 'Basic',
              tagline: 'Free',
              originalPrice: null,
              promoPrice: '\$0',
              priceNote: '/month AUD',
              promoNote: 'No lock-in contract, cancel anytime',
              ctaText: 'Start with Basic',
              ctaColor: Colors.grey,
              features: [
                'News feed & fighter profiles',
                'Limited highlights',
                'Community access',
              ],
              isPopular: false,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard({
    required int index,
    required String name,
    required String? tagline,
    required String? originalPrice,
    required String promoPrice,
    required String priceNote,
    required String? promoNote,
    required String ctaText,
    required Color ctaColor,
    required List<String> features,
    required bool isPopular,
  }) {
    final selected = _selectedTier == index;

    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedTier = index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: selected
                  ? DesignTokens.bgCard
                  : DesignTokens.bgSecondary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? (isPopular
                          ? DesignTokens.neonGreen.withValues(
                              alpha: _glow.value,
                            )
                          : DesignTokens.neonCyan.withValues(alpha: 0.4))
                    : Colors.white.withValues(alpha: 0.06),
                width: selected ? 1.5 : 1,
              ),
              boxShadow: selected && isPopular
                  ? [
                      BoxShadow(
                        color: DesignTokens.neonGreen.withValues(
                          alpha: _glow.value * 0.15,
                        ),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag line
                if (tagline != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isPopular
                          ? DesignTokens.neonGreen.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tagline,
                      style: TextStyle(
                        color: isPopular
                            ? DesignTokens.neonGreen
                            : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                // Plan name
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),

                // Pricing row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (originalPrice != null) ...[
                      Text(
                        originalPrice,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 16,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      promoPrice,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        priceNote,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                if (promoNote != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    promoNote,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // CTA button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      if (index == 0) {
                        // Basic = free, just navigate home
                        if (mounted) context.go(rc.RouteConstants.root);
                        return;
                      }
                      final tier = index == 2 ? 'promoter' : 'fighter pro';
                      final link = DfcStripeLinks.subscriptionLink(tier);
                      if (link != null) {
                        final opened = await DfcStripeLinks.openPaymentLink(
                          link,
                        );
                        if (!opened && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not open checkout. Try again.',
                              ),
                              backgroundColor: DesignTokens.bgCard,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ctaColor == Colors.white
                          ? Colors.white
                          : ctaColor == Colors.grey
                          ? Colors.white.withValues(alpha: 0.1)
                          : ctaColor,
                      foregroundColor: ctaColor == Colors.white
                          ? Colors.black
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      ctaText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Features
                ...features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: isPopular
                              ? DesignTokens.neonGreen
                              : DesignTokens.neonCyan.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            f,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
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
        );
      },
    );
  }

  // ── Feature Comparison Table ──
  SliverToBoxAdapter _buildFeatureComparison() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "What's Included",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _comparisonRow('Watch live events & on-demand', false, true, true),
            _comparisonRow(
              'Watch NRL, AFL, Boxing, MMA content',
              false,
              true,
              true,
            ),
            _comparisonRow('Live in 4K on Kayo Premium*', false, false, true),
            _comparisonRow('Multi-camera fight angles', false, false, true),
            _comparisonRow('PPV events included', false, false, true),
            _comparisonRow('Fighter stats & profiles', true, true, true),
            _comparisonRow('Community & social feed', true, true, true),
            _comparisonRow('News & highlights', true, true, true),
          ],
        ),
      ),
    );
  }

  Widget _comparisonRow(
    String feature,
    bool basic,
    bool standard,
    bool premium,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              feature,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(child: _checkIcon(basic)),
          Expanded(child: _checkIcon(standard)),
          Expanded(child: _checkIcon(premium)),
        ],
      ),
    );
  }

  Widget _checkIcon(bool included) {
    return Center(
      child: Icon(
        included ? Icons.check : Icons.close,
        size: 16,
        color: included
            ? DesignTokens.neonGreen
            : Colors.white.withValues(alpha: 0.15),
      ),
    );
  }

  // ── Sport Logos Grid (like Kayo shows AFL, UFC, BBL logos) ──
  SliverToBoxAdapter _buildSportLogos() {
    const sports = [
      {'name': 'UFC', 'icon': Icons.sports_mma},
      {'name': 'Boxing', 'icon': Icons.sports_kabaddi},
      {'name': 'BKFC', 'icon': Icons.front_hand},
      {'name': 'MMA', 'icon': Icons.sports_martial_arts},
      {'name': 'Muay Thai', 'icon': Icons.sports},
      {'name': 'Kickboxing', 'icon': Icons.sports_kabaddi},
      {'name': 'Wrestling', 'icon': Icons.sports},
      {'name': 'BJJ', 'icon': Icons.self_improvement},
      {'name': 'K-1', 'icon': Icons.flash_on},
      {'name': 'ONE FC', 'icon': Icons.looks_one},
      {'name': 'Bellator', 'icon': Icons.military_tech},
      {'name': 'RIZIN', 'icon': Icons.auto_awesome},
    ];

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stream Combat Sports',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'All your favourite promotions in one place',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: sports.length,
              itemBuilder: (context, index) {
                final sport = sports[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        sport['icon'] as IconData,
                        color: DesignTokens.neonCyan.withValues(alpha: 0.7),
                        size: 24,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sport['name'] as String,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── FAQ Section ──
  SliverToBoxAdapter _buildFAQ() {
    final faqs = [
      {
        'q': 'Can I cancel anytime?',
        'a':
            'Yes. No lock-in contract. Cancel anytime from your account settings.',
      },
      {
        'q': 'Are PPV events included?',
        'a':
            'Premium subscribers get all PPV events at no extra cost. Standard subscribers get a discounted PPV rate.',
      },
      {
        'q': 'What devices can I watch on?',
        'a':
            'DFC works on iPhone, iPad, Android, Web, Smart TVs, and desktop. Premium supports 2 simultaneous screens.',
      },
      {
        'q': 'How does the \$1 first month work?',
        'a':
            'New Premium subscribers pay just \$1 for the first month. After that, it renews at \$24.99/month AUD.',
      },
    ];

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            ...faqs.map((faq) => _buildFAQItem(faq['q']!, faq['a']!)),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      iconColor: DesignTokens.neonCyan,
      collapsedIconColor: Colors.white38,
      title: Text(
        question,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Text(
          answer,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
