import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/router_constants.dart' as rc;
import '../../../core/theme/design_tokens.dart';

/// Admin Event Manager — Create, manage, and promote events.
/// Status pipeline: DRAFT → LIVE → ARCHIVED
/// Promo assets, region assignment, watch links, card builder.
class AdminEventManagerScreen extends StatefulWidget {
  const AdminEventManagerScreen({super.key});

  @override
  State<AdminEventManagerScreen> createState() =>
      _AdminEventManagerScreenState();
}

class _AdminEventManagerScreenState extends State<AdminEventManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _statusFilter = 'ALL';

  static const _events = [
    _EventData(
      'BKFC Fight Night Australia',
      'Apr 18, 2026',
      'Townsville Entertainment Centre',
      'LIVE',
      'BKFC',
      'Townsville',
      ['Haze Hepi vs Wisniewski', 'BK Bau vs TBA', 'Undercard x3'],
      'https://bfrb.tv/bkfc-australia',
    ),
    _EventData(
      'Logan Fight Night V',
      'May 10, 2026',
      'Logan Metro Indoor Sports Centre',
      'DRAFT',
      'DFC / Island Warriors',
      'Logan',
      ['Main Event TBA', 'Co-Main TBA'],
      '',
    ),
    _EventData(
      'Brisbane Brawl III',
      'Jun 7, 2026',
      'Nissan Arena, Brisbane',
      'DRAFT',
      'DFC',
      'Brisbane',
      ['Main Event TBA'],
      '',
    ),
    _EventData(
      'DFC Bronx Islanders Showcase',
      'Jul 12, 2026',
      'St. Mary\'s Park, Bronx',
      'DRAFT',
      'DFC / Bronx Islanders',
      'Bronx Islanders',
      ['TBA'],
      '',
    ),
    _EventData(
      'BKFC 72: USA Card',
      'Mar 8, 2026',
      'Biloxi Civic Center',
      'ARCHIVED',
      'BKFC',
      'USA',
      ['Main Event: Harris vs Cruz'],
      'https://bfrb.tv/bkfc-72',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<_EventData> get _filtered => _statusFilter == 'ALL'
      ? _events
      : _events.where((e) => e.status == _statusFilter).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Text(
          'EVENT MANAGER',
          style: TextStyle(
            color: DesignTokens.neonCyan,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(
                Icons.add,
                color: DesignTokens.neonGreen,
                size: 16,
              ),
              label: const Text(
                'CREATE EVENT',
                style: TextStyle(
                  color: DesignTokens.neonGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: DesignTokens.neonCyan,
          labelColor: DesignTokens.neonCyan,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 1.0,
          ),
          tabs: const [
            Tab(text: 'ALL EVENTS'),
            Tab(text: 'PROMO ASSETS'),
            Tab(text: 'ANALYTICS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildEventsTab(), _buildPromoTab(), _buildAnalyticsTab()],
      ),
    );
  }

  // ── Events Tab ──

  Widget _buildEventsTab() {
    return Column(
      children: [
        // Status filter strip
        Container(
          height: 50,
          color: DesignTokens.bgSecondary,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            children: [
              for (final s in ['ALL', 'LIVE', 'DRAFT', 'ARCHIVED'])
                _filterChip(s),
            ],
          ),
        ),
        // Events list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filtered.length,
            itemBuilder: (context, index) => _buildEventCard(_filtered[index]),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label) {
    final selected = _statusFilter == label;
    final color = switch (label) {
      'LIVE' => DesignTokens.neonGreen,
      'DRAFT' => DesignTokens.neonAmber,
      'ARCHIVED' => Colors.white38,
      _ => DesignTokens.neonCyan,
    };
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.3) : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : Colors.white38,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(_EventData event) {
    final statusColor = switch (event.status) {
      'LIVE' => DesignTokens.neonGreen,
      'DRAFT' => DesignTokens.neonAmber,
      _ => Colors.white38,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.event, color: statusColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${event.date} · ${event.venue}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    event.status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Event details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _metaChip(
                  Icons.sports_mma,
                  event.promotion,
                  DesignTokens.neonMagenta,
                ),
                const SizedBox(width: 8),
                _metaChip(
                  Icons.location_city,
                  event.region,
                  DesignTokens.neonGreen,
                ),
              ],
            ),
          ),
          // Fight card preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FIGHT CARD',
                  style: TextStyle(
                    color: Colors.white24,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                for (final bout in event.card)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sports_mma,
                          color: DesignTokens.neonCyan.withValues(alpha: 0.4),
                          size: 12,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          bout,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Watch link
          if (event.watchUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    color: DesignTokens.neonRed.withValues(alpha: 0.6),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      event.watchUrl,
                      style: TextStyle(
                        color: DesignTokens.neonRed.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          // Action row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _actionBtn('EDIT', DesignTokens.neonCyan, Icons.edit_outlined),
                const SizedBox(width: 8),
                _actionBtn('PROMOTE', DesignTokens.neonGold, Icons.campaign),
                const SizedBox(width: 8),
                if (event.status == 'DRAFT')
                  _actionBtn('PUBLISH', DesignTokens.neonGreen, Icons.publish),
                if (event.status == 'LIVE')
                  _actionBtn('ARCHIVE', Colors.white38, Icons.archive_outlined),
                const Spacer(),
                _actionBtn(
                  'OPEN CARD BUILDER',
                  DesignTokens.neonMagenta,
                  Icons.view_list,
                  onTap: () {
                    context.push(rc.RouteConstants.eventManagerPath);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Promo Assets Tab ──

  Widget _buildPromoTab() {
    final assets = [
      (
        'BKFC Australia Poster',
        'Image',
        'Scheduled Apr 10',
        DesignTokens.neonGold,
      ),
      ('Hepi Hype Video', 'Video', 'Published', DesignTokens.neonGreen),
      ('Logan Fight Night Banner', 'Image', 'Draft', DesignTokens.neonAmber),
      ('Brisbane Brawl Social Card', 'Image', 'Draft', DesignTokens.neonAmber),
      ('Islanders Support Reel', 'Video', 'In Review', DesignTokens.neonCyan),
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final a = assets[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: a.$4.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: a.$4.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  a.$2 == 'Video' ? Icons.videocam : Icons.image,
                  color: a.$4,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.$1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${a.$2} · ${a.$3}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: a.$4.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  a.$3.split(' ').last.toUpperCase(),
                  style: TextStyle(
                    color: a.$4,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Analytics Tab ──

  Widget _buildAnalyticsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'EVENT PERFORMANCE',
          style: TextStyle(
            color: DesignTokens.neonCyan,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _statCard('TOTAL EVENTS', '5', DesignTokens.neonCyan),
            _statCard('LIVE', '1', DesignTokens.neonGreen),
            _statCard('DRAFTS', '3', DesignTokens.neonAmber),
            _statCard('PPV CLICKS', '2.4K', DesignTokens.neonRed),
            _statCard('PROMO REACH', '18K', DesignTokens.neonGold),
            _statCard('ENGAGEMENT', '6.2%', DesignTokens.neonMagenta),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'TOP PERFORMING',
          style: TextStyle(
            color: DesignTokens.neonCyan,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 12),
        _perfRow('BKFC Fight Night Australia', '2.4K clicks', '89%'),
        _perfRow('Logan Fight Night IV', '1.2K clicks', '72%'),
        _perfRow('Brisbane Brawl II', '890 clicks', '65%'),
      ],
    );
  }

  // ── Shared Widgets ──

  Widget _metaChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color.withValues(alpha: 0.6), size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
    String label,
    Color color,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
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
                fontWeight: FontWeight.w800,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return SizedBox(
      width: 140,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _perfRow(String title, String metric, String rate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            metric,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: DesignTokens.neonGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              rate,
              style: const TextStyle(
                color: DesignTokens.neonGreen,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventData {
  final String title;
  final String date;
  final String venue;
  final String status;
  final String promotion;
  final String region;
  final List<String> card;
  final String watchUrl;
  const _EventData(
    this.title,
    this.date,
    this.venue,
    this.status,
    this.promotion,
    this.region,
    this.card,
    this.watchUrl,
  );
}
