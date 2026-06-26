import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/global_seo_service.dart';

/// Global SEO Engine Screen — preview and copy SEO metadata for fighters, gyms, and events.
/// Powered by GlobalSeoService. Wire to HTML head injection for web.
class GlobalSeoScreen extends StatefulWidget {
  const GlobalSeoScreen({super.key});

  @override
  State<GlobalSeoScreen> createState() => _GlobalSeoScreenState();
}

class _GlobalSeoScreenState extends State<GlobalSeoScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _svc = GlobalSeoService();

  // Demo data — replace with live Firestore reads when wired
  late final List<_SeoEntry> _fighters;
  late final List<_SeoEntry> _gyms;
  late final List<_SeoEntry> _events;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);

    _fighters = [
      _SeoEntry(
        label: 'Christine Ferea',
        subtitle: 'Bare Knuckle · Women\'s Heavyweight',
        emoji: '🥊',
        meta: _svc.forFighter(
          name: 'Christine Ferea',
          weightClass: 'Women\'s Heavyweight',
          sport: 'Bare Knuckle',
          wins: 10,
          losses: 0,
          countryCode: 'AU',
          fighterId: 'ferea-001',
        ),
      ),
      _SeoEntry(
        label: 'Stamp Fairtex',
        subtitle: 'Muay Thai / MMA · Women\'s Atomweight',
        emoji: '🇹🇭',
        meta: _svc.forFighter(
          name: 'Stamp Fairtex',
          weightClass: 'Atomweight',
          sport: 'MMA',
          wins: 18,
          losses: 3,
          countryCode: 'TH',
          fighterId: 'stamp-001',
        ),
      ),
      _SeoEntry(
        label: 'Logan DFC',
        subtitle: 'MMA · Dragon Heritage Champion',
        emoji: '🐉',
        meta: _svc.forFighter(
          name: 'Logan DFC',
          weightClass: 'Lightweight',
          sport: 'MMA',
          wins: 14,
          losses: 2,
          countryCode: 'AU',
          fighterId: 'logan-001',
        ),
      ),
      _SeoEntry(
        label: 'Israel Adesanya',
        subtitle: 'MMA · Middleweight',
        emoji: '🇳🇿',
        meta: _svc.forFighter(
          name: 'Israel Adesanya',
          weightClass: 'Middleweight',
          sport: 'MMA',
          wins: 24,
          losses: 4,
          countryCode: 'NZ',
        ),
      ),
    ];

    _gyms = [
      _SeoEntry(
        label: 'City Kickboxing',
        subtitle: 'Auckland, NZ · MMA / Kickboxing',
        emoji: '🥋',
        meta: _svc.forGym(
          gymName: 'City Kickboxing',
          city: 'Auckland',
          country: 'New Zealand',
          sports: ['MMA', 'Kickboxing', 'BJJ'],
        ),
      ),
      _SeoEntry(
        label: 'Evolve MMA',
        subtitle: 'Singapore · Multi-discipline',
        emoji: '🇸🇬',
        meta: _svc.forGym(
          gymName: 'Evolve MMA',
          city: 'Singapore',
          country: 'Singapore',
          sports: ['MMA', 'Muay Thai', 'BJJ', 'Boxing'],
        ),
      ),
      _SeoEntry(
        label: 'DFC Training Centre',
        subtitle: 'Brisbane, AU · Combat Sports Hub',
        emoji: '🇦🇺',
        meta: _svc.forGym(
          gymName: 'DFC Training Centre',
          city: 'Brisbane',
          country: 'Australia',
          sports: ['MMA', 'Brawling', 'BKFC', 'Boxing'],
        ),
      ),
    ];

    _events = [
      _SeoEntry(
        label: 'IBC IV — Gold Coast',
        subtitle: 'MMA · April 2026',
        emoji: '🏆',
        meta: _svc.forEvent(
          eventName: 'IBC IV Gold Coast',
          promoter: 'DFC',
          location: 'Gold Coast, Australia',
          date: DateTime(2026, 4, 18),
          headliners: ['Logan DFC', 'Matagi Toa'],
        ),
      ),
      _SeoEntry(
        label: 'BKFC Knucklemania',
        subtitle: 'Bare Knuckle · Brisbane',
        emoji: '✊',
        meta: _svc.forEvent(
          eventName: 'BKFC Knucklemania',
          promoter: 'Bare Knuckle FC',
          location: 'Brisbane, Australia',
          date: DateTime(2026, 5, 3),
          headliners: ['Christine Ferea', 'Paige VanZant'],
        ),
      ),
      _SeoEntry(
        label: 'Eternal MMA 81',
        subtitle: 'MMA · Brisbane',
        emoji: '🌀',
        meta: _svc.forEvent(
          eventName: 'Eternal MMA 81',
          promoter: 'Eternal MMA',
          location: 'Brisbane, Australia',
          date: DateTime(2026, 6, 7),
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBackground,
        title: const Text(
          'Global SEO Engine',
          style: TextStyle(
            color: AppTheme.neonCyan,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.neonCyan),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppTheme.neonCyan,
          labelColor: AppTheme.neonCyan,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'FIGHTERS'),
            Tab(text: 'GYMS'),
            Tab(text: 'EVENTS'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildList(_fighters),
                _buildList(_gyms),
                _buildList(_events),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonMagenta.withValues(alpha: 0.08),
            AppTheme.neonCyan.withValues(alpha: 0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppTheme.neonCyan.withValues(alpha: 0.15)),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.travel_explore, color: AppTheme.neonCyan, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Auto-generated SEO metadata for fighters, gyms, and events. '
              'Wires to HTML head injection for global search visibility.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<_SeoEntry> entries) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [...entries.map(_buildSeoCard), const SizedBox(height: 24)],
    );
  }

  Widget _buildSeoCard(_SeoEntry entry) {
    final m = entry.meta;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Text(entry.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        entry.subtitle,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.neonGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.neonGreen.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Text(
                    'SEO READY',
                    style: TextStyle(
                      color: AppTheme.neonGreen,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          // Meta fields
          _metaRow('Title', m.title, AppTheme.neonCyan),
          const Divider(height: 1, color: Colors.white10),
          _metaRow('Description', m.description, Colors.white70),
          const Divider(height: 1, color: Colors.white10),
          _metaRow('OG Title', m.ogTitle, AppTheme.neonMagenta),
          const Divider(height: 1, color: Colors.white10),
          // Keywords
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.label,
                      size: 12,
                      color: AppTheme.neonOrange,
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'KEYWORDS',
                      style: TextStyle(
                        color: AppTheme.neonOrange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _copy(m.keywords.join(', '), 'Keywords'),
                      child: const Icon(
                        Icons.copy,
                        size: 13,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: m.keywords.map(_buildKeywordChip).toList(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          // Canonical URL
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Row(
              children: [
                const Icon(Icons.link, size: 12, color: Colors.white38),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    m.canonicalUrl,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _copy(m.canonicalUrl, 'URL'),
                  child: const Icon(
                    Icons.copy,
                    size: 13,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _copy(value, label),
                child: const Icon(Icons.copy, size: 13, color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(color: color, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildKeywordChip(String kw) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.neonOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.neonOrange.withValues(alpha: 0.25)),
      ),
      child: Text(
        kw,
        style: const TextStyle(
          color: AppTheme.neonOrange,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SeoEntry {
  final String label;
  final String subtitle;
  final String emoji;
  final SeoMeta meta;

  const _SeoEntry({
    required this.label,
    required this.subtitle,
    required this.emoji,
    required this.meta,
  });
}
