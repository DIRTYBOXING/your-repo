import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'dfc_glass_panel.dart';

class FighterBrief {
  final String name;
  final String record;
  final double heightCm;
  final double reachCm;
  final double avgStrikesLanded;
  final List<String> keyStrengths;
  final List<String> keyWeaknesses;

  const FighterBrief({
    required this.name,
    required this.record,
    required this.heightCm,
    required this.reachCm,
    required this.avgStrikesLanded,
    required this.keyStrengths,
    required this.keyWeaknesses,
  });
}

class OnlyFitPredictionCard extends StatelessWidget {
  final FighterBrief fighterA;
  final FighterBrief fighterB;
  final double winProbA; // e.g. 0.62 for 62%
  final String explanation;

  const OnlyFitPredictionCard({
    super.key,
    required this.fighterA,
    required this.fighterB,
    required this.winProbA,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    final double winProbB = 1.0 - winProbA;
    final primaryAccent = AppColors.neonCyan;

    return DfcGlassPanel(
      glowColor: primaryAccent,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Corporate-Grade Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DFC SECURE PREDICT',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'DATA-DRIVEN ML CALIBRATION',
                      style: TextStyle(
                        color: primaryAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.analytics_outlined,
                  color: Colors.white70,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // MATCHUP VS CARD
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFighterHeader(
                  fighterA,
                  (winProbA * 100).toStringAsFixed(0) + '%',
                ),
                const Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildFighterHeader(
                  fighterB,
                  (winProbB * 100).toStringAsFixed(0) + '%',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // PROBABILITY COMPARISON BAR
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    Expanded(
                      flex: (winProbA * 100).round(),
                      child: Container(color: AppColors.neonCyan),
                    ),
                    Expanded(
                      flex: (winProbB * 100).round(),
                      child: Container(color: AppColors.neonMagenta),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // STRENGTHS & WEAKNESSES DEEP DIVE
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildDetailsBlock(fighterA, AppColors.neonCyan),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailsBlock(fighterB, AppColors.neonMagenta),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ML EXPLANATION (SHAP VECTORS HELPER)
            DfcGlassPanel(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOP SHAP PREDICTOR FEATURE INFLUENCE',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      explanation,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
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

  Widget _buildFighterHeader(FighterBrief fighter, String pct) {
    return Column(
      children: [
        Text(
          fighter.name.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          pct,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          fighter.record,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildDetailsBlock(FighterBrief fighter, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STRENGTHS',
          style: TextStyle(
            color: accent,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        ...fighter.keyStrengths.map(
          (s) => Text(
            '• $s',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'WEAKNESSES',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        ...fighter.keyWeaknesses.map(
          (w) => Text(
            '• $w',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
