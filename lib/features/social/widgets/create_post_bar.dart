import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/glass_panel.dart';
import '../../../core/theme/glow_effects.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/widgets/dfc_network_image.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CREATE POST BAR — Facebook-style "What's on your mind?" composer trigger
///
/// • User avatar on the left
/// • Tappable "Share a thought..." pill opens compose screen
/// • Quick-action row: Live · Photo/Video · Reel
/// • Card-based with subtle neon border / glow
/// ═══════════════════════════════════════════════════════════════════════════
class CreatePostBar extends StatelessWidget {
  final Future<void> Function()? onPostCreated;

  const CreatePostBar({super.key, this.onPostCreated});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.userModel;
    final photoUrl = user?.photoUrl;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: GlassPanel(
      padding: const EdgeInsets.all(12),
      backgroundColor: DesignTokens.bgCard.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
      borderColor: DesignTokens.neonCyan.withValues(alpha: 0.18),
      borderWidth: DesignTokens.borderThin,
      shadows: NeonGlow.softCyan(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar + "Share a thought..." pill
          Row(
            children: [
              // User avatar
              DfcCircleAvatar(
                imageUrl: photoUrl,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                borderColor: DesignTokens.neonCyan.withValues(alpha: 0.25),
                borderWidth: 1,
                fallbackIconColor: Colors.white.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 10),
              // Tappable pill
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final posted = await context.push<bool>('/compose-post');
                    if (posted == true) {
                      await onPostCreated?.call();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 0.5,
                      ),
                    ),
                    child: const Text(
                      'Share a thought...',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Divider
          Container(height: 0.5, color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 8),
          // Quick-action row: Live · Photo/Video · Reel
          Row(
            children: [
              _QuickAction(
                icon: Icons.videocam_rounded,
                label: 'Live',
                color: const Color(0xFFFF3366),
                onTap: () async {
                  final posted = await context.push<bool>('/compose-post');
                  if (posted == true) {
                    await onPostCreated?.call();
                  }
                },
              ),
              _divider(),
              _QuickAction(
                icon: Icons.photo_library_rounded,
                label: 'Photo/Video',
                color: const Color(0xFF00FF88),
                onTap: () async {
                  final posted = await context.push<bool>('/compose-post');
                  if (posted == true) {
                    await onPostCreated?.call();
                  }
                },
              ),
              _divider(),
              _QuickAction(
                icon: Icons.slow_motion_video_rounded,
                label: 'Reel',
                color: const Color(0xFFFFB800),
                onTap: () => context.push('/upload-clip'),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  static Widget _divider() {
    return Container(
      width: 0.5,
      height: 24,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
