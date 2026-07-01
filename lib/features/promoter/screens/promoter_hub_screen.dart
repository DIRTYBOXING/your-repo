import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/promoter_hub_service.dart';
import '../../../core/config/router_config.dart' as dfc_router;

// ═════════════════════════════════════════════════════════════════════════════
// PROMOTER HUB SCREEN — One-Stop Promotions Shop
// ═════════════════════════════════════════════════════════════════════════════
//
// Five-tab command centre:
//   OVERVIEW   — event stats, reach totals, settlement snapshot
//   MEDIA POOL — shared assets per event (upload + browse + download)
//   DISTRIBUTE — channel toggles + per-region push + accounting log
//   TEAM       — collaborators (friends/crew) + quick message shortcut
//   REVENUE    — per-channel revenue lines + settlement status
//
// ═════════════════════════════════════════════════════════════════════════════

const _kCyan = DesignTokens.neonCyan;
const _kMagenta = DesignTokens.neonMagenta;
const _kGreen = DesignTokens.neonGreen;
const _kAmber = DesignTokens.neonAmber;
const _kBg = DesignTokens.bgPrimary;
const _kCard = DesignTokens.bgCard;
const _kText = DesignTokens.textPrimary;
const _kMuted = DesignTokens.textMuted;

class PromoterHubScreen extends StatefulWidget {
  /// [eventId] optionally pre-selects an event context.
  const PromoterHubScreen({super.key, this.eventId});
  final String? eventId;

  @override
  State<PromoterHubScreen> createState() => _PromoterHubScreenState();
}

