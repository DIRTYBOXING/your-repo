import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/auth_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  MEMBERS ACCOUNT — Unified account management hub
//  Edit details · Membership · Security · Billing · Support · Logout
// ═══════════════════════════════════════════════════════════════════════════

class MembersAccountScreen extends StatelessWidget {
  const MembersAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Consumer<AuthService>(
                builder: (context, auth, _) {
                  final user = auth.userModel;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    children: [
                      // ── Member Info Card ──
                      _buildMemberCard(context, auth),
                      const SizedBox(height: 20),

                      // ── Account Details ──
                      _sectionLabel('ACCOUNT DETAILS', Icons.person),
                      const SizedBox(height: 6),
                      _menuItem(
                        Icons.edit_outlined,
                        'Edit Profile',
                        'Update your name, bio, photo & fight record',
                        DesignTokens.neonCyan,
                        () => context.push('/profile/edit'),
                      ),
                      _menuItem(
                        Icons.email_outlined,
                        'Email Address',
                        user?.email ?? 'Not set',
                        DesignTokens.neonCyan,
                        () => _showChangeEmailInfo(context),
                      ),
                      _menuItem(
                        Icons.lock_outline,
                        'Change Password',
                        'Update your account password',
                        DesignTokens.neonCyan,
                        () => _showChangePasswordDialog(context),
                      ),
                      const SizedBox(height: 20),

                      // ── Membership & Billing ──
                      _sectionLabel(
                        'MEMBERSHIP & BILLING',
                        Icons.workspace_premium,
                      ),
                      const SizedBox(height: 6),
                      _menuItem(
                        Icons.workspace_premium,
                        'Membership Plan',
                        'Free / Gold / Diamond — Manage your tier',
                        DesignTokens.neonMagenta,
                        () => context.push('/membership'),
                      ),
                      _menuItem(
                        Icons.receipt_long_outlined,
                        'Billing History',
                        'View past invoices & payment history',
                        DesignTokens.neonMagenta,
                        () => context.push('/billing-history'),
                      ),
                      _menuItem(
                        Icons.credit_card_outlined,
                        'Subscription',
                        'Manage subscription & payment method',
                        DesignTokens.neonMagenta,
                        () => context.push('/subscription'),
                      ),
                      const SizedBox(height: 20),

                      // ── Security & Verification ──
                      _sectionLabel('SECURITY & VERIFICATION', Icons.shield),
                      const SizedBox(height: 6),
                      _menuItem(
                        Icons.verified_user_outlined,
                        'Identity Verification',
                        user?.isVerified == true
                            ? 'Verified ✓'
                            : 'Get verified — unlock features',
                        DesignTokens.neonGold,
                        () => context.push('/identity-verification'),
                      ),
                      _menuItem(
                        Icons.notifications_active_outlined,
                        'Notification Preferences',
                        'Push, email & in-app alerts',
                        DesignTokens.neonAmber,
                        () => context.push('/notification-settings'),
                      ),
                      _menuItem(
                        Icons.security_outlined,
                        'Privacy & Security',
                        'Data, visibility & safety settings',
                        DesignTokens.neonAmber,
                        () => context.push('/privacy'),
                      ),
                      const SizedBox(height: 20),

                      // ── Support & Info ──
                      _sectionLabel('SUPPORT', Icons.help_outline),
                      const SizedBox(height: 6),
                      _menuItem(
                        Icons.settings_outlined,
                        'All Settings',
                        'Full settings & preferences',
                        Colors.white.withValues(alpha: 0.4),
                        () => context.push('/settings'),
                      ),
                      _menuItem(
                        Icons.volunteer_activism_outlined,
                        'Donate / Support DFC',
                        'Help keep Data Fight Central running',
                        DesignTokens.neonGreen,
                        () => context.push('/donation'),
                      ),
                      const SizedBox(height: 20),

                      // ── Sign Out ──
                      _buildLogoutButton(context),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white70,
              size: 18,
            ),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.account_circle, color: DesignTokens.neonCyan, size: 22),
          const SizedBox(width: 8),
          const Text(
            'MEMBERS ACCOUNT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, AuthService auth) {
    final user = auth.userModel;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.neonCyan.withValues(alpha: 0.08),
            DesignTokens.neonMagenta.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                width: 2,
              ),
              color: DesignTokens.neonCyan.withValues(alpha: 0.1),
            ),
            child: user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                ? ClipOval(
                    child: DfcNetworkImage(
                      url: user.photoUrl!,
                    ),
                  )
                : Icon(
                    Icons.person,
                    color: DesignTokens.neonCyan.withValues(alpha: 0.5),
                    size: 28,
                  ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'Fighter',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _statusChip(
                      user?.emailVerified == true ? 'Verified' : 'Unverified',
                      user?.emailVerified == true
                          ? DesignTokens.neonGreen
                          : DesignTokens.neonAmber,
                    ),
                    const SizedBox(width: 6),
                    _statusChip(
                      user?.role.name.toUpperCase() ?? 'MEMBER',
                      DesignTokens.neonCyan,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c.withValues(alpha: 0.8),
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.25)),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _menuItem(
    IconData icon,
    String title,
    String subtitle,
    Color accent,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent.withValues(alpha: 0.6), size: 18),
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
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.15),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLogoutDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFF5252).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFF5252).withValues(alpha: 0.15),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFFF5252), size: 18),
            SizedBox(width: 8),
            Text(
              'Sign Out',
              style: TextStyle(
                color: Color(0xFFFF5252),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A1628),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthService>().signOut();
              if (context.mounted) context.go('/');
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(
                color: Color(0xFFFF5252),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangeEmailInfo(BuildContext context) {
    final user = context.read<AuthService>().userModel;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A1628),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Email Address',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Your account email is:\n${user?.email ?? "Not set"}\n\nTo change your email, go to Edit Profile or contact support.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00F5FF))),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final auth = context.read<AuthService>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A1628),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Change Password',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'A password reset link will be sent to your email address.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final email = auth.userModel?.email;
              if (email != null && email.isNotEmpty) {
                try {
                  await auth.sendPasswordResetEmail(email);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Password reset email sent to $email'),
                        backgroundColor: DesignTokens.neonGreen.withValues(
                          alpha: 0.9,
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red.withValues(alpha: 0.9),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text(
              'Send Reset Link',
              style: TextStyle(
                color: Color(0xFF00F5FF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
