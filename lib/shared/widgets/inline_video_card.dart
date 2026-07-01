import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// INLINE VIDEO CARD — Compact embedded video for sections
///
/// Displays a rounded-corner video with play/pause overlay, title,
/// and optional subtitle. Perfect for embedding in dashboards, tools
/// panels, and section headers.
///
/// Usage:
///   InlineVideoCard(
///     assetPath: 'assets/videos/ipad_tutorial.mp4',
///     title: 'Event Setup Tutorial',
///   )
/// ═══════════════════════════════════════════════════════════════════════════
class InlineVideoCard extends StatefulWidget {
  final String assetPath;
  final String title;
  final String? subtitle;
  final double height;
  final Color accentColor;
  final IconData icon;

  const InlineVideoCard({
    super.key,
    required this.assetPath,
    required this.title,
    this.subtitle,
    this.height = 200,
    this.accentColor = DesignTokens.neonCyan,
    this.icon = Icons.play_circle_fill,
  });

  @override
  State<InlineVideoCard> createState() => _InlineVideoCardState();
}

class _InlineVideoCardState extends State<InlineVideoCard> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.asset(widget.assetPath);
      await _controller!.initialize();
      _controller!.setLooping(false);
      _controller!.setVolume(0); // Start muted for inline
      _controller!.addListener(_onUpdate);
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('InlineVideoCard: Failed to load ${widget.assetPath}: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _onUpdate() {
    if (!mounted) return;
    final playing = _controller?.value.isPlaying ?? false;
    if (playing != _isPlaying) {
      setState(() => _isPlaying = playing);
    }
  }

  void _togglePlay() {
    if (_controller == null || !_isInitialized) return;
    if (_isPlaying) {
      _controller!.pause();
    } else {
      _controller!.setVolume(1.0);
      _controller!.play();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.accentColor.withValues(alpha: 0.15)),
          color: DesignTokens.bgCard,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library_outlined,
                size: 32,
                color: widget.accentColor.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 8),
              Text(
                'Video unavailable',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.accentColor.withValues(alpha: 0.25)),
        color: DesignTokens.bgCard,
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video / placeholder
          if (_isInitialized && _controller != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            )
          else if (_hasError)
            _buildPlaceholder(Icons.videocam_off, 'Video unavailable')
          else
            _buildPlaceholder(Icons.hourglass_top, 'Loading...'),

          // Dark gradient overlay at bottom
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
                    Colors.black.withValues(alpha: 0.9),
                  ],
                  stops: const [0.0, 0.4, 0.75, 1.0],
                ),
              ),
            ),
          ),

          // Play/pause overlay button
          Center(
            child: GestureDetector(
              onTap: _togglePlay,
              child: AnimatedOpacity(
                opacity: _isPlaying ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.5),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor.withValues(alpha: 0.3),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: widget.accentColor,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),

          // Tap to pause when playing
          if (_isPlaying)
            Positioned.fill(
              child: GestureDetector(
                onTap: _togglePlay,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),

          // Title + subtitle bar
          Positioned(
            left: 14,
            right: 14,
            bottom: 12,
            child: Row(
              children: [
                Icon(widget.icon, color: widget.accentColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.8),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Volume indicator
                if (_isInitialized)
                  GestureDetector(
                    onTap: () {
                      final muted = _controller!.value.volume == 0;
                      _controller!.setVolume(muted ? 1.0 : 0.0);
                      setState(() {});
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        (_controller?.value.volume ?? 0) > 0
                            ? Icons.volume_up
                            : Icons.volume_off,
                        color: widget.accentColor.withValues(alpha: 0.7),
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Progress bar
          if (_isInitialized)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: widget.accentColor,
                  bufferedColor: widget.accentColor.withValues(alpha: 0.2),
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                ),
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(IconData icon, String text) {
    return Container(
      color: DesignTokens.bgSecondary,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: widget.accentColor.withValues(alpha: 0.4),
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
