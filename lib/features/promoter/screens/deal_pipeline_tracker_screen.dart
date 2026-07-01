import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/dfc_cosmetic_widgets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DEAL PIPELINE TRACKER — Manage promoter deals from pitch to payout
/// ═══════════════════════════════════════════════════════════════════════════

class DealPipelineTrackerScreen extends StatefulWidget {
  const DealPipelineTrackerScreen({super.key});

  @override
  State<DealPipelineTrackerScreen> createState() =>
      _DealPipelineTrackerScreenState();
}

class _DealPipelineTrackerScreenState extends State<DealPipelineTrackerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseAnim;

  final List<_Deal> _deals = [
    _Deal(
      id: '1',
      promoter: 'Townsville Fight Show',
      fighter: 'Aze Hepi',
      stage: _DealStage.pitched,
      guarantee: 2000,
      split: '60/40',
      adBudget: 1000,
      daysOpen: 3,
      notes: 'Pilot proposal sent — awaiting pixel access',
    ),
    _Deal(
      id: '2',
      promoter: 'Adelaide Combat Series',
      fighter: 'Logan / The Hood',
      stage: _DealStage.accessGranted,
      guarantee: 3000,
      split: '55/45 sliding',
      adBudget: 2500,
      daysOpen: 7,
      notes: 'Pixel access confirmed, term sheet pending signature',
    ),
    _Deal(
      id: '3',
      promoter: 'BKFC Australia',
      fighter: 'Aze Hepi',
      stage: _DealStage.pilotRunning,
      guarantee: 5000,
      split: '60/40 → 50/50',
      adBudget: 5000,
      daysOpen: 12,
      notes: 'Day 5 of 7 — CTR 3.2%, 42 tickets sold, on track',
    ),
    _Deal(
      id: '4',
      promoter: 'LFS 45',
      fighter: 'Card Multi',
      stage: _DealStage.signed,
      guarantee: 1500,
      split: '60/40',
      adBudget: 800,
      daysOpen: 21,
      notes: 'Full term sheet signed, activation launching Monday',
    ),
    _Deal(
      id: '5',
      promoter: 'Foxtel / Kayo',
      fighter: 'Clip License',
      stage: _DealStage.outreach,
      guarantee: 0,
      split: 'Co-promo',
      adBudget: 0,
      daysOpen: 1,
      notes: 'Initial email sent for clip pilot license',
    ),
  ];

  _DealStage? _filterStage;
  String _sortBy = 'stage';

  @override
  void initState() {
    super.initState();
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseAnim.dispose();
    super.dispose();
  }

  List<_Deal> get _filteredDeals {
    final list = _filterStage == null
        ? _deals
        : _deals.where((d) => d.stage == _filterStage).toList();
    switch (_sortBy) {
      case 'guarantee':
        list.sort((a, b) => b.guarantee.compareTo(a.guarantee));
        break;
      case 'daysOpen':
        list.sort((a, b) => b.daysOpen.compareTo(a.daysOpen));
        break;
      default:
        list.sort((a, b) => a.stage.index.compareTo(b.stage.index));
    }
    return list;
  }

  void _advanceStage(_Deal deal) {
    setState(() {
      final idx = _DealStage.values.indexOf(deal.stage);
      if (idx < _DealStage.values.length - 1) {
        deal.stage = _DealStage.values[idx + 1];
      }
    });
  }

  void _addDeal() {
    setState(() {
      _deals.add(
        _Deal(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          promoter: 'New Promoter',
          fighter: 'TBD',
          stage: _DealStage.outreach,
          guarantee: 0,
          split: '60/40',
          adBudget: 0,
          daysOpen: 0,
          notes: '',
        ),
      );
    });
  }

  void _exportPipeline() {
    final buf = StringBuffer('DEAL PIPELINE EXPORT\n');
    buf.writeln('=' * 50);
    for (final d in _filteredDeals) {
      buf.writeln('${d.promoter} — ${d.fighter}');
      buf.writeln('  Stage: ${d.stage.label}');
      buf.writeln('  Split: ${d.split} | Guarantee: AUD ${d.guarantee}');
      buf.writeln('  Ad Budget: AUD ${d.adBudget} | Days Open: ${d.daysOpen}');
      buf.writeln('  Notes: ${d.notes}');
      buf.writeln();
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pipeline exported to clipboard'),
        backgroundColor: Color(0xFF00FF88),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      floatingActionButton: FloatingActionButton(
        backgroundColor: DesignTokens.neonCyan,
        onPressed: _addDeal,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Stack(
        children: [
          const DFCCosmicBackground(
            particleCount: 30,
            primaryColor: DesignTokens.neonGreen,
            secondaryColor: DesignTokens.neonGold,
          ),
          SafeArea(
            child: Column(
              children: [
                _header(),
                _stageSummaryBar(),
                _filterBar(),
                Expanded(child: _dealList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, a) => Icon(
              Icons.handshake,
              color: Color.lerp(
                DesignTokens.neonGreen,
                DesignTokens.neonGold,
                _pulseAnim.value,
              ),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEAL PIPELINE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Track deals from outreach to payout',
                  style: TextStyle(color: DesignTokens.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.file_download_outlined,
              color: DesignTokens.neonGreen,
            ),
            tooltip: 'Export Pipeline',
            onPressed: _exportPipeline,
          ),
        ],
      ),
    );
  }

  Widget _stageSummaryBar() {
    final counts = <_DealStage, int>{};
    for (final s in _DealStage.values) {
      counts[s] = _deals.where((d) => d.stage == s).length;
    }
    final totalGuarantee = _deals.fold<double>(
      0,
      (sum, d) => sum + d.guarantee,
    );
    final totalBudget = _deals.fold<double>(0, (sum, d) => sum + d.adBudget);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: GlassDecoration.card(accent: DesignTokens.neonGreen),
      child: Column(
        children: [
          Row(
            children: _DealStage.values.map((s) {
              final c = counts[s] ?? 0;
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      '$c',
                      style: TextStyle(
                        color: s.color,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      s.shortLabel,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat('Total Deals', '${_deals.length}', Colors.white),
              _miniStat(
                'Guarantees',
                'AUD ${totalGuarantee.toStringAsFixed(0)}',
                DesignTokens.neonGold,
              ),
              _miniStat(
                'Ad Budget',
                'AUD ${totalBudget.toStringAsFixed(0)}',
                DesignTokens.neonAmber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }

  Widget _filterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Stage filter chips
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All', _filterStage == null, () {
                    setState(() => _filterStage = null);
                  }),
                  ..._DealStage.values.map(
                    (s) => _filterChip(
                      s.shortLabel,
                      _filterStage == s,
                      () => setState(() => _filterStage = s),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Sort dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: DesignTokens.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: DesignTokens.neonCyan.withValues(alpha: 0.2),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortBy,
                dropdownColor: DesignTokens.bgSecondary,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                items: const [
                  DropdownMenuItem(value: 'stage', child: Text('By Stage')),
                  DropdownMenuItem(
                    value: 'guarantee',
                    child: Text('By Guarantee'),
                  ),
                  DropdownMenuItem(value: 'daysOpen', child: Text('By Age')),
                ],
                onChanged: (v) => setState(() => _sortBy = v!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool sel, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: sel
                ? DesignTokens.neonCyan.withValues(alpha: 0.15)
                : DesignTokens.bgCard,
            border: Border.all(
              color: sel
                  ? DesignTokens.neonCyan
                  : DesignTokens.neonCyan.withValues(alpha: 0.15),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: sel ? DesignTokens.neonCyan : Colors.white54,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dealList() {
    final deals = _filteredDeals;
    if (deals.isEmpty) {
      return const Center(
        child: Text(
          'No deals match filter',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: deals.length,
      itemBuilder: (context, i) => _dealCard(deals[i]),
    );
  }

  Widget _dealCard(_Deal deal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: GlassDecoration.card(accent: deal.stage.color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: deal.stage.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: deal.stage.color),
                ),
                child: Text(
                  deal.stage.label,
                  style: TextStyle(
                    color: deal.stage.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  deal.promoter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                '${deal.daysOpen}d',
                style: TextStyle(
                  color: deal.daysOpen > 14
                      ? DesignTokens.neonRed
                      : Colors.white38,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Fighter + Split ──
          Row(
            children: [
              const Icon(Icons.sports_mma, color: Colors.white38, size: 14),
              const SizedBox(width: 6),
              Text(
                deal.fighter,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              Text(
                'Split: ${deal.split}',
                style: const TextStyle(
                  color: DesignTokens.neonGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ── Financials ──
          Row(
            children: [
              _dealStat(
                'Guarantee',
                'AUD ${deal.guarantee.toStringAsFixed(0)}',
                DesignTokens.neonGreen,
              ),
              const SizedBox(width: 16),
              _dealStat(
                'Ad Budget',
                'AUD ${deal.adBudget.toStringAsFixed(0)}',
                DesignTokens.neonAmber,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Notes ──
          if (deal.notes.isNotEmpty)
            Text(
              deal.notes,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: 10),

          // ── Actions ──
          Row(
            children: [
              if (deal.stage.index < _DealStage.values.length - 1)
                _miniButton(
                  'Advance →',
                  deal.stage.color,
                  () => _advanceStage(deal),
                ),
              const Spacer(),
              _miniButton('Edit', DesignTokens.neonCyan, () => _editDeal(deal)),
              const SizedBox(width: 8),
              _miniButton('Copy', DesignTokens.neonGold, () {
                Clipboard.setData(
                  ClipboardData(
                    text:
                        '${deal.promoter} — ${deal.fighter}\nStage: ${deal.stage.label}\nSplit: ${deal.split}\nGuarantee: AUD ${deal.guarantee}\nNotes: ${deal.notes}',
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Deal details copied'),
                    backgroundColor: Color(0xFF00FF88),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dealStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _miniButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  void _editDeal(_Deal deal) {
    final nameCtrl = TextEditingController(text: deal.promoter);
    final fighterCtrl = TextEditingController(text: deal.fighter);
    final splitCtrl = TextEditingController(text: deal.split);
    final guaranteeCtrl = TextEditingController(
      text: deal.guarantee.toStringAsFixed(0),
    );
    final budgetCtrl = TextEditingController(
      text: deal.adBudget.toStringAsFixed(0),
    );
    final notesCtrl = TextEditingController(text: deal.notes);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Text(
          'Edit Deal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(nameCtrl, 'Promoter'),
              _dialogField(fighterCtrl, 'Fighter'),
              _dialogField(splitCtrl, 'Split'),
              _dialogField(guaranteeCtrl, 'Guarantee (AUD)'),
              _dialogField(budgetCtrl, 'Ad Budget (AUD)'),
              _dialogField(notesCtrl, 'Notes', maxLines: 3),
            ],
          ),
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
              backgroundColor: DesignTokens.neonCyan,
            ),
            onPressed: () {
              setState(() {
                deal.promoter = nameCtrl.text;
                deal.fighter = fighterCtrl.text;
                deal.split = splitCtrl.text;
                deal.guarantee =
                    double.tryParse(guaranteeCtrl.text) ?? deal.guarantee;
                deal.adBudget =
                    double.tryParse(budgetCtrl.text) ?? deal.adBudget;
                deal.notes = notesCtrl.text;
              });
              Navigator.pop(ctx);
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: DesignTokens.neonCyan.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: DesignTokens.neonCyan),
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: DesignTokens.bgCard,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════════════════════════════════

enum _DealStage {
  outreach,
  pitched,
  accessGranted,
  pilotRunning,
  signed,
  payout;

  String get label => switch (this) {
    outreach => 'OUTREACH',
    pitched => 'PITCHED',
    accessGranted => 'ACCESS GRANTED',
    pilotRunning => 'PILOT RUNNING',
    signed => 'SIGNED',
    payout => 'PAYOUT',
  };

  String get shortLabel => switch (this) {
    outreach => 'Out',
    pitched => 'Pitch',
    accessGranted => 'Access',
    pilotRunning => 'Pilot',
    signed => 'Signed',
    payout => 'Paid',
  };

  Color get color => switch (this) {
    outreach => DesignTokens.textMuted,
    pitched => DesignTokens.neonCyan,
    accessGranted => DesignTokens.neonAmber,
    pilotRunning => DesignTokens.neonMagenta,
    signed => DesignTokens.neonGreen,
    payout => DesignTokens.neonGold,
  };
}

class _Deal {
  final String id;
  String promoter;
  String fighter;
  _DealStage stage;
  double guarantee;
  String split;
  double adBudget;
  int daysOpen;
  String notes;

  _Deal({
    required this.id,
    required this.promoter,
    required this.fighter,
    required this.stage,
    required this.guarantee,
    required this.split,
    required this.adBudget,
    required this.daysOpen,
    required this.notes,
  });
}
