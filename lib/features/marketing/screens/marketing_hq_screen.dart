import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/dfc_card.dart';
import '../../../shared/widgets/dfc_cosmetic_widgets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MARKETING HQ — NASA Mission-Control Grade Command Center
/// Animated telemetry · Real-time sparklines · Orbital metrics · Holo cards
/// ═══════════════════════════════════════════════════════════════════════════

class MarketingHQScreen extends StatefulWidget {
  const MarketingHQScreen({super.key});

  @override
  State<MarketingHQScreen> createState() => _MarketingHQScreenState();
}

class _MarketingHQScreenState extends State<MarketingHQScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseController;
  late AnimationController _sweepController;
  late AnimationController _tickerController;
  late Animation<double> _pulseAnim;

  // Live telemetry counters
  int _impressions = 0;
  int _clicks = 0;
  double _convRate = 0;
  int _revenue = 0;
  final int _targetImpressions = 42847;
  final int _targetClicks = 3128;
  final double _targetConvRate = 7.4;
  final int _targetRevenue = 12480;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _sweepController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _tickerController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _tickerController.addListener(() {
      setState(() {
        _impressions = (_targetImpressions * _tickerController.value).round();
        _clicks = (_targetClicks * _tickerController.value).round();
        _convRate = _targetConvRate * _tickerController.value;
        _revenue = (_targetRevenue * _tickerController.value).round();
      });
    });
    _tickerController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _sweepController.dispose();
    _tickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020810),
      body: Stack(
        children: [
          // NASA grid background
          const _NasaGridBackground(),
          const DFCCosmicBackground(particleCount: 30),
          SafeArea(
            child: Column(
              children: [
                _buildMissionHeader(),
                _buildTelemetryBar(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCampaignsTab(),
                      _buildABTestsTab(),
                      _buildAffiliatesTab(),
                      _buildPlannerTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 4),
              // Status beacon
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DesignTokens.neonGreen.withValues(
                      alpha: _pulseAnim.value,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DesignTokens.neonGreen.withValues(
                          alpha: _pulseAnim.value * 0.6,
                        ),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'SYSTEMS NOMINAL',
                style: TextStyle(
                  color: DesignTokens.neonGreen.withValues(alpha: 0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              const DFCLogo(size: DFCLogoSize.small),
            ],
          ),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                DesignTokens.neonCyan,
                DesignTokens.neonMagenta,
                DesignTokens.neonCyan,
              ],
            ).createShader(bounds),
            child: const Text(
              'MARKETING HQ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'MISSION CONTROL · CAMPAIGN TELEMETRY · REAL-TIME ANALYTICS',
            style: TextStyle(
              color: DesignTokens.neonCyan.withValues(alpha: 0.35),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// ── NASA-style animated telemetry bar with counting numbers ──
  Widget _buildTelemetryBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          _telemetryStat(
            value: _formatNumber(_impressions),
            label: 'IMPRESSIONS',
            color: DesignTokens.neonCyan,
            sparkData: [0.3, 0.5, 0.4, 0.7, 0.6, 0.8, 0.9, 0.75, 0.85, 1.0],
          ),
          _telemetryDivider(),
          _telemetryStat(
            value: _formatNumber(_clicks),
            label: 'CLICKS',
            color: DesignTokens.neonGreen,
            sparkData: [0.2, 0.3, 0.5, 0.4, 0.6, 0.7, 0.55, 0.8, 0.9, 0.85],
          ),
          _telemetryDivider(),
          _telemetryStat(
            value: '${_convRate.toStringAsFixed(1)}%',
            label: 'CONV RATE',
            color: DesignTokens.neonGold,
            sparkData: [0.5, 0.6, 0.55, 0.7, 0.65, 0.8, 0.75, 0.7, 0.85, 0.74],
          ),
          _telemetryDivider(),
          _telemetryStat(
            value: '\$${_formatNumber(_revenue)}',
            label: 'REVENUE',
            color: DesignTokens.neonMagenta,
            sparkData: [0.1, 0.2, 0.3, 0.35, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0],
          ),
        ],
      ),
    );
  }

  Widget _telemetryStat({
    required String value,
    required String label,
    required Color color,
    required List<double> sparkData,
  }) {
    return Expanded(
      child: Column(
        children: [
          // Mini sparkline
          SizedBox(
            height: 18,
            child: CustomPaint(
              size: const Size(double.infinity, 18),
              painter: _SparklinePainter(data: sparkData, color: color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 7,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _telemetryDivider() {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withValues(alpha: 0.06),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              DesignTokens.neonMagenta.withValues(alpha: 0.2),
              DesignTokens.neonCyan.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: DesignTokens.neonMagenta.withValues(alpha: 0.35),
            width: 0.5,
          ),
        ),
        labelColor: DesignTokens.neonMagenta,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.35),
        labelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
        dividerHeight: 0,
        tabs: const [
          Tab(text: 'CAMPAIGNS'),
          Tab(text: 'A/B TESTS'),
          Tab(text: 'AFFILIATES'),
          Tab(text: 'PLANNER'),
        ],
      ),
    );
  }

  // ── CAMPAIGNS TAB — Mission Control Grade ──

  Widget _buildCampaignsTab() {
    final campaigns = _mockCampaigns();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        _nasaSectionHeader(
          'ACTIVE CAMPAIGNS',
          Icons.rocket_launch,
          DesignTokens.neonCyan,
        ),
        const SizedBox(height: 8),
        ...campaigns.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _missionCampaignCard(c),
          ),
        ),
        const SizedBox(height: 18),
        _nasaSectionHeader(
          'PERFORMANCE TRAJECTORY',
          Icons.show_chart,
          DesignTokens.neonGreen,
        ),
        const SizedBox(height: 8),
        _buildAnimatedPerformanceChart(),
        const SizedBox(height: 18),
        _nasaSectionHeader(
          'CHANNEL TELEMETRY',
          Icons.satellite_alt,
          DesignTokens.neonMagenta,
        ),
        const SizedBox(height: 8),
        _buildChannelTelemetry(),
      ],
    );
  }

  Widget _nasaSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) => Icon(
            icon,
            color: color.withValues(alpha: 0.5 + _pulseAnim.value * 0.5),
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 0.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.4), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _missionCampaignCard(_Campaign c) {
    return DFCCard.glass(
      accent: c.color,
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${c.name} — Mission Details Loading...')),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Pulsing status beacon
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.statusColor.withValues(alpha: _pulseAnim.value),
                    boxShadow: [
                      BoxShadow(
                        color: c.statusColor.withValues(
                          alpha: _pulseAnim.value * 0.5,
                        ),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: c.statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: c.statusColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  c.status,
                  style: TextStyle(
                    color: c.statusColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                c.platform,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            c.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            c.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Metrics row with mini sparklines
          Row(
            children: [
              _miniMetricWithSpark('Reach', c.reach, c.color, [
                0.3,
                0.5,
                0.7,
                0.6,
                0.9,
              ]),
              _miniMetricWithSpark('Clicks', c.clicks, c.color, [
                0.2,
                0.4,
                0.6,
                0.8,
                0.7,
              ]),
              _miniMetricWithSpark('Conv', c.conversions, c.color, [
                0.4,
                0.5,
                0.3,
                0.7,
                0.8,
              ]),
              _miniMetricWithSpark('Cost', c.cost, c.color, [
                0.1,
                0.2,
                0.35,
                0.5,
                0.6,
              ]),
            ],
          ),
          const SizedBox(height: 10),
          // Animated progress bar with glow
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: c.progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.04),
                  valueColor: AlwaysStoppedAnimation<Color>(c.color),
                  minHeight: 4,
                ),
              ),
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Positioned(
                  left:
                      c.progress * (MediaQuery.of(context).size.width - 80) - 2,
                  top: 0,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(
                        alpha: _pulseAnim.value * 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: c.color.withValues(
                            alpha: _pulseAnim.value * 0.6,
                          ),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(c.progress * 100).round()}% COMPLETE',
                style: TextStyle(
                  color: c.color.withValues(alpha: 0.6),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'T+${(c.progress * 30).round()} DAYS',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniMetricWithSpark(
    String label,
    String value,
    Color color,
    List<double> spark,
  ) {
    return Expanded(
      child: Column(
        children: [
          SizedBox(
            height: 12,
            child: CustomPaint(
              size: const Size(double.infinity, 12),
              painter: _SparklinePainter(
                data: spark,
                color: color.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedPerformanceChart() {
    final data = [
      ('Mon', 0.4, DesignTokens.neonCyan),
      ('Tue', 0.7, DesignTokens.neonCyan),
      ('Wed', 0.55, DesignTokens.neonGreen),
      ('Thu', 0.85, DesignTokens.neonGreen),
      ('Fri', 0.65, DesignTokens.neonGold),
      ('Sat', 0.9, DesignTokens.neonGold),
      ('Sun', 0.5, DesignTokens.neonMagenta),
    ];
    return DFCCard.glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'WEEKLY ENGAGEMENT TRAJECTORY',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'LIVE',
                    style: TextStyle(
                      color: DesignTokens.neonGreen.withValues(
                        alpha: _pulseAnim.value,
                      ),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((d) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${(d.$2 * 100).round()}%',
                          style: TextStyle(
                            color: d.$3.withValues(alpha: 0.7),
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedBuilder(
                          animation: _tickerController,
                          builder: (_, child) {
                            final h =
                                90 *
                                d.$2 *
                                math.min(1.0, _tickerController.value * 1.5);
                            return Container(
                              height: h,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    d.$3.withValues(alpha: 0.5),
                                    d.$3.withValues(alpha: 0.15),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: d.$3.withValues(alpha: 0.4),
                                  width: 0.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: d.$3.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, -2),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          d.$1,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelTelemetry() {
    final channels = [
      (
        'Instagram',
        Icons.camera_alt,
        0.82,
        DesignTokens.neonMagenta,
        '34.2K reach',
      ),
      (
        'YouTube',
        Icons.play_circle_outline,
        0.71,
        DesignTokens.neonRed,
        '12.8K views',
      ),
      ('TikTok', Icons.music_note, 0.93, DesignTokens.neonCyan, '89.1K views'),
      ('Email', Icons.email, 0.56, DesignTokens.neonGreen, '2.1K opens'),
      ('FightWire', Icons.feed, 0.88, DesignTokens.neonGold, '4.7K reads'),
    ];
    return DFCCard.glass(
      accent: DesignTokens.neonMagenta,
      child: Column(
        children: channels.map((ch) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(ch.$2, color: ch.$4, size: 16),
                const SizedBox(width: 8),
                Text(
                  ch.$1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  ch.$5,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 60, child: _buildMiniGauge(ch.$3, ch.$4)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMiniGauge(double value, Color color) {
    return AnimatedBuilder(
      animation: _tickerController,
      builder: (_, child) {
        final v = value * math.min(1.0, _tickerController.value * 1.5);
        return Stack(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: v,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── A/B TESTS TAB — Experiment Control ──

  Widget _buildABTestsTab() {
    final tests = _mockABTests();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        _nasaSectionHeader(
          'RUNNING EXPERIMENTS',
          Icons.science,
          DesignTokens.neonGreen,
        ),
        const SizedBox(height: 8),
        ...tests.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _experimentCard(t),
          ),
        ),
        const SizedBox(height: 16),
        _nasaSectionHeader(
          'CONFIDENCE MATRIX',
          Icons.grid_on,
          DesignTokens.neonCyan,
        ),
        const SizedBox(height: 8),
        _buildConfidenceMatrix(tests),
      ],
    );
  }

  Widget _experimentCard(_ABTest test) {
    final winColor = test.winning == 'A'
        ? DesignTokens.neonCyan
        : DesignTokens.neonGreen;
    return DFCCard.glass(
      accent: winColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Icon(
                  Icons.science_outlined,
                  color: DesignTokens.neonMagenta.withValues(
                    alpha: 0.5 + _pulseAnim.value * 0.5,
                  ),
                  size: 16,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                test.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: DesignTokens.neonGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: DesignTokens.neonGreen.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  test.status,
                  style: const TextStyle(
                    color: DesignTokens.neonGreen,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _variantBar(
                  'A',
                  test.variantA,
                  test.rateA,
                  DesignTokens.neonCyan,
                  test.winning == 'A',
                ),
              ),
              const SizedBox(width: 10),
              // VS divider
              Column(
                children: [
                  Text(
                    'VS',
                    style: TextStyle(
                      color: DesignTokens.neonMagenta.withValues(alpha: 0.5),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _variantBar(
                  'B',
                  test.variantB,
                  test.rateB,
                  DesignTokens.neonGreen,
                  test.winning == 'B',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Confidence gauge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${test.sampleSize} SAMPLES',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: _buildMiniGauge(
                      test.confidence / 100.0,
                      DesignTokens.neonGold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${test.confidence}% CONF',
                    style: TextStyle(
                      color: DesignTokens.neonGold.withValues(alpha: 0.8),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceMatrix(List<_ABTest> tests) {
    return DFCCard.glass(
      child: Column(
        children: tests.map((t) {
          final diff = ((t.rateA - t.rateB).abs() * 100).toStringAsFixed(1);
          final winner = t.winning == 'A' ? t.variantA : t.variantB;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    t.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    winner,
                    style: const TextStyle(
                      color: DesignTokens.neonGreen,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '+${diff}pp',
                  style: const TextStyle(
                    color: DesignTokens.neonGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _variantBar(
    String label,
    String name,
    double rate,
    Color color,
    bool isWinning,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isWinning ? 0.1 : 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: isWinning ? 0.4 : 0.1),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Variant $label',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isWinning) ...[
                const Spacer(),
                const Icon(
                  Icons.emoji_events,
                  color: DesignTokens.neonGold,
                  size: 12,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(rate * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'conversion',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // ── AFFILIATES TAB — Partner Network ──

  Widget _buildAffiliatesTab() {
    final affiliates = _mockAffiliates();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        _nasaSectionHeader(
          'TOP AFFILIATES',
          Icons.people,
          DesignTokens.neonGold,
        ),
        const SizedBox(height: 8),
        ...affiliates.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _affiliateRankCard(e.value, e.key + 1),
          ),
        ),
        const SizedBox(height: 16),
        _nasaSectionHeader(
          'NETWORK OVERVIEW',
          Icons.hub,
          DesignTokens.neonCyan,
        ),
        const SizedBox(height: 8),
        _buildNetworkOverview(),
        const SizedBox(height: 16),
        _nasaSectionHeader(
          'AFFILIATE PROGRAM',
          Icons.card_giftcard,
          DesignTokens.neonGold,
        ),
        const SizedBox(height: 8),
        DFCCard.glass(
          accent: DesignTokens.neonGold,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Earn with DFC',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Share your referral link. Earn 15% commission on every subscription, pass, and ticket sale.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _affPerk('15%', 'Commission'),
                  const SizedBox(width: 10),
                  _affPerk('30d', 'Cookie'),
                  const SizedBox(width: 10),
                  _affPerk('\$0', 'To Join'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _affiliateRankCard(_Affiliate a, int rank) {
    final rankColors = [
      DesignTokens.neonGold,
      DesignTokens.neonCyan,
      DesignTokens.neonGreen,
    ];
    final color = rank <= 3 ? rankColors[rank - 1] : Colors.white54;
    return DFCCard.glass(
      accent: color,
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
              color: color.withValues(alpha: 0.1),
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                a.name[0],
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${a.referrals} referrals',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Mini bar
                    SizedBox(
                      width: 40,
                      child: _buildMiniGauge(a.referrals / 50.0, color),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                a.earnings,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'earned',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkOverview() {
    return DFCCard.glass(
      child: Row(
        children: [
          _networkStat('146', 'ACTIVE', DesignTokens.neonGreen),
          _networkStat('23', 'PENDING', DesignTokens.neonAmber),
          _networkStat('\$2.4K', 'THIS MONTH', DesignTokens.neonGold),
          _networkStat('12.8%', 'AVG CONV', DesignTokens.neonCyan),
        ],
      ),
    );
  }

  Widget _networkStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 7,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _affPerk(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: DesignTokens.neonGold.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: DesignTokens.neonGold.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: DesignTokens.neonGold,
                fontSize: 16,
                fontWeight: FontWeight.w900,
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
        ),
      ),
    );
  }

  // ── PLANNER TAB — Orbital Schedule Command ──

  Widget _buildPlannerTab() {
    final schedule = _mockSchedule();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        _nasaSectionHeader(
          'ENGAGEMENT HEATMAP',
          Icons.grid_on,
          DesignTokens.neonMagenta,
        ),
        const SizedBox(height: 4),
        Text(
          'Optimal posting windows based on audience activity telemetry.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 10),
        _buildHeatGrid(),
        const SizedBox(height: 18),
        _nasaSectionHeader('LAUNCH QUEUE', Icons.rocket, DesignTokens.neonCyan),
        const SizedBox(height: 8),
        ...schedule.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _missionScheduleCard(e.value, e.key),
          ),
        ),
      ],
    );
  }

  Widget _buildHeatGrid() {
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final hours = ['6am', '9am', '12pm', '3pm', '6pm', '9pm'];
    final heat = [
      [0.2, 0.5, 0.7, 0.4, 0.8, 0.3],
      [0.3, 0.6, 0.8, 0.5, 0.9, 0.4],
      [0.1, 0.4, 0.6, 0.7, 0.7, 0.5],
      [0.4, 0.7, 0.9, 0.6, 0.8, 0.6],
      [0.5, 0.8, 0.7, 0.8, 1.0, 0.7],
      [0.3, 0.5, 0.4, 0.9, 0.9, 0.8],
      [0.2, 0.3, 0.3, 0.7, 0.8, 0.6],
    ];

    return DFCCard.glass(
      accent: DesignTokens.neonMagenta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 28),
              ...hours.map(
                (h) => Expanded(
                  child: Center(
                    child: Text(
                      h,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.25),
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...List.generate(7, (dayIdx) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    child: Text(
                      days[dayIdx],
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...List.generate(6, (hourIdx) {
                    final val = heat[dayIdx][hourIdx];
                    final isHot = val >= 0.8;
                    return Expanded(
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, child) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          height: 20,
                          decoration: BoxDecoration(
                            color: DesignTokens.neonMagenta.withValues(
                              alpha: val * 0.5,
                            ),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: isHot
                                ? [
                                    BoxShadow(
                                      color: DesignTokens.neonMagenta
                                          .withValues(
                                            alpha: val * 0.2 * _pulseAnim.value,
                                          ),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isHot
                              ? Center(
                                  child: Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(
                                        alpha: _pulseAnim.value * 0.6,
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'LOW',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              ...List.generate(5, (i) {
                return Container(
                  width: 12,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonMagenta.withValues(
                      alpha: (i + 1) * 0.1,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
              const SizedBox(width: 4),
              Text(
                'HIGH',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _missionScheduleCard(_ScheduledPost s, int index) {
    return DFCCard.glass(
      accent: s.color,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // T-minus countdown style
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: s.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: s.color.withValues(alpha: 0.25)),
            ),
            child: Icon(s.icon, color: s.color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  s.channel,
                  style: TextStyle(
                    color: s.color,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                s.time,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                s.date == 'Today'
                    ? 'T-0'
                    : s.date == 'Tomorrow'
                    ? 'T-1'
                    : s.date,
                style: TextStyle(
                  color: s.date == 'Today'
                      ? DesignTokens.neonGreen
                      : Colors.white.withValues(alpha: 0.3),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── MOCK DATA ──

  List<_Campaign> _mockCampaigns() => [
    const _Campaign(
      name: 'DFC Launch 2026',
      description:
          'Grand launch campaign across all channels — drive app downloads and brand awareness.',
      status: 'ACTIVE',
      statusColor: DesignTokens.neonGreen,
      platform: 'Multi-channel',
      reach: '12.4K',
      clicks: '892',
      conversions: '156',
      cost: '\$420',
      progress: 0.67,
      color: DesignTokens.neonCyan,
    ),
    const _Campaign(
      name: 'Fighter Pro Push',
      description:
          'Targeted campaign to convert free users to Fighter Pro subscriptions.',
      status: 'ACTIVE',
      statusColor: DesignTokens.neonGreen,
      platform: 'In-App + Email',
      reach: '3.8K',
      clicks: '445',
      conversions: '89',
      cost: '\$180',
      progress: 0.45,
      color: DesignTokens.neonGreen,
    ),
    const _Campaign(
      name: 'Fighters for Kids Awareness',
      description:
          'Charity campaign driving donations and fight pass purchases for sick children.',
      status: 'SCHEDULED',
      statusColor: DesignTokens.neonAmber,
      platform: 'Social + FightWire',
      reach: '—',
      clicks: '—',
      conversions: '—',
      cost: '\$0',
      progress: 0.1,
      color: Color(0xFFFF6B9D),
    ),
  ];

  List<_ABTest> _mockABTests() => [
    const _ABTest(
      name: 'CTA Button Color',
      variantA: '"Get Started" cyan',
      variantB: '"Join Now" green',
      rateA: 0.043,
      rateB: 0.067,
      winning: 'B',
      sampleSize: 2400,
      confidence: 94,
      status: 'RUNNING',
    ),
    const _ABTest(
      name: 'Pricing Display',
      variantA: '\$9.99/month',
      variantB: '\$0.33/day',
      rateA: 0.052,
      rateB: 0.071,
      winning: 'B',
      sampleSize: 1800,
      confidence: 89,
      status: 'RUNNING',
    ),
    const _ABTest(
      name: 'Hero Headline',
      variantA: '"Train Like a Champion"',
      variantB: '"We All Got Some Fight"',
      rateA: 0.061,
      rateB: 0.058,
      winning: 'A',
      sampleSize: 3200,
      confidence: 72,
      status: 'RUNNING',
    ),
  ];

  List<_Affiliate> _mockAffiliates() => [
    const _Affiliate(name: 'Coach Ray Mitchell', referrals: 47, earnings: '\$312'),
    const _Affiliate(
      name: 'Golden Dragon Muay Thai',
      referrals: 31,
      earnings: '\$208',
    ),
    const _Affiliate(name: 'The Boxing Blog', referrals: 28, earnings: '\$186'),
    const _Affiliate(name: 'MMA Weekly Pod', referrals: 22, earnings: '\$152'),
    const _Affiliate(
      name: 'Jake Morrison Performance',
      referrals: 18,
      earnings: '\$124',
    ),
  ];

  List<_ScheduledPost> _mockSchedule() => [
    const _ScheduledPost(
      title: 'Fight Night Promo',
      channel: 'FightWire',
      time: '6:00 PM',
      date: 'Today',
      icon: Icons.feed,
      color: DesignTokens.neonCyan,
    ),
    const _ScheduledPost(
      title: 'Fighter Pro Launch',
      channel: 'Email Campaign',
      time: '9:00 AM',
      date: 'Tomorrow',
      icon: Icons.email,
      color: DesignTokens.neonGreen,
    ),
    const _ScheduledPost(
      title: 'Kids Campaign Video',
      channel: 'Social Media',
      time: '12:00 PM',
      date: 'Feb 12',
      icon: Icons.videocam,
      color: DesignTokens.neonMagenta,
    ),
    const _ScheduledPost(
      title: 'Weekly Newsletter',
      channel: 'Email',
      time: '7:00 AM',
      date: 'Feb 14',
      icon: Icons.newspaper,
      color: DesignTokens.neonAmber,
    ),
  ];
}

class _Campaign {
  final String name,
      description,
      status,
      platform,
      reach,
      clicks,
      conversions,
      cost;
  final Color statusColor, color;
  final double progress;
  const _Campaign({
    required this.name,
    required this.description,
    required this.status,
    required this.statusColor,
    required this.platform,
    required this.reach,
    required this.clicks,
    required this.conversions,
    required this.cost,
    required this.progress,
    required this.color,
  });
}

class _ABTest {
  final String name, variantA, variantB, winning, status;
  final double rateA, rateB;
  final int sampleSize, confidence;
  const _ABTest({
    required this.name,
    required this.variantA,
    required this.variantB,
    required this.rateA,
    required this.rateB,
    required this.winning,
    required this.sampleSize,
    required this.confidence,
    required this.status,
  });
}

class _Affiliate {
  final String name, earnings;
  final int referrals;
  const _Affiliate({
    required this.name,
    required this.referrals,
    required this.earnings,
  });
}

class _ScheduledPost {
  final String title, channel, time, date;
  final IconData icon;
  final Color color;
  const _ScheduledPost({
    required this.title,
    required this.channel,
    required this.time,
    required this.date,
    required this.icon,
    required this.color,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// NASA-grade custom painters
// ═══════════════════════════════════════════════════════════════════════════

/// Sparkline painter — mini line chart with gradient fill
class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final dx = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = dx * i;
      final y = size.height - (data[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    // Gradient fill beneath the line
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.2), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // End dot
    final dotPaint = Paint()..color = color;
    final lastX = dx * (data.length - 1);
    final lastY = size.height - (data.last * size.height);
    canvas.drawCircle(Offset(lastX, lastY), 2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.data != data || old.color != color;
}

/// NASA-style grid background with subtle scan lines and crosshairs
class _NasaGridBackground extends StatelessWidget {
  const _NasaGridBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.infinite, painter: _NasaGridPainter());
  }
}

class _NasaGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = DesignTokens.neonCyan.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;

    // Horizontal grid lines
    const spacing = 40.0;
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Vertical grid lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Subtle diagonal scan-line overlay
    final scanPaint = Paint()
      ..color = DesignTokens.neonMagenta.withValues(alpha: 0.008)
      ..strokeWidth = 0.3;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
