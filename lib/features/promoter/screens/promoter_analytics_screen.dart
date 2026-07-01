import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PROMOTER ANALYTICS & REGIONAL TARGETING — Owner Command Center
// Precision geo-targeting, campaign KPIs, social boost amplification
// ═══════════════════════════════════════════════════════════════════════════

const _kCyan = Color(0xFF00E5FF);
const _kMagenta = Color(0xFFE040FB);
const _kGreen = Color(0xFF00E676);
const _kOrange = Color(0xFFFF9100);
const _kRed = Color(0xFFFF1744);
const _kGold = Color(0xFFFFD740);
const _kBg = Color(0xFF060A14);
const _kPanel = Color(0xFF0C1226);
const _kBorder = Color(0xFF1A2744);

// ── Region definitions ─────────────────────────────────────────────────
class _TargetRegion {
  final String id;
  final String name;
  final String flag;
  final List<String> subRegions;
  final Color color;
  bool active;
  double budgetPercent;
  // Demo metrics
  final int impressions;
  final int clicks;
  final int conversions;
  final double cpc;
  final double roi;

  _TargetRegion({
    required this.id,
    required this.name,
    required this.flag,
    required this.subRegions,
    required this.color,
    this.active = false,
    this.budgetPercent = 0,
    this.impressions = 0,
    this.clicks = 0,
    this.conversions = 0,
    this.cpc = 0,
    this.roi = 0,
  });
}

class _BoostTier {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int multiplier;
  final String price;
  bool active;

  _BoostTier({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.multiplier,
    required this.price,
    this.active = false,
  });
}

class PromoterAnalyticsScreen extends StatefulWidget {
  const PromoterAnalyticsScreen({super.key});

  @override
  State<PromoterAnalyticsScreen> createState() =>
      _PromoterAnalyticsScreenState();
}

