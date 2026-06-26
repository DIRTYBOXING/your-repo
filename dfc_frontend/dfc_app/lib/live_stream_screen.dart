import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/dfc_player.dart';
import '../widgets/live_chat_overlay.dart';
import '../widgets/live_stats_overlay.dart';

class LiveStreamScreen extends StatefulWidget {
  final String streamId;

  const LiveStreamScreen({super.key, required this.streamId});

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  @override
  void initState() {
    super.initState();
    // Force Landscape for Cinematic View
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Revert to Portrait
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. The Immersive Player
          Positioned.fill(child: DfcPlayer(streamUrl: widget.streamId)),

          // 2. Chat Overlay (Right Side)
          const Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            child: LiveChatOverlay(),
          ),

          // 3. Stats Overlay (Bottom Left)
          const Positioned(bottom: 24, left: 24, child: LiveStatsOverlay()),

          // 4. Back Button
          Positioned(
            top: 24,
            left: 24,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Colors.white, size: 32),
            ),
          ),
        ],
      ),
    );
  }
}
