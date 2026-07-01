import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC AI CONTRACT NEGOTIATION — #114
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Helps fighters and promoters negotiate fair fight contracts.
///
/// Inputs:
///   • Fighter market value (record, following, drawing power)
///   • Historical purse data for similar fighters
///   • Event revenue projections
///   • Opponent market value
///   • Sponsorship value
///
/// Outputs:
///   • Recommended purse range
///   • Win bonus recommendation
///   • PPV points recommendation
///   • Contract term recommendation
///   • Fairness score (0–100)
///
/// ═══════════════════════════════════════════════════════════════════════════

class FighterMarketValue {
  final String fighterId;
  final String name;
  final int wins;
  final int losses;
  final int draws;
  final int socialFollowers;
  final double ppvDrawingPower; // 0.0 – 1.0
  final double brandValue; // estimated $ value
  final int titleFights;
  final bool isChampion;
  final String division;

  const FighterMarketValue({
    required this.fighterId,
    required this.name,
    required this.wins,
    required this.losses,
    this.draws = 0,
    this.socialFollowers = 0,
    this.ppvDrawingPower = 0,
    this.brandValue = 0,
    this.titleFights = 0,
    this.isChampion = false,
    required this.division,
  });

  double get winRate => (wins + losses) > 0 ? wins / (wins + losses) : 0;
}

class ContractRecommendation {
  final String fighterId;
  final double recommendedBasePurse;
  final double recommendedWinBonus;
  final double ppvPointsPercent;
  final int contractTermFights;
  final double fairnessScore; // 0 – 100
  final Map<String, String> justifications;
  final DateTime assessedAt;

  const ContractRecommendation({
    required this.fighterId,
    required this.recommendedBasePurse,
    required this.recommendedWinBonus,
    required this.ppvPointsPercent,
    required this.contractTermFights,
    required this.fairnessScore,
    required this.justifications,
    required this.assessedAt,
  });
}

class AiContractNegotiationService extends ChangeNotifier {
  static final AiContractNegotiationService _instance =
      AiContractNegotiationService._internal();
  factory AiContractNegotiationService() => _instance;
  AiContractNegotiationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _initialized = false;
  int _totalAssessments = 0;

  // ── Getters ──
  bool get initialized => _initialized;
  int get totalAssessments => _totalAssessments;

