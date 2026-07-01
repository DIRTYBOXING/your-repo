import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/router_config.dart' as rc;
import '../../../shared/services/promotion_run_service.dart';
import '../widgets/command_center_global_panels.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC COMMAND CENTER — 7-Panel Platform Powerhouse
///
/// Panel 1: Live Production Control
/// Panel 2: Global Distribution Map
/// Panel 3: PPV Sales Engine
/// Panel 4: Campaign Performance
/// Panel 5: SEO Dominance
/// Panel 6: System Health
/// Panel 7: WOW Factor / Highlights
/// ═══════════════════════════════════════════════════════════════════════════
class DfcCommandCenterScreen extends StatefulWidget {
  const DfcCommandCenterScreen({super.key});

  @override
  State<DfcCommandCenterScreen> createState() => _DfcCommandCenterScreenState();
}

class _DfcCommandCenterScreenState extends State<DfcCommandCenterScreen> {
  // Live demo data
  final _liveStats = const {
    'activeViewers': 2847,
    'peakViewers': 5120,
    'totalRevenue': 48750.0,
    'ppvBuys': 1624,
    'activeCampaigns': 12,
    'countries': 38,
    'liveStreams': 3,
    'socialReach': 1250000,
    'seoScore': 87,
    'uptimePercent': 99.7,
  };

  final List<_GlobalRegion> _regions = const [
    _GlobalRegion('🇦🇺', 'Australia', 1245, 38.2, true),
    _GlobalRegion('🇺🇸', 'USA', 892, 27.4, true),
    _GlobalRegion('🇬🇧', 'UK', 312, 9.6, true),
    _GlobalRegion('🇹🇭', 'Thailand', 198, 6.1, false),
    _GlobalRegion('🇧🇷', 'Brazil', 145, 4.5, false),
    _GlobalRegion('🇳🇿', 'New Zealand', 87, 2.7, false),
    _GlobalRegion('🇯🇵', 'Japan', 64, 2.0, false),
    _GlobalRegion('🇵🇭', 'Philippines', 52, 1.6, false),
    _GlobalRegion('🇳🇬', 'Nigeria', 41, 1.3, false),
    _GlobalRegion('🇿🇦', 'South Africa', 38, 1.2, false),
    _GlobalRegion('🇩🇪', 'Germany', 29, 0.9, false),
    _GlobalRegion('🇮🇪', 'Ireland', 24, 0.7, false),
  ];

