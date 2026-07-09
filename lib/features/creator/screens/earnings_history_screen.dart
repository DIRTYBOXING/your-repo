import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/creator_dashboard_controller.dart';

/// Earnings history and detailed breakdown screen
class EarningsHistoryScreen extends StatefulWidget {
  final String creatorId;

  const EarningsHistoryScreen({Key? key, required this.creatorId})
    : super(key: key);

  @override
  State<EarningsHistoryScreen> createState() => _EarningsHistoryScreenState();
}

class _EarningsHistoryScreenState extends State<EarningsHistoryScreen> {
  late CreatorDashboardController _controller;
  bool _isLoading = true;
  Map<String, dynamic>? _earningsData;

  @override
  void initState() {
    super.initState();
    _controller = context.read<CreatorDashboardController>();
    _loadEarningsHistory();
  }

  Future<void> _loadEarningsHistory() async {
    // Load earnings history
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('Earnings History'),
        backgroundColor: AppTheme.bgCard,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonCyan),
              ),
            )
          : Consumer<CreatorDashboardController>(
              builder: (context, controller, _) {
                final earnings = controller.currentMonthEarnings;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total Lifetime Earnings
                      _buildTotalEarningsCard(controller),

                      const SizedBox(height: 24),

                      // Month Breakdown
                      _buildMonthBreakdownSection(earnings),

                      const SizedBox(height: 24),

                      // Earnings Sources
                      _buildEarningsSourcesSection(earnings),

                      const SizedBox(height: 24),

                      // Performance Metrics
                      _buildPerformanceMetricsSection(earnings),

                      const SizedBox(height: 24),

                      // Payout Information
                      if (earnings != null) _buildPayoutInfoSection(earnings),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTotalEarningsCard(CreatorDashboardController controller) {
    final currentMonth = controller.currentMonthEarnings;
    final totalLifetime = controller.profile?.followerCount ?? 0; // Placeholder

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonGreen.withOpacity(0.2),
            AppTheme.neonCyan.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Lifetime Earnings',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${(totalLifetime * 0.25).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.neonGreen,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This Month',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${currentMonth?.formattedEarnings() ?? "0"}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neonCyan,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Conversion Rate',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currentMonth?.formattedConversionRate() ?? "0"}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neonAmber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthBreakdownSection(dynamic earnings) {
    // Sample months for demonstration
    final months = [
      {'month': 'January', 'earnings': 1250.0},
      {'month': 'February', 'earnings': 1890.0},
      {'month': 'March', 'earnings': 2340.0},
      {'month': 'April', 'earnings': 1650.0},
      {'month': 'May', 'earnings': earnings?.totalEarnings ?? 0.0},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monthly Breakdown',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.neonCyan.withOpacity(0.2)),
          ),
          child: Column(
            children: months.asMap().entries.map((entry) {
              final month = entry.value['month'] as String;
              final amount = entry.value['earnings'] as double;
              final maxEarnings = 2500.0;
              final progress = amount / maxEarnings;

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        month,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        '\$${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.neonGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: AppTheme.neonGreen.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.neonGreen,
                      ),
                    ),
                  ),
                  if (entry.key < months.length - 1) const SizedBox(height: 12),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsSourcesSection(dynamic earnings) {
    final sources = [
      {
        'source': 'PPV Conversions',
        'percentage': 45,
        'color': AppTheme.neonGreen,
        'amount': (earnings?.totalEarnings ?? 0) * 0.45,
      },
      {
        'source': 'Clip Royalties',
        'percentage': 30,
        'color': AppTheme.neonCyan,
        'amount': (earnings?.totalEarnings ?? 0) * 0.30,
      },
      {
        'source': 'Ad Revenue',
        'percentage': 15,
        'color': AppTheme.neonAmber,
        'amount': (earnings?.totalEarnings ?? 0) * 0.15,
      },
      {
        'source': 'Sponsorships',
        'percentage': 10,
        'color': AppTheme.neonRed,
        'amount': (earnings?.totalEarnings ?? 0) * 0.10,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Earnings Sources',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...sources.map((source) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSourceTile(
              source['source'] as String,
              source['amount'] as double,
              source['percentage'] as int,
              source['color'] as Color,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSourceTile(
    String source,
    double amount,
    int percentage,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                source,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100.0,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetricsSection(dynamic earnings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonCyan.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Metrics',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            'Clips Generated',
            '${earnings?.clipsGenerated ?? 0}',
            AppTheme.neonCyan,
          ),
          const SizedBox(height: 8),
          _buildMetricRow(
            'Total Views',
            '${earnings?.totalViews ?? 0}',
            AppTheme.neonGreen,
          ),
          const SizedBox(height: 8),
          _buildMetricRow(
            'Avg Earnings Per Clip',
            '\$${earnings?.avgEarningsPerClip?.toStringAsFixed(2) ?? "0"}',
            AppTheme.neonAmber,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPayoutInfoSection(dynamic earnings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payout Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Next Payout Date',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              Text(
                earnings?.nextPayoutDate?.toString().split(' ')[0] ?? 'N/A',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neonGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              Text(
                earnings?.payoutProcessed == true ? 'Processed ✓' : 'Pending',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: earnings?.payoutProcessed == true
                      ? AppTheme.neonGreen
                      : AppTheme.neonAmber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
