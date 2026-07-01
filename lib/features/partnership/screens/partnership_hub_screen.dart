import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';

// ═════════════════════════════════════════════════════════════════════════════
// DFC PARTNERSHIP HUB — FIGHTER SPONSOR · GYM MENTOR · REGISTER GYM
// ═════════════════════════════════════════════════════════════════════════════
// Three-path gateway for gym owners, fighter sponsors, and gym mentors to
// onboard into the DFC ecosystem and get branded presence on the satellite map.
// ═════════════════════════════════════════════════════════════════════════════

class PartnershipHubScreen extends StatefulWidget {
  const PartnershipHubScreen({super.key});

  @override
  State<PartnershipHubScreen> createState() => _PartnershipHubScreenState();
}

class _PartnershipHubScreenState extends State<PartnershipHubScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildHeroSection()),
          SliverToBoxAdapter(child: _buildPartnershipCards()),
          SliverToBoxAdapter(child: _buildTrustBanner()),
          SliverToBoxAdapter(child: _buildStats()),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // APP BAR
  // ─────────────────────────────────────────────────────────────────────────
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppTheme.primaryBackground,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        color: AppTheme.neonCyan,
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'DFC PARTNERSHIPS',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
          color: AppTheme.neonCyan,
        ),
      ),
      centerTitle: true,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HERO
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeroSection() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, _) => Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.neonCyan.withValues(alpha: 0.08),
              AppColors.neonMagenta.withValues(alpha: 0.04),
              Colors.white.withValues(alpha: 0.02),
            ],
          ),
          border: Border.all(
            color: AppTheme.neonCyan.withValues(
              alpha: (0.15 + _pulseCtrl.value * 0.15).clamp(0.0, 1.0),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.neonCyan.withValues(alpha: 0.08),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          children: [
            // DFC icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.neonCyan.withValues(alpha: 0.3),
                    AppColors.neonMagenta.withValues(alpha: 0.2),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonCyan.withValues(alpha: 0.3),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Icon(Icons.handshake, size: 28, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'JOIN THE NETWORK',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Partner with DFC to grow your brand, support fighters,\nand build the future of combat sports.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PARTNERSHIP CARDS — The 3 paths
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPartnershipCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildPartnerCard(
            icon: Icons.store_mall_directory,
            title: 'REGISTER YOUR GYM',
            subtitle: 'Get your gym on the DFC satellite map',
            description:
                'Your logo. Your location. Your brand — pinned on the DFC global satellite map '
                'for the entire fight community to see. Select your tier, upload your logo, '
                'and go live in 24 hours.',
            color: AppTheme.neonCyan,
            features: [
              'Logo pin on satellite map',
              'DFC Verified badge',
              'Sport & tier listing',
              'Network exposure',
            ],
            ctaText: 'REGISTER GYM',
            onTap: () => context.push('/register-gym'),
          ),
          const SizedBox(height: 16),
          _buildPartnerCard(
            icon: Icons.military_tech,
            title: 'FIGHTER SPONSOR',
            subtitle: 'Back a fighter. Build a legacy.',
            description:
                'Sponsor individual fighters or entire fight teams. Your brand gets premium '
                'placement on fighter profiles, fight cards, walkout content, and the DFC '
                'satellite map alongside your sponsored athletes.',
            color: AppColors.neonAmber,
            features: [
              'Brand on fighter profiles',
              'Map pin with sponsor badge',
              'Fight card branding',
              'ROI analytics dashboard',
            ],
            ctaText: 'BECOME A SPONSOR',
            onTap: () => context.push('/fighter-sponsor'),
          ),
          const SizedBox(height: 16),
          _buildPartnerCard(
            icon: Icons.shield,
            title: 'GYM MENTOR',
            subtitle: 'Lead. Train. Protect.',
            description:
                'Become a DFC-certified gym mentor. Train and support athletes through the '
                'Pink Diamond initiative, domestic violence recovery programs, and youth '
                'development pathways. Mentors get premium map presence and community trust badges.',
            color: Colors.pinkAccent,
            features: [
              'Pink Diamond certification',
              'Mentor profile & map pin',
              'Community trust badge',
              'Safe space verification',
            ],
            ctaText: 'APPLY AS MENTOR',
            onTap: () => context.push('/gym-mentor'),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required List<String> features,
    required String ctaText,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, _) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 20),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: color.withValues(alpha: 0.12),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Description
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // Features
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: color.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      f,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // CTA
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.withValues(alpha: 0.15),
                  foregroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: color.withValues(alpha: 0.4)),
                  ),
                  elevation: 0,
                ),
                onPressed: onTap,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      ctaText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
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

  // ─────────────────────────────────────────────────────────────────────────
  // TRUST BANNER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTrustBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            AppColors.neonPurple.withValues(alpha: 0.08),
            AppColors.neonMagenta.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified_user,
            size: 28,
            color: AppColors.neonPurple.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DFC VERIFIED PARTNERS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'All partners are manually verified by the DFC team. '
                  'We review every application within 24-48 hours to maintain network quality.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STATS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Row(
        children: [
          _buildStatCard('25+', 'GYMS\nONBOARDED', AppTheme.neonCyan),
          const SizedBox(width: 10),
          _buildStatCard('12', 'FIGHTER\nSPONSORS', AppColors.neonAmber),
          const SizedBox(width: 10),
          _buildStatCard('8', 'CERTIFIED\nMENTORS', Colors.pinkAccent),
        ],
      ),
    );
  }

  Widget _buildStatCard(String count, String label, Color color) {
    return Expanded(
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, _) => Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: color.withValues(alpha: 0.06),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
