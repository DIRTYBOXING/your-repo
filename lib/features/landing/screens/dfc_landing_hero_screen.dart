import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/router_config.dart' as rc;
import '../../../core/constants/app_constants.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DFC LANDING HERO — "Faster Highlights, Fairer Pay"
// Hero CTA · Trust badges · Feature bullets · Partner application
// ═══════════════════════════════════════════════════════════════════════════════

const _cyan = Color(0xFF00F5FF);
const _magenta = Color(0xFFFF00FF);
const _green = Color(0xFF00FF88);
const _amber = Color(0xFFFFB800);
const _red = Color(0xFFFF3366);
const _gold = Color(0xFFFFD700);
const _bg = Color(0xFF050A14);
const _panel = Color(0xFF0D1B2A);
const _surface = Color(0xFF142236);
const _border = Color(0xFF1A2744);

class DfcLandingHeroScreen extends StatefulWidget {
  const DfcLandingHeroScreen({super.key});
  @override
  State<DfcLandingHeroScreen> createState() => _DfcLandingHeroScreenState();
}

class _DfcLandingHeroScreenState extends State<DfcLandingHeroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _openPartnerFlow() {
    context.goNamed(rc.RouteConstants.roleSelection);
  }

  void _openWatchFlow() {
    if (AppConstants.authEnabled) {
      context.goNamed(rc.RouteConstants.login);
      return;
    }
    context.goNamed(rc.RouteConstants.ppvHub);
  }

  void _openHowItWorks() {
    context.go('/how-we-work');
  }

  void _openPricingFlow(String tier) {
    switch (tier) {
      case 'Free':
        _openWatchFlow();
        break;
      case 'Partner':
      case 'Enterprise':
        _openPartnerFlow();
        break;
    }
  }

  String _pricingButtonLabel(String tier) {
    switch (tier) {
      case 'Free':
        return 'EXPLORE PLATFORM';
      case 'Partner':
        return 'START PROMOTER FLOW';
      case 'Enterprise':
        return 'START INTAKE';
      default:
        return 'GET STARTED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;
    final isMedium = screenWidth > 600;
    return Scaffold(
      backgroundColor: _bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(isWide, isMedium),
            _buildTrustBar(),
            _buildFeatureGrid(isWide),
            _buildStatsStrip(),
            _buildPricingSection(isWide),
            _buildPartnerCTA(isWide),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HERO SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeroSection(bool isWide, bool isMedium) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isWide
            ? 80
            : isMedium
            ? 40
            : 20,
        vertical: isWide ? 80 : 48,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_bg, _panel, _magenta.withValues(alpha: 0.06)],
        ),
      ),
      child: isWide
          ? Row(
              children: [
                Expanded(flex: 3, child: _heroText(isWide)),
                const SizedBox(width: 48),
                Expanded(flex: 2, child: _heroVisual()),
              ],
            )
          : Column(
              children: [
                _heroText(isWide),
                const SizedBox(height: 32),
                _heroVisual(),
              ],
            ),
    );
  }

  Widget _heroText(bool isWide) {
    return Column(
      crossAxisAlignment: isWide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        // Tagline badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _gold.withValues(alpha: 0.4)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flash_on, color: _gold, size: 14),
              SizedBox(width: 4),
              Text(
                'THE COMBAT SPORTS PLATFORM',
                style: TextStyle(
                  color: _gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Headline
        Text(
          'Faster Highlights.\nFairer Pay.',
          style: TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: isWide ? 52 : 36,
            fontWeight: FontWeight.w900,
            height: 1.1,
            color: Colors.white,
          ),
          textAlign: isWide ? TextAlign.left : TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Subheadline
        Text(
          'DFC delivers fight highlights in under 120 seconds, pays promoters 80% of revenue, and gives fighters a guaranteed 15% pool. No middlemen. No delays.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: isWide ? 18 : 15,
            height: 1.5,
          ),
          textAlign: isWide ? TextAlign.left : TextAlign.center,
        ),
        const SizedBox(height: 28),
        // CTA buttons
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: isWide ? WrapAlignment.start : WrapAlignment.center,
          children: [
            _ctaButton(
              'APPLY TO PARTNER',
              _magenta,
              Icons.handshake,
              true,
              _openPartnerFlow,
            ),
            _ctaButton(
              'WATCH SINGLE FIGHT',
              _cyan,
              Icons.play_circle_fill,
              false,
              _openWatchFlow,
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Sub-CTA text
        Text(
          'No credit card required · First event free · Cancel anytime',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 12,
          ),
          textAlign: isWide ? TextAlign.left : TextAlign.center,
        ),
      ],
    );
  }

  Widget _heroVisual() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnim.value,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _magenta.withValues(alpha: 0.2),
                  _cyan.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
              border: Border.all(color: _cyan.withValues(alpha: 0.2), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_mma,
                  color: _cyan.withValues(alpha: 0.8),
                  size: 64,
                ),
                const SizedBox(height: 12),
                const Text(
                  'DFC',
                  style: TextStyle(
                    color: _gold,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                    fontFamily: 'Segoe UI',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'DATA FIGHT CENTRAL',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _ctaButton(
    String label,
    Color color,
    IconData icon,
    bool filled,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: filled ? 0 : 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: filled ? Colors.white : color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TRUST BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTrustBar() {
    final badges = [
      ('MMA', Icons.sports_mma),
      ('BKFC', Icons.sports_kabaddi),
      ('Boxing', Icons.sports_handball),
      ('Kickboxing', Icons.sports_martial_arts),
      ('Bare Knuckle', Icons.front_hand),
      ('Muay Thai', Icons.sports),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: _panel,
        border: Border(
          top: BorderSide(color: _border),
          bottom: BorderSide(color: _border),
        ),
      ),
      child: Column(
        children: [
          Text(
            'TRUSTED BY PROMOTERS ACROSS EVERY COMBAT DISCIPLINE',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: badges
                  .map(
                    (b) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            b.$2,
                            color: _cyan.withValues(alpha: 0.5),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            b.$1,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FEATURE GRID
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFeatureGrid(bool isWide) {
    final features = <_Feature>[
      _Feature(
        'Sub-120s Highlights',
        'AI clips and publishes fight highlights in under 2 minutes. No manual editing needed.',
        Icons.speed,
        _cyan,
      ),
      _Feature(
        '80/15/5 Revenue Split',
        'Promoters keep 80%. Fighters get a guaranteed 15% pool. Platform takes just 5%.',
        Icons.pie_chart,
        _green,
      ),
      _Feature(
        'Instant Cashout',
        'Stripe Connect payouts with instant cashout option. Weekly settlements by default.',
        Icons.flash_on,
        _amber,
      ),
      _Feature(
        'AI Moderation',
        '250+ pattern NLP moderation with human-in-the-loop escalation. Zero tolerance for unsafe content.',
        Icons.shield,
        _magenta,
      ),
      _Feature(
        'Multi-Discipline',
        'MMA, Boxing, BKFC, Bare Knuckle, Kickboxing, Muay Thai, Brawling — all under one roof.',
        Icons.sports_mma,
        _gold,
      ),
      _Feature(
        'Promo Code Engine',
        'Create codes, track redemptions, manage affiliates, and measure conversion in real time.',
        Icons.confirmation_number,
        _red,
      ),
    ];
    final crossCount = isWide ? 3 : 2;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 20, vertical: 48),
      child: Column(
        children: [
          const Text(
            'BUILT FOR COMBAT SPORTS',
            style: TextStyle(
              color: _gold,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Everything you need to run, promote, and monetize fights',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: isWide ? 1.8 : 1.4,
            ),
            itemCount: features.length,
            itemBuilder: (ctx, i) => _featureCard(features[i]),
          ),
        ],
      ),
    );
  }

  Widget _featureCard(_Feature f) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: f.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: f.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(f.icon, color: f.color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            f.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            f.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATS STRIP
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsStrip() {
    final stats = [
      ('120s', 'Avg Highlight Time', _cyan),
      ('80%', 'Promoter Revenue Share', _green),
      ('250+', 'Moderation Patterns', _magenta),
      ('0.2%', 'Dispute Rate', _gold),
      ('3.2d', 'Avg Payout Speed', _amber),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(
          top: BorderSide(color: _border),
          bottom: BorderSide(color: _border),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: stats
              .map(
                (s) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        s.$1,
                        style: TextStyle(
                          color: s.$3,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Segoe UI',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.$2,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRICING SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPricingSection(bool isWide) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 20, vertical: 48),
      child: Column(
        children: [
          const Text(
            'SIMPLE PRICING',
            style: TextStyle(
              color: _gold,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pay nothing until you earn',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          isWide
              ? Row(
                  children: [
                    Expanded(
                      child: _pricingCard(
                        'Free',
                        '\$0',
                        'Perfect for getting started',
                        [
                          '1 event per month',
                          'Standard highlights (5 min)',
                          'Basic analytics',
                          'Community support',
                        ],
                        _cyan,
                        false,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _pricingCard(
                        'Partner',
                        '5%',
                        'For serious promoters',
                        [
                          'Unlimited events',
                          'Sub-120s highlights',
                          'Full analytics dashboard',
                          'Priority support',
                          'Promo code engine',
                          'Instant cashout',
                        ],
                        _gold,
                        true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _pricingCard(
                        'Enterprise',
                        'Custom',
                        'Multi-venue operations',
                        [
                          'Everything in Partner',
                          'White-label option',
                          'Dedicated account manager',
                          'Custom split ratios',
                          'API access',
                          'SLA guarantee',
                        ],
                        _magenta,
                        false,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _pricingCard(
                      'Free',
                      '\$0',
                      'Perfect for getting started',
                      ['1 event/mo', 'Standard highlights', 'Basic analytics'],
                      _cyan,
                      false,
                    ),
                    const SizedBox(height: 16),
                    _pricingCard(
                      'Partner',
                      '5%',
                      'For serious promoters',
                      [
                        'Unlimited events',
                        'Sub-120s highlights',
                        'Full analytics',
                        'Promo codes',
                        'Instant cashout',
                      ],
                      _gold,
                      true,
                    ),
                    const SizedBox(height: 16),
                    _pricingCard(
                      'Enterprise',
                      'Custom',
                      'Multi-venue operations',
                      [
                        'Everything in Partner',
                        'White-label',
                        'Dedicated support',
                        'API access',
                      ],
                      _magenta,
                      false,
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _pricingCard(
    String tier,
    String price,
    String subtitle,
    List<String> features,
    Color color,
    bool featured,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: featured ? color.withValues(alpha: 0.08) : _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: featured ? color : _border,
          width: featured ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (featured)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'MOST POPULAR',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          Text(
            tier,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
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
            child: ElevatedButton(
              onPressed: () => _openPricingFlow(tier),
              style: ElevatedButton.styleFrom(
                backgroundColor: featured ? color : _surface,
                foregroundColor: featured ? Colors.black : color,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _pricingButtonLabel(tier),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PARTNER CTA
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPartnerCTA(bool isWide) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: isWide ? 80 : 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _magenta.withValues(alpha: 0.15),
            _cyan.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _magenta.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.handshake, color: _gold, size: 40),
          const SizedBox(height: 12),
          Text(
            'Ready to partner with the future of fight media?',
            style: TextStyle(
              color: Colors.white,
              fontSize: isWide ? 24 : 18,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Apply now and run your first event on DFC within 48 hours.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _ctaButton(
            'APPLY TO PARTNER',
            _magenta,
            Icons.arrow_forward,
            true,
            _openPartnerFlow,
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withValues(alpha: 0.7),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FOOTER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      margin: const EdgeInsets.only(top: 48),
      decoration: const BoxDecoration(
        color: _panel,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Column(
        children: [
          const Text(
            'DATA FIGHT CENTRAL',
            style: TextStyle(
              color: _gold,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '© 2026 Data Fight Central. All rights reserved.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              _footerLink('WATCH FIGHTS', _openWatchFlow),
              _footerLink('BECOME A PROMOTER', _openPartnerFlow),
              _footerLink('HOW IT WORKS', _openHowItWorks),
              _footerLink(
                'SIGN IN',
                () => context.goNamed(rc.RouteConstants.login),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'MMA · Boxing · BKFC · Bare Knuckle · Kickboxing · Muay Thai · Brawling',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Data models
// ═══════════════════════════════════════════════════════════════════════════════
class _Feature {
  final String title, description;
  final IconData icon;
  final Color color;
  _Feature(this.title, this.description, this.icon, this.color);
}
