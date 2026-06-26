import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/image_assets.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/config/router_config.dart' as routes;
import '../../../shared/widgets/dfc_network_image.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// STORIES BAR — live network channels and active story lanes
///
/// • "Create" button opens full story creator with media upload
/// • Live category stories with animated gradient rings
/// • Tap any category to dive into Fight Stories magazine
/// • "LIVE" badge pulses on active stories
/// • Promotional content rotates through demo stories
/// ═══════════════════════════════════════════════════════════════════════════
class StoriesBar extends StatefulWidget {
  const StoriesBar({super.key});

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  // Real story categories — each maps to a content section
  static const _stories = <_StoryData>[
    _StoryData(
      label: 'Update',
      icon: Icons.add_rounded,
      ringColors: [Color(0xFF00F5FF), Color(0xFF00FF88)],
      isAdd: true,
      routeCategory: null,
      badgeText: null,
      thumbnailAsset: null,
    ),
    _StoryData(
      label: 'Live Desk',
      icon: Icons.live_tv_rounded,
      ringColors: [Color(0xFFFF3366), Color(0xFFFF00FF)],
      isAdd: false,
      routeCategory: 'EVENTS',
      badgeText: 'LIVE',
      thumbnailAsset: ImageAssets.bgAction,
    ),
    _StoryData(
      label: 'Camps',
      icon: Icons.sports_mma_rounded,
      ringColors: [Color(0xFFFF00FF), Color(0xFF7B1FA2)],
      isAdd: false,
      routeCategory: 'FIGHTERS',
      badgeText: '3 NEW',
      thumbnailAsset: ImageAssets.fightPlaceholder,
    ),
    _StoryData(
      label: 'BKFC',
      icon: Icons.local_fire_department_rounded,
      ringColors: [Color(0xFFFFD700), Color(0xFFFF6D00)],
      isAdd: false,
      routeCategory: 'BKFC',
      badgeText: 'HOT',
      thumbnailAsset: ImageAssets.bkfcPlaceholder,
    ),
    _StoryData(
      label: 'Cards',
      icon: Icons.event_rounded,
      ringColors: [Color(0xFF00F5FF), Color(0xFF448AFF)],
      isAdd: false,
      routeCategory: 'EVENTS',
      badgeText: '5',
      thumbnailAsset: ImageAssets.eventPlaceholder,
    ),
    _StoryData(
      label: 'Weigh-In',
      icon: Icons.monitor_weight_rounded,
      ringColors: [Color(0xFFFFC107), Color(0xFFFF9800)],
      isAdd: false,
      routeCategory: 'EVENTS',
      badgeText: null,
      thumbnailAsset: ImageAssets.bgPromo,
    ),
    _StoryData(
      label: 'Training',
      icon: Icons.fitness_center_rounded,
      ringColors: [Color(0xFF00FF88), Color(0xFF00C853)],
      isAdd: false,
      routeCategory: 'FIGHTERS',
      badgeText: null,
      thumbnailAsset: ImageAssets.trainingPlaceholder,
    ),
    _StoryData(
      label: 'Recaps',
      icon: Icons.emoji_events_rounded,
      ringColors: [Color(0xFFFFD740), Color(0xFFFF6D00)],
      isAdd: false,
      routeCategory: 'RECAPS',
      badgeText: 'NEW',
      thumbnailAsset: ImageAssets.bgAction,
    ),
    _StoryData(
      label: 'Gyms',
      icon: Icons.location_city_rounded,
      ringColors: [Color(0xFF40C4FF), Color(0xFF0288D1)],
      isAdd: false,
      routeCategory: 'CITIES',
      badgeText: null,
      thumbnailAsset: ImageAssets.gymPlaceholder,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 138,
      decoration: BoxDecoration(
        color: DesignTokens.bgPrimary,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DesignTokens.neonRed,
                    boxShadow: [
                      BoxShadow(
                        color: DesignTokens.neonRed.withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Live channels',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_stories.length - 1} active lanes',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              itemCount: _stories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _StoryCircle(
                data: _stories[i],
                pulseAnimation: _pulseCtrl,
                onTap: () => _handleStoryTap(context, _stories[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleStoryTap(BuildContext context, _StoryData story) {
    if (story.isAdd) {
      context.push(routes.RouterConfig.createStoryPath);
    } else {
      context.push(
        '${routes.RouterConfig.storyViewerPath}?category=${story.routeCategory ?? 'EVENTS'}',
      );
    }
  }
}

// ── Data model ──
class _StoryData {
  final String label;
  final IconData icon;
  final List<Color> ringColors;
  final bool isAdd;
  final String? routeCategory;
  final String? badgeText;
  final String? thumbnailAsset;

  const _StoryData({
    required this.label,
    required this.icon,
    required this.ringColors,
    required this.isAdd,
    required this.routeCategory,
    required this.badgeText,
    required this.thumbnailAsset,
  });
}

// ── Story circle widget ──
class _StoryCircle extends StatelessWidget {
  final _StoryData data;
  final Animation<double> pulseAnimation;
  final VoidCallback onTap;

  const _StoryCircle({
    required this.data,
    required this.pulseAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLive = data.badgeText == 'LIVE';

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedBuilder(
                  animation: pulseAnimation,
                  builder: (context, child) {
                    final glowOpacity = isLive
                        ? 0.22 + pulseAnimation.value * 0.24
                        : 0.0;
                    return Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: data.isAdd
                            ? null
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: data.ringColors,
                              ),
                        border: data.isAdd
                            ? Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 2,
                              )
                            : null,
                        boxShadow: isLive
                            ? [
                                BoxShadow(
                                  color: data.ringColors.first.withValues(
                                    alpha: glowOpacity,
                                  ),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: DfcCircleAvatar(
                        imageUrl: data.thumbnailAsset,
                        radius: 27,
                        backgroundColor: data.isAdd
                            ? DesignTokens.bgCard
                            : DesignTokens.bgSecondary,
                        fallbackChild: Icon(
                          data.icon,
                          color: data.isAdd
                              ? DesignTokens.neonCyan
                              : data.ringColors.first,
                          size: data.isAdd ? 26 : 22,
                        ),
                      ),
                    );
                  },
                ),

                if (data.badgeText != null)
                  Positioned(
                    top: -3,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isLive
                            ? const Color(0xFFFF3366)
                            : data.ringColors.first,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isLive
                                        ? const Color(0xFFFF3366)
                                        : data.ringColors.first)
                                    .withValues(alpha: 0.35),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        data.badgeText!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              data.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: data.isAdd
                    ? DesignTokens.neonCyan
                    : Colors.white.withValues(alpha: 0.78),
                fontSize: 10,
                fontWeight: data.isAdd ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: data.badgeText == 'LIVE' ? 0.5 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
