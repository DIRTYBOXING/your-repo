import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/campaign_service.dart';

/// Marketing Analytics Screen — Real Firestore KPI dashboard.
/// Reads live counts from posts, events, news_articles, swarm_content,
/// social_engine_posts + campaign aggregate stats.
class MarketingAnalyticsScreen extends StatefulWidget {
  const MarketingAnalyticsScreen({super.key});

  @override
  State<MarketingAnalyticsScreen> createState() =>
      _MarketingAnalyticsScreenState();
}

class _MarketingAnalyticsScreenState extends State<MarketingAnalyticsScreen> {
  final CampaignService _campaignService = CampaignService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _loading = true;
  Map<String, dynamic> _campaignStats = {};
  Map<String, int> _contentCounts = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _campaignService.getMarketingStats(),
        _getContentCounts(),
      ]);
      if (mounted) {
        setState(() {
          _campaignStats = results[0];
          _contentCounts = Map<String, int>.from(results[1]);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Map<String, int>> _getContentCounts() async {
    final collections = [
      'posts',
      'events',
      'news_articles',
      'swarm_content',
      'social_engine_posts',
      'marketing_campaigns',
    ];
    final counts = <String, int>{};
    for (final col in collections) {
      try {
        final snap = await _db.collection(col).count().get();
        counts[col] = snap.count ?? 0;
      } catch (_) {
        counts[col] = 0;
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('MARKETING ANALYTICS'),
        backgroundColor: AppTheme.cardBackground,
        foregroundColor: AppTheme.neonPurple,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.neonPurple),
            )
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('CONTENT METRICS', AppTheme.neonCyan),
                    const SizedBox(height: 12),
                    _buildContentGrid(),
                    const SizedBox(height: 24),
                    _sectionTitle('CAMPAIGN KPIs', AppTheme.neonMagenta),
                    const SizedBox(height: 12),
                    _buildCampaignKPIs(),
                    const SizedBox(height: 24),
                    _sectionTitle('ENGAGEMENT OVERVIEW', AppTheme.neonGreen),
                    const SizedBox(height: 12),
                    _buildEngagementOverview(),
                    const SizedBox(height: 24),
                    _sectionTitle('BUDGET & ROI', AppTheme.neonOrange),
                    const SizedBox(height: 12),
                    _buildBudgetSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionTitle(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildContentGrid() {
    final items = [
      _MetricTile(
        'Posts',
        _contentCounts['posts'] ?? 0,
        Icons.article,
        AppTheme.neonCyan,
      ),
      _MetricTile(
        'Events',
        _contentCounts['events'] ?? 0,
        Icons.event,
        AppTheme.neonOrange,
      ),
      _MetricTile(
        'News',
        _contentCounts['news_articles'] ?? 0,
        Icons.newspaper,
        AppTheme.neonMagenta,
      ),
      _MetricTile(
        'Swarm Content',
        _contentCounts['swarm_content'] ?? 0,
        Icons.hive,
        AppTheme.neonGreen,
      ),
      _MetricTile(
        'Social Posts',
        _contentCounts['social_engine_posts'] ?? 0,
        Icons.share,
        AppTheme.neonPurple,
      ),
      _MetricTile(
        'Campaigns',
        _contentCounts['marketing_campaigns'] ?? 0,
        Icons.campaign,
        const Color(0xFFFFD700),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final m = items[i];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: m.color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(m.icon, color: m.color, size: 24),
              const SizedBox(height: 6),
              Text(
                '${m.count}',
                style: TextStyle(
                  color: m.color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                m.label,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCampaignKPIs() {
    final kpis = [
      _KPI(
        'Total Campaigns',
        '${_campaignStats['totalCampaigns'] ?? 0}',
        AppTheme.neonCyan,
      ),
      _KPI(
        'Active',
        '${_campaignStats['activeCampaigns'] ?? 0}',
        AppTheme.neonGreen,
      ),
      _KPI(
        'Impressions',
        _formatNumber(_campaignStats['totalImpressions'] ?? 0),
        AppTheme.neonMagenta,
      ),
      _KPI(
        'Clicks',
        _formatNumber(_campaignStats['totalClicks'] ?? 0),
        AppTheme.neonOrange,
      ),
      _KPI(
        'CTR',
        '${(_campaignStats['ctr'] ?? 0.0).toStringAsFixed(2)}%',
        AppTheme.neonPurple,
      ),
      _KPI(
        'Swarm Powered',
        '${_campaignStats['swarmPowered'] ?? 0}',
        const Color(0xFFFFD700),
      ),
    ];

    return Column(
      children: kpis
          .map(
            (k) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: k.color.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    k.label,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    k.value,
                    style: TextStyle(
                      color: k.color,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEngagementOverview() {
    final conversions = _campaignStats['totalConversions'] ?? 0;
    final shares = _campaignStats['totalShares'] ?? 0;
    final clicks = _campaignStats['totalClicks'] ?? 0;
    final total = conversions + shares + clicks;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _engagementStat('Clicks', clicks, AppTheme.neonCyan),
              _engagementStat('Shares', shares, AppTheme.neonMagenta),
              _engagementStat('Conversions', conversions, AppTheme.neonGreen),
            ],
          ),
          const SizedBox(height: 12),
          // Simple bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? clicks / total : 0,
              backgroundColor: AppTheme.primaryBackground,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.neonCyan,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total Engagement: ${_formatNumber(total)}',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _engagementStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          _formatNumber(value),
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildBudgetSection() {
    final budget = (_campaignStats['totalBudget'] ?? 0.0) as double;
    final spent = (_campaignStats['totalSpent'] ?? 0.0) as double;
    final revenue = (_campaignStats['totalRevenue'] ?? 0.0) as double;
    final roi = (_campaignStats['roi'] ?? 0.0) as double;
    final utilization = budget > 0 ? spent / budget : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Budget',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              Text(
                '\$${budget.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppTheme.neonOrange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Spent',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              Text(
                '\$${spent.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppTheme.neonMagenta,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: utilization.clamp(0.0, 1.0),
              backgroundColor: AppTheme.primaryBackground,
              valueColor: AlwaysStoppedAnimation(
                utilization > 0.9 ? AppTheme.error : AppTheme.neonGreen,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Revenue',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              Text(
                '\$${revenue.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppTheme.neonGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ROI',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              Text(
                '${roi.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: roi >= 0 ? AppTheme.neonGreen : AppTheme.error,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _MetricTile {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  _MetricTile(this.label, this.count, this.icon, this.color);
}

class _KPI {
  final String label;
  final String value;
  final Color color;
  _KPI(this.label, this.value, this.color);
}