class _PromoterHubScreenState extends State<PromoterHubScreen>
    with TickerProviderStateMixin {
  final _svc = PromoterHubService();
  late TabController _tabs;
  late AnimationController _glowCtrl;

  // selected event context for media pool / distribution
  String _eventId = '';
  bool _useDemoData = false;

  // Cached stream data
  List<DistributionRun> _runs = [];
  List<PoolAsset> _assets = [];
  List<HubCollaborator> _collaborators = [];
  StreamSubscription<List<DistributionRun>>? _runsSub;
  StreamSubscription<List<PoolAsset>>? _assetsSub;

  // Overview stats
  int _totalSent = 0, _totalReachK = 0, _totalRevenueCents = 0;
  List<ChannelRevenueLine> _revenueLines = [];

  // Channel toggle state (simulated locally for demo)
  final Set<String> _enabledChannels = {
    'dfc',
    'instagram',
    'youtube',
    'facebook',
  };

  static const _kTabCount = 5;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _kTabCount, vsync: this);
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _eventId = widget.eventId ?? 'demo';
    _initData();
  }

  void _initData() {
    // Try live Firestore streams; fall back to demo data if auth/error
    _runsSub = _svc
        .streamDistributionRuns(_eventId)
        .listen(
          (runs) {
            if (mounted) {
              setState(() {
                _runs = runs.isEmpty ? _svc.demoRuns : runs;
                _useDemoData = runs.isEmpty;
                _recalcStats();
              });
            }
          },
          onError: (_) {
            if (mounted) {
              setState(() {
                _runs = _svc.demoRuns;
                _useDemoData = true;
                _recalcStats();
              });
            }
          },
        );

    _assetsSub = _svc
        .streamPoolAssets(_eventId)
        .listen(
          (assets) {
            if (mounted) {
              setState(
                () => _assets = assets.isEmpty ? _svc.demoAssets : assets,
              );
            }
          },
          onError: (_) {
            if (mounted) setState(() => _assets = _svc.demoAssets);
          },
        );

    // Collaborators (demo)
    setState(() => _collaborators = _svc.demoCollaborators);

    // Revenue lines (async)
    _svc
        .getRevenueLines(_eventId)
        .then((lines) {
          if (mounted) {
            setState(() {
              _revenueLines = lines.isEmpty ? _demoRevenueLines() : lines;
            });
          }
        })
        .catchError((_) {
          if (mounted) setState(() => _revenueLines = _demoRevenueLines());
        });
  }

  void _recalcStats() {
    final sent = _runs.where((r) => r.status == 'sent');
    _totalSent = sent.length;
    _totalReachK = sent.fold(0, (s, r) => s + r.actualReachK);
    _totalRevenueCents = sent.fold(0, (s, r) => s + r.revenueCents);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _glowCtrl.dispose();
    _runsSub?.cancel();
    _assetsSub?.cancel();
    super.dispose();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [_buildAppBar(ctx)],
        body: TabBarView(
          controller: _tabs,
          children: [
            _OverviewTab(
              runs: _runs,
              totalSent: _totalSent,
              totalReachK: _totalReachK,
              totalRevenueCents: _totalRevenueCents,
              useDemoData: _useDemoData,
              onNavigateDistribute: () => _tabs.animateTo(2),
              onNavigateRevenue: () => _tabs.animateTo(4),
            ),
            _MediaPoolTab(assets: _assets, onUpload: _showUploadSheet),
            _DistributeTab(
              runs: _runs,
              enabledChannels: _enabledChannels,
              eventId: _eventId,
              svc: _svc,
              onToggle: (ch, on) => setState(() {
                on ? _enabledChannels.add(ch) : _enabledChannels.remove(ch);
              }),
              onPushAll: _pushToAllEnabled,
            ),
            _TeamTab(
              collaborators: _collaborators,
              onMessage: _openDM,
              onAddMember: _showAddMemberSheet,
            ),
            _RevenueTab(
              lines: _revenueLines,
              totalRevenueCents: _totalRevenueCents,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext ctx) {
    return SliverAppBar(
      backgroundColor: _kBg,
      pinned: true,
      expandedHeight: 120,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: _kCyan,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, _) => Text(
                'PROMOTER HUB',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                  color: Color.lerp(_kCyan, _kMagenta, _glowCtrl.value),
                  shadows: [
                    Shadow(
                      color: _kCyan.withValues(alpha: 0.6),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
            const Text(
              'One-Stop Promotions Shop',
              style: TextStyle(
                fontSize: 11,
                color: _kMuted,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A0518), _kBg],
            ),
          ),
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(
                Icons.rocket_launch_rounded,
                color: _kCyan.withValues(alpha: 0.12),
                size: 80,
              ),
            ),
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabs,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: _kCyan,
        labelColor: _kCyan,
        unselectedLabelColor: _kMuted,
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
        tabs: const [
          Tab(text: 'OVERVIEW'),
          Tab(text: 'MEDIA POOL'),
          Tab(text: 'DISTRIBUTE'),
          Tab(text: 'TEAM'),
          Tab(text: 'REVENUE'),
        ],
      ),
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  void _showUploadSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: _kMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'UPLOAD TO MEDIA POOL',
              style: TextStyle(
                color: _kCyan,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _uploadOption(
              Icons.image_rounded,
              'Poster / Banner',
              PoolAssetType.poster,
            ),
            _uploadOption(
              Icons.view_agenda_rounded,
              'Fight Card',
              PoolAssetType.fightCard,
            ),
            _uploadOption(
              Icons.videocam_rounded,
              'Promo Clip',
              PoolAssetType.clip,
            ),
            _uploadOption(
              Icons.photo_rounded,
              'Thumbnail',
              PoolAssetType.thumbnail,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _uploadOption(IconData icon, String label, PoolAssetType type) {
    return ListTile(
      leading: Icon(icon, color: _kMagenta),
      title: Text(
        label,
        style: const TextStyle(color: _kText, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.upload_rounded, color: _kMuted, size: 18),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connect Firebase Storage to enable $label upload'),
            backgroundColor: _kCard,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  Future<void> _pushToAllEnabled() async {
    try {
      for (final ch in _enabledChannels) {
        await _svc.logDistributionRun(
          eventId: _eventId,
          channel: ch,
          region: 'au',
          estimatedReachK: 30,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Queued push to ${_enabledChannels.length} channels'),
          backgroundColor: _kGreen.withValues(alpha: 0.2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Distribution blocked: $e'),
          backgroundColor: DesignTokens.neonRed.withValues(alpha: 0.2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openDM(HubCollaborator collab) {
    // Route to messaging inbox — user taps a thread from there
    context.pushNamed(dfc_router.RouterConfig.inbox);
  }

  void _showAddMemberSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: _kMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ADD COLLABORATOR',
              style: TextStyle(
                color: _kCyan,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Find fighters, managers, or media crew in your DFC network to join this event pool.',
              style: TextStyle(color: _kMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kCyan,
                foregroundColor: _kBg,
                minimumSize: const Size(double.infinity, 46),
              ),
              icon: const Icon(Icons.person_search_rounded),
              label: const Text(
                'SEARCH MY NETWORK',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              onPressed: () {
                Navigator.pop(context);
                context.pushNamed(dfc_router.RouterConfig.findFriends);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── Demo Revenue ──────────────────────────────────────────────────────────

  List<ChannelRevenueLine> _demoRevenueLines() => [
    const ChannelRevenueLine(
      channel: 'dfc',
      region: 'au',
      salesCount: 186,
      grossRevenueCents: 559800,
      platformFeeCents: 83970,
      promoterShareCents: 475830,
      settled: true,
    ),
    const ChannelRevenueLine(
      channel: 'youtube',
      region: 'global',
      salesCount: 116,
      grossRevenueCents: 349900,
      platformFeeCents: 52485,
      promoterShareCents: 297415,
    ),
    const ChannelRevenueLine(
      channel: 'instagram',
      region: 'au',
      salesCount: 63,
      grossRevenueCents: 189900,
      platformFeeCents: 28485,
      promoterShareCents: 161415,
    ),
    const ChannelRevenueLine(
      channel: 'facebook',
      region: 'au',
      salesCount: 33,
      grossRevenueCents: 99900,
      platformFeeCents: 14985,
      promoterShareCents: 84915,
    ),
  ];
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 1 — OVERVIEW
// ═════════════════════════════════════════════════════════════════════════════

class _OverviewTab extends StatelessWidget {
  final List<DistributionRun> runs;
  final int totalSent, totalReachK, totalRevenueCents;
  final bool useDemoData;
  final VoidCallback onNavigateDistribute, onNavigateRevenue;

  const _OverviewTab({
    required this.runs,
    required this.totalSent,
    required this.totalReachK,
    required this.totalRevenueCents,
    required this.useDemoData,
    required this.onNavigateDistribute,
    required this.onNavigateRevenue,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        if (useDemoData) _demoBanner(),
        const SizedBox(height: 12),
        _sectionLabel('REACH & REVENUE'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _stat(
                'CHANNEL SENDS',
                '$totalSent',
                _kCyan,
                Icons.send_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _stat(
                'TOTAL REACH',
                '${totalReachK}K',
                _kMagenta,
                Icons.visibility_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _stat(
                'REVENUE',
                _formatPrice(totalRevenueCents),
                _kGreen,
                Icons.attach_money_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _stat(
                'FAILED',
                '${runs.where((r) => r.status == "failed").length}',
                _kRed,
                Icons.error_outline_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionLabel('RECENT DISTRIBUTIONS'),
        const SizedBox(height: 10),
        ...runs.take(5).map(_runRow),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kCyan,
                  side: BorderSide(color: _kCyan.withValues(alpha: 0.5)),
                ),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('DISTRIBUTE NOW'),
                onPressed: onNavigateDistribute,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kGreen,
                  side: BorderSide(color: _kGreen.withValues(alpha: 0.5)),
                ),
                icon: const Icon(Icons.bar_chart_rounded, size: 16),
                label: const Text('REVENUE'),
                onPressed: onNavigateRevenue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionLabel('INTERNATIONAL CHANNELS'),
        const SizedBox(height: 10),
        _intlChannelSummary(),
      ],
    );
  }

  Widget _demoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kAmber.withValues(alpha: 0.08),
        border: Border.all(color: _kAmber.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: _kAmber, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing demo data — sign in as a promoter to see live stats',
              style: TextStyle(color: _kAmber, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
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
            style: const TextStyle(color: _kMuted, fontSize: 10, letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }

  Widget _runRow(DistributionRun run) {
    final icon = _channelIcon(run.channel);
    final statusColor = run.status == 'sent'
        ? _kGreen
        : run.status == 'failed'
        ? _kRed
        : _kAmber;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _channelColor(run.channel), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  run.channel.toUpperCase(),
                  style: const TextStyle(
                    color: _kText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${run.region.toUpperCase()}  ·  ${run.actualReachK > 0 ? "${run.actualReachK}K reach" : "${run.estimatedReachK}K est."}',
                  style: const TextStyle(color: _kMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              run.status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _intlChannelSummary() {
    final channels = PromoterHubService.kIntlChannels.take(8).toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: channels.map((ch) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _kCard,
            border: Border.all(color: _kCyan.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${ch.name} · ${ch.region.toUpperCase()}',
            style: const TextStyle(color: _kMuted, fontSize: 11),
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _kMuted,
        fontSize: 11,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  String _formatPrice(int cents) {
    if (cents == 0) return 'A\$0';
    return 'A\$${(cents / 100).toStringAsFixed(0)}';
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 2 — MEDIA POOL
// ═════════════════════════════════════════════════════════════════════════════

class _MediaPoolTab extends StatelessWidget {
  final List<PoolAsset> assets;
  final VoidCallback onUpload;

  const _MediaPoolTab({required this.assets, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    final totalMb =
        assets.fold<int>(0, (s, a) => s + a.fileSizeBytes) / (1024 * 1024);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Storage usage bar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kCyan.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.cloud_rounded, color: _kCyan, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'SHARED EVENT POOL',
                    style: TextStyle(
                      color: _kCyan,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${totalMb.toStringAsFixed(1)} MB',
                    style: const TextStyle(color: _kMuted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (totalMb / 500).clamp(0, 1),
                backgroundColor: _kBg,
                valueColor: const AlwaysStoppedAnimation(_kCyan),
                borderRadius: BorderRadius.circular(4),
                minHeight: 6,
              ),
              const SizedBox(height: 4),
              Text(
                '${totalMb.toStringAsFixed(1)} / 500 MB used',
                style: const TextStyle(color: _kMuted, fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kMagenta,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.upload_rounded),
          label: const Text(
            'UPLOAD ASSET',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
          ),
          onPressed: onUpload,
        ),
        const SizedBox(height: 16),
        if (assets.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload_rounded, color: _kMuted, size: 48),
                  SizedBox(height: 8),
                  Text('No assets yet', style: TextStyle(color: _kMuted)),
                ],
              ),
            ),
          )
        else
          ...assets.map(_assetTile),
      ],
    );
  }

  Widget _assetTile(PoolAsset asset) {
    final icon = _assetIcon(asset.type);
    final color = _assetColor(asset.type);
    final mb = asset.fileSizeBytes / (1024 * 1024);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.fileName,
                  style: const TextStyle(
                    color: _kText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${asset.type.name.toUpperCase()}  ·  ${mb.toStringAsFixed(1)} MB  ·  ${asset.uploaderName}',
                  style: const TextStyle(color: _kMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.download_rounded, color: _kMuted, size: 20),
        ],
      ),
    );
  }

  IconData _assetIcon(PoolAssetType t) => switch (t) {
    PoolAssetType.poster => Icons.image_rounded,
    PoolAssetType.banner => Icons.panorama_rounded,
    PoolAssetType.clip => Icons.videocam_rounded,
    PoolAssetType.thumbnail => Icons.photo_rounded,
    PoolAssetType.fightCard => Icons.view_agenda_rounded,
    PoolAssetType.other => Icons.insert_drive_file_rounded,
  };

  Color _assetColor(PoolAssetType t) => switch (t) {
    PoolAssetType.poster => _kMagenta,
    PoolAssetType.banner => _kCyan,
    PoolAssetType.clip => _kAmber,
    PoolAssetType.thumbnail => _kGreen,
    PoolAssetType.fightCard => DesignTokens.neonGold,
    PoolAssetType.other => _kMuted,
  };
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 3 — DISTRIBUTE
// ═════════════════════════════════════════════════════════════════════════════

class _DistributeTab extends StatelessWidget {
  final List<DistributionRun> runs;
  final Set<String> enabledChannels;
  final String eventId;
  final PromoterHubService svc;
  final void Function(String channel, bool on) onToggle;
  final VoidCallback onPushAll;

  const _DistributeTab({
    required this.runs,
    required this.enabledChannels,
    required this.eventId,
    required this.svc,
    required this.onToggle,
    required this.onPushAll,
  });

  static const _channels = [
    ('dfc', 'DFC Platform', Icons.sports_martial_arts_rounded),
    ('youtube', 'YouTube', Icons.play_circle_filled_rounded),
    ('instagram', 'Instagram', Icons.camera_alt_rounded),
    ('facebook', 'Facebook', Icons.facebook_rounded),
    ('tiktok', 'TikTok / Reels', Icons.music_note_rounded),
    ('twitter', 'Twitter / X', Icons.close_rounded),
    ('broadcast', 'Intl Broadcast', Icons.broadcast_on_personal_rounded),
    ('ppv', 'PPV Partners', Icons.live_tv_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kCyan.withValues(alpha: 0.05),
            border: Border.all(color: _kCyan.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.public_rounded, color: _kCyan, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Toggle channels then push your event to all active distribution points simultaneously.',
                  style: TextStyle(color: _kMuted, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._channels.map((ch) => _channelRow(ch.$1, ch.$2, ch.$3)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kCyan,
            foregroundColor: _kBg,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.send_rounded),
          label: Text(
            'PUSH TO ${enabledChannels.length} CHANNELS',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          onPressed: onPushAll,
        ),
        const SizedBox(height: 20),
        const Text(
          'INTERNATIONAL COVERAGE',
          style: TextStyle(
            color: _kMuted,
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        _intlGrid(),
        const SizedBox(height: 20),
        const Text(
          'DISTRIBUTION LOG',
          style: TextStyle(
            color: _kMuted,
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        ...runs.map(_logRow),
      ],
    );
  }

  Widget _channelRow(String id, String label, IconData icon) {
    final enabled = enabledChannels.contains(id);
    final color = _channelColor(id);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: enabled ? color.withValues(alpha: 0.4) : Colors.transparent,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(
          label,
          style: const TextStyle(
            color: _kText,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing: Switch(
          value: enabled,
          onChanged: (v) => onToggle(id, v),
          activeThumbColor: color,
          inactiveTrackColor: _kCard,
        ),
      ),
    );
  }

  Widget _intlGrid() {
    final channels = PromoterHubService.kIntlChannels
        .where((c) => c.type != 'social')
        .take(6)
        .toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: channels.map((c) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _kCard,
            border: Border.all(color: _kMagenta.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.broadcast_on_personal_rounded,
                color: _kMagenta,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                '${c.name} · ${c.region.replaceAll("_", "").toUpperCase()}',
                style: const TextStyle(color: _kMuted, fontSize: 11),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _logRow(DistributionRun run) {
    final color = run.status == 'sent'
        ? _kGreen
        : run.status == 'failed'
        ? _kRed
        : _kAmber;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _channelIcon(run.channel),
            color: _channelColor(run.channel),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${run.channel} → ${run.region.toUpperCase()}',
              style: const TextStyle(color: _kMuted, fontSize: 12),
            ),
          ),
          Text(
            run.status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 4 — TEAM
// ═════════════════════════════════════════════════════════════════════════════

class _TeamTab extends StatelessWidget {
  final List<HubCollaborator> collaborators;
  final void Function(HubCollaborator) onMessage;
  final VoidCallback onAddMember;

  const _TeamTab({
    required this.collaborators,
    required this.onMessage,
    required this.onAddMember,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kMagenta.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.groups_rounded, color: _kMagenta, size: 18),
              const SizedBox(width: 8),
              Text(
                '${collaborators.length} COLLABORATORS',
                style: const TextStyle(
                  color: _kMagenta,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onAddMember,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _kMagenta.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kMagenta.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: _kMagenta, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'ADD',
                        style: TextStyle(
                          color: _kMagenta,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...collaborators.map(_collaboratorTile),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: _kCyan,
            side: BorderSide(color: _kCyan.withValues(alpha: 0.4)),
            minimumSize: const Size(double.infinity, 44),
          ),
          icon: const Icon(Icons.person_search_rounded, size: 18),
          label: const Text(
            'FIND FIGHTERS & PROMOTERS',
            style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.8),
          ),
          onPressed: onAddMember,
        ),
      ],
    );
  }

  Widget _collaboratorTile(HubCollaborator collab) {
    final roleColor = switch (collab.role) {
      'promoter' => _kCyan,
      'media' => _kMagenta,
      'fighter' => _kAmber,
      'manager' => _kGreen,
      _ => _kMuted,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: roleColor.withValues(alpha: 0.15)),
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: roleColor.withValues(alpha: 0.15),
              child: Text(
                collab.displayName.substring(0, 1),
                style: TextStyle(color: roleColor, fontWeight: FontWeight.w800),
              ),
            ),
            if (collab.isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _kGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: _kBg, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          collab.displayName,
          style: const TextStyle(
            color: _kText,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          collab.role.toUpperCase(),
          style: TextStyle(
            color: roleColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: _kCyan,
            size: 20,
          ),
          onPressed: () => onMessage(collab),
          tooltip: 'Message',
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 5 — REVENUE
// ═════════════════════════════════════════════════════════════════════════════

class _RevenueTab extends StatelessWidget {
  final List<ChannelRevenueLine> lines;
  final int totalRevenueCents;

  const _RevenueTab({required this.lines, required this.totalRevenueCents});

  String _fmt(int cents) {
    if (cents == 0) return 'A\$0';
    return 'A\$${(cents / 100).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final promoterTotal = lines.fold<int>(
      0,
      (s, l) => s + l.promoterShareCents,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Summary header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_kGreen.withValues(alpha: 0.08), _kCard],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GROSS REVENUE',
                style: TextStyle(
                  color: _kMuted,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _fmt(totalRevenueCents),
                style: const TextStyle(
                  color: _kGreen,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Divider(height: 20, color: Colors.white12),
              Row(
                children: [
                  Expanded(
                    child: _summaryItem(
                      'YOUR SHARE (85%)',
                      _fmt(promoterTotal),
                      _kGreen,
                    ),
                  ),
                  Expanded(
                    child: _summaryItem(
                      'DFC FEE (15%)',
                      _fmt(totalRevenueCents - promoterTotal),
                      _kMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'CHANNEL BREAKDOWN',
          style: TextStyle(
            color: _kMuted,
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (lines.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No revenue data yet',
                style: TextStyle(color: _kMuted),
              ),
            ),
          )
        else
          ...lines.map(_revenueLine),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kAmber.withValues(alpha: 0.05),
            border: Border.all(color: _kAmber.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: _kAmber, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Settlement within 30 days of event via Stripe Connect. 85% promoter / 15% DFC platform fee.',
                  style: TextStyle(color: _kMuted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: _kMuted, fontSize: 9, letterSpacing: 1),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _revenueLine(ChannelRevenueLine line) {
    final maxRevenue = lines.isEmpty ? 1 : lines.first.grossRevenueCents;
    final ratio = maxRevenue > 0 ? line.grossRevenueCents / maxRevenue : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: line.settled ? _kGreen.withValues(alpha: 0.3) : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _channelIcon(line.channel),
                color: _channelColor(line.channel),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                line.channel.toUpperCase(),
                style: const TextStyle(
                  color: _kText,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '· ${line.region.toUpperCase()}',
                style: const TextStyle(color: _kMuted, fontSize: 11),
              ),
              const Spacer(),
              if (line.settled)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'SETTLED',
                    style: TextStyle(
                      color: _kGreen,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: ratio.toDouble(),
            backgroundColor: _kBg,
            valueColor: AlwaysStoppedAnimation(_channelColor(line.channel)),
            borderRadius: BorderRadius.circular(4),
            minHeight: 4,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${line.salesCount} sales',
                style: const TextStyle(color: _kMuted, fontSize: 11),
              ),
              Text(
                _fmt(line.grossRevenueCents),
                style: const TextStyle(
                  color: _kGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Text(
            'Your share: ${_fmt(line.promoterShareCents)}',
            style: const TextStyle(color: _kMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Helpers — shared across tabs
// ═════════════════════════════════════════════════════════════════════════════

const _kRed = DesignTokens.neonRed;

IconData _channelIcon(String ch) => switch (ch) {
  'instagram' => Icons.camera_alt_rounded,
  'facebook' => Icons.facebook_rounded,
  'youtube' => Icons.play_circle_filled_rounded,
  'tiktok' => Icons.music_note_rounded,
  'dfc' => Icons.sports_martial_arts_rounded,
  'ppv' => Icons.live_tv_rounded,
  'broadcast' => Icons.broadcast_on_personal_rounded,
  'twitter' => Icons.close_rounded,
  _ => Icons.send_rounded,
};

Color _channelColor(String ch) => switch (ch) {
  'instagram' => const Color(0xFFE1306C),
  'facebook' => const Color(0xFF1877F2),
  'youtube' => const Color(0xFFFF0000),
  'tiktok' => const Color(0xFF00F2EA),
  'dfc' => _kCyan,
  'ppv' => _kAmber,
  'broadcast' => _kMagenta,
  _ => _kMuted,
};
