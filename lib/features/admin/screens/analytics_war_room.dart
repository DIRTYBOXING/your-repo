import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/market_expansion_playbook.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/admin_service.dart';
import '../../../shared/services/social_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// 📊 ANALYTICS WAR ROOM — Growth and engagement metrics
/// ═══════════════════════════════════════════════════════════════════════════
class AnalyticsWarRoom extends StatefulWidget {
  final String adminId;

  const AnalyticsWarRoom({super.key, required this.adminId});

  @override
  State<AnalyticsWarRoom> createState() => _AnalyticsWarRoomState();
}

class _AnalyticsWarRoomState extends State<AnalyticsWarRoom> {
  final _adminService = AdminService();
  final _socialService = SocialService();

  SystemStatus? _systemStatus;
  GrowthMetrics? _growthMetrics;
  bool _isLoading = true;
  bool _campaignFiring = false;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final status = await _adminService.getSystemStatus();
      final growth = await _adminService.getGrowthMetrics();

      setState(() {
        _systemStatus = status;
        _growthMetrics = growth;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load analytics: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: const Row(
          children: [
            Icon(Icons.analytics, color: AppTheme.accentTeal),
            SizedBox(width: 8),
            Text(
              'Analytics War Room',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.neonGreen),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _campaignFiring ? null : _fireCampaignFromWarRoom,
        backgroundColor: AppTheme.neonGreen,
        icon: _campaignFiring
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : const Icon(Icons.campaign, color: Colors.black),
        label: Text(
          _campaignFiring ? 'Firing...' : 'Fire Campaign',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.neonGreen))
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetricsGrid(),
                    const SizedBox(height: 24),
                    _buildPeaceFrameworkPanel(),
                    const SizedBox(height: 24),
                    _buildCodeOfLawPanel(),
                    const SizedBox(height: 24),
                    _buildInternationalExpansionEngine(),
                    const SizedBox(height: 24),
                    _buildCreatorConversionEngine(),
                    const SizedBox(height: 24),
                    _buildStakeholderPpvStrategyPanel(),
                    const SizedBox(height: 24),
                    _buildPromoterBridgePanel(),
                    const SizedBox(height: 24),
                    _buildProductRoadmapPanel(),
                    const SizedBox(height: 24),
                    _buildEngagementChart(),
                    const SizedBox(height: 24),
                    _buildGrowthChart(),
                    const SizedBox(height: 24),
                    _buildKeyMetrics(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricsGrid() {
    if (_systemStatus == null || _growthMetrics == null) {
      return const SizedBox.shrink();
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildMetricCard(
          title: 'Total Users',
          value: _growthMetrics!.totalUsers.toString(),
          icon: Icons.people,
          color: AppTheme.neonGreen,
          trend: '+${_growthMetrics!.newUsersToday} today',
        ),
        _buildMetricCard(
          title: 'Active Now',
          value: _systemStatus!.usersOnline.toString(),
          icon: Icons.online_prediction,
          color: Colors.greenAccent,
          trend: 'Live',
        ),
        _buildMetricCard(
          title: 'Posts Today',
          value: _systemStatus!.postsToday.toString(),
          icon: Icons.article,
          color: AppTheme.accentTeal,
          trend: 'Content',
        ),
        _buildMetricCard(
          title: 'Donations',
          value: '\$${_systemStatus!.donationsToday.toStringAsFixed(0)}',
          icon: Icons.favorite,
          color: Colors.pinkAccent,
          trend: 'Today',
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Text(
                trend,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCodeOfLawPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.cardBackground,
            AppTheme.neonGreen.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.neonGreen.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.balance, color: AppTheme.neonGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'DFC Code of Law',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Bridge Principle: Opportunities are open to any promoter and any fighter who operates through professional shows and verifiable professional records.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ExpansionTag('Open Access', 'No closed circle politics'),
              _ExpansionTag(
                'Professional Standard',
                'Sanctioned events + verified records',
              ),
              _ExpansionTag(
                'Equal Pathway',
                'Unknown talent gets real opportunities',
              ),
              _ExpansionTag(
                'Promoter Bridge',
                'Promoters request and match global contenders',
              ),
              _ExpansionTag(
                'Outcome',
                'Professional shows make opportunities real',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildMetricRow('Verified fighter applications (30d)', '2,140'),
          _buildMetricRow('Promoter opportunity requests (30d)', '312'),
          _buildMetricRow('Record verification pass rate', '91.4%'),
          _buildMetricRow('Opportunities converted to pro bouts', '187'),
        ],
      ),
    );
  }

  Widget _buildPeaceFrameworkPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.cardBackground,
            AppTheme.accentTeal.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentTeal.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.volunteer_activism,
                color: AppTheme.accentTeal,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'DFC Peace Framework',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Core principle: Fight is a sport and a game, not war. DFC uses professional pathways to turn conflict energy into discipline, identity, opportunity, and care across countries.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ExpansionTag(
                'Identity',
                'Represent your people with pride, respect, and records',
              ),
              _ExpansionTag(
                'Love & Care',
                'Guardrails for youth safety, health, and fairness',
              ),
              _ExpansionTag(
                'No Hate Pipeline',
                'Zero tolerance for violence outside sport rules',
              ),
              _ExpansionTag(
                'Bridge Model',
                'Promoters + fighters + fans in one opportunity system',
              ),
              _ExpansionTag(
                'Peace Outcome',
                'Talent visibility, jobs, travel, and community hope',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildMetricRow('Countries with active peace-sport pathways', '42'),
          _buildMetricRow('Youth-safe campaigns running', '18'),
          _buildMetricRow('Cross-border pro opportunity matches', '264'),
          _buildMetricRow('Community sentiment (positive)', '93.1%'),
        ],
      ),
    );
  }

  // ── Fire Campaign from War Room ──────────────────────────────────────────
  Future<void> _fireCampaignFromWarRoom() async {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final script = MarketExpansionPlaybook.scriptFor(
      countryCode: locale.countryCode ?? 'US',
      languageCode: locale.languageCode,
    );

    final content =
        '${script.gatewayHeadline}\n\n'
        '${script.gatewaySubtitle}\n\n'
        '${script.gymOffer}\n\n'
        '${script.creatorAmplifier}\n\n'
        '#DFCFightPipe #FightGame #OpenNetwork';

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.campaign, color: AppTheme.neonGreen, size: 22),
                SizedBox(width: 8),
                Text(
                  'Post to FightWire Feed',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.neonGreen.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                content,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text(
                    'Fire It',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _campaignFiring = true);
    try {
      await _socialService.createPost(
        authorId: widget.adminId,
        content: content,
        postType: 'campaign',
        campaignId: 'dfc_gateway_${DateTime.now().millisecondsSinceEpoch}',
        displayName: 'DFC FightPipe Opportunities Desk',
        role: 'admin',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.neonGreen, size: 18),
                SizedBox(width: 8),
                Text(
                  'Campaign fired to FightWire feed!',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
              ],
            ),
            backgroundColor: AppTheme.cardDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to post campaign: $e')));
      }
    } finally {
      if (mounted) setState(() => _campaignFiring = false);
    }
  }

