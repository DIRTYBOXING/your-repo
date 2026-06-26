import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import '../../../shared/widgets/dfc_network_image.dart';
import '../../../shared/services/war_room_engine.dart';
import '../../../shared/services/promoter_ai_service.dart';
import '../../../shared/services/market_export_engine.dart';
import '../../../shared/services/war_room_approvals_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// WAR ROOM — Super Promoter Factory
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Upload posters. Watch the bots work. Fire campaigns.
/// Prove that AI is the promotional future of combat sports.
/// ═══════════════════════════════════════════════════════════════════════════

const _kCyan = Color(0xFF00E5FF);
const _kMagenta = Color(0xFFE040FB);
const _kGreen = Color(0xFF00E676);
const _kOrange = Color(0xFFFF9100);
const _kRed = Color(0xFFFF1744);
const _kGold = Color(0xFFFFD740);
const _kBg = Color(0xFF060A14);
const _kPanel = Color(0xFF0C1226);
const _kBorder = Color(0xFF1A2744);

class WarRoomScreen extends StatefulWidget {
  const WarRoomScreen({super.key});
  @override
  State<WarRoomScreen> createState() => _WarRoomScreenState();
}

class _WarRoomScreenState extends State<WarRoomScreen>
    with SingleTickerProviderStateMixin {
  final WarRoomEngine _engine = WarRoomEngine();
  final MarketExportEngine _exportEngine = MarketExportEngine();
  final WarRoomApprovalsService _approvals = WarRoomApprovalsService();
  late TabController _tabCtrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _engine.addListener(_onEngineUpdate);
    _boot();
  }

  Future<void> _boot() async {
    await _engine.initialize();
    _approvals.addListener(_onEngineUpdate);
    _approvals.fetchPendingApprovals();
    if (mounted) setState(() => _loading = false);
  }

  void _onEngineUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineUpdate);
    _engine.stopEngine();
    _engine.dispose();
    _exportEngine.dispose();
    _approvals.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _exportPoster(WarRoomPoster poster) async {
    final results = await _exportEngine.exportWarRoomPoster(
      posterId: poster.id,
      eventTitle: poster.eventTitle,
      promoBody:
          '${poster.sportType} from ${poster.region} — ${poster.eventTitle}. '
          'Watch LIVE on DataFightCentral PPV.',
      imageUrl: poster.imageUrl,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported to ${results.length} markets'),
          backgroundColor: const Color(0xFF00E676),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kCyan))
          : NestedScrollView(
              headerSliverBuilder: (ctx, inner) => [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildStatsBar()),
                SliverToBoxAdapter(child: _buildEngineToggle()),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      controller: _tabCtrl,
                      labelColor: _kCyan,
                      unselectedLabelColor: Colors.white38,
                      indicatorColor: _kCyan,
                      isScrollable: true,
                      tabs: const [
                        Tab(icon: Icon(Icons.photo_library), text: 'POSTERS'),
                        Tab(icon: Icon(Icons.smart_toy), text: 'BOT FACTORY'),
                        Tab(icon: Icon(Icons.rocket_launch), text: 'CAMPAIGNS'),
                        Tab(icon: Icon(Icons.gavel), text: 'APPROVALS'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildPostersTab(),
                  _buildBotFactoryTab(),
                  _buildCampaignsTab(),
                  _buildApprovalsTab(),
                ],
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HEADER — War Room identity
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    final totalImpressions = _engine.posters.fold<int>(
      0,
      (sum, p) => sum + p.impressions,
    );
    final boostedCount = _engine.posters
        .where((p) => p.status == WarRoomPosterStatus.boosted)
        .length;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        20,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A0E1A), Color(0xFF12182E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(color: _kCyan.withValues(alpha: 0.15)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [_kRed, _kOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kRed.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.military_tech,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WAR ROOM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'SUPER PROMOTER FACTORY — AU/NZ',
                      style: TextStyle(
                        color: _kCyan,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Engine status indicator
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _engine.isEngineRunning ? _kGreen : Colors.red,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_engine.isEngineRunning ? _kGreen : Colors.red)
                                  .withValues(alpha: 0.6),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _engine.isEngineRunning ? 'LIVE' : 'OFF',
                    style: TextStyle(
                      color: _engine.isEngineRunning ? _kGreen : Colors.white30,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick summary row
          Row(
            children: [
              _HeaderStat(
                icon: Icons.visibility,
                value: _formatNumber(totalImpressions),
                label: 'TOTAL REACH',
                color: _kCyan,
              ),
              const SizedBox(width: 16),
              _HeaderStat(
                icon: Icons.photo_library,
                value: '${_engine.posters.length}',
                label: 'EVENTS',
                color: _kGold,
              ),
              const SizedBox(width: 16),
              _HeaderStat(
                icon: Icons.rocket_launch,
                value: '$boostedCount',
                label: 'BOOSTED',
                color: _kMagenta,
              ),
              const SizedBox(width: 16),
              _HeaderStat(
                icon: Icons.smart_toy,
                value: '${_engine.activeBots}',
                label: 'BOTS ON',
                color: _kGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STATS BAR — Live numbers
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kPanel,
        border: Border(
          bottom: BorderSide(color: _kBorder.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          _StatChip(
            label: 'BOTS',
            value: '${_engine.activeBots}/${_engine.totalBots}',
            color: _kCyan,
          ),
          _StatChip(
            label: 'CONTENT',
            value: '${_engine.totalContentFired}',
            color: _kMagenta,
          ),
          _StatChip(
            label: 'REACH',
            value: _formatNumber(_engine.totalReach),
            color: _kGreen,
          ),
          _StatChip(
            label: 'POSTERS',
            value: '${_engine.posters.length}',
            color: _kGold,
          ),
          _StatChip(
            label: 'BLASTS',
            value: '${_engine.blasts.length}',
            color: _kOrange,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ENGINE TOGGLE — Start/stop the promotional machine
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildEngineToggle() {
    final running = _engine.isEngineRunning;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () {
          if (running) {
            _engine.stopEngine();
          } else {
            _engine.startEngine();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: running
                  ? [
                      _kGreen.withValues(alpha: 0.2),
                      _kCyan.withValues(alpha: 0.1),
                    ]
                  : [
                      _kRed.withValues(alpha: 0.15),
                      _kOrange.withValues(alpha: 0.08),
                    ],
            ),
            border: Border.all(
              color: running
                  ? _kGreen.withValues(alpha: 0.4)
                  : _kRed.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                running ? Icons.stop_circle : Icons.play_circle_fill,
                color: running ? _kGreen : _kRed,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                running
                    ? 'ENGINE RUNNING — 8 BOTS ACTIVE'
                    : 'START PROMOTIONAL ENGINE',
                style: TextStyle(
                  color: running ? _kGreen : Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 1 — POSTERS (Upload + Gallery)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildPostersTab() {
    return CustomScrollView(
      slivers: [
        // Upload button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: _uploadPoster,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _kCyan.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  gradient: LinearGradient(
                    colors: [
                      _kCyan.withValues(alpha: 0.06),
                      _kMagenta.withValues(alpha: 0.03),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kCyan.withValues(alpha: 0.12),
                      ),
                      child: const Icon(
                        Icons.cloud_upload_outlined,
                        color: _kCyan,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UPLOAD EVENT POSTER',
                          style: TextStyle(
                            color: _kCyan,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Add fight cards, PPV art, promo graphics',
                          style: TextStyle(color: Colors.white30, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Poster count summary
        if (_engine.posters.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Text(
                    '${_engine.posters.length} EVENTS',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_engine.posters.where((p) => p.status == WarRoomPosterStatus.boosted).length} boosted',
                    style: TextStyle(
                      color: _kMagenta.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Poster grid
        if (_engine.posters.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 48,
                    color: Colors.white12,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No posters yet',
                    style: TextStyle(color: Colors.white24, fontSize: 14),
                  ),
                  Text(
                    'Upload your first fight poster to get started',
                    style: TextStyle(color: Colors.white12, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.52,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _PosterCard(
                  poster: _engine.posters[i],
                  onBoost: () => _engine.boostPoster(_engine.posters[i].id),
                  onExport: () => _exportPoster(_engine.posters[i]),
                ),
                childCount: _engine.posters.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 2 — BOT FACTORY (Live activity feed)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildBotFactoryTab() {
    return CustomScrollView(
      slivers: [
        // Bot roster
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PROMOTIONAL BOT ROSTER',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _engine.bots.map((bot) {
                    return _BotChip(
                      bot: bot,
                      isEngineOn: _engine.isEngineRunning,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),

        // AI generated content preview
        if (_engine.latestContent.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'AI-GENERATED CONTENT',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((ctx, i) {
              final content = _engine.latestContent[i];
              return _ContentPreviewCard(content: content);
            }, childCount: _engine.latestContent.length.clamp(0, 8)),
          ),
        ],

        // Live activity feed
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'LIVE BOT ACTIVITY',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        if (_engine.botActivity.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Start the engine to see bots working',
                  style: TextStyle(color: Colors.white24, fontSize: 13),
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((ctx, i) {
              final event = _engine.botActivity[i];
              return _BotActivityTile(event: event);
            }, childCount: _engine.botActivity.length.clamp(0, 30)),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 3 — CAMPAIGNS (Fire blasts)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildCampaignsTab() {
    return CustomScrollView(
      slivers: [
        // Quick-fire campaign buttons
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QUICK-FIRE CAMPAIGNS',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                _CampaignButton(
                  label: 'AU/NZ MMA BLITZ',
                  icon: Icons.flash_on,
                  color: _kCyan,
                  subtitle: 'Target Australian & NZ MMA audience',
                  onTap: () => _engine.fireCampaignBlast(
                    name: 'AU/NZ MMA Blitz',
                    sportTypes: ['MMA'],
                  ),
                ),
                const SizedBox(height: 8),
                _CampaignButton(
                  label: 'BKFC AUSTRALIA PUSH',
                  icon: Icons.local_fire_department,
                  color: _kRed,
                  subtitle: 'Bare knuckle exposure across Australia',
                  onTap: () => _engine.fireCampaignBlast(
                    name: 'BKFC Australia Push',
                    targetRegion: 'AU',
                    sportTypes: ['BKFC', 'Bare Knuckle'],
                  ),
                ),
                const SizedBox(height: 8),
                _CampaignButton(
                  label: 'BOXING NZ SPOTLIGHT',
                  icon: Icons.sports_mma,
                  color: _kGold,
                  subtitle: 'Highlight New Zealand boxing talent',
                  onTap: () => _engine.fireCampaignBlast(
                    name: 'Boxing NZ Spotlight',
                    targetRegion: 'NZ',
                    sportTypes: ['Boxing'],
                  ),
                ),
                const SizedBox(height: 8),
                _CampaignButton(
                  label: 'FULL SPECTRUM AUNZ',
                  icon: Icons.rocket_launch,
                  color: _kMagenta,
                  subtitle: 'All sports, all regions, maximum exposure',
                  onTap: () => _engine.fireCampaignBlast(
                    name: 'Full Spectrum AUNZ',
                    sportTypes: [
                      'MMA',
                      'Boxing',
                      'BKFC',
                      'Muay Thai',
                      'Kickboxing',
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Blast history
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'CAMPAIGN BLAST LOG',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        if (_engine.blasts.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No campaigns fired yet',
                  style: TextStyle(color: Colors.white24, fontSize: 13),
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _BlastLogTile(blast: _engine.blasts[i]),
              childCount: _engine.blasts.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 4 — APPROVALS (DM/Publish/Spend approval queue)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildApprovalsTab() {
    final pending = _approvals.pendingTickets;
    return CustomScrollView(
      slivers: [
        // Stats bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _StatChip(
                  label: 'PENDING',
                  value: '${pending.length}',
                  color: _kOrange,
                ),
                _StatChip(
                  label: 'TOTAL',
                  value: '${_approvals.stats.total}',
                  color: _kCyan,
                ),
              ],
            ),
          ),
        ),
        // Refresh
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: _approvals.fetchPendingApprovals,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kCyan.withValues(alpha: 0.3)),
                ),
                child: const Center(
                  child: Text(
                    'REFRESH APPROVALS',
                    style: TextStyle(
                      color: _kCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        // List
        if (pending.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: Colors.white12,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No pending approvals',
                    style: TextStyle(color: Colors.white24, fontSize: 14),
                  ),
                  Text(
                    'All clear — bots are running clean',
                    style: TextStyle(color: Colors.white12, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _ApprovalCard(
                ticket: pending[i],
                onApprove: () => _handleApprove(pending[i]),
                onReject: () => _handleReject(pending[i]),
                onEscalate: () => _handleEscalate(pending[i]),
              ),
              childCount: pending.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Future<void> _handleApprove(ApprovalTicket ticket) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    final ok = await _approvals.approveTicket(
      ticketId: ticket.ticketId,
      reviewerId: uid,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Approved: ${ticket.assetTitle}' : 'Approval failed',
          ),
          backgroundColor: ok ? _kGreen : _kRed,
        ),
      );
    }
  }

  Future<void> _handleReject(ApprovalTicket ticket) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kPanel,
        title: const Text(
          'Rejection Reason',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Reason is required...',
            hintStyle: TextStyle(color: Colors.white30),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _kBorder),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Reject', style: TextStyle(color: _kRed)),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    final ok = await _approvals.rejectTicket(
      ticketId: ticket.ticketId,
      reviewerId: uid,
      reason: reason,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Rejected: ${ticket.assetTitle}' : 'Rejection failed',
          ),
          backgroundColor: ok ? _kOrange : _kRed,
        ),
      );
    }
  }

  Future<void> _handleEscalate(ApprovalTicket ticket) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    final target = ticket.requiresLegal
        ? 'legal'
        : ticket.hasMedicalGate
        ? 'medical'
        : 'admin';
    final ok = await _approvals.escalateTicket(
      ticketId: ticket.ticketId,
      to: target,
      reason: 'Escalated from War Room by operator',
      escalatedBy: uid,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Escalated to $target' : 'Escalation failed'),
          backgroundColor: ok ? _kGold : _kRed,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // POSTER UPLOAD — Firebase-first, local fallback
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> _uploadPoster() async {
    // Step 1: Collect metadata first (so user doesn't pick an image for nothing)
    final result = await _showPosterMetadataDialog();
    if (result == null) return;

    // Step 2: Pick image
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
    );
    if (picked == null) return;
    if (!mounted) return;

    setState(() => _loading = true);

    String? imageUrl;

    // Step 3: Try Firebase Storage upload
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final ref = FirebaseStorage.instance.ref(
          'war_room/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        final bytes = await picked.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        imageUrl = await ref.getDownloadURL();
      }
    } catch (e) {
      debugPrint('WarRoom: Firebase upload skipped — $e');
      // Not fatal — proceed with local-only poster
    }

    // Step 4: Add poster (works with or without image URL)
    try {
      await _engine.addPoster(
        eventTitle: result['title']!,
        imageUrl: imageUrl ?? '',
        eventDate: DateTime.tryParse(result['date'] ?? '') ?? DateTime.now(),
        region: result['region'] ?? 'AUNZ',
        sportType: result['sport'] ?? 'MMA',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: _kGreen, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    imageUrl != null
                        ? '${result['title']} uploaded & synced'
                        : '${result['title']} saved locally',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: _kPanel,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: _kRed, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Save failed: ${e.toString().split(':').first}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: _kPanel,
          ),
        );
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<Map<String, String>?> _showPosterMetadataDialog() async {
    final titleCtrl = TextEditingController();
    final regions = ['AU', 'NZ', 'AUNZ'];
    final sports = [
      'MMA',
      'Boxing',
      'BKFC',
      'Bare Knuckle',
      'Muay Thai',
      'Kickboxing',
      'Brawling',
    ];
    String selectedRegion = 'AUNZ';
    String selectedSport = 'MMA';

    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: _kPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _kCyan.withValues(alpha: 0.3)),
          ),
          title: const Text(
            'POSTER DETAILS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Event Title',
                    labelStyle: const TextStyle(color: Colors.white54),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: _kBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: _kCyan),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedRegion,
                  dropdownColor: _kPanel,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Region',
                    labelStyle: const TextStyle(color: Colors.white54),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: _kBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: regions
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setDlgState(() => selectedRegion = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedSport,
                  dropdownColor: _kPanel,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Sport',
                    labelStyle: const TextStyle(color: Colors.white54),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: _kBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: sports
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setDlgState(() => selectedSport = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kCyan,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, {
                  'title': titleCtrl.text.trim(),
                  'region': selectedRegion,
                  'sport': selectedSport,
                  'date': DateTime.now().toIso8601String(),
                });
              },
              child: const Text(
                'UPLOAD',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

/// Stat chip for the stats bar
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
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
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Poster card in the gallery grid
class _PosterCard extends StatelessWidget {
  final WarRoomPoster poster;
  final VoidCallback onBoost;
  final VoidCallback onExport;
  const _PosterCard({
    required this.poster,
    required this.onBoost,
    required this.onExport,
  });

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  Color get _statusColor {
    switch (poster.status) {
      case WarRoomPosterStatus.boosted:
        return _kMagenta;
      case WarRoomPosterStatus.live:
        return _kGreen;
      default:
        return _kCyan;
    }
  }

  String get _statusLabel {
    switch (poster.status) {
      case WarRoomPosterStatus.boosted:
        return 'BOOSTED';
      case WarRoomPosterStatus.live:
        return 'LIVE';
      default:
        return 'DRAFT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBoosted = poster.status == WarRoomPosterStatus.boosted;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBoosted ? _kMagenta.withValues(alpha: 0.5) : _kBorder,
          width: isBoosted ? 1.5 : 1,
        ),
        color: _kPanel,
        boxShadow: isBoosted
            ? [
                BoxShadow(
                  color: _kMagenta.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Poster image + status badge
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                poster.imageUrl != null && poster.imageUrl!.isNotEmpty
                    ? DfcNetworkImage(url: poster.imageUrl!)
                    : _PosterPlaceholder(title: poster.eventTitle),
                // Status badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: _statusColor.withValues(alpha: 0.85),
                      boxShadow: [
                        BoxShadow(
                          color: _statusColor.withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      _statusLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                // Sport type badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.black54,
                    ),
                    child: Text(
                      poster.sportType,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // Gradient overlay at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 40,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, _kPanel],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info bar
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  poster.eventTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                // Region tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _kCyan.withValues(alpha: 0.1),
                    border: Border.all(color: _kCyan.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    poster.region,
                    style: const TextStyle(
                      color: _kCyan,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Metrics row
                Row(
                  children: [
                    _MetricPill(
                      icon: Icons.visibility,
                      value: _fmt(poster.impressions),
                    ),
                    const SizedBox(width: 6),
                    _MetricPill(icon: Icons.share, value: _fmt(poster.shares)),
                    const SizedBox(width: 6),
                    _MetricPill(
                      icon: Icons.bookmark,
                      value: _fmt(poster.saves),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Action row
                if (!isBoosted)
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: onBoost,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [_kMagenta, _kCyan],
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'BOOST',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onExport,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: _kCyan.withValues(alpha: 0.12),
                              border: Border.all(
                                color: _kCyan.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'EXPORT',
                                style: TextStyle(
                                  color: _kCyan,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: _kMagenta.withValues(alpha: 0.15),
                        ),
                        child: const Icon(
                          Icons.rocket_launch,
                          color: _kMagenta,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  final String title;
  const _PosterPlaceholder({this.title = ''});

  String get _initials {
    final words = title.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 'DFC';
    if (words.length == 1) {
      return words[0].substring(0, words[0].length.clamp(0, 3)).toUpperCase();
    }
    return words.take(3).map((w) => w[0]).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF0D0D1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _initials,
              style: TextStyle(
                color: _kCyan.withValues(alpha: 0.4),
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              Icons.photo_camera,
              color: Colors.white.withValues(alpha: 0.08),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact metric pill for poster cards
class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String value;
  const _MetricPill({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: Colors.white30),
          const SizedBox(width: 3),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Header stat widget for the war room header
class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _HeaderStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: 0.06),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white30,
                fontSize: 7,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bot chip showing active/inactive
class _BotChip extends StatelessWidget {
  final PromoBot bot;
  final bool isEngineOn;
  const _BotChip({required this.bot, required this.isEngineOn});

  @override
  Widget build(BuildContext context) {
    final active = bot.isActive && isEngineOn;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: active
            ? _kCyan.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.03),
        border: Border.all(
          color: active ? _kCyan.withValues(alpha: 0.4) : Colors.white12,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(bot.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            bot.name,
            style: TextStyle(
              color: active ? _kCyan : Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (active) ...[
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _kGreen,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Content preview card for AI-generated promotional content
class _ContentPreviewCard extends StatelessWidget {
  final PromoContent content;
  const _ContentPreviewCard({required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: _kPanel,
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _kMagenta.withValues(alpha: 0.15),
                  ),
                  child: Text(
                    content.typeLabel,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  content.botName,
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                ),
                const Spacer(),
                // Hype score bar
                SizedBox(
                  width: 40,
                  child: LinearProgressIndicator(
                    value: content.hypeScore,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(
                      content.hypeScore > 0.8 ? _kGreen : _kCyan,
                    ),
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content.headline,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              content.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            if (content.hashtags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                content.hashtags.take(4).join(' '),
                style: TextStyle(
                  color: _kCyan.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Single bot activity tile
class _BotActivityTile extends StatelessWidget {
  final BotActivityEvent event;
  const _BotActivityTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: _kPanel.withValues(alpha: 0.7),
          border: Border.all(color: _kBorder.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Text(event.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        event.botName,
                        style: const TextStyle(
                          color: _kCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: _kMagenta.withValues(alpha: 0.15),
                        ),
                        child: Text(
                          event.action,
                          style: const TextStyle(
                            color: _kMagenta,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.detail,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
            // Hype indicator
            Column(
              children: [
                Text(
                  '${(event.hypeScore * 100).toInt()}',
                  style: TextStyle(
                    color: event.hypeScore > 0.8 ? _kGreen : _kCyan,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'HYPE',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 7,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Campaign fire button
class _CampaignButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String subtitle;
  final VoidCallback onTap;
  const _CampaignButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ),
            Icon(Icons.send, color: color.withValues(alpha: 0.5), size: 18),
          ],
        ),
      ),
    );
  }
}

/// Blast log history tile
class _BlastLogTile extends StatelessWidget {
  final WarRoomCampaignBlast blast;
  const _BlastLogTile({required this.blast});

  @override
  Widget build(BuildContext context) {
    final statusColors = {
      WarRoomBlastStatus.firing: _kOrange,
      WarRoomBlastStatus.delivered: _kCyan,
      WarRoomBlastStatus.complete: _kGreen,
    };
    final color = statusColors[blast.status] ?? _kCyan;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: _kPanel,
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: color.withValues(alpha: 0.15),
              ),
              child: Center(
                child: Icon(Icons.campaign, color: color, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blast.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${blast.targetRegion} · ${blast.sportTypes.join(", ")}',
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${blast.contentPiecesFired} pieces',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '~${blast.estimatedReach} reach',
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Approval ticket card for the War Room approvals queue
class _ApprovalCard extends StatelessWidget {
  final ApprovalTicket ticket;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onEscalate;
  const _ApprovalCard({
    required this.ticket,
    required this.onApprove,
    required this.onReject,
    required this.onEscalate,
  });

  @override
  Widget build(BuildContext context) {
    final hasSafetyFlag =
        ticket.requiresLegal || ticket.hasMedicalGate || ticket.hasAgeGating;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: _kPanel.withValues(alpha: 0.85),
          border: Border.all(
            color: hasSafetyFlag
                ? _kRed.withValues(alpha: 0.6)
                : _kBorder.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: title + status
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.assetTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _kOrange.withValues(alpha: 0.15),
                  ),
                  child: Text(
                    ticket.status.toUpperCase(),
                    style: const TextStyle(
                      color: _kOrange,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Info row
            Row(
              children: [
                _infoChip('TYPE', ticket.type, _kCyan),
                const SizedBox(width: 8),
                if (ticket.estimatedSpendUsd > 0)
                  _infoChip('SPEND', '\$${ticket.estimatedSpendUsd}', _kGold),
                const SizedBox(width: 8),
                if (ticket.influencerCount > 0)
                  _infoChip(
                    'INFLUENCERS',
                    '${ticket.influencerCount}',
                    _kMagenta,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Confidence bar
            Row(
              children: [
                const Text(
                  'CONFIDENCE',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: ticket.confidence,
                      minHeight: 4,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ticket.confidence >= 0.8
                            ? _kGreen
                            : ticket.confidence >= 0.5
                            ? _kOrange
                            : _kRed,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${(ticket.confidence * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            // Safety flags
            if (hasSafetyFlag) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  if (ticket.requiresLegal) _flagChip('LEGAL REVIEW', _kRed),
                  if (ticket.hasMedicalGate)
                    _flagChip('MEDICAL GATE', _kOrange),
                  if (ticket.hasAgeGating) _flagChip('AGE GATING', _kMagenta),
                ],
              ),
            ],
            const SizedBox(height: 10),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _actionBtn('ESCALATE', _kGold, onEscalate),
                const SizedBox(width: 8),
                _actionBtn('REJECT', _kRed, onReject),
                const SizedBox(width: 8),
                _actionBtn('APPROVE', _kGreen, onApprove),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white30,
            fontSize: 7,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _flagChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 7,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Pinned tab bar delegate for NestedScrollView
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext ctx, double shrink, bool overlap) {
    return Container(color: _kBg, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}
