import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/ppv_model.dart';
import '../../../shared/services/ppv_service.dart';
import '../models/fight_stats_model.dart';
import '../services/live_fight_stats_service.dart';
import '../widgets/ppv_video_player_hud.dart';
import '../widgets/ppv_round_timer.dart';
import '../widgets/ppv_stats_overlay.dart';
import '../widgets/ppv_replay_toolbar.dart';
import '../widgets/ppv_camera_switcher.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV WATCH SCREEN — NEON-GLASS FIGHT EXPERIENCE
/// ═══════════════════════════════════════════════════════════════════════════
///
/// The premium watch interface that turns standard video playback into
/// a **fight OS** with:
///
///   1. NEON HUD — Fighter names, round clock, live badge
///   2. ROUND TIMER — Animated, pulsing, data-driven
///   3. STATS OVERLAY — Strikes, takedowns, control time, scorecards
///   4. REPLAY TOOLBAR — Clip creation, sharing, timeline navigation
///   5. CAMERA SWITCHER — Multi-camera ready
///
/// Built on Chewie (video_player + built-in controls) with DFC overlays.
/// ═══════════════════════════════════════════════════════════════════════════

class PPVWatchScreen extends StatefulWidget {
  /// Event ID from router (loads full event data)
  final String? eventId;

  /// Full PPV event (preferred — carries all fight data)
  final PPVEvent? event;

  /// Fallback: Mux playback ID (minimal player)
  final String? playbackId;

  /// Optional: Navigate back on close
  final VoidCallback? onClose;

  const PPVWatchScreen({
    super.key,
    this.eventId,
    this.event,
    this.playbackId,
    this.onClose,
  }) : assert(
         eventId != null || event != null || playbackId != null,
         'Either eventId, event, or playbackId must be provided',
       );

  @override
  State<PPVWatchScreen> createState() => _PPVWatchScreenState();
}

