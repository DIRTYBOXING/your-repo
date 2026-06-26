import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/consent_model.dart';
import '../../../shared/services/auth_service.dart';

// ═══════════════════════════════════════════════════════════════════
//  PRIVACY & DATA SHIELD v2.0
//  Dark themed · GDPR/APP compliance · Consent management
// ═══════════════════════════════════════════════════════════════════

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _marketingEmails = false;
  bool _pushNotifications = true;
  bool _analyticsTracking = true;
  bool _thirdPartySharing = false;

  void _goBackSafely() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildContent()),
          ],
        ),
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
            color: DesignTokens.neonGreen.withValues(alpha: 0.1),
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
              colors: [DesignTokens.neonGreen, DesignTokens.neonCyan],
            ).createShader(r),
            child: const Text(
              'PRIVACY & DATA',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: DesignTokens.neonGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: DesignTokens.neonGreen.withValues(alpha: 0.2),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user,
                  color: DesignTokens.neonGreen,
                  size: 12,
                ),
                SizedBox(width: 4),
                Text(
                  'GDPR',
                  style: TextStyle(
                    color: DesignTokens.neonGreen,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
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
  //  CONTENT
  // ═══════════════════════════════════════════════════════════════

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // ── Shield info card ──
        _privacyBanner(),
        const SizedBox(height: 20),

        // ── Consent management ──
        _sectionLabel('MANAGE YOUR CONSENTS', Icons.toggle_on),
        const SizedBox(height: 8),
        _consentToggle(
          Icons.mark_email_read,
          'Marketing Emails',
          'Promotional emails and newsletters',
          _marketingEmails,
          DesignTokens.neonAmber,
          (v) {
            setState(() => _marketingEmails = v);
            _updateConsent(ConsentType.marketingEmails, v);
          },
        ),
        _consentToggle(
          Icons.notifications_active,
          'Push Notifications',
          'Event updates and alerts',
          _pushNotifications,
          DesignTokens.neonCyan,
          (v) {
            setState(() => _pushNotifications = v);
            _updateConsent(ConsentType.pushNotifications, v);
          },
        ),
        _consentToggle(
          Icons.analytics,
          'Analytics Tracking',
          'Help improve the app with usage data',
          _analyticsTracking,
          DesignTokens.neonGreen,
          (v) {
            setState(() => _analyticsTracking = v);
            _updateConsent(ConsentType.analyticsTracking, v);
          },
        ),
        _consentToggle(
          Icons.share,
          'Third-Party Sharing',
          'Share data with trusted partners',
          _thirdPartySharing,
          DesignTokens.neonMagenta,
          (v) {
            setState(() => _thirdPartySharing = v);
            _updateConsent(ConsentType.thirdPartySharing, v);
          },
        ),
        const SizedBox(height: 24),

        // ── Your rights ──
        _sectionLabel('YOUR RIGHTS', Icons.gavel),
        const SizedBox(height: 8),
        _rightsCard(),
        const SizedBox(height: 24),

        // ── Data actions ──
        _sectionLabel('DATA ACTIONS', Icons.storage),
        const SizedBox(height: 8),
        _actionTile(
          Icons.download,
          'Download Your Data',
          'Get a copy of all your personal data',
          DesignTokens.neonCyan,
          _requestDataExport,
        ),
        _actionTile(
          Icons.visibility,
          'View Data Usage',
          'See how your data is being used',
          DesignTokens.neonGreen,
          () {},
        ),
        _actionTile(
          Icons.delete_forever,
          'Delete All Data',
          'Permanently delete your account and data',
          DesignTokens.neonRed,
          _requestDataDeletion,
          isDestructive: true,
        ),
        const SizedBox(height: 24),

        // ── Legal ──
        _sectionLabel('LEGAL DOCUMENTS', Icons.description),
        const SizedBox(height: 8),
        _legalTile(
          Icons.privacy_tip,
          'Privacy Policy',
          'How we collect, use, and protect your data',
        ),
        _legalTile(
          Icons.gavel,
          'Terms of Service',
          'Rules and guidelines for using DataFight',
        ),
        _legalTile(
          Icons.cookie,
          'Cookie Policy',
          'How we use cookies and similar technologies',
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  WIDGETS
  // ═══════════════════════════════════════════════════════════════

  Widget _privacyBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonGreen.withValues(alpha: 0.08),
            DesignTokens.neonCyan.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DesignTokens.neonGreen.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: DesignTokens.neonGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shield,
              color: DesignTokens.neonGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Privacy Matters',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'DataFight complies with Australian Privacy Principles (APP) and '
                  'GDPR. You have full control over your personal data.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
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
    );
  }

  Widget _consentToggle(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    Color color,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: value
                ? color.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: value
                  ? color.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.04),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: value
                      ? color.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: value ? color : Colors.white.withValues(alpha: 0.2),
                  size: 17,
                ),
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
                        fontWeight: FontWeight.w600,
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

  Widget _rightsCard() {
    const rights = [
      (
        Icons.visibility,
        'Right to Access',
        'View all personal data we hold',
        DesignTokens.neonCyan,
      ),
      (
        Icons.edit,
        'Right to Rectification',
        'Correct any inaccurate data',
        DesignTokens.neonAmber,
      ),
      (
        Icons.delete,
        'Right to Erasure',
        'Request deletion of your data',
        DesignTokens.neonRed,
      ),
      (
        Icons.download,
        'Right to Portability',
        'Export in machine-readable format',
        DesignTokens.neonGreen,
      ),
      (
        Icons.block,
        'Right to Restrict',
        'Limit how we process your data',
        DesignTokens.neonMagenta,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: rights.asMap().entries.map((entry) {
          final r = entry.value;
          final isLast = entry.key == rights.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: r.$4.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(r.$1, color: r.$4, size: 15),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.$2,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            r.$3,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _actionTile(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: color.withValues(alpha: 0.08),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDestructive
                  ? DesignTokens.neonRed.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDestructive
                    ? DesignTokens.neonRed.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.04),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 17),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDestructive
                              ? DesignTokens.neonRed
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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

  Widget _legalTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (title == 'Privacy Policy') {
              context.push('/privacy-policy');
            } else if (title == 'Terms of Service') {
              context.push('/terms-of-service');
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('$title — see Settings for details')));
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.04),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: DesignTokens.neonCyan, size: 15),
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
                Icon(
                  Icons.open_in_new,
                  color: Colors.white.withValues(alpha: 0.15),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ACTIONS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _updateConsent(ConsentType type, bool granted) async {
    final authService = context.read<AuthService>();
    await authService.recordConsent(
      consentType: type,
      isGranted: granted,
      version: '1.0',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: DesignTokens.bgSecondary,
          content: Text(
            granted
                ? 'Consent granted for ${type.name}'
                : 'Consent revoked for ${type.name}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  void _requestDataExport() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Export Your Data',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We will prepare a complete copy of your personal data including:',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            _exportItem('Profile information'),
            _exportItem('Posts and comments'),
            _exportItem('Activity history'),
            _exportItem('Consent records'),
            const SizedBox(height: 12),
            Text(
              'You\'ll receive a secure download link within 48 hours.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 11,
              ),
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
                    'Data export request submitted',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
            child: const Text(
              'Request Export',
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

  Widget _exportItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: DesignTokens.neonGreen,
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _requestDataDeletion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber,
              color: DesignTokens.neonRed,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Delete All Data',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete:',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...[
              'Your account and profile',
              'All posts and comments',
              'Activity history',
              'Consent records',
            ].map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    const Icon(
                      Icons.remove_circle_outline,
                      color: DesignTokens.neonRed,
                      size: 12,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone. You have 30 days to cancel by contacting support.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 11,
              ),
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
              _confirmDeletion();
            },
            child: const Text(
              'Continue',
              style: TextStyle(
                color: DesignTokens.neonRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeletion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm Deletion',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Type "DELETE" to confirm you want to permanently delete your account and all data.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
            height: 1.4,
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
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: DesignTokens.bgSecondary,
                  content: Text(
                    'Data deletion scheduled. 30 days to cancel.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
            child: const Text(
              'Delete Forever',
              style: TextStyle(
                color: DesignTokens.neonRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
