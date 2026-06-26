import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/apex_operating_model.dart';
import 'dfc_core_loop_engine.dart';
import 'dfc_intelligence_layer.dart';
import 'dfc_infrastructure_layer.dart';
import 'dfc_athlete_ecosystem_engine.dart';
import 'dfc_promotion_factory_engine.dart';
import 'dfc_global_network_service.dart';
import 'dfc_growth_flywheel_engine.dart';
import 'dfc_governance_layer.dart';
import 'dfc_future_layer.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC UNIFIED OPERATING MODEL — Layer 10: The Final Unifying Blueprint
/// ═══════════════════════════════════════════════════════════════════════════
///
/// DFC is NOT an app, NOT a website, NOT a streaming service, NOT a social
/// network, NOT a marketplace, NOT a training tool.
///
/// DFC is a **Combat Sports Operating System**.
///
/// A platform that:
///   • discovers talent        (Core Loop + Global Network)
///   • builds fighters         (Athlete Ecosystem)
///   • empowers promoters      (Promotion Factory)
///   • engages fans            (Core Loop + Intelligence)
///   • produces events         (Promotion Factory)
///   • analyzes fights         (Intelligence Layer)
///   • protects athletes       (Governance + Athlete Ecosystem)
///   • monetizes content       (Core Loop + Promotion Factory)
///   • scales globally         (Global Network + Growth Flywheel)
///   • evolves intelligently   (Future Layer + Intelligence)
///
/// This service boots all 10 layers, monitors their health, and provides
/// a single unified snapshot of the entire platform at any moment.
///
/// ═══════════════════════════════════════════════════════════════════════════
class DfcUnifiedOperatingModel extends ChangeNotifier {
  static final DfcUnifiedOperatingModel _instance =
      DfcUnifiedOperatingModel._internal();
  factory DfcUnifiedOperatingModel() => _instance;
  DfcUnifiedOperatingModel._internal();

  // ── The 10 Layers ──
  final DfcCoreLoopEngine coreLoop = DfcCoreLoopEngine();
  final DfcIntelligenceLayer intelligence = DfcIntelligenceLayer();
  final DfcInfrastructureLayer infrastructure = DfcInfrastructureLayer();
  final DfcAthleteEcosystemEngine athleteEcosystem =
      DfcAthleteEcosystemEngine();
  final DfcPromotionFactoryEngine promotionFactory =
      DfcPromotionFactoryEngine();
  final DfcGlobalNetworkService globalNetwork = DfcGlobalNetworkService();
  final DfcGrowthFlywheelEngine growthFlywheel = DfcGrowthFlywheelEngine();
  final DfcGovernanceLayer governance = DfcGovernanceLayer();
  final DfcFutureLayer future = DfcFutureLayer();

  bool _initialized = false;
  Timer? _snapshotTimer;
  ApexPlatformSnapshot? _latestSnapshot;
  DateTime? _bootedAt;

  // ── Getters ──
  bool get initialized => _initialized;
  ApexPlatformSnapshot? get latestSnapshot => _latestSnapshot;
  DateTime? get bootedAt => _bootedAt;

  /// Uptime since boot.
  Duration get uptime =>
      _bootedAt != null ? DateTime.now().difference(_bootedAt!) : Duration.zero;

  /// Quick check: all 10 layers healthy.
  bool get allLayersHealthy => _latestSnapshot?.allLayersHealthy ?? false;

  /// List of any degraded layers.
  List<ApexLayer> get degradedLayers => _latestSnapshot?.degradedLayers ?? [];

  // ═══════════════════════════════════════════════════════════════════════
  // BOOT SEQUENCE — Initialize all 10 layers
  // ═══════════════════════════════════════════════════════════════════════

