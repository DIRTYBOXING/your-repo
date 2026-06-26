import 'package:flutter/material.dart';
import '../../../shared/services/market_export_engine.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MARKET EXPORT — Global Revenue Pipeline Dashboard
/// ═══════════════════════════════════════════════════════════════════════════
///
/// 8 target markets · Localized PPV pricing · Platform-specific formatting
/// Every export injects PPV buy-links to drive overseas revenue.
/// ═══════════════════════════════════════════════════════════════════════════

const _kCyan = Color(0xFF00E5FF);
const _kMagenta = Color(0xFFE040FB);
const _kGreen = Color(0xFF00E676);
const _kOrange = Color(0xFFFF9100);
const _kGold = Color(0xFFFFD740);
const _kBg = Color(0xFF060A14);
const _kPanel = Color(0xFF0C1226);
const _kBorder = Color(0xFF1A2744);

class MarketExportScreen extends StatefulWidget {
  const MarketExportScreen({super.key});
  @override
  State<MarketExportScreen> createState() => _MarketExportScreenState();
}

class _MarketExportScreenState extends State<MarketExportScreen>
    with SingleTickerProviderStateMixin {
  final MarketExportEngine _engine = MarketExportEngine();
  late TabController _tabCtrl;
  bool _loading = true;

  // Quick-fire export form
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final Set<String> _selectedMarketIds = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _engine.addListener(_onUpdate);
    _boot();
  }

  Future<void> _boot() async {
    await Future.wait([_engine.loadHistory(), _engine.loadAnalytics()]);
    if (mounted) setState(() => _loading = false);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _engine.removeListener(_onUpdate);
    _engine.dispose();
    _tabCtrl.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
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
                SliverToBoxAdapter(child: _buildStatsRow()),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      controller: _tabCtrl,
                      indicatorColor: _kCyan,
                      labelColor: _kCyan,
                      unselectedLabelColor: Colors.white38,
                      tabs: const [
                        Tab(text: 'MARKETS'),
                        Tab(text: 'EXPORT'),
                        Tab(text: 'HISTORY'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildMarketsTab(),
                  _buildExportTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D0D2B), Color(0xFF060A14)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              const Text(
                'MARKET EXPORT',
                style: TextStyle(
                  color: _kCyan,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${MarketExportEngine.targetMarkets.length} REGIONS',
                  style: const TextStyle(
                    color: _kGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text(
              'AU/NZ fight content → Global PPV revenue',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Row ─────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _statCard('Exported', '${_engine.totalExported}', _kCyan),
          const SizedBox(width: 8),
          _statCard(
            'Markets',
            '${MarketExportEngine.targetMarkets.where((m) => m.isActive).length}',
            _kGreen,
          ),
          const SizedBox(width: 8),
          _statCard(
            'Queued',
            '${_engine.packages.where((p) => p.status == ExportStatus.queued).length}',
            _kOrange,
          ),
          const SizedBox(width: 8),
          _statCard(
            'Status',
            _engine.isExporting ? 'LIVE' : 'READY',
            _engine.isExporting ? _kMagenta : _kGold,
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: _kPanel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TAB 1 — MARKETS (geo-targeted regions with localized PPV pricing)
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildMarketsTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: MarketExportEngine.targetMarkets.length,
      itemBuilder: (ctx, i) {
        final market = MarketExportEngine.targetMarkets[i];
        final analytics = _engine.analytics[market.id];
        final exported = _engine.packagesForMarket(market.id).length;
        return _marketCard(market, exported, analytics);
      },
    );
  }

  Widget _marketCard(
    ExportMarket market,
    int exported,
    ExportAnalytics? analytics,
  ) {
    final ppvPrice = _engine.localizedPpvPrice(market);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _regionFlag(market.regionCode),
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      market.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PPV $ppvPrice · ${market.currency}',
                      style: const TextStyle(
                        color: _kGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: market.isActive
                      ? _kGreen.withValues(alpha: 0.15)
                      : Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  market.isActive ? 'ACTIVE' : 'OFF',
                  style: TextStyle(
                    color: market.isActive ? _kGreen : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Platform chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: market.platforms.map((p) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kCyan.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _kCyan.withValues(alpha: 0.2)),
                ),
                child: Text(
                  p.toUpperCase(),
                  style: const TextStyle(
                    color: _kCyan,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Stats row
          Row(
            children: [
              _miniStat('Exported', '$exported', _kCyan),
              const SizedBox(width: 12),
              _miniStat('PPV Clicks', '${analytics?.ppvClicks ?? 0}', _kOrange),
              const SizedBox(width: 12),
              _miniStat(
                'Purchases',
                '${analytics?.ppvPurchases ?? 0}',
                _kGreen,
              ),
              const SizedBox(width: 12),
              _miniStat(
                'Conv %',
                '${(analytics?.conversionRate ?? 0).toStringAsFixed(1)}%',
                _kMagenta,
              ),
            ],
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
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TAB 2 — EXPORT (quick-fire blast to selected markets)
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title field
          _inputField('Headline', _titleCtrl, 'Fight Night AU — PPV LIVE'),
          const SizedBox(height: 10),
          // Body field
          _inputField(
            'Promo Body',
            _bodyCtrl,
            'Australian combat sports at its finest. Watch live PPV on DFC.',
            maxLines: 4,
          ),
          const SizedBox(height: 16),

          // Market selection
          const Text(
            'TARGET MARKETS',
            style: TextStyle(
              color: _kCyan,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MarketExportEngine.targetMarkets.map((m) {
              final selected = _selectedMarketIds.contains(m.id);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedMarketIds.remove(m.id);
                    } else {
                      _selectedMarketIds.add(m.id);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? _kCyan.withValues(alpha: 0.15) : _kPanel,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? _kCyan : _kBorder,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _regionFlag(m.regionCode),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        m.name,
                        style: TextStyle(
                          color: selected ? _kCyan : Colors.white70,
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Select all / clear
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() {
                  _selectedMarketIds.addAll(
                    MarketExportEngine.targetMarkets.map((m) => m.id),
                  );
                }),
                child: const Text(
                  'SELECT ALL',
                  style: TextStyle(color: _kCyan, fontSize: 11),
                ),
              ),
              TextButton(
                onPressed: () => setState(_selectedMarketIds.clear),
                child: const Text(
                  'CLEAR',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick-blast presets
          const Text(
            'QUICK BLASTS',
            style: TextStyle(
              color: _kGold,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quickBlastBtn(
                'GLOBAL PPV PUSH',
                Icons.public,
                _kMagenta,
                () => _fireBlast(
                  'PPV LIVE — Australian Combat Sports',
                  'Watch the biggest fight night from Australia LIVE on DataFightCentral PPV. Real fights, real data, real time.',
                  null,
                ),
              ),
              _quickBlastBtn(
                'MMA AUNZ EXPORT',
                Icons.sports_mma,
                _kCyan,
                () => _fireBlast(
                  'MMA from Down Under — LIVE PPV',
                  'Australian and New Zealand MMA is on FIRE. Watch the next generation of fighters compete live on DFC.',
                  ['aunz', 'na', 'uk_eu', 'sea'],
                ),
              ),
              _quickBlastBtn(
                'BKFC WORLDWIDE',
                Icons.front_hand,
                _kOrange,
                () => _fireBlast(
                  'Bare Knuckle Fighting — Raw, Real, Uncut',
                  'BKFC and IBC are redefining combat sports. No gloves, no excuses. PPV available worldwide on DFC.',
                  null,
                ),
              ),
              _quickBlastBtn(
                'BOXING ASIA PUSH',
                Icons.sports_kabaddi,
                _kGreen,
                () => _fireBlast(
                  'Boxing from Australia — Watch LIVE',
                  'Professional boxing from Australia and New Zealand. Stream live or watch replays on DFC PPV.',
                  ['sea', 'japan', 'india'],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // FIRE button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _engine.isExporting ? null : _fireCustomExport,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kCyan.withValues(alpha: 0.15),
                foregroundColor: _kCyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: _kCyan),
                ),
              ),
              icon: _engine.isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: _kCyan,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.rocket_launch, size: 20),
              label: Text(
                _engine.isExporting ? 'EXPORTING...' : 'FIRE EXPORT',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(
    String label,
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _kCyan, fontSize: 12),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
        filled: true,
        fillColor: _kPanel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kCyan),
        ),
      ),
    );
  }

  Widget _quickBlastBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: _engine.isExporting ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TAB 3 — HISTORY (export log)
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildHistoryTab() {
    if (_engine.packages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.public_off,
              color: Colors.white.withValues(alpha: 0.15),
              size: 64,
            ),
            const SizedBox(height: 12),
            Text(
              'No exports yet',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Fire your first export from the EXPORT tab',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _engine.packages.length,
      itemBuilder: (ctx, i) {
        final pkg = _engine.packages[i];
        return _packageCard(pkg);
      },
    );
  }

  Widget _packageCard(ExportPackage pkg) {
    final statusColor = switch (pkg.status) {
      ExportStatus.dispatched => _kGreen,
      ExportStatus.delivered => _kCyan,
      ExportStatus.queued => _kOrange,
      ExportStatus.processing => _kMagenta,
      ExportStatus.failed => Colors.red,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _regionFlag(pkg.market.regionCode),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pkg.title,
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  pkg.status.name.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${pkg.market.name} · PPV ${pkg.ppvPrice} · ${pkg.targetPlatforms.length} platforms',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
          Text(
            pkg.sourceType == 'war_room'
                ? 'Source: War Room'
                : 'Source: ${pkg.sourceType}',
            style: TextStyle(
              color: _kCyan.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────
  Future<void> _fireCustomExport() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a headline and promo body'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedMarketIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one target market'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedMarketIds.length == MarketExportEngine.targetMarkets.length) {
      await _engine.exportToAllMarkets(
        sourceType: 'manual',
        sourceId: 'export_screen',
        title: title,
        body: body,
        campaignTag: 'manual_export',
      );
    } else {
      for (final mktId in _selectedMarketIds) {
        final market = MarketExportEngine.targetMarkets.firstWhere(
          (m) => m.id == mktId,
        );
        await _engine.exportToMarket(
          sourceType: 'manual',
          sourceId: 'export_screen',
          title: title,
          body: body,
          market: market,
          campaignTag: 'manual_export',
        );
      }
    }

    if (mounted) {
      _titleCtrl.clear();
      _bodyCtrl.clear();
      _selectedMarketIds.clear();
      _tabCtrl.animateTo(2); // switch to history tab
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export dispatched!'),
          backgroundColor: Color(0xFF00E676),
        ),
      );
    }
  }

  Future<void> _fireBlast(
    String title,
    String body,
    List<String>? marketIds,
  ) async {
    if (marketIds != null) {
      for (final mktId in marketIds) {
        final market = MarketExportEngine.targetMarkets.firstWhere(
          (m) => m.id == mktId,
        );
        await _engine.exportToMarket(
          sourceType: 'quick_blast',
          sourceId: 'export_screen',
          title: title,
          body: body,
          market: market,
          campaignTag: 'quick_blast',
        );
      }
    } else {
      await _engine.exportToAllMarkets(
        sourceType: 'quick_blast',
        sourceId: 'export_screen',
        title: title,
        body: body,
        campaignTag: 'quick_blast',
      );
    }

    if (mounted) {
      _tabCtrl.animateTo(2);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Blast dispatched!'),
          backgroundColor: Color(0xFF00E676),
        ),
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  String _regionFlag(String regionCode) {
    return switch (regionCode) {
      'AUNZ' => '🇦🇺',
      'NA' => '🇺🇸',
      'UK_EU' => '🇬🇧',
      'SEA' => '🇹🇭',
      'JAPAN' => '🇯🇵',
      'LATAM' => '🇧🇷',
      'AFRICA' => '🇿🇦',
      'INDIA' => '🇮🇳',
      _ => '🌍',
    };
  }
}

// ── Tab Bar Delegate ────────────────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _TabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: _kBg, child: _tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate old) => false;
}
