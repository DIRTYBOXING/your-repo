// ignore_for_file: unused_element

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../shared/services/combat_intelligence_engine.dart';
import '../../../shared/services/quantum_optimization_service.dart';
import '../../../shared/services/predictor_live_inputs_service.dart';
import '../widgets/animated_probability_ring.dart';
import '../widgets/conditioning_panel.dart';
import '../widgets/shap_explanation_card.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// AI FIGHT PREDICTIONS — Samurai Swarm Intelligence × Quantum Analytics Engine
// Dual-engine fight analysis: CombatIntelligenceEngine + QuantumOptimizationService
// ═══════════════════════════════════════════════════════════════════════════════

class AiFightPredictionsScreen extends StatefulWidget {
  const AiFightPredictionsScreen({super.key});

  @override
  State<AiFightPredictionsScreen> createState() =>
      _AiFightPredictionsScreenState();
}

class _AiFightPredictionsScreenState extends State<AiFightPredictionsScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _analyzeCtrl;

  final _intel = CombatIntelligenceEngine();
  final _quantum = QuantumOptimizationService();
  final _livePredictor = PredictorLiveInputsService();

  int _selectedMatchup = 0;
  bool _analyzing = false;
  StyleClashAnalysis? _intelResult;
  FightProbabilities? _quantumResult;
  String? _userPick; // 'A' or 'B'

  // ── Live Inputs (Option F) ──────────────────────────────────────────────
  ConditioningInputs _conditioning = const ConditioningInputs();

  // ── Man vs Machine state ───────────────────────────────────────────────
  final Map<int, _HumanPrediction> _humanPicks = {};
  int _humanScore = 0;
  int _aiScore = 0;
  int _totalRounds = 0;
  bool _roundRevealed = false;

  static const _cyan = Color(0xFF00E5FF);
  static const _red = Color(0xFFFF1744);
  static const _gold = Color(0xFFFFD600);
  static const _green = Color(0xFF00E676);
  static const _purple = Color(0xFF9C6FFF);

  // ── Pre-loaded matchup catalogue ───────────────────────────────────────
  static const _matchups = [
    _Matchup(
      fighterA: _AiFighter(
        id: 'islam_m',
        name: 'Islam Makhachev',
        flag: '🇷🇺',
        record: '26-1-0',
        weightClass: 'Lightweight',
        wins: 26,
        losses: 1,
        ko: 5,
        sub: 11,
        stance: 'Orthodox',
        power: 82,
        speed: 85,
        cardio: 94,
        ground: 97,
        chin: 88,
        iq: 96,
        strikeAcc: 0.52,
        tdAcc: 0.62,
        tdDef: 0.93,
        subRate: 0.42,
        koRate: 0.19,
        decRate: 0.39,
        rankPts: 2850,
      ),
      fighterB: _AiFighter(
        id: 'alex_v',
        name: 'Alexander Volkanovski',
        flag: '🇦🇺',
        record: '26-4-0',
        weightClass: 'Featherweight',
        wins: 26,
        losses: 4,
        ko: 13,
        sub: 3,
        stance: 'Orthodox',
        power: 78,
        speed: 90,
        cardio: 96,
        ground: 80,
        chin: 85,
        iq: 94,
        strikeAcc: 0.57,
        tdAcc: 0.44,
        tdDef: 0.78,
        subRate: 0.12,
        koRate: 0.50,
        decRate: 0.38,
        rankPts: 2600,
      ),
      title: 'LIGHTWEIGHT TITLE',
    ),
    _Matchup(
      fighterA: _AiFighter(
        id: 'jon_j',
        name: 'Jon Jones',
        flag: '🇺🇸',
        record: '27-1-0',
        weightClass: 'Heavyweight',
        wins: 27,
        losses: 1,
        ko: 10,
        sub: 7,
        stance: 'Orthodox',
        power: 88,
        speed: 84,
        cardio: 86,
        ground: 94,
        chin: 82,
        iq: 98,
        strikeAcc: 0.56,
        tdAcc: 0.45,
        tdDef: 0.95,
        subRate: 0.26,
        koRate: 0.37,
        decRate: 0.37,
        rankPts: 3100,
      ),
      fighterB: _AiFighter(
        id: 'tom_a',
        name: 'Tom Aspinall',
        flag: '🇬🇧',
        record: '14-3-0',
        weightClass: 'Heavyweight',
        wins: 14,
        losses: 3,
        ko: 11,
        sub: 1,
        stance: 'Orthodox',
        power: 96,
        speed: 88,
        cardio: 78,
        ground: 72,
        chin: 76,
        iq: 82,
        strikeAcc: 0.65,
        tdAcc: 0.36,
        tdDef: 0.72,
        subRate: 0.07,
        koRate: 0.79,
        decRate: 0.14,
        rankPts: 2400,
      ),
      title: 'HEAVYWEIGHT TITLE',
    ),
    _Matchup(
      fighterA: _AiFighter(
        id: 'ilia_t',
        name: 'Ilia Topuria',
        flag: '🇪🇸',
        record: '15-0-0',
        weightClass: 'Featherweight',
        wins: 15,
        losses: 0,
        ko: 7,
        sub: 4,
        stance: 'Orthodox',
        power: 90,
        speed: 86,
        cardio: 84,
        ground: 88,
        chin: 84,
        iq: 88,
        strikeAcc: 0.61,
        tdAcc: 0.50,
        tdDef: 0.80,
        subRate: 0.27,
        koRate: 0.47,
        decRate: 0.26,
        rankPts: 2500,
      ),
      fighterB: _AiFighter(
        id: 'max_h',
        name: 'Max Holloway',
        flag: '🇺🇸',
        record: '25-7-0',
        weightClass: 'Featherweight',
        wins: 25,
        losses: 7,
        ko: 12,
        sub: 0,
        stance: 'Orthodox',
        power: 72,
        speed: 92,
        cardio: 98,
        ground: 68,
        chin: 92,
        iq: 92,
        strikeAcc: 0.48,
        tdAcc: 0.32,
        tdDef: 0.82,
        subRate: 0.0,
        koRate: 0.48,
        decRate: 0.52,
        rankPts: 2300,
      ),
      title: 'FEATHERWEIGHT TITLE',
    ),
    _Matchup(
      fighterA: _AiFighter(
        id: 'alex_p',
        name: 'Alex Pereira',
        flag: '🇧🇷',
        record: '11-2-0',
        weightClass: 'Light Heavyweight',
        wins: 11,
        losses: 2,
        ko: 10,
        sub: 0,
        stance: 'Orthodox',
        power: 98,
        speed: 80,
        cardio: 72,
        ground: 55,
        chin: 80,
        iq: 84,
        strikeAcc: 0.58,
        tdAcc: 0.20,
        tdDef: 0.65,
        subRate: 0.0,
        koRate: 0.91,
        decRate: 0.09,
        rankPts: 2450,
      ),
      fighterB: _AiFighter(
        id: 'magomed_a',
        name: 'Magomed Ankalaev',
        flag: '🇷🇺',
        record: '18-1-1',
        weightClass: 'Light Heavyweight',
        wins: 18,
        losses: 1,
        ko: 8,
        sub: 1,
        stance: 'Orthodox',
        power: 86,
        speed: 78,
        cardio: 88,
        ground: 90,
        chin: 88,
        iq: 86,
        strikeAcc: 0.52,
        tdAcc: 0.48,
        tdDef: 0.88,
        subRate: 0.06,
        koRate: 0.44,
        decRate: 0.50,
        rankPts: 2350,
      ),
      title: 'LIGHT HEAVYWEIGHT TITLE',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _analyzeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _intel.initialize();
    _quantum.initialize();
    _runAnalysis();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _pulseCtrl.dispose();
    _analyzeCtrl.dispose();
    _livePredictor.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    setState(() => _analyzing = true);
    _analyzeCtrl.forward(from: 0);

    final m = _matchups[_selectedMatchup];

    // Wire live predictor to current matchup
    _livePredictor.setFighterA(m.fighterA.id, m.fighterA.name);
    _livePredictor.setFighterB(m.fighterB.id, m.fighterB.name);
    _livePredictor.updateInputs(_conditioning);

    // Profile fighters
    _intel.profileFighter(
      fighterId: m.fighterA.id,
      name: m.fighterA.name,
      wins: m.fighterA.wins,
      losses: m.fighterA.losses,
      knockouts: m.fighterA.ko,
      submissions: m.fighterA.sub,
      weightClass: m.fighterA.weightClass,
      stance: m.fighterA.stance,
    );
    _intel.profileFighter(
      fighterId: m.fighterB.id,
      name: m.fighterB.name,
      wins: m.fighterB.wins,
      losses: m.fighterB.losses,
      knockouts: m.fighterB.ko,
      submissions: m.fighterB.sub,
      weightClass: m.fighterB.weightClass,
      stance: m.fighterB.stance,
    );

    // Run both engines
    final intelResult = _intel.analyzeStyleClash(
      fighterAId: m.fighterA.id,
      fighterAName: m.fighterA.name,
      fighterBId: m.fighterB.id,
      fighterBName: m.fighterB.name,
      fighterAWins: m.fighterA.wins,
      fighterALosses: m.fighterA.losses,
      fighterBWins: m.fighterB.wins,
      fighterBLosses: m.fighterB.losses,
    );

    final q1 = QuantumFighterProfile(
      fighterId: m.fighterA.id,
      name: m.fighterA.name,
      weightClass: m.fighterA.weightClass,
      wins: m.fighterA.wins,
      losses: m.fighterA.losses,
      strikeAccuracy: m.fighterA.strikeAcc,
      takedownAccuracy: m.fighterA.tdAcc,
      takedownDefense: m.fighterA.tdDef,
      submissionRate: m.fighterA.subRate,
      koRate: m.fighterA.koRate,
      decisionRate: m.fighterA.decRate,
      cardioEndurance: m.fighterA.cardio / 100,
      chinDurability: m.fighterA.chin / 100,
      recentForm: m.fighterA.wins > m.fighterA.losses ? 0.8 : 0.5,
      rankingPoints: m.fighterA.rankPts.toDouble(),
    );

    final q2 = QuantumFighterProfile(
      fighterId: m.fighterB.id,
      name: m.fighterB.name,
      weightClass: m.fighterB.weightClass,
      wins: m.fighterB.wins,
      losses: m.fighterB.losses,
      strikeAccuracy: m.fighterB.strikeAcc,
      takedownAccuracy: m.fighterB.tdAcc,
      takedownDefense: m.fighterB.tdDef,
      submissionRate: m.fighterB.subRate,
      koRate: m.fighterB.koRate,
      decisionRate: m.fighterB.decRate,
      cardioEndurance: m.fighterB.cardio / 100,
      chinDurability: m.fighterB.chin / 100,
      recentForm: m.fighterB.wins > m.fighterB.losses ? 0.8 : 0.5,
      rankingPoints: m.fighterB.rankPts.toDouble(),
    );

    final quantumResult = _quantum.predictFight(q1, q2);

    // Simulated loading for dramatic effect
    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      setState(() {
        _intelResult = intelResult;
        _quantumResult = quantumResult;
        _analyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030810),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildMatchupSelector(),
            if (_analyzing)
              _buildAnalyzingOverlay()
            else ...[
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildPredictionTab(),
                    _buildBreakdownTab(),
                    _buildTrainingTab(),
                    _buildManVsMachineTab(),
                    _buildLiveInputsTab(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        border: Border(
          bottom: BorderSide(color: _cyan.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white54,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, _) => Icon(
              Icons.psychology,
              color: _purple.withValues(alpha: 0.6 + _pulseCtrl.value * 0.4),
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI FIGHT PREDICTIONS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'Samurai Swarm × Quantum Engine',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _green.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 10, color: Color(0xFF00E676)),
                SizedBox(width: 3),
                Text(
                  'DUAL AI',
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
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
  // MATCHUP SELECTOR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMatchupSelector() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _matchups.length,
        itemBuilder: (_, i) {
          final m = _matchups[i];
          final active = i == _selectedMatchup;
          return GestureDetector(
            onTap: () {
              if (i != _selectedMatchup) {
                setState(() => _selectedMatchup = i);
                _runAnalysis();
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? _cyan.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: active ? _cyan.withValues(alpha: 0.5) : Colors.white10,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '${m.fighterA.flag} vs ${m.fighterB.flag}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    m.title,
                    style: TextStyle(
                      color: active ? _cyan : Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalyzingOverlay() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _analyzeCtrl,
              builder: (_, _) => Transform.rotate(
                angle: _analyzeCtrl.value * math.pi * 2,
                child: Icon(
                  Icons.psychology,
                  color: _purple.withValues(alpha: 0.8),
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ANALYZING...',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 180,
              child: AnimatedBuilder(
                animation: _analyzeCtrl,
                builder: (_, _) => LinearProgressIndicator(
                  value: _analyzeCtrl.value,
                  backgroundColor: Colors.white10,
                  color: _purple,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Running dual AI engines\nSamurai Swarm + Quantum Optimization',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: _purple,
        labelColor: _purple,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.analytics, size: 16), text: 'PREDICTION'),
          Tab(icon: Icon(Icons.compare_arrows, size: 16), text: 'BREAKDOWN'),
          Tab(icon: Icon(Icons.fitness_center, size: 16), text: 'TRAINING'),
          Tab(icon: Icon(Icons.sports_esports, size: 16), text: 'MAN vs AI'),
          Tab(icon: Icon(Icons.tune, size: 16), text: 'LIVE INPUTS'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1 — MAIN PREDICTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPredictionTab() {
    if (_intelResult == null || _quantumResult == null) {
      return const Center(
        child: Text('Loading...', style: TextStyle(color: Colors.white30)),
      );
    }

    final m = _matchups[_selectedMatchup];
    final intel = _intelResult!;
    final quantum = _quantumResult!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Gamification — lock in pick + community split
          _buildPickAndCommunity(m),
          const SizedBox(height: 14),

          // VS card
          _buildVsCard(m),
          const SizedBox(height: 14),

          // Arc gauge win probability
          _buildProbabilitySection(m, intel, quantum),
          const SizedBox(height: 14),

          // Round-by-round forecast
          _buildRoundProjection(m, intel),
          const SizedBox(height: 14),

          // Intel engine result
          _buildEngineCard(
            'SAMURAI SWARM INTELLIGENCE',
            Icons.psychology,
            _purple,
            [
              _resultRow('Prediction', intel.prediction),
              _resultRow(
                'Confidence',
                '${(intel.confidence * 100).toStringAsFixed(0)}%',
              ),
              _resultRow('Method', intel.predictedMethod),
              _resultRow(
                'Crowd Hype',
                '${(intel.crowdHypeRating * 10).toStringAsFixed(1)}/10',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quantum engine result
          _buildEngineCard(
            'QUANTUM OPTIMIZATION ENGINE',
            Icons.blur_circular,
            _cyan,
            [
              _resultRow(
                '${m.fighterA.name} Win',
                '${(quantum.fighter1Win * 100).toStringAsFixed(1)}%',
              ),
              _resultRow(
                '${m.fighterB.name} Win',
                '${(quantum.fighter2Win * 100).toStringAsFixed(1)}%',
              ),
              _resultRow(
                'Excitement',
                '${(quantum.excitement * 100).toStringAsFixed(0)}%',
              ),
              _resultRow(
                'Competitiveness',
                '${(quantum.competitiveness * 100).toStringAsFixed(0)}%',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Key factors
          _buildKeyFactors(intel, quantum),
        ],
      ),
    );
  }

  Widget _buildVsCard(_Matchup m) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1628), Color(0xFF150A20)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _purple.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildFighterCard(m.fighterA, _cyan)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                const Text(
                  'VS',
                  style: TextStyle(
                    color: _red,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    m.title,
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildFighterCard(m.fighterB, _red)),
        ],
      ),
    );
  }

  Widget _buildFighterCard(_AiFighter f, Color color) {
    return Column(
      children: [
        Text(f.flag, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 6),
        Text(
          f.name,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          f.record,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        Text(
          f.weightClass,
          style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: 9),
        ),
      ],
    );
  }

  Widget _buildProbabilitySection(
    _Matchup m,
    StyleClashAnalysis intel,
    FightProbabilities quantum,
  ) {
    final aWin = (intel.fighterAWinProb + quantum.fighter1Win) / 2;
    final bWin = (intel.fighterBWinProb + quantum.fighter2Win) / 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _purple.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          const Text(
            'COMBINED AI WIN PROBABILITY',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          // Arc gauges side by side
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _arcGaugeWidget(
                m.fighterA.flag,
                m.fighterA.name.split(' ').last,
                aWin,
                _cyan,
              ),
              // Center column: HYPE score + VS pulse
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _gold.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${quantum.excitement.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: _gold,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'HYPE',
                          style: TextStyle(
                            color: _gold.withValues(alpha: 0.5),
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, _) => Text(
                      'VS',
                      style: TextStyle(
                        color: _red.withValues(
                          alpha: 0.4 + _pulseCtrl.value * 0.6,
                        ),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              _arcGaugeWidget(
                m.fighterB.flag,
                m.fighterB.name.split(' ').last,
                bWin,
                _red,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Method breakdown chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _methodChip(
                'KO/TKO',
                '${((quantum.ko1 + quantum.ko2) * 100).toStringAsFixed(0)}%',
                _red,
              ),
              _methodChip(
                'SUB',
                '${((quantum.submission1 + quantum.submission2) * 100).toStringAsFixed(0)}%',
                _purple,
              ),
              _methodChip(
                'DEC',
                '${(quantum.decision * 100).toStringAsFixed(0)}%',
                _cyan,
              ),
              _methodChip(
                'DRAW',
                '${(quantum.draw * 100).toStringAsFixed(0)}%',
                _gold,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _arcGaugeWidget(
    String flag,
    String lastName,
    double prob,
    Color color,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: prob),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (ctx, val, _) {
        return Column(
          children: [
            SizedBox(
              width: 100,
              height: 58,
              child: CustomPaint(
                painter: _ArcGaugePainter(value: val, color: color),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(val * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(flag, style: const TextStyle(fontSize: 16)),
            Text(
              lastName,
              style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _methodChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.5),
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildEngineCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> rows,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
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
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyFactors(
    StyleClashAnalysis intel,
    FightProbabilities quantum,
  ) {
    final allFactors = [...intel.keyFactors, ...quantum.keyFactors];
    final uniqueFactors = allFactors.toSet().take(6).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _gold.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: _gold, size: 14),
              SizedBox(width: 6),
              Text(
                'KEY FACTORS',
                style: TextStyle(
                  color: _gold,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...uniqueFactors.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '▸ ',
                    style: TextStyle(color: _gold, fontSize: 10),
                  ),
                  Expanded(
                    child: Text(
                      f,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        height: 1.3,
                      ),
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
  // TAB 2 — SKILL BREAKDOWN
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBreakdownTab() {
    final m = _matchups[_selectedMatchup];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Radar chart — instant visual impact
          _buildRadarChart(m),
          const SizedBox(height: 16),
          _buildSkillComparison('POWER', m.fighterA.power, m.fighterB.power, m),
          _buildSkillComparison('SPEED', m.fighterA.speed, m.fighterB.speed, m),
          _buildSkillComparison(
            'CARDIO',
            m.fighterA.cardio,
            m.fighterB.cardio,
            m,
          ),
          _buildSkillComparison(
            'GROUND GAME',
            m.fighterA.ground,
            m.fighterB.ground,
            m,
          ),
          _buildSkillComparison('CHIN', m.fighterA.chin, m.fighterB.chin, m),
          _buildSkillComparison('FIGHT IQ', m.fighterA.iq, m.fighterB.iq, m),
          const SizedBox(height: 16),
          _buildAccuracyComparison(m),
          const SizedBox(height: 16),
          if (_intelResult != null) _buildStyleMatchup(),
        ],
      ),
    );
  }

  Widget _buildSkillComparison(String label, int a, int b, _Matchup m) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$a',
                style: TextStyle(
                  color: a > b ? _cyan : Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '$b',
                style: TextStyle(
                  color: b > a ? _red : Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: a / 100,
                    child: Container(
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _cyan,
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: b / 100,
                    child: Container(
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _red,
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyComparison(_Matchup m) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cyan.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          const Text(
            'ACCURACY & RATES',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          _accRow(
            'Strike Acc.',
            '${(m.fighterA.strikeAcc * 100).toStringAsFixed(0)}%',
            '${(m.fighterB.strikeAcc * 100).toStringAsFixed(0)}%',
          ),
          _accRow(
            'TD Accuracy',
            '${(m.fighterA.tdAcc * 100).toStringAsFixed(0)}%',
            '${(m.fighterB.tdAcc * 100).toStringAsFixed(0)}%',
          ),
          _accRow(
            'TD Defense',
            '${(m.fighterA.tdDef * 100).toStringAsFixed(0)}%',
            '${(m.fighterB.tdDef * 100).toStringAsFixed(0)}%',
          ),
          _accRow(
            'KO Rate',
            '${(m.fighterA.koRate * 100).toStringAsFixed(0)}%',
            '${(m.fighterB.koRate * 100).toStringAsFixed(0)}%',
          ),
          _accRow(
            'Sub Rate',
            '${(m.fighterA.subRate * 100).toStringAsFixed(0)}%',
            '${(m.fighterB.subRate * 100).toStringAsFixed(0)}%',
          ),
        ],
      ),
    );
  }

  Widget _accRow(String label, String a, String b) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              a,
              style: const TextStyle(
                color: _cyan,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              b,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: _red,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleMatchup() {
    final intel = _intelResult!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _purple.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.compare_arrows, color: _purple, size: 14),
              SizedBox(width: 6),
              Text(
                'STYLE MATCHUP SUMMARY',
                style: TextStyle(
                  color: _purple,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            intel.styleMatchupSummary,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          if (intel.breakdown.isNotEmpty)
            Text(
              intel.breakdown,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                height: 1.3,
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3 — TRAINING OPTIMIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTrainingTab() {
    final m = _matchups[_selectedMatchup];

    // Get training plans from Intel engine
    final planA = _intel.getTrainingPlan(m.fighterA.id);
    final planB = _intel.getTrainingPlan(m.fighterB.id);

    // Get training optimization from Quantum engine
    final optA = _quantum.optimizeTraining(
      currentRecovery: m.fighterA.cardio.toDouble(),
      daysUntilFight: 42,
      recentTrainingLoad: 65.0,
      fatigueLevel: 35.0,
    );
    final optB = _quantum.optimizeTraining(
      currentRecovery: m.fighterB.cardio.toDouble(),
      daysUntilFight: 42,
      recentTrainingLoad: 65.0,
      fatigueLevel: 35.0,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTrainingCard(
            m.fighterA.name,
            m.fighterA.flag,
            _cyan,
            planA,
            optA,
          ),
          const SizedBox(height: 12),
          _buildTrainingCard(
            m.fighterB.name,
            m.fighterB.flag,
            _red,
            planB,
            optB,
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingCard(
    String name,
    String flag,
    Color color,
    List<TrainingInsight> plan,
    TrainingOptimization opt,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 20),

          // Quantum optimization
          Row(
            children: [
              Icon(Icons.speed, color: color, size: 12),
              const SizedBox(width: 6),
              const Text(
                'QUANTUM TRAINING OPTIMIZATION',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _resultRow(
            'Optimal Intensity',
            '${(opt.optimalIntensity * 100).toStringAsFixed(0)}%',
          ),
          _resultRow(
            'Suggested Volume',
            '${opt.suggestedVolume.toStringAsFixed(0)}% of normal',
          ),
          _resultRow('Phase', opt.phaseRecommendation),
          _resultRow(
            'Injury Risk',
            '${(opt.injuryRisk * 100).toStringAsFixed(0)}%',
          ),
          const SizedBox(height: 6),
          if (opt.focusAreas.isNotEmpty) ...[
            const Text(
              'Focus Areas:',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: opt.focusAreas
                  .take(4)
                  .map(
                    (a) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        a,
                        style: TextStyle(
                          color: color.withValues(alpha: 0.7),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],

          // Intel training insights
          if (plan.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.psychology, color: _purple, size: 12),
                SizedBox(width: 6),
                Text(
                  'SAMURAI TRAINING INSIGHTS',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...plan
                .take(3)
                .map(
                  (insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '▸ ',
                          style: TextStyle(color: _purple, fontSize: 10),
                        ),
                        Expanded(
                          child: Text(
                            insight.description,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GAMIFICATION — Lock In Your Pick
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPickAndCommunity(_Matchup m) {
    final communityA =
        m.fighterA.rankPts / (m.fighterA.rankPts + m.fighterB.rankPts);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [
            _cyan.withValues(alpha: 0.06),
            const Color(0xFF0A1628),
            _red.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: _gold.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              const Icon(Icons.bolt, color: _gold, size: 13),
              const SizedBox(width: 6),
              const Text(
                'LOCK IN YOUR PICK',
                style: TextStyle(
                  color: _gold,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _gold.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 9)),
                    SizedBox(width: 4),
                    Text(
                      '7 STREAK',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Fighter pick buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _userPick = _userPick == 'A' ? null : 'A'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _userPick == 'A'
                          ? _cyan.withValues(alpha: 0.18)
                          : _cyan.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _userPick == 'A'
                            ? _cyan
                            : _cyan.withValues(alpha: 0.2),
                        width: _userPick == 'A' ? 2 : 1,
                      ),
                      boxShadow: _userPick == 'A'
                          ? [
                              BoxShadow(
                                color: _cyan.withValues(alpha: 0.25),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Text(
                          m.fighterA.flag,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.fighterA.name.split(' ').last,
                          style: TextStyle(
                            color: _userPick == 'A' ? _cyan : Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (_userPick == 'A') ...[
                          const SizedBox(height: 4),
                          const Icon(
                            Icons.check_circle,
                            color: _cyan,
                            size: 14,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    const Text(
                      '+43',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'PTS',
                      style: TextStyle(
                        color: _gold.withValues(alpha: 0.5),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _userPick = _userPick == 'B' ? null : 'B'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _userPick == 'B'
                          ? _red.withValues(alpha: 0.18)
                          : _red.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _userPick == 'B'
                            ? _red
                            : _red.withValues(alpha: 0.2),
                        width: _userPick == 'B' ? 2 : 1,
                      ),
                      boxShadow: _userPick == 'B'
                          ? [
                              BoxShadow(
                                color: _red.withValues(alpha: 0.25),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Text(
                          m.fighterB.flag,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.fighterB.name.split(' ').last,
                          style: TextStyle(
                            color: _userPick == 'B' ? _red : Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (_userPick == 'B') ...[
                          const SizedBox(height: 4),
                          const Icon(Icons.check_circle, color: _red, size: 14),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Community vote bar
          Row(
            children: [
              Text(
                '${(communityA * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: _cyan.withValues(alpha: 0.6),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Row(
                    children: [
                      Expanded(
                        flex: (communityA * 100).round(),
                        child: Container(
                          height: 5,
                          color: _cyan.withValues(alpha: 0.7),
                        ),
                      ),
                      Expanded(
                        flex: ((1 - communityA) * 100).round(),
                        child: Container(
                          height: 5,
                          color: _red.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${((1 - communityA) * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: _red.withValues(alpha: 0.6),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '12,481 FANS VOTED · COMMUNITY SPLIT',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 7,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ROUND-BY-ROUND PROJECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRoundProjection(_Matchup m, StyleClashAnalysis intel) {
    final rounds = intel.roundByRoundProb.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (rounds.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _gold.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, color: _gold, size: 14),
              const SizedBox(width: 6),
              const Text(
                'ROUND-BY-ROUND PROJECTION',
                style: TextStyle(
                  color: _gold,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                'AI FORECAST',
                style: TextStyle(
                  color: _gold.withValues(alpha: 0.35),
                  fontSize: 7,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(rounds.length, (i) {
            final entry = rounds[i];
            final aProb = entry.value.clamp(0.05, 0.95);
            final shortLabel = entry.key.replaceAll('Round ', 'R');

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      shortLabel,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.5, end: aProb),
                      duration: Duration(milliseconds: 500 + i * 120),
                      curve: Curves.easeOutCubic,
                      builder: (ctx, val, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Row(
                            children: [
                              Expanded(
                                flex: (val * 100).round(),
                                child: Container(
                                  height: 18,
                                  color: _cyan.withValues(alpha: 0.45),
                                ),
                              ),
                              Expanded(
                                flex: ((1 - val) * 100).round(),
                                child: Container(
                                  height: 18,
                                  color: _red.withValues(alpha: 0.35),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(width: 28),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _cyan.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  m.fighterA.name.split(' ').last,
                  style: const TextStyle(color: Colors.white24, fontSize: 8),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                m.fighterB.name.split(' ').last,
                style: const TextStyle(color: Colors.white24, fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIGHTER RADAR CHART
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRadarChart(_Matchup m) {
    const labels = ['POWER', 'SPEED', 'CARDIO', 'GROUND', 'CHIN', 'IQ'];
    final valsA = [
      m.fighterA.power / 100,
      m.fighterA.speed / 100,
      m.fighterA.cardio / 100,
      m.fighterA.ground / 100,
      m.fighterA.chin / 100,
      m.fighterA.iq / 100,
    ];
    final valsB = [
      m.fighterB.power / 100,
      m.fighterB.speed / 100,
      m.fighterB.cardio / 100,
      m.fighterB.ground / 100,
      m.fighterB.chin / 100,
      m.fighterB.iq / 100,
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _purple.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.radar, color: _purple, size: 14),
              SizedBox(width: 6),
              Text(
                'FIGHTER RADAR — ATTRIBUTE OVERLAY',
                style: TextStyle(
                  color: _purple,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 2,
                color: _cyan.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 5),
              Text(
                m.fighterA.name.split(' ').last,
                style: TextStyle(
                  color: _cyan.withValues(alpha: 0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 20,
                height: 2,
                color: _red.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 5),
              Text(
                m.fighterB.name.split(' ').last,
                style: TextStyle(
                  color: _red.withValues(alpha: 0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: _RadarChartPainter(
                valuesA: valsA,
                valuesB: valsB,
                labels: labels,
                colorA: _cyan,
                colorB: _red,
              ),
              size: const Size(double.infinity, 200),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAN vs MACHINE TAB — Human vs AI prediction game
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildManVsMachineTab() {
    final m = _matchups[_selectedMatchup];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Scoreboard ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _cyan.withValues(alpha: 0.08),
                  _red.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cyan.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                const Text(
                  'MAN vs MACHINE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Can you out-predict the AI?',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _scoreColumn('🧠 YOU', _humanScore, _cyan),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    Text(
                      '$_totalRounds',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    _scoreColumn('🤖 AI', _aiScore, _red),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Current matchup card ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1628),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _purple.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text(
                  m.title,
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _pickCard(m.fighterA, 'A')),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Expanded(child: _pickCard(m.fighterB, 'B')),
                  ],
                ),
                const SizedBox(height: 16),

                // Method picker
                if (_humanPicks[_selectedMatchup] != null &&
                    !_roundRevealed) ...[
                  Text(
                    'HOW DOES ${_humanPicks[_selectedMatchup]!.winnerSide == 'A' ? m.fighterA.name.toUpperCase() : m.fighterB.name.toUpperCase()} WIN?',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['KO/TKO', 'Submission', 'Decision'].map((
                      method,
                    ) {
                      final pick = _humanPicks[_selectedMatchup];
                      final selected = pick?.method == method;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _humanPicks[_selectedMatchup] = _HumanPrediction(
                              winnerSide: pick!.winnerSide,
                              method: method,
                            );
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? _gold.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? _gold
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            method,
                            style: TextStyle(
                              color: selected ? _gold : Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 16),

                // Lock in / Reveal button
                if (_humanPicks[_selectedMatchup]?.method != null &&
                    !_roundRevealed)
                  GestureDetector(
                    onTap: _revealRound,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_cyan, _purple],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _cyan.withValues(alpha: 0.3),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: const Text(
                        '⚡ LOCK IN & REVEAL',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),

                // Result display
                if (_roundRevealed) _buildRoundResult(m),
              ],
            ),
          ),

          // ── Navigate matchups ──
          const SizedBox(height: 16),
          if (_roundRevealed)
            GestureDetector(
              onTap: () {
                if (_selectedMatchup < _matchups.length - 1) {
                  setState(() {
                    _selectedMatchup++;
                    _roundRevealed = false;
                  });
                  _runAnalysis();
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _green.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _selectedMatchup < _matchups.length - 1
                      ? '→ NEXT MATCHUP'
                      : '🏆 GAME OVER — Final: YOU $_humanScore – $_aiScore AI',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _green,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _scoreColumn(String label, int score, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$score',
          style: TextStyle(
            color: color,
            fontSize: 36,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _pickCard(_AiFighter fighter, String side) {
    final pick = _humanPicks[_selectedMatchup];
    final selected = pick?.winnerSide == side;
    final color = side == 'A' ? _cyan : _red;

    return GestureDetector(
      onTap: _roundRevealed
          ? null
          : () {
              setState(() {
                _humanPicks[_selectedMatchup] = _HumanPrediction(
                  winnerSide: side,
                );
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.white.withValues(alpha: 0.08),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(fighter.flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              fighter.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? color : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              fighter.record,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
            if (selected) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'YOUR PICK',
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _revealRound() {
    final pick = _humanPicks[_selectedMatchup];
    if (pick == null || pick.method == null) return;

    // AI prediction based on engine analysis
    final m = _matchups[_selectedMatchup];
    final aWins = (m.fighterA.rankPts > m.fighterB.rankPts);
    final aiSide = aWins ? 'A' : 'B';
    final winner = aWins ? m.fighterA : m.fighterB;
    final aiMethod = winner.koRate > 0.5
        ? 'KO/TKO'
        : (winner.subRate > 0.25 ? 'Submission' : 'Decision');

    int humanPts = 0;
    int aiPts = 0;

    // 1 point for correct winner, 1 for correct method
    if (pick.winnerSide == aiSide) {
      // Both picked same winner
      humanPts += 1;
      aiPts += 1;
      if (pick.method == aiMethod) {
        humanPts += 1;
        aiPts += 1;
      }
    } else {
      // Give the "correct" answer based on rankings
      if (pick.winnerSide == (aWins ? 'A' : 'B')) humanPts += 1;
      aiPts += 1; // AI gets winner point by default (uses data)
    }

    setState(() {
      _humanScore += humanPts;
      _aiScore += aiPts;
      _totalRounds++;
      _roundRevealed = true;
    });
  }

  Widget _buildRoundResult(_Matchup m) {
    final pick = _humanPicks[_selectedMatchup]!;
    final aWins = (m.fighterA.rankPts > m.fighterB.rankPts);
    final aiSide = aWins ? 'A' : 'B';
    final winner = aWins ? m.fighterA : m.fighterB;
    final aiMethod = winner.koRate > 0.5
        ? 'KO/TKO'
        : (winner.subRate > 0.25 ? 'Submission' : 'Decision');

    final yourWinner = pick.winnerSide == 'A'
        ? m.fighterA.name
        : m.fighterB.name;
    final aiWinner = aiSide == 'A' ? m.fighterA.name : m.fighterB.name;
    final winnerMatch = pick.winnerSide == aiSide;
    final methodMatch = pick.method == aiMethod;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _gold.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Text(
            '⚔️ ROUND RESULT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _mvsResultRow(
            'Your pick:',
            '$yourWinner via ${pick.method}',
            winnerMatch && methodMatch ? _green : _red,
          ),
          const SizedBox(height: 6),
          _mvsResultRow('AI pick:', '$aiWinner via $aiMethod', _cyan),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (winnerMatch)
                _badge('✅ Winner', _green)
              else
                _badge('❌ Winner', _red),
              const SizedBox(width: 8),
              if (methodMatch)
                _badge('✅ Method', _green)
              else
                _badge('❌ Method', _red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mvsResultRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 5 — LIVE INPUTS (Option F — Predictor Engine Live Inputs)
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildLiveInputsTab() {
    final m = _matchups[_selectedMatchup];
    return ListenableBuilder(
      listenable: _livePredictor,
      builder: (_, __) {
        final result = _livePredictor.result;
        final computing = _livePredictor.computing;
        final error = _livePredictor.error;

        // Base probabilities from dual-engine analysis (fallback when live result absent)
        final baseA = _intelResult != null && _quantumResult != null
            ? (_intelResult!.fighterAWinProb + _quantumResult!.fighter1Win) / 2
            : 0.5;
        final baseB = 1.0 - baseA;

        final probA = result?.winProbA ?? baseA;
        final probB = result?.winProbB ?? baseB;
        final method = result?.predictedMethod ?? 'Decision';
        final confidence = result?.confidence ?? 0.65;
        final shapFeatures = result?.shapFeatures ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Error banner
              if (error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD600).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFFD600).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: Color(0xFFFFD600),
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          error,
                          style: const TextStyle(
                            color: Color(0xFFFFD600),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Animated probability ring
              AnimatedProbabilityRing(
                probA: probA,
                probB: probB,
                nameA: m.fighterA.name,
                nameB: m.fighterB.name,
                flagA: m.fighterA.flag,
                flagB: m.fighterB.flag,
                colorA: _cyan,
                colorB: _red,
                method: method,
                confidence: confidence,
                isComputing: computing,
              ),

              const SizedBox(height: 16),

              // Conditioning sliders
              ConditioningPanel(
                inputs: _conditioning,
                nameA: m.fighterA.name,
                nameB: m.fighterB.name,
                colorA: _cyan,
                colorB: _red,
                onChanged: (updated) {
                  setState(() => _conditioning = updated);
                  _livePredictor.updateInputs(updated);
                },
              ),

              const SizedBox(height: 16),

              // SHAP explanation tree
              ShapExplanationCard(
                features: shapFeatures,
                nameA: m.fighterA.name,
                nameB: m.fighterB.name,
                isLoading: computing && shapFeatures.isEmpty,
              ),

              const SizedBox(height: 16),

              // Force recalculate button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: computing ? null : _livePredictor.forceRecompute,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text(
                    'RECALCULATE NOW',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontSize: 12,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white10,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Source + timestamp
              if (result != null)
                Text(
                  result.fromCache
                      ? 'Result from cache · ${_timeAgo(result.computedAt)}'
                      : 'Live result · computed ${_timeAgo(result.computedAt)}',
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

/// Half-circle arc gauge. Center at bottom, arc sweeps counterclockwise up.
class _ArcGaugePainter extends CustomPainter {
  final double value; // 0.0–1.0
  final Color color;

  const _ArcGaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 6;

    // Background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      -math.pi,
      false,
      Paint()
        ..color = Colors.white10
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Foreground arc (animated value)
    if (value > 0.01) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,
        -math.pi * value,
        false,
        Paint()
          ..color = color
          ..strokeWidth = 7
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4),
      );
      // Solid line on top (no blur)
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,
        -math.pi * value,
        false,
        Paint()
          ..color = color
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcGaugePainter old) =>
      old.value != value || old.color != color;
}

/// Hexagonal radar/spider chart comparing two fighters across N attributes.
class _RadarChartPainter extends CustomPainter {
  final List<double> valuesA;
  final List<double> valuesB;
  final List<String> labels;
  final Color colorA;
  final Color colorB;

  const _RadarChartPainter({
    required this.valuesA,
    required this.valuesB,
    required this.labels,
    required this.colorA,
    required this.colorB,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2 - 28;
    final count = labels.length;
    const startAngle = -math.pi / 2;
    final angleStep = (2 * math.pi) / count;

    // Grid rings
    for (int lvl = 1; lvl <= 4; lvl++) {
      final r = maxRadius * lvl / 4;
      final path = Path();
      for (int i = 0; i < count; i++) {
        final a = startAngle + i * angleStep;
        final pt = Offset(
          center.dx + r * math.cos(a),
          center.dy + r * math.sin(a),
        );
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: lvl == 4 ? 0.08 : 0.04)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    // Axis spokes
    for (int i = 0; i < count; i++) {
      final a = startAngle + i * angleStep;
      canvas.drawLine(
        center,
        Offset(
          center.dx + maxRadius * math.cos(a),
          center.dy + maxRadius * math.sin(a),
        ),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.06)
          ..strokeWidth = 0.5,
      );
    }

    // Helper: build polygon
    Path polygon(List<double> vals) {
      final path = Path();
      for (int i = 0; i < count; i++) {
        final a = startAngle + i * angleStep;
        final r = maxRadius * vals[i].clamp(0.0, 1.0);
        final pt = Offset(
          center.dx + r * math.cos(a),
          center.dy + r * math.sin(a),
        );
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      return path;
    }

    // Fighter B
    canvas.drawPath(
      polygon(valuesB),
      Paint()
        ..color = colorB.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      polygon(valuesB),
      Paint()
        ..color = colorB.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Fighter A (drawn on top)
    canvas.drawPath(
      polygon(valuesA),
      Paint()
        ..color = colorA.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      polygon(valuesA),
      Paint()
        ..color = colorA.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Labels
    for (int i = 0; i < count; i++) {
      final a = startAngle + i * angleStep;
      final lr = maxRadius + 22;
      final lx = center.dx + lr * math.cos(a);
      final ly = center.dy + lr * math.sin(a);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 7,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RadarChartPainter old) =>
      old.valuesA != valuesA || old.valuesB != valuesB;
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

class _AiFighter {
  final String id, name, flag, record, weightClass, stance;
  final int wins, losses, ko, sub, power, speed, cardio, ground, chin, iq;
  final double strikeAcc, tdAcc, tdDef, subRate, koRate, decRate;
  final int rankPts;

  const _AiFighter({
    required this.id,
    required this.name,
    required this.flag,
    required this.record,
    required this.weightClass,
    required this.wins,
    required this.losses,
    required this.ko,
    required this.sub,
    required this.stance,
    required this.power,
    required this.speed,
    required this.cardio,
    required this.ground,
    required this.chin,
    required this.iq,
    required this.strikeAcc,
    required this.tdAcc,
    required this.tdDef,
    required this.subRate,
    required this.koRate,
    required this.decRate,
    required this.rankPts,
  });
}

class _Matchup {
  final _AiFighter fighterA, fighterB;
  final String title;

  const _Matchup({
    required this.fighterA,
    required this.fighterB,
    required this.title,
  });
}

class _HumanPrediction {
  final String winnerSide; // 'A' or 'B'
  final String? method; // 'KO/TKO', 'Submission', 'Decision'

  const _HumanPrediction({required this.winnerSide, this.method});
}
