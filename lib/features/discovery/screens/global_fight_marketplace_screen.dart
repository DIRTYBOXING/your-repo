import 'package:flutter/material.dart';
import '../../../shared/services/global_fight_discovery_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// GLOBAL FIGHT MARKETPLACE — Discovery + Matchmaking + Opportunities.
/// Connects: GlobalFightDiscoveryService → Explore Tab integration.
/// ═══════════════════════════════════════════════════════════════════════════

const _kBg = Color(0xFF060A14);
const _kPanel = Color(0xFF0C1226);
const _kBorder = Color(0xFF1A2744);
const _kCyan = Color(0xFF00E5FF);
const _kGold = Color(0xFFFFD740);
const _kMagenta = Color(0xFFE040FB);
const _kGreen = Color(0xFF00E676);
const _kOrange = Color(0xFFFF9100);
const _kRed = Color(0xFFFF1744);

class GlobalFightMarketplaceScreen extends StatefulWidget {
  const GlobalFightMarketplaceScreen({super.key});

  @override
  State<GlobalFightMarketplaceScreen> createState() =>
      _GlobalFightMarketplaceScreenState();
}

class _GlobalFightMarketplaceScreenState
    extends State<GlobalFightMarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final GlobalFightDiscoveryService _discovery = GlobalFightDiscoveryService();
  String _selectedDiscipline = 'All';

  final _disciplines = [
    'All',
    'MMA',
    'Boxing',
    'Muay Thai',
    'BJJ',
    'Kickboxing',
    'Bare Knuckle',
    'BKFC',
    'Brawling',
    'Wrestling',
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('GLOBAL FIGHT MARKETPLACE'),
        backgroundColor: _kBg,
        foregroundColor: _kCyan,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _kCyan,
          labelColor: _kCyan,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'FIGHTERS'),
            Tab(text: 'EVENTS'),
            Tab(text: 'OPPORTUNITIES'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildDisciplineFilter(),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildFightersTab(),
                _buildEventsTab(),
                _buildOpportunitiesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisciplineFilter() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: _disciplines.map((d) {
          final sel = d == _selectedDiscipline;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _selectedDiscipline = d),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: sel ? _kCyan.withValues(alpha: 0.2) : _kPanel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sel ? _kCyan : _kBorder),
                ),
                child: Text(
                  d,
                  style: TextStyle(
                    color: sel ? _kCyan : Colors.white54,
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFightersTab() {
    final total = _discovery.totalFighters;
    final opps = _discovery.totalOpportunities;
    // header
    final header = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kCyan.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statChip('Fighters', '$total', _kCyan),
          _statChip('Opportunities', '$opps', _kGold),
          _statChip('Searches', '${_discovery.totalSearches}', _kMagenta),
        ],
      ),
    );
    final fighters = [
      const _FighterCard(
        'Alex "The Machine" Volkov',
        'MMA · 185 lbs',
        'Melbourne, AU',
        '14-3-0',
        _kCyan,
      ),
      const _FighterCard(
        'Maria Santos',
        'Muay Thai · 125 lbs',
        'São Paulo, BR',
        '22-5-0',
        _kMagenta,
      ),
      const _FighterCard(
        'Jake "Iron Fist" Torres',
        'Boxing · 154 lbs',
        'Las Vegas, US',
        '18-1-0',
        _kGold,
      ),
      const _FighterCard(
        'Yuki Tanaka',
        'MMA · 145 lbs',
        'Tokyo, JP',
        '9-2-0',
        _kGreen,
      ),
      const _FighterCard(
        'Omar "The Bear" Karimi',
        'Wrestling · 205 lbs',
        'Tehran, IR',
        '11-0-0',
        _kOrange,
      ),
      const _FighterCard(
        'Sarah "Knuckles" Chen',
        'BKFC · 135 lbs',
        'Hong Kong',
        '7-1-0',
        _kRed,
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: fighters.length + 1,
      itemBuilder: (context, i) =>
          i == 0 ? header : _buildFighterRow(fighters[i - 1]),
    );
  }

  Widget _buildFighterRow(_FighterCard f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: f.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: f.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(Icons.sports_mma, color: f.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  f.discipline,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                Text(
                  f.location,
                  style: TextStyle(color: f.color, fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              f.record,
              style: const TextStyle(
                color: _kGreen,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    final events = [
      const _EventCard('DFC 15: Clash Down Under', 'Mar 22 · Sydney, AU', 8, _kGold),
      const _EventCard('Underground BKFC 4', 'Apr 5 · Las Vegas, US', 6, _kRed),
      const _EventCard('Asia Pacific MMA Series', 'Apr 18 · Tokyo, JP', 10, _kCyan),
      const _EventCard(
        'European Kickboxing GP',
        'May 2 · Amsterdam, NL',
        12,
        _kOrange,
      ),
      const _EventCard(
        'South American Fight Night',
        'May 15 · São Paulo, BR',
        7,
        _kMagenta,
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: events.length,
      itemBuilder: (context, i) {
        final e = events[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kPanel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: e.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.event, color: e.color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      e.details,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: e.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${e.fights} fights',
                  style: TextStyle(
                    color: e.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOpportunitiesTab() {
    final opps = [
      const _OppCard(
        'Main Event Slot',
        'DFC 15 needs 185lb headliner',
        _kGold,
        'URGENT',
      ),
      const _OppCard(
        'Short Notice Fight',
        'Replacement needed — 145lb — Mar 10',
        _kRed,
        'HOT',
      ),
      const _OppCard(
        'Exhibition Match',
        'Charity event — any weight',
        _kGreen,
        'OPEN',
      ),
      const _OppCard(
        'Sparring Partner',
        'Pro camp needs sparring for title prep',
        _kCyan,
        'AVAILABLE',
      ),
      const _OppCard(
        'Undercard Fill',
        'Asia Pacific card needs 3 fighters',
        _kOrange,
        'RECRUITING',
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: opps.length,
      itemBuilder: (context, i) {
        final o = opps[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kPanel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: o.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      o.description,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: o.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: o.color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  o.tag,
                  style: TextStyle(
                    color: o.color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }
}

class _FighterCard {
  final String name;
  final String discipline;
  final String location;
  final String record;
  final Color color;
  const _FighterCard(
    this.name,
    this.discipline,
    this.location,
    this.record,
    this.color,
  );
}

class _EventCard {
  final String name;
  final String details;
  final int fights;
  final Color color;
  const _EventCard(this.name, this.details, this.fights, this.color);
}

class _OppCard {
  final String title;
  final String description;
  final Color color;
  final String tag;
  const _OppCard(this.title, this.description, this.color, this.tag);
}
