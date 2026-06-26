import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/dfc_themes.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/account_deletion_service.dart';
import '../../../shared/services/data_export_service.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import '../services/settings_service.dart';

import '../../../shared/services/localization_service.dart';

// ═══════════════════════════════════════════════════════════════════
//  SETTINGS COMMAND CENTER v2.0
//  Dark themed · Neon accents · Grouped sections
// ═══════════════════════════════════════════════════════════════════

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _goBackSafely() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/home');
  }

  @override
  void initState() {
    super.initState();
    // Optionally, load saved hydration settings here
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                children: [
                  // ── Profile Card ──
                  _buildProfileCard(),
                  const SizedBox(height: 24),

                  // ── Content Mode ──
                  _sectionLabel('CONTENT MODE', Icons.family_restroom),
                  const SizedBox(height: 6),
                  _buildContentModeSelector(settings),
                  const SizedBox(height: 20),

                  // ── Account ──
                  _sectionLabel('ACCOUNT', Icons.person),
                  const SizedBox(height: 6),
                  _menuItem(
                    Icons.person_outline,
                    'Edit Profile',
                    DesignTokens.neonCyan,
                    () => context.push('/profile/edit'),
                  ),
                  _menuItem(
                    Icons.lock_outline,
                    'Change Password',
                    DesignTokens.neonCyan,
                    _showChangePasswordDialog,
                  ),
                  _menuItem(
                    Icons.alternate_email,
                    'Change Email',
                    DesignTokens.neonCyan,
                    _showChangeEmailDialog,
                  ),
                  _menuItem(
                    Icons.email_outlined,
                    'Email Preferences',
                    DesignTokens.neonCyan,
                    _showEmailPreferencesDialog,
                  ),
                  _menuItem(
                    Icons.verified,
                    'Identity Verification',
                    DesignTokens.neonGold,
                    () => context.push('/identity-verification'),
                    trailing: _badge('Get Verified', DesignTokens.neonGold),
                  ),
                  _menuItem(
                    Icons.workspace_premium,
                    'Membership',
                    DesignTokens.neonMagenta,
                    () => context.push('/membership'),
                    trailing: _badge(
                      'Free / Gold / Diamond',
                      DesignTokens.neonMagenta,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Notifications ──
                  _sectionLabel('NOTIFICATIONS', Icons.notifications),
                  const SizedBox(height: 6),
                  _menuItem(
                    Icons.notifications_active,
                    'Notification Preferences',
                    DesignTokens.neonAmber,
                    () => context.push('/notification-settings'),
                  ),
                  _switchItem(
                    Icons.notifications_outlined,
                    'Push Notifications',
                    'Receive push notifications',
                    DesignTokens.neonAmber,
                    settings.notificationsEnabled,
                    settings.setNotifications,
                  ),
                  _switchItem(
                    Icons.mail_outline,
                    'Email Notifications',
                    'Receive email updates',
                    DesignTokens.neonAmber,
                    settings.emailNotifications,
                    settings.setEmailNotifications,
                  ),
                  const SizedBox(height: 20),

                  // ── Appearance ──
                  _sectionLabel('APPEARANCE', Icons.palette),
                  const SizedBox(height: 6),
                  _menuItem(
                    Icons.palette_outlined,
                    'Theme Mode',
                    DesignTokens.neonMagenta,
                    () => _showThemePicker(settings),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: settings.themeMode.previewAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          settings.themeMode.label,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Builder(
                    builder: (ctx) {
                      final loc = ctx.watch<LocalizationService>();
                      final info = loc.getCurrentLocaleInfo();
                      return _menuItem(
                        Icons.language,
                        'Language',
                        DesignTokens.neonMagenta,
                        _showLanguageDialog,
                        trailing: Text(
                          '${info.flag} ${info.nativeName}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Sensory & Haptics ──
                  _sectionLabel(
                      'SENSORY & HAPTICS', Icons.vibration),
                  const SizedBox(height: 6),
                  _switchItem(
                    Icons.flash_on,
                    'Hardcore Mode',
                    'Full haptics, strobes & fire effects during fights',
                    DesignTokens.neonRed,
                    settings.isHardcoreMode,
                    (v) => settings.setSensoryMode(
                        v ? 'hardcore' : 'standard'),
                  ),
                  const SizedBox(height: 20),

                  // ── Billing ──
                  _sectionLabel('BILLING & SUBSCRIPTION', Icons.receipt_long),
                  const SizedBox(height: 6),
                  _menuItem(
                    Icons.receipt_long,
                    'Billing History',
                    DesignTokens.neonGreen,
                    () => context.push('/billing-history'),
                  ),
                  _menuItem(
                    Icons.card_membership,
                    'Manage Subscription',
                    DesignTokens.neonGreen,
                    () => context.push('/subscription'),
                  ),
                  const SizedBox(height: 20),

                  // ── Privacy ──
                  _sectionLabel('PRIVACY & SECURITY', Icons.shield),
                  const SizedBox(height: 6),
                  _menuItem(
                    Icons.privacy_tip_outlined,
                    'Privacy Settings',
                    DesignTokens.neonRed,
                    () => context.push('/privacy'),
                  ),
                  _menuItem(
                    Icons.security,
                    'Security Settings',
                    DesignTokens.neonAmber,
                    () => context.push('/security-settings'),
                  ),
                  _menuItem(
                    Icons.history,
                    'Login Activity',
                    DesignTokens.neonCyan,
                    () => context.push('/login-activity'),
                  ),
                  _menuItem(
                    Icons.account_circle,
                    'Account Recovery',
                    DesignTokens.neonGreen,
                    () => context.push('/account-recovery'),
                  ),
                  _menuItem(
                    Icons.shield,
                    'Community Standards',
                    DesignTokens.neonRed,
                    () => context.push('/community-standards'),
                  ),
                  _menuItem(
                    Icons.block,
                    'Blocked Users',
                    DesignTokens.neonRed,
                    () => context.push('/blocked-users'),
                  ),
                  _switchItem(
                    Icons.analytics_outlined,
                    'Analytics',
                    'Help improve the app with usage data',
                    DesignTokens.neonRed,
                    settings.analyticsEnabled,
                    settings.setAnalytics,
                  ),
                  _menuItem(
                    Icons.file_download,
                    'Export Fight Data',
                    DesignTokens.neonCyan,
                    _showDataExportDialog,
                  ),
                  _menuItem(
                    Icons.delete_outline,
                    'Delete Account',
                    DesignTokens.neonRed,
                    _showDeleteAccountDialog,
                    isDestructive: true,
                  ),
                  const SizedBox(height: 20),

                  // ── About ──
                  _sectionLabel('ABOUT', Icons.info_outline),
                  const SizedBox(height: 6),
                  _menuItem(
                    Icons.info_outline,
                    'About DataFight',
                    DesignTokens.neonCyan,
                    _showAboutDialog,
                  ),
                  _menuItem(
                    Icons.description_outlined,
                    'Terms of Service',
                    DesignTokens.neonCyan,
                    () => context.push('/terms-of-service'),
                  ),
                  _menuItem(
                    Icons.shield_outlined,
                    'Privacy Policy',
                    DesignTokens.neonCyan,
                    () => context.push('/privacy-policy'),
                  ),
                  _menuItem(
                    Icons.code,
                    'App Version',
                    DesignTokens.neonCyan,
                    _showVersionInfo,
                    trailing: Text(
                      '2.6.0',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Help & Support ──
                  _sectionLabel('HELP & SUPPORT', Icons.support),
                  const SizedBox(height: 6),
                  _menuItem(
                    Icons.help_center,
                    'Help Center',
                    DesignTokens.neonGreen,
                    () => context.push('/help-center'),
                  ),
                  _menuItem(
                    Icons.bug_report_outlined,
                    'Report a Problem',
                    DesignTokens.neonGreen,
                    () => context.push('/help-center'),
                  ),
                  _menuItem(
                    Icons.contact_mail_outlined,
                    'Contact Admin',
                    DesignTokens.neonGreen,
                    () => context.push('/help-center'),
                  ),
                  const SizedBox(height: 24),

                  // ── Sign Out ──
                  GestureDetector(
                    onTap: _showLogoutDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: DesignTokens.neonRed.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: DesignTokens.neonRed.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout,
                            color: DesignTokens.neonRed,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Sign Out',
                            style: TextStyle(
                              color: DesignTokens.neonRed,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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

  // ═══════════════════════════════════════════════════════════════
  //  PROFILE CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildProfileCard() {
    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    final displayName = user?.displayName ?? 'Fighter';
    final email = user?.email ?? 'Set up your profile';
    final photoUrl = user?.photoURL;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.neonCyan.withValues(alpha: 0.08),
            DesignTokens.neonMagenta.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          // ── Avatar with gradient ring ──
          GestureDetector(
            onTap: () => context.push('/profile/edit'),
            child: Stack(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.5),
                    child: DfcCircleAvatar(
                      imageUrl: photoUrl,
                      radius: 31,
                      backgroundColor: DesignTokens.bgPrimary,
                      fallbackText: displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'F',
                      fallbackIconColor: DesignTokens.neonCyan,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: DesignTokens.neonCyan,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: DesignTokens.bgPrimary,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.black,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // ── Name / Email / Edit button ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => context.push('/profile/edit'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit,
                          color: DesignTokens.neonCyan,
                          size: 12,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'EDIT PROFILE',
                          style: TextStyle(
                            color: DesignTokens.neonCyan,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: DesignTokens.neonCyan.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            onPressed: _goBackSafely,
          ),
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
            ).createShader(r),
            child: const Text(
              'SETTINGS',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          Icon(
            Icons.settings,
            color: DesignTokens.neonCyan.withValues(alpha: 0.3),
            size: 22,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  CONTENT MODE SELECTOR — Standard vs 18+
  // ═══════════════════════════════════════════════════════════════

  Widget _buildContentModeSelector(SettingsService settings) {
    final isAdult = settings.isAdultMode;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAdult
              ? [
                  const Color(0xFFFF0080).withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.02),
                ]
              : [
                  const Color(0xFF00E676).withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAdult
              ? const Color(0xFFFF0080).withValues(alpha: 0.25)
              : const Color(0xFF00E676).withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAdult ? Icons.shield : Icons.family_restroom,
                color: isAdult
                    ? const Color(0xFFFF0080)
                    : const Color(0xFF00E676),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAdult ? '18+ FULL MODE' : 'STANDARD MODE',
                      style: TextStyle(
                        color: isAdult
                            ? const Color(0xFFFF0080)
                            : const Color(0xFF00E676),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAdult
                          ? 'Full intensity feed — all sanctioned sport content'
                          : 'Lighter view for users who prefer less intense fight content',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => settings.setContentMode('family'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !isAdult
                          ? const Color(0xFF00E676).withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !isAdult
                            ? const Color(0xFF00E676).withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.family_restroom,
                          color: !isAdult
                              ? const Color(0xFF00E676)
                              : Colors.white.withValues(alpha: 0.3),
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'STANDARD',
                          style: TextStyle(
                            color: !isAdult
                                ? const Color(0xFF00E676)
                                : Colors.white.withValues(alpha: 0.3),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _confirmAdultMode(settings),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isAdult
                          ? const Color(0xFFFF0080).withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isAdult
                            ? const Color(0xFFFF0080).withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.shield,
                          color: isAdult
                              ? const Color(0xFFFF0080)
                              : Colors.white.withValues(alpha: 0.3),
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '18+',
                          style: TextStyle(
                            color: isAdult
                                ? const Color(0xFFFF0080)
                                : Colors.white.withValues(alpha: 0.3),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmAdultMode(SettingsService settings) {
    if (settings.isAdultMode) return; // Already in adult mode
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1B2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.shield, color: Color(0xFFFF0080), size: 22),
            SizedBox(width: 8),
            Text(
              'Switch To Full Mode?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: const Text(
          'This enables full-intensity combat sports viewing.\n\n'
          'All content is sanctioned sport and educational. '
          'If you have a weak stomach, stay on Standard mode. '
          'Confirm you are 18 years or older to continue.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0080),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              settings.setContentMode('18plus');
              Navigator.pop(ctx);
            },
            child: const Text(
              'I\'m 18+, Full Mode',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  REUSABLE WIDGETS
  // ═══════════════════════════════════════════════════════════════

  Widget _sectionLabel(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Row(
        children: [
          Icon(icon, color: Colors.white24, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap, {
    Widget? trailing,
    bool isDestructive = false,
  }) {
    final itemColor = isDestructive ? DesignTokens.neonRed : color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: itemColor.withValues(alpha: 0.08),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.03),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: itemColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: itemColor, size: 15),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDestructive
                          ? DesignTokens.neonRed
                          : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (trailing != null) ...[trailing, const SizedBox(width: 4)],
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.15),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _switchItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: value
                ? color.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: value
                  ? color.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.03),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 15),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              _neonSwitch(value, color, onChanged),
            ],
          ),
        ),
      ),
    );
  }

  Widget _neonSwitch(bool value, Color color, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42,
        height: 22,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value
              ? color.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: value
                ? color.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: value ? color : Colors.white30,
              shape: BoxShape.circle,
              boxShadow: value
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  DIALOGS (dark themed)
  // ═══════════════════════════════════════════════════════════════

  AlertDialog _darkDialog({
    required String title,
    required Widget content,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      backgroundColor: DesignTokens.bgSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: content,
      actions: actions,
    );
  }

  void _showDataExportDialog() {
    final categories = <String, bool>{
      'Fight Camp Results': true,
      'Training Sessions & Logs': true,
      'Performance Science Data': true,
      'Combat Analytics': true,
      'Body Stats & Metrics': false,
      'Sparring Records': false,
      'Account & Profile': false,
    };
    final icons = <String, IconData>{
      'Fight Camp Results': Icons.emoji_events,
      'Training Sessions & Logs': Icons.fitness_center,
      'Performance Science Data': Icons.science,
      'Combat Analytics': Icons.analytics,
      'Body Stats & Metrics': Icons.monitor_heart,
      'Sparring Records': Icons.sports_mma,
      'Account & Profile': Icons.person,
    };
    final colors = <String, Color>{
      'Fight Camp Results': DesignTokens.neonCyan,
      'Training Sessions & Logs': DesignTokens.neonAmber,
      'Performance Science Data': DesignTokens.neonMagenta,
      'Combat Analytics': DesignTokens.neonGreen,
      'Body Stats & Metrics': const Color(0xFFFF8800),
      'Sparring Records': DesignTokens.neonRed,
      'Account & Profile': Colors.white54,
    };

    String format = 'PDF';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final selected = categories.entries.where((e) => e.value).length;
          return _darkDialog(
            title: 'Export Fight Data',
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select what to export:',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...categories.keys.map((cat) {
                    final on = categories[cat]!;
                    final c = colors[cat]!;
                    return GestureDetector(
                      onTap: () => setD(() => categories[cat] = !on),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: on
                              ? c.withValues(alpha: 0.08)
                              : Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: on
                                ? c.withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(icons[cat], color: c, size: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: on ? Colors.white : Colors.white54,
                                  fontSize: 13,
                                  fontWeight: on
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: on
                                    ? c.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: on
                                      ? c.withValues(alpha: 0.5)
                                      : Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: on
                                  ? Icon(Icons.check, color: c, size: 14)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 14),
                  // Format selector
                  Row(
                    children: [
                      Text(
                        'FORMAT:',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ...['PDF', 'CSV', 'JSON'].map((f) {
                        final sel = format == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => setD(() => format = f),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: sel
                                    ? DesignTokens.neonCyan.withValues(
                                        alpha: 0.15,
                                      )
                                    : Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: sel
                                      ? DesignTokens.neonCyan.withValues(
                                          alpha: 0.4,
                                        )
                                      : Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Text(
                                f,
                                style: TextStyle(
                                  color: sel
                                      ? DesignTokens.neonCyan
                                      : Colors.white54,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'GDPR Art. 20 & AU Privacy Principle 12 compliant.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                ),
              ),
              TextButton(
                onPressed: selected == 0
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        // Map UI categories to service params
                        final authService = context.read<AuthService>();
                        final userId = authService.currentUser?.uid;
                        if (userId == null) return;
                        final exportService = DataExportService();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: DesignTokens.bgSecondary,
                            duration: const Duration(seconds: 2),
                            content: Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: DesignTokens.neonCyan,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Preparing $format export...',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        );
                        final json = await exportService.exportUserData(
                          userId,
                          includePosts:
                              categories['Fight Camp Results'] ?? false,
                          includeTraining:
                              categories['Training Sessions & Logs'] ?? false,
                          includeAnalytics:
                              (categories['Performance Science Data'] ??
                                  false) ||
                              (categories['Combat Analytics'] ?? false),
                          includeWellness:
                              categories['Body Stats & Metrics'] ?? false,
                          includeProfile:
                              categories['Account & Profile'] ?? false,
                        );
                        if (json != null && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: DesignTokens.bgSecondary,
                              content: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: DesignTokens.neonGreen,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$selected categories exported successfully',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: DesignTokens.bgSecondary,
                              content: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: DesignTokens.neonRed,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Export failed. Please try again.',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                child: Text(
                  'EXPORT $selected CATEGORIES',
                  style: TextStyle(
                    color: selected > 0
                        ? DesignTokens.neonCyan
                        : Colors.white24,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final deletionService = AccountDeletionService();
    bool isProcessing = false;
    String? errorMsg;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          if (deletionService.isDeleting) {
            // Show progress while deleting
            return _darkDialog(
              title: 'Deleting Account...',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: deletionService.progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation(
                      DesignTokens.neonRed,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    deletionService.status,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              actions: const [],
            );
          }
          return _darkDialog(
            title: 'Delete Account',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This action is PERMANENT and cannot be undone.\n\n'
                  'All your data will be deleted in accordance with '
                  'GDPR Article 17 and AU Privacy Principle 13.\n\n'
                  'Please re-enter your credentials to confirm:',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ),
                if (errorMsg != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMsg!,
                    style: const TextStyle(
                      color: DesignTokens.neonRed,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                ),
              ),
              TextButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                          setD(() => errorMsg = 'Both fields are required');
                          return;
                        }
                        // Capture context-dependent refs before async gap
                        final authService = context.read<AuthService>();
                        final router = GoRouter.of(context);
                        setD(() {
                          isProcessing = true;
                          errorMsg = null;
                        });
                        // Step 1: Re-authenticate
                        final reauthed = await deletionService.reauthenticate(
                          emailCtrl.text.trim(),
                          passCtrl.text,
                        );
                        if (!reauthed) {
                          setD(() {
                            isProcessing = false;
                            errorMsg = 'Invalid credentials. Please try again.';
                          });
                          return;
                        }
                        // Step 2: Cascade delete
                        final userId = authService.currentUser?.uid;
                        if (userId == null) return;
                        setD(() {}); // trigger rebuild to show progress
                        deletionService.addListener(() {
                          if (ctx.mounted) setD(() {});
                        });
                        final success = await deletionService.deleteAllUserData(
                          userId,
                        );
                        if (success && ctx.mounted) {
                          Navigator.pop(ctx);
                          await authService.signOut();
                          router.go('/login');
                        } else {
                          setD(() {
                            isProcessing = false;
                            errorMsg =
                                'Deletion failed. Please contact support.';
                          });
                        }
                      },
                child: Text(
                  isProcessing ? 'DELETING...' : 'DELETE PERMANENTLY',
                  style: TextStyle(
                    color: isProcessing ? Colors.white24 : DesignTokens.neonRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _darkDialog(
        title: 'Sign Out',
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final router = GoRouter.of(context);
              await context.read<AuthService>().signOut();
              if (mounted) router.go('/');
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(
                color: DesignTokens.neonCyan,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => _darkDialog(
        title: 'Change Password',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _darkTextField(currentCtrl, 'Current Password', obscure: true),
            const SizedBox(height: 12),
            _darkTextField(newCtrl, 'New Password', obscure: true),
            const SizedBox(height: 12),
            _darkTextField(confirmCtrl, 'Confirm Password', obscure: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: DesignTokens.bgSecondary,
                    content: Text(
                      'Passwords do not match',
                      style: TextStyle(color: DesignTokens.neonRed),
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final success = await context.read<AuthService>().updatePassword(
                currentPassword: currentCtrl.text,
                newPassword: newCtrl.text,
              );
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    backgroundColor: DesignTokens.bgSecondary,
                    content: Text(
                      success ? 'Password updated' : 'Failed to update',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'Update',
              style: TextStyle(
                color: DesignTokens.neonCyan,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangeEmailDialog() {
    final passwordCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => _darkDialog(
        title: 'Change Email',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A verification link will be sent to your new email. Your email won\'t change until you verify.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            _darkTextField(passwordCtrl, 'Current Password', obscure: true),
            const SizedBox(height: 12),
            _darkTextField(emailCtrl, 'New Email Address'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (emailCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final success = await context.read<AuthService>().updateEmail(
                currentPassword: passwordCtrl.text,
                newEmail: emailCtrl.text.trim(),
              );
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    backgroundColor: DesignTokens.bgSecondary,
                    content: Text(
                      success
                          ? 'Verification sent to ${emailCtrl.text.trim()}'
                          : 'Failed to update email',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'Send Verification',
              style: TextStyle(
                color: DesignTokens.neonCyan,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmailPreferencesDialog() {
    bool marketing = true;
    bool fights = true;
    bool weekly = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => _darkDialog(
          title: 'Email Preferences',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogSwitch(
                'Marketing Emails',
                'Promotions and offers',
                marketing,
                (v) => setD(() => marketing = v),
              ),
              _dialogSwitch(
                'Fight Alerts',
                'Events and results',
                fights,
                (v) => setD(() => fights = v),
              ),
              _dialogSwitch(
                'Weekly Summary',
                'Performance report',
                weekly,
                (v) => setD(() => weekly = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: DesignTokens.bgSecondary,
                    content: Text(
                      'Email preferences saved',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
              child: const Text(
                'Save',
                style: TextStyle(
                  color: DesignTokens.neonCyan,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogSwitch(
    String title,
    String sub,
    bool val,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _neonSwitch(val, DesignTokens.neonCyan, onChanged),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    final loc = context.read<LocalizationService>();
    final allLocales = LocalizationService.supportedLocales;
    final currentCode = loc.currentLocale;

    showDialog(
      context: context,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final filtered = searchQuery.isEmpty
                ? allLocales
                : allLocales.where((l) {
                    final q = searchQuery.toLowerCase();
                    return l.name.toLowerCase().contains(q) ||
                        l.nativeName.toLowerCase().contains(q) ||
                        l.code.toLowerCase().contains(q);
                  }).toList();

            return _darkDialog(
              title: 'Select Language',
              content: SizedBox(
                width: double.maxFinite,
                height: 420,
                child: Column(
                  children: [
                    // Search box
                    TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search languages...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 18,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) => setDialogState(() => searchQuery = v),
                    ),
                    const SizedBox(height: 8),
                    // Language list
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final l = filtered[i];
                          final selected = l.code == currentCode;
                          return GestureDetector(
                            onTap: () {
                              loc.setLocale(l.code);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: DesignTokens.bgSecondary,
                                  content: Text(
                                    'Language set to ${l.nativeName}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: selected
                                    ? DesignTokens.neonCyan.withValues(
                                        alpha: 0.08,
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    l.flag,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l.nativeName,
                                          style: TextStyle(
                                            color: selected
                                                ? DesignTokens.neonCyan
                                                : Colors.white,
                                            fontSize: 14,
                                            fontWeight: selected
                                                ? FontWeight.w700
                                                : FontWeight.w400,
                                          ),
                                        ),
                                        Text(
                                          l.name,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.4,
                                            ),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (selected)
                                    const Icon(
                                      Icons.check,
                                      color: DesignTokens.neonCyan,
                                      size: 18,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showThemePicker(SettingsService settings) {
    showDialog(
      context: context,
      builder: (ctx) => _darkDialog(
        title: 'Choose Theme',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: DFCThemeMode.values.map((mode) {
            final isSelected = mode == settings.themeMode;
            return GestureDetector(
              onTap: () {
                settings.setThemeMode(mode);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: DesignTokens.bgSecondary,
                    content: Text(
                      'Theme set to ${mode.label}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? mode.previewAccent.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(
                          color: mode.previewAccent.withValues(alpha: 0.3),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(mode.icon, color: mode.previewAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mode.label,
                            style: TextStyle(
                              color: isSelected
                                  ? mode.previewAccent
                                  : Colors.white,
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                          Text(
                            mode.description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: mode.previewAccent,
                        size: 18,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Logo & brand ──
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
                ),
                boxShadow: [
                  BoxShadow(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.25),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Icon(
                Icons.sports_mma,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
              ).createShader(r),
              child: const Text(
                'DataFightCentral',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'v2.6.0',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),
            // ── Divider ──
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    DesignTokens.neonCyan.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ── Description ──
            Text(
              'The unstoppable promotional engine for combat sports events, fights & fighters worldwide.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            // ── Tagline ──
            const Text(
              'Protect  •  Promote  •  Perform',
              style: TextStyle(
                color: DesignTokens.neonCyan,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 14),
            // ── Capabilities ──
            Text(
              'Real-time rankings · PPV streaming · AI-powered insights · Global fighter promotion · Event management',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Powered by Google Gemini AI',
              style: TextStyle(
                color: DesignTokens.neonGold.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            // ── Copyright ──
            Text(
              '© 2026 DataFightCentral. All rights reserved.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 10,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: DesignTokens.neonCyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVersionInfo() {
    showDialog(
      context: context,
      builder: (ctx) => _darkDialog(
        title: 'Version Info',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _versionRow('App Version', '2.6.0', Colors.white),
            _versionRow('Build', '2026.03.23', Colors.white),
            _versionRow('Flutter SDK', '3.32+', Colors.white54),
            _versionRow('Firebase', 'Connected', DesignTokens.neonGreen),
            _versionRow('AI Engine', 'Gemini 2.5 Pro', DesignTokens.neonCyan),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(color: DesignTokens.neonCyan),
            ),
          ),
        ],
      ),
    );
  }

  Widget _versionRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _darkTextField(
    TextEditingController ctrl,
    String hint, {
    bool obscure = false,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: DesignTokens.neonCyan),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}
