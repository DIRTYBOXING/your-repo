import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/content_policy.dart';
import '../../../core/theme/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════════════
/// Community Standards Screen
///
/// In-app representation of DFC's family-safe, athlete-first content
/// policy. Accessible from Settings, Drawer, and onboarding flows.
/// ═══════════════════════════════════════════════════════════════════════
class CommunityStandardsScreen extends StatelessWidget {
  const CommunityStandardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(child: _buildHero()),
          SliverToBoxAdapter(child: _buildMission()),
          SliverToBoxAdapter(child: _buildProhibited()),
          SliverToBoxAdapter(child: _buildEncouraged()),
          SliverToBoxAdapter(child: _buildEnforcement()),
          SliverToBoxAdapter(child: _buildYouthProtection()),
          SliverToBoxAdapter(child: _buildCrisisSupport()),
          SliverToBoxAdapter(child: _buildReportingInfo(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────
  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppTheme.primaryBackground.withValues(alpha: 0.9),
      pinned: true,
      expandedHeight: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      title: const Row(
        children: [
          Icon(Icons.shield, color: AppTheme.neonCyan, size: 22),
          SizedBox(width: 8),
          Text(
            'Community Standards',
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

  // ── Hero Banner ───────────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D47A1), Color(0xFF1A237E)],
        ),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.neonCyan.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.verified_user,
              color: AppTheme.neonCyan,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'CLEAN • SAFE • SPORT-FIRST',
            style: TextStyle(
              color: AppTheme.neonCyan,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Family-Safe Platform',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'DataFightCentral is built for athletes, coaches, gyms, and fans.\n'
            'Everyone deserves a clean, respectful space.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Mission Statement ─────────────────────────────────────────────
  Widget _buildMission() {
    return _glassCard(
      icon: Icons.flag_rounded,
      iconColor: AppTheme.neonCyan,
      title: 'Our Mission',
      child: Text(
        ContentPolicy.platformMission,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 14,
          height: 1.6,
        ),
      ),
    );
  }

  // ── Prohibited Content ────────────────────────────────────────────
  Widget _buildProhibited() {
    return _glassCard(
      icon: Icons.block,
      iconColor: AppTheme.error,
      title: 'Zero Tolerance — Prohibited Content',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Any of the following will result in content removal '
                    'and may lead to an immediate permanent ban.',
                    style: TextStyle(
                      color: AppTheme.error.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...ContentPolicy.prohibitedCategories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cat,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
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

  // ── Encouraged Content ────────────────────────────────────────────
  Widget _buildEncouraged() {
    return _glassCard(
      icon: Icons.thumb_up_alt_rounded,
      iconColor: AppTheme.neonGreen,
      title: 'What We Encourage',
      child: Column(
        children: ContentPolicy.encouragedContent
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: AppTheme.neonGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── Enforcement Tiers ─────────────────────────────────────────────
  Widget _buildEnforcement() {
    return _glassCard(
      icon: Icons.gavel_rounded,
      iconColor: AppTheme.warning,
      title: 'Enforcement',
      child: Column(
        children: ContentPolicy.enforcementTiers.entries.map((e) {
          final colors = [
            AppTheme.warning,
            AppTheme.neonOrange,
            AppTheme.neonMagenta,
            AppTheme.error,
          ];
          final color = colors[(e.key - 1).clamp(0, 3)];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${e.key}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.value,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Youth Protection ──────────────────────────────────────────────
  Widget _buildYouthProtection() {
    return _glassCard(
      icon: Icons.child_care,
      iconColor: const Color(0xFF4FC3F7),
      title: 'Youth Protection',
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
                  color: const Color(0xFF4FC3F7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Min age: ${ContentPolicy.minimumAge}',
                  style: TextStyle(
                    color: Color(0xFF4FC3F7),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4FC3F7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Adult: ${ContentPolicy.adultAge}+',
                  style: TextStyle(
                    color: Color(0xFF4FC3F7),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ContentPolicy.youthProtectionPolicy,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Crisis Support ────────────────────────────────────────────────
  Widget _buildCrisisSupport() {
    return _glassCard(
      icon: Icons.health_and_safety,
      iconColor: AppTheme.neonGreen,
      title: 'Crisis & Support Helplines',
      child: Column(
        children: ContentPolicy.crisisHelplines.map((h) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(Icons.phone, color: AppTheme.neonGreen, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h['name']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${h['number']} — ${h['description']}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── How to Report ─────────────────────────────────────────────────
  Widget _buildReportingInfo(BuildContext context) {
    return _glassCard(
      icon: Icons.report_outlined,
      iconColor: AppTheme.neonCyan,
      title: 'How to Report',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'If you see content or behaviour that violates our standards, '
            'please report it immediately. We review every report.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _reportStep('1', 'Tap the ••• menu on any post, comment, or profile'),
          _reportStep('2', 'Select "Report" and choose a reason'),
          _reportStep('3', 'Add optional details to help our review team'),
          _reportStep('4', 'Our moderation team will review within 24 hours'),
          const SizedBox(height: 16),
          Text(
            'You can also block users from their profile page.\n'
            'Blocked users cannot see your content or message you.',
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

  Widget _reportStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.neonCyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                color: AppTheme.neonCyan,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Glass Card Helper ─────────────────────────────────────────────
  Widget _glassCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: iconColor, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
