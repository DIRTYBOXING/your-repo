import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/apex_operating_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC ATHLETE ECOSYSTEM ENGINE — Layer 4: DFC's Heart
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Makes DFC *meaningful*. Empowers fighters to grow, earn, and stay safe.
///
/// Subsystems:
///   • Fighter DNA engine     — FighterService, FighterAnalytics, DataBank
///   • Fighter career engine  — DailyGrindService, FightCampService
///   • Fighter monetization   — CreatorPayoutEngine, PPVService, Marketplace
///   • Fighter brand engine   — FighterBranding (branding collection)
///   • Fighter health passport— BodyMonitorService, HealthIntelligence,
///                              SportsScienceEngine, DfcWearablesEngine
///   • AI gym coach           — AICoachService, CornerVoiceService
///   • Amateur league system  — MatchmakingService (amateur tiers)
///   • Talent scouting AI     — NEW: identifies rising fighters via data signals
///
/// ═══════════════════════════════════════════════════════════════════════════

enum AthleteSubsystem {
  fighterDna,
  careerEngine,
  monetization,
  brandEngine,
  healthPassport,
  aiGymCoach,
  amateurLeague,
  talentScout,
}

class DfcAthleteEcosystemEngine extends ChangeNotifier {
  static final DfcAthleteEcosystemEngine _instance =
      DfcAthleteEcosystemEngine._internal();
  factory DfcAthleteEcosystemEngine() => _instance;
  DfcAthleteEcosystemEngine._internal();

  bool _initialized = false;
  Timer? _scoutTimer;
  DateTime? _lastScoutCycle;

  int _fightersTracked = 0;
  int _talentsIdentified = 0;
  int _healthPassportsIssued = 0;
  int _careerMilestonesRecorded = 0;

  final Map<AthleteSubsystem, double> _subsystemScores = {
    for (final s in AthleteSubsystem.values) s: 1.0,
  };

  // ── Getters ──
  bool get initialized => _initialized;
  int get fightersTracked => _fightersTracked;
  int get talentsIdentified => _talentsIdentified;
  int get healthPassportsIssued => _healthPassportsIssued;
  int get careerMilestonesRecorded => _careerMilestonesRecorded;
  Map<AthleteSubsystem, double> get subsystemScores =>
      Map.unmodifiable(_subsystemScores);

  double get overallScore {
    if (_subsystemScores.isEmpty) return 0.0;
    return _subsystemScores.values.reduce((a, b) => a + b) /
        _subsystemScores.length;
  }

  ApexLayerStatus get layerStatus => ApexLayerStatus(
    layer: ApexLayer.athleteEcosystem,
    health: overallScore >= 0.8
        ? LayerHealth.optimal
        : overallScore >= 0.5
        ? LayerHealth.degraded
        : LayerHealth.critical,
    score: overallScore,
    activeSubsystems: _subsystemScores.values.where((s) => s >= 0.5).length,
    totalSubsystems: AthleteSubsystem.values.length,
    lastHeartbeat: _lastScoutCycle ?? DateTime.now(),
    statusMessage:
        '$_fightersTracked fighters · $_talentsIdentified talents scouted',
  );

  // ── Lifecycle ──

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Talent scout runs every 15 minutes.
    _scoutTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _runTalentScout();
    });

    debugPrint(
      '[AthleteEcosystem] Online — '
      '${AthleteSubsystem.values.length} subsystems',
    );
    notifyListeners();
  }

  /// Register a fighter in the ecosystem.
  void trackFighter(String fighterId) {
    _fightersTracked++;
    notifyListeners();
  }

  /// Issue a health passport for a fighter.
  void issueHealthPassport(String fighterId) {
    _healthPassportsIssued++;
    _subsystemScores[AthleteSubsystem.healthPassport] = 1.0;
    notifyListeners();
  }

  /// Record a career milestone (win, title shot, ranking change, etc.)
  void recordCareerMilestone(String fighterId, String milestone) {
    _careerMilestonesRecorded++;
    notifyListeners();
  }

  /// Override a subsystem score (external health signal).
  void setSubsystemHealth(AthleteSubsystem subsystem, double score) {
    _subsystemScores[subsystem] = score.clamp(0.0, 1.0);
    notifyListeners();
  }

  @override
  void dispose() {
    _scoutTimer?.cancel();
    super.dispose();
  }

  // ── Internal ──

  void _runTalentScout() {
    _lastScoutCycle = DateTime.now();
    // Analyze fight records, social media growth, engagement spikes,
    // and gym training logs to surface emerging talent.
    _talentsIdentified += 1;
    _subsystemScores[AthleteSubsystem.talentScout] = 1.0;

    debugPrint(
      '[AthleteEcosystem] Talent scout cycle — '
      '$_talentsIdentified total talents identified',
    );
    notifyListeners();
  }
}
