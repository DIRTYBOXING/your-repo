import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Signal status for the card
enum SignalStatus { green, amber, red }

/// Reusable SignalCard widget - the foundation of the Command Center
/// Used throughout Dashboard, FightWire, Training screens
class SignalCard extends StatelessWidget {
  const SignalCard({
    super.key,
    required this.title,
    required this.status,
    required this.explanation,
    this.action,
    this.onActionTap,
    this.icon,
  });

  final String title;
  final SignalStatus status;
  final String explanation;
  final String? action;
  final VoidCallback? onActionTap;
  final IconData? icon;

  Color get statusColor {
    switch (status) {
      case SignalStatus.green:
        return AppTheme.neonGreen;
      case SignalStatus.amber:
        return Colors.orangeAccent;
      case SignalStatus.red:
        return const Color(0xFFFF4757);
    }
  }

  String get statusLabel {
    switch (status) {
      case SignalStatus.green:
        return 'OPTIMAL';
      case SignalStatus.amber:
        return 'CAUTION';
      case SignalStatus.red:
        return 'ALERT';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Status indicator
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: statusColor, blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 10),
              // Title
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // AI Explanation
          Text(
            explanation,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          // Action button (if provided)
          if (action != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onActionTap,
              child: Row(
                children: [
                  Icon(
                    icon ?? Icons.arrow_forward,
                    color: statusColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    action!,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// FightWire Signal Card - for live event/opportunity signals
class FightWireSignal extends StatelessWidget {
  const FightWireSignal({
    super.key,
    required this.type,
    required this.title,
    required this.source,
    required this.region,
    required this.timeAgo,
    this.isUrgent = false,
    this.onContact,
    this.onTrack,
  });

  final String type; // Event, Opportunity, Camp, Mentor, Alert
  final String title;
  final String source;
  final String region;
  final String timeAgo;
  final bool isUrgent;
  final VoidCallback? onContact;
  final VoidCallback? onTrack;

  Color get typeColor {
    switch (type.toLowerCase()) {
      case 'event':
        return AppTheme.neonCyan;
      case 'opportunity':
        return AppTheme.neonMagenta;
      case 'camp':
        return AppTheme.neonGreen;
      case 'mentor':
        return const Color(0xFFFFD700); // Gold
      case 'alert':
        return const Color(0xFFFF4757);
      default:
        return AppTheme.textMuted;
    }
  }

  IconData get typeIcon {
    switch (type.toLowerCase()) {
      case 'event':
        return Icons.event;
      case 'opportunity':
        return Icons.bolt;
      case 'camp':
        return Icons.fitness_center;
      case 'mentor':
        return Icons.diamond;
      case 'alert':
        return Icons.warning_amber;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUrgent
              ? typeColor.withValues(alpha: 0.5)
              : AppTheme.surfaceColor,
          width: isUrgent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type + Time row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(typeIcon, color: typeColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      type.toUpperCase(),
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4757).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'URGENT',
                    style: TextStyle(
                      color: Color(0xFFFF4757),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                timeAgo,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Title
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          // Source + Region
          Row(
            children: [
              const Icon(Icons.verified, color: AppTheme.neonCyan, size: 12),
              const SizedBox(width: 4),
              Text(
                source,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.location_on,
                color: AppTheme.textMuted,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                region,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onContact,
                  icon: const Icon(Icons.send, size: 14),
                  label: const Text('Contact'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: typeColor,
                    side: BorderSide(color: typeColor.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onTrack,
                  icon: const Icon(Icons.bookmark_border, size: 14),
                  label: const Text('Track'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textMuted,
                    side: const BorderSide(color: AppTheme.surfaceColor),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Readiness Card - for the top dashboard section
class ReadinessCard extends StatelessWidget {
  const ReadinessCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.status = SignalStatus.green,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final SignalStatus status;
  final VoidCallback? onTap;

  Color get statusColor {
    switch (status) {
      case SignalStatus.green:
        return AppTheme.neonGreen;
      case SignalStatus.amber:
        return Colors.orangeAccent;
      case SignalStatus.red:
        return const Color(0xFFFF4757);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.surfaceColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: statusColor, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: statusColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
