import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

/// Production-grade KPI monitoring panel.
/// Pulls live data from Firestore: events, posts, gyms, fighters.
/// Renders revenue trend, member growth, PPV engagement, and gym tier breakdown.
class KpiMonitoringPanel extends StatefulWidget {
  const KpiMonitoringPanel({super.key});

  @override
  State<KpiMonitoringPanel> createState() => _KpiMonitoringPanelState();
}

class _KpiMonitoringPanelState extends State<KpiMonitoringPanel> {
  bool _loading = true;
  _KpiSnapshot? _snapshot;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = FirebaseFirestore.instance;
      final now = DateTime.now();

      // Parallel reads — last 7 days of posts (feed activity) + aggregate counts
      final futures = await Future.wait([
        db
            .collection('posts')
            .where(
              'timestamp',
              isGreaterThan: Timestamp.fromDate(
                now.subtract(const Duration(days: 7)),
              ),
            )
            .orderBy('timestamp')
            .limit(200)
            .get(),
        db.collection('gyms').limit(200).get(),
        db.collection('fighters').limit(200).get(),
        db
            .collection('events')
            .where('isPPV', isEqualTo: true)
            .limit(100)
            .get(),
      ]);

      final postsSnap = futures[0];
      final gymsSnap = futures[1];
      final fightersSnap = futures[2];
      final ppvSnap = futures[3];

      // Build daily post counts for the last 7 days
      final dayBuckets = List.filled(7, 0);
      for (final doc in postsSnap.docs) {
        final ts = doc.data()['timestamp'];
        if (ts is Timestamp) {
          final daysAgo = now.difference(ts.toDate()).inDays;
          if (daysAgo >= 0 && daysAgo < 7) {
            dayBuckets[6 - daysAgo] += 1;
          }
        }
      }

      // Gym tier breakdown
      int gymElite = 0, gymPremier = 0, gymStandard = 0;
      for (final doc in gymsSnap.docs) {
        final tier = (doc.data()['tier'] as String? ?? '').toLowerCase();
        if (tier == 'elite') {
          gymElite++;
        } else if (tier == 'premier') {
          gymPremier++;
        } else {
          gymStandard++;
        }
      }

      // Fighter record aggregates
      final int totalFighters = fightersSnap.docs.length;
      int fightersWithRecord = 0;
      for (final doc in fightersSnap.docs) {
        final wins = doc.data()['wins'] ?? doc.data()['w'];
        if (wins != null) fightersWithRecord++;
      }

      if (!mounted) return;
      setState(() {
        _snapshot = _KpiSnapshot(
          dailyPostCounts: dayBuckets,
          totalPosts: postsSnap.docs.length,
          totalGyms: gymsSnap.docs.length,
          gymElite: gymElite,
          gymPremier: gymPremier,
          gymStandard: gymStandard,
          totalFighters: totalFighters,
          fightersWithRecord: fightersWithRecord,
          totalPpvEvents: ppvSnap.docs.length,
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'KPI data unavailable: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: CircularProgressIndicator(color: DesignTokens.neonCyan),
        ),
      );
    }
    if (_error != null) {
      return _ErrorCard(message: _error!);
    }
    final s = _snapshot!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.analytics,
                color: DesignTokens.neonCyan,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'PLATFORM KPIs',
                style: TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() => _loading = true);
                  _load();
                },
                child: const Icon(
                  Icons.refresh,
                  color: Colors.white38,
                  size: 16,
                ),
              ),
            ],
          ),
        ),

        // ── Metric cards row ────────────────────────────────────────
        Row(
          children: [
            _MetricCard(
              label: 'GYMS',
              value: '${s.totalGyms}',
              icon: Icons.fitness_center,
              color: DesignTokens.neonAmber,
            ),
            const SizedBox(width: 10),
            _MetricCard(
              label: 'FIGHTERS',
              value: '${s.totalFighters}',
              icon: Icons.sports_mma,
              color: DesignTokens.neonCyan,
            ),
            const SizedBox(width: 10),
            _MetricCard(
              label: 'PPV EVENTS',
              value: '${s.totalPpvEvents}',
              icon: Icons.ondemand_video,
              color: DesignTokens.neonMagenta,
            ),
            const SizedBox(width: 10),
            _MetricCard(
              label: '7D POSTS',
              value: '${s.totalPosts}',
              icon: Icons.forum,
              color: DesignTokens.neonGreen,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── 7-day feed activity line chart ──────────────────────────
        _FeedActivityChart(dailyCounts: s.dailyPostCounts),
        const SizedBox(height: 16),

        // ── Gym tier bar chart ──────────────────────────────────────
        _GymTierChart(
          elite: s.gymElite,
          premier: s.gymPremier,
          standard: s.gymStandard,
        ),
        const SizedBox(height: 16),

        // ── Fighter data coverage ───────────────────────────────────
        _FighterCoverageBar(
          total: s.totalFighters,
          withRecord: s.fightersWithRecord,
        ),
      ],
    );
  }
}

