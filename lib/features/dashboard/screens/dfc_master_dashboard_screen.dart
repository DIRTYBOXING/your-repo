import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../widgets/kpi_monitoring_panel.dart';

/// DFC Master Dashboard — The unified admin command center.
/// Sections: Home overview, Social, Fighters, Events, Gyms, Regions, Settings.
class DfcMasterDashboardScreen extends StatefulWidget {
  const DfcMasterDashboardScreen({super.key});

  @override
  State<DfcMasterDashboardScreen> createState() =>
      _DfcMasterDashboardScreenState();
}

class _DfcMasterDashboardScreenState extends State<DfcMasterDashboardScreen> {
  int _selectedSection = 0;

  static const _sections = [
    _DashSection('HOME', Icons.dashboard_outlined),
    _DashSection('SOCIAL', Icons.forum_outlined),
    _DashSection('FIGHTERS', Icons.sports_mma_outlined),
    _DashSection('EVENTS', Icons.event_outlined),
    _DashSection('GYMS', Icons.fitness_center_outlined),
    _DashSection('REGIONS', Icons.map_outlined),
    _DashSection('SETTINGS', Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  // ─── WIDE (Desktop) ───────────────────────────────────────

  Widget _buildWideLayout() {
    return Row(
      children: [
        // Sidebar
        Container(
          width: 220,
          decoration: BoxDecoration(
            color: DesignTokens.bgSecondary,
            border: Border(
              right: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Logo area
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: DesignTokens.neonCyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.shield,
                        color: DesignTokens.neonCyan,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'DFC ADMIN',
                      style: TextStyle(
                        color: DesignTokens.neonCyan,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
              const SizedBox(height: 8),
              // Nav items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: _sections.length,
                  itemBuilder: (context, index) {
                    final s = _sections[index];
                    final selected = index == _selectedSection;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedSection = index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? DesignTokens.neonCyan.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: selected
                              ? Border.all(
                                  color: DesignTokens.neonCyan.withValues(
                                    alpha: 0.2,
                                  ),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              s.icon,
                              color: selected
                                  ? DesignTokens.neonCyan
                                  : Colors.white38,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              s.label,
                              style: TextStyle(
                                color: selected
                                    ? DesignTokens.neonCyan
                                    : Colors.white54,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Content
        Expanded(child: _buildSectionContent(_selectedSection)),
      ],
    );
  }

  // ─── NARROW (Mobile) ──────────────────────────────────────

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        // Top bar
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            bottom: 12,
          ),
          color: DesignTokens.bgSecondary,
          child: Row(
            children: [
              const Icon(Icons.shield, color: DesignTokens.neonCyan, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'DFC ADMIN',
                  style: TextStyle(
                    color: DesignTokens.neonCyan,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Text(
                _sections[_selectedSection].label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        // Section chips
        Container(
          height: 48,
          color: DesignTokens.bgSecondary,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _sections.length,
            itemBuilder: (context, index) {
              final s = _sections[index];
              final selected = index == _selectedSection;
              return GestureDetector(
                onTap: () => setState(() => _selectedSection = index),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? DesignTokens.neonCyan.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: selected
                        ? Border.all(
                            color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        s.icon,
                        color: selected
                            ? DesignTokens.neonCyan
                            : Colors.white38,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        s.label,
                        style: TextStyle(
                          color: selected
                              ? DesignTokens.neonCyan
                              : Colors.white38,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Content
        Expanded(child: _buildSectionContent(_selectedSection)),
      ],
    );
  }

  // ─── SECTION CONTENT ──────────────────────────────────────

  Widget _buildSectionContent(int section) {
    switch (section) {
      case 0:
        return _buildHomeSection();
      case 1:
        return _buildSocialSection();
      case 2:
        return _buildFightersSection();
      case 3:
        return _buildEventsSection();
      case 4:
        return _buildGymsSection();
      case 5:
        return _buildRegionsSection();
      case 6:
        return _buildSettingsSection();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── HOME ─────────────────────────────────────────────────

  Widget _buildHomeSection() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('OVERVIEW'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _statCard('NEW POSTS', '47', '+12%', DesignTokens.neonCyan),
            _statCard('NEW USERS', '23', '+8%', DesignTokens.neonGreen),
            _statCard('QUESTIONS', '12', '+34%', DesignTokens.neonAmber),
            _statCard('REPORTS', '3', '-15%', DesignTokens.neonRed),
            _statCard('UPCOMING', '2', '', DesignTokens.neonMagenta),
            _statCard('REGIONS', '4', '', DesignTokens.neonGold),
          ],
        ),
        const SizedBox(height: 24),
        _sectionTitle('QUICK ACTIONS'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _actionButton(
              'Social Management',
              Icons.forum,
              () => setState(() => _selectedSection = 1),
            ),
            _actionButton(
              'View Mod Queue',
              Icons.shield,
              () => setState(() => _selectedSection = 1),
            ),
            _actionButton(
              'Fighter Profiles',
              Icons.sports_mma,
              () => setState(() => _selectedSection = 2),
            ),
            _actionButton(
              'Create Event',
              Icons.add_circle_outline,
              () => setState(() => _selectedSection = 3),
            ),
            _actionButton(
              'Region Management',
              Icons.map,
              () => setState(() => _selectedSection = 5),
            ),
            _actionButton(
              'Settings',
              Icons.settings,
              () => setState(() => _selectedSection = 6),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _sectionTitle('NOTIFICATIONS'),
        const SizedBox(height: 12),
        _notifCard(
          'BKFC Townsville — 24 days away. Event page needs promo assets.',
          DesignTokens.neonAmber,
        ),
        _notifCard(
          '3 new fan questions awaiting moderation for Haze Hepi.',
          DesignTokens.neonCyan,
        ),
        _notifCard(
          'Logan region has 120 new followers this week.',
          DesignTokens.neonGreen,
        ),
        const SizedBox(height: 28),
        const KpiMonitoringPanel(),
      ],
    );
  }

  // ─── SOCIAL ───────────────────────────────────────────────

  Widget _buildSocialSection() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('SOCIAL MANAGEMENT'),
        const SizedBox(height: 16),
        _navTile(
          'All Posts',
          'Filter by region, fighter, type',
          Icons.article_outlined,
          DesignTokens.neonCyan,
          () {},
        ),
        _navTile(
          'Moderation Queue',
          'Reported / flagged content',
          Icons.shield_outlined,
          DesignTokens.neonRed,
          () {},
        ),
        _navTile(
          'Q&A Queue',
          'Fan questions awaiting approval',
          Icons.question_answer_outlined,
          DesignTokens.neonAmber,
          () => context.push('/correspondence/fighter-inbox'),
        ),
        _navTile(
          'Community Management',
          'Region pages & community health',
          Icons.people_outlined,
          DesignTokens.neonGreen,
          () {},
        ),
        _navTile(
          'Reports',
          'User reports & safety actions',
          Icons.report_outlined,
          DesignTokens.neonMagenta,
          () {},
        ),
        _navTile(
          'Content Pipeline',
          'Auto-feed orchestration & sources',
          Icons.auto_awesome_outlined,
          DesignTokens.neonGold,
          () {},
        ),
      ],
    );
  }

  // ─── FIGHTERS ─────────────────────────────────────────────

  Widget _buildFightersSection() {
    final fighters = [
      ('Haze Hepi', '8-2-0', 'Logan', 'haze_hepi'),
      ('Mark Flanagan', '24-7-0', 'Sydney', 'mark_flanagan'),
      ('Sam Soliman', '44-13-0', 'Melbourne', 'sam_soliman'),
      ('Krzysztof Wisniewski', '4-0-0', 'Poland', 'wisniewski'),
      ('BK Bau', '6-3-0', 'Logan', 'bk_bau'),
    ];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('FIGHTERS MANAGEMENT'),
        const SizedBox(height: 16),
        ...fighters.map((f) => _fighterAdminTile(f.$1, f.$2, f.$3, f.$4)),
      ],
    );
  }

  Widget _fighterAdminTile(
    String name,
    String record,
    String region,
    String id,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DesignTokens.neonCyan.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Text(
                name[0],
                style: const TextStyle(
                  color: DesignTokens.neonCyan,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
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
                Row(
                  children: [
                    Text(
                      record,
                      style: const TextStyle(
                        color: DesignTokens.neonAmber,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      region,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _smallButton(
            'PROFILE',
            DesignTokens.neonCyan,
            () => context.push('/fighter-profile/$id'),
          ),
          const SizedBox(width: 8),
          _smallButton(
            'Q&A',
            DesignTokens.neonAmber,
            () => context.push('/correspondence/fighter-inbox?fighterId=$id'),
          ),
        ],
      ),
    );
  }

  Widget _smallButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 9,
          ),
        ),
      ),
    );
  }

  // ─── EVENTS ───────────────────────────────────────────────

  Widget _buildEventsSection() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('EVENTS MANAGEMENT'),
        const SizedBox(height: 16),
        _eventAdminCard(
          'BKFC Fight Night Australia',
          'Apr 18, 2026',
          'Townsville',
          'UPCOMING',
          DesignTokens.neonGreen,
        ),
        _eventAdminCard(
          'Logan Fight Night V',
          'May 10, 2026',
          'Logan',
          'PLANNING',
          DesignTokens.neonAmber,
        ),
        const SizedBox(height: 20),
        _actionButton('Create New Event', Icons.add_circle_outline, () {}),
      ],
    );
  }

  Widget _eventAdminCard(
    String title,
    String date,
    String location,
    String status,
    Color statusColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$date · $location',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
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
  }

  // ─── GYMS ─────────────────────────────────────────────────

  Widget _buildGymsSection() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('GYMS MANAGEMENT'),
        const SizedBox(height: 16),
        _gymAdminTile('Island Warriors MMA', 'Logan', true, 120),
        _gymAdminTile('Logan Boxing Club', 'Logan', true, 85),
        _gymAdminTile('Integrated MMA', 'Brisbane', true, 200),
        _gymAdminTile('Pacific Force BJJ', 'Logan', false, 64),
      ],
    );
  }

  Widget _gymAdminTile(
    String name,
    String region,
    bool pinkShield,
    int members,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DesignTokens.neonMagenta.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: DesignTokens.neonMagenta,
              size: 18,
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
                  '$region · $members members',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (pinkShield)
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: DesignTokens.neonMagenta.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.shield,
                color: DesignTokens.neonMagenta,
                size: 14,
              ),
            ),
        ],
      ),
    );
  }

  // ─── REGIONS ──────────────────────────────────────────────

  Widget _buildRegionsSection() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('REGIONS MANAGEMENT'),
        const SizedBox(height: 16),
        _regionAdminTile('Logan', '12.4K followers', '84 fighters', 'logan'),
        _regionAdminTile(
          'Brisbane',
          '8.2K followers',
          '56 fighters',
          'brisbane',
        ),
        _regionAdminTile(
          'Bronx Islanders',
          '6.8K followers',
          '42 fighters',
          'bronx_islanders',
        ),
        _regionAdminTile(
          'Townsville',
          '3.4K followers',
          '28 fighters',
          'townsville',
        ),
        const SizedBox(height: 20),
        _actionButton(
          'Create New Region',
          Icons.add_location_alt_outlined,
          () {},
        ),
      ],
    );
  }

  Widget _regionAdminTile(
    String name,
    String followers,
    String fighters,
    String id,
  ) {
    return GestureDetector(
      onTap: () => context.push('/region/$id?name=$name'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DesignTokens.neonGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.location_city,
                color: DesignTokens.neonGreen,
                size: 18,
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
                    '$followers · $fighters',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }

  // ─── SETTINGS ─────────────────────────────────────────────

  Widget _buildSettingsSection() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('ACCOUNT'),
        const SizedBox(height: 12),
        _navTile(
          'Profile',
          'Name, handle, avatar',
          Icons.person_outline,
          DesignTokens.neonCyan,
          () => context.push('/settings'),
        ),
        _navTile(
          'Notifications',
          'Push, email, in-app',
          Icons.notifications_outlined,
          DesignTokens.neonAmber,
          () => context.push('/notification-settings'),
        ),
        _navTile(
          'Privacy',
          'Data, visibility, consent',
          Icons.lock_outline,
          DesignTokens.neonGreen,
          () => context.push('/privacy'),
        ),
        const SizedBox(height: 20),
        _sectionTitle('PLATFORM'),
        const SizedBox(height: 12),
        _navTile(
          'Moderation Rules',
          'AI filters, keyword lists, severity levels',
          Icons.shield_outlined,
          DesignTokens.neonRed,
          () {},
        ),
        _navTile(
          'Content Filters',
          'Auto-flag, auto-remove, trust scores',
          Icons.filter_alt_outlined,
          DesignTokens.neonMagenta,
          () {},
        ),
        _navTile(
          'Roles & Permissions',
          'Admin, mod, fighter, fan, gym',
          Icons.admin_panel_settings_outlined,
          DesignTokens.neonCyan,
          () {},
        ),
        _navTile(
          'Safety Settings',
          'Ninja moderation, shadow mute, bans',
          Icons.security_outlined,
          DesignTokens.neonAmber,
          () {},
        ),
        const SizedBox(height: 20),
        _sectionTitle('BRANDING'),
        const SizedBox(height: 12),
        _navTile(
          'Theme & Colors',
          'Neon accents, backgrounds',
          Icons.palette_outlined,
          DesignTokens.neonGold,
          () {},
        ),
        _navTile(
          'Event Templates',
          'Poster styles, promo formats',
          Icons.style_outlined,
          DesignTokens.neonMagenta,
          () {},
        ),
        const SizedBox(height: 20),
        _sectionTitle('INTEGRATIONS'),
        const SizedBox(height: 12),
        _navTile(
          'Firebase',
          'Auth, Firestore, Analytics',
          Icons.cloud_outlined,
          DesignTokens.neonAmber,
          () {},
        ),
        _navTile(
          'Payments',
          'Stripe, PPV purchases',
          Icons.payment_outlined,
          DesignTokens.neonGreen,
          () {},
        ),
        _navTile(
          'Analytics',
          'Dashboard metrics, events',
          Icons.analytics_outlined,
          DesignTokens.neonCyan,
          () {},
        ),
        _navTile(
          'Agents',
          'AI feed, moderation, coaching',
          Icons.smart_toy_outlined,
          DesignTokens.neonMagenta,
          () => context.push('/ai-bots'),
        ),
      ],
    );
  }

  // ─── SHARED WIDGETS ───────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: DesignTokens.neonCyan,
        fontWeight: FontWeight.w900,
        fontSize: 13,
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _statCard(String label, String value, String change, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
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
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 28,
            ),
          ),
          if (change.isNotEmpty)
            Text(
              change,
              style: TextStyle(
                color: change.startsWith('+')
                    ? DesignTokens.neonGreen
                    : DesignTokens.neonRed,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: DesignTokens.neonCyan.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: DesignTokens.neonCyan.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: DesignTokens.neonCyan, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: DesignTokens.neonCyan,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notifCard(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active, color: color, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
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
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }
}

class _DashSection {
  final String label;
  final IconData icon;
  const _DashSection(this.label, this.icon);
}
