import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/promotion_model.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/promotion_service.dart';

/// Event Promotion Tools — Young fighters learn promotion with mentor guidance
class EventPromotionToolsScreen extends StatefulWidget {
  final String? eventId; // Optional: for quick-create from event detail

  const EventPromotionToolsScreen({super.key, this.eventId});

  @override
  State<EventPromotionToolsScreen> createState() =>
      _EventPromotionToolsScreenState();
}

class _EventPromotionToolsScreenState extends State<EventPromotionToolsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _titleCtrl = TextEditingController();
    _descCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promotionService = context.read<PromotionService>();

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [AppTheme.neonCyan, AppTheme.neonMagenta],
          ).createShader(b),
          child: const Text(
            'PROMOTION TOOLS',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.neonCyan,
          labelColor: AppTheme.neonCyan,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'CREATE'),
            Tab(text: 'ACTIVE'),
            Tab(text: 'LEARN'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreateTab(context, promotionService),
          _buildActiveTab(promotionService),
          _buildLearnTab(promotionService),
        ],
      ),
    );
  }

  Widget _buildCreateTab(
    BuildContext context,
    PromotionService promotionService,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.neonCyan.withValues(alpha: 0.1),
                  AppTheme.neonMagenta.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.rocket_launch,
                  color: AppTheme.neonCyan,
                  size: 28,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Promote Your Fight',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Work with your coach to create a smart promotion strategy. We\'ll guide you through messaging, timing, and channels.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Event selection (or auto-filled if eventId passed)
          const Text(
            'EVENT TO PROMOTE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month,
                  color: AppTheme.neonCyan,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Your Fight',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Tap to choose from your upcoming fights',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.neonCyan),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Promotion title
          const Text(
            'CAMPAIGN TITLE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'e.g. "Support My UFC Debut" or "Help Me Train"',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppTheme.neonCyan.withValues(alpha: 0.15),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppTheme.neonCyan.withValues(alpha: 0.15),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppTheme.neonCyan,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Description
          const Text(
            'WHAT ARE YOU PROMOTING?',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText:
                  'Describe your fight, your goals, why people should support you...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppTheme.neonCyan.withValues(alpha: 0.15),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppTheme.neonCyan.withValues(alpha: 0.15),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppTheme.neonCyan,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Channels to promote on
          const Text(
            'PROMOTION CHANNELS',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildChannelSelector(),
          const SizedBox(height: 20),
          // Mentor connection
          const Text(
            'MENTOR GUIDANCE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.neonGreen.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.neonGreen.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.neonGreen,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Coach Ray Mitchell will review your campaign',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'He\'ll provide feedback and approve before launch',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Campaign saved! Your coach will review it soon.',
                    ),
                  ),
                );
              },
              child: const Text(
                'CREATE CAMPAIGN',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.neonCyan.withValues(alpha: 0.6),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your campaign requires mentor approval before going live. This protects your reputation and ensures smart messaging.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      height: 1.4,
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

  Widget _buildChannelSelector() {
    final channels = PromotionChannel.values;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: channels.map(_channelTile).toList(),
    );
  }

  Widget _channelTile(PromotionChannel channel) {
    final name = channel.toString().split('.').last.toUpperCase();
    final icon = _channelIcon(channel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.neonCyan, size: 16),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _channelIcon(PromotionChannel channel) {
    switch (channel) {
      case PromotionChannel.social:
        return Icons.share;
      case PromotionChannel.email:
        return Icons.email;
      case PromotionChannel.messaging:
        return Icons.chat;
      case PromotionChannel.sms:
        return Icons.sms;
      case PromotionChannel.posters:
        return Icons.image;
      case PromotionChannel.video:
        return Icons.videocam;
    }
  }

  Widget _buildActiveTab(PromotionService service) {
    final userId =
        context.read<AuthService>().currentUser?.uid ?? 'demo_fighter';
    return StreamBuilder<List<PromotionCampaign>>(
      stream: service.streamActiveCampaigns(fighterId: userId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.neonCyan),
          );
        }

        if (!snap.hasData || snap.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No active campaigns',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snap.data!.length,
          itemBuilder: (_, i) => _campaignCard(snap.data![i]),
        );
      },
    );
  }

  Widget _campaignCard(PromotionCampaign campaign) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.eventTitle ?? 'Event',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      campaign.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.neonCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: AppTheme.neonCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Text(
            'Reach: ${campaign.currentReach}/${campaign.targetReach}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: campaign.reachPercentage / 100,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.neonCyan),
            minHeight: 4,
          ),
          const SizedBox(height: 10),
          // Engagement
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Engagements: ${campaign.engagements}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
              Text(
                '${campaign.engagementRate.toStringAsFixed(1)}% rate',
                style: const TextStyle(
                  color: AppTheme.neonCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLearnTab(PromotionService service) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROMOTION BEST PRACTICES',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _learnCard(
            icon: Icons.schedule,
            title: 'Timing Matters',
            desc:
                'Post when your audience is active: weekends for fans, weekday mornings for sponsors.',
            color: AppTheme.neonCyan,
          ),
          _learnCard(
            icon: Icons.groups,
            title: 'Build Community',
            desc:
                'Engage with supporters. Reply to messages, thank people who share your posts.',
            color: AppTheme.neonMagenta,
          ),
          _learnCard(
            icon: Icons.videocam,
            title: 'Show, Don\'t Tell',
            desc:
                'Video is 10x more engaging than text. Share training clips, fight highlights, behind-the-scenes.',
            color: AppTheme.neonGreen,
          ),
          _learnCard(
            icon: Icons.trending_up,
            title: 'Use Hashtags Smart',
            desc:
                'Mix popular tags (#UFC, #MMA) with niche tags (#YouthMMA, #CoachLife) for reach.',
            color: AppTheme.neonOrange,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.neonGreen.withValues(alpha: 0.1),
                  AppTheme.neonCyan.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💬 Talk to Your Coach',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your coach reviews every campaign before it goes live. This isn\'t censorship — it\'s mentorship. They\'ll help you craft messages that build your rep, not hurt it.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _learnCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
