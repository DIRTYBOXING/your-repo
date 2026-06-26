import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/services/auth_service.dart';
import '../models/ppv_storefront_models.dart';
import '../services/ppv_storefront_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV HERO STOREFRONT SCREEN — MOBILE-FIRST, RESPONSIVE
/// ═══════════════════════════════════════════════════════════════════════════
/// Professional pay-per-view experience with:
/// - Responsive grid layout (mobile, tablet, desktop)
/// - Real-time Firestore data loading
/// - Image caching and optimization
/// - Professional fight card rendering
/// - Integrated checkout flow

class PpvHeroStorefrontScreen extends StatefulWidget {
  const PpvHeroStorefrontScreen({super.key});

  @override
  State<PpvHeroStorefrontScreen> createState() =>
      _PpvHeroStorefrontScreenState();
}

class _PpvHeroStorefrontScreenState extends State<PpvHeroStorefrontScreen> {
  late final PpvStorefrontService _storefrontService;
  PPVStorefrontEvent? _currentEvent;
  int _selectedTierIndex = 0;
  bool _isCheckingOut = false;
  String? _lastOrderId;

  @override
  void initState() {
    super.initState();
    _storefrontService = PpvStorefrontService();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    try {
      final db = FirebaseFirestore.instance;
      // Try to load the first active PPV event
      final snapshot = await db
          .collection('ppv_events')
          .where('eventStatus', isNotEqualTo: 'expired')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final event = PPVStorefrontEvent.fromFirestore(
          snapshot.docs.first.id,
          snapshot.docs.first.data(),
        );
        setState(() {
          _currentEvent = event;
          _selectedTierIndex = 0;
        });
      } else {
        // Fallback to sandbox event
        setState(() {
          _currentEvent = _buildSandboxEvent();
          _selectedTierIndex = 0;
        });
      }
    } catch (e) {
      setState(() {
        _currentEvent = _buildSandboxEvent();
        _selectedTierIndex = 0;
      });
    }
  }

  PPVStorefrontEvent _buildSandboxEvent() {
    return PPVStorefrontEvent(
      id: 'sandbox-main-card',
      title: 'Main Card Event',
      subtitle: 'Premium Pay-Per-View',
      description:
          'Experience the ultimate in combat sports with crystal-clear 4K streaming, multi-camera angles, and exclusive post-fight analysis.',
      promotion: 'DFC Network',
      sportType: 'Combat Sports',
      eventDate: DateTime.now().add(const Duration(days: 1)),
      posterUrl:
          'https://images.unsplash.com/photo-1544390623-df9c1db162e4?w=800&q=80',
      heroImageUrl:
          'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=1200&q=80',
      pricingTiers: const [
        PPVPricingTier(
          id: 'standard',
          title: 'Standard Access',
          priceLabel: '\$49.99 AUD',
          description: 'Full live event + 7-day replay',
          features: [
            'Live HD stream',
            '7-day replay access',
            'Match highlights',
            'Community chat',
          ],
          priceAUD: 4999,
        ),
        PPVPricingTier(
          id: 'premium',
          title: 'Premium Bundle',
          priceLabel: '\$69.99 AUD',
          description: 'Everything + multi-cam & analysis',
          features: [
            '4K + 60fps stream',
            'Multiple camera angles',
            'Expert commentary',
            '30-day replay access',
            'Exclusive fighter insights',
          ],
          priceAUD: 6999,
          isRecommended: true,
        ),
        PPVPricingTier(
          id: 'ultimate',
          title: 'Ultimate VIP',
          priceLabel: '\$89.99 AUD',
          description: 'All access + VIP perks',
          features: [
            '4K + 60fps stream',
            'All camera angles',
            'Multi-language commentary',
            'Lifetime replay access',
            'VIP live chat',
            'Post-fight interviews',
          ],
          priceAUD: 8999,
        ),
      ],
      fightCard: const [
        PPVFightPreview(
          fighterId1: 'fighter1',
          fighterId2: 'fighter2',
          fighter1Name: 'Champion A',
          fighter2Name: 'Challenger B',
          weightClass: 'Middleweight',
          mainTitle: 'MAIN EVENT',
          order: 0,
        ),
        PPVFightPreview(
          fighterId1: 'fighter3',
          fighterId2: 'fighter4',
          fighter1Name: 'Fighter C',
          fighter2Name: 'Fighter D',
          weightClass: 'Lightweight',
          mainTitle: 'CO-MAIN',
          order: 1,
        ),
      ],
      eventStatus: 'onSale',
      hasMultiCam: true,
    );
  }

  @override
  void dispose() {
    _storefrontService.dispose();
    super.dispose();
  }

  Future<void> _handleCheckout() async {
    if (_currentEvent == null) return;

    setState(() => _isCheckingOut = true);

    try {
      final auth = context.read<AuthService>();
      final userId = auth.currentUser?.uid ?? 'guest_operator';
      final tier = _currentEvent!.pricingTiers[_selectedTierIndex];

      final order = await _storefrontService.createOrder(
        eventId: _currentEvent!.id,
        tierId: tier.id,
        userId: userId,
      );

      if (!mounted) return;

      setState(() {
        _lastOrderId = order['orderId']?.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order created: ${order['orderId']} - Ready for payment',
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // Navigate to payment flow or show payment dialog
      // context.push('/ppv/checkout', extra: order);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Checkout failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isCheckingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.width > 800;
    final isMobile = mediaQuery.size.width < 600;

    if (_currentEvent == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircularProgressIndicator(color: AppTheme.accentCyan),
              SizedBox(height: 16),
              Text('Loading event...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    final event = _currentEvent!;
    final selectedTier = event.pricingTiers[_selectedTierIndex];

    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: isMobile
          ? _MobileStickyCheckoutBar(
              eventId: event.id,
              tier: selectedTier,
              isCheckingOut: _isCheckingOut,
              onCheckout: _handleCheckout,
              showReadyBanner: _lastOrderId != null,
              orderId: _lastOrderId,
            )
          : null,
      body: Semantics(
        label: 'data-test=ppv-hub',
        child: CustomScrollView(
          slivers: [
            // Hero section with event image
            SliverToBoxAdapter(child: _HeroSection(event: event)),
            // Main content - responsive layout
            if (isMobile)
              // MOBILE: Stacked vertically
              SliverToBoxAdapter(
                child: _MobileLayout(
                  event: event,
                  selectedTier: selectedTier,
                  selectedTierIndex: _selectedTierIndex,
                  isCheckingOut: _isCheckingOut,
                  onTierSelected: (index) =>
                      setState(() => _selectedTierIndex = index),
                  onCheckout: _handleCheckout,
                ),
              )
            else if (isTablet)
              // TABLET: Two-column layout
              SliverToBoxAdapter(
                child: _TabletLayout(
                  event: event,
                  selectedTier: selectedTier,
                  selectedTierIndex: _selectedTierIndex,
                  isCheckingOut: _isCheckingOut,
                  onTierSelected: (index) =>
                      setState(() => _selectedTierIndex = index),
                  onCheckout: _handleCheckout,
                ),
              )
            else
              // DESKTOP: Three-column layout
              SliverToBoxAdapter(
                child: _DesktopLayout(
                  event: event,
                  selectedTier: selectedTier,
                  selectedTierIndex: _selectedTierIndex,
                  isCheckingOut: _isCheckingOut,
                  onTierSelected: (index) =>
                      setState(() => _selectedTierIndex = index),
                  onCheckout: _handleCheckout,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

/// ═════════════════════════════════════════════════════════════════════════
/// HERO SECTION — Event image, title, live countdown, trust signals
class _HeroSection extends StatelessWidget {
  final PPVStorefrontEvent event;

  const _HeroSection({required this.event});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'data-test=event-poster',
      child: Stack(
        children: [
          // Background image with gradient overlay
          Container(
            height: 400,
            color: AppTheme.background,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (event.heroImageUrl != null)
                  CachedNetworkImage(
                    imageUrl: event.heroImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey[900]),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[900],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
                  )
                else
                  Container(color: Colors.grey[900]),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        AppTheme.background.withValues(alpha: 0.8),
                        AppTheme.background,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content overlay
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.promotion != null)
                    Text(
                      event.promotion!.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.accentCyan,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  if (event.subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      event.subtitle!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Back button
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ═════════════════════════════════════════════════════════════════════════
/// MOBILE LAYOUT — Stacked vertically, full width
class _MobileLayout extends StatelessWidget {
  final PPVStorefrontEvent event;
  final PPVPricingTier selectedTier;
  final int selectedTierIndex;
  final bool isCheckingOut;
  final Function(int) onTierSelected;
  final VoidCallback onCheckout;

  const _MobileLayout({
    required this.event,
    required this.selectedTier,
    required this.selectedTierIndex,
    required this.isCheckingOut,
    required this.onTierSelected,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event story
          if (event.description != null) ...[
            const _SectionTitle(title: 'About This Event'),
            const SizedBox(height: 12),
            _StoryCard(description: event.description!),
            const SizedBox(height: 24),
          ],
          // Fight card
          if (event.fightCard.isNotEmpty) ...[
            const _SectionTitle(title: 'Fight Card'),
            const SizedBox(height: 12),
            ..._buildFightCardMobile(event.fightCard),
            const SizedBox(height: 24),
          ],
          // Pricing tiers
          const _SectionTitle(title: 'Choose Your Access'),
          const SizedBox(height: 12),
          ..._buildTierSelectors(
            event.pricingTiers,
            selectedTierIndex,
            onTierSelected,
          ),
          const SizedBox(height: 16),
          // Tier details
          _TierDetailsCard(tier: selectedTier),
          const SizedBox(height: 16),
          const SizedBox(height: 8),
          Text(
            'Quick checkout stays pinned below while you browse tiers and card details.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          // Trust signals
          _TrustSignals(event: event),
        ],
      ),
    );
  }

  List<Widget> _buildTierSelectors(
    List<PPVPricingTier> tiers,
    int selectedIndex,
    Function(int) onSelect,
  ) {
    return List<Widget>.generate(
      tiers.length,
      (index) => Padding(
        padding: EdgeInsets.only(bottom: index == tiers.length - 1 ? 0 : 12),
        child: _PricingTierButton(
          tier: tiers[index],
          selected: index == selectedIndex,
          onTap: () => onSelect(index),
        ),
      ),
    );
  }

  List<Widget> _buildFightCardMobile(List<PPVFightPreview> fights) {
    return fights
        .map(
          (fight) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FightCardItemMobile(fight: fight),
          ),
        )
        .toList();
  }
}

class _MobileStickyCheckoutBar extends StatelessWidget {
  final String eventId;
  final PPVPricingTier tier;
  final bool isCheckingOut;
  final VoidCallback onCheckout;
  final bool showReadyBanner;
  final String? orderId;

  const _MobileStickyCheckoutBar({
    required this.eventId,
    required this.tier,
    required this.isCheckingOut,
    required this.onCheckout,
    required this.showReadyBanner,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: AppTheme.background,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showReadyBanner)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.neonGreen.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'Checkout prepared. Order ${orderId ?? ''} is ready for payment confirmation.',
                  style: const TextStyle(
                    color: AppTheme.neonGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: Semantics(
                button: true,
                label: 'data-test=buy-cta-$eventId',
                child: ElevatedButton(
                  key: ValueKey('buy-cta-$eventId'),
                  onPressed: isCheckingOut ? null : onCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentCyan,
                    foregroundColor: Colors.black,
                  ),
                  child: isCheckingOut
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'CHECKOUT ${tier.priceLabel}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 0.4,
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
}

/// ═════════════════════════════════════════════════════════════════════════
/// TABLET LAYOUT — Two-column: content + sidebar
class _TabletLayout extends StatelessWidget {
  final PPVStorefrontEvent event;
  final PPVPricingTier selectedTier;
  final int selectedTierIndex;
  final bool isCheckingOut;
  final Function(int) onTierSelected;
  final VoidCallback onCheckout;

  const _TabletLayout({
    required this.event,
    required this.selectedTier,
    required this.selectedTierIndex,
    required this.isCheckingOut,
    required this.onTierSelected,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: content
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.description != null) ...[
                    const _SectionTitle(title: 'About This Event'),
                    const SizedBox(height: 12),
                    _StoryCard(description: event.description!),
                    const SizedBox(height: 32),
                  ],
                  if (event.fightCard.isNotEmpty) ...[
                    const _SectionTitle(title: 'Fight Card'),
                    const SizedBox(height: 16),
                    ...event.fightCard.map(
                      (fight) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FightCardItemTablet(fight: fight),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 32),
          // Right column: pricing sidebar
          SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(title: 'Pricing'),
                  const SizedBox(height: 16),
                  ...List<Widget>.generate(
                    event.pricingTiers.length,
                    (index) => Padding(
                      padding: EdgeInsets.only(
                        bottom: index == event.pricingTiers.length - 1 ? 0 : 12,
                      ),
                      child: _PricingTierButton(
                        tier: event.pricingTiers[index],
                        selected: index == selectedTierIndex,
                        onTap: () => onTierSelected(index),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _TierDetailsCard(tier: selectedTier),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Semantics(
                      button: true,
                      label: 'data-test=buy-cta-${selectedTier.id}',
                      child: ElevatedButton(
                        key: ValueKey('buy-cta-${selectedTier.id}'),
                        onPressed: isCheckingOut ? null : onCheckout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentCyan,
                          foregroundColor: Colors.black,
                        ),
                        child: isCheckingOut
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'CHECKOUT',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _TrustSignals(event: event),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ═════════════════════════════════════════════════════════════════════════
/// DESKTOP LAYOUT — Three-column: story + fight card + pricing
class _DesktopLayout extends StatelessWidget {
  final PPVStorefrontEvent event;
  final PPVPricingTier selectedTier;
  final int selectedTierIndex;
  final bool isCheckingOut;
  final Function(int) onTierSelected;
  final VoidCallback onCheckout;

  const _DesktopLayout({
    required this.event,
    required this.selectedTier,
    required this.selectedTierIndex,
    required this.isCheckingOut,
    required this.onTierSelected,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Story & fight card
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.description != null) ...[
                    const _SectionTitle(title: 'Event Story'),
                    const SizedBox(height: 16),
                    _StoryCard(description: event.description!),
                    const SizedBox(height: 40),
                  ],
                  if (event.fightCard.isNotEmpty) ...[
                    const _SectionTitle(title: 'Fight Card'),
                    const SizedBox(height: 16),
                    ...event.fightCard.map(
                      (fight) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _FightCardItemDesktop(fight: fight),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 40),
          // Right: Pricing
          SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(title: 'Choose Your Access'),
                  const SizedBox(height: 20),
                  ...List<Widget>.generate(
                    event.pricingTiers.length,
                    (index) => Padding(
                      padding: EdgeInsets.only(
                        bottom: index == event.pricingTiers.length - 1 ? 0 : 14,
                      ),
                      child: _PricingTierButton(
                        tier: event.pricingTiers[index],
                        selected: index == selectedTierIndex,
                        onTap: () => onTierSelected(index),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _TierDetailsCard(tier: selectedTier),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: Semantics(
                      button: true,
                      label: 'data-test=buy-cta-${selectedTier.id}',
                      child: ElevatedButton(
                        key: ValueKey('buy-cta-${selectedTier.id}'),
                        onPressed: isCheckingOut ? null : onCheckout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentCyan,
                          foregroundColor: Colors.black,
                        ),
                        child: isCheckingOut
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'CHECKOUT ${selectedTier.priceLabel}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _TrustSignals(event: event),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ═════════════════════════════════════════════════════════════════════════
/// SHARED WIDGETS
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final String description;

  const _StoryCard({required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        description,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 15,
          height: 1.6,
        ),
      ),
    );
  }
}

class _FightCardItemMobile extends StatelessWidget {
  final PPVFightPreview fight;

  const _FightCardItemMobile({required this.fight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fight.mainTitle != null)
            Text(
              fight.mainTitle!,
              style: const TextStyle(
                color: AppTheme.accentCyan,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fight.fighter1Name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'vs',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      fight.fighter2Name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            fight.weightClass,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FightCardItemTablet extends StatelessWidget {
  final PPVFightPreview fight;

  const _FightCardItemTablet({required this.fight});

  @override
  Widget build(BuildContext context) {
    return _FightCardItemMobile(fight: fight);
  }
}

class _FightCardItemDesktop extends StatelessWidget {
  final PPVFightPreview fight;

  const _FightCardItemDesktop({required this.fight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fight.mainTitle != null)
                  Text(
                    fight.mainTitle!,
                    style: const TextStyle(
                      color: AppTheme.accentCyan,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  fight.fighter1Name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fight.weightClass,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'vs',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (fight.mainTitle != null)
                  Opacity(
                    opacity: 0,
                    child: Text(
                      fight.mainTitle!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  fight.fighter2Name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fight.weightClass,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingTierButton extends StatelessWidget {
  final PPVPricingTier tier;
  final bool selected;
  final VoidCallback onTap;

  const _PricingTierButton({
    required this.tier,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accentCyan.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppTheme.accentCyan
                : Colors.white.withValues(alpha: 0.1),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tier.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tier.priceLabel,
              style: const TextStyle(
                color: AppTheme.accentCyan,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tier.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierDetailsCard extends StatelessWidget {
  final PPVPricingTier tier;

  const _TierDetailsCard({required this.tier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tier.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...tier.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.accentCyan,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feature,
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
        ],
      ),
    );
  }
}

class _TrustSignals extends StatelessWidget {
  final PPVStorefrontEvent event;

  const _TrustSignals({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Security & Support',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          if (event.hasDrmProtection)
            const _TrustRow(
              icon: Icons.lock_outline,
              label: 'DRM Protected',
              value: 'Yes',
            ),
          if (event.hasReplayAccess)
            const _TrustRow(
              icon: Icons.replay_outlined,
              label: 'Replay Access',
              value: 'Included',
            ),
          if (event.hasMultiCam)
            const _TrustRow(
              icon: Icons.videocam_outlined,
              label: 'Multi-Camera',
              value: 'Yes',
            ),
        ],
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TrustRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentCyan, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.accentCyan,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
