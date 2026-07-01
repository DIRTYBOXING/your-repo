import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dfc_theme.dart';
import 'auth_controller.dart'; // Adjust path if needed depending on your router's source of truth
import 'modules/settings/controllers/settings_controller.dart';

class SettingsAccountScreen extends StatefulWidget {
  const SettingsAccountScreen({super.key});

  @override
  State<SettingsAccountScreen> createState() => _SettingsAccountScreenState();
}

class _SettingsAccountScreenState extends State<SettingsAccountScreen> {
  late final SettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SettingsController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? 'fighter@datafightcentral.com';
    final userName =
        user?.displayName ?? (userEmail.split('@').first.toUpperCase());
    final avatarUrl =
        user?.photoURL ??
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(userName)}&background=00E5FF&color=000';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (_controller.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.accentCyan),
              );
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                const SizedBox(height: 32),

                // ─── 1. HEADER ───────────────────────────────────────────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'SETTINGS & ACCOUNT',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ─── 2. PROFILE HERO ─────────────────────────────────────────────
                _DfcCard(
                  height: 120,
                  glow: true,
                  glowColor: AppColors.accentCyan,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: NetworkImage(avatarUrl),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userEmail,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: AppColors.accentCyan,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ─── 3. PREFERENCES ──────────────────────────────────────────────
                _buildSectionHeader(
                  Icons.tune,
                  'PREFERENCES',
                  AppColors.accentCyan,
                ),
                _DfcCard(
                  height: 190,
                  child: Column(
                    children: [
                      _buildToggleRow(
                        title: 'Push Notifications',
                        value: _controller.settings.pushNotifications,
                        onChanged: _controller.togglePush,
                        color: AppColors.accentCyan,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(color: AppColors.border),
                      ),
                      _buildToggleRow(
                        title: 'Email Updates',
                        value: _controller.settings.emailUpdates,
                        onChanged: _controller.toggleEmail,
                        color: AppColors.accentCyan,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(color: AppColors.border),
                      ),
                      _buildNavigationRow(title: 'Theme & Appearance'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ─── 4. SECURITY & PRIVACY ───────────────────────────────────────
                _buildSectionHeader(
                  Icons.security,
                  'SECURITY',
                  AppColors.accentPurple,
                ),
                _DfcCard(
                  height: 190,
                  child: Column(
                    children: [
                      _buildToggleRow(
                        title: 'Biometric Login (Face ID)',
                        value: _controller.settings.biometricLogin,
                        onChanged: _controller.toggleBiometrics,
                        color: AppColors.accentPurple,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(color: AppColors.border),
                      ),
                      _buildNavigationRow(title: 'Change Password'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(color: AppColors.border),
                      ),
                      _buildNavigationRow(
                        title: 'Two-Factor Authentication (2FA)',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ─── 5. BILLING & SUBSCRIPTION ───────────────────────────────────
                _buildSectionHeader(
                  Icons.payment,
                  'BILLING',
                  AppColors.accentGreen,
                ),
                _DfcCard(
                  height: 130,
                  child: Column(
                    children: [
                      _buildNavigationRow(
                        title: 'Payment Methods',
                        subtitle: _controller.settings.paymentMethod,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(color: AppColors.border),
                      ),
                      _buildNavigationRow(
                        title: 'Subscription Plan',
                        subtitle: _controller.settings.subscriptionTier,
                        valueColor: AppColors.accentGreen,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // ─── 6. DANGER ZONE ──────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      // Trigger the global AuthController logout which updates GoRouter
                      authController.logout();
                    },
                    child: const Text(
                      'LOG OUT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'DELETE ACCOUNT',
                      style: TextStyle(
                        color: AppColors.accentRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── HELPER WIDGETS ────────────────────────────────────────────────────────

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

  Widget _buildToggleRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        ),
        SizedBox(
          height: 24,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
            activeTrackColor: color.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.border,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationRow({
    required String title,
    String? subtitle,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        ),
        Row(
          children: [
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(
                  color: valueColor ?? AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ],
    );
  }
}

class _DfcCard extends StatelessWidget {
  final double height;
  final bool glow;
  final Color glowColor;
  final Widget child;

  const _DfcCard({
    required this.height,
    this.glow = false,
    this.glowColor = AppColors.accentCyan,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: child,
    );
  }
}
