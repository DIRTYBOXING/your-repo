import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/services/fight_matcher_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT MATCHER SCREEN — Smart Fighter Matching
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Search the fighter databank by weight, record, style, location.
/// Scored results show compatibility percentage.
/// Select a fighter to auto-fill a fight card bout.
///
/// Can be opened standalone or as a picker from the Fight Card Builder.
///
/// ═══════════════════════════════════════════════════════════════════════════
class FightMatcherScreen extends StatefulWidget {
  /// If non-null, we're picking a fighter to fill a bout slot.
  /// The result is popped back via Navigator.pop(context, MatchResult).
  final bool pickMode;

  /// Pre-fill weight class from the bout being filled
  final String? presetWeightClass;
  final String? presetSportType;

  const FightMatcherScreen({
    this.pickMode = false,
    this.presetWeightClass,
    this.presetSportType,
    super.key,
  });

  @override
  State<FightMatcherScreen> createState() => _FightMatcherScreenState();
}

class _FightMatcherScreenState extends State<FightMatcherScreen> {
  final _searchCtrl = TextEditingController();

  // Filters
  String? _weightClass;
  String _sportType = 'MMA';
  String? _country;
  bool _lastMinuteOnly = false;
  bool _willingToTravel = false;

  // Experience filter
  int? _minWins;
  int? _maxWins;