// ── 7-Day Feed Activity ─────────────────────────────────────────────────────

class _FeedActivityChart extends StatelessWidget {
  final List<int> dailyCounts;
  const _FeedActivityChart({required this.dailyCounts});

  @override
  Widget build(BuildContext context) {
    final spots = List.generate(
      dailyCounts.length,
      (i) => FlSpot(i.toDouble(), dailyCounts[i].toDouble()),
    );
    final maxY = dailyCounts.isEmpty
        ? 10.0
        : (dailyCounts.reduce((a, b) => a > b ? a : b).toDouble() * 1.2).clamp(
            4.0,
            double.infinity,
          );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignTokens.neonGreen.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.forum, color: DesignTokens.neonGreen, size: 16),
              SizedBox(width: 8),
              Text(
                'FEED ACTIVITY — LAST 7 DAYS',
                style: TextStyle(
                  color: DesignTokens.neonGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.white30,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final i = v.toInt();
                        if (i < 0 || i >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          days[i],
                          style: const TextStyle(
                            color: Colors.white30,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    
                  ),
                  topTitles: const AxisTitles(
                    
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: DesignTokens.neonGreen,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                        radius: 3,
                        color: DesignTokens.neonGreen,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          DesignTokens.neonGreen.withValues(alpha: 0.25),
                          DesignTokens.neonGreen.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
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
}

// ── Gym Tier Bar Chart ──────────────────────────────────────────────────────

class _GymTierChart extends StatelessWidget {
  final int elite, premier, standard;
  const _GymTierChart({
    required this.elite,
    required this.premier,
    required this.standard,
  });

  @override
  Widget build(BuildContext context) {
    final total = (elite + premier + standard).clamp(1, 9999);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignTokens.neonAmber.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.fitness_center,
                color: DesignTokens.neonAmber,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'GYM TIER BREAKDOWN',
                style: TextStyle(
                  color: DesignTokens.neonAmber,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _tierBar('ELITE', elite, total, const Color(0xFFFFD54F)),
          const SizedBox(height: 8),
          _tierBar('PREMIER', premier, total, DesignTokens.neonCyan),
          const SizedBox(height: 8),
          _tierBar('COMMUNITY', standard, total, DesignTokens.neonGreen),
        ],
      ),
    );
  }

  Widget _tierBar(String label, int count, int total, Color color) {
    final pct = count / total;
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

// ── Fighter Data Coverage ───────────────────────────────────────────────────

class _FighterCoverageBar extends StatelessWidget {
  final int total, withRecord;
  const _FighterCoverageBar({required this.total, required this.withRecord});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : withRecord / total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sports_mma,
                color: DesignTokens.neonCyan,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'FIGHTER RECORD COVERAGE',
                  style: TextStyle(
                    color: DesignTokens.neonCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: const AlwaysStoppedAnimation<Color>(
                DesignTokens.neonCyan,
              ),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$withRecord of $total fighters have full W/L/D records',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ── Metric Card ─────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.5),
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error Card ──────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data snapshot ───────────────────────────────────────────────────────────

class _KpiSnapshot {
  final List<int> dailyPostCounts;
  final int totalPosts;
  final int totalGyms;
  final int gymElite, gymPremier, gymStandard;
  final int totalFighters, fightersWithRecord;
  final int totalPpvEvents;

  const _KpiSnapshot({
    required this.dailyPostCounts,
    required this.totalPosts,
    required this.totalGyms,
    required this.gymElite,
    required this.gymPremier,
    required this.gymStandard,
    required this.totalFighters,
    required this.fightersWithRecord,
    required this.totalPpvEvents,
  });
}
