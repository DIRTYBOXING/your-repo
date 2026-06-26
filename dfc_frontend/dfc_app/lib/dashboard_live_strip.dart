import 'package:flutter/material.dart';
import '../../../dfc_theme.dart';
import '../models/dashboard_item_model.dart';

class DashboardLiveStrip extends StatelessWidget {
  final List<DashboardItemModel> items;

  const DashboardLiveStrip({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.accentRed,
        boxShadow: [BoxShadow(color: AppColors.accentRed.withValues(alpha: 0.4), blurRadius: 12)],
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: items.map((item) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.center,
            child: Row(
              children: [
                Icon(item.icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  item.title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}