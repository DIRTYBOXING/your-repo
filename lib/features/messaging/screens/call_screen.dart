import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/dfc_network_image.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC CALL SCREEN — Voice & Video calls (WebRTC-ready)
///
/// Currently renders a full native-quality call UI with:
/// - Incoming/outgoing call states with ring animation
/// - Active call timer, mute, speaker, hold controls
/// - Video toggle with picture-in-picture layout
/// - End call with haptic feedback
/// - Ready for WebRTC signaling integration
/// ═══════════════════════════════════════════════════════════════════════════
enum CallType { voice, video }

enum CallState { ringing, connecting, active, ended }

class CallScreen extends StatefulWidget {
  final String otherName;
  final String otherPhotoUrl;
  final String otherUserId;
  final CallType callType;
  final bool isIncoming;

  const CallScreen({
    super.key,
    required this.otherName,
    this.otherPhotoUrl = '',
    this.otherUserId = '',
    this.callType = CallType.voice,
    this.isIncoming = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen>
    with TickerProviderStateMixin {
  late CallState _callState;
  late CallType _callType;
  bool _isMuted = false;
  bool _isSpeaker = false;
  bool _isHeld = false;
  bool _localVideoEnabled = true;
  Duration _callDuration = Duration.zero;
  Timer? _callTimer;
  Timer? _autoConnect;

  late AnimationController _ringController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _callType = widget.callType;
    _callState = widget.isIncoming ? CallState.ringing : CallState.connecting;

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto-connect after 3 seconds for outgoing calls (simulated)
    if (!widget.isIncoming) {
      _autoConnect = Timer(const Duration(seconds: 3), _onConnected);
    }
  }

  void _onConnected() {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _callState = CallState.active);
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _callDuration += const Duration(seconds: 1));
    });
  }

  void _answerCall() {
    HapticFeedback.heavyImpact();
    setState(() => _callState = CallState.connecting);
    Timer(const Duration(seconds: 1), _onConnected);
  }

  void _endCall() {
    HapticFeedback.heavyImpact();
    _callTimer?.cancel();
    setState(() => _callState = CallState.ended);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _autoConnect?.cancel();
    _ringController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryBackground,
                  const Color(0xFF0A1929),
                  _callType == CallType.video
                      ? Colors.black
                      : const Color(0xFF0D2137),
                ],
              ),
            ),
          ),

          // Video call: full screen "remote video" placeholder
          if (_callType == CallType.video && _callState == CallState.active)
            Positioned.fill(
              child: Container(
                color: const Color(0xFF0A0A0A),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAvatar(size: 120),
                      const SizedBox(height: 16),
                      Text(
                        widget.otherName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Video connected',
                        style: TextStyle(
                          color: AppTheme.neonCyan.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Video call: local video PiP
          if (_callType == CallType.video &&
              _callState == CallState.active &&
              _localVideoEnabled)
            Positioned(
              right: 16,
              top: MediaQuery.of(context).padding.top + 16,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.neonCyan.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person,
                          size: 40,
                          color: AppTheme.neonCyan.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Main call UI
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      if (_callState != CallState.ringing)
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _callState == CallState.active
                              ? AppTheme.neonGreen.withValues(alpha: 0.15)
                              : AppTheme.neonCyan.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _callState == CallState.active
                                ? AppTheme.neonGreen.withValues(alpha: 0.3)
                                : AppTheme.neonCyan.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_callState == CallState.active)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.neonGreen,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.neonGreen.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            Icon(
                              _callType == CallType.video
                                  ? Icons.videocam
                                  : Icons.phone,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _callType == CallType.video
                                  ? 'Video Call'
                                  : 'Voice Call',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Center content
                if (_callType != CallType.video ||
                    _callState != CallState.active)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated avatar with ring effect
                        AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _callState == CallState.ringing
                                  ? _pulseAnim.value
                                  : 1.0,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Pulse rings
                                  if (_callState == CallState.ringing ||
                                      _callState == CallState.connecting)
                                    ...List.generate(3, (i) {
                                      return AnimatedBuilder(
                                        animation: _ringController,
                                        builder: (context, _) {
                                          final progress =
                                              (_ringController.value +
                                                      i * 0.33) %
                                                  1.0;
                                          return Container(
                                            width: 140 + (progress * 60),
                                            height: 140 + (progress * 60),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppTheme.neonCyan
                                                    .withValues(
                                                      alpha: 0.3 *
                                                          (1 - progress),
                                                    ),
                                                width: 2,
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }),
                                  _buildAvatar(size: 120),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Name
                        Text(
                          widget.otherName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Status
                        Text(
                          _statusText,
                          style: TextStyle(
                            color: _callState == CallState.active
                                ? AppTheme.neonGreen
                                : AppTheme.neonCyan.withValues(alpha: 0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        // Call timer
                        if (_callState == CallState.active) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatDuration(_callDuration),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],

                        if (_isHeld) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.neonOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'ON HOLD',
                              style: TextStyle(
                                color: AppTheme.neonOrange,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                else
                  const Spacer(),

                // Control buttons
                _buildControls(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppTheme.neonCyan.withValues(alpha: 0.3),
            AppTheme.neonMagenta.withValues(alpha: 0.3),
          ],
        ),
        border: Border.all(
          color: AppTheme.neonCyan.withValues(alpha: 0.4),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonCyan.withValues(alpha: 0.2),
            blurRadius: 30,
          ),
        ],
      ),
      child: ClipOval(
        child: widget.otherPhotoUrl.isNotEmpty
            ? DfcNetworkImage(url: widget.otherPhotoUrl)
            : Center(
                child: Text(
                  widget.otherName.isNotEmpty
                      ? widget.otherName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
      ),
    );
  }

  String get _statusText {
    switch (_callState) {
      case CallState.ringing:
        return widget.isIncoming ? 'Incoming call…' : 'Ringing…';
      case CallState.connecting:
        return 'Connecting…';
      case CallState.active:
        return 'Connected';
      case CallState.ended:
        return 'Call ended';
    }
  }

  Widget _buildControls() {
    if (_callState == CallState.ringing && widget.isIncoming) {
      return _buildIncomingControls();
    }
    return _buildActiveControls();
  }

  Widget _buildIncomingControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Decline
          _buildCallButton(
            icon: Icons.call_end,
            label: 'Decline',
            color: Colors.red,
            onTap: _endCall,
            size: 72,
          ),
          // Answer
          _buildCallButton(
            icon: widget.callType == CallType.video
                ? Icons.videocam
                : Icons.call,
            label: 'Answer',
            color: AppTheme.neonGreen,
            onTap: _answerCall,
            size: 72,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveControls() {
    return Column(
      children: [
        // Main controls row
        if (_callState == CallState.active)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  label: _isMuted ? 'Unmute' : 'Mute',
                  isActive: _isMuted,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isMuted = !_isMuted);
                  },
                ),
                _buildControlButton(
                  icon: _isSpeaker ? Icons.volume_up : Icons.volume_down,
                  label: _isSpeaker ? 'Speaker' : 'Speaker',
                  isActive: _isSpeaker,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isSpeaker = !_isSpeaker);
                  },
                ),
                if (_callType == CallType.video)
                  _buildControlButton(
                    icon: _localVideoEnabled
                        ? Icons.videocam
                        : Icons.videocam_off,
                    label: 'Camera',
                    isActive: !_localVideoEnabled,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(
                        () => _localVideoEnabled = !_localVideoEnabled,
                      );
                    },
                  ),
                _buildControlButton(
                  icon: _isHeld ? Icons.play_arrow : Icons.pause,
                  label: _isHeld ? 'Resume' : 'Hold',
                  isActive: _isHeld,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isHeld = !_isHeld);
                  },
                ),
                if (_callType == CallType.voice)
                  _buildControlButton(
                    icon: Icons.videocam,
                    label: 'Video',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _callType = CallType.video);
                    },
                  ),
              ],
            ),
          ),

        const SizedBox(height: 24),

        // End call button
        _buildCallButton(
          icon: Icons.call_end,
          label: 'End Call',
          color: Colors.red,
          onTap: _endCall,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: isActive
                    ? AppTheme.neonCyan.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    double size = 64,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: size * 0.45),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
