import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';

class DFCStatePanel extends StatelessWidget {
  const DFCStatePanel({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.accent,
    this.actionLabel,
    this.onAction,
  });

  const DFCStatePanel.loading({
    super.key,
    this.title = 'Loading',
    this.message = 'Preparing this view...',
    this.actionLabel,
    this.onAction,
  }) : icon = Icons.hourglass_top_rounded,
       accent = DesignTokens.neonCyan,
       assert(actionLabel == null),
       assert(onAction == null);

  const DFCStatePanel.empty({
    super.key,
    this.title = 'Nothing here yet',
    this.message = 'This area is ready for content when data arrives.',
    this.actionLabel,
    this.onAction,
  }) : icon = Icons.inbox_outlined,
       accent = DesignTokens.neonMagenta,
       assert(actionLabel == null),
       assert(onAction == null);

  const DFCStatePanel.error({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    VoidCallback? onRetry,
  }) : icon = Icons.error_outline_rounded,
       accent = DesignTokens.neonRed,
       actionLabel = onRetry == null ? null : 'Try again',
       onAction = onRetry;

  final String title;
  final String message;
  final IconData icon;
  final Color accent;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DesignTokens.bgOverlay.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
