import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC VIDEO INTRO SYSTEM — 3 Video Strategy
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Video 1 (First Time User / Welcome):
///   File: assets/videos/download (5).mp4
///   Use: Onboarding step 0, landing page background (optional)
///   Purpose: "Welcome to DataFightCentral" — shown once only
///
/// Video 2 (Subscriber / Premium Upgrade):
///   File: assets/videos/download (2).mp4
///   Use: Subscription purchase success, after login if premium detected
///   Purpose: "High impact premium welcome"
///
/// Video 3 (Promoter / Event Mode / Red & Green):
///   File: assets/videos/download.mp4
///   Use: Promoter role activation, promoter dashboard entry, fight show mode
///   Purpose: "Live promoter mode activation"
///
/// Video 4 (Genie AI Mentor / Samurai Shido Intro):
///   File: assets/videos/genie_intro.mp4 (or reuse welcome video)
///   Use: First Genie chat, AI coach activation, Samurai Shido introduction
///   Purpose: "Meet your AI corner coach - Samurai Shido"

enum DfcVideoType {
  welcome, // First time user
  premium, // Subscriber/Premium
  promoter, // Promoter mode
  genie, // Genie AI Mentor / Samurai Shido
}

class DfcVideoIntroService {
  static const String _welcomeVideo = 'assets/videos/ai_data_intro.mp4';
  static const String _premiumVideo = 'assets/videos/promo_video.mp4';
  static const String _promoterVideo = 'assets/videos/promo_video.mp4';
  static const String _genieVideo = 'assets/videos/ai_data_intro.mp4';

  /// Get video path based on type
  static String getVideoPath(DfcVideoType type) {
    switch (type) {
      case DfcVideoType.welcome:
        return _welcomeVideo;
      case DfcVideoType.premium:
        return _premiumVideo;
      case DfcVideoType.promoter:
        return _promoterVideo;
      case DfcVideoType.genie:
        return _genieVideo;
    }
  }

  /// Show video intro as full-screen overlay
  static Future<void> showVideoIntro(
    BuildContext context,
    DfcVideoType type, {
    VoidCallback? onComplete,
    bool skippable = true,
  }) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, _) => DfcVideoIntroScreen(
          videoType: type,
          onComplete: onComplete,
          skippable: skippable,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC VIDEO INTRO SCREEN — Full-screen video player
/// ═══════════════════════════════════════════════════════════════════════════

class DfcVideoIntroScreen extends StatefulWidget {
  final DfcVideoType videoType;
  final VoidCallback? onComplete;
  final bool skippable;

  const DfcVideoIntroScreen({
    required this.videoType,
    this.onComplete,
    this.skippable = true,
    super.key,
  });

  @override
  State<DfcVideoIntroScreen> createState() => _DfcVideoIntroScreenState();
}

class _DfcVideoIntroScreenState extends State<DfcVideoIntroScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _error = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final videoPath = DfcVideoIntroService.getVideoPath(widget.videoType);
      _controller = VideoPlayerController.asset(videoPath);

      await _controller!.initialize();

      if (mounted) {
        setState(() => _initialized = true);
        _fadeController.forward();

        // Auto-play and add completion listener
        _controller!.play();
        _controller!.addListener(_onVideoUpdate);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = true);
        _closeAndCallback();
      }
    }
  }

  void _onVideoUpdate() {
    // Check if video has finished
    if (_controller != null &&
        _controller!.value.position >= _controller!.value.duration) {
      _closeAndCallback();
    }
  }

  void _closeAndCallback() {
    if (mounted) {
      Navigator.of(context).pop();
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoUpdate);
    _controller?.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video player
          if (_initialized && !_error)
            FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),
            )
          else if (_error)
            const Center(
              child: Icon(Icons.error_outline, color: Colors.red, size: 64),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.cyan)),

          // Skip button (top-right)
          if (widget.skippable && _initialized)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _closeAndCallback,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'SKIP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Tap to skip (anywhere on screen)
          if (widget.skippable && _initialized)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeAndCallback,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.transparent),
              ),
            ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// HELPER WIDGET — Background video player (for landing page)
/// ═══════════════════════════════════════════════════════════════════════════

class DfcBackgroundVideo extends StatefulWidget {
  final DfcVideoType videoType;
  final bool muted;
  final bool loop;

  const DfcBackgroundVideo({
    required this.videoType,
    this.muted = true,
    this.loop = true,
    super.key,
  });

  @override
  State<DfcBackgroundVideo> createState() => _DfcBackgroundVideoState();
}

class _DfcBackgroundVideoState extends State<DfcBackgroundVideo> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final videoPath = DfcVideoIntroService.getVideoPath(widget.videoType);
      _controller = VideoPlayerController.asset(videoPath);

      await _controller!.initialize();

      if (mounted) {
        setState(() => _initialized = true);
        _controller!.setLooping(widget.loop);
        if (widget.muted) {
          _controller!.setVolume(0.0);
        }
        _controller!.play();
      }
    } catch (e) {
      // Silent fail for background videos
      debugPrint('Background video failed to load: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _controller == null) {
      return const SizedBox.expand();
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}
