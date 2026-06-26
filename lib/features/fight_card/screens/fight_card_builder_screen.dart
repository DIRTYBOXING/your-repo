import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/fight_card_template.dart';
import '../../../shared/services/fight_card_template_service.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/fight_matcher_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT CARD BUILDER — Editor Screen
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Coaches/promoters build an event fight card from scratch.
/// Template: Main Event → Semi-Main → Co-Main → Prelims → Undercard.
/// Each bout has Red/Blue corner, weight class, rounds, rules.
///
/// ═══════════════════════════════════════════════════════════════════════════
class FightCardBuilderScreen extends StatefulWidget {
  final String? existingCardId;
  const FightCardBuilderScreen({this.existingCardId, super.key});

  @override
  State<FightCardBuilderScreen> createState() => _FightCardBuilderScreenState();
}

class _FightCardBuilderScreenState extends State<FightCardBuilderScreen> {
  // Event details controllers
  final _eventNameCtrl = TextEditingController();
  final _promotionCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _sanctionCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _country = 'Australia';
  String _sportType = 'MMA';
  DateTime _eventDate = DateTime.now().add(const Duration(days: 30));

  List<FightCardBout> _bouts = [];
  bool _saving = false;
  String? _existingDocId;
  bool _loadedExisting = false;

  static const _countries = [
    'Australia',
    'New Zealand',
    'United States',
    'United Kingdom',
    'Thailand',
    'Japan',
    'Philippines',
    'Indonesia',
    'Canada',
    'Ireland',
    'South Africa',
    'Brazil',
    'Mexico',
    'France',
    'Germany',
  ];

  @override
  void initState() {
    super.initState();
    // Start with a fuller default template so promoters see
    // a realistic card immediately in preview.
    _bouts = [
      // Headliners
      FightCardBout(id: _uid(), position: BoutPosition.mainEvent),
      FightCardBout(id: _uid(), position: BoutPosition.semiMain),
      FightCardBout(id: _uid(), position: BoutPosition.coMain),
      FightCardBout(
        id: _uid(),
        position: BoutPosition.superfight,
      ),

      // Prelims
      FightCardBout(id: _uid()),
      FightCardBout(id: _uid(), boutOrder: 1),
      FightCardBout(id: _uid(), boutOrder: 2),
      FightCardBout(id: _uid(), boutOrder: 3),

      // Undercard
      FightCardBout(id: _uid(), position: BoutPosition.undercard),
      FightCardBout(id: _uid(), position: BoutPosition.undercard, boutOrder: 1),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.existingCardId != null && !_loadedExisting) {
      _loadExistingCard();
    }
  }

  Future<void> _loadExistingCard() async {
    _loadedExisting = true;
    final svc = context.read<FightCardTemplateService>();
    // Try to find in local lists
    final card = svc.myCards.cast<FightCardTemplate?>().firstWhere(
      (c) => c?.id == widget.existingCardId,
      orElse: () => null,
    );
    if (card != null) {
      _populateFrom(card);
    }
  }

  void _populateFrom(FightCardTemplate card) {
    setState(() {
      _eventNameCtrl.text = card.eventName;
      _promotionCtrl.text = card.promotionName;
      _venueCtrl.text = card.venue;
      _cityCtrl.text = card.city;
      _sanctionCtrl.text = card.sanctioningBody;
      _notesCtrl.text = card.notes ?? '';
      _country = card.country;
      _sportType = card.sportType;
      _eventDate = card.eventDate;
      _bouts = List<FightCardBout>.from(card.bouts);
      _existingDocId = card.id;
    });
  }

