import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/cards/dfc_card.dart';
import '../../../core/layout/dfc_layout.dart';
import '../../../core/layout/dfc_padding.dart';
import '../../admin/models/fighter_model.dart';

class FighterProfileScreen extends StatefulWidget {
  final FighterModel fighter;

  const FighterProfileScreen({super.key, required this.fighter});

  @override
  State<FighterProfileScreen> createState() => _FighterProfileScreenState();
}

class _FighterProfileScreenState extends State<FighterProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: DfcPadding(
              child: DfcLayout.constrain(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildQuickStatsRow(),
                    const SizedBox(height: 24),
                    _buildTaleOfTheTape(),
                    const SizedBox(height: 24),
                    _buildGymAndTeam(),
                    const SizedBox(height: 24),
                    _buildFightHistory(),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: const Color(0xFF05060A),
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 20, right: 24),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.fighter.nickname.isNotEmpty)
              Text(
                '"${widget.fighter.nickname.toUpperCase()}"',
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            Text(
              '${widget.fighter.firstName} ${widget.fighter.lastName}'
                  .toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.fighter.profileImageUrl.isNotEmpty)
              Image.network(widget.fighter.profileImageUrl, fit: BoxFit.cover)
            else
              Container(
                color: const Color(0xFF101320),
                child: const Center(
                  child: Icon(
                    Icons.sports_mma,
                    size: 100,
                    color: Colors.white10,
                  ),
                ),
              ),
            // Parallax Gradient Overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF05060A).withValues(alpha: 0.6),
                    const Color(0xFF05060A),
                  ],
                  stops: const [0.4, 0.8, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statBox('RECORD', '0-0-0'),
        ), // Hook up to real record later
        const SizedBox(width: 12),
        Expanded(
          child: _statBox('CLASS', widget.fighter.weightClass.toUpperCase()),
        ),
        const SizedBox(width: 12),
        Expanded(child: _statBox('RANK', 'U/R')), // Unranked
      ],
    );
  }

  Widget _statBox(String label, String value) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaleOfTheTape() {
    return DfcCard(
      height: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.straighten, color: Colors.cyanAccent, size: 18),
              SizedBox(width: 8),
              Text(
                'TALE OF THE TAPE',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _tapeStat('HEIGHT', '--'),
              _tapeStat('REACH', '--'),
              _tapeStat('STANCE', 'Orthodox'),
              _tapeStat('AGE', '--'),
            ],
          ),
          const Spacer(),
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.cyanAccent.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tapeStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildGymAndTeam() {
    return DfcCard(
      height: 120,
      glow: false,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: Colors.greenAccent,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'FIGHT CAMP',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.fighter.gymId.isNotEmpty
                      ? widget.fighter.gymId.toUpperCase()
                      : 'INDEPENDENT',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFightHistory() {
    // Placeholder for future Fight History integration
    return const SizedBox.shrink();
  }
}