  // ── Lifecycle ──

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    debugPrint('[AIContract] Online — negotiation engine active');
    notifyListeners();
  }

  // ── Core Assessment ──

  /// Generate a contract recommendation based on fighter market value,
  /// event revenue projections, and historical data.
  ContractRecommendation assessContract(
    FighterMarketValue fighter, {
    double eventRevenueProjection = 500000,
    double? opponentValue,
  }) {
    _totalAssessments++;

    final justifications = <String, String>{};

    // Base purse calculation.
    final double basePurse = _calculateBasePurse(fighter, eventRevenueProjection);
    justifications['basePurse'] =
        'Based on ${fighter.wins}-${fighter.losses} record, '
        '${fighter.socialFollowers} followers, and projected event revenue';

    // Win bonus: typically 50–100% of base.
    final double winBonus = basePurse * (fighter.winRate > 0.7 ? 1.0 : 0.5);
    justifications['winBonus'] =
        '${fighter.winRate > 0.7 ? "100" : "50"}% of base — '
        'win rate: ${(fighter.winRate * 100).toStringAsFixed(0)}%';

    // PPV points: only for top draws.
    double ppvPoints = 0;
    if (fighter.ppvDrawingPower > 0.5 || fighter.isChampion) {
      ppvPoints = fighter.ppvDrawingPower * 5; // 0–5%
      justifications['ppvPoints'] =
          'Drawing power: ${(fighter.ppvDrawingPower * 100).toStringAsFixed(0)}%';
    } else {
      justifications['ppvPoints'] =
          'Not eligible — drawing power below threshold';
    }

    // Contract term.
    int termFights;
    if (fighter.isChampion || fighter.wins >= 15) {
      termFights = 3;
      justifications['term'] = 'Short term — established fighter has leverage';
    } else if (fighter.wins >= 8) {
      termFights = 5;
      justifications['term'] = 'Medium term — proven fighter, building brand';
    } else {
      termFights = 8;
      justifications['term'] =
          'Longer term — developing fighter, promotional investment';
    }

    // Fairness score.
    final double fairness = _calculateFairness(
      basePurse,
      eventRevenueProjection,
      fighter,
    );

    final recommendation = ContractRecommendation(
      fighterId: fighter.fighterId,
      recommendedBasePurse: basePurse,
      recommendedWinBonus: winBonus,
      ppvPointsPercent: ppvPoints,
      contractTermFights: termFights,
      fairnessScore: fairness,
      justifications: justifications,
      assessedAt: DateTime.now(),
    );

    _persistRecommendation(recommendation);

    debugPrint(
      '[AIContract] Contract assessment for ${fighter.name}: '
      '\$${basePurse.toStringAsFixed(0)} base, '
      'fairness ${fairness.toStringAsFixed(0)}/100',
    );
    notifyListeners();
    return recommendation;
  }

  /// Evaluate an existing contract offer for fairness.
  Map<String, dynamic> evaluateOffer(
    FighterMarketValue fighter,
    double offeredPurse,
    double offeredWinBonus,
    double offeredPpv,
    int offeredTermFights,
  ) {
    final recommended = assessContract(fighter);
    final purseGap = offeredPurse - recommended.recommendedBasePurse;
    final bonusGap = offeredWinBonus - recommended.recommendedWinBonus;
    final ppvGap = offeredPpv - recommended.ppvPointsPercent;

    return {
      'recommended': recommended,
      'purseGap': purseGap,
      'bonusGap': bonusGap,
      'ppvGap': ppvGap,
      'verdict': purseGap >= 0 && ppvGap >= -0.5
          ? 'FAIR'
          : purseGap > -recommended.recommendedBasePurse * 0.2
          ? 'NEGOTIATE'
          : 'BELOW MARKET',
      'tips': _negotiationTips(fighter, purseGap, ppvGap),
    };
  }

  // ── Internal ──

  double _calculateBasePurse(FighterMarketValue fighter, double eventRevenue) {
    // Fighters typically earn 15–25% of event revenue depending on star power.
    final revenueShare = eventRevenue * 0.20;

    // Record bonus.
    final recordMultiplier = fighter.winRate * 0.5 + 0.5;

    // Brand value component.
    final brandComponent = fighter.brandValue * 0.01; // 1% of brand value

    // Champion premium.
    final championBonus = fighter.isChampion ? revenueShare * 0.3 : 0;

    // Social drawing premium.
    final socialPremium = fighter.socialFollowers > 100000
        ? eventRevenue * 0.05
        : 0;

    return (revenueShare * recordMultiplier +
            brandComponent +
            championBonus +
            socialPremium)
        .clamp(5000, eventRevenue * 0.35);
  }

  double _calculateFairness(
    double purse,
    double eventRevenue,
    FighterMarketValue fighter,
  ) {
    // Fairness = how close the purse is to industry-standard percentages.
    final sharePercent = eventRevenue > 0 ? purse / eventRevenue : 0;

    // Target: 15–25% for main card, 5–10% for undercard.
    double score = 50.0;
    if (sharePercent >= 0.15 && sharePercent <= 0.30) {
      score += 30;
    } else if (sharePercent >= 0.10) {
      score += 15;
    }

    // Win rate fairness.
    if (fighter.winRate > 0.6) score += 10;

    // Champion treatment.
    if (fighter.isChampion && sharePercent >= 0.20) score += 10;

    return score.clamp(0, 100);
  }

  List<String> _negotiationTips(
    FighterMarketValue fighter,
    double purseGap,
    double ppvGap,
  ) {
    final tips = <String>[];
    if (purseGap < 0) {
      tips.add('Counter-offer with evidence of drawing power');
    }
    if (ppvGap < 0 && fighter.ppvDrawingPower > 0.3) {
      tips.add('Request PPV points — your drawing power supports it');
    }
    if (fighter.isChampion) {
      tips.add('Leverage champion status for shorter contract terms');
    }
    if (fighter.socialFollowers > 500000) {
      tips.add('Highlight social media reach as negotiation leverage');
    }
    return tips;
  }

  Future<void> _persistRecommendation(ContractRecommendation rec) async {
    try {
      await _firestore
          .collection('contract_negotiations')
          .doc('${rec.fighterId}_${rec.assessedAt.millisecondsSinceEpoch}')
          .set({
            'fighterId': rec.fighterId,
            'basePurse': rec.recommendedBasePurse,
            'winBonus': rec.recommendedWinBonus,
            'ppvPoints': rec.ppvPointsPercent,
            'termFights': rec.contractTermFights,
            'fairnessScore': rec.fairnessScore,
            'assessedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('[AIContract] Persist error: $e');
    }
  }
}
