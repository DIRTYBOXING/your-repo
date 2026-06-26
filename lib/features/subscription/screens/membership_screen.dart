import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════════════
/// DFC Membership Screen
///
/// Three tiers: Free, Gold (verified), Diamond (verified + paid)
/// Gold = Identity verified (driver's licence / govt ID)
/// Diamond = Identity verified + active paid subscription
/// ═══════════════════════════════════════════════════════════════════════
class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key});

  static const _gold = Color(0xFFFFD700);
  static const _diamond = Color(0xFFB9F2FF);
  static const _free = Color(0xFF8E8E93);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(child: _buildHero()),
          SliverToBoxAdapter(
            child: _buildTierCard(
              tierName: 'FREE',
              color: _free,
              icon: Icons.person,
              price: 'Free forever',
              badge: null,
              features: const [
                'Basic profile & community feed',
                'Crisis support access 24/7',
                'Find nearby gyms',
                '5 AI Coach interactions/day',
                'Safety alerts',
                'Basic health tracking',
              ],
              buttonLabel: 'Current Plan',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You are on the Free plan')),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: _buildTierCard(
              tierName: 'GOLD',
              color: _gold,
              icon: Icons.verified,
              price: 'Free with ID verification',
              badge: '★ VERIFIED',
              features: const [
                'Everything in Free',
                'Gold verified badge on profile',
                'Trusted account status',
                'Priority in search & discovery',
                'Protection against impersonators',
                'Enhanced community trust score',
                'Destroys fake / spam accounts',
              ],
              buttonLabel: 'Get Verified',
              onTap: () => context.push('/identity-verification'),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildTierCard(
              tierName: 'DIAMOND',
              color: _diamond,
              icon: Icons.diamond,
              price: 'From \$0.99/month',
              badge: '◆ ELITE',
              features: const [
                'Everything in Gold',
                'Diamond badge on profile',
                'Unlimited AI Coach',
                'Full training analytics',
                'Fight recommendations',
                'Weight cut tracker',
                'Recovery insights',
                'Priority signal feed',
                'Export PDF reports',
                'Team management (Coach tier)',
                'Event creation (Promoter tier)',
              ],
              buttonLabel: 'Upgrade to Diamond',
              onTap: () => context.push('/plans'),
            ),
          ),
          SliverToBoxAdapter(child: _buildComparisonTable()),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppTheme.primaryBackground.withValues(alpha: 0.9),
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      title: const Row(
        children: [
          Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 22),
          SizedBox(width: 8),
          Text(
            'Membership',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        border: Border.all(color: _gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person, color: _free, size: 32),
              SizedBox(width: 16),
              Icon(Icons.verified, color: _gold, size: 36),
              SizedBox(width: 16),
              Icon(Icons.diamond, color: _diamond, size: 32),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'FREE • GOLD • DIAMOND',
            style: TextStyle(
              color: _gold,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose Your Level',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gold = Verified with ID. Diamond = Verified + Paid.\n'
            'No fakes. No spam. Real people only.',
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

  Widget _buildTierCard({
    required String tierName,
    required Color color,
    required IconData icon,
    required String price,
    required String? badge,
    required List<String> features,
    required String buttonLabel,
    required VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      tierName,
                      style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: color.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                ...features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: color, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            f,
                            style: const TextStyle(
                              color: Colors.white,
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
                  height: 46,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: onTap != null
                          ? color
                          : color.withValues(alpha: 0.3),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      buttonLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Comparison',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          _compRow('Feature', 'Free', 'Gold', 'Diamond', isHeader: true),
          _compRow('Profile', '✓', '✓', '✓'),
          _compRow('Verified Badge', '✗', '★', '◆'),
          _compRow('AI Coach', '5/day', '5/day', '∞'),
          _compRow('Analytics', 'Basic', 'Basic', 'Full'),
          _compRow('Priority Search', '✗', '✓', '✓'),
          _compRow('Export Reports', '✗', '✗', '✓'),
          _compRow('Team Mgmt', '✗', '✗', '✓'),
          _compRow('Fake Protection', '✗', '✓', '✓'),
        ],
      ),
    );
  }

  Widget _compRow(
    String feature,
    String free,
    String gold,
    String diamond, {
    bool isHeader = false,
  }) {
    final style = TextStyle(
      color: isHeader ? AppTheme.neonCyan : Colors.white,
      fontSize: 12,
      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(feature, style: style)),
          Expanded(
            child: Text(
              free,
              style: style.copyWith(color: isHeader ? style.color : _free),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              gold,
              style: style.copyWith(color: isHeader ? style.color : _gold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              diamond,
              style: style.copyWith(color: isHeader ? style.color : _diamond),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
