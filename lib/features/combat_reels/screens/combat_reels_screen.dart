import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// COMBAT REELS — TikTok-level vertical short-form fight highlights
/// Full-screen, swipeable, auto-playing fight clips with engagement overlay.
/// This is DFC's answer to TikTok Shorts / YouTube Shorts / Instagram Reels.
/// ═══════════════════════════════════════════════════════════════════════════
class CombatReelsScreen extends StatefulWidget {
  const CombatReelsScreen({super.key});

  @override
  State<CombatReelsScreen> createState() => _CombatReelsScreenState();
}

class _CombatReelsScreenState extends State<CombatReelsScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  final List<_CombatReel> _reels = [
    _CombatReel(
      id: 'reel-1',
      title: 'FLYING KNEE KO — Round 1',
      fighter: 'Stamp Fairtex',
      event: 'ONE Fight Night 22',
      location: '🇹🇭 Bangkok',
      views: '2.4M',
      likes: '412K',
      shares: '89K',
      comments: '14.3K',
      tags: ['#KO', '#MuayThai', '#ONE'],
      gradientColors: [
        const Color(0xFF0A1929),
        const Color(0xFF00BCD4).withValues(alpha: 0.3),
        const Color(0xFF0A1929),
      ],
      accentColor: AppTheme.neonCyan,
      thumbnailAsset: 'assets/dfc_backgrounds/new_dfc_image_1.png',
      videoUrl: 'assets/videos/promo_video.mp4',
    ),
    _CombatReel(
      id: 'reel-2',
      title: 'SPINNING BACK FIST FINISH',
      fighter: 'Shara Magomedov',
      event: 'UFC Fight Night 241',
      location: '🇺🇸 Las Vegas',
      views: '1.8M',
      likes: '298K',
      shares: '67K',
      comments: '9.1K',
      tags: ['#UFC', '#MMA', '#SpinningBackFist'],
      gradientColors: [
        const Color(0xFF0A1929),
        const Color(0xFFFF1493).withValues(alpha: 0.3),
        const Color(0xFF0A1929),
      ],
      accentColor: AppTheme.neonMagenta,
      thumbnailAsset: 'assets/dfc_backgrounds/dfc2_image.png',
      videoUrl: 'assets/videos/ai_data_intro.mp4',
    ),
    _CombatReel(
      id: 'reel-3',
      title: 'BARE KNUCKLE WAR — 5 Rounds',
      fighter: 'Mike Perry',
      event: 'BKFC 56',
      location: '🇺🇸 Tampa',
      views: '987K',
      likes: '156K',
      shares: '41K',
      comments: '7.2K',
      tags: ['#BKFC', '#BareKnuckle', '#War'],
      gradientColors: [
        const Color(0xFF0A1929),
        const Color(0xFFFF6B00).withValues(alpha: 0.3),
        const Color(0xFF0A1929),
      ],
      accentColor: AppTheme.neonOrange,
      thumbnailAsset: 'assets/dfc_backgrounds/dfc_and_back_ground.png',
      videoUrl: 'assets/videos/ipad_tutorial.mp4',
    ),
    _CombatReel(
      id: 'reel-4',
      title: 'SUBMISSION OF THE YEAR CONTENDER',
      fighter: 'Jai Opetaia',
      event: 'IBC 03: Gold Coast',
      location: '🇦🇺 Gold Coast',
      views: '1.2M',
      likes: '203K',
      shares: '54K',
      comments: '11.8K',
      tags: ['#IBC', '#Boxing', '#Australia'],
      gradientColors: [
        const Color(0xFF0A1929),
        const Color(0xFF00FF88).withValues(alpha: 0.3),
        const Color(0xFF0A1929),
      ],
      accentColor: AppTheme.neonGreen,
      thumbnailAsset: 'assets/dfc_backgrounds/datafight_central_with_logo.png',
      videoUrl: 'assets/videos/promo_video.mp4',
    ),
    _CombatReel(
      id: 'reel-5',
      title: 'CLINCH MASTERCLASS — Saenchai',
      fighter: 'Saenchai',
      event: 'Lumpinee Stadium',
      location: '🇹🇭 Bangkok',
      views: '3.1M',
      likes: '521K',
      shares: '112K',
      comments: '18.4K',
      tags: ['#MuayThai', '#Legend', '#Clinch'],
      gradientColors: [
        const Color(0xFF0A1929),
        const Color(0xFF9D00FF).withValues(alpha: 0.3),
        const Color(0xFF0A1929),
      ],
      accentColor: AppTheme.neonPurple,
      thumbnailAsset: 'assets/dfc_backgrounds/dfc2_image_.png',
      videoUrl: 'assets/videos/ai_data_intro.mp4',
    ),
    _CombatReel(
      id: 'reel-6',
      title: 'WALK-OFF KO — Ice Cold',
      fighter: 'Alex Pereira',
      event: 'UFC 300',
      location: '🇺🇸 Las Vegas',
      views: '4.7M',
      likes: '689K',
      shares: '201K',
      comments: '23.1K',
      tags: ['#UFC', '#KO', '#WalkOff'],
      gradientColors: [
        const Color(0xFF0A1929),
        const Color(0xFF00BCD4).withValues(alpha: 0.3),
        const Color(0xFF0A1929),
      ],
      accentColor: AppTheme.neonCyan,
      thumbnailAsset: 'assets/dfc_backgrounds/dfc_logo_resized.png',
      videoUrl: 'assets/videos/ipad_tutorial.mp4',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-screen vertical swipe
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _reels.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) => _CombatReelPlayer(
              reel: _reels[index],
              isActive: index == _currentPage,
            ),
          ),
          // Top bar overlay
          _buildTopBar(context),
          // Progress dots (right edge)
          _buildProgressDots(),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppTheme.neonCyan, AppTheme.neonMagenta],
                ).createShader(bounds),
                child: const Text(
                  'COMBAT REELS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: Colors.red,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'TRENDING',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDots() {
    return Positioned(
      right: 4,
      top: 0,
      bottom: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            _reels.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(vertical: 3),
              width: 4,
              height: i == _currentPage ? 20 : 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: i == _currentPage
                    ? _reels[i].accentColor
                    : Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Combat Reel Player ─────────────────────────────────────────────────

class _CombatReelPlayer extends StatefulWidget {
  final _CombatReel reel;
  final bool isActive;

  const _CombatReelPlayer({required this.reel, required this.isActive});

  @override
  State<_CombatReelPlayer> createState() => _CombatReelPlayerState();
}

class _CombatReelPlayerState extends State<_CombatReelPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _loadFailed = false;
  bool _showPlayIcon = false;

  @override
  void initState() {
    super.initState();
    final source = widget.reel.videoUrl;
    _controller = source.startsWith('assets/')
        ? VideoPlayerController.asset(source)
        : VideoPlayerController.networkUrl(Uri.parse(source));

    _controller
        .initialize()
        .timeout(const Duration(seconds: 12))
        .then((_) {
          if (!mounted) {
            return;
          }
          setState(() {
            _initialized = true;
            _loadFailed = false;
          });
          _controller.setLooping(true);
          _controller.setVolume(1.0);
          if (widget.isActive) {
            _controller.play();
          }
        })
        .catchError((_) {
          if (!mounted) {
            return;
          }
          setState(() {
            _initialized = false;
            _loadFailed = true;
          });
        });
  }

  @override
  void didUpdateWidget(covariant _CombatReelPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.play();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_initialized || _loadFailed) {
      return;
    }
    if (_controller.value.isPlaying) {
      _controller.pause();
      setState(() => _showPlayIcon = true);
    } else {
      _controller.play();
      setState(() => _showPlayIcon = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video or thumbnail fallback
          if (_initialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            )
          else
            Image.asset(
              reel.thumbnailAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(color: Colors.black),
            ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // Loading spinner
          if (!_initialized && !_loadFailed)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white54,
                strokeWidth: 2,
              ),
            ),

          if (_loadFailed)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: reel.accentColor.withValues(alpha: 0.55),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_disabled,
                      color: reel.accentColor,
                      size: 30,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Clip unavailable right now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Preview art is still available while the video source reloads.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Paused play icon
          if (_showPlayIcon)
            Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.4),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),

          // Engagement bar (right side)
          Positioned(
            right: 12,
            bottom: 180,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _engageButton(Icons.favorite, reel.likes, Colors.red),
                const SizedBox(height: 20),
                _engageButton(Icons.chat_bubble, reel.comments, Colors.white),
                const SizedBox(height: 20),
                _engageButton(Icons.share, reel.shares, AppTheme.neonCyan),
                const SizedBox(height: 20),
                _engageButton(Icons.bookmark_border, '', Colors.white),
              ],
            ),
          ),

          // Bottom info
          Positioned(
            left: 12,
            right: 70,
            bottom: 40,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: reel.accentColor, width: 2),
                          color: reel.accentColor.withValues(alpha: 0.15),
                        ),
                        child: Icon(
                          Icons.person,
                          color: reel.accentColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reel.fighter,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${reel.event} • ${reel.location}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reel.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: reel.tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: reel.accentColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _engageButton(IconData icon, String count, Color color) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        if (count.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Data Model ──────────────────────────────────────────────────────────

class _CombatReel {
  final String id;
  final String title;
  final String fighter;
  final String event;
  final String location;
  final String views;
  final String likes;
  final String shares;
  final String comments;
  final List<String> tags;
  final List<Color> gradientColors;
  final Color accentColor;
  final String thumbnailAsset;
  final String videoUrl;

  const _CombatReel({
    required this.id,
    required this.title,
    required this.fighter,
    required this.event,
    required this.location,
    required this.views,
    required this.likes,
    required this.shares,
    required this.comments,
    required this.tags,
    required this.gradientColors,
    required this.accentColor,
    required this.thumbnailAsset,
    required this.videoUrl,
  });
}
