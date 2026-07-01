import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import 'dfc_search_bar.dart';

enum DFCShellOverflowAction { messaging, friendRequests, dashboard }

class DFCHomeShellTopBar extends StatelessWidget {
  const DFCHomeShellTopBar({
    super.key,
    required this.onOpenMessaging,
    required this.onOpenFriendRequests,
    required this.onOpenDashboard,
    required this.onOpenAccountMenu,
    required this.inboxBadgeStream,
    required this.friendRequestBadgeStream,
  });

  final VoidCallback onOpenMessaging;
  final VoidCallback onOpenFriendRequests;
  final VoidCallback onOpenDashboard;
  final VoidCallback onOpenAccountMenu;
  final Stream<int> inboxBadgeStream;
  final Stream<int> friendRequestBadgeStream;

  @override
  Widget build(BuildContext context) {
    final useShellV2 = AppConstants.featureShellV2;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final useOverflow = maxWidth < 350;
        final compactAccount = maxWidth < 300;
        final searchWidth = math.max(
          120.0,
          math.min(
            useOverflow ? 176.0 : 248.0,
            maxWidth - (useOverflow ? 104 : 196),
          ),
        );

        return Semantics(
          label: 'Home shell top bar',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: searchWidth),
                child: DFCSearchBar(
                  expandedWidth: searchWidth,
                  showFilters: !useOverflow,
                ),
              ),
              const SizedBox(width: 8),
              if (useOverflow)
                _OverflowMenu(
                  onSelected: (action) {
                    switch (action) {
                      case DFCShellOverflowAction.messaging:
                        onOpenMessaging();
                        break;
                      case DFCShellOverflowAction.friendRequests:
                        onOpenFriendRequests();
                        break;
                      case DFCShellOverflowAction.dashboard:
                        onOpenDashboard();
                        break;
                    }
                  },
                )
              else ...[
                DFCTopBarIcon(
                  icon: Icons.mail_outline,
                  iconColor: useShellV2
                      ? DesignTokens.shellTextMuted
                      : AppTheme.neonCyan,
                  borderColor: useShellV2 ? DesignTokens.shellBorder : null,
                  tooltip: 'Open inbox',
                  onTap: onOpenMessaging,
                  badgeStream: inboxBadgeStream,
                ),
                const SizedBox(width: 8),
                DFCTopBarIcon(
                  icon: Icons.person_add_alt_1_outlined,
                  iconColor: useShellV2
                      ? DesignTokens.shellTextMuted
                      : AppTheme.neonCyan,
                  borderColor: useShellV2 ? DesignTokens.shellBorder : null,
                  tooltip: 'Open friend requests',
                  onTap: onOpenFriendRequests,
                  badgeStream: friendRequestBadgeStream,
                ),
                const SizedBox(width: 8),
                DFCTopBarIcon(
                  icon: Icons.dashboard_rounded,
                  iconColor: useShellV2
                      ? DesignTokens.ppvAccent
                      : AppTheme.neonGreen,
                  borderColor: useShellV2
                      ? DesignTokens.shellBorder
                      : AppTheme.neonGreen.withValues(alpha: 0.3),
                  tooltip: 'Open command dashboard',
                  onTap: onOpenDashboard,
                ),
                const SizedBox(width: 8),
              ],
              _AccountButton(compact: compactAccount, onTap: onOpenAccountMenu),
            ],
          ),
        );
      },
    );
  }
}

class DFCTopBarIcon extends StatelessWidget {
  const DFCTopBarIcon({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.iconColor = AppTheme.neonCyan,
    this.borderColor,
    this.badgeStream,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color iconColor;
  final Color? borderColor;
  final Stream<int>? badgeStream;

  @override
  Widget build(BuildContext context) {
    final useShellV2 = AppConstants.featureShellV2;
    final effectiveIconColor = useShellV2
        ? iconColor
        : iconColor.withValues(alpha: 0.8);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: useShellV2
                    ? DesignTokens.shellSurfaceRaised.withValues(alpha: 0.96)
                    : DesignTokens.bgOverlay.withValues(alpha: 0.9),
                border: Border.all(
                  color: useShellV2
                      ? (borderColor ?? DesignTokens.shellBorder)
                      : borderColor ?? iconColor.withValues(alpha: 0.3),
                ),
              ),
              child: badgeStream == null
                  ? Icon(icon, color: effectiveIconColor, size: 20)
                  : StreamBuilder<int>(
                      stream: badgeStream,
                      builder: (ctx, snap) {
                        final count = snap.data ?? 0;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(icon, color: effectiveIconColor, size: 20),
                            if (count > 0)
                              Positioned(
                                top: -6,
                                right: -8,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: DesignTokens.neonRed,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    count > 9 ? '9+' : '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({required this.onSelected});

  final ValueChanged<DFCShellOverflowAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final useShellV2 = AppConstants.featureShellV2;
    return PopupMenuButton<DFCShellOverflowAction>(
      tooltip: 'More actions',
      color: useShellV2
          ? DesignTokens.shellSurfaceRaised
          : DesignTokens.bgOverlay,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: useShellV2
              ? DesignTokens.shellSurfaceRaised.withValues(alpha: 0.96)
              : DesignTokens.bgOverlay.withValues(alpha: 0.9),
          border: Border.all(
            color: useShellV2
                ? DesignTokens.shellBorder
                : AppTheme.neonCyan.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(
          Icons.more_horiz_rounded,
          color: useShellV2
              ? DesignTokens.shellTextMuted
              : AppTheme.neonCyan.withValues(alpha: 0.8),
          size: 20,
        ),
      ),
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: DFCShellOverflowAction.messaging,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.mail_outline),
            title: Text('Inbox'),
          ),
        ),
        PopupMenuItem(
          value: DFCShellOverflowAction.friendRequests,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.person_add_alt_1_outlined),
            title: Text('Friend requests'),
          ),
        ),
        PopupMenuItem(
          value: DFCShellOverflowAction.dashboard,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.dashboard_rounded),
            title: Text('Dashboard'),
          ),
        ),
      ],
    );
  }
}

class _AccountButton extends StatelessWidget {
  const _AccountButton({required this.compact, required this.onTap});

  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final useShellV2 = AppConstants.featureShellV2;
    return Tooltip(
      message: 'Open account menu',
      child: Semantics(
        button: true,
        label: 'Open account menu',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: useShellV2
                    ? DesignTokens.shellSurfaceRaised.withValues(alpha: 0.96)
                    : DesignTokens.bgOverlay.withValues(alpha: 0.9),
                border: Border.all(
                  color: useShellV2
                      ? DesignTokens.shellBorder
                      : AppTheme.neonCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_circle,
                    color: useShellV2
                        ? DesignTokens.shellTextMuted
                        : AppTheme.neonCyan.withValues(alpha: 0.8),
                    size: 20,
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.expand_more,
                      color: useShellV2
                          ? DesignTokens.shellTextSubtle
                          : Colors.white54,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
