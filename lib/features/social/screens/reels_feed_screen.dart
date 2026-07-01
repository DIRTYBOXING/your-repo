import 'package:flutter/material.dart' hide RouterConfig;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../core/config/router_config.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/community/short_video_model.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/short_video_service.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import '../widgets/reel_comments_sheet.dart';

/// TikTok-style vertical swipe Reels feed — full-screen videos with
/// auto-play, engagement overlay, and creator info.
class ReelsFeedScreen extends StatefulWidget {
  const ReelsFeedScreen({super.key});

  @override
  State<ReelsFeedScreen> createState() => _ReelsFeedScreenState();
}

class _ReelsFeedScreenState extends State<ReelsFeedScreen> {
  List<ShortVideoModel> _reels = [];
  bool _loading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadReels();
  }

  Future<void> _loadReels() async {
    final service = context.read<ShortVideoService>();
    final reels = await service.getReelsFeed();
    if (!mounted) return;
    setState(() {
      _reels = reels;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Reels',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam, color: DesignTokens.neonCyan),
            tooltip: 'Upload Reel',
            onPressed: () => context.push(RouterConfig.uploadReelPath),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: DesignTokens.neonCyan),
            )
          : _reels.isEmpty
          ? _buildEmptyState()
          : PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: _reels.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                return _ReelPage(
                  reel: _reels[index],
                  isActive: index == _currentIndex,
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.slow_motion_video_rounded,
            size: 64,
            color: DesignTokens.neonCyan,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Reels Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to post a fight clip!',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.videocam),
            label: const Text('Upload Reel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.neonCyan,
              foregroundColor: DesignTokens.bgPrimary,
            ),
            onPressed: () => context.push(RouterConfig.uploadReelPath),
          ),
        ],
      ),
    );
  }
}

// ─── Individual Reel Page ───────────────────────────────────────────────────

class _ReelPage extends StatefulWidget {
  final ShortVideoModel reel;
  final bool isActive;

  const _ReelPage({required this.reel, required this.isActive});

  @override
  State<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<_ReelPage> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _showPlayButton = false;

  bool get _hasPlayableVideo {
    final url = widget.reel.videoUrl.trim();
    final uri = Uri.tryParse(url);
    return url.isNotEmpty && uri != null && uri.hasScheme;
  }

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() {
    if (!_hasPlayableVideo) {
      return;
    }

    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.reel.videoUrl))
          ..initialize().then((_) {
            if (!mounted) return;
            setState(() => _initialized = true);
            _controller!.setLooping(true);
            if (widget.isActive) {
              _controller!.play();
              _trackView();
            }
          });
  }

  void _trackView() {
    context.read<ShortVideoService>().incrementViewCount(widget.reel.id);
  }

  @override
  void didUpdateWidget(covariant _ReelPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller?.play();
      _trackView();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller?.pause();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_initialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _showPlayButton = true;
      } else {
        _controller!.play();
        _showPlayButton = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video layer
          if (!_hasPlayableVideo)
            _buildUnavailableVideoState()
          else if (_initialized && _controller != null)
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            )
          else
            Container(
              color: DesignTokens.bgSecondary,
              child: const Center(
                child: CircularProgressIndicator(
                  color: DesignTokens.neonCyan,
                  strokeWidth: 2,
                ),
              ),
            ),

          // Gradient overlay for text readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Play/Pause icon overlay
          if (_showPlayButton)
            const Center(
              child: Icon(
                Icons.play_arrow_rounded,
                size: 72,
                color: Colors.white54,
              ),
            ),

          // Right-side engagement buttons
          Positioned(
            right: 12,
            bottom: 120,
            child: _EngagementBar(reel: widget.reel),
          ),

          // Bottom creator info + description
          Positioned(
            left: 16,
            right: 72,
            bottom: 32,
            child: _CreatorOverlay(reel: widget.reel),
          ),

          // Progress indicator
          if (_initialized && _controller != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: DesignTokens.neonCyan,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnavailableVideoState() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.reel.thumbnailUrl.isNotEmpty)
          DfcNetworkImage(url: widget.reel.thumbnailUrl)
        else
          Container(color: DesignTokens.bgSecondary),
        Container(color: Colors.black.withValues(alpha: 0.55)),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.visibility_off_rounded,
                  size: 54,
                  color: Colors.white70,
                ),
                const SizedBox(height: 14),
                const Text(
                  'This reel is unavailable right now',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Playback is hidden until the media approval check completes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.74),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Engagement Buttons (Right Side) ────────────────────────────────────────