class _PPVWatchScreenState extends State<PPVWatchScreen>
    with TickerProviderStateMixin {
  final PPVService _ppvService = PPVService();
  late LiveFightStatsService _liveStatsService;

  // ── Video Player ──
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  // ── Overlays State ──
  bool _showOverlays = true;
  late AnimationController _overlayFadeCtrl;
  late Animation<double> _overlayFade;

  // ── Fight Data ──
  PPVEvent? _event;
  bool _loading = true;
  String? _error;

  // ── Round State ──
  final ValueNotifier<int> _currentRound = ValueNotifier<int>(1);
  final ValueNotifier<int> _roundTimeRemaining = ValueNotifier<int>(
    300,
  ); // 5 min per round

  // ── Stats State ──
  final ValueNotifier<FighterStats> _fighter1Stats =
      ValueNotifier<FighterStats>(FighterStats.initial());
  final ValueNotifier<FighterStats> _fighter2Stats =
      ValueNotifier<FighterStats>(FighterStats.initial());

  // ── Camera State ──
  final ValueNotifier<int> _selectedCamera = ValueNotifier<int>(0);

  // ── Timers ──
  late AnimationController _roundPulseCtrl;

  @override
  void initState() {
    super.initState();
    _liveStatsService = LiveFightStatsService();
    _liveStatsService.addListener(_onLiveStatsUpdate);
    _loadEventAndInitPlayer();
    _initAnimations();
  }

  void _onLiveStatsUpdate() {
    // Live stats updated from Firestore
    // Update round and stats ValueNotifiers
    if (mounted) {
      _currentRound.value = _liveStatsService.currentRound;
      if (_liveStatsService.fighter1Stats != null) {
        _fighter1Stats.value = _liveStatsService.fighter1Stats!;
      }
      if (_liveStatsService.fighter2Stats != null) {
        _fighter2Stats.value = _liveStatsService.fighter2Stats!;
      }
    }
  }

  void _initAnimations() {
    // Overlay fade animation
    _overlayFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _overlayFade = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _overlayFadeCtrl, curve: Curves.easeOut));

    // Round timer pulse
    _roundPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _liveStatsService.removeListener(_onLiveStatsUpdate);
    _liveStatsService.dispose();
    _overlayFadeCtrl.dispose();
    _roundPulseCtrl.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    _currentRound.dispose();
    _roundTimeRemaining.dispose();
    _fighter1Stats.dispose();
    _fighter2Stats.dispose();
    _selectedCamera.dispose();
    super.dispose();
  }

  Future<void> _loadEventAndInitPlayer() async {
    try {
      // Priority: Use preloaded event, fetch by ID, then fallback to playbackId
      if (widget.event != null) {
        _event = widget.event;
        _initVideoPlayer();
        // Initialize live stats if we have event ID (for real fight scenarios)
        if (widget.eventId != null) {
          await _liveStatsService.initializeFightStats(
            widget.eventId!,
            'live', // Default session ID
          );
        }
        if (mounted) {
          setState(() => _loading = false);
        }
        return;
      }

      // If we have an event ID, fetch the event from Firestore
      if (widget.eventId != null) {
        _event = await _ppvService.getPPVEvent(widget.eventId!);
        _initVideoPlayer();
        // Initialize live stats
        await _liveStatsService.initializeFightStats(widget.eventId!, 'live');
        if (mounted) {
          setState(() => _loading = false);
        }
        return;
      }

      // If we have a playback ID, minimal load (no live stats)
      if (widget.playbackId != null) {
        _initVideoPlayer();
        if (mounted) {
          setState(() => _loading = false);
        }
        return;
      }

      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load event: $e';
        });
      }
    }
  }

  void _initVideoPlayer() {
    final playbackId =
        _event?.muxPlaybackId ?? _event?.replayPlaybackId ?? widget.playbackId;

    if (playbackId == null) {
      debugPrint('⚠️ No playback ID available for PPV watch screen');
      return;
    }

    final url = 'https://stream.mux.com/$playbackId.m3u8';

    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));

    _videoController!.initialize().then((_) {
      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        autoInitialize: true,
        aspectRatio: _videoController!.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: DesignTokens.neonCyan,
          handleColor: DesignTokens.neonCyan,
          backgroundColor: Colors.white12,
          bufferedColor: Colors.white38,
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: DesignTokens.neonRed,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      setState(() {});
    });
  }

  void _toggleOverlays() {
    if (_showOverlays) {
      _overlayFadeCtrl.forward();
    } else {
      _overlayFadeCtrl.reverse();
    }
    setState(() => _showOverlays = !_showOverlays);
  }

  void _advanceRound() {
    if (_event == null) return;
    final maxRounds = _event!.fightCard.isNotEmpty
        ? _event!.fightCard.first.rounds
        : 3;
    if (_currentRound.value < maxRounds) {
      _currentRound.value++;
      _roundTimeRemaining.value = 300; // Reset to 5 min
    }
  }

  void _previousRound() {
    if (_currentRound.value > 1) {
      _currentRound.value--;
      _roundTimeRemaining.value = 300;
    }
  }

  void _updateFighterStats(int fighterIndex, FighterStats stats) {
    if (fighterIndex == 0) {
      _fighter1Stats.value = stats;
    } else {
      _fighter2Stats.value = stats;
    }
  }

  void _switchCamera(int index) {
    _selectedCamera.value = index;
    // TODO: Implement actual camera switching in video stream
  }

  String? _getVideoUrl() {
    // Try to get from Mux playback ID first
    if (widget.playbackId != null) {
      return 'https://stream.mux.com/${widget.playbackId}.m3u8';
    }

    // Try from event
    if (_event?.muxPlaybackId != null) {
      return 'https://stream.mux.com/${_event!.muxPlaybackId}.m3u8';
    }

    if (_event?.streamUrl != null) {
      return _event!.streamUrl;
    }

    return null;
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _overlayFadeCtrl.dispose();
    _roundPulseCtrl.dispose();
    _currentRound.dispose();
    _roundTimeRemaining.dispose();
    _fighter1Stats.dispose();
    _fighter2Stats.dispose();
    _selectedCamera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF030810),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: DesignTokens.neonRed, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF030810),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(DesignTokens.neonCyan),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'LOADING FIGHT...',
                style: TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_chewieController == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF030810),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: DesignTokens.neonRed, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Failed to load video player',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleOverlays,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Video Player (Background) ──
            Theme(
              data: ThemeData.dark(),
              child: Chewie(controller: _chewieController!),
            ),

            // ── Animated Overlay Container ──
            FadeTransition(
              opacity: _overlayFade,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── Neon HUD (Top) ──
                  if (_event != null)
                    PPVVideoPlayerHUD(
                      event: _event!,
                      currentRound: _currentRound,
                      isLive: _event!.isLive,
                    ),

                  // ── Round Timer (Center) ──
                  if (_event != null)
                    Center(
                      child: PPVRoundTimer(
                        currentRound: _currentRound,
                        totalRounds: _event!.fightCard.isNotEmpty
                            ? _event!.fightCard.first.rounds
                            : 3,
                        timeRemaining: _roundTimeRemaining,
                        pulseAnimation: _roundPulseCtrl,
                        onNextRound: _advanceRound,
                        onPrevRound: _previousRound,
                      ),
                    ),

                  // ── Stats Overlay (Bottom Right) ──
                  if (_event != null && _event!.fightCard.isNotEmpty)
                    Positioned(
                      right: 16,
                      bottom: 100,
                      child: PPVStatsOverlay(
                        fighter1: _event!.fightCard.first.fighter1Name,
                        fighter2: _event!.fightCard.first.fighter2Name,
                        fighter1Stats: _fighter1Stats,
                        fighter2Stats: _fighter2Stats,
                      ),
                    ),

                  // ── Camera Switcher (Top Right) ──
                  if (_event?.multiCamEnabled ?? false)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: PPVCameraSwitcher(
                        selectedCamera: _selectedCamera,
                        onCameraSwitch: _switchCamera,
                      ),
                    ),

                  // ── Replay Toolbar (Bottom) ──
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: PPVReplayToolbar(
                      event: _event,
                      currentRound: _currentRound,
                      videoUrl: _getVideoUrl(),
                      fighter1Name: _event?.fightCard.isNotEmpty ?? false
                          ? _event!.fightCard.first.fighter1Name
                          : null,
                      fighter2Name: _event?.fightCard.isNotEmpty ?? false
                          ? _event!.fightCard.first.fighter2Name
                          : null,
                      onClipCreated: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✨ Clip editor opened!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),

                  // ── Close Button (Top Left) ──
                  Positioned(
                    top: 12,
                    left: 12,
                    child: SafeArea(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onClose ?? () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ── Fight Stats Model ──
class FighterStats {
  final int strikesLanded;
  final int strikeAttempts;
  final int takedownsLanded;
  final int takedownAttempts;
  final int controlTimeSeconds;
  final int knockdowns;

  FighterStats({
    required this.strikesLanded,
    required this.strikeAttempts,
    required this.takedownsLanded,
    required this.takedownAttempts,
    required this.controlTimeSeconds,
    required this.knockdowns,
  });

  factory FighterStats.initial() => FighterStats(
    strikesLanded: 0,
    strikeAttempts: 0,
    takedownsLanded: 0,
    takedownAttempts: 0,
    controlTimeSeconds: 0,
    knockdowns: 0,
  );

  double get strikeAccuracy =>
      strikeAttempts > 0 ? (strikesLanded / strikeAttempts) * 100 : 0;

  double get takedownAccuracy =>
      takedownAttempts > 0 ? (takedownsLanded / takedownAttempts) * 100 : 0;

  String get controlTimeDisplay {
    final mins = controlTimeSeconds ~/ 60;
    final secs = controlTimeSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}
