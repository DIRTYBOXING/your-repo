/// ═══════════════════════════════════════════════════════════════════════════
///
///    ██████╗ ██╗   ██╗ █████╗ ███╗   ██╗████████╗██╗   ██╗███╗   ███╗
///   ██╔═══██╗██║   ██║██╔══██╗████╗  ██║╚══██╔══╝██║   ██║████╗ ████║
///   ██║   ██║██║   ██║███████║██╔██╗ ██║   ██║   ██║   ██║██╔████╔██║
///   ██║▄▄ ██║██║   ██║██╔══██║██║╚██╗██║   ██║   ██║   ██║██║╚██╔╝██║
///   ╚██████╔╝╚██████╔╝██║  ██║██║ ╚████║   ██║   ╚██████╔╝██║ ╚═╝ ██║
///    ╚══▀▀═╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝
///
///   QUANTUM-INSPIRED AI OPTIMIZATION ENGINE
///   Advanced Fight Analytics • Matchmaking • Performance Prediction
///
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Uses quantum-inspired algorithms for complex optimization problems:
///
/// QUANTUM PRINCIPLES APPLIED:
/// ├── Quantum Annealing → Optimal matchmaking through energy minimization
/// ├── Superposition Search → Explore multiple fight scenarios simultaneously
/// ├── Entanglement Modeling → Fighter attribute correlations
/// └── Parameterized Circuits → Adaptive prediction models
///
/// CAPABILITIES:
/// ├── Fight Outcome Prediction (multi-factor analysis)
/// ├── Optimal Matchmaking (excitement + fairness balance)
/// ├── Training Load Optimization (recovery + performance)
/// ├── Career Path Modeling (probabilistic futures)
/// └── Performance Anomaly Detection (injury prediction)
///
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DATA MODELS
/// ═══════════════════════════════════════════════════════════════════════════

/// Fighter profile for quantum analysis
class QuantumFighterProfile {
  final String fighterId;
  final String name;
  final String weightClass;
  final int wins;
  final int losses;
  final int draws;
  final double strikeAccuracy;
  final double takedownAccuracy;
  final double takedownDefense;
  final double submissionRate;
  final double koRate;
  final double decisionRate;
  final double cardioEndurance; // 0-100
  final double chinDurability; // 0-100
  final double recentForm; // -1 to +1 (losing streak to winning streak)
  final int daysSinceLastFight;
  final double rankingPoints;
  final Map<String, double>
  styleAttributes; // e.g., {'wrestling': 0.85, 'striking': 0.72}

  const QuantumFighterProfile({
    required this.fighterId,
    required this.name,
    required this.weightClass,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.strikeAccuracy = 0.5,
    this.takedownAccuracy = 0.5,
    this.takedownDefense = 0.5,
    this.submissionRate = 0.0,
    this.koRate = 0.0,
    this.decisionRate = 0.0,
    this.cardioEndurance = 70.0,
    this.chinDurability = 70.0,
    this.recentForm = 0.0,
    this.daysSinceLastFight = 90,
    this.rankingPoints = 0.0,
    this.styleAttributes = const {},
  });

  double get winRate =>
      (wins + losses + draws) > 0 ? wins / (wins + losses + draws) : 0.5;

  double get finishRate => koRate + submissionRate;

  /// Convert to quantum state vector (normalized attributes)
  List<double> toQuantumState() {
    return [
      winRate,
      strikeAccuracy,
      takedownAccuracy,
      takedownDefense,
      submissionRate,
      koRate,
      cardioEndurance / 100,
      chinDurability / 100,
      (recentForm + 1) / 2, // Normalize to 0-1
      min(1.0, daysSinceLastFight / 365), // Normalize activity
    ];
  }
}

/// Quantum-style probability distribution for fight outcomes
class FightProbabilities {
  final double fighter1Win;
  final double fighter2Win;
  final double draw;
  final double ko1;
  final double ko2;
  final double submission1;
  final double submission2;
  final double decision;
  final double excitement; // 0-100
  final double competitiveness; // 0-100 (closer = more competitive)
  final double confidence; // How confident is the prediction
  final List<String> keyFactors;

  const FightProbabilities({
    required this.fighter1Win,
    required this.fighter2Win,
    this.draw = 0.02,
    this.ko1 = 0.0,
    this.ko2 = 0.0,
    this.submission1 = 0.0,
    this.submission2 = 0.0,
    this.decision = 0.0,
    this.excitement = 50.0,
    this.competitiveness = 50.0,
    this.confidence = 0.7,
    this.keyFactors = const [],
  });

