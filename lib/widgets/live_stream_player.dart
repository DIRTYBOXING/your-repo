import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../core/theme/design_tokens.dart';
import '../shared/widgets/liquid_fire_overlay.dart';
import '../shared/services/adrenaline_controller.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// LIVE STREAM PLAYER — Drop-in PPV stream + countdown widget
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Place directly below [FightCardPoster] on fight night.
///
/// Behaviour:
///   • Before event  → shows animated countdown with pulsing red LIVE badge
///   • During event  → auto-flips to stream (YouTube embed or HLS player)
///   • After event   → shows replay prompt
///
/// Supports:
///   • YouTube embeds via [youtubeVideoId]
///   • HLS / DASH via [streamUrl]
///   • Falls back to countdown if neither is provided
///   • Emergency YouTube fallback via [fallbackYoutubeId]
///   • Adrenaline Gate HUD: Liquid Fire overlay + haptic triggers
///
/// Usage:
///   LiveStreamPlayer(
///     eventDate: DateTime(2026, 5, 10, 19, 0),
///     eventTitle: 'Roesler vs Tanwar',
///     streamUrl: 'https://stream.mux.com/xxx.m3u8',
///     fallbackYoutubeId: 'abc123',   // emergency backup
///   )
/// ═══════════════════════════════════════════════════════════════════════════
class LiveStreamPlayer extends StatefulWidget {
  final DateTime eventDate;
  final String eventTitle;
  final String? streamUrl;
  final String? youtubeVideoId;
  /// Emergency YouTube fallback if primary HLS stream fails.
  final String? fallbackYoutubeId;
  final int viewerCount;
  final VoidCallback? onExpand;
  /// Enable Adrenaline Gate HUD (Liquid Fire overlay + haptics).
  final bool enableAdrenalineHUD;

  const LiveStreamPlayer({
    super.key,
    required this.eventDate,
    this.eventTitle = '',
    this.streamUrl,
    this.youtubeVideoId,
    this.fallbackYoutubeId,
    this.viewerCount = 0,
    this.onExpand,
    this.enableAdrenalineHUD = true,
  });

  @override
  State<LiveStreamPlayer> createState() => _LiveStreamPlayerState();
}

