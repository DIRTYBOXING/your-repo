import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/theme_mode.dart';
import '../../../shared/widgets/neon_card.dart';
import '../../../core/theme/theme_controller.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.neonBlue.withValues(alpha: 0.08),
                  AppColors.panel,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.neonBlue, width: 2),
                    color: AppColors.elevated,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      u?.email?.split('@').first ?? 'Fighter',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified,
                      size: 16,
                      color: AppColors.neonBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  u?.email ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _badge('Fighter'),
                    const SizedBox(width: 8),
                    _badge('Verified'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ps('Fights', '0'),
                    _ps('Record', '0-0'),
                    _ps('KOs', '0'),
                    _ps('Events', '0'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NeonCard(
            glow: ThemeController.accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.palette,
                      size: 16,
                      color: ThemeController.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Fight Camp Phase',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: ThemeController.accent,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ThemeController.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ThemeController.label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: ThemeController.accent,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: DfcThemeMode.values.map((m) {
                    final active = ThemeController.mode.value == m;
                    final c = ThemeController.accent;
                    return GestureDetector(
                      onTap: () {
                        ThemeController.setMode(m);
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? c.withValues(alpha: 0.15)
                              : AppColors.elevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: active
                                ? c.withValues(alpha: 0.5)
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          _modeLabel(m),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: active ? c : AppColors.textTertiary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...[
            ('About', Icons.info_outline),
            ('Stats & Analytics', Icons.bar_chart),
            ('Fight History', Icons.history),
            ('Media Gallery', Icons.photo_library_outlined),
            ('Sponsors', Icons.handshake_outlined),
            ('Reviews', Icons.star_outline),
            ('Verification', Icons.verified_user_outlined),
            ('Membership', Icons.card_membership),
            ('Settings', Icons.settings_outlined),
          ].map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NeonCard(
                onTap: () {
                  final messages = {
                    'About': 'Tap Edit Profile to update your bio',
                    'Stats & Analytics': 'Train and compete to build your stats',
                    'Fight History': 'Your fight record appears here as events are logged',
                    'Media Gallery': 'Upload photos and videos from your profile page',
                    'Sponsors': 'Attract sponsors by building your DFC presence',
                    'Reviews': 'Reviews from coaches and training partners appear here',
                    'Verification': 'Apply for verification once your profile is complete',
                    'Membership': 'Upgrade your plan from the Subscription page',
                    'Settings': 'Manage your account in the Settings tab',
                  };
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(messages[e.$1] ?? e.$1)),
                  );
                },
                child: Row(
                  children: [
                    Icon(e.$2, size: 20, color: AppColors.neonBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.$1,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _badge(String l) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.neonBlue.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.neonBlue.withValues(alpha: 0.3)),
    ),
    child: Text(
      l,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: AppColors.neonBlue,
      ),
    ),
  );

  static Widget _ps(String l, String v) => Column(
    children: [
      Text(
        v,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      Text(
        l,
        style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
      ),
    ],
  );

  static String _modeLabel(DfcThemeMode m) {
    switch (m) {
      case DfcThemeMode.classic:
        return 'Classic';
      case DfcThemeMode.baseCamp:
        return 'Base Camp';
      case DfcThemeMode.fightCamp:
        return 'Fight Camp';
      case DfcThemeMode.fightWeek:
        return 'Fight Week';
      case DfcThemeMode.fightDay:
        return 'Fight Day';
      case DfcThemeMode.recovery:
        return 'Recovery';
    }
  }
}
