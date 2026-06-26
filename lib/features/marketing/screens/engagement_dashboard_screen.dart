import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/engagement_tracker_service.dart';

/// Engagement Dashboard Screen — Top content, hourly heatmap, event breakdown.
/// Reads from `engagement_events` Firestore collection via EngagementTrackerService.
class EngagementDashboardScreen extends StatefulWidget {
  const EngagementDashboardScreen({super.key});

  @override
  State<EngagementDashboardScreen> createState() =>
      _EngagementDashboardScreenState();
}

class _EngagementDashboardScreenState extends State<EngagementDashboardScreen> {
  final EngagementTrackerService _tracker = EngagementTrackerService();

  bool _loading = true;
  int _totalEvents = 0;
  Map<String, int> _topContent = {};
  Map<int, int> _heatmap = {};
  Map<String, int> _breakdown = {};
  String _dateRange = 'today';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  DateTime get _start {
    switch (_dateRange) {
      case '7d':
        return DateTime.now().subtract(const Duration(days: 7));
      case '30d':
        return DateTime.now().subtract(const Duration(days: 30));
      default: // today
        return DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );
    }
  }

  DateTime get _end => DateTime.now();

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _tracker.getTotalEvents(start: _start, end: _end),
        _tracker.getTopContent(start: _start, end: _end, limit: 10),
        _tracker.getHourlyHeatmap(EngagementTrackerService.todayKey()),
        _tracker.getEventBreakdown(start: _start, end: _end),
      ]);

      if (mounted) {
        setState(() {
          _totalEvents = results[0] as int;
          _topContent = results[1] as Map<String, int>;
          _heatmap = results[2] as Map<int, int>;
          _breakdown = results[3] as Map<String, int>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('ENGAGEMENT DASHBOARD'),
        backgroundColor: AppTheme.cardBackground,
        foregroundColor: const Color(0xFFFFD700),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.neonCyan),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date range filter
                    _buildDateFilter(),
                    const SizedBox(height: 16),

                    // Total events
                    _buildTotalCard(),
                    const SizedBox(height: 20),

                    // Event breakdown
                    _sectionTitle('EVENT BREAKDOWN', AppTheme.neonMagenta),
                    const SizedBox(height: 10),
                    _buildBreakdown(),
                    const SizedBox(height: 20),

                    // Hourly heatmap
                    _sectionTitle(
                      'HOURLY ACTIVITY (TODAY)',
                      AppTheme.neonGreen,
                    ),
                    const SizedBox(height: 10),
                    _buildHeatmap(),
                    const SizedBox(height: 20),

                    // Top content
                    _sectionTitle('TOP CONTENT', AppTheme.neonCyan),
                    const SizedBox(height: 10),
                    _buildTopContent(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDateFilter() {
    final options = [('today', 'Today'), ('7d', '7 Days'), ('30d', '30 Days')];

    return Row(
      children: options.map((o) {
        final isActive = _dateRange == o.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(
              o.$2,
              style: TextStyle(
                color: isActive
                    ? AppTheme.primaryBackground
                    : AppTheme.textPrimary,
                fontSize: 12,
              ),
            ),
            selected: isActive,
            selectedColor: const Color(0xFFFFD700),
            backgroundColor: AppTheme.cardBackground,
            onSelected: (_) {
              setState(() => _dateRange = o.$1);
              _loadData();
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withValues(alpha: 0.15),
            AppTheme.cardBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Text(
            _formatNumber(_totalEvents),
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 40,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'TOTAL ENGAGEMENT EVENTS',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdown() {
    if (_breakdown.isEmpty) {
      return _emptyState('No events recorded yet');
    }

    final sorted = _breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.isNotEmpty ? sorted.first.value : 1;

    return Column(
      children: sorted.map((entry) {
        final color = _eventColor(entry.key);
        final ratio = maxVal > 0 ? entry.value / maxVal : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(_eventIcon(entry.key), color: color, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        entry.key.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${entry.value}',
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  backgroundColor: AppTheme.primaryBackground,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeatmap() {
    if (_heatmap.isEmpty) {
      return _emptyState('No hourly data yet');
    }

    final maxVal = _heatmap.values.fold<int>(0, (m, v) => v > m ? v : m);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Hours grid (4 rows of 6)
          for (int row = 0; row < 4; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: List.generate(6, (col) {
                  final hour = row * 6 + col;
                  final count = _heatmap[hour] ?? 0;
                  final intensity = maxVal > 0
                      ? (count / maxVal).clamp(0.0, 1.0)
                      : 0.0;

                  return Expanded(
                    child: Tooltip(
                      message:
                          '${hour.toString().padLeft(2, '0')}:00 — $count events',
                      child: Container(
                        height: 36,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.neonGreen.withValues(
                            alpha: 0.1 + intensity * 0.8,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            hour.toString().padLeft(2, '0'),
                            style: TextStyle(
                              color: intensity > 0.5
                                  ? AppTheme.primaryBackground
                                  : AppTheme.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Low',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
              Container(
                height: 8,
                width: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.neonGreen.withValues(alpha: 0.1),
                      AppTheme.neonGreen,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Text(
                'High',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopContent() {
    if (_topContent.isEmpty) {
      return _emptyState('No content engagement yet');
    }

    int rank = 1;
    return Column(
      children: _topContent.entries.take(10).map((entry) {
        final r = rank++;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: r <= 3
                ? Border.all(
                    color: r == 1
                        ? const Color(0xFFFFD700)
                        : r == 2
                        ? AppTheme.neonCyan
                        : AppTheme.neonMagenta,
                    width: 0.5,
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: r <= 3
                      ? (r == 1
                                ? const Color(0xFFFFD700)
                                : r == 2
                                ? AppTheme.neonCyan
                                : AppTheme.neonMagenta)
                            .withValues(alpha: 0.2)
                      : AppTheme.primaryBackground,
                ),
                child: Center(
                  child: Text(
                    '#$r',
                    style: TextStyle(
                      color: r <= 3
                          ? (r == 1
                                ? const Color(0xFFFFD700)
                                : r == 2
                                ? AppTheme.neonCyan
                                : AppTheme.neonMagenta)
                          : AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.key.length > 24
                      ? '${entry.key.substring(0, 24)}...'
                      : entry.key,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${entry.value}',
                style: const TextStyle(
                  color: AppTheme.neonCyan,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _emptyState(String msg) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        const Icon(Icons.inbox, color: AppTheme.textMuted, size: 36),
        const SizedBox(height: 8),
        Text(
          msg,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
      ],
    ),
  );

  Widget _sectionTitle(String text, Color color) => Text(
    text,
    style: TextStyle(
      color: color,
      fontSize: 15,
      fontWeight: FontWeight.w800,
      letterSpacing: 2,
    ),
  );

  Color _eventColor(String event) {
    switch (event) {
      case 'view':
        return AppTheme.neonCyan;
      case 'click':
        return AppTheme.neonOrange;
      case 'like':
        return AppTheme.neonMagenta;
      case 'share':
        return AppTheme.neonGreen;
      case 'navigation':
        return AppTheme.neonPurple;
      case 'conversion':
        return const Color(0xFFFFD700);
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _eventIcon(String event) {
    switch (event) {
      case 'view':
        return Icons.visibility;
      case 'click':
        return Icons.touch_app;
      case 'like':
        return Icons.favorite;
      case 'share':
        return Icons.share;
      case 'navigation':
        return Icons.route;
      case 'conversion':
        return Icons.star;
      default:
        return Icons.circle;
    }
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
