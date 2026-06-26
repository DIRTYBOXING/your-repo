import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/dfc_glass_panel.dart';
import '../../../shared/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  Map<String, dynamic>? _profileData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await _profileService.getCurrentUserProfile();
    if (mounted) {
      setState(() {
        _profileData = data;
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
          child: CircularProgressIndicator(color: AppColors.neonCyan),
        ),
      );
    }

    final user = _profileData?['user'] ?? {};
    final fighter = _profileData?['fighter'] ?? {};
    final currentUid = context.read<AuthService>().currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'CONTROL CENTER',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          DfcGlassPanel(
            accent: AppColors.neonCyan,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['displayName'] ?? 'Fighter Name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  fighter['weightClass'] ?? 'Weight Class',
                  style: const TextStyle(
                    color: AppColors.neonCyan,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.sensors, color: AppColors.neonBlue),
            title: const Text(
              'Manage Devices',
              style: TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: () => context.push('/devices'),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(
              Icons.account_balance_wallet,
              color: AppColors.neonGreen,
            ),
            title: const Text(
              'Wallet & Earnings',
              style: TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: () {
              if (currentUid != null)
                context.push('/finance/fighter/$currentUid');
            },
          ),
        ],
      ),
    );
  }
}
