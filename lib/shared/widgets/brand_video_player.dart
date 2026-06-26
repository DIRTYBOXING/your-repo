import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// BRAND VIDEO PLAYER - Cinematic Video Experiences
/// Reusable component for promo, AI intro, and tutorial videos
/// ═══════════════════════════════════════════════════════════════════════════

enum BrandVideoType {
  promo, // DFC iPad promo hero (1.5 MB) — sells the app
  aiIntro, // Full DFC intro video (13 MB) — intelligence is the new battle
  tutorial, // iPad tutorial video (1.5 MB)
}

class BrandVideoPlayer extends StatefulWidget {
  final BrandVideoType videoType;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;
  final bool showSkipButton;
  final bool autoPlay;
  final bool loop;
  final bool showControls;

  const BrandVideoPlayer({
    super.key,
    required this.videoType,
    this.onComplete,
    this.onSkip,
    this.showSkipButton = true,
    this.autoPlay = true,
    this.loop = false,
    this.showControls = false,
  });

  @override
  State<BrandVideoPlayer> createState() => _BrandVideoPlayerState();
}

class _BrandVideoPlayerState extends State<BrandVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasEnded = false;

  String get _videoAsset {
    switch (widget.videoType) {
      case BrandVideoType.promo:
        return 'assets/videos/promo_video.mp4';
      case BrandVideoType.aiIntro:
        return 'assets/videos/ai_data_intro.mp4';
      case BrandVideoType.tutorial:
        return 'assets/videos/ipad_tutorial.mp4';
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.asset(_videoAsset);

    try {
      await _controller.initialize();
      _controller.setLooping(widget.loop);
      _controller.setVolume(1.0);

      _controller.addListener(_videoListener);

      if (widget.autoPlay) {
        _controller.play();
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Video initialization error: $e');
      // If video fails, trigger skip/complete
      widget.onComplete?.call();
    }
  }

  void _videoListener() {
    if (_controller.value.isCompleted && !_hasEnded) {
      _hasEnded = true;
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) widget.onComplete?.call();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video or loading indicator
          if (_isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            )
          else
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.neonCyan),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),

          // Controls overlay
          if (widget.showControls && _isInitialized)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _VideoControls(controller: _controller),
            ),

          // Volume toggle (always visible when not showing full controls)
          if (!widget.showControls && _isInitialized)
            Positioned(
              bottom: 16,
              right: 16,
              child: ValueListenableBuilder(
                valueListenable: _controller,
                builder: (context, value, child) {
                  final isMuted = value.volume == 0;
                  return GestureDetector(
                    onTap: () => _controller.setVolume(isMuted ? 1.0 : 0.0),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Icon(
                        isMuted ? Icons.volume_off : Icons.volume_up,
                        color: isMuted ? Colors.white38 : AppTheme.neonCyan,
                        size: 18,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Skip button
          if (widget.showSkipButton)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: _SkipButton(onTap: widget.onSkip ?? widget.onComplete),
            ),

          // Progress indicator at bottom
          if (_isInitialized && !widget.showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: false,
                colors: const VideoProgressColors(
                  playedColor: AppTheme.neonCyan,
                  bufferedColor: AppTheme.surfaceColor,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _SkipButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Skip',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }
}

class _VideoControls extends StatelessWidget {
  final VideoPlayerController controller;

  const _VideoControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, child) {
              return IconButton(
                icon: Icon(
                  value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () {
                  value.isPlaying ? controller.pause() : controller.play();
                },
                tooltip: value.isPlaying ? 'Pause' : 'Play',
              );
            },
          ),
          Expanded(
            child: VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: AppTheme.neonCyan,
                bufferedColor: AppTheme.surfaceColor,
                backgroundColor: AppTheme.primaryBackground,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, child) {
              return Text(
                _formatDuration(value.position),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
          const SizedBox(width: 4),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, child) {
              final isMuted = value.volume == 0;
              return IconButton(
                icon: Icon(
                  isMuted ? Icons.volume_off : Icons.volume_up,
                  color: isMuted ? Colors.white38 : Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  controller.setVolume(isMuted ? 1.0 : 0.0);
                },
                tooltip: isMuted ? 'Unmute' : 'Mute',
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// VIDEO INTRO SCREEN - Full-screen video with brand overlay
/// Use for onboarding step 0 or splash
/// ═══════════════════════════════════════════════════════════════════════════
class VideoIntroScreen extends StatelessWidget {
  final BrandVideoType videoType;
  final VoidCallback onComplete;
  final String? title;
  final String? subtitle;

  const VideoIntroScreen({
    super.key,
    required this.videoType,
    required this.onComplete,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          BrandVideoPlayer(
            videoType: videoType,
            onComplete: onComplete,
            onSkip: onComplete,
          ),
          // Optional title overlay
          if (title != null)
            Positioned(
              bottom: 80,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title!,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// AI INTRO CARD - Embedded video card for dashboard
/// ═══════════════════════════════════════════════════════════════════════════
class AIIntroCard extends StatefulWidget {
  final VoidCallback? onDismiss;

  const AIIntroCard({super.key, this.onDismiss});

  @override
  State<AIIntroCard> createState() => _AIIntroCardState();
}

class _AIIntroCardState extends State<AIIntroCard> {
  bool _showVideo = false;

  @override
  Widget build(BuildContext context) {
    if (_showVideo) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: BrandVideoPlayer(
          videoType: BrandVideoType.aiIntro,
          showControls: true,
          onComplete: () => setState(() => _showVideo = false),
          onSkip: () => setState(() => _showVideo = false),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonCyan.withValues(alpha: 0.15),
            AppTheme.neonMagenta.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.neonCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: AppTheme.neonCyan),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meet Your AI Coach',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Data-driven insights for your journey',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (widget.onDismiss != null)
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                  onPressed: widget.onDismiss,
                  tooltip: 'Dismiss',
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Your AI Coach analyzes training patterns, recovery metrics, and performance data to provide personalized guidance.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _showVideo = true),
              icon: const Icon(Icons.play_circle_filled, size: 20),
              label: const Text('Watch Introduction'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// TUTORIAL VIDEO CARD - Help/How-to video
/// ═══════════════════════════════════════════════════════════════════════════
class TutorialVideoCard extends StatefulWidget {
  const TutorialVideoCard({super.key});

  @override
  State<TutorialVideoCard> createState() => _TutorialVideoCardState();
}

class _TutorialVideoCardState extends State<TutorialVideoCard> {
  bool _showVideo = false;

  @override
  Widget build(BuildContext context) {
    if (_showVideo) {
      return Container(
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: BrandVideoPlayer(
          videoType: BrandVideoType.tutorial,
          showControls: true,
          onComplete: () => setState(() => _showVideo = false),
          onSkip: () => setState(() => _showVideo = false),
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _showVideo = true),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.surfaceColor),
        ),
        child: const Row(
          children: [
            Icon(Icons.tablet_mac, color: AppTheme.neonGreen),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to Use DataFightCentral',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Watch a quick tour of the app',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_circle_outline,
              color: AppTheme.neonGreen,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
