import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/creator_dashboard_controller.dart';

/// Creator ranking and leaderboard screen
class CreatorRankScreen extends StatefulWidget {
  final String creatorId;

  const CreatorRankScreen({Key? key, required this.creatorId})
    : super(key: key);

  @override
  State<CreatorRankScreen> createState() => _CreatorRankScreenState();
}

class _CreatorRankScreenState extends State<CreatorRankScreen> {
  late CreatorDashboardController _controller;
  bool _isLoading = true;
  Map<String, dynamic>? _rankingInfo;
  List<Map<String, dynamic>> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _controller = context.read<CreatorDashboardController>();
    _loadRankingData();
  }

  Future<void> _loadRankingData() async {
    _rankingInfo = await _controller.getCreatorRankingInfo(widget.creatorId);
    _leaderboard = await _controller.getLeaderboard(limit: 100);

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('Creator Rankings'),
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Your Ranking
                  if (_rankingInfo != null)
                    _buildYourRankingCard(_rankingInfo!),

                  const SizedBox(height: 24),

                  // Leaderboard
                  _buildLeaderboardSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildYourRankingCard(Map<String, dynamic> rankingInfo) {
    final rank = rankingInfo['rank'] as int? ?? 9999;
    final trendingScore = rankingInfo['trendingScore'] as double? ?? 0.0;
    final percentile = rankingInfo['percentile'] as String? ?? '0';
    final rankStatus = rankingInfo['rankStatus'] as String? ?? '📈 RISING';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonCyan.withOpacity(0.15),
            AppTheme.neonAmber.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Ranking',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Rank Circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.neonAmber, width: 2),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '#$rank',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neonAmber,
                        ),
                      ),
                      const Text(
                        'Global',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Ranking Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.neonAmber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        rankStatus,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.neonAmber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRankMetric(
                      'Trending Score',
                      '${trendingScore.toStringAsFixed(1)}/10',
                      AppTheme.neonCyan,
                    ),
                    const SizedBox(height: 8),
                    _buildRankMetric('Top', '$percentile%', AppTheme.neonGreen),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankMetric(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Global Leaderboard',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (_leaderboard.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.neonCyan.withOpacity(0.2)),
            ),
            child: const Center(
              child: Text(
                'No data available',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          Column(
            children: _leaderboard.asMap().entries.map((entry) {
              final index = entry.key;
              final creator = entry.value;
              final rank = index + 1;
              final isTopThree = rank <= 3;

              return _buildLeaderboardTile(
                rank,
                creator['displayName'] ?? 'Unknown',
                creator['avatarUrl'],
                creator['earnings'] ?? 0.0,
                isTopThree,
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildLeaderboardTile(
    int rank,
    String displayName,
    String? avatarUrl,
    double earnings,
    bool isTopThree,
  ) {
    Color rankColor = AppTheme.textSecondary;
    String medal = '';

    if (rank == 1) {
      rankColor = AppTheme.neonAmber;
      medal = '🥇';
    } else if (rank == 2) {
      rankColor = Colors.grey[400] ?? AppTheme.textSecondary;
      medal = '🥈';
    } else if (rank == 3) {
      rankColor = Colors.orange[300] ?? AppTheme.neonAmber;
      medal = '🥉';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTopThree
              ? rankColor.withOpacity(0.3)
              : AppTheme.neonCyan.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rankColor.withOpacity(0.2),
              border: Border.all(color: rankColor.withOpacity(0.5)),
            ),
            child: Center(
              child: Text(
                medal.isNotEmpty ? medal : '#$rank',
                style: TextStyle(
                  fontSize: medal.isNotEmpty ? 20 : 14,
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Creator Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Creator',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          // Earnings
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${earnings.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neonGreen,
                ),
              ),
              Text(
                'earnings',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
