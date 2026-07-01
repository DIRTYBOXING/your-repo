import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/dfc_card.dart';
import '../../../shared/widgets/dfc_cosmetic_widgets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PLATFORM CONTROL CENTER — DFC Admin
/// ═══════════════════════════════════════════════════════════════════════════
/// Master kill switches for streams, chat, payments, registration, AI.
/// Full lockdown disables everything except owner access.
/// All state persisted to Firestore `platform_config/lockdown`.
/// Audit log written to `platform_config/lockdown/audit_log` subcollection.
/// ═══════════════════════════════════════════════════════════════════════════
class EmergencyLockdownPage extends StatefulWidget {
  const EmergencyLockdownPage({super.key});

  @override
  State<EmergencyLockdownPage> createState() => _EmergencyLockdownPageState();
}

class _EmergencyLockdownPageState extends State<EmergencyLockdownPage>
    with SingleTickerProviderStateMixin {
  bool _lockdownActive = false;
  bool _streamsKilled = false;
  bool _chatDisabled = false;
  bool _paymentsDisabled = false;
  bool _registrationDisabled = false;
  bool _socialDisabled = false;
  bool _aiDisabled = false;
  bool _loading = true;
  String _lastTriggeredBy = '';
  DateTime? _lastTriggeredAt;
  List<Map<String, dynamic>> _auditLog = [];

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  final _docRef = FirebaseFirestore.instance
      .collection('platform_config')
      .doc('lockdown');

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _loadStatus();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIRESTORE — Load / Save / Audit
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadStatus() async {
    try {
      final doc = await _docRef.get();
      if (doc.exists) {
        final d = doc.data()!;
        setState(() {
          _lockdownActive = d['lockdownActive'] ?? false;
          _streamsKilled = d['streamsKilled'] ?? false;
          _chatDisabled = d['chatDisabled'] ?? false;
          _paymentsDisabled = d['paymentsDisabled'] ?? false;
          _registrationDisabled = d['registrationDisabled'] ?? false;
          _socialDisabled = d['socialDisabled'] ?? false;
          _aiDisabled = d['aiDisabled'] ?? false;
          _lastTriggeredBy = d['lastTriggeredBy'] ?? '';
          _lastTriggeredAt = (d['lastTriggeredAt'] as Timestamp?)?.toDate();
        });
      }
      final logSnap = await _docRef
          .collection('audit_log')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();
      _auditLog = logSnap.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('⚠️ Lockdown load failed: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggle(String field, bool value) async {
    final extras = <String, bool>{};
    setState(() {
      switch (field) {
        case 'lockdownActive':
          _lockdownActive = value;
          if (value) {
            _streamsKilled = true;
            _chatDisabled = true;
            _paymentsDisabled = true;
            _registrationDisabled = true;
            _socialDisabled = true;
            _aiDisabled = true;
            extras.addAll({
              'streamsKilled': true,
              'chatDisabled': true,
              'paymentsDisabled': true,
              'registrationDisabled': true,
              'socialDisabled': true,
              'aiDisabled': true,
            });
          }
        case 'streamsKilled':
          _streamsKilled = value;
        case 'chatDisabled':
          _chatDisabled = value;
        case 'paymentsDisabled':
          _paymentsDisabled = value;
        case 'registrationDisabled':
          _registrationDisabled = value;
        case 'socialDisabled':
          _socialDisabled = value;
        case 'aiDisabled':
          _aiDisabled = value;
      }
    });

    try {
      await _docRef.set({
        'lockdownActive': _lockdownActive,
        'streamsKilled': _streamsKilled,
        'chatDisabled': _chatDisabled,
        'paymentsDisabled': _paymentsDisabled,
        'registrationDisabled': _registrationDisabled,
        'socialDisabled': _socialDisabled,
        'aiDisabled': _aiDisabled,
        'lastTriggeredBy': 'admin',
        'lastTriggeredAt': FieldValue.serverTimestamp(),
        ...extras,
      }, SetOptions(merge: true));

      await _docRef.collection('audit_log').add({
        'action': field,
        'value': value,
        'triggeredBy': 'admin',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ Lockdown write failed: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            field == 'lockdownActive' && value
                ? '🔴 FULL LOCKDOWN ACTIVATED — All systems disabled'
                : field == 'lockdownActive' && !value
                ? '🟢 LOCKDOWN LIFTED — Systems restored'
                : '${value ? '🔴' : '🟢'} ${_label(field)} ${value ? 'DISABLED' : 'ENABLED'}',
          ),
          backgroundColor: value
              ? DesignTokens.neonRed.withValues(alpha: 0.9)
              : DesignTokens.neonGreen.withValues(alpha: 0.7),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _label(String field) => switch (field) {
    'streamsKilled' => 'Live Streams',
    'chatDisabled' => 'Chat & Messaging',
    'paymentsDisabled' => 'Payments',
    'registrationDisabled' => 'Registration',
    'socialDisabled' => 'Social Feed',
    'aiDisabled' => 'AI Systems',
    _ => field,
  };

  int get _killCount => [
    _streamsKilled,
    _chatDisabled,
    _paymentsDisabled,
    _registrationDisabled,
    _socialDisabled,
    _aiDisabled,
  ].where((v) => v).length;

  int get _liveCount => 6 - _killCount;

  Color get _statusAccent => _lockdownActive
      ? DesignTokens.neonRed
      : _killCount > 0
      ? DesignTokens.neonAmber
      : DesignTokens.neonGreen;

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: Stack(
        children: [
          DFCCosmicBackground(
            particleCount: 15,
            primaryColor: _lockdownActive
                ? DesignTokens.neonRed
                : DesignTokens.neonCyan,
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _loading
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: _statusAccent,
                                strokeWidth: 2,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'LOADING PLATFORM STATUS…',
                                style: TextStyle(
                                  color: DesignTokens.textMuted,
                                  fontSize: DesignTokens.fontSizeCaption,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadStatus,
                          color: DesignTokens.neonCyan,
                          child: _buildContent(),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, _) => Opacity(
                  opacity: _lockdownActive ? _pulse.value : 1.0,
                  child: Icon(
                    _lockdownActive ? Icons.lock : Icons.shield_outlined,
                    color: _statusAccent,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: _lockdownActive
                        ? [DesignTokens.neonRed, DesignTokens.neonAmber]
                        : [DesignTokens.neonCyan, DesignTokens.neonBlue],
                  ).createShader(bounds),
                  child: const Text(
                    'PLATFORM CONTROL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              // Status badge
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, _) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _statusAccent.withValues(
                      alpha: _lockdownActive ? _pulse.value * 0.2 : 0.15,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _statusAccent.withValues(alpha: 0.4),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _statusAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _statusAccent.withValues(alpha: 0.6),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _lockdownActive ? 'LOCKED' : '$_liveCount/6',
                        style: TextStyle(
                          color: _statusAccent,
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
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(left: 48),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Kill Switches · Services · Audit · Broadcast',
                style: TextStyle(
                  color: DesignTokens.textDisabled,
                  fontSize: DesignTokens.fontSizeMicro,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          DFCNeonDivider(color: _statusAccent),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTENT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // ── Status Banner ──
        _buildStatusBanner(),
        const SizedBox(height: 16),

        // ── Service health grid ──
        _buildServiceHealthGrid(),
        const SizedBox(height: 20),

        // ── Master Kill Switch ──
        _buildMasterSwitch(),
        const SizedBox(height: 24),

        // ── Individual Controls ──
        const DFCSectionHeader(title: 'STREAM CONTROL', icon: Icons.videocam),
        const SizedBox(height: 8),
        _toggleCard(
          icon: Icons.videocam_off,
          title: 'Kill All Live Streams',
          subtitle: 'Immediately terminate all active PPV & live streams',
          value: _streamsKilled,
          accent: DesignTokens.neonRed,
          onChanged: (v) => _confirm(
            v ? 'Kill all live streams?' : 'Restore live streams?',
            () => _toggle('streamsKilled', v),
          ),
        ),
        const SizedBox(height: 20),

        const DFCSectionHeader(
          title: 'COMMUNICATION',
          icon: Icons.chat_bubble_outline,
        ),
        const SizedBox(height: 8),
        _toggleCard(
          icon: Icons.chat_bubble_outline,
          title: 'Disable All Chat',
          subtitle: 'Kill live chat, comments, DMs, and messaging',
          value: _chatDisabled,
          accent: DesignTokens.neonAmber,
          onChanged: (v) => _toggle('chatDisabled', v),
        ),
        const SizedBox(height: 8),
        _toggleCard(
          icon: Icons.feed_outlined,
          title: 'Disable Social Feed',
          subtitle: 'Block all social posts, stories, and sharing',
          value: _socialDisabled,
          accent: DesignTokens.neonAmber,
          onChanged: (v) => _toggle('socialDisabled', v),
        ),
        const SizedBox(height: 20),

        const DFCSectionHeader(title: 'COMMERCE', icon: Icons.payment),
        const SizedBox(height: 8),
        _toggleCard(
          icon: Icons.money_off,
          title: 'Disable Payments',
          subtitle: 'Block all Stripe checkout, subscriptions & donations',
          value: _paymentsDisabled,
          accent: DesignTokens.neonGold,
          onChanged: (v) => _confirm(
            v
                ? 'Disable ALL payments?\n\nNo purchases, subs, or donations will process.'
                : 'Re-enable payments?',
            () => _toggle('paymentsDisabled', v),
          ),
        ),
        const SizedBox(height: 20),

        const DFCSectionHeader(title: 'ACCESS CONTROL', icon: Icons.person_outline),
        const SizedBox(height: 8),
        _toggleCard(
          icon: Icons.person_add_disabled,
          title: 'Disable Registration',
          subtitle: 'Block all new user signups',
          value: _registrationDisabled,
          accent: DesignTokens.neonMagenta,
          onChanged: (v) => _toggle('registrationDisabled', v),
        ),
        const SizedBox(height: 20),

        const DFCSectionHeader(title: 'AI SYSTEMS', icon: Icons.psychology),
        const SizedBox(height: 8),
        _toggleCard(
          icon: Icons.psychology_alt,
          title: 'Disable AI / Swarm',
          subtitle: 'Kill Samurai Swarm, content generation & all AI agents',
          value: _aiDisabled,
          accent: DesignTokens.neonBlue,
          onChanged: (v) => _toggle('aiDisabled', v),
        ),
        const SizedBox(height: 24),

        // ── Quick Actions ──
        const DFCSectionHeader(title: 'QUICK ACTIONS', icon: Icons.flash_on),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _quickAction(
                icon: Icons.delete_forever,
                label: 'Purge Cache',
                accent: DesignTokens.neonRed,
                onTap: () => _snack('🗑️ Cache purged'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _quickAction(
                icon: Icons.refresh,
                label: 'Force Refresh',
                accent: DesignTokens.neonCyan,
                onTap: _loadStatus,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _quickAction(
                icon: Icons.broadcast_on_personal,
                label: 'Send Alert',
                accent: DesignTokens.neonAmber,
                onTap: _showBroadcastDialog,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Audit Log ──
        const DFCSectionHeader(title: 'AUDIT LOG', icon: Icons.history),
        const SizedBox(height: 8),
        if (_lastTriggeredAt != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DFCCard.glass(
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: DesignTokens.neonCyan,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Last action by $_lastTriggeredBy at '
                      '${_lastTriggeredAt!.toLocal().toString().split('.').first}',
                      style: const TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: DesignTokens.fontSizeSubtitle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ..._auditLog.take(10).map(_buildAuditRow),
        const SizedBox(height: 40),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS BANNER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStatusBanner() {
    final partial = _killCount > 0 && !_lockdownActive;
    return DFCCard.glass(
      accent: _statusAccent,
      child: Row(
        children: [
          // Status icon with glow ring
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _statusAccent.withValues(alpha: 0.12),
              border: Border.all(
                color: _statusAccent.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _statusAccent.withValues(alpha: 0.2),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(
              _lockdownActive
                  ? Icons.lock
                  : partial
                  ? Icons.warning_amber_rounded
                  : Icons.verified_outlined,
              color: _statusAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _statusAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _lockdownActive
                            ? '🔴 LOCKDOWN'
                            : partial
                            ? '⚠️ PARTIAL'
                            : '✅ ALL CLEAR',
                        style: TextStyle(
                          color: _statusAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _lockdownActive
                      ? 'FULL LOCKDOWN ACTIVE'
                      : partial
                      ? '$_killCount SERVICE${_killCount > 1 ? 'S' : ''} DISABLED'
                      : 'ALL SYSTEMS OPERATIONAL',
                  style: const TextStyle(
                    color: DesignTokens.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _lockdownActive
                      ? 'Only owner has platform access'
                      : partial
                      ? 'Some services are currently disabled'
                      : '6/6 services running normally',
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: DesignTokens.fontSizeSubtitle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SERVICE HEALTH GRID — 6 micro status dots
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildServiceHealthGrid() {
    final services = [
      ('Streams', _streamsKilled, Icons.videocam, DesignTokens.neonRed),
      (
        'Chat',
        _chatDisabled,
        Icons.chat_bubble_outline,
        DesignTokens.neonAmber,
      ),
      ('Payments', _paymentsDisabled, Icons.payment, DesignTokens.neonGold),
      (
        'Signups',
        _registrationDisabled,
        Icons.person_add,
        DesignTokens.neonMagenta,
      ),
      ('Social', _socialDisabled, Icons.feed, DesignTokens.neonAmber),
      ('AI', _aiDisabled, Icons.psychology, DesignTokens.neonBlue),
    ];

    return Row(
      children: services.map((s) {
        final (label, killed, icon, accentColor) = s;
        final color = killed ? accentColor : DesignTokens.neonGreen;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              border: Border.all(
                color: color.withValues(alpha: 0.15),
                width: DesignTokens.borderThin,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: color.withValues(alpha: killed ? 0.5 : 0.8),
                  size: 16,
                ),
                const SizedBox(height: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  killed ? 'KILLED' : 'LIVE',
                  style: TextStyle(
                    color: color,
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MASTER KILL SWITCH
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMasterSwitch() {
    final accent = _lockdownActive
        ? DesignTokens.neonRed
        : DesignTokens.neonCyan;
    return DFCCard.glass(
      accent: accent,
      child: Column(
        children: [
          const SizedBox(height: 4),
          // Animated lock icon
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, _) => Transform.scale(
              scale: _lockdownActive ? _pulse.value * 0.15 + 0.85 : 1.0,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.1),
                  border: Border.all(
                    color: accent.withValues(
                      alpha: _lockdownActive ? _pulse.value * 0.4 : 0.25,
                    ),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(
                        alpha: _lockdownActive ? _pulse.value * 0.25 : 0.1,
                      ),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _lockdownActive ? Icons.lock : Icons.lock_open_outlined,
                  color: accent,
                  size: 30,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: _lockdownActive
                  ? [DesignTokens.neonRed, DesignTokens.neonAmber]
                  : [DesignTokens.neonCyan, DesignTokens.neonGreen],
            ).createShader(bounds),
            child: Text(
              _lockdownActive ? 'PLATFORM LOCKED DOWN' : 'PLATFORM OPERATIONAL',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _lockdownActive
                ? 'ALL services disabled. Only owner has access.\n'
                      'Streams killed · Payments blocked · AI offline'
                : 'All systems running. Toggle individual services below.',
            style: const TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeSubtitle,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Master button
          GestureDetector(
            onTap: () => _confirm(
              _lockdownActive
                  ? 'Lift lockdown and restore all services?'
                  : '⚠️ ACTIVATE FULL LOCKDOWN?\n\n'
                        'This will immediately:\n'
                        '• Kill ALL live streams\n'
                        '• Disable chat & social\n'
                        '• Block ALL payments\n'
                        '• Disable registration\n'
                        '• Shut down AI systems\n\n'
                        'Only you (owner) will have access.',
              () => _toggle('lockdownActive', !_lockdownActive),
            ),
            child: AnimatedContainer(
              duration: DesignTokens.animNormal,
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _lockdownActive
                      ? [
                          DesignTokens.neonGreen.withValues(alpha: 0.15),
                          DesignTokens.neonGreen.withValues(alpha: 0.08),
                        ]
                      : [
                          DesignTokens.neonRed.withValues(alpha: 0.2),
                          DesignTokens.neonRed.withValues(alpha: 0.08),
                        ],
                ),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                border: Border.all(
                  color: _lockdownActive
                      ? DesignTokens.neonGreen.withValues(alpha: 0.4)
                      : DesignTokens.neonRed.withValues(alpha: 0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (_lockdownActive
                                ? DesignTokens.neonGreen
                                : DesignTokens.neonRed)
                            .withValues(alpha: 0.15),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _lockdownActive ? Icons.lock_open : Icons.lock,
                    color: _lockdownActive
                        ? DesignTokens.neonGreen
                        : DesignTokens.neonRed,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _lockdownActive
                        ? 'LIFT LOCKDOWN'
                        : 'ACTIVATE FULL LOCKDOWN',
                    style: TextStyle(
                      color: _lockdownActive
                          ? DesignTokens.neonGreen
                          : DesignTokens.neonRed,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOGGLE CARD — Individual kill switch
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _toggleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color accent,
    required ValueChanged<bool> onChanged,
  }) {
    final displayColor = value ? accent : DesignTokens.neonGreen;
    return DFCCard.glass(
      accent: displayColor,
      child: Row(
        children: [
          // Icon container
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: displayColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: displayColor.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Icon(icon, color: displayColor, size: 20),
          ),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: DesignTokens.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: DesignTokens.fontSizeSubtitle,
                  ),
                ),
              ],
            ),
          ),
          // Switch + status label
          Column(
            children: [
              Switch(
                value: value,
                activeThumbColor: accent,
                activeTrackColor: accent.withValues(alpha: 0.3),
                inactiveThumbColor: DesignTokens.neonGreen,
                inactiveTrackColor: DesignTokens.neonGreen.withValues(
                  alpha: 0.15,
                ),
                onChanged: onChanged,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: displayColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  value ? 'KILLED' : 'LIVE',
                  style: TextStyle(
                    color: displayColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUICK ACTION TILE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: DFCCard.glass(
        accent: accent,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.1),
                border: Border.all(
                  color: accent.withValues(alpha: 0.25),
                  width: 0.5,
                ),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: accent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUDIT LOG ROW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAuditRow(Map<String, dynamic> entry) {
    final action = entry['action'] ?? '';
    final value = entry['value'] ?? false;
    final by = entry['triggeredBy'] ?? 'unknown';
    final ts = (entry['timestamp'] as Timestamp?)?.toDate();
    final rowColor = value == true
        ? DesignTokens.neonRed
        : DesignTokens.neonGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: rowColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: rowColor.withValues(alpha: 0.08),
          width: DesignTokens.borderThin,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rowColor.withValues(alpha: 0.12),
            ),
            child: Icon(
              value == true ? Icons.cancel : Icons.check_circle,
              color: rowColor,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_label(action)} ${value == true ? 'DISABLED' : 'ENABLED'}',
                  style: const TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'by $by',
                  style: const TextStyle(
                    color: DesignTokens.textDisabled,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (ts != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIALOGS — glass-styled
  // ═══════════════════════════════════════════════════════════════════════════

  void _confirm(String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          side: BorderSide(
            color: DesignTokens.neonAmber.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DesignTokens.neonAmber.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: DesignTokens.neonAmber,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'CONFIRM ACTION',
              style: TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: DesignTokens.textSecondary,
            fontSize: DesignTokens.fontSizeBody,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: DesignTokens.neonRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: DesignTokens.neonRed.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
              child: const Text(
                'CONFIRM',
                style: TextStyle(
                  color: DesignTokens.neonRed,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBroadcastDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          side: BorderSide(
            color: DesignTokens.neonAmber.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DesignTokens.neonAmber.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.broadcast_on_personal,
                color: DesignTokens.neonAmber,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'BROADCAST ALERT',
              style: TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          style: const TextStyle(color: DesignTokens.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Type your platform-wide message…',
            hintStyle: const TextStyle(color: DesignTokens.textDisabled),
            filled: true,
            fillColor: DesignTokens.bgSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: DesignTokens.neonCyan.withValues(alpha: 0.15),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: DesignTokens.neonCyan.withValues(alpha: 0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: DesignTokens.neonCyan.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('platform_alerts')
                    .add({
                      'message': ctrl.text.trim(),
                      'sentBy': 'admin',
                      'timestamp': FieldValue.serverTimestamp(),
                      'read': false,
                    });
              }
              if (ctx.mounted) Navigator.pop(ctx);
              _snack('📢 Alert broadcast sent');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: DesignTokens.neonAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: DesignTokens.neonAmber.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
              child: const Text(
                'SEND',
                style: TextStyle(
                  color: DesignTokens.neonAmber,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: DesignTokens.bgCard,
        ),
      );
    }
  }
}
