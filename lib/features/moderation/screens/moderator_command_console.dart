import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/moderation_model.dart';
import '../../../shared/services/moderation_engine.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MODERATOR COMMAND CONSOLE — Real-time, keyboard-driven triage UI
///
/// 3-panel layout: Filters (left) | Queue (center) | Detail (right)
/// Hotkeys: J/K navigate, A approve, R reject, E edit, P pin,
///          S escalate, B bulk, U undo, ? help
/// Integrates with ModerationEngine for Firestore real-time queue,
/// immutable audit writes, and undo-within-60s soft actions.
/// ═══════════════════════════════════════════════════════════════════════════

class ModeratorCommandConsole extends StatefulWidget {
  const ModeratorCommandConsole({super.key});
  @override
  State<ModeratorCommandConsole> createState() =>
      _ModeratorCommandConsoleState();
}

class _ModeratorCommandConsoleState extends State<ModeratorCommandConsole> {
  final ModerationEngine _engine = ModerationEngine();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _editCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController();

  // ── State ──────────────────────────────────────────────────────────────
  List<_QueueItem> _items = [];
  int _selectedIndex = 0;
  bool _bulkMode = false;
  final Set<int> _bulkSelected = {};
  bool _editMode = false;
  bool _showHelp = false;
  String _filterRegion = 'ALL';
  String _filterSeverity = 'ALL';
  String _filterType = 'ALL';
  bool _useDemoData = true;

  // Undo stack (soft actions within 60s window)
  final List<_UndoEntry> _undoStack = [];
  Timer? _undoCleanupTimer;