class _LiveStreamPlayerState extends State<LiveStreamPlayer>
    with SingleTickerProviderStateMixin {
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  bool _isLive = false;
  bool _isReplay = false;

  // HLS player
  VideoPlayerController? _videoController;
  bool _videoReady = false;

  // YouTube player
  YoutubePlayerController? _ytController;

  // Pulse animation for LIVE badge
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  // ── Adrenaline Gate ──
  final AdrenalineController _adrenaline = AdrenalineController();
  double _hypeIntensity = 0.0;

  // ── Stream health ──
  bool _streamFailed = false;
  bool _usingFallback = false;
  int _stallCount = 0;
  Timer? _healthTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _evaluateState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _evaluateState();
    });
  }

  void _evaluateState() {
    final now = DateTime.now();
    final diff = widget.eventDate.difference(now);

    if (diff.isNegative && diff.inHours.abs() > 6) {
      // Event ended > 6 hours ago → replay
      if (!_isReplay) {
        setState(() {
          _isReplay = true;
          _isLive = false;
        });
      }
    } else if (diff.isNegative || diff.inMinutes < 5) {
      // Within 5 min of start or past start → LIVE
      if (!_isLive) {
        setState(() {
          _isLive = true;
          _isReplay = false;
        });
        _initStream();
      }
    } else {
      // Pre-event countdown
      setState(() {
        _remaining = diff;
        _isLive = false;
        _isReplay = false;
      });
    }
  }

  void _initStream() {
    if (widget.youtubeVideoId != null && widget.youtubeVideoId!.isNotEmpty) {
      _ytController = YoutubePlayerController.fromVideoId(
        videoId: widget.youtubeVideoId!,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
        ),
      );
      setState(() {});
    } else if (widget.streamUrl != null && widget.streamUrl!.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.streamUrl!),
      )..initialize().then((_) {
          if (mounted) {
            setState(() => _videoReady = true);
            _videoController!.play();
            // Seek to live edge for minimum latency
            _seekToLiveEdge();
            // Start stream health monitor
            _startHealthMonitor();
          }
        }).catchError((e) {
          // Primary stream failed — try fallback
          debugPrint('Primary stream failed: $e');
          _activateFallback();
        });
    }
    // Set initial hype
    if (widget.enableAdrenalineHUD) {
      _hypeIntensity = 0.6;
      _adrenaline.updateIntensity(0.6);
    }
  }

  /// Seek to the live edge of the HLS stream for minimum glass-to-glass latency.
  void _seekToLiveEdge() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;
    final duration = controller.value.duration;
    if (duration > Duration.zero) {
      // Seek to within 1 second of live edge
      final liveEdge = duration - const Duration(seconds: 1);
      if (liveEdge > Duration.zero) {
        controller.seekTo(liveEdge);
      }
    }
  }

  /// Monitor stream health: detect stalls and trigger fallback.
  void _startHealthMonitor() {
    _healthTimer?.cancel();
    Duration? lastPosition;
    _healthTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final controller = _videoController;
      if (controller == null || !controller.value.isInitialized) return;

      final pos = controller.value.position;
      if (lastPosition != null && pos == lastPosition && controller.value.isPlaying) {
        _stallCount++;
        if (_stallCount >= 3) {
          // 9+ seconds stalled — try live-edge re-seek first
          _seekToLiveEdge();
        }
        if (_stallCount >= 5) {
          // 15+ seconds stalled — activate emergency fallback
          _activateFallback();
        }
      } else {
        _stallCount = 0;
      }
      lastPosition = pos;

      // Periodically re-seek to live edge to prevent drift
      if (_stallCount == 0 && _isLive) {
        final duration = controller.value.duration;
        final drift = duration - pos;
        if (drift > const Duration(seconds: 5)) {
          _seekToLiveEdge();
        }
      }
    });
  }

  /// Activate emergency YouTube fallback stream.
  void _activateFallback() {
    if (_usingFallback) return;
    final fallbackId = widget.fallbackYoutubeId;
    if (fallbackId == null || fallbackId.isEmpty) {
      setState(() => _streamFailed = true);
      return;
    }

    debugPrint('Activating emergency YouTube fallback: $fallbackId');
    _healthTimer?.cancel();
    _videoController?.dispose();
    _videoController = null;

    _ytController = YoutubePlayerController.fromVideoId(
      videoId: fallbackId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
      ),
    );
    setState(() {
      _usingFallback = true;
      _streamFailed = false;
      _videoReady = false;
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _healthTimer?.cancel();
    _pulseCtrl.dispose();
    _adrenaline.dispose();
    _videoController?.dispose();
    _ytController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        border: Border.all(
          color: _isLive ? DesignTokens.neonRed : DesignTokens.borderSubtle,
          width: _isLive ? DesignTokens.borderThick : DesignTokens.borderThin,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Header bar ───
          _buildHeader(),
          // ─── Main content ───
          if (_isLive)
            _buildLivePlayer()
          else if (_isReplay)
            _buildReplayPrompt()
          else
            _buildCountdown(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.cardPaddingMedium,
        vertical: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.bgOverlay,
        border: Border(
          bottom: BorderSide(
            color: _isLive
                ? DesignTokens.neonRed.withValues(alpha: 0.4)
                : DesignTokens.borderSubtle,
          ),
        ),
      ),
      child: Row(
        children: [
          // LIVE badge or UPCOMING label
          if (_isLive) ...[
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DesignTokens.neonRed.withValues(alpha: _pulse.value),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.white, size: 8),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ] else ...[
            Icon(
              _isReplay ? Icons.replay : Icons.schedule,
              color: DesignTokens.textMuted,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              _isReplay ? 'REPLAY' : 'UPCOMING',
              style: const TextStyle(
                color: DesignTokens.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Event title
          Expanded(
            child: Text(
              widget.eventTitle,
              style: const TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: DesignTokens.fontSizeSubtitleLarge,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Viewer count (when live)
          if (_isLive && widget.viewerCount > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.visibility, color: DesignTokens.neonCyan, size: 14),
                const SizedBox(width: 4),
                Text(
                  _formatViewers(widget.viewerCount),
                  style: const TextStyle(
                    color: DesignTokens.neonCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          // Expand button
          if (widget.onExpand != null)
            IconButton(
              icon: const Icon(Icons.fullscreen, color: DesignTokens.textMuted, size: 20),
              onPressed: widget.onExpand,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COUNTDOWN — pre-event
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCountdown() {
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, _) => Icon(
              Icons.sports_mma,
              color: DesignTokens.neonRed.withValues(alpha: _pulse.value),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'FIGHT STARTS IN',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _countdownUnit(days.toString().padLeft(2, '0'), 'DAYS'),
              _countdownSeparator(),
              _countdownUnit(hours.toString().padLeft(2, '0'), 'HRS'),
              _countdownSeparator(),
              _countdownUnit(minutes.toString().padLeft(2, '0'), 'MIN'),
              _countdownSeparator(),
              _countdownUnit(seconds.toString().padLeft(2, '0'), 'SEC'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _countdownUnit(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: DesignTokens.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _countdownSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        ':',
        style: TextStyle(
          color: DesignTokens.neonRed,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LIVE PLAYER — YouTube or HLS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLivePlayer() {
    if (_streamFailed) {
      return _buildStreamFailedState();
    }

    Widget player;

    if (_ytController != null) {
      player = AspectRatio(
        aspectRatio: 16 / 9,
        child: YoutubePlayer(controller: _ytController!),
      );
    } else if (_videoController != null && _videoReady) {
      player = AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_videoController!),
            // Tap to play/pause
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                  _seekToLiveEdge();
                }
                setState(() {});
              },
              child: const SizedBox.expand(),
            ),
          ],
        ),
      );
    } else {
      // Stream initializing
      player = const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: DesignTokens.neonRed),
              SizedBox(height: 12),
              Text(
                'Connecting to stream...',
                style: TextStyle(color: DesignTokens.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // ── Adrenaline Gate HUD: wrap player with Liquid Fire overlay ──
    if (widget.enableAdrenalineHUD && _isLive) {
      return Stack(
        children: [
          player,
          // Liquid Fire edge glow (GPU shader)
          Positioned.fill(
            child: IgnorePointer(
              child: LiquidFireOverlay(
                winProbability: _hypeIntensity,
                threshold: 0.2,
              ),
            ),
          ),
          // Fallback indicator
          if (_usingFallback)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'BACKUP STREAM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return player;
  }

  /// Stream failed with no fallback available — show error state.
  Widget _buildStreamFailedState() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: DesignTokens.bgCard,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.signal_wifi_off, color: DesignTokens.neonRed, size: 40),
              const SizedBox(height: 12),
              const Text(
                'STREAM INTERRUPTED',
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Attempting to reconnect...',
                style: TextStyle(color: DesignTokens.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _streamFailed = false;
                    _stallCount = 0;
                  });
                  _initStream();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('RETRY'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.neonRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REPLAY — post-event
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildReplayPrompt() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          const Icon(Icons.replay, color: DesignTokens.neonCyan, size: 40),
          const SizedBox(height: 12),
          const Text(
            'EVENT CONCLUDED',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.eventTitle,
            style: const TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.streamUrl != null || widget.youtubeVideoId != null)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLive = true;
                  _isReplay = false;
                });
                _initStream();
              },
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('WATCH REPLAY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.neonRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatViewers(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
