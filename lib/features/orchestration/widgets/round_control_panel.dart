import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../models/event_session_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ROUND CONTROL PANEL — Round Advancement & Fight Control
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Interactive control for:
///   - Advancing rounds
///   - Controlling fight timer
///   - Recording special events
///   - Ending the fight
///
/// ═══════════════════════════════════════════════════════════════════════════

class RoundControlPanel extends StatelessWidget {
  /// Current fight session
  final FightSession fight;

  /// Callback to advance round
  final VoidCallback onAdvanceRound;

  /// Callback to end fight
  final VoidCallback onEndFight;

  const RoundControlPanel({
    super.key,
    required this.fight,
    required this.onAdvanceRound,
    required this.onEndFight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        border: Border.all(
          color: DesignTokens.neonAmber.withOpacity(0.4),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ROUND CONTROL',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),

          // ── Round Display ──
          Center(
            child: Column(
              children: [
                Text(
                  'Round ${fight.currentRound}',
                  style: TextStyle(
                    color: DesignTokens.neonAmber,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    '${fight.roundTimeRemaining} seconds remaining',
                    style: TextStyle(
                      color: fight.isRoundActive
                          ? DesignTokens.neonGreen
                          : Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Control Buttons ──
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildControlButton(
                label: 'Advance Round',
                icon: Icons.arrow_forward,
                color: DesignTokens.neonGreen,
                onPressed: onAdvanceRound,
              ),
              _buildControlButton(
                label: 'End Fight',
                icon: Icons.stop_circle,
                color: DesignTokens.neonRed,
                onPressed: onEndFight,
              ),
              _buildControlButton(
                label: 'Knockdown',
                icon: Icons.blur_on,
                color: DesignTokens.neonCyan,
                onPressed: () {
                  // TODO: Open knockdown dialog
                },
              ),
              _buildControlButton(
                label: 'Submission',
                icon: Icons.handshake,
                color: DesignTokens.neonAmber,
                onPressed: () {
                  // TODO: Open submission dialog
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        side: BorderSide(color: color, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.all(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