  String _uid() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  @override
  void dispose() {
    _eventNameCtrl.dispose();
    _promotionCtrl.dispose();
    _venueCtrl.dispose();
    _cityCtrl.dispose();
    _sanctionCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: Text(
          widget.existingCardId != null
              ? 'EDIT FIGHT CARD'
              : 'BUILD FIGHT CARD',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: AppTheme.secondaryBackground,
        actions: [
          // Preview button
          IconButton(
            icon: const Icon(Icons.visibility, color: AppTheme.neonCyan),
            tooltip: 'Preview',
            onPressed: _bouts.isEmpty ? null : _openPreview,
          ),
          // Save button
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.neonGreen,
                    ),
                  )
                : const Icon(Icons.save, color: AppTheme.neonGreen),
            tooltip: 'Save',
            onPressed: _saving ? null : _saveCard,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Event Details Section ────────────────────────────
            _sectionHeader('EVENT DETAILS', Icons.event),
            const SizedBox(height: 12),
            _buildEventDetailsForm(),

            const SizedBox(height: 28),

            // ── Fight Card Section ───────────────────────────────
            _sectionHeader('FIGHT CARD', Icons.sports_mma),
            const SizedBox(height: 8),
            const Text(
              'Fill bouts from Main Event down. Tap + to add more.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),

            ..._buildBoutEditors(),

            const SizedBox(height: 12),
            _buildAddBoutButton(),

            const SizedBox(height: 28),

            // ── Notes Section ────────────────────────────────────
            _sectionHeader('NOTES', Icons.note),
            const SizedBox(height: 8),
            _buildField(
              _notesCtrl,
              'Additional notes, rules, or instructions',
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            // ── Action Buttons ───────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.visibility),
                    label: const Text('PREVIEW'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.neonCyan,
                      side: const BorderSide(color: AppTheme.neonCyan),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _openPreview,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('SAVE CARD'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _saving ? null : _saveCard,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EVENT DETAILS FORM
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildEventDetailsForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          _buildField(
            _eventNameCtrl,
            'Event Name *',
            hint: 'e.g. DFC Fight Night 12',
          ),
          const SizedBox(height: 12),
          _buildField(
            _promotionCtrl,
            'Promotion / Organisation',
            hint: 'e.g. DataFightCentral Promotions',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildField(
                  _venueCtrl,
                  'Venue',
                  hint: 'e.g. Melbourne Pavilion',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildField(_cityCtrl, 'City', hint: 'e.g. Melbourne'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildCountryDropdown()),
              const SizedBox(width: 12),
              Expanded(child: _buildSportTypeDropdown()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildField(
                  _sanctionCtrl,
                  'Sanctioning Body',
                  hint: 'e.g. WKBF, ISKA',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildDatePicker()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _country,
      dropdownColor: AppTheme.cardBackground,
      decoration: InputDecoration(
        labelText: 'Country',
        labelStyle: const TextStyle(color: AppTheme.textMuted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      style: const TextStyle(color: Colors.white),
      items: _countries
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) => setState(() => _country = v ?? _country),
    );
  }

  Widget _buildSportTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _sportType,
      dropdownColor: AppTheme.cardBackground,
      decoration: InputDecoration(
        labelText: 'Sport',
        labelStyle: const TextStyle(color: AppTheme.textMuted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      style: const TextStyle(color: Colors.white),
      items: AppConstants.sportTypes
          .where((s) => s != 'Run It') // Not a combat sport
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (v) => setState(() => _sportType = v ?? _sportType),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _eventDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 730)),
        );
        if (picked != null) setState(() => _eventDate = picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Event Date',
          labelStyle: const TextStyle(color: AppTheme.textMuted),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          '${_eventDate.day.toString().padLeft(2, '0')}/${_eventDate.month.toString().padLeft(2, '0')}/${_eventDate.year}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOUT EDITORS
  // ═══════════════════════════════════════════════════════════════════════════
  List<Widget> _buildBoutEditors() {
    // Sort like the model
    final sorted = List<FightCardBout>.from(_bouts);
    sorted.sort((a, b) {
      final posCmp = a.position.sortOrder.compareTo(b.position.sortOrder);
      if (posCmp != 0) return posCmp;
      return a.boutOrder.compareTo(b.boutOrder);
    });

    return sorted.asMap().entries.map((entry) {
      final bout = entry.value;
      final boutIndex = _bouts.indexOf(bout);
      return _BoutEditorCard(
        key: ValueKey(bout.id),
        bout: bout,
        sportType: _sportType,
        onChanged: (updated) {
          setState(() => _bouts[boutIndex] = updated);
        },
        onDelete: _bouts.length > 1
            ? () => setState(() => _bouts.removeAt(boutIndex))
            : null,
      );
    }).toList();
  }

  Widget _buildAddBoutButton() {
    return PopupMenuButton<BoutPosition>(
      onSelected: (pos) {
        setState(() {
          _bouts.add(
            FightCardBout(
              id: _uid(),
              position: pos,
              boutOrder: _bouts.where((b) => b.position == pos).length,
              sportType: _sportType,
            ),
          );
        });
      },
      itemBuilder: (_) => BoutPosition.values
          .map((p) => PopupMenuItem(value: p, child: Text(p.label)))
          .toList(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.neonCyan.withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle, color: AppTheme.neonCyan, size: 22),
            SizedBox(width: 8),
            Text(
              'ADD BOUT',
              style: TextStyle(
                color: AppTheme.neonCyan,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.neonCyan, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.neonCyan,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label, {
    String? hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppTheme.textMuted),
        hintStyle: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }

  // ── Save ───────────────────────────────────────────────────────────────────
  Future<void> _saveCard() async {
    if (_eventNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an event name')),
      );
      return;
    }

    setState(() => _saving = true);

    final auth = context.read<AuthService>();
    final svc = context.read<FightCardTemplateService>();
    final now = DateTime.now();

    final card = FightCardTemplate(
      id: _existingDocId ?? '',
      creatorId: auth.currentUser?.uid ?? 'anonymous',
      creatorName: auth.userModel?.displayName ?? 'Unknown',
      eventName: _eventNameCtrl.text.trim(),
      promotionName: _promotionCtrl.text.trim(),
      venue: _venueCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      country: _country,
      eventDate: _eventDate,
      sportType: _sportType,
      sanctioningBody: _sanctionCtrl.text.trim(),
      bouts: _bouts,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: now,
      updatedAt: now,
    );

    bool success;
    if (_existingDocId != null) {
      success = await svc.updateCard(card);
    } else {
      final docId = await svc.createCard(card);
      success = docId != null;
      if (success) _existingDocId = docId;
    }

    setState(() => _saving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Fight card saved!' : 'Failed to save'),
        backgroundColor: success ? AppTheme.success : AppTheme.error,
      ),
    );
  }

  // ── Preview ────────────────────────────────────────────────────────────────
  void _openPreview() {
    final auth = context.read<AuthService>();
    final card = FightCardTemplate(
      id: _existingDocId ?? 'preview',
      creatorId: auth.currentUser?.uid ?? 'anonymous',
      creatorName: auth.userModel?.displayName ?? 'Unknown',
      eventName: _eventNameCtrl.text.trim().isEmpty
          ? 'Untitled Event'
          : _eventNameCtrl.text.trim(),
      promotionName: _promotionCtrl.text.trim(),
      venue: _venueCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      country: _country,
      eventDate: _eventDate,
      sportType: _sportType,
      sanctioningBody: _sanctionCtrl.text.trim(),
      bouts: _bouts,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    context.push('/fight-card-preview', extra: card);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BOUT EDITOR CARD — one per bout
// ═════════════════════════════════════════════════════════════════════════════
class _BoutEditorCard extends StatefulWidget {
  final FightCardBout bout;
  final String sportType;
  final ValueChanged<FightCardBout> onChanged;
  final VoidCallback? onDelete;

  const _BoutEditorCard({
    required this.bout,
    required this.sportType,
    required this.onChanged,
    this.onDelete,
    super.key,
  });

  @override
  State<_BoutEditorCard> createState() => _BoutEditorCardState();
}

class _BoutEditorCardState extends State<_BoutEditorCard> {
  late TextEditingController _redNameCtrl;
  late TextEditingController _blueNameCtrl;
  late TextEditingController _redGymCtrl;
  late TextEditingController _blueGymCtrl;
  late TextEditingController _redRecordCtrl;
  late TextEditingController _blueRecordCtrl;
  late TextEditingController _titleCtrl;

  @override
  void initState() {
    super.initState();
    _redNameCtrl = TextEditingController(text: widget.bout.redCornerName);
    _blueNameCtrl = TextEditingController(text: widget.bout.blueCornerName);
    _redGymCtrl = TextEditingController(text: widget.bout.redCornerGym);
    _blueGymCtrl = TextEditingController(text: widget.bout.blueCornerGym);
    _redRecordCtrl = TextEditingController(text: widget.bout.redCornerRecord);
    _blueRecordCtrl = TextEditingController(text: widget.bout.blueCornerRecord);
    _titleCtrl = TextEditingController(text: widget.bout.titleFight ?? '');
  }

  @override
  void dispose() {
    _redNameCtrl.dispose();
    _blueNameCtrl.dispose();
    _redGymCtrl.dispose();
    _blueGymCtrl.dispose();
    _redRecordCtrl.dispose();
    _blueRecordCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      widget.bout.copyWith(
        redCornerName: _redNameCtrl.text,
        blueCornerName: _blueNameCtrl.text,
        redCornerGym: _redGymCtrl.text,
        blueCornerGym: _blueGymCtrl.text,
        redCornerRecord: _redRecordCtrl.text,
        blueCornerRecord: _blueRecordCtrl.text,
        titleFight: _titleCtrl.text.isEmpty ? null : _titleCtrl.text,
      ),
    );
  }

  Color get _posColor {
    if (widget.bout.position == BoutPosition.mainEvent) {
      return const Color(0xFFFFD700);
    }
    if (widget.bout.position == BoutPosition.semiMain) {
      return AppTheme.neonOrange;
    }
    return AppTheme.neonCyan;
  }

  @override
  Widget build(BuildContext context) {
    final bout = widget.bout;
    final weightClasses = _getWeightClasses();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: _posColor),
            Expanded(
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded:
                      bout.position == BoutPosition.mainEvent ||
                      bout.position == BoutPosition.semiMain,
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  childrenPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Icon(Icons.sports_mma, color: _posColor, size: 20),
                  title: Text(
                    bout.position.label,
                    style: TextStyle(
                      color: _posColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                  subtitle: Text(
                    bout.redCornerName.isEmpty && bout.blueCornerName.isEmpty
                        ? 'TBA vs TBA'
                        : '${bout.redCornerName.isEmpty ? "TBA" : bout.redCornerName} vs ${bout.blueCornerName.isEmpty ? "TBA" : bout.blueCornerName}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  trailing: widget.onDelete != null
                      ? IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: AppTheme.error,
                            size: 20,
                          ),
                          onPressed: widget.onDelete,
                        )
                      : null,
                  children: [
                    // Position selector
                    DropdownButtonFormField<BoutPosition>(
                      initialValue: bout.position,
                      dropdownColor: AppTheme.cardBackground,
                      decoration: _decor('Bout Position'),
                      style: const TextStyle(color: Colors.white),
                      items: BoutPosition.values
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          widget.onChanged(bout.copyWith(position: v));
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Title fight
                    if (bout.position == BoutPosition.mainEvent ||
                        bout.position == BoutPosition.superfight)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          controller: _titleCtrl,
                          style: const TextStyle(color: Color(0xFFFFD700)),
                          decoration: _decor(
                            'Title / Championship',
                            hint: 'e.g. DFC Lightweight Title',
                          ),
                          onChanged: (_) => _emit(),
                        ),
                      ),

                    // Red corner
                    Row(
                      children: [
                        Expanded(
                          child: _cornerHeader('RED CORNER', Colors.redAccent),
                        ),
                        _findFighterButton(Colors.redAccent, isRed: true),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _redNameCtrl,
                            style: const TextStyle(color: Colors.redAccent),
                            decoration: _decor('Fighter Name'),
                            onChanged: (_) => _emit(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
                          child: TextField(
                            controller: _redRecordCtrl,
                            style: const TextStyle(color: Colors.redAccent),
                            decoration: _decor('Record', hint: '5-1-0'),
                            onChanged: (_) => _emit(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _redGymCtrl,
                      style: TextStyle(
                        color: Colors.redAccent.withValues(alpha: 0.7),
                      ),
                      decoration: _decor('Gym / Trainer'),
                      onChanged: (_) => _emit(),
                    ),
                    const SizedBox(height: 16),

                    // Blue corner
                    Row(
                      children: [
                        Expanded(
                          child: _cornerHeader(
                            'BLUE CORNER',
                            Colors.blueAccent,
                          ),
                        ),
                        _findFighterButton(Colors.blueAccent, isRed: false),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _blueNameCtrl,
                            style: const TextStyle(color: Colors.blueAccent),
                            decoration: _decor('Fighter Name'),
                            onChanged: (_) => _emit(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
                          child: TextField(
                            controller: _blueRecordCtrl,
                            style: const TextStyle(color: Colors.blueAccent),
                            decoration: _decor('Record', hint: '3-0-0'),
                            onChanged: (_) => _emit(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _blueGymCtrl,
                      style: TextStyle(
                        color: Colors.blueAccent.withValues(alpha: 0.7),
                      ),
                      decoration: _decor('Gym / Trainer'),
                      onChanged: (_) => _emit(),
                    ),
                    const SizedBox(height: 16),

                    // Weight class + Rounds + Rules
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: bout.weightClass.isEmpty
                                ? null
                                : bout.weightClass,
                            dropdownColor: AppTheme.cardBackground,
                            decoration: _decor('Weight Class'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            isExpanded: true,
                            items: weightClasses
                                .map(
                                  (w) => DropdownMenuItem(
                                    value: w,
                                    child: Text(w),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              widget.onChanged(
                                bout.copyWith(weightClass: v ?? ''),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: bout.rounds,
                            dropdownColor: AppTheme.cardBackground,
                            decoration: _decor('Rounds'),
                            style: const TextStyle(color: Colors.white),
                            items: [1, 2, 3, 4, 5, 6, 7, 8, 10, 12]
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r,
                                    child: Text('$r Rds'),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              widget.onChanged(bout.copyWith(rounds: v ?? 3));
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: bout.roundMinutes,
                            dropdownColor: AppTheme.cardBackground,
                            decoration: _decor('Mins/Rd'),
                            style: const TextStyle(color: Colors.white),
                            items: [1, 2, 3, 4, 5]
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text('$m min'),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              widget.onChanged(
                                bout.copyWith(roundMinutes: v ?? 3),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: bout.rules,
                            dropdownColor: AppTheme.cardBackground,
                            decoration: _decor('Rules'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            isExpanded: true,
                            items:
                                const [
                                      'Full Contact',
                                      'Amateur',
                                      'Pro',
                                      'K-1',
                                      'Modified',
                                      'Exhibition',
                                    ]
                                    .map(
                                      (r) => DropdownMenuItem(
                                        value: r,
                                        child: Text(r),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) {
                              widget.onChanged(
                                bout.copyWith(rules: v ?? 'Full Contact'),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cornerHeader(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  InputDecoration _decor(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
    hintStyle: TextStyle(
      color: AppTheme.textMuted.withValues(alpha: 0.4),
      fontSize: 12,
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
  );

  List<String> _getWeightClasses() {
    if (widget.sportType == 'Boxing') return AppConstants.boxingWeightClasses;
    return AppConstants.mmaWeightClasses;
  }

  /// "Find Fighter" button that opens the Fight Matcher in pick mode
  Widget _findFighterButton(Color color, {required bool isRed}) {
    return TextButton.icon(
      icon: Icon(Icons.person_search, color: color, size: 16),
      label: Text(
        'FIND',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () async {
        final result = await context.push<MatchResult>(
          '/fight-matcher',
          extra: {
            'pickMode': true,
            'presetWeightClass': widget.bout.weightClass.isNotEmpty
                ? widget.bout.weightClass
                : null,
            'presetSportType': widget.bout.sportType,
          },
        );
        if (result != null) {
          setState(() {
            if (isRed) {
              _redNameCtrl.text = result.name;
              _redRecordCtrl.text = result.record;
              _redGymCtrl.text = result.gym;
            } else {
              _blueNameCtrl.text = result.name;
              _blueRecordCtrl.text = result.record;
              _blueGymCtrl.text = result.gym;
            }
          });
          _emit();
        }
      },
    );
  }
}
