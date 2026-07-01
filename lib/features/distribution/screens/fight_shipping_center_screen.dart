import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/market_export_engine.dart';
import '../../../shared/services/global_distribution_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  FIGHT SHIPPING CENTER v1.0
//  "We Ship Fights" — Unified Content Distribution Command Center
//
//  Combines Market Export, Global Distribution, and Social Syndication
//  into a single battlefield command screen. Every fight, every event,
//  every fighter — shipped worldwide from here.
//
//  Tabs:
//    1. LIVE MAP    — Global distribution overview with region cards
//    2. SHIP NOW    — Quick-fire multi-region, multi-platform blast
//    3. CHANNELS    — Platform channel health & sync status
//    4. OPERATIONS  — Export history, pipeline metrics, audit trail
// ═══════════════════════════════════════════════════════════════════════════

class FightShippingCenterScreen extends StatefulWidget {
  const FightShippingCenterScreen({super.key});

  @override
  State<FightShippingCenterScreen> createState() =>
      _FightShippingCenterScreenState();
}

class _FightShippingCenterScreenState extends State<FightShippingCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Market Export data
  List<ExportMarket> _markets = [];
  List<ExportPackage> _exportHistory = [];
  int _totalExported = 0;
  int _activeMarkets = 0;
  int _queuedExports = 0;

  // Distribution channel data
  List<DistributionChannelConfig> _channels = [];

  // Ship Now form
  final _headlineController = TextEditingController();
  final _bodyController = TextEditingController();
  final Set<String> _selectedMarkets = {};
  final Set<String> _selectedPlatforms = {};
  bool _shipping = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final exportEngine = context.read<MarketExportEngine>();
    final distService = GlobalDistributionService();

    await exportEngine.loadHistory();
    final channelConfigs = await distService.getChannelConfigs();

    if (mounted) {
      setState(() {
        _markets = MarketExportEngine.targetMarkets;
        _exportHistory = exportEngine.packages;
        _totalExported = exportEngine.packages
            .where((e) =>
                e.status == ExportStatus.dispatched ||
                e.status == ExportStatus.delivered)
            .length;
        _activeMarkets = _markets.where((m) => m.isActive).length;
        _queuedExports = exportEngine.packages
            .where((e) => e.status == ExportStatus.queued)
            .length;
        _channels = channelConfigs;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headlineController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStatsRow(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLiveMapTab(),
                  _buildShipNowTab(),
                  _buildChannelsTab(),
                  _buildOperationsTab(),
                ],
              ),
            ),
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
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [DesignTokens.neonCyan, DesignTokens.neonGreen],
            ).createShader(r),
            child: const Text(
              'FIGHT SHIPPING CENTER',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: DesignTokens.neonGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: DesignTokens.neonGreen.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: DesignTokens.neonGreen, size: 8),
                SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: DesignTokens.neonGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
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
  //  STATS ROW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStatsRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _stat('SHIPPED', '$_totalExported', DesignTokens.neonGreen),
          _statDivider(),
          _stat('MARKETS', '$_activeMarkets', DesignTokens.neonCyan),
          _statDivider(),
          _stat('QUEUED', '$_queuedExports', DesignTokens.neonAmber),
          _statDivider(),
          _stat(
              'CHANNELS',
              '${_channels.where((c) => c.enabled).length}',
              DesignTokens.neonMagenta),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: 0.06),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      indicatorColor: DesignTokens.neonCyan,
      indicatorSize: TabBarIndicatorSize.label,
      labelColor: DesignTokens.neonCyan,
      unselectedLabelColor: Colors.white.withValues(alpha: 0.3),
      labelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
      tabAlignment: TabAlignment.start,
      tabs: const [
        Tab(text: 'LIVE MAP'),
        Tab(text: 'SHIP NOW'),
        Tab(text: 'CHANNELS'),
        Tab(text: 'OPERATIONS'),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 1: LIVE MAP — Global Distribution Overview
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLiveMapTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        // World coverage banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignTokens.neonCyan.withValues(alpha: 0.06),
                DesignTokens.neonGreen.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: DesignTokens.neonCyan.withValues(alpha: 0.12)),
          ),
          child: Column(
            children: [
              const Icon(Icons.public, color: DesignTokens.neonCyan, size: 36),
              const SizedBox(height: 8),
              const Text(
                'GLOBAL FIGHT DISTRIBUTION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_activeMarkets markets active · ${_channels.where((c) => c.enabled).length} channels live',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Region cards
        ..._markets.map(_buildRegionCard),
      ],
    );
  }

  Widget _buildRegionCard(ExportMarket market) {
    final color = _regionColor(market.regionCode);
    final flag = _regionFlag(market.regionCode);
    final exported = _exportHistory
        .where((e) => e.market.id == market.id)
        .length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            // Flag/icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  flag,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Market info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        market.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (market.isActive)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: DesignTokens.neonGreen,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${market.platforms.length} platforms · ${market.currencySymbol}${(14.99 * market.ppvMultiplier).toStringAsFixed(2)} PPV · $exported shipped',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Quick ship button
            IconButton(
              icon: Icon(Icons.send, color: color, size: 18),
              tooltip: 'Ship to ${market.name}',
              onPressed: () {
                setState(() {
                  _selectedMarkets.clear();
                  _selectedMarkets.add(market.id);
                  _tabController.animateTo(1);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 2: SHIP NOW — Quick-Fire Distribution
  // ═══════════════════════════════════════════════════════════════

  Widget _buildShipNowTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        // Headline
        _inputField(
          controller: _headlineController,
          label: 'HEADLINE',
          hint: 'UFC 310: Adesanya vs. Pereira III',
          icon: Icons.title,
        ),
        const SizedBox(height: 12),
        _inputField(
          controller: _bodyController,
          label: 'CONTENT',
          hint: 'Live PPV streaming now available. Order today...',
          icon: Icons.article,
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Quick presets
        _sectionLabel('QUICK PRESETS'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _presetChip('🌍 Global PPV Push', () {
              setState(() {
                _selectedMarkets
                    .addAll(_markets.map((m) => m.id));
              });
            }),
            _presetChip('🥊 MMA AU/NZ', () {
              setState(() {
                _selectedMarkets.clear();
                _selectedMarkets.add('aunz');
              });
            }),
            _presetChip('👊 BKFC Worldwide', () {
              setState(() {
                _selectedMarkets
                    .addAll(_markets.map((m) => m.id));
              });
            }),
            _presetChip('🥋 Boxing Asia', () {
              setState(() {
                _selectedMarkets.clear();
                _selectedMarkets.addAll(['sea', 'japan', 'india']);
              });
            }),
            _presetChip('🌎 Americas', () {
              setState(() {
                _selectedMarkets.clear();
                _selectedMarkets.addAll(['north_america', 'latam']);
              });
            }),
            _presetChip('🇪🇺 Europe + UK', () {
              setState(() {
                _selectedMarkets.clear();
                _selectedMarkets.add('uk_eu');
              });
            }),
          ],
        ),
        const SizedBox(height: 16),

        // Target markets selector
        _sectionLabel('TARGET MARKETS'),
        const SizedBox(height: 6),
        ..._markets.map(_marketCheckbox),
        const SizedBox(height: 16),

        // Platform selector
        _sectionLabel('PLATFORMS'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _platformChip('Facebook', Icons.facebook),
            _platformChip('Instagram', Icons.camera_alt),
            _platformChip('YouTube', Icons.play_circle),
            _platformChip('TikTok', Icons.music_note),
            _platformChip('X', Icons.alternate_email),
            _platformChip('Threads', Icons.forum),
            _platformChip('WhatsApp', Icons.chat),
            _platformChip('LinkedIn', Icons.work),
            _platformChip('BlueSky', Icons.cloud),
            _platformChip('RedNote', Icons.note),
          ],
        ),
        const SizedBox(height: 24),

        // SHIP IT button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _shipping || _selectedMarkets.isEmpty
                ? null
                : _shipContent,
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.neonGreen.withValues(alpha: 0.2),
              foregroundColor: DesignTokens.neonGreen,
              side: const BorderSide(
                  color: DesignTokens.neonGreen),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _shipping
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DesignTokens.neonGreen,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.rocket_launch, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'SHIP TO ${_selectedMarkets.length} MARKET${_selectedMarkets.length == 1 ? '' : 'S'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
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

  Future<void> _shipContent() async {
    final headline = _headlineController.text.trim();
    final body = _bodyController.text.trim();
    if (headline.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: DesignTokens.bgSecondary,
          content: Text('Add a headline first',
              style: TextStyle(color: Colors.white)),
        ),
      );
      return;
    }

    setState(() => _shipping = true);

    final exportEngine = context.read<MarketExportEngine>();
    int shipped = 0;

    for (final marketId in _selectedMarkets) {
      final market =
          _markets.where((m) => m.id == marketId).firstOrNull;
      if (market == null) continue;

      await exportEngine.exportToMarket(
        market: market,
        sourceType: 'shipping_center',
        sourceId: 'manual_${DateTime.now().millisecondsSinceEpoch}',
        title: headline,
        body: body.isNotEmpty ? body : headline,
      );
      shipped++;
    }

    if (mounted) {
      setState(() => _shipping = false);
      _headlineController.clear();
      _bodyController.clear();
      _selectedMarkets.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: DesignTokens.bgSecondary,
          content: Text(
            '🚀 Shipped to $shipped market${shipped == 1 ? '' : 's'}!',
            style: const TextStyle(color: DesignTokens.neonGreen),
          ),
        ),
      );

      await _loadData();
    }
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15)),
            prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.15), size: 20),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: DesignTokens.neonCyan),
            ),
          ),
        ),
      ],
    );
  }

  Widget _presetChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: DesignTokens.neonCyan.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: DesignTokens.neonCyan.withValues(alpha: 0.15)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: DesignTokens.neonCyan,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _marketCheckbox(ExportMarket market) {
    final selected = _selectedMarkets.contains(market.id);
    final color = _regionColor(market.regionCode);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            if (selected) {
              _selectedMarkets.remove(market.id);
            } else {
              _selectedMarkets.add(market.id);
            }
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                color: selected
                    ? color
                    : Colors.white.withValues(alpha: 0.2),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                _regionFlag(market.regionCode),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  market.name,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              Text(
                '${market.currencySymbol}${(14.99 * market.ppvMultiplier).toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _platformChip(String name, IconData icon) {
    final selected = _selectedPlatforms.contains(name);

    return InkWell(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedPlatforms.remove(name);
          } else {
            _selectedPlatforms.add(name);
          }
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? DesignTokens.neonMagenta.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? DesignTokens.neonMagenta.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected
                  ? DesignTokens.neonMagenta
                  : Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 4),
            Text(
              name,
              style: TextStyle(
                color: selected
                    ? DesignTokens.neonMagenta
                    : Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 3: CHANNELS — Platform Health & Sync
  // ═══════════════════════════════════════════════════════════════

  Widget _buildChannelsTab() {
    final allPlatforms = [
      'Facebook',
      'Instagram',
      'YouTube',
      'TikTok',
      'X (Twitter)',
      'Threads',
      'WhatsApp',
      'LinkedIn',
      'BlueSky',
      'RedNote',
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        _sectionLabel('DISTRIBUTION CHANNELS'),
        const SizedBox(height: 8),
        ...allPlatforms.map((platform) {
          final config = _channels
              .where((c) =>
                  c.platform.toLowerCase() == platform.toLowerCase())
              .firstOrNull;
          final enabled = config?.enabled ?? false;
          final synced = config?.itemsSynced ?? 0;
          final lastSync = config?.lastSync;

          return _buildChannelCard(
            platform: platform,
            icon: _platformIcon(platform),
            enabled: enabled,
            itemsSynced: synced,
            lastSync: lastSync,
          );
        }),
      ],
    );
  }

  Widget _buildChannelCard({
    required String platform,
    required IconData icon,
    required bool enabled,
    required int itemsSynced,
    DateTime? lastSync,
  }) {
    final color = enabled ? DesignTokens.neonGreen : Colors.white.withValues(alpha: 0.2);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: enabled
              ? DesignTokens.neonGreen.withValues(alpha: 0.03)
              : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? DesignTokens.neonGreen.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    platform,
                    style: TextStyle(
                      color: enabled
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (enabled && lastSync != null)
                    Text(
                      '$itemsSynced synced · ${_timeAgo(lastSync)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 11,
                      ),
                    )
                  else
                    Text(
                      enabled ? 'Connected' : 'Not connected',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.25),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: enabled
                    ? DesignTokens.neonGreen.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                enabled ? 'LIVE' : 'OFF',
                style: TextStyle(
                  color: enabled
                      ? DesignTokens.neonGreen
                      : Colors.white.withValues(alpha: 0.2),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 4: OPERATIONS — Export History & Pipeline Metrics
  // ═══════════════════════════════════════════════════════════════

  Widget _buildOperationsTab() {
    // Pipeline metrics
    final dispatched = _exportHistory
        .where((e) => e.status == ExportStatus.dispatched)
        .length;
    final delivered = _exportHistory
        .where((e) => e.status == ExportStatus.delivered)
        .length;
    final failed = _exportHistory
        .where((e) => e.status == ExportStatus.failed)
        .length;
    final processing = _exportHistory
        .where((e) => e.status == ExportStatus.processing)
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        // Pipeline metrics
        _sectionLabel('PIPELINE METRICS'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                  'Dispatched', dispatched, DesignTokens.neonCyan)),
            const SizedBox(width: 8),
            Expanded(
              child: _metricCard(
                  'Delivered', delivered, DesignTokens.neonGreen)),
            const SizedBox(width: 8),
            Expanded(
              child: _metricCard(
                  'Processing', processing, DesignTokens.neonAmber)),
            const SizedBox(width: 8),
            Expanded(
              child: _metricCard('Failed', failed, DesignTokens.neonRed)),
          ],
        ),
        const SizedBox(height: 20),

        // Recent exports
        _sectionLabel('RECENT SHIPMENTS'),
        const SizedBox(height: 8),
        if (_exportHistory.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.local_shipping_outlined,
                    color: Colors.white.withValues(alpha: 0.1), size: 40),
                const SizedBox(height: 8),
                Text(
                  'No shipments yet',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Go to SHIP NOW to blast content worldwide',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          )
        else
          ..._exportHistory
              .take(20)
              .map(_buildExportHistoryTile),
        const SizedBox(height: 20),

        // Quick actions
        _sectionLabel('QUICK ACTIONS'),
        const SizedBox(height: 8),
        _actionButton(
          Icons.rocket_launch,
          'Ship to All Markets',
          'Blast current content to all $_activeMarkets active markets',
          DesignTokens.neonGreen,
          () {
            setState(() {
              _selectedMarkets.addAll(_markets.map((m) => m.id));
              _tabController.animateTo(1);
            });
          },
        ),
        _actionButton(
          Icons.analytics,
          'Market Export Dashboard',
          'Detailed analytics & market-level insights',
          DesignTokens.neonCyan,
          () => context.push('/promoter/market-export'),
        ),
        _actionButton(
          Icons.file_download,
          'Export User Data (GDPR)',
          'Download all your DFC data',
          DesignTokens.neonAmber,
          () => context.push('/settings'),
        ),
      ],
    );
  }

  Widget _metricCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportHistoryTile(ExportPackage pkg) {
    Color statusColor;
    IconData statusIcon;
    switch (pkg.status) {
      case ExportStatus.delivered:
        statusColor = DesignTokens.neonGreen;
        statusIcon = Icons.check_circle;
        break;
      case ExportStatus.dispatched:
        statusColor = DesignTokens.neonCyan;
        statusIcon = Icons.send;
        break;
      case ExportStatus.processing:
        statusColor = DesignTokens.neonAmber;
        statusIcon = Icons.hourglass_top;
        break;
      case ExportStatus.queued:
        statusColor = Colors.white.withValues(alpha: 0.3);
        statusIcon = Icons.queue;
        break;
      case ExportStatus.failed:
        statusColor = DesignTokens.neonRed;
        statusIcon = Icons.error_outline;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pkg.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${pkg.market.regionCode} · ${pkg.sourceType} · ${_timeAgo(pkg.createdAt)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                pkg.status.name.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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
              Icon(Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.1), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.3),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }

  Color _regionColor(String regionCode) {
    switch (regionCode) {
      case 'AUNZ':
        return DesignTokens.neonGreen;
      case 'NA':
        return DesignTokens.neonCyan;
      case 'UK_EU':
        return DesignTokens.neonAmber;
      case 'SEA':
        return DesignTokens.neonMagenta;
      case 'JAPAN':
        return DesignTokens.neonRed;
      case 'LATAM':
        return const Color(0xFFFF6B35);
      case 'AFRICA':
        return DesignTokens.neonGold;
      case 'INDIA':
        return const Color(0xFF9B59B6);
      default:
        return DesignTokens.neonCyan;
    }
  }

  String _regionFlag(String regionCode) {
    switch (regionCode) {
      case 'AUNZ':
        return '🇦🇺';
      case 'NA':
        return '🇺🇸';
      case 'UK_EU':
        return '🇬🇧';
      case 'SEA':
        return '🇸🇬';
      case 'JAPAN':
        return '🇯🇵';
      case 'LATAM':
        return '🇧🇷';
      case 'AFRICA':
        return '🇿🇦';
      case 'INDIA':
        return '🇮🇳';
      default:
        return '🌍';
    }
  }

  IconData _platformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.camera_alt;
      case 'youtube':
        return Icons.play_circle;
      case 'tiktok':
        return Icons.music_note;
      case 'x (twitter)':
      case 'x':
        return Icons.alternate_email;
      case 'threads':
        return Icons.forum;
      case 'whatsapp':
        return Icons.chat;
      case 'linkedin':
        return Icons.work;
      case 'bluesky':
        return Icons.cloud;
      case 'rednote':
        return Icons.note;
      default:
        return Icons.language;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}
