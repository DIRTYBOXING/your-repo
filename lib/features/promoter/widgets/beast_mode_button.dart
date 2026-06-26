import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/beast_mode_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// BEAST MODE BUTTON — Rapid Promotional Power Toggle
/// ═══════════════════════════════════════════════════════════════════════════
///
/// A visually striking button that activates Beast Mode for promotional campaigns.
/// Features:
///  • Animated glow effects when active
///  • Pulsing animations at higher intensities
///  • Real-time stats display
///  • Tap to cycle through intensities: OFF → TURBO → BEAST → NUCLEAR → OFF
///  • Long-press for quick Beast mode activation
///  • Visual intensity indicators
/// ═══════════════════════════════════════════════════════════════════════════

class BeastModeButton extends StatefulWidget {
  final bool showStats;
  final bool compact;

  const BeastModeButton({
    super.key,
    this.showStats = true,
    this.compact = false,
  });

  @override
  State<BeastModeButton> createState() => _BeastModeButtonState();
}

class _BeastModeButtonState extends State<BeastModeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final beastMode = context.watch<BeastModeService>();

    return widget.compact
        ? _buildCompactButton(beastMode)
        : _buildFullButton(beastMode);
  }

  Widget _buildCompactButton(BeastModeService beastMode) {
    final isActive = beastMode.isActive;
    final intensity = beastMode.intensity;

    return GestureDetector(
      onTap: () => beastMode.toggle(),
      onLongPress: () => beastMode.quickBeast(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? _getIntensityColor(intensity)
              : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? _getIntensityColor(intensity).withValues(alpha: 0.8)
                : AppTheme.neonCyan.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _getIntensityColor(intensity).withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(intensity.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              isActive ? intensity.label : 'BEAST MODE',
              style: TextStyle(
                color: isActive ? Colors.white : AppTheme.neonCyan,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                '${intensity.multiplier.toStringAsFixed(0)}x',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFullButton(BeastModeService beastMode) {
    final isActive = beastMode.isActive;
    final intensity = beastMode.intensity;
    final stats = beastMode.stats;

    return GestureDetector(
      onTap: () => beastMode.toggle(),
      onLongPress: () => _showBeastModeDialog(context, beastMode),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isActive ? _pulseAnimation.value : 1.0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        colors: [
                          _getIntensityColor(intensity),
                          _getIntensityColor(intensity).withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isActive ? null : AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isActive
                      ? _getIntensityColor(intensity).withValues(alpha: 0.8)
                      : AppTheme.neonCyan.withValues(alpha: 0.3),
                  width: 3,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: _getIntensityColor(
                            intensity,
                          ).withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppTheme.neonCyan.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Main Button ─────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        intensity.emoji,
                        style: TextStyle(fontSize: isActive ? 40 : 32),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BEAST MODE',
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : AppTheme.neonCyan,
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            isActive ? intensity.label : 'TAP TO ACTIVATE',
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : AppTheme.textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // ── Multiplier Display ──────────────────────────
                  if (isActive) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMultiplierChip(
                            'Content',
                            '${intensity.multiplier.toStringAsFixed(1)}x',
                          ),
                          _buildMultiplierChip(
                            'Reach',
                            '${beastMode.reachMultiplier.toStringAsFixed(1)}x',
                          ),
                          _buildMultiplierChip(
                            'Viral',
                            '+${(beastMode.viralPotentialBoost * 100).toStringAsFixed(0)}%',
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Stats Display ───────────────────────────────
                  if (widget.showStats && isActive) ...[
                    const SizedBox(height: 16),
                    _buildStatsRow(stats),
                  ],

                  // ── Instructions ────────────────────────────────
                  if (!isActive) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Tap to cycle • Long-press for quick Beast',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMultiplierChip(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BeastModeStats stats) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('🚀', '${stats.contentAmplified}', 'Amplified'),
          _buildStatItem('📣', '${stats.campaignsBoost}', 'Boosted'),
          _buildStatItem('⚡', _formatDuration(stats.activeDuration), 'Active'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getIntensityColor(BeastModeIntensity intensity) {
    switch (intensity) {
      case BeastModeIntensity.off:
        return AppTheme.cardBackground;
      case BeastModeIntensity.turbo:
        return AppTheme.neonCyan;
      case BeastModeIntensity.beast:
        return AppTheme.neonOrange;
      case BeastModeIntensity.nuclear:
        return const Color(0xFFFF0044); // Hot red
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final mins = d.inMinutes.remainder(60);
    final secs = d.inSeconds.remainder(60);
    if (hours > 0) return '${hours}h ${mins}m';
    if (mins > 0) return '${mins}m ${secs}s';
    return '${secs}s';
  }

  void _showBeastModeDialog(BuildContext context, BeastModeService beastMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Text('🔥', style: TextStyle(fontSize: 32)),
            SizedBox(width: 12),
            Text(
              'BEAST MODE',
              style: TextStyle(
                color: AppTheme.neonOrange,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select intensity level:',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...[
              BeastModeIntensity.turbo,
              BeastModeIntensity.beast,
              BeastModeIntensity.nuclear,
            ].map(
              (intensity) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _getIntensityColor(
                        intensity,
                      ).withValues(alpha: 0.5),
                    ),
                  ),
                  leading: Text(
                    intensity.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(
                    intensity.label,
                    style: TextStyle(
                      color: _getIntensityColor(intensity),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    '${intensity.multiplier}x multiplier',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  onTap: () {
                    beastMode.activate(intensity);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          if (beastMode.isActive)
            TextButton(
              onPressed: () {
                beastMode.deactivate();
                Navigator.pop(context);
              },
              child: const Text(
                'Deactivate',
                style: TextStyle(color: AppTheme.neonOrange),
              ),
            ),
        ],
      ),
    );
  }
}
