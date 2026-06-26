import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// BROADCAST OVERLAY SCREEN
/// A transparent web-view designed to be pulled into OBS/vMix as a browser source.
/// Displays live, real-time scorecard updates from the Officials Tablet.
/// ═══════════════════════════════════════════════════════════════════════════
class BroadcastOverlayScreen extends StatefulWidget {
  final String eventId;
  const BroadcastOverlayScreen({super.key, required this.eventId});

  @override
  State<BroadcastOverlayScreen> createState() => _BroadcastOverlayScreenState();
}

class _BroadcastOverlayScreenState extends State<BroadcastOverlayScreen> {
  final String _fighterAName = 'TORRES';
  final String _fighterBName = 'OKAFOR';

  VideoPlayerController? _videoController;
  bool _isVideoLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMuxStream();
  }

  Future<void> _initializeMuxStream() async {
    try {
      // 1. Query `ppvEvents` using widget.eventId to get the Mux streamUrl
      final eventDoc = await FirebaseFirestore.instance
          .collection('ppvEvents')
          .doc(widget.eventId)
          .get();
      final muxStreamUrl =
          eventDoc.data()?['streamUrl'] ??
          'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8'; // Fallback for testing

      // 2. Initialize the video player
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(muxStreamUrl))
            ..initialize().then((_) {
              if (mounted) setState(() => _isVideoLoading = false);
              _videoController?.setVolume(
                0.0,
              ); // Mute the local player for clean overlay capture
              _videoController?.play();
            });
    } catch (e) {
      debugPrint('Error initializing Mux Stream: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. MUX VIDEO LAYER (Background)
          Positioned.fill(
            child: const Center(
              child: Text(
                'MUX LIVE STREAM PLAYER (Awaiting video_player package)',
                style: TextStyle(color: Colors.white38, letterSpacing: 2),
              ),
            ),
          ),

          // 2. LIVE DATA OVERLAY (Foreground)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('judges_scores')
                    .where(
                      'fight_id',
                      isEqualTo: widget.eventId,
                    ) // Hooks directly to the URL route param
                    .snapshots(),
                builder: (context, snapshot) {
                  int totalScoreA = 0;
                  int totalScoreB = 0;
                  int roundsScored = 0;

                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    roundsScored = snapshot.data!.docs.length;
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      totalScoreA +=
                          (data['fighter_a_score'] as num?)?.toInt() ?? 0;
                      totalScoreB +=
                          (data['fighter_b_score'] as num?)?.toInt() ?? 0;
                    }
                  }

                  return _buildLowerThird(
                    totalScoreA,
                    totalScoreB,
                    roundsScored,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowerThird(int scoreA, int scoreB, int roundsScored) {
    return Container(
      height: 80,
      width: 700,
      decoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // DFC Branding Block
          Container(
            width: 100,
            decoration: const BoxDecoration(
              color: AppColors.neonCyan,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(10)),
            ),
            child: const Center(
              child: Text(
                'DFC',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),

          // Red Corner
          Expanded(
            child: Container(
              color: AppColors.neonRed.withValues(alpha: 0.15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Text(
                      _fighterAName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: Text(
                      scoreA > 0 ? scoreA.toString() : '-',
                      style: const TextStyle(
                        color: AppColors.neonRed,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center Round Indicator
          Container(
            width: 80,
            color: AppColors.panel,
            child: Center(
              child: Text(
                'R${roundsScored + 1}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Blue Corner
          Expanded(
            child: Container(
              color: AppColors.neonBlue.withValues(alpha: 0.15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Text(
                      scoreB > 0 ? scoreB.toString() : '-',
                      style: const TextStyle(
                        color: AppColors.neonBlue,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: Text(
                      _fighterBName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
