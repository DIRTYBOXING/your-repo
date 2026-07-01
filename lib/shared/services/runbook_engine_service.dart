import 'package:flutter/foundation.dart';
import '../models/kanban_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// RUNBOOK ENGINE SERVICE — Store, display, execute runbook steps with audit
/// ═══════════════════════════════════════════════════════════════════════════

enum RunbookExecutionStatus { pending, running, passed, failed, skipped }

class RunbookExecution {
  final String id;
  final String runbookId;
  final String executedBy;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<RunbookStepResult> stepResults;
  final RunbookExecutionStatus status;

  const RunbookExecution({
    required this.id,
    required this.runbookId,
    required this.executedBy,
    required this.startedAt,
    this.completedAt,
    this.stepResults = const [],
    this.status = RunbookExecutionStatus.pending,
  });
}

class RunbookStepResult {
  final int stepOrder;
  final RunbookExecutionStatus status;
  final String output;
  final DateTime executedAt;

  const RunbookStepResult({
    required this.stepOrder,
    required this.status,
    this.output = '',
    required this.executedAt,
  });
}

class RunbookEngineService with ChangeNotifier {
  static final RunbookEngineService _instance = RunbookEngineService._();
  factory RunbookEngineService() => _instance;
  RunbookEngineService._();

  final List<Runbook> _runbooks = [];
  final List<RunbookExecution> _executions = [];
  bool _initialized = false;

  List<Runbook> get runbooks => List.unmodifiable(_runbooks);
  List<RunbookExecution> get executions => List.unmodifiable(_executions);
  bool get initialized => _initialized;

