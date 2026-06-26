/// ═══════════════════════════════════════════════════════════════════════════
/// APEX+++ OPERATING MODEL — The 10-Layer DFC Architecture
/// ═══════════════════════════════════════════════════════════════════════════
///
/// DFC is a Combat Sports Operating System built on 10 unified layers:
///
///   1. Core Loop        — Discover → Engage → Monetize → Retain → Amplify
///   2. Intelligence      — AI brain: predictions, coaching, moderation, storytelling
///   3. Infrastructure    — Self-healing, multi-region, CDN, zero-loss
///   4. Athlete Ecosystem — Fighter DNA, career engine, health passport, talent scouting
///   5. Promotion Factory — Event automation, sponsorships, AI event director
///   6. Global Network    — Regional federations, multi-language, localized pricing
///   7. Growth Flywheel   — Self-sustaining: more fighters → more content → more fans → more revenue
///   8. Governance        — Safety, moderation, audit, compliance, medical oversight
///   9. Future            — Wearables, metaverse, AR overlays, smart gloves, virtual gyms
///  10. Unified Blueprint — The master orchestrator that binds all layers into one OS
///
/// ═══════════════════════════════════════════════════════════════════════════
library;

/// The 10 layers of the DFC Apex+++ architecture.
enum ApexLayer {
  coreLoop,
  intelligence,
  infrastructure,
  athleteEcosystem,
  promotionFactory,
  globalNetwork,
  growthFlywheel,
  governance,
  future,
  unifiedBlueprint,
}

/// Health status for any layer or subsystem.
enum LayerHealth { optimal, degraded, critical, offline, booting }

/// The 5 phases of the Core Loop engine.
enum CoreLoopPhase { discover, engage, monetize, retain, amplify }

/// Snapshot of a single layer's runtime state.
class ApexLayerStatus {
  final ApexLayer layer;
  final LayerHealth health;
  final double score; // 0.0 – 1.0 performance score
  final int activeSubsystems;
  final int totalSubsystems;
  final DateTime lastHeartbeat;
  final String? statusMessage;

  const ApexLayerStatus({
    required this.layer,
    required this.health,
    required this.score,
    required this.activeSubsystems,
    required this.totalSubsystems,
    required this.lastHeartbeat,
    this.statusMessage,
  });

  double get uptimeRatio =>
      totalSubsystems > 0 ? activeSubsystems / totalSubsystems : 0.0;

  bool get isHealthy => health == LayerHealth.optimal;
}

/// Full platform snapshot across all 10 layers.
class ApexPlatformSnapshot {
  final DateTime generatedAt;
  final Map<ApexLayer, ApexLayerStatus> layerStatuses;
  final double overallScore;
  final LayerHealth overallHealth;
  final int totalActiveSubsystems;
  final int totalSubsystems;

  const ApexPlatformSnapshot({
    required this.generatedAt,
    required this.layerStatuses,
    required this.overallScore,
    required this.overallHealth,
    required this.totalActiveSubsystems,
    required this.totalSubsystems,
  });

  ApexLayerStatus? statusFor(ApexLayer layer) => layerStatuses[layer];

  bool get allLayersHealthy => layerStatuses.values.every((s) => s.isHealthy);

  List<ApexLayer> get degradedLayers => layerStatuses.entries
      .where((e) => !e.value.isHealthy)
      .map((e) => e.key)
      .toList();
}

/// Growth Flywheel metric: tracks the self-reinforcing cycle.
class FlywheelMetric {
  final String stage; // fighters, content, fans, revenue, promoters, events
  final double value;
  final double growthRate; // % change period over period
  final DateTime measuredAt;

  const FlywheelMetric({
    required this.stage,
    required this.value,
    required this.growthRate,
    required this.measuredAt,
  });

  bool get isGrowing => growthRate > 0;
}

/// Core Loop cycle result — one full pass through the 5 phases.
class CoreLoopCycleResult {
  final DateTime cycledAt;
  final Map<CoreLoopPhase, double> phaseScores;
  final int itemsDiscovered;
  final int engagementActions;
  final double revenueGenerated;
  final int usersRetained;
  final int amplificationReach;

  const CoreLoopCycleResult({
    required this.cycledAt,
    required this.phaseScores,
    required this.itemsDiscovered,
    required this.engagementActions,
    required this.revenueGenerated,
    required this.usersRetained,
    required this.amplificationReach,
  });

  double get overallScore {
    if (phaseScores.isEmpty) return 0.0;
    return phaseScores.values.reduce((a, b) => a + b) / phaseScores.length;
  }
}