  final List<_CampaignRow> _campaigns = const [
    _CampaignRow('IBC IV Gold Coast', 'event', 82.4, 14200, 'active'),
    _CampaignRow('Christine Ferea BKFC', 'fighter', 91.2, 8700, 'active'),
    _CampaignRow('Stamp Fairtex ONE', 'fighter', 78.5, 6100, 'active'),
    _CampaignRow('Eternal MMA 81', 'event', 65.0, 3400, 'scheduled'),
    _CampaignRow('BKFC Knucklemania', 'event', 70.3, 5200, 'active'),
    _CampaignRow('DFC Coffee Not Coffin', 'brand', 55.0, 12800, 'active'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('DFC COMMAND CENTER'),
        backgroundColor: AppTheme.cardBackground,
        foregroundColor: AppTheme.neonCyan,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Owner Command Center',
            onPressed: () =>
                context.push(rc.RouterConfig.ownerCommandCenterPath),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _buildLiveBar(),
            const SizedBox(height: 12),
            _buildPanel1LiveProduction(),
            const SizedBox(height: 12),
            _buildPanel2GlobalDistribution(),
            const SizedBox(height: 12),
            _buildPanel3PpvSalesEngine(),
            const SizedBox(height: 12),
            _buildPanel4CampaignPerformance(),
            const SizedBox(height: 12),
            _buildPanel5SeoDominance(),
            const SizedBox(height: 12),
            _buildPanel6SystemHealth(),
            const SizedBox(height: 12),
            _buildPanel7WowFactor(),
            const SizedBox(height: 24),
            const SizedBox(height: 16),
            // Global Expansion Engine Panels
            const CommandCenterGlobalPanels(),
          ],
        ),
      ),
    );
  }

  // ── LIVE STATUS BAR ─────────────────────────────────────────────────────
  Widget _buildLiveBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade900.withValues(alpha: 0.6),
            AppTheme.cardBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${_liveStats['activeViewers']} viewers',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            '${_liveStats['countries']} countries',
            style: const TextStyle(color: AppTheme.neonCyan, fontSize: 13),
          ),
          const SizedBox(width: 16),
          Text(
            '${_liveStats['liveStreams']} streams',
            style: const TextStyle(color: Colors.greenAccent, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── PANEL 1: LIVE PRODUCTION CONTROL ────────────────────────────────────
  Widget _buildPanel1LiveProduction() {
    return _panelCard(
      icon: Icons.videocam,
      title: 'LIVE PRODUCTION CONTROL',
      color: Colors.redAccent,
      child: Column(
        children: [
          Row(
            children: [
              _metricTile(
                'Active Streams',
                '${_liveStats['liveStreams']}',
                Colors.greenAccent,
              ),
              _metricTile(
                'Peak Viewers',
                '${_liveStats['peakViewers']}',
                Colors.amberAccent,
              ),
              _metricTile('Avg Bitrate', '4.2 Mbps', AppTheme.neonCyan),
            ],
          ),
          const SizedBox(height: 12),
          _liveStreamRow('IBC IV: Gold Coast', 'LIVE', Colors.redAccent, 1245),
          _liveStreamRow('BKFC Training Camp', 'LIVE', Colors.redAccent, 892),
          _liveStreamRow('DFC Studio Open Mat', 'LIVE', Colors.redAccent, 710),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _actionButton('PPV Hub', Icons.live_tv, () {
                  context.push(rc.RouterConfig.ppvHubPath);
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  'Stream Control',
                  Icons.settings_input_antenna,
                  () {
                    context.push(rc.RouterConfig.ownerCommandCenterPath);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _liveStreamRow(
    String name,
    String status,
    Color statusColor,
    int viewers,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Text(
            '$viewers viewers',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ── PANEL 2: GLOBAL DISTRIBUTION MAP ────────────────────────────────────
  Widget _buildPanel2GlobalDistribution() {
    return _panelCard(
      icon: Icons.public,
      title: 'GLOBAL DISTRIBUTION',
      color: Colors.blueAccent,
      child: Column(
        children: [
          Row(
            children: [
              _metricTile(
                'Countries',
                '${_liveStats['countries']}',
                Colors.blueAccent,
              ),
              _metricTile('Total Users', '3,257', AppTheme.neonCyan),
              _metricTile('Growth', '+12.4%', Colors.greenAccent),
            ],
          ),
          const SizedBox(height: 12),
          ..._regions.take(8).map(_regionRow),
          const SizedBox(height: 8),
          _actionButton('Full Globe View', Icons.map, () {
            context.push(rc.RouterConfig.combatMapPath);
          }),
        ],
      ),
    );
  }

  Widget _regionRow(_GlobalRegion r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(r.flag, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              r.country,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          SizedBox(
            width: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: r.percent / 100,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(
                  r.isLive ? Colors.greenAccent : Colors.blueAccent,
                ),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 50,
            child: Text(
              '${r.users}',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: r.isLive ? Colors.greenAccent : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── PANEL 3: PPV SALES ENGINE ───────────────────────────────────────────
  Widget _buildPanel3PpvSalesEngine() {
    return _panelCard(
      icon: Icons.attach_money,
      title: 'PPV SALES ENGINE',
      color: Colors.amberAccent,
      child: Column(
        children: [
          Row(
            children: [
              _metricTile(
                'Revenue',
                '\$${(_liveStats['totalRevenue'] as double).toStringAsFixed(0)}',
                Colors.amberAccent,
              ),
              _metricTile(
                'PPV Buys',
                '${_liveStats['ppvBuys']}',
                Colors.greenAccent,
              ),
              _metricTile('Conv Rate', '8.2%', AppTheme.neonCyan),
            ],
          ),
          const SizedBox(height: 12),
          _ppvRow('IBC IV: Gold Coast PPV', 812, 24360.0),
          _ppvRow('BKFC Knucklemania IV', 532, 15960.0),
          _ppvRow('Eternal MMA 81', 280, 8400.0),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _actionButton('PPV Analytics', Icons.analytics, () {
                  context.push(rc.RouterConfig.ppvHubPath);
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton('Pricing Engine', Icons.price_change, () {
                  context.push(rc.RouterConfig.promoterPricingPath);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ppvRow(String title, int buys, double revenue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Text(
            '$buys buys',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '\$${revenue.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.amberAccent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── PANEL 4: CAMPAIGN PERFORMANCE ───────────────────────────────────────
  Widget _buildPanel4CampaignPerformance() {
    return _panelCard(
      icon: Icons.campaign,
      title: 'CAMPAIGN PERFORMANCE',
      color: Colors.purpleAccent,
      child: Column(
        children: [
          Row(
            children: [
              _metricTile(
                'Active',
                '${_liveStats['activeCampaigns']}',
                Colors.purpleAccent,
              ),
              _metricTile('Reach', '1.25M', Colors.greenAccent),
              _metricTile('ROI', '340%', Colors.amberAccent),
            ],
          ),
          const SizedBox(height: 12),
          ..._campaigns.map(_campaignRow),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _actionButton('Promo Center', Icons.rocket_launch, () {
                  context.push(rc.RouterConfig.promoCommandCenterPath);
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton('Marketing HQ', Icons.business, () {
                  context.push(rc.RouterConfig.marketingHQPath);
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push(rc.RouterConfig.campaignOpsPath),
              icon: const Icon(
                Icons.warning_amber,
                size: 16,
                color: Colors.black,
              ),
              label: const Text(
                'OPS & DLQ',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campaignRow(_CampaignRow c) {
    final color = c.status == 'active'
        ? Colors.greenAccent
        : Colors.amberAccent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              c.name,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              '${c.score.toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 55,
            child: Text(
              '${(c.reach / 1000).toStringAsFixed(1)}k',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── PANEL 5: SEO DOMINANCE ──────────────────────────────────────────────
  Widget _buildPanel5SeoDominance() {
    return _panelCard(
      icon: Icons.search,
      title: 'SEO DOMINANCE',
      color: Colors.tealAccent,
      child: Column(
        children: [
          Row(
            children: [
              _metricTile(
                'SEO Score',
                '${_liveStats['seoScore']}',
                Colors.tealAccent,
              ),
              _metricTile('Indexed', '12.4k', AppTheme.neonCyan),
              _metricTile('Rank Δ', '+14', Colors.greenAccent),
            ],
          ),
          const SizedBox(height: 12),
          _seoRow('datafightcentral.com', 1, '+2'),
          _seoRow('bare knuckle fighting', 3, '+5'),
          _seoRow('mma fight events australia', 2, '+3'),
          _seoRow('combat sports platform', 4, '+8'),
          _seoRow('ppv combat streaming', 5, '+12'),

        ],
      ),
    );
  }

  Widget _seoRow(String keyword, int rank, String change) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.neonCyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              keyword,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Text(
            change,
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── PANEL 6: SYSTEM HEALTH ──────────────────────────────────────────────
  Widget _buildPanel6SystemHealth() {
    return _panelCard(
      icon: Icons.monitor_heart,
      title: 'SYSTEM HEALTH',
      color: Colors.greenAccent,
      child: FutureBuilder<Map<String, int>>(
        future: PromotionRunService().getHealthSummary(),
        builder: (ctx, snap) {
          final dlq = snap.data?['dlq'] ?? 0;
          final errors = snap.data?['error'] ?? 0;
          final workerHealthy = dlq == 0 && errors == 0;
          return Column(
            children: [
              Row(
                children: [
                  _metricTile(
                    'Uptime',
                    '${_liveStats['uptimePercent']}%',
                    Colors.greenAccent,
                  ),
                  _metricTile('Latency', '42ms', AppTheme.neonCyan),
                  _metricTile(
                    'DLQ',
                    '$dlq',
                    dlq > 0 ? Colors.redAccent : Colors.greenAccent,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _healthRow('Firebase Auth', true, '12ms'),
              _healthRow('Firestore', true, '28ms'),
              _healthRow('Cloud Functions', true, '45ms'),
              _healthRow('Mux Streaming', true, '38ms'),
              _healthRow('CDN / Assets', true, '15ms'),
              _healthRow('AI Engines', true, '120ms'),
              _healthRow(
                'Promotion Worker',
                workerHealthy,
                workerHealthy ? 'ok' : '$errors err · $dlq dlq',
              ),
              const SizedBox(height: 8),
              _actionButton('Full Health Report', Icons.health_and_safety, () {
                context.push(rc.RouterConfig.ownerCommandCenterPath);
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _healthRow(String service, bool healthy, String latency) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            healthy ? Icons.check_circle : Icons.error,
            color: healthy ? Colors.greenAccent : Colors.redAccent,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              service,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Text(
            latency,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ── PANEL 7: WOW FACTOR ─────────────────────────────────────────────────
  Widget _buildPanel7WowFactor() {
    return _panelCard(
      icon: Icons.auto_awesome,
      title: 'WOW FACTOR',
      color: Colors.pinkAccent,
      child: Column(
        children: [
          _wowCard(
            '🏆',
            'FIGHT OF THE WEEK',
            'Christine Ferea vs Katie Zechowski — BKFC 67',
            'Las Vegas, USA • 1.2M views',
          ),
          const SizedBox(height: 8),
          _wowCard(
            '🔥',
            'VIRAL MOMENT',
            'Stamp Fairtex spinning elbow KO',
            'Bangkok, Thailand • 840k shares',
          ),
          const SizedBox(height: 8),
          _wowCard(
            '🌏',
            'GLOBAL MILESTONE',
            'DFC crosses 38 country reach',
            'Platform growth +18% this month',
          ),
          const SizedBox(height: 8),
          _wowCard(
            '💰',
            'PPV RECORD',
            'IBC IV breaks DFC PPV sales record',
            'Gold Coast, Australia • \$24.3k revenue',
          ),
        ],
      ),
    );
  }

  Widget _wowCard(String emoji, String title, String subtitle, String detail) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.pinkAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                Text(
                  detail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SHARED BUILDERS ─────────────────────────────────────────────────────

  Widget _panelCard({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, Color color) {
    return Expanded(
      child: Column(
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
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.neonCyan,
        side: BorderSide(color: AppTheme.neonCyan.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

// ── Data classes ────────────────────────────────────────────────────────────
class _GlobalRegion {
  final String flag;
  final String country;
  final int users;
  final double percent;
  final bool isLive;
  const _GlobalRegion(
    this.flag,
    this.country,
    this.users,
    this.percent,
    this.isLive,
  );
}

class _CampaignRow {
  final String name;
  final String type;
  final double score;
  final int reach;
  final String status;
  const _CampaignRow(this.name, this.type, this.score, this.reach, this.status);
}