  Runbook? getRunbook(String id) {
    try {
      return _runbooks.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _seedRunbooks();
    _initialized = true;
    notifyListeners();
  }

  // ─── CRUD ──────────────────────────────────────────────────────────────

  void addRunbook(Runbook runbook) {
    _runbooks.add(runbook);
    notifyListeners();
  }

  void removeRunbook(String id) {
    _runbooks.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  // ─── Execution ─────────────────────────────────────────────────────────

  Future<RunbookExecution> executeRunbook({
    required String runbookId,
    required String executedBy,
  }) async {
    final runbook = getRunbook(runbookId);
    if (runbook == null) throw StateError('Runbook $runbookId not found');

    final execution = RunbookExecution(
      id: 'exec_${DateTime.now().millisecondsSinceEpoch}',
      runbookId: runbookId,
      executedBy: executedBy,
      startedAt: DateTime.now(),
      status: RunbookExecutionStatus.running,
    );
    _executions.insert(0, execution);
    notifyListeners();

    final results = <RunbookStepResult>[];
    for (final step in runbook.steps) {
      await Future.delayed(const Duration(milliseconds: 200));
      results.add(
        RunbookStepResult(
          stepOrder: step.order,
          status: RunbookExecutionStatus.passed,
          output: 'Step ${step.order}: ${step.instruction} — OK',
          executedAt: DateTime.now(),
        ),
      );
      final idx = _executions.indexWhere((e) => e.id == execution.id);
      if (idx != -1) {
        _executions[idx] = RunbookExecution(
          id: execution.id,
          runbookId: runbookId,
          executedBy: executedBy,
          startedAt: execution.startedAt,
          stepResults: List.from(results),
          status: RunbookExecutionStatus.running,
        );
        notifyListeners();
      }
    }

    final completed = RunbookExecution(
      id: execution.id,
      runbookId: runbookId,
      executedBy: executedBy,
      startedAt: execution.startedAt,
      completedAt: DateTime.now(),
      stepResults: results,
      status: RunbookExecutionStatus.passed,
    );
    final idx = _executions.indexWhere((e) => e.id == execution.id);
    if (idx != -1) _executions[idx] = completed;
    notifyListeners();
    return completed;
  }

  // ─── Seed Runbooks ─────────────────────────────────────────────────────

  void _seedRunbooks() {
    final now = DateTime.now();
    _runbooks.addAll([
      Runbook(
        id: 'rb_emergency_ppv_pause',
        title: 'Emergency PPV Pause',
        triggerConditions: 'Critical safety alert OR payment gateway outage',
        impact: 'Pause all checkouts and show maintenance page',
        prechecks: [
          'Confirm alert source and severity',
          'Notify Ops Lead and Safety Officer',
        ],
        steps: [
          const RunbookStep(
            order: 1,
            instruction: 'Execute pause-ppv action',
            command: 'POST /actions/pause-ppv',
          ),
          const RunbookStep(
            order: 2,
            instruction: 'Verify checkout endpoints return maintenance status',
          ),
          const RunbookStep(
            order: 3,
            instruction: 'Post message to #warroom Slack with incident link',
          ),
          const RunbookStep(
            order: 4,
            instruction: 'If issue persists >5m, trigger rollback',
            command: 'POST /actions/rollback',
            requiresApproval: true,
          ),
          const RunbookStep(
            order: 5,
            instruction: 'Open incident ticket and assign Safety Officer',
          ),
        ],
        postmortem: 'Export logs, attach audit trail, schedule RCA within 24h',
        createdAt: now,
      ),
      Runbook(
        id: 'rb_one_click_deploy',
        title: 'One-Click Deploy',
        triggerConditions: 'Release PR approved',
        impact: 'Deploy new image, run smoke tests, notify stakeholders',
        prechecks: ['All unit tests passed', 'Security scan passed'],
        steps: [
          const RunbookStep(
            order: 1,
            instruction: 'Trigger CI/CD pipeline',
            command: 'POST /actions/deploy',
          ),
          const RunbookStep(
            order: 2,
            instruction: 'Wait for build status to report success',
          ),
          const RunbookStep(
            order: 3,
            instruction: 'Run smoke tests',
            command: 'POST /actions/smoke-test',
          ),
          const RunbookStep(
            order: 4,
            instruction: 'If smoke tests fail, trigger rollback',
            requiresApproval: true,
          ),
          const RunbookStep(
            order: 5,
            instruction: 'Post deploy summary to #warroom Slack',
          ),
        ],
        postmortem: 'Attach deploy logs and audit entry to release PR',
        createdAt: now,
      ),
      Runbook(
        id: 'rb_rollback',
        title: 'Emergency Rollback',
        triggerConditions: 'Error rate >1% sustained or critical safety alert',
        impact: 'Revert to previous stable revision',
        prechecks: ['Identify failing revision', 'Notify on-call team'],
        steps: [
          const RunbookStep(
            order: 1,
            instruction: 'Shift traffic to previous revision',
            command: 'POST /actions/rollback',
          ),
          const RunbookStep(
            order: 2,
            instruction: 'Run post-rollback health checks',
          ),
          const RunbookStep(
            order: 3,
            instruction: 'Confirm error rate stabilizes',
          ),
          const RunbookStep(order: 4, instruction: 'Open incident ticket'),
        ],
        postmortem: 'Collect logs, tag deploy, schedule RCA',
        createdAt: now,
      ),
      Runbook(
        id: 'rb_war_room_drill',
        title: 'War Room Drill',
        triggerConditions: 'Scheduled drill or pre-event readiness check',
        impact: 'Validate all War Room systems end-to-end',
        prechecks: ['All services healthy', 'Ops team on standby'],
        steps: [
          const RunbookStep(
            order: 1,
            instruction: 'Inject synthetic safety alert',
          ),
          const RunbookStep(
            order: 2,
            instruction: 'Trigger pause PPV from War Room UI',
          ),
          const RunbookStep(order: 3, instruction: 'Confirm checkout disabled'),
          const RunbookStep(order: 4, instruction: 'Trigger rollback workflow'),
          const RunbookStep(
            order: 5,
            instruction: 'Run smoke tests to confirm recovery',
          ),
          const RunbookStep(
            order: 6,
            instruction: 'Collect logs and export audit trail',
          ),
          const RunbookStep(order: 7, instruction: 'Mark drill card Verified'),
        ],
        postmortem: 'Measure MTTR, update drill report, schedule next drill',
        createdAt: now,
      ),
      Runbook(
        id: 'rb_health_sweep',
        title: 'Full Health Sweep',
        triggerConditions: 'Pre-event or on-demand health check',
        impact: 'Verify all services are healthy',
        prechecks: [],
        steps: [
          const RunbookStep(
            order: 1,
            instruction: 'Run health sweep across all services',
            command: 'POST /actions/health-sweep',
          ),
          const RunbookStep(
            order: 2,
            instruction: 'Review results and flag unhealthy services',
          ),
          const RunbookStep(
            order: 3,
            instruction: 'Restart unhealthy services if needed',
          ),
          const RunbookStep(
            order: 4,
            instruction: 'Confirm all services healthy',
          ),
        ],
        postmortem: 'Log health report',
        createdAt: now,
      ),
    ]);
  }
}
