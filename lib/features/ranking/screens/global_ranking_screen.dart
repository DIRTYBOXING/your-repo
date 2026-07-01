import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/global_ranking_service.dart';

/// Global Ranking Screen — DFC live leaderboard with sport/weight-class filters,
/// sort toggle, and on-demand score recomputation.
class GlobalRankingScreen extends StatefulWidget {
  const GlobalRankingScreen({super.key});

  @override
  State<GlobalRankingScreen> createState() => _GlobalRankingScreenState();
}

class _GlobalRankingScreenState extends State<GlobalRankingScreen> {
  final GlobalRankingService _svc = GlobalRankingService();

  // ── Filter state ────────────────────────────────────────────────────────────
  String _sportFilter = 'All';
  String _weightFilter = 'All';
  String _genderFilter = 'All';
  String _sortBy = 'Global'; // 'Global' | 'Hype' | 'Momentum' | 'Record'

  static const List<String> _sports = [
    'All',
    'MMA',
    'Boxing',
    'Bare Knuckle',
    'Kickboxing',
    'Muay Thai',
    'Brawling',
  ];

  static const List<String> _weights = [
    'All',
    'Strawweight',
    'Flyweight',
    'Bantamweight',
    'Featherweight',
    'Lightweight',
    'Welterweight',
    'Middleweight',
    'Light Heavyweight',
    'Heavyweight',
  ];

