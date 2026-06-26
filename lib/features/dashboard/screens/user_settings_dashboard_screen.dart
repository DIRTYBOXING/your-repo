import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

/// User Settings Dashboard — Unified settings for all roles.
/// Sections: Account, Privacy, Platform, Community Standards.
/// Left nav (wide) or top tabs (narrow), right content panel.
class UserSettingsDashboardScreen extends StatefulWidget {
  const UserSettingsDashboardScreen({super.key});

  @override
  State<UserSettingsDashboardScreen> createState() =>
      _UserSettingsDashboardScreenState();
}

class _UserSettingsDashboardScreenState
    extends State<UserSettingsDashboardScreen> {
  int _selectedSection = 0;

  static final _sections = [
    _SettingsSection('ACCOUNT', Icons.person_outline, [
      _SettingsGroup('Profile', [
        _Toggle('Display Name', 'Visible on your public profile', true),
        _Toggle('Avatar', 'Your profile picture', true),
        _Toggle('Bio', 'Short description about you', true),
        _Toggle('Region Badge', 'Show your home region badge', true),
      ]),
      _SettingsGroup('Identity Verification', [
        _Toggle(
          'Verified Status',
          'Request verification for your account',
          false,
        ),
        _Toggle('Fighter ID', 'Link your official fighter record', false),
        _Toggle('Gym Affiliation', 'Connect to your gym profile', false),
      ]),
      _SettingsGroup('Billing & Subscription', [
        _Toggle('DFC Premium', 'Access premium content and features', false),
        _Toggle('PPV Purchases', 'Manage your pay-per-view history', true),
        _Toggle('Auto-Renewal', 'Automatically renew subscriptions', true),
      ]),
    ]),
    _SettingsSection('PRIVACY', Icons.shield_outlined, [
      _SettingsGroup('Visibility', [
        _Toggle('Profile Visibility', 'Who can see your profile', true),
        _Toggle('Activity Status', 'Show when you\'re online', false),
        _Toggle('Region Visibility', 'Show your region on profile', true),
        _Toggle('Fight Record', 'Show your record publicly (fighters)', true),
      ]),
      _SettingsGroup('Blocked Users', [
        _Toggle('Block List', 'Manage users you\'ve blocked', true),
        _Toggle(
          'Auto-block Flagged',
          'Block users flagged by moderation',
          true,
        ),
      ]),
      _SettingsGroup('Data & Export', [
        _Toggle('Download My Data', 'Export all your DFC data', true),
        _Toggle('Delete Account', 'Permanently remove your account', false),
      ]),
    ]),
    _SettingsSection('PLATFORM', Icons.settings_outlined, [
      _SettingsGroup('Notifications', [
        _Toggle('Push Notifications', 'Receive push alerts', true),
        _Toggle('Event Reminders', 'Get notified before events start', true),
        _Toggle(
          'Fighter Replies',
          'When a fighter answers your question',
          true,
        ),
        _Toggle('Region Updates', 'News from your home region', true),
        _Toggle('Moderation Alerts', 'Content review notifications', false),
      ]),
      _SettingsGroup('Appearance', [
        _Toggle('Dark Mode', 'DFC neon theme (default)', true),
        _Toggle('High Contrast', 'Increased contrast for accessibility', false),
        _Toggle('Large Text', 'Increase font sizes', false),
        _Toggle('Reduce Animations', 'Minimize motion effects', false),
      ]),
      _SettingsGroup('Language', [
        _Toggle('English', 'Primary language', true),
        _Toggle('Auto-Translate', 'Translate posts to your language', false),
      ]),
    ]),
    _SettingsSection('COMMUNITY', Icons.groups_outlined, [
      _SettingsGroup('Q&A Settings (Fighters)', [
        _Toggle('Q&A Enabled', 'Allow fans to submit questions', true),
        _Toggle('Topic Filter', 'Only allow selected topics', false),
        _Toggle('Auto-Publish Replies', 'Post replies to your feed', true),
      ]),
      _SettingsGroup('Comment Settings', [
        _Toggle('Allow Comments', 'Let others comment on your posts', true),
        _Toggle('Comment Approval', 'Require approval before display', false),
        _Toggle('Emoji Only', 'Only allow emoji reactions', false),
      ]),
      _SettingsGroup('Region Membership', [
        _Toggle('Logan', 'Member of Logan community', true),
        _Toggle('Brisbane', 'Member of Brisbane community', false),
        _Toggle('Bronx Islanders', 'Member of Bronx Islanders', false),
        _Toggle('Townsville', 'Member of Townsville community', false),
      ]),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            color: DesignTokens.neonCyan,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        // Left nav
        Container(
          width: 220,
          color: DesignTokens.bgSecondary,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: _sections.length,
            itemBuilder: (context, index) {
              final s = _sections[index];
              final selected = index == _selectedSection;
              return GestureDetector(
                onTap: () => setState(() => _selectedSection = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? DesignTokens.neonCyan.withValues(alpha: 0.08)
                        : Colors.transparent,
                    border: Border(
                      left: BorderSide(
                        color: selected
                            ? DesignTokens.neonCyan
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        s.icon,
                        color: selected
                            ? DesignTokens.neonCyan
                            : Colors.white38,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        s.label,
                        style: TextStyle(
                          color: selected
                              ? DesignTokens.neonCyan
                              : Colors.white54,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Content
        Expanded(child: _buildSectionContent()),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        // Section chips
        Container(
          height: 50,
          color: DesignTokens.bgSecondary,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            itemCount: _sections.length,
            itemBuilder: (context, index) {
              final s = _sections[index];
              final selected = index == _selectedSection;
              return GestureDetector(
                onTap: () => setState(() => _selectedSection = index),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? DesignTokens.neonCyan.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? DesignTokens.neonCyan.withValues(alpha: 0.3)
                          : Colors.white12,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        s.icon,
                        color: selected
                            ? DesignTokens.neonCyan
                            : Colors.white38,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        s.label,
                        style: TextStyle(
                          color: selected
                              ? DesignTokens.neonCyan
                              : Colors.white38,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(child: _buildSectionContent()),
      ],
    );
  }

  Widget _buildSectionContent() {
    final section = _sections[_selectedSection];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final group in section.groups) ...[
          Text(
            group.title.toUpperCase(),
            style: const TextStyle(
              color: DesignTokens.neonCyan,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: DesignTokens.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: [
                for (int i = 0; i < group.toggles.length; i++) ...[
                  _buildToggleTile(group.toggles[i]),
                  if (i < group.toggles.length - 1)
                    Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildToggleTile(_Toggle toggle) {
    return StatefulBuilder(
      builder: (context, setLocal) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      toggle.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      toggle.description,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: toggle.value,
                onChanged: (v) => setLocal(() => toggle.value = v),
                activeTrackColor: DesignTokens.neonCyan,
                inactiveTrackColor: Colors.white12,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsSection {
  final String label;
  final IconData icon;
  final List<_SettingsGroup> groups;
  const _SettingsSection(this.label, this.icon, this.groups);
}

class _SettingsGroup {
  final String title;
  final List<_Toggle> toggles;
  const _SettingsGroup(this.title, this.toggles);
}

class _Toggle {
  final String label;
  final String description;
  bool value;
  _Toggle(this.label, this.description, this.value);
}