class _PromoterAnalyticsScreenState extends State<PromoterAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // ── Regions ──────────────────────────────────────────────────────────
  late final List<_TargetRegion> _regions;

  // ── Boost tiers ──────────────────────────────────────────────────────
  late final List<_BoostTier> _boosts;

  // ── Campaign timeline data (12 weeks) ────────────────────────────────
  final _weekLabels = [
    'W1',
    'W2',
    'W3',
    'W4',
    'W5',
    'W6',
    'W7',
    'W8',
    'W9',
    'W10',
    'W11',
    'W12',
  ];
  final _impressionsByWeek = <double>[
    12400,
    18200,
    24800,
    31500,
    28900,
    42100,
    55200,
    48600,
    62300,
    71800,
    84500,
    96200,
  ];
  final _clicksByWeek = <double>[
    620,
    910,
    1240,
    1575,
    1445,
    2105,
    2760,
    2430,
    3115,
    3590,
    4225,
    4810,
  ];
  final _conversionsByWeek = <double>[
    31,
    46,
    62,
    79,
    72,
    105,
    138,
    122,
    156,
    180,
    211,
    241,
  ];

  // Total budget
  final double _totalBudget = 25000;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);

    _regions = [
      _TargetRegion(
        id: 'us',
        name: 'United States',
        flag: '🇺🇸',
        subRegions: [
          'California',
          'Texas',
          'Florida',
          'New York',
          'Nevada',
          'Arizona',
          'Illinois',
          'Ohio',
          'Georgia',
          'New Jersey',
        ],
        color: _kCyan,
        active: true,
        budgetPercent: 35,
        impressions: 284500,
        clicks: 14225,
        conversions: 711,
        cpc: 0.62,
        roi: 3.8,
      ),
      _TargetRegion(
        id: 'au',
        name: 'Australia & NZ',
        flag: '🇦🇺',
        subRegions: [
          'Sydney',
          'Melbourne',
          'Brisbane',
          'Perth',
          'Auckland',
          'Gold Coast',
        ],
        color: _kGreen,
        active: true,
        budgetPercent: 20,
        impressions: 142800,
        clicks: 8568,
        conversions: 428,
        cpc: 0.58,
        roi: 4.1,
      ),
      _TargetRegion(
        id: 'me',
        name: 'Middle East',
        flag: '🇦🇪',
        subRegions: [
          'Dubai',
          'Abu Dhabi',
          'Riyadh',
          'Doha',
          'Bahrain',
          'Kuwait',
        ],
        color: _kGold,
        active: true,
        budgetPercent: 20,
        impressions: 98400,
        clicks: 5904,
        conversions: 295,
        cpc: 0.85,
        roi: 2.9,
      ),
      _TargetRegion(
        id: 'asia',
        name: 'Asia-Pacific',
        flag: '🇯🇵',
        subRegions: [
          'Japan',
          'Thailand',
          'Philippines',
          'South Korea',
          'Singapore',
          'Indonesia',
        ],
        color: _kMagenta,
        active: true,
        budgetPercent: 15,
        impressions: 76200,
        clicks: 4572,
        conversions: 229,
        cpc: 0.74,
        roi: 3.2,
      ),
      _TargetRegion(
        id: 'uk',
        name: 'UK & Europe',
        flag: '🇬🇧',
        subRegions: [
          'London',
          'Manchester',
          'Dublin',
          'Paris',
          'Berlin',
          'Amsterdam',
        ],
        color: _kOrange,
        budgetPercent: 10,
        impressions: 52100,
        clicks: 3126,
        conversions: 156,
        cpc: 0.80,
        roi: 2.4,
      ),
      _TargetRegion(
        id: 'latam',
        name: 'Latin America',
        flag: '🇧🇷',
        subRegions: [
          'Brazil',
          'Mexico',
          'Colombia',
          'Argentina',
          'Chile',
          'Peru',
        ],
        color: _kRed,
        impressions: 31400,
        clicks: 1884,
        conversions: 94,
        cpc: 0.42,
        roi: 3.6,
      ),
      _TargetRegion(
        id: 'africa',
        name: 'Africa',
        flag: '🇿🇦',
        subRegions: [
          'South Africa',
          'Nigeria',
          'Kenya',
          'Egypt',
          'Morocco',
          'Ghana',
        ],
        color: const Color(0xFF8E24AA),
        impressions: 18600,
        clicks: 1116,
        conversions: 56,
        cpc: 0.38,
        roi: 4.2,
      ),
    ];

    _boosts = [
      _BoostTier(
        name: 'STREET TEAM',
        description:
            'Micro-influencer network — 50 combat sport creators share your event across socials',
        icon: Icons.groups,
        color: _kCyan,
        multiplier: 3,
        price: '\$199/week',
        active: true,
      ),
      _BoostTier(
        name: 'ENTOURAGE EFFECT',
        description:
            'Mid-tier fighter endorsements — verified athletes repost, tag, story-share your promo',
        icon: Icons.local_fire_department,
        color: _kOrange,
        multiplier: 8,
        price: '\$499/week',
      ),
      _BoostTier(
        name: 'MAIN EVENT PUSH',
        description:
            'Top-tier influencer blitz — major combat sport accounts, podcasters, and media outlets amplify',
        icon: Icons.rocket_launch,
        color: _kMagenta,
        multiplier: 25,
        price: '\$1,499/week',
      ),
      _BoostTier(
        name: 'CHAMPIONSHIP WAVE',
        description:
            'Full saturation — A-list fighter co-signs, media features, trending hashtag campaign, live takeover',
        icon: Icons.emoji_events,
        color: _kGold,
        multiplier: 100,
        price: '\$4,999/week',
      ),
    ];
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  int get _totalImpressions =>
      _regions.where((r) => r.active).fold(0, (s, r) => s + r.impressions);
  int get _totalClicks =>
      _regions.where((r) => r.active).fold(0, (s, r) => s + r.clicks);
  int get _totalConversions =>
      _regions.where((r) => r.active).fold(0, (s, r) => s + r.conversions);
  double get _avgCPC {
    final active = _regions.where((r) => r.active).toList();
    if (active.isEmpty) return 0;
    return active.fold(0.0, (s, r) => s + r.cpc) / active.length;
  }

  double get _avgROI {
    final active = _regions.where((r) => r.active).toList();
    if (active.isEmpty) return 0;
    return active.fold(0.0, (s, r) => s + r.roi) / active.length;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          _buildAppBar(),
          _buildGlobalKPIs(),
          SliverPersistentHeader(
            pinned: true,
            delegate: _PinnedTabBar(
              tabBar: TabBar(
                controller: _tabCtrl,
                indicatorColor: _kMagenta,
                indicatorWeight: 3,
                labelColor: _kMagenta,
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
                tabs: const [
                  Tab(text: 'REGIONS'),
                  Tab(text: 'PERFORMANCE'),
                  Tab(text: 'SOCIAL BOOST'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildRegionsTab(),
            _buildPerformanceTab(),
            _buildSocialBoostTab(),
          ],
        ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _kBg.withValues(alpha: 0.95),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.canPop() ? context.pop() : null,
      ),
      title: const Row(
        children: [
          Icon(Icons.radar, color: _kMagenta, size: 22),
          SizedBox(width: 10),
          Text(
            'TARGETING HQ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          SizedBox(width: 8),
          _LiveBadge(),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: _kCyan, size: 20),
          onPressed: () => setState(() {}),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Global KPIs Bar ──────────────────────────────────────────────────
  SliverToBoxAdapter _buildGlobalKPIs() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _kMagenta.withValues(alpha: 0.08),
              _kCyan.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kMagenta.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speed, color: _kMagenta, size: 16),
                const SizedBox(width: 6),
                Text(
                  'GLOBAL CAMPAIGN OVERVIEW',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'BUDGET: \$${_totalBudget.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: _kGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniKPI(
                  label: 'IMPRESSIONS',
                  value: _formatNum(_totalImpressions),
                  color: _kCyan,
                ),
                _MiniKPI(
                  label: 'CLICKS',
                  value: _formatNum(_totalClicks),
                  color: _kGreen,
                ),
                _MiniKPI(
                  label: 'CONVERTS',
                  value: _formatNum(_totalConversions),
                  color: _kGold,
                ),
                _MiniKPI(
                  label: 'AVG CPC',
                  value: '\$${_avgCPC.toStringAsFixed(2)}',
                  color: _kOrange,
                ),
                _MiniKPI(
                  label: 'AVG ROI',
                  value: '${_avgROI.toStringAsFixed(1)}x',
                  color: _kMagenta,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 1 — REGIONS (Geo-Targeting)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildRegionsTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Budget allocation header
        _buildBudgetAllocationBar(),
        const SizedBox(height: 16),

        // Region cards
        ..._regions.map(_buildRegionCard),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildBudgetAllocationBar() {
    final activeRegions = _regions.where((r) => r.active).toList();
    final totalAlloc = activeRegions.fold(0.0, (s, r) => s + r.budgetPercent);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart, color: _kGold, size: 16),
              const SizedBox(width: 6),
              const Text(
                'BUDGET ALLOCATION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                '${totalAlloc.toStringAsFixed(0)}% allocated',
                style: TextStyle(
                  color: totalAlloc > 100 ? _kRed : _kGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  ...activeRegions.map((r) {
                    final frac = r.budgetPercent / math.max(totalAlloc, 1);
                    return Expanded(
                      flex: (frac * 1000).round().clamp(1, 1000),
                      child: Container(
                        color: r.color.withValues(alpha: 0.7),
                        alignment: Alignment.center,
                        child: frac > 0.08
                            ? Text(
                                '${r.budgetPercent.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              )
                            : null,
                      ),
                    );
                  }),
                  if (totalAlloc < 100)
                    Expanded(
                      flex: ((1 - totalAlloc / 100) * 1000).round().clamp(
                        1,
                        1000,
                      ),
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.05),
                        alignment: Alignment.center,
                        child: Text(
                          '${(100 - totalAlloc).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: activeRegions
                .map(
                  (r) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: r.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${r.flag} ${r.name}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionCard(_TargetRegion region) {
    final budgetDollars = _totalBudget * (region.budgetPercent / 100);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: region.active ? region.color.withValues(alpha: 0.4) : _kBorder,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            onTap: () {
              setState(() => region.active = !region.active);
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Text(region.flag, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          region.name,
                          style: TextStyle(
                            color: region.active
                                ? Colors.white
                                : Colors.white54,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          region.subRegions.take(4).join(' · '),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Toggle switch
                  Switch(
                    value: region.active,
                    activeThumbColor: region.color,
                    onChanged: (v) => setState(() => region.active = v),
                  ),
                ],
              ),
            ),
          ),

          // Metrics row (visible when active)
          if (region.active) ...[
            Container(height: 1, color: _kBorder),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  // KPI row
                  Row(
                    children: [
                      _RegionStat(
                        label: 'Impressions',
                        value: _formatNum(region.impressions),
                        color: region.color,
                      ),
                      _RegionStat(
                        label: 'Clicks',
                        value: _formatNum(region.clicks),
                        color: _kCyan,
                      ),
                      _RegionStat(
                        label: 'Converts',
                        value: _formatNum(region.conversions),
                        color: _kGreen,
                      ),
                      _RegionStat(
                        label: 'CPC',
                        value: '\$${region.cpc.toStringAsFixed(2)}',
                        color: _kOrange,
                      ),
                      _RegionStat(
                        label: 'ROI',
                        value: '${region.roi.toStringAsFixed(1)}x',
                        color: region.roi >= 3.5 ? _kGreen : _kGold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Budget slider
                  Row(
                    children: [
                      Text(
                        'BUDGET',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7,
                            ),
                            activeTrackColor: region.color,
                            inactiveTrackColor: region.color.withValues(
                              alpha: 0.15,
                            ),
                            thumbColor: region.color,
                            overlayColor: region.color.withValues(alpha: 0.15),
                          ),
                          child: Slider(
                            value: region.budgetPercent,
                            max: 60,
                            divisions: 12,
                            onChanged: (v) =>
                                setState(() => region.budgetPercent = v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 80,
                        child: Text(
                          '${region.budgetPercent.toStringAsFixed(0)}% · \$${budgetDollars.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: region.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Sub-region chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: region.subRegions.map((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: region.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: region.color.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            color: region.color.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 2 — PERFORMANCE (Charts)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildPerformanceTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Impressions chart
        _buildChartSection(
          title: 'IMPRESSIONS',
          icon: Icons.visibility,
          color: _kCyan,
          data: _impressionsByWeek,
          chartColor: _kCyan,
        ),
        const SizedBox(height: 16),

        // Clicks chart
        _buildChartSection(
          title: 'CLICKS',
          icon: Icons.touch_app,
          color: _kGreen,
          data: _clicksByWeek,
          chartColor: _kGreen,
        ),
        const SizedBox(height: 16),

        // Conversions chart
        _buildChartSection(
          title: 'CONVERSIONS',
          icon: Icons.check_circle,
          color: _kGold,
          data: _conversionsByWeek,
          chartColor: _kGold,
        ),
        const SizedBox(height: 16),

        // Region breakdown pie
        _buildRegionBreakdownPie(),
        const SizedBox(height: 16),

        // Region comparison bars
        _buildRegionComparisonBars(),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildChartSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<double> data,
    required Color chartColor,
  }) {
    final maxVal = data.reduce(math.max);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                _formatNum(data.last.round()),
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.trending_up, color: color, size: 14),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: maxVal / 4,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    
                  ),
                  rightTitles: const AxisTitles(
                    
                  ),
                  topTitles: const AxisTitles(
                    
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= _weekLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          _weekLabels[idx],
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                minY: 0,
                maxY: maxVal * 1.15,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      data.length,
                      (i) => FlSpot(i.toDouble(), data[i]),
                    ),
                    isCurved: true,
                    color: chartColor,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                            radius: 3,
                            color: chartColor,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          chartColor.withValues(alpha: 0.25),
                          chartColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => _kPanel,
                    getTooltipItems: (spots) => spots.map((s) {
                      return LineTooltipItem(
                        _formatNum(s.y.round()),
                        TextStyle(
                          color: chartColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionBreakdownPie() {
    final activeRegions = _regions.where((r) => r.active).toList();
    if (activeRegions.isEmpty) {
      return const SizedBox.shrink();
    }
    final total = activeRegions.fold(0, (s, r) => s + r.impressions);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.donut_large, color: _kMagenta, size: 16),
              SizedBox(width: 6),
              Text(
                'IMPRESSIONS BY REGION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 35,
                      sections: activeRegions.map((r) {
                        final pct = total > 0
                            ? (r.impressions / total * 100)
                            : 0.0;
                        return PieChartSectionData(
                          value: r.impressions.toDouble(),
                          color: r.color,
                          radius: 50,
                          title: '${pct.toStringAsFixed(0)}%',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: activeRegions.map((r) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: r.color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${r.flag} ${r.name}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionComparisonBars() {
    final activeRegions = _regions.where((r) => r.active).toList();
    if (activeRegions.isEmpty) return const SizedBox.shrink();
    final maxImp = activeRegions
        .map((r) => r.impressions)
        .reduce(math.max)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: _kCyan, size: 16),
              SizedBox(width: 6),
              Text(
                'REGION COMPARISON',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: activeRegions.length * 52.0,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxImp * 1.15,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => _kPanel,
                    getTooltipItem: (group, gIdx, rod, rIdx) {
                      final r = activeRegions[group.x.toInt()];
                      return BarTooltipItem(
                        '${r.flag} ${_formatNum(r.impressions)} imp\n'
                        '${_formatNum(r.clicks)} clicks · ${r.roi}x ROI',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    
                  ),
                  rightTitles: const AxisTitles(
                    
                  ),
                  topTitles: const AxisTitles(
                    
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= activeRegions.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          activeRegions[idx].flag,
                          style: const TextStyle(fontSize: 16),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: List.generate(activeRegions.length, (i) {
                  final r = activeRegions[i];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: r.impressions.toDouble(),
                        width: 22,
                        color: r.color,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxImp * 1.15,
                          color: r.color.withValues(alpha: 0.06),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 3 — SOCIAL BOOST (Amplification)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildSocialBoostTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Boost header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _kMagenta.withValues(alpha: 0.12),
                _kOrange.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kMagenta.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt, color: _kGold, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'SOCIAL AMPLIFICATION ENGINE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Activate boost tiers to amplify your promotions across the combat sport ecosystem. '
                'Each tier increases your reach multiplier through verified networks.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Boost tiers
        ..._boosts.map(_buildBoostCard),

        const SizedBox(height: 16),

        // Active boost metrics
        _buildCurrentBoostMetrics(),
        const SizedBox(height: 16),

        // Viral reach projection
        _buildViralProjection(),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildBoostCard(_BoostTier boost) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: boost.active ? _kPanel : _kBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: boost.active ? boost.color.withValues(alpha: 0.5) : _kBorder,
          width: boost.active ? 1.5 : 1,
        ),
        boxShadow: boost.active
            ? [
                BoxShadow(
                  color: boost.color.withValues(alpha: 0.15),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => boost.active = !boost.active),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: boost.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: boost.color.withValues(alpha: 0.3)),
                ),
                child: Icon(boost.icon, color: boost.color, size: 26),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          boost.name,
                          style: TextStyle(
                            color: boost.active ? boost.color : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: boost.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${boost.multiplier}x REACH',
                            style: TextStyle(
                              color: boost.color,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      boost.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      boost.price,
                      style: TextStyle(
                        color: boost.color.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              // Activate button
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: boost.active
                      ? boost.color.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: boost.active
                        ? boost.color
                        : Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  boost.active ? 'ACTIVE' : 'BOOST',
                  style: TextStyle(
                    color: boost.active ? boost.color : Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentBoostMetrics() {
    final activeBoosts = _boosts.where((b) => b.active).toList();
    final totalMultiplier = activeBoosts.fold(1, (s, b) => s * b.multiplier);
    final projectedReach = _totalImpressions * totalMultiplier;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, color: _kGold, size: 16),
              const SizedBox(width: 6),
              const Text(
                'BOOSTED METRICS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${totalMultiplier}x MULTIPLIER',
                  style: const TextStyle(
                    color: _kGold,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _BoostMetric(
                label: 'BASE REACH',
                value: _formatNum(_totalImpressions),
                color: _kCyan,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.white24,
                  size: 16,
                ),
              ),
              _BoostMetric(
                label: 'PROJECTED',
                value: _formatNum(projectedReach),
                color: _kGold,
              ),
              const Spacer(),
              _BoostMetric(
                label: 'ACTIVE TIERS',
                value: '${activeBoosts.length}',
                color: _kMagenta,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViralProjection() {
    final activeBoosts = _boosts.where((b) => b.active).toList();
    final totalMultiplier = activeBoosts.fold(1, (s, b) => s * b.multiplier);

    // Generate projection curve
    final projWeeks = List.generate(12, (i) {
      final base = _impressionsByWeek[i];
      final boosted = base * totalMultiplier;
      // Viral compound — reaches grow faster each week
      final viralCompound = boosted * (1 + (i * 0.08));
      return viralCompound;
    });
    final maxProj = projWeeks.reduce(math.max);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.rocket_launch, color: _kOrange, size: 16),
              SizedBox(width: 6),
              Text(
                'VIRAL PROJECTION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Projected reach with active boost tiers over 12 weeks',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: maxProj > 0 ? maxProj / 4 : 1,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.white.withValues(alpha: 0.04),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    
                  ),
                  rightTitles: const AxisTitles(
                    
                  ),
                  topTitles: const AxisTitles(
                    
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= _weekLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          _weekLabels[idx],
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 11,
                minY: 0,
                maxY: maxProj * 1.15,
                lineBarsData: [
                  // Base impressions (faded)
                  LineChartBarData(
                    spots: List.generate(
                      _impressionsByWeek.length,
                      (i) => FlSpot(i.toDouble(), _impressionsByWeek[i]),
                    ),
                    isCurved: true,
                    color: Colors.white.withValues(alpha: 0.15),
                    barWidth: 1.5,
                    dotData: const FlDotData(show: false),
                    dashArray: [4, 4],
                  ),
                  // Projected (boosted)
                  LineChartBarData(
                    spots: List.generate(
                      projWeeks.length,
                      (i) => FlSpot(i.toDouble(), projWeeks[i]),
                    ),
                    isCurved: true,
                    color: _kOrange,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _kOrange.withValues(alpha: 0.2),
                          _kOrange.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: const LineTouchData(enabled: false),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 16,
                height: 2,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              const SizedBox(width: 4),
              Text(
                'Base',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 16),
              Container(width: 16, height: 2, color: _kOrange),
              const SizedBox(width: 4),
              const Text(
                'Boosted projection',
                style: TextStyle(color: _kOrange, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────
  String _formatNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _kGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _kGreen.withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: _kGreen, size: 6),
          SizedBox(width: 3),
          Text(
            'LIVE',
            style: TextStyle(
              color: _kGreen,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniKPI extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniKPI({
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
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _RegionStat({
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
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BoostMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _BoostMetric({
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _PinnedTabBar extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _PinnedTabBar({required this.tabBar});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext ctx, double shrink, bool overlap) {
    return Container(color: _kBg, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _PinnedTabBar old) => false;
}