class _EngagementBar extends StatefulWidget {
  final ShortVideoModel reel;

  const _EngagementBar({required this.reel});

  @override
  State<_EngagementBar> createState() => _EngagementBarState();
}

class _EngagementBarState extends State<_EngagementBar> {
  late bool _liked;
  late bool _saved;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthService>().currentUser?.uid ?? '';
    _liked = widget.reel.isLikedBy(uid);
    _saved = widget.reel.isSavedBy(uid);
    _likeCount = widget.reel.likeCount;
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Like
        _engagementButton(
          icon: _liked ? Icons.favorite : Icons.favorite_border,
          label: _formatCount(_likeCount),
          color: _liked ? DesignTokens.neonRed : Colors.white,
          onTap: () {
            final uid = context.read<AuthService>().currentUser?.uid ?? '';
            if (uid.isEmpty) return;
            context.read<ShortVideoService>().toggleLike(widget.reel.id, uid);
            setState(() {
              _liked = !_liked;
              _likeCount += _liked ? 1 : -1;
            });
          },
        ),
        const SizedBox(height: 20),

        // Comment
        _engagementButton(
          icon: Icons.chat_bubble_outline,
          label: _formatCount(widget.reel.commentCount),
          color: Colors.white,
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => ReelCommentsSheet(videoId: widget.reel.id),
            );
          },
        ),
        const SizedBox(height: 20),

        // Share
        _engagementButton(
          icon: Icons.send_rounded,
          label: _formatCount(widget.reel.shareCount),
          color: Colors.white,
          onTap: () {
            context.read<ShortVideoService>().incrementShareCount(
              widget.reel.id,
            );
          },
        ),
        const SizedBox(height: 20),

        // Save / Bookmark
        _engagementButton(
          icon: _saved ? Icons.bookmark : Icons.bookmark_border,
          label: _saved ? 'Saved' : 'Save',
          color: _saved ? DesignTokens.neonAmber : Colors.white,
          onTap: () {
            final uid = context.read<AuthService>().currentUser?.uid ?? '';
            if (uid.isEmpty) return;
            context.read<ShortVideoService>().toggleSave(widget.reel.id, uid);
            setState(() => _saved = !_saved);
          },
        ),
        const SizedBox(height: 20),

        // Report
        _engagementButton(
          icon: Icons.flag_outlined,
          label: 'Report',
          color: Colors.white54,
          onTap: () => _showReportDialog(context),
        ),
      ],
    );
  }

  void _showReportDialog(BuildContext context) {
    final reasons = [
      'Violence or threats',
      'Harassment or bullying',
      'Hate speech',
      'Spam or scam',
      'Adult content',
      'Other',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Video',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...reasons.map(
              (r) => ListTile(
                dense: true,
                title: Text(
                  r,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                leading: const Icon(
                  Icons.report_outlined,
                  color: DesignTokens.neonRed,
                  size: 20,
                ),
                onTap: () {
                  final uid =
                      context.read<AuthService>().currentUser?.uid ?? '';
                  if (uid.isNotEmpty) {
                    context.read<ShortVideoService>().reportVideo(
                      videoId: widget.reel.id,
                      reporterId: uid,
                      reason: r,
                    );
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report submitted. Thank you.'),
                      backgroundColor: DesignTokens.neonGreen,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _engagementButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─── Creator Overlay (Bottom Left) ──────────────────────────────────────────

class _CreatorOverlay extends StatelessWidget {
  final ShortVideoModel reel;

  const _CreatorOverlay({required this.reel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Creator row
        Row(
          children: [
            DfcCircleAvatar(
              imageUrl: reel.creatorAvatarUrl,
              radius: 16,
              backgroundColor: DesignTokens.neonCyan.withValues(alpha: 0.3),
              fallbackText: reel.creatorName.isNotEmpty
                  ? reel.creatorName[0].toUpperCase()
                  : '?',
              fallbackTextStyle: const TextStyle(
                color: DesignTokens.neonCyan,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                reel.creatorName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Title
        Text(
          reel.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        // Description (if present)
        if (reel.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            reel.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        // Hashtags
        if (reel.hashtags.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: reel.hashtags.take(4).map((tag) {
              final display = tag.startsWith('#') ? tag : '#$tag';
              return GestureDetector(
                onTap: () {
                  final cleanTag = tag.startsWith('#') ? tag.substring(1) : tag;
                  context.push('/hashtag/$cleanTag');
                },
                child: Text(
                  display,
                  style: const TextStyle(
                    color: DesignTokens.neonCyan,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
