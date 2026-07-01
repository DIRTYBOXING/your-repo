import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/services/ab_test_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DFC DEVELOPER CONTROL CENTER
//  Restricted admin page — only accessible by authorised developer accounts.
//  Neon-themed dark UI consistent with the DFC design system.
// ─────────────────────────────────────────────────────────────────────────────

class DeveloperPage extends StatefulWidget {
  final bool isDeveloper;
  const DeveloperPage({required this.isDeveloper, super.key});

  @override
  State<DeveloperPage> createState() => _DeveloperPageState();
}

class _DeveloperPageState extends State<DeveloperPage> {
  // ── Theme colours ─────────────────────────────────────────────────────────
  static const _bg = Color(0xFF0A0E1A);
  static const _card = Color(0xFF111827);
  static const _cyan = Color(0xFF00E5FF);
  static const _green = Color(0xFF00E676);
  static const _amber = Color(0xFFFFAB00);
  static const _red = Color(0xFFFF1744);
  static const _purple = Color(0xFF9D00FF);
  static const _orange = Color(0xFFFF6D00);

  // ── Feature flags (toggle live) ───────────────────────────────────────────
  bool _maintenanceMode = false;
  bool _debugOverlay = false;
  bool _analyticsVerbose = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isDeveloper) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('ACCESS DENIED'),
          backgroundColor: _bg,
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, color: _red, size: 64),
              SizedBox(height: 16),
              Text(
                'DEVELOPER ONLY',
                style: TextStyle(
                  color: _red,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'You do not have permission to access this page.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.developer_mode, color: _cyan, size: 20),
            SizedBox(width: 8),
            Text(
              'DFC DEVELOPER CONTROL CENTER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _cyan),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
        children: [
          // ── Status Banner ─────────────────────────────────────────────────
          _statusBanner(),
          const SizedBox(height: 16),

          // ── Feature Flags ─────────────────────────────────────────────────
          _sectionHeader(Icons.toggle_on, 'FEATURE FLAGS', _cyan),
          const SizedBox(height: 8),
          _featureFlags(),
          const SizedBox(height: 16),

          // ── A/B Experiments ───────────────────────────────────────────────
          _sectionHeader(Icons.science, 'A/B EXPERIMENTS', _purple),
          const SizedBox(height: 8),
          _abExperimentsPanel(),
          const SizedBox(height: 16),

          // ── App Health & Diagnostics ───────────────────────────────────────
          _sectionHeader(
            Icons.health_and_safety,
            'APP HEALTH & DIAGNOSTICS',
            _green,
          ),
          const SizedBox(height: 8),
          _devCard(
            Icons.bug_report,
            'Error Logs & Crash Reports',
            'View runtime errors, exceptions, and crash analytics.',
            _red,
            () => _showSnack('Opening error logs...'),
          ),
          _devCard(
            Icons.speed,
            'Performance Metrics',
            'CPU usage, memory, frame rate, response times.',
            _amber,
            () => _showSnack('Loading performance data...'),
          ),
          _devCard(
            Icons.wifi_tethering,
            'Real-Time Status',
            'Firebase connection, API latency, auth status.',
            _green,
            () => _showSnack('Checking real-time status...'),
          ),
          const SizedBox(height: 16),

          // ── Analytics & Usage ─────────────────────────────────────────────
          _sectionHeader(Icons.analytics, 'ANALYTICS & USAGE', _purple),
          const SizedBox(height: 8),
          _devCard(
            Icons.trending_up,
            'Feature Usage Stats',
            'Most/least used screens and functions — identify popular vs unusable.',
            _purple,
            () => _showSnack('Loading feature analytics...'),
          ),
          _devCard(
            Icons.people_outline,
            'User Activity',
            'Active users, retention, engagement, session durations.',
            _cyan,
            () => _showSnack('Loading user activity...'),
          ),
          _devCard(
            Icons.filter_alt,
            'Conversion Funnels',
            'Track onboarding, sign-up, and subscription funnels.',
            _amber,
            () => _showSnack('Loading funnels...'),
          ),
          const SizedBox(height: 16),

          // ── Content Management ────────────────────────────────────────────
          _sectionHeader(Icons.video_library, 'CONTENT MANAGEMENT', _orange),
          const SizedBox(height: 8),
          _devCard(
            Icons.article,
            'Manage Posts & Content',
            'Create, edit, approve, or reject user submissions.',
            _orange,
            () => _showSnack('Opening content manager...'),
          ),
          _devCard(
            Icons.flag,
            'Flagged Content',
            'Review reported or flagged content for moderation.',
            _red,
            () => _showSnack('Opening flagged content...'),
          ),
          const SizedBox(height: 16),

          // ── User Management ───────────────────────────────────────────────
          _sectionHeader(Icons.people, 'USER MANAGEMENT', _cyan),
          const SizedBox(height: 8),
          _devCard(
            Icons.person_search,
            'View User Profiles',
            'Search, view, and manage all user accounts.',
            _cyan,
            () => _showSnack('Opening user profiles...'),
          ),
          _devCard(
            Icons.block,
            'Ban / Suspend Users',
            'Restrict access for rule-breaking accounts.',
            _red,
            () => _showSnack('Opening ban controls...'),
          ),
          _devCard(
            Icons.admin_panel_settings,
            'Assign Roles & Permissions',
            'Set user roles: fighter, coach, gym, promoter, admin.',
            _purple,
            () => _showSnack('Opening role management...'),
          ),
          const SizedBox(height: 16),

          // ── Notifications & Messaging ──────────────────────────────────────
          _sectionHeader(
            Icons.notifications_active,
            'NOTIFICATIONS & MESSAGING',
            _amber,
          ),
          const SizedBox(height: 8),
          _devCard(
            Icons.send,
            'Send Push Notifications',
            'Broadcast to all users or specific segments.',
            _amber,
            () => _showSnack('Opening push notification sender...'),
          ),
          _devCard(
            Icons.history,
            'Notification Logs',
            'View history of all sent notifications.',
            Colors.white38,
            () => _showSnack('Loading notification history...'),
          ),
          const SizedBox(height: 16),

          // ── Integrations ──────────────────────────────────────────────────
          _sectionHeader(
            Icons.integration_instructions,
            'INTEGRATIONS',
            _green,
          ),
          const SizedBox(height: 8),
          _devCard(
            Icons.play_circle,
            'YouTube Channel',
            'Manage connected YouTube channel and video uploads.',
            _red,
            () => _launchUrl('https://studio.youtube.com'),
          ),
          _devCard(
            Icons.analytics_outlined,
            'Google Analytics',
            'Open Google Analytics dashboard for DFC.',
            _amber,
            () => _launchUrl('https://analytics.google.com'),
          ),
          _devCard(
            Icons.cloud,
            'Firebase Console',
            'Open Firebase project console.',
            _orange,
            () => _launchUrl('https://console.firebase.google.com'),
          ),
          _devCard(
            Icons.payment,
            'Stripe Dashboard',
            'Manage payments, subscriptions and payouts.',
            _purple,
            () => _launchUrl('https://dashboard.stripe.com'),
          ),
          _devCard(
            Icons.code,
            'GitHub Repository',
            'Open DFC source code repository.',
            Colors.white60,
            () =>
                _launchUrl('https://github.com/DIRTYBOXING/Data-Fight-Central'),
          ),
          _devCard(
            Icons.vpn_key,
            'API Keys & Webhooks',
            'Manage API keys, secrets, and webhook endpoints.',
            _cyan,
            () => _showSnack('Opening API key manager...'),
          ),
          const SizedBox(height: 16),

          // ── Settings & Configuration ──────────────────────────────────────
          _sectionHeader(Icons.settings, 'SETTINGS & CONFIGURATION', _cyan),
          const SizedBox(height: 8),
          _devCard(
            Icons.palette,
            'Theme & Appearance',
            'Toggle dark mode, neon colours, font sizes.',
            _cyan,
            () => _showSnack('Opening theme settings...'),
          ),
          _devCard(
            Icons.language,
            'Languages & Localisation',
            'Manage supported languages and translations.',
            _green,
            () => _showSnack('Opening language settings...'),
          ),
          _devCard(
            Icons.location_on,
            'Countries & Locations',
            'Filter by country, region, or GPS location.',
            _amber,
            () => _showSnack('Opening location settings...'),
          ),
          _devCard(
            Icons.science,
            'Environment Variables',
            'View and edit runtime environment config.',
            _purple,
            () => _showSnack('Opening env vars...'),
          ),
          const SizedBox(height: 16),

          // ── Release & Deployment ──────────────────────────────────────────
          _sectionHeader(Icons.system_update, 'RELEASE & DEPLOYMENT', _orange),
          const SizedBox(height: 8),
          _devCard(
            Icons.info_outline,
            'App Version & Build Info',
            'Current version, build number, platform info.',
            _orange,
            _showVersionDialog,
          ),
          _devCard(
            Icons.cloud_upload,
            'Deploy Controls',
            'Trigger builds, push updates, manage releases.',
            _green,
            () => _showSnack('Opening deploy controls...'),
          ),
          _devCard(
            Icons.history_edu,
            'Changelog & Release Notes',
            'View full history of app changes and updates.',
            Colors.white38,
            () => _showSnack('Opening changelog...'),
          ),
          const SizedBox(height: 16),

          // ── Support & Feedback ────────────────────────────────────────────
          _sectionHeader(Icons.support_agent, 'SUPPORT & FEEDBACK', _red),
          const SizedBox(height: 8),
          _devCard(
            Icons.feedback,
            'User Feedback',
            'View submitted feedback, ratings, and suggestions.',
            _amber,
            () => _showSnack('Opening feedback inbox...'),
          ),
          _devCard(
            Icons.help_outline,
            'FAQ & Help Docs',
            'Manage help documentation and FAQs.',
            _cyan,
            () => _showSnack('Opening help docs...'),
          ),
          _devCard(
            Icons.email,
            'Contact / Support',
            'Support email, links, and response queue.',
            _green,
            () => _showSnack('Opening support queue...'),
          ),
          const SizedBox(height: 16),

          // ── Quick Links & Resources ───────────────────────────────────────
          _sectionHeader(Icons.link, 'QUICK LINKS & RESOURCES', _purple),
          const SizedBox(height: 8),
          _quickLinksGrid(),
          const SizedBox(height: 24),

          // ── DFC Power Banner ──────────────────────────────────────────────
          _powerBanner(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _statusBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_cyan.withAlpha(30), _purple.withAlpha(20)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cyan.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _maintenanceMode ? _amber : _green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_maintenanceMode ? _amber : _green).withAlpha(120),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _maintenanceMode
                ? 'MAINTENANCE MODE ACTIVE'
                : 'ALL SYSTEMS OPERATIONAL',
            style: TextStyle(
              color: _maintenanceMode ? _amber : _green,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          const Text(
            'v2.0.0 • datafight-master-2',
            style: TextStyle(color: Colors.white30, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _featureFlags() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cyan.withAlpha(30)),
      ),
      child: Column(
        children: [
          _flagToggle(
            'Maintenance Mode',
            'Puts app in read-only state for all users.',
            _maintenanceMode,
            _amber,
            (v) => setState(() => _maintenanceMode = v),
          ),
          _flagToggle(
            'Debug Overlay',
            'Show performance overlay and debug info.',
            _debugOverlay,
            _green,
            (v) => setState(() => _debugOverlay = v),
          ),
          _flagToggle(
            'Verbose Analytics',
            'Log all user actions for deep analytics.',
            _analyticsVerbose,
            _purple,
            (v) => setState(() => _analyticsVerbose = v),
          ),
        ],
      ),
    );
  }

  Widget _flagToggle(
    String title,
    String desc,
    bool value,
    Color col,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Switch(value: value, onChanged: onChanged, activeThumbColor: col),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: col,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.white30, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _abExperimentsPanel() {
    final abService = ABTestService();
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: abService.streamExperiments(limit: 10),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _purple.withAlpha(30)),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: _purple),
            ),
          );
        }
        final experiments = snap.data ?? [];
        if (experiments.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _purple.withAlpha(30)),
            ),
            child: const Text(
              'No A/B experiments yet. Create one from the admin panel.',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _purple.withAlpha(30)),
          ),
          child: Column(
            children: experiments.map((exp) {
              final status = exp['status'] as String? ?? 'unknown';
              final name = exp['name'] as String? ?? 'Unnamed';
              final participants = exp['totalParticipants'] ?? 0;
              final isActive = status == 'active';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? _green : Colors.white24,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              color: isActive ? _cyan : Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '$status \u2022 $participants participants',
                            style: const TextStyle(
                              color: Colors.white24,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final newStatus = isActive ? 'paused' : 'active';
                        abService.updateExperimentStatus(
                          exp['id'] as String,
                          newStatus,
                        );
                      },
                      child: Text(
                        isActive ? 'PAUSE' : 'RESUME',
                        style: TextStyle(
                          color: isActive ? _amber : _green,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color col) {
    return Row(
      children: [
        Icon(icon, color: col, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: col,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _devCard(
    IconData icon,
    String title,
    String subtitle,
    Color col,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withAlpha(40)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: col.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: col, size: 18),
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
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: col.withAlpha(100), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickLinksGrid() {
    final links = [
      (
        'Docs',
        Icons.menu_book,
        _cyan,
        'https://github.com/DIRTYBOXING/Data-Fight-Central/tree/master/docs',
      ),
      (
        'GitHub',
        Icons.code,
        Colors.white60,
        'https://github.com/DIRTYBOXING/Data-Fight-Central',
      ),
      ('YouTube', Icons.play_circle, _red, 'https://studio.youtube.com'),
      ('Analytics', Icons.analytics, _amber, 'https://analytics.google.com'),
      ('Firebase', Icons.cloud, _orange, 'https://console.firebase.google.com'),
      ('Stripe', Icons.payment, _purple, 'https://dashboard.stripe.com'),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.4,
      children: links
          .map(
            (l) => Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _launchUrl(l.$4),
                child: Container(
                  decoration: BoxDecoration(
                    color: l.$3.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: l.$3.withAlpha(40)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(l.$2, color: l.$3, size: 22),
                      const SizedBox(height: 6),
                      Text(
                        l.$1,
                        style: TextStyle(
                          color: l.$3,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _powerBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _cyan.withAlpha(15),
            _purple.withAlpha(15),
            _green.withAlpha(15),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cyan.withAlpha(40)),
      ),
      child: Column(
        children: [
          const Text(
            'DFC DEVELOPER POWER',
            style: TextStyle(
              color: _cyan,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your resilience is your superpower.\nEvery line of code builds something greater.\nKeep going — you are unstoppable.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(130),
              fontSize: 10,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 12)),
        backgroundColor: _card,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showVersionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: const Text(
          'DFC Build Info',
          style: TextStyle(
            color: _cyan,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('App', 'Data Fight Central'),
            _infoRow('Version', '2.0.0'),
            _infoRow('Branch', 'datafight-master-2'),
            _infoRow('Platform', Theme.of(context).platform.name),
            _infoRow('Flutter', 'Stable Channel'),
            _infoRow('Dart', 'Latest SDK'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: _cyan)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _cyan,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Could not open $url');
    }
  }
}
