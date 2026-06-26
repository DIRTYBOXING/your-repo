import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'dfc_theme.dart';
import 'blue/controllers/social_feed_controller.dart';
import 'blue/repositories/social_feed_repository.dart';
import 'blue/state/social_feed_state.dart';
import 'blue/models/social_feed_model.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  late final SocialFeedController _controller;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _controller = SocialFeedController(
      repo: SocialFeedRepository(api: ApiService()),
    )..loadFeed();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final state = _controller.state;

          if (state is SocialFeedInitial || state is SocialFeedLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentCyan),
            );
          }
          if (state is SocialFeedError) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: const TextStyle(color: AppColors.accentRed),
              ),
            );
          }
          if (state is SocialFeedLoaded) {
            return PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical, // TikTok Style
              itemCount: state.feed.length,
              itemBuilder: (context, index) {
                return _FeedItemStage(post: state.feed[index]);
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

/// THE FULL-SCREEN CONTENT CANVAS
class _FeedItemStage extends StatelessWidget {
  final SocialFeedModel post;

  const _FeedItemStage({required this.post});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. FULL-BLEED MEDIA BACKGROUND
        Image.network(
          post.mediaUrl,
          fit: BoxFit.cover,
          color: Colors.black.withValues(alpha: 0.3), // Darken for text readability
          colorBlendMode: BlendMode.darken,
        ),

        // 2. GRADIENT OVERLAYS (Top and Bottom)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.background.withValues(alpha: 0.8),
                Colors.transparent,
                Colors.transparent,
                AppColors.background.withValues(alpha: 0.9),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.2, 0.6, 1.0],
            ),
          ),
        ),

        // 3. TOP LEFT: DFC OVERLAY (Identity & Tags)
        Positioned(
          top: MediaQuery.of(context).padding.top + 20,
          left: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    post.creatorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildTierBadge(post.creatorTier),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.shield,
                    color: AppColors.textSecondary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    post.gymName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: post.aiTags.map((tag) => _buildAiTag(tag)).toList(),
              ),
            ],
          ),
        ),

        // 4. TOP RIGHT: PPV RIBBON
        if (post.ppvRibbon != null || post.isLive)
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: post.isLive
                    ? AppColors.accentRed
                    : AppColors.accentRed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.accentRed),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentRed.withValues(alpha: 0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Text(
                post.isLive ? 'LIVE NOW' : post.ppvRibbon!,
                style: TextStyle(
                  color: post.isLive ? Colors.white : AppColors.accentRed,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

        // 5. RIGHT SIDE: ACTION STACK
        Positioned(
          bottom: 100,
          right: 16,
          child: Column(
            children: [
              _buildActionButton(
                Icons.favorite,
                NumberFormat.compact().format(post.likes),
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              _buildActionButton(
                Icons.chat_bubble,
                NumberFormat.compact().format(post.comments),
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              _buildActionButton(Icons.share, 'Share', color: Colors.white),
              const SizedBox(height: 32),
              // Premium Tip Button
              _buildActionButton(
                Icons.diamond,
                'Tip',
                color: AppColors.accentCyan,
                glow: true,
              ),
            ],
          ),
        ),

        // 6. BOTTOM LEFT: CAPTION BLOCK
        Positioned(
          bottom: 40,
          left: 20,
          right: 100, // Leave room for right stack
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.type == 'ppv_promo')
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentRed.withValues(alpha: 0.15),
                    border: Border.all(color: AppColors.accentRed),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_cart,
                        color: AppColors.accentRed,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'BUY PPV ACCESS',
                        style: TextStyle(
                          color: AppColors.accentRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                '@${post.creatorName.replaceAll(" ", "").toLowerCase()}',
                style: const TextStyle(
                  color: AppColors.accentCyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                post.caption,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // 7. BOTTOM RIGHT: AI TRAINING METRICS
        if (post.aiMetrics != null)
          Positioned(
            bottom: 40,
            right: 80, // Next to action stack
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentCyan.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildMetricRow(
                    'HR',
                    post.aiMetrics!['hr'],
                    AppColors.accentRed,
                  ),
                  const SizedBox(height: 6),
                  _buildMetricRow(
                    'SPD',
                    post.aiMetrics!['speed'],
                    AppColors.accentCyan,
                  ),
                  const SizedBox(height: 6),
                  _buildMetricRow(
                    'PWR',
                    post.aiMetrics!['power'],
                    AppColors.championGold,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ─── HELPER WIDGETS ────────────────────────────────────────────────────────

  Widget _buildTierBadge(String tier) {
    Color color;
    if (tier == 'CHAMPION') {
      color = AppColors.championGold;
    } else if (tier == 'PRO')
      color = AppColors.accentCyan;
    else
      color = AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tier,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildAiTag(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.accentCyan, size: 10),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label, {
    required Color color,
    bool glow = false,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
            boxShadow: glow
                ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 15)]
                : [],
            border: glow ? Border.all(color: color) : null,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black, blurRadius: 5)],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