  // ── Old School Promoter Bridge Blueprint ─────────────────────────────────
  Widget _buildPromoterBridgePanel() {
    const funnelSteps = [
      _FunnelStep(
        label: 'Creator\nSubs',
        icon: Icons.people,
        color: Color(0xFF00E5FF),
        value: '10M',
        barY: 10.0,
        detail:
            'Social media giant audience (TikTok / YouTube / Instagram combined)',
      ),
      _FunnelStep(
        label: 'Warm\nViewers',
        icon: Icons.visibility,
        color: Color(0xFF69FF47),
        value: '2.5M',
        barY: 2.5,
        detail: '25% watch fight-related content from the original channel',
      ),
      _FunnelStep(
        label: 'DFC\nWaitlist',
        icon: Icons.airplane_ticket_outlined,
        color: Color(0xFFFFD740),
        value: '750k',
        barY: 0.75,
        detail: '30% of warm viewers click to DFC event waitlist',
      ),
      _FunnelStep(
        label: 'PPV\nBuyers',
        icon: Icons.shopping_cart,
        color: Color(0xFFFF6B35),
        value: '150k',
        barY: 0.15,
        detail: '20% of waitlist converts at event launch',
      ),
      _FunnelStep(
        label: 'Revenue\nGross',
        icon: Icons.attach_money,
        color: Color(0xFFAB47BC),
        value: '\$1.5B+',
        barY: 0.05,
        detail:
            '\$9.99–\$12.99 PPV × 150k buyers × multi-country portals × replay',
      ),
    ];

    const oldWay = [
      'Relies on 1 TV deal or 1 territory',
      'Pays for print, outdoor and radio ads',
      'No data on who is watching or from where',
      'Sells tickets in one city, one country',
      'Cannot reach younger fans or new markets',
      'PPV only through legacy cable gatekeepers',
      'Revenue ceiling: gate + one broadcast window',
    ];
    const newWay = [
      'Creator with 10M subs promotes globally',
      'Zero media spend — content IS the ad',
      'Real-time data: country, age, engagement',
      'PPV sells in every country creator reaches',
      'Gen Z + millennial audience built in from day 1',
      'DFC FightPipe streams direct — no cable wall',
      'Revenue: gate + PPV + replay + merch + sub share',
    ];

    const portals = [
      _PortalRevenue(
        country: 'Australia',
        buyers: 45000,
        price: 12.99,
        barFraction: 1.00,
        color: Color(0xFF00E5FF),
      ),
      _PortalRevenue(
        country: 'USA',
        buyers: 38000,
        price: 12.99,
        barFraction: 0.84,
        color: Color(0xFF69FF47),
      ),
      _PortalRevenue(
        country: 'UK',
        buyers: 22000,
        price: 9.99,
        barFraction: 0.49,
        color: Color(0xFFAB47BC),
      ),
      _PortalRevenue(
        country: 'India',
        buyers: 30000,
        price: 2.99,
        barFraction: 0.67,
        color: Color(0xFFFF9800),
      ),
      _PortalRevenue(
        country: 'Africa',
        buyers: 20000,
        price: 2.99,
        barFraction: 0.44,
        color: Color(0xFFFF6B35),
      ),
      _PortalRevenue(
        country: 'PNG / Pacific',
        buyers: 10000,
        price: 4.99,
        barFraction: 0.22,
        color: Color(0xFFFFD740),
      ),
    ];
    const totalBuyers = 165000;
    const totalRevenue = 1310450.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF6B35).withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(
                Icons.connecting_airports,
                color: Color(0xFFFF6B35),
                size: 22,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'The Bridge Blueprint — Old School Promoter × Social Giant',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'You have the best shows and the best fighters. They have 10 million subscribers. '
            'You don\'t need to learn TikTok. You need DFC to open the wormhole between your fight card and their audience.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Flow Diagram
          const Text(
            'HOW THE WORMHOLE WORKS',
            style: TextStyle(
              color: Color(0xFFFF6B35),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _buildWormholeFlow(),
          const SizedBox(height: 20),

          // Old vs New
          const Text(
            'OLD SCHOOL vs FIGHTPIPE MODEL',
            style: TextStyle(
              color: AppTheme.accentTeal,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildComparisonColumn(
                  title: 'Old Promoter',
                  icon: Icons.sports_mma,
                  color: Colors.redAccent,
                  items: oldWay,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildComparisonColumn(
                  title: 'DFC FightPipe',
                  icon: Icons.rocket_launch,
                  color: const Color(0xFF69FF47),
                  items: newWay,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Funnel Bar Chart
          const Text(
            'SUBSCRIBER → PPV BUYER FUNNEL (10M CREATOR)',
            style: TextStyle(
              color: Color(0xFFFFD740),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    
                  ),
                  rightTitles: const AxisTitles(
                    
                  ),
                  topTitles: const AxisTitles(
                    
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= funnelSteps.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            funnelSteps[idx].label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 9,
                              height: 1.1,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(
                  funnelSteps.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: funnelSteps[i].barY,
                        color: funnelSteps[i].color,
                        width: 30,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...funnelSteps.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: s.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${s.value}  ',
                    style: TextStyle(
                      color: s.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      s.detail,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Multi-country portal revenue
          const Text(
            'MULTI-COUNTRY PORTAL REVENUE — 1 FLAGSHIP EVENT',
            style: TextStyle(
              color: Color(0xFFAB47BC),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Each country is an open portal. Same event, local price, local creator, local revenue stream.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ...portals.map(_buildPortalRow),
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFAB47BC).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFAB47BC).withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '$totalBuyers buyers across 6 portals',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '\$${totalRevenue.toStringAsFixed(0)} gross',
                  style: const TextStyle(
                    color: Color(0xFFAB47BC),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Wormhole Principle callout
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00E5FF).withValues(alpha: 0.07),
                  const Color(0xFFAB47BC).withValues(alpha: 0.07),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.30),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF00E5FF),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'The Wormhole Principle',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'A wormhole connects two points that would otherwise never meet. '
                  'DFC is the wormhole between an old-school promoter\'s fight card and a social media giant\'s 10 million fans. '
                  'The promoter keeps running great shows. The creator keeps making great content. '
                  'DFC opens every portal between them and takes a slice of every dollar that flows through it. '
                  'Multiply by 10 promoters × 10 creators × 6 country portals = 600 revenue streams. Billions.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _ExpansionTag(
                      'Promoter role',
                      'Run the best show possible — nothing else changes',
                    ),
                    _ExpansionTag(
                      'Creator role',
                      'Make content — DFC handles the PPV checkout',
                    ),
                    _ExpansionTag(
                      'DFC role',
                      'Build every portal, collect and distribute revenue',
                    ),
                    _ExpansionTag(
                      'Fan role',
                      'Pay once, watch anywhere, join the community',
                    ),
                    _ExpansionTag(
                      'Scale',
                      '10 promoters × 10 creators × 6 portals = 600 revenue streams',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWormholeFlow() {
    const steps = [
      _FlowStep(
        icon: Icons.sports_mma,
        label: 'Promoter\n+ Fight Card',
        color: Color(0xFF00E5FF),
      ),
      _FlowStep(icon: Icons.arrow_forward, label: '', color: Colors.white38),
      _FlowStep(
        icon: Icons.hub,
        label: 'DFC\nBridge',
        color: Color(0xFFFF6B35),
      ),
      _FlowStep(icon: Icons.arrow_forward, label: '', color: Colors.white38),
      _FlowStep(
        icon: Icons.person_pin,
        label: 'Creator\n10M Subs',
        color: Color(0xFFFFD740),
      ),
      _FlowStep(icon: Icons.arrow_forward, label: '', color: Colors.white38),
      _FlowStep(
        icon: Icons.public,
        label: 'Global\nFans',
        color: Color(0xFF69FF47),
      ),
      _FlowStep(icon: Icons.arrow_forward, label: '', color: Colors.white38),
      _FlowStep(
        icon: Icons.attach_money,
        label: 'PPV\nRevenue',
        color: Color(0xFFAB47BC),
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: steps
            .map(
              (s) => s.label.isEmpty
                  ? Icon(s.icon, color: s.color, size: 14)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(s.icon, color: s.color, size: 22),
                        const SizedBox(height: 4),
                        Text(
                          s.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: s.color,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildComparisonColumn({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5, right: 6),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortalRow(_PortalRevenue p) {
    final revenue = p.buyers * p.price;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              p.country,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: p.barFraction,
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: p.color.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              '${p.buyers ~/ 1000}k buys',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 74,
            child: Text(
              '\$${revenue.toStringAsFixed(0)}',
              style: TextStyle(
                color: p.color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ── Phase 2 Product Roadmap ──────────────────────────────────────────────
  Widget _buildProductRoadmapPanel() {
    const phases = [
      _RoadmapPhase(
        icon: Icons.sports_mma,
        color: Color(0xFF00E5FF),
        phase: 'Phase 2A',
        title: 'Matchmaking Engine',
        subtitle: 'The fight is made before the venue is booked.',
        bullets: [
          'Fighter profile with weight class, style, pro record, and location',
          'Promoter browse + shortlist tool (filter by region/weight/availability)',
          'Bout creation workflow: offer → negotiate → confirm → publish',
          'Auto-notify matched fighters when a promoter card has an opening',
          'Record verification layer — verifiable bout history from approved sources',
        ],
      ),
      _RoadmapPhase(
        icon: Icons.live_tv,
        color: Color(0xFF69FF47),
        phase: 'Phase 2B',
        title: 'Live Event Hub',
        subtitle: 'FightPipe goes live.',
        bullets: [
          'Event scheduling: card builder, bouts list, venue and date',
          'Ticket tier management: GA / VIP / ringside + digital access pass',
          'Live stream player embedded in-app (DFC FightPipe brand)',
          'PPV checkout: Stripe paywall + access token gated stream URL',
          'Post-event replay and highlight reel publishing',
        ],
      ),
      _RoadmapPhase(
        icon: Icons.payments_outlined,
        color: Color(0xFFAB47BC),
        phase: 'Phase 2C',
        title: 'Revenue Rail',
        subtitle: 'Everyone gets paid. System is self-liquidating.',
        bullets: [
          'Payout split engine: promoter / gym / fighter / platform percentages',
          'Subscription tier billing: fan / creator / pro / promoter plans',
          'DFC Creator Fund: revenue share back to top-performing channel builders',
          'Marketplace: gym memberships, merch, shorts, event bundles',
          'Donation / tip rail for fighters direct from fans',
        ],
      ),
      _RoadmapPhase(
        icon: Icons.public,
        color: Color(0xFFFFAB40),
        phase: 'Phase 2D',
        title: 'Community & App Store',
        subtitle: 'The platform becomes the home of the fight game.',
        bullets: [
          'iOS + Android production release (TestFlight → App Store)',
          'Fighter rankings: community-weighted + record-based hybrid score',
          'Gym directory with trial booking and review system',
          'Fan prediction game: pick winners, earn DFC points',
          'Push notifications: bout announcements, event countdowns, record updates',
        ],
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.rocket_launch, color: Colors.amberAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'Phase 2 — Product Execution Roadmap',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Marketing is done. The audience is warmed. Now the product has to deliver. '
            'These four phases convert attention into infrastructure.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          ...phases.map(_buildRoadmapPhaseCard),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.amberAccent.withValues(alpha: 0.25),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt, color: Colors.amberAccent, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rule: Ship Phase 2A before the first international campaign closes. '
                    'Fighters apply because they trust the pathway is real.',
                    style: TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmapPhaseCard(_RoadmapPhase p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: p.color.withValues(alpha: 0.30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(p.icon, color: p.color, size: 18),
                const SizedBox(width: 8),
                Text(
                  p.phase,
                  style: TextStyle(
                    color: p.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              p.subtitle,
              style: TextStyle(
                color: p.color.withValues(alpha: 0.75),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 10),
            ...p.bullets.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5, right: 8),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: p.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        b,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart, color: AppTheme.accentTeal, size: 20),
              SizedBox(width: 8),
              Text(
                'Engagement (Last 7 Days)',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 100),
                      const FlSpot(1, 150),
                      const FlSpot(2, 120),
                      const FlSpot(3, 180),
                      const FlSpot(4, 200),
                      const FlSpot(5, 250),
                      const FlSpot(6, 300),
                    ],
                    isCurved: true,
                    color: AppTheme.neonGreen,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.neonGreen.withValues(alpha: 0.3),
                          AppTheme.neonGreen.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInternationalExpansionEngine() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final countryCode = (locale.countryCode?.isNotEmpty == true)
        ? locale.countryCode!
        : 'US';
    final langCode = locale.languageCode;
    final script = MarketExpansionPlaybook.scriptFor(
      countryCode: countryCode,
      languageCode: langCode,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.cardBackground,
            AppTheme.accentTeal.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.neonGreen.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flight_takeoff, color: AppTheme.neonGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Fight Tube Expansion Engine',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Mission: DFC is FightPipe - we hunt fighters, connect promoters, and turn opportunities into real pro-show outcomes. Use Australia (Melbourne/Gold Coast), Tokyo, and partner destinations to create hope, reveal hidden talent, and grow awareness while driving stronger ticket demand.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const _ExpansionTag(
                'Open Destinations',
                'Melbourne • Gold Coast • Tokyo • partner markets',
              ),
              const _ExpansionTag(
                'Open Feeder Regions',
                'India • Africa • NZ • PNG • Solomon Islands • expanding',
              ),
              const _ExpansionTag(
                'Readiness Gate',
                'Coach Ref • Medical Clear • Weight Ready • Passport',
              ),
              const _ExpansionTag(
                'Impact Goal',
                'Hope + awareness + talent discovery + ticket uplift',
              ),
              const _ExpansionTag(
                'Destination Principle',
                'Sometimes the destination is the product, not only the fight',
              ),
              _ExpansionTag(
                'Region Detected',
                '${script.region.toUpperCase()} • $countryCode',
              ),
              _ExpansionTag(
                'Top Popularity Driver',
                script.prominentFightBrand,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildMetricRow('Localized market headline', script.gatewayHeadline),
          _buildMetricRow('Localized gym offer', script.gymOffer),
          _buildMetricRow('Creator amplifier model', script.creatorAmplifier),
          _buildMetricRow('Pipeline (qualified contenders)', '48'),
          _buildMetricRow('Promoters requesting foreign matchups', '17'),
          _buildMetricRow(
            'Est. int. ticket uplift per major card',
            '+12% to +22%',
          ),
          _buildMetricRow('Destination-led subscriber conversion', '4.8%'),
          _buildMetricRow('Open partner events onboarded (30d)', '26'),
          _buildMetricRow('Opportunity applications (30d)', '1,340'),
          _buildMetricRow('Application to ticket conversion', '11.6%'),
        ],
      ),
    );
  }

  Widget _buildCreatorConversionEngine() {
    // Creator funnel from user scenario.
    const tiktokSubs = 80000;
    const youtubeSubs = 15000;
    const overlapRate = 0.25; // Audience overlap across platforms
    const monthlyRevenueGoal = 5000.0;

    final overlap = (youtubeSubs * overlapRate).round();
    final uniqueReach = tiktokSubs + youtubeSubs - overlap;

    // Paid conversion scenarios from unique reach.
    final lowPaid = (uniqueReach * 0.02).round();
    final basePaid = (uniqueReach * 0.05).round();
    final highPaid = (uniqueReach * 0.08).round();

    // Price points for dream-fight campaigns.
    const communityPass = 2.99;
    const mainCard = 9.99;

    final baseCommunityRevenue = basePaid * communityPass;
    final baseMainRevenue = basePaid * mainCard;
    final targetViewersCommunity = (monthlyRevenueGoal / communityPass).ceil();
    final targetViewersMain = (monthlyRevenueGoal / mainCard).ceil();

    // Mega-creator scenario: fighter with 1M subs wanting Australia feature card.
    const megaSubs = 1000000;
    const megaLowConv = 0.01; // 1%
    const megaBaseConv = 0.025; // 2.5%
    const megaHighConv = 0.04; // 4%
    const megaPpvPrice = 12.99;
    const promoterShare = 0.72;

    final megaLowViewers = (megaSubs * megaLowConv).round();
    final megaBaseViewers = (megaSubs * megaBaseConv).round();
    final megaHighViewers = (megaSubs * megaHighConv).round();

    final megaBaseGross = megaBaseViewers * megaPpvPrice;
    final megaBasePromoter = megaBaseGross * promoterShare;
    final megaBasePlatform = megaBaseGross - megaBasePromoter;

    // Direct stream math requested: 1,000,000 paid views.
    const millionViews = 1000000;
    final grossAt299 = millionViews * 2.99;
    final grossAt999 = millionViews * 9.99;
    final grossAt1299 = millionViews * 12.99;
    final promoterAt1299 = grossAt1299 * promoterShare;
    final platformAt1299 = grossAt1299 - promoterAt1299;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentPurple.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.campaign, color: AppTheme.accentPurple, size: 20),
              SizedBox(width: 8),
              Text(
                'FightPipe Creator-to-Paid Viewer Engine',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Goal: Turn creator followers into paid viewers for a dream-fight campaign with clear steps: teaser content, waitlist, countdown, and checkout.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          _buildMetricRow('TikTok followers (2 weeks)', tiktokSubs.toString()),
          _buildMetricRow('YouTube subscribers', youtubeSubs.toString()),
          _buildMetricRow(
            'Estimated overlap',
            '${(overlapRate * 100).round()}%',
          ),
          _buildMetricRow(
            'Net unique reachable audience',
            uniqueReach.toString(),
          ),
          _buildMetricRow(
            'Monthly revenue goal',
            '\$${monthlyRevenueGoal.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 12),
          _buildMetricRow('Paid viewers (low 2%)', lowPaid.toString()),
          _buildMetricRow('Paid viewers (base 5%)', basePaid.toString()),
          _buildMetricRow('Paid viewers (high 8%)', highPaid.toString()),
          _buildMetricRow(
            'Needed viewers @ \$2.99 offer',
            targetViewersCommunity.toString(),
          ),
          _buildMetricRow(
            'Needed viewers @ \$9.99 offer',
            targetViewersMain.toString(),
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            'Base revenue @ community pass (\$2.99)',
            '\$${baseCommunityRevenue.toStringAsFixed(0)}',
          ),
          _buildMetricRow(
            'Base revenue @ main card (\$9.99)',
            '\$${baseMainRevenue.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 12),
          const Text(
            'Mega creator scenario (1M subscribers -> Australia PPV headline):',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          _buildMetricRow(
            'Projected viewers (low 1%)',
            megaLowViewers.toString(),
          ),
          _buildMetricRow(
            'Projected viewers (base 2.5%)',
            megaBaseViewers.toString(),
          ),
          _buildMetricRow(
            'Projected viewers (high 4%)',
            megaHighViewers.toString(),
          ),
          _buildMetricRow(
            'Base gross @ \$12.99 PPV',
            '\$${megaBaseGross.toStringAsFixed(0)}',
          ),
          _buildMetricRow(
            'Promoter/event payout (72%)',
            '\$${megaBasePromoter.toStringAsFixed(0)}',
          ),
          _buildMetricRow(
            'Platform revenue (28%)',
            '\$${megaBasePlatform.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 12),
          const Text(
            'Direct stream math (1,000,000 paid views):',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          _buildMetricRow(
            'Gross @ \$2.99',
            '\$${grossAt299.toStringAsFixed(0)}',
          ),
          _buildMetricRow(
            'Gross @ \$9.99',
            '\$${grossAt999.toStringAsFixed(0)}',
          ),
          _buildMetricRow(
            'Gross @ \$12.99',
            '\$${grossAt1299.toStringAsFixed(0)}',
          ),
          _buildMetricRow(
            'Promoter/event payout @ \$12.99 (72%)',
            '\$${promoterAt1299.toStringAsFixed(0)}',
          ),
          _buildMetricRow(
            'DFC platform @ \$12.99 (28%)',
            '\$${platformAt1299.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 12),
          const Text(
            'Execution script (faceless mode): 1) Voiceover + gloves/padwork clips only, 2) Waitlist CTA, 3) Region-specific offer, 4) 72h countdown, 5) Live watch-party push, 6) Replay upsell + membership.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Minor safety policy: no face reveal, guardian-managed accounts, no direct DMs, and age-appropriate moderation/compliance enabled.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStakeholderPpvStrategyPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.neonGreen.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.hub, color: AppTheme.neonGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Stakeholder PPV Strategy Engine',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Whole-point model: DFC turns creator attention into paid PPV demand, then distributes value across events, promoters, gyms, and fighters in one connected system.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Destination economics: in many campaigns, the city and journey (Melbourne, Gold Coast, Tokyo, partner hubs) drive demand as strongly as the matchup itself.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ExpansionTag(
                'Events',
                'Bigger international cards + stronger gate + higher PPV upside',
              ),
              _ExpansionTag(
                'Promoters',
                'Faster matchmaking, better talent access, and paid audience carry-over',
              ),
              _ExpansionTag(
                'Gyms',
                'Team ticket bundles, trial exposure, and prospect pipeline growth',
              ),
              _ExpansionTag(
                'Fighters',
                'Verified pathway from local to pro to global destination cards',
              ),
              _ExpansionTag(
                'Fans',
                'More relevant fights by region with affordable + premium PPV tiers',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildMetricRow(
            'Cross-platform inflow (major creator ecosystems)',
            '1.9M monthly reachable',
          ),
          _buildMetricRow(
            'Warm audience -> paid sub conversion target',
            '3.5% to 6.0%',
          ),
          _buildMetricRow(
            'Paid subs feeding PPV campaigns (monthly)',
            '66k to 114k',
          ),
          _buildMetricRow('PPV buyers from paid-sub pool target', '18% to 26%'),
          _buildMetricRow(
            'Projected PPV buyers per flagship card',
            '12k to 29k',
          ),
          _buildMetricRow(
            'Promoter/event expected revenue lift',
            '+18% to +37%',
          ),
          const SizedBox(height: 10),
          const Text(
            'Channel script: creator clips -> waitlist -> paid subscriber offers -> PPV launch countdown -> watch party activation -> replay and membership upsell.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthChart() {
    if (_growthMetrics == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.greenAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'User Growth',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(toY: 50, color: AppTheme.accentTeal),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(toY: 80, color: AppTheme.accentTeal),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(toY: 120, color: AppTheme.accentTeal),
                    ],
                  ),
                  BarChartGroupData(
                    x: 3,
                    barRods: [
                      BarChartRodData(toY: 150, color: AppTheme.accentTeal),
                    ],
                  ),
                  BarChartGroupData(
                    x: 4,
                    barRods: [
                      BarChartRodData(toY: 200, color: AppTheme.neonGreen),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                'Mon',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              Text(
                'Tue',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              Text(
                'Wed',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              Text(
                'Thu',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              Text(
                'Fri',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics() {
    if (_growthMetrics == null) return const SizedBox.shrink();
    final totalUsers = _growthMetrics!.totalUsers;
    final growthRate = totalUsers > 0
        ? (_growthMetrics!.newUsersToday / totalUsers * 100)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights, color: AppTheme.accentPurple, size: 20),
              SizedBox(width: 8),
              Text(
                'Key Metrics',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetricRow(
            'Invites Sent (7d)',
            _growthMetrics!.invitesSent.toString(),
          ),
          _buildMetricRow(
            'Active Regions',
            _growthMetrics!.activeRegions.toString(),
          ),
          _buildMetricRow(
            'New Users Today',
            _growthMetrics!.newUsersToday.toString(),
          ),
          _buildMetricRow('Growth Rate', '+${growthRate.toStringAsFixed(2)}%'),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FunnelStep {
  final String label;
  final IconData icon;
  final Color color;
  final String value;
  final double barY;
  final String detail;
  const _FunnelStep({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.barY,
    required this.detail,
  });
}

class _PortalRevenue {
  final String country;
  final int buyers;
  final double price;
  final double barFraction;
  final Color color;
  const _PortalRevenue({
    required this.country,
    required this.buyers,
    required this.price,
    required this.barFraction,
    required this.color,
  });
}

class _FlowStep {
  final IconData icon;
  final String label;
  final Color color;
  const _FlowStep({
    required this.icon,
    required this.label,
    required this.color,
  });
}

class _RoadmapPhase {
  final IconData icon;
  final Color color;
  final String phase;
  final String title;
  final String subtitle;
  final List<String> bullets;

  const _RoadmapPhase({
    required this.icon,
    required this.color,
    required this.phase,
    required this.title,
    required this.subtitle,
    required this.bullets,
  });
}

class _ExpansionTag extends StatelessWidget {
  final String label;
  final String value;

  const _ExpansionTag(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: AppTheme.accentTeal,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