  bool _showFilters = true;

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
  ];

  @override
  void initState() {
    super.initState();
    if (widget.presetWeightClass != null) {
      _weightClass = widget.presetWeightClass;
    }
    if (widget.presetSportType != null) {
      _sportType = widget.presetSportType!;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: Text(
          widget.pickMode ? 'FIND FIGHTER' : 'FIGHT MATCHER',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: AppTheme.secondaryBackground,
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: AppTheme.neonCyan,
            ),
            tooltip: _showFilters ? 'Hide Filters' : 'Show Filters',
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ─────────────────────────────────────────
          Container(
            color: AppTheme.secondaryBackground,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by fighter name...',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textMuted),
                        onPressed: () {
                          _searchCtrl.clear();
                          context.read<FightMatcherService>().clearResults();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _searchByName,
            ),
          ),

          // ── Filters panel ──────────────────────────────────────
          if (_showFilters) _buildFiltersPanel(),

          // ── Action buttons ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text(
                      'FIND MATCHES',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: _runMatchSearch,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.flash_on, size: 18),
                    label: const Text(
                      'LAST MINUTE',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.neonOrange,
                      side: const BorderSide(color: AppTheme.neonOrange),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: _runLastMinuteSearch,
                  ),
                ),
              ],
            ),
          ),

          // ── Results ────────────────────────────────────────────
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILTERS PANEL
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFiltersPanel() {
    final weightClasses = _sportType == 'Boxing'
        ? AppConstants.boxingWeightClasses
        : AppConstants.mmaWeightClasses;

    return Container(
      color: AppTheme.secondaryBackground.withValues(alpha: 0.6),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              // Weight class
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _weightClass,
                  dropdownColor: AppTheme.cardBackground,
                  decoration: _filterDecor('Weight Class'),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(child: Text('Any')),
                    ...weightClasses.map(
                      (w) => DropdownMenuItem(value: w, child: Text(w)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _weightClass = v),
                ),
              ),
              const SizedBox(width: 10),
              // Sport type
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _sportType,
                  dropdownColor: AppTheme.cardBackground,
                  decoration: _filterDecor('Sport'),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: AppConstants.sportTypes
                      .where((s) => s != 'Run It')
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _sportType = v ?? 'MMA';
                    _weightClass = null; // reset when sport changes
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Country
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _country,
                  dropdownColor: AppTheme.cardBackground,
                  decoration: _filterDecor('Country'),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(child: Text('Any')),
                    ..._countries.map(
                      (c) => DropdownMenuItem(value: c, child: Text(c)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _country = v),
                ),
              ),
              const SizedBox(width: 10),
              // Win range
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _minWins?.toString(),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: _filterDecor('Min Wins'),
                        onChanged: (v) => _minWins = int.tryParse(v),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextFormField(
                        initialValue: _maxWins?.toString(),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: _filterDecor('Max Wins'),
                        onChanged: (v) => _maxWins = int.tryParse(v),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _filterChip(
                'Willing to Travel',
                _willingToTravel,
                (v) => setState(() => _willingToTravel = v),
              ),
              const SizedBox(width: 10),
              _filterChip(
                'Last Minute Only',
                _lastMinuteOnly,
                (v) => setState(() => _lastMinuteOnly = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool value, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: value ? Colors.black : AppTheme.textSecondary,
        ),
      ),
      selected: value,
      onSelected: onChanged,
      selectedColor: AppTheme.neonCyan,
      backgroundColor: AppTheme.cardBackground,
      checkmarkColor: Colors.black,
      visualDensity: VisualDensity.compact,
    );
  }

  InputDecoration _filterDecor(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // RESULTS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildResults() {
    return Consumer<FightMatcherService>(
      builder: (context, svc, _) {
        if (svc.searching) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.neonCyan),
                SizedBox(height: 16),
                Text(
                  'Scanning fighter database...',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ],
            ),
          );
        }

        if (svc.results.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_outline, size: 64, color: AppTheme.textMuted),
                const SizedBox(height: 16),
                Text(
                  svc.lastCriteria != null
                      ? 'No fighters found matching your criteria'
                      : 'Set filters and tap FIND MATCHES',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                if (svc.lastCriteria != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Try broader filters or enable "Willing to Travel"',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: svc.results.length,
          itemBuilder: (context, i) => _buildMatchCard(svc.results[i]),
        );
      },
    );
  }

  Widget _buildMatchCard(MatchResult match) {
    final scoreColor = match.score >= 70
        ? AppTheme.neonGreen
        : match.score >= 40
        ? AppTheme.neonOrange
        : AppTheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scoreColor.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: widget.pickMode ? () => Navigator.pop(context, match) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: name, score
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.surfaceColor,
                    child: Text(
                      match.name.isNotEmpty ? match.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppTheme.neonCyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (match.nickname.isNotEmpty)
                          Text(
                            '"${match.nickname}"',
                            style: TextStyle(
                              color: AppTheme.neonCyan.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Match score
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: scoreColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '${match.score.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Stats row
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _statChip(Icons.emoji_events, match.record, Colors.white),
                  _statChip(
                    Icons.fitness_center,
                    match.weightClass,
                    AppTheme.neonCyan,
                  ),
                  _statChip(
                    Icons.sports_mma,
                    match.sportType,
                    AppTheme.neonOrange,
                  ),
                  if (match.city.isNotEmpty)
                    _statChip(
                      Icons.location_on,
                      '${match.city}, ${match.country}',
                      AppTheme.textSecondary,
                    ),
                  if (match.stance.isNotEmpty)
                    _statChip(
                      Icons.swap_horiz,
                      match.stance,
                      AppTheme.neonPurple,
                    ),
                  if (match.willingToTravel)
                    _statChip(Icons.flight, 'Will Travel', AppTheme.neonGreen),
                ],
              ),

              // Match reasons
              if (match.matchReasons.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: match.matchReasons
                      .map(
                        (r) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: scoreColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            r,
                            style: TextStyle(
                              color: scoreColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],

              // Notes
              if (match.matchupNotes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Note: ${match.matchupNotes}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              // Pick mode button
              if (widget.pickMode) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('SELECT FIGHTER'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => Navigator.pop(context, match),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════
  void _runMatchSearch() {
    final svc = context.read<FightMatcherService>();
    svc.findMatches(
      MatchCriteria(
        weightClass: _weightClass,
        sportType: _sportType,
        country: _country,
        minWins: _minWins,
        maxWins: _maxWins,
        onlyWillingToTravel: _willingToTravel,
        lastMinuteOnly: _lastMinuteOnly,
      ),
    );
  }

  void _runLastMinuteSearch() {
    final svc = context.read<FightMatcherService>();
    svc.findLastMinuteReplacements(
      weightClass: _weightClass ?? '',
      sportType: _sportType,
    );
  }

  void _searchByName(String query) {
    final svc = context.read<FightMatcherService>();
    svc.searchByName(query);
  }
}
