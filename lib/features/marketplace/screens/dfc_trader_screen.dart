import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DFC TRADER — Learn to Trade Fight Stocks
// Educational stock market simulator for the combat sports industry
// Real tickers, simulated portfolio, lessons, and market intelligence
// ═══════════════════════════════════════════════════════════════════════════════

/// Fight stock data model
class _FightStock {
  final String symbol;
  final String name;
  final String sector;
  final double price;
  final double change;
  final double volume;
  final List<double> sparkline;
  final String description;
  final Color accentColor;

  const _FightStock({
    required this.symbol,
    required this.name,
    required this.sector,
    required this.price,
    required this.change,
    required this.volume,
    required this.sparkline,
    required this.description,
    required this.accentColor,
  });

  bool get isUp => change >= 0;
  String get changeStr => '${isUp ? "+" : ""}${change.toStringAsFixed(2)}%';
  String get priceStr => '\$${price.toStringAsFixed(2)}';
  String get volumeStr {
    if (volume >= 1e9) return '${(volume / 1e9).toStringAsFixed(1)}B';
    if (volume >= 1e6) return '${(volume / 1e6).toStringAsFixed(1)}M';
    if (volume >= 1e3) return '${(volume / 1e3).toStringAsFixed(0)}K';
    return volume.toStringAsFixed(0);
  }
}

/// Trading lesson model
class _TradingLesson {
  final String title;
  final String summary;
  final IconData icon;
  final Color color;
  final String difficulty;
  final int durationMin;
  final List<String> topics;

  const _TradingLesson({
    required this.title,
    required this.summary,
    required this.icon,
    required this.color,
    required this.difficulty,
    required this.durationMin,
    required this.topics,
  });
}

/// Portfolio position model
class _PortfolioPosition {
  final String symbol;
  final String name;
  final int shares;
  final double avgCost;
  final double currentPrice;
  final Color color;

  const _PortfolioPosition({
    required this.symbol,
    required this.name,
    required this.shares,
    required this.avgCost,
    required this.currentPrice,
    required this.color,
  });

  double get totalValue => shares * currentPrice;
  double get totalCost => shares * avgCost;
  double get profitLoss => totalValue - totalCost;
  double get profitPct => totalCost > 0 ? (profitLoss / totalCost) * 100 : 0;
  bool get isProfit => profitLoss >= 0;
}

class DfcTraderScreen extends StatefulWidget {
  const DfcTraderScreen({super.key});

  @override
  State<DfcTraderScreen> createState() => _DfcTraderScreenState();
}