  // ── Computed leaderboard ────────────────────────────────────────────────────
  List<GlobalRankEntry> get _filtered {
    var list = _svc.getDemoLeaderboard();
    if (_sportFilter != 'All') {
      list = list.where((e) => e.sport == _sportFilter).toList();
    }
    if (_weightFilter != 'All') {
      list = list.where((e) => e.weightClass == _weightFilter).toList();
    }
    if (_genderFilter == 'Women') {
      list = list.where((e) => e.gender == 'F').toList();
    } else if (_genderFilter == 'Men') {
      list = list.where((e) => e.gender == 'M').toList();
    }
    list = List.of(list)
      ..sort(
        (a, b) => switch (_sortBy) {
          'Hype' => b.hypeScore.compareTo(a.hypeScore),
          'Momentum' => b.momentumScore.compareTo(a.momentumScore),
          'Record' => (b.wins / (b.wins + b.losses + 1)).compareTo(
            a.wins / (a.wins + a.losses + 1),
          ),
          _ => b.globalScore.compareTo(a.globalScore),
        },
      );
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filtered;

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBackground,
        title: const Text(
          'Global Rankings',
          style: TextStyle(
            color: AppTheme.neonCyan,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.neonCyan),
      ),
      body: Column(
        children: [
          _buildGenderTabs(),
          _buildFilters(),
          Expanded(
            child: entries.isEmpty
                ? _buildEmpty()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      const SizedBox(height: 12),
                      _buildHeader(entries.length),
                      const SizedBox(height: 14),
                      ...entries.asMap().entries.map(
                        (e) => _buildRankCard(e.key + 1, e.value),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── Gender quick-filter tabs ────────────────────────────────────────────────

  Widget _buildGenderTabs() {
    return Container(
      color: const Color(0xFF050E1A),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _genderTab('All', null),
          const SizedBox(width: 8),
          _genderTab('Women', 'F'),
          const SizedBox(width: 8),
          _genderTab('Men', 'M'),
        ],
      ),
    );
  }

  Widget _genderTab(String label, String? gender) {
    final String filterVal = gender == null
        ? 'All'
        : (gender == 'F' ? 'Women' : 'Men');
    final bool active = _genderFilter == filterVal;
    final Color col = gender == 'F'
        ? const Color(0xFFFF69B4)
        : gender == 'M'
        ? AppTheme.neonCyan
        : Colors.white70;
    return GestureDetector(
      onTap: () => setState(() => _genderFilter = filterVal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? col.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? col : Colors.white12,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (gender == 'F')
              const Text(
                '♀ ',
                style: TextStyle(color: Color(0xFFFF69B4), fontSize: 13),
              ),
            if (gender == 'M')
              const Text(
                '♂ ',
                style: TextStyle(color: AppTheme.neonCyan, fontSize: 13),
              ),
            Text(
              label,
              style: TextStyle(
                color: active ? col : Colors.white54,
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter bar ──────────────────────────────────────────────────────────────

  Widget _buildFilters() {
    return Container(
      color: const Color(0xFF0A1628),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Sport filter
          Expanded(
            child: _dropdown('Sport', _sports, _sportFilter, (v) {
              if (v != null) setState(() => _sportFilter = v);
            }),
          ),
          const SizedBox(width: 8),
          // Weight class filter
          Expanded(
            child: _dropdown('Weight', _weights, _weightFilter, (v) {
              if (v != null) setState(() => _weightFilter = v);
            }),
          ),
          const SizedBox(width: 8),
          // Sort
          Expanded(
            child: _dropdown(
              'Sort',
              ['Global', 'Hype', 'Momentum', 'Record'],
              _sortBy,
              (v) {
                if (v != null) setState(() => _sortBy = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(
    String label,
    List<String> items,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 11),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppTheme.neonCyan.withValues(alpha: 0.25),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.neonCyan),
        ),
        filled: true,
        fillColor: const Color(0xFF0D1B2A),
      ),
      dropdownColor: const Color(0xFF0D1B2A),
      style: const TextStyle(color: Colors.white, fontSize: 12),
      icon: const Icon(Icons.expand_more, color: AppTheme.neonCyan, size: 16),
      items: items
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: onChanged,
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonMagenta.withValues(alpha: 0.12),
            AppTheme.neonCyan.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonMagenta.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: AppTheme.neonMagenta, size: 30),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DFC GLOBAL LEADERBOARD',
                style: TextStyle(
                  color: AppTheme.neonMagenta,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 1.4,
                ),
              ),
              Text(
                '$count fighters · sorted by $_sortBy score',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, color: Colors.white24, size: 48),
          const SizedBox(height: 12),
          const Text(
            'No fighters match these filters',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() {
              _sportFilter = 'All';
              _weightFilter = 'All';
              _genderFilter = 'All';
              _sortBy = 'Global';
            }),
            child: const Text(
              'Clear filters',
              style: TextStyle(color: AppTheme.neonCyan),
            ),
          ),
        ],
      ),
    );
  }

  // ── Rank card ───────────────────────────────────────────────────────────────

  Widget _buildRankCard(int rank, GlobalRankEntry entry) {
    final label = _svc.rankLabel(entry.globalScore);
    final labelColor = switch (label) {
      'ELITE' => AppTheme.neonMagenta,
      'TOP 10' => AppTheme.neonCyan,
      'RANKED' => AppTheme.neonGreen,
      'RISING' => Colors.orange,
      _ => Colors.white38,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rank == 1
              ? AppTheme.neonMagenta.withValues(alpha: 0.5)
              : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: rank == 1 ? AppTheme.neonMagenta : Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: rank == 1 ? 18 : 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    // Gender indicator
                    Text(
                      entry.gender == 'F' ? '♀' : '♂',
                      style: TextStyle(
                        color: entry.gender == 'F'
                            ? const Color(0xFFFF69B4)
                            : AppTheme.neonCyan,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (entry.isChampion)
                      const Icon(
                        Icons.military_tech,
                        color: AppTheme.neonMagenta,
                        size: 16,
                      )
                    else
                      const Icon(
                        Icons.trending_up,
                        color: AppTheme.neonGreen,
                        size: 16,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.sport} · ${entry.weightClass} · ${entry.region}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _scoreChip('HYPE', entry.hypeScore, AppTheme.neonCyan),
                    const SizedBox(width: 6),
                    _scoreChip('MOM', entry.momentumScore, AppTheme.neonGreen),
                    const SizedBox(width: 6),
                    _scoreChip('GLOBAL', entry.globalScore, labelColor),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(
                            text:
                                '${entry.name} — Global: ${entry.globalScore.toStringAsFixed(1)} Hype: ${entry.hypeScore.toStringAsFixed(1)} Mom: ${entry.momentumScore.toStringAsFixed(1)} (${entry.record})',
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied to clipboard'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.copy,
                        color: Colors.white24,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Rank label badge
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: labelColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: labelColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          // Record
          const SizedBox(width: 8),
          Text(
            entry.record,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreChip(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label ${value.toStringAsFixed(1)}',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
