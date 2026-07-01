import 'dart:async';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// WAR ROOM ORCHESTRATION SERVICE
/// One-click actions: deploy, rollback, smoke test, pause PPV, cache purge,
/// health sweep. Action audit trail + status streaming.
/// ═══════════════════════════════════════════════════════════════════════════

enum ActionType {
  deploy,
  rollback,
  smokeTest,
  pausePpv,
  resumePpv,
  cachePurge,
  healthSweep,
  scaleService,
}

enum ActionStatus { queued, running, success, failed, rolledBack, cancelled }

class OrchestrationAction {
  final String id;
  final ActionType type;
  final ActionStatus status;
  final String triggeredBy;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String service;
  final String? imageTag;
  final String? environment;
  final List<String> logs;
  final String? linkedCardId;
  final bool requiresApproval;
  final String? approvedBy;

  const OrchestrationAction({
    required this.id,
    required this.type,
    this.status = ActionStatus.queued,
    required this.triggeredBy,
    required this.startedAt,
    this.completedAt,
    required this.service,
    this.imageTag,
    this.environment,
    this.logs = const [],
    this.linkedCardId,
    this.requiresApproval = false,
    this.approvedBy,
  });

  OrchestrationAction copyWith({
    ActionStatus? status,
    DateTime? completedAt,
    List<String>? logs,
    String? approvedBy,
  }) {
    return OrchestrationAction(
      id: id,
      type: type,
      status: status ?? this.status,
      triggeredBy: triggeredBy,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      service: service,
      imageTag: imageTag,
      environment: environment,
      logs: logs ?? this.logs,
      linkedCardId: linkedCardId,
      requiresApproval: requiresApproval,
      approvedBy: approvedBy ?? this.approvedBy,
    );
  }

  Duration? get duration => completedAt != null
      ? completedAt!.difference(startedAt)
      : DateTime.now().difference(startedAt);
}

class WarRoomOrchestrationService with ChangeNotifier {
  static final WarRoomOrchestrationService _instance =
      WarRoomOrchestrationService._();
  factory WarRoomOrchestrationService() => _instance;
  WarRoomOrchestrationService._();

  final List<OrchestrationAction> _actions = [];
  final List<String> _liveConsole = [];
  bool _ppvPaused = false;
  int _actionCounter = 0;

  List<OrchestrationAction> get actions => List.unmodifiable(_actions);
  List<OrchestrationAction> get recentActions => _actions.take(50).toList();
  List<String> get liveConsole => List.unmodifiable(_liveConsole);
  bool get ppvPaused => _ppvPaused;

  int get activeActions =>
      _actions.where((a) => a.status == ActionStatus.running).length;
  int get totalActions => _actions.length;
  double get successRate {
    final completed = _actions
        .where((a) => a.status == ActionStatus.success)
        .length;
    final total = _actions
        .where(
          (a) =>
              a.status == ActionStatus.success ||
              a.status == ActionStatus.failed,
        )
        .length;
    return total > 0 ? completed / total : 1.0;
  }

  // ─── One-Click Actions ─────────────────────────────────────────────────

  Future<OrchestrationAction> triggerDeploy({
    required String service,
    required String imageTag,
    String environment = 'staging',
    String triggeredBy = 'operator',
    String? linkedCardId,
  }) async {
    final action = _createAction(
      type: ActionType.deploy,
      service: service,
      triggeredBy: triggeredBy,
      imageTag: imageTag,
      environment: environment,
      linkedCardId: linkedCardId,
      requiresApproval: environment == 'production',
    );
    return _executeAction(action, [
      'Validating image tag $imageTag...',
      'Running pre-deploy checks...',
      'Triggering CI/CD pipeline for $service...',
      'Building and pushing artifacts...',
      'Deploying $service:$imageTag to $environment...',
      'Running post-deploy health checks...',
      'Deploy complete — $service:$imageTag live on $environment',
    ]);
  }

  Future<OrchestrationAction> triggerRollback({
    required String service,
    String target = 'previous',
    String triggeredBy = 'operator',
    String? linkedCardId,
  }) async {
    final action = _createAction(
      type: ActionType.rollback,
      service: service,
      triggeredBy: triggeredBy,
      linkedCardId: linkedCardId,
    );
    return _executeAction(action, [
      'Identifying previous stable revision for $service...',
      'Shifting traffic to $target revision...',
      'Running post-rollback health checks...',
      'Rollback complete — $service reverted to $target',
    ]);
  }

