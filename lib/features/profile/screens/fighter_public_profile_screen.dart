import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_panel.dart';
import '../../../core/theme/glow_effects.dart';
import '../../../shared/widgets/dfc_network_image.dart';
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

    final displayName = _fighterData?['displayName'] ?? 'Unknown Fighter';
    final coverImage = _firstAvailableField(const [
      'pageCoverUrl',
      'pageBannerUrl',
      'coverPhotoUrl',
      'bannerUrl',
    ]);
    final avatarImage = _firstAvailableField(const [
      'pageAvatarUrl',
      'photoUrl',
      'photoURL',
    ]);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          GlassPanel(
            padding: EdgeInsets.zero,
            backgroundColor: AppColors.glassMedium,
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            borderColor: AppColors.neonMagenta.withValues(alpha: 0.3),
            shadows: NeonGlow.mediumMagenta(),
            child: Column(
              children: [
                if (coverImage != null && coverImage.isNotEmpty)
                  DfcNetworkImage(
                    url: coverImage,
                    width: double.infinity,
                    height: 140,
                    fit: BoxFit.cover,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  )
                else
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.neonMagenta.withValues(alpha: 0.2),
                          AppColors.neonCyan.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -36),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.neonCyan.withValues(alpha: 0.75),
                              width: 2,
                            ),
                            boxShadow: NeonGlow.mediumCyan(),
                          ),
                          child: ClipOval(
                            child: avatarImage != null && avatarImage.isNotEmpty
                                ? DfcNetworkImage(
                                    url: avatarImage,
                                    width: 84,
                                    height: 84,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 84,
                                    height: 84,
                                    color: AppColors.surfaceElevated,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.person,
                                      size: 36,
                                      color: AppColors.neonCyan,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        displayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            accentColor: AppColors.neonCyan,
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
                    children: [
                      _buildStatColumn(
                        'WINS',
                        _fighterData?['wins']?.toString() ?? '0',
                      ),
                      const SizedBox(width: 12),
                      _buildStatColumn(
                        'LOSSES',
                        _fighterData?['losses']?.toString() ?? '0',
                      ),
                      const SizedBox(width: 12),
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

  String? _firstAvailableField(List<String> keys) {
    for (final key in keys) {
      final value = _fighterData?[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  Widget _buildStatColumn(String label, String value) {
    return Expanded(
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        backgroundColor: AppColors.neonCyan.withValues(alpha: 0.06),
        borderColor: AppColors.neonCyan.withValues(alpha: 0.22),
        shadows: NeonGlow.softCyan(),
        child: Column(
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
        ),
      ),
    );
  }
}
