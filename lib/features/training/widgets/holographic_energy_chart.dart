/// ═══════════════════════════════════════════════════════════════════════════
/// FUTURE SESSION DATA MODEL — Energy System, AI, Subjective, Physiology
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Designed for 2037-level sports science, holographic UI, and AI integration.
///
library;

import 'package:flutter/material.dart';

/// Energy system breakdown per session
class EnergySystemUsage {
  final double atpPcPercent; // ATP-PC (explosive)
  final double anaerobicPercent; // Glycolytic (high intensity)
  final double aerobicPercent; // Oxidative (endurance)

  const EnergySystemUsage({
    required this.atpPcPercent,
    required this.anaerobicPercent,
    required this.aerobicPercent,
  });
}

/// Subjective ratings
class SessionSubjective {
  final double rpe; // Rate of Perceived Exertion (1-10)
  final double mood; // Mood score (1-10)
  final double soreness; // Soreness (1-10)
  final String notes; // Qualitative feedback

  const SessionSubjective({
    required this.rpe,
    required this.mood,
    required this.soreness,
    this.notes = '',
  });
}

/// Physiological signals
class SessionPhysiology {
  final double avgHeartRate;
  final double hrv;
  final double sleepHours;
  final double recoveryScore;

  const SessionPhysiology({
    required this.avgHeartRate,
    required this.hrv,
    required this.sleepHours,
    required this.recoveryScore,
  });
}

/// AI feedback and composite scores
class SessionAIInsights {
  final String aiSummary;
  final double performanceScore;
  final double recoveryAdviceScore;
  final List<String> correlations; // e.g. "High RPE correlates with low HRV"

  const SessionAIInsights({
    required this.aiSummary,
    required this.performanceScore,
    required this.recoveryAdviceScore,
    this.correlations = const [],
  });
}

/// Complete session record
class FutureSessionRecord {
  final DateTime timestamp;
  final String sessionType;
  final int durationMinutes;
  final EnergySystemUsage energySystems;
  final SessionSubjective subjective;
  final SessionPhysiology physiology;
  final SessionAIInsights aiInsights;

  const FutureSessionRecord({
    required this.timestamp,
    required this.sessionType,
    required this.durationMinutes,
    required this.energySystems,
    required this.subjective,
    required this.physiology,
    required this.aiInsights,
  });
}

/// Example: UI widget for holographic energy system chart
class HolographicEnergyChart extends StatelessWidget {
  final EnergySystemUsage usage;

  const HolographicEnergyChart({required this.usage, super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder: Replace with animated, glassmorphic, neon chart
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blueAccent, Colors.purpleAccent, Colors.orangeAccent],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Energy System Breakdown',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _energyBar('ATP-PC', usage.atpPcPercent, Colors.orangeAccent),
              _energyBar(
                'Anaerobic',
                usage.anaerobicPercent,
                Colors.purpleAccent,
              ),
              _energyBar('Aerobic', usage.aerobicPercent, Colors.blueAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _energyBar(String label, double percent, Color color) {
    return Column(
      children: [
        Container(
          width: 32,
          height: percent * 2,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        Text(
          '${percent.toStringAsFixed(0)}%',
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}

/// Extend this with animated, interactive, and AI-powered chart widgets for full dashboard.
