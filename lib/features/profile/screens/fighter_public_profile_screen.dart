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
          // TODO: Build out Record, Highlights, and Recent Fights UI Components
        ],
      ),
    );
  }
}
