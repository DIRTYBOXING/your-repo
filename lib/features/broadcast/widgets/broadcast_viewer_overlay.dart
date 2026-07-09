import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../models/broadcast_control_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// BROADCAST VIEWER OVERLAY — Graphics & Commentary Layer
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Professional graphics overlay for PPV viewer:
///   - Round banners (with fighter names & round number)
///   - Fighter stats bursts
///   - Lower thirds (commentary, commentary credits)
///   - Replay graphics badge
///   - Live indicator
///   - Smooth fade transitions
///
/// Rendered on top of the video player to show professional broadcast graphics.
///
/// ═══════════════════════════════════════════════════════════════════════════

class BroadcastViewerOverlay extends StatelessWidget {
  /// Graphics state to display
  final GraphicsState graphicsState;

  /// Broadcast mode (live, replay, etc.)
  final BroadcastMode broadcastMode;

  /// Fighter names (optional)
  final String? fighter1Name;
  final String? fighter2Name;

  /// Opacity (0.0 - 1.0)
  final double opacity;

  const BroadcastViewerOverlay({
    super.key,
    required this.graphicsState,
    required this.broadcastMode,
    this.fighter1Name,
    this.fighter2Name,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity * graphicsState.graphicsAlpha,
      child: Stack(
        children: [
          // ── Live/Replay Indicator (Top Right) ──
          Positioned(top: 12, right: 12, child: _buildLiveIndicator()),

          // ── Round Banner (Top Center) ──
          if (graphicsState.showRoundBanner)
            Positioned(top: 24, left: 0, right: 0, child: _buildRoundBanner()),

          // ── Stats Banner (Below Round) ──
          if (graphicsState.showStatsBanner)
            Positioned(top: 100, left: 0, right: 0, child: _buildStatsBanner()),

          // ── Lower Third (Bottom) ──
          if (graphicsState.showLowerThird)
            Positioned(bottom: 0, left: 0, right: 0, child: _buildLowerThird()),

          // ── Replay Graphics Badge (Bottom Right) ──
          if (graphicsState.showReplayGraphics &&
              broadcastMode == BroadcastMode.replay)
            Positioned(bottom: 12, right: 12, child: _buildReplayBadge()),
        ],
      ),
    );
  }

  Widget _buildLiveIndicator() {
    final isLive = broadcastMode == BroadcastMode.live;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isLive ? DesignTokens.neonRed : DesignTokens.neonAmber,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isLive ? '🔴 LIVE' : '▶️ REPLAY',
          style: TextStyle(
            color: isLive ? DesignTokens.neonRed : DesignTokens.neonAmber,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRoundBanner() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          border: Border.all(color: DesignTokens.neonCyan, width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.neonCyan.withOpacity(0.3),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          children: [
            Text(
              'ROUND ${graphicsState.roundNumber}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            if (fighter1Name != null && fighter2Name != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      fighter1Name!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: DesignTokens.neonGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'vs',
                      style: TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      fighter2Name!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: DesignTokens.neonAmber,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBanner() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          border: Border.all(
            color: DesignTokens.neonGreen.withOpacity(0.5),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📊', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              'STATS',
              style: TextStyle(
                color: DesignTokens.neonGreen,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowerThird() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        border: Border(
          top: BorderSide(
            color: DesignTokens.neonCyan.withOpacity(0.5),
            width: 2,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        graphicsState.lowerThirdText,
        style: TextStyle(
          color: DesignTokens.neonCyan,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildReplayBadge() {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.neonAmber.withOpacity(0.2),
        border: Border.all(color: DesignTokens.neonAmber, width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.neonAmber.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Text('⏱️', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(
            'INSTANT REPLAY',
            style: TextStyle(
              color: DesignTokens.neonAmber,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