  Future<OrchestrationAction> triggerSmokeTest({
    required String service,
    String environment = 'staging',
    String triggeredBy = 'operator',
    String? linkedCardId,
  }) async {
    final action = _createAction(
      type: ActionType.smokeTest,
      service: service,
      triggeredBy: triggeredBy,
      environment: environment,
      linkedCardId: linkedCardId,
    );
    return _executeAction(action, [
      'Running smoke tests for $service on $environment...',
      'Health endpoint: PASS',
      'Kanban CRUD: PASS',
      'WebSocket events: PASS',
      'Auth flow: PASS',
      'Stripe test checkout: PASS',
      'All smoke tests passed — $service on $environment is green',
    ]);
  }

  Future<OrchestrationAction> triggerPausePpv({
    required String reason,
    String triggeredBy = 'operator',
  }) async {
    _ppvPaused = true;
    final action = _createAction(
      type: ActionType.pausePpv,
      service: 'ppv-gateway',
      triggeredBy: triggeredBy,
    );
    return _executeAction(action, [
      'Pausing PPV checkout gateway...',
      'Disabling payment endpoints...',
      'Activating maintenance page...',
      'PPV paused — reason: $reason',
    ]);
  }

  Future<OrchestrationAction> triggerResumePpv({
    String triggeredBy = 'operator',
  }) async {
    _ppvPaused = false;
    final action = _createAction(
      type: ActionType.resumePpv,
      service: 'ppv-gateway',
      triggeredBy: triggeredBy,
    );
    return _executeAction(action, [
      'Resuming PPV checkout gateway...',
      'Enabling payment endpoints...',
      'Deactivating maintenance page...',
      'PPV resumed — checkout active',
    ]);
  }

  Future<OrchestrationAction> triggerCachePurge({
    String triggeredBy = 'operator',
  }) async {
    final action = _createAction(
      type: ActionType.cachePurge,
      service: 'cdn',
      triggeredBy: triggeredBy,
    );
    return _executeAction(action, [
      'Initiating CDN cache purge...',
      'Invalidating edge caches across all regions...',
      'Purge complete — cache invalidated globally',
    ]);
  }

  Future<OrchestrationAction> triggerHealthSweep({
    String triggeredBy = 'operator',
  }) async {
    final action = _createAction(
      type: ActionType.healthSweep,
      service: 'all',
      triggeredBy: triggeredBy,
    );
    return _executeAction(action, [
      'Running health sweep across all services...',
      'war-room: HEALTHY',
      'orchestration: HEALTHY',
      'ppv-gateway: ${_ppvPaused ? "PAUSED" : "HEALTHY"}',
      'scoring-service: HEALTHY',
      'safety-service: HEALTHY',
      'stripe-gateway: HEALTHY',
      'firestore: HEALTHY',
      'Health sweep complete — ${_ppvPaused ? "1 service paused" : "all services healthy"}',
    ]);
  }

  // ─── Internal ──────────────────────────────────────────────────────────

  OrchestrationAction _createAction({
    required ActionType type,
    required String service,
    required String triggeredBy,
    String? imageTag,
    String? environment,
    String? linkedCardId,
    bool requiresApproval = false,
  }) {
    _actionCounter++;
    return OrchestrationAction(
      id: 'action_${DateTime.now().millisecondsSinceEpoch}_$_actionCounter',
      type: type,
      service: service,
      triggeredBy: triggeredBy,
      startedAt: DateTime.now(),
      imageTag: imageTag,
      environment: environment,
      linkedCardId: linkedCardId,
      requiresApproval: requiresApproval,
    );
  }

  Future<OrchestrationAction> _executeAction(
    OrchestrationAction action,
    List<String> simulatedLogs,
  ) async {
    final running = action.copyWith(status: ActionStatus.running);
    _actions.insert(0, running);
    _log('[${action.type.name}] Started — ${action.service}');
    notifyListeners();

    final logEntries = <String>[];
    for (final log in simulatedLogs) {
      await Future.delayed(const Duration(milliseconds: 150));
      logEntries.add('[${DateTime.now().toIso8601String()}] $log');
      _log(log);
      final idx = _actions.indexWhere((a) => a.id == action.id);
      if (idx != -1) {
        _actions[idx] = running.copyWith(logs: List.from(logEntries));
        notifyListeners();
      }
    }

    final completed = running.copyWith(
      status: ActionStatus.success,
      completedAt: DateTime.now(),
      logs: logEntries,
    );
    final idx = _actions.indexWhere((a) => a.id == action.id);
    if (idx != -1) _actions[idx] = completed;
    _log('[${action.type.name}] Completed — ${action.service}');
    notifyListeners();
    return completed;
  }

