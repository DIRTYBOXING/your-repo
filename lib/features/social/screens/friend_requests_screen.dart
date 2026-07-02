import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/enhanced_friends_service.dart';
import '../../../shared/models/friend_model.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import '../../../core/theme/glass_panel.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FRIEND REQUESTS SCREEN
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Shows:
/// - Incoming friend requests with accept/reject
/// - Outgoing pending requests with cancel
/// - Mutual friends preview
/// - Request expiration countdown
/// ═══════════════════════════════════════════════════════════════════════════
class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        foregroundColor: Colors.white,
        title: const Text(
          'Friend Requests',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.neonCyan,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppTheme.neonCyan,
          tabs: const [
            Tab(text: 'Received'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_ReceivedRequestsTab(), _SentRequestsTab()],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RECEIVED REQUESTS TAB — Incoming friend requests
// ═══════════════════════════════════════════════════════════════════════════
class _ReceivedRequestsTab extends StatelessWidget {
  const _ReceivedRequestsTab();

  @override
  Widget build(BuildContext context) {
    final friendsService = context.watch<EnhancedFriendsService>();

    return StreamBuilder<List<FriendRequest>>(
      stream: friendsService.streamPendingRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.neonCyan),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_add_disabled,
                  size: 80,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No pending requests',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Friend requests will appear here',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return RequestCard(request: requests[index], isIncoming: true);
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SENT REQUESTS TAB — Outgoing pending requests
// ═══════════════════════════════════════════════════════════════════════════
class _SentRequestsTab extends StatelessWidget {
  const _SentRequestsTab();

  @override
  Widget build(BuildContext context) {
    final friendsService = context.watch<EnhancedFriendsService>();

    return StreamBuilder<List<FriendRequest>>(
      stream: friendsService.streamSentPendingRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.neonCyan),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.send,
                  size: 80,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No pending sent requests',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Friend requests you send will appear here',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return RequestCard(request: requests[index], isIncoming: false);
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REQUEST CARD — Individual friend request
// ═══════════════════════════════════════════════════════════════════════════
class RequestCard extends StatefulWidget {
  final FriendRequest request;
  final bool isIncoming;

  const RequestCard({
    super.key,
    required this.request,
    required this.isIncoming,
  });

  @override
  State<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<RequestCard> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final timeAgo = _formatTimeAgo(request.createdAt);
    final expiresIn = request.expiresAt.difference(DateTime.now());
    final isExpiringSoon = expiresIn.inDays < 3 && !request.isExpired;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassPanel(
      padding: EdgeInsets.zero,
      backgroundColor: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                GestureDetector(
                  onTap: () => context.push('/user/${request.senderId}'),
                  child: DfcCircleAvatar(
                    imageUrl: request.senderPhotoUrl,
                    radius: 32,
                    backgroundColor: AppTheme.cardBackground,
                    borderColor: Colors.white.withValues(alpha: 0.08),
                    borderWidth: 1,
                    fallbackText: request.senderName.isNotEmpty
                        ? request.senderName[0].toUpperCase()
                        : '?',
                  ),
                ),

                const SizedBox(width: 12),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/user/${request.senderId}'),
                        child: Text(
                          request.senderName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _getRoleIcon(request.senderRole),
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            request.senderRole.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeAgo,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Expiration warning
                if (isExpiringSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppTheme.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${expiresIn.inDays}d',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Mutual friends
            if (request.mutualFriendsCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.neonCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.neonCyan.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.people,
                      size: 16,
                      color: AppTheme.neonCyan,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${request.mutualFriendsCount} mutual ${request.mutualFriendsCount == 1 ? "friend" : "friends"}',
                      style: const TextStyle(
                        color: AppTheme.neonCyan,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Message
            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request.message!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],

            // Action buttons
            if (widget.isIncoming) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : () => _handleAccept(context),
                      icon: const Icon(Icons.check),
                      label: const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : () => _handleReject(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _handleCancel(context),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel Request'),
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _handleAccept(BuildContext context) async {
    setState(() => _isProcessing = true);

    final service = context.read<EnhancedFriendsService>();

    try {
      await service.acceptFriendRequest(widget.request.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You are now friends with ${widget.request.senderName}!',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleReject(BuildContext context) async {
    setState(() => _isProcessing = true);

    final service = context.read<EnhancedFriendsService>();

    try {
      await service.rejectFriendRequest(widget.request.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request declined')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleCancel(BuildContext context) async {
    setState(() => _isProcessing = true);

    final service = context.read<EnhancedFriendsService>();

    try {
      await service.cancelFriendRequest(widget.request.recipientId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request cancelled')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'fighter':
        return Icons.sports_mma;
      case 'coach':
        return Icons.school;
      case 'judge':
        return Icons.gavel;
      case 'fan':
        return Icons.favorite;
      default:
        return Icons.person;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
