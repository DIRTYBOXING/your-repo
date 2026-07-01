import 'package:flutter/material.dart';
import '../../../../dfc_theme.dart';

/// V12 Core Player Wrapper
/// In production, this wraps `video_player` or `better_player` for Mux streaming.
class DfcPlayer extends StatelessWidget {
  final String streamUrl;
  final bool isLive;

  const DfcPlayer({super.key, required this.streamUrl, this.isLive = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Simulated Video Feed
          Image.network(
            'https://images.unsplash.com/photo-1517438476312-10d79c077509?auto=format&fit=crop&q=80&w=1200',
            fit: BoxFit.cover,
          ),
          // Gradient Vignette
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                radius: 1.5,
              ),
            ),
          ),
          // LIVE Badge
          if (isLive)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentRed,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [BoxShadow(color: AppColors.accentRed.withValues(alpha: 0.5), blurRadius: 10)],
                ),
                child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
              ),
            ),
        ],
      ),
    );
  }
}