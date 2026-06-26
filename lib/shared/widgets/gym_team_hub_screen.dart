import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/dfc_glass_panel.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/fighter_gym_service.dart';

class GymTeamHubScreen extends StatefulWidget {
  const GymTeamHubScreen({super.key});

  @override
  State<GymTeamHubScreen> createState() => _GymTeamHubScreenState();
}

class _GymTeamHubScreenState extends State<GymTeamHubScreen> {
  Map<String, dynamic>? _gymData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGymData();
  }

  Future<void> _fetchGymData() async {
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid != null) {
      final service = context.read<FighterGymService>();
      final data = await service.getFighterWithGym(uid);
      if (mounted) {
        setState(() {
          _gymData = data != null ? data['gyms'] : null;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Using standard TextStyles to match your AppColors and Tesla aesthetic
    const headingStyle = TextStyle(
      color: Colors.white,
      fontSize: 22,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.2,
    );

    const subheadingStyle = TextStyle(
      color: AppColors.neonCyan,
      fontSize: 14,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.5,
    );

    const bodyStyle = TextStyle(
      color: Colors.white70,
      fontSize: 13,
      height: 1.5,
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.neonBlue),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // 1. Gym Header
                    DfcGlassPanel(
                      glowColor: AppColors.neonBlue,
                      child: Row(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: AppColors.neonBlue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.neonBlue.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.shield,
                                color: AppColors.neonBlue,
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _gymData?['name'] ?? "Launceston Combat Club",
                                  style: headingStyle,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _gymData?['location'] ??
                                      "Tasmania, AUS • Est. 2024",
                                  style: bodyStyle.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildStatBadge(
                                      "Fighters: 42",
                                      AppColors.neonCyan,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildStatBadge(
                                      "Readiness: 88%",
                                      AppColors.neonGreen,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 2. AI Team Insight
                    DfcGlassPanel(
                      glowColor: AppColors.neonMagenta,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.psychology,
                                color: AppColors.neonMagenta,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text("AI TEAM INSIGHT", style: subheadingStyle),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Your pro team is peaking perfectly for the upcoming event. Team average HRV is up 12% this week. Keep sparring volume light to maintain the taper.",
                            style: bodyStyle,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 3. Team Leaderboards
                    DfcGlassPanel(
                      glowColor: AppColors.neonAmber,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "TEAM LEADERBOARDS",
                            style: subheadingStyle,
                          ),
                          const SizedBox(height: 12),
                          _buildListTile(
                            "Highest Power",
                            "Mark Lee (342 N)",
                            Icons.flash_on,
                            AppColors.neonAmber,
                          ),
                          _buildListTile(
                            "Best Recovery",
                            "Alex Cruz (92%)",
                            Icons.health_and_safety,
                            AppColors.neonGreen,
                          ),
                          _buildListTile(
                            "Most Rounds",
                            "John Smith (48 Rnds)",
                            Icons.sports_mma,
                            AppColors.neonRed,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 4. Active Roster
                    DfcGlassPanel(
                      glowColor: AppColors.neonCyan,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("ACTIVE ROSTER", style: subheadingStyle),
                          const SizedBox(height: 12),
                          _buildListTile(
                            "Coaches",
                            "3 Active",
                            Icons.assignment_ind,
                            AppColors.neonCyan,
                          ),
                          _buildListTile(
                            "Pro Fighters",
                            "8 Active",
                            Icons.star,
                            AppColors.neonMagenta,
                          ),
                          _buildListTile(
                            "Amateurs",
                            "31 Active",
                            Icons.group,
                            AppColors.neonBlue,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 5. Team Analytics Graph Placeholder
                    DfcGlassPanel(
                      glowColor: AppColors.neonGreen,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("TEAM ANALYTICS", style: subheadingStyle),
                          const SizedBox(height: 16),
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                "Live Team Telemetry Graph",
                                style: bodyStyle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildListTile(
    String title,
    String trailing,
    IconData icon,
    Color iconColor,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Text(
        trailing,
        style: TextStyle(
          color: iconColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
