import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/combat_analytics_charts.dart';
import '../../../shared/widgets/dfc_section_title.dart';

/// COMBAT ANALYTICS v4.0 — With Full Session Input System
/// Users can log training: sparring, bag work, pad work, sprints, drills, etc.
class CombatAnalyticsScreen extends StatefulWidget {
  const CombatAnalyticsScreen({super.key});

  @override
  State<CombatAnalyticsScreen> createState() => _CombatAnalyticsScreenState();
}

class _CombatAnalyticsScreenState extends State<CombatAnalyticsScreen>
    with TickerProviderStateMixin {
  int _selectedTimeframe = 0;
  late AnimationController _bgCtrl;

  // ── USER SESSIONS (mutable — new sessions get added here) ──
  final List<CombatSession> _dailySessions = [
    const CombatSession(
      label: 'Morning Sparring',
      type: 'sparring',
      intensity: 0.85,
      duration: 0.06,
      timeOfDay: 0.30,
    ),
    const CombatSession(
      label: 'Jiu-Jitsu Drilling',
      type: 'grappling',
      intensity: 0.55,
      duration: 0.05,
      timeOfDay: 0.42,
    ),
    const CombatSession(
      label: 'Strength & Conditioning',
      type: 'conditioning',
      intensity: 0.92,
      duration: 0.04,
      timeOfDay: 0.56,
    ),
    const CombatSession(
      label: 'Recovery Yoga',
      type: 'recovery',
      intensity: 0.25,
      duration: 0.035,
      timeOfDay: 0.70,
    ),
    const CombatSession(
      label: 'Pad Work',
      type: 'pad_work',
      intensity: 0.70,
      duration: 0.04,
      timeOfDay: 0.80,
    ),
  ];

  // ── WEEKLY: computed from daily sessions ──
  late List<WeeklyCategory> _weeklyCategories;

  late List<DailySummary> _monthlyData;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _recomputeDerived();
    _loadSessionsFromFirestore();
  }

  Future<void> _loadSessionsFromFirestore() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final snap = await FirebaseFirestore.instance
          .collection('training_sessions')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      if (snap.docs.isEmpty) return;
      final loaded = snap.docs.map((d) {
        final data = d.data();
        return CombatSession(
          label: data['label'] ?? '',
          type: data['type'] ?? 'conditioning',
          intensity: (data['intensity'] as num?)?.toDouble() ?? 0.5,
          duration: (data['duration'] as num?)?.toDouble() ?? 0.04,
          timeOfDay: (data['timeOfDay'] as num?)?.toDouble() ?? 0.5,
        );
      }).toList();
      if (mounted && loaded.isNotEmpty) {
        setState(() {
          _dailySessions
            ..clear()
            ..addAll(loaded);
          _recomputeDerived();
        });
      }
    } catch (_) {
      // Firestore unavailable — keep defaults
    }
  }

  /// Map a session type to its weekly category.
  static String _categoryForType(String type) {
    switch (type) {
      case 'sparring':
      case 'bag_work':
      case 'pad_work':
      case 'shadowboxing':
      case 'clinch':
        return 'Striking';
      case 'grappling':
      case 'drilling':
        return 'Grappling';
      case 'conditioning':
      case 'sprints':
      case 'roadwork':
        return 'Conditioning';
      case 'recovery':
      case 'yoga':
        return 'Recovery';
      default:
        return 'Conditioning';
    }
  }

  static Color _categoryColor(String cat) {
    switch (cat) {
      case 'Striking':
        return const Color(0xFFFF3366);
      case 'Grappling':
        return AppColors.neonBlue;
      case 'Conditioning':
        return Colors.orange;
      case 'Recovery':
        return AppTheme.neonGreen;
      default:
        return Colors.grey;
    }
  }

  /// Recompute weekly categories & monthly summaries from _dailySessions.
  void _recomputeDerived() {
    // ── Weekly categories ──
    final catHours = <String, double>{};
    final catPeakIntensity = <String, double>{};
    for (final cat in ['Striking', 'Grappling', 'Conditioning', 'Recovery']) {
      catHours[cat] = 0;
      catPeakIntensity[cat] = 0;
    }

    for (final s in _dailySessions) {
      final cat = _categoryForType(s.type);
      final hrs = s.duration * 24;
      catHours[cat] = (catHours[cat] ?? 0) + hrs;
      catPeakIntensity[cat] = math.max(catPeakIntensity[cat] ?? 0, s.intensity);
    }

    final totalHrs = catHours.values.fold(0.0, (a, b) => a + b);

    _weeklyCategories = catHours.entries.where((e) => e.value > 0).map((e) {
      final dailyInts = List<double>.filled(7, 0.0);
      // Place today's peak intensity in the last slot (day 7)
      dailyInts[6] = catPeakIntensity[e.key] ?? 0;
      return WeeklyCategory(
        label: e.key,
        color: _categoryColor(e.key),
        totalHours: double.parse(e.value.toStringAsFixed(1)),
        percentage: totalHrs > 0 ? e.value / totalHrs : 0,
        dailyIntensities: dailyInts,
      );
    }).toList();

    if (_weeklyCategories.isEmpty) {
      _weeklyCategories = [
        WeeklyCategory(
          label: 'No Data',
          color: Colors.grey,
          totalHours: 0,
          percentage: 1.0,
          dailyIntensities: List.filled(7, 0.0),
        ),
      ];
    }

    // ── Monthly summaries (30 days) ──
    final avgDailyLoad = _dailySessions.isEmpty
        ? 0.4
        : _dailySessions.map((s) => s.intensity).reduce((a, b) => a + b) /
              _dailySessions.length;
    final sessionCount = _dailySessions.length;
    final rng = math.Random(42);

    _monthlyData = List.generate(30, (i) {
      if (i == 29) {
        // Today — use actual session data
        final load = avgDailyLoad.clamp(0.0, 1.0);
        final recovery = (1.0 - load * 0.6).clamp(0.0, 1.0);
        return DailySummary(
          load: load,
          recovery: recovery,
          isBreakthrough: sessionCount >= 5 && avgDailyLoad > 0.7,
          isInjuryRisk: sessionCount >= 4 && avgDailyLoad > 0.85,
          dayLabel: '${i + 1}',
        );
      }
      // Historical — plausible variation scaled to actual training intensity
      final dayInCycle = i % 7;
      final isDeload = dayInCycle >= 5;
      final baseLoad = isDeload
          ? avgDailyLoad * 0.4
          : avgDailyLoad * (0.7 + (dayInCycle / 5) * 0.5);
      final load = (baseLoad + rng.nextDouble() * 0.15).clamp(0.0, 1.0);
      final recovery = (1.0 - load * 0.6 + rng.nextDouble() * 0.2).clamp(
        0.0,
        1.0,
      );
      return DailySummary(
        load: load,
        recovery: recovery,
        isBreakthrough: i == 4 || i == 18,
        isInjuryRisk: i == 11 || i == 25,
        dayLabel: '${i + 1}',
      );
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      floatingActionButton: _buildLogSessionFAB(),
      body: Stack(
        children: [
          _buildAnimatedBg(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(child: _buildTimeframeToggle()),
                SliverToBoxAdapter(child: _buildActiveChart()),
                SliverToBoxAdapter(child: _buildInsightCard()),
                SliverToBoxAdapter(child: _buildMiniMetrics()),
                SliverToBoxAdapter(child: _buildBreakdownTable()),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //
  // LOG SESSION FAB + BOTTOM SHEET
  //

  Widget _buildLogSessionFAB() {
    return FloatingActionButton.extended(
      onPressed: _showLogSessionSheet,
      backgroundColor: DesignTokens.neonCyan,
      foregroundColor: DesignTokens.bgPrimary,
      icon: const Icon(Icons.add, size: 20),
      label: const Text(
        'LOG SESSION',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showLogSessionSheet() {
    String selectedType = 'sparring';
    double rpe = 7.0;
    int durationMin = 30;
    final notesController = TextEditingController();
    final labelController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: const BoxDecoration(
                color: DesignTokens.bgSecondary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: DesignTokens.textDisabled,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  DesignTokens.neonCyan,
                                  DesignTokens.neonMagenta,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.fitness_center,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LOG TRAINING SESSION',
                                style: TextStyle(
                                  color: DesignTokens.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Record your work \u2014 track your progress',
                                style: TextStyle(
                                  color: DesignTokens.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // SESSION NAME
                      const Text(
                        'SESSION NAME',
                        style: TextStyle(
                          color: DesignTokens.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: labelController,
                        style: const TextStyle(
                          color: DesignTokens.textPrimary,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'e.g. Evening Sparring, Bag Work Session...',
                          hintStyle: const TextStyle(
                            color: DesignTokens.textDisabled,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: DesignTokens.bgCard,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: DesignTokens.textDisabled.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: DesignTokens.textDisabled.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: DesignTokens.neonCyan,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // TRAINING TYPE
                      const Text(
                        'TRAINING TYPE',
                        style: TextStyle(
                          color: DesignTokens.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _trainingTypes.map((t) {
                          final isActive = t.key == selectedType;
                          return GestureDetector(
                            onTap: () =>
                                setSheetState(() => selectedType = t.key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? t.color.withValues(alpha: 0.15)
                                    : DesignTokens.bgCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isActive
                                      ? t.color
                                      : DesignTokens.textDisabled.withValues(
                                          alpha: 0.12,
                                        ),
                                  width: isActive ? 1.5 : 1,
                                ),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: t.color.withValues(
                                            alpha: 0.15,
                                          ),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    t.icon,
                                    color: isActive
                                        ? t.color
                                        : DesignTokens.textMuted,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    t.label,
                                    style: TextStyle(
                                      color: isActive
                                          ? t.color
                                          : DesignTokens.textSecondary,
                                      fontSize: 13,
                                      fontWeight: isActive
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      // INTENSITY / RPE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'INTENSITY (RPE)',
                            style: TextStyle(
                              color: DesignTokens.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _rpeColor(rpe).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _rpeColor(rpe).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '${rpe.toStringAsFixed(1)} / 10',
                              style: TextStyle(
                                color: _rpeColor(rpe),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 6,
                          activeTrackColor: _rpeColor(rpe),
                          inactiveTrackColor: DesignTokens.bgCard,
                          thumbColor: _rpeColor(rpe),
                          overlayColor: _rpeColor(rpe).withValues(alpha: 0.15),
                          thumbShape: const RoundSliderThumbShape(
                            
                          ),
                        ),
                        child: Slider(
                          value: rpe,
                          min: 1,
                          max: 10,
                          divisions: 18,
                          onChanged: (v) => setSheetState(() => rpe = v),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Easy',
                              style: TextStyle(
                                color: DesignTokens.neonGreen.withValues(
                                  alpha: 0.6,
                                ),
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              'Moderate',
                              style: TextStyle(
                                color: DesignTokens.neonAmber.withValues(
                                  alpha: 0.6,
                                ),
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              'Max Effort',
                              style: TextStyle(
                                color: DesignTokens.neonRed.withValues(
                                  alpha: 0.6,
                                ),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // DURATION
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'DURATION',
                            style: TextStyle(
                              color: DesignTokens.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            '$durationMin min',
                            style: const TextStyle(
                              color: DesignTokens.neonCyan,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [15, 20, 30, 45, 60, 90, 120].map((mins) {
                          final isActive = durationMin == mins;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setSheetState(() => durationMin = mins),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? DesignTokens.neonCyan.withValues(
                                          alpha: 0.15,
                                        )
                                      : DesignTokens.bgCard,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isActive
                                        ? DesignTokens.neonCyan.withValues(
                                            alpha: 0.5,
                                          )
                                        : DesignTokens.textDisabled.withValues(
                                            alpha: 0.1,
                                          ),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${mins}m',
                                    style: TextStyle(
                                      color: isActive
                                          ? DesignTokens.neonCyan
                                          : DesignTokens.textMuted,
                                      fontSize: 12,
                                      fontWeight: isActive
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // NOTES
                      const Text(
                        'NOTES (optional)',
                        style: TextStyle(
                          color: DesignTokens.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        style: const TextStyle(
                          color: DesignTokens.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'How did it go? What did you work on...',
                          hintStyle: const TextStyle(
                            color: DesignTokens.textDisabled,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: DesignTokens.bgCard,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: DesignTokens.textDisabled.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: DesignTokens.textDisabled.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: DesignTokens.neonCyan,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // SAVE BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            final label = labelController.text.trim().isEmpty
                                ? _trainingTypes
                                      .firstWhere((t) => t.key == selectedType)
                                      .label
                                : labelController.text.trim();

                            final now = DateTime.now();
                            final todFraction =
                                (now.hour * 60 + now.minute) / 1440.0;

                            setState(() {
                              _dailySessions.add(
                                CombatSession(
                                  label: label,
                                  type: selectedType,
                                  intensity: rpe / 10.0,
                                  duration: durationMin / 1440.0,
                                  timeOfDay: todFraction,
                                ),
                              );
                              _recomputeDerived();
                            });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: DesignTokens.neonGreen,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '$label logged \u2014 RPE ${rpe.toStringAsFixed(1)}, ${durationMin}min',
                                    ),
                                  ],
                                ),
                                backgroundColor: DesignTokens.bgCard,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignTokens.neonCyan,
                            foregroundColor: DesignTokens.bgPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_alt, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'SAVE SESSION',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
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
            );
          },
        );
      },
    );
  }

  Color _rpeColor(double rpe) {
    if (rpe <= 3) return DesignTokens.neonGreen;
    if (rpe <= 5) return DesignTokens.neonCyan;
    if (rpe <= 7) return DesignTokens.neonAmber;
    if (rpe <= 8.5) return const Color(0xFFFF8800);
    return DesignTokens.neonRed;
  }

  //
  // TRAINING TYPE DEFINITIONS
  //

  static final _trainingTypes = [
    const _TrainingType(
      'sparring',
      'Sparring',
      Icons.sports_mma,
      Color(0xFFFF3366),
    ),
    const _TrainingType(
      'bag_work',
      'Bag Work',
      Icons.sports_martial_arts,
      DesignTokens.neonAmber,
    ),
    const _TrainingType(
      'pad_work',
      'Pad Work',
      Icons.front_hand,
      Color(0xFFFF8800),
    ),
    const _TrainingType(
      'grappling',
      'Grappling',
      Icons.accessibility_new,
      AppColors.neonBlue,
    ),
    const _TrainingType('drilling', 'Drilling', Icons.loop, DesignTokens.neonCyan),
    const _TrainingType('conditioning', 'S&C', Icons.fitness_center, Colors.orange),
    const _TrainingType(
      'sprints',
      'Sprints',
      Icons.directions_run,
      DesignTokens.neonMagenta,
    ),
    const _TrainingType('roadwork', 'Roadwork', Icons.route, Color(0xFF9C27B0)),
    const _TrainingType(
      'clinch',
      'Clinch Work',
      Icons.people,
      Color(0xFF26C6DA),
    ),
    const _TrainingType(
      'shadowboxing',
      'Shadow Boxing',
      Icons.blur_on,
      DesignTokens.neonGreen,
    ),
    const _TrainingType(
      'recovery',
      'Recovery',
      Icons.self_improvement,
      DesignTokens.neonGreen,
    ),
    const _TrainingType('yoga', 'Yoga', Icons.spa, Color(0xFF66BB6A)),
  ];

  //
  // ORIGINAL UI METHODS (unchanged logic)
  //

  Widget _buildAnimatedBg() {
    return AnimatedBuilder(
      animation: _bgCtrl,
      builder: (context, _) {
        return CustomPaint(
          painter: _AnalyticsBgPainter(_bgCtrl.value),
          size: Size.infinite,
        );
      },
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white70,
          size: 18,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const DfcSectionTitle(
        title: 'COMBAT ANALYTICS',
        icon: Icons.analytics,
        iconSize: 20,
        fontSize: 15,
        letterSpacing: 2.5,
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            Icons.share_outlined,
            color: Colors.white.withValues(alpha: 0.4),
            size: 18,
          ),
          onPressed: () {
            SharePlus.instance.share(
              ShareParams(
                text: 'Check out my combat analytics on Data Fight Central\n'
                    'https://datafightcentral.web.app',
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimeframeToggle() {
    final labels = ['DAILY', 'WEEKLY', 'MONTHLY'];
    final icons = [Icons.today, Icons.date_range, Icons.calendar_month];
    final colors = [
      AppTheme.neonCyan,
      AppColors.neonPurple,
      AppColors.neonPink,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: List.generate(3, (i) {
            final isSelected = _selectedTimeframe == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTimeframe = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors[i].withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(13),
                    border: isSelected
                        ? Border.all(color: colors[i].withValues(alpha: 0.3))
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colors[i].withValues(alpha: 0.1),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icons[i],
                        size: 14,
                        color: isSelected
                            ? colors[i]
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        labels[i],
                        style: TextStyle(
                          color: isSelected
                              ? colors[i]
                              : Colors.white.withValues(alpha: 0.3),
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildActiveChart() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _GlassPanel(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOutCubic,
          child: _selectedTimeframe == 0
              ? _buildDailyChart()
              : _selectedTimeframe == 1
              ? _buildWeeklyChart()
              : _buildMonthlyChart(),
        ),
      ),
    );
  }

  Widget _buildDailyChart() {
    return Column(
      key: const ValueKey('daily'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CombatPulseTimeline(
          sessions: _dailySessions,
          overallReadiness: _calcReadiness(),
        ),
        const SizedBox(height: 16),
        ...(_dailySessions.map(_buildSessionTile)),
      ],
    );
  }

  double _calcReadiness() {
    if (_dailySessions.isEmpty) return 0.5;
    final avgInt =
        _dailySessions.map((s) => s.intensity).reduce((a, b) => a + b) /
        _dailySessions.length;
    return (1.0 - avgInt * 0.3).clamp(0.1, 1.0);
  }

  Widget _buildSessionTile(CombatSession session) {
    final color = _typeColor(session.type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _getTypeLabel(session.type).toUpperCase(),
                    style: TextStyle(
                      color: color.withValues(alpha: 0.6),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(session.intensity * 100).round()}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: session.intensity,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Column(
      key: const ValueKey('weekly'),
      children: [
        Row(
          children: [
            const Icon(Icons.blur_circular, color: AppColors.neonPurple, size: 18),
            const SizedBox(width: 8),
            const Text(
              'TRAINING ORBITS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            Text(
              'THIS WEEK',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OrbitalTrainingPie(categories: _weeklyCategories, totalHours: 24.4),
        const SizedBox(height: 12),
        _buildWeekDayBar(),
      ],
    );
  }

  Widget _buildWeekDayBar() {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final dailyTotals = List.generate(7, (d) {
      return _weeklyCategories.fold(
        0.0,
        (acc, cat) => acc + cat.dailyIntensities[d],
      );
    });
    final maxTotal = dailyTotals
        .reduce((a, b) => a > b ? a : b)
        .clamp(0.1, double.infinity);

    return Row(
      children: List.generate(7, (i) {
        final normalized = dailyTotals[i] / maxTotal;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              children: [
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: normalized,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppTheme.neonCyan.withValues(alpha: 0.3),
                              AppColors.neonPurple.withValues(alpha: 0.6),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.neonCyan.withValues(alpha: 0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  days[i],
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.25),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMonthlyChart() {
    return Column(
      key: const ValueKey('monthly'),
      children: [
        DNAHelixChart(
          days: _monthlyData,
          currentLoad: 0.72,
          currentRecovery: 0.65,
        ),
      ],
    );
  }

  Widget _buildInsightCard() {
    final weeklyHrs = _weeklyCategories.fold(0.0, (s, c) => s + c.totalHours);
    final topCat = _weeklyCategories.isNotEmpty
        ? (_weeklyCategories.toList()
                ..sort((a, b) => b.totalHours.compareTo(a.totalHours)))
              .first
              .label
        : 'N/A';
    final breakthroughs = _monthlyData.where((d) => d.isBreakthrough).length;
    final avgMonthLoad = _monthlyData.isEmpty
        ? 0.0
        : _monthlyData.map((d) => d.load).reduce((a, b) => a + b) /
              _monthlyData.length;

    final insights = [
      (
        AppTheme.neonCyan,
        _dailySessions.isEmpty
            ? 'Log your first session to unlock AI-driven insights.'
            : 'You logged ${_dailySessions.length} sessions today. ${_dailySessions.length >= 4 ? "Strong volume \u2014 watch recovery." : "Room for more work if energy allows."}',
      ),
      (
        AppColors.neonPurple,
        weeklyHrs > 0
            ? '$topCat dominates at ${weeklyHrs.toStringAsFixed(1)} total hrs across ${_weeklyCategories.where((c) => c.totalHours > 0).length} categories. ${_weeklyCategories.length >= 3 ? 'Good training diversity.' : 'Consider adding more variety.'}'
            : 'No sessions logged yet this week. Start training to see orbital analytics.',
      ),
      (
        AppColors.neonPink,
        breakthroughs > 0
            ? 'Training DNA shows $breakthroughs breakthrough${breakthroughs > 1 ? 's' : ''} this month. Avg load ${(avgMonthLoad * 100).round()}% \u2014 ${avgMonthLoad > 0.65 ? 'recovery strand needs attention.' : 'recovery alignment is strong.'}'
            : 'No breakthroughs detected yet. Consistent training unlocks DNA pattern analysis.',
      ),
    ];

    final (color, insight) = insights[_selectedTimeframe];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: _GlassPanel(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.auto_awesome, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI INSIGHT',
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMetrics() {
    final sessionCount = _dailySessions.length;
    final peakRpe = _dailySessions.isEmpty
        ? 0.0
        : _dailySessions
                  .map((s) => s.intensity)
                  .reduce((a, b) => a > b ? a : b) *
              10;
    final totalHrs =
        _dailySessions.fold(0.0, (acc, s) => acc + s.duration) * 24;
    final readiness = (_calcReadiness() * 100).round();

    final metrics = _selectedTimeframe == 0
        ? [
            ('Sessions', '$sessionCount', AppTheme.neonCyan),
            ('Peak RPE', peakRpe.toStringAsFixed(1), const Color(0xFFFF3366)),
            ('Total Hrs', totalHrs.toStringAsFixed(1), AppTheme.neonGreen),
            ('Readiness', '$readiness%', Colors.amber),
          ]
        : _selectedTimeframe == 1
        ? () {
            final wkHrs = _weeklyCategories.fold(
              0.0,
              (s, c) => s + c.totalHours,
            );
            final avgRpe = _dailySessions.isEmpty
                ? 0.0
                : _dailySessions
                          .map((s) => s.intensity * 10)
                          .reduce((a, b) => a + b) /
                      _dailySessions.length;
            final restDays = 7 - (_dailySessions.isEmpty ? 0 : 1);
            final catCount = _weeklyCategories
                .where((c) => c.totalHours > 0)
                .length;
            return <(String, String, Color)>[
              ('Total Hrs', wkHrs.toStringAsFixed(1), AppTheme.neonCyan),
              ('Avg RPE', avgRpe.toStringAsFixed(1), Colors.amber),
              ('Rest Days', '$restDays', AppTheme.neonGreen),
              ('Categories', '$catCount', AppColors.neonPurple),
            ];
          }()
        : () {
            final trainDays = _monthlyData.where((d) => d.load > 0.2).length;
            final avgLoad = _monthlyData.isEmpty
                ? 0.0
                : _monthlyData.map((d) => d.load).reduce((a, b) => a + b) /
                      _monthlyData.length;
            final prs = _monthlyData.where((d) => d.isBreakthrough).length;
            final risks = _monthlyData.where((d) => d.isInjuryRisk).length;
            return <(String, String, Color)>[
              ('Train Days', '$trainDays', AppTheme.neonCyan),
              ('Avg Load', '${(avgLoad * 100).round()}%', Colors.amber),
              ('PRs Hit', '$prs', AppTheme.neonGreen),
              ('Injury Risk', '$risks', const Color(0xFFFF3366)),
            ];
          }();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: metrics.map((m) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _GlassPanel(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Column(
                  children: [
                    Text(
                      m.$2,
                      style: TextStyle(
                        color: m.$3,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.$1,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBreakdownTable() {
    List<(String, String, String, Color)> rows;

    if (_selectedTimeframe == 0) {
      // Build from actual session data
      final typeMap = <String, List<CombatSession>>{};
      for (final s in _dailySessions) {
        typeMap.putIfAbsent(s.type, () => []).add(s);
      }
      rows = typeMap.entries.map((e) {
        final count = e.value.length;
        final avgRpe =
            e.value.map((s) => s.intensity * 10).reduce((a, b) => a + b) /
            count;
        return (
          _getTypeLabel(e.key),
          '$count session${count > 1 ? 's' : ''}',
          'RPE ${avgRpe.toStringAsFixed(1)}',
          _typeColor(e.key),
        );
      }).toList();
    } else if (_selectedTimeframe == 1) {
      rows = _weeklyCategories.map((c) {
        return (
          c.label,
          '${c.totalHours.toStringAsFixed(1)} hrs',
          '${(c.percentage * 100).round()}%',
          c.color,
        );
      }).toList();
    } else {
      // Compute 4-week periodization from monthly data
      rows = List.generate(4, (w) {
        final start = w * 7;
        final end = math.min(start + 7, _monthlyData.length);
        if (start >= _monthlyData.length) {
          return ('Week ${w + 1}', 'N/A', '--', Colors.grey);
        }
        final week = _monthlyData.sublist(start, end);
        final avgLoad =
            week.map((d) => d.load).reduce((a, b) => a + b) / week.length;
        final prevAvg = w > 0
            ? () {
                final ps = (w - 1) * 7;
                final pe = math.min(w * 7, _monthlyData.length);
                final pw = _monthlyData.sublist(ps, pe);
                return pw.map((d) => d.load).reduce((a, b) => a + b) /
                    pw.length;
              }()
            : avgLoad;
        final change = w > 0
            ? ((avgLoad - prevAvg) / prevAvg * 100).round()
            : 0;
        final phase = avgLoad > 0.65
            ? 'Peak'
            : avgLoad > 0.45
            ? 'Build'
            : 'Deload';
        final changeStr = w == 0
            ? 'Base'
            : '${change >= 0 ? '\u2191' : '\u2193'} ${change.abs()}%';
        final color = avgLoad > 0.65
            ? AppColors.neonPurple
            : avgLoad > 0.45
            ? AppTheme.neonCyan
            : AppTheme.neonGreen;
        return ('Week ${w + 1}', phase, changeStr, color);
      });
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: _GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedTimeframe == 2 ? 'PERIODIZATION' : 'BREAKDOWN',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            ...rows.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 20,
                      decoration: BoxDecoration(
                        color: r.$4,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: r.$4.withValues(alpha: 0.4),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        r.$1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      r.$2,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: r.$4.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        r.$3,
                        style: TextStyle(
                          color: r.$4,
                          fontSize: 10,
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
      ),
    );
  }

  Color _typeColor(String type) {
    for (final t in _trainingTypes) {
      if (t.key == type) return t.color;
    }
    switch (type) {
      case 'striking':
        return const Color(0xFFFF3366);
      case 'grappling':
        return AppColors.neonBlue;
      case 'conditioning':
        return Colors.orange;
      case 'recovery':
        return AppTheme.neonGreen;
      default:
        return AppTheme.neonCyan;
    }
  }

  String _getTypeLabel(String type) {
    for (final t in _trainingTypes) {
      if (t.key == type) return t.label;
    }
    return type[0].toUpperCase() + type.substring(1);
  }
}

//
// TRAINING TYPE MODEL
//

class _TrainingType {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const _TrainingType(this.key, this.label, this.icon, this.color);
}

//
// GLASS PANEL
//

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}

//
// BACKGROUND PAINTER
//

class _AnalyticsBgPainter extends CustomPainter {
  final double phase;
  _AnalyticsBgPainter(this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF050A14), Color(0xFF0A1628), Color(0xFF050A14)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final rng = math.Random(7);
    for (int i = 0; i < 40; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.2 + rng.nextDouble() * 0.8;
      final particlePhase = (phase * speed + rng.nextDouble()) % 1.0;
      final x = baseX + math.sin(particlePhase * math.pi * 2) * 15;
      final y = baseY + math.cos(particlePhase * math.pi * 2) * 10;
      final alpha = (0.03 + math.sin(particlePhase * math.pi) * 0.04).clamp(
        0.0,
        1.0,
      );
      canvas.drawCircle(
        Offset(x, y),
        1 + rng.nextDouble() * 1.5,
        Paint()..color = AppTheme.neonCyan.withValues(alpha: alpha),
      );
    }

    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.2),
      size.width * 0.4,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                AppColors.neonPurple.withValues(alpha: 0.02),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width * 0.3, size.height * 0.2),
                radius: size.width * 0.4,
              ),
            ),
    );
  }

  @override
  bool shouldRepaint(covariant _AnalyticsBgPainter old) => old.phase != phase;
}
