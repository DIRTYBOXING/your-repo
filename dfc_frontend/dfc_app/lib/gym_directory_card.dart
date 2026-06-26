import 'package:flutter/material.dart';
import '../../../dfc_theme.dart';
import '../models/gym_directory_model.dart';

class GymDirectoryCard extends StatelessWidget {
  final GymDirectoryModel gym;

  const GymDirectoryCard({super.key, required this.gym});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10)],
        image: DecorationImage(
          image: NetworkImage(gym.bannerUrl),
          fit: BoxFit.cover,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // GRADIENT OVERLAY
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // CONTENT
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: gym.tags.map((tag) => _buildTag(tag)).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.surface,
                      backgroundImage: NetworkImage(gym.logoUrl),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gym.name,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            gym.location,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${gym.fighterCount} Fighters', style: const TextStyle(color: AppColors.accentCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${gym.championCount} Champs', style: const TextStyle(color: AppColors.championGold, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Text('#$text', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}