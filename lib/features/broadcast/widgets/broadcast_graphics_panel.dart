import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../models/broadcast_control_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// BROADCAST GRAPHICS PANEL — On-Screen Graphics Controls
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Director controls for graphics overlays:
///   - Round banners
///   - Fighter nameplates
///   - Stats bursts
///   - Lower thirds
///   - Replay graphics
///   - Commentary credits
///   - Graphics alpha/fade
///
/// ═══════════════════════════════════════════════════════════════════════════

class BroadcastGraphicsPanel extends StatefulWidget {
  final GraphicsState graphicsState;
  final void Function(GraphicsState) onGraphicsUpdate;

  const BroadcastGraphicsPanel({
    super.key,
    required this.graphicsState,
    required this.onGraphicsUpdate,
  });

  @override
  State<BroadcastGraphicsPanel> createState() => _BroadcastGraphicsPanelState();
}

class _BroadcastGraphicsPanelState extends State<BroadcastGraphicsPanel> {
  late TextEditingController _lowerThirdController;

  @override
  void initState() {
    super.initState();
    _lowerThirdController = TextEditingController(
      text: widget.graphicsState.lowerThirdText,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        border: Border.all(
          color: DesignTokens.neonGreen.withOpacity(0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GRAPHICS OVERLAY',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),

          // ── Graphics Toggle Grid ──
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildGraphicsToggle(
                icon: Icons.looks_3,
                label: 'Round Banner',
                value: widget.graphicsState.showRoundBanner,
                onChanged: (value) {
                  onGraphicsToggle(showRoundBanner: value);
                },
              ),
              _buildGraphicsToggle(
                icon: Icons.bar_chart,
                label: 'Stats Banner',
                value: widget.graphicsState.showStatsBanner,
                onChanged: (value) {
                  onGraphicsToggle(showStatsBanner: value);
                },
              ),
              _buildGraphicsToggle(
                icon: Icons.replay,
                label: 'Replay Graphics',
                value: widget.graphicsState.showReplayGraphics,
                onChanged: (value) {
                  onGraphicsToggle(showReplayGraphics: value);
                },
              ),
              _buildGraphicsToggle(
                icon: Icons.text_fields,
                label: 'Lower Third',
                value: widget.graphicsState.showLowerThird,
                onChanged: (value) {
                  onGraphicsToggle(showLowerThird: value);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Lower Third Text Input ──
          if (widget.graphicsState.showLowerThird)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lower Third Text',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _lowerThirdController,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'e.g., "SUBMISSION" or "KNOCKOUT"',
                    hintStyle: TextStyle(color: Colors.white30, fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.white20, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: DesignTokens.neonGreen,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white05,
                  ),
                  onChanged: (value) {
                    onGraphicsToggle(lowerThirdText: value);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),

          // ── Graphics Alpha Control ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Graphics Opacity',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.neonGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${(widget.graphicsState.graphicsAlpha * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: DesignTokens.neonGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 12,
                  ),
                ),
                child: Slider(
                  value: widget.graphicsState.graphicsAlpha,
                  onChanged: (value) {
                    onGraphicsToggle(graphicsAlpha: value);
                  },
                  min: 0.0,
                  max: 1.0,
                  activeColor: DesignTokens.neonGreen,
                  inactiveColor: Colors.white20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGraphicsToggle({
    required IconData icon,
    required String label,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        decoration: BoxDecoration(
          color: value
              ? DesignTokens.neonGreen.withOpacity(0.15)
              : Colors.white05,
          border: Border.all(
            color: value
                ? DesignTokens.neonGreen.withOpacity(0.5)
                : Colors.white20,
            width: value ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: value ? DesignTokens.neonGreen : Colors.white40,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: value ? DesignTokens.neonGreen : Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            if (value)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: DesignTokens.neonGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'ON',
                  style: TextStyle(
                    color: DesignTokens.neonGreen,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void onGraphicsToggle({
    bool? showRoundBanner,
    bool? showStatsBanner,
    bool? showReplayGraphics,
    bool? showLowerThird,
    String? lowerThirdText,
    double? graphicsAlpha,
  }) {
    final updated = widget.graphicsState.copyWith(
      showRoundBanner: showRoundBanner ?? widget.graphicsState.showRoundBanner,
      showStatsBanner: showStatsBanner ?? widget.graphicsState.showStatsBanner,
      showReplayGraphics:
          showReplayGraphics ?? widget.graphicsState.showReplayGraphics,
      showLowerThird: showLowerThird ?? widget.graphicsState.showLowerThird,
      lowerThirdText: lowerThirdText ?? widget.graphicsState.lowerThirdText,
      graphicsAlpha: graphicsAlpha ?? widget.graphicsState.graphicsAlpha,
    );

    widget.onGraphicsUpdate(updated);
  }

  @override
  void dispose() {
    _lowerThirdController.dispose();
    super.dispose();
  }
}
