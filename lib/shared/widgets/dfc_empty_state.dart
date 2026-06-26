import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC EMPTY STATE — Gentle illustration for zero-data screens
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Usage:
///   DFCEmptyState(
///     icon: Icons.campaign_outlined,
///     title: 'No Campaigns Yet',
///     subtitle: 'Create your first campaign to get started.',
///     actionLabel: 'Create Campaign',
///     onAction: () => ...,
///   )
/// ═══════════════════════════════════════════════════════════════════════════

class DFCEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color accent;

  const DFCEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.accent = AppTheme.neonCyan,
  });

  // ── Presets ──

  /// No posts / feed items
  factory DFCEmptyState.noPosts({VoidCallback? onAction}) => DFCEmptyState(
    icon: Icons.article_outlined,
    title: 'No Posts Yet',
    subtitle: 'Be the first to share something with the community.',
    actionLabel: onAction != null ? 'Create Post' : null,
    onAction: onAction,
  );

  /// No campaigns
  factory DFCEmptyState.noCampaigns({VoidCallback? onAction}) => DFCEmptyState(
    icon: Icons.campaign_outlined,
    title: 'No Campaigns',
    subtitle: 'Launch a campaign to reach your audience.',
    actionLabel: onAction != null ? 'New Campaign' : null,
    onAction: onAction,
    accent: AppTheme.neonOrange,
  );

  /// No events
  factory DFCEmptyState.noEvents({VoidCallback? onAction}) => DFCEmptyState(
    icon: Icons.event_outlined,
    title: 'No Events',
    subtitle: 'Upcoming fight events will appear here.',
    actionLabel: onAction != null ? 'Browse Events' : null,
    onAction: onAction,
    accent: AppTheme.neonMagenta,
  );

  /// No data / generic
  factory DFCEmptyState.noData({String? message}) => DFCEmptyState(
    icon: Icons.inbox_outlined,
    title: 'Nothing Here',
    subtitle: message ?? 'Data will appear once available.',
  );

  /// No search results
  factory DFCEmptyState.noResults() => const DFCEmptyState(
    icon: Icons.search_off,
    title: 'No Results',
    subtitle: 'Try adjusting your search or filters.',
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingXXL,
          vertical: DesignTokens.spacingXXL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with subtle glow ring
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.06),
                border: Border.all(
                  color: accent.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, color: accent.withValues(alpha: 0.6), size: 36),
            ),
            const SizedBox(height: DesignTokens.spacingXL),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: DesignTokens.spacingS),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
            ],

            // Action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DesignTokens.spacingXXL),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel!),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusSmall,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC ERROR STATE — For StreamBuilder / FutureBuilder error snapshots
/// ═══════════════════════════════════════════════════════════════════════════
class DFCErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const DFCErrorState({
    super.key,
    this.message = 'Something went wrong',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: AppTheme.error.withValues(alpha: 0.7),
              size: 48,
            ),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              message,
              style: TextStyle(
                color: AppTheme.textMuted.withValues(alpha: 0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: DesignTokens.spacingL),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.neonCyan,
                  side: BorderSide(
                    color: AppTheme.neonCyan.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC LOADING STATE — Consistent loading spinner
/// ═══════════════════════════════════════════════════════════════════════════
class DFCLoadingState extends StatelessWidget {
  final String? message;

  const DFCLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppTheme.neonCyan),
          if (message != null) ...[
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              message!,
              style: TextStyle(
                color: AppTheme.textMuted.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
