import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 🎬 CREATOR DEAL ROOM — Where creators meet fight promotions
// ─────────────────────────────────────────────────────────────────────────────

class CreatorDealRoom extends StatefulWidget {
  final String userId;
  final String creatorName;

  const CreatorDealRoom({
    super.key,
    required this.userId,
    required this.creatorName,
  });

  @override
  State<CreatorDealRoom> createState() => _CreatorDealRoomState();
}

class _CreatorDealRoomState extends State<CreatorDealRoom>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _entryCtrl;
  late final TabController _tabCtrl;

  // Creator social stats
  double _youtubeSubs = 850000;
  double _tiktokSubs = 2400000;
  double _avgViews = 180000;
  double _ppvPrice = 12.99;

  static final _demoDeals = [
    _CreatorDeal(
      eventName: 'DFC Road to Australia III',
      promoter: 'Fight Network Australia',
      eventDate: DateTime(2026, 6, 15),
      city: 'Melbourne',
      country: 'Australia',
      reachRequired: 500000,
      creatorReach: 3250000,
      revenueShare: 18.0,
      status: _DealStatus.offered,
      projectedEarnings: 48500,
      color: const Color(0xFF00E5FF),
    ),
    _CreatorDeal(
      eventName: 'Pacific Rumble V',
      promoter: 'Pacific Combat Series',
      eventDate: DateTime(2026, 7, 3),
      city: 'Port Moresby',
      country: 'Papua New Guinea',
      reachRequired: 200000,
      creatorReach: 3250000,
      revenueShare: 12.0,
      status: _DealStatus.signed,
      projectedEarnings: 18200,
      color: const Color(0xFF69FF47),
    ),
    _CreatorDeal(
      eventName: 'K1 India Open 2026',
      promoter: 'K1 India Open',
      eventDate: DateTime(2026, 8, 20),
      city: 'Mumbai',
      country: 'India',
      reachRequired: 1000000,
      creatorReach: 3250000,
      revenueShare: 22.0,
      status: _DealStatus.reviewing,
      projectedEarnings: 71400,
      color: const Color(0xFFFFD740),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  double get _totalReach => (_youtubeSubs + _tiktokSubs) * 0.82;
  double get _projectedViewers => _totalReach * 0.04;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD740).withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFD740).withValues(alpha: 0.50),
                ),
              ),
              child: const Icon(
                Icons.video_camera_front,
                color: Color(0xFFFFD740),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Creator Deal Room',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildCreatorHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildCalculatorTab(),
                _buildDealsTab(),
                _buildEarningsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Creator Header ────────────────────────────────────────────────────────
  Widget _buildCreatorHeader() {
    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, child) => Opacity(
        opacity: _entryCtrl.value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - _entryCtrl.value)),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        color: AppTheme.cardDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CREATOR DEAL ROOM',
                        style: TextStyle(
                          color: Color(0xFFFFD740),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.creatorName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, child) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFFFD740,
                      ).withValues(alpha: 0.08 + 0.08 * _pulseCtrl.value),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(
                          0xFFFFD740,
                        ).withValues(alpha: 0.30 + 0.30 * _pulseCtrl.value),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFFD740,
                            ).withValues(alpha: 0.5 + 0.5 * _pulseCtrl.value),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFFD740,
                                ).withValues(alpha: 0.6 * _pulseCtrl.value),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'DEAL READY',
                          style: TextStyle(
                            color: Color(0xFFFFD740),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _reachChip(
                  Icons.play_circle,
                  _fmt(_youtubeSubs.round()),
                  'YouTube',
                  const Color(0xFFFF0000),
                ),
                const SizedBox(width: 8),
                _reachChip(
                  Icons.music_video,
                  _fmt(_tiktokSubs.round()),
                  'TikTok',
                  const Color(0xFF69FF47),
                ),
                const SizedBox(width: 8),
                _reachChip(
                  Icons.visibility,
                  _fmt(_totalReach.round()),
                  'Total Reach',
                  const Color(0xFFFFD740),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _reachChip(IconData icon, String value, String platform, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  platform,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: AppTheme.cardDark,
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: const Color(0xFFFFD740),
        labelColor: const Color(0xFFFFD740),
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        tabs: const [
          Tab(icon: Icon(Icons.calculate, size: 14), text: 'CALCULATOR'),
          Tab(icon: Icon(Icons.handshake, size: 14), text: 'MY DEALS'),
          Tab(
            icon: Icon(Icons.account_balance_wallet, size: 14),
            text: 'EARNINGS',
          ),
        ],
      ),
    );
  }

  // ── Calculator Tab ────────────────────────────────────────────────────────
  Widget _buildCalculatorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('YOUR SOCIAL PROFILE'),
          const SizedBox(height: 10),
          _buildSliderCard(
            'YouTube Subscribers',
            _youtubeSubs,
            1000,
            5000000,
            const Color(0xFFFF0000),
            (v) => setState(() => _youtubeSubs = v),
          ),
          const SizedBox(height: 8),
          _buildSliderCard(
            'TikTok Followers',
            _tiktokSubs,
            1000,
            10000000,
            const Color(0xFF69FF47),
            (v) => setState(() => _tiktokSubs = v),
          ),
          const SizedBox(height: 8),
          _buildSliderCard(
            'Avg Views per Post',
            _avgViews,
            1000,
            2000000,
            AppTheme.accentTeal,
            (v) => setState(() => _avgViews = v),
          ),
          const SizedBox(height: 8),
          _buildSliderCard(
            'PPV Price (AUD \$)',
            _ppvPrice,
            2.99,
            29.99,
            const Color(0xFFFFD740),
            (v) => setState(() => _ppvPrice = v),
          ),
          const SizedBox(height: 14),
          _sectionLabel('YOUR PROJECTED EARNINGS'),
          const SizedBox(height: 10),
          _buildProjectionCard(),
          const SizedBox(height: 14),
          _sectionLabel('REVENUE SPLIT'),
          const SizedBox(height: 10),
          _buildRevenueSplitPie(),
        ],
      ),
    );
  }

  Widget _buildSliderCard(
    String label,
    double value,
    double min,
    double max,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    final displayVal = value >= 1000000
        ? '${(value / 1000000).toStringAsFixed(1)}M'
        : value >= 1000
        ? '${(value / 1000).toStringAsFixed(0)}k'
        : value.toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const Spacer(),
              Text(
                displayVal,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.15),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.15),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectionCard() {
    final scenarios = [
      ('Conservative (2%)', _projectedViewers * 0.5, const Color(0xFF69FF47)),
      ('Base (4%)', _projectedViewers, AppTheme.accentTeal),
      ('Optimistic (8%)', _projectedViewers * 2, const Color(0xFFFFD740)),
    ];
    final maxEarning = scenarios.last.$2 * _ppvPrice * 0.20;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD740).withValues(alpha: 0.08),
            const Color(0xFFFF6B9D).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFD740).withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Color(0xFFFFD740),
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Your earnings per DFC event',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...scenarios.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      s.$1,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0.0,
                        end: maxEarning > 0
                            ? (s.$2 * _ppvPrice * 0.20 / maxEarning).clamp(
                                0.0,
                                1.0,
                              )
                            : 0.0,
                      ),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOut,
                      builder: (_, v, child) => Stack(
                        children: [
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: v,
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: s.$3.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [
                                  BoxShadow(
                                    color: s.$3.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 64,
                    child: Text(
                      '\$${_fmtMoney(s.$2 * _ppvPrice * 0.20)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: s.$3,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSplitPie() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 28,
                sections: [
                  PieChartSectionData(
                    value: 20,
                    color: const Color(0xFFFFD740),
                    radius: 28,
                    title: '20%',
                    titleStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  PieChartSectionData(
                    value: 72,
                    color: const Color(0xFF00E5FF),
                    radius: 28,
                    title: '72%',
                    titleStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  PieChartSectionData(
                    value: 8,
                    color: const Color(0xFFAB47BC),
                    radius: 28,
                    title: '8%',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _legendItem('Creator share', const Color(0xFFFFD740), '20%'),
              const SizedBox(height: 8),
              _legendItem('Promoter share', const Color(0xFF00E5FF), '72%'),
              const SizedBox(height: 8),
              _legendItem('DFC Platform', const Color(0xFFAB47BC), '8%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, String pct) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(width: 4),
        Text(
          pct,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ── Deals Tab ─────────────────────────────────────────────────────────────
  Widget _buildDealsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _demoDeals.length,
      itemBuilder: (_, i) => _buildDealCard(_demoDeals[i], i),
    );
  }

  Widget _buildDealCard(_CreatorDeal deal, int index) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 100),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - v)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: deal.color.withValues(alpha: 0.30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: deal.color.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      deal.eventName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  _dealStatusBadge(deal.status),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${deal.city}, ${deal.country} · ${deal.eventDate.day} ${months[deal.eventDate.month - 1]} ${deal.eventDate.year}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    deal.promoter,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _dealMetric(
                        'Revenue Share',
                        '${deal.revenueShare.toStringAsFixed(0)}%',
                        deal.color,
                      ),
                      const SizedBox(width: 12),
                      _dealMetric(
                        'Proj. Earnings',
                        '\$${_fmtMoney(deal.projectedEarnings.toDouble())}',
                        const Color(0xFFFFD740),
                      ),
                      const SizedBox(width: 12),
                      _dealMetric(
                        'Reach Match',
                        '${((deal.creatorReach / deal.reachRequired) * 100).toStringAsFixed(0)}%',
                        AppTheme.neonGreen,
                      ),
                    ],
                  ),
                  if (deal.status == _DealStatus.offered) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Deal signed: ${deal.eventName}',
                                  ),
                                  backgroundColor: AppTheme.cardDark,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.neonGreen,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'SIGN DEAL',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(
                                color: Colors.redAccent,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'DECLINE',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dealMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _dealStatusBadge(_DealStatus status) {
    final (label, color) = switch (status) {
      _DealStatus.offered => ('OFFERED', const Color(0xFFFFD740)),
      _DealStatus.reviewing => ('REVIEWING', AppTheme.accentTeal),
      _DealStatus.signed => ('SIGNED', AppTheme.neonGreen),
      _DealStatus.declined => ('DECLINED', Colors.redAccent),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.50)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ── Earnings Tab ──────────────────────────────────────────────────────────
  Widget _buildEarningsTab() {
    const months = ['Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar'];
    const earnings = [0.0, 0.0, 18200.0, 18200.0, 18200.0, 66700.0];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFD740).withValues(alpha: 0.10),
                  const Color(0xFFFF6B9D).withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFFFD740).withValues(alpha: 0.30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL EARNINGS',
                  style: TextStyle(
                    color: Color(0xFFFFD740),
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 102900.0),
                  duration: const Duration(milliseconds: 1400),
                  curve: Curves.easeOut,
                  builder: (_, v, child) => Text(
                    '\$${_fmtMoney(v)}',
                    style: const TextStyle(
                      color: Color(0xFFFFD740),
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Lifetime earnings across all DFC deals',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _sectionLabel('EARNINGS HISTORY'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  backgroundColor: Colors.transparent,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.white.withValues(alpha: 0.04),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
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
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= months.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            months[i],
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(
                    earnings.length,
                    (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: earnings[i],
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              const Color(0xFFFFD740).withValues(alpha: 0.3),
                              const Color(0xFFFFD740),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  maxY: 80000,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
    return n.toString();
  }

  String _fmtMoney(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

// ── Data Classes ──────────────────────────────────────────────────────────────
enum _DealStatus { offered, reviewing, signed, declined }

class _CreatorDeal {
  final String eventName;
  final String promoter;
  final DateTime eventDate;
  final String city;
  final String country;
  final int reachRequired;
  final int creatorReach;
  final double revenueShare;
  final _DealStatus status;
  final double projectedEarnings;
  final Color color;

  const _CreatorDeal({
    required this.eventName,
    required this.promoter,
    required this.eventDate,
    required this.city,
    required this.country,
    required this.reachRequired,
    required this.creatorReach,
    required this.revenueShare,
    required this.status,
    required this.projectedEarnings,
    required this.color,
  });
}
