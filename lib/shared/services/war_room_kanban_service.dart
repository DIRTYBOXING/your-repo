import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/kanban_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// WAR ROOM KANBAN SERVICE — Card CRUD, column management, seeded board
/// ═══════════════════════════════════════════════════════════════════════════

class WarRoomKanbanService with ChangeNotifier {
  static final WarRoomKanbanService _instance = WarRoomKanbanService._();
  factory WarRoomKanbanService() => _instance;
  WarRoomKanbanService._();

  // ─── State ─────────────────────────────────────────────────────────────
  final List<KanbanCard> _cards = [];
  final List<KanbanAuditEntry> _globalAudit = [];
  bool _initialized = false;
  String _filterOwner = '';
  KanbanPriority? _filterPriority;

  // ─── Getters ───────────────────────────────────────────────────────────
  List<KanbanCard> get cards => List.unmodifiable(_cards);
  List<KanbanAuditEntry> get globalAudit => List.unmodifiable(_globalAudit);
  bool get initialized => _initialized;

  List<KanbanCard> cardsForColumn(KanbanColumn col) {
    var filtered = _cards.where((c) => c.column == col);
    if (_filterOwner.isNotEmpty) {
      filtered = filtered.where(
        (c) => c.owner.toLowerCase().contains(_filterOwner.toLowerCase()),
      );
    }
    if (_filterPriority != null) {
      filtered = filtered.where((c) => c.priority == _filterPriority);
    }
    return filtered.toList()
      ..sort((a, b) => a.priority.index.compareTo(b.priority.index));
  }

  int columnCount(KanbanColumn col) => cardsForColumn(col).length;

  void setOwnerFilter(String owner) {
    _filterOwner = owner;
    notifyListeners();
  }

  void setPriorityFilter(KanbanPriority? p) {
    _filterPriority = p;
    notifyListeners();
  }