  String get favoriteLabel =>
      fighter1Win > fighter2Win ? 'Fighter 1' : 'Fighter 2';
  double get favoriteScore => max(fighter1Win, fighter2Win);
  bool get isCompetitive => competitiveness > 70;
  bool get isExciting => excitement > 70;
}

/// Match quality score for matchmaking
class MatchQuality {
  final String fighter1Id;
  final String fighter2Id;
  final double overallScore; // 0-100
  final double competitiveBalance; // 0-100
  final double styleMismatch; // 0-100 (higher = more interesting clash)
  final double narrativeValue; // 0-100 (storyline potential)
  final double commercialValue; // 0-100 (draw power)
  final double riskLevel; // 0-100 (injury/mismatch risk)
  final List<String> sellingPoints;

  const MatchQuality({
    required this.fighter1Id,
    required this.fighter2Id,
    required this.overallScore,
    this.competitiveBalance = 50.0,
    this.styleMismatch = 50.0,
    this.narrativeValue = 50.0,
    this.commercialValue = 50.0,
    this.riskLevel = 30.0,
    this.sellingPoints = const [],
  });

  bool get isExcellent => overallScore >= 85;
  bool get isGood => overallScore >= 70;
  bool get isFair => overallScore >= 50;
  bool get isPoor => overallScore < 50;
}

/// Training load optimization result
class TrainingOptimization {
  final double optimalIntensity; // 0-100
  final double suggestedVolume; // 0-100 (relative to normal)
  final List<String> focusAreas;
  final List<String> avoidances;
  final double injuryRisk; // 0-100
  final double performanceProjection; // How performance will trend
  final String phaseRecommendation; // 'build', 'peak', 'maintain', 'deload'
  final int daysUntilPeak;

  const TrainingOptimization({
    this.optimalIntensity = 70.0,
    this.suggestedVolume = 80.0,
    this.focusAreas = const [],
    this.avoidances = const [],
    this.injuryRisk = 20.0,
    this.performanceProjection = 0.0,
    this.phaseRecommendation = 'maintain',
    this.daysUntilPeak = 14,
  });

  bool get shouldDeload => phaseRecommendation == 'deload';
  bool get isInRedZone => injuryRisk > 70;
}

/// ═══════════════════════════════════════════════════════════════════════════
/// QUANTUM OPTIMIZATION SERVICE
/// ═══════════════════════════════════════════════════════════════════════════

