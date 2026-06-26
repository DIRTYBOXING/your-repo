import 'package:flutter/material.dart';
import '../models/badge_model.dart' as model;

class BadgeStrip extends StatelessWidget {
  final List<model.Badge> badges;
  const BadgeStrip({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: badges
          .map(
            (badge) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Tooltip(
                message: '${badge.name}\n${badge.description}',
                child: Image.asset(
                  badge.iconPath,
                  width: 32,
                  height: 32,
                  errorBuilder: (c, o, s) => const Icon(
                    Icons.emoji_events,
                    color: Colors.amber,
                    size: 28,
                  ),
                ),
              ),
            ),
          )
          .toList()
          .cast<Widget>(),
    );
  }
}
