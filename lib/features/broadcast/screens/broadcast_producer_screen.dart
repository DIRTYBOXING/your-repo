import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../models/broadcast_control_model.dart';
import '../services/broadcast_control_service.dart';
import '../widgets/broadcast_camera_grid.dart';
import '../widgets/broadcast_replay_queue.dart';
import '../widgets/broadcast_graphics_panel.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// BROADCAST PRODUCER SCREEN — Professional Production Booth
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Director interface for:
///   - Multi-camera switching
///   - Replay queue management
///   - Graphics overlay control
///   - Broadcast mode control (live, replay, paused, slow-mo)
///   - Commentary track management
///   - Timeline scrubbing
///
/// This is where the broadcast director controls the professional broadcast
/// experience in real-time from orchestration events.
///
/// ═══════════════════════════════════════════════════════════════════════════

class BroadcastProducerScreen extends StatefulWidget {
  /// Event ID
  final String eventId;

  /// Session ID
  final String sessionId;

  /// Fight ID
  final String fightId;

  const BroadcastProducerScreen({
    super.key,
    required this.eventId,
    required this.sessionId,
    required this.fightId,
  });

  @override
  State<BroadcastProducerScreen> createState() =>
      _BroadcastProducerScreenState();
}

class _BroadcastProducerScreenState extends State<BroadcastProducerScreen> {
  late BroadcastControlService _broadcastService;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _broadcastService = BroadcastControlService();
    _broadcastService.addListener(_onBroadcastUpdate);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _broadcastService.initializeBroadcast(
        widget.eventId,
        widget.sessionId,
        widget.fightId,
      );
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to initialize broadcast: $e');
      }
    }
  }

  void _onBroadcastUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: DesignTokens.bgPrimary,
        appBar: AppBar(title: const Text('Production Booth')),
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: DesignTokens.bgPrimary,
        appBar: AppBar(title: const Text('Production Booth')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final session = _broadcastService.broadcastSession;
    if (session == null) {
      return Scaffold(
        backgroundColor: DesignTokens.bgPrimary,
        appBar: AppBar(title: const Text('Production Booth')),
        body: const Center(child: Text('No broadcast session loaded')),
      );
    }

    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgCard,
        title: const Text('🎬 Professional Broadcast Booth'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: session.isLiveOnWire
                      ? DesignTokens.neonRed.withOpacity(0.2)
                      : Colors.white10,
                  border: Border.all(
                    color: session.isLiveOnWire
                        ? DesignTokens.neonRed
                        : Colors.white30,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  session.isLiveOnWire ? '🔴 LIVE ON AIR' : '⚫ REHEARSAL',
                  style: TextStyle(
                    color: session.isLiveOnWire
                        ? DesignTokens.neonRed
                        : Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Broadcast Mode Control ──
              _buildModeControl(session),
              const SizedBox(height: 24),

              // ── Camera Grid ──
              _buildCameraSection(session),
              const SizedBox(height: 24),

              // ── Replay Queue ──
              BroadcastReplayQueue(
                markers: _broadcastService.replayQueue,
                onPlayReplay: _onPlayReplay,
              ),
              const SizedBox(height: 24),

              // ── Graphics Control ──
              BroadcastGraphicsPanel(
                graphicsState: _broadcastService.graphicsState,
                onGraphicsUpdate: _onGraphicsUpdate,
              ),
              const SizedBox(height: 24),

              // ── Go Live Button ──
              if (!session.isLiveOnWire)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onGoLive,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.neonRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '🔴 GO LIVE ON BROADCAST WIRE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeControl(BroadcastSession session) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        border: Border.all(
          color: DesignTokens.neonCyan.withOpacity(0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BROADCAST MODE',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ...([
                ('LIVE', BroadcastMode.live, DesignTokens.neonGreen),
                ('REPLAY', BroadcastMode.replay, DesignTokens.neonAmber),
                ('PAUSE', BroadcastMode.paused, DesignTokens.neonRed),
                ('SLOW-MO', BroadcastMode.slowMotion, DesignTokens.neonCyan),
              ].map((item) {
                final (label, mode, color) = item;
                final isActive = session.mode == mode;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: () => _onModeChange(mode),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive
                            ? color.withOpacity(0.3)
                            : Colors.white10,
                        foregroundColor: isActive ? color : Colors.white60,
                        side: BorderSide(
                          color: isActive ? color : Colors.white24,
                          width: isActive ? 2 : 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                );
              })),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraSection(BroadcastSession session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CAMERA CONTROL',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        BroadcastCameraGrid(
          cameras: session.cameras,
          activeCameraId: session.activeCameraId,
          onCameraSelected: _onCameraSelected,
        ),
      ],
    );
  }

  Future<void> _onCameraSelected(String cameraId) async {
    await _broadcastService.switchCamera(
      widget.eventId,
      widget.sessionId,
      widget.fightId,
      cameraId,
    );
  }

  Future<void> _onModeChange(BroadcastMode mode) async {
    await _broadcastService.setBroadcastMode(
      widget.eventId,
      widget.sessionId,
      widget.fightId,
      mode,
    );
  }

  Future<void> _onPlayReplay() async {
    await _broadcastService.playNextReplay(
      widget.eventId,
      widget.sessionId,
      widget.fightId,
    );
  }

  Future<void> _onGraphicsUpdate(GraphicsState newState) async {
    await _broadcastService.updateGraphics(
      widget.eventId,
      widget.sessionId,
      widget.fightId,
      newState,
    );
  }

  Future<void> _onGoLive() async {
    await _broadcastService.goLiveOnWire(
      widget.eventId,
      widget.sessionId,
      widget.fightId,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🔴 NOW LIVE ON BROADCAST WIRE'),
          backgroundColor: DesignTokens.neonRed,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _broadcastService.removeListener(_onBroadcastUpdate);
    _broadcastService.dispose();
    super.dispose();
  }
}