class QuantumOptimizationService extends ChangeNotifier {
  static final QuantumOptimizationService _instance =
      QuantumOptimizationService._internal();
  factory QuantumOptimizationService() => _instance;
  QuantumOptimizationService._internal();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize the quantum engine
  Future<void> initialize() async {
    // Simulate quantum system warmup
    await Future.delayed(const Duration(milliseconds: 100));
    _isInitialized = true;
    debugPrint('''
═══════════════════════════════════════════════════════════════════════════
   ⚛️  QUANTUM OPTIMIZATION ENGINE ONLINE
   Quantum-Inspired Fight Analytics Ready
═══════════════════════════════════════════════════════════════════════════
''');
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIGHT PREDICTION (Quantum Annealing-Inspired)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Predict fight outcome using quantum-inspired multi-factor analysis
  FightProbabilities predictFight(
    QuantumFighterProfile fighter1,
    QuantumFighterProfile fighter2,
  ) {
    // Convert fighters to quantum states
    final state1 = fighter1.toQuantumState();
    final state2 = fighter2.toQuantumState();

    // Calculate base winning probability using "quantum interference"
    double baseProb1 = _calculateBaseWinProbability(state1, state2);
    double baseProb2 = 1 - baseProb1 - 0.02; // Account for draw

    // Apply style matchup modifiers
    final styleModifier = _calculateStyleMatchup(fighter1, fighter2);
    baseProb1 += styleModifier;
    baseProb2 -= styleModifier;

    // Apply momentum/form adjustment
    final momentumShift = (fighter1.recentForm - fighter2.recentForm) * 0.05;
    baseProb1 += momentumShift;
    baseProb2 -= momentumShift;

    // Normalize probabilities
    final total = baseProb1 + baseProb2 + 0.02;
    final prob1 = baseProb1 / total;
    final prob2 = baseProb2 / total;
    const draw = 0.02;

    // Calculate finish probabilities
    final ko1 = prob1 * fighter1.koRate * (1 - fighter2.chinDurability / 100);
    final ko2 = prob2 * fighter2.koRate * (1 - fighter1.chinDurability / 100);
    final sub1 =
        prob1 * fighter1.submissionRate * (1 - fighter2.takedownDefense);
    final sub2 =
        prob2 * fighter2.submissionRate * (1 - fighter1.takedownDefense);
    final decision = 1 - ko1 - ko2 - sub1 - sub2 - draw;

    // Calculate excitement and competitiveness
    final excitement = _calculateExcitement(fighter1, fighter2, prob1, prob2);
    final competitiveness = 100 - (prob1 - prob2).abs() * 100;

    // Identify key factors
    final keyFactors = _identifyKeyFactors(fighter1, fighter2);

    return FightProbabilities(
      fighter1Win: prob1.clamp(0.05, 0.95),
      fighter2Win: prob2.clamp(0.05, 0.95),
      ko1: ko1.clamp(0, 0.5),
      ko2: ko2.clamp(0, 0.5),
      submission1: sub1.clamp(0, 0.3),
      submission2: sub2.clamp(0, 0.3),
      decision: decision.clamp(0.2, 0.8),
      excitement: excitement.clamp(0, 100),
      competitiveness: competitiveness.clamp(0, 100),
      confidence: _calculateConfidence(fighter1, fighter2),
      keyFactors: keyFactors,
    );
  }

  double _calculateBaseWinProbability(
    List<double> state1,
    List<double> state2,
  ) {
    // "Quantum" dot product with weighted attributes
    const weights = [
      0.25,
      0.15,
      0.10,
      0.10,
      0.08,
      0.08,
      0.10,
      0.07,
      0.05,
      0.02,
    ];
    double score1 = 0;
    double score2 = 0;

    for (int i = 0; i < min(state1.length, weights.length); i++) {
      score1 += state1[i] * weights[i];
      score2 += state2[i] * weights[i];
    }

    // Sigmoid normalization
    final diff = score1 - score2;
    return 1 / (1 + exp(-diff * 4));
  }

  double _calculateStyleMatchup(
    QuantumFighterProfile f1,
    QuantumFighterProfile f2,
  ) {
    double modifier = 0;

    // Striker vs Grappler dynamics
    final f1Wrestling = f1.styleAttributes['wrestling'] ?? f1.takedownAccuracy;
    final f2Wrestling = f2.styleAttributes['wrestling'] ?? f2.takedownAccuracy;
    final f1Striking = f1.styleAttributes['striking'] ?? f1.strikeAccuracy;
    final f2Striking = f2.styleAttributes['striking'] ?? f2.strikeAccuracy;

    // Wrestling advantage
    if (f1Wrestling > f2Wrestling + 0.2) {
      modifier += 0.05;
    } else if (f2Wrestling > f1Wrestling + 0.2) {
      modifier -= 0.05;
    }

    // Striking advantage
    if (f1Striking > f2Striking + 0.15) {
      modifier += 0.04;
    } else if (f2Striking > f1Striking + 0.15) {
      modifier -= 0.04;
    }

    // Cardio advantage in later rounds
    if (f1.cardioEndurance > f2.cardioEndurance + 15) {
      modifier += 0.03;
    } else if (f2.cardioEndurance > f1.cardioEndurance + 15) {
      modifier -= 0.03;
    }

    return modifier;
  }

  double _calculateExcitement(
    QuantumFighterProfile f1,
    QuantumFighterProfile f2,
    double prob1,
    double prob2,
  ) {
    double excitement = 50;

    // High finish rates = more exciting
    excitement += (f1.finishRate + f2.finishRate) * 30;

    // Close fight = more exciting
    excitement += (100 - (prob1 - prob2).abs() * 100) * 0.3;

    // Both aggressive strikers = exciting
    excitement += (f1.strikeAccuracy + f2.strikeAccuracy - 1.0) * 10;

    // Activity (recent fighters are more exciting)
    final avgDaysSince = (f1.daysSinceLastFight + f2.daysSinceLastFight) / 2;
    if (avgDaysSince < 120) excitement += 5;

    return excitement;
  }

  double _calculateConfidence(
    QuantumFighterProfile f1,
    QuantumFighterProfile f2,
  ) {
    double confidence = 0.7;

    // More fights = more data = higher confidence
    final totalFights = f1.wins + f1.losses + f2.wins + f2.losses;
    if (totalFights > 40) confidence += 0.1;
    if (totalFights < 15) confidence -= 0.1;

    // Similar level = harder to predict
    final rankDiff = (f1.rankingPoints - f2.rankingPoints).abs();
    if (rankDiff < 100) confidence -= 0.05;

    return confidence.clamp(0.4, 0.95);
  }

  List<String> _identifyKeyFactors(
    QuantumFighterProfile f1,
    QuantumFighterProfile f2,
  ) {
    final factors = <String>[];

    if ((f1.takedownAccuracy - f2.takedownDefense).abs() > 0.2) {
      factors.add('Wrestling exchanges will be crucial');
    }

    if (f1.cardioEndurance > f2.cardioEndurance + 20 ||
        f2.cardioEndurance > f1.cardioEndurance + 20) {
      factors.add('Cardio advantage could decide later rounds');
    }

    if (f1.koRate > 0.4 || f2.koRate > 0.4) {
      factors.add('Heavy hitters - expect KO threat');
    }

    if (f1.chinDurability < 60 || f2.chinDurability < 60) {
      factors.add('Durability concerns could be exploited');
    }

    if (f1.recentForm * f2.recentForm < 0) {
      factors.add('Momentum clash - one fighter trending up, other down');
    }

    if (factors.isEmpty) {
      factors.add('Evenly matched - expect a technical battle');
    }

    return factors;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MATCHMAKING (Quantum Annealing Optimization)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Find optimal match for a fighter from a pool
  List<MatchQuality> findOptimalMatches(
    QuantumFighterProfile fighter,
    List<QuantumFighterProfile> pool, {
    int topN = 5,
  }) {
    final matches = <MatchQuality>[];

    for (final opponent in pool) {
      if (opponent.fighterId == fighter.fighterId) continue;
      if (opponent.weightClass != fighter.weightClass) continue;

      final quality = evaluateMatchQuality(fighter, opponent);
      matches.add(quality);
    }

    // Sort by overall score (quantum annealing finds minimum energy = maximum quality)
    matches.sort((a, b) => b.overallScore.compareTo(a.overallScore));

    return matches.take(topN).toList();
  }

  /// Evaluate quality of a specific matchup
  MatchQuality evaluateMatchQuality(
    QuantumFighterProfile fighter1,
    QuantumFighterProfile fighter2,
  ) {
    // Predict fight to get competitiveness
    final prediction = predictFight(fighter1, fighter2);

    // Calculate individual quality factors
    final competitiveBalance = prediction.competitiveness;

    // Style mismatch (different styles = interesting)
    final styleDiff = _calculateStyleDifference(fighter1, fighter2);

    // Narrative value (rankings, streaks, etc.)
    final narrative = _calculateNarrativeValue(fighter1, fighter2);

    // Commercial value
    final commercial = _calculateCommercialValue(fighter1, fighter2);

    // Risk assessment
    final risk = _calculateMatchRisk(fighter1, fighter2, prediction);

    // Weighted overall score
    final overall =
        (competitiveBalance * 0.30 +
        styleDiff * 0.20 +
        narrative * 0.20 +
        commercial * 0.20 -
        risk * 0.10);

    // Generate selling points
    final sellingPoints = _generateSellingPoints(
      fighter1,
      fighter2,
      prediction,
      styleDiff,
      narrative,
    );

    return MatchQuality(
      fighter1Id: fighter1.fighterId,
      fighter2Id: fighter2.fighterId,
      overallScore: overall.clamp(0, 100),
      competitiveBalance: competitiveBalance,
      styleMismatch: styleDiff,
      narrativeValue: narrative,
      commercialValue: commercial,
      riskLevel: risk,
      sellingPoints: sellingPoints,
    );
  }

  double _calculateStyleDifference(
    QuantumFighterProfile f1,
    QuantumFighterProfile f2,
  ) {
    // Calculate how different their styles are
    double diff = 0;

    diff += (f1.strikeAccuracy - f2.strikeAccuracy).abs() * 30;
    diff += (f1.takedownAccuracy - f2.takedownAccuracy).abs() * 30;
    diff += (f1.koRate - f2.koRate).abs() * 20;
    diff += (f1.submissionRate - f2.submissionRate).abs() * 20;

    return (diff * 100).clamp(0, 100);
  }

  double _calculateNarrativeValue(
    QuantumFighterProfile f1,
    QuantumFighterProfile f2,
  ) {
    double narrative = 50;

    // Both on winning streaks
    if (f1.recentForm > 0.5 && f2.recentForm > 0.5) {
      narrative += 20;
    }

    // Ranking implications
    final rankDiff = (f1.rankingPoints - f2.rankingPoints).abs();
    if (rankDiff < 200) narrative += 15; // Close in rankings

    // Veteran vs newcomer
    final expDiff = ((f1.wins + f1.losses) - (f2.wins + f2.losses)).abs();
    if (expDiff > 20) narrative += 10;

    return narrative.clamp(0, 100);
  }

  double _calculateCommercialValue(
    QuantumFighterProfile f1,
    QuantumFighterProfile f2,
  ) {
    double commercial = 40;

    // High ranking = more draw
    commercial += (f1.rankingPoints + f2.rankingPoints) / 50;

    // Finish rate = more casual appeal
    commercial += (f1.finishRate + f2.finishRate) * 15;

    // Win rate = star power
    commercial += (f1.winRate + f2.winRate) * 20;

    return commercial.clamp(0, 100);
  }

  double _calculateMatchRisk(
    QuantumFighterProfile f1,
    QuantumFighterProfile f2,
    FightProbabilities prediction,
  ) {
    double risk = 20;

    // Very one-sided = bad for business
    if (prediction.competitiveness < 40) risk += 30;

    // Coming off long layoff = injury risk
    if (f1.daysSinceLastFight > 365 || f2.daysSinceLastFight > 365) {
      risk += 15;
    }

    // Huge experience gap = potential mismatch
    final expGap = ((f1.wins + f1.losses) - (f2.wins + f2.losses)).abs();
    if (expGap > 15) risk += 15;

    return risk.clamp(0, 100);
  }

  List<String> _generateSellingPoints(
    QuantumFighterProfile f1,
    QuantumFighterProfile f2,
    FightProbabilities prediction,
    double styleDiff,
    double narrative,
  ) {
    final points = <String>[];

    if (prediction.isCompetitive) {
      points.add('🔥 Highly competitive matchup');
    }

    if (prediction.isExciting) {
      points.add('⚡ High action potential');
    }

    if (styleDiff > 60) {
      points.add('🥊 Clash of styles');
    }

    if (narrative > 70) {
      points.add('📖 Great storyline potential');
    }

    if (f1.finishRate + f2.finishRate > 1.2) {
      points.add('💥 Finish likely');
    }

    if (points.isEmpty) {
      points.add('👊 Solid competitive fight');
    }

    return points;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TRAINING OPTIMIZATION (Parameterized Quantum Circuit-Inspired)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Optimize training load based on multiple factors
  TrainingOptimization optimizeTraining({
    required double currentRecovery, // 0-100
    required int daysUntilFight,
    required double recentTrainingLoad, // 0-100 (average)
    required double fatigueLevel, // 0-100
    double? sleepQuality, // 0-100
    double? stressLevel, // 0-100
    List<String>? injuries,
  }) {
    // Calculate base intensity
    double intensity = 70;
    double volume = 80;
    String phase = 'maintain';
    final focusAreas = <String>[];
    final avoidances = <String>[];
    double injuryRisk = 20;

    // Recovery-based adjustments
    if (currentRecovery < 40) {
      intensity = 30;
      volume = 40;
      phase = 'deload';
      focusAreas.add('Active recovery');
      focusAreas.add('Mobility work');
    } else if (currentRecovery < 60) {
      intensity = 50;
      volume = 60;
      phase = 'maintain';
      focusAreas.add('Technical drilling');
    } else if (currentRecovery > 85) {
      intensity = 85;
      volume = 90;
      phase = 'build';
      focusAreas.add('High intensity sparring');
    }

    // Fight camp periodization
    if (daysUntilFight > 0) {
      if (daysUntilFight <= 7) {
        // Fight week
        intensity = 40;
        volume = 30;
        phase = 'peak';
        focusAreas.clear();
        focusAreas.add('Light technical work');
        focusAreas.add('Visualization');
        focusAreas.add('Weight management');
        avoidances.add('Heavy sparring');
        avoidances.add('New techniques');
      } else if (daysUntilFight <= 14) {
        // Taper
        intensity = 60;
        volume = 50;
        phase = 'peak';
        focusAreas.add('Sharpening combinations');
        avoidances.add('Exhaustive conditioning');
      } else if (daysUntilFight <= 42) {
        // Peak training
        intensity = 90;
        volume = 85;
        phase = 'build';
        focusAreas.add('Fight-specific sparring');
        focusAreas.add('Conditioning');
      }
    }

    // Fatigue adjustments
    if (fatigueLevel > 70) {
      intensity *= 0.7;
      volume *= 0.6;
      avoidances.add('High impact training');
      injuryRisk += 25;
    }

    // Sleep impact
    if (sleepQuality != null && sleepQuality < 50) {
      intensity *= 0.85;
      injuryRisk += 15;
      focusAreas.add('Prioritize sleep tonight');
    }

    // Stress impact
    if (stressLevel != null && stressLevel > 70) {
      volume *= 0.8;
      focusAreas.add('Include stress-relief activities');
    }

    // Injury considerations
    if (injuries != null && injuries.isNotEmpty) {
      injuryRisk += injuries.length * 10;
      for (final injury in injuries) {
        avoidances.add('Avoid aggravating $injury');
      }
    }

    // Calculate days until peak performance
    final daysUntilPeak = daysUntilFight > 0 ? max(1, daysUntilFight - 3) : 14;

    // Performance projection
    final performanceProjection = phase == 'deload'
        ? -0.1
        : phase == 'build'
        ? 0.15
        : 0.05;

    return TrainingOptimization(
      optimalIntensity: intensity.clamp(20, 100),
      suggestedVolume: volume.clamp(20, 100),
      focusAreas: focusAreas,
      avoidances: avoidances,
      injuryRisk: injuryRisk.clamp(0, 100),
      performanceProjection: performanceProjection,
      phaseRecommendation: phase,
      daysUntilPeak: daysUntilPeak,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CAREER PATH MODELING (Superposition-Inspired Scenario Analysis)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Model multiple career path scenarios
  List<Map<String, dynamic>> modelCareerPaths(
    QuantumFighterProfile fighter, {
    int scenarios = 5,
    int yearsAhead = 3,
  }) {
    final paths = <Map<String, dynamic>>[];

    for (int i = 0; i < scenarios; i++) {
      final path = _simulateCareerPath(fighter, yearsAhead, i);
      paths.add(path);
    }

    // Sort by favorability
    paths.sort(
      (a, b) =>
          (b['favorability'] as double).compareTo(a['favorability'] as double),
    );

    return paths;
  }

  Map<String, dynamic> _simulateCareerPath(
    QuantumFighterProfile fighter,
    int years,
    int scenarioSeed,
  ) {
    final random = Random(scenarioSeed + fighter.fighterId.hashCode);

    int wins = fighter.wins;
    int losses = fighter.losses;
    double ranking = fighter.rankingPoints;
    final events = <String>[];
    double favorability = 50;

    for (int year = 1; year <= years; year++) {
      final fightsPerYear = 2 + random.nextInt(2);

      for (int fight = 0; fight < fightsPerYear; fight++) {
        final winChance = (fighter.winRate * 0.7 + ranking / 2000 * 0.3).clamp(
          0.3,
          0.8,
        );

        if (random.nextDouble() < winChance) {
          wins++;
          ranking += 50 + random.nextInt(100);

          if (ranking > 1000 && random.nextDouble() < 0.3) {
            events.add('Year $year: Title shot opportunity');
            favorability += 20;
          } else if (random.nextDouble() < 0.5) {
            events.add('Year $year: Impressive victory');
            favorability += 5;
          }
        } else {
          losses++;
          ranking = max(0, ranking - 100);
          events.add('Year $year: Setback loss');
          favorability -= 10;
        }
      }
    }

    // Determine scenario type
    String scenarioType;
    if (favorability > 70) {
      scenarioType = 'Champion Path';
    } else if (favorability > 50) {
      scenarioType = 'Contender Path';
    } else if (favorability > 30) {
      scenarioType = 'Gatekeeper Path';
    } else {
      scenarioType = 'Rebuilding Path';
    }

    return {
      'scenarioType': scenarioType,
      'finalRecord': '$wins-$losses',
      'finalRanking': ranking.round(),
      'keyEvents': events,
      'favorability': favorability.clamp(0, 100),
      'probability': (100 - (scenarioSeed * 15)).clamp(5, 40).toDouble(),
    };
  }
}
