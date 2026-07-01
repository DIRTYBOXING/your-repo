import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/sports_science_engine.dart';
import '../../../shared/widgets/signal_card.dart';

/// TRAINING COMMAND - Training & Health Intelligence Dashboard v3.0
/// DesignTokens - Animated CustomPainters - Signal Cards - AI Insights
class TrainingDashboardScreen extends StatefulWidget {
  const TrainingDashboardScreen({super.key});

  @override
  State<TrainingDashboardScreen> createState() =>
      _TrainingDashboardScreenState();
}

class _TrainingDashboardScreenState extends State<TrainingDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

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
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final science = context.watch<SportsScienceEngine>();

    List<double> tailOrFallback(List<double> values, List<double> fallback) {
      if (values.isEmpty) return fallback;
      if (values.length >= 7) return values.sublist(values.length - 7);
      return [
        ...List<double>.filled(7 - values.length, values.first),
        ...values,
      ];
    }

    final sleepData = tailOrFallback(
      science.getSleepTrend(days: 7).map((entry) => entry.value).toList(),
      [7.5, 6.8, 7.2, 8.0, 5.5, 7.8, 8.2],
    );
    final restingHrData = tailOrFallback(
      science.getRestingHRTrend(days: 7).map((entry) => entry.value).toList(),
      [58, 62, 60, 56, 68, 59, 55].map((e) => e.toDouble()).toList(),
    );
    final weightData = tailOrFallback(
      science.getWeightTrend(days: 7).map((entry) => entry.value).toList(),
      [170.5, 170.3, 170.0, 170.4, 170.2, 170.1, 170.2],
    );
    final readinessData = tailOrFallback(
      science
          .getReadinessTrend(days: 7)
          .map((entry) => (entry.value / 10).clamp(1, 10).toDouble())
          .toList(),
      [8, 7, 8, 9, 7, 8, 8].map((e) => e.toDouble()).toList(),
    );

    final stressRecovery = science.getStressRecoveryCorrelation(days: 7);
    final stressData = tailOrFallback(
      stressRecovery
          .map((entry) => (entry.stress / 10).clamp(1, 10).toDouble())
          .toList(),
      [3, 4, 6, 7, 5, 3, 2].map((e) => e.toDouble()).toList(),
    );

    final loadTrend = science.getDailyLoadTrend(days: 7);
    final loadScores = tailOrFallback(
      loadTrend
          .map((entry) => (entry.value / 100).clamp(1, 10).toDouble())
          .toList(),
      [8, 7, 9, 6, 8, 4, 2].map((e) => e.toDouble()).toList(),
    );

    final loadRecoveryData = List.generate(7, (index) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return {
        'day': days[index],
        'load': loadScores[index].round(),
        'recovery': readinessData[index].round(),
      };
    });

    final avgSleep = sleepData.reduce((a, b) => a + b) / sleepData.length;
    final avgHr = restingHrData.reduce((a, b) => a + b) / restingHrData.length;
    final trainingDays = loadScores
        .where((entry) => entry >= 4)
        .length
        .clamp(0, 7);
    final consistency = ((trainingDays / 7) * 100).round();

    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverAppBar(
                floating: true,
                backgroundColor: DesignTokens.bgPrimary,
                elevation: 0,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            DesignTokens.neonGreen,
                            DesignTokens.neonCyan,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusSmall,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: DesignTokens.neonGreen.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fitness_center,
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
                          'TRAINING COMMAND',
                          style: TextStyle(
                            color: DesignTokens.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          'Health & Recovery Intelligence',
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
                  IconButton(
                    icon: const Icon(
                      Icons.calendar_today_outlined,
                      color: DesignTokens.textMuted,
                    ),
                    onPressed: () => context.push('/planner'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune, color: DesignTokens.textMuted),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Use the category tabs below to filter your training data'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(DesignTokens.spacingL),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Week Summary
                    _buildWeekSummary(
                      trainingDays: trainingDays,
                      avgSleep: avgSleep,
                      avgHr: avgHr,
                      consistency: consistency,
                    ),
                    const SizedBox(height: DesignTokens.spacingXXL),

                    // Load vs Recovery
                    _buildSectionHeader(
                      'Load vs Recovery',
                      'Training balance over 7 days',
                    ),
                    const SizedBox(height: DesignTokens.spacingM),
                    _buildLoadRecoveryChart(loadRecoveryData),
                    _buildAIExplanation(
                      'Your load exceeded recovery on Wednesday and Friday. '
                      'Consider active recovery or reduced volume to restore balance.',
                      status: SignalStatus.amber,
                    ),
                    const SizedBox(height: DesignTokens.spacingXXL),

                    // Sleep vs HR
                    _buildSectionHeader(
                      'Sleep vs Resting HR',
                      'Recovery correlation',
                    ),
                    const SizedBox(height: DesignTokens.spacingM),
                    _buildDualLineChart(
                      data1: sleepData,
                      data2: restingHrData,
                      color1: DesignTokens.neonCyan,
                      color2: DesignTokens.neonRed,
                      label1: 'Sleep (hrs)',
                      label2: 'HR (bpm)',
                    ),
                    _buildAIExplanation(
                      'Good sleep correlates with lower resting HR. '
                      'Your Friday dip in sleep quality showed in Saturday morning HR.',
                    ),
                    const SizedBox(height: DesignTokens.spacingXXL),

                    // Weight vs Hydration
                    _buildSectionHeader(
                      'Weight vs Hydration',
                      'Cut monitoring',
                    ),
                    const SizedBox(height: DesignTokens.spacingM),
                    _buildDualLineChart(
                      data1: weightData,
                      data2: readinessData,
                      color1: DesignTokens.neonAmber,
                      color2: DesignTokens.neonCyan,
                      label1: 'Weight (kg)',
                      label2: 'Hydration',
                      subtitle:
                          'Current: ${(weightData.last * 0.4536).toStringAsFixed(1)} kg',
                    ),
                    _buildAIExplanation(
                      'Weight stable at 77.2 kg / 170.2 lbs. Hydration levels good. '
                      'No concerning patterns for weight cut preparation.',
                    ),
                    const SizedBox(height: DesignTokens.spacingXXL),

                    // Stress vs Training
                    _buildSectionHeader(
                      'Stress vs Training',
                      'Mental load tracking',
                    ),
                    const SizedBox(height: DesignTokens.spacingM),
                    _buildDualLineChart(
                      data1: stressData,
                      data2: loadScores,
                      color1: DesignTokens.neonRed,
                      color2: DesignTokens.neonGreen,
                      label1: 'Stress',
                      label2: 'Training',
                    ),
                    _buildAIExplanation(
                      'Stress levels elevated mid-week despite moderate training. '
                      'External stressors may be affecting recovery. Consider journaling or support.',
                      status: SignalStatus.amber,
                    ),
                    const SizedBox(height: DesignTokens.spacingXXL),

                    // Recovery Panel
                    _buildRecoveryPanel(),
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

  // ========== WEEK SUMMARY ==========

  Widget _buildWeekSummary({
    required int trainingDays,
    required double avgSleep,
    required double avgHr,
    required int consistency,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.neonCyan.withValues(alpha: 0.08),
            DesignTokens.neonMagenta.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.15),
          width: DesignTokens.borderThin,
        ),
      ),
      child: Row(
        children: [
          _buildSummaryItem('Training', '$trainingDays', Icons.fitness_center),
          _summaryDivider(),
          _buildSummaryItem(
            'Avg Sleep',
            '${avgSleep.toStringAsFixed(1)}h',
            Icons.bedtime,
          ),
          _summaryDivider(),
          _buildSummaryItem('Avg HR', avgHr.toStringAsFixed(0), Icons.favorite),
          _summaryDivider(),
          _buildSummaryItem('Consistency', '$consistency%', Icons.trending_up),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: DesignTokens.neonCyan, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: DesignTokens.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeSubtitle,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _summaryDivider() {
    return Container(
      width: 1,
      height: 40,
      color: DesignTokens.textDisabled.withValues(alpha: 0.2),
    );
  }

  // ========== SECTION HEADER ==========

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [DesignTokens.neonGreen, DesignTokens.neonCyan],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
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
                  fontSize: DesignTokens.fontSizeTitle,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
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
      ],
    );
  }

  // ========== LOAD VS RECOVERY CHART ==========

  Widget _buildLoadRecoveryChart(List<Map<String, dynamic>> loadRecoveryData) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.12),
          width: DesignTokens.borderThin,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildLegendItem('Load', const Color(0xFF6C5CE7)),
              const SizedBox(width: 16),
              _buildLegendItem('Recovery', DesignTokens.neonGreen),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: loadRecoveryData.map((data) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AnimatedBuilder(
                              animation: _fadeAnim,
                              builder: (context, child) {
                                return Container(
                                  width: 12,
                                  height:
                                      (data['load'] as int) *
                                      12.0 *
                                      _fadeAnim.value,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFF6C5CE7),
                                        Color(0xFF4A3BAD),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF6C5CE7,
                                        ).withValues(alpha: 0.3),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 3),
                            AnimatedBuilder(
                              animation: _fadeAnim,
                              builder: (context, child) {
                                return Container(
                                  width: 12,
                                  height:
                                      (data['recovery'] as int) *
                                      12.0 *
                                      _fadeAnim.value,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        DesignTokens.neonGreen,
                                        DesignTokens.neonGreen.withValues(
                                          alpha: 0.6,
                                        ),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: DesignTokens.neonGreen
                                            .withValues(alpha: 0.3),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['day'] as String,
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
            ),
          ),
        ],
      ),
    );
  }

  // ========== DUAL LINE CHART ==========

  Widget _buildDualLineChart({
    required List<num> data1,
    required List<num> data2,
    required Color color1,
    required Color color2,
    required String label1,
    required String label2,
    String? subtitle,
  }) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: color1.withValues(alpha: 0.12),
          width: DesignTokens.borderThin,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: DesignTokens.fontSizeSubtitleLarge,
                  ),
                )
              else
                const SizedBox.shrink(),
              Row(
                children: [
                  _buildLegendItem(label1, color1),
                  const SizedBox(width: 16),
                  _buildLegendItem(label2, color2),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: _DualLinePainter(
                data1: data1,
                data2: data2,
                color1: color1,
                color2: color2,
                animation: _fadeAnim.value,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== LEGEND ==========

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: DesignTokens.textMuted,
            fontSize: DesignTokens.fontSizeSubtitle,
          ),
        ),
      ],
    );
  }

  // ========== AI EXPLANATION ==========

  Widget _buildAIExplanation(
    String text, {
    SignalStatus status = SignalStatus.green,
  }) {
    final color = status == SignalStatus.green
        ? DesignTokens.neonGreen
        : status == SignalStatus.amber
        ? DesignTokens.neonAmber
        : DesignTokens.neonRed;

    return Container(
      margin: const EdgeInsets.only(top: DesignTokens.spacingM),
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.06),
            color.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: DesignTokens.borderThin,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.auto_awesome, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: DesignTokens.textSecondary,
                fontSize: DesignTokens.fontSizeBody,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== RECOVERY PANEL ==========

  Widget _buildRecoveryPanel() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingLarge),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonAmber.withValues(alpha: 0.15),
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
                  color: DesignTokens.neonAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: DesignTokens.neonAmber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recovery & Redline Indicators',
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: DesignTokens.fontSizeTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildIndicatorRow('Overreaching Risk', 'Low', SignalStatus.green),
          _buildIndicatorRow(
            'Caffeine Load',
            '180mg today',
            SignalStatus.green,
          ),
          _buildIndicatorRow(
            'Supplement Stack',
            'Normal range',
            SignalStatus.green,
          ),
          _buildIndicatorRow(
            'Iron Levels',
            'Self-check recommended',
            SignalStatus.amber,
          ),
          const SizedBox(height: 14),
          const Text(
            'Note: These are wellness indicators, not medical advice. Consult a healthcare professional for clinical assessments.',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeCaption,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorRow(String label, String value, SignalStatus status) {
    final color = status == SignalStatus.green
        ? DesignTokens.neonGreen
        : status == SignalStatus.amber
        ? DesignTokens.neonAmber
        : DesignTokens.neonRed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: DesignTokens.textSecondary,
                fontSize: DesignTokens.fontSizeBody,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ========== DUAL LINE PAINTER ==========

class _DualLinePainter extends CustomPainter {
  final List<num> data1;
  final List<num> data2;
  final Color color1;
  final Color color2;
  final double animation;

  _DualLinePainter({
    required this.data1,
    required this.data2,
    required this.color1,
    required this.color2,
    this.animation = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Grid
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = DesignTokens.textDisabled.withValues(alpha: 0.1);

    for (var i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final max1 = data1.reduce((a, b) => a > b ? a : b).toDouble();
    final min1 = data1.reduce((a, b) => a < b ? a : b).toDouble();
    final max2 = data2.reduce((a, b) => a > b ? a : b).toDouble();
    final min2 = data2.reduce((a, b) => a < b ? a : b).toDouble();

    final animatedCount = (data1.length * animation).ceil().clamp(
      0,
      data1.length,
    );

    _drawLine(canvas, size, data1, min1, max1, color1, animatedCount);
    _drawLine(canvas, size, data2, min2, max2, color2, animatedCount);

    // Day labels
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    for (int i = 0; i < data1.length && i < days.length; i++) {
      final x = (i / (data1.length - 1)) * size.width;
      final tp = TextPainter(
        text: TextSpan(
          text: days[i],
          style: const TextStyle(color: DesignTokens.textDisabled, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height + 4));
    }
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    List<num> data,
    double minVal,
    double maxVal,
    Color color,
    int count,
  ) {
    final range = (maxVal - minVal).abs() < 0.001 ? 1.0 : (maxVal - minVal);

    final path = Path();
    for (int i = 0; i < count; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y =
          size.height -
          ((data[i] - minVal) / range) * size.height * 0.8 -
          size.height * 0.1;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = ((i - 1) / (data.length - 1)) * size.width;
        final prevY =
            size.height -
            ((data[i - 1] - minVal) / range) * size.height * 0.8 -
            size.height * 0.1;
        final cx = (prevX + x) / 2;
        path.quadraticBezierTo(cx, prevY, x, y);
      }
    }

    // Glow
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = color.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Line
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = color
        ..strokeCap = StrokeCap.round,
    );

    // Points
    for (int i = 0; i < count; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y =
          size.height -
          ((data[i] - minVal) / range) * size.height * 0.8 -
          size.height * 0.1;
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = color);
      canvas.drawCircle(Offset(x, y), 1.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _DualLinePainter old) =>
      old.animation != animation;
}