class _DfcTraderScreenState extends State<DfcTraderScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseController;
  late AnimationController _tickerController;
  Timer? _priceTimer;
  final _random = math.Random();

  // Simulated balance
  double _balance = 50000.00;
  int _selectedStockIndex = 0;
  String _selectedTimeframe = '1D';

  Duration _cadenceForTimeframe(String timeframe) {
    switch (timeframe) {
      case '1D':
        return const Duration(seconds: 2);
      case '1W':
        return const Duration(seconds: 4);
      case '1M':
        return const Duration(seconds: 6);
      case '3M':
        return const Duration(seconds: 8);
      case '1Y':
        return const Duration(seconds: 12);
      case 'ALL':
        return const Duration(seconds: 16);
      default:
        return const Duration(seconds: 8);
    }
  }

  // Two-hit drum envelope: hard strike then lighter ghost hit.
  double _drumBeat(double t) {
    double peak(double center, double width, double amp) {
      final n = (1 - ((t - center).abs() / width)).clamp(0.0, 1.0);
      return n * amp;
    }

    final primary = peak(0.08, 0.08, 1.0);
    final ghost = peak(0.26, 0.06, 0.65);
    return (primary + ghost).clamp(0.0, 1.0);
  }

  double _volatilityForTimeframe(String timeframe) {
    switch (timeframe) {
      case '1D':
        return 1.00;
      case '1W':
        return 0.70;
      case '1M':
        return 0.45;
      case '3M':
        return 0.30;
      case '1Y':
        return 0.18;
      case 'ALL':
        return 0.12;
      default:
        return 0.50;
    }
  }

  void _startPriceTimer() {
    _priceTimer?.cancel();
    _priceTimer = Timer.periodic(_cadenceForTimeframe(_selectedTimeframe), (_) {
      if (!mounted) return;
      setState(() {
        final vol = _volatilityForTimeframe(_selectedTimeframe);
        for (var i = 0; i < _stocks.length; i++) {
          final stock = _stocks[i];
          final delta = (_random.nextDouble() - 0.48) * 0.5 * vol;
          final newPrice = (stock.price + delta).clamp(
            stock.price * (1 - (0.10 * vol)),
            stock.price * (1 + (0.10 * vol)),
          );
          _stocks[i] = _FightStock(
            symbol: stock.symbol,
            name: stock.name,
            sector: stock.sector,
            price: double.parse(newPrice.toStringAsFixed(2)),
            change: stock.change + ((_random.nextDouble() - 0.48) * 0.1 * vol),
            volume: stock.volume,
            sparkline: [...stock.sparkline.skip(1), newPrice],
            description: stock.description,
            accentColor: stock.accentColor,
          );
        }
      });
    });
  }

  // ── FIGHT STOCKS — Real companies + combat sports entities ────────────────
  final List<_FightStock> _stocks = [
    const _FightStock(
      symbol: 'EDR',
      name: 'Endeavor Group (UFC Owner)',
      sector: 'Entertainment / MMA',
      price: 28.54,
      change: 3.21,
      volume: 8.4e6,
      sparkline: [26.1, 26.5, 27.0, 26.8, 27.4, 27.9, 28.1, 28.3, 28.0, 28.54],
      description:
          'Parent company of UFC, the world\'s largest MMA promotion. Also owns WME talent agency and IMG. Key revenue: PPV, broadcast rights, sponsorships, and live events.',
      accentColor: Color(0xFF00E5FF),
    ),
    const _FightStock(
      symbol: 'ONEW',
      name: 'ONE Championship (Group ONE)',
      sector: 'Combat Sports / Asia',
      price: 12.87,
      change: 5.63,
      volume: 2.1e6,
      sparkline: [11.2, 11.5, 11.8, 12.0, 12.3, 12.1, 12.5, 12.7, 12.9, 12.87],
      description:
          'Asia\'s largest martial arts organisation. Hosts events across MMA, Muay Thai, kickboxing, and submission grappling. Major markets: Thailand, Singapore, Japan, Philippines.',
      accentColor: Color(0xFFFF0080),
    ),
    const _FightStock(
      symbol: 'PFL',
      name: 'Professional Fighters League',
      sector: 'MMA / Season Format',
      price: 8.45,
      change: -2.14,
      volume: 1.3e6,
      sparkline: [9.1, 8.9, 8.7, 8.8, 8.6, 8.5, 8.4, 8.3, 8.5, 8.45],
      description:
          'Season-based MMA league with \$1M prize per weight class. Innovative format combining regular season, playoffs, and championship. Global expansion underway with PFL Europe and PFL Africa.',
      accentColor: Color(0xFF2979FF),
    ),
    const _FightStock(
      symbol: 'BKFC',
      name: 'Bare Knuckle Fighting Championship',
      sector: 'Combat Sports / Niche',
      price: 3.28,
      change: 8.94,
      volume: 890e3,
      sparkline: [2.8, 2.9, 3.0, 2.95, 3.1, 3.15, 3.2, 3.18, 3.25, 3.28],
      description:
          'Fast-growing bare-knuckle boxing promotion. High celebrity crossover appeal. Known for aggressive marketing and viral moments. Expanding to Australia and UK in 2026.',
      accentColor: Color(0xFFFF8800),
    ),
    const _FightStock(
      symbol: 'GLRY',
      name: 'GLORY Kickboxing',
      sector: 'Kickboxing / Europe',
      price: 5.12,
      change: 1.76,
      volume: 650e3,
      sparkline: [4.8, 4.9, 5.0, 4.95, 5.05, 5.1, 5.08, 5.15, 5.1, 5.12],
      description:
          'Premier kickboxing promotion based in Netherlands. Features the world\'s best strikers across multiple weight classes. Strong European and Asian broadcast deals.',
      accentColor: Color(0xFF00E676),
    ),
    const _FightStock(
      symbol: 'EVRL',
      name: 'Everlast Worldwide',
      sector: 'Equipment / Apparel',
      price: 4.12,
      change: -1.83,
      volume: 420e3,
      sparkline: [4.3, 4.25, 4.2, 4.18, 4.15, 4.1, 4.08, 4.12, 4.1, 4.12],
      description:
          'Iconic boxing equipment and apparel brand. 100+ year heritage. Gloves, bags, wraps, and training gear. Partnerships with major promotions and fighters worldwide.',
      accentColor: Color(0xFFFFD700),
    ),
    const _FightStock(
      symbol: 'NKE',
      name: 'Nike Inc',
      sector: 'Sportswear / Global',
      price: 71.83,
      change: 1.12,
      volume: 18.7e6,
      sparkline: [70.5, 70.8, 71.0, 71.2, 71.5, 71.3, 71.6, 71.4, 71.7, 71.83],
      description:
          'World\'s largest sportswear company. Major combat sports sponsorships including boxing (Mendoza, Crawford) and MMA. Growing presence in fight culture through athlete endorsements.',
      accentColor: Color(0xFFFF5722),
    ),
    const _FightStock(
      symbol: 'UAA',
      name: 'Under Armour',
      sector: 'Performance Gear',
      price: 8.17,
      change: -2.41,
      volume: 5.2e6,
      sparkline: [8.5, 8.4, 8.35, 8.3, 8.25, 8.2, 8.18, 8.15, 8.2, 8.17],
      description:
          'Performance apparel and footwear. Sponsors UFC fighters and MMA training camps. Popular among combat athletes for compression gear and training footwear.',
      accentColor: Color(0xFF9C27B0),
    ),
    const _FightStock(
      symbol: 'LULU',
      name: 'Lululemon Athletica',
      sector: 'Premium Athletic Wear',
      price: 321.50,
      change: 2.84,
      volume: 3.1e6,
      sparkline: [
        312.0,
        314.5,
        316.0,
        318.2,
        315.8,
        317.4,
        319.1,
        320.0,
        321.2,
        321.50,
      ],
      description:
          'Premium athleisure brand expanding into combat sports. Growing category of fight-inspired training wear. Popular among female fighters and martial arts practitioners.',
      accentColor: Color(0xFFE91E63),
    ),
    const _FightStock(
      symbol: 'DAZN',
      name: 'DAZN Group (Perform)',
      sector: 'Broadcast / Streaming',
      price: 15.67,
      change: 4.52,
      volume: 1.8e6,
      sparkline: [14.5, 14.8, 15.0, 14.9, 15.2, 15.4, 15.3, 15.5, 15.6, 15.67],
      description:
          'Global sports streaming platform. Major boxing rights holder (Matchroom, Golden Boy). Expanding into MMA and kickboxing. Key disruptor in combat sports broadcasting.',
      accentColor: Color(0xFF00BCD4),
    ),
    const _FightStock(
      symbol: 'TOPRANK',
      name: 'Premier Boxing Promotions',
      sector: 'Boxing Promotion',
      price: 22.30,
      change: 0.89,
      volume: 780e3,
      sparkline: [
        21.5,
        21.8,
        22.0,
        21.9,
        22.1,
        22.0,
        22.2,
        22.15,
        22.25,
        22.30,
      ],
      description:
          'Legendary boxing promotion founded by the veteran promoter. Promotes Marcus Webb, Naoya Inoue, and Connor McKinnon. ESPN broadcast partnership. One of the most storied names in boxing history.',
      accentColor: Color(0xFFF44336),
    ),
    const _FightStock(
      symbol: 'BELLTR',
      name: 'Bellator MMA (PFL)',
      sector: 'MMA / Acquired',
      price: 6.78,
      change: -0.44,
      volume: 540e3,
      sparkline: [7.0, 6.95, 6.9, 6.85, 6.8, 6.82, 6.79, 6.75, 6.8, 6.78],
      description:
          'Former standalone MMA promotion acquired by PFL in 2023. Features established champions and veteran fighters. Champions Summit event series continues the brand legacy.',
      accentColor: Color(0xFF795548),
    ),
  ];

  // ── PORTFOLIO — Simulated demo positions ──────────────────────────────────
  late final List<_PortfolioPosition> _portfolio;

  // ── TRADING LESSONS ───────────────────────────────────────────────────────
  static const _lessons = <_TradingLesson>[
    _TradingLesson(
      title: 'What Are Fight Stocks?',
      summary:
          'Learn how combat sports companies are publicly traded and how their stock prices move with fight results, TV deals, and athlete performance.',
      icon: Icons.sports_mma,
      color: Color(0xFF00E5FF),
      difficulty: 'Beginner',
      durationMin: 5,
      topics: [
        'Stock basics',
        'Combat sports industry',
        'Market cap explained',
        'How UFC/ONE generate revenue',
      ],
    ),
    _TradingLesson(
      title: 'Reading Stock Charts',
      summary:
          'Master candlestick patterns, support/resistance levels, and moving averages. Learn to identify buy and sell signals on price charts.',
      icon: Icons.candlestick_chart,
      color: Color(0xFF00E676),
      difficulty: 'Beginner',
      durationMin: 8,
      topics: [
        'Candlestick basics',
        'Support & resistance',
        'Moving averages',
        'Volume analysis',
      ],
    ),
    _TradingLesson(
      title: 'Event-Driven Trading',
      summary:
          'How fight announcements, PPV numbers, and event results impact stock prices. Time your trades around the fight calendar.',
      icon: Icons.event,
      color: Color(0xFFFF8800),
      difficulty: 'Intermediate',
      durationMin: 10,
      topics: [
        'PPV impact on stock',
        'Fight week volatility',
        'Earnings around events',
        'News trading',
      ],
    ),
    _TradingLesson(
      title: 'Risk Management 101',
      summary:
          'Never risk more than you can afford to lose. Learn position sizing, stop-losses, and portfolio diversification for fight stocks.',
      icon: Icons.shield,
      color: Color(0xFFFF1744),
      difficulty: 'Beginner',
      durationMin: 7,
      topics: [
        'Position sizing',
        'Stop-loss orders',
        'Risk/reward ratio',
        'Diversification',
      ],
    ),
    _TradingLesson(
      title: 'Broadcast Deal Analysis',
      summary:
          'TV and streaming rights drive combat sports valuations. Learn to evaluate broadcast partnerships (ESPN, DAZN, Prime) and their impact on stock prices.',
      icon: Icons.tv,
      color: Color(0xFF2979FF),
      difficulty: 'Intermediate',
      durationMin: 12,
      topics: [
        'Broadcast rights value',
        'Streaming vs PPV',
        'ESPN/DAZN/Prime deals',
        'Revenue projections',
      ],
    ),
    _TradingLesson(
      title: 'Technical Indicators',
      summary:
          'RSI, MACD, Bollinger Bands — the tools professional traders use to time entries and exits. Apply them to fight stock analysis.',
      icon: Icons.analytics,
      color: Color(0xFF9C27B0),
      difficulty: 'Advanced',
      durationMin: 15,
      topics: [
        'RSI (Relative Strength Index)',
        'MACD crossovers',
        'Bollinger Bands',
        'Fibonacci retracements',
      ],
    ),
    _TradingLesson(
      title: 'Building a Fight Portfolio',
      summary:
          'Create a diversified portfolio across promotions, equipment makers, broadcasters, and training brands. Balance growth and value picks.',
      icon: Icons.pie_chart,
      color: Color(0xFFFFD700),
      difficulty: 'Intermediate',
      durationMin: 10,
      topics: [
        'Sector allocation',
        'Growth vs value',
        'Rebalancing',
        'Long-term vs swing trading',
      ],
    ),
    _TradingLesson(
      title: 'Athlete Sponsorship Economics',
      summary:
          'How fighter endorsements, brand deals, and social media influence stock valuations of sponsors and promotions.',
      icon: Icons.star,
      color: Color(0xFFE91E63),
      difficulty: 'Advanced',
      durationMin: 12,
      topics: [
        'Sponsorship valuation',
        'Social media impact',
        'Fighter brand power',
        'Merch & licensing',
      ],
    ),
  ];

  // ── MARKET NEWS ───────────────────────────────────────────────────────────
  static const _marketNews = <(String, String, String, Color)>[
    (
      'UFC Parent Endeavor Reports Record Q4 Revenue',
      'EDR up 3.2% on \$1.8B quarterly earnings — PPV and live event revenue surged 22% year-over-year',
      '2h ago',
      Color(0xFF00E5FF),
    ),
    (
      'ONE Championship Eyes NASDAQ Listing in 2026',
      'Group ONE Holdings explores US IPO, valuation estimated at \$3-4B following Amazon Prime partnership',
      '4h ago',
      Color(0xFFFF0080),
    ),
    (
      'BKFC Australia Expansion Sends Stock Soaring',
      'Bare Knuckle FC announces Perth debut + Brisbane arena series — BKFC shares jump 8.9%',
      '6h ago',
      Color(0xFFFF8800),
    ),
    (
      'DAZN Secures Exclusive Boxing Deal Worth \$2B',
      'Global streaming platform locks in 5-year exclusive boxing rights across 200 territories',
      '8h ago',
      Color(0xFF00BCD4),
    ),
    (
      'Everlast Warns on Q1 Manufacturing Costs',
      'EVRL shares dip 1.8% as raw material costs squeeze margins — new factory in Vietnam delayed',
      '12h ago',
      Color(0xFFFFD700),
    ),
    (
      'PFL Season Format Shake-Up — Fighters React',
      'New playoff structure announced for 2026 season — mixed analyst reactions on revenue impact',
      '1d ago',
      Color(0xFF2979FF),
    ),
    (
      'Nike Signs Record \$50M Combat Sports Deal',
      'NKE expands fight division with multi-athlete sponsorship — Mendoza, Crawford, and UFC stars',
      '1d ago',
      Color(0xFFFF5722),
    ),
    (
      'Lululemon Launches "Fighter" Collection',
      'Combat sports-inspired training wear line sees 40% sell-through in first week — LULU up 2.8%',
      '2d ago',
      Color(0xFFE91E63),
    ),
    (
      'Australian Combat Sports IPO Pipeline Grows',
      'Three AU/NZ fight promotions exploring public listings as industry valuation soars post-pandemic',
      '2d ago',
      Color(0xFF00E676),
    ),
    (
      'GLORY Kickboxing Announces Saudi Arabia Multi-Event Deal',
      'Kingdom-backed series worth \$80M over 3 years — GLORY shares rally 1.7%',
      '3d ago',
      Color(0xFF00E676),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    )..repeat();
    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _portfolio = [
      const _PortfolioPosition(
        symbol: 'EDR',
        name: 'Endeavor (UFC)',
        shares: 200,
        avgCost: 25.40,
        currentPrice: 28.54,
        color: Color(0xFF00E5FF),
      ),
      const _PortfolioPosition(
        symbol: 'ONEW',
        name: 'ONE Championship',
        shares: 500,
        avgCost: 10.20,
        currentPrice: 12.87,
        color: Color(0xFFFF0080),
      ),
      const _PortfolioPosition(
        symbol: 'BKFC',
        name: 'Bare Knuckle FC',
        shares: 1000,
        avgCost: 2.50,
        currentPrice: 3.28,
        color: Color(0xFFFF8800),
      ),
      const _PortfolioPosition(
        symbol: 'DAZN',
        name: 'DAZN Group',
        shares: 150,
        avgCost: 13.80,
        currentPrice: 15.67,
        color: Color(0xFF00BCD4),
      ),
      const _PortfolioPosition(
        symbol: 'NKE',
        name: 'Nike Inc',
        shares: 50,
        avgCost: 68.50,
        currentPrice: 71.83,
        color: Color(0xFFFF5722),
      ),
    ];

    // Simulate live price updates with timeframe-aware heartbeat.
    _startPriceTimer();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _tickerController.dispose();
    _priceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final beat = _drumBeat(_pulseController.value);
        return Scaffold(
          backgroundColor: DesignTokens.bgPrimary,
          body: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.15),
                      radius: 1.0,
                      colors: [
                        const Color(
                          0xFF00E5FF,
                        ).withValues(alpha: 0.05 + (beat * 0.09)),
                        DesignTokens.bgPrimary,
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Transform.scale(
                  scale: 1.0 + (beat * 0.004),
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildTickerStrip(),
                      _buildTabBar(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildMarketTab(),
                            _buildPortfolioTab(),
                            _buildLearnTab(),
                            _buildNewsTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF00E676)],
                  ).createShader(bounds),
                  child: const Text(
                    'DFC TRADER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                Text(
                  'Learn to Trade Fight Stocks',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Balance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF00E676).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '\$${_balance.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Color(0xFF00E676),
                fontWeight: FontWeight.w800,
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LIVE TICKER STRIP
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTickerStrip() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final beat = _drumBeat(_pulseController.value);
        return Transform.translate(
          offset: Offset(0, beat * 0.8),
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.01 + (beat * 0.02)),
              border: Border(
                top: BorderSide(
                  color: const Color(
                    0xFF00E5FF,
                  ).withValues(alpha: 0.06 + (beat * 0.12)),
                ),
                bottom: BorderSide(
                  color: const Color(
                    0xFF00E5FF,
                  ).withValues(alpha: 0.06 + (beat * 0.12)),
                ),
              ),
            ),
            child: AnimatedBuilder(
              animation: _tickerController,
              builder: (context, _) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _stocks.length,
                  itemBuilder: (context, i) {
                    final s = _stocks[i];
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.symbol,
                            style: TextStyle(
                              color: s.accentColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            s.priceStr,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (s.isUp
                                          ? const Color(0xFF00E676)
                                          : const Color(0xFFFF1744))
                                      .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              s.changeStr,
                              style: TextStyle(
                                color: s.isUp
                                    ? const Color(0xFF00E676)
                                    : const Color(0xFFFF1744),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF00E5FF),
        unselectedLabelColor: Colors.white38,
        indicatorColor: const Color(0xFF00E5FF),
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        tabs: const [
          Tab(text: 'MARKET'),
          Tab(text: 'PORTFOLIO'),
          Tab(text: 'LEARN'),
          Tab(text: 'NEWS'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MARKET TAB — Stock list with detail cards
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMarketTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Timeframe selector
        Row(
          children: ['1D', '1W', '1M', '3M', '1Y', 'ALL'].map((tf) {
            final sel = tf == _selectedTimeframe;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedTimeframe = tf);
                  _startPriceTimer();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: sel
                        ? Border.all(
                            color: const Color(
                              0xFF00E5FF,
                            ).withValues(alpha: 0.4),
                          )
                        : null,
                  ),
                  child: Text(
                    tf,
                    style: TextStyle(
                      color: sel ? const Color(0xFF00E5FF) : Colors.white38,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Selected stock detail
        _buildStockDetail(_stocks[_selectedStockIndex]),
        const SizedBox(height: 16),
        // Stock list
        ...List.generate(_stocks.length, _buildStockRow),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildStockDetail(_FightStock stock) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final beat = Curves.easeInOut.transform(_pulseController.value);
        final scale = 1.0 + (beat * 0.015);
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: stock.accentColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: stock.accentColor.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: stock.accentColor.withValues(
                    alpha: 0.12 + (beat * 0.12),
                  ),
                  blurRadius: 14 + (beat * 10),
                  spreadRadius: 1 + (beat * 2),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: stock.accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  stock.symbol,
                  style: TextStyle(
                    color: stock.accentColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      stock.sector,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite,
                        color: stock.isUp
                            ? const Color(0xFF00E676)
                            : const Color(0xFFFF1744),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _selectedTimeframe,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stock.priceStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (stock.isUp
                                  ? const Color(0xFF00E676)
                                  : const Color(0xFFFF1744))
                              .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      stock.changeStr,
                      style: TextStyle(
                        color: stock.isUp
                            ? const Color(0xFF00E676)
                            : const Color(0xFFFF1744),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Sparkline chart
          SizedBox(
            height: 60,
            child: CustomPaint(
              size: const Size(double.infinity, 60),
              painter: _SparklinePainter(
                data: stock.sparkline,
                color: stock.isUp
                    ? const Color(0xFF00E676)
                    : const Color(0xFFFF1744),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            stock.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metricChip('Vol', stock.volumeStr, Colors.white38),
              const SizedBox(width: 8),
              _metricChip(
                'Mkt Cap',
                '${(stock.price * stock.volume / 1e6).toStringAsFixed(0)}M',
                Colors.white38,
              ),
              const SizedBox(width: 8),
              _metricChip(
                'Beat',
                '${_cadenceForTimeframe(_selectedTimeframe).inSeconds}s',
                Colors.white38,
              ),
              const Spacer(),
              _tradeButton('BUY', const Color(0xFF00E676), stock),
              const SizedBox(width: 8),
              _tradeButton('SELL', const Color(0xFFFF1744), stock),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tradeButton(String label, Color color, _FightStock stock) {
    return GestureDetector(
      onTap: () => _showTradeSheet(stock, label == 'BUY'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _metricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockRow(int index) {
    final stock = _stocks[index];
    final selected = index == _selectedStockIndex;
    return GestureDetector(
      onTap: () => setState(() => _selectedStockIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? stock.accentColor.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? Border.all(color: stock.accentColor.withValues(alpha: 0.2))
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                stock.symbol,
                style: TextStyle(
                  color: stock.accentColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            Expanded(
              child: Text(
                stock.name,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: selected ? 0.9 : 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Mini sparkline
            SizedBox(
              width: 40,
              height: 16,
              child: CustomPaint(
                painter: _SparklinePainter(
                  data: stock.sparkline,
                  color: stock.isUp
                      ? const Color(0xFF00E676)
                      : const Color(0xFFFF1744),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final glow = 0.15 + (_pulseController.value * 0.55);
                return Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: stock.isUp
                        ? const Color(0xFF00E676).withValues(alpha: glow)
                        : const Color(0xFFFF1744).withValues(alpha: glow),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (stock.isUp
                                    ? const Color(0xFF00E676)
                                    : const Color(0xFFFF1744))
                                .withValues(alpha: glow),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(
              width: 52,
              child: Text(
                stock.priceStr,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color:
                    (stock.isUp
                            ? const Color(0xFF00E676)
                            : const Color(0xFFFF1744))
                        .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                stock.changeStr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: stock.isUp
                      ? const Color(0xFF00E676)
                      : const Color(0xFFFF1744),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PORTFOLIO TAB
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPortfolioTab() {
    final totalValue = _portfolio.fold<double>(
      0,
      (sum, p) => sum + p.totalValue,
    );
    final totalCost = _portfolio.fold<double>(0, (sum, p) => sum + p.totalCost);
    final totalPL = totalValue - totalCost;
    final totalPLPct = totalCost > 0 ? (totalPL / totalCost) * 100 : 0;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Portfolio summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00E5FF).withValues(alpha: 0.08),
                const Color(0xFF00E676).withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              Text(
                'DEMO PORTFOLIO',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${totalValue.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    totalPL >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: totalPL >= 0
                        ? const Color(0xFF00E676)
                        : const Color(0xFFFF1744),
                    size: 20,
                  ),
                  Text(
                    '\$${totalPL.abs().toStringAsFixed(2)} (${totalPLPct.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      color: totalPL >= 0
                          ? const Color(0xFF00E676)
                          : const Color(0xFFFF1744),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Cash: \$${_balance.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Positions
        Text(
          'POSITIONS',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ..._portfolio.map(_buildPositionCard),
        const SizedBox(height: 16),
        // Disclaimer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF8800).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFFF8800).withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: const Color(0xFFFF8800).withValues(alpha: 0.6),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This is a simulated portfolio for educational purposes only. No real money is at risk. DFC Trader teaches you how stock markets work using combat sports companies.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildPositionCard(_PortfolioPosition pos) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pos.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: pos.color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: pos.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              pos.symbol,
              style: TextStyle(
                color: pos.color,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pos.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${pos.shares} shares @ \$${pos.avgCost.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${pos.totalValue.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                '${pos.isProfit ? "+" : ""}\$${pos.profitLoss.toStringAsFixed(2)} (${pos.profitPct.toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: pos.isProfit
                      ? const Color(0xFF00E676)
                      : const Color(0xFFFF1744),
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEARN TAB
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLearnTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Progress bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFD700).withValues(alpha: 0.08),
                const Color(0xFFFF8800).withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.school, color: Color(0xFFFFD700), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'TRADING ACADEMY',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '3/${_lessons.length} Complete',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 3 / _lessons.length,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700)),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._lessons.asMap().entries.map(
          (e) => _buildLessonCard(e.key, e.value),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildLessonCard(int index, _TradingLesson lesson) {
    final completed = index < 3;
    return GestureDetector(
      onTap: () => _showLessonSheet(lesson, completed),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: lesson.color.withValues(alpha: completed ? 0.04 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: lesson.color.withValues(alpha: completed ? 0.1 : 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: lesson.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                completed ? Icons.check_circle : lesson.icon,
                color: completed ? const Color(0xFF00E676) : lesson.color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: completed ? 0.5 : 0.9,
                      ),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      decoration: completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: lesson.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          lesson.difficulty,
                          style: TextStyle(
                            color: lesson.color,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${lesson.durationMin} min',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NEWS TAB
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildNewsTab() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _marketNews.length + 1,
      itemBuilder: (context, i) {
        if (i == _marketNews.length) return const SizedBox(height: 80);
        final (title, summary, time, color) = _marketNews[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                summary,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                time,
                style: TextStyle(
                  color: color.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TRADE SHEET
  // ═══════════════════════════════════════════════════════════════════════════
  void _showTradeSheet(_FightStock stock, bool isBuy) {
    int shares = 10;
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final total = shares * stock.price;
          final color = isBuy
              ? const Color(0xFF00E676)
              : const Color(0xFFFF1744);
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${isBuy ? "BUY" : "SELL"} ${stock.symbol}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stock.name,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  stock.priceStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 16),
                // Shares selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: shares > 1
                          ? () => setSheetState(() => shares--)
                          : null,
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$shares',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setSheetState(() => shares++),
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: \$${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        if (isBuy) {
                          _balance -= total;
                        } else {
                          _balance += total;
                        }
                      });
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${isBuy ? "Bought" : "Sold"} $shares shares of ${stock.symbol} @ ${stock.priceStr}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: color.withValues(alpha: 0.8),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '${isBuy ? "BUY" : "SELL"} ${stock.symbol} — \$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Simulated trade — no real money involved',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LESSON SHEET
  // ═══════════════════════════════════════════════════════════════════════════
  void _showLessonSheet(_TradingLesson lesson, bool completed) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: lesson.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(lesson.icon, color: lesson.color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                lesson.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: lesson.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      lesson.difficulty,
                      style: TextStyle(
                        color: lesson.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.timer_outlined, color: Colors.white38, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${lesson.durationMin} min read',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                lesson.summary,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'TOPICS COVERED',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...lesson.topics.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: lesson.color,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          completed
                              ? 'Lesson already completed!'
                              : 'Lesson started: ${lesson.title}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: lesson.color.withValues(alpha: 0.8),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: completed
                        ? Colors.white.withValues(alpha: 0.1)
                        : lesson.color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    completed ? 'REVIEW LESSON' : 'START LESSON',
                    style: TextStyle(
                      color: completed ? Colors.white54 : Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SPARKLINE PAINTER
// ═══════════════════════════════════════════════════════════════════════════════
class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  const _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final minVal = data.reduce(math.min);
    final maxVal = data.reduce(math.max);
    final range = maxVal - minVal;
    if (range == 0) return;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minVal) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.data != data || old.color != color;
}
