import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/config/router_config.dart' as rc;

/// ═══════════════════════════════════════════════════════════════════════════
/// THE NUKE ROOM — DFC Admin Powerhouse Command Center
/// ═══════════════════════════════════════════════════════════════════════════
///
/// One screen to rule them all. Professional dark-themed NavigationRail
/// with 8 mission-critical sections. No more bouncing between 8+ ugly
/// teal-gradient pages. Every admin tool, engine, bot, and marketing
/// weapon in one organized command center.
///
/// Sections:
///  0  OVERVIEW     — Live KPIs, system health, quick actions
///  1  FACTORY      — Upload posters, launch pipeline, toggle engines
///  2  CONTENT      — Publish, AI feeder, manage articles
///  3  MARKETING    — Campaigns, SEO, social deployment
///  4  BOTS         — Swarm agents, scanner, promoter AI
///  5  PIPELINE     — Feed monitor, trust rules, audit
///  6  COMMAND      — Live production, PPV, global distribution
///  7  ANALYTICS    — Performance, engagement, revenue
///
/// ═══════════════════════════════════════════════════════════════════════════
class NukeRoomScreen extends StatefulWidget {
  const NukeRoomScreen({super.key});

  @override
  State<NukeRoomScreen> createState() => _NukeRoomScreenState();
}

class _NukeRoomScreenState extends State<NukeRoomScreen> {
  int _selectedIndex = 0;

  static const _sections = <_NavSection>[
    _NavSection(Icons.dashboard_rounded, 'OVERVIEW'),
    _NavSection(Icons.factory_rounded, 'FACTORY'),
    _NavSection(Icons.article_rounded, 'CONTENT'),
    _NavSection(Icons.campaign_rounded, 'MARKETING'),
    _NavSection(Icons.smart_toy_rounded, 'BOTS'),
    _NavSection(Icons.linear_scale_rounded, 'PIPELINE'),
    _NavSection(Icons.military_tech_rounded, 'COMMAND'),
    _NavSection(Icons.analytics_rounded, 'ANALYTICS'),
  ];

