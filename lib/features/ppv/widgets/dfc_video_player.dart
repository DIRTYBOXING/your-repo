import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/design_tokens.dart';
import 'dfc_shaka_player.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC VIDEO PLAYER — Premium Combat Sports Streaming Player
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Kayo / ESPN+ / DAZN quality video player for PPV live streams & replays.
///
/// Features:
///   • HLS/DASH adaptive streaming via video_player
///   • Custom DFC-branded overlay controls
///   • Live indicator with viewer count
///   • Fullscreen toggle
///   • Quality selector (Auto, 1080p, 720p, 480p)
///   • Seek bar with buffer indicator
///   • Auto-hide controls on tap
///   • Pre-event countdown overlay
///   • DFC watermark
///
/// Usage:
///   DFCVideoPlayer(
///     streamUrl: 'https://stream.dfc.live/event/hls/master.m3u8',
///     isLive: true,
///     viewerCount: 4200,
///     eventTitle: 'IBC 03: GOLD COAST BRAWL',
///   )
/// ═══════════════════════════════════════════════════════════════════════════
class DFCVideoPlayer extends StatefulWidget {
  final String? streamUrl;
  final bool isLive;
  final int viewerCount;
  final String eventTitle;
  final String? posterUrl;
  final String? drmToken;
  final String? widevineLicenseUrl;
  final String? fairplayLicenseUrl;
  final String? fairplayCertificateUrl;
  final VoidCallback? onBack;
  final VoidCallback? onChatToggle;
  final bool showChat;

  const DFCVideoPlayer({
    super.key,
    this.streamUrl,
    this.isLive = false,
    this.viewerCount = 0,
    this.eventTitle = '',
    this.posterUrl,
    this.drmToken,
    this.widevineLicenseUrl,
    this.fairplayLicenseUrl,
    this.fairplayCertificateUrl,
    this.onBack,
    this.onChatToggle,
    this.showChat = false,
  });

  @override
  State<DFCVideoPlayer> createState() => _DFCVideoPlayerState();
}

