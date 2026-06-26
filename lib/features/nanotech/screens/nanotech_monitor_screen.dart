import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// NANOTECH FUTURE — Where human biology meets nanoscale engineering.
///
/// This screen visualizes the coming era where:
///  • Nanobots patrol the bloodstream, repairing tissue in real time
///  • Neural interfaces relay fight sense directly to AI coaches
///  • Cellular-level recovery turns days of healing into hours
///  • Blood chemistry is monitored continuously, pre-empting injury
///
/// Not science fiction — science *trajectory*. DFC builds the bridge.
/// ═══════════════════════════════════════════════════════════════════════════

class NanotechMonitorScreen extends StatefulWidget {
  const NanotechMonitorScreen({super.key});

  @override
  State<NanotechMonitorScreen> createState() => _NanotechMonitorScreenState();
}

class _NanotechMonitorScreenState extends State<NanotechMonitorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _NanoFieldPainter(phase: _ctrl.value)),
              SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(child: _buildNanobotView()),
                    SliverToBoxAdapter(child: _buildBloodChemistry()),
                    SliverToBoxAdapter(child: _buildCellularRecovery()),
                    SliverToBoxAdapter(child: _buildNeuralInterface()),
                    SliverToBoxAdapter(child: _buildDNAOptimization()),
                    SliverToBoxAdapter(child: _buildTimelineToFuture()),
                    SliverToBoxAdapter(child: _buildVisionStatement()),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go('/home'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Icon(
                Icons.arrow_back,
                color: Colors.white.withValues(alpha: 0.6),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NANOTECH FUTURE',
                  style: TextStyle(
                    color: AppColors.neonCyan,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  'Where biology meets engineering',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.neonCyan.withValues(alpha: 0.2),
              ),
              color: AppColors.neonCyan.withValues(alpha: 0.05),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.neonCyan,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonCyan.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'CONCEPT',
                  style: TextStyle(
                    color: AppColors.neonCyan.withValues(alpha: 0.7),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NANOBOT SWARM VIEW — Live visualization of nanobots in bloodstream
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildNanobotView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('NANOBOT SWARM', AppColors.neonCyan),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.neonCyan.withValues(alpha: 0.02),
                  border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 180,
                      child: CustomPaint(
                        size: const Size(double.infinity, 180),
                        painter: _NanobotSwarmPainter(phase: _ctrl.value),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _nanoStat('ACTIVE', '2.4M', AppColors.neonGreen),
                        _nanoStat('REPAIRING', '847K', AppColors.neonOrange),
                        _nanoStat('PATROL', '1.6M', AppColors.neonCyan),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Autonomous repair bots circulating through the cardiovascular system. '
                      'Each nanobot carries targeted repair payloads for muscle micro-tears, '
                      'cartilage damage, and inflammation markers.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.25),
                        fontSize: 10,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nanoStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.4),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BLOOD CHEMISTRY — Real-time molecular monitoring
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBloodChemistry() {
    final markers = [
      const _ChemMarker('Cortisol', 12.8, 'μg/dL', 6.0, 20.0, AppColors.neonOrange),
      const _ChemMarker('Testosterone', 687, 'ng/dL', 300, 1000, AppColors.neonGreen),
      const _ChemMarker('CRP (Inflammation)', 0.8, 'mg/L', 0, 3.0, AppColors.neonRed),
      const _ChemMarker(
        'Creatine Kinase',
        245,
        'U/L',
        30,
        400,
        AppColors.neonMagenta,
      ),
      const _ChemMarker('Lactate', 1.2, 'mmol/L', 0.5, 2.0, AppColors.neonCyan),
      const _ChemMarker(
        'Iron (Ferritin)',
        78,
        'ng/mL',
        30,
        300,
        AppColors.neonPurple,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('BLOOD CHEMISTRY', AppColors.neonRed),
          const SizedBox(height: 4),
          Text(
            'Continuous molecular monitoring via intravascular nanosensors',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 10),
          ...markers.map(_buildMarkerRow),
        ],
      ),
    );
  }

  Widget _buildMarkerRow(_ChemMarker m) {
    final pct = ((m.value - m.min) / (m.max - m.min)).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: m.color.withValues(alpha: 0.02),
          border: Border.all(color: m.color.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    m.name,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${m.value}',
                  style: TextStyle(
                    color: m.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  ' ${m.unit}',
                  style: TextStyle(
                    color: m.color.withValues(alpha: 0.4),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Stack(
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: m.color.withValues(alpha: 0.06),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: m.color.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${m.min}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.15),
                    fontSize: 8,
                  ),
                ),
                Text(
                  'OPTIMAL RANGE',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.1),
                    fontSize: 7,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '${m.max}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.15),
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CELLULAR RECOVERY — Tissue repair at cellular level
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCellularRecovery() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('CELLULAR RECOVERY', AppColors.neonGreen),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.neonGreen.withValues(alpha: 0.02),
                  border: Border.all(
                    color: AppColors.neonGreen.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    _recoveryZone(
                      'Right Knee (MCL)',
                      0.72,
                      'Nanobot repair in progress — 72% healed',
                      AppColors.neonGreen,
                    ),
                    _recoveryZone(
                      'Left Shoulder',
                      0.95,
                      'Near complete — cleared for impact',
                      AppColors.neonCyan,
                    ),
                    _recoveryZone(
                      'Rib Cage (R)',
                      0.45,
                      'Active tissue reconstruction — avoid heavy sparring',
                      AppColors.neonOrange,
                    ),
                    _recoveryZone(
                      'Facial Laceration',
                      0.88,
                      'Surface tissue closure nearly complete',
                      AppColors.neonGreen,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.neonGreen.withValues(alpha: 0.03),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.speed,
                            color: AppColors.neonGreen.withValues(alpha: 0.4),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Recovery speed: 4.2x faster than natural healing. '
                              'Estimated full recovery: 3 days (traditional: 12 days)',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 10,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recoveryZone(String zone, double pct, String note, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  zone,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(pct * 100).toInt()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.4)),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            note,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NEURAL INTERFACE — Brain-to-device direct link
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildNeuralInterface() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('NEURAL INTERFACE', AppColors.neonMagenta),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.neonMagenta.withValues(alpha: 0.02),
                  border: Border.all(
                    color: AppColors.neonMagenta.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 120,
                      child: CustomPaint(
                        size: const Size(double.infinity, 120),
                        painter: _NeuralWavePainter(phase: _ctrl.value),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _neuralRow(
                      'Reaction Time',
                      '112ms',
                      'Elite-tier',
                      AppColors.neonGreen,
                    ),
                    _neuralRow(
                      'Pattern Recognition',
                      '94.2%',
                      'AI-augmented',
                      AppColors.neonCyan,
                    ),
                    _neuralRow(
                      'Pain Threshold',
                      '8.4/10',
                      'High tolerance',
                      AppColors.neonOrange,
                    ),
                    _neuralRow(
                      'Fight IQ Signal',
                      '780 μV',
                      'Strong clarity',
                      AppColors.neonMagenta,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Non-invasive cortical interface reads motor cortex intentions, '
                      'enabling AI co-pilot to suggest counters before conscious awareness. '
                      'Fighter retains full autonomy — AI advises, never controls.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.2),
                        fontSize: 10,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _neuralRow(String label, String value, String tag, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            tag,
            style: TextStyle(color: color.withValues(alpha: 0.3), fontSize: 8),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DNA OPTIMIZATION — Epigenetic tuning for fighters
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDNAOptimization() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('EPIGENETIC OPTIMIZATION', AppColors.neonPurple),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.neonPurple.withValues(alpha: 0.02),
              border: Border.all(
                color: AppColors.neonPurple.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              children: [
                _geneRow(
                  'ACTN3 (Power)',
                  'R/R',
                  'Sprint/power genotype — explosive capacity',
                  AppColors.neonGreen,
                ),
                _geneRow(
                  'ACE (Endurance)',
                  'I/D',
                  'Balanced — adaptable to both power and endurance',
                  AppColors.neonCyan,
                ),
                _geneRow(
                  'COMT (Pain)',
                  'Val/Met',
                  'Moderate pain tolerance — trainable threshold',
                  AppColors.neonOrange,
                ),
                _geneRow(
                  'BDNF (Neuroplasticity)',
                  'Val/Val',
                  'High learning rate — optimized for skill acquisition',
                  AppColors.neonMagenta,
                ),
                _geneRow(
                  'IL-6 (Recovery)',
                  'G/C',
                  'Average recovery — nanobot supplementation active',
                  AppColors.neonPurple,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nanobots deliver targeted epigenetic modulators to optimize gene expression '
                  'without altering DNA sequence. Your genetics set the ceiling — nanotech helps '
                  'you reach it.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 10,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _geneRow(String gene, String variant, String note, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: color.withValues(alpha: 0.08),
              ),
              child: Text(
                variant,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
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
                  gene,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  note,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TIMELINE TO FUTURE — When will this tech arrive?
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTimelineToFuture() {
    final milestones = [
      const _Milestone(
        '2024',
        'NOW',
        'Wearable biometric tracking — devices on the body',
        AppColors.neonGreen,
        true,
      ),
      const _Milestone(
        '2026',
        'NEAR',
        'Implantable glucose & lactate monitors',
        AppColors.neonCyan,
        false,
      ),
      const _Milestone(
        '2028',
        'MID',
        'First therapeutic nanobots — targeted drug delivery',
        AppColors.neonMagenta,
        false,
      ),
      const _Milestone(
        '2030',
        'MID',
        'Non-invasive neural interfaces — thought-to-coach',
        AppColors.neonOrange,
        false,
      ),
      const _Milestone(
        '2033',
        'FAR',
        'Autonomous tissue-repair nanobots in bloodstream',
        AppColors.neonPurple,
        false,
      ),
      const _Milestone(
        '2035',
        'FAR',
        'Epigenetic optimization — personalized gene expression',
        AppColors.neonRed,
        false,
      ),
      const _Milestone(
        '2040',
        'VISION',
        'Full human-AI-nanobot symbiosis — the augmented fighter',
        AppColors.neonCyan,
        false,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('TIMELINE TO FUTURE', AppColors.neonOrange),
          const SizedBox(height: 4),
          Text(
            'From wearable to implantable to symbiotic',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 12),
          ...milestones.map(_buildMilestoneCard),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(_Milestone m) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              m.year,
              style: TextStyle(
                color: m.color.withValues(alpha: m.current ? 0.8 : 0.4),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: m.current
                      ? m.color.withValues(alpha: 0.6)
                      : Colors.transparent,
                  border: Border.all(
                    color: m.color.withValues(alpha: m.current ? 0.6 : 0.2),
                    width: m.current ? 2 : 1,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: m.color.withValues(alpha: 0.08),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: m.color.withValues(alpha: m.current ? 0.04 : 0.02),
                border: Border.all(
                  color: m.color.withValues(alpha: m.current ? 0.1 : 0.04),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.desc,
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: m.current ? 0.6 : 0.35,
                      ),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    m.era,
                    style: TextStyle(
                      color: m.color.withValues(alpha: 0.3),
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // VISION STATEMENT
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildVisionStatement() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.02),
          border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Text(
              'DFC VISION',
              style: TextStyle(
                color: AppColors.neonCyan.withValues(alpha: 0.4),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We don\'t wait for the future. We build the bridge to it.\n\n'
              'Every feature in DFC today is a step toward the augmented fighter of tomorrow — '
              'where AI coaches think alongside you, where nanobots heal you in hours not weeks, '
              'where your genetics are a starting point not a limit.\n\n'
              'The fighters of 2040 will look back at today the way we look at fighters '
              'who trained without video analysis.\n\n'
              'DFC is their foundation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
                height: 1.8,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═════════════════════════════════════════════════════════════════════════════
class _ChemMarker {
  final String name, unit;
  final double value, min, max;
  final Color color;
  const _ChemMarker(
    this.name,
    this.value,
    this.unit,
    this.min,
    this.max,
    this.color,
  );
}

class _Milestone {
  final String year, era, desc;
  final Color color;
  final bool current;
  const _Milestone(this.year, this.era, this.desc, this.color, this.current);
}

// ═════════════════════════════════════════════════════════════════════════════
// NANO FIELD — Background particles drifting through bloodstream
// ═════════════════════════════════════════════════════════════════════════════
class _NanoFieldPainter extends CustomPainter {
  final double phase;

  _NanoFieldPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final colors = [
      AppColors.neonCyan,
      AppColors.neonGreen,
      AppColors.neonMagenta,
    ];

    for (int i = 0; i < 40; i++) {
      final x = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final y = (baseY + phase * size.height * speed) % size.height;
      final r = 1.0 + rng.nextDouble() * 2;
      paint.color = colors[i % 3].withValues(
        alpha: 0.03 + rng.nextDouble() * 0.04,
      );
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NanoFieldPainter old) => old.phase != phase;
}

// ═════════════════════════════════════════════════════════════════════════════
// NANOBOT SWARM — Animated cluster visualization
// ═════════════════════════════════════════════════════════════════════════════
class _NanobotSwarmPainter extends CustomPainter {
  final double phase;

  _NanobotSwarmPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    // cx used in flow calculations below
    final rng = math.Random(77);

    // Blood vessel tube — two curved lines
    final vesselPaint = Paint()
      ..color = AppColors.neonRed.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 40;
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), vesselPaint);

    // Nanobots flowing through
    for (int i = 0; i < 30; i++) {
      final t = (phase + i / 30.0) % 1.0;
      final x = t * size.width;
      final yOff = math.sin(t * math.pi * 4 + rng.nextDouble() * 2) * 15;
      final y = cy + yOff + (rng.nextDouble() - 0.5) * 20;
      final isRepairing = i < 8;
      final color = isRepairing ? AppColors.neonOrange : AppColors.neonCyan;

      // Trail
      canvas.drawLine(
        Offset(x, y),
        Offset(x - 8, y + yOff * 0.2),
        Paint()
          ..color = color.withValues(alpha: 0.05)
          ..strokeWidth = 1,
      );

      // Bot body — hexagonal shape
      final hexPath = Path();
      for (int h = 0; h < 6; h++) {
        final angle = math.pi / 3 * h - math.pi / 6;
        final r = 3.0 + (isRepairing ? math.sin(phase * math.pi * 4) * 1 : 0);
        final hx = x + r * math.cos(angle);
        final hy = y + r * math.sin(angle);
        if (h == 0) {
          hexPath.moveTo(hx, hy);
        } else {
          hexPath.lineTo(hx, hy);
        }
      }
      hexPath.close();

      canvas.drawPath(hexPath, Paint()..color = color.withValues(alpha: 0.3));
      canvas.drawPath(
        hexPath,
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    // Flow direction arrow
    final arrowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int a = 0; a < 3; a++) {
      final ax = ((phase * size.width + a * size.width / 3) % size.width);
      canvas.drawLine(Offset(ax, cy - 6), Offset(ax + 6, cy), arrowPaint);
      canvas.drawLine(Offset(ax, cy + 6), Offset(ax + 6, cy), arrowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NanobotSwarmPainter old) => old.phase != phase;
}

// ═════════════════════════════════════════════════════════════════════════════
// NEURAL WAVE — Brainwave signal visualization
// ═════════════════════════════════════════════════════════════════════════════
class _NeuralWavePainter extends CustomPainter {
  final double phase;

  _NeuralWavePainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final waves = [
      (AppColors.neonMagenta, 12.0, 3.0, 0.3),
      (AppColors.neonCyan, 8.0, 5.0, 0.2),
      (AppColors.neonPurple, 15.0, 2.0, 0.15),
    ];

    for (final (color, amp, freq, opacity) in waves) {
      final path = Path();
      for (double x = 0; x <= size.width; x += 2) {
        final t = x / size.width;
        final y =
            size.height / 2 +
            amp * math.sin(t * math.pi * freq + phase * math.pi * 4) +
            amp *
                0.5 *
                math.sin(t * math.pi * freq * 2.3 + phase * math.pi * 6);
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Spike markers
    for (int i = 0; i < 4; i++) {
      final sx = size.width * (0.15 + i * 0.25);
      final sy = size.height / 2 + math.sin(phase * math.pi * 4 + i * 1.7) * 12;
      canvas.drawCircle(
        Offset(sx, sy),
        2,
        Paint()..color = AppColors.neonMagenta.withValues(alpha: 0.4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NeuralWavePainter old) => old.phase != phase;
}
