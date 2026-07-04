import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/dfc_glass_panel.dart';
import '../services/profile_service.dart';

class FighterPublicProfileScreen extends StatefulWidget {
  final String fighterId;

  const FighterPublicProfileScreen({super.key, this.fighterId = 'demo_id'});

  @override
  State<FighterPublicProfileScreen> createState() =>
      _FighterPublicProfileScreenState();
}

class _FighterPublicProfileScreenState
    extends State<FighterPublicProfileScreen> {
  final _profileService = ProfileService();
  Map<String, dynamic>? _fighterData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPublicProfile();
  }

  Future<void> _loadPublicProfile() async {
    final data = await _profileService.getPublicFighterProfile(
      widget.fighterId,
    );
    if (mounted) {
      setState(() {
        _fighterData = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.neonMagenta),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          DfcGlassPanel(
            glowColor: AppColors.neonMagenta,
            child: Center(
              child: Text(
                _fighterData?['displayName'] ?? 'Unknown Fighter',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          DfcGlassPanel(
            glowColor: AppColors.neonCyan,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              key: const ValueKey('fighter_stats_panel'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FIGHT RECORD & HISTORY',
                    style: TextStyle(
                      color: AppColors.neonCyan,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(
                        'WINS',
                        _fighterData?['wins']?.toString() ?? '0',
                      ),
                      _buildStatColumn(
                        'LOSSES',
                        _fighterData?['losses']?.toString() ?? '0',
                      ),
                      _buildStatColumn(
                        'DRAWS',
                        _fighterData?['draws']?.toString() ?? '0',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'RECENT FIGHT HIGHLIGHTS',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _fighterData?['highlights'] ??
                        'No highlights recorded yet.',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
