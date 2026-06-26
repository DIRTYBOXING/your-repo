import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Fighter Pro Pricing Screen — Tiered membership with free 1-week trial.
class FighterProPricingScreen extends StatefulWidget {
  const FighterProPricingScreen({super.key});

  @override
  State<FighterProPricingScreen> createState() =>
      _FighterProPricingScreenState();
}

class _FighterProPricingScreenState extends State<FighterProPricingScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTier = 1; // default: Pro
  late AnimationController _glowCtrl;

  static const _pink = Color(0xFFFF69B4);
  static const _gold = Color(0xFFFFD700);
  static const _cyan = Color(0xFF00E5FF);
  static const _bg = Color(0xFF0A0A12);

  static const _tiers = [
    _PricingTier(
      label: 'STARTER',
      price: 0,
      period: 'Free',
      color: Color(0xFF00E676),
      icon: Icons.sports_mma,
      badge: null,
      features: [
        '✅ DFC Community Access',
        '✅ Regional Fight Feed',
        '✅ Event Listings (public)',
        '✅ Basic Fighter Profile',
        '❌ PPV Access',
        '❌ Mentor Matching',
        '❌ Advanced Analytics',
        '❌ Gold Coin Rewards',
      ],
    ),
    _PricingTier(
      label: 'PRO',
      price: 1499,
      period: 'per month',
      color: Color(0xFF00E5FF),
      icon: Icons.workspace_premium,
      badge: 'MOST POPULAR',
      features: [
        '✅ Everything in Starter',
        '✅ PPV Purchase Access',
        '✅ Full Fighter Analytics',
        '✅ Mentor Discovery Map',
        '✅ Gold Coin Rewards (500/mo)',
        '✅ Priority Event Alerts',
        '✅ Verified Fighter Badge',
        '❌ Pink Diamond Mentorship',
      ],
    ),
    _PricingTier(
      label: 'PINK DIAMOND',
      price: 4999,
      period: 'per month',
      color: Color(0xFFFF69B4),
      icon: Icons.diamond,
      badge: 'ELITE',
      features: [
        '✅ Everything in Pro',
        '✅ Pink Diamond Mentor Access',
        '✅ Gold Coin Rewards (2000/mo)',
        '✅ Live Event Priority Seating',
        '✅ 1-on-1 Coach Messaging',
        '✅ Performance AI Deep Dive',
        '✅ Campaign Sponsorship Visibility',
        '✅ DFC Hall of Fame Nomination',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'DFC MEMBERSHIP',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, _) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.diamond,
                color: _pink.withValues(alpha: 0.5 + _glowCtrl.value * 0.5),
                size: 22,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── FREE TRIAL HERO ───────────────────────────────────────
            _buildTrialHero(),
            const SizedBox(height: 28),

            // ── TIER SELECTOR ─────────────────────────────────────────
            Row(
              children: List.generate(_tiers.length, (i) {
                final t = _tiers[i];
                final isSelected = i == _selectedTier;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTier = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? t.color.withValues(alpha: 0.15)
                            : const Color(0xFF12121A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? t.color
                              : Colors.white.withValues(alpha: 0.08),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(t.icon, color: t.color, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            t.label,
                            style: TextStyle(
                              color: t.color,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // ── SELECTED TIER CARD ────────────────────────────────────
            _buildTierCard(_tiers[_selectedTier], _selectedTier),
            const SizedBox(height: 20),

            // ── FEATURE COMPARISON TABLE ──────────────────────────────
            _buildFeatureList(_tiers[_selectedTier]),
            const SizedBox(height: 24),

            // ── CTA BUTTONS ───────────────────────────────────────────
            _buildCTAButtons(_tiers[_selectedTier]),
            const SizedBox(height: 16),

            // ── TRUST SIGNALS ─────────────────────────────────────────
            _buildTrustRow(),
            const SizedBox(height: 28),

            // ── GYM TRIAL OFFER ───────────────────────────────────────
            _buildGymTrialBanner(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTrialHero() {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, _) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _pink.withValues(alpha: 0.18),
              _gold.withValues(alpha: 0.08),
              _cyan.withValues(alpha: 0.12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _pink.withValues(alpha: 0.25 + _glowCtrl.value * 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _pink.withValues(alpha: 0.08 + _glowCtrl.value * 0.06),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.celebration,
                  color: _gold.withValues(alpha: 0.9),
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Text(
                  'FREE 1-WEEK TRIAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.celebration,
                  color: _gold.withValues(alpha: 0.9),
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Try any paid tier free for 7 days. No credit card required.\nCancel anytime before your trial ends.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _trialChip(Icons.shield, 'Pink Shield Access', _pink),
                _trialChip(Icons.monetization_on, 'Gold Coins Included', _gold),
                _trialChip(Icons.fitness_center, 'Gym Finder Unlocked', _cyan),
                _trialChip(Icons.diamond, 'Mentor Map Access', _pink),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _trialChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard(_PricingTier tier, int index) {
    final isMonthly = tier.price > 0;
    final badgeColor = index == 2
        ? _pink
        : (index == 1 ? _cyan : const Color(0xFF00E676));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tier.color.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: tier.color.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(tier.icon, color: tier.color, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tier.label,
                    style: TextStyle(
                      color: tier.color,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (tier.badge != null)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        tier.badge!,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isMonthly)
                    Text(
                      '\$${(tier.price / 100).toStringAsFixed(0)}',
                      style: TextStyle(
                        color: tier.color,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  else
                    Text(
                      'FREE',
                      style: TextStyle(
                        color: tier.color,
                        fontSize: 28,
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
          if (isMonthly) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _gold.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.celebration, color: _gold, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '7-day FREE trial included — no payment today',
                    style: TextStyle(
                      color: _gold.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureList(_PricingTier tier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "WHAT'S INCLUDED",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ...tier.features.map(
            (f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                f,
                style: TextStyle(
                  color: f.startsWith('✅')
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.3),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTAButtons(_PricingTier tier) {
    final isFree = tier.price == 0;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleTrialSignup(tier),
            icon: Icon(isFree ? Icons.rocket_launch : Icons.celebration),
            label: Text(
              isFree ? 'GET STARTED FREE' : 'START FREE 7-DAY TRIAL',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: tier.color,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        if (!isFree) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _handleDirectSubscribe(tier),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white54,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'SUBSCRIBE NOW (\$${(tier.price / 100).toStringAsFixed(0)}/mo)',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrustRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _trustItem(Icons.lock_outline, 'Secure\nPayment'),
        _trustItem(Icons.cancel_outlined, 'Cancel\nAnytime'),
        _trustItem(Icons.support_agent, '24/7\nSupport'),
        _trustItem(Icons.verified_user_outlined, 'No Hidden\nFees'),
      ],
    );
  }

  Widget _trustItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white38, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white30,
            fontSize: 10,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildGymTrialBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1A1A2E), _cyan.withValues(alpha: 0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cyan.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _cyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: Color(0xFF00E5FF),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GYM FINDER — FREE WEEK TRAINING',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Any verified gym on the DFC map offers a complimentary first-week trial for DFC members. Find your nearest gym and book through the map.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () => context.push('/map'),
            style: TextButton.styleFrom(
              foregroundColor: _cyan,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map, size: 18),
                SizedBox(height: 2),
                Text(
                  'FIND GYM',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleTrialSignup(_PricingTier tier) {
    if (tier.price == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Welcome to DFC Starter — you\'re all set!'),
          backgroundColor: const Color(0xFF00E676),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12121A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _TrialConfirmSheet(tier: tier),
    );
  }

  void _handleDirectSubscribe(_PricingTier tier) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Subscribing to ${tier.label}...'),
        backgroundColor: tier.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ── Trial Confirm Bottom Sheet ──────────────────────────────────────────────

class _TrialConfirmSheet extends StatelessWidget {
  final _PricingTier tier;
  const _TrialConfirmSheet({required this.tier});

  static const _gold = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Icon(Icons.celebration, color: _gold, size: 36),
          const SizedBox(height: 12),
          Text(
            'Start Your 7-Day Free Trial',
            style: TextStyle(
              color: tier.color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll get full ${tier.label} access for 7 days, completely free.\nYour card will only be charged after the trial ends.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '🎉 ${tier.label} trial started! Enjoy 7 days free.',
                    ),
                    backgroundColor: tier.color,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: tier.color,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'CONFIRM — START FREE TRIAL',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Maybe later',
              style: TextStyle(color: Colors.white38),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data classes ────────────────────────────────────────────────────────────

class _PricingTier {
  final String label;
  final int price; // cents
  final String period;
  final Color color;
  final IconData icon;
  final String? badge;
  final List<String> features;

  const _PricingTier({
    required this.label,
    required this.price,
    required this.period,
    required this.color,
    required this.icon,
    required this.badge,
    required this.features,
  });
}