  // ─── Initialize with seed data ─────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;
    _seedCards();
    _initialized = true;
    notifyListeners();
  }

  // ─── CRUD ──────────────────────────────────────────────────────────────

  KanbanCard createCard({
    required String title,
    String description = '',
    KanbanPriority priority = KanbanPriority.p2Medium,
    String owner = 'Unassigned',
    String? eta,
    List<String> linkedServices = const [],
    String? runbookId,
  }) {
    final card = KanbanCard(
      id: 'card_${DateTime.now().millisecondsSinceEpoch}_${_cards.length}',
      title: title,
      description: description,
      priority: priority,
      owner: owner,
      eta: eta,
      linkedServices: linkedServices,
      runbookId: runbookId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      audit: [
        KanbanAuditEntry(
          timestamp: DateTime.now(),
          userId: 'system',
          action: 'created',
          details: 'Card created: $title',
        ),
      ],
    );
    _cards.add(card);
    _logGlobal('created', 'Card "$title" created by $owner');
    notifyListeners();
    return card;
  }

  void updateCard(String cardId, KanbanCard Function(KanbanCard) updater) {
    final idx = _cards.indexWhere((c) => c.id == cardId);
    if (idx == -1) return;
    _cards[idx] = updater(_cards[idx]);
    _logGlobal('updated', 'Card "${_cards[idx].title}" updated');
    notifyListeners();
  }

  void moveCard(String cardId, KanbanColumn toColumn) {
    final idx = _cards.indexWhere((c) => c.id == cardId);
    if (idx == -1) return;
    final old = _cards[idx];
    _cards[idx] = old.copyWith(
      column: toColumn,
      audit: [
        ...old.audit,
        KanbanAuditEntry(
          timestamp: DateTime.now(),
          userId: 'operator',
          action: 'moved',
          details:
              '${kanbanColumnLabel(old.column)} → ${kanbanColumnLabel(toColumn)}',
        ),
      ],
    );
    _logGlobal('moved', '"${old.title}" → ${kanbanColumnLabel(toColumn)}');
    notifyListeners();
  }

  void deleteCard(String cardId) {
    final card = _cards.firstWhere(
      (c) => c.id == cardId,
      orElse: () => throw StateError('Card not found'),
    );
    _cards.removeWhere((c) => c.id == cardId);
    _logGlobal('deleted', 'Card "${card.title}" deleted');
    notifyListeners();
  }

  void assignCard(String cardId, String owner) {
    updateCard(cardId, (c) => c.copyWith(owner: owner));
  }

  void setPriority(String cardId, KanbanPriority p) {
    updateCard(cardId, (c) => c.copyWith(priority: p));
  }

  void setDeployStatus(String cardId, DeployStatus status) {
    updateCard(cardId, (c) => c.copyWith(deployStatus: status));
  }

  void linkPR(String cardId, String prUrl) {
    updateCard(cardId, (c) => c.copyWith(linkedPR: prUrl));
  }

  void attachRunbook(String cardId, String runbookId) {
    updateCard(cardId, (c) => c.copyWith(runbookId: runbookId));
  }

  // ─── Audit ─────────────────────────────────────────────────────────────
  void _logGlobal(String action, String details) {
    _globalAudit.insert(
      0,
      KanbanAuditEntry(
        timestamp: DateTime.now(),
        userId: 'operator',
        action: action,
        details: details,
      ),
    );
    if (_globalAudit.length > 500) {
      _globalAudit.removeRange(500, _globalAudit.length);
    }
  }

  // ─── Seed 20 priority cards ────────────────────────────────────────────
  void _seedCards() {
    final now = DateTime.now();
    final seeds = <Map<String, dynamic>>[
      {
        'title': 'Wire AI Media Director to Creator Studio',
        'owner': 'Frontend',
        'priority': KanbanPriority.p0Critical,
        'eta': '3d',
        'services': ['AiMediaDirectorService'],
        'col': KanbanColumn.inProgress,
      },
      {
        'title': 'Implement one-click deploy workflow',
        'owner': 'DevOps',
        'priority': KanbanPriority.p0Critical,
        'eta': '4d',
        'services': ['WarRoomOrchestrationService'],
        'col': KanbanColumn.ready,
      },
      {
        'title': 'Build Event Builder modal',
        'owner': 'Product',
        'priority': KanbanPriority.p1High,
        'eta': '5d',
        'services': ['AiEventDirectorService'],
        'col': KanbanColumn.backlog,
      },
      {
        'title': 'Integrate Real-Time Scoring overlay',
        'owner': 'LiveOps',
        'priority': KanbanPriority.p0Critical,
        'eta': '3d',
        'services': ['RealtimeScoringService'],
        'col': KanbanColumn.inProgress,
      },
      {
        'title': 'Fighter Health Passport gating',
        'owner': 'Safety',
        'priority': KanbanPriority.p0Critical,
        'eta': '2d',
        'services': ['FighterHealthPassportService'],
        'col': KanbanColumn.verify,
      },
      {
        'title': 'Stripe payout admin panel',
        'owner': 'Finance',
        'priority': KanbanPriority.p1High,
        'eta': '3d',
        'services': ['StripePaymentService'],
        'col': KanbanColumn.ready,
      },
      {
        'title': 'Safety alert integration',
        'owner': 'Safety',
        'priority': KanbanPriority.p0Critical,
        'eta': '2d',
        'services': ['FighterSafetySystemService'],
        'col': KanbanColumn.inProgress,
      },
      {
        'title': 'Wire Talent Scouting to Discovery Page',
        'owner': 'ML',
        'priority': KanbanPriority.p1High,
        'eta': '3d',
        'services': ['TalentScoutingService'],
        'col': KanbanColumn.backlog,
      },
      {
        'title': 'Fight Simulation preview modal',
        'owner': 'Frontend',
        'priority': KanbanPriority.p2Medium,
        'eta': '2d',
        'services': ['FightSimulationEngine'],
        'col': KanbanColumn.done,
      },
      {
        'title': 'Monetization Wallet integration',
        'owner': 'Backend',
        'priority': KanbanPriority.p1High,
        'eta': '4d',
        'services': ['RevenueEngineService'],
        'col': KanbanColumn.ready,
      },
      {
        'title': 'Poster generator AI hook',
        'owner': 'AI',
        'priority': KanbanPriority.p2Medium,
        'eta': '2d',
        'services': ['AiMediaDirectorService'],
        'col': KanbanColumn.backlog,
      },
      {
        'title': 'Admin Console core layout',
        'owner': 'Product',
        'priority': KanbanPriority.p1High,
        'eta': '3d',
        'services': ['PlatformControlTowerService'],
        'col': KanbanColumn.done,
      },
      {
        'title': 'Runbook engine — store, render, attach',
        'owner': 'Ops',
        'priority': KanbanPriority.p0Critical,
        'eta': '2d',
        'services': ['RunbookEngineService'],
        'col': KanbanColumn.inProgress,
      },
      {
        'title': 'One-click rollback workflow',
        'owner': 'DevOps',
        'priority': KanbanPriority.p0Critical,
        'eta': '3d',
        'services': ['WarRoomOrchestrationService'],
        'col': KanbanColumn.ready,
      },
      {
        'title': 'Embed live logs tailing',
        'owner': 'SRE',
        'priority': KanbanPriority.p2Medium,
        'eta': '2d',
        'services': [],
        'col': KanbanColumn.backlog,
      },
      {
        'title': 'Link PRs to Kanban cards',
        'owner': 'DevOps',
        'priority': KanbanPriority.p2Medium,
        'eta': '2d',
        'services': ['WarRoomKanbanService'],
        'col': KanbanColumn.backlog,
      },
      {
        'title': 'Approval flow — 2FA + second approver',
        'owner': 'Security',
        'priority': KanbanPriority.p1High,
        'eta': '2d',
        'services': ['WarRoomRbacService'],
        'col': KanbanColumn.ready,
      },
      {
        'title': 'Presale checkout test flow',
        'owner': 'Commerce',
        'priority': KanbanPriority.p1High,
        'eta': '3d',
        'services': ['StripePaymentService'],
        'col': KanbanColumn.backlog,
      },
      {
        'title': 'Event presale PPV funnel smoke test',
        'owner': 'Growth',
        'priority': KanbanPriority.p2Medium,
        'eta': '2d',
        'services': ['PpvCommandService'],
        'col': KanbanColumn.backlog,
      },
      {
        'title': 'War Room drill script — simulate incident',
        'owner': 'Ops',
        'priority': KanbanPriority.p1High,
        'eta': '1d',
        'services': ['WarRoomOrchestrationService', 'RunbookEngineService'],
        'col': KanbanColumn.backlog,
      },
    ];

    for (var i = 0; i < seeds.length; i++) {
      final s = seeds[i];
      _cards.add(
        KanbanCard(
          id: 'seed_${i + 1}',
          title: s['title'] as String,
          column: s['col'] as KanbanColumn,
          priority: s['priority'] as KanbanPriority,
          owner: s['owner'] as String,
          eta: s['eta'] as String?,
          linkedServices: List<String>.from(s['services'] as List),
          createdAt: now.subtract(Duration(hours: seeds.length - i)),
          updatedAt: now,
          audit: [
            KanbanAuditEntry(
              timestamp: now,
              userId: 'system',
              action: 'seeded',
              details: 'Activation roadmap seed card',
            ),
          ],
        ),
      );
    }
  }
}
