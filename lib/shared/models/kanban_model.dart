/// ═══════════════════════════════════════════════════════════════════════════
/// KANBAN DATA MODEL — Card, Column, Board, and supporting types.
/// Immutable data classes for the War Room Kanban system.
/// ═══════════════════════════════════════════════════════════════════════════
library;

// ─── Enums ───────────────────────────────────────────────────────────────

enum KanbanColumn { backlog, ready, inProgress, verify, blocked, done }

enum KanbanPriority { p0Critical, p1High, p2Medium, p3Low }

enum DeployStatus {
  notStarted,
  building,
  deploying,
  deployed,
  failed,
  rolledBack,
}

enum WarRoomRole {
  founderAdmin,
  opsLead,
  promoterManager,
  safetyOfficer,
  readOnlyAuditor,
}

// ─── Kanban Card ─────────────────────────────────────────────────────────

class KanbanCard {
  final String id;
  final String title;
  final String description;
  final KanbanColumn column;
  final KanbanPriority priority;
  final String owner;
  final String? eta;
  final List<String> linkedServices;
  final String? linkedPR;
  final String? runbookId;
  final List<String> testChecklist;
  final DeployStatus deployStatus;
  final String? incidentLink;
  final List<String> attachments;
  final List<KanbanSubtask> subtasks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<KanbanAuditEntry> audit;

  const KanbanCard({
    required this.id,
    required this.title,
    this.description = '',
    this.column = KanbanColumn.backlog,
    this.priority = KanbanPriority.p2Medium,
    this.owner = 'Unassigned',
    this.eta,
    this.linkedServices = const [],
    this.linkedPR,
    this.runbookId,
    this.testChecklist = const [],
    this.deployStatus = DeployStatus.notStarted,
    this.incidentLink,
    this.attachments = const [],
    this.subtasks = const [],
    required this.createdAt,
    required this.updatedAt,
    this.audit = const [],
  });

  KanbanCard copyWith({
    String? title,
    String? description,
    KanbanColumn? column,
    KanbanPriority? priority,
    String? owner,
    String? eta,
    List<String>? linkedServices,
    String? linkedPR,
    String? runbookId,
    List<String>? testChecklist,
    DeployStatus? deployStatus,
    String? incidentLink,
    List<String>? attachments,
    List<KanbanSubtask>? subtasks,
    List<KanbanAuditEntry>? audit,
  }) {
    return KanbanCard(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      column: column ?? this.column,
      priority: priority ?? this.priority,
      owner: owner ?? this.owner,
      eta: eta ?? this.eta,
      linkedServices: linkedServices ?? this.linkedServices,
      linkedPR: linkedPR ?? this.linkedPR,
      runbookId: runbookId ?? this.runbookId,
      testChecklist: testChecklist ?? this.testChecklist,
      deployStatus: deployStatus ?? this.deployStatus,
      incidentLink: incidentLink ?? this.incidentLink,
      attachments: attachments ?? this.attachments,
      subtasks: subtasks ?? this.subtasks,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      audit: audit ?? this.audit,
    );
  }
}

// ─── Subtask ─────────────────────────────────────────────────────────────

class KanbanSubtask {
  final String id;
  final String title;
  final bool completed;

  const KanbanSubtask({
    required this.id,
    required this.title,
    this.completed = false,
  });
}

// ─── Audit Entry ─────────────────────────────────────────────────────────

class KanbanAuditEntry {
  final DateTime timestamp;
  final String userId;
  final String action;
  final String details;

  const KanbanAuditEntry({
    required this.timestamp,
    required this.userId,
    required this.action,
    required this.details,
  });
}

// ─── Runbook ─────────────────────────────────────────────────────────────

class Runbook {
  final String id;
  final String title;
  final String triggerConditions;
  final String impact;
  final List<String> prechecks;
  final List<RunbookStep> steps;
  final String postmortem;
  final DateTime createdAt;

  const Runbook({
    required this.id,
    required this.title,
    this.triggerConditions = '',
    this.impact = '',
    this.prechecks = const [],
    this.steps = const [],
    this.postmortem = '',
    required this.createdAt,
  });
}

class RunbookStep {
  final int order;
  final String instruction;
  final String? command;
  final bool requiresApproval;

  const RunbookStep({
    required this.order,
    required this.instruction,
    this.command,
    this.requiresApproval = false,
  });
}

// ─── Incident ────────────────────────────────────────────────────────────

enum IncidentSeverity { critical, high, medium, low }

enum IncidentStatus { open, investigating, mitigating, resolved, postmortem }

class Incident {
  final String id;
  final String title;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final String assignee;
  final String? linkedCardId;
  final DateTime openedAt;
  final DateTime? resolvedAt;
  final List<String> timeline;

  const Incident({
    required this.id,
    required this.title,
    this.severity = IncidentSeverity.medium,
    this.status = IncidentStatus.open,
    this.assignee = 'Unassigned',
    this.linkedCardId,
    required this.openedAt,
    this.resolvedAt,
    this.timeline = const [],
  });
}

// ─── RBAC Permission ─────────────────────────────────────────────────────

class RolePermission {
  final WarRoomRole role;
  final bool canDeploy;
  final bool canRollback;
  final bool canPausePPV;
  final bool canApprovePayouts;
  final bool canManageCards;
  final bool canViewAuditLogs;
  final bool canManageSafety;
  final bool canEditRunbooks;
  final bool requiresSecondApprover;

  const RolePermission({
    required this.role,
    this.canDeploy = false,
    this.canRollback = false,
    this.canPausePPV = false,
    this.canApprovePayouts = false,
    this.canManageCards = false,
    this.canViewAuditLogs = false,
    this.canManageSafety = false,
    this.canEditRunbooks = false,
    this.requiresSecondApprover = false,
  });
}

// ─── War Room Telemetry ──────────────────────────────────────────────────

class WarRoomTelemetry {
  final String clusterHealth; // green, amber, red
  final int activeIncidents;
  final int liveViewers;
  final double ppvRevenueToday;
  final double deploySuccessRate;
  final Duration meanTimeToDetect;
  final Duration meanTimeToRecover;
  final int safetyAlertsToday;

  const WarRoomTelemetry({
    this.clusterHealth = 'green',
    this.activeIncidents = 0,
    this.liveViewers = 0,
    this.ppvRevenueToday = 0,
    this.deploySuccessRate = 0,
    this.meanTimeToDetect = Duration.zero,
    this.meanTimeToRecover = Duration.zero,
    this.safetyAlertsToday = 0,
  });
}

// ─── Helpers ─────────────────────────────────────────────────────────────

String kanbanColumnLabel(KanbanColumn col) {
  switch (col) {
    case KanbanColumn.backlog:
      return 'BACKLOG';
    case KanbanColumn.ready:
      return 'READY';
    case KanbanColumn.inProgress:
      return 'IN PROGRESS';
    case KanbanColumn.verify:
      return 'VERIFY';
    case KanbanColumn.blocked:
      return 'BLOCKED';
    case KanbanColumn.done:
      return 'DONE';
  }
}

String priorityLabel(KanbanPriority p) {
  switch (p) {
    case KanbanPriority.p0Critical:
      return 'P0 CRITICAL';
    case KanbanPriority.p1High:
      return 'P1 HIGH';
    case KanbanPriority.p2Medium:
      return 'P2 MEDIUM';
    case KanbanPriority.p3Low:
      return 'P3 LOW';
  }
}
