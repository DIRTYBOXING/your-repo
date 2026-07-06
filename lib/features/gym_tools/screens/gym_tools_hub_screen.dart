import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/router_config.dart' as rc;

/// ═══════════════════════════════════════════════════════════════════════════
/// GYM TOOLS HUB — Unified command centre for gym owners & coaches
/// Combines gym profile management, fighter roster, training programs,
/// partnership tools, and analytics into one power-screen.
/// ═══════════════════════════════════════════════════════════════════════════
class GymToolsHubScreen extends StatefulWidget {
  const GymToolsHubScreen({super.key});

  @override
  State<GymToolsHubScreen> createState() => _GymToolsHubScreenState();
}

class _GymToolsHubScreenState extends State<GymToolsHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            // Quick stats bar
            _buildQuickStats(),
            // Tabs
            Container(
              color: AppTheme.secondaryBackground,
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Dashboard'),
                  Tab(text: 'Roster'),
                  Tab(text: 'Programs'),
                  Tab(text: 'Business'),
                ],
                labelColor: AppTheme.neonCyan,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.neonCyan,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDashboardTab(context),
                  _buildRosterTab(),
                  _buildProgramsTab(),
                  _buildBusinessTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(left: 4, right: 8),
            child: Image.asset(
              'assets/logos/dfc_icon_transparent.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.fitness_center,
                color: Colors.cyanAccent,
                size: 20,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Back',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
          ),
          const Text(
            '🏋️ GYM COMMAND',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.neonGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.neonGreen.withValues(alpha: 0.4),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: AppTheme.neonGreen, size: 14),
                SizedBox(width: 4),
                Text(
                  'VERIFIED',
                  style: TextStyle(
                    color: AppTheme.neonGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonCyan.withValues(alpha: 0.08),
            AppTheme.neonMagenta.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMiniStat('Fighters', '47', AppTheme.neonCyan),
          _divider(),
          _buildMiniStat('Coaches', '8', AppTheme.neonMagenta),
          _divider(),
          _buildMiniStat('Programs', '12', AppTheme.neonGreen),
          _divider(),
          _buildMiniStat('Rating', '4.8', AppTheme.neonOrange),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 28, color: Colors.white12);
  }

  // ── Dashboard Tab ──────────────────────────────────────────────────────

  Widget _buildDashboardTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Gym Profile Card
        _buildSectionCard(
          title: 'GYM PROFILE',
          icon: Icons.store,
          accent: AppTheme.neonCyan,
          children: [
            _buildInfoRow('Name', 'Tiger Muay Thai'),
            _buildInfoRow('Location', '🇹🇭 Phuket, Thailand'),
            _buildInfoRow('Disciplines', 'MMA, Muay Thai, Boxing, BJJ'),
            _buildInfoRow('Established', '2003'),
            _buildInfoRow('Members', '200+'),
          ],
        ),
        const SizedBox(height: 12),
        // Quick Actions Grid
        _buildSectionCard(
          title: 'QUICK ACTIONS',
          icon: Icons.flash_on,
          accent: AppTheme.neonMagenta,
          children: [_buildActionGrid(context)],
        ),
        const SizedBox(height: 12),
        // Recent Activity
        _buildSectionCard(
          title: 'RECENT ACTIVITY',
          icon: Icons.history,
          accent: AppTheme.neonGreen,
          children: [
            _buildActivityItem(
              'New fighter registered',
              'Somchai T.',
              '2h ago',
              AppTheme.neonCyan,
            ),
            _buildActivityItem(
              'Training program updated',
              'Muay Thai Fundamentals',
              '5h ago',
              AppTheme.neonGreen,
            ),
            _buildActivityItem(
              'Partnership inquiry',
              'ONE Championship',
              '1d ago',
              AppTheme.neonMagenta,
            ),
            _buildActivityItem(
              'Event registered',
              'IBC 04 Training Camp',
              '2d ago',
              AppTheme.neonOrange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    final actions = [
      _ActionTile('Edit Profile', Icons.edit, AppTheme.neonCyan, () {}),
      _ActionTile('Add Fighter', Icons.person_add, AppTheme.neonGreen, () {}),
      _ActionTile('New Program', Icons.add_circle, AppTheme.neonMagenta, () {}),
      _ActionTile(
        'Partnerships',
        Icons.handshake,
        AppTheme.neonOrange,
        () => context.push(rc.RouteConstants.partnershipHubPath),
      ),
      _ActionTile(
        'Analytics',
        Icons.analytics,
        AppTheme.neonCyan,
        () => context.push(rc.RouteConstants.combatAnalyticsPath),
      ),
      _ActionTile(
        'Mentor Tools',
        Icons.school,
        AppTheme.neonGreen,
        () => context.push(rc.RouteConstants.gymMentorPath),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.1,
      children: actions.map(_buildActionTile).toList(),
    );
  }

  Widget _buildActionTile(_ActionTile action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: action.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: action.color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: action.color, size: 24),
            const SizedBox(height: 6),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Roster Tab ─────────────────────────────────────────────────────────

  Widget _buildRosterTab() {
    final fighters = [
      const _RosterFighter(
        'Stamp Fairtex',
        '🇹🇭',
        'Muay Thai • Atomweight',
        '67-18-5',
        AppTheme.neonCyan,
        'Active',
      ),
      const _RosterFighter(
        'Rodtang Jitmuangnon',
        '🇹🇭',
        'Muay Thai • Flyweight',
        '272-42-10',
        AppTheme.neonOrange,
        'Active',
      ),
      const _RosterFighter(
        'Superbon',
        '🇹🇭',
        'Kickboxing • Featherweight',
        '113-34',
        AppTheme.neonMagenta,
        'Active',
      ),
      const _RosterFighter(
        'Tawanchai',
        '🇹🇭',
        'Muay Thai • Featherweight',
        '130-30',
        AppTheme.neonGreen,
        'Active',
      ),
      const _RosterFighter(
        'Panpayak Jitmuangnon',
        '🇹🇭',
        'Muay Thai • Bantamweight',
        '220-35-3',
        AppTheme.neonCyan,
        'Injured',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Search
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.2)),
          ),
          child: TextField(
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search roster...',
              hintStyle: TextStyle(
                color: AppTheme.neonCyan.withValues(alpha: 0.4),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: AppTheme.neonCyan.withValues(alpha: 0.5),
                size: 20,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        // Roster list
        ...fighters.map(_buildRosterCard),
      ],
    );
  }

  Widget _buildRosterCard(_RosterFighter f) {
    final isInjured = f.status == 'Injured';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isInjured
              ? Colors.red.withValues(alpha: 0.3)
              : f.accent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: f.accent, width: 2),
            ),
            child: Center(
              child: Text(f.flag, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      f.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isInjured
                            ? Colors.red.withValues(alpha: 0.15)
                            : AppTheme.neonGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        f.status,
                        style: TextStyle(
                          color: isInjured ? Colors.red : AppTheme.neonGreen,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  f.discipline,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: f.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              f.record,
              style: TextStyle(
                color: f.accent,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Programs Tab ───────────────────────────────────────────────────────

  Widget _buildProgramsTab() {
    final programs = [
      const _GymProgram(
        'Muay Thai Fundamentals',
        '8 weeks',
        24,
        0.85,
        AppTheme.neonCyan,
        Icons.sports_mma,
      ),
      const _GymProgram(
        'MMA Fight Camp',
        '12 weeks',
        18,
        0.72,
        AppTheme.neonMagenta,
        Icons.sports_kabaddi,
      ),
      const _GymProgram(
        'Boxing Conditioning',
        '6 weeks',
        31,
        0.91,
        AppTheme.neonOrange,
        Icons.sports_mma,
      ),
      const _GymProgram(
        'BJJ Competition Prep',
        '10 weeks',
        15,
        0.68,
        AppTheme.neonGreen,
        Icons.sports,
      ),
      const _GymProgram(
        'Kids Martial Arts',
        '16 weeks',
        42,
        0.94,
        AppTheme.neonCyan,
        Icons.child_care,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ...programs.map(_buildProgramCard),
        const SizedBox(height: 12),
        // Add program button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: AppTheme.neonCyan.withValues(alpha: 0.6),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Create New Program',
                style: TextStyle(
                  color: AppTheme.neonCyan.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgramCard(_GymProgram p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.accent.withValues(alpha: 0.15),
                ),
                child: Icon(p.icon, color: p.accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${p.duration} • ${p.enrolled} enrolled',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(p.completionRate * 100).toInt()}%',
                style: TextStyle(
                  color: p.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: p.completionRate,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation(p.accent),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Business Tab ───────────────────────────────────────────────────────

  Widget _buildBusinessTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Revenue overview
        _buildSectionCard(
          title: 'REVENUE OVERVIEW',
          icon: Icons.attach_money,
          accent: AppTheme.neonGreen,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRevStat('Monthly', '\$24.8K', AppTheme.neonGreen),
                _buildRevStat('Members', '203', AppTheme.neonCyan),
                _buildRevStat('Retention', '92%', AppTheme.neonMagenta),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Partnership & sponsor tools
        _buildSectionCard(
          title: 'PARTNERSHIPS & SPONSORS',
          icon: Icons.handshake,
          accent: AppTheme.neonOrange,
          children: [
            _buildBusinessLink(
              'Partnership Hub',
              Icons.handshake,
              AppTheme.neonOrange,
              () => context.push(rc.RouteConstants.partnershipHubPath),
            ),
            _buildBusinessLink(
              'Sponsor Dashboard',
              Icons.diamond,
              AppTheme.neonCyan,
              () => context.push(rc.RouteConstants.sponsorDashboardPath),
            ),
            _buildBusinessLink(
              'Register Gym on DFC',
              Icons.app_registration,
              AppTheme.neonGreen,
              () => context.push(rc.RouteConstants.registerGymPath),
            ),
            _buildBusinessLink(
              'Mentor Tools',
              Icons.school,
              AppTheme.neonMagenta,
              () => context.push(rc.RouteConstants.gymMentorPath),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Equipment & facility
        _buildSectionCard(
          title: 'FACILITY MANAGEMENT',
          icon: Icons.store,
          accent: AppTheme.neonMagenta,
          children: [
            _buildInfoRow('Facility Size', '14,000 sq ft'),
            _buildInfoRow('Equipment Status', 'All Operational'),
            _buildInfoRow('Next Inspection', 'Jan 15, 2026'),
            _buildInfoRow('Insurance', 'Active — Renewed Aug 2025'),
          ],
        ),
      ],
    );
  }

  Widget _buildRevStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessLink(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.3),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared Builders ────────────────────────────────────────────────────

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color accent,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String action,
    String detail,
    String time,
    Color accent,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                Text(
                  detail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data Models ─────────────────────────────────────────────────────────

class _ActionTile {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile(this.label, this.icon, this.color, this.onTap);
}

class _RosterFighter {
  final String name;
  final String flag;
  final String discipline;
  final String record;
  final Color accent;
  final String status;
  const _RosterFighter(
    this.name,
    this.flag,
    this.discipline,
    this.record,
    this.accent,
    this.status,
  );
}

class _GymProgram {
  final String name;
  final String duration;
  final int enrolled;
  final double completionRate;
  final Color accent;
  final IconData icon;
  const _GymProgram(
    this.name,
    this.duration,
    this.enrolled,
    this.completionRate,
    this.accent,
    this.icon,
  );
}
