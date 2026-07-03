import 'package:flutter/material.dart';
import '../../../../dfc_theme.dart';
import '../models/notification_item_model.dart';

class NotificationListItem extends StatelessWidget {
  final NotificationItemModel notification;

  const NotificationListItem({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case 'payment':
        icon = Icons.attach_money;
        color = AppColors.championGold;
        break;
      case 'live':
        icon = Icons.sensors;
        color = AppColors.accentRed;
        break;
      case 'training':
        icon = Icons.fitness_center;
        color = AppColors.accentCyan;
        break;
      default:
        icon = Icons.info_outline;
        color = AppColors.textMuted;
    }

    if (notification.isRead) color = AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? AppColors.border
              : color.withValues(alpha: 0.5),
        ),
        boxShadow: notification.isRead
            ? []
            : [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        color: notification.isRead
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      notification.timeAgo,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification.message,
                  style: TextStyle(
                    color: notification.isRead
                        ? AppColors.textMuted
                        : AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
