import 'package:flutter/material.dart';
import 'api_service.dart';
import 'blue/controllers/growth_controller.dart';
import 'blue/models/growth_model.dart';
import 'blue/repositories/growth_repository.dart';
import 'blue/state/growth_state.dart';

class GrowthDashboardScreen extends StatefulWidget {
  const GrowthDashboardScreen({super.key});

  @override
  State<GrowthDashboardScreen> createState() => _GrowthDashboardScreenState();
}

class _GrowthDashboardScreenState extends State<GrowthDashboardScreen> {
  late final GrowthController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GrowthController(repo: GrowthRepository(api: ApiService()))
      ..loadGrowthData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleClaim(MissionModel mission) async {
    if (mission.status == 'CLAIMABLE') {
      await _controller.claimReward(mission.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '+${mission.rewardTokens} DFC TOKENS CLAIMED',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.amberAccent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // ─── 1. HEADER ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'REWARDS & MISSIONS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── 2. STATE BUILDER ────────────────────────────────────────────
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  final state = _controller.state;
                  if (state is GrowthInitial || state is GrowthLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.amberAccent,
                      ),
                    );
                  }
                  if (state is GrowthError) {
                    return Center(
                      child: Text(
                        'Error: ${state.message}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }
                  if (state is GrowthLoaded) {
                    return _buildContent(state.data);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(GrowthDataModel data) {
    return RefreshIndicator(
      onRefresh: _controller.loadGrowthData,
      color: Colors.amberAccent,
      backgroundColor: const Color(0xFF0A0E17),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        children: [
          // ─── DAILY STREAK HERO ───────────────────────────────────────────
          _buildSectionHeader(
            Icons.local_fire_department,
            'DAILY ACTIVITY',
            Colors.orangeAccent,
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E17),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.orangeAccent.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'CURRENT STREAK',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.orangeAccent,
                      size: 48,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${data.streakDays}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'DAYS',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: data.streakDays / data.nextMilestone,
                    backgroundColor: Colors.white10,
                    color: Colors.orangeAccent,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${data.nextMilestone - data.streakDays} Days until ${data.milestoneReward} DFC Token Bonus',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ─── ACTIVE MISSIONS ─────────────────────────────────────────────
          _buildSectionHeader(
            Icons.military_tech,
            'DAILY BOUNTIES',
            Colors.amberAccent,
          ),
          ...data.missions.map((mission) => _buildMissionCard(mission)),
          const SizedBox(height: 16),

          // ─── REFERRAL ENGINE ─────────────────────────────────────────────
          _buildSectionHeader(
            Icons.group_add,
            'INVITE & EARN',
            Colors.cyanAccent,
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E17),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'YOUR DFC LINK',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${data.totalReferrals} REFERRALS',
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'dfc.tv/join/${data.referralCode}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(
                        Icons.copy,
                        color: Colors.cyanAccent,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Invite a friend to DFC. When they buy their first PPV or Vault Pass, you both get 1,000 DFC Tokens.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text(
                      'SHARE LINK',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(MissionModel mission) {
    bool isClaimable = mission.status == 'CLAIMABLE';
    bool isCompleted = mission.status == 'COMPLETED';
    Color statusColor = isClaimable
        ? Colors.amberAccent
        : (isCompleted ? Colors.greenAccent : Colors.white24);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isClaimable
            ? Colors.amberAccent.withValues(alpha: 0.05)
            : const Color(0xFF0A0E17),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isClaimable
              ? Colors.amberAccent.withValues(alpha: 0.5)
              : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.toll,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mission.description,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Text(
                  '+${mission.rewardTokens} TOKENS',
                  style: TextStyle(
                    color: isCompleted ? Colors.white38 : Colors.amberAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (isClaimable)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
              ),
              onPressed: () => _handleClaim(mission),
              child: const Text(
                'CLAIM',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            )
          else if (isCompleted)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'CLAIMED',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'INCOMPLETE',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
