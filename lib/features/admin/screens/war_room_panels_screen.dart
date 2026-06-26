import 'package:flutter/material.dart';
import '../../../shared/models/kanban_model.dart';
import '../../../shared/services/war_room_orchestration_service.dart';
import '../../../shared/services/war_room_rbac_service.dart';
import '../../../shared/services/war_room_kanban_service.dart';
import '../../../shared/services/runbook_engine_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// WAR ROOM PANELS SCREEN — Tabbed sub-panels:
///   Runbooks | Actions Log | Incidents | Audit | Approvals
/// ═══════════════════════════════════════════════════════════════════════════
class WarRoomPanelsScreen extends StatefulWidget {
  const WarRoomPanelsScreen({super.key});

  @override
  State<WarRoomPanelsScreen> createState() => _WarRoomPanelsScreenState();
}

class _WarRoomPanelsScreenState extends State<WarRoomPanelsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _orchestration = WarRoomOrchestrationService();
  final _rbac = WarRoomRbacService();
  final _kanban = WarRoomKanbanService();
  final _runbooks = RunbookEngineService();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
    _rbac.initialize();
    _runbooks.initialize();
    _kanban.initialize();
    _orchestration.addListener(_refresh);
    _rbac.addListener(_refresh);
    _runbooks.addListener(_refresh);
    _kanban.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _orchestration.removeListener(_refresh);
    _rbac.removeListener(_refresh);
    _runbooks.removeListener(_refresh);
    _kanban.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C1226),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.dashboard_customize, color: Color(0xFFFFD740), size: 20),
            SizedBox(width: 8),
            Text(
              'WAR ROOM PANELS',
              style: TextStyle(
                color: Color(0xFFFFD740),
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: const Color(0xFFFFD740),
          labelColor: const Color(0xFFFFD740),
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          tabs: const [
            Tab(text: 'RUNBOOKS'),
            Tab(text: 'ACTIONS'),
            Tab(text: 'INCIDENTS'),
            Tab(text: 'AUDIT'),
            Tab(text: 'APPROVALS'),
            Tab(text: 'DRILL'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildRunbooksTab(),
          _buildActionsTab(),
          _buildIncidentsTab(),
          _buildAuditTab(),
          _buildApprovalsTab(),
          _buildDrillTab(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // RUNBOOKS TAB
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildRunbooksTab() {
    final rbs = _runbooks.runbooks;
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: rbs.length,
      itemBuilder: (ctx, i) {
        final rb = rbs[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0C1226),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFE040FB).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.menu_book,
                    color: Color(0xFFE040FB),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rb.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _runbooks.executeRunbook(
                      runbookId: rb.id,
                      executedBy: _rbac.currentUser?.displayName ?? 'operator',
                    ),
                    icon: const Icon(Icons.play_arrow, size: 14),
                    label: const Text(
                      'Execute',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFFE040FB,
                      ).withValues(alpha: 0.2),
                      foregroundColor: const Color(0xFFE040FB),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                  ),
                ],
              ),
              if (rb.triggerConditions.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Trigger: ${rb.triggerConditions}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
              if (rb.impact.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Impact: ${rb.impact}',
                  style: const TextStyle(color: Colors.orange, fontSize: 11),
                ),
              ],
              const SizedBox(height: 8),
              // Steps
              ...rb.steps.map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFE040FB,
                          ).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${step.order}',
                          style: const TextStyle(
                            color: Color(0xFFE040FB),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.instruction,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                            if (step.command != null)
                              Text(
                                step.command!,
                                style: const TextStyle(
                                  color: Colors.cyan,
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            if (step.requiresApproval)
                              const Text(
                                '⚠ Requires approval',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 9,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (rb.postmortem.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Postmortem: ${rb.postmortem}',
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ACTIONS TAB
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildActionsTab() {
    final actions = _orchestration.recentActions;
    if (actions.isEmpty) {
      return const Center(
        child: Text(
          'No actions executed yet.',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: actions.length,
      itemBuilder: (ctx, i) {
        final a = actions[i];
        final color = _actionColor(a.status);
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0C1226),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_actionIcon(a.type), color: color, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    a.type.name.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      a.status.name.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${a.startedAt.hour.toString().padLeft(2, '0')}:${a.startedAt.minute.toString().padLeft(2, '0')}:${a.startedAt.second.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.white24,
                      fontSize: 9,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${a.service} — by ${a.triggeredBy}',
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
              if (a.duration != null)
                Text(
                  'Duration: ${a.duration!.inMilliseconds}ms',
                  style: const TextStyle(color: Colors.white24, fontSize: 9),
                ),
              if (a.logs.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF080C18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  constraints: const BoxConstraints(maxHeight: 80),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: a.logs
                          .take(5)
                          .map(
                            (l) => Text(
                              l,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 9,
                                fontFamily: 'monospace',
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // INCIDENTS TAB
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildIncidentsTab() {
    // Simulated incidents from orchestration state
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('ACTIVE INCIDENTS'),
          const SizedBox(height: 8),
          if (_orchestration.ppvPaused)
            _incidentCard(
              'PPV Gateway Paused',
              'Manual pause triggered from War Room',
              IncidentSeverity.high,
              IncidentStatus.mitigating,
            ),
          if (!_orchestration.ppvPaused)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 48,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No active incidents',
                      style: TextStyle(color: Colors.green, fontSize: 14),
                    ),
                    Text(
                      'All systems operational',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          _sectionTitle('QUICK ACTIONS'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _actionChip(
                'Create Incident',
                Icons.add_alert,
                Colors.red,
                () {},
              ),
              _actionChip('Export Logs', Icons.download, Colors.cyan, () {}),
              _actionChip('Schedule RCA', Icons.event, Colors.orange, () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _incidentCard(
    String title,
    String desc,
    IncidentSeverity sev,
    IncidentStatus status,
  ) {
    final color = sev == IncidentSeverity.critical
        ? Colors.red
        : sev == IncidentSeverity.high
        ? Colors.orange
        : Colors.yellow;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                Text(
                  'Status: ${status.name.toUpperCase()}',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AUDIT TAB
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildAuditTab() {
    final entries = _kanban.globalAudit;
    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'No audit entries yet.',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: const Color(0xFF0A1020),
          child: Row(
            children: [
              Text(
                '${entries.length} entries',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {}, // Export stub
                icon: const Icon(Icons.download, size: 14, color: Colors.cyan),
                label: const Text(
                  'Export CSV',
                  style: TextStyle(color: Colors.cyan, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: entries.length,
            itemBuilder: (ctx, i) {
              final e = entries[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 3),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C1226),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Text(
                      '${e.timestamp.hour.toString().padLeft(2, '0')}:${e.timestamp.minute.toString().padLeft(2, '0')}:${e.timestamp.second.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: _auditColor(e.action).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        e.action.toUpperCase(),
                        style: TextStyle(
                          color: _auditColor(e.action),
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.details,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // APPROVALS TAB
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildApprovalsTab() {
    final pending = _rbac.pendingApprovals;
    final all = _rbac.allApprovals;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('PENDING APPROVALS (${pending.length})'),
          const SizedBox(height: 8),
          if (pending.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No pending approvals',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          ...pending.map(_approvalCard),
          const SizedBox(height: 16),
          _sectionTitle('APPROVAL HISTORY (${all.length})'),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: all
                  .where((a) => a.status != 'pending')
                  .take(20)
                  .map(_approvalCard)
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _approvalCard(ApprovalRequest req) {
    final color = req.status == 'pending'
        ? Colors.orange
        : req.status == 'approved'
        ? Colors.green
        : Colors.red;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1226),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            req.status == 'pending'
                ? Icons.hourglass_empty
                : req.status == 'approved'
                ? Icons.check_circle
                : Icons.cancel,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Action: ${req.actionId}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'By: ${req.requestedBy} — ${req.reason}',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
                Text(
                  req.status.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (req.status == 'pending' && _rbac.canDeploy()) ...[
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green, size: 18),
              onPressed: () => _rbac.approveRequest(
                req.id,
                _rbac.currentUser?.uid ?? 'admin',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red, size: 18),
              onPressed: () =>
                  _rbac.rejectRequest(req.id, 'Rejected by operator'),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Drill Tab ──────────────────────────────────────────────────────────

  Widget _buildDrillTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('WAR ROOM READINESS DRILL'),
          const SizedBox(height: 12),
          Row(
            children: [
              _actionChip(
                _orchestration.drillRunning ? 'DRILL RUNNING...' : 'RUN DRILL',
                Icons.local_fire_department,
                _orchestration.drillRunning
                    ? const Color(0xFFFFD740)
                    : const Color(0xFF00E676),
                _orchestration.drillRunning
                    ? () {}
                    : _orchestration.runWarRoomDrill,
              ),
              const SizedBox(width: 12),
              if (_orchestration.lastDrillAt != null)
                Text(
                  'Last: ${_orchestration.lastDrillAt!.toIso8601String().substring(0, 19)} — ${_orchestration.lastDrillPassed ? "PASSED" : "FAILED"}',
                  style: TextStyle(
                    color: _orchestration.lastDrillPassed
                        ? Colors.green
                        : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle(
            'DRILL REPORT (${_orchestration.drillReport.length} entries)',
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF080E1C),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1A2744)),
              ),
              child: _orchestration.drillReport.isEmpty
                  ? const Center(
                      child: Text(
                        'No drill run yet. Hit RUN DRILL to begin.',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _orchestration.drillReport.length,
                      itemBuilder: (context, i) {
                        final line = _orchestration.drillReport[i];
                        final isPass = line.contains('PASS');
                        final isFail = line.contains('FAIL');
                        final isStep = line.contains('STEP');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            line,
                            style: TextStyle(
                              color: isFail
                                  ? Colors.red
                                  : isPass
                                  ? Colors.green
                                  : isStep
                                  ? const Color(0xFFFFD740)
                                  : Colors.white54,
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );
  }

  Widget _actionChip(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _actionColor(ActionStatus status) {
    switch (status) {
      case ActionStatus.queued:
        return Colors.blueGrey;
      case ActionStatus.running:
        return const Color(0xFFFFD740);
      case ActionStatus.success:
        return Colors.green;
      case ActionStatus.failed:
        return Colors.red;
      case ActionStatus.rolledBack:
        return Colors.orange;
      case ActionStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _actionIcon(ActionType type) {
    switch (type) {
      case ActionType.deploy:
        return Icons.rocket_launch;
      case ActionType.rollback:
        return Icons.undo;
      case ActionType.smokeTest:
        return Icons.science;
      case ActionType.pausePpv:
        return Icons.pause_circle;
      case ActionType.resumePpv:
        return Icons.play_circle;
      case ActionType.cachePurge:
        return Icons.cleaning_services;
      case ActionType.healthSweep:
        return Icons.health_and_safety;
      case ActionType.scaleService:
        return Icons.scale;
    }
  }

  Color _auditColor(String action) {
    switch (action) {
      case 'created':
        return Colors.green;
      case 'moved':
        return Colors.cyan;
      case 'updated':
        return const Color(0xFFFFD740);
      case 'deleted':
        return Colors.red;
      case 'seeded':
        return const Color(0xFFE040FB);
      default:
        return Colors.white54;
    }
  }
}
