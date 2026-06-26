// ═══════════════════════════════════════════════════════════════════════════
// DFC REFERRAL & REWARDS SCREEN
// ═══════════════════════════════════════════════════════════════════════════
// Share your code, earn points, unlock rewards
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/referral_points_service.dart';

class ReferralRewardsScreen extends StatefulWidget {
  final String userId;

  const ReferralRewardsScreen({super.key, required this.userId});

  @override
  State<ReferralRewardsScreen> createState() => _ReferralRewardsScreenState();
}

class _ReferralRewardsScreenState extends State<ReferralRewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = ReferralPointsService();
  UserPointsSummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    final summary = await _service.getUserPoints(widget.userId);
    setState(() {
      _summary = summary;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.neonCyan),
            )
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(child: _buildPointsCard()),
                SliverToBoxAdapter(child: _buildShareSection()),
                SliverToBoxAdapter(child: _buildTabBar()),
                SliverFillRemaining(child: _buildTabContent()),
              ],
            ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppTheme.backgroundDark,
      pinned: true,
      expandedHeight: 120,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Earn & Reward',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.neonCyan.withValues(alpha: 0.3),
                AppTheme.backgroundDark,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPointsCard() {
    final summary = _summary!;
    final tier = summary.currentTier;
    final nextTier = summary.nextTier;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.neonCyan.withValues(alpha: 0.2),
            AppTheme.surfaceDark,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // Points display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${summary.lifetimePoints}',
                style: const TextStyle(
                  color: AppTheme.neonCyan,
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'POINTS',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Current tier
          if (tier != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tier.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    tier.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Progress to next tier
          if (nextTier != null) ...[
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: summary.progressToNextTier,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation(
                        AppTheme.neonCyan,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(nextTier.icon, style: const TextStyle(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${summary.pointsToNextTier} points to ${nextTier.name}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                'Referrals',
                '${summary.referralCount}',
                Icons.people,
              ),
              _buildStatItem(
                'Upgraded',
                '${summary.subscriptionReferrals}',
                Icons.star,
              ),
              _buildStatItem(
                'Rewards',
                '${summary.unlockedRewards.length}',
                Icons.card_giftcard,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.neonCyan, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildShareSection() {
    final summary = _summary!;
    final link = _service.getReferralLink(summary.referralCode);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.share, color: AppTheme.neonCyan),
              SizedBox(width: 8),
              Text(
                'Share & Earn 500 Points',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Get 500 points for every friend who signs up, plus 1000 bonus when they upgrade!',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          // Referral code
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Code',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      Text(
                        summary.referralCode,
                        style: const TextStyle(
                          color: AppTheme.neonCyan,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: summary.referralCode),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied!'),
                        backgroundColor: AppTheme.neonCyan,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, color: AppTheme.neonCyan),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Share buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _shareLink(link),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share Link'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => _shareToTwitter(summary.referralCode),
                  icon: const Icon(Icons.alternate_email, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => _shareToInstagram(summary.referralCode),
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.neonCyan,
        labelColor: AppTheme.neonCyan,
        unselectedLabelColor: Colors.white60,
        tabs: const [
          Tab(text: 'Rewards'),
          Tab(text: 'How to Earn'),
          Tab(text: 'Leaderboard'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [_buildRewardsList(), _buildHowToEarn(), _buildLeaderboard()],
    );
  }

  Widget _buildRewardsList() {
    final summary = _summary!;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rewardTiers.length,
      itemBuilder: (context, index) {
        final tier = rewardTiers[index];
        final isUnlocked = summary.lifetimePoints >= tier.pointsRequired;
        final isClaimed = summary.unlockedRewards.contains(tier.name);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnlocked
                ? AppTheme.neonCyan.withValues(alpha: 0.1)
                : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnlocked
                  ? AppTheme.neonCyan.withValues(alpha: 0.5)
                  : Colors.white12,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isUnlocked ? AppTheme.neonCyan : Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(tier.icon, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tier.name,
                      style: TextStyle(
                        color: isUnlocked ? AppTheme.neonCyan : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      tier.reward,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${tier.pointsRequired} points',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isClaimed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'CLAIMED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (isUnlocked)
                const Icon(Icons.check_circle, color: AppTheme.neonCyan)
              else
                Icon(Icons.lock, color: Colors.white.withValues(alpha: 0.3)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHowToEarn() {
    final actions = [
      {'action': 'Refer a friend', 'points': 500, 'icon': Icons.person_add},
      {'action': 'Friend upgrades', 'points': 1000, 'icon': Icons.star},
      {'action': 'Complete profile', 'points': 200, 'icon': Icons.person},
      {'action': 'Daily login', 'points': 10, 'icon': Icons.calendar_today},
      {'action': 'Share fighter card', 'points': 50, 'icon': Icons.share},
      {'action': 'Make a prediction', 'points': 100, 'icon': Icons.sports_mma},
      {'action': 'Correct prediction', 'points': 75, 'icon': Icons.check},
      {'action': 'Create a post', 'points': 15, 'icon': Icons.edit},
      {'action': 'Get a like', 'points': 5, 'icon': Icons.thumb_up},
      {'action': 'Connect socials', 'points': 100, 'icon': Icons.link},
      {'action': 'Event check-in', 'points': 100, 'icon': Icons.location_on},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final item = actions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                item['icon'] as IconData,
                color: AppTheme.neonCyan,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item['action'] as String,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.neonCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${item['points']}',
                  style: const TextStyle(
                    color: AppTheme.neonCyan,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaderboard() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _service.getLeaderboard(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.neonCyan),
          );
        }

        final leaders = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: leaders.length,
          itemBuilder: (context, index) {
            final leader = leaders[index];
            final rank = index + 1;
            final isCurrentUser = leader['userId'] == widget.userId;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? AppTheme.neonCyan.withValues(alpha: 0.2)
                    : AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: isCurrentUser
                    ? Border.all(color: AppTheme.neonCyan)
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _getRankColor(rank),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        rank <= 3 ? _getRankEmoji(rank) : '#$rank',
                        style: TextStyle(
                          color: rank <= 3 ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: rank <= 3 ? 18 : 12,
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
                          isCurrentUser
                              ? 'You'
                              : 'Fighter #${leader['userId'].toString().substring(0, 6)}',
                          style: TextStyle(
                            color: isCurrentUser
                                ? AppTheme.neonCyan
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${leader['referralCount'] ?? 0} referrals',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${leader['lifetimePoints'] ?? 0}',
                    style: const TextStyle(
                      color: AppTheme.neonCyan,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.orange.shade700;
      default:
        return Colors.white12;
    }
  }

  String _getRankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  void _shareLink(String link) {
    // Using clipboard as cross-platform share fallback
    Clipboard.setData(
      ClipboardData(text: _service.getShareText(_summary!.referralCode)),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share text copied to clipboard!'),
        backgroundColor: AppTheme.neonCyan,
      ),
    );
  }

  void _shareToTwitter(String code) {
    final text = Uri.encodeComponent(_service.getShareText(code));
    debugPrint('Twitter share: https://twitter.com/intent/tweet?text=$text');
    // URL launch deferred to url_launcher integration
  }

  void _shareToInstagram(String code) {
    Clipboard.setData(ClipboardData(text: _service.getShareText(code)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Caption copied! Open Instagram to share.'),
        backgroundColor: Colors.pink,
      ),
    );
  }
}
