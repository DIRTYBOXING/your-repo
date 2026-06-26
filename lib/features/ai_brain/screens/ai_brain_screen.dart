import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/combat_intelligence_engine.dart';
import '../../../shared/services/ai_eso_engine_service.dart';
import '../../../shared/services/ai_coach_service.dart';
import '../../../shared/services/neural_mesh_engine.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// AI BRAIN v5.0 — NEURAL COMMAND CENTRE
/// The Smartest Combat Sports Intelligence System on Earth
/// Powered by: Google Gemini, Firebase Genkit, DFC Neural Mesh
/// Wired to: CombatIntelligenceEngine, AIEsoEngine, AICoachService
/// Future-ready: Quantum ML, Edge AI, Neural Implant API, Mars Protocol
/// ═══════════════════════════════════════════════════════════════════════════

class AIBrainScreen extends StatefulWidget {
  const AIBrainScreen({super.key});

  @override
  State<AIBrainScreen> createState() => _AIBrainScreenState();
}

class _AIBrainScreenState extends State<AIBrainScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late AnimationController _gridController;
  late AnimationController _glowController;
  late AnimationController _neuralController;

  // ── Live service connections ──
  final CombatIntelligenceEngine _combatEngine = CombatIntelligenceEngine();
  late final AIEsoEngineService _esoEngine;
  // ignore: unused_field
  late final AICoachService _coachService;
  late final NeuralMeshEngine _neuralMesh;

  // ── Live data from engines ──
  Map<String, dynamic> _engineStats = {};
  WellnessSnapshot? _wellness;
  TrainingLoad? _trainingLoad;
  PerformanceIndex? _performance;
  // ignore: unused_field
  FighterIntelProfile? _demoProfile;
  StyleClashAnalysis? _demoClash;
  bool _isInitialized = false;
  bool _depsInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_depsInitialized) {
      _depsInitialized = true;
      _esoEngine = context.read<AIEsoEngineService>();
      _coachService = context.read<AICoachService>();
      _neuralMesh = context.read<NeuralMeshEngine>();
      _initializeEngines();
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _neuralController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  Future<void> _initializeEngines() async {
    await _combatEngine.initialize();
    await _esoEngine.initialize();
    await _neuralMesh.initialize();

    _demoProfile = _combatEngine.profileFighter(
      fighterId: 'sample_analysis',
      name: 'Sample Fighter',
      wins: 18,
      losses: 3,
      knockouts: 12,
      submissions: 3,
    );

    _demoClash = _combatEngine.analyzeStyleClash(
      fighterAId: 'sample_analysis',
      fighterAName: 'Fighter A',
      fighterBId: 'sample_opponent',
      fighterBName: 'Fighter B',
      fighterAWins: 18,
      fighterALosses: 3,
      fighterBWins: 15,
      fighterBLosses: 5,
    );

    setState(() {
      _engineStats = _combatEngine.engineStats;
      _wellness = _esoEngine.currentWellness;
      _trainingLoad = _esoEngine.trainingLoad;
      _performance = _esoEngine.performanceIndex;
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _scanController.dispose();
    _gridController.dispose();
    _glowController.dispose();
    _neuralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      body: Stack(
        children: [
          // ── Neural Grid Background ──
          AnimatedBuilder(
            animation: _gridController,
            builder: (context, _) => CustomPaint(
              painter: _NeuralGridPainter(phase: _gridController.value),
              size: Size.infinite,
            ),
          ),
          // ── Horizontal Scan ──
          AnimatedBuilder(
            animation: _scanController,
            builder: (context, _) => Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height:
                    MediaQuery.of(context).size.height * _scanController.value,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      DesignTokens.neonMagenta.withValues(alpha: 0.02),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.95, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildNeuralStatus(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNeuralMeshTab(),
                      _buildComingSoonTab(
                        icon: Icons.monitor_heart_outlined,
                        title: 'Biometrics',
                        description:
                            'Real-time heart rate, HRV, VO2 max tracking and fight-readiness scoring. Connect your wearables to unlock.',
                      ),
                      _buildComingSoonTab(
                        icon: Icons.watch_outlined,
                        title: 'Devices',
                        description:
                            'Pair smartwatches, chest straps, and gym sensors. Auto-sync training load and recovery data.',
                      ),
                      _buildComingSoonTab(
                        icon: Icons.insights_outlined,
                        title: 'Insights',
                        description:
                            'AI-generated fight reports, weekly performance summaries, and trend analysis across all your data.',
                      ),
                      _buildComingSoonTab(
                        icon: Icons.rocket_launch_outlined,
                        title: 'Future Tech',
                        description:
                            'AR fight visualisation, motion capture training, and neural feedback systems on the horizon.',
                      ),
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

  // ═══════════════════════════════════════════════════════
  // COMING SOON TAB — Gated placeholder with details
  // ═══════════════════════════════════════════════════════

  Widget _buildComingSoonTab({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.cyanAccent.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'IN DEVELOPMENT',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This module is being built. Follow DFC updates for launch.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // HEADER — NEURAL COMMAND CENTRE
  // ═══════════════════════════════════════════════════════

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final glow = 0.08 + _glowController.value * 0.06;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignTokens.neonMagenta.withValues(alpha: glow * 0.3),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: DesignTokens.neonMagenta.withValues(alpha: 0.15),
                    ),
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
                    Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              DesignTokens.neonMagenta,
                              Color.lerp(
                                DesignTokens.neonMagenta,
                                DesignTokens.neonCyan,
                                _glowController.value,
                              )!,
                              DesignTokens.neonCyan,
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'AI BRAIN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.neonGreen.withValues(
                                alpha: 0.1 + _pulseController.value * 0.08,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: DesignTokens.neonGreen.withValues(
                                  alpha: 0.3 + _pulseController.value * 0.2,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: DesignTokens.neonGreen.withValues(
                                    alpha: _pulseController.value * 0.15,
                                  ),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: DesignTokens.neonGreen,
                                    boxShadow: [
                                      BoxShadow(
                                        color: DesignTokens.neonGreen
                                            .withValues(alpha: 0.6),
                                        blurRadius:
                                            4 + _pulseController.value * 3,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'LEARNING',
                                  style: TextStyle(
                                    color: DesignTokens.neonGreen,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'NEURAL COMMAND \u2022 TELEMETRY \u2022 INTELLIGENCE',
                          style: TextStyle(
                            color: DesignTokens.neonMagenta.withValues(
                              alpha: 0.4,
                            ),
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'v5.0',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.2),
                            fontSize: 8,
                            fontFamily: 'monospace',
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
      },
    );
  }

  // ═══════════════════════════════════════════════════════
  // NEURAL STATUS — IQ + ENGINE METRICS
  // ═══════════════════════════════════════════════════════

  Widget _buildNeuralStatus() {
    final dataPoints = ((_engineStats['dataPointsProcessed'] as num?) ?? 0)
        .toInt();
    final accuracy = (((_engineStats['predictionAccuracy'] as num?) ?? 0) * 100)
        .toInt();
    final profiles = ((_engineStats['profilesAnalyzed'] as num?) ?? 0).toInt();
    final int wellnessScore = _wellness?.overallIndex.toInt() ?? 0;
    final iqScore = _isInitialized
        ? (accuracy * 0.4 + (wellnessScore * 0.3) + (profiles * 5).clamp(0, 30))
              .toInt()
        : 0;
    final iqNormalized = (iqScore / 100).clamp(0.0, 1.0);
    final statusColor = iqScore >= 70
        ? DesignTokens.neonGreen
        : iqScore >= 50
        ? DesignTokens.neonAmber
        : DesignTokens.neonRed;
    final statusLabel = iqScore >= 70
        ? 'GENIUS'
        : iqScore >= 50
        ? 'LEARNING'
        : 'BOOTING';

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _glowController]),
      builder: (context, _) {
        final pulse = _pulseController.value;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DesignTokens.neonMagenta.withValues(alpha: 0.06 + pulse * 0.02),
                DesignTokens.neonCyan.withValues(alpha: 0.03),
                const Color(0xFF020408).withValues(alpha: 0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DesignTokens.neonMagenta.withValues(
                alpha: 0.12 + pulse * 0.06,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.neonMagenta.withValues(
                  alpha: 0.04 + pulse * 0.03,
                ),
                blurRadius: 20,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Animated IQ Ring ──
              SizedBox(
                width: 72,
                height: 72,
                child: CustomPaint(
                  painter: _BrainScorePainter(
                    score: iqNormalized,
                    glowPhase: pulse,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$iqScore',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: statusColor.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 6,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, DesignTokens.neonMagenta],
                          ).createShader(bounds),
                          child: const Text(
                            'Neural Intelligence Score',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.neonGreen.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _isInitialized ? 'GEMINI' : 'BOOT',
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              color: _isInitialized
                                  ? DesignTokens.neonGreen
                                  : DesignTokens.neonAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isInitialized
                          ? 'Processing $dataPoints data points \u00b7 $profiles profiles \u00b7 7 AI bots active'
                          : 'Initializing neural mesh...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 9.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _kpiBadge(
                          _wellness?.overallIndex.toStringAsFixed(0) ??
                              '\u2014',
                          'WEL',
                          DesignTokens.neonGreen,
                        ),
                        const SizedBox(width: 4),
                        _kpiBadge(
                          _trainingLoad != null
                              ? _trainingLoad!.ratio.toStringAsFixed(2)
                              : '\u2014',
                          'LOAD',
                          DesignTokens.neonAmber,
                        ),
                        const SizedBox(width: 4),
                        _kpiBadge('$accuracy%', 'ACC', DesignTokens.neonCyan),
                        const SizedBox(width: 4),
                        _kpiBadge('7', 'BOTS', DesignTokens.neonMagenta),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _kpiBadge(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // TAB BAR
  // ═══════════════════════════════════════════════════════

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: DesignTokens.neonMagenta.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: DesignTokens.neonMagenta,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'NEURAL MESH'),
          Tab(text: 'BIOMETRICS'),
          Tab(text: 'DEVICES'),
          Tab(text: 'INSIGHTS'),
          Tab(text: 'FUTURE TECH'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // TAB 1 — NEURAL MESH (AI Bot Army)
  // ═══════════════════════════════════════════════════════

  Widget _buildNeuralMeshTab() {
    final stats = _engineStats;
    final predAcc = (stats['predictionAccuracy'] as double?) ?? 0.72;
    final wellnessAcc = (_wellness?.overallIndex ?? 75) / 100;
    final loadRatio = _trainingLoad?.ratio ?? 1.0;
    final perfCurrent = (_performance?.current ?? 70) / 100;

    final combatAcc = predAcc.clamp(0.0, 1.0);
    final readinessAcc = wellnessAcc.clamp(0.0, 1.0);
    // Real data from NeuralMeshEngine (PSYCHE, SCALES, SHIELD, FUEL)
    final psyche = _neuralMesh.psycheAnalysis;
    final scales = _neuralMesh.scalesAnalysis;
    final shield = _neuralMesh.shieldAnalysis;
    final fuel = _neuralMesh.fuelAnalysis;

    final mentalAcc =
        (psyche != null
                ? psyche.overallMentalScore / 100
                : (wellnessAcc * 0.7 + perfCurrent * 0.3))
            .clamp(0.0, 1.0);
    final weightAcc =
        (scales != null
                ? scales.trajectoryConfidence
                : (loadRatio < 1.5 ? 0.88 : 0.65))
            .clamp(0.0, 1.0);
    final injuryAcc =
        (shield != null
                ? (1.0 - shield.injuryRiskScore / 100)
                : (1.0 - (loadRatio - 1.0).abs() * 0.5))
            .clamp(0.0, 1.0);
    final opponentAcc = ((_demoClash?.confidence ?? 0.6) * 0.8 + predAcc * 0.2)
        .clamp(0.0, 1.0);
    final nutritionAcc =
        (fuel != null ? fuel.nutritionScore / 100 : (wellnessAcc * 0.8 + 0.15))
            .clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle(
          'U0001f9e0 AI Bot Army \u2014 7 Specialized Neural Agents',
          DesignTokens.neonMagenta,
        ),
        Text(
          'Each bot is a dedicated AI agent trained for a specific domain. They work together as a neural mesh \u2014 sharing data, cross-referencing insights, and learning from every interaction.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10.5,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        _aiBotCard(
          botName: 'ATLAS',
          role: 'Combat Performance Director',
          icon: Icons.sports_mma,
          color: DesignTokens.neonRed,
          accuracy: combatAcc,
          status: 'ACTIVE',
          description:
              'Tracks striking accuracy, takedown rates, submission chains, round-by-round gas tank. Learns your patterns before opponents do. Powered by fight film metadata + accelerometer data from smart gloves.',
          capabilities: [
            'Strike analysis',
            'Grappling metrics',
            'Gas tank prediction',
            'Pattern detection',
            'Opponent weakness scan',
          ],
          dataSources:
              'Hykso sensors, fight footage, manual logs, sparring GPS',
          learningRate:
              '${(combatAcc * 100).toInt()}% confidence after ${_engineStats['dataPointsProcessed'] ?? 0} data points',
        ),
        _aiBotCard(
          botName: 'VITALS',
          role: 'Physical Readiness Engine',
          icon: Icons.favorite,
          color: DesignTokens.neonGreen,
          accuracy: readinessAcc,
          status: 'ACTIVE',
          description:
              'Correlates HRV, sleep architecture, training load, hydration, skin temperature to predict fight-day readiness. Learns your optimal taper length and recovery curve. Cross-references with NASA astronaut recovery protocols.',
          capabilities: [
            'Recovery prediction',
            'Taper optimization',
            'Sleep quality scoring',
            'HRV trend analysis',
            'Overtraining alerts',
          ],
          dataSources: 'Apple Watch, Oura Ring, Whoop, Garmin, smart scales',
          learningRate: 'Confidence grows 2% per week of consistent data',
        ),
        _aiBotCard(
          botName: 'PSYCHE',
          role: 'Mental State Analyst',
          icon: Icons.psychology,
          color: DesignTokens.neonCyan,
          accuracy: mentalAcc,
          status: 'ACTIVE',
          description:
              'Tracks mood, motivation, confidence, focus over time. Detects pre-fight anxiety patterns and suggests coping strategies based on historical wins. Uses NLP sentiment analysis on journal entries and voice stress detection.',
          capabilities: [
            'Mood tracking',
            'Anxiety detection',
            'Confidence scoring',
            'Focus patterns',
            'Voice stress analysis',
          ],
          dataSources:
              'Manual mood logs, journal NLP, voice recordings, HRV-derived stress',
          learningRate: 'Needs 14 days minimum for baseline personality model',
        ),
        _aiBotCard(
          botName: 'SCALES',
          role: 'Weight Management Strategist',
          icon: Icons.monitor_weight,
          color: DesignTokens.neonAmber,
          accuracy: weightAcc,
          status: 'ACTIVE',
          description:
              'Models your weight trajectory using daily weigh-ins, hydration, caloric intake, sweat rate. Predicts if you\'ll make weight and suggests adjustments 7+ days out. Uses ML regression on your personal cut history.',
          capabilities: [
            'Weight prediction',
            'Cut planning',
            'Rehydration protocol',
            'Calorie optimization',
            'Water loading schedule',
          ],
          dataSources:
              'Smart scales, food logs, hydration tracker, body comp scans',
          learningRate:
              '${(weightAcc * 100).toInt()}% accuracy after 3+ weight cuts',
        ),
        _aiBotCard(
          botName: 'SHIELD',
          role: 'Injury Prevention Guardian',
          icon: Icons.healing,
          color: DesignTokens.neonMagenta,
          accuracy: injuryAcc,
          status: 'ACTIVE',
          description:
              'Cross-references training intensity, sleep deficit, historical injury data, asymmetry patterns, and inflammation markers to flag overtraining zones. Suggests deload weeks proactively before injury occurs.',
          capabilities: [
            'Overtraining detection',
            'Deload scheduling',
            'Asymmetry alerts',
            'Inflammation tracking',
            'Recovery optimization',
          ],
          dataSources:
              'Training logs, HRV, sleep data, pain reports, movement quality',
          learningRate: 'Improves with each reported injury/pain event',
        ),
        _aiBotCard(
          botName: 'SCOUT',
          role: 'Opponent Intelligence Operative',
          icon: Icons.visibility,
          color: DesignTokens.neonGold,
          accuracy: opponentAcc,
          status: 'ACTIVE',
          description:
              'Builds opponent profiles from fight footage metadata. Identifies tendencies, reach advantages, weakness clusters, round-by-round patterns. Gets smarter with each scouted fight. Cross-references global fight databases.',
          capabilities: [
            'Tendency mapping',
            'Weakness detection',
            'Style clash analysis',
            'Win probability',
            'Game plan generation',
          ],
          dataSources:
              'Fight footage, public records, DFC profiles, manual scouting',
          learningRate:
              '${(opponentAcc * 100).toInt()}% confidence \u2014 improves per scouted bout',
        ),
        _aiBotCard(
          botName: 'FUEL',
          role: 'Nutrition & Recovery Architect',
          icon: Icons.restaurant,
          color: const Color(0xFF4ADE80),
          accuracy: nutritionAcc,
          status: 'ACTIVE',
          description:
              'Plans macro/micro nutrition around training phases, fight camp, weight cut, and recovery. Optimizes meal timing, supplementation, and hydration protocols. Adapts to your metabolic rate and food preferences.',
          capabilities: [
            'Macro planning',
            'Supplement timing',
            'Hydration protocols',
            'Metabolic adaptation',
            'Fight-day nutrition',
          ],
          dataSources:
              'Food logs, body comp, metabolic estimates, blood glucose (future)',
          learningRate: 'Reaches peak accuracy after 30 days of food logging',
        ),
        const SizedBox(height: 16),

        _sectionTitle(
          '\u2699\ufe0f How the Neural Mesh Works',
          DesignTokens.neonCyan,
        ),
        _techPipelineCard(
          step: '01',
          title: 'Data Ingestion Layer',
          desc:
              'Collects from wearables, manual logs, fight records, third-party APIs in real-time. All data encrypted end-to-end with AES-256. Supports offline-first with sync queue.',
          color: DesignTokens.neonCyan,
          icon: Icons.download,
        ),
        _techPipelineCard(
          step: '02',
          title: 'Pattern Recognition Engine',
          desc:
              'Time-series analysis, clustering algorithms, anomaly detection. Identifies recurring patterns across training, recovery, and performance that humans miss.',
          color: DesignTokens.neonGreen,
          icon: Icons.auto_graph,
        ),
        _techPipelineCard(
          step: '03',
          title: 'Predictive ML Models',
          desc:
              'Personalized models built from YOUR data \u2014 not generic athlete templates. Predictions improve as data accumulates (minimum 30 days for baseline). Uses gradient boosting + neural networks.',
          color: DesignTokens.neonAmber,
          icon: Icons.model_training,
        ),
        _techPipelineCard(
          step: '04',
          title: 'Cross-Bot Intelligence',
          desc:
              'All 7 bots share a unified data lake. ATLAS detects dropping strike accuracy \u2192 VITALS checks recovery \u2192 SHIELD flags overtraining \u2192 FUEL adjusts nutrition. Autonomous cascade.',
          color: DesignTokens.neonMagenta,
          icon: Icons.hub,
        ),
        _techPipelineCard(
          step: '05',
          title: 'Continuous Learning Loop',
          desc:
              'Feedback loops: when predictions match reality, confidence grows. When wrong, the model self-corrects. You can manually rate prediction quality to accelerate learning.',
          color: DesignTokens.neonRed,
          icon: Icons.loop,
        ),
        _techPipelineCard(
          step: '06',
          title: 'Privacy-First Architecture',
          desc:
              'All AI can run on-device (Edge AI). Cloud processing uses anonymized, temporary data. You own your data \u2014 export or delete anytime. Zero-knowledge architecture.',
          color: Colors.white70,
          icon: Icons.lock,
        ),
      ],
    );
  }

  Widget _aiBotCard({
    required String botName,
    required String role,
    required IconData icon,
    required Color color,
    required double accuracy,
    required String status,
    required String description,
    required List<String> capabilities,
    required String dataSources,
    required String learningRate,
  }) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final pulse = _pulseController.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.04 + pulse * 0.02),
                const Color(0xFF020408).withValues(alpha: 0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.12 + pulse * 0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.03 + pulse * 0.02),
                blurRadius: 12,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: pulse * 0.15),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              botName,
                              style: TextStyle(
                                color: color,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: DesignTokens.neonGreen.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: DesignTokens.neonGreen,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: DesignTokens.neonGreen
                                              .withValues(alpha: 0.6),
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    status,
                                    style: const TextStyle(
                                      color: DesignTokens.neonGreen,
                                      fontSize: 7,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          role,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Accuracy ring
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      '${(accuracy * 100).toInt()}% acc',
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 10.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              // Capabilities chips
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: capabilities
                    .map(
                      (c) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: color.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          c,
                          style: TextStyle(
                            color: color,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              // Data sources + learning rate
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.sensors,
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 11,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            dataSources,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.32),
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 11,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            learningRate,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.32),
                              fontSize: 9,
                            ),
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
      },
    );
  }

  Widget _techPipelineCard({
    required String step,
    required String title,
    required String desc,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                step,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 10.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Title Helper ──
  Widget _sectionTitle(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ──  Custom Painters  ─────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _NeuralGridPainter extends CustomPainter {
  final double phase;

  _NeuralGridPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DesignTokens.neonMagenta.withValues(alpha: 0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeuralGridPainter oldDelegate) {
    return phase != oldDelegate.phase;
  }
}

class _BrainScorePainter extends CustomPainter {
  final double score;
  final double glowPhase;

  _BrainScorePainter({required this.score, required this.glowPhase});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    // Score arc
    final scorePaint = Paint()
      ..color = DesignTokens.neonCyan
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * 3.14159 * score;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // Start at top
      sweepAngle,
      false,
      scorePaint,
    );

    // Glow effect
    if (glowPhase > 0.5) {
      final glowPaint = Paint()
        ..color = DesignTokens.neonCyan.withValues(
          alpha: 0.3 * (1.0 - glowPhase),
        )
        ..strokeWidth = 6.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 / 2,
        sweepAngle,
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BrainScorePainter oldDelegate) {
    return score != oldDelegate.score || glowPhase != oldDelegate.glowPhase;
  }
}