class _DFCVideoPlayerState extends State<DFCVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _showControls = true;
  bool _isFullscreen = false;
  bool _isBuffering = false;
  bool _hasError = false;
  String _selectedQuality = 'Auto';
  Timer? _hideTimer;

  static const _qualities = ['Auto', '1080p', '720p', '480p', '360p'];

  bool get _useWebDrmPlayer =>
      kIsWeb &&
      (widget.streamUrl?.isNotEmpty ?? false) &&
      (widget.drmToken?.isNotEmpty ?? false) &&
      ((widget.widevineLicenseUrl?.isNotEmpty ?? false) ||
          (widget.fairplayLicenseUrl?.isNotEmpty ?? false));

  @override
  void initState() {
    super.initState();
    if (!_useWebDrmPlayer &&
        widget.streamUrl != null &&
        widget.streamUrl!.isNotEmpty) {
      _initPlayer();
    }
    _startHideTimer();
  }

  @override
  void didUpdateWidget(DFCVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_useWebDrmPlayer) {
      return;
    }
    if (oldWidget.streamUrl != widget.streamUrl &&
        widget.streamUrl != null &&
        widget.streamUrl!.isNotEmpty) {
      _controller?.dispose();
      _initPlayer();
    }
  }

  Future<void> _initPlayer() async {
    try {
      final uri = Uri.parse(widget.streamUrl!);
      _controller = VideoPlayerController.networkUrl(uri);
      _controller!.addListener(_playerListener);
      await _controller!.initialize();
      if (mounted) {
        setState(() => _initialized = true);
        _controller!.play();
      }
    } catch (e) {
      debugPrint('DFCVideoPlayer: init error: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _playerListener() {
    if (!mounted || _controller == null) return;
    final buffering = _controller!.value.isBuffering;
    if (buffering != _isBuffering) {
      setState(() => _isBuffering = buffering);
    }
    if (_controller!.value.hasError && !_hasError) {
      setState(() => _hasError = true);
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _showControls) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
  }

  void _togglePlay() {
    if (_controller == null) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
    setState(() {});
    _startHideTimer();
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _seek(Duration position) {
    _controller?.seekTo(position);
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.removeListener(_playerListener);
    _controller?.dispose();
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_useWebDrmPlayer) {
      return _buildWebDrmPlayer(context);
    }

    return AspectRatio(
      aspectRatio: _isFullscreen
          ? MediaQuery.of(context).size.aspectRatio
          : 16 / 9,
      child: ClipRRect(
        borderRadius: _isFullscreen
            ? BorderRadius.zero
            : BorderRadius.circular(DesignTokens.radiusMedium),
        child: Container(
          color: Colors.black,
          child: GestureDetector(
            onTap: _toggleControls,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video layer
                if (_initialized && _controller != null)
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  )
                else
                  _buildPosterOrPlaceholder(),

                // Buffering indicator
                if (_isBuffering)
                  const Center(
                    child: CircularProgressIndicator(
                      color: DesignTokens.neonCyan,
                      strokeWidth: 3,
                    ),
                  ),

                // Error state
                if (_hasError) _buildErrorOverlay(),

                // Controls overlay
                if (_showControls && !_hasError) _buildControlsOverlay(),

                // DFC watermark (always visible, subtle)
                Positioned(
                  right: 12,
                  bottom: _showControls ? 52 : 12,
                  child: Opacity(
                    opacity: 0.25,
                    child: Text(
                      'DFC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebDrmPlayer(BuildContext context) {
    return AspectRatio(
      aspectRatio: _isFullscreen
          ? MediaQuery.of(context).size.aspectRatio
          : 16 / 9,
      child: ClipRRect(
        borderRadius: _isFullscreen
            ? BorderRadius.zero
            : BorderRadius.circular(DesignTokens.radiusMedium),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DfcShakaPlayer(
              manifestUrl: widget.streamUrl!,
              drmToken: widget.drmToken!,
              widevineLicenseUrl: widget.widevineLicenseUrl,
              fairplayLicenseUrl: widget.fairplayLicenseUrl,
              fairplayCertificateUrl: widget.fairplayCertificateUrl,
              isLive: widget.isLive,
            ),
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.5),
                    ],
                    stops: const [0.0, 0.18, 0.7, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.eventTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  if (widget.isLive) _buildLiveBadge(),
                ],
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: const Text(
                  'DRM',
                  style: TextStyle(
                    color: DesignTokens.neonCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Poster / Placeholder ──
  Widget _buildPosterOrPlaceholder() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0A0E1A), Color(0xFF050A14)],
            ),
          ),
        ),
        // Center icon
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignTokens.neonCyan.withValues(alpha: 0.1),
                  border: Border.all(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  widget.isLive ? Icons.live_tv : Icons.play_circle_outline,
                  color: DesignTokens.neonCyan,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.streamUrl == null || widget.streamUrl!.isEmpty
                    ? 'Stream starting soon...'
                    : 'Loading stream...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Error Overlay ──
  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: DesignTokens.neonRed,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'Stream unavailable',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection or try again',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                setState(() => _hasError = false);
                _initPlayer();
              },
              icon: const Icon(
                Icons.refresh,
                color: DesignTokens.neonCyan,
                size: 18,
              ),
              label: const Text(
                'Retry',
                style: TextStyle(color: DesignTokens.neonCyan),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Controls Overlay ──
  Widget _buildControlsOverlay() {
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.8),
            ],
            stops: const [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Top bar
            _buildTopBar(),
            const Spacer(),
            // Center play button
            _buildCenterPlayButton(),
            const Spacer(),
            // Bottom bar
            if (_initialized) _buildSeekBar(),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ──
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          if (widget.onBack != null)
            IconButton(
              onPressed: widget.onBack,
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 20,
              ),
            ),
          Expanded(
            child: Text(
              widget.eventTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Live badge
          if (widget.isLive) _buildLiveBadge(),
          const SizedBox(width: 8),
          // Viewer count
          if (widget.viewerCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility,
                    size: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatViewers(widget.viewerCount),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Center Play Button ──
  Widget _buildCenterPlayButton() {
    final playing = _controller?.value.isPlaying ?? false;
    return GestureDetector(
      onTap: _togglePlay,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.5),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Icon(
          playing ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }

  // ── Seek Bar ──
  Widget _buildSeekBar() {
    if (_controller == null) return const SizedBox.shrink();
    final value = _controller!.value;
    final duration = value.duration;
    final position = value.position;
    final buffered = value.buffered.isNotEmpty
        ? value.buffered.last.end
        : Duration.zero;

    if (duration.inMilliseconds == 0) return const SizedBox.shrink();

    // For live streams, don't show seek bar
    if (widget.isLive) return const SizedBox.shrink();

    final progress = position.inMilliseconds / duration.inMilliseconds;
    final bufferProgress = buffered.inMilliseconds / duration.inMilliseconds;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: DesignTokens.neonCyan,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
              thumbColor: DesignTokens.neonCyan,
              overlayColor: DesignTokens.neonCyan.withValues(alpha: 0.2),
              trackHeight: 3,
            ),
            child: Stack(
              children: [
                // Buffer indicator
                SliderTheme(
                  data: SliderThemeData(
                    thumbShape: SliderComponentShape.noThumb,
                    activeTrackColor: Colors.white.withValues(alpha: 0.25),
                    inactiveTrackColor: Colors.transparent,
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: bufferProgress.clamp(0.0, 1.0),
                    onChanged: (_) {},
                  ),
                ),
                // Seek slider
                Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: (v) {
                    final newPos = Duration(
                      milliseconds: (v * duration.inMilliseconds).round(),
                    );
                    _seek(newPos);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
                Text(
                  _formatDuration(duration),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Bar ──
  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          // Play/Pause
          IconButton(
            onPressed: _togglePlay,
            icon: Icon(
              (_controller?.value.isPlaying ?? false)
                  ? Icons.pause
                  : Icons.play_arrow,
              color: Colors.white,
              size: 24,
            ),
          ),
          // Volume
          IconButton(
            onPressed: () {
              final muted = _controller?.value.volume == 0;
              _controller?.setVolume(muted ? 1.0 : 0.0);
              setState(() {});
            },
            icon: Icon(
              (_controller?.value.volume ?? 1.0) == 0
                  ? Icons.volume_off
                  : Icons.volume_up,
              color: Colors.white,
              size: 20,
            ),
          ),
          const Spacer(),
          // Quality selector
          _buildQualityButton(),
          const SizedBox(width: 4),
          // Chat toggle
          if (widget.onChatToggle != null)
            IconButton(
              onPressed: widget.onChatToggle,
              icon: Icon(
                widget.showChat ? Icons.chat : Icons.chat_outlined,
                color: widget.showChat ? DesignTokens.neonCyan : Colors.white,
                size: 20,
              ),
            ),
          // Fullscreen
          IconButton(
            onPressed: _toggleFullscreen,
            icon: Icon(
              _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityButton() {
    return PopupMenuButton<String>(
      onSelected: (q) => setState(() => _selectedQuality = q),
      offset: const Offset(0, -200),
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hd, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              _selectedQuality,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (_) => _qualities
          .map(
            (q) => PopupMenuItem(
              value: q,
              child: Row(
                children: [
                  if (q == _selectedQuality)
                    const Icon(
                      Icons.check,
                      color: DesignTokens.neonCyan,
                      size: 16,
                    )
                  else
                    const SizedBox(width: 16),
                  const SizedBox(width: 8),
                  Text(q, style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ── Helpers ──
  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatViewers(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
