import 'dart:async';
import 'package:flutter/foundation.dart';

import 'dfc_ai_powerhouse.dart';
import 'sports_science_engine.dart';
import 'dfc_nexus.dart';

/// Core operating pillars for SAMURAI
/// These define how the engine governs DFC end-to-end.
enum SamuraiPillar {
  automation,
  monitoring,
  monetization,
  promotion,
  health,
  discipline,
}

enum SamuraiProtocolStatus { active, warning, critical }

class SamuraiCommand {
  final String id;
  final SamuraiPillar pillar;
  final String title;
  final String action;
  final double priority;
  final bool automated;
  final DateTime createdAt;

  const SamuraiCommand({
    required this.id,
    required this.pillar,
    required this.title,
    required this.action,
    required this.priority,
    this.automated = true,
    required this.createdAt,
  });
}

class SamuraiProtocolSnapshot {
  final DateTime generatedAt;
  final Map<SamuraiPillar, double> pillarScores;
  final SamuraiProtocolStatus status;
  final double powerIndex;
  final List<SamuraiCommand> commandQueue;

  const SamuraiProtocolSnapshot({
    required this.generatedAt,
    required this.pillarScores,
    required this.status,
    required this.powerIndex,
    this.commandQueue = const [],
  });

  double scoreFor(SamuraiPillar pillar) => pillarScores[pillar] ?? 0.0;
}

/// SAMURAI CORE ENGINE
/// Unified protocol engine that keeps DFC disciplined, automated, and growing.
class SamuraiCoreEngine extends ChangeNotifier {
  static final SamuraiCoreEngine _instance = SamuraiCoreEngine._internal();
  factory SamuraiCoreEngine() => _instance;
  SamuraiCoreEngine._internal();

  final DFCAIPowerhouse _powerhouse = DFCAIPowerhouse();
  final SportsScienceEngine _sportsScience = SportsScienceEngine();
  final DfcNexus _nexus = DfcNexus();

  bool _initialized = false;
  bool _autonomousMode = true;
  DateTime? _lastCycle;
  Timer? _cycleTimer;

  SamuraiProtocolSnapshot? _latestSnapshot;
  List<SamuraiCommand> _commandQueue = [];

  bool get initialized => _initialized;
  bool get autonomousMode => _autonomousMode;
  DateTime? get lastCycle => _lastCycle;
  SamuraiProtocolSnapshot? get latestSnapshot => _latestSnapshot;
  List<SamuraiCommand> get commandQueue => List.unmodifiable(_commandQueue);

  Future<void> initialize() async {
    if (_initialized) return;

    await Future.wait([
      _nexus.initialize(),
      if (!_sportsScience.initialized) _sportsScience.initialize(),
      if (!_powerhouse.initialized && !_powerhouse.isBooting)
        _powerhouse.bootAllEngines(),
    ]);

    _initialized = true;
    await runAutonomousCycle();
    _startAutonomousTimer();
    notifyListeners();

    debugPrint('⚔️ SAMURAI CORE ENGINE ONLINE — protocols active');
  }

  void setAutonomousMode(bool enabled) {
    _autonomousMode = enabled;
    if (enabled) {
      _startAutonomousTimer();
    } else {
      _cycleTimer?.cancel();
    }
    notifyListeners();
  }

  Future<SamuraiProtocolSnapshot> runAutonomousCycle() async {
    if (!_initialized) {
      await initialize();
    }

    final scores = _calculatePillarScores();
    final powerIndex = scores.values.isEmpty
        ? 0.0
        : scores.values.reduce((a, b) => a + b) / scores.length;

    final status = powerIndex >= 0.78
        ? SamuraiProtocolStatus.active
        : powerIndex >= 0.55
        ? SamuraiProtocolStatus.warning
        : SamuraiProtocolStatus.critical;

    _commandQueue = _buildCommandQueue(scores, status);
    _lastCycle = DateTime.now();

    _latestSnapshot = SamuraiProtocolSnapshot(
      generatedAt: _lastCycle!,
      pillarScores: scores,
      status: status,
      powerIndex: powerIndex,
      commandQueue: _commandQueue,
    );

    notifyListeners();
    return _latestSnapshot!;
  }

  Map<String, dynamic> getExecutiveSummary() {
    final snapshot = _latestSnapshot;
    if (snapshot == null) {
      return {
        'status': 'initializing',
        'powerIndex': 0.0,
        'commands': <Map<String, dynamic>>[],
      };
    }

    return {
      'status': snapshot.status.name,
      'powerIndex': snapshot.powerIndex,
      'lastCycle': snapshot.generatedAt.toIso8601String(),
      'pillarScores': {
        for (final entry in snapshot.pillarScores.entries)
          entry.key.name: entry.value,
      },
      'topCommands': snapshot.commandQueue
          .take(5)
          .map(
            (command) => {
              'pillar': command.pillar.name,
              'title': command.title,
              'action': command.action,
              'priority': command.priority,
            },
          )
          .toList(),
    };
  }

