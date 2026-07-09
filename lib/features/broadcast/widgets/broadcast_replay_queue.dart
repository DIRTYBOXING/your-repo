import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../models/broadcast_control_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// BROADCAST REPLAY QUEUE — Instant Replay Management
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Manages replay markers with:
///   - Auto-captured replays (knockdowns, submissions)
///   - Manual replay markers
///   - Playback controls (speed, trim)
///   - Queue visualization
///   - Multi-clip replay sequences
///
/// ═══════════════════════════════════════════════════════════════════════════

class BroadcastReplayQueue extends StatelessWidget {
  final List<ReplayMarker> markers;
  final VoidCallback onPlayReplay;

  const BroadcastReplayQueue({
    super.key,
    required this.markers,
    required this.onPlayReplay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        border: Border.all(
          color: DesignTokens.neonAmber.withOpacity(0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INSTANT REPLAYS',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${markers.length} replay${markers.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: DesignTokens.neonAmber,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (markers.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: onPlayReplay,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('PLAY NEXT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.neonAmber.withOpacity(0.2),
                    foregroundColor: DesignTokens.neonAmber,
                    side: BorderSide(
                      color: DesignTokens.neonAmber.withOpacity(0.5),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (markers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No replays yet. Knockdowns & submissions will be captured.',
                  style: TextStyle(color: Colors.white30, fontSize: 12),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: markers.length,
              itemBuilder: (context, index) {
                final marker = markers[index];
                return _ReplayMarkerTile(marker: marker, index: index);
              },
            ),
        ],
      ),
    );
  }
}

/// Individual replay marker tile
class _ReplayMarkerTile extends StatelessWidget {
  final ReplayMarker marker;
  final int index;

  const _ReplayMarkerTile({required this.marker, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white05,
        border: Border.all(color: _getEventColor().withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // ── Event Icon ──
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getEventColor().withOpacity(0.2),
              border: Border.all(
                color: _getEventColor().withOpacity(0.5),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Icon(_getEventIcon(), color: _getEventColor(), size: 16),
            ),
          ),
          const SizedBox(width: 12),

          // ── Event Details ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getEventLabel(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${marker.durationSeconds}s',
                      style: TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  marker.description,
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${marker.startTimeSeconds}s',
                      style: TextStyle(color: Colors.white30, fontSize: 9),
                    ),
                    if (marker.fighterIndex != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'Fighter ${marker.fighterIndex! + 1}',
                            style: TextStyle(
                              color: Colors.white40,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (marker.playbackSpeed != 1.0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.neonCyan.withOpacity(0.2),
                          border: Border.all(
                            color: DesignTokens.neonCyan.withOpacity(0.5),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '${marker.playbackSpeed}x SPEED',
                          style: TextStyle(
                            color: DesignTokens.neonCyan,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── Status Badge ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: marker.hasBeenReplayed
                  ? Colors.white10
                  : DesignTokens.neonGreen.withOpacity(0.2),
              border: Border.all(
                color: marker.hasBeenReplayed
                    ? Colors.white20
                    : DesignTokens.neonGreen.withOpacity(0.5),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              marker.hasBeenReplayed ? '✓ PLAYED' : '● QUEUED',
              style: TextStyle(
                color: marker.hasBeenReplayed
                    ? Colors.white60
                    : DesignTokens.neonGreen,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getEventLabel() {
    switch (marker.eventType) {
      case 'knockdown':
        return '💥 KNOCKDOWN';
      case 'submission':
        return '🔐 SUBMISSION';
      case 'roundEnd':
        return '🔔 ROUND END';
      default:
        return marker.eventType.toUpperCase();
    }
  }

  IconData _getEventIcon() {
    switch (marker.eventType) {
      case 'knockdown':
        return Icons.bolt;
      case 'submission':
        return Icons.handshake;
      case 'roundEnd':
        return Icons.schedule;
      default:
        return Icons.info;
    }
  }

  Color _getEventColor() {
    switch (marker.eventType) {
      case 'knockdown':
        return DesignTokens.neonRed;
      case 'submission':
        return DesignTokens.neonGreen;
      case 'roundEnd':
        return DesignTokens.neonAmber;
      default:
        return DesignTokens.neonCyan;
    }
  }
}
