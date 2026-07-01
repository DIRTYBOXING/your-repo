import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:async';
import '../../../core/theme/design_tokens.dart';
import '../../../core/constants/app_logos.dart';
import '../../../shared/services/body_monitor_service.dart';
import '../../../shared/services/auth_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// BODY MONITOR — Glass Morphism · Weight · Fluids · Body Comp
/// Hydration Alerts · Safety · AI Insights
/// ═══════════════════════════════════════════════════════════════════════════

const _kCyan = Color(0xFF00F5FF);
const _kBlue = Color(0xFF2979FF);
const _kRed = Color(0xFFFF2D55);
const _kGold = Color(0xFFFFD700);
const _kGreen = Color(0xFF00E676);
const _kMagenta = Color(0xFFFF0080);
const _kAmber = Color(0xFFFFB800);
const _kPanel = Color(0xFF0D1B2A);

class BodyMonitorScreen extends StatefulWidget {
  const BodyMonitorScreen({super.key});
  @override
  State<BodyMonitorScreen> createState() => _BodyMonitorScreenState();
}

class _BodyMonitorScreenState extends State<BodyMonitorScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _waveCtrl;

  // Hydration reminder
  Timer? _hydrationTimer;
  bool _showHydrationAlert = false;
  int _hydrationMinutes = 30; // remind every N minutes
  DateTime? _lastDrinkTime;
  int _waterStreak = 0; // consecutive alerts responded to

  // Quick-add animation
  // ignore: unused_field
  bool _justLogged = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _loadData();
    _startHydrationReminder();
  }

  void _loadData() {
    final uid = context.read<AuthService>().currentUser?.uid ?? 'demo';
    final svc = context.read<BodyMonitorService>();
    svc.loadToday(uid);
    svc.loadWeek(uid);
  }

  void _startHydrationReminder() {
    _hydrationTimer?.cancel();
    _hydrationTimer = Timer.periodic(Duration(minutes: _hydrationMinutes), (_) {
      if (mounted) setState(() => _showHydrationAlert = true);
    });
    // Show first reminder after 30 min
    Future.delayed(Duration(minutes: _hydrationMinutes), () {
      if (mounted) setState(() => _showHydrationAlert = true);
    });
  }

  void _dismissHydrationAlert({bool drank = false}) {
    setState(() {
      _showHydrationAlert = false;
      if (drank) {
        _lastDrinkTime = DateTime.now();
        _waterStreak++;
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _hydrationTimer?.cancel();
    super.dispose();
  }

  String get _uid => context.read<AuthService>().currentUser?.uid ?? 'demo';

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (ctx, innerBoxIsScrolled) => [
              _buildAppBar(innerBoxIsScrolled),
            ],
            body: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildWeightTab(),
                _buildFluidsTab(),
                _buildBodyCompTab(),
                _buildSafetyTab(),
                _buildAIInsightsTab(),
              ],
            ),
          ),
          // Hydration alert overlay
          if (_showHydrationAlert) _buildHydrationAlertOverlay(),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────
  SliverAppBar _buildAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: _kPanel.withValues(alpha: 0.95),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.canPop() ? context.pop() : null,
      ),
      title: Row(
        children: [
          Image.asset(
            AppLogos.icon,
            width: 22,
            height: 22,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.shield, color: _kCyan, size: 18),
          ),
          const SizedBox(width: 8),
          const Text(
            'BODY MONITOR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 8),
          // Hydration streak badge
          if (_waterStreak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kCyan, _kBlue]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '💧$_waterStreak',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
      actions: [
        // Water reminder toggle
        IconButton(
          icon: Icon(
            Icons.notifications_active,
            color: _hydrationTimer != null ? _kCyan : Colors.white30,
            size: 20,
          ),
          tooltip: 'Hydration Alerts',
          onPressed: _showHydrationSettings,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white38, size: 20),
          color: _kPanel,
          onSelected: _handleMenuAction,
          itemBuilder: (_) => [
            _menuItem('sync', Icons.sync, 'Sync Device', _kCyan),
            _menuItem('export', Icons.download, 'Export Report', _kGreen),
            _menuItem('target', Icons.flag, 'Set Target', _kAmber),
          ],
        ),
      ],
      bottom: TabBar(
        controller: _tabCtrl,
        indicatorColor: _kCyan,
        indicatorWeight: 2.5,
        labelColor: _kCyan,
        unselectedLabelColor: Colors.white30,
        isScrollable: true,
        tabAlignment: TabAlignment.center,
        labelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
        tabs: const [
          Tab(text: 'WEIGHT', icon: Icon(Icons.monitor_weight, size: 16)),
          Tab(text: 'FLUIDS', icon: Icon(Icons.water_drop, size: 16)),
          Tab(text: 'BODY COMP', icon: Icon(Icons.accessibility_new, size: 16)),
          Tab(text: 'SAFETY', icon: Icon(Icons.health_and_safety, size: 16)),
          Tab(text: 'AI INSIGHTS', icon: Icon(Icons.psychology, size: 16)),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String v, IconData ic, String t, Color c) {
    return PopupMenuItem(
      value: v,
      child: Row(
        children: [
          Icon(ic, size: 16, color: c),
          const SizedBox(width: 8),
          Text(t, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'sync':
        _showSyncDialog();
        break;
      case 'export':
        _showExportPreview();
        break;
      case 'target':
        _showTargetDialog();
        break;
    }
  }

  // ── FAB ──────────────────────────────────────────────────────
  Widget _buildFab() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (ctx, child) {
        final scale = 1.0 + (_pulseCtrl.value * 0.05);
        return Transform.scale(
          scale: scale,
          child: FloatingActionButton(
            backgroundColor: _kCyan,
            foregroundColor: Colors.black,
            onPressed: () {
              final tab = _tabCtrl.index;
              if (tab == 0) {
                _showWeightInputDialog();
              } else if (tab == 1) {
                _showFluidInputDialog();
              } else if (tab == 3) {
                _showEyeCheckDialog();
              } else {
                _showWeightInputDialog();
              }
            },
            child: const Icon(Icons.add, size: 28),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HYDRATION ALERT OVERLAY — drink water reminder
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildHydrationAlertOverlay() {
    return AnimatedBuilder(
      animation: _waveCtrl,
      builder: (ctx, child) {
        return GestureDetector(
          onTap: _dismissHydrationAlert,
          child: Container(
            color: Colors.black.withValues(alpha: 0.6),
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _kCyan.withValues(alpha: 0.15),
                      _kBlue.withValues(alpha: 0.08),
                      _kPanel,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _kCyan.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kCyan.withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated water drop
                    Transform.translate(
                      offset: Offset(
                        0,
                        math.sin(_waveCtrl.value * math.pi * 2) * 6,
                      ),
                      child: const Text('💧', style: TextStyle(fontSize: 64)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'DRINK WATER',
                      style: TextStyle(
                        color: _kCyan,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _lastDrinkTime != null
                          ? 'Last drink ${DateTime.now().difference(_lastDrinkTime!).inMinutes} min ago'
                          : 'Stay hydrated for peak performance',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (_waterStreak > 0)
                      Text(
                        '🔥 $_waterStreak drink streak — keep it up!',
                        style: TextStyle(
                          color: _kAmber.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Quick add buttons
                    Row(
                      children: [
                        Expanded(child: _alertQuickBtn('250ml', 250, '🥛')),
                        const SizedBox(width: 8),
                        Expanded(child: _alertQuickBtn('500ml', 500, '💧')),
                        const SizedBox(width: 8),
                        Expanded(child: _alertQuickBtn('750ml', 750, '🫗')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _alertQuickBtn(
                            'Electrolytes',
                            500,
                            '⚡',
                            type: FluidType.electrolyteWater,
                            color: _kAmber,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _alertQuickBtn(
                            'Protein Shake',
                            350,
                            '🥤',
                            type: FluidType.proteinShake,
                            color: _kGreen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _alertQuickBtn(
                            'Coffee',
                            250,
                            '☕',
                            type: FluidType.coffee,
                            color: const Color(0xFFD4A574),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _dismissHydrationAlert,
                      child: Text(
                        'Dismiss',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _alertQuickBtn(
    String label,
    double ml,
    String emoji, {
    FluidType type = FluidType.water,
    Color color = _kCyan,
  }) {
    return GestureDetector(
      onTap: () {
        final svc = context.read<BodyMonitorService>();
        svc.logFluid(
          _uid,
          amountMl: ml,
          type: type,
          notes: 'Quick add — hydration alert',
        );
        _dismissHydrationAlert(drank: true);
        _showQuickAddFeedback(label, emoji);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickAddFeedback(String label, String emoji) {
    setState(() => _justLogged = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _justLogged = false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$emoji $label logged — nice!'),
        backgroundColor: _kCyan,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showHydrationSettings() {
    showDialog(
      context: context,
      builder: (ctx) {
        var mins = _hydrationMinutes;
        return StatefulBuilder(
          builder: (ctx, setDlg) => AlertDialog(
            backgroundColor: _kPanel,
            title: const Text(
              '💧 Hydration Reminders',
              style: TextStyle(color: _kCyan),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Remind me every:',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [15, 20, 30, 45, 60].map((m) {
                    final active = mins == m;
                    return GestureDetector(
                      onTap: () => setDlg(() => mins = m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? _kCyan.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: active
                                ? _kCyan.withValues(alpha: 0.4)
                                : Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Text(
                          '${m}min',
                          style: TextStyle(
                            color: active ? _kCyan : Colors.white38,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.white.withValues(alpha: 0.2),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'A full-screen reminder will appear every $mins minutes',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _hydrationTimer?.cancel();
                    _hydrationTimer = null;
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Turn Off', style: TextStyle(color: _kRed)),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hydrationMinutes = mins;
                  });
                  _startHydrationReminder();
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kCyan,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // WEIGHT TAB
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildWeightTab() {
    return Consumer<BodyMonitorService>(
      builder: (context, svc, _) {
        if (svc.loading) return _glassLoader();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildWeightHero(svc),
            const SizedBox(height: 14),
            _buildWeightChart(svc),
            const SizedBox(height: 14),
            if (svc.targetWeight != null) ...[
              _buildWeightCutProgress(svc),
              const SizedBox(height: 14),
            ],
            _glassSection(
              'TODAY\'S WEIGH-INS',
              Icons.list,
              trailing: _addBtn(_showWeightInputDialog),
            ),
            ...svc.weightLogs.map(_buildWeightLogCard),
            if (svc.weightLogs.isEmpty)
              _emptyGlass('No weight logs today', Icons.monitor_weight),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildWeightHero(BodyMonitorService svc) {
    return _GlassCard(
      accent: _kCyan,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _kCyan,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'CURRENT WEIGHT',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              svc.latestWeight != null
                  ? '${svc.latestWeight!.toStringAsFixed(1)} lbs'
                  : '— lbs',
              style: const TextStyle(
                color: _kCyan,
                fontSize: 44,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (svc.latestWeight != null)
              Text(
                '${(svc.latestWeight! * 0.453592).toStringAsFixed(1)} kg',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 14,
                ),
              ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (svc.latestBodyFat != null)
                  _glassBadge(
                    'Body Fat',
                    '${svc.latestBodyFat!.toStringAsFixed(1)}%',
                    _kAmber,
                  ),
                const SizedBox(width: 10),
                _glassBadge(
                  'Phase',
                  '${svc.currentPhase.emoji} ${svc.currentPhase.label}',
                  _kGreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightChart(BodyMonitorService svc) {
    final snapshots = svc.weekSnapshots;
    if (snapshots.isEmpty) return const SizedBox.shrink();

    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _glassSection('7-DAY WEIGHT TREND', Icons.show_chart),
            const SizedBox(height: 10),
            SizedBox(
              height: 130,
              child: CustomPaint(
                size: const Size(double.infinity, 130),
                painter: _WeightChartPainter(
                  snapshots: snapshots,
                  targetWeight: svc.targetWeight,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: snapshots.map((s) {
                const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                return Text(
                  days[s.date.weekday - 1],
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightCutProgress(BodyMonitorService svc) {
    final current = svc.latestWeight ?? 162.4;
    final target = svc.targetWeight ?? 155.0;
    final toCut = current - target;
    final startWeight = current + 3;
    final progress = toCut > 0
        ? ((startWeight - current) / (startWeight - target)).clamp(0.0, 1.0)
        : 1.0;
    final color = toCut <= 0
        ? _kGreen
        : toCut < 5
        ? _kAmber
        : _kRed;

    return _GlassCard(
      accent: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _glassSection('WEIGHT CUT PROGRESS', Icons.trending_down),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _cutStat('Current', '${current.toStringAsFixed(1)} lbs'),
                _cutStat('Target', '${target.toStringAsFixed(1)} lbs'),
                _cutStat('To Cut', '${toCut.toStringAsFixed(1)} lbs'),
                _cutStat('Progress', '${(progress * 100).toStringAsFixed(0)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cutStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 9,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildWeightLogCard(WeightLog w) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _GlassCard(
        compact: true,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(w.source.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${w.weightLbs.toStringAsFixed(1)} lbs',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${w.timestamp.hour.toString().padLeft(2, '0')}:${w.timestamp.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 11,
                          ),
                        ),
                        if (w.bodyFatPercent != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${w.bodyFatPercent!.toStringAsFixed(1)}% BF',
                            style: const TextStyle(
                              color: _kAmber,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Text(
                          w.source.label,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.2),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    if (w.notes.isNotEmpty)
                      Text(
                        w.notes,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: _kRed, size: 16),
                onPressed: () => context
                    .read<BodyMonitorService>()
                    .deleteWeightLog(_uid, w.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FLUIDS TAB
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildFluidsTab() {
    return Consumer<BodyMonitorService>(
      builder: (context, svc, _) {
        if (svc.loading) return _glassLoader();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHydrationHero(svc),
            const SizedBox(height: 14),
            _buildQuickFluidButtons(),
            const SizedBox(height: 14),
            _buildFluidBalance(svc),
            const SizedBox(height: 14),
            // Hydration timeline
            _buildHydrationTimeline(svc),
            const SizedBox(height: 14),
            _glassSection(
              'FLUID LOG',
              Icons.list,
              trailing: _addBtn(_showFluidInputDialog),
            ),
            ...svc.fluidLogs.map(_buildFluidLogCard),
            if (svc.fluidLogs.isEmpty)
              _emptyGlass('No fluid logs today', Icons.water_drop),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildHydrationHero(BodyMonitorService svc) {
    final intakeMl = svc.todayFluidIntake;
    final targetMl = 3500.0;
    final progress = (intakeMl / targetMl).clamp(0.0, 1.2);
    final color = _hydrationColor(progress);

    return _GlassCard(
      accent: color,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'HYDRATION STATUS',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Animated water ring
            AnimatedBuilder(
              animation: _waveCtrl,
              builder: (ctx, child) {
                return SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ring
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: CircularProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          strokeWidth: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.04),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                      // Glow ring
                      SizedBox(
                        width: 118,
                        height: 118,
                        child: CircularProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          strokeWidth: 2,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation(
                            color.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.translate(
                            offset: Offset(
                              0,
                              math.sin(_waveCtrl.value * math.pi * 2) * 2,
                            ),
                            child: const Text(
                              '💧',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                          Text(
                            '${(intakeMl / 1000).toStringAsFixed(1)}L',
                            style: TextStyle(
                              color: color,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '/ ${(targetMl / 1000).toStringAsFixed(1)}L',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              svc.todaySnapshot?.hydrationStatus ?? '🟡 MODERATE',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (_lastDrinkTime != null) ...[
              const SizedBox(height: 6),
              Text(
                'Last drink ${DateTime.now().difference(_lastDrinkTime!).inMinutes} min ago',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFluidButtons() {
    final amounts = [
      {'label': '250ml', 'ml': 250.0, 'emoji': '🥛', 'color': _kCyan},
      {'label': '500ml', 'ml': 500.0, 'emoji': '💧', 'color': _kBlue},
      {'label': '750ml', 'ml': 750.0, 'emoji': '🫗', 'color': _kGreen},
      {'label': '1L', 'ml': 1000.0, 'emoji': '🧴', 'color': _kAmber},
    ];

    return Row(
      children: amounts.map((a) {
        final c = a['color'] as Color;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () {
                context.read<BodyMonitorService>().logFluid(
                  _uid,
                  amountMl: a['ml'] as double,
                );
                setState(() => _lastDrinkTime = DateTime.now());
                _showQuickAddFeedback(
                  a['label'] as String,
                  a['emoji'] as String,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.withValues(alpha: 0.15)),
                ),
                child: Column(
                  children: [
                    Text(
                      a['emoji'] as String,
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a['label'] as String,
                      style: TextStyle(
                        color: c,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFluidBalance(BodyMonitorService svc) {
    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _glassSection('FLUID BALANCE', Icons.balance),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _fluidStat(
                  'Intake',
                  '${(svc.todayFluidIntake / 1000).toStringAsFixed(1)}L',
                  _kCyan,
                  Icons.arrow_downward,
                ),
                _fluidStat(
                  'Loss',
                  '${(svc.todayFluidLoss / 1000).toStringAsFixed(1)}L',
                  _kRed,
                  Icons.arrow_upward,
                ),
                _fluidStat(
                  'Net',
                  '${svc.netFluidBalance >= 0 ? "+" : ""}${(svc.netFluidBalance / 1000).toStringAsFixed(1)}L',
                  svc.netFluidBalance >= 0 ? _kGreen : _kRed,
                  svc.netFluidBalance >= 0 ? Icons.check_circle : Icons.warning,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fluidStat(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 9,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildHydrationTimeline(BodyMonitorService svc) {
    if (svc.fluidLogs.isEmpty) return const SizedBox.shrink();
    final intakes = svc.fluidLogs.where((f) => !f.isLoss).toList();
    if (intakes.isEmpty) return const SizedBox.shrink();

    // Show hourly hydration bars
    final Map<int, double> hourly = {};
    for (final f in intakes) {
      hourly[f.timestamp.hour] = (hourly[f.timestamp.hour] ?? 0) + f.amountMl;
    }

    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _glassSection('HYDRATION TIMELINE', Icons.timeline),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(24, (h) {
                  final ml = hourly[h] ?? 0;
                  final maxMl = hourly.values.isEmpty
                      ? 1.0
                      : hourly.values.reduce(math.max);
                  final pct = maxMl > 0 ? (ml / maxMl) : 0.0;
                  final now = DateTime.now().hour;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (ml > 0)
                            Text(
                              '${ml.round()}',
                              style: TextStyle(
                                color: _kCyan.withValues(alpha: 0.5),
                                fontSize: 6,
                              ),
                            ),
                          Flexible(
                            child: FractionallySizedBox(
                              heightFactor: pct > 0
                                  ? pct.clamp(0.05, 1.0)
                                  : 0.02,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: h == now
                                      ? _kCyan.withValues(alpha: 0.6)
                                      : ml > 0
                                      ? _kCyan.withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          if (h % 4 == 0)
                            Text(
                              '${h}h',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.2),
                                fontSize: 7,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFluidLogCard(FluidLog f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _GlassCard(
        compact: true,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(
                f.isLoss ? '🔴' : f.type.emoji,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${f.isLoss ? "−" : "+"}${f.amountMl.toStringAsFixed(0)}ml  ${f.type.label}',
                      style: TextStyle(
                        color: f.isLoss ? _kRed : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${f.timestamp.hour.toString().padLeft(2, '0')}:${f.timestamp.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 11,
                          ),
                        ),
                        if (f.notes.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              f.notes,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: _kRed, size: 16),
                onPressed: () => context
                    .read<BodyMonitorService>()
                    .deleteFluidLog(_uid, f.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BODY COMP TAB
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildBodyCompTab() {
    return Consumer<BodyMonitorService>(
      builder: (context, svc, _) {
        final latest = svc.weightLogs.isNotEmpty ? svc.weightLogs.first : null;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _compMetric(
                  'Weight',
                  latest?.weightLbs != null
                      ? '${latest!.weightLbs.toStringAsFixed(1)} lbs'
                      : '—',
                  Icons.monitor_weight,
                  _kCyan,
                ),
                _compMetric(
                  'Body Fat',
                  latest?.bodyFatPercent != null
                      ? '${latest!.bodyFatPercent!.toStringAsFixed(1)}%'
                      : '—',
                  Icons.pie_chart,
                  _kAmber,
                ),
                _compMetric(
                  'Muscle Mass',
                  latest?.muscleMassLbs != null
                      ? '${latest!.muscleMassLbs!.toStringAsFixed(1)} lbs'
                      : '—',
                  Icons.fitness_center,
                  _kGreen,
                ),
                _compMetric(
                  'BMI',
                  latest?.bmi != null ? latest!.bmi!.toStringAsFixed(1) : '—',
                  Icons.speed,
                  _kMagenta,
                ),
                _compMetric(
                  'Visceral Fat',
                  latest?.visceralFat != null
                      ? latest!.visceralFat!.toStringAsFixed(0)
                      : '—',
                  Icons.warning_amber,
                  _kRed,
                ),
                _compMetric(
                  'Bone Mass',
                  latest?.boneMassLbs != null
                      ? '${latest!.boneMassLbs!.toStringAsFixed(1)} lbs'
                      : '—',
                  Icons.architecture,
                  _kGold,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDevicesCard(),
            const SizedBox(height: 16),
            _buildTranspirationCard(),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _compMetric(String label, String value, IconData icon, Color color) {
    final w = (MediaQuery.of(context).size.width - 42) / 2;
    return SizedBox(
      width: w,
      child: _GlassCard(
        accent: color,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color.withValues(alpha: 0.6), size: 20),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDevicesCard() {
    return _GlassCard(
      accent: _kCyan,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _glassSection('CONNECTED DEVICES', Icons.devices),
            const SizedBox(height: 8),
            _deviceRow(MonitorSource.smartScale, true),
            _deviceRow(MonitorSource.appleWatch, false),
            _deviceRow(MonitorSource.whoop, false),
            _deviceRow(MonitorSource.garmin, false),
            _deviceRow(MonitorSource.ouraRing, false),
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: () => context.push('/smart-devices'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _kCyan.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kCyan.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: _kCyan.withValues(alpha: 0.5),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Connect Device',
                        style: TextStyle(
                          color: _kCyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deviceRow(MonitorSource device, bool connected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(device.icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              device.label,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: connected
                  ? _kGreen.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              connected ? 'CONNECTED' : 'CONNECT',
              style: TextStyle(
                color: connected ? _kGreen : Colors.white30,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranspirationCard() {
    return _GlassCard(
      accent: _kAmber,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _glassSection('TRANSPIRATION CALCULATOR', Icons.thermostat),
            const SizedBox(height: 8),
            Text(
              'Weigh before and after training to calculate sweat rate.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showTranspirationCalculator,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _kAmber.withValues(alpha: 0.2),
                      _kAmber.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kAmber.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calculate, color: _kAmber, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'CALCULATE SWEAT RATE',
                      style: TextStyle(
                        color: _kAmber,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SAFETY TAB
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildSafetyTab() {
    return Consumer<BodyMonitorService>(
      builder: (context, svc, _) {
        if (svc.loading) return _glassLoader();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _GlassCard(
              accent: _kRed,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _kRed.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.health_and_safety,
                        color: _kRed,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'FIGHTER SAFETY CHECKPOINT',
                      style: TextStyle(
                        color: _kRed,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Monitor pupil dilation, reaction times, and anisocoria\nduring extreme weight cuts to prevent neurological trauma.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _showEyeCheckDialog,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _kRed.withValues(alpha: 0.3),
                              _kRed.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _kRed.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.remove_red_eye,
                              color: _kRed,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'LOG EYE CHECK',
                              style: TextStyle(
                                color: _kRed,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _glassSection('RECENT EYE CHECKS', Icons.history),
            ...svc.eyeCheckLogs.map(_buildEyeCheckCard),
            if (svc.eyeCheckLogs.isEmpty)
              _emptyGlass('No safety checks logged', Icons.remove_red_eye),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildEyeCheckCard(EyeCheckLog log) {
    final isWarning =
        log.hasAnisocoria || log.hasRedness || log.reactionTimeMs > 250;
    final color = isWarning ? _kRed : _kGreen;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _GlassCard(
        accent: color,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isWarning
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.timestamp.toString().substring(0, 16),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'L: ${log.leftPupilSizeMm}mm | R: ${log.rightPupilSizeMm}mm | RT: ${log.reactionTimeMs}ms',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                    if (log.notes.isNotEmpty)
                      Text(
                        log.notes,
                        style: TextStyle(
                          color: color.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.white.withValues(alpha: 0.2),
                  size: 16,
                ),
                onPressed: () => context
                    .read<BodyMonitorService>()
                    .deleteEyeCheckLog(_uid, log.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AI INSIGHTS TAB
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildAIInsightsTab() {
    return Consumer<BodyMonitorService>(
      builder: (context, svc, _) {
        final analysis = svc.analyzeWeightCut(
          svc.weightLogs,
          svc.targetWeight ?? 155.0,
          DateTime.now().add(const Duration(days: 21)),
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // AI brain
            _GlassCard(
              accent: _kMagenta,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _kMagenta.withValues(alpha: 0.15),
                            _kMagenta.withValues(alpha: 0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.psychology,
                        color: _kMagenta,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'AI BODY INTELLIGENCE',
                      style: TextStyle(
                        color: _kMagenta,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Monitoring 24/7 · learning your patterns',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            _insightCard(
              'Weight Cut Risk',
              analysis['riskLevel'] as String? ?? '—',
              analysis['recommendation'] as String? ?? '',
              Icons.warning,
              _kAmber,
            ),
            const SizedBox(height: 10),

            if (svc.todaySnapshot != null)
              _insightCard(
                'Daily Analysis',
                svc.todaySnapshot!.hydrationStatus,
                svc.todaySnapshot!.aiInsight,
                Icons.analytics,
                _kCyan,
              ),
            const SizedBox(height: 10),

            _insightCard(
              'Weekly Trend',
              analysis['weeklyTrend'] != null
                  ? '${(analysis['weeklyTrend'] as double) > 0 ? "+" : ""}${(analysis['weeklyTrend'] as double).toStringAsFixed(1)} lbs'
                  : 'Collecting data...',
              analysis['daysLeft'] != null
                  ? '${analysis['daysLeft']} days to fight · ${(analysis['toCut'] as double?)?.toStringAsFixed(1) ?? "—"} lbs to cut'
                  : 'Set a target weight and fight date for analysis.',
              Icons.trending_down,
              _kGreen,
            ),
            const SizedBox(height: 14),

            // Recommendations
            _GlassCard(
              accent: _kMagenta,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _glassSection('AI RECOMMENDATIONS', Icons.lightbulb),
                    const SizedBox(height: 10),
                    _recRow(
                      '💧',
                      'Increase water intake by 500ml before afternoon training',
                    ),
                    _recRow(
                      '⚖️',
                      'Morning weigh-in shows consistent -0.14 kg/day trend',
                    ),
                    _recRow(
                      '🏃',
                      'Add 20min low-intensity cardio for faster cut',
                    ),
                    _recRow(
                      '😴',
                      'Sleep quality impacts weight retention — aim for 8hrs',
                    ),
                    _recRow(
                      '🍽️',
                      'Reduce sodium intake 48hrs before weigh-in',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Export
            GestureDetector(
              onTap: _showExportPreview,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _kGreen.withValues(alpha: 0.2),
                      _kGreen.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.download, color: _kGreen, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'EXPORT FULL REPORT',
                      style: TextStyle(
                        color: _kGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _insightCard(
    String title,
    String status,
    String detail,
    IconData icon,
    Color color,
  ) {
    return _GlassCard(
      accent: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color.withValues(alpha: 0.6), size: 18),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (detail.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                detail,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _recRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DIALOGS (same logic, glass styled)
  // ═══════════════════════════════════════════════════════════════════════
  void _showWeightInputDialog() {
    final weightCtrl = TextEditingController();
    final bfCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    var source = MonitorSource.manual;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '⚖️ LOG WEIGHT',
                style: TextStyle(
                  color: _kCyan,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              _sheetField(
                weightCtrl,
                'Weight (lbs)',
                autofocus: true,
                numeric: true,
              ),
              const SizedBox(height: 10),
              _sheetField(bfCtrl, 'Body Fat % (optional)', numeric: true),
              const SizedBox(height: 10),
              DropdownButtonFormField<MonitorSource>(
                initialValue: source,
                decoration: _inputDeco('Source'),
                dropdownColor: _kPanel,
                style: const TextStyle(color: Colors.white),
                items: MonitorSource.values
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text('${s.icon} ${s.label}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => ss(() => source = v!),
              ),
              const SizedBox(height: 10),
              _sheetField(notesCtrl, 'Notes (optional)'),
              const SizedBox(height: 16),
              _sheetBtn('LOG WEIGHT', _kCyan, () {
                final w = double.tryParse(weightCtrl.text);
                if (w == null || w <= 0) return;
                context.read<BodyMonitorService>().logWeight(
                  _uid,
                  weightLbs: w,
                  bodyFatPercent: double.tryParse(bfCtrl.text),
                  source: source,
                  notes: notesCtrl.text,
                );
                Navigator.pop(ctx);
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showFluidInputDialog() {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    var type = FluidType.water;
    var isLoss = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '💧 LOG FLUID',
                style: TextStyle(
                  color: _kCyan,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              _sheetField(
                amountCtrl,
                'Amount (ml)',
                autofocus: true,
                numeric: true,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<FluidType>(
                initialValue: type,
                decoration: _inputDeco('Type'),
                dropdownColor: _kPanel,
                style: const TextStyle(color: Colors.white),
                items: FluidType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text('${t.emoji} ${t.label}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => ss(() => type = v!),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: Text(
                  'Fluid Loss (sweat / transpiration)',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                value: isLoss,
                activeThumbColor: _kRed,
                activeTrackColor: _kRed.withValues(alpha: 0.3),
                onChanged: (v) => ss(() => isLoss = v),
              ),
              const SizedBox(height: 10),
              _sheetField(notesCtrl, 'Notes (optional)'),
              const SizedBox(height: 16),
              _sheetBtn('LOG FLUID', _kCyan, () {
                final ml = double.tryParse(amountCtrl.text);
                if (ml == null || ml <= 0) return;
                context.read<BodyMonitorService>().logFluid(
                  _uid,
                  amountMl: ml,
                  type: type,
                  isLoss: isLoss,
                  notes: notesCtrl.text,
                );
                if (!isLoss) setState(() => _lastDrinkTime = DateTime.now());
                Navigator.pop(ctx);
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showEyeCheckDialog() {
    double leftMm = 3.0, rightMm = 3.0, rtMs = 200.0;
    bool redness = false, anisocoria = false;
    String notes = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          backgroundColor: _kPanel,
          title: const Text(
            '👁️ Log Eye Check',
            style: TextStyle(
              color: _kRed,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: leftMm.toString(),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDeco('Left Pupil (mm)'),
                        onChanged: (v) => leftMm = double.tryParse(v) ?? leftMm,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: rightMm.toString(),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDeco('Right Pupil (mm)'),
                        onChanged: (v) =>
                            rightMm = double.tryParse(v) ?? rightMm,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: rtMs.toString(),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco('Reaction Time (ms)'),
                  onChanged: (v) => rtMs = double.tryParse(v) ?? rtMs,
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: Text(
                    'Redness',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                  value: redness,
                  activeThumbColor: _kRed,
                  onChanged: (v) => ss(() => redness = v),
                ),
                SwitchListTile(
                  title: Text(
                    'Anisocoria',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                  value: anisocoria,
                  activeThumbColor: _kRed,
                  onChanged: (v) => ss(() => anisocoria = v),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco('Notes'),
                  onChanged: (v) => notes = v,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<BodyMonitorService>().logEyeCheck(
                  _uid,
                  leftPupilSizeMm: leftMm,
                  rightPupilSizeMm: rightMm,
                  reactionTimeMs: rtMs,
                  hasRedness: redness,
                  hasAnisocoria: anisocoria,
                  notes: notes,
                );
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSyncDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kPanel,
        title: const Text('Sync Device', style: TextStyle(color: _kCyan)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: MonitorSource.values
              .where((s) => s != MonitorSource.manual)
              .map(
                (s) => ListTile(
                  leading: Text(s.icon, style: const TextStyle(fontSize: 18)),
                  title: Text(
                    s.label,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  onTap: () {
                    context.read<BodyMonitorService>().syncFromDevice(_uid, s);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${s.icon} Syncing ${s.label}...'),
                        backgroundColor: _kCyan,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showTargetDialog() {
    final svc = context.read<BodyMonitorService>();
    final weightCtrl = TextEditingController(
      text: svc.targetWeight?.toString() ?? '155.0',
    );
    var phase = svc.currentPhase;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          backgroundColor: _kPanel,
          title: const Text('🎯 Set Target', style: TextStyle(color: _kAmber)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDeco('Target Weight (lbs)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<WeightPhase>(
                initialValue: phase,
                decoration: _inputDeco('Phase'),
                dropdownColor: _kPanel,
                style: const TextStyle(color: Colors.white),
                items: WeightPhase.values
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text('${p.emoji} ${p.label}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => ss(() => phase = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final w = double.tryParse(weightCtrl.text);
                if (w != null) {
                  context.read<BodyMonitorService>().setTarget(w, phase);
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAmber,
                foregroundColor: Colors.black,
              ),
              child: const Text('Set'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTranspirationCalculator() {
    final preCtrl = TextEditingController();
    final postCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    final fluidCtrl = TextEditingController();
    String? result;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          backgroundColor: _kPanel,
          title: const Text(
            '🌊 Transpiration Calculator',
            style: TextStyle(color: _kAmber),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: preCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco('Pre-Workout Weight (lbs)'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: postCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco('Post-Workout Weight (lbs)'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: durationCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco('Duration (minutes)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: fluidCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco('Fluid consumed during (ml)'),
                  keyboardType: TextInputType.number,
                ),
                if (result != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kAmber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kAmber.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      result!,
                      style: const TextStyle(
                        color: _kAmber,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Close',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final pre = double.tryParse(preCtrl.text);
                final post = double.tryParse(postCtrl.text);
                final dur = int.tryParse(durationCtrl.text);
                final fluid = double.tryParse(fluidCtrl.text) ?? 0;
                if (pre != null && post != null && dur != null) {
                  final rate = context
                      .read<BodyMonitorService>()
                      .computeTranspirationRate(pre, post, dur, fluid);
                  if (rate != null) {
                    ss(() {
                      result =
                          '🌊 Sweat Rate: ${rate.toStringAsFixed(0)} ml/hr\n'
                          '💧 Total Loss: ${((pre - post) * 453.592 + fluid).toStringAsFixed(0)} ml\n'
                          '⚖️ Weight Lost: ${(pre - post).toStringAsFixed(1)} lbs';
                    });
                    context.read<BodyMonitorService>().logFluid(
                      _uid,
                      amountMl: (pre - post) * 453.592 + fluid,
                      isLoss: true,
                      notes:
                          'Transpiration loss — ${dur}min (${rate.toStringAsFixed(0)} ml/hr)',
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAmber,
                foregroundColor: Colors.black,
              ),
              child: const Text('Calculate'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportPreview() {
    final svc = context.read<BodyMonitorService>();
    svc.generateExportHtml(
      fighterName:
          context.read<AuthService>().userModel?.displayName ?? 'Fighter',
      snapshots: svc.weekSnapshots,
      recentWeights: svc.weightLogs,
      recentFluids: svc.fluidLogs,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kPanel,
        title: const Text('Export Report', style: TextStyle(color: _kGreen)),
        content: Text(
          'Report generated! Ready for email or print.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📧 Report ready for export'),
                  backgroundColor: _kGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.email),
            label: const Text('Email'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SHARED GLASS HELPERS
  // ═══════════════════════════════════════════════════════════════════════
  Widget _glassLoader() =>
      const Center(child: CircularProgressIndicator(color: _kCyan));

  Widget _glassSection(String title, IconData icon, {Widget? trailing}) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: _kCyan,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, color: _kCyan.withValues(alpha: 0.4), size: 14),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing],
      ],
    );
  }

  Widget _addBtn(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        Icons.add_circle,
        color: _kCyan.withValues(alpha: 0.5),
        size: 20,
      ),
    );
  }

  Widget _glassBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
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
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 8,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyGlass(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: _kCyan.withValues(alpha: 0.15)),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetField(
    TextEditingController ctrl,
    String label, {
    bool autofocus = false,
    bool numeric = false,
  }) {
    return TextField(
      controller: ctrl,
      autofocus: autofocus,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
      decoration: _inputDeco(label),
    );
  }

  Widget _sheetBtn(String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Color _hydrationColor(double progress) {
    if (progress < 0.3) return _kRed;
    if (progress < 0.5) return _kAmber;
    if (progress < 0.7) return _kCyan;
    return _kGreen;
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kCyan),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GLASS CARD WIDGET
// ═══════════════════════════════════════════════════════════════════════════
class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color? accent;
  final bool compact;
  const _GlassCard({required this.child, this.accent, this.compact = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (accent ?? _kCyan).withValues(alpha: 0.04),
            Colors.white.withValues(alpha: 0.02),
            Colors.white.withValues(alpha: 0.01),
          ],
        ),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(
          color: (accent ?? _kCyan).withValues(alpha: compact ? 0.06 : 0.1),
          width: 0.5,
        ),
        boxShadow: compact
            ? null
            : [
                BoxShadow(
                  color: (accent ?? _kCyan).withValues(alpha: 0.03),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WEIGHT CHART PAINTER
// ═══════════════════════════════════════════════════════════════════════════
class _WeightChartPainter extends CustomPainter {
  final List<DailyBodySnapshot> snapshots;
  final double? targetWeight;
  _WeightChartPainter({required this.snapshots, this.targetWeight});

  @override
  void paint(Canvas canvas, Size size) {
    if (snapshots.isEmpty) return;
    final weights = snapshots
        .map((s) => s.morningWeight ?? s.eveningWeight ?? 0)
        .where((w) => w > 0)
        .toList();
    if (weights.isEmpty) return;

    final minW = weights.reduce(math.min) - 1;
    final maxW = weights.reduce(math.max) + 1;
    final range = maxW - minW;
    if (range <= 0) return;

    final paint = Paint()
      ..color = _kCyan
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()
      ..color = _kCyan
      ..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..color = _kCyan.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final path = Path();
    final step = size.width / (snapshots.length - 1).clamp(1, 100);

    for (int i = 0; i < snapshots.length; i++) {
      final w = snapshots[i].morningWeight ?? snapshots[i].eveningWeight ?? 0;
      if (w <= 0) continue;
      final x = step * i;
      final y = size.height - ((w - minW) / range * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
      canvas.drawCircle(Offset(x, y), 8, glowPaint);
    }
    canvas.drawPath(path, paint);

    if (targetWeight != null &&
        targetWeight! >= minW &&
        targetWeight! <= maxW) {
      final ty = size.height - ((targetWeight! - minW) / range * size.height);
      final tp = Paint()
        ..color = _kGreen.withValues(alpha: 0.3)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, ty), Offset(size.width, ty), tp);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
