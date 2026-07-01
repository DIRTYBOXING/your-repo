import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/config/router_config.dart' as rc;

/// HEALTH INTELLIGENCE - Vitals & Recovery Dashboard v3.0
/// DesignTokens - NeonLineChart CustomPainter - Firestore Integration
/// HR, Sleep, Hydration, Stress - Google Fit integration ready
class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen>
    with SingleTickerProviderStateMixin {
  String _selectedRange = 'Week';
  bool _isLoading = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final Map<String, dynamic> _todayStats = {
    'hr': 62,
    'hrTrend': 'stable',
    'sleep': 7.2,
    'sleepTrend': 'stable',
    'hydration': 2.1,
    'hydrationTarget': 3.0,
    'stress': 3,
    'stressTrend': 'stable',
    'steps': 8420,
    'activeMinutes': 45,
  };

  List<double> _hrData = [58, 62, 60, 65, 59, 62, 61];
  List<double> _sleepData = [7.5, 6.8, 7.2, 8.0, 5.5, 7.8, 7.2];
  List<double> _hydrationData = [2.5, 2.1, 2.8, 3.0, 1.8, 2.4, 2.1];
  List<double> _stressData = [3, 4, 5, 6, 4, 3, 3];

  // Seed data for Day / Month views (demo)
  static const _hrDay = [64, 62, 60, 58, 61, 65, 72, 68, 63, 60, 59, 62];
  static const _sleepDay = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 7.2, 0.0, 0.0, 0.0, 0.0];
  static const _hydDay = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.5, 0.7, 0.3, 0.2, 0.1];
  static const _stressDay = [2, 2, 2, 1, 1, 2, 3, 4, 5, 4, 3, 3];

  static const _hrMonth = [60, 62, 58, 64, 61, 63, 65, 59, 62, 60, 66, 63, 61, 58, 62, 64, 60, 59, 63, 61, 65, 62, 60, 58, 63, 61, 64, 62, 60, 62];
  static const _sleepMonth = [7.0, 6.5, 7.2, 8.0, 5.5, 7.8, 7.2, 6.8, 7.5, 7.0, 6.2, 7.8, 8.1, 6.5, 7.0, 7.3, 6.8, 7.5, 7.2, 6.0, 7.8, 7.5, 7.0, 6.5, 7.2, 8.0, 7.5, 6.8, 7.0, 7.2];
  static const _hydMonth = [2.5, 2.1, 2.8, 3.0, 1.8, 2.4, 2.1, 2.6, 2.3, 2.0, 2.9, 2.7, 2.2, 1.9, 2.5, 2.8, 2.1, 2.4, 2.6, 2.0, 2.3, 2.7, 2.5, 2.1, 2.8, 3.0, 2.4, 2.2, 2.6, 2.1];
  static const _stressMonth = [3, 4, 5, 6, 4, 3, 3, 5, 4, 3, 6, 5, 4, 3, 4, 5, 3, 4, 5, 6, 4, 3, 3, 4, 5, 3, 4, 5, 4, 3];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
    _fetchHealthData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchHealthData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() => _isLoading = false);
        return;
      }

      final snap = await FirebaseFirestore.instance
          .collection('health_metrics')
          .where('userId', isEqualTo: uid)
          .orderBy('recordedAt', descending: true)
          .limit(7)
          .get();

      if (snap.docs.isNotEmpty) {
        final latest = snap.docs.first.data();
        setState(() {
          if (latest['restingHeartRate'] != null) {
            _todayStats['hr'] = (latest['restingHeartRate'] as num).toInt();
          } else if (latest['heartRate'] != null) {
            _todayStats['hr'] = (latest['heartRate'] as num).toInt();
          }
          if (latest['sleepHours'] != null) {
            _todayStats['sleep'] = (latest['sleepHours'] as num).toDouble();
          }
          if (latest['hydrationOz'] != null) {
            _todayStats['hydration'] = ((latest['hydrationOz'] as num) / 33.814)
                .toDouble();
          }
          if (latest['perceivedStress'] != null) {
            _todayStats['stress'] = (latest['perceivedStress'] as num).toInt();
          }
          if (latest['perceivedExertion'] != null) {
            _todayStats['activeMinutes'] =
                (latest['perceivedExertion'] as num).toInt() * 10;
          }

          if (snap.docs.length > 1) {
            final hrWeek = <double>[];
            final sleepWeek = <double>[];
            final hydWeek = <double>[];
            final stressWeek = <double>[];
            for (final doc in snap.docs.reversed) {
              final d = doc.data();
              hrWeek.add(
                ((d['restingHeartRate'] ?? d['heartRate'] ?? 62) as num)
                    .toDouble(),
              );
              sleepWeek.add(((d['sleepHours'] ?? 7.0) as num).toDouble());
              hydWeek.add((((d['hydrationOz'] ?? 70) as num) / 33.814));
              stressWeek.add(((d['perceivedStress'] ?? 3) as num).toDouble());
            }
            _hrData = hrWeek;
            _sleepData = sleepWeek;
            _hydrationData = hydWeek;
            _stressData = stressWeek;
          }
        });
      }
    } catch (_) {
      // Keep demo data on error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyRange(String range) {
    setState(() {
      switch (range) {
        case 'Day':
          _hrData = _hrDay.map((e) => e.toDouble()).toList();
          _sleepData = List<double>.from(_sleepDay);
          _hydrationData = List<double>.from(_hydDay);
          _stressData = _stressDay.map((e) => e.toDouble()).toList();
        case 'Month':
          _hrData = _hrMonth.map((e) => e.toDouble()).toList();
          _sleepData = List<double>.from(_sleepMonth);
          _hydrationData = List<double>.from(_hydMonth);
          _stressData = _stressMonth.map((e) => e.toDouble()).toList();
        default: // Week
          _hrData = [58, 62, 60, 65, 59, 62, 61];
          _sleepData = [7.5, 6.8, 7.2, 8.0, 5.5, 7.8, 7.2];
          _hydrationData = [2.5, 2.1, 2.8, 3.0, 1.8, 2.4, 2.1];
          _stressData = [3, 4, 5, 6, 4, 3, 3];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        color: DesignTokens.neonMagenta,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Syncing health data...',
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : FadeTransition(
                opacity: _fadeAnim,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Header
                    SliverAppBar(
                      floating: true,
                      backgroundColor: DesignTokens.bgPrimary,
                      elevation: 0,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                      ),
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  DesignTokens.neonMagenta,
                                  DesignTokens.neonRed,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                DesignTokens.radiusSmall,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: DesignTokens.neonMagenta.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.monitor_heart,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'HEALTH INTEL',
                                style: TextStyle(
                                  color: DesignTokens.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                'Vitals & Recovery Dashboard',
                                style: TextStyle(
                                  color: DesignTokens.textMuted,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      actions: [
                        Container(
                          margin: const EdgeInsets.only(right: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.neonGreen.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusPill,
                            ),
                            border: Border.all(
                              color: DesignTokens.neonGreen.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sync,
                                color: DesignTokens.neonGreen,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Synced',
                                style: TextStyle(
                                  color: DesignTokens.neonGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Content
                    SliverPadding(
                      padding: const EdgeInsets.all(DesignTokens.spacingL),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildTimeRangeSelector(),
                          const SizedBox(height: DesignTokens.spacingXL),
                          _buildVitalsGrid(),
                          const SizedBox(height: DesignTokens.spacingXXL),
                          _buildChartSection(
                            title: 'Heart Rate',
                            subtitle: 'Resting HR trend',
                            icon: Icons.favorite,
                            color: DesignTokens.neonRed,
                            data: _hrData,
                            currentValue: '${_todayStats['hr']} bpm',
                            trend: _todayStats['hrTrend'] as String,
                            aiInsight:
                                'Resting HR stable. Good recovery indicators.',
                          ),
                          const SizedBox(height: DesignTokens.spacingXL),
                          _buildChartSection(
                            title: 'Sleep Quality',
                            subtitle: 'Hours per night',
                            icon: Icons.bedtime,
                            color: DesignTokens.neonCyan,
                            data: _sleepData,
                            currentValue: '${_todayStats['sleep']}h',
                            trend: _todayStats['sleepTrend'] as String,
                            aiInsight:
                                'Sleep improved 12% this week. Keep the rhythm.',
                          ),
                          const SizedBox(height: DesignTokens.spacingXL),
                          _buildChartSection(
                            title: 'Hydration',
                            subtitle: 'Daily intake (liters)',
                            icon: Icons.water_drop,
                            color: DesignTokens.neonGreen,
                            data: _hydrationData,
                            currentValue: '${_todayStats['hydration']}L',
                            trend: 'stable',
                            aiInsight:
                                'Below target today. Increase fluids before training.',
                          ),
                          const SizedBox(height: DesignTokens.spacingXL),
                          _buildChartSection(
                            title: 'Stress Level',
                            subtitle: 'Self-reported (1-10)',
                            icon: Icons.psychology,
                            color: DesignTokens.neonAmber,
                            data: _stressData,
                            currentValue: '${_todayStats['stress']}/10',
                            trend: _todayStats['stressTrend'] as String,
                            aiInsight:
                                'Stress elevated mid-week but recovering well.',
                          ),
                          const SizedBox(height: DesignTokens.spacingXXL),
                          _buildAISummary(),
                          const SizedBox(height: DesignTokens.spacingXXL),
                          _buildDataSources(),
                          const SizedBox(height: DesignTokens.spacingXXL),
                          _buildQuickNav(),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context.push('/medical-intelligence');
                              },
                              icon: const Icon(
                                Icons.medical_information_outlined,
                                size: 18,
                              ),
                              label: const Text(
                                'Open Medical Intelligence Companion',
                              ),
                            ),
                          ),
                          const SizedBox(height: 100),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ========== TIME RANGE SELECTOR ==========

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
      ),
      child: Row(
        children: ['Day', 'Week', 'Month'].map((range) {
          final isSelected = _selectedRange == range;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedRange = range;
                _applyRange(range);
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            DesignTokens.neonCyan.withValues(alpha: 0.15),
                            DesignTokens.neonMagenta.withValues(alpha: 0.08),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                  border: isSelected
                      ? Border.all(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                        )
                      : null,
                ),
                child: Text(
                  range,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? DesignTokens.neonCyan
                        : DesignTokens.textMuted,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: DesignTokens.fontSizeBody,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ========== VITALS GRID ==========

  Widget _buildVitalsGrid() {
    final vitals = [
      _VitalData(
        'Resting HR',
        '${_todayStats['hr']}',
        'bpm',
        Icons.favorite,
        DesignTokens.neonRed,
      ),
      _VitalData(
        'Sleep',
        '${_todayStats['sleep']}',
        'hrs',
        Icons.bedtime,
        DesignTokens.neonCyan,
      ),
      _VitalData(
        'Steps',
        '${(_todayStats['steps'] as int) ~/ 1000}k',
        '',
        Icons.directions_walk,
        DesignTokens.neonGreen,
      ),
      _VitalData(
        'Active',
        '${_todayStats['activeMinutes']}',
        'min',
        Icons.local_fire_department,
        DesignTokens.neonAmber,
      ),
    ];

    return Row(
      children: vitals.asMap().entries.map((entry) {
        final v = entry.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: entry.key < vitals.length - 1 ? DesignTokens.spacingS : 0,
            ),
            padding: const EdgeInsets.all(DesignTokens.cardPaddingSmall),
            decoration: BoxDecoration(
              color: DesignTokens.bgCard,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              border: Border.all(
                color: v.color.withValues(alpha: 0.15),
                width: DesignTokens.borderThin,
              ),
            ),
            child: Column(
              children: [
                Icon(v.icon, color: v.color, size: 20),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: v.value,
                        style: const TextStyle(
                          color: DesignTokens.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      TextSpan(
                        text: v.unit,
                        style: const TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: DesignTokens.fontSizeCaption,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  v.label,
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: DesignTokens.fontSizeCaption,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ========== CHART SECTION ==========

  Widget _buildChartSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<double> data,
    required String currentValue,
    required String trend,
    required String aiInsight,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
          width: DesignTokens.borderThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
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
                        color: DesignTokens.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: DesignTokens.fontSizeBody,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currentValue,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      shadows: [
                        Shadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trend == 'up'
                            ? Icons.trending_up
                            : trend == 'down'
                            ? Icons.trending_down
                            : Icons.trending_flat,
                        color: trend == 'up'
                            ? DesignTokens.neonGreen
                            : trend == 'down'
                            ? DesignTokens.neonRed
                            : DesignTokens.textMuted,
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        trend.toUpperCase(),
                        style: TextStyle(
                          color: trend == 'up'
                              ? DesignTokens.neonGreen
                              : trend == 'down'
                              ? DesignTokens.neonRed
                              : DesignTokens.textMuted,
                          fontSize: DesignTokens.fontSizeCaption,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chart
          SizedBox(
            height: 120,
            child: AnimatedBuilder(
              animation: _fadeAnim,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(double.infinity, 120),
                  painter: _NeonLineChartPainter(
                    data: data,
                    color: color,
                    animation: _fadeAnim.value,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // AI Insight
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.06),
                  color.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              border: Border.all(color: color.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: color, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    aiInsight,
                    style: const TextStyle(
                      color: DesignTokens.textSecondary,
                      fontSize: DesignTokens.fontSizeSubtitleLarge,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== AI SUMMARY ==========

  Widget _buildAISummary() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.neonMagenta.withValues(alpha: 0.08),
            DesignTokens.neonCyan.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonMagenta.withValues(alpha: 0.2),
          width: DesignTokens.borderThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [DesignTokens.neonMagenta, DesignTokens.neonCyan],
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Weekly Health Summary',
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: DesignTokens.fontSizeTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Your recovery metrics look balanced this week. Sleep consistency improved while stress remained manageable. '
            'Hydration needs attention \u2014 you\'re averaging 15% below target. '
            'Consider setting water reminders before training sessions.',
            style: TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: DesignTokens.fontSizeBody,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Note: This is wellness awareness, not medical advice.',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeCaption,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ========== QUICK NAV ==========

  Widget _buildQuickNav() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: DesignTokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TRAINING & HEALTH HUB',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeCaption,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _quickNavBtn(
                icon: Icons.fitness_center,
                label: 'Fight Camp',
                color: DesignTokens.neonAmber,
                route: rc.RouterConfig.fightCampToolsPath,
              ),
              const SizedBox(width: 8),
              _quickNavBtn(
                icon: Icons.psychology_alt,
                label: 'AI Coach',
                color: DesignTokens.neonCyan,
                route: rc.RouterConfig.neuralCoachPath,
              ),
              const SizedBox(width: 8),
              _quickNavBtn(
                icon: Icons.watch,
                label: 'Devices',
                color: DesignTokens.neonGreen,
                route: rc.RouterConfig.deviceHubPath,
              ),
              const SizedBox(width: 8),
              _quickNavBtn(
                icon: Icons.scale,
                label: 'Body',
                color: DesignTokens.neonMagenta,
                route: rc.RouterConfig.bodyMonitorPath,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickNavBtn({
    required IconData icon,
    required String label,
    required Color color,
    required String route,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.push(route),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
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

  // ========== DATA SOURCES ==========

  Widget _buildDataSources() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        border: Border.all(
          color: DesignTokens.textDisabled.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Sources',
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: DesignTokens.fontSizeBody,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildSourceChip('Google Fit', Icons.fitness_center, true),
              const SizedBox(width: 8),
              _buildSourceChip('Manual Input', Icons.edit, true),
              const SizedBox(width: 8),
              _buildSourceChip('Wearable', Icons.watch, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourceChip(String label, IconData icon, bool connected) {
    final color = connected ? DesignTokens.neonGreen : DesignTokens.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: connected
            ? DesignTokens.neonGreen.withValues(alpha: 0.08)
            : DesignTokens.bgSecondary,
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(
          color: connected
              ? DesignTokens.neonGreen.withValues(alpha: 0.25)
              : DesignTokens.textDisabled.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: DesignTokens.fontSizeCaption,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalData {
  final String label, value, unit;
  final IconData icon;
  final Color color;
  const _VitalData(this.label, this.value, this.unit, this.icon, this.color);
}

// ========== NEON LINE CHART PAINTER ==========

class _NeonLineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double animation;

  _NeonLineChartPainter({
    required this.data,
    required this.color,
    this.animation = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Reserve space for Y-axis labels and X-axis date labels
    const double yAxisWidth = 34;
    const double xAxisHeight = 16;
    final chartLeft = yAxisWidth;
    final chartTop = 4.0;
    final chartWidth = size.width - yAxisWidth;
    final chartHeight = size.height - xAxisHeight - chartTop;

    final max = data.reduce((a, b) => a > b ? a : b);
    final min = data.reduce((a, b) => a < b ? a : b);
    final range = max - min == 0 ? 1.0 : max - min;
    final animatedCount = (data.length * animation).ceil().clamp(
      0,
      data.length,
    );

    // --- Y-axis value labels and grid lines ---
    final yLabelStyle = TextStyle(
      color: color.withValues(alpha: 0.5),
      fontSize: 9,
      fontFamily: 'monospace',
    );
    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 2; i++) {
      final fraction = i / 2.0; // 0 = top (max), 1 = mid, 2 = bottom (min)
      final yVal = max - fraction * range;
      final yPos = chartTop + fraction * chartHeight * 0.8 + chartHeight * 0.1;

      // Grid line
      canvas.drawLine(
        Offset(chartLeft, yPos),
        Offset(size.width, yPos),
        gridPaint,
      );

      // Label
      final label = yVal == yVal.roundToDouble()
          ? yVal.toInt().toString()
          : yVal.toStringAsFixed(1);
      final tp = TextPainter(
        text: TextSpan(text: label, style: yLabelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: yAxisWidth - 4);
      tp.paint(canvas, Offset(yAxisWidth - tp.width - 4, yPos - tp.height / 2));
    }

    // --- X-axis date labels ---
    final now = DateTime.now();
    final xLabelStyle = TextStyle(
      color: color.withValues(alpha: 0.45),
      fontSize: 8,
      fontFamily: 'monospace',
    );
    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 0; i < data.length; i++) {
      final x = chartLeft + (i / (data.length - 1)) * chartWidth;
      // Default: day abbreviations counting back from today
      final day = now.subtract(Duration(days: data.length - 1 - i));
      final label = weekDays[day.weekday - 1];
      final tp = TextPainter(
        text: TextSpan(text: label, style: xLabelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 30);
      tp.paint(canvas, Offset(x - tp.width / 2, chartTop + chartHeight + 2));
    }

    // --- Chart line and area ---
    final path = Path();
    final areaPath = Path();

    for (int i = 0; i < animatedCount; i++) {
      final x = chartLeft + (i / (data.length - 1)) * chartWidth;
      final y =
          chartTop +
          chartHeight -
          ((data[i] - min) / range) * chartHeight * 0.8 -
          chartHeight * 0.1;

      if (i == 0) {
        path.moveTo(x, y);
        areaPath.moveTo(x, chartTop + chartHeight);
        areaPath.lineTo(x, y);
      } else {
        final prevX = chartLeft + ((i - 1) / (data.length - 1)) * chartWidth;
        final prevY =
            chartTop +
            chartHeight -
            ((data[i - 1] - min) / range) * chartHeight * 0.8 -
            chartHeight * 0.1;
        final cx = (prevX + x) / 2;
        path.quadraticBezierTo(cx, prevY, x, y);
        areaPath.quadraticBezierTo(cx, prevY, x, y);
      }
    }

    // Close area
    if (animatedCount > 0) {
      final lastX =
          chartLeft + ((animatedCount - 1) / (data.length - 1)) * chartWidth;
      areaPath.lineTo(lastX, chartTop + chartHeight);
      areaPath.close();
    }

    // Apply clip so chart doesn't overflow into label areas
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(chartLeft, 0, chartWidth, chartTop + chartHeight + 1),
    );

    // Area fill
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.25),
                color.withValues(alpha: 0.0),
              ],
            ).createShader(
              Rect.fromLTWH(chartLeft, chartTop, chartWidth, chartHeight),
            ),
    );

    // Glow
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Line
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Points
    for (int i = 0; i < animatedCount; i++) {
      final x = chartLeft + (i / (data.length - 1)) * chartWidth;
      final y =
          chartTop +
          chartHeight -
          ((data[i] - min) / range) * chartHeight * 0.8 -
          chartHeight * 0.1;
      canvas.drawCircle(
        Offset(x, y),
        5,
        Paint()
          ..color = color.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = color);
      canvas.drawCircle(Offset(x, y), 1.5, Paint()..color = Colors.white);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NeonLineChartPainter old) =>
      old.data != data || old.color != color || old.animation != animation;
}
