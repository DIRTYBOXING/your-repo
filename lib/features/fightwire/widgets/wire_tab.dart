import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/neon_card.dart';

class WireTab extends StatelessWidget {
  const WireTab({super.key});

  static const _posts = [
    (
      'Marcus Torres',
      'Camp update: 3 weeks out. Feeling sharp.',
      '2h',
      Icons.sports_mma,
      Color(0xFFE53935),
      true,
    ),
    (
      'DFC News',
      'Hex Fight Series 27 officially announced for March!',
      '4h',
      Icons.campaign,
      Color(0xFF00BCD4),
      true,
    ),
    (
      'Absolute MMA Melbourne',
      'New sparring sessions \u{2014} book now.',
      '5h',
      Icons.fitness_center,
      Color(0xFFFF9800),
      true,
    ),
    (
      'Rankings Update',
      'Lightweight shakeup after last weekend.',
      '8h',
      Icons.emoji_events,
      Color(0xFFFFCA28),
      false,
    ),
    (
      'FightTasker',
      '12 new gig opportunities posted today.',
      '10h',
      Icons.work,
      Color(0xFF4CAF50),
      false,
    ),
    (
      'Corner Voice AI',
      '"Champions are made in the dark."',
      '12h',
      Icons.psychology,
      Color(0xFF9C27B0),
      false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _fChip('All', true),
              _fChip('Fighters', false),
              _fChip('Gyms', false),
              _fChip('Promoters', false),
              _fChip('Sponsors', false),
              _fChip('News', false),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _posts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final p = _posts[i];
              return NeonCard(
                glow: p.$5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: p.$5.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(p.$4, size: 16, color: p.$5),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    p.$1,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (p.$6) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.verified,
                                      size: 14,
                                      color: AppColors.neonBlue,
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                p.$3,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.more_horiz,
                          size: 18,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.$2,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(
                          Icons.favorite_outline,
                          size: 15,
                          color: AppColors.textTertiary,
                        ),
                        SizedBox(width: 3),
                        Text(
                          '24',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(
                          Icons.comment_outlined,
                          size: 15,
                          color: AppColors.textTertiary,
                        ),
                        SizedBox(width: 3),
                        Text(
                          '8',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(
                          Icons.share_outlined,
                          size: 15,
                          color: AppColors.textTertiary,
                        ),
                        Spacer(),
                        Icon(
                          Icons.bookmark_outline,
                          size: 15,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _fChip(String l, bool a) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: a
            ? AppColors.neonBlue.withValues(alpha: 0.15)
            : AppColors.elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: a
              ? AppColors.neonBlue.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Text(
        l,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: a ? AppColors.neonBlue : AppColors.textTertiary,
        ),
      ),
    ),
  );
}
