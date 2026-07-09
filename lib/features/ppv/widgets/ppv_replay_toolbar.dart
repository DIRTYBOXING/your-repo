import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/ppv_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV REPLAY TOOLBAR — SOCIAL ENGINE
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Bottom toolbar with:
/// - Replay 10s button
/// - Clip moment button
/// - Share to social (Discord, Twitter, TikTok)
/// - Timeline markers
/// - Highlight creation
///
/// ═══════════════════════════════════════════════════════════════════════════

class PPVReplayToolbar extends StatefulWidget {
  final PPVEvent? event;
  final ValueNotifier<int> currentRound;
  final VoidCallback onClipCreated;

  const PPVReplayToolbar({
    super.key,
    this.event,
    required this.currentRound,
    required this.onClipCreated,
  });

  @override
  State<PPVReplayToolbar> createState() => _PPVReplayToolbarState();
}

class _PPVReplayToolbarState extends State<PPVReplayToolbar> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: BackdropFilter(
        filter: const ColorFilter.mode(Colors.black45, BlendMode.srcOver),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            border: Border(
              top: BorderSide(
                color: DesignTokens.neonCyan.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Action Buttons Row ──
                Row(
                  children: [
                    // Replay 10s
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.replay_10,
                        label: 'Replay 10s',
                        onTap: () {
                          // TODO: Implement replay 10s seek
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⏪ Replaying last 10 seconds...'),
                              duration: Duration(milliseconds: 800),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Clip Moment
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.bookmark_add,
                        label: 'Clip Moment',
                        onTap: () {
                          widget.onClipCreated();
                          // TODO: Implement clip creation
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Share
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.share,
                        label: 'Share',
                        onTap: _shareClip,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Timeline Markers ──
                if (widget.event != null && widget.event!.fightCard.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        widget.event!.fightCard.first.rounds,
                        (index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ValueListenableBuilder<int>(
                              valueListenable: widget.currentRound,
                              builder: (context, round, _) {
                                final isActive = round == (index + 1);
                                return GestureDetector(
                                  onTap: () {
                                    // Jump to round
                                    widget.currentRound.value = index + 1;
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isActive
                                          ? DesignTokens.neonCyan.withValues(
                                              alpha: 0.3,
                                            )
                                          : Colors.white.withValues(alpha: 0.1),
                                      border: Border.all(
                                        color: isActive
                                            ? DesignTokens.neonCyan
                                            : Colors.white.withValues(
                                                alpha: 0.2,
                                              ),
                                        width: isActive ? 2 : 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: isActive
                                              ? DesignTokens.neonCyan
                                              : Colors.white.withValues(
                                                  alpha: 0.5,
                                                ),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: DesignTokens.neonCyan, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareClip() {
    if (widget.event == null) return;

    final text =
        'Check out Round ${widget.currentRound.value} of ${widget.event!.title} on DFC! #Combat #PPV #DFC';

    Share.share(text, subject: '${widget.event!.title} - Amazing moment!');
  }
}
