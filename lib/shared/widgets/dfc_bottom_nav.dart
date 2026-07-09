import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../shared/services/enhanced_friends_service.dart';

/// Bottom navigation bar with 4 core tabs: Feed, PPV, Explore, Profile.
/// Neon glow top edge, frosted glass blur, pulsing active indicators.
class DFCBottomNav extends StatelessWidget {
  const DFCBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _baseItems = <_NavItem>[
    _NavItem(Icons.home_outlined, Icons.home, 'Home'),
    _NavItem(Icons.live_tv_outlined, Icons.live_tv, 'Watch'),
    _NavItem(Icons.explore_outlined, Icons.explore, 'Explore'),
    _NavItem(Icons.people_outline, Icons.people, 'Network'),
    _NavItem(Icons.person_outline, Icons.person, 'Profile'),
  ];

  // Dynamic items list based on user role (creator tab shown conditionally)
  List<_NavItem> get _items {
    final items = List<_NavItem>.from(_baseItems);
    // Conditionally add Creator tab if user is a creator
    // TODO(phase2b): Wire to user.isCreator after Firestore integration
    // For now, show Creator tab in dev builds only
    if (kDebugMode) {
      items.insert(
        4,
        const _NavItem(
          Icons.video_camera_outlined,
          Icons.video_camera,
          'Creator',
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final navContent = Container(
      decoration: BoxDecoration(
        color: kIsWeb
            ? AppTheme.primaryBackground
            : AppTheme.primaryBackground.withValues(alpha: 0.82),
        border: const Border(top: BorderSide(color: DesignTokens.neonCyan)),
        boxShadow: kIsWeb
            ? []
            : [
                BoxShadow(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        bottom: !kIsWeb,
        minimum: const EdgeInsets.only(top: kIsWeb ? 0 : 6),
        child: SizedBox(
          height: kIsWeb ? 84 : null,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == selectedIndex;
              final showBadge =
                  i == 3; // Social tab — show pending friend requests
              return Expanded(
                child: _NavTile(
                  item: item,
                  selected: selected,
                  showBadge: showBadge,
                  onTap: () => onDestinationSelected(i),
                ),
              );
            }),
          ),
        ),
      ),
    );

    // Skip BackdropFilter on web — it causes body content to vanish
    return kIsWeb
        ? navContent
        : ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: navContent,
            ),
          );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
    this.showBadge = false,
  }) : isPPV = false;

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final bool showBadge;
  final bool isPPV;

  @override
  Widget build(BuildContext context) {
    final color = selected ? DesignTokens.neonCyan : AppTheme.textMuted;
    final friendsService = Provider.of<EnhancedFriendsService>(
      context,
      listen: false,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          children: [
            Align(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pill highlight with neon glow when selected
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: selected
                          ? DesignTokens.neonCyan.withValues(alpha: 0.12)
                          : Colors.transparent,
                    ),
                    child: Icon(
                      selected ? item.activeIcon : item.icon,
                      size: 22,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Neon underline bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 2,
                    width: selected ? 20 : 0,
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      gradient: selected
                          ? const LinearGradient(
                              colors: [
                                DesignTokens.neonCyan,
                                DesignTokens.neonMagenta,
                              ],
                            )
                          : null,
                      boxShadow: const [],
                    ),
                  ),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                      color: color,
                      letterSpacing: 0.1,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            // Badge for pending friend requests
            if (showBadge)
              Positioned(
                top: 0,
                right: 8,
                child: StreamBuilder<int>(
                  stream: friendsService.streamPendingRequestCount(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: DesignTokens.neonRed,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          count > 9 ? '9+' : count.toString(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