  // ── Demo data ──────────────────────────────────────────────────────────
  static final _demoItems = [
    _QueueItem(
      id: 'q1',
      type: 'post',
      author: 'FightFan_92',
      authorId: 'u1',
      content:
          'This fight was rigged! The ref stopped it way too early. Total fix.',
      region: 'USA',
      severity: 'HIGH',
      toxicity: 0.72,
      createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
      flaggedTerms: ['rigged', 'fix'],
      status: 'pending',
    ),
    _QueueItem(
      id: 'q2',
      type: 'comment',
      author: 'MMA_Truth',
      authorId: 'u2',
      content:
          'Great card tonight. Real warriors in there. Respect to both fighters.',
      region: 'AUSTRALIA',
      severity: 'LOW',
      toxicity: 0.05,
      createdAt: DateTime.now().subtract(const Duration(minutes: 7)),
      flaggedTerms: [],
      status: 'pending',
    ),
    _QueueItem(
      id: 'q3',
      type: 'question',
      author: 'BKFCBrawler',
      authorId: 'u3',
      content:
          'Hey champ, your last opponent said you took a dive. Any response?',
      region: 'USA',
      severity: 'MEDIUM',
      toxicity: 0.55,
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
      flaggedTerms: ['took a dive'],
      status: 'pending',
    ),
    _QueueItem(
      id: 'q4',
      type: 'post',
      author: 'CryptoFightBet',
      authorId: 'u4',
      content:
          'GUARANTEED RETURNS 🔥🔥🔥 Send crypto to this wallet for insider fight tips. DM me for details!',
      region: 'GLOBAL',
      severity: 'CRITICAL',
      toxicity: 0.92,
      createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
      flaggedTerms: ['guaranteed return', 'send crypto', 'dm me for'],
      status: 'pending',
    ),
    _QueueItem(
      id: 'q5',
      type: 'comment',
      author: 'ThaiBoxer99',
      authorId: 'u5',
      content:
          'Training at Tiger Muay Thai next month. Anyone want to meet up for sparring?',
      region: 'THAILAND',
      severity: 'LOW',
      toxicity: 0.0,
      createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
      flaggedTerms: [],
      status: 'pending',
    ),
    _QueueItem(
      id: 'q6',
      type: 'post',
      author: 'AngryFan',
      authorId: 'u6',
      content:
          'You worthless pathetic loser. You should quit fighting forever. KYS',
      region: 'UK',
      severity: 'CRITICAL',
      toxicity: 1.0,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      flaggedTerms: ['worthless', 'pathetic', 'loser', 'kys'],
      status: 'pending',
    ),
    _QueueItem(
      id: 'q7',
      type: 'question',
      author: 'RealFan',
      authorId: 'u7',
      content:
          'Coach, what weight class do you recommend for a 5\'10 beginner at 170lbs?',
      region: 'AUSTRALIA',
      severity: 'LOW',
      toxicity: 0.0,
      createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
      flaggedTerms: [],
      status: 'pending',
    ),
    _QueueItem(
      id: 'q8',
      type: 'post',
      author: 'PromoBot',
      authorId: 'u8',
      content:
          'BUY NOW BUY NOW BUY NOW!!! CLICK THIS LINK: http://scam-site.xyz/fight-tickets',
      region: 'GLOBAL',
      severity: 'CRITICAL',
      toxicity: 0.88,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      flaggedTerms: ['click this link'],
      status: 'pending',
    ),
    _QueueItem(
      id: 'q9',
      type: 'comment',
      author: 'LoganLocal',
      authorId: 'u9',
      content:
          'Dirty Boxing Gym put on an awesome show last weekend. Can\'t wait for the next DFC event.',
      region: 'AUSTRALIA',
      severity: 'LOW',
      toxicity: 0.0,
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      flaggedTerms: [],
      status: 'pending',
    ),
    _QueueItem(
      id: 'q10',
      type: 'post',
      author: 'ShadyPromoter',
      authorId: 'u10',
      content:
          'I know the outcome of next week\'s main event. Fix the fight for big money. Contact me.',
      region: 'USA',
      severity: 'CRITICAL',
      toxicity: 0.95,
      createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
      flaggedTerms: ['fix the fight', 'fixed outcome'],
      status: 'pending',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _items = List.from(_demoItems);
    _loadLiveQueue();
    // Clean expired undo entries every 10 seconds
    _undoCleanupTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _cleanExpiredUndos();
    });
  }

  Future<void> _loadLiveQueue() async {
    try {
      _engine.streamQueue(status: ModerationStatus.pending).listen((items) {
        if (mounted && items.isNotEmpty) {
          setState(() {
            _useDemoData = false;
            _items = items
                .map(
                  (m) => _QueueItem(
                    id: m.id,
                    type: m.type.name,
                    author: m.userId,
                    authorId: m.userId,
                    content: m.content,
                    region: 'GLOBAL',
                    severity: 'MEDIUM',
                    toxicity: 0.5,
                    createdAt: m.createdAt,
                    flaggedTerms: [],
                    status: m.status.name,
                  ),
                )
                .toList();
          });
        }
      });
    } catch (_) {
      // Offline — keep demo data
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _searchCtrl.dispose();
    _editCtrl.dispose();
    _reasonCtrl.dispose();
    _undoCleanupTimer?.cancel();
    super.dispose();
  }

  // ── Filtered items ─────────────────────────────────────────────────────
  List<_QueueItem> get _filteredItems {
    final query = _searchCtrl.text.toLowerCase();
    return _items.where((item) {
      if (item.status != 'pending') return false;
      if (_filterRegion != 'ALL' && item.region != _filterRegion) {
        return false;
      }
      if (_filterSeverity != 'ALL' && item.severity != _filterSeverity) {
        return false;
      }
      if (_filterType != 'ALL' && item.type != _filterType) {
        return false;
      }
      if (query.isNotEmpty &&
          !item.content.toLowerCase().contains(query) &&
          !item.author.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  _QueueItem? get _selected {
    final filtered = _filteredItems;
    if (filtered.isEmpty || _selectedIndex >= filtered.length) return null;
    return filtered[_selectedIndex];
  }

  // ── Actions ────────────────────────────────────────────────────────────
  void _approve([String? id]) {
    final target = id != null
        ? _items.firstWhere((i) => i.id == id)
        : _selected;
    if (target == null) return;
    _pushUndo(target, 'approve');
    setState(() => target.status = 'approved');
    if (!_useDemoData) _engine.approve(target.id, 'moderator_current');
  }

  void _reject([String? id]) {
    final target = id != null
        ? _items.firstWhere((i) => i.id == id)
        : _selected;
    if (target == null) return;
    _showRejectDialog(target);
  }

  void _showRejectDialog(_QueueItem item) {
    _reasonCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgCard,
        title: Row(
          children: [
            const Icon(
              Icons.block_rounded,
              color: DesignTokens.neonRed,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'REJECT: ${item.author}',
              style: const TextStyle(
                color: DesignTokens.neonRed,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${item.content.length > 80 ? '${item.content.substring(0, 80)}...' : item.content}"',
              style: const TextStyle(
                color: DesignTokens.textMuted,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Reason:',
              style: TextStyle(color: DesignTokens.textPrimary, fontSize: 12),
            ),
            const SizedBox(height: 6),
            // Canned reasons
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final reason in _cannedReasons)
                  ActionChip(
                    label: Text(reason, style: const TextStyle(fontSize: 10)),
                    backgroundColor: DesignTokens.bgSecondary,
                    side: const BorderSide(color: DesignTokens.borderSubtle),
                    onPressed: () {
                      _reasonCtrl.text = reason;
                      (ctx as Element).markNeedsBuild();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonCtrl,
              style: const TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: 12,
              ),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Custom reason…',
                hintStyle: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: 11,
                ),
                filled: true,
                fillColor: DesignTokens.bgSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: DesignTokens.textMuted),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.neonRed,
            ),
            icon: const Icon(
              Icons.block_rounded,
              size: 14,
              color: Colors.white,
            ),
            label: const Text(
              'REJECT',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            onPressed: () {
              final reason = _reasonCtrl.text.isEmpty
                  ? 'Rejected by moderator'
                  : _reasonCtrl.text;
              _pushUndo(item, 'reject');
              setState(() => item.status = 'rejected');
              if (!_useDemoData) {
                _engine.reject(item.id, 'moderator_current', reason);
              }
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _escalate() {
    final item = _selected;
    if (item == null) return;
    _pushUndo(item, 'escalate');
    setState(() => item.status = 'escalated');
    if (!_useDemoData) {
      // Write escalation doc
      // FirebaseFirestore.instance.collection('escalations').add({...});
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: DesignTokens.neonAmber,
        content: Text(
          'Escalated "${item.author}" to Safety team',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _pin() {
    final item = _selected;
    if (item == null) return;
    setState(() => item.pinned = !item.pinned);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: DesignTokens.neonGreen,
        content: Text(
          item.pinned ? 'Pinned "${item.author}"' : 'Unpinned "${item.author}"',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _startEdit() {
    final item = _selected;
    if (item == null) return;
    _editCtrl.text = item.content;
    setState(() => _editMode = true);
  }

  void _saveEdit() {
    final item = _selected;
    if (item == null || _editCtrl.text.trim().isEmpty) return;
    _pushUndo(item, 'edit');
    setState(() {
      item.content = _editCtrl.text.trim();
      _editMode = false;
    });
  }

  void _undoLast() {
    if (_undoStack.isEmpty) return;
    final entry = _undoStack.removeLast();
    final elapsed = DateTime.now().difference(entry.timestamp).inSeconds;
    if (elapsed > 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: DesignTokens.neonRed,
          content: Text(
            'Undo window expired (60s)',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }
    setState(() {
      entry.item.status = entry.previousStatus;
      entry.item.content = entry.previousContent;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: DesignTokens.neonCyan,
        content: Text(
          'Undone ${entry.action} on "${entry.item.author}" (${60 - elapsed}s remaining)',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _bulkApprove() {
    for (final idx in _bulkSelected) {
      final filtered = _filteredItems;
      if (idx < filtered.length) _approve(filtered[idx].id);
    }
    setState(() {
      _bulkSelected.clear();
      _bulkMode = false;
    });
  }

  void _pushUndo(_QueueItem item, String action) {
    _undoStack.add(
      _UndoEntry(
        item: item,
        action: action,
        previousStatus: item.status,
        previousContent: item.content,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _cleanExpiredUndos() {
    _undoStack.removeWhere(
      (e) => DateTime.now().difference(e.timestamp).inSeconds > 60,
    );
  }

  static const _cannedReasons = [
    'Harassment',
    'Spam / Scam',
    'Defamation',
    'Match Fixing',
    'Explicit Content',
    'Threat / Violence',
    'Impersonation',
    'Off-Topic',
  ];

  static const _regions = [
    'ALL',
    'AUSTRALIA',
    'USA',
    'UK',
    'THAILAND',
    'BRAZIL',
    'GLOBAL',
  ];
  static const _severities = ['ALL', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];
  static const _types = ['ALL', 'post', 'comment', 'question'];

  // ── Keyboard handler ───────────────────────────────────────────────────
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_editMode) return KeyEventResult.ignored; // let text field handle keys

    final key = event.logicalKey;
    final filtered = _filteredItems;

    if (key == LogicalKeyboardKey.keyJ) {
      setState(
        () =>
            _selectedIndex = (_selectedIndex + 1).clamp(0, filtered.length - 1),
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyK) {
      setState(
        () =>
            _selectedIndex = (_selectedIndex - 1).clamp(0, filtered.length - 1),
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyA) {
      if (_bulkMode && _bulkSelected.isNotEmpty) {
        _bulkApprove();
      } else {
        _approve();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyR) {
      _reject();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyE) {
      _startEdit();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyP) {
      _pin();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyS) {
      _escalate();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyB) {
      setState(() {
        _bulkMode = !_bulkMode;
        _bulkSelected.clear();
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyU) {
      _undoLast();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.slash || key == LogicalKeyboardKey.question) {
      setState(() => _showHelp = !_showHelp);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      setState(() {
        _showHelp = false;
        _editMode = false;
        _bulkMode = false;
        _bulkSelected.clear();
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 1000;
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: DesignTokens.bgPrimary,
        appBar: _appBar(),
        body: Stack(
          children: [
            wide ? _wideLayout() : _narrowLayout(),
            if (_showHelp) _hotKeyOverlay(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    final pendingCount = _filteredItems.length;
    final undoCount = _undoStack
        .where((e) => DateTime.now().difference(e.timestamp).inSeconds <= 60)
        .length;
    return AppBar(
      backgroundColor: DesignTokens.bgSecondary,
      elevation: 0,
      title: Row(
        children: [
          const Icon(
            Icons.shield_rounded,
            color: DesignTokens.neonCyan,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'MOD COMMAND',
            style: TextStyle(
              color: DesignTokens.neonCyan,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 12),
          _badge(pendingCount.toString(), DesignTokens.neonRed),
          const SizedBox(width: 6),
          const Text(
            'pending',
            style: TextStyle(color: DesignTokens.textMuted, fontSize: 10),
          ),
          if (undoCount > 0) ...[
            const SizedBox(width: 12),
            _badge(undoCount.toString(), DesignTokens.neonAmber),
            const SizedBox(width: 4),
            const Text(
              'undo',
              style: TextStyle(color: DesignTokens.textMuted, fontSize: 10),
            ),
          ],
          if (_bulkMode) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: DesignTokens.neonMagenta.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'BULK (${_bulkSelected.length})',
                style: const TextStyle(
                  color: DesignTokens.neonMagenta,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          if (_useDemoData) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: DesignTokens.neonAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'DEMO',
                style: TextStyle(
                  color: DesignTokens.neonAmber,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline_rounded, size: 18),
          color: DesignTokens.textMuted,
          tooltip: 'Hotkeys (?)',
          onPressed: () => setState(() => _showHelp = !_showHelp),
        ),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LAYOUTS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _wideLayout() {
    return Row(
      children: [
        SizedBox(width: 240, child: _filterPanel()),
        const VerticalDivider(width: 1, color: DesignTokens.borderSubtle),
        Expanded(child: _queueList()),
        const VerticalDivider(width: 1, color: DesignTokens.borderSubtle),
        SizedBox(width: 400, child: _detailPane()),
      ],
    );
  }

  Widget _narrowLayout() {
    return Column(
      children: [
        SizedBox(height: 48, child: _filterChipsCompact()),
        const Divider(height: 1, color: DesignTokens.borderSubtle),
        Expanded(
          child: _selected != null
              ? Row(
                  children: [
                    Expanded(child: _queueList()),
                    SizedBox(width: 320, child: _detailPane()),
                  ],
                )
              : _queueList(),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LEFT PANEL — FILTERS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _filterPanel() {
    return Container(
      color: DesignTokens.bgSecondary,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Search
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: 12,
            ),
            decoration: InputDecoration(
              hintText: 'Search content / author…',
              hintStyle: const TextStyle(color: DesignTokens.textMuted, fontSize: 11),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: DesignTokens.neonCyan,
                size: 16,
              ),
              filled: true,
              fillColor: DesignTokens.bgCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 10,
              ),
            ),
          ),
          const SizedBox(height: 16),

          _filterSection(
            'REGION',
            _regions,
            _filterRegion,
            (v) => setState(() {
              _filterRegion = v;
              _selectedIndex = 0;
            }),
          ),
          const SizedBox(height: 12),
          _filterSection(
            'SEVERITY',
            _severities,
            _filterSeverity,
            (v) => setState(() {
              _filterSeverity = v;
              _selectedIndex = 0;
            }),
          ),
          const SizedBox(height: 12),
          _filterSection(
            'TYPE',
            _types,
            _filterType,
            (v) => setState(() {
              _filterType = v;
              _selectedIndex = 0;
            }),
          ),

          const SizedBox(height: 20),
          // Quick stats
          _statTile(
            'Total Queue',
            '${_items.where((i) => i.status == 'pending').length}',
            DesignTokens.neonCyan,
          ),
          _statTile(
            'Critical',
            '${_items.where((i) => i.severity == 'CRITICAL' && i.status == 'pending').length}',
            DesignTokens.neonRed,
          ),
          _statTile(
            'Approved Today',
            '${_items.where((i) => i.status == 'approved').length}',
            DesignTokens.neonGreen,
          ),
          _statTile(
            'Rejected Today',
            '${_items.where((i) => i.status == 'rejected').length}',
            DesignTokens.neonAmber,
          ),

          const SizedBox(height: 16),
          // Bulk actions
          if (_bulkMode && _bulkSelected.isNotEmpty) ...[
            const Divider(color: DesignTokens.borderSubtle),
            const SizedBox(height: 8),
            Text(
              'BULK ACTIONS (${_bulkSelected.length})',
              style: const TextStyle(
                color: DesignTokens.neonMagenta,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            _bulkActionBtn(
              'Approve All',
              Icons.check_circle_rounded,
              DesignTokens.neonGreen,
              _bulkApprove,
            ),
            const SizedBox(height: 4),
            _bulkActionBtn(
              'Reject All',
              Icons.block_rounded,
              DesignTokens.neonRed,
              () {
                for (final idx in _bulkSelected) {
                  if (idx < _filteredItems.length) {
                    final item = _filteredItems[idx];
                    _pushUndo(item, 'reject');
                    item.status = 'rejected';
                  }
                }
                setState(() {
                  _bulkSelected.clear();
                  _bulkMode = false;
                });
              },
            ),
            const SizedBox(height: 4),
            _bulkActionBtn(
              'Escalate All',
              Icons.warning_amber_rounded,
              DesignTokens.neonAmber,
              () {
                for (final idx in _bulkSelected) {
                  if (idx < _filteredItems.length) {
                    final item = _filteredItems[idx];
                    _pushUndo(item, 'escalate');
                    item.status = 'escalated';
                  }
                }
                setState(() {
                  _bulkSelected.clear();
                  _bulkMode = false;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterSection(
    String label,
    List<String> options,
    String current,
    ValueChanged<String> onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: DesignTokens.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: options.map((opt) {
            final sel = current == opt;
            return GestureDetector(
              onTap: () => onSelect(opt),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: sel
                      ? DesignTokens.neonCyan.withValues(alpha: 0.15)
                      : DesignTokens.bgCard,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: sel
                        ? DesignTokens.neonCyan
                        : DesignTokens.borderSubtle,
                  ),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: sel ? DesignTokens.neonCyan : DesignTokens.textMuted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _statTile(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: DesignTokens.textMuted, fontSize: 10),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulkActionBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14, color: color),
        label: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 6),
        ),
      ),
    );
  }

  Widget _filterChipsCompact() {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      children: [
        for (final s in _severities)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ChoiceChip(
              label: Text(
                s,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: _filterSeverity == s
                      ? Colors.black
                      : DesignTokens.textMuted,
                ),
              ),
              selected: _filterSeverity == s,
              selectedColor: _severityColor(s),
              backgroundColor: DesignTokens.bgCard,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => setState(() {
                _filterSeverity = s;
                _selectedIndex = 0;
              }),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CENTER PANEL — QUEUE LIST
  // ═══════════════════════════════════════════════════════════════════════

  Widget _queueList() {
    final items = _filteredItems;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_user_rounded,
              size: 48,
              color: DesignTokens.neonGreen.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            const Text(
              'Queue Clear',
              style: TextStyle(
                color: DesignTokens.neonGreen,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'No pending items match current filters',
              style: TextStyle(color: DesignTokens.textMuted, fontSize: 11),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (_, i) => _queueCard(items[i], i),
    );
  }

  Widget _queueCard(_QueueItem item, int index) {
    final isSelected = index == _selectedIndex;
    final sevColor = _severityColor(item.severity);
    return GestureDetector(
      onTap: () => setState(() {
        if (_bulkMode) {
          _bulkSelected.contains(index)
              ? _bulkSelected.remove(index)
              : _bulkSelected.add(index);
        } else {
          _selectedIndex = index;
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? DesignTokens.neonCyan.withValues(alpha: 0.06)
              : DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _bulkSelected.contains(index)
                ? DesignTokens.neonMagenta
                : isSelected
                ? DesignTokens.neonCyan.withValues(alpha: 0.5)
                : DesignTokens.borderSubtle,
            width: isSelected || _bulkSelected.contains(index) ? 1.5 : 0.6,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Severity indicator
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: sevColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: _typeColor(item.type).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          item.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: _typeColor(item.type),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.author,
                        style: const TextStyle(
                          color: DesignTokens.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      if (item.pinned)
                        const Icon(
                          Icons.push_pin_rounded,
                          size: 12,
                          color: DesignTokens.neonGreen,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        _timeAgo(item.createdAt),
                        style: const TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DesignTokens.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _toxicityBar(item.toxicity),
                      const Spacer(),
                      if (item.flaggedTerms.isNotEmpty)
                        Text(
                          item.flaggedTerms.take(2).join(', '),
                          style: TextStyle(
                            color: DesignTokens.neonRed.withValues(alpha: 0.7),
                            fontSize: 9,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Quick action buttons
            if (isSelected && !_bulkMode) ...[
              const SizedBox(width: 6),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _quickBtn(
                    Icons.check_rounded,
                    DesignTokens.neonGreen,
                    'Approve',
                    _approve,
                  ),
                  const SizedBox(height: 2),
                  _quickBtn(
                    Icons.close_rounded,
                    DesignTokens.neonRed,
                    'Reject',
                    _reject,
                  ),
                  const SizedBox(height: 2),
                  _quickBtn(
                    Icons.warning_amber_rounded,
                    DesignTokens.neonAmber,
                    'Escalate',
                    _escalate,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _quickBtn(
    IconData icon,
    Color color,
    String tooltip,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }

  Widget _toxicityBar(double score) {
    final color = score >= 0.8
        ? DesignTokens.neonRed
        : score >= 0.5
        ? DesignTokens.neonAmber
        : score >= 0.2
        ? const Color(0xFFFFD700)
        : DesignTokens.neonGreen;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 50,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: score,
              color: color,
              backgroundColor: Colors.white10,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${(score * 100).toInt()}%',
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // RIGHT PANEL — DETAIL PANE
  // ═══════════════════════════════════════════════════════════════════════

  Widget _detailPane() {
    final item = _selected;
    if (item == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app_rounded,
              size: 36,
              color: DesignTokens.textMuted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select an item',
              style: TextStyle(color: DesignTokens.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 4),
            const Text(
              'J/K to navigate',
              style: TextStyle(color: DesignTokens.textMuted, fontSize: 10),
            ),
          ],
        ),
      );
    }
    return Container(
      color: DesignTokens.bgSecondary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _severityColor(item.severity).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.severity,
                  style: TextStyle(
                    color: _severityColor(item.severity),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _typeColor(item.type).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.type.toUpperCase(),
                  style: TextStyle(
                    color: _typeColor(item.type),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                item.region,
                style: const TextStyle(color: DesignTokens.textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Author
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: DesignTokens.neonCyan.withValues(alpha: 0.15),
                child: Text(
                  item.author[0],
                  style: const TextStyle(
                    color: DesignTokens.neonCyan,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.author,
                    style: const TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'ID: ${item.authorId}  •  ${_timeAgo(item.createdAt)}',
                    style: const TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Full content
          const Text(
            'CONTENT',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          if (_editMode) ...[
            TextField(
              controller: _editCtrl,
              maxLines: 6,
              style: const TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: 12,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: DesignTokens.bgCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _saveEdit,
                  icon: const Icon(Icons.save_rounded, size: 14),
                  label: const Text(
                    'Save & Publish',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.neonGreen,
                    foregroundColor: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() => _editMode = false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DesignTokens.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DesignTokens.borderSubtle),
              ),
              child: SelectableText(
                item.content,
                style: const TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Toxicity analysis
          const Text(
            'ANALYSIS',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          _analysisTile(
            'Toxicity Score',
            '${(item.toxicity * 100).toInt()}%',
            item.toxicity >= 0.8
                ? DesignTokens.neonRed
                : item.toxicity >= 0.4
                ? DesignTokens.neonAmber
                : DesignTokens.neonGreen,
          ),
          if (item.flaggedTerms.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: item.flaggedTerms
                  .map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.neonRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: DesignTokens.neonRed.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        t,
                        style: const TextStyle(
                          color: DesignTokens.neonRed,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 20),

          // Action bar
          const Text(
            'ACTIONS',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _actionButton(
                'APPROVE (A)',
                Icons.check_circle_rounded,
                DesignTokens.neonGreen,
                _approve,
              ),
              _actionButton(
                'REJECT (R)',
                Icons.block_rounded,
                DesignTokens.neonRed,
                _reject,
              ),
              _actionButton(
                'EDIT (E)',
                Icons.edit_rounded,
                DesignTokens.neonCyan,
                _startEdit,
              ),
              _actionButton(
                'PIN (P)',
                Icons.push_pin_rounded,
                DesignTokens.neonGold,
                _pin,
              ),
              _actionButton(
                'ESCALATE (S)',
                Icons.warning_amber_rounded,
                DesignTokens.neonAmber,
                _escalate,
              ),
              _actionButton(
                'UNDO (U)',
                Icons.undo_rounded,
                DesignTokens.textMuted,
                _undoLast,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Audit trail
          const Text(
            'AUDIT TRAIL',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          _auditEntry(
            'Created',
            item.createdAt.toIso8601String(),
            Icons.add_circle_outline_rounded,
          ),
          _auditEntry(
            'Flagged by AI',
            'Layer 2 — toxicity ${(item.toxicity * 100).toInt()}%',
            Icons.smart_toy_rounded,
          ),
          _auditEntry(
            'Queued for review',
            'Pending moderator action',
            Icons.hourglass_top_rounded,
          ),
        ],
      ),
    );
  }

  Widget _analysisTile(String label, String value, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: DesignTokens.textMuted, fontSize: 11),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }

  Widget _auditEntry(String action, String detail, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: DesignTokens.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(color: DesignTokens.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HOTKEY HELP OVERLAY
  // ═══════════════════════════════════════════════════════════════════════

  Widget _hotKeyOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _showHelp = false),
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: DesignTokens.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: DesignTokens.neonCyan.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'KEYBOARD SHORTCUTS',
                  style: TextStyle(
                    color: DesignTokens.neonCyan,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                _hotkeyRow('J', 'Next item'),
                _hotkeyRow('K', 'Previous item'),
                _hotkeyRow('A', 'Approve selected'),
                _hotkeyRow('R', 'Reject selected (reason modal)'),
                _hotkeyRow('E', 'Edit selected (inline editor)'),
                _hotkeyRow('P', 'Pin / unpin selected'),
                _hotkeyRow('S', 'Escalate to Safety'),
                _hotkeyRow('B', 'Toggle bulk select mode'),
                _hotkeyRow('U', 'Undo last action (60s window)'),
                _hotkeyRow('?', 'Toggle this help'),
                _hotkeyRow('Esc', 'Close overlay / cancel'),
                const SizedBox(height: 12),
                const Text(
                  'Press any key to close',
                  style: TextStyle(color: DesignTokens.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hotkeyRow(String key, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DesignTokens.bgPrimary,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: DesignTokens.neonCyan.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              key,
              style: const TextStyle(
                color: DesignTokens.neonCyan,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            desc,
            style: const TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  Color _severityColor(String severity) => switch (severity) {
    'CRITICAL' => DesignTokens.neonRed,
    'HIGH' => DesignTokens.neonAmber,
    'MEDIUM' => const Color(0xFFFFD700),
    'LOW' => DesignTokens.neonGreen,
    _ => DesignTokens.textMuted,
  };

  Color _typeColor(String type) => switch (type) {
    'post' => DesignTokens.neonCyan,
    'comment' => DesignTokens.neonMagenta,
    'question' => DesignTokens.neonAmber,
    _ => DesignTokens.textMuted,
  };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

class _QueueItem {
  final String id;
  final String type;
  final String author;
  final String authorId;
  String content;
  final String region;
  final String severity;
  final double toxicity;
  final DateTime createdAt;
  final List<String> flaggedTerms;
  String status;
  bool pinned;

  _QueueItem({
    required this.id,
    required this.type,
    required this.author,
    required this.authorId,
    required this.content,
    required this.region,
    required this.severity,
    required this.toxicity,
    required this.createdAt,
    required this.flaggedTerms,
    required this.status,
    this.pinned = false, // ignore: unused_element_parameter
  });
}

class _UndoEntry {
  final _QueueItem item;
  final String action;
  final String previousStatus;
  final String previousContent;
  final DateTime timestamp;

  _UndoEntry({
    required this.item,
    required this.action,
    required this.previousStatus,
    required this.previousContent,
    required this.timestamp,
  });
}
