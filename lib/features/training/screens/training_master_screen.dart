import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/image_assets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// TRAINING COMMAND — 2030 Holographic Space-Age Edition
/// Glassmorphic panels · Animated pie charts · Fight stocks ticker
/// Daily→Weekly→Monthly rollup · Smart device constellation
/// ═══════════════════════════════════════════════════════════════════════════
class TrainingMasterScreen extends StatefulWidget {
  const TrainingMasterScreen({super.key});

  @override
  State<TrainingMasterScreen> createState() => _TrainingMasterScreenState();
}

class _TrainingMasterScreenState extends State<TrainingMasterScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──
  late AnimationController _bgController;
  late AnimationController _pulseController;
  late AnimationController _graphController;
  late AnimationController _tickerController;
  late AnimationController _ringController;

  // ── RPE sliders ──
  double _strikingRPE = 7.0;
  double _grapplingRPE = 6.5;
  double _conditioningRPE = 8.0;
  double _recoveryRPE = 5.0;

  // ── Fight stock carousel ──
  late PageController _stockCarouselController;

  final String _currentPhase = 'BUILD';
  final int _daysToFight = 42;
  int _selectedTimeframe = 0; // 0=Daily, 1=Weekly, 2=Monthly

  // ── LIVE data from Firestore ──
  bool _isLoadingData = true;
  List<Map<String, dynamic>> _recentSessions = [];

  // Pie chart data — starts empty, populated from Firestore
  late List<_PieSlice> _dailyPieData;
  late List<_PieSlice> _weeklyPieData;
  late List<_PieSlice> _monthlyPieData;

  // Weekly bar chart — computed from real session data
  late List<List<double>> _weeklyBars;

  List<_PieSlice> get _activePieData {
    switch (_selectedTimeframe) {
      case 1:
        return _weeklyPieData;
      case 2:
        return _monthlyPieData;
      default:
        return _dailyPieData;
    }
  }

  final _fightStocks = [
    const _FightStock('EDR', 'Endeavor (UFC)', 28.54, 3.2, [
      25.1,
      26.0,
      25.8,
      27.2,
      27.9,
      28.1,
      28.54,
    ], 'EDR'),
    const _FightStock('EVRL', 'Everlast', 4.12, -1.8, [
      4.40,
      4.35,
      4.28,
      4.20,
      4.18,
      4.15,
      4.12,
    ], 'EVRLF'),
    const _FightStock('ONON', 'On Holding', 52.30, 5.6, [
      48.0,
      49.2,
      50.1,
      50.8,
      51.4,
      52.0,
      52.30,
    ], 'ONON'),
    const _FightStock('UAA', 'Under Armour', 8.17, -2.4, [
      8.60,
      8.50,
      8.42,
      8.35,
      8.28,
      8.20,
      8.17,
    ], 'UAA'),
    const _FightStock('NKE', 'Nike', 71.83, 1.1, [
      70.2,
      70.8,
      71.0,
      71.3,
      71.5,
      71.7,
      71.83,
    ], 'NKE'),
    const _FightStock('PTON', 'Peloton', 9.45, -4.3, [
      10.2,
      10.0,
      9.85,
      9.70,
      9.60,
      9.50,
      9.45,
    ], 'PTON'),
    const _FightStock('LULU', 'Lululemon', 321.50, 2.8, [
      308.0,
      312.0,
      315.0,
      318.0,
      319.5,
      320.0,
      321.50,
    ], 'LULU'),
    const _FightStock('SGC', 'Bellator/SGC', 1.24, -6.1, [
      1.40,
      1.38,
      1.35,
      1.30,
      1.28,
      1.25,
      1.24,
    ], 'SGC'),
  ];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat();

    _graphController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..forward();

    _tickerController = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    )..repeat();

    _ringController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _stockCarouselController = PageController(viewportFraction: 0.42);

    // Initialize with default values, then try loading real data
    _dailyPieData = _defaultPieData();
    _weeklyPieData = _defaultWeeklyPieData();
    _monthlyPieData = _defaultMonthlyPieData();
    _weeklyBars = _defaultWeeklyBars();
    _recentSessions = _defaultRecentSessions();

    _loadTrainingData();
  }

  /// Default pie data shown before Firestore data loads (today)
  List<_PieSlice> _defaultPieData() => [
    const _PieSlice('Striking', 0.38, Colors.red),
    const _PieSlice('Grappling', 0.27, Colors.blue),
    const _PieSlice('Conditioning', 0.22, Colors.orange),
    const _PieSlice('Recovery', 0.13, AppTheme.neonGreen),
  ];

  /// Default weekly pie data
  List<_PieSlice> _defaultWeeklyPieData() => [
    const _PieSlice('Striking', 0.33, Colors.red),
    const _PieSlice('Grappling', 0.28, Colors.blue),
    const _PieSlice('Conditioning', 0.24, Colors.orange),
    const _PieSlice('Recovery', 0.15, AppTheme.neonGreen),
  ];

  /// Default monthly pie data
  List<_PieSlice> _defaultMonthlyPieData() => [
    const _PieSlice('Striking', 0.31, Colors.red),
    const _PieSlice('Grappling', 0.30, Colors.blue),
    const _PieSlice('Conditioning', 0.25, Colors.orange),
    const _PieSlice('Recovery', 0.14, AppTheme.neonGreen),
  ];

  /// Default weekly bar data with realistic training minutes
  List<List<double>> _defaultWeeklyBars() => [
    [45, 30, 20], // Mon — heavy striking + grappling
    [20, 50, 25], // Tue — grappling-focused
    [35, 20, 40], // Wed — conditioning day
    [50, 35, 15], // Thu — hard sparring day
    [25, 45, 30], // Fri — grappling rounds
    [40, 25, 50], // Sat — full camp session
    [0, 0, 15], // Sun — active recovery only
  ];

  /// Default recent sessions for demo mode
  List<Map<String, dynamic>> _defaultRecentSessions() {
    final now = DateTime.now();
    return [
      {
        'strikingMinutes': 45,
        'grapplingMinutes': 20,
        'conditioningMinutes': 15,
        'totalMinutes': 80,
        'rpe': 8.5,
        'date': Timestamp.fromDate(now.subtract(const Duration(hours: 3))),
      },
      {
        'strikingMinutes': 15,
        'grapplingMinutes': 50,
        'conditioningMinutes': 20,
        'totalMinutes': 85,
        'rpe': 7.5,
        'date': Timestamp.fromDate(
          now.subtract(const Duration(days: 1, hours: 2)),
        ),
      },
      {
        'strikingMinutes': 30,
        'grapplingMinutes': 30,
        'conditioningMinutes': 40,
        'totalMinutes': 100,
        'rpe': 9.0,
        'date': Timestamp.fromDate(
          now.subtract(const Duration(days: 2, hours: 5)),
        ),
      },
      {
        'strikingMinutes': 50,
        'grapplingMinutes': 10,
        'conditioningMinutes': 25,
        'totalMinutes': 85,
        'rpe': 7.0,
        'date': Timestamp.fromDate(
          now.subtract(const Duration(days: 3, hours: 1)),
        ),
      },
      {
        'strikingMinutes': 20,
        'grapplingMinutes': 45,
        'conditioningMinutes': 30,
        'totalMinutes': 95,
        'rpe': 8.0,
        'date': Timestamp.fromDate(
          now.subtract(const Duration(days: 4, hours: 4)),
        ),
      },
    ];
  }

  /// Load REAL training data from Firestore, fall back to demo data
  Future<void> _loadTrainingData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // No auth — use demo data already set in initState
        _graphController.forward(from: 0);
        if (mounted) setState(() => _isLoadingData = false);
        return;
      }

      final uid = user.uid;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(
        Duration(days: todayStart.weekday - 1),
      );
      final monthStart = DateTime(now.year, now.month);

      // Fetch last 30 days of training sessions for this user
      final snapshot = await FirebaseFirestore.instance
          .collection('training_sessions')
          .where('userId', isEqualTo: uid)
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(
              monthStart.subtract(const Duration(days: 1)),
            ),
          )
          .orderBy('date', descending: true)
          .limit(100)
          .get();

      final sessions = snapshot.docs.map((d) => d.data()).toList();

      if (sessions.isNotEmpty) {
        // ── Compute PIE data from real sessions ──
        _dailyPieData = _computePieData(sessions, todayStart, now);
        _weeklyPieData = _computePieData(sessions, weekStart, now);
        _monthlyPieData = _computePieData(sessions, monthStart, now);

        // ── Compute WEEKLY BAR chart from real sessions ──
        _weeklyBars = _computeWeeklyBars(sessions, weekStart);

        // ── Recent sessions (last 5) ──
        _recentSessions = sessions.take(5).toList();
      }
      // If no sessions found, demo data from initState remains

      // Animate the graph in
      _graphController.forward(from: 0);
    } catch (_) {
      // On error, keep demo defaults — works offline
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  /// Compute pie percentages from real training session minutes
  List<_PieSlice> _computePieData(
    List<Map<String, dynamic>> sessions,
    DateTime from,
    DateTime to,
  ) {
    double striking = 0, grappling = 0, conditioning = 0;
    for (final s in sessions) {
      final date = (s['date'] as Timestamp?)?.toDate();
      if (date == null || date.isBefore(from) || date.isAfter(to)) continue;
      striking += (s['strikingMinutes'] ?? 0).toDouble();
      grappling += (s['grapplingMinutes'] ?? 0).toDouble();
      conditioning += (s['conditioningMinutes'] ?? 0).toDouble();
    }
    final total = striking + grappling + conditioning;
    if (total == 0) return _defaultPieData();

    // Recovery is estimated rest time per session (proportional)
    final sessionCount = sessions.where((s) {
      final date = (s['date'] as Timestamp?)?.toDate();
      return date != null && !date.isBefore(from) && !date.isAfter(to);
    }).length;
    final recoveryMin = sessionCount * 10.0; // ~10 min cooldown per session
    final grandTotal = total + recoveryMin;

    return [
      _PieSlice('Striking', striking / grandTotal, Colors.red),
      _PieSlice('Grappling', grappling / grandTotal, Colors.blue),
      _PieSlice('Conditioning', conditioning / grandTotal, Colors.orange),
      _PieSlice('Recovery', recoveryMin / grandTotal, AppTheme.neonGreen),
    ];
  }

  /// Compute 7 days of stacked bar data [striking, grappling, conditioning]
  List<List<double>> _computeWeeklyBars(
    List<Map<String, dynamic>> sessions,
    DateTime weekStart,
  ) {
    final bars = List.generate(7, (_) => [0.0, 0.0, 0.0]);
    for (final s in sessions) {
      final date = (s['date'] as Timestamp?)?.toDate();
      if (date == null) continue;
      final dayIndex = date.difference(weekStart).inDays;
      if (dayIndex < 0 || dayIndex > 6) continue;
      bars[dayIndex][0] += (s['strikingMinutes'] ?? 0).toDouble();
      bars[dayIndex][1] += (s['grapplingMinutes'] ?? 0).toDouble();
      bars[dayIndex][2] += (s['conditioningMinutes'] ?? 0).toDouble();
    }
    return bars;
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pulseController.dispose();
    _graphController.dispose();
    _tickerController.dispose();
    _ringController.dispose();
    _stockCarouselController.dispose();
    super.dispose();
  }

  void _switchTimeframe(int index) {
    setState(() => _selectedTimeframe = index);
    _graphController.forward(from: 0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    try {
      return _buildContent(context);
    } catch (e, st) {
      debugPrint('TrainingMasterScreen build error: $e\n$st');
      return Scaffold(
        backgroundColor: const Color(0xFF030810),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Training screen error:\n$e',
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030810),
      body: Stack(
        children: [
          // ── Cosmic background ──
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) => CustomPaint(
              painter: _TrainingCosmicPainter(animation: _bgController.value),
              size: Size.infinite,
            ),
          ),
          // ── Content ──
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Hero image banner ──
                      Container(
                        height: 160,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: const DecorationImage(
                            image: AssetImage(
                              ImageAssets.trainingPlaceholder,
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                const Color(0xFF0A0E1A).withValues(alpha: 0.9),
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.bottomLeft,
                          child: const Text(
                            'FIGHT CAMP COMMAND CENTER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                      _buildCampStatusHolo(),
                      const SizedBox(height: 20),
                      _buildFightStocksCarousel(),
                      const SizedBox(height: 20),
                      _buildTimeframeSelector(),
                      const SizedBox(height: 14),
                      _buildPieAndBarsRow(),
                      const SizedBox(height: 20),
                      _buildTrainingInputsHolo(),
                      const SizedBox(height: 20),
                      _buildWeeklyLoadHolo(),
                      const SizedBox(height: 20),
                      _buildRecentSessionsHolo(),
                      const SizedBox(height: 20),
                      _buildSmartDeviceConstellation(),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          // ── Genie AI Coach ──
        ],
      ),
      floatingActionButton: _buildHoloFAB(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          // Animated neon icon
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final pulse =
                  math.sin(_pulseController.value * math.pi * 2) * 0.3;
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.neonCyan.withValues(alpha: 0.2 + pulse * 0.1),
                      AppTheme.neonMagenta.withValues(
                        alpha: 0.15 + pulse * 0.08,
                      ),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.neonCyan.withValues(
                      alpha: 0.3 + pulse * 0.15,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonCyan.withValues(
                        alpha: 0.15 + pulse * 0.1,
                      ),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: AppTheme.neonCyan,
                  size: 20,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Training',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'Holographic Command',
                style: TextStyle(color: AppTheme.neonCyan, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
      actions: [
        _glassIconButton(Icons.calendar_month, () => context.push('/planner')),
        _glassIconButton(Icons.settings, () => context.push('/settings')),
      ],
    );
  }

  Widget _glassIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CAMP STATUS — Holographic Card
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCampStatusHolo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _ringController]),
      builder: (context, _) {
        final pulse = math.sin(_pulseController.value * math.pi * 2);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.06),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.neonCyan.withValues(alpha: 0.15 + pulse * 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonCyan.withValues(alpha: 0.06 + pulse * 0.03),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.neonGreen,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.neonGreen.withValues(
                                    alpha: 0.6,
                                  ),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'CAMP ACTIVE',
                            style: TextStyle(
                              color: AppTheme.neonGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'UFC 313 — Las Vegas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Main Event · Light Heavyweight Title',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  // Days counter with ring
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(70, 70),
                          painter: _CountdownRingPainter(
                            progress: _daysToFight / 90,
                            color: AppTheme.neonCyan,
                            animation: _ringController.value,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_daysToFight',
                              style: const TextStyle(
                                color: AppTheme.neonCyan,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'DAYS',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Phase progress with holographic connectors
              Row(
                children: [
                  _buildPhaseNode(
                    'BUILD',
                    _currentPhase == 'BUILD',
                    AppTheme.neonGreen,
                  ),
                  _buildPhaseConnectorHolo(true),
                  _buildPhaseNode('CUT', _currentPhase == 'CUT', Colors.orange),
                  _buildPhaseConnectorHolo(false),
                  _buildPhaseNode(
                    'TAPER',
                    _currentPhase == 'TAPER',
                    AppTheme.neonMagenta,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhaseNode(String label, bool active, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? color.withValues(alpha: 0.2) : Colors.transparent,
              border: Border.all(
                color: active ? color : Colors.white.withValues(alpha: 0.15),
                width: active ? 2 : 1,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              active ? Icons.check : Icons.circle,
              color: active ? color : Colors.white24,
              size: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.white30,
              fontSize: 9,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseConnectorHolo(bool completed) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          gradient: completed
              ? LinearGradient(
                  colors: [
                    AppTheme.neonGreen.withValues(alpha: 0.6),
                    AppTheme.neonCyan.withValues(alpha: 0.3),
                  ],
                )
              : null,
          color: completed ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(1),
          boxShadow: completed
              ? [
                  BoxShadow(
                    color: AppTheme.neonGreen.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIGHT STOCKS CAROUSEL
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFightStocksCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              const Icon(Icons.show_chart, color: AppTheme.neonCyan, size: 16),
              const SizedBox(width: 6),
              const Text(
                'Fight Stocks',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'MARKET',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              const Text(
                'LIVE',
                style: TextStyle(
                  color: AppTheme.neonGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  final o =
                      (0.4 +
                              math.sin(_pulseController.value * math.pi * 2) *
                                  0.6)
                          .clamp(0.0, 1.0);
                  return Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppTheme.neonGreen.withValues(alpha: o),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            controller: _stockCarouselController,
            scrollDirection: Axis.horizontal,
            itemCount: _fightStocks.length,
            itemBuilder: (context, i) {
              final stock = _fightStocks[i];
              final isUp = stock.change >= 0;
              final changeColor = isUp ? AppTheme.neonGreen : Colors.red;
              return GestureDetector(
                onTap: () async {
                  final url = Uri.parse(stock.yahooUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: changeColor.withValues(alpha: 0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: changeColor.withValues(alpha: 0.05),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            stock.symbol,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: changeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${isUp ? "+" : ""}${stock.change.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: changeColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stock.name,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${stock.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      // Mini sparkline
                      SizedBox(
                        height: 24,
                        child: CustomPaint(
                          size: const Size(double.infinity, 24),
                          painter: _MiniSparklinePainter(
                            data: stock.sparkline,
                            color: changeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TIMEFRAME SELECTOR (Daily / Weekly / Monthly)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTimeframeSelector() {
    const labels = ['Daily', 'Weekly', 'Monthly'];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final active = _selectedTimeframe == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => _switchTimeframe(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.neonCyan.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: active
                      ? Border.all(
                          color: AppTheme.neonCyan.withValues(alpha: 0.3),
                        )
                      : null,
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppTheme.neonCyan.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: active ? AppTheme.neonCyan : Colors.white38,
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PIE CHART + MINI BARS ROW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPieAndBarsRow() {
    return AnimatedBuilder(
      animation: _graphController,
      builder: (context, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pie chart
            Expanded(flex: 5, child: _buildPieChartCard()),
            const SizedBox(width: 12),
            // Stats breakdown
            Expanded(flex: 4, child: _buildPieBreakdown()),
          ],
        );
      },
    );
  }

  Widget _buildPieChartCard() {
    const labels = ['Today', 'This Week', 'This Month'];
    return _glassCard(
      child: Column(
        children: [
          Text(
            labels[_selectedTimeframe],
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 130,
            width: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(130, 130),
                  painter: _HoloPieChartPainter(
                    slices: _activePieData,
                    animation: _graphController.value,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(_activePieData.fold<double>(0, (s, e) => s + e.value) * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Total',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 9,
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

  Widget _buildPieBreakdown() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Breakdown',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._activePieData.map((slice) {
            final pct = (slice.value * 100 * _graphController.value).round();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: slice.color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: slice.color.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            slice.label,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$pct%',
                        style: TextStyle(
                          color: slice.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: slice.value * _graphController.value,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation(slice.color),
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TRAINING INPUTS — Holographic RPE Sliders
  // ═══════════════════════════════════════════════════════════════════════════
  bool _isSavingRPE = false;

  Widget _buildTrainingInputsHolo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.edit_note, 'Today\'s Training RPE'),
        const SizedBox(height: 10),
        _glassCard(
          child: Column(
            children: [
              _buildHoloRPE(
                'Striking',
                Icons.sports_mma,
                Colors.red,
                _strikingRPE,
                (v) => setState(() => _strikingRPE = v),
              ),
              const SizedBox(height: 14),
              _buildHoloRPE(
                'Grappling',
                Icons.sports_kabaddi,
                Colors.blue,
                _grapplingRPE,
                (v) => setState(() => _grapplingRPE = v),
              ),
              const SizedBox(height: 14),
              _buildHoloRPE(
                'Conditioning',
                Icons.directions_run,
                Colors.orange,
                _conditioningRPE,
                (v) => setState(() => _conditioningRPE = v),
              ),
              const SizedBox(height: 14),
              _buildHoloRPE(
                'Recovery',
                Icons.self_improvement,
                AppTheme.neonGreen,
                _recoveryRPE,
                (v) => setState(() => _recoveryRPE = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSavingRPE ? null : _saveRPEData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonCyan.withValues(alpha: 0.15),
                    foregroundColor: AppTheme.neonCyan,
                    side: BorderSide(
                      color: AppTheme.neonCyan.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isSavingRPE
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_alt, size: 16),
                  label: Text(
                    _isSavingRPE ? 'SAVING...' : 'SAVE TODAY\'S RPE',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveRPEData() async {
    setState(() => _isSavingRPE = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'demo_user';
      final now = DateTime.now();
      final avgRPE =
          (_strikingRPE + _grapplingRPE + _conditioningRPE + _recoveryRPE) / 4;

      await FirebaseFirestore.instance.collection('health_metrics').add({
        'userId': uid,
        'recordedAt': Timestamp.fromDate(now),
        'source': 'manual',
        'perceivedExertion': avgRPE.round(),
        'trainingIntensity': avgRPE.round(),
        'notes':
            'RPE — Striking: ${_strikingRPE.toStringAsFixed(1)}, '
            'Grappling: ${_grapplingRPE.toStringAsFixed(1)}, '
            'Conditioning: ${_conditioningRPE.toStringAsFixed(1)}, '
            'Recovery: ${_recoveryRPE.toStringAsFixed(1)}',
        'createdAt': Timestamp.fromDate(now),
        'isVerified': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'RPE saved — avg ${avgRPE.toStringAsFixed(1)} across 4 disciplines',
            ),
            backgroundColor: AppTheme.neonCyan,
          ),
        );
        // Refresh charts with new data
        _loadTrainingData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingRPE = false);
    }
  }

  Widget _buildHoloRPE(
    String label,
    IconData icon,
    Color color,
    double value,
    ValueChanged<double> onChanged,
  ) {
    final rpeColor = value >= 8
        ? Colors.red
        : value >= 6
        ? Colors.orange
        : AppTheme.neonGreen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: rpeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: rpeColor.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(
                    color: rpeColor.withValues(alpha: 0.15),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                'RPE ${value.toStringAsFixed(1)}',
                style: TextStyle(
                  color: rpeColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.12),
            thumbColor: Colors.white,
            overlayColor: color.withValues(alpha: 0.15),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value,
            min: 1,
            max: 10,
            divisions: 18,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WEEKLY LOAD — Holographic Bars
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildWeeklyLoadHolo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.bar_chart, 'Weekly Training Load'),
        const SizedBox(height: 10),
        _glassCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendDot('Striking', Colors.red),
                  const SizedBox(width: 12),
                  _legendDot('Grappling', Colors.blue),
                  const SizedBox(width: 12),
                  _legendDot('Conditioning', Colors.orange),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: _graphController,
                builder: (context, _) {
                  return SizedBox(
                    height: 110,
                    child: CustomPaint(
                      size: const Size(double.infinity, 110),
                      painter: _HoloBarChartPainter(
                        data: _weeklyBars,
                        animation: _graphController.value,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                    .map(
                      (d) => Text(
                        d,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 9,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              // Overtraining warning — glass style (dynamic)
              Builder(
                builder: (_) {
                  // Find the day with highest total load
                  double maxLoad = 0;
                  int maxDay = 0;
                  const dayNames = [
                    'Monday',
                    'Tuesday',
                    'Wednesday',
                    'Thursday',
                    'Friday',
                    'Saturday',
                    'Sunday',
                  ];
                  for (int i = 0; i < _weeklyBars.length; i++) {
                    final dayTotal = _weeklyBars[i].fold<double>(
                      0,
                      (a, b) => a + b,
                    );
                    if (dayTotal > maxLoad) {
                      maxLoad = dayTotal;
                      maxDay = i;
                    }
                  }
                  final totalWeek = _weeklyBars.fold<double>(
                    0,
                    (runningTotal, day) =>
                        runningTotal + day.fold<double>(0, (a, b) => a + b),
                  );
                  final riskLevel = maxLoad > 120
                      ? 'HIGH'
                      : maxLoad > 60
                      ? 'MODERATE'
                      : totalWeek == 0
                      ? 'LOW — No data'
                      : 'LOW';
                  final riskColor = maxLoad > 120
                      ? Colors.red
                      : maxLoad > 60
                      ? Colors.orange
                      : AppTheme.neonGreen;
                  final riskMsg = totalWeek == 0
                      ? 'Log sessions to track load'
                      : '${dayNames[maxDay]} load: ${maxLoad.toInt()} min';

                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: riskColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          totalWeek == 0
                              ? Icons.info_outline
                              : Icons.warning_amber,
                          color: riskColor.withValues(alpha: 0.8),
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Overtraining Risk: $riskLevel',
                                style: TextStyle(
                                  color: riskColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                riskMsg,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECENT SESSIONS — Glass tiles
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRecentSessionsHolo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionHeader(Icons.history, 'Recent Sessions'),
            GestureDetector(
              onTap: () => context.push('/fight-camp-tools'),
              child: Text(
                'View All',
                style: TextStyle(
                  color: AppTheme.neonCyan.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_isLoadingData)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.neonCyan.withValues(alpha: 0.5),
                ),
              ),
            ),
          )
        else if (_recentSessions.isEmpty) ...[
          _buildSessionTile(
            'No sessions yet',
            'Tap + Log Training to start',
            Icons.add_circle_outline,
            AppTheme.neonCyan,
            '',
            '',
          ),
        ] else
          ..._recentSessions.map((session) {
            final strikingMin = (session['strikingMinutes'] ?? 0) as int;
            final grapplingMin = (session['grapplingMinutes'] ?? 0) as int;
            final condMin = (session['conditioningMinutes'] ?? 0) as int;
            final totalMin =
                session['totalMinutes'] ??
                (strikingMin + grapplingMin + condMin);
            final rpe = (session['rpe'] ?? 0).toDouble();
            final date =
                (session['date'] as Timestamp?)?.toDate() ?? DateTime.now();

            // Determine primary discipline for icon/color
            String title;
            IconData icon;
            Color color;
            if (strikingMin >= grapplingMin && strikingMin >= condMin) {
              title = strikingMin > 0 ? 'Striking Session' : 'Training Session';
              icon = Icons.sports_mma;
              color = Colors.red;
            } else if (grapplingMin >= condMin) {
              title = 'Grappling Session';
              icon = Icons.sports_kabaddi;
              color = Colors.blue;
            } else {
              title = 'Conditioning Session';
              icon = Icons.directions_run;
              color = Colors.orange;
            }

            // Format time
            final now = DateTime.now();
            final diff = now.difference(date);
            String timeStr;
            if (diff.inMinutes < 60) {
              timeStr = '${diff.inMinutes}m ago';
            } else if (diff.inHours < 24) {
              timeStr = '${diff.inHours}h ago';
            } else if (diff.inDays == 1) {
              timeStr = 'Yesterday';
            } else if (diff.inDays < 7) {
              timeStr = '${diff.inDays} days ago';
            } else {
              timeStr = '${date.day}/${date.month}/${date.year}';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildSessionTile(
                title,
                timeStr,
                icon,
                color,
                rpe > 0 ? 'RPE ${rpe.toStringAsFixed(1)}' : '',
                '$totalMin min',
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSessionTile(
    String title,
    String time,
    IconData icon,
    Color color,
    String rpe,
    String duration,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.20)),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
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
                rpe,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              Text(
                duration,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // SMART DEVICE CONSTELLATION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSmartDeviceConstellation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.devices_other, 'Connected Devices'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildDeviceHolo(
                'Apple Watch',
                Icons.watch,
                AppTheme.neonMagenta,
                true,
                'Synced 2m ago',
                '♡ 72 BPM',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDeviceHolo(
                'Garmin',
                Icons.sports_score,
                Colors.blue,
                false,
                'Tap to connect',
                '--',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildDeviceHolo(
                'Google Fit',
                Icons.fitness_center,
                AppTheme.neonGreen,
                true,
                'Active',
                '12.4K steps',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDeviceHolo(
                'BT Scale',
                Icons.monitor_weight,
                AppTheme.neonCyan,
                true,
                'Ready',
                '84.0 kg / 185.2 lbs',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildDeviceHolo(
                'Whoop',
                Icons.monitor_heart,
                Colors.teal,
                true,
                'Streaming',
                '92% Recovery',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDeviceHolo(
                'Oura Ring',
                Icons.blur_circular,
                Colors.purple,
                false,
                'Pairing…',
                '--',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeviceHolo(
    String name,
    IconData icon,
    Color color,
    bool connected,
    String status,
    String metric,
  ) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final pulse = connected
            ? math.sin(_pulseController.value * math.pi * 2) * 0.3
            : 0.0;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: connected
                  ? color.withValues(alpha: 0.2 + pulse * 0.1)
                  : Colors.white.withValues(alpha: 0.06),
            ),
            boxShadow: connected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.05 + pulse * 0.03),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const Spacer(),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: connected
                          ? AppTheme.neonGreen
                          : Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      boxShadow: connected
                          ? [
                              BoxShadow(
                                color: AppTheme.neonGreen.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 9,
                ),
              ),
              if (connected) ...[
                const SizedBox(height: 6),
                Text(
                  metric,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HOLOGRAPHIC FAB
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHoloFAB() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final pulse = math.sin(_pulseController.value * math.pi * 2);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonCyan.withValues(alpha: 0.25 + pulse * 0.1),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            heroTag: 'training_log_fab',
            onPressed: _showLogTraining,
            backgroundColor: AppTheme.neonCyan,
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text(
              'Log Training',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _glassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }

  Widget _sectionHeader(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.neonCyan, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  bool _isSavingSession = false;

  void _showLogTraining() {
    final strikingCtrl = TextEditingController();
    final grapplingCtrl = TextEditingController();
    final conditioningCtrl = TextEditingController();
    final sparringCtrl = TextEditingController();
    final restingHRCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    double sessionRPE = 7.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1628),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.neonCyan.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Log Training Session',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter your session details below',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            // ── Minutes per discipline ──
                            _logMinuteField(
                              strikingCtrl,
                              'Striking Minutes',
                              Icons.sports_mma,
                              Colors.red,
                            ),
                            const SizedBox(height: 10),
                            _logMinuteField(
                              grapplingCtrl,
                              'Grappling Minutes',
                              Icons.sports_kabaddi,
                              Colors.blue,
                            ),
                            const SizedBox(height: 10),
                            _logMinuteField(
                              conditioningCtrl,
                              'Conditioning Minutes',
                              Icons.directions_run,
                              Colors.orange,
                            ),
                            const SizedBox(height: 10),
                            _logMinuteField(
                              sparringCtrl,
                              'Sparring Rounds',
                              Icons.sports_gymnastics,
                              AppTheme.neonMagenta,
                            ),
                            const SizedBox(height: 10),
                            _logMinuteField(
                              restingHRCtrl,
                              'Resting Heart Rate (BPM)',
                              Icons.favorite_border,
                              Colors.pink,
                            ),
                            const SizedBox(height: 16),

                            // ── Session RPE Slider ──
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.speed,
                                        color: AppTheme.neonCyan,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Session Intensity (RPE)',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              (sessionRPE >= 8
                                                      ? Colors.red
                                                      : sessionRPE >= 6
                                                      ? Colors.orange
                                                      : AppTheme.neonGreen)
                                                  .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'RPE ${sessionRPE.toStringAsFixed(1)}',
                                          style: TextStyle(
                                            color: sessionRPE >= 8
                                                ? Colors.red
                                                : sessionRPE >= 6
                                                ? Colors.orange
                                                : AppTheme.neonGreen,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Slider(
                                    value: sessionRPE,
                                    min: 1,
                                    max: 10,
                                    divisions: 18,
                                    // activeThumbColor: AppTheme.neonCyan, // Removed: not a valid parameter
                                    inactiveColor: AppTheme.neonCyan.withValues(
                                      alpha: 0.12,
                                    ),
                                    onChanged: (v) =>
                                        setSheetState(() => sessionRPE = v),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Easy',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        'Moderate',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        'Max Effort',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ── Notes ──
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: TextField(
                                controller: notesCtrl,
                                maxLines: 3,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Session notes (optional)',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  prefixIcon: Icon(
                                    Icons.edit_note,
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── Save Button ──
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isSavingSession
                                    ? null
                                    : () => _saveTrainingSession(
                                        ctx,
                                        strikingCtrl,
                                        grapplingCtrl,
                                        conditioningCtrl,
                                        sparringCtrl,
                                        restingHRCtrl,
                                        sessionRPE,
                                        notesCtrl,
                                      ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.neonCyan,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: _isSavingSession
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : const Icon(Icons.save),
                                label: Text(
                                  _isSavingSession
                                      ? 'SAVING...'
                                      : 'SAVE SESSION',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _logMinuteField(
    TextEditingController ctrl,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Text(
            label.contains('Rounds')
                ? 'rds'
                : label.contains('BPM')
                ? 'bpm'
                : 'min',
            style: TextStyle(
              color: color.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTrainingSession(
    BuildContext ctx,
    TextEditingController strikingCtrl,
    TextEditingController grapplingCtrl,
    TextEditingController conditioningCtrl,
    TextEditingController sparringCtrl,
    TextEditingController restingHRCtrl,
    double sessionRPE,
    TextEditingController notesCtrl,
  ) async {
    setState(() => _isSavingSession = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'demo_user';
      final now = DateTime.now();
      final strikingMin = int.tryParse(strikingCtrl.text);
      final grapplingMin = int.tryParse(grapplingCtrl.text);
      final conditioningMin = int.tryParse(conditioningCtrl.text);
      final sparringRds = int.tryParse(sparringCtrl.text);
      final restingHR = double.tryParse(restingHRCtrl.text);
      final totalMin =
          (strikingMin ?? 0) + (grapplingMin ?? 0) + (conditioningMin ?? 0);

      if (totalMin == 0 && (sparringRds ?? 0) == 0) {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Enter at least one training field'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isSavingSession = false);
        return;
      }

      final data = <String, dynamic>{
        'userId': uid,
        'recordedAt': Timestamp.fromDate(now),
        'source': 'manual',
        'strikingMinutes': strikingMin,
        'grapplingMinutes': grapplingMin,
        'conditioningMinutes': conditioningMin,
        'sparringRounds': sparringRds,
        'perceivedExertion': sessionRPE.round(),
        'trainingIntensity': sessionRPE.round(),
        'restingHeartRate': restingHR,
        'notes': notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
        'createdAt': Timestamp.fromDate(now),
        'isVerified': false,
      };

      await FirebaseFirestore.instance.collection('health_metrics').add(data);

      // Also log to training_sessions for Cloud Function readiness analysis
      await FirebaseFirestore.instance.collection('training_sessions').add({
        'userId': uid,
        'date': Timestamp.fromDate(now),
        'strikingMinutes': strikingMin ?? 0,
        'grapplingMinutes': grapplingMin ?? 0,
        'conditioningMinutes': conditioningMin ?? 0,
        'sparringRounds': sparringRds ?? 0,
        'totalMinutes': totalMin,
        'rpe': sessionRPE,
        'sRPE': sessionRPE * totalMin, // Session RPE × duration
        'restingHR': restingHR,
        'notes': notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
        'createdAt': Timestamp.fromDate(now),
      });

      if (ctx.mounted) {
        Navigator.of(ctx).pop();
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.black, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Session saved — $totalMin min, RPE ${sessionRPE.toStringAsFixed(1)}',
                ),
              ],
            ),
            backgroundColor: AppTheme.neonCyan,
          ),
        );
        // Refresh charts with new session data
        _loadTrainingData();
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingSession = false);
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═════════════════════════════════════════════════════════════════════════════
class _PieSlice {
  final String label;
  final double value;
  final Color color;
  const _PieSlice(this.label, this.value, this.color);
}

class _FightStock {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final List<double> sparkline;
  final String yahooTicker;
  const _FightStock(
    this.symbol,
    this.name,
    this.price,
    this.change,
    this.sparkline,
    this.yahooTicker,
  );

  String get yahooUrl => 'https://finance.yahoo.com/quote/$yahooTicker';
}

// ═════════════════════════════════════════════════════════════════════════════
// COSMIC BACKGROUND PAINTER (aurora + stars + nebula)
// ═════════════════════════════════════════════════════════════════════════════
class _TrainingCosmicPainter extends CustomPainter {
  final double animation;
  late final List<_Star> _stars;

  _TrainingCosmicPainter({required this.animation}) {
    final rng = math.Random(99);
    _stars = List.generate(
      120,
      (i) => _Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: rng.nextDouble() * 1.6 + 0.3,
        brightness: rng.nextDouble() * 0.6 + 0.15,
        twinkles: rng.nextDouble() > 0.78,
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Deep space
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0.2, -0.4),
          radius: 1.8,
          colors: [Color(0xFF0C1A32), Color(0xFF060E1C), Color(0xFF030810)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Aurora ribbons
    for (int i = 0; i < 3; i++) {
      final aPath = Path();
      final yBase = size.height * 0.05 + i * 50;
      final xPhase = animation * math.pi * 2 + i * 0.8;
      aPath.moveTo(0, yBase + 60);
      for (double x = 0; x <= size.width; x += 10) {
        final f = x / size.width;
        aPath.lineTo(
          x,
          yBase +
              math.sin(f * math.pi * 3 + xPhase) * 40 +
              math.sin(f * math.pi * 6 + xPhase * 1.3) * 15,
        );
      }
      aPath.lineTo(size.width, yBase + 100);
      aPath.lineTo(0, yBase + 100);
      aPath.close();
      final aColors = [
        [AppTheme.neonCyan, AppTheme.neonGreen],
        [AppTheme.neonMagenta, AppTheme.neonCyan],
        [const Color(0xFF6C63FF), AppTheme.neonMagenta],
      ];
      canvas.drawPath(
        aPath,
        Paint()
          ..shader = LinearGradient(
            colors: [
              aColors[i][0].withValues(alpha: 0.02),
              aColors[i][1].withValues(alpha: 0.03),
            ],
          ).createShader(Rect.fromLTWH(0, yBase, size.width, 100))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
      );
    }

    // Nebula
    for (final n in [
      [0.20, 0.30, AppTheme.neonCyan, 0.04],
      [0.75, 0.50, AppTheme.neonMagenta, 0.03],
      [0.50, 0.80, AppTheme.neonGreen, 0.025],
    ]) {
      canvas.drawCircle(
        Offset((n[0] as double) * size.width, (n[1] as double) * size.height),
        size.width * 0.28,
        Paint()
          ..color = (n[2] as Color).withValues(
            alpha: (n[3] as double).clamp(0.0, 1.0),
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70),
      );
    }

    // Stars
    for (final s in _stars) {
      final t = s.twinkles
          ? (math.sin(animation * math.pi * 4 + s.x * 22 + s.y * 14) * 0.4 +
                0.6)
          : 1.0;
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size,
        Paint()
          ..color = Colors.white.withValues(
            alpha: (s.brightness * t).clamp(0.0, 1.0),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrainingCosmicPainter old) =>
      old.animation != animation;
}

class _Star {
  final double x, y, size, brightness;
  final bool twinkles;
  const _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.brightness,
    required this.twinkles,
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// COUNTDOWN RING PAINTER
// ═════════════════════════════════════════════════════════════════════════════
class _CountdownRingPainter extends CustomPainter {
  final double progress, animation;
  final Color color;

  _CountdownRingPainter({
    required this.progress,
    required this.color,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Glow
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * math.pi * 2,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * math.pi * 2,
      false,
      Paint()
        ..shader = SweepGradient(
          colors: [
            color.withValues(alpha: 0.4),
            color,
            Colors.white.withValues(alpha: 0.8),
          ],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Orbiting dot
    final dotAngle = animation * math.pi * 2 - math.pi / 2;
    canvas.drawCircle(
      Offset(
        center.dx + math.cos(dotAngle) * radius,
        center.dy + math.sin(dotAngle) * radius,
      ),
      2.5,
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter old) =>
      old.animation != animation;
}

// ═════════════════════════════════════════════════════════════════════════════
// HOLOGRAPHIC PIE CHART PAINTER
// ═════════════════════════════════════════════════════════════════════════════
class _HoloPieChartPainter extends CustomPainter {
  final List<_PieSlice> slices;
  final double animation;

  _HoloPieChartPainter({required this.slices, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    const gap = 0.03;
    var startAngle = -math.pi / 2;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16,
    );

    for (final slice in slices) {
      final sweep = (slice.value * math.pi * 2 - gap) * animation;
      if (sweep <= 0) {
        startAngle += slice.value * math.pi * 2;
        continue;
      }

      // Glow
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = slice.color.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Main arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = slice.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round,
      );

      // Inner glow
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 2),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );

      startAngle += slice.value * math.pi * 2;
    }
  }

  @override
  bool shouldRepaint(covariant _HoloPieChartPainter old) =>
      old.animation != animation;
}

// ═════════════════════════════════════════════════════════════════════════════
// MINI SPARKLINE (for fight stocks)
// ═════════════════════════════════════════════════════════════════════════════
class _MiniSparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _MiniSparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final maxV = data.reduce(math.max);
    final minV = data.reduce(math.min);
    final range = maxV - minV;
    if (range == 0) return;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y =
          size.height -
          ((data[i] - minV) / range) * size.height * 0.8 -
          size.height * 0.1;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final px = ((i - 1) / (data.length - 1)) * size.width;
        final py =
            size.height -
            ((data[i - 1] - minV) / range) * size.height * 0.8 -
            size.height * 0.1;
        final cx = (px + x) / 2;
        path.cubicTo(cx, py, cx, y, x, y);
        fillPath.cubicTo(cx, py, cx, y, x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Fill
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.20), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniSparklinePainter old) => false;
}

// ═════════════════════════════════════════════════════════════════════════════
// HOLOGRAPHIC BAR CHART PAINTER
// ═════════════════════════════════════════════════════════════════════════════
class _HoloBarChartPainter extends CustomPainter {
  final List<List<double>>
  data; // Each inner = [striking, grappling, conditioning]
  final double animation;

  _HoloBarChartPainter({required this.data, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    const maxTotal = 200.0;
    final barWidth = size.width / data.length - 10;
    final colors = [Colors.red, Colors.blue, Colors.orange];

    // Grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Overtraining threshold
    final warnY = size.height * 0.25;
    canvas.drawLine(
      Offset(0, warnY),
      Offset(size.width, warnY),
      Paint()
        ..color = Colors.red.withValues(alpha: 0.25)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    for (int i = 0; i < data.length; i++) {
      final x = i * (size.width / data.length) + 5;
      var topY = size.height;

      for (int j = data[i].length - 1; j >= 0; j--) {
        final h = (data[i][j] / maxTotal) * size.height * animation;
        topY -= h;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, topY, barWidth, h),
          const Radius.circular(3),
        );

        // Glow
        canvas.drawRRect(
          rect,
          Paint()
            ..color = colors[j].withValues(alpha: 0.20)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );

        // Bar gradient
        canvas.drawRRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colors[j], colors[j].withValues(alpha: 0.55)],
            ).createShader(Rect.fromLTWH(x, topY, barWidth, h)),
        );

        // Glass highlight
        if (h > 4) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x + 2, topY + 1, barWidth - 4, 2),
              const Radius.circular(1),
            ),
            Paint()..color = Colors.white.withValues(alpha: 0.12),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HoloBarChartPainter old) =>
      old.animation != animation;
}
