import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/login_history_service.dart';

// ═══════════════════════════════════════════════════════════════════
//  LOGIN ACTIVITY v1.0
//  "Where you're logged in" — Facebook-style session management
//  Active sessions · Login history · Remote logout
// ═══════════════════════════════════════════════════════════════════

class LoginActivityScreen extends StatefulWidget {
  const LoginActivityScreen({super.key});

  @override
  State<LoginActivityScreen> createState() => _LoginActivityScreenState();
}

class _LoginActivityScreenState extends State<LoginActivityScreen> {
  List<ActiveSession> _sessions = [];
  List<LoginEvent> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    final svc = LoginHistoryService();
    await svc.loadSessions(uid);
    await svc.loadHistory(uid, limit: 20);

    if (mounted) {
      setState(() {
        _sessions = svc.sessions;
        _history = svc.events;
        _loading = false;
      });
    }
  }

  Future<void> _endSession(String sessionId) async {
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    await LoginHistoryService().endSession(uid, sessionId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: DesignTokens.bgSecondary,
          content: Text('Session ended', style: TextStyle(color: Colors.white)),
        ),
      );
      _loadData();
    }
  }

  Future<void> _endAllOtherSessions() async {
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Log Out Everywhere Else?',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'This will end all sessions except this device. Anyone using your account on other devices will be signed out.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Log Out All',
              style: TextStyle(color: DesignTokens.neonRed, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await LoginHistoryService().endAllOtherSessions(uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: DesignTokens.bgSecondary,
            content: Text('All other sessions ended', style: TextStyle(color: Colors.white)),
          ),
        );
        _loadData();
      }
    }
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
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: DesignTokens.neonCyan),
                    )
                  : _buildContent(),
            ),
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
          bottom: BorderSide(color: DesignTokens.neonCyan.withValues(alpha: 0.1)),
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
              colors: [DesignTokens.neonCyan, DesignTokens.neonGreen],
            ).createShader(r),
            child: const Text(
              'LOGIN ACTIVITY',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.white,
              ),
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
        // ── Active sessions ──
        _sectionLabel('WHERE YOU\'RE LOGGED IN', Icons.devices),
        const SizedBox(height: 8),
        if (_sessions.isEmpty)
          _emptyCard('No active sessions found')
        else
          ..._sessions.map(_buildSessionCard),
        const SizedBox(height: 8),

        if (_sessions.length > 1)
          _dangerButton(
            'Log Out of All Other Devices',
            Icons.logout,
            _endAllOtherSessions,
          ),
        const SizedBox(height: 24),

        // ── Recent activity ──
        _sectionLabel('RECENT LOGIN HISTORY', Icons.history),
        const SizedBox(height: 8),
        if (_history.isEmpty)
          _emptyCard('No login history yet')
        else
          ..._history.map(_buildHistoryTile),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SESSION CARDS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSessionCard(ActiveSession session) {
    final platform = session.platform;
    final deviceName = session.deviceName ?? platform;
    final browser = session.browser ?? '';
    final location = session.location ?? '';
    final isCurrent = session.isCurrent;
    final sessionId = session.id;

    String lastActiveStr = 'Active now';
    if (!isCurrent) {
      final diff = DateTime.now().difference(session.lastActiveAt);
      if (diff.inMinutes < 5) {
        lastActiveStr = 'Active now';
      } else if (diff.inHours < 1) {
        lastActiveStr = '${diff.inMinutes}m ago';
      } else if (diff.inDays < 1) {
        lastActiveStr = '${diff.inHours}h ago';
      } else {
        lastActiveStr = '${diff.inDays}d ago';
      }
    }

    final icon = _platformIcon(platform);
    final color = isCurrent ? DesignTokens.neonGreen : DesignTokens.neonCyan;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        deviceName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: DesignTokens.neonGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'THIS DEVICE',
                            style: TextStyle(
                              color: DesignTokens.neonGreen,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [browser, location].where((s) => s.isNotEmpty).join(' · '),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
                  ),
                  Text(
                    lastActiveStr,
                    style: TextStyle(
                      color: isCurrent
                          ? DesignTokens.neonGreen
                          : Colors.white.withValues(alpha: 0.3),
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (!isCurrent)
              IconButton(
                tooltip: 'End session',
                icon: Icon(Icons.logout, color: DesignTokens.neonRed.withValues(alpha: 0.6), size: 18),
                onPressed: () => _endSession(sessionId),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HISTORY TILES
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHistoryTile(LoginEvent event) {
    final method = event.method;
    final platform = event.platform;
    final success = event.success;
    final location = event.location ?? '';

    String timeStr = '';
    final diff = DateTime.now().difference(event.timestamp);
    if (diff.inMinutes < 60) {
      timeStr = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      timeStr = '${diff.inHours}h ago';
    } else {
      timeStr = '${diff.inDays}d ago';
    }

    final color = success ? DesignTokens.neonGreen : DesignTokens.neonRed;
    final icon = success ? Icons.login : Icons.warning_amber;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${success ? "Signed in" : "Failed login"} via $method',
                    style: TextStyle(
                      color: success ? Colors.white : DesignTokens.neonRed,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    [platform, location, timeStr].where((s) => s.isNotEmpty).join(' · '),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
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
  //  HELPERS
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

  Widget _emptyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
        ),
      ),
    );
  }

  Widget _dangerButton(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: DesignTokens.neonRed.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: DesignTokens.neonRed.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DesignTokens.neonRed.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: DesignTokens.neonRed, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: DesignTokens.neonRed,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _platformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'web':
        return Icons.language;
      case 'android':
        return Icons.phone_android;
      case 'ios':
        return Icons.phone_iphone;
      case 'windows':
        return Icons.desktop_windows;
      case 'macos':
        return Icons.laptop_mac;
      case 'linux':
        return Icons.computer;
      default:
        return Icons.devices;
    }
  }
}
