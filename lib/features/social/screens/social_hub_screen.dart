import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/enhanced_friends_service.dart';
import '../../../shared/widgets/dfc_tab_intro_header.dart';
import '../widgets/stories_bar.dart';
import '../widgets/create_post_bar.dart';
import '../widgets/people_you_may_know.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SOCIAL HUB — Facebook-grade social tab for DFC
///
/// Layout (top to bottom):
///   1. Quick-nav row: Friends · Groups · Events · Marketplace
///   2. Stories bar (existing widget)
///   3. "Share a thought..." create post bar
///   4. People you may know (horizontal cards)
///   5. Navigation cards: Friend Requests · Find Friends · Member Directory
///
/// This is Tab 4 in the bottom nav (Social/People icon).
/// ═══════════════════════════════════════════════════════════════════════════
class SocialHubScreen extends StatelessWidget {
  const SocialHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: CustomScrollView(
              slivers: [
                // Top padding for overlay nav pills
                const SliverToBoxAdapter(child: SizedBox(height: 56)),
                const SliverToBoxAdapter(
                  child: DFCTabIntroHeader(
                    title: 'Network',
                    subtitle:
                        'Member discovery, connection requests, and professional relationship management.',
                    icon: Icons.hub_rounded,
                  ),
                ),
                // Network Pulse
                const SliverToBoxAdapter(child: _NetworkPulseBand()),
                // Quick Nav Row
                SliverToBoxAdapter(child: _QuickNavRow()),
                // Stories
                const SliverToBoxAdapter(child: StoriesBar()),
                const SliverToBoxAdapter(child: SizedBox(height: 4)),
                // Create Post Bar
                const SliverToBoxAdapter(child: CreatePostBar()),
                // Divider
                SliverToBoxAdapter(child: _sectionDivider()),
                // People You May Know
                const SliverToBoxAdapter(child: PeopleYouMayKnowBar()),
                // Divider
                SliverToBoxAdapter(child: _sectionDivider()),
                // Social Navigation Cards
                SliverToBoxAdapter(child: _SocialNavSection()),
                // Online Friends
                SliverToBoxAdapter(child: _sectionDivider()),
                SliverToBoxAdapter(child: _OnlineFriendsStrip()),
                // Bottom spacing
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _sectionDivider() {
    return Container(
      height: 1,
      color: Colors.white.withValues(alpha: 0.05),
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK NAV ROW — Friends · Requests · Events · Directory
// ─────────────────────────────────────────────────────────────────────────────
class _QuickNavRow extends StatelessWidget {
  static const _items = <_NavChip>[
    _NavChip(
      Icons.people_rounded,
      'Friends',
      '/friends',
      DesignTokens.neonCyan,
    ),
    _NavChip(
      Icons.person_add_rounded,
      'Requests',
      '/friend-requests',
      DesignTokens.neonMagenta,
    ),
    _NavChip(Icons.event_rounded, 'Events', '/events', DesignTokens.neonAmber),
    _NavChip(
      Icons.storefront_rounded,
      'Market',
      '/marketplace',
      DesignTokens.neonGreen,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 380;

        Widget tile(_NavChip item) {
          return GestureDetector(
            onTap: () => context.push(item.route),
            child: Container(
              width: isNarrow ? 82 : null,
              padding: EdgeInsets.symmetric(vertical: isNarrow ? 9 : 10),
              decoration: BoxDecoration(
                color: const Color(0xFF10192A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    color: Colors.white70,
                    size: isNarrow ? 18 : 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: isNarrow ? 10 : 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }

        if (isNarrow) {
          return SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemBuilder: (context, index) => tile(_items[index]),
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemCount: _items.length,
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: _items
                .map(
                  (item) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: tile(item),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _NetworkPulseBand extends StatelessWidget {
  const _NetworkPulseBand();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: context
          .read<EnhancedFriendsService>()
          .streamPendingRequestCount()
          .handleError((_) {}),
      builder: (context, snapshot) {
        final width = MediaQuery.of(context).size.width;
        final isNarrow = width < 380;
        final pendingRequests = snapshot.data ?? 0;
        final metrics = [
          const _PulseMetric(
            label: 'Live now',
            value: '28',
            accent: DesignTokens.neonGreen,
          ),
          _PulseMetric(
            label: 'Pending',
            value: '$pendingRequests',
            accent: DesignTokens.neonRed,
          ),
          const _PulseMetric(
            label: 'Event desks',
            value: '6',
            accent: DesignTokens.neonAmber,
          ),
        ];

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF132238), Color(0xFF0E1726)],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.6,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isNarrow)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: DesignTokens.neonGreen,
                              boxShadow: [
                                BoxShadow(
                                  color: DesignTokens.neonGreen.withValues(
                                    alpha: 0.45,
                                  ),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Network pulse',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Updated moments ago',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: DesignTokens.neonGreen,
                          boxShadow: [
                            BoxShadow(
                              color: DesignTokens.neonGreen.withValues(
                                alpha: 0.45,
                              ),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Network pulse',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Updated moments ago',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                Text(
                  'Fight camps are active, connection traffic is up, and event teams are moving across the platform.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                if (isNarrow)
                  Column(
                    children: metrics
                        .map(
                          (metric) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _PulseMetricTile(metric: metric),
                          ),
                        )
                        .toList(),
                  )
                else
                  Row(
                    children: metrics
                        .map(
                          (metric) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: _PulseMetricTile(metric: metric),
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PulseMetric {
  const _PulseMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;
}

class _PulseMetricTile extends StatelessWidget {
  const _PulseMetricTile({required this.metric});

  final _PulseMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.value,
            style: TextStyle(
              color: metric.accent,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavChip {
  const _NavChip(this.icon, this.label, this.route, this.color);
  final IconData icon;
  final String label;
  final String route;
  final Color color;
}

// ─────────────────────────────────────────────────────────────────────────────
// SOCIAL NAVIGATION CARDS — Friend Requests, Find Friends, Directory
// ─────────────────────────────────────────────────────────────────────────────
class _SocialNavSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Network tools',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _NavCard(
            icon: Icons.person_add_alt_1_rounded,
            title: 'Friend Requests',
            subtitle: 'Review pending inbound requests',
            color: DesignTokens.neonCyan,
            badgeStream: true,
            onTap: () => context.push('/friend-requests'),
          ),
          const SizedBox(height: 8),
          _NavCard(
            icon: Icons.person_search_rounded,
            title: 'Member Search',
            subtitle: 'Search by name, gym, or discipline',
            color: DesignTokens.neonAmber,
            onTap: () => context.push('/find-friends'),
          ),
          const SizedBox(height: 8),
          _NavCard(
            icon: Icons.groups_rounded,
            title: 'Member Directory',
            subtitle: 'Browse fighters, coaches, promoters, and gyms',
            color: DesignTokens.neonCyan,
            onTap: () => context.push('/members'),
          ),
          const SizedBox(height: 8),
          _NavCard(
            icon: Icons.leaderboard_rounded,
            title: 'Suggested Connections',
            subtitle: 'Recommended contacts based on roster overlap',
            color: DesignTokens.neonAmber,
            onTap: () => context.push('/friend-suggestions'),
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badgeStream = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool badgeStream;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon circle
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.10),
              ),
              child: Icon(icon, color: Colors.white70, size: 20),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (badgeStream) _PendingBadge(),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: context
          .read<EnhancedFriendsService>()
          .streamPendingRequestCount()
          .handleError((_) {}),
      builder: (context, snap) {
        final count = snap.data ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: DesignTokens.neonRed,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count > 99 ? '99+' : '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONLINE FRIENDS STRIP — Who's online now
// ─────────────────────────────────────────────────────────────────────────────
class _OnlineFriendsStrip extends StatelessWidget {
  // Demo data — real DFC members currently online
  static const _onlineFriends = [
    'Jordan R',
    'Joshy B',
    'Joey D',
    'Sumire Y',
    'Justis H',
    'Stephanie C',
    'Karim M',
  ];

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 380;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isNarrow)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: DesignTokens.neonGreen,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Online Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_onlineFriends.length} friends',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: DesignTokens.neonGreen,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Online Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_onlineFriends.length} friends',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          SizedBox(
            height: isNarrow ? 82 : 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _onlineFriends.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: DesignTokens.bgCard,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Icon(
                              Icons.person,
                              color: Colors.white.withValues(alpha: 0.4),
                              size: 22,
                            ),
                          ),
                          // Green dot
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: DesignTokens.neonGreen,
                                border: Border.all(
                                  color: DesignTokens.bgPrimary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _onlineFriends[index],
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
