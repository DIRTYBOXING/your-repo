import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/pricing_engine.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/payments_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC ACCESS PASS - Subscription Tier Screen
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Three tiers:
///   🟦 FREE ACCESS     — Basic community features
///   🟩 FIGHTER PRO     — Full training + intelligence + marketplace
///   🟥 PROMOTER CMD    — Everything + event management + analytics
///
/// Battle Pass style with neon glow hover, glass panels
/// ═══════════════════════════════════════════════════════════════════════════

class DFCAccessPassScreen extends StatefulWidget {
  const DFCAccessPassScreen({super.key});

  @override
  State<DFCAccessPassScreen> createState() => _DFCAccessPassScreenState();
}

class _DFCAccessPassScreenState extends State<DFCAccessPassScreen>
    with TickerProviderStateMixin {
  int _selectedTier = 1; // 0=Free, 1=Fighter Pro, 2=Promoter Command
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  final PaymentsService _paymentsService = PaymentsService();

  String _countryCode = 'US';
  LoyaltyStatus _loyalty = DfcPricingEngine.loyaltyFor(null);

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _resolveRegionalContext();
  }

  void _resolveRegionalContext() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final cc = (locale.countryCode?.isNotEmpty == true)
        ? locale.countryCode!
        : 'US';
    final user = FirebaseAuth.instance.currentUser;
    final memberSince = user?.metadata.creationTime;
    setState(() {
      _countryCode = cc;
      _loyalty = DfcPricingEngine.loyaltyFor(memberSince);
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              children: [
                Row(
                  children: [
                    Tooltip(
                      message: 'Back to Dashboard with DFC Command drawer open',
                      child: IconButton(
                        onPressed: _goBackToDashboardDrawer,
                        icon: const Icon(
                          Icons.arrow_back,
                          color: DesignTokens.textPrimary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Tooltip(
                      message:
                          'Access Pass Guide: Choose a tier to unlock tools.\n'
                          'FREE = basics, FIGHTER PRO = performance stack,\n'
                          'PROMOTER CMD = full event + growth tools.',
                      child: IconButton(
                        onPressed: _showAccessPassGuide,
                        icon: const Icon(
                          Icons.help_outline,
                          color: DesignTokens.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spacingXL),
                // Logo / Title
                _buildHeader(),
                const SizedBox(height: DesignTokens.spacingXXL),
                // Tier selector
                _buildTierSelector(),
                const SizedBox(height: DesignTokens.spacingL),
                // Loyalty banner (hidden for new members)
                _buildLoyaltyBanner(),
                // Selected tier detail card
                _buildTierDetail(),
                const SizedBox(height: DesignTokens.spacingXL),
                // Feature comparison
                _buildFeatureComparison(),
                const SizedBox(height: DesignTokens.spacingXXL),
                // CTA
                _buildCTA(),
                const SizedBox(height: DesignTokens.spacingXXL),
                // FAQ
                _buildFAQ(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goBackToDashboardDrawer() {
    context.go('/home?tab=0&drawer=1');
  }

  void _showAccessPassGuide() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0E1A),
        title: const Text(
          'Access Pass Guide',
          style: TextStyle(color: DesignTokens.textPrimary),
        ),
        content: const Text(
          'Free Access: core community tools.\n\n'
          'Fighter Pro: advanced training, analytics, and career tools.\n\n'
          'Promoter Command: full event operations, growth stack, and promotion tools.',
          style: TextStyle(color: DesignTokens.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        // DFC Logo glow
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DesignTokens.neonCyan.withValues(
                      alpha: 0.3 * _glowAnimation.value,
                    ),
                    DesignTokens.neonMagenta.withValues(
                      alpha: 0.1 * _glowAnimation.value,
                    ),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: DesignTokens.neonCyan.withValues(
                      alpha: 0.2 * _glowAnimation.value,
                    ),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'DFC',
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: DesignTokens.spacingL),
        const Text(
          'ACCESS PASS',
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 6,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        const Text(
          'Choose your level. Unlock professional social and PPV tools.',
          style: TextStyle(
            color: DesignTokens.textMuted,
            fontSize: DesignTokens.fontSizeBody,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TIER SELECTOR (3 Cards)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTierSelector() {
    return Row(
      children: [
        Expanded(child: _buildTierCard(0)),
        const SizedBox(width: DesignTokens.spacingS),
        Expanded(child: _buildTierCard(1)),
        const SizedBox(width: DesignTokens.spacingS),
        Expanded(child: _buildTierCard(2)),
      ],
    );
  }

  Widget _buildTierCard(int tier) {
    final isSelected = _selectedTier == tier;
    final tierData = _tiers[tier];

    return GestureDetector(
      onTap: () => setState(() => _selectedTier = tier),
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return AnimatedContainer(
            duration: DesignTokens.animNormal,
            curve: DesignTokens.animCurve,
            padding: const EdgeInsets.all(DesignTokens.cardPaddingSmall),
            decoration: BoxDecoration(
              color: isSelected
                  ? tierData.color.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: DesignTokens.glassOpacity),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              border: Border.all(
                color: isSelected
                    ? tierData.color.withValues(
                        alpha: 0.5 * _glowAnimation.value,
                      )
                    : DesignTokens.borderSubtle,
                width: isSelected
                    ? DesignTokens.borderThick
                    : DesignTokens.borderThin,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: tierData.color.withValues(
                          alpha: 0.15 * _glowAnimation.value,
                        ),
                        blurRadius: DesignTokens.glowRadius,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tier icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tierData.color.withValues(
                      alpha: isSelected ? 0.2 : 0.08,
                    ),
                  ),
                  child: Icon(tierData.icon, color: tierData.color, size: 20),
                ),
                const SizedBox(height: DesignTokens.spacingS),
                Text(
                  tierData.name,
                  style: TextStyle(
                    color: isSelected
                        ? tierData.color
                        : DesignTokens.textSecondary,
                    fontSize: DesignTokens.fontSizeCaption,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                _buildTierCardPrice(tier, isSelected),
              ],
            ),
          );
        },
      ),
    );
  }

  // Compact per-tier price widget used inside the small selector cards
  Widget _buildTierCardPrice(int tierIndex, bool isSelected) {
    if (tierIndex == 0) {
      return Text(
        'FREE',
        style: TextStyle(
          color: isSelected ? DesignTokens.textPrimary : DesignTokens.textMuted,
          fontSize: DesignTokens.fontSizeStatSmall,
          fontWeight: DesignTokens.fontWeightStat,
        ),
      );
    }
    final prodKey = tierIndex == 1 ? 'fighter_pro' : 'promoter_cmd';
    final regional = DfcPricingEngine.priceFor(
      productKey: prodKey,
      countryCode: _countryCode,
    );
    final baseUsd = regional.usd;
    final effectiveUsd = _loyalty.hasDiscount
        ? DfcPricingEngine.applyLoyaltyDiscount(baseUsd, _loyalty.discountPct)
        : baseUsd;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_loyalty.hasDiscount) ...[
          Text(
            '\$${baseUsd.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFF555555),
              fontSize: 9,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          Text(
            '\$${effectiveUsd.toStringAsFixed(2)}',
            style: TextStyle(
              color: isSelected
                  ? DesignTokens.neonGreen
                  : DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeStatSmall,
              fontWeight: DesignTokens.fontWeightStat,
            ),
          ),
        ] else
          Text(
            regional.display,
            style: TextStyle(
              color: isSelected
                  ? DesignTokens.textPrimary
                  : DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeStatSmall,
              fontWeight: DesignTokens.fontWeightStat,
            ),
          ),
        const Text(
          '/mo',
          style: TextStyle(
            color: DesignTokens.textMuted,
            fontSize: DesignTokens.fontSizeMicro,
          ),
        ),
      ],
    );
  }

  // Loyalty banner shown between tier selector and detail card
  Widget _buildLoyaltyBanner() {
    if (!_loyalty.hasDiscount) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingL),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _loyalty.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: _loyalty.color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Text(_loyalty.badge, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _loyalty.label.toUpperCase(),
                  style: TextStyle(
                    color: _loyalty.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  '${_loyalty.discountLabel} applied · ${_loyalty.monthsActive} months with DFC',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _loyalty.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _loyalty.discountLabel,
              style: TextStyle(
                color: _loyalty.color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TIER DETAIL CARD
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTierDetail() {
    final tier = _tiers[_selectedTier];

    return AnimatedSwitcher(
      duration: DesignTokens.animNormal,
      child: Container(
        key: ValueKey(_selectedTier),
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.cardPaddingLarge),
        decoration: BoxDecoration(
          color: tier.color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          border: Border.all(
            color: tier.color.withValues(
              alpha: DesignTokens.glassBorderOpacity,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tier header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(tier.icon, color: tier.color, size: 28),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier.fullName,
                        style: TextStyle(
                          color: tier.color,
                          fontSize: DesignTokens.fontSizeTitleLarge,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        tier.tagline,
                        style: const TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: DesignTokens.fontSizeSubtitle,
                        ),
                      ),
                    ],
                  ),
                ),
                // Regional price block (non-free tiers only)
                if (_selectedTier != 0) _buildDetailPriceBlock(tier.color),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingL),

            // Benefits list
            ...tier.benefits.map(
              (benefit) => Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.spacingS),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: tier.color),
                    const SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: Text(
                        benefit,
                        style: const TextStyle(
                          color: DesignTokens.textSecondary,
                          fontSize: DesignTokens.fontSizeBody,
                          height: 1.3,
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
  }

  // Price block shown top-right of the detail card
  Widget _buildDetailPriceBlock(Color accentColor) {
    final prodKey = _selectedTier == 1 ? 'fighter_pro' : 'promoter_cmd';
    final regional = DfcPricingEngine.priceFor(
      productKey: prodKey,
      countryCode: _countryCode,
    );
    final baseUsd = regional.usd;
    final effectiveUsd = _loyalty.hasDiscount
        ? DfcPricingEngine.applyLoyaltyDiscount(baseUsd, _loyalty.discountPct)
        : baseUsd;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_loyalty.hasDiscount)
            Text(
              '\$${baseUsd.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 10,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          Text(
            '\$${effectiveUsd.toStringAsFixed(2)}/mo',
            style: TextStyle(
              color: _loyalty.hasDiscount
                  ? DesignTokens.neonGreen
                  : accentColor,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (regional.localDisplay != null)
            Text(
              regional.localDisplay!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 10,
              ),
            ),
          Text(
            DfcPricingEngine.regionLabel(_countryCode),
            style: TextStyle(
              color: accentColor.withValues(alpha: 0.6),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FEATURE COMPARISON TABLE
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildFeatureComparison() {
    final features = _comparisonFeatures;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.borderSubtle,
          width: DesignTokens.borderThin,
        ),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.cardPaddingMedium,
              vertical: DesignTokens.spacingM,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(DesignTokens.radiusMedium),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'FEATURE',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeMicro,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                ...List.generate(3, (i) {
                  final tier = _tiers[i];
                  return Expanded(
                    flex: 2,
                    child: Text(
                      tier.shortName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: tier.color,
                        fontSize: DesignTokens.fontSizeMicro,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          // Feature rows
          ...features.asMap().entries.map((entry) {
            final i = entry.key;
            final feature = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.cardPaddingMedium,
                vertical: 10,
              ),
              color: i.isEven
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.02),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      feature.name,
                      style: const TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: DesignTokens.fontSizeCaption,
                      ),
                    ),
                  ),
                  Expanded(flex: 2, child: _buildFeatureCheck(feature.free)),
                  Expanded(flex: 2, child: _buildFeatureCheck(feature.pro)),
                  Expanded(flex: 2, child: _buildFeatureCheck(feature.command)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFeatureCheck(String value) {
    if (value == '✓') {
      return const Icon(
        Icons.check_circle,
        size: 16,
        color: DesignTokens.success,
      );
    }
    if (value == '—') {
      return const Icon(
        Icons.remove_circle_outline,
        size: 16,
        color: DesignTokens.textDisabled,
      );
    }
    return Text(
      value,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: DesignTokens.textSecondary,
        fontSize: DesignTokens.fontSizeMicro,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // Small price line rendered inside the CTA button
  Widget _buildCtaPriceLine() {
    if (_selectedTier == 0) return const SizedBox.shrink();
    final prodKey = _selectedTier == 1 ? 'fighter_pro' : 'promoter_cmd';
    final regional = DfcPricingEngine.priceFor(
      productKey: prodKey,
      countryCode: _countryCode,
    );
    final effectiveUsd = _loyalty.hasDiscount
        ? DfcPricingEngine.applyLoyaltyDiscount(
            regional.usd,
            _loyalty.discountPct,
          )
        : regional.usd;
    final parts = [
      '\$${effectiveUsd.toStringAsFixed(2)}/month',
      if (regional.localDisplay != null) regional.localDisplay!,
      if (_loyalty.hasDiscount) _loyalty.discountLabel,
    ];
    return Text(
      parts.join(' · '),
      style: TextStyle(
        color: Colors.black.withValues(alpha: 0.65),
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CTA BUTTON
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _handleCheckoutTap() async {
    if (_selectedTier == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Free tier activated.')));
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to start secure checkout.')),
      );
      return;
    }

    final locale = Localizations.localeOf(context);
    final countryCode = _countryCode.isNotEmpty
        ? _countryCode
        : (locale.countryCode ?? 'US');
    final opened = await _paymentsService.openGlobalSubscriptionCheckout(
      userId: userId,
      tier: _selectedTier == 1 ? 'fighter' : 'promoter',
      billingCycle: 'monthly',
      countryCode: countryCode,
      isMobile: MediaQuery.of(context).size.width < 900,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          opened
              ? 'Opening secure checkout...'
              : (_paymentsService.error ?? 'Could not open checkout.'),
        ),
      ),
    );
  }

  Widget _buildCTA() {
    final tier = _tiers[_selectedTier];

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            gradient: LinearGradient(
              colors: [tier.color, tier.color.withValues(alpha: 0.7)],
            ),
            boxShadow: [
              BoxShadow(
                color: tier.color.withValues(alpha: 0.3 * _glowAnimation.value),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              onTap: _handleCheckoutTap,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedTier == 0
                          ? 'CONTINUE WITH FREE'
                          : 'UNLOCK ${tier.name}',
                      style: TextStyle(
                        color: _selectedTier == 2 ? Colors.white : Colors.black,
                        fontSize: DesignTokens.fontSizeTitle,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (_selectedTier != 0) _buildCtaPriceLine(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FAQ
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildFAQ() {
    final faqs = [
      (
        'Can I cancel anytime?',
        'Yes — no contracts, no commitments. Cancel from your profile settings.',
      ),
      (
        'Do I keep my data if I downgrade?',
        'All your fight data, training logs, and connections are always yours. Premium analytics become read-only.',
      ),
      (
        'Can I upgrade mid-month?',
        'Absolutely. You\'ll be charged the prorated difference and get instant access to all new features.',
      ),
      (
        'Is there a team/gym pricing?',
        'Yes — gym subscription bundles for coaches and their fighters at reduced rates are in development. Email partners@datafightcentral.com for early access.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FAQ',
          style: TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: DesignTokens.fontSizeTitle,
            fontWeight: DesignTokens.fontWeightTitle,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingM),
        ...faqs.map(
          (faq) => Container(
            margin: const EdgeInsets.only(bottom: DesignTokens.spacingS),
            padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: DesignTokens.glassOpacity),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              border: Border.all(
                color: DesignTokens.borderSubtle,
                width: DesignTokens.borderThin,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faq.$1,
                  style: const TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  faq.$2,
                  style: const TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: DesignTokens.fontSizeSubtitleLarge,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TIER DATA
  // ═══════════════════════════════════════════════════════════════════════════

  static final List<_TierData> _tiers = [
    const _TierData(
      name: 'FREE',
      shortName: 'FREE',
      fullName: 'FREE ACCESS',
      icon: Icons.shield_outlined,
      color: DesignTokens.neonCyan,
      price: 'FREE',
      period: 'forever',
      tagline: 'Get started with the basics',
      benefits: [
        'Community feed & FightWire access',
        'Basic fighter profile',
        'View marketplace listings',
        'Fight news & breaking alerts',
        'Limited fight history (last 5)',
        'Ad-supported experience',
      ],
    ),
    const _TierData(
      name: 'FIGHTER PRO',
      shortName: 'PRO',
      fullName: 'FIGHTER PRO',
      icon: Icons.local_fire_department,
      color: DesignTokens.neonGreen,
      price: '\$2.99',
      period: '/month',
      tagline: 'Less than a meal. Train smarter. Fight harder.',
      benefits: [
        'Everything in Free, plus:',
        'Full Combat Intelligence Engine access',
        'AI training insights & coaching',
        'Unlimited fight history & analytics',
        'Style clash predictor',
        'Marketplace posting (sell gear, advertise)',
        'Trainer discovery & booking',
        'Wellness & recovery tracking',
        'Priority support',
        'Ad-free experience',
      ],
    ),
    const _TierData(
      name: 'PROMOTER CMD',
      shortName: 'CMD',
      fullName: 'PROMOTER COMMAND',
      icon: Icons.military_tech,
      color: DesignTokens.neonRed,
      price: '\$9.99',
      period: '/month',
      tagline: 'Run the show. Own the game.',
      benefits: [
        'Everything in Fighter Pro, plus:',
        'Event creation & management',
        'Fighter roster management',
        'Matchmaking AI assistant',
        'Promo signal broadcasting',
        'Revenue & attendance analytics',
        'Featured marketplace placement',
        'Gym startup tools & consulting',
        'Custom branding options',
        'Priority job postings',
        'Dedicated account manager',
      ],
    ),
  ];

  static final List<_ComparisonFeature> _comparisonFeatures = [
    const _ComparisonFeature('FightWire Feed', '✓', '✓', '✓'),
    const _ComparisonFeature('Fighter Profile', 'Basic', 'Full', 'Full'),
    const _ComparisonFeature('Fight History', '5 max', '✓', '✓'),
    const _ComparisonFeature('Combat Intelligence', '—', '✓', '✓'),
    const _ComparisonFeature('AI Training Coach', '—', '✓', '✓'),
    const _ComparisonFeature('Style Clash Predictor', '—', '✓', '✓'),
    const _ComparisonFeature('Marketplace Selling', '—', '✓', '✓'),
    const _ComparisonFeature('Trainer Booking', 'View', '✓', '✓'),
    const _ComparisonFeature('Wellness Tracking', '—', '✓', '✓'),
    const _ComparisonFeature('Ad-Free', '—', '✓', '✓'),
    const _ComparisonFeature('Event Management', '—', '—', '✓'),
    const _ComparisonFeature('Matchmaking AI', '—', '—', '✓'),
    const _ComparisonFeature('Revenue Analytics', '—', '—', '✓'),
    const _ComparisonFeature('Signal Broadcasting', '—', '—', '✓'),
    const _ComparisonFeature('Priority Support', '—', '✓', '✓'),
    const _ComparisonFeature('Gym Startup Tools', '—', '—', '✓'),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════════════════════

class _TierData {
  final String name;
  final String shortName;
  final String fullName;
  final IconData icon;
  final Color color;
  final String price;
  final String period;
  final String tagline;
  final List<String> benefits;

  const _TierData({
    required this.name,
    required this.shortName,
    required this.fullName,
    required this.icon,
    required this.color,
    required this.price,
    required this.period,
    required this.tagline,
    required this.benefits,
  });
}

class _ComparisonFeature {
  final String name;
  final String free;
  final String pro;
  final String command;

  const _ComparisonFeature(this.name, this.free, this.pro, this.command);
}