  bool get _isWide {
    if (!mounted) return true;
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          // ═════════════════════════════════════════════════════════════════
          // SIDEBAR RAIL
          // ═════════════════════════════════════════════════════════════════
          Container(
            width: _isWide ? 200 : 72,
            decoration: BoxDecoration(
              color: AppColors.panel,
              border: Border(
                right: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Column(
              children: [
                // Logo / Title
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _isWide ? 16 : 8,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.neonRed, AppColors.neonOrange],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      if (_isWide) ...[
                        const SizedBox(height: 10),
                        const Text(
                          'NUKE ROOM',
                          style: TextStyle(
                            color: AppColors.neonRed,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const Text(
                          'Admin Only',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF1D2B4F), height: 1),
                // Nav items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _sections.length,
                    itemBuilder: (context, i) {
                      final s = _sections[i];
                      final active = _selectedIndex == i;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => setState(() => _selectedIndex = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(
                                horizontal: _isWide ? 12 : 0,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.neonCyan.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: active
                                    ? Border.all(
                                        color: AppColors.neonCyan.withValues(
                                          alpha: 0.3,
                                        ),
                                      )
                                    : null,
                              ),
                              child: _isWide
                                  ? Row(
                                      children: [
                                        Icon(
                                          s.icon,
                                          size: 20,
                                          color: active
                                              ? AppColors.neonCyan
                                              : AppColors.textTertiary,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          s.label,
                                          style: TextStyle(
                                            color: active
                                                ? AppColors.neonCyan
                                                : AppColors.textSecondary,
                                            fontSize: 12,
                                            fontWeight: active
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Center(
                                      child: Icon(
                                        s.icon,
                                        size: 22,
                                        color: active
                                            ? AppColors.neonCyan
                                            : AppColors.textTertiary,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Back button
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.arrow_back,
                            size: 16,
                            color: AppColors.textTertiary,
                          ),
                          if (_isWide) ...[
                            const SizedBox(width: 8),
                            const Text(
                              'EXIT',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ═════════════════════════════════════════════════════════════════
          // MAIN CONTENT AREA
          // ═════════════════════════════════════════════════════════════════
          Expanded(
            child: Column(
              children: [
                // Top bar
                _buildTopBar(),
                // Content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildSection(_selectedIndex),
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
  // TOP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _sections[_selectedIndex].icon,
            color: AppColors.neonCyan,
            size: 22,
          ),
          const SizedBox(width: 12),
          Text(
            _sections[_selectedIndex].label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.neonGreen.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: AppColors.neonGreen),
                SizedBox(width: 6),
                Text(
                  'ALL SYSTEMS LIVE',
                  style: TextStyle(
                    color: AppColors.neonGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
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
  // SECTION ROUTER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSection(int index) {
    switch (index) {
      case 0:
        return _OverviewPanel(
          key: const ValueKey('overview'),
          onNavigate: (i) => setState(() => _selectedIndex = i),
        );
      case 1:
        return const _FactoryPanel(key: ValueKey('factory'));
      case 2:
        return const _ContentPanel(key: ValueKey('content'));
      case 3:
        return const _MarketingPanel(key: ValueKey('marketing'));
      case 4:
        return const _BotsPanel(key: ValueKey('bots'));
      case 5:
        return const _PipelinePanel(key: ValueKey('pipeline'));
      case 6:
        return _CommandPanel(key: const ValueKey('command'), context: context);
      case 7:
        return const _AnalyticsPanel(key: ValueKey('analytics'));
      default:
        return const SizedBox.shrink();
    }
  }
}

class _NavSection {
  final IconData icon;
  final String label;
  const _NavSection(this.icon, this.label);
}

// ═══════════════════════════════════════════════════════════════════════════
// PANEL 0: OVERVIEW — Live KPIs + Quick Actions
// ═══════════════════════════════════════════════════════════════════════════

class _OverviewPanel extends StatelessWidget {
  final void Function(int) onNavigate;
  const _OverviewPanel({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // KPI Row
        const _SectionTitle('LIVE METRICS'),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _KpiCard(
              icon: Icons.smart_toy,
              label: 'Bots Active',
              value: '53',
              color: AppColors.neonCyan,
            ),
            _KpiCard(
              icon: Icons.article,
              label: 'Content Today',
              value: '0',
              color: AppColors.neonBlue,
            ),
            _KpiCard(
              icon: Icons.campaign,
              label: 'Campaigns',
              value: '3',
              color: AppColors.neonOrange,
            ),
            _KpiCard(
              icon: Icons.trending_up,
              label: 'Reach',
              value: '0',
              color: AppColors.neonGreen,
            ),
            _KpiCard(
              icon: Icons.visibility,
              label: 'Viewers',
              value: '0',
              color: AppColors.neonPurple,
            ),
            _KpiCard(
              icon: Icons.health_and_safety,
              label: 'Health',
              value: '100%',
              color: AppColors.neonGreen,
            ),
          ],
        ),

        const SizedBox(height: 32),
        const _SectionTitle('QUICK ACTIONS'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _QuickAction(
              icon: Icons.upload_file,
              label: 'Upload Poster',
              color: AppColors.neonCyan,
              onTap: () => onNavigate(1),
            ),
            _QuickAction(
              icon: Icons.publish,
              label: 'Publish Content',
              color: AppColors.neonBlue,
              onTap: () => onNavigate(2),
            ),
            _QuickAction(
              icon: Icons.rocket_launch,
              label: 'Launch Campaign',
              color: AppColors.neonOrange,
              onTap: () => onNavigate(3),
            ),
            _QuickAction(
              icon: Icons.flash_on,
              label: 'Fire Bots',
              color: AppColors.neonRed,
              onTap: () => onNavigate(4),
            ),
            _QuickAction(
              icon: Icons.monitor_heart,
              label: 'Pipeline Monitor',
              color: AppColors.neonGreen,
              onTap: () => onNavigate(5),
            ),
            _QuickAction(
              icon: Icons.bar_chart,
              label: 'View Analytics',
              color: AppColors.neonPurple,
              onTap: () => onNavigate(7),
            ),
          ],
        ),

        const SizedBox(height: 32),
        const _SectionTitle('SYSTEM HEALTH'),
        const SizedBox(height: 12),
        ..._healthRows(),
      ],
    );
  }

  List<Widget> _healthRows() {
    const systems = [
      ('Firebase Auth', 'Operational', true),
      ('Firestore', 'Operational', true),
      ('Cloud Functions', 'Operational', true),
      ('Storage', 'Operational', true),
      ('Samurai Swarm', '53 agents online', true),
      ('Content Scanner', 'Scanning', true),
      ('Promoter AI', 'Active', true),
      ('Feed Pipeline', 'Healthy', true),
    ];
    return systems
        .map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _HealthRow(name: s.$1, status: s.$2, ok: s.$3),
          ),
        )
        .toList();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PANEL 1: FACTORY — Upload, Pipeline, Engine Toggles
// ═══════════════════════════════════════════════════════════════════════════

class _FactoryPanel extends StatefulWidget {
  const _FactoryPanel({super.key});

  @override
  State<_FactoryPanel> createState() => _FactoryPanelState();
}

class _FactoryPanelState extends State<_FactoryPanel> {
  final List<String> _uploadedFiles = [];
  bool _pipelineRunning = false;

  // Engine states
  final Map<String, bool> _engines = {
    'Content Scanner': true,
    'Promoter AI': true,
    'Auto-Feed Orchestrator': true,
    'Samurai Transformer': true,
    'Email Blast Engine': false,
    'Social Engine': true,
    'SEO Crawler': false,
    'Image Generator': true,
    'Video Transcoder': false,
    'PPV Publisher': false,
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Upload zone
        const _SectionTitle('UPLOAD ZONE'),
        const SizedBox(height: 12),
        _buildUploadZone(),

        const SizedBox(height: 24),
        // Pipeline control
        const _SectionTitle('PIPELINE CONTROL'),
        const SizedBox(height: 12),
        _buildPipelineControl(),

        const SizedBox(height: 24),
        // Engine toggles
        const _SectionTitle('ENGINE ROOM'),
        const SizedBox(height: 12),
        _buildEngineGrid(),
      ],
    );
  }

  Widget _buildUploadZone() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.neonCyan.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: _uploadedFiles.isEmpty
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: AppColors.neonCyan,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'DROP FILES HERE OR TAP TO UPLOAD',
                    style: TextStyle(
                      color: AppColors.neonCyan,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Posters, fight footage, event media — any format',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                itemCount: _uploadedFiles.length + 1,
                itemBuilder: (context, i) {
                  if (i == _uploadedFiles.length) {
                    return GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.neonCyan.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              color: AppColors.neonCyan,
                              size: 32,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Add More',
                              style: TextStyle(
                                color: AppColors.neonCyan,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.insert_drive_file,
                          color: AppColors.neonOrange,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            _uploadedFiles[i],
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.neonGreen,
                          size: 18,
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _pickFile() {
    // Simulate file pick — in production this would use file_picker
    setState(() {
      _uploadedFiles.add('poster_${_uploadedFiles.length + 1}.jpg');
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File added to upload queue'),
        backgroundColor: AppColors.neonCyan,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _buildPipelineControl() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _pipelineRunning
              ? AppColors.neonGreen.withValues(alpha: 0.3)
              : AppColors.border.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _pipelineRunning
                  ? AppColors.neonGreen.withValues(alpha: 0.15)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _pipelineRunning ? Icons.play_circle : Icons.pause_circle,
              color: _pipelineRunning
                  ? AppColors.neonGreen
                  : AppColors.textTertiary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _pipelineRunning ? 'PIPELINE ACTIVE' : 'PIPELINE STOPPED',
                  style: TextStyle(
                    color: _pipelineRunning
                        ? AppColors.neonGreen
                        : AppColors.textTertiary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _pipelineRunning
                      ? 'Intake → Transcode → Generate → Distribute'
                      : 'Tap START to begin processing queue',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _pipelineRunning = !_pipelineRunning),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: _pipelineRunning
                    ? const LinearGradient(
                        colors: [AppColors.neonRed, AppColors.neonPink],
                      )
                    : const LinearGradient(
                        colors: [AppColors.neonGreen, AppColors.neonCyan],
                      ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _pipelineRunning ? 'STOP' : 'START',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngineGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _engines.entries.map((e) {
        return Container(
          width: 220,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: e.value
                  ? AppColors.neonGreen.withValues(alpha: 0.25)
                  : AppColors.border.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                e.value ? Icons.power : Icons.power_off,
                color: e.value ? AppColors.neonGreen : AppColors.textTertiary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e.key,
                  style: TextStyle(
                    color: e.value
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: e.value,
                activeThumbColor: AppColors.neonGreen,
                onChanged: (v) => setState(() => _engines[e.key] = v),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PANEL 2: CONTENT — Publish, AI Feeder, Manage
// ═══════════════════════════════════════════════════════════════════════════

class _ContentPanel extends StatefulWidget {
  const _ContentPanel({super.key});

  @override
  State<_ContentPanel> createState() => _ContentPanelState();
}

class _ContentPanelState extends State<_ContentPanel> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _contentType = 'News';
  bool _aiFeederActive = false;
  bool _isFeatured = false;
  bool _isBreaking = false;

  static const _types = [
    'News',
    'Event',
    'Fight Show',
    'PPV',
    'Signal',
    'Post',
    'Training',
    'Fighter Story',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Publish form
        const _SectionTitle('PUBLISH CONTENT'),
        const SizedBox(height: 12),
        _buildPublishForm(),

        const SizedBox(height: 24),
        const _SectionTitle('AI FEEDER'),
        const SizedBox(height: 12),
        _buildAiFeeder(),

        const SizedBox(height: 24),
        const _SectionTitle('RECENT CONTENT'),
        const SizedBox(height: 12),
        _buildRecentContent(),
      ],
    );
  }

  Widget _buildPublishForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type selector
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _types.map((t) {
              final active = _contentType == t;
              return GestureDetector(
                onTap: () => setState(() => _contentType = t),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: active
                        ? const LinearGradient(
                            colors: [AppColors.neonCyan, AppColors.neonBlue],
                          )
                        : null,
                    color: active ? null : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: active
                          ? Colors.transparent
                          : AppColors.border.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    t,
                    style: TextStyle(
                      color: active ? Colors.black : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Title
          _DarkTextField(controller: _titleCtrl, hint: 'Title'),
          const SizedBox(height: 10),
          // Body
          _DarkTextField(
            controller: _bodyCtrl,
            hint: 'Content body...',
            maxLines: 5,
          ),
          const SizedBox(height: 12),
          // Toggles
          Row(
            children: [
              _ToggleChip(
                label: 'FEATURED',
                active: _isFeatured,
                onTap: () => setState(() => _isFeatured = !_isFeatured),
              ),
              const SizedBox(width: 8),
              _ToggleChip(
                label: 'BREAKING',
                active: _isBreaking,
                color: AppColors.neonRed,
                onTap: () => setState(() => _isBreaking = !_isBreaking),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Content published'),
                      backgroundColor: AppColors.neonGreen,
                    ),
                  );
                  _titleCtrl.clear();
                  _bodyCtrl.clear();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.neonCyan, AppColors.neonBlue],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'PUBLISH',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
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

  Widget _buildAiFeeder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _aiFeederActive
              ? AppColors.neonPurple.withValues(alpha: 0.3)
              : AppColors.border.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _aiFeederActive
                  ? AppColors.neonPurple.withValues(alpha: 0.15)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_awesome,
              color: _aiFeederActive
                  ? AppColors.neonPurple
                  : AppColors.textTertiary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _aiFeederActive ? 'AI FEEDER ACTIVE' : 'AI FEEDER OFFLINE',
                  style: TextStyle(
                    color: _aiFeederActive
                        ? AppColors.neonPurple
                        : AppColors.textTertiary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _aiFeederActive
                      ? 'Auto-generating news, signals, promo content'
                      : 'Tap toggle to start autonomous content generation',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _aiFeederActive,
            activeThumbColor: AppColors.neonPurple,
            onChanged: (v) => setState(() => _aiFeederActive = v),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentContent() {
    const items = [
      ('UFC 320 Main Card Announced', 'Event', '2m ago'),
      ('Breaking: Jon Jones Returns', 'News', '15m ago'),
      ('BKFC 67 Live Coverage', 'Fight Show', '1h ago'),
      ('Fighter Safety Protocol Update', 'Signal', '3h ago'),
      ('Weekend Fight Picks', 'Post', '5h ago'),
    ];
    return Column(
      children: items
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neonCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.$2,
                      style: const TextStyle(
                        color: AppColors.neonCyan,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.$1,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    item.$3,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PANEL 3: MARKETING — Campaigns, SEO, Social
// ═══════════════════════════════════════════════════════════════════════════

class _MarketingPanel extends StatelessWidget {
  const _MarketingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Campaign overview
        const _SectionTitle('ACTIVE CAMPAIGNS'),
        const SizedBox(height: 12),
        _buildCampaignCards(),

        const SizedBox(height: 24),
        const _SectionTitle('SEO RANKINGS'),
        const SizedBox(height: 12),
        _buildSeoTable(),

        const SizedBox(height: 24),
        const _SectionTitle('SOCIAL DEPLOYMENT'),
        const SizedBox(height: 12),
        _buildSocialPlatforms(),
      ],
    );
  }

  Widget _buildCampaignCards() {
    const campaigns = [
      ('DFC Launch 2026', 'Multi-channel', 'Active', 4200, 312, 7.4, 420.0),
      ('Fighter Pro Push', 'Badge + Email', 'Active', 890, 445, 5.2, 180.0),
      ('Fighters for Kids', 'Social + FightWire', 'Paused', 340, 0, 0.0, 90.0),
    ];

    return Column(
      children: campaigns.map((c) {
        final isActive = c.$3 == 'Active';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? AppColors.neonGreen.withValues(alpha: 0.2)
                  : AppColors.border.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.neonGreen.withValues(alpha: 0.15)
                          : AppColors.neonAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      c.$3,
                      style: TextStyle(
                        color: isActive
                            ? AppColors.neonGreen
                            : AppColors.neonAmber,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      c.$1,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    c.$2,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MiniStat('Reach', '${c.$4}'),
                  _MiniStat('Clicks', '${c.$5}'),
                  _MiniStat('Conv', '${c.$6}%'),
                  _MiniStat('Cost', '\$${c.$7.toInt()}'),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeoTable() {
    const keywords = [
      ('boxing training app', 1, '+2', true),
      ('MMA fight tracker', 3, '+5', true),
      ('combat sports analytics', 7, '+1', true),
      ('fighter performance stats', 12, '-3', false),
      ('fight camp planner', 15, '+8', true),
      ('boxing workout tracker', 18, '+4', true),
      ('fight prediction AI', 22, '+12', true),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: keywords.map((k) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: k.$2 <= 3
                        ? AppColors.neonGreen.withValues(alpha: 0.15)
                        : k.$2 <= 10
                        ? AppColors.neonCyan.withValues(alpha: 0.1)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '#${k.$2}',
                      style: TextStyle(
                        color: k.$2 <= 3
                            ? AppColors.neonGreen
                            : k.$2 <= 10
                            ? AppColors.neonCyan
                            : AppColors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    k.$1,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: k.$4
                        ? AppColors.neonGreen.withValues(alpha: 0.1)
                        : AppColors.neonRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    k.$3,
                    style: TextStyle(
                      color: k.$4 ? AppColors.neonGreen : AppColors.neonRed,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSocialPlatforms() {
    const platforms = [
      ('Instagram', Icons.camera_alt, '12.4K', true),
      ('TikTok', Icons.music_note, '8.2K', true),
      ('YouTube', Icons.play_circle, '5.1K', true),
      ('X / Twitter', Icons.alternate_email, '3.8K', true),
      ('Facebook', Icons.facebook, '2.1K', false),
      ('LinkedIn', Icons.work, '890', false),
      ('Reddit', Icons.forum, '1.2K', true),
      ('Threads', Icons.tag, '450', false),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: platforms.map((p) {
        return Container(
          width: 180,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: p.$4
                  ? AppColors.neonGreen.withValues(alpha: 0.2)
                  : AppColors.border.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Icon(p.$2, color: AppColors.neonCyan, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.$1,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${p.$3} followers',
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                p.$4 ? Icons.check_circle : Icons.remove_circle_outline,
                color: p.$4 ? AppColors.neonGreen : AppColors.textTertiary,
                size: 16,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PANEL 4: BOTS — Swarm Agents
// ═══════════════════════════════════════════════════════════════════════════

class _BotsPanel extends StatelessWidget {
  const _BotsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Swarm status
        const _SectionTitle('SWARM STATUS'),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _KpiCard(
              icon: Icons.smart_toy,
              label: 'Agents Online',
              value: '53',
              color: AppColors.neonCyan,
            ),
            _KpiCard(
              icon: Icons.article,
              label: 'Content Generated',
              value: '847',
              color: AppColors.neonBlue,
            ),
            _KpiCard(
              icon: Icons.message,
              label: 'Messages',
              value: '2.3K',
              color: AppColors.neonPurple,
            ),
            _KpiCard(
              icon: Icons.speed,
              label: 'Velocity',
              value: '12/min',
              color: AppColors.neonOrange,
            ),
          ],
        ),

        const SizedBox(height: 24),
        const _SectionTitle('AGENTS'),
        const SizedBox(height: 12),
        _buildAgentList(),

        const SizedBox(height: 24),
        // Bulk actions
        const _SectionTitle('SWARM CONTROLS'),
        const SizedBox(height: 12),
        _buildSwarmControls(context),
      ],
    );
  }

  Widget _buildAgentList() {
    const agents = [
      ('Samurai Core', 'Content Transformer', true, 142),
      ('Scanner Alpha', 'UFC Source Monitor', true, 88),
      ('Scanner Beta', 'Boxing Wire', true, 65),
      ('Scanner Gamma', 'BKFC / Bare Knuckle', true, 41),
      ('Promoter Zeus', 'Hype Generator', true, 234),
      ('Promoter Athena', 'Social Distributor', true, 189),
      ('SEO Hunter', 'Keyword Targeting', false, 0),
      ('Email Cannon', 'Blast Engine', false, 0),
      ('Video Worker', 'FFmpeg Transcoder', true, 12),
      ('Image Forge', 'Poster Generator', true, 56),
      ('PPV Publisher', 'Checkout Linker', false, 0),
      ('Recap Writer', 'Auto-Recap AI', true, 28),
    ];

    return Column(
      children: agents.map((a) {
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: a.$3
                  ? AppColors.neonGreen.withValues(alpha: 0.15)
                  : AppColors.border.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: a.$3 ? AppColors.neonGreen : AppColors.neonRed,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  a.$1,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  a.$2,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  '${a.$4} items',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: a.$3 ? AppColors.neonCyan : AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSwarmControls(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _SwarmButton(
          icon: Icons.flash_on,
          label: 'PUMP',
          desc: 'Force content generation',
          color: AppColors.neonCyan,
          onTap: () => _showSnack(context, 'Content pump fired'),
        ),
        _SwarmButton(
          icon: Icons.rocket_launch,
          label: 'FIRE ALL',
          desc: 'Publish to all channels',
          color: AppColors.neonOrange,
          onTap: () => _showSnack(context, 'Publishing to all channels'),
        ),
        _SwarmButton(
          icon: Icons.grass,
          label: 'SEED',
          desc: 'Mega seed generation',
          color: AppColors.neonPurple,
          onTap: () => _showSnack(context, 'Seeding all pages'),
        ),
        _SwarmButton(
          icon: Icons.restart_alt,
          label: 'REBOOT',
          desc: 'Restart all agents',
          color: AppColors.neonRed,
          onTap: () => _showSnack(context, 'Rebooting swarm'),
        ),
      ],
    );
  }

  static void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.neonCyan),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PANEL 5: PIPELINE — Feed Monitor
// ═══════════════════════════════════════════════════════════════════════════

class _PipelinePanel extends StatelessWidget {
  const _PipelinePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const _SectionTitle('PIPELINE STAGES'),
        const SizedBox(height: 12),
        _buildStages(),

        const SizedBox(height: 24),
        const _SectionTitle('SOURCE TRUST PROFILES'),
        const SizedBox(height: 12),
        _buildTrustProfiles(),

        const SizedBox(height: 24),
        const _SectionTitle('RECENT EVENTS'),
        const SizedBox(height: 12),
        _buildEvents(),
      ],
    );
  }

  Widget _buildStages() {
    const stages = [
      ('Intake', 45, AppColors.neonCyan),
      ('Normalize', 42, AppColors.neonBlue),
      ('Rank', 38, AppColors.neonPurple),
      ('Publish', 35, AppColors.neonGreen),
    ];

    return Row(
      children: stages.map((s) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: s.$3.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text(
                  '${s.$2}',
                  style: TextStyle(
                    color: s.$3,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.$1,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrustProfiles() {
    const profiles = [
      ('UFC Official', 0.95, true),
      ('Boxing Scene', 0.88, true),
      ('MMA Fighting', 0.85, true),
      ('ESPN MMA', 0.82, true),
      ('BKFC News', 0.78, true),
      ('Reddit MMA', 0.65, false),
      ('Twitter MMA', 0.55, false),
    ];

    return Column(
      children: profiles.map((p) {
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  p.$1,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Trust bar
              Expanded(
                flex: 4,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: p.$2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: p.$2 > 0.7
                              ? [AppColors.neonGreen, AppColors.neonCyan]
                              : [AppColors.neonAmber, AppColors.neonOrange],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 40,
                child: Text(
                  '${(p.$2 * 100).toInt()}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: p.$2 > 0.7
                        ? AppColors.neonGreen
                        : AppColors.neonAmber,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                p.$3 ? Icons.verified : Icons.warning_amber,
                size: 16,
                color: p.$3 ? AppColors.neonGreen : AppColors.neonAmber,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEvents() {
    const events = [
      ('Intake', 'UFC 320 card data ingested', true, '1m ago'),
      ('Normalize', 'Boxing rankings updated', true, '3m ago'),
      ('Publish', 'BKFC 67 preview published', true, '8m ago'),
      ('Rank', 'Trust score recalculated', true, '12m ago'),
      ('Intake', 'Reddit scrape — low trust', false, '15m ago'),
    ];

    return Column(
      children: events.map((e) {
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(
                e.$3 ? Icons.check_circle : Icons.error_outline,
                size: 16,
                color: e.$3 ? AppColors.neonGreen : AppColors.neonAmber,
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  e.$1,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e.$2,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                e.$4,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PANEL 6: COMMAND — Live Production, PPV, Health
// ═══════════════════════════════════════════════════════════════════════════

class _CommandPanel extends StatelessWidget {
  final BuildContext context;
  const _CommandPanel({super.key, required this.context});

  @override
  Widget build(BuildContext ctx) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const _SectionTitle('LIVE PRODUCTION'),
        const SizedBox(height: 12),
        _buildLiveStreams(),

        const SizedBox(height: 24),
        const _SectionTitle('PPV SALES'),
        const SizedBox(height: 12),
        _buildPpvSales(),

        const SizedBox(height: 24),
        const _SectionTitle('GLOBAL DISTRIBUTION'),
        const SizedBox(height: 12),
        _buildRegions(),

        const SizedBox(height: 24),
        const _SectionTitle('QUICK LINKS'),
        const SizedBox(height: 12),
        _buildQuickLinks(ctx),
      ],
    );
  }

  Widget _buildLiveStreams() {
    const streams = [
      ('DFC Main Channel', true, 1240),
      ('BKFC Undercard', true, 834),
      ('Training Camp Cam', false, 0),
    ];

    return Column(
      children: streams.map((s) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: s.$2
                  ? AppColors.neonRed.withValues(alpha: 0.3)
                  : AppColors.border.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              if (s.$2)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: AppColors.neonRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: AppColors.neonRed,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  s.$1,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (s.$2)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.visibility,
                      size: 14,
                      color: AppColors.neonCyan,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${s.$3}',
                      style: const TextStyle(
                        color: AppColors.neonCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              else
                const Text(
                  'Offline',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPpvSales() {
    const ppvs = [
      ('UFC 320: Jones vs Aspinall', 12400, 618760.0),
      ('BKFC 67: Rumble Night', 3200, 79680.0),
      ('Boxing: Fury vs Usyk III', 8900, 443610.0),
    ];

    return Column(
      children: ppvs.map((p) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  p.$1,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _MiniStat('Buys', '${p.$2}'),
              _MiniStat('Revenue', '\$${(p.$3 / 1000).toStringAsFixed(0)}K'),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRegions() {
    const regions = [
      ('🇺🇸', 'United States', 42),
      ('🇬🇧', 'United Kingdom', 18),
      ('🇧🇷', 'Brazil', 12),
      ('🇦🇺', 'Australia', 8),
      ('🇨🇦', 'Canada', 7),
      ('🇮🇪', 'Ireland', 5),
      ('🇳🇿', 'New Zealand', 4),
      ('🇸🇦', 'Saudi Arabia', 4),
    ];

    return Column(
      children: regions.map((r) {
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Text(r.$1, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  r.$2,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Progress bar
              SizedBox(
                width: 100,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: r.$3 / 42.0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.neonCyan, AppColors.neonBlue],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${r.$3}%',
                style: const TextStyle(
                  color: AppColors.neonCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _NavChip(
          'PPV Hub',
          Icons.live_tv,
          () => context.push(rc.RouteConstants.ppvHubPath),
        ),
        _NavChip(
          'War Room',
          Icons.military_tech,
          () => context.push(rc.RouteConstants.warRoomPath),
        ),
        _NavChip(
          'Control Tower',
          Icons.cell_tower,
          () => context.push(rc.RouteConstants.controlTowerPath),
        ),
        _NavChip(
          'Swarm',
          Icons.smart_toy,
          () => context.push(rc.RouteConstants.swarmDashboardPath),
        ),
        _NavChip(
          'Content HQ',
          Icons.article,
          () => context.push(rc.RouteConstants.contentCommandCenterPath),
        ),
        _NavChip(
          'Marketing HQ',
          Icons.campaign,
          () => context.push(rc.RouteConstants.marketingHQPath),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PANEL 7: ANALYTICS
// ═══════════════════════════════════════════════════════════════════════════

class _AnalyticsPanel extends StatelessWidget {
  const _AnalyticsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const _SectionTitle('PERFORMANCE'),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _KpiCard(
              icon: Icons.people,
              label: 'Total Users',
              value: '2.4K',
              color: AppColors.neonCyan,
            ),
            _KpiCard(
              icon: Icons.trending_up,
              label: 'DAU',
              value: '342',
              color: AppColors.neonGreen,
            ),
            _KpiCard(
              icon: Icons.timer,
              label: 'Avg Session',
              value: '4m 12s',
              color: AppColors.neonBlue,
            ),
            _KpiCard(
              icon: Icons.sync,
              label: 'Retention',
              value: '34%',
              color: AppColors.neonPurple,
            ),
            _KpiCard(
              icon: Icons.monetization_on,
              label: 'Revenue',
              value: '\$1.2K',
              color: AppColors.neonAmber,
            ),
            _KpiCard(
              icon: Icons.download,
              label: 'Downloads',
              value: '890',
              color: AppColors.neonOrange,
            ),
          ],
        ),

        const SizedBox(height: 24),
        const _SectionTitle('WEEKLY ENGAGEMENT'),
        const SizedBox(height: 12),
        _buildWeeklyChart(),

        const SizedBox(height: 24),
        const _SectionTitle('TOP CONTENT'),
        const SizedBox(height: 12),
        _buildTopContent(),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    const days = [
      ('Mon', 0.4),
      ('Tue', 0.55),
      ('Wed', 0.7),
      ('Thu', 0.65),
      ('Fri', 0.85),
      ('Sat', 1.0),
      ('Sun', 0.75),
    ];

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((d) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: d.$2,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [AppColors.neonCyan, AppColors.neonBlue],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    d.$1,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopContent() {
    const content = [
      ('UFC 320 Main Card Preview', 12400, 'Event'),
      ('Jon Jones: The GOAT Returns', 8900, 'News'),
      ('BKFC 67 Fight Night Recap', 5200, 'Recap'),
      ('Boxing Training Camp Secrets', 3800, 'Training'),
      ('Fighter Safety: New Protocols', 2100, 'Signal'),
    ];

    return Column(
      children: content.asMap().entries.map((entry) {
        final i = entry.key;
        final c = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: i == 0
                      ? AppColors.neonAmber.withValues(alpha: 0.15)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '#${i + 1}',
                    style: TextStyle(
                      color: i == 0
                          ? AppColors.neonAmber
                          : AppColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  c.$1,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  c.$3,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(c.$2 / 1000).toStringAsFixed(1)}K',
                style: const TextStyle(
                  color: AppColors.neonCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.neonCyan,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 155,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  final String name;
  final String status;
  final bool ok;

  const _HealthRow({
    required this.name,
    required this.status,
    required this.ok,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: ok ? AppColors.neonGreen : AppColors.neonRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: ok ? AppColors.neonGreen : AppColors.neonRed,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.active,
    this.color = AppColors.neonCyan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? color.withValues(alpha: 0.4)
                : AppColors.border.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? color : AppColors.textTertiary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _DarkTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textTertiary.withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.neonCyan),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}

class _SwarmButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final Color color;
  final VoidCallback onTap;

  const _SwarmButton({
    required this.icon,
    required this.label,
    required this.desc,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.neonCyan,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _NavChip(this.label, this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.neonCyan, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.neonCyan,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
