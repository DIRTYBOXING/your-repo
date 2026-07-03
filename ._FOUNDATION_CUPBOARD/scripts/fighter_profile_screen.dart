import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'fighter_providers.dart';
import 'fighter_model.dart';

class FighterProfileScreen extends ConsumerWidget {
  final String fighterId;

  const FighterProfileScreen({super.key, required this.fighterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fighterAsync = ref.watch(fighterProvider(fighterId));

    return Scaffold(
      backgroundColor: const Color(0xFF050509), // Deep space background
      body: fighterAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF2E7E)),
        ),
        error: (e, st) => Center(
          child: Text(
            'Error loading fighter: $e',
            style: const TextStyle(color: Colors.white54),
          ),
        ),
        data: (fighter) {
          if (fighter == null) {
            return const Center(
              child: Text(
                'Fighter not found in the database.',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              _buildCinematicHeader(context, fighter),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGlassStatsRow(fighter),
                      const SizedBox(height: 40),
                      _buildEditorialBio(fighter),
                      const SizedBox(height: 40),
                      _buildAffiliations(context, fighter),
                      const SizedBox(height: 120), // Bottom padding for dock
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCinematicHeader(BuildContext context, Fighter fighter) {
    return SliverAppBar(
      expandedHeight: 480,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hero Image
            fighter.profileImageUrl.isNotEmpty
                ? Image.network(fighter.profileImageUrl, fit: BoxFit.cover)
                : Container(
                    color: const Color(0xFF10101A),
                    child: const Icon(
                      Icons.sports_mma,
                      size: 100,
                      color: Colors.white10,
                    ),
                  ),

            // Gradient Mask for Cinematic Fade
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black54,
                    Colors.transparent,
                    Color(0xFF050509),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),

            // Fighter Name & Nickname overlay
            Positioned(
              left: 24,
              bottom: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (fighter.nickname.isNotEmpty)
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFF2E7E), Color(0xFF00E0FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        '"${fighter.nickname.toUpperCase()}"',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '${fighter.firstName}\n${fighter.lastName}'.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                      letterSpacing: -1.5,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassStatsRow(Fighter fighter) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statColumn(
                'WINS',
                fighter.wins.toString(),
                const Color(0xFF00E676),
              ),
              _statColumn(
                'LOSSES',
                fighter.losses.toString(),
                const Color(0xFFFF4D4D),
              ),
              _statColumn('DRAWS', fighter.draws.toString(), Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            color: Color(0xFF7A7A8A),
          ),
        ),
      ],
    );
  }

  Widget _buildEditorialBio(Fighter fighter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'THE STORY',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
            color: Color(0xFFB8B8C9),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Fighting out of the ${fighter.weightClass} division, ${fighter.firstName} is currently active and pushing through the ranks. Editorial and deeper biographical context will populate here via the CMS.',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.6,
            color: Color(0xFF9A9AB5),
          ),
        ),
      ],
    );
  }

  Widget _buildAffiliations(BuildContext context, Fighter fighter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AFFILIATIONS',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
            color: Color(0xFFB8B8C9),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (fighter.gymId.isNotEmpty)
              _buildActionChip(context, 'GYM', Icons.business, () {
                context.push('/gym/${fighter.gymId}');
              }),
            if (fighter.promotionId.isNotEmpty)
              _buildActionChip(context, 'PROMOTION', Icons.campaign, () {
                context.push('/promotion/${fighter.promotionId}');
              }),
            _buildActionChip(context, 'MESSAGE', Icons.chat_bubble_outline, () {
              context.push(
                '/dm/${fighter.id}/USER123',
              ); // Assuming USER123 is current user
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildActionChip(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF10101A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF00E0FF)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
