import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/pricing_engine.dart';
import '../../../shared/services/services.dart';
import '../../../shared/widgets/dfc_state_panel.dart';
import '../../../shared/widgets/dfc_tab_intro_header.dart';
import '../../../core/theme/design_tokens.dart';

// ═══════════════════════════════════════════════════════════════════
//  ELITE SUBSCRIPTION COMMAND v3.0
//  "Your training evolution starts here"
//  Immersive dark theme · Animated tiers · Payment integration
// ═══════════════════════════════════════════════════════════════════

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late AnimationController _shimmerController;
  String _billingCycle = 'monthly';
  late PaymentsService _payments;
  late SubscriptionService _subscriptionService;
  bool _depsInitialized = false;
  int _expandedTierIndex = 1;
  bool _checkoutOpened = false;
  String _countryCode = 'US';
  LoyaltyStatus _loyalty = DfcPricingEngine.loyaltyFor(null);
  UserSubscription? _currentSubscription;
  bool _isSubscriptionStateLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_depsInitialized) {
      _depsInitialized = true;
      _payments = context.read<PaymentsService>();
      _subscriptionService = context.read<SubscriptionService>();
      _payments.initialize();
      _loadPlans();
      _refreshSubscriptionState();
      // Resolve country + loyalty from locale + Firebase Auth
      final locale = Localizations.localeOf(context);
      final cc = locale.countryCode?.isNotEmpty == true
          ? locale.countryCode!
          : 'US';
      final user = context.read<AuthService>().currentUser;
      _countryCode = cc;
      _loyalty = DfcPricingEngine.loyaltyFor(user?.metadata.creationTime);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _checkoutOpened) {
      _checkoutOpened = false;
      _autoSyncAfterCheckout();
    }
  }

  Future<void> _autoSyncAfterCheckout() async {
    final authService = context.read<AuthService>();
    final userId = authService.currentUser?.uid;
    if (userId == null || !mounted) return;
    final ok = await _payments.syncPostCheckoutStatus(userId);
    if (!mounted) return;
    if (ok) {
      await _refreshSubscriptionState();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment confirmed — premium unlocked!'),
          backgroundColor: Color(0xFF00FFD1),
        ),
      );
      setState(() {});
    }
  }

  Future<void> _loadPlans() async {
    try {
      await _subscriptionService.fetchPlans();
      if (mounted) setState(() {}); // _seededPlans removed as unused
    } catch (_) {}
  }

  Future<void> _refreshSubscriptionState() async {
    final authService = context.read<AuthService>();
    final userId = authService.currentUser?.uid;

    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _currentSubscription = UserSubscription.free('anonymous');
        _isSubscriptionStateLoading = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isSubscriptionStateLoading = true;
      });
    }

    await _payments.loadUserSubscription(userId);
    final subscription = await _subscriptionService.getCurrentSubscription();

    if (!mounted) return;
    setState(() {
      _currentSubscription = subscription;
      _isSubscriptionStateLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: Stack(
        children: [
          // Background grid
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _GridPainter(),
          ),
          SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                    context,
                  ),
                  sliver: _buildAppBar(),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildScrollableTab(_buildPlansContent()),
                  _buildScrollableTab(_buildAnalyticsContent()),
                  _buildScrollableTab(_buildManageContent()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────────
  Widget _buildAppBar() {
    final canPop = context.canPop();

    return SliverAppBar(
      floating: true,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: DesignTokens.bgPrimary,
      surfaceTintColor: Colors.transparent,
      expandedHeight: 224,
      title: const Text(
        'PREMIUM ACCESS',
        style: TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                DesignTokens.neonGold.withValues(alpha: 0.15),
                DesignTokens.bgPrimary,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DFCTabIntroHeader(
                title: 'Premium Access',
                subtitle:
                    'Training insights, recovery tools, and premium business access across the DFC network.',
                icon: Icons.workspace_premium,
                accent: DesignTokens.neonGold,
                topInset: 8,
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                leading: canPop
                    ? IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 18,
                        ),
                      )
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildImpactChip(
                      '2,400+',
                      'FIGHTERS',
                      DesignTokens.neonCyan,
                    ),
                    _buildImpactChip(
                      '89%',
                      'WIN RATE ↑',
                      DesignTokens.neonGreen,
                    ),
                    _buildImpactChip('4.9★', 'RATED', DesignTokens.neonGold),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            tabAlignment: TabAlignment.fill,
            indicatorColor: DesignTokens.neonGold,
            indicatorWeight: 3,
            labelColor: DesignTokens.neonGold,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
            labelPadding: EdgeInsets.zero,
            tabs: const [
              Tab(height: 40, text: 'PLANS'),
              Tab(height: 40, text: 'VALUE'),
              Tab(height: 40, text: 'MANAGE'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImpactChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SCROLL WRAPPER ────────────────────────────────────────────────
  Widget _buildScrollableTab(Widget content) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverToBoxAdapter(child: content),
          ],
        );
      },
    );
  }

  // ─── PLANS TAB ────────────────────────────────────────────────────
  Widget _buildPlansContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Transformation banner
          _buildTransformBanner(),
          const SizedBox(height: 20),
          // Billing cycle toggle
          _buildBillingToggle(),
          const SizedBox(height: 24),
          // Tier cards
          _buildTierCard(
            index: 0,
            tier: 'FREE ACCESS',
            subtitle: 'Start your journey',
            price: 'FREE',
            priceLabel: 'forever',
            color: const Color(0xFF8E8E93),
            icon: Icons.shield_outlined,
            features: [
              const _F('Browse events & news', true),
              const _F('View fighter profiles', true),
              const _F('Community feed access', true),
              const _F('Basic fight cards', true),
              const _F('Performance analytics', false),
              const _F('AI coaching', false),
              const _F('Smart device sync', false),
            ],
          ),
          const SizedBox(height: 16),
          _buildTierCard(
            index: 1,
            tier: 'FIGHTER PRO',
            subtitle: 'Serious training. Serious results.',
            price: _priceFor('Fighter'),
            priceLabel: _cycleLabel(),
            color: DesignTokens.neonCyan,
            icon: Icons.local_fire_department,
            isPopular: true,
            features: [
              const _F('Everything in Free', true),
              const _F('Full performance dashboard', true),
              const _F('AI fight analysis & predictions', true),
              const _F('Smart device integration', true),
              const _F('Training load analytics', true),
              const _F('Mental health & recovery tools', true),
              const _F('Fight camp planning', true),
              const _F('Work & sponsorship access', true),
              const _F('Priority matchmaking', true),
            ],
          ),
          const SizedBox(height: 16),
          _buildTierCard(
            index: 2,
            tier: 'PROMOTER CMD',
            subtitle: 'Run events like a champion',
            price: _priceFor('Promoter'),
            priceLabel: _cycleLabel(),
            color: DesignTokens.neonMagenta,
            icon: Icons.stadium,
            features: [
              const _F('Everything in Fighter Pro', true),
              const _F('Event creation & management', true),
              const _F('Fighter database & recruiting', true),
              const _F('Advanced matchmaking engine', true),
              const _F('Ticket & pass management', true),
              const _F('Revenue analytics', true),
              const _F('Marketing & SEO tools', true),
              const _F('API access', true),
              const _F('Dedicated support', true),
            ],
          ),
          const SizedBox(height: 16),
          _buildTierCard(
            index: 3,
            tier: 'SUPPORTER',
            subtitle: 'Champion the fighters you love',
            price: _priceFor('Supporter'),
            priceLabel: _cycleLabel(),
            color: DesignTokens.neonGold,
            icon: Icons.favorite,
            features: [
              const _F('Everything in Free', true),
              const _F('Ad-free experience', true),
              const _F('Exclusive behind-the-scenes', true),
              const _F('Early event access & presale', true),
              const _F('Support your favourite fighters', true),
              const _F('Supporter badge', true),
            ],
          ),
          const SizedBox(height: 32),
          // Trust section
          _buildTrustSection(),
          const SizedBox(height: 24),
          // Feature comparison
          _buildCompareButton(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTransformBanner() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment(-1 + _shimmerController.value * 2, 0),
              end: Alignment(1 + _shimmerController.value * 2, 0),
              colors: [
                DesignTokens.neonCyan.withValues(alpha: 0.05),
                DesignTokens.neonGold.withValues(alpha: 0.1),
                DesignTokens.neonCyan.withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(
              color: DesignTokens.neonGold.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              const Text(
                '🔥 YOUR TRAINING EVOLUTION STARTS HERE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join elite fighters who transformed their game with AI-powered analytics, '
                'smart device integration, and the most advanced fight camp tools ever built.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMiniStat('78%', 'train more\nconsistently'),
                  _buildMiniStat('3.2x', 'faster\nrecovery insight'),
                  _buildMiniStat('92%', 'say it changed\ntheir lifestyle'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: DesignTokens.neonGold,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCycleChip('weekly', 'Weekly'),
          _buildCycleChip('fortnightly', '2 Weeks'),
          _buildCycleChip('monthly', 'Monthly'),
        ],
      ),
    );
  }

  Widget _buildCycleChip(String value, String label) {
    final selected = _billingCycle == value;
    return GestureDetector(
      onTap: () => setState(() => _billingCycle = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                )
              : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white38,
            fontWeight: selected ? FontWeight.w800 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTierCard({
    required int index,
    required String tier,
    required String subtitle,
    required String price,
    required String priceLabel,
    required Color color,
    required IconData icon,
    required List<_F> features,
    bool isPopular = false,
  }) {
    final expanded = _expandedTierIndex == index;
    return GestureDetector(
      onTap: () => setState(
        () => _expandedTierIndex = _expandedTierIndex == index ? -1 : index,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPopular
                ? color
                : color.withValues(alpha: expanded ? 0.5 : 0.15),
            width: isPopular ? 1.5 : 1,
          ),
          boxShadow: isPopular
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 30,
                    spreadRadius: -5,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Popular badge
            if (isPopular)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'MOST POPULAR — 89% WIN RATE IMPROVEMENT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tier,
                              style: TextStyle(
                                color: color,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            price,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (price != 'FREE')
                            Text(
                              priceLabel,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  // Features (expanded)
                  if (expanded) ...[
                    const SizedBox(height: 18),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                    const SizedBox(height: 14),
                    ...features.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              f.included
                                  ? Icons.check_circle
                                  : Icons.remove_circle_outline,
                              color: f.included
                                  ? DesignTokens.neonGreen
                                  : Colors.white24,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                f.label,
                                style: TextStyle(
                                  color: f.included
                                      ? Colors.white
                                      : Colors.white38,
                                  fontSize: 13,
                                  decoration: f.included
                                      ? null
                                      : TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Subscribe button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: price == 'FREE'
                            ? null
                            : () => _subscribe(tier),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.white.withValues(
                            alpha: 0.06,
                          ),
                          disabledForegroundColor: Colors.white38,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          price == 'FREE'
                              ? 'CURRENT PLAN'
                              : 'START 7-DAY FREE TRIAL',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    if (price != 'FREE')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Cancel anytime. No commitments.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ] else ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '${features.where((f) => f.included).length} features included',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.expand_more,
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          const Text(
            'TRUSTED BY FIGHTERS WORLDWIDE',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTrustItem(Icons.security, 'Secure\nPayments'),
              _buildTrustItem(Icons.cancel_outlined, 'Cancel\nAnytime'),
              _buildTrustItem(
                Icons.health_and_safety,
                'Crisis Support\nAlways Free',
              ),
              _buildTrustItem(Icons.lock, 'Data\nProtected'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _paymentBadge('Stripe'),
              const SizedBox(width: 8),
              _paymentBadge('Apple Pay'),
              const SizedBox(width: 8),
              _paymentBadge('Google Pay'),
              const SizedBox(width: 8),
              _paymentBadge('PayPal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: DesignTokens.neonGreen, size: 24),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _paymentBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCompareButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _showFeatureComparison,
        icon: const Icon(Icons.compare_arrows, size: 18),
        label: const Text(
          'COMPARE ALL FEATURES',
          style: TextStyle(
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white54,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ─── VALUE / ANALYTICS TAB ────────────────────────────────────────
  Widget _buildAnalyticsContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Value score
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: DesignTokens.bgCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: DesignTokens.neonGold.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'YOUR VALUE SCORE',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CustomPaint(
                    painter: _ValueRingPainter(0.82, DesignTokens.neonGold),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '82%',
                            style: TextStyle(
                              color: DesignTokens.neonGold,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'EXCELLENT',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You use 82% of available features.\nFighter Pro gives you maximum ROI.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Feature usage breakdown
          _sectionLabel('FEATURE USAGE'),
          const SizedBox(height: 12),
          _buildUsageBar('Training Analytics', 0.92, DesignTokens.neonCyan),
          _buildUsageBar('AI Fight Analysis', 0.78, DesignTokens.neonGreen),
          _buildUsageBar(
            'Performance Dashboard',
            0.85,
            DesignTokens.neonMagenta,
          ),
          _buildUsageBar('Smart Devices', 0.65, DesignTokens.neonAmber),
          _buildUsageBar('Mental Health Tools', 0.45, const Color(0xFF9B59B6)),
          _buildUsageBar('Matchmaking', 0.30, DesignTokens.neonRed),
          const SizedBox(height: 24),
          // Cost breakdown
          _sectionLabel('COST BREAKDOWN'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DesignTokens.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: [
                _buildCostRow('Base plan', _priceFor('Fighter')),
                _buildCostRow('Add-ons', '\$0.00'),
                _buildCostRow(
                  'Discounts',
                  _loyalty.hasDiscount
                      ? '-${_loyalty.discountLabel}'
                      : '-\$0.00',
                ),
                const Divider(color: Colors.white12, height: 24),
                _buildCostRow(
                  'Monthly total',
                  _priceFor('Fighter'),
                  highlight: true,
                ),
                const SizedBox(height: 8),
                _buildCostRow(
                  'Daily cost',
                  "\$${(DfcPricingEngine.priceFor(productKey: 'fighter_pro', countryCode: _countryCode).usd / 30).toStringAsFixed(2)}",
                  accent: DesignTokens.neonGreen,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // ROI comparison
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DesignTokens.neonGreen.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: DesignTokens.neonGreen.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.trending_up,
                  color: DesignTokens.neonGreen,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BETTER THAN A GYM MEMBERSHIP',
                        style: TextStyle(
                          color: DesignTokens.neonGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Average gym: \$50/mo. Personal trainer: \$200/mo.\n'
                        'DFC Fighter Pro: ${_priceFor("Fighter")}/mo with AI coaching included.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildUsageBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.5)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(
    String label,
    String amount, {
    bool highlight = false,
    Color? accent,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlight ? Colors.white : Colors.white54,
              fontSize: 13,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: accent ?? (highlight ? Colors.white : Colors.white54),
              fontSize: highlight ? 18 : 13,
              fontWeight: highlight ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── MANAGE TAB ───────────────────────────────────────────────────
  Widget _buildManageContent() {
    final subscription = _currentSubscription;
    final hasPaidSubscription =
        subscription != null &&
        subscription.isActive &&
        subscription.tier.name != 'free';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isSubscriptionStateLoading)
            const DFCStatePanel.loading(
              title: 'Loading subscription',
              message: 'Checking your current plan and billing access...',
            )
          else if (!hasPaidSubscription)
            DFCStatePanel(
              title: 'No paid subscription yet',
              message:
                  'You are currently on the free plan. Upgrade to unlock advanced training analytics, AI coaching, and premium fight tools.',
              icon: Icons.workspace_premium_outlined,
              accent: DesignTokens.neonGold,
              actionLabel: 'View plans',
              onAction: () => _tabController.animateTo(0),
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _subscriptionAccent(subscription).withValues(alpha: 0.1),
                    DesignTokens.bgCard,
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _subscriptionAccent(
                    subscription,
                  ).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _subscriptionAccent(
                            subscription,
                          ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          subscription.isTrial ? 'TRIAL' : 'ACTIVE',
                          style: TextStyle(
                            color: _subscriptionAccent(subscription),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _subscriptionName(subscription),
                        style: TextStyle(
                          color: _subscriptionAccent(subscription),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _manageDetailRow('Price', _subscriptionPrice(subscription)),
                  _manageDetailRow(
                    'Member since',
                    _formatSubscriptionDate(subscription.startDate),
                  ),
                  _manageDetailRow(
                    subscription.isTrial ? 'Trial ends' : 'Next billing',
                    _subscriptionRenewalLabel(subscription),
                  ),
                  _manageDetailRow(
                    'Payment',
                    subscription.stripeCustomerId != null
                        ? 'Secure Stripe checkout on file'
                        : 'Managed through secure checkout',
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          _sectionLabel('QUICK ACTIONS'),
          const SizedBox(height: 12),
          _buildManageItem(
            icon: Icons.swap_horiz,
            label: 'Change Plan',
            subtitle: 'Upgrade or downgrade',
            color: DesignTokens.neonCyan,
            onTap: () {
              _tabController.animateTo(0);
            },
          ),
          _buildManageItem(
            icon: Icons.credit_card,
            label: 'Payment Method',
            subtitle: 'Update card or wallet',
            color: DesignTokens.neonGreen,
            onTap: _showPaymentMethodDialog,
          ),
          _buildManageItem(
            icon: Icons.receipt_long,
            label: 'Billing History',
            subtitle: 'View past invoices',
            color: DesignTokens.neonAmber,
            onTap: () {
              if (mounted) {
                context.push('/billing-history');
              }
            },
          ),
          _buildManageItem(
            icon: Icons.card_giftcard,
            label: 'Redeem Code',
            subtitle: 'Gift cards & promo codes',
            color: DesignTokens.neonMagenta,
            onTap: _showRedeemDialog,
          ),
          _buildManageItem(
            icon: Icons.restore,
            label: 'Restore Purchases',
            subtitle: 'Recover previous subscriptions',
            color: const Color(0xFF9B59B6),
            onTap: () async {
              final authService = context.read<AuthService>();
              final userId = authService.currentUser?.uid ?? 'anonymous';
              final restored = await _payments.restorePurchases(userId);
              if (restored) {
                await _refreshSubscriptionState();
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      restored
                          ? 'Purchases restored successfully.'
                          : 'No previous purchases found to restore.',
                    ),
                    backgroundColor: DesignTokens.bgSecondary,
                  ),
                );
              }
            },
          ),
          _buildManageItem(
            icon: Icons.sync,
            label: 'Sync Payment Status',
            subtitle: 'Refresh after Stripe checkout',
            color: const Color(0xFF00D4FF),
            onTap: () async {
              final authService = context.read<AuthService>();
              final userId = authService.currentUser?.uid;
              if (userId == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sign in to sync payments.')),
                  );
                }
                return;
              }

              final ok = await _payments.syncPostCheckoutStatus(userId);
              if (ok) {
                await _refreshSubscriptionState();
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Payment confirmed. Premium access is active.'
                          : 'No active paid subscription found yet. Try again in a minute.',
                    ),
                    backgroundColor: DesignTokens.bgSecondary,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 24),
          // Cancel section
          if (hasPaidSubscription)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DesignTokens.neonRed.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: DesignTokens.neonRed.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: DesignTokens.neonRed.withValues(alpha: 0.6),
                    size: 24,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cancel Subscription',
                          style: TextStyle(
                            color: DesignTokens.neonRed,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Your access continues until ${_subscriptionRenewalLabel(subscription)}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    onPressed: _showCancelDialog,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildManageItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DesignTokens.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.2),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _manageDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.4),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }

  String _priceFor(String tier) {
    final prodKey = switch (tier.toLowerCase()) {
      'fighter' => 'fighter_pro',
      'promoter' => 'promoter_cmd',
      'supporter' => 'supporter',
      _ => 'fighter_pro',
    };
    final monthly = DfcPricingEngine.priceFor(
      productKey: prodKey,
      countryCode: _countryCode,
    ).usd;
    final effective = _loyalty.hasDiscount
        ? DfcPricingEngine.applyLoyaltyDiscount(monthly, _loyalty.discountPct)
        : monthly;
    switch (_billingCycle) {
      case 'weekly':
        return '\$${(effective / 4.33).toStringAsFixed(2)}';
      case 'fortnightly':
        return '\$${(effective / 2.17).toStringAsFixed(2)}';
      default:
        return '\$${effective.toStringAsFixed(2)}';
    }
  }

  String _cycleLabel() {
    switch (_billingCycle) {
      case 'weekly':
        return '/week';
      case 'fortnightly':
        return '/2 weeks';
      default:
        return '/month';
    }
  }

  String _subscriptionName(UserSubscription subscription) {
    switch (subscription.tier.name) {
      case 'fighterPro':
        return 'Fighter Pro';
      case 'coachMentor':
        return 'Coach & Mentor';
      case 'promoterGym':
      case 'legacy':
        return 'Promoter & Gym';
      default:
        return 'Free Access';
    }
  }

  Color _subscriptionAccent(UserSubscription? subscription) {
    switch (subscription?.tier.name) {
      case 'supporter':
        return DesignTokens.neonGold;
      case 'coachMentor':
        return DesignTokens.neonGreen;
      case 'promoterGym':
      case 'legacy':
        return DesignTokens.neonMagenta;
      case 'fighterPro':
        return DesignTokens.neonCyan;
      default:
        return Colors.white54;
    }
  }

  String _subscriptionPrice(UserSubscription subscription) {
    switch (subscription.tier.name) {
      case 'fighterPro':
        return '${_priceFor('Fighter')}/month';
      case 'promoterGym':
      case 'legacy':
        return '${_priceFor('Promoter')}/month';
      case 'supporter':
        return '${_priceFor('Supporter')}/month';
      default:
        return 'Free';
    }
  }

  String _subscriptionRenewalLabel(UserSubscription subscription) {
    final renewalDate = subscription.trialEndDate ?? subscription.endDate;
    if (renewalDate == null) {
      return subscription.isYearly
          ? 'Annual renewal active'
          : 'Monthly renewal active';
    }
    return _formatSubscriptionDate(renewalDate);
  }

  String _formatSubscriptionDate(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }

  Future<void> _subscribe(String tier) async {
    final authService = context.read<AuthService>();
    final userId = authService.currentUser?.uid ?? 'anonymous';
    final countryCode =
        Localizations.localeOf(context).countryCode?.toUpperCase() ?? 'US';
    final cycle = _billingCycle == 'yearly' ? 'yearly' : 'monthly';

    final opened = await _payments.openGlobalSubscriptionCheckout(
      userId: userId,
      tier: tier,
      billingCycle: cycle,
      countryCode: countryCode,
      isMobile: !kIsWeb,
    );
    if (opened) _checkoutOpened = true;

    final recommendation = _payments.recommendCheckoutRail(
      countryCode: countryCode,
      amount: switch (tier.toLowerCase()) {
        'fighter' =>
          cycle == 'yearly'
              ? DfcPricingEngine.yearlyPrice(
                  productKey: 'fighter_pro',
                  countryCode: _countryCode,
                )
              : DfcPricingEngine.priceFor(
                  productKey: 'fighter_pro',
                  countryCode: _countryCode,
                ).usd,
        'promoter' =>
          cycle == 'yearly'
              ? DfcPricingEngine.yearlyPrice(
                  productKey: 'promoter_cmd',
                  countryCode: _countryCode,
                )
              : DfcPricingEngine.priceFor(
                  productKey: 'promoter_cmd',
                  countryCode: _countryCode,
                ).usd,
        'supporter' =>
          cycle == 'yearly'
              ? DfcPricingEngine.yearlyPrice(
                  productKey: 'supporter',
                  countryCode: _countryCode,
                )
              : DfcPricingEngine.priceFor(
                  productKey: 'supporter',
                  countryCode: _countryCode,
                ).usd,
        _ => 0.0,
      },
      isMobile: !kIsWeb,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            opened
                ? 'Opening secure checkout (${recommendation.primaryLabel})…'
                : 'Could not open checkout. Please try again.',
          ),
          backgroundColor: DesignTokens.bgSecondary,
        ),
      );
    }
  }

  void _showFeatureComparison() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              const Center(
                child: Text(
                  'FEATURE COMPARISON',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _compHeader(),
              _compRow('Browse events', true, true, true, true),
              _compRow('Fighter profiles', true, true, true, true),
              _compRow('Community feed', true, true, true, true),
              _compRow('Ad-free experience', false, true, true, true),
              _compRow('Performance dashboard', false, true, true, false),
              _compRow('AI fight analysis', false, true, true, false),
              _compRow('Training analytics', false, true, true, false),
              _compRow('Smart device sync', false, true, true, false),
              _compRow('Mental health tools', false, true, true, false),
              _compRow('Fight camp planning', false, true, true, false),
              _compRow('Work opportunities', false, true, true, false),
              _compRow('Event management', false, false, true, false),
              _compRow('Matchmaking engine', false, false, true, false),
              _compRow('Revenue analytics', false, false, true, false),
              _compRow('Marketing & SEO', false, false, true, false),
              _compRow('API access', false, false, true, false),
              _compRow('Dedicated support', false, false, true, false),
              _compRow('Exclusive content', false, false, false, true),
              _compRow('Early event access', false, false, false, true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _compHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Feature',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Free',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ),
          Expanded(
            child: Text(
              'Pro',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DesignTokens.neonCyan,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'CMD',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DesignTokens.neonMagenta,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Fan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DesignTokens.neonGold,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compRow(String feature, bool free, bool pro, bool cmd, bool fan) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              feature,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
          Expanded(child: _checkDot(free, Colors.white38)),
          Expanded(child: _checkDot(pro, DesignTokens.neonCyan)),
          Expanded(child: _checkDot(cmd, DesignTokens.neonMagenta)),
          Expanded(child: _checkDot(fan, DesignTokens.neonGold)),
        ],
      ),
    );
  }

  Widget _checkDot(bool has, Color color) {
    return Icon(
      has ? Icons.check_circle : Icons.remove,
      color: has ? color : Colors.white12,
      size: 16,
    );
  }

  void _showPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Payment Method',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _payMethodTile('Visa •••• 4242', Icons.credit_card, true),
            _payMethodTile('Apple Pay', Icons.phone_iphone, false),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add New Method'),
              style: OutlinedButton.styleFrom(
                foregroundColor: DesignTokens.neonCyan,
                side: BorderSide(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                ),
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _payMethodTile(String label, IconData icon, bool active) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active
            ? DesignTokens.neonCyan.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? DesignTokens.neonCyan.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: active ? DesignTokens.neonCyan : Colors.white38,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.white54,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          if (active)
            const Text(
              'DEFAULT',
              style: TextStyle(
                color: DesignTokens.neonCyan,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }

  void _showRedeemDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Redeem Code',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter promo or gift code',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Code applied!'),
                  backgroundColor: DesignTokens.bgSecondary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.neonGold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancel Subscription?',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ll lose access to:',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            _cancelLossItem('AI fight analysis & predictions'),
            _cancelLossItem('Smart device integration'),
            _cancelLossItem('Training analytics'),
            _cancelLossItem('Performance dashboard'),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DesignTokens.neonGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Crisis support & mental health resources remain free forever.',
                style: TextStyle(color: DesignTokens.neonGreen, fontSize: 11),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final rootNav = Navigator.of(ctx, rootNavigator: true);
              if (rootNav.canPop()) {
                rootNav.pop();
                return;
              }
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: const Text(
              'Keep Plan',
              style: TextStyle(color: DesignTokens.neonCyan),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final authService = context.read<AuthService>();
              final userId = authService.currentUser?.uid ?? 'anonymous';
              final cancelled = await _payments.cancelSubscription(userId);
              if (cancelled) {
                await _refreshSubscriptionState();
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      cancelled
                          ? 'Subscription cancelled.'
                          : 'Unable to cancel subscription right now.',
                    ),
                    backgroundColor: DesignTokens.bgSecondary,
                  ),
                );
              }
            },
            child: const Text(
              'Cancel Subscription',
              style: TextStyle(color: DesignTokens.neonRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cancelLossItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.remove_circle,
            color: DesignTokens.neonRed,
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─── DATA CLASS ────────────────────────────────────────────────────
class _F {
  final String label;
  final bool included;
  const _F(this.label, this.included);
}

// ─── GRID BACKGROUND PAINTER ──────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── VALUE RING PAINTER ───────────────────────────────────────────
class _ValueRingPainter extends CustomPainter {
  final double value;
  final Color color;
  _ValueRingPainter(this.value, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );
    // Value arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ValueRingPainter old) =>
      old.value != value || old.color != color;
}
