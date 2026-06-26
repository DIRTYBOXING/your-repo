import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import '../../../shared/services/media_upload_service.dart';

import 'package:provider/provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/content_pipeline_service.dart';
import '../../../shared/services/content_conveyor_belt.dart';
import '../../../shared/services/war_room_engine.dart';
import '../../../shared/services/promoter_ai_service.dart';
import '../../../shared/services/dfc_ai_powerhouse.dart';
import '../../../shared/services/email_blast_engine.dart';
import '../../../shared/services/content_scanner_engine.dart';
import '../widgets/pipeline_live_visualizer.dart';
import '../widgets/international_promo_targets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC FIGHT FACTORY — TESLA MEGA-FACTORY COMMAND CENTER
/// ═══════════════════════════════════════════════════════════════════════════
///
/// 6 Factory Bays:
///  1. DROP ZONE — Drag posters into the production line
///  2. ENGINE ROOM — 22+ machines with manual/auto controls
///  3. PIPELINE — Live conveyor belt visualization
///  4. BULLET RAIL — Email magazine cannon / mass comms
///  5. TARGETS — International promotion targeting
///  6. COMMAND — Unified powerhouse dashboard
///
/// Every service is a MACHINE. Every bot is a WORKER. You are the FOREMAN.
/// ═══════════════════════════════════════════════════════════════════════════
class FightFactoryScreen extends StatefulWidget {
  const FightFactoryScreen({super.key});

  @override
  State<FightFactoryScreen> createState() => _FightFactoryScreenState();
}