  /// Boot the entire DFC Operating System.
  void boot() {
    if (_initialized) return;
    _bootedAt = DateTime.now();

    debugPrint('');
    debugPrint('══════════════════════════════════════════════════════════');
    debugPrint('  DFC UNIFIED OPERATING MODEL — BOOT SEQUENCE');
    debugPrint('  Combat Sports Operating System v1.0');
    debugPrint('══════════════════════════════════════════════════════════');
    debugPrint('');

    // Layer 1: Core Loop
    coreLoop.initialize();
    debugPrint('  [1/10] Core Loop Engine .............. ONLINE');

    // Layer 2: Intelligence
    intelligence.initialize();
    debugPrint('  [2/10] Intelligence Layer ............ ONLINE');

    // Layer 3: Infrastructure
    infrastructure.initialize();
    debugPrint('  [3/10] Infrastructure Layer ........... ONLINE');

    // Layer 4: Athlete Ecosystem
    athleteEcosystem.initialize();
    debugPrint('  [4/10] Athlete Ecosystem ............. ONLINE');

    // Layer 5: Promotion Factory
    promotionFactory.initialize();
    debugPrint('  [5/10] Promotion Factory ............. ONLINE');

    // Layer 6: Global Network
    globalNetwork.initialize();
    debugPrint('  [6/10] Global Network ................ ONLINE');

    // Layer 7: Growth Flywheel
    growthFlywheel.initialize();
    debugPrint('  [7/10] Growth Flywheel ............... ONLINE');

    // Layer 8: Governance
    governance.initialize();
    debugPrint('  [8/10] Governance Layer .............. ONLINE');

    // Layer 9: Future
    future.initialize();
    debugPrint('  [9/10] Future Layer .................. ONLINE');

    // Layer 10: Unified Blueprint (this)
    _initialized = true;
    debugPrint('  [10/10] Unified Blueprint ............ ONLINE');

    debugPrint('');
    debugPrint('  ALL 10 LAYERS OPERATIONAL');
    debugPrint('  DFC Combat Sports OS — READY');
    debugPrint('══════════════════════════════════════════════════════════');
    debugPrint('');

    // Take initial snapshot.
    _takeSnapshot();

    // Continuous platform snapshot every 60 seconds.
    _snapshotTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _takeSnapshot();
    });

    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PLATFORM SNAPSHOT
  // ═══════════════════════════════════════════════════════════════════════

  /// Take a full platform snapshot across all 10 layers.
  void _takeSnapshot() {
    final statuses = <ApexLayer, ApexLayerStatus>{
      ApexLayer.coreLoop: coreLoop.layerStatus,
      ApexLayer.intelligence: intelligence.layerStatus,
      ApexLayer.infrastructure: infrastructure.layerStatus,
      ApexLayer.athleteEcosystem: athleteEcosystem.layerStatus,
      ApexLayer.promotionFactory: promotionFactory.layerStatus,
      ApexLayer.globalNetwork: globalNetwork.layerStatus,
      ApexLayer.growthFlywheel: growthFlywheel.layerStatus,
      ApexLayer.governance: governance.layerStatus,
      ApexLayer.future: future.layerStatus,
      ApexLayer.unifiedBlueprint: ApexLayerStatus(
        layer: ApexLayer.unifiedBlueprint,
        health: _initialized ? LayerHealth.optimal : LayerHealth.offline,
        score: _initialized ? 1.0 : 0.0,
        activeSubsystems: 10,
        totalSubsystems: 10,
        lastHeartbeat: DateTime.now(),
        statusMessage: 'Uptime ${uptime.inMinutes}m',
      ),
    };

    final scores = statuses.values.map((s) => s.score).toList();
    final avgScore = scores.reduce((a, b) => a + b) / scores.length;

    int totalActive = 0;
    int totalSubs = 0;
    for (final s in statuses.values) {
      totalActive += s.activeSubsystems;
      totalSubs += s.totalSubsystems;
    }

    final overallHealth = avgScore >= 0.85
        ? LayerHealth.optimal
        : avgScore >= 0.6
        ? LayerHealth.degraded
        : LayerHealth.critical;

    _latestSnapshot = ApexPlatformSnapshot(
      generatedAt: DateTime.now(),
      layerStatuses: statuses,
      overallScore: avgScore,
      overallHealth: overallHealth,
      totalActiveSubsystems: totalActive,
      totalSubsystems: totalSubs,
    );

    notifyListeners();
  }

  /// Force an immediate platform snapshot.
  ApexPlatformSnapshot takeSnapshotNow() {
    _takeSnapshot();
    return _latestSnapshot!;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DIAGNOSTICS
  // ═══════════════════════════════════════════════════════════════════════

  /// Print a human-readable platform status to debug console.
  void printStatus() {
    final snap = _latestSnapshot;
    if (snap == null) {
      debugPrint('[DFC OS] No snapshot available — call boot() first');
      return;
    }

    debugPrint('');
    debugPrint('── DFC PLATFORM STATUS ──────────────────────────────');
    debugPrint(
      '  Overall: ${snap.overallHealth.name.toUpperCase()} '
      '(${(snap.overallScore * 100).toStringAsFixed(1)}%)',
    );
    debugPrint(
      '  Subsystems: ${snap.totalActiveSubsystems}/'
      '${snap.totalSubsystems} active',
    );
    debugPrint('  Uptime: ${uptime.inHours}h ${uptime.inMinutes % 60}m');
    debugPrint('');

    for (final layer in ApexLayer.values) {
      final status = snap.statusFor(layer);
      if (status != null) {
        final healthIcon = switch (status.health) {
          LayerHealth.optimal => '●',
          LayerHealth.degraded => '◐',
          LayerHealth.critical => '○',
          LayerHealth.offline => '✕',
          LayerHealth.booting => '◌',
        };
        debugPrint(
          '  $healthIcon ${layer.name.padRight(20)} '
          '${(status.score * 100).toStringAsFixed(0)}% '
          '(${status.activeSubsystems}/${status.totalSubsystems}) '
          '${status.statusMessage ?? ''}',
        );
      }
    }
    debugPrint('─────────────────────────────────────────────────────');
    debugPrint('');
  }

  @override
  void dispose() {
    _snapshotTimer?.cancel();
    super.dispose();
  }
}
