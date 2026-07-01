import 'package:flutter/material.dart';
import '../../../shared/models/kanban_model.dart';
import '../../../shared/services/war_room_kanban_service.dart';
import '../../../shared/services/war_room_orchestration_service.dart';
import '../../../shared/services/war_room_rbac_service.dart';
import '../../../shared/services/runbook_engine_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// WAR ROOM KANBAN SCREEN — Production-grade Admin Panel
/// Layout: Top status bar → Center Kanban board → Bottom live console
/// ═══════════════════════════════════════════════════════════════════════════
class WarRoomKanbanScreen extends StatefulWidget {
  const WarRoomKanbanScreen({super.key});

  @override
  State<WarRoomKanbanScreen> createState() => _WarRoomKanbanScreenState();
}

class _WarRoomKanbanScreenState extends State<WarRoomKanbanScreen> {
  final _kanban = WarRoomKanbanService();
  final _orchestration = WarRoomOrchestrationService();
  final _rbac = WarRoomRbacService();
  final _runbooks = RunbookEngineService();
  KanbanCard? _selectedCard;
  bool _showConsole = true;

  @override
  void initState() {
    super.initState();
    _kanban.initialize();
    _orchestration;
    _rbac.initialize();
    _runbooks.initialize();
    _kanban.addListener(_onUpdate);
    _orchestration.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _kanban.removeListener(_onUpdate);
    _orchestration.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A14),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Row(
              children: [
                // Center: Kanban Board
                Expanded(flex: 3, child: _buildKanbanBoard()),
                // Right: Context Panel
                if (_selectedCard != null)
                  SizedBox(width: 340, child: _buildContextPanel()),
              ],
            ),
          ),
          if (_showConsole) _buildLiveConsole(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TOP STATUS BAR
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildTopBar() {
    final role = _rbac.currentUser?.role;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0C1226),
        border: Border(bottom: BorderSide(color: Color(0xFF1A2340))),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield, color: Color(0xFFFFD740), size: 22),
          const SizedBox(width: 8),
          const Text(
            'WAR ROOM',
            style: TextStyle(
              color: Color(0xFFFFD740),
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 16),
          _statusChip(
            'CLUSTER',
            _orchestration.ppvPaused ? 'DEGRADED' : 'GREEN',
            _orchestration.ppvPaused ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 8),
          _statusChip(
            'ACTIONS',
            '${_orchestration.activeActions}',
            Colors.cyan,
          ),
          const SizedBox(width: 8),
          _statusChip(
            'SUCCESS',
            '${(_orchestration.successRate * 100).toInt()}%',
            Colors.green,
          ),
          const SizedBox(width: 8),
          _statusChip(
            'CARDS',
            '${_kanban.cards.length}',
            const Color(0xFFE040FB),
          ),
          const Spacer(),
          // Role indicator
          if (role != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFFFD740).withValues(alpha: 0.4),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _roleLabel(role),
                style: const TextStyle(
                  color: Color(0xFFFFD740),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 12),
          // Quick actions
          _quickActionBtn(
            Icons.rocket_launch,
            'Deploy',
            const Color(0xFF00E676),
            _rbac.canDeploy() ? _showDeployDialog : null,
          ),
          _quickActionBtn(
            Icons.undo,
            'Rollback',
            Colors.orange,
            _rbac.canRollback() ? _triggerRollback : null,
          ),
          _quickActionBtn(
            Icons.pause_circle,
            _orchestration.ppvPaused ? 'Resume' : 'Pause PPV',
            _orchestration.ppvPaused ? Colors.green : Colors.red,
            _rbac.canPausePpv() ? _togglePpv : null,
          ),
          _quickActionBtn(
            Icons.health_and_safety,
            'Health',
            Colors.cyan,
            _triggerHealthSweep,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              _showConsole ? Icons.terminal : Icons.terminal,
              color: Colors.white54,
              size: 20,
            ),
            onPressed: () => setState(() => _showConsole = !_showConsole),
            tooltip: 'Toggle Console',
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionBtn(
    IconData icon,
    String tip,
    Color color,
    VoidCallback? onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: tip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: onTap != null
                  ? color.withValues(alpha: 0.15)
                  : Colors.white10,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: onTap != null ? color : Colors.white24,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // KANBAN BOARD — 6 columns
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildKanbanBoard() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: KanbanColumn.values
            .map((col) => Expanded(child: _buildColumn(col)))
            .toList(),
      ),
    );
  }

  Widget _buildColumn(KanbanColumn col) {
    final cards = _kanban.cardsForColumn(col);
    final color = _columnColor(col);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  kanbanColumnLabel(col),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${cards.length}',
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Cards
          Expanded(
            child: DragTarget<KanbanCard>(
              onAcceptWithDetails: (details) {
                _kanban.moveCard(details.data.id, col);
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  color: candidateData.isNotEmpty
                      ? color.withValues(alpha: 0.05)
                      : Colors.transparent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(4),
                    itemCount: cards.length,
                    itemBuilder: (ctx, i) => _buildCardWidget(cards[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardWidget(KanbanCard card) {
    final pColor = _priorityColor(card.priority);
    final isSelected = _selectedCard?.id == card.id;
    return Draggable<KanbanCard>(
      data: card,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 200, child: _cardContent(card, pColor, false)),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _cardContent(card, pColor, isSelected),
      ),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCard = card),
        child: _cardContent(card, pColor, isSelected),
      ),
    );
  }

  Widget _cardContent(KanbanCard card, Color pColor, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF141C35) : const Color(0xFF0C1226),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFFFD740)
              : pColor.withValues(alpha: 0.3),
          width: isSelected ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority + Deploy status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: pColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  card.priority == KanbanPriority.p0Critical
                      ? 'P0'
                      : card.priority == KanbanPriority.p1High
                      ? 'P1'
                      : card.priority == KanbanPriority.p2Medium
                      ? 'P2'
                      : 'P3',
                  style: TextStyle(
                    color: pColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              if (card.deployStatus != DeployStatus.notStarted)
                Icon(
                  card.deployStatus == DeployStatus.deployed
                      ? Icons.check_circle
                      : card.deployStatus == DeployStatus.failed
                      ? Icons.error
                      : Icons.pending,
                  color: card.deployStatus == DeployStatus.deployed
                      ? Colors.green
                      : card.deployStatus == DeployStatus.failed
                      ? Colors.red
                      : Colors.orange,
                  size: 12,
                ),
            ],
          ),
          const SizedBox(height: 4),
          // Title
          Text(
            card.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          // Owner + ETA
          Row(
            children: [
              const Icon(Icons.person, size: 10, color: Colors.white38),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  card.owner,
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (card.eta != null)
                Text(
                  card.eta!,
                  style: const TextStyle(color: Colors.white24, fontSize: 9),
                ),
            ],
          ),
          // Service links
          if (card.linkedServices.isNotEmpty) ...[
            const SizedBox(height: 3),
            Wrap(
              spacing: 3,
              children: card.linkedServices.take(2).map((s) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    s,
                    style: const TextStyle(color: Colors.cyan, fontSize: 7),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CONTEXT PANEL (right side — card detail + actions)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildContextPanel() {
    final card = _selectedCard!;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0C1226),
        border: Border(left: BorderSide(color: Color(0xFF1A2340))),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1A2340))),
            ),
            child: Row(
              children: [
                const Icon(Icons.article, color: Color(0xFFFFD740), size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'CARD DETAIL',
                    style: TextStyle(
                      color: Color(0xFFFFD740),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white54,
                    size: 16,
                  ),
                  onPressed: () => setState(() => _selectedCard = null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _detailRow(
                    'Priority',
                    priorityLabel(card.priority),
                    _priorityColor(card.priority),
                  ),
                  _detailRow(
                    'Column',
                    kanbanColumnLabel(card.column),
                    _columnColor(card.column),
                  ),
                  _detailRow('Owner', card.owner, Colors.white70),
                  if (card.eta != null)
                    _detailRow('ETA', card.eta!, Colors.white54),
                  _detailRow(
                    'Deploy',
                    card.deployStatus.name.toUpperCase(),
                    card.deployStatus == DeployStatus.deployed
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  // Linked services
                  if (card.linkedServices.isNotEmpty) ...[
                    const Text(
                      'LINKED SERVICES',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: card.linkedServices.map((s) {
                        return Chip(
                          label: Text(s, style: const TextStyle(fontSize: 9)),
                          backgroundColor: Colors.cyan.withValues(alpha: 0.15),
                          labelStyle: const TextStyle(color: Colors.cyan),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Runbook
                  if (card.runbookId != null) ...[
                    const Text(
                      'RUNBOOK',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _runbookChip(card.runbookId!),
                    const SizedBox(height: 12),
                  ],
                  // Card actions
                  const Text(
                    'ACTIONS',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _cardActionBtn(
                        'Move →',
                        Icons.arrow_forward,
                        Colors.cyan,
                        () => _moveCardForward(card),
                      ),
                      _cardActionBtn(
                        'Smoke Test',
                        Icons.science,
                        Colors.green,
                        () => _runSmokeForCard(card),
                      ),
                      if (card.column == KanbanColumn.verify)
                        _cardActionBtn(
                          'Mark Done',
                          Icons.check,
                          const Color(0xFF00E676),
                          () => _kanban.moveCard(card.id, KanbanColumn.done),
                        ),
                      _cardActionBtn(
                        'Block',
                        Icons.block,
                        Colors.red,
                        () => _kanban.moveCard(card.id, KanbanColumn.blocked),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Audit trail
                  const Text(
                    'AUDIT TRAIL',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...card.audit
                      .take(10)
                      .map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${a.timestamp.hour.toString().padLeft(2, '0')}:${a.timestamp.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: Colors.white24,
                                  fontSize: 9,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  a.details,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _runbookChip(String runbookId) {
    final rb = _runbooks.getRunbook(runbookId);
    return InkWell(
      onTap: rb != null ? () => _executeRunbook(rb) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE040FB).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: const Color(0xFFE040FB).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book, color: Color(0xFFE040FB), size: 12),
            const SizedBox(width: 4),
            Text(
              rb?.title ?? runbookId,
              style: const TextStyle(color: Color(0xFFE040FB), fontSize: 10),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.play_arrow, color: Color(0xFFE040FB), size: 12),
          ],
        ),
      ),
    );
  }

  Widget _cardActionBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LIVE CONSOLE (bottom)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildLiveConsole() {
    final logs = _orchestration.liveConsole;
    return Container(
      height: 140,
      decoration: const BoxDecoration(
        color: Color(0xFF080C18),
        border: Border(top: BorderSide(color: Color(0xFF1A2340))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: const Color(0xFF0A1020),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE CONSOLE',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _orchestration.clearConsole,
                  child: const Text(
                    'CLEAR',
                    style: TextStyle(color: Colors.white24, fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: logs.length,
              itemBuilder: (ctx, i) {
                return Text(
                  logs[i],
                  style: TextStyle(
                    color:
                        logs[i].contains('ERROR') || logs[i].contains('failed')
                        ? Colors.red
                        : logs[i].contains('PASS') ||
                              logs[i].contains('complete') ||
                              logs[i].contains('success')
                        ? Colors.green
                        : Colors.white54,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════

  void _showDeployDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0C1226),
        title: const Text(
          'One-Click Deploy',
          style: TextStyle(color: Color(0xFFFFD740), fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Deploy war-room to staging with latest image?',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (_rbac.requiresSecondApprover())
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Requires second approval',
                      style: TextStyle(color: Colors.orange, fontSize: 11),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _orchestration.triggerDeploy(
                service: 'war-room',
                imageTag: 'latest',
                triggeredBy: _rbac.currentUser?.displayName ?? 'operator',
              );
            },
            child: const Text('Deploy', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _triggerRollback() {
    _orchestration.triggerRollback(
      service: 'war-room',
      triggeredBy: _rbac.currentUser?.displayName ?? 'operator',
    );
  }

  void _togglePpv() {
    if (_orchestration.ppvPaused) {
      _orchestration.triggerResumePpv(
        triggeredBy: _rbac.currentUser?.displayName ?? 'operator',
      );
    } else {
      _orchestration.triggerPausePpv(
        reason: 'Manual pause from War Room',
        triggeredBy: _rbac.currentUser?.displayName ?? 'operator',
      );
    }
  }

  void _triggerHealthSweep() {
    _orchestration.triggerHealthSweep(
      triggeredBy: _rbac.currentUser?.displayName ?? 'operator',
    );
  }

  void _moveCardForward(KanbanCard card) {
    final cols = KanbanColumn.values;
    final nextIdx = cols.indexOf(card.column) + 1;
    if (nextIdx < cols.length) {
      _kanban.moveCard(card.id, cols[nextIdx]);
      setState(() => _selectedCard = null);
    }
  }

  void _runSmokeForCard(KanbanCard card) {
    _orchestration.triggerSmokeTest(
      service: card.linkedServices.isNotEmpty
          ? card.linkedServices.first
          : 'war-room',
      triggeredBy: _rbac.currentUser?.displayName ?? 'operator',
      linkedCardId: card.id,
    );
  }

  void _executeRunbook(Runbook rb) {
    _runbooks.executeRunbook(
      runbookId: rb.id,
      executedBy: _rbac.currentUser?.displayName ?? 'operator',
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  Color _columnColor(KanbanColumn col) {
    switch (col) {
      case KanbanColumn.backlog:
        return Colors.blueGrey;
      case KanbanColumn.ready:
        return Colors.cyan;
      case KanbanColumn.inProgress:
        return const Color(0xFFFFD740);
      case KanbanColumn.verify:
        return const Color(0xFFE040FB);
      case KanbanColumn.blocked:
        return Colors.red;
      case KanbanColumn.done:
        return const Color(0xFF00E676);
    }
  }

  Color _priorityColor(KanbanPriority p) {
    switch (p) {
      case KanbanPriority.p0Critical:
        return Colors.red;
      case KanbanPriority.p1High:
        return Colors.orange;
      case KanbanPriority.p2Medium:
        return Colors.cyan;
      case KanbanPriority.p3Low:
        return Colors.blueGrey;
    }
  }

  String _roleLabel(WarRoomRole role) {
    switch (role) {
      case WarRoomRole.founderAdmin:
        return 'FOUNDER ADMIN';
      case WarRoomRole.opsLead:
        return 'OPS LEAD';
      case WarRoomRole.safetyOfficer:
        return 'SAFETY OFFICER';
      case WarRoomRole.promoterManager:
        return 'PROMOTER MGR';
      case WarRoomRole.readOnlyAuditor:
        return 'READ-ONLY';
    }
  }
}
