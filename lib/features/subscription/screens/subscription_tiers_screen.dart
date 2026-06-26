// ═══════════════════════════════════════════════════════════════════════════
// DFC SUBSCRIPTION TIERS SCREEN
// ═══════════════════════════════════════════════════════════════════════════
// Beautiful tier comparison with upgrade flow
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../../core/constants/stripe_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/subscription_tiers_service.dart';

class SubscriptionTiersScreen extends StatefulWidget {
  const SubscriptionTiersScreen({super.key});

  @override
  State<SubscriptionTiersScreen> createState() =>
      _SubscriptionTiersScreenState();
}

class _SubscriptionTiersScreenState extends State<SubscriptionTiersScreen> {
  bool _isYearly = true;
  int _selectedIndex = 1; // Default to Warrior (most popular)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Choose Your Plan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Billing toggle
          _buildBillingToggle(),

          const SizedBox(height: 16),

          // Tier cards carousel
          Expanded(
            child: PageView.builder(
              controller: PageController(
                viewportFraction: 0.85,
                initialPage: _selectedIndex,
              ),
              onPageChanged: (index) {
                setState(() => _selectedIndex = index);
              },
              itemCount: SubscriptionTiersService.tiers.length,
              itemBuilder: (context, index) {
                final tier = SubscriptionTiersService.tiers[index];
                return _buildTierCard(tier, index == _selectedIndex);
              },
            ),
          ),

          // CTA button
          _buildCTAButton(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYearly = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isYearly ? AppTheme.neonCyan : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Monthly',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !_isYearly ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYearly = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isYearly ? AppTheme.neonCyan : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Yearly',
                      style: TextStyle(
                        color: _isYearly ? Colors.black : Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_isYearly) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Save 17%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard(SubscriptionTierDef tier, bool isSelected) {
    final color = Color(int.parse(tier.colorHex.replaceFirst('#', '0xFF')));
    final price = _isYearly ? tier.yearlyPrice / 12 : tier.monthlyPrice;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: isSelected ? 8 : 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.3), AppTheme.surfaceDark],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? color : Colors.white24,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(tier.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier.name,
                        style: TextStyle(
                          color: color,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        tier.tagline,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (tier.tier == SubscriptionTier.warrior)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'POPULAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!tier.isFree) ...[
                  Text(
                    '\$',
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    price.toStringAsFixed(2),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  Text(
                    '/mo',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                ] else ...[
                  const Text(
                    'FREE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),

            if (_isYearly && !tier.isFree) ...[
              const SizedBox(height: 4),
              Text(
                'Billed \$${tier.yearlyPrice.toStringAsFixed(2)}/year',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],

            const SizedBox(height: 6),
            Text(
              'For ${tier.targetAudience}',
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),

            const Divider(color: Colors.white24, height: 32),

            // Features
            ...tier.highlights.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, color: color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          color: Colors.white,
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
  }

  Widget _buildCTAButton() {
    final selectedTier = SubscriptionTiersService.tiers[_selectedIndex];
    final color = Color(
      int.parse(selectedTier.colorHex.replaceFirst('#', '0xFF')),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _handleSubscribe(selectedTier),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: color.withValues(alpha: 0.5),
              ),
              child: Text(
                selectedTier.isFree
                    ? 'Continue with Free'
                    : 'Subscribe to ${selectedTier.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            selectedTier.isFree
                ? 'Unlimited access to basic features'
                : 'Cancel anytime • 7-day free trial',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubscribe(SubscriptionTierDef tier) {
    if (tier.isFree) {
      Navigator.pop(context);
      return;
    }

    // Show Stripe checkout (placeholder)
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _buildCheckoutSheet(tier),
    );
  }

  Widget _buildCheckoutSheet(SubscriptionTierDef tier) {
    final color = Color(int.parse(tier.colorHex.replaceFirst('#', '0xFF')));
    final price = _isYearly ? tier.yearlyPrice : tier.monthlyPrice;

    return Container(
      padding: const EdgeInsets.all(24),
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
          const SizedBox(height: 24),

          Text(
            '${tier.emoji} ${tier.name} Plan',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            '\$${price.toStringAsFixed(2)} ${_isYearly ? "/year" : "/month"}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          // Payment methods
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPaymentMethod('Apple Pay', Icons.apple),
              const SizedBox(width: 16),
              _buildPaymentMethod('Google Pay', Icons.g_mobiledata),
              const SizedBox(width: 16),
              _buildPaymentMethod('Card', Icons.credit_card),
            ],
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                // Map tier to Stripe Payment Link
                String? link;
                switch (tier.tier) {
                  case SubscriptionTier.warrior:
                    link = _isYearly
                        ? DfcStripeLinks.fighterProYearly
                        : DfcStripeLinks.fighterProMonthly;
                    break;
                  case SubscriptionTier.coach:
                    link = _isYearly
                        ? DfcStripeLinks.coachMentorYearly
                        : DfcStripeLinks.coachMentorMonthly;
                    break;
                  case SubscriptionTier.gym:
                  case SubscriptionTier.promoter:
                    link = _isYearly
                        ? DfcStripeLinks.promoterGymYearly
                        : DfcStripeLinks.promoterGymMonthly;
                    break;
                  case SubscriptionTier.free:
                    link = null;
                    break;
                }
                if (link != null) {
                  DfcStripeLinks.openPaymentLink(link);
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      tier.isFree
                          ? 'Free plan activated!'
                          : 'Opening ${tier.name} checkout...',
                    ),
                    backgroundColor: color,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Start 7-Day Free Trial',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Secure payment powered by Stripe',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}
