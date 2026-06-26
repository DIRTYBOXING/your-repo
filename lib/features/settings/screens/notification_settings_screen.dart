import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/user_settings_service.dart';
import '../../../shared/models/user_settings_model.dart';

// ═══════════════════════════════════════════════════════════════════
//  NOTIFICATION COMMAND CENTER v2.0
//  Push control · In-app alerts · Quiet hours · Email digest
// ═══════════════════════════════════════════════════════════════════

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // ── State loaded from Firestore (via UserSettingsService) ──
  // Local copies for instant UI; flushed to Firestore on change.
  bool _pushMaster = true;
  bool _fightAlerts = true;
  bool _trainingReminders = true;
  bool _socialMentions = true;
  bool _campaignWins = true;
  bool _marketplace = true;
  bool _weightReminders = true;
  bool _coachMessages = true;

  bool _aiTips = true;
  bool _fightWire = true;
  bool _achievements = true;
  bool _promotions = false;
  bool _community = true;

  bool _quietEnabled = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0);

  String _emailDigest = 'Daily';

  @override
  void initState() {
    super.initState();
    _hydrateFromFirestore();
  }

  /// Pull saved preferences from Firestore and populate local state
  void _hydrateFromFirestore() {
    final settingsService = context.read<UserSettingsService>();
    final prefs = settingsService.settings?.notifications;
    if (prefs == null) return;

    setState(() {
      _pushMaster = prefs.pushEnabled;
      _fightAlerts = prefs.fightAlerts;
      _trainingReminders = prefs.trainingReminders;
      _socialMentions = prefs.socialMentions;
      _campaignWins = prefs.campaignWins;
      _marketplace = prefs.marketplace;
      _weightReminders = prefs.weightReminders;
      _coachMessages = prefs.coachMessages;
      _aiTips = prefs.aiTips;
      _fightWire = prefs.fightWire;
      _achievements = prefs.achievements;
      _promotions = prefs.promotions;
      _community = prefs.community;
      _quietEnabled = prefs.quietHoursEnabled;
      _quietStart = TimeOfDay(
        hour: prefs.quietStartHour,
        minute: prefs.quietStartMinute,
      );
      _quietEnd = TimeOfDay(
        hour: prefs.quietEndHour,
        minute: prefs.quietEndMinute,
      );
      _emailDigest = prefs.emailDigest;
    });
  }

  /// Persist current local state to Firestore
  Future<void> _saveToFirestore() async {
    final settingsService = context.read<UserSettingsService>();
    await settingsService.updateNotificationPreferences(
      NotificationPreferences(
        pushEnabled: _pushMaster,
        fightAlerts: _fightAlerts,
        trainingReminders: _trainingReminders,
        socialMentions: _socialMentions,
        campaignWins: _campaignWins,
        marketplace: _marketplace,
        weightReminders: _weightReminders,
        coachMessages: _coachMessages,
        aiTips: _aiTips,
        fightWire: _fightWire,
        achievements: _achievements,
        promotions: _promotions,
        community: _community,
        quietHoursEnabled: _quietEnabled,
        quietStartHour: _quietStart.hour,
        quietStartMinute: _quietStart.minute,
        quietEndHour: _quietEnd.hour,
        quietEndMinute: _quietEnd.minute,
        emailDigest: _emailDigest,
        emailNotifications: _emailDigest != 'Off',
      ),
    );
  }

  /// setState + auto-persist
  void _toggle(void Function() mutate) {
    setState(mutate);
    _saveToFirestore();
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: _goBackSafely,
              ),
              const Spacer(),
              // Mute all quick-toggle
              GestureDetector(
                onTap: () {
                  _toggle(() => _pushMaster = !_pushMaster);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _pushMaster
                        ? DesignTokens.neonGreen.withValues(alpha: 0.12)
                        : DesignTokens.neonRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _pushMaster
                          ? DesignTokens.neonGreen.withValues(alpha: 0.3)
                          : DesignTokens.neonRed.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _pushMaster
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        color: _pushMaster
                            ? DesignTokens.neonGreen
                            : DesignTokens.neonRed,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _pushMaster ? 'LIVE' : 'MUTED',
                        style: TextStyle(
                          color: _pushMaster
                              ? DesignTokens.neonGreen
                              : DesignTokens.neonRed,
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
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [DesignTokens.neonCyan, DesignTokens.neonGreen],
                  ).createShader(r),
                  child: const Text(
                    'NOTIFICATIONS',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Fine-tune how DFC communicates with you',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      children: [
        // ── Active channel summary ──
        _activeChannelStrip(),
        const SizedBox(height: 20),

        // ── Push categories ──
        _sectionLabel('PUSH NOTIFICATIONS', Icons.cell_tower),
        const SizedBox(height: 8),
        _notifToggle(
          Icons.sports_mma,
          'Fight Alerts',
          'Live results, event reminders, breaking news',
          _fightAlerts,
          (v) => _toggle(() => _fightAlerts = v),
          DesignTokens.neonRed,
        ),
        _notifToggle(
          Icons.fitness_center,
          'Training Reminders',
          'Workout schedule, fight camp nudges',
          _trainingReminders,
          (v) => _toggle(() => _trainingReminders = v),
          DesignTokens.neonAmber,
        ),
        _notifToggle(
          Icons.alternate_email,
          'Social Mentions',
          'Tags, replies, and FightWire mentions',
          _socialMentions,
          (v) => _toggle(() => _socialMentions = v),
          DesignTokens.neonMagenta,
        ),
        _notifToggle(
          Icons.campaign,
          'Campaign Wins',
          'Marketing milestones and A/B test results',
          _campaignWins,
          (v) => _toggle(() => _campaignWins = v),
          DesignTokens.neonGreen,
        ),
        _notifToggle(
          Icons.storefront,
          'Marketplace',
          'Deal alerts, seller activity, price drops',
          _marketplace,
          (v) => _toggle(() => _marketplace = v),
          DesignTokens.neonGold,
        ),
        _notifToggle(
          Icons.monitor_weight,
          'Weight Reminders',
          'Daily weigh-in and hydration prompts',
          _weightReminders,
          (v) => _toggle(() => _weightReminders = v),
          DesignTokens.neonCyan,
        ),
        _notifToggle(
          Icons.chat_bubble,
          'Coach Messages',
          'New messages from your coaching team',
          _coachMessages,
          (v) => _toggle(() => _coachMessages = v),
          const Color(0xFF64B5F6),
        ),

        const SizedBox(height: 24),

        // ── In-app alerts ──
        _sectionLabel('IN-APP ALERTS', Icons.app_shortcut),
        const SizedBox(height: 8),
        _notifToggle(
          Icons.psychology,
          'AI Tips & Insights',
          'Smart suggestions while you browse',
          _aiTips,
          (v) => _toggle(() => _aiTips = v),
          DesignTokens.neonCyan,
        ),
        _notifToggle(
          Icons.feed,
          'FightWire Activity',
          'New posts, reactions, and thread updates',
          _fightWire,
          (v) => _toggle(() => _fightWire = v),
          DesignTokens.neonGreen,
        ),
        _notifToggle(
          Icons.emoji_events,
          'Achievements',
          'Badge unlocks and milestone celebrations',
          _achievements,
          (v) => _toggle(() => _achievements = v),
          DesignTokens.neonGold,
        ),
        _notifToggle(
          Icons.local_offer,
          'Promotions',
          'Special offers, discounts, new features',
          _promotions,
          (v) => _toggle(() => _promotions = v),
          DesignTokens.neonMagenta,
        ),
        _notifToggle(
          Icons.groups,
          'Community Updates',
          'New members, events, community highlights',
          _community,
          (v) => _toggle(() => _community = v),
          const Color(0xFF81C784),
        ),

        const SizedBox(height: 24),

        // ── Quiet hours ──
        _sectionLabel('QUIET HOURS', Icons.bedtime),
        const SizedBox(height: 8),
        _quietHoursCard(),

        const SizedBox(height: 24),

        // ── Email digest ──
        _sectionLabel('EMAIL DIGEST', Icons.email),
        const SizedBox(height: 8),
        _emailDigestCard(),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  WIDGETS
  // ═══════════════════════════════════════════════════════════════

  Widget _activeChannelStrip() {
    final pushCount = [
      _fightAlerts,
      _trainingReminders,
      _socialMentions,
      _campaignWins,
      _marketplace,
      _weightReminders,
      _coachMessages,
    ].where((v) => v).length;
    final inAppCount = [
      _aiTips,
      _fightWire,
      _achievements,
      _promotions,
      _community,
    ].where((v) => v).length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonCyan.withValues(alpha: 0.08),
            DesignTokens.neonGreen.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          _channelPill('$pushCount/7', 'Push', DesignTokens.neonCyan),
          const SizedBox(width: 8),
          _channelPill('$inAppCount/5', 'In-App', DesignTokens.neonGreen),
          const SizedBox(width: 8),
          _channelPill(
            _quietEnabled ? 'ON' : 'OFF',
            'Quiet',
            _quietEnabled ? DesignTokens.neonMagenta : Colors.white24,
          ),
          const SizedBox(width: 8),
          _channelPill(_emailDigest, 'Email', DesignTokens.neonGold),
        ],
      ),
    );
  }

  Widget _channelPill(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
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

  Widget _notifToggle(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    Color color,
  ) {
    final enabled = _pushMaster;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: enabled ? () => onChanged(!value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: value && enabled
                ? color.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: value && enabled
                  ? color.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.04),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: value && enabled
                      ? color.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: value && enabled
                      ? color
                      : Colors.white.withValues(alpha: 0.2),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: enabled
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
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
              _customSwitch(value && enabled, color, (v) {
                if (enabled) onChanged(v);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customSwitch(bool value, Color color, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 24,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value
              ? color.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? color.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: value ? color : Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              boxShadow: value
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _quietHoursCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _quietEnabled
            ? DesignTokens.neonMagenta.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _quietEnabled
              ? DesignTokens.neonMagenta.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: DesignTokens.neonMagenta.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.do_not_disturb,
                  color: DesignTokens.neonMagenta,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Do Not Disturb',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Silence all notifications during set hours',
                      style: TextStyle(color: Colors.white30, fontSize: 11),
                    ),
                  ],
                ),
              ),
              _customSwitch(
                _quietEnabled,
                DesignTokens.neonMagenta,
                (v) => _toggle(() => _quietEnabled = v),
              ),
            ],
          ),
          if (_quietEnabled) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _timeTile('FROM', _quietStart, (t) {
                    _toggle(() => _quietStart = t);
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward,
                    color: Colors.white.withValues(alpha: 0.15),
                    size: 16,
                  ),
                ),
                Expanded(
                  child: _timeTile('UNTIL', _quietEnd, (t) {
                    _toggle(() => _quietEnd = t);
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Silent from ${_quietStart.format(context)} to ${_quietEnd.format(context)}',
              style: TextStyle(
                color: DesignTokens.neonMagenta.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timeTile(
    String label,
    TimeOfDay time,
    ValueChanged<TimeOfDay> onPicked,
  ) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: DesignTokens.neonMagenta,
                surface: Color(0xFF0D1B2A),
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: DesignTokens.neonMagenta.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: DesignTokens.neonMagenta.withValues(alpha: 0.5),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              time.format(context),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emailDigestCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: DesignTokens.neonGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.mark_email_read,
                  color: DesignTokens.neonGold,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Summary Emails',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Performance reports & community highlights',
                      style: TextStyle(color: Colors.white30, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: ['Off', 'Daily', 'Weekly', 'Monthly'].map((opt) {
              final selected = _emailDigest == opt;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _toggle(() => _emailDigest = opt),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? DesignTokens.neonGold.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? DesignTokens.neonGold.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.06),
                        width: selected ? 1 : 0.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        opt,
                        style: TextStyle(
                          color: selected
                              ? DesignTokens.neonGold
                              : Colors.white30,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