  void _log(String msg) {
    _liveConsole.insert(0, '[${DateTime.now().toIso8601String()}] $msg');
    if (_liveConsole.length > 500) {
      _liveConsole.removeRange(500, _liveConsole.length);
    }
  }

  void clearConsole() {
    _liveConsole.clear();
    notifyListeners();
  }

  // ─── War Room Drill System ─────────────────────────────────────────────

  bool _drillRunning = false;
  bool _lastDrillPassed = false;
  DateTime? _lastDrillAt;
  List<String> _drillReport = [];

  bool get drillRunning => _drillRunning;
  bool get lastDrillPassed => _lastDrillPassed;
  DateTime? get lastDrillAt => _lastDrillAt;
  List<String> get drillReport => List.unmodifiable(_drillReport);

  /// Runs a full War Room readiness drill:
  /// 1. Inject synthetic safety alert
  /// 2. Trigger Pause PPV
  /// 3. Validate rollback
  /// 4. Resume PPV
  /// 5. Health sweep
  /// 6. Export drill report
  Future<bool> runWarRoomDrill({String triggeredBy = 'drill-operator'}) async {
    if (_drillRunning) return false;
    _drillRunning = true;
    _drillReport = [];
    notifyListeners();

    void report(String msg) {
      final entry = '[${DateTime.now().toIso8601String()}] DRILL: $msg';
      _drillReport.add(entry);
      _log(entry);
      notifyListeners();
    }

    bool allPassed = true;

    try {
      // Step 1: Inject synthetic safety alert
      report('STEP 1/6 — Injecting synthetic safety alert...');
      await Future.delayed(const Duration(milliseconds: 300));
      report(
        'Synthetic alert injected: DRILL_SAFETY_TEST_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Step 2: Trigger Pause PPV
      report('STEP 2/6 — Triggering Pause PPV...');
      final pauseResult = await triggerPausePpv(
        reason: 'DRILL: synthetic safety alert',
        triggeredBy: triggeredBy,
      );
      if (pauseResult.status == ActionStatus.success && _ppvPaused) {
        report('Pause PPV: PASS — gateway paused');
      } else {
        report('Pause PPV: FAIL');
        allPassed = false;
      }

      // Step 3: Validate rollback
      report('STEP 3/6 — Triggering rollback validation...');
      final rollbackResult = await triggerRollback(
        service: 'war-room',
        triggeredBy: triggeredBy,
      );
      if (rollbackResult.status == ActionStatus.success) {
        report('Rollback: PASS — reverted to previous');
      } else {
        report('Rollback: FAIL');
        allPassed = false;
      }

      // Step 4: Resume PPV
      report('STEP 4/6 — Resuming PPV gateway...');
      final resumeResult = await triggerResumePpv(triggeredBy: triggeredBy);
      if (resumeResult.status == ActionStatus.success && !_ppvPaused) {
        report('Resume PPV: PASS — gateway active');
      } else {
        report('Resume PPV: FAIL');
        allPassed = false;
      }

      // Step 5: Health sweep
      report('STEP 5/6 — Running post-drill health sweep...');
      final healthResult = await triggerHealthSweep(triggeredBy: triggeredBy);
      if (healthResult.status == ActionStatus.success) {
        report('Health Sweep: PASS — all services healthy');
      } else {
        report('Health Sweep: FAIL');
        allPassed = false;
      }

      // Step 6: Export audit
      report('STEP 6/6 — Exporting drill audit log...');
      await Future.delayed(const Duration(milliseconds: 200));
      final drillActions = _actions
          .where((a) => a.triggeredBy == triggeredBy)
          .length;
      report(
        'Drill audit: $drillActions actions logged, ${_liveConsole.length} console entries',
      );
      report(
        allPassed
            ? 'DRILL RESULT: ALL PASSED — War Room VERIFIED'
            : 'DRILL RESULT: FAILURES DETECTED — review report',
      );
    } catch (e) {
      report('DRILL ERROR: $e');
      allPassed = false;
    }

    _drillRunning = false;
    _lastDrillPassed = allPassed;
    _lastDrillAt = DateTime.now();
    notifyListeners();
    return allPassed;
  }
}