  Map<SamuraiPillar, double> _calculatePillarScores() {
    final status = _powerhouse.status;
    final readinessTrend = _sportsScience.getReadinessTrend(days: 7);
    final sleepTrend = _sportsScience.getSleepTrend(days: 7);
    final acwr = _sportsScience.currentACWR?.ratio ?? 1.2;

    final avgReadiness = readinessTrend.isEmpty
        ? 70.0
        : readinessTrend.map((item) => item.value).reduce((a, b) => a + b) /
              readinessTrend.length;

    final avgSleep = sleepTrend.isEmpty
        ? 7.0
        : sleepTrend.map((item) => item.value).reduce((a, b) => a + b) /
              sleepTrend.length;

    final healthScore = _clamp01(
      (avgReadiness / 100) * 0.7 + (avgSleep / 9) * 0.3,
    );
    final monitoringScore = _clamp01(status.healthPercent);

    final promotionSignal = _powerhouse.unifiedFeed.length;
    final promotionScore = _clamp01(
      (promotionSignal / 120).clamp(0, 1).toDouble(),
    );

    final monetizationScore = _clamp01(
      (promotionScore * 0.55) + (monitoringScore * 0.45),
    );

    final disciplinePenalty = acwr > 1.5 || acwr < 0.75 ? 0.25 : 0.0;
    final disciplineScore = _clamp01(
      (healthScore * 0.8) - disciplinePenalty + 0.2,
    );

    final automationScore = _clamp01(
      ((_powerhouse.initialized ? 1.0 : 0.0) +
              (_sportsScience.initialized ? 1.0 : 0.0) +
              (_nexus.isInitialized ? 1.0 : 0.0)) /
          3,
    );

    return {
      SamuraiPillar.automation: automationScore,
      SamuraiPillar.monitoring: monitoringScore,
      SamuraiPillar.monetization: monetizationScore,
      SamuraiPillar.promotion: promotionScore,
      SamuraiPillar.health: healthScore,
      SamuraiPillar.discipline: disciplineScore,
    };
  }

  List<SamuraiCommand> _buildCommandQueue(
    Map<SamuraiPillar, double> scores,
    SamuraiProtocolStatus status,
  ) {
    final commands = <SamuraiCommand>[];

    void addCommand({
      required SamuraiPillar pillar,
      required String title,
      required String action,
      required double priority,
    }) {
      commands.add(
        SamuraiCommand(
          id: '${pillar.name}_${DateTime.now().microsecondsSinceEpoch}_${commands.length}',
          pillar: pillar,
          title: title,
          action: action,
          priority: priority,
          createdAt: DateTime.now(),
        ),
      );
    }

    if ((scores[SamuraiPillar.health] ?? 0) < 0.65) {
      addCommand(
        pillar: SamuraiPillar.health,
        title: 'Stabilize Recovery Load',
        action:
            'Reduce high-intensity volume 20% and prioritize sleep/recovery protocol.',
        priority: 0.95,
      );
    }

    if ((scores[SamuraiPillar.monitoring] ?? 0) < 0.70) {
      addCommand(
        pillar: SamuraiPillar.monitoring,
        title: 'Increase Sensor Coverage',
        action: 'Sync all wearables and enforce missing biometrics completion.',
        priority: 0.90,
      );
    }

    if ((scores[SamuraiPillar.promotion] ?? 0) < 0.65) {
      addCommand(
        pillar: SamuraiPillar.promotion,
        title: 'Boost Content Cadence',
        action:
            'Generate 3 promoter-ready campaign items from powerhouse trending signals.',
        priority: 0.82,
      );
    }

    if ((scores[SamuraiPillar.monetization] ?? 0) < 0.60) {
      addCommand(
        pillar: SamuraiPillar.monetization,
        title: 'Activate Monetization Funnel',
        action:
            'Prioritize premium insights and sponsor spotlight placements on high-engagement feeds.',
        priority: 0.80,
      );
    }

    if ((scores[SamuraiPillar.automation] ?? 0) < 0.75) {
      addCommand(
        pillar: SamuraiPillar.automation,
        title: 'Repair Automation Pipeline',
        action:
            'Reboot AI Powerhouse heartbeat and enforce autonomous cycle health checks.',
        priority: 0.88,
      );
    }

    if ((scores[SamuraiPillar.discipline] ?? 0) < 0.70) {
      addCommand(
        pillar: SamuraiPillar.discipline,
        title: 'Enforce Training Discipline',
        action:
            'Apply protocol lock: no overload session while ACWR risk is elevated.',
        priority: 0.92,
      );
    }

    if (status == SamuraiProtocolStatus.active && commands.isEmpty) {
      addCommand(
        pillar: SamuraiPillar.automation,
        title: 'Scale Winning System',
        action:
            'Maintain autonomous cycle and expand promotional output by +15% this week.',
        priority: 0.70,
      );
    }

    commands.sort((a, b) => b.priority.compareTo(a.priority));
    return commands;
  }

  void _startAutonomousTimer() {
    _cycleTimer?.cancel();
    if (!_autonomousMode) return;

    _cycleTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      runAutonomousCycle();
    });
  }

  double _clamp01(double value) => value.clamp(0.0, 1.0);

  @override
  void dispose() {
    _cycleTimer?.cancel();
    super.dispose();
  }
}
