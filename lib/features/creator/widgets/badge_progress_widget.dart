import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Badge progress widget
/// Displays creator's badge collection and progress
class BadgeProgressWidget extends StatelessWidget {
  final List<Map<String, dynamic>> badgeProgress;

  const BadgeProgressWidget({Key? key, required this.badgeProgress})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (badgeProgress.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.neonCyan.withOpacity(0.2)),
        ),
        child: const Center(
          child: Text(
            'No badges yet',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ),
      );
    }

    // Count unlocked badges
    final unlockedCount = badgeProgress
        .where((b) => b['isUnlocked'] == true)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Creator Badges',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.neonGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$unlockedCount/${badgeProgress.length}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.neonGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: badgeProgress.map((badge) {
            return _buildBadgeTile(
              badge['emoji'] ?? '⭐',
              badge['displayName'] ?? '',
              badge['isUnlocked'] ?? false,
              badge['progressPercent'] ?? 0.0,
              badge['remaining'] ?? 0,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBadgeTile(
    String emoji,
    String name,
    bool isUnlocked,
    double progressPercent,
    int remaining,
  ) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnlocked
              ? AppTheme.neonAmber.withOpacity(0.1)
              : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked
                ? AppTheme.neonAmber.withOpacity(0.5)
                : AppTheme.neonCyan.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge Emoji/Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked
                    ? AppTheme.neonAmber.withOpacity(0.2)
                    : AppTheme.neonCyan.withOpacity(0.1),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(height: 8),
            // Badge Name
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isUnlocked ? AppTheme.neonAmber : AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            if (!isUnlocked)
              // Progress Bar for locked badges
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: (progressPercent / 100).clamp(0.0, 1.0),
                      minHeight: 3,
                      backgroundColor: AppTheme.neonCyan.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.neonCyan,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$remaining left',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              )
            else
              // Unlocked indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '✓',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppTheme.neonGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 2),
                    Text(
                      'Unlocked',
                      style: TextStyle(
                        fontSize: 8,
                        color: AppTheme.neonGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
