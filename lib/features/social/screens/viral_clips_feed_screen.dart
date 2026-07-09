import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/design_tokens.dart';
import '../../ppv/models/ppv_model.dart';
import '../controllers/social_feed_controller.dart';
import '../models/social_clip_model.dart';
import '../widgets/clip_player_modal.dart';
import '../widgets/clip_preview_card.dart';
import '../widgets/live_fight_banner_widget.dart';
import '../widgets/trending_clips_widget.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// VIRAL CLIPS FEED SCREEN — Tier 6D: Social Integration Loop
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Dedicated viral discovery feed displaying:
///   - Trending clips (viral right now)
///   - Live fight banner (when available)
///   - Feed tabs (viral, live, highlights, recent)
///   - Individual clip cards with engagement tracking
///   - PPV conversion flow
///
/// ═══════════════════════════════════════════════════════════════════════════

class ViralClipsFeedScreen extends StatefulWidget {
  final PPVEvent? event;

  const ViralClipsFeedScreen({super.key, this.event});

  @override
  State<ViralClipsFeedScreen> createState() => _ViralClipsFeedScreenState();
}

class _ViralClipsFeedScreenState extends State<ViralClipsFeedScreen> {
  late SocialFeedController _controller;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = SocialFeedController();
    _scrollController = ScrollController();
    _controller.refreshFeed();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SocialFeedController>.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: DesignTokens.bgPrimary,
        appBar: AppBar(
          backgroundColor: DesignTokens.bgPrimary,
          elevation: 0,
          title: const Text(
            'VIRAL ARENA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () => _controller.refreshFeed(),
              icon: Icon(Icons.refresh, color: DesignTokens.neonCyan),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Consumer<SocialFeedController>(
          builder: (context, controller, _) {
            return RefreshIndicator(
              onRefresh: () => controller.refreshFeed(),
              child: ListView(
                controller: _scrollController,
                children: [
                  // ── Live Fight Banner ──
                  if (widget.event != null &&
                      widget.event!.fightCard.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: LiveFightBannerWidget(
                        event: widget.event!,
                        currentFight: widget.event!.fightCard.first,
                        round: 1,
                        timeInRound: 180,
                        recentAction: 'Knockdown detected',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Navigate to PPV watch...'),
                              backgroundColor: DesignTokens.neonGreen,
                            ),
                          );
                        },
                      ),
                    ),

                  // ── Trending Section ──
                  _buildSectionHeader('🔥 TRENDING NOW'),
                  if (controller.trendingClips.isNotEmpty)
                    TrendingClipsWidget(
                      clips: controller.trendingClips,
                      onClipTap: (clip) => _showClipPlayer(context, clip),
                    )
                  else
                    _buildEmptyState('No trending clips yet'),

                  const SizedBox(height: 16),

                  // ── Feed Tabs ──
                  _buildFeedTabs(controller),

                  const SizedBox(height: 12),

                  // ── Feed Content ──
                  _buildFeedContent(context, controller),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  /// Build feed tab bar
  Widget _buildFeedTabs(SocialFeedController controller) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 12),
          ...FeedTab.values.map(
            (tab) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildTabButton(
                tab,
                controller.currentTab == tab,
                () => controller.switchTab(tab),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildTabButton(FeedTab tab, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? DesignTokens.neonCyan.withOpacity(0.2)
              : Colors.white05,
          border: Border.all(
            color: isSelected
                ? DesignTokens.neonCyan.withOpacity(0.7)
                : Colors.white20,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          tab.label,
          style: TextStyle(
            color: isSelected ? DesignTokens.neonCyan : Colors.white60,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Build feed content based on current tab
  Widget _buildFeedContent(
    BuildContext context,
    SocialFeedController controller,
  ) {
    List<SocialClip> clips;

    switch (controller.currentTab) {
      case FeedTab.viral:
        clips = controller.trendingClips;
        break;
      case FeedTab.live:
        clips = controller.liveClips;
        break;
      case FeedTab.highlights:
        clips = controller.highlightClips;
        break;
      case FeedTab.recent:
        clips = controller.recentClips;
        break;
    }

    if (clips.isEmpty) {
      return _buildEmptyState('No clips in ${controller.currentTab.label}');
    }

    return Column(
      children: clips.map((clip) {
        return ClipPreviewCard(
          clip: clip,
          onTap: () => _showClipPlayer(context, clip),
          onLike: () {
            controller.recordEngagement(clip.id, 'like');
          },
          onShare: () {
            controller.recordEngagement(clip.id, 'share');
          },
          onComment: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Comments coming soon...'),
                backgroundColor: DesignTokens.neonCyan,
              ),
            );
          },
          onWatch: () => _showClipPlayer(context, clip),
        );
      }).toList(),
    );
  }

  /// Show clip player modal
  void _showClipPlayer(BuildContext context, SocialClip clip) {
    // Record view
    _controller.recordEngagement(clip.id, 'view');

    showDialog(
      context: context,
      builder: (context) => ClipPlayerModal(
        clip: clip,
        onLike: () {
          _controller.recordEngagement(clip.id, 'like');
        },
        onShare: () {
          _controller.recordEngagement(clip.id, 'share');
        },
        onWatchFullFight: () {
          // Record PPV conversion
          _controller.recordPPVConversion(clip.id);

          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Redirecting to PPV watch screen...'),
              backgroundColor: DesignTokens.neonGreen,
            ),
          );
        },
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.video_library_outlined, size: 48, color: Colors.white20),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.white30, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
