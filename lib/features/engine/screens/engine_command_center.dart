import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/services/content_scanner_engine.dart';
import '../../../shared/services/promoter_ai_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ENGINE COMMAND CENTER — The Brain Behind DataFightCentral
/// Shows all scanner bots, promoter AI bots, live stats, and content feed
/// ═══════════════════════════════════════════════════════════════════════════
class EngineCommandCenter extends StatefulWidget {
  const EngineCommandCenter({super.key});

  @override
  State<EngineCommandCenter> createState() => _EngineCommandCenterState();
}

class _EngineCommandCenterState extends State<EngineCommandCenter>
    with TickerProviderStateMixin {
  late ContentScannerEngine _scanner;
  late PromoterAIService _promoter;
  late AnimationController _pulseCtrl;
  bool _initialized = false;
  bool _depsInitialized = false;
  int _selectedTab = 0; // 0=overview, 1=scanner, 2=promoter, 3=feed

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_depsInitialized) {
      _depsInitialized = true;
      _scanner = context.read<ContentScannerEngine>();
      _promoter = context.read<PromoterAIService>();
      _initializeEngines();
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  Future<void> _initializeEngines() async {
    await _scanner.initialize();
    _scanner.startEngine();
    await _promoter.initialize();
    _promoter.startEngine();
    if (mounted) setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A14),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: const Color(0xFF0A1628),
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, _) {
                      final glow =
                          math.sin(_pulseCtrl.value * math.pi * 2) * 0.5 + 0.5;
                      return Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _initialized
                              ? Color.lerp(
                                  AppTheme.neonGreen,
                                  Colors.white,
                                  glow * 0.3,
                                )
                              : Colors.orange,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (_initialized
                                          ? AppTheme.neonGreen
                                          : Colors.orange)
                                      .withValues(alpha: 0.4 + glow * 0.3),
                              blurRadius: 8 + glow * 4,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ENGINE COMMAND CENTER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0F1E3C), Color(0xFF0A1628)],
                  ),
                ),
              ),
            ),
          ),

          // Tab Bar
          SliverToBoxAdapter(child: _buildTabBar()),

          // Content based on tab
          if (!_initialized)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.neonCyan),
                    SizedBox(height: 16),
                    Text(
                      'INITIALIZING ENGINES...',
                      style: TextStyle(
                        color: Colors.white54,
                        letterSpacing: 3,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_selectedTab == 0)
            ..._buildOverview()
          else if (_selectedTab == 1)
            ..._buildScannerView()
          else if (_selectedTab == 2)
            ..._buildPromoterView()
          else
            ..._buildFeedView(),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['OVERVIEW', 'SCANNER', 'PROMOTER', 'LIVE FEED'];
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final selected = e.key == _selectedTab;
          final colors = [
            AppTheme.neonCyan,
            AppTheme.neonGreen,
            AppTheme.neonMagenta,
            AppColors.neonRed,
          ];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: selected
                      ? colors[e.key].withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.03),
                  border: Border.all(
                    color: selected
                        ? colors[e.key].withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Text(
                  e.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? colors[e.key] : Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OVERVIEW TAB
  // ═══════════════════════════════════════════════════════════════════════════
  List<Widget> _buildOverview() {
    final scanStats = _scanner.stats;
    final promoStats = _promoter.stats;

    return [
      // Engine Status Cards
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Header
              _sectionHeader('ENGINE STATUS', AppTheme.neonCyan),
              const SizedBox(height: 12),

              // Status Grid
              Row(
                children: [
                  _statCard(
                    'SCANNER',
                    '${scanStats.activeBots}/${scanStats.totalBots}',
                    'bots active',
                    AppTheme.neonGreen,
                  ),
                  const SizedBox(width: 8),
                  _statCard(
                    'PROMOTER',
                    '${promoStats.activeBots}/${promoStats.totalBots}',
                    'bots active',
                    AppTheme.neonMagenta,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _statCard(
                    'CONTENT',
                    '${scanStats.totalContentFound}',
                    'items scanned',
                    AppTheme.neonCyan,
                  ),
                  const SizedBox(width: 8),
                  _statCard(
                    'PROMOS',
                    '${promoStats.totalContentGenerated}',
                    'posts generated',
                    AppColors.neonRed,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _statCard(
                    'HEALTH',
                    '${(scanStats.overallHealth * 100).toInt()}%',
                    'system health',
                    AppTheme.neonGreen,
                  ),
                  const SizedBox(width: 8),
                  _statCard(
                    'SCANS',
                    '${scanStats.totalScans}',
                    'completed',
                    AppColors.neonBlue,
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _sectionHeader('BOT SWARM STATUS', AppTheme.neonMagenta),
              const SizedBox(height: 12),

              // Scanner Bots Mini
              ..._scanner.bots.map(
                (bot) => _botStatusRow(
                  bot.name,
                  bot.source.name.toUpperCase(),
                  bot.isActive,
                  bot.itemsFound,
                  AppTheme.neonGreen,
                ),
              ),

              const SizedBox(height: 16),

              // Promoter Bots Mini
              ..._promoter.bots.map(
                (bot) => _botStatusRow(
                  '${bot.emoji} ${bot.name}',
                  bot.speciality.name.toUpperCase(),
                  bot.isActive,
                  bot.contentGenerated,
                  AppTheme.neonMagenta,
                ),
              ),

              const SizedBox(height: 24),
              _sectionHeader('LIVE SCANNER FEED', AppColors.neonRed),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),

      // Latest Content
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final items = _scanner.getLatest(limit: 15);
          if (index >= items.length) return null;
          return _contentCard(items[index]);
        }, childCount: math.min(_scanner.getLatest(limit: 15).length, 15)),
      ),

      const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCANNER TAB
  // ═══════════════════════════════════════════════════════════════════════════
  List<Widget> _buildScannerView() {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader('SCANNER BOTS', AppTheme.neonGreen),
              const SizedBox(height: 12),
              ..._scanner.bots.map(_expandedBotCard),
              const SizedBox(height: 24),
              _sectionHeader('CONTENT BY SOURCE', AppTheme.neonCyan),
              const SizedBox(height: 12),
              ..._scanner.stats.contentBySource.entries.map((e) {
                return _sourceBar(
                  e.key.name.toUpperCase(),
                  e.value,
                  AppTheme.neonCyan,
                );
              }),
              const SizedBox(height: 24),
              _sectionHeader('CONTENT BY SPORT', AppTheme.neonOrange),
              const SizedBox(height: 12),
              ..._scanner.stats.contentBySport.entries.map((e) {
                return _sourceBar(
                  e.key.name.toUpperCase(),
                  e.value,
                  AppTheme.neonOrange,
                );
              }),
            ],
          ),
        ),
      ),
      const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROMOTER TAB
  // ═══════════════════════════════════════════════════════════════════════════
  List<Widget> _buildPromoterView() {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader('PROMOTER AI BOTS', AppTheme.neonMagenta),
              const SizedBox(height: 12),
              ..._promoter.bots.map(_promoBotCard),
              const SizedBox(height: 24),
              _sectionHeader('ACTIVE CAMPAIGNS', AppColors.neonRed),
              const SizedBox(height: 12),
              ..._promoter.campaigns.map(_campaignCard),
              const SizedBox(height: 24),
              _sectionHeader('TOP HYPE CONTENT', AppTheme.neonOrange),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final items = _promoter.getTopHype();
          if (index >= items.length) return null;
          return _promoCard(items[index]);
        }, childCount: math.min(_promoter.getTopHype().length, 10)),
      ),
      const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LIVE FEED TAB
  // ═══════════════════════════════════════════════════════════════════════════
  List<Widget> _buildFeedView() {
    final combined = <dynamic>[
      ..._scanner.getLatest(limit: 30),
      ..._promoter.getLatest(),
    ];
    combined.sort((a, b) {
      final aTime = a is ScannedContent
          ? a.publishedAt
          : (a as PromoContent).generatedAt;
      final bTime = b is ScannedContent
          ? b.publishedAt
          : (b as PromoContent).generatedAt;
      return bTime.compareTo(aTime);
    });

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _sectionHeader('UNIFIED LIVE FEED', AppColors.neonRed),
        ),
      ),
      const SliverPadding(padding: EdgeInsets.only(top: 8)),
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index >= combined.length) return null;
          final item = combined[index];
          if (item is ScannedContent) return _contentCard(item);
          if (item is PromoContent) return _promoCard(item);
          return const SizedBox();
        }, childCount: combined.length),
      ),
      const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _sectionHeader(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, String subtitle, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.06),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.5),
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botStatusRow(
    String name,
    String type,
    bool active,
    int items,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white.withValues(alpha: 0.02),
          border: Border.all(
            color: active
                ? color.withValues(alpha: 0.2)
                : Colors.red.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? color : Colors.red.withValues(alpha: 0.5),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ]
                    : [],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              type,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                fontSize: 8,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$items',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _expandedBotCard(ScannerBot bot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.neonGreen.withValues(alpha: 0.04),
        border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bot.isActive ? AppTheme.neonGreen : Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                bot.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                bot.source.name.toUpperCase(),
                style: TextStyle(
                  color: AppTheme.neonGreen.withValues(alpha: 0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _miniStat('Items', '${bot.itemsFound}', AppTheme.neonCyan),
              const SizedBox(width: 12),
              _miniStat(
                'Rate',
                '${(bot.successRate * 100).toInt()}%',
                AppTheme.neonGreen,
              ),
              const SizedBox(width: 12),
              _miniStat(
                'Interval',
                '${bot.interval.inMinutes}m',
                AppColors.neonBlue,
              ),
            ],
          ),
          if (bot.targets.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: bot.targets.take(4).map((t) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  child: Text(
                    t,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 8,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _promoBotCard(PromoBot bot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppTheme.neonMagenta.withValues(alpha: 0.04),
        border: Border.all(color: AppTheme.neonMagenta.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Text(bot.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bot.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                Text(
                  bot.speciality.name.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 8,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${bot.contentGenerated}',
                style: const TextStyle(
                  color: AppTheme.neonMagenta,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                'generated',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _campaignCard(PromoCampaign campaign) {
    final daysLeft = campaign.endDate.difference(DateTime.now()).inDays;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.neonRed.withValues(alpha: 0.04),
        border: Border.all(color: AppColors.neonRed.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: campaign.isActive ? AppTheme.neonGreen : Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  campaign.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                '${daysLeft}d left',
                style: TextStyle(
                  color: AppColors.neonRed.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            campaign.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Est. Reach: ${campaign.reachEstimate >= 1000 ? '${(campaign.reachEstimate / 1000).toStringAsFixed(0)}K' : campaign.reachEstimate}',
            style: TextStyle(
              color: AppTheme.neonCyan.withValues(alpha: 0.6),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contentCard(ScannedContent content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white.withValues(alpha: 0.02),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(content.sourceIcon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  content.sourceName,
                  style: TextStyle(
                    color: AppTheme.neonCyan.withValues(alpha: 0.6),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: AppTheme.neonOrange.withValues(alpha: 0.1),
                  ),
                  child: Text(
                    content.sportLabel,
                    style: TextStyle(
                      color: AppTheme.neonOrange.withValues(alpha: 0.7),
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (content.isBreaking) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: AppColors.neonRed.withValues(alpha: 0.15),
                    ),
                    child: Text(
                      'BREAKING',
                      style: TextStyle(
                        color: AppColors.neonRed.withValues(alpha: 0.9),
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  content.timeAgo,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.25),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              content.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${content.engagementLabel} engagements',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 9,
                  ),
                ),
                const Spacer(),
                Text(
                  content.authorName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _promoCard(PromoContent promo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [
              AppTheme.neonMagenta.withValues(alpha: 0.04),
              AppColors.neonRed.withValues(alpha: 0.02),
            ],
          ),
          border: Border.all(
            color: AppTheme.neonMagenta.withValues(alpha: 0.12),
          ),
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
                    color: AppTheme.neonMagenta.withValues(alpha: 0.15),
                  ),
                  child: Text(
                    promo.typeLabel,
                    style: const TextStyle(fontSize: 8),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  promo.botName,
                  style: TextStyle(
                    color: AppTheme.neonMagenta.withValues(alpha: 0.5),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  'HYPE ${(promo.hypeScore * 100).toInt()}%',
                  style: TextStyle(
                    color: AppColors.neonRed.withValues(alpha: 0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              promo.headline,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              promo.body,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (promo.hashtags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                promo.hashtags.join(' '),
                style: TextStyle(
                  color: AppTheme.neonCyan.withValues(alpha: 0.4),
                  fontSize: 8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sourceBar(String label, int count, Color color) {
    final maxCount = _scanner.contentFeed.length.clamp(1, 9999);
    final ratio = (count / maxCount).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: color.withValues(alpha: 0.5),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.25),
            fontSize: 8,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
