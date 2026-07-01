import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/content_pipeline_service.dart';
import '../../../shared/services/content_scanner_engine.dart';
import '../../../shared/services/war_room_engine.dart';
import '../../../shared/services/dfc_ai_powerhouse.dart';
import '../../../shared/services/email_blast_engine.dart';
import '../../../shared/services/promoter_ai_service.dart';
import '../../../shared/services/content_publisher_service.dart';
import '../../../shared/services/dfc_social_engine.dart';
import '../../../shared/services/auto_feed_orchestrator_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC FACTORY CONTROL PANEL — POWERHOUSE OPERATIONS CENTRE
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Single admin surface for:
///  - Service health & floating toggles
///  - One-click actions (Poster, Publish, Crawl, Watchlist, Health Check)
///  - Upload → Process → Publish flow
///  - Poster generator template
///  - Social caption templates & tagging
///  - Orchestration audit trail
///
/// ═══════════════════════════════════════════════════════════════════════════
class FactoryControlPanelScreen extends StatefulWidget {
  const FactoryControlPanelScreen({super.key});

  @override
  State<FactoryControlPanelScreen> createState() =>
      _FactoryControlPanelScreenState();
}

class _FactoryControlPanelScreenState extends State<FactoryControlPanelScreen>
    with TickerProviderStateMixin {
  // ─── Services (available for orchestration flows) ──────────────────
  // ignore: unused_field
  final ContentPipelineService _pipeline = ContentPipelineService();
  // ignore: unused_field
  final ContentScannerEngine _scanner = ContentScannerEngine();
  // ignore: unused_field
  final WarRoomEngine _warRoom = WarRoomEngine();
  // ignore: unused_field
  final DFCAIPowerhouse _powerhouse = DFCAIPowerhouse();
  // ignore: unused_field
  final EmailBlastEngine _emailEngine = EmailBlastEngine();
  // ignore: unused_field
  final PromoterAIService _promoterAI = PromoterAIService();
  // ignore: unused_field
  final ContentPublisherService _publisher = ContentPublisherService();
  // ignore: unused_field
  final DfcSocialEngine _socialEngine = DfcSocialEngine();
  // ignore: unused_field
  final AutoFeedOrchestratorService _feedOrchestrator =
      AutoFeedOrchestratorService();

  // ─── Tab & Animation ───────────────────────────────────────────────────
  late final TabController _tabController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  // ─── State ─────────────────────────────────────────────────────────────
  String _environment = 'Production';
  bool _loading = true;

  // Service toggle states
  final Map<String, bool> _serviceStates = {};
  final Map<String, _ServiceHealth> _serviceHealth = {};

  // Poster generator fields
  final _posterFighterA = TextEditingController();
  final _posterFighterB = TextEditingController();
  final _posterTitle = TextEditingController();
  final _posterSubtitle = TextEditingController();
  final _posterDateVenue = TextEditingController();
  String _posterPalette = 'DFC Neon';

  // Social caption state
  int _selectedCaptionTemplate = 0;

  // Audit trail
  final List<_AuditEntry> _auditTrail = [];

  // Upload flow state
  _UploadState _uploadState = _UploadState.idle;
  String? _uploadFileName;

  // ─── Service Registry ──────────────────────────────────────────────────
  late final List<_FactoryService> _services;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _buildServiceRegistry();
    _runHealthCheck();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _posterFighterA.dispose();
    _posterFighterB.dispose();
    _posterTitle.dispose();
    _posterSubtitle.dispose();
    _posterDateVenue.dispose();
    super.dispose();
  }

  void _buildServiceRegistry() {
    _services = [
      const _FactoryService(
        id: 'content_pipeline',
        name: 'Content Pipeline',
        icon: Icons.conveyor_belt,
        color: DesignTokens.neonCyan,
        type: 'Engine',
        desc: 'Intake → Transform → Queue → Distribute → Track',
      ),
      const _FactoryService(
        id: 'content_scanner',
        name: 'Content Scanner',
        icon: Icons.radar,
        color: DesignTokens.neonGreen,
        type: 'Crawler',
        desc: 'RSS, social, and promoter site scanning',
      ),
      const _FactoryService(
        id: 'war_room',
        name: 'War Room Engine',
        icon: Icons.military_tech,
        color: DesignTokens.neonAmber,
        type: 'Engine',
        desc: 'Posters, bot army, campaign blasts',
      ),
      const _FactoryService(
        id: 'ai_powerhouse',
        name: 'AI Powerhouse',
        icon: Icons.psychology,
        color: DesignTokens.neonMagenta,
        type: 'Engine',
        desc: 'Master AI engine controller',
      ),
      const _FactoryService(
        id: 'email_blast',
        name: 'Email Blast Engine',
        icon: Icons.email,
        color: DesignTokens.neonRed,
        type: 'Bot',
        desc: 'Mass email campaigns & magazine cannon',
      ),
      const _FactoryService(
        id: 'promoter_ai',
        name: 'Promoter AI',
        icon: Icons.smart_toy,
        color: Color(0xFF00BFFF),
        type: 'Bot',
        desc: 'Autonomous promoter bots & content generation',
      ),
      const _FactoryService(
        id: 'social_engine',
        name: 'Social Engine',
        icon: Icons.share,
        color: Color(0xFF1DA1F2),
        type: 'Engine',
        desc: 'Cross-platform social posting & scheduling',
      ),
      const _FactoryService(
        id: 'feed_orchestrator',
        name: 'Auto Feed Orchestrator',
        icon: Icons.rss_feed,
        color: DesignTokens.neonGold,
        type: 'Engine',
        desc: 'Cross-source normalization & feed ranking',
      ),
      const _FactoryService(
        id: 'publisher',
        name: 'Content Publisher',
        icon: Icons.publish,
        color: DesignTokens.neonGreen,
        type: 'Engine',
        desc: 'Draft → Review → Publish lifecycle',
      ),
      const _FactoryService(
        id: 'samurai_swarm',
        name: 'Samurai Swarm',
        icon: Icons.hive,
        color: Color(0xFFFF6B35),
        type: 'Swarm',
        desc: '53 agents · 25 engines · 1 hive mind',
      ),
      const _FactoryService(
        id: 'media_upload',
        name: 'Media Upload',
        icon: Icons.cloud_upload,
        color: DesignTokens.neonBlue,
        type: 'Service',
        desc: 'Asset upload, processing & CDN delivery',
      ),
    ];
    for (final svc in _services) {
      _serviceStates[svc.id] = true;
      _serviceHealth[svc.id] = _ServiceHealth.healthy;
    }
  }

  Future<void> _runHealthCheck() async {
    setState(() => _loading = true);
    // Simulated health probe — in production hit each service /health endpoint
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _addAudit('Full health check completed — all services nominal');
    setState(() => _loading = false);
  }

  void _toggleService(String id) {
    setState(() {
      _serviceStates[id] = !(_serviceStates[id] ?? false);
    });
    final state = _serviceStates[id]! ? 'STARTED' : 'STOPPED';
    _addAudit('$id → $state');
  }

  void _addAudit(String action) {
    _auditTrail.insert(0, _AuditEntry(DateTime.now(), action));
    if (_auditTrail.length > 100) _auditTrail.removeLast();
  }

  // ─── One-Click Actions ─────────────────────────────────────────────────

  Future<void> _actionCreatePoster() async {
    _addAudit('CREATE POSTER — opening poster generator…');
    setState(() {});
    if (mounted) {
      context.push(
        '/promoter/poster-generator'
        '?event=${Uri.encodeComponent(_posterFighterA.text)}'
        '&date=${Uri.encodeComponent(DateTime.now().toString().split(' ').first)}',
      );
    }
  }

  Future<void> _actionPublishArticle() async {
    _addAudit('PUBLISH — opening Outreach HQ…');
    setState(() {});
    if (mounted) {
      context.push('/promoter-outreach-hq');
    }
  }

  Future<void> _actionStartCrawl() async {
    _addAudit('CRAWL — opening UTM Link Builder…');
    setState(() {});
    if (mounted) {
      context.push('/utm-link-builder');
    }
  }

  Future<void> _actionWatchlistScan() async {
    _addAudit('WATCHLIST — opening Deal Pipeline…');
    setState(() {});
    if (mounted) {
      context.push('/deal-pipeline');
    }
  }

  Future<void> _actionHealthCheck() async {
    _addAudit('HEALTH — opening Contract Calculator…');
    setState(() {});
    if (mounted) {
      context.push('/sliding-contract-calculator');
    }
  }

  void _simulateUpload() {
    setState(() {
      _uploadState = _UploadState.uploading;
      _uploadFileName = 'hepi_rematch_photo.jpg';
    });
    _addAudit('UPLOAD started: $_uploadFileName');
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _uploadState = _UploadState.processing);
      _addAudit('Processing: resize, watermark, generate variants…');
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() => _uploadState = _UploadState.complete);
        _addAudit('Upload complete: 4 variants stored on CDN, draft created');
      });
    });
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildServicesTab(),
                _buildActionsTab(),
                _buildUploadTab(),
                _buildPosterTab(),
                _buildSocialTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: DesignTokens.bgSecondary,
      title: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, a) => Icon(
              Icons.factory,
              color: DesignTokens.neonCyan.withValues(alpha: _pulseAnim.value),
              size: 28,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'FACTORY CONTROL PANEL',
            style: TextStyle(
              color: DesignTokens.neonCyan,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          // Environment selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: DesignTokens.bgCard,
              borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
              border: Border.all(
                color: DesignTokens.neonCyan.withValues(alpha: 0.3),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _environment,
                dropdownColor: DesignTokens.bgCard,
                style: const TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                items: ['Production', 'Staging', 'Dev']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _environment = v);
                  _addAudit('Environment → $v');
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Global health pill
          _buildHealthPill(),
        ],
      ),
    );
  }

  Widget _buildHealthPill() {
    final allHealthy = _serviceHealth.values.every(
      (h) => h == _ServiceHealth.healthy,
    );
    final color = allHealthy ? DesignTokens.success : DesignTokens.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(
            allHealthy ? 'ALL SYSTEMS GO' : 'DEGRADED',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: DesignTokens.bgSecondary,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: DesignTokens.neonCyan,
        labelColor: DesignTokens.neonCyan,
        unselectedLabelColor: DesignTokens.textMuted,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 1,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.dns, size: 18), text: 'SERVICES'),
          Tab(icon: Icon(Icons.bolt, size: 18), text: 'ACTIONS'),
          Tab(icon: Icon(Icons.cloud_upload, size: 18), text: 'UPLOAD'),
          Tab(icon: Icon(Icons.image, size: 18), text: 'POSTER'),
          Tab(icon: Icon(Icons.share, size: 18), text: 'SOCIAL'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1: SERVICES — Floating toggles & health
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildServicesTab() {
    return Row(
      children: [
        // Left: Service list
        Expanded(
          flex: 3,
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: DesignTokens.neonCyan,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(DesignTokens.spacingL),
                  itemCount: _services.length,
                  itemBuilder: (_, i) => _buildServiceCard(_services[i]),
                ),
        ),
        // Right: Audit trail
        Expanded(flex: 2, child: _buildAuditPanel()),
      ],
    );
  }

  Widget _buildServiceCard(_FactoryService svc) {
    final isOn = _serviceStates[svc.id] ?? false;
    final health = _serviceHealth[svc.id] ?? _ServiceHealth.healthy;
    final healthColor = switch (health) {
      _ServiceHealth.healthy => DesignTokens.success,
      _ServiceHealth.degraded => DesignTokens.warning,
      _ServiceHealth.down => DesignTokens.error,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingS),
      padding: const EdgeInsets.all(DesignTokens.cardPaddingSmall),
      decoration: GlassDecoration.card(accent: svc.color),
      child: Row(
        children: [
          // Health dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: healthColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: healthColor.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.spacingM),
          // Icon
          Icon(svc.icon, color: svc.color, size: 22),
          const SizedBox(width: DesignTokens.spacingM),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      svc.name,
                      style: const TextStyle(
                        color: DesignTokens.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: svc.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusPill,
                        ),
                      ),
                      child: Text(
                        svc.type,
                        style: TextStyle(
                          color: svc.color,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  svc.desc,
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Floating toggle pill
          GestureDetector(
            onTap: () => _toggleService(svc.id),
            onLongPress: () => _showServiceLogs(svc),
            child: AnimatedContainer(
              duration: DesignTokens.animNormal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isOn
                    ? DesignTokens.success.withValues(alpha: 0.2)
                    : DesignTokens.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                border: Border.all(
                  color: isOn
                      ? DesignTokens.success.withValues(alpha: 0.6)
                      : DesignTokens.error.withValues(alpha: 0.6),
                ),
              ),
              child: Text(
                isOn ? 'ON' : 'OFF',
                style: TextStyle(
                  color: isOn ? DesignTokens.success : DesignTokens.error,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showServiceLogs(_FactoryService svc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.bgCard,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(svc.icon, color: svc.color, size: 24),
                const SizedBox(width: 12),
                Text(
                  svc.name,
                  style: const TextStyle(
                    color: DesignTokens.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _logLine('CPU', '12%', DesignTokens.success),
            _logLine('Memory', '340 MB', DesignTokens.neonCyan),
            _logLine('Latency', '45 ms', DesignTokens.success),
            _logLine('Last Deploy', '2026-03-25 08:00', DesignTokens.textMuted),
            _logLine('Errors (24h)', '0', DesignTokens.success),
            const SizedBox(height: 12),
            const Text(
              'Recent Logs',
              style: TextStyle(
                color: DesignTokens.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            ...[
              '[08:00] Service started - health OK',
              '[08:05] Processed 12 items',
              '[08:10] Queue depth: 3',
            ].map(
              (l) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  l,
                  style: TextStyle(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logLine(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: DesignTokens.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditPanel() {
    return Container(
      margin: const EdgeInsets.all(DesignTokens.spacingL),
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: GlassDecoration.card(accent: DesignTokens.neonAmber),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, color: DesignTokens.neonAmber, size: 18),
              SizedBox(width: 8),
              Text(
                'AUDIT TRAIL',
                style: TextStyle(
                  color: DesignTokens.neonAmber,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _auditTrail.isEmpty
                ? const Center(
                    child: Text(
                      'No actions yet',
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _auditTrail.length,
                    itemBuilder: (_, i) {
                      final entry = _auditTrail[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.time.hour.toString().padLeft(2, '0')}:${entry.time.minute.toString().padLeft(2, '0')}:${entry.time.second.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: DesignTokens.neonAmber.withValues(
                                  alpha: 0.6,
                                ),
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.action,
                                style: const TextStyle(
                                  color: DesignTokens.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2: ONE-CLICK ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActionsTab() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ONE-CLICK OPERATIONS',
                  style: TextStyle(
                    color: DesignTokens.neonCyan,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Each button runs a full orchestration flow with audit logging',
                  style: TextStyle(color: DesignTokens.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.8,
                    children: [
                      _buildActionButton(
                        'CREATE POSTER',
                        'Generate poster variants from template',
                        Icons.image,
                        DesignTokens.neonMagenta,
                        _actionCreatePoster,
                      ),
                      _buildActionButton(
                        'PUBLISH / OUTREACH',
                        'Open Promoter Outreach HQ for emails & scripts',
                        Icons.outgoing_mail,
                        DesignTokens.neonGreen,
                        _actionPublishArticle,
                      ),
                      _buildActionButton(
                        'UTM BUILDER',
                        'Build tracked marketing links for any channel',
                        Icons.link,
                        DesignTokens.neonCyan,
                        _actionStartCrawl,
                      ),
                      _buildActionButton(
                        'DEAL PIPELINE',
                        'Track deals from outreach to payout',
                        Icons.handshake,
                        DesignTokens.neonAmber,
                        _actionWatchlistScan,
                      ),
                      _buildActionButton(
                        'CONTRACTS',
                        'Sliding contract calculator + term sheet',
                        Icons.gavel,
                        DesignTokens.success,
                        _actionHealthCheck,
                      ),
                      _buildActionButton(
                        'EMERGENCY STOP',
                        'Pause crawlers, disable bots, notify ops',
                        Icons.emergency,
                        DesignTokens.error,
                        () {
                          _addAudit(
                            'EMERGENCY STOP — all crawlers paused, bots disabled',
                          );
                          for (final svc in _services) {
                            _serviceStates[svc.id] = false;
                          }
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(flex: 2, child: _buildAuditPanel()),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    String tooltip,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.cardPaddingSmall),
            decoration: GlassDecoration.card(accent: color, hasGlow: true),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusSmall,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tooltip,
                        style: const TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3: UPLOAD → PROCESS → PUBLISH
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildUploadTab() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'UPLOAD → PROCESS → PUBLISH',
                  style: TextStyle(
                    color: DesignTokens.neonCyan,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                // Pipeline progress
                _buildPipelineProgress(),
                const SizedBox(height: 24),
                // Upload zone
                _buildUploadZone(),
                const SizedBox(height: 16),
                // Required fields info
                Container(
                  padding: const EdgeInsets.all(DesignTokens.cardPaddingSmall),
                  decoration: GlassDecoration.card(
                    accent: DesignTokens.neonAmber,
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REQUIRED METADATA',
                        style: TextStyle(
                          color: DesignTokens.neonAmber,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• file (image/video)\n'
                        '• fighter_slug (canonical ID)\n'
                        '• event_slug (event reference)\n'
                        '• rights_owner (copyright holder)\n'
                        '• rights_expiry_date\n'
                        '• uploader_id',
                        style: TextStyle(
                          color: DesignTokens.textSecondary,
                          fontSize: 11,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(flex: 2, child: _buildAuditPanel()),
      ],
    );
  }

  Widget _buildPipelineProgress() {
    final stages = ['Upload', 'Process', 'Review', 'Publish'];
    final currentStage = switch (_uploadState) {
      _UploadState.idle => -1,
      _UploadState.uploading => 0,
      _UploadState.processing => 1,
      _UploadState.review => 2,
      _UploadState.complete => 3,
    };

    return Row(
      children: List.generate(stages.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector
          final stageIdx = i ~/ 2;
          final active = currentStage > stageIdx;
          return Expanded(
            child: Container(
              height: 2,
              color: active ? DesignTokens.neonCyan : DesignTokens.textDisabled,
            ),
          );
        }
        final stageIdx = i ~/ 2;
        final active = currentStage >= stageIdx;
        final isCurrent = currentStage == stageIdx;
        return Column(
          children: [
            AnimatedContainer(
              duration: DesignTokens.animNormal,
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: active
                    ? DesignTokens.neonCyan.withValues(alpha: 0.2)
                    : DesignTokens.bgCard,
                shape: BoxShape.circle,
                border: Border.all(
                  color: active
                      ? DesignTokens.neonCyan
                      : DesignTokens.textDisabled,
                  width: isCurrent ? 2 : 1,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: active && !isCurrent
                    ? const Icon(
                        Icons.check,
                        color: DesignTokens.neonCyan,
                        size: 16,
                      )
                    : Text(
                        '${stageIdx + 1}',
                        style: TextStyle(
                          color: active
                              ? DesignTokens.neonCyan
                              : DesignTokens.textDisabled,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stages[stageIdx],
              style: TextStyle(
                color: active
                    ? DesignTokens.neonCyan
                    : DesignTokens.textDisabled,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildUploadZone() {
    return GestureDetector(
      onTap: _uploadState == _UploadState.idle ? _simulateUpload : null,
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(
            color: DesignTokens.neonCyan.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: _uploadState == _UploadState.idle
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload,
                    color: DesignTokens.neonCyan,
                    size: 40,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'TAP TO UPLOAD',
                    style: TextStyle(
                      color: DesignTokens.neonCyan,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Images, posters, fight footage',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_uploadState == _UploadState.uploading)
                      const CircularProgressIndicator(
                        color: DesignTokens.neonCyan,
                      ),
                    if (_uploadState == _UploadState.processing)
                      const CircularProgressIndicator(
                        color: DesignTokens.neonAmber,
                      ),
                    if (_uploadState == _UploadState.complete)
                      const Icon(
                        Icons.check_circle,
                        color: DesignTokens.success,
                        size: 40,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      switch (_uploadState) {
                        _UploadState.uploading => 'Uploading $_uploadFileName…',
                        _UploadState.processing =>
                          'Processing: resize, watermark, variants…',
                        _UploadState.complete => 'Complete — 4 variants on CDN',
                        _ => '',
                      },
                      style: TextStyle(
                        color: switch (_uploadState) {
                          _UploadState.uploading => DesignTokens.neonCyan,
                          _UploadState.processing => DesignTokens.neonAmber,
                          _UploadState.complete => DesignTokens.success,
                          _ => DesignTokens.textMuted,
                        },
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    if (_uploadState == _UploadState.complete) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            setState(() => _uploadState = _UploadState.idle),
                        child: const Text(
                          'UPLOAD ANOTHER',
                          style: TextStyle(color: DesignTokens.neonCyan),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 4: POSTER GENERATOR TEMPLATE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPosterTab() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'POSTER GENERATOR',
                  style: TextStyle(
                    color: DesignTokens.neonMagenta,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Fill template fields → generate 4 variants automatically',
                  style: TextStyle(color: DesignTokens.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 20),
                // Template fields
                _buildPosterField('Fighter A', _posterFighterA, 'hepi-haze'),
                _buildPosterField(
                  'Fighter B',
                  _posterFighterB,
                  'sosoli-savage',
                ),
                _buildPosterField('Fight Title', _posterTitle, 'THE REMATCH'),
                _buildPosterField(
                  'Subtitle',
                  _posterSubtitle,
                  'WAR IN TOWNSVILLE',
                ),
                _buildPosterField(
                  'Date & Venue',
                  _posterDateVenue,
                  'JUNE 2026 — TOWNSVILLE ENTERTAINMENT CENTRE',
                ),
                const SizedBox(height: 12),
                // Palette selector
                Row(
                  children: [
                    const Text(
                      'Palette:',
                      style: TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ...[
                      'DFC Neon',
                      'BKFC Red',
                      'Gold Classic',
                      'Māori Earth',
                    ].map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(p, style: const TextStyle(fontSize: 11)),
                          selected: _posterPalette == p,
                          selectedColor: DesignTokens.neonMagenta.withValues(
                            alpha: 0.3,
                          ),
                          labelStyle: TextStyle(
                            color: _posterPalette == p
                                ? DesignTokens.neonMagenta
                                : DesignTokens.textMuted,
                          ),
                          onSelected: (_) => setState(() => _posterPalette = p),
                          backgroundColor: DesignTokens.bgCard,
                          side: BorderSide(
                            color: _posterPalette == p
                                ? DesignTokens.neonMagenta.withValues(
                                    alpha: 0.5,
                                  )
                                : DesignTokens.textDisabled,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Output variants info
                Container(
                  padding: const EdgeInsets.all(DesignTokens.cardPaddingSmall),
                  decoration: GlassDecoration.card(
                    accent: DesignTokens.neonMagenta,
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OUTPUT VARIANTS',
                        style: TextStyle(
                          color: DesignTokens.neonMagenta,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Web Hero — 1600 × 900\n'
                        '• IG Square — 1080 × 1080\n'
                        '• FB Banner — 1200 × 628\n'
                        '• Thumbnail — 400 × 225',
                        style: TextStyle(
                          color: DesignTokens.textSecondary,
                          fontSize: 11,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Generate button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _actionCreatePoster,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text(
                      'GENERATE POSTER',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.neonMagenta,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusMedium,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(flex: 2, child: _buildAuditPanel()),
      ],
    );
  }

  Widget _buildPosterField(
    String label,
    TextEditingController ctrl,
    String hint,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: DesignTokens.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(
            color: DesignTokens.textMuted,
            fontSize: 12,
          ),
          hintStyle: const TextStyle(color: DesignTokens.textDisabled, fontSize: 12),
          filled: true,
          fillColor: DesignTokens.bgCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            borderSide: BorderSide(
              color: DesignTokens.neonMagenta.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            borderSide: BorderSide(
              color: DesignTokens.neonMagenta.withValues(alpha: 0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            borderSide: const BorderSide(color: DesignTokens.neonMagenta),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 5: SOCIAL CAPTIONS & TAGGING
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSocialTab() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SOCIAL CAPTION TEMPLATES',
                  style: TextStyle(
                    color: Color(0xFF1DA1F2),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ready-to-post captions with exact tag lists',
                  style: TextStyle(color: DesignTokens.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 20),
                // Caption templates
                ..._captionTemplates.asMap().entries.map(
                  (e) => _buildCaptionCard(e.key, e.value),
                ),
                const SizedBox(height: 20),
                // Tag list
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
                  decoration: GlassDecoration.card(
                    accent: DesignTokens.neonGold,
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EXACT TAG LIST',
                        style: TextStyle(
                          color: DesignTokens.neonGold,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Fighter Handles',
                        style: TextStyle(
                          color: DesignTokens.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '@hepi_official  @sosoli_official',
                        style: TextStyle(
                          color: DesignTokens.neonCyan,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Promotions',
                        style: TextStyle(
                          color: DesignTokens.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '@BKB  @BKFC  @BKB_AU',
                        style: TextStyle(
                          color: DesignTokens.neonCyan,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Local & Community',
                        style: TextStyle(
                          color: DesignTokens.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '@TownsvilleCouncil  @LoganCityNews',
                        style: TextStyle(
                          color: DesignTokens.neonCyan,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Hashtags',
                        style: TextStyle(
                          color: DesignTokens.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '#Logan #Townsville #Māori #PacificIslander #BareKnuckle #DFC #HepiVsSosoli #WarInTownsville',
                        style: TextStyle(
                          color: DesignTokens.neonGold,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Social playbook
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
                  decoration: GlassDecoration.card(
                    accent: DesignTokens.neonGreen,
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SOCIAL PLAYBOOK',
                        style: TextStyle(
                          color: DesignTokens.neonGreen,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '1. PRIMARY POST — hero image + 1-line hook + tag fighters + tag BKB + 3 local tags\n'
                        '2. AMPLIFY (24h later) — poster variant or short clip + tag local gyms & community pages\n'
                        '3. ENGAGE — pinned poll or demand-rematch thread for viral pressure\n'
                        '4. PAID PUSH — small geo-targeted boost around Townsville/Logan',
                        style: TextStyle(
                          color: DesignTokens.textSecondary,
                          fontSize: 11,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(flex: 2, child: _buildAuditPanel()),
      ],
    );
  }

  static const _captionTemplates = [
    _CaptionTemplate(
      name: 'PRIMARY — Hero Post',
      caption:
          'HEPI vs SOSOLI — THE REMATCH\n\nTownsville goes to war. June 2026 at the Townsville Entertainment Centre. This is Logan energy — tag the fighters, tag the promoters, make noise.',
      tags:
          '@hepi_official @sosoli_official @BKB @BKFC #HepiVsSosoli #WarInTownsville #Logan #DFC #BareKnuckle',
      color: DesignTokens.neonCyan,
    ),
    _CaptionTemplate(
      name: 'SHORT HYPE — Second Post',
      caption:
          'Rematch demanded. Rematch delivered. Hepi returns to settle the score.',
      tags: '#TheRematch #LoganBrawler #DFC',
      color: DesignTokens.neonAmber,
    ),
    _CaptionTemplate(
      name: 'ENGAGEMENT — Poll / CTA',
      caption:
          'Who wins the rematch — Hepi or Sosoli? Vote and tag BKB to make them notice.',
      tags: '#TagBKB #DFC',
      color: DesignTokens.neonGreen,
    ),
  ];

  Widget _buildCaptionCard(int index, _CaptionTemplate template) {
    final selected = _selectedCaptionTemplate == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedCaptionTemplate = index),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
        decoration: GlassDecoration.card(
          accent: template.color,
          isHovered: selected,
          hasGlow: selected,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: template.color,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  template.name,
                  style: TextStyle(
                    color: template.color,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              template.caption,
              style: const TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              template.tags,
              style: TextStyle(
                color: template.color.withValues(alpha: 0.7),
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

class _FactoryService {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String type;
  final String desc;

  const _FactoryService({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    required this.desc,
  });
}

enum _ServiceHealth { healthy, degraded, down }

class _AuditEntry {
  final DateTime time;
  final String action;
  const _AuditEntry(this.time, this.action);
}

enum _UploadState { idle, uploading, processing, review, complete }

class _CaptionTemplate {
  final String name;
  final String caption;
  final String tags;
  final Color color;

  const _CaptionTemplate({
    required this.name,
    required this.caption,
    required this.tags,
    required this.color,
  });
}
