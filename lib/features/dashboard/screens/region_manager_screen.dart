import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

/// Region Manager — Admin screen for managing all DFC regions.
/// Tabs: Overview | Feed | Events | Gyms | Members | Settings
class RegionManagerScreen extends StatefulWidget {
  const RegionManagerScreen({super.key});

  @override
  State<RegionManagerScreen> createState() => _RegionManagerScreenState();
}

class _RegionManagerScreenState extends State<RegionManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedRegion = 0;

  static const _regions = [
    _RegionData('Logan', '12.4K', 84, 3, true),
    _RegionData('Brisbane', '8.2K', 56, 2, true),
    _RegionData('Bronx Islanders', '6.8K', 42, 1, true),
    _RegionData('Townsville', '3.4K', 28, 1, false),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  _RegionData get _region => _regions[_selectedRegion];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Text(
          'REGION MANAGER',
          style: TextStyle(
            color: DesignTokens.neonCyan,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 1.5,
          ),
        ),
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
            Tab(text: 'OVERVIEW'),
            Tab(text: 'FEED'),
            Tab(text: 'EVENTS'),
            Tab(text: 'MEMBERS'),
            Tab(text: 'SETTINGS'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Region selector strip
          _buildRegionSelector(),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(isWide),
                _buildFeedTab(),
                _buildEventsTab(),
                _buildMembersTab(),
                _buildSettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionSelector() {
    return Container(
      height: 56,
      color: DesignTokens.bgSecondary,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: _regions.length,
        itemBuilder: (context, index) {
          final r = _regions[index];
          final selected = index == _selectedRegion;
          return GestureDetector(
            onTap: () => setState(() => _selectedRegion = index),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? DesignTokens.neonGreen.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: selected
                    ? Border.all(
                        color: DesignTokens.neonGreen.withValues(alpha: 0.3),
                      )
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_city,
                    color: selected ? DesignTokens.neonGreen : Colors.white38,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    r.name,
                    style: TextStyle(
                      color: selected ? DesignTokens.neonGreen : Colors.white54,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    r.followers,
                    style: TextStyle(
                      color: selected ? DesignTokens.neonGreen : Colors.white24,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Overview Tab ──

  Widget _buildOverviewTab(bool isWide) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Region banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignTokens.neonGreen.withValues(alpha: 0.1),
                DesignTokens.neonCyan.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DesignTokens.neonGreen.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: DesignTokens.neonGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _region.name[0],
                        style: const TextStyle(
                          color: DesignTokens.neonGreen,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _region.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          '${_region.followers} followers · ${_region.fighters} fighters · ${_region.events} events',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_region.verified)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.neonGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            color: DesignTokens.neonGreen,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'VERIFIED',
                            style: TextStyle(
                              color: DesignTokens.neonGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Stats grid
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _statCard('FOLLOWERS', _region.followers, DesignTokens.neonCyan),
            _statCard(
              'FIGHTERS',
              '${_region.fighters}',
              DesignTokens.neonAmber,
            ),
            _statCard('EVENTS', '${_region.events}', DesignTokens.neonMagenta),
            _statCard('POSTS/WEEK', '34', DesignTokens.neonGreen),
            _statCard('GROWTH', '+8%', DesignTokens.neonGold),
            _statCard('ENGAGEMENT', '4.2%', DesignTokens.neonRed),
          ],
        ),
        const SizedBox(height: 24),
        _sectionHeader('TOP FIGHTERS'),
        const SizedBox(height: 12),
        _fighterRow('Haze Hepi', '8-2-0', 'BKFC · HW'),
        _fighterRow('BK Bau', '6-3-0', 'BKFC · HW'),
        _fighterRow('Isaac Hardman', '12-2-0', 'IBC · MW'),
        const SizedBox(height: 24),
        _sectionHeader('RECENT ACTIVITY'),
        const SizedBox(height: 12),
        _activityItem('New post by Haze Hepi', '2h ago', Icons.article),
        _activityItem(
          'Event: Logan Fight Night V created',
          '1d ago',
          Icons.event,
        ),
        _activityItem('12 new members joined', '2d ago', Icons.people),
      ],
    );
  }

  // ── Feed Tab ──

  Widget _buildFeedTab() {
    final posts = [
      const _PostData(
        'Haze Hepi',
        'Getting ready for Townsville. Can\'t wait to represent Logan!',
        '2h ago',
        47,
        true,
      ),
      const _PostData(
        'DFC Official',
        'BKFC Fight Night poster drop — see the full card!',
        '5h ago',
        123,
        true,
      ),
      const _PostData(
        'Mark Flanagan',
        'Training camp day 14. Feeling sharp.',
        '1d ago',
        34,
        false,
      ),
      const _PostData(
        'BK Bau',
        'Logan warriors never back down. April 18.',
        '2d ago',
        56,
        false,
      ),
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final p = posts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: p.pinned
                  ? DesignTokens.neonGold.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: DesignTokens.neonCyan.withValues(
                      alpha: 0.15,
                    ),
                    child: Text(
                      p.author[0],
                      style: const TextStyle(
                        color: DesignTokens.neonCyan,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p.author,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    p.timeAgo,
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                  if (p.pinned) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.push_pin,
                      color: DesignTokens.neonGold,
                      size: 12,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                p.content,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: DesignTokens.neonRed.withValues(alpha: 0.6),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${p.likes}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const Spacer(),
                  _miniAction(
                    p.pinned ? 'UNPIN' : 'PIN',
                    DesignTokens.neonGold,
                  ),
                  const SizedBox(width: 8),
                  _miniAction('BOOST', DesignTokens.neonCyan),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Events Tab ──

  Widget _buildEventsTab() {
    final events = [
      ('BKFC Fight Night Australia', 'Apr 18, 2026', 'Townsville', 'LIVE'),
      ('Logan Fight Night V', 'May 10, 2026', 'Logan', 'PLANNING'),
      ('Brisbane Brawl III', 'Jun 7, 2026', 'Brisbane', 'DRAFT'),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...events.map((e) {
          final statusColor = switch (e.$4) {
            'LIVE' => DesignTokens.neonGreen,
            'PLANNING' => DesignTokens.neonAmber,
            _ => Colors.white38,
          };
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DesignTokens.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.event, color: statusColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.$1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${e.$2} · ${e.$3}',
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
                    e.$4,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Members Tab ──

  Widget _buildMembersTab() {
    final members = [
      ('Haze Hepi', 'Fighter', 'Verified', DesignTokens.neonCyan),
      ('BK Bau', 'Fighter', 'Verified', DesignTokens.neonCyan),
      ('Island Warriors MMA', 'Gym', 'Pink Shield', DesignTokens.neonMagenta),
      ('Tama Kerehoma', 'Fan', 'Trust: High', DesignTokens.neonGreen),
      ('Sione Tu\'uaga', 'Fan', 'Trust: Medium', DesignTokens.neonAmber),
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final m = members[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: m.$4.withValues(alpha: 0.15),
                child: Text(
                  m.$1[0],
                  style: TextStyle(
                    color: m.$4,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.$1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      m.$2,
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
                  color: m.$4.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  m.$3,
                  style: TextStyle(
                    color: m.$4,
                    fontWeight: FontWeight.w700,
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

  // ── Settings Tab ──

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionHeader('REGION SETTINGS'),
        const SizedBox(height: 12),
        _settingTile('Region Name', _region.name, Icons.edit_outlined),
        _settingTile('Visibility', 'Public', Icons.visibility_outlined),
        _settingTile('Auto-moderation', 'Enabled', Icons.shield_outlined),
        _settingTile(
          'Allow Posts',
          'Members + Fighters',
          Icons.article_outlined,
        ),
        const SizedBox(height: 20),
        _sectionHeader('DANGER ZONE'),
        const SizedBox(height: 12),
        _settingTile(
          'Archive Region',
          'Hides from public',
          Icons.archive_outlined,
          color: DesignTokens.neonRed,
        ),
      ],
    );
  }

  // ── Shared Widgets ──

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

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: DesignTokens.neonCyan,
        fontWeight: FontWeight.w900,
        fontSize: 12,
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _fighterRow(String name, String record, String meta) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: DesignTokens.neonCyan.withValues(alpha: 0.12),
            child: Text(
              name[0],
              style: const TextStyle(
                color: DesignTokens.neonCyan,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '$record · $meta',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityItem(String text, String time, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
          Text(
            time,
            style: const TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _miniAction(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 9,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _settingTile(
    String title,
    String subtitle,
    IconData icon, {
    Color color = DesignTokens.neonCyan,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
        ],
      ),
    );
  }
}

class _RegionData {
  final String name;
  final String followers;
  final int fighters;
  final int events;
  final bool verified;
  const _RegionData(
    this.name,
    this.followers,
    this.fighters,
    this.events,
    this.verified,
  );
}

class _PostData {
  final String author;
  final String content;
  final String timeAgo;
  final int likes;
  final bool pinned;
  const _PostData(
    this.author,
    this.content,
    this.timeAgo,
    this.likes,
    this.pinned,
  );
}
