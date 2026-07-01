import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/notification_model.dart';
import '../../../shared/services/notification_service.dart';
import '../../../shared/services/auth_service.dart';
import 'package:provider/provider.dart';

/// In-app notification feed — real-time from Firestore
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _loading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final auth = context.read<AuthService>();
    _userId = auth.currentUser?.uid;
    if (_userId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final items = await _notificationService.getNotifications(_userId!);
      if (mounted) {
        setState(() {
          _notifications = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    if (_userId == null) return;
    await _notificationService.markAllAsRead(_userId!);
    setState(() {
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
    });
  }

  Future<void> _clearAll() async {
    if (_userId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DesignTokens.bgCard,
        title: const Text('Clear All?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Delete all notifications? This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: DesignTokens.neonRed)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _notificationService.clearAll(_userId!);
      setState(() => _notifications = []);
    }
  }

  Future<void> _onTap(NotificationModel n) async {
    // Mark as read
    if (!n.isRead && _userId != null) {
      await _notificationService.markAsRead(_userId!, n.id);
      setState(() {
        final idx = _notifications.indexWhere((x) => x.id == n.id);
        if (idx >= 0) {
          _notifications[idx] = n.copyWith(isRead: true);
        }
      });
    }
    // Navigate if route present
    if (n.actionRoute != null && n.actionRoute!.isNotEmpty && mounted) {
      context.push(n.actionRoute!);
    }
  }

  Future<void> _onDismiss(NotificationModel n) async {
    if (_userId == null) return;
    await _notificationService.deleteNotification(_userId!, n.id);
    setState(() {
      _notifications.removeWhere((x) => x.id == n.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                  border: Border.all(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: DesignTokens.neonCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_notifications.isNotEmpty) ...[
            IconButton(
              tooltip: 'Mark all read',
              icon: const Icon(
                Icons.done_all,
                color: DesignTokens.neonGreen,
                size: 22,
              ),
              onPressed: _markAllRead,
            ),
            IconButton(
              tooltip: 'Clear all',
              icon: const Icon(
                Icons.delete_sweep,
                color: DesignTokens.neonRed,
                size: 22,
              ),
              onPressed: _clearAll,
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: DesignTokens.neonCyan),
            )
          : _notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              color: DesignTokens.neonCyan,
              backgroundColor: DesignTokens.bgCard,
              onRefresh: _loadNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingL,
                  vertical: DesignTokens.spacingM,
                ),
                itemCount: _notifications.length,
                itemBuilder: (ctx, i) =>
                    _buildNotificationTile(_notifications[i]),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: DesignTokens.textMuted,
          ),
          SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: DesignTokens.fontSizeTitle,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Fight offers, social activity, and alerts\nwill appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeBody,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel n) {
    final accentColor = _accentForType(n.type);

    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: DesignTokens.neonRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        ),
        child: const Icon(Icons.delete, color: DesignTokens.neonRed),
      ),
      onDismissed: (_) => _onDismiss(n),
      child: GestureDetector(
        onTap: () => _onTap(n),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(DesignTokens.cardPaddingSmall),
          decoration: BoxDecoration(
            color: n.isRead
                ? Colors.white.withValues(alpha: 0.02)
                : accentColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            border: Border.all(
              color: n.isRead
                  ? Colors.white.withValues(alpha: 0.06)
                  : accentColor.withValues(alpha: 0.2),
              width: DesignTokens.borderThin,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon / avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(n.type.icon, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: DesignTokens.fontSizeBody,
                              fontWeight: n.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          n.timeAgo,
                          style: const TextStyle(
                            color: DesignTokens.textMuted,
                            fontSize: DesignTokens.fontSizeCaption,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.body,
                      style: TextStyle(
                        color: n.isRead
                            ? DesignTokens.textMuted
                            : DesignTokens.textSecondary,
                        fontSize: DesignTokens.fontSizeSubtitleLarge,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (n.actionRoute != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                DesignTokens.radiusPill,
                              ),
                            ),
                            child: Text(
                              n.type.label,
                              style: TextStyle(
                                color: accentColor,
                                fontSize: DesignTokens.fontSizeMicro,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: DesignTokens.textMuted,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Unread dot
              if (!n.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _accentForType(NotificationType type) {
    switch (type) {
      case NotificationType.fightOffer:
      case NotificationType.matchFound:
        return DesignTokens.neonCyan;
      case NotificationType.eventInvite:
        return DesignTokens.neonAmber;
      case NotificationType.socialLike:
      case NotificationType.socialFollow:
        return DesignTokens.neonMagenta;
      case NotificationType.socialComment:
      case NotificationType.postMention:
        return DesignTokens.neonBlue;
      case NotificationType.achievement:
        return DesignTokens.neonGold;
      case NotificationType.safetyAlert:
        return DesignTokens.neonRed;
      case NotificationType.promoterMessage:
        return DesignTokens.neonGreen;
      case NotificationType.trainingReminder:
        return DesignTokens.neonAmber;
      case NotificationType.databankUpdate:
        return DesignTokens.neonCyan;
      case NotificationType.systemAlert:
      case NotificationType.general:
        return DesignTokens.textSecondary;
      case NotificationType.friendRequest:
      case NotificationType.friendRequestAccepted:
        return DesignTokens.neonCyan;
      case NotificationType.friendRequestRejected:
        return DesignTokens.neonRed;
    }
  }
}
