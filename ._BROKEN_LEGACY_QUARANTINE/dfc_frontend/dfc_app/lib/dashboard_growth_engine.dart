import 'package:flutter/material.dart';
import '../../../dfc_theme.dart';
import '../models/dashboard_item_model.dart';

class DashboardGrowthEngine extends StatelessWidget {
  final List<DashboardItemModel> items;

  const DashboardGrowthEngine({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "DAILY MISSIONS",
            style: TextStyle(
              color: AppColors.championGold,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: items.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.championGold.withValues(alpha: 0.3)),
                  boxShadow: [BoxShadow(color: AppColors.championGold.withValues(alpha: 0.05), blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.championGold.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: AppColors.championGold, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}