class _FightFactoryScreenState extends State<FightFactoryScreen>
    with TickerProviderStateMixin {
  // ─── Services ──────────────────────────────────────────────────────────
  final ContentPipelineService _pipeline = ContentPipelineService();
  // ignore: unused_field
  final ContentConveyorBelt _conveyor = ContentConveyorBelt();
  final WarRoomEngine _warRoom = WarRoomEngine();
  final DFCAIPowerhouse _powerhouse = DFCAIPowerhouse();
  final EmailBlastEngine _emailEngine = EmailBlastEngine();
  // ignore: unused_field
  final ContentScannerEngine _scanner = ContentScannerEngine();
  // ignore: unused_field
  final PromoterAIService _promoter = PromoterAIService();

  // ─── State ─────────────────────────────────────────────────────────────
  final List<_FactoryItem> _dropZoneItems = [];
  final List<_PipelineJob> _activeJobs = [];
  Map<String, int> _stageCounts = {};
  bool _loading = true;
  bool _engineRunning = false;
  // ignore: unused_field
  int _selectedTab = 0;
  bool _isDragHovering = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  // ignore: unused_field
  String? _errorMessage;

  // ─── Machine states (toggle on/off) ────────────────────────────────────
  final Map<String, bool> _machineStates = {};
  final Map<String, String> _machineStatuses = {};

  // ─── Email Bullet Rail state ───────────────────────────────────────────
  final TextEditingController _emailSubjectCtrl = TextEditingController();
  final TextEditingController _emailBodyCtrl = TextEditingController();
  EmailCampaignType _selectedCampaignType = EmailCampaignType.eventPromo;
  bool _emailGenerating = false;
  bool _emailFiring = false;

  // ─── Controllers ───────────────────────────────────────────────────────
  late final TabController _tabController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;
  late final AnimationController _gearController;
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final ScrollController _jobScrollCtrl = ScrollController();

  // ─── Region / Sport / Platform targets ─────────────────────────────────
  final Set<String> _selectedRegions = {'Global'};
  final Set<String> _selectedSports = {'MMA'};
  final Set<String> _selectedPlatforms = {'DFC App', 'Instagram', 'TikTok'};

  // ─── Factory Machine Registry ──────────────────────────────────────────
  late final List<_FactoryMachine> _machines;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() => _selectedTab = _tabController.index);
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _gearController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _buildMachineRegistry();
    _initialize();
  }

  void _buildMachineRegistry() {
    _machines = [
      // ── SCANNER BOTS (14) ──
      const _FactoryMachine(
        id: 'meta_scanner',
        name: 'Meta Scanner',
        icon: Icons.facebook,
        color: Color(0xFF1877F2),
        bay: 'SCANNER BAY',
        desc: 'Facebook page & group monitoring',
        type: 'Scanner Bot',
      ),
      const _FactoryMachine(
        id: 'instagram_crawler',
        name: 'Instagram Crawler',
        icon: Icons.camera_alt,
        color: Color(0xFFE4405F),
        bay: 'SCANNER BAY',
        desc: 'Hashtag & account tracking',
        type: 'Scanner Bot',
      ),
      const _FactoryMachine(
        id: 'tiktok_tracker',
        name: 'TikTok Tracker',
        icon: Icons.music_note,
        color: Color(0xFF00F2EA),
        bay: 'SCANNER BAY',
        desc: 'Viral fight content detection',
        type: 'Scanner Bot',
      ),
      const _FactoryMachine(
        id: 'youtube_monitor',
        name: 'YouTube Monitor',
        icon: Icons.play_circle_fill,
        color: Color(0xFFFF0000),
        bay: 'SCANNER BAY',
        desc: 'Video & channel monitoring',
        type: 'Scanner Bot',
      ),
      const _FactoryMachine(
        id: 'twitter_wire',
        name: 'Twitter/X Wire',
        icon: Icons.tag,
        color: Colors.white,
        bay: 'SCANNER BAY',
        desc: 'Real-time fight news wire',
        type: 'Scanner Bot',
      ),
      const _FactoryMachine(
        id: 'reddit_scanner',
        name: 'Reddit Scanner',
        icon: Icons.forum,
        color: Color(0xFFFF4500),
        bay: 'SCANNER BAY',
        desc: 'Subreddit monitoring & trending',
        type: 'Scanner Bot',
      ),
      const _FactoryMachine(
        id: 'mma_news_wire',
        name: 'MMA News Wire',
        icon: Icons.newspaper,
        color: AppTheme.neonCyan,
        bay: 'SCANNER BAY',
        desc: 'MMA Fighting, Junkie, Mania RSS',
        type: 'Scanner Bot',
      ),
      const _FactoryMachine(
        id: 'boxing_news_wire',
        name: 'Boxing News Wire',
        icon: Icons.sports_mma,
        color: AppTheme.neonOrange,
        bay: 'SCANNER BAY',
        desc: 'BoxingScene, RingTV, WBN RSS',
        type: 'Scanner Bot',
      ),
      const _FactoryMachine(
        id: 'espn_fight_desk',
        name: 'ESPN Fight Desk',
        icon: Icons.sports,
        color: Color(0xFFCC0000),
        bay: 'SCANNER BAY',
        desc: 'ESPN MMA & Boxing feeds',
        type: 'Scanner Bot',
      ),
      const _FactoryMachine(
        id: 'fight_blog_crawler',
        name: 'Fight Blog Crawler',
        icon: Icons.rss_feed,
        color: AppTheme.neonGreen,
        bay: 'SCANNER BAY',
        desc: 'Blog & independent media scrape',
        type: 'Scanner Bot',
      ),
      const _FactoryMachine(
        id: 'podcast_tracker',
        name: 'Podcast Tracker',
        icon: Icons.podcasts,
        color: Color(0xFF8B5CF6),
        bay: 'SCANNER BAY',
        desc: 'MMA Hour, Morning Kombat, JRE',
        type: 'Scanner Bot',
      ),
      const _FactoryMachine(
        id: 'event_calendar_bot',
        name: 'Event Calendar Bot',
        icon: Icons.event,
        color: AppTheme.neonMagenta,
        bay: 'SCANNER BAY',
        desc: 'UFC, Bellator, ONE, PFL, BKFC',
        type: 'Scanner Bot',
      ),
      const _FactoryMachine(
        id: 'snapchat_scanner',
        name: 'Snapchat Scanner',
        icon: Icons.photo_camera_front,
        color: Color(0xFFFFFC00),
        bay: 'SCANNER BAY',
        desc: 'Story & spotlight detection',
        type: 'Scanner Bot',
      ),
      const _FactoryMachine(
        id: 'twitch_streams',
        name: 'Twitch Streams',
        icon: Icons.live_tv,
        color: Color(0xFF9146FF),
        bay: 'SCANNER BAY',
        desc: 'Live fight stream monitoring',
        type: 'Scanner Bot',
      ),

      // ── PROMO BOTS (8) ──
      const _FactoryMachine(
        id: 'hype_bot',
        name: 'HypeBot',
        icon: Icons.local_fire_department,
        color: Color(0xFFFF6B35),
        bay: 'PROMO BAY',
        desc: 'Explosive fight hype generation',
        type: 'Promo Bot',
      ),
      const _FactoryMachine(
        id: 'spotlight_bot',
        name: 'SpotlightBot',
        icon: Icons.star,
        color: Color(0xFFFFD700),
        bay: 'PROMO BAY',
        desc: 'Fighter profile features',
        type: 'Promo Bot',
      ),
      const _FactoryMachine(
        id: 'matchmaker_bot',
        name: 'MatchmakerBot',
        icon: Icons.sports_mma,
        color: AppTheme.neonCyan,
        bay: 'PROMO BAY',
        desc: 'Dream matchup analysis',
        type: 'Promo Bot',
      ),
      const _FactoryMachine(
        id: 'trend_bot',
        name: 'TrendBot',
        icon: Icons.trending_up,
        color: AppTheme.neonGreen,
        bay: 'PROMO BAY',
        desc: 'Viral trend identification',
        type: 'Promo Bot',
      ),
      const _FactoryMachine(
        id: 'campaign_bot',
        name: 'CampaignBot',
        icon: Icons.campaign,
        color: AppTheme.neonMagenta,
        bay: 'PROMO BAY',
        desc: 'Multi-post campaigns',
        type: 'Promo Bot',
      ),
      const _FactoryMachine(
        id: 'event_bot',
        name: 'EventBot',
        icon: Icons.timer,
        color: Color(0xFF00C8FF),
        bay: 'PROMO BAY',
        desc: 'Event countdown builder',
        type: 'Promo Bot',
      ),
      const _FactoryMachine(
        id: 'viral_bot',
        name: 'ViralBot',
        icon: Icons.rocket_launch,
        color: Color(0xFFFF00FF),
        bay: 'PROMO BAY',
        desc: 'Share-worthy snippet creator',
        type: 'Promo Bot',
      ),
      const _FactoryMachine(
        id: 'analytics_bot',
        name: 'AnalyticsBot',
        icon: Icons.analytics,
        color: Color(0xFF4CAF50),
        bay: 'PROMO BAY',
        desc: 'Performance reporting',
        type: 'Promo Bot',
      ),

      // ── CORE ENGINES ──
      const _FactoryMachine(
        id: 'eso_engine',
        name: 'ESO Engine',
        icon: Icons.psychology,
        color: Color(0xFF00E5FF),
        bay: 'CORE ENGINE',
        desc: 'Kimik2.5 wellness + training AI',
        type: 'AI Engine',
      ),
      const _FactoryMachine(
        id: 'email_blast',
        name: 'Bullet Rail Gun',
        icon: Icons.email,
        color: Color(0xFFFF1744),
        bay: 'CORE ENGINE',
        desc: 'Nuclear email magazine cannon',
        type: 'Comms Engine',
      ),
      const _FactoryMachine(
        id: 'content_pipeline',
        name: 'Content Pipeline',
        icon: Icons.conveyor_belt,
        color: AppTheme.neonCyan,
        bay: 'CORE ENGINE',
        desc: '6-stage content production line',
        type: 'Pipeline',
      ),
      const _FactoryMachine(
        id: 'war_room',
        name: 'War Room',
        icon: Icons.military_tech,
        color: Color(0xFFFF6D00),
        bay: 'CORE ENGINE',
        desc: 'Bot orchestration & campaigns',
        type: 'Command',
      ),
      const _FactoryMachine(
        id: 'samurai_engine',
        name: 'Samurai Engine',
        icon: Icons.shield,
        color: Color(0xFFE91E63),
        bay: 'CORE ENGINE',
        desc: 'Content transformation & routing',
        type: 'AI Engine',
      ),
      const _FactoryMachine(
        id: 'wolverine_regen',
        name: 'Wolverine Protocol',
        icon: Icons.healing,
        color: Color(0xFF76FF03),
        bay: 'CORE ENGINE',
        desc: 'Auto-retry & self-healing ops',
        type: 'Recovery',
      ),
      const _FactoryMachine(
        id: 'feed_ranking',
        name: 'Feed Ranking Engine',
        icon: Icons.sort,
        color: Color(0xFF7C4DFF),
        bay: 'CORE ENGINE',
        desc: 'Feed priority & sort algorithms',
        type: 'AI Engine',
      ),
      const _FactoryMachine(
        id: 'auto_feed',
        name: 'Auto Feed Orchestrator',
        icon: Icons.auto_mode,
        color: Color(0xFF00BFA5),
        bay: 'CORE ENGINE',
        desc: 'Cross-source normalization',
        type: 'Pipeline',
      ),
      const _FactoryMachine(
        id: 'cdn_pipeline',
        name: 'CDN Media Pipeline',
        icon: Icons.cloud_upload,
        color: Color(0xFF448AFF),
        bay: 'CORE ENGINE',
        desc: 'Media optimization & delivery',
        type: 'Pipeline',
      ),
      const _FactoryMachine(
        id: 'content_safety',
        name: 'Content Safety',
        icon: Icons.security,
        color: Color(0xFFFF9100),
        bay: 'CORE ENGINE',
        desc: 'Trust & safety enforcement',
        type: 'Security',
      ),
      const _FactoryMachine(
        id: 'ai_moderation',
        name: 'AI Moderation',
        icon: Icons.gavel,
        color: Color(0xFFD500F9),
        bay: 'CORE ENGINE',
        desc: 'Automated content moderation',
        type: 'Security',
      ),
      const _FactoryMachine(
        id: 'combat_intel',
        name: 'Combat Intelligence',
        icon: Icons.insights,
        color: Color(0xFF1DE9B6),
        bay: 'CORE ENGINE',
        desc: 'Fight data analysis engine',
        type: 'AI Engine',
      ),

      // ── DISTRIBUTION ENGINES ──
      const _FactoryMachine(
        id: 'social_engine',
        name: 'Social Engine',
        icon: Icons.share,
        color: Color(0xFF2196F3),
        bay: 'DISTRIBUTION',
        desc: 'Multi-platform social posting',
        type: 'Distribution',
      ),
      const _FactoryMachine(
        id: 'streaming_engine',
        name: 'Streaming Engine',
        icon: Icons.videocam,
        color: Color(0xFFE040FB),
        bay: 'DISTRIBUTION',
        desc: 'Live PPV & video streaming',
        type: 'Distribution',
      ),
      const _FactoryMachine(
        id: 'push_notifications',
        name: 'Push Cannon',
        icon: Icons.notifications_active,
        color: Color(0xFFFF5252),
        bay: 'DISTRIBUTION',
        desc: 'Mass push notification fire',
        type: 'Distribution',
      ),
      const _FactoryMachine(
        id: 'realtime_ws',
        name: 'WebSocket Live',
        icon: Icons.bolt,
        color: Color(0xFFFFD740),
        bay: 'DISTRIBUTION',
        desc: 'Real-time data broadcasting',
        type: 'Distribution',
      ),
      const _FactoryMachine(
        id: 'sponsor_feed',
        name: 'Sponsor Feed Engine',
        icon: Icons.monetization_on,
        color: Color(0xFF69F0AE),
        bay: 'DISTRIBUTION',
        desc: 'Sponsored content placement',
        type: 'Revenue',
      ),
    ];

    // Initialize all machines as ON
    for (final m in _machines) {
      _machineStates[m.id] = true;
      _machineStatuses[m.id] = 'ONLINE';
    }
  }

  Future<void> _initialize() async {
    try {
      await _warRoom.initialize();
      final counts = await _pipeline.getStageCounts();
      // Boot powerhouse engines
      try {
        await _powerhouse.bootAllEngines();
      } catch (_) {}
      try {
        await _emailEngine.initialize();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _stageCounts = counts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Engine init: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _gearController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _jobScrollCtrl.dispose();
    _emailSubjectCtrl.dispose();
    _emailBodyCtrl.dispose();
    super.dispose();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // ══ OWNER-ONLY ACCESS GATE ══════════════════════════════════════════
    // The Fight Factory is TOP SECRET. Only the platform owner can enter.
    final auth = context.watch<AuthService>();
    if (!auth.isOwner) {
      return _buildAccessDenied();
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: _buildAppBar(),
      body: _loading
          ? _buildFactoryBootScreen()
          : Column(
              children: [
                _buildEngineStatusBar(),
                _buildTabBar(),
                Expanded(child: _buildTabView()),
              ],
            ),
    );
  }

  /// Access-denied screen for non-owner users.
  Widget _buildAccessDenied() {
    return Scaffold(
      backgroundColor: const Color(0xFF050A14),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFF3366).withValues(alpha: 0.6),
                  width: 3,
                ),
              ),
              child: const Icon(Icons.lock, color: Color(0xFFFF3366), size: 64),
            ),
            const SizedBox(height: 32),
            const Text(
              'TOP SECRET',
              style: TextStyle(
                color: Color(0xFFFF3366),
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'FIGHT FACTORY — OWNER ACCESS ONLY',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This facility is restricted to the DFC platform owner.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 32),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Color(0xFF00F5FF)),
              label: const Text(
                'GO BACK',
                style: TextStyle(
                  color: Color(0xFF00F5FF),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── FACTORY BOOT SCREEN — Cinematic loading ──────────────────────────
  Widget _buildFactoryBootScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF050A14), Color(0xFF0A1628), Color(0xFF050A14)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Spinning gear
            AnimatedBuilder(
              animation: _gearController,
              builder: (_, child) => Transform.rotate(
                angle: _gearController.value * 2 * math.pi,
                child: child,
              ),
              child: Icon(
                Icons.settings,
                color: AppTheme.neonCyan.withValues(alpha: 0.8),
                size: 72,
              ),
            ),
            const SizedBox(height: 24),
            // Factory name
            const Text(
              'DFC FIGHT FACTORY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'POWERING UP ${_machines.length} MACHINES',
              style: TextStyle(
                color: AppTheme.neonCyan.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 32),
            // Boot progress bar
            SizedBox(
              width: 300,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      backgroundColor: Color(0xFF1A2744),
                      valueColor: AlwaysStoppedAnimation(AppTheme.neonCyan),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, _) => Text(
                      'INITIALIZING ENGINES...',
                      style: TextStyle(
                        color: AppTheme.neonGreen.withValues(
                          alpha: _pulseAnim.value,
                        ),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0A0E1A),
      elevation: 0,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, _) => Icon(
              Icons.factory_outlined,
              color: _engineRunning
                  ? AppTheme.neonGreen.withValues(alpha: _pulseAnim.value)
                  : AppTheme.neonCyan,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'FIGHT FACTORY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
      actions: [
        // Engine toggle
        IconButton(
          icon: Icon(
            _engineRunning ? Icons.pause_circle : Icons.play_circle,
            color: _engineRunning ? AppTheme.neonGreen : AppTheme.neonMagenta,
            size: 28,
          ),
          tooltip: _engineRunning ? 'Pause Pipeline' : 'Start Pipeline',
          onPressed: _toggleEngine,
        ),
        // Refresh
        IconButton(
          icon: const Icon(Icons.refresh, color: AppTheme.neonCyan),
          onPressed: _refreshCounts,
        ),
      ],
    );
  }

  // ─── Engine Status Bar ─────────────────────────────────────────────────
  Widget _buildEngineStatusBar() {
    final total = _stageCounts.values.fold(0, (a, b) => a + b);
    final inPipeline =
        total - (_stageCounts['complete'] ?? 0) - (_stageCounts['failed'] ?? 0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        border: Border(
          bottom: BorderSide(
            color: _engineRunning
                ? AppTheme.neonGreen.withValues(alpha: 0.4)
                : AppTheme.neonCyan.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Engine status indicator
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _engineRunning ? AppTheme.neonGreen : Colors.grey,
              boxShadow: _engineRunning
                  ? [
                      BoxShadow(
                        color: AppTheme.neonGreen.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _engineRunning ? 'ENGINE LIVE' : 'ENGINE IDLE',
            style: TextStyle(
              color: _engineRunning ? AppTheme.neonGreen : Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          _statChip('IN PIPELINE', '$inPipeline', AppTheme.neonCyan),
          const SizedBox(width: 12),
          _statChip(
            'PUBLISHED',
            '${_stageCounts['complete'] ?? 0}',
            AppTheme.neonGreen,
          ),
          const SizedBox(width: 12),
          _statChip(
            'FAILED',
            '${_stageCounts['failed'] ?? 0}',
            AppTheme.neonMagenta,
          ),
          const SizedBox(width: 12),
          _statChip(
            'BOTS ACTIVE',
            '${_warRoom.activeBots}/${_warRoom.totalBots}',
            AppTheme.neonOrange,
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.6),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  // ─── Tab Bar ───────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF0A0E1A),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppTheme.neonCyan,
        indicatorWeight: 3,
        labelColor: AppTheme.neonCyan,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          fontSize: 11,
        ),
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(icon: Icon(Icons.upload_file, size: 18), text: 'DROP ZONE'),
          Tab(
            icon: Icon(Icons.precision_manufacturing, size: 18),
            text: 'ENGINE ROOM',
          ),
          Tab(icon: Icon(Icons.conveyor_belt, size: 18), text: 'PIPELINE'),
          Tab(icon: Icon(Icons.rocket_launch, size: 18), text: 'BULLET RAIL'),
          Tab(icon: Icon(Icons.public, size: 18), text: 'TARGETS'),
          Tab(icon: Icon(Icons.dashboard, size: 18), text: 'COMMAND'),
        ],
      ),
    );
  }

  Widget _buildTabView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildDropZoneTab(),
        _buildEngineRoomTab(),
        PipelineLiveVisualizer(
          stageCounts: _stageCounts,
          activeJobs: _activeJobs
              .map(
                (j) => PipelineJobInfo(
                  id: j.id,
                  title: j.title,
                  stage: j.currentStage,
                  imageUrl: j.imageUrl,
                  sport: j.sport,
                  region: j.region,
                  progress: j.progress,
                  startedAt: j.startedAt,
                ),
              )
              .toList(),
          onRefresh: _refreshCounts,
        ),
        _buildBulletRailTab(),
        InternationalPromoTargets(
          selectedRegions: _selectedRegions,
          selectedSports: _selectedSports,
          selectedPlatforms: _selectedPlatforms,
          botActivity: _warRoom.botActivity,
          blasts: _warRoom.blasts,
          onRegionToggle: (r) => setState(() {
            _selectedRegions.contains(r)
                ? _selectedRegions.remove(r)
                : _selectedRegions.add(r);
          }),
          onSportToggle: (s) => setState(() {
            _selectedSports.contains(s)
                ? _selectedSports.remove(s)
                : _selectedSports.add(s);
          }),
          onPlatformToggle: (p) => setState(() {
            _selectedPlatforms.contains(p)
                ? _selectedPlatforms.remove(p)
                : _selectedPlatforms.add(p);
          }),
          onFireBlast: _fireCampaignBlast,
        ),
        _buildCommandTab(),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TAB 1 — DROP ZONE (Drag & Drop Poster/Image Upload)
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildDropZoneTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT — Drop zone + metadata form
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildDragDropZone(),
                const SizedBox(height: 16),
                _buildMetadataForm(),
                const SizedBox(height: 12),
                _buildLaunchButton(),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // RIGHT — Queued items ready to fire
          Expanded(flex: 2, child: _buildQueuedItems()),
        ],
      ),
    );
  }

  // ─── Drag & Drop Zone ─────────────────────────────────────────────────
  Widget _buildDragDropZone() {
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) {
        setState(() => _isDragHovering = true);
        return true;
      },
      onLeave: (_) => setState(() => _isDragHovering = false),
      onAcceptWithDetails: (details) {
        setState(() => _isDragHovering = false);
        _handleExternalDrop(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: _pickFiles,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 220,
            decoration: BoxDecoration(
              color: _isDragHovering
                  ? AppTheme.neonCyan.withValues(alpha: 0.08)
                  : const Color(0xFF0D1B2A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isDragHovering
                    ? AppTheme.neonCyan
                    : AppTheme.neonCyan.withValues(alpha: 0.25),
                width: _isDragHovering ? 2.5 : 1.5,
              ),
              boxShadow: _isDragHovering
                  ? [
                      BoxShadow(
                        color: AppTheme.neonCyan.withValues(alpha: 0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: _dropZoneItems.isEmpty
                ? _buildEmptyDropZone()
                : _buildDropZoneWithItems(),
          ),
        );
      },
    );
  }

  Widget _buildEmptyDropZone() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, _) => Icon(
              Icons.cloud_upload_outlined,
              size: 56,
              color: AppTheme.neonCyan.withValues(alpha: _pulseAnim.value),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isDragHovering ? 'DROP IT' : 'DRAG POSTERS & IMAGES HERE',
            style: TextStyle(
              color: _isDragHovering ? AppTheme.neonCyan : Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'or tap to browse • PNG, JPG, WEBP up to 20MB',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.neonMagenta.withValues(alpha: 0.4),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'REAL POSTERS • REAL EVENTS • REAL PROMOTION',
              style: TextStyle(
                color: AppTheme.neonMagenta,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropZoneWithItems() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image, color: AppTheme.neonCyan, size: 16),
              const SizedBox(width: 6),
              Text(
                '${_dropZoneItems.length} FILE${_dropZoneItems.length > 1 ? 'S' : ''} LOADED',
                style: const TextStyle(
                  color: AppTheme.neonCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('ADD MORE'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.neonCyan,
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(_dropZoneItems.clear),
                icon: const Icon(Icons.clear_all, size: 16, color: Colors.grey),
                label: const Text(
                  'CLEAR',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _dropZoneItems.length,
              itemBuilder: (ctx, i) {
                final item = _dropZoneItems[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _buildDroppedItemCard(item, i),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDroppedItemCard(_FactoryItem item, int index) {
    return Draggable<int>(
      data: index,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 120,
          height: 140,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.neonCyan, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonCyan.withValues(alpha: 0.3),
                blurRadius: 12,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.image, color: AppTheme.neonCyan, size: 40),
          ),
        ),
      ),
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: const Color(0xFF101828),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.neonCyan.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            // Poster thumbnail
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
                  color: Color(0xFF1A2744),
                ),
                child: item.imageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(9),
                        ),
                        child: DfcNetworkImage(
                          url: item.imageUrl!,
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.image,
                              color: AppTheme.neonCyan,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.fileName ?? 'poster',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 9,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            // Remove button
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFF1A2744)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _dropZoneItems.removeAt(index)),
                    child: const Icon(
                      Icons.close,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Metadata Form ─────────────────────────────────────────────────────
  Widget _buildMetadataForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EVENT DETAILS',
            style: TextStyle(
              color: AppTheme.neonCyan,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          // Title
          _factoryTextField(
            controller: _titleCtrl,
            hint: 'Event title — e.g. "DFC Brisbane Fight Night 12"',
            icon: Icons.title,
          ),
          const SizedBox(height: 10),
          // Description
          _factoryTextField(
            controller: _descCtrl,
            hint: 'Description / fighter card / venue info',
            icon: Icons.description_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          // Sport + Region quick selectors (inline chips)
          Row(
            children: [
              const Text(
                'SPORT:',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              ..._buildInlineSportChips(),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'REGION:',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              ..._buildInlineRegionChips(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _factoryTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppTheme.neonCyan, size: 18),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        filled: true,
        fillColor: const Color(0xFF101828),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppTheme.neonCyan.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppTheme.neonCyan.withValues(alpha: 0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.neonCyan, width: 1.5),
        ),
      ),
    );
  }

  List<Widget> _buildInlineSportChips() {
    const sports = ['MMA', 'Boxing', 'BKFC', 'Muay Thai', 'Kickboxing', 'BJJ'];
    return sports
        .map(
          (s) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _miniChip(
              s,
              _selectedSports.contains(s),
              () => setState(() {
                _selectedSports.contains(s)
                    ? _selectedSports.remove(s)
                    : _selectedSports.add(s);
              }),
            ),
          ),
        )
        .toList();
  }

  List<Widget> _buildInlineRegionChips() {
    const regions = ['Global', 'AU', 'NZ', 'US', 'UK', 'Asia', 'EU'];
    return regions
        .map(
          (r) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _miniChip(
              r,
              _selectedRegions.contains(r),
              () => setState(() {
                _selectedRegions.contains(r)
                    ? _selectedRegions.remove(r)
                    : _selectedRegions.add(r);
              }),
            ),
          ),
        )
        .toList();
  }

  Widget _miniChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.neonCyan.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppTheme.neonCyan
                : Colors.white.withValues(alpha: 0.15),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.neonCyan : Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ─── Launch Button ─────────────────────────────────────────────────────
  Widget _buildLaunchButton() {
    final hasItems = _dropZoneItems.isNotEmpty;
    final hasTitle = _titleCtrl.text.trim().isNotEmpty;
    final canLaunch = hasItems && hasTitle && !_isUploading;

    return Column(
      children: [
        if (_isUploading) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: const Color(0xFF1A2744),
              valueColor: const AlwaysStoppedAnimation(AppTheme.neonCyan),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'UPLOADING ${(_uploadProgress * 100).toInt()}%  —  INJECTING INTO WATERFALL...',
            style: TextStyle(
              color: AppTheme.neonCyan.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: canLaunch ? _launchIntoPipeline : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isUploading
                  ? const Color(0xFF0D2847)
                  : canLaunch
                  ? AppTheme.neonCyan
                  : const Color(0xFF1A2744),
              foregroundColor: canLaunch ? Colors.black : Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: canLaunch ? 4 : 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isUploading
                      ? Icons.cloud_upload
                      : canLaunch
                      ? Icons.rocket_launch
                      : Icons.block,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  _isUploading
                      ? 'UPLOADING TO DFC PIPELINE...'
                      : canLaunch
                      ? 'LAUNCH INTO PIPELINE  →  ${_selectedRegions.join(", ")}'
                      : 'ADD POSTER + EVENT TITLE TO LAUNCH',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Queued Items Panel ────────────────────────────────────────────────
  Widget _buildQueuedItems() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonMagenta.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.conveyor_belt,
                color: AppTheme.neonMagenta,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'PIPELINE QUEUE',
                style: TextStyle(
                  color: AppTheme.neonMagenta,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Text(
                '${_activeJobs.length}',
                style: const TextStyle(
                  color: AppTheme.neonMagenta,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_activeJobs.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox,
                      color: Colors.white.withValues(alpha: 0.15),
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No active jobs',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Drop posters and launch',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.2),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _jobScrollCtrl,
                itemCount: _activeJobs.length,
                itemBuilder: (_, i) => _buildJobCard(_activeJobs[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJobCard(_PipelineJob job) {
    final stageColor = _stageColor(job.currentStage);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF101828),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: stageColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + stage badge
          Row(
            children: [
              Expanded(
                child: Text(
                  job.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: stageColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: stageColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  job.currentStage.toUpperCase(),
                  style: TextStyle(
                    color: stageColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: job.progress,
              backgroundColor: const Color(0xFF1A2744),
              valueColor: AlwaysStoppedAnimation(stageColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          // Metadata
          Row(
            children: [
              Text(
                '${job.sport} • ${job.region}',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
              const Spacer(),
              Text(
                '${(job.progress * 100).toInt()}%',
                style: TextStyle(
                  color: stageColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═════════════════════════════════════════════════════════════════════════

  void _toggleEngine() {
    setState(() => _engineRunning = !_engineRunning);
    if (_engineRunning) {
      _warRoom.startEngine();
      _startPipelineSimulation();
    } else {
      _warRoom.stopEngine();
    }
  }

  Future<void> _refreshCounts() async {
    try {
      final counts = await _pipeline.getStageCounts();
      if (mounted) setState(() => _stageCounts = counts);
    } catch (_) {}
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true, // get bytes for web + native
      );
      if (result == null || result.files.isEmpty) return;
      setState(() {
        for (final file in result.files) {
          if (file.bytes != null && file.bytes!.isNotEmpty) {
            _dropZoneItems.add(
              _FactoryItem(
                id: 'pick_${DateTime.now().millisecondsSinceEpoch}_${file.name}',
                fileName: file.name,
                bytes: file.bytes,
              ),
            );
          }
        }
      });
    } catch (e) {
      debugPrint('FightFactory: file pick failed: $e');
    }
  }

  void _handleExternalDrop(String data) {
    // Handle URL drops (e.g. dragged from browser)
    if (data.startsWith('http')) {
      setState(() {
        _dropZoneItems.add(
          _FactoryItem(
            id: 'drop_${DateTime.now().millisecondsSinceEpoch}',
            fileName: data.split('/').last,
            imageUrl: data,
          ),
        );
      });
    }
  }

  /// LAUNCH — uploads posters to Firebase Storage, writes to ingested_content
  /// for waterfall promotion, and to content_pipeline for the existing flow.
  /// DFC owns all promotional rights. PPV sales → DFC. Broadcast rights → DFC.
  Future<void> _launchIntoPipeline() async {
    if (_dropZoneItems.isEmpty || _titleCtrl.text.trim().isEmpty) return;

    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final regions = _selectedRegions.toList();
    final sports = _selectedSports.toList();
    final platforms = _selectedPlatforms.toList();
    final auth = context.read<AuthService>();
    final userId = auth.currentUser?.uid ?? 'dfc_owner';
    final uploader = MediaUploadService();
    final db = FirebaseFirestore.instance;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    final totalItems = _dropZoneItems.length;
    int completed = 0;

    for (final item in _dropZoneItems) {
      try {
        String? posterUrl = item.imageUrl;

        // ── UPLOAD to Firebase Storage if we have raw bytes ──
        if (item.bytes != null && item.bytes!.isNotEmpty) {
          final result = await uploader.uploadImage(
            imageBytes: item.bytes!,
            userId: userId,
            type: MediaUploadType.event,
            onProgress: (p) {
              if (mounted) {
                setState(() {
                  _uploadProgress = (completed + p) / totalItems;
                });
              }
            },
          );
          if (result.success && result.url != null) {
            posterUrl = result.url;
          }
        }

        // ── WRITE to ingested_content for WATERFALL promotion ──
        // This is the real pipeline — waterfall scores, tiers, and promotes.
        final ingestId =
            'dfc_poster_${DateTime.now().millisecondsSinceEpoch}_$completed';
        await db.collection('ingested_content').doc(ingestId).set({
          'title': title,
          'summary': desc.isNotEmpty ? desc : 'DFC event poster: $title',
          'source': 'DFC Fight Factory',
          'category': sports.isNotEmpty
              ? sports.first.toLowerCase().replaceAll(' ', '_')
              : 'general',
          'url': posterUrl ?? '',
          'imageUrl': posterUrl,
          'publishedAt': DateTime.now().toIso8601String(),
          'tags': [...sports, ...regions, 'poster', 'event', 'dfc_original'],
          'region': regions.isNotEmpty ? regions.first.toLowerCase() : 'global',
          'isBreaking': false,
          'isFeatured': true, // DFC owner content gets featured
          'trustScore': 1.0, // Maximum trust — we own the pipeline
          'authorName': 'DFC Fight Factory',
          'attribution': '© DataFightCentral — All rights reserved',
          'status': 'new', // Waterfall will pick this up
          // ── DFC OWNERSHIP FLAGS ──
          'dfcOriginal': true,
          'promotionAccess': 'dfc_owner', // Full pipeline access
          'ppvRightsDfc': true, // All PPV sales → DFC
          'broadcastRights': 'dfc_exclusive', // DFC owns broadcast
          'licenseType': 'dfc_owned',
          'fileName': item.fileName,
          'uploadedBy': userId,
          'uploadedAt': FieldValue.serverTimestamp(),
        });

        // ── ALSO write to content_pipeline (existing flow) ──
        final docId = await _pipeline.intake(
          contentType: 'event',
          title: title,
          body: desc.isNotEmpty ? desc : 'Fight event promotion for $title',
          imageUrl: posterUrl,
          targetPlatforms: platforms,
          metadata: {
            'regions': regions,
            'sports': sports,
            'fileName': item.fileName,
            'source': 'fight_factory',
            'dfcOriginal': true,
            'ppvRightsDfc': true,
            'broadcastRights': 'dfc_exclusive',
            'launchedAt': DateTime.now().toIso8601String(),
          },
        );

        // Add to active jobs tracker
        final job = _PipelineJob(
          id: docId,
          title: title,
          imageUrl: posterUrl,
          sport: sports.isNotEmpty ? sports.first : 'MMA',
          region: regions.join(', '),
          currentStage: 'intake',
          progress: 0.0,
          startedAt: DateTime.now(),
        );
        setState(() => _activeJobs.insert(0, job));

        // Also create a War Room poster entry for international promotion
        await _warRoom.addPoster(
          eventTitle: title,
          imageUrl: posterUrl ?? '',
          eventDate: DateTime.now().add(const Duration(days: 14)),
          region: regions.isNotEmpty ? regions.first : 'Global',
          sportType: sports.isNotEmpty ? sports.first : 'MMA',
        );

        completed++;
        if (mounted) {
          setState(() => _uploadProgress = completed / totalItems);
        }
      } catch (e) {
        debugPrint('FightFactory: launch failed for item: $e');
      }
    }

    // Clear the drop zone
    setState(() {
      _dropZoneItems.clear();
      _titleCtrl.clear();
      _descCtrl.clear();
      _isUploading = false;
      _uploadProgress = 0.0;
    });

    // Switch to pipeline tab to watch them flow
    _tabController.animateTo(1);

    // If engine is running, start processing
    if (_engineRunning) {
      _advanceJobs();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.neonGreen,
          content: Text(
            '$completed poster(s) uploaded & launched into waterfall → ${regions.join(", ")}',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
  }

  /// Fire a campaign blast through War Room
  Future<void> _fireCampaignBlast() async {
    await _warRoom.fireCampaignBlast(
      name: 'Fight Factory Blast ${DateTime.now().millisecondsSinceEpoch}',
      targetRegion: _selectedRegions.first,
      sportTypes: _selectedSports.toList(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.neonMagenta,
          content: Text(
            'CAMPAIGN BLAST FIRED → ${_selectedRegions.join(", ")} • ${_selectedSports.join(", ")}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }
  }

  // ─── Pipeline Simulation (advances jobs through stages) ────────────────
  Timer? _simTimer;

  void _startPipelineSimulation() {
    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_engineRunning) {
        _simTimer?.cancel();
        return;
      }
      _advanceJobs();
    });
  }

  void _advanceJobs() {
    const stageOrder = [
      'intake',
      'transform',
      'queue',
      'distribute',
      'track',
      'complete',
    ];
    bool changed = false;

    for (int i = 0; i < _activeJobs.length; i++) {
      final job = _activeJobs[i];
      final stageIdx = stageOrder.indexOf(job.currentStage);
      if (stageIdx >= 0 && stageIdx < stageOrder.length - 1) {
        final nextStage = stageOrder[stageIdx + 1];
        final newProgress = (stageIdx + 2) / stageOrder.length;
        _activeJobs[i] = job.copyWith(
          currentStage: nextStage,
          progress: newProgress,
        );
        changed = true;

        // Actually advance in Firestore
        _pipeline.advanceStage(job.id, nextStage);
      }
    }

    // Remove completed jobs after a delay
    _activeJobs.removeWhere((j) => j.currentStage == 'complete');

    if (changed && mounted) {
      setState(() {});
      _refreshCounts();
    }
  }

  Color _stageColor(String stage) {
    switch (stage) {
      case 'intake':
        return AppTheme.neonCyan;
      case 'transform':
        return AppTheme.neonMagenta;
      case 'queue':
        return AppTheme.neonOrange;
      case 'distribute':
        return AppTheme.neonPurple;
      case 'track':
        return const Color(0xFF00C8FF);
      case 'complete':
        return AppTheme.neonGreen;
      case 'failed':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TAB 2 — ENGINE ROOM (22+ Machines with toggle controls)
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildEngineRoomTab() {
    final bayGroups = <String, List<_FactoryMachine>>{};
    for (final m in _machines) {
      bayGroups.putIfAbsent(m.bay, () => []).add(m);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Full Engine Room Dashboard Launcher ──
        GestureDetector(
          onTap: () => context.push('/engine-room'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.neonCyan.withValues(alpha: 0.15),
                  AppTheme.neonMagenta.withValues(alpha: 0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.4),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.precision_manufacturing,
                  color: AppTheme.neonCyan,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FULL ENGINE ROOM DASHBOARD',
                        style: TextStyle(
                          color: AppTheme.neonCyan,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Pipeline • Hype Engine • Adrenaline Dump • Balance • Telemetry',
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.neonCyan,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        for (final bay in bayGroups.keys) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.neonCyan,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  bay,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const Spacer(),
                Text(
                  '${bayGroups[bay]!.length} MACHINES',
                  style: TextStyle(
                    color: AppTheme.neonCyan.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          ...bayGroups[bay]!.map(_buildMachineCard),
        ],
      ],
    );
  }

  Widget _buildMachineCard(_FactoryMachine m) {
    final isOn = _machineStates[m.id] ?? false;
    final status = _machineStatuses[m.id] ?? 'STANDBY';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOn
              ? m.color.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(m.icon, color: isOn ? m.color : Colors.grey, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
                  style: TextStyle(
                    color: isOn ? Colors.white : Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  m.desc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: isOn ? AppTheme.neonGreen : Colors.grey,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: isOn,
            activeThumbColor: m.color,
            onChanged: (v) {
              setState(() {
                _machineStates[m.id] = v;
                _machineStatuses[m.id] = v ? 'RUNNING' : 'STANDBY';
              });
            },
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TAB 4 — BULLET RAIL (Email Magazine Cannon)
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildBulletRailTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Campaign type selector
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFF1744).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.email, color: Color(0xFFFF1744), size: 24),
                  SizedBox(width: 8),
                  Text(
                    'BULLET RAIL GUN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<EmailCampaignType>(
                initialValue: _selectedCampaignType,
                dropdownColor: const Color(0xFF0D1B2A),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'CAMPAIGN TYPE',
                  labelStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFF1744)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: EmailCampaignType.values.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(t.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedCampaignType = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailSubjectCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'SUBJECT LINE',
                  labelStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFF1744)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailBodyCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: 'EMAIL BODY',
                  labelStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFF1744)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _emailGenerating
                          ? null
                          : _generateEmailContent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A2744),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _emailGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.auto_awesome,
                              color: AppTheme.neonCyan,
                            ),
                      label: Text(
                        _emailGenerating ? 'GENERATING...' : 'AI GENERATE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          (_emailFiring || _emailSubjectCtrl.text.isEmpty)
                          ? null
                          : _fireEmailBlast,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF1744),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _emailFiring
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.rocket_launch,
                              color: Colors.white,
                            ),
                      label: Text(
                        _emailFiring ? 'FIRING...' : 'FIRE BLAST',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _generateEmailContent() async {
    setState(() => _emailGenerating = true);
    try {
      final content = await _emailEngine.generateEmailContent(
        campaignType: _selectedCampaignType,
        targetAudience: _emailSubjectCtrl.text.isNotEmpty
            ? _emailSubjectCtrl.text
            : null,
      );
      if (mounted && content != null) {
        setState(() {
          _emailSubjectCtrl.text = content.subjectLine;
          _emailBodyCtrl.text = content.body;
        });
      }
    } catch (_) {
      // Email engine may not be fully wired yet
    } finally {
      if (mounted) setState(() => _emailGenerating = false);
    }
  }

  Future<void> _fireEmailBlast() async {
    setState(() => _emailFiring = true);
    try {
      await _emailEngine.sendCampaign(
        subject: _emailSubjectCtrl.text,
        htmlBody: _emailBodyCtrl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('BLAST FIRED'),
            backgroundColor: Color(0xFFFF1744),
          ),
        );
      }
    } catch (_) {
      // Silently handle
    } finally {
      if (mounted) setState(() => _emailFiring = false);
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TAB 6 — COMMAND (Unified powerhouse dashboard)
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildCommandTab() {
    final totalMachines = _machines.length;
    final runningCount = _machineStates.values.where((v) => v).length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Factory stats overview
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0D1B2A),
                AppTheme.neonCyan.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              const Text(
                'FACTORY STATUS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatBox(
                    'MACHINES',
                    '$totalMachines',
                    AppTheme.neonCyan,
                  ),
                  _buildStatBox('RUNNING', '$runningCount', AppTheme.neonGreen),
                  _buildStatBox(
                    'STANDBY',
                    '${totalMachines - runningCount}',
                    Colors.grey,
                  ),
                  _buildStatBox(
                    'JOBS',
                    '${_activeJobs.length}',
                    AppTheme.neonMagenta,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Engine toggle (master switch)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _engineRunning
                  ? AppTheme.neonGreen.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _engineRunning ? Icons.power : Icons.power_off,
                color: _engineRunning ? AppTheme.neonGreen : Colors.grey,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _engineRunning ? 'FACTORY ONLINE' : 'FACTORY OFFLINE',
                      style: TextStyle(
                        color: _engineRunning
                            ? AppTheme.neonGreen
                            : Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'Master engine toggle',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _engineRunning,
                activeThumbColor: AppTheme.neonGreen,
                onChanged: (v) {
                  setState(() => _engineRunning = v);
                  if (v) {
                    // Turn all machines on
                    for (final m in _machines) {
                      _machineStates[m.id] = true;
                      _machineStatuses[m.id] = 'RUNNING';
                    }
                  } else {
                    // Turn all machines off
                    for (final m in _machines) {
                      _machineStates[m.id] = false;
                      _machineStatuses[m.id] = 'STANDBY';
                    }
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Region / platform summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ACTIVE TARGETS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ..._selectedRegions.map(
                    (r) => _chipTag(r, AppTheme.neonCyan),
                  ),
                  ..._selectedSports.map(
                    (s) => _chipTag(s, AppTheme.neonMagenta),
                  ),
                  ..._selectedPlatforms.map(
                    (p) => _chipTag(p, AppTheme.neonGreen),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.6),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _chipTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

class _FactoryMachine {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String bay;
  final String desc;
  final String type;

  const _FactoryMachine({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.bay,
    required this.desc,
    required this.type,
  });
}

class _FactoryItem {
  final String id;
  final String? fileName;
  final String? imageUrl;
  final Uint8List? bytes;

  const _FactoryItem({
    required this.id,
    this.fileName,
    this.imageUrl,
    this.bytes,
  });
}

class _PipelineJob {
  final String id;
  final String title;
  final String? imageUrl;
  final String sport;
  final String region;
  final String currentStage;
  final double progress;
  final DateTime startedAt;

  const _PipelineJob({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.sport,
    required this.region,
    required this.currentStage,
    required this.progress,
    required this.startedAt,
  });

  _PipelineJob copyWith({String? currentStage, double? progress}) =>
      _PipelineJob(
        id: id,
        title: title,
        imageUrl: imageUrl,
        sport: sport,
        region: region,
        currentStage: currentStage ?? this.currentStage,
        progress: progress ?? this.progress,
        startedAt: startedAt,
      );
}
