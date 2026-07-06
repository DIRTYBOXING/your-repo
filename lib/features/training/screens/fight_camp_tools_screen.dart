import 'package:flutter/material.dart';
import 'dart:math';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/config/router_config.dart' as rc;
import '../../../shared/widgets/inline_video_card.dart';

// ═══════════════════════════════════════════════════════════════════
//  FIGHT CAMP COMMAND CENTER v2.0
//  Real training logging · Live analytics · Weight management
// ═══════════════════════════════════════════════════════════════════

// ── DATA MODELS ──────────────────────────────────────────────────

class _TrainingCategory {
  final String name;
  final IconData icon;
  final Color color;
  final bool hasDistance;
  const _TrainingCategory({
    required this.name,
    required this.icon,
    required this.color,
    this.hasDistance = false,
  });
}

class _TrainingSession {
  final _TrainingCategory category;
  final int intensity; // 1–10
  final int durationMin;
  final double? distanceKm;
  final DateTime date;
  final String? notes;
  _TrainingSession({
    required this.category,
    required this.intensity,
    required this.durationMin,
    this.distanceKm,
    required this.date,
    this.notes,
  });
  double? get speedKmh => distanceKm != null && durationMin > 0
      ? distanceKm! / (durationMin / 60.0)
      : null;
}

class _WeightEntry {
  final DateTime date;
  final double weightLbs;
  _WeightEntry({required this.date, required this.weightLbs});
}

// ── CATEGORIES ───────────────────────────────────────────────────

const _kBlue = Color(0xFF4FC3F7);
const _kPurple = Color(0xFFBB86FC);
const _kOrange = Color(0xFFFF9800);

final List<_TrainingCategory> _allCategories = [
  const _TrainingCategory(
    name: 'Padwork',
    icon: Icons.sports_kabaddi,
    color: DesignTokens.neonAmber,
  ),
  const _TrainingCategory(
    name: 'Footwork',
    icon: Icons.directions_walk,
    color: DesignTokens.neonCyan,
  ),
  const _TrainingCategory(
    name: 'Sparring',
    icon: Icons.sports_mma,
    color: DesignTokens.neonRed,
  ),
  const _TrainingCategory(
    name: 'Ground Work',
    icon: Icons.sports_martial_arts,
    color: DesignTokens.neonGreen,
  ),
  const _TrainingCategory(
    name: 'Jiu-Jitsu',
    icon: Icons.self_improvement,
    color: _kPurple,
  ),
  const _TrainingCategory(
    name: 'Wrestling',
    icon: Icons.sports_kabaddi,
    color: _kOrange,
  ),
  const _TrainingCategory(
    name: 'Shadowboxing',
    icon: Icons.sports_martial_arts,
    color: DesignTokens.neonMagenta,
  ),
  const _TrainingCategory(
    name: 'Weights',
    icon: Icons.fitness_center,
    color: DesignTokens.neonCyan,
  ),
  const _TrainingCategory(
    name: 'Sprints',
    icon: Icons.directions_run,
    color: DesignTokens.neonRed,
    hasDistance: true,
  ),
  const _TrainingCategory(
    name: 'Swimming',
    icon: Icons.pool,
    color: _kBlue,
    hasDistance: true,
  ),
  const _TrainingCategory(
    name: 'Meditation',
    icon: Icons.self_improvement,
    color: DesignTokens.neonGreen,
  ),
  const _TrainingCategory(
    name: 'Yoga',
    icon: Icons.self_improvement,
    color: DesignTokens.neonGold,
  ),
  const _TrainingCategory(
    name: 'S&C',
    icon: Icons.fitness_center,
    color: _kOrange,
  ),
  const _TrainingCategory(
    name: 'Bag Work',
    icon: Icons.sports_mma,
    color: DesignTokens.neonAmber,
  ),
  const _TrainingCategory(
    name: 'Running',
    icon: Icons.directions_run,
    color: DesignTokens.neonCyan,
    hasDistance: true,
  ),
];

// ═══════════════════════════════════════════════════════════════════
//  MAIN WIDGET
// ═══════════════════════════════════════════════════════════════════

class FightCampToolsScreen extends StatefulWidget {
  const FightCampToolsScreen({super.key});
  @override
  State<FightCampToolsScreen> createState() => _FightCampToolsScreenState();
}

