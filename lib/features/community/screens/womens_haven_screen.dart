import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/cards/dfc_card.dart';
import '../../../core/layout/dfc_layout.dart';
import '../../../core/layout/dfc_padding.dart';

class WomensHavenScreen extends StatelessWidget {
  const WomensHavenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: DfcPadding(
        child: DfcLayout.constrain(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.04),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              color: Colors.white.withValues(alpha: 0.6),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'DFC WOMEN\'S HAVEN',
                            style: TextStyle(
                              color: Color(0xFF00F5FF), // Neon Cyan
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Strength. Health. Confidence. Community.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 32),

                    // 1. The Essence Statement
                    _buildHeroStatement(),
                    const SizedBox(height: 24),

                    // 2. The DFC Clean Creator Economy
                    _buildSectionCard(
                      title: 'THE DFC CREATOR ECONOMY',
                      subtitle: 'Earn through discipline, not exploitation.',
                      icon: Icons.monetization_on,
                      accentColor: const Color(0xFFFFD700), // Neon Gold
                      content:
                          'The world\'s first clean fitness lifestyle economy. Women earn money for training content, coaching, nutrition, and community leadership. We pay for real work, real sweat, and real growth.',
                      actionLabel: 'START EARNING',
                      onActionTap: () => context.push('/stripe-onboarding'),
                    ),
                    const SizedBox(height: 16),

                    // 3. The DFC Ranking System
                    _buildSectionCard(
                      title: 'THE DFC RANKING SYSTEM',
                      subtitle: 'Ranked on character, not looks.',
                      icon: Icons.format_list_numbered,
                      accentColor: const Color(0xFF00FF88), // Neon Green
                      content:
                          'We disrupt the industry by ranking athletes on discipline, consistency, training hours, and community impact. This creates true role models, not just content creators.',
                      actionLabel: 'VIEW LEADERBOARDS',
                      onActionTap: () => context.push('/leaderboard'),
                    ),
                    const SizedBox(height: 16),

                    // 4. Girls' Opportunity Program
                    _buildSectionCard(
                      title: 'GIRLS\' OPPORTUNITY PROGRAM',
                      subtitle: 'Building the next generation.',
                      icon: Icons.school,
                      accentColor: const Color(0xFFFF00FF), // Neon Magenta
                      content:
                          'Providing sponsored training, safe gym environments, female coaches, and positive lifestyle guidance for young girls who need structure and confidence. We give them the opportunities they deserve.',
                      actionLabel: 'APPLY OR NOMINATE',
                    ),
                    const SizedBox(height: 24),

                    // 5. Training, Health & Fashion Hubs
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildGridCard(
                            title: 'TRAINING HAVEN',
                            icon: Icons.sports_mma,
                            accentColor: const Color(0xFFFF3366), // Neon Red
                            content:
                                'Empowering, confidence-building, community-driven. No judgement, just real work.',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildGridCard(
                            title: 'BEAUTY OF HEALTH',
                            icon: Icons.spa,
                            accentColor: const Color(0xFF00F5FF), // Neon Cyan
                            content:
                                'Defined by clean eating, discipline, recovery, and natural mental strength.',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildGridCard(
                            title: 'ATHLETIC FASHION',
                            icon: Icons.checkroom,
                            accentColor: const Color(0xFFD500F9), // Neon Purple
                            content:
                                'Respectful, non-sexual, athlete-focused style for the real world.',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // 6. Transformation Stories (The Core of the Mission)
                    _buildTransformationStories(),
                    const SizedBox(height: 32),

                    // 7. DFC Women's Safety Code
                    _buildSectionCard(
                      title: 'THE SAFETY CODE',
                      subtitle: 'Non-negotiable protection.',
                      icon: Icons.shield,
                      accentColor: const Color(0xFF00E5FF), // Neon Cyan
                      content:
                          'DFC will never allow sexual content, explicit posing, exploitation, or harassment. This is a family-safe, clean, and respectful platform built to empower athletes, not objectify them.',
                    ),
                    const SizedBox(height: 16),

                    // 8. Community & Support
                    _buildSectionCard(
                      title: 'WOMEN\'S COMMUNITY',
                      subtitle: 'Connect, learn, and grow.',
                      icon: Icons.people_alt,
                      accentColor: const Color(0xFFFFD700), // Neon Gold
                      content:
                          'A positive space to share journeys, find mentors, and support each other through life and combat sports.',
                      actionLabel: 'JOIN THE NETWORK',
                    ),
                    const SizedBox(height: 32),

                    // 9. The DFC Promise
                    _buildPromiseCard(),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroStatement() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF00F5FF).withValues(alpha: 0.1),
                const Color(0xFFFF00FF).withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00F5FF).withValues(alpha: 0.2)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '❝ Beauty is built, not bought.\nStrength is earned, not exposed.\nConfidence is created through discipline, not attention. ❞',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required String content,
    required IconData icon,
    required Color accentColor,
    String? actionLabel,
    VoidCallback? onActionTap,
  }) {
    return DfcCard(
      height: actionLabel != null ? 200 : 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
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
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (actionLabel != null) ...[
            const Spacer(),
            GestureDetector(
              onTap: onActionTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  actionLabel,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGridCard({
    required String title,
    required String content,
    required IconData icon,
    required Color accentColor,
  }) {
    return DfcCard(
      height: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransformationStories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_graph, color: Color(0xFFFF3366), size: 20),
            SizedBox(width: 12),
            Text(
              'TRANSFORMATION STORIES',
              style: TextStyle(
                color: Color(0xFFFF3366),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Real athletes rising from nothing. Told with dignity, respect, and privacy.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildStoryChip(
                'Addiction to Elite',
                'Sarah M.',
                const Color(0xFFFF3366),
              ),
              const SizedBox(width: 12),
              _buildStoryChip(
                'A Mother\'s Return',
                'Elena T.',
                const Color(0xFF00F5FF),
              ),
              const SizedBox(width: 12),
              _buildStoryChip(
                'Finding Confidence',
                'Maya K.',
                const Color(0xFFFF00FF),
              ),
              const SizedBox(width: 12),
              _buildStoryChip(
                'From the Streets',
                'Anonymous',
                const Color(0xFFFFD700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStoryChip(String title, String name, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_fill, color: color, size: 28),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromiseCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E17),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_user, color: Colors.white54, size: 32),
          const SizedBox(height: 16),
          const Text(
            'THE DFC PROMISE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We pay women for their qualities — discipline, strength, health, and character.\n\nNever for exploitation.\nNever for compromise.\nNever for anything that harms dignity.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
