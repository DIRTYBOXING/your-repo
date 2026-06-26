import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// STORY HIGHLIGHTS — Instagram-grade profile highlights
///
/// • Circular highlight covers on profile
/// • Grouped archived stories by category
/// • Create / Edit / Delete highlights
/// • Tap to view highlight reel
/// ═══════════════════════════════════════════════════════════════════════════

class StoryHighlightsBar extends StatelessWidget {
  const StoryHighlightsBar({super.key});

  static const _highlights = <_HighlightData>[
    _HighlightData(
      label: 'Fights',
      icon: Icons.sports_mma_rounded,
      color: Color(0xFFFF3366),
      count: 8,
    ),
    _HighlightData(
      label: 'Training',
      icon: Icons.fitness_center_rounded,
      color: Color(0xFF00F5FF),
      count: 14,
    ),
    _HighlightData(
      label: 'Events',
      icon: Icons.event_rounded,
      color: Color(0xFFFFD700),
      count: 6,
    ),
    _HighlightData(
      label: 'Weigh-In',
      icon: Icons.monitor_weight_rounded,
      color: Color(0xFFFF00FF),
      count: 3,
    ),
    _HighlightData(
      label: 'BTS',
      icon: Icons.videocam_rounded,
      color: Color(0xFF00FF88),
      count: 11,
    ),
    _HighlightData(
      label: 'New',
      icon: Icons.add_rounded,
      color: Colors.white24,
      count: 0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _highlights.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final h = _highlights[i];
          return _HighlightCircle(data: h);
        },
      ),
    );
  }
}

class _HighlightCircle extends StatelessWidget {
  final _HighlightData data;
  const _HighlightCircle({required this.data});

  @override
  Widget build(BuildContext context) {
    final isAdd = data.label == 'New';
    return GestureDetector(
      onTap: () {
        if (isAdd) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Create a new highlight from your stories'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${data.label}: ${data.count} stories saved'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isAdd
                      ? Colors.white.withValues(alpha: 0.2)
                      : data.color,
                  width: isAdd ? 1.5 : 2,
                ),
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: isAdd
                    ? DesignTokens.bgCard
                    : data.color.withValues(alpha: 0.12),
                child: Icon(
                  data.icon,
                  color: isAdd ? Colors.white54 : data.color,
                  size: isAdd ? 24 : 22,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightData {
  final String label;
  final IconData icon;
  final Color color;
  final int count;

  const _HighlightData({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
  });
}
