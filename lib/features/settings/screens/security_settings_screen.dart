import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/user_settings_service.dart';
import '../../../shared/models/user_settings_model.dart';

// ═══════════════════════════════════════════════════════════════════
//  SECURITY & PRIVACY CONTROL ROOM v1.0
//  Who can see you · Who can message you · Visibility toggles
//  Firestore-backed via UserSettingsService
// ═══════════════════════════════════════════════════════════════════

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  // ── Privacy Controls ──
  String _profileVisibility = 'public';
  String _activityVisibility = 'friends';
  bool _showOnlineStatus = true;
  bool _allowFriendRequests = true;
  bool _allowMessagesFromStrangers = false;
  bool _showInSearchResults = true;
  bool _showFightRecord = true;
  bool _allowTagging = true;
  bool _showLocation = false;
  bool _shareTrainingData = false;

  // ── Security Controls ──
  bool _twoFactorEnabled = false;
  bool _loginAlerts = true;
  String _recoveryEmail = '';
  String _recoveryPhone = '';

  @override
  void initState() {
    super.initState();
    _hydrateFromFirestore();
  }

  void _hydrateFromFirestore() {
    final svc = context.read<UserSettingsService>();
    final privacy = svc.settings?.privacy;
    final security = svc.settings?.security;

    if (privacy != null) {
      setState(() {
        _profileVisibility = privacy.profileVisibility;
        _activityVisibility = privacy.activityVisibility;
        _showOnlineStatus = privacy.showOnlineStatus;
        _allowFriendRequests = privacy.allowFriendRequests;
        _allowMessagesFromStrangers = privacy.allowMessagesFromStrangers;
        _showInSearchResults = privacy.showInSearchResults;
        _showFightRecord = privacy.showFightRecord;
        _allowTagging = privacy.allowTagging;
        _showLocation = privacy.showLocation;
        _shareTrainingData = privacy.shareTrainingData;
      });
    }

    if (security != null) {
      setState(() {
        _twoFactorEnabled = security.twoFactorEnabled;
        _loginAlerts = security.loginAlertsEnabled;
        _recoveryEmail = security.recoveryEmail ?? '';
        _recoveryPhone = security.recoveryPhone ?? '';
      });
    }
  }

  Future<void> _savePrivacy() async {
    final svc = context.read<UserSettingsService>();
    await svc.updatePrivacySettings(PrivacySettings(
      profileVisibility: _profileVisibility,
      activityVisibility: _activityVisibility,
      showOnlineStatus: _showOnlineStatus,
      allowFriendRequests: _allowFriendRequests,
      allowMessagesFromStrangers: _allowMessagesFromStrangers,
      showInSearchResults: _showInSearchResults,
      showFightRecord: _showFightRecord,
      allowTagging: _allowTagging,
      showLocation: _showLocation,
      shareTrainingData: _shareTrainingData,
    ));
  }

  Future<void> _saveSecurity() async {
    final svc = context.read<UserSettingsService>();
    await svc.updateSecuritySettings(SecuritySettings(
      twoFactorEnabled: _twoFactorEnabled,
      loginAlertsEnabled: _loginAlerts,
      recoveryEmail: _recoveryEmail.isNotEmpty ? _recoveryEmail : null,
      recoveryPhone: _recoveryPhone.isNotEmpty ? _recoveryPhone : null,
    ));
  }

  void _togglePrivacy(void Function() mutate) {
    setState(mutate);
    _savePrivacy();
  }

  void _toggleSecurity(void Function() mutate) {
    setState(mutate);
    _saveSecurity();
  }

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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: DesignTokens.neonRed.withValues(alpha: 0.1),
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
              colors: [DesignTokens.neonRed, DesignTokens.neonAmber],
            ).createShader(r),
            child: const Text(
              'SECURITY & PRIVACY',
              style: TextStyle(
                fontSize: 20,
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
              color: DesignTokens.neonRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: DesignTokens.neonRed.withValues(alpha: 0.2),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield, color: DesignTokens.neonRed, size: 12),
                SizedBox(width: 4),
                Text(
                  'SECURE',
                  style: TextStyle(
                    color: DesignTokens.neonRed,
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

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // ── WHO CAN SEE YOUR PROFILE ──
        _sectionLabel('WHO CAN SEE YOUR STUFF', Icons.visibility),
        const SizedBox(height: 8),
        _visibilitySelector(
          'Profile Visibility',
          'Who can see your profile page',
          Icons.person,
          _profileVisibility,
          (v) => _togglePrivacy(() => _profileVisibility = v),
        ),
        _visibilitySelector(
          'Activity Feed',
          'Who can see your activity & posts',
          Icons.timeline,
          _activityVisibility,
          (v) => _togglePrivacy(() => _activityVisibility = v),
        ),
        const SizedBox(height: 20),

        // ── INTERACTION CONTROLS ──
        _sectionLabel('INTERACTION CONTROLS', Icons.forum),
        const SizedBox(height: 8),
        _privacyToggle(
          Icons.circle,
          'Online Status',
          'Show when you\'re active',
          _showOnlineStatus,
          DesignTokens.neonGreen,
          (v) => _togglePrivacy(() => _showOnlineStatus = v),
        ),
        _privacyToggle(
          Icons.person_add,
          'Friend Requests',
          'Allow others to send you requests',
          _allowFriendRequests,
          DesignTokens.neonCyan,
          (v) => _togglePrivacy(() => _allowFriendRequests = v),
        ),
        _privacyToggle(
          Icons.message,
          'Messages from Anyone',
          'Allow non-friends to DM you',
          _allowMessagesFromStrangers,
          DesignTokens.neonAmber,
          (v) => _togglePrivacy(() => _allowMessagesFromStrangers = v),
        ),
        _privacyToggle(
          Icons.search,
          'Appear in Search',
          'Show your profile in search results',
          _showInSearchResults,
          DesignTokens.neonCyan,
          (v) => _togglePrivacy(() => _showInSearchResults = v),
        ),
        _privacyToggle(
          Icons.local_offer,
          'Allow Tagging',
          'Let others tag you in posts & photos',
          _allowTagging,
          DesignTokens.neonMagenta,
          (v) => _togglePrivacy(() => _allowTagging = v),
        ),
        const SizedBox(height: 20),

        // ── FIGHTER DATA ──
        _sectionLabel('FIGHTER DATA', Icons.sports_mma),
        const SizedBox(height: 8),
        _privacyToggle(
          Icons.emoji_events,
          'Fight Record',
          'Show your W-L record on your profile',
          _showFightRecord,
          DesignTokens.neonGold,
          (v) => _togglePrivacy(() => _showFightRecord = v),
        ),
        _privacyToggle(
          Icons.location_on,
          'Location',
          'Show your city/region on your profile',
          _showLocation,
          DesignTokens.neonRed,
          (v) => _togglePrivacy(() => _showLocation = v),
        ),
        _privacyToggle(
          Icons.fitness_center,
          'Training Data',
          'Share workout & training stats with friends',
          _shareTrainingData,
          DesignTokens.neonGreen,
          (v) => _togglePrivacy(() => _shareTrainingData = v),
        ),
        const SizedBox(height: 20),

        // ── ACCOUNT SECURITY ──
        _sectionLabel('ACCOUNT SECURITY', Icons.lock),
        const SizedBox(height: 8),
        _privacyToggle(
          Icons.security,
          'Two-Factor Authentication',
          'Extra verification on sign-in',
          _twoFactorEnabled,
          DesignTokens.neonRed,
          (v) => _toggleSecurity(() => _twoFactorEnabled = v),
        ),
        _privacyToggle(
          Icons.notifications_active,
          'Login Alerts',
          'Get notified of new sign-ins',
          _loginAlerts,
          DesignTokens.neonAmber,
          (v) => _toggleSecurity(() => _loginAlerts = v),
        ),
        const SizedBox(height: 8),
        _actionTile(
          Icons.history,
          'Login Activity',
          'See where you\'re logged in',
          DesignTokens.neonCyan,
          () => context.push('/login-activity'),
        ),
        _actionTile(
          Icons.email_outlined,
          'Recovery Email',
          _recoveryEmail.isNotEmpty ? _recoveryEmail : 'Not set',
          DesignTokens.neonGreen,
          _showRecoveryEmailDialog,
        ),
        _actionTile(
          Icons.phone,
          'Recovery Phone',
          _recoveryPhone.isNotEmpty ? _recoveryPhone : 'Not set',
          DesignTokens.neonGreen,
          _showRecoveryPhoneDialog,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  WIDGETS
  // ═══════════════════════════════════════════════════════════════

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

  Widget _visibilitySelector(
    String title,
    String subtitle,
    IconData icon,
    String current,
    ValueChanged<String> onChanged,
  ) {
    const options = ['public', 'friends', 'private'];
    const icons = {
      'public': Icons.public,
      'friends': Icons.group,
      'private': Icons.lock,
    };
    const colors = {
      'public': DesignTokens.neonGreen,
      'friends': DesignTokens.neonCyan,
      'private': DesignTokens.neonRed,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
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
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: (colors[current] ?? DesignTokens.neonCyan)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: colors[current] ?? DesignTokens.neonCyan,
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
            // Segmented selector
            Row(
              mainAxisSize: MainAxisSize.min,
              children: options.map((opt) {
                final selected = opt == current;
                final c = colors[opt] ?? DesignTokens.neonCyan;
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: GestureDetector(
                    onTap: () => onChanged(opt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: selected
                            ? c.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? c.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Icon(
                        icons[opt],
                        size: 16,
                        color: selected
                            ? c
                            : Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _privacyToggle(
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
                  ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)]
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionTile(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
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

  // ═══════════════════════════════════════════════════════════════
  //  DIALOGS
  // ═══════════════════════════════════════════════════════════════

  void _showRecoveryEmailDialog() {
    final controller = TextEditingController(text: _recoveryEmail);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Recovery Email',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Set a backup email for account recovery if you lose access.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'backup@example.com',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: DesignTokens.neonCyan),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final email = controller.text.trim();
              if (email.isNotEmpty) {
                setState(() => _recoveryEmail = email);
                context.read<UserSettingsService>().setRecoveryEmail(email);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: DesignTokens.bgSecondary,
                    content: Text('Recovery email updated', style: TextStyle(color: Colors.white)),
                  ),
                );
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(color: DesignTokens.neonCyan, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showRecoveryPhoneDialog() {
    final controller = TextEditingController(text: _recoveryPhone);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Recovery Phone',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Set a phone number for account recovery via SMS.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '+61 4XX XXX XXX',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: DesignTokens.neonCyan),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final phone = controller.text.trim();
              if (phone.isNotEmpty) {
                setState(() => _recoveryPhone = phone);
                context.read<UserSettingsService>().setRecoveryPhone(phone);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: DesignTokens.bgSecondary,
                    content: Text('Recovery phone updated', style: TextStyle(color: Colors.white)),
                  ),
                );
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(color: DesignTokens.neonCyan, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
