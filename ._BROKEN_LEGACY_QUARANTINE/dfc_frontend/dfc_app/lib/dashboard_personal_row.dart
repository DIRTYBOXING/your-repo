import 'package:flutter/material.dart';
import '../../../dfc_theme.dart';
import '../models/dashboard_item_model.dart';

class DashboardPersonalRow extends StatelessWidget {
  final List<DashboardItemModel> items;

  const DashboardPersonalRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "YOUR STUFF",
            style: TextStyle(
              color: AppColors.accentCyan,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: items.map((item) {
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [BoxShadow(color: AppColors.accentCyan.withValues(alpha: 0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, color: AppColors.textPrimary, size: 32),
                      const SizedBox(height: 12),
                      Text(
                        item.title,
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}