class _FightCampToolsScreenState extends State<FightCampToolsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // ── Training state ──
  final List<_TrainingSession> _sessions = [];
  DateTime _calSelectedDate = DateTime.now();
  DateTime _calViewMonth = DateTime(DateTime.now().year, DateTime.now().month);

  // ── Weight state ──
  final List<_WeightEntry> _weightEntries = [];
  final double _targetWeight = 155.0;

  // ── Recovery state ──
  final Map<int, bool> _recoveryChecked = {};
  final Map<int, bool> _supplementChecked = {};

  // ── Blood Work state ──
  // Iron: 0 = not tested, 1 = low, 2 = normal, 3 = high
  int _ironLevel = 2;
  // Blood sugar (mmol/L)
  double _bloodSugar = 5.2;
  // Hemoglobin (g/dL)
  double _hemoglobin = 14.5;
  // Vitamin D (ng/mL)
  double _vitaminD = 42.0;
  // Testosterone (ng/dL) — optional
  double _testosterone = 620;
  // Cortisol (μg/dL)
  double _cortisol = 12.0;
  // CRP / Inflammation (mg/L)
  double _crp = 0.8;
  // Last blood test date
  DateTime? _lastBloodTest;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    _seedData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── BUILD ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildCampQuickNav(),
            // ── Promo data roll video ──
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: InlineVideoCard(
                assetPath: 'assets/videos/promo_video.mp4',
                title: 'DFC \u2014 Data Meets Combat',
                subtitle: 'Your fight camp, powered by data',
                icon: Icons.sports_mma,
                accentColor: DesignTokens.neonMagenta,
                height: 170,
              ),
            ),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildLogTab(),
                  _buildCalendarTab(),
                  _buildStatsTab(),
                  _buildWeightTab(),
                  _buildRecoveryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSessionSheet,
        backgroundColor: DesignTokens.neonCyan,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  QUICK NAV BAR — Cross-link to related screens
  // ═══════════════════════════════════════════════════════════════

  Widget _buildCampQuickNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Row(
        children: [
          _campNavChip(
            icon: Icons.psychology_alt,
            label: 'AI Coach',
            color: DesignTokens.neonCyan,
            route: rc.RouteConstants.neuralCoachPath,
          ),
          const SizedBox(width: 6),
          _campNavChip(
            icon: Icons.monitor_heart,
            label: 'Health',
            color: DesignTokens.neonMagenta,
            route: rc.RouteConstants.healthDashboardPath,
          ),
          const SizedBox(width: 6),
          _campNavChip(
            icon: Icons.watch,
            label: 'Devices',
            color: DesignTokens.neonGreen,
            route: rc.RouteConstants.deviceHubPath,
          ),
          const SizedBox(width: 6),
          _campNavChip(
            icon: Icons.scale,
            label: 'Body',
            color: DesignTokens.neonAmber,
            route: rc.RouteConstants.bodyMonitorPath,
          ),
        ],
      ),
    );
  }

  Widget _campNavChip({
    required IconData icon,
    required String label,
    required Color color,
    required String route,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.push(route),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HEADER + TABS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
            ).createShader(r),
            child: const Text(
              'FIGHT CAMP',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: DesignTokens.neonRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: DesignTokens.neonRed.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: DesignTokens.neonRed,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_currentStreak}d streak',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabCtrl,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: DesignTokens.neonCyan,
      unselectedLabelColor: Colors.white38,
      indicatorColor: DesignTokens.neonCyan,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      tabs: const [
        Tab(text: 'LOG'),
        Tab(text: 'CALENDAR'),
        Tab(text: 'ANALYTICS'),
        Tab(text: 'WEIGHT'),
        Tab(text: 'RECOVERY'),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 1: LOG — Today's sessions + add new
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLogTab() {
    final today = DateTime.now();
    final todaySessions =
        _sessions
            .where(
              (s) =>
                  s.date.year == today.year &&
                  s.date.month == today.month &&
                  s.date.day == today.day,
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    final totalMin = todaySessions.fold<int>(
      0,
      (sum, s) => sum + s.durationMin,
    );
    final avgIntensity = todaySessions.isEmpty
        ? 0.0
        : todaySessions.fold<int>(0, (sum, s) => sum + s.intensity) /
              todaySessions.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // ── Today's stats strip ──
        Row(
          children: [
            _miniStat(
              'SESSIONS',
              '${todaySessions.length}',
              DesignTokens.neonCyan,
            ),
            const SizedBox(width: 8),
            _miniStat('TOTAL TIME', '${totalMin}m', DesignTokens.neonGreen),
            const SizedBox(width: 8),
            _miniStat(
              'AVG INTENSITY',
              avgIntensity.toStringAsFixed(1),
              DesignTokens.neonAmber,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Quick-add category grid ──
        const Text(
          'QUICK ADD',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _allCategories.length,
            itemBuilder: (ctx, i) {
              final cat = _allCategories[i];
              return GestureDetector(
                onTap: () => _showAddSessionSheet(preselect: cat),
                child: Container(
                  width: 72,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: cat.color.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(cat.icon, color: cat.color, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        cat.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: cat.color,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // ── Today's sessions ──
        Row(
          children: [
            const Text(
              "TODAY'S LOG",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _showAddSessionSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: DesignTokens.neonCyan, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Add Session',
                      style: TextStyle(
                        color: DesignTokens.neonCyan,
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
        const SizedBox(height: 8),
        if (todaySessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.fitness_center,
                  color: Colors.white.withValues(alpha: 0.15),
                  size: 36,
                ),
                const SizedBox(height: 8),
                Text(
                  'No sessions logged today',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap + to log your first session',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          )
        else
          ...todaySessions.map(_sessionCard),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionCard(_TrainingSession s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: s.category.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: s.category.color.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: s.category.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(s.category.icon, color: s.category.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _sessionChip(
                      '${s.durationMin}m',
                      Icons.timer,
                      Colors.white38,
                    ),
                    const SizedBox(width: 8),
                    _sessionChip(
                      '${s.intensity}/10',
                      Icons.local_fire_department,
                      _intensityColor(s.intensity),
                    ),
                    if (s.distanceKm != null) ...[
                      const SizedBox(width: 8),
                      _sessionChip(
                        '${s.distanceKm!.toStringAsFixed(1)}km',
                        Icons.straighten,
                        DesignTokens.neonCyan,
                      ),
                    ],
                    if (s.speedKmh != null) ...[
                      const SizedBox(width: 8),
                      _sessionChip(
                        '${s.speedKmh!.toStringAsFixed(1)}km/h',
                        Icons.speed,
                        DesignTokens.neonGreen,
                      ),
                    ],
                  ],
                ),
                if (s.notes != null && s.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      s.notes!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Delete button
          GestureDetector(
            onTap: () => setState(() => _sessions.remove(s)),
            child: Icon(
              Icons.close,
              color: Colors.white.withValues(alpha: 0.2),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sessionChip(String text, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _intensityColor(int intensity) {
    if (intensity <= 3) return DesignTokens.neonGreen;
    if (intensity <= 6) return DesignTokens.neonAmber;
    if (intensity <= 8) return _kOrange;
    return DesignTokens.neonRed;
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 2: CALENDAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildCalendarTab() {
    final year = _calViewMonth.year;
    final month = _calViewMonth.month;
    final firstDay = DateTime(year, month);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun

    final selectedSessions = _sessions
        .where(
          (s) =>
              s.date.year == _calSelectedDate.year &&
              s.date.month == _calSelectedDate.month &&
              s.date.day == _calSelectedDate.day,
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // ── Month navigation ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white54),
              onPressed: () => setState(() {
                _calViewMonth = DateTime(year, month - 1);
              }),
            ),
            Text(
              '${_monthName(month)} $year',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white54),
              onPressed: () => setState(() {
                _calViewMonth = DateTime(year, month + 1);
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Day headers ──
        Row(
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),

        // ── Calendar grid ──
        _buildCalendarGrid(year, month, daysInMonth, startWeekday),
        const SizedBox(height: 6),

        // ── Intensity legend ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendDot(Colors.white.withValues(alpha: 0.1), 'Rest'),
            const SizedBox(width: 12),
            _legendDot(DesignTokens.neonGreen, 'Light'),
            const SizedBox(width: 12),
            _legendDot(DesignTokens.neonAmber, 'Medium'),
            const SizedBox(width: 12),
            _legendDot(DesignTokens.neonRed, 'Hard'),
          ],
        ),
        const SizedBox(height: 16),

        // ── Selected day detail ──
        Text(
          _formatDate(_calSelectedDate),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (selectedSessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Rest day — no sessions logged',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
          )
        else
          ...selectedSessions.map(_sessionCard),
      ],
    );
  }

  Widget _buildCalendarGrid(
    int year,
    int month,
    int daysInMonth,
    int startWeekday,
  ) {
    final totalCells = startWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final today = DateTime.now();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final cellIndex = row * 7 + col;
            final day = cellIndex - startWeekday + 1;

            if (day < 1 || day > daysInMonth) {
              return const Expanded(child: SizedBox(height: 40));
            }

            final date = DateTime(year, month, day);
            final daySessions = _sessions
                .where(
                  (s) =>
                      s.date.year == date.year &&
                      s.date.month == date.month &&
                      s.date.day == date.day,
                )
                .toList();

            final isSelected =
                _calSelectedDate.year == date.year &&
                _calSelectedDate.month == date.month &&
                _calSelectedDate.day == date.day;
            final isToday =
                today.year == date.year &&
                today.month == date.month &&
                today.day == date.day;

            Color bgColor;
            if (daySessions.isEmpty) {
              bgColor = Colors.white.withValues(alpha: 0.03);
            } else {
              final maxIntensity = daySessions
                  .map((s) => s.intensity)
                  .reduce(max);
              bgColor = _intensityColor(maxIntensity).withValues(alpha: 0.2);
            }

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _calSelectedDate = date),
                child: Container(
                  height: 40,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? DesignTokens.neonCyan
                          : isToday
                          ? DesignTokens.neonCyan.withValues(alpha: 0.3)
                          : Colors.transparent,
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          color: isSelected
                              ? DesignTokens.neonCyan
                              : Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                      if (daySessions.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            min(daySessions.length, 3),
                            (i) => Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: daySessions[i].category.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 3: ANALYTICS — Graphs from real data
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStatsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // ── Summary cards ──
        Row(
          children: [
            _statCard(
              'TOTAL\nSESSIONS',
              '${_sessions.length}',
              DesignTokens.neonCyan,
            ),
            const SizedBox(width: 8),
            _statCard(
              'TOTAL\nHOURS',
              (_sessions.fold<int>(0, (s, e) => s + e.durationMin) / 60)
                  .toStringAsFixed(1),
              DesignTokens.neonGreen,
            ),
            const SizedBox(width: 8),
            _statCard(
              'AVG\nINTENSITY',
              _sessions.isEmpty
                  ? '0'
                  : (_sessions.fold<int>(0, (s, e) => s + e.intensity) /
                            _sessions.length)
                        .toStringAsFixed(1),
              DesignTokens.neonAmber,
            ),
            const SizedBox(width: 8),
            _statCard('STREAK\nDAYS', '$_currentStreak', DesignTokens.neonRed),
          ],
        ),
        const SizedBox(height: 20),

        // ── Weekly volume chart ──
        const Text(
          'WEEKLY TRAINING VOLUME',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              width: 0.5,
            ),
          ),
          child: CustomPaint(
            size: const Size(double.infinity, 136),
            painter: _WeeklyVolumePainter(_weeklyVolumeData()),
          ),
        ),
        const SizedBox(height: 20),

        // ── Intensity trend ──
        const Text(
          'INTENSITY TREND (LAST 14 DAYS)',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              width: 0.5,
            ),
          ),
          child: CustomPaint(
            size: const Size(double.infinity, 116),
            painter: _IntensityTrendPainter(_intensityTrendData()),
          ),
        ),
        const SizedBox(height: 20),

        // ── Category breakdown ──
        const Text(
          'TRAINING BREAKDOWN',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        ..._categoryBreakdown(),

        const SizedBox(height: 20),

        // ── Distance stats (for cardio) ──
        const Text(
          'CARDIO DISTANCE',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        _buildDistanceStats(),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _categoryBreakdown() {
    final Map<String, int> counts = {};
    final Map<String, int> minutes = {};
    final Map<String, Color> colors = {};
    for (final s in _sessions) {
      counts[s.category.name] = (counts[s.category.name] ?? 0) + 1;
      minutes[s.category.name] =
          (minutes[s.category.name] ?? 0) + s.durationMin;
      colors[s.category.name] = s.category.color;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'No data — log sessions to see breakdown',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 12,
            ),
          ),
        ),
      ];
    }

    final maxCount = sorted.first.value;
    return sorted.map((e) {
      final color = colors[e.key]!;
      final mins = minutes[e.key]!;
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                e.key,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: e.value / maxCount,
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: color.withValues(alpha: 0.5),
                          width: 0.5,
                        ),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        '${e.value}x · ${mins}m',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildDistanceStats() {
    final cardioSessions = _sessions
        .where((s) => s.distanceKm != null)
        .toList();
    if (cardioSessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No distance data — log runs, swims, or sprints',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 12,
          ),
        ),
      );
    }

    final totalDist = cardioSessions.fold<double>(
      0,
      (s, e) => s + e.distanceKm!,
    );
    final avgSpeed =
        cardioSessions
            .where((s) => s.speedKmh != null)
            .fold<double>(0, (s, e) => s + e.speedKmh!) /
        cardioSessions.where((s) => s.speedKmh != null).length;
    final bestSpeed = cardioSessions
        .where((s) => s.speedKmh != null)
        .map((s) => s.speedKmh!)
        .fold<double>(0, max);

    return Row(
      children: [
        _miniStat(
          'TOTAL KM',
          totalDist.toStringAsFixed(1),
          DesignTokens.neonCyan,
        ),
        const SizedBox(width: 8),
        _miniStat(
          'AVG SPEED',
          '${avgSpeed.toStringAsFixed(1)}km/h',
          DesignTokens.neonGreen,
        ),
        const SizedBox(width: 8),
        _miniStat(
          'BEST SPEED',
          '${bestSpeed.toStringAsFixed(1)}km/h',
          DesignTokens.neonRed,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 4: WEIGHT TRACKING
  // ═══════════════════════════════════════════════════════════════

  Widget _buildWeightTab() {
    final sorted = List<_WeightEntry>.from(_weightEntries)
      ..sort((a, b) => b.date.compareTo(a.date));
    final currentW = sorted.isNotEmpty ? sorted.first.weightLbs : 0.0;
    final toCut = currentW - _targetWeight;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // ── Current vs Target ──
        Row(
          children: [
            Expanded(
              child: _weightStatCard(
                'CURRENT',
                '${currentW.toStringAsFixed(1)} lbs',
                DesignTokens.neonCyan,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _weightStatCard(
                'TARGET',
                '${_targetWeight.toStringAsFixed(1)} lbs',
                DesignTokens.neonGreen,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _weightStatCard(
                'TO CUT',
                '${toCut > 0 ? toCut.toStringAsFixed(1) : "0.0"} lbs',
                toCut > 5
                    ? DesignTokens.neonRed
                    : toCut > 2
                    ? DesignTokens.neonAmber
                    : DesignTokens.neonGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Progress bar ──
        if (sorted.length >= 2) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'WEIGHT CUT PROGRESS',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '${((1 - toCut / (sorted.last.weightLbs - _targetWeight)).clamp(0, 1) * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: DesignTokens.neonGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (1 - toCut / (sorted.last.weightLbs - _targetWeight))
                        .clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: const AlwaysStoppedAnimation(
                      DesignTokens.neonGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Weight trend graph ──
        const Text(
          'WEIGHT TREND',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              width: 0.5,
            ),
          ),
          child: CustomPaint(
            size: const Size(double.infinity, 136),
            painter: _WeightTrendPainter(sorted, _targetWeight),
          ),
        ),
        const SizedBox(height: 16),

        // ── Add weight entry ──
        GestureDetector(
          onTap: _showAddWeightDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: DesignTokens.neonCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DesignTokens.neonCyan.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: DesignTokens.neonCyan,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Log Weight',
                  style: TextStyle(
                    color: DesignTokens.neonCyan,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Weight log ──
        const Text(
          'WEIGHT LOG',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        ...sorted.take(10).map((e) {
          final change = sorted.indexOf(e) < sorted.length - 1
              ? e.weightLbs - sorted[sorted.indexOf(e) + 1].weightLbs
              : 0.0;
          return _weightLogRow(e, change);
        }),

        const SizedBox(height: 16),

        // ── Safety warning ──
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DesignTokens.neonRed.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: DesignTokens.neonRed.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: DesignTokens.neonRed,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'SAFETY WARNING',
                    style: TextStyle(
                      color: DesignTokens.neonRed,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Never cut more than 10% of body weight. Consult a medical professional '
                'before any weight cutting program. Rapid dehydration is dangerous.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _weightStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.6),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _weightLogRow(_WeightEntry e, double change) {
    final changeColor = change < 0
        ? DesignTokens.neonGreen
        : change > 0
        ? DesignTokens.neonRed
        : Colors.white38;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            _formatDateShort(e.date),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '${e.weightLbs.toStringAsFixed(1)} lbs',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            change == 0
                ? '—'
                : '${change > 0 ? "+" : ""}${change.toStringAsFixed(1)}',
            style: TextStyle(
              color: changeColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 5: RECOVERY CHECKLIST + HEALTH METRICS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildRecoveryTab() {
    final checklist = _recoveryChecklist;
    final total = checklist.length;
    final checked = _recoveryChecked.values.where((v) => v).length;
    final score = total > 0 ? (checked / total) * 100 : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // ── Recovery score ──
        _buildRecoveryScoreCard(score, checked, total),
        const SizedBox(height: 12),

        // ── Recovery Checklist ──
        _buildSectionLabel('Recovery Checklist', Icons.checklist),
        const SizedBox(height: 6),
        ...checklist.asMap().entries.map(
          (e) => _buildChecklistItem(e.key, e.value, _recoveryChecked),
        ),
        const SizedBox(height: 20),

        // ── Supplementation Tracker ──
        _buildSectionLabel('Supplementation', Icons.medication_liquid),
        const SizedBox(height: 6),
        ..._supplementChecklist.asMap().entries.map(
          (e) => _buildChecklistItem(e.key, e.value, _supplementChecked),
        ),
        const SizedBox(height: 20),

        // ── Blood Work Panel ──
        _buildSectionLabel('Blood Work Results', Icons.bloodtype),
        const SizedBox(height: 6),
        _buildBloodWorkPanel(),
        const SizedBox(height: 20),

        // ── Health Biomarkers ──
        _buildSectionLabel('Health Biomarkers', Icons.monitor_heart),
        const SizedBox(height: 6),
        _buildHealthBiomarkersPanel(),
      ],
    );
  }

  // ── Section label helper ──
  Widget _buildSectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: DesignTokens.neonCyan, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        Container(
          width: 24,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignTokens.neonCyan,
                DesignTokens.neonCyan.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Recovery score card ──
  Widget _buildRecoveryScoreCard(double score, int checked, int total) {
    final color = score > 70
        ? DesignTokens.neonGreen
        : score > 40
        ? DesignTokens.neonAmber
        : DesignTokens.neonRed;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                Text(
                  '${score.round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recovery Score',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  score > 70
                      ? 'Great recovery! Keep it up.'
                      : score > 40
                      ? 'Moderate — complete more items.'
                      : 'Low — prioritize rest & hydration.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$checked/$total',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared checklist item widget ──
  Widget _buildChecklistItem(
    int i,
    (String, IconData, Color) item,
    Map<int, bool> stateMap,
  ) {
    final isChecked = stateMap[i] ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: () => setState(() => stateMap[i] = !isChecked),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isChecked
                ? item.$3.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isChecked
                  ? item.$3.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.06),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isChecked
                      ? item.$3.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isChecked
                        ? item.$3
                        : Colors.white.withValues(alpha: 0.15),
                    width: 0.5,
                  ),
                ),
                child: isChecked
                    ? Icon(Icons.check, color: item.$3, size: 14)
                    : null,
              ),
              const SizedBox(width: 10),
              Icon(item.$2, color: item.$3, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.$1,
                  style: TextStyle(
                    color: isChecked
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BLOOD WORK PANEL
  // ═══════════════════════════════════════════════════════════════

  Widget _buildBloodWorkPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Last test date
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: Colors.white.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 6),
              Text(
                _lastBloodTest != null
                    ? 'Last test: ${_formatDateShort(_lastBloodTest!)}'
                    : 'No blood work recorded yet',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showBloodWorkEntryDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    'Update',
                    style: TextStyle(
                      color: DesignTokens.neonCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Iron level
          _buildBloodMetricRow(
            'Iron',
            _ironLevel == 1
                ? "LOW"
                : _ironLevel == 2
                ? "NORMAL"
                : _ironLevel == 3
                ? "HIGH"
                : "—",
            _ironLevel == 1
                ? DesignTokens.neonRed
                : _ironLevel == 2
                ? DesignTokens.neonGreen
                : _ironLevel == 3
                ? DesignTokens.neonAmber
                : Colors.grey,
            Icons.bloodtype,
            _ironLevel > 0 ? (_ironLevel - 1) / 2.0 : 0,
          ),
          const SizedBox(height: 8),

          // Blood sugar
          _buildBloodMetricRow(
            'Blood Sugar',
            '${_bloodSugar.toStringAsFixed(1)} mmol/L',
            _getMetricColor(_bloodSugar, 3.9, 5.6),
            Icons.water_drop,
            _clampFraction(_bloodSugar, 2.0, 8.0),
          ),
          const SizedBox(height: 8),

          // Hemoglobin
          _buildBloodMetricRow(
            'Hemoglobin',
            '${_hemoglobin.toStringAsFixed(1)} g/dL',
            _getMetricColor(_hemoglobin, 13.5, 17.5),
            Icons.opacity,
            _clampFraction(_hemoglobin, 10.0, 20.0),
          ),
          const SizedBox(height: 8),

          // Vitamin D
          _buildBloodMetricRow(
            'Vitamin D',
            '${_vitaminD.toStringAsFixed(0)} ng/mL',
            _getMetricColor(_vitaminD, 30, 100),
            Icons.wb_sunny,
            _clampFraction(_vitaminD, 0, 120),
          ),
          const SizedBox(height: 8),

          // Testosterone
          _buildBloodMetricRow(
            'Testosterone',
            '${_testosterone.toStringAsFixed(0)} ng/dL',
            _getMetricColor(_testosterone, 300, 1000),
            Icons.trending_up,
            _clampFraction(_testosterone, 100, 1200),
          ),
          const SizedBox(height: 8),

          // Cortisol
          _buildBloodMetricRow(
            'Cortisol',
            '${_cortisol.toStringAsFixed(1)} μg/dL',
            _getMetricColor(_cortisol, 6, 18),
            Icons.speed,
            _clampFraction(_cortisol, 0, 25),
          ),
          const SizedBox(height: 8),

          // CRP / Inflammation
          _buildBloodMetricRow(
            'CRP (Inflammation)',
            '${_crp.toStringAsFixed(1)} mg/L',
            _crp <= 1
                ? DesignTokens.neonGreen
                : _crp <= 3
                ? DesignTokens.neonAmber
                : DesignTokens.neonRed,
            Icons.local_fire_department,
            _clampFraction(_crp, 0, 10),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodMetricRow(
    String label,
    String value,
    Color color,
    IconData icon,
    double progress,
  ) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  minHeight: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Color _getMetricColor(double value, double low, double high) {
    if (value < low) return DesignTokens.neonRed;
    if (value > high) return DesignTokens.neonAmber;
    return DesignTokens.neonGreen;
  }

  double _clampFraction(double value, double min, double max) {
    return ((value - min) / (max - min)).clamp(0, 1);
  }

  // ═══════════════════════════════════════════════════════════════
  //  HEALTH BIOMARKERS PANEL
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHealthBiomarkersPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          // Row 1: Resting HR + HRV
          Row(
            children: [
              Expanded(
                child: _buildBiomarkerTile(
                  'Resting HR',
                  '58',
                  'bpm',
                  Icons.favorite,
                  DesignTokens.neonRed,
                  status: 'Athletic',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBiomarkerTile(
                  'HRV',
                  '62',
                  'ms',
                  Icons.timeline,
                  DesignTokens.neonGreen,
                  status: 'Good',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: Body Temp + SpO2
          Row(
            children: [
              Expanded(
                child: _buildBiomarkerTile(
                  'Body Temp',
                  '36.6',
                  '°C',
                  Icons.thermostat,
                  DesignTokens.neonAmber,
                  status: 'Normal',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBiomarkerTile(
                  'SpO2',
                  '98',
                  '%',
                  Icons.air,
                  DesignTokens.neonCyan,
                  status: 'Optimal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 3: Sleep Quality + Stress
          Row(
            children: [
              Expanded(
                child: _buildBiomarkerTile(
                  'Sleep Quality',
                  '82',
                  '%',
                  Icons.nights_stay,
                  DesignTokens.neonMagenta,
                  status: 'Good',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBiomarkerTile(
                  'Stress Level',
                  '3',
                  '/10',
                  Icons.psychology_alt,
                  DesignTokens.neonGold,
                  status: 'Low',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 4: Body Fat + Hydration Level
          Row(
            children: [
              Expanded(
                child: _buildBiomarkerTile(
                  'Body Fat',
                  '12.4',
                  '%',
                  Icons.accessibility_new,
                  DesignTokens.neonGreen,
                  status: 'Athletic',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBiomarkerTile(
                  'Hydration',
                  '68',
                  '%',
                  Icons.water_drop,
                  DesignTokens.neonBlue,
                  status: 'Adequate',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBiomarkerTile(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color, {
    String? status,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (status != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BLOOD WORK ENTRY DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showBloodWorkEntryDialog() {
    int tempIron = _ironLevel;
    double tempSugar = _bloodSugar;
    double tempHemo = _hemoglobin;
    double tempVitD = _vitaminD;
    double tempTesto = _testosterone;
    double tempCortisol = _cortisol;
    double tempCrp = _crp;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1a1a2e),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.bloodtype, color: DesignTokens.neonRed, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Update Blood Work',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Iron level selector
                    _buildDialogDropdown(
                      'Iron Level',
                      tempIron,
                      {0: 'Not Tested', 1: 'Low', 2: 'Normal', 3: 'High'},
                      (v) => setDialogState(() => tempIron = v),
                    ),
                    const SizedBox(height: 10),
                    _buildDialogSlider(
                      'Blood Sugar',
                      tempSugar,
                      2.0,
                      15.0,
                      'mmol/L',
                      (v) => setDialogState(() => tempSugar = v),
                    ),
                    const SizedBox(height: 10),
                    _buildDialogSlider(
                      'Hemoglobin',
                      tempHemo,
                      8.0,
                      22.0,
                      'g/dL',
                      (v) => setDialogState(() => tempHemo = v),
                    ),
                    const SizedBox(height: 10),
                    _buildDialogSlider(
                      'Vitamin D',
                      tempVitD,
                      0,
                      150,
                      'ng/mL',
                      (v) => setDialogState(() => tempVitD = v),
                    ),
                    const SizedBox(height: 10),
                    _buildDialogSlider(
                      'Testosterone',
                      tempTesto,
                      50,
                      1500,
                      'ng/dL',
                      (v) => setDialogState(() => tempTesto = v),
                    ),
                    const SizedBox(height: 10),
                    _buildDialogSlider(
                      'Cortisol',
                      tempCortisol,
                      0,
                      30,
                      'μg/dL',
                      (v) => setDialogState(() => tempCortisol = v),
                    ),
                    const SizedBox(height: 10),
                    _buildDialogSlider(
                      'CRP',
                      tempCrp,
                      0,
                      15,
                      'mg/L',
                      (v) => setDialogState(() => tempCrp = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.neonCyan.withValues(
                      alpha: 0.2,
                    ),
                    foregroundColor: DesignTokens.neonCyan,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _ironLevel = tempIron;
                      _bloodSugar = tempSugar;
                      _hemoglobin = tempHemo;
                      _vitaminD = tempVitD;
                      _testosterone = tempTesto;
                      _cortisol = tempCortisol;
                      _crp = tempCrp;
                      _lastBloodTest = DateTime.now();
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogDropdown(
    String label,
    int value,
    Map<int, String> options,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: DropdownButton<int>(
            value: value,
            isExpanded: true,
            dropdownColor: const Color(0xFF1a1a2e),
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            items: options.entries
                .map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(
                      e.value,
                      style: TextStyle(
                        color: e.key == 1
                            ? DesignTokens.neonRed
                            : e.key == 2
                            ? DesignTokens.neonGreen
                            : e.key == 3
                            ? DesignTokens.neonAmber
                            : Colors.white60,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDialogSlider(
    String label,
    double value,
    double min,
    double max,
    String unit,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${value.toStringAsFixed(1)} $unit',
              style: const TextStyle(
                color: DesignTokens.neonCyan,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: DesignTokens.neonCyan,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
            thumbColor: DesignTokens.neonCyan,
            overlayColor: DesignTokens.neonCyan.withValues(alpha: 0.1),
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
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ADD SESSION BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════

  void _showAddSessionSheet({_TrainingCategory? preselect}) {
    _TrainingCategory? selectedCat = preselect;
    double intensity = 5;
    final durationCtrl = TextEditingController(text: '30');
    final distanceCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: DesignTokens.bgSecondary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border.all(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'LOG TRAINING SESSION',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Category picker ──
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        const Text(
                          'CATEGORY',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _allCategories.map((cat) {
                            final selected = selectedCat?.name == cat.name;
                            return GestureDetector(
                              onTap: () =>
                                  setSheetState(() => selectedCat = cat),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? cat.color.withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected
                                        ? cat.color
                                        : Colors.white.withValues(alpha: 0.1),
                                    width: selected ? 1.5 : 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      cat.icon,
                                      color: selected
                                          ? cat.color
                                          : Colors.white38,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      cat.name,
                                      style: TextStyle(
                                        color: selected
                                            ? cat.color
                                            : Colors.white54,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // ── Intensity slider ──
                        Row(
                          children: [
                            const Text(
                              'INTENSITY',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${intensity.round()}/10',
                              style: TextStyle(
                                color: _intensityColor(intensity.round()),
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(ctx).copyWith(
                            activeTrackColor: _intensityColor(
                              intensity.round(),
                            ),
                            inactiveTrackColor: Colors.white.withValues(
                              alpha: 0.06,
                            ),
                            thumbColor: _intensityColor(intensity.round()),
                            overlayColor: _intensityColor(
                              intensity.round(),
                            ).withValues(alpha: 0.1),
                          ),
                          child: Slider(
                            value: intensity,
                            min: 1,
                            max: 10,
                            divisions: 9,
                            onChanged: (v) =>
                                setSheetState(() => intensity = v),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Duration + Distance ──
                        Row(
                          children: [
                            Expanded(
                              child: _sheetTextField(
                                durationCtrl,
                                'Duration (min)',
                                Icons.timer,
                              ),
                            ),
                            if (selectedCat?.hasDistance == true) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: _sheetTextField(
                                  distanceCtrl,
                                  'Distance (km)',
                                  Icons.straighten,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ── Notes ──
                        _sheetTextField(
                          notesCtrl,
                          'Notes (optional)',
                          Icons.note,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 20),

                        // ── Submit ──
                        GestureDetector(
                          onTap: () {
                            if (selectedCat == null) return;
                            final dur = int.tryParse(durationCtrl.text) ?? 30;
                            final dist = selectedCat!.hasDistance
                                ? double.tryParse(distanceCtrl.text)
                                : null;
                            setState(() {
                              _sessions.add(
                                _TrainingSession(
                                  category: selectedCat!,
                                  intensity: intensity.round(),
                                  durationMin: dur,
                                  distanceKm: dist,
                                  date: DateTime.now(),
                                  notes: notesCtrl.text.isEmpty
                                      ? null
                                      : notesCtrl.text,
                                ),
                              );
                            });
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: selectedCat != null
                                  ? LinearGradient(
                                      colors: [
                                        selectedCat!.color,
                                        selectedCat!.color.withValues(
                                          alpha: 0.6,
                                        ),
                                      ],
                                    )
                                  : null,
                              color: selectedCat == null
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : null,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              selectedCat != null
                                  ? 'LOG ${selectedCat!.name.toUpperCase()}'
                                  : 'SELECT A CATEGORY',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: selectedCat != null
                                    ? Colors.black
                                    : Colors.white30,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
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
  }

  Widget _sheetTextField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      keyboardType: maxLines == 1 ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
        prefixIcon: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.3),
          size: 18,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DesignTokens.neonCyan),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ADD WEIGHT DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showAddWeightDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Log Weight',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontSize: 18),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Weight in lbs',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
            suffixText: 'lbs',
            suffixStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: DesignTokens.neonCyan),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            ),
          ),
          TextButton(
            onPressed: () {
              final w = double.tryParse(ctrl.text);
              if (w != null && w > 0) {
                setState(() {
                  _weightEntries.add(
                    _WeightEntry(date: DateTime.now(), weightLbs: w),
                  );
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text(
              'Log',
              style: TextStyle(
                color: DesignTokens.neonCyan,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  GRAPH DATA HELPERS
  // ═══════════════════════════════════════════════════════════════

  List<double> _weeklyVolumeData() {
    // Last 7 days — total minutes per day
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return _sessions
          .where(
            (s) =>
                s.date.year == day.year &&
                s.date.month == day.month &&
                s.date.day == day.day,
          )
          .fold<double>(0, (sum, s) => sum + s.durationMin.toDouble());
    });
  }

  List<double> _intensityTrendData() {
    // Last 14 days — avg intensity per day (0 if no sessions)
    final now = DateTime.now();
    return List.generate(14, (i) {
      final day = now.subtract(Duration(days: 13 - i));
      final daySessions = _sessions.where(
        (s) =>
            s.date.year == day.year &&
            s.date.month == day.month &&
            s.date.day == day.day,
      );
      if (daySessions.isEmpty) return 0.0;
      return daySessions.fold<int>(0, (s, e) => s + e.intensity) /
          daySessions.length;
    });
  }

  int get _currentStreak {
    final now = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final day = now.subtract(Duration(days: i));
      final hasSessions = _sessions.any(
        (s) =>
            s.date.year == day.year &&
            s.date.month == day.month &&
            s.date.day == day.day,
      );
      if (hasSessions) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }

  // ═══════════════════════════════════════════════════════════════
  //  FORMATTING HELPERS
  // ═══════════════════════════════════════════════════════════════

  String _monthName(int month) {
    const names = [
      '',
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];
    return names[month];
  }

  String _formatDate(DateTime d) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      '',
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
    return '${days[d.weekday - 1]}, ${months[d.month]} ${d.day}';
  }

  String _formatDateShort(DateTime d) {
    final months = [
      '',
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
    return '${months[d.month]} ${d.day}';
  }

  // ═══════════════════════════════════════════════════════════════
  //  RECOVERY CHECKLIST DATA
  // ═══════════════════════════════════════════════════════════════

  static const List<(String, IconData, Color)> _recoveryChecklist = [
    ('Sleep 8+ Hours', Icons.bedtime, DesignTokens.neonMagenta),
    ('Hydration (3.8 L)', Icons.water_drop, DesignTokens.neonCyan),
    ('Protein Intake (180g)', Icons.restaurant, DesignTokens.neonGreen),
    ('Stretching / Mobility', Icons.self_improvement, DesignTokens.neonAmber),
    ('Ice Bath / Cold Therapy', Icons.ac_unit, _kBlue),
    ('Foam Rolling', Icons.sports_gymnastics, DesignTokens.neonGold),
    ('Mental Visualization', Icons.psychology, DesignTokens.neonMagenta),
    ('No Alcohol / No Junk', Icons.no_food, DesignTokens.neonRed),
  ];

  // ═══════════════════════════════════════════════════════════════
  //  SUPPLEMENTATION CHECKLIST DATA
  // ═══════════════════════════════════════════════════════════════

  static const List<(String, IconData, Color)> _supplementChecklist = [
    ('Multivitamin', Icons.medication, DesignTokens.neonCyan),
    ('Omega-3 / Fish Oil', Icons.water, DesignTokens.neonBlue),
    ('Vitamin D3', Icons.wb_sunny, DesignTokens.neonAmber),
    ('Magnesium', Icons.bedtime, DesignTokens.neonMagenta),
    ('Creatine (5g)', Icons.fitness_center, DesignTokens.neonGreen),
    ('Protein Shake', Icons.blender, DesignTokens.neonGold),
    ('Iron Supplement', Icons.bloodtype, DesignTokens.neonRed),
    ('Electrolytes', Icons.bolt, DesignTokens.neonCyan),
    ('Zinc', Icons.shield, DesignTokens.neonAmber),
    ('BCAAs / EAAs', Icons.science, DesignTokens.neonGreen),
  ];

  // ═══════════════════════════════════════════════════════════════
  //  SEED DATA — 14 days of training for demonstration
  // ═══════════════════════════════════════════════════════════════

  void _seedData() {
    final now = DateTime.now();
    final rng = Random(42);
    final cats = _allCategories;

    // Generate 2-4 sessions per day for the last 14 days
    for (int d = 13; d >= 0; d--) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: d));
      final sessionCount = rng.nextInt(3) + 2; // 2-4 sessions
      for (int s = 0; s < sessionCount; s++) {
        final cat = cats[rng.nextInt(cats.length)];
        final intensity = rng.nextInt(7) + 3; // 3-9
        final duration = (rng.nextInt(4) + 2) * 15; // 30-75 min
        _sessions.add(
          _TrainingSession(
            category: cat,
            intensity: intensity,
            durationMin: duration,
            distanceKm: cat.hasDistance ? (rng.nextDouble() * 8 + 2) : null,
            date: day.add(Duration(hours: 6 + s * 3, minutes: rng.nextInt(30))),
          ),
        );
      }
    }

    // Weight entries — gradual cut over 14 days
    for (int d = 13; d >= 0; d--) {
      final day = now.subtract(Duration(days: d));
      _weightEntries.add(
        _WeightEntry(
          date: day,
          weightLbs: 168.0 - (13 - d) * 0.4 + rng.nextDouble() * 0.6 - 0.3,
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════════

class _WeeklyVolumePainter extends CustomPainter {
  final List<double> data;
  _WeeklyVolumePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = data.reduce(max).clamp(1.0, double.infinity);
    final barWidth = size.width / (data.length * 2 - 1);
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    for (int i = 0; i < data.length; i++) {
      final x = i * barWidth * 2;
      final barH = (data[i] / maxVal) * (size.height - 16);
      final y = size.height - 16 - barH;

      // Determine bar color by volume
      final color = data[i] > 90
          ? DesignTokens.neonRed
          : data[i] > 60
          ? DesignTokens.neonAmber
          : DesignTokens.neonCyan;

      final barPaint = Paint()..color = color.withValues(alpha: 0.6);
      final borderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barH),
        const Radius.circular(4),
      );
      canvas.drawRRect(barRect, barPaint);
      canvas.drawRRect(barRect, borderPaint);

      // Value label
      if (data[i] > 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${data[i].round()}m',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 8,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x + (barWidth - tp.width) / 2, y - 12));
      }

      // Day label
      final dayTp = TextPainter(
        text: TextSpan(
          text: days[i % 7],
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      dayTp.paint(
        canvas,
        Offset(x + (barWidth - dayTp.width) / 2, size.height - 12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _IntensityTrendPainter extends CustomPainter {
  final List<double> data;
  _IntensityTrendPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final linePaint = Paint()
      ..color = DesignTokens.neonAmber.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          DesignTokens.neonAmber.withValues(alpha: 0.15),
          DesignTokens.neonAmber.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = data.length > 1
          ? (i / (data.length - 1)) * size.width
          : size.width / 2;
      final y = size.height - (data[i] / 10.0) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      // Data point dot
      if (data[i] > 0) {
        canvas.drawCircle(
          Offset(x, y),
          3,
          Paint()..color = DesignTokens.neonAmber,
        );
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Grid lines at intensity 3, 5, 7
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;
    for (final val in [3, 5, 7]) {
      final y = size.height - (val / 10.0) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _WeightTrendPainter extends CustomPainter {
  final List<_WeightEntry> entries;
  final double target;
  _WeightTrendPainter(this.entries, this.target);

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final weights = entries.map((e) => e.weightLbs).toList();
    final allVals = [...weights, target];
    final minW = allVals.reduce(min) - 2;
    final maxW = allVals.reduce(max) + 2;
    final range = maxW - minW;
    if (range == 0) return;

    // Line
    final linePaint = Paint()
      ..color = DesignTokens.neonCyan.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          DesignTokens.neonCyan.withValues(alpha: 0.12),
          DesignTokens.neonCyan.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < weights.length; i++) {
      final x = weights.length > 1
          ? (i / (weights.length - 1)) * size.width
          : size.width / 2;
      final y = size.height - ((weights[i] - minW) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()..color = DesignTokens.neonCyan,
      );
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Target line
    final targetY = size.height - ((target - minW) / range) * size.height;
    final dashPaint = Paint()
      ..color = DesignTokens.neonGreen.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    // Dashed line
    const dashW = 6.0;
    const gapW = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, targetY),
        Offset(min(startX + dashW, size.width), targetY),
        dashPaint,
      );
      startX += dashW + gapW;
    }

    // Target label
    final tp = TextPainter(
      text: TextSpan(
        text: '${target.round()} lbs (target)',
        style: TextStyle(
          color: DesignTokens.neonGreen.withValues(alpha: 0.6),
          fontSize: 8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width - tp.width - 4, targetY - 12));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
