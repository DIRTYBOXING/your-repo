import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// REAL-TIME PPV STREAMING — WebRTC Multi-Angle Arena (God Tier Edition)
/// ═══════════════════════════════════════════════════════════════════════════
class PpvStreamScreen extends StatefulWidget {
  final String eventId;

  const PpvStreamScreen({super.key, required this.eventId});

  @override
  State<PpvStreamScreen> createState() => _PpvStreamScreenState();
}

class _PpvStreamScreenState extends State<PpvStreamScreen>
    with TickerProviderStateMixin {
  // WebRTC Renderers
  final RTCVideoRenderer _mainRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _redCornerRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _blueCornerRenderer = RTCVideoRenderer();

  late AnimationController _hypeController;
  late AnimationController _uiFadeController;

  bool _isUiVisible = true;
  int _activeCameraAngle = 0; // 0: Main, 1: Red Corner, 2: Blue Corner
  bool _isConnecting = true;

  final List<String> _chatMessages = [];
  final TextEditingController _chatInputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initRenderers();

    _hypeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _uiFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );

    // Simulate connection delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isConnecting = false);
      _simulateLiveChat();
    });
  }

  Future<void> _initRenderers() async {
    await _mainRenderer.initialize();
    await _redCornerRenderer.initialize();
    await _blueCornerRenderer.initialize();
    // In a real implementation, you would attach the MediaStream here:
    // _mainRenderer.srcObject = _webrtcService.mainStream;
  }

  @override
  void dispose() {
    _mainRenderer.dispose();
    _redCornerRenderer.dispose();
    _blueCornerRenderer.dispose();
    _hypeController.dispose();
    _uiFadeController.dispose();
    _chatInputCtrl.dispose();
    super.dispose();
  }

  void _toggleUi() {
    if (_isUiVisible) {
      _uiFadeController.reverse();
    } else {
      _uiFadeController.forward();
    }
    _isUiVisible = !_isUiVisible;
  }

  void _simulateLiveChat() {
    final messages = [
      "Lets gooo Pereira! 🏹",
      "That leg kick was brutal 💥",
      "Watch out for the counter",
      "HYPE is real right now 🔥🔥🔥",
    ];
    int i = 0;
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _chatMessages.insert(0, messages[i % messages.length]);
        if (_chatMessages.length > 20) _chatMessages.removeLast();
      });
      i++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleUi,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── 1. The Video Stream (WebRTC Renderer) ──
            _buildVideoLayer(),

            // ── 2. Cinematic Gradient Overlay ──
            Positioned.fill(
              child: IgnorePointer(
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
                      stops: const [0.0, 0.2, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // ── 3. Fadeable UI Layer ──
            FadeTransition(
              opacity: _uiFadeController,
              child: Stack(
                children: [
                  _buildTopBar(),
                  _buildLiveStatsOverlay(),
                  _buildCameraAngleSelector(),
                  _buildHypeMeter(),
                  _buildBottomChatArea(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI COMPONENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildVideoLayer() {
    if (_isConnecting) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.neonRed),
            SizedBox(height: 16),
            Text(
              'ESTABLISHING SECURE WEBRTC CONNECTION...',
              style: TextStyle(
                color: AppTheme.neonRed,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );
    }

    // Display the active WebRTC renderer
    // Wrapping in a placeholder container since we don't have actual streams injected
    return Container(
      color: const Color(0xFF0A0F14),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _activeCameraAngle == 0
                  ? Icons.videocam
                  : _activeCameraAngle == 1
                  ? Icons.camera_alt
                  : Icons.camera,
              size: 80,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(
              _activeCameraAngle == 0
                  ? 'MAIN BROADCAST FEED'
                  : _activeCameraAngle == 1
                  ? 'RED CORNER CAM'
                  : 'BLUE CORNER CAM',
              style: const TextStyle(
                color: Colors.white38,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          // Live Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.neonRed,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonRed.withValues(alpha: 0.5),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.sensors, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UFC 315: PEREIRA VS ANKALAEV',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(blurRadius: 4)],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Main Event - Round 2',
                  style: TextStyle(
                    color: DesignTokens.neonGold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Viewer count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: const Row(
              children: [
                Icon(Icons.remove_red_eye, color: AppTheme.neonCyan, size: 14),
                SizedBox(width: 4),
                Text(
                  '1.2M',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatsOverlay() {
    return Positioned(
      top: 100,
      left: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatBox('SIG. STRIKES', '34 - 12', AppTheme.neonCyan),
          const SizedBox(height: 8),
          _buildStatBox('TAKEDOWNS', '0 - 1', AppTheme.neonMagenta),
          const SizedBox(height: 8),
          _buildStatBox('CTRL TIME', '0:00 - 1:42', DesignTokens.neonGold),
        ],
      ),
    );
  }

  Widget _buildStatBox(String title, String value, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraAngleSelector() {
    return Positioned(
      right: 16,
      top: 100,
      child: Column(
        children: [
          _buildCamButton(0, 'MAIN', Icons.videocam),
          const SizedBox(height: 12),
          _buildCamButton(1, 'RED', Icons.camera_alt, color: AppTheme.neonRed),
          const SizedBox(height: 12),
          _buildCamButton(
            2,
            'BLUE',
            Icons.camera_alt,
            color: AppTheme.neonCyan,
          ),
        ],
      ),
    );
  }

  Widget _buildCamButton(
    int index,
    String label,
    IconData icon, {
    Color? color,
  }) {
    final isSelected = _activeCameraAngle == index;
    final activeColor = color ?? Colors.white;

    return GestureDetector(
      onTap: () => setState(() => _activeCameraAngle = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? activeColor.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.6),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : Colors.white54,
              size: 18,
            ),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : Colors.white54,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHypeMeter() {
    return Positioned(
      right: 16,
      bottom: 140,
      child: AnimatedBuilder(
        animation: _hypeController,
        builder: (context, child) {
          final scale = 1.0 + (_hypeController.value * 0.15);
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [AppTheme.neonRed, Colors.transparent],
                  stops: [0.3, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonRed.withValues(
                      alpha: 0.5 * _hypeController.value,
                    ),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 32,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomChatArea() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 250,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Chat Stream
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: _chatMessages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Text(
                          'User123: ',
                          style: TextStyle(
                            color: AppTheme.neonCyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _chatMessages[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Input Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatInputCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Join the hype...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (text) {
                        if (text.isNotEmpty) {
                          setState(() => _chatMessages.insert(0, text));
                          _chatInputCtrl.clear();
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppTheme.neonCyan),
                    onPressed: () {
                      if (_chatInputCtrl.text.isNotEmpty) {
                        setState(
                          () => _chatMessages.insert(0, _chatInputCtrl.text),
                        );
                        _chatInputCtrl.clear();
                      }
                    },
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
